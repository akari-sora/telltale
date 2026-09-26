#!/usr/bin/env python3
"""Fail-closed runner and verification gate for required localization and accessibility suites.

Validates that all required test cases registered in the production acceptance
manifest are executed, succeed, have zero skips, and produce valid artifacts.
Ensures strict suite identity, lifecycle non-overwriting, manifest schema validation,
PNG chunk/decode verification, process execution context binding, and atomic evidence archiving.
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import zlib

# Import core oracle guard functionality
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO_ROOT))
from tool.oracle_guard.assert_no_skips import (
    _parse_events,
    _require_typed_testid,
    _strict_bool,
    GuardError,
)

SUPPORTED_SCHEMA_VERSIONS = {"1.0.0"}
ALLOWED_PROFILES = {"software-root", "test-profile"}


class L10nRequiredError(Exception):
    """Localization required gate rejection."""


def _strict_json_loads(text: str) -> dict:
    """Parses JSON rejecting any duplicate keys at any nesting level."""
    def _pairs_hook(pairs):
        obj = {}
        for k, v in pairs:
            if k in obj:
                raise L10nRequiredError(f"Duplicate JSON key in manifest: {k!r}")
            obj[k] = v
        return obj
    try:
        return json.loads(text, object_pairs_hook=_pairs_hook)
    except Exception as exc:
        if isinstance(exc, L10nRequiredError):
            raise
        raise L10nRequiredError(f"Malformed manifest JSON: {exc}") from exc


def normalize_suite_path(p: str, repo_root: Path) -> str:
    """Normalizes a suite path to be relative to repo_root where possible."""
    path_obj = Path(p)
    if path_obj.is_absolute():
        try:
            return path_obj.resolve().relative_to(repo_root.resolve()).as_posix()
        except ValueError:
            return path_obj.as_posix()
    return path_obj.as_posix()


def _safe_relpath(p: Path, base: Path) -> str:
    try:
        return str(p.resolve().relative_to(base.resolve()))
    except (ValueError, RuntimeError):
        return str(p)


def validate_and_decode_png(
    data: bytes,
    expected_width: int | None = None,
    expected_height: int | None = None,
) -> tuple[int, int]:
    """Validates PNG magic, chunk structure, CRC32, IDAT decompressibility, IEND and dimensions.

    Rejects bad magic, magic+junk, truncated chunks, CRC mismatches, corrupt IDAT,
    trailing junk after IEND, and zero/negative dimensions.
    """
    if len(data) < 8 or data[:8] != b"\x89PNG\r\n\x1a\n":
        raise L10nRequiredError("Invalid PNG magic header")

    offset = 8
    ihdr_seen = False
    iend_seen = False
    idat_chunks: list[bytes] = []
    width, height = 0, 0

    while offset < len(data):
        if offset + 8 > len(data):
            raise L10nRequiredError("Truncated PNG chunk header")
        length, ctype = struct.unpack(">I4s", data[offset:offset + 8])
        offset += 8
        if offset + length + 4 > len(data):
            raise L10nRequiredError(
                f"Truncated PNG chunk data for {ctype.decode('latin1', errors='replace')}"
            )
        cdata = data[offset:offset + length]
        crc = struct.unpack(">I", data[offset + length:offset + length + 4])[0]
        offset += length + 4

        expected_crc = zlib.crc32(ctype + cdata) & 0xFFFFFFFF
        if crc != expected_crc:
            raise L10nRequiredError(
                f"CRC32 mismatch in PNG chunk {ctype.decode('latin1', errors='replace')}"
            )

        if not ihdr_seen:
            if ctype != b"IHDR":
                raise L10nRequiredError("First chunk in PNG must be IHDR")
            if length != 13:
                raise L10nRequiredError(f"IHDR chunk must be 13 bytes, got {length}")
            width, height, bit_depth, color_type, comp, filt, interlace = struct.unpack(
                ">IIBBBBB", cdata
            )
            if width <= 0 or height <= 0:
                raise L10nRequiredError(f"Invalid PNG dimensions: {width}x{height}")
            if comp != 0 or filt != 0:
                raise L10nRequiredError("Invalid PNG compression or filter method")
            ihdr_seen = True

        if ctype == b"IDAT":
            idat_chunks.append(cdata)
        elif ctype == b"IEND":
            if length != 0:
                raise L10nRequiredError("IEND chunk must have 0 length")
            iend_seen = True
            if offset != len(data):
                raise L10nRequiredError(f"Trailing data after IEND chunk: {len(data) - offset} bytes")
            break

    if not ihdr_seen:
        raise L10nRequiredError("PNG missing IHDR chunk")
    if not iend_seen:
        raise L10nRequiredError("PNG missing IEND chunk")
    if not idat_chunks:
        raise L10nRequiredError("PNG missing IDAT image data")

    try:
        decompressed = zlib.decompress(b"".join(idat_chunks))
    except Exception as exc:
        raise L10nRequiredError(f"Corrupted PNG IDAT compression: {exc}") from exc

    if len(decompressed) == 0:
        raise L10nRequiredError("Decompressed PNG image data is empty")

    if expected_width is not None and width != expected_width:
        raise L10nRequiredError(f"PNG width {width} does not match expected width {expected_width}")
    if expected_height is not None and height != expected_height:
        raise L10nRequiredError(f"PNG height {height} does not match expected height {expected_height}")

    return width, height


def get_git_info(repo_root: Path) -> tuple[str, str]:
    """Returns (commit_sha, tree_sha). Returns ('unknown', 'unknown') if git fails."""
    try:
        commit = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=repo_root, text=True, stderr=subprocess.DEVNULL
        ).strip()
        tree = subprocess.check_output(
            ["git", "rev-parse", "HEAD^{tree}"], cwd=repo_root, text=True, stderr=subprocess.DEVNULL
        ).strip()
        return commit, tree
    except Exception:
        return "unknown", "unknown"


def get_sdk_info(flutter_bin: str, repo_root: Path) -> str:
    """Returns flutter sdk version string or description."""
    try:
        return subprocess.check_output(
            [flutter_bin, "--version", "--machine"], cwd=repo_root, text=True, stderr=subprocess.DEVNULL
        ).strip()
    except Exception:
        return "flutter-unknown"


def verify_l10n_required(
    manifest_path: Path,
    report_path: Path,
    *,
    runner_exit: int = 0,
    evidence_path: Path | None = None,
    bundle_dir: Path | None = None,
    repo_root: Path = REPO_ROOT,
    expected_profile: str | None = None,
    child_stderr: str = "",
    run_id: str | None = None,
    source_sha: str | None = None,
    tree_sha: str | None = None,
    sdk_info: str | None = None,
    argv: list[str] | None = None,
    command: list[str] | None = None,
) -> dict:
    """Verifies that the report satisfies all requirements in the manifest."""
    if run_id is None:
        run_id = f"run_{datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')}_{os.getpid()}"
    try:
        return _verify_l10n_required_inner(
            manifest_path,
            report_path,
            runner_exit=runner_exit,
            evidence_path=evidence_path,
            bundle_dir=bundle_dir,
            repo_root=repo_root,
            expected_profile=expected_profile,
            child_stderr=child_stderr,
            run_id=run_id,
            source_sha=source_sha,
            tree_sha=tree_sha,
            sdk_info=sdk_info,
            argv=argv,
            command=command,
        )
    except Exception as exc:
        if evidence_path:
            failed_receipt = {
                "status": "REJECTED",
                "executionStatus": "EXECUTION_FAIL",
                "reviewStatus": "PENDING_REVIEW",
                "provenanceLevel": "C1A_R2A_VERIFIER_PROVENANCE_ACCEPTED",
                "runId": run_id,
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
    bundle_dir: Path | None = None,
    repo_root: Path = REPO_ROOT,
    expected_profile: str | None = None,
    child_stderr: str = "",
    run_id: str = "",
    source_sha: str | None = None,
    tree_sha: str | None = None,
    sdk_info: str | None = None,
    argv: list[str] | None = None,
    command: list[str] | None = None,
) -> dict:
    if runner_exit != 0:
        raise L10nRequiredError(f"Runner failed with nonzero exit code: {runner_exit}")

    if not manifest_path.exists():
        raise L10nRequiredError(f"Manifest not found: {manifest_path}")

    manifest_raw = manifest_path.read_bytes()
    manifest_hash = hashlib.sha256(manifest_raw).hexdigest()
    manifest_text = manifest_raw.decode("utf-8-sig", errors="replace")

    # Strict JSON parsing rejecting duplicate keys
    manifest = _strict_json_loads(manifest_text)

    # SchemaVersion validation
    schema_version = manifest.get("schemaVersion")
    if not schema_version or not isinstance(schema_version, str) or schema_version not in SUPPORTED_SCHEMA_VERSIONS:
        raise L10nRequiredError(
            f"Unsupported or missing manifest schemaVersion: {schema_version!r} (supported: {sorted(SUPPORTED_SCHEMA_VERSIONS)})"
        )

    # Profile validation
    profile = manifest.get("profile")
    if not profile or not isinstance(profile, str) or not profile.strip():
        raise L10nRequiredError("Manifest profile missing or empty")
    if expected_profile is not None:
        if profile != expected_profile:
            raise L10nRequiredError(
                f"Manifest profile {profile!r} does not match expected profile {expected_profile!r}"
            )
    elif profile not in ALLOWED_PROFILES:
        raise L10nRequiredError(f"Unrecognized manifest profile: {profile}")

    raw_cases = manifest.get("cases")
    if not isinstance(raw_cases, list) or not raw_cases:
        raise L10nRequiredError("Manifest 'cases' field must be a non-empty array")

    required_cases: list[dict] = []
    seen_case_ids: set[str] = set()
    seen_targets: set[tuple[str, str]] = set()

    for c in raw_cases:
        if not isinstance(c, dict):
            raise L10nRequiredError("Manifest case must be a JSON object")
        case_id = c.get("caseId")
        if not case_id or not isinstance(case_id, str):
            raise L10nRequiredError(f"Manifest case missing or invalid string 'caseId': {case_id!r}")
        if case_id in seen_case_ids:
            raise L10nRequiredError(f"Manifest duplicate caseId: {case_id}")
        seen_case_ids.add(case_id)

        req_val = c.get("required")
        if req_val is None or not isinstance(req_val, bool):
            raise L10nRequiredError(
                f"Manifest case {case_id} has invalid non-boolean 'required': {req_val!r} ({type(req_val).__name__})"
            )

        if req_val is True:
            suite_path = c.get("suitePath")
            qualified_name = c.get("qualifiedTestName")
            if not suite_path or not isinstance(suite_path, str) or not suite_path.strip():
                raise L10nRequiredError(f"Required case {case_id} missing non-empty string suitePath")
            if not qualified_name or not isinstance(qualified_name, str) or not qualified_name.strip():
                raise L10nRequiredError(f"Required case {case_id} missing non-empty string qualifiedTestName")
            norm_target = (normalize_suite_path(suite_path, repo_root), qualified_name)
            if norm_target in seen_targets:
                raise L10nRequiredError(f"Manifest duplicate required test target: {norm_target}")
            seen_targets.add(norm_target)
            required_cases.append(c)

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

    # Parse and validate events strictly
    suite_id_to_path: dict[int, str] = {}
    test_id_to_info: dict[int, dict] = {}
    test_id_to_outcome: dict[int, dict] = {}
    started_test_ids: set[int] = set()
    terminal_test_ids: set[int] = set()
    all_failures: list[dict] = []
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
            if not isinstance(sinfo, dict):
                raise L10nRequiredError("Suite event missing suite dictionary")
            sid = sinfo.get("id")
            if sid is None or isinstance(sid, bool) or not isinstance(sid, int):
                raise L10nRequiredError(f"Suite event id must be integer: {sid!r}")
            if sid in suite_id_to_path:
                raise L10nRequiredError(f"Duplicate suite definition for suite ID {sid}")
            spath = sinfo.get("path")
            if not spath or not isinstance(spath, str) or not spath.strip():
                raise L10nRequiredError(f"Suite ID {sid} missing or empty path: {spath!r}")
            suite_id_to_path[sid] = normalize_suite_path(spath, repo_root)

        elif etype == "testStart":
            tinfo = event.get("test")
            if not isinstance(tinfo, dict):
                raise L10nRequiredError("testStart missing test object")
            raw_id = tinfo.get("id")
            if raw_id is None or isinstance(raw_id, bool) or not isinstance(raw_id, int):
                raise L10nRequiredError(f"testStart test ID must be integer: {raw_id!r}")
            if raw_id in started_test_ids or raw_id in test_id_to_info:
                raise L10nRequiredError(f"Duplicate testStart for test ID {raw_id}")
            if raw_id in terminal_test_ids:
                raise L10nRequiredError(f"testStart for already terminated test ID {raw_id}")

            tname = tinfo.get("name")
            if not tname or not isinstance(tname, str):
                raise L10nRequiredError(f"testStart test ID {raw_id} missing or invalid test name")

            sid = tinfo.get("suiteID")
            if sid is None or isinstance(sid, bool) or not isinstance(sid, int):
                raise L10nRequiredError(f"testStart test ID {raw_id} missing or invalid integer suiteID: {sid!r}")
            if sid not in suite_id_to_path:
                raise L10nRequiredError(f"testStart test ID {raw_id} references unknown suiteID {sid}")
            spath = suite_id_to_path[sid]

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
                raise L10nRequiredError(f"testDone testID must be integer: {tid!r}")
            if tid not in started_test_ids:
                raise L10nRequiredError(f"testDone testID={tid} without preceding testStart")
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
            if not isinstance(result, str):
                raise L10nRequiredError(f"testDone testID={tid} result must be string: {result!r}")

            test_id_to_outcome[tid] = {
                "result": result,
                "hidden": hidden,
                "skipped": skipped,
            }

            if result != "success" and not skipped:
                t_info = test_id_to_info.get(tid, {})
                all_failures.append({
                    "testID": tid,
                    "name": t_info.get("name", "unknown"),
                    "suite": t_info.get("suite_path", "unknown"),
                    "result": result,
                })

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
            if all_failures:
                raise L10nRequiredError(f"Report contains failed tests: {all_failures}")
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
        case_id = req["caseId"]
        expected_norm_suite = normalize_suite_path(req["suitePath"], repo_root)
        expected_name = req["qualifiedTestName"]

        matched_tid = None
        for tid, tinfo in test_id_to_info.items():
            t_suite = tinfo.get("suite_path", "")
            t_name = tinfo.get("name", "")
            # Strict suite matching: no fallback to empty/missing suite
            if bool(t_suite) and t_suite == expected_norm_suite and t_name == expected_name:
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
            dim_str = None
            if artifact_rel.endswith(".png"):
                w, h = validate_and_decode_png(content)
                dim_str = f"{w}x{h}"

            ahash = hashlib.sha256(content).hexdigest()
            art_entry = {
                "path": artifact_rel,
                "bytes": len(content),
                "sha256": ahash,
            }
            if dim_str:
                art_entry["dimensions"] = dim_str
            artifact_receipts.append(art_entry)

        verified_cases.append({
            "caseId": case_id,
            "qualifiedTestName": test_id_to_info[matched_tid]["name"],
            "suitePath": test_id_to_info[matched_tid]["suite_path"],
            "result": "success",
            "artifacts": artifact_receipts,
        })

    if missing_cases:
        raise L10nRequiredError(f"Required cases missing from report: {missing_cases}")
    if skipped_cases:
        raise L10nRequiredError(f"Required cases were skipped: {skipped_cases}")
    if failed_cases:
        raise L10nRequiredError(f"Required cases failed: {failed_cases}")

    # Determine target bundle directory for complete evidence archive
    target_bundle_dir: Path | None = None
    if bundle_dir is not None:
        target_bundle_dir = bundle_dir
    elif evidence_path is not None:
        parent_str = str(evidence_path.parent)
        if "ci-artifacts" in parent_str or evidence_path.parent.name not in ("evidence", "docs"):
            target_bundle_dir = evidence_path.parent / run_id

    # Complete Atomic Evidence Archive before writing ACCEPTED receipt
    if target_bundle_dir is not None:
        try:
            target_bundle_dir.mkdir(parents=True, exist_ok=True)
            artifacts_archive_dir = target_bundle_dir / "artifacts"
            artifacts_archive_dir.mkdir(parents=True, exist_ok=True)

            # 1. manifest.json
            dest_manifest = target_bundle_dir / "manifest.json"
            if manifest_path.resolve() != dest_manifest.resolve():
                shutil.copyfile(manifest_path, dest_manifest)
            if hashlib.sha256(dest_manifest.read_bytes()).hexdigest() != manifest_hash:
                raise L10nRequiredError("Archived manifest hash mismatch")

            # 2. command.json
            command_info = {
                "command": command or [],
                "cwd": str(repo_root),
                "timestampUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            }
            (target_bundle_dir / "command.json").write_text(
                json.dumps(command_info, indent=2) + "\n", encoding="utf-8"
            )

            # 3. child.exit
            (target_bundle_dir / "child.exit").write_text(f"{runner_exit}\n", encoding="utf-8")

            # 4. child.stdout.jsonl
            dest_report = target_bundle_dir / "child.stdout.jsonl"
            if report_path.resolve() != dest_report.resolve():
                shutil.copyfile(report_path, dest_report)
            if hashlib.sha256(dest_report.read_bytes()).hexdigest() != report_hash:
                raise L10nRequiredError("Archived report hash mismatch")

            # 5. child.stderr.txt
            stderr_path = target_bundle_dir / "child.stderr.txt"
            stderr_path.write_text(child_stderr, encoding="utf-8")
            stderr_hash = hashlib.sha256(stderr_path.read_bytes()).hexdigest()

            # 6. case-observations.json
            observations = []
            for tid, tinfo in test_id_to_info.items():
                tout = test_id_to_outcome.get(tid, {})
                observations.append({
                    "testID": tid,
                    "name": tinfo.get("name"),
                    "suite": tinfo.get("suite_path"),
                    "result": tout.get("result"),
                    "hidden": tout.get("hidden"),
                    "skipped": tout.get("skipped"),
                })
            (target_bundle_dir / "case-observations.json").write_text(
                json.dumps(observations, indent=2) + "\n", encoding="utf-8"
            )

            # 7. artifacts and artifacts.sha256
            art_sha_lines = []
            for vcase in verified_cases:
                for art in vcase.get("artifacts", []):
                    art_src = repo_root / art["path"]
                    art_dest = artifacts_archive_dir / Path(art["path"]).name
                    if art_src.resolve() != art_dest.resolve():
                        shutil.copyfile(art_src, art_dest)
                    art_bytes = art_dest.read_bytes()
                    if hashlib.sha256(art_bytes).hexdigest() != art["sha256"]:
                        raise L10nRequiredError(f"Archived artifact hash mismatch: {art['path']}")
                    if art["path"].endswith(".png"):
                        validate_and_decode_png(art_bytes)
                    art_sha_lines.append(f"{art['sha256']}  {art_dest.name}")

            (target_bundle_dir / "artifacts.sha256").write_text(
                "\n".join(art_sha_lines) + ("\n" if art_sha_lines else ""), encoding="utf-8"
            )

            # 8. attempt.json
            attempt_info = {
                "attempt": 1,
                "runId": run_id,
                "runnerExit": runner_exit,
                "status": "PASS",
                "timestampUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            }
            (target_bundle_dir / "attempt.json").write_text(
                json.dumps(attempt_info, indent=2) + "\n", encoding="utf-8"
            )

            # 9. run-context.json
            run_context = {
                "runId": run_id,
                "profile": profile,
                "provenanceLevel": "C1A_R2A_VERIFIER_PROVENANCE_ACCEPTED",
                "sourceSha": source_sha or "unknown",
                "treeSha": tree_sha or "unknown",
                "sdk": sdk_info or "unknown",
                "argv": argv or sys.argv,
                "manifestHash": manifest_hash,
                "reportHash": report_hash,
                "stderrHash": stderr_hash,
                "childExit": runner_exit,
                "timestampUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            }
            (target_bundle_dir / "run-context.json").write_text(
                json.dumps(run_context, indent=2) + "\n", encoding="utf-8"
            )

            # 10. verification.json
            verification_summary = {
                "executionStatus": "EXECUTION_PASS",
                "reviewStatus": "PENDING_REVIEW",
                "provenanceLevel": "C1A_R2A_VERIFIER_PROVENANCE_ACCEPTED",
                "runId": run_id,
                "manifestHash": manifest_hash,
                "reportHash": report_hash,
                "requiredCasesTotal": len(required_cases),
                "requiredCasesPassed": len(verified_cases),
                "cases": verified_cases,
                "timestampUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            }
            (target_bundle_dir / "verification.json").write_text(
                json.dumps(verification_summary, indent=2) + "\n", encoding="utf-8"
            )

        except Exception as exc:
            raise L10nRequiredError(f"Evidence archive failed: {exc}") from exc

    receipt = {
        "status": "ACCEPTED",
        "executionStatus": "EXECUTION_PASS",
        "reviewStatus": "PENDING_REVIEW",
        "provenanceLevel": "C1A_R2A_VERIFIER_PROVENANCE_ACCEPTED",
        "runId": run_id,
        "profile": manifest.get("profile", "software-root"),
        "timestampUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "sourceSha": source_sha or "unknown",
        "treeSha": tree_sha or "unknown",
        "manifestHash": manifest_hash,
        "reportHash": report_hash,
        "requiredCasesTotal": len(required_cases),
        "requiredCasesPassed": len(verified_cases),
        "cases": verified_cases,
        "nativeResiduals": manifest.get("nativeResiduals", []),
    }
    if target_bundle_dir is not None:
        receipt["bundleDir"] = _safe_relpath(target_bundle_dir, repo_root)

    if evidence_path:
        evidence_dir = evidence_path.parent
        evidence_dir.mkdir(parents=True, exist_ok=True)
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
        "--output-dir",
        type=Path,
        default=None,
        help="Directory to store evidence bundle",
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

    run_id = f"run_{datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')}_{os.getpid()}"
    source_sha, tree_sha = get_git_info(REPO_ROOT)
    flutter_bin = find_flutter_bin(args.flutter)
    sdk_info = get_sdk_info(flutter_bin, REPO_ROOT)

    report_path = args.report
    runner_exit = args.runner_exit
    child_stderr = ""
    cmd: list[str] = []

    # If no report path provided, invoke flutter test
    if report_path is None:
        report_path = REPO_ROOT / "build/reports/l10n_required_report.jsonl"
        report_path.parent.mkdir(parents=True, exist_ok=True)

        # Cleanup stale PNGs before new run
        a11y_reports = REPO_ROOT / "build/reports/l10n_accessibility"
        if a11y_reports.exists():
            for p in a11y_reports.glob("*.png"):
                try:
                    p.unlink()
                except OSError:
                    pass

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
        try:
            with open(report_path, "w", encoding="utf-8") as outfile:
                proc = subprocess.run(cmd, cwd=REPO_ROOT, stdout=outfile, stderr=subprocess.PIPE)
                runner_exit = proc.returncode
                child_stderr = proc.stderr.decode("utf-8", errors="replace") if proc.stderr else ""
        except Exception as spawn_exc:
            runner_exit = 1
            child_stderr = f"Failed to spawn runner process: {spawn_exc}"
            failed_receipt = {
                "status": "REJECTED",
                "executionStatus": "EXECUTION_FAIL",
                "reviewStatus": "PENDING_REVIEW",
                "provenanceLevel": "C1A_R2A_VERIFIER_PROVENANCE_ACCEPTED",
                "runId": run_id,
                "error": f"Child spawn failed: {spawn_exc}",
                "timestampUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            }
            if args.evidence:
                try:
                    args.evidence.parent.mkdir(parents=True, exist_ok=True)
                    args.evidence.write_text(json.dumps(failed_receipt, indent=2) + "\n", encoding="utf-8")
                except Exception:
                    pass
            print(f"L10n Required Gate FAILED: {spawn_exc}", file=sys.stderr)
            return 1

    bundle_dir: Path | None = None
    if args.output_dir:
        bundle_dir = args.output_dir / run_id
    elif args.evidence and ("ci-artifacts" in str(args.evidence) or args.evidence.parent.name not in ("evidence", "docs")):
        bundle_dir = args.evidence.parent / run_id

    try:
        receipt = verify_l10n_required(
            args.manifest,
            report_path,
            runner_exit=runner_exit,
            evidence_path=args.evidence,
            bundle_dir=bundle_dir,
            expected_profile=args.expected_profile,
            child_stderr=child_stderr,
            run_id=run_id,
            source_sha=source_sha,
            tree_sha=tree_sha,
            sdk_info=sdk_info,
            argv=sys.argv if argv is None else argv,
            command=cmd,
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
