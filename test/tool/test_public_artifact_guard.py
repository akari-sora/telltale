#!/usr/bin/env python3
"""Comprehensive test suite for tool/workshop/public_artifact_guard.py (Issue #11, WS-07 Slice 3).

Verifies public artifact privacy boundary governance:
- S3-A1..A16 Acceptance criteria
- Positive controls (clean JSON, CSV, log, segments, isolated timestamps, allowlisted OBD tokens)
- Sensitive negatives (plain VIN, fragmented VIN, hex ASCII VIN, MAC, device UUID, device serial, plate/customer, GPS, user path, timestamp+identity correlation)
- Parser/robustness negatives (malformed JSON, malformed CSV, sequence index duplicates/gaps, invalid UTF-8, oversized input)
- Private/public separation and byte immutability
- Sentinel finding/exception non-leak assertions
- S3-M1..M7 Mutation controls
"""
from __future__ import annotations

import copy
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
TOOL_DIR = REPO_ROOT / "tool/workshop"
sys.path.insert(0, str(TOOL_DIR))

import public_artifact_guard  # noqa: E402
from public_artifact_guard import Finding, GuardResult, PublicArtifactGuard, SanitizedError  # noqa: E402

FIXTURES_DIR = REPO_ROOT / "test/privacy/fixtures"
POLICY_PATH = REPO_ROOT / "docs/privacy/public-artifact-policy.json"


class TestPublicArtifactGuardAcceptance(unittest.TestCase):
    """Verifies S3-A1 through S3-A16 acceptance criteria."""

    def setUp(self) -> None:
        self.guard = PublicArtifactGuard(policy_path=POLICY_PATH)
        self.canary_vin = "TELLTALE0TEST0001"
        self.canary_mac = "02:00:00:00:CA:FE"
        self.canary_uuid = "00000000-0000-4000-8000-000000000001"
        self.canary_serial = "TEL-SERIAL-0001"
        self.canary_plate = "SYNTH-PLATE-01"

    def test_s3_a1_policy_schema_and_classifications(self) -> None:
        """S3-A1: Machine-readable policy exists and defines 3 classifications."""
        self.assertTrue(POLICY_PATH.is_file(), f"Policy missing at {POLICY_PATH}")
        policy = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
        self.assertEqual(policy.get("schema_version"), 1)
        self.assertEqual(policy.get("policy_id"), "ws07-public-artifact-privacy-policy")

        classes = policy.get("classifications", {})
        self.assertIn("private-raw", classes)
        self.assertIn("public-summary", classes)
        self.assertIn("synthetic-canary", classes)

        self.assertFalse(classes["private-raw"]["publishable"])
        self.assertFalse(classes["private-raw"]["mutable"])
        self.assertTrue(classes["public-summary"]["publishable"])
        self.assertFalse(classes["public-summary"]["mutable"])
        self.assertFalse(classes["synthetic-canary"]["publishable"])
        self.assertFalse(classes["synthetic-canary"]["mutable"])

        # Check required categories are documented
        categories = policy.get("rule_categories", {})
        expected_cats = {
            "vehicle.vin.plain",
            "vehicle.vin.fragmented",
            "vehicle.vin.hex_ascii",
            "device.mac",
            "device.uuid",
            "device.serial",
            "subject.plate_or_customer_id",
            "location.gps",
            "host.user_path",
            "correlation.timestamp_with_identity",
        }
        for cat in expected_cats:
            self.assertIn(cat, categories, f"Missing category {cat} in policy")

    def test_s3_a1_policy_loading_validation_fail_closed(self) -> None:
        """S3-A1 & Blocker 2: Corrupted, missing, or malformed policy strictly fails closed."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp = Path(tmp_dir)
            missing = tmp / "missing.json"
            guard_missing = PublicArtifactGuard(policy_path=missing)
            self.assertIsNotNone(guard_missing.policy_error)
            res = guard_missing.check(FIXTURES_DIR / "json/clean_public_summary.json")
            self.assertFalse(res.publishable)
            self.assertTrue(any(e.code == "error.invalid_policy" for e in res.errors))

            # Malformed JSON
            bad_json = tmp / "bad.json"
            bad_json.write_text("{broken", encoding="utf-8")
            guard_bad = PublicArtifactGuard(policy_path=bad_json)
            self.assertIsNotNone(guard_bad.policy_error)
            res_bad = guard_bad.check(FIXTURES_DIR / "json/clean_public_summary.json")
            self.assertFalse(res_bad.publishable)
            self.assertTrue(any(e.code == "error.invalid_policy" for e in res_bad.errors))

            # Non-dict JSON root
            scalar_json = tmp / "scalar.json"
            scalar_json.write_text("12345", encoding="utf-8")
            guard_scalar = PublicArtifactGuard(policy_path=scalar_json)
            self.assertIsNotNone(guard_scalar.policy_error)
            res_scalar = guard_scalar.check(FIXTURES_DIR / "json/clean_public_summary.json")
            self.assertFalse(res_scalar.publishable)
            self.assertTrue(any(e.code == "error.invalid_policy" for e in res_scalar.errors))

            # Unsupported schema_version
            valid_policy = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
            bad_ver = copy.deepcopy(valid_policy)
            bad_ver["schema_version"] = 99
            ver_path = tmp / "ver.json"
            ver_path.write_text(json.dumps(bad_ver), encoding="utf-8")
            guard_ver = PublicArtifactGuard(policy_path=ver_path)
            self.assertIsNotNone(guard_ver.policy_error)
            res_ver = guard_ver.check(FIXTURES_DIR / "json/clean_public_summary.json")
            self.assertFalse(res_ver.publishable)

            # Invalid max_input_bytes
            bad_max = copy.deepcopy(valid_policy)
            bad_max["max_input_bytes"] = True  # bool is not allowed
            max_path = tmp / "max.json"
            max_path.write_text(json.dumps(bad_max), encoding="utf-8")
            guard_max = PublicArtifactGuard(policy_path=max_path)
            self.assertIsNotNone(guard_max.policy_error)
            res_max = guard_max.check(FIXTURES_DIR / "json/clean_public_summary.json")
            self.assertFalse(res_max.publishable)

    def test_s3_a2_canary_inventory_is_synthetic(self) -> None:
        """S3-A2: All test canaries are explicitly synthetic; no real identities."""
        self.assertTrue(self.canary_vin.startswith("TELLTALE0TEST"))
        self.assertTrue(self.canary_mac.startswith("02:00:00:00"))  # Locally administered MAC
        self.assertTrue(self.canary_serial.startswith("TEL-SERIAL"))
        self.assertTrue(self.canary_plate.startswith("SYNTH-PLATE"))

    def test_s3_a3_all_four_format_families_exercised(self) -> None:
        """S3-A3: JSON, CSV, log, and segments formats are supported and scanned."""
        formats = {"json", "csv", "log", "segments"}
        self.assertEqual(public_artifact_guard.VALID_FORMATS - {"auto"}, formats)

        json_res = self.guard.check(FIXTURES_DIR / "json/clean_public_summary.json", format_hint="json")
        csv_res = self.guard.check(FIXTURES_DIR / "csv/clean_public_summary.csv", format_hint="csv")
        log_res = self.guard.check(FIXTURES_DIR / "log/clean_public_summary.log", format_hint="log")
        seg_res = self.guard.check(FIXTURES_DIR / "segments/clean_segments.json", format_hint="segments")

        self.assertTrue(json_res.is_clean)
        self.assertTrue(csv_res.is_clean)
        self.assertTrue(log_res.is_clean)
        self.assertTrue(seg_res.is_clean)

    def test_s3_a3_unknown_format_auto_rejected(self) -> None:
        """S3-A3 & Blocker 4: Unknown file extensions under auto format fail closed."""
        with tempfile.NamedTemporaryFile(suffix=".unknown_extension", mode="w", encoding="utf-8") as tmp:
            tmp.write("some benign log data\n")
            tmp.flush()
            res = self.guard.check(tmp.name, format_hint="auto")
            self.assertFalse(res.publishable)
            self.assertTrue(any(e.code == "error.unsupported_format" for e in res.errors))

    def test_s3_a4_plain_vin_detected(self) -> None:
        """S3-A4: Plain VIN in explicit VIN context is detected."""
        # JSON
        res_json = self.guard.check(FIXTURES_DIR / "json/dirty_vin.json")
        self.assertFalse(res_json.is_clean)
        self.assertTrue(any(f.category == "vehicle.vin.plain" for f in res_json.findings))

        # CSV
        res_csv = self.guard.check(FIXTURES_DIR / "csv/dirty_vin.csv")
        self.assertFalse(res_csv.is_clean)
        self.assertTrue(any(f.category == "vehicle.vin.plain" for f in res_csv.findings))

        # Log
        res_log = self.guard.check(FIXTURES_DIR / "log/dirty_vin.log")
        self.assertFalse(res_log.is_clean)
        self.assertTrue(any(f.category == "vehicle.vin.plain" for f in res_log.findings))

    def test_s3_a5_fragmented_and_hex_vin_detected(self) -> None:
        """S3-A5: Fragmented VIN and hex-encoded ASCII VIN are detected across segments and contiguous."""
        # Segmented plain VIN
        res_seg_vin = self.guard.check(FIXTURES_DIR / "segments/dirty_segmented_vin.json", format_hint="segments")
        self.assertFalse(res_seg_vin.is_clean)
        self.assertTrue(any(f.category == "vehicle.vin.fragmented" for f in res_seg_vin.findings))

        # Segmented hex VIN
        res_seg_hex = self.guard.check(FIXTURES_DIR / "segments/dirty_segmented_hex_vin.json", format_hint="segments")
        self.assertFalse(res_seg_hex.is_clean)
        self.assertTrue(any(f.category == "vehicle.vin.hex_ascii" for f in res_seg_hex.findings))

        # Contiguous hex VIN in JSON
        res_json_hex = self.guard.check(FIXTURES_DIR / "json/dirty_hex_vin.json")
        self.assertFalse(res_json_hex.is_clean)
        self.assertTrue(any(f.category == "vehicle.vin.hex_ascii" for f in res_json_hex.findings))

    def test_s3_a6_device_identity_and_plate_detected(self) -> None:
        """S3-A6: MAC, context-bound device UUID, serial, and plate/customer detected."""
        # MAC in CSV
        res_mac = self.guard.check(FIXTURES_DIR / "csv/dirty_mac.csv")
        self.assertFalse(res_mac.is_clean)
        self.assertTrue(any(f.category == "device.mac" for f in res_mac.findings))

        # Device UUID in JSON
        res_uuid = self.guard.check(FIXTURES_DIR / "json/dirty_device_uuid.json")
        self.assertFalse(res_uuid.is_clean)
        self.assertTrue(any(f.category == "device.uuid" for f in res_uuid.findings))

        # Device serial in log
        res_serial = self.guard.check(FIXTURES_DIR / "log/dirty_device_serial.log")
        self.assertFalse(res_serial.is_clean)
        self.assertTrue(any(f.category == "device.serial" for f in res_serial.findings))

        # Plate / customer in CSV
        res_plate = self.guard.check(FIXTURES_DIR / "csv/dirty_customer_plate.csv")
        self.assertFalse(res_plate.is_clean)
        self.assertTrue(any(f.category == "subject.plate_or_customer_id" for f in res_plate.findings))

    def test_s3_a4_a6_keys_headers_and_non_leak_locations(self) -> None:
        """S3-A4..A6 & Blocker 3: Keys and headers are scanned; unknown keys masked to <key>."""
        # JSON key contains VIN
        json_with_vin_key = json.dumps({"TELLTALE0TEST0001": "clean_value"})
        findings, _ = self.guard.scan_content(json_with_vin_key, "json")
        self.assertTrue(any(f.category == "vehicle.vin.plain" for f in findings))
        vin_finding = next(f for f in findings if f.category == "vehicle.vin.plain")
        self.assertNotIn("TELLTALE0TEST0001", vin_finding.location)

        # JSON with unknown custom key: location must be masked with <key>
        json_with_custom_key = json.dumps({"custom_arbitrary_account_id_99": {"vin": "TELLTALE0TEST0001"}})
        findings_custom, _ = self.guard.scan_content(json_with_custom_key, "json")
        custom_finding = next(f for f in findings_custom if f.category == "vehicle.vin.plain")
        self.assertNotIn("custom_arbitrary_account_id_99", custom_finding.location)
        self.assertIn("<key>", custom_finding.location)

        # CSV header contains VIN
        csv_with_vin_header = "scenario_id,vin_TELLTALE0TEST0001,status\nTC-1,foo,PASS\n"
        findings_csv, _ = self.guard.scan_content(csv_with_vin_header, "csv")
        self.assertTrue(any(f.category == "vehicle.vin.plain" for f in findings_csv))
        csv_finding = next(f for f in findings_csv if f.category == "vehicle.vin.plain")
        self.assertNotIn("TELLTALE0TEST0001", csv_finding.location)
        self.assertEqual(csv_finding.location, "header col 2")

    def test_s3_a7_gps_and_timestamp_correlation_detected(self) -> None:
        """S3-A7: GPS coordinates and timestamp+identity correlation detected while timestamp-alone is allowed."""
        # GPS in JSON
        res_gps = self.guard.check(FIXTURES_DIR / "json/dirty_gps.json")
        self.assertFalse(res_gps.is_clean)
        self.assertTrue(any(f.category == "location.gps" for f in res_gps.findings))

        # Correlated timestamp + VIN in JSON
        res_corr = self.guard.check(FIXTURES_DIR / "json/dirty_timestamp_identity.json")
        self.assertFalse(res_corr.is_clean)
        self.assertTrue(any(f.category == "correlation.timestamp_with_identity" for f in res_corr.findings))

        # Timestamp alone in clean fixture must be GREEN
        res_clean = self.guard.check(FIXTURES_DIR / "json/clean_public_summary.json")
        self.assertTrue(res_clean.is_clean)
        self.assertEqual(res_clean.findings, [])

    def test_s3_a8_synthetic_user_paths_detected(self) -> None:
        """S3-A8: Synthetic user-home absolute paths on Unix/macOS/Windows are detected."""
        # Unix/Linux /home
        res_unix = self.guard.check(FIXTURES_DIR / "log/dirty_user_path.log")
        self.assertFalse(res_unix.is_clean)
        self.assertTrue(any(f.category == "host.user_path" for f in res_unix.findings))

        # macOS /Users
        res_mac = self.guard.check(FIXTURES_DIR / "json/dirty_user_path.json")
        self.assertFalse(res_mac.is_clean)
        self.assertTrue(any(f.category == "host.user_path" for f in res_mac.findings))

        # Windows C:\Users
        res_win = self.guard.check(FIXTURES_DIR / "log/dirty_windows_path.log")
        self.assertFalse(res_win.is_clean)
        self.assertTrue(any(f.category == "host.user_path" for f in res_win.findings))

    def test_s3_a8_target_path_sanitization_in_reports(self) -> None:
        """S3-A8 & Blocker 3: Reports never leak host home paths or sensitive filenames."""
        fake_path = "/Users/alice_dev/secret_project/summary.json"
        res = GuardResult(
            target_path=fake_path,
            classification="public-summary",
            publishable=False,
            findings=[],
            errors=[SanitizedError("error.test", "Test error")],
        )
        text_rep = public_artifact_guard.format_text_report(res)
        json_rep = public_artifact_guard.format_json_report(res)
        self.assertNotIn("/Users/alice_dev", text_rep)
        self.assertNotIn("/Users/alice_dev", json_rep)
        self.assertIn("<artifact>", text_rep)
        self.assertIn("<artifact>", json_rep)

        fake_vin_path = "/home/bob/TELLTALE0TEST0001.json"
        res_vin = GuardResult(
            target_path=fake_vin_path,
            classification="public-summary",
            publishable=False,
            findings=[],
            errors=[],
        )
        text_vin = public_artifact_guard.format_text_report(res_vin)
        self.assertNotIn("TELLTALE0TEST0001", text_vin)
        self.assertIn("<artifact>", text_vin)


    def test_s3_a9_findings_and_exceptions_sentinel_non_leak(self) -> None:
        """S3-A9 & S3-M5: Findings and exceptions NEVER contain raw identifiers or sensitive tokens."""
        sentinel_targets = [
            FIXTURES_DIR / "json/dirty_vin.json",
            FIXTURES_DIR / "csv/dirty_mac.csv",
            FIXTURES_DIR / "log/dirty_device_serial.log",
            FIXTURES_DIR / "json/dirty_gps.json",
            FIXTURES_DIR / "log/dirty_user_path.log",
            FIXTURES_DIR / "json/dirty_hex_vin.json",
            FIXTURES_DIR / "raw/private_raw_transcript.log",
        ]

        forbidden_tokens = [
            self.canary_vin,
            self.canary_mac,
            self.canary_uuid,
            self.canary_serial,
            "canary-user",
            "37.7749",
            "-122.4194",
            "54454c4c54414c45305445535430303031",
            hashlib.sha256(self.canary_vin.encode("utf-8")).hexdigest(),
        ]

        for target in sentinel_targets:
            res = self.guard.check(target)
            text_rep = public_artifact_guard.format_text_report(res)
            json_rep = public_artifact_guard.format_json_report(res)

            for token in forbidden_tokens:
                self.assertNotIn(
                    token.lower(),
                    text_rep.lower(),
                    f"Sensitive token leaked in text report for {target.name}",
                )
                self.assertNotIn(
                    token.lower(),
                    json_rep.lower(),
                    f"Sensitive token leaked in json report for {target.name}",
                )

    def test_s3_a10_clean_public_summary_negative_controls_stay_green(self) -> None:
        """S3-A10: Clean public summary containing DTC, ECU, protocol, git SHA, and scenario ID remains GREEN."""
        res = self.guard.check(FIXTURES_DIR / "json/clean_public_summary.json")
        self.assertTrue(res.is_clean)
        self.assertEqual(res.findings, [])
        self.assertEqual(res.errors, [])

    def test_s3_a11_private_raw_fixtures_byte_immutability(self) -> None:
        """S3-A11: Private raw fixtures remain byte-identical before and after guard execution."""
        target = FIXTURES_DIR / "raw/private_raw_transcript.log"
        sha_before = hashlib.sha256(target.read_bytes()).hexdigest()

        # Execute guard check with both classifications
        self.guard.check(target, classification="private-raw")
        self.guard.check(target, classification="public-summary")

        sha_after = hashlib.sha256(target.read_bytes()).hexdigest()
        self.assertEqual(sha_before, sha_after)

    def test_s3_a12_classification_fail_closed(self) -> None:
        """S3-A12 & S3-M6: Non-public-summary cannot be published; public-summary scans fail-closed."""
        target = FIXTURES_DIR / "raw/private_raw_transcript.log"

        # Under private-raw classification: rejected unconditionally
        res_priv = self.guard.check(target, classification="private-raw")
        self.assertFalse(res_priv.publishable)
        self.assertFalse(res_priv.is_clean)
        self.assertTrue(any(e.code == "policy.not_publishable" for e in res_priv.errors))

        # Under synthetic-canary classification: rejected unconditionally
        res_canary = self.guard.check(target, classification="synthetic-canary")
        self.assertFalse(res_canary.publishable)
        self.assertFalse(res_canary.is_clean)
        self.assertTrue(any(e.code == "policy.not_publishable" for e in res_canary.errors))

        # Under public-summary classification: dirty content fails closed
        res_pub = self.guard.check(target, classification="public-summary")
        self.assertFalse(res_pub.publishable)
        self.assertFalse(res_pub.is_clean)
        self.assertGreater(len(res_pub.findings), 0)

    def test_s3_a13_parser_and_robustness_negatives_fail_closed(self) -> None:
        """S3-A13: Malformed JSON, CSV, segment errors, invalid encoding, and oversize fail closed."""
        # Malformed JSON
        res_json = self.guard.check(FIXTURES_DIR / "json/malformed.json")
        self.assertFalse(res_json.publishable)
        self.assertTrue(any(e.code == "error.malformed_json" for e in res_json.errors))

        # Malformed CSV
        res_csv = self.guard.check(FIXTURES_DIR / "csv/malformed.csv")
        self.assertFalse(res_csv.publishable)
        self.assertTrue(any(e.code == "error.malformed_csv" for e in res_csv.errors))

        # Strict CSV quoting error
        strict_csv_content = 'col1,col2\nval1,"val2 unclosed\nval3,val4\n'
        _, errors_csv = self.guard.scan_content(strict_csv_content, "csv")
        self.assertTrue(any(e.code == "error.malformed_csv" for e in errors_csv))

        # Duplicate JSON keys (Blocker 6)
        dup_json = '{"protocol": "CAN", "protocol": "ISO"}'
        _, errors_dup = self.guard.scan_content(dup_json, "json")
        self.assertTrue(any(e.code == "schema.duplicate_json_key" for e in errors_dup))

        # Root scalar JSON (Blocker 6)
        _, errors_scalar = self.guard.scan_content('"string_root"', "json")
        self.assertTrue(any(e.code == "error.invalid_json_root" for e in errors_scalar))

        # Duplicate segment index
        res_dup = self.guard.check(FIXTURES_DIR / "segments/duplicate_seq_segments.json", format_hint="segments")
        self.assertFalse(res_dup.publishable)
        self.assertTrue(any(f.rule_id == "schema.duplicate_segment_index" for f in res_dup.findings))

        # Missing segment index
        res_gap = self.guard.check(FIXTURES_DIR / "segments/missing_seq_segments.json", format_hint="segments")
        self.assertFalse(res_gap.publishable)
        self.assertTrue(any(f.rule_id == "schema.missing_segment_index" for f in res_gap.findings))

        # Segments with non-dict element (Blocker 5)
        _, errors_seg_elem = self.guard.scan_content('[123, "not_dict"]', "segments")
        self.assertTrue(any(e.code == "schema.invalid_segments" for e in errors_seg_elem))

        # Segments with missing seq or payload (Blocker 5)
        _, errors_seg_keys = self.guard.scan_content('[{"only_meta": "test"}]', "segments")
        self.assertTrue(any(e.code == "schema.invalid_segments" for e in errors_seg_keys))

        # Segments with sensitive metadata (Blocker 5)
        seg_with_mac = json.dumps([
            {"seq": 0, "payload": "clean_part", "metadata": {"adapter_mac": "02:00:00:00:CA:FE"}}
        ])
        findings_seg, _ = self.guard.scan_content(seg_with_mac, "segments")
        self.assertTrue(any(f.category == "device.mac" for f in findings_seg))

        # Oversized file
        small_guard = PublicArtifactGuard(max_bytes=10)
        res_over = small_guard.check(FIXTURES_DIR / "json/clean_public_summary.json")
        self.assertFalse(res_over.publishable)
        self.assertTrue(any(e.code == "error.oversized_input" for e in res_over.errors))

    def test_s3_a14_cli_determinism_and_idempotency(self) -> None:
        """S3-A14: CLI execution is deterministic and idempotent."""
        cmd = [
            sys.executable,
            str(TOOL_DIR / "public_artifact_guard.py"),
            "check",
            "--classification",
            "public-summary",
            "--output",
            "json",
            str(FIXTURES_DIR / "json/clean_public_summary.json"),
        ]
        res1 = subprocess.run(cmd, capture_output=True, text=True, check=False)
        self.assertEqual(res1.returncode, 0)

        res2 = subprocess.run(cmd, capture_output=True, text=True, check=False)
        self.assertEqual(res1.stdout, res2.stdout)

    def test_s3_a15_private_raw_transcript_truthfulness_and_rejection(self) -> None:
        """S3-A15 & Blocker 8: Private raw transcript retains synthetic VIN; rejected by public summary."""
        target = FIXTURES_DIR / "raw/private_raw_transcript.log"
        content = target.read_text(encoding="utf-8")
        self.assertIn("TELLTALE0TEST0001", content, "Private raw transcript must truthfully retain synthetic VIN")

        # Under private-raw classification: rejected unconditionally
        res_priv = self.guard.check(target, classification="private-raw")
        self.assertFalse(res_priv.publishable)
        self.assertTrue(any(e.code == "policy.not_publishable" for e in res_priv.errors))

        # Under public-summary classification: dirty content fails closed
        res_pub = self.guard.check(target, classification="public-summary")
        self.assertFalse(res_pub.publishable)
        self.assertTrue(any(f.category == "vehicle.vin.plain" for f in res_pub.findings))

    def test_additional_correctness_fixes(self) -> None:
        """Verify --max-bytes cannot be relaxed by policy max, and plate key ignores template."""
        guard_tight = PublicArtifactGuard(policy_path=POLICY_PATH, max_bytes=100)
        self.assertEqual(guard_tight.max_bytes, 100)

        self.assertFalse(public_artifact_guard._is_plate_or_customer_key("template"))
        self.assertFalse(public_artifact_guard._is_plate_or_customer_key("boilerplate"))
        self.assertFalse(public_artifact_guard._is_plate_or_customer_key("plateau"))
        self.assertTrue(public_artifact_guard._is_plate_or_customer_key("plate"))
        self.assertTrue(public_artifact_guard._is_plate_or_customer_key("license_plate"))
        self.assertTrue(public_artifact_guard._is_plate_or_customer_key("plate_number"))
        self.assertTrue(public_artifact_guard._is_plate_or_customer_key("customer_id"))

    def test_s3_git_commit_sha_and_scenario_id_key_negative_controls(self) -> None:
        """P2: Git commit SHAs and scenario IDs as map keys or headers are not misclassified as VIN."""
        # Git commit hash (40-hex) as map key
        payload = json.dumps({
            "builds_by_commit": {
                "63007823eec73273e9365538e1b6f001ca250eb9": {"status": "PASS"}
            }
        })
        findings, errors = self.guard.scan_content(payload, "json")
        self.assertEqual(errors, [])
        self.assertFalse(any(f.category == "vehicle.vin.plain" for f in findings))
        self.assertEqual(findings, [])

        # Scenario identifier (17 chars) without VIN context as key
        payload_scenario = json.dumps({
            "scenario_test_001": {"result": "PASS"}
        })
        findings_scen, _ = self.guard.scan_content(payload_scenario, "json")
        self.assertFalse(any(f.category == "vehicle.vin.plain" for f in findings_scen))

        # CSV with commit SHA header
        csv_content = "scenario_id,commit_hash,status\nTC-1,63007823eec73273e9365538e1b6f001ca250eb9,PASS\n"
        findings_csv, _ = self.guard.scan_content(csv_content, "csv")
        self.assertFalse(any(f.category == "vehicle.vin.plain" for f in findings_csv))

    def test_s3_r3_f01_f03_device_serial_filename_non_leak(self) -> None:
        """P1-R1 & F01-F03: Arbitrary device serial filename is never leaked in text or JSON report."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            # Dirty content
            f_dirty = Path(tmp_dir) / "SYNTH7X9.json"
            f_dirty.write_text(json.dumps({"deviceSerial": "SYNTH7X9"}), encoding="utf-8")
            res_dirty = self.guard.check(f_dirty)
            self.assertFalse(res_dirty.is_clean)
            text_dirty = public_artifact_guard.format_text_report(res_dirty)
            json_dirty = public_artifact_guard.format_json_report(res_dirty)
            self.assertNotIn("SYNTH7X9", text_dirty.split("\n")[0])
            self.assertEqual(json.loads(json_dirty)["target_path"], "<artifact>")
            self.assertIn("<artifact>", text_dirty)

            # Clean content
            f_clean = Path(tmp_dir) / "SYNTH7X9.json"
            f_clean.write_text("{}", encoding="utf-8")
            res_clean = self.guard.check(f_clean)
            self.assertTrue(res_clean.is_clean)
            text_clean = public_artifact_guard.format_text_report(res_clean)
            json_clean = public_artifact_guard.format_json_report(res_clean)
            self.assertNotIn("SYNTH7X9", text_clean)
            self.assertEqual(json.loads(json_clean)["target_path"], "<artifact>")
            self.assertIn("<artifact>", text_clean)

    def test_s3_r3_f08_f10_declared_segments_fail_closed(self) -> None:
        """P1-R2 & F08-F10: Declared segment containers in JSON fail closed on invalid/null elements."""
        # F08: {"segments": [{"seq": 0}, null]}
        _, errs1 = self.guard.scan_content(json.dumps({"segments": [{"seq": 0}, None]}), "json")
        self.assertTrue(any(e.code == "schema.invalid_segments" for e in errs1))

        # F09: {"segments": [null]}
        _, errs2 = self.guard.scan_content(json.dumps({"segments": [None]}), "json")
        self.assertTrue(any(e.code == "schema.invalid_segments" for e in errs2))

    def test_s3_r3_f04_f07_explicit_vin_priority_over_test_words(self) -> None:
        """P1-VIN & F04-F07: Explicit VIN keywords have priority over test/case/build keywords."""
        # F04: JSON key "case VIN=TELLTALE0TEST0001"
        findings_case, _ = self.guard.scan_content(json.dumps({"case VIN=TELLTALE0TEST0001": ""}), "json")
        self.assertTrue(any(f.category == "vehicle.vin.plain" for f in findings_case))

        # F05: JSON key "build VIN=TELLTALE0TEST0001"
        findings_build, _ = self.guard.scan_content(json.dumps({"build VIN=TELLTALE0TEST0001": ""}), "json")
        self.assertTrue(any(f.category == "vehicle.vin.plain" for f in findings_build))

        # F06: CSV header "case VIN=TELLTALE0TEST0001,speed"
        findings_csv, _ = self.guard.scan_content("case VIN=TELLTALE0TEST0001,speed\nval1,val2\n", "csv")
        self.assertTrue(any(f.category == "vehicle.vin.plain" for f in findings_csv))

    def test_s3_r3_e22_scenario_context_not_misclassified_as_vin(self) -> None:
        """P2 & E22: 17-character scenario key within scenarios container is not misclassified as VIN."""
        e22_payload = json.dumps({"scenarios": {"ABCDEFGHJKLMNPRST": {"status": "PASS"}}})
        findings, errors = self.guard.scan_content(e22_payload, "json")
        self.assertEqual(errors, [])
        self.assertFalse(any(f.category == "vehicle.vin.plain" for f in findings))
        self.assertEqual(findings, [])

    def test_s3_r3_f11_f12_git_sha_in_segments_clean(self) -> None:
        """P2 & F11-F12: Git SHA in segment payload is not misclassified as fragmented VIN."""
        sha_payload = json.dumps([{"seq": 0, "payload": "63007823eec73273e9365538e1b6f001ca250eb9"}])
        findings, errors = self.guard.scan_content(sha_payload, "segments")
        self.assertEqual(errors, [])
        self.assertFalse(any(f.category == "vehicle.vin.fragmented" for f in findings))
        self.assertEqual(findings, [])

    def test_s3_r4_g01_g19_reviewer_boundary_controls(self) -> None:
        """Round 4 Reviewer Findings G01-G19: Identity arrays, declared segments, and hex ASCII VIN runs."""
        # G01: Scalar VIN
        f_g01, _ = self.guard.scan_content(json.dumps({"vin": "TELLTALE0TEST0001"}), "json")
        self.assertTrue(any(f.category == "vehicle.vin.plain" for f in f_g01))

        # G02: VIN array
        f_g02, _ = self.guard.scan_content(json.dumps({"vin": ["TELLTALE0TEST0001"]}), "json")
        self.assertTrue(any(f.category == "vehicle.vin.plain" and f.location == "vin[0]" for f in f_g02))

        # G03: Scalar deviceUuid
        f_g03, _ = self.guard.scan_content(json.dumps({"deviceUuid": "00000000-0000-4000-8000-000000000001"}), "json")
        self.assertTrue(any(f.category == "device.uuid" for f in f_g03))

        # G04: deviceUuid array
        f_g04, _ = self.guard.scan_content(json.dumps({"deviceUuid": ["00000000-0000-4000-8000-000000000001"]}), "json")
        self.assertTrue(any(f.category == "device.uuid" and f.location == "deviceUuid[0]" for f in f_g04))

        # G05: Scalar deviceSerial
        f_g05, _ = self.guard.scan_content(json.dumps({"deviceSerial": "TEL-SERIAL-0001"}), "json")
        self.assertTrue(any(f.category == "device.serial" for f in f_g05))

        # G06: deviceSerial array
        f_g06, _ = self.guard.scan_content(json.dumps({"deviceSerial": ["TEL-SERIAL-0001"]}), "json")
        self.assertTrue(any(f.category == "device.serial" and f.location == "deviceSerial[0]" for f in f_g06))

        # G07: run_id generic UUID array (negative control, must stay GREEN)
        f_g07, e_g07 = self.guard.scan_content(json.dumps({"run_id": ["00000000-0000-4000-8000-000000000001"]}), "json")
        self.assertEqual(f_g07, [])
        self.assertEqual(e_g07, [])

        # G08: Log plain VIN prefix
        f_g08, _ = self.guard.scan_content("VIN=TELLTALE0TEST0001\n", "log")
        self.assertTrue(any(f.category == "vehicle.vin.plain" for f in f_g08))

        # G09: JSON message with plain VIN prefix
        f_g09, _ = self.guard.scan_content(json.dumps({"message": "VIN=TELLTALE0TEST0001"}), "json")
        self.assertTrue(any(f.category == "vehicle.vin.plain" and f.location == "message" for f in f_g09))

        # G10: Legitimate segment array with VIN fragments
        f_g10, _ = self.guard.scan_content(json.dumps({
            "segments": [
                {"seq": 0, "payload": "TELLTALE0"},
                {"seq": 1, "payload": "TEST0001"},
            ]
        }), "json")
        self.assertTrue(any(f.category == "vehicle.vin.fragmented" for f in f_g10))

        # G11: Declared segments with object instead of array
        _, e_g11 = self.guard.scan_content(json.dumps({
            "segments": {
                "0": {"seq": 0, "payload": "TELLTALE0"},
                "1": {"seq": 1, "payload": "TEST0001"},
            }
        }), "json")
        self.assertTrue(any(e.code == "schema.invalid_segments" for e in e_g11))

        # G12: Declared segments with null
        _, e_g12 = self.guard.scan_content(json.dumps({"segments": None}), "json")
        self.assertTrue(any(e.code == "schema.invalid_segments" for e in e_g12))

        # G13: Declared segments with string
        f_g13, e_g13 = self.guard.scan_content(json.dumps({"segments": "VIN=TELLTALE0TEST0001"}), "json")
        self.assertTrue(any(e.code == "schema.invalid_segments" for e in e_g13))
        self.assertTrue(any(f.category == "vehicle.vin.plain" for f in f_g13))

        # G14: Format segments with object
        _, e_g14 = self.guard.scan_content(json.dumps({
            "0": {"seq": 0, "payload": "TELLTALE0"},
            "1": {"seq": 1, "payload": "TEST0001"},
        }), "segments")
        self.assertTrue(any(e.code == "schema.invalid_segments" for e in e_g14))

        # G15: Plain number array (negative control, must stay GREEN)
        f_g15, e_g15 = self.guard.scan_content(json.dumps({"values": [1, 2, 3]}), "json")
        self.assertEqual(f_g15, [])
        self.assertEqual(e_g15, [])

        # G16: Continuous hex ASCII VIN in log
        f_g16, _ = self.guard.scan_content("RX: 54454C4C54414C45305445535430303031\n", "log")
        self.assertTrue(any(f.category == "vehicle.vin.hex_ascii" for f in f_g16))

        # G17: Space-separated hex ASCII VIN in log
        f_g17, _ = self.guard.scan_content("RX: 54 45 4C 4C 54 41 4C 45 30 54 45 53 54 30 30 30 31\n", "log")
        self.assertTrue(any(f.category == "vehicle.vin.hex_ascii" for f in f_g17))

        # G18: Space-separated hex in JSON raw_payload_hex
        f_g18, _ = self.guard.scan_content(json.dumps({
            "raw_payload_hex": "54 45 4C 4C 54 41 4C 45 30 54 45 53 54 30 30 30 31",
        }), "json")
        self.assertTrue(any(f.category == "vehicle.vin.hex_ascii" for f in f_g18))

        # G19: Short OBD reply in log (negative control, must stay GREEN)
        f_g19, e_g19 = self.guard.scan_content("RX: 41 00 BE 3F B8 13\n", "log")
        self.assertEqual(f_g19, [])
        self.assertEqual(e_g19, [])

        # Additional schema error assertions on identity nested object types
        _, e_vin_obj = self.guard.scan_content(json.dumps({"vin": {"nested": "value"}}), "json")
        self.assertTrue(any(e.code == "schema.invalid_identity_type" for e in e_vin_obj))

        _, e_uuid_obj = self.guard.scan_content(json.dumps({"deviceUuid": {"nested": "value"}}), "json")
        self.assertTrue(any(e.code == "schema.invalid_identity_type" for e in e_uuid_obj))

        # CLI exit code 2 on schema error (G11)
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as tf:
            tf.write(json.dumps({"segments": {"0": {"seq": 0, "payload": "TELLTALE0"}}}))
            tf_path = tf.name
        try:
            cli_res = subprocess.run(
                [sys.executable, str(TOOL_DIR / "public_artifact_guard.py"), "check", "--classification", "public-summary", "--format", "json", tf_path],
                capture_output=True,
                text=True,
            )
            self.assertEqual(cli_res.returncode, 2)
            self.assertIn("schema.invalid_segments", cli_res.stderr)
        finally:
            os.unlink(tf_path)

    def test_s3_json_segment_container_null_and_invalid_payload_fail_closed(self) -> None:

        """P1-R2: JSON segment containers fail closed when null or invalid payload elements are present."""
        # Minimal counterexample from reviewer: array with null between fragments
        payload_with_null = json.dumps({
            "segments": [
                {"seq": 0, "payload": "TELLTALE0"},
                None,
                {"seq": 1, "payload": "TEST0001"},
            ]
        })
        findings, errors = self.guard.scan_content(payload_with_null, "json")
        self.assertTrue(any(f.category == "vehicle.vin.fragmented" for f in findings))
        self.assertTrue(any(e.code == "schema.invalid_segments" for e in errors))

        # Array with invalid payload types (None / list)
        payload_invalid_type = json.dumps({
            "segments": [
                {"seq": 0, "payload": None},
                {"seq": 1, "payload": [1, 2, 3]},
            ]
        })
        _, errors_type = self.guard.scan_content(payload_invalid_type, "json")
        self.assertTrue(any(e.code == "schema.invalid_segments" for e in errors_type))

    def test_s3_policy_semantics_verification(self) -> None:
        """P1-POLICY: Policy schema strictly verifies true boolean semantics and supported formats."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_p = Path(tmp_dir) / "policy.json"
            base_policy = json.loads(POLICY_PATH.read_text(encoding="utf-8"))

            # Tamper 1: public-summary.publishable = False
            p1 = dict(base_policy)
            p1["classifications"] = dict(base_policy["classifications"])
            p1["classifications"]["public-summary"] = {"publishable": False, "mutable": False}
            tmp_p.write_text(json.dumps(p1), encoding="utf-8")
            g1 = PublicArtifactGuard(policy_path=tmp_p)
            self.assertIsNotNone(g1.policy_error)
            self.assertEqual(g1.policy_error.code, "error.invalid_policy")

            # Tamper 2: private-raw.publishable = True
            p2 = dict(base_policy)
            p2["classifications"] = dict(base_policy["classifications"])
            p2["classifications"]["private-raw"] = {"publishable": True, "mutable": False}
            tmp_p.write_text(json.dumps(p2), encoding="utf-8")
            g2 = PublicArtifactGuard(policy_path=tmp_p)
            self.assertIsNotNone(g2.policy_error)
            self.assertEqual(g2.policy_error.code, "error.invalid_policy")

            # Tamper 3: Extra supported format
            p3 = dict(base_policy)
            p3["supported_formats"] = list(base_policy["supported_formats"]) + ["yaml"]
            tmp_p.write_text(json.dumps(p3), encoding="utf-8")
            g3 = PublicArtifactGuard(policy_path=tmp_p)
            self.assertIsNotNone(g3.policy_error)
            self.assertEqual(g3.policy_error.code, "error.invalid_policy")

    def test_s3_r12_r13_sensitive_filename_sanitization_in_reports(self) -> None:
        """P1-R1 & R12/R13: Sensitive filenames in relative and absolute paths are masked in text and JSON reports."""
        with tempfile.TemporaryDirectory() as tmp_dir:
            # File named with synthetic serial
            serial_file = Path(tmp_dir) / "device_serial_12345.json"
            serial_file.write_text(json.dumps({"status": "PASS", "data": "clean"}), encoding="utf-8")
            res_serial = self.guard.check(serial_file)
            self.assertTrue(res_serial.is_clean)
            text_rep = public_artifact_guard.format_text_report(res_serial)
            json_rep = public_artifact_guard.format_json_report(res_serial)
            self.assertNotIn("device_serial_12345", text_rep)
            self.assertNotIn("device_serial_12345", json_rep)
            self.assertIn("<artifact>", text_rep)
            self.assertIn("<artifact>", json_rep)

            # File named with synthetic VIN
            vin_file = Path(tmp_dir) / "TELLTALE0TEST0001.json"
            vin_file.write_text(json.dumps({"status": "PASS"}), encoding="utf-8")
            res_vin = self.guard.check(vin_file)
            text_vin = public_artifact_guard.format_text_report(res_vin)
            json_vin = public_artifact_guard.format_json_report(res_vin)
            self.assertNotIn("TELLTALE0TEST0001", text_vin)
            self.assertNotIn("TELLTALE0TEST0001", json_vin)
            self.assertIn("<artifact>", text_vin)
            self.assertIn("<artifact>", json_vin)


    def test_s3_r14_cli_invalid_arguments_stderr_non_leak(self) -> None:
        """P1-R1 & R14: CLI argument errors exit 2 and output sanitized message without echoing raw sentinel arguments."""
        sentinels = [
            ("check", "--classification", "SECRET_SENTINEL_CLASSIFICATION", str(FIXTURES_DIR / "json/clean_public_summary.json")),
            ("check", "--format", "SECRET_SENTINEL_FORMAT", str(FIXTURES_DIR / "json/clean_public_summary.json")),
            ("check", "--max-bytes", "NOT_AN_INT_SENTINEL", str(FIXTURES_DIR / "json/clean_public_summary.json")),
        ]
        for cmd_args in sentinels:
            cmd = [sys.executable, str(TOOL_DIR / "public_artifact_guard.py")] + list(cmd_args)
            proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
            self.assertEqual(proc.returncode, 2)
            self.assertEqual(proc.stderr, "[FAIL] Invalid command-line arguments.\n")
            for token in cmd_args:
                if "SECRET" in token or "SENTINEL" in token:
                    self.assertNotIn(token, proc.stderr)
                    self.assertNotIn(token, proc.stdout)


class TestPublicArtifactGuardMutations(unittest.TestCase):
    """Verifies mutation controls S3-M1 through S3-M7 with real production method monkeypatching."""

    def test_s3_m1_direct_vin_bypass_mutation(self) -> None:
        """S3-M1: Disabling direct VIN detection causes targeted negative test to turn RED."""
        acc = TestPublicArtifactGuardAcceptance()
        acc.setUp()
        orig = public_artifact_guard._is_vin_key
        try:
            public_artifact_guard._is_vin_key = lambda k: False
            with self.assertRaises(AssertionError):
                acc.test_s3_a4_plain_vin_detected()
        finally:
            public_artifact_guard._is_vin_key = orig
        acc.test_s3_a4_plain_vin_detected()

    def test_s3_m2_fragmented_hex_bypass_mutation(self) -> None:
        """S3-M2: Disabling hex ASCII decoding causes fragmented/hex canaries to turn RED."""
        acc = TestPublicArtifactGuardAcceptance()
        acc.setUp()
        orig = public_artifact_guard._try_hex_ascii_vin
        try:
            public_artifact_guard._try_hex_ascii_vin = lambda s: False
            with self.assertRaises(AssertionError):
                acc.test_s3_a5_fragmented_and_hex_vin_detected()
        finally:
            public_artifact_guard._try_hex_ascii_vin = orig
        acc.test_s3_a5_fragmented_and_hex_vin_detected()

    def test_s3_m2_plain_segment_reassembly_bypass_mutation(self) -> None:
        """S3-M2 (sub): Disabling plain segment reassembly causes fragmented VIN canary to turn RED."""
        acc = TestPublicArtifactGuardAcceptance()
        acc.setUp()
        orig_exact = public_artifact_guard.VIN_EXACT_RE
        orig_substr = public_artifact_guard.VIN_SUBSTR_RE
        try:
            public_artifact_guard.VIN_EXACT_RE = re.compile(r"^$")
            public_artifact_guard.VIN_SUBSTR_RE = re.compile(r"^$")
            with self.assertRaises(AssertionError):
                acc.test_s3_a5_fragmented_and_hex_vin_detected()
        finally:
            public_artifact_guard.VIN_EXACT_RE = orig_exact
            public_artifact_guard.VIN_SUBSTR_RE = orig_substr
        acc.test_s3_a5_fragmented_and_hex_vin_detected()

    def test_s3_m3_device_identity_bypass_mutation(self) -> None:
        """S3-M3: Disabling device UUID detection causes device negative test to turn RED."""
        acc = TestPublicArtifactGuardAcceptance()
        acc.setUp()
        orig = public_artifact_guard._is_device_uuid_key
        try:
            public_artifact_guard._is_device_uuid_key = lambda k: False
            with self.assertRaises(AssertionError):
                acc.test_s3_a6_device_identity_and_plate_detected()
        finally:
            public_artifact_guard._is_device_uuid_key = orig
        acc.test_s3_a6_device_identity_and_plate_detected()

    def test_s3_m3_mac_bypass_mutation(self) -> None:
        """S3-M3 (sub): Disabling MAC detection causes MAC negative test to turn RED."""
        acc = TestPublicArtifactGuardAcceptance()
        acc.setUp()
        orig = public_artifact_guard.MAC_RE
        try:
            public_artifact_guard.MAC_RE = re.compile(r"^$")
            with self.assertRaises(AssertionError):
                acc.test_s3_a6_device_identity_and_plate_detected()
        finally:
            public_artifact_guard.MAC_RE = orig
        acc.test_s3_a6_device_identity_and_plate_detected()

    def test_s3_m3_device_serial_bypass_mutation(self) -> None:
        """S3-M3 (sub): Disabling device serial detection causes serial negative test to turn RED."""
        acc = TestPublicArtifactGuardAcceptance()
        acc.setUp()
        orig_re = public_artifact_guard.DEVICE_SERIAL_LOG_RE
        orig_fn = public_artifact_guard._is_device_serial_key
        try:
            public_artifact_guard.DEVICE_SERIAL_LOG_RE = re.compile(r"^$")
            public_artifact_guard._is_device_serial_key = lambda k: False
            with self.assertRaises(AssertionError):
                acc.test_s3_a6_device_identity_and_plate_detected()
        finally:
            public_artifact_guard.DEVICE_SERIAL_LOG_RE = orig_re
            public_artifact_guard._is_device_serial_key = orig_fn
        acc.test_s3_a6_device_identity_and_plate_detected()

    def test_s3_m4_location_path_correlation_bypass_mutation(self) -> None:
        """S3-M4: Disabling GPS dict checking causes location negative test to turn RED."""
        acc = TestPublicArtifactGuardAcceptance()
        acc.setUp()
        orig = public_artifact_guard.PublicArtifactGuard._check_dict_gps
        try:
            public_artifact_guard.PublicArtifactGuard._check_dict_gps = lambda self, d, p, f: None
            with self.assertRaises(AssertionError):
                acc.test_s3_a7_gps_and_timestamp_correlation_detected()
        finally:
            public_artifact_guard.PublicArtifactGuard._check_dict_gps = orig
        acc.test_s3_a7_gps_and_timestamp_correlation_detected()

    def test_s3_m4_user_path_bypass_mutation(self) -> None:
        """S3-M4 (sub): Disabling user home path detection causes user path negative test to turn RED."""
        acc = TestPublicArtifactGuardAcceptance()
        acc.setUp()
        orig_unix = public_artifact_guard.USER_PATH_UNIX_RE
        orig_win = public_artifact_guard.USER_PATH_WIN_RE
        try:
            public_artifact_guard.USER_PATH_UNIX_RE = re.compile(r"^$")
            public_artifact_guard.USER_PATH_WIN_RE = re.compile(r"^$")
            with self.assertRaises(AssertionError):
                acc.test_s3_a8_synthetic_user_paths_detected()
        finally:
            public_artifact_guard.USER_PATH_UNIX_RE = orig_unix
            public_artifact_guard.USER_PATH_WIN_RE = orig_win
        acc.test_s3_a8_synthetic_user_paths_detected()

    def test_s3_m4_timestamp_identity_correlation_bypass_mutation(self) -> None:
        """S3-M4 (sub): Disabling timestamp+identity correlation causes correlation test to turn RED."""
        acc = TestPublicArtifactGuardAcceptance()
        acc.setUp()
        orig = public_artifact_guard.PublicArtifactGuard._check_dict_correlation
        try:
            public_artifact_guard.PublicArtifactGuard._check_dict_correlation = lambda self, d, p, f: None
            with self.assertRaises(AssertionError):
                acc.test_s3_a7_gps_and_timestamp_correlation_detected()
        finally:
            public_artifact_guard.PublicArtifactGuard._check_dict_correlation = orig
        acc.test_s3_a7_gps_and_timestamp_correlation_detected()

    def test_s3_m5_exception_leakage_mutation(self) -> None:
        """S3-M5: Emitting raw sensitive token in report output causes non-leak test to turn RED."""
        acc = TestPublicArtifactGuardAcceptance()
        acc.setUp()
        orig = public_artifact_guard.format_text_report
        try:
            public_artifact_guard.format_text_report = lambda res: "leaked TELLTALE0TEST0001"
            with self.assertRaises(AssertionError):
                acc.test_s3_a9_findings_and_exceptions_sentinel_non_leak()
        finally:
            public_artifact_guard.format_text_report = orig
        acc.test_s3_a9_findings_and_exceptions_sentinel_non_leak()

    def test_s3_m6_classification_fail_open_mutation(self) -> None:
        """S3-M6: Permitting private-raw to publish causes publication gate test to turn RED."""
        acc = TestPublicArtifactGuardAcceptance()
        acc.setUp()
        orig = public_artifact_guard.PublicArtifactGuard.check

        def mutated_check(self, target_path, classification="public-summary", format_hint="auto"):
            res = orig(self, target_path, classification=classification, format_hint=format_hint)
            if classification == "private-raw":
                return public_artifact_guard.GuardResult(res.target_path, classification, True, [], [])
            return res

        try:
            public_artifact_guard.PublicArtifactGuard.check = mutated_check
            with self.assertRaises(AssertionError):
                acc.test_s3_a12_classification_fail_closed()
        finally:
            public_artifact_guard.PublicArtifactGuard.check = orig
        acc.test_s3_a12_classification_fail_closed()

    def test_s3_m7_over_redaction_regression_mutation(self) -> None:
        """S3-M7: Injecting spurious findings on clean summary causes negative control test to turn RED."""
        acc = TestPublicArtifactGuardAcceptance()
        acc.setUp()
        orig = public_artifact_guard.PublicArtifactGuard._walk_json

        def mutated_walk(self, obj, path_prefix, findings, errors, *args, **kwargs):
            orig(self, obj, path_prefix, findings, errors, *args, **kwargs)
            findings.append(public_artifact_guard.Finding("vehicle.vin.plain", "json", "over_redacted", "rule", "fake"))

        try:
            public_artifact_guard.PublicArtifactGuard._walk_json = mutated_walk
            with self.assertRaises(AssertionError):
                acc.test_s3_a10_clean_public_summary_negative_controls_stay_green()
        finally:
            public_artifact_guard.PublicArtifactGuard._walk_json = orig
        acc.test_s3_a10_clean_public_summary_negative_controls_stay_green()


if __name__ == "__main__":
    unittest.main()
