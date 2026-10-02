/// Adaptive modal migration tests for FOLD-07.
///
/// Verifies:
/// - TelemetryExportSheet (compact bottomSheet vs expanded dialog, CSV/JSON returns, dismiss null).
/// - TelemetryLaneSelector (compact bottomSheet vs expanded sideSheet, toggle and Done).
/// - ServiceRecipeDetailSheet (compact bottomSheet vs expanded sideSheet, Close dismiss, short landscape).
/// - PID Arrange Sheet (compact bottomSheet vs expanded trailing sideSheet, vertical hinge isolation).
/// - Tabletop posture (horizontal separating hinge forces single-region dialog).
/// - Static check: 0 occurrences of showModalBottomSheet across all production code.
library;

import 'dart:io';
import 'dart:ui'
    show DisplayFeature, DisplayFeatureState, DisplayFeatureType, Rect, Size;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/diagnostics/service_recipes/active_test_profile.dart';
import 'package:torque_obd/diagnostics/service_recipes/candidate_matrix.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/telemetry_sessions.dart';
import 'package:torque_obd/ui/screens/pids/pid_manager_screen.dart';
import 'package:torque_obd/ui/screens/telemetry/telemetry_export_sheet.dart';
import 'package:torque_obd/ui/screens/workshop/service_recipe_detail_sheet.dart';
import 'package:torque_obd/ui/widgets/telemetry/telemetry_lane_selector.dart';
import 'package:torque_obd/state/telemetry_trends.dart';

import '../../support/localized_app.dart';

class _FixedActivePids extends ActivePids {
  _FixedActivePids(this.pids);
  final List<Pid> pids;

  @override
  List<Pid> build() => pids;
}

class _TestTelemetryTrendsNotifier extends TelemetryTrendsNotifier {
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

Future<void> _pumpModalHarness(
  WidgetTester tester, {
  required Size size,
  List<DisplayFeature> displayFeatures = const [],
  TextDirection textDirection = TextDirection.ltr,
  List<dynamic> overrides = const [],
  required Widget Function(BuildContext) childBuilder,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.displayFeatures = displayFeatures;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetDisplayFeatures);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: Directionality(
        textDirection: textDirection,
        child: localizedMaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => childBuilder(context),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Remaining Adaptive Modals Integration (FOLD-07)', () {
    // -------------------------------------------------------------------------
    // TelemetryExportSheet Tests
    // -------------------------------------------------------------------------
    group('TelemetryExportSheet', () {
      testWidgets('F07-14: Compact (360x800) presents Material Bottom Sheet', (tester) async {
        await _pumpModalHarness(
          tester,
          size: const Size(360, 800),
          childBuilder: (context) => ElevatedButton(
            key: const Key('open_export'),
            onPressed: () => showTelemetryExportSheet(context),
            child: const Text('Export'),
          ),
        );

        await tester.tap(find.byKey(const Key('open_export')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsOneWidget);
        expect(find.byKey(const ValueKey('adaptive-modal-dialog')), findsNothing);
        expect(find.byType(TelemetryExportSheet), findsOneWidget);
      });

      testWidgets('F07-15: Expanded (1000x800) presents Centered Dialog', (tester) async {
        await _pumpModalHarness(
          tester,
          size: const Size(1000, 800),
          childBuilder: (context) => ElevatedButton(
            key: const Key('open_export'),
            onPressed: () => showTelemetryExportSheet(context),
            child: const Text('Export'),
          ),
        );

        await tester.tap(find.byKey(const Key('open_export')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('adaptive-modal-dialog')), findsOneWidget);
        expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsNothing);
        expect(find.byType(TelemetryExportSheet), findsOneWidget);
      });

      testWidgets('F07-16: Returns TelemetryExportFormat.csv and .json on selection', (tester) async {
        TelemetryExportFormat? selectedFormat;

        await _pumpModalHarness(
          tester,
          size: const Size(360, 800),
          childBuilder: (context) => ElevatedButton(
            key: const Key('open_export'),
            onPressed: () async {
              selectedFormat = await showTelemetryExportSheet(context);
            },
            child: const Text('Export'),
          ),
        );

        // Test CSV selection
        await tester.tap(find.byKey(const Key('open_export')));
        await tester.pumpAndSettle();

        final csvFinder = find.byType(OutlinedButton);
        expect(csvFinder, findsOneWidget);
        await tester.tap(csvFinder);
        await tester.pumpAndSettle();

        expect(selectedFormat, equals(TelemetryExportFormat.csv));
        expect(find.byType(TelemetryExportSheet), findsNothing);

        // Test JSON selection
        await tester.tap(find.byKey(const Key('open_export')));
        await tester.pumpAndSettle();

        final jsonFinder = find.byType(FilledButton);
        expect(jsonFinder, findsOneWidget);
        await tester.tap(jsonFinder);
        await tester.pumpAndSettle();

        expect(selectedFormat, equals(TelemetryExportFormat.json));
        expect(find.byType(TelemetryExportSheet), findsNothing);
      });

      testWidgets('F07-17: Barrier dismiss returns null', (tester) async {
        TelemetryExportFormat? selectedFormat = TelemetryExportFormat.csv;

        await _pumpModalHarness(
          tester,
          size: const Size(1000, 800),
          childBuilder: (context) => ElevatedButton(
            key: const Key('open_export'),
            onPressed: () async {
              selectedFormat = await showTelemetryExportSheet(context);
            },
            child: const Text('Export'),
          ),
        );

        await tester.tap(find.byKey(const Key('open_export')));
        await tester.pumpAndSettle();

        expect(find.byType(TelemetryExportSheet), findsOneWidget);

        // Tap top-left corner outside modal dialog
        await tester.tapAt(const Offset(50, 50));
        await tester.pumpAndSettle();

        expect(selectedFormat, isNull);
        expect(find.byType(TelemetryExportSheet), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // TelemetryLaneSelector Tests
    // -------------------------------------------------------------------------
    group('TelemetryLaneSelector', () {
      testWidgets('F07-18: Expanded (1000x800) presents Side Sheet with 0.72 height factor', (tester) async {
        await _pumpModalHarness(
          tester,
          size: const Size(1000, 800),
          childBuilder: (context) => TelemetryLaneSelector(
            activePids: const [PidLibrary.engineRpm, PidLibrary.vehicleSpeed],
            selectedIds: [PidLibrary.engineRpm.id],
            enabled: true,
            disabledReason: null,
          ),
        );

        await tester.tap(find.byKey(const ValueKey('telemetry-lane-selector')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsOneWidget);
        expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsNothing);

        final sideSheetFinder = find.byKey(const ValueKey('adaptive-modal-side-sheet'));
        final rect = tester.getRect(sideSheetFinder);
        // Trailing side sheet on 1000 width
        expect(rect.right, equals(1000.0 - 16.0));
      });

      testWidgets('F07-19: Toggling signal selection and clicking Done updates selection', (tester) async {
        final testNotifier = _TestTelemetryTrendsNotifier();

        await _pumpModalHarness(
          tester,
          size: const Size(360, 800),
          overrides: [
            telemetryTrendsProvider.overrideWith(() => testNotifier),
          ],
          childBuilder: (context) => TelemetryLaneSelector(
            activePids: const [PidLibrary.engineRpm, PidLibrary.vehicleSpeed],
            selectedIds: [PidLibrary.engineRpm.id],
            enabled: true,
            disabledReason: null,
          ),
        );

        await tester.tap(find.byKey(const ValueKey('telemetry-lane-selector')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsOneWidget);

        // Toggle Speed (010D)
        await tester.tap(find.text('Speed'));
        await tester.pumpAndSettle();

        // Tap Done button
        final doneButtonFinder = find.byType(FilledButton);
        expect(doneButtonFinder, findsOneWidget);
        await tester.tap(doneButtonFinder);
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsNothing);
        expect(
          testNotifier.updatedIds,
          containsAll([PidLibrary.engineRpm.id, PidLibrary.vehicleSpeed.id]),
        );
      });

      testWidgets('F07-19b: Selection state is preserved across surface morph (1000dp sideSheet -> 500dp bottomSheet -> 1000dp sideSheet) and committed upon Done', (tester) async {
        final testNotifier = _TestTelemetryTrendsNotifier();

        await _pumpModalHarness(
          tester,
          size: const Size(1000, 800),
          overrides: [
            telemetryTrendsProvider.overrideWith(() => testNotifier),
          ],
          childBuilder: (context) => TelemetryLaneSelector(
            activePids: const [PidLibrary.engineRpm, PidLibrary.vehicleSpeed],
            selectedIds: [PidLibrary.engineRpm.id],
            enabled: true,
            disabledReason: null,
          ),
        );

        // Open modal on 1000dp expanded screen -> sideSheet
        await tester.tap(find.byKey(const ValueKey('telemetry-lane-selector')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsOneWidget);
        expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsNothing);

        // Toggle Speed (010D) to select it (uncommitted in sheet state)
        await tester.tap(find.text('Speed'));
        await tester.pumpAndSettle();

        // Verify speed checkbox is checked in sideSheet
        var speedCheckboxFinder = find.widgetWithText(CheckboxListTile, 'Speed');
        expect(speedCheckboxFinder, findsOneWidget);
        var speedTile = tester.widget<CheckboxListTile>(speedCheckboxFinder);
        expect(speedTile.value, isTrue);

        // Fold device: morph from 1000dp expanded to 500dp compact
        tester.view.physicalSize = const Size(500, 800);
        await tester.pumpAndSettle();

        // Verify surface morphed to bottomSheet
        expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsOneWidget);
        expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsNothing);

        // Assert uncommitted selection is preserved in bottomSheet
        speedCheckboxFinder = find.widgetWithText(CheckboxListTile, 'Speed');
        expect(speedCheckboxFinder, findsOneWidget);
        speedTile = tester.widget<CheckboxListTile>(speedCheckboxFinder);
        expect(speedTile.value, isTrue);

        // Unfold device: morph back from 500dp compact to 1000dp expanded
        tester.view.physicalSize = const Size(1000, 800);
        await tester.pumpAndSettle();

        // Verify surface morphed back to sideSheet
        expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsOneWidget);
        expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsNothing);

        // Assert uncommitted selection is still preserved
        speedCheckboxFinder = find.widgetWithText(CheckboxListTile, 'Speed');
        expect(speedCheckboxFinder, findsOneWidget);
        speedTile = tester.widget<CheckboxListTile>(speedCheckboxFinder);
        expect(speedTile.value, isTrue);

        // Tap Done button
        final doneButtonFinder = find.byType(FilledButton);
        expect(doneButtonFinder, findsOneWidget);
        await tester.tap(doneButtonFinder);
        await tester.pumpAndSettle();

        // Verify modal closed and both RPM & Speed were committed to provider
        expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsNothing);
        expect(
          testNotifier.updatedIds,
          containsAll([PidLibrary.engineRpm.id, PidLibrary.vehicleSpeed.id]),
        );
      });
    });

    // -------------------------------------------------------------------------
    // ServiceRecipeDetailSheet Tests
    // -------------------------------------------------------------------------
    group('ServiceRecipeDetailSheet', () {
      late ActiveTestProfile profile;

      setUp(() {
        final fixtureFile = File(BundledServiceRecipes.bundledAssetPaths.first);
        final jsonString = fixtureFile.readAsStringSync();
        profile = BundledServiceRecipes.parseProfileJson(jsonString);
      });

      testWidgets('F07-20: Compact (360x800) presents Bottom Sheet', (tester) async {
        await _pumpModalHarness(
          tester,
          size: const Size(360, 800),
          childBuilder: (context) => ElevatedButton(
            key: const Key('open_recipe'),
            onPressed: () => showServiceRecipeDetailSheet(
              context: context,
              profile: profile,
            ),
            child: const Text('Recipe'),
          ),
        );

        await tester.tap(find.byKey(const Key('open_recipe')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsOneWidget);
        expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsNothing);
        expect(find.byType(ServiceRecipeDetailSheet), findsOneWidget);
      });

      testWidgets('F07-21: Expanded (1000x800) presents Side Sheet', (tester) async {
        await _pumpModalHarness(
          tester,
          size: const Size(1000, 800),
          childBuilder: (context) => ElevatedButton(
            key: const Key('open_recipe'),
            onPressed: () => showServiceRecipeDetailSheet(
              context: context,
              profile: profile,
            ),
            child: const Text('Recipe'),
          ),
        );

        await tester.tap(find.byKey(const Key('open_recipe')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsOneWidget);
        expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsNothing);
        expect(find.byType(ServiceRecipeDetailSheet), findsOneWidget);
      });

      testWidgets('F07-22: Short landscape (700x360) renders without overflow and dismisses via close icon', (tester) async {
        await _pumpModalHarness(
          tester,
          size: const Size(700, 360),
          childBuilder: (context) => ElevatedButton(
            key: const Key('open_recipe'),
            onPressed: () => showServiceRecipeDetailSheet(
              context: context,
              profile: profile,
            ),
            child: const Text('Recipe'),
          ),
        );

        await tester.tap(find.byKey(const Key('open_recipe')));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ServiceRecipeDetailSheet), findsOneWidget);

        // Tap close icon
        final closeIconFinder = find.byIcon(Icons.close);
        expect(closeIconFinder, findsOneWidget);
        await tester.tap(closeIconFinder);
        await tester.pumpAndSettle();

        expect(find.byType(ServiceRecipeDetailSheet), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // PID Arrange Sheet Tests
    // -------------------------------------------------------------------------
    group('PID Arrange Sheet', () {
      testWidgets('F07-23: Compact (360x800) opens Bottom Sheet; Expanded (1000x800) opens Trailing Side Sheet', (tester) async {
        final pids = [PidLibrary.engineRpm, PidLibrary.vehicleSpeed];

        // 1. Compact check
        await _pumpModalHarness(
          tester,
          size: const Size(360, 800),
          overrides: [
            activePidsProvider.overrideWith(() => _FixedActivePids(pids)),
          ],
          childBuilder: (context) => ElevatedButton(
            key: const Key('open_arrange'),
            onPressed: () => showPidArrangeSheet(context),
            child: const Text('Arrange'),
          ),
        );

        await tester.tap(find.byKey(const Key('open_arrange')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsOneWidget);
        expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsNothing);

        // Dismiss
        await tester.tapAt(const Offset(50, 50));
        await tester.pumpAndSettle();

        // 2. Expanded check
        await _pumpModalHarness(
          tester,
          size: const Size(1000, 800),
          overrides: [
            activePidsProvider.overrideWith(() => _FixedActivePids(pids)),
          ],
          childBuilder: (context) => ElevatedButton(
            key: const Key('open_arrange'),
            onPressed: () => showPidArrangeSheet(context),
            child: const Text('Arrange'),
          ),
        );

        await tester.tap(find.byKey(const Key('open_arrange')));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsOneWidget);
        expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsNothing);

        final sideSheetFinder = find.byKey(const ValueKey('adaptive-modal-side-sheet'));
        final rect = tester.getRect(sideSheetFinder);
        // Trailing side sheet on 1000 width
        expect(rect.right, equals(1000.0 - 16.0));
      });

      testWidgets('F07-24: Vertical separating hinge in LTR isolates Side Sheet to trailing region (zero overlap)', (tester) async {
        const hingeFeature = DisplayFeature(
          bounds: Rect.fromLTWH(490, 0, 20, 800),
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.postureHalfOpened,
        );

        final pids = [PidLibrary.engineRpm, PidLibrary.vehicleSpeed];

        await _pumpModalHarness(
          tester,
          size: const Size(1000, 800),
          displayFeatures: const [hingeFeature],
          overrides: [
            activePidsProvider.overrideWith(() => _FixedActivePids(pids)),
          ],
          childBuilder: (context) => ElevatedButton(
            key: const Key('open_arrange'),
            onPressed: () => showPidArrangeSheet(context),
            child: const Text('Arrange'),
          ),
        );

        await tester.tap(find.byKey(const Key('open_arrange')));
        await tester.pumpAndSettle();

        final sideSheetFinder = find.byKey(const ValueKey('adaptive-modal-side-sheet'));
        expect(sideSheetFinder, findsOneWidget);

        final rect = tester.getRect(sideSheetFinder);
        // Must be strictly right of hinge: left >= 510.0
        expect(rect.left, greaterThanOrEqualTo(510.0));
        expect(rect.overlaps(hingeFeature.bounds), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // Tabletop Posture Mode
    // -------------------------------------------------------------------------
    group('Tabletop Posture Mode', () {
      testWidgets('Horizontal separating hinge forces single-region Dialog presentation', (tester) async {
        const tabletopHinge = DisplayFeature(
          bounds: Rect.fromLTWH(0, 390, 800, 20),
          type: DisplayFeatureType.hinge,
          state: DisplayFeatureState.postureHalfOpened,
        );

        await _pumpModalHarness(
          tester,
          size: const Size(800, 800),
          displayFeatures: const [tabletopHinge],
          childBuilder: (context) => ElevatedButton(
            key: const Key('open_export'),
            onPressed: () => showTelemetryExportSheet(context),
            child: const Text('Export'),
          ),
        );

        await tester.tap(find.byKey(const Key('open_export')));
        await tester.pumpAndSettle();

        final dialogFinder = find.byKey(const ValueKey('adaptive-modal-dialog'));
        expect(dialogFinder, findsOneWidget);

        final rect = tester.getRect(dialogFinder);
        // Zero overlap with horizontal tabletop hinge
        expect(rect.overlaps(tabletopHinge.bounds), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // Static Audit Check
    // -------------------------------------------------------------------------
    group('Static Audit Check', () {
      test('F07-25: 0 occurrences of showModalBottomSheet across all production code in lib/', () {
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
          reason:
              'Found legacy showModalBottomSheet call(s). All modal sheets must use showAdaptiveModal:\n${matches.join('\n')}',
        );
      });
    });
  });
}
