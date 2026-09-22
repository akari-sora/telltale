# Architecture Decision Record: DiagnosticLink Abstraction and Sidecar Evaluation

- **Status**: Accepted for the existing ELM-backed architecture only
- **Parent Issue**: [#9](https://gitlab.com/aa22396584/telltale/-/work_items/9)
- **Software Baseline**: `ccb3281c309ea417a90e80008e6dc0137cf1d42f`
- **Date**: 2026-09-22
- **Scope**: Evaluates transport boundaries and process topology for diagnostic communications in Telltale. Retains in-process Native Dart for existing ELM-backed operations while evaluating out-of-process helper architectures (sidecars). This ADR does not choose implementations for #14, #15, or #16.

---

## 1. Context

Telltale is a multiplatform vehicle telemetry and diagnostics application built on Flutter and Dart (`torque_obd` / `com.cbstudio.telltale`).

The diagnostic foundation has historically communicated through an ASCII ELM327 protocol adapter stack across four supported transport media:
1. Bluetooth Classic (RFCOMM / SPP);
2. Bluetooth Low Energy (GATT characteristic streaming);
3. Wi-Fi (TCP socket to port 35000 / custom port);
4. Demo Loopback (deterministic synthetic vehicle simulation).

Across Slices 1–4 of Issue #9, a typed, half-duplex application boundary (`DiagnosticLink`) was introduced above the existing ELM stack:
- **Slice 1**: Defined typed application messages and PDUs (`DiagnosticRequest`, `DiagnosticResponse`, `ApplicationPdu`, `DiagnosticMessage`), transport capabilities (`DiagnosticCapability`), target addressing (`DiagnosticTarget`), connection generations, deadlines, and cooperative cancellation tokens. Migrated responder discovery (`PollingEngine.discoverResponders()`).
- **Slice 2**: Introduced a shared half-duplex ownership authority (`DiagnosticLinkOwnershipAuthority`, `DiagnosticOwnership`, `DiagnosticOwnershipMode.oneShot`), arbitrating access between continuous background polling and one-shot diagnostic inquiries, enforcing link retirement upon disconnection.
- **Slice 3**: Extended targeting with typed physical CAN addressing (`DiagnosticTarget.physicalCan`), migrating experimental BMS battery diagnostic probing.
- **Slice 4**: Implemented exclusive link ownership (`DiagnosticOwnershipMode.exclusive`) for non-actuating Mode 08 system capability discovery (`Mode08DiscoveryService`), guaranteeing background telemetry freeze with wire-zero interleaving proof.

Crucially, the ELM327 byte-stream protocol is an ASCII AT-command wrapper over vehicle buses. It does **not** expose raw CAN arbitration IDs, unformatted ISO-TP PDUs, raw UDS services, or Ethernet DoIP frames. As community interest emerged regarding advanced diagnostic transports (such as Linux SocketCAN, Ethernet DoIP, and Windows J2534 Pass-Thru), architectural questions arose regarding whether non-ELM transports or even existing ELM communication should be delegated to an external, out-of-process helper daemon (sidecar).

---

## 2. Decision

1. **Existing ELM path: Native Dart / Flutter remains adopted.**
   The existing ELM327 transport layer, ASCII framing, transaction scheduling, lifecycle ownership, and `DiagnosticLink` abstraction remain executing entirely in-process within the Native Dart/Flutter engine runtime across all supported desktop and mobile platforms.

2. **Desktop sidecar for the existing ELM path: NOT ADOPTED.**
   Introducing an external out-of-process daemon, broker, Python runtime, or local RPC sidecar to mediate existing ELM327 communications (Classic, BLE, Wi-Fi, or Demo) introduces unnecessary IPC overhead, packaging complexity, failure surface, and security attack vectors. No measured benefit has been demonstrated that would justify migrating the existing ELM path to a sidecar. It is explicitly rejected.

3. **Future sidecar: candidate-only and issue-owned; requires independent evidence before adoption.**
   An out-of-process architecture is not adopted globally. It remains an unmeasured candidate whose adoption can only be evaluated and justified on an issue-by-issue basis where process isolation or foreign vendor ABIs are intrinsic to the requirement (such as Windows J2534). Any future adoption must satisfy the mandatory security and benchmark gates defined in Section 6.

*Explicit negative declaration*: This ADR does **not** claim that Native Dart is universally superior for every imaginable automotive protocol, nor does it decree that all future diagnostic links must be Dart. Each future transport must be evaluated against measured evidence.

---

## 3. Measured / Verified Evidence Ledger

All entries in this ledger represent verified facts backed by repository artifacts, reproducible test suites, or authoritative CI pipeline executions.

| Evidence Item | Classification | Verification Artifact / Provenance | Measured Findings & Explicit Scope Boundaries |
|---|---|---|---|
| **Software Baseline & CI Gate** | `MEASURED / VERIFIED` | GitLab Pipeline `#2871335221` / Job `#16653856159` (`full-gate`, 686s); Commit `ccb3281c309ea417a90e80008e6dc0137cf1d42f` | `flutter analyze` 0 issues; Python tools 425 pass; Python Mode08 17 pass; Flutter 3,400 passed / 23 skipped; required Mode 08 replay oracle PASS; 3 split APKs generated. |
| **Native Dart ELM Functional Path** | `MEASURED / VERIFIED` | `test/emulator_integration_test.dart`<br>`tool/desktop_wifi_oracle/run.sh`<br>`docs/verification/rig-matrix.md` | Proves in-process Dart `WifiTransport` communicates over TCP loopback to Ircama ELM327 simulator (port 35000), executing connection handshake, vehicle VIN query, live PID queries (RPM/speed), and telemetry record export. *Boundary*: Evidence is established on emulator, loopback, and test rigs; it does not claim Mode 08 discovery or freeze-frame execution (which are verified by separate focused suites), nor does it constitute a universal compatibility claim across all physical ELM clones or vehicle ECUs. |
| **Multiplatform Transport Compatibility** | `MEASURED / VERIFIED` | `docs/platform-support.md` | Honestly classifies host platform transport maturity without flattening:<br>• **pass**: Android (BT Classic, BLE, Wi-Fi), iOS (Wi-Fi, BLE, Demo), macOS (Wi-Fi, Demo);<br>• **wired**: macOS Classic (IOBluetooth RFCOMM), Windows Classic (SetupAPI COM), Linux Classic (BlueZ RFCOMM TTY);<br>• **OS-blocked**: iOS Bluetooth Classic (no third-party SPP API);<br>• **deferred**: Desktop BLE / signing workflows. |
| **Desktop Standalone Packaging Shape** | `MEASURED / VERIFIED` | `tool/packaging/macos_dmg.sh`<br>`tool/packaging/windows_zip.sh`<br>`tool/packaging/linux_tarball.sh` | Desktop artifacts are self-contained Flutter application bundles (.dmg, .zip, .tar.gz) without any secondary daemon, Python interpreter, or sidecar executable. Platform signing and notarization remain deferred where noted in platform documentation. |
| **Physical Field Verification Boundary** | `MEASURED / VERIFIED` | `docs/platform-support.md`<br>`docs/verification/rig-matrix.md` | Bounded physical ELM field verification on Toyota GT86 using purchased BLE adapter (`docs/verification/rig-matrix.md`). *Boundary*: Physical field observation is bounded to Bluetooth Low Energy; Classic phone rig operates across a mocked native boundary and does not qualify Windows, Linux, or macOS Classic/BLE or unverified vehicle makes. |
| **Sidecar Performance Metrics** | `NOT MEASURED` | None (No sidecar prototype exists for ELM) | Process startup latency, IPC RTT overhead, RSS increase, and binary size inflation for an ELM sidecar are unmeasured and zero numeric claims are fabricated. |

---

## 4. Candidate Ledger for Future Transports

Future diagnostic links tracked under separate issues represent candidates with differing architectural constraints:

| Candidate Issue | Candidate Transport | Candidate Architecture | Reasons for Consideration | Current Knowledge | Explicitly NOT MEASURED | Status |
|---|---|---|---|---|---|---|
| **#14** | SocketCAN / ISO-TP | Native Dart FFI vs. Out-of-process C/Python daemon | Linux kernel provides native `AF_CAN` and `can-isotp` socket interfaces; permission and interface requirements remain to be evaluated by #14. | Linux socket programming can be bound via Dart FFI or an external helper daemon. | Startup latency delta, IPC overhead, package size impact on Linux tarball. | `CANDIDATE / NOT ADOPTED` |
| **#15** | Diagnostics over IP (DoIP) | Native Dart Socket vs. Sidecar broker | ISO 13400-2 uses standard TCP and UDP IP networking. | Native Dart `RawSocket` and `Socket` primitives handle TCP/UDP natively without kernel drivers or elevated privileges. | High-throughput UDS frame rates, socket buffering latency under severe network load. | `CANDIDATE / NOT ADOPTED` |
| **#16** | Windows J2534 Pass-Thru | Out-of-process 32/64-bit Broker | #16 explicitly addresses 32-bit to 64-bit architecture mismatch and vendor DLL crash isolation for proprietary J2534 PassThru binaries. | Process isolation protects main GUI from vendor driver crashes and enables 32-bit to 64-bit IPC thunking. | IPC round-trip latency (p50/p95), broker cold startup latency, crash recovery latency, binary size delta. | `CANDIDATE / NOT ADOPTED` |

---

## 5. Architectural Cost Matrix

Comparison between the adopted in-process Native Dart architecture and an out-of-process helper sidecar:

| Architectural Dimension | Native Dart (ADOPTED for ELM) | Out-of-process Sidecar (CANDIDATE ONLY) | Cost Classification |
|---|---|---|---|
| **Process Lifecycle** | `[Measured Fact]` Unified lifecycle: starts and terminates synchronously with Flutter app process. | `[Architectural Consequence]` Requires daemon supervision, process spawning, PID tracking, orphan cleanup, and SIGKILL handling. | Architectural Consequence |
| **Process / Memory Isolation** | `[Architectural Consequence]` Shared address space: a native plugin crash (SIGSEGV) brings down entire application. | `[Architectural Consequence]` Fault isolation: helper crash does not terminate main GUI process; worker can be restarted. | Architectural Consequence |
| **IPC & Serialization Overhead** | `[Measured Fact]` Zero IPC: function calls and stream controllers pass typed Dart memory references directly. | `[Architectural Consequence]` Inter-process communication over UDS, named pipes, or localhost TCP requires serialization, deserialization, context switches, and kernel buffers. | Architectural Consequence |
| **Authentication & Authorization** | `[Measured Fact]` Local process security boundary: internal Dart memory references cannot be snooped or injected by unprivileged local users without debugger attachment. | `[Architectural Consequence]` Local IPC socket/pipe requires session tokens, access control checks, and defense against unprivileged local processes injecting diagnostic commands. | Architectural Consequence |
| **External Dependency Lifecycle** | `[Measured Fact]` Standalone Dart/Flutter dependency tree managed by `pubspec.lock`. Zero external runtime interpreters required. | `[Architectural Consequence]` Packaging Python or C++ runtime requires managing separate runtime dependencies, DLL hell, virtualenvs, or containerization. | Architectural Consequence |
| **Desktop Packaging Complexity** | `[Architectural Consequence]` Single application bundle / directory structure (`tool/packaging/*.sh`). Standard Flutter desktop bundle output. | `[Architectural Consequence]` Multi-binary bundle packaging: managing helper executable location, executable permissions, path resolution across platforms. | Architectural Consequence |
| **Signing / Notarization / Antivirus** | `[Architectural Consequence]` Standard application bundle signing. Single certificate chain evaluation for main app. | `[Architectural Consequence]` Nested binary signing, separate entitlements, hardened runtime notarization for daemon, increased heuristic false-positive rates by AV scanners. | Architectural Consequence |
| **Startup Latency** | `[Architectural Consequence]` Current architecture has no project-owned sidecar spawn or ready handshake. | `[NOT MEASURED]` Sidecar startup delta: NOT MEASURED. | `NOT MEASURED` |
| **Per-Request Latency** | `[Architectural Consequence]` Current architecture has no project-owned cross-process diagnostic IPC hop. | `[NOT MEASURED]` Native-vs-sidecar request latency delta: NOT MEASURED. | `NOT MEASURED` |
| **Memory / RSS Footprint** | `[Architectural Consequence]` Current architecture operates within the single Flutter engine memory footprint. | `[NOT MEASURED]` Dual-process memory/RSS delta: NOT MEASURED. | `NOT MEASURED` |
| **Upgrade & Version Skew** | `[Measured Fact]` Atomic updates: application and diagnostic logic are compiled and deployed as a single immutable binary. | `[Architectural Consequence]` Potential version skew between main app and running helper daemon if updates do not atomically restart helper. | Architectural Consequence |
| **Debugging & Evidence Collection** | `[Measured Fact]` Single unified debug console, unified stack traces, coherent logcat/os_log outputs. | `[Architectural Consequence]` Distributed tracing: requires cross-process correlation IDs, dual logging sinks, split crash reporting. | Architectural Consequence |
| **Cross-Platform Portability** | `[Measured Fact]` Runs uniformly across Android, iOS, macOS, Windows, and Linux via Flutter engine abstractions. | `[Architectural Consequence]` Platform-specific IPC: Unix domain sockets on Linux/macOS vs. Named Pipes on Windows; POSIX signals vs. Windows job objects. | Architectural Consequence |
| **Access to Vendor-Only ABI** | `[Measured Fact]` Limited to Dart FFI capabilities and host architecture (e.g. 64-bit Dart cannot call 32-bit DLLs). | `[Architectural Consequence]` Enables 32-bit/64-bit thunking and hosting proprietary third-party C ABIs without risking Flutter engine stability. | Architectural Consequence |

---

## 6. Mandatory Sidecar Adoption Gate

Before any future issue (#14, #15, #16, or subsequent transport extensions) may claim an out-of-process sidecar architecture is **adopted**, the owning issue must implement a project-owned, bounded prototype and provide empirical benchmarks against the following two contracts:

### A. IPC and Security Contract
The sidecar communication link must strictly satisfy:
1. **Typed protocol version**: Explicit version negotiation field in initial handshake; incompatible versions fail closed.
2. **Request ID**: Every request carries a unique 64-bit or UUID request identifier echoed in all corresponding responses.
3. **Connection generation**: Connection generation integer tracked; requests submitted under prior generations are rejected.
4. **Absolute deadline + cancellation**: Every request includes an absolute UTC deadline and supports explicit cooperative cancellation tokens.
5. **Authenticated client**: Authenticated per-process or per-session secret token generated by the main Flutter app upon launch; unauthenticated connections are dropped.
6. **Local-only endpoint by default**: IPC must bind strictly to loopback (`127.0.0.1` / `::1`) or POSIX filesystem domain sockets with `0700` permissions. Never listen on external network interfaces.
7. **Bounded message sizes**: Strict frame and PDU size limits (e.g. max 4 KB); oversized messages trigger immediate connection termination.
8. **Bounded queue / resource owner**: Max bounded queue depth; requests exceeding depth are rejected with backpressure exceptions.
9. **No arbitrary shell execution**: The helper daemon must never expose an execution endpoint that passes strings to `/bin/sh`, `cmd.exe`, or `powershell.exe`.
10. **No arbitrary DLL/library path**: Library loading paths (e.g. for J2534) must be strictly validated against an approved allowlist; never load arbitrary paths supplied by user input, vehicle profiles, or network packets.
11. **Pinned dependencies + hashes/lockfiles**: Any helper runtime dependencies must be locked with cryptographic hashes.
12. **Clean shutdown and stale-request retirement**: Graceful termination on SIGTERM/SIGINT; queued requests for dead clients are immediately retired without execution.
13. **No uncertain auto-replay**: If the worker crashes or restarts while an in-flight diagnostic operation is active, it must **never** automatically replay the operation upon reconnect.

### B. Benchmark Contract before Adoption
On the actual target desktop hardware and OS, the implementing issue must benchmark and record:
1. **Process startup / ready time**: p50 and p95 latency from spawn to ready handshake.
2. **Bounded request IPC round-trip**: p50 and p95 latency under realistic diagnostic traffic (e.g. 50 requests/sec).
3. **App + worker memory / RSS delta**: Base memory footprint vs. combined dual-process memory footprint.
4. **Package / archive size delta**: Uncompressed and compressed installer package size differences.
5. **Worker crash / restart recovery behavior**: Empirical proof that worker crashes are detected within bounded deadlines and do not orphan resources or lock ports.
6. **Exact environment provenance**: Operating system release, kernel version, CPU architecture, Dart SDK version, compiler flags, and dependency lockfile hashes.
7. **Raw log and artifact hashes**: SHA-256 hashes of all benchmark logs and raw measurement outputs.

Where a native comparator exists on the same platform, the sidecar must be benchmarked directly against the native implementation. Where no native comparator exists (e.g. Windows J2534 requiring 32-bit isolation), absolute costs must still be measured and justified.

---

## 7. Capability and Safety Boundary

This architecture decision record establishes strict boundaries regarding system capability:
- **DiagnosticLink capability does not imply raw CAN, raw ISO-TP, UDS, DoIP, or J2534**: The presence of the `DiagnosticLink` interface merely indicates a typed half-duplex diagnostic communication channel. It does not certify that the underlying hardware or bus protocol supports arbitrary arbitration IDs, multi-frame ISO-TP reassembly, or OEM diagnostic sessions.
- **Transport and link availability does not imply an OEM command exists**: Successfully establishing a connection to an adapter or vehicle bus does not infer that manufacturer-specific commands, proprietary PIDs, or diagnostic routines are available or safe to execute.
- **Discovery and support does not imply actuation authorization**: Discovering that an ECU supports a specific diagnostic service (such as Mode 08 system tests) does not grant permission to actuate vehicle components.
- **No flashing or programming capability**: This ADR grants **no flashing, calibration, bootloader entry, memory writing, or ECU reflashing capability whatsoever**.
- **Authority of separate safety standards**: Issue #10 (Service Classification) and the separate active-test authorization and qualification gates remain authoritative. Actuation, bidirectional control, and live hardware qualification are governed exclusively by their dedicated safety contracts.

---

## 8. Rollback and Compatibility

This slice represents an architecture decision record and contract verification suite only:
- **Zero runtime code changes**: No modifications are made to `lib/**`, platform plugins, or native runners.
- **Zero transport migration**: Existing ELM, Classic, BLE, Wi-Fi, and Demo paths remain untouched.
- **Zero schema changes**: User settings, telemetry logs, NDJSON records, and export formats are unaffected.
- **Zero Demo fallback impact**: Synthetic simulation behavior is preserved identically.
- **Rollback procedure**: If this ADR is rejected or superseded, rollback is achieved simply by reverting this documentation file and its associated contract test. No database migration, configuration cleanup, or deprecation cycle is required.

---

## 9. Revisit Triggers

This architectural decision shall be revisited only when an owning link issue presents one of the following concrete conditions:
1. A required vendor ABI (such as Windows J2534) cannot be portably or safely hosted within the 64-bit Flutter engine process;
2. Process isolation is formally established as a mandatory security or reliability requirement for an unstable transport;
3. A complete, project-owned prototype satisfying the Section 6 adoption gate demonstrates empirical benefits that justify the added complexity;
4. Platform packaging, notarization, or OS sandboxing constraints change materially on supported desktop operating systems.
