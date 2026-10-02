/// Foldable, adaptive, and master-detail tests for [PidManagerScreen].
///
/// Validates FOLD-03 acceptance criteria (F03-06 through F03-21):
/// - F03-06: No selection placeholder in expanded two-pane
/// - F03-07: Selecting built-in PID updates detail without toggling active status
/// - F03-08: Row switch toggles active state while selection remains unchanged
/// - F03-09: Single-pane (compact) row tap toggles active directly
/// - F03-10: Two-pane custom PID detail shows Edit button which routes to editor
/// - F03-11: Editor save updates selection to saved PID ID
/// - F03-12: Editor cancel preserves existing selection
/// - F03-13: Selection continuity across fold/unfold layout transitions
/// - F03-14: No-selection continuity (never auto-selects first item)
/// - F03-15: Search/filter query survives fold/unfold and does not evict selection
/// - F03-16: Registry update dynamically updates detail pane by ID
/// - F03-17: Deleting selected PID safely clears selection to placeholder
/// - F03-18: Vertical separating hinge safety in LTR (zero overlap)
/// - F03-19: RTL layout safety across vertical hinge
/// - F03-20: SafeArea + NavigationRail + hinge coordinate projection integration
/// - F03-21: In-flight editor dirty draft survives fold/unfold transitions
/// - F03-22: Creating custom PID via Add button saves and selects it in two-pane
/// - F03-23: Active-only filter preserves inactive selection across fold/unfold
/// - F03-24: Toggling switch in detail pane synchronizes with master row
/// - F03-25: Empty search results display EmptyState while detail retains selection
library;

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/ui/screens/pids/pid_detail_pane.dart';
import 'package:torque_obd/ui/screens/pids/pid_editor_screen.dart';
import 'package:torque_obd/ui/screens/pids/pid_manager_screen.dart';
import 'package:torque_obd/ui/screens/pids/powertrain_battery_catalog_screen.dart';
import 'package:torque_obd/ui/shell.dart';

import '../../support/localized_app.dart';

const _kCustomPidJson =
    '{"name":"Boost Sensor","shortName":"BST","modeAndPid":"010B",'
    '"equation":"A","minValue":0,"maxValue":300,"units":"kPa",'
    '"header":"7E0","isCustom":true,"variant":"boost"}';

class _PidFoldableHarness extends StatefulWidget {
  const _PidFoldableHarness({
    super.key,
    required this.initialSize,
    this.initialFeatures = const [],
    this.initialPadding = EdgeInsets.zero,
    this.withShell = false,
    this.textDirection = TextDirection.ltr,
  });

  final Size initialSize;
  final List<DisplayFeature> initialFeatures;
  final EdgeInsets initialPadding;
  final bool withShell;
  final TextDirection textDirection;

  @override
  State<_PidFoldableHarness> createState() => _PidFoldableHarnessState();
}

class _PidFoldableHarnessState extends State<_PidFoldableHarness> {
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
      ),
      child: Directionality(
        textDirection: widget.textDirection,
        child: widget.withShell
            ? const AppShell(child: PidManagerScreen())
            : const PidManagerScreen(),
      ),
    );
  }
}

Future<void> _scrollAndTap(WidgetTester tester, Finder finder) async {
  final scrollable = find.descendant(
    of: find.byKey(const PageStorageKey('pid-master-scroll')),
    matching: find.byType(Scrollable),
  ).first;
  await tester.scrollUntilVisible(
    finder,
    150,
    scrollable: scrollable,
  );
  await tester.drag(scrollable, const Offset(0, -80));
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<GlobalKey<_PidFoldableHarnessState>> _pumpHarness(
  WidgetTester tester, {
  required Size size,
  List<DisplayFeature> displayFeatures = const [],
  EdgeInsets padding = EdgeInsets.zero,
  bool withShell = false,
  TextDirection textDirection = TextDirection.ltr,
  Map<String, Object> initialPrefs = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({
    'active_pid_ids_v1': <String>[],
    ...initialPrefs,
  });
  final prefs = await SharedPreferences.getInstance();

  final harnessKey = GlobalKey<_PidFoldableHarnessState>();
  final router = GoRouter(
    initialLocation: PidManagerScreen.path,
    routes: [
      GoRoute(
        path: PidManagerScreen.path,
        builder: (context, state) => _PidFoldableHarness(
          key: harnessKey,
          initialSize: size,
          initialFeatures: displayFeatures,
          initialPadding: padding,
          withShell: withShell,
          textDirection: textDirection,
        ),
      ),
      GoRoute(
        path: PidEditorScreen.path,
        builder: (context, state) => PidEditorScreen(
          pidId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: PowertrainBatteryCatalogScreen.path,
        builder: (context, state) => const Scaffold(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: localizedMaterialAppRouter(
        routerConfig: router,
        locale: const Locale('en'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harnessKey;
}

void main() {
  group('PID Manager Foldable Master-Detail (FOLD-03)', () {
    testWidgets('F03-06: expanded mode shows master list and placeholder when no selection',
        (tester) async {
      await _pumpHarness(
        tester,
        size: const Size(1000, 700),
      );

      expect(find.byKey(const PageStorageKey('pid-master-scroll')), findsOneWidget);
      expect(find.byKey(const ValueKey('pid-detail-empty')), findsOneWidget);
      expect(find.byType(PidDetailPane), findsNothing);
    });

    testWidgets('F03-07: selecting built-in PID displays detail and does not toggle active',
        (tester) async {
      await _pumpHarness(
        tester,
        size: const Size(1000, 700),
      );

      final rpmRowKey = ValueKey('pid-row-${PidLibrary.engineRpm.id}');
      expect(find.byKey(rpmRowKey), findsOneWidget);

      // Verify switch is off initially
      final rowSwitchFinder = find.descendant(
        of: find.byKey(rpmRowKey),
        matching: find.byType(Switch),
      );
      final initialSwitch = tester.widget<Switch>(rowSwitchFinder);
      expect(initialSwitch.value, isFalse);

      // Tap row to select
      await tester.tap(find.byKey(rpmRowKey));
      await tester.pumpAndSettle();

      // Detail pane is now visible for RPM
      expect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
        findsOneWidget,
      );

      // Row tap must NOT toggle active switch in two-pane mode
      final switchAfterTap = tester.widget<Switch>(rowSwitchFinder);
      expect(switchAfterTap.value, isFalse);
    });

    testWidgets('F03-08: switch on row toggles active state without affecting selection',
        (tester) async {
      await _pumpHarness(
        tester,
        size: const Size(1000, 700),
      );

      final rpmRowKey = ValueKey('pid-row-${PidLibrary.engineRpm.id}');
      await tester.tap(find.byKey(rpmRowKey));
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
        findsOneWidget,
      );

      // Tap switch
      final rowSwitchFinder = find.descendant(
        of: find.byKey(rpmRowKey),
        matching: find.byType(Switch),
      );
      await tester.tap(rowSwitchFinder);
      await tester.pumpAndSettle();

      // Switch should now be active
      final updatedSwitch = tester.widget<Switch>(rowSwitchFinder);
      expect(updatedSwitch.value, isTrue);

      // Detail pane remains focused on RPM
      expect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
        findsOneWidget,
      );
    });

    testWidgets('F03-09: single-pane compact mode tap toggles active directly without selecting',
        (tester) async {
      await _pumpHarness(
        tester,
        size: const Size(360, 800),
      );

      final rpmRowKey = ValueKey('pid-row-${PidLibrary.engineRpm.id}');
      final rowSwitchFinder = find.descendant(
        of: find.byKey(rpmRowKey),
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(rowSwitchFinder).value, isFalse);

      // Tap row in compact mode
      await tester.tap(find.byKey(rpmRowKey));
      await tester.pumpAndSettle();

      // Active toggled to true!
      expect(tester.widget<Switch>(rowSwitchFinder).value, isTrue);

      // No detail pane or placeholder exists in single pane
      expect(find.byType(PidDetailPane), findsNothing);
      expect(find.byKey(const ValueKey('pid-detail-empty')), findsNothing);
    });

    testWidgets('F03-10: custom PID detail in two-pane shows edit button routing to editor',
        (tester) async {
      await _pumpHarness(
        tester,
        size: const Size(1000, 700),
        initialPrefs: {
          'custom_pids_v1': [_kCustomPidJson],
        },
      );

      const customPidId = 'custom:7E0:010B#boost';
      const customRowKey = ValueKey('pid-row-$customPidId');

      await _scrollAndTap(tester, find.byKey(customRowKey));

      // Detail pane displays custom PID
      expect(find.byKey(const ValueKey('pid-detail-$customPidId')), findsOneWidget);

      // Tap Edit button in detail pane
      final editBtn = find.descendant(
        of: find.byKey(const ValueKey('pid-detail-$customPidId')),
        matching: find.widgetWithText(FilledButton, 'Edit'),
      );
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // PidEditorScreen is pushed
      expect(find.byType(PidEditorScreen), findsOneWidget);
    });

    testWidgets('F03-11: editor save pops and updates selection to newly saved PID',
        (tester) async {
      await _pumpHarness(
        tester,
        size: const Size(1000, 700),
        initialPrefs: {
          'custom_pids_v1': [_kCustomPidJson],
        },
      );

      const customPidId = 'custom:7E0:010B#boost';
      await _scrollAndTap(tester, find.byKey(const ValueKey('pid-row-$customPidId')));

      // Open editor
      await tester.tap(find.widgetWithText(FilledButton, 'Edit'));
      await tester.pumpAndSettle();

      // Change name to Boost Renamed
      final nameField = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text == 'Boost Sensor',
      );
      await tester.enterText(nameField, 'Boost Renamed');
      await tester.pumpAndSettle();

      // Tap Save
      final saveBtn = find.widgetWithText(FilledButton, 'Save');
      await tester.scrollUntilVisible(
        saveBtn,
        150,
        scrollable: find.descendant(
          of: find.byType(PidEditorScreen),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Returned to Manager screen with editor closed
      expect(find.byType(PidEditorScreen), findsNothing);

      // Detail pane shows updated name
      expect(
        find.descendant(
          of: find.byType(PidDetailPane),
          matching: find.text('Boost Renamed'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('F03-12: editor cancel retains previous selection', (tester) async {
      await _pumpHarness(
        tester,
        size: const Size(1000, 700),
        initialPrefs: {
          'custom_pids_v1': [_kCustomPidJson],
        },
      );

      const customPidId = 'custom:7E0:010B#boost';
      await _scrollAndTap(tester, find.byKey(const ValueKey('pid-row-$customPidId')));

      // Open editor
      await tester.tap(find.widgetWithText(FilledButton, 'Edit'));
      await tester.pumpAndSettle();

      // Pop without saving
      final backBtn = find.byType(BackButton);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Returned to Manager screen and selection is still custom PID
      expect(find.byType(PidEditorScreen), findsNothing);
      expect(find.byKey(const ValueKey('pid-detail-$customPidId')), findsOneWidget);
    });

    testWidgets('F03-13: selection survives fold/unfold layout transitions',
        (tester) async {
      final harnessKey = await _pumpHarness(
        tester,
        size: const Size(1000, 700),
      );

      // Select RPM
      await tester.tap(find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
        findsOneWidget,
      );

      // Fold to compact
      harnessKey.currentState!.updateLayout(newSize: const Size(400, 800));
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();

      // In compact mode, detail is not rendered
      expect(find.byType(PidDetailPane), findsNothing);

      // Unfold back to expanded
      harnessKey.currentState!.updateLayout(newSize: const Size(1000, 700));
      tester.view.physicalSize = const Size(1000, 700);
      await tester.pumpAndSettle();

      // Selection restored!
      expect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
        findsOneWidget,
      );
    });

    testWidgets('F03-14: no-selection state survives fold/unfold without auto-selecting',
        (tester) async {
      final harnessKey = await _pumpHarness(
        tester,
        size: const Size(1000, 700),
      );

      expect(find.byKey(const ValueKey('pid-detail-empty')), findsOneWidget);

      // Fold to medium
      harnessKey.currentState!.updateLayout(newSize: const Size(700, 700));
      tester.view.physicalSize = const Size(700, 700);
      await tester.pumpAndSettle();

      // Unfold back to expanded
      harnessKey.currentState!.updateLayout(newSize: const Size(1000, 700));
      tester.view.physicalSize = const Size(1000, 700);
      await tester.pumpAndSettle();

      // Still placeholder, no auto-selection!
      expect(find.byKey(const ValueKey('pid-detail-empty')), findsOneWidget);
      expect(find.byType(PidDetailPane), findsNothing);
    });

    testWidgets('F03-15: search query survives fold/unfold and does not evict active selection',
        (tester) async {
      final harnessKey = await _pumpHarness(
        tester,
        size: const Size(1000, 700),
      );

      // Select RPM
      await tester.tap(find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
        findsOneWidget,
      );

      // Enter search query that excludes RPM from the master list
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'speed');
      await tester.pumpAndSettle();

      // Master list only shows Vehicle Speed, RPM is filtered out
      expect(find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}')), findsNothing);
      expect(find.byKey(ValueKey('pid-row-${PidLibrary.vehicleSpeed.id}')), findsOneWidget);

      // But detail pane STILL retains RPM!
      expect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
        findsOneWidget,
      );

      // Fold and unfold
      harnessKey.currentState!.updateLayout(newSize: const Size(400, 800));
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();

      harnessKey.currentState!.updateLayout(newSize: const Size(1000, 700));
      tester.view.physicalSize = const Size(1000, 700);
      await tester.pumpAndSettle();

      // Query remains 'speed' and detail pane still displays RPM
      expect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
        findsOneWidget,
      );
      expect(find.text('speed'), findsOneWidget);
    });

    testWidgets('F03-16: registry update dynamically reflects in detail pane',
        (tester) async {
      await _pumpHarness(
        tester,
        size: const Size(1000, 700),
        initialPrefs: {
          'custom_pids_v1': [_kCustomPidJson],
        },
      );

      const customPidId = 'custom:7E0:010B#boost';
      await _scrollAndTap(tester, find.byKey(const ValueKey('pid-row-$customPidId')));

      expect(
        find.descendant(
          of: find.byType(PidDetailPane),
          matching: find.text('Boost Sensor'),
        ),
        findsOneWidget,
      );

      // Directly update registry via notifier
      final element = tester.element(find.byType(PidManagerScreen));
      final container = ProviderScope.containerOf(element);
      const updatedPid = Pid(
        name: 'Turbo Boost Gauge',
        shortName: 'BST',
        modeAndPid: '010B',
        equation: 'A*1.5',
        minValue: 0,
        maxValue: 300,
        units: 'psi',
        header: '7E0',
        isCustom: true,
        variant: 'boost',
      );
      await container.read(pidRegistryProvider.notifier).upsertCustom(updatedPid);
      await tester.pumpAndSettle();

      // Detail pane shows updated name
      expect(
        find.descendant(
          of: find.byType(PidDetailPane),
          matching: find.text('Turbo Boost Gauge'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('F03-17: removing selected PID safely falls back to placeholder without crashing',
        (tester) async {
      await _pumpHarness(
        tester,
        size: const Size(1000, 700),
        initialPrefs: {
          'custom_pids_v1': [_kCustomPidJson],
        },
      );

      const customPidId = 'custom:7E0:010B#boost';
      await _scrollAndTap(tester, find.byKey(const ValueKey('pid-row-$customPidId')));

      expect(find.byKey(const ValueKey('pid-detail-$customPidId')), findsOneWidget);

      // Remove custom PID from registry
      final element = tester.element(find.byType(PidManagerScreen));
      final container = ProviderScope.containerOf(element);
      final customPid = container.read(pidRegistryProvider).firstWhere((p) => p.id == customPidId);
      await container.read(pidRegistryProvider.notifier).removeCustom(customPid);
      await tester.pumpAndSettle();

      // Selection clears safely to placeholder
      expect(find.byKey(const ValueKey('pid-detail-empty')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('F03-18: vertical separating hinge keeps master and detail zero-intersecting (LTR)',
        (tester) async {
      const hinge = Rect.fromLTWH(490, 0, 20, 700);
      await _pumpHarness(
        tester,
        size: const Size(1000, 700),
        displayFeatures: const [
          DisplayFeature(
            bounds: hinge,
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );

      // Select RPM
      await tester.tap(find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}')));
      await tester.pumpAndSettle();

      final masterRect = tester.getRect(find.byKey(const PageStorageKey('pid-master-scroll')));
      final detailRect = tester.getRect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
      );

      // LTR: master on left, detail on right
      expect(masterRect.right, lessThanOrEqualTo(hinge.left));
      expect(detailRect.left, greaterThanOrEqualTo(hinge.right));
      expect(masterRect.overlaps(hinge), isFalse);
      expect(detailRect.overlaps(hinge), isFalse);
    });

    testWidgets('F03-19: vertical separating hinge in RTL puts master on right and detail on left',
        (tester) async {
      const hinge = Rect.fromLTWH(490, 0, 20, 700);
      await _pumpHarness(
        tester,
        size: const Size(1000, 700),
        textDirection: TextDirection.rtl,
        displayFeatures: const [
          DisplayFeature(
            bounds: hinge,
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );

      // Select RPM
      await tester.tap(find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}')));
      await tester.pumpAndSettle();

      final masterRect = tester.getRect(find.byKey(const PageStorageKey('pid-master-scroll')));
      final detailRect = tester.getRect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
      );

      // RTL: detail on physical left, master on physical right
      expect(detailRect.right, lessThanOrEqualTo(hinge.left));
      expect(masterRect.left, greaterThanOrEqualTo(hinge.right));
      expect(masterRect.overlaps(hinge), isFalse);
      expect(detailRect.overlaps(hinge), isFalse);
    });

    testWidgets('F03-20: SafeArea + NavigationRail + hinge local projection keeps hinge safe',
        (tester) async {
      const globalHinge = Rect.fromLTWH(490, 0, 20, 700);
      const safePadding = EdgeInsets.fromLTRB(24, 40, 16, 0);

      await _pumpHarness(
        tester,
        size: const Size(1000, 700),
        withShell: true,
        padding: safePadding,
        displayFeatures: const [
          DisplayFeature(
            bounds: globalHinge,
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );

      // Select RPM (scroll master slightly to bring row fully into viewport)
      final masterScroll = find.descendant(
        of: find.byKey(const PageStorageKey('pid-master-scroll')),
        matching: find.byType(Scrollable),
      ).first;
      await tester.drag(masterScroll, const Offset(0, -150));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}')));
      await tester.pumpAndSettle();

      final masterRect = tester.getRect(find.byKey(const PageStorageKey('pid-master-scroll')));
      final detailRect = tester.getRect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
      );

      // Neither master nor detail overlaps the global hinge
      expect(masterRect.overlaps(globalHinge), isFalse);
      expect(detailRect.overlaps(globalHinge), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('F03-21: in-flight editor dirty draft survives fold/unfold layout transitions',
        (tester) async {
      final harnessKey = await _pumpHarness(
        tester,
        size: const Size(1000, 700),
        initialPrefs: {
          'custom_pids_v1': [_kCustomPidJson],
        },
      );

      const customPidId = 'custom:7E0:010B#boost';
      await _scrollAndTap(tester, find.byKey(const ValueKey('pid-row-$customPidId')));

      // Open editor
      await tester.tap(find.widgetWithText(FilledButton, 'Edit'));
      await tester.pumpAndSettle();

      expect(find.byType(PidEditorScreen), findsOneWidget);

      // Type uncommitted draft text in formula field
      final formulaField = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text == 'A',
      );
      await tester.enterText(formulaField, 'A*2+B');
      await tester.pumpAndSettle();

      // Resize/fold to compact
      harnessKey.currentState!.updateLayout(newSize: const Size(400, 800));
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();

      // Editor screen is still mounted and draft text is preserved
      expect(find.byType(PidEditorScreen), findsOneWidget);
      expect(find.text('A*2+B'), findsOneWidget);

      // Unfold back to expanded
      harnessKey.currentState!.updateLayout(newSize: const Size(1000, 700));
      tester.view.physicalSize = const Size(1000, 700);
      await tester.pumpAndSettle();

      expect(find.byType(PidEditorScreen), findsOneWidget);
      expect(find.text('A*2+B'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('F03-22: creating custom PID via Add button saves and selects it in two-pane',
        (tester) async {
      await _pumpHarness(
        tester,
        size: const Size(1000, 700),
      );

      // Tap New (Add) button in master pane
      final addBtn = find.widgetWithIcon(FilledButton, Icons.add);
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.byType(PidEditorScreen), findsOneWidget);

      // Fill in required fields
      final nameField = find.widgetWithText(TextField, 'Name');
      await tester.enterText(nameField, 'Turbo Boost Gauge');

      final modeAndPidField = find.widgetWithText(TextField, 'Mode + PID');
      await tester.enterText(modeAndPidField, '010B');

      final equationField = find.widgetWithText(TextField, 'Expression');
      await tester.enterText(equationField, 'A*2');
      await tester.pumpAndSettle();

      // Tap Save
      final saveBtn = find.widgetWithText(FilledButton, 'Save');
      await tester.scrollUntilVisible(
        saveBtn,
        150,
        scrollable: find.descendant(
          of: find.byType(PidEditorScreen),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Returned to Manager screen
      expect(find.byType(PidEditorScreen), findsNothing);

      // Newly added custom PID is automatically selected in two-pane mode!
      expect(
        find.descendant(
          of: find.byType(PidDetailPane),
          matching: find.text('Turbo Boost Gauge'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('F03-23: active-only filter preserves inactive selection across fold/unfold',
        (tester) async {
      final harnessKey = await _pumpHarness(
        tester,
        size: const Size(1000, 700),
      );

      // Select RPM (which is inactive)
      final rpmRowKey = ValueKey('pid-row-${PidLibrary.engineRpm.id}');
      await tester.tap(find.byKey(rpmRowKey));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
        findsOneWidget,
      );

      // Tap 'Enabled only' FilterChip
      final filterChip = find.widgetWithText(FilterChip, 'Enabled only');
      await tester.tap(filterChip);
      await tester.pumpAndSettle();

      // RPM row is now filtered out of master list
      expect(find.byKey(rpmRowKey), findsNothing);

      // But detail pane STILL displays RPM!
      expect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
        findsOneWidget,
      );

      // Fold to compact
      harnessKey.currentState!.updateLayout(newSize: const Size(400, 800));
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();

      // Unfold back to expanded
      harnessKey.currentState!.updateLayout(newSize: const Size(1000, 700));
      tester.view.physicalSize = const Size(1000, 700);
      await tester.pumpAndSettle();

      // Selection remains RPM and Enabled only filter is still preserved
      expect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
        findsOneWidget,
      );
      final chipWidget = tester.widget<FilterChip>(filterChip);
      expect(chipWidget.selected, isTrue);
    });

    testWidgets('F03-24: toggling switch in detail pane synchronizes with master row',
        (tester) async {
      await _pumpHarness(
        tester,
        size: const Size(1000, 700),
      );

      final rpmRowKey = ValueKey('pid-row-${PidLibrary.engineRpm.id}');
      await tester.tap(find.byKey(rpmRowKey));
      await tester.pumpAndSettle();

      // Master switch is false
      final masterSwitchFinder = find.descendant(
        of: find.byKey(rpmRowKey),
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(masterSwitchFinder).value, isFalse);

      // Detail switch is false
      final detailSwitchFinder = find.descendant(
        of: find.byType(PidDetailPane),
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(detailSwitchFinder).value, isFalse);

      // Toggle switch in detail pane
      await tester.tap(detailSwitchFinder);
      await tester.pumpAndSettle();

      // Both are now true
      expect(tester.widget<Switch>(masterSwitchFinder).value, isTrue);
      expect(tester.widget<Switch>(detailSwitchFinder).value, isTrue);

      // Toggle again
      await tester.tap(detailSwitchFinder);
      await tester.pumpAndSettle();

      // Both are now false
      expect(tester.widget<Switch>(masterSwitchFinder).value, isFalse);
      expect(tester.widget<Switch>(detailSwitchFinder).value, isFalse);
    });

    testWidgets('F03-25: empty search results display EmptyState while detail retains selection',
        (tester) async {
      await _pumpHarness(
        tester,
        size: const Size(1000, 700),
      );

      // Select RPM
      await tester.tap(find.byKey(ValueKey('pid-row-${PidLibrary.engineRpm.id}')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
        findsOneWidget,
      );

      // Type nonexistent query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'xyz_does_not_exist');
      await tester.pumpAndSettle();

      // Master pane shows EmptyState
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No matching PID'), findsOneWidget);

      // Detail pane STILL displays RPM
      expect(
        find.byKey(ValueKey('pid-detail-${PidLibrary.engineRpm.id}')),
        findsOneWidget,
      );
    });
  });
}
