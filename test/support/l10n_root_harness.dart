import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_ble/src/universal_ble_pigeon/universal_ble_pigeon_channel.dart';
import 'package:universal_ble/universal_ble.dart';

import 'package:torque_obd/app.dart';
import 'package:torque_obd/core/app_locales_platform.dart';
import 'package:torque_obd/core/share/app_share_platform_bridge.dart';
import 'package:torque_obd/l10n/app_locales_sync.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/obd/transport/demo_transport.dart';
import 'package:torque_obd/state/app_runtime.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/state/telemetry_runtime.dart';
import 'package:torque_obd/state/telemetry_sessions.dart';
import 'package:torque_obd/telemetry/session/telemetry_session.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_store.dart';
import 'package:torque_obd/ui/screens/connect/connect_screen.dart';

/// Captures shared files and metadata for verification.
class CapturingAppSharePlatform implements AppSharePlatform {
  final List<AppSharePlatformRequest> requests = [];
  final StreamController<AppSharePlatformRequest> _requestEvents =
      StreamController<AppSharePlatformRequest>.broadcast(sync: true);
  AppShareResult nextResult = AppShareResult.selected;

  Future<AppSharePlatformRequest> get nextRequest => _requestEvents.stream.first;

  @override
  Future<AppShareResult> share(AppSharePlatformRequest request) async {
    requests.add(request);
    _requestEvents.add(request);
    return nextResult;
  }

  Future<void> dispose() => _requestEvents.close();
}

/// An AppShareCoordinator that is always ready in test harnesses.
class AlwaysReadyAppShareCoordinator extends AppShareCoordinator {
  static int _shareId = 0;
  static var clockOffset = Duration.zero;

  static void advanceClock([Duration duration = const Duration(minutes: 20)]) {
    clockOffset += duration;
  }

  AlwaysReadyAppShareCoordinator({
    required super.policy,
    required super.artifactGate,
    required Directory Function() captureDirectory,
    AppSharePlatform? platform,
    Future<Directory> Function()? rootDirectoryOverride,
  }) : super(
          rootDirectory: rootDirectoryOverride ?? (() async => captureDirectory()),
          platform: platform ?? const AppSharePlatformBridge(),
          idSource: () => (++_shareId).toRadixString(16).padLeft(32, '0'),
          nowUtc: () => DateTime.now().toUtc().add(clockOffset),
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
    if (name == #stopScan) {
      return Future<void>.value();
    }
    if (name == #connect) {
      connectCount++;
      return Future<void>.value();
    }
    if (name == #disconnect) {
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

  ArtifactOperationGate get artifactGate =>
      appRef.read(artifactOperationGateProvider);

  bool _initialized = false;
  bool get isInitialized => _initialized;
  List<String> currentOsTags = ['en'];
  Future<Directory> Function()? shareRootDirectoryOverride;

  /// Fake-time pause inserted at the start of recording prepare.
  ///
  /// [pumpUntil] advances the demo timer faster than Start's file I/O.
  /// A dwell longer than the initial 3s idle makes that race fail unless
  /// [holdDemoAtIdle] is holding the drive at 0 km/h.
  Duration recordingPrepareDwell = Duration.zero;

  void advanceShareClock([Duration duration = const Duration(minutes: 20)]) =>
      AlwaysReadyAppShareCoordinator.advanceClock(duration);

  /// Installs an idle simulator before the UI calls [connectDemo].
  ///
  /// [connectDemo] builds a new transport on every attempt, and the drive
  /// timer starts inside [DemoTransport.connect]. Setting a flag afterwards
  /// cannot stop that timer, so this has to run first. The substitute answers
  /// every PID and never starts the timer, so the car stays at 0 km/h.
  void holdDemoAtIdle() {
    appRef.read(obdSessionProvider.notifier).demoTransportFactory =
        (latency) => _IdleDemoTransport(responseLatency: latency);
  }

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
    UniversalBle.setInstance(blePlatform);
    sharePlatform = CapturingAppSharePlatform();
    _initialized = true;
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    try {
      if (appRef.read(obdSessionProvider).isConnected) {
        await appRef.read(obdSessionProvider.notifier).disconnect();
      }
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sharePlatform.dispose();
    blePlatform.reset();
    UniversalBle.setInstance(UniversalBlePigeonChannel.instance);
    AlwaysReadyAppShareCoordinator.clockOffset = Duration.zero;
    AppLocalesPlatform.live = false;
    shareRootDirectoryOverride = null;
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
          telemetryRecorderRuntimeProvider.overrideWith((ref) {
            final runtime = ref.watch(productionTelemetryRecorderRuntimeProvider);
            final dwell = recordingPrepareDwell;
            if (dwell <= Duration.zero) return runtime;
            return TelemetryRecorderRuntime(
              environment: runtime.environment,
              storage: _RecordingPrepareDwellStorage(runtime.storage, dwell),
              utcNow: runtime.utcNow,
              elapsedUs: runtime.elapsedUs,
            );
          }),
          appSharePolicyProvider.overrideWith(
            (ref) => ref.watch(productionAppSharePolicyProvider),
          ),
          appShareCoordinatorProvider.overrideWith(
            (ref) => AlwaysReadyAppShareCoordinator(
              policy: ref.watch(appSharePolicyProvider),
              artifactGate: ref.watch(artifactOperationGateProvider),
              captureDirectory: () => tempShareDir,
              platform: sharePlatform,
              rootDirectoryOverride: shareRootDirectoryOverride,
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
            return const RepaintBoundary(
              key: Key('app_root_repaint_boundary'),
              child: TorqueApp(),
            );
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

/// Simulator that answers every PID and never starts the drive timer.
///
/// [DemoTransport.disconnect] only cancels a timer when one exists, so a
/// connect that never armed `_tick` still disconnects cleanly.
final class _IdleDemoTransport extends DemoTransport {
  _IdleDemoTransport({super.responseLatency});

  @override
  Future<void> connect() async {
    if (isConnected) return;
    setConnected(true);
  }
}

/// Pauses once, on the tester clock, before the real prepare I/O.
///
/// The pause is a [Future.delayed] in the widget test's fake-async zone, so
/// each [WidgetTester.pump] both burns the pause and ticks the demo drive.
final class _RecordingPrepareDwellStorage implements TelemetryRecorderStorage {
  _RecordingPrepareDwellStorage(this.inner, this.pause);

  final TelemetryRecorderStorage inner;
  final Duration pause;

  @override
  Future<void> prepareDirectory({void Function(String checkpoint)? checkpoint}) async {
    if (pause > Duration.zero) {
      await Future<void>.delayed(pause);
    }
    await inner.prepareDirectory(checkpoint: checkpoint);
  }

  @override
  Future<TelemetryStorageQuota> scanQuota({void Function(String checkpoint)? checkpoint}) =>
      inner.scanQuota(checkpoint: checkpoint);

  @override
  Future<TelemetryStagingWriter> createExclusive(
    TelemetrySessionHeader Function(String sessionId) headerForId, {
    required TelemetryStorageQuota quota,
    void Function(String checkpoint)? checkpoint,
  }) =>
      inner.createExclusive(headerForId, quota: quota, checkpoint: checkpoint);
}
