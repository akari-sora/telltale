/// Widget and interaction tests for ServiceRecipesScreen and ServiceRecipeDetailSheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';
import 'package:torque_obd/diagnostics/service_recipes/active_test_profile.dart';
import 'package:torque_obd/diagnostics/service_recipes/candidate_matrix.dart';
import 'package:torque_obd/diagnostics/service_recipes/mode08_discovery_service.dart';
import 'package:torque_obd/diagnostics/service_recipes/qualification_tier.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart'
    show sharedPreferencesProvider;
import 'package:torque_obd/state/service_recipes_provider.dart';
import 'package:torque_obd/ui/screens/settings/settings_screen.dart';
import 'package:torque_obd/ui/screens/workshop/service_recipe_detail_sheet.dart';
import 'package:torque_obd/ui/screens/workshop/service_recipes_screen.dart';

import '../../support/fake_elm327.dart';
import '../../support/localized_app.dart';
import 'package:torque_obd/obd/elm327_client.dart';

class _DisconnectedSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState();
}

class _ConnectedCanSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState(
    phase: ConnectionPhase.connected,
    protocol: 'ISO 15765-4 (CAN 11/500)',
  );
}

class _RealControllerCanSession extends ObdSession {
  _RealControllerCanSession(this._clientInstance);

  final Elm327Client _clientInstance;

  @override
  Elm327Client? get client => _clientInstance;

  @override
  int get generation => _clientInstance.connectionGeneration;

  @override
  ObdConnectionState build() => const ObdConnectionState(
    phase: ConnectionPhase.connected,
    protocol: 'ISO 15765-4 (CAN 11/500)',
  );

  @override
  Future<T> runDiagnosticExclusive<T>({
    required String operationName,
    required Future<T> Function(Object wireOwner) action,
    DiagnosticCancellation? cancellation,
    DateTime? deadline,
  }) async {
    return await action(Object());
  }
}

Map<String, List<int>> _physicsReplies() => {
  '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
  '0105': [0x41, 0x05, 0x7B],
  '010C': [0x41, 0x0C, 0x1A, 0xF8],
};

FakeElm327 _createTestCan11Transport({
  Map<String, List<String>> literalResponses = const {},
}) => FakeElm327(
  protocol: BusProtocol.can11,
  ecus: [
    FakeEcu(
      name: 'ECM',
      requestId: '7E0',
      responseId: '7E8',
      responses: _physicsReplies(),
      literalResponses: literalResponses,
    ),
  ],
);

class _TestDiscoveryNotifier extends Mode08DiscoveryNotifier {
  _TestDiscoveryNotifier(this._initialState);

  final Mode08DiscoveryState _initialState;
  bool discoveryInvoked = false;

  @override
  Mode08DiscoveryState build() => _initialState;

  @override
  Future<void> runDiscovery({
    Duration timeout = Mode08DiscoveryService.defaultDiscoveryTimeout,
    Duration budget = Mode08DiscoveryService.defaultTotalBudget,
    DateTime? deadline,
  }) async {
    discoveryInvoked = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CandidateMatrix bundledMatrix;

  setUpAll(() async {
    final profiles = <ActiveTestProfile>[];
    for (final path in BundledServiceRecipes.bundledAssetPaths) {
      final jsonString = await rootBundle.loadString(path);
      profiles.add(BundledServiceRecipes.parseProfileJson(jsonString));
    }
    bundledMatrix = CandidateMatrix.fromProfiles(profiles);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ServiceRecipesScreen', () {
    testWidgets(
      'renders Zero Live Candidates Safety Banner and loads bundled recipes',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_DisconnectedSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        // Safety Banner
        expect(
          find.byKey(const Key('zero_live_candidates_banner')),
          findsOneWidget,
        );
        expect(find.text('Zero Live Candidates'), findsOneWidget);
        expect(
          find.textContaining('strictly prohibited (0 qualified vehicles)'),
          findsOneWidget,
        );

        // Bundled recipes
        expect(
          find.byKey(const Key('service_recipe_tile_synthetic_mode08_evap_01')),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const Key('service_recipe_tile_synthetic_uds_2f_fan_control_01'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const Key('service_recipe_tile_synthetic_uds_31_pump_routine_01'),
          ),
          findsOneWidget,
        );

        // Badges
        expect(find.text('Simulation Ready'), findsNWidgets(3));
        expect(find.text('Live Blocked (0 Live Candidates)'), findsNWidgets(3));
      },
    );

    testWidgets(
      'tapping a recipe tile opens detail sheet with full specifications',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_DisconnectedSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final tile = find.byKey(
          const Key('service_recipe_tile_synthetic_mode08_evap_01'),
        );
        expect(tile, findsOneWidget);
        await tester.tap(tile);
        await tester.pumpAndSettle();

        // Sheet contents
        final sheet = find.byType(ServiceRecipeDetailSheet);
        expect(sheet, findsOneWidget);
        expect(
          find.descendant(
            of: sheet,
            matching: find.text('Standard: SAE J1979:2014'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheet,
            matching: find.textContaining('Section 8.4 Mode 08'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: sheet, matching: find.text('ECU Header: 7E0')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheet,
            matching: find.textContaining('vehicleSpeedKmh: 0 .. 0'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheet,
            matching: find.text('Automatic return upon completion or timeout'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sheet,
            matching: find.textContaining(
              '341756910e1fac80dfe5c34410a5a2ce5487c2f2c0d4e4abc1025f3e595f287d',
            ),
          ),
          findsOneWidget,
        );

        // Close the sheet
        final closeBtn = find.widgetWithText(FilledButton, 'Close');
        expect(closeBtn, findsOneWidget);
        await tester.tap(closeBtn);
        await tester.pumpAndSettle();

        expect(find.byType(ServiceRecipeDetailSheet), findsNothing);
      },
    );

    testWidgets('Mode 08 discovery button is disabled when not connected', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            obdSessionProvider.overrideWith(_DisconnectedSession.new),
            serviceRecipesMatrixProvider.overrideWith(
              (ref) async => bundledMatrix,
            ),
          ],
          child: localizedMaterialApp(
            home: const ServiceRecipesScreen(),
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('mode08_discovery_button')),
      );
      expect(button.onPressed, isNull);
      expect(
        find.text('Requires an active OBD-II CAN bus connection.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Mode 08 discovery triggers runDiscovery on tap when connected',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final notifier = _TestDiscoveryNotifier(
          const Mode08DiscoveryState.idle(),
        );

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_ConnectedCanSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
              mode08DiscoveryStateProvider.overrideWith(() => notifier),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final button = find.byKey(const Key('mode08_discovery_button'));
        expect(button, findsOneWidget);
        await tester.tap(button);
        await tester.pump();

        expect(notifier.discoveryInvoked, isTrue);
      },
    );

    testWidgets(
      'Mode 08 discovery completed state renders success message and TID chips',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final result = Mode08DiscoveryResult(
          isSupported: true,
          supportStatus: EcuSupportStatus.supported,
          supportedTids: const {0x01, 0x02},
          queriedBlocks: const [0x00],
          discoveredAt: DateTime.utc(2026, 9, 14),
        );

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_ConnectedCanSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
              mode08DiscoveryStateProvider.overrideWith(
                () => _TestDiscoveryNotifier(
                  Mode08DiscoveryState.completed(result: result),
                ),
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('mode08_discovery_success_container')),
          findsOneWidget,
        );
        expect(
          find.text('Mode 08 is supported by ECU. Supported TIDs: \$01, \$02'),
          findsOneWidget,
        );
        expect(find.text('TID \$01'), findsOneWidget);
        expect(find.text('TID \$02'), findsOneWidget);
      },
    );

    testWidgets(
      'Mode 08 discovery partially completed renders partial warning with failure reason, uncompleted blocks, and disclaimer',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final result = Mode08DiscoveryResult(
          isSupported: true,
          supportStatus: EcuSupportStatus.supported,
          supportedTids: const {0x01, 0x02},
          queriedBlocks: const [0x00],
          unqueriedBlocks: const [0x20],
          isComplete: false,
          failureReason: 'Timeout on block 0x20',
          discoveredAt: DateTime.utc(2026, 9, 14),
        );

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_ConnectedCanSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
              mode08DiscoveryStateProvider.overrideWith(
                () => _TestDiscoveryNotifier(
                  Mode08DiscoveryState.completed(result: result),
                ),
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final warningContainer = find.byKey(
          const Key('mode08_discovery_partial_warning'),
        );
        expect(warningContainer, findsOneWidget);
        expect(
          find.descendant(
            of: warningContainer,
            matching: find.textContaining('Timeout on block 0x20'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: warningContainer,
            matching: find.textContaining('Uncompleted blocks: \$20'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: warningContainer,
            matching: find.textContaining(
              'Not found does not mean unsupported',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: warningContainer,
            matching: find.textContaining('未查到不代表不支援'),
          ),
          findsNothing,
        );
        expect(
          find.byKey(const Key('mode08_discovery_success_container')),
          findsOneWidget,
        );
        expect(find.text('TID \$01'), findsOneWidget);
        expect(find.text('TID \$02'), findsOneWidget);
      },
    );

    testWidgets(
      'Mode 08 discovery partial warning renders purely in German without Chinese leak',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final result = Mode08DiscoveryResult(
          isSupported: true,
          supportStatus: EcuSupportStatus.supported,
          supportedTids: const {0x01, 0x02},
          queriedBlocks: const [0x00],
          unqueriedBlocks: const [0x20],
          isComplete: false,
          incompletionReason:
              Mode08IncompletionReason.unheaderedCrossBlockLimitation,
          discoveredAt: DateTime.utc(2026, 9, 14),
        );

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_ConnectedCanSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
              mode08DiscoveryStateProvider.overrideWith(
                () => _TestDiscoveryNotifier(
                  Mode08DiscoveryState.completed(result: result),
                ),
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('de'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final warningContainer = find.byKey(
          const Key('mode08_discovery_partial_warning'),
        );
        expect(warningContainer, findsOneWidget);
        expect(
          find.descendant(
            of: warningContainer,
            matching: find.textContaining(
              'Quellzuordnung und Abdeckung unbestätigt',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: warningContainer,
            matching: find.textContaining(
              'Hinweis: Nicht gefunden bedeutet nicht nicht unterstützt.',
            ),
          ),
          findsOneWidget,
        );
        // Pure German: no Chinese characters
        expect(
          find.descendant(
            of: warningContainer,
            matching: find.textContaining('未查到不代表不支援'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: warningContainer,
            matching: find.textContaining('來源歸因'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Mode 08 discovery partial warning renders Traditional Chinese correctly',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final result = Mode08DiscoveryResult(
          isSupported: true,
          supportStatus: EcuSupportStatus.supported,
          supportedTids: const {0x01, 0x02},
          queriedBlocks: const [0x00],
          unqueriedBlocks: const [0x20],
          isComplete: false,
          incompletionReason:
              Mode08IncompletionReason.unheaderedCrossBlockLimitation,
          discoveredAt: DateTime.utc(2026, 9, 14),
        );

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_ConnectedCanSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
              mode08DiscoveryStateProvider.overrideWith(
                () => _TestDiscoveryNotifier(
                  Mode08DiscoveryState.completed(result: result),
                ),
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: testUiLocale,
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final warningContainer = find.byKey(
          const Key('mode08_discovery_partial_warning'),
        );
        expect(warningContainer, findsOneWidget);
        expect(
          find.descendant(
            of: warningContainer,
            matching: find.textContaining('來源歸因與覆蓋完整度未確認'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: warningContainer,
            matching: find.textContaining('未查到不代表不支援'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Mode 08 discovery unsupported state renders unsupported message',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final result = Mode08DiscoveryResult(
          isSupported: false,
          supportStatus: EcuSupportStatus.unsupported,
          supportedTids: const {},
          queriedBlocks: const [0x00],
          discoveredAt: DateTime.utc(2026, 9, 14),
        );

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_ConnectedCanSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
              mode08DiscoveryStateProvider.overrideWith(
                () => _TestDiscoveryNotifier(
                  Mode08DiscoveryState.completed(result: result),
                ),
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.text('Mode 08 is not supported by this ECU'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Mode 08 discovery refused state renders refused message', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            obdSessionProvider.overrideWith(_ConnectedCanSession.new),
            serviceRecipesMatrixProvider.overrideWith(
              (ref) async => bundledMatrix,
            ),
            mode08DiscoveryStateProvider.overrideWith(
              () => _TestDiscoveryNotifier(
                const Mode08DiscoveryState.refused(reason: 'CAN bus required'),
              ),
            ),
          ],
          child: localizedMaterialApp(
            home: const ServiceRecipesScreen(),
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('CAN bus required'), findsOneWidget);
    });
  });

  group('SettingsScreen navigation tile', () {
    testWidgets('contains service recipes entry in diagnostics section', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            obdSessionProvider.overrideWith(_DisconnectedSession.new),
          ],
          child: localizedMaterialApp(
            home: const SettingsScreen(),
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      final tile = find.byKey(const Key('settings_service_recipes_tile'));
      await tester.scrollUntilVisible(
        tile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(tile, findsOneWidget);
      expect(find.text('Service Recipes & Active Tests'), findsOneWidget);
      expect(
        find.text(
          'Inspect workshop service recipes and discover supported Mode 08 tests',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'Mode 08 discovery outcome renders without overflow on narrow screen (320dp) and 200% text scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final result = Mode08DiscoveryResult(
          isSupported: true,
          supportStatus: EcuSupportStatus.supported,
          supportedTids: const {0x01, 0x02, 0x20, 0x22},
          queriedBlocks: const [0x00, 0x20],
          unqueriedBlocks: const [0x40],
          isComplete: false,
          incompletionReason:
              Mode08IncompletionReason.unheaderedCrossBlockLimitation,
          discoveredAt: DateTime.utc(2026, 9, 14),
        );

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(_ConnectedCanSession.new),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
              mode08DiscoveryStateProvider.overrideWith(
                () => _TestDiscoveryNotifier(
                  Mode08DiscoveryState.completed(result: result),
                ),
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: const Locale('en'),
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final warning = find.byKey(
          const Key('mode08_discovery_partial_warning'),
        );
        await tester.scrollUntilVisible(
          warning,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(warning, findsOneWidget);
      },
    );

    group('real Mode08DiscoveryNotifier -> UI classification and localization', () {
      Future<void> pumpScreenAndTriggerDiscovery(
        WidgetTester tester, {
        required ObdSession session,
        required Locale locale,
      }) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              obdSessionProvider.overrideWith(() => session),
              serviceRecipesMatrixProvider.overrideWith(
                (ref) async => bundledMatrix,
              ),
            ],
            child: localizedMaterialApp(
              home: const ServiceRecipesScreen(),
              locale: locale,
            ),
          ),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        final discoverButton = find.byKey(const Key('mode08_discovery_button'));
        await tester.scrollUntilVisible(
          discoverButton,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(discoverButton);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }

      testWidgets('NO DATA outcome renders unknown in EN', (tester) async {
        await tester.runAsync(() async {
          final transport = _createTestCan11Transport();
          final client = Elm327Client(transport);
          expect(await client.connect(), isTrue);
          client.cancelWatchdogForTesting();
          try {
            await pumpScreenAndTriggerDiscovery(
              tester,
              session: _RealControllerCanSession(client),
              locale: const Locale('en'),
            );

            expect(find.textContaining('unknown', findRichText: true), findsWidgets);
            expect(find.textContaining('0x00'), findsWidgets);
          } finally {
            await client.disconnect();
          }
        });
      });

      testWidgets('NO DATA outcome renders unknown in zh-Hant', (tester) async {
        await tester.runAsync(() async {
          final transport = _createTestCan11Transport();
          final client = Elm327Client(transport);
          expect(await client.connect(), isTrue);
          client.cancelWatchdogForTesting();
          try {
            await pumpScreenAndTriggerDiscovery(
              tester,
              session: _RealControllerCanSession(client),
              locale: testUiLocale,
            );

            expect(find.textContaining('未知', findRichText: true), findsWidgets);
            expect(find.textContaining('0x00'), findsWidgets);
          } finally {
            await client.disconnect();
          }
        });
      });

      testWidgets('NRC 22 outcome renders unknown in EN', (tester) async {
        await tester.runAsync(() async {
          final transport = _createTestCan11Transport(
            literalResponses: {
              '0800': ['7E8 03 7F 08 22'],
            },
          );
          final client = Elm327Client(transport);
          expect(await client.connect(), isTrue);
          client.cancelWatchdogForTesting();
          try {
            await pumpScreenAndTriggerDiscovery(
              tester,
              session: _RealControllerCanSession(client),
              locale: const Locale('en'),
            );

            expect(find.textContaining('unknown', findRichText: true), findsWidgets);
            expect(find.textContaining('0x22'), findsWidgets);
          } finally {
            await client.disconnect();
          }
        });
      });

      testWidgets('NRC 22 outcome renders unknown in zh-Hant', (tester) async {
        await tester.runAsync(() async {
          final transport = _createTestCan11Transport(
            literalResponses: {
              '0800': ['7E8 03 7F 08 22'],
            },
          );
          final client = Elm327Client(transport);
          expect(await client.connect(), isTrue);
          client.cancelWatchdogForTesting();
          try {
            await pumpScreenAndTriggerDiscovery(
              tester,
              session: _RealControllerCanSession(client),
              locale: testUiLocale,
            );

            expect(find.textContaining('未知', findRichText: true), findsWidgets);
            expect(find.textContaining('0x22'), findsWidgets);
          } finally {
            await client.disconnect();
          }
        });
      });

      testWidgets(
        'NRC 12 outcome renders unsupported in EN without unknown',
        (tester) async {
          await tester.runAsync(() async {
            final transport = _createTestCan11Transport(
              literalResponses: {
                '0800': ['7E8 03 7F 08 12'],
              },
            );
            final client = Elm327Client(transport);
            expect(await client.connect(), isTrue);
            client.cancelWatchdogForTesting();
            try {
              await pumpScreenAndTriggerDiscovery(
                tester,
                session: _RealControllerCanSession(client),
                locale: const Locale('en'),
              );

              expect(
                find.textContaining('not supported', findRichText: true),
                findsWidgets,
              );
              expect(find.textContaining('0x12'), findsWidgets);
              expect(
                find.textContaining('unknown', findRichText: true),
                findsNothing,
              );
              expect(
                find.textContaining('Unknown', findRichText: true),
                findsNothing,
              );
            } finally {
              await client.disconnect();
            }
          });
        },
      );

      testWidgets(
        'NRC 12 outcome renders unsupported in zh-Hant without unknown',
        (tester) async {
          await tester.runAsync(() async {
            final transport = _createTestCan11Transport(
              literalResponses: {
                '0800': ['7E8 03 7F 08 12'],
              },
            );
            final client = Elm327Client(transport);
            expect(await client.connect(), isTrue);
            client.cancelWatchdogForTesting();
            try {
              await pumpScreenAndTriggerDiscovery(
                tester,
                session: _RealControllerCanSession(client),
                locale: testUiLocale,
              );

              expect(
                find.textContaining('不支援', findRichText: true),
                findsWidgets,
              );
              expect(find.textContaining('0x12'), findsWidgets);
              expect(find.textContaining('未知', findRichText: true), findsNothing);
            } finally {
              await client.disconnect();
            }
          });
        },
      );

      testWidgets(
        'Malformed response renders localized reason and hides raw enum in EN',
        (tester) async {
          await tester.runAsync(() async {
            final transport = _createTestCan11Transport(
              literalResponses: {
                '0800': ['7E8 ZZ INVALID HEX DATA'],
              },
            );
            final client = Elm327Client(transport);
            expect(await client.connect(), isTrue);
            client.cancelWatchdogForTesting();
            try {
              await pumpScreenAndTriggerDiscovery(
                tester,
                session: _RealControllerCanSession(client),
                locale: const Locale('en'),
              );

              expect(
                find.textContaining('Invalid hex', findRichText: true),
                findsWidgets,
              );
              expect(find.textContaining('invalidHex'), findsNothing);
              expect(
                find.textContaining('7E8 ZZ INVALID HEX DATA'),
                findsWidgets,
              );
            } finally {
              await client.disconnect();
            }
          });
        },
      );

      testWidgets(
        'Malformed response renders localized reason and hides raw enum in zh-Hant',
        (tester) async {
          await tester.runAsync(() async {
            final transport = _createTestCan11Transport(
              literalResponses: {
                '0800': ['7E8 ZZ INVALID HEX DATA'],
              },
            );
            final client = Elm327Client(transport);
            expect(await client.connect(), isTrue);
            client.cancelWatchdogForTesting();
            try {
              await pumpScreenAndTriggerDiscovery(
                tester,
                session: _RealControllerCanSession(client),
                locale: testUiLocale,
              );

              expect(
                find.textContaining('十六進位格式無效', findRichText: true),
                findsWidgets,
              );
              expect(find.textContaining('invalidHex'), findsNothing);
              expect(
                find.textContaining('7E8 ZZ INVALID HEX DATA'),
                findsWidgets,
              );
            } finally {
              await client.disconnect();
            }
          });
        },
      );
    });
  });
}
