/// Tests for [HudPreflightDialog] flow and layout adaptability under short landscape
/// and high text scaling conditions, ensuring hit-testing and navigation integrity.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:torque_obd/hud/hud_controller.dart';
import 'package:torque_obd/hud/hud_display_platform.dart';
import 'package:torque_obd/hud/hud_frame.dart';
import 'package:torque_obd/ui/screens/hud/hud_preflight_dialog.dart';
import 'package:torque_obd/ui/screens/hud/hud_screen.dart';

class _MockPlatform implements HudDisplayPlatform {
  final List<double?> calls = [];

  @override
  Future<void> setBrightnessOverride(double? value) async {
    calls.add(value);
  }

  @override
  Future<void> setSystemBarsHidden(bool hidden) async {}
}

class _StaticFrameNotifier extends HudFrameNotifier {
  @override
  HudFrame build() {
    return const HudFrame(
      speedKmh: HudValue.live(90.0),
      rpm: HudValue.live(3000.0),
      coolantC: HudValue.live(90.0),
      connected: true,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestRouterApp({
    required _MockPlatform platform,
    required Size size,
    required double textScale,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const ValueKey('launch-preflight-btn'),
                onPressed: () => HudPreflightDialog.show(context),
                child: const Text('OPEN PREFLIGHT'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/hud',
          builder: (context, state) => const HudScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        hudDisplayPlatformProvider.overrideWithValue(platform),
        currentHudFrameProvider.overrideWith(_StaticFrameNotifier.new),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
      ),
    );
  }

  group('HUD Preflight Dialog Adaptability & Navigation Matrix', () {
    final viewports = <Size>[
      const Size(800.0, 360.0), // Short landscape (primary stress test)
      const Size(800.0, 480.0), // Standard landscape
      const Size(390.0, 844.0), // Standard portrait
    ];
    final textScales = <double>[1.0, 1.3];

    for (final size in viewports) {
      for (final scale in textScales) {
        testWidgets(
            'viewport ${size.width.toInt()}x${size.height.toInt()} textScale $scale: renders without overflow and START HUD is clickable',
            (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final platform = _MockPlatform();
          await tester.pumpWidget(
            buildTestRouterApp(platform: platform, size: size, textScale: scale),
          );
          await tester.pumpAndSettle();

          // 1. Open Preflight Dialog from host screen
          await tester.tap(find.byKey(const ValueKey('launch-preflight-btn')));
          await tester.pumpAndSettle();

          // 2. Dialog is visible with 0 RenderFlex overflow
          expect(find.byType(HudPreflightDialog), findsOneWidget);
          expect(tester.takeException(), isNull,
              reason: 'Preflight dialog must not overflow on ${size.width}x${size.height} textScale $scale');

          // 3. START HUD button is strictly visible, hittable, and not obstructed
          final startBtnFinder = find.byKey(const ValueKey('start-hud-btn'));
          expect(startBtnFinder, findsOneWidget);

          // 4. Tap START HUD and verify navigation into /hud
          await tester.tap(startBtnFinder);
          await tester.pumpAndSettle();

          // 5. Preflight is dismissed and HudScreen is now active
          expect(find.byType(HudPreflightDialog), findsNothing);
          expect(find.byType(HudScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('Cancel button dismisses preflight dialog without navigating to /hud', (tester) async {
      final platform = _MockPlatform();
      await tester.pumpWidget(
        buildTestRouterApp(
          platform: platform,
          size: const Size(800.0, 360.0),
          textScale: 1.0,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('launch-preflight-btn')));
      await tester.pumpAndSettle();

      expect(find.byType(HudPreflightDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(HudPreflightDialog), findsNothing);
      expect(find.byType(HudScreen), findsNothing);
    });
  });
}
