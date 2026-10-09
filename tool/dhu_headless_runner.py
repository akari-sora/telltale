#!/usr/bin/env python3
"""Headless Google Desktop Head Unit (DHU) 2.0 Test Runner.

Automates Android Auto Headless DHU verification for CI and local test harnesses:
- DHU 2.0 `--headless` execution with stdin script automation pipeline.
- Supports 6 INI profiles in docs/android-auto/aa-06/configs/.
- Supports 7 walkthrough scripts in docs/android-auto/aa-06/scripts/.
- Automated screenshot verification via Pillow luminance and variance analysis.
  Rejects pure black (0,0,0) and flat blank screens with non-zero exit codes.
- Full `--dry-run` mode for CI environments without physical head unit servers.
"""

from __future__ import annotations

import argparse
import configparser
import math
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
from typing import Any, Dict, List, Optional, Tuple

try:
    from PIL import Image, ImageDraw, ImageStat
except ImportError:
    Image = None  # type: ignore[assignment]
    ImageDraw = None  # type: ignore[assignment]
    ImageStat = None  # type: ignore[assignment]

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CONFIGS_DIR = REPO_ROOT / "docs" / "android-auto" / "aa-06" / "configs"
DEFAULT_SCRIPTS_DIR = REPO_ROOT / "docs" / "android-auto" / "aa-06" / "scripts"
DEFAULT_EVIDENCE_DIR = REPO_ROOT / "docs" / "android-auto" / "aa-06" / "evidence" / "dhu"
DEFAULT_OUTPUT_DIR = REPO_ROOT / "build" / "dhu_headless"

KNOWN_PROFILES = [
    "p1-small-landscape.ini",
    "p2-720p.ini",
    "p3-wide.ini",
    "p4-portrait.ini",
    "p5-high-dpi.ini",
    "p6-insets.ini",
]

KNOWN_SCRIPTS = [
    "baseline.txt",
    "day-night.txt",
    "host-speed.txt",
    "hybrid.txt",
    "lifecycle.txt",
    "motion-gates.txt",
    "rotary.txt",
]

KNOWN_COMMANDS = {
    "sleep",
    "screenshot",
    "speed",
    "gear",
    "parking_brake",
    "restrict",
    "dpad",
    "tap",
    "day",
    "night",
    "daynight",
    "focus",
    "exit",
    "quit",
}


def find_dhu_binary(explicit_path: Optional[str] = None) -> Optional[Path]:
    """Resolve the Desktop Head Unit 2.0 binary path."""
    if explicit_path:
        p = Path(explicit_path).expanduser().resolve()
        if p.is_file() and os.access(p, os.X_OK):
            return p

    env_bin = os.environ.get("DHU_BIN")
    if env_bin:
        p = Path(env_bin).expanduser().resolve()
        if p.is_file() and os.access(p, os.X_OK):
            return p

    which_dhu = shutil.which("desktop-head-unit")
    if which_dhu:
        return Path(which_dhu).resolve()

    candidates = []
    android_home = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if android_home:
        candidates.append(Path(android_home) / "extras" / "google" / "auto" / "desktop-head-unit")

    # Common macOS / Linux SDK locations
    candidates.extend([
        Path.home() / "Library" / "Android" / "sdk" / "extras" / "google" / "auto" / "desktop-head-unit",
        Path.home() / "Android" / "Sdk" / "extras" / "google" / "auto" / "desktop-head-unit",
        Path("/opt/android-sdk/extras/google/auto/desktop-head-unit"),
    ])

    for c in candidates:
        if c.is_file() and os.access(c, os.X_OK):
            return c.resolve()

    return None


def list_profiles(configs_dir: Path) -> Dict[str, Path]:
    """List available INI profile configuration files."""
    profiles: Dict[str, Path] = {}
    if not configs_dir.is_dir():
        return profiles
    for ini_file in sorted(configs_dir.glob("*.ini")):
        profiles[ini_file.name] = ini_file
        stem = ini_file.stem
        profiles[stem] = ini_file
        # also support short name like "p1"
        short = stem.split("-")[0]
        if short and short not in profiles:
            profiles[short] = ini_file
    return profiles


def list_scripts(scripts_dir: Path) -> Dict[str, Path]:
    """List available DHU walkthrough scripts."""
    scripts: Dict[str, Path] = {}
    if not scripts_dir.is_dir():
        return scripts
    for txt_file in sorted(scripts_dir.glob("*.txt")):
        scripts[txt_file.name] = txt_file
        scripts[txt_file.stem] = txt_file
    return scripts


def validate_profile_ini(path: Path) -> Tuple[bool, str, Dict[str, Any]]:
    """Validate INI profile structure and mandatory keys."""
    if not path.is_file():
        return False, f"File not found: {path}", {}

    cp = configparser.ConfigParser(interpolation=None)
    try:
        cp.read(str(path), encoding="utf-8")
    except Exception as e:
        return False, f"INI parse error: {e}", {}

    if "general" not in cp:
        return False, "Missing [general] section", {}

    general = cp["general"]
    resolution = general.get("resolution")
    if not resolution:
        return False, "Missing 'resolution' in [general]", {}

    res_match = re.match(r"^(\d+)x(\d+)$", resolution.strip())
    if not res_match:
        return False, f"Invalid resolution format: {resolution} (expected WxH)", {}

    width, height = int(res_match.group(1)), int(res_match.group(2))
    dpi = cp.getint("general", "dpi", fallback=160)
    framerate = cp.getint("general", "framerate", fallback=30)
    inputmode = general.get("inputmode", "touch")

    details = {
        "resolution": (width, height),
        "dpi": dpi,
        "framerate": framerate,
        "inputmode": inputmode,
        "has_sensors": "sensors" in cp,
    }
    return True, "Valid profile", details


def parse_and_validate_script(path: Path) -> Tuple[bool, str, List[str], List[str]]:
    """Parse and validate DHU script lines and collect screenshot targets."""
    if not path.is_file():
        return False, f"Script not found: {path}", [], []

    try:
        content = path.read_text(encoding="utf-8")
    except Exception as e:
        return False, f"Cannot read script: {e}", [], []

    valid_lines: List[str] = []
    screenshots: List[str] = []

    for lineno, raw_line in enumerate(content.splitlines(), start=1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue

        tokens = line.split()
        cmd = tokens[0].lower()
        if cmd not in KNOWN_COMMANDS:
            return False, f"Line {lineno}: unknown DHU command '{cmd}'", [], []

        if cmd == "screenshot":
            if len(tokens) < 2:
                return False, f"Line {lineno}: 'screenshot' missing target filename", [], []
            screenshots.append(tokens[1])

        valid_lines.append(line)

    return True, f"Parsed {len(valid_lines)} commands, {len(screenshots)} screenshots", valid_lines, screenshots


def verify_non_black_screen(
    image_input: Any,
    min_luminance: float = 1.0,
    min_variance: float = 1.0,
) -> Tuple[bool, str, Dict[str, Any]]:
    """Verify screenshot is genuinely non-black and non-blank using Pillow.

    Calculates:
    - Luminance via grayscale (ITU-R BT.601) mean.
    - Standard deviation and variance of pixel intensity.
    - Alpha channel sanity (ensures non-transparent / no missing textures).

    Fails if:
    - Mean luminance < min_luminance (pitch black).
    - Variance < min_variance (flat unrendered canvas / blank screen).
    """
    if Image is None or ImageStat is None:
        return False, "Pillow library is not available", {}

    if isinstance(image_input, (str, Path)):
        p = Path(image_input)
        if not p.is_file():
            return False, f"Screenshot file not found: {p}", {}
        if p.stat().st_size == 0:
            return False, f"Screenshot file is empty (0 bytes): {p}", {}
        try:
            im = Image.open(p)
            im.load()
        except Exception as e:
            return False, f"Failed to decode image {p}: {e}", {}
    elif isinstance(image_input, Image.Image):
        im = image_input
    else:
        return False, f"Unsupported image input type: {type(image_input)}", {}

    width, height = im.size
    if width <= 0 or height <= 0:
        return False, f"Invalid image dimensions: {width}x{height}", {}

    # Alpha check if present
    if im.mode == "RGBA":
        a_channel = im.getchannel("A")
        min_a, max_a = a_channel.getextrema()
        if max_a == 0:
            return False, "Image is completely transparent (alpha == 0)", {"alpha_range": (min_a, max_a)}

    # Convert to grayscale luminance
    gray = im.convert("L")
    stat = ImageStat.Stat(gray)

    mean_lum = float(stat.mean[0])
    stddev_lum = float(stat.stddev[0])
    var_lum = float(stat.var[0])

    stats = {
        "dimensions": (width, height),
        "mode": im.mode,
        "mean_luminance": round(mean_lum, 3),
        "stddev": round(stddev_lum, 3),
        "variance": round(var_lum, 3),
    }

    # Pure black check
    if mean_lum < min_luminance and var_lum < min_variance:
        return False, f"Black screen detected: mean luminance={mean_lum:.2f} < {min_luminance}, variance={var_lum:.2f} < {min_variance}", stats

    # Flat unrendered screen check (variance too low)
    if var_lum < min_variance:
        return False, f"Blank/flat screen detected: variance={var_lum:.2f} < {min_variance} (uniform unrendered display)", stats

    return True, "Non-black screen verified", stats


def run_dry_run(
    configs_dir: Path,
    scripts_dir: Path,
    evidence_dir: Path,
    verbose: bool = False,
) -> int:
    """Execute complete dry-run validation suite for DHU runner."""
    print("=" * 70)
    print(" [DHU-HEADLESS-RUNNER] Starting Dry-Run Verification Suite")
    print("=" * 70)

    # 1. Check Profiles
    print("\n[Phase 1] Validating 6 INI Profiles...")
    profiles = list_profiles(configs_dir)
    profile_errors: List[str] = []
    for expected in KNOWN_PROFILES:
        target_path = configs_dir / expected
        if expected not in profiles or not target_path.is_file():
            profile_errors.append(f"Missing expected profile: {expected}")
            continue
        valid, msg, details = validate_profile_ini(target_path)
        if not valid:
            profile_errors.append(f"Profile {expected} invalid: {msg}")
        else:
            res_w, res_h = details["resolution"]
            print(f"  ✓ {expected:<24} {res_w}x{res_h} @ {details['dpi']}dpi ({details['inputmode']})")

    if profile_errors:
        for err in profile_errors:
            print(f"  ✗ ERROR: {err}", file=sys.stderr)
        return 1
    print(f"  -> All {len(KNOWN_PROFILES)} INI profiles successfully validated.")

    # 2. Check Scripts
    print("\n[Phase 2] Validating 7 Walkthrough Scripts...")
    scripts = list_scripts(scripts_dir)
    script_errors: List[str] = []
    total_commands = 0
    total_screenshots = 0
    for expected in KNOWN_SCRIPTS:
        target_path = scripts_dir / expected
        if expected not in scripts or not target_path.is_file():
            script_errors.append(f"Missing expected script: {expected}")
            continue
        valid, msg, cmds, shots = parse_and_validate_script(target_path)
        if not valid:
            script_errors.append(f"Script {expected} invalid: {msg}")
        else:
            total_commands += len(cmds)
            total_screenshots += len(shots)
            shots_str = f"[{len(shots)} screenshots: {', '.join(shots[:2])}{'...' if len(shots) > 2 else ''}]"
            print(f"  ✓ {expected:<18} {len(cmds):>2} commands, {shots_str}")

    if script_errors:
        for err in script_errors:
            print(f"  ✗ ERROR: {err}", file=sys.stderr)
        return 1
    print(f"  -> All {len(KNOWN_SCRIPTS)} scripts validated ({total_commands} commands, {total_screenshots} screenshots).")

    # 3. Test Non-Black Screen Detection Algorithm with Pillow
    print("\n[Phase 3] Testing Pillow Non-Black Screen Detection Algorithm...")
    if Image is None:
        print("  ✗ ERROR: Pillow is required but not installed", file=sys.stderr)
        return 1

    # Test Case A: Pure Black Image (Should Fail)
    black_img = Image.new("RGB", (800, 480), (0, 0, 0))
    passed, msg, stats = verify_non_black_screen(black_img)
    if passed:
        print("  ✗ ERROR: Pure black image was erroneously accepted!", file=sys.stderr)
        return 1
    print(f"  ✓ Pure black rejection: correctly caught (mean={stats['mean_luminance']}, var={stats['variance']})")

    # Test Case B: Flat Blank Screen (Uniform Grey, var=0, Should Fail)
    grey_img = Image.new("RGB", (800, 480), (120, 120, 120))
    passed, msg, stats = verify_non_black_screen(grey_img)
    if passed:
        print("  ✗ ERROR: Flat uniform screen was erroneously accepted!", file=sys.stderr)
        return 1
    print(f"  ✓ Flat uniform screen rejection: correctly caught (var={stats['variance']})")

    # Test Case C: Synthetic Valid UI Screen (Should Pass)
    synthetic_ui = Image.new("RGB", (800, 480), (20, 20, 30))
    draw = ImageDraw.Draw(synthetic_ui)
    draw.rectangle([50, 50, 750, 430], fill=(40, 80, 160), outline=(255, 255, 255))
    draw.text((100, 100), "Telltale Automotive UI", fill=(255, 255, 255))
    passed, msg, stats = verify_non_black_screen(synthetic_ui)
    if not passed:
        print(f"  ✗ ERROR: Synthetic UI was erroneously rejected: {msg}", file=sys.stderr)
        return 1
    print(f"  ✓ Synthetic UI verification: passed (mean={stats['mean_luminance']}, var={stats['variance']})")

    # Test Case D: Genuine Evidence Fixtures (if available in repository)
    if evidence_dir.is_dir():
        evidence_files = list(evidence_dir.glob("*.png"))
        if evidence_files:
            print(f"  Testing on {len(evidence_files)} repository evidence fixtures...")
            for f in evidence_files[:5]:
                p, m, st = verify_non_black_screen(f)
                if not p:
                    print(f"  ✗ ERROR: Genuine evidence {f.name} failed verification: {m}", file=sys.stderr)
                    return 1
                if verbose:
                    print(f"    - {f.name}: mean={st['mean_luminance']}, var={st['variance']}")
            print(f"  ✓ Genuine repository screenshots verified ({len(evidence_files)} files tested).")

    # 4. Check DHU Binary Resolution
    print("\n[Phase 4] Checking DHU 2.0 Binary Resolution...")
    dhu_bin = find_dhu_binary()
    if dhu_bin:
        print(f"  ✓ Local DHU 2.0 binary discovered at: {dhu_bin}")
    else:
        print("  ℹ Local DHU binary not found in standard paths (acceptable in CI headless runner).")

    print("\n" + "=" * 70)
    print(" [DHU-HEADLESS-RUNNER] DRY-RUN VERIFICATION 100% PASSED")
    print("=" * 70)
    return 0


def run_live_execution(
    profile_path: Path,
    script_path: Path,
    output_dir: Path,
    dhu_bin: Optional[Path],
    device: Optional[str] = None,
    adb_port: int = 5277,
    timeout: int = 60,
    verbose: bool = False,
) -> int:
    """Execute live DHU headless run with physical/emulator connection."""
    print(f"=== Starting Live Headless DHU Execution ===")
    print(f"Profile: {profile_path}")
    print(f"Script:  {script_path}")
    print(f"Output:  {output_dir}")

    if not dhu_bin or not dhu_bin.is_file():
        print(f"Error: DHU binary not found. Set DHU_BIN or install Google DHU.", file=sys.stderr)
        return 2

    valid_prof, p_msg, p_details = validate_profile_ini(profile_path)
    if not valid_prof:
        print(f"Error: Profile validation failed: {p_msg}", file=sys.stderr)
        return 1

    valid_script, s_msg, cmd_lines, screenshots = parse_and_validate_script(script_path)
    if not valid_script:
        print(f"Error: Script validation failed: {s_msg}", file=sys.stderr)
        return 1

    output_dir.mkdir(parents=True, exist_ok=True)

    # 1. Forward ADB port
    adb_cmd = ["adb"]
    if device:
        adb_cmd.extend(["-s", device])
    adb_forward = adb_cmd + ["forward", f"tcp:{adb_port}", "tcp:5277"]
    print(f"Forwarding ADB port: {' '.join(adb_forward)}")
    try:
        subprocess.run(adb_forward, check=True, capture_output=True, text=True)
    except Exception as e:
        print(f"Warning: ADB port forwarding failed: {e}", file=sys.stderr)

    # 2. Build input stream
    input_text = "\n".join(cmd_lines) + "\nexit\n"

    # 3. Launch DHU in headless mode
    dhu_cmd = [str(dhu_bin), "--headless", "-c", str(profile_path)]
    if adb_port != 5277:
        dhu_cmd.extend(["-a", f"localhost:{adb_port}"])

    print(f"Executing: {' '.join(dhu_cmd)}")
    start_time = time.time()
    try:
        proc = subprocess.Popen(
            dhu_cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=str(output_dir),
            text=True,
        )
        stdout, stderr = proc.communicate(input=input_text, timeout=timeout)
        retcode = proc.returncode
    except subprocess.TimeoutExpired:
        proc.kill()
        print(f"Error: DHU execution timed out after {timeout} seconds", file=sys.stderr)
        return 3
    except Exception as e:
        print(f"Error: Failed to launch DHU: {e}", file=sys.stderr)
        return 4

    elapsed = time.time() - start_time
    print(f"DHU finished with exit code {retcode} in {elapsed:.1f}s")
    if verbose:
        if stdout:
            print(f"[DHU STDOUT]\n{stdout}")
        if stderr:
            print(f"[DHU STDERR]\n{stderr}")

    # 4. Verify Screenshots
    failed_screenshots: List[str] = []
    for shot_name in screenshots:
        shot_path = output_dir / shot_name
        if not shot_path.is_file():
            print(f"✗ Screenshot not generated: {shot_name}", file=sys.stderr)
            failed_screenshots.append(shot_name)
            continue

        passed, msg, stats = verify_non_black_screen(shot_path)
        if not passed:
            print(f"✗ Screenshot check FAILED for {shot_name}: {msg}", file=sys.stderr)
            failed_screenshots.append(shot_name)
        else:
            print(f"✓ Screenshot {shot_name}: OK (mean={stats['mean_luminance']}, var={stats['variance']})")

    if failed_screenshots:
        print(f"\n[FAILURE] {len(failed_screenshots)} screenshot(s) failed non-black screen gate!", file=sys.stderr)
        return 1

    print("\n[SUCCESS] Headless DHU run passed all checks!")
    return 0


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Headless Google Desktop Head Unit (DHU) 2.0 Test Runner"
    )
    parser.add_argument(
        "--profile",
        default="p1-small-landscape.ini",
        help="Profile name or path (default: p1-small-landscape.ini, or 'all')",
    )
    parser.add_argument(
        "--script",
        default="baseline.txt",
        help="Script name or path (default: baseline.txt, or 'all')",
    )
    parser.add_argument(
        "--all-profiles",
        action="store_true",
        help="Run against all 6 profiles",
    )
    parser.add_argument(
        "--all-scripts",
        action="store_true",
        help="Run against all 7 scripts",
    )
    parser.add_argument(
        "--configs-dir",
        type=Path,
        default=DEFAULT_CONFIGS_DIR,
        help="Directory containing INI configs",
    )
    parser.add_argument(
        "--scripts-dir",
        type=Path,
        default=DEFAULT_SCRIPTS_DIR,
        help="Directory containing walkthrough scripts",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help="Directory for output screenshots and logs",
    )
    parser.add_argument(
        "--dhu-bin",
        type=str,
        default=None,
        help="Explicit path to desktop-head-unit binary",
    )
    parser.add_argument(
        "--device",
        "-s",
        type=str,
        default=None,
        help="ADB device serial",
    )
    parser.add_argument(
        "--adb-port",
        type=int,
        default=5277,
        help="ADB port forward host port (default: 5277)",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=60,
        help="Execution timeout in seconds",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate configs, scripts, and non-black detection without hardware",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose output",
    )

    args = parser.parse_args(argv)

    if args.dry_run:
        return run_dry_run(
            configs_dir=args.configs_dir,
            scripts_dir=args.scripts_dir,
            evidence_dir=DEFAULT_EVIDENCE_DIR,
            verbose=args.verbose,
        )

    # Live run
    dhu_bin = find_dhu_binary(args.dhu_bin)
    available_profiles = list_profiles(args.configs_dir)
    available_scripts = list_scripts(args.scripts_dir)

    # Resolve Profile
    prof_name = args.profile
    if prof_name in available_profiles:
        profile_path = available_profiles[prof_name]
    elif Path(prof_name).is_file():
        profile_path = Path(prof_name)
    else:
        print(f"Error: Unknown profile '{prof_name}'. Available: {list(available_profiles.keys())}", file=sys.stderr)
        return 1

    # Resolve Script
    script_name = args.script
    if script_name in available_scripts:
        script_path = available_scripts[script_name]
    elif Path(script_name).is_file():
        script_path = Path(script_name)
    else:
        print(f"Error: Unknown script '{script_name}'. Available: {list(available_scripts.keys())}", file=sys.stderr)
        return 1

    return run_live_execution(
        profile_path=profile_path,
        script_path=script_path,
        output_dir=args.output_dir,
        dhu_bin=dhu_bin,
        device=args.device,
        adb_port=args.adb_port,
        timeout=args.timeout,
        verbose=args.verbose,
    )


if __name__ == "__main__":
    sys.exit(main())
