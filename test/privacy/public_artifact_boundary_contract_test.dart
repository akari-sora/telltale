/// Contract test for public artifact privacy boundary & governance policy (Issue #11, WS-07 Slice 3).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/share/app_share_platform_bridge.dart';
import 'package:torque_obd/core/share/share_lease_ledger.dart';
import 'package:torque_obd/obd/transcript.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/app_share_entry_controller.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> policy;
  late Map<String, dynamic> classifications;

  setUpAll(() {
    final policyFile = File('docs/privacy/public-artifact-policy.json');
    expect(policyFile.existsSync(), isTrue, reason: 'public-artifact-policy.json must exist');
    policy = jsonDecode(policyFile.readAsStringSync()) as Map<String, dynamic>;
    classifications = policy['classifications'] as Map<String, dynamic>;
  });

  test('S3-A1: policy defines exact schema_version and three classifications', () {
    expect(policy['schema_version'], equals(1));
    expect(policy['policy_id'], equals('ws07-public-artifact-privacy-policy'));
    expect(classifications.containsKey('private-raw'), isTrue);
    expect(classifications.containsKey('public-summary'), isTrue);
    expect(classifications.containsKey('synthetic-canary'), isTrue);
  });

  test('S3-A1 & S3-A12: only public-summary is publishable; raw and canary are forbidden', () {
    final priv = classifications['private-raw'] as Map<String, dynamic>;
    final pub = classifications['public-summary'] as Map<String, dynamic>;
    final canary = classifications['synthetic-canary'] as Map<String, dynamic>;

    expect(priv['publishable'], isFalse);
    expect(priv['mutable'], isFalse);
    expect(pub['publishable'], isTrue);
    expect(pub['mutable'], isFalse);
    expect(canary['publishable'], isFalse);
    expect(canary['mutable'], isFalse);
  });

  test('S3-A1: ten required detection categories are documented in policy', () {
    final categories = policy['rule_categories'] as Map<String, dynamic>;
    const expectedCategories = [
      'vehicle.vin.plain',
      'vehicle.vin.fragmented',
      'vehicle.vin.hex_ascii',
      'device.mac',
      'device.uuid',
      'device.serial',
      'subject.plate_or_customer_id',
      'location.gps',
      'host.user_path',
      'correlation.timestamp_with_identity',
    ];

    for (final cat in expectedCategories) {
      expect(categories.containsKey(cat), isTrue, reason: 'Policy must document rule category: $cat');
    }
  });

  test('S3-A1: boundary documentation exists and is non-empty', () {
    final docFile = File('docs/privacy/public-artifact-boundary.md');
    expect(docFile.existsSync(), isTrue, reason: 'public-artifact-boundary.md must exist');
    expect(docFile.lengthSync(), greaterThan(500));
  });

  test('S3-A15: user-controlled private export kinds remain intact in runtime types', () {
    // Ensures ShareSourceKind enum retains rawTranscript and telemetry kinds
    expect(ShareSourceKind.rawTranscript, isNotNull);
    expect(ShareSourceKind.recoveredTranscript, isNotNull);
    expect(ShareSourceKind.telemetryCsv, isNotNull);
    expect(ShareSourceKind.telemetryJson, isNotNull);
    expect(ShareSourceKind.pidCsv, isNotNull);
  });

  test('S3-A15 & Blocker 8: user-controlled private raw transcript preserves synthetic VIN; rejected as public-summary', () async {
    const syntheticVin = 'TELLTALE0TEST0001';
    final tempDir = await Directory.systemTemp.createTemp('telltale-privacy-contract-');
    addTearDown(() => tempDir.delete(recursive: true));

    final platform = _CapturingPlatform();
    final coordinator = AppShareCoordinator(
      rootDirectory: () async => tempDir,
      policy: const _AllowPolicy(),
      artifactGate: ArtifactOperationGate(),
      platform: platform,
      idSource: () => '1111222233334444aaaabbbbccccdddd',
      nowUtc: () => DateTime.utc(2026, 9, 24),
      availableBytes: (_) async => 64 * 1024 * 1024,
    );
    expect(await coordinator.initialize(), AppShareInitializationOutcome.ready);

    final transcript = ObdTranscript();
    transcript.recordWrite(utf8.encode('09 02\r'), DateTime.utc(2026, 9, 24, 0, 0, 1));
    transcript.recordRead(
      utf8.encode('49 02 01 54 45 4C 4C 54 41 4C 45 30 54 45 53 54 30 30 30 31\r'),
      DateTime.utc(2026, 9, 24, 0, 0, 1),
    );

    final outcome = await AppShareEntryController(coordinator).shareRawTranscript(
      transcript: transcript,
      header: 'Telltale Diagnostic Capture\nVIN=$syntheticVin\n',
      withHex: true,
      subjectAt: DateTime.utc(2026, 9, 24, 0, 0, 1),
    );

    expect(outcome.error, isNull);
    expect(outcome.result, AppShareResult.selected);
    expect(platform.lastPath, isNotNull);

    final stagedFile = File(platform.lastPath!);
    expect(stagedFile.existsSync(), isTrue);

    // 1. Assert private raw export byte truthfulness: synthetic VIN is retained unredacted
    final privateBytes = stagedFile.readAsStringSync();
    expect(privateBytes, contains(syntheticVin), reason: 'Private export must truthfully retain VIN for diagnostic fidelity');
    expect(privateBytes, contains('54 45 4C 4C 54 41 4C 45 30 54 45 53 54 30 30 30 31'));

    // 2. Assert policy forbids publication of private-raw artifacts
    final privPolicy = classifications['private-raw'] as Map<String, dynamic>;
    expect(privPolicy['publishable'], isFalse);

    // 3. Assert public-summary publication gate rejects these dirty bytes with vehicle.vin.plain
    final pubResult = Process.runSync(
      'python3',
      [
        'tool/workshop/public_artifact_guard.py',
        'check',
        '--classification',
        'public-summary',
        platform.lastPath!,
      ],
    );
    expect(pubResult.exitCode, equals(1));
    final pubOutput = '${pubResult.stdout}\n${pubResult.stderr}';
    expect(pubOutput, contains('[FAIL]'));
    expect(pubOutput, contains('vehicle.vin.plain'));

    // 4. Assert private-raw classification is unconditionally rejected by publication check
    final privResult = Process.runSync(
      'python3',
      [
        'tool/workshop/public_artifact_guard.py',
        'check',
        '--classification',
        'private-raw',
        platform.lastPath!,
      ],
    );
    expect(privResult.exitCode, equals(1));
    final privOutput = '${privResult.stdout}\n${privResult.stderr}';
    expect(privOutput, contains('policy.not_publishable'));
  });

  test('S3-A10: positive control clean public summary fixture exists and is valid', () {
    final fixtureFile = File('test/privacy/fixtures/json/clean_public_summary.json');
    expect(fixtureFile.existsSync(), isTrue);
    final fixtureData = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
    expect(fixtureData['benchmark_summary'], isNotNull);
    final summary = fixtureData['benchmark_summary'] as Map<String, dynamic>;
    expect(summary['dtc_code'], equals('P0300'));
    expect(summary['ecu_id'], equals('7E8'));
  });
}

final class _CapturingPlatform implements AppSharePlatform {
  int calls = 0;
  String? lastPath;
  String? lastMime;

  @override
  Future<AppShareResult> share(AppSharePlatformRequest request) async {
    calls += 1;
    lastPath = request.path;
    lastMime = request.mimeType;
    return AppShareResult.selected;
  }
}

final class _AllowPolicy implements AppSharePolicy {
  const _AllowPolicy();

  @override
  SharePreparationPermit? freeze() => const SharePreparationPermit(
        recorderEpoch: 1,
        foregroundEpoch: 1,
        connectionEpoch: 1,
        safetyEpoch: 1,
        connectionClass: ShareConnectionClass.disconnected,
      );

  @override
  SharePermitValidation validate(SharePreparationPermit permit) =>
      const SharePermitValidation.valid();
}
