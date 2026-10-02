/// Adaptive layout data computed from [MediaQuery] once per frame.
///
/// Every screen that needs to adapt to window size, display features,
/// or hinge presence should read [AdaptiveLayout.of] instead of
/// scattering raw [MediaQuery] calls throughout the widget tree.
library;

import 'dart:ui' show DisplayFeature, DisplayFeatureType;

import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';

/// Immutable snapshot of the current window's adaptive properties.
///
/// Constructed via [AdaptiveLayout.of] which reads [MediaQuery] once
/// and derives all adaptive decisions. Screens then branch on
/// [windowClass], [hasSeparatingFeature], [isShortLandscape], etc.
@immutable
class AdaptiveLayout {
  /// Creates an [AdaptiveLayout] from pre-computed values.
  const AdaptiveLayout({
    required this.size,
    required this.windowClass,
    required this.displayFeatures,
    required this.separatingFeature,
    required this.regions,
  });

  /// Reads [MediaQuery] and computes all adaptive properties.
  ///
  /// This is the primary entry point. Call it at the top of `build`:
  /// ```dart
  /// final layout = AdaptiveLayout.of(context);
  /// ```
  factory AdaptiveLayout.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final features = MediaQuery.displayFeaturesOf(context);
    final windowClass = AppBreakpoints.widthClass(size.width);

    // Find the first obstructing feature that actually separates the
    // window into two usable halves (spans nearly the full height or
    // width).
    DisplayFeature? separator;
    for (final f in features) {
      if (_isObstructing(f) && _isSeparating(f, size)) {
        separator = f;
        break;
      }
    }

    // Compute usable regions. When there is no separator the entire
    // window is one region. When a vertical separator exists we get
    // left + right; horizontal gives top + bottom.
    final regions = _computeRegions(separator, size);

    return AdaptiveLayout(
      size: size,
      windowClass: windowClass,
      displayFeatures: features,
      separatingFeature: separator,
      regions: regions,
    );
  }

  /// The logical size of the app window.
  final Size size;

  /// Material 3 width class derived from [size].
  final AppWindowClass windowClass;

  /// All display features reported by the platform (hinges, folds,
  /// cutouts).
  final List<DisplayFeature> displayFeatures;

  /// A hinge or cutout that physically splits the usable display area.
  ///
  /// Null when the display is uninterrupted or the feature is too
  /// small to be considered a separator.
  final DisplayFeature? separatingFeature;

  /// Usable rectangles in logical window coordinates.
  ///
  /// Typically one element for normal displays, two when
  /// [separatingFeature] is present.
  final List<Rect> regions;

  // ── Convenience getters ───────────────────────────────────────────

  /// True when [windowClass] is [AppWindowClass.compact].
  bool get isCompact => windowClass == AppWindowClass.compact;

  /// True when [windowClass] is [AppWindowClass.medium].
  bool get isMedium => windowClass == AppWindowClass.medium;

  /// True when [windowClass] is [AppWindowClass.expanded].
  bool get isExpanded => windowClass == AppWindowClass.expanded;

  /// True when there is a physical separator (hinge/cutout) that
  /// splits the display.
  bool get hasSeparatingFeature => separatingFeature != null;

  /// True when the separator splits the display vertically (left|right).
  bool get hasVerticalSeparator =>
      separatingFeature != null &&
      separatingFeature!.bounds.height >= size.height * 0.9;

  /// True when the separator splits the display horizontally (top/bottom).
  bool get hasHorizontalSeparator =>
      separatingFeature != null &&
      separatingFeature!.bounds.width >= size.width * 0.9;

  /// True when the window is landscape with very limited vertical
  /// space — the typical vehicle-mounted scenario.
  bool get isShortLandscape =>
      size.width > size.height &&
      size.height < AppBreakpoints.shortLandscapeHeight;

  // ── Private helpers ───────────────────────────────────────────────

  /// Returns `true` for display features that represent a physical
  /// obstruction (content cannot be rendered there).
  static bool _isObstructing(DisplayFeature feature) {
    return feature.type == DisplayFeatureType.hinge ||
        feature.type == DisplayFeatureType.cutout;
  }

  /// A feature is "separating" if it spans nearly the full height
  /// (vertical separator) or nearly the full width (horizontal
  /// separator). This is more robust than comparing width vs height
  /// of the feature bounds.
  static bool _isSeparating(DisplayFeature feature, Size windowSize) {
    final bounds = feature.bounds;
    final isVertical = bounds.height >= windowSize.height * 0.9;
    final isHorizontal = bounds.width >= windowSize.width * 0.9;
    return isVertical || isHorizontal;
  }

  /// Computes usable rectangles by splitting around the separator.
  static List<Rect> _computeRegions(
    DisplayFeature? separator,
    Size windowSize,
  ) {
    if (separator == null) {
      return [Offset.zero & windowSize];
    }

    final bounds = separator.bounds;
    final isVertical = bounds.height >= windowSize.height * 0.9;

    if (isVertical) {
      // Left region | hinge | Right region
      return [
        Rect.fromLTWH(0, 0, bounds.left, windowSize.height),
        Rect.fromLTWH(
          bounds.right,
          0,
          windowSize.width - bounds.right,
          windowSize.height,
        ),
      ];
    } else {
      // Top region / hinge / Bottom region
      return [
        Rect.fromLTWH(0, 0, windowSize.width, bounds.top),
        Rect.fromLTWH(
          0,
          bounds.bottom,
          windowSize.width,
          windowSize.height - bounds.bottom,
        ),
      ];
    }
  }

  @override
  String toString() => 'AdaptiveLayout('
      'size: $size, '
      'class: $windowClass, '
      'separator: ${separatingFeature != null}, '
      'regions: ${regions.length}'
      ')';
}
