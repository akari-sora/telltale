"""Challenger 1 Empirical Stress Test Harness for Defect R3.

Empirically tests and stress-tests:
1. Compilation failure simulation -> INFRA_ERROR classification.
2. Zero tests executed simulation -> INFRA_ERROR classification.
3. Patch apply check failure simulation -> INVALID_MUTATION without file modification.
4. Genuine SHA-256 and restoration method verification against manifest.json and restore.txt.
5. Malformed XML and edge case robustness.
"""

import hashlib
import json
import sys
from pathlib import Path
from typing import List
import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from tool.ci.run_targeted_mutations import (
    EVIDENCE_DIR,
    MUTATIONS,
    REPO_ROOT,
    JUnitTestRunSummary,
    MutationResultStatus,
    TestFailureDetail,
    classify_mutation_outcome,
    compute_sha256,
    parse_gradle_junit_reports,
    run_single_mutation,
)


def test_adversarial_compilation_failure_variants():
    """Stress-test various Kotlin/Java compiler failure output patterns."""
    compiler_error_patterns = [
        "compileDebugKotlin FAILED\ne: /path/Test.kt: (1, 1): Syntax error",
        "compileDebugJavaWithJavac FAILED\nerror: ';' expected",
        "e: Compilation error: Type mismatch",
        "Unresolved reference: unresolvedVariable",
        "Compilation failed with 3 errors",
    ]
    for pattern in compiler_error_patterns:
        status, reason = classify_mutation_outcome(
            exit_code=1,
            build_log=f"> Task :car-core:{pattern}\nFAILURE: Build failed.",
            junit_summary=JUnitTestRunSummary(0, 0, 0, 0, []),
            expected_failing_classes=["CarVehicleMotionResolverTest"],
        )
        assert status == MutationResultStatus.INFRA_ERROR, f"Pattern failed to classify as INFRA_ERROR: {pattern}"
        assert status != MutationResultStatus.KILLED_BY_TEST


def test_adversarial_zero_tests_executed_across_exit_codes():
    """Verify that 0 tests executed is ALWAYS INFRA_ERROR regardless of exit code."""
    for code in [0, 1, 2, 130, 137, 255]:
        status, reason = classify_mutation_outcome(
            exit_code=code,
            build_log=f"Build finished with exit code {code}",
            junit_summary=JUnitTestRunSummary(0, 0, 0, 0, []),
            expected_failing_classes=["CarVehicleMotionResolverTest"],
        )
        assert status == MutationResultStatus.INFRA_ERROR, f"Exit code {code} with 0 tests not classified as INFRA_ERROR"
        assert "Zero tests executed" in reason


def test_adversarial_patch_check_failure_aborts_without_file_write(tmp_path: Path):
    """Stress-test git apply --check failure abortion ensuring disk write NEVER occurs."""
    target_rel = "VehicleGuard.kt"
    target_file = tmp_path / target_rel
    original_code = "fun guard() = true\n"
    target_file.write_text(original_code, encoding="utf-8")
    orig_sha = compute_sha256(original_code.encode("utf-8"))
    orig_mtime = target_file.stat().st_mtime_ns

    mutation_spec = {
        "id": "MUT-ADVERSARIAL-PATCH-FAIL",
        "name": "Failing Patch Apply",
        "description": "Ensure no disk mutation when git apply fails",
        "file": target_rel,
        "target": "fun guard() = true",
        "replacement": "fun guard() = false",
        "expected_failing_classes": ["VehicleGuardTest"],
    }
    out_dir = tmp_path / "evidence"

    # Command runner simulating git apply --check failure (exit 128)
    def mock_cmd_failing_patch(cmd: List[str], cwd: Path = tmp_path):
        if "apply" in cmd and "--check" in cmd:
            return 128, "fatal: corrupt patch at line 1"
        return 0, ""

    result = run_single_mutation(
        m=mutation_spec,
        repo_root=tmp_path,
        out_dir=out_dir,
        run_cmd_fn=mock_cmd_failing_patch,
    )

    # Status must be INVALID_MUTATION
    assert result["status"] == MutationResultStatus.INVALID_MUTATION.value
    assert result["mutant_killed"] is False
    assert result["apply_check_exit"] == 128

    # File on disk must not have been touched
    assert target_file.read_text(encoding="utf-8") == original_code
    post_sha = compute_sha256(target_file.read_text(encoding="utf-8").encode("utf-8"))
    assert post_sha == orig_sha
    assert target_file.stat().st_mtime_ns == orig_mtime

    # restore.txt must document the aborted attempt honestly
    restore_file = out_dir / "MUT-ADVERSARIAL-PATCH-FAIL" / "restore.txt"
    assert restore_file.exists()
    restore_content = restore_file.read_text(encoding="utf-8")
    assert "RESTORE_METHOD: not_modified_patch_check_aborted" in restore_content
    assert "SHA256_MATCH: True" in restore_content


def test_adversarial_evidence_manifest_and_restore_txt_integrity():
    """Verify that genuine SHA-256 and restoration method are reported in evidence."""
    manifest_file = EVIDENCE_DIR / "manifest.json"
    assert manifest_file.exists(), "manifest.json does not exist"

    with open(manifest_file, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    mutations = manifest.get("mutations", {})
    assert len(mutations) == 4, f"Expected 4 mutations, got {len(mutations)}"

    for mut_id, mut_data in mutations.items():
        assert mut_data["status"] == "KILLED_BY_TEST"
        assert mut_data["restore_sha_match"] is True

        # Check real file on disk matches reported pre/post SHA-256
        rel_file = mut_data["target_file"]
        abs_file = REPO_ROOT / rel_file
        assert abs_file.exists(), f"Target file does not exist: {rel_file}"

        current_sha = compute_sha256(abs_file.read_bytes())
        assert current_sha == mut_data["pre_mutation_sha256"], f"Pre-mutation SHA mismatch for {mut_id}"
        assert current_sha == mut_data["post_restore_sha256"], f"Post-restore SHA mismatch for {mut_id}"

        # Verify restore.txt
        restore_file = EVIDENCE_DIR / mut_id / "restore.txt"
        assert restore_file.exists(), f"restore.txt does not exist for {mut_id}"
        content = restore_file.read_text(encoding="utf-8")
        assert "RESTORE_METHOD: direct_file_rewrite_and_verification" in content
        assert f"PRE_MUTATION_SHA256: {current_sha}" in content
        assert f"POST_RESTORE_SHA256: {current_sha}" in content
        assert "SHA256_MATCH: True" in content
        assert "git checkout --" not in content, f"Fake git checkout found in restore.txt for {mut_id}"


def test_adversarial_malformed_junit_xml_resilience(tmp_path: Path):
    """Verify parse_gradle_junit_reports does not crash on corrupt XML."""
    corrupt_xml = tmp_path / "TEST-corrupt.xml"
    corrupt_xml.write_text("<testsuite tests='5'> <unclosed_tag", encoding="utf-8")

    summary = parse_gradle_junit_reports(tmp_path)
    assert summary.total_tests == 0
    assert summary.total_failures == 0


def test_adversarial_target_substring_not_found(tmp_path: Path):
    """Verify INVALID_MUTATION when target substring is missing."""
    target_rel = "TestFile.kt"
    target_file = tmp_path / target_rel
    target_file.write_text("class TestFile {}\n", encoding="utf-8")

    mutation_spec = {
        "id": "MUT-MISSING-TARGET",
        "name": "Missing target",
        "description": "Target string not in file",
        "file": target_rel,
        "target": "val nonExistentString = 123",
        "replacement": "val nonExistentString = 456",
        "expected_failing_classes": ["TestFileTest"],
    }
    out_dir = tmp_path / "evidence"
    result = run_single_mutation(mutation_spec, tmp_path, out_dir)
    assert result["status"] == MutationResultStatus.INVALID_MUTATION.value
    assert "Target substring not found" in result["status_reason"]
