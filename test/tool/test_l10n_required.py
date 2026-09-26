#!/usr/bin/env python3
"""Unit tests and mutation coverage for tool/ci/run_l10n_required.py.

Verifies fail-closed behavior across M01-M07 mutation scenarios:
- M01: Missing required test case
- M02: Required test case failure
- M03: Required test case skip
- M04: Truncated or malformed report JSON
- M05: Nonzero runner child exit code
- M06: Missing required artifact file
- M07: Happy path control (all cases succeed and artifacts present)
"""

from __future__ import annotations

import json
import os
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
from tool.ci.run_l10n_required import verify_l10n_required, L10nRequiredError, find_flutter_bin


class TestL10nRequiredRunner(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp_dir.name)

        # Create dummy artifacts
        self.artifact_file = self.root / "test_artifact.png"
        self.artifact_file.write_bytes(b"\x89PNG\r\n\x1a\n" + b"dummy" * 50)

        # Base minimal manifest
        self.manifest_data = {
            "schemaVersion": "1.0.0",
            "profile": "test-profile",
            "cases": [
                {
                    "caseId": "C01",
                    "criterionId": "AC40-1",
                    "suitePath": "test/l10n/test.dart",
                    "qualifiedTestName": "Test Suite [C01] Language",
                    "layer": "software-root",
                    "required": True,
                },
                {
                    "caseId": "C09.1",
                    "criterionId": "AC40-1",
                    "suitePath": "test/l10n/test_a11y.dart",
                    "qualifiedTestName": "Test Suite [C09.1] A11y",
                    "layer": "software-root",
                    "required": True,
                    "artifactRoles": ["test_artifact.png"],
                },
            ],
            "nativeResiduals": [],
        }
        self.manifest_path = self.root / "manifest.json"
        self._write_manifest(self.manifest_data)

    def tearDown(self):
        self.tmp_dir.cleanup()

    def _write_manifest(self, data: dict) -> None:
        self.manifest_path.write_text(json.dumps(data), encoding="utf-8")

    def _generate_report_jsonl(
        self,
        c01_result: str = "success",
        c01_skipped: bool = False,
        c09_result: str = "success",
        c09_skipped: bool = False,
        include_c01: bool = True,
        include_c09: bool = True,
        done_success: bool = True,
        truncated: bool = False,
    ) -> Path:
        report_path = self.root / "report.jsonl"
        lines = []

        # startup / start events
        if include_c01:
            lines.append(json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language"}}))
        if include_c09:
            lines.append(json.dumps({"type": "testStart", "test": {"id": 2, "name": "Test Suite [C09.1] A11y"}}))

        if include_c01:
            lines.append(json.dumps({
                "type": "testDone",
                "testID": 1,
                "result": c01_result,
                "hidden": False,
                "skipped": c01_skipped,
            }))
        if include_c09:
            lines.append(json.dumps({
                "type": "testDone",
                "testID": 2,
                "result": c09_result,
                "hidden": False,
                "skipped": c09_skipped,
            }))

        lines.append(json.dumps({"type": "done", "success": done_success}))

        content = "\n".join(lines) + "\n"
        if truncated:
            content = content[:-10]  # truncate trailing JSON

        report_path.write_text(content, encoding="utf-8")
        return report_path

    def test_m07_happy_path_control(self):
        """M07: Valid report and artifacts pass cleanly and produce receipt."""
        report = self._generate_report_jsonl()
        receipt_path = self.root / "receipt.json"

        receipt = verify_l10n_required(
            self.manifest_path,
            report,
            runner_exit=0,
            evidence_path=receipt_path,
            repo_root=self.root,
        )

        self.assertEqual(receipt["status"], "ACCEPTED")
        self.assertEqual(receipt["requiredCasesPassed"], 2)
        self.assertEqual(receipt["requiredCasesTotal"], 2)
        self.assertTrue(receipt_path.exists())

    def test_m01_missing_required_case(self):
        """M01: Missing required test case fails closed."""
        report = self._generate_report_jsonl(include_c09=False)
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(
                self.manifest_path,
                report,
                runner_exit=0,
                repo_root=self.root,
            )
        self.assertIn("missing", str(ctx.exception).lower())

    def test_m02_required_case_failure(self):
        """M02: Test case failure in required suite fails closed."""
        report = self._generate_report_jsonl(c01_result="failure")
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(
                self.manifest_path,
                report,
                runner_exit=0,
                repo_root=self.root,
            )
        self.assertIn("failed", str(ctx.exception).lower())

    def test_m03_required_case_skipped(self):
        """M03: Skipped required test fails closed."""
        report = self._generate_report_jsonl(c01_skipped=True)
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(
                self.manifest_path,
                report,
                runner_exit=0,
                repo_root=self.root,
            )
        self.assertIn("skipped", str(ctx.exception).lower())

    def test_m04_truncated_report(self):
        """M04: Truncated report fails closed."""
        report = self._generate_report_jsonl(truncated=True)
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(
                self.manifest_path,
                report,
                runner_exit=0,
                repo_root=self.root,
            )
        self.assertIn("json", str(ctx.exception).lower())

    def test_m05_nonzero_exit_code(self):
        """M05: Nonzero runner child exit code fails closed immediately."""
        report = self._generate_report_jsonl()
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(
                self.manifest_path,
                report,
                runner_exit=1,
                repo_root=self.root,
            )
        self.assertIn("nonzero exit code", str(ctx.exception).lower())

    def test_m06_missing_required_artifact(self):
        """M06: Missing required artifact file fails closed."""
        self.artifact_file.unlink()  # remove artifact
        report = self._generate_report_jsonl()
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(
                self.manifest_path,
                report,
                runner_exit=0,
                repo_root=self.root,
            )
        self.assertIn("artifact", str(ctx.exception).lower())

    def test_find_flutter_bin_resolution(self):
        """find_flutter_bin resolves explicit flags, env vars, or sensible defaults."""
        self.assertEqual(find_flutter_bin("/custom/path/to/flutter"), "/custom/path/to/flutter")
        
        orig_env = os.environ.get("FLUTTER_BIN")
        try:
            os.environ["FLUTTER_BIN"] = "/env/path/to/flutter"
            self.assertEqual(find_flutter_bin(), "/env/path/to/flutter")
        finally:
            if orig_env is not None:
                os.environ["FLUTTER_BIN"] = orig_env
            else:
                os.environ.pop("FLUTTER_BIN", None)

        # Fallback should return a non-empty string (either PATH, local FVM, or "flutter")
        res = find_flutter_bin()
        self.assertTrue(len(res) > 0)


if __name__ == "__main__":
    unittest.main()
