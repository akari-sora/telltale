#!/usr/bin/env python3
"""Offline, deterministic public artifact privacy & redaction guard (Issue #11, WS-07 Slice 3).

Enforces fail-closed publication boundaries for derived evidence summaries,
public test artifacts, and bug report fixtures. Validates that publication
candidates contain zero sensitive identifiers (VIN, MAC, device UUIDs, device
serials, customer/plate IDs, GPS coordinates, user-home paths, or correlated
timestamps with identity).

Strictly isolates public summaries from private raw diagnostic captures.
Never mutates source files. Never echoes raw sensitive tokens, keys, or source
rows in findings or exception messages.

Usage:
    python3 tool/workshop/public_artifact_guard.py check \\
        --classification public-summary \\
        --format json|csv|log|segments|auto \\
        [--policy docs/privacy/public-artifact-policy.json] \\
        [--output text|json] \\
        <path>

Exit codes:
    0: Classification is 'public-summary' and zero sensitive findings detected.
    1: Classification is not publishable OR sensitive findings detected.
    2: Input/format/schema error (sanitized error message).
"""
from __future__ import annotations

import argparse
import csv
import io
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

DEFAULT_MAX_INPUT_BYTES = 10 * 1024 * 1024  # 10 MB

VALID_CLASSIFICATIONS = frozenset({
    "private-raw",
    "public-summary",
    "synthetic-canary",
})

VALID_FORMATS = frozenset({
    "auto",
    "json",
    "csv",
    "log",
    "segments",
})

# Standard ISO 3779 VIN pattern (17 alphanumeric chars, excluding I, O, Q)
VIN_EXACT_RE = re.compile(r"^[A-HJ-NPR-Z0-9]{17}$", re.IGNORECASE)
VIN_SUBSTR_RE = re.compile(r"[A-HJ-NPR-Z0-9]{17}", re.IGNORECASE)
VIN_LOG_RE = re.compile(r"\b(?:vin|vehicle_id|chassis)\s*[:=]\s*([A-HJ-NPR-Z0-9]{17})\b", re.IGNORECASE)

# Standard MAC address: 6 hex pairs separated by : or -
MAC_RE = re.compile(r"\b(?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}\b")

# UUID regex
UUID_RE = re.compile(
    r"\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b"
)
DEVICE_UUID_LOG_RE = re.compile(
    r"\b(?:device|adapter|peripheral|dongle|hardware)\s*(?:uuid|id)\s*[:=]\s*([0-9a-fA-F-]{36})\b",
    re.IGNORECASE,
)

# Device serial
DEVICE_SERIAL_LOG_RE = re.compile(
    r"\b(?:device|adapter|hardware|dongle)\s*serial\s*[:=]\s*(\S+)",
    re.IGNORECASE,
)

# Plate or customer ID
PLATE_OR_CUSTOMER_LOG_RE = re.compile(
    r"\b(?:license_plate|plate_number|plate|customer_id|customer_name|client_id)\s*[:=]\s*(\S+)",
    re.IGNORECASE,
)

# User home paths
USER_PATH_UNIX_RE = re.compile(r"(?:^|[\s\"'(=,/])/(?:Users|home)/[a-zA-Z0-9_\.\-]+/[^\s\"'\)]+", re.IGNORECASE)
USER_PATH_WIN_RE = re.compile(r"(?:^|[\s\"'(=,/])[a-zA-Z]:\\Users\\[a-zA-Z0-9_\.\-]+\\[^\s\"'\)]+", re.IGNORECASE)

# GPS coordinates in text/log
GPS_LOG_RE = re.compile(
    r"\b(?:lat|latitude)\s*[:=]\s*([-+]?\d+(?:\.\d+)?).*?\b(?:lon|lng|longitude)\s*[:=]\s*([-+]?\d+(?:\.\d+)?)",
    re.IGNORECASE,
)
GPS_PAIR_RE = re.compile(
    r"\b(?:gps|location|coords|coordinates)\s*[:=]\s*[-+]?([1-8]?\d(?:\.\d+)?|90(?:\.0+)?),\s*[-+]?(180(?:\.0+)?|(?:1[0-7]\d|\d{1,2})(?:\.\d+)?)",
    re.IGNORECASE,
)

# ISO timestamp or UTC timestamp pattern
TIMESTAMP_RE = re.compile(r"\b\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?\b")


@dataclass(frozen=True)
class Finding:
    """Sanitized finding representing a detected sensitive privacy item.

    Privacy contract: Must NEVER contain the matched sensitive token, raw source line,
    surrounding text, raw key name, or reversible/hash encoding.
    """
    category: str
    format: str
    location: str
    rule_id: str
    message: str

    def to_dict(self) -> dict[str, str]:
        return asdict(self)


@dataclass(frozen=True)
class SanitizedError:
    """Sanitized parse or evaluation error.

    Privacy contract: Must NEVER echo raw input snippets or sensitive values.
    """
    code: str
    message: str

    def to_dict(self) -> dict[str, str]:
        return asdict(self)


@dataclass
class GuardResult:
    """Outcome of public artifact evaluation."""
    target_path: str
    classification: str
    publishable: bool
    findings: list[Finding]
    errors: list[SanitizedError]

    @property
    def is_clean(self) -> bool:
        return self.publishable and len(self.findings) == 0 and len(self.errors) == 0


def _is_vin_key(key: str) -> bool:
    """Check if key represents vehicle identification context."""
    k = key.lower()
    return bool(re.search(r"\bvin\b", k) or k in {"vehicle_id", "vehicle_identification_number", "vin_number", "car_vin", "target_vin"})


def _is_device_uuid_key(key: str) -> bool:
    """Check if key represents explicit device/adapter UUID context."""
    k = key.lower()
    if "uuid" not in k and "id" not in k:
        return False
    return any(term in k for term in ["device", "adapter", "peripheral", "hardware", "dongle", "bt_device", "ble_device"])


def _is_device_serial_key(key: str) -> bool:
    """Check if key represents explicit device/adapter serial context."""
    k = key.lower()
    if "serial" not in k:
        return False
    return any(term in k for term in ["device", "adapter", "hardware", "dongle"]) or k in {"serial_number", "serialnumber"}


def _is_plate_or_customer_key(key: str) -> bool:
    """Check if key represents license plate or customer identifier context."""
    k = key.lower().strip()
    exact_terms = {
        "plate", "license_plate", "plate_number", "plate_no", "license_plate_number",
        "customer_id", "customer_name", "client_id", "client_name", "owner_id", "owner_name",
        "user_id", "user_name", "driver_id", "driver_name",
    }
    if k in exact_terms:
        return True
    tokens = set(re.split(r"[_\-\s]+", k))
    has_identity_stem = bool(tokens & {"plate", "customer", "client", "owner", "driver"})
    has_qualifier = bool(tokens & {"plate", "id", "name", "number", "num", "code"})
    return has_identity_stem and has_qualifier


def _is_identity_key(key: str) -> bool:
    """Check if key represents an identity context (VIN, device UUID, device serial, plate/customer)."""
    return bool(
        key
        and (
            _is_vin_key(key)
            or _is_device_uuid_key(key)
            or _is_device_serial_key(key)
            or _is_plate_or_customer_key(key)
        )
    )


def _is_timestamp_key(key: str) -> bool:
    """Check if key indicates a timestamp field."""
    k = key.lower()
    return k in {"timestamp", "time", "ts", "date", "created_at", "observed_at", "utc_time"}


def _try_hex_ascii_vin(val_str: str) -> bool:
    """Attempt decoding 34-hex string (with optional whitespace) to ASCII and check if it forms a valid VIN."""
    s = re.sub(r"\s+", "", val_str.strip())
    if len(s) == 34 and re.fullmatch(r"^[0-9A-Fa-f]{34}$", s):
        try:
            decoded = bytes.fromhex(s).decode("ascii")
            return bool(VIN_EXACT_RE.match(decoded))
        except (ValueError, UnicodeDecodeError):
            return False
    return False


def _is_vin_in_header_or_key(s: str, parent_key: str = "") -> bool:
    """Check if a dictionary key or CSV column header contains a plain VIN without misclassifying hashes or test IDs."""
    trimmed = s.strip()
    s_lower = trimmed.lower()
    parent_lower = parent_key.strip().lower()

    # Rule 1: High-confidence explicit VIN context always wins.
    # If the key or header explicitly indicates VIN context and contains a 17-char VIN pattern,
    # it must be flagged even if words like 'case', 'test', 'build' are present.
    has_vin_term = any(term in s_lower for term in ["vin", "vehicle_id", "chassis"])
    has_vin_substr = bool(VIN_SUBSTR_RE.search(trimmed))
    if has_vin_term and has_vin_substr:
        return True

    # Rule 2: Explicit negative control allowlist for hashes:
    # 40-hex Git commit SHA or 64-hex SHA-256 digest
    if len(trimmed) in {40, 64} and re.fullmatch(r"^[0-9a-fA-F]+$", trimmed):
        return False
    # Long hex strings (>= 32 chars) without VIN indicators are hashes
    if len(trimmed) >= 32 and re.fullmatch(r"^[0-9a-fA-F]+$", trimmed):
        return False

    # Rule 3: Scenario / test / build container context (E22 fix):
    # If the parent dictionary is explicitly a scenario/test/build container,
    # keys inside it are test identifiers, not vehicle VINs, unless they have explicit VIN terms.
    is_test_or_scenario_parent = parent_lower in {
        "scenarios", "scenario", "test_cases", "test_case", "tests", "test",
        "cases", "case", "fixtures", "fixture", "builds", "build", "builds_by_commit",
    }
    if is_test_or_scenario_parent:
        return False

    # Rule 4: Explicit negative control allowlist: test case and scenario identifier labels
    if re.search(r"\b(?:scenario|test|case|fixture|scenario_id|build|commit|hash)\b", s_lower):
        return False

    # Rule 5: Key IS exactly a 17-character VIN pattern and NOT in a test container
    if len(trimmed) == 17 and VIN_EXACT_RE.fullmatch(trimmed):
        return True

    return False


def _is_vin_in_reconstructed(reconstructed: str) -> bool:
    """Check if reconstructed segment payload represents a VIN without misclassifying hashes."""
    s = reconstructed.strip()
    if VIN_EXACT_RE.fullmatch(s):
        return True
    if len(s) in {40, 64} and re.fullmatch(r"^[0-9a-fA-F]+$", s):
        return False
    if len(s) >= 32 and re.fullmatch(r"^[0-9a-fA-F]+$", s) and not any(k in s.lower() for k in ["vin", "vehicle"]):
        return False
    m = VIN_SUBSTR_RE.search(s)
    if m:
        if re.fullmatch(r"^[0-9a-fA-F]+$", s):
            return False
        return True
    return False


SAFE_KEY_ALLOWLIST = frozenset({

    "schema_version",
    "policy_id",
    "classifications",
    "rule_categories",
    "status",
    "summary",
    "benchmark_summary",
    "timestamp",
    "time",
    "ts",
    "date",
    "created_at",
    "observed_at",
    "utc_time",
    "dtc_code",
    "dtc",
    "ecu_id",
    "ecu",
    "protocol",
    "scenario_id",
    "git_commit_sha",
    "git_commit",
    "session_id",
    "item_id",
    "record_id",
    "items",
    "records",
    "data",
    "payload",
    "seq",
    "index",
    "count",
    "total",
    "name",
    "type",
    "format",
    "version",
    "result",
    "findings",
    "errors",
    "code",
    "message",
    "location",
    "category",
    "publishable",
    "mutable",
    "allowed_scopes",
    "max_input_bytes",
    "supported_formats",
    "allowlist_rules",
    "template",
    "title",
    "build",
    "test_id",
    "banner",
    "endpoint",
    "total_frames",
    "error_count",
    "run_id",
    "sha256",
    "metadata",
    "connection",
    "deviceuuid",
    "device_uuid",
    "deviceserial",
    "device_serial",
    "telemetry",
    "lat",
    "lon",
    "latitude",
    "longitude",
    "raw_payload_hex",
    "event",
    "log_file",
    "vehicle",
    "vin",
    "plate",
    "license_plate",
    "plate_number",
    "customer_id",
    "client_id",
    "owner_id",
    "driver_id",
    "user_id",
    "adapter_address",
})


def _sanitize_path_segment(seg: str) -> str:
    """Sanitize path key for safe reporting in findings without echoing arbitrary keys."""
    s = str(seg).strip()
    if s.lower() in SAFE_KEY_ALLOWLIST:
        return s
    return "<key>"


def _is_sensitive_filename(name: str) -> bool:
    """Check if filename contains sensitive identifiers or tokens."""
    return bool(
        VIN_SUBSTR_RE.search(name)
        or MAC_RE.search(name)
        or UUID_RE.search(name)
        or _try_hex_ascii_vin(name)
        or re.search(r"\b(?:vin|serial|plate|customer|client|owner|driver|uuid|mac)\b", name, re.IGNORECASE)
        or re.search(r"serial|plate|customer|client|driver|owner", name, re.IGNORECASE)
    )


def _sanitize_target_label(path_str: str) -> str:
    """Sanitize target path so user home directory, host paths, and sensitive filenames are never leaked."""
    return "<artifact>"



def _reject_duplicate_keys(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    """Strict JSON object_pairs_hook rejecting duplicate keys fail-closed."""
    d: dict[str, Any] = {}
    for k, v in pairs:
        if k in d:
            raise ValueError(f"duplicate key {k}")
        d[k] = v
    return d


def _is_segment_container(items: list[Any], path_prefix: str = "") -> bool:
    """Detect if a list represents an explicit segment container."""
    if not items or not isinstance(items, list):
        return False
    p_lower = path_prefix.lower()
    if any(k in p_lower for k in ["segment", "sequence", "fragment"]):
        return True
    for x in items:
        if isinstance(x, dict) and ("seq" in x or "index" in x) and ("payload" in x or "data" in x):
            return True
    return False


class PublicArtifactGuard:
    """Deterministic, fail-closed privacy guard for publication candidates."""

    REQUIRED_CATEGORIES = frozenset({
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
    })

    def __init__(
        self,
        policy_path: Path | None = None,
        max_bytes: int = DEFAULT_MAX_INPUT_BYTES,
    ) -> None:
        self.max_bytes = max_bytes
        self.policy: dict[str, Any] = {}
        self.policy_error: SanitizedError | None = None

        target_policy = policy_path if policy_path is not None else Path("docs/privacy/public-artifact-policy.json")
        if not target_policy.is_file():
            self.policy_error = SanitizedError(
                code="error.invalid_policy",
                message="Policy file missing or unreadable.",
            )
            return

        try:
            policy_data = json.loads(target_policy.read_text(encoding="utf-8"))
        except Exception:
            self.policy_error = SanitizedError(
                code="error.invalid_policy",
                message="Malformed policy JSON syntax.",
            )
            return

        if not isinstance(policy_data, dict):
            self.policy_error = SanitizedError(
                code="error.invalid_policy",
                message="Policy root must be a JSON object.",
            )
            return

        if policy_data.get("schema_version") != 1:
            self.policy_error = SanitizedError(
                code="error.invalid_policy",
                message="Unsupported policy schema version.",
            )
            return

        if policy_data.get("policy_id") != "ws07-public-artifact-privacy-policy":
            self.policy_error = SanitizedError(
                code="error.invalid_policy",
                message="Invalid policy identifier.",
            )
            return

        classifications = policy_data.get("classifications")
        if not isinstance(classifications, dict) or set(classifications.keys()) != VALID_CLASSIFICATIONS:
            self.policy_error = SanitizedError(
                code="error.invalid_policy",
                message="Policy classifications mismatch.",
            )
            return

        expected_semantics = {
            "private-raw": (False, False),
            "public-summary": (True, False),
            "synthetic-canary": (False, False),
        }
        for cls_name, (exp_pub, exp_mut) in expected_semantics.items():
            cfg = classifications.get(cls_name)
            if not isinstance(cfg, dict):
                self.policy_error = SanitizedError(
                    code="error.invalid_policy",
                    message="Policy classification definition must be an object.",
                )
                return
            if cfg.get("publishable") is not exp_pub or cfg.get("mutable") is not exp_mut:
                self.policy_error = SanitizedError(
                    code="error.invalid_policy",
                    message="Invalid policy classification publishable/mutable semantics.",
                )
                return

        categories = policy_data.get("rule_categories")
        if not isinstance(categories, dict) or set(categories.keys()) != self.REQUIRED_CATEGORIES:
            self.policy_error = SanitizedError(
                code="error.invalid_policy",
                message="Policy missing required detection categories.",
            )
            return

        formats = policy_data.get("supported_formats")
        expected_formats = {"json", "csv", "log", "segments"}
        if not isinstance(formats, list) or set(formats) != expected_formats or len(formats) != len(expected_formats):
            self.policy_error = SanitizedError(
                code="error.invalid_policy",
                message="Policy missing supported formats.",
            )
            return

        pol_max = policy_data.get("max_input_bytes")
        if pol_max is not None:
            if not isinstance(pol_max, int) or isinstance(pol_max, bool) or pol_max <= 0:
                self.policy_error = SanitizedError(
                    code="error.invalid_policy",
                    message="Policy max_input_bytes must be a positive integer.",
                )
                return
            self.max_bytes = min(self.max_bytes, pol_max)

        self.policy = policy_data

    def check(
        self,
        target_path: Path | str,
        classification: str = "public-summary",
        format_hint: str = "auto",
    ) -> GuardResult:
        """Evaluate an artifact at target_path for publication compliance."""
        path = Path(target_path)
        clean_target = _sanitize_target_label(str(path))

        if self.policy_error is not None:
            return GuardResult(
                target_path=clean_target,
                classification=classification if classification in VALID_CLASSIFICATIONS else "<invalid>",
                publishable=False,
                findings=[],
                errors=[self.policy_error],
            )

        if classification not in VALID_CLASSIFICATIONS:
            return GuardResult(
                target_path=clean_target,
                classification="<invalid>",
                publishable=False,
                findings=[],
                errors=[SanitizedError(
                    code="error.invalid_classification",
                    message="Unsupported classification parameter.",
                )],
            )

        # Gate Rule S3-A12 / S3-M6: Non-public-summary cannot be published under any circumstances.
        if classification == "private-raw":
            return GuardResult(
                target_path=clean_target,
                classification=classification,
                publishable=False,
                findings=[],
                errors=[SanitizedError(
                    code="policy.not_publishable",
                    message="Artifact classified as 'private-raw' cannot be published.",
                )],
            )

        if classification == "synthetic-canary":
            return GuardResult(
                target_path=clean_target,
                classification=classification,
                publishable=False,
                findings=[],
                errors=[SanitizedError(
                    code="policy.not_publishable",
                    message="Artifact classified as 'synthetic-canary' cannot be published.",
                )],
            )

        if not path.is_file():
            return GuardResult(
                target_path=clean_target,
                classification=classification,
                publishable=False,
                findings=[],
                errors=[SanitizedError(
                    code="error.file_not_found",
                    message="Target file does not exist or is not a regular file.",
                )],
            )

        try:
            size = path.stat().st_size
            if size > self.max_bytes:
                return GuardResult(
                    target_path=clean_target,
                    classification=classification,
                    publishable=False,
                    findings=[],
                    errors=[SanitizedError(
                        code="error.oversized_input",
                        message=f"File size ({size} bytes) exceeds maximum permitted limit ({self.max_bytes} bytes).",
                    )],
                )
        except OSError:
            return GuardResult(
                target_path=clean_target,
                classification=classification,
                publishable=False,
                findings=[],
                errors=[SanitizedError(
                    code="error.file_access",
                    message="Failed to access file properties.",
                )],
            )

        # Read binary bytes first to verify UTF-8 strictly without leaking raw text on failure
        try:
            raw_bytes = path.read_bytes()
        except OSError:
            return GuardResult(
                target_path=clean_target,
                classification=classification,
                publishable=False,
                findings=[],
                errors=[SanitizedError(
                    code="error.file_read",
                    message="Failed to read file contents.",
                )],
            )

        try:
            content = raw_bytes.decode("utf-8")
        except UnicodeDecodeError:
            return GuardResult(
                target_path=clean_target,
                classification=classification,
                publishable=False,
                findings=[],
                errors=[SanitizedError(
                    code="error.unsupported_encoding",
                    message="File contains invalid UTF-8 encoding.",
                )],
            )

        fmt = self._resolve_format(path, format_hint)
        if fmt not in VALID_FORMATS or fmt == "auto" or fmt == "unknown":
            return GuardResult(
                target_path=clean_target,
                classification=classification,
                publishable=False,
                findings=[],
                errors=[SanitizedError(
                    code="error.unsupported_format",
                    message="Unable to determine supported file format.",
                )],
            )

        findings, errors = self.scan_content(content, fmt)

        return GuardResult(
            target_path=clean_target,
            classification=classification,
            publishable=len(findings) == 0 and len(errors) == 0,
            findings=findings,
            errors=errors,
        )

    def _resolve_format(self, path: Path, hint: str) -> str:
        """Resolve format from explicit hint or file suffix."""
        if hint != "auto":
            return hint.lower()
        suffixes = [s.lower() for s in path.suffixes]
        if not suffixes:
            return "unknown"
        suffix = suffixes[-1]
        if suffix in {".share", ".tmp"} and len(suffixes) >= 2:
            suffix = suffixes[-2]
        if suffix == ".json":
            return "json"
        if suffix == ".csv":
            return "csv"
        if suffix in {".log", ".txt", ".out"}:
            return "log"
        if suffix in {".segments", ".seq"}:
            return "segments"
        return "unknown"

    def scan_content(self, content: str, fmt: str) -> tuple[list[Finding], list[SanitizedError]]:
        """Scan string content according to format rules."""
        if fmt == "json":
            return self._scan_json(content)
        if fmt == "csv":
            return self._scan_csv(content)
        if fmt == "segments":
            return self._scan_segments(content)
        if fmt == "log":
            return self._scan_log(content)
        return [], [SanitizedError(code="error.unsupported_format", message="Unsupported artifact format.")]

    # --- JSON Scanner ---
    def _scan_json(self, content: str) -> tuple[list[Finding], list[SanitizedError]]:
        findings: list[Finding] = []
        errors: list[SanitizedError] = []

        try:
            root = json.loads(content, object_pairs_hook=_reject_duplicate_keys)
        except ValueError as exc:
            if "duplicate key" in str(exc):
                return [], [SanitizedError(code="schema.duplicate_json_key", message="Duplicate JSON key detected in payload.")]
            return [], [SanitizedError(code="error.malformed_json", message="Malformed JSON syntax.")]
        except Exception:
            return [], [SanitizedError(code="error.malformed_json", message="Malformed JSON syntax.")]

        if not isinstance(root, (dict, list)):
            return [], [SanitizedError(code="error.invalid_json_root", message="JSON root must be an object or array.")]

        self._walk_json(root, "root", findings, errors)
        return findings, errors

    def _walk_json(
        self,
        obj: Any,
        path_prefix: str,
        findings: list[Finding],
        errors: list[SanitizedError],
        parent_key: str = "",
        declared_segment_container: bool = False,
    ) -> None:
        if declared_segment_container:
            if not isinstance(obj, list):
                errors.append(SanitizedError(
                    code="schema.invalid_segments",
                    message="Declared segment container must be a JSON array.",
                ))
                if isinstance(obj, str):
                    self._check_value_strings(obj, "json", path_prefix, findings)
                return
            self._check_segment_items(obj, path_prefix, findings, errors)
            return

        if isinstance(obj, dict):
            # Check for GPS coordinates in current object
            self._check_dict_gps(obj, path_prefix, findings)

            # Check for timestamp + identity correlation in current object
            self._check_dict_correlation(obj, path_prefix, findings)

            for key, val in obj.items():
                safe_key = _sanitize_path_segment(str(key))
                child_path = f"{path_prefix}.{safe_key}" if path_prefix != "root" else safe_key

                # Inspect key string itself for sensitive leaks
                if isinstance(key, str):
                    self._check_value_strings(key, "json", f"{path_prefix}[key]", findings)
                    if _is_vin_in_header_or_key(key, parent_key=parent_key):
                        findings.append(Finding(
                            category="vehicle.vin.plain",
                            format="json",
                            location=f"{path_prefix}[key]",
                            rule_id="vehicle.vin.plain",
                            message="Plain VIN detected in JSON key",
                        ))
                    if UUID_RE.search(key) and any(t in key.lower() for t in ["device", "adapter", "hardware", "peripheral"]):
                        findings.append(Finding(
                            category="device.uuid",
                            format="json",
                            location=f"{path_prefix}[key]",
                            rule_id="device.uuid",
                            message="Device UUID detected in JSON key",
                        ))

                # Key context checks (scalar values and rejection of invalid object types)
                if _is_vin_key(key):
                    if isinstance(val, str) and VIN_EXACT_RE.match(val.strip()):
                        findings.append(Finding(
                            category="vehicle.vin.plain",
                            format="json",
                            location=child_path,
                            rule_id="vehicle.vin.plain",
                            message="Plain VIN detected in explicit vehicle context",
                        ))
                    elif isinstance(val, dict):
                        errors.append(SanitizedError(
                            code="schema.invalid_identity_type",
                            message="Identity field cannot contain nested objects.",
                        ))

                if _is_device_uuid_key(key):
                    if isinstance(val, str) and UUID_RE.search(val):
                        findings.append(Finding(
                            category="device.uuid",
                            format="json",
                            location=child_path,
                            rule_id="device.uuid",
                            message="Device UUID detected in device context",
                        ))
                    elif isinstance(val, dict):
                        errors.append(SanitizedError(
                            code="schema.invalid_identity_type",
                            message="Identity field cannot contain nested objects.",
                        ))

                if _is_device_serial_key(key):
                    if isinstance(val, (str, int)) and not isinstance(val, bool) and str(val).strip():
                        findings.append(Finding(
                            category="device.serial",
                            format="json",
                            location=child_path,
                            rule_id="device.serial",
                            message="Device serial detected in device context",
                        ))
                    elif isinstance(val, dict):
                        errors.append(SanitizedError(
                            code="schema.invalid_identity_type",
                            message="Identity field cannot contain nested objects.",
                        ))

                if _is_plate_or_customer_key(key):
                    if isinstance(val, (str, int)) and not isinstance(val, bool) and str(val).strip():
                        findings.append(Finding(
                            category="subject.plate_or_customer_id",
                            format="json",
                            location=child_path,
                            rule_id="subject.plate_or_customer_id",
                            message="Subject identifier (plate or customer ID) detected",
                        ))
                    elif isinstance(val, dict):
                        errors.append(SanitizedError(
                            code="schema.invalid_identity_type",
                            message="Identity field cannot contain nested objects.",
                        ))

                # Value inspections
                if isinstance(val, str):
                    self._check_value_strings(val, "json", child_path, findings)

                is_segment_decl = str(key).lower().strip() in {
                    "segments", "segment", "sequences", "sequence", "fragments", "fragment",
                }

                # Recursive walk
                self._walk_json(
                    val,
                    child_path,
                    findings,
                    errors,
                    parent_key=str(key),
                    declared_segment_container=is_segment_decl,
                )

        elif isinstance(obj, list):
            # Enforce identity schema contract: identity lists cannot be bypassed by inferred segment dispatch
            if not _is_identity_key(parent_key) and _is_segment_container(obj, path_prefix):
                self._check_segment_items(obj, path_prefix, findings, errors)
                return
            else:
                for idx, item in enumerate(obj):
                    child_path = f"{path_prefix}[{idx}]"
                    if isinstance(item, str):
                        self._check_value_strings(item, "json", child_path, findings)
                        if _is_vin_key(parent_key) and VIN_EXACT_RE.match(item.strip()):
                            findings.append(Finding(
                                category="vehicle.vin.plain",
                                format="json",
                                location=child_path,
                                rule_id="vehicle.vin.plain",
                                message="Plain VIN detected in explicit vehicle context",
                            ))
                        if _is_device_uuid_key(parent_key) and UUID_RE.search(item):
                            findings.append(Finding(
                                category="device.uuid",
                                format="json",
                                location=child_path,
                                rule_id="device.uuid",
                                message="Device UUID detected in device context",
                            ))
                        if _is_device_serial_key(parent_key) and item.strip():
                            findings.append(Finding(
                                category="device.serial",
                                format="json",
                                location=child_path,
                                rule_id="device.serial",
                                message="Device serial detected in device context",
                            ))
                        if _is_plate_or_customer_key(parent_key) and item.strip():
                            findings.append(Finding(
                                category="subject.plate_or_customer_id",
                                format="json",
                                location=child_path,
                                rule_id="subject.plate_or_customer_id",
                                message="Subject identifier (plate or customer ID) detected",
                            ))
                    elif isinstance(item, int) and not isinstance(item, bool):
                        if _is_device_serial_key(parent_key):
                            findings.append(Finding(
                                category="device.serial",
                                format="json",
                                location=child_path,
                                rule_id="device.serial",
                                message="Device serial detected in device context",
                            ))
                        if _is_plate_or_customer_key(parent_key):
                            findings.append(Finding(
                                category="subject.plate_or_customer_id",
                                format="json",
                                location=child_path,
                                rule_id="subject.plate_or_customer_id",
                                message="Subject identifier (plate or customer ID) detected",
                            ))
                    elif isinstance(item, dict):
                        if _is_identity_key(parent_key):
                            errors.append(SanitizedError(
                                code="schema.invalid_identity_type",
                                message="Identity field cannot contain nested objects.",
                            ))
                    self._walk_json(item, child_path, findings, errors, parent_key=parent_key)


    def _check_dict_gps(self, d: dict[str, Any], path_prefix: str, findings: list[Finding]) -> None:
        """Check for latitude and longitude fields within the same dictionary."""
        keys = {k.lower(): k for k in d.keys()}
        lat_key = next((keys[k] for k in ["lat", "latitude"] if k in keys), None)
        lon_key = next((keys[k] for k in ["lon", "lng", "longitude"] if k in keys), None)

        if lat_key and lon_key:
            try:
                lat_val = float(d[lat_key])
                lon_val = float(d[lon_key])
                if -90.0 <= lat_val <= 90.0 and -180.0 <= lon_val <= 180.0:
                    findings.append(Finding(
                        category="location.gps",
                        format="json",
                        location=f"{path_prefix}[gps]",
                        rule_id="location.gps",
                        message="GPS coordinates detected in record",
                    ))
            except (ValueError, TypeError):
                pass

        # Also check for single string gps coordinates
        for k, v in d.items():
            if isinstance(v, str) and (GPS_LOG_RE.search(v) or GPS_PAIR_RE.search(v)):
                findings.append(Finding(
                    category="location.gps",
                    format="json",
                    location=f"{path_prefix}.{_sanitize_path_segment(str(k))}",
                    rule_id="location.gps",
                    message="GPS coordinates detected in field",
                ))

    def _check_dict_correlation(self, d: dict[str, Any], path_prefix: str, findings: list[Finding]) -> None:
        """Check for timestamp correlated with identity in the same dictionary."""
        has_timestamp = any(_is_timestamp_key(k) for k in d.keys())
        if not has_timestamp:
            for v in d.values():
                if isinstance(v, str) and TIMESTAMP_RE.search(v):
                    has_timestamp = True
                    break

        if not has_timestamp:
            return

        has_identity = False
        for k, v in d.items():
            if _is_vin_key(k) and isinstance(v, str) and VIN_EXACT_RE.match(v.strip()):
                has_identity = True
                break
            if _is_device_uuid_key(k) and isinstance(v, str) and UUID_RE.search(v):
                has_identity = True
                break
            if _is_device_serial_key(k) and str(v).strip():
                has_identity = True
                break
            if _is_plate_or_customer_key(k) and str(v).strip():
                has_identity = True
                break
            if isinstance(v, str) and MAC_RE.search(v):
                has_identity = True
                break

        if has_identity:
            findings.append(Finding(
                category="correlation.timestamp_with_identity",
                format="json",
                location=path_prefix,
                rule_id="correlation.timestamp_with_identity",
                message="Timestamp correlated with identity in same logical record",
            ))

    def _check_segment_items(
        self,
        items: list[Any],
        path_prefix: str,
        findings: list[Finding],
        errors: list[SanitizedError],
    ) -> None:
        """Validate, recursively scan, and reconstruct explicit sequence/payload segments."""
        seen_indices: set[int] = set()
        segments_map: dict[int, str] = {}

        for item_idx, item in enumerate(items):
            loc = f"{path_prefix}[{item_idx}]"
            if not isinstance(item, dict):
                errors.append(SanitizedError(
                    code="schema.invalid_segments",
                    message="Segment element must be a JSON object.",
                ))
                if isinstance(item, str):
                    self._check_value_strings(item, "json", loc, findings)
                continue

            has_seq = "seq" in item or "index" in item
            has_payload = "payload" in item or "data" in item

            if not has_seq or not has_payload:
                errors.append(SanitizedError(
                    code="schema.invalid_segments",
                    message="Segment element missing required seq or payload keys.",
                ))
                self._walk_json(item, loc, findings, errors)
                continue

            seq = item.get("seq") if "seq" in item else item.get("index")
            payload = item.get("payload") if "payload" in item else item.get("data")

            if isinstance(seq, bool) or not isinstance(seq, int) or seq < 0:
                findings.append(Finding(
                    category="vehicle.vin.fragmented",
                    format="segments",
                    location=loc,
                    rule_id="schema.missing_segment_index",
                    message="Segment missing non-negative integer sequence index",
                ))
                self._walk_json(item, loc, findings, errors)
                continue

            if payload is None or isinstance(payload, (bool, list, dict)) or not isinstance(payload, (str, int)):
                errors.append(SanitizedError(
                    code="schema.invalid_segments",
                    message="Segment payload must be a string or integer.",
                ))
                self._walk_json(item, loc, findings, errors)
                continue

            if seq in seen_indices:
                findings.append(Finding(
                    category="vehicle.vin.fragmented",
                    format="segments",
                    location=loc,
                    rule_id="schema.duplicate_segment_index",
                    message="Duplicate sequence index in segmented payload",
                ))
            seen_indices.add(seq)
            payload_str = str(payload)
            segments_map[seq] = payload_str

            # Walk every segment element for normal sensitive detectors (MAC, UUID, GPS, paths, etc.)
            self._walk_json(item, loc, findings, errors)

        if seen_indices:
            expected_count = len(seen_indices)
            for i in range(expected_count):
                if i not in seen_indices:
                    findings.append(Finding(
                        category="vehicle.vin.fragmented",
                        format="segments",
                        location=f"{path_prefix}.gap[{i}]",
                        rule_id="schema.missing_segment_index",
                        message="Missing sequence index gap in segmented payload",
                    ))

            ordered_indices = sorted(seen_indices)
            reconstructed = "".join(segments_map[idx] for idx in ordered_indices)

            if _is_vin_in_reconstructed(reconstructed):
                findings.append(Finding(
                    category="vehicle.vin.fragmented",
                    format="segments",
                    location=f"{path_prefix}.reconstructed_payload",
                    rule_id="vehicle.vin.fragmented",
                    message="Fragmented VIN reconstructed across sequence segments",
                ))

            if _try_hex_ascii_vin(reconstructed):
                findings.append(Finding(
                    category="vehicle.vin.hex_ascii",
                    format="segments",
                    location=f"{path_prefix}.reconstructed_payload",
                    rule_id="vehicle.vin.hex_ascii",
                    message="Hex ASCII VIN reconstructed across sequence segments",
                ))

    # --- CSV Scanner ---
    def _scan_csv(self, content: str) -> tuple[list[Finding], list[SanitizedError]]:
        findings: list[Finding] = []
        errors: list[SanitizedError] = []

        try:
            reader = csv.reader(io.StringIO(content), strict=True)
            rows = list(reader)
        except csv.Error:
            return [], [SanitizedError(code="error.malformed_csv", message="Malformed CSV formatting.")]
        except Exception:
            return [], [SanitizedError(code="error.malformed_csv", message="Malformed CSV formatting.")]

        if not rows:
            return [], []

        headers = [h.strip() for h in rows[0]]
        for col_idx, header in enumerate(headers):
            loc = f"header col {col_idx + 1}"
            self._check_value_strings(header, "csv", loc, findings)
            if _is_vin_in_header_or_key(header):
                findings.append(Finding(
                    category="vehicle.vin.plain",
                    format="csv",
                    location=loc,
                    rule_id="vehicle.vin.plain",
                    message="Plain VIN detected in CSV header",
                ))
            if UUID_RE.search(header) and any(t in header.lower() for t in ["device", "adapter", "hardware", "peripheral"]):
                findings.append(Finding(
                    category="device.uuid",
                    format="csv",
                    location=loc,
                    rule_id="device.uuid",
                    message="Device UUID detected in CSV header",
                ))

        for row_idx, row in enumerate(rows[1:], start=2):
            if len(row) != len(headers):
                errors.append(SanitizedError(
                    code="error.malformed_csv",
                    message="Malformed CSV row column count mismatch.",
                ))
                return findings, errors

            row_has_timestamp = False
            row_has_identity = False

            lat_val: float | None = None
            lon_val: float | None = None

            for col_idx, cell in enumerate(row):
                header = headers[col_idx] if col_idx < len(headers) else f"col_{col_idx}"
                cell_s = cell.strip()
                loc = f"row {row_idx}, col {col_idx + 1}"

                if _is_vin_key(header):
                    if VIN_EXACT_RE.match(cell_s):
                        findings.append(Finding(
                            category="vehicle.vin.plain",
                            format="csv",
                            location=loc,
                            rule_id="vehicle.vin.plain",
                            message="Plain VIN detected in explicit CSV column",
                        ))
                        row_has_identity = True

                if _is_device_uuid_key(header):
                    if UUID_RE.search(cell_s):
                        findings.append(Finding(
                            category="device.uuid",
                            format="csv",
                            location=loc,
                            rule_id="device.uuid",
                            message="Device UUID detected in CSV column",
                        ))
                        row_has_identity = True

                if _is_device_serial_key(header):
                    if cell_s:
                        findings.append(Finding(
                            category="device.serial",
                            format="csv",
                            location=loc,
                            rule_id="device.serial",
                            message="Device serial detected in CSV column",
                        ))
                        row_has_identity = True

                if _is_plate_or_customer_key(header):
                    if cell_s:
                        findings.append(Finding(
                            category="subject.plate_or_customer_id",
                            format="csv",
                            location=loc,
                            rule_id="subject.plate_or_customer_id",
                            message="Subject identifier detected in CSV column",
                        ))
                        row_has_identity = True

                if _is_timestamp_key(header) or TIMESTAMP_RE.search(cell_s):
                    row_has_timestamp = True

                header_l = header.lower()
                if header_l in {"lat", "latitude"}:
                    try:
                        lat_val = float(cell_s)
                    except ValueError:
                        pass
                if header_l in {"lon", "lng", "longitude"}:
                    try:
                        lon_val = float(cell_s)
                    except ValueError:
                        pass

                if MAC_RE.search(cell_s):
                    row_has_identity = True

                self._check_value_strings(cell_s, "csv", loc, findings)

            if lat_val is not None and lon_val is not None:
                if -90.0 <= lat_val <= 90.0 and -180.0 <= lon_val <= 180.0:
                    findings.append(Finding(
                        category="location.gps",
                        format="csv",
                        location=f"row {row_idx}",
                        rule_id="location.gps",
                        message="GPS coordinates detected in CSV row",
                    ))

            if row_has_timestamp and row_has_identity:
                findings.append(Finding(
                    category="correlation.timestamp_with_identity",
                    format="csv",
                    location=f"row {row_idx}",
                    rule_id="correlation.timestamp_with_identity",
                    message="Timestamp correlated with identity in same CSV row",
                ))

        return findings, errors

    # --- Segments Scanner ---
    def _scan_segments(self, content: str) -> tuple[list[Finding], list[SanitizedError]]:
        findings: list[Finding] = []
        errors: list[SanitizedError] = []

        try:
            data = json.loads(content, object_pairs_hook=_reject_duplicate_keys)
        except ValueError as exc:
            if "duplicate key" in str(exc):
                return [], [SanitizedError(code="schema.duplicate_json_key", message="Duplicate JSON key detected in segments payload.")]
            return [], [SanitizedError(code="error.malformed_json", message="Malformed JSON syntax in segments payload.")]
        except Exception:
            return [], [SanitizedError(code="error.malformed_json", message="Malformed JSON syntax in segments payload.")]

        if not isinstance(data, list):
            return [], [SanitizedError(code="schema.invalid_segments", message="Segments payload must be a JSON array.")]

        self._check_segment_items(data, "root", findings, errors)
        return findings, errors

    # --- Log/Text Scanner ---
    def _scan_log(self, content: str) -> tuple[list[Finding], list[SanitizedError]]:
        findings: list[Finding] = []
        errors: list[SanitizedError] = []

        lines = content.splitlines()
        for line_idx, line in enumerate(lines, start=1):
            loc = f"line {line_idx}"

            line_has_timestamp = bool(TIMESTAMP_RE.search(line))
            line_has_identity = False

            # Plain VIN
            if VIN_LOG_RE.search(line):
                findings.append(Finding(
                    category="vehicle.vin.plain",
                    format="log",
                    location=loc,
                    rule_id="vehicle.vin.plain",
                    message="Plain VIN detected in explicit log context",
                ))
                line_has_identity = True

            # MAC Address
            if MAC_RE.search(line):
                findings.append(Finding(
                    category="device.mac",
                    format="log",
                    location=loc,
                    rule_id="device.mac",
                    message="Hardware MAC address detected in log line",
                ))
                line_has_identity = True

            # Device UUID in device context
            if DEVICE_UUID_LOG_RE.search(line):
                findings.append(Finding(
                    category="device.uuid",
                    format="log",
                    location=loc,
                    rule_id="device.uuid",
                    message="Device UUID detected in device log context",
                ))
                line_has_identity = True

            # Device Serial
            if DEVICE_SERIAL_LOG_RE.search(line):
                findings.append(Finding(
                    category="device.serial",
                    format="log",
                    location=loc,
                    rule_id="device.serial",
                    message="Device serial detected in log line",
                ))
                line_has_identity = True

            # Plate or Customer ID
            if PLATE_OR_CUSTOMER_LOG_RE.search(line):
                findings.append(Finding(
                    category="subject.plate_or_customer_id",
                    format="log",
                    location=loc,
                    rule_id="subject.plate_or_customer_id",
                    message="Subject identifier detected in log line",
                ))
                line_has_identity = True

            # GPS in log
            m_gps = GPS_LOG_RE.search(line) or GPS_PAIR_RE.search(line)
            if m_gps:
                findings.append(Finding(
                    category="location.gps",
                    format="log",
                    location=loc,
                    rule_id="location.gps",
                    message="GPS coordinates detected in log line",
                ))

            # User home paths
            if USER_PATH_UNIX_RE.search(line) or USER_PATH_WIN_RE.search(line):
                findings.append(Finding(
                    category="host.user_path",
                    format="log",
                    location=loc,
                    rule_id="host.user_path",
                    message="User-home absolute filesystem path detected in log line",
                ))

            # Hex ASCII VIN
            found_hex_ascii = False
            for m_hex in re.finditer(r"\b([0-9A-Fa-f]{34})\b", line):
                if _try_hex_ascii_vin(m_hex.group(1)):
                    findings.append(Finding(
                        category="vehicle.vin.hex_ascii",
                        format="log",
                        location=loc,
                        rule_id="vehicle.vin.hex_ascii",
                        message="Hex-encoded ASCII VIN detected in log line",
                    ))
                    line_has_identity = True
                    found_hex_ascii = True
                    break

            if not found_hex_ascii:
                for m_run in re.finditer(r"\b([0-9A-Fa-f]{2}(?:[ \t]+[0-9A-Fa-f]{2}){16,})\b", line):
                    tokens = re.split(r"[ \t]+", m_run.group(1).strip())
                    for i in range(len(tokens) - 16):
                        candidate = "".join(tokens[i : i + 17])
                        if _try_hex_ascii_vin(candidate):
                            findings.append(Finding(
                                category="vehicle.vin.hex_ascii",
                                format="log",
                                location=loc,
                                rule_id="vehicle.vin.hex_ascii",
                                message="Hex-encoded ASCII VIN detected in log line",
                            ))
                            line_has_identity = True
                            found_hex_ascii = True
                            break
                    if found_hex_ascii:
                        break

            # Correlated timestamp with identity in same line
            if line_has_timestamp and line_has_identity:
                findings.append(Finding(
                    category="correlation.timestamp_with_identity",
                    format="log",
                    location=loc,
                    rule_id="correlation.timestamp_with_identity",
                    message="Timestamp correlated with identity in same log line",
                ))

        return findings, errors

    # --- Common Value Checker ---
    def _check_value_strings(self, val: str, fmt: str, location: str, findings: list[Finding]) -> None:
        """Scan generic string values for context-free sensitive tokens."""
        # Explicit VIN prefix context (e.g. VIN=..., vehicle_id: ..., chassis=...)
        if VIN_LOG_RE.search(val):
            findings.append(Finding(
                category="vehicle.vin.plain",
                format=fmt,
                location=location,
                rule_id="vehicle.vin.plain",
                message="Plain VIN detected in explicit context string",
            ))

        # MAC
        if MAC_RE.search(val):
            findings.append(Finding(
                category="device.mac",
                format=fmt,
                location=location,
                rule_id="device.mac",
                message="Hardware MAC address detected",
            ))

        # User-home path
        if USER_PATH_UNIX_RE.search(val) or USER_PATH_WIN_RE.search(val):
            findings.append(Finding(
                category="host.user_path",
                format=fmt,
                location=location,
                rule_id="host.user_path",
                message="User-home absolute filesystem path detected",
            ))

        # Hex-encoded ASCII VIN
        if _try_hex_ascii_vin(val):
            findings.append(Finding(
                category="vehicle.vin.hex_ascii",
                format=fmt,
                location=location,
                rule_id="vehicle.vin.hex_ascii",
                message="Hex-encoded ASCII VIN detected",
            ))
        else:
            # Check for hex VIN substrings (continuous 34-hex or space-separated 17-byte run)
            found_hex = False
            for m_hex in re.finditer(r"\b([0-9A-Fa-f]{34})\b", val):
                if _try_hex_ascii_vin(m_hex.group(1)):
                    findings.append(Finding(
                        category="vehicle.vin.hex_ascii",
                        format=fmt,
                        location=location,
                        rule_id="vehicle.vin.hex_ascii",
                        message="Hex-encoded ASCII VIN detected",
                    ))
                    found_hex = True
                    break
            if not found_hex:
                for m_run in re.finditer(r"\b([0-9A-Fa-f]{2}(?:[ \t]+[0-9A-Fa-f]{2}){16,})\b", val):
                    tokens = re.split(r"[ \t]+", m_run.group(1).strip())
                    for i in range(len(tokens) - 16):
                        candidate = "".join(tokens[i : i + 17])
                        if _try_hex_ascii_vin(candidate):
                            findings.append(Finding(
                                category="vehicle.vin.hex_ascii",
                                format=fmt,
                                location=location,
                                rule_id="vehicle.vin.hex_ascii",
                                message="Hex-encoded ASCII VIN detected",
                            ))
                            found_hex = True
                            break
                    if found_hex:
                        break


def format_text_report(result: GuardResult) -> str:
    """Format human-readable, sanitized console report."""
    target_label = _sanitize_target_label(result.target_path)
    lines: list[str] = []
    if result.is_clean:
        lines.append(f"[PASS] Public artifact check succeeded: {target_label}")
        lines.append(f"Classification: {result.classification} (Publishable: true)")
        lines.append("Sensitive findings: 0")
        return "\n".join(lines)

    lines.append(f"[FAIL] Public artifact check rejected: {target_label}")
    lines.append(f"Classification: {result.classification} (Publishable: {str(result.publishable).lower()})")

    if result.errors:
        lines.append("\nErrors:")
        for err in result.errors:
            lines.append(f"  • [{err.code}] {err.message}")

    if result.findings:
        lines.append(f"\nSensitive findings ({len(result.findings)}):")
        for f in result.findings:
            lines.append(f"  • [{f.category}] location: {f.location} | rule: {f.rule_id} | {f.message}")

    return "\n".join(lines)


def format_json_report(result: GuardResult) -> str:
    """Format machine-readable sanitized JSON report."""
    data = {
        "target_path": _sanitize_target_label(result.target_path),
        "classification": result.classification,
        "publishable": result.publishable,
        "is_clean": result.is_clean,
        "findings_count": len(result.findings),
        "findings": [f.to_dict() for f in result.findings],
        "errors": [e.to_dict() for e in result.errors],
    }
    return json.dumps(data, indent=2)


class SanitizedArgumentParser(argparse.ArgumentParser):
    """Argument parser that never echoes raw invalid tokens or arguments to stderr."""

    def error(self, message: str) -> None:
        sys.stderr.write("[FAIL] Invalid command-line arguments.\n")
        sys.exit(2)


def main(argv: list[str] | None = None) -> int:
    parser = SanitizedArgumentParser(
        description="Fail-closed public artifact privacy guard (Issue #11, WS-07 Slice 3).",
    )
    subparsers = parser.add_subparsers(dest="command", parser_class=SanitizedArgumentParser)

    check_parser = subparsers.add_parser("check", help="Check candidate artifact for publication safety.")
    check_parser.add_argument(
        "target",
        help="Path to artifact file to evaluate.",
    )
    check_parser.add_argument(
        "--classification",
        choices=["public-summary", "private-raw", "synthetic-canary"],
        default="public-summary",
        help="Artifact classification tier (default: public-summary).",
    )
    check_parser.add_argument(
        "--format",
        choices=["auto", "json", "csv", "log", "segments"],
        default="auto",
        help="Input format (default: auto).",
    )
    check_parser.add_argument(
        "--policy",
        type=Path,
        default=Path("docs/privacy/public-artifact-policy.json"),
        help="Path to public artifact policy JSON.",
    )
    check_parser.add_argument(
        "--output",
        choices=["text", "json"],
        default="text",
        help="Output report format (default: text).",
    )
    check_parser.add_argument(
        "--max-bytes",
        type=int,
        default=DEFAULT_MAX_INPUT_BYTES,
        help="Maximum allowable input file size in bytes.",
    )

    args = parser.parse_args(argv)
    if not args.command:
        sys.stderr.write("[FAIL] Missing required command.\n")
        return 2

    if args.command == "check":
        if args.max_bytes <= 0:
            sys.stderr.write("[FAIL] Invalid command-line arguments.\n")
            return 2

        guard = PublicArtifactGuard(
            policy_path=args.policy,
            max_bytes=args.max_bytes,
        )
        result = guard.check(
            target_path=args.target,
            classification=args.classification,
            format_hint=args.format,
        )

        report = format_json_report(result) if args.output == "json" else format_text_report(result)
        if result.is_clean:
            print(report)
            return 0

        # Output failure details
        if args.output == "json":
            print(report)
        else:
            print(report, file=sys.stderr)

        if result.errors and not result.findings:
            return 2 if any(e.code.startswith(("error.", "schema.")) for e in result.errors) else 1
        return 1

    return 2


if __name__ == "__main__":
    sys.exit(main())
