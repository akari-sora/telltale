import '../../adaptive/adaptive_layout.dart';

/// Layout decisions for Performance screen across foldable and adaptive window classes.
abstract final class PerformanceLayout {
  /// Target fixed width for the primary cockpit / controls pane in a two-pane layout.
  static const double primaryWidth = 400.0;

  /// Returns true when the performance screen should present a two-pane
  /// layout instead of a single-pane scroll view.
  ///
  /// Contract:
  /// - Horizontal separating hinge forces single-pane.
  /// - Vertical separating hinge enables two-pane regardless of window class.
  /// - Expanded window class (usable width >= 840) enables two-pane when no
  ///   horizontal separator exists.
  static bool useTwoPane(AdaptiveLayout layout) {
    if (layout.hasHorizontalSeparator) {
      return false;
    }

    return layout.hasVerticalSeparator || layout.isExpanded;
  }
}
