#!/usr/bin/env python3
"""Run and verify required WS10-S1 L0 CAN contracts and test suites.

Enforces machine-readable verification of required L0 test cases (L01..L12)
with fail-closed exit codes:
  0: Required L0 cases actually executed and passed (0 required skip/missing)
  1: Assertion or product contract failure
  2: Fixture/source/toolchain missing, required skip/missing, or invalid invocation
  3: Internal harness, reporting, or cleanup error
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time

REQUIRED_CASE_MARKERS = [
    "L01",
    "L02",
    "L03",
    "L04",
    "L05",
    "L06",
    "L07",
    "L08",
    "L09",
    "L10",
    "L11",
    "L12",
]


def checked_run(command: list[str], cwd: Path, stdout: Path, stderr: Path,
                timeout: float) -> int:
    with stdout.open('wb') as out, stderr.open('wb') as err:
        process = subprocess.Popen(command, cwd=cwd, stdout=out, stderr=err,
                                   start_new_session=True)
        try:
            return process.wait(timeout=timeout)
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait(timeout=5)


def parse_and_validate_reporter(report_path: Path) -> tuple[int, set[str], list[str], int]:
    """Parses Flutter test --reporter json output.

    Returns:
        (total_passed, passed_markers, failure_descriptions, skipped_count)
    """
    if not report_path.exists() or report_path.stat().st_size == 0:
        raise FileNotFoundError(f"Missing or empty test report: {report_path}")

    tests_by_id: dict[int, dict] = {}
    seen_start_test_ids: set[int] = set()
    passed_tests: set[int] = set()
    failed_tests: set[int] = set()
    skipped_tests: set[int] = set()
    hidden_tests: set[int] = set()
    errors_by_test: dict[int, list[str]] = {}
    global_errors: list[str] = []
    seen_done_event = False
    final_done_success = False
    events_after_done = 0

    for line_num, raw_line in enumerate(report_path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
        line = raw_line.strip()
        if not line:
            continue
        # `flutter test --reporter json` can print pub resolver prose
        # ("Resolving dependencies...", package lines) before the first
        # event. Ignore non-objects. A line that starts with '{' is
        # claiming to be an event and must parse.
        if not line.startswith("{"):
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError as exc:
            raise ValueError(f"Malformed JSON on line {line_num} of test report: {exc}")

        if not isinstance(event, dict):
            raise ValueError(f"Invalid JSON event on line {line_num}: expected JSON object")

        if seen_done_event:
            events_after_done += 1

        event_type = event.get("type")
        if event_type == "testStart":
            t = event.get("test", {})
            tid = t.get("id")
            if tid is not None:
                if tid in seen_start_test_ids:
                    raise ValueError(f"Protocol violation: duplicate or reused test ID {tid} on line {line_num}")
                seen_start_test_ids.add(tid)
                tests_by_id[tid] = t
        elif event_type == "error":
            tid = event.get("testID")
            err_msg = event.get("error", "")
            if tid is not None:
                errors_by_test.setdefault(tid, []).append(err_msg)
                failed_tests.add(tid)
                passed_tests.discard(tid)
            else:
                global_errors.append(err_msg)
        elif event_type == "testDone":
            tid = event.get("testID")
            result = event.get("result")
            hidden = event.get("hidden", False)
            skipped = event.get("skipped", False)

            if skipped:
                skipped_tests.add(tid)
                passed_tests.discard(tid)
            elif result != "success" or tid in failed_tests or errors_by_test.get(tid):
                failed_tests.add(tid)
                passed_tests.discard(tid)
            elif hidden:
                hidden_tests.add(tid)
            else:
                passed_tests.add(tid)
        elif event_type == "done":
            seen_done_event = True
            final_done_success = (event.get("success") is True)

    # Check for uncompleted tests (testStart without testDone)
    uncompleted = set(tests_by_id.keys()) - (passed_tests | failed_tests | skipped_tests | hidden_tests)
    failure_messages: list[str] = []
    for tid in sorted(uncompleted):
        t = tests_by_id.get(tid, {})
        tname = t.get("name", f"test_{tid}")
        failure_messages.append(f"INCOMPLETE (missing testDone): {tname}")

    if not seen_done_event:
        failure_messages.append("Incomplete test suite: missing 'done' event")
    elif not final_done_success:
        failure_messages.append("Test suite failed: final 'done' event reported success=false")
    elif events_after_done > 0:
        failure_messages.append(f"Protocol violation: {events_after_done} events received after terminal 'done' event")

    for g_err in global_errors:
        failure_messages.append(f"Global test error: {g_err}")

    for tid in sorted(failed_tests):
        tname = tests_by_id.get(tid, {}).get("name", f"test_{tid}")
        errs = errors_by_test.get(tid, ["Failed with assertion/error"])
        failure_messages.append(f"{tname}: {'; '.join(errs)}")

    for tid in sorted(skipped_tests):
        tname = tests_by_id.get(tid, {}).get("name", f"test_{tid}")
        failure_messages.append(f"SKIPPED (prohibited): {tname}")

    # Check coverage of required markers with 1-to-1 distinct test case requirement
    marker_to_test: dict[str, int] = {}
    for tid in sorted(passed_tests):
        tname = tests_by_id.get(tid, {}).get("name", "")
        for marker in REQUIRED_CASE_MARKERS:
            if marker not in marker_to_test and re.search(rf"\b{marker}\b", tname):
                marker_to_test[marker] = tid
                break

    passed_markers = set(marker_to_test.keys())
    return len(passed_tests), passed_markers, failure_messages, len(skipped_tests)


def run(repo: Path, output: Path, flutter: str, timeout: int) -> int:
    repo = repo.resolve()
    output = output.resolve()
    output.mkdir(parents=True, exist_ok=True)

    fixture = repo / "test/fixtures/ws10_s1/literal_pdu_cases.json"
    if not fixture.exists():
        sys.stderr.write(f"Missing required fixture: {fixture}\n")
        return 2

    fixture_sha = hashlib.sha256(fixture.read_bytes()).hexdigest()

    result: dict = {
        "schema_version": 1,
        "milestone": "WS10-S1",
        "evidence_level": "virtual_l0_core",
        "fixture_sha256": fixture_sha,
        "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "ok": False,
    }

    try:
        for key, argument in [("commit", "HEAD"), ("tree", "HEAD^{tree}")]:
            result[key] = subprocess.check_output(
                ["git", "rev-parse", argument], cwd=repo, text=True
            ).strip()

        test_command = [
            flutter,
            "test",
            "test/diagnostics/can/can_endpoint_test.dart",
            "test/diagnostics/can/can_io_core_test.dart",
            "test/diagnostics/can/can_io_boundary_test.dart",
            "test/diagnostics/can/can_io_mutation_test.dart",
            "--reporter",
            "json",
        ]
        result["test_command"] = test_command

        report_file = output / "test_report.jsonl"
        stderr_file = output / "test_stderr.log"

        runner_exit = checked_run(test_command, repo, report_file, stderr_file, timeout)
        result["runner_exit"] = runner_exit

        if runner_exit != 0:
            result["error"] = f"Flutter test runner exited with non-zero code {runner_exit}"
            (output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
            return 1

        total_passed, passed_markers, failures, skipped_count = parse_and_validate_reporter(report_file)
        result["total_passed"] = total_passed
        result["passed_markers"] = sorted(passed_markers)
        result["missing_markers"] = sorted(set(REQUIRED_CASE_MARKERS) - passed_markers)
        result["skipped_count"] = skipped_count

        if skipped_count > 0:
            result["error"] = f"Required tests were skipped ({skipped_count} skipped tests detected)."
            result["failures"] = failures
            (output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
            return 2

        missing = set(REQUIRED_CASE_MARKERS) - passed_markers
        if missing:
            result["error"] = f"Required L0 markers missing from executed tests: {sorted(missing)}"
            if failures:
                result["failures"] = failures
            (output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
            return 2

        if failures:
            result["failures"] = failures
            (output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
            return 1

        result["ok"] = True
        (output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
        return 0

    except (FileNotFoundError, ValueError) as exc:
        result["error"] = str(exc)
        (output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
        return 2
    except Exception as exc:
        result["error"] = f"Unexpected internal harness error: {type(exc).__name__}: {exc}"
        (output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
        return 3


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--flutter", default="flutter")
    parser.add_argument("--timeout", type=int, default=300)
    args = parser.parse_args()

    if not 1 <= args.timeout <= 3600:
        sys.stderr.write("Error: --timeout must be 1..3600 seconds\n")
        return 2

    return run(args.repo, args.output_dir, args.flutter, args.timeout)


if __name__ == "__main__":
    raise SystemExit(main())
