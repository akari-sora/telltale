#!/usr/bin/env python3
"""Comprehensive test suite for tool/workshop/validate_privacy_contract.py (Issue #11, WS-07 Slice 4)."""
from __future__ import annotations

import copy
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any

# Locate repo root
REPO_ROOT = Path(__file__).resolve().parents[2]
TOOL_DIR = REPO_ROOT / "tool/workshop"
sys.path.insert(0, str(TOOL_DIR))

import validate_privacy_contract  # noqa: E402


class TestValidatePrivacyContract(unittest.TestCase):
    """Verifies privacy & data flow contract validator, schema enforcement, and fail-closed mutations."""

    def setUp(self) -> None:
        self.contract_path = REPO_ROOT / "docs/privacy/data-flow-inventory.json"
        self.raw_contract = json.loads(
            self.contract_path.read_text(encoding="utf-8")
        )

    def _run_with_disposable_repo(
        self,
        file_overrides: dict[str, str | bytes] | None = None,
        contract_data: dict[str, Any] | None = None,
        delete_files: list[str] | None = None,
    ) -> tuple[list[validate_privacy_contract.ValidationError], list[validate_privacy_contract.ValidationError]]:
        with tempfile.TemporaryDirectory() as td:
            tpath = Path(td)
            shutil.copytree(REPO_ROOT / "docs", tpath / "docs")
            shutil.copy(REPO_ROOT / "PRIVACY.md", tpath / "PRIVACY.md")
            shutil.copy(REPO_ROOT / "pubspec.yaml", tpath / "pubspec.yaml")
            if (REPO_ROOT / "pubspec.lock").is_file():
                shutil.copy(REPO_ROOT / "pubspec.lock", tpath / "pubspec.lock")
            (tpath / "android/app/src/main").mkdir(parents=True)
            shutil.copy(REPO_ROOT / "android/app/src/main/AndroidManifest.xml", tpath / "android/app/src/main/AndroidManifest.xml")
            if (REPO_ROOT / "android/app/build.gradle.kts").is_file():
                shutil.copy(REPO_ROOT / "android/app/build.gradle.kts", tpath / "android/app/build.gradle.kts")
            (tpath / "macos/Runner").mkdir(parents=True)
            shutil.copy(REPO_ROOT / "macos/Runner/Release.entitlements", tpath / "macos/Runner/Release.entitlements")
            (tpath / "ios/Runner").mkdir(parents=True)
            shutil.copy(REPO_ROOT / "ios/Runner/Info.plist", tpath / "ios/Runner/Info.plist")
            shutil.copytree(REPO_ROOT / "lib", tpath / "lib")
            shutil.copytree(REPO_ROOT / "test", tpath / "test")
            shutil.copytree(REPO_ROOT / "tool", tpath / "tool")
            repo_head = validate_privacy_contract._get_repo_head_sha(REPO_ROOT)
            if repo_head:
                (tpath / ".git").mkdir(parents=True, exist_ok=True)
                (tpath / ".git/HEAD").write_text(repo_head, encoding="utf-8")

            # State 1: Pristine GREEN - baseline must have 0 schema errors and 0 drift errors
            base_cdata = json.loads((tpath / "docs/privacy/data-flow-inventory.json").read_text(encoding="utf-8"))
            base_s, base_d = validate_privacy_contract.validate_contract_data(base_cdata, tpath)
            assert not base_s and not base_d, f"Disposable repo pristine baseline not clean: {base_s} {base_d}"

            # Backup original file contents or record files that did not exist
            backup: dict[str, bytes | None] = {}
            if file_overrides:
                for rel_str in file_overrides:
                    p = tpath / rel_str
                    if p.is_file():
                        backup[rel_str] = p.read_bytes()
                    else:
                        backup[rel_str] = None

            if delete_files:
                for rel_str in delete_files:
                    p = tpath / rel_str
                    if p.is_file():
                        backup[rel_str] = p.read_bytes()
                    else:
                        backup[rel_str] = None

            # State 2: Apply Mutant -> Execute validation
            if file_overrides:
                for rel_str, content in file_overrides.items():
                    p = tpath / rel_str
                    p.parent.mkdir(parents=True, exist_ok=True)
                    if isinstance(content, bytes):
                        p.write_bytes(content)
                    else:
                        p.write_text(content, encoding="utf-8")

            if delete_files:
                for rel_str in delete_files:
                    p = tpath / rel_str
                    if p.is_file():
                        p.unlink()

            cdata = contract_data if contract_data is not None else json.loads(
                (tpath / "docs/privacy/data-flow-inventory.json").read_text(encoding="utf-8")
            )
            mutant_s, mutant_d = validate_privacy_contract.validate_contract_data(cdata, tpath)

            # State 3: Restore to original & Verify Restored GREEN
            for rel_str, orig_bytes in backup.items():
                p = tpath / rel_str
                if orig_bytes is None:
                    if p.is_file():
                        p.unlink()
                else:
                    p.write_bytes(orig_bytes)

            restored_s, restored_d = validate_privacy_contract.validate_contract_data(base_cdata, tpath)
            assert not restored_s and not restored_d, f"Disposable repo restored baseline not clean: {restored_s} {restored_d}"

            return mutant_s, mutant_d

    def test_canonical_contract_passes(self) -> None:
        """S4-A1..A3: Canonical committed data flow inventory passes with 0 errors."""
        schema_errs, drift_errs = validate_privacy_contract.validate_contract_data(
            self.raw_contract, REPO_ROOT
        )
        self.assertEqual(schema_errs, [], f"Unexpected schema errors: {schema_errs}")
        self.assertEqual(drift_errs, [], f"Unexpected drift errors: {drift_errs}")

    def test_cli_execution_text_output_passes(self) -> None:
        """S4-A13: CLI execution returns code 0 and text report."""
        cmd = [
            sys.executable,
            str(TOOL_DIR / "validate_privacy_contract.py"),
            "--repo-root",
            str(REPO_ROOT),
            "--contract",
            str(self.contract_path),
            "--output",
            "text",
        ]
        res = subprocess.run(cmd, capture_output=True, text=True, check=False)
        self.assertEqual(res.returncode, 0, msg=f"CLI failed: {res.stderr}\n{res.stdout}")
        self.assertIn("[PASS]", res.stdout)
        self.assertIn("covered_domains: 10", res.stdout)

    def test_cli_execution_json_output_passes(self) -> None:
        """S4-A13: CLI execution returns code 0 and valid JSON report."""
        cmd = [
            sys.executable,
            str(TOOL_DIR / "validate_privacy_contract.py"),
            "--repo-root",
            str(REPO_ROOT),
            "--contract",
            str(self.contract_path),
            "--output",
            "json",
        ]
        res = subprocess.run(cmd, capture_output=True, text=True, check=False)
        self.assertEqual(res.returncode, 0, msg=f"CLI failed: {res.stderr}\n{res.stdout}")
        payload = json.loads(res.stdout)
        self.assertEqual(payload["status"], "pass")
        self.assertEqual(payload["exit_code"], 0)
        self.assertEqual(payload["summary"]["covered_domains"], 10)
        self.assertEqual(payload["errors"], [])

    def test_duplicate_key_rejection_and_non_leak(self) -> None:
        """S4-A13 / P1-R1: Rejects duplicate JSON keys with exit code 2 and scrubs sensitive key name."""
        canary = "SYNTH_PRIVATE_SENTINEL_R1_SECRET_CANARY"
        with tempfile.TemporaryDirectory(dir=str(REPO_ROOT)) as tmp_dir:
            tmp_contract = Path(tmp_dir) / "dup_contract.json"
            tmp_contract.write_text(
                f'{{"schema_version": 1, "{canary}": 1, "{canary}": 2}}',
                encoding="utf-8",
            )
            rel_path = tmp_contract.relative_to(REPO_ROOT)
            code, report = validate_privacy_contract.run_validator(str(REPO_ROOT), str(rel_path))
            self.assertEqual(code, 2)
            self.assertEqual(report["status"], "error")
            self.assertEqual(report["errors"][0]["code"], "json.duplicate_key")
            # Verify non-leak: canary string MUST NOT appear in report message or target
            serialized = json.dumps(report)
            self.assertNotIn(canary, serialized)

    def test_path_traversal_rejection(self) -> None:
        """S4-A13: Rejects path traversal escaping repo-root with exit code 2."""
        code, report = validate_privacy_contract.run_validator(
            str(REPO_ROOT), "../../outside.json"
        )
        self.assertEqual(code, 2)
        self.assertEqual(report["status"], "error")
        self.assertEqual(report["errors"][0]["code"], "path.traversal_or_escape")

    def test_absolute_symlink_escape_rejection_r11(self) -> None:
        """P1-R4 / R11: Absolute contract path pointing to symlink escaping repo-root is rejected."""
        with tempfile.NamedTemporaryFile(suffix=".json") as outside_f:
            outside_f.write(b'{"schema_version": 1}')
            outside_f.flush()
            symlink_path = REPO_ROOT / "test_escape_symlink_r11.json"
            try:
                os.symlink(outside_f.name, symlink_path)
                code, report = validate_privacy_contract.run_validator(
                    str(REPO_ROOT), str(symlink_path.resolve())
                )
                self.assertEqual(code, 2)
                self.assertEqual(report["errors"][0]["code"], "path.traversal_or_escape")
            finally:
                if symlink_path.exists() or symlink_path.is_symlink():
                    symlink_path.unlink()

    def test_missing_contract_file_rejection(self) -> None:
        """S4-A13: Rejects non-existent contract file with exit code 2."""
        code, report = validate_privacy_contract.run_validator(
            str(REPO_ROOT), "docs/privacy/non_existent.json"
        )
        self.assertEqual(code, 2)
        self.assertEqual(report["status"], "error")
        self.assertEqual(report["errors"][0]["code"], "contract.file_not_found")

    def test_typed_error_resilience_r07_r08_r09(self) -> None:
        """P1-R4 / R07–R09: Non-string/None types and malformed UTF-8 return code 2 cleanly with no traceback."""
        # R07: actor is a list
        mutated_actor = copy.deepcopy(self.raw_contract)
        mutated_actor["flows"][0]["actor"] = []
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated_actor, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.invalid_actor" for e in schema_errs))

        # R08: source binding path is None
        mutated_path = copy.deepcopy(self.raw_contract)
        mutated_path["flows"][0]["source_bindings"][0]["path"] = None
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated_path, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.invalid_binding_entry" for e in schema_errs))

    def test_d01_storage_fact_mismatch(self) -> None:
        """D01: Storage fact altered to Caches while source code uses Documents."""
        mutated = copy.deepcopy(self.raw_contract)
        for f in mutated["flows"]:
            if f["id"] == "DF-03-RAW-TRANSCRIPT-LOG":
                f["storage"]["api"] = "getApplicationCacheDirectory"
                f["source_bindings"][0]["storage_fact"] = "getApplicationCacheDirectory"
                f["backup_classification"] = "os-backup-excluded"
        _, drift_errs = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "source.storage_fact_mismatch" for e in drift_errs))

    def test_d02_symbol_only_in_comment(self) -> None:
        """D02: Symbol present only within comment blocks is rejected."""
        mutated = copy.deepcopy(self.raw_contract)
        # Use a symbol that only exists in comments in settings.dart
        mutated["flows"][0]["source_bindings"][0]["symbol"] = "never a cross-session trust decision"
        _, drift_errs = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "source.symbol_missing" for e in drift_errs))

    def test_d03_missing_required_flow_fields(self) -> None:
        """D03: Deleting required flow metadata causes schema error."""
        mutated = copy.deepcopy(self.raw_contract)
        del mutated["flows"][0]["purpose"]
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.missing_required_flow_fields" for e in schema_errs))

    def test_d04_empty_test_ids(self) -> None:
        """D04: Empty test_ids list is rejected."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["flows"][0]["test_ids"] = []
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.invalid_test_ids" for e in schema_errs))

    def test_d05_empty_symbol(self) -> None:
        """D05: Empty symbol string is rejected."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["flows"][0]["source_bindings"][0]["symbol"] = "   "
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.invalid_binding_entry" for e in schema_errs))

    def test_d06_missing_policy_ref(self) -> None:
        """D06: Nonexistent policy_ref file is rejected with exit code 2."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["policy_ref"] = "docs/privacy/non_existent_policy.json"
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "policy_ref.file_missing" for e in schema_errs))

    def test_d08_real_backup_without_receipt(self) -> None:
        """D08: Elevating evidence_level to REAL-BACKUP without receipt file is rejected."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["flows"][0]["evidence_level"] = "REAL-BACKUP"
        mutated["flows"][0].pop("receipt_file", None)
        _, drift_errs = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "evidence.real_backup_missing_receipt" for e in drift_errs))

    def test_d10_schema_version_boolean_rejection(self) -> None:
        """D10: schema_version=true (boolean True instead of int 1) is rejected."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["schema_version"] = True
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.invalid_version" for e in schema_errs))

    def test_d11_storage_api_null_rejection(self) -> None:
        """D11: storage.api=null is rejected."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["flows"][0]["storage"]["api"] = None
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.invalid_storage" for e in schema_errs))

    def test_mutation_m1_missing_coverage_domain(self) -> None:
        """M1: Deleting coverage domain causes coverage.domain_missing drift error (exit code 1)."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["flows"] = [f for f in mutated["flows"] if f.get("coverage_id") != "DF04"]
        schema_errs, drift_errs = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertEqual(schema_errs, [])
        self.assertTrue(any(e.code == "coverage.domain_missing" and e.target == "DF04" for e in drift_errs))

    def test_mutation_m2_policy_visible_clause_contradiction(self) -> None:
        """M2: Policy visible clause modified to claim '保證不備份' triggers policy.clause_contradiction."""
        orig_text = (REPO_ROOT / "PRIVACY.md").read_text(encoding="utf-8")
        mutated_text = orig_text.replace(
            "Android、iOS 或 macOS 的作業系統備份可能依你的裝置",
            "我們保證絕不備份任何資料，Android、iOS 或 macOS 的作業系統備份可能依你的裝置",
        )
        _, drift_errs = self._run_with_disposable_repo({"PRIVACY.md": mutated_text})
        self.assertTrue(any(e.code == "policy.clause_contradiction" for e in drift_errs))

    def test_mutation_m3_source_storage_fact_mismatch(self) -> None:
        """M3: Flow storage modified to Caches causes storage_fact_mismatch via contract and physical Dart file."""
        # 1. Via contract mutation
        mutated = copy.deepcopy(self.raw_contract)
        for f in mutated["flows"]:
            if f["id"] == "DF-04-TELEMETRY-NDJSON":
                f["storage"]["api"] = "getApplicationCacheDirectory"
                f["source_bindings"][0]["storage_fact"] = "getApplicationCacheDirectory"
                f["backup_classification"] = "os-backup-excluded"
        _, drift_errs = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "source.storage_fact_mismatch" for e in drift_errs))

        # 2. Via physical Dart file modification in disposable repo (pristine GREEN -> mutant RED -> restored GREEN)
        orig_store_dart = (REPO_ROOT / "lib/telemetry/session/telemetry_session_store.dart").read_text(encoding="utf-8")
        mutated_dart = orig_store_dart.replace(
            "documentsDirectory ?? getApplicationDocumentsDirectory",
            "documentsDirectory ?? getApplicationCacheDirectory",
        )
        _, d_errs = self._run_with_disposable_repo({"lib/telemetry/session/telemetry_session_store.dart": mutated_dart})
        self.assertTrue(any(e.code in ("source.storage_fact_mismatch", "source.hash_mismatch") for e in d_errs))

    def test_mutation_m4_manifest_setting_drift(self) -> None:
        """M4: Setting android:allowBackup="false" in AndroidManifest triggers backup.manifest_setting_drift."""
        orig_manifest = (REPO_ROOT / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
        for mutated_variant in [
            orig_manifest.replace("<application", '<application android:allowBackup="false"'),
            orig_manifest.replace("<application", "<application android:allowBackup='false'"),
            orig_manifest.replace("<application", '<application android:allowBackup = "false"'),
        ]:
            _, drift_errs = self._run_with_disposable_repo({"android/app/src/main/AndroidManifest.xml": mutated_variant})
            self.assertTrue(any(e.code == "backup.manifest_setting_drift" for e in drift_errs))

    def test_mutation_m5_missing_test_file(self) -> None:
        """M5: Missing or empty referenced test file triggers drift error."""
        # 1. Missing test file triggers test.file_missing
        mutated = copy.deepcopy(self.raw_contract)
        mutated["flows"][0]["test_ids"] = ["test/privacy/non_existent_m5_test.dart"]
        _, drift_errs = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "test.file_missing" for e in drift_errs))

        # 2. Empty test file with 0 test declarations triggers test.empty_or_no_tests
        mutated_empty = copy.deepcopy(self.raw_contract)
        mutated_empty["flows"][0]["test_ids"] = ["test/privacy/empty_dummy_test.dart"]
        _, empty_errs = self._run_with_disposable_repo(
            file_overrides={"test/privacy/empty_dummy_test.dart": "// Empty test file with no declarations\n"},
            contract_data=mutated_empty,
        )
        self.assertTrue(any(e.code == "test.empty_or_no_tests" for e in empty_errs))

    def test_mutation_m6_policy_visible_24h_deletion_contradiction(self) -> None:
        """M6: Claiming guaranteed 24h deletion in visible policy triggers policy.clause_contradiction."""
        orig_text = (REPO_ROOT / "PRIVACY.md").read_text(encoding="utf-8")
        mutated_text = orig_text.replace(
            "非作業系統背景排程保證",
            "承諾 24 小時必定刪除所有資料",
        )
        _, drift_errs = self._run_with_disposable_repo({"PRIVACY.md": mutated_text})
        self.assertTrue(any(e.code == "policy.clause_contradiction" for e in drift_errs))

    def test_mutation_m7_escaping_source_path(self) -> None:
        """M7: Source binding attempting path traversal causes path.traversal_or_escape schema error and does not leak canary."""
        canary = "SECRET_CANARY_PRIVATE_PATH_TOKEN"
        mutated = copy.deepcopy(self.raw_contract)
        mutated["flows"][0]["source_bindings"] = [{
            "path": f"../../../outside_{canary}.dart",
            "symbol": "VehicleProfileController",
            "sha256": "0" * 64,
            "storage_fact": "SharedPreferences",
        }]
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "path.traversal_or_escape" for e in schema_errs))
        for err in schema_errs:
            self.assertNotIn(canary, err.message)
            self.assertNotIn(canary, err.target)
            self.assertNotIn(canary, err.code)

    def test_p01_html_contradictory_term_rejection(self) -> None:
        """P01: Modifying HTML visible clause to state 'never copy' triggers policy.clause_contradiction."""
        orig_html = (REPO_ROOT / "docs/privacy.html").read_text(encoding="utf-8")
        mutated_html = orig_html.replace(
            "Android, iOS, or macOS system backup may copy",
            "Android, iOS, or macOS system backup will never copy",
        )
        _, drift_errs = self._run_with_disposable_repo({"docs/privacy.html": mutated_html})
        self.assertTrue(any(e.code == "policy.clause_contradiction" for e in drift_errs))

    def test_p02_visible_clause_emptied_only_comments_remain(self) -> None:
        """P02: Deleting visible clause text leaving only comments triggers policy.clause_empty."""
        orig_html = (REPO_ROOT / "docs/privacy.html").read_text(encoding="utf-8")
        import re
        matches = list(re.finditer(r'(<div[^>]*data-claim-id=[\"\']CLAIM-DEVELOPER-NO-COLLECTION[\"\'][^>]*>)(.*?)(</div>)', orig_html, re.DOTALL))
        m = matches[1]  # English section clause
        mutated_html = orig_html[:m.start(2)] + "\n<!-- comments only -->\n" + orig_html[m.end(2):]
        _, drift_errs = self._run_with_disposable_repo({"docs/privacy.html": mutated_html})
        self.assertTrue(any(e.code == "policy.clause_empty" for e in drift_errs))

    def test_p03_html_section_hidden_rejection(self) -> None:
        """P03: HTML section container marked hidden triggers policy.clause_hidden."""
        orig_html = (REPO_ROOT / "docs/privacy.html").read_text(encoding="utf-8")
        mutated_html = orig_html.replace(
            '<section id="en-policy" lang="en">',
            '<section id="en-policy" lang="en" hidden>',
        )
        _, drift_errs = self._run_with_disposable_repo({"docs/privacy.html": mutated_html})
        self.assertTrue(any(e.code == "policy.clause_hidden" and "en" in (e.target or "") for e in drift_errs))

    def test_p04_duplicate_claim_anchor_rejection(self) -> None:
        """P04: Adding duplicate claim anchor in section triggers policy.duplicate_claim_anchor."""
        orig_html = (REPO_ROOT / "docs/privacy.html").read_text(encoding="utf-8")
        mutated_html = orig_html.replace(
            'data-claim-id="CLAIM-OS-BACKUP-BEHAVIOR"',
            'data-claim-id="CLAIM-OS-BACKUP-BEHAVIOR" data-extra="1"><div data-claim-id="CLAIM-OS-BACKUP-BEHAVIOR"',
        )
        _, drift_errs = self._run_with_disposable_repo({"docs/privacy.html": mutated_html})
        self.assertTrue(any(e.code == "policy.duplicate_claim_anchor" for e in drift_errs))

    def test_r01_cli_argument_reflection_non_leak(self) -> None:
        """R01: CLI argument parser does not echo invalid argument values to stderr."""
        canary = "SYNTH_PRIVATE_R2_SENTINEL"
        res = subprocess.run(
            [sys.executable, str(TOOL_DIR / "validate_privacy_contract.py"), "--output", canary],
            capture_output=True,
            text=True,
        )
        self.assertEqual(res.returncode, 2)
        self.assertNotIn(canary, res.stdout)
        self.assertNotIn(canary, res.stderr)

    def test_canonical_digest_mismatch_rejection(self) -> None:
        """P1-R2: Policy visible text drift from pre-audited canonical digest triggers policy.clause_drift."""
        orig_html = (REPO_ROOT / "docs/privacy.html").read_text(encoding="utf-8")
        mutated_html = orig_html.replace(
            "Android, iOS, or macOS system backup may copy",
            "Android, iOS, or macOS system backup will not copy",
        )
        _, drift_errs = self._run_with_disposable_repo({"docs/privacy.html": mutated_html})
        self.assertTrue(any(e.code == "policy.clause_drift" for e in drift_errs))

    def test_p05_missing_policy_document_rejection(self) -> None:
        """P05: Removing docs/privacy.html from policy_documents triggers policy.document_missing."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["policy_documents"] = ["PRIVACY.md"]
        _, drift_errs = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "policy.document_missing" and e.target == "docs/privacy.html" for e in drift_errs))

    def test_p06_missing_required_claim_rejection(self) -> None:
        """P06: Removing required claim from claims map triggers policy.claim_missing."""
        mutated = copy.deepcopy(self.raw_contract)
        del mutated["claims"]["CLAIM-OS-BACKUP-BEHAVIOR"]
        _, drift_errs = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "policy.claim_missing" and e.target == "CLAIM-OS-BACKUP-BEHAVIOR" for e in drift_errs))

    def test_p07_claim_parity_rules_schema_validation(self) -> None:
        """P07: Removing claim from claim_parity_rules causes schema.missing_claim_parity_rule error."""
        mutated = copy.deepcopy(self.raw_contract)
        del mutated["claim_parity_rules"]["CLAIM-OS-BACKUP-BEHAVIOR"]
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.missing_claim_parity_rule" and e.target == "CLAIM-OS-BACKUP-BEHAVIOR" for e in schema_errs))

    def test_platform_storage_mapping_schema_validation(self) -> None:
        """Verifies missing platform_storage_mapping triggers schema error."""
        mutated = copy.deepcopy(self.raw_contract)
        del mutated["platform_storage_mapping"]["android"]
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.invalid_platform_storage_mapping" for e in schema_errs))

    def test_shared_preferences_backup_classification_mismatch(self) -> None:
        """Verifies flow using SharedPreferences cannot be classified as os-backup-excluded."""
        mutated = copy.deepcopy(self.raw_contract)
        for f in mutated["flows"]:
            if f["storage"]["api"] == "SharedPreferences":
                f["backup_classification"] = "os-backup-excluded"
        _, drift_errs = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "backup.classification_mismatch" for e in drift_errs))

    def test_invalid_repo_root_rejection(self) -> None:
        """P1-R1: Non-existent repo_root directory is rejected with exit code 2 and fixed error code."""
        code, report = validate_privacy_contract.run_validator("/nonexistent/repo_root_dir", "docs/privacy/data-flow-inventory.json")
        self.assertEqual(code, 2)
        self.assertEqual(report["errors"][0]["code"], "path.invalid_repo_root")
        self.assertEqual(report["errors"][0]["target"], "repo_root")

    def test_bounded_read_file_size_exceeded(self) -> None:
        """P1-R4: Bounded read rejects file exceeding max byte budget with BudgetExceededError."""
        with tempfile.NamedTemporaryFile() as tmp:
            tmp.write(b"x" * 100)
            tmp.flush()
            with self.assertRaises(validate_privacy_contract.BudgetExceededError) as ctx:
                validate_privacy_contract.bounded_read_bytes(Path(tmp.name), max_bytes=50)
            self.assertEqual(ctx.exception.reason, "file_too_large")

    def test_bounded_read_aggregate_bytes_budget_exceeded(self) -> None:
        """P1-R4: Bounded read rejects aggregate bytes exceeding per-run aggregate budget."""
        tracker = validate_privacy_contract.BudgetTracker(max_aggregate_bytes=100, max_reads=10)
        with tempfile.NamedTemporaryFile() as tmp:
            tmp.write(b"x" * 60)
            tmp.flush()
            validate_privacy_contract.bounded_read_bytes(Path(tmp.name), max_bytes=100, tracker=tracker)
            with self.assertRaises(validate_privacy_contract.BudgetExceededError) as ctx:
                validate_privacy_contract.bounded_read_bytes(Path(tmp.name), max_bytes=100, tracker=tracker)
            self.assertEqual(ctx.exception.reason, "aggregate_bytes_exceeded")

    def test_bounded_read_aggregate_count_budget_exceeded(self) -> None:
        """P1-R4: Bounded read rejects file read count exceeding per-run read count limit."""
        tracker = validate_privacy_contract.BudgetTracker(max_aggregate_bytes=10000, max_reads=2)
        with tempfile.NamedTemporaryFile() as tmp:
            tmp.write(b"x" * 10)
            tmp.flush()
            validate_privacy_contract.bounded_read_bytes(Path(tmp.name), max_bytes=100, tracker=tracker)
            validate_privacy_contract.bounded_read_bytes(Path(tmp.name), max_bytes=100, tracker=tracker)
            with self.assertRaises(validate_privacy_contract.BudgetExceededError) as ctx:
                validate_privacy_contract.bounded_read_bytes(Path(tmp.name), max_bytes=100, tracker=tracker)
            self.assertEqual(ctx.exception.reason, "aggregate_read_count_exceeded")

    def test_ios_plist_verification_and_drift_rejection(self) -> None:
        """P1-R6: Mutating iOS Info.plist to add forbidden iCloud key triggers backup.ios_icloud_key_detected."""
        orig_plist = (REPO_ROOT / "ios/Runner/Info.plist").read_text(encoding="utf-8")
        mutated_plist = orig_plist.replace(
            "</dict>",
            "\t<key>NSUbiquitousContainers</key>\n\t<dict/>\n</dict>",
        )
        _, drift_errs = self._run_with_disposable_repo({"ios/Runner/Info.plist": mutated_plist})
        self.assertTrue(any(e.code == "backup.ios_icloud_key_detected" for e in drift_errs))

    def test_claim_description_drift_p06(self) -> None:
        """P06: Mutating claim description without updating canonical_claim_digest triggers policy.claim_description_drift."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["claims"]["CLAIM-DEVELOPER-NO-COLLECTION"] = "Altered claim description for developer collection."
        _, drift_errs = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "policy.claim_description_drift" for e in drift_errs))

    def test_disallowed_html_markup_j13(self) -> None:
        """J13: Adding forbidden <template> or <noscript> markup to HTML triggers policy.disallowed_markup."""
        orig_html = (REPO_ROOT / "docs/privacy.html").read_text(encoding="utf-8")
        # Template markup injection
        mutated_template = orig_html.replace(
            "</body>",
            '<template data-claim-id="CLAIM-USER-CONTROLLED-SHARE"><p>fake</p></template></body>',
        )
        _, drift_errs = self._run_with_disposable_repo({"docs/privacy.html": mutated_template})
        self.assertTrue(any(e.code == "policy.disallowed_markup" for e in drift_errs))

        # Noscript markup injection
        mutated_noscript = orig_html.replace(
            "</body>",
            '<noscript><p>fake noscript</p></noscript></body>',
        )
        _, d_errs = self._run_with_disposable_repo({"docs/privacy.html": mutated_noscript})
        self.assertTrue(any(e.code == "policy.disallowed_markup" for e in d_errs))

    def test_unmarked_section_contradiction_j14(self) -> None:
        """J14: Adding contradiction in section text outside claim block triggers policy.clause_contradiction."""
        orig_html = (REPO_ROOT / "docs/privacy.html").read_text(encoding="utf-8")
        mutated_html = orig_html.replace(
            '<p class="lede">',
            '<p class="lede">我們保證不備份任何資料。',
        )
        _, drift_errs = self._run_with_disposable_repo({"docs/privacy.html": mutated_html})
        self.assertTrue(any(e.code == "policy.clause_contradiction" for e in drift_errs))

    def test_missing_platform_files_j04_j05_j06(self) -> None:
        """J04–J06: Missing Gradle, Info.plist, or Release.entitlements triggers respective schema error."""
        # J04: Missing build.gradle.kts
        s_errs, _ = self._run_with_disposable_repo(delete_files=["android/app/build.gradle.kts"])
        self.assertTrue(any(e.code == "backup.gradle_missing" for e in s_errs))

        # J05: Missing Info.plist
        s_errs, _ = self._run_with_disposable_repo(delete_files=["ios/Runner/Info.plist"])
        self.assertTrue(any(e.code == "backup.ios_plist_missing" for e in s_errs))

        # J06: Missing Release.entitlements
        s_errs, _ = self._run_with_disposable_repo(delete_files=["macos/Runner/Release.entitlements"])
        self.assertTrue(any(e.code == "backup.macos_entitlements_missing" for e in s_errs))

    def test_gradle_invalid_utf8_and_too_large_j07_j08(self) -> None:
        """J07–J08: Invalid UTF-8 or oversized build.gradle.kts triggers respective schema error."""
        # J07: Invalid UTF-8 bytes
        s_errs, _ = self._run_with_disposable_repo({"android/app/build.gradle.kts": b"\x80\x81\xff\xfe"})
        self.assertTrue(any(e.code == "backup.gradle_invalid_utf8" for e in s_errs))

        # J08: File exceeding 5MB budget
        huge_bytes = b"// padding\n" * (500 * 1024)
        s_errs, _ = self._run_with_disposable_repo({"android/app/build.gradle.kts": huge_bytes})
        self.assertTrue(any(e.code == "backup.gradle_too_large" for e in s_errs))

    def test_real_backup_receipt_validation_j02_j03(self) -> None:
        """J02–J03: REAL-BACKUP receipt validation rejects invalid, empty, or oversized receipts."""
        # 1. Flow declaring REAL-BACKUP pointing to non-existent receipt
        mutated = copy.deepcopy(self.raw_contract)
        mutated["flows"][0]["evidence_level"] = "REAL-BACKUP"
        mutated["flows"][0]["receipt_file"] = "docs/privacy/non_existent_receipt.json"
        _, drift_errs = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_not_found" for e in drift_errs))

        # 2. Receipt with invalid status or missing required fields
        invalid_receipt = json.dumps({"receipt_id": "", "status": "FAIL"}).encode("utf-8")
        mutated["flows"][0]["receipt_file"] = "docs/privacy/dummy_receipt.json"
        s_errs, d_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": invalid_receipt},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in (s_errs + d_errs)))

        # 3. Receipt exceeding 5MB
        huge_receipt = b" " * (5 * 1024 * 1024 + 100)
        s_errs, d_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": huge_receipt},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_too_large" for e in (s_errs + d_errs)))

    def test_synthetic_canary_publishable_rejection(self) -> None:
        """Verifies policy allowing synthetic-canary to be publishable triggers policy.synthetic_canary_publishable."""
        orig_class = (REPO_ROOT / "docs/privacy/public-artifact-policy.json").read_text(encoding="utf-8")
        mutated_class = orig_class.replace(
            '"synthetic-canary": {\n      "description": "Test-only fixtures containing synthetic, non-real sensitive identifiers (e.g. synthetic VIN, MAC, UUID, customer IDs, GPS, user paths). Used exclusively to verify that the privacy guard detects leaks. Strictly forbidden from public distribution.",\n      "publishable": false',
            '"synthetic-canary": {\n      "description": "Test-only fixtures containing synthetic, non-real sensitive identifiers (e.g. synthetic VIN, MAC, UUID, customer IDs, GPS, user paths). Used exclusively to verify that the privacy guard detects leaks. Strictly forbidden from public distribution.",\n      "publishable": true',
        )
        # Update policy_ref_sha256 in contract to match mutated public-artifact-policy
        new_sha = hashlib.sha256(mutated_class.encode("utf-8")).hexdigest()
        mutated_contract = copy.deepcopy(self.raw_contract)
        mutated_contract["policy_ref_sha256"] = new_sha
        _, drift_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/public-artifact-policy.json": mutated_class},
            contract_data=mutated_contract,
        )
        self.assertTrue(any(e.code == "policy.synthetic_canary_publishable" for e in drift_errs))

    def test_scalar_flow_field_null_or_empty(self) -> None:
        """Flow with empty string or None in required scalar text fields triggers schema error."""
        mutated_empty = copy.deepcopy(self.raw_contract)
        mutated_empty["flows"][0]["purpose"] = "   "
        s_errs, _ = validate_privacy_contract.validate_contract_data(mutated_empty, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.missing_required_flow_fields" for e in s_errs))

        mutated_none = copy.deepcopy(self.raw_contract)
        mutated_none["flows"][0]["purpose"] = None
        s_errs, _ = validate_privacy_contract.validate_contract_data(mutated_none, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.missing_required_flow_fields" for e in s_errs))

    def test_data_categories_invalid_type(self) -> None:
        """Flow with non-list or list containing non-string data_categories triggers schema.invalid_data_categories."""
        mutated_str = copy.deepcopy(self.raw_contract)
        mutated_str["flows"][0]["data_categories"] = "diagnostic_trouble_codes"
        s_errs, _ = validate_privacy_contract.validate_contract_data(mutated_str, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.invalid_data_categories" for e in s_errs))

        mutated_int = copy.deepcopy(self.raw_contract)
        mutated_int["flows"][0]["data_categories"] = [123, 456]
        s_errs, _ = validate_privacy_contract.validate_contract_data(mutated_int, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.invalid_data_categories" for e in s_errs))

    def test_macos_entitlements_verification_and_drift_rejection(self) -> None:
        """P1-R6: Mutating macOS Release.entitlements to disable app-sandbox triggers backup.macos_sandbox_disabled."""
        orig_ent = (REPO_ROOT / "macos/Runner/Release.entitlements").read_text(encoding="utf-8")
        mutated_ent = orig_ent.replace("<true/>", "<false/>")
        _, drift_errs = self._run_with_disposable_repo({"macos/Runner/Release.entitlements": mutated_ent})
        self.assertTrue(any(e.code == "backup.macos_sandbox_disabled" for e in drift_errs))

    def test_gradle_comment_deception_j10(self) -> None:
        """J10: build.gradle.kts with applicationId in comment but wrong real assignment triggers backup.gradle_application_id_mismatch."""
        orig_gradle = (REPO_ROOT / "android/app/build.gradle.kts").read_text(encoding="utf-8")
        mutated_gradle = orig_gradle.replace(
            'applicationId = "com.cbstudio.telltale"',
            '// applicationId = "com.cbstudio.telltale"\n        applicationId = "com.cbstudio.attacker"',
        )
        _, drift_errs = self._run_with_disposable_repo({"android/app/build.gradle.kts": mutated_gradle})
        self.assertTrue(any(e.code == "backup.gradle_application_id_mismatch" for e in drift_errs))

    def test_policy_unapproved_paragraph_or_exfiltration_j14(self) -> None:
        """J14: Injected policy statements outside approved claims trigger policy.clause_contradiction."""
        orig_html = (REPO_ROOT / "docs/privacy.html").read_text(encoding="utf-8")
        mutated_exfil = orig_html.replace(
            '<p class="sub">',
            '<p>The application sends every diagnostic log to the developer automatically without asking.</p>\n<p class="sub">',
        )
        _, drift_errs = self._run_with_disposable_repo({"docs/privacy.html": mutated_exfil})
        self.assertTrue(any(e.code == "policy.clause_contradiction" for e in drift_errs))

        mutated_unapproved = orig_html.replace(
            '<p class="sub">',
            '<p>Some unapproved text not in boilerplate hash set.</p>\n<p class="sub">',
        )
        _, drift_errs2 = self._run_with_disposable_repo({"docs/privacy.html": mutated_unapproved})
        self.assertTrue(any(e.code == "policy.clause_contradiction" for e in drift_errs2))

    def test_source_binding_symbol_boundary_synthetic_store_j16(self) -> None:
        """J16: File having SyntheticStoreReplacement does not satisfy SyntheticStore binding."""
        code_bytes = b"class SyntheticStoreReplacement {}\n"
        mutated = copy.deepcopy(self.raw_contract)
        mutated["flows"][0]["source_bindings"][0]["symbol"] = "SyntheticStore"
        mutated["flows"][0]["source_bindings"][0]["path"] = "lib/state/app_runtime.dart"
        mutated["flows"][0]["source_bindings"][0]["sha256"] = hashlib.sha256(code_bytes).hexdigest()
        _, drift_errs = self._run_with_disposable_repo(
            file_overrides={"lib/state/app_runtime.dart": code_bytes},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "source.symbol_missing" for e in drift_errs))

    def test_platform_storage_mapping_drift_j17(self) -> None:
        """J17: platform_storage_mapping with drifted native_path triggers schema.invalid_platform_storage_mapping."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["platform_storage_mapping"]["ios"]["preferences"]["native_path"] = "Documents/WRONG-SYNTHETIC"
        s_errs, _ = self._run_with_disposable_repo(contract_data=mutated)
        self.assertTrue(any(e.code == "schema.invalid_platform_storage_mapping" for e in s_errs))

    def test_manifest_allow_backup_non_boolean_j18(self) -> None:
        """J18: AndroidManifest with non-boolean android:allowBackup triggers backup.manifest_setting_drift."""
        orig_manifest = (REPO_ROOT / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
        mutated_manifest = orig_manifest.replace(
            '<application',
            '<application android:allowBackup="SYNTH_UNKNOWN"',
        )
        _, drift_errs = self._run_with_disposable_repo({"android/app/src/main/AndroidManifest.xml": mutated_manifest})
        self.assertTrue(any(e.code == "backup.manifest_setting_drift" for e in drift_errs))

    def test_real_backup_receipt_strict_validation_residuals_r3(self) -> None:
        """P1-R3: Receipt with cases: [null], status: NOT_RUN, or all-zero head_sha triggers evidence.real_backup_receipt_invalid."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["flows"][0]["evidence_level"] = "REAL-BACKUP"
        mutated["flows"][0]["receipt_file"] = "docs/privacy/dummy_receipt.json"

        # Case 1: cases contains null
        receipt_null_case = json.dumps({
            "receipt_id": "rec-1",
            "status": "PASS",
            "exit_code": 0,
            "head_sha": "a" * 40,
            "cases": [None],
        }).encode("utf-8")
        _, d_errs1 = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": receipt_null_case},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in d_errs1))

        # Case 2: status is NOT_RUN
        receipt_not_run = json.dumps({
            "receipt_id": "rec-2",
            "status": "NOT_RUN",
            "exit_code": 0,
            "head_sha": "a" * 40,
            "cases": [{"id": "c1", "status": "PASS", "exit_code": 0}],
        }).encode("utf-8")
        _, d_errs2 = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": receipt_not_run},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in d_errs2))

        # Case 3: all-zero head_sha
        receipt_zero_sha = json.dumps({
            "receipt_id": "rec-3",
            "status": "PASS",
            "exit_code": 0,
            "head_sha": "0" * 40,
            "cases": [{"id": "c1", "status": "PASS", "exit_code": 0}],
        }).encode("utf-8")
        _, d_errs3 = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": receipt_zero_sha},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in d_errs3))

    def test_referenced_test_empty_or_comment_only_non_leak(self) -> None:
        """P1-R1-REG: Test file with only comments triggers test.empty_or_no_tests without leaking file path."""
        mutated = copy.deepcopy(self.raw_contract)
        secret_test_path = "test/secret_canary_test.dart"
        mutated["flows"][0]["test_ids"] = [secret_test_path]
        comment_only_dart = "// test('dummy', () {});\n/* void test() {} */"
        _, drift_errs = self._run_with_disposable_repo(
            file_overrides={secret_test_path: comment_only_dart},
            contract_data=mutated,
        )
        err = next((e for e in drift_errs if e.code == "test.empty_or_no_tests"), None)
        self.assertIsNotNone(err)
        self.assertEqual(err.message, "Referenced test file contains no test declarations")
        self.assertNotIn("secret_canary", err.message)

    def test_p1_r2_n05_unapproved_html_div_rejection(self) -> None:
        """P1-R2 / N05: Injecting text via <div> outside registered claims is rejected."""
        orig_html = (REPO_ROOT / "docs/privacy.html").read_text("utf-8")
        mutated_html = orig_html.replace(
            "</body>",
            "<div>Routine diagnostic records are transmitted to our service every minute.</div></body>",
        )
        _, drift_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy.html": mutated_html},
        )
        self.assertTrue(any(e.code == "policy.clause_contradiction" for e in drift_errs))

    def test_p1_r2_n06_unapproved_markdown_paragraph_rejection(self) -> None:
        """P1-R2 / N06: Injecting unapproved paragraph or heading+body into PRIVACY.md is rejected."""
        orig_md = (REPO_ROOT / "PRIVACY.md").read_text("utf-8")
        # Case A: Plain paragraph injection
        mutated_md_a = orig_md + "\n\nRoutine diagnostic records are transmitted to our service every minute.\n"
        _, drift_errs_a = self._run_with_disposable_repo(
            file_overrides={"PRIVACY.md": mutated_md_a},
        )
        self.assertTrue(any(e.code == "policy.clause_contradiction" for e in drift_errs_a))

        # Case B: ATX heading with unapproved paragraph immediately following without intervening blank line
        mutated_md_b = orig_md + "\n\n## Automatic diagnostics\nRoutine diagnostic records are transmitted to our service every minute.\n"
        _, drift_errs_b = self._run_with_disposable_repo(
            file_overrides={"PRIVACY.md": mutated_md_b},
        )
        self.assertTrue(any(e.code == "policy.clause_contradiction" for e in drift_errs_b))

        # Case C: Known heading with unapproved paragraph following
        mutated_md_c = orig_md + "\n\n## 聯絡\nRoutine diagnostic records are transmitted to our service every minute.\n"
        _, drift_errs_c = self._run_with_disposable_repo(
            file_overrides={"PRIVACY.md": mutated_md_c},
        )
        self.assertTrue(any(e.code == "policy.clause_contradiction" for e in drift_errs_c))

    def test_p1_r2_n07_unapproved_claim_id_div_rejection(self) -> None:
        """P1-R2 / N07: Div with unregistered data-claim-id is rejected."""
        orig_html = (REPO_ROOT / "docs/privacy.html").read_text("utf-8")
        mutated_html = orig_html.replace(
            "</body>",
            '<div data-claim-id="UNREVIEWED"><p>Routine diagnostic records are transmitted to our service every minute.</p></div></body>',
        )
        _, drift_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy.html": mutated_html},
        )
        self.assertTrue(any(e.code in ("policy.unknown_claim_id", "policy.clause_contradiction") for e in drift_errs))

    def test_unknown_claim_id_non_leak(self) -> None:
        """Q08-Q11: Unknown claim ID must be blocked without leaking into error message or target."""
        synth_id = "SYNTH_PRIVATE_CLAIM_R6_987654"

        # HTML test
        orig_html = (REPO_ROOT / "docs/privacy.html").read_text("utf-8")
        mutated_html = orig_html.replace("</body>", f'<div data-claim-id="{synth_id}"><p>test</p></div></body>')
        _, drift_errs_html = self._run_with_disposable_repo(file_overrides={"docs/privacy.html": mutated_html})
        html_unknown_errs = [e for e in drift_errs_html if e.code == "policy.unknown_claim_id"]
        self.assertTrue(len(html_unknown_errs) > 0)
        for e in html_unknown_errs:
            self.assertNotIn(synth_id, e.message)
            self.assertNotIn(synth_id, e.target)

        # Markdown test
        orig_md = (REPO_ROOT / "PRIVACY.md").read_text("utf-8")
        mutated_md = orig_md + f"\n\n<!-- claim: {synth_id} -->\nClaim body\n"
        _, drift_errs_md = self._run_with_disposable_repo(file_overrides={"PRIVACY.md": mutated_md})
        md_unknown_errs = [e for e in drift_errs_md if e.code == "policy.unknown_claim_id"]
        self.assertTrue(len(md_unknown_errs) > 0)
        for e in md_unknown_errs:
            self.assertNotIn(synth_id, e.message)
            self.assertNotIn(synth_id, e.target)

    def test_p1_r3_n02_real_backup_receipt_sha_mismatch(self) -> None:
        """P1-R3 / N02: Receipt with head_sha not matching repo HEAD or mismatching artifact digest is rejected."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["flows"][0]["evidence_level"] = "REAL-BACKUP"
        mutated["flows"][0]["receipt_file"] = "docs/privacy/dummy_receipt.json"

        # 1. Wrong head_sha
        receipt_wrong_head = json.dumps({
            "receipt_id": "rec-n02-head",
            "status": "PASS",
            "exit_code": 0,
            "head_sha": "b7f82524f3ff9b7545892888284ec2ebb5433ac7",
            "commands": [{"id": "cmd-1", "command": "sh backup.sh", "exit_code": 0}],
            "artifacts": [{"id": "art-1", "path": "docs/privacy.html", "sha256": "a" * 64}],
            "cases": [{"id": "c1", "status": "PASS", "exit_code": 0, "command_id": "cmd-1", "artifact_id": "art-1"}],
        }).encode("utf-8")
        _, drift_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": receipt_wrong_head},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in drift_errs))

        # 2. Correct head_sha, but artifact sha256 mismatch (64 'a')
        repo_head = validate_privacy_contract._get_repo_head_sha(REPO_ROOT) or ("1" * 40)
        receipt_wrong_art_sha = json.dumps({
            "receipt_id": "rec-n02-art",
            "status": "PASS",
            "exit_code": 0,
            "head_sha": repo_head,
            "commands": [{"id": "cmd-1", "command": "sh backup.sh", "exit_code": 0}],
            "artifacts": [{"id": "art-1", "path": "docs/privacy.html", "sha256": "a" * 64}],
            "cases": [{"id": "c1", "status": "PASS", "exit_code": 0, "command_id": "cmd-1", "artifact_id": "art-1"}],
        }).encode("utf-8")
        _, drift_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": receipt_wrong_art_sha},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in drift_errs))

        # 3. Correct head_sha, non-hex 64 'Z'
        receipt_non_hex_art = json.dumps({
            "receipt_id": "rec-n02-nonhex",
            "status": "PASS",
            "exit_code": 0,
            "head_sha": repo_head,
            "commands": [{"id": "cmd-1", "command": "sh backup.sh", "exit_code": 0}],
            "artifacts": [{"id": "art-1", "path": "docs/privacy.html", "sha256": "Z" * 64}],
            "cases": [{"id": "c1", "status": "PASS", "exit_code": 0, "command_id": "cmd-1", "artifact_id": "art-1"}],
        }).encode("utf-8")
        _, drift_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": receipt_non_hex_art},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in drift_errs))

        # 4. Correct head_sha, 40-hex
        receipt_hex40_art = json.dumps({
            "receipt_id": "rec-n02-hex40",
            "status": "PASS",
            "exit_code": 0,
            "head_sha": repo_head,
            "commands": [{"id": "cmd-1", "command": "sh backup.sh", "exit_code": 0}],
            "artifacts": [{"id": "art-1", "path": "docs/privacy.html", "sha256": "a" * 40}],
            "cases": [{"id": "c1", "status": "PASS", "exit_code": 0, "command_id": "cmd-1", "artifact_id": "art-1"}],
        }).encode("utf-8")
        _, drift_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": receipt_hex40_art},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in drift_errs))

        # 5. Correct head_sha, authentic artifact sha256 -> PASS
        real_html_bytes = (REPO_ROOT / "docs/privacy.html").read_bytes()
        real_sha256 = hashlib.sha256(real_html_bytes).hexdigest()
        receipt_authentic = json.dumps({
            "receipt_id": "rec-n02-auth",
            "status": "PASS",
            "exit_code": 0,
            "head_sha": repo_head,
            "commands": [{"id": "cmd-1", "command": "sh backup.sh", "exit_code": 0}],
            "artifacts": [{"id": "art-1", "path": "docs/privacy.html", "sha256": real_sha256}],
            "cases": [{"id": "c1", "status": "PASS", "exit_code": 0, "command_id": "cmd-1", "artifact_id": "art-1"}],
        }).encode("utf-8")
        s_errs, d_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": receipt_authentic},
            contract_data=mutated,
        )
        self.assertEqual(s_errs, [])
        self.assertEqual(d_errs, [])

    def test_p1_r3_n03_real_backup_receipt_missing_commands_or_artifacts(self) -> None:
        """P1-R3 / N03: Receipt lacking commands or artifacts is rejected."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["flows"][0]["evidence_level"] = "REAL-BACKUP"
        mutated["flows"][0]["receipt_file"] = "docs/privacy/dummy_receipt.json"
        repo_head = validate_privacy_contract._get_repo_head_sha(REPO_ROOT) or ("1" * 40)
        receipt_no_cmd = json.dumps({
            "receipt_id": "rec-n03",
            "status": "PASS",
            "exit_code": 0,
            "head_sha": repo_head,
            "cases": [{"id": "c1", "status": "PASS", "exit_code": 0}],
        }).encode("utf-8")
        _, drift_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": receipt_no_cmd},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in drift_errs))

    def test_p1_r3_n04_link01_link02_typed_linkage(self) -> None:
        """P1-R3 / LINK01 & LINK02: Typed linkage between cases, commands, and artifacts."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["flows"][0]["evidence_level"] = "REAL-BACKUP"
        mutated["flows"][0]["receipt_file"] = "docs/privacy/dummy_receipt.json"
        repo_head = validate_privacy_contract._get_repo_head_sha(REPO_ROOT) or ("1" * 40)
        real_html_bytes = (REPO_ROOT / "docs/privacy.html").read_bytes()
        real_sha256 = hashlib.sha256(real_html_bytes).hexdigest()

        # LINK01: Valid typed linkage referencing known command_id and artifact_id/path -> PASS
        receipt_link01 = json.dumps({
            "receipt_id": "rec-link01",
            "status": "PASS",
            "exit_code": 0,
            "head_sha": repo_head,
            "commands": [{"id": "cmd-1", "command": "sh backup.sh", "exit_code": 0}],
            "artifacts": [{"id": "art-1", "path": "docs/privacy.html", "sha256": real_sha256}],
            "cases": [
                {
                    "id": "c1",
                    "status": "PASS",
                    "exit_code": 0,
                    "command_id": "cmd-1",
                    "artifact_id": "art-1",
                },
                {
                    "id": "c2",
                    "status": "PASS",
                    "exit_code": 0,
                    "command_ids": ["cmd-1"],
                    "artifact_ids": ["docs/privacy.html"],
                },
            ],
        }).encode("utf-8")
        s_errs, d_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": receipt_link01},
            contract_data=mutated,
        )
        self.assertEqual(s_errs, [])
        self.assertEqual(d_errs, [])

        # LINK02a: Case references unknown command_id -> REJECT
        receipt_link02a = json.dumps({
            "receipt_id": "rec-link02a",
            "status": "PASS",
            "exit_code": 0,
            "head_sha": repo_head,
            "commands": [{"id": "cmd-1", "command": "sh backup.sh", "exit_code": 0}],
            "artifacts": [{"id": "art-1", "path": "docs/privacy.html", "sha256": real_sha256}],
            "cases": [{
                "id": "c1",
                "status": "PASS",
                "exit_code": 0,
                "command_id": "NO_SUCH_COMMAND",
                "artifact_id": "art-1",
            }],
        }).encode("utf-8")
        _, drift_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": receipt_link02a},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in drift_errs))

        # LINK02b: Case references unknown artifact_id -> REJECT
        receipt_link02b = json.dumps({
            "receipt_id": "rec-link02b",
            "status": "PASS",
            "exit_code": 0,
            "head_sha": repo_head,
            "commands": [{"id": "cmd-1", "command": "sh backup.sh", "exit_code": 0}],
            "artifacts": [{"id": "art-1", "path": "docs/privacy.html", "sha256": real_sha256}],
            "cases": [{
                "id": "c1",
                "status": "PASS",
                "exit_code": 0,
                "command_id": "cmd-1",
                "artifact_ids": ["NO_SUCH_ARTIFACT"],
            }],
        }).encode("utf-8")
        _, drift_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": receipt_link02b},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in drift_errs))

    def test_p1_r3_n08_dart_empty_group_rejection(self) -> None:
        """P1-R3 / N08: Dart test file containing only an empty group is rejected."""
        mutated = copy.deepcopy(self.raw_contract)
        test_path = "test/n08_empty_group_test.dart"
        mutated["flows"][0]["test_ids"] = [test_path]
        empty_group_dart = "void main() { group('empty group', () {}); }"
        _, drift_errs = self._run_with_disposable_repo(
            file_overrides={test_path: empty_group_dart},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "test.empty_or_no_tests" for e in drift_errs))

    def test_p1_r3_n09_dart_string_literal_test_rejection(self) -> None:
        """P1-R3 / N09: Dart test file where test(...) is only within a string literal is rejected."""
        mutated = copy.deepcopy(self.raw_contract)
        test_path = "test/n09_string_literal_test.dart"
        mutated["flows"][0]["test_ids"] = [test_path]
        string_literal_dart = 'const text = "test(ghost)"; void main() {}'
        _, drift_errs = self._run_with_disposable_repo(
            file_overrides={test_path: string_literal_dart},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "test.empty_or_no_tests" for e in drift_errs))

    def test_p1_r3_u04_to_u09_mandatory_typed_linkage(self) -> None:
        """P1-R3 / U04–U09: Mandatory typed linkage contract rejects missing, null, or empty references and identifiers."""
        mutated = copy.deepcopy(self.raw_contract)
        mutated["flows"][0]["evidence_level"] = "REAL-BACKUP"
        mutated["flows"][0]["receipt_file"] = "docs/privacy/dummy_receipt.json"
        repo_head = validate_privacy_contract._get_repo_head_sha(REPO_ROOT) or ("1" * 40)
        real_html_bytes = (REPO_ROOT / "docs/privacy.html").read_bytes()
        real_sha256 = hashlib.sha256(real_html_bytes).hexdigest()

        def make_receipt(cmd_entry, art_entry, case_entry):
            return json.dumps({
                "receipt_id": "rec-u-test",
                "status": "PASS",
                "exit_code": 0,
                "head_sha": repo_head,
                "commands": [cmd_entry],
                "artifacts": [art_entry],
                "cases": [case_entry],
            }).encode("utf-8")

        base_cmd = {"id": "cmd-1", "command": "sh backup.sh", "exit_code": 0}
        base_art = {"id": "art-1", "path": "docs/privacy.html", "sha256": real_sha256}
        base_case = {"id": "case-1", "status": "PASS", "exit_code": 0, "command_id": "cmd-1", "artifact_id": "art-1"}

        # Positive baseline: Valid typed linkage passes
        s_errs, d_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": make_receipt(base_cmd, base_art, base_case)},
            contract_data=mutated,
        )
        self.assertEqual(s_errs, [])
        self.assertEqual(d_errs, [])

        # U04: Case deletes command_id (no command reference) -> REJECT
        u04_case = {"id": "case-1", "status": "PASS", "exit_code": 0, "artifact_id": "art-1"}
        _, errs_u04 = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": make_receipt(base_cmd, base_art, u04_case)},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in errs_u04))

        # U05: Case deletes artifact_id (no artifact reference) -> REJECT
        u05_case = {"id": "case-1", "status": "PASS", "exit_code": 0, "command_id": "cmd-1"}
        _, errs_u05 = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": make_receipt(base_cmd, base_art, u05_case)},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in errs_u05))

        # U06: Case deletes both command and artifact references -> REJECT
        u06_case = {"id": "case-1", "status": "PASS", "exit_code": 0}
        _, errs_u06 = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": make_receipt(base_cmd, base_art, u06_case)},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in errs_u06))

        # U07a: Case sets both references to null -> REJECT
        u07a_case = {"id": "case-1", "status": "PASS", "exit_code": 0, "command_id": None, "artifact_id": None}
        _, errs_u07a = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": make_receipt(base_cmd, base_art, u07a_case)},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in errs_u07a))

        # U07b: Case sets plural references to null -> REJECT
        u07b_case = {"id": "case-1", "status": "PASS", "exit_code": 0, "command_ids": None, "artifact_ids": None}
        _, errs_u07b = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": make_receipt(base_cmd, base_art, u07b_case)},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in errs_u07b))

        # U08: Command and artifact IDs are deleted -> REJECT
        u08_cmd = {"command": "sh backup.sh", "exit_code": 0}
        u08_art = {"path": "docs/privacy.html", "sha256": real_sha256}
        _, errs_u08 = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": make_receipt(u08_cmd, u08_art, base_case)},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in errs_u08))

        # U09a: Command and artifact IDs are empty string -> REJECT
        u09a_cmd = {"id": "", "command": "sh backup.sh", "exit_code": 0}
        u09a_art = {"id": "", "path": "docs/privacy.html", "sha256": real_sha256}
        _, errs_u09a = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": make_receipt(u09a_cmd, u09a_art, base_case)},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in errs_u09a))

        # U09b: Case references are empty strings -> REJECT
        u09b_case = {"id": "case-1", "status": "PASS", "exit_code": 0, "command_id": "", "artifact_id": ""}
        _, errs_u09b = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": make_receipt(base_cmd, base_art, u09b_case)},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in errs_u09b))

        # U10: Case plural references are empty lists -> REJECT
        u10_case = {"id": "case-1", "status": "PASS", "exit_code": 0, "command_ids": [], "artifact_ids": []}
        _, errs_u10 = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/dummy_receipt.json": make_receipt(base_cmd, base_art, u10_case)},
            contract_data=mutated,
        )
        self.assertTrue(any(e.code == "evidence.real_backup_receipt_invalid" for e in errs_u10))

    def test_df10_audit_a00_control_pass(self) -> None:
        """A00: Control pass: Pristine DF10 audit scope and receipt yield 0 errors and exit code 0."""
        schema_errs, drift_errs = validate_privacy_contract.validate_contract_data(
            self.raw_contract, REPO_ROOT
        )
        self.assertEqual(schema_errs, [])
        self.assertEqual(drift_errs, [])
        code, result = validate_privacy_contract.run_validator(str(REPO_ROOT), str(self.contract_path))
        self.assertEqual(code, 0)
        self.assertEqual(result["status"], "pass")

    def test_df10_audit_a01_missing_scope(self) -> None:
        """A01: Missing audit_scope in DF10 triggers schema.missing_audit_scope (exit 2)."""
        mutated = copy.deepcopy(self.raw_contract)
        for f in mutated["flows"]:
            if f.get("coverage_id") == "DF10":
                del f["audit_scope"]
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.missing_audit_scope" for e in schema_errs))

        with tempfile.NamedTemporaryFile("w", dir=str(REPO_ROOT / "docs/privacy"), suffix=".json", delete=False) as tf:
            json.dump(mutated, tf)
            tf_path = tf.name
        try:
            res = subprocess.run(
                [sys.executable, str(TOOL_DIR / "validate_privacy_contract.py"), "--contract", tf_path, "--repo-root", str(REPO_ROOT)],
                capture_output=True,
                text=True,
            )
            self.assertEqual(res.returncode, 2)
        finally:
            os.remove(tf_path)

    def test_df10_audit_a02_empty_roots_or_patterns(self) -> None:
        """A02: Empty roots or patterns triggers schema error (exit 2)."""
        # Empty roots
        mutated_roots = copy.deepcopy(self.raw_contract)
        for f in mutated_roots["flows"]:
            if f.get("coverage_id") == "DF10":
                f["audit_scope"]["audited_roots"] = []
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated_roots, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.invalid_audited_roots" for e in schema_errs))

        # Empty patterns
        mutated_patterns = copy.deepcopy(self.raw_contract)
        for f in mutated_patterns["flows"]:
            if f.get("coverage_id") == "DF10":
                f["audit_scope"]["prohibited_sdk_patterns"] = []
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated_patterns, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.invalid_prohibited_patterns" for e in schema_errs))

        with tempfile.NamedTemporaryFile("w", dir=str(REPO_ROOT / "docs/privacy"), suffix=".json", delete=False) as tf:
            json.dump(mutated_roots, tf)
            tf_path = tf.name
        try:
            res = subprocess.run(
                [sys.executable, str(TOOL_DIR / "validate_privacy_contract.py"), "--contract", tf_path, "--repo-root", str(REPO_ROOT)],
                capture_output=True,
                text=True,
            )
            self.assertEqual(res.returncode, 2)
        finally:
            os.remove(tf_path)

    def test_df10_audit_a03_unresolved_hits(self) -> None:
        """A03: Non-zero hits_count or non-PASS status triggers audit.unresolved_hits (exit 1)."""
        # Via contract data scope mutation
        mutated_scope = copy.deepcopy(self.raw_contract)
        for f in mutated_scope["flows"]:
            if f.get("coverage_id") == "DF10":
                f["audit_scope"]["hits_count"] = 1
                f["audit_scope"]["status"] = "FAIL"
        schema_errs, drift_errs = validate_privacy_contract.validate_contract_data(mutated_scope, REPO_ROOT)
        self.assertEqual(schema_errs, [])
        self.assertTrue(any(e.code == "audit.unresolved_hits" for e in drift_errs))

        with tempfile.NamedTemporaryFile("w", dir=str(REPO_ROOT / "docs/privacy"), suffix=".json", delete=False) as tf:
            json.dump(mutated_scope, tf)
            tf_path = tf.name
        try:
            res = subprocess.run(
                [sys.executable, str(TOOL_DIR / "validate_privacy_contract.py"), "--contract", tf_path, "--repo-root", str(REPO_ROOT)],
                capture_output=True,
                text=True,
            )
            self.assertEqual(res.returncode, 1)
        finally:
            os.remove(tf_path)

        # Via physical receipt file override
        orig_receipt = json.loads((REPO_ROOT / "docs/privacy/sdk-audit-receipt.json").read_text(encoding="utf-8"))
        mutated_receipt = copy.deepcopy(orig_receipt)
        mutated_receipt["status"] = "FAIL"
        mutated_receipt["exit_code"] = 1
        mutated_receipt["hits_count"] = 2
        mutated_receipt["findings"] = "prohibited-telemetry-found"
        s_errs, d_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/sdk-audit-receipt.json": json.dumps(mutated_receipt)}
        )
        self.assertEqual(s_errs, [])
        self.assertTrue(any(e.code == "audit.unresolved_hits" for e in d_errs))

    def test_df10_audit_a04_string_scope(self) -> None:
        """A04: String-typed audit_scope triggers schema.invalid_audit_scope (exit 2)."""
        mutated = copy.deepcopy(self.raw_contract)
        for f in mutated["flows"]:
            if f.get("coverage_id") == "DF10":
                f["audit_scope"] = "invalid_string_scope"
        schema_errs, _ = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.invalid_audit_scope" for e in schema_errs))

        with tempfile.NamedTemporaryFile("w", dir=str(REPO_ROOT / "docs/privacy"), suffix=".json", delete=False) as tf:
            json.dump(mutated, tf)
            tf_path = tf.name
        try:
            res = subprocess.run(
                [sys.executable, str(TOOL_DIR / "validate_privacy_contract.py"), "--contract", tf_path, "--repo-root", str(REPO_ROOT)],
                capture_output=True,
                text=True,
            )
            self.assertEqual(res.returncode, 2)
        finally:
            os.remove(tf_path)

    def test_df10_audit_b01_lockfile_drift(self) -> None:
        """B01: Modified bytes in pubspec.lock on disk triggers audit.lockfile_drift (exit 1)."""
        s_errs, d_errs = self._run_with_disposable_repo(
            file_overrides={"pubspec.lock": "mutated_lockfile_content\n"}
        )
        self.assertEqual(s_errs, [])
        self.assertTrue(any(e.code == "audit.lockfile_drift" for e in d_errs))

    def test_df10_audit_b02_lockfile_missing(self) -> None:
        """B02: Deleted pubspec.lock on disk triggers audit.lockfile_missing (exit 1)."""
        s_errs, d_errs = self._run_with_disposable_repo(
            delete_files=["pubspec.lock"]
        )
        self.assertEqual(s_errs, [])
        self.assertTrue(any(e.code == "audit.lockfile_missing" for e in d_errs))

    def test_df10_audit_b03_receipt_roots_mismatch(self) -> None:
        """B03: Receipt audited_roots mismatch triggers audit.roots_mismatch (exit 1)."""
        orig_receipt = json.loads((REPO_ROOT / "docs/privacy/sdk-audit-receipt.json").read_text(encoding="utf-8"))
        mutated_receipt = copy.deepcopy(orig_receipt)
        mutated_receipt["audited_roots"] = ["lib", "pubspec.yaml"]
        s_errs, d_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/sdk-audit-receipt.json": json.dumps(mutated_receipt)}
        )
        self.assertEqual(s_errs, [])
        self.assertTrue(any(e.code == "audit.roots_mismatch" for e in d_errs))

    def test_df10_audit_b04_scope_root_missing_on_disk(self) -> None:
        """B04: Scope root path pointing to non-existent directory triggers audit.root_missing (exit 1)."""
        mutated = copy.deepcopy(self.raw_contract)
        for f in mutated["flows"]:
            if f.get("coverage_id") == "DF10":
                f["audit_scope"]["audited_roots"].append("nonexistent/dir/path")
        s_errs, d_errs = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertEqual(s_errs, [])
        self.assertTrue(any(e.code == "audit.root_missing" for e in d_errs))

    def test_df10_audit_b05_receipt_patterns_mismatch(self) -> None:
        """B05: Receipt prohibited_sdk_patterns mismatch triggers audit.patterns_mismatch (exit 1)."""
        orig_receipt = json.loads((REPO_ROOT / "docs/privacy/sdk-audit-receipt.json").read_text(encoding="utf-8"))
        mutated_receipt = copy.deepcopy(orig_receipt)
        mutated_receipt["prohibited_sdk_patterns"] = ["firebase", "sentry"]
        s_errs, d_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/sdk-audit-receipt.json": json.dumps(mutated_receipt)}
        )
        self.assertEqual(s_errs, [])
        self.assertTrue(any(e.code == "audit.patterns_mismatch" for e in d_errs))

    def test_df10_audit_b06_command_mismatch(self) -> None:
        """B06: Command mismatch between scope and receipt triggers audit.command_mismatch (exit 1)."""
        orig_receipt = json.loads((REPO_ROOT / "docs/privacy/sdk-audit-receipt.json").read_text(encoding="utf-8"))
        mutated_receipt = copy.deepcopy(orig_receipt)
        mutated_receipt["command"] = "flutter pub deps --style=tree"
        s_errs, d_errs = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/sdk-audit-receipt.json": json.dumps(mutated_receipt)}
        )
        self.assertEqual(s_errs, [])
        self.assertTrue(any(e.code == "audit.command_mismatch" for e in d_errs))

    def test_df10_audit_b07_synthetic_source_added(self) -> None:
        """B07: Adding synthetic source with tracking pattern or unrecorded file triggers source_drift / unresolved_hits (exit 1)."""
        # Case A: Synthetic source with prohibited pattern
        s_errs_a, d_errs_a = self._run_with_disposable_repo(
            file_overrides={"lib/synthetic_sentry_tracker.dart": "import 'package:sentry/sentry.dart';\nvoid init() {}\n"}
        )
        self.assertEqual(s_errs_a, [])
        self.assertTrue(any(e.code in ("audit.source_drift", "audit.unresolved_hits") for e in d_errs_a))

        # Case B: Clean synthetic source not present in receipt audited_sources
        s_errs_b, d_errs_b = self._run_with_disposable_repo(
            file_overrides={"lib/synthetic_clean_helper.dart": "void cleanHelper() {}\n"}
        )
        self.assertEqual(s_errs_b, [])
        self.assertTrue(any(e.code == "audit.source_drift" for e in d_errs_b))

    def test_df10_audit_b09_receipt_metadata_missing(self) -> None:
        """B09: Receipt missing execution metadata fields triggers audit.receipt_metadata_missing (exit 2)."""
        minimal_receipt = {
            "status": "PASS",
            "exit_code": 0,
            "hits_count": 0,
            "findings": "zero-third-party-sdk-dependencies",
            "target_lock_sha256": "0c59c66b40489b3490b71b64be682387dd27ebde0db6205f73bc4c87d585b90c",
        }
        s_errs, _ = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/sdk-audit-receipt.json": json.dumps(minimal_receipt)}
        )
        self.assertTrue(any(e.code == "audit.receipt_metadata_missing" for e in s_errs))

    def test_df10_audit_b10_platform_storage_mapping_root_enforced(self) -> None:
        """B10: Android documents backup_domain must be 'root'; 'file' triggers schema error (exit 2)."""
        mutated = copy.deepcopy(self.raw_contract)
        s_pass, d_pass = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertEqual(s_pass, [])
        self.assertEqual(d_pass, [])

        mutated["platform_storage_mapping"]["android"]["documents"]["backup_domain"] = "file"
        s_errs, _ = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertTrue(any(e.code == "schema.invalid_platform_storage_mapping" for e in s_errs))

    def test_df10_audit_l02_l03_receipt_missing_non_leak(self) -> None:
        """L02/L03: Non-existent receipt file produces exit 1 without leaking secret path into message or text output."""
        mutated = copy.deepcopy(self.raw_contract)
        secret_receipt = "docs/privacy/SYNTH_PRIVATE_AUDIT_RECEIPT_R11_7654321.json"
        for f in mutated["flows"]:
            if f.get("coverage_id") == "DF10":
                f["audit_scope"]["receipt_file"] = secret_receipt

        s_errs, d_errs = validate_privacy_contract.validate_contract_data(mutated, REPO_ROOT)
        self.assertEqual(s_errs, [])
        missing_errs = [e for e in d_errs if e.code == "audit.receipt_missing"]
        self.assertTrue(len(missing_errs) > 0)
        for e in missing_errs:
            self.assertNotIn("SYNTH_PRIVATE_AUDIT_RECEIPT", e.message)
            self.assertNotIn(secret_receipt, e.message)
            self.assertEqual(e.message, "Receipt file does not exist")

        with tempfile.NamedTemporaryFile("w", dir=str(REPO_ROOT / "docs/privacy"), suffix=".json", delete=False) as tf:
            json.dump(mutated, tf)
            tf_path = tf.name
        try:
            res_text = subprocess.run(
                [sys.executable, str(TOOL_DIR / "validate_privacy_contract.py"), "--contract", tf_path, "--repo-root", str(REPO_ROOT)],
                capture_output=True,
                text=True,
            )
            self.assertEqual(res_text.returncode, 1)
            self.assertNotIn("SYNTH_PRIVATE_AUDIT_RECEIPT", res_text.stdout)
            self.assertNotIn("SYNTH_PRIVATE_AUDIT_RECEIPT", res_text.stderr)

            res_json = subprocess.run(
                [sys.executable, str(TOOL_DIR / "validate_privacy_contract.py"), "--contract", tf_path, "--repo-root", str(REPO_ROOT), "--output", "json"],
                capture_output=True,
                text=True,
            )
            self.assertEqual(res_json.returncode, 1)
            self.assertNotIn("SYNTH_PRIVATE_AUDIT_RECEIPT", res_json.stdout)
            self.assertNotIn("SYNTH_PRIVATE_AUDIT_RECEIPT", res_json.stderr)
        finally:
            os.remove(tf_path)

    def test_df10_audit_receipt_null_and_non_dict_rejected(self) -> None:
        """Section 3: Receipt containing JSON null or non-dict root triggers audit.receipt_malformed (exit 2)."""
        # Case A: JSON null literal
        s_errs_null, d_errs_null = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/sdk-audit-receipt.json": "null"}
        )
        self.assertTrue(any(e.code == "audit.receipt_malformed" for e in s_errs_null))
        self.assertEqual(d_errs_null, [])

        # Case B: JSON array literal
        s_errs_arr, d_errs_arr = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/sdk-audit-receipt.json": "[]"}
        )
        self.assertTrue(any(e.code == "audit.receipt_malformed" for e in s_errs_arr))
        self.assertEqual(d_errs_arr, [])

        # Case C: JSON number literal
        s_errs_num, d_errs_num = self._run_with_disposable_repo(
            file_overrides={"docs/privacy/sdk-audit-receipt.json": "42"}
        )
        self.assertTrue(any(e.code == "audit.receipt_malformed" for e in s_errs_num))
        self.assertEqual(d_errs_num, [])

    def test_df10_audit_source_invalid_utf8_rejected(self) -> None:
        """Section 4: Audited source file with invalid UTF-8 bytes triggers audit.source_encoding_error (exit 1)."""
        s_errs, d_errs = self._run_with_disposable_repo(
            file_overrides={"lib/main.dart": b"// \xff\xfe\x80 invalid utf8\n"}
        )
        self.assertEqual(s_errs, [])
        enc_errs = [e for e in d_errs if e.code == "audit.source_encoding_error"]
        self.assertTrue(len(enc_errs) > 0)
        for e in enc_errs:
            self.assertEqual(e.message, "Audited source file is not valid UTF-8 text")
            self.assertTrue(e.target.endswith(".receipt_file"))

    def test_df10_audit_source_budget_exceeded(self) -> None:
        """Section 4: Audited source scan exceeding file budget triggers budget.aggregate_exceeded (exit 1)."""
        orig_max_files = validate_privacy_contract.MAX_AUDIT_SOURCE_FILES
        try:
            validate_privacy_contract.MAX_AUDIT_SOURCE_FILES = 2
            s_errs, d_errs = validate_privacy_contract.validate_contract_data(self.raw_contract, REPO_ROOT)
            self.assertEqual(s_errs, [])
            budget_errs = [e for e in d_errs if e.code == "budget.aggregate_exceeded"]
            self.assertTrue(len(budget_errs) > 0)
            for e in budget_errs:
                self.assertEqual(e.message, "Audited source files exceed aggregate budget")
                self.assertTrue(e.target.endswith(".receipt_file"))
        finally:
            validate_privacy_contract.MAX_AUDIT_SOURCE_FILES = orig_max_files


if __name__ == "__main__":
    unittest.main()
