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

        # Suite events
        lines.append(json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/l10n/test.dart"}}))
        lines.append(json.dumps({"type": "suite", "suite": {"id": 2, "path": "test/l10n/test_a11y.dart"}}))

        # startup / start events
        if include_c01:
            lines.append(json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": 1}}))
        if include_c09:
            lines.append(json.dumps({"type": "testStart", "test": {"id": 2, "name": "Test Suite [C09.1] A11y", "suiteID": 2}}))

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

    def test_reject_one_test_covering_two_required_cases(self):
        """Negative 1: Single test cannot satisfy multiple required cases (1-to-1 violation)."""
        manifest_data = dict(self.manifest_data)
        # Attempt to map C09.1 to the same test name as C01
        manifest_data["cases"] = [
            dict(manifest_data["cases"][0]),
            {
                "caseId": "C09.1",
                "criterionId": "AC40-1",
                "suitePath": "test/l10n/test_a11y.dart",
                "qualifiedTestName": manifest_data["cases"][0]["qualifiedTestName"],
                "layer": "software-root",
                "required": True,
            },
        ]
        manifest_file = self.root / "manifest_dup_target.json"
        manifest_file.write_text(json.dumps(manifest_data), encoding="utf-8")

        # Report has only one test
        report_path = self.root / "report_single_test.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/l10n/test.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": manifest_data["cases"][0]["qualifiedTestName"], "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError):
            verify_l10n_required(manifest_file, report_path, runner_exit=0, repo_root=self.root)

    def test_reject_wrong_suite_or_wrong_qualified_name(self):
        """Negative 2: Wrong suite or wrong qualified name with matching tag is rejected."""
        report_path = self.root / "report_wrong_suite.jsonl"
        lines = [
            # Wrong suite path
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/other/wrong_suite.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 2, "path": "test/l10n/test_a11y.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": 1}}),
            json.dumps({"type": "testStart", "test": {"id": 2, "name": "Test Suite [C09.1] A11y", "suiteID": 2}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "testDone", "testID": 2, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report_path, runner_exit=0, repo_root=self.root)
        self.assertIn("missing", str(ctx.exception).lower())

    def test_reject_done_before_tests(self):
        """Negative 3: Done event appearing before any tests started is rejected."""
        report_path = self.root / "report_done_first.jsonl"
        lines = [
            json.dumps({"type": "done", "success": True}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError):
            verify_l10n_required(self.manifest_path, report_path, runner_exit=0, repo_root=self.root)

    def test_reject_done_false_after_done_true(self):
        """Negative 4: Events after done or duplicate done are rejected."""
        report_path = self.root / "report_duplicate_done.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/l10n/test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 2, "path": "test/l10n/test_a11y.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": 1}}),
            json.dumps({"type": "testStart", "test": {"id": 2, "name": "Test Suite [C09.1] A11y", "suiteID": 2}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "testDone", "testID": 2, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
            json.dumps({"type": "done", "success": False}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError):
            verify_l10n_required(self.manifest_path, report_path, runner_exit=0, repo_root=self.root)

    def test_reject_test_failure_overwritten_by_success(self):
        """Negative 5: Test failure followed by success on same testID is rejected as duplicate terminal."""
        report_path = self.root / "report_overwritten.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/l10n/test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 2, "path": "test/l10n/test_a11y.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": 1}}),
            json.dumps({"type": "testStart", "test": {"id": 2, "name": "Test Suite [C09.1] A11y", "suiteID": 2}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "failure", "hidden": False, "skipped": False}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "testDone", "testID": 2, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError):
            verify_l10n_required(self.manifest_path, report_path, runner_exit=0, repo_root=self.root)

    def test_reject_report_with_global_error(self):
        """Negative 6: Report containing error event is rejected."""
        report_path = self.root / "report_error.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/l10n/test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 2, "path": "test/l10n/test_a11y.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": 1}}),
            json.dumps({"type": "testStart", "test": {"id": 2, "name": "Test Suite [C09.1] A11y", "suiteID": 2}}),
            json.dumps({"type": "error", "error": "fatal compilation problem"}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "testDone", "testID": 2, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError):
            verify_l10n_required(self.manifest_path, report_path, runner_exit=0, repo_root=self.root)

    def test_reject_unclosed_started_test(self):
        """Negative 7: Unclosed test still running at done is rejected."""
        report_path = self.root / "report_unclosed.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/l10n/test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 2, "path": "test/l10n/test_a11y.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": 1}}),
            json.dumps({"type": "testStart", "test": {"id": 2, "name": "Test Suite [C09.1] A11y", "suiteID": 2}}),
            json.dumps({"type": "testStart", "test": {"id": 3, "name": "Extra Dangling Test", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "testDone", "testID": 2, "result": "success", "hidden": False, "skipped": False}),
            # testID 3 is never closed
            json.dumps({"type": "done", "success": True}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report_path, runner_exit=0, repo_root=self.root)
        self.assertIn("still running", str(ctx.exception).lower())

    def test_reject_string_skipped_or_hidden(self):
        """Negative 8: String boolean 'true' for skipped is rejected."""
        report_path = self.root / "report_string_skipped.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/l10n/test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 2, "path": "test/l10n/test_a11y.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": 1}}),
            json.dumps({"type": "testStart", "test": {"id": 2, "name": "Test Suite [C09.1] A11y", "suiteID": 2}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": "true"}),
            json.dumps({"type": "testDone", "testID": 2, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report_path, runner_exit=0, repo_root=self.root)
        self.assertIn("boolean", str(ctx.exception).lower())

    def test_reject_required_case_hidden(self):
        """Negative 9: Required case marked hidden is rejected."""
        report_path = self.root / "report_hidden.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/l10n/test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 2, "path": "test/l10n/test_a11y.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": 1}}),
            json.dumps({"type": "testStart", "test": {"id": 2, "name": "Test Suite [C09.1] A11y", "suiteID": 2}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": True, "skipped": False}),
            json.dumps({"type": "testDone", "testID": 2, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report_path, runner_exit=0, repo_root=self.root)
        self.assertIn("hidden", str(ctx.exception).lower())

    def test_reject_artifact_invalid_png_magic_bytes(self):
        """Negative 10: Artifact with non-PNG magic bytes is rejected."""
        # Overwrite artifact with non-PNG bytes
        self.artifact_file.write_bytes(b"NOT_A_PNG_FILE_JUST_SOME_TEXT_DATA")
        report = self._generate_report_jsonl()
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report, runner_exit=0, repo_root=self.root)
        self.assertIn("valid png", str(ctx.exception).lower())

    def test_reject_unrecognized_or_mismatched_profile(self):
        """Negative 11: Unrecognized or mismatched profile is rejected."""
        bad_manifest = dict(self.manifest_data)
        bad_manifest["profile"] = "unrecognized-unknown-profile"
        m_file = self.root / "manifest_bad_profile.json"
        m_file.write_text(json.dumps(bad_manifest), encoding="utf-8")
        report = self._generate_report_jsonl()

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(m_file, report, runner_exit=0, repo_root=self.root)
        self.assertIn("profile", str(ctx.exception).lower())

        # Also test profile mismatch against expected_profile
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(
                self.manifest_path,
                report,
                runner_exit=0,
                repo_root=self.root,
                expected_profile="hardware-profile",
            )
        self.assertIn("profile", str(ctx.exception).lower())

    def test_reject_manifest_duplicate_required_case(self):
        """Negative 12: Manifest duplicate required caseId is rejected."""
        dup_manifest = dict(self.manifest_data)
        dup_manifest["cases"] = list(self.manifest_data["cases"]) + [self.manifest_data["cases"][0]]
        m_file = self.root / "manifest_dup_case.json"
        m_file.write_text(json.dumps(dup_manifest), encoding="utf-8")
        report = self._generate_report_jsonl()

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(m_file, report, runner_exit=0, repo_root=self.root)
        self.assertIn("duplicate", str(ctx.exception).lower())

    def test_failure_clears_stale_accepted_receipt(self):
        """Receipt integrity: Verification failure overwrites stale ACCEPTED receipt."""
        receipt_path = self.root / "receipt.json"
        receipt_path.write_text(json.dumps({"status": "ACCEPTED"}), encoding="utf-8")

        report = self._generate_report_jsonl(c01_result="failure")
        with self.assertRaises(L10nRequiredError):
            verify_l10n_required(
                self.manifest_path,
                report,
                runner_exit=0,
                evidence_path=receipt_path,
                repo_root=self.root,
            )

        self.assertTrue(receipt_path.exists())
        data = json.loads(receipt_path.read_text(encoding="utf-8"))
        self.assertEqual(data["status"], "REJECTED")


if __name__ == "__main__":
    unittest.main()
