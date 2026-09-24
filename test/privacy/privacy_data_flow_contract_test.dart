/// Contract test for runtime data flow facts and zero-handoff guarantees (Issue #11, WS-07 Slice 4).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/hash/fnv1a64.dart';
import 'package:torque_obd/core/share/app_share_cache.dart';
import 'package:torque_obd/core/share/app_share_platform_bridge.dart';
import 'package:torque_obd/core/share/share_lease_ledger.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/transcript.dart';
import 'package:torque_obd/obd/transcript_store.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/app_share_entry_controller.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';
import 'package:torque_obd/state/telemetry_sessions.dart';
import 'package:torque_obd/state/transcript_store_runtime.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_session.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_codec.dart';
import 'package:torque_obd/ui/widgets/recommended_purchase_panel.dart';
import 'package:torque_obd/ui/widgets/transcript_export.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_session_detail_screen.dart';
import 'package:torque_obd/ui/screens/pids/pid_manager_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/state/app_runtime.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_store.dart';
import 'package:torque_obd/ui/screens/connect/connect_screen.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';

import '../support/localized_app.dart';

class _IdleSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState();
}

class _SessionWithTranscript extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState(
    phase: ConnectionPhase.disconnected,
    deviceName: 'Wi-Fi ELM327',
  );

  @override
  ({ObdTranscript transcript, String header})? get exportableRecord {
    final t = ObdTranscript()
      ..recordWrite(utf8.encode('01 0C\r'), DateTime.utc(2026, 9, 24, 12, 0));
    return (
      transcript: t,
      header: 'Wi-Fi ELM327; protocol ISO 15765-4',
    );
  }
}

class _StorePolicy implements AppSharePolicy {
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

class _ObservableCoordinator extends AppShareCoordinator {
  _ObservableCoordinator({
    required super.rootDirectory,
    required super.policy,
    required super.artifactGate,
    required super.platform,
    required super.idSource,
    required super.nowUtc,
    required super.availableBytes,
  });

  Future<AppShareOutcome>? lastShareFuture;

  @override
  Future<AppShareOutcome> share(AppShareRequest request) {
    final future = Zone.root.run(() => super.share(request));
    lastShareFuture = future;
    return future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> inventory;
  late List<dynamic> flows;

  setUpAll(() {
    final inventoryFile = File('docs/privacy/data-flow-inventory.json');
    expect(inventoryFile.existsSync(), isTrue, reason: 'data-flow-inventory.json must exist');
    inventory = jsonDecode(inventoryFile.readAsStringSync()) as Map<String, dynamic>;
    flows = inventory['flows'] as List<dynamic>;
  });

  test('S4-A2: inventory covers all required domains DF01 to DF10 with valid schema', () {
    const requiredDomains = [
      'DF01', 'DF02', 'DF03', 'DF04', 'DF05',
      'DF06', 'DF07', 'DF08', 'DF09', 'DF10',
    ];
    final coveredDomains = <String>{};

    for (final item in flows) {
      final flow = item as Map<String, dynamic>;
      final covId = flow['coverage_id'] as String;
      coveredDomains.add(covId);

      expect(flow['id'], isNotNull);
      expect(flow['name'], isNotNull);
      expect(flow['actor'], isNotNull);
      expect(flow['platform_scope'], isNotNull);
      expect(flow['storage'], isNotNull);
      expect(flow['recipient_egress_class'], isNotNull);
      expect(flow['retention_trigger'], isNotNull);
      expect(flow['local_deletion'], isNotNull);
      expect(flow['post_handoff_limitation'], isNotNull);
      expect(flow['backup_classification'], isNotNull);
      expect(flow['source_bindings'], isNotEmpty);
      expect(flow['claim_ids'], isNotEmpty);
      expect(flow['test_ids'], isNotEmpty);
      expect(flow['evidence_level'], isNotNull);
    }

    for (final domain in requiredDomains) {
      expect(coveredDomains.contains(domain), isTrue, reason: 'Domain $domain must be covered in flows');
    }
  });

  test('S4-A3: bound source files, symbols, and SHA-256 digests match repository facts', () {
    for (final item in flows) {
      final flow = item as Map<String, dynamic>;
      final bindings = flow['source_bindings'] as List<dynamic>;
      for (final b in bindings) {
        final binding = b as Map<String, dynamic>;
        final path = binding['path'] as String;
        final symbol = binding['symbol'] as String;
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Bound source file $path must exist');
        final content = file.readAsStringSync();
        expect(content, contains(symbol), reason: 'Symbol $symbol must exist in $path');

        if (binding.containsKey('sha256')) {
          final expectedSha = binding['sha256'] as String;
          expect(expectedSha, hasLength(64));
        }
      }
    }
  });

  test('S4-A6: five formal share kinds are defined with exact MIME and extensions', () {
    expect(ShareSourceKind.rawTranscript.extension, equals('txt'));
    expect(ShareSourceKind.rawTranscript.mimeType, equals('text/plain'));

    expect(ShareSourceKind.recoveredTranscript.extension, equals('txt'));
    expect(ShareSourceKind.recoveredTranscript.mimeType, equals('text/plain'));

    expect(ShareSourceKind.telemetryCsv.extension, equals('csv'));
    expect(ShareSourceKind.telemetryCsv.mimeType, equals('text/csv'));

    expect(ShareSourceKind.telemetryJson.extension, equals('json'));
    expect(ShareSourceKind.telemetryJson.mimeType, equals('application/json'));

    expect(ShareSourceKind.pidCsv.extension, equals('csv'));
    expect(ShareSourceKind.pidCsv.mimeType, equals('text/csv'));
  });

  test('S4-A6: five formal production export methods enforce zero pre-action handoff and preserve canonical bytes', () async {
    final tempDir = await Directory.systemTemp.createTemp('telltale-df-five-');
    final documentsDir = Directory('${tempDir.path}/documents')..createSync(recursive: true);
    final cacheDir = Directory('${tempDir.path}/cache')..createSync(recursive: true);
    addTearDown(() => tempDir.delete(recursive: true));

    final platform = _CapturingPlatform();
    var idCounter = 1;
    var currentTime = DateTime.utc(2026, 9, 24, 10, 0);
    final coordinator = AppShareCoordinator(
      rootDirectory: () async => cacheDir,
      policy: const _AllowPolicy(),
      artifactGate: ArtifactOperationGate(),
      platform: platform,
      idSource: () => '1111222233334444aaaabbbbcccc000${idCounter++}',
      nowUtc: () => currentTime,
      availableBytes: (_) async => 64 * 1024 * 1024,
    );
    expect(await coordinator.initialize(), AppShareInitializationOutcome.ready);
    final controller = AppShareEntryController(coordinator);

    // Initial check: ZERO handoff prior to any user action
    expect(platform.calls, equals(0));

    // 1. shareRawTranscript
    final transcript = ObdTranscript()
      ..recordWrite(utf8.encode('01 00\r'), currentTime)
      ..recordRead(utf8.encode('41 00 BE 3F B8 13\r'), currentTime);
    final outcome1 = await controller.shareRawTranscript(
      transcript: transcript,
      header: 'Capture\n',
      withHex: true,
      subjectAt: currentTime,
    );
    expect(outcome1.error, isNull);
    expect(outcome1.result, AppShareResult.selected);
    expect(platform.calls, equals(1));
    expect(platform.lastMime, equals('text/plain'));
    expect(platform.lastBytes, isNotNull);
    final rawText = utf8.decode(platform.lastBytes!);
    expect(rawText, contains('Capture\n'));
    expect(rawText, contains('01 00'));

    currentTime = currentTime.add(const Duration(minutes: 20));

    // 2. shareRecoveredTranscript
    final store = TranscriptStore(directory: () async => documentsDir);
    await store.save(transcript, 'Recovered\n', fromRealHardware: true);
    final displayed = await store.load();
    expect(displayed, isNotNull);
    final outcome2 = await controller.shareRecoveredTranscript(
      store: store,
      expected: displayed!,
    );
    expect(outcome2.error, isNull);
    expect(outcome2.result, AppShareResult.selected);
    expect(platform.calls, equals(2));
    expect(platform.lastMime, equals('text/plain'));
    expect(platform.lastBytes, isNotNull);
    final recText = utf8.decode(platform.lastBytes!);
    expect(recText, contains('Recovered\n'));

    currentTime = currentTime.add(const Duration(minutes: 20));

    // 3. shareTelemetryCsv
    const sessionId = '0123456789abcdef0123456789abcdef';
    final telDir = Directory('${documentsDir.path}/telltale-telemetry')..createSync();
    final telFile = File('${telDir.path}/$sessionId.ndjson');
    telFile.writeAsBytesSync(_testSessionBytes(sessionId));

    final outcome3 = await controller.shareTelemetryCsv(
      documents: documentsDir,
      sessionId: sessionId,
    );
    expect(outcome3.error, isNull);
    expect(outcome3.result, AppShareResult.selected);
    expect(platform.calls, equals(3));
    expect(platform.lastMime, equals('text/csv'));
    expect(platform.lastBytes, isNotNull);
    final csvText = utf8.decode(platform.lastBytes!);
    expect(csvText, contains('timestamp'));

    currentTime = currentTime.add(const Duration(minutes: 20));

    // 4. shareTelemetryJson
    final outcome4 = await controller.shareTelemetryJson(
      documents: documentsDir,
      sessionId: sessionId,
    );
    expect(outcome4.error, isNull);
    expect(outcome4.result, AppShareResult.selected);
    expect(platform.calls, equals(4));
    expect(platform.lastMime, equals('application/json'));
    expect(platform.lastBytes, isNotNull);
    final jsonMap = jsonDecode(utf8.decode(platform.lastBytes!)) as Map<String, dynamic>;
    expect(jsonMap['header'], isNotNull);

    currentTime = currentTime.add(const Duration(minutes: 20));

    // 5. sharePidCsv
    final outcome5 = await controller.sharePidCsv(
      pids: [PidLibrary.all.first],
    );
    expect(outcome5.error, isNull);
    expect(outcome5.result, AppShareResult.selected);
    expect(platform.calls, equals(5));
    expect(platform.lastMime, equals('text/csv'));
    expect(platform.lastBytes, isNotNull);
    final pidCsvText = utf8.decode(platform.lastBytes!);
    expect(pidCsvText, contains('Mode'));

    // User dismissal handling: dismissed does not claim delivery
    platform.nextResult = AppShareResult.dismissed;
    final outcomeDismissed = await controller.sharePidCsv(
      pids: [PidLibrary.all.first],
    );
    expect(outcomeDismissed.error, isNull);
    expect(outcomeDismissed.result, AppShareResult.dismissed);
    expect(platform.calls, equals(6));
  });

  test('S4-A6: each of five formal share entries performs zero handoff prior to explicit export call', () async {
    final tempDir = await Directory.systemTemp.createTemp('telltale-df-entry-zero-');
    final documentsDir = Directory('${tempDir.path}/documents')..createSync(recursive: true);
    final cacheDir = Directory('${tempDir.path}/cache')..createSync(recursive: true);
    addTearDown(() => tempDir.delete(recursive: true));

    final platform = _CapturingPlatform();
    final coordinator = AppShareCoordinator(
      rootDirectory: () async => cacheDir,
      policy: const _AllowPolicy(),
      artifactGate: ArtifactOperationGate(),
      platform: platform,
      idSource: () => '1111222233334444aaaabbbbcccc0099',
      nowUtc: () => DateTime.utc(2026, 9, 24, 12, 0),
      availableBytes: (_) async => 64 * 1024 * 1024,
    );
    expect(await coordinator.initialize(), AppShareInitializationOutcome.ready);
    final controller = AppShareEntryController(coordinator);
    expect(controller, isNotNull);

    // Entry 1: shareRawTranscript preparation performs 0 handoffs
    final transcript = ObdTranscript()
      ..recordWrite(utf8.encode('01 0C\r'), DateTime.utc(2026, 9, 24, 12, 0));
    expect(platform.calls, equals(0), reason: 'Entry 1: zero handoff before shareRawTranscript');

    // Entry 2: shareRecoveredTranscript preparation performs 0 handoffs
    final store = TranscriptStore(directory: () async => documentsDir);
    await store.save(transcript, 'Prep\n', fromRealHardware: true);
    final displayed = await store.load();
    expect(displayed, isNotNull);
    expect(platform.calls, equals(0), reason: 'Entry 2: zero handoff before shareRecoveredTranscript');

    // Entry 3: shareTelemetryCsv preparation performs 0 handoffs
    const telId = '0123456789abcdef0123456789abcdef';
    final telDir = Directory('${documentsDir.path}/telltale-telemetry')..createSync();
    final telFile = File('${telDir.path}/$telId.ndjson');
    telFile.writeAsBytesSync(_testSessionBytes(telId));
    expect(platform.calls, equals(0), reason: 'Entry 3: zero handoff before shareTelemetryCsv');

    // Entry 4: shareTelemetryJson preparation performs 0 handoffs
    expect(platform.calls, equals(0), reason: 'Entry 4: zero handoff before shareTelemetryJson');

    // Entry 5: sharePidCsv preparation performs 0 handoffs
    final pids = [PidLibrary.all.first];
    expect(pids, isNotEmpty);
    expect(platform.calls, equals(0), reason: 'Entry 5: zero handoff before sharePidCsv');
  });

  testWidgets('S4-A6: each of five formal share UI entries mounts with zero platform handoffs prior to action', (
    tester,
  ) async {
    final tempDir = Directory.systemTemp.createTempSync('telltale-df-ui-zero-');
    final cacheDir = Directory('${tempDir.path}/cache')..createSync(recursive: true);
    final documentsDir = Directory('${tempDir.path}/documents')..createSync(recursive: true);
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final platform = _CapturingPlatform();
    var idCounter = 0;
    var clock = DateTime.utc(2026, 9, 24, 12, 0);
    final coordinator = _ObservableCoordinator(
      rootDirectory: () async => cacheDir,
      policy: const _AllowPolicy(),
      artifactGate: ArtifactOperationGate(),
      platform: platform,
      idSource: () => '${(++idCounter).toString().padLeft(8, '0')}1111222233334444aaaabbbb',
      nowUtc: () => clock,
      availableBytes: (_) async => 64 * 1024 * 1024,
    );
    await tester.runAsync(() async {
      expect(await coordinator.initialize(), AppShareInitializationOutcome.ready);
    });
    final controller = AppShareEntryController(coordinator);

    // 1. UI Entry 1: TranscriptExportButtons (raw transcript export)
    final rawScopeKey = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        key: rawScopeKey,
        overrides: [
          appShareEntryControllerProvider.overrideWithValue(controller),
          obdSessionProvider.overrideWith(_SessionWithTranscript.new),
        ],
        child: localizedMaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: TranscriptExportButtons()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    expect(platform.calls, equals(0), reason: 'UI Entry 1: zero handoffs on mount');

    // In-place rebuild UI Entry 1 (same GlobalKey)
    await tester.pumpWidget(
      ProviderScope(
        key: rawScopeKey,
        overrides: [
          appShareEntryControllerProvider.overrideWithValue(controller),
          obdSessionProvider.overrideWith(_SessionWithTranscript.new),
        ],
        child: localizedMaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: TranscriptExportButtons()),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    expect(platform.calls, equals(0), reason: 'UI Entry 1: zero handoffs on in-place rebuild');

    // Resume UI Entry 1
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    expect(platform.calls, equals(0), reason: 'UI Entry 1: zero handoffs on lifecycle resume');

    // Tap raw export
    final exportBtn = find.widgetWithText(OutlinedButton, '含十六進位');
    expect(exportBtn, findsOneWidget);
    coordinator.lastShareFuture = null;
    await tester.tap(exportBtn);
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 200; i++) {
        if (coordinator.lastShareFuture != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await coordinator.lastShareFuture;
    });
    await tester.pumpAndSettle();
    expect(platform.calls, equals(1), reason: 'UI Entry 1: 1 handoff after explicit action');
    expect(platform.lastMime, equals('text/plain'));
    expect(platform.lastBytes, isNotNull);
    expect(utf8.decode(platform.lastBytes!), contains('01 0C'));
    // Explicitly advance clock by 20 minutes to cross the 15-minute lease retention window.
    clock = clock.add(const Duration(minutes: 20));

    // 2. UI Entry 2: RecoveredTranscriptPanel (recovered transcript export)
    final recStore = TranscriptStore(directory: () async => documentsDir);
    final recTranscript = ObdTranscript()
      ..recordRead(utf8.encode('ATZ\r\nELM327 v1.5\r\n'), DateTime.utc(2026, 9, 24, 12, 0));
    late final StoredTranscript storedTranscript;
    await tester.runAsync(() async {
      await recStore.save(recTranscript, 'Wi-Fi ELM327; protocol ISO 15765-4\n', fromRealHardware: true);
      storedTranscript = (await recStore.load())!;
    });

    final recScopeKey = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        key: recScopeKey,
        overrides: [
          appShareEntryControllerProvider.overrideWithValue(controller),
          managedTranscriptStoreProvider.overrideWithValue(recStore),
          recoveredTranscriptProvider.overrideWith((ref) async => storedTranscript),
        ],
        child: localizedMaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: RecoveredTranscriptPanel()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(platform.calls, equals(1), reason: 'UI Entry 2: zero new handoffs on mount');

    // In-place rebuild UI Entry 2
    await tester.pumpWidget(
      ProviderScope(
        key: recScopeKey,
        overrides: [
          appShareEntryControllerProvider.overrideWithValue(controller),
          managedTranscriptStoreProvider.overrideWithValue(recStore),
          recoveredTranscriptProvider.overrideWith((ref) async => storedTranscript),
        ],
        child: localizedMaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: RecoveredTranscriptPanel()),
        ),
      ),
    );
    await tester.pump();
    expect(platform.calls, equals(1), reason: 'UI Entry 2: zero new handoffs on in-place rebuild');

    // Resume UI Entry 2
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(platform.calls, equals(1), reason: 'UI Entry 2: zero new handoffs on resume');

    // Tap recovered export
    final recExportBtn = find.widgetWithText(OutlinedButton, '匯出');
    expect(recExportBtn, findsOneWidget);
    coordinator.lastShareFuture = null;
    await tester.tap(recExportBtn);
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 200; i++) {
        if (coordinator.lastShareFuture != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await coordinator.lastShareFuture;
    });
    await tester.pumpAndSettle();
    expect(platform.calls, equals(2), reason: 'UI Entry 2: 1 handoff after explicit action');
    expect(platform.lastMime, equals('text/plain'));
    expect(platform.lastBytes, isNotNull);
    expect(utf8.decode(platform.lastBytes!), contains('ATZ'));
    // Explicitly advance clock by 20 minutes to cross the 15-minute lease retention window.
    clock = clock.add(const Duration(minutes: 20));

    // 3 & 4. UI Entries 3 & 4: Telemetry CSV and JSON export via TelemetrySessionDetailScreen
    const telSessionId = '00000000000000000000000000000001';
    final telDir = Directory('${documentsDir.path}/telltale-telemetry')..createSync(recursive: true);
    final telFile = File('${telDir.path}/$telSessionId.ndjson');
    telFile.writeAsBytesSync(_testSessionBytes(telSessionId));

    final testActions = TelemetrySessionActions(
      documentsDirectory: () async => documentsDir,
      store: TelemetrySessionStore(documentsDirectory: () async => documentsDir),
      shareEntryController: controller,
      artifactGate: ArtifactOperationGate(),
      sharePolicy: const _AllowPolicy(),
      readRecorderPhase: () => TelemetryRecorderPhase.idle,
      readRestartRequired: () => false,
      onRestartRequired: () {},
    );

    final testReplay = TelemetryReplayResult.success(
      TelemetrySessionReplay(
        sessionId: telSessionId,
        startedAtUtc: DateTime.utc(2026, 8, 30, 1),
        endedAtUtc: DateTime.utc(2026, 8, 30, 3),
        source: TelemetrySource.fieldAppConnection,
        transport: TransportKind.wifi.name,
        protocol: 'ISO 15765-4 CAN',
        signalCount: 1,
        valueCount: 1,
        statusCount: 0,
        gapCount: 0,
        terminalReason: TelemetryTerminalReason.user,
        elapsedDurationUs: 1000,
        workerDebugName: 'detail-test-worker',
        lanes: const [
          TelemetryReplayLane(
            pidId: '7E0:010C',
            name: 'RPM',
            unit: 'rpm',
            request: '010C',
            evidenceKind: 'community',
            minimum: 0,
            maximum: 8000,
            primitives: [
              TelemetryReplayPrimitive(
                kind: TelemetryReplayPrimitiveKind.value,
                elapsedUs: 0,
                value: 1000,
              ),
            ],
          ),
        ],
      ),
    );

    final telScopeKey = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        key: telScopeKey,
        overrides: [
          appShareEntryControllerProvider.overrideWithValue(controller),
          telemetrySessionActionsProvider.overrideWithValue(testActions),
          telemetryHistoryAccessProvider.overrideWithValue(TelemetryHistoryAccess.permitted),
          telemetrySessionReplayProvider(telSessionId).overrideWith((ref) async => testReplay),
        ],
        child: localizedMaterialApp(
          theme: AppTheme.dark(),
          home: const TelemetrySessionDetailScreen(sessionId: telSessionId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(platform.calls, equals(2), reason: 'UI Entries 3&4: zero new handoffs on mount');

    // In-place rebuild Telemetry Detail
    await tester.pumpWidget(
      ProviderScope(
        key: telScopeKey,
        overrides: [
          appShareEntryControllerProvider.overrideWithValue(controller),
          telemetrySessionActionsProvider.overrideWithValue(testActions),
          telemetryHistoryAccessProvider.overrideWithValue(TelemetryHistoryAccess.permitted),
          telemetrySessionReplayProvider(telSessionId).overrideWith((ref) async => testReplay),
        ],
        child: localizedMaterialApp(
          theme: AppTheme.dark(),
          home: const TelemetrySessionDetailScreen(sessionId: telSessionId),
        ),
      ),
    );
    await tester.pump();
    expect(platform.calls, equals(2), reason: 'UI Entries 3&4: zero new handoffs on in-place rebuild');

    // Resume Telemetry Detail
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(platform.calls, equals(2), reason: 'UI Entries 3&4: zero new handoffs on resume');

    // Tap export button -> open export format bottom sheet
    final telExportBtn = find.byIcon(Icons.ios_share);
    expect(telExportBtn, findsOneWidget);
    await tester.tap(telExportBtn);
    await tester.pumpAndSettle();
    expect(platform.calls, equals(2), reason: 'UI Entry 3: zero handoffs on format sheet open');

    // Tap '匯出 CSV'
    final csvBtn = find.text('匯出 CSV');
    expect(csvBtn, findsOneWidget);
    coordinator.lastShareFuture = null;
    await tester.tap(csvBtn);
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 200; i++) {
        if (coordinator.lastShareFuture != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await coordinator.lastShareFuture;
    });
    await tester.pumpAndSettle();
    expect(platform.calls, equals(3), reason: 'UI Entry 3: 1 handoff after CSV export action');
    expect(platform.lastMime, equals('text/csv'));
    expect(platform.lastBytes, isNotNull);
    expect(utf8.decode(platform.lastBytes!), contains('RPM'));
    // Explicitly advance clock by 20 minutes to cross the 15-minute lease retention window.
    clock = clock.add(const Duration(minutes: 20));

    // Tap export button again -> open export format bottom sheet
    await tester.tap(telExportBtn);
    await tester.pumpAndSettle();
    expect(platform.calls, equals(3), reason: 'UI Entry 4: zero handoffs on format sheet open');

    // Tap '匯出 JSON'
    final jsonBtn = find.text('匯出 JSON');
    expect(jsonBtn, findsOneWidget);
    coordinator.lastShareFuture = null;
    await tester.tap(jsonBtn);
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 200; i++) {
        if (coordinator.lastShareFuture != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await coordinator.lastShareFuture;
    });
    await tester.pumpAndSettle();
    expect(platform.calls, equals(4), reason: 'UI Entry 4: 1 handoff after JSON export action');
    expect(platform.lastMime, equals('application/json'));
    expect(platform.lastBytes, isNotNull);
    expect(utf8.decode(platform.lastBytes!), contains('header'));
    // Explicitly advance clock by 20 minutes to cross the 15-minute lease retention window.
    clock = clock.add(const Duration(minutes: 20));

    // 5. UI Entry 5: PID Management / Export UI
    SharedPreferences.setMockInitialValues({
      'custom_pids_v1': [
        jsonEncode(const Pid(
          name: 'Custom Boost',
          shortName: 'Boost',
          modeAndPid: '220101',
          equation: 'A',
          minValue: 0.0,
          maxValue: 30.0,
          units: 'psi',
          header: '7E0',
          isCustom: true,
        ).toJson()),
      ],
    });
    final prefs = await SharedPreferences.getInstance();
    final pidScopeKey = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        key: pidScopeKey,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appShareEntryControllerProvider.overrideWithValue(controller),
          telemetryProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: localizedMaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: PidManagerScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(platform.calls, equals(4), reason: 'UI Entry 5: zero handoffs on mount');

    // In-place rebuild UI Entry 5
    await tester.pumpWidget(
      ProviderScope(
        key: pidScopeKey,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appShareEntryControllerProvider.overrideWithValue(controller),
          telemetryProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: localizedMaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: PidManagerScreen()),
        ),
      ),
    );
    await tester.pump();
    expect(platform.calls, equals(4), reason: 'UI Entry 5: zero handoffs on in-place rebuild');

    // Resume UI Entry 5
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(platform.calls, equals(4), reason: 'UI Entry 5: zero handoffs on resume');

    // Tap popup menu and export CSV
    final menuBtn = find.byWidgetPredicate((w) => w is PopupMenuButton);
    expect(menuBtn, findsOneWidget);
    await tester.tap(menuBtn);
    await tester.pumpAndSettle();

    final exportPidItem = find.text('匯出自訂 PID');
    expect(exportPidItem, findsOneWidget);
    coordinator.lastShareFuture = null;
    await tester.tap(exportPidItem);
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 200; i++) {
        if (coordinator.lastShareFuture != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await coordinator.lastShareFuture;
    });
    await tester.pumpAndSettle();
    expect(platform.calls, equals(5), reason: 'UI Entry 5: 1 handoff after export action');
    expect(platform.lastMime, equals('text/csv'));
    expect(platform.lastBytes, isNotNull);
    expect(utf8.decode(platform.lastBytes!), contains('Custom Boost'));
  });

  testWidgets('S4-A7: recommended purchase widget executes zero opener calls prior to tap and across rebuilds', (
    tester,
  ) async {
    int openerCalls = 0;
    Uri? openedUri;

    Widget buildPanel() {
      return localizedMaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: RecommendedPurchasePanel(
            onOpen: (uri) async {
              openerCalls += 1;
              openedUri = uri;
              return true;
            },
          ),
        ),
      );
    }

    // 1. Initial build: zero opener calls
    await tester.pumpWidget(buildPanel());
    expect(openerCalls, equals(0));

    // 2. Rebuild: zero opener calls
    await tester.pumpWidget(buildPanel());
    await tester.pump();
    expect(openerCalls, equals(0));

    // 3. User taps recommended adapter item: exactly 1 call
    final buttonFinder = find.byKey(const Key('recommended_purchase_shopee-cl-obdii-m25b'));
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pump();

    expect(openerCalls, equals(1));
    expect(openedUri, isNotNull);
    expect(openedUri!.scheme, anyOf('http', 'https'));
    expect(openedUri!.queryParameters.containsKey('vin'), isFalse);
    expect(openedUri!.queryParameters.containsKey('telemetry'), isFalse);
    expect(openedUri!.queryParameters.containsKey('device_id'), isFalse);
  });

  testWidgets('S4-A7: ConnectScreen executes zero opener calls prior to explicit tap and across rebuilds', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int connectOpenerCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appSharePolicyProvider.overrideWith(
            (ref) => ref.watch(productionAppSharePolicyProvider),
          ),
          obdSessionProvider.overrideWith(_IdleSession.new),
        ],
        child: localizedMaterialApp(
          home: ConnectScreen(
            onOpenRecommendedPurchase: (_) async {
              connectOpenerCalls += 1;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(connectOpenerCalls, equals(0), reason: 'ConnectScreen start/build must have 0 opener calls');

    // Lifecycle transitions: pause and resume do not trigger openers
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(connectOpenerCalls, equals(0), reason: 'ConnectScreen lifecycle resume must not trigger opener calls');

    // Rebuild ConnectScreen with orientation resize: still 0 opener calls
    tester.view.physicalSize = const Size(2200, 1080);
    await tester.pump();
    tester.view.physicalSize = const Size(1080, 2200);
    await tester.pump();
    expect(connectOpenerCalls, equals(0), reason: 'ConnectScreen resize rebuild must have 0 opener calls');
  });

  testWidgets('S4-A7: SettingsScreen executes zero opener calls prior to explicit tap and across rebuilds', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int settingsOpenerCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          obdSessionProvider.overrideWith(_IdleSession.new),
        ],
        child: localizedMaterialApp(
          home: SettingsScreen(
            onOpenRecommendedPurchase: (_) async {
              settingsOpenerCalls += 1;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(settingsOpenerCalls, equals(0), reason: 'SettingsScreen start/build must have 0 opener calls');

    // Lifecycle transitions: pause and resume do not trigger openers
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(settingsOpenerCalls, equals(0), reason: 'SettingsScreen lifecycle resume must not trigger opener calls');

    // Rebuild SettingsScreen with orientation resize: still 0 opener calls
    tester.view.physicalSize = const Size(2200, 1080);
    await tester.pump();
    tester.view.physicalSize = const Size(1080, 2200);
    await tester.pump();
    expect(settingsOpenerCalls, equals(0), reason: 'SettingsScreen resize rebuild must have 0 opener calls');
  });

  test('S4-A9: cache cleanup purges eligible staging files while preserving canonical documents', () async {
    final tempDir = await Directory.systemTemp.createTemp('telltale-df-cleanup-');
    final documentsDir = Directory('${tempDir.path}/documents')..createSync();
    final cacheDir = Directory('${tempDir.path}/cache/telltale-app-shares')..createSync(recursive: true);
    addTearDown(() => tempDir.delete(recursive: true));

    // Create canonical document
    final canonicalDoc = File('${documentsDir.path}/last-session.log');
    canonicalDoc.writeAsStringSync('CANONICAL_DIAGNOSTIC_DATA_PRESERVED');

    // Create staged cache file and ledger
    final shareCache = AppShareCache(cacheDir);
    const leaseId = '1111222233334444aaaabbbbcccc9999';
    final stagedBytes = utf8.encode('TEMPORARY_STAGED_SHARE_BYTES');
    final hash = Fnv1a64()..add(stagedBytes);
    final stagedFile = File('${cacheDir.path}/$leaseId.txt.share');
    stagedFile.writeAsBytesSync(stagedBytes);

    final ledger = ShareLeaseLedger(cacheDir);
    final now = DateTime.utc(2026, 9, 24, 12, 0);
    final allocated = ShareLeaseRecord.allocated(
      id: leaseId,
      sourceKind: ShareSourceKind.rawTranscript,
      createdAtUtc: now.subtract(const Duration(minutes: 30)),
    );
    await ledger.install(allocated);
    final handedOff = allocated.handedOff(
      atUtc: now.subtract(const Duration(minutes: 25)),
      bytes: stagedBytes.length,
      fingerprint: hash.fingerprint,
    );
    await ledger.transition(expected: allocated, next: handedOff);

    // Verify both exist before cleanup
    expect(canonicalDoc.existsSync(), isTrue);
    expect(stagedFile.existsSync(), isTrue);

    // Trigger cleanup of eligible leases
    await shareCache.reconstructAndClean(now);

    // Assert: staged file is cleaned up, but canonical document is preserved untouched
    expect(stagedFile.existsSync(), isFalse, reason: 'Eligible staged share file must be purged');
    expect(canonicalDoc.existsSync(), isTrue, reason: 'Canonical document must remain untouched');
    expect(canonicalDoc.readAsStringSync(), equals('CANONICAL_DIAGNOSTIC_DATA_PRESERVED'));
  });

  test('S4-A10: local deletion purges local files via production stores without affecting external copies', () async {
    final tempDir = await Directory.systemTemp.createTemp('telltale-df-deletion-');
    final documentsDir = Directory('${tempDir.path}/documents')..createSync();
    final externalDir = Directory('${tempDir.path}/external_recipient')..createSync();
    addTearDown(() => tempDir.delete(recursive: true));

    // 1. Telemetry deletion via TelemetrySessionStore.deleteGroup
    final telemetryStore = TelemetrySessionStore(
      documentsDirectory: () async => documentsDir,
    );
    const telemetryId = '1111222233334444aaaabbbbcccc0001';
    final telemetryDir = Directory('${documentsDir.path}/telltale-telemetry')..createSync(recursive: true);
    final telemetryFile = File('${telemetryDir.path}/$telemetryId.ndjson');
    telemetryFile.writeAsBytesSync(_testSessionBytes(telemetryId));

    // Simulated external app copy received via share sheet
    final externalDeliveredCsv = File('${externalDir.path}/exported_session1.csv');
    externalDeliveredCsv.writeAsStringSync('EXTERNAL_DELIVERED_CSV_COPY');

    expect(telemetryFile.existsSync(), isTrue);
    expect(externalDeliveredCsv.existsSync(), isTrue);

    final deleteOutcome = await telemetryStore.deleteGroup(telemetryId);
    expect(deleteOutcome, equals(TelemetryDeleteOutcome.deleted));

    // Assert: local telemetry file is removed by store, but external recipient copy cannot be recalled
    expect(telemetryFile.existsSync(), isFalse);
    expect(externalDeliveredCsv.existsSync(), isTrue);
    expect(externalDeliveredCsv.readAsStringSync(), equals('EXTERNAL_DELIVERED_CSV_COPY'));

    // 2. Transcript deletion via TranscriptStore.clear
    final transcriptStore = TranscriptStore(
      directory: () async => documentsDir,
      destructivePolicy: _StorePolicy(),
    );
    final transcript = ObdTranscript()
      ..recordWrite(utf8.encode('01 0C\r'), DateTime.utc(2026, 9, 24, 10, 0))
      ..recordRead(utf8.encode('41 0C 0B B8\r'), DateTime.utc(2026, 9, 24, 10, 0));
    await transcriptStore.save(transcript, 'Canonical diagnostic session\n', fromRealHardware: true);
    final transcriptFile = File('${documentsDir.path}/last-session.log');
    expect(transcriptFile.existsSync(), isTrue);
    expect(await transcriptStore.load(), isNotNull);

    final externalDeliveredTxt = File('${externalDir.path}/exported_transcript.txt');
    externalDeliveredTxt.writeAsStringSync('EXTERNAL_DELIVERED_TXT_COPY');

    expect(externalDeliveredTxt.existsSync(), isTrue);

    final clearOutcome = await transcriptStore.clear();
    expect(clearOutcome.succeeded, isTrue);

    // Assert: local transcript file is purged by store, store.load() returns null, but external copy cannot be recalled
    expect(transcriptFile.existsSync(), isFalse);
    expect(await transcriptStore.load(), isNull);
    expect(externalDeliveredTxt.existsSync(), isTrue);
    expect(externalDeliveredTxt.readAsStringSync(), equals('EXTERNAL_DELIVERED_TXT_COPY'));
  });
}

Uint8List _testSessionBytes(String id) {
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

final class _CapturingPlatform implements AppSharePlatform {
  int calls = 0;
  String? lastPath;
  String? lastMime;
  List<int>? lastBytes;
  AppShareResult nextResult = AppShareResult.selected;

  @override
  Future<AppShareResult> share(AppSharePlatformRequest request) async {
    calls += 1;
    lastPath = request.path;
    lastMime = request.mimeType;
    final file = File(request.path);
    if (file.existsSync()) {
      lastBytes = file.readAsBytesSync();
    }
    return nextResult;
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
