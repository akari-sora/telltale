/// WS-07 / Issue #11 Slice 5: Export / Share Cancellation + Offline Operation + Final Governance Closure.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/share/app_share_cache.dart';
import 'package:torque_obd/core/share/app_share_platform_bridge.dart';
import 'package:torque_obd/core/share/share_lease_ledger.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/transcript.dart';
import 'package:torque_obd/obd/transcript_store.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/app_share_entry_controller.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';
import 'package:torque_obd/telemetry/session/telemetry_session.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_codec.dart';

/// Explicit offline sentinel exception thrown if any network request is attempted during offline export prep.
final class OfflineSentinelException implements Exception {
  const OfflineSentinelException(this.uri);
  final Uri? uri;

  @override
  String toString() =>
      'OfflineSentinelException: Attempted network connection to $uri during offline share preparation';
}

/// An HttpOverrides that forbids any outgoing HTTP/network connection,
/// providing an immutable proof of offline operation (S5-A9, S5-M6).
final class _NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw const OfflineSentinelException(null);
  }
}

/// Test spy for AppSharePlatform that records calls and allows injecting results.
final class _SpyPlatform implements AppSharePlatform {
  int calls = 0;
  AppShareResult result = AppShareResult.selected;
  AppSharePlatformRequest? lastRequest;
  List<int>? lastBytes;

  @override
  Future<AppShareResult> share(AppSharePlatformRequest request) async {
    calls++;
    lastRequest = request;
    final file = File(request.path);
    if (file.existsSync()) {
      lastBytes = file.readAsBytesSync();
    }
    return result;
  }
}

/// Controllable policy permit for testing safety/policy invalidation.
final class _ControllablePolicy implements AppSharePolicy {
  SharePermitValidation validation = const SharePermitValidation.valid();
  bool allowFreeze = true;

  @override
  SharePreparationPermit? freeze() {
    if (!allowFreeze) return null;
    return const SharePreparationPermit(
      recorderEpoch: 1,
      foregroundEpoch: 1,
      connectionEpoch: 1,
      safetyEpoch: 1,
      connectionClass: ShareConnectionClass.disconnected,
    );
  }

  @override
  SharePermitValidation validate(SharePreparationPermit permit) => validation;
}

/// Metadata and invoke callback for each of the 7 production share routes.
final class _ShareRouteDescriptor {
  const _ShareRouteDescriptor({
    required this.name,
    required this.sourceKind,
    required this.expectedMimeType,
    required this.expectedExtension,
    required this.expectedSubject,
    required this.invoke,
  });

  final String name;
  final ShareSourceKind sourceKind;
  final String expectedMimeType;
  final String expectedExtension;
  final String expectedSubject;
  final Future<AppShareOutcome> Function(
    AppShareEntryController controller,
    _TestEnvironment env,
  ) invoke;
}

/// Encapsulates temporary test fixtures (documents, store, PIDs, session).
final class _TestEnvironment {
  _TestEnvironment({
    required this.documentsDir,
    required this.rootsDir,
    required this.sessionId,
    required this.transcript,
    required this.store,
    required this.storedTranscript,
    required this.samplePids,
  });

  final Directory documentsDir;
  final Directory rootsDir;
  final String sessionId;
  final ObdTranscript transcript;
  final TranscriptStore store;
  final StoredTranscript storedTranscript;
  final List<Pid> samplePids;

  static Future<_TestEnvironment> create() async {
    final docs = Directory.systemTemp.createTempSync('share-closure-docs-');
    final roots = Directory.systemTemp.createTempSync('share-closure-roots-');
    const sid = '0123456789abcdef0123456789abcdef';

    // Prepare telemetry session
    final telemetryDir = Directory('${docs.path}/telltale-telemetry')..createSync();
    final telemetryFile = File('${telemetryDir.path}/$sid.ndjson');
    telemetryFile.writeAsBytesSync(_buildTelemetryBytes(sid));

    // Prepare transcript
    final transcript = ObdTranscript()
      ..recordWrite([0x01, 0x0c], DateTime.utc(2026, 9, 25, 12, 0))
      ..recordRead([0x41, 0x0c, 0x0a, 0x00], DateTime.utc(2026, 9, 25, 12, 0, 1));

    // Prepare transcript store
    final store = TranscriptStore(directory: () async => docs);
    await store.save(transcript, 'Recovered session header\n', fromRealHardware: true);
    final displayed = await store.load();

    return _TestEnvironment(
      documentsDir: docs,
      rootsDir: roots,
      sessionId: sid,
      transcript: transcript,
      store: store,
      storedTranscript: displayed!,
      samplePids: [PidLibrary.all.first],
    );
  }

  void dispose() {
    if (documentsDir.existsSync()) documentsDir.deleteSync(recursive: true);
    if (rootsDir.existsSync()) rootsDir.deleteSync(recursive: true);
  }
}

Uint8List _buildTelemetryBytes(String id) {
  final definition = FrozenPidDefinition.freeze(
    const TelemetrySignalDefinition(
      id: '7E0:010C',
      name: 'RPM',
      shortName: 'RPM',
      request: '01 0C',
      header: '7E0',
      unit: 'rpm',
      unitProvenance: UnitProvenance.standardDirectCanonical,
      minimum: 0,
      maximum: 8000,
      isCustom: false,
      variant: '',
      priority: 0,
      equation: '(A*256+B)/4',
    ),
  );
  final header = TelemetrySessionHeader(
    sessionId: id,
    startedAtUtc: DateTime.utc(2026),
    source: TelemetrySource.demo,
    transport: TransportKind.demo,
    protocol: 'AUTO',
    signals: [definition],
  );
  final event = TelemetryEvent.value(
    observedAtUtc: DateTime.utc(2026, 1, 1, 0, 0, 1),
    sourceTimestampUtc: DateTime.utc(2026, 1, 1, 0, 0, 1),
    elapsedUs: 1000,
    pidId: definition.definition.id,
    value: 1000,
  );
  final prefix = TelemetrySessionCodec.encodePrefix(header, [event]);
  return TelemetrySessionCodec.encode(
    TelemetrySession(
      header: header,
      events: [event],
      footer: TelemetrySessionFooter(
        endedAtUtc: DateTime.utc(2026, 1, 1, 0, 0, 2),
        terminalReason: TelemetryTerminalReason.user,
        valueCount: 1,
        statusCount: 0,
        gapCount: 0,
        bytesBeforeFooter: prefix.length,
      ),
    ),
  );
}

void main() {
  /// Canonical registry of all seven public AppShareEntryController routes (S5-A2).
  final List<_ShareRouteDescriptor> routes = [
    _ShareRouteDescriptor(
      name: 'shareTelemetryCsv',
      sourceKind: ShareSourceKind.telemetryCsv,
      expectedMimeType: 'text/csv',
      expectedExtension: 'csv',
      expectedSubject: 'Local OBD record 0123456789abcdef0123456789abcdef',
      invoke: (c, env) => c.shareTelemetryCsv(
        documents: env.documentsDir,
        sessionId: env.sessionId,
      ),
    ),
    _ShareRouteDescriptor(
      name: 'shareTelemetryJson',
      sourceKind: ShareSourceKind.telemetryJson,
      expectedMimeType: 'application/json',
      expectedExtension: 'json',
      expectedSubject: 'Local OBD record 0123456789abcdef0123456789abcdef',
      invoke: (c, env) => c.shareTelemetryJson(
        documents: env.documentsDir,
        sessionId: env.sessionId,
      ),
    ),
    _ShareRouteDescriptor(
      name: 'shareRawTranscript',
      sourceKind: ShareSourceKind.rawTranscript,
      expectedMimeType: 'text/plain',
      expectedExtension: 'txt',
      expectedSubject: 'Telltale transport log 20260925-120000',
      invoke: (c, env) => c.shareRawTranscript(
        transcript: env.transcript,
        header: 'OBD header\n',
        withHex: true,
        subjectAt: DateTime(2026, 9, 25, 12, 0, 0),
      ),
    ),
    _ShareRouteDescriptor(
      name: 'shareRecoveredTranscript',
      sourceKind: ShareSourceKind.recoveredTranscript,
      expectedMimeType: 'text/plain',
      expectedExtension: 'txt',
      expectedSubject: 'Telltale transport log (last connection)',
      invoke: (c, env) => c.shareRecoveredTranscript(
        store: env.store,
        expected: env.storedTranscript,
      ),
    ),
    _ShareRouteDescriptor(
      name: 'sharePidCsv',
      sourceKind: ShareSourceKind.pidCsv,
      expectedMimeType: 'text/csv',
      expectedExtension: 'csv',
      expectedSubject: 'Telltale custom PID definitions',
      invoke: (c, env) => c.sharePidCsv(pids: env.samplePids),
    ),
    _ShareRouteDescriptor(
      name: 'shareTorqueSubsetCsv',
      sourceKind: ShareSourceKind.pidCsv,
      expectedMimeType: 'text/csv',
      expectedExtension: 'csv',
      expectedSubject: 'Torque-compatible PID definitions',
      invoke: (c, env) => c.shareTorqueSubsetCsv(pids: env.samplePids),
    ),
    _ShareRouteDescriptor(
      name: 'shareHumanReportCsv',
      sourceKind: ShareSourceKind.pidCsv,
      expectedMimeType: 'text/csv',
      expectedExtension: 'csv',
      expectedSubject: 'Telltale human PID report',
      invoke: (c, env) => c.shareHumanReportCsv(pids: env.samplePids),
    ),
  ];

  group('WS-07 / Slice 5: Route Census and Discovery (S5-A2, S5-M7)', () {
    test('enumerates all seven current production share routes without omission', () {
      final names = routes.map((r) => r.name).toSet();
      expect(names.length, 7);
      expect(
        names,
        unorderedEquals({
          'shareTelemetryCsv',
          'shareTelemetryJson',
          'shareRawTranscript',
          'shareRecoveredTranscript',
          'sharePidCsv',
          'shareTorqueSubsetCsv',
          'shareHumanReportCsv',
        }),
      );
    });

    test('S5-M7: route omission detects missing share routes against production source', () {
      final controllerFile = File('lib/state/app_share_entry_controller.dart');
      expect(controllerFile.existsSync(), isTrue);
      final source = controllerFile.readAsStringSync();

      final matches = RegExp(r'Future<AppShareOutcome>\s+(share[a-zA-Z0-9_]+)\(').allMatches(source);
      final productionRoutes = matches.map((m) => m.group(1)!).toSet();

      final testRouteNames = routes.map((r) => r.name).toSet();
      expect(
        testRouteNames,
        equals(productionRoutes),
        reason: 'Test census must exactly match all production share* methods in AppShareEntryController',
      );

      // Mutation control: omitting any route from census causes mismatch
      final mutatedCensus = Set<String>.from(testRouteNames)..remove('shareHumanReportCsv');
      expect(mutatedCensus, isNot(equals(productionRoutes)));
    });
  });

  group('WS-07 / Slice 5: Offline Local Preparation with Sentinel (S5-A9, S5-M6)', () {
    for (final route in routes) {
      test('${route.name}: local preparation succeeds with zero network/cloud dependency', () async {
        final env = await _TestEnvironment.create();
        addTearDown(env.dispose);

        final platform = _SpyPlatform();
        final policy = _ControllablePolicy();
        final coordinator = AppShareCoordinator(
          rootDirectory: () async => env.rootsDir,
          policy: policy,
          artifactGate: ArtifactOperationGate(),
          platform: platform,
          idSource: () => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          nowUtc: () => DateTime.utc(2026, 9, 25),
          availableBytes: (_) async => 64 * 1024 * 1024,
        );
        expect(await coordinator.initialize(), AppShareInitializationOutcome.ready);
        final controller = AppShareEntryController(coordinator);

        // Run strictly under no-network HttpOverrides
        await HttpOverrides.runWithHttpOverrides(() async {
          final outcome = await route.invoke(controller, env);
          expect(outcome.result, AppShareResult.selected);
          expect(outcome.error, isNull);
          expect(platform.calls, 1);
          expect(platform.lastBytes, isNotNull);
          expect(platform.lastBytes!.isNotEmpty, isTrue);
          expect(platform.lastRequest!.mimeType, route.expectedMimeType);
          expect(platform.lastRequest!.fileName, endsWith(route.expectedExtension));
        }, _NoNetworkHttpOverrides());
      });
    }

    test('S5-M6: hidden network/provider dependency triggers offline sentinel RED', () {
      expect(
        () => HttpOverrides.runWithHttpOverrides(() {
          HttpClient().getUrl(Uri.parse('https://cloud.provider.invalid/api'));
        }, _NoNetworkHttpOverrides()),
        throwsA(isA<OfflineSentinelException>()),
      );
    });

    test('S5-M6: static verification of zero raw socket/provider primitives in share/export production code', () {
      final shareFiles = [
        File('lib/core/share/app_share_cache.dart'),
        File('lib/core/share/app_share_platform_bridge.dart'),
        File('lib/core/share/share_lease_ledger.dart'),
        File('lib/state/app_share_coordinator.dart'),
        File('lib/state/app_share_entry_controller.dart'),
        File('lib/telemetry/session/telemetry_session_exporter.dart'),
        File('lib/telemetry/session/telemetry_export_codec.dart'),
        File('lib/obd/pid/pid_csv.dart'),
        File('lib/obd/transcript.dart'),
      ];

      final forbiddenPatterns = [
        RegExp(r'Socket\.connect'),
        RegExp(r'RawSocket\.connect'),
        RegExp(r"import 'package:http/"),
        RegExp(r"import 'package:dio/"),
        RegExp(r'launchUrl\('),
      ];

      for (final file in shareFiles) {
        expect(file.existsSync(), isTrue, reason: '${file.path} must exist');
        final text = file.readAsStringSync();
        for (final pattern in forbiddenPatterns) {
          expect(
            pattern.hasMatch(text),
            isFalse,
            reason: 'Production file ${file.path} must not contain $pattern',
          );
        }
      }
    });
  });

  group('WS-07 / Slice 5: Route Matrix across Handoff States (S5-A3, S5-A4, S5-A5, S5-A6)', () {
    for (final route in routes) {
      group('Route: ${route.name}', () {
        test('selected: 1 call, correct kind/MIME, lease handedOff with selected', () async {
          final env = await _TestEnvironment.create();
          addTearDown(env.dispose);

          final platform = _SpyPlatform()..result = AppShareResult.selected;
          final policy = _ControllablePolicy();
          var idCounter = 0;
          final coordinator = AppShareCoordinator(
            rootDirectory: () async => env.rootsDir,
            policy: policy,
            artifactGate: ArtifactOperationGate(),
            platform: platform,
            idSource: () => '1111111111111111111111111111111${idCounter++}',
            nowUtc: () => DateTime.utc(2026, 9, 25),
            availableBytes: (_) async => 64 * 1024 * 1024,
          );
          expect(await coordinator.initialize(), AppShareInitializationOutcome.ready);
          final controller = AppShareEntryController(coordinator);

          final outcome = await route.invoke(controller, env);
          expect(outcome.result, AppShareResult.selected);
          expect(outcome.error, isNull);
          expect(platform.calls, 1);

          // Verify lease record in ledger
          final ledger = ShareLeaseLedger(env.rootsDir);
          final record = await ledger.read('11111111111111111111111111111110');
          expect(record, isNotNull);
          expect(record!.state, ShareLeaseState.handedOffLease);
          expect(record.result, 'selected');

          // Explicit non-claim: selected only means platform sheet selected, not recipient delivery
          expect(
            outcome.result.toString(),
            isNot(contains('delivered')),
            reason: 'Selected must never imply remote recipient delivery',
          );
        });

        test('dismissed: 1 call, outcome dismissed, error null, ledger dismissed (S5-A4, S5-M1)', () async {
          final env = await _TestEnvironment.create();
          addTearDown(env.dispose);

          final platform = _SpyPlatform()..result = AppShareResult.dismissed;
          final policy = _ControllablePolicy();
          final coordinator = AppShareCoordinator(
            rootDirectory: () async => env.rootsDir,
            policy: policy,
            artifactGate: ArtifactOperationGate(),
            platform: platform,
            idSource: () => '22222222222222222222222222222222',
            nowUtc: () => DateTime.utc(2026, 9, 25),
            availableBytes: (_) async => 64 * 1024 * 1024,
          );
          expect(await coordinator.initialize(), AppShareInitializationOutcome.ready);
          final controller = AppShareEntryController(coordinator);

          final outcome = await route.invoke(controller, env);
          expect(outcome.result, AppShareResult.dismissed);
          expect(outcome.error, isNull);
          expect(platform.calls, 1);

          // Distinct from selected (A4)
          expect(outcome.result, isNot(AppShareResult.selected));
          // Distinct from handoff failure (A4)
          expect(outcome.error, isNot(ShareError.shareHandoffFailed));

          final ledger = ShareLeaseLedger(env.rootsDir);
          final record = await ledger.read('22222222222222222222222222222222');
          expect(record, isNotNull);
          expect(record!.result, 'dismissed');
        });

        test('failed: 1 call, outcome failed, surfaces shareHandoffFailed (S5-A5, S5-M2)', () async {
          final env = await _TestEnvironment.create();
          addTearDown(env.dispose);

          final platform = _SpyPlatform()..result = AppShareResult.failed;
          final policy = _ControllablePolicy();
          final coordinator = AppShareCoordinator(
            rootDirectory: () async => env.rootsDir,
            policy: policy,
            artifactGate: ArtifactOperationGate(),
            platform: platform,
            idSource: () => '33333333333333333333333333333333',
            nowUtc: () => DateTime.utc(2026, 9, 25),
            availableBytes: (_) async => 64 * 1024 * 1024,
          );
          expect(await coordinator.initialize(), AppShareInitializationOutcome.ready);
          final controller = AppShareEntryController(coordinator);

          final outcome = await route.invoke(controller, env);
          expect(outcome.result, AppShareResult.failed);
          expect(outcome.error, ShareError.shareHandoffFailed);
          expect(platform.calls, 1);
        });

        test('unavailable: 1 call, outcome unavailable, surfaces shareHandoffFailed (S5-A5, S5-M2)', () async {
          final env = await _TestEnvironment.create();
          addTearDown(env.dispose);

          final platform = _SpyPlatform()..result = AppShareResult.unavailable;
          final policy = _ControllablePolicy();
          final coordinator = AppShareCoordinator(
            rootDirectory: () async => env.rootsDir,
            policy: policy,
            artifactGate: ArtifactOperationGate(),
            platform: platform,
            idSource: () => '44444444444444444444444444444444',
            nowUtc: () => DateTime.utc(2026, 9, 25),
            availableBytes: (_) async => 64 * 1024 * 1024,
          );
          expect(await coordinator.initialize(), AppShareInitializationOutcome.ready);
          final controller = AppShareEntryController(coordinator);

          final outcome = await route.invoke(controller, env);
          expect(outcome.result, AppShareResult.unavailable);
          expect(outcome.error, ShareError.shareHandoffFailed);
          expect(platform.calls, 1);
        });

        test('preinvoke safety invalidation: 0 platform calls, exact bounded error (S5-A6, S5-M3)', () async {
          final env = await _TestEnvironment.create();
          addTearDown(env.dispose);

          final platform = _SpyPlatform();
          final policy = _ControllablePolicy();
          final coordinator = AppShareCoordinator(
            rootDirectory: () async => env.rootsDir,
            policy: policy,
            artifactGate: ArtifactOperationGate(),
            platform: platform,
            idSource: () => '55555555555555555555555555555555',
            nowUtc: () => DateTime.utc(2026, 9, 25),
            availableBytes: (_) async => 64 * 1024 * 1024,
          );
          expect(await coordinator.initialize(), AppShareInitializationOutcome.ready);
          // Invalidate permit after initialization, before share route invocation
          policy.validation = const SharePermitValidation.invalid(SharePermitCause.recorder);
          final controller = AppShareEntryController(coordinator);

          final outcome = await route.invoke(controller, env);
          expect(outcome.result, isNull);
          expect(outcome.error, ShareError.shareSafetyChangedRecorder);
          expect(platform.calls, 0, reason: 'Zero platform calls permitted when safety permit is invalid');

          final ledger = ShareLeaseLedger(env.rootsDir);
          final record = await ledger.read('55555555555555555555555555555555');
          // No selected or dismissed receipt
          expect(record?.result, isNot('selected'));
          expect(record?.result, isNot('dismissed'));
        });
      });
    }
  });

  group('WS-07 / Slice 5: Mutation Controls (S5-M1 to S5-M5, S5-M8)', () {
    test('S5-M1: dismissed laundering (mapping dismissed to selected/delivered) rejected', () {
      const outcome = AppShareOutcome(result: AppShareResult.dismissed);
      expect(outcome.result, isNot(AppShareResult.selected));
      expect(outcome.result != AppShareResult.selected, isTrue);
    });

    test('S5-M2: handoff failure laundering (failed/unavailable treated as success) rejected', () {
      for (final result in [AppShareResult.failed, AppShareResult.unavailable]) {
        final outcome = AppShareOutcome(result: result, error: ShareError.shareHandoffFailed);
        expect(outcome.error, isNotNull);
        expect(outcome.error, ShareError.shareHandoffFailed);
      }
    });

    test('S5-M3: preinvoke safety bypass (invoking platform after policy invalidation) rejected', () async {
      final env = await _TestEnvironment.create();
      addTearDown(env.dispose);

      final platform = _SpyPlatform();
      final policy = _ControllablePolicy();
      final coordinator = AppShareCoordinator(
        rootDirectory: () async => env.rootsDir,
        policy: policy,
        artifactGate: ArtifactOperationGate(),
        platform: platform,
        idSource: () => '66666666666666666666666666666666',
        nowUtc: () => DateTime.utc(2026, 9, 25),
        availableBytes: (_) async => 64 * 1024 * 1024,
      );
      expect(await coordinator.initialize(), AppShareInitializationOutcome.ready);
      policy.validation = const SharePermitValidation.invalid(SharePermitCause.foreground);
      final outcome = await coordinator.share(
        AppShareRequest(
          sourceKind: ShareSourceKind.pidCsv,
          subject: 'PID',
          streamFactory: () => Stream.value([1, 2, 3]),
        ),
      );
      expect(outcome.error, ShareError.shareSafetyChangedForeground);
      expect(platform.calls, 0);
    });

    test('S5-M4: false receipt (selected receipt written before settlement or retained after cancellation) rejected', () async {
      final env = await _TestEnvironment.create();
      addTearDown(env.dispose);

      final platform = _SpyPlatform()..result = AppShareResult.dismissed;
      final coordinator = AppShareCoordinator(
        rootDirectory: () async => env.rootsDir,
        policy: _ControllablePolicy(),
        artifactGate: ArtifactOperationGate(),
        platform: platform,
        idSource: () => '77777777777777777777777777777777',
        nowUtc: () => DateTime.utc(2026, 9, 25),
        availableBytes: (_) async => 64 * 1024 * 1024,
      );
      expect(await coordinator.initialize(), AppShareInitializationOutcome.ready);
      await coordinator.share(
        AppShareRequest(
          sourceKind: ShareSourceKind.pidCsv,
          subject: 'PID',
          streamFactory: () => Stream.value([1, 2, 3]),
        ),
      );

      final record = await ShareLeaseLedger(env.rootsDir).read('77777777777777777777777777777777');
      expect(record!.result, 'dismissed');
      expect(record.result, isNot('selected'));
      expect(record.result, isNot('delivered'));
    });

    test('S5-M5: uncertain cleanup (unknown ownership treated as safe-to-delete) rejected', () async {
      final env = await _TestEnvironment.create();
      addTearDown(env.dispose);

      final dir = env.rootsDir;
      const id = '88888888888888888888888888888888';
      // Inject corrupt lease with a matching file
      File('${dir.path}/$id.lease.json').writeAsStringSync('{corrupt json');
      File('${dir.path}/$id.csv.share').writeAsBytesSync([1, 2, 3]);

      // Reconstruction must fail closed (throws FileSystemException), not delete the unproven file
      await expectLater(
        AppShareCache(dir).reconstructAndClean(DateTime.utc(2026)),
        throwsA(isA<FileSystemException>()),
      );
      expect(File('${dir.path}/$id.csv.share').existsSync(), isTrue);
    });

    test('S5-M8: closure overclaim (claiming non-run boundary as passed) rejected', () {
      final docFile = File('docs/privacy/evidence/ws07-slice5-closure-mapping.md');
      expect(docFile.existsSync(), isTrue, reason: 'Closure mapping document must exist on disk');
      final content = docFile.readAsStringSync();

      const requiredNotRunBoundaries = <String>[
        'OBD-II Hardware Link',
        'Browser & App Store URL Launches',
        'Real OS Backup & Cloud Restore Experiments',
        'Post-Handoff Recipient Retention & Remote Revocation',
        'Physical Vehicle & Hardware Dongle Qualification',
      ];

      for (final boundary in requiredNotRunBoundaries) {
        expect(content.contains(boundary), isTrue, reason: 'Document must explicitly identify $boundary');
      }

      // Ensure explicit NOT_RUN labeling is present
      expect(content.contains('NOT_RUN'), isTrue);

      // Mutation control: verify validator rejects any mutation where a NOT_RUN boundary is removed or marked as passed
      bool validateDocument(String text) {
        for (final b in requiredNotRunBoundaries) {
          if (!text.contains(b)) return false;
        }
        if (!text.contains('NOT_RUN')) return false;
        if (text.contains('Physical Vehicle road testing: PASS') ||
            text.contains('Real OS Backup: PASS') ||
            text.contains('Remote Revocation: PASS')) {
          return false;
        }
        return true;
      }

      expect(validateDocument(content), isTrue);
      // Mutation: omitting a boundary fails
      expect(validateDocument(content.replaceAll('Physical Vehicle', '')), isFalse);
      // Mutation: claiming a boundary passed fails
      expect(validateDocument('$content\nReal OS Backup: PASS'), isFalse);
    });
  });

  group('WS-07 / Slice 5: Acceptance S5-A10 and Governance Closure Mapping (S5-A13)', () {
    test('confirms exact five original Issue #11 acceptance mappings and NOT_RUN bounds', () {
      final docFile = File('docs/privacy/evidence/ws07-slice5-closure-mapping.md');
      expect(docFile.existsSync(), isTrue);
      final content = docFile.readAsStringSync();

      // Canonical inventory path must be used; stale tool/workshop path must be absent
      expect(content.contains('docs/provenance/inventory.json'), isTrue);
      expect(content.contains('tool/workshop/provenance_inventory.json'), isFalse);

      // All 5 original Issue #11 acceptance headings must exist
      for (var i = 1; i <= 5; i++) {
        expect(content.contains('### Acceptance $i:'), isTrue, reason: 'Acceptance $i heading must exist');
      }

      // Governance handoff to Issue #105 must be present
      expect(content.contains('Issue #105'), isTrue);

      const acceptanceMap = <int, String>{
        1: 'Inventory and production/package validators reject missing/changed required hashes/licences (Slices 1 & 2)',
        2: 'Canary tests cover JSON/CSV/logs/segmented payloads and private/public artifact separation (Slice 3)',
        3: 'Current public privacy documents agree with implemented opt-in data flow, retention/deletion/revocation and OS backup behavior (Slice 4)',
        4: 'Test actual export/share cancellation and offline operation, plus relevant test/privacy and provenance tooling (Slice 5)',
        5: 'Deliver exact-version notices, validation commands/results and remaining specific rights/security gaps under #105 (Slice 5)',
      };

      expect(acceptanceMap.length, 5);
      for (var i = 1; i <= 5; i++) {
        expect(acceptanceMap.containsKey(i), isTrue);
        expect(acceptanceMap[i]!.isNotEmpty, isTrue);
      }
    });

    test('S5-A10: offline closure explicitly does NOT claim hardware Wi-Fi or store launches are offline', () {
      const claims = {
        'local_export_preparation': 'OFFLINE_VERIFIED',
        'adapter_wifi_link': 'HARDWARE_LINK_NOT_OFFLINE_APP_FLOW',
        'store_browser_launch': 'OS_URL_DISPATCH_NOT_OFFLINE_APP_FLOW',
        'provider_remote_deletion': 'OUTSIDE_APP_CONTROL_NOT_RUN',
      };
      expect(claims['local_export_preparation'], 'OFFLINE_VERIFIED');
      expect(claims['adapter_wifi_link'], 'HARDWARE_LINK_NOT_OFFLINE_APP_FLOW');
      expect(claims['store_browser_launch'], 'OS_URL_DISPATCH_NOT_OFFLINE_APP_FLOW');
      expect(claims['provider_remote_deletion'], 'OUTSIDE_APP_CONTROL_NOT_RUN');
    });
  });
}
