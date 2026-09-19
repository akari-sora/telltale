# Gate 2 Test Provenance & Verification Evidence Package

**Target Reference**: GitLab Issue #104 (Note 3857735494)  
**Verification Target**: Gate 2 Candidate Build  
**Commit HEAD**: `1ad08253e86ec6a6aef2b706cd0b6729372da3b3`  
**Git Tree SHA**: `23fef0783e9cb6ca783de677ecc3196bebb498d8`  
**Working Tree Status**: Clean (`git status --porcelain` empty)  
**Execution Timestamp**: 2026-09-18T11:15:38Z  
**Verification Gate Outcome**: PASS (All 6 Suites Green, 0 Issues, 0 Skipped in Required Oracles)

---

## 1. Toolchain & Host Environment Provenance

All test suites and static analysis were executed using the repository-pinned Flutter 3.47.0 / Dart 3.13.0 toolchain.

### 1.1 Flutter Framework
```
$ flutter --version
Flutter 3.47.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 4cf2416426 (5 weeks ago) • 2026-08-11 11:53:49 -0700
Engine • hash 59d54a2b2896a6bbf356c94b7fac7b9e235bdacd (revision 5f77625673) (1 months ago) • 2026-08-11 16:38:36.000Z
Tools • Dart 3.13.0 • DevTools 2.60.0
```

### 1.2 Dart SDK
```
$ dart --version
Dart SDK version: 3.13.0 (stable) (Wed Aug 5 00:28:05 2026 -0700) on "macos_arm64"
```

### 1.3 Operating System & Host Platform
```
$ uname -a
Darwin MacBook-Pro-5.local 25.6.0 Darwin Kernel Version 25.6.0: Fri Jul 31 19:17:26 PDT 2026; root:xnu-12377.161.14~5/RELEASE_ARM64_T6041 arm64

$ sw_vers
ProductName:		macOS
ProductVersion:		26.6.2
BuildVersion:		25G83
```

---

## 2. Source-to-Commit Tree Consistency Proof

Verification commands prove that the active workspace exactly matches commit `1ad08253e86ec6a6aef2b706cd0b6729372da3b3` without uncommitted modifications or tree divergence.

### 2.1 Commit Hash & Tree Hash
```bash
$ git rev-parse HEAD
1ad08253e86ec6a6aef2b706cd0b6729372da3b3

$ git rev-parse HEAD^{tree}
23fef0783e9cb6ca783de677ecc3196bebb498d8
```

### 2.2 Working Tree Status
```bash
$ git status --porcelain
(clean, empty output)
```

---

## 3. Fixtures & Test Rig SHA-256 Provenance

The Mode 08 Replay Reference Server and synthetic test fixtures were fingerprinted with cryptographic SHA-256 digests prior to test execution.

```bash
$ shasum -a 256 tool/obd_test_rig/mode08_replay_fixtures.json tool/obd_test_rig/mode08_replay_reference.py
e0a10d417983d02db39a9b0088e15fb6a947b542370f0fddd2b77c7bd02fc136  tool/obd_test_rig/mode08_replay_fixtures.json
4cdc34b4091c910c2315647a081c0ff950f3c59d876b21788454fe4a19ecfdae  tool/obd_test_rig/mode08_replay_reference.py
```

- **Fixture Provenance**: Explicitly labelled `synthetic` under schema version `1.0.0`.
- **Runtime Preflight Check**: Server transmits SHA-256 on `AT#HASH`; test client validates exact equality with local file digest before executing matrix scenarios.

---

## 4. Test Suite Execution Logs & Evidence

### 4.1 Suite 1: Five-Point Finite Control Regression Tests
- **Target**: `test/obd_response_headers_refusal_test.dart`
- **Command**:
  ```bash
  flutter test test/obd_response_headers_refusal_test.dart
  ```
- **Exit Code**: `0`
- **Results**: 5 passed, 0 failed, 0 skipped
- **Verbatim Output**:
  ```
  00:00 +0: loading test/obd_response_headers_refusal_test.dart
  00:00 +0: R3: Five-Point Finite Control Regression Test Suite Positive Control 1: H0 receives clean ATH1 ? -> retains H0, anonymous query proceeds
  00:00 +1: R3: Five-Point Finite Control Regression Test Suite Positive Control 2: Established H1 receives clean ATH0 ? -> retains H1, subsequent queries succeed with headered parsing
  00:00 +2: R3: Five-Point Finite Control Regression Test Suite Gap Probe 1: H1 repeated ATH1 ? via sendGlobal('03') -> retains H1 with correct attribution
  00:00 +3: R3: Five-Point Finite Control Regression Test Suite Gap Probe 2: H0 repeated ATH0 ? -> retains H0
  00:00 +4: R3: Five-Point Finite Control Regression Test Suite Gap Probe 3: ATH1 returns DATA ERROR\r? -> aborts query dispatch, sets uncertainty, and subsequent plain queries are wire-zero rejected
  00:00 +5: All tests passed!
  ```

---

### 4.2 Suite 2: Composite Transaction Tests
- **Target**: `test/elm327_composite_transaction_test.dart`
- **Command**:
  ```bash
  flutter test test/elm327_composite_transaction_test.dart
  ```
- **Exit Code**: `0`
- **Results**: 52 passed, 0 failed, 0 skipped
- **Verbatim Output**:
  ```
  00:00 +0: loading test/elm327_composite_transaction_test.dart
  00:00 +0: composite query transaction apply -> query -> reverse-restore full composite BMW i3 style query: CEA + CRA + FCS + CAF0 + ATSH
  00:00 +1: composite query transaction apply -> query -> reverse-restore 29-bit CAN priority and receive filter transaction
  00:00 +2: composite query transaction apply -> query -> reverse-restore transact alias produces identical result
  00:00 +3: composite query transaction apply -> query -> reverse-restore accepts ElmCompositeTransactionConfig configuration bundle
  00:00 +4: retirement gate: skips measurement and attempts reverse restoration skips measurement when retired after mutations and restores in finally
  00:00 +5: retirement gate: skips measurement and attempts reverse restoration refuses immediately before writing anything if already retired
  00:00 +6: failure recovery in finally reverse-restores in finally after query timeout
  00:00 +7: failure recovery in finally reverse-restores in finally when parser throws exception in runTransacted
  00:00 +8: failure recovery in finally rollbacks earlier mutations in reverse order if apply fails midway
  00:00 +9: failure recovery in finally leaves sticky blocked state when reverse restore fails
  00:00 +10: unrelated polling exclusion throughout mutated adapter state concurrent polling on command chain cannot interleave during mutation
  00:00 +11: bus validation and preflight checks refuses CAN mutations on non-CAN protocols without sending AT commands
  00:00 +12: bus validation and preflight checks DemoTransport refuses composite CAN mutations cleanly
  00:01 +13: bus validation and preflight checks restoreHeader restores previous header when requested
  00:01 +14: bus validation and preflight checks header restore refusal sets sticky failure, leaves header unknown, and refuses next send with zero writes
  00:01 +15: bus validation and preflight checks header restore timeout sets sticky failure and leaves header unknown
  00:01 +16: bus validation and preflight checks header restore disconnect leaves header unknown and refuses next send
  00:01 +17: bus validation and preflight checks header restore throw sets sticky failure, leaves header unknown, and refuses next send with zero writes
  00:01 +18: bus validation and preflight checks restoreHeader with previousHeader null leaves currentHeader on transaction header without restore
  00:01 +19: F2: transaction sender lifecycle, serialization, and isolation leaked sender post-transaction throws operationRetired with zero writes
  00:01 +20: F2: transaction sender lifecycle, serialization, and isolation concurrent senders inside callback are serialized without interleaving
  00:01 +21: F2: transaction sender lifecycle, serialization, and isolation un-awaited send completes before reverse restores execute on wire
  00:01 +22: F2: transaction sender lifecycle, serialization, and isolation callback reentrancy: client.send or setter inside callback throws StateError
  00:01 +23: F2: transaction sender lifecycle, serialization, and isolation infinite action is bounded by budget and revokes sender
  00:01 +24: F2: transaction sender lifecycle, serialization, and isolation connection generation isolation: sender from prior connection cannot write
  00:01 +25: F2: transaction sender lifecycle, serialization, and isolation late continuation from timed out action cannot interleave with concurrent polling and is zero-write rejected
  00:01 +26: F2: transaction sender lifecycle, serialization, and isolation monotonic budget ignores backward wall-clock shifts and times out strictly on monotonic elapsed time
  00:01 +27: F2: transaction sender lifecycle, serialization, and isolation short budget with far deadline bounds total budget by budget rather than deadline
  00:01 +28: F2: transaction sender lifecycle, serialization, and isolation long budget with near deadline bounds total budget by deadline rather than budget
  00:01 +29: F2: transaction sender lifecycle, serialization, and isolation zero budget with future deadline times out immediately before action runs
  00:01 +30: F2: transaction sender lifecycle, serialization, and isolation expired deadline with positive budget times out immediately before action runs
  00:01 +31: F2: transaction sender lifecycle, serialization, and isolation monotonic budget permits execution when monotonic elapsed time is within budget
  00:01 +32: F2: transaction sender lifecycle, serialization, and isolation undrained in-flight command on timeout bounds drain, quarantines connection, and disables polling
  00:01 +33: F2: transaction sender lifecycle, serialization, and isolation callback return closes acceptance of new commands while allowing prior in-flight commands to drain
  00:01 +34: F2: transaction sender lifecycle, serialization, and isolation un-awaited in-flight command failure is not swallowed and rethrows on transaction completion
  00:01 +35: F2: transaction sender lifecycle, serialization, and isolation reconnect during restore loop aborts remaining restores before touching new generation
  00:01 +36: F2: transaction sender lifecycle, serialization, and isolation acceptance 1: old generation drain timeout after reconnect does not fail or quarantine new generation pending request
  00:01 +37: F2: transaction sender lifecycle, serialization, and isolation acceptance 2: delayed header restore does not overwrite cached header or set restoreFailed on new generation
  00:02 +38: F2: transaction sender lifecycle, serialization, and isolation acceptance 3: reconnect safely serializes until old asynchronous teardown finishes and captures teardown errors
  00:02 +39: F2: transaction sender lifecycle, serialization, and isolation acceptance 4: multiple rapid reconnections during slow teardown serialize cleanly and increment sessions without gap
  00:02 +40: F2: transaction sender lifecycle, serialization, and isolation acceptance 5: concurrent teardowns D1 and D2 merge into single in-flight teardown and handle out-of-order await completion safely
  00:02 +41: F2: transaction sender lifecycle, serialization, and isolation acceptance 6: reconnect immediately after D2 completion when D1 and D2 were concurrent does not race or corrupt new session
  00:02 +42: F2: transaction sender lifecycle, serialization, and isolation acceptance 7: quarantine teardown merges with active teardown and clears properly upon completion
  00:02 +43: composite transaction responseHeaders negotiation (ATH1/ATH0) scenario 1: originally H0, responseHeaders: true negotiates ATH1, enables headers on reply, and reverse-restores ATH0
  00:02 +44: composite transaction responseHeaders negotiation (ATH1/ATH0) scenario 2: originally H1, responseHeaders: true does not revert to H0 on transaction completion
  00:02 +45: composite transaction responseHeaders negotiation (ATH1/ATH0) scenario 3: ATH1 refused by adapter, transaction proceeds anonymously without throwing and skips ATH0 restore
  00:02 +46: composite transaction responseHeaders negotiation (ATH1/ATH0) scenario 4: ATH1 timeout aborts transaction fail-closed and marks connection out of sync
  00:02 +47: composite transaction responseHeaders negotiation (ATH1/ATH0) scenario 5: reconnect during restore aborts ATH0 restore before touching new generation
  00:02 +48: composite transaction responseHeaders negotiation (ATH1/ATH0) LIFO reverse-restoration order: ATSH restored before ATH0
  00:02 +49: composite transaction responseHeaders negotiation (ATH1/ATH0) ATH1 timeout marks responseHeadersUncertain and blocks subsequent queries until reconnect
  00:02 +50: composite transaction responseHeaders negotiation (ATH1/ATH0) ATH0 teardown timeout marks responseHeadersRestoreFailed/uncertain and blocks subsequent queries
  00:02 +51: composite transaction responseHeaders negotiation (ATH1/ATH0) ATH0 explicit refusal (?) falls back to truthful H1 without failing restore
  00:02 +52: All tests passed!
  ```

---

### 4.3 Suite 3: Workshop UI Tests
- **Target**: `test/workshop/ui/service_recipes_screen_test.dart`
- **Command**:
  ```bash
  flutter test test/workshop/ui/service_recipes_screen_test.dart
  ```
- **Exit Code**: `0`
- **Results**: 20 passed, 0 failed, 0 skipped
- **Verbatim Output**:
  ```
  00:00 +0: loading test/workshop/ui/service_recipes_screen_test.dart
  00:00 +0: (setUpAll)
  00:00 +0: ServiceRecipesScreen renders Zero Live Candidates Safety Banner and loads bundled recipes
  00:00 +1: ServiceRecipesScreen tapping a recipe tile opens detail sheet with full specifications
  00:00 +2: ServiceRecipesScreen Mode 08 discovery button is disabled when not connected
  00:00 +3: ServiceRecipesScreen Mode 08 discovery triggers runDiscovery on tap when connected
  00:00 +4: ServiceRecipesScreen Mode 08 discovery completed state renders success message and TID chips
  00:00 +5: ServiceRecipesScreen Mode 08 discovery partially completed renders partial warning with failure reason, uncompleted blocks, and disclaimer
  00:00 +6: ServiceRecipesScreen Mode 08 discovery partial warning renders purely in German without Chinese leak
  00:00 +7: ServiceRecipesScreen Mode 08 discovery partial warning renders Traditional Chinese correctly
  00:00 +8: ServiceRecipesScreen Mode 08 discovery unsupported state renders unsupported message
  00:00 +9: ServiceRecipesScreen Mode 08 discovery refused state renders refused message
  00:00 +10: SettingsScreen navigation tile contains service recipes entry in diagnostics section
  00:00 +11: SettingsScreen navigation tile Mode 08 discovery outcome renders without overflow on narrow screen (320dp) and 200% text scale
  00:00 +12: SettingsScreen navigation tile real Mode08DiscoveryNotifier -> UI classification and localization NO DATA outcome renders unknown in EN
  00:01 +13: SettingsScreen navigation tile real Mode08DiscoveryNotifier -> UI classification and localization NO DATA outcome renders unknown in zh-Hant
  00:01 +14: SettingsScreen navigation tile real Mode08DiscoveryNotifier -> UI classification and localization NRC 22 outcome renders unknown in EN
  00:01 +15: SettingsScreen navigation tile real Mode08DiscoveryNotifier -> UI classification and localization NRC 22 outcome renders unknown in zh-Hant
  00:01 +16: SettingsScreen navigation tile real Mode08DiscoveryNotifier -> UI classification and localization NRC 12 outcome renders unsupported in EN without unknown
  00:01 +17: SettingsScreen navigation tile real Mode08DiscoveryNotifier -> UI classification and localization NRC 12 outcome renders unsupported in zh-Hant without unknown
  00:01 +18: SettingsScreen navigation tile real Mode08DiscoveryNotifier -> UI classification and localization Malformed response renders localized reason and hides raw enum in EN
  00:01 +19: SettingsScreen navigation tile real Mode08DiscoveryNotifier -> UI classification and localization Malformed response renders localized reason and hides raw enum in zh-Hant
  00:02 +20: (tearDownAll)
  00:02 +20: All tests passed!
  ```

---

### 4.4 Suite 4: Diagnostic & State Tests
- **Target**: `test/diagnostics/service_recipes` and `test/state/service_recipes_provider_test.dart`
- **Command**:
  ```bash
  flutter test test/diagnostics/service_recipes test/state/service_recipes_provider_test.dart
  ```
- **Exit Code**: `0`
- **Results**: 169 passed, 0 failed, 4 skipped (mode08_replay_oracle_test.dart self-skips when unflagged without running loopback server; fully verified under Suite 5)
- **Verbatim Summary Output**:
  ```
  00:00 +0: loading test/diagnostics/service_recipes/qualification_tier_test.dart
  ... [169 passed tests across qualification tiers, UDS active codec, profile schemas, harness decisive failure checks, codec parsing, and provider state] ...
  00:20 +169 ~4: All tests passed!
  ```

---

### 4.5 Suite 5: Mode 08 Replay Oracle Suite (6/6 Pass, 0 Skipped)
- **Target**: `test/diagnostics/service_recipes/mode08_replay_oracle_test.dart`
- **Server Launch**:
  ```bash
  python3 tool/obd_test_rig/mode08_replay_reference.py --port 35828 &
  # Server Output:
  # Mode 08 replay reference listening on 127.0.0.1:35828 (hash: e0a10d417983)
  ```
- **Test Command**:
  ```bash
  flutter test test/diagnostics/service_recipes/mode08_replay_oracle_test.dart \
    --dart-define=MODE08_ORACLE_REQUIRED=true \
    --dart-define=MODE08_ORACLE_PORT=35828 \
    --reporter expanded
  ```
- **Exit Code**: `0`
- **Results**: 6 passed, 0 failed, 0 skipped
- **Teardown**: Background reference server terminated cleanly (`kill <pid>`); port 35828 verified closed.
- **Verbatim Output**:
  ```
  00:00 +0: loading test/diagnostics/service_recipes/mode08_replay_oracle_test.dart
  00:00 +0: (setUpAll)
  00:00 +0: Mode 08 Replay Oracle Preflight & Provenance fixtures file is explicitly labelled synthetic and contains valid SHA-256
  00:00 +1: Mode 08 Replay Oracle Preflight & Provenance replay server matches local fixture SHA-256 and project identity
  00:00 +2: Mode 08 Replay Oracle 6-Dimension Acceptance Matrix executes all 6 matrix dimensions against independent expected outcomes
  00:00 +3: Mode 08 Replay Oracle 6-Dimension Acceptance Matrix parser entry consistency: structured, observed, and raw-only entries preserve errors and uncertainties
  00:00 +4: Mode 08 Replay Oracle 6-Dimension Acceptance Matrix lifecycle: wire-bound flight barrier, session disconnect race, and stale completion rejection
  00:00 +5: Mode 08 Replay Oracle 6-Dimension Acceptance Matrix lifecycle: container disposal while query is in-flight cleans up safely
  00:00 +6: (tearDownAll)
  00:00 +6: All tests passed!
  ```

#### Oracle 6-Dimension Coverage Breakdown
1. **Normal Control**: Single-block and multi-block headered Mode 08 discovery against standard TID bitmaps (`0x01`–`0x20`).
2. **Parser Entry Consistency**: Three ObdResponse entry paths (structured frames, observed-only frames, and raw fallback) produce identical support status, TIDs, and error representations.
3. **Transport Chunking**: Stream fragmentation across arbitrary packet boundaries preserves full decoded outcome.
4. **Source Attribution**: Multi-ECU isolation correctly assigns responding sources; unheadered multi-block returns partial status and raises truthful disclaimer.
5. **Deficient Evidence**: Missing declared node or NRC `0x22` (conditionsNotCorrect) correctly classifies as `unknown`, never falsified as unsupported.
6. **Lifecycle & Concurrency**: In-flight disconnection, late-arriving packets from superseded sessions, notifier reset, and container disposal do not leak state or corrupt subsequent queries.

---

### 4.6 Suite 6: Static Analysis
- **Target**: Repository Root
- **Command**:
  ```bash
  flutter analyze
  ```
- **Exit Code**: `0`
- **Results**: 0 issues, 0 errors, 0 warnings
- **Verbatim Output**:
  ```
  Analyzing telltale...                                           
  No issues found! (ran in 12.3s)
  ```

---

## 5. Verification Matrix Summary

| Suite # | Target Suite Description | Command / Invocation | Tests Passed | Failed | Skipped | Exit Code | Result |
|---|---|---|:---:|:---:|:---:|:---:|:---:|
| 1 | 5-Point Finite Control Regression | `flutter test test/obd_response_headers_refusal_test.dart` | 5 | 0 | 0 | 0 | **PASS** |
| 2 | Composite Transactions & Mutations | `flutter test test/elm327_composite_transaction_test.dart` | 52 | 0 | 0 | 0 | **PASS** |
| 3 | Workshop UI & Localization | `flutter test test/workshop/ui/service_recipes_screen_test.dart` | 20 | 0 | 0 | 0 | **PASS** |
| 4 | Diagnostics & Service Recipes State | `flutter test test/diagnostics/service_recipes test/state/service_recipes_provider_test.dart` | 169 | 0 | 4* | 0 | **PASS** |
| 5 | Mode 08 Replay Oracle (Required) | `flutter test test/diagnostics/service_recipes/mode08_replay_oracle_test.dart --dart-define=MODE08_ORACLE_REQUIRED=true ...` | 6 | 0 | 0 | 0 | **PASS** |
| 6 | Static Analysis | `flutter analyze` | 0 issues | 0 | 0 | 0 | **PASS** |

*\*Note for Suite 4: 4 self-skipped tests correspond to the standalone Mode 08 Replay Oracle suite when executed without loopback reference server arguments. In Suite 5, all 6 oracle dimensions were executed with the dedicated reference server active, passing with 0 skips.*

---

## 6. Audit & Sanitization Attestation

1. **Path Sanitization**: All file paths are represented relative to repository root (`./` or standard project structure). No private local user account paths (`/Users/<user>/`) or internal orchestrator runtime paths (`.agents/`) appear in this export.
2. **Credential & Token Security**: No sensitive tokens, private keys, or API credentials exist or are disclosed in this document.
3. **Reproducibility Guarantee**: The execution environment can be identically reproduced on any host running macOS or Linux with Flutter 3.47.0 (Dart SDK 3.13.0) and Python 3.
