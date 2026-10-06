import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/hud/hud_controller.dart';
import 'package:torque_obd/hud/hud_display_platform.dart';
import 'package:torque_obd/hud/hud_frame.dart';
import 'package:torque_obd/hud/hud_settings.dart';
import 'package:torque_obd/ui/screens/hud/hud_screen.dart';
import 'package:torque_obd/ui/screens/hud/hud_viewport.dart';

class _NoopPlatform implements HudDisplayPlatform {
  @override
  Future<void> setBrightnessOverride(double? value) async {}

  @override
  Future<void> setSystemBarsHidden(bool hidden) async {}
}

class _StaticFrameNotifier extends HudFrameNotifier {
  @override
  HudFrame build() {
    return const HudFrame(
      speedKmh: HudValue.live(105.0),
      rpm: HudValue.live(3200.0),
      coolantC: HudValue.live(90.0),
      connected: true,
    );
  }
}

class _SettingsOverrideNotifier extends HudSettingsNotifier {
  final bool _mirrored;
  _SettingsOverrideNotifier(this._mirrored);

  @override
  HudSettings build() => HudSettings(mirrored: _mirrored);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestHud({required bool mirrored}) {
    return ProviderScope(
      key: ValueKey('hud_test_$mirrored'),
      overrides: [
        hudDisplayPlatformProvider.overrideWithValue(_NoopPlatform()),
        hudSettingsProvider.overrideWith(() => _SettingsOverrideNotifier(mirrored)),
        currentHudFrameProvider.overrideWith(_StaticFrameNotifier.new),
      ],
      child: const MaterialApp(
        home: HudScreen(),
      ),
    );
  }

  group('HUD Real Screen Mirror Geometry Gate', () {
    testWidgets('mounts REAL HudScreen: validates exact Transform matrix values for mirrored vs normal', (tester) async {
      // 1. Mirrored = true
      await tester.pumpWidget(buildTestHud(mirrored: true));
      await tester.pumpAndSettle();

      final transformFinderMirrored = find.ancestor(
        of: find.byType(HudViewport),
        matching: find.byType(Transform),
      );
      expect(transformFinderMirrored, findsOneWidget);

      final transformWidgetMirrored = tester.widget<Transform>(transformFinderMirrored);
      final m = transformWidgetMirrored.transform.storage;

      // Mathematical contract: X is flipped (-1.0), Y is strictly preserved (+1.0), Z is +1.0
      expect(m[0], -1.0, reason: 'm00 (scaleX) must be -1.0 for horizontal reflection');
      expect(m[5], 1.0, reason: 'm11 (scaleY) must be strictly 1.0 (never invert vertical axis)');
      expect(m[10], 1.0, reason: 'm22 (scaleZ) must be 1.0');
      expect(transformWidgetMirrored.alignment, Alignment.center, reason: 'Reflection must be center-aligned');

      // 2. Mirrored = false
      await tester.pumpWidget(buildTestHud(mirrored: false));
      await tester.pumpAndSettle();

      final transformFinderNormal = find.ancestor(
        of: find.byType(HudViewport),
        matching: find.byType(Transform),
      );
      final transformWidgetNormal = tester.widget<Transform>(transformFinderNormal);
      final mNormal = transformWidgetNormal.transform.storage;

      expect(mNormal[0], 1.0, reason: 'm00 must be 1.0 when un-mirrored');
      expect(mNormal[5], 1.0, reason: 'm11 must remain 1.0');
    });

    testWidgets('mounts REAL HudScreen: element vertical positions are strictly identical between mirrored and normal', (tester) async {
      // Test at fixed 800x480 resolution
      tester.view.physicalSize = const Size(800.0, 480.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Normal mode measurements
      await tester.pumpWidget(buildTestHud(mirrored: false));
      await tester.pumpAndSettle();

      final speedNormalBox = tester.getRect(find.text('105'));
      final rpmNormalBox = tester.getRect(find.text('3200'));
      final coolantNormalBox = tester.getRect(find.text('90'));

      // Mirrored mode measurements
      await tester.pumpWidget(buildTestHud(mirrored: true));
      await tester.pumpAndSettle();

      final speedMirroredBox = tester.getRect(find.text('105'));
      final rpmMirroredBox = tester.getRect(find.text('3200'));
      final coolantMirroredBox = tester.getRect(find.text('90'));

      // Invariant: Y coordinates MUST be strictly identical between normal and mirrored
      expect(speedMirroredBox.top, equals(speedNormalBox.top));
      expect(speedMirroredBox.height, equals(speedNormalBox.height));

      expect(rpmMirroredBox.top, equals(rpmNormalBox.top));
      expect(coolantMirroredBox.top, equals(coolantNormalBox.top));

      // Invariant: Speed center X is preserved (since speed is center-aligned at screen center 400.0)
      expect(speedMirroredBox.center.dx, closeTo(400.0, 5.0));
      expect(speedNormalBox.center.dx, closeTo(400.0, 5.0));
    });
  });
}
