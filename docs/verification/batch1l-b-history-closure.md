# Batch 1L-B2b Verification Record: Issue #39 Acceptance & Evidence Reconciliation

**Scope**: Issue #39 (Batch 1L-B2b Closeout Reconciliation, coordinating #34)  
**Date**: 2026-09-26  
**Status**: RECONCILED (All 4 original ACs addressed; Software Gate 100% PASS; Native/Physical NOT_RUN transparently isolated)  
**References**:
- MR !69 (Batch 1L-B1, `feat/i18n-history-export-presentation`)
- MR !70 (Batch 1L-B2a, `feat/i18n-history-async-feedback`)
- Base Branch: `main` (Merge commit `6aad1a97`, squashed from !70 `5f73e4c4`)
- Preceding Verification Records:
  - `docs/verification/batch1l-b1-history-export.md`
  - `docs/verification/batch1l-b2-async-feedback.md`

---

## 1. Executive Summary & Closeout Protocol

Issue #39 ("Localization of History, Export, and Presentation while Preserving Canonical Observations") establishes the requirement that user-facing screens and share actions must adapt to runtime language transitions while exported artifacts, wire tokens, units, timestamps, and recorded telemetry remain strictly canonical, immutable, and locale-invariant.

This document performs the final reconciliation across the two implementation slices:
1. **Batch 1L-B1 (MR !69)**: Presentation vs state separation, typed restart notice (`telemetryArtifactNoticeProvider`), canonical exporter locale-neutrality (`TelemetrySessionExporter`), and production share entry (`AppShareEntryController`).
2. **Batch 1L-B2a (MR !70)**: Render-time locale resolution for active SnackBars (`TelemetrySessionActionFeedback`), route currentness guarding (`ModalRoute.of(context).isCurrent`), target identity guarding across awaits, explicit widget keying (`ValueKey`), and ELM reply-timer remaining deadline budget clipping (H01–H05).

---

## 2. Evidence Ledger: Four Original Acceptance Criteria of Issue #39

### AC39-1: Canonical Observations & Units Preserved Across Export, Replay, and Migration
> *Requirement*: Identical canonical observations, units, status, and timestamps must be preserved across locale transitions during export, import, replay, and legacy format migration; only declared human display fields may differ.

- **Production Paths**:
  - `lib/telemetry/session/telemetry_session_exporter.dart` (`TelemetrySessionExporter`)
  - `lib/telemetry/session/telemetry_export_codec.dart` (`TelemetryExportCodec`)
  - `lib/telemetry/session/telemetry_session_reader.dart` (`TelemetrySessionReader`)
  - `lib/state/telemetry_session_replay.dart` (`TelemetrySessionReplay`)
- **Suites & Test Cases**:
  - `test/telemetry/telemetry_locale_invariant_export_test.dart` (Cases B02, B03, B05, B08)
  - `test/l10n/l05_history_action_locale_journey_test.dart` (Case B04)
  - `test/telemetry/telemetry_session_replay_test.dart`
- **Layers**: Domain, Boundary-Integration, Widget
- **Verified Evidence**:
  - Export payloads (CSV and JSON) generated from the same recorded telemetry under `en` vs `zh-TW` produce 100% byte-identical contents with matching SHA-256 and FNV-1a checksums.
  - Verbatim preview header policy (`# preview=預覽已抽樣；匯出保留完整已記錄事件`) is preserved across all locales.
  - Timestamps remain ISO-8601 UTC; units remain canonical (`RPM`, `km/h`, `kPa`, `°C`); numeric values (`-12.5`, `0.0`, `null`) are unaltered.
  - Negative control: Tampered column names (`elapsed_ms` -> `經過毫秒`) and translated JSON keys fail schema validation invariants (B08).
- **Status**: **PASS (Software & In-App Replay)**
- **Transparent Scope Note**: In-app replay loads from local session storage (`TelemetrySessionStore`). An external file importer UI does not exist in the app; external diagnostic report import workflows are reserved for successor issues #70.A/#70.B.

---

### AC39-2: Production Exporters & Legitimate Run Metadata Canonicalization
> *Requirement*: Verified against real production exporters; legitimate run metadata has correct canonicalization and locale-independent metadata allowlist.

- **Production Paths**:
  - `lib/state/app_share_entry_controller.dart` (`AppShareEntryController`)
  - `lib/state/app_share_coordinator.dart` (`AppShareCoordinator`)
  - `lib/telemetry/session/telemetry_session_exporter.dart` (`TelemetrySessionExporter`)
- **Suites & Test Cases**:
  - `test/telemetry/telemetry_locale_invariant_export_test.dart` (Case B02)
  - `test/app_share_entry_controller_test.dart` (13/13 tests)
- **Layers**: Production-Root, Controller, Exporter
- **Verified Evidence**:
  - Tested via `AppShareEntryController` under injected `LocalePreference.english` and `LocalePreference.traditionalChinese`.
  - Human share subject text localizes correctly (`shareTelemetrySubjectText`), while the staged export file remains byte-identical to direct exporter output.
  - Legitimate metadata headers (`# source=fieldAppConnection`, `# transport=bluetoothLe`, `# protocol=...`) follow strict canonical token representations.
- **Status**: **PASS**

---

### AC39-3: Locale Events, Chooser Cancellation, Full Storage, Restart, and Failed Staging Keep Owner & Originals
> *Requirement*: Recording/export locale events, chooser cancellation, full storage, restart notice, failed staging, and missing values must maintain owner and original artifacts without leaking permissions or repeating dispatches.

- **Production Paths**:
  - `lib/state/telemetry_sessions.dart` (`TelemetrySessionActions`)
  - `lib/state/artifact_operation_gate.dart` (`ArtifactOperationGate`)
  - `lib/state/app_share_policy.dart` (`AppSharePolicy`)
  - `lib/ui/widgets/telemetry/telemetry_artifact_restart_notice.dart`
- **Suites & Test Cases**:
  - `test/l10n/l05_history_async_feedback_test.dart` (Cases T01–T07, T11)
  - `test/telemetry/telemetry_locale_invariant_export_test.dart` (Cases B05, B06)
  - `test/app_share_entry_controller_test.dart`
- **Layers**: Boundary-Integration, Widget, State
- **Verified Evidence**:
  - **Typed Restart Notice**: Maintained in `telemetryArtifactNoticeProvider` (`ArtifactNoticeReason.restartRequired`); displayed dynamically via `TelemetryArtifactRestartNotice` without discarding gate token or requiring action replay.
  - **Stream Cancellation & Cleanup**: `subscription.cancel()` verified upon stream termination with zero subsequent read dispatch; contained share worker process clean exit verified.
  - **Artifact Gate Synchronization**: `ArtifactOperationGate` synchronously excludes concurrent deletions/modifications, tracks owner ID, and transitions to `isIdle` on terminal release.
  - **Target Identity Isolation**: Handlers capture `targetSessionId` / `targetId` prior to async dispatch and discard stale feedback if active session mutated during await.
- **Status**: **PASS**

---

### AC39-4: Readability Under Other OS Locales, Timezones, Viewports, and Accessibility Without Polluting Machine Data
> *Requirement*: English and Traditional Chinese must remain legible under other OS locales, across midnight/timezones, negative/decimal/unknown values, and long labels without RenderFlex overflow or polluting machine data.

- **Production Paths**:
  - `lib/ui/screens/telemetry/telemetry_session_detail_screen.dart`
  - `lib/ui/screens/telemetry/telemetry_sessions_screen.dart`
  - `lib/ui/widgets/telemetry/telemetry_session_action_feedback.dart`
  - `lib/l10n/app_en.arb` / `lib/l10n/app_zh_Hant.arb`
- **Suites & Test Cases**:
  - `test/l10n/l05_history_action_locale_journey_test.dart` (Cases B04, B07)
  - `test/l10n/l05_history_async_feedback_test.dart` (Cases T01–T03, T08–T11)
- **Layers**: Widget, Presentation, Accessibility
- **Verified Evidence**:
  - **Dynamic Relocalization (F03)**: Active on-screen SnackBars dynamically rebuild in new locale upon runtime language change (`en` ↔ `zh-TW`) via `TelemetrySessionActionFeedback`.
  - **320dp Portrait & Narrow Landscape (F06)**: Tested at 320dp width portrait and 568x320 landscape under 200% text scale (`TextScaler.linear(2.0)`); both dialog and SnackBar render with 0 RenderFlex overflow.
  - **Touch Targets & Semantics**: Delete confirmation dialogs made `scrollable: true`; touch targets strictly >= 48dp height; buttons have `hasTapAction`, `isButton`, `isSelected` semantics.
  - **Route Currentness Protection (F04)**: Asynchronous completion checks `ModalRoute.of(context).isCurrent`; suppresses SnackBar and `Navigator.pop` when screen is covered by another route, while ensuring underlying library provider cache is reliably invalidated.
- **Status**: **PASS (Software Harness)**
- **Transparent Scope Note**: Native Android OS activity recreation (`API 32/33+`) and physical vehicle testing remain **NOT_RUN** (as explicitly recognized in #39 task definition: software contract completion does not require live vehicle runs; native platform lifecycle belongs to platform ticket #36).

---

## 3. ELM Timing Hotfix Reconciliation (R70-04 / H01–H05)

In `lib/obd/elm327_client.dart` (`_sendNow`), write latency could previously extend total command timeout because post-write timer arming reused the pre-write budget duration.

- **Fix Applied**:
  ```dart
  if (identical(_pending, pending) && !pending.isCompleted) {
    final replyTimeout = _withinDeadline(timeout);
    _pendingDeadline = replyTimeout;
    _armPendingTimer(replyTimeout, _onCommandTimeout);
  }
  ```
- **H01 Verification**: Added H01 test in `test/lifecycle_test.dart`:
  - Case 1: 40ms write + 30ms reply <= 120ms deadline -> completes successfully.
  - Case 2: 50ms write + 70ms reply > 100ms deadline -> correctly times out at remaining 50ms budget (`throwsA(isA<TimeoutException>())`).
  - Total lifecycle tests: 12/12 passing.

---

## 4. Quality Gate Summary

| Gate | Command | Exit Code | Result |
| :--- | :--- | :--- | :--- |
| **Dart Analyzer** | `fvm flutter analyze` | 0 | 0 issues found |
| **Privacy Contract** | `python3 tool/workshop/validate_privacy_contract.py --repo-root .` | 0 | 12 flows, 12 claims, 0 errors |
| **History Async Feedback** | `fvm flutter test test/l10n/l05_history_async_feedback_test.dart` | 0 | 11/11 PASS |
| **Lifecycle & Timing** | `fvm flutter test test/lifecycle_test.dart` | 0 | 12/12 PASS |
| **Glossary Evidence** | `fvm flutter test test/l10n/glossary_evidence_test.dart` | 0 | 18/18 PASS |
| **Transcript Periodic Snapshot** | `fvm flutter test test/transcript_periodic_snapshot_test.dart` | 0 | 16/16 PASS |
| **Locale Invariant Export** | `fvm flutter test test/telemetry/telemetry_locale_invariant_export_test.dart` | 0 | All PASS |
| **Share Entry Controller** | `fvm flutter test test/app_share_entry_controller_test.dart` | 0 | 13/13 PASS |

---

## 5. Closeout Verdict & Next Handoffs

- **Issue #39 Verdict**: **ACCEPTED FOR CLOSEOUT** (Software acceptance criteria AC39-1 through AC39-4 fully satisfied with reproducible automated test evidence).
- **Residual Items Handed Off to Successor Issues**:
  1. `Issue #40` (1L-C1): Production root journey & end-to-end full accessibility acceptance.
  2. `Issue #36` (1L-L02): Native Android/iOS platform lifecycle & OS locale recreation residuals.
  3. `Issue #72 / #48` (1L-C2): Candidate adoption, release packaging, and store verification.
  4. `Issue #101`: Write receipt reconciliation (independent diagnostics inquiry).
  5. `Epic #34`: Overall milestone ledger reconciliation.
