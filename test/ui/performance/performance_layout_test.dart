import "dart:ui" show DisplayFeature, DisplayFeatureState, DisplayFeatureType, Rect, Size;

import "package:flutter_test/flutter_test.dart";
import "package:torque_obd/ui/adaptive/adaptive_layout.dart";
import "package:torque_obd/ui/screens/performance/performance_layout.dart";

void main() {
  group("PerformanceLayout pure tests (FOLD-06)", () {
    test("F06-01: 599 width compact window yields single pane", () {
      final layout = AdaptiveLayout.fromValues(
        size: const Size(599, 800),
        displayFeatures: const [],
      );
      expect(PerformanceLayout.useTwoPane(layout), isFalse);
    });

    test("F06-02: 600–839 width medium window yields single pane", () {
      final layout600 = AdaptiveLayout.fromValues(
        size: const Size(600, 800),
        displayFeatures: const [],
      );
      final layout839 = AdaptiveLayout.fromValues(
        size: const Size(839, 800),
        displayFeatures: const [],
      );
      expect(PerformanceLayout.useTwoPane(layout600), isFalse);
      expect(PerformanceLayout.useTwoPane(layout839), isFalse);
    });

    test("F06-03: 840 width expanded window yields two-pane", () {
      final layout = AdaptiveLayout.fromValues(
        size: const Size(840, 800),
        displayFeatures: const [],
      );
      expect(PerformanceLayout.useTwoPane(layout), isTrue);
    });

    test("F06-04: Medium width with vertical separating hinge yields two-pane", () {
      final layout = AdaptiveLayout.fromValues(
        size: const Size(700, 800),
        displayFeatures: const [
          DisplayFeature(
            bounds: Rect.fromLTWH(340, 0, 20, 800),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );
      expect(layout.hasVerticalSeparator, isTrue);
      expect(PerformanceLayout.useTwoPane(layout), isTrue);
    });

    test("F06-05: Expanded width with horizontal separating hinge yields single pane", () {
      final layout = AdaptiveLayout.fromValues(
        size: const Size(1000, 800),
        displayFeatures: const [
          DisplayFeature(
            bounds: Rect.fromLTWH(0, 390, 1000, 20),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );
      expect(layout.hasHorizontalSeparator, isTrue);
      expect(PerformanceLayout.useTwoPane(layout), isFalse);
    });

    test("F06-06: Primary width is 400.0", () {
      expect(PerformanceLayout.primaryWidth, equals(400.0));
    });
  });
}
