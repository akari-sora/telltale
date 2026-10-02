/// Integration and adaptive modal tests for [SettingsScreen] vehicle catalog flow (FOLD-04).
///
/// Verifies:
/// 1. Compact (<600): Market chooser opens in BottomSheet; US picker opens in BottomSheet.
/// 2. Expanded (>=840): Market chooser opens in Dialog; US picker opens in Trailing Side Sheet.
/// 3. Vertical separating hinge in LTR: Modal is strictly isolated to right region without hinge overlap.
/// 4. Vertical separating hinge in RTL: Modal is strictly isolated to left region without hinge overlap.
/// 5. Selection and result propagation: Selecting market and configuring vehicle updates profile.
library;

import 'dart:convert';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/obd/physics/vehicle_profile.dart';
import 'package:torque_obd/obd/vehicle_catalog/us_vehicle_catalog.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/settings.dart';
import 'package:torque_obd/state/vehicle_catalog.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';

import '../../support/localized_app.dart';

const _catalogCsv =
    'epa_id,year,make,model,base_model,transmission,drive,fuel_type,fuel_type_primary,fuel_type_secondary,alternative_vehicle_type,displacement_l,cylinders,modified_on\n'
    '1,2020,Alpha,Roadster,Roadster,Manual 6-spd,Rear-Wheel Drive,Premium,Premium Gasoline,,,2.0,4,2020-01-01\n';

String get _catalogManifest => jsonEncode({
      'schema_version': 2,
      'dataset': 'U.S. EPA FuelEconomy.gov Find-a-Car vehicle configurations',
      'coverage': {
        'market': 'United States',
        'vehicle_scope': 'FuelEconomy.gov Find-a-Car configurations',
      },
      'source': {
        'archive_url':
            'https://www.fueleconomy.gov/feg/epadata/vehicles.csv.zip',
        'landing_page': 'https://www.fueleconomy.gov/feg/download.shtml',
        'retrieved_at_utc': '2026-08-29T14:28:23+00:00',
        'sha256': 'a' * 64,
      },
      'output': {
        'file': 'us_epa_vehicles.csv',
        'columns': UsVehicleCatalog.requiredColumns,
        'row_count': 1,
        'sha256':
            '55d34c5d52f6018feca6735707c4ae443b939a0f26f69bd52651e70f9f388612',
        'size_bytes': 268,
        'unique_make_count': 1,
        'year_min': 2020,
        'year_max': 2020,
      },
    });

class _DisconnectedSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState();
}

Future<ProviderContainer> _pumpSettingsScreen(
  WidgetTester tester, {
  required Size size,
  List<DisplayFeature> displayFeatures = const [],
  TextDirection textDirection = TextDirection.ltr,
  UsVehicleCatalog? catalog,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.displayFeatures = displayFeatures;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetDisplayFeatures);

  final resolvedCatalog = catalog ??
      UsVehicleCatalog.fromStrings(
          manifestJson: _catalogManifest, csv: _catalogCsv);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      obdSessionProvider.overrideWith(_DisconnectedSession.new),
      usVehicleCatalogLoaderProvider
          .overrideWithValue(() async => resolvedCatalog),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: testUiLocale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) {
          return Directionality(
            textDirection: textDirection,
            child: MediaQuery(
              data: MediaQueryData(
                size: size,
                displayFeatures: displayFeatures,
              ),
              child: child!,
            ),
          );
        },
        home: const Scaffold(
          body: SettingsScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('SettingsScreen Adaptive Modal Integration (FOLD-04)', () {
    testWidgets(
        'F04-S01: Compact screen presents market chooser and vehicle picker in BottomSheet',
        (tester) async {
      await _pumpSettingsScreen(tester, size: const Size(400, 800));

      // Scroll down to locate the official vehicle catalog button
      final chooseButton =
          find.widgetWithIcon(OutlinedButton, Icons.directions_car_outlined);
      await tester.scrollUntilVisible(chooseButton, 200);
      await tester.tap(chooseButton);
      await tester.pumpAndSettle();

      // Market chooser opens as BottomSheet in Compact
      expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('adaptive-modal-dialog')), findsNothing);
      expect(find.byKey(const Key('catalog_market_us')), findsOneWidget);

      // Tap US market to open US EPA vehicle picker
      await tester.tap(find.byKey(const Key('catalog_market_us')));
      await tester.pumpAndSettle();

      // Vehicle picker opens as BottomSheet in Compact
      expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')),
          findsOneWidget);
      expect(find.byKey(const Key('us_epa_year')), findsOneWidget);
    });

    testWidgets(
        'F04-S02: Expanded screen presents market chooser in Dialog and vehicle picker in Trailing Side Sheet',
        (tester) async {
      await _pumpSettingsScreen(tester, size: const Size(1000, 800));

      final chooseButton =
          find.widgetWithIcon(OutlinedButton, Icons.directions_car_outlined);
      await tester.scrollUntilVisible(chooseButton, 200);
      await tester.tap(chooseButton);
      await tester.pumpAndSettle();

      // Market chooser opens as centered Dialog on expanded screen
      expect(
          find.byKey(const ValueKey('adaptive-modal-dialog')), findsOneWidget);
      expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')),
          findsNothing);

      // Select US market
      await tester.tap(find.byKey(const Key('catalog_market_us')));
      await tester.pumpAndSettle();

      // US EPA vehicle picker opens as Trailing Side Sheet on expanded screen
      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')),
          findsNothing);

      final sheetRender = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('adaptive-modal-side-sheet')),
      );
      expect(sheetRender.size.width, lessThanOrEqualTo(560.0));

      final sheetTopRight = tester.getTopRight(
        find.byKey(const ValueKey('adaptive-modal-side-sheet')),
      );
      expect(sheetTopRight.dx, closeTo(1000 - 16.0, 1.0));
    });

    testWidgets(
        'F04-S03: Vertical separating hinge in LTR isolates picker to right region',
        (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(490, 0, 510, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.unknown,
      );

      await _pumpSettingsScreen(
        tester,
        size: const Size(1000, 800),
        displayFeatures: const [hinge],
        textDirection: TextDirection.ltr,
      );

      final chooseButton =
          find.widgetWithIcon(OutlinedButton, Icons.directions_car_outlined);
      await tester.scrollUntilVisible(chooseButton, 200);
      await tester.tap(chooseButton);
      await tester.pumpAndSettle();

      // Open US market
      await tester.tap(find.byKey(const Key('catalog_market_us')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')),
          findsOneWidget);

      final modalRect = tester.getRect(
        find.byKey(const ValueKey('adaptive-modal-side-sheet')),
      );
      expect(modalRect.left, greaterThanOrEqualTo(510.0));
      expect(modalRect.overlaps(hinge.bounds), isFalse);
    });

    testWidgets(
        'F04-S04: Vertical separating hinge in RTL isolates picker to left region',
        (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(490, 0, 510, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.unknown,
      );

      await _pumpSettingsScreen(
        tester,
        size: const Size(1000, 800),
        displayFeatures: const [hinge],
        textDirection: TextDirection.rtl,
      );

      final chooseButton =
          find.widgetWithIcon(OutlinedButton, Icons.directions_car_outlined);
      await tester.scrollUntilVisible(chooseButton, 200);
      await tester.tap(chooseButton);
      await tester.pumpAndSettle();

      // Open US market
      await tester.tap(find.byKey(const Key('catalog_market_us')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')),
          findsOneWidget);

      final modalRect = tester.getRect(
        find.byKey(const ValueKey('adaptive-modal-side-sheet')),
      );
      expect(modalRect.right, lessThanOrEqualTo(490.0));
      expect(modalRect.overlaps(hinge.bounds), isFalse);
    });

    testWidgets(
        'F04-S05: Full picker selection updates vehicle profile state',
        (tester) async {
      final container = await _pumpSettingsScreen(
        tester,
        size: const Size(1000, 800),
      );

      final chooseButton =
          find.widgetWithIcon(OutlinedButton, Icons.directions_car_outlined);
      await tester.scrollUntilVisible(chooseButton, 200);
      await tester.tap(chooseButton);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('catalog_market_us')));
      await tester.pumpAndSettle();

      // Select Year 2020
      await tester.tap(find.byKey(const Key('us_epa_year')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2020').last);
      await tester.pumpAndSettle();

      // Select Make Alpha
      await tester.tap(find.byKey(const Key('us_epa_make')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alpha').last);
      await tester.pumpAndSettle();

      // Select Model Roadster
      await tester.tap(find.byKey(const Key('us_epa_model')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Roadster').last);
      await tester.pumpAndSettle();

      // Select configuration
      await tester.tap(find.byKey(const Key('us_epa_config_1')));
      await tester.pumpAndSettle();

      // Press Apply button inside picker sheet
      final applyButton = find.descendant(
        of: find.byKey(const ValueKey('adaptive-modal-side-sheet')),
        matching: find.byType(FilledButton),
      );
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      // Modal is dismissed
      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')),
          findsNothing);

      // Verify vehicle profile updated
      final updatedProfile = container.read(vehicleProfileProvider);
      expect(updatedProfile.displacementL, 2.0);
      expect(updatedProfile.fuelType, FuelType.gasoline);
    });
  });
}
