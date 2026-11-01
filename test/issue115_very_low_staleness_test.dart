import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/telemetry.dart';

void main() {
  final at = DateTime.utc(2026, 10, 24);

  Reading reading({Duration? interval, Pid pid = PidLibrary.distanceWithMil}) =>
      Reading(
        pid: pid,
        value: 0,
        rawBytes: const [0, 0],
        timestamp: at,
        receivedElapsed: const Duration(seconds: 10),
        observedInterval: interval,
      );

  test('first reading stays live for three scheduled rounds', () {
    final r = reading();
    expect(r.maxAge, const Duration(seconds: 90));
    expect(r.isStaleAt(at.add(const Duration(seconds: 32))), isFalse);
    expect(
      r.isStaleAt(at.add(const Duration(seconds: 90, milliseconds: 1))),
      isTrue,
    );
  });

  for (final seconds in [30, 32]) {
    test('a $seconds second cadence ages after three missed rounds', () {
      final r = reading(interval: Duration(seconds: seconds));
      expect(r.maxAge, Duration(seconds: seconds * 3));
      expect(r.isStaleAt(at.add(Duration(seconds: seconds + 1))), isFalse);
      expect(
        r.isStaleAt(
          at,
          elapsed: Duration(seconds: 10 + seconds * 3, milliseconds: 1),
        ),
        isTrue,
      );
    });
  }

  test('invalid or excessive observed intervals cannot hide old data', () {
    expect(
      reading(interval: const Duration(seconds: -1)).maxAge,
      const Duration(seconds: 90),
    );
    expect(
      reading(interval: Duration.zero).maxAge,
      const Duration(seconds: 90),
    );
    final r = reading(interval: const Duration(hours: 1));
    expect(r.maxAge, const Duration(seconds: 120));
    expect(r.isStaleAt(at.add(const Duration(seconds: 121))), isTrue);
  });

  test('the existing ceiling remains for the other priorities', () {
    for (final pid in [
      PidLibrary.engineRpm,
      PidLibrary.coolantTemp,
      PidLibrary.ambientAirTemp,
    ]) {
      expect(
        reading(pid: pid, interval: const Duration(seconds: 30)).maxAge,
        const Duration(seconds: 10),
      );
    }
  });
}
