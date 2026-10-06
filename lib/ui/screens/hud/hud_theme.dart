/// Design system, colors, and typography rules for HUD presentation.
///
/// Guidelines:
/// - Background is always pure #000000 (OLED battery efficiency & glare minimization).
/// - High contrast single-hue vector theme (Green, Amber, Ice Blue).
/// - No drop shadows, gradients, or decorative glassmorphism chrome.
/// - Tabular figures enabled on all numerical digits to prevent layout jitter.
library;

import 'package:flutter/material.dart';
import '../../../hud/hud_settings.dart';

@immutable
class HudColorSet {
  /// Dominant high-contrast primary display color.
  final Color primary;

  /// Lower-intensity secondary color for units, labels, and secondary gauges.
  final Color secondary;

  /// De-emphasized color for inactive or unpopulated elements.
  final Color dim;

  /// High-visibility warning / alert color.
  final Color alert;

  const HudColorSet({
    required this.primary,
    required this.secondary,
    required this.dim,
    required this.alert,
  });
}

abstract final class HudTheme {
  /// Pure black background for night HUD windshield reflection.
  static const Color background = Color(0xFF000000);

  /// Classic high-contrast HUD green.
  static const HudColorSet green = HudColorSet(
    primary: Color(0xFF00FF66),
    secondary: Color(0xFF00CC52),
    dim: Color(0xFF1B4726),
    alert: Color(0xFFFF3B30),
  );

  /// Warm flight-deck amber.
  static const HudColorSet amber = HudColorSet(
    primary: Color(0xFFFFB000),
    secondary: Color(0xFFCC8D00),
    dim: Color(0xFF4A3608),
    alert: Color(0xFFFF3B30),
  );

  /// Cold high-legibility ice blue.
  static const HudColorSet iceBlue = HudColorSet(
    primary: Color(0xFF00E5FF),
    secondary: Color(0xFF00B4CC),
    dim: Color(0xFF0B3A42),
    alert: Color(0xFFFF3B30),
  );

  /// Resolves the active [HudColorSet] for a given [HudThemePalette].
  static HudColorSet colorsOf(HudThemePalette palette) {
    switch (palette) {
      case HudThemePalette.green:
        return green;
      case HudThemePalette.amber:
        return amber;
      case HudThemePalette.iceBlue:
        return iceBlue;
    }
  }

  /// Base text style with tabular numbers enabled.
  static TextStyle baseStyle({
    required Color color,
    double fontSize = 16.0,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: 0.5,
      decoration: TextDecoration.none,
    );
  }
}
