/// Pure layout calculation helpers for dashboard gauge grids.
///
/// Handles column clamping (maximum 6 columns, maximum 3 columns per pane
/// on vertical hinge foldables), spacing-aware width-to-column calculations,
/// and stable contiguous PID splitting across panes.
library;

/// Pure layout calculations for dashboard gauge displays.
abstract final class DashboardGridLayout {
  /// Maximum columns on any standard or unfolded display.
  static const int maxColumns = 6;

  /// Maximum columns per pane when separated by a vertical hinge.
  static const int maxColumnsPerHingePane = 3;

  /// Computes the number of columns that fit within [width] while guaranteeing
  /// that each tile is at least [minTileWidth] wide, factoring in [spacing].
  ///
  /// The formula `((width + spacing) / (minTileWidth + spacing)).floor()`
  /// ensures tiles never shrink below [minTileWidth] even with cross-axis
  /// spacing between them. The result is clamped to `[1, maxColumns]`.
  static int columnsForWidth({
    required double width,
    required double minTileWidth,
    required double spacing,
    int maxColumns = DashboardGridLayout.maxColumns,
  }) {
    if (width <= 0) return 1;

    final natural =
        ((width + spacing) / (minTileWidth + spacing))
            .floor();

    return natural.clamp(1, maxColumns);
  }

  /// Calculates the split index for [itemCount] items across two panes.
  ///
  /// Always assigns the extra item to the primary (left) pane when
  /// [itemCount] is odd: `(itemCount + 1) ~/ 2`.
  static int stableSplitIndex(int itemCount) =>
      (itemCount + 1) ~/ 2;
}
