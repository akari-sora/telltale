# Verification Record: TELLTALE-L02-LIVE-ARTIFACT-GUARD

**Task ID:** TELLTALE-L02-LIVE-ARTIFACT-GUARD-R1-EVIDENCE  
**Refs:** #36, #40, #34  
**Date:** 2026-09-27  

## 1. Defect Analysis & Objective

Prior to this fix, `ArtifactOperationGate` (`lib/state/artifact_operation_gate.dart`) was an unobservable plain Dart object. While its internal fields `_active` and `_snapshot` updated synchronously on `tryAcquire` and `release`, these mutations did not emit any notification to Riverpod. Consequently, Riverpod's `languageSwitchBlockProvider` (which evaluated `!ref.watch(artifactOperationGateProvider).snapshot.isIdle`) remained cached and unaware of active artifact mutations unless manually invalidated.

In the test suite for MR !76, this was masked by subclassing `NotifyingArtifactOperationGate` and manually invoking:
```dart
appRef.invalidate(artifactOperationGateProvider);
appRef.invalidate(languageSwitchBlockProvider);
```
In real production execution, this meant:
1. When an artifact operation (such as export, record, or delete) was acquired, `languageSwitchBlockProvider` failed to transition to `LanguageSwitchBlock.artifactBusy`.
2. In-app language picker operations or asynchronous locale persistence could proceed concurrently with artifact mutations, violating runtime exclusion boundaries.

## 2. Architectural Solution

In compliance with the architecture contract specified in the execution card:
1. **Gate Owner Identity Preservation**:
   `ArtifactOperationGate` extends Flutter's `ChangeNotifier`. `artifactOperationGateProvider` remains a `Provider<ArtifactOperationGate>` that owns the gate instance for the lifetime of the root container. Its identity is never replaced or invalidated during notifications.
2. **Separation of Observable Snapshot from Coordinator Lifecycle**:
   Subscribers do not watch the gate directly to obtain state updates. Instead, `artifactOperationSnapshotProvider` (a `NotifierProvider<ArtifactOperationSnapshotNotifier, ArtifactOperationSnapshot>`) observes gate notifications and projects the current `ArtifactOperationSnapshot`. Coordinators holding `ArtifactOperationGate` (such as `AppShareCoordinator` or telemetry runtime) are never reconstructed when the gate transitions between idle and busy.
3. **Synchronous Notification on Real State Transitions**:
   `notifyListeners()` is invoked synchronously only upon successful acquisition or release. Contending acquire attempts, foreign release attempts, and reused release attempts do not produce spurious notifications.
4. **Natural Provider Reactivity**:
   `languageSwitchBlockProvider` watches `artifactOperationSnapshotProvider`. When an operation starts or finishes, `languageSwitchBlockProvider` invalidates and updates automatically without any manual invalidation calls or test fakes.

## 3. Scope & Files Changed

- `lib/state/artifact_operation_gate.dart`:
  - `ArtifactOperationGate` extends `ChangeNotifier`.
  - Added value equality (`operator ==` and `hashCode`) to `ArtifactOperationSnapshot`.
  - Added synchronous `notifyListeners()` on successful `tryAcquire` and `release`.
  - Added `artifactOperationSnapshotProvider`.
- `lib/state/language_switch_guard.dart`:
  - `languageSwitchBlockProvider` observes `ref.watch(artifactOperationSnapshotProvider).isIdle` instead of the gate provider snapshot.
- `test/l10n/l07_live_artifact_guard_test.dart`:
  - Focused verification covering the entire LG01~LG07 matrix using the real production gate without test fakes or manual invalidation.
- `docs/privacy/sdk-audit-receipt.json`:
  - Verified SHA-256 digests for modified runtime files (Exit 0 drift check).
- `docs/verification/l02-live-artifact-guard.md`:
  - Comprehensive verification documentation, exact command receipts, and mutation evidence.

## 4. Test Matrix Verification (LG01~LG07)

*Note on Test Levels*:
- **LG03** is a component-level test on the production `LanguagePicker` widget (verifying button rejection, SnackBar display, 0 SharedPreferences writes, and 0 OS setter calls while busy; plus positive control write count increment upon idle switch).
- **LG05b** is a focused coordinator integration test under isolated test conditions with a real temporary directory and real `AppShareCoordinator` executing a PID CSV export transaction.
- Full Settings and root journey end-to-end integration verification remains under MR !76.

| ID | Specification | Status | Evidence |
|---|---|---|---|
| **LG01** | Live Gate state reactivity: starts none, becomes artifactBusy upon acquire without manual invalidate, restores none on release | PASS | Verified in `test/l10n/l07_live_artifact_guard_test.dart` |
| **LG02** | Gate/coordinator identity preserved across notifications (starting with active snapshot/guard subscriptions before first acquire); active token exclusive; foreign/reused release rejected with StateError | PASS | Verified identity preservation and StateError rejections |
| **LG03** | LanguagePicker component action blocked during artifactBusy without writing prefs (0 store writes via `_CountingSharedPreferencesStore`) or calling OS setter (0 OS sets); succeeds when idle with store write counter incrementing by 1 (positive control) | PASS | Verified widget UI SnackBar, store write counter, and MethodChannel mock |
| **LG04a** | Queued setter aborts before execution if gate becomes busy while queued | PASS | Verified rollback to committed state on concurrent gate acquisition, 0 store writes |
| **LG04b** | Queued setter aborts across OS-get await if gate becomes busy: exactly 1 OS get, 0 OS set, 0 store writes (verified via `_CountingSharedPreferencesStore` with `previousStore` restoration), `controller.committed` and state stay English, no unnecessary reconcile (`needsReconcile == false`), bounded 10s wait and strict ordered async `try...finally` cleanup (unblocking get barrier, awaiting setter termination, releasing token, disposing container, restoring channel) | PASS | Verified in-flight MethodChannel await boundary, zero writes, clean rollback, and safe teardown |
| **LG05a** | Gate owner and token exclusivity persist across UI mount and unmount | PASS | Verified widget unmount, continued guard block, and clean release |
| **LG05b** | Real pending export coordinator transaction completes after UI unmount and owner self-releases: real `AppShareCoordinator` with temporary directory, controllable platform pauses at barrier, UI unmounts, gate remains busy, language switch blocked, platform barrier releases, exact payload bytes verified against literal payload (`'time,rpm,speed\n0,800,0\n'.codeUnits`), coordinator completes and self-releases its token via its outcome/cleanup path (test never manually calls `gate.release()`), provider identity remains identical throughout, gate returns to idle, language switch succeeds, bounded 10s wait, `previousStore` restoration, and strict ordered async `try...finally` cleanup (releasing barrier, awaiting `shareFuture` completion in real async, disposing container, deleting temp directory) | PASS | Verified real coordinator transaction lifecycle, staging cleanup, zero manual release, byte matching, natural idle recovery, and ordered async teardown |
| **LG06** | Contender refusal, foreign/reused release, and container disposal do not trigger duplicate notifications or leak listeners | PASS | Verified notification counts (1 on acquire, 1 on release, 0 on contenders/errors) |
| **LG07** | Positive control proving reactive bridge eliminates stale snapshot caching across all 9 operations | PASS | Verified all 9 `ArtifactOperation` variants |
| **LG08** | Terminal cleanup helper preserves resources when operation remains pending, cleans up when terminated | PASS | Verified fail-closed timeout preservation and safe terminal state cleanup |

## 5. Semantic Mutation Verification Receipt (AC E04)

To satisfy Acceptance Criterion E04, a semantic mutation was applied to verify that the reactive notification bridge is strictly required for the test suite to pass.

### Mutation Parameters & Provenance
- **Target File:** `lib/state/artifact_operation_gate.dart` (SHA-256: `e739a31af31169972bddcc2b5432669cfb2c1a4c105075c683d067ae3df5de52`)
- **Test File:** `test/l10n/l07_live_artifact_guard_test.dart` (SHA-256: `4188e303472243ceb68e074a6875d0f810a3877d5bce6ba382c26c8f3062f688`)
- **Anchor Line:** Line 90 (`tryAcquire` method)
- **Mutation Description:** Commented out `notifyListeners()` on successful token acquisition.
- **Raw Run Output Log:** Saved to repository evidence path `docs/verification/evidence/l02_mutation_run.txt`.

```diff
--- a/lib/state/artifact_operation_gate.dart
+++ b/lib/state/artifact_operation_gate.dart
@@ -87,7 +87,7 @@ class ArtifactOperationGate extends ChangeNotifier {
       ownerId: ownerId,
       operation: operation,
     );
-    notifyListeners();
+    // notifyListeners();
     return ArtifactAcquireResult.acquired(token);
   }
```

### Empirical Execution Results
1. **Baseline Control Run:**
   - Command: `fvm flutter test test/l10n/l07_live_artifact_guard_test.dart`
   - Result: 10 passed / 0 failed / 0 skipped, **Exit Code: 0**
2. **Mutant Test Run:**
   - Command: `fvm flutter test test/l10n/l07_live_artifact_guard_test.dart --reporter expanded`
   - Census: **4 passed / 6 failed / 0 skipped** (total 10 tests), **Exit Code: 1**
   - **Named Failing Tests & Provenance (line numbers from `test/l10n/l07_live_artifact_guard_test.dart`):**
     1. `LG01`: line 311 (`Expected: LanguageSwitchBlock.artifactBusy, Actual: LanguageSwitchBlock.none`)
     2. `LG02`: line 359 (`Expected: 'owner-primary', Actual: <null>`)
     3. `LG04a`: line 531 (`Expected: false, Actual: <true>`)
     4. `LG04b`: line 646 (`Expected: LanguageSwitchBlock.artifactBusy, Actual: LanguageSwitchBlock.none`)
        * *Teardown verification via SafeCleanupRunner:* Upon assertion failure at line 646, the `runGuarded` flow invokes the shared `SafeCleanupRunner`, which unblocks the OS get barrier, cleanly waits for `setTracker.awaitTermination`, executes teardown actions (including restoring `SharedPreferencesStorePlatform.instance = previousStore`) without silent catch-alls, and disposes the container without dangling barrier, unhandled error, or premature teardown.
     5. `LG06`: line 934 (`Expected: <1>, Actual: <0>`)
     6. `LG07`: line 1015 (`Expected: LanguageSwitchBlock.artifactBusy, Actual: LanguageSwitchBlock.none`)
   - **Named Passing Tests:**
     1. `LG03: LanguagePicker component action blocked during artifactBusy, unblocked when idle`
     2. `LG05a: gate owner and token exclusivity persist across UI mount and unmount`
     3. `LG05b: real pending export coordinator transaction completes after UI unmount and owner self-releases`
     4. `LG08: safe cleanup runner preserves resources when operation remains pending, cleans up when terminated, and preserves multi-failure stacks`
3. **Restoration Run:**
   - Target file restored cleanly via `try...finally`.
   - Post-restore hash: `e739a31af31169972bddcc2b5432669cfb2c1a4c105075c683d067ae3df5de52` (exact match: true).
   - Command: `fvm flutter test test/l10n/l07_live_artifact_guard_test.dart`
   - Result: 10 passed / 0 failed / 0 skipped, **Exit Code: 0**

### Shared Teardown Architecture (`SafeCleanupRunner`) & Error Preservation Contract
To address asynchronous test teardown, fail-closed resource preservation, and complete error provenance without code duplication or empty catch-alls:
- A shared `SafeCleanupRunner<T>` test helper is utilized across `LG04b`, `LG05b`, and `LG08`.
- Features `runGuarded(body: ...)` to capture and preserve primary assertion failures from the test body alongside any subsequent teardown or tracked-operation errors.
- Uses `TestFailureEntry(phase, error, stackTrace)` to retain the original error object, execution phase, and stack trace without string degradation.
- When multiple errors occur across different phases (e.g. primary test assertion failure + teardown error, primary assertion failure + pending timeout, or tracked operation error + teardown error), throws `AggregateTestFailure` containing all entries. When exactly one error occurs, it is rethrown with its exact original stack trace via `Error.throwWithStackTrace`.
- Enforces strict fail-closed resource protection: if an operation remains pending at cleanup time, throws `StateError` and refuses to release tokens, delete temporary directories, dispose live containers, or restore global platform singletons while workers are in flight.
- `LG08` directly validates all 7 branches against `SafeCleanupRunner`:
  1. **Branch 1 (Pending timeout):** Strictly fail-closed. Resources preserved, `StateError` thrown.
  2. **Branch 2 (Normal completion):** Clean up proceeds safely in order across all registered actions.
  3. **Branch 3 (Single operation error):** Resources cleaned up, original error object and stack trace faithfully preserved and rethrown.
  4. **Branch 4 (Single teardown action error):** Surfaces cleanup error with stack trace rather than swallowing silently.
  5. **Branch 5 (Operation error + teardown error):** `AggregateTestFailure` captures both original errors and respective stack traces.
  6. **Branch 6 (Primary body assertion + teardown error):** `AggregateTestFailure` retains the primary assertion failure without allowing teardown failure to mask it.
  7. **Branch 7 (Primary body assertion + pending timeout):** `AggregateTestFailure` retains primary assertion, enforces fail-closed resource retention (0 cleanup actions executed), and records pending timeout failure.

**Conclusion:** The mutation unambiguously demonstrates that the reactive notification path is essential for language switch gating and is actively defended by the test suite across 6 distinct test cases with robust fail-closed async teardown and complete error provenance.

## 6. Verification Commands & Results

- `fvm flutter analyze`: 0 issues found.
- `fvm flutter test test/l10n/l07_live_artifact_guard_test.dart --reporter expanded`: 10/10 tests PASS.
- `python3 tool/workshop/validate_privacy_contract.py --repo-root .`: Exit 0 (12 flows, 12 claims, 0 errors).
- `fvm flutter test test/app_share_entry_controller_test.dart --reporter expanded`: 13/13 tests PASS.
- `python3 -m unittest discover -s test/tool -p 'test_*.py'`: 707/707 OK.
- `python3 -m unittest discover -s tool/i18n_verify -p 'test_*.py'`: 17/17 OK.
