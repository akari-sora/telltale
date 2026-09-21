#!/usr/bin/env python3
"""Rigorous fail-closed forensic artifact verifier for D05 Android Lifecycle Verification.

Verifies with zero tolerance for missing files or legacy formats:
1. Critical files existence: SHA256SUMS, candidate.sha256, installed-apk.sha256,
   runner.exit == 0, last-stage.txt, execution_result.json, android_logcat.txt, controller.jsonl.
2. 100% bit-for-bit SHA-256 integrity of all files listed in SHA256SUMS.
3. Candidate and installed APK SHA-256 match pinned candidate hash.
4. Native OS lifecycle proof from android_logcat.txt:
   - All evidence lines recorded in controller.jsonl exist verbatim in android_logcat.txt.
   - All evidence lines carry a valid epoch timestamp strictly greater than the hold dispatch epoch.
   - Correct native markers matched for HOME (Launcher) and SLEEP (PowerManagerService / Going to sleep).
5. Terminal screenshot & XML hierarchy binding:
   - Terminal PNG and XML files exist on disk.
   - Calculated file SHA-256 matches controller.jsonl and SHA256SUMS.
6. Single-run continuous execution & Host Monotonic Clock Proof:
   - Exactly 3 cases (1: HOME, 2: SLEEP, 3: HOME) in strictly ascending order.
   - All 3 cases belong to the same connection session.
   - verified_at_monotonic strictly < hold_release_at_monotonic (no legacy fallback).
   - time_advance_ms > 0.
   - hold_duration_s > 0 and strictly < 2.0s discovery timeout.
   - case 1 release < case 2 verified < case 2 release < case 3 verified < case 3 release.
   - Terminal UI acceptance == CONFIRMED_TERMINAL_UI for all 3 cases.
7. execution_result.json confirms all_three_observed == True and zero UI failures.
8. Optional: GitLab raw trace verification if provided.
"""

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

EXPECTED_CANDIDATE = "acc80f75b599d7f85e5c11416ec6c2e92f774f6b9e1699584414ca35abbade9e"

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


def verify_artifacts(directory: Path, raw_trace_path: Path | None = None) -> tuple[bool, list[str]]:
    errors: list[str] = []
    print(f"=== Rigorous Forensic Verification: {directory} ===")

    if not directory.is_dir():
        errors.append(f"Target directory does not exist: {directory}")
        return False, errors

    # 1. Mandatory Files Existence & Pre-validation (Fail Closed)
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

    # Check runner.exit code == 0
    runner_exit_file = directory / "runner.exit"
    if runner_exit_file.is_file():
        exit_code_str = runner_exit_file.read_text().strip()
        if exit_code_str != "0":
            errors.append(f"runner.exit indicates failure: '{exit_code_str}' (expected '0')")
        else:
            print("    OK: runner.exit == 0")

    # If critical files are missing, fail immediately
    if errors:
        return False, errors

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

    # Check untracked files
    ignored_names = {"SHA256SUMS", ".DS_Store"}
    for p in directory.rglob("*"):
        if p.is_file() and p.name not in ignored_names:
            rel = str(p.relative_to(directory))
            if "scroll-build" in rel:
                continue
            if rel not in checksums:
                errors.append(f"Untracked file on disk not recorded in SHA256SUMS: {rel}")

    print(f"    OK: {verified_count}/{len(checksums)} files verified bit-for-bit.")

    # 3. Verify Candidate & Installed APK Hashes
    print("[3] Verifying APK candidate and installed hashes...")
    candidate_file = directory / "candidate.sha256"
    cand_hash = candidate_file.read_text().strip().split()[0]
    if cand_hash != EXPECTED_CANDIDATE:
        errors.append(f"candidate.sha256 mismatch: expected {EXPECTED_CANDIDATE}, got {cand_hash}")
    else:
        print(f"    OK: candidate.sha256 == {EXPECTED_CANDIDATE}")

    installed_file = directory / "installed-apk.sha256"
    inst_hash = installed_file.read_text().strip().split()[0]
    if inst_hash != EXPECTED_CANDIDATE:
        errors.append(f"installed-apk.sha256 mismatch: expected {EXPECTED_CANDIDATE}, got {inst_hash}")
    else:
        print(f"    OK: installed-apk.sha256 == {EXPECTED_CANDIDATE}")

    # 4. Parse controller.jsonl & Verify Monotonic Timestamps and Structure
    print("[4] Verifying controller.jsonl trace structure and monotonic clock proof...")
    jsonl_path = directory / "controller.jsonl"
    events: list[dict] = []
    for line_idx, line in enumerate(jsonl_path.read_text().splitlines(), 1):
        line = line.strip()
        if line:
            try:
                events.append(json.loads(line))
            except Exception as e:
                errors.append(f"controller.jsonl line {line_idx}: invalid JSON: {e}")

    def get_case_index(ev: dict) -> int | None:
        if "index" in ev and ev["index"] in (1, 2, 3):
            return ev["index"]
        run_id = ev.get("run_id")
        if run_id:
            m = re.match(r'^d05_(\d+)_', run_id)
            if m:
                return int(m.group(1))
        return None

    # Group events by case index (1, 2, 3)
    cases_events: dict[int, list[dict]] = {1: [], 2: [], 3: []}
    for ev in events:
        c_idx = get_case_index(ev)
        if c_idx in (1, 2, 3):
            cases_events[c_idx].append(ev)

    # Check that all 3 cases have required sequence of events
    case_summary = {}
    prev_release_mono = 0.0
    common_connection = None

    for idx in (1, 2, 3):
        evs = cases_events[idx]
        held_ev = next((e for e in evs if e.get("event") == "mode08_response_held"), None)
        cmd_ev = next((e for e in evs if e.get("event") == "os_command_executed_during_hold"), None)
        rel_ev = next((e for e in evs if e.get("event") == "mode08_hold_released_for_resume"), None)
        term_ui_ev = next((e for e in evs if e.get("event") == "mode08_terminal_ui_confirmed"), None)
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

        # Single run connection consistency
        conn = held_ev.get("connection")
        if conn is None:
            errors.append(f"Case {idx}: mode08_response_held missing connection ID")
        elif common_connection is None:
            common_connection = conn
        elif conn != common_connection:
            errors.append(f"Case {idx}: connection ID {conn} != session connection ID {common_connection}")

        # Action & Expected State
        expected_action = "SLEEP" if idx == 2 else "HOME"
        actual_action = cmd_ev.get("action")
        if actual_action != expected_action:
            errors.append(f"Case {idx}: action expected {expected_action}, got {actual_action}")

        expected_state = "wakefulness_asleep" if idx == 2 else "activity_launcher"
        actual_state = cmd_ev.get("verified_state")
        if actual_state != expected_state:
            errors.append(f"Case {idx}: verified_state expected {expected_state}, got {actual_state}")

        # Host Monotonic Clock Proof (Mandatory: NO LEGACY FALLBACK)
        v_mono = cmd_ev.get("verified_at_monotonic")
        r_mono = cmd_ev.get("hold_release_at_monotonic")
        if v_mono is None:
            errors.append(f"Case {idx}: missing mandatory verified_at_monotonic")
        if r_mono is None:
            errors.append(f"Case {idx}: missing mandatory hold_release_at_monotonic")

        if v_mono is not None and r_mono is not None:
            if v_mono >= r_mono:
                errors.append(f"Case {idx}: host monotonic ordering violation: verified_at ({v_mono}) >= hold_release_at ({r_mono})")
            else:
                time_advance = cmd_ev.get("time_advance_ms")
                if time_advance is None or time_advance <= 0:
                    errors.append(f"Case {idx}: time_advance_ms ({time_advance}) must be strictly > 0")
                print(f"    OK Case {idx} Monotonic Proof: verified_at ({v_mono:.6f}) < hold_release_at ({r_mono:.6f}) (advance: {(r_mono - v_mono)*1000:.3f}ms)")

            # Sequential order across cases
            if v_mono <= prev_release_mono:
                errors.append(f"Case {idx}: verified_at ({v_mono}) <= previous case release ({prev_release_mono}) (out-of-order execution)")
            prev_release_mono = r_mono

        # Hold duration < 2.0s
        hold_duration = rel_ev.get("hold_duration_s")
        if hold_duration is None:
            errors.append(f"Case {idx}: missing hold_duration_s in mode08_hold_released_for_resume")
        elif hold_duration <= 0 or hold_duration >= 2.0:
            errors.append(f"Case {idx}: hold_duration_s ({hold_duration}) not in valid window (0 < dur < 2.0s)")
        else:
            print(f"    OK Case {idx} Hold Duration: {hold_duration:.3f}s (< 2.0s discovery timeout)")

        # Terminal UI acceptance
        if comp_ev.get("acceptance") != "CONFIRMED_TERMINAL_UI":
            errors.append(f"Case {idx}: acceptance != CONFIRMED_TERMINAL_UI ({comp_ev.get('acceptance')})")

        case_summary[idx] = {
            "held_ev": held_ev,
            "cmd_ev": cmd_ev,
            "rel_ev": rel_ev,
            "term_snap_ev": term_snap_ev,
            "comp_ev": comp_ev,
        }

    # 5. Native android_logcat.txt Cross-Verification (Anti-Stale & Anti-Spoofing)
    print("[5] Cross-verifying native OS events in android_logcat.txt...")
    logcat_path = directory / "android_logcat.txt"
    logcat_content = logcat_path.read_text(errors="replace")

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
        if not held_epoch_ns:
            errors.append(f"Case {idx}: missing host_epoch_ns in mode08_response_held")
            continue
        held_epoch_s = held_epoch_ns / 1_000_000_000.0

        target_pattern = SLEEP_PATTERN if action == "SLEEP" else HOME_PATTERN
        verified_evidence_lines = 0

        for line in evidence_list:
            stripped_line = line.strip()
            # 1. Must exist verbatim in android_logcat.txt
            if stripped_line not in logcat_content:
                errors.append(f"Case {idx}: evidence line not found in android_logcat.txt: '{stripped_line[:60]}...'")
                continue

            # 2. Must match target regex pattern
            if not target_pattern.search(stripped_line):
                errors.append(f"Case {idx}: evidence line does not match {action} pattern: '{stripped_line[:60]}...'")
                continue

            # 3. Must have valid epoch timestamp
            m_ts = re.match(r'^\s*(\d+\.\d+)\s+', stripped_line)
            if not m_ts:
                errors.append(f"Case {idx}: evidence line lacks epoch timestamp: '{stripped_line[:60]}...'")
                continue

            ev_epoch = float(m_ts.group(1))
            # 4. Must be strictly fresh: timestamp > hold start epoch
            if ev_epoch <= held_epoch_s:
                errors.append(
                    f"Case {idx}: stale logcat event: evidence timestamp ({ev_epoch:.3f}) <= hold epoch ({held_epoch_s:.3f})"
                )
            else:
                diff_s = ev_epoch - held_epoch_s
                verified_evidence_lines += 1
                print(f"    OK Case {idx} ({action}): native logcat confirmed (+{diff_s:.3f}s after hold): {stripped_line[:75]}...")

        if verified_evidence_lines == 0:
            errors.append(f"Case {idx}: no valid fresh native logcat evidence confirmed")

    # 6. Terminal Screenshot and XML Hierarchy Binding Check
    print("[6] Verifying terminal screenshot PNG and XML bindings...")
    for idx in (1, 2, 3):
        if idx not in case_summary:
            continue
        snap_ev = case_summary[idx]["term_snap_ev"]
        png_file_rel = snap_ev.get("file")
        png_sha256 = snap_ev.get("sha256")
        xml_file_rel = snap_ev.get("xml_file")
        xml_sha256 = snap_ev.get("xml_sha256")

        if not png_file_rel or not png_sha256:
            errors.append(f"Case {idx}: terminal screenshot event missing file or sha256")
        else:
            png_path = directory / png_file_rel
            if not png_path.is_file():
                errors.append(f"Case {idx}: terminal screenshot PNG not found on disk: {png_file_rel}")
            else:
                act_png_hash = sha256_file(png_path)
                if act_png_hash != png_sha256:
                    errors.append(f"Case {idx}: terminal PNG hash mismatch on disk: expected {png_sha256}, got {act_png_hash}")
                if png_file_rel in checksums and checksums[png_file_rel] != png_sha256:
                    errors.append(f"Case {idx}: terminal PNG hash != SHA256SUMS")
                print(f"    OK Case {idx} PNG: {png_file_rel} == {png_sha256}")

        if not xml_file_rel or not xml_sha256:
            errors.append(f"Case {idx}: terminal screenshot event missing xml_file or xml_sha256")
        else:
            xml_path = directory / xml_file_rel
            if not xml_path.is_file():
                errors.append(f"Case {idx}: terminal XML hierarchy not found on disk: {xml_file_rel}")
            else:
                act_xml_hash = sha256_file(xml_path)
                if act_xml_hash != xml_sha256:
                    errors.append(f"Case {idx}: terminal XML hash mismatch on disk: expected {xml_sha256}, got {act_xml_hash}")
                if xml_file_rel in checksums and checksums[xml_file_rel] != xml_sha256:
                    errors.append(f"Case {idx}: terminal XML hash != SHA256SUMS")
                print(f"    OK Case {idx} XML: {xml_file_rel} == {xml_sha256}")

    # 7. execution_result.json Check
    print("[7] Verifying execution_result.json...")
    res_path = directory / "execution_result.json"
    try:
        res = json.loads(res_path.read_text())
        if res.get("candidate_sha256") != EXPECTED_CANDIDATE:
            errors.append(f"execution_result.json candidate_sha256 mismatch")
        if res.get("completed_case_indices") != [1, 2, 3]:
            errors.append(f"execution_result.json completed_case_indices != [1, 2, 3]: {res.get('completed_case_indices')}")
        if res.get("all_three_observed") is not True:
            errors.append("execution_result.json all_three_observed is not True")
        if res.get("ui_operation_failures"):
            errors.append(f"execution_result.json has ui_operation_failures: {res.get('ui_operation_failures')}")
        print("    OK: execution_result.json confirms all 3 cases observed without failures.")
    except Exception as e:
        errors.append(f"Failed to parse execution_result.json: {e}")

    # 8. Optional Raw Trace Cross-Check
    if raw_trace_path and raw_trace_path.is_file():
        print(f"[8] Cross-verifying against raw trace: {raw_trace_path}...")
        raw_text = raw_trace_path.read_text(errors="replace")
        for idx in (1, 2, 3):
            if idx in case_summary:
                png_hash = case_summary[idx]["term_snap_ev"].get("sha256", "")
                if png_hash and png_hash not in raw_text:
                    errors.append(f"Case {idx}: terminal PNG hash {png_hash} not found in raw trace")
                else:
                    print(f"    OK Case {idx} terminal PNG hash verified in raw trace.")

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
    parser.add_argument("--raw-trace", dest="raw_trace", default=None, help="Optional path to raw job trace")
    args = parser.parse_args()

    dir_path = Path(args.directory)
    raw_trace = Path(args.raw_trace) if args.raw_trace else None

    success, _ = verify_artifacts(dir_path, raw_trace)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
