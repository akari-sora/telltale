# Issue #101 Closeout: Bind Write-Audit Receipts to Queued Operation, Not Global Window

- **Task ID**: `TELLTALE-101-OPERATION-RECEIPT-CLOSEOUT`
- **Branch**: `test/obd101-operation-receipt-closeout`
- **Primary Issue**: #101 (`[BUG][P2] Bind write-audit receipts to the queued operation, not a global window`)
- **Parent Issue**: Finite audit #100
- **Issue References**: Refs #101, #100 (Do not prematurely close #101)
- **Baseline Commit**: `c39efcd270fba83128ffd84db0b26b1cb9a8efae`
- **Baseline Tree SHA**: `4797f670dbd7486df49c194442eb4d27e1fd7c37`
- **Exact-Main CI Status**: Pipeline #2886819993 (Job #16762204791 `full-gate`, 1503s, 100% SUCCESS)

---

## 1. Objective, Boundaries & Scope Governance

### 1.1 Objective
Reconcile and close out Issue #101 by:
1. Reconciling the historical repair commit (`4c575f634040ef3db546063fdc73f69f343fc059`) with the active production source (`974a4fc78838cbb9c5c10b14b1331e5e57a58d61` on `c39efcd2`).
2. Verifying that the existing client-owned, single-use `ElmWriteAudit` tokens provide complete per-operation write receipt isolation without constructing a redundant second receipt manager.
3. Establishing and executing the W101-01 through W101-12 acceptance test matrix and M101-1 through M101-5 semantic mutation proofs.
4. Documenting explicit closure evidence mapped to the four finite acceptance criteria of Issue #101.

### 1.2 Non-Goals
- No root-cause speculation or premature changes for Issue #106 (disconnects after voltage reading on slow buses).
- No changes to `fastMode` calculation or bus discovery algorithms.
- No new diagnostic recipes, raw, manual, or remote execution endpoints.
- No new ECU actuation permissions, and receipts are never treated as user consent.
- No persistent audit database expansions or schema migrations.

### 1.3 Whitelist & Denylist
- **Default Whitelist**:
  - `test/write_audit_window_test.dart`
  - `test/support/fake_elm327.dart` (bounded barriers, faults, wire observation only)
  - `test/mode01_batch_observation_test.dart` (existing consumer scope)
  - `docs/verification/issue101-operation-receipt-closeout.md`
- **Conditional Whitelist** (opened only if red test demonstrates production gap):
  - `lib/obd/elm327_client.dart`
  - `lib/obd/polling_engine.dart`
  - `lib/obd/transport/obd_transport.dart`
- **Denylist**:
  - No global timeout, retry, or watchdog relaxation.
  - No deletion of safety guards or fail-closed validations.
  - No production mock or fake substitution.
  - No Android/iOS plugin or SDK version upgrades.
  - No live vehicle, physical adapter, BLE, or Wear experiments.

---

## 2. Four Finite Acceptance Criteria Resolution

| Issue #101 Acceptance Criterion | Target Contract | Verification Strategy | Status |
|---|---|---|---|
| **A1: Source & Repair Disposition Reconciliation** | `ElmWriteAudit`, `beginWriteAudit`, `_claimWriteAudit`, `wroteSinceAudit` | Reconcile historical commit `4c575f63` against `974a4fc7` on `c39efcd2`. Trace line numbers and call sites. | **RESOLVED** |
| **A2: Interleaving, Token Life-cycle & Retirement** | Same/different command isolation, foreign/reused token rejection, generation/epoch cancellation | W101-02, W101-03, W101-04, W101-05, W101-06, W101-09, W101-11 test coverage. | **RESOLVED** |
| **A3: Conservative Wire Count & Zero-byte Refusal** | Transport precondition refusal rollback, partial/unknown write conservatism, no unauthorized send | W101-07, W101-08, W101-10, W101-11 wire observation. | **RESOLVED** |
| **A4: Test Suites, Exit Codes & Artifact Hashes** | Write-audit, clear, polling, lifecycle suites pass with 0 skips and clean teardown | Full gate test replay, JSON reporter execution logs, SHA-256 evidence. | **IN_REVIEW** (Software verification clean; pending reviewer SIGNED-OFF and merge) |

---

## 3. W101 Acceptance Matrix

| Case ID | Objective | Expected Observable Behavior | Status |
|---|---|---|---|
| **W101-01** | Historical repair & source reconciliation | Validate `ElmWriteAudit` token contract and `Elm327Client` receipt methods. | **PASS** |
| **W101-02** | Same/different command A/B interleaving | Operations A and B interleaved (same command '04' and distinct '0100'/'010C') record strictly to their own receipt without cross-pollution. In-flight barrier check proves queued B has receipt `false` while A is on wire. | **PASS** |
| **W101-03** | Queued operation not dispatched (barrier proof) | Blocker holds wire; operation B queued has `wroteSinceAudit == false` (transient, not terminal unsent). Once released, only B records B's command. | **PASS** |
| **W101-04** | Single-use token enforcement | Reusing a token while queued, after completion, or after legacy synchronous refusal throws `ArgumentError` synchronously without wire transmission. Fresh token succeeds. | **PASS** |
| **W101-05** | Foreign token rejection & zero contamination | Passing client A's token to client B throws `ArgumentError` on send and inspect. Client A's receipt remains unconsumed and uncontaminated. | **PASS** |
| **W101-06** | Pre-handoff retirement & generation isolation | In-queue retirement: when owner transmit permission is revoked while queued, dequeue triggers `OperationRetiredException`, zero bytes enter wire, receipt is `false`, token consumed and does not resurrect. | **PASS** |
| **W101-07** | Proven-zero rollback on `WriteRefusedException` | When transport throws `WriteRefusedException` (0 bytes accepted), tentative command is rolled back from receipt. Prior writes on receipt preserved. Token remains consumed. | **PASS** |
| **W101-08** | Partial & unknown write conservatism | Spy transport verifies partial write yields `writeCalls == 1` (0 replay), `acceptedBytes > 0`, `completeCommands == 0`, and conservative receipt `true`. Write completion stall maintains conservative receipt. | **PASS** |
| **W101-09** | Caller wrapper timeout isolation | Caller `Future.timeout` expiring does not cancel or corrupt low-level transport future. Op 2 queued during Op 1 delayed reply completes with distinct semantic response and attribution (04 positive payload '44' vs ATRV '13.9V'), ordered dispatch (04 before ATRV), and zero receipt borrowing. | **PASS** |
| **W101-10** | Setup / service / restore boundaries | Header setup refusal (`ATH1`) leaves service command ('04') unsent. Composite service completion and header restore (`ATH0`) verified via response barrier: `client.headersOn` remains true until restore ACK is processed, and exact transmission sequence verified: `ATH1 -> ATSH -> 04 -> ATH0`. | **PASS** |
| **W101-11** | Real consumer engine verification | `PollingEngine.clearDtcs()` correctly distinguishes retry-harm vs safe-retry based on receipt. On the same session and `dtcScanProvider` flow, real Mode 01 polling (`010C`) is executed and verified with valid telemetry readings, producing 0 extra Mode 04 commands, while the same `clearRepeatWouldHarm` latch remains firmly retained. | **PASS** |
| **W101-12** | Gate and resource cleanup | All 30 test cases pass with 0 skips, each test cleanly disconnects, no leaked timers, streams, or dangling futures. | **PASS** |

---

## 4. Semantic Mutations Matrix (M101-1 ~ M101-5)

- **Control Source Baseline**: Production source code in `lib/` is bit-identical to `c39efcd270fba83128ffd84db0b26b1cb9a8efae` (0 diff in `lib/`).
- **Test Overlay**: `test/write_audit_window_test.dart` at HEAD revision (30/30 PASS).
- **Patch Format Integrity**: All patches below are standard unified diffs validated with `git apply --numstat` (Exit 0).

| Mutation ID | Injected Mutation Description | Target Cases | Expected Outcome | Actual Result |
|---|---|---|---|---|
| **M101-1** | Pollute receipt with another operation's write of same command | W101-02, W101-03 | FAIL (Target tests fail) | **KILLED** (`W101-02` failed: `Expected: false, Actual: <true>`, Exit 1) |
| **M101-2** | Remove single-use or foreign-client check | W101-04, W101-05 | FAIL (Target tests fail) | **KILLED** (`W101-04` failed: `Expected: throws ArgumentError, Actual: returned Future`, Exit 1) |
| **M101-3** | Record only after write completes (losing pending/partial evidence) | W101-03, W101-08 | FAIL (Target tests fail) | **KILLED** (`W101-08` failed: `Expected: true, Actual: <false>`, Exit 1) |
| **M101-4** | Treat general transport error/timeout as zero-byte rollback | W101-08 | FAIL (Target tests fail) | **KILLED** (`W101-08` failed: `Expected: true, Actual: <false>`, Exit 1) |
| **M101-5** | Consumer treats unsettled false as unsent or allows later poll to replace clear evidence | W101-03, W101-11 | FAIL (Target tests fail) | **KILLED** (`W101-11` failed: `Expected: repeatWouldHarm: true, Actual: <false>`, Exit 1) |

---

## 5. Verification Results & Execution Evidence

### 5.1 Test Suite Replay
1. **Target Suite**: `test/write_audit_window_test.dart` (30 tests: 18 legacy regression + 12 W101 matrix):
   - Command: `~/fvm/versions/3.47.0/bin/flutter test test/write_audit_window_test.dart`
   - Result: `All tests passed! (30/30 PASS, 0 failures, 0 skips)`
2. **Focused Regression Suite** (5 test files, 282 tests):
   - Command: `~/fvm/versions/3.47.0/bin/flutter test test/write_audit_window_test.dart test/mode01_batch_observation_test.dart test/lifecycle_test.dart test/obd_session_test.dart test/round5_triggers_test.dart`
   - Result: `All tests passed! (282/282 PASS, 0 failures, 0 skips)`
3. **Static Analysis**:
   - Command: `~/fvm/versions/3.47.0/bin/flutter analyze`
   - Result: `No issues found! (0 warnings, 0 errors, ran in 10.3s)`
4. **Privacy Contract Gate**:
   - Command: `python3 tool/workshop/validate_privacy_contract.py --repo-root .`
   - Result: `[PASS] Privacy Contract Validation (Exit 0, 12 flows, 12 claims, 10 domains, 0 errors)`

### 5.2 Semantic Mutation Replay Cards (R80-3 Deliverable)

#### M101-1 Replay Card
- **Control Baseline**: Production source `lib/obd/elm327_client.dart` (`c39efcd2`), Test overlay `test/write_audit_window_test.dart`
- **Target Test**: `W101-02: same-command and different-command A/B interleaving isolation`
- **Diff Patch** (`git apply --numstat` validated: `1 1 lib/obd/elm327_client.dart`):
  ```diff
  diff --git a/lib/obd/elm327_client.dart b/lib/obd/elm327_client.dart
  index 455e69e..6b81dc7 100644
  --- a/lib/obd/elm327_client.dart
  +++ b/lib/obd/elm327_client.dart
  @@ -5356,5 +5356,5 @@ class Elm327Client {
         throw ArgumentError('The write audit belongs to another client.');
       }
       final key = command.trim().toUpperCase().replaceAll(' ', '');
  -    return audit._commands.contains(key);
  +    return audit._commands.contains(key) || _pendingCommand == key;
     }
  ```
- **Execution & Raw Failure**:
  - Command: `flutter test test/write_audit_window_test.dart --name="W101-02"`
  - Exit Code: `1`
  - Output: `Expected: false, Actual: <true> at test/write_audit_window_test.dart:408:9`
- **Restoration Verification**:
  - File Restore: `git checkout lib/obd/elm327_client.dart` (Exit Code `0`)
  - Working Tree Integrity: `git status --porcelain lib/obd/elm327_client.dart` (Clean, Exit Code `0`)
  - Post-Restore Suite Verification: `flutter test test/write_audit_window_test.dart --name="W101-02"` (Exit Code `0`, 1 passed, 0 failed, PASS)

#### M101-2 Replay Card
- **Control Baseline**: Production source `lib/obd/elm327_client.dart` (`c39efcd2`), Test overlay `test/write_audit_window_test.dart`
- **Target Test**: `W101-04: single-use token rejection across queued, completed, and synchronous refusal states`
- **Diff Patch** (`git apply --numstat` validated: `1 1 lib/obd/elm327_client.dart`):
  ```diff
  diff --git a/lib/obd/elm327_client.dart b/lib/obd/elm327_client.dart
  index 455e69e..8679f29 100644
  --- a/lib/obd/elm327_client.dart
  +++ b/lib/obd/elm327_client.dart
  @@ -5344,5 +5344,5 @@ class Elm327Client {
       if (audit == null) return;
  -    if (!identical(audit._client, this) || audit._claimed) {
  +    if (!identical(audit._client, this)) {
         throw ArgumentError('A write audit belongs to one send on its client.');
       }
       audit._claimed = true;
  ```
- **Execution & Raw Failure**:
  - Command: `flutter test test/write_audit_window_test.dart --name="W101-04"`
  - Exit Code: `1`
  - Output: `Expected: throws ArgumentError, Actual: returned Future at test/write_audit_window_test.dart:487:9`
- **Restoration Verification**:
  - File Restore: `git checkout lib/obd/elm327_client.dart` (Exit Code `0`)
  - Working Tree Integrity: `git status --porcelain lib/obd/elm327_client.dart` (Clean, Exit Code `0`)
  - Post-Restore Suite Verification: `flutter test test/write_audit_window_test.dart --name="W101-04"` (Exit Code `0`, 1 passed, 0 failed, PASS)

#### M101-3 Replay Card
- **Control Baseline**: Production source `lib/obd/elm327_client.dart` (`c39efcd2`), Test overlay `test/write_audit_window_test.dart`
- **Target Test**: `W101-08: partial byte and write completion stall maintain conservative evidence with zero replay`
- **Diff Patch** (`git apply --numstat` validated: `2 1 lib/obd/elm327_client.dart`):
  ```diff
  diff --git a/lib/obd/elm327_client.dart b/lib/obd/elm327_client.dart
  index 37522c84..e84bd8ba 100644
  --- a/lib/obd/elm327_client.dart
  +++ b/lib/obd/elm327_client.dart
  @@ -1504,7 +1504,7 @@ class Elm327Client {
         // 04 that may have reached the adapter must not be offered as a free
         // retry, and one that provably did not must not be locked away — so the
         // fact is recorded where it is known instead of guessed where it is not.
  -      writeAudit?._commands.add(normalised);
  +      // writeAudit?._commands.add(normalised);
         // Recorded before the write, not after it. A write that never returns is
         // the case worth having on record, and recording on success would be the
         // one time the transcript stays silent.
  @@ -1523,6 +1523,7 @@ class Elm327Client {
           requestedProtocol = normalised.substring(4);
         }
         await transport.write(wire).timeout(_withinDeadline(writeTimeout));
  +      writeAudit?._commands.add(normalised);
       } on Object catch (e) {
         // …and taken back only when the transport says it never started.
         //
  ```
- **Execution & Raw Failure**:
  - Command: `flutter test test/write_audit_window_test.dart --name="W101-08"`
  - Exit Code: `1`
  - Output: `Expected: true, Actual: <false> at test/write_audit_window_test.dart:748:9`
- **Restoration Verification**:
  - File Restore: `git checkout lib/obd/elm327_client.dart` (Exit Code `0`)
  - Working Tree Integrity: `git status --porcelain lib/obd/elm327_client.dart` (Clean, Exit Code `0`)
  - Post-Restore Suite Verification: `flutter test test/write_audit_window_test.dart --name="W101-08"` (Exit Code `0`, 1 passed, 0 failed, PASS)

#### M101-4 Replay Card
- **Control Baseline**: Production source `lib/obd/elm327_client.dart` (`c39efcd2`), Test overlay `test/write_audit_window_test.dart`
- **Target Test**: `W101-08: partial byte and write completion stall maintain conservative evidence with zero replay`
- **Diff Patch** (`git apply --numstat` validated: `1 1 lib/obd/elm327_client.dart`):
  ```diff
  diff --git a/lib/obd/elm327_client.dart b/lib/obd/elm327_client.dart
  index 37522c84..3d177432 100644
  --- a/lib/obd/elm327_client.dart
  +++ b/lib/obd/elm327_client.dart
  @@ -1535,7 +1535,7 @@ class Elm327Client {
         // Without this, a `04` rejected at that guard was reported as sent, so
         // the clear locked its button over a Mode 04 that provably never
         // happened and asked for a rescan that could settle nothing.
  -      if (e is WriteRefusedException) {
  +      if (e is Object) {
           if (!previouslyWritten) writeAudit?._commands.remove(normalised);
           requestedProtocol = previousRequested;
         }
  ```
- **Execution & Raw Failure**:
  - Command: `flutter test test/write_audit_window_test.dart --name="W101-08"`
  - Exit Code: `1`
  - Output: `Expected: true, Actual: <false> at test/write_audit_window_test.dart:748:9`
- **Restoration Verification**:
  - File Restore: `git checkout lib/obd/elm327_client.dart` (Exit Code `0`)
  - Working Tree Integrity: `git status --porcelain lib/obd/elm327_client.dart` (Clean, Exit Code `0`)
  - Post-Restore Suite Verification: `flutter test test/write_audit_window_test.dart --name="W101-08"` (Exit Code `0`, 1 passed, 0 failed, PASS)

#### M101-5 Replay Card
- **Control Baseline**: Production source `lib/obd/polling_engine.dart` (`c39efcd2`), Test overlay `test/write_audit_window_test.dart`
- **Target Test**: `W101-11: real consumer engine verification (clear retry lock, subsequent polling observation, and latch retention)`
- **Diff Patch** (`git apply --numstat` validated: `1 1 lib/obd/polling_engine.dart`):
  ```diff
  diff --git a/lib/obd/polling_engine.dart b/lib/obd/polling_engine.dart
  index 9aabce6d..4e2a1f56 100644
  --- a/lib/obd/polling_engine.dart
  +++ b/lib/obd/polling_engine.dart
  @@ -2548,7 +2548,7 @@ class PollingEngine {
         // reached the transport then `04` never went out. Asked as a window
         // rather than as "the last write", because the header restore runs even
         // when the service write failed.
  -      final reached = client.wroteSinceAudit(clearAudit, '04');
  +      final reached = false;
         throw DtcReadException(
           reached
               ? 'The clear was sent, then the connection dropped, so it is not known whether the vehicle cleared. '
  ```
- **Execution & Raw Failure**:
  - Command: `flutter test test/write_audit_window_test.dart --name="W101-11"`
  - Exit Code: `1`
  - Output: `Expected: throws DtcReadException with repeatWouldHarm: true, Actual: repeatWouldHarm: <false> at test/write_audit_window_test.dart:996:15`
- **Restoration Verification**:
  - File Restore: `git checkout lib/obd/polling_engine.dart` (Exit Code `0`)
  - Working Tree Integrity: `git status --porcelain lib/obd/polling_engine.dart` (Clean, Exit Code `0`)
  - Post-Restore Suite Verification: `flutter test test/write_audit_window_test.dart --name="W101-11"` (Exit Code `0`, 1 passed, 0 failed, PASS)

---

## 6. Detailed Acceptance Mapping

### 6.1 A1: Source & Repair Disposition Reconciliation
- **Historical Commit**: `4c575f634040ef3db546063fdc73f69f343fc059` (`fix(obd): bind write receipts to individual operations`)
- **Active Production Carrier**: Commit `974a4fc78838cbb9c5c10b14b1331e5e57a58d61` present on `c39efcd270fba83128ffd84db0b26b1cb9a8efae`
- **Reconciliation Audit**:
  - `ElmWriteAudit`: Defined as a `final class` in `lib/obd/elm327_client.dart`. Private constructor `ElmWriteAudit._(this._client)` prevents caller fabrication.
  - `beginWriteAudit()`: `lib/obd/elm327_client.dart` creates token bound to `this`.
  - `_claimWriteAudit()`: `lib/obd/elm327_client.dart` validates `identical(audit._client, this)` and `!audit._claimed`, consuming `audit._claimed = true`.
  - `wroteSinceAudit()`: `lib/obd/elm327_client.dart` verifies client identity and checks `audit._commands.contains(key)`.
  - Enqueue Call Sites: `send`, `sendAddressed`, `sendGlobal`.
  - Consumer Call Sites: `PollingEngine.clearDtcs()` and `PollingEngine._pollBatch`.
  - **Verdict**: Fully reconciled. No second receipt manager needed or created.

### 6.2 A2: Interleaving, Token Life-cycle & Retirement
- Verified by W101-02 (same/different command interleaving with wire-barrier check), W101-03 (barrier proof), W101-04 (single-use), W101-05 (foreign token rejection), W101-06 (in-queue pre-handoff retirement), W101-09 (timeout and delayed reply queueing isolation), and W101-11 (consumer engine).

### 6.3 A3: Conservative Wire Count & Zero-byte Refusal
- Verified by W101-07 (proven-zero rollback on `WriteRefusedException` with prior writes preserved and token consumed), W101-08 (partial/unknown write conservatism with `writeCalls == 1`, `acceptedBytes > 0`, `completeCommands == 0`, and write completion stall), W101-10 (setup/service/restore separation with true response barrier convergence), and W101-11 (clear lock latch prevents unsynchronized clear retry dispatch at the consumer layer across live polling cycles).

### 6.4 A4: Test Suites, Exit Codes & Artifact Hashes
- 30/30 write audit suite tests pass, 282/282 focused regression tests pass, analyze 0 issues, privacy contract exit 0. Zero skipped tests.
