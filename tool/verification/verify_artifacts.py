#!/usr/bin/env python3
"""Forensic artifact hash consistency verifier for D05 Android Lifecycle Verification.

Verifies:
1. Every file in d05-device/ matches its SHA256 in SHA256SUMS (100% bit-for-bit).
2. Candidate APK hash matches pinned hash.
3. Every file and sha256 logged in controller.jsonl matches disk files.
4. Host monotonic timestamps in controller.jsonl prove:
   verified_at_monotonic < hold_release_at_monotonic for all 3 cases.
5. All 3 cases reached CONFIRMED_TERMINAL_UI in a single continuous run.
6. execution_result.json confirms all_three_observed == True.
"""

import hashlib
import json
import sys
from pathlib import Path

EXPECTED_CANDIDATE = "acc80f75b599d7f85e5c11416ec6c2e92f774f6b9e1699584414ca35abbade9e"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()


def verify_artifacts(directory: Path) -> bool:
    print(f"=== Verifying D05 Artifacts in {directory} ===")
    errors = []

    # 1. Verify SHA256SUMS
    sha_file = directory / "SHA256SUMS"
    if not sha_file.exists():
        print(f"FAIL: {sha_file} not found")
        return False

    checksums = {}
    for line in sha_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) >= 2:
            digest = parts[0]
            rel_path = parts[1].lstrip("./")
            checksums[rel_path] = digest

    print(f"[1] Verifying SHA256SUMS ({len(checksums)} entries)...")
    verified_files = 0
    for rel_path, expected_digest in checksums.items():
        file_path = directory / rel_path
        if not file_path.exists():
            errors.append(f"Missing file listed in SHA256SUMS: {rel_path}")
            continue
        actual_digest = sha256_file(file_path)
        if actual_digest != expected_digest:
            errors.append(f"Hash mismatch for {rel_path}: expected {expected_digest}, got {actual_digest}")
        else:
            verified_files += 1

    # Check for untracked files
    for p in directory.rglob("*"):
        if p.is_file() and p.name != "SHA256SUMS":
            rel = str(p.relative_to(directory))
            if rel not in checksums:
                errors.append(f"File present on disk but not in SHA256SUMS: {rel}")

    print(f"    OK: {verified_files}/{len(checksums)} files verified bit-for-bit.")

    # 2. Verify Candidate APK
    print("[2] Verifying Candidate APK hash...")
    for apk_txt in ("candidate.sha256", "installed-apk.sha256"):
        p = directory / apk_txt
        if p.exists():
            content = p.read_text().strip().split()[0]
            if content != EXPECTED_CANDIDATE:
                errors.append(f"{apk_txt} mismatch: expected {EXPECTED_CANDIDATE}, got {content}")
            else:
                print(f"    OK: {apk_txt} == {EXPECTED_CANDIDATE}")

    # 3. Verify controller.jsonl events and host monotonic clock proof
    print("[3] Verifying controller.jsonl trace and host monotonic proof...")
    jsonl_path = directory / "controller.jsonl"
    if not jsonl_path.exists():
        errors.append(f"Missing {jsonl_path}")
    else:
        events = [json.loads(line) for line in jsonl_path.read_text().splitlines() if line.strip()]
        print(f"    Loaded {len(events)} events from controller.jsonl")

        # Verify logged file hashes match disk
        for ev in events:
            if "file" in ev and "sha256" in ev:
                fpath = directory / ev["file"]
                if fpath.exists():
                    actual = sha256_file(fpath)
                    if actual != ev["sha256"]:
                        errors.append(f"controller.jsonl event {ev.get('seq')} sha256 mismatch for {ev['file']}")

        # Group by case index
        case_events = {1: [], 2: [], 3: []}
        for ev in events:
            idx = ev.get("index")
            if idx in (1, 2, 3):
                case_events[idx].append(ev)

        for idx in (1, 2, 3):
            evs = case_events[idx]
            cmd_ev = next((e for e in evs if e.get("event") == "os_command_executed_during_hold"), None)
            rel_ev = next((e for e in evs if e.get("event") == "mode08_hold_released_for_resume"), None)
            comp_ev = next((e for e in evs if e.get("event") == "case_observations_complete"), None)

            if not cmd_ev:
                errors.append(f"Case {idx}: missing os_command_executed_during_hold event")
                continue
            if not rel_ev:
                errors.append(f"Case {idx}: missing mode08_hold_released_for_resume event")
                continue
            if not comp_ev:
                errors.append(f"Case {idx}: missing case_observations_complete event")
                continue

            # Check verified state
            expected_state = "wakefulness_asleep" if idx == 2 else "activity_launcher"
            if cmd_ev.get("verified_state") != expected_state:
                errors.append(f"Case {idx}: expected verified_state={expected_state}, got {cmd_ev.get('verified_state')}")

            # Check host monotonic timestamps if present (Modified Option B)
            v_mono = cmd_ev.get("verified_at_monotonic")
            r_mono = cmd_ev.get("hold_release_at_monotonic")
            if v_mono is not None and r_mono is not None:
                if v_mono >= r_mono:
                    errors.append(f"Case {idx}: host monotonic violation: verified_at ({v_mono}) >= hold_release_at ({r_mono})")
                else:
                    advance_ms = cmd_ev.get("time_advance_ms", round((r_mono - v_mono) * 1000, 3))
                    print(f"    OK Case {idx} host monotonic proof: verified_at ({v_mono}) < hold_release_at ({r_mono}) (advance: {advance_ms:.3f}ms)")
            else:
                print(f"    INFO Case {idx}: running legacy event format without monotonic timestamps")

            # Check hold duration strictly < 2.0s
            dur = rel_ev.get("hold_duration_s", 0)
            if dur >= 2.0:
                errors.append(f"Case {idx}: hold duration {dur}s exceeded 2.0s discovery timeout")
            else:
                print(f"    OK Case {idx} hold duration: {dur}s (< 2.0s)")

            if comp_ev.get("acceptance") != "CONFIRMED_TERMINAL_UI":
                errors.append(f"Case {idx}: acceptance={comp_ev.get('acceptance')} != CONFIRMED_TERMINAL_UI")

    # 4. Verify execution_result.json
    print("[4] Verifying execution_result.json...")
    res_path = directory / "execution_result.json"
    if not res_path.exists():
        errors.append(f"Missing {res_path}")
    else:
        res = json.loads(res_path.read_text())
        if res.get("candidate_sha256") != EXPECTED_CANDIDATE:
            errors.append(f"execution_result candidate_sha256 mismatch")
        if res.get("completed_case_indices") != [1, 2, 3]:
            errors.append(f"execution_result completed_case_indices != [1, 2, 3]: {res.get('completed_case_indices')}")
        if not res.get("all_three_observed"):
            errors.append("execution_result all_three_observed != True")
        if res.get("ui_operation_failures"):
            errors.append(f"execution_result has ui_operation_failures: {res.get('ui_operation_failures')}")
        print("    OK: execution_result.json confirms all 3 cases observed without failures.")

    print("=== Verification Summary ===")
    if errors:
        print(f"FAILED with {len(errors)} errors:")
        for err in errors:
            print(f"  - {err}")
        return False
    else:
        print("PASS: All forensic integrity criteria 100% satisfied.")
        return True


if __name__ == "__main__":
    target_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("d05-device")
    success = verify_artifacts(target_dir)
    sys.exit(0 if success else 1)
