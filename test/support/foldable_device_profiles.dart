/// Standard device and display feature profiles for foldable quality gate testing.
library;

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;
import 'package:flutter/material.dart';

/// Predefined device profile defining display metrics and environment parameters.
@immutable
class FoldableDeviceProfile {
  const FoldableDeviceProfile({
    required this.name,
    required this.size,
    this.displayFeatures = const [],
    this.safeInsets = EdgeInsets.zero,
    this.viewInsets = EdgeInsets.zero,
    this.textDirection = TextDirection.ltr,
    this.textScaler = TextScaler.noScaling,
    this.locale = const Locale('en'),
  });

  final String name;
  final Size size;
  final List<DisplayFeature> displayFeatures;
  final EdgeInsets safeInsets;
  final EdgeInsets viewInsets;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final Locale locale;

  FoldableDeviceProfile copyWith({
    String? name,
    Size? size,
    List<DisplayFeature>? displayFeatures,
    EdgeInsets? safeInsets,
    EdgeInsets? viewInsets,
    TextDirection? textDirection,
    TextScaler? textScaler,
    Locale? locale,
  }) {
    return FoldableDeviceProfile(
      name: name ?? this.name,
      size: size ?? this.size,
      displayFeatures: displayFeatures ?? this.displayFeatures,
      safeInsets: safeInsets ?? this.safeInsets,
      viewInsets: viewInsets ?? this.viewInsets,
      textDirection: textDirection ?? this.textDirection,
      textScaler: textScaler ?? this.textScaler,
      locale: locale ?? this.locale,
    );
  }
}

/// Standard logical device dimensions and form factors.
abstract final class FoldableDeviceProfiles {
  /// Galaxy Z Fold outer cover screen stress profile (~23:9 aspect ratio).
  static const narrowCover = FoldableDeviceProfile(
    name: 'Narrow Cover (320x818)',
    size: Size(320, 818),
  );

  /// Standard compact phone portrait.
  static const compactPortrait = FoldableDeviceProfile(
    name: 'Compact Portrait (360x800)',
    size: Size(360, 800),
  );

  /// Compact phone in landscape with height <= 480 dp (triggers NavigationRail).
  static const compactShortLandscape = FoldableDeviceProfile(
    name: 'Compact Short Landscape (568x320)',
    size: Size(568, 320),
  );

  /// Medium tablet / unfolded small tablet (600..839 dp width).
  static const medium = FoldableDeviceProfile(
    name: 'Medium (700x900)',
    size: Size(700, 900),
  );

  /// Unfolded inner display canonical baseline (>= 840 dp).
  static const expandedInner = FoldableDeviceProfile(
    name: 'Expanded Inner (1000x800)',
    size: Size(1000, 800),
  );

  /// Large tablet / desktop display.
  static const largeExpanded = FoldableDeviceProfile(
    name: 'Large Expanded (1200x900)',
    size: Size(1200, 900),
  );

  /// Galaxy Z Fold outer cover screen stress profile with Traditional Chinese locale.
  static const narrowCoverZh = FoldableDeviceProfile(
    name: 'Narrow Cover zh-Hant (320x818)',
    size: Size(320, 818),
    locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  );

  /// Expanded unfolded inner display with German locale and 2.0x font scale.
  static const expandedGermanA11y = FoldableDeviceProfile(
    name: 'Expanded German 2.0x (1000x800)',
    size: Size(1000, 800),
    displayFeatures: [verticalHalfOpenHinge],
    textScaler: TextScaler.linear(2.0),
    locale: Locale('de'),
  );

  /// Vertical separating hinge in fully flat posture (Book mode unfolded flat).
  static const verticalFlatHinge = DisplayFeature(
    bounds: Rect.fromLTWH(490, 0, 20, 800),
    type: DisplayFeatureType.hinge,
    state: DisplayFeatureState.postureFlat,
  );

  /// Vertical separating hinge in half-opened posture (Book mode dual screen).
  static const verticalHalfOpenHinge = DisplayFeature(
    bounds: Rect.fromLTWH(490, 0, 20, 800),
    type: DisplayFeatureType.hinge,
    state: DisplayFeatureState.postureHalfOpened,
  );

  /// Horizontal separating hinge in half-opened posture (Tabletop mode).
  static const tabletopHinge = DisplayFeature(
    bounds: Rect.fromLTWH(0, 390, 800, 20),
    type: DisplayFeatureType.hinge,
    state: DisplayFeatureState.postureHalfOpened,
  );

  /// Pure fold crease without physical obstruction (should NOT split layout).
  static const flatCrease = DisplayFeature(
    bounds: Rect.fromLTWH(490, 0, 20, 800),
    type: DisplayFeatureType.fold,
    state: DisplayFeatureState.postureFlat,
  );

  /// Asymmetric vertical separating hinge for testing region preference resolution.
  static const asymmetricVerticalHinge = DisplayFeature(
    bounds: Rect.fromLTWH(300, 0, 20, 800),
    type: DisplayFeatureType.hinge,
    state: DisplayFeatureState.postureHalfOpened,
  );
}
