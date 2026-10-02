/// Unit tests for [DashboardGridLayout].
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/ui/screens/dashboard/dashboard_grid_layout.dart';

void main() {
  group('DashboardGridLayout.columnsForWidth', () {
    const minTileWidth = 156.0;
    const spacing = Spacing.md; // 16.0

    test('wide display clamps to maxColumns (6)', () {
      expect(
        DashboardGridLayout.columnsForWidth(
          width: 2000,
          minTileWidth: minTileWidth,
          spacing: spacing,
        ),
        6,
      );
      expect(
        DashboardGridLayout.columnsForWidth(
          width: 4000,
          minTileWidth: minTileWidth,
          spacing: spacing,
        ),
        6,
      );
    });

    test('tiny or non-positive width returns minimum 1 column', () {
      expect(
        DashboardGridLayout.columnsForWidth(
          width: 50,
          minTileWidth: minTileWidth,
          spacing: spacing,
        ),
        1,
      );
      expect(
        DashboardGridLayout.columnsForWidth(
          width: 0,
          minTileWidth: minTileWidth,
          spacing: spacing,
        ),
        1,
      );
      expect(
        DashboardGridLayout.columnsForWidth(
          width: -100,
          minTileWidth: minTileWidth,
          spacing: spacing,
        ),
        1,
      );
    });

    test('spacing-aware thresholds: exactly fits N columns vs 1px below', () {
      // 2 columns requires: 2 * minWidth + 1 * spacing = 312 + 16 = 328
      const exact2Cols = 2 * minTileWidth + 1 * spacing;
      expect(
        DashboardGridLayout.columnsForWidth(
          width: exact2Cols,
          minTileWidth: minTileWidth,
          spacing: spacing,
        ),
        2,
      );
      expect(
        DashboardGridLayout.columnsForWidth(
          width: exact2Cols - 1,
          minTileWidth: minTileWidth,
          spacing: spacing,
        ),
        1,
      );

      // 3 columns requires: 3 * minWidth + 2 * spacing = 468 + 32 = 500
      const exact3Cols = 3 * minTileWidth + 2 * spacing;
      expect(
        DashboardGridLayout.columnsForWidth(
          width: exact3Cols,
          minTileWidth: minTileWidth,
          spacing: spacing,
        ),
        3,
      );
      expect(
        DashboardGridLayout.columnsForWidth(
          width: exact3Cols - 1,
          minTileWidth: minTileWidth,
          spacing: spacing,
        ),
        2,
      );

      // 6 columns requires: 6 * minWidth + 5 * spacing = 936 + 80 = 1016
      const exact6Cols = 6 * minTileWidth + 5 * spacing;
      expect(
        DashboardGridLayout.columnsForWidth(
          width: exact6Cols,
          minTileWidth: minTileWidth,
          spacing: spacing,
        ),
        6,
      );
      expect(
        DashboardGridLayout.columnsForWidth(
          width: exact6Cols - 1,
          minTileWidth: minTileWidth,
          spacing: spacing,
        ),
        5,
      );
    });

    test('text scaling reduces column count at the same width', () {
      const width = 600.0;
      final normalCols = DashboardGridLayout.columnsForWidth(
        width: width,
        minTileWidth: minTileWidth,
        spacing: spacing,
      );
      // Double text scale doubles minTileWidth
      final largeTextCols = DashboardGridLayout.columnsForWidth(
        width: width,
        minTileWidth: minTileWidth * 2,
        spacing: spacing,
      );

      expect(normalCols, 3);
      expect(largeTextCols, 1);
      expect(largeTextCols, lessThan(normalCols));
    });

    test('pane cap clamps to maxColumnsPerHingePane (3)', () {
      expect(
        DashboardGridLayout.columnsForWidth(
          width: 2000,
          minTileWidth: minTileWidth,
          spacing: spacing,
          maxColumns: DashboardGridLayout.maxColumnsPerHingePane,
        ),
        3,
      );
    });
  });

  group('DashboardGridLayout.stableSplitIndex', () {
    test('splits evenly for even counts and assigns extra to left for odd', () {
      expect(DashboardGridLayout.stableSplitIndex(0), 0);
      expect(DashboardGridLayout.stableSplitIndex(1), 1);
      expect(DashboardGridLayout.stableSplitIndex(2), 1);
      expect(DashboardGridLayout.stableSplitIndex(3), 2);
      expect(DashboardGridLayout.stableSplitIndex(4), 2);
      expect(DashboardGridLayout.stableSplitIndex(5), 3);
      expect(DashboardGridLayout.stableSplitIndex(6), 3);
      expect(DashboardGridLayout.stableSplitIndex(7), 4);
      expect(DashboardGridLayout.stableSplitIndex(8), 4);
      expect(DashboardGridLayout.stableSplitIndex(12), 6);
    });
  });
}
