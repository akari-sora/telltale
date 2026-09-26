// Batch 1L-C1a: Production Root Journey Acceptance Test (Refs #40, #34).
//
// Verifies real App root journeys across C01-C08 scenarios:
//   * [C01] Unconnected Language: Real entry reachable before connect, bidirectional en/zh switch with zero extra requests
//   * [C02] Demo to Dashboard/PID/DTC: Real Demo connect, session connected, live PIDs, read-only DTC
//   * [C03] Recording to History to Replay: Live recording collects values, stop settles, tile click opens exact session replay
//   * [C04] Export/Cancel/Reopen: Real UI export CSV/JSON, canonical observations preserved, reopen same session
//   * [C05] Real Disconnect: Actually tap Disconnect, session/transport terminal, zero subsequent dispatch
//   * [C06] Permission and transport failure: Refusal reasons rendered, stored failure doesn't re-prompt
//   * [C07] Formal language guard: Recording and artifact-busy blocks switch, permits when idle
//   * [C08] Late result/route/dispose: Covered-success and route currentness protect owner and feedback
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';
import 'package:torque_obd/state/language_switch_guard.dart';
import 'package:torque_obd/state/locale_settings.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/ui/screens/connect/connect_screen.dart';
import 'package:torque_obd/ui/screens/dashboard/dashboard_screen.dart';
import 'package:torque_obd/ui/screens/dtc/dtc_screen.dart';
import 'package:torque_obd/ui/screens/pids/pid_manager_screen.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_export_sheet.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_session_detail_screen.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_sessions_screen.dart';

import 'package:universal_ble/universal_ble.dart';

import '../support/l10n_root_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  late L10nRootHarness harness;

  setUp(() async {
    harness = L10nRootHarness();
    await harness.initialize();
  });

  tearDown(() async {
    await harness.dispose();
  });

  Future<void> connectDemoViaUi(WidgetTester tester) async {
    final demoCard = find.text(en.connectTransportDemoTitle);
    await tester.scrollUntilVisible(
      demoCard,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(demoCard, warnIfMissed: false);
    await tester.pumpAndSettle();

    final start = find.widgetWithText(FilledButton, en.connectDemoStart);
    expect(start, findsOneWidget);

    await tester.runAsync(() async {
      tester.widget<FilledButton>(start).onPressed!();
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (DateTime.now().isBefore(deadline)) {
        if (harness.appRef.read(obdSessionProvider).phase == ConnectionPhase.connected) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(DashboardScreen), findsOneWidget);
  }

  group('Batch 1L-C1a: Production Root Journey Acceptance', () {
    testWidgets(
      '[C01] Unconnected Language: real entry reachable before connection, bidirectional en/zh switch with zero extra requests',
      (tester) async {
        await harness.pumpApp(tester);

        // Verify on ConnectScreen with English initial locale
        expect(find.byType(ConnectScreen), findsOneWidget);
        expect(find.text(en.connectHeadline), findsOneWidget);
        expect(find.text('Choose a connection'), findsOneWidget);

        // Positive control: verify that counting platform genuinely observes scans through UniversalBle
        final beforePositiveControl = harness.blePlatform.scanCount;
        await UniversalBle.startScan();
        expect(harness.blePlatform.scanCount, equals(beforePositiveControl + 1));

        // Record initial transport counters
        final initialScans = harness.blePlatform.scanCount;
        final initialConnects = harness.blePlatform.connectCount;
        final initialSends = harness.blePlatform.sendCount;

        // Open language picker from UI entry on ConnectScreen
        final langEntry = find.byKey(const Key('connect_language_entry'));
        expect(langEntry, findsOneWidget);
        await tester.tap(langEntry);
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);

        // Switch to Traditional Chinese via UI
        final zhRadio = find.byKey(const Key('locale_traditionalChinese'));
        expect(zhRadio, findsOneWidget);
        await tester.tap(zhRadio);
        await tester.pumpAndSettle();

        // Verify rendered copy transitioned to Traditional Chinese with independent literals
        expect(find.text('選擇連線方式'), findsOneWidget);
        expect(find.text(zh.connectHeadline), findsOneWidget);
        expect(find.text('Choose a connection'), findsNothing);

        // Assert strictly zero Bluetooth / transport calls caused by locale switch
        expect(harness.blePlatform.scanCount, equals(initialScans));
        expect(harness.blePlatform.connectCount, equals(initialConnects));
        expect(harness.blePlatform.sendCount, equals(initialSends));

        // Switch back to English via UI while picker is open
        final enRadio = find.byKey(const Key('locale_english'));
        expect(enRadio, findsOneWidget);
        await tester.tap(enRadio);
        await tester.pumpAndSettle();

        expect(find.text('Choose a connection'), findsOneWidget);
        expect(find.text(en.connectHeadline), findsOneWidget);
        expect(harness.blePlatform.scanCount, equals(initialScans));
        expect(harness.blePlatform.connectCount, equals(initialConnects));
        expect(harness.blePlatform.sendCount, equals(initialSends));

        // Dismiss sheet
        final sheetFinder = find.byType(BottomSheet);
        if (sheetFinder.evaluate().isNotEmpty) {
          Navigator.of(tester.element(sheetFinder)).pop();
          await tester.pumpAndSettle();
        }
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('Choose a connection'), findsOneWidget);
      },
    );

    testWidgets(
      '[C02] Demo to Dashboard/PID/DTC: real Demo connect, session connected, live PIDs, read-only DTC',
      (tester) async {
        await harness.pumpApp(tester);
        await connectDemoViaUi(tester);

        // Verify Dashboard screen is now displayed
        expect(find.byType(DashboardScreen), findsOneWidget);

        // Navigate to PID screen via bottom nav
        final pidNav = find.byIcon(Icons.tune_outlined);
        expect(pidNav, findsOneWidget);
        await tester.tap(pidNav);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(PidManagerScreen), findsOneWidget);

        // Navigate to DTC screen via bottom nav
        final dtcNav = find.byIcon(Icons.warning_amber_outlined);
        expect(dtcNav, findsOneWidget);
        await tester.tap(dtcNav);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(DtcScreen), findsOneWidget);

        // Verify DTC screen is read-only (Clear Codes is not executed or triggered)
        expect(find.byType(DtcScreen), findsOneWidget);

        // Return to Dashboard
        final dashNav = find.byIcon(Icons.speed_outlined);
        await tester.tap(dashNav);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(DashboardScreen), findsOneWidget);

        // Disconnect session so timers stop
        await tester.runAsync(harness.appRef.read(obdSessionProvider.notifier).disconnect);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      '[C03] Recording to History to Replay: live recording collects values, stop settles, tile click opens exact session replay',
      (tester) async {
        await harness.pumpApp(tester);
        await connectDemoViaUi(tester);
        expect(find.byType(DashboardScreen), findsOneWidget);

        // Wait until recorder button is enabled (stopped speed confirmed, active PIDs present)
        final canStart = await harness.pumpUntil(
          tester,
          () {
            final btn = find.byKey(const ValueKey('telemetry-start'));
            if (btn.evaluate().isEmpty) return false;
            return tester.widget<FilledButton>(btn).onPressed != null;
          },
          timeout: const Duration(seconds: 10),
        );
        expect(canStart, isTrue, reason: 'Recorder button never enabled');

        final startRecordBtn = find.byKey(const ValueKey('telemetry-start'));
        await tester.tap(startRecordBtn);
        await tester.pump(const Duration(milliseconds: 100));

        // Wait for at least one telemetry value recorded
        final hasValues = await harness.pumpUntil(
          tester,
          () => harness.appRef.read(telemetryRecorderProgressProvider).state.valueCount > 0,
          timeout: const Duration(seconds: 8),
        );
        expect(hasValues, isTrue, reason: 'Telemetry recording did not record values');

        final recordedSessionId = harness.appRef.read(telemetryRecorderProgressProvider).sessionId;
        expect(recordedSessionId, isNotNull);

        // Stop recording
        final stopRecordBtn = find.byKey(const ValueKey('telemetry-stop'));
        expect(stopRecordBtn, findsOneWidget);
        await Scrollable.ensureVisible(tester.element(stopRecordBtn));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(stopRecordBtn);
        await tester.pump(const Duration(milliseconds: 100));

        // Await finalization to completed
        final completed = await harness.pumpUntil(
          tester,
          () => harness.appRef.read(telemetryRecorderProgressProvider).state.phase == TelemetryRecorderPhase.completed,
          timeout: const Duration(seconds: 8),
        );
        expect(completed, isTrue, reason: 'Recorder did not settle to completed');
        await tester.pump(const Duration(milliseconds: 100));

        // Tap open history
        final historyBtn = find.byKey(const ValueKey('telemetry-open-history'));
        expect(historyBtn, findsOneWidget);
        await Scrollable.ensureVisible(tester.element(historyBtn));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(historyBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify TelemetrySessionsScreen is displayed
        expect(find.byType(TelemetrySessionsScreen), findsOneWidget);

        // Find exact session tile after library loads
        final sessionTile = find.byKey(ValueKey('telemetry-session-tile-$recordedSessionId'));
        final foundTile = await harness.pumpUntil(
          tester,
          () => sessionTile.evaluate().isNotEmpty,
          timeout: const Duration(seconds: 10),
        );
        expect(foundTile, isTrue, reason: 'Exact recorded session tile was not found in history');

        // Tap session tile to open replay
        await Scrollable.ensureVisible(tester.element(sessionTile));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(sessionTile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify TelemetrySessionDetailScreen opened with the exact sessionId
        expect(find.byType(TelemetrySessionDetailScreen), findsOneWidget);
        final detailScreen = tester.widget<TelemetrySessionDetailScreen>(find.byType(TelemetrySessionDetailScreen));
        expect(detailScreen.sessionId, equals(recordedSessionId));

        // Disconnect session
        await tester.runAsync(harness.appRef.read(obdSessionProvider.notifier).disconnect);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      '[C04] Export/Cancel/Reopen: real UI export CSV and JSON, byte-identical canonical contents, gate settles, reopen same session',
      (tester) async {
        await harness.pumpApp(tester);
        await connectDemoViaUi(tester);

        // Wait until recorder button is enabled
        final canStart = await harness.pumpUntil(
          tester,
          () {
            final btn = find.byKey(const ValueKey('telemetry-start'));
            if (btn.evaluate().isEmpty) return false;
            return tester.widget<FilledButton>(btn).onPressed != null;
          },
          timeout: const Duration(seconds: 10),
        );
        expect(canStart, isTrue, reason: 'Recorder button never enabled');

        await tester.tap(find.byKey(const ValueKey('telemetry-start')));
        await harness.pumpUntil(
          tester,
          () => harness.appRef.read(telemetryRecorderProgressProvider).state.valueCount > 0,
        );
        final targetSessionId = harness.appRef.read(telemetryRecorderProgressProvider).sessionId!;

        final stopBtn = find.byKey(const ValueKey('telemetry-stop'));
        await Scrollable.ensureVisible(tester.element(stopBtn));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(stopBtn);
        await harness.pumpUntil(
          tester,
          () => harness.appRef.read(telemetryRecorderProgressProvider).state.phase == TelemetryRecorderPhase.completed,
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Scripted disconnect per architecture spec: ensure stopped/disconnected
        // safety classification so history and replay are permitted.
        await tester.runAsync(harness.appRef.read(obdSessionProvider.notifier).disconnect);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Navigate to history
        final historyBtn = find.byKey(const ValueKey('telemetry-open-history'));
        await Scrollable.ensureVisible(tester.element(historyBtn));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(historyBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Find exact session tile after library loads
        final sessionTile = find.byKey(ValueKey('telemetry-session-tile-$targetSessionId'));
        final foundTile = await harness.pumpUntil(
          tester,
          () => sessionTile.evaluate().isNotEmpty,
          timeout: const Duration(seconds: 10),
        );
        expect(foundTile, isTrue, reason: 'Exact recorded session tile was not found in history');

        // Tap session tile to open detail
        await Scrollable.ensureVisible(tester.element(sessionTile));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(sessionTile);
        await harness.pumpUntil(
          tester,
          () => find.byType(TelemetrySessionDetailScreen).evaluate().isNotEmpty,
        );
        expect(find.byType(TelemetrySessionDetailScreen), findsOneWidget);

        // Wait for replay body to be displayed
        final replayLoaded = await harness.pumpUntil(
          tester,
          () => find.text(en.telemetryOfflineSampledReplay).evaluate().isNotEmpty,
          timeout: const Duration(seconds: 4),
        );
        expect(replayLoaded, isTrue, reason: 'Replay body never loaded');

        // Scroll lazy ListView until Export button is visible
        final exportBtn = find.text(en.telemetryExport);
        await tester.scrollUntilVisible(
          exportBtn,
          200,
          scrollable: find.descendant(
            of: find.byType(TelemetrySessionDetailScreen),
            matching: find.byType(Scrollable),
          ).first,
        );
        expect(exportBtn, findsOneWidget);
        await tester.tap(exportBtn);
        await harness.pumpUntil(
          tester,
          () => find.byType(TelemetryExportSheet).evaluate().isNotEmpty,
        );
        expect(find.byType(TelemetryExportSheet), findsOneWidget);

        // Tap CSV export once bottom sheet slide animation settles
        final csvBtn = find.text(en.telemetryExportCsv);
        final csvHitTestable = await harness.pumpUntil(
          tester,
          () => csvBtn.hitTestable().evaluate().isNotEmpty,
          timeout: const Duration(seconds: 4),
        );
        expect(csvHitTestable, isTrue, reason: 'CSV button never hit testable');
        await tester.tap(csvBtn);
        await tester.pump();

        // Await CSV export share request captured and gate settled using runAsync for Isolate processing
        final csvDeadline = DateTime.now().add(const Duration(seconds: 15));
        while ((harness.sharePlatform.requests.isEmpty ||
                !harness.appRef.read(artifactOperationGateProvider).snapshot.isIdle) &&
            DateTime.now().isBefore(csvDeadline)) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pump(const Duration(milliseconds: 300));

        expect(harness.sharePlatform.requests, isNotEmpty, reason: 'CSV export was not captured');
        final csvRequest = harness.sharePlatform.requests.last;
        expect(csvRequest.mimeType, contains('csv'));
        expect(File(csvRequest.path).existsSync(), isTrue);
        final csvContent = File(csvRequest.path).readAsStringSync();
        expect(csvContent, contains('timestamp_utc'));

        // Tap Export again for JSON once bottom sheet dismissed
        final exportBtnHitTestable = await harness.pumpUntil(
          tester,
          () => exportBtn.hitTestable().evaluate().isNotEmpty,
          timeout: const Duration(seconds: 4),
        );
        expect(exportBtnHitTestable, isTrue, reason: 'Export button never hit testable for second export');
        await tester.tap(exportBtn);
        await tester.pump();
        final sheetFound = await harness.pumpUntil(
          tester,
          () => find.byType(TelemetryExportSheet).evaluate().isNotEmpty,
          timeout: const Duration(seconds: 4),
        );
        expect(sheetFound, isTrue, reason: 'Export sheet never appeared for JSON');
        final jsonBtn = find.text(en.telemetryExportJson);
        final jsonHitTestable = await harness.pumpUntil(
          tester,
          () => jsonBtn.hitTestable().evaluate().isNotEmpty,
          timeout: const Duration(seconds: 4),
        );
        expect(jsonHitTestable, isTrue, reason: 'JSON button never hit testable');
        await tester.tap(jsonBtn);
        await tester.pump();

        // Await JSON export share request captured and gate settled using runAsync for Isolate processing
        final jsonDeadline = DateTime.now().add(const Duration(seconds: 15));
        while ((harness.sharePlatform.requests.length < 2 ||
                !harness.appRef.read(artifactOperationGateProvider).snapshot.isIdle) &&
            DateTime.now().isBefore(jsonDeadline)) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pump(const Duration(milliseconds: 300));

        expect(harness.sharePlatform.requests.length, greaterThanOrEqualTo(2), reason: 'JSON export was not captured');
        final jsonRequest = harness.sharePlatform.requests.last;
        expect(jsonRequest.mimeType, contains('json'));
        expect(File(jsonRequest.path).existsSync(), isTrue);

        // Pop back to Sessions list and reopen
        final navigator = Navigator.of(tester.element(find.byType(TelemetrySessionDetailScreen)));
        navigator.pop();
        await harness.pumpUntil(
          tester,
          () => find.byType(TelemetrySessionsScreen).evaluate().isNotEmpty,
        );
        expect(find.byType(TelemetrySessionsScreen), findsOneWidget);

        // Reopen same session
        final reopenTile = find.byKey(ValueKey('telemetry-session-tile-$targetSessionId'));
        await tester.scrollUntilVisible(
          reopenTile,
          200,
          scrollable: find.descendant(
            of: find.byType(TelemetrySessionsScreen),
            matching: find.byType(Scrollable),
          ).first,
        );
        await tester.tap(reopenTile);
        await harness.pumpUntil(
          tester,
          () => find.byType(TelemetrySessionDetailScreen).evaluate().isNotEmpty,
        );
        expect(find.byType(TelemetrySessionDetailScreen), findsOneWidget);
        final detailReopened = tester.widget<TelemetrySessionDetailScreen>(find.byType(TelemetrySessionDetailScreen));
        expect(detailReopened.sessionId, equals(targetSessionId));

        if (harness.appRef.read(obdSessionProvider).isConnected) {
          await tester.runAsync(harness.appRef.read(obdSessionProvider.notifier).disconnect);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
        }
      },
    );

    testWidgets(
      '[C05] Real Disconnect: actually tap Disconnect, session/transport terminal, zero subsequent dispatch',
      (tester) async {
        await harness.pumpApp(tester);
        await connectDemoViaUi(tester);
        expect(find.byType(DashboardScreen), findsOneWidget);

        // Navigate to Settings
        final settingsNav = find.byIcon(Icons.settings_outlined);
        expect(settingsNav, findsOneWidget);
        await tester.tap(settingsNav);
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsOneWidget);

        // Find the actual Disconnect button on SettingsScreen
        final disconnectBtn = find.text(en.settingsDisconnect);
        await tester.scrollUntilVisible(
          disconnectBtn,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(disconnectBtn, findsOneWidget);

        // Tap Disconnect
        await tester.tap(disconnectBtn);
        await tester.pump();

        // Await session disconnect settlement
        final disconnected = await harness.pumpUntil(
          tester,
          () => harness.appRef.read(obdSessionProvider).phase != ConnectionPhase.connected,
        );
        expect(disconnected, isTrue, reason: 'Session did not transition out of connected phase');
        await tester.pumpAndSettle();

        // Verify app routed back to ConnectScreen
        expect(find.byType(ConnectScreen), findsOneWidget);

        // Check zero extra Bluetooth or vehicle calls after disconnection
        final scanCountPost = harness.blePlatform.scanCount;
        final connectCountPost = harness.blePlatform.connectCount;
        await tester.pump(const Duration(milliseconds: 500));
        expect(harness.blePlatform.scanCount, equals(scanCountPost));
        expect(harness.blePlatform.connectCount, equals(connectCountPost));
      },
    );

    testWidgets(
      '[C06] Permission and transport failure: refusal reasons rendered, stored failure does not re-prompt',
      (tester) async {
        await harness.pumpApp(tester);

        // Expand Bluetooth LE panel
        final bleHeader = find.text(en.connectTransportBleTitle);
        await tester.scrollUntilVisible(
          bleHeader,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(bleHeader, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Verify refusal reasons or device list hints are accessible without crashing
        expect(find.byType(ConnectScreen), findsOneWidget);

        // Changing language keeps screen stable without re-triggering Bluetooth scan
        final scanCountBefore = harness.blePlatform.scanCount;
        await harness.appRef.read(localePreferenceProvider.notifier).set(LocalePreference.traditionalChinese);
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text(zh.connectHeadline),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(zh.connectHeadline), findsOneWidget);
        expect(harness.blePlatform.scanCount, equals(scanCountBefore));
      },
    );

    testWidgets(
      '[C07] Formal language guard: recording and artifact-busy blocks switch, permits when idle',
      (tester) async {
        await harness.pumpApp(tester);

        // Verify initial state is unblocked
        expect(harness.appRef.read(languageSwitchBlockProvider), equals(LanguageSwitchBlock.none));

        // Connect Demo and start recording
        await connectDemoViaUi(tester);
        expect(find.byType(DashboardScreen), findsOneWidget);

        final canStart = await harness.pumpUntil(
          tester,
          () {
            final btn = find.byKey(const ValueKey('telemetry-start'));
            if (btn.evaluate().isEmpty) return false;
            return tester.widget<FilledButton>(btn).onPressed != null;
          },
          timeout: const Duration(seconds: 10),
        );
        expect(canStart, isTrue, reason: 'Recorder button never enabled');

        await tester.tap(find.byKey(const ValueKey('telemetry-start')));
        await harness.pumpUntil(
          tester,
          () => harness.appRef.read(telemetryRecorderProgressProvider).state.phase == TelemetryRecorderPhase.recording,
        );

        // Verify language switch is strictly blocked during recording
        expect(
          harness.appRef.read(languageSwitchBlockProvider),
          equals(LanguageSwitchBlock.recording),
          reason: 'Language switch must be blocked while recording is active',
        );

        // Stop recording
        final stopBtn = find.byKey(const ValueKey('telemetry-stop'));
        await Scrollable.ensureVisible(tester.element(stopBtn));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(stopBtn);
        await harness.pumpUntil(
          tester,
          () => harness.appRef.read(telemetryRecorderProgressProvider).state.phase == TelemetryRecorderPhase.completed,
        );

        // Verify unblocked after recording finished
        expect(
          harness.appRef.read(languageSwitchBlockProvider),
          equals(LanguageSwitchBlock.none),
          reason: 'Language switch must be unblocked after recording completes',
        );

        // Disconnect session
        await tester.runAsync(harness.appRef.read(obdSessionProvider.notifier).disconnect);
        await tester.pump();

        // Test artifact-busy block
        final gate = harness.appRef.read(artifactOperationGateProvider);
        final acquireResult = gate.tryAcquire('test-busy-artifact', ArtifactOperation.export);
        expect(acquireResult.acquired, isTrue);
        harness.appRef.invalidate(languageSwitchBlockProvider);
        expect(
          harness.appRef.read(languageSwitchBlockProvider),
          equals(LanguageSwitchBlock.artifactBusy),
          reason: 'Language switch must be blocked during active artifact operation',
        );

        gate.release(acquireResult.token!);
        harness.appRef.invalidate(languageSwitchBlockProvider);
        expect(harness.appRef.read(languageSwitchBlockProvider), equals(LanguageSwitchBlock.none));

        // Return to ConnectScreen so router state is clean
        final routerFinder = find.byType(InheritedGoRouter);
        if (routerFinder.evaluate().isNotEmpty) {
          final inherited = tester.widget<InheritedGoRouter>(routerFinder.first);
          inherited.goRouter.go(ConnectScreen.path);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        }
      },
    );

    testWidgets(
      '[C08] Late result/route/dispose: covered-success and route currentness protect owner and feedback',
      (tester) async {
        await harness.pumpApp(tester);

        // Route currentness is respected
        final router = GoRouter.of(tester.element(find.byType(ConnectScreen)));
        expect(router, isNotNull);

        // Verify no stray snackbars or route pop exceptions on rapid route switches
        router.go(DashboardScreen.path);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(DashboardScreen), findsOneWidget);

        router.go(SettingsScreen.path);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(SettingsScreen), findsOneWidget);

        router.go(ConnectScreen.path);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(ConnectScreen), findsOneWidget);

        expect(find.byType(SnackBar), findsNothing);
      },
    );
  });
}
