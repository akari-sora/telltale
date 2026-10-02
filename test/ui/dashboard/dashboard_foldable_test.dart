/// Comprehensive foldable and adaptive tests for [DashboardScreen].
///
/// Validates FOLD-02 acceptance criteria:
/// - D02-01: Standard grid column cap (maximum 6 columns on wide displays)
/// - D02-02: Zero gauge tiles intersect the vertical separating hinge
/// - D02-03: Contiguous stable split across panes and order preservation
/// - D02-04: Odd PID counts allocate the extra item to the primary (left) pane
/// - D02-05: Fold/unfold maintains selected workspace mode (gauges vs trends)
/// - D02-06: Scroll position survives fold/unfold layout rebuilds
/// - D02-07: OBD connection session is maintained through fold/unfold transitions
/// - D02-08: Shell NavigationRail coordinate projection keeps hinge safe in global coordinates
/// - D02-09: Compact portrait and landscape behavior has no regression
/// - D02-10: Accessibility text scaling preserves minimum tile width contract
library;

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/obd/physics/vehicle_profile.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/settings.dart';
import 'package:torque_obd/ui/screens/dashboard/dashboard_screen.dart';
import 'package:torque_obd/ui/screens/dashboard/telemetry_workspace.dart';
import 'package:torque_obd/ui/shell.dart';

final _testPids = [
  PidLibrary.engineRpm,
  PidLibrary.vehicleSpeed,
  PidLibrary.coolantTemp,
  PidLibrary.intakeAirTemp,
  PidLibrary.engineLoad,
  PidLibrary.throttlePosition,
  PidLibrary.manifoldPressure,
  PidLibrary.mafRate,
  PidLibrary.timingAdvance,
  PidLibrary.fuelPressure,
  PidLibrary.fuelLevel,
  PidLibrary.controlModuleVoltage,
];

class _FixedSession extends ObdSession {
  _FixedSession(this._state);
  final ObdConnectionState _state;

  @override
  ObdConnectionState build() => _state;
}

class _FixedActivePids extends ActivePids {
  _FixedActivePids(this._pids);
  final List<Pid> _pids;

  @override
  List<Pid> build() => _pids;
}

class _FixedProfile extends VehicleProfileController {
  @override
  VehicleProfile build() => const VehicleProfile();
}

late SharedPreferences _testPrefs;

class _FoldableHarness extends StatefulWidget {
  const _FoldableHarness({
    super.key,
    required this.initialSize,
    this.initialFeatures = const [],
    this.initialTextScaler = TextScaler.noScaling,
    this.initialPadding = EdgeInsets.zero,
    required this.pids,
    this.connectionState = const ObdConnectionState(
      phase: ConnectionPhase.connected,
      kind: TransportKind.demo,
      deviceName: 'Demo ECU',
    ),
    this.withShell = false,
    this.textDirection = TextDirection.ltr,
  });

  final Size initialSize;
  final List<DisplayFeature> initialFeatures;
  final TextScaler initialTextScaler;
  final EdgeInsets initialPadding;
  final List<Pid> pids;
  final ObdConnectionState connectionState;
  final bool withShell;
  final TextDirection textDirection;

  @override
  State<_FoldableHarness> createState() => _FoldableHarnessState();
}

class _FoldableHarnessState extends State<_FoldableHarness> {
  late Size size;
  late List<DisplayFeature> features;
  late TextScaler textScaler;
  late EdgeInsets padding;

  @override
  void initState() {
    super.initState();
    size = widget.initialSize;
    features = widget.initialFeatures;
    textScaler = widget.initialTextScaler;
    padding = widget.initialPadding;
  }

  void updateLayout({
    required Size newSize,
    List<DisplayFeature> newFeatures = const [],
    TextScaler? newTextScaler,
    EdgeInsets? newPadding,
  }) {
    setState(() {
      size = newSize;
      features = newFeatures;
      if (newTextScaler != null) textScaler = newTextScaler;
      if (newPadding != null) padding = newPadding;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        displayFeatures: features,
        textScaler: textScaler,
        padding: padding,
      ),
      child: Directionality(
        textDirection: widget.textDirection,
        child: widget.withShell
            ? const AppShell(child: DashboardScreen())
            : const DashboardScreen(),
      ),
    );
  }
}

Future<GlobalKey<_FoldableHarnessState>> _pumpFoldableDashboard(
  WidgetTester tester, {
  required Size size,
  List<DisplayFeature> displayFeatures = const [],
  List<Pid> pids = const [],
  ObdConnectionState connectionState = const ObdConnectionState(
    phase: ConnectionPhase.connected,
    kind: TransportKind.demo,
    deviceName: 'Demo ECU',
  ),
  TextScaler textScaler = TextScaler.noScaling,
  EdgeInsets padding = EdgeInsets.zero,
  bool withShell = false,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final harnessKey = GlobalKey<_FoldableHarnessState>();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => _FoldableHarness(
          key: harnessKey,
          initialSize: size,
          initialFeatures: displayFeatures,
          initialTextScaler: textScaler,
          initialPadding: padding,
          pids: pids,
          connectionState: connectionState,
          withShell: withShell,
          textDirection: textDirection,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_testPrefs),
        obdSessionProvider.overrideWith(() => _FixedSession(connectionState)),
        activePidsProvider.overrideWith(() => _FixedActivePids(pids)),
        vehicleProfileProvider.overrideWith(_FixedProfile.new),
        telemetryProvider.overrideWith(
          (ref) => Stream.value(const TelemetrySnapshot()),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark(),
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
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
  return harnessKey;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _testPrefs = await SharedPreferences.getInstance();
  });

  group('FOLD-02 Dashboard foldable adaptations', () {
    testWidgets('D02-01: normal expanded clamps grid to maximum 6 columns', (
      tester,
    ) async {
      await _pumpFoldableDashboard(
        tester,
        size: const Size(1800, 900),
        pids: _testPids.sublist(0, 8),
      );

      final firstGaugeY = tester.getTopLeft(
        find.byKey(ValueKey('dashboard-gauge-${_testPids[0].id}')),
      ).dy;

      // Exactly 6 gauges should share the same top row coordinate
      var firstRowCount = 0;
      for (final pid in _testPids.sublist(0, 8)) {
        final top = tester.getTopLeft(
          find.byKey(ValueKey('dashboard-gauge-${pid.id}')),
        ).dy;
        if ((top - firstGaugeY).abs() < 1.0) {
          firstRowCount++;
        }
      }

      expect(firstRowCount, 6);
      expect(tester.takeException(), isNull);
    });

    testWidgets('D02-02: zero gauge tiles intersect vertical separating hinge', (
      tester,
    ) async {
      const hingeRect = Rect.fromLTWH(490, 0, 20, 700);
      const hingeFeature = DisplayFeature(
        bounds: hingeRect,
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      final pids = _testPids.sublist(0, 8);
      await _pumpFoldableDashboard(
        tester,
        size: const Size(1000, 700),
        displayFeatures: const [hingeFeature],
        pids: pids,
      );

      for (final pid in pids) {
        final gaugeFinder = find.byKey(ValueKey('dashboard-gauge-${pid.id}'));
        expect(gaugeFinder, findsOneWidget);
        final rect = tester.getRect(gaugeFinder);
        expect(
          rect.overlaps(hingeRect),
          isFalse,
          reason: 'Gauge ${pid.id} at $rect must not overlap hinge $hingeRect',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('D02-03: stable contiguous PID split across panes (8 PIDs)', (
      tester,
    ) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 700),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      final pids = _testPids.sublist(0, 8);

      // 1. Folded state
      final harnessKey = await _pumpFoldableDashboard(
        tester,
        size: const Size(1000, 700),
        displayFeatures: const [hingeFeature],
        pids: pids,
      );

      // Left pane: P0..P3; Right pane: P4..P7
      for (var i = 0; i < 4; i++) {
        final center = tester.getCenter(
          find.byKey(ValueKey('dashboard-gauge-${pids[i].id}')),
        );
        expect(center.dx, lessThan(490));
      }
      for (var i = 4; i < 8; i++) {
        final center = tester.getCenter(
          find.byKey(ValueKey('dashboard-gauge-${pids[i].id}')),
        );
        expect(center.dx, greaterThan(510));
      }

      // 2. Unfold (no hinge)
      tester.view.physicalSize = const Size(1000, 700);
      harnessKey.currentState!.updateLayout(
        newSize: const Size(1000, 700),
        newFeatures: const [],
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // 3. Fold again
      harnessKey.currentState!.updateLayout(
        newSize: const Size(1000, 700),
        newFeatures: const [hingeFeature],
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify stable split and ordering are preserved
      for (var i = 0; i < 4; i++) {
        final center = tester.getCenter(
          find.byKey(ValueKey('dashboard-gauge-${pids[i].id}')),
        );
        expect(center.dx, lessThan(490));
      }
      for (var i = 4; i < 8; i++) {
        final center = tester.getCenter(
          find.byKey(ValueKey('dashboard-gauge-${pids[i].id}')),
        );
        expect(center.dx, greaterThan(510));
      }
    });

    testWidgets('D02-04: odd PID count allocates extra item to primary pane (7 PIDs)', (
      tester,
    ) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 700),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      final pids = _testPids.sublist(0, 7);
      await _pumpFoldableDashboard(
        tester,
        size: const Size(1000, 700),
        displayFeatures: const [hingeFeature],
        pids: pids,
      );

      // Primary pane gets (7 + 1) ~/ 2 = 4 (indices 0..3)
      for (var i = 0; i < 4; i++) {
        final center = tester.getCenter(
          find.byKey(ValueKey('dashboard-gauge-${pids[i].id}')),
        );
        expect(center.dx, lessThan(490), reason: 'PID $i should be in left pane');
      }
      // Secondary pane gets 3 (indices 4..6)
      for (var i = 4; i < 7; i++) {
        final center = tester.getCenter(
          find.byKey(ValueKey('dashboard-gauge-${pids[i].id}')),
        );
        expect(center.dx, greaterThan(510), reason: 'PID $i should be in right pane');
      }
    });

    testWidgets('D02-05: workspace mode survives fold and unfold transitions', (
      tester,
    ) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 700),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      final pids = _testPids.sublist(0, 4);

      // 1. Unfolded normal display
      final harnessKey = await _pumpFoldableDashboard(
        tester,
        size: const Size(1000, 700),
        displayFeatures: const [],
        pids: pids,
      );

      // Switch to Trends mode
      final trendsIconFinder = find.byIcon(Icons.show_chart);
      expect(trendsIconFinder, findsOneWidget);
      await tester.tap(trendsIconFinder);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TelemetryWorkspace), findsOneWidget);

      // 2. Fold device
      tester.view.physicalSize = const Size(1000, 700);
      harnessKey.currentState!.updateLayout(
        newSize: const Size(1000, 700),
        newFeatures: const [hingeFeature],
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Trends mode is retained
      expect(find.byType(TelemetryWorkspace), findsOneWidget);

      // 3. Unfold device again
      harnessKey.currentState!.updateLayout(
        newSize: const Size(1000, 700),
        newFeatures: const [],
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TelemetryWorkspace), findsOneWidget);
    });

    testWidgets('D02-06: scroll position survives fold and unfold', (
      tester,
    ) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 500),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      final pids = _testPids; // all 12 PIDs

      // 1. Pump unfolded
      final harnessKey = await _pumpFoldableDashboard(
        tester,
        size: const Size(1000, 500),
        displayFeatures: const [],
        pids: pids,
      );

      // Scroll down
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -150));
      await tester.pump(const Duration(milliseconds: 100));

      final scrollableBefore = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final offsetBefore = scrollableBefore.position.pixels;
      expect(offsetBefore, greaterThan(50));

      // 2. Fold device
      tester.view.physicalSize = const Size(1000, 500);
      harnessKey.currentState!.updateLayout(
        newSize: const Size(1000, 500),
        newFeatures: const [hingeFeature],
      );
      await tester.pump(const Duration(milliseconds: 300));

      final scrollableAfter = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final offsetAfter = scrollableAfter.position.pixels;
      expect(offsetAfter, closeTo(offsetBefore, 5.0));

      // 3. Unfold again
      harnessKey.currentState!.updateLayout(
        newSize: const Size(1000, 500),
        newFeatures: const [],
      );
      await tester.pump(const Duration(milliseconds: 300));

      final scrollableFinal = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollableFinal.position.pixels, closeTo(offsetBefore, 5.0));
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('D02-07: OBD connection session state survives fold/unfold rebuild', (
      tester,
    ) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 700),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      const testSessionState = ObdConnectionState(
        phase: ConnectionPhase.connected,
        kind: TransportKind.demo,
        deviceName: 'Persistent Demo ECU',
      );

      // 1. Pump normal
      final harnessKey = await _pumpFoldableDashboard(
        tester,
        size: const Size(1000, 700),
        displayFeatures: const [],
        connectionState: testSessionState,
        pids: _testPids.sublist(0, 4),
      );

      // Status strip displays connected state
      expect(find.textContaining('Demo ECU'), findsOneWidget);

      // 2. Fold
      tester.view.physicalSize = const Size(1000, 700);
      harnessKey.currentState!.updateLayout(
        newSize: const Size(1000, 700),
        newFeatures: const [hingeFeature],
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Still connected, same device
      expect(find.textContaining('Demo ECU'), findsOneWidget);

      // 3. Unfold
      harnessKey.currentState!.updateLayout(
        newSize: const Size(1000, 700),
        newFeatures: const [],
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Demo ECU'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('D02-08: NavigationRail + hinge coordinate projection in global space', (
      tester,
    ) async {
      const globalHinge = Rect.fromLTWH(490, 0, 20, 700);
      const hingeFeature = DisplayFeature(
        bounds: globalHinge,
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      final pids = _testPids.sublist(0, 6);
      await _pumpFoldableDashboard(
        tester,
        size: const Size(1000, 700),
        displayFeatures: const [hingeFeature],
        pids: pids,
        withShell: true,
      );

      // NavigationRail is present on the left
      expect(find.byType(NavigationRail), findsOneWidget);

      // In global coordinates, no gauge tile must ever overlap the global physical hinge 490..510
      for (final pid in pids) {
        final rect = tester.getRect(
          find.byKey(ValueKey('dashboard-gauge-${pid.id}')),
        );
        expect(
          rect.overlaps(globalHinge),
          isFalse,
          reason: 'Global gauge rect $rect must not overlap global hinge $globalHinge',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('D02-09: compact phone behavior (360x800 and 800x360) no regression', (
      tester,
    ) async {
      final pids = _testPids.sublist(0, 4);

      // 1. Portrait 360x800
      final harnessKey = await _pumpFoldableDashboard(
        tester,
        size: const Size(360, 800),
        pids: pids,
      );

      expect(tester.takeException(), isNull);
      for (final pid in pids) {
        expect(find.byKey(ValueKey('dashboard-gauge-${pid.id}')), findsOneWidget);
      }

      // 2. Landscape 800x360
      tester.view.physicalSize = const Size(800, 360);
      harnessKey.currentState!.updateLayout(
        newSize: const Size(800, 360),
        newFeatures: const [],
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      // In narrow landscape, scroll down so gauges enter the viewport
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
      await tester.pump(const Duration(milliseconds: 300));

      for (final pid in pids) {
        expect(find.byKey(ValueKey('dashboard-gauge-${pid.id}')), findsOneWidget);
      }

      // All 4 gauges in landscape fit in 1 row (4 columns)
      final y0 = tester.getTopLeft(find.byKey(ValueKey('dashboard-gauge-${pids[0].id}'))).dy;
      for (final pid in pids) {
        final y = tester.getTopLeft(find.byKey(ValueKey('dashboard-gauge-${pid.id}'))).dy;
        expect((y - y0).abs(), lessThan(1.0));
      }
    });

    testWidgets('D02-10: text scaling honors minimum tile width contract', (
      tester,
    ) async {
      final pids = _testPids.sublist(0, 4);

      // Normal text scale 1.0 at 600x800
      final harnessKey = await _pumpFoldableDashboard(
        tester,
        size: const Size(600, 800),
        textScaler: const TextScaler.linear(1.0),
        pids: pids,
      );
      expect(tester.takeException(), isNull);

      final tileWidth1 = tester.getRect(
        find.byKey(ValueKey('dashboard-gauge-${pids[0].id}')),
      ).width;

      // Large text scale 2.0
      harnessKey.currentState!.updateLayout(
        newSize: const Size(600, 800),
        newTextScaler: const TextScaler.linear(2.0),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      final tileWidth2 = tester.getRect(
        find.byKey(ValueKey('dashboard-gauge-${pids[0].id}')),
      ).width;

      // Minimum tile width scaled up: column count drops, so individual tile width must be larger
      expect(tileWidth2, greaterThan(tileWidth1));
    });

    testWidgets('D02-11: SafeArea + NavigationRail + hinge coordinate projection in global space', (
      tester,
    ) async {
      const globalHinge = Rect.fromLTWH(490, 0, 20, 700);
      const hingeFeature = DisplayFeature(
        bounds: globalHinge,
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      final pids = _testPids.sublist(0, 6);
      await _pumpFoldableDashboard(
        tester,
        size: const Size(1000, 700),
        displayFeatures: const [hingeFeature],
        padding: const EdgeInsets.only(left: 24, top: 40, right: 16),
        pids: pids,
        withShell: true,
      );

      // NavigationRail is present on the left
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(tester.takeException(), isNull);

      // In global coordinates, no gauge tile must ever overlap the global physical hinge 490..510
      for (final pid in pids) {
        final rect = tester.getRect(
          find.byKey(ValueKey('dashboard-gauge-${pid.id}')),
        );
        expect(
          rect.overlaps(globalHinge),
          isFalse,
          reason: 'Global gauge rect $rect must not overlap global hinge $globalHinge',
        );
      }

      // Verify the entire hinged row fits inside the safe content area without overflow
      final scrollableRect = tester.getRect(find.byType(CustomScrollView));
      expect(scrollableRect.left, greaterThanOrEqualTo(24.0));
      expect(scrollableRect.right, lessThanOrEqualTo(1000.0 - 16.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('D02-12: RTL directionality preserves physical hinge safety and pane order', (
      tester,
    ) async {
      const globalHinge = Rect.fromLTWH(490, 0, 20, 700);
      const hingeFeature = DisplayFeature(
        bounds: globalHinge,
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureFlat,
      );

      final pids = _testPids.sublist(0, 6);
      await _pumpFoldableDashboard(
        tester,
        size: const Size(1000, 700),
        displayFeatures: const [hingeFeature],
        padding: const EdgeInsets.only(left: 24, top: 40, right: 16),
        pids: pids,
        withShell: true,
        textDirection: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);

      // In global coordinates, no gauge tile must ever overlap the global physical hinge 490..510
      for (final pid in pids) {
        final rect = tester.getRect(
          find.byKey(ValueKey('dashboard-gauge-${pid.id}')),
        );
        expect(
          rect.overlaps(globalHinge),
          isFalse,
          reason: 'Global gauge rect $rect must not overlap global hinge $globalHinge in RTL',
        );
      }

      // In RTL, the primary (reading start) pane is the right pane, so the first PID must be on the right
      final firstGaugeCenter = tester.getCenter(
        find.byKey(ValueKey('dashboard-gauge-${pids[0].id}')),
      );
      expect(
        firstGaugeCenter.dx,
        greaterThan(510),
        reason: 'First PID in RTL should be in the primary (right) pane',
      );
    });

    testWidgets(
        'D02-13: ultra-wide short landscape (2400x200) clamps to 6 columns and scrolls vertically',
        (tester) async {
      final pids = _testPids.sublist(0, 8);
      await _pumpFoldableDashboard(
        tester,
        size: const Size(2400, 200),
        pids: pids,
        withShell: true,
      );

      expect(tester.takeException(), isNull);
      // Rail used for short landscape
      expect(find.byType(NavigationRail), findsOneWidget);

      // In a 200px high viewport, scroll down past toolbar/recorder to bring gauges into view
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      // Verify column cap of 6
      final firstGaugeFinder = find.byKey(ValueKey('dashboard-gauge-${pids[0].id}'));
      expect(firstGaugeFinder, findsOneWidget);
      final firstGaugeY = tester.getTopLeft(firstGaugeFinder).dy;
      var topRowCount = 0;
      for (final pid in pids) {
        final finder = find.byKey(ValueKey('dashboard-gauge-${pid.id}'));
        if (finder.evaluate().isNotEmpty) {
          final top = tester.getTopLeft(finder).dy;
          if ((top - firstGaugeY).abs() < 1.0) {
            topRowCount++;
          }
        }
      }
      expect(topRowCount, 6);
    });
  });
}
