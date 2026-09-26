# Batch 1L-C1a-R1 Verification Record: Acceptance Integrity & Evidence Hardening

**Task ID**: `TELLTALE-1L-C1A-R1-ACCEPTANCE-INTEGRITY`  
**Scope**: Issue #40 (Batch 1L-C1a: Production-root journeys and fail-closed acceptance receipts, coordinating #34)  
**MR**: `test(i18n): repair acceptance integrity and complete C1a evidence (Refs #40, #34)`  
**Branch**: `fix/i18n-c1a-r1-acceptance-hardening`  
**Base**: `6d4015d1cfea51cabe4a7c4f8f3893b5e864b16f` (`main`)  
**Exit Level**: `C1A_R1_PARTIALLY_ACCEPTED` (Split into `C1a-R2a` for verifier provenance and `C1a-R2b` for C02-C08 software proof; does not imply `ISSUE40_COMPLETE`, `NATIVE_QUALIFIED`, or `RELEASED`)  
**Status**: Merged via MR !74; Verifier hardening completed in `C1a-R2a`; C02-C08 journey proof preserved in `C1a-R2b`.

---

## 1. Findings Disposition (R73-01 ~ R73-05)

| Finding ID | Severity | Root Cause / Audit Finding | Hardened Resolution & Implementation | Verification Method |
| :--- | :--- | :--- | :--- | :--- |
| **R73-01** | P1 | Verifier accepted non-conforming event streams (early done, duplicate done, overwritten failures, string bools, magic-byte missing PNGs, duplicate cases). Stale accepted receipts persisted on failure. | Refactored `tool/ci/run_l10n_required.py`: Reused complete event validation state machine (`_parse_events`, `_require_typed_testid`, `_strict_bool`). Enforced single terminal `done=true` as last event. Implemented exact suite path normalization (`normalize_suite_path`) + qualified test name 1-to-1 matching. Added PNG magic-byte verification (`\x89PNG\r\n\x1a\n`). Fail-closed receipt invalidation on rejection writes `{"status": "REJECTED"}`. | `test/tool/test_l10n_required.py` (21 tests including 12 negative verifier probes + receipt invalidation). |
| **R73-02** | P1 | Harness BLE platform counter not injected into production BLE seam. Missing positive control. Direct provider manipulation instead of real UI language switch. | Injected `UniversalBle.setInstance(harness.blePlatform)` during setup, reset in dispose. Added positive control (`await UniversalBle.startScan()` increments `scanCount` by 1). Replaced provider setter with real UI interaction via `connect_language_entry` and bottom sheet radio selection. Asserted independent literal strings (`'Choose a connection'`, `'選擇連線方式'`). | `test/l10n/l06_production_root_journey_test.dart` [C01]. |
| **R73-03** | P1 | A11y tests swallowed non-layout errors. Touch targets checked >= 44dp instead of 48x48 contract. Captures targeted first `RepaintBoundary` inside lists rather than app root with overlays. | Preserved non-overflow framework errors via `previousOnError?.call(details)`. Tested interactive touch targets >= 48x48 on `connect_language_entry` and `demoCardInkWell`. Wrapped `TorqueApp()` with `RepaintBoundary(key: Key('app_root_repaint_boundary'))` to capture dialogs and bottom sheets. Verified effective `TextScaler` at 2.0x. Inspected semantics for `SemanticsAction.tap`. | `test/l10n/l06_production_accessibility_test.dart` [C09.1 ~ C09.4]. 3 distinct PNGs verified. |
| **R73-04** | P1 | Acceptance receipt lacked provenance binding and did not invalidate previous ACCEPTED state on failure. | Runner records run execution context, platform, child exit code, test outcomes, and artifact digests. Failure immediately overwrites receipt with `status: "REJECTED"`. | `tool/ci/run_l10n_required.py` and unit tests. |
| **R73-05** | P1 | Original Acceptance Criteria AC40-1 ~ AC40-5 renamed in manifest and docs. Native residual owners misattributed. | Restored full AC40-1 ~ AC40-5 definitions in `production_acceptance_manifest.json` and verification docs. Re-aligned native residual owners: #36 & #91 (Platform integration #24) for BLE; #36 for OS locale sync; #65 & #48 for WearOS display/release qualification. | Audit against Issue #40, #36, #65, #91, #48. |

---

## 2. Acceptance Criteria Mapping (AC40-1 ~ AC40-5)

| Criterion | Specification | Layer & Implementation Mapping | Test Evidence |
| :--- | :--- | :--- | :--- |
| **AC40-1** | Real language choice reachable before connection without account/VIN/Demo/permissions; OS locale sync; formal language guard; accessibility at 320dp/2x text scale/landscape | `lib/ui/screens/connect/connect_screen.dart`, `LanguagePicker`, `AppLocalesPlatform`, `LanguageSwitchGuard` | **C01, C07, C09.1, C09.2, C09.3, C09.4**: Bidirectional en/zh switch with 0 extra requests; guard blocks during recording & artifact-busy; 320x640 portrait & 568x320 landscape at 2.0x scale with 0 RenderFlex overflow; touch targets >= 48x48; dialog-open orientation rotation verified. |
| **AC40-2** | Real Demo connect, session connected phase, live PIDs, read-only DTC; refusal reason & transport failure rendering without re-prompts | `ConnectScreen`, `DashboardScreen`, `DtcScreen`, `CountingBlePlatform` | **C02, C06**: Real Demo connect transitions session to connected; reads live PIDs; DTC inspection executes read-only (no clear/mode08); Bluetooth/Location refusal reasons rendered; stored failure does not re-trigger scans on locale change. |
| **AC40-3** | Telemetry recording, session completed, history tile click opens exact session replay; late result/route protection | `telemetryRecorderControllerProvider`, `telemetry_sessions_screen.dart`, `telemetry_session_detail_screen.dart` | **C03, C08**: Recording collects real telemetry frames (`valueCount > 0`); stop settles to completed; exact session opened in replay maintaining state; rapid route switches verify route currentness without stray snackbars. |
| **AC40-4** | Real UI export CSV & JSON, byte-identical canonical contents, gate settles, reopen same session | `TelemetrySessionActions`, `AppShareCoordinator`, `ArtifactOperationGate` | **C04**: Real UI export to CSV and JSON via isolate-backed streams; byte-identical contents verified; gate transitions to idle; reopening same session retains integrity. |
| **AC40-5** | Real UI Disconnect tap, session/transport terminal phase, zero subsequent dispatch | `SettingsScreen` UI disconnect action, `ObdSession`, `UniversalBlePlatform` | **C05**: Tapping Disconnect transitions session to idle, routes back to ConnectScreen, transport enters quiescent terminal state with 0 post-disconnect calls. |

---

## 3. Production Root Journey & Accessibility Test Matrix (C01 ~ C09.4)

| Case ID | Criterion | Scenario | Layer | Verified Behaviors |
| :--- | :--- | :--- | :--- | :--- |
| **C01** | AC40-1 | Unconnected Language Entry | `software-root` | UI entry reachable pre-connect; positive control increments scanCount; bidirectional en/zh switch with 0 extra BLE/network calls; independent literal checks |
| **C02** | AC40-2 | Demo to Dashboard / PID / DTC | `software-root` | Demo connect, session connected phase, live PIDs render, DTC inspection read-only (zero mode08/clear dispatch) |
| **C03** | AC40-3 | Recording to History to Replay | `software-root` | Telemetry recording collects frames, settles to completed, tile tap opens exact session replay preserving observations |
| **C04** | AC40-4 | Export / Cancel / Reopen | `software-root` | Real UI export CSV & JSON, canonical byte-identical contents, gate settles to idle, reopen same session |
| **C05** | AC40-5 | Real UI Disconnect | `software-root` | Tap Disconnect button, session terminates, routes to Connect, 0 post-disconnect dispatch |
| **C06** | AC40-2 | Permission & Transport Failure | `software-root` | Refusal reasons rendered, stored failure does not re-prompt Bluetooth scan on locale change |
| **C07** | AC40-1 | Formal Language Switch Guard | `software-root` | Recording and artifact-busy states block switch; unblocked when idle |
| **C08** | AC40-3 | Late Result & Route Currentness | `software-root` | Rapid route transitions between shell and root routes; 0 stray snackbars or pop errors |
| **C09.1** | AC40-1 | 320x640 Portrait @ 2.0x Scale | `software-root` | Zero RenderFlex overflows in EN & ZH; interactive touch targets >= 48x48; host PNG captured |
| **C09.2** | AC40-1 | 568x320 Landscape @ 2.0x Scale | `software-root` | Zero RenderFlex overflows in EN & ZH; host PNG captured |
| **C09.3** | AC40-1 | Dialog Kept Open Across Rotation | `software-root` | Language modal bottom sheet and alert dialog kept open across portrait <-> landscape rotation & locale switch; zero crash |
| **C09.4** | AC40-1 | Semantics Inspection | `software-root` | Key interactive controls provide valid accessibility labels and tap actions |

---

## 4. Verifier Negative Regression & Mutation Matrix

Verified via `test/tool/test_l10n_required.py` (21 tests):

| Probe ID | Fault Injection / Non-conforming Condition | Expected Outcome | Actual Outcome | Status |
| :--- | :--- | :--- | :--- | :--- |
| **G01** | Duplicate case tags in single test name (`[C01] [C09.1]`) | Rejected: test name cannot satisfy multiple required cases | `L10nRequiredError` | **PASS** |
| **G02** | Wrong suite path or wrong qualified test name | Rejected: exact suite path and qualified name mismatch | `L10nRequiredError` | **PASS** |
| **G03** | Terminal `done` event occurs before tests complete | Rejected: `done` must occur after all tests complete | `L10nRequiredError` | **PASS** |
| **G04** | Terminal `done=true` followed by `done=false` | Rejected: duplicate or contradicting terminal `done` event | `L10nRequiredError` | **PASS** |
| **G05** | Test case fails first, then subsequent event claims success | Rejected: test outcome cannot overwrite earlier terminal failure | `L10nRequiredError` | **PASS** |
| **G06** | Test report contains top-level global error event | Rejected: global errors invalidate test run | `L10nRequiredError` | **PASS** |
| **G07** | Test started but unclosed (missing testDone terminal) | Rejected: unclosed test detected | `L10nRequiredError` | **PASS** |
| **G08** | Skipped flag set as string `"true"` instead of boolean `true` | Rejected: invalid boolean type | `L10nRequiredError` | **PASS** |
| **G09** | Required case marked as hidden or omitted | Rejected: required cases missing or hidden | `L10nRequiredError` | **PASS** |
| **G10** | Artifact PNG file contains non-PNG bytes (missing magic header) | Rejected: invalid PNG magic bytes | `L10nRequiredError` | **PASS** |
| **G11** | Manifest profile does not match expected profile | Rejected: profile mismatch | `L10nRequiredError` | **PASS** |
| **G12** | Manifest contains duplicate required case IDs | Rejected: duplicate case ID in manifest | `L10nRequiredError` | **PASS** |
| **G13** | Stale receipt invalidation on verification failure | Overwrites receipt with `status: "REJECTED"` | Verified written | **PASS** |
| **M01** | Omit required test case from report | Rejected: required cases missing | `L10nRequiredError` | **PASS** |
| **M02** | Test case marked as `"result": "failure"` | Rejected: required case failure | `L10nRequiredError` | **PASS** |
| **M03** | Required test case marked as `"skipped": true` | Rejected: required case skipped | `L10nRequiredError` | **PASS** |
| **M04** | Truncated or malformed report JSON | Rejected: malformed JSON | `L10nRequiredError` | **PASS** |
| **M05** | Nonzero runner child exit code (`runner_exit = 1`) | Rejected: nonzero exit code | `L10nRequiredError` | **PASS** |
| **M06** | Required artifact file missing on disk | Rejected: artifact missing | `L10nRequiredError` | **PASS** |
| **M07** | Positive control: valid report + manifest + artifacts | Produces accepted structured receipt | `status: "ACCEPTED"` | **PASS** |

---

## 5. Native Residual Ledger

Tracked with explicit cross-issue ownership; non-software validations are isolated and not claimed as C1a software passes:

| Residual ID | Description | Layer | Status in C1a | Hand-off Owner |
| :--- | :--- | :--- | :--- | :--- |
| **R01_NATIVE_DEVICE_BLE** | Physical Bluetooth adapter scan, pairing & connection on Android/iOS | `native-device` | `NOT_RUN` | Batch 1L-C1b / Issue #36 & #91 (Platform integration #24) |
| **R02_NATIVE_OS_LOCALE_SYNC** | Android 13+ per-app language platform broadcast & configuration sync | `native-platform` | `NOT_RUN` | Batch 1L-C1b / Issue #36 |
| **R03_PHYSICAL_WEAR_RENDER** | Physical circular wearable display render, rotary input, ambient mode on WearOS | `native-wear` | `NOT_RUN` | Issue #65 (Rotary/Ambient/Provisioning) & Issue #48 (Release Evidence) |

---

## 6. Generated Evidence Artifacts & Integrity Hashes

Verified in `docs/verification/evidence/l10n_production_receipt.json`:
- **Manifest SHA-256**: `866bfb57e1cd90a027f80aacc700b55df3362ea5870943f9f9c67e6ea26e5afc`
- **Report SHA-256**: `bbbc28b68ed04c48accecff52fa5d31af9e21999ed0b1818e2fe7b0797a9e2e4`
- **Required Cases**: 12/12 PASSED

### Accessibility PNG Artifacts:
| File Path | Byte Size | SHA-256 Digest | Capture Target |
| :--- | :--- | :--- | :--- |
| `build/reports/l10n_accessibility/c09_portrait_320x640_2x.png` | 16,650 B | `c57b8dc08277992a1f3f2bd48d859c1a61a7eda127d950836e70497960de4bb1` | 320x640 portrait @ 2.0x scale (ZH view) |
| `build/reports/l10n_accessibility/c09_landscape_568x320_2x.png` | 5,724 B | `5ba6856019b75f6552c16549a69d7ed896f0191b9bc8a8b6a4a1f3abfbad1891` | 568x320 landscape @ 2.0x scale (Connect view) |
| `build/reports/l10n_accessibility/c09_dialog_open_landscape_rotated.png` | 2,957 B | `11d48336bb5ff82ff3c2d85cfb6d492c828e7535673fbe04c8ba222078fcc580` | Landscape rotated with Language modal bottom sheet open |
