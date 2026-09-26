# Batch 1L-C1a-R2a Verification Record: Verifier Provenance & Atomic Archive

**Task ID**: `TELLTALE-1L-C1A-R2A-VERIFIER-PROVENANCE`  
**Scope**: Issue #40 (Batch 1L-C1a: Production-root journeys and fail-closed acceptance receipts, coordinating #34)  
**MR**: `fix(ci): close C1a verifier and evidence provenance gaps (Refs #40, #34)`  
**Branch**: `fix/i18n-c1a-r2a-verifier-provenance`  
**Base**: `5512d7dfc248115848d16da7f06892e296c17c70` (`main`)  
**Exit Level**: `C1A_R2A_VERIFIER_PROVENANCE_ACCEPTED`  
**Explicitly NOT Exit Level**: `C1A_SOFTWARE_ACCEPTED`, `ISSUE40_COMPLETE`, `NATIVE_QUALIFIED`, `RELEASED`  
**Status**: 100% PASS (35/35 Python verifier unit & negative regression tests passing, 12/12 required journey/accessibility cases passing, fail-closed receipts generated, 11-file evidence bundle verified)

---

## 1. Scope & Findings Disposition

This execution slice specifically resolves **R73-01** and **R73-04** plus documentation alignment. Residual software obligations under **R73-02** (C02~C08 journey behavioral evidence) and **R73-03** (collector forwarding negative controls & visual artifact acceptance) remain **OPEN / PENDING** and are explicitly deferred to **Batch 1L-C1a-R2b** (`test/i18n-c1a-r2b-production-proof`).

| Finding ID | Severity | Audit Finding | Hardened Resolution & Implementation | Status |
| :--- | :--- | :--- | :--- | :--- |
| **R73-01** | P1 | Verifier fail-open paths: missing suite fallback (`not t_suite`), test identity overwrites (`testStart` after terminal borrowing result), duplicate suite IDs, string booleans in `required`, unhandled unrelated failures. | Refactored `tool/ci/run_l10n_required.py`: enforced strict non-empty exact suite match (`t_suite == expected_norm_suite`), rejected duplicate `suiteID`s and duplicate `testStart` events, prohibited `testStart` for already-terminated tests, enforced strict boolean types for manifest `required` fields via `_strict_json_loads` (rejecting duplicate JSON keys and string booleans), and failed the run if ANY test in report failed. | **CLOSED** in R2a |
| **R73-04** | P1 | Best-effort archive copy after writing `ACCEPTED` receipt; child spawn failure outside wrapper left stale `ACCEPTED` receipt; receipts lacked full process execution context (source/tree SHA, SDK, run ID, argv, timestamps). | Refactored `run_l10n_required.py`: process execution context (source SHA, tree SHA, SDK machine info, unique run ID, timestamps, child exit) bound at runtime. Child process spawn wrapped in try/except to overwrite stale receipts with `status: "REJECTED"`, `executionStatus: "EXECUTION_FAIL"`. Full 11-file atomic evidence bundle written and verified *before* publishing `ACCEPTED` receipt; any archive error raises `L10nRequiredError` and records rejection. Real PNG chunk/CRC/IDAT decode validation implemented. | **CLOSED** in R2a |
| **R73-02** | P1 | C02~C08 journey evidence, true UI interaction, independent PID/DTC observations. | Preserved existing C01 real UI language switch and BLE platform seam. Detailed journey completions deferred to R2b. | **OPEN** (Assigned to C1a-R2b) |
| **R73-03** | P1 | Collector negative controls and visual PNG inspection. | Decodable PNG validation and 48x48 bounds preserved. Full collector failure injection and visual inspection deferred to R2b. | **OPEN** (Assigned to C1a-R2b) |
| **R73-05** | P1 | AC / case reconciliation and native owner precision. | Re-aligned native residual owners (#36/#91 for BLE, #36 for OS sync, #65/#48 for WearOS). Exit level bounded to `C1A_R2A_VERIFIER_PROVENANCE_ACCEPTED`. | **CLOSED** in R2a |

---

## 2. Hardened Verification State Machine

```
PRECHECK
→ NEW_RUN_CREATED / RUNNING recorded
→ CHILD_STARTED
→ CHILD_TERMINATED
→ STRICT_REPORT_VALIDATED
→ EXACT_CASES_AND_PROFILE_VALIDATED
→ ARTIFACTS_VALIDATED (Chunk, CRC, IDAT decompressed, dimensions)
→ ARCHIVE_COMPLETE (11-file atomic bundle verified)
→ EXECUTION_PASS
```

Any failure during precheck, spawn, child execution, report validation, or bundle archiving results in:
- `executionStatus = EXECUTION_FAIL`
- `status = REJECTED`
- Immediate overwrite of any existing receipt file
- Non-zero process exit code

---

## 3. Evidence Bundle Layout

Under `ci-artifacts/l10n-required/<run-id>/`:
1. `run-context.json`: Run identity, source SHA, tree SHA, SDK info, argv, timestamps, hashes.
2. `manifest.json`: Verified copy of production acceptance manifest.
3. `command.json`: Child command invocation and working directory.
4. `child.exit`: Exit code of the runner child process.
5. `child.stdout.jsonl`: Raw JSONL report stream from runner child.
6. `child.stderr.txt`: Raw stderr output (empty file created if zero stderr bytes).
7. `case-observations.json`: Observed test events, suites, IDs, and outcomes.
8. `artifacts/`: Decoded and verified test artifacts (e.g. accessibility PNGs).
9. `artifacts.sha256`: SHA-256 digests of all archived artifacts.
10. `attempt.json`: Attempt status and timing metadata.
11. `verification.json`: Execution pass verification summary.

Receipt output:
`ci-artifacts/l10n-required/receipt.json` and `docs/verification/evidence/l10n_production_receipt.json` link directly to the run identity and bundle directory.

---

## 4. Test Matrix & Regression Proof

Verified via `test/tool/test_l10n_required.py` (35 tests passing):
- **G-SUITE**: Missing suite path, empty suite path, undeclared suite ID in testStart, duplicate suite definition, boolean suite ID/reference.
- **G-EVENT**: Duplicate testStart, testStart after terminal outcome borrowing result, unclosed started tests, global error events.
- **G-CENSUS**: Unrelated test failures in report fail gate, 1-to-1 required test matching violations.
- **G-MANIFEST**: Duplicate JSON keys rejected, unsupported schemaVersion rejected, non-boolean string `required` rejected.
- **G-PNG**: Invalid PNG magic, magic bytes followed by arbitrary junk, chunk CRC32 check, IDAT decompression check.
- **G-FAILURE**: Runner binary spawn failure invalidates receipt and writes `REJECTED` / `EXECUTION_FAIL`.
- **G-ARCHIVE**: Bundle archive collision/error invalidates receipt and writes `REJECTED` / `EXECUTION_FAIL`. Successful runs create and verify all 11 bundle files.
- **M01 ~ M07**: Happy path control and standard mutation coverage (missing cases, failed cases, skipped cases, malformed JSON, nonzero exit, missing artifacts).
