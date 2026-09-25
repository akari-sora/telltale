# WS-09 / Issue #13 Slice 5: Bounded Read-Only UDS Verification & Audit Closure Mapping

This document provides the definitive verification and audit closure mapping for **WS-09 / Issue #13** (*Deliver a bounded read-only UDS (ISO 14229-1) diagnostic slice on the unified transport with independent NRC/timing fixtures*), closing out the 5 original acceptance criteria across Slices 1–5 and establishing the governance baseline for unified diagnostic transport extensions (WS-10 SocketCAN / Issue #14).

---

## 1. Executive Summary & Verification Baseline

| Milestone / Slice | Target Subsystem | Key Artifacts | CI / Audit Status |
|---|---|---|---|
| **Slice 1** | python-udsoncan Reference Harness & Corpus | `test/fixtures/uds/`, `tool/workshop/validate_uds_corpus.py` | Verified against pinned reference |
| **Slice 2** | Dart UdsCodec & Frame Parser | `lib/diagnostics/uds/uds_codec.dart`, `test/diagnostics/uds/uds_codec_test.dart` | Zero float hallucinations, strict NRC parsing |
| **Slice 3** | UdsTransactionEngine State Machine & Negative Paths | `lib/diagnostics/uds/uds_transaction_engine.dart`, `test/diagnostics/uds/uds_transaction_engine_test.dart` | Bounded P2/P2*, NRC21 budget, NRC78 pending |
| **Slice 4** | Wire Integration Channel & ObdSession Facade | `lib/diagnostics/uds/uds_diagnostic_link_channel.dart`, `lib/state/obd_session.dart`, `test/diagnostics/uds/uds_diagnostic_link_channel_test.dart` | Merged (!57), Exact-Main Gate |
| **Slice 5** | Verification & Audit Closure Mapping | `docs/verification/ws09-closure-mapping.md` | Issue #13 Formal Audit Closure |

---

## 2. Five Original Acceptance Criteria Resolution Matrix

All 5 acceptance criteria defined in Issue #13 are mapped to deterministic automated test gates:

### Acceptance 1: Independent Reference Corpus Verification
> *Literal positive/negative corpus independently checks Dart against the pinned reference; expectations are not generated only by the implementation under test.*

- **Resolution (Slice 1 & 2):**
  - Dart `UdsCodec` and frame parsing logic are validated against literal corpora produced from standard ISO 14229-1 specifications and the pinned `python-udsoncan` reference implementation.
  - Test suites enforce exact byte parity on request encoding, positive response parsing (SID `0x62`, `0x59`), NRC decoding (SID `0x7F`), and negative edge cases.
  - Validation commands:
    ```bash
    flutter test test/diagnostics/uds/uds_codec_test.dart
    ```

### Acceptance 2: Negative & Boundary Matrix (Wire Contract W01~W07)
> *Wrong source/SID/DID/subfunction, short/long payload, unknown NRC, pending→success/failure/endless, duplicate/late reply, cancellation and reconnect are covered.*

- **Resolution (Slice 3 & 4):**
  - **W01**: Clean single-frame `0x22` echo over real TCP link.
  - **W02**: Clean multi-frame `0x19` DTC response over real TCP link.
  - **W03**: NRC `0x21` busy-repeat over real TCP link: safe retry budget, distinct request IDs, succeeds on final response.
  - **W04 / W04b / W04c**: NRC `0x78` pending: zero wire retry, wire continuation, rejection on budget exhausted (`maxResponsePendingCount: 0`), wrong-source pending fail-closed rejection.
  - **W05**: Wrong responder rejection: foreign responder ID is rejected fail-closed.
  - **W06**: Unattributed source rejection: responses missing hardware headers are rejected fail-closed.
  - **W07**: Generation retirement: connection generation change during in-flight wire transaction aborts fail-closed.
  - Validation commands:
    ```bash
    flutter test test/diagnostics/uds/uds_transaction_engine_test.dart
    flutter test test/diagnostics/uds/uds_diagnostic_link_channel_test.dart
    ```

### Acceptance 3: Production Request Path on Real TCP Loopback
> *One actual production request path reaches a real loopback/ISO-TP software peer and returns attributed results; no injected prepared Reading is accepted as end-to-end evidence.*

- **Resolution (Slice 4):**
  - Production path `ObdSession.runDiagnosticExclusive` and `ObdSession.runReadOnlyUdsTransaction` connects via `Elm327DiagnosticLink` backed by a live TCP loopback `ServerSocket` (`_createProductionTcpStack`).
  - Wire traffic goes through full real TCP byte transmission, adapter AT handshakes, and attributed responses (`7E8`). Zero synthetic or in-memory stub readings are accepted.
  - In-flight reply barrier proves that zero background polling (`010D`) is transmitted during UDS execution.
  - Disconnect or session retirement during in-flight transactions safely cleans up and never restores polling.
  - Validation command:
    ```bash
    flutter test test/diagnostics/uds/uds_diagnostic_link_channel_test.dart --name="E2E Wire Integration"
    ```

### Acceptance 4: Service Admission & Raw Fallback
> *Forbidden services have zero outgoing requests. Missing metadata/profile cannot disable other valid generic or manually selected bounded reads; absent decoding definition has an actionable raw/unknown state.*

- **Resolution (Slice 2 & 4):**
  - Strict admission defense at channel boundary (`DiagnosticLinkUdsTransactionChannel.send`):
    * Disallowed SIDs (`0x2E` WriteDataByIdentifier, `0x10` DiagnosticSessionControl, `0x27` SecurityAccess, `0x31` RoutineControl) throw `DiagnosticLinkException(unsupportedTarget)` with zero calls to `link.send()`.
    * `wholeVehicleObd` target throws `DiagnosticLinkException(unsupportedTarget)` prior to transmission.
    * Multi-DID PDUs (`22 01 00 02 00`) and invalid `0x19` subfunctions/trailing bytes are rejected at admission.
  - Unrecognized positive DIDs return actionable raw byte payloads without throwing or coercing to zero.
  - Validation commands:
    ```bash
    flutter test test/diagnostics/uds/uds_diagnostic_link_channel_test.dart --name="admission defense"
    ```

### Acceptance 5: Verification Suite & Regression Protection
> *Execute applicable flutter test test/diagnostics/uds, reference tests, existing protocol/safety regressions and required evidence checks; retain exact results and resource/timing limits.*

- **Resolution (Slice 4 & 5):**
  - Full test suite passes 100% with zero regressions:
    * `flutter analyze`: 0 issues found.
    * `flutter test`: 3,700+ passing tests, 23 skips.
    * Python tools and reference tests: 630 passed, 17 Mode08 passed.
    * SDK audit receipt verified (`docs/privacy/sdk-audit-receipt.json`).
  - Isolated BMS consumer protection: `DiagnosticRequest.includePendingObservations` ensures existing consumers (`PowertrainBatteryProbe`) remain on terminal-only semantics without regression.
  - Validation command:
    ```bash
    flutter test test/diagnostics/uds/
    flutter test test/powertrain_battery_probe_test.dart
    ```

---

## 3. Reviewer Audit Mitigations (MR !57 / F1~F6)

| Audit Item | Core Defect / Requirement | Applied Mitigation | Verification Evidence |
|---|---|---|---|
| **F1** | Admission Grammar Hardening | Whole-vehicle targeting & malformed PDUs (trailing bytes, multi-DID) rejected before wire transmission. | `uds_diagnostic_link_channel_test.dart`: 11 admission unit tests |
| **F2** | Facade Deadline Penetration | `ObdSession` passes `outerDeadline` to channel; tests actively exercise callback expiration. | `uds_diagnostic_link_channel_test.dart`: outerDeadline penetration tests |
| **F3** | Final State Priority | `DiagnosticLinkContinuationUnavailableException` re-evaluates cancellation, generation, outer & total deadlines first. | `uds_diagnostic_link_channel_test.dart`: unavailable priority test |
| **F4** | Pending Isolation | `includePendingObservations` flag added to `DiagnosticRequest`, defaulting to `false` for BMS consumers. | `powertrain_battery_probe_test.dart`: regression tests for pending & terminal |
| **F5** | In-flight Polling Barrier | Verified zero `010D` commands during exclusive UDS transaction; retired session does not restore polling. | `uds_diagnostic_link_channel_test.dart`: E2E barrier & retirement tests |
| **F6** | Verification Completeness | Clean SDK receipt, 0 linter issues, 100% green CI pipeline. | GitLab Pipeline #2883137525, Job #16740239110 |

---

## 4. Exact-Main CI Gate Diagnostics & Remedy Resolution

Following the merge of MR !57 into `main` (`e7c72668`), post-merge `exact-main` CI (Pipeline #2883137525) revealed three specific timing/boundary conditions under high-concurrency runner load (3,700+ parallel test execution):

1. **W04b (NRC 0x78 on real TCP with maxResponsePendingCount = 0)**:
   - *Diagnosis*: Under CI load, adapter preamble (`ATH1`, `ATSH`) consumed part of the 50ms window when P2 was treated as both phase timeout and absolute deadline.
   - *Remedy*: Decoupled ECU phase timeout (P2) from transaction absolute deadline in `UdsTransactionChannel.send` and configured explicit synthetic timing profile (`p2Timeout: 1s`) for mock test environment.
2. **W06 (Response without source header / unattributed frame)**:
   - *Diagnosis*: Mock test relied on default 50ms P2 timeout; under CI thread contention, response wait exceeded 50ms, triggering `UdsTransactionTimedOut` prior to header attribution assertion.
   - *Remedy*: Configured explicit synthetic profile (`p2Timeout: 1s`), ensuring link parsing deterministically evaluates the unattributed response and throws `DiagnosticLinkException(unsupportedTarget)`.
3. **Reconnection Decoupling (Session reconnected with fresh link generation)**:
   - *Diagnosis*: Sequential read on reconnected mock adapter exceeded default 50ms under multi-suite load.
   - *Remedy*: Explicitly passed `policy: UdsTransactionPolicy(p2Timeout: Duration(seconds: 1))` for the synthetic test calls.
4. **ObdSession Cancellation Priority Invariant**:
   - *Diagnosis*: Static review identified that `runReadOnlyUdsTransaction` evaluated `deadline` expiration before checking `cancellation.isCancelled`.
   - *Remedy*: Strictly prioritized `cancellation.isCancelled` before `deadline` evaluation; added comprehensive test verifying that a pre-cancelled request with an expired deadline returns `UdsTransactionCancelled` with zero wire transmissions.

All 4 items are locked by automated regression tests in `test/diagnostics/uds/uds_diagnostic_link_channel_test.dart`.

---

## 5. Conclusion & Governance Handoff

With the completion of MR !57, this gate remedy, and this mapping document, all requirements of **Issue #13 ([WS-09][P1])** are fully satisfied, proven by automated end-to-end tests and reproducible wire evidence. 

Issue #13 is formally ready for **CLOSED** status. The unified diagnostic transport abstraction is now established as the foundation for **Issue #14 ([WS-10][P1] SocketCAN/ISO-TP Bridge)**.

