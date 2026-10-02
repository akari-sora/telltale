import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/pid/priority_tier.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/ui/screens/pids/pid_detail_pane.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark(),
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('PidDetailPlaceholder', () {
    testWidgets('renders empty state icon and localized text', (tester) async {
      await tester.pumpWidget(_wrap(const PidDetailPlaceholder()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.text('Select a PID'), findsOneWidget);
      expect(
        find.text(
          'Choose a PID from the list to inspect its definition and live status.',
        ),
        findsOneWidget,
      );
    });
  });

  group('PidDetailPane', () {
    testWidgets('renders built-in PID details and handles toggle', (tester) async {
      bool toggled = false;
      const pid = PidLibrary.engineRpm;

      await tester.pumpWidget(
        _wrap(
          PidDetailPane(
            pid: pid,
            isActive: false,
            reading: Reading(
              pid: pid,
              value: 3245.0,
              rawBytes: const [0x0C, 0xAA],
              timestamp: DateTime.now(),
            ),
            isStale: false,
            isUnsupported: false,
            onToggle: () async {
              toggled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(pid.name), findsOneWidget);
      expect(find.text('3245'), findsOneWidget);
      expect(find.text(pid.modeAndPid), findsOneWidget);
      expect(find.text(pid.equation), findsOneWidget);
      expect(find.text('Range'), findsOneWidget);
      expect(find.text('${pid.minValue} — ${pid.maxValue}'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('Default (7E0)'), findsOneWidget);

      // Verify switch exists and toggling works
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pump();
      expect(toggled, isTrue);
    });

    testWidgets('renders stale reading with stale label', (tester) async {
      const pid = PidLibrary.vehicleSpeed;

      await tester.pumpWidget(
        _wrap(
          PidDetailPane(
            pid: pid,
            isActive: true,
            reading: Reading(
              pid: pid,
              value: 65.0,
              rawBytes: const [0x41],
              timestamp: DateTime.now(),
            ),
            isStale: true,
            isUnsupported: false,
            onToggle: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('65.0'), findsOneWidget);
      expect(find.text('${pid.units} · stale'), findsOneWidget);
    });

    testWidgets('renders custom PID with pill and invokes edit callback', (tester) async {
      bool editCalled = false;
      const customPid = Pid(
        name: 'Oil Pressure Gauge',
        shortName: 'Oil P',
        modeAndPid: '221122',
        equation: 'A*2',
        minValue: 0,
        maxValue: 100,
        units: 'psi',
        header: '7E0',
        priority: PriorityTier.high,
        isCustom: true,
      );

      await tester.pumpWidget(
        _wrap(
          PidDetailPane(
            pid: customPid,
            isActive: true,
            reading: null,
            isStale: false,
            isUnsupported: false,
            onToggle: () async {},
            onEdit: () {
              editCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('—'), findsWidgets); // null reading placeholder

      final editButton = find.widgetWithText(FilledButton, 'Edit');
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pump();
      expect(editCalled, isTrue);
    });

    testWidgets('renders unsupported badge when vehicle disclaimed PID', (tester) async {
      const pid = PidLibrary.intakeAirTemp;

      await tester.pumpWidget(
        _wrap(
          PidDetailPane(
            pid: pid,
            isActive: false,
            reading: null,
            isStale: false,
            isUnsupported: true,
            onToggle: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unsupported'), findsOneWidget);
    });
  });
}
