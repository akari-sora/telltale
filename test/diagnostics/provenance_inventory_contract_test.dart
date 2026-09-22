/// Contract tests for the canonical provenance inventory (Issue #11, WS-07 Slice 1).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/licenses/powertrain_battery_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> inventory;
  late Map<String, dynamic> batteryClass;

  setUpAll(() {
    final file = File('docs/provenance/inventory.json');
    expect(file.existsSync(), isTrue, reason: 'inventory.json must exist');
    inventory = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final artifacts = (inventory['artifacts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(
      artifacts.length,
      equals(1),
      reason: 'Slice 1 permits exactly one artifact class',
    );
    batteryClass = artifacts.first;
  });

  test('A1: canonical inventory defines powertrain-battery-bundled-third-party', () {
    expect(inventory['schema_version'], equals(1));
    expect(batteryClass['id'], equals('powertrain-battery-bundled-third-party'));
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
    // Remediation must clearly state that generic OBD / demo mode remains functional
    final remediation = batteryClass['remediation'] as Map<String, dynamic>;
    final onRights = remediation['on_rights_revocation'] as String;
    final onIntegrity = remediation['on_integrity_failure'] as String;

    expect(onRights.toLowerCase(), contains('generic obd'));
    expect(onRights.toLowerCase(), contains('demo mode'));
    expect(onIntegrity.toLowerCase(), contains('without affecting generic diagnostics'));
  });
}
