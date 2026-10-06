import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/hud/hud_projector.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/telemetry.dart';

void main() {
  final now = DateTime.utc(2026, 10, 6, 12, 0, 0);

  Reading createReading(Pid pid, double value, {DateTime? time}) {
    return Reading(
      pid: pid,
      value: value,
      rawBytes: const [0x41, 0x0D, 0x00],
      timestamp: time ?? now,
    );
  }

  group('projectHudFrame', () {
    test('null telemetry or disconnected returns missing or stale frame', () {
      final frameNull = projectHudFrame(
        telemetry: null,
        isConnected: false,
        now: now,
      );
      expect(frameNull.connected, isFalse);
      expect(frameNull.speedKmh.isMissing, isTrue);
      expect(frameNull.rpm.isMissing, isTrue);
      expect(frameNull.coolantC.isMissing, isTrue);

      final snapshot = TelemetrySnapshot(
        readings: {
          HudSignalSources.speedKmh.id: createReading(HudSignalSources.speedKmh, 50.0),
        },
        capturedAt: now,
      );

      final frameDisconnected = projectHudFrame(
        telemetry: snapshot,
        isConnected: false,
        now: now,
      );
      expect(frameDisconnected.connected, isFalse);
      expect(frameDisconnected.speedKmh.isStale, isTrue);
      expect(frameDisconnected.speedKmh.value, 50.0);
    });

    test('live speed 0 km/h is preserved as live(0.0), not missing', () {
      final snapshot = TelemetrySnapshot(
        readings: {
          HudSignalSources.speedKmh.id: createReading(HudSignalSources.speedKmh, 0.0),
          HudSignalSources.rpm.id: createReading(HudSignalSources.rpm, 750.0),
          HudSignalSources.coolantC.id: createReading(HudSignalSources.coolantC, 90.0),
        },
        capturedAt: now,
      );

      final frame = projectHudFrame(
        telemetry: snapshot,
        isConnected: true,
        now: now,
      );

      expect(frame.connected, isTrue);
      expect(frame.speedKmh.isLive, isTrue);
      expect(frame.speedKmh.value, 0.0);
      expect(frame.rpm.isLive, isTrue);
      expect(frame.rpm.value, 750.0);
      expect(frame.coolantC.isLive, isTrue);
      expect(frame.coolantC.value, 90.0);
    });

    test('missing speed is reported as missing, never coerced to 0.0', () {
      final snapshot = TelemetrySnapshot(
        readings: {
          HudSignalSources.rpm.id: createReading(HudSignalSources.rpm, 2000.0),
        },
        capturedAt: now,
      );

      final frame = projectHudFrame(
        telemetry: snapshot,
        isConnected: true,
        now: now,
      );

      expect(frame.speedKmh.isMissing, isTrue);
      expect(frame.speedKmh.value, isNull);
      expect(frame.rpm.isLive, isTrue);
      expect(frame.rpm.value, 2000.0);
    });

    test('stale speed past TTL is reported as stale, not live', () {
      final oldTime = now.subtract(const Duration(seconds: 15));
      final snapshot = TelemetrySnapshot(
        readings: {
          HudSignalSources.speedKmh.id:
              createReading(HudSignalSources.speedKmh, 100.0, time: oldTime),
        },
        capturedAt: oldTime,
      );

      final frame = projectHudFrame(
        telemetry: snapshot,
        isConnected: true,
        now: now,
      );

      expect(frame.speedKmh.isStale, isTrue);
      expect(frame.speedKmh.value, 100.0);
    });

    test('ECU fault marks signal as unavailable', () {
      final snapshot = TelemetrySnapshot(
        faults: {
          HudSignalSources.speedKmh.id: PidFault.unsupported,
        },
        capturedAt: now,
      );

      final frame = projectHudFrame(
        telemetry: snapshot,
        isConnected: true,
        now: now,
      );

      expect(frame.speedKmh.isUnavailable, isTrue);
      expect(frame.speedKmh.value, isNull);
    });
  });
}
