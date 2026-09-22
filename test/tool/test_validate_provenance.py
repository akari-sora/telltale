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

    def test_malformed_revision_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["source_families"][0]["revision"] = "not-a-sha-commit"
        errors = validate_provenance.validate_provenance_data(
            data, REPO_ROOT, scope="production-package"
        )
        self.assertTrue(
            any(e.error_code == "MALFORMED_REVISION" for e in errors)
        )

    def test_malformed_digest_rejected(self) -> None:
        data = copy.deepcopy(self.raw_inventory)
        data["artifacts"][0]["source_families"][0]["artifact_sha256"] = "short"
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


if __name__ == "__main__":
    unittest.main()
