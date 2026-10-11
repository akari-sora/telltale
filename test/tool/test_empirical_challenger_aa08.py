#!/usr/bin/env python3
"""Empirical Challenger Adversarial Verification Harness for Defects R1, R5, R6, R2, R7.

Strictly challenges:
- R1: DHU runner exit code enforcement (exit 37, 43), stale screenshot injection rejection,
      missing screenshot manifest failure, artifact persistence (result.json, stdout/stderr).
- R5: 42-combination matrix scheduler (6 profiles x 7 scripts), aggregate failure oracle.
- R6: Non-black verification gates:
      * 6 white pixels rejection (mean luminance gate).
      * Host chrome only rejection (crop_content gate).
      * Modal dialog with dark scrim rejection (perimeter variance < 5.0 gate).
      * Genuine dark mode UI acceptance.
- R2: AAOS runner AdbResult error interception (exit 19, SecurityException, Unknown command,
      Permission denial), Stage 4 RUNNING_LOCKED rejection, E2E state observation oracles.
- R7: AAOS runner emulator ownership isolation (strictly preserving foreign/pre-existing emulators).
"""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import MagicMock, patch

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
    list_profiles,
    list_scripts,
    main as dhu_main,
    run_live_execution as dhu_run_live_execution,
    run_matrix_execution as dhu_run_matrix_execution,
    verify_non_black_screen,
)
from tool.aaos_headless_runner import (
    AaosStateObserver,
    AdbResult,
    DEFAULT_SCENARIOS,
    EmulatorInstance,
    GEAR_DRIVE,
    GEAR_PARK,
    GEAR_REVERSE,
    main as aaos_main,
    parse_app_package_ready,
    parse_stage4_response,
    parse_template_host_response,
    parse_user_unlocked_response,
    run_adb_shell,
    run_live_execution as aaos_run_live_execution,
    verify_stage4_readiness,
)


class MockDhuProcess:
    def __init__(
        self,
        returncode: int = 0,
        cwd: str | Path = ".",
        create_shots: list[str] | None = None,
        stale_offset: float | None = None,
    ):
        self.returncode = returncode
        self.cwd = Path(cwd)
        self.create_shots = create_shots or []
        self.stale_offset = stale_offset
        self.killed = False

    def communicate(self, input: str | None = None, timeout: float | None = None) -> tuple[str, str]:
        for shot_name in self.create_shots:
            shot_path = self.cwd / shot_name
            img = Image.new("RGB", (800, 480), (20, 25, 35))
            draw = ImageDraw.Draw(img)
            draw.rectangle([50, 50, 750, 430], fill=(40, 80, 160), outline=(255, 255, 255))
            draw.text((100, 100), "Valid UI", fill=(255, 255, 255))
            img.save(shot_path)
            if self.stale_offset is not None:
                stale_time = time.time() - self.stale_offset
                os.utime(shot_path, (stale_time, stale_time))
        return "mock stdout", "mock stderr"

    def kill(self) -> None:
        self.killed = True


class EmpiricalChallengerTest(unittest.TestCase):
    # =========================================================================
    # 1. DHU Runner (R6): Black Image with 6 White Pixels
    # =========================================================================

    def test_challenge_r6_black_image_with_sparse_white_pixels(self):
        """CHALLENGE R6: An 800x480 black image with 6 white pixels must be REJECTED.
        
        Mathematical oracle:
        - 6 white pixels (value 255) in 384,000 pixels.
        - Mean luminance = 6 * 255 / 384,000 = 0.00398 < 1.0.
        - Variance = ~1.015 > 1.0 (would fool a naive variance-only gate).
        - Must return False due to independent mean_luminance check.
        """
        for dims in [(800, 480), (1280, 720), (1920, 1080)]:
            im = Image.new("RGB", dims, (0, 0, 0))
            pixels = [(10, 10), (100, 50), (200, 150), (300, 250), (400, 350), (500, 450)]
            for pt in pixels:
                if pt[0] < dims[0] and pt[1] < dims[1]:
                    im.putpixel(pt, (255, 255, 255))

            valid, msg, stats = verify_non_black_screen(im, crop_content=False)
            self.assertFalse(valid, f"Failed to reject sparse pixels for {dims}: {msg}")
            self.assertIn("Black screen detected", msg)
            self.assertLess(stats["mean_luminance"], 1.0)
            self.assertGreater(stats["variance"], 0.0)

    # =========================================================================
    # 2. DHU Runner (R6): Host Chrome Only (Middle Black)
    # =========================================================================

    def test_challenge_r6_host_chrome_only_with_crop_content(self):
        """CHALLENGE R6: Host chrome rendered (top status bar & bottom nav dock) but
        middle content canvas is 100% pitch black -> must be REJECTED with crop_content=True.
        """
        im = Image.new("RGB", (800, 480), (0, 0, 0))
        draw = ImageDraw.Draw(im)

        # Draw Top Status Bar (0..31)
        draw.rectangle([0, 0, 800, 31], fill=(50, 55, 60))
        draw.text((10, 8), "12:34 PM  LTE 100%", fill=(255, 255, 255))

        # Draw Bottom Navigation Bar (424..479)
        draw.rectangle([0, 424, 800, 479], fill=(30, 30, 35))
        draw.rectangle([380, 440, 420, 465], fill=(255, 255, 255))  # Home button
        draw.ellipse([50, 440, 75, 465], fill=(200, 200, 200))      # App switcher

        # App content area [16..784, 32..424] is entirely (0, 0, 0)
        valid, msg, stats = verify_non_black_screen(im, crop_content=True)
        self.assertFalse(valid, f"Host chrome was incorrectly accepted: {msg}")
        self.assertIn("Black screen detected", msg)
        self.assertEqual(stats["mean_luminance"], 0.0)
        self.assertEqual(stats["variance"], 0.0)

    # =========================================================================
    # 3. DHU Runner (R6): Modal Dialog with Dark Scrim
    # =========================================================================

    def test_challenge_r6_modal_dialog_with_dark_scrim_rejected(self):
        """CHALLENGE R6: Modal dialog box on uniform dark scrim (perim_var < 5.0) ->
        must be REJECTED by perimeter variance check unless explicitly allowed.
        """
        # Dimmed scrim backdrop RGB(18, 18, 18)
        im = Image.new("RGB", (800, 480), (18, 18, 18))
        draw = ImageDraw.Draw(im)

        # Centered alert dialog
        draw.rectangle([220, 140, 580, 340], fill=(240, 240, 245), outline=(200, 0, 0), width=3)
        draw.text((250, 180), "CRITICAL SYSTEM ERROR", fill=(200, 0, 0))
        draw.text((250, 220), "Connection to vehicle lost.", fill=(0, 0, 0))

        # 1. Default (allow_dialog=False) -> REJECTED
        valid, msg, stats = verify_non_black_screen(im, allow_dialog=False)
        self.assertFalse(valid, f"Modal scrim was incorrectly accepted: {msg}")
        self.assertIn("Error dialog or modal scrim detected", msg)
        self.assertLess(stats["perimeter_variance"], 5.0)

        # 2. Explicit allow_dialog=True -> ALLOWED
        valid_opt, msg_opt, stats_opt = verify_non_black_screen(im, allow_dialog=True)
        self.assertTrue(valid_opt, f"Explicit dialog permission was rejected: {msg_opt}")

    # =========================================================================
    # 4. DHU Runner (R6): Genuine Dark Mode UI Accepted
    # =========================================================================

    def test_challenge_r6_genuine_dark_mode_ui_passes(self):
        """CHALLENGE R6: Legitimate dark mode UI with edge-to-edge gauges, telemetry cards,
        and real repository fixtures must PASS all gates.
        """
        # Synthetic rich dark mode screen
        im = Image.new("RGB", (800, 480), (12, 16, 24))
        draw = ImageDraw.Draw(im)
        # Dashboard cards spanning perimeter and content
        draw.rectangle([20, 35, 380, 220], fill=(22, 30, 46), outline=(0, 220, 255), width=2)
        draw.text((40, 50), "SPEED: 104 km/h", fill=(0, 220, 255))
        draw.rectangle([400, 35, 770, 220], fill=(22, 30, 46), outline=(255, 180, 0), width=2)
        draw.text((420, 50), "RPM: 3,250", fill=(255, 180, 0))
        draw.rectangle([20, 240, 770, 420], fill=(20, 24, 34), outline=(100, 200, 100), width=2)
        draw.text((40, 260), "BATTERY: 13.8V  COOLANT: 92°C  GEAR: DRIVE", fill=(100, 255, 100))

        valid, msg, stats = verify_non_black_screen(im)
        self.assertTrue(valid, f"Genuine synthetic dark UI failed: {msg}")
        self.assertGreater(stats["mean_luminance"], 1.0)
        self.assertGreater(stats["variance"], 1.0)
        self.assertGreater(stats["perimeter_variance"], 5.0)

        # Test against all 22 real fixtures in repo
        if DEFAULT_EVIDENCE_DIR.is_dir():
            evidence_shots = list(DEFAULT_EVIDENCE_DIR.glob("*.png"))
            self.assertEqual(len(evidence_shots), 22, f"Expected 22 evidence shots, found {len(evidence_shots)}")
            for shot_path in evidence_shots:
                v, m, s = verify_non_black_screen(shot_path)
                self.assertTrue(v, f"Repository fixture {shot_path.name} failed: {m}")

    # =========================================================================
    # 5. DHU Runner (R1): Stale Screenshot Injection Rejected
    # =========================================================================

    @patch("subprocess.run")
    @patch("subprocess.Popen")
    def test_challenge_r1_stale_screenshot_injection_fails(self, mock_popen, mock_run):
        """CHALLENGE R1: Screenshot injected from prior run with stale mtime (mtime < start_time)
        must be REJECTED and marked FAILED.
        """
        mock_run.return_value = MagicMock(returncode=0)

        # Simulate DHU run producing a screenshot that has mtime from 1 hour ago
        mock_popen.side_effect = lambda *a, **kw: MockDhuProcess(
            returncode=0,
            cwd=kw.get("cwd", "."),
            create_shots=["aa06-baseline-home.png"],
            stale_offset=3600.0,
        )

        with tempfile.TemporaryDirectory() as tmpdir:
            out_dir = Path(tmpdir)
            dhu_bin = out_dir / "dhu_mock"
            dhu_bin.touch(mode=0o755)

            code, record = dhu_run_live_execution(
                profile_path=DEFAULT_CONFIGS_DIR / "p1-small-landscape.ini",
                script_path=DEFAULT_SCRIPTS_DIR / "baseline.txt",
                output_dir=out_dir,
                dhu_bin=dhu_bin,
            )
            self.assertNotEqual(code, 0, "Stale screenshot was accepted!")
            self.assertEqual(record.status, "FAILED")
            self.assertIn("aa06-baseline-home.png", record.failed_screenshots)

            # result.json check
            res_file = Path(record.run_dir) / "result.json"
            self.assertTrue(res_file.is_file())
            data = json.loads(res_file.read_text(encoding="utf-8"))
            self.assertEqual(data["status"], "FAILED")
            self.assertIn("aa06-baseline-home.png", data["failed_screenshots"])

    # =========================================================================
    # 6. DHU Runner (R1): Exit Code 37 and 43 Enforcement & Artifact Persistence
    # =========================================================================

    @patch("subprocess.run")
    @patch("subprocess.Popen")
    def test_challenge_r1_dhu_exit_code_37_and_43_rejected(self, mock_popen, mock_run):
        """CHALLENGE R1: DHU process exiting with non-zero code (e.g. 37 or 43) must FAIL,
        must return that exit code, and must persist result.json, stdout.log, stderr.log.
        """
        mock_run.return_value = MagicMock(returncode=0)

        for mock_exit_code in (37, 43):
            mock_popen.side_effect = lambda *a, **kw: MockDhuProcess(
                returncode=mock_exit_code,
                cwd=kw.get("cwd", "."),
                create_shots=["aa06-baseline-home.png"],
            )

            with tempfile.TemporaryDirectory() as tmpdir:
                out_dir = Path(tmpdir)
                dhu_bin = out_dir / "dhu_mock"
                dhu_bin.touch(mode=0o755)

                code, record = dhu_run_live_execution(
                    profile_path=DEFAULT_CONFIGS_DIR / "p1-small-landscape.ini",
                    script_path=DEFAULT_SCRIPTS_DIR / "baseline.txt",
                    output_dir=out_dir,
                    dhu_bin=dhu_bin,
                )
                self.assertEqual(code, mock_exit_code, f"Expected code {mock_exit_code}, got {code}")
                self.assertEqual(record.status, "FAILED")
                self.assertEqual(record.exit_code, mock_exit_code)
                self.assertIn(f"exit code {mock_exit_code}", record.error_message)

                # Verify artifacts in run_dir
                run_dir = Path(record.run_dir)
                self.assertTrue(run_dir.is_dir())
                self.assertTrue((run_dir / "stdout.log").is_file())
                self.assertTrue((run_dir / "stderr.log").is_file())
                result_json = run_dir / "result.json"
                self.assertTrue(result_json.is_file())

                res_data = json.loads(result_json.read_text(encoding="utf-8"))
                self.assertEqual(res_data["exit_code"], mock_exit_code)
                self.assertEqual(res_data["status"], "FAILED")

    # =========================================================================
    # 7. DHU Runner (R5): 42-Combination Matrix Scheduler & Aggregate Failure Gate
    # =========================================================================

    def test_challenge_r5_42_combination_matrix_and_aggregate_oracle(self):
        """CHALLENGE R5:
        1. --all-profiles --all-scripts schedules exactly 42 combinations (6 profiles x 7 scripts).
        2. Any failure in a required combination must cause MatrixResult.aggregate_verdict to be FAILED.
        """
        profiles = list_profiles(DEFAULT_CONFIGS_DIR)
        scripts = list_scripts(DEFAULT_SCRIPTS_DIR)
        p_list = [profiles[p] for p in KNOWN_PROFILES if p in profiles]
        s_list = [scripts[s] for s in KNOWN_SCRIPTS if s in scripts]
        self.assertEqual(len(p_list), 6, "Must have exactly 6 profiles")
        self.assertEqual(len(s_list), 7, "Must have exactly 7 scripts")
        self.assertEqual(len(p_list) * len(s_list), 42, "Must form exactly 42 combinations")

        # Test CLI invocation in dry-run mode
        ret_cli = dhu_main(["--dry-run", "--all-profiles", "--all-scripts"])
        self.assertEqual(ret_cli, 0)

        # Test aggregate failure oracle: 1 failure out of 3 scenarios must fail matrix
        with patch("tool.dhu_headless_runner.run_live_execution") as mock_live:
            rec_pass = DhuExecutionRecord(
                scenario_id="sc_pass", profile="p.ini", script="s.txt", command=[],
                exit_code=0, start_time=0.0, end_time=1.0, duration_seconds=1.0,
                status="PASSED", stdout="", stderr="", expected_screenshots=["a.png"],
                verified_screenshots={"a.png": {}}, failed_screenshots=[], run_dir="/tmp/p",
            )
            rec_fail = DhuExecutionRecord(
                scenario_id="sc_fail", profile="p.ini", script="s.txt", command=[],
                exit_code=1, start_time=1.0, end_time=2.0, duration_seconds=1.0,
                status="FAILED", stdout="", stderr="", expected_screenshots=["b.png"],
                verified_screenshots={}, failed_screenshots=["b.png"], run_dir="/tmp/f",
            )
            mock_live.side_effect = [(0, rec_pass), (1, rec_fail)]

            with tempfile.TemporaryDirectory() as tmpdir:
                out_dir = Path(tmpdir)
                combos = [
                    (DEFAULT_CONFIGS_DIR / "p1-small-landscape.ini", DEFAULT_SCRIPTS_DIR / "baseline.txt"),
                    (DEFAULT_CONFIGS_DIR / "p2-720p.ini", DEFAULT_SCRIPTS_DIR / "baseline.txt"),
                ]
                code, matrix = dhu_run_matrix_execution(
                    combinations=combos,
                    output_dir=out_dir,
                    dhu_bin=Path("/mock/dhu"),
                )
                self.assertEqual(code, 1)
                self.assertEqual(matrix.aggregate_verdict, "FAILED")
                self.assertEqual(matrix.total_failed, 1)
                self.assertEqual(matrix.total_passed, 1)
                self.assertEqual(matrix.total_planned, 2)

                summary_file = out_dir / "matrix_summary.json"
                self.assertTrue(summary_file.is_file())
                data = json.loads(summary_file.read_text(encoding="utf-8"))
                self.assertEqual(data["aggregate_verdict"], "FAILED")
                self.assertEqual(data["total_failed"], 1)

    # =========================================================================
    # 8. AAOS Runner (R2): Exit 19, SecurityException, Unknown Command Interception
    # =========================================================================

    def test_challenge_r2_adb_result_rejections(self):
        """CHALLENGE R2:
        - exit 19 -> is_success is False, raise_for_status raises RuntimeError.
        - SecurityException -> is_success is False, raise_for_status raises RuntimeError.
        - Unknown command -> is_success is False, raise_for_status raises RuntimeError.
        - Permission denial -> is_success is False, raise_for_status raises RuntimeError.
        """
        cases = [
            (19, "cmd output", "", "exit=19"),
            (0, "java.lang.SecurityException: Permission Denial: inject-vhal-event", "", "SecurityException"),
            (0, "Unknown command: inject-vhal-event", "", "Unknown command"),
            (0, "Error: Permission denial for calling uid", "", "Permission denial"),
        ]

        for code, out, err, expected_err in cases:
            res = AdbResult(
                returncode=code,
                stdout=out,
                stderr=err,
                command=["adb", "shell", "cmd", "car_service"],
            )
            self.assertFalse(res.is_success, f"AdbResult failed to detect error: {expected_err}")
            with self.assertRaises(RuntimeError) as ctx:
                res.raise_for_status()
            self.assertIn(expected_err, str(ctx.exception))

    def test_challenge_r2_live_runner_fails_on_injection_errors(self):
        """CHALLENGE R2: Live runner must fail and return exit code 1 if VHAL injection
        returns exit 19 or Unknown command.
        """
        def make_fake_run(exit_code: int, stdout_msg: str):
            def fake_run(cmd, *args, **kwargs):
                cmd_str = " ".join(str(c) for c in cmd)
                if "get-state" in cmd_str:
                    return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="device\n", stderr="")
                elif "sys.boot_completed" in cmd_str:
                    return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="1\n", stderr="")
                elif "service" in cmd_str and "check" in cmd_str:
                    return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="found\n", stderr="")
                elif "am" in cmd_str and "get-current-user" in cmd_str:
                    return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="10\n", stderr="")
                elif "am" in cmd_str and "is-user-unlocked" in cmd_str:
                    return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="true\n", stderr="")
                elif "pm" in cmd_str and "features" in cmd_str:
                    return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="feature:android.software.car.templates_host\n", stderr="")
                elif "pm" in cmd_str and "path" in cmd_str:
                    return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="package:/data/app/com.cbstudio.telltale.carproto.aaos/base.apk\n", stderr="")
                elif "inject-vhal-event" in cmd_str:
                    return subprocess.CompletedProcess(
                        args=cmd,
                        returncode=exit_code,
                        stdout=stdout_msg if exit_code == 0 else "",
                        stderr="Rejected" if exit_code != 0 else "",
                    )
                return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="", stderr="")
            return fake_run

        # Case A: exit 19
        with patch("subprocess.run", side_effect=make_fake_run(19, "")):
            ret = aaos_run_live_execution(
                avd_name="AAOS_Automotive_1080p", serial="emulator-5554",
                emulator_bin=None, adb_bin=Path(sys.executable),
                skip_launch=True, boot_timeout=5,
            )
            self.assertEqual(ret, 1)

        # Case B: Unknown command: inject-vhal-event
        with patch("subprocess.run", side_effect=make_fake_run(0, "Unknown command: inject-vhal-event")):
            ret = aaos_run_live_execution(
                avd_name="AAOS_Automotive_1080p", serial="emulator-5554",
                emulator_bin=None, adb_bin=Path(sys.executable),
                skip_launch=True, boot_timeout=5,
            )
            self.assertEqual(ret, 1)

    # =========================================================================
    # 9. AAOS Runner (R2): RUNNING_LOCKED Rejection in Stage 4
    # =========================================================================

    def test_challenge_r2_stage4_rejects_running_locked(self):
        """CHALLENGE R2: Stage 4 must strictly REJECT user states reporting RUNNING_LOCKED
        or locked driver profiles.
        """
        locked_strings = [
            "User 10: RUNNING_LOCKED",
            "UserInfo{10:Driver:locked}",
            "10 locked",
            "RUNNING_LOCKED\n",
            "locked\n",
        ]

        for s in locked_strings:
            self.assertFalse(parse_stage4_response(s), f"parse_stage4_response accepted locked state: {s}")
            self.assertFalse(parse_user_unlocked_response(s), f"parse_user_unlocked_response accepted locked state: {s}")

        # verify_stage4_readiness negative oracle
        self.assertFalse(
            verify_stage4_readiness(
                user_output="10",
                unlocked_output="User 10: RUNNING_LOCKED",
                features_output="feature:android.software.car.templates_host",
                package_output="package:/data/app/com.cbstudio.telltale.carproto.aaos/base.apk",
            )
        )

    # =========================================================================
    # 10. AAOS Runner (R7): Preservation of Pre-existing / Foreign Emulators
    # =========================================================================

    def test_challenge_r7_preservation_of_foreign_emulators(self):
        """CHALLENGE R7: EmulatorInstance.cleanup() must NEVER kill or terminate
        a pre-existing / foreign emulator (owned=False).
        """
        mock_foreign_proc = MagicMock()
        foreign_instance = EmulatorInstance(
            pid=99999,
            port=5554,
            serial="emulator-5554",
            owned=False,
            process=mock_foreign_proc,
        )

        with patch("subprocess.run") as mock_run:
            foreign_instance.cleanup(keep_alive=False, adb_bin=Path("/mock/adb"))

            # Verification: zero subprocess calls with emu kill
            for call_item in mock_run.call_args_list:
                args = call_item[0][0]
                self.assertNotIn("emu", args)
                self.assertNotIn("kill", args)

            # Verification: process terminate or kill was NOT called
            mock_foreign_proc.terminate.assert_not_called()
            mock_foreign_proc.kill.assert_not_called()

    def test_challenge_r7_owned_instance_strictly_killed(self):
        """CHALLENGE R7: Only owned instances (owned=True) are cleaned up with targeted serial."""
        mock_owned_proc = MagicMock()
        mock_owned_proc.poll.return_value = None

        owned_instance = EmulatorInstance(
            pid=43210,
            port=5570,
            serial="emulator-5570",
            owned=True,
            process=mock_owned_proc,
        )

        with patch("subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(args=[], returncode=0)
            owned_instance.cleanup(keep_alive=False, adb_bin=Path("/mock/adb"))

            # Must call targeted adb -s emulator-5570 emu kill
            mock_run.assert_called_once()
            called_cmd = mock_run.call_args[0][0]
            self.assertEqual(called_cmd, ["/mock/adb", "-s", "emulator-5570", "emu", "kill"])

            # Process terminate must be invoked
            mock_owned_proc.terminate.assert_called_once()


if __name__ == "__main__":
    unittest.main(verbosity=2)
