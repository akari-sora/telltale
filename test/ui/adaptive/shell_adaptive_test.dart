/// Shell navigation policy tests.
///
/// Two-layer approach per GPT-6 Pro review:
/// 1. Unit tests on [shouldUseNavigationRail] for the full size matrix.
/// 2. Widget tests rendering production [AppShell] to verify
///    NavigationBar / NavigationRail are actually wired correctly.
library;


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
  // ─────────────────────────────────────────────────────────────────
  // Layer 1: Unit tests on the shared policy function.
  // ─────────────────────────────────────────────────────────────────

  group('shouldUseNavigationRail (unit)', () {
    test('compact portrait → false (Bar)', () {
      expect(shouldUseNavigationRail(AppWindowClass.compact, false), isFalse);
    });

    test('compact short landscape → true (Rail)', () {
      expect(shouldUseNavigationRail(AppWindowClass.compact, true), isTrue);
    });

    test('medium → true (Rail)', () {
      expect(shouldUseNavigationRail(AppWindowClass.medium, false), isTrue);
    });

    test('expanded → true (Rail)', () {
      expect(shouldUseNavigationRail(AppWindowClass.expanded, false), isTrue);
    });

    test('full size matrix', () {
      AdaptiveLayout layoutForSize(double w, double h) {
        return AdaptiveLayout(
          size: Size(w, h),
          windowClass: AppBreakpoints.widthClass(w),
          displayFeatures: const [],
          separatingFeature: null,
          regions: [Rect.fromLTWH(0, 0, w, h)],
        );
      }

      final cases = <(double, double, bool)>[
        (360, 800, false), // compact portrait
        (412, 915, false), // standard phone
        (599, 700, false), // boundary - 1
        (500, 400, true), // compact short landscape
        (500, 350, true), // compact short landscape
        (600, 700, true), // medium
        (720, 700, true), // old breakpoint
        (800, 360, true), // landscape phone
        (839, 700, true), // medium boundary
        (840, 700, true), // expanded
        (1000, 700, true), // Fold inner
        (1400, 900, true), // large tablet
      ];

      for (final (w, h, expectedRail) in cases) {
        final layout = layoutForSize(w, h);
        expect(
          shouldUseNavigationRail(layout.windowClass, layout.isShortLandscape),
          expectedRail,
          reason: '${w}x$h should ${expectedRail ? "use Rail" : "use Bar"}',
        );
      }
    });

    test('600–719 transition: now Rail (was Bar before FOLD-01)', () {
      for (final width in [600.0, 650.0, 700.0, 719.0]) {
        final wc = AppBreakpoints.widthClass(width);
        expect(
          shouldUseNavigationRail(wc, false),
          isTrue,
          reason: '${width}w should use Rail',
        );
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Layer 2: Widget tests rendering production AppShell.
  // ─────────────────────────────────────────────────────────────────

  group('AppShell widget (integration)', () {
    // Minimal GoRouter just to satisfy AppShell's GoRouterState.of.
    GoRouter buildRouter() {
      return GoRouter(
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const SizedBox(key: Key('dashboard')),
              ),
            ],
          ),
        ],
      );
    }

    Future<void> pumpShell(
      WidgetTester tester, {
      required double width,
      required double height,
    }) async {
      tester.view.physicalSize = Size(width, height);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
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
      );
      // Allow GoRouter to settle.
      await tester.pumpAndSettle();
    }

    testWidgets('599×700 → NavigationBar only', (tester) async {
      await pumpShell(tester, width: 599, height: 700);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('600×700 → NavigationRail only', (tester) async {
      await pumpShell(tester, width: 600, height: 700);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('840×700 → NavigationRail only', (tester) async {
      await pumpShell(tester, width: 840, height: 700);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('500×400 → NavigationRail (compact short landscape)',
        (tester) async {
      await pumpShell(tester, width: 500, height: 400);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('360×800 → NavigationBar (compact portrait)', (tester) async {
      await pumpShell(tester, width: 360, height: 800);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });
  });
}
