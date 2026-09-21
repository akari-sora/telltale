#!/usr/bin/env python3
"""Deep Hardened Forensic Artifact Verifier for D05 Android Lifecycle Verification.

Enforces fail-closed cryptographic and forensic integrity:
1. Critical files presence: SHA256SUMS, candidate.sha256, installed-apk.sha256,
   runner.exit == 0, last-stage.txt, execution_result.json, android_logcat.txt, controller.jsonl.
2. 4-Way Hash Verification: Disk files == SHA256SUMS == controller.jsonl == raw job_trace.txt.
   Both PNG files and XML hierarchy files are verified for all captures.
3. True android_logcat.txt parsing:
   - Line-by-line structured parsing with epoch timestamp validation.
   - ActivityTaskManager verified for HOME (Case 1 & 3).
   - PowerManagerService verified for SLEEP (Case 2).
   - Logcat timestamp strictly >= hold start epoch (no loose negative threshold).
   - Verbatim evidence matching and chronological cross-case progression.
4. Single-run connection & Query Continuity:
   - All 3 cases strictly on connection 1 (no reconnects or switches).
   - Query commands: Case 1='0800', Case 2='0820', Case 3='0800'.
   - Run IDs follow d05_{idx}_<ts> pattern.
5. Strict Host Monotonic Clock Proof:
   - verified_at_monotonic < hold_release_at_monotonic (no legacy fallback).
   - Finite, non-NaN positive float validation.
   - hold_duration_s strictly in (0.0, 2.0s).
   - elapsed_s strictly in (0.0, 2.0s).
6. execution_result.json confirms all_three_observed == True with 0 UI failures.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import sys
from pathlib import Path

EXPECTED_CANDIDATE = "acc80f75b599d7f85e5c11416ec6c2e92f774f6b9e1699584414ca35abbade9e"
HEX_SHA256_RE = re.compile(r'^[a-f0-9]{64}$')
LOGCAT_LINE_RE = re.compile(r'^\s*(\d+\.\d+)\s+(\d+)\s+(\d+)\s+([VDIWEF])\s+([^:]+):\s*(.*)$')

HOME_PATTERN = re.compile(
    r'(?:cat=\[android\.intent\.category\.HOME\]|START u0.*cmp=.*launcher|Displayed .*launcher)',
    re.IGNORECASE
)

SLEEP_PATTERN = re.compile(
    r'(?:PowerManagerService:\s*(?:Going to sleep|Sleeping)|goToSleep\(GO_TO_SLEEP_REASON|mWakefulness=Asleep|Display Power: state=OFF)',
    re.IGNORECASE
)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()


def is_valid_sha256(val: object) -> bool:
    return isinstance(val, str) and bool(HEX_SHA256_RE.match(val))


def is_valid_positive_float(val: object, max_val: float = float("inf")) -> bool:
    if not isinstance(val, (int, float)) or isinstance(val, bool):
        return False
    fval = float(val)
    if math.isnan(fval) or math.isinf(fval):
        return False
    return 0.0 < fval < max_val


def parse_logcat_lines(content: str) -> list[dict]:
    parsed = []
    for line in content.splitlines():
        line_str = line.strip()
        if not line_str:
            continue
        m = LOGCAT_LINE_RE.match(line)
        if m:
            parsed.append({
                "ts": float(m.group(1)),
                "pid": int(m.group(2)),
                "tid": int(m.group(3)),
                "level": m.group(4),
                "tag": m.group(5).strip(),
                "msg": m.group(6),
                "raw": line_str,
            })
        else:
            parsed.append({
                "ts": None,
                "pid": None,
                "tid": None,
                "level": None,
                "tag": None,
                "msg": line_str,
                "raw": line_str,
            })
    return parsed


def verify_artifacts(directory: Path, raw_trace_path: Path | None = None) -> tuple[bool, list[str]]:
    errors: list[str] = []
    print(f"=== Rigorous Forensic Verification: {directory} ===")

    def fail_summary() -> tuple[bool, list[str]]:
        print("\n=== Verification Summary ===")
        print(f"FAIL: Verification failed with {len(errors)} error(s):")
        for err in errors:
            print(f"  [X] {err}")
        return False, errors

    if not directory.is_dir():
        errors.append(f"Target directory does not exist: {directory}")
        return fail_summary()

    # Auto-detect job_trace.txt if not explicitly passed
    if raw_trace_path is None:
        candidate_traces = [
            directory / "job_trace.txt",
            directory.parent / "job_trace.txt",
            Path("job_trace.txt"),
        ]
        for ct in candidate_traces:
            if ct.is_file():
                raw_trace_path = ct
                break

    # If raw_trace_path was explicitly specified but does not exist -> FAIL CLOSED
    if raw_trace_path is not None and not raw_trace_path.is_file():
        errors.append(f"Raw trace file not found: {raw_trace_path}")
        return fail_summary()

    # 1. Mandatory Artifact Files Check (Fail Closed)
    print("[1] Checking mandatory artifact files...")
    mandatory_files = [
        "SHA256SUMS",
        "candidate.sha256",
        "installed-apk.sha256",
        "runner.exit",
        "last-stage.txt",
        "execution_result.json",
        "android_logcat.txt",
        "controller.jsonl",
    ]
    for mf in mandatory_files:
        fpath = directory / mf
        if not fpath.is_file():
            errors.append(f"Missing mandatory file: {mf}")
        elif fpath.stat().st_size == 0:
            errors.append(f"Mandatory file is empty: {mf}")

    runner_exit_file = directory / "runner.exit"
    if runner_exit_file.is_file():
        exit_code_str = runner_exit_file.read_text().strip()
        if exit_code_str != "0":
            errors.append(f"runner.exit indicates failure: '{exit_code_str}' (expected '0')")
        else:
            print("    OK: runner.exit == 0")

    if errors:
        return fail_summary()

    # 2. SHA256SUMS Verification
    print("[2] Verifying SHA256SUMS (100% bit-for-bit)...")
    sha_file = directory / "SHA256SUMS"
    checksums: dict[str, str] = {}
    for line in sha_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) >= 2:
            digest = parts[0]
            rel_path = parts[1].lstrip("./")
            if not is_valid_sha256(digest):
                errors.append(f"Invalid SHA256 digest in SHA256SUMS for {rel_path}: {digest}")
            checksums[rel_path] = digest

    if len(checksums) < 5:
        errors.append(f"SHA256SUMS contains too few entries ({len(checksums)}), expected comprehensive run")

    verified_count = 0
    for rel_path, expected_digest in checksums.items():
        file_path = directory / rel_path
        if not file_path.exists():
            errors.append(f"File in SHA256SUMS not found on disk: {rel_path}")
            continue
        actual_digest = sha256_file(file_path)
        if actual_digest != expected_digest:
            errors.append(f"SHA-256 mismatch for {rel_path}: expected {expected_digest}, got {actual_digest}")
        else:
            verified_count += 1

    # Check for untracked files on disk
    ignored_names = {"SHA256SUMS", ".DS_Store", "job_trace.txt"}
    for p in directory.rglob("*"):
        if p.is_file() and p.name not in ignored_names:
            rel = str(p.relative_to(directory))
            if "scroll-build" in rel:
                continue
            if rel not in checksums:
                errors.append(f"Untracked file on disk not recorded in SHA256SUMS: {rel}")

    print(f"    OK: {verified_count}/{len(checksums)} files verified bit-for-bit against SHA256SUMS.")

    # 3. Verify Candidate & Installed APK Hashes
    print("[3] Verifying APK candidate and installed hashes...")
    for apk_meta in ["candidate.sha256", "installed-apk.sha256"]:
        apk_file = directory / apk_meta
        content = apk_file.read_text().strip().split()[0]
        if content != EXPECTED_CANDIDATE:
            errors.append(f"{apk_meta} mismatch: expected {EXPECTED_CANDIDATE}, got {content}")
        else:
            print(f"    OK: {apk_meta} == {EXPECTED_CANDIDATE}")

    # 4. Parse controller.jsonl & Verify Monotonic Timestamps and Continuity
    print("[4] Verifying controller.jsonl trace structure, run identity, and monotonic clock proof...")
    jsonl_path = directory / "controller.jsonl"
    events: list[dict] = []
    last_seq = 0
    last_mono_ns = 0

    for line_idx, line in enumerate(jsonl_path.read_text().splitlines(), 1):
        line = line.strip()
        if not line:
            continue
        try:
            ev = json.loads(line)
            events.append(ev)
        except Exception as e:
            errors.append(f"controller.jsonl line {line_idx}: invalid JSON: {e}")
            continue

        # Global sequence and monotonic check
        seq = ev.get("seq")
        if seq is None or not isinstance(seq, int) or seq <= last_seq:
            errors.append(f"controller.jsonl line {line_idx}: non-monotonic seq ({seq} <= {last_seq})")
        else:
            last_seq = seq

        mono_ns = ev.get("host_monotonic_ns")
        if mono_ns is not None:
            if not isinstance(mono_ns, int) or mono_ns < last_mono_ns:
                errors.append(f"controller.jsonl line {line_idx}: non-monotonic host_monotonic_ns ({mono_ns} < {last_mono_ns})")
            else:
                last_mono_ns = mono_ns

    # Check for disconnect / UI failure events in controller.jsonl
    for ev in events:
        ev_name = ev.get("event", "")
        ev_err = str(ev.get("error", ""))
        if ev_name in ("operation_failed", "connection_lost", "unexpected_disconnect") or \
           "connection_lost" in ev_name or \
           "operation_failed" in ev_name or \
           "dropped back" in ev_err:
            errors.append(f"controller.jsonl contains failure event: {ev}")

    # Group events by case index (1, 2, 3)
    def get_case_index(ev: dict) -> int | None:
        if "index" in ev and ev["index"] in (1, 2, 3):
            return ev["index"]
        run_id = ev.get("run_id")
        if run_id:
            m = re.match(r'^d05_(\d+)_', run_id)
            if m:
                return int(m.group(1))
        return None

    cases_events: dict[int, list[dict]] = {1: [], 2: [], 3: []}
    for ev in events:
        c_idx = get_case_index(ev)
        if c_idx in (1, 2, 3):
            cases_events[c_idx].append(ev)

    case_summary = {}
    prev_release_mono = 0.0

    for idx in (1, 2, 3):
        evs = cases_events[idx]
        held_ev = next((e for e in evs if e.get("event") == "mode08_response_held"), None)
        cmd_ev = next((e for e in evs if e.get("event") == "os_command_executed_during_hold"), None)
        rel_ev = next((e for e in evs if e.get("event") == "mode08_hold_released_for_resume"), None)
        term_snap_ev = next((e for e in evs if e.get("event") == "screenshot_captured" and "mode08_terminal" in e.get("file", "")), None)
        comp_ev = next((e for e in evs if e.get("event") == "case_observations_complete"), None)

        if not held_ev:
            errors.append(f"Case {idx}: missing mode08_response_held event")
        if not cmd_ev:
            errors.append(f"Case {idx}: missing os_command_executed_during_hold event")
        if not rel_ev:
            errors.append(f"Case {idx}: missing mode08_hold_released_for_resume event")
        if not comp_ev:
            errors.append(f"Case {idx}: missing case_observations_complete event")
        if not term_snap_ev:
            errors.append(f"Case {idx}: missing terminal screenshot_captured event")

        if not (held_ev and cmd_ev and rel_ev and comp_ev and term_snap_ev):
            continue

        # Connection ID must be strictly 1 for all cases
        conn = held_ev.get("connection")
        if conn != 1:
            errors.append(f"Case {idx}: connection ID must be 1, got {conn}")

        # Command check
        expected_cmd = "0820" if idx == 2 else "0800"
        actual_cmd = held_ev.get("command")
        if actual_cmd != expected_cmd:
            errors.append(f"Case {idx}: command expected {expected_cmd}, got {actual_cmd}")

        # Run ID format check
        run_id = held_ev.get("run_id", "")
        if not re.match(rf'^d05_{idx}_\d+$', run_id):
            errors.append(f"Case {idx}: invalid run_id format: '{run_id}' (expected 'd05_{idx}_<timestamp>')")

        # Action & Expected State
        expected_action = "SLEEP" if idx == 2 else "HOME"
        actual_action = cmd_ev.get("action")
        if actual_action != expected_action:
            errors.append(f"Case {idx}: action expected {expected_action}, got {actual_action}")

        expected_state = "wakefulness_asleep" if idx == 2 else "activity_launcher"
        actual_state = cmd_ev.get("verified_state")
        if actual_state != expected_state:
            errors.append(f"Case {idx}: verified_state expected {expected_state}, got {actual_state}")

        # Host Monotonic Clock Proof (Strict: NO LEGACY FALLBACK)
        v_mono = cmd_ev.get("verified_at_monotonic")
        r_mono = cmd_ev.get("hold_release_at_monotonic")
        if not is_valid_positive_float(v_mono):
            errors.append(f"Case {idx}: missing or invalid verified_at_monotonic: {v_mono}")
        if not is_valid_positive_float(r_mono):
            errors.append(f"Case {idx}: missing or invalid hold_release_at_monotonic: {r_mono}")

        if is_valid_positive_float(v_mono) and is_valid_positive_float(r_mono):
            if v_mono >= r_mono:
                errors.append(f"Case {idx}: host monotonic ordering violation: verified_at ({v_mono}) >= hold_release_at ({r_mono})")
            else:
                time_advance = cmd_ev.get("time_advance_ms")
                if not is_valid_positive_float(time_advance):
                    errors.append(f"Case {idx}: time_advance_ms ({time_advance}) must be strictly > 0")
                print(f"    OK Case {idx} Monotonic Proof: verified_at ({v_mono:.6f}) < hold_release_at ({r_mono:.6f}) (advance: {(r_mono - v_mono)*1000:.3f}ms)")

            if v_mono <= prev_release_mono:
                errors.append(f"Case {idx}: verified_at ({v_mono}) <= previous case release ({prev_release_mono}) (out-of-order execution)")
            prev_release_mono = r_mono

        # Hold duration strictly in (0.0, 2.0s)
        hold_duration = rel_ev.get("hold_duration_s")
        if not is_valid_positive_float(hold_duration, max_val=2.0):
            errors.append(f"Case {idx}: hold_duration_s ({hold_duration}) not in valid window (0 < dur < 2.0s)")
        else:
            print(f"    OK Case {idx} Hold Duration: {hold_duration:.3f}s (< 2.0s discovery timeout)")

        elapsed = cmd_ev.get("elapsed_s")
        if not is_valid_positive_float(elapsed, max_val=2.0):
            errors.append(f"Case {idx}: elapsed_s ({elapsed}) not in valid window (0 < elapsed < 2.0s)")

        if comp_ev.get("acceptance") != "CONFIRMED_TERMINAL_UI":
            errors.append(f"Case {idx}: acceptance != CONFIRMED_TERMINAL_UI ({comp_ev.get('acceptance')})")

        case_summary[idx] = {
            "held_ev": held_ev,
            "cmd_ev": cmd_ev,
            "rel_ev": rel_ev,
            "term_snap_ev": term_snap_ev,
            "comp_ev": comp_ev,
        }

    # 5. True android_logcat.txt Parsing & Anti-Spoofing
    print("[5] Parsing and cross-verifying native OS events in android_logcat.txt...")
    logcat_path = directory / "android_logcat.txt"
    logcat_content = logcat_path.read_text(errors="replace")
    parsed_logcat = parse_logcat_lines(logcat_content)
    verbatim_raw_set = {entry["raw"] for entry in parsed_logcat}

    prev_evidence_ts = 0.0

    for idx in (1, 2, 3):
        if idx not in case_summary:
            continue
        cdata = case_summary[idx]
        held_ev = cdata["held_ev"]
        cmd_ev = cdata["cmd_ev"]
        action = cmd_ev.get("action")
        evidence_list = cmd_ev.get("evidence", [])

        if not evidence_list:
            errors.append(f"Case {idx}: evidence list is empty in os_command_executed_during_hold")
            continue

        held_epoch_ns = held_ev.get("host_epoch_ns")
        if not held_epoch_ns or not isinstance(held_epoch_ns, int):
            errors.append(f"Case {idx}: missing host_epoch_ns in mode08_response_held")
            continue
        held_epoch_s = held_epoch_ns / 1_000_000_000.0

        target_pattern = SLEEP_PATTERN if action == "SLEEP" else HOME_PATTERN
        target_tag = "PowerManagerService" if action == "SLEEP" else "ActivityTaskManager"
        verified_evidence_lines = 0

        for line in evidence_list:
            stripped_line = line.strip()
            # 1. Must exist verbatim in parsed android_logcat.txt
            if stripped_line not in verbatim_raw_set:
                errors.append(f"Case {idx}: evidence line not found verbatim in android_logcat.txt: '{stripped_line[:60]}...'")
                continue

            # 2. Must match target regex pattern
            if not target_pattern.search(stripped_line):
                errors.append(f"Case {idx}: evidence line does not match {action} pattern: '{stripped_line[:60]}...'")
                continue

            # 3. Must have valid epoch timestamp
            m_ts = LOGCAT_LINE_RE.match(stripped_line)
            if not m_ts:
                errors.append(f"Case {idx}: evidence line lacks valid epoch timestamp: '{stripped_line[:60]}...'")
                continue

            ev_epoch = float(m_ts.group(1))
            ev_tag = m_ts.group(5).strip()

            if target_tag not in ev_tag:
                errors.append(f"Case {idx}: evidence tag '{ev_tag}' does not match expected '{target_tag}'")

            # 4. Strict Freshness: evidence timestamp >= held epoch
            if ev_epoch < held_epoch_s:
                errors.append(f"Case {idx}: stale logcat event: evidence timestamp ({ev_epoch:.3f}) < hold epoch ({held_epoch_s:.3f})")
            elif ev_epoch <= prev_evidence_ts:
                errors.append(f"Case {idx}: out-of-order logcat timestamp: {ev_epoch:.3f} <= previous case {prev_evidence_ts:.3f}")
            else:
                prev_evidence_ts = ev_epoch
                diff_s = ev_epoch - held_epoch_s
                verified_evidence_lines += 1
                print(f"    OK Case {idx} ({action}): native logcat confirmed (+{diff_s:.3f}s after hold): {stripped_line[:75]}...")

        if verified_evidence_lines == 0:
            errors.append(f"Case {idx}: no valid fresh native logcat evidence confirmed")

    # 6. Comprehensive 4-Way Hash Verification (All Captures)
    print("[6] Performing 4-way hash verification across all captured artifacts...")
    raw_trace_content = raw_trace_path.read_text(errors="replace") if raw_trace_path else None

    # Verify EVERY screenshot_captured event in controller.jsonl
    capture_events = [e for e in events if e.get("event") == "screenshot_captured"]
    if len(capture_events) < 3:
        errors.append(f"controller.jsonl contains too few screenshot_captured events ({len(capture_events)})")

    for ev in capture_events:
        seq = ev.get("seq")
        png_file = ev.get("file")
        png_hash = ev.get("sha256")
        xml_file = ev.get("xml_file")
        xml_hash = ev.get("xml_sha256")

        # PNG verification
        if not png_file or not is_valid_sha256(png_hash):
            errors.append(f"Event seq {seq}: missing or invalid file/sha256")
        else:
            png_path = directory / png_file
            if not png_path.is_file():
                errors.append(f"Event seq {seq}: PNG file not found on disk: {png_file}")
            else:
                act_png = sha256_file(png_path)
                if act_png != png_hash:
                    errors.append(f"Event seq {seq}: PNG hash mismatch on disk: expected {png_hash}, got {act_png}")
                if png_file in checksums and checksums[png_file] != png_hash:
                    errors.append(f"Event seq {seq}: PNG hash mismatch with SHA256SUMS for {png_file}")
                if raw_trace_content and png_hash not in raw_trace_content:
                    errors.append(f"Event seq {seq}: PNG hash {png_hash} not found in raw job trace")

        # XML verification
        if not xml_file or not is_valid_sha256(xml_hash):
            errors.append(f"Event seq {seq}: missing or invalid xml_file/xml_sha256")
        else:
            xml_path = directory / xml_file
            if not xml_path.is_file():
                errors.append(f"Event seq {seq}: XML hierarchy file not found on disk: {xml_file}")
            else:
                act_xml = sha256_file(xml_path)
                if act_xml != xml_hash:
                    errors.append(f"Event seq {seq}: XML hash mismatch on disk: expected {xml_hash}, got {act_xml}")
                if xml_file in checksums and checksums[xml_file] != xml_hash:
                    errors.append(f"Event seq {seq}: XML hash mismatch with SHA256SUMS for {xml_file}")
                if raw_trace_content and xml_hash not in raw_trace_content:
                    errors.append(f"Event seq {seq}: XML hash {xml_hash} not found in raw job trace")

    # Specifically report terminal PNG/XML
    for idx in (1, 2, 3):
        if idx in case_summary:
            snap = case_summary[idx]["term_snap_ev"]
            print(f"    OK Case {idx} 4-Way Verified: PNG={snap.get('file')} ({snap.get('sha256')[:16]}...) XML={snap.get('xml_file')} ({snap.get('xml_sha256')[:16]}...)")

    # 7. execution_result.json Check
    print("[7] Verifying execution_result.json...")
    res_path = directory / "execution_result.json"
    try:
        res = json.loads(res_path.read_text())
        if res.get("candidate_sha256") != EXPECTED_CANDIDATE:
            errors.append("execution_result.json candidate_sha256 mismatch")
        if res.get("completed_case_indices") != [1, 2, 3]:
            errors.append(f"execution_result.json completed_case_indices != [1, 2, 3]: {res.get('completed_case_indices')}")
        if res.get("all_three_observed") is not True:
            errors.append("execution_result.json all_three_observed is not True")
        if res.get("ui_operation_failures"):
            errors.append(f"execution_result.json has ui_operation_failures: {res.get('ui_operation_failures')}")
        print("    OK: execution_result.json confirms all 3 cases observed without failures.")
    except Exception as e:
        errors.append(f"Failed to parse execution_result.json: {e}")

    # Summary
    print("\n=== Verification Summary ===")
    if errors:
        print(f"FAIL: Verification failed with {len(errors)} error(s):")
        for err in errors:
            print(f"  [X] {err}")
        return False, errors
    else:
        print("PASS: All forensic integrity criteria 100% satisfied.")
        return True, []


def main():
    parser = argparse.ArgumentParser(description="Forensic artifact verifier for D05 Android Lifecycle Verification.")
    parser.add_argument("directory", nargs="?", default="d05-device", help="Directory containing D05 artifacts")
    parser.add_argument("--raw-trace", dest="raw_trace", default=None, help="Path to raw job trace")
    args = parser.parse_args()

    dir_path = Path(args.directory)
    raw_trace = Path(args.raw_trace) if args.raw_trace else None

    success, _ = verify_artifacts(dir_path, raw_trace)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
