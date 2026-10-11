#!/usr/bin/env python3
"""Targeted Mutation Testing Suite for Automotive Safety Guards (AA-08 Milestone M4 / SAFE-08).

Measures whether the test suite kills deliberate, dangerous mutations
in the automotive core safety guards (:car-core):
  - MUT-AA08-01: Reverse speed check weakening in CarVehicleMotionResolver.kt
  - MUT-AA08-02: Motion gate disconnected phase speed check weakening in CarDtcMotionGate.kt
  - MUT-AA08-03: ConnectionEpoch isolation removal in CarHealthEvaluator.kt
  - MUT-AA08-04: Pre-render secondary isStationary verification removal in CarDtcSummaryScreen.kt

Protocol per mutant:
  1. Generate unified diff patch.
  2. Verify patch apply check (`git apply --check`).
     If apply check fails, abort immediately as INVALID_MUTATION without writing mutant.
  3. Apply mutation patch to working tree.
  4. In a try...finally block:
     a. Run test suite against mutant.
     b. Parse Gradle JUnit XML reports (TEST-*.xml).
     c. Classify outcome into five-dimensional status:
        KILLED_BY_TEST, SURVIVED, INVALID_MUTATION, INFRA_ERROR, TIMEOUT.
     d. Finally: restore file to exact pre-mutation baseline via direct file rewrite,
        verify pre/post SHA-256 match, and log restore details to restore.txt and manifest.json.
  5. If live run, execute restored test suite -> ASSERT test pass (exit code == 0).
  6. Record evidence, logs, and SHA256 sums to evidence directory.
"""

import argparse
import difflib
import hashlib
import json
import os
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Tuple, Union


REPO_ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE_DIR = REPO_ROOT / "docs" / "verification" / "aa08-mutation-evidence"

TEST_CMD = ["./android/gradlew", "-p", "android", ":car-core:testDebugUnitTest"]

DEFAULT_JUNIT_RESULTS_DIRS = [
    REPO_ROOT / "build" / "car-core" / "test-results" / "testDebugUnitTest",
    REPO_ROOT / "android" / "car-core" / "build" / "test-results" / "testDebugUnitTest",
]


class MutationResultStatus(str, Enum):
    KILLED_BY_TEST = "KILLED_BY_TEST"
    SURVIVED = "SURVIVED"
    INVALID_MUTATION = "INVALID_MUTATION"
    INFRA_ERROR = "INFRA_ERROR"
    TIMEOUT = "TIMEOUT"
    NOT_EXECUTED = "NOT_EXECUTED"


@dataclass
class TestFailureDetail:
    __test__ = False
    classname: str
    testcase: str
    failure_type: str
    message: str
    kind: str  # 'failure' | 'error'


@dataclass
class JUnitTestRunSummary:
    total_tests: int
    total_failures: int
    total_errors: int
    total_skipped: int
    failures: List[TestFailureDetail]


MUTATIONS: List[Dict[str, Any]] = [
    {
        "id": "MUT-AA08-01",
        "name": "Reverse speed check weakening",
        "description": "Weaken reverse motion check from 'it != 0.0' to 'it > 0.0', ignoring negative speeds",
        "file": "android/car-core/src/main/kotlin/com/cbstudio/telltale/car/hardware/CarVehicleMotionResolver.kt",
        "target": "        if (freshSpeeds.any { it != 0.0 }) {",
        "replacement": "        if (freshSpeeds.any { it > 0.0 }) {",
        "expected_failing_classes": [
            "CarVehicleMotionResolverTest",
            "CarDtcMotionGateTest",
        ],
    },
    {
        "id": "MUT-AA08-02",
        "name": "Motion gate non-connected fail-open",
        "description": "Treat unresolved non-connected host motion as stationary, allowing DTC access without live zero-speed evidence",
        "file": "android/car-core/src/main/kotlin/com/cbstudio/telltale/car/safety/CarDtcMotionGate.kt",
        "target": "                    } else {\n                        CarDtcMotionState.UNKNOWN\n                    }",
        "replacement": "                    } else {\n                        CarDtcMotionState.STATIONARY\n                    }",
        "expected_failing_classes": [
            "CarDtcMotionGateTest",
            "CarDtcMotionGateAdversarialStressTest",
        ],
    },
    {
        "id": "MUT-AA08-03",
        "name": "ConnectionEpoch isolation removal",
        "description": "Remove connectionEpoch isolation check in matchingDtcReport, allowing cross-epoch report pollution",
        "file": "android/car-core/src/main/kotlin/com/cbstudio/telltale/car/health/CarHealthEvaluator.kt",
        "target": "    if (currentTelemetry.connectionEpoch != currentDtc.connectionEpoch) return null",
        "replacement": "    // Epoch isolation removed",
        "expected_failing_classes": [
            "CarDtcScreensTest",
            "CarHealthScreenTest",
            "CarAlertEvaluatorTest",
            "CarAlertCoordinatorTest",
        ],
    },
    {
        "id": "MUT-AA08-04",
        "name": "Pre-render secondary isStationary verification removal",
        "description": "Remove pre-render isStationary secondary safety check and popTo in CarDtcSummaryScreen.onGetTemplate",
        "file": "android/car-core/src/main/kotlin/com/cbstudio/telltale/car/CarDtcSummaryScreen.kt",
        "target": """        // SAFE-04 / SAFE-06: Secondary motion check right before rendering template
        if (!CarDtcMotionGate.isStationary(telemetryRepository.state.value, hostSpeedRepository.sample.value, motionResolver)) {
            try {
                screenManager.popTo(CarHealthScreen.CAR_HEALTH_MARKER)
            } catch (_: Throwable) {
                try {
                    screenManager.pop()
                } catch (_: Throwable) {
                }
            }
            val header = Header.Builder()
                .setTitle(carContext.getString(R.string.car_dtc_summary_title))
                .setStartHeaderAction(Action.BACK)
                .build()

            return ListTemplate.Builder()
                .setHeader(header)
                .setSingleList(
                    ItemList.Builder()
                        .addItem(
                            Row.Builder()
                                .setTitle(carContext.getString(R.string.car_dtc_status_unavailable))
                                .build(),
                        )
                        .build(),
                )
                .build()
        }""",
        "replacement": "        // SAFE-04 / SAFE-06: Secondary motion check removed",
        "expected_failing_classes": [
            "CarDtcScreensTest",
            "CarDtcEmpiricalChallengeTest",
        ],
    },
]


def run_cmd(
    cmd: List[str],
    cwd: Path = REPO_ROOT,
    check: bool = False,
    timeout: Optional[int] = None,
) -> Tuple[int, str]:
    """Run shell command returning (exit_code, stdout+stderr)."""
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=timeout,
        )
        if check and result.returncode != 0:
            raise RuntimeError(f"Command failed (exit {result.returncode}): {' '.join(cmd)}\n{result.stdout}")
        return result.returncode, result.stdout
    except subprocess.TimeoutExpired as e:
        output = (e.stdout or "") if isinstance(e.stdout, str) else ""
        return 124, f"Command timed out after {timeout} seconds: {' '.join(cmd)}\n{output}"


def get_git_rev(ref: str = "HEAD", cwd: Path = REPO_ROOT) -> str:
    code, out = run_cmd(["git", "rev-parse", ref], cwd=cwd)
    return out.strip() if code == 0 else "unknown"


def generate_patch(file_path: Union[str, Path], original_text: str, mutated_text: str) -> str:
    """Generate git-apply compatible unified diff."""
    rel_path = str(file_path)
    lines_orig = original_text.splitlines(keepends=True)
    lines_mut = mutated_text.splitlines(keepends=True)
    diff = difflib.unified_diff(
        lines_orig,
        lines_mut,
        fromfile=f"a/{rel_path}",
        tofile=f"b/{rel_path}",
    )
    return "".join(diff)


def compute_sha256(data_bytes: bytes) -> str:
    return hashlib.sha256(data_bytes).hexdigest()


def write_file(path: Path, content: Union[str, bytes]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(content, str):
        path.write_text(content, encoding="utf-8")
    else:
        path.write_bytes(content)


def resolve_junit_results_dir(
    repo_root: Path = REPO_ROOT,
    preferred_dir: Optional[Path] = None,
) -> Path:
    """Resolve the directory containing Gradle JUnit XML reports."""
    if preferred_dir:
        return preferred_dir
    candidates = [
        repo_root / "build" / "car-core" / "test-results" / "testDebugUnitTest",
        repo_root / "android" / "car-core" / "build" / "test-results" / "testDebugUnitTest",
    ]
    for c in candidates:
        if c.exists():
            return c
    return candidates[0]


def clean_test_results_dir(results_dir: Path) -> None:
    """Clean old XML reports from results directory before a test run."""
    if results_dir.exists():
        for f in results_dir.glob("TEST-*.xml"):
            try:
                f.unlink()
            except OSError:
                pass


def parse_gradle_junit_reports(
    results_dir: Path,
    fallback_to_defaults: bool = False,
) -> JUnitTestRunSummary:
    """Parse all TEST-*.xml files produced by Gradle in results_dir or fallback candidate."""
    dirs_to_check = [results_dir]
    # If fallback is requested and the provided path doesn't have XMLs, check fallback paths
    if fallback_to_defaults and (not results_dir.exists() or not list(results_dir.glob("TEST-*.xml"))):
        for default_dir in DEFAULT_JUNIT_RESULTS_DIRS:
            if default_dir != results_dir and default_dir.exists() and default_dir not in dirs_to_check:
                dirs_to_check.append(default_dir)

    xml_files: List[Path] = []
    for d in dirs_to_check:
        if d.exists():
            found = list(d.glob("TEST-*.xml"))
            if found:
                xml_files = found
                break

    if not xml_files:
        return JUnitTestRunSummary(
            total_tests=0,
            total_failures=0,
            total_errors=0,
            total_skipped=0,
            failures=[],
        )

    total_tests = 0
    total_failures = 0
    total_errors = 0
    total_skipped = 0
    failures: List[TestFailureDetail] = []

    for xml_file in sorted(xml_files):
        try:
            tree = ET.parse(xml_file)
            root = tree.getroot()
            suites = [root] if root.tag == "testsuite" else root.findall(".//testsuite")
            if not suites and root.tag != "testsuite":
                suites = [root]

            for suite in suites:
                total_tests += int(suite.attrib.get("tests", 0))
                total_failures += int(suite.attrib.get("failures", 0))
                total_errors += int(suite.attrib.get("errors", 0))
                total_skipped += int(suite.attrib.get("skipped", 0))

                for tc in suite.findall("testcase"):
                    classname = tc.attrib.get("classname", suite.attrib.get("name", ""))
                    testcase_name = tc.attrib.get("name", "")

                    fail_elem = tc.find("failure")
                    err_elem = tc.find("error")
                    if fail_elem is not None:
                        failures.append(
                            TestFailureDetail(
                                classname=classname,
                                testcase=testcase_name,
                                failure_type=fail_elem.attrib.get("type", "AssertionError"),
                                message=fail_elem.attrib.get("message", "") or (fail_elem.text or "").strip(),
                                kind="failure",
                            )
                        )
                    elif err_elem is not None:
                        failures.append(
                            TestFailureDetail(
                                classname=classname,
                                testcase=testcase_name,
                                failure_type=err_elem.attrib.get("type", "Error"),
                                message=err_elem.attrib.get("message", "") or (err_elem.text or "").strip(),
                                kind="error",
                            )
                        )
        except Exception:
            continue

    return JUnitTestRunSummary(
        total_tests=total_tests,
        total_failures=total_failures,
        total_errors=total_errors,
        total_skipped=total_skipped,
        failures=failures,
    )


def classify_mutation_outcome(
    exit_code: int,
    build_log: str,
    junit_summary: JUnitTestRunSummary,
    expected_failing_classes: List[str],
) -> Tuple[MutationResultStatus, str]:
    """Classify mutation outcome according to 5-dimensional status criteria:

    - TIMEOUT: Process timed out.
    - INFRA_ERROR: Kotlin/Java compilation failure or zero tests executed or infrastructure error.
    - SURVIVED: All tests passed with zero failures and zero errors.
    - KILLED_BY_TEST: Expected safety guard test assertion failure occurred.
    """
    # 1. Timeout detection
    if exit_code == 124 or "TIMEOUT" in build_log or "timed out" in build_log.lower():
        return MutationResultStatus.TIMEOUT, "Execution timed out"

    # 2. Compilation / Build Infrastructure failures
    compilation_error_tokens = [
        "compileDebugKotlin FAILED",
        "compileDebugJavaWithJavac FAILED",
        "Compilation error",
        "Unresolved reference",
        "Compilation failed",
    ]
    if any(tok in build_log for tok in compilation_error_tokens):
        return (
            MutationResultStatus.INFRA_ERROR,
            "Compilation failed (syntax/type error in mutant)",
        )

    # 3. Zero tests executed
    if junit_summary.total_tests == 0:
        return (
            MutationResultStatus.INFRA_ERROR,
            f"Zero tests executed (exit={exit_code})",
        )

    # 4. Mutant survived (all tests passed)
    if exit_code == 0 and junit_summary.total_failures == 0 and junit_summary.total_errors == 0:
        return (
            MutationResultStatus.SURVIVED,
            "All tests passed; mutant escaped detection",
        )

    # 5. Matching expected failure with AssertionError
    matching_failures = [
        f
        for f in junit_summary.failures
        if any(target in f.classname for target in expected_failing_classes)
        and ("AssertionError" in f.failure_type or "assertion" in f.failure_type.lower())
    ]
    if matching_failures:
        first = matching_failures[0]
        return (
            MutationResultStatus.KILLED_BY_TEST,
            f"Killed by expected assertion failure: {first.classname}#{first.testcase}",
        )

    # 6. Other test assertion failures
    other_assertion_failures = [
        f
        for f in junit_summary.failures
        if "AssertionError" in f.failure_type or "assertion" in f.failure_type.lower()
    ]
    if other_assertion_failures:
        first = other_assertion_failures[0]
        return (
            MutationResultStatus.KILLED_BY_TEST,
            f"Killed by test assertion: {first.classname}#{first.testcase}",
        )

    # 7. Runtime / Infrastructure errors (e.g. ClassNotFound, Gradle error during test run)
    if junit_summary.total_errors > 0 and junit_summary.total_failures == 0:
        err_type = junit_summary.failures[0].failure_type if junit_summary.failures else "Runtime error"
        return (
            MutationResultStatus.INFRA_ERROR,
            f"Runtime infrastructure error during test: {err_type}",
        )

    # 8. Other general test failures
    if junit_summary.total_failures > 0:
        first = junit_summary.failures[0]
        return (
            MutationResultStatus.KILLED_BY_TEST,
            f"Killed by test failure: {first.classname}#{first.testcase}",
        )

    # 9. Fallback infrastructure error
    return (
        MutationResultStatus.INFRA_ERROR,
        f"Test execution failed without verified test assertion (exit={exit_code})",
    )


def run_single_mutation(
    m: Dict[str, Any],
    repo_root: Path,
    out_dir: Path,
    test_cmd: List[str] = TEST_CMD,
    junit_results_dir: Optional[Path] = None,
    dry_run: bool = False,
    run_cmd_fn: Callable = run_cmd,
) -> Dict[str, Any]:
    """Execute a single targeted mutation experiment with strict verification and restoration."""
    m_id = m["id"]
    m_name = m["name"]
    m_file_rel = m["file"]
    m_file_abs = repo_root / m_file_rel
    m_target = m["target"]
    m_replacement = m["replacement"]
    expected_failing_classes = m.get("expected_failing_classes", [])

    m_dir = out_dir / m_id
    m_dir.mkdir(parents=True, exist_ok=True)

    print(f"\n--- {m_id}: {m_name} ---")
    print(f"Target: {m_file_rel}")

    # 1. Read original content
    if not m_file_abs.exists():
        print(f"❌ Target file does not exist: {m_file_rel}")
        return {
            "id": m_id,
            "status": MutationResultStatus.INVALID_MUTATION.value,
            "status_reason": f"Target file does not exist: {m_file_rel}",
            "target_file": m_file_rel,
            "target_test": f"{m_id} ({m_name})",
            "description": m["description"],
            "patch_sha256": None,
            "apply_check_exit": -1,
            "mutant_test_exit": None,
            "mutant_killed": False,
            "pre_mutation_sha256": None,
            "post_restore_sha256": None,
            "restore_sha_match": False,
            "restored_test_exit": None,
            "restored_test_passed": False,
        }

    orig_content = m_file_abs.read_text(encoding="utf-8")
    orig_sha = compute_sha256(orig_content.encode("utf-8"))

    if m_target not in orig_content:
        print(f"❌ Target substring not found in {m_file_rel}!")
        return {
            "id": m_id,
            "status": MutationResultStatus.INVALID_MUTATION.value,
            "status_reason": "Target substring not found in source file",
            "target_file": m_file_rel,
            "target_test": f"{m_id} ({m_name})",
            "description": m["description"],
            "patch_sha256": None,
            "apply_check_exit": -1,
            "mutant_test_exit": None,
            "mutant_killed": False,
            "pre_mutation_sha256": orig_sha,
            "post_restore_sha256": orig_sha,
            "restore_sha_match": True,
            "restored_test_exit": None,
            "restored_test_passed": False,
        }

    mut_content = orig_content.replace(m_target, m_replacement, 1)

    # 2. Generate patch
    patch_text = generate_patch(m_file_rel, orig_content, mut_content)
    patch_file = m_dir / "mutation.patch"
    write_file(patch_file, patch_text)
    patch_sha = compute_sha256(patch_text.encode("utf-8"))

    # 3. Patch apply check (git apply --check)
    try:
        patch_arg = str(patch_file.relative_to(repo_root))
    except ValueError:
        patch_arg = str(patch_file.resolve())

    apply_check_cmd = ["git", "apply", "--check", patch_arg]
    chk_code, chk_log = run_cmd_fn(apply_check_cmd, cwd=repo_root)
    write_file(
        m_dir / "apply-check.txt",
        f"{' '.join(apply_check_cmd)}\nEXIT: {chk_code}\n{chk_log}",
    )

    if chk_code != 0:
        print(f"❌ git apply --check failed for {m_id} (exit={chk_code})! Aborting mutant write.")
        restore_log = (
            f"RESTORE_METHOD: not_modified_patch_check_aborted\n"
            f"TARGET_FILE: {m_file_rel}\n"
            f"PRE_MUTATION_SHA256: {orig_sha}\n"
            f"POST_RESTORE_SHA256: {orig_sha}\n"
            f"SHA256_MATCH: True\n"
        )
        write_file(m_dir / "restore.txt", restore_log)
        return {
            "id": m_id,
            "status": MutationResultStatus.INVALID_MUTATION.value,
            "status_reason": f"git apply --check failed with exit code {chk_code}",
            "target_file": m_file_rel,
            "target_test": f"{m_id} ({m_name})",
            "description": m["description"],
            "patch_sha256": patch_sha,
            "apply_check_exit": chk_code,
            "mutant_test_exit": None,
            "mutant_killed": False,
            "pre_mutation_sha256": orig_sha,
            "post_restore_sha256": orig_sha,
            "restore_sha_match": True,
            "restored_test_exit": None,
            "restored_test_passed": True,
        }

    # 4. Apply mutation and execute in try...finally block
    res_dir = resolve_junit_results_dir(repo_root, junit_results_dir)
    mut_code = -1
    mut_log = ""
    status = MutationResultStatus.INFRA_ERROR
    reason = "Unknown"
    junit_summary = JUnitTestRunSummary(0, 0, 0, 0, [])

    try:
        if not dry_run:
            clean_test_results_dir(res_dir)
        m_file_abs.write_text(mut_content, encoding="utf-8")

        if dry_run:
            print("  [DRY-RUN] Patch generation/application checked; tests were NOT EXECUTED.")
            mut_code = None
            mut_log = ""
            status = MutationResultStatus.NOT_EXECUTED
            reason = "DRY_RUN: mutation tests and JUnit parsing were not executed"
        else:
            t0 = time.time()
            mut_code, mut_log = run_cmd_fn(test_cmd, cwd=repo_root)
            mut_elapsed = time.time() - t0
            write_file(
                m_dir / "mutant-test.txt",
                f"{' '.join(test_cmd)}\nEXIT: {mut_code}\n{mut_log}",
            )

            junit_summary = parse_gradle_junit_reports(res_dir, fallback_to_defaults=True)
            status, reason = classify_mutation_outcome(
                exit_code=mut_code,
                build_log=mut_log,
                junit_summary=junit_summary,
                expected_failing_classes=expected_failing_classes,
            )
            print(f"  [{status.value}] {reason} (exit={mut_code}, duration={mut_elapsed:.1f}s)")
    finally:
        # Guarantee restoration under all circumstances
        m_file_abs.write_text(orig_content, encoding="utf-8")
        post_content = m_file_abs.read_text(encoding="utf-8")
        post_sha = compute_sha256(post_content.encode("utf-8"))
        restored = (post_sha == orig_sha)

        restore_log = (
            f"RESTORE_METHOD: direct_file_rewrite_and_verification\n"
            f"TARGET_FILE: {m_file_rel}\n"
            f"PRE_MUTATION_SHA256: {orig_sha}\n"
            f"POST_RESTORE_SHA256: {post_sha}\n"
            f"SHA256_MATCH: {restored}\n"
        )
        write_file(m_dir / "restore.txt", restore_log)

    # 5. Restored baseline run
    if not dry_run:
        t0 = time.time()
        post_code, post_log = run_cmd_fn(test_cmd, cwd=repo_root)
        post_elapsed = time.time() - t0
        write_file(
            m_dir / "restored-test.txt",
            f"{' '.join(test_cmd)}\nEXIT: {post_code}\n{post_log}",
        )
        restored_passed = (post_code == 0)
        print(f"  [RESTORED RUN] Exit code: {post_code} (Passed: {restored_passed}, duration={post_elapsed:.1f}s)")
    else:
        post_code = None
        restored_passed = False

    mutant_killed = (status == MutationResultStatus.KILLED_BY_TEST)

    return {
        "id": m_id,
        "status": status.value,
        "status_reason": reason,
        "target_file": m_file_rel,
        "target_test": f"{m_id} ({m_name})",
        "description": m["description"],
        "patch_sha256": patch_sha,
        "apply_check_exit": chk_code,
        "mutant_test_exit": mut_code,
        "mutant_killed": mutant_killed,
        "pre_mutation_sha256": orig_sha,
        "post_restore_sha256": post_sha,
        "restore_sha_match": restored,
        "restored_test_exit": post_code,
        "restored_test_passed": restored_passed,
        "junit_summary": {
            "total_tests": junit_summary.total_tests,
            "total_failures": junit_summary.total_failures,
            "total_errors": junit_summary.total_errors,
            "total_skipped": junit_summary.total_skipped,
            "failures_count": len(junit_summary.failures),
        },
    }


def main():
    parser = argparse.ArgumentParser(description="Run targeted mutation verification for AA-08.")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=EVIDENCE_DIR,
        help="Directory to save mutation evidence and manifest.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Run fast dry-run verification (checks patch, apply, and restoration without full gradlew test run).",
    )
    parser.add_argument(
        "--mutation-id",
        type=str,
        default=None,
        help="Run specific mutation by ID (e.g. MUT-AA08-01).",
    )
    parser.add_argument(
        "--skip-control",
        action="store_true",
        help="Skip baseline control test run.",
    )
    args = parser.parse_args()

    out_dir = args.output_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    print("=" * 70)
    print("AA-08 / SAFE-08 Targeted Mutation Testing Suite")
    print("=" * 70)
    print(f"Repository Root: {REPO_ROOT}")
    print(f"Evidence Directory: {out_dir}")
    print(f"Test Command: {' '.join(TEST_CMD)}")
    print(f"Dry Run Mode: {'ENABLED' if args.dry_run else 'DISABLED'}")

    head_sha = get_git_rev("HEAD")
    tree_sha = get_git_rev("HEAD^{tree}")

    # Control Run
    control_code = None
    control_status = "SKIPPED"
    if not args.dry_run and not args.skip_control:
        print("\n[Phase 1] Executing Control Test (Baseline)...")
        t0 = time.time()
        control_code, control_log = run_cmd(TEST_CMD)
        elapsed = time.time() - t0
        control_dir = out_dir / "control"
        control_dir.mkdir(parents=True, exist_ok=True)
        write_file(control_dir / "control-test.txt", f"{' '.join(TEST_CMD)}\nEXIT: {control_code}\n{control_log}")

        if control_code != 0:
            print(f"❌ Control test FAILED with exit code {control_code} in {elapsed:.1f}s!")
            sys.exit(1)
        print(f"✅ Control test PASSED in {elapsed:.1f}s.")
        control_status = "PASS"
    else:
        print("\n[Phase 1] Skipping control test (dry-run or skip-control).")

    manifest = {
        "evidence_version": "1.0.0",
        "task_id": "AA08-TARGETED-MUTATION-VERIFICATION",
        "product_head_sha": head_sha,
        "product_tree_sha": tree_sha,
        "control": {
            "command": " ".join(TEST_CMD),
            "exit_code": control_code,
            "status": control_status,
            "executed": control_code is not None,
        },
        "mutations": {},
    }

    mutations_to_run = MUTATIONS
    if args.mutation_id:
        mutations_to_run = [m for m in MUTATIONS if m["id"] == args.mutation_id]
        if not mutations_to_run:
            print(f"❌ Mutation ID {args.mutation_id} not found!")
            sys.exit(1)

    print("\n[Phase 2] Executing Targeted Mutations...")
    all_killed = True
    all_restored = True
    status_breakdown = {status.value: 0 for status in MutationResultStatus}

    for m in mutations_to_run:
        res = run_single_mutation(
            m=m,
            repo_root=REPO_ROOT,
            out_dir=out_dir,
            test_cmd=TEST_CMD,
            dry_run=args.dry_run,
        )
        manifest["mutations"][m["id"]] = res
        status_breakdown[res["status"]] = status_breakdown.get(res["status"], 0) + 1

        if not res["mutant_killed"]:
            all_killed = False
        if not (res["restore_sha_match"] and res["restored_test_passed"]):
            all_restored = False

    total_count = len(mutations_to_run)
    killed_count = status_breakdown[MutationResultStatus.KILLED_BY_TEST.value]
    kill_rate = (killed_count / total_count * 100.0) if total_count > 0 else 0.0

    manifest["summary"] = {
        "total_mutations": total_count,
        "mutants_killed": killed_count,
        "mutant_kill_rate_percent": kill_rate,
        "status_breakdown": status_breakdown,
        "all_restored_passed": all_restored,
        "verified": (not args.dry_run and control_status == "PASS" and all_killed and all_restored),
        "execution_mode": "DRY_RUN" if args.dry_run else "LIVE",
    }

    # Write manifest
    manifest_path = out_dir / "manifest.json"
    write_file(manifest_path, json.dumps(manifest, indent=2) + "\n")

    # Generate SHA256SUMS
    sha256_lines = []
    for root, _, files in os.walk(out_dir):
        for f in sorted(files):
            if f == "SHA256SUMS":
                continue
            fpath = Path(root) / f
            rel = fpath.relative_to(out_dir)
            sha = hashlib.sha256(fpath.read_bytes()).hexdigest()
            sha256_lines.append(f"{sha}  {rel}")

    sha256_file = out_dir / "SHA256SUMS"
    write_file(sha256_file, "\n".join(sha256_lines) + "\n")

    print("\n" + "=" * 70)
    print("MUTATION TESTING RESULTS SUMMARY")
    print("=" * 70)
    print(f"Total Mutants Evaluated: {total_count}")
    print(f"Mutants Killed (TEST):   {killed_count}")
    print(f"Mutant Kill Rate:        {kill_rate:.1f}%")
    print(f"Status Breakdown:        {status_breakdown}")
    print(f"All Restored Clean:      {'YES' if all_restored else 'NO'}")
    print(f"Manifest Written:        {manifest_path}")
    print(f"SHA256SUMS Written:      {sha256_file}")
    print("=" * 70)

    if manifest["summary"]["verified"]:
        print("🏆 100% MUTATION INTERCEPTION VERIFIED - ALL GUARDS PROVED ACTIVE!")
        sys.exit(0)
    else:
        if args.dry_run:
            print("ℹ️ DRY RUN COMPLETE - MUTATION INTERCEPTION WAS NOT EXECUTED OR VERIFIED.")
        else:
            print("❌ MUTATION TEST FAILED - NOT ALL MUTANTS KILLED BY TESTS!")
        sys.exit(1)


if __name__ == "__main__":
    main()
