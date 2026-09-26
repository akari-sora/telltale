import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';
import 'package:torque_obd/state/telemetry_sessions.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_session.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_store.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_session_detail_screen.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_sessions_screen.dart';

import '../support/localized_app.dart';

Future<void> _waitForSettlement(
  WidgetTester tester,
  bool Function() condition,
) async {
  final stop = Stopwatch()..start();
  while (!condition()) {
    if (stop.elapsed > const Duration(seconds: 5)) {
      fail('Timed out waiting for condition to settle');
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

void main() {
  const testSessionId = '00000000000000000000000000000001';
  const testSessionId2 = '00000000000000000000000000000002';
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('b2a_test_');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  TelemetryReplayResult makeReplay(String id) => TelemetryReplayResult.success(
        TelemetrySessionReplay(
          sessionId: id,
          startedAtUtc: DateTime.utc(2026, 8, 30, 1),
          endedAtUtc: DateTime.utc(2026, 8, 30, 3),
          source: TelemetrySource.demo,
          transport: TransportKind.demo.name,
          protocol: 'ISO 15765-4 CAN',
          signalCount: 1,
          valueCount: 1,
          statusCount: 0,
          gapCount: 0,
          terminalReason: TelemetryTerminalReason.user,
          elapsedDurationUs: 1000,
          workerDebugName: 'b2a-worker',
          lanes: const [
            TelemetryReplayLane(
              pidId: '7E0:010C',
              name: 'RPM',
              unit: 'rpm',
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

  final testReplay = makeReplay(testSessionId);
  final testReplay2 = makeReplay(testSessionId2);

  group('Batch 1L-B2a: UI Feedback render-time locale resolution & target identity', () {
    testWidgets('detail export failure dynamically relocalizes active on-screen snackbar across locale transitions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final actions = TelemetrySessionActions(
        documentsDirectory: () async => tempDir,
        store: TelemetrySessionStore(documentsDirectory: () async => tempDir),
        artifactGate: ArtifactOperationGate(),
        sharePolicy: const _AllowPolicy(),
        readRecorderPhase: () => TelemetryRecorderPhase.idle,
        readRestartRequired: () => false,
      );

      final harnessKey = GlobalKey<_TestLocaleHarnessState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryHistoryAccessProvider.overrideWithValue(
              TelemetryHistoryAccess.permitted,
            ),
            telemetrySessionReplayProvider.overrideWith(
              (ref, id) async => testReplay,
            ),
            telemetrySessionActionsProvider.overrideWithValue(actions),
          ],
          child: _TestLocaleHarness(
            key: harnessKey,
            child: const TelemetrySessionDetailScreen(sessionId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final exportBtn = find.widgetWithText(FilledButton, 'Export');
      expect(exportBtn, findsOneWidget);
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      expect(find.text('Export CSV'), findsOneWidget);
      await tester.tap(find.text('Export CSV'));
      await tester.pumpAndSettle();

      expect(find.text('Export did not finish: Could not prepare or open sharing.'), findsOneWidget);
      expect(find.textContaining('匯出未完成'), findsNothing);

      harnessKey.currentState!.changeLocale(testUiLocale);
      await tester.pump();

      expect(find.text('匯出未完成：無法準備或開啟分享'), findsOneWidget);
      expect(find.textContaining('Export did not finish'), findsNothing);

      harnessKey.currentState!.changeLocale(const Locale('en'));
      await tester.pump();

      expect(find.text('Export did not finish: Could not prepare or open sharing.'), findsOneWidget);
      expect(find.textContaining('匯出未完成'), findsNothing);
    });

    testWidgets('detail delete failure dynamically relocalizes active on-screen snackbar across locale transitions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final actions = TelemetrySessionActions(
        documentsDirectory: () async => tempDir,
        store: TelemetrySessionStore(documentsDirectory: () async => tempDir),
        artifactGate: ArtifactOperationGate(),
        sharePolicy: const _DenyPolicy(),
        readRecorderPhase: () => TelemetryRecorderPhase.idle,
        readRestartRequired: () => false,
      );

      final harnessKey = GlobalKey<_TestLocaleHarnessState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryHistoryAccessProvider.overrideWithValue(
              TelemetryHistoryAccess.permitted,
            ),
            telemetrySessionReplayProvider.overrideWith(
              (ref, id) async => testReplay,
            ),
            telemetrySessionActionsProvider.overrideWithValue(actions),
          ],
          child: _TestLocaleHarness(
            key: harnessKey,
            child: const TelemetrySessionDetailScreen(sessionId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteBtn = find.widgetWithText(OutlinedButton, 'Delete');
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Delete this local recording?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete did not finish: Driving or connection state changed during this operation.'), findsOneWidget);

      harnessKey.currentState!.changeLocale(testUiLocale);
      await tester.pump();

      expect(find.text('刪除未完成：操作期間行車或連線狀態已改變'), findsOneWidget);
      expect(find.textContaining('Delete did not finish'), findsNothing);

      harnessKey.currentState!.changeLocale(const Locale('en'));
      await tester.pump();

      expect(find.text('Delete did not finish: Driving or connection state changed during this operation.'), findsOneWidget);
    });

    testWidgets('damaged artifact delete failure dynamically relocalizes active on-screen snackbar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final actions = TelemetrySessionActions(
        documentsDirectory: () async => tempDir,
        store: TelemetrySessionStore(documentsDirectory: () async => tempDir),
        artifactGate: ArtifactOperationGate(),
        sharePolicy: const _DenyPolicy(),
        readRecorderPhase: () => TelemetryRecorderPhase.idle,
        readRestartRequired: () => false,
      );

      final harnessKey = GlobalKey<_TestLocaleHarnessState>();
      const damagedId = '0000000000000000000000000000000d';
      final damaged = DamagedTelemetryProjection(
        id: damagedId,
        filesystemModifiedAtUtc: DateTime.utc(2026, 8, 30, 2),
        kind: DamagedTelemetryKind.corrupt,
      );

      final library = TelemetrySessionLibrary(
        sessions: const [],
        damaged: [damaged],
        groupCount: 1,
        recognizedBytes: 500,
        omittedCount: 0,
        encodedProjectionBytes: 500,
        workerDebugName: 'damaged-test-worker',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryHistoryAccessProvider.overrideWithValue(
              TelemetryHistoryAccess.permitted,
            ),
            telemetrySessionLibraryProvider.overrideWith(
              (ref) async => library,
            ),
            telemetrySessionActionsProvider.overrideWithValue(actions),
          ],
          child: _TestLocaleHarness(
            key: harnessKey,
            child: const TelemetrySessionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete this damaged recording?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete did not finish: Driving or connection state changed during this operation.'), findsOneWidget);

      harnessKey.currentState!.changeLocale(testUiLocale);
      await tester.pump();

      expect(find.text('刪除未完成：操作期間行車或連線狀態已改變'), findsOneWidget);
      expect(find.textContaining('Delete did not finish'), findsNothing);
    });

    testWidgets('detail delete success on current route pops screen, but suppresses pop if covered by new route', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sessionDir = Directory('${tempDir.path}/telltale-telemetry')..createSync(recursive: true);
      final sessionFile = File('${sessionDir.path}/$testSessionId.ndjson');
      sessionFile.writeAsStringSync('{"kind":"header"}\n');

      final currentBarrier = _TestBarrier();
      Future<Directory> currentDir() async {
        if (!currentBarrier.entered.isCompleted) {
          currentBarrier.entered.complete();
        }
        await currentBarrier.release.future;
        return tempDir;
      }

      final currentActions = TelemetrySessionActions(
        documentsDirectory: currentDir,
        store: TelemetrySessionStore(documentsDirectory: currentDir),
        artifactGate: ArtifactOperationGate(),
        sharePolicy: const _AllowPolicy(),
        readRecorderPhase: () => TelemetryRecorderPhase.idle,
        readRestartRequired: () => false,
      );

      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryHistoryAccessProvider.overrideWithValue(
              TelemetryHistoryAccess.permitted,
            ),
            telemetrySessionReplayProvider.overrideWith(
              (ref, id) async => testReplay,
            ),
            telemetrySessionActionsProvider.overrideWithValue(currentActions),
          ],
          child: MaterialApp(
            navigatorKey: navKey,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: Text('Library Root')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      navKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const TelemetrySessionDetailScreen(sessionId: testSessionId),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TelemetrySessionDetailScreen), findsOneWidget);

      // Tap Delete -> confirm
      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Wait for delete action to enter
      await currentBarrier.entered.future.timeout(const Duration(seconds: 5));
      // Release barrier
      currentBarrier.release.complete();
      await _waitForSettlement(
        tester,
        () => !sessionFile.existsSync() &&
            find.byType(TelemetrySessionDetailScreen).evaluate().isEmpty,
      );

      // Terminal assertion: file deleted and detail screen popped
      expect(sessionFile.existsSync(), isFalse);
      expect(find.byType(TelemetrySessionDetailScreen), findsNothing);
      expect(find.text('Library Root'), findsOneWidget);

      // Case 2: route guard prevents popping a covering route if pushed during in-flight delete
      sessionFile.writeAsStringSync('{"kind":"header"}\n');
      final coveredBarrier = _TestBarrier();
      Future<Directory> coveredDir() async {
        if (!coveredBarrier.entered.isCompleted) {
          coveredBarrier.entered.complete();
        }
        await coveredBarrier.release.future;
        return tempDir;
      }

      final coveredActions = TelemetrySessionActions(
        documentsDirectory: coveredDir,
        store: TelemetrySessionStore(documentsDirectory: coveredDir),
        artifactGate: ArtifactOperationGate(),
        sharePolicy: const _AllowPolicy(),
        readRecorderPhase: () => TelemetryRecorderPhase.idle,
        readRestartRequired: () => false,
      );

      final navKey2 = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryHistoryAccessProvider.overrideWithValue(
              TelemetryHistoryAccess.permitted,
            ),
            telemetrySessionReplayProvider.overrideWith(
              (ref, id) async => testReplay,
            ),
            telemetrySessionActionsProvider.overrideWithValue(coveredActions),
          ],
          child: MaterialApp(
            navigatorKey: navKey2,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: Text('Library Root')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      navKey2.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const TelemetrySessionDetailScreen(sessionId: testSessionId),
        ),
      );
      await tester.pumpAndSettle();

      // Start delete
      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Wait for delete action to enter
      await coveredBarrier.entered.future.timeout(const Duration(seconds: 5));

      // Push a covering route while delete is in-flight behind barrier
      navKey2.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Covering Route Screen')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Covering Route Screen'), findsOneWidget);

      // Release the delete barrier to complete successfully
      coveredBarrier.release.complete();
      await _waitForSettlement(tester, () => !sessionFile.existsSync());

      // Terminal assertion: file is deleted, but covering route was NOT erroneously popped
      expect(sessionFile.existsSync(), isFalse);
      expect(find.text('Covering Route Screen'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      // Pop the covering screen manually to return
      navKey2.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Covering Route Screen'), findsNothing);
    });

    testWidgets('detail export and delete failure suppress snackbar if route is no longer current', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Part A: Export failure suppression under covered route
      final exportBarrier = _TestBarrier();
      Future<Directory> exportDir() async {
        if (!exportBarrier.entered.isCompleted) {
          exportBarrier.entered.complete();
        }
        await exportBarrier.release.future;
        return tempDir;
      }

      final exportActions = TelemetrySessionActions(
        documentsDirectory: exportDir,
        store: TelemetrySessionStore(documentsDirectory: exportDir),
        artifactGate: ArtifactOperationGate(),
        sharePolicy: const _DenyPolicy(),
        readRecorderPhase: () => TelemetryRecorderPhase.idle,
        readRestartRequired: () => false,
      );

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryHistoryAccessProvider.overrideWithValue(
              TelemetryHistoryAccess.permitted,
            ),
            telemetrySessionReplayProvider.overrideWith(
              (ref, id) async => testReplay,
            ),
            telemetrySessionActionsProvider.overrideWithValue(exportActions),
          ],
          child: MaterialApp(
            navigatorKey: navKey,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: Text('Root')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      navKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const TelemetrySessionDetailScreen(sessionId: testSessionId),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Export -> CSV
      await tester.tap(find.widgetWithText(FilledButton, 'Export'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export CSV'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Wait for export action to enter
      await exportBarrier.entered.future.timeout(const Duration(seconds: 5));

      // Push covering route while export is in flight
      navKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Covering Route Screen')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Covering Route Screen'), findsOneWidget);

      // Release export barrier
      exportBarrier.release.complete();
      await _waitForSettlement(tester, () => true);

      // Terminal assertion: No SnackBar displayed on covering route
      expect(find.byType(SnackBar), findsNothing);

      // Pop covering route
      navKey.currentState!.pop();
      await tester.pumpAndSettle();

      // Part B: Delete failure suppression under covered route
      final deleteBarrier = _TestBarrier();
      Future<Directory> deleteDir() async {
        if (!deleteBarrier.entered.isCompleted) {
          deleteBarrier.entered.complete();
        }
        await deleteBarrier.release.future;
        return tempDir;
      }

      final deleteActions = TelemetrySessionActions(
        documentsDirectory: deleteDir,
        store: TelemetrySessionStore(documentsDirectory: deleteDir),
        artifactGate: ArtifactOperationGate(),
        sharePolicy: const _AllowPolicy(),
        readRecorderPhase: () => TelemetryRecorderPhase.idle,
        readRestartRequired: () => false,
      );

      final navKeyDelete = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryHistoryAccessProvider.overrideWithValue(
              TelemetryHistoryAccess.permitted,
            ),
            telemetrySessionReplayProvider.overrideWith(
              (ref, id) async => testReplay,
            ),
            telemetrySessionActionsProvider.overrideWithValue(deleteActions),
          ],
          child: MaterialApp(
            navigatorKey: navKeyDelete,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: Text('Root')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      navKeyDelete.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const TelemetrySessionDetailScreen(sessionId: testSessionId),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Delete -> confirm
      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Wait for delete action to enter
      await deleteBarrier.entered.future.timeout(const Duration(seconds: 5));

      // Push covering route
      navKeyDelete.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Covering Route Screen 2')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Covering Route Screen 2'), findsOneWidget);

      // Release delete barrier (fails with notFound because file does not exist)
      deleteBarrier.release.complete();
      await _waitForSettlement(tester, () => true);

      // Terminal assertion: No SnackBar displayed on covering route
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('damaged artifact delete suppresses snackbar if route is no longer current', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final deleteBarrier = _TestBarrier();
      Future<Directory> deleteDir() async {
        if (!deleteBarrier.entered.isCompleted) {
          deleteBarrier.entered.complete();
        }
        await deleteBarrier.release.future;
        return tempDir;
      }

      final actions = TelemetrySessionActions(
        documentsDirectory: deleteDir,
        store: TelemetrySessionStore(documentsDirectory: deleteDir),
        artifactGate: ArtifactOperationGate(),
        sharePolicy: const _AllowPolicy(),
        readRecorderPhase: () => TelemetryRecorderPhase.idle,
        readRestartRequired: () => false,
      );

      const damagedId = '0000000000000000000000000000000d';
      final damaged = DamagedTelemetryProjection(
        id: damagedId,
        filesystemModifiedAtUtc: DateTime.utc(2026, 8, 30, 2),
        kind: DamagedTelemetryKind.corrupt,
      );

      final library = TelemetrySessionLibrary(
        sessions: const [],
        damaged: [damaged],
        groupCount: 1,
        recognizedBytes: 500,
        omittedCount: 0,
        encodedProjectionBytes: 500,
        workerDebugName: 'damaged-test-worker',
      );

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryHistoryAccessProvider.overrideWithValue(
              TelemetryHistoryAccess.permitted,
            ),
            telemetrySessionLibraryProvider.overrideWith(
              (ref) async => library,
            ),
            telemetrySessionActionsProvider.overrideWithValue(actions),
          ],
          child: MaterialApp(
            navigatorKey: navKey,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const TelemetrySessionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Wait for delete action to enter
      await deleteBarrier.entered.future.timeout(const Duration(seconds: 5));

      // Push covering route
      navKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Covering Route Screen')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Covering Route Screen'), findsOneWidget);

      // Release delete barrier (store operation fails via _DenyPolicy)
      deleteBarrier.release.complete();
      await _waitForSettlement(tester, () => true);

      // Terminal assertion: SnackBar suppressed because route is not current
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('damaged artifact delete success invalidates library provider even if route was covered', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sessionDir = Directory('${tempDir.path}/telltale-telemetry')..createSync(recursive: true);
      const damagedId = '0000000000000000000000000000000d';
      final damagedFile = File('${sessionDir.path}/$damagedId.ndjson');
      damagedFile.writeAsStringSync('{"kind":"corrupted"}\n');

      final deleteBarrier = _TestBarrier();
      Future<Directory> deleteDir() async {
        if (!deleteBarrier.entered.isCompleted) {
          deleteBarrier.entered.complete();
        }
        await deleteBarrier.release.future;
        return tempDir;
      }

      final actions = TelemetrySessionActions(
        documentsDirectory: deleteDir,
        store: TelemetrySessionStore(documentsDirectory: deleteDir),
        artifactGate: ArtifactOperationGate(),
        sharePolicy: const _AllowPolicy(),
        readRecorderPhase: () => TelemetryRecorderPhase.idle,
        readRestartRequired: () => false,
      );

      final damaged = DamagedTelemetryProjection(
        id: damagedId,
        filesystemModifiedAtUtc: DateTime.utc(2026, 8, 30, 2),
        kind: DamagedTelemetryKind.corrupt,
      );

      var libraryLoadCount = 0;
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryHistoryAccessProvider.overrideWithValue(
              TelemetryHistoryAccess.permitted,
            ),
            telemetrySessionLibraryProvider.overrideWith((ref) async {
              libraryLoadCount++;
              final exists = damagedFile.existsSync();
              return TelemetrySessionLibrary(
                sessions: const [],
                damaged: exists ? [damaged] : const [],
                groupCount: exists ? 1 : 0,
                recognizedBytes: exists ? 500 : 0,
                omittedCount: 0,
                encodedProjectionBytes: exists ? 500 : 0,
                workerDebugName: 'damaged-invalidate-worker',
              );
            }),
            telemetrySessionActionsProvider.overrideWithValue(actions),
          ],
          child: MaterialApp(
            navigatorKey: navKey,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const TelemetrySessionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Damaged tile is initially present
      expect(find.byKey(const ValueKey('telemetry-damaged-tile-$damagedId')), findsOneWidget);
      expect(libraryLoadCount, 1);

      // Start delete
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Wait for delete action to enter
      await deleteBarrier.entered.future.timeout(const Duration(seconds: 5));

      // Push covering route while delete is in-flight
      navKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Covering Route Screen')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Covering Route Screen'), findsOneWidget);

      // Release delete barrier -> delete completes successfully on disk
      deleteBarrier.release.complete();
      await _waitForSettlement(tester, () => !damagedFile.existsSync());

      // Terminal assertions:
      // 1. File was actually deleted on disk
      expect(damagedFile.existsSync(), isFalse);
      // 2. Covering route was NOT popped
      expect(find.text('Covering Route Screen'), findsOneWidget);
      // 3. No SnackBar on covering route
      expect(find.byType(SnackBar), findsNothing);

      // Pop the covering route to return to TelemetrySessionsScreen
      navKey.currentState!.pop();
      await _waitForSettlement(tester, () => libraryLoadCount >= 2);
      await tester.pumpAndSettle();

      // 4. libraryProvider was invalidated upon success (ref.invalidate re-evaluated it upon return)
      expect(libraryLoadCount, greaterThanOrEqualTo(2));

      // 5. Damaged tile is no longer rendered in the library!
      expect(find.byKey(const ValueKey('telemetry-damaged-tile-$damagedId')), findsNothing);
    });

    testWidgets('damaged tile has identity key and prevents Element cross-artifact reuse under stable root', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const damagedId1 = '00000000000000000000000000000001';
      const damagedId2 = '00000000000000000000000000000002';
      final damaged1 = DamagedTelemetryProjection(
        id: damagedId1,
        filesystemModifiedAtUtc: DateTime.utc(2026, 8, 30, 2),
        kind: DamagedTelemetryKind.corrupt,
      );
      final damaged2 = DamagedTelemetryProjection(
        id: damagedId2,
        filesystemModifiedAtUtc: DateTime.utc(2026, 8, 30, 3),
        kind: DamagedTelemetryKind.collision,
      );

      final trackingPolicy = _TrackingPolicy(allow: false);
      final actions = TelemetrySessionActions(
        documentsDirectory: () async => tempDir,
        store: TelemetrySessionStore(documentsDirectory: () async => tempDir),
        artifactGate: ArtifactOperationGate(),
        sharePolicy: trackingPolicy,
        readRecorderPhase: () => TelemetryRecorderPhase.idle,
        readRestartRequired: () => false,
      );

      var damagedList = <DamagedTelemetryProjection>[damaged1];

      // Root ProviderScope and MaterialApp remain 100% stable (no changing key on root)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryHistoryAccessProvider.overrideWithValue(
              TelemetryHistoryAccess.permitted,
            ),
            telemetrySessionActionsProvider.overrideWithValue(actions),
            telemetrySessionLibraryProvider.overrideWith(
              (ref) async => TelemetrySessionLibrary(
                sessions: const [],
                damaged: damagedList,
                groupCount: damagedList.length,
                recognizedBytes: 500,
                omittedCount: 0,
                encodedProjectionBytes: 500,
                workerDebugName: 'damaged-key-test-worker',
              ),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: TelemetrySessionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify tile has identity key matching damagedId1
      expect(find.byKey(const ValueKey('telemetry-damaged-tile-$damagedId1')), findsOneWidget);
      expect(find.byKey(const ValueKey('telemetry-damaged-tile-$damagedId2')), findsNothing);

      // Tap delete on damagedId1 to open confirmation dialog
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Delete this damaged recording?'), findsOneWidget);

      // Mutate list while confirmation dialog is open: replace damagedId1 with damagedId2
      damagedList = [damaged2];
      final container = ProviderScope.containerOf(tester.element(find.byType(TelemetrySessionsScreen)));
      container.invalidate(telemetrySessionLibraryProvider);
      await tester.pumpAndSettle();

      // Tile has now changed identity to damagedId2
      expect(find.byKey(const ValueKey('telemetry-damaged-tile-$damagedId2')), findsOneWidget);
      expect(find.byKey(const ValueKey('telemetry-damaged-tile-$damagedId1')), findsNothing);

      // Confirm delete in the dialog originally opened for damagedId1
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // State identity defense: widget.artifact.id != targetId check aborted the action
      expect(trackingPolicy.freezeCount, 0);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('positive control: dialog cancel = 0 dispatches, confirm = 1 dispatch, locale rebuild = 0 re-dispatches', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final trackingPolicy = _TrackingPolicy(allow: false);
      final actions = TelemetrySessionActions(
        documentsDirectory: () async => tempDir,
        store: TelemetrySessionStore(documentsDirectory: () async => tempDir),
        artifactGate: ArtifactOperationGate(),
        sharePolicy: trackingPolicy,
        readRecorderPhase: () => TelemetryRecorderPhase.idle,
        readRestartRequired: () => false,
      );

      final harnessKey = GlobalKey<_TestLocaleHarnessState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryHistoryAccessProvider.overrideWithValue(
              TelemetryHistoryAccess.permitted,
            ),
            telemetrySessionReplayProvider.overrideWith(
              (ref, id) async => testReplay,
            ),
            telemetrySessionActionsProvider.overrideWithValue(actions),
          ],
          child: _TestLocaleHarness(
            key: harnessKey,
            child: const TelemetrySessionDetailScreen(sessionId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Cancel does NOT dispatch
      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(trackingPolicy.freezeCount, 0);

      // 2. Confirm dispatches exactly ONCE
      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(trackingPolicy.freezeCount, 1);

      // 3. Repeated locale switching does NOT re-dispatch action or re-prompt dialog
      harnessKey.currentState!.changeLocale(testUiLocale);
      await tester.pumpAndSettle();
      expect(trackingPolicy.freezeCount, 1);
      expect(find.byType(AlertDialog), findsNothing);

      harnessKey.currentState!.changeLocale(const Locale('en'));
      await tester.pumpAndSettle();
      expect(trackingPolicy.freezeCount, 1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('narrow 320dp width, landscape, and 200% text scale render real confirmation dialog and snackbar without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final actions = TelemetrySessionActions(
        documentsDirectory: () async => tempDir,
        store: TelemetrySessionStore(documentsDirectory: () async => tempDir),
        artifactGate: ArtifactOperationGate(),
        sharePolicy: const _DenyPolicy(),
        readRecorderPhase: () => TelemetryRecorderPhase.idle,
        readRestartRequired: () => false,
      );

      final harnessKey = GlobalKey<_TestLocaleHarnessState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryHistoryAccessProvider.overrideWithValue(
              TelemetryHistoryAccess.permitted,
            ),
            telemetrySessionReplayProvider.overrideWith(
              (ref, id) async => testReplay,
            ),
            telemetrySessionActionsProvider.overrideWithValue(actions),
          ],
          child: _TestLocaleHarness(
            key: harnessKey,
            textScaler: const TextScaler.linear(2.0),
            child: const TelemetrySessionDetailScreen(sessionId: testSessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open real delete dialog from real TelemetrySessionDetailScreen
      final deleteBtn = find.widgetWithText(OutlinedButton, 'Delete');
      await tester.scrollUntilVisible(deleteBtn, 100);
      await tester.ensureVisible(deleteBtn);
      await tester.pumpAndSettle();
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      final dialogFinder = find.byType(AlertDialog);
      expect(dialogFinder, findsOneWidget);

      // Verify effective text scaling is genuinely 2.0 (14 scaled to 28)
      expect(
        MediaQuery.textScalerOf(tester.element(dialogFinder)).scale(14),
        28.0,
      );

      // Verify no RenderFlex overflow during 200% text scale rendering at 320dp width
      expect(tester.takeException(), isNull);

      // Verify accessible touch target dimensions (>= 48dp min touch height)
      final confirmBtnFinder = find.widgetWithText(FilledButton, 'Delete');
      final cancelBtnFinder = find.widgetWithText(TextButton, 'Cancel');
      expect(tester.getSize(confirmBtnFinder).height, greaterThanOrEqualTo(48.0));
      expect(tester.getSize(cancelBtnFinder).height, greaterThanOrEqualTo(48.0));

      // Confirm delete -> SnackBar displayed
      await tester.tap(confirmBtnFinder);
      await tester.pumpAndSettle();

      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);
      expect(
        MediaQuery.textScalerOf(tester.element(snackBarFinder)).scale(14),
        28.0,
      );
      expect(tester.takeException(), isNull);

      // Switch to Traditional Chinese
      harnessKey.currentState!.changeLocale(testUiLocale);
      await tester.pump();

      expect(find.text('刪除未完成：操作期間行車或連線狀態已改變'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Verify narrow landscape layout (568x320)
      tester.view.physicalSize = const Size(568, 320);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('detail actions discard feedback if sessionId changes during await', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final trackingPolicy = _TrackingPolicy(allow: false);
      final exportBarrier = _TestBarrier();
      Future<Directory> exportDir() async {
        if (!exportBarrier.entered.isCompleted) {
          exportBarrier.entered.complete();
        }
        await exportBarrier.release.future;
        return tempDir;
      }

      final actions = TelemetrySessionActions(
        documentsDirectory: exportDir,
        store: TelemetrySessionStore(documentsDirectory: exportDir),
        artifactGate: ArtifactOperationGate(),
        sharePolicy: trackingPolicy,
        readRecorderPhase: () => TelemetryRecorderPhase.idle,
        readRestartRequired: () => false,
      );

      final sessionNotifier = ValueNotifier<String>(testSessionId);
      addTearDown(sessionNotifier.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryHistoryAccessProvider.overrideWithValue(
              TelemetryHistoryAccess.permitted,
            ),
            telemetrySessionReplayProvider.overrideWith(
              (ref, id) async => id == testSessionId ? testReplay : testReplay2,
            ),
            telemetrySessionActionsProvider.overrideWithValue(actions),
          ],
          child: ValueListenableBuilder<String>(
            valueListenable: sessionNotifier,
            builder: (context, currentId, _) => MaterialApp(
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: TelemetrySessionDetailScreen(sessionId: currentId),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Case 1: Delete confirmation aborted when sessionId changes
      final deleteBtn = find.widgetWithText(OutlinedButton, 'Delete');
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Delete this local recording?'), findsOneWidget);

      // Mutate sessionId while dialog is awaiting confirmation
      sessionNotifier.value = testSessionId2;
      await tester.pump();

      // Confirm delete in dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // targetSessionId mismatch safely aborted before action dispatch
      expect(trackingPolicy.freezeCount, 0);
      expect(find.byType(SnackBar), findsNothing);

      // Case 2: In-flight export feedback aborted when sessionId changes during await
      sessionNotifier.value = testSessionId;
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Export'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export CSV'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Wait for export action to enter
      await exportBarrier.entered.future.timeout(const Duration(seconds: 5));

      // Mutate sessionId while export is in flight
      sessionNotifier.value = testSessionId2;
      await tester.pump();

      // Release export barrier
      exportBarrier.release.complete();
      await _waitForSettlement(tester, () => true);

      // TargetSessionId check safely discarded stale feedback for testSessionId2
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}

class _TestBarrier {
  final entered = Completer<void>();
  final release = Completer<void>();
}

class _TestLocaleHarness extends StatefulWidget {
  const _TestLocaleHarness({
    required this.child,
    this.textScaler,
    super.key,
  });

  final Widget child;
  final TextScaler? textScaler;

  @override
  State<_TestLocaleHarness> createState() => _TestLocaleHarnessState();
}

class _TestLocaleHarnessState extends State<_TestLocaleHarness> {
  Locale _locale = const Locale('en');

  void changeLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: widget.textScaler == null
          ? null
          : (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: widget.textScaler),
                child: child!,
              ),
      home: widget.child,
    );
  }
}

class _AllowPolicy implements AppSharePolicy {
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

class _DenyPolicy implements AppSharePolicy {
  const _DenyPolicy();

  @override
  SharePreparationPermit? freeze() => null;

  @override
  SharePermitValidation validate(SharePreparationPermit permit) =>
      const SharePermitValidation.invalid(SharePermitCause.connection);
}

class _TrackingPolicy implements AppSharePolicy {
  _TrackingPolicy({required this.allow});

  final bool allow;
  int freezeCount = 0;
  int validateCount = 0;

  @override
  SharePreparationPermit? freeze() {
    freezeCount++;
    if (!allow) return null;
    return const SharePreparationPermit(
      recorderEpoch: 1,
      foregroundEpoch: 1,
      connectionEpoch: 1,
      safetyEpoch: 1,
      connectionClass: ShareConnectionClass.disconnected,
    );
  }

  @override
  SharePermitValidation validate(SharePreparationPermit permit) {
    validateCount++;
    return allow
        ? const SharePermitValidation.valid()
        : const SharePermitValidation.invalid(SharePermitCause.connection);
  }
}
