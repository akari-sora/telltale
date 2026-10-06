/// Widget tests for [HudScreen] verifying layout integrity, themes, text scaling,
/// tabular figure stability, and PopScope lifecycle exit.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/hud/hud_controller.dart';
import 'package:torque_obd/hud/hud_display_platform.dart';
import 'package:torque_obd/hud/hud_display_session.dart';
import 'package:torque_obd/hud/hud_frame.dart';
import 'package:torque_obd/hud/hud_settings.dart';
import 'package:torque_obd/ui/screens/hud/hud_screen.dart';
import 'package:torque_obd/ui/screens/hud/hud_theme.dart';

class MockPlatform implements HudDisplayPlatform {
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

class TestHudFrameNotifier extends HudFrameNotifier {
  final HudFrame initial;

  TestHudFrameNotifier([this.initial = const HudFrame.empty()]);

  @override
  HudFrame build() => initial;

  void emit(HudFrame frame) {
    state = frame;
  }
}

class TestSettingsNotifier extends HudSettingsNotifier {
  final HudSettings initial;
  TestSettingsNotifier(this.initial);

  @override
  HudSettings build() => initial;

  void updateSettings(HudSettings settings) {
    state = settings;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HudScreen Comprehensive Acceptance Matrix', () {
    testWidgets('renders 3-digit speed (188) and handles themes without overflow', (tester) async {
      final mockPlatform = MockPlatform();
      late TestHudFrameNotifier notifier;

      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hudDisplayPlatformProvider.overrideWithValue(mockPlatform),
            currentHudFrameProvider.overrideWith(() {
              notifier = TestHudFrameNotifier(
                const HudFrame(
                  speedKmh: HudValue.live(188.0),
                  rpm: HudValue.live(4500.0),
                  coolantC: HudValue.live(95.0),
                  connected: true,
                ),
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: HudScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify 3-digit speed and units rendered without overflow
      expect(find.text('188'), findsOneWidget);
      expect(find.text('km/h'), findsOneWidget);
      expect(find.text('4500'), findsOneWidget);
      expect(find.text('95'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Stale/Disconnected message rendering
      notifier.emit(
        const HudFrame(
          speedKmh: HudValue.missing(),
          rpm: HudValue.missing(),
          coolantC: HudValue.missing(),
          connected: false,
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('--'), findsNWidgets(3));
      expect(find.text('DISCONNECTED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('multi-theme and multi-orientation rendering with zero overflow across textScale 1.0 and 1.3',
        (tester) async {
      final mockPlatform = MockPlatform();

      // Test matrix: [Portrait 480x800, Landscape 800x480] x [scale 1.0, scale 1.3] x [Green, Amber, Ice Blue]
      final orientations = [
        const Size(800, 480), // Landscape
        const Size(480, 800), // Portrait
      ];
      final scales = [1.0, 1.3];
      final palettes = [
        HudThemePalette.green,
        HudThemePalette.amber,
        HudThemePalette.iceBlue,
      ];

      for (final size in orientations) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        for (final scale in scales) {
          for (final palette in palettes) {
            await tester.pumpWidget(
              ProviderScope(
                key: UniqueKey(),
                overrides: [
                  hudDisplayPlatformProvider.overrideWithValue(mockPlatform),
                  hudSettingsProvider.overrideWith(
                    () => TestSettingsNotifier(HudSettings(palette: palette)),
                  ),
                  currentHudFrameProvider.overrideWith(
                    () => TestHudFrameNotifier(
                      const HudFrame(
                        speedKmh: HudValue.live(120.0),
                        rpm: HudValue.live(3500.0),
                        coolantC: HudValue.live(89.0),
                        connected: true,
                      ),
                    ),
                  ),
                ],
                child: MaterialApp(
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: size,
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: const HudScreen(),
                  ),
                ),
              ),
            );

            await tester.pumpAndSettle();

            // Zero overflow guarantee
            expect(tester.takeException(), isNull,
                reason: 'Overflow detected at size $size, scale $scale, palette $palette');

            // Metric values rendered
            expect(find.text('120'), findsOneWidget);
            expect(find.text('3500'), findsOneWidget);
            expect(find.text('89'), findsOneWidget);

            // Palette color verified
            final speedText = tester.widget<Text>(find.text('120'));
            final expectedColor = HudTheme.colorsOf(palette).primary;
            expect(speedText.style?.color, equals(expectedColor),
                reason: 'Speed text must use primary color of $palette');
          }
        }
      }
    });

    testWidgets('tabular figures stability: 88 to 188 transition preserves horizontal center and vertical layout',
        (tester) async {
      final mockPlatform = MockPlatform();
      late TestHudFrameNotifier notifier;

      tester.view.physicalSize = const Size(800, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hudDisplayPlatformProvider.overrideWithValue(mockPlatform),
            currentHudFrameProvider.overrideWith(() {
              notifier = TestHudFrameNotifier(
                const HudFrame(
                  speedKmh: HudValue.live(88.0),
                  rpm: HudValue.live(2200.0),
                  coolantC: HudValue.live(85.0),
                  connected: true,
                ),
              );
              return notifier;
            }),
          ],
          child: const MaterialApp(
            home: HudScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial 2-digit measurement
      final speed88Rect = tester.getRect(find.text('88'));
      final rpm88Rect = tester.getRect(find.text('2200'));
      final coolant88Rect = tester.getRect(find.text('85'));

      // Center X must be anchored around screen center (400.0)
      expect(speed88Rect.center.dx, closeTo(400.0, 5.0));

      // Transition to 3-digit speed (188)
      notifier.emit(
        const HudFrame(
          speedKmh: HudValue.live(188.0),
          rpm: HudValue.live(2200.0),
          coolantC: HudValue.live(85.0),
          connected: true,
        ),
      );
      await tester.pumpAndSettle();

      final speed188Rect = tester.getRect(find.text('188'));
      final rpm188Rect = tester.getRect(find.text('2200'));
      final coolant188Rect = tester.getRect(find.text('85'));

      // Horizontal center is strictly maintained at screen center (400.0)
      expect(speed188Rect.center.dx, closeTo(400.0, 5.0));

      // Vertical secondary metrics position is strictly stable (0 layout jitter)
      expect(rpm188Rect.top, equals(rpm88Rect.top));
      expect(coolant188Rect.top, equals(coolant88Rect.top));
    });

    testWidgets('HUD-R2-04: Popping HudScreen with Night/Boost preset restores brightness(null), SystemUI, orientations [], and idle state',
        (tester) async {
      final mockPlatform = MockPlatform();
      final systemChromeCalls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        systemChromeCalls.add(call);
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hudDisplayPlatformProvider.overrideWithValue(mockPlatform),
            hudSettingsProvider.overrideWith(
              () => TestSettingsNotifier(
                const HudSettings(
                  brightnessPreset: HudBrightnessPreset.night, // 0.30 screen brightness
                  orientationMode: HudOrientationMode.landscape,
                ),
              ),
            ),
            currentHudFrameProvider.overrideWith(
              () => TestHudFrameNotifier(
                const HudFrame(
                  speedKmh: HudValue.live(60.0),
                  rpm: HudValue.live(2000.0),
                  coolantC: HudValue.live(85.0),
                  connected: true,
                ),
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return MaterialApp(
                home: Builder(
                  builder: (context) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HudScreen()),
                        );
                      },
                      child: const Text('OPEN_HUD'),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // 1. Open HUD screen with Night (0.30) preset
      await tester.tap(find.text('OPEN_HUD'));
      await tester.pumpAndSettle();
      expect(find.byType(HudScreen), findsOneWidget);

      final session = container.read(hudDisplaySessionProvider);
      expect(session.state, equals(HudSessionState.active));

      // HUD-R2-04: Verify entry set a NON-NULL brightness override (0.30)
      expect(mockPlatform.brightnessCalls.isNotEmpty, isTrue);
      expect(mockPlatform.brightnessCalls.last, equals(0.30),
          reason: 'Entry must apply Night preset non-null brightness (0.30)');

      final callsCountBeforeExit = mockPlatform.brightnessCalls.length;

      // 2. Dispatch real framework Back event (via handlePopRoute)
      final handled = await tester.binding.handlePopRoute();
      expect(handled, isTrue, reason: 'Framework system Back must be consumed by active route');
      await tester.pumpAndSettle();

      // 3. HudScreen is popped, returned to caller
      expect(find.byType(HudScreen), findsNothing);
      expect(find.text('OPEN_HUD'), findsOneWidget);

      // HUD-R2-04: Verify exit added a new call restoring brightness to null and system bars restored
      expect(mockPlatform.brightnessCalls.length, greaterThan(callsCountBeforeExit));
      expect(mockPlatform.brightnessCalls.last, isNull,
          reason: 'Back exit must append brightness override restoration to null');
      expect(mockPlatform.systemBarsCalls.last, isFalse,
          reason: 'Back exit must restore native system bars');

      // Verify session returns to idle
      expect(session.state, equals(HudSessionState.idle));

      // HUD-R2-04: Verify SystemChrome calls restored edgeToEdge and unconstrained orientations []
      final orientationCalls = systemChromeCalls
          .where((c) => c.method == 'SystemChrome.setPreferredOrientations')
          .toList();
      expect(orientationCalls.isNotEmpty, isTrue);
      expect(orientationCalls.last.arguments, equals([]),
          reason: 'Exit must restore preferred orientations to empty list []');

      final systemUiCalls = systemChromeCalls
          .where((c) =>
              c.method == 'SystemChrome.setEnabledSystemUIMode' ||
              c.method == 'SystemChrome.setEnabledSystemUIOverlays')
          .toList();
      expect(systemUiCalls.isNotEmpty, isTrue);
      expect(systemUiCalls.last.arguments, equals('SystemUiMode.edgeToEdge'),
          reason: 'Exit must restore system UI to edgeToEdge');
    });

    testWidgets('HUD-R2-04: Pause -> Resume -> Back pop cycle preserves clean restoration',
        (tester) async {
      final mockPlatform = MockPlatform();
      final systemChromeCalls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        systemChromeCalls.add(call);
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            hudDisplayPlatformProvider.overrideWithValue(mockPlatform),
            hudSettingsProvider.overrideWith(
              () => TestSettingsNotifier(
                const HudSettings(
                  brightnessPreset: HudBrightnessPreset.boost, // 1.00 brightness
                  orientationMode: HudOrientationMode.landscape,
                ),
              ),
            ),
            currentHudFrameProvider.overrideWith(
              () => TestHudFrameNotifier(
                const HudFrame(
                  speedKmh: HudValue.live(100.0),
                  rpm: HudValue.live(3000.0),
                  coolantC: HudValue.live(90.0),
                  connected: true,
                ),
              ),
            ),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return MaterialApp(
                home: Builder(
                  builder: (context) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HudScreen()),
                        );
                      },
                      child: const Text('OPEN_HUD'),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('OPEN_HUD'));
      await tester.pumpAndSettle();

      final session = container.read(hudDisplaySessionProvider);
      expect(session.state, equals(HudSessionState.active));
      expect(mockPlatform.brightnessCalls.last, equals(1.00));

      // 1. Simulate App Pause (Background)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      expect(session.state, equals(HudSessionState.suspended));
      expect(mockPlatform.brightnessCalls.last, isNull,
          reason: 'App pause must immediately suspend brightness override to null');

      // 2. Simulate App Resume (Foreground)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(session.state, equals(HudSessionState.active));
      expect(mockPlatform.brightnessCalls.last, equals(1.00),
          reason: 'App resume must re-apply active Boost preset (1.00)');

      // 3. Dispatch Back pop after resume (via framework handlePopRoute)
      final handled = await tester.binding.handlePopRoute();
      expect(handled, isTrue, reason: 'Framework system Back must be consumed by active route');
      await tester.pumpAndSettle();

      expect(find.byType(HudScreen), findsNothing);
      expect(session.state, equals(HudSessionState.idle));
      expect(mockPlatform.brightnessCalls.last, isNull,
          reason: 'Back pop after resume must restore brightness to null');
      expect(mockPlatform.systemBarsCalls.last, isFalse,
          reason: 'Back pop after resume must restore native system bars');
    });
  });
}
