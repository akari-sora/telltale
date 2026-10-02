/// Layout constants and decisions for Connection Wizard across foldable
/// and adaptive window classes.
///
/// Contract:
/// - Single linear workflow: never split across two columns or two panes.
/// - Centered content width constrained to [maxContentWidth] on medium/expanded windows.
/// - When a physical separating hinge is present, the wizard is strictly placed
///   in the primary physical region to prevent hinge obstruction.
library;

abstract final class ConnectLayout {
  /// Maximum readable width for the single connection wizard scroll view.
  static const double maxContentWidth = 600.0;
}
