import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/hud/hud_controller.dart';
import 'package:torque_obd/hud/hud_display_platform.dart';
import 'package:torque_obd/hud/hud_frame.dart';
import 'package:torque_obd/hud/hud_settings.dart';
import 'package:torque_obd/ui/screens/hud/hud_control_overlay.dart';
import 'package:torque_obd/ui/screens/hud/hud_screen.dart';
import 'package:torque_obd/ui/screens/hud/hud_viewport.dart';

class TestMockHudDisplayPlatform implements HudDisplayPlatform {
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

class StaticHudFrameNotifier extends HudFrameNotifier {
  @override
  HudFrame build() {
    return const HudFrame(
      speedKmh: HudValue.live(88.0),
      rpm: HudValue.live(3000.0),
      coolantC: HudValue.live(92.0),
      connected: true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHudScreenApp({
    required TestMockHudDisplayPlatform platform,
    HudSettings? initialSettings,
    VoidCallback? onPopped,
    bool disableAnimations = false,
  }) {
    return ProviderScope(
      overrides: [
        hudDisplayPlatformProvider.overrideWithValue(platform),
        hudSettingsProvider.overrideWith(
          () => _TestSettingsNotifier(initialSettings ?? const HudSettings(mirrored: true)),
        ),
        currentHudFrameProvider.overrideWith(StaticHudFrameNotifier.new),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HudScreen()),
                ).then((_) => onPopped?.call());
              },
              child: const Text('LAUNCH'),
            ),
          ),
        ),
      ),
    );
  }

  group('HUD Real Screen Touch Isolation & P1/P2 Safety Gate', () {
    testWidgets('mounts REAL HudScreen: viewport is actively wrapped in IgnorePointer and mirrored', (tester) async {
      final platform = TestMockHudDisplayPlatform();
      await tester.pumpWidget(
        buildHudScreenApp(platform: platform, initialSettings: const HudSettings(mirrored: true)),
      );

      // Launch real HudScreen
      await tester.tap(find.text('LAUNCH'));
      await tester.pumpAndSettle();

      // 1. Verify Real HudScreen renders HudViewport wrapped in Transform + IgnorePointer
      final ignorePointerFinder = find.ancestor(
        of: find.byType(HudViewport),
        matching: find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring),
      );
      expect(ignorePointerFinder, findsOneWidget);

      final transformFinder = find.ancestor(
        of: find.byType(HudViewport),
        matching: find.byWidgetPredicate((w) {
          if (w is! Transform) return false;
          // Verify horizontal mirror: m00 == -1.0, m11 == 1.0
          final storage = w.transform.storage;
          return storage[0] == -1.0 && storage[5] == 1.0;
        }),
      );
      expect(transformFinder, findsOneWidget);

      // 2. Control overlay sits outside the mirror transform
      final overlayTransform = find.ancestor(
        of: find.byType(HudControlOverlay),
        matching: find.byType(Transform),
      );
      expect(overlayTransform, findsNothing);
    });

    testWidgets('P1 Audit: short taps on active HUD surface never modify settings, brightness, or navigation', (tester) async {
      final platform = TestMockHudDisplayPlatform();
      bool popped = false;

      await tester.pumpWidget(
        buildHudScreenApp(
          platform: platform,
          onPopped: () => popped = true,
          initialSettings: const HudSettings(
            mirrored: true,
            palette: HudThemePalette.green,
            brightnessPreset: HudBrightnessPreset.night,
          ),
        ),
      );

      await tester.tap(find.text('LAUNCH'));
      await tester.pumpAndSettle();

      final initialBrightnessCalls = List<double?>.from(platform.brightnessCalls);

      // 1. Short tap on driving speed number (center screen)
      await tester.tap(find.text('88'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      // 2. Short tap on top-right corner where options/mirror used to live
      await tester.tapAt(const Offset(760.0, 30.0));
      await tester.pump(const Duration(milliseconds: 100));

      // 3. Short tap on Exit button (< 700ms)
      await tester.tap(find.text('HOLD TO EXIT'));
      await tester.pump(const Duration(milliseconds: 200));

      // Assert Invariants:
      // - Route was NOT popped
      expect(popped, isFalse);
      // - Settings remain 100% unchanged
      final container = ProviderScope.containerOf(tester.element(find.byType(HudScreen)));
      final currentSettings = container.read(hudSettingsProvider);
      expect(currentSettings.mirrored, isTrue);
      expect(currentSettings.palette, HudThemePalette.green);
      expect(currentSettings.brightnessPreset, HudBrightnessPreset.night);
      // - No unwanted brightness calls issued
      expect(platform.brightnessCalls, initialBrightnessCalls);
    });

    for (final disableAnimations in [false, true]) {
      group('HUD Exit Gesture (disableAnimations: $disableAnimations)', () {
        testWidgets('100ms and exact 699ms releases do NOT trigger exit', (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(disableAnimations: disableAnimations);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          expect(SemanticsBinding.instance.disableAnimations, equals(disableAnimations));

          final platform = TestMockHudDisplayPlatform();
          bool popped = false;

          await tester.pumpWidget(
            buildHudScreenApp(
              platform: platform,
              onPopped: () => popped = true,
              disableAnimations: disableAnimations,
            ),
          );
          await tester.tap(find.text('LAUNCH'));
          await tester.pumpAndSettle();

          final exitTarget = find.text('HOLD TO EXIT');

          // Case 1: 100ms early release (< 700ms)
          final g1 = await tester.startGesture(tester.getCenter(exitTarget));
          await tester.pump(const Duration(milliseconds: 100));
          await g1.up();
          await tester.pump(const Duration(milliseconds: 100));
          expect(popped, isFalse, reason: '100ms release must not trigger exit');

          // Case 2: Exact 699ms release (< 700ms boundary)
          final g2 = await tester.startGesture(tester.getCenter(exitTarget));
          await tester.pump(const Duration(milliseconds: 699));
          await g2.up();
          await tester.pump(const Duration(milliseconds: 100));
          expect(popped, isFalse, reason: 'Exact 699ms release must not trigger exit');
        });

        testWidgets('valid 700ms long-press triggers exit exactly once', (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(disableAnimations: disableAnimations);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          expect(SemanticsBinding.instance.disableAnimations, equals(disableAnimations));

          int popCount = 0;
          final platform = TestMockHudDisplayPlatform();

          await tester.pumpWidget(
            buildHudScreenApp(
              platform: platform,
              onPopped: () => popCount++,
              disableAnimations: disableAnimations,
            ),
          );
          await tester.tap(find.text('LAUNCH'));
          await tester.pumpAndSettle();

          final exitTarget = find.text('HOLD TO EXIT');

          final g = await tester.startGesture(tester.getCenter(exitTarget));
          // Advance full 700ms to trigger exit timer
          await tester.pump(const Duration(milliseconds: 700));
          await g.up();
          await tester.pumpAndSettle();

          expect(popCount, equals(1), reason: 'Valid 700ms hold must exit exactly once');
          expect(platform.brightnessCalls.last, isNull, reason: 'Brightness must be restored on exit');
          expect(platform.systemBarsCalls.last, isFalse, reason: 'System bars must be restored on exit');
        });

        testWidgets('drag-outside and pointer cancel abort exit qualification', (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(disableAnimations: disableAnimations);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          expect(SemanticsBinding.instance.disableAnimations, equals(disableAnimations));

          final platform = TestMockHudDisplayPlatform();
          bool popped = false;

          await tester.pumpWidget(
            buildHudScreenApp(
              platform: platform,
              onPopped: () => popped = true,
              disableAnimations: disableAnimations,
            ),
          );
          await tester.tap(find.text('LAUNCH'));
          await tester.pumpAndSettle();

          final exitTarget = find.text('HOLD TO EXIT');

          // Sub-case A: Drag finger outside exit button boundary
          final gDrag = await tester.startGesture(tester.getCenter(exitTarget));
          await tester.pump(const Duration(milliseconds: 300));
          // Move 200 logical pixels away into screen center
          await gDrag.moveTo(const Offset(400.0, 300.0));
          await tester.pump(const Duration(milliseconds: 500)); // Total hold 800ms > 700ms
          await gDrag.up();
          await tester.pump(const Duration(milliseconds: 100));
          expect(popped, isFalse, reason: 'Dragging outside exit button must abort exit');

          // Sub-case B: Pointer cancel event
          final gCancel = await tester.startGesture(tester.getCenter(exitTarget));
          await tester.pump(const Duration(milliseconds: 300));
          await gCancel.cancel();
          await tester.pump(const Duration(milliseconds: 500)); // Total elapsed > 700ms
          expect(popped, isFalse, reason: 'Pointer cancel must abort exit');
        });

        testWidgets('Active Pointer Locking: secondary pointer within exit button (up & cancel) is ignored', (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(disableAnimations: disableAnimations);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          expect(SemanticsBinding.instance.disableAnimations, equals(disableAnimations));

          final platform = TestMockHudDisplayPlatform();
          int popCount = 0;

          await tester.pumpWidget(
            buildHudScreenApp(
              platform: platform,
              onPopped: () => popCount++,
              disableAnimations: disableAnimations,
            ),
          );
          await tester.tap(find.text('LAUNCH'));
          await tester.pumpAndSettle();

          final exitTarget = find.text('HOLD TO EXIT');
          final exitCenter = tester.getCenter(exitTarget);

          // Sub-case A: Secondary pointer up inside exit button hitbox
          final gPrimary1 = await tester.startGesture(exitCenter, pointer: 1);
          await tester.pump(const Duration(milliseconds: 100));

          final gSecondary1 = await tester.startGesture(exitCenter + const Offset(8.0, 0.0), pointer: 2);
          await tester.pump(const Duration(milliseconds: 200));

          // Secondary finger releases inside exit button; must NOT reset primary exit timer
          await gSecondary1.up();

          await tester.pump(const Duration(milliseconds: 400));
          await gPrimary1.up();
          await tester.pumpAndSettle();

          expect(popCount, equals(1), reason: 'Secondary pointer up must not interfere with primary finger exit');

          // Sub-case B: Secondary pointer cancel inside exit button hitbox
          await tester.tap(find.text('LAUNCH'));
          await tester.pumpAndSettle();

          final gPrimary2 = await tester.startGesture(exitCenter, pointer: 3);
          await tester.pump(const Duration(milliseconds: 100));

          final gSecondary2 = await tester.startGesture(exitCenter + const Offset(8.0, 0.0), pointer: 4);
          await tester.pump(const Duration(milliseconds: 200));

          // Secondary finger receives cancel; must NOT reset primary exit timer
          await gSecondary2.cancel();

          await tester.pump(const Duration(milliseconds: 400));
          await gPrimary2.up();
          await tester.pumpAndSettle();

          expect(popCount, equals(2), reason: 'Secondary pointer cancel must not interfere with primary finger exit');
        });

        testWidgets('disposing overlay during pending 700ms timer cleans up safely without leaks or late calls (up event)', (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(disableAnimations: disableAnimations);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          expect(SemanticsBinding.instance.disableAnimations, equals(disableAnimations));

          final platform = TestMockHudDisplayPlatform();
          bool popped = false;

          await tester.pumpWidget(
            buildHudScreenApp(
              platform: platform,
              onPopped: () => popped = true,
              disableAnimations: disableAnimations,
            ),
          );
          await tester.tap(find.text('LAUNCH'));
          await tester.pumpAndSettle();

          final exitTarget = find.text('HOLD TO EXIT');

          // Press down, pump frame to initialize ticker, then pump 300ms so progress > 0
          final g = await tester.startGesture(tester.getCenter(exitTarget));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Unmount HudScreen by pumping an empty SizedBox
          await tester.pumpWidget(const SizedBox());

          // Primary pointer up after unmount/dispose
          await g.up();
          await tester.pump(const Duration(milliseconds: 500));

          expect(tester.takeException(), isNull, reason: 'Pointer up on unmounted overlay must not trigger controller errors');
          expect(popped, isFalse, reason: 'Disposed overlay must not fire onExitRequested');
        });

        testWidgets('disposing overlay during pending 700ms timer cleans up safely without leaks or late calls (cancel event)', (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              FakeAccessibilityFeatures(disableAnimations: disableAnimations);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          expect(SemanticsBinding.instance.disableAnimations, equals(disableAnimations));

          final platform = TestMockHudDisplayPlatform();
          bool popped = false;

          await tester.pumpWidget(
            buildHudScreenApp(
              platform: platform,
              onPopped: () => popped = true,
              disableAnimations: disableAnimations,
            ),
          );
          await tester.tap(find.text('LAUNCH'));
          await tester.pumpAndSettle();

          final exitTarget = find.text('HOLD TO EXIT');

          // Press down, pump frame to initialize ticker, then pump 300ms so progress > 0
          final g = await tester.startGesture(tester.getCenter(exitTarget));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Unmount HudScreen by pumping an empty SizedBox
          await tester.pumpWidget(const SizedBox());

          // Primary pointer cancel after unmount/dispose
          await g.cancel();
          await tester.pump(const Duration(milliseconds: 500));

          expect(tester.takeException(), isNull, reason: 'Pointer cancel on unmounted overlay must not trigger controller errors');
          expect(popped, isFalse, reason: 'Disposed overlay must not fire onExitRequested');
        });
      });
    }
  });
}

class _TestSettingsNotifier extends HudSettingsNotifier {
  final HudSettings _initial;
  _TestSettingsNotifier(this._initial);

  @override
  HudSettings build() => _initial;
}
