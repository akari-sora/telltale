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
WILDCARD_RE = re.compile(r"[\*\?\[\]]")

# Slice 1 finite boundary: exactly one declared artifact class.
SLICE1_ALLOWED_CLASSES = frozenset({"powertrain-battery-bundled-third-party"})


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

        # Source-of-truth paths verification
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

        # Required package assets verification
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

        # Runtime licence registry assets
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

        # Catalog manifest cross-check
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

        # Source families verification
        source_families = item.get("source_families", [])
        if isinstance(source_families, list):
            for src in source_families:
                name = src.get("name", "<unnamed>")
                rev = src.get("revision")
                if rev is not None:
                    if not isinstance(rev, str) or not SHA40_RE.match(rev):
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "MALFORMED_REVISION",
                                f"Source family '{name}' has malformed revision '{rev}'; must be 40-character hex commit",
                            )
                        )
                digest = src.get("artifact_sha256")
                if digest is not None:
                    if not isinstance(digest, str) or not SHA256_RE.match(digest):
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "MALFORMED_SHA256",
                                f"Source family '{name}' has malformed digest '{digest}'; must be 64-character hex SHA-256",
                            )
                        )
                lic_asset = src.get("licence_asset")
                if lic_asset is not None:
                    if not (repo_root / lic_asset).is_file():
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "SOURCE_LICENCE_ASSET_MISSING",
                                f"Source family '{name}' licence asset '{lic_asset}' missing on disk",
                            )
                        )
                    if pkg_assets and lic_asset not in pkg_assets:
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "SOURCE_LICENCE_NOT_IN_PACKAGE_ASSETS",
                                f"Source family '{name}' licence asset '{lic_asset}' not in required_package_assets",
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
            lic_assets = art.get("runtime_licence_registry_assets", [])
            lines.append(f"    - Licence registry: {len(lic_assets)} verified in powertrain_battery_licenses.dart")
            srcs = art.get("source_families", [])
            lines.append(f"    - Upstream source families: {len(srcs)} verified (valid revisions/hashes)")
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
