"""Unit & Negative Test Suite for Targeted Mutation Runner (Defect R3 / AA-08 / SAFE-08).

Verifies the 5-dimensional classification, JUnit XML parsing, strict compile/test execution checks,
git apply --check aborts, and try...finally restoration invariants specified in Section 4.2
of the handoff report.
"""

import hashlib
import sys
from pathlib import Path
from typing import List

import pytest

# Ensure repo root is on sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

import tool.ci.run_targeted_mutations as mutation_runner
from tool.ci.run_targeted_mutations import (
    JUnitTestRunSummary,
    MutationResultStatus,
    TestFailureDetail,
    classify_mutation_outcome,
    compute_sha256,
    create_evidence_run_dir,
    generate_patch,
    parse_gradle_junit_reports,
    run_single_mutation,
)


# ==============================================================================
# 1. Negative Test: Compilation Failure -> INFRA_ERROR (Never KILLED)
# ==============================================================================

def test_classify_infra_error_on_compilation_failure():
    """Verify that Gradle compilation failure (syntax/type error) is strictly classified

    as INFRA_ERROR, never as KILLED_BY_TEST.
    """
    exit_code = 1
    build_log = (
        "> Task :car-core:compileDebugKotlin FAILED\n"
        "e: /path/to/CarVehicleMotionResolver.kt: (57, 33): Unresolved reference: unknownSymbol\n"
        "FAILURE: Build failed with an exception."
    )
    junit_summary = JUnitTestRunSummary(
        total_tests=0,
        total_failures=0,
        total_errors=0,
        total_skipped=0,
        failures=[],
    )
    expected_failing_classes = ["CarVehicleMotionResolverTest"]

    status, reason = classify_mutation_outcome(
        exit_code=exit_code,
        build_log=build_log,
        junit_summary=junit_summary,
        expected_failing_classes=expected_failing_classes,
    )

    assert status == MutationResultStatus.INFRA_ERROR
    assert status != MutationResultStatus.KILLED_BY_TEST
    assert "Compilation failed" in reason


# ==============================================================================
# 2. Negative Test: Zero Tests Executed -> INFRA_ERROR
# ==============================================================================

def test_classify_infra_error_on_zero_tests():
    """Verify that if 0 tests were executed, the runner classifies it as INFRA_ERROR

    even if Gradle exited with non-zero or zero.
    """
    exit_code = 1
    build_log = "BUILD SUCCESSFUL in 2s\n0 actionable tasks: 0 executed"
    junit_summary = JUnitTestRunSummary(
        total_tests=0,
        total_failures=0,
        total_errors=0,
        total_skipped=0,
        failures=[],
    )
    expected_failing_classes = ["CarVehicleMotionResolverTest"]

    status, reason = classify_mutation_outcome(
        exit_code=exit_code,
        build_log=build_log,
        junit_summary=junit_summary,
        expected_failing_classes=expected_failing_classes,
    )

    assert status == MutationResultStatus.INFRA_ERROR
    assert status != MutationResultStatus.KILLED_BY_TEST
    assert "Zero tests executed" in reason


# ==============================================================================
# 3. Negative Test: Patch Apply Check Failure -> INVALID_MUTATION (No file write)
# ==============================================================================

def test_classify_invalid_mutation_on_patch_check_failure(tmp_path: Path):
    """Verify that if git apply --check fails, the experiment aborts immediately

    as INVALID_MUTATION and does NOT modify the target file.
    """
    target_rel = "sample.kt"
    target_file = tmp_path / target_rel
    initial_content = "class VehicleMotion {\n    val speed = 0.0\n}\n"
    target_file.write_text(initial_content, encoding="utf-8")
    initial_sha = compute_sha256(initial_content.encode("utf-8"))

    mutation_spec = {
        "id": "MUT-TEST-01",
        "name": "Test patch failure",
        "description": "Mutation with failing patch apply check",
        "file": target_rel,
        "target": "val speed = 0.0",
        "replacement": "val speed = -1.0",
        "expected_failing_classes": ["VehicleMotionTest"],
    }
    out_dir = tmp_path / "evidence"

    # Mock command runner that fails on git apply --check (exit code 1)
    def mock_run_cmd_failing_apply(cmd: List[str], cwd: Path = tmp_path):
        if "apply" in cmd and "--check" in cmd:
            return 1, "error: patch failed: sample.kt:1\nerror: sample.kt: patch does not apply"
        return 0, ""

    result = run_single_mutation(
        m=mutation_spec,
        repo_root=tmp_path,
        out_dir=out_dir,
        run_cmd_fn=mock_run_cmd_failing_apply,
    )

    # Outcome assertions
    assert result["status"] == MutationResultStatus.INVALID_MUTATION.value
    assert result["mutant_killed"] is False
    assert result["apply_check_exit"] == 1

    # Target file integrity assertion: must NOT be written to or modified
    assert target_file.read_text(encoding="utf-8") == initial_content
    post_sha = compute_sha256(target_file.read_text(encoding="utf-8").encode("utf-8"))
    assert post_sha == initial_sha

    # restore.txt must confirm it was aborted without writing
    restore_txt = out_dir / "MUT-TEST-01" / "restore.txt"
    assert restore_txt.exists()
    content = restore_txt.read_text(encoding="utf-8")
    assert "RESTORE_METHOD: not_modified_patch_check_aborted" in content
    assert "SHA256_MATCH: True" in content


# ==============================================================================
# 4. Positive Test: Expected AssertionError -> KILLED_BY_TEST
# ==============================================================================

def test_classify_killed_by_test_on_assertion_failure():
    """Verify that expected AssertionError in target test class is classified as KILLED_BY_TEST."""
    exit_code = 1
    build_log = (
        "> Task :car-core:testDebugUnitTest FAILED\n"
        "com.cbstudio.telltale.car.hardware.CarVehicleMotionResolverTest > "
        "reverseMotionWithNegativeObdSpeedEvaluatesToMoving FAILED\n"
        "    java.lang.AssertionError: expected:<MOVING> but was:<STATIONARY>\n"
        "FAILURE: Build failed with an exception."
    )
    junit_summary = JUnitTestRunSummary(
        total_tests=7,
        total_failures=1,
        total_errors=0,
        total_skipped=0,
        failures=[
            TestFailureDetail(
                classname="com.cbstudio.telltale.car.hardware.CarVehicleMotionResolverTest",
                testcase="reverseMotionWithNegativeObdSpeedEvaluatesToMoving",
                failure_type="java.lang.AssertionError",
                message="expected:<MOVING> but was:<STATIONARY>",
                kind="failure",
            )
        ],
    )
    expected_failing_classes = ["CarVehicleMotionResolverTest"]

    status, reason = classify_mutation_outcome(
        exit_code=exit_code,
        build_log=build_log,
        junit_summary=junit_summary,
        expected_failing_classes=expected_failing_classes,
    )

    assert status == MutationResultStatus.KILLED_BY_TEST
    assert "CarVehicleMotionResolverTest#reverseMotionWithNegativeObdSpeedEvaluatesToMoving" in reason


# ==============================================================================
# 5. Positive/Negative Test: All Tests Pass -> SURVIVED
# ==============================================================================

def test_classify_survived_when_all_tests_pass():
    """Verify that when Gradle exits 0 and all tests pass with 0 failures,

    the mutant is classified as SURVIVED (escaped detection).
    """
    exit_code = 0
    build_log = "BUILD SUCCESSFUL in 1s"
    junit_summary = JUnitTestRunSummary(
        total_tests=15,
        total_failures=0,
        total_errors=0,
        total_skipped=0,
        failures=[],
    )
    expected_failing_classes = ["CarVehicleMotionResolverTest"]

    status, reason = classify_mutation_outcome(
        exit_code=exit_code,
        build_log=build_log,
        junit_summary=junit_summary,
        expected_failing_classes=expected_failing_classes,
    )

    assert status == MutationResultStatus.SURVIVED
    assert "mutant escaped detection" in reason


# ==============================================================================
# 6. Integrity Invariant: try...finally Guarantees File Restoration on Exception
# ==============================================================================

def test_finally_guarantees_restoration_on_exception(tmp_path: Path):
    """Verify that if an unhandled exception or crash occurs during mutant test execution,

    the finally block guarantees that the file is restored and SHA-256 matches pre-mutation.
    """
    target_rel = "CarVehicleMotionResolver.kt"
    target_file = tmp_path / target_rel
    initial_content = "class Resolver {\n    if (freshSpeeds.any { it != 0.0 }) { return MOVING }\n}\n"
    target_file.write_text(initial_content, encoding="utf-8")
    initial_sha = compute_sha256(initial_content.encode("utf-8"))

    mutation_spec = {
        "id": "MUT-TEST-CRASH",
        "name": "Crash simulation",
        "description": "Simulate crash during test run",
        "file": target_rel,
        "target": "if (freshSpeeds.any { it != 0.0 }) { return MOVING }",
        "replacement": "if (freshSpeeds.any { it > 0.0 }) { return MOVING }",
        "expected_failing_classes": ["CarVehicleMotionResolverTest"],
    }
    out_dir = tmp_path / "evidence"

    # Mock runner: git apply check succeeds, but test_cmd raises an unexpected error
    def mock_run_cmd_crash(cmd: List[str], cwd: Path = tmp_path):
        if "apply" in cmd and "--check" in cmd:
            return 0, ""
        # Simulate runner crash or interruption while mutant is active on disk
        raise RuntimeError("Simulated sudden runner crash or KeyboardInterrupt during test execution")

    with pytest.raises(RuntimeError, match="Simulated sudden runner crash"):
        run_single_mutation(
            m=mutation_spec,
            repo_root=tmp_path,
            out_dir=out_dir,
            run_cmd_fn=mock_run_cmd_crash,
        )

    # Invariant: Target file must be fully restored despite the crash!
    restored_content = target_file.read_text(encoding="utf-8")
    assert restored_content == initial_content
    restored_sha = compute_sha256(restored_content.encode("utf-8"))
    assert restored_sha == initial_sha

    # restore.txt must exist and confirm the successful restoration
    restore_txt = out_dir / "MUT-TEST-CRASH" / "restore.txt"
    assert restore_txt.exists()
    content = restore_txt.read_text(encoding="utf-8")
    assert "RESTORE_METHOD: direct_file_rewrite_and_verification" in content
    assert f"PRE_MUTATION_SHA256: {initial_sha}" in content
    assert f"POST_RESTORE_SHA256: {initial_sha}" in content
    assert "SHA256_MATCH: True" in content


# ==============================================================================
# 7. Audit Invariant: restore.txt Reflects Actual Method and Hash (No Fake Checkout)
# ==============================================================================

def test_restore_txt_reflects_actual_method_and_hash(tmp_path: Path):
    """Verify that restore.txt logs the genuine restoration method and real SHA256 hashes,

    and does NOT contain fake 'git checkout --' logs.
    """
    target_rel = "Guard.kt"
    target_file = tmp_path / target_rel
    initial_content = "val guardActive = true\n"
    target_file.write_text(initial_content, encoding="utf-8")
    initial_sha = compute_sha256(initial_content.encode("utf-8"))

    mutation_spec = {
        "id": "MUT-TEST-RESTORE",
        "name": "Restore log verification",
        "description": "Verify restore.txt output contents",
        "file": target_rel,
        "target": "val guardActive = true",
        "replacement": "val guardActive = false",
        "expected_failing_classes": ["GuardTest"],
    }
    out_dir = tmp_path / "evidence"

    def mock_run_cmd_normal(cmd: List[str], cwd: Path = tmp_path):
        return 0, "OK"

    run_single_mutation(
        m=mutation_spec,
        repo_root=tmp_path,
        out_dir=out_dir,
        run_cmd_fn=mock_run_cmd_normal,
        dry_run=True,
    )

    restore_txt = out_dir / "MUT-TEST-RESTORE" / "restore.txt"
    assert restore_txt.exists()
    content = restore_txt.read_text(encoding="utf-8")

    # Positive assertions: Real restoration method and SHA-256 hashes
    assert "RESTORE_METHOD: direct_file_rewrite_and_verification" in content
    assert f"TARGET_FILE: {target_rel}" in content
    assert f"PRE_MUTATION_SHA256: {initial_sha}" in content
    assert f"POST_RESTORE_SHA256: {initial_sha}" in content
    assert "SHA256_MATCH: True" in content

    # Negative assertion: No fake git checkout command
    assert "git checkout --" not in content


# ==============================================================================
# 8. JUnit XML Parsing Tests
# ==============================================================================

def test_parse_gradle_junit_reports_parses_failures_and_errors(tmp_path: Path):
    """Verify parse_gradle_junit_reports correctly parses testcase count, failures, and errors."""
    xml_content = """<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="com.cbstudio.telltale.car.hardware.CarVehicleMotionResolverTest" tests="3" skipped="1" failures="1" errors="1">
  <testcase name="testPass" classname="com.cbstudio.telltale.car.hardware.CarVehicleMotionResolverTest" time="0.01"/>
  <testcase name="testSkipped" classname="com.cbstudio.telltale.car.hardware.CarVehicleMotionResolverTest">
    <skipped/>
  </testcase>
  <testcase name="testFail" classname="com.cbstudio.telltale.car.hardware.CarVehicleMotionResolverTest">
    <failure message="expected true but was false" type="java.lang.AssertionError">
Stacktrace here
    </failure>
  </testcase>
  <testcase name="testError" classname="com.cbstudio.telltale.car.hardware.CarVehicleMotionResolverTest">
    <error message="Class not found" type="java.lang.ClassNotFoundException">
Error stacktrace
    </error>
  </testcase>
</testsuite>
"""
    xml_file = tmp_path / "TEST-com.cbstudio.telltale.car.hardware.CarVehicleMotionResolverTest.xml"
    xml_file.write_text(xml_content, encoding="utf-8")

    summary = parse_gradle_junit_reports(tmp_path)
    assert summary.total_tests == 3
    assert summary.total_failures == 1
    assert summary.total_errors == 1
    assert summary.total_skipped == 1
    assert len(summary.failures) == 2

    # Check failure detail
    fail_detail = summary.failures[0]
    assert fail_detail.kind == "failure"
    assert fail_detail.testcase == "testFail"
    assert fail_detail.failure_type == "java.lang.AssertionError"
    assert "expected true but was false" in fail_detail.message

    # Check error detail
    err_detail = summary.failures[1]
    assert err_detail.kind == "error"
    assert err_detail.testcase == "testError"
    assert err_detail.failure_type == "java.lang.ClassNotFoundException"


def test_parse_gradle_junit_reports_empty_dir(tmp_path: Path):
    """Verify parse_gradle_junit_reports returns 0s when directory has no XML files."""
    empty_dir = tmp_path / "empty_dir"
    empty_dir.mkdir()
    summary = parse_gradle_junit_reports(empty_dir)
    assert summary.total_tests == 0
    assert summary.total_failures == 0
    assert summary.total_errors == 0
    assert summary.total_skipped == 0
    assert summary.failures == []


# ==============================================================================
# 9. Timeout Classification Test
# ==============================================================================

def test_classify_timeout():
    """Verify that exit code 124 or timeout string in log is classified as TIMEOUT."""
    status, reason = classify_mutation_outcome(
        exit_code=124,
        build_log="Command timed out after 300 seconds",
        junit_summary=JUnitTestRunSummary(0, 0, 0, 0, []),
        expected_failing_classes=["CarVehicleMotionResolverTest"],
    )
    assert status == MutationResultStatus.TIMEOUT
    assert "timed out" in reason.lower()


# ==============================================================================
# 10. Runtime Infrastructure Error Classification Test
# ==============================================================================

def test_classify_runtime_infra_error_on_test_error():
    """Verify that runtime errors (e.g. ClassNotFoundException / environment crash)

    during test execution with no assertion failures are classified as INFRA_ERROR.
    """
    junit_summary = JUnitTestRunSummary(
        total_tests=5,
        total_failures=0,
        total_errors=1,
        total_skipped=0,
        failures=[
            TestFailureDetail(
                classname="com.cbstudio.telltale.car.SomeTest",
                testcase="testSetup",
                failure_type="java.lang.NoClassDefFoundError",
                message="Could not initialize class com.cbstudio.telltale.car.NativeLib",
                kind="error",
            )
        ],
    )
    status, reason = classify_mutation_outcome(
        exit_code=1,
        build_log="BUILD FAILED",
        junit_summary=junit_summary,
        expected_failing_classes=["CarVehicleMotionResolverTest"],
    )
    assert status == MutationResultStatus.INFRA_ERROR
    assert "Runtime infrastructure error" in reason


def test_dry_run_is_not_executed_and_never_reuses_junit(tmp_path: Path):
    target = tmp_path / "sample.kt"
    target.write_text("val motion = UNKNOWN\n", encoding="utf-8")
    stale_results = tmp_path / "results"
    stale_results.mkdir()
    (stale_results / "TEST-stale.xml").write_text(
        '<testsuite tests="1" failures="1"><testcase classname="GuardTest" name="fails">'
        '<failure type="AssertionError">old</failure></testcase></testsuite>',
        encoding="utf-8",
    )
    mutation = {
        "id": "MUT-DRY",
        "name": "dry run",
        "description": "dry-run classification",
        "file": "sample.kt",
        "target": "UNKNOWN",
        "replacement": "STATIONARY",
        "expected_failing_classes": ["GuardTest"],
    }

    def fake_cmd(cmd, cwd=tmp_path):
        return 0, ""

    result = run_single_mutation(
        mutation,
        tmp_path,
        tmp_path / "evidence",
        junit_results_dir=stale_results,
        dry_run=True,
        run_cmd_fn=fake_cmd,
    )

    assert result["status"] == MutationResultStatus.NOT_EXECUTED.value
    assert result["mutant_killed"] is False
    assert result["mutant_test_exit"] is None
    assert result["restored_test_exit"] is None
    assert result["restored_test_passed"] is False
    assert result["junit_summary"]["total_tests"] == 0
    assert not (tmp_path / "evidence" / "MUT-DRY" / "mutant-test.txt").exists()


def test_live_run_does_not_reuse_stale_junit_from_other_directory(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
):
    target = tmp_path / "Guard.kt"
    target.write_text("val guardActive = true\n", encoding="utf-8")
    selected_results = tmp_path / "selected-results"
    selected_results.mkdir()
    stale_results = tmp_path / "stale-results"
    stale_results.mkdir()
    (stale_results / "TEST-stale.xml").write_text(
        '<testsuite tests="1" failures="1"><testcase classname="GuardTest" name="fails">'
        '<failure type="AssertionError">old failure</failure></testcase></testsuite>',
        encoding="utf-8",
    )
    monkeypatch.setattr(mutation_runner, "DEFAULT_JUNIT_RESULTS_DIRS", [stale_results])

    mutation = {
        "id": "MUT-FRESH-JUNIT",
        "name": "fresh junit only",
        "description": "Never classify from another invocation's reports",
        "file": "Guard.kt",
        "target": "val guardActive = true",
        "replacement": "val guardActive = false",
        "expected_failing_classes": ["GuardTest"],
    }
    command_count = 0

    def fake_cmd(cmd: List[str], cwd: Path = tmp_path):
        nonlocal command_count
        if "apply" in cmd and "--check" in cmd:
            return 0, ""
        command_count += 1
        return (1, "BUILD FAILED") if command_count == 1 else (0, "BUILD SUCCESSFUL")

    result = run_single_mutation(
        mutation,
        tmp_path,
        tmp_path / "evidence",
        junit_results_dir=selected_results,
        run_cmd_fn=fake_cmd,
    )

    assert result["status"] == MutationResultStatus.INFRA_ERROR.value
    assert result["mutant_killed"] is False
    assert result["junit_summary"]["total_tests"] == 0


def test_isolated_evidence_run_preserves_and_excludes_seeded_stale_logs(tmp_path: Path):
    evidence_root = tmp_path / "evidence"
    evidence_root.mkdir()
    stale_log = evidence_root / "MUT-AA08-01" / "mutant-test.txt"
    stale_log.parent.mkdir()
    stale_log.write_text("STALE LIVE LOG", encoding="utf-8")
    unrelated = evidence_root / "README.md"
    unrelated.write_text("keep me", encoding="utf-8")

    run_dir = create_evidence_run_dir(evidence_root, dry_run=True)
    (run_dir / "manifest.json").write_text('{"verified": false}\n', encoding="utf-8")

    assert run_dir.parent == evidence_root
    assert "dry-run" in run_dir.name
    assert stale_log.read_text(encoding="utf-8") == "STALE LIVE LOG"
    assert unrelated.read_text(encoding="utf-8") == "keep me"
    assert not (run_dir / "MUT-AA08-01" / "mutant-test.txt").exists()
    assert list(run_dir.rglob("*.txt")) == []
