/// Unit tests for [AdaptiveLayout].
library;

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/ui/adaptive/adaptive_layout.dart';
import 'package:torque_obd/ui/adaptive/app_breakpoints.dart';

void main() {
  group('AdaptiveLayout.of', () {
    Widget buildWithSize(
      Size size, {
      List<DisplayFeature> features = const [],
      required Widget child,
    }) {
      return MediaQuery(
        data: MediaQueryData(
          size: size,
          displayFeatures: features,
        ),
        child: child,
      );
    }

    testWidgets('compact phone 360x800', (tester) async {
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        buildWithSize(
          const Size(360, 800),
          child: Builder(
            builder: (context) {
              layout = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(layout.isCompact, isTrue);
      expect(layout.isMedium, isFalse);
      expect(layout.isExpanded, isFalse);
      expect(layout.hasSeparatingFeature, isFalse);
      expect(layout.isShortLandscape, isFalse);
      expect(layout.regions, hasLength(1));
    });

    testWidgets('medium 600x700', (tester) async {
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        buildWithSize(
          const Size(600, 700),
          child: Builder(
            builder: (context) {
              layout = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(layout.isCompact, isFalse);
      expect(layout.isMedium, isTrue);
      expect(layout.isExpanded, isFalse);
      expect(layout.hasSeparatingFeature, isFalse);
    });

    testWidgets('expanded 1000x700', (tester) async {
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        buildWithSize(
          const Size(1000, 700),
          child: Builder(
            builder: (context) {
              layout = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(layout.isCompact, isFalse);
      expect(layout.isMedium, isFalse);
      expect(layout.isExpanded, isTrue);
      expect(layout.hasSeparatingFeature, isFalse);
      expect(layout.regions, hasLength(1));
    });

    testWidgets('short landscape 800x360', (tester) async {
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        buildWithSize(
          const Size(800, 360),
          child: Builder(
            builder: (context) {
              layout = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(layout.isMedium, isTrue);
      expect(layout.isShortLandscape, isTrue);
    });

    testWidgets('not short landscape at height = 480', (tester) async {
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        buildWithSize(
          const Size(800, 480),
          child: Builder(
            builder: (context) {
              layout = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(layout.isShortLandscape, isFalse);
    });

    testWidgets('portrait is never short landscape', (tester) async {
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        buildWithSize(
          const Size(360, 400),
          child: Builder(
            builder: (context) {
              layout = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      // width <= height, so not landscape at all.
      expect(layout.isShortLandscape, isFalse);
    });

    testWidgets('vertical hinge creates two regions', (tester) async {
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        buildWithSize(
          const Size(1000, 700),
          features: [
            const DisplayFeature(
              bounds: Rect.fromLTWH(490, 0, 20, 700),
              type: DisplayFeatureType.hinge,
              state: DisplayFeatureState.postureFlat,
            ),
          ],
          child: Builder(
            builder: (context) {
              layout = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(layout.hasSeparatingFeature, isTrue);
      expect(layout.regions, hasLength(2));
      // Left region
      expect(layout.regions[0].left, 0);
      expect(layout.regions[0].right, 490);
      // Right region
      expect(layout.regions[1].left, 510);
      expect(layout.regions[1].right, 1000);
    });

    testWidgets('horizontal hinge creates top/bottom regions',
        (tester) async {
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        buildWithSize(
          const Size(800, 600),
          features: [
            const DisplayFeature(
              bounds: Rect.fromLTWH(0, 290, 800, 20),
              type: DisplayFeatureType.hinge,
              state: DisplayFeatureState.postureFlat,
            ),
          ],
          child: Builder(
            builder: (context) {
              layout = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(layout.hasSeparatingFeature, isTrue);
      expect(layout.regions, hasLength(2));
      expect(layout.regions[0].top, 0);
      expect(layout.regions[0].bottom, 290);
      expect(layout.regions[1].top, 310);
      expect(layout.regions[1].bottom, 600);
    });

    testWidgets('cutout is also treated as obstructing', (tester) async {
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        buildWithSize(
          const Size(1000, 700),
          features: [
            const DisplayFeature(
              bounds: Rect.fromLTWH(490, 0, 20, 700),
              type: DisplayFeatureType.cutout,
              state: DisplayFeatureState.unknown,
            ),
          ],
          child: Builder(
            builder: (context) {
              layout = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(layout.hasSeparatingFeature, isTrue);
      expect(layout.regions, hasLength(2));
    });

    testWidgets('fold (crease) is NOT treated as separator', (tester) async {
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        buildWithSize(
          const Size(1000, 700),
          features: [
            const DisplayFeature(
              bounds: Rect.fromLTWH(490, 0, 20, 700),
              type: DisplayFeatureType.fold,
              state: DisplayFeatureState.postureFlat,
            ),
          ],
          child: Builder(
            builder: (context) {
              layout = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      // fold is not obstructing — it's just a crease.
      expect(layout.hasSeparatingFeature, isFalse);
      expect(layout.regions, hasLength(1));
    });

    testWidgets('small hinge is not separating', (tester) async {
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        buildWithSize(
          const Size(1000, 700),
          features: [
            // Camera cutout — only covers a small area.
            const DisplayFeature(
              bounds: Rect.fromLTWH(480, 0, 40, 40),
              type: DisplayFeatureType.cutout,
              state: DisplayFeatureState.unknown,
            ),
          ],
          child: Builder(
            builder: (context) {
              layout = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      // Small cutout (camera hole) should not be treated as separator.
      expect(layout.hasSeparatingFeature, isFalse);
      expect(layout.regions, hasLength(1));
    });
  });

  group('AdaptiveLayout size matrix', () {
    // Per GPT-6 Pro test strategy: test all key sizes.
    final sizeTests = <String, (Size, AppWindowClass)>{
      '360x800 (compact phone)': (const Size(360, 800), AppWindowClass.compact),
      '412x915 (standard phone)': (
        const Size(412, 915),
        AppWindowClass.compact,
      ),
      '800x360 (landscape phone)': (
        const Size(800, 360),
        AppWindowClass.medium,
      ),
      '599x700 (boundary-1)': (const Size(599, 700), AppWindowClass.compact),
      '600x700 (medium)': (const Size(600, 700), AppWindowClass.medium),
      '839x700 (boundary-1)': (const Size(839, 700), AppWindowClass.medium),
      '840x700 (expanded)': (const Size(840, 700), AppWindowClass.expanded),
      '1000x700 (Fold inner)': (const Size(1000, 700), AppWindowClass.expanded),
      '1400x900 (large tablet)': (
        const Size(1400, 900),
        AppWindowClass.expanded,
      ),
    };

    for (final entry in sizeTests.entries) {
      testWidgets(entry.key, (tester) async {
        late AdaptiveLayout layout;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: entry.value.$1),
            child: Builder(
              builder: (context) {
                layout = AdaptiveLayout.of(context);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(
          layout.windowClass,
          entry.value.$2,
          reason: '${entry.key} should be ${entry.value.$2}',
        );
      });
    }
  });

  group('AdaptiveLayout orientation getters', () {
    testWidgets('hasVerticalSeparator for vertical hinge', (tester) async {
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(1000, 700),
            displayFeatures: [
              DisplayFeature(
                bounds: Rect.fromLTWH(490, 0, 20, 700),
                type: DisplayFeatureType.hinge,
                state: DisplayFeatureState.postureFlat,
              ),
            ],
          ),
          child: Builder(
            builder: (context) {
              layout = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(layout.hasVerticalSeparator, isTrue);
      expect(layout.hasHorizontalSeparator, isFalse);
    });

    testWidgets('hasHorizontalSeparator for horizontal hinge', (tester) async {
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 600),
            displayFeatures: [
              DisplayFeature(
                bounds: Rect.fromLTWH(0, 290, 800, 20),
                type: DisplayFeatureType.hinge,
                state: DisplayFeatureState.postureFlat,
              ),
            ],
          ),
          child: Builder(
            builder: (context) {
              layout = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(layout.hasVerticalSeparator, isFalse);
      expect(layout.hasHorizontalSeparator, isTrue);
    });

    testWidgets('no separator = both false', (tester) async {
      late AdaptiveLayout layout;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1000, 700)),
          child: Builder(
            builder: (context) {
              layout = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(layout.hasVerticalSeparator, isFalse);
      expect(layout.hasHorizontalSeparator, isFalse);
    });
  });
}
