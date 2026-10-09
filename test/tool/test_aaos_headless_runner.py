#!/usr/bin/env python3
"""Unit tests for tool/aaos_headless_runner.py."""

from __future__ import annotations

from pathlib import Path
import sys
import unittest

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
    build_adb_prefix,
    build_emulator_launch_cmd,
    build_gear_injection_cmd,
    build_speed_injection_cmd,
    main,
    parse_stage1_response,
    parse_stage2_response,
    parse_stage3_response,
    parse_stage4_response,
    run_dry_run,
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


if __name__ == "__main__":
    unittest.main()
