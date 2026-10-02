import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/ui/adaptive/adaptive_layout.dart';
import 'package:torque_obd/ui/screens/pids/pid_manager_layout.dart';

void main() {
  group('PidManagerLayout policy', () {
    test('masterWidth is 400', () {
      expect(PidManagerLayout.masterWidth, 400.0);
    });

    test('F03-01: compact width (<600) uses single pane', () {
      final layout = AdaptiveLayout.fromValues(
        size: const Size(599, 800),
        displayFeatures: const [],
      );

      expect(layout.isCompact, isTrue);
      expect(PidManagerLayout.useTwoPane(layout), isFalse);
    });

    test('F03-02: medium width (600–839) uses single pane', () {
      final lowerMedium = AdaptiveLayout.fromValues(
        size: const Size(600, 800),
        displayFeatures: const [],
      );
      final upperMedium = AdaptiveLayout.fromValues(
        size: const Size(839, 800),
        displayFeatures: const [],
      );

      expect(lowerMedium.isMedium, isTrue);
      expect(PidManagerLayout.useTwoPane(lowerMedium), isFalse);

      expect(upperMedium.isMedium, isTrue);
      expect(PidManagerLayout.useTwoPane(upperMedium), isFalse);
    });

    test('F03-03: expanded width (>=840) uses two pane', () {
      final boundaryExpanded = AdaptiveLayout.fromValues(
        size: const Size(840, 800),
        displayFeatures: const [],
      );
      final wideExpanded = AdaptiveLayout.fromValues(
        size: const Size(1200, 900),
        displayFeatures: const [],
      );

      expect(boundaryExpanded.isExpanded, isTrue);
      expect(PidManagerLayout.useTwoPane(boundaryExpanded), isTrue);

      expect(wideExpanded.isExpanded, isTrue);
      expect(PidManagerLayout.useTwoPane(wideExpanded), isTrue);
    });

    test('F03-04: vertical separating hinge uses two pane regardless of width', () {
      // 700 width is medium, but has vertical hinge -> two pane
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

      expect(layout.isMedium, isTrue);
      expect(layout.hasVerticalSeparator, isTrue);
      expect(PidManagerLayout.useTwoPane(layout), isTrue);
    });

    test('F03-05: horizontal hinge on expanded display forces single pane', () {
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

      expect(layout.isExpanded, isTrue);
      expect(layout.hasHorizontalSeparator, isTrue);
      expect(PidManagerLayout.useTwoPane(layout), isFalse);
    });
  });
}
