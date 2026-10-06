/// User preferences and configuration state for HUD mode.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported high-contrast color palettes for HUD projection.
enum HudThemePalette {
  /// Classic aviation HUD green (#00FF66).
  green,

  /// Warm amber (#FFB000).
  amber,

  /// High-visibility cold ice blue (#00E5FF).
  iceBlue,
}

/// Screen brightness preset modes.
enum HudBrightnessPreset {
  /// Retains normal system brightness policy (null / -1 on Android).
  system,

  /// Night windshield mode (0.30 screen brightness).
  night,

  /// Medium ambient mode (0.55 screen brightness).
  medium,

  /// Explicit high-glare boost mode (1.00 screen brightness).
  boost,
}

/// Extension providing numeric brightness overrides for each preset.
extension HudBrightnessPresetExtension on HudBrightnessPreset {
  /// Window-level brightness override factor (0.0 to 1.0), or null to restore system brightness.
  double? get brightnessValue {
    switch (this) {
      case HudBrightnessPreset.system:
        return null;
      case HudBrightnessPreset.night:
        return 0.30;
      case HudBrightnessPreset.medium:
        return 0.55;
      case HudBrightnessPreset.boost:
        return 1.00;
    }
  }
}

/// Desired device orientation while in HUD viewing mode.
enum HudOrientationMode {
  /// Respects system / sensor rotation.
  auto,

  /// Standard landscape viewing mode (default).
  landscape,

  /// Vertical / portrait mounting mode.
  portrait,
}

/// Immutable configuration settings for HUD viewing mode.
@immutable
class HudSettings {
  final HudThemePalette palette;
  final HudBrightnessPreset brightnessPreset;
  final HudOrientationMode orientationMode;
  final bool mirrored;

  const HudSettings({
    this.palette = HudThemePalette.green,
    this.brightnessPreset = HudBrightnessPreset.system,
    this.orientationMode = HudOrientationMode.landscape,
    this.mirrored = true,
  });

  HudSettings copyWith({
    HudThemePalette? palette,
    HudBrightnessPreset? brightnessPreset,
    HudOrientationMode? orientationMode,
    bool? mirrored,
  }) {
    return HudSettings(
      palette: palette ?? this.palette,
      brightnessPreset: brightnessPreset ?? this.brightnessPreset,
      orientationMode: orientationMode ?? this.orientationMode,
      mirrored: mirrored ?? this.mirrored,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HudSettings &&
          runtimeType == other.runtimeType &&
          palette == other.palette &&
          brightnessPreset == other.brightnessPreset &&
          orientationMode == other.orientationMode &&
          mirrored == other.mirrored;

  @override
  int get hashCode =>
      Object.hash(palette, brightnessPreset, orientationMode, mirrored);

  @override
  String toString() =>
      'HudSettings(palette: $palette, brightness: $brightnessPreset, orientation: $orientationMode, mirrored: $mirrored)';
}

/// State notifier managing HUD user preferences.
class HudSettingsNotifier extends Notifier<HudSettings> {
  @override
  HudSettings build() => const HudSettings();

  void setPalette(HudThemePalette palette) {
    if (state.palette != palette) {
      state = state.copyWith(palette: palette);
    }
  }

  void setBrightnessPreset(HudBrightnessPreset preset) {
    if (state.brightnessPreset != preset) {
      state = state.copyWith(brightnessPreset: preset);
    }
  }

  void setOrientationMode(HudOrientationMode mode) {
    if (state.orientationMode != mode) {
      state = state.copyWith(orientationMode: mode);
    }
  }

  void toggleMirrored() {
    state = state.copyWith(mirrored: !state.mirrored);
  }

  void setMirrored(bool value) {
    if (state.mirrored != value) {
      state = state.copyWith(mirrored: value);
    }
  }
}

/// Global provider exposing HUD preferences.
final hudSettingsProvider =
    NotifierProvider<HudSettingsNotifier, HudSettings>(
  HudSettingsNotifier.new,
);
