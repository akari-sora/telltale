import '../../adaptive/adaptive_layout.dart';

/// Layout decisions for the PID manager screen across foldable and adaptive
/// window classes.
abstract final class PidManagerLayout {
  /// Target fixed width for the master PID list pane in a two-pane layout.
  static const double masterWidth = 400;

  /// Returns true when the PID manager should present a master-detail two-pane
  /// layout instead of a single-pane list.
  ///
  /// Contract:
  /// - Horizontal separating hinge (tabletop/flip) forces single-pane.
  /// - Vertical separating hinge (book posture) enables two-pane regardless of
  ///   window class.
  /// - Expanded window class (usable width >= 840) enables two-pane when no
  ///   horizontal separator exists.
  static bool useTwoPane(AdaptiveLayout layout) {
    if (layout.hasHorizontalSeparator) {
      return false;
    }

    return layout.hasVerticalSeparator || layout.isExpanded;
  }
}
