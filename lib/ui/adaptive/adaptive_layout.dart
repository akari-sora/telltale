/// Adaptive layout data computed from [MediaQuery] once per frame.
///
/// Every screen that needs to adapt to window size, display features,
/// or hinge presence should read [AdaptiveLayout.of] instead of
/// scattering raw [MediaQuery] calls throughout the widget tree.
library;

import 'dart:ui' show DisplayFeature, DisplayFeatureType;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';

/// An [InheritedWidget] providing an [AdaptiveLayout] to its subtree.
///
/// Used by shell and container widgets to expose content-viewport-localized
/// layouts to child screens when chrome (e.g. NavigationRail) consumes space.
class AdaptiveLayoutScope extends InheritedWidget {
  const AdaptiveLayoutScope({
    required this.layout,
    required super.child,
    super.key,
  });

  final AdaptiveLayout layout;

  static AdaptiveLayout? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AdaptiveLayoutScope>()
          ?.layout;

  @override
  bool updateShouldNotify(AdaptiveLayoutScope oldWidget) =>
      oldWidget.layout != layout;
}

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

  /// Computes adaptive properties from explicit size and display features.
  factory AdaptiveLayout.fromValues({
    required Size size,
    required List<DisplayFeature> displayFeatures,
  }) {
    final windowClass = AppBreakpoints.widthClass(size.width);

    DisplayFeature? separator;
    for (final f in displayFeatures) {
      if (_isObstructing(f) && _isSeparating(f, size)) {
        separator = f;
        break;
      }
    }

    final regions = _computeRegions(separator, size);

    return AdaptiveLayout(
      size: size,
      windowClass: windowClass,
      displayFeatures: displayFeatures,
      separatingFeature: separator,
      regions: regions,
    );
  }

  /// Reads [MediaQuery] or [AdaptiveLayoutScope] and computes adaptive properties.
  ///
  /// This is the primary entry point. Call it at the top of `build`:
  /// ```dart
  /// final layout = AdaptiveLayout.of(context);
  /// ```
  factory AdaptiveLayout.of(BuildContext context) {
    final scoped = AdaptiveLayoutScope.maybeOf(context);
    if (scoped != null) return scoped;

    return AdaptiveLayout.fromValues(
      size: MediaQuery.sizeOf(context),
      displayFeatures: MediaQuery.displayFeaturesOf(context),
    );
  }

  /// Projects this layout into a local [viewport] within the window.
  ///
  /// Used when child content does not occupy the full window (for example,
  /// when a [NavigationRail] occupies the left edge). Display features are
  /// clipped to the viewport, shifted to local coordinates (origin at
  /// `viewport.topLeft`), and adaptive regions/breakpoints are recomputed.
  AdaptiveLayout projectTo(Rect viewport) {
    final localSize = viewport.size;
    final localFeatures = <DisplayFeature>[];

    for (final feature in displayFeatures) {
      final intersection = feature.bounds.intersect(viewport);
      if (intersection.isEmpty) continue;

      localFeatures.add(
        DisplayFeature(
          bounds: intersection.shift(-viewport.topLeft),
          type: feature.type,
          state: feature.state,
        ),
      );
    }

    return AdaptiveLayout.fromValues(
      size: localSize,
      displayFeatures: localFeatures,
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveLayout &&
          runtimeType == other.runtimeType &&
          size == other.size &&
          windowClass == other.windowClass &&
          separatingFeature == other.separatingFeature &&
          listEquals(displayFeatures, other.displayFeatures) &&
          listEquals(regions, other.regions);

  @override
  int get hashCode => Object.hash(
        size,
        windowClass,
        separatingFeature,
        Object.hashAll(displayFeatures),
        Object.hashAll(regions),
      );

  @override
  String toString() => 'AdaptiveLayout('
      'size: $size, '
      'class: $windowClass, '
      'separator: ${separatingFeature != null}, '
      'regions: ${regions.length}'
      ')';
}
