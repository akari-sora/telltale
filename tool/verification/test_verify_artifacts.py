#!/usr/bin/env python3
"""Unit tests for verify_artifacts.py validating fail-closed defense against counterexamples."""

import json
import shutil
import tempfile
import unittest
from pathlib import Path

from tool.verification import verify_artifacts as VA

GENUINE_DIR = Path("d05-device")


class VerifyArtifactsCounterexampleTests(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = Path(tempfile.mkdtemp())

    def tearDown(self):
        shutil.rmtree(self.tmp_dir, ignore_errors=True)

    def test_reviewer_synthetic_folder_fails_closed(self):
        """Counterexample 1 from ChatGPT Reviewer:
        Minimal synthetic folder containing only SHA256SUMS, controller.jsonl with 3 summary events,
        and execution_result.json, lacking logcat, screenshots, monotonic timestamps, etc.
        Must FAIL closed immediately.
        """
        # Create minimal synthetic folder
        (self.tmp_dir / "SHA256SUMS").write_text("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 empty.txt\n")
        (self.tmp_dir / "empty.txt").write_text("")
        (self.tmp_dir / "controller.jsonl").write_text(
            '{"event": "os_command_executed_during_hold", "index": 1, "action": "HOME"}\n'
            '{"event": "os_command_executed_during_hold", "index": 2, "action": "SLEEP"}\n'
            '{"event": "os_command_executed_during_hold", "index": 3, "action": "HOME"}\n'
        )
        (self.tmp_dir / "execution_result.json").write_text(
            json.dumps({"candidate_sha256": VA.EXPECTED_CANDIDATE, "completed_case_indices": [1, 2, 3], "all_three_observed": True})
        )

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success, "Synthetic folder must be rejected")
        self.assertTrue(any("Missing mandatory file: android_logcat.txt" in e for e in errors))
        self.assertTrue(any("Missing mandatory file: candidate.sha256" in e for e in errors))
        self.assertTrue(any("Missing mandatory file: runner.exit" in e for e in errors))

    def test_missing_screenshot_or_xml_fails(self):
        """Counterexample 2 from ChatGPT Reviewer:
        Screenshot event pointing to non-existent PNG or XML file must FAIL.
        """
        # Populate mandatory files
        for mf in ["candidate.sha256", "installed-apk.sha256"]:
            (self.tmp_dir / mf).write_text(f"{VA.EXPECTED_CANDIDATE}  base.apk\n")
        (self.tmp_dir / "runner.exit").write_text("0\n")
        (self.tmp_dir / "last-stage.txt").write_text("cleanup\n")
        (self.tmp_dir / "android_logcat.txt").write_text("1790012000.000 Initial\n")
        (self.tmp_dir / "execution_result.json").write_text(
            json.dumps({"candidate_sha256": VA.EXPECTED_CANDIDATE, "completed_case_indices": [1, 2, 3], "all_three_observed": True})
        )

        # Points to non-existent image
        (self.tmp_dir / "controller.jsonl").write_text(
            '{"seq": 1, "event": "screenshot_captured", "index": 1, "file": "non_existent.png", "sha256": "deadbeef", "xml_file": "non_existent.xml", "xml_sha256": "deadbeef"}\n'
        )
        (self.tmp_dir / "SHA256SUMS").write_text(
            f"{VA.EXPECTED_CANDIDATE}  candidate.sha256\n"
            f"{VA.EXPECTED_CANDIDATE}  installed-apk.sha256\n"
            "0000000000000000000000000000000000000000000000000000000000000000  runner.exit\n"
            "0000000000000000000000000000000000000000000000000000000000000000  last-stage.txt\n"
            "0000000000000000000000000000000000000000000000000000000000000000  android_logcat.txt\n"
            "0000000000000000000000000000000000000000000000000000000000000000  controller.jsonl\n"
            "0000000000000000000000000000000000000000000000000000000000000000  execution_result.json\n"
        )

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(len(errors) > 0)

    def test_stale_logcat_event_fails(self):
        """Counterexample: evidence logcat line timestamp is earlier than or equal to hold dispatch timestamp.
        Must FAIL with stale logcat error.
        """
        # If genuine directory is present, test mutation
        if not GENUINE_DIR.is_dir():
            self.skipTest("d05-device directory not present")

        # Copy genuine dir to tmp_dir
        shutil.rmtree(self.tmp_dir)
        shutil.copytree(GENUINE_DIR, self.tmp_dir)

        # Mutate controller.jsonl so hold timestamp is AFTER evidence timestamp
        jsonl_path = self.tmp_dir / "controller.jsonl"
        lines = jsonl_path.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("event") == "mode08_response_held" and ev.get("run_id", "").startswith("d05_1_"):
                # Advance hold timestamp by 10 seconds into the future so evidence is in the past!
                ev["host_epoch_ns"] += 10_000_000_000
            mutated.append(json.dumps(ev))
        jsonl_path.write_text("\n".join(mutated) + "\n")

        # Update SHA256SUMS for controller.jsonl so SHA check passes
        new_hash = VA.sha256_file(jsonl_path)
        sha_lines = [
            f"{new_hash}  controller.jsonl" if "controller.jsonl" in l else l
            for l in (self.tmp_dir / "SHA256SUMS").read_text().splitlines()
        ]
        (self.tmp_dir / "SHA256SUMS").write_text("\n".join(sha_lines) + "\n")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("stale logcat event" in e for e in errors), f"Expected stale logcat error, got: {errors}")

    def test_missing_monotonic_timestamps_fails(self):
        """Legacy format without monotonic timestamps must be strictly rejected."""
        if not GENUINE_DIR.is_dir():
            self.skipTest("d05-device directory not present")

        shutil.rmtree(self.tmp_dir)
        shutil.copytree(GENUINE_DIR, self.tmp_dir)

        jsonl_path = self.tmp_dir / "controller.jsonl"
        lines = jsonl_path.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("event") == "os_command_executed_during_hold" and ev.get("index") == 1:
                # Remove monotonic fields (simulating legacy format)
                ev.pop("verified_at_monotonic", None)
                ev.pop("hold_release_at_monotonic", None)
            mutated.append(json.dumps(ev))
        jsonl_path.write_text("\n".join(mutated) + "\n")

        new_hash = VA.sha256_file(jsonl_path)
        sha_lines = [
            f"{new_hash}  controller.jsonl" if "controller.jsonl" in l else l
            for l in (self.tmp_dir / "SHA256SUMS").read_text().splitlines()
        ]
        (self.tmp_dir / "SHA256SUMS").write_text("\n".join(sha_lines) + "\n")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("missing mandatory verified_at_monotonic" in e for e in errors))

    def test_inverted_monotonic_timestamps_fails(self):
        """verified_at_monotonic >= hold_release_at_monotonic must be strictly rejected."""
        if not GENUINE_DIR.is_dir():
            self.skipTest("d05-device directory not present")

        shutil.rmtree(self.tmp_dir)
        shutil.copytree(GENUINE_DIR, self.tmp_dir)

        jsonl_path = self.tmp_dir / "controller.jsonl"
        lines = jsonl_path.read_text().splitlines()
        mutated = []
        for line in lines:
            ev = json.loads(line)
            if ev.get("event") == "os_command_executed_during_hold" and ev.get("index") == 1:
                # Invert timestamps: verified_at > hold_release_at
                ev["verified_at_monotonic"] = ev["hold_release_at_monotonic"] + 1.0
            mutated.append(json.dumps(ev))
        jsonl_path.write_text("\n".join(mutated) + "\n")

        new_hash = VA.sha256_file(jsonl_path)
        sha_lines = [
            f"{new_hash}  controller.jsonl" if "controller.jsonl" in l else l
            for l in (self.tmp_dir / "SHA256SUMS").read_text().splitlines()
        ]
        (self.tmp_dir / "SHA256SUMS").write_text("\n".join(sha_lines) + "\n")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("host monotonic ordering violation" in e for e in errors))

    def test_runner_exit_nonzero_fails(self):
        """runner.exit != '0' must fail closed."""
        if not GENUINE_DIR.is_dir():
            self.skipTest("d05-device directory not present")

        shutil.rmtree(self.tmp_dir)
        shutil.copytree(GENUINE_DIR, self.tmp_dir)

        (self.tmp_dir / "runner.exit").write_text("1\n")
        new_hash = VA.sha256_file(self.tmp_dir / "runner.exit")
        sha_lines = [
            f"{new_hash}  runner.exit" if "runner.exit" in l else l
            for l in (self.tmp_dir / "SHA256SUMS").read_text().splitlines()
        ]
        (self.tmp_dir / "SHA256SUMS").write_text("\n".join(sha_lines) + "\n")

        success, errors = VA.verify_artifacts(self.tmp_dir)
        self.assertFalse(success)
        self.assertTrue(any("runner.exit indicates failure" in e for e in errors))

    def test_genuine_artifacts_pass_100_percent(self):
        """Genuine artifacts in d05-device must PASS 100%."""
        if not GENUINE_DIR.is_dir():
            self.skipTest("d05-device directory not present")

        success, errors = VA.verify_artifacts(GENUINE_DIR)
        self.assertTrue(success, f"Genuine artifacts failed verification: {errors}")
        self.assertEqual(len(errors), 0)


if __name__ == "__main__":
    unittest.main()
