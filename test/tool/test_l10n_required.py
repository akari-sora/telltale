#!/usr/bin/env python3
"""Unit tests and mutation coverage for tool/ci/run_l10n_required.py.

Verifies fail-closed behavior across M01-M07 mutation scenarios and G-EVENT,
G-SUITE, G-MANIFEST, G-CENSUS, G-PNG, G-RUN, G-FAILURE, G-ARCHIVE regressions:
- M01: Missing required test case
- M02: Required test case failure
- M03: Required test case skip
- M04: Truncated or malformed report JSON
- M05: Nonzero runner child exit code
- M06: Missing required artifact file
- M07: Happy path control (all cases succeed and artifacts present)
- G-SUITE: Missing suite, unknown suiteID, duplicate suite, boolean suite ID
- G-EVENT: Duplicate testStart, testStart after terminal borrowing outcome, unclosed tests
- G-CENSUS: Unrelated test failure in report, 1-to-1 violation
- G-MANIFEST: Duplicate JSON keys, unsupported schemaVersion, string required field
- G-PNG: PNG magic with junk bytes, corrupt IDAT, trailing junk
- G-FAILURE: Child process spawn failure overwrites stale ACCEPTED receipt
- G-ARCHIVE: Complete atomic archive bundle creation and failure fail-closed behavior
"""

from __future__ import annotations

import json
import os
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import zlib

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))
from tool.ci.run_l10n_required import (
    verify_l10n_required,
    L10nRequiredError,
    find_flutter_bin,
    main as runner_main,
)


def make_valid_png(width: int = 1, height: int = 1) -> bytes:
    """Generates a strictly valid minimal RGBA PNG."""
    def chunk(ctype: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + ctype
            + data
            + struct.pack(">I", zlib.crc32(ctype + data) & 0xFFFFFFFF)
        )

    magic = b"\x89PNG\r\n\x1a\n"
    ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    raw_scanlines = b"".join(b"\x00" + b"\x00\x00\x00\xff" * width for _ in range(height))
    idat = chunk(b"IDAT", zlib.compress(raw_scanlines))
    iend = chunk(b"IEND", b"")
    return magic + ihdr + idat + iend


class TestL10nRequiredRunner(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp_dir.name)

        # Create valid artifact PNG
        self.artifact_file = self.root / "test_artifact.png"
        self.artifact_file.write_bytes(make_valid_png(1, 1))

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
        self.assertEqual(receipt["executionStatus"], "EXECUTION_PASS")
        self.assertEqual(receipt["reviewStatus"], "PENDING_REVIEW")
        self.assertEqual(receipt["provenanceLevel"], "C1A_R2B_PRODUCTION_PROOF_ACCEPTED")
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
        self.assertTrue("failed" in str(ctx.exception).lower() or "failing" in str(ctx.exception).lower())

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

        res = find_flutter_bin()
        self.assertTrue(len(res) > 0)

    def test_reject_one_test_covering_two_required_cases(self):
        """Negative 1: Single test cannot satisfy multiple required cases (1-to-1 violation)."""
        manifest_data = dict(self.manifest_data)
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
        self.artifact_file.write_bytes(b"NOT_A_PNG_FILE_JUST_SOME_TEXT_DATA")
        report = self._generate_report_jsonl()
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report, runner_exit=0, repo_root=self.root)
        self.assertIn("png", str(ctx.exception).lower())

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

    # --- New G-Suite, G-Event, G-Manifest, G-PNG, G-Failure, G-Archive Regressions ---

    def test_reject_png_magic_plus_junk(self):
        """G-PNG: PNG with magic bytes followed by arbitrary junk is rejected by chunk parser."""
        self.artifact_file.write_bytes(b"\x89PNG\r\n\x1a\n" + b"junk_bytes_instead_of_chunks" * 10)
        report = self._generate_report_jsonl()
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report, runner_exit=0, repo_root=self.root)
        self.assertTrue("png" in str(ctx.exception).lower() or "chunk" in str(ctx.exception).lower())

    def test_reject_missing_or_empty_suite_path(self):
        """G-SUITE: Suite event with empty or whitespace path is rejected."""
        report_path = self.root / "report_empty_suite_path.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "   "}}),
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
        self.assertIn("suite", str(ctx.exception).lower())

    def test_reject_unknown_suite_in_test_start(self):
        """G-SUITE: testStart referencing undeclared suiteID is rejected."""
        report_path = self.root / "report_unknown_suite_id.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/l10n/test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 2, "path": "test/l10n/test_a11y.dart"}}),
            # testID 1 points to unknown suiteID 99
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": 99}}),
            json.dumps({"type": "testStart", "test": {"id": 2, "name": "Test Suite [C09.1] A11y", "suiteID": 2}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "testDone", "testID": 2, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report_path, runner_exit=0, repo_root=self.root)
        self.assertIn("unknown suiteid", str(ctx.exception).lower())

    def test_reject_duplicate_suite_id(self):
        """G-SUITE: Duplicate suite definition for the same suite ID is rejected."""
        report_path = self.root / "report_dup_suite.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/l10n/test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/l10n/test_other.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report_path, runner_exit=0, repo_root=self.root)
        self.assertIn("duplicate suite", str(ctx.exception).lower())

    def test_reject_boolean_suite_id_or_ref(self):
        """G-SUITE: Boolean value for suite.id or testStart.suiteID is rejected."""
        report_path = self.root / "report_bool_suite.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": True, "path": "test/l10n/test.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": True}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report_path, runner_exit=0, repo_root=self.root)
        self.assertIn("suite", str(ctx.exception).lower())

    def test_reject_duplicate_test_start(self):
        """G-EVENT: Duplicate testStart for the same test ID is rejected."""
        report_path = self.root / "report_dup_start.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/l10n/test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 2, "path": "test/l10n/test_a11y.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": 1}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Another Name", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report_path, runner_exit=0, repo_root=self.root)
        self.assertIn("duplicate teststart", str(ctx.exception).lower())

    def test_reject_test_start_after_terminal_borrowing_result(self):
        """G-EVENT: testStart issued after testDone borrowing result is rejected."""
        report_path = self.root / "report_borrow_terminal.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/l10n/test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 2, "path": "test/l10n/test_a11y.dart"}}),
            # testID 1 starts as Non-Required
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Unrelated Test", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            # testID 1 reissued as required name after terminal
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": 1}}),
            json.dumps({"type": "testStart", "test": {"id": 2, "name": "Test Suite [C09.1] A11y", "suiteID": 2}}),
            json.dumps({"type": "testDone", "testID": 2, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report_path, runner_exit=0, repo_root=self.root)
        self.assertTrue("terminated" in str(ctx.exception).lower() or "duplicate" in str(ctx.exception).lower())

    def test_reject_unrelated_test_failure_in_report(self):
        """G-CENSUS: Unrelated test failure in report fails closed even if all required cases pass."""
        report_path = self.root / "report_extra_failure.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/l10n/test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 2, "path": "test/l10n/test_a11y.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Test Suite [C01] Language", "suiteID": 1}}),
            json.dumps({"type": "testStart", "test": {"id": 2, "name": "Test Suite [C09.1] A11y", "suiteID": 2}}),
            json.dumps({"type": "testStart", "test": {"id": 3, "name": "Unrelated Failing Test", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "testDone", "testID": 2, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "testDone", "testID": 3, "result": "failure", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report_path, runner_exit=0, repo_root=self.root)
        self.assertTrue("failed" in str(ctx.exception).lower() or "failing" in str(ctx.exception).lower())

    def test_reject_manifest_duplicate_json_keys(self):
        """G-MANIFEST: Duplicate JSON keys in manifest are rejected by strict parser."""
        bad_json = """{
            "schemaVersion": "1.0.0",
            "profile": "test-profile",
            "profile": "other-profile",
            "cases": []
        }"""
        m_file = self.root / "manifest_dup_keys.json"
        m_file.write_text(bad_json, encoding="utf-8")
        report = self._generate_report_jsonl()

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(m_file, report, runner_exit=0, repo_root=self.root)
        self.assertIn("duplicate json key", str(ctx.exception).lower())

    def test_reject_manifest_unsupported_schema_version(self):
        """G-MANIFEST: Unsupported manifest schemaVersion is rejected."""
        manifest_data = dict(self.manifest_data)
        manifest_data["schemaVersion"] = "99.0.0"
        m_file = self.root / "manifest_unsupported_schema.json"
        m_file.write_text(json.dumps(manifest_data), encoding="utf-8")
        report = self._generate_report_jsonl()

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(m_file, report, runner_exit=0, repo_root=self.root)
        self.assertIn("schemaversion", str(ctx.exception).lower())

    def test_reject_manifest_string_required(self):
        """G-MANIFEST: String 'true' for case.required is rejected with non-boolean type error."""
        manifest_data = dict(self.manifest_data)
        manifest_data["cases"] = [
            {
                "caseId": "C01",
                "criterionId": "AC40-1",
                "suitePath": "test/l10n/test.dart",
                "qualifiedTestName": "Test Suite [C01] Language",
                "layer": "software-root",
                "required": "true",  # String instead of bool!
            }
        ]
        m_file = self.root / "manifest_string_req.json"
        m_file.write_text(json.dumps(manifest_data), encoding="utf-8")
        report = self._generate_report_jsonl()

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(m_file, report, runner_exit=0, repo_root=self.root)
        self.assertIn("non-boolean", str(ctx.exception).lower())

    def test_archive_failure_overwrites_rejected_receipt(self):
        """G-ARCHIVE: Archive failure (e.g. destination collision) fails closed and writes REJECTED receipt."""
        bundle_dir = self.root / "broken_bundle"
        bundle_dir.mkdir(parents=True)
        # Create collision where manifest.json is a directory
        (bundle_dir / "manifest.json").mkdir()

        receipt_path = self.root / "receipt.json"
        receipt_path.write_text(json.dumps({"status": "ACCEPTED"}), encoding="utf-8")
        report = self._generate_report_jsonl()

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(
                self.manifest_path,
                report,
                runner_exit=0,
                evidence_path=receipt_path,
                bundle_dir=bundle_dir,
                repo_root=self.root,
            )
        self.assertIn("archive failed", str(ctx.exception).lower())
        data = json.loads(receipt_path.read_text(encoding="utf-8"))
        self.assertEqual(data["status"], "REJECTED")
        self.assertEqual(data["executionStatus"], "EXECUTION_FAIL")

    def test_main_spawn_failure_overwrites_rejected_receipt(self):
        """G-FAILURE: Subprocess spawn failure in main() writes REJECTED receipt and returns 1."""
        receipt_path = self.root / "receipt_spawn_fail.json"
        receipt_path.write_text(json.dumps({"status": "ACCEPTED"}), encoding="utf-8")

        rc = runner_main([
            "--flutter",
            "/nonexistent/binary/path/that/cannot/exist",
            "--manifest",
            str(self.manifest_path),
            "--evidence",
            str(receipt_path),
            "--expected-profile",
            "test-profile",
        ])
        self.assertEqual(rc, 1)
        data = json.loads(receipt_path.read_text(encoding="utf-8"))
        self.assertEqual(data["status"], "REJECTED")
        self.assertEqual(data["executionStatus"], "EXECUTION_FAIL")
        self.assertIn("child spawn failed", data["error"].lower())

    def test_main_missing_report_file_overwrites_rejected_receipt(self):
        """G-FAILURE: Missing report file passed via --report writes REJECTED receipt and returns 1."""
        receipt_path = self.root / "receipt_missing_report.json"
        receipt_path.write_text(json.dumps({"status": "ACCEPTED"}), encoding="utf-8")

        rc = runner_main([
            "--flutter",
            "flutter",
            "--manifest",
            str(self.manifest_path),
            "--report",
            str(self.root / "nonexistent_report.jsonl"),
            "--evidence",
            str(receipt_path),
            "--expected-profile",
            "test-profile",
        ])
        self.assertEqual(rc, 1)
        data = json.loads(receipt_path.read_text(encoding="utf-8"))
        self.assertEqual(data["status"], "REJECTED")
        self.assertEqual(data["executionStatus"], "EXECUTION_FAIL")
        self.assertIn("report not found", data["error"].lower())

    def test_normalize_suite_path_resolves_dot_dot_segments(self):
        """G-SUITE: Suite paths containing relative navigation segments are canonicalized."""
        from tool.ci.run_l10n_required import normalize_suite_path
        p = "test/../test/l10n/test.dart"
        self.assertEqual(normalize_suite_path(p, self.root), "test/l10n/test.dart")

    def test_reject_png_invalid_color_type(self):
        """G-PNG: PNG with invalid RFC 2083 color_type is rejected."""
        def chunk(ctype: bytes, data: bytes) -> bytes:
            return struct.pack(">I", len(data)) + ctype + data + struct.pack(">I", zlib.crc32(ctype + data) & 0xFFFFFFFF)
        magic = b"\x89PNG\r\n\x1a\n"
        ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 99, 0, 0, 0))
        idat = chunk(b"IDAT", zlib.compress(b"\x00\x00\x00\x00\xff"))
        self.artifact_file.write_bytes(magic + ihdr + idat + chunk(b"IEND", b""))
        report = self._generate_report_jsonl()
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report, runner_exit=0, repo_root=self.root)
        self.assertIn("color type", str(ctx.exception).lower())

    def test_reject_png_dimension_overflow(self):
        """G-PNG: PNG with dimension exceeding RFC 2083 2^31 - 1 limit is rejected."""
        def chunk(ctype: bytes, data: bytes) -> bytes:
            return struct.pack(">I", len(data)) + ctype + data + struct.pack(">I", zlib.crc32(ctype + data) & 0xFFFFFFFF)
        magic = b"\x89PNG\r\n\x1a\n"
        ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", 0x80000000, 1, 8, 6, 0, 0, 0))
        idat = chunk(b"IDAT", zlib.compress(b"\x00\x00\x00\x00\xff"))
        self.artifact_file.write_bytes(magic + ihdr + idat + chunk(b"IEND", b""))
        report = self._generate_report_jsonl()
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report, runner_exit=0, repo_root=self.root)
        self.assertIn("dimensions", str(ctx.exception).lower())

    def test_reject_png_decompressed_payload_mismatch(self):
        """G-PNG: PNG with decompressed payload length mismatching dimensions is rejected."""
        def chunk(ctype: bytes, data: bytes) -> bytes:
            return struct.pack(">I", len(data)) + ctype + data + struct.pack(">I", zlib.crc32(ctype + data) & 0xFFFFFFFF)
        magic = b"\x89PNG\r\n\x1a\n"
        ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", 100, 100, 8, 6, 0, 0, 0))
        idat = chunk(b"IDAT", zlib.compress(b"short_dummy_payload"))
        self.artifact_file.write_bytes(magic + ihdr + idat + chunk(b"IEND", b""))
        report = self._generate_report_jsonl()
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(self.manifest_path, report, runner_exit=0, repo_root=self.root)
        self.assertIn("payload length", str(ctx.exception).lower())

    def test_reject_conflicting_artifact_destinations(self):
        """G-ARCHIVE: Conflicting artifact destinations with differing digests are rejected."""
        bundle_dir = self.root / "conflict_bundle"
        art1 = self.root / "art1.png"
        art2 = self.root / "sub" / "art1.png"
        art2.parent.mkdir(parents=True, exist_ok=True)
        art1.write_bytes(make_valid_png(1, 1))
        art2.write_bytes(make_valid_png(2, 2))

        manifest_data = dict(self.manifest_data)
        manifest_data["cases"] = [
            {
                "caseId": "C01",
                "criterionId": "AC40-1",
                "suitePath": "test/l10n/test.dart",
                "qualifiedTestName": "Test Suite [C01] Language",
                "layer": "software-root",
                "required": True,
                "artifactRoles": ["art1.png"],
            },
            {
                "caseId": "C09.1",
                "criterionId": "AC40-1",
                "suitePath": "test/l10n/test_a11y.dart",
                "qualifiedTestName": "Test Suite [C09.1] A11y",
                "layer": "software-root",
                "required": True,
                "artifactRoles": ["sub/art1.png"],
            },
        ]
        m_file = self.root / "manifest_art_conflict.json"
        m_file.write_text(json.dumps(manifest_data), encoding="utf-8")
        report = self._generate_report_jsonl()

        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(
                m_file,
                report,
                runner_exit=0,
                bundle_dir=bundle_dir,
                repo_root=self.root,
            )
        self.assertIn("conflicting artifact", str(ctx.exception).lower())

    def test_bundle_dir_failure_recording(self):
        """G-ARCHIVE: When verification fails, bundle_dir records attempt.json with status FAIL."""
        bundle_dir = self.root / "fail_bundle"
        bundle_dir.mkdir(parents=True, exist_ok=True)
        report = self._generate_report_jsonl(c01_result="failure")

        with self.assertRaises(L10nRequiredError):
            verify_l10n_required(
                self.manifest_path,
                report,
                runner_exit=0,
                bundle_dir=bundle_dir,
                repo_root=self.root,
            )
        attempt_file = bundle_dir / "attempt.json"
        self.assertTrue(attempt_file.exists())
        data = json.loads(attempt_file.read_text(encoding="utf-8"))
        self.assertEqual(data["status"], "FAIL")

    def test_full_archive_bundle_generation(self):
        """G-ARCHIVE: Verified run creates complete 11-file bundle archive and matches hashes."""
        bundle_dir = self.root / "ci-artifacts/l10n-required/test-run"
        receipt_path = self.root / "ci-artifacts/l10n-required/receipt.json"
        report = self._generate_report_jsonl()

        receipt = verify_l10n_required(
            self.manifest_path,
            report,
            runner_exit=0,
            evidence_path=receipt_path,
            bundle_dir=bundle_dir,
            repo_root=self.root,
        )

        self.assertEqual(receipt["status"], "ACCEPTED")
        self.assertEqual(receipt["executionStatus"], "EXECUTION_PASS")
        self.assertEqual(receipt["reviewStatus"], "PENDING_REVIEW")
        self.assertEqual(receipt["provenanceLevel"], "C1A_R2B_PRODUCTION_PROOF_ACCEPTED")

        # Verify all bundle files exist
        required_bundle_files = [
            "run-context.json",
            "manifest.json",
            "command.json",
            "child.exit",
            "child.stdout.jsonl",
            "child.stderr.txt",
            "case-observations.json",
            "artifacts/test_artifact.png",
            "artifacts.sha256",
            "attempt.json",
            "verification.json",
        ]
        for f in required_bundle_files:
            file_path = bundle_dir / f
            self.assertTrue(file_path.exists(), f"Missing required bundle file: {f}")

        # Check sha256 in artifacts.sha256
        sha_lines = (bundle_dir / "artifacts.sha256").read_text(encoding="utf-8").strip().splitlines()
        self.assertEqual(len(sha_lines), 1)
        self.assertIn("test_artifact.png", sha_lines[0])

    def test_png_duplicate_ihdr_rejected(self):
        """G-PNG: Duplicate IHDR chunk is rejected."""
        from tool.ci.run_l10n_required import validate_and_decode_png
        def chunk(ctype: bytes, data: bytes) -> bytes:
            return (
                struct.pack(">I", len(data))
                + ctype
                + data
                + struct.pack(">I", zlib.crc32(ctype + data) & 0xFFFFFFFF)
            )
        magic = b"\x89PNG\r\n\x1a\n"
        ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 6, 0, 0, 0))
        idat = chunk(b"IDAT", zlib.compress(b"\x00\x00\x00\x00\xff"))
        iend = chunk(b"IEND", b"")
        duplicate_ihdr_png = magic + ihdr + ihdr + idat + iend

        with self.assertRaises(L10nRequiredError) as ctx:
            validate_and_decode_png(duplicate_ihdr_png)
        self.assertIn("duplicate ihdr", str(ctx.exception).lower())

    def test_png_indexed_missing_plte_rejected(self):
        """G-PNG: Indexed color (color_type=3) without PLTE is rejected."""
        from tool.ci.run_l10n_required import validate_and_decode_png
        def chunk(ctype: bytes, data: bytes) -> bytes:
            return (
                struct.pack(">I", len(data))
                + ctype
                + data
                + struct.pack(">I", zlib.crc32(ctype + data) & 0xFFFFFFFF)
            )
        magic = b"\x89PNG\r\n\x1a\n"
        ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 3, 0, 0, 0))
        idat = chunk(b"IDAT", zlib.compress(b"\x00\x00"))
        iend = chunk(b"IEND", b"")
        indexed_no_plte = magic + ihdr + idat + iend

        with self.assertRaises(L10nRequiredError) as ctx:
            validate_and_decode_png(indexed_no_plte)
        self.assertIn("plte", str(ctx.exception).lower())

    def test_png_grayscale_with_plte_rejected(self):
        """G-PNG: Grayscale PNG (color_type=0) with PLTE is rejected."""
        from tool.ci.run_l10n_required import validate_and_decode_png
        def chunk(ctype: bytes, data: bytes) -> bytes:
            return (
                struct.pack(">I", len(data))
                + ctype
                + data
                + struct.pack(">I", zlib.crc32(ctype + data) & 0xFFFFFFFF)
            )
        magic = b"\x89PNG\r\n\x1a\n"
        ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 0, 0, 0, 0))
        plte = chunk(b"PLTE", b"\x00\x00\x00")
        idat = chunk(b"IDAT", zlib.compress(b"\x00\x00"))
        iend = chunk(b"IEND", b"")
        gray_plte = magic + ihdr + plte + idat + iend

        with self.assertRaises(L10nRequiredError) as ctx:
            validate_and_decode_png(gray_plte)
        self.assertIn("grayscale", str(ctx.exception).lower())

    def test_png_interlace_adam7_rejected(self):
        """G-PNG: Interlace method 1 (Adam7) is rejected as unsupported for screenshot artifacts."""
        from tool.ci.run_l10n_required import validate_and_decode_png
        def chunk(ctype: bytes, data: bytes) -> bytes:
            return (
                struct.pack(">I", len(data))
                + ctype
                + data
                + struct.pack(">I", zlib.crc32(ctype + data) & 0xFFFFFFFF)
            )
        magic = b"\x89PNG\r\n\x1a\n"
        ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 6, 0, 0, 1))
        idat = chunk(b"IDAT", zlib.compress(b"\x00\x00\x00\x00\xff"))
        iend = chunk(b"IEND", b"")
        adam7 = magic + ihdr + idat + iend

        with self.assertRaises(L10nRequiredError) as ctx:
            validate_and_decode_png(adam7)
        self.assertIn("unsupported png interlace method", str(ctx.exception).lower())

    def test_png_expected_dimensions_mismatch(self):
        """G-PNG: Dimension mismatch against expected dimensions is rejected."""
        from tool.ci.run_l10n_required import validate_and_decode_png
        png_1x1 = make_valid_png(1, 1)
        with self.assertRaises(L10nRequiredError) as ctx:
            validate_and_decode_png(png_1x1, expected_width=320, expected_height=640)
        self.assertIn("does not match expected width 320", str(ctx.exception))

    def test_suite_path_escapes_repo_root_rejected(self):
        """G-SUITE: Suite path escaping repository root containment is rejected."""
        from tool.ci.run_l10n_required import normalize_suite_path
        with self.assertRaises(L10nRequiredError) as ctx:
            normalize_suite_path("../../outside.dart", self.root)
        self.assertIn("escapes repository root containment", str(ctx.exception))

    def test_software_root_profile_requires_known_source_and_sdk(self):
        """G-RUN: software-root profile strictly fails closed if sourceSha or sdk is unknown."""
        manifest_data = dict(self.manifest_data)
        manifest_data["profile"] = "software-root"
        m_file = self.root / "manifest_software_root.json"
        m_file.write_text(json.dumps(manifest_data), encoding="utf-8")
        report = self._generate_report_jsonl()

        # Unknown source_sha
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(
                m_file,
                report,
                runner_exit=0,
                repo_root=self.root,
                source_sha="unknown",
                tree_sha="abc123",
                sdk_info="Flutter 3.47.0",
            )
        self.assertIn("known git sourcesha", str(ctx.exception).lower())

        # Unknown sdk_info
        with self.assertRaises(L10nRequiredError) as ctx:
            verify_l10n_required(
                m_file,
                report,
                runner_exit=0,
                repo_root=self.root,
                source_sha="def456",
                tree_sha="abc123",
                sdk_info="flutter-unknown",
            )
        self.assertIn("known sdk info", str(ctx.exception).lower())

    def test_png_truncated_zlib_stream_rejected(self):
        """G-PNG: Truncated PNG IDAT zlib stream is rejected."""
        from tool.ci.run_l10n_required import validate_and_decode_png
        def chunk(ctype: bytes, data: bytes) -> bytes:
            return (
                struct.pack(">I", len(data))
                + ctype
                + data
                + struct.pack(">I", zlib.crc32(ctype + data) & 0xFFFFFFFF)
            )
        magic = b"\x89PNG\r\n\x1a\n"
        ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 6, 0, 0, 0))
        full_zlib = zlib.compress(b"\x00\x00\x00\x00\xff")
        truncated_zlib = full_zlib[:-3]
        idat = chunk(b"IDAT", truncated_zlib)
        iend = chunk(b"IEND", b"")
        truncated_png = magic + ihdr + idat + iend

        with self.assertRaises(L10nRequiredError) as ctx:
            validate_and_decode_png(truncated_png)
        self.assertIn("truncated png idat zlib stream", str(ctx.exception).lower())

    def test_png_extraneous_zlib_data_rejected(self):
        """G-PNG: Extraneous data inside PNG IDAT zlib stream after end-of-stream is rejected."""
        from tool.ci.run_l10n_required import validate_and_decode_png
        def chunk(ctype: bytes, data: bytes) -> bytes:
            return (
                struct.pack(">I", len(data))
                + ctype
                + data
                + struct.pack(">I", zlib.crc32(ctype + data) & 0xFFFFFFFF)
            )
        magic = b"\x89PNG\r\n\x1a\n"
        ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 6, 0, 0, 0))
        full_zlib = zlib.compress(b"\x00\x00\x00\x00\xff")
        idat = chunk(b"IDAT", full_zlib + b"EXTRA_BYTES")
        iend = chunk(b"IEND", b"")
        extraneous_png = magic + ihdr + idat + iend

        with self.assertRaises(L10nRequiredError) as ctx:
            validate_and_decode_png(extraneous_png)
        self.assertIn("extraneous data inside png idat zlib stream", str(ctx.exception).lower())

    def test_failure_archives_child_stdout_and_exit(self):
        """G-FAILURE: Verifier failure creates failure archive with child.exit, stdout, and stderr."""
        bundle_dir = self.root / "ci-artifacts/l10n-required/failure-run"
        report = self._generate_report_jsonl(c01_result="failure")
        with self.assertRaises(L10nRequiredError):
            verify_l10n_required(
                self.manifest_path,
                report,
                runner_exit=42,
                bundle_dir=bundle_dir,
                child_stderr="synthetic stderr content",
                repo_root=self.root,
            )
        self.assertTrue((bundle_dir / "child.exit").exists())
        self.assertEqual((bundle_dir / "child.exit").read_text(encoding="utf-8").strip(), "42")
        self.assertTrue((bundle_dir / "child.stderr.txt").exists())
        self.assertIn("synthetic stderr content", (bundle_dir / "child.stderr.txt").read_text(encoding="utf-8"))
        self.assertTrue((bundle_dir / "child.stdout.jsonl").exists())
        self.assertTrue((bundle_dir / "attempt.json").exists())
        attempt_data = json.loads((bundle_dir / "attempt.json").read_text(encoding="utf-8"))
        self.assertEqual(attempt_data["status"], "FAIL")

    def test_offline_report_preserves_run_context(self):
        """G-RUN: Offline report verification preserves provenance from adjacent run-context.json."""
        report = self._generate_report_jsonl()
        run_context_file = report.parent / "run-context.json"
        run_context_file.write_text(
            json.dumps({
                "runId": "run_orig_9999",
                "sourceSha": "abcdef0123456789abcdef0123456789abcdef01",
                "treeSha": "1234567890abcdef1234567890abcdef12345678",
                "sdkInfo": "Flutter 3.47.0 • channel stable",
            }),
            encoding="utf-8",
        )
        receipt_file = self.root / "receipt_from_offline.json"
        ret = runner_main([
            "--manifest", str(self.manifest_path),
            "--report", str(report),
            "--runner-exit", "0",
            "--evidence", str(receipt_file),
            "--expected-profile", "test-profile",
            "--repo-root", str(self.root),
        ])
        self.assertEqual(ret, 0)
        self.assertTrue(receipt_file.exists())
        receipt_data = json.loads(receipt_file.read_text(encoding="utf-8"))
        self.assertEqual(receipt_data["runId"], "run_orig_9999")
        self.assertEqual(receipt_data["sourceSha"], "abcdef0123456789abcdef0123456789abcdef01")
        self.assertEqual(receipt_data["treeSha"], "1234567890abcdef1234567890abcdef12345678")
        self.assertEqual(receipt_data["sdk"], "Flutter 3.47.0 • channel stable")
        self.assertEqual(receipt_data["sdkInfo"], "Flutter 3.47.0 • channel stable")

    def test_offline_report_rejects_conflicting_cli_identity_and_tampered_hash(self):
        """G-RUN: offline report rejects conflicting identity and tampered report hash."""
        report = self._generate_report_jsonl()
        context_file = report.parent / "run-context.json"
        context_file.write_text(
            json.dumps({
                "runId": "run_tamper_1",
                "sourceSha": "1111111111111111111111111111111111111111",
                "treeSha": "2222222222222222222222222222222222222222",
                "sdk": "Flutter 3.47.0 • channel stable",
                "reportHash": "badbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadb",
            }),
            encoding="utf-8",
        )
        receipt_file = self.root / "receipt_tamper.json"
        # Hash mismatch should fail
        ret = runner_main([
            "--manifest", str(self.manifest_path),
            "--report", str(report),
            "--evidence", str(receipt_file),
            "--expected-profile", "test-profile",
            "--repo-root", str(self.root),
        ])
        self.assertNotEqual(ret, 0)

        # Fix report hash, test conflicting CLI sourceSha
        import hashlib
        real_hash = hashlib.sha256(report.read_bytes()).hexdigest()
        context_file.write_text(
            json.dumps({
                "runId": "run_tamper_1",
                "sourceSha": "1111111111111111111111111111111111111111",
                "treeSha": "2222222222222222222222222222222222222222",
                "sdk": "Flutter 3.47.0 • channel stable",
                "reportHash": real_hash,
            }),
            encoding="utf-8",
        )
        ret_conflict = runner_main([
            "--manifest", str(self.manifest_path),
            "--report", str(report),
            "--source-sha", "9999999999999999999999999999999999999999",
            "--evidence", str(receipt_file),
            "--expected-profile", "test-profile",
            "--repo-root", str(self.root),
        ])
        self.assertNotEqual(ret_conflict, 0)

    def test_offline_report_reads_non_zero_child_exit_from_context(self):
        """G-RUN: offline report consumes non-zero childExit from context without silent fallback."""
        report = self._generate_report_jsonl()
        context_file = report.parent / "run-context.json"
        context_file.write_text(
            json.dumps({
                "runId": "run_exit1",
                "sourceSha": "1111111111111111111111111111111111111111",
                "treeSha": "2222222222222222222222222222222222222222",
                "sdk": "Flutter 3.47.0 • channel stable",
                "childExit": 1,
            }),
            encoding="utf-8",
        )
        receipt_file = self.root / "receipt_exit1.json"
        ret = runner_main([
            "--manifest", str(self.manifest_path),
            "--report", str(report),
            "--evidence", str(receipt_file),
            "--expected-profile", "test-profile",
            "--repo-root", str(self.root),
        ])
        self.assertNotEqual(ret, 0)


if __name__ == "__main__":
    unittest.main()

