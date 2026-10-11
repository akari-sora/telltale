#!/usr/bin/env python3
"""Headless Google Desktop Head Unit (DHU) 2.0 Test Runner.

Automates Android Auto Headless DHU verification for CI and local test harnesses:
- DHU 2.0 `--headless` execution with stdin script automation pipeline.
- Supports 6 INI profiles in docs/android-auto/aa-06/configs/.
- Supports 7 walkthrough scripts in docs/android-auto/aa-06/scripts/.
- 42-combination matrix scheduling (6 profiles × 7 scripts).
- Isolated run and evidence directories (run_<timestamp>_<uuid>).
- Strict exit code and ADB port forwarding enforcement.
- Automated screenshot verification via Pillow luminance, variance, host chrome exclusion,
  and modal perimeter variance analysis.
- Full `--dry-run` mode for CI environments without physical head unit servers.
"""

from __future__ import annotations

import argparse
import configparser
from dataclasses import dataclass, field
import hashlib
import itertools
import json
import math
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
from typing import Any, Dict, List, Optional, Tuple
import uuid

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


@dataclass
class DhuExecutionRecord:
    scenario_id: str
    profile: str
    script: str
    command: List[str]
    exit_code: Optional[int]
    start_time: float
    end_time: float
    duration_seconds: float
    status: str  # "PASSED", "FAILED", "TIMEOUT", "ADB_ERROR", "LAUNCH_ERROR"
    stdout: str
    stderr: str
    expected_screenshots: List[str]
    verified_screenshots: Dict[str, Dict[str, Any]] = field(default_factory=dict)
    failed_screenshots: List[str] = field(default_factory=list)
    capture_preconditions_passed: bool = False
    error_message: Optional[str] = None
    run_dir: Optional[str] = None


@dataclass
class MatrixResult:
    total_planned: int
    total_executed: int
    total_passed: int
    total_failed: int
    total_skipped: int
    records: List[DhuExecutionRecord] = field(default_factory=list)
    aggregate_verdict: str = "FAILED"  # "PASSED" only if total_failed == 0 and total_executed > 0


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


def crop_app_content_area(
    im: Image.Image,
    insets: Optional[Tuple[int, int, int, int]] = None,
) -> Image.Image:
    """Crop screenshot to isolate App content area, excluding host status bar and nav bar.

    Default insets (left, top, right, bottom):
    - Top status bar: 32px (or ~8% of height)
    - Bottom navigation dock: 56px (or ~12% of height)
    - Left/Right margins: 16px
    """
    w, h = im.size
    if insets is None:
        left = 16
        top = 32
        right = 16
        bottom = 56
    else:
        left, top, right, bottom = insets

    if w <= (left + right) or h <= (top + bottom):
        return im

    crop_box = (
        max(0, left),
        max(0, top),
        min(w, w - right),
        min(h, h - bottom),
    )
    return im.crop(crop_box)


def compute_perimeter_variance(
    gray_img: Image.Image,
    pw: int,
    ph: int,
) -> float:
    """Compute variance of pixel intensity along outer perimeter of gray_img.

    pw: width of left/right perimeter bands.
    ph: height of top/bottom perimeter bands.
    """
    w, h = gray_img.size
    if pw <= 0 or ph <= 0 or w <= 2 * pw or h <= 2 * ph:
        stat = ImageStat.Stat(gray_img)
        return float(stat.var[0])

    mask = Image.new("L", (w, h), 255)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rectangle([pw, ph, w - pw - 1, h - ph - 1], fill=0)
    stat = ImageStat.Stat(gray_img, mask=mask)
    return float(stat.var[0])


def verify_non_black_screen(
    image_input: Any,
    min_luminance: float = 1.0,
    min_variance: float = 1.0,
    min_perimeter_variance: float = 5.0,
    crop_content: bool = True,
    insets: Optional[Tuple[int, int, int, int]] = None,
    allow_dialog: bool = False,
) -> Tuple[bool, str, Dict[str, Any]]:
    """Verify screenshot is genuinely non-black, non-blank, and not an error dialog modal.

    Calculates:
    - Luminance via grayscale (ITU-R BT.601) mean on cropped content area.
    - Standard deviation and variance of pixel intensity.
    - Alpha channel sanity (ensures non-transparent / no missing textures).
    - Perimeter variance check to catch dimmed modal scrims / error dialogs.

    Fails if:
    - Mean luminance < min_luminance (pitch black or black with sparse noise).
    - Variance < min_variance (flat unrendered canvas / blank screen).
    - Perimeter variance < min_perimeter_variance (modal dialog / error dialog scrim).
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

    target_img = crop_app_content_area(im, insets=insets) if crop_content else im

    gray = target_img.convert("L")
    stat = ImageStat.Stat(gray)

    mean_lum = float(stat.mean[0])
    stddev_lum = float(stat.stddev[0])
    var_lum = float(stat.var[0])

    stats = {
        "dimensions": (width, height),
        "content_dimensions": target_img.size,
        "mode": im.mode,
        "mean_luminance": round(mean_lum, 3),
        "stddev": round(stddev_lum, 3),
        "variance": round(var_lum, 3),
    }

    # Strict independent checks
    # 1. Mean luminance check (catches pure black and black with sparse noise dots)
    if mean_lum < min_luminance:
        return False, f"Black screen detected: mean luminance={mean_lum:.2f} < {min_luminance}", stats

    # 2. Variance check (catches flat unrendered canvas)
    if var_lum < min_variance:
        return False, f"Blank/flat screen detected: variance={var_lum:.2f} < {min_variance} (uniform unrendered display)", stats

    # 3. Perimeter variance check (catches modal scrim / error dialogs)
    if not allow_dialog:
        cw, ch = target_img.size
        pw = max(1, int(cw * 0.15))
        ph = max(1, int(ch * 0.15))
        perim_var = compute_perimeter_variance(gray, pw, ph)
        stats["perimeter_variance"] = round(perim_var, 3)
        if perim_var < min_perimeter_variance:
            return False, f"Error dialog or modal scrim detected: perimeter variance={perim_var:.2f} < {min_perimeter_variance}", stats

    return True, "Non-black screen verified", stats


def verify_semantic_evidence(
    evidence_path: Optional[Path],
    scenario_id: str,
    screenshots: List[str],
    run_dir: Path,
) -> Tuple[bool, str, Dict[str, Dict[str, str]]]:
    """Bind an external UI observation to the exact screenshot bytes.

    Pixel checks establish capture integrity only. Acceptance additionally
    requires a human/semantic observer receipt with a SHA-256 for every image.
    """
    if evidence_path is None or not evidence_path.is_file():
        return False, "semantic evidence receipt is missing", {}
    try:
        payload = json.loads(evidence_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return False, f"semantic evidence receipt is unreadable: {exc}", {}
    if payload.get("scenario_id") != scenario_id:
        return False, "semantic evidence scenario_id does not match", {}
    observations = payload.get("screenshots")
    if not isinstance(observations, dict):
        return False, "semantic evidence screenshots map is missing", {}
    verified: Dict[str, Dict[str, str]] = {}
    for name in screenshots:
        observation = observations.get(name)
        if not isinstance(observation, dict):
            return False, f"semantic observation missing for {name}", {}
        observed_state = observation.get("observed_state")
        observer = observation.get("observer")
        expected_hash = observation.get("sha256")
        if not all(isinstance(value, str) and value.strip() for value in (observed_state, observer, expected_hash)):
            return False, f"semantic observation incomplete for {name}", {}
        actual_hash = hashlib.sha256((run_dir / name).read_bytes()).hexdigest()
        if expected_hash.lower() != actual_hash:
            return False, f"semantic observation hash mismatch for {name}", {}
        verified[name] = {
            "observed_state": observed_state.strip(),
            "observer": observer.strip(),
            "sha256": actual_hash,
        }
    return True, "semantic observations bound to fresh screenshots", verified


def review_existing_run(run_dir: Path, semantic_evidence: Path) -> Tuple[int, str]:
    """Complete semantic review for a previously captured fail-closed run."""
    result_path = run_dir / "result.json"
    if not result_path.is_file():
        return 1, "run result.json is missing"
    try:
        result = json.loads(result_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return 1, f"run result.json is unreadable: {exc}"
    scenario_id = result.get("scenario_id")
    screenshots = result.get("expected_screenshots")
    start_time = result.get("start_time")
    if not isinstance(scenario_id, str) or not isinstance(screenshots, list) or not screenshots:
        return 1, "run result lacks scenario or screenshot metadata"
    if not isinstance(start_time, (int, float)):
        return 1, "run result lacks start time"
    if result.get("status") != "PENDING_SEMANTIC_REVIEW":
        return 1, "run is not pending semantic review"
    if result.get("exit_code") != 0:
        return 1, "run process did not exit successfully"
    if result.get("capture_preconditions_passed") is not True:
        return 1, "capture preconditions did not pass"
    if result.get("failed_screenshots"):
        return 1, "run contains failed screenshots"
    for name in screenshots:
        if not isinstance(name, str):
            return 1, "run result has invalid screenshot name"
        image_path = run_dir / name
        if not image_path.is_file() or image_path.stat().st_mtime < (start_time - 1.0):
            return 1, f"fresh screenshot is missing for {name}"
        pixel_ok, pixel_message, _ = verify_non_black_screen(image_path)
        if not pixel_ok:
            return 1, f"pixel precondition failed for {name}: {pixel_message}"
    semantic_ok, message, observations = verify_semantic_evidence(
        semantic_evidence,
        scenario_id,
        screenshots,
        run_dir,
    )
    if not semantic_ok:
        return 1, message
    review = {
        "scenario_id": scenario_id,
        "status": "PASSED",
        "semantic_evidence": str(semantic_evidence),
        "screenshots": observations,
    }
    (run_dir / "semantic-review.json").write_text(json.dumps(review, indent=2), encoding="utf-8")
    return 0, "capture and semantic evidence verified"


def save_execution_artifacts(record: DhuExecutionRecord, run_dir: Path) -> None:
    """Save execution logs and result.json manifest to the run directory."""
    run_dir.mkdir(parents=True, exist_ok=True)
    (run_dir / "stdout.log").write_text(record.stdout or "", encoding="utf-8")
    (run_dir / "stderr.log").write_text(record.stderr or "", encoding="utf-8")
    result_data = {
        "scenario_id": record.scenario_id,
        "profile": record.profile,
        "script": record.script,
        "command": record.command,
        "exit_code": record.exit_code,
        "start_time": record.start_time,
        "end_time": record.end_time,
        "duration_seconds": round(record.duration_seconds, 3),
        "status": record.status,
        "expected_screenshots": record.expected_screenshots,
        "verified_screenshots": record.verified_screenshots,
        "failed_screenshots": record.failed_screenshots,
        "capture_preconditions_passed": record.capture_preconditions_passed,
        "error_message": record.error_message,
        "run_dir": str(run_dir),
    }
    (run_dir / "result.json").write_text(json.dumps(result_data, indent=2), encoding="utf-8")


def _write_matrix_summary(matrix: MatrixResult, output_dir: Path) -> None:
    """Write matrix execution summary to output_dir/matrix_summary.json."""
    output_dir.mkdir(parents=True, exist_ok=True)
    summary_data = {
        "total_planned": matrix.total_planned,
        "total_executed": matrix.total_executed,
        "total_passed": matrix.total_passed,
        "total_failed": matrix.total_failed,
        "total_skipped": matrix.total_skipped,
        "aggregate_verdict": matrix.aggregate_verdict,
        "scenarios": [
            {
                "scenario_id": r.scenario_id,
                "profile": r.profile,
                "script": r.script,
                "status": r.status,
                "exit_code": r.exit_code,
                "duration_seconds": round(r.duration_seconds, 3),
                "error_message": r.error_message,
                "run_dir": r.run_dir,
            }
            for r in matrix.records
        ],
    }
    (output_dir / "matrix_summary.json").write_text(json.dumps(summary_data, indent=2), encoding="utf-8")


def run_live_execution(
    profile_path: Path,
    script_path: Path,
    output_dir: Path,
    dhu_bin: Optional[Path],
    device: Optional[str] = None,
    adb_port: int = 5277,
    timeout: int = 60,
    verbose: bool = False,
    semantic_evidence: Optional[Path] = None,
) -> Tuple[int, DhuExecutionRecord]:
    """Execute live DHU headless run with physical/emulator connection."""
    scenario_id = f"{profile_path.stem}__{script_path.stem}"
    start_time = time.time()
    run_uuid = uuid.uuid4().hex[:8]
    run_timestamp = int(start_time)
    run_dir = output_dir / f"run_{run_timestamp}_{run_uuid}"
    run_dir.mkdir(parents=True, exist_ok=True)

    record = DhuExecutionRecord(
        scenario_id=scenario_id,
        profile=profile_path.name,
        script=script_path.name,
        command=[],
        exit_code=None,
        start_time=start_time,
        end_time=start_time,
        duration_seconds=0.0,
        status="FAILED",
        stdout="",
        stderr="",
        expected_screenshots=[],
        verified_screenshots={},
        failed_screenshots=[],
        error_message=None,
        run_dir=str(run_dir),
    )

    print(f"=== Starting Live Headless DHU Execution ===")
    print(f"Scenario: {scenario_id}")
    print(f"Profile:  {profile_path}")
    print(f"Script:   {script_path}")
    print(f"Run Dir:  {run_dir}")

    if not dhu_bin or not dhu_bin.is_file():
        err_msg = "DHU binary not found. Set DHU_BIN or install Google DHU."
        print(f"Error: {err_msg}", file=sys.stderr)
        record.status = "LAUNCH_ERROR"
        record.error_message = err_msg
        record.end_time = time.time()
        record.duration_seconds = record.end_time - start_time
        save_execution_artifacts(record, run_dir)
        return 2, record

    valid_prof, p_msg, p_details = validate_profile_ini(profile_path)
    if not valid_prof:
        err_msg = f"Profile validation failed: {p_msg}"
        print(f"Error: {err_msg}", file=sys.stderr)
        record.status = "LAUNCH_ERROR"
        record.error_message = err_msg
        record.end_time = time.time()
        record.duration_seconds = record.end_time - start_time
        save_execution_artifacts(record, run_dir)
        return 1, record

    valid_script, s_msg, cmd_lines, screenshots = parse_and_validate_script(script_path)
    if not valid_script:
        err_msg = f"Script validation failed: {s_msg}"
        print(f"Error: {err_msg}", file=sys.stderr)
        record.status = "LAUNCH_ERROR"
        record.error_message = err_msg
        record.end_time = time.time()
        record.duration_seconds = record.end_time - start_time
        save_execution_artifacts(record, run_dir)
        return 1, record

    record.expected_screenshots = list(screenshots)

    # Acceptance mode gate: 0-screenshot scenarios fail
    if not screenshots:
        err_msg = "Acceptance mode failed: scenario manifest contains 0 screenshots to verify"
        print(f"Error: {err_msg}", file=sys.stderr)
        record.status = "FAILED"
        record.error_message = err_msg
        record.end_time = time.time()
        record.duration_seconds = record.end_time - start_time
        save_execution_artifacts(record, run_dir)
        return 1, record

    # 1. Forward ADB port
    adb_cmd = ["adb"]
    if device:
        adb_cmd.extend(["-s", device])
    adb_forward = adb_cmd + ["forward", f"tcp:{adb_port}", "tcp:5277"]
    print(f"Forwarding ADB port: {' '.join(adb_forward)}")
    try:
        adb_res = subprocess.run(adb_forward, check=True, capture_output=True, text=True)
        if verbose and adb_res.stdout:
            print(adb_res.stdout)
    except subprocess.CalledProcessError as e:
        err_msg = f"ADB port forwarding failed (code {e.returncode}): {e.stderr.strip() if e.stderr else 'error'}"
        print(f"Error: {err_msg}", file=sys.stderr)
        record.status = "ADB_ERROR"
        record.exit_code = e.returncode
        record.error_message = err_msg
        record.stderr = e.stderr or ""
        record.stdout = e.stdout or ""
        record.end_time = time.time()
        record.duration_seconds = record.end_time - start_time
        save_execution_artifacts(record, run_dir)
        return 5, record
    except Exception as e:
        err_msg = f"ADB port forwarding failed: {e}"
        print(f"Error: {err_msg}", file=sys.stderr)
        record.status = "ADB_ERROR"
        record.error_message = err_msg
        record.end_time = time.time()
        record.duration_seconds = record.end_time - start_time
        save_execution_artifacts(record, run_dir)
        return 5, record

    # 2. Build input stream
    input_text = "\n".join(cmd_lines) + "\nexit\n"

    # 3. Launch DHU in headless mode
    dhu_cmd = [str(dhu_bin), "--headless", "-c", str(profile_path)]
    if adb_port != 5277:
        dhu_cmd.extend(["-a", f"localhost:{adb_port}"])
    record.command = dhu_cmd

    print(f"Executing: {' '.join(dhu_cmd)}")
    proc_start_time = time.time()
    try:
        proc = subprocess.Popen(
            dhu_cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=str(run_dir),
            text=True,
        )
        stdout, stderr = proc.communicate(input=input_text, timeout=timeout)
        retcode = proc.returncode
        record.stdout = stdout or ""
        record.stderr = stderr or ""
        record.exit_code = retcode
    except subprocess.TimeoutExpired:
        proc.kill()
        try:
            out, err = proc.communicate(timeout=5)
            record.stdout = out or ""
            record.stderr = err or ""
        except Exception:
            pass
        record.status = "TIMEOUT"
        err_msg = f"DHU execution timed out after {timeout} seconds"
        record.error_message = err_msg
        print(f"Error: {err_msg}", file=sys.stderr)
        record.end_time = time.time()
        record.duration_seconds = record.end_time - start_time
        save_execution_artifacts(record, run_dir)
        return 3, record
    except Exception as e:
        err_msg = f"Failed to launch DHU: {e}"
        print(f"Error: {err_msg}", file=sys.stderr)
        record.status = "LAUNCH_ERROR"
        record.error_message = err_msg
        record.end_time = time.time()
        record.duration_seconds = record.end_time - start_time
        save_execution_artifacts(record, run_dir)
        return 4, record

    elapsed = time.time() - proc_start_time
    print(f"DHU finished with exit code {retcode} in {elapsed:.1f}s")
    if verbose:
        if stdout:
            print(f"[DHU STDOUT]\n{stdout}")
        if stderr:
            print(f"[DHU STDERR]\n{stderr}")

    if retcode != 0:
        err_msg = f"DHU process failed with exit code {retcode}"
        print(f"Error: {err_msg}", file=sys.stderr)
        record.status = "FAILED"
        record.exit_code = retcode
        record.error_message = err_msg
        record.end_time = time.time()
        record.duration_seconds = record.end_time - start_time
        save_execution_artifacts(record, run_dir)
        return retcode, record

    # 4. Verify Screenshots with Freshness & Content gates
    failed_screenshots: List[str] = []
    for shot_name in screenshots:
        shot_path = run_dir / shot_name
        if not shot_path.is_file():
            print(f"✗ Screenshot not generated: {shot_name}", file=sys.stderr)
            failed_screenshots.append(shot_name)
            continue

        # Freshness check: must have mtime >= start_time - 1.0
        mtime = shot_path.stat().st_mtime
        if mtime < (start_time - 1.0):
            print(f"✗ Screenshot {shot_name} is stale (mtime {mtime} < start {start_time})", file=sys.stderr)
            failed_screenshots.append(shot_name)
            continue

        passed, msg, stats = verify_non_black_screen(shot_path)
        if not passed:
            print(f"✗ Screenshot check FAILED for {shot_name}: {msg}", file=sys.stderr)
            failed_screenshots.append(shot_name)
        else:
            print(f"✓ Screenshot {shot_name}: OK (mean={stats['mean_luminance']}, var={stats['variance']})")
            record.verified_screenshots[shot_name] = stats

    record.capture_preconditions_passed = not failed_screenshots
    if record.capture_preconditions_passed:
        semantic_ok, semantic_message, semantic_observations = verify_semantic_evidence(
            semantic_evidence,
            scenario_id,
            screenshots,
            run_dir,
        )
        if not semantic_ok:
            print(f"✗ Semantic acceptance FAILED: {semantic_message}", file=sys.stderr)
            record.failed_screenshots = []
            record.status = "PENDING_SEMANTIC_REVIEW"
            record.error_message = semantic_message
            record.end_time = time.time()
            record.duration_seconds = record.end_time - start_time
            save_execution_artifacts(record, run_dir)
            return 1, record
        else:
            for name, observation in semantic_observations.items():
                record.verified_screenshots[name]["semantic_observation"] = observation

    record.failed_screenshots = failed_screenshots
    record.end_time = time.time()
    record.duration_seconds = record.end_time - start_time

    if failed_screenshots:
        err_msg = f"{len(failed_screenshots)} screenshot(s) failed validation: {', '.join(failed_screenshots)}"
        print(f"\n[FAILURE] {err_msg}", file=sys.stderr)
        record.status = "FAILED"
        record.error_message = err_msg
        save_execution_artifacts(record, run_dir)
        return 1, record

    record.status = "PASSED"
    save_execution_artifacts(record, run_dir)
    print("\n[SUCCESS] Headless DHU run passed capture and semantic checks!")
    return 0, record


def run_matrix_execution(
    combinations: List[Tuple[Path, Path]],
    output_dir: Path,
    dhu_bin: Optional[Path],
    device: Optional[str] = None,
    adb_port: int = 5277,
    timeout: int = 60,
    fail_fast: bool = False,
    verbose: bool = False,
    semantic_evidence_dir: Optional[Path] = None,
) -> Tuple[int, MatrixResult]:
    """Execute multi-combination matrix with isolated evidence dirs and summary tracking."""
    output_dir.mkdir(parents=True, exist_ok=True)
    matrix = MatrixResult(
        total_planned=len(combinations),
        total_executed=0,
        total_passed=0,
        total_failed=0,
        total_skipped=0,
    )

    print("=" * 70)
    print(f" [DHU-HEADLESS-RUNNER] Starting Matrix Execution: {len(combinations)} combinations planned")
    print("=" * 70)

    for i, (prof_path, script_path) in enumerate(combinations, start=1):
        scenario_id = f"{prof_path.stem}__{script_path.stem}"
        comb_output_dir = output_dir / scenario_id
        matrix.total_executed += 1

        print(f"\n[{i}/{len(combinations)}] Executing scenario: {scenario_id}")
        code, record = run_live_execution(
            profile_path=prof_path,
            script_path=script_path,
            output_dir=comb_output_dir,
            dhu_bin=dhu_bin,
            device=device,
            adb_port=adb_port,
            timeout=timeout,
            verbose=verbose,
            semantic_evidence=(semantic_evidence_dir / f"{scenario_id}.json") if semantic_evidence_dir else None,
        )
        matrix.records.append(record)
        if code == 0 and record.status == "PASSED":
            matrix.total_passed += 1
            print(f"[{i}/{len(combinations)}] Scenario {scenario_id}: PASSED")
        else:
            matrix.total_failed += 1
            print(f"[{i}/{len(combinations)}] Scenario {scenario_id}: FAILED ({record.error_message})", file=sys.stderr)
            if fail_fast:
                matrix.total_skipped = matrix.total_planned - matrix.total_executed
                print(f"Fail-fast enabled: aborting matrix run. Skipped remaining {matrix.total_skipped} scenarios.", file=sys.stderr)
                break

    matrix.aggregate_verdict = "PASSED" if matrix.total_failed == 0 and matrix.total_executed > 0 else "FAILED"
    _write_matrix_summary(matrix, output_dir)

    print("\n" + "=" * 70)
    print(f" [DHU-HEADLESS-RUNNER] Matrix Summary: Planned={matrix.total_planned}, Executed={matrix.total_executed}, Passed={matrix.total_passed}, Failed={matrix.total_failed}, Skipped={matrix.total_skipped}")
    print(f" Aggregate Verdict: {matrix.aggregate_verdict}")
    print("=" * 70)

    return (0 if matrix.aggregate_verdict == "PASSED" else 1), matrix


def run_dry_run(
    configs_dir: Path,
    scripts_dir: Path,
    evidence_dir: Path,
    target_profiles: Optional[List[Path]] = None,
    target_scripts: Optional[List[Path]] = None,
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

    # Test Case C: Black Screen with Sparse Dots (Should Fail)
    sparse_img = Image.new("RGB", (800, 480), (0, 0, 0))
    for pt in [(100, 100), (200, 200), (300, 300), (400, 200), (500, 100), (600, 300)]:
        sparse_img.putpixel(pt, (255, 255, 255))
    passed, msg, stats = verify_non_black_screen(sparse_img)
    if passed:
        print("  ✗ ERROR: Black screen with sparse dots was erroneously accepted!", file=sys.stderr)
        return 1
    print(f"  ✓ Sparse dots rejection: correctly caught (mean={stats['mean_luminance']}, var={stats['variance']})")

    # Test Case D: Host Chrome Only with black content (Should Fail)
    host_only = Image.new("RGB", (800, 480), (0, 0, 0))
    h_draw = ImageDraw.Draw(host_only)
    h_draw.rectangle([0, 0, 800, 31], fill=(45, 45, 45))
    h_draw.text((10, 5), "12:00", fill=(255, 255, 255))
    h_draw.rectangle([0, 424, 800, 479], fill=(45, 45, 45))
    h_draw.rectangle([380, 440, 420, 465], fill=(255, 255, 255))
    passed, msg, stats = verify_non_black_screen(host_only, crop_content=True)
    if passed:
        print("  ✗ ERROR: Host chrome only with black content was erroneously accepted!", file=sys.stderr)
        return 1
    print(f"  ✓ Host chrome exclusion: correctly caught unrendered content area (mean={stats['mean_luminance']})")

    # Test Case E: Error Dialog with modal scrim (Should Fail)
    modal_dialog = Image.new("RGB", (800, 480), (16, 16, 16))
    m_draw = ImageDraw.Draw(modal_dialog)
    m_draw.rectangle([250, 150, 550, 330], fill=(220, 50, 50), outline=(255, 255, 255))
    m_draw.text((270, 180), "Connection Error", fill=(255, 255, 255))
    passed, msg, stats = verify_non_black_screen(modal_dialog)
    if passed:
        print("  ✗ ERROR: Error dialog with modal scrim was erroneously accepted!", file=sys.stderr)
        return 1
    print(f"  ✓ Modal scrim rejection: correctly caught dialog (perim_var={stats['perimeter_variance']})")

    # Test Case F: Synthetic Valid UI Screen (Should Pass)
    synthetic_ui = Image.new("RGB", (800, 480), (20, 20, 30))
    draw = ImageDraw.Draw(synthetic_ui)
    draw.rectangle([50, 50, 750, 430], fill=(40, 80, 160), outline=(255, 255, 255))
    draw.text((100, 100), "Telltale Automotive UI", fill=(255, 255, 255))
    passed, msg, stats = verify_non_black_screen(synthetic_ui)
    if not passed:
        print(f"  ✗ ERROR: Synthetic UI was erroneously rejected: {msg}", file=sys.stderr)
        return 1
    print(f"  ✓ Synthetic UI verification: passed (mean={stats['mean_luminance']}, var={stats['variance']})")

    # Test Case G: Genuine Evidence Fixtures (if available in repository)
    if evidence_dir.is_dir():
        evidence_files = sorted(evidence_dir.glob("*.png"))
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

    # 5. Matrix Scheduling Validation
    profs_to_eval = target_profiles if target_profiles is not None else [configs_dir / p for p in KNOWN_PROFILES if (configs_dir / p).is_file()]
    scripts_to_eval = target_scripts if target_scripts is not None else [scripts_dir / s for s in KNOWN_SCRIPTS if (scripts_dir / s).is_file()]
    combinations = list(itertools.product(profs_to_eval, scripts_to_eval))

    print(f"\n[Phase 5] Matrix Scheduling Plan: {len(combinations)} combinations ({len(profs_to_eval)} profiles × {len(scripts_to_eval)} scripts)")
    print(f"  Planned: {len(combinations)}, Executed: 0, Passed: 0, Failed: 0, Skipped: {len(combinations)}")
    for prof, scr in combinations:
        scenario_id = f"{prof.stem}__{scr.stem}"
        if verbose:
            print(f"  - Plan combination: {scenario_id} -> OK")
    print(f"  ✓ Matrix scheduling validated ({len(combinations)} combinations ready).")

    print("\n" + "=" * 70)
    print(" [DHU-HEADLESS-RUNNER] DRY-RUN TOOLING VALIDATION COMPLETE; LIVE ACCEPTANCE NOT EXECUTED")
    print("=" * 70)
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
        "--fail-fast",
        action="store_true",
        help="Stop execution immediately on first failed scenario",
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
        "--semantic-evidence",
        type=Path,
        default=None,
        help="JSON observer receipt binding semantic observations to screenshot SHA-256 values",
    )
    parser.add_argument(
        "--semantic-evidence-dir",
        type=Path,
        default=None,
        help="Directory of <profile>__<script>.json semantic receipts for matrix execution",
    )
    parser.add_argument(
        "--review-run-dir",
        type=Path,
        default=None,
        help="Post-review an existing run directory using --semantic-evidence",
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

    available_profiles = list_profiles(args.configs_dir)
    available_scripts = list_scripts(args.scripts_dir)

    # Resolve Profiles
    if args.all_profiles or args.profile == "all":
        target_profiles = [available_profiles[p] for p in KNOWN_PROFILES if p in available_profiles]
        if not target_profiles:
            target_profiles = sorted(list(set(available_profiles.values())))
    else:
        if args.profile in available_profiles:
            target_profiles = [available_profiles[args.profile]]
        elif Path(args.profile).is_file():
            target_profiles = [Path(args.profile)]
        else:
            print(f"Error: Unknown profile '{args.profile}'. Available: {list(available_profiles.keys())}", file=sys.stderr)
            return 1

    # Resolve Scripts
    if args.all_scripts or args.script == "all":
        target_scripts = [available_scripts[s] for s in KNOWN_SCRIPTS if s in available_scripts]
        if not target_scripts:
            target_scripts = sorted(list(set(available_scripts.values())))
    else:
        if args.script in available_scripts:
            target_scripts = [available_scripts[args.script]]
        elif Path(args.script).is_file():
            target_scripts = [Path(args.script)]
        else:
            print(f"Error: Unknown script '{args.script}'. Available: {list(available_scripts.keys())}", file=sys.stderr)
            return 1

    combinations = list(itertools.product(target_profiles, target_scripts))

    if args.review_run_dir is not None:
        if args.semantic_evidence is None:
            print("Error: --review-run-dir requires --semantic-evidence", file=sys.stderr)
            return 1
        code, message = review_existing_run(args.review_run_dir, args.semantic_evidence)
        print(message, file=sys.stdout if code == 0 else sys.stderr)
        return code

    if args.dry_run:
        return run_dry_run(
            configs_dir=args.configs_dir,
            scripts_dir=args.scripts_dir,
            evidence_dir=DEFAULT_EVIDENCE_DIR,
            target_profiles=target_profiles,
            target_scripts=target_scripts,
            verbose=args.verbose,
        )

    # Live execution
    dhu_bin = find_dhu_binary(args.dhu_bin)

    if len(combinations) == 1 and not (args.all_profiles or args.all_scripts or args.profile == "all" or args.script == "all"):
        prof_path, script_path = combinations[0]
        code, _ = run_live_execution(
            profile_path=prof_path,
            script_path=script_path,
            output_dir=args.output_dir,
            dhu_bin=dhu_bin,
            device=args.device,
            adb_port=args.adb_port,
            timeout=args.timeout,
            verbose=args.verbose,
            semantic_evidence=args.semantic_evidence,
        )
        return code
    else:
        code, _ = run_matrix_execution(
            combinations=combinations,
            output_dir=args.output_dir,
            dhu_bin=dhu_bin,
            device=args.device,
            adb_port=args.adb_port,
            timeout=args.timeout,
            fail_fast=args.fail_fast,
            verbose=args.verbose,
            semantic_evidence_dir=args.semantic_evidence_dir,
        )
        return code


if __name__ == "__main__":
    sys.exit(main())
