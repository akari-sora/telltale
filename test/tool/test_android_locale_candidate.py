#!/usr/bin/env python3
"""Batch 1L-C1b-N1: Android API 33+ Native Locale Candidate Verification Suite.

Tests matrix N00-N07 per Task TELLTALE-1L-C1B-N1-ANDROID-LOCALE-CANDIDATE
(Refs #36, #40, #34):
- N00: Candidate identity, source/tree provenance, binary hash, package, flavor, signature, target OS.
- N01: Android 13+ manifest & localeConfig discoverability (en, zh-Hant, de).
- N02: OS -> App locale sync (en/zh Connect screen markers).
- N03: App LanguagePicker -> OS sync & loop prevention.
- N04: Follow-system preference reset & empty override behavior.
- N05: Process idle restart state retention (no cross-APK pollution).
- N06: Original system locale restoration & teardown.
- N07: Negative controls (tampered binary, bad exit, missing cases, bad hash, wrong device).
"""

from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool" / "l10n_rig"))

from android_os_locale import (  # noqa: E402
    CANDIDATE_CASE_IDS,
    GateError,
    main,
    validate_android_os_locale_report,
    validate_candidate_locale_report,
)


def _candidate_pass(**overrides):
    report = {
        "lane": "android-os-locale",
        "profile": "candidate-native-locale",
        "provenanceLevel": "NATIVE_LOCALE_CANDIDATE_N1_ACCEPTED",
        "device": "emulator-5554",
        "fingerprint": "google/sdk_gphone64_arm64/emu64a:14/UPB2.230407.019/10141209:user/release-keys",
        "target_api_level": 34,
        "candidate_sha256": "a" * 64,
        "source_sha": "b" * 40,
        "tree_sha": "c" * 40,
        "package": "com.cbstudio.telltale.rig",
        "flavor": "rig",
        "version_name": "1.0.13-rig",
        "version_code": 10013,
        "signature_digest": "d" * 64,
        "manifest_locale_config_valid": True,
        "supported_locales": ["en", "zh-Hant", "de"],
        "english_seen": True,
        "chinese_seen": True,
        "os_to_app_sync_verified": True,
        "app_to_os_sync_verified": True,
        "sync_loop_prevented": True,
        "follow_system_verified": True,
        "process_recreated": True,
        "state_retained": True,
        "teardown_restored": True,
        "exit": 0,
        "case_ids": list(CANDIDATE_CASE_IDS),
        "screenshots": {
            "en-US": "1" * 64,
            "zh-Hant-TW": "2" * 64,
        },
        "command": ["adb", "-s", "emulator-5554", "shell", "cmd", "locale"],
    }
    report.update(overrides)
    return report


class AndroidLocaleCandidateTest(unittest.TestCase):
    # N00: Provenance & Candidate Identity
    def test_n00_candidate_provenance_success(self):
        report = _candidate_pass()
        validated = validate_candidate_locale_report(report)
        self.assertEqual(validated["device"], "emulator-5554")
        self.assertEqual(validated["candidate_sha256"], "a" * 64)
        self.assertEqual(validated["provenanceLevel"], "NATIVE_LOCALE_CANDIDATE_N1_ACCEPTED")

    def test_n00_candidate_provenance_tampered_sha_rejected(self):
        report = _candidate_pass(candidate_sha256="z" * 64)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("candidate_sha256", str(ctx.exception))

    def test_n00_candidate_provenance_all_zero_sha_rejected(self):
        report = _candidate_pass(candidate_sha256="0" * 64)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("all-zero candidate_sha256", str(ctx.exception))

    def test_n00_candidate_provenance_mismatched_expected_sha_rejected(self):
        report = _candidate_pass(candidate_sha256="a" * 64)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report, expected_candidate_sha="f" * 64)
        self.assertIn("does not match expected", str(ctx.exception))

    def test_n00_candidate_provenance_mismatched_source_sha_rejected(self):
        report = _candidate_pass(source_sha="b" * 40)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report, expected_source_sha="e" * 40)
        self.assertIn("source_sha", str(ctx.exception))

    def test_n00_candidate_provenance_mismatched_tree_sha_rejected(self):
        report = _candidate_pass(tree_sha="c" * 40)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report, expected_tree_sha="e" * 40)
        self.assertIn("tree_sha", str(ctx.exception))

    def test_n00_candidate_provenance_field_candidate_success(self):
        report = _candidate_pass(package="com.cbstudio.telltale", flavor="field")
        validated = validate_candidate_locale_report(report)
        self.assertEqual(validated["package"], "com.cbstudio.telltale")
        self.assertEqual(validated["flavor"], "field")

    def test_n00_candidate_provenance_wrong_package_rejected(self):
        report = _candidate_pass(package="com.example.other")
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("package must be", str(ctx.exception))

    def test_n00_candidate_provenance_wrong_flavor_rejected(self):
        report = _candidate_pass(flavor="production")
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("flavor must be 'rig' or 'field'", str(ctx.exception))

    def test_n00_candidate_provenance_mismatched_package_and_flavor_rejected(self):
        report = _candidate_pass(package="com.cbstudio.telltale", flavor="rig")
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("incompatible with flavor", str(ctx.exception))

    def test_n00_candidate_provenance_api_level_under_33_rejected(self):
        report = _candidate_pass(target_api_level=32)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("requires Android API 33+", str(ctx.exception))

    def test_n00_candidate_provenance_field_phone_refused(self):
        report = _candidate_pass(device="R5CX10VFFBA")
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("refuses the field phone", str(ctx.exception))

    def test_n00_candidate_provenance_wrong_emulator_refused(self):
        report = _candidate_pass(device="emulator-5556")
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("not the disposable AOSP emulator", str(ctx.exception))

    # N01: Manifest and LocaleConfig
    def test_n01_manifest_locale_config_valid(self):
        report = _candidate_pass()
        validated = validate_candidate_locale_report(report)
        self.assertTrue(validated["manifest_locale_config_valid"])
        self.assertIn("zh-Hant", validated["supported_locales"])

    def test_n01_manifest_locale_config_flag_false_rejected(self):
        report = _candidate_pass(manifest_locale_config_valid=False)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("N01 failed: manifest localeConfig", str(ctx.exception))

    def test_n01_manifest_locale_config_missing_locales_rejected(self):
        report = _candidate_pass(supported_locales=["en"])
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("N01 failed: supported_locales must include en and zh-Hant", str(ctx.exception))

    # N02: OS -> App Sync
    def test_n02_os_to_app_sync_missing_chinese_rejected(self):
        report = _candidate_pass(chinese_seen=False)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("N02 failed: Traditional Chinese", str(ctx.exception))

    def test_n02_os_to_app_sync_missing_english_rejected(self):
        report = _candidate_pass(english_seen=False)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("N02 failed: English", str(ctx.exception))

    def test_n02_os_to_app_sync_flag_false_rejected(self):
        report = _candidate_pass(os_to_app_sync_verified=False)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("N02 failed: OS->App sync was not verified", str(ctx.exception))

    # N03: App -> OS Sync
    def test_n03_app_to_os_sync_missing_sync_rejected(self):
        report = _candidate_pass(app_to_os_sync_verified=False)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("N03 failed: App->OS sync", str(ctx.exception))

    def test_n03_app_to_os_sync_loop_not_prevented_rejected(self):
        report = _candidate_pass(sync_loop_prevented=False)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("N03 failed: sync loop prevention", str(ctx.exception))

    # N04: Follow System
    def test_n04_follow_system_missing_rejected(self):
        report = _candidate_pass(follow_system_verified=False)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("N04 failed: follow-system", str(ctx.exception))

    # N05: Process Recreation & Retention
    def test_n05_idle_restart_recreation_missing_rejected(self):
        report = _candidate_pass(process_recreated=False)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("N05 failed: process recreation", str(ctx.exception))

    def test_n05_idle_restart_state_retention_missing_rejected(self):
        report = _candidate_pass(state_retained=False)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("N05 failed: state retention", str(ctx.exception))

    # N06: Teardown & Restoration
    def test_n06_teardown_restoration_missing_rejected(self):
        report = _candidate_pass(teardown_restored=False)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("N06 failed: teardown restoration", str(ctx.exception))

    # N07: Negative Controls
    def test_n07_nonzero_exit_rejected(self):
        report = _candidate_pass(exit=1)
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("nonzero exit", str(ctx.exception))

    def test_n07_missing_case_ids_rejected(self):
        report = _candidate_pass(case_ids=["N00_candidate_provenance"])
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("missing required case IDs", str(ctx.exception))

    def test_n07_missing_screenshots_rejected(self):
        report = _candidate_pass(screenshots={"en-US": "1" * 64})
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("screenshots must cover", str(ctx.exception))

    def test_n07_all_zero_screenshot_rejected(self):
        report = _candidate_pass(screenshots={"en-US": "0" * 64, "zh-Hant-TW": "2" * 64})
        with self.assertRaises(GateError) as ctx:
            validate_candidate_locale_report(report)
        self.assertIn("screenshot hash invalid", str(ctx.exception))

    # Routing through validate_android_os_locale_report
    def test_routing_candidate_profile(self):
        report = _candidate_pass()
        validated = validate_android_os_locale_report(report)
        self.assertEqual(validated["provenanceLevel"], "NATIVE_LOCALE_CANDIDATE_N1_ACCEPTED")

    # Offline CLI validation
    def test_cli_offline_report_validation_success(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            report_file = Path(tmpdir) / "candidate_report.json"
            report_file.write_text(json.dumps(_candidate_pass()), encoding="utf-8")
            exit_code = main(["--report", str(report_file)])
            self.assertEqual(exit_code, 0)

    def test_cli_offline_report_validation_failure(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            report_file = Path(tmpdir) / "candidate_report.json"
            report_file.write_text(json.dumps(_candidate_pass(exit=1)), encoding="utf-8")
            exit_code = main(["--report", str(report_file)])
            self.assertEqual(exit_code, 1)


if __name__ == "__main__":
    unittest.main()
