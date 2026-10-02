/// Unit and widget tests for [AdaptiveLayoutScope] and [AdaptiveLayout.projectTo].
library;

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/ui/adaptive/adaptive_layout.dart';
import 'package:torque_obd/ui/adaptive/app_breakpoints.dart';
import 'package:torque_obd/ui/shell.dart';

void main() {
  group('AdaptiveLayoutScope & projectTo', () {
    testWidgets('maybeOf returns null when no scope present', (tester) async {
      late AdaptiveLayout? scoped;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            scoped = AdaptiveLayoutScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      );
      expect(scoped, isNull);
    });

    testWidgets('maybeOf and of return scoped layout when present', (
      tester,
    ) async {
      const layout = AdaptiveLayout(
        size: Size(500, 400),
        windowClass: AppWindowClass.compact,
        displayFeatures: [],
        separatingFeature: null,
        regions: [Rect.fromLTWH(0, 0, 500, 400)],
      );

      late AdaptiveLayout found;
      await tester.pumpWidget(
        AdaptiveLayoutScope(
          layout: layout,
          child: Builder(
            builder: (context) {
              found = AdaptiveLayout.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(found.size, const Size(500, 400));
      expect(found.windowClass, AppWindowClass.compact);
      expect(found, equals(layout));
    });

    test('AdaptiveLayout equality and hashCode', () {
      const layout1 = AdaptiveLayout(
        size: Size(500, 400),
        windowClass: AppWindowClass.compact,
        displayFeatures: [],
        separatingFeature: null,
        regions: [Rect.fromLTWH(0, 0, 500, 400)],
      );
      const layout2 = AdaptiveLayout(
        size: Size(500, 400),
        windowClass: AppWindowClass.compact,
        displayFeatures: [],
        separatingFeature: null,
        regions: [Rect.fromLTWH(0, 0, 500, 400)],
      );
      const layout3 = AdaptiveLayout(
        size: Size(600, 400),
        windowClass: AppWindowClass.medium,
        displayFeatures: [],
        separatingFeature: null,
        regions: [Rect.fromLTWH(0, 0, 600, 400)],
      );

      expect(layout1, equals(layout2));
      expect(layout1.hashCode, equals(layout2.hashCode));
      expect(layout1, isNot(equals(layout3)));

      const scope1 = AdaptiveLayoutScope(layout: layout1, child: SizedBox());
      const scope2 = AdaptiveLayoutScope(layout: layout2, child: SizedBox());
      const scope3 = AdaptiveLayoutScope(layout: layout3, child: SizedBox());

      expect(scope1.updateShouldNotify(scope2), isFalse);
      expect(scope1.updateShouldNotify(scope3), isTrue);
    });

    test('projectTo translates hinge and clips features to viewport', () {
      const fullSize = Size(1000, 700);
      const hinge = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 700),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );
      const outsideFeature = DisplayFeature(
        bounds: Rect.fromLTWH(10, 10, 20, 20),
        type: DisplayFeatureType.cutout,
        state: DisplayFeatureState.unknown,
      );

      final fullLayout = AdaptiveLayout.fromValues(
        size: fullSize,
        displayFeatures: const [outsideFeature, hinge],
      );

      // Viewport simulating content area to the right of a 100px NavigationRail
      const viewport = Rect.fromLTWH(100, 0, 900, 700);
      final projected = fullLayout.projectTo(viewport);

      expect(projected.size, const Size(900, 700));
      // outsideFeature at (10, 10) does not intersect viewport (100..1000), so dropped
      expect(projected.displayFeatures.length, 1);
      final localHinge = projected.displayFeatures.first;
      // Hinge shifted by (-100, 0): 490-100=390, width=20
      expect(localHinge.bounds, const Rect.fromLTWH(390, 0, 20, 700));
      expect(projected.hasVerticalSeparator, isTrue);
      expect(projected.regions.length, 2);
      expect(projected.regions[0], const Rect.fromLTWH(0, 0, 390, 700));
      expect(projected.regions[1], const Rect.fromLTWH(410, 0, 490, 700));
    });
  });

  group('AppShell content localization with NavigationRail', () {
    testWidgets('D02-08: shell projects hinge coordinates for content screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late AdaptiveLayout childLayout;

      final router = GoRouter(
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Builder(
                  builder: (context) {
                    childLayout = AdaptiveLayout.of(context);
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          child: MediaQuery(
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
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Rail width > 0, so content width is less than 1000
      expect(childLayout.size.width, lessThan(1000));
      expect(childLayout.hasVerticalSeparator, isTrue);

      final railWidth = 1000 - childLayout.size.width;
      final localHingeBounds = childLayout.separatingFeature!.bounds;
      // Local hinge left must equal 490 - railWidth
      expect(localHingeBounds.left, closeTo(490 - railWidth, 0.01));
      expect(localHingeBounds.width, 20);
    });
  });
}
