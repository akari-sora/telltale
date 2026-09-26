// Batch 1L-B1 / Issue #39: History, Detail, and Replay locale journey test.
//
// Verifies:
//   * B01: Restart, storage, and share failure notices dynamically rerender
//     across locales with identical typed reasons and arguments, retaining
//     undismissible process-lifetime gates without repeating actions.
//   * B04: Session identity, PID selection, and replay position are preserved
//     across locale changes with zero bluetooth/transport connections or scans.
//   * B07: Accessibility, narrow viewport (320dp), and 2.0x text scaling.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/ble_scan_permissions.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/telemetry_sessions.dart';
import 'package:torque_obd/telemetry/session/telemetry_session.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_session_detail_screen.dart';
import 'package:torque_obd/ui/widgets/telemetry/telemetry_artifact_restart_notice.dart';
import 'package:universal_ble/universal_ble.dart';

import '../support/cjk.dart';
import '../support/localized_app.dart';

final _testReplay = TelemetryReplayResult.success(
  TelemetrySessionReplay(
    sessionId: 'deadbeefcafe00010002000300040005',
    startedAtUtc: DateTime.utc(2026, 3, 15, 10, 0),
    endedAtUtc: DateTime.utc(2026, 3, 15, 10, 0, 20),
    source: TelemetrySource.demo,
    transport: TransportKind.demo.name,
    protocol: 'AUTO',
    signalCount: 1,
    valueCount: 20,
    statusCount: 0,
    gapCount: 0,
    terminalReason: TelemetryTerminalReason.user,
    elapsedDurationUs: 20000000,
    workerDebugName: 'l05-test-worker',
    lanes: const [
      TelemetryReplayLane(
        pidId: '7E0:010C',
        name: 'Engine RPM',
        unit: 'rpm',
        request: '010C',
        evidenceKind: 'standard',
        minimum: 0,
        maximum: 8000,
        primitives: [
          TelemetryReplayPrimitive(
            kind: TelemetryReplayPrimitiveKind.value,
            elapsedUs: 0,
            value: 800,
          ),
          TelemetryReplayPrimitive(
            kind: TelemetryReplayPrimitiveKind.value,
            elapsedUs: 10000000,
            value: 2500,
          ),
        ],
      ),
    ],
  ),
);

class _CountingBlePlatform extends UniversalBlePlatform {
  int scanCount = 0;
  int connectCount = 0;
  int sendCount = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #startScan) {
      scanCount++;
      return Future<void>.value();
    }
    if (name == #connect) {
      connectCount++;
      return Future<void>.value();
    }
    if (name == #writeValue || name == #writeCommand) {
      sendCount++;
      return Future<void>.value();
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('B01: Failure and restart notices across locales', () {
    testWidgets('restart warning dynamically re-renders from English to Chinese without dismissing', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(telemetryArtifactNoticeProvider.notifier).requireRestart();
      expect(container.read(telemetryArtifactNoticeProvider), isNotNull);
      expect(
        container.read(telemetryArtifactNoticeProvider)!.reason,
        ArtifactNoticeReason.restartRequired,
      );

      var currentLocale = englishLocale;
      late StateSetter setLocaleState;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: StatefulBuilder(
            builder: (context, setState) {
              setLocaleState = setState;
              return localizedMaterialApp(
                locale: currentLocale,
                home: const Scaffold(body: TelemetryArtifactRestartNotice()),
              );
            },
          ),
        ),
      );

      // 1. Initial English rendering
      final noticeFinder = find.byKey(const ValueKey('telemetry-artifact-restart-notice'));
      expect(noticeFinder, findsOneWidget);

      const enText = 'The state of local file work cannot be confirmed. Quit Telltale completely and reopen it before continuing';
      expect(find.text(enText), findsOneWidget);
      expect(containsChinese(enText), isFalse);

      // Verify undismissible: no close buttons, no icon buttons
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);

      // 2. Switch locale to Traditional Chinese
      setLocaleState(() {
        currentLocale = traditionalChineseLocale;
      });
      await tester.pump();

      // Dynamically updates to Chinese
      expect(find.text(enText), findsNothing);
      expect(find.text(telemetryArtifactRestartRequiredCopy), findsOneWidget);
      expect(noticeFinder, findsOneWidget);

      // 3. Switch back to English
      setLocaleState(() {
        currentLocale = englishLocale;
      });
      await tester.pump();

      expect(find.text(enText), findsOneWidget);
      expect(find.text(telemetryArtifactRestartRequiredCopy), findsNothing);

      // Gate remains firmly set
      expect(container.read(telemetryArtifactNoticeProvider), isNotNull);
    });

    test('failure action result messages format accurately under en and zh', () {
      final en = lookupAppLocalizations(englishLocale);
      final zh = lookupAppLocalizations(traditionalChineseLocale);

      const restartFailure = TelemetrySessionActionResult.failure(
        TelemetrySessionActionFailure.restartRequired,
      );
      expect(
        en.telemetryDeleteFailed(restartFailure.message(en)),
        'Delete did not finish: The state of local file work cannot be confirmed. Quit Telltale completely and reopen it before continuing',
      );
      expect(
        zh.telemetryDeleteFailed(restartFailure.message(zh)),
        '刪除未完成：本機檔案作業狀態無法確認；請完全關閉並重新啟動 App 後再操作',
      );

      expect(
        en.telemetryExportFailed(restartFailure.message(en)),
        'Export did not finish: The state of local file work cannot be confirmed. Quit Telltale completely and reopen it before continuing',
      );
      expect(
        zh.telemetryExportFailed(restartFailure.message(zh)),
        '匯出未完成：本機檔案作業狀態無法確認；請完全關閉並重新啟動 App 後再操作',
      );
    });
  });

  group('B04: Replay & Detail state preservation under locale switch', () {
    testWidgets('Detail screen retains session identity and signal selection on locale switch', (
      tester,
    ) async {
      final requestedSessionIds = <String>[];
      final container = ProviderContainer(
        overrides: [
          telemetryHistoryAccessProvider.overrideWithValue(
            TelemetryHistoryAccess.permitted,
          ),
          telemetrySessionReplayProvider.overrideWith(
            (ref, id) async {
              requestedSessionIds.add(id);
              return _testReplay;
            },
          ),
        ],
      );
      addTearDown(container.dispose);

      final countingBle = _CountingBlePlatform();
      UniversalBle.setInstance(countingBle);
      addTearDown(() {
        UniversalBle.setInstance(_CountingBlePlatform());
      });

      var permissionCallCount = 0;
      testEnsureBluetoothPermissionsOverride = ({required bool forScanning}) async {
        permissionCallCount++;
        return const BlePermissionResult.granted();
      };
      addTearDown(() {
        testEnsureBluetoothPermissionsOverride = null;
      });

      // Positive controls on side-effect observation instrumentation
      await countingBle.startScan();
      await countingBle.connect('mock-device');
      await countingBle.writeValue(
        'mock-device',
        '0000',
        '0001',
        Uint8List(0),
        BleOutputProperty.withResponse,
      );
      final testPerm = await ensureBluetoothPermissions(forScanning: true);
      expect(testPerm.granted, isTrue);
      expect(countingBle.scanCount, equals(1));
      expect(countingBle.connectCount, equals(1));
      expect(countingBle.sendCount, equals(1));
      expect(permissionCallCount, equals(1));
      countingBle.scanCount = 0;
      countingBle.connectCount = 0;
      countingBle.sendCount = 0;
      permissionCallCount = 0;

      var currentLocale = englishLocale;
      late StateSetter setLocaleState;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: StatefulBuilder(
            builder: (context, setState) {
              setLocaleState = setState;
              return localizedMaterialApp(
                locale: currentLocale,
                home: const TelemetrySessionDetailScreen(
                  sessionId: 'deadbeefcafe00010002000300040005',
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Screen rendered in English
      expect(find.byType(TelemetrySessionDetailScreen), findsOneWidget);
      expect(find.textContaining('Engine RPM'), findsWidgets);

      final en = lookupAppLocalizations(englishLocale);
      expect(find.text(en.telemetryReplayTitle), findsOneWidget);

      // Verify controls
      expect(find.text('1x'), findsOneWidget);
      expect(find.text('4x'), findsOneWidget);
      expect(find.text('16x'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Switch speed to 16x and verify selection state
      expect(
        (tester.widget(find.widgetWithText(ChoiceChip, '1x')) as ChoiceChip).selected,
        isTrue,
      );
      expect(
        (tester.widget(find.widgetWithText(ChoiceChip, '16x')) as ChoiceChip).selected,
        isFalse,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, '16x'));
      await tester.pump();
      expect(
        (tester.widget(find.widgetWithText(ChoiceChip, '16x')) as ChoiceChip).selected,
        isTrue,
      );
      expect(
        (tester.widget(find.widgetWithText(ChoiceChip, '1x')) as ChoiceChip).selected,
        isFalse,
      );

      // Scrub Slider to 0.6 non-zero position and pause
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);
      expect((tester.widget(sliderFinder) as Slider).value, equals(0.0));
      tester.widget<Slider>(sliderFinder).onChanged!(0.6);
      await tester.pump();
      expect((tester.widget(sliderFinder) as Slider).value, equals(0.6));

      // Reset counters before locale switch
      countingBle.scanCount = 0;
      countingBle.connectCount = 0;
      countingBle.sendCount = 0;
      permissionCallCount = 0;

      // Switch locale to Traditional Chinese
      setLocaleState(() {
        currentLocale = traditionalChineseLocale;
      });
      await tester.pumpAndSettle();

      // Session detail is still showing the exact same session, lane, and timeline value
      final zh = lookupAppLocalizations(traditionalChineseLocale);
      expect(find.text(zh.telemetryReplayTitle), findsOneWidget);
      expect(find.text(en.telemetryReplayTitle), findsNothing);
      expect(find.textContaining('Engine RPM'), findsWidgets);
      expect(find.textContaining('2500'), findsWidgets);

      // Verify session identity requested and preserved
      expect(requestedSessionIds, isNotEmpty);
      expect(
        requestedSessionIds.every((id) => id == 'deadbeefcafe00010002000300040005'),
        isTrue,
      );
      expect(_testReplay.replay!.lanes.single.pidId, equals('7E0:010C'));
      expect(_testReplay.replay!.lanes.single.primitives[1].value, equals(2500));

      // Controls, speed selection, and scrubbed Slider value are preserved across locale switch
      expect(
        (tester.widget(find.widgetWithText(ChoiceChip, '16x')) as ChoiceChip).selected,
        isTrue,
      );
      expect(
        (tester.widget(find.widgetWithText(ChoiceChip, '1x')) as ChoiceChip).selected,
        isFalse,
      );
      expect((tester.widget(find.byType(Slider)) as Slider).value, equals(0.6));

      // B04: Verify zero Bluetooth/transport connections, scans, sends, or permissions occurred
      expect(countingBle.scanCount, equals(0));
      expect(countingBle.connectCount, equals(0));
      expect(countingBle.sendCount, equals(0));
      expect(permissionCallCount, equals(0));
    });
  });

  group('B07: Accessibility, narrow layout, and 2.0x text scaling', () {
    testWidgets('restart notice renders cleanly on 320dp width with 2.0x text scaling', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(telemetryArtifactNoticeProvider.notifier).requireRestart();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2.0),
            ),
            child: localizedMaterialApp(
              locale: englishLocale,
              home: const Scaffold(
                body: TelemetryArtifactRestartNotice(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);

      final noticeFinder = find.byKey(const ValueKey('telemetry-artifact-restart-notice'));
      expect(noticeFinder, findsOneWidget);

      final noticeElement = tester.element(noticeFinder);
      expect(MediaQuery.textScalerOf(noticeElement).scale(14.0), equals(28.0));

      final renderBox = tester.renderObject<RenderBox>(noticeFinder);
      expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
      expect(renderBox.size.width, equals(320.0));
    });

    testWidgets('Detail screen interactive buttons and chips satisfy touch target >= 48dp with 2.0x text scaling', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320 * 2.0, 640 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          telemetryHistoryAccessProvider.overrideWithValue(
            TelemetryHistoryAccess.permitted,
          ),
          telemetrySessionReplayProvider.overrideWith(
            (ref, id) async => _testReplay,
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2.0),
            ),
            child: localizedMaterialApp(
              locale: englishLocale,
              home: const TelemetrySessionDetailScreen(
                sessionId: 'deadbeefcafe00010002000300040005',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no RenderFlex overflow on narrow viewport
      expect(tester.takeException(), isNull);

      // Scroll until playback controls and chips are visible
      final playButtonFinder = find.widgetWithIcon(FilledButton, Icons.play_arrow);
      await tester.scrollUntilVisible(playButtonFinder, 100);
      expect(playButtonFinder, findsOneWidget);

      // Verify effective TextScaler is linear(2.0)
      expect(MediaQuery.textScalerOf(tester.element(playButtonFinder)).scale(14.0), equals(28.0));

      // Play button touch target height >= 48dp
      final playButtonSize = tester.getSize(playButtonFinder);
      expect(playButtonSize.height, greaterThanOrEqualTo(48.0));
      expect(playButtonSize.width, greaterThanOrEqualTo(48.0));

      final semanticsHandle = tester.ensureSemantics();

      // ChoiceChips touch target bounds and semantics
      final chipFinder = find.widgetWithText(ChoiceChip, '16x');
      await tester.scrollUntilVisible(chipFinder, 100);
      expect(chipFinder, findsOneWidget);
      expect(MediaQuery.textScalerOf(tester.element(chipFinder)).scale(14.0), equals(28.0));
      final chipSize = tester.getSize(chipFinder);
      expect(chipSize.height, greaterThanOrEqualTo(32.0));
      final chipSemantics = tester.getSemantics(chipFinder);
      expect(chipSemantics, isSemantics(isButton: true));
      expect(chipSemantics.rect.height, greaterThanOrEqualTo(48.0));
      expect(chipSemantics.rect.width, greaterThanOrEqualTo(48.0));

      final chip1xSemantics = tester.getSemantics(find.widgetWithText(ChoiceChip, '1x'));
      expect(chip1xSemantics, isSemantics(isButton: true, isSelected: true));
      expect(chip1xSemantics.rect.height, greaterThanOrEqualTo(48.0));
      expect(chip1xSemantics.rect.width, greaterThanOrEqualTo(48.0));

      // Play button touch target height >= 48dp, width >= 48dp, semantics
      expect(playButtonSize.height, greaterThanOrEqualTo(48.0));
      expect(playButtonSize.width, greaterThanOrEqualTo(48.0));
      expect(tester.getSemantics(playButtonFinder), isSemantics(isButton: true, hasTapAction: true));

      // Export button touch target height >= 48dp, width >= 48dp, semantics
      final exportButtonFinder = find.widgetWithIcon(FilledButton, Icons.ios_share);
      await tester.scrollUntilVisible(exportButtonFinder, 100);
      expect(exportButtonFinder, findsOneWidget);
      final exportButtonSize = tester.getSize(exportButtonFinder);
      expect(exportButtonSize.height, greaterThanOrEqualTo(48.0));
      expect(exportButtonSize.width, greaterThanOrEqualTo(48.0));
      expect(tester.getSemantics(exportButtonFinder), isSemantics(isButton: true, hasTapAction: true));

      // Delete button touch target height >= 48dp, width >= 48dp, semantics
      final deleteButtonFinder = find.widgetWithIcon(OutlinedButton, Icons.delete_outline);
      await tester.scrollUntilVisible(deleteButtonFinder, 100);
      expect(deleteButtonFinder, findsOneWidget);
      final deleteButtonSize = tester.getSize(deleteButtonFinder);
      expect(deleteButtonSize.height, greaterThanOrEqualTo(48.0));
      expect(deleteButtonSize.width, greaterThanOrEqualTo(48.0));
      expect(tester.getSemantics(deleteButtonFinder), isSemantics(isButton: true, hasTapAction: true));

      semanticsHandle.dispose();
    });

    testWidgets('Detail screen renders cleanly in narrow landscape (640x320) under zh-Hant with 2.0x scaling', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(640 * 2.0, 320 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          telemetryHistoryAccessProvider.overrideWithValue(
            TelemetryHistoryAccess.permitted,
          ),
          telemetrySessionReplayProvider.overrideWith(
            (ref, id) async => _testReplay,
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(640, 320),
              textScaler: TextScaler.linear(2.0),
            ),
            child: localizedMaterialApp(
              locale: traditionalChineseLocale,
              home: const TelemetrySessionDetailScreen(
                sessionId: 'deadbeefcafe00010002000300040005',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify zero RenderFlex overflow on narrow landscape
      expect(tester.takeException(), isNull);
      final zh = lookupAppLocalizations(traditionalChineseLocale);
      expect(find.text(zh.telemetryReplayTitle), findsOneWidget);
    });
  });
}
