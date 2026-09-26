# Batch 1L-B1 Verification Record: History Presentation & Canonical Export Isolation

**Scope**: Issue #39 (Batch 1L-B1, coordinating #34, #40, #72)  
**Date**: 2026-09-26  
**Status**: 100% PASS (0 warnings, 0 skips, 0 drift)

---

## 1. Architecture Invariant & Scope Boundary

1. **Presentation vs State Separation**:
   - `telemetryArtifactNoticeProvider` holds typed state `ArtifactNotice?` containing `reason: ArtifactNoticeReason.restartRequired` and optional `rawDetail`.
   - UI (`TelemetryArtifactRestartNotice`) reads `AppLocalizations.of(context)` during widget build, dynamically rendering localized sentences (`l10n.telemetryArtifactRestartRequired`) without dismissing or dropping the process-lifetime gate.
   - `TelemetrySessionActionResult.failure` produces localized error sentences on demand via `message(l10n)`, avoiding hardcoded Chinese strings in application state.

2. **Canonical Exporter Locale-Neutrality**:
   - `TelemetrySessionExporter` and `TelemetryExportCodec` maintain strict locale-independence.
   - Canonical format preview header (`# preview=預覽已抽樣；匯出保留完整已記錄事件`) is preserved verbatim in all CSV exports regardless of device or runtime language.
   - Wire keys, column headers (`elapsed_ms`, `pid_id`, `value`, `unit`, etc.), numeric formatting (`-12.5`, `0.0`), and JSON types remain invariant.

3. **Evidence Layer Clarity**:
   - **Production Entry Layer**: Tested via `AppShareEntryController` with `LocalePreference` injection and temporary file staging, verifying that human share subjects localize (`shareTelemetrySubjectText`) while canonical payloads (CSV / JSON) remain 100% byte-identical (matching SHA-256, FNV-1a, and direct exporter output).
   - **Permission & Side-Effect Boundary**: Hooked directly to real permission facade (`ensureBluetoothPermissions` via `testEnsureBluetoothPermissionsOverride`) alongside UniversalBle (`scan`, `connect`, `send`). Every side effect is validated with a verified positive control prior to asserting exact zero-increment during locale transitions.
   - **Cancellation & Worker Lifecycle**: `subscription.cancel()` is baselined immediately upon Future resolution with zero post-cancel read dispatch, and cross-mapped to contained worker lifecycle tests (`app_share_entry_controller_test.dart`).

---

## 2. Canonical Export Field & Metadata Inventory

| Field / Metadata Key | Type | Locale Neutral? | Preservation Policy |
| :--- | :--- | :--- | :--- |
| `# telltale_telemetry_csv_version=2` | Header | Yes | Constant version indicator |
| `# source=fieldAppConnection` | Header | Yes | `TelemetrySource.wireName` |
| `# transport=bluetoothLe` | Header | Yes | Transport enum name |
| `# protocol=...` | Header | Yes | Wire protocol identifier |
| `# preview=預覽已抽樣；匯出保留完整已記錄事件` | Header | Yes | Verbatim format policy, never translated |
| `# privacy_exclusions=...` | Header | Yes | Canonical privacy tokens |
| `observed_at_utc` | CSV col 1 | Yes | ISO-8601 UTC timestamp |
| `source_timestamp_utc` | CSV col 2 | Yes | ISO-8601 UTC timestamp |
| `elapsed_ms` | CSV col 3 | Yes | Monotonic microseconds / 1000 |
| `pid_id` | CSV col 4 | Yes | Wire PID identifier (e.g. `7E0:010C`) |
| `signal_name` | CSV col 5 | Yes | Escaped definition label (quotes/newlines safe) |
| `event_type` | CSV col 6 | Yes | Wire event type token (`value`, `status`) |
| `value` | CSV col 7 | Yes | Numeric representation or null; negative and 0.0 preserved |
| `unit` | CSV col 8 | Yes | Standard canonical unit |
| `quality` | CSV col 13 | Yes | Quality flags (e.g. `outOfReferenceRange`, `stale`) |

---

## 3. Acceptance Matrix: B01 ~ B08

| ID | Scenario | Test Suite | Command & Result |
| :--- | :--- | :--- | :--- |
| **B01** | Restart, storage, and share failure notices dynamically rerender across locales without repeating action | `test/l10n/l05_history_action_locale_journey_test.dart` | `flutter test test/l10n/l05_history_action_locale_journey_test.dart` -> **PASS** |
| **B02** | Production share entry (`AppShareEntryController`) under confirmed `LocalePreference.english` vs `traditionalChinese` verifies localized subject text with byte-identical CSV/JSON payloads, matching SHA-256, FNV-1a, and direct exporter | `test/telemetry/telemetry_locale_invariant_export_test.dart` | `flutter test test/telemetry/` -> **PASS** |
| **B03** | Same fixture across en & zh-Hant produces byte-identical CSV/JSON with matching SHA-256/FNV-1a, verified against parsed data rows and JSON schema | `test/telemetry/telemetry_locale_invariant_export_test.dart` | `flutter test test/telemetry/` -> **PASS** |
| **B04** | Detail screen retains session identity (family calls recorded), PID selection, speed (16x selected == true), scrubbed Slider value (0.6), and timeline value (2500 RPM) across locale change with zero scans, zero connects, zero sends, and zero permissions (all 4 verified with positive controls) | `test/l10n/l05_history_action_locale_journey_test.dart` | `flutter test test/l10n/l05_history_action_locale_journey_test.dart` -> **PASS** |
| **B05** | Negative values (`-12.5`), zero (`0.0`), stale status, estimates, and escaped quotes/newlines | `test/telemetry/telemetry_locale_invariant_export_test.dart` | `flutter test test/telemetry/` -> **PASS** |
| **B06** | Stream cancel mid-way captures immediate post-cancel baseline on `subscription.cancel()` Future completion, proving zero subsequent read dispatch, zero late chunk emissions, done == false, and source bytes/hash intact. Corroborated by contained worker exit and cancel tests. | `test/telemetry/telemetry_locale_invariant_export_test.dart`<br>`test/app_share_entry_controller_test.dart` | `flutter test test/telemetry/`<br>`flutter test test/app_share_entry_controller_test.dart` -> **PASS** |
| **B07** | 320dp portrait and 640x320 landscape under en and zh-Hant with 2.0x text scaling; interactive controls (buttons and chips) satisfy touch targets (>= 48x48 bounds) with canonical `isSemantics` (isButton, isSelected, hasTapAction) and 0 RenderFlex overflow | `test/l10n/l05_history_action_locale_journey_test.dart` | `flutter test test/l10n/l05_history_action_locale_journey_test.dart` -> **PASS** |
| **B08** | Tampered CSV columns, translated headers (`elapsed_ms` -> `經過毫秒`, `value` -> `數值`, `unit` -> `單位`), translated preview policy, and translated JSON keys fail schema invariants via negative controls | `test/telemetry/telemetry_locale_invariant_export_test.dart` | `flutter test test/telemetry/` -> **PASS** |

---

## 4. Verification Evidence & Quality Gates

1. **Flutter Analyzer**:
   ```bash
   ~/fvm/versions/3.47.0/bin/flutter analyze
   # Output: No issues found! (ran in 2.8s)
   ```
2. **SDK Privacy Audit Receipt Validation**:
   ```bash
   python3 tool/workshop/validate_privacy_contract.py --repo-root .
   # Output: [PASS] Privacy Contract Validation (Exit 0)
   #   - flows_count: 12, claims_count: 12, covered_domains: 10, errors_count: 0
   ```
3. **Targeted Journey & Export Suites**:
   ```bash
   ~/fvm/versions/3.47.0/bin/flutter test test/telemetry/telemetry_locale_invariant_export_test.dart test/l10n/l05_history_action_locale_journey_test.dart
   # Output: All 14 tests passed!
   ```
4. **Contained Share Worker Lifecycle & Cancellation Suite**:
   ```bash
   ~/fvm/versions/3.47.0/bin/flutter test test/app_share_entry_controller_test.dart
   # Output: All 13 tests passed!
   #   - stream cancellation waits for contained worker shutdown: PASS
   #   - completed stream waits for the worker exit acknowledgement: PASS
   ```
5. **Combined L10n and Telemetry Suites**:
   ```bash
   ~/fvm/versions/3.47.0/bin/flutter test test/l10n/ test/telemetry/
   # Output: All 876 tests passed!
   ```
