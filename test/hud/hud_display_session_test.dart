import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/hud/hud_display_platform.dart';
import 'package:torque_obd/hud/hud_display_session.dart';
import 'package:torque_obd/hud/hud_settings.dart';

class MockHudDisplayPlatform implements HudDisplayPlatform {
  final List<double?> calls = [];
  final List<bool> systemBarsCalls = [];

  @override
  Future<void> setBrightnessOverride(double? value) async {
    calls.add(value);
  }

  @override
  Future<void> setSystemBarsHidden(bool hidden) async {
    systemBarsCalls.add(hidden);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HudDisplaySession', () {
    Completer<void>? blockOrientation;
    Completer<void>? blockSystemUi;

    final systemChromeCalls = <MethodCall>[];

    setUp(() {
      blockOrientation = null;
      blockSystemUi = null;
      systemChromeCalls.clear();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          systemChromeCalls.add(call);
          if (call.method == 'SystemChrome.setPreferredOrientations') {
            final c = blockOrientation;
            if (c != null) {
              blockOrientation = null;
              await c.future;
            }
          } else if (call.method == 'SystemChrome.setEnabledSystemUIMode' ||
              call.method == 'SystemChrome.setEnabledSystemUIOverlays') {
            final c = blockSystemUi;
            if (c != null) {
              blockSystemUi = null;
              await c.future;
            }
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('linear lifecycle progression works idempotently with verified SystemChrome call order', () async {
      final platform = MockHudDisplayPlatform();
      final session = HudDisplaySession(platform: platform);

      expect(session.state, HudSessionState.idle);

      // 1. Enter Night (0.30)
      await session.enter(
        brightnessPreset: HudBrightnessPreset.night,
        orientationMode: HudOrientationMode.landscape,
      );
      expect(session.state, HudSessionState.active);
      expect(platform.calls, [0.30]);
      expect(platform.systemBarsCalls, [true], reason: 'System bars must be hidden on enter');

      // Verify enter sequence: orientation -> system UI -> brightness override
      final enterOrientations = systemChromeCalls
          .where((c) => c.method == 'SystemChrome.setPreferredOrientations')
          .last;
      expect(enterOrientations.arguments, equals([
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]));

      final enterUi = systemChromeCalls
          .where((c) => c.method == 'SystemChrome.setEnabledSystemUIMode')
          .last;
      expect(enterUi.arguments, equals('SystemUiMode.immersiveSticky'));

      // 2. Suspend
      await session.onAppSuspended();
      expect(session.state, HudSessionState.suspended);
      expect(platform.calls, [0.30, null]);

      // 3. Resume
      await session.onAppResumed();
      expect(session.state, HudSessionState.active);
      expect(platform.calls, [0.30, null, 0.30]);
      expect(platform.systemBarsCalls, [true, true], reason: 'System bars must re-hide on resume');

      // 4. Exit
      await session.exit();
      expect(session.state, HudSessionState.idle);
      expect(platform.calls, [0.30, null, 0.30, null]);
      expect(platform.systemBarsCalls, [true, true, false], reason: 'System bars must be restored on exit');

      // Verify exit sequence and restoration:
      // Last orientation call must be unconstrained []
      final exitOrientations = systemChromeCalls
          .where((c) => c.method == 'SystemChrome.setPreferredOrientations')
          .last;
      expect(exitOrientations.arguments, equals([]));

      // Last system UI call must be edgeToEdge
      final exitUi = systemChromeCalls
          .where((c) => c.method == 'SystemChrome.setEnabledSystemUIMode')
          .last;
      expect(exitUi.arguments, equals('SystemUiMode.edgeToEdge'));

      // 5. Idempotent duplicate exit does not re-invoke platform when already idle
      final callsAfterFirstExit = systemChromeCalls.length;
      await session.exit();
      expect(session.state, HudSessionState.idle);
      expect(platform.calls, [0.30, null, 0.30, null]);
      expect(systemChromeCalls.length, equals(callsAfterFirstExit),
          reason: 'Duplicate exit on idle session must be a no-op');
    });

    test('Race 1: enter pending (blocked at orientation) -> exit completed -> resume old enter does NOT apply brightness', () async {
      final platform = MockHudDisplayPlatform();
      final session = HudDisplaySession(platform: platform);

      // 1. Block orientation call during enter
      final completer = Completer<void>();
      blockOrientation = completer;

      final enterFuture = session.enter(
        brightnessPreset: HudBrightnessPreset.night,
        orientationMode: HudOrientationMode.landscape,
      );

      // Let event loop reach the blocked orientation call
      await Future<void>.delayed(Duration.zero);
      expect(platform.calls, isEmpty); // Has not reached brightness yet

      // 2. User exits HUD while enter is still blocked
      await session.exit();
      expect(session.state, HudSessionState.idle);
      expect(platform.calls, [null]);

      // 3. Unblock orientation
      completer.complete();
      await enterFuture;

      // Invariant: Stale enter must abort, session remains idle, brightness remains null!
      expect(session.state, HudSessionState.idle);
      expect(platform.calls, [null]);
    });

    test('Race 2: enter pending -> app paused -> old enter does NOT apply brightness to backgrounded app', () async {
      final platform = MockHudDisplayPlatform();
      final session = HudDisplaySession(platform: platform);

      final completer = Completer<void>();
      blockOrientation = completer;

      final enterFuture = session.enter(
        brightnessPreset: HudBrightnessPreset.boost,
        orientationMode: HudOrientationMode.landscape,
      );

      await Future<void>.delayed(Duration.zero);
      expect(platform.calls, isEmpty);

      // App paused mid-enter
      await session.onAppSuspended();
      expect(session.state, HudSessionState.suspended);
      expect(platform.calls, [null]);

      completer.complete();
      await enterFuture;

      // Invariant: Stale enter must abort; brightness remains null for backgrounded app
      expect(session.state, HudSessionState.suspended);
      expect(platform.calls, [null]);
    });

    test('Race 3: resume pending -> app paused again -> final observed brightness is null', () async {
      final platform = MockHudDisplayPlatform();
      final session = HudDisplaySession(platform: platform);

      await session.enter(
        brightnessPreset: HudBrightnessPreset.medium,
        orientationMode: HudOrientationMode.landscape,
      );
      await session.onAppSuspended();
      expect(platform.calls, [0.55, null]);

      // Block resume at orientation
      final completer = Completer<void>();
      blockOrientation = completer;
      final resumeFuture = session.onAppResumed();

      await Future<void>.delayed(Duration.zero);

      // App paused again before resume finishes
      await session.onAppSuspended();
      expect(platform.calls.last, isNull);

      completer.complete();
      await resumeFuture;

      // Invariant: Final brightness MUST be null, session remains suspended
      expect(session.state, HudSessionState.suspended);
      expect(platform.calls.last, isNull);
    });

    test('Race 4: resume pending -> route dispose exit -> restores system defaults', () async {
      final platform = MockHudDisplayPlatform();
      final session = HudDisplaySession(platform: platform);

      await session.enter(
        brightnessPreset: HudBrightnessPreset.night,
        orientationMode: HudOrientationMode.landscape,
      );
      await session.onAppSuspended();

      // Block resume at orientation
      final completer = Completer<void>();
      blockOrientation = completer;
      final resumeFuture = session.onAppResumed();

      await Future<void>.delayed(Duration.zero);

      // Route dispose exit
      await session.exit();
      expect(session.state, HudSessionState.idle);
      expect(platform.calls.last, isNull);

      completer.complete();
      await resumeFuture;

      expect(session.state, HudSessionState.idle);
      expect(platform.calls.last, isNull);
    });

    test('Race 5: overlapping double exit completes idempotently with final null brightness', () async {
      final platform = MockHudDisplayPlatform();
      final session = HudDisplaySession(platform: platform);

      await session.enter(
        brightnessPreset: HudBrightnessPreset.night,
        orientationMode: HudOrientationMode.landscape,
      );

      final exit1 = session.exit();
      final exit2 = session.exit();

      await Future.wait([exit1, exit2]);

      expect(session.state, HudSessionState.idle);
      expect(platform.calls.last, isNull);
    });

    test('Race 6: Route ticket ownership - delayed dispose of route A does NOT kill active route B', () async {
      final platform = MockHudDisplayPlatform();
      final session = HudDisplaySession(platform: platform);

      // Route A enters with ticket 101
      await session.enter(
        ticket: 101,
        brightnessPreset: HudBrightnessPreset.night,
        orientationMode: HudOrientationMode.landscape,
      );
      expect(session.activeRouteTicket, 101);
      expect(session.state, HudSessionState.active);

      // Route B enters with ticket 102
      await session.enter(
        ticket: 102,
        brightnessPreset: HudBrightnessPreset.boost,
        orientationMode: HudOrientationMode.landscape,
      );
      expect(session.activeRouteTicket, 102);
      expect(session.state, HudSessionState.active);

      // Stale Route A delayed dispose calls exit(ticket: 101)
      await session.exit(ticket: 101);

      // Invariant: Route B is NOT affected!
      expect(session.activeRouteTicket, 102);
      expect(session.state, HudSessionState.active);
      expect(platform.calls.last, 1.00); // Boost brightness preserved!

      // Correct Route B disposal exits cleanly
      await session.exit(ticket: 102);
      expect(session.state, HudSessionState.idle);
      expect(platform.calls.last, isNull);
    });

    test('Race 7: enter pending (blocked at SystemChrome) -> exit completed -> unblocked enter does NOT issue native hide', () async {
      final platform = MockHudDisplayPlatform();
      final session = HudDisplaySession(platform: platform);

      // 1. Block SystemUi during enter
      final completer = Completer<void>();
      blockSystemUi = completer;

      final enterFuture = session.enter(
        brightnessPreset: HudBrightnessPreset.night,
        orientationMode: HudOrientationMode.landscape,
      );

      // Advance event loop to reach the blocked SystemChrome call
      await Future<void>.delayed(Duration.zero);
      expect(platform.systemBarsCalls, isEmpty, reason: 'Must not call setSystemBarsHidden before SystemChrome completes');

      // 2. User exits HUD while enter is blocked at SystemChrome
      await session.exit();
      expect(session.state, HudSessionState.idle);
      expect(platform.calls, [null]);
      expect(platform.systemBarsCalls, [false], reason: 'Exit must restore system bars');

      // 3. Unblock SystemChrome
      completer.complete();
      await enterFuture;

      // Invariant: Stale enter must abort, session remains idle, bars remain false (no late hide(true) added!)
      expect(session.state, HudSessionState.idle);
      expect(platform.calls.last, isNull);
      expect(platform.systemBarsCalls, [false], reason: 'Stale enter must NOT issue late hide(true)');
    });

    test('Race 8: resume pending (blocked at SystemChrome) -> exit completed -> unblocked resume does NOT issue native hide', () async {
      final platform = MockHudDisplayPlatform();
      final session = HudDisplaySession(platform: platform);

      await session.enter(
        brightnessPreset: HudBrightnessPreset.night,
        orientationMode: HudOrientationMode.landscape,
      );
      expect(platform.systemBarsCalls, [true]);

      await session.onAppSuspended();
      expect(session.state, HudSessionState.suspended);

      // Block SystemUi during resume
      final completer = Completer<void>();
      blockSystemUi = completer;

      final resumeFuture = session.onAppResumed();
      await Future<void>.delayed(Duration.zero);

      // User exits HUD while resume is blocked at SystemChrome
      await session.exit();
      expect(session.state, HudSessionState.idle);
      expect(platform.systemBarsCalls, [true, false]);

      // Unblock SystemChrome
      completer.complete();
      await resumeFuture;

      // Invariant: Session remains idle, bars remain false, no trailing hide(true)
      expect(session.state, HudSessionState.idle);
      expect(platform.calls.last, isNull);
      expect(platform.systemBarsCalls, [true, false], reason: 'Stale resume must NOT append hide(true)');
    });
  });
}
