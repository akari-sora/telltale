/// Batch 1L-A verification: L01 (entry accessibility), L02 (pure presentation rerendering),
/// L03 (async synchronizer with switch block guard), and L04 (state preservation under guard).
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_ble/universal_ble.dart';

import 'package:torque_obd/app.dart';
import 'package:torque_obd/core/app_locales_platform.dart';
import 'package:torque_obd/core/ble_scan_permissions.dart';
import 'package:torque_obd/core/share/app_share_platform_bridge.dart';
import 'package:torque_obd/l10n/app_locales_sync.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/transport/ble_transport.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/app_locales_synchronizer.dart';
import 'package:torque_obd/state/app_runtime.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';
import 'package:torque_obd/state/language_switch_guard.dart';
import 'package:torque_obd/state/locale_settings.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/state/telemetry_runtime.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_store.dart';
import 'package:torque_obd/ui/screens/connect/connect_screen.dart';
import 'package:torque_obd/ui/screens/connect/transport_kind_copy.dart';
import 'package:torque_obd/ui/wear/wear_permission_copy.dart';
import 'package:torque_obd/ui/widgets/language_picker.dart';
import '../support/localized_app.dart';

class _IdleSession extends ObdSession {
  int connects = 0;

  @override
  ObdConnectionState build() => const ObdConnectionState();

  @override
  Future<bool> connectWifi({String? host, int? port}) async {
    connects++;
    return false;
  }

  @override
  Future<bool> connectClassic(DiscoveredDevice device) async {
    connects++;
    return false;
  }

  @override
  Future<bool> connectBle(BleAdapterHandle device) async {
    connects++;
    return false;
  }

  @override
  Future<bool> connectDemo({Duration? responseLatency}) async {
    connects++;
    return false;
  }
}

class _CountingBlePlatform extends UniversalBlePlatform {
  int scanCount = 0;
  void reset() => scanCount = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #startScan) {
      scanCount++;
      return Future<void>.value();
    }
    return null;
  }
}

class _FaultInjectingPrefs implements SharedPreferences {
  _FaultInjectingPrefs(this._inner);

  final SharedPreferences _inner;
  bool failSetString = false;
  bool failSetBool = false;
  bool throwSetString = false;
  bool throwSetBool = false;

  @override
  Future<bool> setString(String key, String value) async {
    if (throwSetString) throw StateError('Injected storage exception for setString');
    if (failSetString) return false;
    return _inner.setString(key, value);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    if (throwSetBool) throw StateError('Injected storage exception for setBool');
    if (failSetBool) return false;
    return _inner.setBool(key, value);
  }

  @override
  String? getString(String key) => _inner.getString(key);

  @override
  bool? getBool(String key) => _inner.getBool(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => _inner.noSuchMethod(invocation);
}

class _TestProgressNotifier extends TelemetryRecorderProgressNotifier {
  _TestProgressNotifier(this._initial);
  final TelemetryRecorderProgress _initial;

  @override
  TelemetryRecorderProgress build() => _initial;

  void setPhase(TelemetryRecorderPhase phase) {
    state = TelemetryRecorderProgress(
      state: TelemetryRecorderState(phase: phase),
      elapsedUs: state.elapsedUs,
      bytesBeforeFooter: state.bytesBeforeFooter,
      effectiveSessionLimit: state.effectiveSessionLimit,
      sessionId: state.sessionId,
    );
  }
}

class _AlwaysReadyAppShareCoordinator extends AppShareCoordinator {
  _AlwaysReadyAppShareCoordinator({
    required super.policy,
    required super.artifactGate,
  }) : super(
          rootDirectory: () async => Directory.systemTemp,
          platform: const AppSharePlatformBridge(),
          idSource: () => 'fake',
          nowUtc: () => DateTime.now().toUtc(),
          availableBytes: (_) async => 1024,
        );

  @override
  Future<AppShareInitializationOutcome> initialize() async {
    return AppShareInitializationOutcome.ready;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final en = lookupAppLocalizations(englishLocale);
  final zh = lookupAppLocalizations(traditionalChineseLocale);

  Widget buildApp({
    required SharedPreferences prefs,
    required _IdleSession session,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        obdSessionProvider.overrideWith(() => session),
        appSharePolicyProvider.overrideWith(
          (ref) => ref.watch(productionAppSharePolicyProvider),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final pref = ref.watch(localePreferenceProvider);
          final locale = resolveAppLocale(
            deviceLocales: const [Locale('en')],
            preference: pref,
          );
          return localizedMaterialApp(
            locale: locale,
            home: const ConnectScreen(),
          );
        },
      ),
    );
  }

  group('L01: Language entry is accessible before connection and without VIN', () {
    testWidgets('connect screen language button opens picker and updates without connection', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final session = _IdleSession();

      int permissionPromptCount = 0;
      final blePlatform = _CountingBlePlatform();
      UniversalBle.setInstance(blePlatform);
      addTearDown(() {
        blePlatform.reset();
        UniversalBle.setInstance(_CountingBlePlatform());
      });

      // Positive control: verify scanCount increments on startScan
      await blePlatform.startScan();
      expect(blePlatform.scanCount, 1);
      blePlatform.scanCount = 0;

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (call) async {
          permissionPromptCount++;
          return <int, int>{};
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        null,
      ));

      await tester.pumpWidget(buildApp(prefs: prefs, session: session));
      await tester.pumpAndSettle();

      // Find language entry button
      final langBtn = find.byKey(const Key('connect_language_entry'));
      expect(langBtn, findsOneWidget);

      // Verify not connected before
      expect(session.state.isConnected, isFalse);

      // Tap language entry button
      await tester.tap(langBtn);
      await tester.pumpAndSettle();

      // Language picker sheet should be open
      expect(find.byType(LanguagePicker), findsOneWidget);

      // Select Traditional Chinese (zh_Hant)
      await tester.tap(find.byKey(const Key('locale_traditionalChinese')));
      await tester.pumpAndSettle();

      // Verify that locale changed to Traditional Chinese
      expect(prefs.getString(kLocalePreferenceKey), 'zh_Hant');
      expect(find.text(zh.connectHeadline), findsOneWidget);

      // Verify still not connected, zero scans, and zero permission prompts
      expect(session.connects, 0);
      expect(blePlatform.scanCount, 0);
      expect(permissionPromptCount, 0);
      expect(session.state.isConnected, isFalse);
    });
  });

  group('L02: Pure presentation change dynamically re-renders errors across locales', () {
    testWidgets('WiFi validation error updates dynamically when language changes', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final session = _IdleSession();

      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp(prefs: prefs, session: session));
      await tester.pumpAndSettle();

      // Expand Wi-Fi transport
      final wifiTile = find.text(transportKindTitle(en, TransportKind.wifi));
      expect(wifiTile, findsOneWidget);
      await tester.tap(wifiTile);
      await tester.pumpAndSettle();

      // Clear the host text field so host is empty
      final hostField = find.byType(TextField).first;
      expect(hostField, findsOneWidget);
      await tester.enterText(hostField, '');
      await tester.pumpAndSettle();

      // Attempt to connect with empty host
      final connectBtn = find.widgetWithText(FilledButton, en.connectConnect);
      expect(connectBtn, findsOneWidget);
      await tester.tap(connectBtn);
      await tester.pumpAndSettle();

      // English error should be visible
      expect(find.text(en.connectWifiHostRequired), findsOneWidget);

      // Open language picker and switch to Traditional Chinese
      final langBtn = find.byKey(const Key('connect_language_entry'));
      await tester.tap(langBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('locale_traditionalChinese')));
      await tester.pumpAndSettle();

      // Error must now be rendered in Traditional Chinese without tapping connect again!
      expect(find.text(zh.connectWifiHostRequired), findsOneWidget);
      expect(find.text(en.connectWifiHostRequired), findsNothing);

      // Switch language back to English in the open picker
      await tester.tap(find.byKey(const Key('locale_english')));
      await tester.pumpAndSettle();

      // Error must now be rendered in English again
      expect(find.text(en.connectWifiHostRequired), findsOneWidget);
      expect(find.text(zh.connectWifiHostRequired), findsNothing);

      // Dismiss bottom sheet
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // Zero connects initiated
      expect(session.connects, 0);
      expect(session.state.isConnected, isFalse);
    });

    test('Location vs Bluetooth permission copy separation in both languages', () {
      // Android <= 11 location denial should name Location, NOT Bluetooth!
      final locEn = blePermissionName(en, BlePermissionKind.location);
      final locZh = blePermissionName(zh, BlePermissionKind.location);
      expect(locEn, 'Location');
      expect(locZh, '位置');

      final neededEn = en.wearScanPermissionNeeded(locEn);
      final neededZh = zh.wearScanPermissionNeeded(locZh);
      expect(neededEn, contains('Location'));
      expect(neededEn.toLowerCase(), isNot(contains('bluetooth')));
      expect(neededZh, contains('位置'));
      expect(neededZh, isNot(contains('藍牙')));

      final permDeniedEn = en.wearScanPermissionPermanentlyDenied(locEn);
      final permDeniedZh = zh.wearScanPermissionPermanentlyDenied(locZh);
      expect(permDeniedEn, contains('Location'));
      expect(permDeniedEn.toLowerCase(), isNot(contains('bluetooth')));
      expect(permDeniedZh, contains('位置'));
      expect(permDeniedZh, isNot(contains('藍牙')));

      // Bluetooth denial
      final btEn = blePermissionName(en, BlePermissionKind.bluetooth);
      final btZh = blePermissionName(zh, BlePermissionKind.bluetooth);
      expect(btEn, 'Bluetooth');
      expect(btZh, '藍牙');
    });

    testWidgets('WiFi invalid port error dynamically re-renders and cursor selection remains stable', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final session = _IdleSession();

      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp(prefs: prefs, session: session));
      await tester.pumpAndSettle();

      // Expand Wi-Fi transport
      final wifiTile = find.text(transportKindTitle(en, TransportKind.wifi));
      await tester.tap(wifiTile);
      await tester.pumpAndSettle();

      // Enter host and an invalid port "99999"
      final textFields = find.byType(TextField);
      final hostField = textFields.first;
      final portField = textFields.last;

      await tester.enterText(hostField, '192.168.0.10');
      await tester.enterText(portField, '99999');
      await tester.pumpAndSettle();

      // Explicitly set selection offset 5
      final portFieldWidget = tester.widget<TextField>(portField);
      portFieldWidget.controller!.value = const TextEditingValue(
        text: '99999',
        selection: TextSelection.collapsed(offset: 5),
      );
      await tester.pump();

      // Attempt to connect with out-of-range port
      final connectBtn = find.widgetWithText(FilledButton, en.connectConnect);
      await tester.tap(connectBtn);
      await tester.pumpAndSettle();

      final beforeValue = tester.widget<TextField>(portField).controller!.value;

      // English invalid port error should be visible
      final expectedEn = en.connectWifiPortInvalid('99999', 1, 65535);
      final expectedZh = zh.connectWifiPortInvalid('99999', 1, 65535);
      expect(find.text(expectedEn), findsOneWidget);

      // Open language picker and switch to Traditional Chinese
      final langBtn = find.byKey(const Key('connect_language_entry'));
      await tester.tap(langBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('locale_traditionalChinese')));
      await tester.pumpAndSettle();

      // Error must now be rendered in Traditional Chinese dynamically
      expect(find.text(expectedZh), findsOneWidget);
      expect(find.text(expectedEn), findsNothing);

      // Verify that port text field value, selection offset 5, and composing are preserved
      expect(find.widgetWithText(TextField, '99999'), findsOneWidget);
      final afterZhValue = tester.widget<TextField>(portField).controller!.value;
      expect(afterZhValue.text, beforeValue.text);
      expect(afterZhValue.selection.baseOffset, 5);
      expect(afterZhValue.selection.extentOffset, 5);
      expect(afterZhValue.selection, beforeValue.selection);
      expect(afterZhValue.composing, beforeValue.composing);
      expect(afterZhValue.composing.start, -1);
      expect(afterZhValue.composing.end, -1);

      // Switch language back to English
      await tester.tap(find.byKey(const Key('locale_english')));
      await tester.pumpAndSettle();

      expect(find.text(expectedEn), findsOneWidget);
      expect(find.text(expectedZh), findsNothing);

      final afterEnValue = tester.widget<TextField>(portField).controller!.value;
      expect(afterEnValue.text, beforeValue.text);
      expect(afterEnValue.selection.baseOffset, 5);
      expect(afterEnValue.selection.extentOffset, 5);
      expect(afterEnValue.selection, beforeValue.selection);
      expect(afterEnValue.composing, beforeValue.composing);
      expect(afterEnValue.composing.start, -1);
      expect(afterEnValue.composing.end, -1);

      // Dismiss bottom sheet
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
    });

    testWidgets('Location permission denial dynamically re-renders permission copy across locales without side effects', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final session = _IdleSession();

      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var permissionPromptCount = 0;
      testEnsureBluetoothPermissionsOverride = ({required forScanning}) async {
        permissionPromptCount++;
        return const BlePermissionResult.refused(
          BlePermissionOutcome.denied,
          BlePermissionKind.location,
        );
      };
      addTearDown(() => testEnsureBluetoothPermissionsOverride = null);

      final blePlatform = _CountingBlePlatform();
      UniversalBle.setInstance(blePlatform);
      addTearDown(() {
        blePlatform.reset();
        UniversalBle.setInstance(_CountingBlePlatform());
      });

      await tester.pumpWidget(buildApp(prefs: prefs, session: session));
      await tester.pumpAndSettle();

      // Expand BLE section
      final bleTile = find.text(transportKindTitle(en, TransportKind.bluetoothLe));
      await tester.ensureVisible(bleTile);
      await tester.tap(bleTile);
      await tester.pumpAndSettle();

      // Tap scan button to trigger scan with permission check
      final scanBtn = find.widgetWithText(FilledButton, en.connectBleScan);
      await tester.ensureVisible(scanBtn);
      await tester.tap(scanBtn);
      await tester.pumpAndSettle();

      final locEn = blePermissionName(en, BlePermissionKind.location);
      final locZh = blePermissionName(zh, BlePermissionKind.location);
      final expectedEnError = en.wearScanPermissionNeeded(locEn);
      final expectedZhError = zh.wearScanPermissionNeeded(locZh);

      // Verify English permission denial error copy is displayed
      expect(find.text(expectedEnError), findsOneWidget);
      expect(permissionPromptCount, 1);

      // Reset count to verify switching language introduces 0 new prompts/scans/connects
      permissionPromptCount = 0;
      blePlatform.scanCount = 0;

      // Open language picker and switch to Traditional Chinese
      final langBtn = find.byKey(const Key('connect_language_entry'));
      await tester.tap(langBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('locale_traditionalChinese')));
      await tester.pumpAndSettle();

      // Dismiss bottom sheet
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // The error message must dynamically re-render to Traditional Chinese!
      expect(find.text(expectedZhError), findsOneWidget);
      expect(find.text(expectedEnError), findsNothing);
      expect(find.text(zh.connectHeadline), findsOneWidget);

      // Verify zero side effects on locale change
      expect(session.connects, 0);
      expect(permissionPromptCount, 0);
      expect(blePlatform.scanCount, 0);
    });
  });

  group('L03 & L04: Async locale synchronization and guard state preservation', () {
    test('LocalePreferenceController.set is blocked when LanguageSwitchBlock is active', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      // Initial preference is system
      expect(container.read(localePreferenceProvider), LocalePreference.system);

      // Activate dirty editor via provider
      container.read(pidEditorDirtyProvider.notifier).setDirty(true);
      expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.pidEditorDirty);

      // Attempt to change locale preference - should be rejected!
      final result = await container.read(localePreferenceProvider.notifier).set(LocalePreference.german);
      expect(result, isFalse);
      expect(container.read(localePreferenceProvider), LocalePreference.system);

      // Clear block
      container.read(pidEditorDirtyProvider.notifier).setDirty(false);
      expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.none);

      // Now set should succeed!
      final result2 = await container.read(localePreferenceProvider.notifier).set(LocalePreference.traditionalChinese);
      expect(result2, isTrue);
      expect(container.read(localePreferenceProvider), LocalePreference.traditionalChinese);
    });

    test('R67-1 & R67-2: queued synchronizer is superseded when user write begins before execution', () async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(localePreferenceProvider.notifier);

      // 1. Synchronizer queues a sync action
      final osReadCompleter = Completer<AppLocalesSyncResult?>();
      final syncFuture = controller.synchronize((version) => osReadCompleter.future);

      // 2. Before synchronizer runs its queue microtask, user selects Traditional Chinese via Picker
      final userWriteFuture = controller.set(LocalePreference.traditionalChinese);

      // 3. User write completes
      expect(await userWriteFuture, isTrue);
      expect(container.read(localePreferenceProvider), LocalePreference.traditionalChinese);
      expect(prefs.getString(kLocalePreferenceKey), 'zh_Hant');

      // 4. Stale OS read (German) now completes after user write
      osReadCompleter.complete(
        const AppLocalesSyncResult(
          plan: AppLocalesSyncPlan(
            action: AppLocalesSyncAction.alreadyMigratedFollowOs,
            storedIdToKeep: 'de',
            osTagsToWrite: [],
            writeStored: false,
            writeOs: false,
            markMigrated: false,
          ),
          disposition: LocaleSyncDisposition.applied,
          storedIdCommitted: 'de',
        ),
      );

      // 5. Synchronizer detects it was superseded and drops the stale OS result!
      expect(await syncFuture, isFalse);
      expect(container.read(localePreferenceProvider), LocalePreference.traditionalChinese);
      expect(prefs.getString(kLocalePreferenceKey), 'zh_Hant');
    });

    test('R67-3: true in-flight sync race where syncAction enters and waits before picker write', () async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(localePreferenceProvider.notifier);

      final entered = Completer<void>();
      final osReadCompleter = Completer<AppLocalesSyncResult?>();
      var enteredCount = 0;

      // 1. Synchronizer starts and actually enters syncAction
      final syncFuture = controller.synchronize((version) {
        enteredCount++;
        entered.complete();
        return osReadCompleter.future;
      });

      // 2. Wait until syncAction is actively running inside the queue!
      await entered.future;
      expect(enteredCount, 1);

      // 3. While syncAction is in-flight awaiting OS read, user selects Traditional Chinese.
      // Must NOT await userWriteFuture yet because _persistQueue is held by syncFuture.
      final userWriteFuture = controller.set(LocalePreference.traditionalChinese);

      // 4. In-flight OS read completes with German
      osReadCompleter.complete(
        const AppLocalesSyncResult(
          plan: AppLocalesSyncPlan(
            action: AppLocalesSyncAction.alreadyMigratedFollowOs,
            storedIdToKeep: 'de',
            osTagsToWrite: [],
            writeStored: false,
            writeOs: false,
            markMigrated: false,
          ),
          disposition: LocaleSyncDisposition.applied,
          storedIdCommitted: 'de',
        ),
      );

      // 5. Await syncFuture: must be false because version changed during in-flight await!
      expect(await syncFuture, isFalse);

      // 6. Now userWriteFuture executes in queue and succeeds
      expect(await userWriteFuture, isTrue);
      expect(container.read(localePreferenceProvider), LocalePreference.traditionalChinese);
      expect(prefs.getString(kLocalePreferenceKey), 'zh_Hant');
    });

    test('R67-1: guard activated while syncAction is in-flight blocks commit without clobbering', () async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(localePreferenceProvider.notifier);

      final entered = Completer<void>();
      final osReadCompleter = Completer<AppLocalesSyncResult?>();
      var enteredCount = 0;

      final syncFuture = controller.synchronize((version) {
        enteredCount++;
        entered.complete();
        return osReadCompleter.future;
      });

      await entered.future;
      expect(enteredCount, 1);

      // Activate dirty editor guard while syncAction is in-flight
      container.read(pidEditorDirtyProvider.notifier).setDirty(true);
      expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.pidEditorDirty);

      // Complete in-flight OS read
      osReadCompleter.complete(
        const AppLocalesSyncResult(
          plan: AppLocalesSyncPlan(
            action: AppLocalesSyncAction.alreadyMigratedFollowOs,
            storedIdToKeep: 'de',
            osTagsToWrite: [],
            writeStored: false,
            writeOs: false,
            markMigrated: false,
          ),
          disposition: LocaleSyncDisposition.applied,
          storedIdCommitted: 'de',
        ),
      );

      // Synchronizer must detect guard is active and abort commit!
      expect(await syncFuture, isFalse);
      expect(container.read(localePreferenceProvider), LocalePreference.english);
      expect(prefs.getString(kLocalePreferenceKey), 'en');
    });

    test('R67-2 & R67-3: real synchronizer with storage failure (setBool false) preserves store write and assigns appliedNeedsReconcile', () async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
      });
      final basePrefs = await SharedPreferences.getInstance();
      final faultPrefs = _FaultInjectingPrefs(basePrefs);
      faultPrefs.failSetBool = true;

      final synchronizer = AppLocalesSynchronizer(
        prefs: faultPrefs,
        getOs: () async => const AppLocalesSnapshot(
          apiSupported: true,
          sdkInt: 36,
          followsSystem: false,
          overrideTags: ['de'],
          configurationTags: ['de-DE'],
        ),
        setOs: (tags) async => AppLocalesSnapshot(
          apiSupported: true,
          sdkInt: 36,
          followsSystem: tags.isEmpty,
          overrideTags: tags,
          configurationTags: tags,
        ),
      );

      final result = await synchronizer.sync();
      expect(result.disposition, LocaleSyncDisposition.appliedNeedsReconcile);
      expect(result.storeWritten, isTrue);
      expect(result.storedIdCommitted, 'de');
      expect(result.migrationMarked, isFalse);
      expect(basePrefs.getString(kLocalePreferenceKey), 'de');
      expect(basePrefs.getBool(kLocaleOsMigratedKey), isNot(true));

      // Healed storage retry only marks migrated without re-writing store
      faultPrefs.failSetBool = false;
      final healResult = await synchronizer.sync();
      expect(healResult.disposition, LocaleSyncDisposition.applied);
      expect(healResult.migrationMarked, isTrue);
      expect(basePrefs.getBool(kLocaleOsMigratedKey), isTrue);
    });

    test('R67-2 & R67-3: real synchronizer with setString failure returns failed disposition and does not claim storeWritten', () async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
      });
      final basePrefs = await SharedPreferences.getInstance();
      final faultPrefs = _FaultInjectingPrefs(basePrefs);
      faultPrefs.failSetString = true;

      final synchronizer = AppLocalesSynchronizer(
        prefs: faultPrefs,
        getOs: () async => const AppLocalesSnapshot(
          apiSupported: true,
          sdkInt: 36,
          followsSystem: false,
          overrideTags: ['de'],
          configurationTags: ['de-DE'],
        ),
      );

      final result = await synchronizer.sync();
      expect(result.disposition, LocaleSyncDisposition.failed);
      expect(result.storeWritten, isFalse);
      expect(result.storedIdCommitted, isNull);
      expect(basePrefs.getString(kLocalePreferenceKey), 'en');
    });

    test('R67-2 & R67-3: real synchronizer with setBool throw preserves store write, returns appliedNeedsReconcile, and does not leak unhandled error', () async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
      });
      final basePrefs = await SharedPreferences.getInstance();
      final faultPrefs = _FaultInjectingPrefs(basePrefs);
      faultPrefs.throwSetBool = true;

      final synchronizer = AppLocalesSynchronizer(
        prefs: faultPrefs,
        getOs: () async => const AppLocalesSnapshot(
          apiSupported: true,
          sdkInt: 36,
          followsSystem: false,
          overrideTags: ['de'],
          configurationTags: ['de-DE'],
        ),
        setOs: (tags) async => AppLocalesSnapshot(
          apiSupported: true,
          sdkInt: 36,
          followsSystem: tags.isEmpty,
          overrideTags: tags,
          configurationTags: tags,
        ),
      );

      final result = await synchronizer.sync();
      expect(result.disposition, LocaleSyncDisposition.appliedNeedsReconcile);
      expect(result.storeWritten, isTrue);
      expect(result.storedIdCommitted, 'de');
      expect(result.migrationMarked, isFalse);
      expect(basePrefs.getString(kLocalePreferenceKey), 'de');
      expect(basePrefs.getBool(kLocaleOsMigratedKey), isNot(true));
    });

    testWidgets('R67-2 & R67-3: real picker with setBool returning false retains acknowledged store value and marks needsReconcile', (tester) async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
      });
      final basePrefs = await SharedPreferences.getInstance();
      final faultPrefs = _FaultInjectingPrefs(basePrefs);
      faultPrefs.failSetBool = true;

      AppLocalesPlatform.live = true;
      addTearDown(() => AppLocalesPlatform.live = false);

      String? osSetTag;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        (call) async {
          if (call.method == kAppLocalesGetMethod) {
            return {
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': false,
              'overrideTags': [osSetTag ?? 'en'],
              'configurationTags': [osSetTag ?? 'en'],
            };
          }
          if (call.method == kAppLocalesSetMethod) {
            final args = call.arguments as Map?;
            final tags = (args?['tags'] as List?)?.cast<String>();
            osSetTag = tags?.firstOrNull;
            return {
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': tags == null || tags.isEmpty,
              'overrideTags': tags ?? [],
              'configurationTags': tags ?? [],
            };
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        null,
      ));

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(faultPrefs),
          telemetryRecorderProgressProvider.overrideWith(
            () => _TestProgressNotifier(
              const TelemetryRecorderProgress(
                state: TelemetryRecorderState(phase: TelemetryRecorderPhase.idle),
                elapsedUs: 0,
                bytesBeforeFooter: 0,
                effectiveSessionLimit: 1024 * 1024,
                sessionId: 'session-fault-test-1',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(localePreferenceProvider.notifier);
      final ok = await controller.set(LocalePreference.traditionalChinese);

      // Operation returns false because migration marker failed
      expect(ok, isFalse);
      // But store has acknowledged zh_Hant!
      expect(basePrefs.getString(kLocalePreferenceKey), 'zh_Hant');
      expect(controller.committed, LocalePreference.traditionalChinese);
      expect(controller.needsReconcile, isTrue);
      // And OS was NOT rolled back!
      expect(osSetTag, 'zh-Hant');
      // UI reflects preference when unblocked
      expect(container.read(localePreferenceProvider), LocalePreference.traditionalChinese);
    });

    testWidgets('R67-2 & R67-3: real picker with setBool throw retains acknowledged store value, does not rollback OS, marks needsReconcile, and absorbs exception', (tester) async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
      });
      final basePrefs = await SharedPreferences.getInstance();
      final faultPrefs = _FaultInjectingPrefs(basePrefs);
      faultPrefs.throwSetBool = true;

      AppLocalesPlatform.live = true;
      addTearDown(() => AppLocalesPlatform.live = false);

      String? osSetTag;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        (call) async {
          if (call.method == kAppLocalesGetMethod) {
            return {
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': false,
              'overrideTags': [osSetTag ?? 'en'],
              'configurationTags': [osSetTag ?? 'en'],
            };
          }
          if (call.method == kAppLocalesSetMethod) {
            final args = call.arguments as Map?;
            final tags = (args?['tags'] as List?)?.cast<String>();
            osSetTag = tags?.firstOrNull;
            return {
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': tags == null || tags.isEmpty,
              'overrideTags': tags ?? [],
              'configurationTags': tags ?? [],
            };
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        null,
      ));

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(faultPrefs),
          telemetryRecorderProgressProvider.overrideWith(
            () => _TestProgressNotifier(
              const TelemetryRecorderProgress(
                state: TelemetryRecorderState(phase: TelemetryRecorderPhase.idle),
                elapsedUs: 0,
                bytesBeforeFooter: 0,
                effectiveSessionLimit: 1024 * 1024,
                sessionId: 'session-fault-test-2',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(localePreferenceProvider.notifier);
      final ok = await controller.set(LocalePreference.traditionalChinese);

      // Absorbs exception and returns false
      expect(ok, isFalse);
      // Store has acknowledged zh_Hant!
      expect(basePrefs.getString(kLocalePreferenceKey), 'zh_Hant');
      expect(controller.committed, LocalePreference.traditionalChinese);
      expect(controller.needsReconcile, isTrue);
      // OS was NOT rolled back to en!
      expect(osSetTag, 'zh-Hant');
      expect(container.read(localePreferenceProvider), LocalePreference.traditionalChinese);
    });

    test('R67-2: partially successful sync resulting in appliedNeedsReconcile does not overwrite newer picker choice', () async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(localePreferenceProvider.notifier);

      final entered = Completer<void>();
      final syncCompleter = Completer<AppLocalesSyncResult?>();

      final syncFuture = controller.synchronize((version) {
        entered.complete();
        return syncCompleter.future;
      });

      await entered.future;

      // User immediately chooses Traditional Chinese
      final userWriteFuture = controller.set(LocalePreference.traditionalChinese);

      // Stale sync returns appliedNeedsReconcile for German
      syncCompleter.complete(
        const AppLocalesSyncResult(
          plan: AppLocalesSyncPlan(
            action: AppLocalesSyncAction.alreadyMigratedFollowOs,
            storedIdToKeep: 'de',
            osTagsToWrite: [],
            writeStored: true,
            writeOs: false,
            markMigrated: false,
          ),
          disposition: LocaleSyncDisposition.appliedNeedsReconcile,
          storedIdCommitted: 'de',
          storeWritten: true,
        ),
      );

      expect(await syncFuture, isFalse);
      expect(await userWriteFuture, isTrue);
      expect(container.read(localePreferenceProvider), LocalePreference.traditionalChinese);
      expect(prefs.getString(kLocalePreferenceKey), 'zh_Hant');
    });

    testWidgets('R67-1: compensation awaiting rollback does not clobber newer user selection', (tester) async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
      });
      final basePrefs = await SharedPreferences.getInstance();
      final faultPrefs = _FaultInjectingPrefs(basePrefs);
      AppLocalesPlatform.live = true;
      addTearDown(() => AppLocalesPlatform.live = false);

      final rollbackEntered = Completer<void>();
      final rollbackGate = Completer<void>();

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        (call) async {
          if (call.method == kAppLocalesGetMethod) {
            return {
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': false,
              'overrideTags': ['en'],
              'configurationTags': ['en'],
            };
          }
          if (call.method == kAppLocalesSetMethod) {
            final args = call.arguments as Map?;
            final tags = args?['tags'] as List?;
            if (tags != null && tags.contains('en')) {
              if (!rollbackEntered.isCompleted) {
                rollbackEntered.complete();
              }
              await rollbackGate.future;
              return {
                'apiSupported': true,
                'sdkInt': 36,
                'followsSystem': false,
                'overrideTags': ['en'],
                'configurationTags': ['en'],
              };
            }
            return {
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': tags == null || tags.isEmpty,
              'overrideTags': tags ?? [],
              'configurationTags': tags ?? [],
            };
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        null,
      ));

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(faultPrefs),
          telemetryRecorderProgressProvider.overrideWith(
            () => _TestProgressNotifier(
              const TelemetryRecorderProgress(
                state: TelemetryRecorderState(phase: TelemetryRecorderPhase.idle),
                elapsedUs: 0,
                bytesBeforeFooter: 0,
                effectiveSessionLimit: 1024 * 1024,
                sessionId: 'session-rec-test-1',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(localePreferenceProvider.notifier);

      // Attempt 1: set Traditional Chinese, but prefs setString fails, causing rollback to English
      faultPrefs.failSetString = true;
      final attempt1Future = controller.set(LocalePreference.traditionalChinese);

      // Wait until rollback is actively awaiting inside AppLocalesPlatform.setOverrideTags
      await rollbackEntered.future;

      // While rollback is in flight, user selects German (Attempt 2)!
      faultPrefs.failSetString = false;
      final attempt2Future = controller.set(LocalePreference.german);
      expect(container.read(localePreferenceProvider), LocalePreference.german);

      // Release rollback of Attempt 1
      rollbackGate.complete();

      // Attempt 1 completes with false
      expect(await attempt1Future, isFalse);

      // Crucial assertion: Attempt 1 rollback must NOT reset state to English!
      expect(container.read(localePreferenceProvider), LocalePreference.german);

      // Attempt 2 completes with true
      expect(await attempt2Future, isTrue);
      expect(container.read(localePreferenceProvider), LocalePreference.german);
      expect(basePrefs.getString(kLocalePreferenceKey), 'de');
      container.dispose();
    });

    testWidgets('R67-2: OS setter mismatch does not report success and preserves committed state', (tester) async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
      });
      final prefs = await SharedPreferences.getInstance();
      AppLocalesPlatform.live = true;
      addTearDown(() => AppLocalesPlatform.live = false);

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        (call) async {
          if (call.method == kAppLocalesGetMethod) {
            return {
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': false,
              'overrideTags': ['en'],
              'configurationTags': ['en'],
            };
          }
          if (call.method == kAppLocalesSetMethod) {
            // Return mismatch: returns English tags even though Chinese was requested
            return {
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': false,
              'overrideTags': ['en'],
              'configurationTags': ['en'],
            };
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        null,
      ));

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          telemetryRecorderProgressProvider.overrideWith(
            () => _TestProgressNotifier(
              const TelemetryRecorderProgress(
                state: TelemetryRecorderState(phase: TelemetryRecorderPhase.idle),
                elapsedUs: 0,
                bytesBeforeFooter: 0,
                effectiveSessionLimit: 1024 * 1024,
                sessionId: 'session-rec-test-2',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(localePreferenceProvider.notifier);

      final ok = await controller.set(LocalePreference.traditionalChinese);
      expect(ok, isFalse);
      expect(container.read(localePreferenceProvider), LocalePreference.english);
      expect(prefs.getString(kLocalePreferenceKey), 'en');
      container.dispose();
    });

    test('R67-2: AppLocalesSynchronizer returns deferred when shouldAbort triggers', () async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
        kLocaleOsMigratedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      var abort = false;
      final synchronizer = AppLocalesSynchronizer(
        prefs: prefs,
        getOs: () async {
          abort = true;
          return const AppLocalesSnapshot(
            apiSupported: true,
            sdkInt: 36,
            followsSystem: false,
            overrideTags: ['de'],
            configurationTags: ['de-DE'],
          );
        },
        shouldAbort: () => abort,
      );

      final res = await synchronizer.sync();
      expect(res.disposition, LocaleSyncDisposition.deferred);
      expect(prefs.getString(kLocalePreferenceKey), 'en');
    });

    testWidgets('Root lifecycle transition onResume executes synchronizer when unblocked', (tester) async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
        kLocaleOsMigratedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      AppLocalesPlatform.live = true;
      addTearDown(() => AppLocalesPlatform.live = false);

      var getCallCount = 0;
      var setCallCount = 0;
      var currentOsTags = <String>['en'];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        (call) async {
          if (call.method == kAppLocalesGetMethod) {
            getCallCount++;
            return {
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': false,
              'overrideTags': currentOsTags,
              'configurationTags': currentOsTags,
            };
          }
          if (call.method == kAppLocalesSetMethod) {
            setCallCount++;
            return null;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        null,
      ));

      final tempShareDir = Directory.systemTemp.createTempSync('test-share-1-');
      final tempTelemetryDir = Directory.systemTemp.createTempSync('test-telemetry-1-');
      addTearDown(() {
        if (tempShareDir.existsSync()) tempShareDir.deleteSync(recursive: true);
        if (tempTelemetryDir.existsSync()) tempTelemetryDir.deleteSync(recursive: true);
      });

      late WidgetRef appRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appSharePolicyProvider.overrideWith(
              (ref) => ref.watch(productionAppSharePolicyProvider),
            ),
            appShareCoordinatorProvider.overrideWith(
              (ref) => _AlwaysReadyAppShareCoordinator(
                policy: ref.watch(appSharePolicyProvider),
                artifactGate: ref.watch(artifactOperationGateProvider),
              ),
            ),
            telemetrySessionStoreProvider.overrideWithValue(
              TelemetrySessionStore(
                documentsDirectory: () async => tempTelemetryDir,
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              appRef = ref;
              return const TorqueApp();
            },
          ),
        ),
      );
      await tester.runAsync(() async {
        for (var i = 0; i < 40; i++) {
          await Future.delayed(const Duration(milliseconds: 50));
          if (appRef.read(languageSwitchBlockProvider) == LanguageSwitchBlock.none) {
            break;
          }
        }
      });
      await tester.pump();

      // Verify startup completed with English
      expect(prefs.getString(kLocalePreferenceKey), 'en');
      final startupGetCount = getCallCount;
      expect(startupGetCount, greaterThanOrEqualTo(1));

      // Change OS locale to German and trigger Root lifecycle transition onResume
      currentOsTags = <String>['de'];
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Verify that TorqueApp synchronized and updated to de, getter had bounded diff, and zero echo OS write occurred
      expect(getCallCount - startupGetCount, inInclusiveRange(1, 2));
      expect(setCallCount, 0); // No echo write back to OS when authority is OS!
      expect(prefs.getString(kLocalePreferenceKey), 'de');
      expect(appRef.read(localePreferenceProvider), LocalePreference.german);
      expect(currentOsTags, ['de']);
    });

    testWidgets('Root lifecycle onResume is blocked while TelemetryRecorder is in recording phase, and unblocking triggers real state update', (tester) async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
        kLocaleOsMigratedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      AppLocalesPlatform.live = true;
      addTearDown(() => AppLocalesPlatform.live = false);

      var currentOsTags = <String>['en'];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        (call) async {
          if (call.method == kAppLocalesGetMethod) {
            return {
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': false,
              'overrideTags': currentOsTags,
              'configurationTags': currentOsTags,
            };
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        null,
      ));

      final tempShareDir = Directory.systemTemp.createTempSync('test-share-rec-');
      final tempTelemetryDir = Directory.systemTemp.createTempSync('test-telemetry-rec-');
      addTearDown(() {
        if (tempShareDir.existsSync()) tempShareDir.deleteSync(recursive: true);
        if (tempTelemetryDir.existsSync()) tempTelemetryDir.deleteSync(recursive: true);
      });

      final progressNotifier = _TestProgressNotifier(
        const TelemetryRecorderProgress(
          state: TelemetryRecorderState(phase: TelemetryRecorderPhase.idle),
          elapsedUs: 0,
          bytesBeforeFooter: 0,
          effectiveSessionLimit: 1024 * 1024,
          sessionId: 'session-rec-1',
        ),
      );

      late WidgetRef appRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            telemetryRecorderProgressProvider.overrideWith(() => progressNotifier),
            appSharePolicyProvider.overrideWith(
              (ref) => ref.watch(productionAppSharePolicyProvider),
            ),
            appShareCoordinatorProvider.overrideWith(
              (ref) => _AlwaysReadyAppShareCoordinator(
                policy: ref.watch(appSharePolicyProvider),
                artifactGate: ref.watch(artifactOperationGateProvider),
              ),
            ),
            telemetrySessionStoreProvider.overrideWithValue(
              TelemetrySessionStore(
                documentsDirectory: () async => tempTelemetryDir,
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              appRef = ref;
              return const TorqueApp();
            },
          ),
        ),
      );
      await tester.runAsync(() async {
        for (var i = 0; i < 40; i++) {
          await Future.delayed(const Duration(milliseconds: 50));
          if (appRef.read(languageSwitchBlockProvider) == LanguageSwitchBlock.none) {
            break;
          }
        }
      });
      await tester.pump();

      // Enter active recording phase
      progressNotifier.setPhase(TelemetryRecorderPhase.recording);
      await tester.pump(const Duration(milliseconds: 50));
      expect(appRef.read(languageSwitchBlockProvider), LanguageSwitchBlock.recording);

      // OS locale changes to German while app is in background
      currentOsTags = <String>['de'];

      // App resumes from background
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Blocked by recording: stored preference remains English!
      expect(prefs.getString(kLocalePreferenceKey), 'en');

      // Recording ends
      progressNotifier.setPhase(TelemetryRecorderPhase.idle);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (appRef.read(languageSwitchBlockProvider) == LanguageSwitchBlock.none) {
          break;
        }
      }
      expect(appRef.read(languageSwitchBlockProvider), LanguageSwitchBlock.none);

      // Unblocking triggers sync and updates store and controller to German!
      expect(prefs.getString(kLocalePreferenceKey), 'de');
      expect(appRef.read(localePreferenceProvider), LocalePreference.german);
    });

    testWidgets('Root lifecycle onResume is blocked while recording/dirty editor is active, and unblocking triggers real state update', (tester) async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
        kLocaleOsMigratedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      AppLocalesPlatform.live = true;
      addTearDown(() => AppLocalesPlatform.live = false);

      var currentOsTags = <String>['en'];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        (call) async {
          if (call.method == kAppLocalesGetMethod) {
            return {
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': false,
              'overrideTags': currentOsTags,
              'configurationTags': currentOsTags,
            };
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        null,
      ));

      final tempShareDir = Directory.systemTemp.createTempSync('test-share-2-');
      final tempTelemetryDir = Directory.systemTemp.createTempSync('test-telemetry-2-');
      addTearDown(() {
        if (tempShareDir.existsSync()) tempShareDir.deleteSync(recursive: true);
        if (tempTelemetryDir.existsSync()) tempTelemetryDir.deleteSync(recursive: true);
      });

      late WidgetRef appRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appSharePolicyProvider.overrideWith(
              (ref) => ref.watch(productionAppSharePolicyProvider),
            ),
            appShareCoordinatorProvider.overrideWith(
              (ref) => _AlwaysReadyAppShareCoordinator(
                policy: ref.watch(appSharePolicyProvider),
                artifactGate: ref.watch(artifactOperationGateProvider),
              ),
            ),
            telemetrySessionStoreProvider.overrideWithValue(
              TelemetrySessionStore(
                documentsDirectory: () async => tempTelemetryDir,
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              appRef = ref;
              return const TorqueApp();
            },
          ),
        ),
      );
      await tester.runAsync(() async {
        for (var i = 0; i < 40; i++) {
          await Future.delayed(const Duration(milliseconds: 50));
          if (appRef.read(languageSwitchBlockProvider) == LanguageSwitchBlock.none) {
            break;
          }
        }
      });
      await tester.pump();

      // Activate dirty editor guard
      appRef.read(pidEditorDirtyProvider.notifier).setDirty(true);
      await tester.pump(const Duration(milliseconds: 50));
      expect(appRef.read(languageSwitchBlockProvider), LanguageSwitchBlock.pidEditorDirty);

      // OS locale changes to Traditional Chinese while app is in background
      currentOsTags = <String>['zh-Hant'];

      // App resumes from background
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Guard is active: stored preference remains English!
      expect(prefs.getString(kLocalePreferenceKey), 'en');

      // Real unblock transition: editor discard/save completes
      appRef.read(pidEditorDirtyProvider.notifier).setDirty(false);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (appRef.read(languageSwitchBlockProvider) == LanguageSwitchBlock.none) {
          break;
        }
      }
      expect(appRef.read(languageSwitchBlockProvider), LanguageSwitchBlock.none);

      // Unblock transition triggers real sync and updates state to Traditional Chinese!
      expect(prefs.getString(kLocalePreferenceKey), 'zh_Hant');
    });
  });
}
