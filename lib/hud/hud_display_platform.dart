/// Native platform bridge for HUD display controls (e.g. per-window brightness).
///
/// Rules:
/// - Only display control uses platform calls; telemetry does not.
/// - Does not modify system settings (no WRITE_SETTINGS permission).
/// - Android uses Window.attributes.screenBrightness (-1 to restore, 0.0..1.0 for override).
/// - Safe no-op on non-Android platforms or in unit test environments.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contract for controlling HUD screen display properties.
abstract interface class HudDisplayPlatform {
  /// Overrides the per-window screen brightness:
  /// - [value] between 0.0 and 1.0 sets explicit brightness.
  /// - [value] == null restores system automatic/user brightness policy.
  Future<void> setBrightnessOverride(double? value);

  /// Controls the platform system bars immersion (status & navigation bars).
  ///
  /// On Android 15/16 (API 35/36+), edge-to-edge enforcement causes Flutter's
  /// [SystemChrome.setEnabledSystemUIMode] to be ignored. This invokes the native
  /// Android [WindowInsetsControllerCompat] directly to guarantee immersive bars.
  Future<void> setSystemBarsHidden(bool hidden);
}

/// Default implementation communicating via MethodChannel.
class MethodChannelHudDisplayPlatform implements HudDisplayPlatform {
  static const MethodChannel _channel =
      MethodChannel('com.cbstudio.telltale/hud_display');

  const MethodChannelHudDisplayPlatform();

  @override
  Future<void> setBrightnessOverride(double? value) async {
    // Only Android currently implements per-window screen brightness override
    // without requiring WRITE_SETTINGS. Non-mobile or desktop targets safely ignore.
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('setBrightnessOverride', {
        'brightness': value,
      });
    } on MissingPluginException {
      // Ignored in unit tests or unsupported platforms.
    } on PlatformException {
      // Platform error handling; non-fatal display attribute fallback.
    }
  }

  @override
  Future<void> setSystemBarsHidden(bool hidden) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('setSystemBarsHidden', {
        'hidden': hidden,
      });
    } on MissingPluginException {
      // Ignored in unit tests or unsupported platforms.
    } on PlatformException {
      // Platform error handling; non-fatal display attribute fallback.
    }
  }
}

/// Provider exposing the current [HudDisplayPlatform] instance.
final hudDisplayPlatformProvider = Provider<HudDisplayPlatform>((ref) {
  return const MethodChannelHudDisplayPlatform();
});
