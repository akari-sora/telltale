/// Demo ECU end-to-end integration and HUD UI lifecycle test.
///
/// Verifies:
/// 1. Real `connectDemo()` under [ProviderContainer] (real async timers) drives
///    official [telemetryProvider] and [currentHudFrameProvider] with live readings.
/// 2. Disconnect immediately transitions [currentHudFrameProvider] to missing.
/// 3. [HudScreen] properly visualizes live frames, missing placeholders, and
///    restores platform state on 700ms long-press exit.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/hud/hud_controller.dart';
import 'package:torque_obd/hud/hud_display_platform.dart';
import 'package:torque_obd/hud/hud_frame.dart';
import 'package:torque_obd/hud/hud_projector.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/ui/screens/hud/hud_screen.dart';

class _MockHudPlatform implements HudDisplayPlatform {
  final List<double?> brightnessCalls = [];
  final List<bool> systemBarsCalls = [];

  @override
  Future<void> setBrightnessOverride(double? value) async {
    brightnessCalls.add(value);
  }

  @override
  Future<void> setSystemBarsHidden(bool hidden) async {
    systemBarsCalls.add(hidden);
  }
}

class _ConnectedSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState(
        phase: ConnectionPhase.connected,
        kind: TransportKind.demo,
        deviceName: 'Demo ECU',
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('HUD live stream driven by real Demo ECU connection to disconnect lifecycle (pure async container)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final platform = _MockHudPlatform();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        hudDisplayPlatformProvider.overrideWithValue(platform),
      ],
    );
    addTearDown(container.dispose);

    // Initial state: missing, disconnected
    final initialFrame = container.read(currentHudFrameProvider);
    expect(initialFrame.speedKmh.isMissing, isTrue);
    expect(initialFrame.connected, isFalse);

    HudFrame? lastFrame;
    final hudSub = container.listen(
      currentHudFrameProvider,
      (_, next) => lastFrame = next,
      fireImmediately: true,
    );
    addTearDown(hudSub.close);

    // 1. Connect real Demo ECU
    final session = container.read(obdSessionProvider.notifier);
    final connected = await session.connectDemo();
    expect(connected, isTrue, reason: 'Demo ECU must connect successfully');
    expect(container.read(obdSessionProvider).phase, ConnectionPhase.connected);
    expect(container.read(obdSessionProvider).kind, TransportKind.demo);

    // 2. Await real live telemetry from Demo ECU in real async event loop
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (lastFrame == null ||
        !lastFrame!.speedKmh.isLive ||
        !lastFrame!.rpm.isLive ||
        !lastFrame!.coolantC.isLive) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Demo ECU failed to deliver live HUD telemetry within 10s');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    expect(lastFrame!.speedKmh.isLive, isTrue);
    expect(lastFrame!.speedKmh.value, isNotNull);
    expect(lastFrame!.rpm.isLive, isTrue);
    expect(lastFrame!.rpm.value, isNotNull);
    expect(lastFrame!.coolantC.isLive, isTrue);
    expect(lastFrame!.coolantC.value, isNotNull);
    expect(lastFrame!.connected, isTrue);

    // 3. Disconnect from Demo ECU
    await session.disconnect();
    expect(container.read(obdSessionProvider).isConnected, isFalse);

    // Reprojected frame must transition to missing after disconnect
    final disconnectDeadline = DateTime.now().add(const Duration(seconds: 5));
    while (lastFrame!.speedKmh.isLive) {
      if (DateTime.now().isAfter(disconnectDeadline)) {
        fail('HUD frame failed to transition to missing upon disconnect');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    expect(lastFrame!.speedKmh.isMissing, isTrue);
    expect(lastFrame!.connected, isFalse);
  });

  testWidgets('HudScreen renders live demo telemetry and cleanly exits upon 700ms long press', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final platform = _MockHudPlatform();
    final streamController = StreamController<TelemetrySnapshot>.broadcast(sync: true);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        hudDisplayPlatformProvider.overrideWithValue(platform),
        obdSessionProvider.overrideWith(_ConnectedSession.new),
        telemetryProvider.overrideWith((ref) => streamController.stream),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await streamController.close();
    });

    bool popped = false;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HudScreen(),
                      ),
                    ).then((_) => popped = true);
                  },
                  child: const Text('LAUNCH HUD'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Launch HUD
    await tester.tap(find.text('LAUNCH HUD'));
    await tester.pumpAndSettle();

    // 1. Initial connected but unpopulated state (no telemetry yet)
    expect(find.text('--'), findsWidgets);
    expect(find.text('NO LIVE DATA'), findsOneWidget);

    // 2. Emit live snapshot matching Demo ECU values (speed: 72 km/h, rpm: 2200)
    final now = DateTime.now();
    streamController.add(
      TelemetrySnapshot(
        readings: {
          HudSignalSources.speedKmh.id: Reading(
            pid: HudSignalSources.speedKmh,
            value: 72.0,
            rawBytes: const [0x41, 0x0D, 0x48],
            timestamp: now,
          ),
          HudSignalSources.rpm.id: Reading(
            pid: HudSignalSources.rpm,
            value: 2200.0,
            rawBytes: const [0x41, 0x0C, 0x22, 0x60],
            timestamp: now,
          ),
          HudSignalSources.coolantC.id: Reading(
            pid: HudSignalSources.coolantC,
            value: 89.0,
            rawBytes: const [0x41, 0x05, 0x77],
            timestamp: now,
          ),
        },
      ),
    );

    await tester.pump(const Duration(milliseconds: 150));

    // 3. Verify live numbers rendered without placeholders
    expect(find.text('72'), findsOneWidget);
    expect(find.text('2200'), findsOneWidget);
    expect(find.text('89'), findsOneWidget);
    expect(find.text('DISCONNECTED'), findsNothing);

    // 4. Test long-press exit
    final exitTarget = find.text('HOLD TO EXIT');
    final g = await tester.startGesture(tester.getCenter(exitTarget));
    await tester.pump(const Duration(milliseconds: 700));
    await g.up();
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(platform.brightnessCalls.last, isNull);
    expect(platform.systemBarsCalls.last, isFalse);
  });

  testWidgets('End-to-end Demo ECU session drives HudScreen: connectDemo -> live display -> disconnect -> missing placeholders & DISCONNECTED -> 700ms exit', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final platform = _MockHudPlatform();

    // Use REAL obdSessionProvider and REAL telemetryProvider
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        hudDisplayPlatformProvider.overrideWithValue(platform),
      ],
    );
    addTearDown(container.dispose);

    bool popped = false;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HudScreen(),
                      ),
                    ).then((_) => popped = true);
                  },
                  child: const Text('LAUNCH HUD'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Launch HUD while initially disconnected
    await tester.tap(find.text('LAUNCH HUD'));
    await tester.pumpAndSettle();

    expect(find.text('--'), findsWidgets);
    expect(find.text('DISCONNECTED'), findsOneWidget);

    // 2. Connect real Demo ECU via runAsync, waiting for real telemetry stream
    final session = container.read(obdSessionProvider.notifier);
    await tester.runAsync(() async {
      final connected = await session.connectDemo();
      expect(connected, isTrue, reason: 'Demo ECU connectDemo must return true');

      final completer = Completer<void>();
      final sub = session.telemetryStream.listen((snapshot) {
        if (snapshot.readings.containsKey(HudSignalSources.speedKmh.id) &&
            snapshot.readings.containsKey(HudSignalSources.rpm.id) &&
            snapshot.readings.containsKey(HudSignalSources.coolantC.id) &&
            !completer.isCompleted) {
          completer.complete();
        }
      });
      await completer.future.timeout(const Duration(seconds: 10));
      await sub.cancel();
    });

    // Pump fakeAsync clock to let HudRenderThrottle flush the live frame to the screen
    await tester.pump(const Duration(milliseconds: 200));

    // DISCONNECTED must be gone, speed, RPM, and coolant must be live
    expect(find.text('DISCONNECTED'), findsNothing);
    final liveFrame = container.read(currentHudFrameProvider);
    expect(liveFrame.speedKmh.isLive, isTrue);
    expect(liveFrame.rpm.isLive, isTrue);
    expect(liveFrame.coolantC.isLive, isTrue);
    expect(liveFrame.connected, isTrue);
    expect(find.text('${liveFrame.speedKmh.value!.round()}'), findsWidgets);

    // 3. Disconnect from Demo ECU via runAsync
    await tester.runAsync(() async {
      await session.disconnect();
    });

    // Pump fakeAsync clock to let HudRenderThrottle flush the missing frame to the screen
    await tester.pump(const Duration(milliseconds: 200));

    // DISCONNECTED badge and placeholders must return
    expect(find.text('DISCONNECTED'), findsOneWidget);
    expect(find.text('--'), findsWidgets);

    // 4. Test clean 700ms long press exit
    final exitTarget = find.text('HOLD TO EXIT');
    final g = await tester.startGesture(tester.getCenter(exitTarget));
    await tester.pump(const Duration(milliseconds: 700));
    await g.up();
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(platform.brightnessCalls.last, isNull);
    expect(platform.systemBarsCalls.last, isFalse);

    container.dispose();
  });
}

