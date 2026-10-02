import "dart:async";
import "dart:ui"
    show DisplayFeature, DisplayFeatureState, DisplayFeatureType, Rect, Size;

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:torque_obd/core/theme/app_theme.dart";
import "package:torque_obd/l10n/generated/app_localizations.dart";
import "package:torque_obd/l10n/generated/app_localizations_en.dart";
import "package:torque_obd/obd/transport/obd_transport.dart";
import "package:torque_obd/obd/pid/pid_library.dart";
import "package:torque_obd/obd/telemetry.dart";
import "package:torque_obd/state/obd_session.dart";
import "package:torque_obd/ui/shell.dart";
import "package:torque_obd/ui/screens/performance/performance_screen.dart";

final _en = AppLocalizationsEn();

class _TestConnectedSession extends ObdSession {
  _TestConnectedSession({this.connected = true});
  final bool connected;

  @override
  ObdConnectionState build() => ObdConnectionState(
        phase: connected ? ConnectionPhase.connected : ConnectionPhase.disconnected,
        kind: TransportKind.demo,
        deviceName: "Demo ECU",
      );
}

class _PerformanceFoldableHarness extends StatefulWidget {
  const _PerformanceFoldableHarness({
    required this.initialSize,
    this.initialFeatures = const [],
    this.initialPadding = EdgeInsets.zero,
    this.withShell = false,
    this.textDirection = TextDirection.ltr,
    this.textScaler = TextScaler.noScaling,
  });

  final Size initialSize;
  final List<DisplayFeature> initialFeatures;
  final EdgeInsets initialPadding;
  final bool withShell;
  final TextDirection textDirection;
  final TextScaler textScaler;

  @override
  State<_PerformanceFoldableHarness> createState() =>
      _PerformanceFoldableHarnessState();
}

class _PerformanceFoldableHarnessState
    extends State<_PerformanceFoldableHarness> {
  late Size size;
  late List<DisplayFeature> features;
  late EdgeInsets padding;

  @override
  void initState() {
    super.initState();
    size = widget.initialSize;
    features = widget.initialFeatures;
    padding = widget.initialPadding;
  }

  void updateLayout({
    required Size newSize,
    List<DisplayFeature> newFeatures = const [],
    EdgeInsets? newPadding,
  }) {
    setState(() {
      size = newSize;
      features = newFeatures;
      if (newPadding != null) padding = newPadding;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        displayFeatures: features,
        padding: padding,
        textScaler: widget.textScaler,
      ),
      child: Directionality(
        textDirection: widget.textDirection,
        child: widget.withShell
            ? const AppShell(child: PerformanceScreen())
            : const PerformanceScreen(),
      ),
    );
  }
}

int _tick = 0;

TelemetrySnapshot _speedSnapshot(
  double? kmh, {
  Duration? elapsed,
  Duration age = Duration.zero,
}) {
  final tick = _tick++;
  final dur = elapsed ?? Duration(milliseconds: tick * 100);
  return TelemetrySnapshot(
    readings: kmh == null
        ? const {}
        : {
            PidLibrary.vehicleSpeed.id: Reading(
              pid: PidLibrary.vehicleSpeed,
              value: kmh,
              rawBytes: [kmh.round().clamp(0, 255)],
              timestamp: DateTime.now()
                  .subtract(const Duration(milliseconds: 50))
                  .add(Duration(milliseconds: tick))
                  .subtract(age),
              receivedElapsed: dur,
            ),
          },
  );
}

Future<StreamController<TelemetrySnapshot>> _pumpScreen(
  WidgetTester tester, {
  Size size = const Size(1000, 800),
  List<DisplayFeature> features = const [],
  EdgeInsets padding = EdgeInsets.zero,
  bool withShell = false,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
  bool connected = true,
  TelemetrySnapshot? initialTelemetry,
}) async {
  final streamCtrl = StreamController<TelemetrySnapshot>.broadcast();
  addTearDown(streamCtrl.close);

  final initialSnap = initialTelemetry ?? _speedSnapshot(0);

  final overrides = [
    obdSessionProvider.overrideWith(
      () => _TestConnectedSession(connected: connected),
    ),
    telemetryProvider.overrideWith((ref) => streamCtrl.stream),
  ];

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  if (withShell) {
    final router = GoRouter(
      initialLocation: PerformanceScreen.path,
      routes: [
        GoRoute(
          path: PerformanceScreen.path,
          builder: (context, state) => _PerformanceFoldableHarness(
            initialSize: size,
            initialFeatures: features,
            initialPadding: padding,
            withShell: true,
            textDirection: textDirection,
            textScaler: textScaler,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          theme: AppTheme.dark(),
          locale: const Locale("en"),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  } else {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale("en"),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _PerformanceFoldableHarness(
            initialSize: size,
            initialFeatures: features,
            initialPadding: padding,
            withShell: false,
            textDirection: textDirection,
            textScaler: textScaler,
          ),
        ),
      ),
    );
  }

  streamCtrl.add(initialSnap);
  await tester.pumpAndSettle();
  return streamCtrl;
}

Future<void> _emit(
  WidgetTester tester,
  StreamController<TelemetrySnapshot> streamCtrl,
  TelemetrySnapshot snapshot,
) async {
  streamCtrl.add(snapshot);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
}

void main() {
  group("Performance Foldable and Two-Pane Layout (FOLD-06)", () {
    testWidgets("F06-07: Compact single-column regression (360x800)", (tester) async {
      await _pumpScreen(tester, size: const Size(360, 800));

      expect(find.byKey(const ValueKey("performance-page-scroll")), findsOneWidget);
      expect(find.byKey(const ValueKey("performance-primary-pane")), findsNothing);
      expect(find.byKey(const ValueKey("performance-secondary-pane")), findsNothing);
      expect(find.text(_en.performanceHeadline), findsOneWidget);
      expect(find.text(_en.performanceArm), findsOneWidget);
    });

    testWidgets("F06-08: Medium width maintains single column (700x800)", (tester) async {
      await _pumpScreen(tester, size: const Size(700, 800));

      expect(find.byKey(const ValueKey("performance-page-scroll")), findsOneWidget);
      expect(find.byKey(const ValueKey("performance-primary-pane")), findsNothing);
      expect(find.byKey(const ValueKey("performance-secondary-pane")), findsNothing);
    });

    testWidgets("F06-09: Expanded screen renders two-pane with components partitioned (1000x800)", (tester) async {
      await _pumpScreen(tester, size: const Size(1000, 800));

      expect(find.byKey(const ValueKey("performance-page-scroll")), findsNothing);
      expect(find.byKey(const ValueKey("performance-primary-pane")), findsOneWidget);
      expect(find.byKey(const ValueKey("performance-secondary-pane")), findsOneWidget);

      // Gauge, timing panel, target speed, Arm button only in primary
      expect(
        find.descendant(
          of: find.byKey(const ValueKey("performance-primary-pane")),
          matching: find.text(_en.performanceArm),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey("performance-secondary-pane")),
          matching: find.text(_en.performanceArm),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey("performance-primary-pane")),
          matching: find.text(_en.performanceTargetSpeedHeading.toUpperCase()),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey("performance-secondary-pane")),
          matching: find.text(_en.performanceTargetSpeedHeading.toUpperCase()),
        ),
        findsNothing,
      );
    });

    testWidgets("F06-10: Initial Secondary shows Run Guide, no trace/splits, disclaimer visible", (tester) async {
      await _pumpScreen(tester, size: const Size(1000, 800));

      expect(find.text(_en.performanceGuideTitle.toUpperCase()), findsOneWidget);
      expect(find.text(_en.performanceGuideStep1), findsOneWidget);
      expect(find.text(_en.performanceSpeedTraceHeading.toUpperCase()), findsNothing);
      expect(find.text(_en.performanceSplitsHeading.toUpperCase()), findsNothing);
      expect(find.text(_en.performanceDisclaimer), findsOneWidget);
    });

    testWidgets("F06-11: No speed signal disables Arm, shows warning in Primary, Guide in Secondary", (tester) async {
      await _pumpScreen(
        tester,
        size: const Size(1000, 800),
        initialTelemetry: _speedSnapshot(null),
      );

      expect(find.text(_en.performanceNoSpeedSignal), findsOneWidget);
      final armBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, _en.performanceArm),
      );
      expect(armBtn.onPressed, isNull);
      expect(find.text(_en.performanceGuideTitle.toUpperCase()), findsOneWidget);
    });

    testWidgets("F06-12: Target interaction regression (selectable when idle, disabled when running)", (tester) async {
      final ctrl = await _pumpScreen(tester, size: const Size(1000, 800));

      // Tap 60 km/h target
      await tester.tap(find.text("60"));
      await tester.pumpAndSettle();
      expect(find.text("60"), findsOneWidget);

      // Arm and launch
      await tester.tap(find.text(_en.performanceArm));
      await tester.pump();

      await _emit(tester, ctrl, _speedSnapshot(0, elapsed: const Duration(seconds: 1)));
      await _emit(tester, ctrl, _speedSnapshot(5, elapsed: const Duration(seconds: 2)));

      // Now running -> SegmentedButton should have null onSelectionChanged
      final segBtn = tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>));
      expect(segBtn.onSelectionChanged, isNull);
    });

    testWidgets("F06-13: Speed trace placement in Secondary pane only", (tester) async {
      final ctrl = await _pumpScreen(tester, size: const Size(1000, 800));

      await tester.tap(find.text(_en.performanceArm));
      await tester.pump();

      // Launch and generate trace points
      await _emit(tester, ctrl, _speedSnapshot(0, elapsed: const Duration(seconds: 1)));
      await _emit(tester, ctrl, _speedSnapshot(10, elapsed: const Duration(seconds: 2)));
      await _emit(tester, ctrl, _speedSnapshot(30, elapsed: const Duration(seconds: 3)));
      await _emit(tester, ctrl, _speedSnapshot(60, elapsed: const Duration(seconds: 4)));

      expect(
        find.descendant(
          of: find.byKey(const ValueKey("performance-secondary-pane")),
          matching: find.text(_en.performanceSpeedTraceHeading.toUpperCase()),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey("performance-primary-pane")),
          matching: find.text(_en.performanceSpeedTraceHeading.toUpperCase()),
        ),
        findsNothing,
      );
    });

    testWidgets("F06-14: Splits placement in Secondary pane only", (tester) async {
      final ctrl = await _pumpScreen(tester, size: const Size(1000, 800));

      await tester.tap(find.text(_en.performanceArm));
      await tester.pump();

      await _emit(tester, ctrl, _speedSnapshot(0, elapsed: const Duration(seconds: 1)));
      await _emit(tester, ctrl, _speedSnapshot(3, elapsed: const Duration(seconds: 2)));
      await _emit(tester, ctrl, _speedSnapshot(60, elapsed: const Duration(seconds: 5)));

      expect(
        find.descendant(
          of: find.byKey(const ValueKey("performance-secondary-pane")),
          matching: find.text(_en.performanceSplitsHeading.toUpperCase()),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey("performance-primary-pane")),
          matching: find.text(_en.performanceSplitsHeading.toUpperCase()),
        ),
        findsNothing,
      );
    });

    testWidgets("F06-15: Aborted partial evidence retained in Secondary", (tester) async {
      final ctrl = await _pumpScreen(tester, size: const Size(1000, 800));

      await tester.tap(find.text(_en.performanceArm));
      await tester.pump();

      // Launch then stop before reaching target 100 -> abort
      await _emit(tester, ctrl, _speedSnapshot(0, elapsed: const Duration(seconds: 1)));
      await _emit(tester, ctrl, _speedSnapshot(20, elapsed: const Duration(seconds: 2)));
      await _emit(tester, ctrl, _speedSnapshot(60, elapsed: const Duration(seconds: 4)));
      await _emit(tester, ctrl, _speedSnapshot(0, elapsed: const Duration(seconds: 6)));
      await _emit(tester, ctrl, _speedSnapshot(1, elapsed: const Duration(seconds: 7)));

      // Primary shows aborted
      expect(
        find.descendant(
          of: find.byKey(const ValueKey("performance-primary-pane")),
          matching: find.text(_en.performanceStateAborted),
        ),
        findsOneWidget,
      );

      // Secondary retains trace and splits evidence
      expect(
        find.descendant(
          of: find.byKey(const ValueKey("performance-secondary-pane")),
          matching: find.text(_en.performanceSpeedTraceHeading.toUpperCase()),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey("performance-secondary-pane")),
          matching: find.text(_en.performanceSplitsHeading.toUpperCase()),
        ),
        findsOneWidget,
      );
      // Does not revert to guide
      expect(find.text(_en.performanceGuideTitle.toUpperCase()), findsNothing);
    });

    testWidgets("F06-15b: Aborted without evidence shows no-analysis message in Secondary", (tester) async {
      final ctrl = await _pumpScreen(tester, size: const Size(1000, 800));

      await tester.tap(find.text(_en.performanceArm));
      await tester.pump();

      // Enter staged at standstill (0 km/h)
      await _emit(tester, ctrl, _speedSnapshot(0, elapsed: const Duration(seconds: 1)));
      expect(find.text(_en.performanceStateStaged), findsOneWidget);

      // Speed signal goes stale before launch -> aborted with 0 points
      await _emit(
        tester,
        ctrl,
        _speedSnapshot(0, elapsed: const Duration(seconds: 2), age: const Duration(minutes: 5)),
      );

      // Primary shows aborted
      expect(
        find.descendant(
          of: find.byKey(const ValueKey("performance-primary-pane")),
          matching: find.text(_en.performanceStateAborted),
        ),
        findsOneWidget,
      );

      // Secondary shows no-analysis message instead of onboarding guide
      expect(
        find.descendant(
          of: find.byKey(const ValueKey("performance-secondary-pane")),
          matching: find.text(_en.performanceNoAnalysisTitle.toUpperCase()),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey("performance-secondary-pane")),
          matching: find.text(_en.performanceNoAnalysisBody),
        ),
        findsOneWidget,
      );
      expect(find.text(_en.performanceGuideTitle.toUpperCase()), findsNothing);
    });

    testWidgets("F06-16: Reset clears analysis and returns Secondary to Guide", (tester) async {
      final ctrl = await _pumpScreen(tester, size: const Size(1000, 800));

      await tester.tap(find.text(_en.performanceArm));
      await tester.pump();

      await _emit(tester, ctrl, _speedSnapshot(0, elapsed: const Duration(seconds: 1)));
      await _emit(tester, ctrl, _speedSnapshot(3, elapsed: const Duration(seconds: 2)));
      await _emit(tester, ctrl, _speedSnapshot(100, elapsed: const Duration(seconds: 6)));

      expect(find.text(_en.performanceReset), findsOneWidget);

      await tester.tap(find.text(_en.performanceReset));
      await tester.pumpAndSettle();

      expect(find.text(_en.performanceStateIdle), findsOneWidget);
      expect(find.text(_en.performanceSpeedTraceHeading.toUpperCase()), findsNothing);
      expect(find.text(_en.performanceSplitsHeading.toUpperCase()), findsNothing);
      expect(find.text(_en.performanceGuideTitle.toUpperCase()), findsOneWidget);
    });

    testWidgets("F06-17: awaitingStandstill continuity across fold/unfold", (tester) async {
      await _pumpScreen(
        tester,
        size: const Size(1000, 800),
        initialTelemetry: _speedSnapshot(35),
      );

      await tester.tap(find.text(_en.performanceArm));
      await tester.pump();

      expect(find.textContaining("35 km/h"), findsOneWidget);

      // Fold to 400x800
      final harness = tester.state<_PerformanceFoldableHarnessState>(
        find.byType(_PerformanceFoldableHarness),
      );
      harness.updateLayout(newSize: const Size(400, 800));
      await tester.pumpAndSettle();

      expect(find.textContaining("35 km/h"), findsOneWidget);

      // Unfold back to 1000x800
      harness.updateLayout(newSize: const Size(1000, 800));
      await tester.pumpAndSettle();

      expect(find.textContaining("35 km/h"), findsOneWidget);
    });

    testWidgets("F06-18: staged continuity across fold/unfold", (tester) async {
      final ctrl = await _pumpScreen(tester, size: const Size(1000, 800));

      await tester.tap(find.text(_en.performanceArm));
      await tester.pump();

      await _emit(tester, ctrl, _speedSnapshot(0, elapsed: const Duration(seconds: 1)));
      expect(find.text(_en.performanceStateStaged), findsOneWidget);

      // Fold to 400x800
      final harness = tester.state<_PerformanceFoldableHarnessState>(
        find.byType(_PerformanceFoldableHarness),
      );
      harness.updateLayout(newSize: const Size(400, 800));
      await tester.pumpAndSettle();

      expect(find.text(_en.performanceStateStaged), findsOneWidget);

      // Unfold to 1000x800
      harness.updateLayout(newSize: const Size(1000, 800));
      await tester.pumpAndSettle();

      expect(find.text(_en.performanceStateStaged), findsOneWidget);
    });

    testWidgets("F06-19: running continuity across fold/unfold", (tester) async {
      final ctrl = await _pumpScreen(tester, size: const Size(1000, 800));

      await tester.tap(find.text(_en.performanceArm));
      await tester.pump();

      await _emit(tester, ctrl, _speedSnapshot(0, elapsed: const Duration(seconds: 1)));
      await _emit(tester, ctrl, _speedSnapshot(5, elapsed: const Duration(seconds: 2)));
      await _emit(tester, ctrl, _speedSnapshot(45, elapsed: const Duration(seconds: 3)));

      expect(find.text(_en.performanceStateRunning), findsOneWidget);

      // Fold to 400x800
      final harness = tester.state<_PerformanceFoldableHarnessState>(
        find.byType(_PerformanceFoldableHarness),
      );
      harness.updateLayout(newSize: const Size(400, 800));
      await tester.pumpAndSettle();

      expect(find.text(_en.performanceStateRunning), findsOneWidget);

      // Unfold to 1000x800
      harness.updateLayout(newSize: const Size(1000, 800));
      await tester.pumpAndSettle();

      expect(find.text(_en.performanceStateRunning), findsOneWidget);
    });

    testWidgets("F06-20: finish after resize (telemetry subscription remains active across fold)", (tester) async {
      final ctrl = await _pumpScreen(tester, size: const Size(1000, 800));

      await tester.tap(find.text(_en.performanceArm));
      await tester.pump();

      await _emit(tester, ctrl, _speedSnapshot(0, elapsed: const Duration(seconds: 1)));
      await _emit(tester, ctrl, _speedSnapshot(5, elapsed: const Duration(seconds: 2)));

      // Fold to compact
      final harness = tester.state<_PerformanceFoldableHarnessState>(
        find.byType(_PerformanceFoldableHarness),
      );
      harness.updateLayout(newSize: const Size(400, 800));
      await tester.pumpAndSettle();

      // Feed target-reaching sample while folded
      await _emit(tester, ctrl, _speedSnapshot(100, elapsed: const Duration(seconds: 7)));

      expect(find.text(_en.performanceStateFinished(100)), findsOneWidget);

      // Unfold back to expanded
      harness.updateLayout(newSize: const Size(1000, 800));
      await tester.pumpAndSettle();

      expect(find.text(_en.performanceStateFinished(100)), findsOneWidget);
      expect(find.text(_en.performanceSpeedTraceHeading.toUpperCase()), findsOneWidget);
      expect(find.text(_en.performanceSplitsHeading.toUpperCase()), findsOneWidget);
    });

    testWidgets("F06-21: Vertical separating hinge in LTR (zero overlap)", (tester) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      await _pumpScreen(
        tester,
        size: const Size(1000, 800),
        features: const [hingeFeature],
      );

      final primaryRect = tester.getRect(find.byKey(const ValueKey("performance-primary-pane")));
      final secondaryRect = tester.getRect(find.byKey(const ValueKey("performance-secondary-pane")));

      expect(primaryRect.overlaps(hingeFeature.bounds), isFalse);
      expect(secondaryRect.overlaps(hingeFeature.bounds), isFalse);
      expect(primaryRect.right, lessThanOrEqualTo(490.0));
      expect(secondaryRect.left, greaterThanOrEqualTo(510.0));
    });

    testWidgets("F06-22: Vertical separating hinge in RTL (zero overlap)", (tester) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      await _pumpScreen(
        tester,
        size: const Size(1000, 800),
        features: const [hingeFeature],
        textDirection: TextDirection.rtl,
      );

      final primaryRect = tester.getRect(find.byKey(const ValueKey("performance-primary-pane")));
      final secondaryRect = tester.getRect(find.byKey(const ValueKey("performance-secondary-pane")));

      expect(primaryRect.overlaps(hingeFeature.bounds), isFalse);
      expect(secondaryRect.overlaps(hingeFeature.bounds), isFalse);
      // In RTL: primary is on right, secondary is on left
      expect(secondaryRect.right, lessThanOrEqualTo(490.0));
      expect(primaryRect.left, greaterThanOrEqualTo(510.0));
    });

    testWidgets("F06-23: SafeArea + NavigationRail + hinge coordinate projection integration", (tester) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(530, 0, 24, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      await _pumpScreen(
        tester,
        size: const Size(1000, 800),
        features: const [hingeFeature],
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        withShell: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey("performance-primary-pane")), findsOneWidget);
      expect(find.byKey(const ValueKey("performance-secondary-pane")), findsOneWidget);

      final primaryRect = tester.getRect(find.byKey(const ValueKey("performance-primary-pane")));
      final secondaryRect = tester.getRect(find.byKey(const ValueKey("performance-secondary-pane")));

      expect(primaryRect.overlaps(hingeFeature.bounds), isFalse);
      expect(secondaryRect.overlaps(hingeFeature.bounds), isFalse);
    });

    testWidgets("F06-24: Horizontal separating hinge forces single pane", (tester) async {
      const horizontalHinge = DisplayFeature(
        bounds: Rect.fromLTWH(0, 390, 1000, 20),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      await _pumpScreen(
        tester,
        size: const Size(1000, 800),
        features: const [horizontalHinge],
      );

      expect(find.byKey(const ValueKey("performance-page-scroll")), findsOneWidget);
      expect(find.byKey(const ValueKey("performance-primary-pane")), findsNothing);
      expect(find.byKey(const ValueKey("performance-secondary-pane")), findsNothing);
    });

    testWidgets("F06-25: Accessibility: textScale 2.0 with expanded hinge layout has zero overflow", (tester) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      await _pumpScreen(
        tester,
        size: const Size(1000, 800),
        features: const [hingeFeature],
        textScaler: const TextScaler.linear(2.0),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_en.performanceHeadline), findsOneWidget);

      final primaryList = find.byKey(const PageStorageKey("performance-primary-scroll"));
      await tester.scrollUntilVisible(
        find.text(_en.performanceArm),
        150,
        scrollable: find.descendant(of: primaryList, matching: find.byType(Scrollable)),
      );
      expect(find.text(_en.performanceArm), findsOneWidget);
    });

    testWidgets("F06-26: Independent scrolling of Primary and Secondary panes", (tester) async {
      await _pumpScreen(tester, size: const Size(1000, 800));

      final primaryList = find.byKey(const PageStorageKey("performance-primary-scroll"));
      final secondaryList = find.byKey(const PageStorageKey("performance-secondary-scroll"));

      expect(primaryList, findsOneWidget);
      expect(secondaryList, findsOneWidget);

      // Drag primary list
      await tester.drag(primaryList, const Offset(0, -100));
      await tester.pump();

      // Drag secondary list
      await tester.drag(secondaryList, const Offset(0, -100));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
