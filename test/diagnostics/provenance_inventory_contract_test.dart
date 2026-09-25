/// Contract tests for the canonical provenance inventory (Issue #11, WS-07 Slices 1 & 2).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/licenses/powertrain_battery_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> inventory;
  late Map<String, dynamic> batteryClass;
  late List<Map<String, dynamic>> testOnlyClasses;

  setUpAll(() {
    final file = File('docs/provenance/inventory.json');
    expect(file.existsSync(), isTrue, reason: 'inventory.json must exist');
    inventory = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final artifacts = (inventory['artifacts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(
      artifacts.length,
      equals(6),
      reason: 'Inventory defines exactly 1 production and 5 test-only artifact classes',
    );
    batteryClass = artifacts.firstWhere(
      (a) => a['id'] == 'powertrain-battery-bundled-third-party',
    );
    testOnlyClasses = artifacts.where((a) => a['scope'] == 'test-only').toList();
    expect(testOnlyClasses.length, equals(5));
  });

  // =========================================================================
  // Slice 1: Production Package Invariants
  // =========================================================================

  test('A1: canonical inventory defines powertrain-battery-bundled-third-party', () {
    expect(inventory['schema_version'], equals(1));
    expect(batteryClass['id'], equals('powertrain-battery-bundled-third-party'));
    expect(batteryClass['artifact_class'], equals('powertrain-battery-bundled-third-party'));
    expect(batteryClass['scope'], equals('production-package'));
    expect(batteryClass['role'], equals('runtime'));
  });

  test('A2 & A7: distribution and commercial-use decisions are approved', () {
    expect(batteryClass['distribution_decision'], equals('approved'));
    expect(batteryClass['commercial_use_decision'], equals('allowed'));
    expect(batteryClass['reviewer_status'], equals('reviewed'));
    expect(batteryClass['remediation'], isNotNull);
  });

  test('A5: declared package assets exist on disk', () {
    final requiredAssets = (batteryClass['required_package_assets'] as List<dynamic>)
        .cast<String>();
    for (final asset in requiredAssets) {
      final file = File(asset);
      expect(file.existsSync(), isTrue, reason: 'Asset must exist on disk: $asset');
    }
  });

  test('A5 & A11: runtime licence registry assets match Dart license surface', () {
    final registryAssets =
        (batteryClass['runtime_licence_registry_assets'] as List<dynamic>)
            .cast<String>();
    expect(
      registryAssets.toSet(),
      equals(powertrainBatteryLicenseAssets.toSet()),
      reason: 'Inventory registry assets must match Dart licence constant',
    );
  });

  test('A10: containment - battery catalog failure does not alter unrelated components', () {
    final remediation = batteryClass['remediation'] as Map<String, dynamic>;
    final onRights = remediation['on_rights_revocation'] as String;
    final onIntegrity = remediation['on_integrity_failure'] as String;

    expect(onRights.toLowerCase(), contains('generic obd'));
    expect(onRights.toLowerCase(), contains('demo mode'));
    expect(onIntegrity.toLowerCase(), contains('without affecting generic diagnostics'));
  });

  // =========================================================================
  // Slice 2: Test-only Oracle & Reference Invariants
  // =========================================================================

  test('S2-A2: exactly five declared test-only artifact classes with exact IDs', () {
    final ids = testOnlyClasses.map((a) => a['id'] as String).toSet();
    expect(
      ids,
      equals({
        'ircama-elm327-emulator-test-oracle',
        'telltale-chaos-proxy-test-reference',
        'telltale-freeze-frame-reference',
        'telltale-mode08-replay-reference',
        'udsoncan-readonly-reference',
      }),
    );
  });

  test('S2-A7, S2-A10, S2-A11: ownership and independence classifications are exact', () {
    final ircama = testOnlyClasses.firstWhere(
      (a) => a['id'] == 'ircama-elm327-emulator-test-oracle',
    );
    expect(ircama['ownership'], equals('third-party'));
    expect(ircama['independence'], equals('independent-third-party-oracle'));
    expect(ircama['distribution_channel'], equals('external-fetch-only'));
    expect(ircama['distribution_decision'], equals('not_distributed'));
    expect(ircama['commercial_use_decision'], equals('restricted'));

    final chaos = testOnlyClasses.firstWhere(
      (a) => a['id'] == 'telltale-chaos-proxy-test-reference',
    );
    expect(chaos['ownership'], equals('project-owned'));
    expect(chaos['independence'], equals('project-owned-fault-injector'));
    expect(chaos['distribution_channel'], equals('source-repository'));

    final freeze = testOnlyClasses.firstWhere(
      (a) => a['id'] == 'telltale-freeze-frame-reference',
    );
    expect(freeze['ownership'], equals('project-owned'));
    expect(freeze['independence'], equals('project-owned-reference'));
    expect(freeze['distribution_channel'], equals('source-repository'));

    final mode08 = testOnlyClasses.firstWhere(
      (a) => a['id'] == 'telltale-mode08-replay-reference',
    );
    expect(mode08['ownership'], equals('project-owned'));
    expect(mode08['independence'], equals('project-owned-reference'));
    expect(mode08['distribution_channel'], equals('source-repository'));

    final udsoncan = testOnlyClasses.firstWhere(
      (a) => a['id'] == 'udsoncan-readonly-reference',
    );
    expect(udsoncan['ownership'], equals('third-party'));
    expect(udsoncan['independence'], equals('independent-third-party-reference'));
    expect(udsoncan['distribution_channel'], equals('external-fetch-only'));
    expect(udsoncan['distribution_decision'], equals('not_distributed'));
    expect(udsoncan['commercial_use_decision'], equals('allowed'));
  });

  test('S2-A8: package isolation - test-only artifacts forbidden from app package and registries', () {
    final pubspecFile = File('pubspec.yaml');
    expect(pubspecFile.existsSync(), isTrue);
    final pubspecContent = pubspecFile.readAsStringSync();

    for (final art in testOnlyClasses) {
      expect(art['scope'], equals('test-only'));
      expect(art['role'], equals('test-only'));
      final pkgPolicy = art['package_policy'] as Map<String, dynamic>;
      expect(pkgPolicy['app_package'], equals('forbidden'));
      expect(art['distribution_channel'], isNot(equals('app-package')));

      // Verify no referenced paths appear in pubspec.yaml assets or Dart license registry
      final pathsToCheck = <String>[];
      if (art.containsKey('licence_evidence')) {
        final ev = art['licence_evidence'] as Map<String, dynamic>;
        pathsToCheck.add(ev['local_evidence_path'] as String);
      }
      if (art.containsKey('project_source')) {
        final ps = art['project_source'] as Map<String, dynamic>;
        final integrityFiles = (ps['integrity_files'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        for (final inf in integrityFiles) {
          pathsToCheck.add(inf['path'] as String);
        }
      }

      for (final p in pathsToCheck) {
        expect(
          powertrainBatteryLicenseAssets.contains(p),
          isFalse,
          reason: 'Test-only file $p must not be in Dart runtime licence registry',
        );
        expect(
          pubspecContent.contains('  - $p\n'),
          isFalse,
          reason: 'Test-only file $p must not be declared in pubspec.yaml assets',
        );
      }
    }
  });

  test('S2-A5, S2-A6, S2-A12: lockfiles, licence evidence, and integrity files exist on disk', () {
    final ircama = testOnlyClasses.firstWhere(
      (a) => a['id'] == 'ircama-elm327-emulator-test-oracle',
    );
    final src = ircama['source'] as Map<String, dynamic>;
    final lockfiles = (src['lockfiles'] as List<dynamic>).cast<String>();
    for (final lf in lockfiles) {
      expect(File(lf).existsSync(), isTrue, reason: 'Declared lockfile must exist: $lf');
    }

    final licEv = ircama['licence_evidence'] as Map<String, dynamic>;
    final evPath = licEv['local_evidence_path'] as String;
    expect(File(evPath).existsSync(), isTrue, reason: 'Licence evidence must exist: $evPath');

    final mode08 = testOnlyClasses.firstWhere(
      (a) => a['id'] == 'telltale-mode08-replay-reference',
    );
    final ps = mode08['project_source'] as Map<String, dynamic>;
    final infs = (ps['integrity_files'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final declaredPaths = infs.map((f) => f['path'] as String).toSet();
    expect(
      declaredPaths,
      containsAll([
        'tool/obd_test_rig/mode08_replay_reference.py',
        'tool/obd_test_rig/mode08_replay_fixtures.json',
      ]),
    );

    final udsoncan = testOnlyClasses.firstWhere(
      (a) => a['id'] == 'udsoncan-readonly-reference',
    );
    final udSrc = udsoncan['source'] as Map<String, dynamic>;
    final udLockfiles = (udSrc['lockfiles'] as List<dynamic>).cast<String>();
    for (final lf in udLockfiles) {
      expect(File(lf).existsSync(), isTrue, reason: 'Declared lockfile must exist: $lf');
    }
    final udLicEv = udsoncan['licence_evidence'] as Map<String, dynamic>;
    final udEvPath = udLicEv['local_evidence_path'] as String;
    expect(File(udEvPath).existsSync(), isTrue, reason: 'Licence evidence must exist: $udEvPath');
  });
}
