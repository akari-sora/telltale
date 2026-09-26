#!/usr/bin/env python3
"""Fail-closed runner and verification gate for required localization and accessibility suites.

Validates that all required test cases registered in the production acceptance
manifest are executed, succeed, have zero skips, and produce valid artifacts.
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

# Import core oracle guard functionality
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_ROOT))
from tool.oracle_guard.assert_no_skips import (
    _parse_events,
    _require_typed_testid,
    _strict_bool,
    GuardError,
)


class L10nRequiredError(Exception):
    """Localization required gate rejection."""


def normalize_suite_path(p: str, repo_root: Path) -> str:
    """Normalizes a suite path to be relative to repo_root where possible."""
    path_obj = Path(p)
    if path_obj.is_absolute():
        try:
            return path_obj.resolve().relative_to(repo_root.resolve()).as_posix()
        except ValueError:
            return path_obj.as_posix()
    return path_obj.as_posix()


def verify_l10n_required(
    manifest_path: Path,
    report_path: Path,
    *,
    runner_exit: int = 0,
    evidence_path: Path | None = None,
    repo_root: Path = REPO_ROOT,
    expected_profile: str | None = None,
    child_stderr: str = "",
) -> dict:
    """Verifies that the report satisfies all requirements in the manifest."""
    try:
        return _verify_l10n_required_inner(
            manifest_path,
            report_path,
            runner_exit=runner_exit,
            evidence_path=evidence_path,
            repo_root=repo_root,
            expected_profile=expected_profile,
            child_stderr=child_stderr,
        )
    except Exception as exc:
        if evidence_path:
            failed_receipt = {
                "status": "REJECTED",
                "error": str(exc),
                "timestampUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            }
            try:
                evidence_path.parent.mkdir(parents=True, exist_ok=True)
                evidence_path.write_text(json.dumps(failed_receipt, indent=2) + "\n", encoding="utf-8")
            except Exception:
                if evidence_path.exists():
                    evidence_path.unlink()
        raise


def _verify_l10n_required_inner(
    manifest_path: Path,
    report_path: Path,
    *,
    runner_exit: int = 0,
    evidence_path: Path | None = None,
    repo_root: Path = REPO_ROOT,
    expected_profile: str | None = None,
    child_stderr: str = "",
) -> dict:
    if runner_exit != 0:
        raise L10nRequiredError(f"Runner failed with nonzero exit code: {runner_exit}")

    if not manifest_path.exists():
        raise L10nRequiredError(f"Manifest not found: {manifest_path}")

    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except Exception as exc:
        raise L10nRequiredError(f"Malformed manifest JSON: {exc}") from exc

    manifest_raw = manifest_path.read_bytes()
    manifest_hash = hashlib.sha256(manifest_raw).hexdigest()

    # Profile validation
    profile = manifest.get("profile")
    if not profile or not isinstance(profile, str) or not profile.strip():
        raise L10nRequiredError("Manifest profile missing or empty")
    allowed_profiles = {"software-root", "test-profile"}
    if expected_profile is not None:
        if profile != expected_profile:
            raise L10nRequiredError(
                f"Manifest profile {profile!r} does not match expected profile {expected_profile!r}"
            )
    elif profile not in allowed_profiles:
        raise L10nRequiredError(f"Unrecognized manifest profile: {profile}")

    required_cases = [c for c in manifest.get("cases", []) if c.get("required") is True]
    if not required_cases:
        raise L10nRequiredError("Manifest contains zero required test cases")

    # Reject duplicate required caseId or targets in manifest
    seen_case_ids: set[str] = set()
    seen_targets: set[tuple[str, str]] = set()
    for req in required_cases:
        case_id = req.get("caseId")
        if not case_id:
            raise L10nRequiredError("Required case missing caseId")
        if case_id in seen_case_ids:
            raise L10nRequiredError(f"Manifest duplicate required caseId: {case_id}")
        seen_case_ids.add(case_id)

        suite_path = req.get("suitePath")
        qualified_name = req.get("qualifiedTestName")
        if not suite_path or not qualified_name:
            raise L10nRequiredError(f"Required case {case_id} missing suitePath or qualifiedTestName")
        norm_target = (normalize_suite_path(suite_path, repo_root), qualified_name)
        if norm_target in seen_targets:
            raise L10nRequiredError(f"Manifest duplicate required test target: {norm_target}")
        seen_targets.add(norm_target)

    if not report_path.exists():
        raise L10nRequiredError(f"Report not found: {report_path}")

    report_raw = report_path.read_bytes()
    report_hash = hashlib.sha256(report_raw).hexdigest()
    report_text = report_raw.decode("utf-8-sig", errors="replace")

    try:
        events = _parse_events(report_text)
    except GuardError as exc:
        raise L10nRequiredError(f"Report JSON guard rejected report: {exc}") from exc

    # Parse and validate events strictly
    suite_id_to_path: dict[int, str] = {}
    test_id_to_info: dict[int, dict] = {}
    test_id_to_outcome: dict[int, dict] = {}
    started_test_ids: set[int] = set()
    terminal_test_ids: set[int] = set()
    done_seen = False
    done_index: int | None = None

    for index, event in enumerate(events):
        etype = event.get("type")
        if done_seen:
            if etype == "done":
                raise L10nRequiredError("Duplicate done event")
            raise L10nRequiredError(f"Event after terminal done ({etype})")

        if etype == "suite":
            sinfo = event.get("suite")
            if isinstance(sinfo, dict):
                sid = sinfo.get("id")
                spath = sinfo.get("path", "")
                if isinstance(sid, int) and not isinstance(sid, bool):
                    suite_id_to_path[sid] = normalize_suite_path(spath, repo_root)

        elif etype == "testStart":
            tinfo = event.get("test")
            if not isinstance(tinfo, dict):
                raise L10nRequiredError("testStart missing test object")
            raw_id = tinfo.get("id")
            if raw_id is None or isinstance(raw_id, bool) or not isinstance(raw_id, int):
                raise L10nRequiredError("testStart test ID must be integer")
            tname = tinfo.get("name", "")
            sid = tinfo.get("suiteID")
            spath = suite_id_to_path.get(sid, "")
            started_test_ids.add(raw_id)
            test_id_to_info[raw_id] = {
                "name": tname,
                "suite_id": sid,
                "suite_path": spath,
            }

        elif etype == "error":
            raise L10nRequiredError(f"Report contains error event: {event.get('error', 'unknown error')}")

        elif etype == "testDone":
            tid = event.get("testID")
            if tid is None or isinstance(tid, bool) or not isinstance(tid, int):
                raise L10nRequiredError(f"testDone testID must be integer: {tid}")
            if tid not in started_test_ids:
                raise L10nRequiredError(f"testDone testID={tid} without testStart")
            if tid in terminal_test_ids:
                raise L10nRequiredError(f"Duplicate terminal for testID={tid}")
            terminal_test_ids.add(tid)

            if "result" not in event:
                raise L10nRequiredError(f"testDone testID={tid} missing result")

            try:
                hidden = _strict_bool(event.get("hidden"), "hidden", "testDone", tid)
                skipped = _strict_bool(event.get("skipped"), "skipped", "testDone", tid)
            except GuardError as exc:
                raise L10nRequiredError(f"Report JSON guard rejected testDone event: {exc}") from exc
            result = event.get("result")
            test_id_to_outcome[tid] = {
                "result": result,
                "hidden": hidden,
                "skipped": skipped,
            }

        elif etype == "done":
            if not started_test_ids:
                raise L10nRequiredError("done event before any tests started")
            if "success" not in event:
                raise L10nRequiredError("terminal done missing success")
            if event.get("success") is not True:
                raise L10nRequiredError("done.success is not true")
            unfinished = started_test_ids - terminal_test_ids
            if unfinished:
                raise L10nRequiredError(f"done event but tests still running: {sorted(unfinished)}")
            done_seen = True
            done_index = index

    if not done_seen:
        raise L10nRequiredError("Report missing terminal done event")
    if done_index != len(events) - 1:
        raise L10nRequiredError("Terminal done is not the last event")

    # Match manifest required cases against actual test outcomes (1-to-1 exact matching)
    verified_cases = []
    missing_cases = []
    failed_cases = []
    skipped_cases = []
    claimed_test_ids: set[int] = set()

    for req in required_cases:
        case_id = req.get("caseId")
        expected_norm_suite = normalize_suite_path(req.get("suitePath", ""), repo_root)
        expected_name = req.get("qualifiedTestName", "")

        matched_tid = None
        for tid, tinfo in test_id_to_info.items():
            t_suite = tinfo.get("suite_path", "")
            t_name = tinfo.get("name", "")
            suite_match = (not expected_norm_suite) or (not t_suite) or (t_suite == expected_norm_suite)
            if suite_match and t_name == expected_name:
                matched_tid = tid
                break

        if matched_tid is None:
            missing_cases.append(case_id)
            continue

        if matched_tid in claimed_test_ids:
            raise L10nRequiredError(
                f"Test ID {matched_tid} already claimed by another required case (1-to-1 violation)"
            )
        claimed_test_ids.add(matched_tid)

        outcome = test_id_to_outcome.get(matched_tid)
        if not outcome:
            missing_cases.append(case_id)
            continue

        if outcome.get("hidden") is True:
            raise L10nRequiredError(f"Required case {case_id} was marked hidden")

        if outcome.get("skipped") is True:
            skipped_cases.append(case_id)
            continue

        if outcome.get("result") != "success":
            failed_cases.append((case_id, outcome.get("result")))
            continue

        # Check artifact roles if specified
        artifact_receipts = []
        for artifact_rel in req.get("artifactRoles", []):
            artifact_file = repo_root / artifact_rel
            if not artifact_file.exists():
                raise L10nRequiredError(
                    f"Required artifact for case {case_id} not found: {artifact_rel}"
                )
            content = artifact_file.read_bytes()
            if len(content) == 0:
                raise L10nRequiredError(
                    f"Required artifact for case {case_id} is empty: {artifact_rel}"
                )
            if artifact_rel.endswith(".png"):
                if not content.startswith(b"\x89PNG\r\n\x1a\n"):
                    raise L10nRequiredError(
                        f"Required artifact {artifact_rel} is not a valid PNG (bad magic header)"
                    )
            ahash = hashlib.sha256(content).hexdigest()
            artifact_receipts.append({
                "path": artifact_rel,
                "bytes": len(content),
                "sha256": ahash,
            })

        verified_cases.append({
            "caseId": case_id,
            "qualifiedTestName": test_id_to_info[matched_tid]["name"],
            "result": "success",
            "artifacts": artifact_receipts,
        })

    if missing_cases:
        raise L10nRequiredError(f"Required cases missing from report: {missing_cases}")
    if skipped_cases:
        raise L10nRequiredError(f"Required cases were skipped: {skipped_cases}")
    if failed_cases:
        raise L10nRequiredError(f"Required cases failed: {failed_cases}")

    receipt = {
        "status": "ACCEPTED",
        "profile": manifest.get("profile", "software-root"),
        "timestampUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "manifestHash": manifest_hash,
        "reportHash": report_hash,
        "requiredCasesTotal": len(required_cases),
        "requiredCasesPassed": len(verified_cases),
        "cases": verified_cases,
        "nativeResiduals": manifest.get("nativeResiduals", []),
    }

    if evidence_path:
        evidence_dir = evidence_path.parent
        evidence_dir.mkdir(parents=True, exist_ok=True)
        evidence_path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")

        # Archive original test report and artifacts when writing to ci-artifacts or designated bundle directory
        if "ci-artifacts" in str(evidence_dir) or evidence_dir.name not in ("evidence", "docs"):
            try:
                target_report = evidence_dir / "report.jsonl"
                if report_path.resolve() != target_report.resolve():
                    shutil.copyfile(report_path, target_report)
                (evidence_dir / "child.exit").write_text(f"{runner_exit}\n", encoding="utf-8")
                if child_stderr:
                    (evidence_dir / "child.stderr.txt").write_text(child_stderr, encoding="utf-8")

                # Copy verified artifacts to evidence archive
                for vcase in verified_cases:
                    for art in vcase.get("artifacts", []):
                        art_src = repo_root / art["path"]
                        art_dest = evidence_dir / art["path"]
                        art_dest.parent.mkdir(parents=True, exist_ok=True)
                        if art_src.resolve() != art_dest.resolve():
                            shutil.copyfile(art_src, art_dest)
            except Exception:
                pass

    return receipt


def find_flutter_bin(explicit: str | None = None) -> str:
    """Finds flutter binary from explicit flag, env var, PATH, or local FVM."""
    if explicit:
        return explicit
    if "FLUTTER_BIN" in os.environ:
        return os.environ["FLUTTER_BIN"]
    which = shutil.which("flutter")
    if which:
        return which
    fvm_candidate = Path.home() / "fvm/versions/3.47.0/bin/flutter"
    if fvm_candidate.exists():
        return str(fvm_candidate)
    return "flutter"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--manifest",
        type=Path,
        default=REPO_ROOT / "tool/i18n_verify/production_acceptance_manifest.json",
        help="Path to production acceptance manifest",
    )
    parser.add_argument(
        "--report",
        type=Path,
        default=None,
        help="Path to existing JSON report (if running offline or in tests)",
    )
    parser.add_argument(
        "--evidence",
        type=Path,
        default=REPO_ROOT / "docs/verification/evidence/l10n_production_receipt.json",
        help="Path to output acceptance receipt",
    )
    parser.add_argument(
        "--runner-exit",
        type=int,
        default=0,
        help="Exit code of the runner process",
    )
    parser.add_argument(
        "--expected-profile",
        default="software-root",
        help="Expected manifest profile (defaults to software-root)",
    )
    parser.add_argument(
        "--flutter",
        default=None,
        help="Path to flutter binary (defaults to auto-detection from PATH / FVM)",
    )
    args = parser.parse_args(argv)

    report_path = args.report
    runner_exit = args.runner_exit
    child_stderr = ""

    # If no report path provided, invoke flutter test
    if report_path is None:
        report_path = REPO_ROOT / "build/reports/l10n_required_report.jsonl"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        flutter_bin = find_flutter_bin(args.flutter)
        suites = [
            "test/l10n/l06_production_root_journey_test.dart",
            "test/l10n/l06_production_accessibility_test.dart",
        ]
        cmd = [
            flutter_bin,
            "test",
            *suites,
            "--reporter",
            "json",
        ]
        print(f"Running required suites: {' '.join(cmd)}")
        with open(report_path, "w", encoding="utf-8") as outfile:
            proc = subprocess.run(cmd, cwd=REPO_ROOT, stdout=outfile, stderr=subprocess.PIPE)
            runner_exit = proc.returncode
            child_stderr = proc.stderr.decode("utf-8", errors="replace") if proc.stderr else ""

    try:
        receipt = verify_l10n_required(
            args.manifest,
            report_path,
            runner_exit=runner_exit,
            evidence_path=args.evidence,
            expected_profile=args.expected_profile,
            child_stderr=child_stderr,
        )
        print(
            f"L10n Required Gate PASSED: {receipt['requiredCasesPassed']}/"
            f"{receipt['requiredCasesTotal']} required cases verified."
        )
        return 0
    except L10nRequiredError as exc:
        print(f"L10n Required Gate FAILED: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
