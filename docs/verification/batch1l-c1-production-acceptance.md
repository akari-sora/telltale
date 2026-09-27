# Batch 1L-C1a Verification Record: Production-Root Journeys & Fail-Closed Acceptance Receipts

**Scope**: Issue #40 (Batch 1L-C1a: Production-root journeys and fail-closed acceptance receipts, coordinating #34)  
**MR**: `test(i18n): deliver Batch 1L-C1a-R2b production root proof and accessibility (Refs #40, #34)`  
**Branch**: `test/i18n-c1a-r2b-production-proof`  
**Exit Level**: `C1A_SOFTWARE_ACCEPTED` (Does not imply `ISSUE40_COMPLETE`, `NATIVE_QUALIFIED`, or `RELEASED`)  
**Status**: 100% PASS (0 analyzer warnings, 12/12 required journey/accessibility cases passing, 53/53 runner mutation and verifier tests passing, fail-closed receipts generated)

---

## 1. Acceptance Criteria Mapping (AC40-1 ~ AC40-5)

| Criterion | Specification | Layer & Implementation Mapping | Test Evidence |
| :--- | :--- | :--- | :--- |
| **AC40-1** | **Criterion -> Case -> Responsible Layer Mapping**: Every criterion maps to qualified test cases with explicit layer attribution (`software-root` vs `host-render`); unrun native obligations are explicitly marked `NOT_RUN` and never claimed as software passes. | `tool/i18n_verify/production_acceptance_manifest.json`, `test/l10n/l06_production_root_journey_test.dart`, `test/l10n/l06_production_accessibility_test.dart` | **C01~C08** verified at `software-root`; **C09.1~C09.4** verified at `host-render`; Native residuals R01~R03 explicitly tracked as `NOT_RUN` with hand-off owners. |
| **AC40-2** | **Negative Control & Mutation Suite**: Fail-closed verifier detects omissions, failures, skips, malformed JSON, nonzero exits, corrupt PNGs, and profile mismatches. | `tool/ci/run_l10n_required.py`, `test/tool/test_l10n_required.py` | **M01~M07 & G-Probes (53 tests)**: Omission (M01), test failure (M02), skip (M03), truncated JSON (M04), nonzero runner exit (M05), missing PNG artifact (M06), baseline control (M07), corrupt/truncated IDAT zlib, Adam7/PLTE violations, unknown profile fail-closed. |
| **AC40-3** | **Dual en/zh Real Route Coverage, Failure/Recovery & Zero Side Effects**: Production-root widget tree journeys in English and Traditional Chinese without shortcuts, verifying fault handling, clean recovery, and zero side effects. | `lib/ui/screens/connect/connect_screen.dart`, `DashboardScreen`, `TelemetrySessionsScreen`, `TelemetrySessionDetailScreen`, `SettingsScreen`, `LanguageSwitchGuard` | **C01~C08**: Unconnected language switch (C01); Demo connect, live PIDs, read-only DTC (C02); Recording, stop, history tile, exact session replay in en/zh (C03); Real UI CSV/JSON export byte-identical across locales (C04); Real UI disconnect with terminal transport (C05); Permission/transport refusal rendering (C06); Language switch guard during recording/export (C07); Late result route currentness (C08). |
| **AC40-4** | **Complete Provenance & Verifier Audit Trail**: Deterministic receipt records Git commit SHA, tree SHA, Flutter SDK version, run ID, child exit code, execution timestamps, and SHA-256 digests of all reports and artifacts. | `tool/ci/run_l10n_required.py`, `docs/verification/evidence/l10n_production_receipt.json` | Verifier captures `sourceSha`, `treeSha`, `sdkInfo`, `command.json`, `child.exit`, `child.stdout.jsonl`, `child.stderr.txt`, `case-observations.json`, `artifacts.sha256`, and generates cryptographically verifiable receipt. |
| **AC40-5** | **Reviewer Artifact Inspection & Frozen Canonical Contracts**: Human/reviewer inspection of accessibility visual artifacts and byte-identical canonical telemetry exports across locales. | `build/reports/l10n_accessibility/*.png`, `CapturingAppSharePlatform` | **C04 & C09.1~C09.4**: Exported CSV and JSON byte streams are identical between English and Traditional Chinese; captured PNGs at 320x640 and 568x320 at 2.0x scale visually verified with touch targets >= 48x48. |

---

## 2. Test Matrix: `test/l10n/l06_production_root_journey_test.dart` & `l06_production_accessibility_test.dart`

| ID | Scenario | Verified Behavior | Layer | Status |
| :--- | :--- | :--- | :--- | :--- |
| **C01** | Unconnected Language Entry | Reachable before connection; bidirectional en/zh switch with 0 extra BLE/network calls | `software-root` | **PASS** |
| **C02** | Demo to Dashboard / PID / DTC | Demo connects, session connected, live PIDs render, DTC inspection is read-only | `software-root` | **PASS** |
| **C03** | Recording to History to Replay | Real telemetry values recorded, settled to completed, tile opens exact session replay | `software-root` | **PASS** |
| **C04** | Export / Cancel / Reopen | Real UI export CSV & JSON, canonical byte-identical contents, gate settles, reopen same session | `software-root` | **PASS** |
| **C05** | Real UI Disconnect | Actually tap Disconnect button; session terminates; routes to Connect; 0 subsequent dispatch | `software-root` | **PASS** |
| **C06** | Permission & Transport Failure | Refusal reasons rendered; stored failure does not re-prompt Bluetooth on locale change | `software-root` | **PASS** |
| **C07** | Formal Language Switch Guard | Recording and artifact-busy states block switch; unblocked when idle | `software-root` | **PASS** |
| **C08** | Late Result & Route Currentness | Controlled typed failure SnackBar positive control; late result suppressed on covered route | `software-root` | **PASS** |
| **C09.1** | 320x640 Portrait @ 2.0x Scale | Zero RenderFlex overflows in EN & ZH; touch targets >= 48x48; host PNG captured | `host-render` | **PASS** |
| **C09.2** | 568x320 Landscape @ 2.0x Scale | Zero RenderFlex overflows in EN & ZH; host PNG captured | `host-render` | **PASS** |
| **C09.3** | Dialog Kept Open Across Rotation | Language modal bottom sheet kept open across portrait -> landscape rotation & locale switch | `host-render` | **PASS** |
| **C09.4** | Semantics Inspection | Key interactive controls provide valid accessibility labels and tap actions | `host-render` | **PASS** |

---

## 3. Negative Controls & Mutation Matrix (M01 ~ M07, Verifier Stress Probes)

Verified via `test/tool/test_l10n_required.py` (53 tests in suite):

| Mutation ID | Controlled Fault Injection | Expected Failure Mode | Observed Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **M01** | Omit required test case from report | `L10nRequiredError: Required cases missing from report` | Rejection | **PASS** |
| **M02** | Test case marked as `"result": "failure"` | `L10nRequiredError: Required cases failed` | Rejection | **PASS** |
| **M03** | Required test case marked as `"skipped": true` | `L10nRequiredError: Required cases were skipped` | Rejection | **PASS** |
| **M04** | Truncated or malformed report JSON | `L10nRequiredError: Report JSON guard rejected report` | Rejection | **PASS** |
| **M05** | Nonzero runner child exit code (`runner_exit = 1`) | `L10nRequiredError: Runner failed with nonzero exit code: 1` | Rejection | **PASS** |
| **M06** | Required artifact file missing on disk | `L10nRequiredError: Required artifact not found` | Rejection | **PASS** |
| **M07** | Baseline Control: Valid report + manifest + artifacts | Produces accepted structured receipt with SHA-256 digests | Acceptance | **PASS** |
| **G-Probes** | 46 verifier regression probes (G-SUITE, G-EVENT, G-CENSUS, G-MANIFEST, G-PNG, G-FAILURE, G-ARCHIVE, G-RUN, truncated zlib stream, extraneous zlib data, offline provenance preservation) | `L10nRequiredError` / `{"status": "REJECTED"}` | Rejection / Invalidation | **PASS** |

---

## 4. Native Residual Ledger

Per Batch 1L-C1a exit criteria, native and hardware-bound validations are tracked with explicit ownership and not claimed as software passes:

| Residual ID | Description | Layer | Status in C1a | Hand-off Owner |
| :--- | :--- | :--- | :--- | :--- |
| **R01_NATIVE_DEVICE_BLE** | Physical Bluetooth adapter scan, pairing & connection on mobile devices | `native-device` | `NOT_RUN` | Batch 1L-C1b (coordinating #24 platform integration) |
| **R02_NATIVE_OS_LOCALE_SYNC** | Android 13+ per-app language platform broadcast & lifecycle configuration sync | `native-platform` | `NOT_RUN` | Batch 1L-C1b / Issue #36 |
| **R03_PHYSICAL_WEAR_RENDER** | Physical circular wearable display render, rotary/crown input, ambient mode | `native-wear` | `NOT_RUN` | Issue #65 (Wear UI/rotary/ambient) & #91 (Wear BLE) & Issue #48 (Release Evidence) |

---

## 5. Verification Gate Integration

The scoped gate runner `python3 tool/ci/run_l10n_required.py` is integrated into `tool/ci/full_gate.sh`:
```bash
run_step l10n-required python3 tool/ci/run_l10n_required.py --evidence ci-artifacts/l10n-required/receipt.json
```
Receipts, test logs, and accessibility PNG artifacts are saved and verified under `build/reports/l10n_accessibility/` and `docs/verification/evidence/l10n_production_receipt.json`.
For acceptance hardening details, see [docs/verification/batch1l-c1a-r1-acceptance-integrity.md](file:///Users/iml1s/Documents/mine/apps/auto/torque/docs/verification/batch1l-c1a-r1-acceptance-integrity.md) and [docs/verification/batch1l-c1a-r2a-verifier-provenance.md](file:///Users/iml1s/Documents/mine/apps/auto/torque/docs/verification/batch1l-c1a-r2a-verifier-provenance.md).
