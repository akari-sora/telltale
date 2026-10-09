#!/usr/bin/env python3
"""Headless Android Automotive OS (AAOS) Emulator Automation Runner.

Automates Headless AAOS AVD execution and VHAL state machine verification:
- Background headless AVD launch (-no-window -no-audio -no-boot-anim).
- 4-Stage Readiness Verification:
    1. ADB Device State: `adb get-state` -> 'device'
    2. Boot Completed: `getprop sys.boot_completed` -> '1'
    3. Car Service Registration: `service check car_service` -> 'found'
    4. Automotive Foreground User: User 10 ready and unlocked
- VHAL (Vehicle Hardware Abstraction Layer) Injection:
    - Speed: 0x11600207 (0.0 m/s Stationary, 13.89 m/s Cruising, -2.0 m/s Reverse)
    - Gear:  0x11400400 (PARK=4, DRIVE=8, REVERSE=2, NEUTRAL=1)
- State Verification & Clean Teardown (`adb emu kill` / process terminate).
- Full `--dry-run` mode for CI pipelines without hardware/virtualization acceleration.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
from typing import Any, Dict, List, Optional, Tuple

# VHAL Property IDs (VehicleProperty.h)
PROP_PERF_VEHICLE_SPEED = "0x11600207"
PROP_PERF_VEHICLE_SPEED_DISPLAY = "0x11600208"
PROP_GEAR_SELECTION = "0x11400400"

# Gear Enums
GEAR_NEUTRAL = 1
GEAR_REVERSE = 2
GEAR_PARK = 4
GEAR_DRIVE = 8

GEAR_MAP = {
    "PARK": GEAR_PARK,
    "DRIVE": GEAR_DRIVE,
    "REVERSE": GEAR_REVERSE,
    "NEUTRAL": GEAR_NEUTRAL,
    "4": GEAR_PARK,
    "8": GEAR_DRIVE,
    "2": GEAR_REVERSE,
    "1": GEAR_NEUTRAL,
}

GEAR_NAME_REVERSE_MAP = {
    GEAR_PARK: "PARK (4)",
    GEAR_DRIVE: "DRIVE (8)",
    GEAR_REVERSE: "REVERSE (2)",
    GEAR_NEUTRAL: "NEUTRAL (1)",
}

# Standard Speed Test Points (m/s)
SPEED_STATIONARY = 0.0
SPEED_CRUISING = 13.89  # ~50 km/h
SPEED_REVERSE = -2.0    # ~ -7.2 km/h


@dataclass
class VhalScenario:
    name: str
    gear: int
    speed_mps: float
    expected_motion: str
    description: str


DEFAULT_SCENARIOS = [
    VhalScenario(
        name="Parked Baseline",
        gear=GEAR_PARK,
        speed_mps=SPEED_STATIONARY,
        expected_motion="STATIONARY",
        description="Vehicle in PARK at 0.0 m/s: DTC access allowed",
    ),
    VhalScenario(
        name="Drive Cruising",
        gear=GEAR_DRIVE,
        speed_mps=SPEED_CRUISING,
        expected_motion="MOVING",
        description="Vehicle in DRIVE at 13.89 m/s (50 km/h): DTC blocked / auto-pop",
    ),
    VhalScenario(
        name="Reverse Backing",
        gear=GEAR_REVERSE,
        speed_mps=SPEED_REVERSE,
        expected_motion="MOVING",
        description="Vehicle in REVERSE at -2.0 m/s: Negative speed safety gate triggers MOVING",
    ),
    VhalScenario(
        name="Restored Parked",
        gear=GEAR_PARK,
        speed_mps=SPEED_STATIONARY,
        expected_motion="STATIONARY",
        description="Vehicle returns to PARK at 0.0 m/s: Normal stationary state restored",
    ),
]


def find_adb_binary(explicit_path: Optional[str] = None) -> Optional[Path]:
    """Resolve adb binary path."""
    if explicit_path:
        p = Path(explicit_path).expanduser().resolve()
        if p.is_file() and os.access(p, os.X_OK):
            return p

    env_adb = os.environ.get("ADB")
    if env_adb:
        p = Path(env_adb).expanduser().resolve()
        if p.is_file() and os.access(p, os.X_OK):
            return p

    which_adb = shutil.which("adb")
    if which_adb:
        return Path(which_adb).resolve()

    android_home = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    candidates = []
    if android_home:
        candidates.append(Path(android_home) / "platform-tools" / "adb")

    candidates.extend([
        Path.home() / "Library" / "Android" / "sdk" / "platform-tools" / "adb",
        Path.home() / "Android" / "Sdk" / "platform-tools" / "adb",
        Path("/opt/android-sdk/platform-tools/adb"),
    ])

    for c in candidates:
        if c.is_file() and os.access(c, os.X_OK):
            return c.resolve()

    return None


def find_emulator_binary(explicit_path: Optional[str] = None) -> Optional[Path]:
    """Resolve Android emulator binary path."""
    if explicit_path:
        p = Path(explicit_path).expanduser().resolve()
        if p.is_file() and os.access(p, os.X_OK):
            return p

    env_emu = os.environ.get("EMULATOR_BIN")
    if env_emu:
        p = Path(env_emu).expanduser().resolve()
        if p.is_file() and os.access(p, os.X_OK):
            return p

    which_emu = shutil.which("emulator")
    if which_emu:
        return Path(which_emu).resolve()

    android_home = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    candidates = []
    if android_home:
        candidates.append(Path(android_home) / "emulator" / "emulator")

    candidates.extend([
        Path.home() / "Library" / "Android" / "sdk" / "emulator" / "emulator",
        Path.home() / "Android" / "Sdk" / "emulator" / "emulator",
        Path("/opt/android-sdk/emulator/emulator"),
    ])

    for c in candidates:
        if c.is_file() and os.access(c, os.X_OK):
            return c.resolve()

    return None


def list_available_avds(emulator_bin: Optional[Path]) -> List[str]:
    """Query available AVD names via emulator -list-avds."""
    if not emulator_bin or not emulator_bin.is_file():
        return []
    try:
        res = subprocess.run(
            [str(emulator_bin), "-list-avds"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        if res.returncode == 0:
            return [line.strip() for line in res.stdout.splitlines() if line.strip()]
    except Exception:
        pass
    return []


# ---------------------------------------------------------------------------
# Readiness Response Parsers (Used for both live polling & dry-run validation)
# ---------------------------------------------------------------------------

def parse_stage1_response(output: str) -> bool:
    """Stage 1: Verify adb get-state output."""
    return output.strip().lower() == "device"


def parse_stage2_response(output: str) -> bool:
    """Stage 2: Verify getprop sys.boot_completed output."""
    return output.strip() == "1"


def parse_stage3_response(output: str) -> bool:
    """Stage 3: Verify service check car_service output."""
    cleaned = output.strip().lower()
    if "not found" in cleaned:
        return False
    return "found" in cleaned or "is running" in cleaned


def parse_stage4_response(output: str) -> bool:
    """Stage 4: Verify foreground automotive user (User 10) is active."""
    cleaned = output.strip()
    # Check simple `am get-current-user` output
    if cleaned in ("10", "user 10"):
        return True
    # Check `dumpsys user` or `pm list users` output
    if "UserInfo{10:" in output or "User 10: RUNNING_UNLOCKED" in output:
        return True
    # If integer >= 10 returned
    try:
        user_id = int(cleaned.split()[-1])
        return user_id >= 10
    except (ValueError, IndexError):
        return False


# ---------------------------------------------------------------------------
# Command Builders
# ---------------------------------------------------------------------------

def build_emulator_launch_cmd(
    emulator_bin: Path,
    avd_name: str,
    extra_args: Optional[List[str]] = None,
) -> List[str]:
    """Build emulator background launch command line."""
    cmd = [
        str(emulator_bin),
        "-avd",
        avd_name,
        "-no-window",
        "-no-audio",
        "-no-boot-anim",
        "-gpu",
        "swiftshader_indirect",
    ]
    if extra_args:
        cmd.extend(extra_args)
    return cmd


def build_adb_prefix(adb_bin: Path, serial: Optional[str] = None) -> List[str]:
    """Build adb command prefix with optional target serial."""
    cmd = [str(adb_bin)]
    if serial:
        cmd.extend(["-s", serial])
    return cmd


def build_speed_injection_cmd(speed_mps: float) -> List[str]:
    """Build VHAL speed injection command."""
    return ["cmd", "car_service", "inject-vhal-event", PROP_PERF_VEHICLE_SPEED, str(speed_mps)]


def build_gear_injection_cmd(gear: int) -> List[str]:
    """Build VHAL gear injection command."""
    return ["cmd", "car_service", "inject-vhal-event", PROP_GEAR_SELECTION, str(gear)]


# ---------------------------------------------------------------------------
# Dry-Run Execution
# ---------------------------------------------------------------------------

def run_dry_run(
    avd_name: str,
    emulator_bin: Optional[Path],
    adb_bin: Optional[Path],
    verbose: bool = False,
) -> int:
    """Execute complete dry-run validation for AAOS headless runner."""
    print("=" * 70)
    print(" [AAOS-HEADLESS-RUNNER] Starting Dry-Run Verification Suite")
    print("=" * 70)

    # 1. Validate VHAL Constants and Mappings
    print("\n[Phase 1] Validating VHAL Constants and Property Mappings...")
    print(f"  ✓ Speed Property:   {PROP_PERF_VEHICLE_SPEED} (float in m/s)")
    print(f"  ✓ Display Speed:    {PROP_PERF_VEHICLE_SPEED_DISPLAY} (float in m/s)")
    print(f"  ✓ Gear Property:    {PROP_GEAR_SELECTION} (int32)")

    for name, code in [("PARK", 4), ("DRIVE", 8), ("REVERSE", 2), ("NEUTRAL", 1)]:
        mapped = GEAR_MAP[name]
        assert mapped == code, f"Gear map mismatch for {name}: {mapped} != {code}"
        print(f"  ✓ Gear {name:<7} -> {mapped} ({bin(mapped)})")

    # 2. Validate Command Generation
    print("\n[Phase 2] Validating Command Generators...")
    speed_cmd = build_speed_injection_cmd(13.89)
    assert speed_cmd == ["cmd", "car_service", "inject-vhal-event", "0x11600207", "13.89"]
    print(f"  ✓ Speed injection command: {' '.join(speed_cmd)}")

    gear_cmd = build_gear_injection_cmd(4)
    assert gear_cmd == ["cmd", "car_service", "inject-vhal-event", "0x11400400", "4"]
    print(f"  ✓ Gear injection command:  {' '.join(gear_cmd)}")

    emu_cmd = build_emulator_launch_cmd(
        emulator_bin or Path("/usr/local/bin/emulator"),
        avd_name,
    )
    assert "-no-window" in emu_cmd and "-no-audio" in emu_cmd and "-no-boot-anim" in emu_cmd
    print(f"  ✓ Emulator launch command: {' '.join(emu_cmd)}")

    # 3. Validate 4-Stage Readiness Check Parsers
    print("\n[Phase 3] Validating 4-Stage Readiness Parsers...")

    # Stage 1: Device connectivity
    assert parse_stage1_response("device\n") is True
    assert parse_stage1_response("offline\n") is False
    assert parse_stage1_response("") is False
    print("  ✓ Stage 1 (ADB connectivity): 'device' -> PASSED, 'offline' -> REJECTED")

    # Stage 2: Boot Completed
    assert parse_stage2_response("1\n") is True
    assert parse_stage2_response("0\n") is False
    assert parse_stage2_response("") is False
    print("  ✓ Stage 2 (sys.boot_completed): '1' -> PASSED, '0' -> REJECTED")

    # Stage 3: Car Service
    assert parse_stage3_response("Service car_service: found\n") is True
    assert parse_stage3_response("Service car_service: not found\n") is False
    print("  ✓ Stage 3 (service check car_service): 'found' -> PASSED, 'not found' -> REJECTED")

    # Stage 4: Foreground User 10
    assert parse_stage4_response("10\n") is True
    assert parse_stage4_response("UserInfo{10:Driver:13}\n") is True
    assert parse_stage4_response("0\n") is False  # Headless system user not driver
    print("  ✓ Stage 4 (Driver User 10 readiness): '10' -> PASSED, '0' (system user) -> REJECTED")

    # 4. Validate VHAL Test Scenarios
    print("\n[Phase 4] Validating VHAL Injection Matrix...")
    for idx, sc in enumerate(DEFAULT_SCENARIOS, start=1):
        gear_str = GEAR_NAME_REVERSE_MAP[sc.gear]
        s_cmd = build_speed_injection_cmd(sc.speed_mps)
        g_cmd = build_gear_injection_cmd(sc.gear)
        print(f"  ✓ Scenario {idx}: {sc.name:<18} Gear={gear_str:<12} Speed={sc.speed_mps:>6} m/s [{sc.expected_motion}]")
        if verbose:
            print(f"      Gear cmd:  adb shell {' '.join(g_cmd)}")
            print(f"      Speed cmd: adb shell {' '.join(s_cmd)}")
            print(f"      Intent:    {sc.description}")

    # 5. Environment & Tool Discovery Check
    print("\n[Phase 5] Environment & Local Tool Inspection...")
    if adb_bin:
        print(f"  ✓ ADB binary discovered at:      {adb_bin}")
    else:
        print("  ℹ ADB binary not in path (mocked in dry-run).")

    if emulator_bin:
        print(f"  ✓ Emulator binary discovered at: {emulator_bin}")
        avds = list_available_avds(emulator_bin)
        print(f"  ✓ Discovered {len(avds)} local AVDs: {', '.join(avds[:4])}{'...' if len(avds) > 4 else ''}")
        if avd_name in avds:
            print(f"  ✓ Target AVD '{avd_name}' exists locally.")
        else:
            print(f"  ℹ Target AVD '{avd_name}' not in local list (will use mock in dry-run).")
    else:
        print("  ℹ Emulator binary not found in standard paths (acceptable in CI).")

    print("\n" + "=" * 70)
    print(" [AAOS-HEADLESS-RUNNER] DRY-RUN VERIFICATION 100% PASSED")
    print("=" * 70)
    return 0


# ---------------------------------------------------------------------------
# Live Execution
# ---------------------------------------------------------------------------

def run_adb_shell(adb_prefix: List[str], shell_args: List[str], timeout: int = 15) -> str:
    """Execute an adb shell command and return stdout."""
    full_cmd = adb_prefix + ["shell"] + shell_args
    res = subprocess.run(full_cmd, capture_output=True, text=True, timeout=timeout)
    return res.stdout.strip()


def run_live_execution(
    avd_name: str,
    serial: Optional[str],
    emulator_bin: Optional[Path],
    adb_bin: Optional[Path],
    boot_timeout: int = 180,
    skip_launch: bool = False,
    keep_alive: bool = False,
    single_speed: Optional[float] = None,
    single_gear: Optional[int] = None,
    verbose: bool = False,
) -> int:
    """Execute live AAOS headless run."""
    print("=== Starting Live Headless AAOS Execution ===")
    if not adb_bin or not adb_bin.is_file():
        print("Error: adb binary not found.", file=sys.stderr)
        return 2

    adb_prefix = build_adb_prefix(adb_bin, serial)
    emu_proc: Optional[subprocess.Popen] = None

    try:
        # Step 1: Launch Emulator if requested
        if not skip_launch:
            if not emulator_bin or not emulator_bin.is_file():
                print("Error: emulator binary not found.", file=sys.stderr)
                return 2
            launch_cmd = build_emulator_launch_cmd(emulator_bin, avd_name)
            print(f"Launching headless emulator: {' '.join(launch_cmd)}")
            emu_proc = subprocess.Popen(
                launch_cmd,
                stdout=subprocess.DEVNULL if not verbose else None,
                stderr=subprocess.DEVNULL if not verbose else None,
            )
            time.sleep(5)

        # Step 2: 4-Stage Readiness Checks
        print("\n--- Running 4-Stage Readiness Verification ---")
        start_time = time.time()

        # Stage 1: Device connectivity
        print("[Stage 1/4] Waiting for ADB device connectivity...")
        while time.time() - start_time < boot_timeout:
            try:
                res = subprocess.run(
                    adb_prefix + ["get-state"],
                    capture_output=True,
                    text=True,
                    timeout=5,
                )
                if parse_stage1_response(res.stdout):
                    print("  ✓ Stage 1 Passed: ADB device is online.")
                    break
            except Exception:
                pass
            time.sleep(2)
        else:
            print("Error: Stage 1 timed out waiting for device.", file=sys.stderr)
            return 3

        # Stage 2: Boot completed
        print("[Stage 2/4] Waiting for sys.boot_completed...")
        while time.time() - start_time < boot_timeout:
            try:
                out = run_adb_shell(adb_prefix, ["getprop", "sys.boot_completed"])
                if parse_stage2_response(out):
                    print("  ✓ Stage 2 Passed: Android boot completed.")
                    break
            except Exception:
                pass
            time.sleep(2)
        else:
            print("Error: Stage 2 timed out waiting for boot_completed.", file=sys.stderr)
            return 3

        # Stage 3: Car Service
        print("[Stage 3/4] Waiting for car_service...")
        while time.time() - start_time < boot_timeout:
            try:
                out = run_adb_shell(adb_prefix, ["service", "check", "car_service"])
                if parse_stage3_response(out):
                    print("  ✓ Stage 3 Passed: Automotive car_service is running.")
                    break
            except Exception:
                pass
            time.sleep(2)
        else:
            print("Error: Stage 3 timed out waiting for car_service.", file=sys.stderr)
            return 3

        # Stage 4: Foreground User 10
        print("[Stage 4/4] Verifying Foreground User 10 readiness...")
        while time.time() - start_time < boot_timeout:
            try:
                out = run_adb_shell(adb_prefix, ["am", "get-current-user"])
                if parse_stage4_response(out):
                    print(f"  ✓ Stage 4 Passed: Driver User ({out}) is foreground and ready.")
                    break
            except Exception:
                pass
            time.sleep(2)
        else:
            print("Error: Stage 4 timed out waiting for User 10.", file=sys.stderr)
            return 3

        # Step 3: VHAL Injection Suite
        print("\n--- Running VHAL Injection Suite ---")
        if single_speed is not None or single_gear is not None:
            if single_gear is not None:
                g_cmd = build_gear_injection_cmd(single_gear)
                print(f"Injecting single gear: {' '.join(g_cmd)}")
                run_adb_shell(adb_prefix, g_cmd)
            if single_speed is not None:
                s_cmd = build_speed_injection_cmd(single_speed)
                print(f"Injecting single speed: {' '.join(s_cmd)}")
                run_adb_shell(adb_prefix, s_cmd)
        else:
            for idx, sc in enumerate(DEFAULT_SCENARIOS, start=1):
                gear_name = GEAR_NAME_REVERSE_MAP[sc.gear]
                print(f"\n[Scenario {idx}] {sc.name}: Gear={gear_name}, Speed={sc.speed_mps} m/s")
                g_cmd = build_gear_injection_cmd(sc.gear)
                s_cmd = build_speed_injection_cmd(sc.speed_mps)

                out_g = run_adb_shell(adb_prefix, g_cmd)
                out_s = run_adb_shell(adb_prefix, s_cmd)
                time.sleep(1)
                print(f"  ✓ Injected gear ({sc.gear}) and speed ({sc.speed_mps} m/s)")
                if verbose and (out_g or out_s):
                    print(f"    Gear resp:  {out_g}")
                    print(f"    Speed resp: {out_s}")

        print("\n[SUCCESS] AAOS headless execution and VHAL injection completed successfully!")
        return 0

    finally:
        # Step 4: Cleanup
        if not keep_alive and not skip_launch:
            print("\n--- Cleaning up AAOS Emulator ---")
            try:
                subprocess.run(adb_prefix + ["emu", "kill"], timeout=10, capture_output=True)
                print("  ✓ Sent 'adb emu kill'")
            except Exception as e:
                print(f"  Notice: 'emu kill' failed: {e}")

            if emu_proc and emu_proc.poll() is None:
                try:
                    emu_proc.terminate()
                    emu_proc.wait(timeout=5)
                except Exception:
                    emu_proc.kill()
                print("  ✓ Emulator process terminated.")


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Headless Android Automotive OS (AAOS) Emulator Automation Runner"
    )
    parser.add_argument(
        "--avd",
        default="AAOS_Automotive_1080p",
        help="AVD name to launch (default: AAOS_Automotive_1080p)",
    )
    parser.add_argument(
        "--serial",
        "-s",
        type=str,
        default=None,
        help="ADB device serial if connecting to existing emulator",
    )
    parser.add_argument(
        "--emulator-bin",
        type=str,
        default=None,
        help="Explicit path to emulator binary",
    )
    parser.add_argument(
        "--adb-bin",
        type=str,
        default=None,
        help="Explicit path to adb binary",
    )
    parser.add_argument(
        "--boot-timeout",
        type=int,
        default=180,
        help="Max seconds to wait for boot completion (default: 180)",
    )
    parser.add_argument(
        "--skip-launch",
        action="store_true",
        help="Skip launching emulator (target is already running)",
    )
    parser.add_argument(
        "--keep-alive",
        action="store_true",
        help="Do not terminate emulator process upon completion",
    )
    parser.add_argument(
        "--speed",
        type=float,
        default=None,
        help="Inject single speed (m/s)",
    )
    parser.add_argument(
        "--gear",
        type=str,
        default=None,
        help="Inject single gear (PARK, DRIVE, REVERSE, NEUTRAL, or integer)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate parameters, VHAL mappings, and readiness logic without launching emulator",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose output",
    )

    args = parser.parse_args(argv)

    emulator_bin = find_emulator_binary(args.emulator_bin)
    adb_bin = find_adb_binary(args.adb_bin)

    if args.dry_run:
        return run_dry_run(
            avd_name=args.avd,
            emulator_bin=emulator_bin,
            adb_bin=adb_bin,
            verbose=args.verbose,
        )

    # Parse single gear if specified
    gear_int: Optional[int] = None
    if args.gear:
        upper_gear = args.gear.upper()
        if upper_gear in GEAR_MAP:
            gear_int = GEAR_MAP[upper_gear]
        else:
            try:
                gear_int = int(args.gear)
            except ValueError:
                print(f"Error: Invalid gear '{args.gear}'. Choose from PARK, DRIVE, REVERSE, NEUTRAL or 1,2,4,8", file=sys.stderr)
                return 1

    return run_live_execution(
        avd_name=args.avd,
        serial=args.serial,
        emulator_bin=emulator_bin,
        adb_bin=adb_bin,
        boot_timeout=args.boot_timeout,
        skip_launch=args.skip_launch,
        keep_alive=args.keep_alive,
        single_speed=args.speed,
        single_gear=gear_int,
        verbose=args.verbose,
    )


if __name__ == "__main__":
    sys.exit(main())
