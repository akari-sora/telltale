#!/usr/bin/env python3
"""Tests for tool/ci/run_ws10_s1_required.py runner and exit code contracts."""

import json
from pathlib import Path
import tempfile
import unittest

from tool.ci.run_ws10_s1_required import (
    REPO_ROOT,
    REQUIRED_CASE_MARKERS,
    normalize_suite_path,
    parse_and_validate_reporter,
    run,
)


class TestRunWs10S1Required(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.output_dir = Path(self.temp_dir.name) / "output"
        self.output_dir.mkdir(parents=True)

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_required_markers_count(self):
        self.assertEqual(len(REQUIRED_CASE_MARKERS), 12)
        for i in range(1, 13):
            self.assertIn(f"L{i:02d}", REQUIRED_CASE_MARKERS)

    def test_parse_valid_report_with_all_markers(self):
        report_file = self.output_dir / "valid_report.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/diagnostics/can/can_endpoint_test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 2, "path": "test/diagnostics/can/can_io_core_test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 3, "path": "test/diagnostics/can/can_io_boundary_test.dart"}}),
        ]
        suite_by_marker = {
            "L01": 1,
            "L02": 2, "L03": 2, "L04": 2, "L06": 2, "L07": 2, "L08": 2, "L09": 2, "L10": 2, "L11": 2,
            "L05": 3, "L12": 3,
        }
        for i, marker in enumerate(REQUIRED_CASE_MARKERS, start=1):
            sid = suite_by_marker[marker]
            lines.append(json.dumps({
                "type": "testStart",
                "test": {"id": i, "name": f"Suite {marker}: test something", "suiteID": sid}
            }))
            lines.append(json.dumps({
                "type": "testDone",
                "testID": i,
                "result": "success",
                "hidden": False,
                "skipped": False,
            }))
        lines.append(json.dumps({"type": "done", "success": True}))
        report_file.write_text("\n".join(lines) + "\n")

        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertEqual(passed_count, 12)
        self.assertEqual(len(markers), 12)
        self.assertEqual(failures, [])
        self.assertEqual(skipped, 0)

    def test_parse_report_with_failure(self):
        report_file = self.output_dir / "failed_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test"}}),
            json.dumps({"type": "error", "testID": 1, "error": "Expected true but was false"}),
            json.dumps({"type": "testDone", "testID": 1, "result": "failure", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": False}),
        ]
        report_file.write_text("\n".join(lines) + "\n")

        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertEqual(passed_count, 0)
        self.assertEqual(len(failures), 2)
        self.assertTrue(any("Expected true" in f for f in failures))

    def test_parse_report_with_skip(self):
        report_file = self.output_dir / "skipped_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test"}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": True}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")

        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertEqual(passed_count, 0)
        self.assertEqual(len(failures), 1)
        self.assertEqual(skipped, 1)
        self.assertIn("SKIPPED", failures[0])

    def test_malformed_json_raises_value_error(self):
        report_file = self.output_dir / "corrupted_report.jsonl"
        report_file.write_text('{"type": "testStart"}\n{invalid_json}\n')
        with self.assertRaises(ValueError):
            parse_and_validate_reporter(report_file)

    def test_pub_resolver_preamble_still_parses_success(self):
        """CI flutter stdout may lead with pub resolver prose before JSON events."""
        report_file = self.output_dir / "preamble_report.jsonl"
        lines = [
            "Resolving dependencies...",
            "Downloading packages...",
            "  analyzer 13.3.0 (14.4.0 available)",
            "Got dependencies!",
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/diagnostics/can/can_endpoint_test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 2, "path": "test/diagnostics/can/can_io_core_test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 3, "path": "test/diagnostics/can/can_io_boundary_test.dart"}}),
        ]
        suite_by_marker = {
            "L01": 1,
            "L02": 2, "L03": 2, "L04": 2, "L06": 2, "L07": 2, "L08": 2, "L09": 2, "L10": 2, "L11": 2,
            "L05": 3, "L12": 3,
        }
        for i, marker in enumerate(REQUIRED_CASE_MARKERS, start=1):
            sid = suite_by_marker[marker]
            lines.append(json.dumps({
                "type": "testStart",
                "test": {"id": i, "name": f"Suite {marker}: test something", "suiteID": sid}
            }))
            lines.append(json.dumps({
                "type": "testDone",
                "testID": i,
                "result": "success",
                "hidden": False,
                "skipped": False,
            }))
        lines.append(json.dumps({"type": "done", "success": True}))
        report_file.write_text("\n".join(lines) + "\n")

        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertEqual(passed_count, 12)
        self.assertEqual(len(markers), 12)
        self.assertEqual(failures, [])
        self.assertEqual(skipped, 0)

    def test_missing_done_event_reports_failure(self):
        report_file = self.output_dir / "no_done_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test"}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertEqual(len(failures), 1)
        self.assertIn("missing 'done' event", failures[0])

    def test_uncompleted_test_reports_failure(self):
        report_file = self.output_dir / "uncompleted_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test"}}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertEqual(len(failures), 1)
        self.assertIn("INCOMPLETE (missing testDone)", failures[0])

    def test_single_test_with_all_markers_only_satisfies_one_marker(self):
        """Pattern 1: A single test containing all markers L01..L12 cannot satisfy all requirements."""
        report_file = self.output_dir / "single_test_report.jsonl"
        all_markers_name = "Suite " + " ".join(REQUIRED_CASE_MARKERS) + ": omnibus test"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/diagnostics/can/can_endpoint_test.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": all_markers_name, "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertEqual(passed_count, 1)
        # Exactly 1 marker is satisfied, leaving 11 missing
        self.assertEqual(len(markers), 1)
        missing = set(REQUIRED_CASE_MARKERS) - markers
        self.assertEqual(len(missing), 11)

    def test_done_true_then_done_false_reports_failure(self):
        """Pattern 2: A done=true followed by done=false is treated as a failed suite."""
        report_file = self.output_dir / "done_flip_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test"}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
            json.dumps({"type": "done", "success": False}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertTrue(any("success=false" in f or "after terminal 'done'" in f for f in failures))

    def test_duplicate_test_id_raises_protocol_violation(self):
        """Pattern 3: Reused test ID raises a protocol violation error."""
        report_file = self.output_dir / "duplicate_id_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test 1"}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L02: test 2 reused id"}}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        with self.assertRaises(ValueError) as ctx:
            parse_and_validate_reporter(report_file)
        self.assertIn("duplicate or reused test ID 1", str(ctx.exception))

    def test_error_after_test_done_demotes_to_failure(self):
        """Pattern 4: An error event arriving after testDone success demotes the test to failure."""
        report_file = self.output_dir / "late_error_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test"}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "error", "testID": 1, "error": "Asynchronous unhandled error"}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertEqual(passed_count, 0)
        self.assertIn("L01", REQUIRED_CASE_MARKERS)
        self.assertNotIn("L01", markers)
        self.assertTrue(any("Asynchronous unhandled error" in f for f in failures))

    def test_hidden_loading_failure_reports_failure(self):
        """Pattern 5: A hidden loading test that fails is caught and reported as failure."""
        report_file = self.output_dir / "hidden_failure_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "loading test/some_test.dart"}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "failure", "hidden": True, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertEqual(passed_count, 0)
        self.assertTrue(any("loading test/some_test.dart" in f for f in failures))

    def test_missing_fixture_returns_exit_2(self):
        fake_repo = Path(self.temp_dir.name) / "empty_repo"
        fake_repo.mkdir()
        rc = run(fake_repo, self.output_dir / "run_out", flutter="flutter", timeout=10)
        self.assertEqual(rc, 2)

    def test_corrupted_non_json_mid_stream_raises_value_error(self):
        """Probe 1: Corrupted non-JSON line appearing mid-stream must raise ValueError."""
        report_file = self.output_dir / "mid_stream_corrupt_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test"}}),
            "CORRUPTED_NON_JSON_LINE_AFTER_START",
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        with self.assertRaises(ValueError) as ctx:
            parse_and_validate_reporter(report_file)
        self.assertIn("corrupted non-JSON line after stream started", str(ctx.exception))

    def test_corrupted_non_json_tail_after_done_raises_value_error(self):
        """Probe 2: Corrupted non-JSON tail appearing after done event must raise ValueError."""
        report_file = self.output_dir / "corrupted_tail_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test"}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
            "NON_JSON_CORRUPTED_TAIL_AFTER_DONE",
        ]
        report_file.write_text("\n".join(lines) + "\n")
        with self.assertRaises(ValueError) as ctx:
            parse_and_validate_reporter(report_file)
        self.assertIn("corrupted non-JSON line after stream started", str(ctx.exception))

    def test_foreign_suite_markers_are_rejected(self):
        """Probe 3: 12 tests with L01..L12 from a foreign suite cannot satisfy required markers."""
        report_file = self.output_dir / "foreign_suite_report.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 0, "path": "test/other/foreign_suite_test.dart"}}),
        ]
        for i, marker in enumerate(REQUIRED_CASE_MARKERS, start=1):
            lines.append(json.dumps({
                "type": "testStart",
                "test": {"id": i, "name": f"ForeignSuite {marker}: test something", "suiteID": 0}
            }))
            lines.append(json.dumps({
                "type": "testDone",
                "testID": i,
                "result": "success",
                "hidden": False,
                "skipped": False,
            }))
        lines.append(json.dumps({"type": "done", "success": True}))
        report_file.write_text("\n".join(lines) + "\n")

        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertEqual(passed_count, 12)
        # Foreign suite tests must be rejected for required markers
        self.assertEqual(len(markers), 0)

    def test_duplicate_test_done_raises_value_error(self):
        """Probe 4: Same test ID receiving duplicate testDone must raise ValueError."""
        report_file = self.output_dir / "duplicate_done_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test"}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        with self.assertRaises(ValueError) as ctx:
            parse_and_validate_reporter(report_file)
        self.assertIn("duplicate testDone for test ID 1", str(ctx.exception))

    def test_test_done_before_test_start_raises_value_error(self):
        """Probe 5: testDone received for unstarted test ID must raise ValueError."""
        report_file = self.output_dir / "done_before_start_report.jsonl"
        lines = [
            json.dumps({"type": "testDone", "testID": 99, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        with self.assertRaises(ValueError) as ctx:
            parse_and_validate_reporter(report_file)
        self.assertIn("testDone received for unstarted test ID 99", str(ctx.exception))

    def test_probe6_legal_json_event_after_done_reports_protocol_violation(self):
        """Probe 6: Any event arriving after terminal done reports protocol violation failure."""
        report_file = self.output_dir / "event_after_done_report.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/diagnostics/can/can_endpoint_test.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
            json.dumps({"type": "testStart", "test": {"id": 2, "name": "Suite L01: trailing test after done", "suiteID": 1}}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertTrue(any("after terminal 'done'" in f for f in failures))

    def test_probe7_done_false_then_done_true_remains_failed(self):
        """Probe 7: Terminal done success=false cannot be overwritten by subsequent done success=true."""
        report_file = self.output_dir / "done_false_overwrite_report.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/diagnostics/can/can_endpoint_test.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertTrue(any("success=false" in f for f in failures))
        self.assertTrue(any("after terminal 'done'" in f for f in failures))

    def test_probe8_missing_suite_metadata_strictly_rejected(self):
        """Probe 8: Tests without suite metadata cannot satisfy required markers (fail-closed)."""
        report_file = self.output_dir / "missing_suite_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test without suite"}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertEqual(passed_count, 1)
        self.assertNotIn("L01", markers)

    def test_probe9_foreign_path_with_same_basename_rejected(self):
        """Probe 9: Same file basename in another directory cannot satisfy required suite."""
        report_file = self.output_dir / "foreign_basename_report.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/other/can_endpoint_test.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test in other dir", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertNotIn("L01", markers)

    def test_probe10_unrelated_extension_rejected(self):
        """Probe 10: Suite path containing .unrelated suffix is rejected."""
        report_file = self.output_dir / "unrelated_ext_report.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/diagnostics/can/can_endpoint_test.dart.unrelated"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test in .unrelated", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertNotIn("L01", markers)

    def test_probe11_suite_id_redefinition_raises_value_error(self):
        """Probe 11: Reused suite ID with different path raises protocol violation."""
        report_file = self.output_dir / "redefined_suite_report.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/diagnostics/can/can_endpoint_test.dart"}}),
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/diagnostics/can/drifted_path_test.dart"}}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        with self.assertRaises(ValueError) as ctx:
            parse_and_validate_reporter(report_file)
        self.assertIn("suite ID 1 redefined with path", str(ctx.exception))

    def test_probe12_foreign_repo_root_rejected(self):
        """Probe 12: Absolute path belonging to a foreign checkout cannot satisfy required suite."""
        report_file = self.output_dir / "foreign_repo_report.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "/foreign_repo/test/diagnostics/can/can_endpoint_test.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test in foreign repo", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertNotIn("L01", markers)

    def test_probe13_other_checkout_relative_prefix_rejected(self):
        """Probe 13: Relative path with foreign directory prefix cannot satisfy required suite."""
        report_file = self.output_dir / "other_checkout_report.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "other_checkout/test/diagnostics/can/can_endpoint_test.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test in other checkout", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertNotIn("L01", markers)

    def test_probe14_untrusted_uri_authority_rejected(self):
        """Probe 14: file:// URI with untrusted remote authority is strictly rejected."""
        report_file = self.output_dir / "untrusted_uri_report.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "file://untrusted.example.invalid/test/diagnostics/can/can_endpoint_test.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test from remote authority", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertNotIn("L01", markers)

    def test_probe15_contest_substring_rejected(self):
        """Probe 15: Directory containing 'test/' as substring (contest/) cannot satisfy required suite."""
        report_file = self.output_dir / "contest_report.jsonl"
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "contest/diagnostics/can/can_endpoint_test.dart"}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test in contest", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertNotIn("L01", markers)

    def test_probe16_missing_suite_id_with_valid_url_rejected(self):
        """Probe 16: Test without suiteID cannot bypass via test.url fallback."""
        report_file = self.output_dir / "missing_suite_id_url_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test without suiteID", "url": "test/diagnostics/can/can_endpoint_test.dart"}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertNotIn("L01", markers)

    def test_probe17_undeclared_suite_id_with_valid_url_rejected(self):
        """Probe 17: Test referencing unmapped suiteID cannot bypass via test.url fallback."""
        report_file = self.output_dir / "unmapped_suite_url_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test with unmapped suiteID", "suiteID": 999, "url": "test/diagnostics/can/can_endpoint_test.dart"}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertNotIn("L01", markers)

    def test_probe18_suite_declared_after_test_done_rejected(self):
        """Probe 18: Suite declared after test done cannot retroactively associate suite identity."""
        report_file = self.output_dir / "retroactive_suite_report.jsonl"
        lines = [
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test unassociated", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            # Suite event arrives late, after test is already done
            json.dumps({"type": "suite", "suite": {"id": 1, "path": "test/diagnostics/can/can_endpoint_test.dart"}}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertNotIn("L01", markers)

    def test_probe19_positive_control_absolute_repo_path_accepted(self):
        """Probe 19: Positive control - absolute path inside repository root is accepted."""
        report_file = self.output_dir / "abs_repo_path_report.jsonl"
        abs_suite_path = (REPO_ROOT / "test/diagnostics/can/can_endpoint_test.dart").as_posix()
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": abs_suite_path}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test with absolute path", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertIn("L01", markers)

    def test_probe20_positive_control_local_file_uri_accepted(self):
        """Probe 20: Positive control - local file:// URI inside repository is accepted."""
        report_file = self.output_dir / "local_file_uri_report.jsonl"
        file_uri = Path(REPO_ROOT / "test/diagnostics/can/can_endpoint_test.dart").as_uri()
        lines = [
            json.dumps({"type": "suite", "suite": {"id": 1, "path": file_uri}}),
            json.dumps({"type": "testStart", "test": {"id": 1, "name": "Suite L01: test with file uri", "suiteID": 1}}),
            json.dumps({"type": "testDone", "testID": 1, "result": "success", "hidden": False, "skipped": False}),
            json.dumps({"type": "done", "success": True}),
        ]
        report_file.write_text("\n".join(lines) + "\n")
        passed_count, markers, failures, skipped = parse_and_validate_reporter(report_file)
        self.assertIn("L01", markers)


if __name__ == "__main__":
    unittest.main()

