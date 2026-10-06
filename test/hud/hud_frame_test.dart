import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/hud/hud_frame.dart';

void main() {
  group('HudValue', () {
    test('live constructor preserves value and live state', () {
      const val = HudValue.live(45.0);
      expect(val.isLive, isTrue);
      expect(val.isStale, isFalse);
      expect(val.isMissing, isFalse);
      expect(val.isUnavailable, isFalse);
      expect(val.value, 45.0);
      expect(val.state, HudValueState.live);
    });

    test('missing constructor sets null value and missing state', () {
      const val = HudValue.missing();
      expect(val.isMissing, isTrue);
      expect(val.isLive, isFalse);
      expect(val.value, isNull);
      expect(val.state, HudValueState.missing);
    });

    test('unavailable constructor sets null value and unavailable state', () {
      const val = HudValue.unavailable();
      expect(val.isUnavailable, isTrue);
      expect(val.isLive, isFalse);
      expect(val.value, isNull);
      expect(val.state, HudValueState.unavailable);
    });

    test('stale constructor preserves previous value with stale state', () {
      const val = HudValue.stale(88.0);
      expect(val.isStale, isTrue);
      expect(val.isLive, isFalse);
      expect(val.value, 88.0);
      expect(val.state, HudValueState.stale);
    });

    test('value equality and hashCode contract', () {
      const a = HudValue.live(60.0);
      const b = HudValue.live(60.0);
      const c = HudValue.stale(60.0);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('HudFrame', () {
    test('empty frame defaults to missing signals and disconnected', () {
      const frame = HudFrame.empty();
      expect(frame.connected, isFalse);
      expect(frame.speedKmh.isMissing, isTrue);
      expect(frame.rpm.isMissing, isTrue);
      expect(frame.coolantC.isMissing, isTrue);
      expect(frame.capturedAt, isNull);
    });

    test('equality and hashCode contract', () {
      final now = DateTime.utc(2026, 10, 6, 12, 0);
      final f1 = HudFrame(
        speedKmh: const HudValue.live(100.0),
        rpm: const HudValue.live(3000.0),
        coolantC: const HudValue.live(90.0),
        connected: true,
        capturedAt: now,
      );
      final f2 = HudFrame(
        speedKmh: const HudValue.live(100.0),
        rpm: const HudValue.live(3000.0),
        coolantC: const HudValue.live(90.0),
        connected: true,
        capturedAt: now,
      );
      final f3 = HudFrame(
        speedKmh: const HudValue.live(101.0),
        rpm: const HudValue.live(3000.0),
        coolantC: const HudValue.live(90.0),
        connected: true,
        capturedAt: now,
      );

      expect(f1, equals(f2));
      expect(f1.hashCode, equals(f2.hashCode));
      expect(f1, isNot(equals(f3)));
    });
  });
}
