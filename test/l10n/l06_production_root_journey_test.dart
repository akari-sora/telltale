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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:torque_obd/core/ble_scan_permissions.dart';
import 'package:torque_obd/core/share/app_share_platform_bridge.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/transcript.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';
import 'package:torque_obd/state/dtc_scan.dart';
import 'package:torque_obd/state/language_switch_guard.dart';
import 'package:torque_obd/state/locale_settings.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/ui/screens/connect/connect_screen.dart';
import 'package:torque_obd/ui/screens/connect/transport_kind_copy.dart';
import 'package:torque_obd/ui/screens/dashboard/dashboard_screen.dart';
import 'package:torque_obd/ui/screens/dtc/dtc_screen.dart';
import 'package:torque_obd/ui/screens/pids/pid_manager_screen.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_export_sheet.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_session_detail_screen.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_sessions_screen.dart';
import 'package:torque_obd/ui/widgets/language_picker.dart';
import 'package:torque_obd/ui/widgets/telemetry/telemetry_session_action_feedback.dart';

import 'package:universal_ble/universal_ble.dart';

import '../support/l10n_root_harness.dart';

class _TestBarrier {
  final Completer<void> entered = Completer<void>();
  final Completer<void> release = Completer<void>();
}

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

  Future<void> connectDemoViaUi(WidgetTester tester, {Locale? locale}) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      try {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      } catch (_) {}
    });
    await tester.pump();

    final loc = lookupAppLocalizations(locale ?? englishLocale);
    final demoCard = find.text(loc.connectTransportDemoTitle);
    await tester.scrollUntilVisible(
      demoCard,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(demoCard, warnIfMissed: false);
    await tester.pumpAndSettle();

    final start = find.widgetWithText(FilledButton, loc.connectDemoStart);
    expect(start, findsOneWidget);

    await tester.scrollUntilVisible(
      start,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(start, warnIfMissed: false);
    await tester.pump();

    final connected = await harness.pumpUntil(
      tester,
      () => harness.appRef.read(obdSessionProvider).phase == ConnectionPhase.connected,
      timeout: const Duration(seconds: 10),
    );
    expect(connected, isTrue, reason: 'Demo session did not reach connected phase');

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

        for (final targetLocale in [englishLocale, traditionalChineseLocale]) {
          final loc = lookupAppLocalizations(targetLocale);
          final targetPref = targetLocale == englishLocale
              ? LocalePreference.english
              : LocalePreference.traditionalChinese;
          if (harness.appRef.read(localePreferenceProvider) != targetPref) {
            await harness.appRef.read(localePreferenceProvider.notifier).set(targetPref);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 200));
          }

          await connectDemoViaUi(tester, locale: targetLocale);

          // Verify Dashboard screen is now displayed
          expect(find.byType(DashboardScreen), findsOneWidget);

          // Verify live PIDs are observed and active in telemetry snapshot
          final hasLiveTelemetry = await harness.pumpUntil(
            tester,
            () {
              final snap = harness.appRef.read(telemetryProvider).value;
              return snap != null && snap.readings.isNotEmpty;
            },
            timeout: const Duration(seconds: 8),
          );
          expect(hasLiveTelemetry, isTrue, reason: 'No live telemetry readings observed on dashboard ($targetLocale)');
          final snapshot = harness.appRef.read(telemetryProvider).value!;
          expect(snapshot.readings, isNotEmpty);
          final rpmReading = snapshot.readings[PidLibrary.engineRpm.id];
          expect(rpmReading, isNotNull, reason: 'Engine RPM reading must be present in snapshot');
          expect(rpmReading!.value, greaterThan(0), reason: 'Engine RPM reading must be greater than zero');
          expect(rpmReading.pid.id, equals(PidLibrary.engineRpm.id));
          expect(rpmReading.pid.units, equals('rpm'));

          // DemoTransport boundary observation: verify that client transcript recorded actual writes
          final client = harness.appRef.read(obdSessionProvider.notifier).client;
          expect(client, isNotNull, reason: 'Elm327Client must be non-null while Demo session is connected');
          final wireWrites = client!.transcript.entries
              .where((e) => e.direction == TranscriptDirection.out)
              .length;
          expect(wireWrites, greaterThan(0), reason: 'Demo session must produce wire writes during polling ($targetLocale)');

          // Navigate to PID screen via bottom nav
          final pidNav = find.byIcon(Icons.tune_outlined);
          expect(pidNav, findsOneWidget);
          await tester.tap(pidNav);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.byType(PidManagerScreen), findsOneWidget);
          expect(find.text('Engine RPM'), findsWidgets);

          // Navigate to DTC screen via bottom nav
          final dtcNav = find.byIcon(Icons.warning_amber_outlined);
          expect(dtcNav, findsOneWidget);
          await tester.tap(dtcNav);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.byType(DtcScreen), findsOneWidget);

          // Perform read-only DTC scan via UI with localized button text
          final scanBtn = find.widgetWithText(FilledButton, loc.dtcStartScan);
          expect(scanBtn, findsOneWidget);
          await tester.tap(scanBtn);
          await tester.pump();

          // Await DTC scan completion
          final scanCompleted = await harness.pumpUntil(
            tester,
            () => harness.appRef.read(dtcScanProvider).hasScanned,
            timeout: const Duration(seconds: 12),
          );
          expect(scanCompleted, isTrue, reason: 'DTC scan never completed ($targetLocale)');
          await tester.pumpAndSettle();

          final dtcScan = harness.appRef.read(dtcScanProvider);
          expect(dtcScan.totalCodes, greaterThan(0));
          // Verify independent literal fault codes and simulated VIN from Demo simulator
          expect(find.textContaining('P0301'), findsWidgets);
          expect(find.textContaining('1D4GP00R55B123456'), findsWidgets);

          // Explicitly assert read-only inspection: Clear Codes is never confirmed or dispatched
          expect(dtcScan.clearing, isFalse);
          expect(dtcScan.clearNotice, isNull);
          expect(find.byType(AlertDialog), findsNothing);
          expect(find.byType(DtcScreen), findsOneWidget);

          // Return to Dashboard
          final dashNav = find.byIcon(Icons.speed_outlined);
          await tester.tap(dashNav);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.byType(DashboardScreen), findsOneWidget);

          // Disconnect session cleanly so timers stop
          await tester.runAsync(harness.appRef.read(obdSessionProvider.notifier).disconnect);
          await harness.pumpUntil(
            tester,
            () => harness.appRef.read(obdSessionProvider).phase == ConnectionPhase.disconnected,
            timeout: const Duration(seconds: 10),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          // Route cleanly back to ConnectScreen for the next root journey iteration
          final router = GoRouter.of(tester.element(find.byType(DashboardScreen)));
          router.go(ConnectScreen.path);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.byType(ConnectScreen), findsOneWidget);
        }

        // Restore English locale if needed
        if (harness.appRef.read(localePreferenceProvider) != LocalePreference.english) {
          await harness.appRef.read(localePreferenceProvider.notifier).set(LocalePreference.english);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
        }
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
        await tester.runAsync(harness.appRef.read(telemetryRecorderControllerProvider).drainFinalization);
        await tester.pump(const Duration(milliseconds: 100));

        // Disconnect session per safety architecture so history is permitted
        await tester.runAsync(harness.appRef.read(obdSessionProvider.notifier).disconnect);
        await tester.pump();
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

        // Tap formal UI reload button on TelemetrySessionsScreen to refresh
        final reloadBtn = find.byIcon(Icons.refresh);
        if (reloadBtn.evaluate().isNotEmpty) {
          await tester.tap(reloadBtn);
          await tester.pump();
        }

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

        // Verify localized offline sampled replay header in English
        final replayLoadedEn = await harness.pumpUntil(
          tester,
          () => find.text(en.telemetryOfflineSampledReplay).evaluate().isNotEmpty,
          timeout: const Duration(seconds: 15),
        );
        expect(replayLoadedEn, isTrue, reason: 'Replay header text never rendered for English');

        // Dynamically switch to Traditional Chinese and verify localized header re-renders
        await harness.appRef.read(localePreferenceProvider.notifier).set(LocalePreference.traditionalChinese);
        await tester.pumpAndSettle();
        expect(find.text(zh.telemetryOfflineSampledReplay), findsOneWidget);
        expect(find.text(en.telemetryOfflineSampledReplay), findsNothing);

        // Switch back to English
        await harness.appRef.read(localePreferenceProvider.notifier).set(LocalePreference.english);
        await tester.pumpAndSettle();
        expect(find.text(en.telemetryOfflineSampledReplay), findsOneWidget);
        expect(find.text(zh.telemetryOfflineSampledReplay), findsNothing);
      },
    );

    testWidgets(
      '[C04] Export/Cancel/Reopen: real UI export CSV and JSON, byte-identical canonical contents, gate settles, reopen same session',
      (tester) async {
        // The production export worker has a 15-second graceful-exit budget
        // followed by a 5-second forced-exit budget. Subscribe to the actual
        // platform handoff before each tap instead of racing that protocol
        // with a fixed 15-second polling window under concurrent CI load.
        const dispatchWait = Duration(seconds: 45);

        Future<void> awaitDispatchAndGateSettlement(
          Future<AppSharePlatformRequest> dispatch,
          int expectedRequestCount,
          String label,
        ) async {
          var dispatchCompleted = false;
          Object? dispatchFailure;
          StackTrace? dispatchStackTrace;
          final trackedDispatch = dispatch.then<void>(
            (_) => dispatchCompleted = true,
            onError: (Object error, StackTrace stackTrace) {
              dispatchFailure = error;
              dispatchStackTrace = stackTrace;
              dispatchCompleted = true;
            },
          );
          final observed = await harness.pumpUntil(
            tester,
            () => dispatchCompleted,
            // L10nRootHarness.pumpUntil uses a real DateTime deadline while
            // still pumping widget frames. Do not add Future.timeout here:
            // its timer would run on the Flutter test FakeAsync clock.
            timeout: dispatchWait,
          );
          expect(observed, isTrue, reason: '$label platform dispatch was not observed');
          await trackedDispatch;
          if (dispatchFailure != null) {
            Error.throwWithStackTrace(dispatchFailure!, dispatchStackTrace!);
          }
          final settled = await harness.pumpUntil(
            tester,
            () => harness.appRef.read(artifactOperationGateProvider).snapshot.isIdle,
          );
          expect(settled, isTrue, reason: '$label artifact gate did not settle');
          expect(
            harness.sharePlatform.requests.length,
            equals(expectedRequestCount),
            reason: '$label must produce exactly one additional dispatch',
          );
        }

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
        await tester.runAsync(harness.appRef.read(telemetryRecorderControllerProvider).drainFinalization);
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

        expect(find.byType(TelemetrySessionsScreen), findsOneWidget);

        // Tap formal UI refresh button
        final reloadBtn = find.byIcon(Icons.refresh);
        if (reloadBtn.evaluate().isNotEmpty) {
          await tester.tap(reloadBtn);
          await tester.pump();
        }

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
          timeout: const Duration(seconds: 15),
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

        final initialRequests = harness.sharePlatform.requests.length;

        // 1. Cancel flow: tap Export, sheet opens, cancel/dismiss, verify 0 dispatches and gate stays idle
        await tester.tap(exportBtn);
        await harness.pumpUntil(
          tester,
          () => find.byType(TelemetryExportSheet).evaluate().isNotEmpty,
        );
        expect(find.byType(TelemetryExportSheet), findsOneWidget);
        Navigator.of(tester.element(find.byType(TelemetryExportSheet))).pop();
        await tester.pumpAndSettle();
        expect(find.byType(TelemetryExportSheet), findsNothing);
        expect(harness.sharePlatform.requests.length, equals(initialRequests), reason: 'Cancel must produce zero dispatches');
        expect(harness.appRef.read(artifactOperationGateProvider).snapshot.isIdle, isTrue);

        // 2. CSV Export flow: tap Export again
        await tester.tap(exportBtn);
        await harness.pumpUntil(
          tester,
          () => find.byType(TelemetryExportSheet).evaluate().isNotEmpty,
        );
        final csvBtn = find.text(en.telemetryExportCsv);
        final csvHitTestable = await harness.pumpUntil(
          tester,
          () => csvBtn.hitTestable().evaluate().isNotEmpty,
          timeout: const Duration(seconds: 4),
        );
        expect(csvHitTestable, isTrue, reason: 'CSV button never hit testable');
        final csvDispatch = harness.sharePlatform.nextRequest;
        await tester.tap(csvBtn);
        await tester.pump();

        await awaitDispatchAndGateSettlement(csvDispatch, initialRequests + 1, 'CSV export');
        final csvRequest = harness.sharePlatform.requests.last;
        expect(csvRequest.mimeType, contains('csv'));
        expect(File(csvRequest.path).existsSync(), isTrue);
        final csvBytesEn = File(csvRequest.path).readAsBytesSync();
        final csvContentEn = utf8.decode(csvBytesEn);
        expect(csvContentEn, contains('timestamp_utc'));

        // 3. JSON Export flow: tap Export again once bottom sheet dismissed
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
        final jsonDispatch = harness.sharePlatform.nextRequest;
        await tester.tap(jsonBtn);
        await tester.pump();

        await awaitDispatchAndGateSettlement(jsonDispatch, initialRequests + 2, 'JSON export');
        final jsonRequest = harness.sharePlatform.requests.last;
        expect(jsonRequest.mimeType, contains('json'));
        expect(File(jsonRequest.path).existsSync(), isTrue);
        final jsonBytes = File(jsonRequest.path).readAsBytesSync();
        final jsonMap = jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
        expect(jsonMap.isNotEmpty, isTrue);
        expect(jsonMap.containsKey('exportVersion'), isTrue);
        expect(jsonMap.containsKey('events'), isTrue);
        expect(jsonMap['events'], isA<List<dynamic>>());
        final eventsList = jsonMap['events'] as List<dynamic>;
        expect(eventsList, isNotEmpty);
        final firstEvent = eventsList.first as Map<String, dynamic>;
        expect(firstEvent.containsKey('type'), isTrue);
        expect(firstEvent.containsKey('observedAtUtc'), isTrue);
        expect(firstEvent.containsKey('elapsedUs'), isTrue);

        // Ensure previous export sheet is completely dismissed
        await harness.pumpUntil(
          tester,
          () => find.byType(TelemetryExportSheet).evaluate().isEmpty,
          timeout: const Duration(seconds: 4),
        );

        // Advance virtual share clock past lease retention (15 min) so completed staging cache purges
        harness.advanceShareClock();

        // 4. Cross-locale canonical verification: switch to Traditional Chinese, export CSV, assert byte-identical
        await harness.appRef.read(localePreferenceProvider.notifier).set(LocalePreference.traditionalChinese);
        await tester.pumpAndSettle();

        final exportBtnZh = find.widgetWithText(FilledButton, zh.telemetryExport);
        await tester.scrollUntilVisible(
          exportBtnZh,
          200,
          scrollable: find.descendant(
            of: find.byType(TelemetrySessionDetailScreen),
            matching: find.byType(Scrollable),
          ).first,
        );
        expect(exportBtnZh, findsOneWidget);
        await tester.tap(exportBtnZh);
        final sheetFoundZh = await harness.pumpUntil(
          tester,
          () => find.byType(TelemetryExportSheet).evaluate().isNotEmpty,
          timeout: const Duration(seconds: 4),
        );
        expect(sheetFoundZh, isTrue, reason: 'Export sheet never appeared for Chinese CSV');
        final csvBtnZh = find.text(zh.telemetryExportCsv);
        final csvHitTestableZh = await harness.pumpUntil(
          tester,
          () => csvBtnZh.hitTestable().evaluate().isNotEmpty,
          timeout: const Duration(seconds: 4),
        );
        expect(csvHitTestableZh, isTrue, reason: 'Chinese CSV button never hit testable');
        final csvDispatchZh = harness.sharePlatform.nextRequest;
        await tester.tap(csvBtnZh);
        await tester.pump();

        await awaitDispatchAndGateSettlement(csvDispatchZh, initialRequests + 3, 'Chinese CSV export');
        final csvRequestZh = harness.sharePlatform.requests.last;
        final csvBytesZh = File(csvRequestZh.path).readAsBytesSync();
        expect(csvBytesZh, equals(csvBytesEn), reason: 'Canonical CSV export must be byte-identical across locales');

        // Advance share clock for Chinese JSON export
        harness.advanceShareClock();

        final exportBtnHitTestableZh = await harness.pumpUntil(
          tester,
          () => exportBtnZh.hitTestable().evaluate().isNotEmpty,
          timeout: const Duration(seconds: 4),
        );
        expect(exportBtnHitTestableZh, isTrue);
        await tester.tap(exportBtnZh);
        await tester.pump();
        final sheetFoundZhJson = await harness.pumpUntil(
          tester,
          () => find.byType(TelemetryExportSheet).evaluate().isNotEmpty,
          timeout: const Duration(seconds: 4),
        );
        expect(sheetFoundZhJson, isTrue);
        final jsonBtnZh = find.text(zh.telemetryExportJson);
        final jsonHitTestableZh = await harness.pumpUntil(
          tester,
          () => jsonBtnZh.hitTestable().evaluate().isNotEmpty,
          timeout: const Duration(seconds: 4),
        );
        expect(jsonHitTestableZh, isTrue);
        final jsonDispatchZh = harness.sharePlatform.nextRequest;
        await tester.tap(jsonBtnZh);
        await tester.pump();

        await awaitDispatchAndGateSettlement(jsonDispatchZh, initialRequests + 4, 'Chinese JSON export');
        final jsonRequestZh = harness.sharePlatform.requests.last;
        final jsonBytesZh = File(jsonRequestZh.path).readAsBytesSync();
        expect(jsonBytesZh, equals(jsonBytes), reason: 'Canonical JSON export must be byte-identical across locales');

        // Switch back to English
        await harness.appRef.read(localePreferenceProvider.notifier).set(LocalePreference.english);
        await tester.pumpAndSettle();

        // 5. Pop back to Sessions list and reopen
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
        expect(harness.appRef.read(artifactOperationGateProvider).snapshot.isIdle, isTrue);

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

        for (final targetLocale in [englishLocale, traditionalChineseLocale]) {
          final loc = lookupAppLocalizations(targetLocale);
          final targetPref = targetLocale == englishLocale
              ? LocalePreference.english
              : LocalePreference.traditionalChinese;
          if (harness.appRef.read(localePreferenceProvider) != targetPref) {
            await harness.appRef.read(localePreferenceProvider.notifier).set(targetPref);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 200));
          }

          await connectDemoViaUi(tester, locale: targetLocale);
          expect(find.byType(DashboardScreen), findsOneWidget);

          // Positive control: verify DemoTransport actively transmitted wire writes while connected
          final clientPre = harness.appRef.read(obdSessionProvider.notifier).client;
          expect(clientPre, isNotNull, reason: 'Client must be non-null while session is connected ($targetLocale)');
          final writesPre = clientPre!.transcript.entries
              .where((e) => e.direction == TranscriptDirection.out)
              .length;
          expect(writesPre, greaterThan(0), reason: 'Demo session must have produced wire writes ($targetLocale)');

          // Positive control: verify CountingBlePlatform observes transport scans
          final preControlScans = harness.blePlatform.scanCount;
          await UniversalBle.startScan();
          expect(harness.blePlatform.scanCount, equals(preControlScans + 1));

          // Navigate to Settings
          final settingsNav = find.byIcon(Icons.settings_outlined);
          expect(settingsNav, findsOneWidget);
          await tester.tap(settingsNav);
          await tester.pumpAndSettle();
          expect(find.byType(SettingsScreen), findsOneWidget);

          // Find the actual localized Disconnect button on SettingsScreen
          final disconnectBtn = find.text(loc.settingsDisconnect);
          await tester.scrollUntilVisible(
            disconnectBtn,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(disconnectBtn, findsOneWidget);

          // Tap Disconnect
          await tester.tap(disconnectBtn);
          await tester.pump();

          // Await session disconnect settlement to exact disconnected phase
          final disconnected = await harness.pumpUntil(
            tester,
            () => harness.appRef.read(obdSessionProvider).phase == ConnectionPhase.disconnected,
          );
          expect(disconnected, isTrue, reason: 'Session did not transition to exact disconnected phase ($targetLocale)');
          expect(harness.appRef.read(obdSessionProvider).isConnected, isFalse);
          expect(harness.appRef.read(obdSessionProvider).isBusy, isFalse);
          expect(harness.appRef.read(obdSessionProvider.notifier).client, isNull,
              reason: 'Elm327Client must be disposed and cleared on disconnect ($targetLocale)');
          final frozenTranscript = harness.appRef.read(obdSessionProvider.notifier).exportableTranscript;
          expect(frozenTranscript, isNotNull, reason: 'Historical transcript preserved after disconnect ($targetLocale)');
          final frozenRecordedCount = frozenTranscript!.recorded;
          await tester.pumpAndSettle();

          // Verify app routed back to ConnectScreen
          expect(find.byType(ConnectScreen), findsOneWidget);

          // Check zero subsequent Bluetooth or vehicle transport dispatch after disconnection
          final scanCountPost = harness.blePlatform.scanCount;
          final connectCountPost = harness.blePlatform.connectCount;
          final sendCountPost = harness.blePlatform.sendCount;
          await tester.pump(const Duration(milliseconds: 500));
          expect(harness.blePlatform.scanCount, equals(scanCountPost));
          expect(harness.blePlatform.connectCount, equals(connectCountPost));
          expect(harness.blePlatform.sendCount, equals(sendCountPost));
          expect(
            harness.appRef.read(obdSessionProvider.notifier).exportableTranscript?.recorded,
            equals(frozenRecordedCount),
            reason: 'Transport transcript must remain frozen with zero post-disconnect writes ($targetLocale)',
          );
        }

        // Restore English locale
        if (harness.appRef.read(localePreferenceProvider) != LocalePreference.english) {
          await harness.appRef.read(localePreferenceProvider.notifier).set(LocalePreference.english);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
        }
      },
    );

    testWidgets(
      '[C06] Permission and transport failure: refusal reasons rendered, stored failure does not re-prompt',
      (tester) async {
        var permissionPromptCount = 0;
        testEnsureBluetoothPermissionsOverride = ({required forScanning}) async {
          permissionPromptCount++;
          return const BlePermissionResult.refused(
            BlePermissionOutcome.denied,
            BlePermissionKind.location,
          );
        };
        addTearDown(() => testEnsureBluetoothPermissionsOverride = null);

        await harness.pumpApp(tester);

        // Expand Bluetooth LE panel
        final bleTile = find.text(transportKindTitle(en, TransportKind.bluetoothLe));
        await tester.ensureVisible(bleTile);
        await tester.tap(bleTile);
        await tester.pumpAndSettle();

        // Tap scan button to trigger scan with permission check
        final scanBtn = find.widgetWithText(FilledButton, en.connectBleScan);
        await tester.ensureVisible(scanBtn);
        await tester.tap(scanBtn);
        await tester.pumpAndSettle();

        const expectedEnError = 'Scanning needs Location permission';
        const expectedZhError = '需要位置權限才能掃描';

        // Verify English permission denial error copy is displayed
        expect(find.text(expectedEnError), findsOneWidget);
        expect(permissionPromptCount, equals(1));

        // Reset counts to verify switching language introduces 0 new prompts/scans
        permissionPromptCount = 0;
        harness.blePlatform.scanCount = 0;

        // Switch to Traditional Chinese
        await harness.appRef.read(localePreferenceProvider.notifier).set(LocalePreference.traditionalChinese);
        await tester.pumpAndSettle();

        // The error message dynamically re-renders in Traditional Chinese
        expect(find.text(expectedZhError), findsOneWidget);
        expect(find.text(expectedEnError), findsNothing);
        expect(permissionPromptCount, equals(0));
        expect(harness.blePlatform.scanCount, equals(0));

        // Switch back to English
        await harness.appRef.read(localePreferenceProvider.notifier).set(LocalePreference.english);
        await tester.pumpAndSettle();

        expect(find.text(expectedEnError), findsOneWidget);
        expect(find.text(expectedZhError), findsNothing);
        expect(permissionPromptCount, equals(0));
        expect(harness.blePlatform.scanCount, equals(0));
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

        // Verify language switch is strictly and automatically blocked during recording (no manual invalidation)
        expect(
          harness.appRef.read(languageSwitchBlockProvider),
          equals(LanguageSwitchBlock.recording),
          reason: 'Language switch must be blocked while recording is active',
        );

        // Navigate to formal SettingsScreen where LanguagePicker is published
        final settingsNav = find.byIcon(Icons.settings_outlined);
        expect(settingsNav, findsOneWidget);
        await tester.tap(settingsNav);
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsOneWidget);

        final langPicker = find.byType(LanguagePicker);
        await tester.scrollUntilVisible(
          langPicker,
          300,
          scrollable: find.descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          ).first,
        );
        expect(langPicker, findsOneWidget);

        // Tap Traditional Chinese radio in formal Settings LanguagePicker
        final zhRadio = find.byKey(const Key('locale_traditionalChinese'));
        await tester.scrollUntilVisible(
          zhRadio,
          100,
          scrollable: find.descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          ).first,
        );
        await tester.ensureVisible(zhRadio);
        await tester.pumpAndSettle();
        expect(zhRadio, findsOneWidget);
        await tester.tap(zhRadio);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify language switch was blocked: preference unchanged and SnackBar feedback shown
        expect(harness.appRef.read(localePreferenceProvider), equals(LocalePreference.english));
        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.text(en.telemetryBlockedByRecorder),
          ),
          findsOneWidget,
        );

        // Navigate back to Dashboard to stop recording
        final dashNav = find.byIcon(Icons.speed_outlined);
        await tester.tap(dashNav);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(DashboardScreen), findsOneWidget);

        // Stop recording
        final stopBtn = find.byKey(const ValueKey('telemetry-stop'));
        await Scrollable.ensureVisible(tester.element(stopBtn));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(stopBtn);
        await harness.pumpUntil(
          tester,
          () => harness.appRef.read(telemetryRecorderProgressProvider).state.phase == TelemetryRecorderPhase.completed,
        );
        await tester.runAsync(harness.appRef.read(telemetryRecorderControllerProvider).drainFinalization);
        await tester.pump(const Duration(milliseconds: 100));

        // Verify automatically unblocked after recording completes (NO manual invalidation!)
        expect(
          harness.appRef.read(languageSwitchBlockProvider),
          equals(LanguageSwitchBlock.none),
          reason: 'Language switch must be unblocked after recording completes',
        );

        // Navigate back to SettingsScreen
        await tester.tap(settingsNav);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(SettingsScreen), findsOneWidget);

        await tester.scrollUntilVisible(
          zhRadio,
          300,
          scrollable: find.descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          ).first,
        );
        await tester.ensureVisible(zhRadio);
        await tester.pumpAndSettle();

        // Test artifact-busy block: acquire gate token
        final acquireResult = harness.artifactGate.tryAcquire('test-busy-artifact', ArtifactOperation.export);
        expect(acquireResult.acquired, isTrue);

        // Automatically blocked due to active artifact gate notification (NO manual invalidation!)
        await tester.pump();
        expect(
          harness.appRef.read(languageSwitchBlockProvider),
          equals(LanguageSwitchBlock.artifactBusy),
          reason: 'Language switch must be blocked during active artifact operation',
        );

        // Attempt real UI language switch while artifact-busy on SettingsScreen
        await tester.tap(zhRadio);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(harness.appRef.read(localePreferenceProvider), equals(LocalePreference.english));
        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.text(en.telemetryBlockedByRecorder),
          ),
          findsOneWidget,
        );

        // Release token and verify automatically unblocked (NO manual invalidation!)
        harness.artifactGate.release(acquireResult.token!);
        await tester.pump();
        expect(
          harness.appRef.read(languageSwitchBlockProvider),
          equals(LanguageSwitchBlock.none),
          reason: 'Language switch must be automatically unblocked after artifact release',
        );

        // Verify language switch succeeds when idle on SettingsScreen
        await tester.tap(zhRadio);
        await tester.pumpAndSettle();
        expect(harness.appRef.read(localePreferenceProvider), equals(LocalePreference.traditionalChinese));

        // Switch back to English
        final enRadio = find.byKey(const Key('locale_english'));
        await tester.scrollUntilVisible(
          enRadio,
          100,
          scrollable: find.descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          ).first,
        );
        await tester.ensureVisible(enRadio);
        await tester.pumpAndSettle();
        await tester.tap(enRadio);
        await tester.pumpAndSettle();
        expect(harness.appRef.read(localePreferenceProvider), equals(LocalePreference.english));

        // Clean up: disconnect session
        await tester.runAsync(harness.appRef.read(obdSessionProvider.notifier).disconnect);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '[C08] Late result/route/dispose: covered-success and route currentness protect owner and feedback',
      (tester) async {
        final actionBarrier = _TestBarrier();
        var armBarrier = false;
        Future<Directory> captureDirWithBarrier() async {
          if (armBarrier) {
            if (!actionBarrier.entered.isCompleted) {
              actionBarrier.entered.complete();
            }
            await actionBarrier.release.future;
          }
          return harness.tempShareDir;
        }

        // Set rootDirectoryOverride on harness directly (no duplicate provider override!)
        harness.shareRootDirectoryOverride = captureDirWithBarrier;
        await harness.pumpApp(tester);

        // 1. Connect and record a real session so history has an entry
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
        expect(canStart, isTrue);

        await tester.tap(find.byKey(const ValueKey('telemetry-start')));
        await harness.pumpUntil(
          tester,
          () => harness.appRef.read(telemetryRecorderProgressProvider).state.valueCount > 0,
        );
        final sessionId = harness.appRef.read(telemetryRecorderProgressProvider).sessionId!;

        final stopBtn = find.byKey(const ValueKey('telemetry-stop'));
        await Scrollable.ensureVisible(tester.element(stopBtn));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(stopBtn);
        await harness.pumpUntil(
          tester,
          () => harness.appRef.read(telemetryRecorderProgressProvider).state.phase == TelemetryRecorderPhase.completed,
        );
        await tester.runAsync(harness.appRef.read(telemetryRecorderControllerProvider).drainFinalization);
        await tester.pump(const Duration(milliseconds: 100));

        // Disconnect session
        await tester.runAsync(harness.appRef.read(obdSessionProvider.notifier).disconnect);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Open history
        final historyBtn = find.byKey(const ValueKey('telemetry-open-history'));
        await Scrollable.ensureVisible(tester.element(historyBtn));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(historyBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(TelemetrySessionsScreen), findsOneWidget);

        // Reload sessions
        final reloadBtn = find.byIcon(Icons.refresh);
        if (reloadBtn.evaluate().isNotEmpty) {
          await tester.tap(reloadBtn);
          await tester.pump();
        }

        // Open session detail
        final sessionTile = find.byKey(ValueKey('telemetry-session-tile-$sessionId'));
        final foundTile = await harness.pumpUntil(
          tester,
          () => sessionTile.evaluate().isNotEmpty,
          timeout: const Duration(seconds: 10),
        );
        expect(foundTile, isTrue);
        await Scrollable.ensureVisible(tester.element(sessionTile));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(sessionTile);
        await harness.pumpUntil(
          tester,
          () => find.byType(TelemetrySessionDetailScreen).evaluate().isNotEmpty,
          timeout: const Duration(seconds: 15),
        );
        expect(find.byType(TelemetrySessionDetailScreen), findsOneWidget);

        // Wait for replay body to load so scrollable is present
        final replayLoaded = await harness.pumpUntil(
          tester,
          () => find.text(en.telemetryOfflineSampledReplay).evaluate().isNotEmpty,
          timeout: const Duration(seconds: 15),
        );
        expect(replayLoaded, isTrue, reason: 'Replay body never loaded');

        // Scroll until export button is visible
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

        // 1. Positive control: controlled typed failure on current route triggers localized SnackBar
        harness.sharePlatform.nextResult = AppShareResult.unavailable;
        await tester.tap(exportBtn);
        await harness.pumpUntil(
          tester,
          () => find.byType(TelemetryExportSheet).evaluate().isNotEmpty,
        );
        final csvBtnControl = find.text(en.telemetryExportCsv);
        await harness.pumpUntil(
          tester,
          () => csvBtnControl.hitTestable().evaluate().isNotEmpty,
        );
        await tester.tap(csvBtnControl);
        await tester.pump();

        // Await failure settlement: gate settles to idle
        final controlSettled = await harness.pumpUntil(
          tester,
          () => harness.appRef.read(artifactOperationGateProvider).snapshot.isIdle,
          timeout: const Duration(seconds: 15),
        );
        expect(controlSettled, isTrue, reason: 'Gate never settled after controlled failure');
        await tester.pump(const Duration(milliseconds: 300));

        // Positive control assertions: SnackBar IS rendered for failure on current route
        expect(find.byType(SnackBar), findsOneWidget, reason: 'Current route must display SnackBar on export failure');
        expect(find.byType(TelemetrySessionActionFeedback), findsOneWidget);
        expect(find.text(en.telemetryExportFailed(en.shareHandoffFailed)), findsOneWidget);

        // Dismiss the SnackBar before moving to the late-result contrast
        ScaffoldMessenger.of(tester.element(find.byType(TelemetrySessionDetailScreen))).hideCurrentSnackBar();
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);

        // 2. Contrast: identical controlled typed failure arriving late on covered/disposed route suppresses SnackBar
        harness.sharePlatform.nextResult = AppShareResult.unavailable;
        final exportBtnHitTestable = await harness.pumpUntil(
          tester,
          () => exportBtn.hitTestable().evaluate().isNotEmpty,
          timeout: const Duration(seconds: 4),
        );
        expect(exportBtnHitTestable, isTrue);
        await tester.tap(exportBtn);
        await harness.pumpUntil(
          tester,
          () => find.byType(TelemetryExportSheet).evaluate().isNotEmpty,
        );
        final csvBtn = find.text(en.telemetryExportCsv);
        await harness.pumpUntil(
          tester,
          () => csvBtn.hitTestable().evaluate().isNotEmpty,
        );
        armBarrier = true;
        await tester.tap(csvBtn);
        await tester.pump();

        // Wait for action to enter barrier (action-in-flight confirmation)
        await actionBarrier.entered.future.timeout(const Duration(seconds: 15));
        expect(harness.appRef.read(artifactOperationGateProvider).snapshot.isIdle, isFalse,
            reason: 'Gate must be busy while export action is in-flight');

        // Navigate away to ConnectScreen while action is in-flight (route change / cover)
        final router = GoRouter.of(tester.element(find.byType(TelemetrySessionDetailScreen)));
        router.go(ConnectScreen.path);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(ConnectScreen), findsOneWidget);
        expect(find.byType(TelemetrySessionDetailScreen), findsNothing);

        // Release barrier to allow late result to arrive
        actionBarrier.release.complete();

        // Wait for terminal settlement
        final gateSettled = await harness.pumpUntil(
          tester,
          () => harness.appRef.read(artifactOperationGateProvider).snapshot.isIdle,
          timeout: const Duration(seconds: 10),
        );
        expect(gateSettled, isTrue, reason: 'Artifact gate never settled to idle');
        await tester.pump(const Duration(milliseconds: 300));

        // Contrast assertion: The exact same typed failure that displayed a SnackBar on the current route
        // is now cleanly suppressed because the originating route is covered/disposed!
        expect(find.byType(ConnectScreen), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing,
            reason: 'Late action result must NOT show SnackBar on wrong route');
        expect(harness.appRef.read(artifactOperationGateProvider).snapshot.isIdle, isTrue);
      },
    );
  });
}
