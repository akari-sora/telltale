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
ALLOWED_SCOPES = {"production-package", "test-only", "all"}
ALLOWED_ARTIFACT_SCOPES = {"production-package", "test-only"}
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
ALLOWED_OWNERSHIP = {"third-party", "project-owned"}
ALLOWED_INDEPENDENCE = {
    "independent-third-party-oracle",
    "project-owned-fault-injector",
    "project-owned-reference",
}
ALLOWED_DISTRIBUTION_CHANNELS = {
    "external-fetch-only",
    "source-repository",
    "app-package",
}

SHA40_RE = re.compile(r"^[0-9a-f]{40}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
REVISION_RE = re.compile(r"^(?:[0-9a-f]{40}|[0-9a-f]{64})$")
WILDCARD_RE = re.compile(r"[\*\?\[\]]")

# Scoped allowed classes
SCOPE_ALLOWED_CLASSES = {
    "production-package": frozenset({"powertrain-battery-bundled-third-party"}),
    "test-only": frozenset({
        "ircama-elm327-emulator-test-oracle",
        "telltale-chaos-proxy-test-reference",
        "telltale-freeze-frame-reference",
        "telltale-mode08-replay-reference",
    }),
}
ALL_ALLOWED_CLASSES = (
    SCOPE_ALLOWED_CLASSES["production-package"]
    | SCOPE_ALLOWED_CLASSES["test-only"]
)
REQUIRED_SCOPE_CLASSES = SCOPE_ALLOWED_CLASSES
# Backwards compatibility alias for Slice 1 tests
SLICE1_ALLOWED_CLASSES = SCOPE_ALLOWED_CLASSES["production-package"]

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


def _matches_licence_token(licence: str, text: str) -> bool:
    """Checks if a licence identifier appears as an exact token (with word/punctuation boundaries)."""
    pattern = rf"(?<![A-Za-z0-9_.-]){re.escape(licence)}(?![A-Za-z0-9_.-])"
    return bool(re.search(pattern, text))


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



def _parse_lockfile_package_entry(
    lock_text: str, package_name: str
) -> tuple[str | None, str | None, list[str]]:
    """Parses lockfile for a package entry.
    Returns (op, version, list_of_hashes).
    If package not found, returns (None, None, []).
    """
    lines = lock_text.splitlines()
    joined_entries: list[str] = []
    current = ""
    for line in lines:
        line_str = line.strip()
        if not line_str or line_str.startswith("#"):
            continue
        if current:
            current += " " + line_str
        else:
            current = line_str
        if current.endswith("\\"):
            current = current[:-1].strip()
        else:
            joined_entries.append(current)
            current = ""
    if current:
        joined_entries.append(current)

    pattern = re.compile(rf"^{re.escape(package_name)}([><=~!*]+)([^\s\\]+)", re.IGNORECASE)
    for entry in joined_entries:
        m = pattern.match(entry)
        if m:
            op = m.group(1)
            ver = m.group(2)
            hashes = re.findall(r"--hash=(?:sha256:)?([0-9a-fA-F]{64})", entry)
            return op, ver, hashes
    return None, None, []


def _check_test_only_package_isolation(
    artifact_id: str,
    record: dict[str, Any],
    pubspec_assets: set[str],
    dart_license_assets: set[str],
    errors: list[ValidationError],
) -> None:
    """Verifies that no test-only files or assets leak into pubspec.yaml or runtime licence registry."""
    def _scan(val: Any) -> None:
        if isinstance(val, str):
            clean_val = val.strip()
            if clean_val:
                if clean_val in pubspec_assets:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "TEST_ONLY_ASSET_IN_PUBSPEC",
                            f"Test-only asset '{clean_val}' is forbidden from pubspec.yaml assets",
                        )
                    )
                if clean_val in dart_license_assets:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "TEST_ONLY_ASSET_IN_REGISTRY",
                            f"Test-only asset '{clean_val}' is forbidden from runtime licence registry",
                        )
                    )
        elif isinstance(val, list):
            for item in val:
                _scan(item)
        elif isinstance(val, dict):
            for item in val.values():
                _scan(item)

    _scan(record.get("source"))
    _scan(record.get("project_source"))
    _scan(record.get("licence_evidence"))
    _scan(record.get("execution_bindings"))


def _validate_ircama_oracle(
    artifact_id: str,
    item: dict[str, Any],
    repo_root: Path,
    errors: list[ValidationError],
) -> None:
    """Validates third-party Ircama oracle package hashes, lockfiles, and licence evidence."""
    source = item.get("source")
    if not isinstance(source, dict):
        errors.append(ValidationError(artifact_id, "SOURCE_SPEC_MISSING", "'source' object is required for Ircama"))
        return

    kind = source.get("kind")
    if kind != "python-package":
        errors.append(ValidationError(artifact_id, "SOURCE_KIND_INVALID", f"Source kind must be 'python-package', got '{kind}'"))

    pkg_name = source.get("package_name")
    if pkg_name != "ELM327-emulator":
        errors.append(ValidationError(artifact_id, "PACKAGE_NAME_MISMATCH", f"package_name must be 'ELM327-emulator', got '{pkg_name}'"))

    ver = source.get("version")
    if not isinstance(ver, str) or not ver.strip():
        errors.append(ValidationError(artifact_id, "VERSION_MISSING", "version is required and must be non-empty"))

    sha = source.get("artifact_sha256")
    if not isinstance(sha, str) or not SHA256_RE.match(sha):
        errors.append(ValidationError(artifact_id, "SHA256_INVALID", f"artifact_sha256 '{sha}' must be a 64-char hex string"))

    lockfiles = source.get("lockfiles")
    if not isinstance(lockfiles, list) or not lockfiles:
        errors.append(ValidationError(artifact_id, "LOCKFILES_SPEC_MISSING", "'lockfiles' must be a non-empty list of file paths"))
    else:
        for lock_rel in lockfiles:
            if not isinstance(lock_rel, str) or not lock_rel.strip():
                errors.append(ValidationError(artifact_id, "LOCKFILE_PATH_INVALID", f"Invalid lockfile path '{lock_rel}'"))
                continue
            lock_path = repo_root / lock_rel
            if not lock_path.is_file():
                errors.append(ValidationError(artifact_id, "LOCKFILE_MISSING", f"Lockfile '{lock_rel}' missing on disk"))
                continue

            lock_text = lock_path.read_text(encoding="utf-8", errors="replace")
            op, lock_ver, lock_hashes = _parse_lockfile_package_entry(lock_text, pkg_name or "ELM327-emulator")
            if op is None:
                errors.append(ValidationError(artifact_id, "LOCKFILE_PACKAGE_MISSING", f"Lockfile '{lock_rel}' does not contain package '{pkg_name}'"))
            else:
                if op != "==":
                    errors.append(ValidationError(artifact_id, "LOCKFILE_FLOATING_SPEC", f"Lockfile '{lock_rel}' uses floating/range spec '{op}' for {pkg_name}; exact '==' pin required"))
                if ver and lock_ver != ver:
                    errors.append(ValidationError(artifact_id, "LOCKFILE_VERSION_DRIFT", f"Lockfile '{lock_rel}' specifies version '{lock_ver}', expected '{ver}'"))
                if not lock_hashes:
                    errors.append(ValidationError(artifact_id, "LOCKFILE_HASH_MISSING", f"Lockfile '{lock_rel}' missing hash for {pkg_name}"))
                elif sha and not any(h.lower() == sha.lower() for h in lock_hashes):
                    errors.append(ValidationError(artifact_id, "LOCKFILE_HASH_DRIFT", f"Lockfile '{lock_rel}' hash '{lock_hashes[0]}' does not match expected '{sha}'"))

    # Licence evidence validation
    lic_ev = item.get("licence_evidence")
    if not isinstance(lic_ev, dict):
        errors.append(ValidationError(artifact_id, "LICENCE_EVIDENCE_SPEC_MISSING", "'licence_evidence' object is required"))
    else:
        ident = lic_ev.get("identifier")
        if not isinstance(ident, str) or not ident.strip():
            errors.append(ValidationError(artifact_id, "LICENCE_IDENTIFIER_MISSING", "'licence_evidence.identifier' is required"))

        loc_path_str = lic_ev.get("local_evidence_path")
        if not isinstance(loc_path_str, str) or not loc_path_str.strip():
            errors.append(ValidationError(artifact_id, "LICENCE_EVIDENCE_PATH_MISSING", "'licence_evidence.local_evidence_path' is required"))
        else:
            evidence_file = repo_root / loc_path_str
            if not evidence_file.is_file():
                errors.append(ValidationError(artifact_id, "LICENCE_EVIDENCE_MISSING", f"Licence evidence file '{loc_path_str}' missing on disk"))
            else:
                ev_bytes = evidence_file.read_bytes()
                actual_sha = hashlib.sha256(ev_bytes).hexdigest()
                expected_sha = lic_ev.get("source_sha256")
                if not isinstance(expected_sha, str) or not SHA256_RE.match(expected_sha):
                    errors.append(ValidationError(artifact_id, "SHA256_INVALID", f"source_sha256 '{expected_sha}' must be a 64-char hex string"))
                elif actual_sha.lower() != expected_sha.lower():
                    errors.append(ValidationError(artifact_id, "LICENCE_EVIDENCE_HASH_DRIFT", f"Licence evidence file '{loc_path_str}' hash drift: got {actual_sha}, expected {expected_sha}"))

                ev_text = ev_bytes.decode("utf-8", errors="replace")
                if ident and not (_matches_licence_token(ident, ev_text) or "Attribution-NonCommercial-ShareAlike 4.0" in ev_text):
                    errors.append(ValidationError(artifact_id, "LICENCE_EVIDENCE_CONTENT_MISMATCH", f"Licence evidence file '{loc_path_str}' does not contain expected licence identifier '{ident}'"))

    # Execution bindings validation
    exec_bind = item.get("execution_bindings")
    if not isinstance(exec_bind, dict):
        errors.append(ValidationError(artifact_id, "EXECUTION_BINDINGS_MISSING", "'execution_bindings' object is required"))
    else:
        runner_script = exec_bind.get("runner_script")
        if not isinstance(runner_script, str) or not runner_script.strip():
            errors.append(ValidationError(artifact_id, "EXECUTION_RUNNER_MISSING", "'runner_script' is required"))
        else:
            runner_file = repo_root / runner_script
            if not runner_file.is_file():
                errors.append(ValidationError(artifact_id, "EXECUTION_RUNNER_MISSING", f"Execution runner '{runner_script}' missing on disk"))
            else:
                runner_text = runner_file.read_text(encoding="utf-8", errors="replace")
                expected_version = item.get("source", {}).get("version", "3.0.5")
                declared_locks = item.get("source", {}).get("lockfiles", [])

                # Join shell line continuations
                cmd_lines: list[str] = []
                current_line = ""
                for raw_line in runner_text.splitlines():
                    stripped = raw_line.strip()
                    if stripped.startswith("#"):
                        continue
                    if current_line:
                        current_line += " " + stripped
                    else:
                        current_line = stripped
                    if current_line.endswith("\\"):
                        current_line = current_line[:-1].rstrip()
                    else:
                        cmd_lines.append(current_line)
                        current_line = ""
                if current_line:
                    cmd_lines.append(current_line)

                allowed_reqs = set(declared_locks) | {
                    ".github/requirements/elm327-build.lock",
                    "tool/ble_test_rig/requirements.bootstrap",
                }

                for cmd in cmd_lines:
                    if ("pip" in cmd and "install" in cmd) or re.search(r'(?:^|[/\s])pip(?:\d+)?(?:\.exe)?["\']?\s+install\b', cmd):
                        if "--require-hashes" not in cmd:
                            errors.append(
                                ValidationError(
                                    artifact_id,
                                    "RUNNER_UNHASHED_INSTALL_PROHIBITED",
                                    f"Runner '{runner_script}' contains unhashed pip install: '{cmd}'",
                                )
                            )
                        # Check referenced requirements files (-r or --requirement)
                        req_matches = re.findall(r'(?:-r|--requirement)\s+["\']?([^"\';\s]+)["\']?', cmd)
                        for req_match in req_matches:
                            norm_req = req_match.replace("$ROOT/", "").replace("${ROOT}/", "")
                            if norm_req.startswith("./"):
                                norm_req = norm_req[2:]
                            if norm_req not in allowed_reqs:
                                errors.append(
                                    ValidationError(
                                        artifact_id,
                                        "RUNNER_UNDECLARED_REQUIREMENTS",
                                        f"Runner '{runner_script}' references undeclared requirements file '{norm_req}' (allowed: {sorted(allowed_reqs)})",
                                    )
                                )

                # Runner must reference all declared lockfiles
                for lock in declared_locks:
                    if lock not in runner_text:
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "RUNNER_LOCKFILE_MISSING",
                                f"Runner '{runner_script}' does not reference declared lockfile '{lock}'",
                            )
                        )

                # Installed package version preflight check
                has_version_check = (
                    "ELM327-emulator" in runner_text
                    and ("importlib.metadata" in runner_text or "m.version" in runner_text or "version(" in runner_text)
                )
                if not has_version_check:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "RUNNER_VERSION_PREFLIGHT_MISSING",
                            f"Runner '{runner_script}' is missing installed ELM327-emulator version preflight",
                        )
                    )
                else:
                    version_cmp_match = re.search(
                        r'INSTALLED_ELM_VER["\']?\s*(!=|==|=)\s*["\']?([0-9A-Za-z_.\-]+)["\']?',
                        runner_text,
                    )
                    if not version_cmp_match:
                        version_cmp_match = re.search(
                            r'["\']?([0-9A-Za-z_.\-]+)["\']?\s*(!=|==|=)\s*["\']?\$?INSTALLED_ELM_VER',
                            runner_text,
                        )
                    if not version_cmp_match:
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "RUNNER_VERSION_PREFLIGHT_MISSING",
                                f"Runner '{runner_script}' does not check INSTALLED_ELM_VER against exact version",
                            )
                        )
                    else:
                        preflight_ver = version_cmp_match.group(2) if version_cmp_match.lastindex == 2 else version_cmp_match.group(1)
                        if preflight_ver != expected_version:
                            errors.append(
                                ValidationError(
                                    artifact_id,
                                    "RUNNER_PREFLIGHT_VERSION_MISMATCH",
                                    f"Runner preflight checks version '{preflight_ver}', but inventory requires '{expected_version}'",
                                )
                            )

        test_paths = exec_bind.get("test_paths")
        if not isinstance(test_paths, list) or not test_paths:
            errors.append(ValidationError(artifact_id, "EXECUTION_TEST_PATHS_MISSING", "'test_paths' must be a non-empty list of test files"))
        else:
            for tp in test_paths:
                if not isinstance(tp, str) or not (repo_root / tp).is_file():
                    errors.append(ValidationError(artifact_id, "EXECUTION_TEST_PATH_MISSING", f"Test path '{tp}' missing on disk"))

        req_flags = exec_bind.get("required_flags")
        if not isinstance(req_flags, list) or "ELM_ORACLE_REQUIRED=true" not in req_flags:
            errors.append(ValidationError(artifact_id, "EXECUTION_BINDING_FLAG_MISSING", "'required_flags' must include 'ELM_ORACLE_REQUIRED=true'"))


def _validate_project_reference(
    artifact_id: str,
    item: dict[str, Any],
    repo_root: Path,
    errors: list[ValidationError],
) -> None:
    """Validates project-owned reference or fault-injector hashes and identity banners."""
    proj_source = item.get("project_source")
    if not isinstance(proj_source, dict):
        errors.append(ValidationError(artifact_id, "PROJECT_SOURCE_SPEC_MISSING", "'project_source' object is required"))
        return

    lic_loc = proj_source.get("licence_location")
    if not isinstance(lic_loc, str) or not (repo_root / lic_loc).is_file():
        errors.append(ValidationError(artifact_id, "LICENCE_LOCATION_MISSING", f"Project reference licence_location '{lic_loc}' missing on disk"))

    integrity_files = proj_source.get("integrity_files")
    if not isinstance(integrity_files, list) or not integrity_files:
        errors.append(ValidationError(artifact_id, "INTEGRITY_FILES_SPEC_MISSING", "'integrity_files' must be a non-empty list"))
    else:
        declared_paths: set[str] = set()
        for entry in integrity_files:
            if not isinstance(entry, dict):
                errors.append(ValidationError(artifact_id, "INTEGRITY_ENTRY_INVALID", "Integrity file entry must be an object"))
                continue
            path_str = entry.get("path")
            expected_sha = entry.get("sha256")
            if not isinstance(path_str, str) or not path_str.strip():
                errors.append(ValidationError(artifact_id, "INTEGRITY_PATH_INVALID", "Integrity file path must be non-empty string"))
                continue
            declared_paths.add(path_str)
            file_disk = repo_root / path_str
            if not file_disk.is_file():
                errors.append(ValidationError(artifact_id, "INTEGRITY_FILE_MISSING", f"Integrity file '{path_str}' missing on disk"))
                continue
            if not isinstance(expected_sha, str) or not SHA256_RE.match(expected_sha):
                errors.append(ValidationError(artifact_id, "SHA256_INVALID", f"Integrity sha256 '{expected_sha}' must be 64-char hex string"))
                continue
            actual_sha = hashlib.sha256(file_disk.read_bytes()).hexdigest()
            if actual_sha.lower() != expected_sha.lower():
                errors.append(ValidationError(artifact_id, "INTEGRITY_HASH_MISMATCH", f"Integrity file '{path_str}' SHA-256 drift: got {actual_sha}, expected {expected_sha}"))

        if artifact_id == "telltale-mode08-replay-reference":
            required_m08 = {
                "tool/obd_test_rig/mode08_replay_reference.py",
                "tool/obd_test_rig/mode08_replay_fixtures.json",
            }
            if not required_m08.issubset(declared_paths):
                errors.append(ValidationError(artifact_id, "INTEGRITY_FILES_INCOMPLETE", f"Mode08 reference integrity_files must contain both {sorted(required_m08)}"))

    # Identity banner validation
    if artifact_id == "telltale-freeze-frame-reference":
        expected_banner = "Telltale Freeze-Frame Reference"
        declared_banner = proj_source.get("identity_banner")
        if declared_banner != expected_banner:
            errors.append(ValidationError(artifact_id, "IDENTITY_BANNER_MISMATCH", f"Freeze-frame identity banner must be '{expected_banner}', got '{declared_banner}'"))
        ff_file = repo_root / "tool/obd_test_rig/freeze_frame_reference.py"
        if ff_file.is_file():
            ff_text = ff_file.read_text(encoding="utf-8", errors="replace")
            if f'IDENTITY = "{expected_banner}"' not in ff_text:
                errors.append(ValidationError(artifact_id, "IDENTITY_BANNER_MISMATCH", f"Freeze-frame reference script must define IDENTITY = '{expected_banner}'"))
    elif artifact_id == "telltale-mode08-replay-reference":
        expected_banner = "Telltale Mode 08 Replay Reference"
        declared_banner = proj_source.get("identity_banner")
        if declared_banner != expected_banner:
            errors.append(ValidationError(artifact_id, "IDENTITY_BANNER_MISMATCH", f"Mode08 identity banner must be '{expected_banner}', got '{declared_banner}'"))
        m08_file = repo_root / "tool/obd_test_rig/mode08_replay_reference.py"
        if m08_file.is_file():
            m08_text = m08_file.read_text(encoding="utf-8", errors="replace")
            if f'IDENTITY = "{expected_banner}"' not in m08_text:
                errors.append(ValidationError(artifact_id, "IDENTITY_BANNER_MISMATCH", f"Mode08 reference script must define IDENTITY = '{expected_banner}'"))

    # Execution bindings validation
    exec_bind = item.get("execution_bindings")
    if not isinstance(exec_bind, dict):
        errors.append(ValidationError(artifact_id, "EXECUTION_BINDINGS_MISSING", "'execution_bindings' object is required"))
    else:
        runner_script = exec_bind.get("runner_script")
        if not isinstance(runner_script, str) or not (repo_root / runner_script).is_file():
            errors.append(ValidationError(artifact_id, "EXECUTION_RUNNER_MISSING", f"Execution runner '{runner_script}' missing on disk"))

        test_paths = exec_bind.get("test_paths")
        if not isinstance(test_paths, list) or not test_paths:
            errors.append(ValidationError(artifact_id, "EXECUTION_TEST_PATHS_MISSING", "'test_paths' must be a non-empty list of test files"))
        else:
            for tp in test_paths:
                if not isinstance(tp, str) or not (repo_root / tp).is_file():
                    errors.append(ValidationError(artifact_id, "EXECUTION_TEST_PATH_MISSING", f"Test path '{tp}' missing on disk"))

        if artifact_id == "telltale-mode08-replay-reference":
            req_flags = exec_bind.get("required_flags")
            if not isinstance(req_flags, list) or "MODE08_ORACLE_REQUIRED=true" not in req_flags:
                errors.append(ValidationError(artifact_id, "EXECUTION_BINDING_FLAG_MISSING", "'required_flags' must include 'MODE08_ORACLE_REQUIRED=true'"))


def _validate_test_only_artifact(
    artifact_id: str,
    item: dict[str, Any],
    repo_root: Path,
    pubspec_assets: set[str],
    dart_license_assets: set[str],
    errors: list[ValidationError],
) -> None:
    """Validates a test-only oracle or reference artifact record (Slice 2)."""
    # 1. Role validation & escalation check
    role = item.get("role")
    if role in ("runtime", "bundled"):
        errors.append(
            ValidationError(
                artifact_id,
                "TEST_ONLY_ROLE_ESCALATION",
                f"Test-only artifact '{artifact_id}' cannot have role '{role}'",
            )
        )
    elif role != "test-only":
        errors.append(
            ValidationError(
                artifact_id,
                "INVALID_ROLE",
                f"Role '{role}' is not in allowed roles {sorted(ALLOWED_ROLES)}",
            )
        )

    # 2. Package policy
    pkg_policy = item.get("package_policy")
    if not isinstance(pkg_policy, dict) or pkg_policy.get("app_package") != "forbidden":
        errors.append(
            ValidationError(
                artifact_id,
                "PACKAGE_POLICY_INVALID",
                "package_policy.app_package must be 'forbidden' for test-only artifacts",
            )
        )

    # 3. Distribution channel
    dist_channel = item.get("distribution_channel")
    if dist_channel not in ALLOWED_DISTRIBUTION_CHANNELS:
        errors.append(
            ValidationError(
                artifact_id,
                "INVALID_DISTRIBUTION_CHANNEL_ENUM",
                f"Distribution channel '{dist_channel}' is not in {sorted(ALLOWED_DISTRIBUTION_CHANNELS)}",
            )
        )
    elif dist_channel == "app-package":
        errors.append(
            ValidationError(
                artifact_id,
                "DISTRIBUTION_CHANNEL_INVALID",
                f"Test-only artifact '{artifact_id}' cannot have distribution_channel 'app-package'",
            )
        )

    # 4. Ownership & Independence
    ownership = item.get("ownership")
    if ownership not in ALLOWED_OWNERSHIP:
        errors.append(
            ValidationError(
                artifact_id,
                "INVALID_OWNERSHIP_ENUM",
                f"Ownership '{ownership}' is not in {sorted(ALLOWED_OWNERSHIP)}",
            )
        )

    independence = item.get("independence")
    if independence not in ALLOWED_INDEPENDENCE:
        errors.append(
            ValidationError(
                artifact_id,
                "INVALID_INDEPENDENCE_ENUM",
                f"Independence '{independence}' is not in {sorted(ALLOWED_INDEPENDENCE)}",
            )
        )

    # Cross-check ownership & independence
    if ownership == "project-owned" and independence == "independent-third-party-oracle":
        errors.append(
            ValidationError(
                artifact_id,
                "INDEPENDENCE_LAUNDERING",
                f"Project-owned artifact '{artifact_id}' cannot be classified as independent-third-party-oracle",
            )
        )

    if artifact_id == "ircama-elm327-emulator-test-oracle":
        if ownership != "third-party":
            errors.append(
                ValidationError(
                    artifact_id,
                    "OWNERSHIP_MISCLASSIFICATION",
                    f"Ircama test oracle must have ownership 'third-party', got '{ownership}'",
                )
            )
        if independence != "independent-third-party-oracle":
            errors.append(
                ValidationError(
                    artifact_id,
                    "INDEPENDENCE_MISCLASSIFICATION",
                    f"Ircama test oracle must have independence 'independent-third-party-oracle', got '{independence}'",
                )
            )
        if dist_channel != "external-fetch-only":
            errors.append(
                ValidationError(
                    artifact_id,
                    "DISTRIBUTION_CHANNEL_INVALID",
                    f"Ircama must have distribution_channel 'external-fetch-only', got '{dist_channel}'",
                )
            )
    elif artifact_id in (
        "telltale-chaos-proxy-test-reference",
        "telltale-freeze-frame-reference",
        "telltale-mode08-replay-reference",
    ):
        if ownership != "project-owned":
            errors.append(
                ValidationError(
                    artifact_id,
                    "OWNERSHIP_MISCLASSIFICATION",
                    f"Project reference '{artifact_id}' must have ownership 'project-owned', got '{ownership}'",
                )
            )
        if artifact_id == "telltale-chaos-proxy-test-reference":
            if independence != "project-owned-fault-injector":
                errors.append(
                    ValidationError(
                        artifact_id,
                        "INDEPENDENCE_MISCLASSIFICATION",
                        f"Chaos proxy must have independence 'project-owned-fault-injector', got '{independence}'",
                    )
                )
        elif independence != "project-owned-reference":
            errors.append(
                ValidationError(
                    artifact_id,
                    "INDEPENDENCE_MISCLASSIFICATION",
                    f"Reference '{artifact_id}' must have independence 'project-owned-reference', got '{independence}'",
                )
            )
        if dist_channel != "source-repository":
            errors.append(
                ValidationError(
                    artifact_id,
                    "DISTRIBUTION_CHANNEL_INVALID",
                    f"Project reference must have distribution_channel 'source-repository', got '{dist_channel}'",
                )
            )

    # 5. Decisions & Reviewer status
    dist_decision = item.get("distribution_decision")
    if dist_decision not in ALLOWED_DISTRIBUTION_DECISIONS:
        errors.append(
            ValidationError(
                artifact_id,
                "INVALID_DECISION_ENUM",
                f"Distribution decision '{dist_decision}' is not in {sorted(ALLOWED_DISTRIBUTION_DECISIONS)}",
            )
        )
    elif dist_decision == "unknown":
        errors.append(
            ValidationError(
                artifact_id,
                "DECISION_UNRESOLVED",
                f"Distribution decision for '{artifact_id}' is unresolved ('unknown')",
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
    elif comm_decision == "unknown":
        errors.append(
            ValidationError(
                artifact_id,
                "DECISION_UNRESOLVED",
                f"Commercial use decision for '{artifact_id}' is unresolved ('unknown')",
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

    reviewer = item.get("reviewer_status")
    if reviewer not in ALLOWED_REVIEWER_STATUS:
        errors.append(
            ValidationError(
                artifact_id,
                "INVALID_REVIEWER_ENUM",
                f"Reviewer status '{reviewer}' is not in {sorted(ALLOWED_REVIEWER_STATUS)}",
            )
        )
    elif reviewer != "reviewed":
        errors.append(
            ValidationError(
                artifact_id,
                "REVIEWER_STATUS_INVALID",
                f"Reviewer status '{reviewer}' is not reviewed for test-only artifact",
            )
        )

    owning_issues = item.get("owning_issues")
    if (
        not isinstance(owning_issues, list)
        or not owning_issues
        or not all(type(x) is int and not isinstance(x, bool) and x > 0 for x in owning_issues)
    ):
        errors.append(
            ValidationError(
                artifact_id,
                "OWNING_ISSUES_MISSING",
                "'owning_issues' must be a non-empty list of positive issue integers",
            )
        )

    remediation = item.get("remediation")
    if not isinstance(remediation, dict):
        errors.append(
            ValidationError(
                artifact_id,
                "REMEDIATION_MISSING",
                "Remediation guidance is required and must be an object",
            )
        )
    else:
        for rem_key in ("on_rights_revocation", "on_integrity_failure"):
            val = remediation.get(rem_key)
            if not isinstance(val, str) or not val.strip():
                errors.append(
                    ValidationError(
                        artifact_id,
                        "REMEDIATION_MISSING",
                        f"Remediation guidance requires non-empty '{rem_key}' string",
                    )
                )

    # 6. Absolute path protection & Package isolation
    _check_no_absolute_paths(artifact_id, item, errors)
    _check_test_only_package_isolation(artifact_id, item, pubspec_assets, dart_license_assets, errors)

    # 7. Class-specific source & integrity validation
    if artifact_id == "ircama-elm327-emulator-test-oracle":
        _validate_ircama_oracle(artifact_id, item, repo_root, errors)
    elif artifact_id in (
        "telltale-chaos-proxy-test-reference",
        "telltale-freeze-frame-reference",
        "telltale-mode08-replay-reference",
    ):
        _validate_project_reference(artifact_id, item, repo_root, errors)


def validate_provenance_data(
    data: dict[str, Any],
    repo_root: Path,
    scope: str = "production-package",
) -> list[ValidationError]:
    """Validates inventory dictionary against rules and repository tree."""
    errors: list[ValidationError] = []

    if scope not in ALLOWED_SCOPES:
        errors.append(
            ValidationError(
                "<inventory>",
                "INVALID_SCOPE",
                f"Requested scope '{scope}' is not in allowed scopes {sorted(ALLOWED_SCOPES)}",
            )
        )
        return errors

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
    seen_production_classes: set[str] = set()
    seen_test_only_classes: set[str] = set()

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
        if artifact_scope not in ALLOWED_ARTIFACT_SCOPES:
            errors.append(
                ValidationError(
                    artifact_id,
                    "INVALID_SCOPE",
                    f"Scope '{artifact_scope}' is not in allowed scopes {sorted(ALLOWED_ARTIFACT_SCOPES)}",
                )
            )
        else:
            if artifact_scope == "production-package":
                seen_production_classes.add(artifact_id)
            elif artifact_scope == "test-only":
                seen_test_only_classes.add(artifact_id)

        # Filter by requested scope unless 'all'
        if scope != "all" and artifact_scope != scope:
            continue

        # Wildcard protection (scoped)
        if WILDCARD_RE.search(artifact_id):
            errors.append(
                ValidationError(
                    artifact_id,
                    "WILDCARD_ARTIFACT_ID",
                    f"Artifact ID '{artifact_id}' contains wildcard characters; exact IDs required",
                )
            )

        artifact_class = item.get("artifact_class")
        if not isinstance(artifact_class, str) or not artifact_class.strip():
            errors.append(
                ValidationError(
                    artifact_id,
                    "MISSING_ARTIFACT_CLASS",
                    "Artifact entry is missing a valid non-empty 'artifact_class'",
                )
            )
        elif artifact_class != artifact_id:
            errors.append(
                ValidationError(
                    artifact_id,
                    "ARTIFACT_CLASS_MISMATCH",
                    f"Artifact class '{artifact_class}' does not match artifact id '{artifact_id}'",
                )
            )

        if artifact_id not in ALL_ALLOWED_CLASSES:
            errors.append(
                ValidationError(
                    artifact_id,
                    "UNAUTHORIZED_ARTIFACT_CLASS",
                    f"Artifact class '{artifact_id}' is not in allowed classes {sorted(ALL_ALLOWED_CLASSES)}",
                )
            )

        if (
            artifact_scope in SCOPE_ALLOWED_CLASSES
            and artifact_id not in SCOPE_ALLOWED_CLASSES[artifact_scope]
        ):
            errors.append(
                ValidationError(
                    artifact_id,
                    "UNAUTHORIZED_ARTIFACT_CLASS",
                    f"Artifact class '{artifact_id}' is not permitted for scope '{artifact_scope}' (allowed: {sorted(SCOPE_ALLOWED_CLASSES[artifact_scope])})",
                )
            )

        if artifact_scope == "test-only":
            _validate_test_only_artifact(
                artifact_id, item, repo_root, pubspec_assets, dart_license_assets, errors
            )
            continue

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
        if not isinstance(remediation, dict):
            errors.append(
                ValidationError(
                    artifact_id,
                    "REMEDIATION_MISSING",
                    "Remediation guidance is required and must be an object",
                )
            )
        else:
            for rem_key in ("on_rights_revocation", "on_integrity_failure"):
                val = remediation.get(rem_key)
                if not isinstance(val, str) or not val.strip():
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "REMEDIATION_MISSING",
                            f"Remediation guidance requires non-empty '{rem_key}' string",
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
        if (
            not isinstance(owning_issues, list)
            or not owning_issues
            or not all(type(x) is int and not isinstance(x, bool) and x > 0 for x in owning_issues)
        ):
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
        if not isinstance(lic_registry_assets, list) or not lic_registry_assets:
            errors.append(
                ValidationError(
                    artifact_id,
                    "LICENCE_REGISTRY_ASSETS_MISSING",
                    "'runtime_licence_registry_assets' must be a non-empty list",
                )
            )
        else:
            declared_lic_set = set(lic_registry_assets)
            for lic_asset in lic_registry_assets:
                if not isinstance(lic_asset, str) or lic_asset not in dart_license_assets:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "LICENCE_REGISTRY_ASSET_MISSING",
                            f"Licence asset '{lic_asset}' is not registered in powertrain_battery_licenses.dart",
                        )
                    )
            for dart_asset in sorted(dart_license_assets):
                if dart_asset not in declared_lic_set:
                    errors.append(
                        ValidationError(
                            artifact_id,
                            "LICENCE_REGISTRY_ASSET_MISSING",
                            f"Dart registered licence asset '{dart_asset}' is not declared in 'runtime_licence_registry_assets'",
                        )
                    )

        # 6. Catalog manifest cross-check
        catalog_manifest = item.get("catalog_manifest")
        if not isinstance(catalog_manifest, dict):
            errors.append(
                ValidationError(
                    artifact_id,
                    "CATALOG_MANIFEST_SPEC_MISSING",
                    "'catalog_manifest' is required and must be an object",
                )
            )
        else:
            manifest_file = catalog_manifest.get("manifest_file")
            target_file = catalog_manifest.get("target_file")
            expected_sha256 = catalog_manifest.get("expected_sha256")
            expected_size = catalog_manifest.get("expected_size_bytes")
            expected_schema = catalog_manifest.get("expected_schema_version")

            if not expected_sha256 or not SHA256_RE.match(expected_sha256):
                errors.append(
                    ValidationError(
                        artifact_id,
                        "MALFORMED_SHA256",
                        f"Catalog manifest 'expected_sha256' '{expected_sha256}' is malformed",
                    )
                )
            if not isinstance(expected_size, int) or isinstance(expected_size, bool) or expected_size <= 0:
                errors.append(
                    ValidationError(
                        artifact_id,
                        "CATALOG_SIZE_MISMATCH",
                        f"Catalog manifest 'expected_size_bytes' must be a positive integer, got '{expected_size}'",
                    )
                )
            if expected_schema is not None and (not isinstance(expected_schema, int) or isinstance(expected_schema, bool) or expected_schema <= 0):
                errors.append(
                    ValidationError(
                        artifact_id,
                        "CATALOG_SCHEMA_VERSION_MISMATCH",
                        f"Catalog manifest 'expected_schema_version' must be a positive integer, got '{expected_schema}'",
                    )
                )

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
                    if lic not in PERMITTED_OPEN_SOURCE_LICENSES:
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "LICENCE_NOT_PERMITTED",
                                f"Notices-owned record '{pin_name}' licence '{lic}' is not permitted",
                            )
                        )
                    if isinstance(lic_id, str) and not _matches_licence_token(lic, lic_id):
                        errors.append(
                            ValidationError(
                                artifact_id,
                                "LICENCE_IDENTIFIER_DRIFT",
                                f"License '{lic}' required by notices-owned record '{pin_name}' is not declared in 'licence_identifier'",
                            )
                        )
                snippet = pin_info.get("snippet", "")
                for lic in sorted(req_lics):
                    if not _matches_licence_token(lic, snippet):
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
                if not _matches_licence_token(lic, lic_id):
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

    # 4. Scope required-class completeness
    if scope in ("production-package", "all"):
        for req_id in sorted(REQUIRED_SCOPE_CLASSES["production-package"]):
            if req_id not in seen_production_classes:
                errors.append(
                    ValidationError(
                        req_id,
                        "REQUIRED_ARTIFACT_CLASS_MISSING",
                        f"Required production-package artifact class '{req_id}' is missing from inventory",
                    )
                )

    if scope in ("test-only", "all"):
        for req_id in sorted(REQUIRED_SCOPE_CLASSES["test-only"]):
            if req_id not in seen_test_only_classes:
                errors.append(
                    ValidationError(
                        req_id,
                        "REQUIRED_ARTIFACT_CLASS_MISSING",
                        f"Required test-only artifact class '{req_id}' is missing from inventory",
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
        all_artifacts = data.get("artifacts", [])
        artifacts = [
            art for art in all_artifacts
            if scope == "all" or art.get("scope") == scope
        ]
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
            if sot:
                lines.append(f"    - Source truth paths: {len(sot)} verified")
            manifest = art.get("catalog_manifest", {})
            if manifest:
                lines.append(
                    f"    - Catalog manifest: verified (sha256: {manifest.get('expected_sha256')[:8]}..., size: {manifest.get('expected_size_bytes')} bytes)"
                )
            pkg_assets = art.get("required_package_assets", [])
            if pkg_assets:
                lines.append(f"    - Package assets: {len(pkg_assets)} verified in pubspec.yaml")
            srcs = art.get("source_families")
            cov = art.get("source_coverage")
            if cov:
                lines.append("    - Source coverage: verified against owner truth (matrix.json + notices)")
            elif srcs:
                lines.append(f"    - Upstream source families: {len(srcs)} verified against owner truth")
            src = art.get("source")
            if src:
                lines.append(f"    - Upstream source: {src.get('package_name')}=={src.get('version')} (sha256: {src.get('artifact_sha256')[:8]}...) verified in {len(src.get('lockfiles', []))} lockfiles")
            proj_src = art.get("project_source")
            if proj_src:
                lines.append(f"    - Project reference integrity: {len(proj_src.get('integrity_files', []))} file(s) verified")
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
        choices=["production-package", "test-only", "all"],
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
