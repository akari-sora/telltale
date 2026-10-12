import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:torque_obd/core/startup_system_chrome.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  final styles = <SystemUiOverlayStyle>[];

  void mock(Future<Object?> Function(MethodCall call)? handler) {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      handler,
    );
  }

  setUp(() {
    calls.clear();
    styles.clear();
  });

  tearDown(() => mock(null));

  test(
    'a headless platform reply cannot block startup past the deadline',
    () async {
      final neverReplies = Completer<Object?>();
      mock((call) {
        calls.add(call);
        return neverReplies.future;
      });

      await configureStartupSystemChrome(
        orientationTimeout: const Duration(milliseconds: 20),
        overlayStyleSetter: styles.add,
      ).timeout(const Duration(seconds: 1));

      expect(calls.single.method, 'SystemChrome.setPreferredOrientations');
      expect(styles, hasLength(1));
    },
  );

  test(
    'a normal platform reply preserves the requested orientations',
    () async {
      mock((call) async {
        calls.add(call);
        return null;
      });

      await configureStartupSystemChrome(overlayStyleSetter: styles.add);

      expect(calls.single.method, 'SystemChrome.setPreferredOrientations');
      expect(calls.single.arguments, [
        'DeviceOrientation.portraitUp',
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]);
      expect(styles.single.statusBarColor, const Color(0x00000000));
      expect(styles.single.systemNavigationBarColor, const Color(0x00000000));
    },
  );

  test('a platform rejection falls through to the overlay style', () async {
    mock((call) async {
      calls.add(call);
      throw PlatformException(code: 'activity_unavailable');
    });

    await configureStartupSystemChrome(overlayStyleSetter: styles.add);

    expect(calls.single.method, 'SystemChrome.setPreferredOrientations');
    expect(styles, hasLength(1));
  });

  test('a missing plugin falls through to the overlay style', () async {
    mock(null);

    await configureStartupSystemChrome(overlayStyleSetter: styles.add);

    expect(styles, hasLength(1));
  });
}
