#!/usr/bin/env python3
"""Offline, deterministic validator for Telltale provenance inventory (Issue #11, WS-07).

Validates that declared public and packaged artifacts have complete source
provenance, immutable revisions/digests, verified licences, approved distribution
and commercial-use decisions, reviewer status, remediation paths, and that required
packaged assets are present on disk, in pubspec.yaml, and in runtime licence registries.

Usage:
    python3 tool/workshop/validate_provenance.py [--scope production-package]
                                                [--inventory docs/provenance/inventory.json]
                                                [--repo-root .]
                                                [--format text|json]

Exit code 0 on success, non-zero on failure.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

SUPPORTED_SCHEMA_VERSIONS = {1}
ALLOWED_SCOPES = {"production-package", "all"}
ALLOWED_ROLES = {"runtime", "bundled", "test-only"}
ALLOWED_DISTRIBUTION_DECISIONS = {
    "approved",
    "restricted",
    "replace_required",
    "not_distributed",
    "unknown",
}
ALLOWED_COMMERCIAL_DECISIONS = {
    "allowed",
    "restricted",
    "unknown",
    "not_applicable",
}
ALLOWED_REVIEWER_STATUS = {"reviewed", "pending", "unreviewed"}

SHA40_RE = re.compile(r"^[0-9a-f]{40}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
REVISION_RE = re.compile(r"^(?:[0-9a-f]{40}|[0-9a-f]{64})$")
WILDCARD_RE = re.compile(r"[\*\?\[\]]")

# Slice 1 finite boundary: exactly one declared artifact class.
SLICE1_ALLOWED_CLASSES = frozenset({"powertrain-battery-bundled-third-party"})

# Permitted open-source licences for bundled and reference components.
PERMITTED_OPEN_SOURCE_LICENSES = frozenset({
    "Apache-2.0",
    "MIT",
    "GPL-3.0",
    "GPL-3.0-or-later",
    "CC-BY-SA-4.0",
    "CC-BY-4.0",
    "U.S.-Government-Public-Domain",
})

# Pinned upstream repositories in notices not directly participating in matrix rows.
NOTICES_OWNED_PROVENANCE_RECORDS: dict[str, dict[str, Any]] = {
    "kezarjg/etnga-obd": {
        "name": "kezarjg/etnga-obd",
        "required_licenses": frozenset({"CC-BY-4.0", "MIT"}),
        "expected_revision": "817da3ec8ab83bf31f000b0d1c85716280ccd843",
    },
    "kezarjg/open-vehicle-monitoring-system-3": {
        "name": "kezarjg/Open-Vehicle-Monitoring-System-3",
        "required_licenses": frozenset({"MIT"}),
        "expected_revision": "21474124189f8b6483467c6accfd74381d233bed",
    },
    "nickn17/evdash": {
        "name": "nickn17/evDash",
        "required_licenses": frozenset({"MIT"}),
        "expected_revision": "c8c1e2d3acd6afa4719fa78b10359cd6708c72b2",
    },
}


@dataclass(frozen=True)
class ValidationError:
    artifact_id: str
    error_code: str
    message: str


def parse_pubspec_assets(pubspec_path: Path) -> set[str]:
    """Extracts declared assets from pubspec.yaml."""
    if not pubspec_path.is_file():
        return set()
    lines = pubspec_path.read_text(encoding="utf-8").splitlines()
    in_assets = False
    assets = set()
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("#"):
            continue
        if line.startswith("  assets:"):
            in_assets = True
            continue
        if in_assets:
            if line.startswith("    - "):
                asset = line[6:].strip().split("#")[0].strip()
                assets.add(asset)
            elif line and not line.startswith("    ") and not line.startswith("  #"):
                in_assets = False
    return assets


def parse_dart_license_assets(dart_path: Path) -> set[str]:
    """Extracts assets from powertrainBatteryLicenseAssets in Dart source."""
    if not dart_path.is_file():
        return set()
    content = dart_path.read_text(encoding="utf-8")
    match = re.search(
        r"const\s+powertrainBatteryLicenseAssets\s*=\s*<String>\[(.*?)\];",
        content,
        re.DOTALL,
    )
    if not match:
        return set()
    return set(re.findall(r"['\"]([^'\"]+)['\"]", match.group(1)))


def _check_no_absolute_paths(
    artifact_id: str,
    record: dict[str, Any],
    errors: list[ValidationError],
) -> None:
    """Verifies that no host-specific or absolute paths exist in the inventory."""
    def _scan(val: Any, field_name: str) -> None:
        if isinstance(val, str):
            if val.startswith("/") or (len(val) > 2 and val[1] == ":" and val[2] in ("\\", "/")):
                errors.append(
                    ValidationError(
                        artifact_id,
                        "ABSOLUTE_PATH_FORBIDDEN",
                        f"Field '{field_name}' contains absolute path '{val}'; must be relative to repository root",
                    )
                )
        elif isinstance(val, list):
            for i, item in enumerate(val):
                _scan(item, f"{field_name}[{i}]")
        elif isinstance(val, dict):
            for k, item in val.items():
                _scan(item, f"{field_name}.{k}")

    _scan(record.get("source_of_truth_paths"), "source_of_truth_paths")
    _scan(record.get("required_package_assets"), "required_package_assets")
    _scan(record.get("runtime_licence_registry_assets"), "runtime_licence_registry_assets")


def validate_provenance_data(
    data: dict[str, Any],
    repo_root: Path,
    scope: str = "production-package",
) -> list[ValidationError]:
    """Validates inventory dictionary against rules and repository tree."""
    errors: list[ValidationError] = []

    # 1. Top-level schema version
    schema_ver = data.get("schema_version")
    if schema_ver not in SUPPORTED_SCHEMA_VERSIONS:
        errors.append(
            ValidationError(
                "<inventory>",
                "SCHEMA_VERSION_INVALID",
                f"Schema version '{schema_ver}' is not supported (supported: {sorted(SUPPORTED_SCHEMA_VERSIONS)})",
            )
        )
        return errors

    artifacts = data.get("artifacts")
    if not isinstance(artifacts, list):
        errors.append(
            ValidationError(
                "<inventory>",
                "ARTIFACTS_NOT_A_LIST",
                "'artifacts' must be a list of artifact definitions",
            )
        )
        return errors

    pubspec_path = repo_root / "pubspec.yaml"
    pubspec_assets = parse_pubspec_assets(pubspec_path)

    dart_license_path = (
        repo_root / "lib/core/licenses/powertrain_battery_licenses.dart"
    )
    dart_license_assets = parse_dart_license_assets(dart_license_path)

    seen_ids: set[str] = set()

    for item in artifacts:
        if not isinstance(item, dict):
            errors.append(
                ValidationError(
                    "<unknown>",
                    "MALFORMED_ARTIFACT_ENTRY",
                    "Artifact entry must be a JSON object",
                )
            )
            continue

        artifact_id = item.get("id")
        if not isinstance(artifact_id, str) or not artifact_id.strip():
            errors.append(
                ValidationError(
                    "<missing_id>",
                    "MISSING_ARTIFACT_ID",
                    "Artifact entry is missing a valid non-empty 'id'",
                )
            )
            continue

        # Wildcard protection
        if WILDCARD_RE.search(artifact_id):
            errors.append(
                ValidationError(
                    artifact_id,
                    "WILDCARD_ARTIFACT_ID",
                    f"Artifact ID '{artifact_id}' contains wildcard characters; exact IDs required",
                )
            )

        if artifact_id in seen_ids:
            errors.append(
                ValidationError(
                    artifact_id,
                    "DUPLICATE_ARTIFACT_ID",
                    f"Duplicate artifact ID '{artifact_id}' in inventory",
                )
            )
        seen_ids.add(artifact_id)

        artifact_scope = item.get("scope")
        if artifact_scope not in ALLOWED_SCOPES:
            errors.append(
                ValidationError(
                    artifact_id,
                    "INVALID_SCOPE",
                    f"Scope '{artifact_scope}' is not in allowed scopes {sorted(ALLOWED_SCOPES)}",
                )
            )

        # Filter by requested scope unless 'all'
        if scope != "all" and artifact_scope != scope:
            continue

        # Finite Slice 1 gate: only declared artifact class permitted
        if artifact_id not in SLICE1_ALLOWED_CLASSES:
            errors.append(
                ValidationError(
                    artifact_id,
                    "UNAUTHORIZED_ARTIFACT_CLASS",
                    f"Artifact class '{artifact_id}' is not permitted in Slice 1 (allowed: {sorted(SLICE1_ALLOWED_CLASSES)})",
                )
            )

        role = item.get("role")
        if role not in ALLOWED_ROLES:
            errors.append(
                ValidationError(
                    artifact_id,
                    "INVALID_ROLE",
                    f"Role '{role}' is not in allowed roles {sorted(ALLOWED_ROLES)}",
                )
            )

        dist_decision = item.get("distribution_decision")
        if dist_decision not in ALLOWED_DISTRIBUTION_DECISIONS:
            errors.append(
                ValidationError(
                    artifact_id,
                    "INVALID_DECISION_ENUM",
                    f"Distribution decision '{dist_decision}' is not in {sorted(ALLOWED_DISTRIBUTION_DECISIONS)}",
                )
            )
        elif artifact_scope == "production-package" and dist_decision != "approved":
            errors.append(
                ValidationError(
                    artifact_id,
                    "DISTRIBUTION_DECISION_INVALID",
                    f"Distribution decision '{dist_decision}' is not approved for production-package scope",
                )
            )

        comm_decision = item.get("commercial_use_decision")
        if comm_decision not in ALLOWED_COMMERCIAL_DECISIONS:
            errors.append(
                ValidationError(
                    artifact_id,
                    "INVALID_COMMERCIAL_ENUM",
                    f"Commercial use decision '{comm_decision}' is not in {sorted(ALLOWED_COMMERCIAL_DECISIONS)}",
                )
            )
        elif artifact_scope == "production-package" and comm_decision != "allowed":
            errors.append(
                ValidationError(
                    artifact_id,
                    "COMMERCIAL_USE_DECISION_INVALID",
                    f"Commercial use decision '{comm_decision}' is not allowed for production-package scope",
                )
            )

        reviewer = item.get("reviewer_status")
        if reviewer not in ALLOWED_REVIEWER_STATUS:
            errors.append(
                ValidationError(
                    artifact_id,
                    "INVALID_REVIEWER_ENUM",
                    f"Reviewer status '{reviewer}' is not in {sorted(ALLOWED_REVIEWER_STATUS)}",
                )
            )
        elif artifact_scope == "production-package" and reviewer != "reviewed":
            errors.append(
                ValidationError(
                    artifact_id,
                    "REVIEWER_STATUS_INVALID",
                    f"Reviewer status '{reviewer}' is not reviewed for production-package scope",
                )
            )

        remediation = item.get("remediation")
        if not remediation or (isinstance(remediation, dict) and not any(remediation.values())):
            errors.append(
                ValidationError(
                    artifact_id,
                    "REMEDIATION_MISSING",
                    "Remediation guidance is required and cannot be empty",
                )
            )

        _check_no_absolute_paths(artifact_id, item, errors)

        # 2. Field validations (licence_location, commercial_use_rationale, owning_issues, licence_identifier)
        lic_loc = item.get("licence_location")
        if not isinstance(lic_loc, str) or not lic_loc.strip():
            errors.append(
                ValidationError(
                    artifact_id,
                    "LICENCE_LOCATION_MISSING",
                    "'licence_location' is required and must be a non-empty string",
                )
            )
        elif not (repo_root / lic_loc).is_file():
            errors.append(
                ValidationError(
                    artifact_id,
                    "LICENCE_LOCATION_MISSING",
                    f"Licence location file '{lic_loc}' missing on disk",
                )
            )

        comm_rationale = item.get("commercial_use_rationale")
        if not isinstance(comm_rationale, str) or not comm_rationale.strip():
            errors.append(
                ValidationError(
                    artifact_id,
                    "COMMERCIAL_RATIONALE_MISSING",
                    "'commercial_use_rationale' is required and cannot be empty",
                )
            )

        owning_issues = item.get("owning_issues")
        if not isinstance(owning_issues, list) or not owning_issues or not all(isinstance(x, int) and x > 0 for x in owning_issues):
            errors.append(
                ValidationError(
                    artifact_id,
                    "OWNING_ISSUES_MISSING",
                    "'owning_issues' must be a non-empty list of positive issue integers",
                )
            )

        lic_id = item.get("licence_identifier")
        if not isinstance(lic_id, str) or not lic_id.strip():
            errors.append(
                ValidationError(
                    artifact_id,
                    "LICENCE_IDENTIFIER_MISSING",
                    "'licence_identifier' is required and cannot be empty",
                )
            )

        # 3. Source-of-truth paths verification
        sot_paths = item.get("source_of_truth_paths")
        if not isinstance(sot_paths, dict) or not sot_paths:
            errors.append(
                ValidationError(
                    artifact_id,
                    "SOURCE_OF_TRUTH_MISSING",
                    "'source_of_truth_paths' must be a non-empty dictionary",
                )
            )
        else:
            for key, path_str in sot_paths.items():
                if not isinstance(path_str, str) or not (repo_root / path_str).is_file():
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "SOURCE_PATH_MISSING",
                            f"Source-of-truth path '{key}': '{path_str}' missing on disk",
                        )
                    )

        # 4. Required package assets verification
        pkg_assets = item.get("required_package_assets")
        if not isinstance(pkg_assets, list) or not pkg_assets:
            errors.append(
                ValidationError(
                    artifact_id,
                    "PACKAGE_ASSETS_SPEC_MISSING",
                    "'required_package_assets' must be a non-empty list",
                )
            )
        else:
            for asset in pkg_assets:
                asset_disk = repo_root / asset
                if not asset_disk.is_file():
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "PACKAGE_ASSET_MISSING",
                            f"Required package asset '{asset}' missing on disk",
                        )
                    )
                if asset not in pubspec_assets:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "PUBSPEC_ASSET_MISSING",
                            f"Required package asset '{asset}' is not declared in pubspec.yaml",
                        )
                    )

        # 5. Runtime licence registry assets
        lic_registry_assets = item.get("runtime_licence_registry_assets")
        if isinstance(lic_registry_assets, list):
            for lic_asset in lic_registry_assets:
                if lic_asset not in dart_license_assets:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "LICENCE_REGISTRY_ASSET_MISSING",
                            f"Licence asset '{lic_asset}' is not registered in powertrain_battery_licenses.dart",
                        )
                    )

        # 6. Catalog manifest cross-check
        catalog_manifest = item.get("catalog_manifest")
        if isinstance(catalog_manifest, dict):
            manifest_file = catalog_manifest.get("manifest_file")
            target_file = catalog_manifest.get("target_file")
            expected_sha256 = catalog_manifest.get("expected_sha256")
            expected_size = catalog_manifest.get("expected_size_bytes")
            expected_schema = catalog_manifest.get("expected_schema_version")

            if not manifest_file or not (repo_root / manifest_file).is_file():
                errors.append(
                    ValidationError(
                        artifact_id,
                        "CATALOG_MANIFEST_MISSING",
                        f"Catalog manifest file '{manifest_file}' missing on disk",
                    )
                )
            if not target_file or not (repo_root / target_file).is_file():
                errors.append(
                    ValidationError(
                        artifact_id,
                        "CATALOG_TARGET_MISSING",
                        f"Catalog target file '{target_file}' missing on disk",
                    )
                )
            elif (repo_root / target_file).is_file() and (repo_root / manifest_file).is_file():
                raw_bytes = (repo_root / target_file).read_bytes()
                computed_sha256 = hashlib.sha256(raw_bytes).hexdigest()
                computed_size = len(raw_bytes)

                if computed_sha256 != expected_sha256:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "CATALOG_SHA256_MISMATCH",
                            f"Catalog SHA-256 mismatch: expected {expected_sha256}, got {computed_sha256}",
                        )
                    )

                if computed_size != expected_size:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "CATALOG_SIZE_MISMATCH",
                            f"Catalog size mismatch: expected {expected_size}, got {computed_size}",
                        )
                    )

                try:
                    manifest_data = json.loads((repo_root / manifest_file).read_text(encoding="utf-8"))
                    if manifest_data.get("sha256") != expected_sha256:
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "CATALOG_MANIFEST_DRIFT",
                                f"Committed manifest SHA-256 '{manifest_data.get('sha256')}' drifts from expected '{expected_sha256}'",
                            )
                        )
                    if manifest_data.get("size_bytes") != expected_size:
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "CATALOG_MANIFEST_DRIFT",
                                f"Committed manifest size '{manifest_data.get('size_bytes')}' drifts from expected '{expected_size}'",
                            )
                        )
                    if expected_schema is not None and manifest_data.get("schema_version") != expected_schema:
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "CATALOG_SCHEMA_VERSION_MISMATCH",
                                f"Catalog manifest schema version mismatch: expected {expected_schema}, got {manifest_data.get('schema_version')}",
                            )
                        )
                except Exception as e:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "CATALOG_MANIFEST_PARSE_ERROR",
                            f"Failed to parse catalog manifest JSON: {e}",
                        )
                    )

        # 7. Owner truth extraction & validation (source_coverage & source_families)
        source_coverage = item.get("source_coverage")
        source_families = item.get("source_families")

        if source_coverage is None and source_families is None:
            errors.append(
                ValidationError(
                    artifact_id,
                    "SOURCE_COVERAGE_MISSING",
                    "Artifact must declare 'source_coverage' or 'source_families'",
                )
            )

        # 7.1 Path consistency and existence check for source_coverage
        if isinstance(source_coverage, dict):
            cov_cat = source_coverage.get("catalog_path")
            cov_man = source_coverage.get("catalog_manifest_path")
            cov_not = source_coverage.get("notices_path")
            cov_mat = source_coverage.get("evidence_matrix_path")

            # Check that all declared paths exist on disk
            for cov_key, cov_path in [
                ("catalog_path", cov_cat),
                ("catalog_manifest_path", cov_man),
                ("notices_path", cov_not),
                ("evidence_matrix_path", cov_mat),
            ]:
                if cov_path is not None:
                    if not isinstance(cov_path, str) or not (repo_root / cov_path).is_file():
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "SOURCE_PATH_MISSING",
                                f"source_coverage path '{cov_key}': '{cov_path}' missing on disk",
                            )
                        )

            # Bidirectional consistency check against source_of_truth_paths
            if isinstance(sot_paths, dict):
                if cov_cat and "catalog" in sot_paths and cov_cat != sot_paths["catalog"]:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "SOURCE_PATH_DRIFT",
                            f"source_coverage.catalog_path '{cov_cat}' drifts from source_of_truth_paths.catalog '{sot_paths['catalog']}'",
                        )
                    )
                if cov_man and "manifest" in sot_paths and cov_man != sot_paths["manifest"]:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "SOURCE_PATH_DRIFT",
                            f"source_coverage.catalog_manifest_path '{cov_man}' drifts from source_of_truth_paths.manifest '{sot_paths['manifest']}'",
                        )
                    )
                if cov_not and "notices" in sot_paths and cov_not != sot_paths["notices"]:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "SOURCE_PATH_DRIFT",
                            f"source_coverage.notices_path '{cov_not}' drifts from source_of_truth_paths.notices '{sot_paths['notices']}'",
                        )
                    )
                if cov_mat and "evidence_matrix" in sot_paths and cov_mat != sot_paths["evidence_matrix"]:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "SOURCE_PATH_DRIFT",
                            f"source_coverage.evidence_matrix_path '{cov_mat}' drifts from source_of_truth_paths.evidence_matrix '{sot_paths['evidence_matrix']}'",
                        )
                    )

            # Consistency against catalog_manifest
            if isinstance(catalog_manifest, dict):
                man_target = catalog_manifest.get("target_file")
                man_file = catalog_manifest.get("manifest_file")
                if cov_cat and man_target and cov_cat != man_target:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "SOURCE_PATH_DRIFT",
                            f"source_coverage.catalog_path '{cov_cat}' drifts from catalog_manifest.target_file '{man_target}'",
                        )
                    )
                if cov_man and man_file and cov_man != man_file:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "SOURCE_PATH_DRIFT",
                            f"source_coverage.catalog_manifest_path '{cov_man}' drifts from catalog_manifest.manifest_file '{man_file}'",
                        )
                    )

            # Consistency against licence_location
            if lic_loc and cov_not and cov_not != lic_loc:
                errors.append(
                    ValidationError(
                        artifact_id,
                        "SOURCE_PATH_DRIFT",
                        f"source_coverage.notices_path '{cov_not}' drifts from licence_location '{lic_loc}'",
                    )
                )

        # Extract owner truth from matrix and notices
        matrix_rel = (
            source_coverage.get("evidence_matrix_path")
            if isinstance(source_coverage, dict) and "evidence_matrix_path" in source_coverage
            else (sot_paths.get("evidence_matrix") if isinstance(sot_paths, dict) else None)
        )
        notices_rel = (
            source_coverage.get("notices_path")
            if isinstance(source_coverage, dict) and "notices_path" in source_coverage
            else (sot_paths.get("notices") if isinstance(sot_paths, dict) else None)
        )

        owner_research: dict[str, dict[str, Any]] = {}
        owner_catalog: dict[str, dict[str, Any]] = {}
        all_owner_licenses: set[str] = set()

        if matrix_rel and (repo_root / matrix_rel).is_file():
            try:
                matrix_data = json.loads((repo_root / matrix_rel).read_text(encoding="utf-8"))
                for r in matrix_data.get("research", []):
                    for sf in r.get("source_families", []):
                        fam = sf.get("family", "").lower()
                        if fam:
                            owner_research[fam] = sf
                            if sf.get("license"):
                                all_owner_licenses.add(sf.get("license"))
                for p in matrix_data.get("catalog", {}).get("profiles", []):
                    for sf in p.get("source_families", []):
                        fam = sf.get("family", "").lower()
                        if fam:
                            if fam not in owner_catalog:
                                owner_catalog[fam] = sf
                            if sf.get("license"):
                                all_owner_licenses.add(sf.get("license"))
            except Exception as e:
                errors.append(
                    ValidationError(
                        artifact_id,
                        "EVIDENCE_MATRIX_PARSE_ERROR",
                        f"Failed to parse evidence matrix: {e}",
                    )
                )

        # 7.2 Read required_owner_fields contract and validate owner sources
        required_owner_fields = ["name", "url", "revision", "license"]
        if isinstance(source_coverage, dict) and "required_owner_fields" in source_coverage:
            cfg_fields = source_coverage.get("required_owner_fields")
            if isinstance(cfg_fields, list) and cfg_fields:
                required_owner_fields = cfg_fields

        # Validate required fields and integrity across BOTH owner_catalog and owner_research
        all_owner_sources: dict[str, dict[str, Any]] = {}
        all_owner_sources.update(owner_catalog)
        all_owner_sources.update(owner_research)

        for fam_key, src in all_owner_sources.items():
            for req_field in required_owner_fields:
                val = src.get(req_field)
                if not val or (isinstance(val, str) and not val.strip()):
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "REQUIRED_OWNER_FIELD_MISSING",
                            f"Owner source family '{fam_key}' is missing required field '{req_field}'",
                        )
                    )
            s_rev = src.get("revision")
            if s_rev and not REVISION_RE.match(s_rev):
                errors.append(
                    ValidationError(
                        artifact_id,
                        "MALFORMED_REVISION",
                        f"Owner source family '{fam_key}' has malformed revision '{s_rev}'",
                    )
                )
            s_sha = src.get("artifact_sha256")
            if s_sha and not SHA256_RE.match(s_sha):
                errors.append(
                    ValidationError(
                        artifact_id,
                        "MALFORMED_SHA256",
                        f"Owner source family '{fam_key}' has malformed artifact_sha256 '{s_sha}'",
                    )
                )

        # 7.3 Extract notices pins and cross-check
        notices_pins: dict[str, dict[str, Any]] = {}
        if notices_rel and (repo_root / notices_rel).is_file():
            notices_text = (repo_root / notices_rel).read_text(encoding="utf-8")
            pin_pattern = re.compile(
                r"-\s*`([^`]+)`(?:\s*\([^)]*\))?,\s*pinned at\s*`([^`]+)`([^\n]*(?:\n(?!\s*[-#])[^\n]*)*)",
                re.MULTILINE,
            )
            for m in pin_pattern.finditer(notices_text):
                repo_name = m.group(1).strip()
                rev = m.group(2).strip()
                snippet = m.group(3).strip()
                notices_pins[repo_name.lower()] = {
                    "name": repo_name,
                    "revision": rev,
                    "snippet": snippet,
                }

        # Cross-check notices pins vs owner truth (research OR catalog) or notices-owned records
        for pin_key, pin_info in notices_pins.items():
            pin_rev = pin_info["revision"]
            pin_name = pin_info["name"]

            # Validate revision format
            if not SHA40_RE.match(pin_rev):
                errors.append(
                    ValidationError(
                        artifact_id,
                        "MALFORMED_REVISION",
                        f"Notices pinned revision '{pin_rev}' for '{pin_name}' is malformed",
                    )
                )
                continue

            matched_owner = owner_research.get(pin_key) or owner_catalog.get(pin_key)
            if matched_owner:
                expected_rev = matched_owner.get("revision")
                if expected_rev and pin_rev != expected_rev:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "REVISION_DRIFT_OR_MISMATCH",
                            f"Notices pinned revision '{pin_rev}' for '{pin_name}' drifts from evidence matrix revision '{expected_rev}'",
                        )
                    )
            elif pin_key in NOTICES_OWNED_PROVENANCE_RECORDS:
                rec = NOTICES_OWNED_PROVENANCE_RECORDS[pin_key]
                expected_rev = rec.get("expected_revision")
                if expected_rev and pin_rev != expected_rev:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "REVISION_DRIFT_OR_MISMATCH",
                            f"Notices pinned revision '{pin_rev}' for '{pin_name}' drifts from expected revision '{expected_rev}'",
                        )
                    )
                req_lics = rec.get("required_licenses", rec.get("allowed_licenses", set()))
                for lic in req_lics:
                    if lic not in PERMITTED_OPEN_SOURCE_LICENSES or (isinstance(lic_id, str) and lic not in lic_id):
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "LICENCE_NOT_PERMITTED",
                                f"Notices-owned record '{pin_name}' licence '{lic}' is not permitted or declared in licence_identifier",
                            )
                        )
                snippet = pin_info.get("snippet", "")
                for lic in sorted(req_lics):
                    if lic not in snippet:
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "LICENCE_MISSING",
                                f"Notices-owned record '{pin_name}' is missing required licence '{lic}' in notices text",
                            )
                        )
            else:
                errors.append(
                    ValidationError(
                        artifact_id,
                        "UNOWNED_SOURCE_DETECTED",
                        f"Notices pin '{pin_name}' has no backing owner entry in evidence matrix or approved notices-owned records",
                    )
                )

        # Cross-check licence_identifier covers all distinct owner licenses
        if isinstance(lic_id, str):
            for lic in sorted(all_owner_licenses):
                if lic not in lic_id:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "LICENCE_IDENTIFIER_DRIFT",
                            f"License '{lic}' present in owner truth is not declared in 'licence_identifier'",
                        )
                    )

        # If source_families is explicitly present, perform strict tuple validation
        if isinstance(source_families, list):
            seen_declared_fams: set[str] = set()
            for sf in source_families:
                sf_name = sf.get("name", "<unnamed>")
                sf_url = sf.get("url")
                if not sf_url:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "SOURCE_URL_MISSING",
                            f"Source family '{sf_name}' is missing required field 'url'",
                        )
                    )
                sf_rev = sf.get("revision")
                if sf_rev is not None:
                    if not isinstance(sf_rev, str) or not SHA40_RE.match(sf_rev):
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "MALFORMED_REVISION",
                                f"Source family '{sf_name}' has malformed revision '{sf_rev}'",
                            )
                        )
                sf_sha = sf.get("artifact_sha256")
                if sf_sha is not None:
                    if not isinstance(sf_sha, str) or not SHA256_RE.match(sf_sha):
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "MALFORMED_SHA256",
                                f"Source family '{sf_name}' has malformed digest '{sf_sha}'",
                            )
                        )
                sf_lic = sf.get("licence")
                if not sf_lic:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "LICENCE_MISSING",
                            f"Source family '{sf_name}' is missing required field 'licence'",
                        )
                    )

                # Match against owner truth
                fam_candidate = sf_name.lower()
                matched_owner = owner_research.get(fam_candidate) or owner_catalog.get(fam_candidate)
                # Also try notices pins
                matched_pin = notices_pins.get(fam_candidate)

                if matched_owner is None and matched_pin is None:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "UNOWNED_SOURCE_DETECTED",
                            f"Source family '{sf_name}' has no backing owner entry in evidence matrix or notices",
                        )
                    )
                else:
                    seen_declared_fams.add(fam_candidate)
                    if matched_owner:
                        owner_rev = matched_owner.get("revision")
                        if owner_rev and sf_rev and sf_rev != owner_rev:
                            errors.append(
                                ValidationError(
                                    artifact_id,
                                    "REVISION_DRIFT_OR_MISMATCH",
                                    f"Declared revision '{sf_rev}' for '{sf_name}' does not match owner revision '{owner_rev}'",
                                )
                            )
                        owner_lic = matched_owner.get("license")
                        if owner_lic and sf_lic and sf_lic != owner_lic:
                            errors.append(
                                ValidationError(
                                    artifact_id,
                                    "LICENCE_MISMATCH",
                                    f"Declared licence '{sf_lic}' for '{sf_name}' does not match owner licence '{owner_lic}'",
                                )
                            )
                        owner_sha = matched_owner.get("artifact_sha256")
                        if owner_sha and sf_sha and sf_sha != owner_sha:
                            errors.append(
                                ValidationError(
                                    artifact_id,
                                    "ARTIFACT_SHA256_MISMATCH",
                                    f"Declared SHA-256 '{sf_sha}' for '{sf_name}' does not match owner SHA-256 '{owner_sha}'",
                                )
                            )
                    elif matched_pin:
                        pin_rev = matched_pin.get("revision")
                        if pin_rev and sf_rev and sf_rev != pin_rev:
                            errors.append(
                                ValidationError(
                                    artifact_id,
                                    "REVISION_DRIFT_OR_MISMATCH",
                                    f"Declared revision '{sf_rev}' for '{sf_name}' does not match notices pinned revision '{pin_rev}'",
                                )
                            )

            # Check if any research owner source was omitted from the explicit list
            if item.get("require_all_research_sources", False):
                for res_fam, res_src in owner_research.items():
                    if res_fam not in seen_declared_fams:
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "OWNER_SOURCE_MISSING",
                                f"Required owner research source '{res_src.get('name')}' is missing from declared source families",
                            )
                        )

    return sorted(errors, key=lambda e: (e.artifact_id, e.error_code, e.message))


def format_report_text(
    data: dict[str, Any],
    errors: list[ValidationError],
    scope: str,
) -> str:
    """Formats deterministic plain text validation report."""
    lines: list[str] = []
    if not errors:
        lines.append(f"[PASS] Provenance inventory validation succeeded for scope: {scope}")
        artifacts = data.get("artifacts", [])
        lines.append(f"Artifact classes validated: {len(artifacts)}")
        for art in artifacts:
            art_id = art.get("id")
            role = art.get("role")
            status = art.get("distribution_decision")
            reviewer = art.get("reviewer_status")
            lines.append(
                f"  • {art_id} (scope: {art.get('scope')}, role: {role}, status: {status}, reviewer: {reviewer})"
            )
            sot = art.get("source_of_truth_paths", {})
            lines.append(f"    - Source truth paths: {len(sot)} verified")
            manifest = art.get("catalog_manifest", {})
            if manifest:
                lines.append(
                    f"    - Catalog manifest: verified (sha256: {manifest.get('expected_sha256')[:8]}..., size: {manifest.get('expected_size_bytes')} bytes)"
                )
            pkg_assets = art.get("required_package_assets", [])
            lines.append(f"    - Package assets: {len(pkg_assets)} verified in pubspec.yaml")
            srcs = art.get("source_families")
            cov = art.get("source_coverage")
            if cov:
                lines.append("    - Source coverage: verified against owner truth (matrix.json + notices)")
            elif srcs:
                lines.append(f"    - Upstream source families: {len(srcs)} verified against owner truth")
    else:
        lines.append(f"[FAIL] Provenance inventory validation failed with {len(errors)} error(s) for scope: {scope}")
        for err in errors:
            lines.append(f"  • [{err.artifact_id}] {err.error_code}: {err.message}")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--scope",
        default="production-package",
        choices=["production-package", "all"],
        help="Release scope to validate (default: production-package)",
    )
    parser.add_argument(
        "--inventory",
        type=Path,
        default=None,
        help="Path to inventory.json (default: docs/provenance/inventory.json)",
    )
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=None,
        help="Path to repository root (default: auto-detected)",
    )
    parser.add_argument(
        "--format",
        default="text",
        choices=["text", "json"],
        help="Report format: text or json (default: text)",
    )
    args = parser.parse_args()

    repo_root = (
        args.repo_root.resolve()
        if args.repo_root
        else Path(__file__).resolve().parents[2]
    )
    inventory_path = (
        args.inventory.resolve()
        if args.inventory
        else repo_root / "docs/provenance/inventory.json"
    )

    if not inventory_path.is_file():
        err = ValidationError("<inventory>", "INVENTORY_NOT_FOUND", f"Inventory file not found: {inventory_path}")
        if args.format == "json":
            print(json.dumps({"status": "fail", "errors": [{"artifact_id": err.artifact_id, "error_code": err.error_code, "message": err.message}]}, indent=2))
        else:
            print(f"[FAIL] {err.error_code}: {err.message}", file=sys.stderr)
        return 1

    try:
        data = json.loads(inventory_path.read_text(encoding="utf-8"))
    except Exception as e:
        err = ValidationError("<inventory>", "INVALID_INVENTORY_JSON", f"Failed to parse inventory JSON: {e}")
        if args.format == "json":
            print(json.dumps({"status": "fail", "errors": [{"artifact_id": err.artifact_id, "error_code": err.error_code, "message": err.message}]}, indent=2))
        else:
            print(f"[FAIL] {err.error_code}: {err.message}", file=sys.stderr)
        return 1

    errors = validate_provenance_data(data, repo_root, scope=args.scope)

    if args.format == "json":
        payload = {
            "status": "pass" if not errors else "fail",
            "scope": args.scope,
            "errors": [
                {"artifact_id": e.artifact_id, "error_code": e.error_code, "message": e.message}
                for e in errors
            ],
        }
        print(json.dumps(payload, indent=2))
    else:
        report = format_report_text(data, errors, args.scope)
        if errors:
            print(report, file=sys.stderr)
        else:
            print(report)

    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
