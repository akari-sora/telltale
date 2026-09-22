#!/usr/bin/env python3
"""Comprehensive unit test suite for hardened verify_artifacts.py."""

import json
import math
import os
import shutil
import tempfile
import unittest
from pathlib import Path

from tool.verification import verify_artifacts as VA

GENUINE_DIR = Path("d05-device")
JOB_TRACE_PATH = Path("job_trace.txt")


class TestVerifyArtifactsComprehensive(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = Path(tempfile.mkdtemp())

    def tearDown(self):
        shutil.rmtree(self.tmp_dir, ignore_errors=True)

    def _copy_genuine_artifacts(self) -> Path:
        if not GENUINE_DIR.is_dir():
            self.skipTest("d05-device directory not present")
        shutil.rmtree(self.tmp_dir)
        shutil.copytree(GENUINE_DIR, self.tmp_dir)
        if JOB_TRACE_PATH.is_file():
            shutil.copy(JOB_TRACE_PATH, self.tmp_dir / "job_trace.txt")
        return self.tmp_dir

    def _update_sha256sums(self, filename: str):
        target = self.tmp_dir / filename
        new_hash = VA.sha256_file(target)
        sha_file = self.tmp_dir / "SHA256SUMS"
        lines = [
            f"{new_hash}  {filename}" if filename in l else l
            for l in sha_file.read_text().splitlines()
        ]
        sha_file.write_text("\n".join(lines) + "\n")

    def test_01_genuine_artifacts_pass_100_percent(self):
        """Genuine artifacts in d05-device must PASS 100% with zero errors."""
        if not GENUINE_DIR.is_dir():
            self.skipTest("d05-device directory not present")
        trace = JOB_TRACE_PATH if JOB_TRACE_PATH.is_file() else None
        success, errors = VA.verify_artifacts(GENUINE_DIR, trace)
        self.assertTrue(success, f"Genuine artifacts failed: {errors}")
        self.assertEqual(len(errors), 0)

    def test_02_missing_android_logcat_fails_closed(self):
        self._copy_genuine_artifacts()
        (self.tmp_dir / "android_logcat.txt").unlink()
        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("Missing mandatory file: android_logcat.txt" in e for e in errors))

    def test_03_empty_android_logcat_fails_closed(self):
        self._copy_genuine_artifacts()
        (self.tmp_dir / "android_logcat.txt").write_text("")
        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("Mandatory file is empty: android_logcat.txt" in e for e in errors))

    def test_04_missing_png_file_fails_closed(self):
        self._copy_genuine_artifacts()
        (self.tmp_dir / "00411_mode08_terminal.png").unlink()
        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("PNG file not found on disk" in e or "File in SHA256SUMS not found" in e for e in errors))

    def test_05_missing_xml_file_fails_closed(self):
        self._copy_genuine_artifacts()
        (self.tmp_dir / "00411_mode08_terminal.xml").unlink()
        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("XML hierarchy file not found on disk" in e or "File in SHA256SUMS not found" in e for e in errors))

    def test_06_missing_raw_trace_file_fails_closed(self):
        self._copy_genuine_artifacts()
        non_existent = self.tmp_dir / "non_existent_trace.txt"
        success, errors = VA.verify_artifacts(self.tmp_dir, non_existent)
        self.assertFalse(success)
        self.assertTrue(any("Raw trace file not found" in e for e in errors))

    def test_07_missing_controller_jsonl_fails_closed(self):
        self._copy_genuine_artifacts()
        (self.tmp_dir / "controller.jsonl").unlink()
        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("Missing mandatory file: controller.jsonl" in e for e in errors))

    def test_08_missing_sha256sums_fails_closed(self):
        self._copy_genuine_artifacts()
        (self.tmp_dir / "SHA256SUMS").unlink()
        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("Missing mandatory file: SHA256SUMS" in e for e in errors))

    def test_09_runner_exit_nonzero_fails_closed(self):
        self._copy_genuine_artifacts()
        (self.tmp_dir / "runner.exit").write_text("1\n")
        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("runner.exit indicates failure" in e for e in errors))

    def test_10_candidate_hash_mismatch_fails(self):
        self._copy_genuine_artifacts()
        (self.tmp_dir / "candidate.sha256").write_text("0000000000000000000000000000000000000000000000000000000000000000 base.apk\n")
        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("candidate.sha256 mismatch" in e for e in errors))

    def test_11_installed_apk_hash_mismatch_fails(self):
        self._copy_genuine_artifacts()
        (self.tmp_dir / "installed-apk.sha256").write_text("0000000000000000000000000000000000000000000000000000000000000000 base.apk\n")
        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("installed-apk.sha256 mismatch" in e for e in errors))

    def test_12_png_hash_mismatch_disk_vs_sha256sums(self):
        self._copy_genuine_artifacts()
        target = self.tmp_dir / "00411_mode08_terminal.png"
        target.write_bytes(target.read_bytes() + b"\x00")
        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("SHA-256 mismatch for 00411_mode08_terminal.png" in e for e in errors))

    def test_13_png_hash_mismatch_disk_vs_controller_jsonl(self):
        self._copy_genuine_artifacts()
        jsonl = self.tmp_dir / "controller.jsonl"
        lines = jsonl.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("file") == "00411_mode08_terminal.png":
                ev["sha256"] = "a" * 64
            mutated.append(json.dumps(ev))
        jsonl.write_text("\n".join(mutated) + "\n")
        self._update_sha256sums("controller.jsonl")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("PNG hash mismatch on disk" in e or "PNG hash mismatch with SHA256SUMS" in e for e in errors))

    def test_14_xml_hash_mismatch_disk_vs_controller_jsonl(self):
        self._copy_genuine_artifacts()
        jsonl = self.tmp_dir / "controller.jsonl"
        lines = jsonl.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("xml_file") == "00411_mode08_terminal.xml":
                ev["xml_sha256"] = "b" * 64
            mutated.append(json.dumps(ev))
        jsonl.write_text("\n".join(mutated) + "\n")
        self._update_sha256sums("controller.jsonl")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("XML hash mismatch on disk" in e for e in errors))

    def test_15_legacy_format_missing_monotonic_timestamps(self):
        self._copy_genuine_artifacts()
        jsonl = self.tmp_dir / "controller.jsonl"
        lines = jsonl.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("event") == "os_command_executed_during_hold" and ev.get("index") == 1:
                ev.pop("verified_at_monotonic", None)
            mutated.append(json.dumps(ev))
        jsonl.write_text("\n".join(mutated) + "\n")
        self._update_sha256sums("controller.jsonl")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("missing or invalid verified_at_monotonic" in e for e in errors))

    def test_16_inverted_monotonic_timestamps(self):
        self._copy_genuine_artifacts()
        jsonl = self.tmp_dir / "controller.jsonl"
        lines = jsonl.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("event") == "os_command_executed_during_hold" and ev.get("index") == 1:
                ev["verified_at_monotonic"] = ev["hold_release_at_monotonic"] + 1.0
            mutated.append(json.dumps(ev))
        jsonl.write_text("\n".join(mutated) + "\n")
        self._update_sha256sums("controller.jsonl")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("host monotonic ordering violation" in e for e in errors))

    def test_17_hold_duration_zero_or_negative(self):
        self._copy_genuine_artifacts()
        jsonl = self.tmp_dir / "controller.jsonl"
        lines = jsonl.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("event") == "mode08_hold_released_for_resume" and ev.get("index") == 1:
                ev["hold_duration_s"] = 0.0
            mutated.append(json.dumps(ev))
        jsonl.write_text("\n".join(mutated) + "\n")
        self._update_sha256sums("controller.jsonl")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("not in valid window (0 < dur < 2.0s)" in e for e in errors))

    def test_18_hold_duration_two_seconds_or_greater(self):
        self._copy_genuine_artifacts()
        jsonl = self.tmp_dir / "controller.jsonl"
        lines = jsonl.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("event") == "mode08_hold_released_for_resume" and ev.get("index") == 1:
                ev["hold_duration_s"] = 2.05
            mutated.append(json.dumps(ev))
        jsonl.write_text("\n".join(mutated) + "\n")
        self._update_sha256sums("controller.jsonl")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("not in valid window (0 < dur < 2.0s)" in e for e in errors))

    def test_19_connection_id_not_one(self):
        self._copy_genuine_artifacts()
        jsonl = self.tmp_dir / "controller.jsonl"
        lines = jsonl.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("event") == "mode08_response_held" and (ev.get("index") == 1 or (ev.get("run_id") or "").startswith("d05_1_")):
                ev["connection"] = 2
            mutated.append(json.dumps(ev))
        jsonl.write_text("\n".join(mutated) + "\n")
        self._update_sha256sums("controller.jsonl")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("connection ID must be 1" in e for e in errors))

    def test_20_wrong_mode08_query_command(self):
        self._copy_genuine_artifacts()
        jsonl = self.tmp_dir / "controller.jsonl"
        lines = jsonl.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("event") == "mode08_response_held" and (ev.get("index") == 1 or (ev.get("run_id") or "").startswith("d05_1_")):
                ev["command"] = "0100"
            mutated.append(json.dumps(ev))
        jsonl.write_text("\n".join(mutated) + "\n")
        self._update_sha256sums("controller.jsonl")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("command expected 0800, got 0100" in e for e in errors))

    def test_21_stale_logcat_event(self):
        self._copy_genuine_artifacts()
        jsonl = self.tmp_dir / "controller.jsonl"
        lines = jsonl.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("event") == "mode08_response_held" and ev.get("run_id", "").startswith("d05_1_"):
                ev["host_epoch_ns"] += 10_000_000_000  # Shift 10s into future
            mutated.append(json.dumps(ev))
        jsonl.write_text("\n".join(mutated) + "\n")
        self._update_sha256sums("controller.jsonl")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("stale logcat event" in e for e in errors))

    def test_22_untimestamped_logcat_evidence(self):
        self._copy_genuine_artifacts()
        jsonl = self.tmp_dir / "controller.jsonl"
        lines = jsonl.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("event") == "os_command_executed_during_hold" and ev.get("index") == 1:
                ev["evidence"] = ["ActivityTaskManager: START u0 {act=android.intent.action.MAIN}"]
            mutated.append(json.dumps(ev))
        jsonl.write_text("\n".join(mutated) + "\n")
        self._update_sha256sums("controller.jsonl")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("evidence line not found verbatim" in e or "evidence line lacks valid epoch timestamp" in e for e in errors))

    def test_23_empty_evidence_list(self):
        self._copy_genuine_artifacts()
        jsonl = self.tmp_dir / "controller.jsonl"
        lines = jsonl.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("event") == "os_command_executed_during_hold" and ev.get("index") == 1:
                ev["evidence"] = []
            mutated.append(json.dumps(ev))
        jsonl.write_text("\n".join(mutated) + "\n")
        self._update_sha256sums("controller.jsonl")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("evidence list is empty" in e for e in errors))

    def test_24_reviewer_synthetic_folder_fails_closed(self):
        (self.tmp_dir / "SHA256SUMS").write_text("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 empty.txt\n")
        (self.tmp_dir / "empty.txt").write_text("")
        (self.tmp_dir / "controller.jsonl").write_text(
            '{"event": "os_command_executed_during_hold", "index": 1, "action": "HOME"}\n'
        )
        (self.tmp_dir / "execution_result.json").write_text(
            json.dumps({"candidate_sha256": VA.EXPECTED_CANDIDATE, "completed_case_indices": [1, 2, 3], "all_three_observed": True})
        )
        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("Missing mandatory file: android_logcat.txt" in e for e in errors))

    def test_25_untracked_file_fails(self):
        self._copy_genuine_artifacts()
        (self.tmp_dir / "untracked_rogue.png").write_bytes(b"\x89PNG\r\n\x1a\n")
        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("Untracked file on disk not recorded" in e for e in errors))

    def test_26_execution_result_ui_failures_fails(self):
        self._copy_genuine_artifacts()
        res_file = self.tmp_dir / "execution_result.json"
        res = json.loads(res_file.read_text())
        res["ui_operation_failures"] = ["unexpected_timeout"]
        res_file.write_text(json.dumps(res))
        self._update_sha256sums("execution_result.json")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("execution_result.json has ui_operation_failures" in e for e in errors))

    def test_27_execution_result_completed_case_indices_mismatch(self):
        self._copy_genuine_artifacts()
        res_file = self.tmp_dir / "execution_result.json"
        res = json.loads(res_file.read_text())
        res["completed_case_indices"] = [1, 2]
        res_file.write_text(json.dumps(res))
        self._update_sha256sums("execution_result.json")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("completed_case_indices != [1, 2, 3]" in e for e in errors))

    def test_28_nan_hold_duration_fails_closed(self):
        self._copy_genuine_artifacts()
        jsonl = self.tmp_dir / "controller.jsonl"
        lines = jsonl.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("event") == "mode08_hold_released_for_resume" and ev.get("index") == 1:
                # Python json module can serialize NaN as NaN
                ev["hold_duration_s"] = float("nan")
            mutated.append(json.dumps(ev))
        jsonl.write_text("\n".join(mutated) + "\n")
        self._update_sha256sums("controller.jsonl")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("not in valid window" in e for e in errors))

    def test_29_non_monotonic_seq_fails(self):
        self._copy_genuine_artifacts()
        jsonl = self.tmp_dir / "controller.jsonl"
        lines = jsonl.read_text().splitlines()
        mutated = []
        for i, line in enumerate(lines):
            ev = json.loads(line)
            if i == 10:
                ev["seq"] = 5  # Step backward
            mutated.append(json.dumps(ev))
        jsonl.write_text("\n".join(mutated) + "\n")
        self._update_sha256sums("controller.jsonl")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("non-monotonic seq" in e for e in errors))

    def test_30_non_terminal_xml_hash_mismatch_fails(self):
        self._copy_genuine_artifacts()
        jsonl = self.tmp_dir / "controller.jsonl"
        lines = jsonl.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("xml_file") == "00124_after_action.xml":
                ev["xml_sha256"] = "f" * 64
            mutated.append(json.dumps(ev))
        jsonl.write_text("\n".join(mutated) + "\n")
        self._update_sha256sums("controller.jsonl")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("XML hash mismatch on disk" in e for e in errors))


if __name__ == "__main__":
    unittest.main()
