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
from tool.oracle_guard.assert_no_skips import _parse_events, GuardError


class L10nRequiredError(Exception):
    """Localization required gate rejection."""


def verify_l10n_required(
    manifest_path: Path,
    report_path: Path,
    *,
    runner_exit: int = 0,
    evidence_path: Path | None = None,
    repo_root: Path = REPO_ROOT,
) -> dict:
    """Verifies that the report satisfies all requirements in the manifest."""
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

    required_cases = [c for c in manifest.get("cases", []) if c.get("required") is True]
    if not required_cases:
        raise L10nRequiredError("Manifest contains zero required test cases")

    if not report_path.exists():
        raise L10nRequiredError(f"Report not found: {report_path}")

    report_raw = report_path.read_bytes()
    report_hash = hashlib.sha256(report_raw).hexdigest()
    report_text = report_raw.decode("utf-8-sig", errors="replace")

    try:
        events = _parse_events(report_text)
    except GuardError as exc:
        raise L10nRequiredError(f"Report JSON guard rejected report: {exc}") from exc

    # Parse test starts and completions
    test_id_to_name: dict[int, str] = {}
    test_id_to_outcome: dict[int, dict] = {}
    done_success = False

    for event in events:
        etype = event.get("type")
        if etype == "testStart":
            tinfo = event.get("test")
            if isinstance(tinfo, dict):
                tid = tinfo.get("id")
                tname = tinfo.get("name", "")
                if isinstance(tid, int):
                    test_id_to_name[tid] = tname
        elif etype == "testDone":
            tid = event.get("testID")
            if isinstance(tid, int):
                test_id_to_outcome[tid] = {
                    "result": event.get("result"),
                    "skipped": event.get("skipped", False),
                    "hidden": event.get("hidden", False),
                }
        elif etype == "done":
            if event.get("success") is True:
                done_success = True

    if not done_success:
        raise L10nRequiredError("Report missing successful terminal 'done' event")

    # Match manifest required cases against actual test outcomes
    verified_cases = []
    missing_cases = []
    failed_cases = []
    skipped_cases = []

    for req in required_cases:
        case_id = req.get("caseId")
        qualified_name = req.get("qualifiedTestName", "")
        # Match by caseId tag like "[C01]" or qualifiedTestName
        matched_tid = None
        for tid, name in test_id_to_name.items():
            if f"[{case_id}]" in name or (qualified_name and qualified_name in name):
                matched_tid = tid
                break

        if matched_tid is None:
            missing_cases.append(case_id)
            continue

        outcome = test_id_to_outcome.get(matched_tid)
        if not outcome:
            missing_cases.append(case_id)
            continue

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
            ahash = hashlib.sha256(content).hexdigest()
            artifact_receipts.append({
                "path": artifact_rel,
                "bytes": len(content),
                "sha256": ahash,
            })

        verified_cases.append({
            "caseId": case_id,
            "qualifiedTestName": test_id_to_name.get(matched_tid),
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
        evidence_path.parent.mkdir(parents=True, exist_ok=True)
        evidence_path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")

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
        "--flutter",
        default=None,
        help="Path to flutter binary (defaults to auto-detection from PATH / FVM)",
    )
    args = parser.parse_args(argv)

    report_path = args.report
    runner_exit = args.runner_exit

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

    try:
        receipt = verify_l10n_required(
            args.manifest,
            report_path,
            runner_exit=runner_exit,
            evidence_path=args.evidence,
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
