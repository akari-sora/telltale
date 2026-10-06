/// Tests for [HudFrameNotifier], [hudDisplaySessionProvider], and [currentHudFrameProvider].
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/hud/hud_controller.dart';
import 'package:torque_obd/hud/hud_display_platform.dart';
import 'package:torque_obd/hud/hud_frame.dart';
import 'package:torque_obd/hud/hud_projector.dart';
import 'package:torque_obd/hud/hud_settings.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/ui/screens/hud/hud_viewport.dart';

class _MockPlatform implements HudDisplayPlatform {
  final List<double?> calls = [];

  @override
  Future<void> setBrightnessOverride(double? value) async {
    calls.add(value);
  }

  @override
  Future<void> setSystemBarsHidden(bool hidden) async {}
}

class _FixedSession extends ObdSession {
  _FixedSession(this._state);
  final ObdConnectionState _state;

  @override
  ObdConnectionState build() => _state;

  void updateState(ObdConnectionState newState) {
    state = newState;
  }
}

Reading _createReading(
  Pid pid,
  double value, {
  DateTime? timestamp,
  Duration? receivedElapsed,
}) {
  final now = timestamp ?? DateTime.now();
  return Reading(
    pid: pid,
    value: value,
    rawBytes: const [0x41, 0x00, 0x00],
    timestamp: now,
    receivedElapsed: receivedElapsed ?? Duration.zero,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('hudDisplaySessionProvider', () {
    test('creates HudDisplaySession bound to overridden platform', () {
      final mockPlatform = _MockPlatform();
      final container = ProviderContainer(
        overrides: [
          hudDisplayPlatformProvider.overrideWithValue(mockPlatform),
        ],
      );
      addTearDown(container.dispose);

      final session = container.read(hudDisplaySessionProvider);
      expect(session, isNotNull);
      expect(session.platform, equals(mockPlatform));
    });
  });

  group('HudFrameNotifier & currentHudFrameProvider (Controlled Monotonic Clock)', () {
    test('initial state projects empty/missing when telemetry is not yet ready and disconnected', () {
      final container = ProviderContainer(
        overrides: [
          telemetryProvider.overrideWith((ref) => const Stream.empty()),
          obdSessionProvider.overrideWith(
            () => _FixedSession(const ObdConnectionState(phase: ConnectionPhase.disconnected)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final frame = container.read(currentHudFrameProvider);
      expect(frame.connected, isFalse);
      expect(frame.speedKmh.isMissing, isTrue);
      expect(frame.rpm.isMissing, isTrue);
      expect(frame.coolantC.isMissing, isTrue);
    });

    test('projects live metrics with authoritative isLive assertion when stream emits valid snapshot', () async {
      final streamController = StreamController<TelemetrySnapshot>.broadcast(sync: true);
      final session = _FixedSession(const ObdConnectionState(phase: ConnectionPhase.connected));

      final container = ProviderContainer(
        overrides: [
          telemetryProvider.overrideWith((ref) => streamController.stream),
          obdSessionProvider.overrideWith(() => session),
        ],
      );

      final subscription = container.listen(
        currentHudFrameProvider,
        (_, _) {},
        fireImmediately: true,
      );

      addTearDown(() async {
        subscription.close();
        container.dispose();
        await streamController.close();
      });

      var simulatedElapsed = Duration.zero;
      final captureTime = DateTime.now();

      final snapshot = TelemetrySnapshot(
        readings: {
          HudSignalSources.speedKmh.id: _createReading(
            HudSignalSources.speedKmh,
            85.0,
            timestamp: captureTime,
            receivedElapsed: Duration.zero,
          ),
          HudSignalSources.rpm.id: _createReading(
            HudSignalSources.rpm,
            2400.0,
            timestamp: captureTime,
            receivedElapsed: Duration.zero,
          ),
          HudSignalSources.coolantC.id: _createReading(
            HudSignalSources.coolantC,
            88.0,
            timestamp: captureTime,
            receivedElapsed: Duration.zero,
          ),
        },
        capturedAt: captureTime,
        elapsedNow: () => simulatedElapsed,
      );

      streamController.add(snapshot);
      await container.pump();

      final frame = container.read(currentHudFrameProvider);
      expect(frame.connected, isTrue);

      // HUD-R2-03: Must assert isLive before asserting numeric value
      expect(frame.speedKmh.isLive, isTrue, reason: 'Fresh telemetry must project isLive == true');
      expect(frame.speedKmh.value, equals(85.0));

      expect(frame.rpm.isLive, isTrue);
      expect(frame.rpm.value, equals(2400.0));

      expect(frame.coolantC.isLive, isTrue);
      expect(frame.coolantC.value, equals(88.0));
    });

    test('authoritative telemetry filtering rejects retained AsyncError and initial unpopulated AsyncLoading by projecting missing', () async {
      final streamController = StreamController<TelemetrySnapshot>.broadcast(sync: true);
      final session = _FixedSession(const ObdConnectionState(phase: ConnectionPhase.connected));

      final container = ProviderContainer(
        overrides: [
          telemetryProvider.overrideWith((ref) => streamController.stream),
          obdSessionProvider.overrideWith(() => session),
        ],
      );

      final subscription = container.listen(
        currentHudFrameProvider,
        (_, _) {},
        fireImmediately: true,
      );

      addTearDown(() async {
        subscription.close();
        container.dispose();
        await streamController.close();
      });

      // 0. Verify initial state before any stream emission is missing (handles initial unpopulated AsyncLoading)
      var initialFrame = container.read(currentHudFrameProvider);
      expect(initialFrame.speedKmh.isMissing, isTrue,
          reason: 'Initial unpopulated AsyncLoading state before stream emits must project missing');

      final captureTime = DateTime.now();
      // 1. Emit live data
      streamController.add(
        TelemetrySnapshot(
          readings: {
            HudSignalSources.speedKmh.id: _createReading(
              HudSignalSources.speedKmh,
              92.0,
              timestamp: captureTime,
              receivedElapsed: Duration.zero,
            ),
            HudSignalSources.rpm.id: _createReading(
              HudSignalSources.rpm,
              2700.0,
              timestamp: captureTime,
              receivedElapsed: Duration.zero,
            ),
          },
          capturedAt: captureTime,
          elapsedNow: () => Duration.zero,
        ),
      );
      await container.pump();

      var frame = container.read(currentHudFrameProvider);
      expect(frame.speedKmh.isLive, isTrue);
      expect(frame.speedKmh.value, equals(92.0));

      // 2. Stream error -> authoritativeTelemetryValue is null -> projects missing (not retained data)
      await Future<void>.delayed(const Duration(milliseconds: 110));
      streamController.addError(Exception('OBD bus error'));
      await container.pump();

      frame = container.read(currentHudFrameProvider);
      expect(frame.speedKmh.isMissing, isTrue,
          reason: 'Authoritative filter must return missing frame when telemetry stream has error');
      expect(frame.rpm.isMissing, isTrue);
    });

    testWidgets('exceeding authoritative TTL transitions metric from live to stale, rendering "--" on screen',
        (tester) async {
      var currentElapsed = Duration.zero;
      final captureTime = DateTime.now();

      final snapshot = TelemetrySnapshot(
        readings: {
          HudSignalSources.speedKmh.id: _createReading(
            HudSignalSources.speedKmh,
            75.0,
            timestamp: captureTime,
            receivedElapsed: Duration.zero,
          ),
          HudSignalSources.rpm.id: _createReading(
            HudSignalSources.rpm,
            2100.0,
            timestamp: captureTime,
            receivedElapsed: Duration.zero,
          ),
          HudSignalSources.coolantC.id: _createReading(
            HudSignalSources.coolantC,
            90.0,
            timestamp: captureTime,
            receivedElapsed: Duration.zero,
          ),
        },
        capturedAt: captureTime,
        elapsedNow: () => currentElapsed,
      );

      // 1. Verify projectHudFrame at T=0 produces live values
      final liveFrame = projectHudFrame(
        telemetry: snapshot,
        isConnected: true,
      );
      expect(liveFrame.speedKmh.isLive, isTrue);
      expect(liveFrame.speedKmh.value, equals(75.0));

      // 2. Render live frame on HudViewport -> displays "75"
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudViewport(
              frame: liveFrame,
              palette: HudThemePalette.green,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('75'), findsOneWidget);

      // 3. Advance elapsed monotonic time past speed PID maxAge (exceeding standard OBD TTL)
      // speedKmh typically has maxAge around 2.5s - 5s; 30s guarantees staleness across all PIDs
      currentElapsed = const Duration(seconds: 30);

      final staleFrame = projectHudFrame(
        telemetry: snapshot,
        isConnected: true,
      );

      // HUD-R2-03: Frame value is stale (value preserved for offline diagnosis, but isLive is false)
      expect(staleFrame.speedKmh.isStale, isTrue);
      expect(staleFrame.speedKmh.isLive, isFalse);
      expect(staleFrame.speedKmh.value, equals(75.0));

      // 4. Render stale frame on HudViewport -> displays "--", "75" completely disappears
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudViewport(
              frame: staleFrame,
              palette: HudThemePalette.green,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('75'), findsNothing, reason: 'Previous speed 75 must be cleared when value becomes stale');
      expect(find.text('--'), findsAtLeast(1));
    });

    test('10Hz latest-wins throttle coalesces bursts of updates into a single latest emission', () async {
      final streamController = StreamController<TelemetrySnapshot>.broadcast(sync: true);
      final session = _FixedSession(const ObdConnectionState(phase: ConnectionPhase.connected));

      final container = ProviderContainer(
        overrides: [
          telemetryProvider.overrideWith((ref) => streamController.stream),
          obdSessionProvider.overrideWith(() => session),
        ],
      );

      final emittedFrames = <HudFrame>[];
      final subscription = container.listen(currentHudFrameProvider, (_, next) {
        emittedFrames.add(next);
      });

      addTearDown(() async {
        subscription.close();
        container.dispose();
        await streamController.close();
      });

      final captureTime = DateTime.now();

      // Frame 1 emitted immediately
      streamController.add(
        TelemetrySnapshot(
          readings: {
            HudSignalSources.speedKmh.id: _createReading(
              HudSignalSources.speedKmh,
              50.0,
              timestamp: captureTime,
              receivedElapsed: Duration.zero,
            ),
          },
          capturedAt: captureTime,
          elapsedNow: () => Duration.zero,
        ),
      );
      await container.pump();
      expect(emittedFrames.length, equals(1));
      expect(emittedFrames.last.speedKmh.isLive, isTrue);
      expect(emittedFrames.last.speedKmh.value, equals(50.0));

      // Burst 3 updates rapidly (during the 100ms throttle cooldown window)
      for (int i = 1; i <= 3; i++) {
        streamController.add(
          TelemetrySnapshot(
            readings: {
              HudSignalSources.speedKmh.id: _createReading(
                HudSignalSources.speedKmh,
                50.0 + i * 10,
                timestamp: captureTime,
                receivedElapsed: Duration.zero,
              ),
            },
            capturedAt: captureTime,
            elapsedNow: () => Duration.zero,
          ),
        );
        await container.pump();
      }

      // Intermediate updates were throttled (not emitted yet)
      expect(emittedFrames.length, equals(1));

      // Wait past the 100ms throttle cooldown
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await container.pump();

      // Latest frame (50 + 3*10 = 80 km/h) was emitted
      expect(emittedFrames.length, equals(2));
      expect(emittedFrames.last.speedKmh.isLive, isTrue);
      expect(emittedFrames.last.speedKmh.value, equals(80.0),
          reason: 'Coalesced throttle emission must deliver latest-wins value');
    });

    test('connection state change recomputes connected status', () async {
      final streamController = StreamController<TelemetrySnapshot>.broadcast(sync: true);
      final session = _FixedSession(const ObdConnectionState(phase: ConnectionPhase.connected));

      final container = ProviderContainer(
        overrides: [
          telemetryProvider.overrideWith((ref) => streamController.stream),
          obdSessionProvider.overrideWith(() => session),
        ],
      );

      final subscription = container.listen(
        currentHudFrameProvider,
        (_, _) {},
        fireImmediately: true,
      );

      addTearDown(() async {
        subscription.close();
        container.dispose();
        await streamController.close();
      });

      // Disconnect session
      session.updateState(const ObdConnectionState(phase: ConnectionPhase.disconnected));
      await container.pump();

      final frame = container.read(currentHudFrameProvider);
      expect(frame.connected, isFalse);
    });
  });
}
