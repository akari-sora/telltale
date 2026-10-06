import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/hud/hud_settings.dart';

void main() {
  group('HudBrightnessPreset', () {
    test('resolves correct numeric brightness overrides', () {
      expect(HudBrightnessPreset.system.brightnessValue, isNull);
      expect(HudBrightnessPreset.night.brightnessValue, 0.30);
      expect(HudBrightnessPreset.medium.brightnessValue, 0.55);
      expect(HudBrightnessPreset.boost.brightnessValue, 1.00);
    });
  });

  group('HudSettingsNotifier', () {
    test('initial state matches defaults', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final settings = container.read(hudSettingsProvider);
      expect(settings.palette, HudThemePalette.green);
      expect(settings.brightnessPreset, HudBrightnessPreset.system);
      expect(settings.orientationMode, HudOrientationMode.landscape);
      expect(settings.mirrored, isTrue, reason: 'HUD default mirrored must be ON (true) for windshield reflection');
    });

    test('state transitions for palette, brightness, orientation, and mirror', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(hudSettingsProvider.notifier);

      notifier.setPalette(HudThemePalette.iceBlue);
      expect(container.read(hudSettingsProvider).palette, HudThemePalette.iceBlue);

      notifier.setBrightnessPreset(HudBrightnessPreset.night);
      expect(
        container.read(hudSettingsProvider).brightnessPreset,
        HudBrightnessPreset.night,
      );

      notifier.setOrientationMode(HudOrientationMode.portrait);
      expect(
        container.read(hudSettingsProvider).orientationMode,
        HudOrientationMode.portrait,
      );

      // Default is true; toggle makes it false
      notifier.toggleMirrored();
      expect(container.read(hudSettingsProvider).mirrored, isFalse);

      notifier.setMirrored(true);
      expect(container.read(hudSettingsProvider).mirrored, isTrue);
    });
  });
}
