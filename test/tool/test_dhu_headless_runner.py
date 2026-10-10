#!/usr/bin/env python3
"""Unit tests for tool/dhu_headless_runner.py.

Covers R1 (runner hardening & artifact persistence), R5 (matrix scheduling),
and R6 (luminance, host chrome crop, perimeter variance gates).
"""

from __future__ import annotations

import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import MagicMock, patch

# Ensure repo root is on sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from PIL import Image, ImageDraw

from tool.dhu_headless_runner import (
    DEFAULT_CONFIGS_DIR,
    DEFAULT_EVIDENCE_DIR,
    DEFAULT_SCRIPTS_DIR,
    KNOWN_PROFILES,
    KNOWN_SCRIPTS,
    DhuExecutionRecord,
    MatrixResult,
    compute_perimeter_variance,
    crop_app_content_area,
    find_dhu_binary,
    list_profiles,
    list_scripts,
    main,
    parse_and_validate_script,
    run_dry_run,
    run_live_execution,
    run_matrix_execution,
    save_execution_artifacts,
    validate_profile_ini,
    verify_non_black_screen,
)


class MockDhuProcess:
    """Mock subprocess.Popen object for simulating DHU execution with generated artifacts."""

    def __init__(
        self,
        returncode: int = 0,
        cwd: str | Path = ".",
        create_shots: list[str] | None = None,
        stale: bool = False,
    ):
        self.returncode = returncode
        self.cwd = Path(cwd)
        self.create_shots = create_shots or []
        self.stale = stale
        self.killed = False

    def communicate(self, input: str | None = None, timeout: float | None = None) -> tuple[str, str]:
        for shot_name in self.create_shots:
            shot_path = self.cwd / shot_name
            img = Image.new("RGB", (800, 480), (30, 40, 50))
            draw = ImageDraw.Draw(img)
            draw.rectangle([50, 50, 750, 430], fill=(50, 100, 200), outline=(255, 255, 255))
            draw.text((100, 100), "Valid UI", fill=(255, 255, 255))
            img.save(shot_path)
            if self.stale:
                stale_time = time.time() - 3600
                os.utime(shot_path, (stale_time, stale_time))
        return "mock stdout", "mock stderr"

    def kill(self) -> None:
        self.killed = True


class DhuHeadlessRunnerTest(unittest.TestCase):
    # =========================================================================
    # Baseline Profile & Script Validation Tests
    # =========================================================================

    def test_known_profiles_exist_and_validate(self):
        """Verify all 6 canonical profiles in docs/android-auto/aa-06/configs exist and pass validation."""
        self.assertTrue(DEFAULT_CONFIGS_DIR.is_dir(), f"Config dir not found: {DEFAULT_CONFIGS_DIR}")
        profiles = list_profiles(DEFAULT_CONFIGS_DIR)
        for expected in KNOWN_PROFILES:
            self.assertIn(expected, profiles, f"Expected profile {expected} not found in {profiles.keys()}")
            profile_path = profiles[expected]
            valid, msg, details = validate_profile_ini(profile_path)
            self.assertTrue(valid, f"Profile {expected} failed validation: {msg}")
            self.assertIn("resolution", details)
            self.assertGreater(details["resolution"][0], 0)
            self.assertGreater(details["resolution"][1], 0)
            self.assertGreater(details["dpi"], 0)
            self.assertIn("inputmode", details)

    def test_invalid_profile_ini_fails(self):
        """Verify malformed INI profiles fail validation gracefully."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # 1. Missing [general]
            p1 = Path(tmpdir) / "missing_gen.ini"
            p1.write_text("[sensors]\nspeed=true\n", encoding="utf-8")
            valid, msg, _ = validate_profile_ini(p1)
            self.assertFalse(valid)
            self.assertIn("Missing [general]", msg)

            # 2. Missing resolution
            p2 = Path(tmpdir) / "missing_res.ini"
            p2.write_text("[general]\ndpi=160\n", encoding="utf-8")
            valid, msg, _ = validate_profile_ini(p2)
            self.assertFalse(valid)
            self.assertIn("resolution", msg)

            # 3. Invalid resolution format
            p3 = Path(tmpdir) / "bad_res.ini"
            p3.write_text("[general]\nresolution=invalid\n", encoding="utf-8")
            valid, msg, _ = validate_profile_ini(p3)
            self.assertFalse(valid)
            self.assertIn("Invalid resolution format", msg)

            # 4. Non-existent file
            p4 = Path(tmpdir) / "non_existent.ini"
            valid, msg, _ = validate_profile_ini(p4)
            self.assertFalse(valid)
            self.assertIn("not found", msg)

    def test_known_scripts_exist_and_parse(self):
        """Verify all 7 canonical scripts in docs/android-auto/aa-06/scripts exist and pass validation."""
        self.assertTrue(DEFAULT_SCRIPTS_DIR.is_dir(), f"Scripts dir not found: {DEFAULT_SCRIPTS_DIR}")
        scripts = list_scripts(DEFAULT_SCRIPTS_DIR)
        for expected in KNOWN_SCRIPTS:
            self.assertIn(expected, scripts, f"Expected script {expected} not found")
            script_path = scripts[expected]
            valid, msg, commands, screenshots = parse_and_validate_script(script_path)
            self.assertTrue(valid, f"Script {expected} failed validation: {msg}")
            self.assertGreater(len(commands), 0)
            self.assertGreater(len(screenshots), 0)

    def test_invalid_script_fails(self):
        """Verify scripts with unknown commands or syntax errors fail validation."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # 1. Unknown command
            s1 = Path(tmpdir) / "bad_cmd.txt"
            s1.write_text("sleep 1\nunknown_dhu_cmd_xyz 123\n", encoding="utf-8")
            valid, msg, _, _ = parse_and_validate_script(s1)
            self.assertFalse(valid)
            self.assertIn("unknown DHU command", msg)

            # 2. Screenshot without argument
            s2 = Path(tmpdir) / "bad_shot.txt"
            s2.write_text("screenshot\n", encoding="utf-8")
            valid, msg, _, _ = parse_and_validate_script(s2)
            self.assertFalse(valid)
            self.assertIn("missing target filename", msg)

            # 3. Non-existent script
            s3 = Path(tmpdir) / "non_existent.txt"
            valid, msg, _, _ = parse_and_validate_script(s3)
            self.assertFalse(valid)
            self.assertIn("not found", msg)

    def test_dry_run_suite_passes(self):
        """Verify run_dry_run execution returns 0."""
        ret = run_dry_run(
            configs_dir=DEFAULT_CONFIGS_DIR,
            scripts_dir=DEFAULT_SCRIPTS_DIR,
            evidence_dir=DEFAULT_EVIDENCE_DIR,
            verbose=False,
        )
        self.assertEqual(ret, 0)

    def test_main_cli_dry_run_exits_zero(self):
        """Verify main() with --dry-run exits with 0."""
        ret = main(["--dry-run"])
        self.assertEqual(ret, 0)

    # =========================================================================
    # Defect R1: Runner Hardening, Freshness, Manifest & Exit Code Enforcement
    # =========================================================================

    @patch("subprocess.run")
    def test_adb_forward_failure_returns_error_code(self, mock_run):
        """R1: Verify ADB port forward failure immediately aborts run with code 5 and ADB_ERROR."""
        mock_run.side_effect = subprocess.CalledProcessError(
            returncode=1,
            cmd=["adb", "forward", "tcp:5277", "tcp:5277"],
            stderr="error: device offline\n",
        )
        with tempfile.TemporaryDirectory() as tmpdir:
            out_dir = Path(tmpdir)
            dhu_bin = out_dir / "dhu_mock"
            dhu_bin.touch(mode=0o755)
            prof_path = DEFAULT_CONFIGS_DIR / "p1-small-landscape.ini"
            script_path = DEFAULT_SCRIPTS_DIR / "baseline.txt"

            code, record = run_live_execution(
                profile_path=prof_path,
                script_path=script_path,
                output_dir=out_dir,
                dhu_bin=dhu_bin,
            )
            self.assertEqual(code, 5)
            self.assertEqual(record.status, "ADB_ERROR")
            self.assertIn("device offline", record.stderr)

            # Verify persistent result.json and logs in isolated run_dir
            run_dir = Path(record.run_dir)
            self.assertTrue(run_dir.is_dir())
            result_file = run_dir / "result.json"
            self.assertTrue(result_file.is_file())
            data = json.loads(result_file.read_text(encoding="utf-8"))
            self.assertEqual(data["status"], "ADB_ERROR")
            self.assertEqual(data["exit_code"], 1)
            self.assertTrue((run_dir / "stdout.log").is_file())
            self.assertTrue((run_dir / "stderr.log").is_file())

    @patch("subprocess.run")
    @patch("subprocess.Popen")
    def test_dhu_exit_code_failure_rejected_despite_screenshots(self, mock_popen, mock_run):
        """R1: Verify non-zero DHU process exit code (e.g. exit 37) fails run despite valid screenshots."""
        mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")

        def popen_factory(*args, **kwargs):
            return MockDhuProcess(
                returncode=37,
                cwd=kwargs.get("cwd", "."),
                create_shots=["aa06-baseline-home.png"],
            )

        mock_popen.side_effect = popen_factory

        with tempfile.TemporaryDirectory() as tmpdir:
            out_dir = Path(tmpdir)
            dhu_bin = out_dir / "dhu_mock"
            dhu_bin.touch(mode=0o755)
            prof_path = DEFAULT_CONFIGS_DIR / "p1-small-landscape.ini"
            script_path = DEFAULT_SCRIPTS_DIR / "baseline.txt"

            code, record = run_live_execution(
                profile_path=prof_path,
                script_path=script_path,
                output_dir=out_dir,
                dhu_bin=dhu_bin,
            )
            self.assertEqual(code, 37)
            self.assertEqual(record.status, "FAILED")
            self.assertEqual(record.exit_code, 37)
            self.assertIn("exit code 37", record.error_message)

            result_file = Path(record.run_dir) / "result.json"
            self.assertTrue(result_file.is_file())
            data = json.loads(result_file.read_text(encoding="utf-8"))
            self.assertEqual(data["status"], "FAILED")
            self.assertEqual(data["exit_code"], 37)

    @patch("subprocess.run")
    @patch("subprocess.Popen")
    def test_stale_screenshot_from_prior_run_rejected(self, mock_popen, mock_run):
        """R1: Verify pre-existing or stale screenshots (mtime < start_time) are rejected."""
        mock_run.return_value = MagicMock(returncode=0)

        def popen_factory(*args, **kwargs):
            return MockDhuProcess(
                returncode=0,
                cwd=kwargs.get("cwd", "."),
                create_shots=["aa06-baseline-home.png"],
                stale=True,
            )

        mock_popen.side_effect = popen_factory

        with tempfile.TemporaryDirectory() as tmpdir:
            out_dir = Path(tmpdir)
            dhu_bin = out_dir / "dhu_mock"
            dhu_bin.touch(mode=0o755)
            prof_path = DEFAULT_CONFIGS_DIR / "p1-small-landscape.ini"
            script_path = DEFAULT_SCRIPTS_DIR / "baseline.txt"

            code, record = run_live_execution(
                profile_path=prof_path,
                script_path=script_path,
                output_dir=out_dir,
                dhu_bin=dhu_bin,
            )
            self.assertNotEqual(code, 0)
            self.assertEqual(record.status, "FAILED")
            self.assertIn("aa06-baseline-home.png", record.failed_screenshots)

    @patch("subprocess.run")
    @patch("subprocess.Popen")
    def test_missing_manifest_screenshot_fails(self, mock_popen, mock_run):
        """R1: Verify scenario fails if DHU omits expected manifest screenshots."""
        mock_run.return_value = MagicMock(returncode=0)

        def popen_factory(*args, **kwargs):
            # day-night.txt expects 3 screenshots: day, night, daynight-toggled.
            # We generate only day.
            return MockDhuProcess(
                returncode=0,
                cwd=kwargs.get("cwd", "."),
                create_shots=["aa06-theme-day.png"],
            )

        mock_popen.side_effect = popen_factory

        with tempfile.TemporaryDirectory() as tmpdir:
            out_dir = Path(tmpdir)
            dhu_bin = out_dir / "dhu_mock"
            dhu_bin.touch(mode=0o755)
            prof_path = DEFAULT_CONFIGS_DIR / "p1-small-landscape.ini"
            script_path = DEFAULT_SCRIPTS_DIR / "day-night.txt"

            code, record = run_live_execution(
                profile_path=prof_path,
                script_path=script_path,
                output_dir=out_dir,
                dhu_bin=dhu_bin,
            )
            self.assertEqual(code, 1)
            self.assertEqual(record.status, "FAILED")
            self.assertIn("aa06-theme-night.png", record.failed_screenshots)

    def test_empty_acceptance_scenario_fails(self):
        """R1: Verify scripts without any screenshot verification commands fail acceptance mode."""
        with tempfile.TemporaryDirectory() as tmpdir:
            script_file = Path(tmpdir) / "empty_acc.txt"
            script_file.write_text("sleep 1\ngear D\nspeed 60\n", encoding="utf-8")
            out_dir = Path(tmpdir)
            dhu_bin = out_dir / "dhu_mock"
            dhu_bin.touch(mode=0o755)
            prof_path = DEFAULT_CONFIGS_DIR / "p1-small-landscape.ini"

            code, record = run_live_execution(
                profile_path=prof_path,
                script_path=script_file,
                output_dir=out_dir,
                dhu_bin=dhu_bin,
            )
            self.assertEqual(code, 1)
            self.assertEqual(record.status, "FAILED")
            self.assertIn("0 screenshots", record.error_message)

    @patch("subprocess.run")
    @patch("subprocess.Popen")
    def test_timeout_kills_process_and_saves_artifacts(self, mock_popen, mock_run):
        """R1: Verify execution timeout kills process and persists TIMEOUT artifacts."""
        mock_run.return_value = MagicMock(returncode=0)
        mock_proc = MagicMock()
        mock_proc.communicate.side_effect = subprocess.TimeoutExpired(cmd=["dhu"], timeout=5)
        mock_popen.return_value = mock_proc

        with tempfile.TemporaryDirectory() as tmpdir:
            out_dir = Path(tmpdir)
            dhu_bin = out_dir / "dhu_mock"
            dhu_bin.touch(mode=0o755)
            prof_path = DEFAULT_CONFIGS_DIR / "p1-small-landscape.ini"
            script_path = DEFAULT_SCRIPTS_DIR / "baseline.txt"

            code, record = run_live_execution(
                profile_path=prof_path,
                script_path=script_path,
                output_dir=out_dir,
                dhu_bin=dhu_bin,
                timeout=5,
            )
            self.assertEqual(code, 3)
            self.assertEqual(record.status, "TIMEOUT")
            mock_proc.kill.assert_called_once()

            result_file = Path(record.run_dir) / "result.json"
            self.assertTrue(result_file.is_file())
            data = json.loads(result_file.read_text(encoding="utf-8"))
            self.assertEqual(data["status"], "TIMEOUT")

    # =========================================================================
    # Defect R5: Multi-Combination Matrix Scheduling & Aggregate Verdict
    # =========================================================================

    def test_matrix_all_profiles_all_scripts_42_combinations(self):
        """R5: Verify --all-profiles --all-scripts schedules exactly 42 combinations."""
        # 1. Via flags
        ret1 = main(["--dry-run", "--all-profiles", "--all-scripts"])
        self.assertEqual(ret1, 0)

        # 2. Via --profile all --script all
        ret2 = main(["--dry-run", "--profile", "all", "--script", "all"])
        self.assertEqual(ret2, 0)

        profiles = list_profiles(DEFAULT_CONFIGS_DIR)
        scripts = list_scripts(DEFAULT_SCRIPTS_DIR)
        p_list = [profiles[p] for p in KNOWN_PROFILES if p in profiles]
        s_list = [scripts[s] for s in KNOWN_SCRIPTS if s in scripts]
        self.assertEqual(len(p_list), 6)
        self.assertEqual(len(s_list), 7)
        self.assertEqual(len(p_list) * len(s_list), 42)

    @patch("tool.dhu_headless_runner.run_live_execution")
    def test_matrix_aggregate_failure_if_single_scenario_fails(self, mock_run_live):
        """R5: Verify matrix execution fails aggregate gate if any required combination fails."""
        rec_pass = DhuExecutionRecord(
            scenario_id="p1__s1",
            profile="p1.ini",
            script="s1.txt",
            command=[],
            exit_code=0,
            start_time=1.0,
            end_time=2.0,
            duration_seconds=1.0,
            status="PASSED",
            stdout="ok",
            stderr="",
            expected_screenshots=["a.png"],
            verified_screenshots={"a.png": {}},
            failed_screenshots=[],
            error_message=None,
            run_dir="/tmp/run1",
        )
        rec_fail = DhuExecutionRecord(
            scenario_id="p2__s2",
            profile="p2.ini",
            script="s2.txt",
            command=[],
            exit_code=1,
            start_time=2.0,
            end_time=3.0,
            duration_seconds=1.0,
            status="FAILED",
            stdout="",
            stderr="dhu crash",
            expected_screenshots=["b.png"],
            verified_screenshots={},
            failed_screenshots=["b.png"],
            error_message="Screenshot check failed",
            run_dir="/tmp/run2",
        )
        mock_run_live.side_effect = [(0, rec_pass), (1, rec_fail)]

        with tempfile.TemporaryDirectory() as tmpdir:
            out_dir = Path(tmpdir)
            combos = [
                (DEFAULT_CONFIGS_DIR / "p1-small-landscape.ini", DEFAULT_SCRIPTS_DIR / "baseline.txt"),
                (DEFAULT_CONFIGS_DIR / "p2-720p.ini", DEFAULT_SCRIPTS_DIR / "baseline.txt"),
            ]
            code, matrix = run_matrix_execution(
                combinations=combos,
                output_dir=out_dir,
                dhu_bin=Path("/mock/dhu"),
            )
            self.assertEqual(code, 1)
            self.assertEqual(matrix.total_planned, 2)
            self.assertEqual(matrix.total_executed, 2)
            self.assertEqual(matrix.total_passed, 1)
            self.assertEqual(matrix.total_failed, 1)
            self.assertEqual(matrix.aggregate_verdict, "FAILED")

            summary_file = out_dir / "matrix_summary.json"
            self.assertTrue(summary_file.is_file())
            summary = json.loads(summary_file.read_text(encoding="utf-8"))
            self.assertEqual(summary["aggregate_verdict"], "FAILED")
            self.assertEqual(summary["total_failed"], 1)

    # =========================================================================
    # Defect R6: Image Cropping, Perimeter Variance & Non-Black Verification
    # =========================================================================

    def test_crop_app_content_area_default_and_custom(self):
        """R6: Verify crop_app_content_area crops status and nav bar with safe dimension guards."""
        im = Image.new("RGB", (800, 480), (100, 100, 100))
        # Default insets: left=16, top=32, right=16, bottom=56
        cropped = crop_app_content_area(im)
        self.assertEqual(cropped.size, (800 - 32, 480 - 88))  # 768 x 392

        # Custom insets
        cropped_custom = crop_app_content_area(im, insets=(10, 20, 30, 40))
        self.assertEqual(cropped_custom.size, (800 - 40, 480 - 60))

        # Small image guard
        small_im = Image.new("RGB", (30, 30), (50, 50, 50))
        cropped_small = crop_app_content_area(small_im)
        self.assertEqual(cropped_small.size, (30, 30))

    def test_compute_perimeter_variance(self):
        """R6: Verify compute_perimeter_variance detects flat outer borders vs textured borders."""
        # Flat border
        flat = Image.new("L", (200, 200), 20)
        p_var_flat = compute_perimeter_variance(flat, pw=20, ph=20)
        self.assertEqual(p_var_flat, 0.0)

        # Textured border
        textured = Image.new("L", (200, 200), 20)
        draw = ImageDraw.Draw(textured)
        draw.rectangle([5, 5, 195, 15], fill=240)  # bright stripe on top perimeter
        p_var_tex = compute_perimeter_variance(textured, pw=20, ph=20)
        self.assertGreater(p_var_tex, 10.0)

    def test_non_black_screen_verifier_pure_black_fails(self):
        """Verify pure black screen is strictly rejected."""
        im = Image.new("RGB", (800, 480), (0, 0, 0))
        valid, msg, stats = verify_non_black_screen(im)
        self.assertFalse(valid)
        self.assertIn("Black screen detected", msg)
        self.assertEqual(stats["mean_luminance"], 0.0)
        self.assertEqual(stats["variance"], 0.0)

    def test_non_black_screen_verifier_flat_blank_fails(self):
        """Verify flat uniform screen (zero variance) is strictly rejected."""
        im = Image.new("RGB", (800, 480), (100, 100, 100))
        valid, msg, stats = verify_non_black_screen(im)
        self.assertFalse(valid)
        self.assertIn("Blank/flat screen detected", msg)
        self.assertEqual(stats["variance"], 0.0)

    def test_non_black_screen_verifier_transparent_rgba_fails(self):
        """Verify fully transparent RGBA image is strictly rejected."""
        im = Image.new("RGBA", (800, 480), (255, 0, 0, 0))
        valid, msg, _ = verify_non_black_screen(im)
        self.assertFalse(valid)
        self.assertIn("transparent", msg)

    def test_non_black_screen_verifier_valid_screen_passes(self):
        """Verify rendered screen with genuine UI elements passes."""
        im = Image.new("RGB", (800, 480), (10, 10, 20))
        draw = ImageDraw.Draw(im)
        draw.rectangle([100, 100, 700, 400], fill=(50, 150, 250), outline=(255, 255, 255))
        valid, msg, stats = verify_non_black_screen(im)
        self.assertTrue(valid, msg)
        self.assertGreater(stats["mean_luminance"], 1.0)
        self.assertGreater(stats["variance"], 1.0)

    def test_non_black_screen_verifier_genuine_fixtures(self):
        """Verify all existing repository evidence fixtures pass non-black validation."""
        if not DEFAULT_EVIDENCE_DIR.is_dir():
            self.skipTest("Evidence dir not available")
        evidence_files = sorted(DEFAULT_EVIDENCE_DIR.glob("*.png"))
        self.assertGreater(len(evidence_files), 0, "No evidence screenshots found")
        for shot in evidence_files:
            valid, msg, stats = verify_non_black_screen(shot)
            self.assertTrue(valid, f"Genuine fixture {shot.name} failed: {msg}")
            self.assertGreater(stats["mean_luminance"], 1.0)
            self.assertGreater(stats["variance"], 1.0)

    def test_negative_black_screen_with_sparse_dots_fails(self):
        """R6: Verify black screen with sparse white dots is rejected by independent mean threshold."""
        im = Image.new("RGB", (800, 480), (0, 0, 0))
        for pt in [(100, 100), (200, 200), (300, 300), (400, 200), (500, 100), (600, 300)]:
            im.putpixel(pt, (255, 255, 255))
        valid, msg, stats = verify_non_black_screen(im)
        self.assertFalse(valid)
        self.assertIn("Black screen detected", msg)
        self.assertLess(stats["mean_luminance"], 1.0)

    def test_negative_host_chrome_only_fails(self):
        """R6: Verify screenshot with only host status & nav bar but unrendered content fails."""
        im = Image.new("RGB", (800, 480), (0, 0, 0))
        draw = ImageDraw.Draw(im)
        # Host status bar (top 32px)
        draw.rectangle([0, 0, 800, 31], fill=(50, 50, 50))
        draw.text((10, 5), "12:00", fill=(255, 255, 255))
        # Host navigation bar (bottom 56px)
        draw.rectangle([0, 424, 800, 479], fill=(50, 50, 50))
        draw.rectangle([380, 440, 420, 465], fill=(255, 255, 255))

        # Middle content area [16..784, 32..424] is 100% pitch black
        valid, msg, stats = verify_non_black_screen(im, crop_content=True)
        self.assertFalse(valid)
        self.assertIn("Black screen detected", msg)

    def test_negative_error_dialog_modal_fails(self):
        """R6: Verify modal error dialog with dimmed scrim perimeter is rejected unless explicitly allowed."""
        im = Image.new("RGB", (800, 480), (16, 16, 16))  # modal scrim backdrop
        draw = ImageDraw.Draw(im)
        # Centered dialog box
        draw.rectangle([250, 150, 550, 330], fill=(220, 50, 50), outline=(255, 255, 255))
        draw.text((270, 180), "Connection Error", fill=(255, 255, 255))

        # Default: rejects modal dialog scrim
        valid, msg, stats = verify_non_black_screen(im)
        self.assertFalse(valid)
        self.assertIn("Error dialog or modal scrim detected", msg)
        self.assertLess(stats["perimeter_variance"], 5.0)

        # Opt-in: allow_dialog=True passes
        valid_opt, msg_opt, _ = verify_non_black_screen(im, allow_dialog=True)
        self.assertTrue(valid_opt, msg_opt)

    def test_positive_legit_dark_mode_passes(self):
        """R6: Verify genuine automotive dark mode screens and repository fixtures pass."""
        im = Image.new("RGB", (800, 480), (15, 18, 25))
        draw = ImageDraw.Draw(im)
        # Rich gauges and telemetry elements spanning viewport
        draw.rectangle([30, 40, 350, 200], fill=(25, 35, 55), outline=(0, 200, 255))
        draw.text((50, 60), "Speed: 105 km/h", fill=(0, 255, 255))
        draw.rectangle([400, 40, 750, 200], fill=(25, 35, 55), outline=(255, 150, 0))
        draw.text((420, 60), "Coolant: 92 C", fill=(255, 200, 0))
        draw.rectangle([30, 230, 750, 410], fill=(20, 25, 40), outline=(100, 100, 100))
        draw.text((50, 250), "DTC Status: Normal (No faults)", fill=(100, 255, 100))

        valid, msg, stats = verify_non_black_screen(im)
        self.assertTrue(valid, msg)
        self.assertGreater(stats["mean_luminance"], 10.0)
        self.assertGreater(stats["perimeter_variance"], 5.0)

        # Verify all 22 genuine fixtures in evidence dir
        if DEFAULT_EVIDENCE_DIR.is_dir():
            files = sorted(DEFAULT_EVIDENCE_DIR.glob("*.png"))
            self.assertEqual(len(files), 22)
            for shot in files:
                val, m, st = verify_non_black_screen(shot)
                self.assertTrue(val, f"Fixture {shot.name} failed: {m}")
                self.assertGreaterEqual(st["mean_luminance"], 20.0)
                self.assertGreaterEqual(st["perimeter_variance"], 5.0)


if __name__ == "__main__":
    unittest.main()
