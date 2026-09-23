#!/usr/bin/env python3
"""Tests for tool/workshop/validate_provenance.py (Issue #11, WS-07 Slice 1)."""
from __future__ import annotations

import copy
import json
import re
import subprocess
import sys
import unittest
from pathlib import Path

# Locate repo root
REPO_ROOT = Path(__file__).resolve().parents[2]
TOOL_DIR = REPO_ROOT / "tool/workshop"
sys.path.insert(0, str(TOOL_DIR))

import validate_provenance  # noqa: E402


class TestValidateProvenance(unittest.TestCase):
    """Verifies provenance inventory schema, integrity, rights, and containment."""

    def setUp(self) -> None:
        self.inventory_path = REPO_ROOT / "docs/provenance/inventory.json"
        self.raw_inventory = json.loads(
            self.inventory_path.read_text(encoding="utf-8")
        )

    def test_canonical_inventory_passes(self) -> None:
        """A1-A5: Canonical committed inventory passes cleanly."""
        errors = validate_provenance.validate_provenance_data(
            self.raw_inventory, REPO_ROOT, scope="production-package"
        )
        self.assertEqual(errors, [])

    def test_cli_execution_passes_and_is_deterministic(self) -> None:
        """A9: CLI execution returns code 0 and produces identical output across runs."""
        cmd = [
            sys.executable,
            str(TOOL_DIR / "validate_provenance.py"),
            "--scope",
            "production-package",
            "--inventory",
            str(self.inventory_path),
            "--repo-root",
            str(REPO_ROOT),
        ]
        res1 = subprocess.run(cmd, capture_output=True, text=True, check=False)
        self.assertEqual(res1.returncode, 0, msg=f"CLI failed: {res1.stderr}")
        self.assertIn("[PASS]", res1.stdout)
        self.assertIn("powertrain-battery-bundled-third-party", res1.stdout)

        res2 = subprocess.run(cmd, capture_output=True, text=True, check=False)
        self.assertEqual(res1.stdout, res2.stdout)

    def test_cli_json_format(self) -> None:
        """Validates JSON reporting format from CLI."""
        cmd = [
            sys.executable,
            str(TOOL_DIR / "validate_provenance.py"),
            "--format",
            "json",
            "--inventory",
            str(self.inventory_path),
            "--repo-root",
            str(REPO_ROOT),
        ]
        res = subprocess.run(cmd, capture_output=True, text=True, check=False)
        self.assertEqual(res.returncode, 0)
        data = json.loads(res.stdout)
        self.assertEqual(data["status"], "pass")
        self.assertEqual(data["errors"], [])

    # =========================================================================
    # Schema / Field Negatives
    # =========================================================================

    def test_unknown_schema_version_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["schema_version"] = 999
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "SCHEMA_VERSION_INVALID" for e in errors)
        )

    def test_duplicate_artifact_id_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"].append(copy.deepcopy(data["artifacts"][0]))
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "DUPLICATE_ARTIFACT_ID" for e in errors)
        )

    def test_missing_or_empty_artifact_id_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["id"] = ""
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "MISSING_ARTIFACT_ID" for e in errors)
        )

    def test_wildcard_artifact_id_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["id"] = "powertrain-battery-*"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "WILDCARD_ARTIFACT_ID" for e in errors)
        )

    def test_unauthorized_artifact_class_in_slice1_rejected(self) -> None:
        """Ensures Slice 1 boundary cannot be bypassed with unvetted classes."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["id"] = "unvetted-external-library"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "UNAUTHORIZED_ARTIFACT_CLASS" for e in errors)
        )

    def test_absolute_path_forbidden(self) -> None:
        """Guards against committing absolute host paths into inventory."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["source_of_truth_paths"]["catalog"] = (
            "/Users/someone/telltale/catalog.json"
        )
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "ABSOLUTE_PATH_FORBIDDEN" for e in errors)
        )

    def test_invalid_role_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["role"] = "magic-telepathy"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(any(e.error_code == "INVALID_ROLE" for e in errors))

    def test_missing_remediation_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["remediation"] = {}
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "REMEDIATION_MISSING" for e in errors)
        )

    # =========================================================================
    # Rights / Decision Negatives
    # =========================================================================

    def test_distribution_decision_unknown_rejected(self) -> None:
        """A7: 'unknown' cannot be silently coerced to approved (M2 target)."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["distribution_decision"] = "unknown"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "DISTRIBUTION_DECISION_INVALID" for e in errors)
        )

    def test_distribution_decision_restricted_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["distribution_decision"] = "restricted"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "DISTRIBUTION_DECISION_INVALID" for e in errors)
        )

    def test_commercial_use_decision_unknown_or_restricted_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["commercial_use_decision"] = "unknown"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "COMMERCIAL_USE_DECISION_INVALID" for e in errors)
        )

    def test_reviewer_status_unreviewed_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["reviewer_status"] = "unreviewed"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "REVIEWER_STATUS_INVALID" for e in errors)
        )

    # =========================================================================
    # Integrity & Package Negatives
    # =========================================================================

    def test_catalog_sha256_mismatch_rejected(self) -> None:
        """M1 target: Tampered SHA-256 is rejected immediately."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["catalog_manifest"]["expected_sha256"] = (
            "0000000000000000000000000000000000000000000000000000000000000000"
        )
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "CATALOG_SHA256_MISMATCH" for e in errors)
        )

    def test_catalog_size_mismatch_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["catalog_manifest"]["expected_size_bytes"] = 12345
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "CATALOG_SIZE_MISMATCH" for e in errors)
        )

    def test_missing_source_path_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["source_of_truth_paths"]["notices"] = (
            "NONEXISTENT_NOTICES_FILE.md"
        )
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "SOURCE_PATH_MISSING" for e in errors)
        )

    def test_package_asset_omission_from_pubspec_rejected(self) -> None:
        """M3 target: Asset in inventory but omitted from pubspec.yaml is caught."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["required_package_assets"].append(
            "docs/provenance/README.md"  # file exists on disk, but NOT in pubspec assets
        )
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "PUBSPEC_ASSET_MISSING" for e in errors)
        )

    def test_licence_registry_asset_omission_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["runtime_licence_registry_assets"].append(
            "assets/powertrain_battery/powertrain_battery_catalog.json"
        )
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "LICENCE_REGISTRY_ASSET_MISSING" for e in errors)
        )

    def test_licence_location_missing_rejected(self) -> None:
        """Field negative: missing or nonexistent licence_location is rejected."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["licence_location"] = "NONEXISTENT_LICENCE_FILE.md"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "LICENCE_LOCATION_MISSING" for e in errors)
        )

    def test_commercial_rationale_missing_rejected(self) -> None:
        """Field negative: missing commercial_use_rationale is rejected."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["commercial_use_rationale"] = ""
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "COMMERCIAL_RATIONALE_MISSING" for e in errors)
        )

    def test_owning_issues_missing_rejected(self) -> None:
        """Field negative: missing or empty owning_issues is rejected."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["owning_issues"] = []
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "OWNING_ISSUES_MISSING" for e in errors)
        )

    def test_licence_identifier_drift_rejected(self) -> None:
        """Integrity negative: licence_identifier omitting owner license is rejected."""
        data = copy.deepcopy(self.raw_inventory)
        # Omit GPL-3.0-or-later and CC-BY-4.0
        data["artifacts"][0]["licence_identifier"] = "Multi-licence (Apache-2.0, MIT)"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "LICENCE_IDENTIFIER_DRIFT" for e in errors)
        )

    def test_source_coverage_missing_rejected(self) -> None:
        """Schema negative: missing both source_coverage and source_families is rejected."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0].pop("source_coverage", None)
        data["artifacts"][0].pop("source_families", None)
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "SOURCE_COVERAGE_MISSING" for e in errors)
        )

    def test_valid_but_wrong_revision_rejected(self) -> None:
        """Targeted negative: valid 40-hex revision that drifts from owner truth is rejected."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["source_families"] = [
            {
                "name": "OBDb/Toyota-Prius",
                "url": "https://github.com/OBDb/Toyota-Prius",
                "revision": "1111111111111111111111111111111111111111",  # valid 40-hex, but wrong!
                "licence": "CC-BY-SA-4.0",
            }
        ]
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "REVISION_DRIFT_OR_MISMATCH" for e in errors)
        )

    def test_valid_but_wrong_sha256_rejected(self) -> None:
        """Targeted negative: valid 64-hex SHA that drifts from owner truth is rejected."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["source_families"] = [
            {
                "name": "OBDb/Kia-EV9",
                "url": "https://github.com/OBDb/Kia-EV9",
                "revision": "85d8cff25e849a6e421cda20cbadfd4630fe85e7",
                "artifact_sha256": "2222222222222222222222222222222222222222222222222222222222222222",  # valid 64-hex, but wrong!
                "licence": "CC-BY-SA-4.0",
            }
        ]
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "ARTIFACT_SHA256_MISMATCH" for e in errors)
        )

    def test_valid_but_wrong_licence_rejected(self) -> None:
        """Targeted negative: valid license enum that drifts from owner truth is rejected."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["source_families"] = [
            {
                "name": "OBDb/Toyota-Prius",
                "url": "https://github.com/OBDb/Toyota-Prius",
                "revision": "0a8c4ec72be860861548a3aeb2be007eecd83941",
                "licence": "MIT",  # valid license enum, but wrong for Toyota-Prius (CC-BY-SA-4.0)!
            }
        ]
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "LICENCE_MISMATCH" for e in errors)
        )

    def test_owner_source_missing_rejected(self) -> None:
        """Targeted negative: missing required owner research source is rejected."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["require_all_research_sources"] = True
        # Provide only a single source, omitting other 13 required research sources
        data["artifacts"][0]["source_families"] = [
            {
                "name": "OBDb/Toyota-Prius",
                "url": "https://github.com/OBDb/Toyota-Prius",
                "revision": "0a8c4ec72be860861548a3aeb2be007eecd83941",
                "licence": "CC-BY-SA-4.0",
            }
        ]
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "OWNER_SOURCE_MISSING" for e in errors)
        )

    def test_extra_unowned_source_rejected(self) -> None:
        """Targeted negative: source with no backing in owner truth is rejected."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["source_families"] = [
            {
                "name": "invented/unowned-magic-profile",
                "url": "https://github.com/invented/unowned-magic-profile",
                "revision": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                "licence": "MIT",
            }
        ]
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "UNOWNED_SOURCE_DETECTED" for e in errors)
        )

    def test_source_url_missing_rejected(self) -> None:
        """Targeted negative: missing source URL is rejected."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["source_families"] = [
            {
                "name": "OBDb/Toyota-Prius",
                "url": "",  # missing URL!
                "revision": "0a8c4ec72be860861548a3aeb2be007eecd83941",
                "licence": "CC-BY-SA-4.0",
            }
        ]
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "SOURCE_URL_MISSING" for e in errors)
        )

    def test_malformed_revision_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["source_families"] = [
            {
                "name": "OBDb/Toyota-Prius",
                "url": "https://github.com/OBDb/Toyota-Prius",
                "revision": "not-a-sha-commit",
                "licence": "CC-BY-SA-4.0",
            }
        ]
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "MALFORMED_REVISION" for e in errors)
        )

    def test_malformed_digest_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["source_families"] = [
            {
                "name": "OBDb/Toyota-Prius",
                "url": "https://github.com/OBDb/Toyota-Prius",
                "revision": "0a8c4ec72be860861548a3aeb2be007eecd83941",
                "artifact_sha256": "short",
                "licence": "CC-BY-SA-4.0",
            }
        ]
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "MALFORMED_SHA256" for e in errors)
        )

    # =========================================================================
    # Containment & Scoped Failure (A10, M4 target)
    # =========================================================================

    def test_containment_failure_is_scoped_not_global(self) -> None:
        """A10 / M4: Failure of battery provenance reports class error and DOES NOT

        claim the whole application or generic OBD is invalid or disabled.
        """
        data = copy.deepcopy(self.raw_inventory)
        # Induce a rights rejection
        data["artifacts"][0]["distribution_decision"] = "restricted"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        report = validate_provenance.format_report_text(
            data, errors, scope="production-package"
        )

        # Scoped failure report
        self.assertIn("powertrain-battery-bundled-third-party", report)
        self.assertIn("DISTRIBUTION_DECISION_INVALID", report)

        # Negative checks: must not claim application invalid or disable generic OBD
        self.assertNotIn("application invalid", report.lower())
        self.assertNotIn("app shutdown", report.lower())
        self.assertNotIn("obd disabled", report.lower())
        self.assertNotIn("demo disabled", report.lower())

    # =========================================================================
    # Upgraded M1 Mutation Verification: Valid-but-wrong owner revision/hash
    # =========================================================================

    def test_m1_valid_but_wrong_owner_revision_bypass_detection(self) -> None:
        """M1: Valid-but-wrong 40-hex commit bypass attempt is detected and rejected."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["source_families"] = [
            {
                "name": "iternio/ev-obd-pids",
                "url": "https://github.com/iternio/ev-obd-pids",
                "revision": "c45a018b60b3341d2d8bfb22cf0491c4e878165a",
                "licence": "Apache-2.0",
            },
            {
                "name": "OBDb/Toyota-Prius",
                "url": "https://github.com/OBDb/Toyota-Prius",
                "revision": "ffffffffffffffffffffffffffffffffffffffff",  # valid 40-hex bypass attempt
                "licence": "CC-BY-SA-4.0",
            },
        ]
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        # Without owner-truth cross-checking, this valid 40-hex string would bypass validation!
        # With owner-truth binding, it MUST be caught as REVISION_DRIFT_OR_MISMATCH:
        m1_errors = [e for e in errors if e.error_code == "REVISION_DRIFT_OR_MISMATCH"]
        self.assertTrue(
            len(m1_errors) > 0,
            msg="M1 failure: valid-but-wrong revision was not caught as REVISION_DRIFT_OR_MISMATCH!",
        )


    # =========================================================================
    # Canonical Production Path (source_coverage, no source_families) Negatives
    # =========================================================================

    def test_canonical_catalog_owner_missing_required_field_rejected(self) -> None:
        """Canonical path: owner catalog source missing required field (e.g. license) is rejected."""
        matrix_path = REPO_ROOT / "tool/powertrain_evidence/matrix.json"
        matrix_data = json.loads(matrix_path.read_text(encoding="utf-8"))
        # Drop 'license' from first catalog profile's source family
        matrix_data["catalog"]["profiles"][0]["source_families"][0]["license"] = ""

        tmp_dir = REPO_ROOT / ".test_tmp"
        tmp_dir.mkdir(exist_ok=True)
        tmp_file = tmp_dir / "mutated_matrix.json"
        try:
            tmp_file.write_text(json.dumps(matrix_data), encoding="utf-8")
            rel_path = str(tmp_file.relative_to(REPO_ROOT))
            data = copy.deepcopy(self.raw_inventory)
            data["artifacts"][0]["source_coverage"]["evidence_matrix_path"] = rel_path
            data["artifacts"][0]["source_of_truth_paths"]["evidence_matrix"] = rel_path
            errors = validate_provenance.validate_provenance_data(
                data, REPO_ROOT, scope="production-package"
            )
            self.assertTrue(
                any(e.error_code == "REQUIRED_OWNER_FIELD_MISSING" for e in errors),
                msg=f"Expected REQUIRED_OWNER_FIELD_MISSING, got: {[e.error_code for e in errors]}",
            )
        finally:
            if tmp_file.exists():
                tmp_file.unlink()
            if tmp_dir.exists():
                tmp_dir.rmdir()

    def test_canonical_catalog_only_notice_revision_drift_rejected(self) -> None:
        """Canonical path: catalog-only notice pinned revision drift is rejected."""
        notices_path = REPO_ROOT / "THIRD_PARTY_NOTICES_POWERTRAIN_BATTERY.md"
        notices_text = notices_path.read_text(encoding="utf-8")
        # Mutate peternixon/MG-EV-OBD-PID revision (catalog-only pin)
        mutated_text = notices_text.replace(
            "2f485fcbffa2259d9e1db92d14483c1bef55dcca",
            "9999999999999999999999999999999999999999",
        )
        self.assertNotEqual(notices_text, mutated_text)

        tmp_dir = REPO_ROOT / ".test_tmp"
        tmp_dir.mkdir(exist_ok=True)
        tmp_file = tmp_dir / "mutated_notices.md"
        try:
            tmp_file.write_text(mutated_text, encoding="utf-8")
            rel_path = str(tmp_file.relative_to(REPO_ROOT))
            data = copy.deepcopy(self.raw_inventory)
            data["artifacts"][0]["source_coverage"]["notices_path"] = rel_path
            data["artifacts"][0]["source_of_truth_paths"]["notices"] = rel_path
            data["artifacts"][0]["licence_location"] = rel_path
            errors = validate_provenance.validate_provenance_data(
                data, REPO_ROOT, scope="production-package"
            )
            self.assertTrue(
                any(e.error_code == "REVISION_DRIFT_OR_MISMATCH" for e in errors),
                msg=f"Expected REVISION_DRIFT_OR_MISMATCH, got: {[e.error_code for e in errors]}",
            )
        finally:
            if tmp_file.exists():
                tmp_file.unlink()
            if tmp_dir.exists():
                tmp_dir.rmdir()

    def test_canonical_notices_only_pin_malformed_rejected(self) -> None:
        """Canonical path: notices-only pin with malformed revision is rejected."""
        notices_path = REPO_ROOT / "THIRD_PARTY_NOTICES_POWERTRAIN_BATTERY.md"
        notices_text = notices_path.read_text(encoding="utf-8")
        # Mutate kezarjg/etnga-obd revision to a malformed non-hex string
        mutated_text = notices_text.replace(
            "817da3ec8ab83bf31f000b0d1c85716280ccd843",
            "not-a-40-hex-revision",
        )
        self.assertNotEqual(notices_text, mutated_text)

        tmp_dir = REPO_ROOT / ".test_tmp"
        tmp_dir.mkdir(exist_ok=True)
        tmp_file = tmp_dir / "mutated_notices.md"
        try:
            tmp_file.write_text(mutated_text, encoding="utf-8")
            rel_path = str(tmp_file.relative_to(REPO_ROOT))
            data = copy.deepcopy(self.raw_inventory)
            data["artifacts"][0]["source_coverage"]["notices_path"] = rel_path
            data["artifacts"][0]["source_of_truth_paths"]["notices"] = rel_path
            data["artifacts"][0]["licence_location"] = rel_path
            errors = validate_provenance.validate_provenance_data(
                data, REPO_ROOT, scope="production-package"
            )
            self.assertTrue(
                any(e.error_code == "MALFORMED_REVISION" for e in errors),
                msg=f"Expected MALFORMED_REVISION, got: {[e.error_code for e in errors]}",
            )
        finally:
            if tmp_file.exists():
                tmp_file.unlink()
            if tmp_dir.exists():
                tmp_dir.rmdir()

    def test_canonical_notices_unowned_pin_rejected(self) -> None:
        """Canonical path: unowned repository pin injected into notices is rejected."""
        notices_path = REPO_ROOT / "THIRD_PARTY_NOTICES_POWERTRAIN_BATTERY.md"
        notices_text = notices_path.read_text(encoding="utf-8")
        # Inject an unowned pin into notices
        injected_pin = "\n- `untrusted/rogue-obd-repo`, pinned at `1111111111111111111111111111111111111111`.\n"
        mutated_text = notices_text + injected_pin

        tmp_dir = REPO_ROOT / ".test_tmp"
        tmp_dir.mkdir(exist_ok=True)
        tmp_file = tmp_dir / "mutated_notices.md"
        try:
            tmp_file.write_text(mutated_text, encoding="utf-8")
            rel_path = str(tmp_file.relative_to(REPO_ROOT))
            data = copy.deepcopy(self.raw_inventory)
            data["artifacts"][0]["source_coverage"]["notices_path"] = rel_path
            data["artifacts"][0]["source_of_truth_paths"]["notices"] = rel_path
            data["artifacts"][0]["licence_location"] = rel_path
            errors = validate_provenance.validate_provenance_data(
                data, REPO_ROOT, scope="production-package"
            )
            self.assertTrue(
                any(e.error_code == "UNOWNED_SOURCE_DETECTED" for e in errors),
                msg=f"Expected UNOWNED_SOURCE_DETECTED, got: {[e.error_code for e in errors]}",
            )
        finally:
            if tmp_file.exists():
                tmp_file.unlink()
            if tmp_dir.exists():
                tmp_dir.rmdir()

    def test_canonical_source_coverage_path_drift_rejected(self) -> None:
        """Canonical path: source_coverage path drifting from truth/manifest/licence is rejected."""
        # 1. notices_path drifts to another existing file (e.g. README.md)
        data1 = copy.deepcopy(self.raw_inventory)
        data1["artifacts"][0]["source_coverage"]["notices_path"] = "README.md"
        errors1 = validate_provenance.validate_provenance_data(
            data1, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "SOURCE_PATH_DRIFT" for e in errors1),
            msg=f"Expected SOURCE_PATH_DRIFT, got: {[e.error_code for e in errors1]}",
        )

        # 2. catalog_path drifts to another existing file (e.g. pubspec.yaml)
        data2 = copy.deepcopy(self.raw_inventory)
        data2["artifacts"][0]["source_coverage"]["catalog_path"] = "pubspec.yaml"
        errors2 = validate_provenance.validate_provenance_data(
            data2, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "SOURCE_PATH_DRIFT" for e in errors2),
            msg=f"Expected SOURCE_PATH_DRIFT, got: {[e.error_code for e in errors2]}",
        )

        # 3. evidence_matrix_path drifts to another existing file
        data3 = copy.deepcopy(self.raw_inventory)
        data3["artifacts"][0]["source_coverage"]["evidence_matrix_path"] = "pubspec.yaml"
        errors3 = validate_provenance.validate_provenance_data(
            data3, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "SOURCE_PATH_DRIFT" for e in errors3),
            msg=f"Expected SOURCE_PATH_DRIFT, got: {[e.error_code for e in errors3]}",
        )

    def test_canonical_notices_only_pin_missing_dual_license_rejected(self) -> None:
        """Canonical path: dual-licensed notices-only record missing any required licence is rejected."""
        notices_path = REPO_ROOT / "THIRD_PARTY_NOTICES_POWERTRAIN_BATTERY.md"
        notices_text = notices_path.read_text(encoding="utf-8")

        tmp_dir = REPO_ROOT / ".test_tmp"
        tmp_dir.mkdir(exist_ok=True)
        try:
            # 1. Keep MIT, remove CC-BY-4.0
            mutated1 = notices_text.replace("CC-BY-4.0", "UNSPECIFIED")
            tmp_file1 = tmp_dir / "mutated_notices1.md"
            tmp_file1.write_text(mutated1, encoding="utf-8")
            rel1 = str(tmp_file1.relative_to(REPO_ROOT))

            data1 = copy.deepcopy(self.raw_inventory)
            data1["artifacts"][0]["source_coverage"]["notices_path"] = rel1
            data1["artifacts"][0]["source_of_truth_paths"]["notices"] = rel1
            data1["artifacts"][0]["licence_location"] = rel1
            errors1 = validate_provenance.validate_provenance_data(
                data1, REPO_ROOT, scope="production-package"
            )
            self.assertTrue(
                any(e.error_code == "LICENCE_MISSING" for e in errors1),
                msg=f"Expected LICENCE_MISSING when CC-BY-4.0 removed, got: {[e.error_code for e in errors1]}",
            )

            # 2. Keep CC-BY-4.0, remove MIT from etnga-obd snippet
            mutated2 = notices_text.replace("`bin/` MIT;", "`bin/` GPL-3.0;")
            tmp_file2 = tmp_dir / "mutated_notices2.md"
            tmp_file2.write_text(mutated2, encoding="utf-8")
            rel2 = str(tmp_file2.relative_to(REPO_ROOT))

            data2 = copy.deepcopy(self.raw_inventory)
            data2["artifacts"][0]["source_coverage"]["notices_path"] = rel2
            data2["artifacts"][0]["source_of_truth_paths"]["notices"] = rel2
            data2["artifacts"][0]["licence_location"] = rel2
            errors2 = validate_provenance.validate_provenance_data(
                data2, REPO_ROOT, scope="production-package"
            )
            self.assertTrue(
                any(e.error_code == "LICENCE_MISSING" for e in errors2),
                msg=f"Expected LICENCE_MISSING when MIT removed, got: {[e.error_code for e in errors2]}",
            )
        finally:
            for p in tmp_dir.glob("*"):
                p.unlink()
            if tmp_dir.exists():
                tmp_dir.rmdir()

    def test_catalog_manifest_spec_missing_rejected(self) -> None:
        """Missing catalog_manifest dictionary in inventory fails closed."""
        data = copy.deepcopy(self.raw_inventory)
        del data["artifacts"][0]["catalog_manifest"]
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "CATALOG_MANIFEST_SPEC_MISSING" for e in errors),
            msg=f"Expected CATALOG_MANIFEST_SPEC_MISSING, got: {[e.error_code for e in errors]}",
        )

    def test_catalog_manifest_malformed_fields_rejected(self) -> None:
        """Malformed expected_sha256 or non-positive sizes fail closed."""
        # 1. Malformed SHA256
        data1 = copy.deepcopy(self.raw_inventory)
        data1["artifacts"][0]["catalog_manifest"]["expected_sha256"] = "not-a-64-hex-digest"
        errors1 = validate_provenance.validate_provenance_data(
            data1, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(any(e.error_code == "MALFORMED_SHA256" for e in errors1))

        # 2. Invalid size
        data2 = copy.deepcopy(self.raw_inventory)
        data2["artifacts"][0]["catalog_manifest"]["expected_size_bytes"] = -1
        errors2 = validate_provenance.validate_provenance_data(
            data2, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(any(e.error_code == "CATALOG_SIZE_MISMATCH" for e in errors2))

    def test_runtime_licence_registry_assets_missing_or_empty_rejected(self) -> None:
        """Missing or empty runtime_licence_registry_assets fails closed."""
        # Missing key
        data1 = copy.deepcopy(self.raw_inventory)
        del data1["artifacts"][0]["runtime_licence_registry_assets"]
        errors1 = validate_provenance.validate_provenance_data(
            data1, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "LICENCE_REGISTRY_ASSETS_MISSING" for e in errors1)
        )

        # Empty list
        data2 = copy.deepcopy(self.raw_inventory)
        data2["artifacts"][0]["runtime_licence_registry_assets"] = []
        errors2 = validate_provenance.validate_provenance_data(
            data2, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "LICENCE_REGISTRY_ASSETS_MISSING" for e in errors2)
        )

    def test_runtime_licence_registry_assets_bidirectional_parity_enforced(self) -> None:
        """Omitting a Dart registered licence asset from inventory fails closed."""
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["runtime_licence_registry_assets"] = [
            a for a in data["artifacts"][0]["runtime_licence_registry_assets"]
            if a != "assets/licenses/GPL-3.0.txt"
        ]
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(
                e.error_code == "LICENCE_REGISTRY_ASSET_MISSING"
                and "GPL-3.0.txt" in e.message
                for e in errors
            ),
            msg=f"Expected LICENCE_REGISTRY_ASSET_MISSING for omitted Dart asset, got: {[e.message for e in errors]}",
        )

    def test_artifact_class_missing_or_mismatch_rejected(self) -> None:
        """Missing or mismatched artifact_class fails closed."""
        # Missing
        data1 = copy.deepcopy(self.raw_inventory)
        del data1["artifacts"][0]["artifact_class"]
        errors1 = validate_provenance.validate_provenance_data(
            data1, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(any(e.error_code == "MISSING_ARTIFACT_CLASS" for e in errors1))

        # Mismatch
        data2 = copy.deepcopy(self.raw_inventory)
        data2["artifacts"][0]["artifact_class"] = "other-class"
        errors2 = validate_provenance.validate_provenance_data(
            data2, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(any(e.error_code == "ARTIFACT_CLASS_MISMATCH" for e in errors2))

    def test_owning_issues_boolean_rejected(self) -> None:
        """Booleans in owning_issues are strictly rejected."""
        data1 = copy.deepcopy(self.raw_inventory)
        data1["artifacts"][0]["owning_issues"] = [True]
        errors1 = validate_provenance.validate_provenance_data(
            data1, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(any(e.error_code == "OWNING_ISSUES_MISSING" for e in errors1))

    def test_remediation_required_subkeys_missing_rejected(self) -> None:
        """Missing on_rights_revocation or on_integrity_failure in remediation fails closed."""
        data1 = copy.deepcopy(self.raw_inventory)
        del data1["artifacts"][0]["remediation"]["on_rights_revocation"]
        errors1 = validate_provenance.validate_provenance_data(
            data1, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(any(e.error_code == "REMEDIATION_MISSING" for e in errors1))

        data2 = copy.deepcopy(self.raw_inventory)
        data2["artifacts"][0]["remediation"]["on_integrity_failure"] = "   "
        errors2 = validate_provenance.validate_provenance_data(
            data2, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(any(e.error_code == "REMEDIATION_MISSING" for e in errors2))

    def test_notices_owned_licence_identifier_drift_rejected(self) -> None:
        """Omitting notices-owned required licence from licence_identifier emits LICENCE_IDENTIFIER_DRIFT."""
        data = copy.deepcopy(self.raw_inventory)
        # Remove CC-BY-4.0 from licence_identifier string
        data["artifacts"][0]["licence_identifier"] = (
            "Multi-licence (Apache-2.0, MIT, GPL-3.0, GPL-3.0-or-later, CC-BY-SA-4.0, U.S.-Government-Public-Domain)"
        )
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(
                e.error_code == "LICENCE_IDENTIFIER_DRIFT"
                and "CC-BY-4.0" in e.message
                for e in errors
            ),
            msg=f"Expected LICENCE_IDENTIFIER_DRIFT for CC-BY-4.0, got: {[f'{e.error_code}: {e.message}' for e in errors]}",
        )

    def test_notices_token_boundary_embedded_word_rejected(self) -> None:
        """Token boundary check: embedded substring like COMMIT does not satisfy MIT requirement."""
        notices_path = REPO_ROOT / "THIRD_PARTY_NOTICES_POWERTRAIN_BATTERY.md"
        notices_text = notices_path.read_text(encoding="utf-8")

        tmp_dir = REPO_ROOT / ".test_tmp_boundary"
        tmp_dir.mkdir(exist_ok=True)
        try:
            # Replace 'bin/` MIT;' with 'bin/` COMMITTED;'
            mutated = notices_text.replace("`bin/` MIT;", "`bin/` COMMITTED;")
            tmp_file = tmp_dir / "mutated_notices_boundary.md"
            tmp_file.write_text(mutated, encoding="utf-8")
            rel = str(tmp_file.relative_to(REPO_ROOT))

            data = copy.deepcopy(self.raw_inventory)
            data["artifacts"][0]["source_coverage"]["notices_path"] = rel
            data["artifacts"][0]["source_of_truth_paths"]["notices"] = rel
            data["artifacts"][0]["licence_location"] = rel
            errors = validate_provenance.validate_provenance_data(
                data, REPO_ROOT, scope="production-package"
            )
            self.assertTrue(
                any(
                    e.error_code == "LICENCE_MISSING" and "MIT" in e.message
                    for e in errors
                ),
                msg=f"Expected LICENCE_MISSING when MIT is only embedded in COMMITTED, got: {[e.message for e in errors]}",
            )
        finally:
            for p in tmp_dir.glob("*"):
                p.unlink()
            if tmp_dir.exists():
                tmp_dir.rmdir()




class TestValidateProvenanceSlice2(unittest.TestCase):
    """Slice 2 tests: Test-only oracle & reference provenance, lockfile validation, and mutations."""

    def setUp(self) -> None:
        self.inventory_path = REPO_ROOT / "docs/provenance/inventory.json"
        self.raw_inventory = json.loads(
            self.inventory_path.read_text(encoding="utf-8")
        )

    def _get_artifact(self, data: dict, art_id: str) -> dict:
        for a in data["artifacts"]:
            if a.get("id") == art_id:
                return a
        raise KeyError(f"Artifact not found: {art_id}")

    # =========================================================================
    # S2 Scope & Schema Tests
    # =========================================================================

    def test_canonical_test_only_scope_passes(self) -> None:
        """S2-A4: Canonical inventory passes under --scope test-only."""
        errors = validate_provenance.validate_provenance_data(
            self.raw_inventory, REPO_ROOT, scope="test-only"
        )
        self.assertEqual(errors, [])

    def test_canonical_all_scope_passes(self) -> None:
        """S2-A1: Canonical inventory passes under --scope all."""
        errors = validate_provenance.validate_provenance_data(
            self.raw_inventory, REPO_ROOT, scope="all"
        )
        self.assertEqual(errors, [])

    def test_cli_test_only_and_all_scopes(self) -> None:
        """S2-A3, S2-A4: CLI returns 0 for test-only and all scopes."""
        for sc in ("test-only", "all"):
            cmd = [
                sys.executable,
                str(TOOL_DIR / "validate_provenance.py"),
                "--scope",
                sc,
                "--inventory",
                str(self.inventory_path),
                "--repo-root",
                str(REPO_ROOT),
            ]
            res = subprocess.run(cmd, capture_output=True, text=True, check=False)
            self.assertEqual(res.returncode, 0, msg=f"CLI failed for scope {sc}: {res.stderr}")
            self.assertIn("[PASS]", res.stdout)

    def test_unknown_scope_rejected(self) -> None:
        """Unknown scope argument must be rejected."""
        errors = validate_provenance.validate_provenance_data(
            self.raw_inventory, REPO_ROOT, scope="invalid-scope"
        )
        self.assertTrue(any(e.error_code == "INVALID_SCOPE" for e in errors))

    def test_duplicate_artifact_id_across_scopes_rejected(self) -> None:
        """Duplicate artifact ID across scopes must fail closed."""
        data = copy.deepcopy(self.raw_inventory)
        dup = copy.deepcopy(data["artifacts"][0])
        dup["scope"] = "test-only"
        data["artifacts"].append(dup)
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="all"
        )
        self.assertTrue(any(e.error_code == "DUPLICATE_ARTIFACT_ID" for e in errors))

    def test_production_artifact_in_test_only_class_set_rejected(self) -> None:
        """Production artifact assigned to test-only class set is rejected."""
        data = copy.deepcopy(self.raw_inventory)
        art = self._get_artifact(data, "powertrain-battery-bundled-third-party")
        art["id"] = "ircama-elm327-emulator-test-oracle"
        art["artifact_class"] = "ircama-elm327-emulator-test-oracle"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(any(e.error_code == "UNAUTHORIZED_ARTIFACT_CLASS" for e in errors))

    def test_test_only_artifact_in_production_class_set_rejected(self) -> None:
        """Test-only artifact assigned to production class set is rejected."""
        data = copy.deepcopy(self.raw_inventory)
        art = self._get_artifact(data, "ircama-elm327-emulator-test-oracle")
        art["id"] = "powertrain-battery-bundled-third-party"
        art["artifact_class"] = "powertrain-battery-bundled-third-party"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "UNAUTHORIZED_ARTIFACT_CLASS" for e in errors))

    # =========================================================================
    # S2 Mutation Tests (S2-M1 to S2-M7)
    # =========================================================================

    def test_s2_m1_ircama_version_and_hash_drift(self) -> None:
        """S2-M1: Ircama version or hash drift causes test-only RED, production GREEN."""
        # Version drift
        data_ver = copy.deepcopy(self.raw_inventory)
        ircama = self._get_artifact(data_ver, "ircama-elm327-emulator-test-oracle")
        ircama["source"]["version"] = "3.0.4"
        errors_test = validate_provenance.validate_provenance_data(
            data_ver, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "LOCKFILE_VERSION_DRIFT" for e in errors_test))
        errors_prod = validate_provenance.validate_provenance_data(
            data_ver, REPO_ROOT, scope="production-package"
        )
        self.assertEqual(errors_prod, [], msg="Production package must remain GREEN on test-only drift")

        # Hash drift
        data_hash = copy.deepcopy(self.raw_inventory)
        ircama_h = self._get_artifact(data_hash, "ircama-elm327-emulator-test-oracle")
        ircama_h["source"]["artifact_sha256"] = "0" * 64
        errors_test_h = validate_provenance.validate_provenance_data(
            data_hash, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "LOCKFILE_HASH_DRIFT" for e in errors_test_h))
        errors_prod_h = validate_provenance.validate_provenance_data(
            data_hash, REPO_ROOT, scope="production-package"
        )
        self.assertEqual(errors_prod_h, [])

    def test_s2_m2_test_only_role_and_package_escalation(self) -> None:
        """S2-M2: Test-only artifact role or package escalation must fail."""
        data_role = copy.deepcopy(self.raw_inventory)
        ircama = self._get_artifact(data_role, "ircama-elm327-emulator-test-oracle")
        ircama["role"] = "runtime"
        errors = validate_provenance.validate_provenance_data(
            data_role, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "TEST_ONLY_ROLE_ESCALATION" for e in errors))

        data_pkg = copy.deepcopy(self.raw_inventory)
        ircama2 = self._get_artifact(data_pkg, "ircama-elm327-emulator-test-oracle")
        ircama2["package_policy"]["app_package"] = "allowed"
        errors2 = validate_provenance.validate_provenance_data(
            data_pkg, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "PACKAGE_POLICY_INVALID" for e in errors2))

        data_chan = copy.deepcopy(self.raw_inventory)
        ircama3 = self._get_artifact(data_chan, "ircama-elm327-emulator-test-oracle")
        ircama3["distribution_channel"] = "app-package"
        errors3 = validate_provenance.validate_provenance_data(
            data_chan, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "DISTRIBUTION_CHANNEL_INVALID" for e in errors3))

    def test_s2_m3_independence_laundering(self) -> None:
        """S2-M3: Project-owned references cannot be classified as independent-third-party-oracle."""
        data_chaos = copy.deepcopy(self.raw_inventory)
        chaos = self._get_artifact(data_chaos, "telltale-chaos-proxy-test-reference")
        chaos["independence"] = "independent-third-party-oracle"
        errors = validate_provenance.validate_provenance_data(
            data_chaos, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "INDEPENDENCE_LAUNDERING" for e in errors))

        data_freeze = copy.deepcopy(self.raw_inventory)
        freeze = self._get_artifact(data_freeze, "telltale-freeze-frame-reference")
        freeze["ownership"] = "third-party"
        errors2 = validate_provenance.validate_provenance_data(
            data_freeze, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "OWNERSHIP_MISCLASSIFICATION" for e in errors2))

        data_mode08 = copy.deepcopy(self.raw_inventory)
        mode08 = self._get_artifact(data_mode08, "telltale-mode08-replay-reference")
        mode08["ownership"] = "third-party"
        errors3 = validate_provenance.validate_provenance_data(
            data_mode08, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "OWNERSHIP_MISCLASSIFICATION" for e in errors3))

    def test_s2_m4_project_owned_integrity_bypass(self) -> None:
        """S2-M4: Project-owned reference / fixture hash drift must fail."""
        data_ff = copy.deepcopy(self.raw_inventory)
        ff = self._get_artifact(data_ff, "telltale-freeze-frame-reference")
        ff["project_source"]["integrity_files"][0]["sha256"] = "1" * 64
        errors = validate_provenance.validate_provenance_data(
            data_ff, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "INTEGRITY_HASH_MISMATCH" for e in errors))

        data_m08 = copy.deepcopy(self.raw_inventory)
        m08 = self._get_artifact(data_m08, "telltale-mode08-replay-reference")
        m08["project_source"]["integrity_files"][1]["sha256"] = "2" * 64
        errors2 = validate_provenance.validate_provenance_data(
            data_m08, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "INTEGRITY_HASH_MISMATCH" for e in errors2))

        # Missing fixtures file from mode08 integrity files
        data_m08_inc = copy.deepcopy(self.raw_inventory)
        m08_inc = self._get_artifact(data_m08_inc, "telltale-mode08-replay-reference")
        m08_inc["project_source"]["integrity_files"] = [m08_inc["project_source"]["integrity_files"][0]]
        errors3 = validate_provenance.validate_provenance_data(
            data_m08_inc, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "INTEGRITY_FILES_INCOMPLETE" for e in errors3))

    def test_s2_m5_runner_contracts(self) -> None:
        """S2-M5: Hardened runner contract negative controls:
        1. Deleting --require-hashes -> RED (RUNNER_UNHASHED_INSTALL_PROHIBITED)
        2. Swapping to undeclared requirements file -> RED (RUNNER_UNDECLARED_REQUIREMENTS)
        3. Deleting version preflight -> RED (RUNNER_VERSION_PREFLIGHT_MISSING)
        4. Changing preflight version 3.0.5 to another valid version 3.0.6 -> RED (RUNNER_PREFLIGHT_VERSION_MISMATCH)
        5. Removing reference to declared lockfile -> RED (RUNNER_LOCKFILE_MISSING)
        """
        real_runner_path = REPO_ROOT / "tool/workshop/run_public_oracles.sh"
        real_text = real_runner_path.read_text(encoding="utf-8")
        tmp_dir = REPO_ROOT / ".test_tmp_runner"
        tmp_dir.mkdir(exist_ok=True)
        try:
            # 1. Delete --require-hashes
            mutated_1 = tmp_dir / "mutated_no_hashes.sh"
            mutated_1.write_text(real_text.replace("--require-hashes", ""), encoding="utf-8")
            data1 = copy.deepcopy(self.raw_inventory)
            self._get_artifact(data1, "ircama-elm327-emulator-test-oracle")["execution_bindings"]["runner_script"] = str(mutated_1.relative_to(REPO_ROOT))
            errs1 = validate_provenance.validate_provenance_data(data1, REPO_ROOT, scope="test-only")
            self.assertTrue(any(e.error_code == "RUNNER_UNHASHED_INSTALL_PROHIBITED" for e in errs1))

            # 2. Swap to undeclared requirements file
            mutated_2 = tmp_dir / "mutated_undeclared_reqs.sh"
            mutated_2.write_text(
                real_text.replace(
                    "$ROOT/tool/ble_test_rig/requirements.lock",
                    "$ROOT/tool/ble_test_rig/undeclared_unpinned.txt",
                ),
                encoding="utf-8",
            )
            data2 = copy.deepcopy(self.raw_inventory)
            self._get_artifact(data2, "ircama-elm327-emulator-test-oracle")["execution_bindings"]["runner_script"] = str(mutated_2.relative_to(REPO_ROOT))
            errs2 = validate_provenance.validate_provenance_data(data2, REPO_ROOT, scope="test-only")
            self.assertTrue(any(e.error_code == "RUNNER_UNDECLARED_REQUIREMENTS" for e in errs2))

            # 3. Delete version preflight
            mutated_3 = tmp_dir / "mutated_no_preflight.sh"
            mutated_3.write_text(
                re.sub(r'INSTALLED_ELM_VER=.*?(?=start_elm)', '', real_text, flags=re.DOTALL),
                encoding="utf-8",
            )
            data3 = copy.deepcopy(self.raw_inventory)
            self._get_artifact(data3, "ircama-elm327-emulator-test-oracle")["execution_bindings"]["runner_script"] = str(mutated_3.relative_to(REPO_ROOT))
            errs3 = validate_provenance.validate_provenance_data(data3, REPO_ROOT, scope="test-only")
            self.assertTrue(any(e.error_code == "RUNNER_VERSION_PREFLIGHT_MISSING" for e in errs3))

            # 4. Change preflight version 3.0.5 to another version 3.0.6
            mutated_4 = tmp_dir / "mutated_wrong_version.sh"
            mutated_4.write_text(
                real_text.replace('"3.0.5"', '"3.0.6"'),
                encoding="utf-8",
            )
            data4 = copy.deepcopy(self.raw_inventory)
            self._get_artifact(data4, "ircama-elm327-emulator-test-oracle")["execution_bindings"]["runner_script"] = str(mutated_4.relative_to(REPO_ROOT))
            errs4 = validate_provenance.validate_provenance_data(data4, REPO_ROOT, scope="test-only")
            self.assertTrue(any(e.error_code == "RUNNER_PREFLIGHT_VERSION_MISMATCH" for e in errs4))

            # 5. Missing declared lockfile
            mutated_5 = tmp_dir / "mutated_missing_lock.sh"
            mutated_5.write_text(
                real_text.replace(".github/requirements/elm327-py314-linux-x86_64.lock", ".github/requirements/other.lock"),
                encoding="utf-8",
            )
            data5 = copy.deepcopy(self.raw_inventory)
            self._get_artifact(data5, "ircama-elm327-emulator-test-oracle")["execution_bindings"]["runner_script"] = str(mutated_5.relative_to(REPO_ROOT))
            errs5 = validate_provenance.validate_provenance_data(data5, REPO_ROOT, scope="test-only")
            self.assertTrue(any(e.error_code == "RUNNER_LOCKFILE_MISSING" for e in errs5))
        finally:
            for p in tmp_dir.glob("*"):
                p.unlink()
            if tmp_dir.exists():
                tmp_dir.rmdir()

    def test_s2_m6_scope_isolation(self) -> None:
        """S2-M6: Fault in test-only breaks test-only and all, but preserves production-package;
        fault in production breaks production and all, but preserves test-only."""
        # 1. Break test-only (Ircama hash)
        data_test_broken = copy.deepcopy(self.raw_inventory)
        ircama = self._get_artifact(data_test_broken, "ircama-elm327-emulator-test-oracle")
        ircama["source"]["artifact_sha256"] = "f" * 64

        self.assertTrue(
            any(e.error_code == "LOCKFILE_HASH_DRIFT" for e in validate_provenance.validate_provenance_data(data_test_broken, REPO_ROOT, scope="test-only"))
        )
        self.assertTrue(
            any(e.error_code == "LOCKFILE_HASH_DRIFT" for e in validate_provenance.validate_provenance_data(data_test_broken, REPO_ROOT, scope="all"))
        )
        self.assertEqual(
            validate_provenance.validate_provenance_data(data_test_broken, REPO_ROOT, scope="production-package"),
            [],
            msg="production-package must stay GREEN when test-only is broken",
        )

        # 2. Break test-only artifact_class
        data_test_class_broken = copy.deepcopy(self.raw_inventory)
        ircama_cls = self._get_artifact(data_test_class_broken, "ircama-elm327-emulator-test-oracle")
        ircama_cls["artifact_class"] = "corrupted-test-oracle-class"

        errs_to = validate_provenance.validate_provenance_data(data_test_class_broken, REPO_ROOT, scope="test-only")
        errs_all = validate_provenance.validate_provenance_data(data_test_class_broken, REPO_ROOT, scope="all")
        errs_prod = validate_provenance.validate_provenance_data(data_test_class_broken, REPO_ROOT, scope="production-package")

        self.assertTrue(any(e.error_code == "ARTIFACT_CLASS_MISMATCH" for e in errs_to))
        self.assertTrue(any(e.error_code == "ARTIFACT_CLASS_MISMATCH" for e in errs_all))
        self.assertEqual(errs_prod, [], msg="production-package must stay GREEN when test-only artifact_class is corrupted")

        # 3. Test-only unauthorized ID
        data_test_unauth_id = copy.deepcopy(self.raw_inventory)
        chaos = self._get_artifact(data_test_unauth_id, "telltale-chaos-proxy-test-reference")
        chaos["id"] = "unauthorized-test-chaos-proxy"
        chaos["artifact_class"] = "unauthorized-test-chaos-proxy"

        errs_to_id = validate_provenance.validate_provenance_data(data_test_unauth_id, REPO_ROOT, scope="test-only")
        errs_all_id = validate_provenance.validate_provenance_data(data_test_unauth_id, REPO_ROOT, scope="all")
        errs_prod_id = validate_provenance.validate_provenance_data(data_test_unauth_id, REPO_ROOT, scope="production-package")

        self.assertTrue(any(e.error_code == "UNAUTHORIZED_ARTIFACT_CLASS" for e in errs_to_id))
        self.assertTrue(any(e.error_code == "UNAUTHORIZED_ARTIFACT_CLASS" for e in errs_all_id))
        self.assertEqual(errs_prod_id, [], msg="production-package must stay GREEN when test-only has unauthorized ID")

        # 4. Break production-package (battery manifest expected_sha256)
        data_prod_broken = copy.deepcopy(self.raw_inventory)
        battery = self._get_artifact(data_prod_broken, "powertrain-battery-bundled-third-party")
        battery["catalog_manifest"]["expected_sha256"] = "e" * 64

        self.assertTrue(
            any(e.error_code == "CATALOG_SHA256_MISMATCH" for e in validate_provenance.validate_provenance_data(data_prod_broken, REPO_ROOT, scope="production-package"))
        )
        self.assertTrue(
            any(e.error_code == "CATALOG_SHA256_MISMATCH" for e in validate_provenance.validate_provenance_data(data_prod_broken, REPO_ROOT, scope="all"))
        )
        self.assertEqual(
            validate_provenance.validate_provenance_data(data_prod_broken, REPO_ROOT, scope="test-only"),
            [],
            msg="test-only must stay GREEN when production-package is broken",
        )

        # 5. Break production artifact_class
        data_prod_class_broken = copy.deepcopy(self.raw_inventory)
        battery_cls = self._get_artifact(data_prod_class_broken, "powertrain-battery-bundled-third-party")
        battery_cls["artifact_class"] = "corrupted-battery-class"

        errs_prod_c = validate_provenance.validate_provenance_data(data_prod_class_broken, REPO_ROOT, scope="production-package")
        errs_all_c = validate_provenance.validate_provenance_data(data_prod_class_broken, REPO_ROOT, scope="all")
        errs_to_c = validate_provenance.validate_provenance_data(data_prod_class_broken, REPO_ROOT, scope="test-only")

        self.assertTrue(any(e.error_code == "ARTIFACT_CLASS_MISMATCH" for e in errs_prod_c))
        self.assertTrue(any(e.error_code == "ARTIFACT_CLASS_MISMATCH" for e in errs_all_c))
        self.assertEqual(errs_to_c, [], msg="test-only must stay GREEN when production artifact_class is corrupted")

        # 6. Production unauthorized ID
        data_prod_unauth_id = copy.deepcopy(self.raw_inventory)
        battery_id = self._get_artifact(data_prod_unauth_id, "powertrain-battery-bundled-third-party")
        battery_id["id"] = "unauthorized-battery-class"
        battery_id["artifact_class"] = "unauthorized-battery-class"

        errs_prod_i = validate_provenance.validate_provenance_data(data_prod_unauth_id, REPO_ROOT, scope="production-package")
        errs_all_i = validate_provenance.validate_provenance_data(data_prod_unauth_id, REPO_ROOT, scope="all")
        errs_to_i = validate_provenance.validate_provenance_data(data_prod_unauth_id, REPO_ROOT, scope="test-only")

        self.assertTrue(any(e.error_code == "UNAUTHORIZED_ARTIFACT_CLASS" for e in errs_prod_i))
        self.assertTrue(any(e.error_code == "UNAUTHORIZED_ARTIFACT_CLASS" for e in errs_all_i))
        self.assertEqual(errs_to_i, [], msg="test-only must stay GREEN when production has unauthorized ID")

    def test_s2_m7_licence_evidence_missing_or_drift(self) -> None:
        """S2-M7: Missing or drifted licence evidence fails test-only validation."""
        # Missing file
        data_missing = copy.deepcopy(self.raw_inventory)
        ircama = self._get_artifact(data_missing, "ircama-elm327-emulator-test-oracle")
        ircama["licence_evidence"]["local_evidence_path"] = "nonexistent/LICENSE"
        errors = validate_provenance.validate_provenance_data(
            data_missing, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "LICENCE_EVIDENCE_MISSING" for e in errors))

        # Hash drift
        data_drift = copy.deepcopy(self.raw_inventory)
        ircama2 = self._get_artifact(data_drift, "ircama-elm327-emulator-test-oracle")
        ircama2["licence_evidence"]["source_sha256"] = "3" * 64
        errors2 = validate_provenance.validate_provenance_data(
            data_drift, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "LICENCE_EVIDENCE_HASH_DRIFT" for e in errors2))

    # =========================================================================
    # Additional Negative & Guard Tests
    # =========================================================================

    def test_ircama_lockfile_floating_spec_rejected(self) -> None:
        """Lockfile containing range or floating spec for Ircama is rejected."""
        tmp_dir = REPO_ROOT / ".test_tmp_lock"
        tmp_dir.mkdir(exist_ok=True)
        try:
            mutated_lock = tmp_dir / "mutated_elm.lock"
            mutated_lock.write_text(
                "ELM327-emulator>=3.0.5 --hash=sha256:c4527894abd613f36c87ecba47b6b4ea91fd2b123509fd71d9e49ab41e656d87\n",
                encoding="utf-8",
            )
            data = copy.deepcopy(self.raw_inventory)
            ircama = self._get_artifact(data, "ircama-elm327-emulator-test-oracle")
            ircama["source"]["lockfiles"] = [str(mutated_lock.relative_to(REPO_ROOT))]
            errors = validate_provenance.validate_provenance_data(
                data, REPO_ROOT, scope="test-only"
            )
            self.assertTrue(any(e.error_code == "LOCKFILE_FLOATING_SPEC" for e in errors))
        finally:
            for p in tmp_dir.glob("*"):
                p.unlink()
            if tmp_dir.exists():
                tmp_dir.rmdir()

    def test_freeze_frame_and_mode08_identity_banners_enforced(self) -> None:
        """Identity banners for freeze-frame and Mode08 cannot be relabelled as Ircama."""
        data_ff = copy.deepcopy(self.raw_inventory)
        ff = self._get_artifact(data_ff, "telltale-freeze-frame-reference")
        ff["project_source"]["identity_banner"] = "Ircama ELM327 Emulator"
        errors = validate_provenance.validate_provenance_data(
            data_ff, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "IDENTITY_BANNER_MISMATCH" for e in errors))

        data_m08 = copy.deepcopy(self.raw_inventory)
        m08 = self._get_artifact(data_m08, "telltale-mode08-replay-reference")
        m08["project_source"]["identity_banner"] = "Ircama ELM327 Emulator"
        errors2 = validate_provenance.validate_provenance_data(
            data_m08, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "IDENTITY_BANNER_MISMATCH" for e in errors2))

    def test_unresolved_decision_rejected(self) -> None:
        """Unresolved ('unknown') distribution or commercial decisions fail closed."""
        data = copy.deepcopy(self.raw_inventory)
        ircama = self._get_artifact(data, "ircama-elm327-emulator-test-oracle")
        ircama["distribution_decision"] = "unknown"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "DECISION_UNRESOLVED" for e in errors))

        data2 = copy.deepcopy(self.raw_inventory)
        ircama2 = self._get_artifact(data2, "ircama-elm327-emulator-test-oracle")
        ircama2["commercial_use_decision"] = "unknown"
        errors2 = validate_provenance.validate_provenance_data(
            data2, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "DECISION_UNRESOLVED" for e in errors2))

    def test_package_isolation_pubspec_and_registry_leak(self) -> None:
        """Test-only assets leaking into pubspec assets or Dart licence registry fail."""
        data = copy.deepcopy(self.raw_inventory)
        # Mock pubspec containing test-only asset
        errors = validate_provenance.validate_provenance_data(
            data,
            REPO_ROOT,
            scope="test-only",
        )
        self.assertEqual(errors, [])

        # Intentionally inject test-only asset into pubspec assets mock
        pubspec_leaked = {"tool/obd_test_rig/chaos_proxy.py"}
        dart_leaked = {"docs/provenance/upstream/ELM327-emulator-3.0.5.LICENSE"}
        errs_pub = []
        validate_provenance._check_test_only_package_isolation(
            "telltale-chaos-proxy-test-reference",
            self._get_artifact(data, "telltale-chaos-proxy-test-reference"),
            pubspec_leaked,
            set(),
            errs_pub,
        )
        self.assertTrue(any(e.error_code == "TEST_ONLY_ASSET_IN_PUBSPEC" for e in errs_pub))

        errs_reg = []
        validate_provenance._check_test_only_package_isolation(
            "ircama-elm327-emulator-test-oracle",
            self._get_artifact(data, "ircama-elm327-emulator-test-oracle"),
            set(),
            dart_leaked,
            errs_reg,
        )
        self.assertTrue(any(e.error_code == "TEST_ONLY_ASSET_IN_REGISTRY" for e in errs_reg))

    def test_execution_bindings_flags_missing(self) -> None:
        """Required oracle execution flags missing from execution_bindings must fail."""
        data = copy.deepcopy(self.raw_inventory)
        ircama = self._get_artifact(data, "ircama-elm327-emulator-test-oracle")
        ircama["execution_bindings"]["required_flags"] = []
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "EXECUTION_BINDING_FLAG_MISSING" for e in errors))

        data2 = copy.deepcopy(self.raw_inventory)
        m08 = self._get_artifact(data2, "telltale-mode08-replay-reference")
        m08["execution_bindings"]["required_flags"] = []
        errors2 = validate_provenance.validate_provenance_data(
            data2, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "EXECUTION_BINDING_FLAG_MISSING" for e in errors2))

    def test_missing_integrity_or_test_path_rejected(self) -> None:
        """Nonexistent integrity files or test paths must fail."""
        data = copy.deepcopy(self.raw_inventory)
        chaos = self._get_artifact(data, "telltale-chaos-proxy-test-reference")
        chaos["project_source"]["integrity_files"][0]["path"] = "tool/missing_chaos.py"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "INTEGRITY_FILE_MISSING" for e in errors))

        data2 = copy.deepcopy(self.raw_inventory)
        ff = self._get_artifact(data2, "telltale-freeze-frame-reference")
        ff["execution_bindings"]["test_paths"] = ["test/missing_oracle_test.dart"]
        errors2 = validate_provenance.validate_provenance_data(
            data2, REPO_ROOT, scope="test-only"
        )
        self.assertTrue(any(e.error_code == "EXECUTION_TEST_PATH_MISSING" for e in errors2))


if __name__ == "__main__":
    unittest.main()


