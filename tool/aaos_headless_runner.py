#!/usr/bin/env python3
"""Headless Android Automotive OS (AAOS) Emulator Automation Runner.

Automates Headless AAOS AVD execution and fail-closed observation:
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
from dataclasses import dataclass, field
import os
from pathlib import Path
import re
import shutil
import socket
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


@dataclass
class AdbResult:
    """Structured representation of an ADB command execution."""
    returncode: int
    stdout: str
    stderr: str
    command: List[str]

    @property
    def is_success(self) -> bool:
        """Check if command succeeded without error exit codes or error tokens."""
        if self.returncode != 0:
            return False
        combined = f"{self.stdout}\n{self.stderr}".lower()
        error_tokens = [
            "securityexception",
            "unknown command",
            "permission denial",
            "error: unknown",
            "can't find service",
            "not found",
        ]
        return not any(tok in combined for tok in error_tokens)

    def raise_for_status(self) -> None:
        """Raise RuntimeError if the command failed or emitted error tokens."""
        if not self.is_success:
            err_msg = self.stderr.strip() or self.stdout.strip()
            raise RuntimeError(
                f"ADB command failed (exit={self.returncode}): {' '.join(self.command)}\n"
                f"Error detail: {err_msg}"
            )

    def strip(self) -> str:
        return self.stdout.strip()

    def __str__(self) -> str:
        return self.stdout


@dataclass
class EmulatorInstance:
    """Represents an Android emulator instance with explicit lifecycle ownership."""
    pid: Optional[int] = None
    port: int = 5554
    serial: str = "emulator-5554"
    owned: bool = False
    process: Optional[subprocess.Popen] = None

    def cleanup(
        self,
        keep_alive: bool = False,
        adb_bin: Optional[Path] = None,
        timeout: int = 10,
    ) -> None:
        """Clean up emulator instance. Strictly preserves foreign/pre-existing emulators."""
        if keep_alive:
            print(f"Keep-alive active; preserving emulator: {self.serial}")
            return

        if not self.owned:
            print(f"Preserving foreign/pre-existing emulator: {self.serial}")
            return

        print(f"\n--- Cleaning up owned AAOS Emulator: {self.serial} (PID={self.pid}) ---")
        if adb_bin:
            try:
                cmd = [str(adb_bin), "-s", self.serial, "emu", "kill"]
                res = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
                if res.returncode == 0:
                    print(f"  ✓ Sent 'adb -s {self.serial} emu kill'")
                else:
                    print(f"  Notice: 'emu kill' on {self.serial} returned {res.returncode}")
            except Exception as e:
                print(f"  Notice: 'emu kill' on {self.serial} failed: {e}")

        if self.process:
            if self.process.poll() is None:
                try:
                    self.process.terminate()
                    self.process.wait(timeout=5)
                    print(f"  ✓ Emulator process (PID {self.pid}) terminated.")
                except subprocess.TimeoutExpired:
                    self.process.kill()
                    self.process.wait(timeout=5)
                    print(f"  ✓ Emulator process (PID {self.pid}) killed.")
                except Exception as e:
                    print(f"  Notice: terminating process failed: {e}")


def find_free_emulator_port(adb_bin: Optional[Path] = None) -> int:
    """Find an unused emulator console port (5554-5584, even ports)."""
    occupied_ports = set()
    if adb_bin and adb_bin.is_file():
        try:
            res = subprocess.run([str(adb_bin), "devices"], capture_output=True, text=True, timeout=5)
            for line in res.stdout.splitlines():
                parts = line.strip().split()
                if parts and parts[0].startswith("emulator-"):
                    try:
                        port = int(parts[0].split("-")[1])
                        occupied_ports.add(port)
                    except ValueError:
                        pass
        except Exception:
            pass

    for port in range(5554, 5586, 2):
        if port in occupied_ports:
            continue
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(("127.0.0.1", port))
                return port
        except OSError:
            occupied_ports.add(port)
            continue

    return 5584


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


def run_adb_shell(
    adb_prefix: List[str],
    shell_args: List[str],
    timeout: int = 15,
    check: bool = True,
) -> AdbResult:
    """Execute an adb shell command and return structured AdbResult."""
    full_cmd = adb_prefix + ["shell"] + shell_args
    res = subprocess.run(full_cmd, capture_output=True, text=True, timeout=timeout)
    result = AdbResult(
        returncode=res.returncode,
        stdout=res.stdout.strip(),
        stderr=res.stderr.strip(),
        command=full_cmd,
    )
    if check:
        result.raise_for_status()
    return result


def parse_stage4_response(output: str) -> bool:
    """Stage 4: Verify foreground automotive user (User 10) is active and unlocked."""
    cleaned = output.strip()
    lowered = output.lower()
    if "running_locked" in lowered or ("locked" in lowered and "unlocked" not in lowered):
        return False
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


def parse_user_unlocked_response(output: str) -> bool:
    """Verify User 10 is unlocked (from 'am is-user-unlocked 10' or 'dumpsys user')."""
    cleaned = output.strip().lower()
    if "running_locked" in cleaned or ("locked" in cleaned and "unlocked" not in cleaned):
        return False
    return cleaned == "true" or "running_unlocked" in cleaned or "is unlocked" in cleaned


def parse_template_host_response(output: str) -> bool:
    """Verify Car App Template Host feature is available."""
    cleaned = output.strip().lower()
    return "android.software.car.templates_host" in cleaned


def parse_app_package_ready(output: str) -> bool:
    """Verify automotive target application package is installed and ready."""
    cleaned = output.strip().lower()
    return "com.cbstudio.telltale.carproto.aaos" in cleaned


def verify_stage4_readiness(
    user_output: str,
    unlocked_output: str,
    features_output: str,
    package_output: str,
) -> bool:
    """Verify all Stage 4 readiness conditions simultaneously."""
    user_ok = parse_stage4_response(user_output) and (
        parse_user_unlocked_response(unlocked_output) or parse_user_unlocked_response(user_output)
    )
    template_ok = parse_template_host_response(features_output)
    app_ok = parse_app_package_ready(package_output)
    return user_ok and template_ok and app_ok


def parse_vhal_speed_from_dumpsys(output: str) -> Optional[float]:
    """Extract speed value from dumpsys car_service CarPropertyService output."""
    if not output:
        return None
    patterns = [
        r'(?:0x11600207|291504647)[^\n]*?\b(?:value[s]?|floatValues|values|val)\s*[:=]?\s*\[?\s*([-+]?[0-9]*\.?[0-9]+)',
        r'\bPERF_VEHICLE_SPEED\s*[:=]\s*([-+]?[0-9]*\.?[0-9]+)',
        r'(?:0x11600207|291504647)\s+([-+]?[0-9]+\.[0-9]+)',
    ]
    for pat in patterns:
        m = re.search(pat, output, re.IGNORECASE)
        if m:
            try:
                return float(m.group(1))
            except ValueError:
                continue
    return None


def parse_vhal_gear_from_dumpsys(output: str) -> Optional[int]:
    """Extract gear value from dumpsys car_service CarPropertyService output."""
    if not output:
        return None
    patterns = [
        r'(?:0x11400400|289408000)[^\n]*?\b(?:value[s]?|int32Values|values|val)\s*[:=]?\s*\[?\s*([0-9]+)',
        r'\bGEAR_SELECTION\s*[:=]\s*([0-9]+)',
        r'(?:0x11400400|289408000)\s+([0-9]+)',
    ]
    for pat in patterns:
        m = re.search(pat, output, re.IGNORECASE)
        if m:
            try:
                return int(m.group(1))
            except ValueError:
                continue
    return None


class AaosStateObserver:
    """Observes AAOS VHAL and Car App motion/screen states via dumpsys and logcat."""
    def __init__(self, adb_prefix: List[str]):
        self.adb_prefix = adb_prefix
        self._dtc_origin_ui: Optional[str] = None

    def get_vhal_property_speed(self) -> Optional[float]:
        """Query current VHAL speed from CarPropertyService."""
        res = run_adb_shell(
            self.adb_prefix,
            ["dumpsys", "car_service", "--services", "CarPropertyService"],
            check=False,
        )
        return parse_vhal_speed_from_dumpsys(res.stdout)

    def get_vhal_property_gear(self) -> Optional[int]:
        """Query current VHAL gear from CarPropertyService."""
        res = run_adb_shell(
            self.adb_prefix,
            ["dumpsys", "car_service", "--services", "CarPropertyService"],
            check=False,
        )
        return parse_vhal_gear_from_dumpsys(res.stdout)

    def observe_app_ui(self) -> str:
        """Return externally observable app UI text/content descriptions, or empty."""
        run_adb_shell(
            self.adb_prefix,
            ["rm", "-f", "/data/local/tmp/telltale-aa08-ui.xml"],
            check=False,
        )
        dump_result = run_adb_shell(
            self.adb_prefix,
            ["uiautomator", "dump", "/data/local/tmp/telltale-aa08-ui.xml"],
            check=False,
        )
        if not dump_result.is_success:
            return ""
        result = run_adb_shell(
            self.adb_prefix,
            ["cat", "/data/local/tmp/telltale-aa08-ui.xml"],
            check=False,
        )
        return result.stdout if result.returncode == 0 else ""

    @staticmethod
    def _is_telltale_ui(ui: str) -> bool:
        return "telltale" in ui.lower()

    @classmethod
    def _is_unique_dtc_screen(cls, ui: str) -> bool:
        lowered = ui.lower()
        return cls._is_telltale_ui(lowered) and "vehicle health" not in lowered and any(
            marker in lowered
            for marker in ("diagnostic codes", "diagnostic trouble codes", "dtc summary")
        )

    def navigate_to_dtc_screen(self, timeout: float = 5.0) -> bool:
        """Tap a uniquely labelled DTC entry and capture the resulting DTC screen."""
        ui = self.observe_app_ui()
        match = re.search(
            r'(?:text|content-desc)="(?:Diagnostic Codes|Diagnostic Trouble Codes)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',
            ui,
            re.IGNORECASE,
        )
        if match is None:
            return False
        x1, y1, x2, y2 = (int(value) for value in match.groups())
        tap = run_adb_shell(
            self.adb_prefix,
            ["input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2)],
            check=False,
        )
        if not tap.is_success:
            return False
        deadline = time.time() + timeout
        while time.time() < deadline:
            candidate = self.observe_app_ui()
            if candidate != ui and self._is_unique_dtc_screen(candidate):
                self._dtc_origin_ui = candidate
                return True
            time.sleep(0.25)
        return False

    def observe_motion_state(self, timeout: float = 5.0) -> str:
        """Observe application motion state from app UI/log output.

        VHAL values are injection/input evidence only. They never establish that
        the application consumed the value or enforced a safety decision.
        
        Returns:
            'STATIONARY', 'MOVING', or 'UNKNOWN'
        """
        ui_lower = self.observe_app_ui().lower()
        if not self._is_telltale_ui(ui_lower):
            return "UNKNOWN"
        if any(token in ui_lower for token in ("vehicle moving", "driving", "motion blocked")):
            return "MOVING"
        if any(token in ui_lower for token in ("vehicle stationary", "parked", "stationary")):
            return "STATIONARY"

        return "UNKNOWN"

    def verify_sample_received(
        self,
        expected_speed: float,
        tolerance: float = 0.1,
        timeout: float = 5.0,
    ) -> bool:
        """Verify both the exact VHAL sample and the application's motion state."""
        expected_motion = "STATIONARY" if expected_speed == 0.0 else "MOVING"

        def sample_matches() -> bool:
            actual_speed = self.get_vhal_property_speed()
            if actual_speed is None or abs(actual_speed - expected_speed) > tolerance:
                return False
            return self.observe_motion_state() == expected_motion

        start = time.time()
        while time.time() - start < timeout:
            if sample_matches():
                return True
            time.sleep(0.5)

        return sample_matches()

    def verify_dtc_accessible(self, timeout: float = 5.0) -> bool:
        """Verify visible DTC UI, not merely a stationary VHAL input."""
        ui = self.observe_app_ui().lower()
        if not self._is_telltale_ui(ui):
            return False
        has_dtc = self._is_unique_dtc_screen(ui)
        blocked = any(token in ui for token in ("blocked", "unavailable while driving", "park to view"))
        return has_dtc and not blocked

    def verify_autopop_occurred(self, timeout: float = 5.0) -> bool:
        """Verify SAFE-06: Auto-pop returned vehicle from DTC screen to safety screen upon motion."""
        motion = self.observe_motion_state(timeout=timeout)
        if motion != "MOVING":
            return False

        origin = self._dtc_origin_ui
        if origin is None or not self._is_unique_dtc_screen(origin):
            return False

        ui = self.observe_app_ui().lower()
        if not self._is_telltale_ui(ui):
            return False
        health_visible = any(token in ui for token in ("vehicle health", "powertrain health"))
        return health_visible and not self._is_unique_dtc_screen(ui) and ui != origin.lower()

    def verify_dtc_blocked(self, timeout: float = 5.0) -> bool:
        """Verify SAFE-02 / AA05-15: DTC access is blocked while moving (including reverse)."""
        ui = self.observe_app_ui().lower()
        if not self._is_telltale_ui(ui):
            return False
        return any(token in ui for token in ("blocked", "unavailable while driving", "park to view"))


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

    # Stage 4: Foreground User 10, Template Host, Target App
    assert parse_stage4_response("10\n") is True
    assert parse_stage4_response("UserInfo{10:Driver:13}\n") is True
    assert parse_stage4_response("0\n") is False
    assert parse_stage4_response("User 10: RUNNING_LOCKED\n") is False
    assert parse_user_unlocked_response("true\n") is True
    assert parse_user_unlocked_response("false\n") is False
    assert parse_user_unlocked_response("User 10: RUNNING_LOCKED\n") is False
    assert parse_template_host_response("feature:android.software.car.templates_host\n") is True
    assert parse_template_host_response("feature:android.hardware.wifi\n") is False
    assert parse_app_package_ready("package:/data/app/test/com.cbstudio.telltale.carproto.aaos/base.apk\n") is True
    assert parse_app_package_ready("") is False
    assert verify_stage4_readiness("10", "true", "feature:android.software.car.templates_host", "com.cbstudio.telltale.carproto.aaos") is True
    assert verify_stage4_readiness("10", "false", "feature:android.software.car.templates_host", "com.cbstudio.telltale.carproto.aaos") is False
    print("  ✓ Stage 4 (Driver User 10, Host & App readiness): validated all unlock & feature gates.")

    # 4. Validate AdbResult & Error Detection
    print("\n[Phase 4] Validating AdbResult & Error Token Interception...")
    ok_res = AdbResult(0, "success", "", ["adb", "shell"])
    assert ok_res.is_success is True
    err_res = AdbResult(19, "", "error", ["adb", "shell"])
    assert err_res.is_success is False
    sec_res = AdbResult(0, "SecurityException: Permission Denial", "", ["adb", "shell"])
    assert sec_res.is_success is False
    unk_res = AdbResult(0, "Unknown command: inject-vhal-event", "", ["adb", "shell"])
    assert unk_res.is_success is False
    print("  ✓ AdbResult: detected exit code != 0, SecurityException, and Unknown command.")

    # 5. Validate VHAL Dumpsys Parsers
    print("\n[Phase 5] Validating VHAL Dumpsys Parsers...")
    sample_dumpsys = "Property: 0x11600207, Area: 0, Value: 13.89\nProperty: 0x11400400, Area: 0, Value: 4"
    assert parse_vhal_speed_from_dumpsys(sample_dumpsys) == 13.89
    assert parse_vhal_gear_from_dumpsys(sample_dumpsys) == 4
    print("  ✓ VHAL Dumpsys: speed 13.89 m/s and gear PARK (4) parsed correctly.")

    # 6. Validate EmulatorInstance Lifecycle Isolation
    print("\n[Phase 6] Validating EmulatorInstance Isolation & Port Allocation...")
    free_port = find_free_emulator_port()
    assert 5554 <= free_port <= 5584
    assert free_port % 2 == 0
    foreign = EmulatorInstance(serial="emulator-5554", owned=False)
    foreign.cleanup(keep_alive=False)  # Must be a no-op that preserves foreign emulator
    print(f"  ✓ Port allocated: {free_port}, Foreign emulator preserved successfully.")

    # 7. Validate VHAL Test Scenarios
    print("\n[Phase 7] Validating VHAL Injection Matrix...")
    for idx, sc in enumerate(DEFAULT_SCENARIOS, start=1):
        gear_str = GEAR_NAME_REVERSE_MAP[sc.gear]
        s_cmd = build_speed_injection_cmd(sc.speed_mps)
        g_cmd = build_gear_injection_cmd(sc.gear)
        print(f"  ✓ Scenario {idx}: {sc.name:<18} Gear={gear_str:<12} Speed={sc.speed_mps:>6} m/s [{sc.expected_motion}]")
        if verbose:
            print(f"      Gear cmd:  adb shell {' '.join(g_cmd)}")
            print(f"      Speed cmd: adb shell {' '.join(s_cmd)}")
            print(f"      Intent:    {sc.description}")

    # 8. Environment & Tool Discovery Check
    print("\n[Phase 8] Environment & Local Tool Inspection...")
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
    print(" [AAOS-HEADLESS-RUNNER] DRY-RUN TOOLING VALIDATION COMPLETE; LIVE ACCEPTANCE NOT EXECUTED")
    print("=" * 70)
    return 0


# ---------------------------------------------------------------------------
# Live Execution
# ---------------------------------------------------------------------------

def run_live_execution(
    avd_name: str,
    serial: Optional[str] = None,
    emulator_bin: Optional[Path] = None,
    adb_bin: Optional[Path] = None,
    boot_timeout: int = 180,
    skip_launch: bool = False,
    keep_alive: bool = False,
    single_speed: Optional[float] = None,
    single_gear: Optional[int] = None,
    verbose: bool = False,
    observer: Optional[AaosStateObserver] = None,
) -> int:
    """Execute live AAOS headless run with strict error interception and state observation."""
    print("=== Starting Live Headless AAOS Execution ===")
    if not adb_bin or not adb_bin.is_file():
        print("Error: adb binary not found.", file=sys.stderr)
        return 2

    instance = EmulatorInstance()
    if skip_launch:
        instance.serial = serial or "emulator-5554"
        instance.owned = False
    else:
        if serial:
            instance.serial = serial
            try:
                instance.port = int(serial.split("-")[1])
            except (IndexError, ValueError):
                instance.port = find_free_emulator_port(adb_bin)
        else:
            instance.port = find_free_emulator_port(adb_bin)
            instance.serial = f"emulator-{instance.port}"
        instance.owned = True

    # All ADB operations strictly target instance.serial
    adb_prefix = build_adb_prefix(adb_bin, instance.serial)

    try:
        # Step 1: Launch Emulator if requested
        if not skip_launch:
            if not emulator_bin or not emulator_bin.is_file():
                print("Error: emulator binary not found.", file=sys.stderr)
                return 2
            launch_cmd = build_emulator_launch_cmd(
                emulator_bin,
                avd_name,
                extra_args=["-port", str(instance.port)],
            )
            print(f"Launching headless emulator: {' '.join(launch_cmd)}")
            instance.process = subprocess.Popen(
                launch_cmd,
                stdout=subprocess.DEVNULL if not verbose else None,
                stderr=subprocess.DEVNULL if not verbose else None,
            )
            instance.pid = instance.process.pid
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
                out = run_adb_shell(adb_prefix, ["getprop", "sys.boot_completed"], check=False)
                if parse_stage2_response(out.stdout):
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
                out = run_adb_shell(adb_prefix, ["service", "check", "car_service"], check=False)
                if parse_stage3_response(out.stdout):
                    print("  ✓ Stage 3 Passed: Automotive car_service is running.")
                    break
            except Exception:
                pass
            time.sleep(2)
        else:
            print("Error: Stage 3 timed out waiting for car_service.", file=sys.stderr)
            return 3

        # Stage 4: Foreground User 10, Template Host, and package installation.
        # Application observation happens below and must fail closed if absent.
        print("[Stage 4/4] Verifying User 10 unlocked, Template Host, and package installation...")
        while time.time() - start_time < boot_timeout:
            try:
                u_out = run_adb_shell(adb_prefix, ["am", "get-current-user"], check=False).stdout
                unlocked_out = run_adb_shell(adb_prefix, ["am", "is-user-unlocked", "10"], check=False).stdout
                feat_out = run_adb_shell(adb_prefix, ["pm", "list", "features"], check=False).stdout
                pkg_out = run_adb_shell(
                    adb_prefix,
                    ["pm", "path", "com.cbstudio.telltale.carproto.aaos"],
                    check=False,
                ).stdout

                if verify_stage4_readiness(u_out, unlocked_out, feat_out, pkg_out):
                    print("  ✓ Stage 4 Passed: Driver User 10 unlocked, Template Host ready, package installed.")
                    break
                elif verbose:
                    if not (parse_stage4_response(u_out) and (parse_user_unlocked_response(unlocked_out) or parse_user_unlocked_response(u_out))):
                        print("    Waiting for User 10 unlock...")
                    if not parse_template_host_response(feat_out):
                        print("    Waiting for Template Host feature...")
                    if not parse_app_package_ready(pkg_out):
                        print("    Waiting for App package ready...")
            except Exception:
                pass
            time.sleep(2)
        else:
            print("Error: Stage 4 timed out waiting for User 10, Template Host, or App readiness.", file=sys.stderr)
            return 3

        # Step 3: VHAL Injection Suite with End-to-End Observation Assertions
        print("\n--- Running VHAL Injection Suite with State Observation ---")
        if observer is None:
            observer = AaosStateObserver(adb_prefix)

        if single_speed is not None or single_gear is not None:
            if single_gear is not None:
                g_cmd = build_gear_injection_cmd(single_gear)
                print(f"Injecting single gear: {' '.join(g_cmd)}")
                run_adb_shell(adb_prefix, g_cmd, check=True)
            if single_speed is not None:
                s_cmd = build_speed_injection_cmd(single_speed)
                print(f"Injecting single speed: {' '.join(s_cmd)}")
                run_adb_shell(adb_prefix, s_cmd, check=True)
        else:
            for idx, sc in enumerate(DEFAULT_SCENARIOS, start=1):
                gear_name = GEAR_NAME_REVERSE_MAP[sc.gear]
                print(f"\n[Scenario {idx}] {sc.name}: Gear={gear_name}, Speed={sc.speed_mps} m/s")

                if sc.speed_mps < 0:
                    reset_gear_cmd = build_gear_injection_cmd(GEAR_PARK)
                    reset_speed_cmd = build_speed_injection_cmd(SPEED_STATIONARY)
                    run_adb_shell(adb_prefix, reset_gear_cmd, check=True)
                    run_adb_shell(adb_prefix, reset_speed_cmd, check=True)
                    time.sleep(1)
                    if not observer.verify_sample_received(SPEED_STATIONARY, timeout=3.0):
                        raise RuntimeError(
                            f"Scenario {idx} ({sc.name}) FAIL: stationary reset was not freshly verified before reverse"
                        )
                    if observer.observe_motion_state() != "STATIONARY":
                        raise RuntimeError(
                            f"Scenario {idx} ({sc.name}) FAIL: application did not report STATIONARY before reverse"
                        )
                    print("  ✓ Fresh stationary reset verified before reverse injection")

                g_cmd = build_gear_injection_cmd(sc.gear)
                s_cmd = build_speed_injection_cmd(sc.speed_mps)

                # 1. Inject gear and speed (check=True ensures failure on exit != 0 or error tokens)
                out_g = run_adb_shell(adb_prefix, g_cmd, check=True)
                out_s = run_adb_shell(adb_prefix, s_cmd, check=True)
                print(f"  ✓ Injected gear ({sc.gear}) and speed ({sc.speed_mps} m/s)")
                if verbose:
                    print(f"    Gear resp:  {out_g.stdout}")
                    print(f"    Speed resp: {out_s.stdout}")

                time.sleep(1)

                # 2. Verify sample reception
                if not observer.verify_sample_received(sc.speed_mps, timeout=3.0):
                    motion = observer.observe_motion_state()
                    raise RuntimeError(
                        f"Scenario {idx} ({sc.name}) FAIL: Speed injection {sc.speed_mps} m/s not freshly received by application (observed: {motion}, expected: {sc.expected_motion})"
                    )

                # 3. End-to-End State Observation Assertions
                observed_motion = observer.observe_motion_state()
                if sc.expected_motion == "STATIONARY":
                    if observed_motion != "STATIONARY":
                        raise RuntimeError(
                            f"Scenario {idx} ({sc.name}) FAIL: Expected STATIONARY motion, got {observed_motion}"
                        )
                    if not observer.navigate_to_dtc_screen():
                        raise RuntimeError(
                            f"Scenario {idx} ({sc.name}) FAIL: could not navigate to and observe the unique Diagnostic Codes screen while stationary"
                        )
                    print(f"  ✓ Observation verified: Motion={observed_motion}, Diagnostic Codes screen observed")

                elif sc.expected_motion == "MOVING":
                    if observed_motion != "MOVING":
                        raise RuntimeError(
                            f"Scenario {idx} ({sc.name}) FAIL: Expected MOVING motion, got {observed_motion}"
                        )
                    if sc.speed_mps > 0:
                        if not observer.verify_autopop_occurred():
                            raise RuntimeError(
                                f"Scenario {idx} ({sc.name}) FAIL: Auto-Pop did not navigate back to safety screen upon motion"
                            )
                        print(f"  ✓ Observation verified: Motion={observed_motion}, Auto-Pop Triggered=True")
                    elif sc.speed_mps < 0:
                        if not observer.verify_dtc_blocked():
                            raise RuntimeError(
                                f"Scenario {idx} ({sc.name}) FAIL: Reverse speed must strictly block DTC access"
                            )
                        print(f"  ✓ Observation verified: Motion={observed_motion}, DTC Blocked=True")

        print("\n[SUCCESS] AAOS headless execution, VHAL injection, and state observation completed successfully!")
        return 0

    except Exception as e:
        print(f"Error during live execution: {e}", file=sys.stderr)
        return 1

    finally:
        # Step 4: Cleanup (Strictly preserves foreign/pre-existing emulators)
        instance.cleanup(keep_alive=keep_alive, adb_bin=adb_bin)


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
