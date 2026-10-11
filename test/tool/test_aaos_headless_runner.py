#!/usr/bin/env python3
"""Unit tests for tool/aaos_headless_runner.py."""

from __future__ import annotations

from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import MagicMock, patch

# Ensure repo root is on sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from tool.aaos_headless_runner import (
    DEFAULT_SCENARIOS,
    GEAR_DRIVE,
    GEAR_MAP,
    GEAR_NEUTRAL,
    GEAR_PARK,
    GEAR_REVERSE,
    PROP_GEAR_SELECTION,
    PROP_PERF_VEHICLE_SPEED,
    PROP_PERF_VEHICLE_SPEED_DISPLAY,
    SPEED_CRUISING,
    SPEED_REVERSE,
    SPEED_STATIONARY,
    AaosStateObserver,
    AdbResult,
    EmulatorInstance,
    build_adb_prefix,
    build_emulator_launch_cmd,
    build_gear_injection_cmd,
    build_speed_injection_cmd,
    find_free_emulator_port,
    main,
    parse_app_package_ready,
    parse_stage1_response,
    parse_stage2_response,
    parse_stage3_response,
    parse_stage4_response,
    parse_template_host_response,
    parse_user_unlocked_response,
    parse_vhal_gear_from_dumpsys,
    parse_vhal_speed_from_dumpsys,
    run_adb_shell,
    run_dry_run,
    run_live_execution,
    verify_stage4_readiness,
)


class AaosHeadlessRunnerTest(unittest.TestCase):
    def test_vhal_properties_and_constants(self):
        """Verify VHAL property constants align with Android VehicleProperty specifications."""
        self.assertEqual(PROP_PERF_VEHICLE_SPEED, "0x11600207")
        self.assertEqual(PROP_PERF_VEHICLE_SPEED_DISPLAY, "0x11600208")
        self.assertEqual(PROP_GEAR_SELECTION, "0x11400400")

        self.assertEqual(GEAR_PARK, 4)
        self.assertEqual(GEAR_DRIVE, 8)
        self.assertEqual(GEAR_REVERSE, 2)
        self.assertEqual(GEAR_NEUTRAL, 1)

    def test_gear_map_lookup(self):
        """Verify gear mapping supports both enum string names and numeric strings."""
        self.assertEqual(GEAR_MAP["PARK"], 4)
        self.assertEqual(GEAR_MAP["DRIVE"], 8)
        self.assertEqual(GEAR_MAP["REVERSE"], 2)
        self.assertEqual(GEAR_MAP["NEUTRAL"], 1)

        self.assertEqual(GEAR_MAP["4"], 4)
        self.assertEqual(GEAR_MAP["8"], 8)
        self.assertEqual(GEAR_MAP["2"], 2)
        self.assertEqual(GEAR_MAP["1"], 1)

    def test_speed_injection_command_generation(self):
        """Verify VHAL speed injection command structure for stationary, cruising, and reverse."""
        # 1. Stationary 0.0 m/s
        cmd_zero = build_speed_injection_cmd(SPEED_STATIONARY)
        self.assertEqual(cmd_zero, ["cmd", "car_service", "inject-vhal-event", "0x11600207", "0.0"])

        # 2. Cruising 13.89 m/s (~50 km/h)
        cmd_cruise = build_speed_injection_cmd(SPEED_CRUISING)
        self.assertEqual(cmd_cruise, ["cmd", "car_service", "inject-vhal-event", "0x11600207", "13.89"])

        # 3. Reverse -2.0 m/s (SAFE-02 negative speed boundary)
        cmd_rev = build_speed_injection_cmd(SPEED_REVERSE)
        self.assertEqual(cmd_rev, ["cmd", "car_service", "inject-vhal-event", "0x11600207", "-2.0"])

    def test_gear_injection_command_generation(self):
        """Verify VHAL gear injection command structure for all transmission gears."""
        cmd_p = build_gear_injection_cmd(GEAR_PARK)
        self.assertEqual(cmd_p, ["cmd", "car_service", "inject-vhal-event", "0x11400400", "4"])

        cmd_d = build_gear_injection_cmd(GEAR_DRIVE)
        self.assertEqual(cmd_d, ["cmd", "car_service", "inject-vhal-event", "0x11400400", "8"])

        cmd_r = build_gear_injection_cmd(GEAR_REVERSE)
        self.assertEqual(cmd_r, ["cmd", "car_service", "inject-vhal-event", "0x11400400", "2"])

        cmd_n = build_gear_injection_cmd(GEAR_NEUTRAL)
        self.assertEqual(cmd_n, ["cmd", "car_service", "inject-vhal-event", "0x11400400", "1"])

    def test_emulator_launch_command_generation(self):
        """Verify emulator background launch flags comply with headless automotive spec."""
        emu_path = Path("/mock/emulator")
        cmd = build_emulator_launch_cmd(emu_path, "AAOS_Automotive_1080p")
        self.assertEqual(cmd[0], str(emu_path))
        self.assertIn("-avd", cmd)
        self.assertIn("AAOS_Automotive_1080p", cmd)
        self.assertIn("-no-window", cmd)
        self.assertIn("-no-audio", cmd)
        self.assertIn("-no-boot-anim", cmd)
        self.assertIn("-gpu", cmd)
        self.assertIn("swiftshader_indirect", cmd)

    def test_adb_prefix_generation(self):
        """Verify adb prefix with and without target device serial."""
        adb_path = Path("/mock/adb")
        self.assertEqual(build_adb_prefix(adb_path), [str(adb_path)])
        self.assertEqual(build_adb_prefix(adb_path, "emulator-5554"), [str(adb_path), "-s", "emulator-5554"])

    def test_readiness_stage1_parser(self):
        """Verify Stage 1 (ADB connectivity) output parsing."""
        self.assertTrue(parse_stage1_response("device\n"))
        self.assertTrue(parse_stage1_response("DEVICE"))
        self.assertFalse(parse_stage1_response("offline\n"))
        self.assertFalse(parse_stage1_response("unauthorized\n"))
        self.assertFalse(parse_stage1_response(""))

    def test_readiness_stage2_parser(self):
        """Verify Stage 2 (sys.boot_completed) output parsing."""
        self.assertTrue(parse_stage2_response("1\n"))
        self.assertTrue(parse_stage2_response("1"))
        self.assertFalse(parse_stage2_response("0\n"))
        self.assertFalse(parse_stage2_response("booting\n"))
        self.assertFalse(parse_stage2_response(""))

    def test_readiness_stage3_parser(self):
        """Verify Stage 3 (service check car_service) output parsing."""
        self.assertTrue(parse_stage3_response("Service car_service: found\n"))
        self.assertTrue(parse_stage3_response("car_service: is running\n"))
        self.assertFalse(parse_stage3_response("Service car_service: not found\n"))
        self.assertFalse(parse_stage3_response("Service car_service not registered\n"))
        self.assertFalse(parse_stage3_response(""))

    def test_readiness_stage4_parser(self):
        """Verify Stage 4 (Driver User 10 readiness) output parsing."""
        self.assertTrue(parse_stage4_response("10\n"))
        self.assertTrue(parse_stage4_response("UserInfo{10:Driver:13}\n"))
        self.assertTrue(parse_stage4_response("User 10: RUNNING_UNLOCKED\n"))
        self.assertFalse(parse_stage4_response("0\n"))  # Headless system user
        self.assertFalse(parse_stage4_response("UserInfo{0:System:13}\n"))
        self.assertFalse(parse_stage4_response(""))

    def test_default_scenarios_composition(self):
        """Verify the 4 default VHAL testing scenarios covering park, drive, and reverse."""
        self.assertEqual(len(DEFAULT_SCENARIOS), 4)

        # Scenario 1: Parked Baseline
        s1 = DEFAULT_SCENARIOS[0]
        self.assertEqual(s1.name, "Parked Baseline")
        self.assertEqual(s1.gear, GEAR_PARK)
        self.assertEqual(s1.speed_mps, 0.0)
        self.assertEqual(s1.expected_motion, "STATIONARY")

        # Scenario 2: Cruising Forward
        s2 = DEFAULT_SCENARIOS[1]
        self.assertEqual(s2.name, "Drive Cruising")
        self.assertEqual(s2.gear, GEAR_DRIVE)
        self.assertEqual(s2.speed_mps, 13.89)
        self.assertEqual(s2.expected_motion, "MOVING")

        # Scenario 3: Reverse Backing (Safe gate check)
        s3 = DEFAULT_SCENARIOS[2]
        self.assertEqual(s3.name, "Reverse Backing")
        self.assertEqual(s3.gear, GEAR_REVERSE)
        self.assertEqual(s3.speed_mps, -2.0)
        self.assertEqual(s3.expected_motion, "MOVING")

        # Scenario 4: Restored Parked
        s4 = DEFAULT_SCENARIOS[3]
        self.assertEqual(s4.name, "Restored Parked")
        self.assertEqual(s4.gear, GEAR_PARK)
        self.assertEqual(s4.speed_mps, 0.0)
        self.assertEqual(s4.expected_motion, "STATIONARY")

    def test_dry_run_suite_passes(self):
        """Verify run_dry_run completes with exit code 0."""
        ret = run_dry_run(
            avd_name="AAOS_Automotive_1080p",
            emulator_bin=None,
            adb_bin=None,
            verbose=False,
        )
        self.assertEqual(ret, 0)

    def test_main_cli_dry_run_exits_zero(self):
        """Verify main() with --dry-run exits with 0."""
        ret = main(["--dry-run"])
        self.assertEqual(ret, 0)

    # -----------------------------------------------------------------------
    # R2 Tests: AdbResult, Error Token Interception & Stage 4 Readiness
    # -----------------------------------------------------------------------

    def test_adb_result_properties_and_string_representation(self):
        """Verify AdbResult properties, error detection, strip, and str behavior."""
        # Success result
        res_ok = AdbResult(
            returncode=0,
            stdout="  device ready  ",
            stderr="",
            command=["adb", "get-state"],
        )
        self.assertTrue(res_ok.is_success)
        self.assertEqual(res_ok.strip(), "device ready")
        self.assertEqual(str(res_ok), "  device ready  ")
        # Should not raise
        res_ok.raise_for_status()

        # Nonzero exit code
        res_err = AdbResult(
            returncode=19,
            stdout="",
            stderr="injection error",
            command=["adb", "shell", "cmd"],
        )
        self.assertFalse(res_err.is_success)
        with self.assertRaises(RuntimeError) as ctx:
            res_err.raise_for_status()
        self.assertIn("exit=19", str(ctx.exception))

    def test_adb_shell_nonzero_exit_code_fails(self):
        """Verify run_adb_shell raises RuntimeError when returncode is non-zero (Defect R2)."""
        with patch("subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(
                args=["adb", "shell", "cmd", "car_service"],
                returncode=19,
                stdout="",
                stderr="Error: command returned status 19",
            )
            with self.assertRaises(RuntimeError) as ctx:
                run_adb_shell(["adb"], ["cmd", "car_service"], check=True)
            self.assertIn("exit=19", str(ctx.exception))

    def test_adb_shell_security_exception_fails(self):
        """Verify run_adb_shell raises RuntimeError when SecurityException is present in output (Defect R2)."""
        with patch("subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(
                args=["adb", "shell", "cmd", "car_service"],
                returncode=0,
                stdout="java.lang.SecurityException: Permission Denial: inject-vhal-event requires car permission",
                stderr="",
            )
            with self.assertRaises(RuntimeError) as ctx:
                run_adb_shell(["adb"], ["cmd", "car_service"], check=True)
            self.assertIn("SecurityException", str(ctx.exception))

    def test_adb_shell_unknown_command_fails(self):
        """Verify run_adb_shell raises RuntimeError when 'Unknown command' is returned (Defect R2)."""
        with patch("subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(
                args=["adb", "shell", "cmd", "car_service"],
                returncode=0,
                stdout="Unknown command: inject-vhal-event",
                stderr="",
            )
            with self.assertRaises(RuntimeError) as ctx:
                run_adb_shell(["adb"], ["cmd", "car_service"], check=True)
            self.assertIn("Unknown command", str(ctx.exception))

    def test_adb_shell_permission_denial_fails(self):
        """Verify run_adb_shell raises RuntimeError when 'Permission Denial' is returned (Defect R2)."""
        with patch("subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(
                args=["adb", "shell", "cmd", "car_service"],
                returncode=0,
                stdout="Error: Permission denial for calling uid",
                stderr="",
            )
            with self.assertRaises(RuntimeError) as ctx:
                run_adb_shell(["adb"], ["cmd", "car_service"], check=True)
            self.assertIn("Permission denial", str(ctx.exception))

    def test_adb_shell_check_false_returns_result_without_raising(self):
        """Verify run_adb_shell returns AdbResult with check=False even on errors."""
        with patch("subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(
                args=["adb", "shell", "service", "check"],
                returncode=1,
                stdout="Service car_service: not found",
                stderr="",
            )
            res = run_adb_shell(["adb"], ["service", "check"], check=False)
            self.assertEqual(res.returncode, 1)
            self.assertFalse(res.is_success)
            self.assertIn("not found", res.stdout)

    def test_stage4_rejects_locked_user(self):
        """Verify Stage 4 rejects RUNNING_LOCKED and locked states for User 10 (Defect R2)."""
        self.assertFalse(parse_stage4_response("User 10: RUNNING_LOCKED\n"))
        self.assertFalse(parse_stage4_response("UserInfo{10:Driver:locked}\n"))
        self.assertFalse(parse_stage4_response("10 locked\n"))
        self.assertFalse(parse_user_unlocked_response("User 10: RUNNING_LOCKED\n"))
        self.assertFalse(parse_user_unlocked_response("false\n"))
        self.assertFalse(parse_user_unlocked_response(""))

        # Valid unlocked states must pass
        self.assertTrue(parse_stage4_response("User 10: RUNNING_UNLOCKED\n"))
        self.assertTrue(parse_user_unlocked_response("true\n"))
        self.assertTrue(parse_user_unlocked_response("User 10: RUNNING_UNLOCKED\n"))

    def test_stage4_rejects_missing_template_host(self):
        """Verify Stage 4 rejects environment lacking android.software.car.templates_host (Defect R2)."""
        output_without_host = "feature:android.hardware.wifi\nfeature:android.hardware.camera\n"
        self.assertFalse(parse_template_host_response(output_without_host))
        self.assertFalse(parse_template_host_response(""))

        output_with_host = "feature:android.software.car.templates_host\nfeature:android.hardware.wifi\n"
        self.assertTrue(parse_template_host_response(output_with_host))

    def test_stage4_rejects_missing_app_package(self):
        """Verify Stage 4 rejects environment lacking the target application package."""
        self.assertFalse(parse_app_package_ready(""))
        self.assertFalse(parse_app_package_ready("package not found\n"))
        self.assertTrue(parse_app_package_ready("package:/data/app/~~foo/com.cbstudio.telltale.carproto.aaos-bar/base.apk\n"))

    def test_stage4_full_readiness_verification(self):
        """Verify verify_stage4_readiness checks user unlocked, template host, and app package."""
        valid_u = "10"
        valid_unlocked = "true"
        valid_feat = "feature:android.software.car.templates_host"
        valid_pkg = "package:/data/app/com.cbstudio.telltale.carproto.aaos"

        # All valid
        self.assertTrue(verify_stage4_readiness(valid_u, valid_unlocked, valid_feat, valid_pkg))

        # User locked
        self.assertFalse(verify_stage4_readiness("10", "false", valid_feat, valid_pkg))
        # Template host missing
        self.assertFalse(verify_stage4_readiness(valid_u, valid_unlocked, "", valid_pkg))
        # App missing
        self.assertFalse(verify_stage4_readiness(valid_u, valid_unlocked, valid_feat, ""))

    # -----------------------------------------------------------------------
    # R2 Tests: VHAL Dumpsys & End-to-End State Observation
    # -----------------------------------------------------------------------

    def test_vhal_dumpsys_speed_parser(self):
        """Verify parse_vhal_speed_from_dumpsys handles dumpsys formats."""
        dumpsys_1 = "Property: 0x11600207, Area: 0, Value: 13.89"
        self.assertEqual(parse_vhal_speed_from_dumpsys(dumpsys_1), 13.89)

        dumpsys_2 = "291504647 floatValues: [0.0]"
        self.assertEqual(parse_vhal_speed_from_dumpsys(dumpsys_2), 0.0)

        dumpsys_3 = "PERF_VEHICLE_SPEED: -2.0"
        self.assertEqual(parse_vhal_speed_from_dumpsys(dumpsys_3), -2.0)

        dumpsys_4 = "0x11600207 15.5"
        self.assertEqual(parse_vhal_speed_from_dumpsys(dumpsys_4), 15.5)

        self.assertIsNone(parse_vhal_speed_from_dumpsys("Empty dumpsys"))
        self.assertIsNone(parse_vhal_speed_from_dumpsys(""))

    def test_vhal_dumpsys_gear_parser(self):
        """Verify parse_vhal_gear_from_dumpsys handles dumpsys formats."""
        dumpsys_1 = "Property: 0x11400400, Area: 0, Value: 4"
        self.assertEqual(parse_vhal_gear_from_dumpsys(dumpsys_1), 4)

        dumpsys_2 = "289408000 int32Values: [8]"
        self.assertEqual(parse_vhal_gear_from_dumpsys(dumpsys_2), 8)

        dumpsys_3 = "GEAR_SELECTION: 2"
        self.assertEqual(parse_vhal_gear_from_dumpsys(dumpsys_3), 2)

        dumpsys_4 = "0x11400400 1"
        self.assertEqual(parse_vhal_gear_from_dumpsys(dumpsys_4), 1)

        self.assertIsNone(parse_vhal_gear_from_dumpsys("Empty dumpsys"))

    def test_observer_state_evaluation_stationary(self):
        """Verify AaosStateObserver evaluates Park & speed 0 as STATIONARY and DTC accessible."""
        observer = AaosStateObserver(["adb", "-s", "emulator-5554"])
        with patch("tool.aaos_headless_runner.run_adb_shell", return_value=AdbResult(0, "", "", [])):
            with patch.object(observer, "observe_app_ui", return_value='text="Telltale" text="Vehicle stationary" text="Diagnostic Codes"'):
                self.assertEqual(observer.observe_motion_state(), "STATIONARY")
                self.assertTrue(observer.verify_dtc_accessible())

    def test_observer_state_evaluation_moving(self):
        """Verify AaosStateObserver evaluates speed > 0 as MOVING, auto-pop triggered, and DTC not accessible."""
        observer = AaosStateObserver(["adb", "-s", "emulator-5554"])
        observer._dtc_origin_ui = 'text="Telltale" text="Diagnostic Codes"'
        with patch("tool.aaos_headless_runner.run_adb_shell", return_value=AdbResult(0, "", "", [])):
            with patch.object(observer, "observe_app_ui", return_value='text="Telltale" text="Vehicle moving" text="Vehicle Health"'):
                self.assertEqual(observer.observe_motion_state(), "MOVING")
                self.assertFalse(observer.verify_dtc_accessible())
                with patch("tool.aaos_headless_runner.run_adb_shell") as mock_shell:
                    mock_shell.return_value = AdbResult(0, "popTo CAR_HEALTH", "", [])
                    self.assertTrue(observer.verify_autopop_occurred())

    def test_identical_health_before_and_after_is_not_autopop(self):
        observer = AaosStateObserver(["adb", "-s", "emulator-5554"])
        identical = 'text="Telltale" text="Vehicle Health" text="Vehicle moving"'
        observer._dtc_origin_ui = identical
        with patch.object(observer, "observe_motion_state", return_value="MOVING"):
            with patch.object(observer, "observe_app_ui", return_value=identical):
                self.assertFalse(observer.verify_autopop_occurred())

    def test_navigate_to_dtc_requires_unique_diagnostic_codes_destination(self):
        observer = AaosStateObserver(["adb", "-s", "emulator-5554"])
        source = (
            'text="Telltale" text="Vehicle Health" '
            'text="Diagnostic Codes" bounds="[100,200][500,300]"'
        )
        destination = 'text="Telltale" text="Diagnostic Codes" text="Trouble code list"'
        with patch.object(observer, "observe_app_ui", side_effect=[source, destination]):
            with patch("tool.aaos_headless_runner.run_adb_shell", return_value=AdbResult(0, "", "", [])) as shell:
                self.assertTrue(observer.navigate_to_dtc_screen(timeout=0.1))
                self.assertEqual(observer._dtc_origin_ui, destination)
                self.assertIn("input", shell.call_args.args[1])

        observer = AaosStateObserver(["adb", "-s", "emulator-5554"])
        with patch.object(observer, "observe_app_ui", return_value='text="Telltale" text="DTC status"'):
            self.assertFalse(observer.navigate_to_dtc_screen(timeout=0.01))

    def test_observer_state_evaluation_reverse(self):
        """Verify AaosStateObserver evaluates reverse speed as MOVING and DTC strictly blocked."""
        observer = AaosStateObserver(["adb", "-s", "emulator-5554"])
        with patch("tool.aaos_headless_runner.run_adb_shell", return_value=AdbResult(0, "", "", [])):
            with patch.object(observer, "observe_app_ui", return_value='text="Telltale" text="Vehicle moving" text="Park to view DTC"'):
                self.assertEqual(observer.observe_motion_state(), "MOVING")
                self.assertTrue(observer.verify_dtc_blocked())
                self.assertFalse(observer.verify_dtc_accessible())

    def test_vhal_echo_without_app_observation_is_unknown(self):
        observer = AaosStateObserver(["adb", "-s", "emulator-5554"])
        with patch.object(observer, "get_vhal_property_speed", return_value=13.89):
            with patch.object(observer, "get_vhal_property_gear", return_value=GEAR_DRIVE):
                with patch("tool.aaos_headless_runner.run_adb_shell", return_value=AdbResult(0, "", "", [])):
                    with patch.object(observer, "observe_app_ui", return_value=""):
                        self.assertEqual(observer.observe_motion_state(), "UNKNOWN")
                        self.assertFalse(observer.verify_autopop_occurred())
                        self.assertFalse(observer.verify_dtc_blocked())

    def test_unrelated_nonempty_ui_is_not_application_evidence(self):
        observer = AaosStateObserver(["adb", "-s", "emulator-5554"])
        with patch.object(observer, "observe_app_ui", return_value='text="Maps" text="Vehicle moving" text="Health"'):
            self.assertEqual(observer.observe_motion_state(), "UNKNOWN")
            self.assertFalse(observer.verify_dtc_accessible())
            self.assertFalse(observer.verify_autopop_occurred())

    def test_failed_fresh_ui_dump_never_reuses_stale_xml(self):
        observer = AaosStateObserver(["adb", "-s", "emulator-5554"])
        responses = [
            AdbResult(0, "", "", []),
            AdbResult(1, "", "dump failed", []),
            AdbResult(0, 'text="Telltale" text="Vehicle moving"', "", []),
        ]
        with patch("tool.aaos_headless_runner.run_adb_shell", side_effect=responses) as shell:
            self.assertEqual(observer.observe_app_ui(), "")
            self.assertEqual(shell.call_count, 2)

    def _create_fake_adb_run(self, fail_inject_cmd: bool = False, inject_exit_code: int = 0, inject_output: str = "success"):
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
                if fail_inject_cmd:
                    return subprocess.CompletedProcess(
                        args=cmd,
                        returncode=inject_exit_code,
                        stdout=inject_output if inject_exit_code == 0 else "",
                        stderr="Rejected" if inject_exit_code != 0 else "",
                    )
                return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="success\n", stderr="")
            return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="", stderr="")
        return fake_run

    def test_scenario_fails_if_sample_unreceived(self):
        """Verify scenario fails and returns 1 when speed sample is not received (Defect R2)."""
        observer = MagicMock(spec=AaosStateObserver)
        # Sample never arrives, and motion does not match expected
        observer.verify_sample_received.return_value = False
        observer.observe_motion_state.return_value = "UNKNOWN"

        with patch("subprocess.run") as mock_run:
            mock_run.side_effect = self._create_fake_adb_run()
            ret = run_live_execution(
                avd_name="AAOS_Automotive_1080p",
                serial="emulator-5554",
                emulator_bin=None,
                adb_bin=Path(sys.executable),
                skip_launch=True,
                boot_timeout=5,
                observer=observer,
            )
            self.assertEqual(ret, 1)

    def test_scenario_fails_if_autopop_does_not_occur(self):
        """Verify scenario fails and returns 1 when cruising speed does not trigger auto-pop (Defect R2)."""
        observer = MagicMock(spec=AaosStateObserver)
        observer.verify_sample_received.return_value = True
        # First scenario (Parked Baseline): STATIONARY
        # Second scenario (Drive Cruising): MOVING, but auto-pop fails to trigger
        observer.observe_motion_state.side_effect = [
            "STATIONARY",
            "MOVING",
            "MOVING",
        ]
        observer.verify_dtc_accessible.return_value = True
        observer.verify_autopop_occurred.return_value = False

        with patch("subprocess.run") as mock_run:
            mock_run.side_effect = self._create_fake_adb_run()
            ret = run_live_execution(
                avd_name="AAOS_Automotive_1080p",
                serial="emulator-5554",
                emulator_bin=None,
                adb_bin=Path(sys.executable),
                skip_launch=True,
                boot_timeout=5,
                observer=observer,
            )
            self.assertEqual(ret, 1)

    def test_scenario_fails_if_dtc_not_blocked_on_reverse(self):
        """Verify scenario fails and returns 1 when reverse speed does not block DTC (Defect R2)."""
        observer = MagicMock(spec=AaosStateObserver)
        observer.verify_sample_received.return_value = True
        observer.observe_motion_state.side_effect = [
            "STATIONARY",
            "MOVING",
            "MOVING",
        ]
        observer.verify_dtc_accessible.return_value = True
        observer.verify_autopop_occurred.return_value = True
        observer.verify_dtc_blocked.return_value = False  # Reverse DTC block failed!

        with patch("subprocess.run") as mock_run:
            mock_run.side_effect = self._create_fake_adb_run()
            ret = run_live_execution(
                avd_name="AAOS_Automotive_1080p",
                serial="emulator-5554",
                emulator_bin=None,
                adb_bin=Path(sys.executable),
                skip_launch=True,
                boot_timeout=5,
                observer=observer,
            )
            self.assertEqual(ret, 1)

    def test_scenario_fails_if_injection_rejected(self):
        """Verify scenario fails and returns 1 immediately when VHAL injection returns exit 19 (Defect R2)."""
        with patch("subprocess.run") as mock_run:
            mock_run.side_effect = self._create_fake_adb_run(fail_inject_cmd=True, inject_exit_code=19)
            ret = run_live_execution(
                avd_name="AAOS_Automotive_1080p",
                serial="emulator-5554",
                emulator_bin=None,
                adb_bin=Path(sys.executable),
                skip_launch=True,
                boot_timeout=5,
            )
            self.assertEqual(ret, 1)

    def test_scenario_fails_if_command_unsupported(self):
        """Verify scenario fails and returns 1 when inject-vhal-event command is unsupported (Defect R2)."""
        with patch("subprocess.run") as mock_run:
            mock_run.side_effect = self._create_fake_adb_run(
                fail_inject_cmd=True,
                inject_exit_code=0,
                inject_output="Unknown command: inject-vhal-event",
            )
            ret = run_live_execution(
                avd_name="AAOS_Automotive_1080p",
                serial="emulator-5554",
                emulator_bin=None,
                adb_bin=Path(sys.executable),
                skip_launch=True,
                boot_timeout=5,
            )
            self.assertEqual(ret, 1)

    # -----------------------------------------------------------------------
    # R7 Tests: EmulatorInstance Lifecycle & Pre-existing Emulator Preservation
    # -----------------------------------------------------------------------

    def test_cleanup_preserves_foreign_emulator(self):
        """Verify cleanup does not terminate or kill foreign/pre-existing emulators (Defect R7)."""
        foreign_instance = EmulatorInstance(
            pid=99999,
            port=5554,
            serial="emulator-5554",
            owned=False,
            process=MagicMock(),
        )

        with patch("subprocess.run") as mock_run:
            foreign_instance.cleanup(keep_alive=False, adb_bin=Path("/mock/adb"))
            # Must NOT call emu kill
            for call_item in mock_run.call_args_list:
                args = call_item[0][0]
                self.assertNotIn("emu", args)
                self.assertNotIn("kill", args)
            # Process terminate must NOT be called
            foreign_instance.process.terminate.assert_not_called()
            foreign_instance.process.kill.assert_not_called()

    def test_cleanup_only_kills_owned_instance(self):
        """Verify cleanup terminates ONLY instances owned by this script (Defect R7)."""
        mock_proc = MagicMock()
        mock_proc.poll.return_value = None

        owned_instance = EmulatorInstance(
            pid=12345,
            port=5584,
            serial="emulator-5584",
            owned=True,
            process=mock_proc,
        )

        with patch("subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(args=[], returncode=0)
            owned_instance.cleanup(keep_alive=False, adb_bin=Path("/mock/adb"))

            # Must call adb -s emulator-5584 emu kill (strictly targeted)
            mock_run.assert_called_once()
            called_cmd = mock_run.call_args[0][0]
            self.assertEqual(called_cmd, ["/mock/adb", "-s", "emulator-5584", "emu", "kill"])

            # Process terminate must be called
            mock_proc.terminate.assert_called_once()

    def test_find_free_emulator_port(self):
        """Verify find_free_emulator_port returns an available even port in [5554, 5584]."""
        with patch("subprocess.run") as mock_run:
            mock_run.return_value = subprocess.CompletedProcess(
                args=["adb", "devices"],
                returncode=0,
                stdout="List of devices attached\nemulator-5554\tdevice\n\n",
            )
            port = find_free_emulator_port(Path("/mock/adb"))
            self.assertGreaterEqual(port, 5556)
            self.assertLessEqual(port, 5584)
            self.assertEqual(port % 2, 0)

    def test_live_execution_full_flow_success_with_mock_observer(self):
        """Verify run_live_execution full success flow with all readiness checks and observer passed."""
        observer = MagicMock(spec=AaosStateObserver)
        observer.verify_sample_received.return_value = True
        observer.observe_motion_state.side_effect = [
            "STATIONARY", "MOVING", "MOVING", "STATIONARY"
        ]
        observer.verify_dtc_accessible.return_value = True
        observer.verify_autopop_occurred.return_value = True
        observer.verify_dtc_blocked.return_value = True

        with patch("subprocess.run") as mock_run:
            mock_run.side_effect = self._create_fake_adb_run()
            ret = run_live_execution(
                avd_name="AAOS_Automotive_1080p",
                serial="emulator-5554",
                emulator_bin=None,
                adb_bin=Path(sys.executable),
                skip_launch=True,
                boot_timeout=5,
                observer=observer,
            )
            self.assertEqual(ret, 0)


if __name__ == "__main__":
    unittest.main()
