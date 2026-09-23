# Public Artifact Privacy Boundary & Governance Specification

**Status:** Normative (Issue #11, WS-07 Slice 3)  
**Parent:** [Issue #11](https://gitlab.com/aa22396584/telltale/-/work_items/11)  
**Machine-Readable Policy:** `docs/privacy/public-artifact-policy.json`  
**Tooling Authority:** `tool/workshop/public_artifact_guard.py`

---

## 1. Scope and Boundary Definition

This document establishes the fail-closed publication boundary for **derived and public evidence artifacts** across Telltale. It explicitly distinguishes between user-controlled local diagnostic exports and public-facing evidence summaries.

### 1.1 Separation from User-Owned Private Exports
- As disclosed in [PRIVACY.md](../../PRIVACY.md) and `docs/privacy.html`, user-controlled diagnostic transcripts (`ShareSourceKind.rawTranscript`, `recoveredTranscript`, telemetry CSV/JSON, PID CSV) are private artifacts generated on the user's device.
- These private exports intentionally contain raw OBD-II diagnostic communication, including vehicle identification numbers (VIN) and Diagnostic Trouble Codes (DTC), which are essential for automotive troubleshooting.
- **Slice 3 does not modify runtime user export code, transcript serialization, or share controllers.** Private artifacts remain truthful, byte-exact, and completely under user ownership.

### 1.2 Publication Safe Flow
Public artifacts (such as CI test summaries, public bug reproductions, benchmark reports, and evidence packets) must never be created by naively line-editing or partially masking private raw files. Instead, public artifacts must follow an explicit derivation pipeline:

```text
Private Raw Artifact (e.g. raw vehicle transcript, device log)
       │
       ├─ Stays local/private, immutable, byte-exact
       │
       └─► Explicit Summary Producer (allowlisted semantic fields)
                 │
                 ▼
          Public-Summary Candidate
                 │
                 ▼
          public_artifact_guard.py check --classification public-summary
                 │
                 ├─► 0 findings: PASS (Eligible for publication)
                 └─► ≥1 findings: FAIL CLOSED (Publication blocked)
```

---

## 2. Classification Model

The governance policy defines three mutually exclusive classifications:

| Classification | Publishable? | Mutable by Guard? | Description / Semantics |
| :--- | :---: | :---: | :--- |
| `private-raw` | **No** | **No** | Raw, un-sanitized internal or device diagnostic captures (e.g. real-vehicle transcripts, raw logs, raw dumps). May contain raw VIN, MAC, UUID, paths. Strictly forbidden from public distribution or external publication. Must remain byte-truthful and immutable. |
| `public-summary` | **Conditional** (Only if 0 findings) | **No** | Publication candidate derived from allowlisted fields and validated summaries. Must contain zero sensitive findings when evaluated by `public_artifact_guard`. Safe for public release, bug reports, and CI artifacts. |
| `synthetic-canary` | **No** | **No** | Test-only fixtures containing synthetic, non-real sensitive identifiers (e.g. synthetic VIN, MAC, UUID, customer IDs, GPS, user paths). Used exclusively to verify that the privacy guard detects leaks. Strictly forbidden from public distribution. |

> **Fail-Closed Gate Rule:** Merely changing the classification flag of a dirty artifact to `public-summary` will cause `public_artifact_guard` to scan and reject the file with exit code 1. `private-raw` and `synthetic-canary` classifications are rejected unconditionally by the publication gate.

---

## 3. Sensitive Categories and Detection Rules

`public_artifact_guard.py` enforces ten distinct sensitive categories:

1. **`vehicle.vin.plain`**:
   - Plain 17-character VIN in explicit vehicle or VIN context (e.g. keys/columns `vin`, `vehicle_id`, or log prefixes `VIN=`).
   - Complies with ISO 3779 alphanumeric format `^[A-HJ-NPR-Z0-9]{17}$`.
2. **`vehicle.vin.fragmented`**:
   - VIN split across declared sequence/index fragments in segmented payloads.
   - Detects ordered fragments reconstructing a valid VIN.
3. **`vehicle.vin.hex_ascii`**:
   - 17-character VIN encoded as hex ASCII bytes (34 hex characters, contiguous or across ordered segments).
4. **`device.mac`**:
   - Hardware MAC address in standard colon or hyphen notation (`02:00:00:00:CA:FE`).
5. **`device.uuid`**:
   - UUID in explicit device context (`deviceUuid`, `adapterUuid`, `peripheralUuid`).
   - Context-sensitive: generic test or run UUIDs without device context remain permitted.
6. **`device.serial`**:
   - Hardware or device serial numbers in explicit serial/device context (`deviceSerial`, `adapterSerial`, `TEL-SERIAL-0001`).
7. **`subject.plate_or_customer_id`**:
   - License plate, customer identifier, client name, or owner identity fields.
8. **`location.gps`**:
   - Geographic coordinates (latitude and longitude) present in the same logical record.
9. **`host.user_path`**:
   - User-home absolute filesystem paths on macOS (`/Users/<user>/...`), Linux (`/home/<user>/...`), or Windows (`C:\Users\<user>\...`).
10. **`correlation.timestamp_with_identity`**:
    - Timestamp correlated with an identity (VIN, device UUID, device serial, MAC, or customer ID) in the same logical record.
    - Timestamp alone in an isolated record is permitted.

---

## 4. Allowlist Rules (Negative Controls)

To prevent over-redaction, the following diagnostic and operational symbols are explicitly safe in `public-summary` artifacts:
- **DTC Codes:** Standard OBD-II fault codes (e.g. `P0300`, `U0100`, `B1234`, `C0040`).
- **ECU Identifiers:** CAN IDs and OBD-II response addresses (e.g. `7E8`, `7E0`, `0x7E8`).
- **Protocol Labels:** Standard bus names (e.g. `ISO 15765-4 CAN 11/500`, `SAE J1850 PWM`).
- **Cryptographic Hashes:** 40-hex Git commit SHAs and 64-hex SHA-256 digests.
- **Test Identifiers:** Scenario and test case tags (e.g. `TC-101`, `S3-M1`).
- **Aggregate Metrics:** Numeric frame counts, error statistics, timing durations.
- **Loopback Addresses:** `127.0.0.1`, `localhost`.
- **Project Banners:** Project-owned headers and notices (`Telltale Freeze-Frame Reference`).
- **Isolated Timestamps:** UTC timestamps without identity pairing.

---

## 5. Finding and Exception Sanitization Contract

To prevent finding logs or exceptions from leaking the very identifiers they detect:
- Reports and exceptions contain **only bounded metadata**: category ID, format, line/record location, and static rule descriptions.
- **Never emitted:** matched tokens, raw input lines, raw JSON/CSV rows, surrounding text, reversible encodings, or hashed tokens.
- Unsafe object keys or headers containing sensitive data are normalized to ordinal indicators or safe placeholders.
- Parser errors (e.g. JSON decode error) are strictly sanitized and never echo raw malformed input text.
