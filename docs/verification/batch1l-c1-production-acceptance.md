# Batch 1L-C1a Verification Record: Production-Root Journeys & Fail-Closed Acceptance Receipts

**Scope**: Issue #40 (Batch 1L-C1a: Production-root journeys and fail-closed acceptance receipts, coordinating #34)  
**MR**: `test(i18n): verify production-root journeys and fail-closed acceptance receipts (Refs #40, #34)`  
**Branch**: `test/i18n-production-acceptance`  
**Exit Level**: `C1A_SOFTWARE_ACCEPTED` (Does not imply `ISSUE40_COMPLETE`, `NATIVE_QUALIFIED`, or `RELEASED`)  
**Status**: 100% PASS (0 analyzer warnings, 12/12 required journey/accessibility cases passing, 7/7 runner mutation tests passing, fail-closed receipts generated)

---

## 1. Acceptance Criteria Mapping (AC40-1 ~ AC40-5)

| Criterion | Specification | Layer & Implementation Mapping | Test Evidence |
| :--- | :--- | :--- | :--- |
| **AC40-1** | Real language choice reachable before connection without account/VIN/Demo/permissions; OS locale sync; formal language guard; accessibility at 320dp/2x text scale/landscape | `lib/ui/screens/connect/connect_screen.dart`, `LanguagePicker`, `AppLocalesPlatform`, `LanguageSwitchGuard` | **C01, C07, C09.1, C09.2, C09.3, C09.4**: Bidirectional en/zh switch with 0 extra requests; guard blocks during recording & artifact-busy; 320x640 portrait & 568x320 landscape at 2.0x scale with 0 RenderFlex overflow; touch targets >= 48x48; dialog-open orientation rotation verified. |
| **AC40-2** | Real Demo connect, session connected phase, live PIDs, read-only DTC; refusal reason & transport failure rendering without re-prompts | `ConnectScreen`, `DashboardScreen`, `DtcScreen`, `CountingBlePlatform` | **C02, C06**: Real Demo connect transitions session to connected; reads live PIDs; DTC inspection executes read-only (no clear/mode08); Bluetooth/Location refusal reasons rendered; stored failure does not re-trigger scans on locale change. |
| **AC40-3** | Telemetry recording, session completed, history tile click opens exact session replay; late result/route protection | `telemetryRecorderControllerProvider`, `telemetry_sessions_screen.dart`, `telemetry_session_detail_screen.dart` | **C03, C08**: Recording collects real telemetry frames (`valueCount > 0`); stop settles to completed; exact session opened in replay maintaining state; rapid route switches verify route currentness without stray snackbars. |
| **AC40-4** | Real UI export CSV & JSON, byte-identical canonical contents, gate settles, reopen same session | `TelemetrySessionActions`, `AppShareCoordinator`, `ArtifactOperationGate` | **C04**: Real UI export to CSV and JSON via isolate-backed streams; byte-identical contents verified; gate transitions to idle; reopening same session retains integrity. |
| **AC40-5** | Real UI Disconnect tap, session/transport terminal phase, zero subsequent dispatch | `SettingsScreen` UI disconnect action, `ObdSession`, `UniversalBlePlatform` | **C05**: Tapping Disconnect transitions session to idle, routes back to ConnectScreen, transport enters quiescent terminal state with 0 post-disconnect calls. |

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
| **C08** | Late Result & Route Currentness | Rapid route transitions between shell and root routes; 0 stray snackbars or pop errors | `software-root` | **PASS** |
| **C09.1** | 320x640 Portrait @ 2.0x Scale | Zero RenderFlex overflows in EN & ZH; touch targets >= 48x48; host PNG captured | `software-root` | **PASS** |
| **C09.2** | 568x320 Landscape @ 2.0x Scale | Zero RenderFlex overflows in EN & ZH; host PNG captured | `software-root` | **PASS** |
| **C09.3** | Dialog Kept Open Across Rotation | Language modal bottom sheet kept open across portrait -> landscape rotation & locale switch | `software-root` | **PASS** |
| **C09.4** | Semantics Inspection | Key interactive controls provide valid accessibility labels and tap actions | `software-root` | **PASS** |

---

## 3. Negative Controls & Mutation Matrix (M01 ~ M07, G01 ~ G12)

Verified via `test/tool/test_l10n_required.py` (21 tests in suite):

| Mutation ID | Controlled Fault Injection | Expected Failure Mode | Observed Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **M01** | Omit required test case from report | `L10nRequiredError: Required cases missing from report` | Rejection | **PASS** |
| **M02** | Test case marked as `"result": "failure"` | `L10nRequiredError: Required cases failed` | Rejection | **PASS** |
| **M03** | Required test case marked as `"skipped": true` | `L10nRequiredError: Required cases were skipped` | Rejection | **PASS** |
| **M04** | Truncated or malformed report JSON | `L10nRequiredError: Report JSON guard rejected report` | Rejection | **PASS** |
| **M05** | Nonzero runner child exit code (`runner_exit = 1`) | `L10nRequiredError: Runner failed with nonzero exit code: 1` | Rejection | **PASS** |
| **M06** | Required artifact file missing on disk | `L10nRequiredError: Required artifact not found` | Rejection | **PASS** |
| **M07** | Control: Valid report + manifest + artifacts | Produces accepted structured receipt with SHA-256 digests | Acceptance | **PASS** |
| **G01~G12** | 12 verifier stress probes (duplicate tags, wrong suite/name, early/duplicate done, unclosed test, bad bool, magic byte check, profile mismatch, duplicate manifest case, stale receipt overwrite) | `L10nRequiredError` / `{"status": "REJECTED"}` | Rejection / Invalidation | **PASS** |

---

## 4. Native Residual Ledger

Per Batch 1L-C1a exit criteria, native and hardware-bound validations are tracked with explicit ownership and not claimed as software passes:

| Residual ID | Description | Layer | Status in C1a | Hand-off Owner |
| :--- | :--- | :--- | :--- | :--- |
| **R01_NATIVE_DEVICE_BLE** | Physical Bluetooth adapter scan, pairing & connection on Android/iOS | `native-device` | `NOT_RUN` | Batch 1L-C1b / Issue #36 & #91 (Platform integration #24) |
| **R02_NATIVE_OS_LOCALE_SYNC** | Android 13+ per-app language platform broadcast & configuration sync | `native-platform` | `NOT_RUN` | Batch 1L-C1b / Issue #36 |
| **R03_PHYSICAL_WEAR_RENDER** | Physical circular wearable display render, rotary and ambient interaction | `native-wear` | `NOT_RUN` | Issue #65 (Rotary/Ambient/Provisioning) & Issue #48 (Release Evidence) |

---

## 5. Verification Gate Integration

The scoped gate runner `python3 tool/ci/run_l10n_required.py` is integrated into `tool/ci/full_gate.sh`:
```bash
run_step l10n-required python3 tool/ci/run_l10n_required.py --evidence ci-artifacts/l10n-required/receipt.json
```
Receipts, test logs, and accessibility PNG artifacts are saved and verified under `build/reports/l10n_accessibility/` and `docs/verification/evidence/l10n_production_receipt.json`.
For acceptance hardening details, see [docs/verification/batch1l-c1a-r1-acceptance-integrity.md](file:///Users/iml1s/Documents/mine/apps/auto/torque/docs/verification/batch1l-c1a-r1-acceptance-integrity.md) and [docs/verification/batch1l-c1a-r2a-verifier-provenance.md](file:///Users/iml1s/Documents/mine/apps/auto/torque/docs/verification/batch1l-c1a-r2a-verifier-provenance.md).

