import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/ui/screens/performance/performance_screen.dart';
import 'package:torque_obd/ui/widgets/gauges/dial_gauge.dart';

import 'support/dashboard_harness.dart';
import 'support/localized_app.dart';

class _ConnectedSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState(
    phase: ConnectionPhase.connected,
    kind: TransportKind.demo,
  );
}

void _expectReadout(
  WidgetTester tester,
  Finder gauge,
  String number,
  String units,
) {
  expect(gauge, findsOneWidget);
  expect(
    find.descendant(of: gauge, matching: find.text(number)),
    findsOneWidget,
  );
  final semantics = tester
      .widgetList<Semantics>(
        find.descendant(of: gauge, matching: find.byType(Semantics)),
      )
      .firstWhere((s) => (s.properties.value ?? '').isNotEmpty);
  expect(semantics.properties.value, startsWith('$number $units'));
}

void main() {
  testWidgets('dashboard speed is integral while voltage keeps its decimal', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      activePids: const [
        PidLibrary.vehicleSpeed,
        PidLibrary.controlModuleVoltage,
      ],
      snapshot: TelemetrySnapshot(
        readings: {
          PidLibrary.vehicleSpeed.id: liveReading(PidLibrary.vehicleSpeed, 62),
          PidLibrary.controlModuleVoltage.id: liveReading(
            PidLibrary.controlModuleVoltage,
            12.4,
          ),
        },
      ),
    );

    _expectReadout(
      tester,
      find.byWidgetPredicate((w) => w is DialGauge && w.units == 'km/h'),
      '62',
      'km/h',
    );
    _expectReadout(
      tester,
      find.byWidgetPredicate((w) => w is DialGauge && w.units == 'V'),
      '12.4',
      'V',
    );
    expect(find.text('62.0'), findsNothing);
  });

  testWidgets('dashboard absent speed remains absent', (tester) async {
    await pumpDashboard(
      tester,
      activePids: const [PidLibrary.vehicleSpeed],
      snapshot: const TelemetrySnapshot(),
    );
    final gauge = find.byType(DialGauge);
    expect(tester.widget<DialGauge>(gauge).value, isNull);
    expect(
      find.descendant(of: gauge, matching: find.text('--')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: gauge, matching: find.text('0.0')),
      findsNothing,
    );
  });

  testWidgets('dashboard stale speed keeps its warning and integer readout', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      activePids: const [PidLibrary.vehicleSpeed],
      snapshot: TelemetrySnapshot(
        readings: {
          PidLibrary.vehicleSpeed.id: Reading(
            pid: PidLibrary.vehicleSpeed,
            value: 62,
            rawBytes: const [62],
            timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
          ),
        },
      ),
    );
    final gauge = find.byType(DialGauge);
    expect(tester.widget<DialGauge>(gauge).isStale, isTrue);
    _expectReadout(tester, gauge, '62', 'km/h');
    final l10n = AppLocalizations.of(tester.element(gauge));
    expect(
      find.descendant(
        of: gauge,
        matching: find.textContaining(l10n.datumBadgeStale),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widgetList<Semantics>(
            find.descendant(of: gauge, matching: find.byType(Semantics)),
          )
          .any(
            (s) => (s.properties.value ?? '').contains(
              l10n.gaugeReadingStale('62 km/h'),
            ),
          ),
      isTrue,
    );
  });

  for (final width in [390.0, 1000.0]) {
    testWidgets('performance speed is integral at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final snapshot = TelemetrySnapshot(
        readings: {
          PidLibrary.vehicleSpeed.id: liveReading(PidLibrary.vehicleSpeed, 62),
        },
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            obdSessionProvider.overrideWith(_ConnectedSession.new),
            telemetryProvider.overrideWith((ref) => Stream.value(snapshot)),
          ],
          child: localizedMaterialApp(home: const PerformanceScreen()),
        ),
      );
      await tester.pumpAndSettle();

      _expectReadout(tester, find.byType(DialGauge), '62', 'km/h');
      expect(find.text('62.0'), findsNothing);
      // No run has started; formatting speed must not invent a timer result.
      expect(find.text('--.-'), findsOneWidget);
    });
  }
}
