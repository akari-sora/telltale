# Provenance and Licence Inventory

This directory maintains the canonical, cross-cutting inventory of public, packaged, and reference artifacts for Telltale (Issue #11, WS-07 Slices 1 & 2).

## Purpose & Scope

The provenance inventory provides release-level admissibility and legal/provenance governance. It records:
- Source upstream URL and repository identity;
- Immutable commit revision and artifact digest (SHA-256);
- Licencing terms, packaged licence file paths, and attribution locations;
- Runtime versus test-only role;
- Distribution and commercial-use admissibility decisions;
- Reviewer status and remediation procedures for rights revocation or integrity failure;
- Lockfile cross-checks, offline licence evidence, and test-only package boundaries.

Existing domain-specific validators (e.g., `tool/update_powertrain_battery_manifest.py`, `tool/powertrain_evidence/validate_matrix.py`) remain authoritative for their catalog schemas, signal definitions, and evidence matrix semantics. This inventory connects them into a unified release admissibility gate without duplicating catalog rows or creating parallel trust models.

## Scopes & Validation Modes

The validator supports three explicit scopes:

1. `--scope production-package`: Validates production-packaged assets admitted to release distributions (`powertrain-battery-bundled-third-party`). Requires `distribution_decision == approved` and `commercial_use_decision == allowed`.
2. `--scope test-only`: Validates test-only oracle dependencies and project-owned references. Verifies lockfile hash parity, exact offline licence evidence, identity banners, and package isolation.
3. `--scope all`: Validates both production-package and test-only artifact records.

A provenance failure in test-only artifacts fails `test-only` and `all`, but **never blocks `production-package`**. Conversely, a failure in production packaging never masks test-only validation.

## Declared Artifact Classes

### 1. Production Package (`scope: production-package`)

- **`powertrain-battery-bundled-third-party`** (Role: `runtime`, Ownership: `third-party`):
  Bundled battery catalog JSON, manifest, notices, and permissive third-party licence texts exposed in app packages and `LicenseRegistry`.

### 2. Test-Only Oracles & References (`scope: test-only`)

- **`ircama-elm327-emulator-test-oracle`** (Role: `test-only`, Ownership: `third-party`, Independence: `independent-third-party-oracle`):
  External ELM327 emulator oracle (`ELM327-emulator==3.0.5`, SHA-256 `c4527894...`). Hash-pinned across `.github/requirements/elm327-py314-linux-x86_64.lock` and `tool/ble_test_rig/requirements.lock`. Reviewed exact licence evidence (`CC-BY-NC-SA-4.0`, SHA-256 `1349a4b6...`) stored under `docs/provenance/upstream/ELM327-emulator-3.0.5.LICENSE`. Execution bound to `tool/workshop/run_public_oracles.sh` with `ELM_ORACLE_REQUIRED=true`.
- **`telltale-chaos-proxy-test-reference`** (Role: `test-only`, Ownership: `project-owned`, Independence: `project-owned-fault-injector`):
  Project-owned TCP fault-injection proxy (`tool/obd_test_rig/chaos_proxy.py`, SHA-256 `6f8638de...`) under repository GPL-3.0 licence. Bound to `test/chaos_oracle_test.dart` and `test/chaos_poll_oracle_test.dart`.
- **`telltale-freeze-frame-reference`** (Role: `test-only`, Ownership: `project-owned`, Independence: `project-owned-reference`):
  Project-owned Mode 02 freeze-frame reference server (`tool/obd_test_rig/freeze_frame_reference.py`, SHA-256 `1f8e5f7b...`) under GPL-3.0. Identity banner pinned to `Telltale Freeze-Frame Reference` to prevent confusion with third-party oracles.
- **`telltale-mode08-replay-reference`** (Role: `test-only`, Ownership: `project-owned`, Independence: `project-owned-reference`):
  Project-owned Mode 08 replay reference server (`tool/obd_test_rig/mode08_replay_reference.py`, SHA-256 `4cdc34b4...`) and synthetic fixtures (`tool/obd_test_rig/mode08_replay_fixtures.json`, SHA-256 `e0a10d41...`) under GPL-3.0. Identity banner pinned to `Telltale Mode 08 Replay Reference`. Bound to `tool/ci/run_mode08_required.py` with `MODE08_ORACLE_REQUIRED=true`.
- **`udsoncan-readonly-reference`** (Role: `test-only`, Ownership: `third-party`, Independence: `independent-third-party-reference`):
  External UDS reference library (`udsoncan==1.26.1`, wheel SHA-256 `c1bd6cc5...`). Hash-pinned in `.github/requirements/udsoncan-reference.lock`. Reviewed exact licence evidence (`MIT`, SHA-256 `aae122e2...`) stored under `docs/provenance/upstream/udsoncan-1.26.1.LICENSE`. Bound to `tool/uds_reference/verify_udsoncan_vectors.py`.

## Package Isolation (S2-A8)

Every test-only artifact is strictly governed by `package_policy.app_package: forbidden`:
- It must **never** be declared in `pubspec.yaml` assets;
- It must **never** be registered in Dart runtime `LicenseRegistry` surfaces (`powertrainBatteryLicenseAssets`);
- It must **never** have role `runtime` or `bundled`;
- It must **never** be distributed in Android APK, macOS/iOS app bundles, or desktop production packages.

## Decision Semantics

The inventory models distribution and commercial-use decisions using explicit finite enumerations:

- `approved`: Validated, reviewed, and permitted for the declared scope.
- `restricted`: Rights or terms limit use; permitted for test-only evaluation on loopback interfaces, prohibited from production packages.
- `replace_required`: An alternative source or asset must replace this entry prior to distribution.
- `not_distributed`: Reference, test dependency, or research material retained for documentation, not packaged in release builds.
- `unknown`: Rights or origin unresolved; **fails closed** (never coerced to approved).

## CLI & Validation

Run the offline, deterministic provenance validator:

```bash
# Validate production-package scope (default)
python3 tool/workshop/validate_provenance.py --scope production-package

# Validate test-only scope
python3 tool/workshop/validate_provenance.py --scope test-only

# Validate all scopes
python3 tool/workshop/validate_provenance.py --scope all

# Run test suite
python3 -m unittest discover -s test/tool -p 'test_validate_provenance.py'
```
