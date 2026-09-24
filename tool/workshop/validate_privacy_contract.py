#!/usr/bin/env python3
"""Offline, deterministic validator for Telltale privacy & data flow contracts (Issue #11, WS-07 Slice 4).

Validates:
1. data-flow-inventory.json schema, duplicate keys, typed bounds, and integrity.
2. Complete coverage of DF01–DF10 data flow domains.
3. Strict containment of source, doc, and contract paths within repo-root (rejects escaping symlinks).
4. Truthful source bindings (file existence, SHA-256 digests, genuine non-comment code symbol presence, storage facts).
5. 4-way policy document parity (PRIVACY.md zh/en, docs/privacy.html zh/en) checking visible text,
   canonical SHA-256 digests, unique anchors, required keywords, and forbidden contradictory terms.
6. Referenced test file existence and naming conventions (_test.dart / test_*.py).
7. Backup configuration, manifest XML structure, and directory mapping parity.

Usage:
    python3 tool/workshop/validate_privacy_contract.py \
        [--repo-root .] \
        [--contract docs/privacy/data-flow-inventory.json] \
        [--output text|json]

Exit codes:
    0: Static contract is valid and consistent with repository facts.
    1: Contract drift (missing claim, symbol missing, digest mismatch, policy parity failure, missing coverage).
    2: Input/schema/path validation error (duplicate keys, malformed JSON, traversal, missing file, type error).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import plistlib
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

MAX_CONTRACT_BYTES = 5 * 1024 * 1024  # 5 MB
MAX_FILE_BYTES = 5 * 1024 * 1024      # 5 MB
MAX_AGGREGATE_BYTES = 25 * 1024 * 1024  # 25 MB aggregate limit per run
MAX_FILE_READS = 64                   # Max file read count per run
MAX_AUDIT_SOURCE_BYTES = 50 * 1024 * 1024  # 50 MB aggregate limit for audited sources
MAX_AUDIT_SOURCE_FILES = 512              # Max source file read count for DF10 scan
MAX_JSON_DEPTH = 32
REQUIRED_SCHEMA_VERSION = 1
REQUIRED_CONTRACT_ID = "ws07-privacy-data-flow-contract"
HEX40_RE = re.compile(r"^[0-9a-f]{40}$")
HEX64_RE = re.compile(r"^[0-9a-f]{64}$")

class BudgetExceededError(Exception):
    """Raised when file size or aggregate read budget is exceeded."""

    def __init__(self, reason: str, target: str | None = None) -> None:
        super().__init__(reason)
        self.reason = reason
        self.target = target


class BudgetTracker:
    """Tracks cumulative bytes and file count across a validator run."""

    def __init__(
        self,
        max_aggregate_bytes: int = MAX_AGGREGATE_BYTES,
        max_reads: int = MAX_FILE_READS,
    ) -> None:
        self.max_aggregate_bytes = max_aggregate_bytes
        self.max_reads = max_reads
        self.total_bytes = 0
        self.total_reads = 0

    def record_read(self, byte_count: int, target: str | None = None) -> None:
        self.total_reads += 1
        if self.total_reads > self.max_reads:
            raise BudgetExceededError("aggregate_read_count_exceeded", target)
        self.total_bytes += byte_count
        if self.total_bytes > self.max_aggregate_bytes:
            raise BudgetExceededError("aggregate_bytes_exceeded", target)


def bounded_read_bytes(
    path: Path,
    max_bytes: int,
    tracker: BudgetTracker | None = None,
    target: str | None = None,
) -> bytes:
    """Reads a file with a limit+1 bound and tracks cumulative per-run budget."""
    try:
        with open(path, "rb") as f:
            chunk = f.read(max_bytes + 1)
            if len(chunk) > max_bytes:
                raise BudgetExceededError("file_too_large", target)
            if tracker is not None:
                tracker.record_read(len(chunk), target)
            return chunk
    except BudgetExceededError:
        raise
    except Exception as e:
        raise OSError(f"Failed reading {path}: {e}") from e

REQUIRED_COVERAGE_IDS = frozenset({
    "DF01", "DF02", "DF03", "DF04", "DF05",
    "DF06", "DF07", "DF08", "DF09", "DF10",
})

REQUIRED_CLAIM_IDS = frozenset({
    "CLAIM-DEVELOPER-NO-COLLECTION",
    "CLAIM-LOCAL-STORAGE-PARTITION",
    "CLAIM-DIAGNOSTIC-RAW-BYTES",
    "CLAIM-TELEMETRY-NDJSON",
    "CLAIM-SHARE-CACHE-LIFECYCLE",
    "CLAIM-USER-CONTROLLED-SHARE",
    "CLAIM-NETWORK-ADAPTER-ONLY",
    "CLAIM-EXTERNAL-AFFILIATE-LINKS",
    "CLAIM-PERMISSIONS-MINIMAL",
    "CLAIM-NO-THIRD-PARTY-SDKS",
    "CLAIM-OS-BACKUP-BEHAVIOR",
    "CLAIM-OPEN-SOURCE-VERIFIABLE",
})

REQUIRED_POLICY_DOCUMENTS = frozenset({
    "PRIVACY.md",
    "docs/privacy.html",
})

REQUIRED_FLOW_KEYS = frozenset({
    "id", "coverage_id", "name", "actor", "platform_scope",
    "user_trigger", "data_categories", "purpose", "storage",
    "recipient_egress_class", "retention_trigger", "local_deletion",
    "post_handoff_limitation", "backup_classification", "source_bindings",
    "claim_ids", "test_ids", "evidence_level",
})

VALID_ACTORS = frozenset({
    "app", "user", "os-backup", "external-recipient", "maintainer",
})

VALID_PLATFORMS = frozenset({
    "all", "android", "ios", "macos",
})

VALID_EGRESS_CLASSES = frozenset({
    "none", "local-private", "user-selected-app", "external-browser", "adapter-socket",
    "external-maintainer-download",
})

VALID_BACKUP_CLASSIFICATIONS = frozenset({
    "os-backup-eligible", "os-backup-excluded", "not-applicable",
})

VALID_EVIDENCE_LEVELS = frozenset({
    "STATIC-CONTRACT", "MOCK-HANDOFF", "LOOPBACK", "NATIVE", "PHYSICAL", "REAL-BACKUP", "NOT_RUN",
})

EXPECTED_PLATFORM_STORAGE = {
    "android": {
        "preferences": {
            "flutter_api": "SharedPreferences",
            "native_path": "/data/data/com.cbstudio.telltale/shared_prefs/FlutterSharedPreferences.xml",
            "backup_domain": "sharedpref",
            "backup_classification": "os-backup-eligible",
        },
        "documents": {
            "flutter_api": "getApplicationDocumentsDirectory",
            "native_path": "/data/data/com.cbstudio.telltale/app_flutter/",
            "backup_domain": "root",
            "backup_classification": "os-backup-eligible",
        },
        "cache": {
            "flutter_api": "getApplicationCacheDirectory",
            "native_path": "/data/data/com.cbstudio.telltale/cache/",
            "backup_domain": "cache",
            "backup_classification": "os-backup-excluded",
        },
    },
    "ios": {
        "preferences": {
            "flutter_api": "SharedPreferences",
            "native_path": "Library/Preferences/com.cbstudio.telltale.plist",
            "backup_classification": "os-backup-eligible",
        },
        "documents": {
            "flutter_api": "getApplicationDocumentsDirectory",
            "native_path": "Documents/",
            "backup_classification": "os-backup-eligible",
        },
        "cache": {
            "flutter_api": "getApplicationCacheDirectory",
            "native_path": "Library/Caches/",
            "backup_classification": "os-backup-excluded",
        },
    },
    "macos": {
        "preferences": {
            "flutter_api": "SharedPreferences",
            "native_path": "Library/Containers/com.cbstudio.telltale/Data/Library/Preferences/com.cbstudio.telltale.plist",
            "backup_classification": "os-backup-eligible",
        },
        "documents": {
            "flutter_api": "getApplicationDocumentsDirectory",
            "native_path": "Library/Containers/com.cbstudio.telltale/Data/Documents/",
            "backup_classification": "os-backup-eligible",
        },
        "cache": {
            "flutter_api": "getApplicationCacheDirectory",
            "native_path": "Library/Containers/com.cbstudio.telltale/Data/Library/Caches/",
            "backup_classification": "os-backup-excluded",
        },
    },
}

APPROVED_HTML_BOILERPLATE_HASHES = frozenset({
    "a338e93932a5ce976aba147dbaff6611f41863d81d1a816eb1eb0f42189c0fda",
    "9fdb8ba9098e4cf13934c95dadd2cafffcdd82e49d9458ec98f1f48ce4062663",
    "856bad524ae4c3351ed9a93ed11a40c4c7d6910c2611d838bc25669d7095d66c",
    "1d9c9ac67f7a4f3ca5fb29182a226e7aa08bc74cb1688eb95372ce19b951f93d",
    "d61521c571462954118fae9725982de3ada484a446858a636d1fd8d1e5682da9",
    "7885708f326c1e649fcadfae8ed70395b059ad3707cad1eb1caa1d3eb4f3c1d1",
    "2469e3c2f16cfac175068757ef11fc3fe13524a72645575ab9d0013ab029f891",
    "c797e5b33c637c11371b9c021edcde4d00fc05ad0df5a7bcfc9247b3f4229630",
    "8aac317fca2f48512248df2904f8c1f24542e7ea92c1e20ccd3fa95b2033c183",
    "7e055502e46a4be9a80104e6256b50c63ddfda00f37fe9ca66fd8c8e49680606",
    "be62596b3d21f16c2dab3e27100dd7672bab105a5f3f5fd83da33a29dafaa932",
    "47d4cc13d0317d87bcf2cf1e49828e9b40062aa2f30fc9df21ce156d93834682",
    "be235d044b73b0bc133af400c8f106c032ae112eba4ace4e8d7120e3256d941e",
    "35052e9d8553acabdd97e007f7b875c7f8c517302aef65a465a72eca0379d304",
})

APPROVED_MD_BOILERPLATE_HASHES = frozenset({
    "366ad3865444e338afe26d001a57194b8dec33967dc36e4bd40da550dfc83e11",
    "47d4cc13d0317d87bcf2cf1e49828e9b40062aa2f30fc9df21ce156d93834682",
    "4ba88f97dbb076d2fd843bb0af15ad016bde39c9d7fcfdd5b2dcc2887412b653",
    "56f2c684cf68614828726ac8380de820922dd8108db6b4c475afffc5862607de",
    "7885708f326c1e649fcadfae8ed70395b059ad3707cad1eb1caa1d3eb4f3c1d1",
    "8aac317fca2f48512248df2904f8c1f24542e7ea92c1e20ccd3fa95b2033c183",
    "a338e93932a5ce976aba147dbaff6611f41863d81d1a816eb1eb0f42189c0fda",
    "be235d044b73b0bc133af400c8f106c032ae112eba4ace4e8d7120e3256d941e",
    "be62596b3d21f16c2dab3e27100dd7672bab105a5f3f5fd83da33a29dafaa932",
    "c35bbc04e18cf7b2ba6057e738a593be199a621b346b18f46832109e49908e21",
    "c797e5b33c637c11371b9c021edcde4d00fc05ad0df5a7bcfc9247b3f4229630",
    "d61521c571462954118fae9725982de3ada484a446858a636d1fd8d1e5682da9",
})

APPROVED_MD_HEADING_LINES = frozenset({
    "# Telltale 隱私權政策",
    "## 一句話版本",
    "## 我們收集哪些資料",
    "## App 在你裝置上儲存哪些東西",
    "## 網路連線",
    "## 權限說明",
    "## 第三方服務",
    "## 兒童",
    "## 付費與退款",
    "## 開放原始碼",
    "## 變更",
    "## 聯絡",
    "# Telltale Privacy Policy",
    "## In one sentence",
    "## What we collect",
    "## What the app stores on your device",
    "## Network access",
    "## Permissions",
    "## Third-party services",
    "## Children",
    "## Payment and refunds",
    "## Open source",
    "## Changes",
    "## Contact",
})

APPROVED_HTML_TEXT_CHUNK_HASHES = frozenset({
    "0226fc91b55c9cfa32fdfb45eb373d5b353d610f87fc66a89b09263db8de499a",
    "12c20687675feac429c0d89ba41af07a745825796134f6cefe5d970296f3bb0e",
    "1c95ab9b144ea2f5b3bbf3635472e3274e8995c31a8a783f283e38790ec63ad9",
    "1d9c9ac67f7a4f3ca5fb29182a226e7aa08bc74cb1688eb95372ce19b951f93d",
    "1e67c8a4c160925acbde3e2a525cfe4504b2aab1b73a0d49f477431aa3fc5229",
    "1ee54a7c9947cff8c84bef3dcb17f091f2d34100825628a671033419918603ba",
    "2b5c3d26721ae9c350cf3009318b626f0fc8a90b4a2ac0ca8099c05aa849282e",
    "2ef399ddad7524afb7fa4495874ac8adb8c694598ba11147ab7ce853d7a6c471",
    "35052e9d8553acabdd97e007f7b875c7f8c517302aef65a465a72eca0379d304",
    "3583a358a585b13b6d6228f12d2baf3ef937fcf50bed4a521b70f95a520bc933",
    "47d4cc13d0317d87bcf2cf1e49828e9b40062aa2f30fc9df21ce156d93834682",
    "52f74c781b76eb9563c27cafd076d827c5c426c32f75704e7641519c2dc58b9a",
    "6437beab04db0ad3e278fc89f5a00fe0c3093641933474bfddc68cc2531952c9",
    "67a0d2e0dab41fca184a37454ca4e946011756ec7b74eede7810d7df89904a18",
    "6893a3820c7b66bf61cf6f1cb2f6de14dff119dbd11763dd1734777dc9aa5a0e",
    "6e1a0fbb65c77dc0f585536ada5de9726df798fa8dd6fa8618142a403fa91f7b",
    "705e7dfca0155da1ca8a7d508404dc2109b50f120209e0643fb5d9e70760f2aa",
    "73b39ea272d6a356ddef3954a1cff7262dca0c238a2093aeb80c81db5597f393",
    "7885708f326c1e649fcadfae8ed70395b059ad3707cad1eb1caa1d3eb4f3c1d1",
    "7aabf6ef80de7702411bb6eb09098da8d24a283d4ab5351bd3bd56f47895a54a",
    "7f6aa5b1c47f81575a4b91057e059a0498a340fe63a6680fba08bb6ec6ad74a2",
    "86cfd36802743856af8b1b8f04b5226a732271906c23c31fba6b13c59f460f9d",
    "9462cbeb03c473a0f1a431136bc9d6c91fd93364830270be5d49d1dc41ef5d04",
    "9e962b07f56c2ade4b5f050a81c909e8fd9b2a34e4c2b4671128361c6276bc06",
    "a0caba334544284ae354ff3856275d69990dd28f807ae3d16cd8c4f3eab11bbd",
    "a338e93932a5ce976aba147dbaff6611f41863d81d1a816eb1eb0f42189c0fda",
    "abccc78cc93c07931feccfbd0665c003373b48334fd8d4cf5c6d0c714e68f26e",
    "ba118bf7fc9c1aedc1edb28a0aa86e0b43b681f222af6616e13c43be87815b06",
    "bbd4b6a86bc65b6ac8e79e97afc61499158edb40f7bb404c70637b46d80a7ad2",
    "be235d044b73b0bc133af400c8f106c032ae112eba4ace4e8d7120e3256d941e",
    "be62596b3d21f16c2dab3e27100dd7672bab105a5f3f5fd83da33a29dafaa932",
    "be805ccb5f2c213752494e1a8b21d3195b3c65cd26a7b4ac3648e0c48107c71b",
    "bef04e58c3f6e2505a8e57cac0bca3c7c700952a2a4032a879bafcd2e99c9bb6",
    "c0c2cf45c20349c8aca44331a01e44c7df12b2d2777705257e7c1c7550ae69ce",
    "c69305b464ad57151b44e53d4980ced4928759693b2e160ec29e4f3a131ce914",
    "c797e5b33c637c11371b9c021edcde4d00fc05ad0df5a7bcfc9247b3f4229630",
    "c856aa9e13499fb807509b7c443c91b3b49a16675d5859ded3cfb113f798c08f",
    "d61521c571462954118fae9725982de3ada484a446858a636d1fd8d1e5682da9",
    "d7422dec270775f7703f9b589a31a96bcd84222a78c559c541e84f1342c85cdc",
    "e45c4235f5a4b17cafeffb1763a08cb549130fd43667a483f1037458905f035e",
    "e477103098262d00edc8757998d67955565d4ea4d1c040b5cb25e98e390b67aa",
    "e74c2d4b30d1276a28fde422c72229f1e6c97f4c753848b4e8d0e8d0fe9d0776",
    "f266ee838eb9271d5fb0646f7e02b87d0a937251184c062a6b9531c4ead2a857",
    "f82606e001f2d27a82dfc231fffe628da3b23c650ed9e2ad5c1162777952ced3",
    "fc6fca7b73488224150884eaf91c8e19a1fd82989cd3e77023ea89de6904bba7",
    "fea579e37bb3af9ebe7dd2ad754151a7cb319b8af489f8595744e9e5ca77b346",
    "ff2bc9eac50a63186cea9c4e0827b770b487c33df39185c224f4a9b7c1bff317",
})

GLOBAL_CONTRADICTORY_PHRASES = (
    "sends every diagnostic log",
    "to the developer automatically",
    "without asking",
    "保證不備份",
    "will never copy",
    "絕不備份",
)


class DuplicateKeyError(Exception):
    """Raised when duplicate keys are detected in JSON."""


def _dict_raise_on_duplicates(ordered_pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    d: dict[str, Any] = {}
    for k, v in ordered_pairs:
        if k in d:
            raise DuplicateKeyError()
        d[k] = v
    return d


class SanitizedArgumentParser(argparse.ArgumentParser):
    """ArgumentParser that never echoes untrusted input values to stderr."""

    def error(self, message: str) -> None:
        sys.stderr.write("error: invalid command line arguments\n")
        sys.exit(2)


@dataclass(frozen=True)
class ValidationError:
    code: str
    message: str
    target: str | None = None


def _is_safe_relative_path(p: Any) -> bool:
    """Verifies that a path is a safe non-empty relative string without traversal."""
    if not isinstance(p, str) or not p.strip():
        return False
    if p.startswith("/") or p.startswith("\\"):
        return False
    parts = Path(p).parts
    return ".." not in parts


def _resolve_contained_path(repo_root: Path, rel_path: Any) -> Path | None:
    """Resolves path relative to repo_root, ensuring no traversal or escaping symlink."""
    if not _is_safe_relative_path(rel_path):
        return None
    try:
        root_resolved = repo_root.resolve()
        target = (repo_root / rel_path).resolve()
        target.relative_to(root_resolved)
        return target
    except (ValueError, RuntimeError, OSError):
        return None


def _get_repo_head_sha(repo_root: Path) -> str | None:
    """Attempts to resolve the exact HEAD commit SHA of the repository."""
    try:
        res = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=repo_root,
            capture_output=True,
            text=True,
            timeout=2,
            check=False,
        )
        if res.returncode == 0 and res.stdout.strip():
            return res.stdout.strip()
    except Exception:
        pass
    git_head = repo_root / ".git" / "HEAD"
    if git_head.is_file():
        try:
            content = git_head.read_text("utf-8").strip()
            if content.startswith("ref: "):
                ref_path = repo_root / ".git" / content[5:].strip()
                if ref_path.is_file():
                    return ref_path.read_text("utf-8").strip()
            elif bool(HEX40_RE.match(content)):
                return content
        except Exception:
            pass
    return None


def _strip_comments_and_strings(code: str) -> str:
    """Removes comments and string literals from source code to find genuine code symbols."""
    # Remove HTML / XML comments <!-- ... -->
    code = re.sub(r'<!--[\s\S]*?-->', '', code)
    # Remove multi-line comments /* ... */
    code = re.sub(r'/\*[\s\S]*?\*/', '', code)
    # Remove single line comments // ...
    code = re.sub(r'//.*$', '', code, flags=re.MULTILINE)
    # Remove Python single line comments # ...
    code = re.sub(r'#.*$', '', code, flags=re.MULTILINE)
    # Remove multi-line string literals """...""" and '''...'''
    code = re.sub(r'("""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\')', '""', code)
    # Remove single-line string literals "..." and '...' without crossing newlines
    code = re.sub(r'("(?:\\.|[^\n"\\])*"|\'(?:\\.|[^\n\'\\])*\')', '""', code)
    return code


def normalize_clause(raw: str) -> str:
    """Extracts and normalizes visible text from Markdown or HTML clause."""
    text = re.sub(r'<!--[\s\S]*?-->', '', raw)
    # Strip inline formatting tags with empty string
    text = re.sub(r'</?(?:strong|em|code|b|i|a|span)\b[^>]*>', '', text)
    # Strip other HTML tags with space
    text = re.sub(r'<[^>]+>', ' ', text)
    # Remove Markdown links [text](url) -> text
    text = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', text)
    # Remove Markdown emphasis **text** or *text*
    text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)
    text = re.sub(r'\*([^*]+)\*', r'\1', text)
    # Remove Markdown backticks `code`
    text = re.sub(r'`([^`]+)`', r'\1', text)
    # Remove Markdown table separators |--|--|
    text = re.sub(r'\|[-:\s|]+\|', ' ', text)
    text = text.replace('|', ' ')
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def extract_html_div_by_claim_id(html_content: str, cid: str) -> str:
    """Extracts inner HTML of the claim container div using depth-balanced parsing."""
    pattern = re.compile(rf'<div\b[^>]*\bdata-claim-id=["\']{cid}["\'][^>]*>', re.IGNORECASE)
    m = pattern.search(html_content)
    if not m:
        return ""
    start_pos = m.end()
    depth = 1
    idx = start_pos
    tag_re = re.compile(r'</?div\b[^>]*>', re.IGNORECASE)
    while depth > 0:
        tm = tag_re.search(html_content, idx)
        if not tm:
            break
        tag = tm.group(0).lower()
        if tag.startswith('</'):
            depth -= 1
            if depth == 0:
                return html_content[start_pos:tm.start()]
        else:
            depth += 1
        idx = tm.end()
    return html_content[start_pos:]


def extract_md_clause(text: str, cid: str) -> str:
    """Extracts Markdown clause following the claim comment marker."""
    m = re.search(rf'<!--\s*claim:\s*{cid}\s*-->(.*?)(?:\n<!--\s*claim:|\n##\s+|\Z)', text, re.DOTALL)
    return m.group(1) if m else ""


def _check_json_depth(obj: Any, current_depth: int = 0) -> bool:
    if current_depth > MAX_JSON_DEPTH:
        return False
    if isinstance(obj, dict):
        return all(_check_json_depth(v, current_depth + 1) for v in obj.values())
    if isinstance(obj, list):
        return all(_check_json_depth(item, current_depth + 1) for item in obj)
    return True


def validate_contract_data(
    data: Any,
    repo_root: Path,
    tracker: BudgetTracker | None = None,
) -> tuple[list[ValidationError], list[ValidationError]]:
    """Validates parsed contract data.

    Returns:
        (schema_errors, drift_errors):
            schema_errors mapped to exit code 2
            drift_errors mapped to exit code 1
    """
    if tracker is None:
        tracker = BudgetTracker()
    schema_errs: list[ValidationError] = []
    drift_errs: list[ValidationError] = []

    if not isinstance(data, dict):
        schema_errs.append(ValidationError(
            code="schema.not_an_object",
            message="Contract root must be a JSON object",
            target="root",
        ))
        return schema_errs, drift_errs

    if not _check_json_depth(data):
        schema_errs.append(ValidationError(
            code="schema.depth_exceeded",
            message=f"JSON exceeds maximum depth limit of {MAX_JSON_DEPTH}",
            target="root",
        ))
        return schema_errs, drift_errs

    # 1. Root schema fields
    version = data.get("schema_version")
    if type(version) is not int or version != REQUIRED_SCHEMA_VERSION:
        schema_errs.append(ValidationError(
            code="schema.invalid_version",
            message=f"Expected integer schema_version {REQUIRED_SCHEMA_VERSION}",
            target="schema_version",
        ))

    contract_id = data.get("contract_id")
    if not isinstance(contract_id, str) or contract_id != REQUIRED_CONTRACT_ID:
        schema_errs.append(ValidationError(
            code="schema.invalid_contract_id",
            message=f"Expected contract_id '{REQUIRED_CONTRACT_ID}'",
            target="contract_id",
        ))

    base_sha = data.get("audited_base_sha")
    if not isinstance(base_sha, str) or not HEX40_RE.match(base_sha):
        schema_errs.append(ValidationError(
            code="schema.invalid_base_sha",
            message="audited_base_sha must be 40-character hex string",
            target="audited_base_sha",
        ))

    policy_ref = data.get("policy_ref")
    if not isinstance(policy_ref, str) or not policy_ref.strip():
        schema_errs.append(ValidationError(
            code="schema.invalid_policy_ref",
            message="policy_ref must be a non-empty relative path string",
            target="policy_ref",
        ))
    else:
        presolved = _resolve_contained_path(repo_root, policy_ref)
        if presolved is None or not presolved.is_file():
            schema_errs.append(ValidationError(
                code="policy_ref.file_missing",
                message="Referenced policy_ref file does not exist",
                target="policy_ref",
            ))
        else:
            expected_pref_sha = data.get("policy_ref_sha256", "386ebb1323de8de42e1dd06616aae112edc9f7cf24cd809f886bfc9c1f14f639")
            if not isinstance(expected_pref_sha, str) or not HEX64_RE.match(expected_pref_sha):
                schema_errs.append(ValidationError(
                    code="schema.invalid_policy_ref_sha256",
                    message="Contract must declare 64-hex policy_ref_sha256",
                    target="policy_ref_sha256",
                ))
            else:
                try:
                    pref_bytes = bounded_read_bytes(presolved, MAX_FILE_BYTES, tracker, "policy_ref")
                    pref_sha = hashlib.sha256(pref_bytes).hexdigest()
                    if pref_sha != expected_pref_sha:
                        drift_errs.append(ValidationError(
                            code="policy_ref.digest_mismatch",
                            message="policy_ref file digest does not match expected canonical digest",
                            target="policy_ref",
                        ))
                    pref_data = json.loads(pref_bytes.decode("utf-8"), object_pairs_hook=_dict_raise_on_duplicates)
                    classes = pref_data.get("classifications", {})
                    if not isinstance(classes, dict):
                        schema_errs.append(ValidationError(
                            code="policy_ref.invalid_schema",
                            message="policy_ref must define classifications dictionary",
                            target="policy_ref",
                        ))
                    else:
                        if classes.get("private-raw", {}).get("publishable") is not False:
                            drift_errs.append(ValidationError(
                                code="policy.private_classification_compromised",
                                message="Referenced policy allows publishing private-raw artifacts",
                                target="policy_ref",
                            ))
                        if classes.get("synthetic-canary", {}).get("publishable") is not False:
                            drift_errs.append(ValidationError(
                                code="policy.synthetic_canary_publishable",
                                message="Referenced policy allows publishing synthetic-canary artifacts",
                                target="policy_ref",
                            ))
                        if classes.get("public-summary", {}).get("publishable") is not True:
                            drift_errs.append(ValidationError(
                                code="policy.public_summary_not_publishable",
                                message="Referenced policy does not allow publishing public-summary artifacts",
                                target="policy_ref",
                            ))
                except BudgetExceededError as be:
                    schema_errs.append(ValidationError(
                        code="policy_ref.too_large" if be.reason == "file_too_large" else "budget.aggregate_exceeded",
                        message="Referenced policy_ref file exceeds maximum size limit",
                        target="policy_ref",
                    ))
                except DuplicateKeyError:
                    schema_errs.append(ValidationError(
                        code="json.duplicate_key",
                        message="Duplicate JSON key detected in policy_ref",
                        target="policy_ref",
                    ))
                except Exception:
                    schema_errs.append(ValidationError(
                        code="policy_ref.invalid",
                        message="Failed reading or parsing referenced policy_ref",
                        target="policy_ref",
                    ))

    policy_docs = data.get("policy_documents")
    if not isinstance(policy_docs, list) or not policy_docs or not all(isinstance(x, str) and x.strip() for x in policy_docs):
        schema_errs.append(ValidationError(
            code="schema.invalid_policy_documents",
            message="policy_documents must be non-empty list of path strings",
            target="policy_documents",
        ))
        policy_docs = []
    else:
        missing_pdocs = REQUIRED_POLICY_DOCUMENTS - set(policy_docs)
        if missing_pdocs:
            for mpd in sorted(missing_pdocs):
                drift_errs.append(ValidationError(
                    code="policy.document_missing",
                    message="Required policy document missing from policy_documents",
                    target=mpd,
                ))

    claims = data.get("claims")
    if not isinstance(claims, dict) or not claims:
        schema_errs.append(ValidationError(
            code="schema.invalid_claims",
            message="claims must be non-empty dictionary",
            target="claims",
        ))
        claims = {}
    else:
        for cid, cval in claims.items():
            if not isinstance(cval, str) or not cval.strip():
                schema_errs.append(ValidationError(
                    code="schema.invalid_claim_entry",
                    message="Claim description must be a non-empty string",
                    target=cid if cid in REQUIRED_CLAIM_IDS else "claims",
                ))

    missing_required_claims = REQUIRED_CLAIM_IDS - set(claims.keys())
    if missing_required_claims:
        for mc in sorted(missing_required_claims):
            drift_errs.append(ValidationError(
                code="policy.claim_missing",
                message="Required policy claim is missing from claims declaration",
                target=mc,
            ))

    unknown_inventory_claims = sorted(set(claims.keys()) - REQUIRED_CLAIM_IDS)
    if unknown_inventory_claims:
        for idx_uic in range(len(unknown_inventory_claims)):
            drift_errs.append(ValidationError(
                code="policy.unknown_claim_id",
                message="claims declaration contains unknown claim id",
                target=f"claims:unknown_claim[{idx_uic}]",
            ))

    # Validate claim parity rules schema
    claim_parity_rules = data.get("claim_parity_rules")
    if not isinstance(claim_parity_rules, dict) or not claim_parity_rules:
        schema_errs.append(ValidationError(
            code="schema.invalid_claim_parity_rules",
            message="claim_parity_rules must be non-empty dictionary mapping each claim to parity rules",
            target="claim_parity_rules",
        ))
        claim_parity_rules = {}
    else:
        missing_rules = REQUIRED_CLAIM_IDS - set(claim_parity_rules.keys())
        if missing_rules:
            for mr in sorted(missing_rules):
                schema_errs.append(ValidationError(
                    code="schema.missing_claim_parity_rule",
                    message="claim_parity_rules is missing parity rules for required claim",
                    target=mr,
                ))
        for rc_id in REQUIRED_CLAIM_IDS:
            if rc_id in claim_parity_rules:
                rule_val = claim_parity_rules[rc_id]
                if not isinstance(rule_val, dict) or not rule_val:
                    schema_errs.append(ValidationError(
                        code="schema.invalid_claim_parity_rules",
                        message="Claim parity rule entry cannot be empty",
                        target=rc_id,
                    ))
                else:
                    cd = rule_val.get("canonical_digest")
                    if (
                        not isinstance(cd, dict) or
                        not isinstance(cd.get("zh"), str) or not HEX64_RE.match(cd["zh"]) or
                        not isinstance(cd.get("en"), str) or not HEX64_RE.match(cd["en"])
                    ):
                        schema_errs.append(ValidationError(
                            code="schema.invalid_canonical_digest",
                            message="Claim parity rule must declare 64-hex canonical_digest for zh and en",
                            target=rc_id,
                        ))
                    ccd = rule_val.get("canonical_claim_digest")
                    if not isinstance(ccd, str) or not HEX64_RE.match(ccd):
                        schema_errs.append(ValidationError(
                            code="schema.invalid_canonical_claim_digest",
                            message="Claim parity rule must declare 64-hex canonical_claim_digest",
                            target=rc_id,
                        ))
                    elif rc_id in claims:
                        actual_claim_digest = hashlib.sha256(claims[rc_id].strip().encode("utf-8")).hexdigest()
                        if actual_claim_digest != ccd:
                            drift_errs.append(ValidationError(
                                code="policy.claim_description_drift",
                                message=f"Claim {rc_id} description in inventory differs from canonical claim digest",
                                target=rc_id,
                            ))

    # Validate platform storage mapping schema
    psm = data.get("platform_storage_mapping")
    if not isinstance(psm, dict) or not psm:
        schema_errs.append(ValidationError(
            code="schema.invalid_platform_storage_mapping",
            message="platform_storage_mapping must be non-empty dictionary",
            target="platform_storage_mapping",
        ))
    else:
        for plat in ("android", "ios", "macos"):
            if plat not in psm or not isinstance(psm[plat], dict) or not psm[plat]:
                schema_errs.append(ValidationError(
                    code="schema.invalid_platform_storage_mapping",
                    message=f"platform_storage_mapping missing {plat} definition",
                    target=f"platform_storage_mapping.{plat}",
                ))
            else:
                plat_dict = psm[plat]
                if plat == "android":
                    pkg = plat_dict.get("package_name")
                    if pkg != "com.cbstudio.telltale":
                        schema_errs.append(ValidationError(
                            code="schema.invalid_platform_storage_mapping",
                            message="android platform_storage_mapping must declare package_name com.cbstudio.telltale",
                            target="platform_storage_mapping.android.package_name",
                        ))
                else:
                    bid = plat_dict.get("bundle_id")
                    if bid != "com.cbstudio.telltale":
                        schema_errs.append(ValidationError(
                            code="schema.invalid_platform_storage_mapping",
                            message=f"{plat} platform_storage_mapping must declare bundle_id com.cbstudio.telltale",
                            target=f"platform_storage_mapping.{plat}.bundle_id",
                        ))

                for dir_key in ("preferences", "documents", "cache"):
                    if dir_key not in plat_dict or not isinstance(plat_dict[dir_key], dict) or not plat_dict[dir_key]:
                        schema_errs.append(ValidationError(
                            code="schema.invalid_platform_storage_mapping",
                            message=f"platform_storage_mapping.{plat} missing {dir_key} definition",
                            target=f"platform_storage_mapping.{plat}.{dir_key}",
                        ))
                    else:
                        d_info = plat_dict[dir_key]
                        f_api = d_info.get("flutter_api")
                        n_path = d_info.get("native_path")
                        b_cls = d_info.get("backup_classification")
                        if not isinstance(f_api, str) or not f_api.strip() or not isinstance(n_path, str) or not n_path.strip() or b_cls not in VALID_BACKUP_CLASSIFICATIONS:
                            schema_errs.append(ValidationError(
                                code="schema.invalid_platform_storage_mapping",
                                message=f"platform_storage_mapping.{plat}.{dir_key} has invalid field values",
                                target=f"platform_storage_mapping.{plat}.{dir_key}",
                            ))
                        expected_cls = "os-backup-excluded" if dir_key == "cache" else "os-backup-eligible"
                        if b_cls != expected_cls:
                            schema_errs.append(ValidationError(
                                code="schema.invalid_platform_storage_mapping",
                                message=f"platform_storage_mapping.{plat}.{dir_key} must have backup_classification {expected_cls}",
                                target=f"platform_storage_mapping.{plat}.{dir_key}",
                            ))
                        if plat == "android":
                            b_dom = d_info.get("backup_domain")
                            expected_dom = "sharedpref" if dir_key == "preferences" else ("root" if dir_key == "documents" else "cache")
                            if b_dom != expected_dom:
                                schema_errs.append(ValidationError(
                                    code="schema.invalid_platform_storage_mapping",
                                    message=f"platform_storage_mapping.android.{dir_key} must have backup_domain {expected_dom}",
                                    target=f"platform_storage_mapping.android.{dir_key}",
                                ))
                        expected_info = EXPECTED_PLATFORM_STORAGE.get(plat, {}).get(dir_key, {})
                        if expected_info:
                            if f_api != expected_info["flutter_api"]:
                                schema_errs.append(ValidationError(
                                    code="schema.invalid_platform_storage_mapping",
                                    message=f"platform_storage_mapping.{plat}.{dir_key} flutter_api must be {expected_info['flutter_api']}",
                                    target=f"platform_storage_mapping.{plat}.{dir_key}.flutter_api",
                                ))
                            if n_path != expected_info["native_path"]:
                                schema_errs.append(ValidationError(
                                    code="schema.invalid_platform_storage_mapping",
                                    message=f"platform_storage_mapping.{plat}.{dir_key} native_path must be {expected_info['native_path']}",
                                    target=f"platform_storage_mapping.{plat}.{dir_key}.native_path",
                                ))

    flows = data.get("flows")
    if not isinstance(flows, list) or not flows:
        schema_errs.append(ValidationError(
            code="schema.invalid_flows",
            message="flows must be non-empty list of data flow definitions",
            target="flows",
        ))
        flows = []

    if schema_errs:
        return schema_errs, drift_errs

    # 2. Flow validation and coverage completeness
    covered_domains: set[str] = set()
    seen_flow_ids: set[str] = set()

    for i, flow in enumerate(flows):
        if not isinstance(flow, dict):
            schema_errs.append(ValidationError(
                code="schema.invalid_flow_item",
                message="Flow definition must be an object",
                target=f"flows[{i}]",
            ))
            continue

        missing_flow_keys = REQUIRED_FLOW_KEYS - set(flow.keys())
        if missing_flow_keys:
            schema_errs.append(ValidationError(
                code="schema.missing_required_flow_fields",
                message="Flow is missing required schema fields",
                target=f"flows[{i}]",
            ))
            continue

        # Strictly check non-null, non-empty types for scalar text fields
        for req_str_key in (
            "name", "user_trigger", "purpose",
            "retention_trigger", "local_deletion", "post_handoff_limitation",
        ):
            val = flow.get(req_str_key)
            if not isinstance(val, str) or not val.strip():
                schema_errs.append(ValidationError(
                    code="schema.missing_required_flow_fields",
                    message=f"Flow field {req_str_key} must be a non-empty string",
                    target=f"flows[{i}].{req_str_key}",
                ))

        cats = flow.get("data_categories")
        if not isinstance(cats, list) or not all(isinstance(c, str) and c.strip() for c in cats):
            schema_errs.append(ValidationError(
                code="schema.invalid_data_categories",
                message="Flow data_categories must be a list of string categories",
                target=f"flows[{i}].data_categories",
            ))

        flow_id = flow.get("id")
        if not isinstance(flow_id, str) or not flow_id.strip():
            schema_errs.append(ValidationError(
                code="schema.missing_flow_id",
                message="Flow missing valid string id",
                target=f"flows[{i}].id",
            ))
            continue

        if flow_id in seen_flow_ids:
            schema_errs.append(ValidationError(
                code="schema.duplicate_flow_id",
                message="Duplicate flow id detected",
                target=f"flows[{i}].id",
            ))
        seen_flow_ids.add(flow_id)

        cov_id = flow.get("coverage_id")
        if not isinstance(cov_id, str) or cov_id not in REQUIRED_COVERAGE_IDS:
            schema_errs.append(ValidationError(
                code="schema.invalid_coverage_id",
                message="Invalid coverage_id in flow definition",
                target=f"flows[{i}].coverage_id",
            ))
        else:
            covered_domains.add(cov_id)

        actor = flow.get("actor")
        if not isinstance(actor, str) or actor not in VALID_ACTORS:
            schema_errs.append(ValidationError(
                code="schema.invalid_actor",
                message="Invalid actor in flow definition",
                target=f"flows[{i}].actor",
            ))

        platform = flow.get("platform_scope")
        if not isinstance(platform, str) or platform not in VALID_PLATFORMS:
            schema_errs.append(ValidationError(
                code="schema.invalid_platform_scope",
                message="Invalid platform_scope in flow definition",
                target=f"flows[{i}].platform_scope",
            ))

        egress = flow.get("recipient_egress_class")
        if not isinstance(egress, str) or egress not in VALID_EGRESS_CLASSES:
            schema_errs.append(ValidationError(
                code="schema.invalid_egress_class",
                message="Invalid recipient_egress_class in flow definition",
                target=f"flows[{i}].recipient_egress_class",
            ))

        backup_class = flow.get("backup_classification")
        if not isinstance(backup_class, str) or backup_class not in VALID_BACKUP_CLASSIFICATIONS:
            schema_errs.append(ValidationError(
                code="schema.invalid_backup_classification",
                message="Invalid backup_classification in flow definition",
                target=f"flows[{i}].backup_classification",
            ))

        evidence = flow.get("evidence_level")
        if not isinstance(evidence, str) or evidence not in VALID_EVIDENCE_LEVELS:
            schema_errs.append(ValidationError(
                code="schema.invalid_evidence_level",
                message="Invalid evidence_level in flow definition",
                target=f"flows[{i}].evidence_level",
            ))
        elif evidence == "REAL-BACKUP":
            receipt = flow.get("receipt_file")
            if not isinstance(receipt, str) or not receipt.strip():
                drift_errs.append(ValidationError(
                    code="evidence.real_backup_missing_receipt",
                    message="Flow declaring REAL-BACKUP lacks required receipt_file",
                    target=f"flows[{i}].receipt_file",
                ))
            elif receipt in REQUIRED_POLICY_DOCUMENTS:
                drift_errs.append(ValidationError(
                    code="evidence.real_backup_receipt_invalid",
                    message="Policy document cannot be used as REAL-BACKUP receipt",
                    target=f"flows[{i}].receipt_file",
                ))
            else:
                r_resolved = _resolve_contained_path(repo_root, receipt)
                if r_resolved is None or not r_resolved.is_file():
                    drift_errs.append(ValidationError(
                        code="evidence.real_backup_receipt_not_found",
                        message="Receipt file for REAL-BACKUP was not found",
                        target=f"flows[{i}].receipt_file",
                    ))
                else:
                    try:
                        rc_bytes = bounded_read_bytes(
                            r_resolved, MAX_FILE_BYTES, tracker, f"flows[{i}].receipt_file"
                        )
                        if len(rc_bytes) == 0:
                            drift_errs.append(ValidationError(
                                code="evidence.real_backup_receipt_empty",
                                message="Receipt file for REAL-BACKUP cannot be empty",
                                target=f"flows[{i}].receipt_file",
                            ))
                        else:
                            rc_json = json.loads(rc_bytes.decode("utf-8"), object_pairs_hook=_dict_raise_on_duplicates)
                            cases = rc_json.get("cases") if isinstance(rc_json, dict) else None
                            valid_cases = False
                            cmd_ids = set()
                            art_ids = set()
                            art_paths = set()
                            valid_linkage = True

                            commands = rc_json.get("commands") if isinstance(rc_json, dict) else None
                            valid_commands = False
                            if isinstance(commands, list) and len(commands) > 0:
                                v_cmds = True
                                seen_cids = set()
                                for cmd in commands:
                                    if not (
                                        isinstance(cmd, dict) and
                                        isinstance(cmd.get("command"), str) and bool(cmd["command"].strip()) and
                                        type(cmd.get("exit_code")) is int and cmd["exit_code"] == 0
                                    ):
                                        v_cmds = False
                                        break
                                    has_id = "id" in cmd
                                    has_alt = "command_id" in cmd
                                    if not has_id and not has_alt:
                                        v_cmds = False
                                        break
                                    if has_id and (not isinstance(cmd["id"], str) or not cmd["id"].strip()):
                                        v_cmds = False
                                        break
                                    if has_alt and (not isinstance(cmd["command_id"], str) or not cmd["command_id"].strip()):
                                        v_cmds = False
                                        break
                                    primary_cid = (cmd["id"] if has_id else cmd["command_id"]).strip()
                                    if primary_cid in seen_cids:
                                        v_cmds = False
                                        break
                                    seen_cids.add(primary_cid)
                                    cmd_ids.add(primary_cid)
                                    if has_id and has_alt:
                                        alt_cid = cmd["command_id"].strip()
                                        if alt_cid != primary_cid:
                                            if alt_cid in seen_cids:
                                                v_cmds = False
                                                break
                                            seen_cids.add(alt_cid)
                                        cmd_ids.add(alt_cid)
                                valid_commands = v_cmds

                            artifacts = rc_json.get("artifacts") if isinstance(rc_json, dict) else None
                            valid_artifacts = False
                            if isinstance(artifacts, list) and len(artifacts) > 0:
                                valid_arts = True
                                seen_aids = set()
                                for art in artifacts:
                                    if (
                                        not isinstance(art, dict) or
                                        not isinstance(art.get("path"), str) or not art["path"].strip() or
                                        not isinstance(art.get("sha256"), str) or not HEX64_RE.match(art["sha256"])
                                    ):
                                        valid_arts = False
                                        break
                                    has_aid = "id" in art
                                    has_alt_aid = "artifact_id" in art
                                    if not has_aid and not has_alt_aid:
                                        valid_arts = False
                                        break
                                    if has_aid and (not isinstance(art["id"], str) or not art["id"].strip()):
                                        valid_arts = False
                                        break
                                    if has_alt_aid and (not isinstance(art["artifact_id"], str) or not art["artifact_id"].strip()):
                                        valid_arts = False
                                        break
                                    primary_aid = (art["id"] if has_aid else art["artifact_id"]).strip()
                                    if primary_aid in seen_aids:
                                        valid_arts = False
                                        break
                                    seen_aids.add(primary_aid)
                                    art_ids.add(primary_aid)
                                    if has_aid and has_alt_aid:
                                        alt_aid = art["artifact_id"].strip()
                                        if alt_aid != primary_aid:
                                            if alt_aid in seen_aids:
                                                valid_arts = False
                                                break
                                            seen_aids.add(alt_aid)
                                        art_ids.add(alt_aid)

                                    art_paths.add(art["path"].strip())
                                    resolved_art = _resolve_contained_path(repo_root, art["path"])
                                    if resolved_art is None or not resolved_art.is_file():
                                        valid_arts = False
                                        break
                                    try:
                                        art_bytes = bounded_read_bytes(
                                            resolved_art, MAX_FILE_BYTES, tracker, f"flows[{i}].receipt_file.artifact"
                                        )
                                        if hashlib.sha256(art_bytes).hexdigest() != art["sha256"]:
                                            valid_arts = False
                                            break
                                    except Exception:
                                        valid_arts = False
                                        break
                                valid_artifacts = valid_arts

                            if isinstance(cases, list) and len(cases) > 0:
                                v_cases = True
                                seen_case_ids = set()
                                for c in cases:
                                    if not (
                                        isinstance(c, dict) and
                                        isinstance(c.get("id"), str) and bool(c["id"].strip()) and
                                        c.get("status") in ("PASS", "SUCCESS") and
                                        type(c.get("exit_code")) is int and c["exit_code"] == 0
                                    ):
                                        v_cases = False
                                        break
                                    cid_str = c["id"].strip()
                                    if cid_str in seen_case_ids:
                                        v_cases = False
                                        break
                                    seen_case_ids.add(cid_str)

                                    # Mandatory Linkage: Command Reference
                                    has_cmd_ref = False
                                    if "command_id" in c:
                                        c_cmd = c["command_id"]
                                        if not isinstance(c_cmd, str) or not c_cmd.strip() or c_cmd.strip() not in cmd_ids:
                                            valid_linkage = False
                                            break
                                        has_cmd_ref = True
                                    if "command_ids" in c:
                                        c_cmds = c["command_ids"]
                                        if (
                                            not isinstance(c_cmds, list) or
                                            len(c_cmds) == 0 or
                                            not all(isinstance(x, str) and bool(x.strip()) and x.strip() in cmd_ids for x in c_cmds)
                                        ):
                                            valid_linkage = False
                                            break
                                        has_cmd_ref = True
                                    if not has_cmd_ref:
                                        valid_linkage = False
                                        break

                                    # Mandatory Linkage: Artifact Reference
                                    has_art_ref = False
                                    if "artifact_id" in c:
                                        c_art = c["artifact_id"]
                                        if (
                                            not isinstance(c_art, str) or
                                            not c_art.strip() or
                                            (c_art.strip() not in art_ids and c_art.strip() not in art_paths)
                                        ):
                                            valid_linkage = False
                                            break
                                        has_art_ref = True
                                    if "artifact_ids" in c:
                                        c_arts = c["artifact_ids"]
                                        if (
                                            not isinstance(c_arts, list) or
                                            len(c_arts) == 0 or
                                            not all(
                                                isinstance(x, str) and bool(x.strip()) and (x.strip() in art_ids or x.strip() in art_paths)
                                                for x in c_arts
                                            )
                                        ):
                                            valid_linkage = False
                                            break
                                        has_art_ref = True
                                    if not has_art_ref:
                                        valid_linkage = False
                                        break
                                valid_cases = v_cases and valid_linkage
                            head_sha = rc_json.get("head_sha") if isinstance(rc_json, dict) else None
                            repo_head = _get_repo_head_sha(repo_root)
                            is_valid_head = (
                                isinstance(head_sha, str) and
                                bool(HEX40_RE.match(head_sha)) and
                                head_sha != "0" * 40 and
                                repo_head is not None and
                                head_sha == repo_head
                            )
                            if (
                                not isinstance(rc_json, dict) or
                                not isinstance(rc_json.get("receipt_id"), str) or not rc_json["receipt_id"].strip() or
                                rc_json.get("status") not in ("PASS", "SUCCESS") or
                                type(rc_json.get("exit_code")) is not int or rc_json["exit_code"] != 0 or
                                not is_valid_head or
                                not valid_cases or
                                not valid_commands or
                                not valid_artifacts
                            ):
                                drift_errs.append(ValidationError(
                                    code="evidence.real_backup_receipt_invalid",
                                    message="Receipt file fails typed schema, execution status, head_sha, commands, artifacts, or test case validation",
                                    target=f"flows[{i}].receipt_file",
                                ))
                    except BudgetExceededError as be:
                        schema_errs.append(ValidationError(
                            code="evidence.real_backup_receipt_too_large" if be.reason == "file_too_large" else "budget.aggregate_exceeded",
                            message="Receipt file exceeds maximum size limit",
                            target=f"flows[{i}].receipt_file",
                        ))
                    except DuplicateKeyError:
                        schema_errs.append(ValidationError(
                            code="json.duplicate_key",
                            message="Duplicate JSON key detected in receipt file",
                            target=f"flows[{i}].receipt_file",
                        ))
                    except Exception:
                        drift_errs.append(ValidationError(
                            code="evidence.real_backup_receipt_malformed",
                            message="Receipt file is not valid JSON",
                            target=f"flows[{i}].receipt_file",
                        ))

        if cov_id == "DF10":
            audit_scope = flow.get("audit_scope")
            if audit_scope is None:
                schema_errs.append(ValidationError(
                    code="schema.missing_audit_scope",
                    message="DF10 flow must declare audit_scope object",
                    target=f"flows[{i}].audit_scope",
                ))
            elif not isinstance(audit_scope, dict):
                schema_errs.append(ValidationError(
                    code="schema.invalid_audit_scope",
                    message="DF10 audit_scope must be a dictionary object",
                    target=f"flows[{i}].audit_scope",
                ))
            else:
                method = audit_scope.get("method")
                if not isinstance(method, str) or not method.strip():
                    schema_errs.append(ValidationError(
                        code="schema.invalid_audit_method",
                        message="DF10 audit_scope.method must be a non-empty string",
                        target=f"flows[{i}].audit_scope.method",
                    ))

                roots = audit_scope.get("audited_roots")
                if not isinstance(roots, list) or len(roots) == 0 or not all(isinstance(r, str) and r.strip() for r in roots):
                    schema_errs.append(ValidationError(
                        code="schema.invalid_audited_roots",
                        message="DF10 audit_scope.audited_roots must be a non-empty list of root paths",
                        target=f"flows[{i}].audit_scope.audited_roots",
                    ))
                else:
                    for r in roots:
                        r_resolved = _resolve_contained_path(repo_root, r)
                        if r_resolved is None or not (r_resolved.is_file() or r_resolved.is_dir()):
                            drift_errs.append(ValidationError(
                                code="audit.root_missing",
                                message="Audited root path does not exist on disk",
                                target=f"flows[{i}].audit_scope.audited_roots",
                            ))

                patterns = audit_scope.get("prohibited_sdk_patterns")
                if not isinstance(patterns, list) or len(patterns) == 0 or not all(isinstance(p, str) and p.strip() for p in patterns):
                    schema_errs.append(ValidationError(
                        code="schema.invalid_prohibited_patterns",
                        message="DF10 audit_scope.prohibited_sdk_patterns must be a non-empty list of pattern strings",
                        target=f"flows[{i}].audit_scope.prohibited_sdk_patterns",
                    ))

                cmd = audit_scope.get("audit_command")
                if not isinstance(cmd, str) or not cmd.strip():
                    schema_errs.append(ValidationError(
                        code="schema.invalid_audit_command",
                        message="DF10 audit_scope.audit_command must be a non-empty string",
                        target=f"flows[{i}].audit_scope.audit_command",
                    ))

                expected_lock_sha = audit_scope.get("target_source_lock_sha256")
                if not isinstance(expected_lock_sha, str) or not HEX64_RE.match(expected_lock_sha):
                    schema_errs.append(ValidationError(
                        code="schema.invalid_lock_sha",
                        message="DF10 audit_scope must declare 64-hex target_source_lock_sha256",
                        target=f"flows[{i}].audit_scope.target_source_lock_sha256",
                    ))

                rc_file = audit_scope.get("receipt_file")
                if not isinstance(rc_file, str) or not rc_file.strip():
                    schema_errs.append(ValidationError(
                        code="schema.missing_receipt_file",
                        message="DF10 audit_scope must declare receipt_file path",
                        target=f"flows[{i}].audit_scope.receipt_file",
                    ))
                else:
                    r_resolved = _resolve_contained_path(repo_root, rc_file)
                    if r_resolved is None:
                        schema_errs.append(ValidationError(
                            code="path.traversal_or_escape",
                            message="Receipt file path escapes repository root",
                            target=f"flows[{i}].audit_scope.receipt_file",
                        ))
                    elif not r_resolved.is_file():
                        drift_errs.append(ValidationError(
                            code="audit.receipt_missing",
                            message="Receipt file does not exist",
                            target=f"flows[{i}].audit_scope.receipt_file",
                        ))
                    else:
                        parse_failed = False
                        try:
                            rc_bytes = bounded_read_bytes(
                                r_resolved, MAX_FILE_BYTES, tracker, f"flows[{i}].audit_scope.receipt_file"
                            )
                            rc_data = json.loads(rc_bytes.decode("utf-8"), object_pairs_hook=_dict_raise_on_duplicates)
                        except DuplicateKeyError:
                            schema_errs.append(ValidationError(
                                code="json.duplicate_key",
                                message="Duplicate JSON key detected in audit receipt file",
                                target=f"flows[{i}].audit_scope.receipt_file",
                            ))
                            parse_failed = True
                        except Exception:
                            drift_errs.append(ValidationError(
                                code="audit.receipt_malformed",
                                message="Audit receipt file is not valid JSON",
                                target=f"flows[{i}].audit_scope.receipt_file",
                            ))
                            parse_failed = True

                        if not parse_failed and not isinstance(rc_data, dict):
                            schema_errs.append(ValidationError(
                                code="audit.receipt_malformed",
                                message="Audit receipt file is not a JSON object",
                                target=f"flows[{i}].audit_scope.receipt_file",
                            ))
                        elif isinstance(rc_data, dict):
                            rc_status = rc_data.get("status")
                            rc_exit_code = rc_data.get("exit_code")
                            rc_hits = rc_data.get("hits_count")
                            rc_findings = rc_data.get("findings")
                            rc_tool = rc_data.get("tool_version")
                            rc_method = rc_data.get("audit_type")
                            rc_cmd = rc_data.get("command")
                            rc_roots = rc_data.get("audited_roots")
                            rc_patterns = rc_data.get("prohibited_sdk_patterns")
                            rc_sources = rc_data.get("audited_sources")

                            if (
                                not isinstance(rc_tool, str) or not rc_tool.strip() or
                                not isinstance(rc_method, str) or not rc_method.strip() or
                                not isinstance(rc_cmd, str) or not rc_cmd.strip() or
                                not isinstance(rc_roots, list) or len(rc_roots) == 0 or
                                not isinstance(rc_patterns, list) or len(rc_patterns) == 0 or
                                not isinstance(rc_sources, dict) or len(rc_sources) == 0
                            ):
                                schema_errs.append(ValidationError(
                                    code="audit.receipt_metadata_missing",
                                    message="Receipt is missing required execution metadata fields",
                                    target=f"flows[{i}].audit_scope.receipt_file",
                                ))

                            scope_status = audit_scope.get("status")
                            scope_exit_code = audit_scope.get("exit_code")
                            scope_hits = audit_scope.get("hits_count")

                            if (
                                rc_status != "PASS" or
                                rc_exit_code != 0 or
                                rc_hits != 0 or
                                rc_findings != "zero-third-party-sdk-dependencies" or
                                scope_status != "PASS" or
                                scope_exit_code != 0 or
                                scope_hits != 0
                            ):
                                drift_errs.append(ValidationError(
                                    code="audit.unresolved_hits",
                                    message="SDK audit receipt indicates failure or unresolved prohibited SDK hits",
                                    target=f"flows[{i}].audit_scope.receipt_file",
                                ))

                            if isinstance(method, str) and isinstance(rc_method, str) and rc_method != method:
                                drift_errs.append(ValidationError(
                                    code="audit.method_mismatch",
                                    message="Receipt audit_type does not match audit_scope method",
                                    target=f"flows[{i}].audit_scope.receipt_file",
                                ))

                            if isinstance(cmd, str) and isinstance(rc_cmd, str) and rc_cmd != cmd:
                                drift_errs.append(ValidationError(
                                    code="audit.command_mismatch",
                                    message="Receipt command does not match audit_scope audit_command",
                                    target=f"flows[{i}].audit_scope.receipt_file",
                                ))

                            if isinstance(roots, list) and isinstance(rc_roots, list) and sorted(rc_roots) != sorted(roots):
                                drift_errs.append(ValidationError(
                                    code="audit.roots_mismatch",
                                    message="Receipt audited_roots does not match audit_scope audited_roots",
                                    target=f"flows[{i}].audit_scope.receipt_file",
                                ))

                            if isinstance(patterns, list) and isinstance(rc_patterns, list) and sorted(rc_patterns) != sorted(patterns):
                                drift_errs.append(ValidationError(
                                    code="audit.patterns_mismatch",
                                    message="Receipt prohibited_sdk_patterns does not match audit_scope prohibited_sdk_patterns",
                                    target=f"flows[{i}].audit_scope.receipt_file",
                                ))

                            if isinstance(expected_lock_sha, str) and HEX64_RE.match(expected_lock_sha):
                                rc_lock_sha = rc_data.get("target_lock_sha256")
                                if rc_lock_sha != expected_lock_sha:
                                    drift_errs.append(ValidationError(
                                        code="audit.lock_sha_mismatch",
                                        message="Receipt target_lock_sha256 does not match audit_scope expected lock SHA",
                                        target=f"flows[{i}].audit_scope.receipt_file",
                                    ))

                                lock_file = _resolve_contained_path(repo_root, "pubspec.lock")
                                if lock_file is None or not lock_file.is_file():
                                    drift_errs.append(ValidationError(
                                        code="audit.lockfile_missing",
                                        message="pubspec.lock does not exist on disk",
                                        target="pubspec.lock",
                                    ))
                                else:
                                    actual_lock_sha = hashlib.sha256(bounded_read_bytes(lock_file, MAX_FILE_BYTES, tracker, "pubspec.lock")).hexdigest()
                                    if actual_lock_sha != expected_lock_sha:
                                        drift_errs.append(ValidationError(
                                            code="audit.lockfile_drift",
                                            message="pubspec.lock on disk does not match declared lock SHA-256",
                                            target="pubspec.lock",
                                        ))

                            # Source manifest and prohibited pattern scan on disk (B07)
                            if isinstance(roots, list) and isinstance(patterns, list) and isinstance(rc_sources, dict):
                                disk_sources = {}
                                pattern_hit = False
                                root_resolved = repo_root.resolve()
                                compiled_patterns = [
                                    re.compile(rf"(?:\b|_){re.escape(p)}(?:\b|_)", re.IGNORECASE)
                                    for p in patterns if isinstance(p, str) and p.strip()
                                ]
                                audit_tracker = BudgetTracker(
                                    max_aggregate_bytes=MAX_AUDIT_SOURCE_BYTES,
                                    max_reads=MAX_AUDIT_SOURCE_FILES,
                                )
                                budget_exceeded = False

                                for r in sorted(roots):
                                    if budget_exceeded:
                                        break
                                    r_path = _resolve_contained_path(repo_root, r)
                                    if r_path and r_path.is_file():
                                        rel = r_path.relative_to(root_resolved).as_posix()
                                        try:
                                            b = bounded_read_bytes(r_path, MAX_FILE_BYTES, audit_tracker, f"flows[{i}].audit_scope.receipt_file")
                                            disk_sources[rel] = hashlib.sha256(b).hexdigest()
                                            try:
                                                text_content = b.decode("utf-8")
                                                for cpat in compiled_patterns:
                                                    if cpat.search(text_content):
                                                        pattern_hit = True
                                            except UnicodeDecodeError:
                                                drift_errs.append(ValidationError(
                                                    code="audit.source_encoding_error",
                                                    message="Audited source file is not valid UTF-8 text",
                                                    target=f"flows[{i}].audit_scope.receipt_file",
                                                ))
                                        except BudgetExceededError as be:
                                            drift_errs.append(ValidationError(
                                                code="audit.source_too_large" if be.reason == "file_too_large" else "budget.aggregate_exceeded",
                                                message="Audited source file exceeds size limit" if be.reason == "file_too_large" else "Audited source files exceed aggregate budget",
                                                target=f"flows[{i}].audit_scope.receipt_file",
                                            ))
                                            budget_exceeded = True
                                            break
                                    elif r_path and r_path.is_dir():
                                        for root_dir, dirs, files in os.walk(r_path):
                                            dirs.sort()
                                            for fname in sorted(files):
                                                fpath = (Path(root_dir) / fname).resolve()
                                                rel = fpath.relative_to(root_resolved).as_posix()
                                                try:
                                                    b = bounded_read_bytes(fpath, MAX_FILE_BYTES, audit_tracker, f"flows[{i}].audit_scope.receipt_file")
                                                    disk_sources[rel] = hashlib.sha256(b).hexdigest()
                                                    try:
                                                        text_content = b.decode("utf-8")
                                                        for cpat in compiled_patterns:
                                                            if cpat.search(text_content):
                                                                pattern_hit = True
                                                    except UnicodeDecodeError:
                                                        drift_errs.append(ValidationError(
                                                            code="audit.source_encoding_error",
                                                            message="Audited source file is not valid UTF-8 text",
                                                            target=f"flows[{i}].audit_scope.receipt_file",
                                                        ))
                                                except BudgetExceededError as be:
                                                    drift_errs.append(ValidationError(
                                                        code="audit.source_too_large" if be.reason == "file_too_large" else "budget.aggregate_exceeded",
                                                        message="Audited source file exceeds size limit" if be.reason == "file_too_large" else "Audited source files exceed aggregate budget",
                                                        target=f"flows[{i}].audit_scope.receipt_file",
                                                    ))
                                                    budget_exceeded = True
                                                    break
                                            if budget_exceeded:
                                                break

                                if pattern_hit:
                                    drift_errs.append(ValidationError(
                                        code="audit.unresolved_hits",
                                        message="Prohibited SDK pattern detected in source file",
                                        target=f"flows[{i}].audit_scope.receipt_file",
                                    ))

                                if not budget_exceeded and disk_sources != rc_sources:
                                    drift_errs.append(ValidationError(
                                        code="audit.source_drift",
                                        message="Audited sources on disk do not match receipt audit manifest",
                                        target=f"flows[{i}].audit_scope.receipt_file",
                                    ))

        storage = flow.get("storage")
        if (
            not isinstance(storage, dict) or
            not isinstance(storage.get("api"), str) or not storage["api"].strip() or
            not isinstance(storage.get("relative_path"), str) or not storage["relative_path"].strip()
        ):
            schema_errs.append(ValidationError(
                code="schema.invalid_storage",
                message="Flow storage must define non-empty string api and relative_path",
                target=f"flows[{i}].storage",
            ))
            storage = {}

        api_val = storage.get("api")
        rel_store_path = storage.get("relative_path", "")

        # Verify storage relative path format
        if api_val == "SharedPreferences":
            if not rel_store_path.startswith("shared_prefs/FlutterSharedPreferences.xml:"):
                schema_errs.append(ValidationError(
                    code="schema.invalid_storage_path",
                    message="SharedPreferences storage must point to FlutterSharedPreferences.xml prefix",
                    target=f"flows[{i}].storage",
                ))
        elif api_val == "getApplicationDocumentsDirectory":
            if not (rel_store_path.startswith("Documents/") or rel_store_path.startswith("last-session.log") or rel_store_path.startswith("telltale-telemetry/")):
                schema_errs.append(ValidationError(
                    code="schema.invalid_storage_path",
                    message="getApplicationDocumentsDirectory storage must reference valid documents subdirectory",
                    target=f"flows[{i}].storage",
                ))
        elif api_val == "getApplicationCacheDirectory":
            if not (rel_store_path.startswith("Caches/") or rel_store_path.startswith("telltale-app-shares/")):
                schema_errs.append(ValidationError(
                    code="schema.invalid_storage_path",
                    message="getApplicationCacheDirectory storage must reference telltale-app-shares cache directory",
                    target=f"flows[{i}].storage",
                ))

        # Consistency check for backup classification vs storage root
        if api_val in ("SharedPreferences", "getApplicationDocumentsDirectory"):
            if backup_class != "os-backup-eligible":
                drift_errs.append(ValidationError(
                    code="backup.classification_mismatch",
                    message=f"Storage API {api_val} must be classified as os-backup-eligible",
                    target=f"flows[{i}]",
                ))
        elif api_val in ("getApplicationCacheDirectory", "flutter-bundle"):
            if backup_class != "os-backup-excluded":
                drift_errs.append(ValidationError(
                    code="backup.classification_mismatch",
                    message=f"Storage API {api_val} must be classified as os-backup-excluded",
                    target=f"flows[{i}]",
                ))
        elif api_val in ("system-share-sheet", "network-socket-or-ble", "url_launcher", "none"):
            if backup_class != "not-applicable":
                drift_errs.append(ValidationError(
                    code="backup.classification_mismatch",
                    message=f"Storage API {api_val} must be classified as not-applicable",
                    target=f"flows[{i}]",
                ))
        elif api_val:
            schema_errs.append(ValidationError(
                code="schema.unknown_storage_api",
                message="Unknown storage API in flow definition",
                target=f"flows[{i}].storage.api",
            ))

        flow_claims = flow.get("claim_ids")
        if not isinstance(flow_claims, list) or not flow_claims:
            schema_errs.append(ValidationError(
                code="schema.invalid_flow_claims",
                message="Flow claim_ids must be non-empty list",
                target=f"flows[{i}].claim_ids",
            ))
        else:
            for cid in flow_claims:
                if not isinstance(cid, str) or cid not in claims:
                    drift_errs.append(ValidationError(
                        code="contract.unknown_claim_id",
                        message="Flow references undeclared claim ID",
                        target=f"flows[{i}].claim_ids",
                    ))

        # Check source bindings
        bindings = flow.get("source_bindings")
        if not isinstance(bindings, list) or not bindings:
            schema_errs.append(ValidationError(
                code="schema.invalid_source_bindings",
                message="Flow source_bindings must be non-empty list",
                target=f"flows[{i}].source_bindings",
            ))
        else:
            for j, b in enumerate(bindings):
                if (
                    not isinstance(b, dict) or
                    not isinstance(b.get("path"), str) or not b["path"].strip() or
                    not isinstance(b.get("symbol"), str) or not b["symbol"].strip() or
                    not isinstance(b.get("sha256"), str) or not HEX64_RE.match(b["sha256"]) or
                    not isinstance(b.get("storage_fact"), str) or not b["storage_fact"].strip()
                ):
                    schema_errs.append(ValidationError(
                        code="schema.invalid_binding_entry",
                        message="Source binding must define non-empty path, symbol, 64-hex sha256, and storage_fact",
                        target=f"flows[{i}].source_bindings[{j}]",
                    ))
                    continue

                rel_path = b["path"]
                symbol = b["symbol"]
                expected_sha = b["sha256"]
                storage_fact = b["storage_fact"]

                resolved = _resolve_contained_path(repo_root, rel_path)
                if resolved is None:
                    schema_errs.append(ValidationError(
                        code="path.traversal_or_escape",
                        message="Bound source path escapes repository root",
                        target=f"flows[{i}].source_bindings[{j}]",
                    ))
                    continue

                if not resolved.is_file():
                    drift_errs.append(ValidationError(
                        code="source.file_missing",
                        message="Bound source file missing from repository",
                        target=f"flows[{i}].source_bindings[{j}]",
                    ))
                    continue

                try:
                    raw_content = bounded_read_bytes(
                        resolved, MAX_FILE_BYTES, tracker, f"flows[{i}].source_bindings[{j}]"
                    )
                    actual_sha = hashlib.sha256(raw_content).hexdigest()
                    if actual_sha != expected_sha:
                        drift_errs.append(ValidationError(
                            code="source.digest_mismatch",
                            message="Bound source file SHA-256 digest mismatch",
                            target=f"flows[{i}].source_bindings[{j}]",
                        ))

                    content = raw_content.decode("utf-8")
                except BudgetExceededError as be:
                    schema_errs.append(ValidationError(
                        code="source.file_too_large" if be.reason == "file_too_large" else "budget.aggregate_exceeded",
                        message="Bound source file exceeds size limit",
                        target=f"flows[{i}].source_bindings[{j}]",
                    ))
                    continue
                except UnicodeDecodeError:
                    schema_errs.append(ValidationError(
                        code="source.invalid_utf8",
                        message="Bound source file contains invalid UTF-8 bytes",
                        target=f"flows[{i}].source_bindings[{j}]",
                    ))
                    continue
                except Exception:
                    schema_errs.append(ValidationError(
                        code="source.read_error",
                        message="Failed reading bound source file",
                        target=f"flows[{i}].source_bindings[{j}]",
                    ))
                    continue

                stripped_code = _strip_comments_and_strings(content)

                symbol_re = re.compile(r'\b' + re.escape(symbol) + r'\b')
                in_stripped = bool(symbol_re.search(stripped_code))
                in_raw = bool(symbol_re.search(content))

                # Symbol presence check (rejects if symbol is only in a comment or string literal)
                if not in_stripped and not in_raw:
                    drift_errs.append(ValidationError(
                        code="source.symbol_missing",
                        message="Symbol not found in bound source file",
                        target=f"flows[{i}].source_bindings[{j}]",
                    ))
                elif in_raw and not in_stripped and not rel_path.endswith((".yaml", ".json", ".md")):
                    drift_errs.append(ValidationError(
                        code="source.symbol_missing",
                        message="Symbol found only within comment blocks or string literals",
                        target=f"flows[{i}].source_bindings[{j}]",
                    ))

                # Storage fact verification
                if storage_fact != api_val:
                    drift_errs.append(ValidationError(
                        code="source.storage_fact_mismatch",
                        message="Declared storage API does not match binding storage fact",
                        target=f"flows[{i}]",
                    ))

                content_lower = content.lower()
                if storage_fact == "getApplicationDocumentsDirectory" and "getapplicationdocumentsdirectory" not in content_lower:
                    drift_errs.append(ValidationError(
                        code="source.storage_fact_mismatch",
                        message="Source does not contain getApplicationDocumentsDirectory storage call",
                        target=f"flows[{i}].source_bindings[{j}]",
                    ))
                elif storage_fact == "getApplicationCacheDirectory" and "getapplicationcachedirectory" not in content_lower:
                    drift_errs.append(ValidationError(
                        code="source.storage_fact_mismatch",
                        message="Source does not contain getApplicationCacheDirectory storage call",
                        target=f"flows[{i}].source_bindings[{j}]",
                    ))
                elif storage_fact == "SharedPreferences" and "sharedpreferences" not in content_lower:
                    drift_errs.append(ValidationError(
                        code="source.storage_fact_mismatch",
                        message="Source does not contain SharedPreferences storage call",
                        target=f"flows[{i}].source_bindings[{j}]",
                    ))

        # Check test ids
        tests = flow.get("test_ids")
        if not isinstance(tests, list) or len(tests) == 0:
            schema_errs.append(ValidationError(
                code="schema.invalid_test_ids",
                message="Flow test_ids must be non-empty list of test file paths",
                target=f"flows[{i}].test_ids",
            ))
        else:
            for k, tpath in enumerate(tests):
                if not isinstance(tpath, str) or not tpath.strip():
                    schema_errs.append(ValidationError(
                        code="schema.invalid_test_ids",
                        message="Test path must be non-empty string",
                        target=f"flows[{i}].test_ids[{k}]",
                    ))
                    continue
                if not (tpath.endswith("_test.dart") or tpath.startswith("test_") or "/test_" in tpath):
                    schema_errs.append(ValidationError(
                        code="schema.invalid_test_ids",
                        message="Test path must end with _test.dart or match test_*.py",
                        target=f"flows[{i}].test_ids[{k}]",
                    ))
                    continue

                tresolved = _resolve_contained_path(repo_root, tpath)
                if tresolved is None:
                    schema_errs.append(ValidationError(
                        code="path.traversal_or_escape",
                        message="Test path escapes repository root",
                        target=f"flows[{i}].test_ids[{k}]",
                    ))
                elif not tresolved.is_file():
                    drift_errs.append(ValidationError(
                        code="test.file_missing",
                        message="Referenced test file missing",
                        target=f"flows[{i}].test_ids[{k}]",
                    ))
                else:
                    try:
                        t_bytes = bounded_read_bytes(tresolved, MAX_FILE_BYTES, tracker, f"flows[{i}].test_ids[{k}]")
                        t_code = t_bytes.decode("utf-8")
                        clean_code = _strip_comments_and_strings(t_code)
                        if tpath.endswith("_test.dart"):
                            if not re.search(r'\b(test|testWidgets)\s*\(', clean_code):
                                drift_errs.append(ValidationError(
                                    code="test.empty_or_no_tests",
                                    message="Referenced test file contains no test declarations",
                                    target=f"flows[{i}].test_ids[{k}]",
                                ))
                        elif tpath.endswith(".py"):
                            if not re.search(r'\b(def\s+test_|class\s+Test|unittest\.TestCase)\b', clean_code):
                                drift_errs.append(ValidationError(
                                    code="test.empty_or_no_tests",
                                    message="Referenced test file contains no test declarations",
                                    target=f"flows[{i}].test_ids[{k}]",
                                ))
                    except BudgetExceededError as be:
                        schema_errs.append(ValidationError(
                            code="test.file_too_large" if be.reason == "file_too_large" else "budget.aggregate_exceeded",
                            message="Test file exceeds maximum size limit",
                            target=f"flows[{i}].test_ids[{k}]",
                        ))
                    except Exception:
                        schema_errs.append(ValidationError(
                            code="test.read_error",
                            message="Failed reading referenced test file",
                            target=f"flows[{i}].test_ids[{k}]",
                        ))

    missing_coverage = REQUIRED_COVERAGE_IDS - covered_domains
    if missing_coverage:
        for cid in sorted(missing_coverage):
            drift_errs.append(ValidationError(
                code="coverage.domain_missing",
                message="Required coverage domain is not covered by any flow",
                target=cid,
            ))

    # 3. Platform backup configuration check (XML, Plist, and Gradle inspection)
    manifest_path = _resolve_contained_path(repo_root, "android/app/src/main/AndroidManifest.xml")
    if manifest_path is None or not manifest_path.is_file():
        schema_errs.append(ValidationError(
            code="backup.manifest_missing",
            message="AndroidManifest.xml is missing from expected path",
            target="android/app/src/main/AndroidManifest.xml",
        ))
    else:
        try:
            m_bytes = bounded_read_bytes(
                manifest_path, MAX_FILE_BYTES, tracker, "android/app/src/main/AndroidManifest.xml"
            )
            m_tree = ET.fromstring(m_bytes.decode("utf-8"))
            app_elems = m_tree.findall("application")
            if not app_elems:
                drift_errs.append(ValidationError(
                    code="backup.manifest_invalid",
                    message="AndroidManifest.xml has no <application> element",
                    target="android/app/src/main/AndroidManifest.xml",
                ))
            else:
                app_elem = app_elems[0]
                android_ns = "{http://schemas.android.com/apk/res/android}"
                raw_allow = app_elem.attrib.get(f"{android_ns}allowBackup", app_elem.attrib.get("android:allowBackup"))
                if raw_allow is not None:
                    norm_allow = raw_allow.strip().lower()
                    if norm_allow not in ("true", "false"):
                        drift_errs.append(ValidationError(
                            code="backup.manifest_setting_drift",
                            message="AndroidManifest android:allowBackup contains invalid non-boolean value",
                            target="android/app/src/main/AndroidManifest.xml",
                        ))
                    elif norm_allow == "false":
                        drift_errs.append(ValidationError(
                            code="backup.manifest_setting_drift",
                            message="AndroidManifest explicitly disables allowBackup, contradicting policy facts",
                            target="android/app/src/main/AndroidManifest.xml",
                        ))
        except BudgetExceededError as be:
            schema_errs.append(ValidationError(
                code="backup.manifest_too_large" if be.reason == "file_too_large" else "budget.aggregate_exceeded",
                message="AndroidManifest.xml exceeds maximum size limit",
                target="android/app/src/main/AndroidManifest.xml",
            ))
        except UnicodeDecodeError:
            schema_errs.append(ValidationError(
                code="backup.manifest_invalid_utf8",
                message="AndroidManifest.xml is not valid UTF-8",
                target="android/app/src/main/AndroidManifest.xml",
            ))
        except ET.ParseError:
            schema_errs.append(ValidationError(
                code="backup.manifest_malformed_xml",
                message="AndroidManifest.xml is malformed XML",
                target="android/app/src/main/AndroidManifest.xml",
            ))

    gradle_path = _resolve_contained_path(repo_root, "android/app/build.gradle.kts")
    if gradle_path is None or not gradle_path.is_file():
        schema_errs.append(ValidationError(
            code="backup.gradle_missing",
            message="android/app/build.gradle.kts is missing from expected path",
            target="android/app/build.gradle.kts",
        ))
    else:
        try:
            g_bytes = bounded_read_bytes(gradle_path, MAX_FILE_BYTES, tracker, "android/app/build.gradle.kts")
            g_text = g_bytes.decode("utf-8")
            clean_gradle = re.sub(r'//.*', '', g_text)
            clean_gradle = re.sub(r'/\*.*?\*/', '', clean_gradle, flags=re.DOTALL)
            app_ids = re.findall(r'^\s*applicationId\s*=\s*["\']([^"\']+)["\']', clean_gradle, re.MULTILINE)
            if not app_ids or any(aid != "com.cbstudio.telltale" for aid in app_ids):
                drift_errs.append(ValidationError(
                    code="backup.gradle_application_id_mismatch",
                    message="android/app/build.gradle.kts applicationId differs from com.cbstudio.telltale",
                    target="android/app/build.gradle.kts",
                ))
        except BudgetExceededError as be:
            schema_errs.append(ValidationError(
                code="backup.gradle_too_large" if be.reason == "file_too_large" else "budget.aggregate_exceeded",
                message="android/app/build.gradle.kts exceeds maximum size limit",
                target="android/app/build.gradle.kts",
            ))
        except UnicodeDecodeError:
            schema_errs.append(ValidationError(
                code="backup.gradle_invalid_utf8",
                message="android/app/build.gradle.kts contains invalid UTF-8 bytes",
                target="android/app/build.gradle.kts",
            ))
        except Exception:
            schema_errs.append(ValidationError(
                code="backup.gradle_read_error",
                message="Failed reading android/app/build.gradle.kts",
                target="android/app/build.gradle.kts",
            ))

    ios_plist_path = _resolve_contained_path(repo_root, "ios/Runner/Info.plist")
    if ios_plist_path is None or not ios_plist_path.is_file():
        schema_errs.append(ValidationError(
            code="backup.ios_plist_missing",
            message="ios/Runner/Info.plist is missing from expected path",
            target="ios/Runner/Info.plist",
        ))
    else:
        try:
            plist_bytes = bounded_read_bytes(ios_plist_path, MAX_FILE_BYTES, tracker, "ios/Runner/Info.plist")
            plist_data = plistlib.loads(plist_bytes)
            if plist_data.get("CFBundleDisplayName") != "Telltale":
                drift_errs.append(ValidationError(
                    code="backup.ios_bundle_name_mismatch",
                    message="iOS Info.plist CFBundleDisplayName is not Telltale",
                    target="ios/Runner/Info.plist",
                ))
            for desc_key in (
                "NSBluetoothAlwaysUsageDescription",
                "NSBluetoothPeripheralUsageDescription",
                "NSLocalNetworkUsageDescription",
            ):
                if not plist_data.get(desc_key):
                    drift_errs.append(ValidationError(
                        code="backup.ios_usage_description_missing",
                        message=f"iOS Info.plist missing {desc_key}",
                        target="ios/Runner/Info.plist",
                    ))
            for icloud_key in (
                "NSUbiquitousContainers",
                "com.apple.developer.ubiquity-container-identifiers",
                "com.apple.developer.icloud-container-identifiers",
            ):
                if icloud_key in plist_data:
                    drift_errs.append(ValidationError(
                        code="backup.ios_icloud_key_detected",
                        message="iOS Info.plist declares forbidden iCloud container key",
                        target="ios/Runner/Info.plist",
                    ))
        except BudgetExceededError as be:
            schema_errs.append(ValidationError(
                code="backup.plist_too_large" if be.reason == "file_too_large" else "budget.aggregate_exceeded",
                message="iOS Info.plist exceeds maximum size limit",
                target="ios/Runner/Info.plist",
            ))
        except Exception:
            schema_errs.append(ValidationError(
                code="backup.ios_plist_invalid",
                message="Failed parsing iOS Info.plist",
                target="ios/Runner/Info.plist",
            ))

    macos_ent_path = _resolve_contained_path(repo_root, "macos/Runner/Release.entitlements")
    if macos_ent_path is None or not macos_ent_path.is_file():
        schema_errs.append(ValidationError(
            code="backup.macos_entitlements_missing",
            message="macos/Runner/Release.entitlements is missing from expected path",
            target="macos/Runner/Release.entitlements",
        ))
    else:
        try:
            ent_bytes = bounded_read_bytes(macos_ent_path, MAX_FILE_BYTES, tracker, "macos/Runner/Release.entitlements")
            ent_data = plistlib.loads(ent_bytes)
            if ent_data.get("com.apple.security.app-sandbox") is not True:
                drift_errs.append(ValidationError(
                    code="backup.macos_sandbox_disabled",
                    message="macOS Release.entitlements does not enable App Sandbox",
                    target="macos/Runner/Release.entitlements",
                ))
            for k in ent_data.keys():
                if "icloud" in k.lower() or "ubiquity" in k.lower():
                    drift_errs.append(ValidationError(
                        code="backup.macos_icloud_detected",
                        message="macOS Release.entitlements contains forbidden iCloud container key",
                        target="macos/Runner/Release.entitlements",
                    ))
        except BudgetExceededError as be:
            schema_errs.append(ValidationError(
                code="backup.entitlements_too_large" if be.reason == "file_too_large" else "budget.aggregate_exceeded",
                message="macOS Release.entitlements exceeds maximum size limit",
                target="macos/Runner/Release.entitlements",
            ))
        except Exception:
            schema_errs.append(ValidationError(
                code="backup.macos_entitlements_invalid",
                message="Failed parsing macOS Release.entitlements",
                target="macos/Runner/Release.entitlements",
            ))

    # 4. Policy document parity and visible clause extraction check
    claim_parity_rules = data.get("claim_parity_rules", {})

    for doc_idx, pdoc in enumerate(policy_docs):
        presolved = _resolve_contained_path(repo_root, pdoc)
        if presolved is None:
            schema_errs.append(ValidationError(
                code="path.traversal_or_escape",
                message="Policy document path escapes repository root",
                target=f"policy_documents[{doc_idx}]",
            ))
            continue
        if not presolved.is_file():
            drift_errs.append(ValidationError(
                code="policy.document_missing",
                message="Declared policy document missing from repository",
                target=pdoc if pdoc in REQUIRED_POLICY_DOCUMENTS else f"policy_documents[{doc_idx}]",
            ))
            continue

        try:
            raw_doc_bytes = bounded_read_bytes(
                presolved, MAX_FILE_BYTES, tracker, f"policy_documents[{doc_idx}]"
            )
            ptext = raw_doc_bytes.decode("utf-8")
        except BudgetExceededError as be:
            schema_errs.append(ValidationError(
                code="policy.file_too_large" if be.reason == "file_too_large" else "budget.aggregate_exceeded",
                message="Policy document file exceeds size limit",
                target=f"policy_documents[{doc_idx}]",
            ))
            continue
        except UnicodeDecodeError:
            schema_errs.append(ValidationError(
                code="policy.invalid_utf8",
                message="Policy document must be strictly valid UTF-8",
                target=f"policy_documents[{doc_idx}]",
            ))
            continue
        except Exception:
            schema_errs.append(ValidationError(
                code="policy.read_error",
                message="Failed to read policy document",
                target=f"policy_documents[{doc_idx}]",
            ))
            continue

        # Check global contradictory phrases across the entire policy document
        ptext_lower = ptext.lower()
        for phrase in GLOBAL_CONTRADICTORY_PHRASES:
            if phrase.lower() in ptext_lower:
                drift_errs.append(ValidationError(
                    code="policy.clause_contradiction",
                    message="Policy document contains contradictory phrase regarding collection or backup",
                    target=f"policy_documents[{doc_idx}]",
                ))
                break

        # Extract language sections
        sections: dict[str, str] = {}
        if pdoc.endswith(".html"):
            found_cids = set(re.findall(r'data-claim-id=["\']([^"\']+)["\']', ptext))
            unknown_claims = sorted(found_cids - REQUIRED_CLAIM_IDS)
            if unknown_claims:
                for idx_uc in range(len(unknown_claims)):
                    drift_errs.append(ValidationError(
                        code="policy.unknown_claim_id",
                        message="HTML policy contains unknown claim id",
                        target=f"policy_documents[{doc_idx}]:unknown_claim[{idx_uc}]",
                    ))

            # Strip ONLY approved claim containers
            no_claims = ptext
            for cid in REQUIRED_CLAIM_IDS:
                pattern = re.compile(rf'<div\b[^>]*\bdata-claim-id=["\']{cid}["\'][^>]*>[\s\S]*?</div>', re.IGNORECASE)
                no_claims = pattern.sub('', no_claims)

            # Check for unapproved paragraph content outside registered claims
            p_matches = re.findall(r'<p\b[^>]*>(.*?)</p>', no_claims, flags=re.DOTALL | re.IGNORECASE)
            for p_body in p_matches:
                norm_p = normalize_clause(p_body)
                if not norm_p:
                    continue
                p_hash = hashlib.sha256(norm_p.encode("utf-8")).hexdigest()
                if p_hash not in APPROVED_HTML_BOILERPLATE_HASHES:
                    drift_errs.append(ValidationError(
                        code="policy.clause_contradiction",
                        message="HTML policy contains unapproved paragraph content outside registered claims",
                        target=f"policy_documents[{doc_idx}]",
                    ))
                    break

            # Strip style and script for text-surface verification
            clean_no_claims = re.sub(r'<(script|style)\b[^>]*>.*?</\1>', '', no_claims, flags=re.DOTALL | re.IGNORECASE)

            # Check for unapproved div containers outside registered claims (N05)
            if re.search(r'<div\b', clean_no_claims, re.IGNORECASE):
                drift_errs.append(ValidationError(
                    code="policy.clause_contradiction",
                    message="HTML policy contains unapproved div container outside registered claims",
                    target=f"policy_documents[{doc_idx}]",
                ))

            # Check every text chunk outside tags against approved text chunks
            text_chunks = [normalize_clause(c) for c in re.split(r'<[^>]+>', clean_no_claims)]
            for chunk in text_chunks:
                if not chunk or chunk == "—":
                    continue
                c_hash = hashlib.sha256(chunk.encode("utf-8")).hexdigest()
                if c_hash not in APPROVED_HTML_TEXT_CHUNK_HASHES:
                    drift_errs.append(ValidationError(
                        code="policy.clause_contradiction",
                        message="HTML policy contains unapproved text outside registered claims",
                        target=f"policy_documents[{doc_idx}]",
                    ))
                    break

            # Check for forbidden script or template or hiding markup in the entire HTML
            if "<script" in ptext.lower():
                drift_errs.append(ValidationError(
                    code="policy.disallowed_markup",
                    message="HTML policy document contains forbidden script elements",
                    target=f"policy_documents[{doc_idx}]",
                ))
            if re.search(r'<template\b', ptext, re.IGNORECASE):
                drift_errs.append(ValidationError(
                    code="policy.disallowed_markup",
                    message="HTML policy document contains forbidden or inert <template> elements",
                    target=f"policy_documents[{doc_idx}]",
                ))
            if re.search(r'<noscript\b', ptext, re.IGNORECASE):
                drift_errs.append(ValidationError(
                    code="policy.disallowed_markup",
                    message="HTML policy document contains forbidden <noscript> elements",
                    target=f"policy_documents[{doc_idx}]",
                ))
            if re.search(r'<style\b[^>]*>[\s\S]*?(?:display:\s*none|visibility:\s*hidden|opacity:\s*0)[\s\S]*?</style>', ptext, re.IGNORECASE):
                drift_errs.append(ValidationError(
                    code="policy.clause_hidden",
                    message="HTML policy contains style block hiding content",
                    target=f"policy_documents[{doc_idx}]",
                ))
            if re.search(r'<(?:html|body|main|div|section)\b[^>]*(?:\bhidden\b|\baria-hidden=["\']true["\']|style=["\'][^"\']*(?:display:\s*none|visibility:\s*hidden)[^"\']*)[^>]*>', ptext, re.IGNORECASE):
                drift_errs.append(ValidationError(
                    code="policy.clause_hidden",
                    message="HTML policy contains structural container with hidden attribute",
                    target=f"policy_documents[{doc_idx}]",
                ))

            zh_match = re.search(r'<section\b([^>]*\bid=["\']zh-policy["\'][^>]*)>(.*?)</section>', ptext, re.DOTALL | re.IGNORECASE)
            en_match = re.search(r'<section\b([^>]*\bid=["\']en-policy["\'][^>]*)>(.*?)</section>', ptext, re.DOTALL | re.IGNORECASE)
            if not zh_match or not en_match:
                drift_errs.append(ValidationError(
                    code="policy.section_missing",
                    message="HTML policy missing zh-policy or en-policy section",
                    target=f"policy_documents[{doc_idx}]",
                ))
                continue

            sections["zh"] = zh_match.group(2)
            sections["en"] = en_match.group(2)
        else:
            found_md_claims = set(re.findall(r'<!--\s*claim:\s*([^\s]+)\s*-->', ptext))
            unknown_md = sorted(found_md_claims - REQUIRED_CLAIM_IDS)
            if unknown_md:
                for idx_uc in range(len(unknown_md)):
                    drift_errs.append(ValidationError(
                        code="policy.unknown_claim_id",
                        message="Markdown policy contains unknown claim id",
                        target=f"policy_documents[{doc_idx}]:unknown_claim[{idx_uc}]",
                    ))

            # Strip approved claims
            no_claims_md = ptext
            for cid in REQUIRED_CLAIM_IDS:
                no_claims_md = re.sub(rf'<!--\s*claim:\s*{cid}\s*-->[\s\S]*?(?=\n<!--\s*claim:|\n##\s+|\Z)', '', no_claims_md)

            # Check headings outside claims (N06)
            for hl in re.findall(r'(?m)^#{1,6}\s+.*$', no_claims_md):
                norm_hl = normalize_clause(hl)
                if norm_hl not in APPROVED_MD_HEADING_LINES:
                    drift_errs.append(ValidationError(
                        code="policy.clause_contradiction",
                        message="Markdown policy contains unapproved heading outside registered claims",
                        target=f"policy_documents[{doc_idx}]",
                    ))
                    break

            # Separate non-heading lines and check paragraphs outside claims (N06)
            body_lines = []
            for line in no_claims_md.split('\n'):
                sline = line.strip()
                if re.match(r'^#{1,6}(\s|$)', sline) or re.match(r'^---+\s*$', sline):
                    continue
                body_lines.append(line)

            clean_body_md = '\n'.join(body_lines)
            md_paras = [normalize_clause(p) for p in clean_body_md.split('\n\n')]
            for mp in md_paras:
                if not mp:
                    continue
                mp_hash = hashlib.sha256(mp.encode("utf-8")).hexdigest()
                if mp_hash not in APPROVED_MD_BOILERPLATE_HASHES:
                    drift_errs.append(ValidationError(
                        code="policy.clause_contradiction",
                        message="Markdown policy contains unapproved paragraph content outside registered claims",
                        target=f"policy_documents[{doc_idx}]",
                    ))
                    break

            parts = re.split(r'\n---\n(?=\s*#\s+Telltale Privacy Policy)', ptext)
            if len(parts) >= 2:
                sections["zh"] = parts[0]
                sections["en"] = parts[1]
            else:
                drift_errs.append(ValidationError(
                    code="policy.section_missing",
                    message="Markdown policy missing distinct zh and en language partitions",
                    target=f"policy_documents[{doc_idx}]",
                ))
                continue

        for lang, sec_text in sections.items():
            for cid in sorted(REQUIRED_CLAIM_IDS):
                # Count anchors on this surface
                if pdoc.endswith(".html"):
                    attr_anchor = f'data-claim-id="{cid}"'
                    attr_anchor_sq = f"data-claim-id='{cid}'"
                    comment_anchor = f'<!-- claim: {cid} -->'
                    attr_count = sec_text.count(attr_anchor) + sec_text.count(attr_anchor_sq)
                    comment_count = sec_text.count(comment_anchor)
                    total_anchors = max(attr_count, comment_count)
                else:
                    comment_anchor = f'<!-- claim: {cid} -->'
                    total_anchors = sec_text.count(comment_anchor)

                if total_anchors == 0:
                    drift_errs.append(ValidationError(
                        code="policy.claim_missing",
                        message="Claim anchor is missing from policy section",
                        target=f"policy_documents[{doc_idx}]:{lang}:{cid}",
                    ))
                    continue
                elif total_anchors > 1:
                    drift_errs.append(ValidationError(
                        code="policy.duplicate_claim_anchor",
                        message="Duplicate claim anchor found in single policy section",
                        target=f"policy_documents[{doc_idx}]:{lang}:{cid}",
                    ))
                    continue

                # Extract clause text block
                if pdoc.endswith(".html"):
                    clause_raw = extract_html_div_by_claim_id(sec_text, cid)
                else:
                    clause_raw = extract_md_clause(sec_text, cid)

                # Check if hidden attribute exists anywhere inside clause
                if re.search(r'\b(hidden|aria-hidden="true")\b', clause_raw) or re.search(r'display:\s*none|visibility:\s*hidden', clause_raw):
                    drift_errs.append(ValidationError(
                        code="policy.clause_hidden",
                        message="Policy clause content is hidden from view",
                        target=f"policy_documents[{doc_idx}]:{lang}:{cid}",
                    ))
                    continue

                visible_text = normalize_clause(clause_raw)
                if len(visible_text) < 20:
                    drift_errs.append(ValidationError(
                        code="policy.clause_empty",
                        message="Visible text for policy claim is empty or missing",
                        target=f"policy_documents[{doc_idx}]:{lang}:{cid}",
                    ))
                    continue

                # Parity rules verification
                rules = claim_parity_rules.get(cid, {})
                canonical_digest_map = rules.get("canonical_digest", {})
                expected_digest = canonical_digest_map.get(lang)
                actual_digest = hashlib.sha256(visible_text.encode("utf-8")).hexdigest()

                if expected_digest and actual_digest != expected_digest:
                    drift_errs.append(ValidationError(
                        code="policy.clause_drift",
                        message="Policy visible text digest differs from canonical contract digest",
                        target=f"policy_documents[{doc_idx}]:{lang}:{cid}",
                    ))

                # Check forbidden terms
                forbidden_list = rules.get("forbidden_terms", {}).get(lang, [])
                for fb in forbidden_list:
                    if fb.lower() in visible_text.lower():
                        drift_errs.append(ValidationError(
                            code="policy.clause_contradiction",
                            message="Policy visible text contains contradictory forbidden term",
                            target=f"policy_documents[{doc_idx}]:{lang}:{cid}",
                        ))
                        break
                    elif fb.lower() in sec_text.lower():
                        drift_errs.append(ValidationError(
                            code="policy.clause_contradiction",
                            message="Policy section contains contradictory forbidden term outside approved claim block",
                            target=f"policy_documents[{doc_idx}]:{lang}:{cid}",
                        ))
                        break

                # Check required keywords
                required_list = rules.get("required_keywords", {}).get(lang, [])
                for req in required_list:
                    if req.lower() not in visible_text.lower():
                        drift_errs.append(ValidationError(
                            code="policy.clause_drift",
                            message="Policy visible text is missing required canonical keyword",
                            target=f"policy_documents[{doc_idx}]:{lang}:{cid}",
                        ))
                        break

    return schema_errs, drift_errs


def run_validator(repo_root_str: str, contract_path_str: str) -> tuple[int, dict[str, Any]]:
    tracker = BudgetTracker()
    try:
        repo_root = Path(repo_root_str).resolve()
        if not repo_root.is_dir():
            return 2, {
                "status": "error",
                "exit_code": 2,
                "summary": {"errors_count": 1},
                "errors": [{
                    "code": "path.invalid_repo_root",
                    "message": "Invalid repository root directory",
                    "target": "repo_root",
                }],
            }
    except Exception:
        return 2, {
            "status": "error",
            "exit_code": 2,
            "summary": {"errors_count": 1},
            "errors": [{
                "code": "path.invalid_repo_root",
                "message": "Invalid repository root directory",
                "target": "repo_root",
            }],
        }

    raw_contract = Path(contract_path_str)
    if not raw_contract.is_absolute():
        raw_contract = repo_root / raw_contract

    # Path containment check for contract file itself (safeguards against escaping symlinks)
    try:
        resolved_contract = raw_contract.resolve()
        resolved_contract.relative_to(repo_root)
    except (ValueError, RuntimeError, OSError):
        return 2, {
            "status": "error",
            "exit_code": 2,
            "summary": {"errors_count": 1},
            "errors": [{
                "code": "path.traversal_or_escape",
                "message": "Contract path escapes repository root",
                "target": "contract_path",
            }],
        }

    if not resolved_contract.is_file():
        return 2, {
            "status": "error",
            "exit_code": 2,
            "summary": {"errors_count": 1},
            "errors": [{
                "code": "contract.file_not_found",
                "message": "Contract file not found",
                "target": "contract_path",
            }],
        }

    # Bounded size check before read_bytes
    try:
        raw_bytes = bounded_read_bytes(
            resolved_contract, MAX_CONTRACT_BYTES, tracker, "contract_path"
        )
    except BudgetExceededError as be:
        return 2, {
            "status": "error",
            "exit_code": 2,
            "summary": {"errors_count": 1},
            "errors": [{
                "code": "contract.file_too_large" if be.reason == "file_too_large" else "budget.aggregate_exceeded",
                "message": f"Contract size exceeds maximum limit of {MAX_CONTRACT_BYTES} bytes",
                "target": "contract_path",
            }],
        }
    except Exception:
        return 2, {
            "status": "error",
            "exit_code": 2,
            "summary": {"errors_count": 1},
            "errors": [{
                "code": "contract.read_failed",
                "message": "Failed to read contract file",
                "target": "contract_path",
            }],
        }

    try:
        text = raw_bytes.decode("utf-8")
    except UnicodeDecodeError:
        return 2, {
            "status": "error",
            "exit_code": 2,
            "summary": {"errors_count": 1},
            "errors": [{
                "code": "contract.invalid_utf8",
                "message": "Contract file must be strictly valid UTF-8",
                "target": "contract_path",
            }],
        }

    try:
        data = json.loads(text, object_pairs_hook=_dict_raise_on_duplicates)
    except DuplicateKeyError:
        return 2, {
            "status": "error",
            "exit_code": 2,
            "summary": {"errors_count": 1},
            "errors": [{
                "code": "json.duplicate_key",
                "message": "Duplicate JSON key detected in object",
                "target": "keys",
            }],
        }
    except json.JSONDecodeError as jerr:
        return 2, {
            "status": "error",
            "exit_code": 2,
            "summary": {"errors_count": 1},
            "errors": [{
                "code": "json.decode_error",
                "message": f"Malformed JSON syntax at line {jerr.lineno} col {jerr.colno}",
                "target": "syntax",
            }],
        }
    except Exception:
        return 2, {
            "status": "error",
            "exit_code": 2,
            "summary": {"errors_count": 1},
            "errors": [{
                "code": "json.decode_error",
                "message": "Malformed JSON structure",
                "target": "syntax",
            }],
        }

    try:
        schema_errs, drift_errs = validate_contract_data(data, repo_root, tracker=tracker)
    except Exception:
        return 2, {
            "status": "error",
            "exit_code": 2,
            "summary": {"errors_count": 1},
            "errors": [{
                "code": "input.malformed_or_error",
                "message": "Input validation encountered a data structure error",
                "target": "root",
            }],
        }

    if schema_errs:
        return 2, {
            "status": "error",
            "exit_code": 2,
            "summary": {
                "schema_errors": len(schema_errs),
                "drift_errors": len(drift_errs),
            },
            "errors": [asdict(e) for e in schema_errs],
        }

    if drift_errs:
        return 1, {
            "status": "fail",
            "exit_code": 1,
            "summary": {
                "schema_errors": 0,
                "drift_errors": len(drift_errs),
            },
            "errors": [asdict(e) for e in drift_errs],
        }

    flows_count = len(data.get("flows", []))
    claims_count = len(data.get("claims", {}))
    return 0, {
        "status": "pass",
        "exit_code": 0,
        "summary": {
            "flows_count": flows_count,
            "claims_count": claims_count,
            "covered_domains": len(REQUIRED_COVERAGE_IDS),
            "errors_count": 0,
        },
        "errors": [],
    }


def main() -> None:
    parser = SanitizedArgumentParser(
        description="Fail-closed privacy & data flow contract validator (Issue #11, WS-07 Slice 4)."
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Repository root directory (default: current directory).",
    )
    parser.add_argument(
        "--contract",
        default="docs/privacy/data-flow-inventory.json",
        help="Path to data-flow-inventory.json relative to repo root.",
    )
    parser.add_argument(
        "--output",
        choices=["text", "json"],
        default="text",
        help="Report output format (default: text).",
    )

    args = parser.parse_args()
    code, result = run_validator(args.repo_root, args.contract)

    if args.output == "json":
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        status_str = result["status"].upper()
        print(f"[{status_str}] Privacy Contract Validation (Exit {code})")
        summary = result.get("summary", {})
        for k, v in summary.items():
            print(f"  - {k}: {v}")
        errors = result.get("errors", [])
        if errors:
            print("\nFindings / Errors:")
            for err in errors:
                target_str = f" [{err['target']}]" if err.get("target") else ""
                print(f"  * {err['code']}{target_str}: {err['message']}")

    sys.exit(code)


if __name__ == "__main__":
    main()
