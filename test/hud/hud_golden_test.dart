import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/hud/hud_frame.dart';
import 'package:torque_obd/hud/hud_settings.dart';
import 'package:torque_obd/ui/screens/hud/hud_theme.dart';
import 'package:torque_obd/ui/screens/hud/hud_viewport.dart';


String _goldenPath(String filename) {
  if (Platform.isLinux) {
    return '../goldens/hud/linux/$filename';
  }
  return '../goldens/hud/$filename';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const liveFrame = HudFrame(
    speedKmh: HudValue.live(88.0),
    rpm: HudValue.live(3000.0),
    coolantC: HudValue.live(92.0),
    connected: true,
  );

  const staleFrame = HudFrame(
    speedKmh: HudValue.stale(88.0),
    rpm: HudValue.stale(3000.0),
    coolantC: HudValue.stale(92.0),
    connected: true,
  );

  const missingFrame = HudFrame(
    speedKmh: HudValue.missing(),
    rpm: HudValue.missing(),
    coolantC: HudValue.missing(),
    connected: false,
  );

  Widget buildTarget({
    required HudFrame frame,
    required HudThemePalette palette,
    bool mirrored = false,
    Size size = const Size(800, 480),
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: HudTheme.background,
      ),
      home: Scaffold(
        backgroundColor: HudTheme.background,
        body: Center(
          child: RepaintBoundary(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Transform(
                alignment: Alignment.center,
                transform: mirrored
                    ? Matrix4.diagonal3Values(-1.0, 1.0, 1.0)
                    : Matrix4.identity(),
                child: HudViewport(
                  frame: frame,
                  palette: palette,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('HUD-01 Golden Acceptance Tests (HUD01-22 / 23)', () {
    testWidgets('landscape-green', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTarget(
          frame: liveFrame,
          palette: HudThemePalette.green,
          mirrored: false,
          size: const Size(800, 480),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile(_goldenPath('landscape-green.png')),
      );
    });

    testWidgets('landscape-green-mirrored', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTarget(
          frame: liveFrame,
          palette: HudThemePalette.green,
          mirrored: true,
          size: const Size(800, 480),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile(_goldenPath('landscape-green-mirrored.png')),
      );
    });

    testWidgets('landscape-amber', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTarget(
          frame: liveFrame,
          palette: HudThemePalette.amber,
          mirrored: false,
          size: const Size(800, 480),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile(_goldenPath('landscape-amber.png')),
      );
    });

    testWidgets('landscape-blue', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTarget(
          frame: liveFrame,
          palette: HudThemePalette.iceBlue,
          mirrored: false,
          size: const Size(800, 480),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile(_goldenPath('landscape-blue.png')),
      );
    });

    testWidgets('portrait-green', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTarget(
          frame: liveFrame,
          palette: HudThemePalette.green,
          mirrored: false,
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile(_goldenPath('portrait-green.png')),
      );
    });

    testWidgets('stale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTarget(
          frame: staleFrame,
          palette: HudThemePalette.green,
          mirrored: false,
          size: const Size(800, 480),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile(_goldenPath('stale.png')),
      );
    });

    testWidgets('missing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTarget(
          frame: missingFrame,
          palette: HudThemePalette.green,
          mirrored: false,
          size: const Size(800, 480),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile(_goldenPath('missing.png')),
      );
    });
  });
}
