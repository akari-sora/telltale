# WS-07 / Issue #11 Slice 5: Final Governance Closure & Evidence Mapping

This document provides the definitive closure mapping for **WS-07 / Issue #11** (*Consolidate provenance, licence and privacy validation on existing public artifacts*), closing out the 5 original acceptance criteria across Slices 1–5 and establishing the governance handoff to **Issue #105**.

---

## 1. Executive Summary & Verification Baseline

| Milestone / Slice | Target Subsystem | Key Artifacts | CI / Audit Status |
|---|---|---|---|
| **Slice 1** | Provenance Inventory & Hash Lockfile Gate | `tool/workshop/validate_provenance.py`, `docs/provenance/inventory.json` | Merged (!38), Pipeline SUCCESS |
| **Slice 2** | Four Artifact Models & Strict Scope/Class Gate | `validate_provenance.py` (scope fail-closed), 4 artifact models | Merged (!39), Pipeline SUCCESS |
| **Slice 3** | De-identification & Public Boundary Gate | `tool/workshop/public_artifact_guard.py`, `docs/privacy/public-artifact-boundary.md` | Merged (!40, !41), Pipeline SUCCESS |
| **Slice 4** | Policy Parity, Data Flow (DF01–DF10) & Backup Mapping | `docs/privacy/data-flow-inventory.json`, `validate_privacy_contract.py`, `PRIVACY.md` | Merged (!42), Pipeline #2880387073 SUCCESS |
| **Slice 5** | Export / Share Cancellation, Offline Proof & Closure | `test/privacy/share_offline_closure_test.dart`, 7-route census, S5-M1..M8 mutation suite | Dedicated Branch `feat/ws07-slice5-share-offline-closure` |

---

## 2. Five Original Acceptance Criteria Resolution Matrix

All 5 acceptance criteria originally defined in Issue #11 are mapped to deterministic automated test gates, candidate for final closure pending reviewer signoff and exact-main merge execution (A14):

### Acceptance 1: Provenance & Licence Validator Fail-Closed Gate
> *Inventory and production/package validators reject missing/changed required hashes/licences and unauthorized content for the relevant release scope; provide a replace/remove path, not a universal app shutdown.*

- **Resolution (Slices 1 & 2):**
  - Production package scope strictly enforces `powertrain-battery-bundled-third-party`.
  - Test-only scope strictly enforces `ircama-elm327-emulator-test-oracle`, `telltale-chaos-proxy-test-reference`, `telltale-freeze-frame-reference`, and `telltale-mode08-replay-reference`.
  - Required artifact class completeness is verified for all scopes (`production-package`, `test-only`, `all`).
  - Validation command:
    ```bash
    python3 tool/workshop/validate_provenance.py --scope all
    ```
  - Exit code contract: 0 = PASS, 1 = validation error, 2 = schema/syntax error.

### Acceptance 2: Canary De-identification & Public/Private Artifact Separation
> *Canary tests cover JSON/CSV/logs/segmented payloads and private/public artifact separation; exceptions cannot leak identifiers.*

- **Resolution (Slice 3):**
  - Implemented public artifact boundary (`docs/privacy/public-artifact-boundary.md`) and policy guard (`tool/workshop/public_artifact_guard.py`).
  - 100% of public fixtures contain synthetic, de-identified or consented data. Zero raw vehicle VINs, MAC addresses, GPS coordinates, customer account tokens, or absolute developer host paths exist in public fixtures.
  - Exception sanitization ensures error logging and stack traces cannot leak customer identity or vehicle credentials.
  - Validation commands:
    ```bash
    python3 -m unittest test/tool/test_public_artifact_guard.py
    flutter test test/privacy/public_artifact_boundary_contract_test.dart
    ```

### Acceptance 3: Policy Parity, Opt-In Data Flow & OS Backup Mapping
> *Current public privacy documents agree with implemented opt-in data flow, retention/deletion/revocation and OS backup behavior; completed translation-only fixes are reused.*

- **Resolution (Slice 4):**
  - Canonical inventory `docs/privacy/data-flow-inventory.json` formalizes 12 flows across 10 domains (DF01–DF10), binding 191 audited source files with exact SHA-256 digests.
  - Deterministic offline contract validator `tool/workshop/validate_privacy_contract.py` enforces 4-way document parity across `PRIVACY.md` (zh/en) and `docs/privacy.html` (zh/en).
  - Explicit platform backup mapping (`docs/privacy/evidence/native-storage-mapping.md`) documents Android Documents storage, Auto Backup domain boundaries, and Apple sandboxed containers.
  - SDK audit receipt (`docs/privacy/sdk-audit-receipt.json`) verifies zero third-party tracking, advertising, or unsolicited telemetry SDKs.
  - Validation command:
    ```bash
    python3 tool/workshop/validate_privacy_contract.py
    flutter test test/privacy/privacy_policy_contract_test.dart
    flutter test test/privacy/privacy_data_flow_contract_test.dart
    flutter test test/privacy/platform_backup_contract_test.dart
    ```

### Acceptance 4: Actual Export / Share Cancellation & Offline Local Operation
> *Test actual export/share cancellation and offline operation, plus relevant test/privacy and provenance tooling; no fake pass for provider or hardware work not run.*

- **Resolution (Slice 5):**
  - Complete 7-route census and route matrix in `test/privacy/share_offline_closure_test.dart` exercising all production export methods.
  - Offline local preparation proven via dual boundaries:
    1. Runtime `_NoNetworkHttpOverrides` sentinel actively intercepts and rejects any `dart:io` `HttpClient` creation during staging.
    2. Static source analysis enforces zero socket/provider primitives (`Socket.connect`, `RawSocket.connect`, `package:http`, `package:dio`, `launchUrl`) across all share/export preparation files.
  - 4 handoff states strictly proven:
    1. `selected`: exactly 1 platform call; staged file matches canonical bytes; ledger records `handedOffLease` with `selected`; never claims recipient received or retained.
    2. `dismissed`: exactly 1 platform call; user cancelled share sheet; outcome returns `dismissed` with `null` error; distinct from `selected` and distinct from handoff failure.
    3. `failed`: exactly 1 platform call; returns `shareHandoffFailed`; never fabricates delivery.
    4. `unavailable`: exactly 1 platform call; returns `shareHandoffFailed`; never fabricates delivery.
  - Pre-invoke safety/policy invalidation proven: 0 platform calls when safety permit is invalid (`platform.calls == 0`), returning exact bounded error with zero false receipts.
  - Indeterminate ownership & crash cuts proven: uncontained resources retain gates, requiring process-level reconstruction.
  - Validation commands:
    ```bash
    flutter test test/privacy/share_offline_closure_test.dart
    flutter test test/app_share_entry_controller_test.dart
    flutter test test/app_share_coordinator_test.dart
    ```

### Acceptance 5: Exact-Version Notices & Governance Handoff to #105
> *Deliver exact-version notices, validation commands/results and remaining specific rights/security gaps under #105.*

- **Resolution (Slice 5):**
  - Exact-version third-party dependencies and notices are verified in `docs/privacy/sdk-audit-receipt.json` and `docs/provenance/inventory.json`:
    * Bundled battery catalog: provenance verified with immutable source URL and SHA-256.
    * ELM327 test oracle (Ircama): pinned to exact version `3.0.5` in test lockfiles with CC-BY-NC-SA external-test scope restriction.
  - Governance handoff formalizes all remaining rights and security gaps into **Issue #105**.

---

## 3. Production Share Routes Census (DF06)

All seven public entry methods on `AppShareEntryController` are formally enumerated, verified, and locked:

| # | Route Method | Source Kind | MIME Type | File Extension | Subject Prefix / Pattern | Local Preparation |
|---|---|---|---|---|---|---|
| 1 | `shareTelemetryCsv` | `telemetryCsv` | `text/csv` | `.csv` | `Local OBD record <sessionId>` | Local NDJSON -> CSV Stream |
| 2 | `shareTelemetryJson` | `telemetryJson` | `application/json` | `.json` | `Local OBD record <sessionId>` | Local NDJSON -> JSON Stream |
| 3 | `shareRawTranscript` | `rawTranscript` | `text/plain` | `.txt` | `Telltale transport log <timestamp>` | In-memory transcript encoding |
| 4 | `shareRecoveredTranscript` | `recoveredTranscript` | `text/plain` | `.txt` | `Telltale transport log (last connection)` | Stored local log streaming |
| 5 | `sharePidCsv` | `pidCsv` | `text/csv` | `.csv` | `Telltale custom PID definitions` | Local PID library export |
| 6 | `shareTorqueSubsetCsv` | `pidCsv` | `text/csv` | `.csv` | `Torque-compatible PID definitions` | 8-column interchange streaming |
| 7 | `shareHumanReportCsv` | `pidCsv` | `text/csv` | `.csv` | `Telltale human PID report` | Labeled human spreadsheet |

---

## 4. Explicit Boundary Declarations & NOT_RUN Constraints

To maintain total integrity and prevent overclaiming, the following areas are formally designated as outside the scope of Issue #11 or not executed during automated gates:

1. **OBD-II Hardware Link (Wi-Fi / BLE / USB Serial):**
   - The connection between Telltale and the ELM327 adapter is a local automotive diagnostic link. It is strictly delineated from app data export and is not claimed as an app cloud/network data flow.
2. **Browser & App Store URL Launches:**
   - External links to recommended hardware or store pages use OS URL dispatch (`launchUrl`). They are explicit user-initiated actions and not part of background data flows.
3. **Real OS Backup & Cloud Restore Experiments:**
   - Platform backup behaviors (Android Auto Backup, iOS iCloud Container) are governed by OS platform configuration and sandboxing. Physical device backup/restore experiments are labeled **NOT_RUN**; CI validates configuration and path mapping contracts.
4. **Post-Handoff Recipient Retention & Remote Revocation:**
   - Once data is handed off to the OS share sheet or an external app chosen by the user, retention, further transmission, or remote deletion is outside Telltale's technical control. Telltale guarantees zero transmission prior to user handoff, and never fabricates delivery or remote revocation claims.
5. **Physical Vehicle & Hardware Dongle Qualification:**
   - Automated tests execute against loopback transports, unit mocks, and simulated test oracles. Physical vehicle road testing outside existing historical qualification rows is labeled **NOT_RUN**.
6. **Successor Transport & Protocol Issues:**
   - Modern diagnostic protocol and transport implementations are tracked in dedicated issues and remain **OPEN**:
     * **#13**: [WS-09][P1] Bounded read-only UDS (ISO 14229-1) diagnostic client on unified transport
     * **#14**: [WS-10][P1] SocketCAN/Linux native CAN transport
     * **#15**: [WS-11][P1] DoIP link (ISO 13400-2) transport implementation
     * **#16**: [WS-12][P1] Windows J2534 PassThru DLL loader and transport
     * **#54**: [COMP-2026][C05][P1] Android USB OTG FTDI/CH340/CP2102 serial transport
     * **#97**: [ELM327][P2] Flow control & ISO-TP reassembly (owned by PR #3)
     * **#101**: [BUG][P2] Bind write-audit receipts to queued operations

---

## 5. Governance Handoff to Issue #105

Subject to reviewer signoff and exact-main merge gate execution (A14), Issue #11 satisfies 5/5 of its original acceptance criteria.
Ongoing maintenance, provenance inventory audits for future dependencies, and licence review obligations are formally transferred to:
- **Issue #105: [MAINTENANCE] Migrated CI delivery, test matrix, and release governance rules**
