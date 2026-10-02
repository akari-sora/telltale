import 'dart:ui'
    show DisplayFeature, DisplayFeatureState, DisplayFeatureType, Rect, Size;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/locale_settings.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/ui/screens/connect/connect_layout.dart';
import 'package:torque_obd/ui/screens/connect/connect_screen.dart';

class _IdleSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState(
        phase: ConnectionPhase.disconnected,
      );
}

class _ConnectFoldableHarness extends StatefulWidget {
  const _ConnectFoldableHarness({
    required this.initialSize,
    this.initialFeatures = const [],
    this.initialPadding = EdgeInsets.zero,
    this.initialInsets = EdgeInsets.zero,
    this.textDirection = TextDirection.ltr,
    this.textScaler = TextScaler.noScaling,
  });

  final Size initialSize;
  final List<DisplayFeature> initialFeatures;
  final EdgeInsets initialPadding;
  final EdgeInsets initialInsets;
  final TextDirection textDirection;
  final TextScaler textScaler;

  @override
  State<_ConnectFoldableHarness> createState() => _ConnectFoldableHarnessState();
}

class _ConnectFoldableHarnessState extends State<_ConnectFoldableHarness> {
  late Size size;
  late List<DisplayFeature> features;
  late EdgeInsets padding;
  late EdgeInsets insets;

  @override
  void initState() {
    super.initState();
    size = widget.initialSize;
    features = widget.initialFeatures;
    padding = widget.initialPadding;
    insets = widget.initialInsets;
  }

  void updateLayout({
    required Size newSize,
    List<DisplayFeature> newFeatures = const [],
    EdgeInsets? newPadding,
    EdgeInsets? newInsets,
  }) {
    setState(() {
      size = newSize;
      features = newFeatures;
      if (newPadding != null) padding = newPadding;
      if (newInsets != null) insets = newInsets;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        displayFeatures: features,
        padding: padding,
        viewInsets: insets,
        textScaler: widget.textScaler,
      ),
      child: Directionality(
        textDirection: widget.textDirection,
        child: const ConnectScreen(),
      ),
    );
  }
}

Future<void> _pumpConnectScreen(
  WidgetTester tester, {
  required Size size,
  List<DisplayFeature> features = const [],
  EdgeInsets padding = EdgeInsets.zero,
  EdgeInsets insets = EdgeInsets.zero,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
  Map<String, Object> prefsData = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.displayFeatures = features;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetDisplayFeatures);

  SharedPreferences.setMockInitialValues(prefsData);
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        obdSessionProvider.overrideWith(() => _IdleSession()),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final locale = resolveAppLocale(
            preference: ref.watch(localePreferenceProvider),
            deviceLocales: const [Locale('en', 'US')],
          );
          return MaterialApp(
            theme: AppTheme.dark(),
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: _ConnectFoldableHarness(
              initialSize: size,
              initialFeatures: features,
              initialPadding: padding,
              initialInsets: insets,
              textDirection: textDirection,
              textScaler: textScaler,
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Connection Wizard Adaptive & Foldable Tests (FOLD-07)', () {
    testWidgets('F07-01: Compact 360dp maintains single scroll workflow taking full width', (tester) async {
      await _pumpConnectScreen(tester, size: const Size(360, 800));

      final scrollFinder = find.byType(CustomScrollView);
      expect(scrollFinder, findsOneWidget);

      final rect = tester.getRect(scrollFinder);
      expect(rect.width, equals(360.0));
      expect(rect.left, equals(0.0));
      expect(rect.right, equals(360.0));

      expect(find.text('Telltale'), findsOneWidget);
      expect(find.byKey(const Key('connect_language_entry')), findsOneWidget);
    });

    testWidgets('F07-02: Medium 700dp centers wizard viewport with width <= 600', (tester) async {
      await _pumpConnectScreen(tester, size: const Size(700, 800));

      final scrollFinder = find.byType(CustomScrollView);
      expect(scrollFinder, findsOneWidget);

      final rect = tester.getRect(scrollFinder);
      expect(rect.width, equals(ConnectLayout.maxContentWidth));
      // Centered: (700 - 600) / 2 = 50.0
      expect(rect.left, equals(50.0));
      expect(rect.right, equals(650.0));
    });

    testWidgets('F07-03: Expanded 1200dp centers wizard viewport with width 600', (tester) async {
      await _pumpConnectScreen(tester, size: const Size(1200, 800));

      final scrollFinder = find.byType(CustomScrollView);
      expect(scrollFinder, findsOneWidget);

      final rect = tester.getRect(scrollFinder);
      expect(rect.width, equals(ConnectLayout.maxContentWidth));
      // Centered: (1200 - 600) / 2 = 300.0
      expect(rect.left, equals(300.0));
      expect(rect.right, equals(900.0));
    });

    testWidgets('F07-04: Vertical separating hinge in LTR confines wizard to left primary region (zero overlap)', (tester) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      await _pumpConnectScreen(
        tester,
        size: const Size(1000, 800),
        features: const [hingeFeature],
      );

      final scrollFinder = find.byType(CustomScrollView);
      expect(scrollFinder, findsOneWidget);

      final rect = tester.getRect(scrollFinder);
      expect(rect.overlaps(hingeFeature.bounds), isFalse);
      expect(rect.right, lessThanOrEqualTo(490.0));
    });

    testWidgets('F07-05: Vertical separating hinge in RTL confines wizard to right primary region (zero overlap)', (tester) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      await _pumpConnectScreen(
        tester,
        size: const Size(1000, 800),
        features: const [hingeFeature],
        textDirection: TextDirection.rtl,
      );

      final scrollFinder = find.byType(CustomScrollView);
      expect(scrollFinder, findsOneWidget);

      final rect = tester.getRect(scrollFinder);
      expect(rect.overlaps(hingeFeature.bounds), isFalse);
      expect(rect.left, greaterThanOrEqualTo(510.0));
    });

    testWidgets('F07-06: Horizontal separating hinge (tabletop) confines wizard to top region', (tester) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(0, 390, 800, 20),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      await _pumpConnectScreen(
        tester,
        size: const Size(800, 800),
        features: const [hingeFeature],
      );

      final scrollFinder = find.byType(CustomScrollView);
      expect(scrollFinder, findsOneWidget);

      final rect = tester.getRect(scrollFinder);
      expect(rect.overlaps(hingeFeature.bounds), isFalse);
      expect(rect.bottom, lessThanOrEqualTo(390.0));
    });

    testWidgets('F07-07: Short landscape 700x360 renders without overflow and scrolls to transport cards', (tester) async {
      await _pumpConnectScreen(tester, size: const Size(700, 360));

      expect(tester.takeException(), isNull);
      expect(find.text('Telltale'), findsOneWidget);

      // Scroll to Demo transport card
      await tester.scrollUntilVisible(
        find.text('Demo simulator'),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Demo simulator'), findsOneWidget);
    });

    testWidgets('F07-08: Short landscape 700x360 with textScale 2.0 reachable without overflow', (tester) async {
      await _pumpConnectScreen(
        tester,
        size: const Size(700, 360),
        textScaler: const TextScaler.linear(2.0),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('connect_language_entry')), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Wi-Fi'),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Wi-Fi'), findsOneWidget);
    });

    testWidgets('F07-09: Wi-Fi card expanded with keyboard insets is scrollable and visible', (tester) async {
      await _pumpConnectScreen(
        tester,
        size: const Size(800, 700),
        insets: const EdgeInsets.only(bottom: 250),
      );

      // Drag up to make Wi-Fi card visible above the keyboard insets
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
      await tester.pumpAndSettle();

      expect(find.text('Wi-Fi'), findsOneWidget);
      await tester.tap(find.text('Wi-Fi'));
      await tester.pumpAndSettle();

      expect(find.text('IP address'), findsOneWidget);
      expect(find.text('Port'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Connect'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.widgetWithText(FilledButton, 'Connect'),
        findsOneWidget,
      );
    });

    testWidgets('F07-10: Language picker on compact (360x800) opens as Bottom Sheet', (tester) async {
      await _pumpConnectScreen(tester, size: const Size(360, 800));

      await tester.tap(find.byKey(const Key('connect_language_entry')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('adaptive-modal-dialog')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('adaptive-modal-bottom-sheet')),
          matching: find.text('Language / 語言'),
        ),
        findsOneWidget,
      );
      expect(find.text('繁體中文'), findsOneWidget);
    });

    testWidgets('F07-10b: Language picker on compact (360x800) is content-sized (< 0.86 * 800) with all options visible', (tester) async {
      await _pumpConnectScreen(tester, size: const Size(360, 800));

      await tester.tap(find.byKey(const Key('connect_language_entry')));
      await tester.pumpAndSettle();

      final sheetFinder = find.byKey(const ValueKey('adaptive-modal-bottom-sheet'));
      expect(sheetFinder, findsOneWidget);

      final sheetRect = tester.getRect(sheetFinder);
      // Content-sized: height should be strictly less than 86% of screen height (688dp)
      expect(sheetRect.height, lessThan(0.86 * 800));

      // Verify all language options are present and visible within viewport
      expect(find.byKey(const Key('locale_system')), findsOneWidget);
      expect(find.byKey(const Key('locale_traditionalChinese')), findsOneWidget);
      expect(find.byKey(const Key('locale_german')), findsOneWidget);
      expect(find.byKey(const Key('locale_english')), findsOneWidget);
    });

    testWidgets('F07-11: Language picker on expanded (1000x800) opens as Dialog', (tester) async {
      await _pumpConnectScreen(tester, size: const Size(1000, 800));

      await tester.tap(find.byKey(const Key('connect_language_entry')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adaptive-modal-dialog')), findsOneWidget);
      expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('adaptive-modal-dialog')),
          matching: find.text('Language / 語言'),
        ),
        findsOneWidget,
      );
      expect(find.text('繁體中文'), findsOneWidget);
    });

    testWidgets('F07-12: Language picker on vertical hinge LTR is confined to leading region (zero overlap)', (tester) async {
      const hingeFeature = DisplayFeature(
        bounds: Rect.fromLTWH(490, 0, 20, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.postureHalfOpened,
      );

      await _pumpConnectScreen(
        tester,
        size: const Size(1000, 800),
        features: const [hingeFeature],
      );

      await tester.tap(find.byKey(const Key('connect_language_entry')));
      await tester.pumpAndSettle();

      final dialogFinder = find.byKey(const ValueKey('adaptive-modal-dialog'));
      expect(dialogFinder, findsOneWidget);

      final rect = tester.getRect(dialogFinder);
      expect(rect.overlaps(hingeFeature.bounds), isFalse);
      expect(rect.right, lessThanOrEqualTo(490.0));
    });

    testWidgets('F07-13: Selecting language in adaptive modal updates locale preference and rebuilds UI', (tester) async {
      await _pumpConnectScreen(tester, size: const Size(360, 800));

      await tester.tap(find.byKey(const Key('connect_language_entry')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('locale_traditionalChinese')));
      await tester.pumpAndSettle();

      // Verified updated to Traditional Chinese
      expect(find.text('選擇連線方式'), findsOneWidget);
    });
  });
}
