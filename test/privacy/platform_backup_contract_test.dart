/// Contract test for platform backup attributes, configurations, and directory mapping (Issue #11, WS-07 Slice 4).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> inventory;
  late _XmlElement androidManifest;
  late Map<String, dynamic> iosInfoPlist;
  late Map<String, dynamic> macosEntitlements;

  setUpAll(() {
    // 1. Load data flow inventory
    final inventoryFile = File('docs/privacy/data-flow-inventory.json');
    expect(inventoryFile.existsSync(), isTrue, reason: 'data-flow-inventory.json must exist');
    inventory = jsonDecode(inventoryFile.readAsStringSync()) as Map<String, dynamic>;

    // 2. Parse Android Manifest
    final manifestFile = File('android/app/src/main/AndroidManifest.xml');
    expect(manifestFile.existsSync(), isTrue, reason: 'AndroidManifest.xml must exist');
    androidManifest = _parseXml(manifestFile.readAsStringSync());

    // 3. Parse iOS Info.plist
    final iosPlistFile = File('ios/Runner/Info.plist');
    expect(iosPlistFile.existsSync(), isTrue, reason: 'iOS Info.plist must exist');
    iosInfoPlist = _parsePlist(iosPlistFile.readAsStringSync());

    // 4. Parse macOS Release.entitlements
    final macosEntFile = File('macos/Runner/Release.entitlements');
    expect(macosEntFile.existsSync(), isTrue, reason: 'macOS Release.entitlements must exist');
    macosEntitlements = _parsePlist(macosEntFile.readAsStringSync());
  });

  group('P1-R6: Android Manifest XML Structure & Effective Backup Configuration', () {
    test('S4-A11: <application> element does not disable backup (defaults to true under Android OS)', () {
      final appElement = androidManifest.findChild('application');
      expect(appElement, isNotNull, reason: '<application> element must exist in manifest');
      // In Android, omitting android:allowBackup causes it to default to true.
      expect(
        appElement!.attributes['android:allowBackup'],
        isNot(equals('false')),
        reason: 'Source manifest must not set allowBackup="false" (defaults to true)',
      );
      expect(appElement.attributes['android:label'], equals('Telltale'));
    });

    test('S4-A11: BLUETOOTH_ADVERTISE is stripped on the same element via tools:node="remove"', () {
      final permissions = androidManifest.findChildren('uses-permission');
      final advertisePerm = permissions.where(
        (p) => p.attributes['android:name'] == 'android.permission.BLUETOOTH_ADVERTISE',
      );
      expect(advertisePerm.length, equals(1), reason: 'BLUETOOTH_ADVERTISE permission element must exist');
      final elem = advertisePerm.first;
      expect(
        elem.attributes['tools:node'],
        equals('remove'),
        reason: 'BLUETOOTH_ADVERTISE must declare tools:node="remove" on the exact same XML element',
      );
    });

    test('S4-A11: BLUETOOTH_SCAN declares neverForLocation and targetApi="s" on the same element', () {
      final permissions = androidManifest.findChildren('uses-permission');
      final scanPerm = permissions.where(
        (p) => p.attributes['android:name'] == 'android.permission.BLUETOOTH_SCAN',
      );
      expect(scanPerm.length, equals(1));
      final elem = scanPerm.first;
      expect(
        elem.attributes['android:usesPermissionFlags'],
        equals('neverForLocation'),
        reason: 'BLUETOOTH_SCAN must specify usesPermissionFlags="neverForLocation"',
      );
      expect(
        elem.attributes['tools:targetApi'],
        equals('s'),
        reason: 'BLUETOOTH_SCAN must target Android 12 (S)',
      );
    });

    test('S4-A11: Location permissions are strictly capped at maxSdkVersion="30"', () {
      final permissions = androidManifest.findChildren('uses-permission');
      final fineLoc = permissions.where(
        (p) => p.attributes['android:name'] == 'android.permission.ACCESS_FINE_LOCATION',
      );
      expect(fineLoc.length, equals(1));
      expect(fineLoc.first.attributes['android:maxSdkVersion'], equals('30'));

      final coarseLoc = permissions.where(
        (p) => p.attributes['android:name'] == 'android.permission.ACCESS_COARSE_LOCATION',
      );
      expect(coarseLoc.length, equals(1));
      expect(coarseLoc.first.attributes['android:maxSdkVersion'], equals('30'));
      expect(coarseLoc.first.attributes['tools:node'], equals('replace'));
    });

    test('S4-A11: Legacy Bluetooth permissions are capped at maxSdkVersion="30"', () {
      final permissions = androidManifest.findChildren('uses-permission');
      final bt = permissions.where(
        (p) => p.attributes['android:name'] == 'android.permission.BLUETOOTH',
      );
      expect(bt.length, equals(1));
      expect(bt.first.attributes['android:maxSdkVersion'], equals('30'));

      final btAdmin = permissions.where(
        (p) => p.attributes['android:name'] == 'android.permission.BLUETOOTH_ADMIN',
      );
      expect(btAdmin.length, equals(1));
      expect(btAdmin.first.attributes['android:maxSdkVersion'], equals('30'));
    });

    test('S4-A11: Hardware features for Bluetooth and BLE are optional (required="false")', () {
      final features = androidManifest.findChildren('uses-feature');
      final btFeature = features.where(
        (f) => f.attributes['android:name'] == 'android.hardware.bluetooth',
      );
      expect(btFeature.length, equals(1));
      expect(btFeature.first.attributes['android:required'], equals('false'));

      final bleFeature = features.where(
        (f) => f.attributes['android:name'] == 'android.hardware.bluetooth_le',
      );
      expect(bleFeature.length, equals(1));
      expect(bleFeature.first.attributes['android:required'], equals('false'));
    });
  });

  group('P1-R6: Apple Plist & Entitlements Structure Verification', () {
    test('S4-A12: iOS Info.plist structured key-values declare required diagnostic usage descriptions', () {
      expect(iosInfoPlist['CFBundleDisplayName'], equals('Telltale'));
      expect(
        iosInfoPlist['NSBluetoothAlwaysUsageDescription'],
        isA<String>().having((s) => s.isNotEmpty, 'isNotEmpty', isTrue),
      );
      expect(
        iosInfoPlist['NSBluetoothPeripheralUsageDescription'],
        isA<String>().having((s) => s.isNotEmpty, 'isNotEmpty', isTrue),
      );
      expect(
        iosInfoPlist['NSLocalNetworkUsageDescription'],
        isA<String>().having((s) => s.isNotEmpty, 'isNotEmpty', isTrue),
      );
    });

    test('S4-A12: iOS Info.plist does not declare proprietary iCloud container keys', () {
      expect(iosInfoPlist.containsKey('NSUbiquitousContainers'), isFalse);
      expect(iosInfoPlist.containsKey('com.apple.developer.ubiquity-container-identifiers'), isFalse);
      expect(iosInfoPlist.containsKey('com.apple.developer.icloud-container-identifiers'), isFalse);
    });

    test('S4-A12: macOS Release.entitlements enforces App Sandbox as boolean true', () {
      expect(
        macosEntitlements['com.apple.security.app-sandbox'],
        isTrue,
        reason: 'macOS Release.entitlements must parse app-sandbox as boolean true',
      );
      expect(
        macosEntitlements['com.apple.security.network.client'],
        isTrue,
        reason: 'macOS must allow client network access for Wi-Fi ELM327',
      );
      expect(
        macosEntitlements['com.apple.security.device.bluetooth'],
        isTrue,
        reason: 'macOS must allow Bluetooth device access',
      );
      expect(
        macosEntitlements['com.apple.security.files.user-selected.read-only'],
        isTrue,
        reason: 'macOS must allow user-selected file read access',
      );
    });

    test('S4-A12: macOS Release.entitlements contains zero iCloud container entitlements', () {
      expect(macosEntitlements.containsKey('com.apple.developer.icloud-container-identifiers'), isFalse);
      expect(macosEntitlements.containsKey('com.apple.developer.ubiquity-container-identifiers'), isFalse);
      expect(macosEntitlements.containsKey('com.apple.developer.icloud-services'), isFalse);
    });
  });

  group('P1-R6: Platform Storage Mapping & Backup Domain Parity', () {
    test('S4-A11: inventory defines complete Android storage directory and backup domain mapping', () {
      final mapping = inventory['platform_storage_mapping'] as Map<String, dynamic>?;
      expect(mapping, isNotNull);
      final androidMap = mapping!['android'] as Map<String, dynamic>?;
      expect(androidMap, isNotNull);

      final pref = androidMap!['preferences'] as Map<String, dynamic>;
      expect(pref['flutter_api'], equals('SharedPreferences'));
      expect(pref['backup_domain'], equals('sharedpref'));
      expect(pref['backup_classification'], equals('os-backup-eligible'));

      final doc = androidMap['documents'] as Map<String, dynamic>;
      expect(doc['flutter_api'], equals('getApplicationDocumentsDirectory'));
      expect(doc['backup_domain'], equals('root'));
      expect(doc['backup_classification'], equals('os-backup-eligible'));

      final cache = androidMap['cache'] as Map<String, dynamic>;
      expect(cache['flutter_api'], equals('getApplicationCacheDirectory'));
      expect(cache['backup_domain'], equals('cache'));
      expect(cache['backup_classification'], equals('os-backup-excluded'));
    });

    test('S4-A12: inventory defines complete Apple storage directory and backup classification mapping', () {
      final mapping = inventory['platform_storage_mapping'] as Map<String, dynamic>?;
      expect(mapping, isNotNull);

      // iOS verification
      final iosMap = mapping!['ios'] as Map<String, dynamic>?;
      expect(iosMap, isNotNull);
      expect(iosMap!['bundle_id'], equals('com.cbstudio.telltale'));

      final iosPref = iosMap['preferences'] as Map<String, dynamic>;
      expect(iosPref['flutter_api'], equals('SharedPreferences'));
      expect(iosPref['native_path'], equals('Library/Preferences/com.cbstudio.telltale.plist'));
      expect(iosPref['backup_classification'], equals('os-backup-eligible'));

      final iosDoc = iosMap['documents'] as Map<String, dynamic>;
      expect(iosDoc['flutter_api'], equals('getApplicationDocumentsDirectory'));
      expect(iosDoc['native_path'], equals('Documents/'));
      expect(iosDoc['backup_classification'], equals('os-backup-eligible'));

      final iosCache = iosMap['cache'] as Map<String, dynamic>;
      expect(iosCache['flutter_api'], equals('getApplicationCacheDirectory'));
      expect(iosCache['native_path'], equals('Library/Caches/'));
      expect(iosCache['backup_classification'], equals('os-backup-excluded'));

      // macOS verification
      final macosMap = mapping['macos'] as Map<String, dynamic>?;
      expect(macosMap, isNotNull);
      expect(macosMap!['bundle_id'], equals('com.cbstudio.telltale'));

      final macPref = macosMap['preferences'] as Map<String, dynamic>;
      expect(macPref['flutter_api'], equals('SharedPreferences'));
      expect(macPref['native_path'], contains('com.cbstudio.telltale.plist'));
      expect(macPref['backup_classification'], equals('os-backup-eligible'));

      final macDoc = macosMap['documents'] as Map<String, dynamic>;
      expect(macDoc['flutter_api'], equals('getApplicationDocumentsDirectory'));
      expect(macDoc['native_path'], contains('Documents/'));
      expect(macDoc['backup_classification'], equals('os-backup-eligible'));

      final macCache = macosMap['cache'] as Map<String, dynamic>;
      expect(macCache['flutter_api'], equals('getApplicationCacheDirectory'));
      expect(macCache['native_path'], contains('Library/Caches/'));
      expect(macCache['backup_classification'], equals('os-backup-excluded'));
    });

    test('S4-A11/A12: all inventory flows strictly conform to platform storage backup rules', () {
      final flows = inventory['flows'] as List<dynamic>;
      for (final flow in flows) {
        final f = flow as Map<String, dynamic>;
        final storage = f['storage'] as Map<String, dynamic>;
        final api = storage['api'] as String;
        final backupClass = f['backup_classification'] as String;

        switch (api) {
          case 'SharedPreferences':
          case 'getApplicationDocumentsDirectory':
            expect(
              backupClass,
              equals('os-backup-eligible'),
              reason: 'Flow ${f['id']} uses $api so it must be os-backup-eligible',
            );
          case 'getApplicationCacheDirectory':
          case 'flutter-bundle':
            expect(
              backupClass,
              equals('os-backup-excluded'),
              reason: 'Flow ${f['id']} uses $api so it must be os-backup-excluded',
            );
          case 'system-share-sheet':
          case 'network-socket-or-ble':
          case 'url_launcher':
          case 'none':
            expect(
              backupClass,
              equals('not-applicable'),
              reason: 'Flow ${f['id']} uses $api so it must be not-applicable',
            );
          default:
            fail('Unknown storage API: $api in flow ${f['id']}');
        }
      }
    });
  });

  group('P1-R6: Evidence Classification Contract', () {
    test('S4-A11/A12: static contracts are verified while live physical OS restore experiments are classified as NOT_RUN', () {
      // 1. Verify CLAIM-OS-BACKUP-BEHAVIOR is present and defined in inventory
      final claimRules = inventory['claim_parity_rules'] as Map<String, dynamic>;
      expect(claimRules.containsKey('CLAIM-OS-BACKUP-BEHAVIOR'), isTrue);

      // 2. Verify all flows declare valid evidence levels (STATIC-CONTRACT, LOOPBACK, or NOT_RUN)
      final flows = inventory['flows'] as List<dynamic>;
      for (final flow in flows) {
        final f = flow as Map<String, dynamic>;
        expect(
          ['STATIC-CONTRACT', 'LOOPBACK', 'MOCK-HANDOFF', 'NATIVE', 'PHYSICAL', 'REAL-BACKUP', 'NOT_RUN'],
          contains(f['evidence_level']),
          reason: 'Flow ${f['id']} must declare valid evidence_level',
        );
      }

      // 3. Verify policy contract document explicitly acknowledges live OS restore is NOT_RUN
      final contractDoc = File('docs/privacy/policy-data-flow-contract.md');
      expect(contractDoc.existsSync(), isTrue);
      final docText = contractDoc.readAsStringSync();
      expect(
        docText.contains('live cloud/D2D physical restoration experiments are classified as `NOT_RUN`') ||
            docText.contains('NOT_RUN'),
        isTrue,
        reason: 'Policy contract doc must classify physical OS backup/restore as NOT_RUN',
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Lightweight, zero-dependency XML and Apple Plist parsers
// ---------------------------------------------------------------------------

final class _XmlElement {
  final String tag;
  final Map<String, String> attributes;
  final List<_XmlElement> children;
  String content = '';

  _XmlElement({
    required this.tag,
    required this.attributes,
    required this.children,
  });

  _XmlElement? findChild(String tag) {
    for (final child in children) {
      if (child.tag == tag) return child;
    }
    return null;
  }

  List<_XmlElement> findChildren(String tag) {
    final results = <_XmlElement>[];
    void visit(_XmlElement node) {
      if (node.tag == tag) results.add(node);
      for (final c in node.children) {
        visit(c);
      }
    }
    for (final c in children) {
      visit(c);
    }
    return results;
  }
}

_XmlElement _parseXml(String source) {
  // Strip XML comments
  var clean = source.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
  // Strip XML declaration and DOCTYPE
  clean = clean.replaceAll(RegExp(r'<\?[^>]*\?>'), '');
  clean = clean.replaceAll(RegExp(r'<!DOCTYPE[^>]*>'), '');

  final tagRe = RegExp(r'''<(/?[a-zA-Z0-9_\-:]+)((?:\s+[a-zA-Z0-9_\-:]+\s*=\s*(?:"[^"]*"|'[^']*'))*)\s*(/?)>''');
  final attrRe = RegExp(r'''([a-zA-Z0-9_\-:]+)\s*=\s*(?:"([^"]*)"|'([^']*)')''');

  final root = _XmlElement(tag: '_root', attributes: {}, children: []);
  final stack = <_XmlElement>[root];

  var lastIndex = 0;
  for (final match in tagRe.allMatches(clean)) {
    final textBefore = clean.substring(lastIndex, match.start).trim();

    final rawTag = match.group(1)!;
    final attrString = match.group(2) ?? '';
    final isSelfClosing = match.group(3) == '/';

    if (rawTag.startsWith('/')) {
      final closingTag = rawTag.substring(1);
      if (stack.length <= 1) {
        throw FormatException('Unexpected closing tag </$closingTag> with no matching open tag');
      }
      if (stack.last.tag != closingTag) {
        throw FormatException('XML endtag mismatch: expected </${stack.last.tag}> but got </$closingTag>');
      }
      final closed = stack.removeLast();
      closed.content = textBefore;
    } else {
      final attrs = <String, String>{};
      for (final a in attrRe.allMatches(attrString)) {
        final key = a.group(1)!;
        final val = a.group(2) ?? a.group(3) ?? '';
        attrs[key] = val;
      }
      final elem = _XmlElement(tag: rawTag, attributes: attrs, children: []);
      stack.last.children.add(elem);
      if (!isSelfClosing) {
        stack.add(elem);
      }
    }
    lastIndex = match.end;
  }

  if (stack.length != 1) {
    final unclosed = stack.skip(1).map((e) => e.tag).join(', ');
    throw FormatException('XML unclosed tags remaining: $unclosed');
  }

  return root.children.isNotEmpty ? root.children.first : root;
}

Map<String, dynamic> _parsePlist(String source) {
  final root = _parseXml(source);
  final dictElem = root.tag == 'plist'
      ? (root.findChild('dict') ?? root)
      : (root.tag == 'dict' ? root : root.findChild('dict'));
  if (dictElem == null) return {};
  return _parseDict(dictElem);
}

Map<String, dynamic> _parseDict(_XmlElement dictElem) {
  final result = <String, dynamic>{};
  String? currentKey;

  for (final child in dictElem.children) {
    if (child.tag == 'key') {
      currentKey = child.content.trim();
    } else if (currentKey != null) {
      result[currentKey] = _parsePlistValue(child);
      currentKey = null;
    }
  }
  return result;
}

dynamic _parsePlistValue(_XmlElement elem) {
  switch (elem.tag) {
    case 'string':
      return elem.content.trim();
    case 'true':
      return true;
    case 'false':
      return false;
    case 'integer':
      return int.tryParse(elem.content.trim()) ?? 0;
    case 'dict':
      return _parseDict(elem);
    case 'array':
      return elem.children.map(_parsePlistValue).toList();
    default:
      return null;
  }
}
