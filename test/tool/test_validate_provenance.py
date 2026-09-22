#!/usr/bin/env python3
"""Tests for tool/workshop/validate_provenance.py (Issue #11, WS-07 Slice 1)."""
from __future__ import annotations

import copy
import json
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


if __name__ == "__main__":
    unittest.main()

