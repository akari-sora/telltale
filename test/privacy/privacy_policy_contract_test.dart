/// Contract test for user-visible privacy policy 4-way parity (Issue #11, WS-07 Slice 4).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> inventory;
  late Map<String, dynamic> claims;
  late String mdContent;
  late String htmlContent;
  late String mdZh;
  late String mdEn;
  late String htmlZh;
  late String htmlEn;

  setUpAll(() {
    final inventoryFile = File('docs/privacy/data-flow-inventory.json');
    expect(inventoryFile.existsSync(), isTrue, reason: 'data-flow-inventory.json must exist');
    inventory = jsonDecode(inventoryFile.readAsStringSync()) as Map<String, dynamic>;
    claims = inventory['claims'] as Map<String, dynamic>;

    final mdFile = File('PRIVACY.md');
    expect(mdFile.existsSync(), isTrue, reason: 'PRIVACY.md must exist');
    mdContent = mdFile.readAsStringSync();

    final htmlFile = File('docs/privacy.html');
    expect(htmlFile.existsSync(), isTrue, reason: 'docs/privacy.html must exist');
    htmlContent = htmlFile.readAsStringSync();

    // Partition Markdown
    final mdParts = mdContent.split(RegExp(r'\n---\n(?=\s*#\s+Telltale Privacy Policy)'));
    expect(mdParts.length, greaterThanOrEqualTo(2), reason: 'PRIVACY.md must contain distinct zh and en partitions');
    mdZh = mdParts[0];
    mdEn = mdParts[1];

    // Partition HTML
    final zhHtmlMatch = RegExp(r'<section\s+id="zh-policy"[^>]*>(.*?)</section>', dotAll: true).firstMatch(htmlContent);
    final enHtmlMatch = RegExp(r'<section\s+id="en-policy"[^>]*>(.*?)</section>', dotAll: true).firstMatch(htmlContent);
    expect(zhHtmlMatch, isNotNull, reason: 'docs/privacy.html must contain zh-policy section');
    expect(enHtmlMatch, isNotNull, reason: 'docs/privacy.html must contain en-policy section');
    htmlZh = zhHtmlMatch!.group(1)!;
    htmlEn = enHtmlMatch!.group(1)!;
  });

  test('S4-A4: inventory declares exact 12 policy claims', () {
    const expectedClaims = [
      'CLAIM-DEVELOPER-NO-COLLECTION',
      'CLAIM-LOCAL-STORAGE-PARTITION',
      'CLAIM-DIAGNOSTIC-RAW-BYTES',
      'CLAIM-TELEMETRY-NDJSON',
      'CLAIM-SHARE-CACHE-LIFECYCLE',
      'CLAIM-USER-CONTROLLED-SHARE',
      'CLAIM-NETWORK-ADAPTER-ONLY',
      'CLAIM-EXTERNAL-AFFILIATE-LINKS',
      'CLAIM-PERMISSIONS-MINIMAL',
      'CLAIM-NO-THIRD-PARTY-SDKS',
      'CLAIM-OS-BACKUP-BEHAVIOR',
      'CLAIM-OPEN-SOURCE-VERIFIABLE',
    ];

    expect(claims.keys.length, equals(12));
    for (final claimId in expectedClaims) {
      expect(claims.containsKey(claimId), isTrue, reason: 'Declared claims must include $claimId');
    }
  });

  test('S4-A4: all 12 claims are explicitly anchored and unique in PRIVACY.md (zh and en)', () {
    for (final claimId in claims.keys) {
      final marker = '<!-- claim: $claimId -->';
      final zhCount = marker.allMatches(mdZh).length;
      final enCount = marker.allMatches(mdEn).length;
      expect(zhCount, equals(1), reason: 'PRIVACY.md zh section must contain exactly 1 anchor for $claimId');
      expect(enCount, equals(1), reason: 'PRIVACY.md en section must contain exactly 1 anchor for $claimId');
    }
  });

  test('S4-A4: all 12 claims are explicitly anchored and unique in docs/privacy.html (zh and en)', () {
    for (final claimId in claims.keys) {
      final markerAttr = 'data-claim-id="$claimId"';
      final inZhCount = markerAttr.allMatches(htmlZh).length;
      final inEnCount = markerAttr.allMatches(htmlEn).length;
      expect(inZhCount, equals(1), reason: 'docs/privacy.html zh section must contain exactly 1 anchor for $claimId');
      expect(inEnCount, equals(1), reason: 'docs/privacy.html en section must contain exactly 1 anchor for $claimId');
    }
  });

  test('S4-A4: policy claim containers do not possess hidden or display:none attributes', () {
    for (final secId in ['zh-policy', 'en-policy']) {
      final secTagMatch = RegExp('<section\\b([^>]*\\bid="$secId"[^>]*)>').firstMatch(htmlContent);
      expect(secTagMatch, isNotNull);
      final secAttrs = secTagMatch!.group(1)!;
      expect(secAttrs.contains('hidden'), isFalse, reason: 'Section container $secId must not have hidden attribute');
      expect(secAttrs.contains('aria-hidden="true"'), isFalse, reason: 'Section container $secId must not have aria-hidden');
      expect(secAttrs.contains('display:none'), isFalse, reason: 'Section container $secId must not have display:none');
      expect(secAttrs.contains('display: none'), isFalse, reason: 'Section container $secId must not have display: none');
    }

    for (final section in [htmlZh, htmlEn]) {
      final matches = RegExp(r'<div\b([^>]*\bdata-claim-id="[^"]+"[^>]*)>', dotAll: true).allMatches(section);
      for (final match in matches) {
        final tag = match.group(1)!;
        expect(tag.contains('hidden'), isFalse, reason: 'Claim container must not have hidden attribute');
        expect(tag.contains('aria-hidden="true"'), isFalse, reason: 'Claim container must not have aria-hidden');
        expect(tag.contains('display:none'), isFalse, reason: 'Claim container must not have display:none');
        expect(tag.contains('display: none'), isFalse, reason: 'Claim container must not have display: none');
      }
    }
  });

  test('S4-A4: developer non-collection polarity is uniform across all four presentations', () {
    // Chinese assertions
    expect(mdZh, contains('不收集資料'));
    expect(mdZh, contains('沒有伺服器'));
    expect(htmlZh, contains('不收集資料'));
    expect(htmlZh, contains('沒有伺服器'));

    // English assertions
    expect(mdEn, contains('collects nothing'));
    expect(mdEn, contains('We have no servers'));
    expect(htmlEn, contains('collects nothing'));
    expect(htmlEn, contains('We have no servers'));
  });

  test('S4-A4: zero forbidden contradictory terms exist in any policy surface', () {
    const forbiddenZh = [
      '保證不備份',
      '絕不備份',
      '24小時必定刪除',
      '24 小時必定刪除',
      '必定刪除外部',
      '召回外部副本',
      '保證召回外部',
    ];
    const forbiddenEn = [
      'guarantee no backup',
      'never backed up',
      'strictly deleted within 24',
      'mandatory 24-hour deletion',
      'recall external copies',
      'revoke delivered copies',
    ];

    for (final term in forbiddenZh) {
      expect(mdZh.contains(term), isFalse, reason: 'mdZh contains forbidden term $term');
      expect(htmlZh.contains(term), isFalse, reason: 'htmlZh contains forbidden term $term');
    }
    for (final term in forbiddenEn) {
      expect(mdEn.toLowerCase().contains(term.toLowerCase()), isFalse, reason: 'mdEn contains forbidden term $term');
      expect(htmlEn.toLowerCase().contains(term.toLowerCase()), isFalse, reason: 'htmlEn contains forbidden term $term');
    }
  });

  test('S4-A5: storage partition claims distinguish transcript, telemetry, and share cache', () {
    // Chinese assertions
    expect(mdZh, contains('last-session.log'));
    expect(mdZh, contains('telltale-telemetry/'));
    expect(mdZh, contains('telltale-app-shares/'));
    expect(htmlZh, contains('last-session.log'));
    expect(htmlZh, contains('telltale-telemetry/'));
    expect(htmlZh, contains('telltale-app-shares/'));

    // English assertions
    expect(mdEn, contains('last-session.log'));
    expect(mdEn, contains('telltale-telemetry/'));
    expect(mdEn, contains('telltale-app-shares/'));
    expect(htmlEn, contains('last-session.log'));
    expect(htmlEn, contains('telltale-telemetry/'));
    expect(htmlEn, contains('telltale-app-shares/'));
  });

  test('S4-A5: telemetry export policy clarifies user-authored signal names and notes are preserved', () {
    // Chinese assertions
    expect(mdZh, contains('自訂訊號名稱、公式、單位與備註是由使用者自行編寫'));
    expect(htmlZh, contains('自訂訊號名稱、公式、單位與備註是由使用者自行編寫'));

    // English assertions
    expect(mdEn, contains('user-authored signal names, equations, units, and notes are preserved'));
    expect(htmlEn, contains('user-authored signal names, equations, units, and notes are preserved'));
  });

  test('S4-A7: affiliate recommended purchase links disclaim appended telemetry or identifiers', () {
    // Chinese assertions
    expect(mdZh, contains('絕不附加車輛 VIN、診斷紀錄、裝置識別碼'));
    expect(htmlZh, contains('絕不附加車輛 VIN、診斷紀錄、裝置識別碼'));

    // English assertions
    expect(mdEn, contains('never appends VIN, telemetry, device identifiers'));
    expect(htmlEn, contains('never appends VIN, telemetry, device identifiers'));
  });

  test('S4-A8: network access policy clarifies user-configured adapter socket endpoint without false blanket LAN filter', () {
    // Chinese assertions
    expect(mdZh, contains('192.168.0.10:35000'));
    expect(mdZh, contains('轉接器連線目的地由使用者自行設定'));
    expect(htmlZh, contains('192.168.0.10:35000'));
    expect(htmlZh, contains('轉接器連線目的地由使用者自行設定'));

    // English assertions
    expect(mdEn, contains('192.168.0.10:35000'));
    expect(mdEn, contains('destination endpoints depend on user settings'));
    expect(htmlEn, contains('192.168.0.10:35000'));
    expect(htmlEn, contains('destination endpoints depend on user settings'));
  });

  test('S4-A9: share cache lifecycle states 15-minute eligible and 24-hour due without false daemon guarantee', () {
    // Chinese assertions
    expect(mdZh, contains('15 分鐘'));
    expect(mdZh, contains('24 小時'));
    expect(mdZh, contains('非作業系統背景排程保證'));
    expect(htmlZh, contains('15 分鐘'));
    expect(htmlZh, contains('24 小時'));
    expect(htmlZh, contains('非作業系統背景排程保證'));

    // English assertions
    expect(mdEn, contains('15-minute'));
    expect(mdEn, contains('24-hour'));
    expect(mdEn, contains('not an OS background daemon guarantee'));
    expect(htmlEn, contains('15-minute'));
    expect(htmlEn, contains('24-hour'));
    expect(htmlEn, contains('not an OS background daemon guarantee'));
  });

  test('S4-A9: vehicle catalog offline bundling is distinguished from developer maintainer update tools', () {
    // Chinese assertions
    expect(mdZh, contains('update_us_vehicle_catalog.py'));
    expect(mdZh, contains('完全離線運作'));
    expect(htmlZh, contains('update_us_vehicle_catalog.py'));
    expect(htmlZh, contains('完全離線運作'));

    // English assertions
    expect(mdEn, contains('update_us_vehicle_catalog.py'));
    expect(mdEn, contains('operates strictly offline'));
    expect(htmlEn, contains('update_us_vehicle_catalog.py'));
    expect(htmlEn, contains('operates strictly offline'));
  });

  test('S4-A10: local deletion disclaims remote recipient recall and previous OS backups', () {
    // Chinese assertions
    expect(mdZh, contains('無法召回'));
    expect(htmlZh, contains('無法召回'));

    // English assertions
    expect(mdEn, contains('cannot recall'));
    expect(htmlEn, contains('cannot recall'));
  });

  test('S4-A11: OS backup behavior warns of cloud and D2D replication without false local-only blanket claims', () {
    // Chinese assertions
    expect(mdZh, contains('作業系統備份'));
    expect(mdZh, contains('解除安裝'));
    expect(htmlZh, contains('作業系統備份'));
    expect(htmlZh, contains('解除安裝'));

    // English assertions
    expect(mdEn, contains('system backup'));
    expect(mdEn, contains('Uninstalling'));
    expect(htmlEn, contains('system backup'));
    expect(htmlEn, contains('Uninstalling'));
  });
}
