/// Widget tests for [DisplayFeatureLayout] and [AdaptiveTwoPane].
library;

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/ui/adaptive/adaptive_layout.dart';
import 'package:torque_obd/ui/adaptive/display_feature_layout.dart';

void main() {
  group('DisplayFeatureLayout', () {
    testWidgets('passes AdaptiveLayout to builder', (tester) async {
      late AdaptiveLayout received;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(600, 700)),
          child: DisplayFeatureLayout(
            builder: (context, layout) {
              received = layout;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(received.isMedium, isTrue);
      expect(received.size, const Size(600, 700));
    });
  });

  group('AdaptiveTwoPane', () {
    Widget buildTwoPane({
      required Size size,
      List<DisplayFeature> features = const [],
      double? primaryWidth,
      double primaryFraction = 0.4,
      TextDirection textDirection = TextDirection.ltr,
    }) {
      return MediaQuery(
        data: MediaQueryData(
          size: size,
          displayFeatures: features,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: AdaptiveTwoPane(
                  primaryWidth: primaryWidth,
                  primaryFraction: primaryFraction,
                  primary: Container(
                    key: const Key('primary'),
                    color: Colors.blue,
                  ),
                  secondary: Container(
                    key: const Key('secondary'),
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('normal expanded: no overflow', (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTwoPane(
        size: const Size(1000, 700),
        primaryWidth: 400,
      ));
      await tester.pump();

      // No RenderFlex overflow.
      expect(tester.takeException(), isNull);

      // Both children rendered.
      expect(find.byKey(const Key('primary')), findsOneWidget);
      expect(find.byKey(const Key('secondary')), findsOneWidget);
    });

    testWidgets('vertical hinge: panes on either side', (tester) async {
      const hingeLeft = 490.0;
      const hingeWidth = 20.0;

      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTwoPane(
        size: const Size(1000, 700),
        features: [
          const DisplayFeature(
            bounds: Rect.fromLTWH(hingeLeft, 0, hingeWidth, 700),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureFlat,
          ),
        ],
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);

      // Primary on the left, secondary on the right.
      final primaryBox = tester.getRect(find.byKey(const Key('primary')));
      final secondaryBox = tester.getRect(find.byKey(const Key('secondary')));

      expect(
        primaryBox.right,
        lessThanOrEqualTo(hingeLeft),
        reason: 'Primary must not extend into hinge',
      );
      expect(
        secondaryBox.left,
        greaterThanOrEqualTo(hingeLeft + hingeWidth),
        reason: 'Secondary must start after hinge',
      );
    });

    testWidgets(
        'vertical hinge in RTL: primary on right, secondary on left, no overlap',
        (tester) async {
      const hingeLeft = 490.0;
      const hingeWidth = 20.0;

      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTwoPane(
        size: const Size(1000, 700),
        features: [
          const DisplayFeature(
            bounds: Rect.fromLTWH(hingeLeft, 0, hingeWidth, 700),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureFlat,
          ),
        ],
        textDirection: TextDirection.rtl,
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);

      final primaryBox = tester.getRect(find.byKey(const Key('primary')));
      final secondaryBox = tester.getRect(find.byKey(const Key('secondary')));

      // In RTL, primary is placed in the right region, secondary in the left region
      expect(
        secondaryBox.right,
        lessThanOrEqualTo(hingeLeft),
        reason: 'Secondary (left pane) must not extend into hinge',
      );
      expect(
        primaryBox.left,
        greaterThanOrEqualTo(hingeLeft + hingeWidth),
        reason: 'Primary (right pane) must start after hinge',
      );
    });

    testWidgets('horizontal hinge: panes top/bottom, no overflow',
        (tester) async {
      const hingeTop = 290.0;
      const hingeHeight = 20.0;

      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTwoPane(
        size: const Size(800, 600),
        features: [
          const DisplayFeature(
            bounds: Rect.fromLTWH(0, hingeTop, 800, hingeHeight),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureFlat,
          ),
        ],
      ));
      await tester.pump();

      // Critical: no RenderFlex overflow — this was the blocking bug.
      expect(tester.takeException(), isNull);

      // Primary on top, secondary on bottom.
      final primaryBox = tester.getRect(find.byKey(const Key('primary')));
      final secondaryBox = tester.getRect(find.byKey(const Key('secondary')));

      expect(
        primaryBox.bottom,
        lessThanOrEqualTo(hingeTop),
        reason: 'Primary must not extend into hinge',
      );
      expect(
        secondaryBox.top,
        greaterThanOrEqualTo(hingeTop + hingeHeight),
        reason: 'Secondary must start after hinge',
      );
    });

    testWidgets('fold (crease): no physical gap, uses normal layout',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTwoPane(
        size: const Size(1000, 700),
        primaryWidth: 400,
        features: [
          const DisplayFeature(
            bounds: Rect.fromLTWH(490, 0, 20, 700),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureFlat,
          ),
        ],
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);

      // fold is NOT treated as separator, so normal layout with divider.
      // Primary should use specified primaryWidth.
      final primaryBox = tester.getRect(find.byKey(const Key('primary')));
      expect(primaryBox.width, 400);
    });
  });
}
