# Provenance and Licence Inventory

This directory maintains the canonical, cross-cutting inventory of public, packaged, and reference artifacts for Telltale (Issue #11, WS-07).

## Purpose & Scope

The provenance inventory provides release-level admissibility and legal/provenance governance. It records:
- Source upstream URL and repository identity;
- Immutable commit revision and artifact digest (SHA-256);
- Licencing terms, packaged licence file paths, and attribution locations;
- Runtime versus test-only role;
- Distribution and commercial-use admissibility decisions;
- Reviewer status and remediation procedures for rights revocation or integrity failure.

Existing domain-specific validators (e.g., `tool/update_powertrain_battery_manifest.py`, `tool/powertrain_evidence/validate_matrix.py`) remain authoritative for their catalog schemas, signal definitions, and evidence matrix semantics. This inventory connects them into a unified release admissibility gate without duplicating catalog rows.

## Decision Semantics

The inventory models distribution and commercial-use decisions using explicit finite enumerations:

- `approved`: Validated, reviewed, and permitted for the declared scope.
- `restricted`: Rights or terms limit use; prohibited from production-package scope without explicit containment.
- `replace_required`: An alternative source or asset must replace this entry prior to distribution.
- `not_distributed`: Reference or research material retained for documentation, not packaged in release builds.
- `unknown`: Rights or origin unresolved; **fails closed** (never coerced to approved).

For any artifact included in `scope: production-package`, both `distribution_decision` and `commercial_use_decision` must be explicitly verified and approved.

## Scoped Failure & Containment (A10)

Provenance rejection is strictly scoped to the affected artifact class or profile subset:
- If a battery profile or catalog provenance check fails, the battery catalog loader fails closed for that class.
- Rejection **never** triggers a global application shutdown or disables generic OBD-II diagnostics, Demo mode, user-authored PIDs, or unrelated vehicle catalogs.

## Owner-Truth Binding & Source Coverage

Rather than manually copying a redundant duplicate list of sources into `inventory.json` that is prone to drift, the inventory establishes a `source_coverage` contract binding directly to authoritative owner files:
- `tool/powertrain_evidence/matrix.json` (authoritative evidence matrix & research sources);
- `THIRD_PARTY_NOTICES_POWERTRAIN_BATTERY.md` (pinned upstream repositories, commits, and notices);
- `assets/powertrain_battery/powertrain_battery_catalog.json` (bundled catalog data);
- `assets/powertrain_battery/powertrain_battery_catalog.manifest.json` (catalog integrity manifest).

The validator dynamically derives all source families from owner truth and verifies:
1. Revisions in notices match authoritative evidence matrix revisions (fail-closed against revision drift);
2. All distinct owner licenses (`Apache-2.0`, `MIT`, `GPL-3.0`, `GPL-3.0-or-later`, `CC-BY-SA-4.0`, `CC-BY-4.0`, `U.S.-Government-Public-Domain`) are declared in `licence_identifier`;
3. Any explicitly declared `source_families` tuples match owner truth exactly (detecting unowned sources, revision mismatch, license mismatch, or hash mismatch).

## CLI & Validation

Run the offline, deterministic provenance validator:

```bash
# Validate production-package scope (default)
python3 tool/workshop/validate_provenance.py --scope production-package

# Run test suite
python3 -m unittest discover -s test/tool -p 'test_validate_provenance.py'
```

The validator:
1. Validates inventory schema, unique non-wildcard IDs, and relative paths (no absolute host paths);
2. Enforces fail-closed rules on unknown or restricted distribution decisions;
3. Verifies that all declared `required_package_assets` exist on disk and are declared in `pubspec.yaml`;
4. Verifies that all `runtime_licence_registry_assets` are registered in `lib/core/licenses/powertrain_battery_licenses.dart`;
5. Cross-checks catalog SHA-256 and byte length against `assets/powertrain_battery/powertrain_battery_catalog.manifest.json`;
6. Verifies owner source coverage, pinned commit revisions (40-char hex), and source digests (64-char hex);
7. Emits bounded, deterministic reports naming the exact class and error ID without leaking confidential data or raw secrets.
