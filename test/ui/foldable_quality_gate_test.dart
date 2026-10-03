/// Foldable Device-Quality Gate (FOLD-08).
///
/// Comprehensive integration and regression quality gate covering:
/// - Form factors: Narrow Cover (320x818), Compact, Short Landscape, Medium, Expanded, Large Expanded.
/// - Hinge/crease postures: Vertical flat, vertical half-open, horizontal tabletop, pure fold crease.
/// - Semantics: RTL mirroring, system font scale (2.0x), SafeArea + NavigationRail + hinge global projection.
/// - Surfaces: Dashboard, PID Manager, DTC, Performance, Connect Wizard, Adaptive Modals.
/// - Continuity: Dynamic resize/rotation without resetting state or leaking subscriptions.
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType, Rect, Size;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/l10n/generated/app_localizations_en.dart';
import 'package:torque_obd/obd/dtc/dtc.dart';
import 'package:torque_obd/obd/freeze_frame.dart';
import 'package:torque_obd/obd/physics/vehicle_profile.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/dtc_scan.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/settings.dart';
import 'package:torque_obd/state/telemetry_trends.dart';
import 'package:torque_obd/ui/adaptive/adaptive_layout.dart';
import 'package:torque_obd/ui/adaptive/adaptive_modal.dart';
import 'package:torque_obd/ui/adaptive/app_breakpoints.dart';
import 'package:torque_obd/ui/adaptive/display_feature_layout.dart';
import 'package:torque_obd/ui/screens/connect/connect_layout.dart';
import 'package:torque_obd/ui/screens/connect/connect_screen.dart';
import 'package:torque_obd/ui/screens/dashboard/dashboard_screen.dart';
import 'package:torque_obd/ui/screens/dashboard/telemetry_workspace.dart';
import 'package:torque_obd/ui/screens/dtc/dtc_screen.dart';
import 'package:torque_obd/ui/screens/performance/performance_screen.dart';
import 'package:torque_obd/ui/screens/pids/pid_manager_screen.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';
import 'package:torque_obd/ui/shell.dart';
import 'package:torque_obd/ui/widgets/language_picker.dart';
import 'package:torque_obd/ui/widgets/telemetry/telemetry_lane_selector.dart';

import '../support/foldable_device_profiles.dart';
import '../support/localized_app.dart';

final _en = AppLocalizationsEn();

// =============================================================================
// Layout Error Collector
// =============================================================================

final List<FlutterErrorDetails> _layoutErrors = [];
void Function(FlutterErrorDetails)? _prevOnError;

void _setupLayoutErrorCollector() {
  _layoutErrors.clear();
  _prevOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exceptionAsString();
    if (_isLayoutFailure(text)) {
      _layoutErrors.add(details);
      return;
    }
    _prevOnError?.call(details);
  };
}

bool _isLayoutFailure(String text) {
  return text.contains('A RenderFlex overflowed') ||
      text.contains('RenderBox was not laid out') ||
      text.contains('BoxConstraints forces an infinite') ||
      text.contains('Vertical viewport was given unbounded height') ||
      text.contains('Horizontal viewport was given unbounded width') ||
      text.contains('Cannot hit test a render box with no size');
}

void _tearDownLayoutErrorCollector() {
  FlutterError.onError = _prevOnError;
}

void expectNoLayoutErrors(WidgetTester tester) {
  final ex = tester.takeException();
  for (final err in _layoutErrors) {
    // ignore: avoid_print
    print('DEBUG LAYOUT_ERROR:\n${err.toDiagnosticsNode().toStringDeep()}');
  }
  expect(
    _layoutErrors,
    isEmpty,
    reason: 'Layout errors detected:\n${_layoutErrors.map((e) => e.exceptionAsString()).join('\n')}',
  );
  expect(ex, isNull);
}

void expectNoHingeOverlap(
  WidgetTester tester,
  Finder finder,
  Rect globalHinge,
) {
  final rect = tester.getRect(finder);
  expect(
    rect.overlaps(globalHinge),
    isFalse,
    reason: '$finder ($rect) overlaps hinge ($globalHinge)',
  );
}

// =============================================================================
// Test Fixtures & Mocks
// =============================================================================

final _gatePids = [
  PidLibrary.engineRpm,
  PidLibrary.vehicleSpeed,
  PidLibrary.coolantTemp,
  PidLibrary.intakeAirTemp,
  PidLibrary.engineLoad,
  PidLibrary.throttlePosition,
];

TelemetrySnapshot _gateTelemetrySnapshot({
  double speedKmh = 45.0,
  double rpm = 2400.0,
  double accelMs2 = 0.8,
}) {
  final now = DateTime.now();
  return TelemetrySnapshot(
    accelerationMs2: accelMs2,
    readings: {
      PidLibrary.vehicleSpeed.id: Reading(
        pid: PidLibrary.vehicleSpeed,
        value: speedKmh,
        rawBytes: [speedKmh.round().clamp(0, 255)],
        timestamp: now,
        receivedElapsed: const Duration(seconds: 1),
      ),
      PidLibrary.engineRpm.id: Reading(
        pid: PidLibrary.engineRpm,
        value: rpm,
        rawBytes: [0x0A, 0xF0],
        timestamp: now,
        receivedElapsed: const Duration(seconds: 1),
      ),
    },
  );
}

final _defaultGateTelemetry = _gateTelemetrySnapshot();

class _GateConnectedSession extends ObdSession {
  _GateConnectedSession({this.connected = true});
  final bool connected;

  @override
  ObdConnectionState build() => ObdConnectionState(
        phase: connected ? ConnectionPhase.connected : ConnectionPhase.disconnected,
        kind: TransportKind.demo,
        deviceName: 'Demo ECU',
      );
}

class _GateFixedActivePids extends ActivePids {
  _GateFixedActivePids(this._pids);
  final List<Pid> _pids;

  @override
  List<Pid> build() => _pids;
}

class _GateFixedProfile extends VehicleProfileController {
  @override
  VehicleProfile build() => const VehicleProfile();
}

const _kP0300Ecm = Dtc(
  code: 'P0300',
  category: DtcCategory.powertrain,
  kind: DtcKind.stored,
  sourceId: '7E8',
  isManufacturerSpecific: false,
);

const _kP0300Tcm = Dtc(
  code: 'P0300',
  category: DtcCategory.powertrain,
  kind: DtcKind.stored,
  sourceId: '7E9',
  isManufacturerSpecific: false,
);

const _kP0420Ecm = Dtc(
  code: 'P0420',
  category: DtcCategory.powertrain,
  kind: DtcKind.pending,
  sourceId: '7E8',
  isManufacturerSpecific: false,
);

DtcScanState _standardScanWithCodes({
  List<Dtc> storedCodes = const [_kP0300Ecm],
  List<Dtc> pendingCodes = const [],
  List<Dtc> partialCodes = const [],
  List<FreezeFrame> freezeFrames = const [],
  MilStatus? mil,
}) {
  return DtcScanState(
    scannedAt: DateTime(2026, 8, 17),
    vin: '1HGCR2F83HA000000',
    results: {
      DtcKind.stored: DtcCategoryResult.codes(storedCodes),
      DtcKind.pending: partialCodes.isNotEmpty
          ? DtcCategoryResult.failed(
              DtcReadException(
                'partial',
                kind: DtcReadFailure.error,
                partial: partialCodes,
              ),
            )
          : DtcCategoryResult.codes(pendingCodes),
      DtcKind.permanent: const DtcCategoryResult.codes([]),
    },
    freezeFrames: freezeFrames,
    mil: mil,
  );
}

class _GateDtcScanNotifier extends DtcScanNotifier {
  _GateDtcScanNotifier(this._initial);
  final DtcScanState _initial;

  @override
  DtcScanState build() => _initial;

  @override
  Future<void> scan() async {
    state = _initial;
  }

  @override
  Future<void> clear() async {
    state = const DtcScanState();
  }
}

class _GateTelemetryTrendsNotifier extends TelemetryTrendsNotifier {
  List<String>? updatedIds;

  @override
  TelemetryTrendsState build() {
    return TelemetryTrendsState(
      lanes: const {},
      selectedIds: const ['010C'],
      windowEndElapsedUs: 0,
    );
  }

  @override
  Future<TelemetryTrendSelectionOutcome> setSelectedIds(List<String> ids) async {
    updatedIds = ids;
    return TelemetryTrendSelectionOutcome.applied;
  }
}

int _gateTick = 0;

TelemetrySnapshot _speedSnapshot(
  double? kmh, {
  Duration? elapsed,
  Duration age = Duration.zero,
}) {
  final tick = _gateTick++;
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

// =============================================================================
// Deformable Quality Harness
// =============================================================================

class _FoldableQualityHarnessController {
  _FoldableQualityHarnessState? _state;

  Future<void> applyProfile(
    WidgetTester tester,
    FoldableDeviceProfile profile,
  ) async {
    tester.view.physicalSize = profile.size;
    tester.view.devicePixelRatio = 1.0;
    tester.view.displayFeatures = profile.displayFeatures;
    _state?.updateProfile(profile);
    await _settle(tester);
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _emitSpeed(
  WidgetTester tester,
  StreamController<TelemetrySnapshot> streamCtrl,
  TelemetrySnapshot snapshot,
) async {
  streamCtrl.add(snapshot);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump();
}

class _FoldableQualityHarness extends StatefulWidget {
  const _FoldableQualityHarness({
    required this.controller,
    required this.initialProfile,
    required this.builder,
  });

  final _FoldableQualityHarnessController controller;
  final FoldableDeviceProfile initialProfile;
  final Widget Function(BuildContext context, FoldableDeviceProfile profile) builder;

  @override
  State<_FoldableQualityHarness> createState() => _FoldableQualityHarnessState();
}

class _FoldableQualityHarnessState extends State<_FoldableQualityHarness> {
  late FoldableDeviceProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    widget.controller._state = this;
  }

  void updateProfile(FoldableDeviceProfile profile) {
    setState(() {
      _profile = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(
        size: _profile.size,
        displayFeatures: _profile.displayFeatures,
        padding: _profile.safeInsets,
        viewInsets: _profile.viewInsets,
        textScaler: _profile.textScaler,
      ),
      child: widget.builder(context, _profile),
    );
  }
}

GoRouter _createGateRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const ConnectScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: DashboardScreen.path,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: PidManagerScreen.path,
            builder: (context, state) => const PidManagerScreen(),
          ),
          GoRoute(
            path: DtcScreen.path,
            builder: (context, state) => const DtcScreen(),
          ),
          GoRoute(
            path: PerformanceScreen.path,
            builder: (context, state) => const PerformanceScreen(),
          ),
          GoRoute(
            path: SettingsScreen.path,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

Future<void> _pumpGateApp(
  WidgetTester tester, {
  required _FoldableQualityHarnessController controller,
  required FoldableDeviceProfile initialProfile,
  String initialLocation = DashboardScreen.path,
  DtcScanState? dtcScan,
  Stream<TelemetrySnapshot>? telemetryStream,
  List<dynamic> extraOverrides = const [],
}) async {
  tester.view.physicalSize = initialProfile.size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.displayFeatures = initialProfile.displayFeatures;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetDisplayFeatures);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final router = _createGateRouter(initialLocation: initialLocation);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        obdSessionProvider.overrideWith(() => _GateConnectedSession(connected: true)),
        activePidsProvider.overrideWith(() => _GateFixedActivePids(_gatePids)),
        vehicleProfileProvider.overrideWith(() => _GateFixedProfile()),
        telemetryProvider.overrideWith(
          (ref) => telemetryStream ?? Stream.value(_defaultGateTelemetry),
        ),
        dtcScanProvider.overrideWith(
          () => _GateDtcScanNotifier(
            dtcScan ??
                _standardScanWithCodes(
                  storedCodes: [_kP0300Ecm, _kP0300Tcm],
                  pendingCodes: [_kP0420Ecm],
                ),
          ),
        ),
        ...extraOverrides.cast(),
      ],
      child: _FoldableQualityHarness(
        controller: controller,
        initialProfile: initialProfile,
        builder: (context, currentProfile) => localizedMaterialAppRouter(
          routerConfig: router,
          locale: currentProfile.locale,
          theme: AppTheme.dark(),
          builder: (context, child) => Directionality(
            textDirection: currentProfile.textDirection,
            child: child!,
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
}

// =============================================================================
// MAIN TEST SUITE
// =============================================================================

void main() {
  setUp(_setupLayoutErrorCollector);
  tearDown(_tearDownLayoutErrorCollector);

  // ---------------------------------------------------------------------------
  // 1. Window Class and Shell Navigation Transitions (F08-01 ~ F08-05)
  // ---------------------------------------------------------------------------
  group('Window Class and Shell Navigation Transitions (F08-01 ~ F08-05)', () {
    testWidgets('F08-01: Narrow Cover 320x818 uses NavigationBar, 0 overflow, scrollable', (tester) async {
      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.narrowCover,
        initialLocation: DashboardScreen.path,
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-02: Compact 360x800 uses NavigationBar and all destinations reachable', (tester) async {
      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.compactPortrait,
        initialLocation: DashboardScreen.path,
      );

      expect(find.byType(NavigationBar), findsOneWidget);

      // Navigate to PIDs
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await _settle(tester);
      expect(find.byType(PidManagerScreen), findsOneWidget);

      // Navigate to DTC
      await tester.tap(find.byIcon(Icons.warning_amber_outlined));
      await _settle(tester);
      expect(find.byType(DtcScreen), findsOneWidget);

      // Navigate to Performance
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await _settle(tester);
      expect(find.byType(PerformanceScreen), findsOneWidget);

      // Navigate back to Dashboard
      await tester.tap(find.byIcon(Icons.speed_outlined));
      await _settle(tester);
      expect(find.byType(DashboardScreen), findsOneWidget);

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-03: Compact Short Landscape 568x320 uses scrollable NavigationRail', (tester) async {
      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.compactShortLandscape,
        initialLocation: DashboardScreen.path,
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.scrollable, isTrue);

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-04: Medium 700x900 uses NavigationRail and accounts for rail width', (tester) async {
      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.medium,
        initialLocation: DashboardScreen.path,
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      final railRect = tester.getRect(find.byType(NavigationRail));
      expect(railRect.width, greaterThan(0.0));
      expect(railRect.left, equals(0.0));

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-05: Expanded 1000x800 uses NavigationRail and expanded policy active', (tester) async {
      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.expandedInner,
        initialLocation: DashboardScreen.path,
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      final adaptive = AdaptiveLayout.of(tester.element(find.byType(DashboardScreen)));
      expect(adaptive.windowClass, equals(AppWindowClass.expanded));

      expectNoLayoutErrors(tester);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Hinge and Pure Crease Semantics (F08-06 ~ F08-09)
  // ---------------------------------------------------------------------------
  group('Hinge and Pure Crease Semantics (F08-06 ~ F08-09)', () {
    test('F08-06: Vertical physical hinge + postureFlat is separating hinge with 0 overlap', () {
      final adaptive = AdaptiveLayout.fromValues(
        size: const Size(1000, 800),
        displayFeatures: const [FoldableDeviceProfiles.verticalFlatHinge],
      );

      expect(adaptive.hasVerticalSeparator, isTrue);
      expect(adaptive.regions.length, equals(2));
      expect(adaptive.regions[0].right, lessThanOrEqualTo(490.0));
      expect(adaptive.regions[1].left, greaterThanOrEqualTo(510.0));
      expect(adaptive.regions[0].overlaps(FoldableDeviceProfiles.verticalFlatHinge.bounds), isFalse);
      expect(adaptive.regions[1].overlaps(FoldableDeviceProfiles.verticalFlatHinge.bounds), isFalse);
    });

    test('F08-07: Vertical fold crease does NOT produce artificial two-region gap', () {
      final adaptive = AdaptiveLayout.fromValues(
        size: const Size(1000, 800),
        displayFeatures: const [FoldableDeviceProfiles.flatCrease],
      );

      expect(adaptive.hasVerticalSeparator, isFalse);
      expect(adaptive.regions.length, equals(1));
      expect(adaptive.regions.first, equals(const Rect.fromLTWH(0, 0, 1000, 800)));
    });

    test('F08-08: Vertical half-open hinge behaves identically to physical separator contract', () {
      final adaptive = AdaptiveLayout.fromValues(
        size: const Size(1000, 800),
        displayFeatures: const [FoldableDeviceProfiles.verticalHalfOpenHinge],
      );

      expect(adaptive.hasVerticalSeparator, isTrue);
      expect(adaptive.regions.length, equals(2));
      expect(adaptive.regions[0].right, lessThanOrEqualTo(490.0));
      expect(adaptive.regions[1].left, greaterThanOrEqualTo(510.0));
    });

    test('F08-09: Tabletop horizontal hinge splits into top and bottom regions avoiding hinge', () {
      final adaptive = AdaptiveLayout.fromValues(
        size: const Size(800, 800),
        displayFeatures: const [FoldableDeviceProfiles.tabletopHinge],
      );

      expect(adaptive.hasHorizontalSeparator, isTrue);
      expect(adaptive.regions.length, equals(2));
      expect(adaptive.regions[0].bottom, lessThanOrEqualTo(390.0));
      expect(adaptive.regions[1].top, greaterThanOrEqualTo(410.0));
      expect(adaptive.regions[0].overlaps(FoldableDeviceProfiles.tabletopHinge.bounds), isFalse);
      expect(adaptive.regions[1].overlaps(FoldableDeviceProfiles.tabletopHinge.bounds), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Dashboard Screen Quality Gate (F08-10 ~ F08-12)
  // ---------------------------------------------------------------------------
  group('Dashboard Screen Quality Gate (F08-10 ~ F08-12)', () {
    testWidgets('F08-10: Dashboard narrow cover reachable without overflow', (tester) async {
      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.narrowCover,
        initialLocation: DashboardScreen.path,
      );

      expect(find.byType(DashboardScreen), findsOneWidget);

      final derivedFinder = find.byIcon(Icons.functions);
      for (var i = 0; i < 8 && derivedFinder.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await _settle(tester);
      }
      expect(derivedFinder.hitTestable(), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-11: Dashboard vertical hinge partitions gauges with 0 hinge overlap', (tester) async {
      final controller = _FoldableQualityHarnessController();
      final hingeProfile = FoldableDeviceProfiles.expandedInner.copyWith(
        displayFeatures: const [FoldableDeviceProfiles.verticalHalfOpenHinge],
      );

      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: hingeProfile,
        initialLocation: DashboardScreen.path,
      );

      expect(find.byType(DashboardScreen), findsOneWidget);

      final hingeBounds = FoldableDeviceProfiles.verticalHalfOpenHinge.bounds;
      var checkedGauges = 0;
      for (final pid in _gatePids) {
        final gaugeFinder = find.byKey(ValueKey('dashboard-gauge-${pid.id}'));
        if (gaugeFinder.evaluate().isNotEmpty) {
          expectNoHingeOverlap(tester, gaugeFinder, hingeBounds);
          checkedGauges++;
        }
      }
      expect(checkedGauges, greaterThan(0));

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-12: Dashboard rotate portrait->landscape->portrait preserves state', (tester) async {
      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.compactPortrait,
        initialLocation: DashboardScreen.path,
      );

      // Switch to Trends workspace
      final trendsFinder = find.text('Trends');
      await tester.tap(trendsFinder);
      await _settle(tester);

      for (var i = 0; i < 5 && find.byType(TelemetryWorkspace).evaluate().isEmpty; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await _settle(tester);
      }
      expect(find.byType(TelemetryWorkspace), findsOneWidget);

      // Rotate to landscape
      await controller.applyProfile(
        tester,
        FoldableDeviceProfiles.compactPortrait.copyWith(size: const Size(800, 360)),
      );
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(TelemetryWorkspace), findsOneWidget);

      // Rotate back to portrait
      await controller.applyProfile(tester, FoldableDeviceProfiles.compactPortrait);
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(TelemetryWorkspace), findsOneWidget);

      expectNoLayoutErrors(tester);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. PID Manager Screen Quality Gate (F08-13 ~ F08-15)
  // ---------------------------------------------------------------------------
  group('PID Manager Screen Quality Gate (F08-13 ~ F08-15)', () {
    testWidgets('F08-13: PID expanded renders master list + detail placeholder', (tester) async {
      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.expandedInner,
        initialLocation: PidManagerScreen.path,
      );

      expect(find.byKey(const PageStorageKey('pid-master-scroll')), findsOneWidget);
      expect(find.byKey(const ValueKey('pid-detail-empty')), findsOneWidget);
      expect(find.byType(AdaptiveTwoPane), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-14: PID vertical hinge selection isolates master & detail with 0 overlap', (tester) async {
      final controller = _FoldableQualityHarnessController();
      final hingeProfile = FoldableDeviceProfiles.expandedInner.copyWith(
        displayFeatures: const [FoldableDeviceProfiles.verticalHalfOpenHinge],
      );

      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: hingeProfile,
        initialLocation: PidManagerScreen.path,
      );

      // Tap on Engine RPM PID row
      final rpmRow = find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}'));
      expect(rpmRow, findsOneWidget);
      await tester.tap(rpmRow);
      await tester.pumpAndSettle();

      // Master and Detail are both visible
      final masterFinder = find.byKey(const PageStorageKey('pid-master-scroll'));
      final detailFinder = find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}'));
      expect(masterFinder, findsOneWidget);
      expect(detailFinder, findsOneWidget);

      final hingeBounds = FoldableDeviceProfiles.verticalHalfOpenHinge.bounds;
      expectNoHingeOverlap(tester, masterFinder, hingeBounds);
      expectNoHingeOverlap(tester, detailFinder, hingeBounds);

      final masterRect = tester.getRect(masterFinder);
      final detailRect = tester.getRect(detailFinder);
      expect(masterRect.right, lessThanOrEqualTo(hingeBounds.left));
      expect(detailRect.left, greaterThanOrEqualTo(hingeBounds.right));

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-15: PID selection survives expanded->compact->expanded fold/unfold', (tester) async {
      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.expandedInner,
        initialLocation: PidManagerScreen.path,
      );

      // Select RPM
      await tester.tap(find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}')));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')), findsOneWidget);

      // Fold to compact
      await controller.applyProfile(tester, FoldableDeviceProfiles.compactPortrait);
      expect(find.byKey(const ValueKey('pid-detail-empty')), findsNothing);
      expect(find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')), findsNothing);
      expect(find.byKey(const PageStorageKey('pid-master-scroll')), findsOneWidget);

      // Unfold back to expanded
      await controller.applyProfile(tester, FoldableDeviceProfiles.expandedInner);
      expect(find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')), findsOneWidget);
      expect(find.byKey(const ValueKey('pid-detail-empty')), findsNothing);
      expect(find.byKey(const PageStorageKey('pid-master-scroll')), findsOneWidget);

      expectNoLayoutErrors(tester);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. DTC Screen Quality Gate (F08-16 ~ F08-18)
  // ---------------------------------------------------------------------------
  group('DTC Screen Quality Gate (F08-16 ~ F08-18)', () {
    testWidgets('F08-16: DTC expanded displays System Overview, NEVER auto-selects first DTC', (tester) async {
      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.expandedInner,
        initialLocation: DtcScreen.path,
      );

      expect(find.byKey(const ValueKey('dtc-master-list')), findsOneWidget);
      expect(find.byKey(const ValueKey('dtc-system-overview-pane')), findsOneWidget);
      expect(find.byKey(const ValueKey('dtc-detail-pane')), findsNothing);

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-17: DTC same code / two controllers + hinge selects exact 7E9 frame', (tester) async {
      const frameEcm = FreezeFrame(
        source: '7E8',
        frameNumber: 0,
        cause: _kP0300Ecm,
        readings: [
          FreezeReading(
            pid: Pid(
              name: 'Engine RPM',
              shortName: 'RPM',
              modeAndPid: '010C',
              equation: 'A',
              minValue: 0,
              maxValue: 8000,
              units: 'rpm',
            ),
            value: 2800,
            raw: [0x0A, 0xF0],
          ),
        ],
        undecodable: 0,
        unread: 0,
      );

      const frameTcm = FreezeFrame(
        source: '7E9',
        frameNumber: 0,
        cause: _kP0300Tcm,
        readings: [
          FreezeReading(
            pid: Pid(
              name: 'Vehicle Speed',
              shortName: 'Speed',
              modeAndPid: '010D',
              equation: 'A',
              minValue: 0,
              maxValue: 255,
              units: 'km/h',
            ),
            value: 65,
            raw: [0x41],
          ),
        ],
        undecodable: 0,
        unread: 0,
      );

      final scan = _standardScanWithCodes(
        storedCodes: [_kP0300Ecm, _kP0300Tcm],
        freezeFrames: [frameEcm, frameTcm],
      );

      final controller = _FoldableQualityHarnessController();
      final hingeProfile = FoldableDeviceProfiles.expandedInner.copyWith(
        displayFeatures: const [FoldableDeviceProfiles.verticalHalfOpenHinge],
      );

      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: hingeProfile,
        initialLocation: DtcScreen.path,
        dtcScan: scan,
      );

      // Tap on the DTC row with 7E9 source
      final tcmRow = find.byKey(const ValueKey('dtc-card-P0300-7E9'));
      expect(tcmRow, findsOneWidget);
      await tester.tap(tcmRow);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('dtc-detail-pane')), findsOneWidget);

      // Assert exact 7E9 frame reading is bound and 7E8 reading is absent
      expect(find.text('Vehicle Speed'), findsOneWidget);
      expect(find.textContaining('65'), findsOneWidget);
      expect(find.text('Engine RPM'), findsNothing);
      expect(find.textContaining('2800'), findsNothing);

      final hingeBounds = FoldableDeviceProfiles.verticalHalfOpenHinge.bounds;
      expectNoHingeOverlap(tester, find.byKey(const ValueKey('dtc-master-list')), hingeBounds);
      expectNoHingeOverlap(tester, find.byKey(const ValueKey('dtc-detail-pane')), hingeBounds);

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-18: DTC selection survives expanded->compact->expanded fold/unfold', (tester) async {
      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.expandedInner,
        initialLocation: DtcScreen.path,
      );

      // Select 7E8 P0300
      await tester.tap(find.byKey(const ValueKey('dtc-card-P0300-7E8')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dtc-detail-pane')), findsOneWidget);

      // Fold to compact
      await controller.applyProfile(tester, FoldableDeviceProfiles.compactPortrait);
      expect(find.byKey(const ValueKey('dtc-master-list')), findsNothing);

      // Unfold back to expanded
      await controller.applyProfile(tester, FoldableDeviceProfiles.expandedInner);
      expect(find.byKey(const ValueKey('dtc-detail-pane')), findsOneWidget);

      expectNoLayoutErrors(tester);
    });
  });

  // ---------------------------------------------------------------------------
  // 6. Performance Screen Quality Gate (F08-19 ~ F08-22)
  // ---------------------------------------------------------------------------
  group('Performance Screen Quality Gate (F08-19 ~ F08-22)', () {
    testWidgets('F08-19: Performance expanded renders Cockpit + Analysis partitions', (tester) async {
      final streamCtrl = StreamController<TelemetrySnapshot>.broadcast();
      addTearDown(streamCtrl.close);
      streamCtrl.add(_speedSnapshot(0));

      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.expandedInner,
        initialLocation: PerformanceScreen.path,
        telemetryStream: streamCtrl.stream,
      );

      expect(find.byKey(const ValueKey('performance-primary-pane')), findsOneWidget);
      expect(find.byKey(const ValueKey('performance-secondary-pane')), findsOneWidget);
      expect(find.byKey(const ValueKey('performance-page-scroll')), findsNothing);

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-20: Performance staged state survives fold/unfold', (tester) async {
      final streamCtrl = StreamController<TelemetrySnapshot>.broadcast();
      addTearDown(streamCtrl.close);

      var elapsedSec = 0;
      TelemetrySnapshot snapshot(double kmh) {
        elapsedSec += 1;
        return _speedSnapshot(kmh, elapsed: Duration(seconds: elapsedSec));
      }

      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.expandedInner,
        initialLocation: PerformanceScreen.path,
        telemetryStream: streamCtrl.stream,
      );

      // Supply live speed signal at standstill (0 km/h) to enable Arm button
      await _emitSpeed(tester, streamCtrl, snapshot(0));

      // Tap Arm
      await tester.tap(find.text(_en.performanceArm));
      await tester.pump();

      // Feed standstill sample so run transitions from awaitingStandstill to staged
      await _emitSpeed(tester, streamCtrl, snapshot(0));
      expect(find.text(_en.performanceStateStaged), findsOneWidget);

      // Fold to compact
      await controller.applyProfile(tester, FoldableDeviceProfiles.compactPortrait);
      expect(find.text(_en.performanceStateStaged), findsOneWidget);

      // Unfold back to expanded
      await controller.applyProfile(tester, FoldableDeviceProfiles.expandedInner);
      expect(find.text(_en.performanceStateStaged), findsOneWidget);

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-21: Performance running run survives resize', (tester) async {
      final streamCtrl = StreamController<TelemetrySnapshot>.broadcast();
      addTearDown(streamCtrl.close);

      var elapsedSec = 0;
      TelemetrySnapshot snapshot(double kmh) {
        elapsedSec += 1;
        return _speedSnapshot(kmh, elapsed: Duration(seconds: elapsedSec));
      }

      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.expandedInner,
        initialLocation: PerformanceScreen.path,
        telemetryStream: streamCtrl.stream,
      );

      // Supply live speed signal at standstill
      await _emitSpeed(tester, streamCtrl, snapshot(0));

      // Arm and trigger start
      await tester.tap(find.text(_en.performanceArm));
      await tester.pump();

      // Stage with standstill, then launch to running
      await _emitSpeed(tester, streamCtrl, snapshot(0));
      await _emitSpeed(tester, streamCtrl, snapshot(15));

      expect(find.text(_en.performanceStateRunning), findsWidgets);

      // Resize during running
      await controller.applyProfile(tester, FoldableDeviceProfiles.compactPortrait);
      expect(find.text(_en.performanceStateRunning), findsWidgets);

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-22: Performance resize then reach target completes run cleanly', (tester) async {
      final streamCtrl = StreamController<TelemetrySnapshot>.broadcast();
      addTearDown(streamCtrl.close);

      var elapsedSec = 0;
      TelemetrySnapshot snapshot(double kmh) {
        elapsedSec += 1;
        return _speedSnapshot(kmh, elapsed: Duration(seconds: elapsedSec));
      }

      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.compactPortrait,
        initialLocation: PerformanceScreen.path,
        telemetryStream: streamCtrl.stream,
      );

      // Supply live speed signal at standstill
      await _emitSpeed(tester, streamCtrl, snapshot(0));

      await tester.tap(find.text(_en.performanceArm));
      await tester.pump();

      // Stage with standstill, then launch
      await _emitSpeed(tester, streamCtrl, snapshot(0));
      await _emitSpeed(tester, streamCtrl, snapshot(15));

      // Resize to expanded
      await controller.applyProfile(tester, FoldableDeviceProfiles.expandedInner);

      // Complete run at target speed 100 km/h (within speedAbsenceGrace 1500ms)
      await _emitSpeed(tester, streamCtrl, snapshot(50));
      await _emitSpeed(tester, streamCtrl, snapshot(105));

      expect(find.text(_en.performanceStateFinished(100)), findsOneWidget);
      expectNoLayoutErrors(tester);
    });
  });

  // ---------------------------------------------------------------------------
  // 7. Connection Wizard & Workflow Containment (F08-23 ~ F08-27)
  // ---------------------------------------------------------------------------
  group('Connection Wizard & Workflow Containment (F08-23 ~ F08-27)', () {
    testWidgets('F08-23: Connect expanded has width <= 600 and is centered', (tester) async {
      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.expandedInner,
        initialLocation: '/',
      );

      final scrollFinder = find.byType(CustomScrollView);
      expect(scrollFinder, findsOneWidget);

      final rect = tester.getRect(scrollFinder);
      expect(rect.width, lessThanOrEqualTo(ConnectLayout.maxContentWidth));
      expect(rect.center.dx, closeTo(500.0, 5.0));

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-24: Connect narrow short landscape is fully scrollable to action', (tester) async {
      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.compactShortLandscape,
        initialLocation: '/',
      );

      expect(find.byType(CustomScrollView), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Demo simulator'),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Demo simulator'), findsOneWidget);

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-25: Connect vertical hinge isolates wizard to primary physical region', (tester) async {
      final controller = _FoldableQualityHarnessController();
      final hingeProfile = FoldableDeviceProfiles.expandedInner.copyWith(
        displayFeatures: const [FoldableDeviceProfiles.verticalHalfOpenHinge],
      );

      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: hingeProfile,
        initialLocation: '/',
      );

      final scrollFinder = find.byType(CustomScrollView);
      expect(scrollFinder, findsOneWidget);

      final rect = tester.getRect(scrollFinder);
      expect(rect.right, lessThanOrEqualTo(490.0));
      expect(rect.overlaps(FoldableDeviceProfiles.verticalHalfOpenHinge.bounds), isFalse);

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-26: Connect tabletop isolates wizard to top primary region', (tester) async {
      final controller = _FoldableQualityHarnessController();
      const tabletopProfile = FoldableDeviceProfile(
        name: 'Tabletop',
        size: Size(800, 800),
        displayFeatures: [FoldableDeviceProfiles.tabletopHinge],
      );

      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: tabletopProfile,
        initialLocation: '/',
      );

      final scrollFinder = find.byType(CustomScrollView);
      expect(scrollFinder, findsOneWidget);

      final rect = tester.getRect(scrollFinder);
      expect(rect.bottom, lessThanOrEqualTo(390.0));
      expect(rect.overlaps(FoldableDeviceProfiles.tabletopHinge.bounds), isFalse);

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-27: Connect transport expansion survives resize', (tester) async {
      final controller = _FoldableQualityHarnessController();
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: FoldableDeviceProfiles.expandedInner,
        initialLocation: '/',
      );

      // Tap Wi-Fi card to expand
      await tester.tap(find.text('Wi-Fi'));
      await tester.pumpAndSettle();
      expect(find.text('IP address'), findsOneWidget);

      // Morph to compact
      await controller.applyProfile(tester, FoldableDeviceProfiles.compactPortrait);
      expect(find.text('IP address'), findsOneWidget);

      expectNoLayoutErrors(tester);
    });
  });

  // ---------------------------------------------------------------------------
  // 8. Directionality & RTL Hinge Mirroring (F08-28 ~ F08-29)
  // ---------------------------------------------------------------------------
  group('Directionality & RTL Hinge Mirroring (F08-28 ~ F08-29)', () {
    testWidgets('F08-28: RTL vertical hinge places Secondary physical left and Primary physical right across PID, DTC, Performance', (tester) async {
      final controller = _FoldableQualityHarnessController();
      final rtlHingeProfile = FoldableDeviceProfiles.expandedInner.copyWith(
        displayFeatures: const [FoldableDeviceProfiles.verticalHalfOpenHinge],
        textDirection: TextDirection.rtl,
      );
      final hinge = FoldableDeviceProfiles.verticalHalfOpenHinge.bounds;

      // 1. Performance in RTL
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: rtlHingeProfile,
        initialLocation: PerformanceScreen.path,
      );

      final perfPrimary = find.byKey(const ValueKey('performance-primary-pane'));
      final perfSecondary = find.byKey(const ValueKey('performance-secondary-pane'));
      expect(perfPrimary, findsOneWidget);
      expect(perfSecondary, findsOneWidget);

      final perfPrimaryRect = tester.getRect(perfPrimary);
      final perfSecondaryRect = tester.getRect(perfSecondary);
      expect(perfSecondaryRect.right, lessThanOrEqualTo(hinge.left));
      expect(perfPrimaryRect.left, greaterThanOrEqualTo(hinge.right));
      expectNoHingeOverlap(tester, perfPrimary, hinge);
      expectNoHingeOverlap(tester, perfSecondary, hinge);

      // 2. PID Manager in RTL
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();

      final pidRpm = find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}'));
      expect(pidRpm, findsOneWidget);
      await tester.tap(pidRpm);
      await tester.pumpAndSettle();

      final pidMaster = find.byKey(const PageStorageKey('pid-master-scroll'));
      final pidDetail = find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}'));
      expect(pidMaster, findsOneWidget);
      expect(pidDetail, findsOneWidget);

      final pidMasterRect = tester.getRect(pidMaster);
      final pidDetailRect = tester.getRect(pidDetail);
      expect(pidDetailRect.right, lessThanOrEqualTo(hinge.left));
      expect(pidMasterRect.left, greaterThanOrEqualTo(hinge.right));
      expectNoHingeOverlap(tester, pidMaster, hinge);
      expectNoHingeOverlap(tester, pidDetail, hinge);

      // 3. DTC in RTL
      await tester.tap(find.byIcon(Icons.warning_amber_outlined));
      await tester.pumpAndSettle();

      final dtcCard = find.byKey(const ValueKey('dtc-card-P0300-7E8'));
      expect(dtcCard, findsOneWidget);
      await tester.tap(dtcCard);
      await tester.pumpAndSettle();

      final dtcMaster = find.byKey(const ValueKey('dtc-master-list'));
      final dtcDetail = find.byKey(const ValueKey('dtc-detail-pane'));
      expect(dtcMaster, findsOneWidget);
      expect(dtcDetail, findsOneWidget);

      final dtcMasterRect = tester.getRect(dtcMaster);
      final dtcDetailRect = tester.getRect(dtcDetail);
      expect(dtcDetailRect.right, lessThanOrEqualTo(hinge.left));
      expect(dtcMasterRect.left, greaterThanOrEqualTo(hinge.right));
      expectNoHingeOverlap(tester, dtcMaster, hinge);
      expectNoHingeOverlap(tester, dtcDetail, hinge);

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-29: RTL Connect places wizard in primary region and Language modal in physical right avoiding hinge', (tester) async {
      final controller = _FoldableQualityHarnessController();
      final rtlHingeProfile = FoldableDeviceProfiles.expandedInner.copyWith(
        displayFeatures: const [FoldableDeviceProfiles.verticalHalfOpenHinge],
        textDirection: TextDirection.rtl,
      );
      final hinge = FoldableDeviceProfiles.verticalHalfOpenHinge.bounds;

      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: rtlHingeProfile,
        initialLocation: '/',
      );

      final scrollFinder = find.byType(CustomScrollView);
      expect(scrollFinder, findsOneWidget);

      final rect = tester.getRect(scrollFinder);
      // In RTL: primary region is on the physical right
      expect(rect.left, greaterThanOrEqualTo(hinge.right));
      expect(rect.overlaps(hinge), isFalse);

      // Open Language modal from connect screen
      final langButton = find.byKey(const Key('connect_language_entry'));
      expect(langButton, findsOneWidget);
      await tester.scrollUntilVisible(
        langButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(langButton);
      await tester.pumpAndSettle();

      // Language picker modal is open with regionPreference.leading
      // In RTL: leading resolves to physical right
      final langPicker = find.byType(LanguagePicker);
      expect(langPicker, findsOneWidget);

      final modalRect = tester.getRect(langPicker);
      expect(modalRect.left, greaterThanOrEqualTo(hinge.right));
      expectNoHingeOverlap(tester, langPicker, hinge);

      // Close modal by tapping backdrop on left
      await tester.tapAt(const Offset(100, 100));
      await tester.pumpAndSettle();
      expect(find.byType(LanguagePicker), findsNothing);

      expectNoLayoutErrors(tester);
    });
  });

  // ---------------------------------------------------------------------------
  // 9. Accessibility & Extreme Font Scale (F08-30 ~ F08-32)
  // ---------------------------------------------------------------------------
  group('Accessibility & Extreme Font Scale (F08-30 ~ F08-32)', () {
    testWidgets('F08-30: Narrow Cover + textScale 2.0 has 0 layout overflow across Dashboard, PID, DTC, Performance', (tester) async {
      final controller = _FoldableQualityHarnessController();
      final a11yProfile = FoldableDeviceProfiles.narrowCover.copyWith(
        textScaler: const TextScaler.linear(2.0),
      );

      // 1. Dashboard
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: a11yProfile,
        initialLocation: DashboardScreen.path,
      );
      expect(find.byType(DashboardScreen), findsOneWidget);

      final derivedFinder = find.byIcon(Icons.functions);
      for (var i = 0; i < 15 && derivedFinder.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await _settle(tester);
      }
      // Drag further to clear bottom navigation bar
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
      await _settle(tester);
      expect(derivedFinder.hitTestable(), findsOneWidget);
      expectNoLayoutErrors(tester);

      // 2. PID Manager
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(PidManagerScreen), findsOneWidget);
      final rpmRowFinder30 = find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}'));
      for (var i = 0; i < 5 && rpmRowFinder30.evaluate().isEmpty; i++) {
        await tester.drag(find.byKey(const PageStorageKey('pid-master-scroll')), const Offset(0, -300));
        await _settle(tester);
      }
      await tester.tap(rpmRowFinder30);
      await tester.pumpAndSettle();
      expectNoLayoutErrors(tester);

      // 3. DTC
      await tester.tap(find.byIcon(Icons.warning_amber_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(DtcScreen), findsOneWidget);
      final dtcCardFinder30 = find.byKey(const ValueKey('dtc-card-P0300-7E8'));
      for (var i = 0; i < 8 && dtcCardFinder30.hitTestable().evaluate().isEmpty; i++) {
        await tester.drag(find.byKey(const ValueKey('dtc-page-scroll')), const Offset(0, -300));
        await _settle(tester);
      }
      expect(dtcCardFinder30.hitTestable(), findsOneWidget);
      await tester.tap(dtcCardFinder30);
      await tester.pumpAndSettle();
      expectNoLayoutErrors(tester);

      // 4. Performance
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(PerformanceScreen), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-31: Expanded vertical hinge + textScale 2.0 has 0 hinge overlap across PID, DTC, Performance', (tester) async {
      final controller = _FoldableQualityHarnessController();
      final a11yHingeProfile = FoldableDeviceProfiles.expandedInner.copyWith(
        displayFeatures: const [FoldableDeviceProfiles.verticalHalfOpenHinge],
        textScaler: const TextScaler.linear(2.0),
      );
      final hinge = FoldableDeviceProfiles.verticalHalfOpenHinge.bounds;

      // 1. Performance
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: a11yHingeProfile,
        initialLocation: PerformanceScreen.path,
      );
      expectNoHingeOverlap(tester, find.byKey(const ValueKey('performance-primary-pane')), hinge);
      expectNoHingeOverlap(tester, find.byKey(const ValueKey('performance-secondary-pane')), hinge);

      // 2. PID Manager
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
      final rpmRowFinder31 = find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}'));
      for (var i = 0; i < 15 && rpmRowFinder31.hitTestable().evaluate().isEmpty; i++) {
        await tester.dragFrom(const Offset(380, 600), const Offset(0, -500));
        await _settle(tester);
      }
      expect(rpmRowFinder31.hitTestable(), findsOneWidget);
      await tester.tap(rpmRowFinder31);
      await tester.pumpAndSettle();
      expectNoHingeOverlap(tester, find.byKey(const PageStorageKey('pid-master-scroll')), hinge);
      expectNoHingeOverlap(tester, find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')), hinge);

      // 3. DTC
      await tester.tap(find.byIcon(Icons.warning_amber_outlined));
      await tester.pumpAndSettle();
      final dtcCardFinder31 = find.byKey(const ValueKey('dtc-card-P0300-7E8'));
      for (var i = 0; i < 10 && dtcCardFinder31.hitTestable().evaluate().isEmpty; i++) {
        await tester.dragFrom(const Offset(380, 600), const Offset(0, -400));
        await _settle(tester);
      }
      expect(dtcCardFinder31.hitTestable(), findsOneWidget);
      await tester.tap(dtcCardFinder31);
      await tester.pumpAndSettle();
      expectNoHingeOverlap(tester, find.byKey(const ValueKey('dtc-master-list')), hinge);
      expectNoHingeOverlap(tester, find.byKey(const ValueKey('dtc-detail-pane')), hinge);
      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-32: Short landscape + textScale 2.0 navigation rail controls hit-testable', (tester) async {
      final controller = _FoldableQualityHarnessController();
      final a11yShortProfile = FoldableDeviceProfiles.compactShortLandscape.copyWith(
        textScaler: const TextScaler.linear(2.0),
      );

      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: a11yShortProfile,
        initialLocation: DashboardScreen.path,
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byIcon(Icons.tune_outlined).hitTestable(), findsOneWidget);

      expectNoLayoutErrors(tester);
    });
  });

  // ---------------------------------------------------------------------------
  // 10. Integration Geometry & Adaptive Modal Contracts (F08-33 ~ F08-36)
  // ---------------------------------------------------------------------------
  group('Integration Geometry & Adaptive Modal Contracts (F08-33 ~ F08-36)', () {
    testWidgets('F08-33: SafeArea + NavigationRail + vertical hinge keeps panes safe from hinge across Dashboard, PID, DTC, Performance', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTWH(530, 0, 24, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );
      const profile = FoldableDeviceProfile(
        name: 'Safe-Hinge-Rail',
        size: Size(1000, 800),
        safeInsets: EdgeInsets.fromLTRB(16, 24, 16, 24),
        displayFeatures: [hinge],
      );

      final controller = _FoldableQualityHarnessController();

      // 1. Performance
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: profile,
        initialLocation: PerformanceScreen.path,
      );

      final perfPrimaryFinder = find.byKey(const ValueKey('performance-primary-pane'));
      final perfSecondaryFinder = find.byKey(const ValueKey('performance-secondary-pane'));
      expectNoHingeOverlap(tester, perfPrimaryFinder, hinge.bounds);
      expectNoHingeOverlap(tester, perfSecondaryFinder, hinge.bounds);
      final perfPrimaryRect = tester.getRect(perfPrimaryFinder);
      final perfSecondaryRect = tester.getRect(perfSecondaryFinder);
      expect(perfPrimaryRect.right, lessThanOrEqualTo(hinge.bounds.left));
      expect(perfSecondaryRect.left, greaterThanOrEqualTo(hinge.bounds.right));

      // 2. PID Manager
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}')));
      await tester.pumpAndSettle();
      final pidMasterFinder = find.byKey(const PageStorageKey('pid-master-scroll'));
      final pidDetailFinder = find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}'));
      expectNoHingeOverlap(tester, pidMasterFinder, hinge.bounds);
      expectNoHingeOverlap(tester, pidDetailFinder, hinge.bounds);
      final pidMasterRect = tester.getRect(pidMasterFinder);
      final pidDetailRect = tester.getRect(pidDetailFinder);
      expect(pidMasterRect.right, lessThanOrEqualTo(hinge.bounds.left));
      expect(pidDetailRect.left, greaterThanOrEqualTo(hinge.bounds.right));

      // 3. DTC
      await tester.tap(find.byIcon(Icons.warning_amber_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('dtc-card-P0300-7E8')));
      await tester.pumpAndSettle();
      final dtcMasterFinder = find.byKey(const ValueKey('dtc-master-list'));
      final dtcDetailFinder = find.byKey(const ValueKey('dtc-detail-pane'));
      expectNoHingeOverlap(tester, dtcMasterFinder, hinge.bounds);
      expectNoHingeOverlap(tester, dtcDetailFinder, hinge.bounds);
      final dtcMasterRect = tester.getRect(dtcMasterFinder);
      final dtcDetailRect = tester.getRect(dtcDetailFinder);
      expect(dtcMasterRect.right, lessThanOrEqualTo(hinge.bounds.left));
      expect(dtcDetailRect.left, greaterThanOrEqualTo(hinge.bounds.right));

      // 4. Dashboard
      await tester.tap(find.byIcon(Icons.speed_outlined));
      await _settle(tester);
      expect(find.byType(DashboardScreen), findsOneWidget);
      var checkedGauges = 0;
      for (final pid in _gatePids) {
        final gaugeFinder = find.byKey(ValueKey('dashboard-gauge-${pid.id}'));
        if (gaugeFinder.evaluate().isNotEmpty) {
          expectNoHingeOverlap(tester, gaugeFinder, hinge.bounds);
          final rect = tester.getRect(gaugeFinder);
          expect(rect.overlaps(hinge.bounds), isFalse);
          checkedGauges++;
        }
      }
      expect(checkedGauges, greaterThan(0));

      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-34: Adaptive Modal side->bottom->side preserves uncommitted state and commits', (tester) async {
      final testTrends = _GateTelemetryTrendsNotifier();

      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            telemetryTrendsProvider.overrideWith(() => testTrends),
          ],
          child: localizedMaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: TelemetryLaneSelector(
                activePids: const [PidLibrary.engineRpm, PidLibrary.vehicleSpeed],
                selectedIds: [PidLibrary.engineRpm.id],
                enabled: true,
                disabledReason: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open modal in expanded -> sideSheet
      await tester.tap(find.byKey(const ValueKey('telemetry-lane-selector')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsOneWidget);

      // Toggle Speed checkbox
      await tester.tap(find.text('Speed'));
      await tester.pumpAndSettle();
      var tile = tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Speed'));
      expect(tile.value, isTrue);

      // Fold to compact -> morphs to bottomSheet
      tester.view.physicalSize = const Size(500, 800);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsOneWidget);
      tile = tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Speed'));
      expect(tile.value, isTrue);

      // Unfold back to expanded -> morphs to sideSheet
      tester.view.physicalSize = const Size(1000, 800);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsOneWidget);
      tile = tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Speed'));
      expect(tile.value, isTrue);

      // Tap Done button
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsNothing);
      expect(
        testTrends.updatedIds,
        containsAll([PidLibrary.engineRpm.id, PidLibrary.vehicleSpeed.id]),
      );
    });

    testWidgets('F08-35: Adaptive Modal horizontal tabletop hinge forces single-region Dialog', (tester) async {
      const tabletopHinge = DisplayFeature(
        bounds: Rect.fromLTWH(0, 390, 800, 20),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      final layout = AdaptiveModalPolicy.resolve(
        size: const Size(800, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [tabletopHinge],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
      );

      expect(layout.surface, equals(AdaptiveModalSurface.dialog));
      expect(layout.region.overlaps(tabletopHinge.bounds), isFalse);
    });

    test('F08-36: Modal region preferences leading/trailing/largest select correct physical regions', () {
      const asymmetricHinge = DisplayFeature(
        bounds: Rect.fromLTWH(300, 0, 20, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      // LTR leading -> left region (0..300)
      final ltrLeading = AdaptiveModalPolicy.resolve(
        size: const Size(1000, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [asymmetricHinge],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.leading,
      );
      expect(ltrLeading.region.right, lessThanOrEqualTo(300.0));

      // LTR trailing -> right region (320..1000)
      final ltrTrailing = AdaptiveModalPolicy.resolve(
        size: const Size(1000, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [asymmetricHinge],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
      );
      expect(ltrTrailing.region.left, greaterThanOrEqualTo(320.0));

      // Largest -> right region (width 680 > 300)
      final largest = AdaptiveModalPolicy.resolve(
        size: const Size(1000, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [asymmetricHinge],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.largest,
      );
      expect(largest.region.left, greaterThanOrEqualTo(320.0));
      expect(largest.region.width, equals(680.0));
    });
  });

  // ---------------------------------------------------------------------------
  // 11. Locale Pairwise Stress Gate (F08-37 ~ F08-38)
  // ---------------------------------------------------------------------------
  group('Locale Pairwise Stress Gate (F08-37 ~ F08-38)', () {
    testWidgets('F08-37: Narrow Cover + zh-Hant pairwise stress renders Chinese without overflow', (tester) async {
      final controller = _FoldableQualityHarnessController();
      const zhNarrowProfile = FoldableDeviceProfiles.narrowCoverZh;

      // 1. Dashboard in zh-Hant
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: zhNarrowProfile,
        initialLocation: DashboardScreen.path,
      );

      // Verify visible zh-Hant localization copy
      expect(find.text('儀表'), findsWidgets);

      // Scroll to lazy section to ensure derived estimates render without overflow
      final derivedFinder = find.byIcon(Icons.functions);
      for (var i = 0; i < 8 && derivedFinder.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await _settle(tester);
      }
      expect(derivedFinder.hitTestable(), findsOneWidget);
      expectNoLayoutErrors(tester);

      // 2. PID Manager in zh-Hant
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(PidManagerScreen), findsOneWidget);
      expect(find.text('PID 管理'), findsOneWidget);
      await tester.drag(find.byKey(const PageStorageKey('pid-master-scroll')), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}')));
      await tester.pumpAndSettle();
      expectNoLayoutErrors(tester);

      // 3. DTC in zh-Hant
      await tester.tap(find.byIcon(Icons.warning_amber_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(DtcScreen), findsOneWidget);
      expect(find.text('故障碼'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('dtc-card-P0300-7E8')));
      await tester.pumpAndSettle();
      expectNoLayoutErrors(tester);

      // 4. Performance in zh-Hant
      await tester.tap(find.byIcon(Icons.timer_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(PerformanceScreen), findsOneWidget);
      expect(find.text('加速測試'), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('F08-38: Expanded vertical hinge + German (de) + textScale 2.0 pairwise stress avoids hinge', (tester) async {
      final controller = _FoldableQualityHarnessController();
      const germanA11yHingeProfile = FoldableDeviceProfiles.expandedGermanA11y;
      final hinge = FoldableDeviceProfiles.verticalHalfOpenHinge.bounds;

      // 1. Performance in German
      await _pumpGateApp(
        tester,
        controller: controller,
        initialProfile: germanA11yHingeProfile,
        initialLocation: PerformanceScreen.path,
      );
      expect(find.text('Beschleunigungstest'), findsOneWidget);
      expectNoHingeOverlap(tester, find.byKey(const ValueKey('performance-primary-pane')), hinge);
      expectNoHingeOverlap(tester, find.byKey(const ValueKey('performance-secondary-pane')), hinge);
      expectNoLayoutErrors(tester);

      // 2. PID Manager in German
      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();
      expect(find.text('PID-Manager'), findsOneWidget);
      final rpmRowFinder38 = find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}'));
      for (var i = 0; i < 15 && rpmRowFinder38.hitTestable().evaluate().isEmpty; i++) {
        await tester.dragFrom(const Offset(380, 600), const Offset(0, -500));
        await _settle(tester);
      }
      expect(rpmRowFinder38.hitTestable(), findsOneWidget);
      await tester.tap(rpmRowFinder38);
      await tester.pumpAndSettle();
      expectNoHingeOverlap(tester, find.byKey(const PageStorageKey('pid-master-scroll')), hinge);
      expectNoHingeOverlap(tester, find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')), hinge);
      expectNoLayoutErrors(tester);

      // 3. DTC in German
      await tester.tap(find.byIcon(Icons.warning_amber_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Fehlercodes'), findsWidgets);
      final dtcCardFinder38 = find.byKey(const ValueKey('dtc-card-P0300-7E8'));
      for (var i = 0; i < 10 && dtcCardFinder38.hitTestable().evaluate().isEmpty; i++) {
        await tester.dragFrom(const Offset(380, 600), const Offset(0, -400));
        await _settle(tester);
      }
      expect(dtcCardFinder38.hitTestable(), findsOneWidget);
      await tester.tap(dtcCardFinder38);
      await tester.pumpAndSettle();
      expectNoHingeOverlap(tester, find.byKey(const ValueKey('dtc-master-list')), hinge);
      expectNoHingeOverlap(tester, find.byKey(const ValueKey('dtc-detail-pane')), hinge);
      expectNoLayoutErrors(tester);
    });
  });

  // ---------------------------------------------------------------------------
  // Static Integrity Audit (F08-39 ~ F08-40)
  // ---------------------------------------------------------------------------
  group('Static Integrity Audit (F08-39 ~ F08-40)', () {
    test('F08-39: Zero occurrences of showModalBottomSheet in production lib/', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final matches = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final lines = entity.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            if (lines[i].contains('showModalBottomSheet')) {
              matches.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
            }
          }
        }
      }

      expect(
        matches,
        isEmpty,
        reason: 'Found legacy showModalBottomSheet call(s):\n${matches.join('\n')}',
      );
    });

    test('F08-40: Zero occurrences of DraggableScrollableSheet in production lib/', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final matches = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final lines = entity.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            if (lines[i].contains('DraggableScrollableSheet')) {
              matches.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
            }
          }
        }
      }

      expect(
        matches,
        isEmpty,
        reason: 'Found DraggableScrollableSheet call(s):\n${matches.join('\n')}',
      );
    });
  });
}
