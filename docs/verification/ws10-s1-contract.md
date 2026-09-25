# WS-10 / Issue #14 Slice 1: Typed CAN Contracts & Bounded L0 I/O Core Specification

This document provides the architectural specification, verification matrix, and audit contract for **WS10-S1** (*Typed CAN Contracts + Bounded L0 I/O Core*), delivering the reusable in-memory L0 foundation for future Linux SocketCAN and CAN_ISOTP transport integrations without native dependencies or premature platform coupling.

---

## 1. Architectural Baseline & Separation of Concerns

WS10-S1 enforces strict boundary isolation:
1. **L0 Scope Only**: Provides strongly-typed endpoint contracts (`CanEndpoint`), canonical UDS read bindings (`CanReadBinding`), single-owner bounded scheduling (`CanIoCoordinator`), and monotonic clock deadline enforcement (`CanIoClock`).
2. **Zero Native C/Kernel Leaks**: Does not execute raw Linux SocketCAN system calls, kernel `can-isotp` sockets, or hardware bitrate manipulation. Native OS interfaces are strictly deferred to **WS10-S2**.
3. **No UDS Engine Duplication**: Does not replicate ISO 14229-1 NRC retry mechanisms, P2 timing state machines, or higher-level diagnostic flows, which remain exclusively owned by `#13` (`uds_transaction_engine.dart`).
4. **Fail-Closed Admission**: Unapproved SIDs (e.g. `0x2E`, `0x10`, `0x27`, `0x31`), multi-DID PDUs, trailing bytes, CAN FD configurations, and extended/mixed addressing modes are rejected at admission with zero wire transmissions.

---

## 2. Data Structures & Bounded Invariants

### 2.1 Endpoint Specification (`CanEndpoint`)
- **Interface & Namespace**: Validated non-empty string, strictly rejecting wildcard characters (`*`, `?`) and whitespace.
- **Identifier Width**: Enforces identical width for physical TX and RX identifiers (either both standard 11-bit or both extended 29-bit).
- **CAN FD & Addressing Modes**: Classical CAN only (`isFd: false`, `payloadLimit: 8`). Any attempt to enable CAN FD or non-normal addressing modes (`extended`, `mixed`) throws `UnsupportedError` to prevent silent downgrades.

### 2.2 Canonical Read Binding (`CanReadBinding`)
- Captured strictly via `CanReadBinding.fromUdsRequest()` from existing `DiagnosticRequest`.
- Validates canonical UDS read PDUs:
  - `0x22` ReadDataByIdentifier: strictly 3 bytes (`22 [DID_HI] [DID_LO]`).
  - `0x19 0x02` ReportDTCByStatusMask: strictly 3 bytes (`19 02 [MASK]`).
  - `0x19 0x0A` ReportSupportedDTC: strictly 2 bytes (`19 0A`).
- Caller cannot supply arbitrary raw payloads or bypass read authorization.

### 2.3 Bounded Resource Limits (`CanIoBudget`)
| Parameter | S1 Contract Limit | Violation Behavior |
|---|---|---|
| **Active Leases** | Max 1 active per coordinator | Strict FIFO serialization |
| **Queued Leases** | Max 8 queued | 9th lease immediately rejected (`CanLeaseRejected`) |
| **Application PDU** | 1 .. 4095 bytes | Length 0 or >4095 rejected |
| **Buffered Observations** | Max 32 observations | 33rd observation throws `StateError` |
| **Aggregate Buffer Bytes** | Max 4096 bytes | >4096 bytes throws `StateError` |
| **Send Attempt Ceiling** | 1 .. 4 attempts (default 1) | Attempt exceeding ceiling throws `StateError` |
| **Cleanup Budget** | 250ms | Bounded drain without extending send authorization |

---

## 3. Test Matrix (L01..L12) & Resolution Mapping

| Test ID | Obligation & Acceptance Requirement | Verifying Test Suite | Result |
|---|---|---|---|
| **L01** | 11/29-bit boundary, empty/wildcard interface, unsupported format (FD/extended addressing) cannot downgrade. | `test/diagnostics/can/can_endpoint_test.dart` | PASS |
| **L02** | Three canonical reads (`0x22`, `0x19 02`, `0x19 0A`); short/long/tail/multi-DID/tampered binding -> backend send = 0. | `test/diagnostics/can/can_io_core_test.dart` | PASS |
| **L03** | Single active lease, FIFO queue serialization, 9th queued lease rejected. | `test/diagnostics/can/can_io_core_test.dart` | PASS |
| **L04** | Foreign/released lease, lost owner, different generation domain -> zero extra calls. | `test/diagnostics/can/can_io_core_test.dart` | PASS |
| **L05** | PDU 1/7/8/4095 vs 4096; 32 vs 33 observations; 4096 vs 4097 aggregate bytes. | `test/diagnostics/can/can_io_boundary_test.dart` | PASS |
| **L06** | Monotonic clock t-1/t/t+1; queue consumes deadline; pre-send barrier across deadline; no deadline reset. | `test/diagnostics/can/can_io_core_test.dart` | PASS |
| **L07** | Prioritized termination: cancellation > retirement > timeout > transport failure. | `test/diagnostics/can/can_io_core_test.dart` | PASS |
| **L08** | Wrong/null source, wrong endpoint, late response -> rejected without polluting results. | `test/diagnostics/can/can_io_core_test.dart` | PASS |
| **L09** | Distinct attempt IDs, fixed PDU, finite send ceiling (1..4), core has zero auto-retry. | `test/diagnostics/can/can_io_core_test.dart` | PASS |
| **L10** | Truthful write disposition (`provenNotSubmitted`, `submitted`, `partialOrUnknown`), no auto-replay. | `test/diagnostics/can/can_io_core_test.dart` | PASS |
| **L11** | Bounded cleanup drain, double-close safe, old cleanup never touches new handle. | `test/diagnostics/can/can_io_core_test.dart` | PASS |
| **L12** | Machine-readable required runner and literal fixture validation (`literal_pdu_cases.json`). | `test/diagnostics/can/can_io_boundary_test.dart` | PASS |

---

## 4. Machine-Readable CI Gate Specification

- **Script**: `tool/ci/run_ws10_s1_required.py`
- **Output Artifacts**: `ci-artifacts/ws10-s1-required/result.json`
- **Exit Code Contract**:
  - `0`: Required L0 cases actually executed and all passed (zero skips/missing).
  - `1`: Assertion or product contract failure.
  - `2`: Fixture, source, or required test marker missing.
  - `3`: Internal harness, reporting, or cleanup error.
