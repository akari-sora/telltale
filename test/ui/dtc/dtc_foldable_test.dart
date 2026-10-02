/// Foldable, adaptive, and master-detail integration tests for [DtcScreen].
///
/// Validates FOLD-05 acceptance criteria (F05-12 through F05-30):
/// - F05-12: Expanded scanned screen presents Master and System Overview (no auto-selection)
/// - F05-13: Selecting DTC shows detail and code attributes
/// - F05-14: Tapping System Overview in Master returns to overview
/// - F05-15: Same code on two controllers listed separately and selectable
/// - F05-16: Exact freeze-frame linkage (controller + kind + code)
/// - F05-17: Partial observation displays qualifier badge and detail warning
/// - F05-18: Compact single-column regression (no master-detail, no row selection navigation)
/// - F05-19: Selection continuity across fold/unfold layout transitions
/// - F05-20: Null selection continuity across fold/unfold
/// - F05-21: Rescan invalidates selection
/// - F05-22: Clear safety (cancel preserves selection, confirm clears selection)
/// - F05-23: Clean scan renders two-pane with clean verdict and readiness overview
/// - F05-24: Partial clean scan preserves partial clean verdict and unanswered category
/// - F05-25: Vertical separating hinge in LTR (zero overlap)
/// - F05-26: Vertical separating hinge in RTL (zero overlap)
/// - F05-27: SafeArea + NavigationRail + hinge coordinate projection integration
/// - F05-28: Horizontal separating hinge forces single pane
/// - F05-29: Unscanned expanded screen maintains single-pane Start Scan flow
/// - F05-30: Accessibility: textScale 2.0 with expanded hinge layout has zero overflow
library;

import "dart:ui" show DisplayFeature, DisplayFeatureState, DisplayFeatureType, Rect, Size;

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:torque_obd/core/theme/app_theme.dart";
import "package:torque_obd/l10n/generated/app_localizations.dart";
import "package:torque_obd/l10n/locale_resolution.dart";
import "package:torque_obd/obd/dtc/dtc.dart";
import "package:torque_obd/obd/freeze_frame.dart";
import "package:torque_obd/obd/pid/pid.dart";
import "package:torque_obd/obd/polling_engine.dart";
import "package:torque_obd/obd/transport/obd_transport.dart";
import "package:torque_obd/state/dtc_scan.dart";
import "package:torque_obd/state/obd_session.dart";
import "package:torque_obd/ui/screens/dtc/dtc_screen.dart";
import "package:torque_obd/ui/shell.dart";

import "../../support/localized_app.dart";

final _zh = lookupAppLocalizations(traditionalChineseLocale);

class _TestScanNotifier extends DtcScanNotifier {
  _TestScanNotifier(this.initial);
  final DtcScanState initial;

  int scanCallCount = 0;
  int clearCallCount = 0;

  @override
  DtcScanState build() => initial;

  @override
  Future<void> scan() async {
    scanCallCount++;
    state = initial;
  }

  @override
  Future<void> clear() async {
    clearCallCount++;
    state = initial;
  }
}

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

class _DtcFoldableHarness extends StatefulWidget {
  const _DtcFoldableHarness({
    super.key,
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
  State<_DtcFoldableHarness> createState() => _DtcFoldableHarnessState();
}

class _DtcFoldableHarnessState extends State<_DtcFoldableHarness> {
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
            ? const AppShell(child: DtcScreen())
            : const DtcScreen(),
      ),
    );
  }
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required DtcScanState scan,
  Size size = const Size(1000, 800),
  List<DisplayFeature> features = const [],
  EdgeInsets padding = EdgeInsets.zero,
  bool withShell = false,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
  _TestScanNotifier? notifier,
  bool connected = true,
}) async {
  final scanNotifier = notifier ?? _TestScanNotifier(scan);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  if (withShell) {
    final router = GoRouter(
      initialLocation: DtcScreen.path,
      routes: [
        GoRoute(
          path: DtcScreen.path,
          builder: (context, state) => _DtcFoldableHarness(
            key: const ValueKey("harness"),
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dtcScanProvider.overrideWith(() => scanNotifier),
          obdSessionProvider.overrideWith(() => _TestConnectedSession(connected: connected)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.dark(),
          locale: traditionalChineseLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  } else {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dtcScanProvider.overrideWith(() => scanNotifier),
          obdSessionProvider.overrideWith(() => _TestConnectedSession(connected: connected)),
        ],
        child: localizedMaterialApp(
          theme: AppTheme.dark(),
          locale: traditionalChineseLocale,
          home: _DtcFoldableHarness(
            key: const ValueKey("harness"),
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
  await tester.pumpAndSettle();
}

const _kP0300Ecm = Dtc(
  code: "P0300",
  category: DtcCategory.powertrain,
  kind: DtcKind.stored,
  sourceId: "7E8",
  isManufacturerSpecific: false,
);

const _kP0300Tcm = Dtc(
  code: "P0300",
  category: DtcCategory.powertrain,
  kind: DtcKind.stored,
  sourceId: "7E9",
  isManufacturerSpecific: false,
);

const _kP0420Ecm = Dtc(
  code: "P0420",
  category: DtcCategory.powertrain,
  kind: DtcKind.pending,
  sourceId: "7E8",
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
    vin: "1HGCR2F83HA000000",
    results: {
      DtcKind.stored: DtcCategoryResult.codes(storedCodes),
      DtcKind.pending: partialCodes.isNotEmpty
          ? DtcCategoryResult.failed(
              DtcReadException(
                "partial",
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

void main() {
  group("DTC Foldable and Master-Detail (FOLD-05)", () {
    testWidgets("F05-12: Expanded scanned screen presents Master and System Overview (no auto-selection)", (tester) async {
      final scan = _standardScanWithCodes();
      await _pumpScreen(tester, scan: scan);

      expect(find.byKey(const ValueKey("dtc-master-list")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-system-overview-pane")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsNothing);
      expect(find.byKey(const ValueKey("dtc-item-system-overview")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-card-P0300-7E8")), findsOneWidget);
    });

    testWidgets("F05-13: Selecting DTC shows detail and code attributes", (tester) async {
      final scan = _standardScanWithCodes();
      await _pumpScreen(tester, scan: scan);

      await tester.tap(find.byKey(const ValueKey("dtc-card-P0300-7E8")));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-system-overview-pane")), findsNothing);
      expect(find.text("P0300"), findsWidgets);
      expect(find.textContaining("7E8"), findsWidgets);
    });

    testWidgets("F05-14: Tapping System Overview in Master returns to overview", (tester) async {
      final scan = _standardScanWithCodes();
      await _pumpScreen(tester, scan: scan);

      // Select DTC
      await tester.tap(find.byKey(const ValueKey("dtc-card-P0300-7E8")));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsOneWidget);

      // Tap System Overview
      await tester.tap(find.byKey(const ValueKey("dtc-item-system-overview")));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey("dtc-system-overview-pane")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsNothing);
    });

    testWidgets("F05-15: Same code on two controllers listed separately and selectable", (tester) async {
      final scan = _standardScanWithCodes(storedCodes: [_kP0300Ecm, _kP0300Tcm]);
      await _pumpScreen(tester, scan: scan);

      expect(find.byKey(const ValueKey("dtc-card-P0300-7E8")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-card-P0300-7E9")), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey("dtc-card-P0300-7E9")));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsOneWidget);
      expect(find.textContaining("7E9"), findsWidgets);
    });

    testWidgets("F05-16: Exact freeze-frame linkage (controller + kind + code)", (tester) async {
      const frameEcm = FreezeFrame(
        source: "7E8",
        frameNumber: 0,
        cause: _kP0300Ecm,
        readings: [
          FreezeReading(
            pid: Pid(
              name: "Engine RPM",
              shortName: "RPM",
              modeAndPid: "010C",
              equation: "A",
              minValue: 0,
              maxValue: 8000,
              units: "rpm",
            ),
            value: 2800,
            raw: [0x0A, 0xF0],
          ),
        ],
        undecodable: 0,
        unread: 0,
      );

      const frameTcm = FreezeFrame(
        source: "7E9",
        frameNumber: 0,
        cause: _kP0300Tcm,
        readings: [],
        undecodable: 0,
        unread: 0,
      );

      final scan = _standardScanWithCodes(
        storedCodes: [_kP0300Ecm, _kP0300Tcm],
        freezeFrames: [frameEcm, frameTcm],
      );
      await _pumpScreen(tester, scan: scan);

      // Select ECM DTC -> only frame for ECM should show
      await tester.tap(find.byKey(const ValueKey("dtc-card-P0300-7E8")));
      await tester.pumpAndSettle();

      expect(find.text("Engine RPM"), findsOneWidget);
      expect(find.textContaining("2800"), findsOneWidget);
    });

    testWidgets("F05-16b: Empty freeze frame with freezeFrameUnread displays safe wording and unread warning", (tester) async {
      final scan = _standardScanWithCodes(
        storedCodes: [_kP0300Ecm],
        freezeFrames: [],
      ).copyWith(freezeFrameUnread: true);

      await _pumpScreen(tester, scan: scan);

      await tester.tap(find.byKey(const ValueKey("dtc-card-P0300-7E8")));
      await tester.pumpAndSettle();

      expect(find.text(_zh.dtcNoLinkedFreezeFrame), findsOneWidget);
      expect(find.text(_zh.dtcFreezeFrameUnreadPanel), findsOneWidget);
      // Ensure no claim of "no frame stored on vehicle"
      expect(find.textContaining("未針對此特定故障碼儲存"), findsNothing);
    });

    testWidgets("F05-17: Partial observation displays qualifier badge and detail warning", (tester) async {
      final scan = _standardScanWithCodes(
        storedCodes: [],
        partialCodes: [_kP0420Ecm],
      );
      await _pumpScreen(tester, scan: scan);

      expect(find.byKey(const ValueKey("dtc-card-P0420-7E8")), findsOneWidget);
      expect(find.text(_zh.dtcPartialObservationBadge), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey("dtc-card-P0420-7E8")));
      await tester.pumpAndSettle();

      expect(find.text(_zh.dtcPartialObservationBody), findsOneWidget);
    });

    testWidgets("F05-18: Compact single-column regression (no master-detail, no row selection navigation)", (tester) async {
      final scan = _standardScanWithCodes();
      await _pumpScreen(tester, scan: scan, size: const Size(360, 800));

      expect(find.byKey(const ValueKey("dtc-page-scroll")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-master-list")), findsNothing);
      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsNothing);
      expect(find.byKey(const ValueKey("dtc-system-overview-pane")), findsNothing);

      // Tapping row has no effect
      await tester.tap(find.text("P0300"));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsNothing);
    });

    testWidgets("F05-19: Selection continuity across fold/unfold layout transitions", (tester) async {
      final scan = _standardScanWithCodes();
      await _pumpScreen(tester, scan: scan, size: const Size(1000, 800));

      await tester.tap(find.byKey(const ValueKey("dtc-card-P0300-7E8")));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsOneWidget);

      // Fold to compact
      final harnessState = tester.state<_DtcFoldableHarnessState>(find.byKey(const ValueKey("harness")));
      harnessState.updateLayout(newSize: const Size(400, 800));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey("dtc-page-scroll")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsNothing);

      // Unfold back to expanded
      harnessState.updateLayout(newSize: const Size(1000, 800));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsOneWidget);
    });

    testWidgets("F05-20: Null selection continuity across fold/unfold", (tester) async {
      final scan = _standardScanWithCodes();
      await _pumpScreen(tester, scan: scan, size: const Size(1000, 800));

      expect(find.byKey(const ValueKey("dtc-system-overview-pane")), findsOneWidget);

      final harnessState = tester.state<_DtcFoldableHarnessState>(find.byKey(const ValueKey("harness")));
      harnessState.updateLayout(newSize: const Size(400, 800));
      await tester.pumpAndSettle();

      harnessState.updateLayout(newSize: const Size(1000, 800));
      await tester.pumpAndSettle();

      // Still System Overview, never auto-selects first DTC
      expect(find.byKey(const ValueKey("dtc-system-overview-pane")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsNothing);
    });

    testWidgets("F05-21: Rescan invalidates selection", (tester) async {
      final notifier = _TestScanNotifier(_standardScanWithCodes());
      await _pumpScreen(tester, scan: notifier.initial, notifier: notifier);

      await tester.tap(find.byKey(const ValueKey("dtc-card-P0300-7E8")));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsOneWidget);

      // Pull to refresh / rescan
      await tester.fling(find.byKey(const ValueKey("dtc-master-list")), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(notifier.scanCallCount, greaterThanOrEqualTo(1));
      expect(find.byKey(const ValueKey("dtc-system-overview-pane")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsNothing);
    });

    testWidgets("F05-22: Clear safety (cancel preserves selection, confirm clears selection)", (tester) async {
      final notifier = _TestScanNotifier(_standardScanWithCodes());
      await _pumpScreen(tester, scan: notifier.initial, notifier: notifier);

      await tester.tap(find.byKey(const ValueKey("dtc-card-P0300-7E8")));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsOneWidget);

      // Clear button exists in Master header, NOT detail
      final clearBtn = find.widgetWithText(OutlinedButton, _zh.dtcClear);
      expect(clearBtn, findsOneWidget);

      // Tap clear -> cancel
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();
      expect(find.text(_zh.dtcClearDialogTitle), findsOneWidget);

      await tester.tap(find.text(_zh.dtcClearCancel));
      await tester.pumpAndSettle();
      // Selection preserved
      expect(find.byKey(const ValueKey("dtc-detail-pane")), findsOneWidget);

      // Tap clear -> confirm
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text(_zh.dtcClearConfirm));
      await tester.pumpAndSettle();

      expect(notifier.clearCallCount, 1);
      // Selection cleared
      expect(find.byKey(const ValueKey("dtc-system-overview-pane")), findsOneWidget);
    });

    testWidgets("F05-23: Clean scan renders two-pane with clean verdict and readiness overview", (tester) async {
      final scan = DtcScanState(
        scannedAt: DateTime(2026, 8, 17),
        results: const {
          DtcKind.stored: DtcCategoryResult.codes([]),
          DtcKind.pending: DtcCategoryResult.codes([]),
          DtcKind.permanent: DtcCategoryResult.codes([]),
        },
      );
      await _pumpScreen(tester, scan: scan);

      expect(find.byKey(const ValueKey("dtc-master-list")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-system-overview-pane")), findsOneWidget);
      expect(find.text(_zh.dtcCompleteCleanTitle), findsOneWidget);
    });

    testWidgets("F05-24: Partial clean scan preserves partial clean verdict and unanswered category", (tester) async {
      final scan = DtcScanState(
        scannedAt: DateTime(2026, 8, 17),
        results: {
          DtcKind.stored: const DtcCategoryResult.codes([]),
          DtcKind.pending: const DtcCategoryResult.failed(
            DtcReadException("no reply", kind: DtcReadFailure.noAnswer),
          ),
          DtcKind.permanent: const DtcCategoryResult.codes([]),
        },
      );
      await _pumpScreen(tester, scan: scan);

      expect(find.byKey(const ValueKey("dtc-master-list")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-system-overview-pane")), findsOneWidget);
      expect(find.text(_zh.dtcPartialCleanTitle), findsOneWidget);
    });

    testWidgets("F05-25: Vertical separating hinge in LTR (zero overlap)", (tester) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      final scan = _standardScanWithCodes();
      await _pumpScreen(
        tester,
        scan: scan,
        size: const Size(1000, 800),
        features: const [hingeFeature],
      );

      final masterBox = tester.getRect(find.byKey(const ValueKey("dtc-master-list")));
      final overviewBox = tester.getRect(find.byKey(const ValueKey("dtc-system-overview-pane")));

      expect(masterBox.right, lessThanOrEqualTo(490.0));
      expect(overviewBox.left, greaterThanOrEqualTo(510.0));
    });

    testWidgets("F05-26: Vertical separating hinge in RTL (zero overlap)", (tester) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      final scan = _standardScanWithCodes();
      await _pumpScreen(
        tester,
        scan: scan,
        size: const Size(1000, 800),
        features: const [hingeFeature],
        textDirection: TextDirection.rtl,
      );

      final masterBox = tester.getRect(find.byKey(const ValueKey("dtc-master-list")));
      final overviewBox = tester.getRect(find.byKey(const ValueKey("dtc-system-overview-pane")));

      // In RTL with hinge, primary (master) is at right, secondary (detail/overview) is at left
      expect(overviewBox.right, lessThanOrEqualTo(490.0));
      expect(masterBox.left, greaterThanOrEqualTo(510.0));
    });

    testWidgets("F05-27: SafeArea + NavigationRail + hinge coordinate projection integration", (tester) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(530, 0, 24, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      final scan = _standardScanWithCodes();
      await _pumpScreen(
        tester,
        scan: scan,
        size: const Size(1000, 800),
        features: const [hingeFeature],
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        withShell: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey("dtc-master-list")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-system-overview-pane")), findsOneWidget);

      final masterRect =
          tester.getRect(find.byKey(const ValueKey('dtc-master-list')));
      final detailRect =
          tester.getRect(find.byKey(const ValueKey('dtc-system-overview-pane')));

      expect(masterRect.overlaps(hingeFeature.bounds), isFalse);
      expect(detailRect.overlaps(hingeFeature.bounds), isFalse);
    });

    testWidgets("F05-28: Horizontal separating hinge forces single pane", (tester) async {
      const horizontalHinge = DisplayFeature(
        bounds: Rect.fromLTWH(0, 390, 1000, 20),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      final scan = _standardScanWithCodes();
      await _pumpScreen(
        tester,
        scan: scan,
        size: const Size(1000, 800),
        features: const [horizontalHinge],
      );

      expect(find.byKey(const ValueKey("dtc-page-scroll")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-master-list")), findsNothing);
    });

    testWidgets("F05-29: Unscanned expanded screen maintains single-pane Start Scan flow", (tester) async {
      const unscannedState = DtcScanState();
      await _pumpScreen(tester, scan: unscannedState, size: const Size(1000, 800));

      expect(find.byKey(const ValueKey("dtc-page-scroll")), findsOneWidget);
      expect(find.byKey(const ValueKey("dtc-master-list")), findsNothing);
      expect(find.text(_zh.dtcStartScan), findsOneWidget);
    });

    testWidgets("F05-30: Accessibility: textScale 2.0 with expanded hinge layout has zero overflow", (tester) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      final scan = _standardScanWithCodes();
      await _pumpScreen(
        tester,
        scan: scan,
        size: const Size(1000, 800),
        features: const [hingeFeature],
        textScaler: const TextScaler.linear(2.0),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey("dtc-master-list")), findsOneWidget);
    });
  });
}
