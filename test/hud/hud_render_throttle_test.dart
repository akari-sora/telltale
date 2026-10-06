// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/hud/hud_frame.dart';
import 'package:torque_obd/hud/hud_render_throttle.dart';

void main() {
  HudFrame makeFrame(double speed) {
    return HudFrame(
      speedKmh: HudValue.live(speed),
      rpm: const HudValue.live(2000.0),
      coolantC: const HudValue.live(90.0),
      connected: true,
    );
  }

  group('HudRenderThrottle', () {
    test('emits first frame immediately, coalesces intermediate frames to latest-wins', () {
      fakeAsync((async) {
        final emitted = <double>[];
        final throttle = HudRenderThrottle(
          interval: const Duration(milliseconds: 100),
          onRender: (frame) => emitted.add(frame.speedKmh.value!),
        );

        // Frame 1: emitted immediately
        throttle.push(makeFrame(10.0));
        expect(emitted, [10.0]);

        // Frame 2 and 3 arrive within 50ms (before the 100ms window expires)
        async.elapse(const Duration(milliseconds: 20));
        throttle.push(makeFrame(20.0));

        async.elapse(const Duration(milliseconds: 20));
        throttle.push(makeFrame(30.0)); // latest wins

        // Still only frame 1 emitted so far
        expect(emitted, [10.0]);

        // Advance to 100ms: frame 3 must be emitted; frame 2 dropped
        async.elapse(const Duration(milliseconds: 65));
        expect(emitted, [10.0, 30.0]);

        // Subsequent pushes after interval elapse immediately
        async.elapse(const Duration(milliseconds: 120));
        throttle.push(makeFrame(40.0));
        expect(emitted, [10.0, 30.0, 40.0]);

        throttle.dispose();
      });
    });

    test('dispose cancels pending throttle and prevents further emission', () {
      fakeAsync((async) {
        final emitted = <double>[];
        final throttle = HudRenderThrottle(
          interval: const Duration(milliseconds: 100),
          onRender: (frame) => emitted.add(frame.speedKmh.value!),
        );

        throttle.push(makeFrame(10.0));
        expect(emitted, [10.0]);

        // Push pending frame
        async.elapse(const Duration(milliseconds: 20));
        throttle.push(makeFrame(20.0));

        // Dispose before timer fires
        throttle.dispose();

        // Elapse past interval
        async.elapse(const Duration(milliseconds: 150));

        // Frame 20.0 must never be emitted
        expect(emitted, [10.0]);
      });
    });
  });
}
