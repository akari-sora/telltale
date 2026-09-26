import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_ble/universal_ble.dart';

import 'package:torque_obd/app.dart';
import 'package:torque_obd/core/app_locales_platform.dart';
import 'package:torque_obd/core/share/app_share_platform_bridge.dart';
import 'package:torque_obd/l10n/app_locales_sync.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/app_runtime.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';
import 'package:torque_obd/state/language_switch_guard.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/state/telemetry_runtime.dart';
import 'package:torque_obd/state/telemetry_sessions.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_store.dart';
import 'package:torque_obd/ui/screens/connect/connect_screen.dart';

/// Captures shared files and metadata for verification.
class CapturingAppSharePlatform implements AppSharePlatform {
  final List<AppSharePlatformRequest> requests = [];

  @override
  Future<AppShareResult> share(AppSharePlatformRequest request) async {
    requests.add(request);
    return AppShareResult.selected;
  }
}

/// An AppShareCoordinator that is always ready in test harnesses.
class AlwaysReadyAppShareCoordinator extends AppShareCoordinator {
  static int _shareId = 0;

  AlwaysReadyAppShareCoordinator({
    required super.policy,
    required super.artifactGate,
    required Directory Function() captureDirectory,
    AppSharePlatform? platform,
  }) : super(
          rootDirectory: () async => captureDirectory(),
          platform: platform ?? const AppSharePlatformBridge(),
          idSource: () => (++_shareId).toRadixString(16).padLeft(32, '0'),
          nowUtc: () => DateTime.now().toUtc(),
          availableBytes: (_) async => 1024 * 1024 * 100, // 100MB
        );
}

/// A UniversalBlePlatform that counts operations without physical adapter.
class CountingBlePlatform extends UniversalBlePlatform {
  int scanCount = 0;
  int connectCount = 0;
  int sendCount = 0;

  void reset() {
    scanCount = 0;
    connectCount = 0;
    sendCount = 0;
  }

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

/// Root harness for production-root journey testing.
class L10nRootHarness {
  L10nRootHarness();

  late Directory tempTelemetryDir;
  late Directory tempShareDir;
  late SharedPreferences prefs;
  late CountingBlePlatform blePlatform;
  late CapturingAppSharePlatform sharePlatform;
  late WidgetRef appRef;

  bool _initialized = false;
  bool get isInitialized => _initialized;
  List<String> currentOsTags = ['en'];

  Future<void> initialize({
    Map<String, Object>? initialPrefs,
  }) async {
    tempTelemetryDir = Directory.systemTemp.createTempSync('l06_telemetry_');
    tempShareDir = Directory.systemTemp.createTempSync('l06_share_');
    SharedPreferences.setMockInitialValues(initialPrefs ?? {
      kLocalePreferenceKey: 'en',
      kLocaleOsMigratedKey: true,
    });
    prefs = await SharedPreferences.getInstance();
    blePlatform = CountingBlePlatform();
    sharePlatform = CapturingAppSharePlatform();
    _initialized = true;
  }

  Future<void> dispose() async {
    AppLocalesPlatform.live = false;
    if (!_initialized) return;
    try {
      if (appRef.read(obdSessionProvider).isConnected) {
        await appRef.read(obdSessionProvider.notifier).disconnect();
      }
    } catch (_) {}
    try {
      if (tempTelemetryDir.existsSync()) {
        tempTelemetryDir.deleteSync(recursive: true);
      }
      if (tempShareDir.existsSync()) {
        tempShareDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    List<dynamic> extraOverrides = const [],
  }) async {
    assert(_initialized, 'Must call initialize() before pumpApp()');

    // Setup mock AppLocalesPlatform channel
    AppLocalesPlatform.live = true;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      AppLocalesPlatform.channel,
      (call) async {
        if (call.method == kAppLocalesGetMethod) {
          return {
            'apiSupported': true,
            'sdkInt': 36,
            'followsSystem': currentOsTags.isEmpty,
            'overrideTags': currentOsTags,
            'configurationTags': currentOsTags,
          };
        }
        if (call.method == kAppLocalesSetMethod) {
          final args = call.arguments as Map?;
          final tags = (args?['tags'] as List?)?.cast<String>();
          if (tags != null) {
            currentOsTags = tags;
          }
          return {
            'apiSupported': true,
            'sdkInt': 36,
            'followsSystem': currentOsTags.isEmpty,
            'overrideTags': currentOsTags,
            'configurationTags': currentOsTags,
          };
        }
        return null;
      },
    );

    // Mock WakelockPlus Pigeon channels to prevent PlatformException
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
      (message) async => const StandardMessageCodec().encodeMessage(<Object?>[null]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          telemetryRecorderRuntimeProvider.overrideWith(
            (ref) => ref.watch(productionTelemetryRecorderRuntimeProvider),
          ),
          appSharePolicyProvider.overrideWith(
            (ref) => ref.watch(productionAppSharePolicyProvider),
          ),
          appShareCoordinatorProvider.overrideWith(
            (ref) => AlwaysReadyAppShareCoordinator(
              policy: ref.watch(appSharePolicyProvider),
              artifactGate: ref.watch(artifactOperationGateProvider),
              captureDirectory: () => tempShareDir,
              platform: sharePlatform,
            ),
          ),
          telemetrySessionStoreProvider.overrideWithValue(
            TelemetrySessionStore(
              documentsDirectory: () async => tempTelemetryDir,
            ),
          ),
          telemetrySessionLibraryServiceProvider.overrideWithValue(
            TelemetrySessionLibraryService(
              documentsDirectory: () async => tempTelemetryDir,
            ),
          ),
          ...extraOverrides.cast(),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            appRef = ref;
            return const TorqueApp();
          },
        ),
      ),
    );

    // Await startup initialization and MaterialApp.router readiness
    await pumpUntil(
      tester,
      () => find.byType(InheritedGoRouter).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 15),
    );

    // Steer back to ConnectScreen if a previous test left router on another screen
    final routerFinder = find.byType(InheritedGoRouter);
    if (routerFinder.evaluate().isNotEmpty) {
      final inherited = tester.widget<InheritedGoRouter>(routerFinder.first);
      inherited.goRouter.go(ConnectScreen.path);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    await pumpUntil(
      tester,
      () => find.byType(ConnectScreen).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 15),
    );
    appRef.invalidate(languageSwitchBlockProvider);
    await tester.pump();
  }

  /// Pumps tester until condition is true or timeout is reached.
  Future<bool> pumpUntil(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 15),
    Duration step = const Duration(milliseconds: 100),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (condition()) return true;
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(step);
    }
    return condition();
  }

  /// Captures a [RepaintBoundary] as PNG bytes.
  static Future<List<int>> captureBoundaryAsPng(
    WidgetTester tester,
    Finder boundaryFinder,
  ) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(boundaryFinder);
    late final List<int> bytes;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Failed to encode boundary to PNG');
      }
      bytes = byteData.buffer.asUint8List();
    });
    return bytes;
  }
}
