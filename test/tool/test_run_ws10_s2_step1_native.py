#!/usr/bin/env python3
"""Unit tests for tool/ci/run_ws10_s2_step1_native.py runner."""

import json
from pathlib import Path
import tempfile
import unittest

from tool.ci.run_ws10_s2_step1_native import find_tool, run


class TestRunWs10S2Step1Native(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.output_dir = Path(self.temp_dir.name) / "output"

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_find_tool(self):
        # python3 should always exist
        py_tool = find_tool("python3")
        self.assertIsNotNone(py_tool)
        # nonexistent tool
        non_tool = find_tool("nonexistent_compiler_xyz_123")
        self.assertIsNone(non_tool)

    def test_run_generates_valid_summary(self):
        exit_code = run(self.output_dir)
        self.assertEqual(exit_code, 0)
        summary_file = self.output_dir / "summary.json"
        self.assertTrue(summary_file.exists())
        data = json.loads(summary_file.read_text(encoding="utf-8"))
        self.assertEqual(data.get("step"), "ws10-s2-step1-native")
        self.assertIn(data.get("status"), ["PASS", "SKIPPED"])

    def test_require_toolchain_fail_closed_on_missing_tools(self):
        from unittest.mock import patch
        with patch("tool.ci.run_ws10_s2_step1_native.find_tool", return_value=None):
            exit_code = run(self.output_dir, require_toolchain=True)
            self.assertEqual(exit_code, 1)
            summary_file = self.output_dir / "summary.json"
            self.assertTrue(summary_file.exists())
            data = json.loads(summary_file.read_text(encoding="utf-8"))
            self.assertEqual(data.get("status"), "FAIL")
            self.assertIn("missing", data.get("error", ""))

    def test_manifest_validation_fail_on_missing_test(self):
        from unittest.mock import patch, MagicMock
        mock_ctest_res = MagicMock()
        mock_ctest_res.returncode = 0
        # Simulated output with only 1 test instead of required 11
        mock_ctest_res.stdout = "1/1 Test #1: ws10_isotp_unit_tests ............   Passed    0.01 sec\n"

        with patch("tool.ci.run_ws10_s2_step1_native.subprocess.run") as mock_run:
            def side_effect(cmd, *args, **kwargs):
                if "--build" in cmd or "-B" in cmd:
                    res = MagicMock()
                    res.returncode = 0
                    res.stdout = ""
                    res.stderr = ""
                    return res
                return mock_ctest_res

            mock_run.side_effect = side_effect
            exit_code = run(self.output_dir, require_toolchain=True)
            self.assertEqual(exit_code, 1)
            summary_file = self.output_dir / "summary.json"
            data = json.loads(summary_file.read_text(encoding="utf-8"))
            self.assertEqual(data.get("status"), "FAIL")
            self.assertIn("missing required tests", data.get("error", ""))

    def test_manifest_validation_fail_on_extra_test(self):
        from unittest.mock import patch, MagicMock
        from tool.ci.run_ws10_s2_step1_native import REQUIRED_TESTS
        mock_ctest_res = MagicMock()
        mock_ctest_res.returncode = 0
        lines = [f"1/12 Test #{i+1}: {t} .... Passed 0.01 sec" for i, t in enumerate(REQUIRED_TESTS)]
        lines.append("12/12 Test #12: unapproved_rogue_test .... Passed 0.01 sec")
        mock_ctest_res.stdout = "\n".join(lines) + "\n"

        with patch("tool.ci.run_ws10_s2_step1_native.subprocess.run") as mock_run:
            def side_effect(cmd, *args, **kwargs):
                if "--build" in cmd or "-B" in cmd:
                    res = MagicMock()
                    res.returncode = 0
                    res.stdout = ""
                    res.stderr = ""
                    return res
                return mock_ctest_res

            mock_run.side_effect = side_effect
            exit_code = run(self.output_dir, require_toolchain=True)
            self.assertEqual(exit_code, 1)
            summary_file = self.output_dir / "summary.json"
            data = json.loads(summary_file.read_text(encoding="utf-8"))
            self.assertEqual(data.get("status"), "FAIL")
            self.assertIn("unapproved extra tests", data.get("error", ""))


if __name__ == "__main__":
    unittest.main()
