import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/ui/screens/dashboard/dashboard_screen.dart';
import 'package:torque_obd/ui/widgets/gauges/dial_gauge.dart';

import '../support/localized_app.dart';

class _ConnectedSession extends ObdSession {
  @override
  ObdConnectionState build() => const ObdConnectionState(
    phase: ConnectionPhase.connected,
    kind: TransportKind.bluetoothClassic,
  );
}

class _ActivePid extends ActivePids {
  @override
  List<Pid> build() => [PidLibrary.engineRpm];
}

void main() {
  final explanations = {
    const Locale('en'): 'Unverified means no real-vehicle comparison for this decoder on your vehicle is documented here. It does not mean the reading is wrong, and it does not certify its accuracy. Freshness and faults are shown separately.',
    const Locale('de'): 'Unverifiziert bedeutet, dass hier kein Abgleich dieser Dekodierung mit Ihrem Fahrzeug dokumentiert ist. Das bedeutet weder, dass der Messwert falsch ist, noch bestätigt es seine Genauigkeit. Aktualität und Fehler werden separat angezeigt.',
    const Locale('zh'):
        '未驗證表示此處沒有這個解碼與本車實際比對的驗證紀錄，不代表讀值錯誤，也不保證讀值準確。更新狀態與異常會另外標示。',
    const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'):
        '未驗證表示此處沒有這個解碼與本車實際比對的驗證紀錄，不代表讀值錯誤，也不保證讀值準確。更新狀態與異常會另外標示。',
  };
  for (final entry in explanations.entries) {
    for (final state in ['fresh', 'stale', 'missing']) {
      testWidgets('${entry.key} $state gauge badge opens evidence details', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        const pid = PidLibrary.engineRpm;
        final now = DateTime.now();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(preferences),
              obdSessionProvider.overrideWith(_ConnectedSession.new),
              activePidsProvider.overrideWith(_ActivePid.new),
              telemetryProvider.overrideWith(
                (ref) => Stream.value(
                  TelemetrySnapshot(
                    readings: {
                      if (state != 'missing')
                        pid.id: Reading(
                          pid: pid,
                          value: 1234,
                          rawBytes: const [0x13, 0x48],
                          timestamp: state == 'stale'
                              ? now.subtract(const Duration(minutes: 1))
                              : now,
                        ),
                    },
                    capturedAt: now,
                  ),
                ),
              ),
            ],
            child: localizedMaterialApp(
              locale: entry.key,
              home: const DashboardScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
        final tile = find.byKey(ValueKey('dashboard-gauge-${pid.id}'));
        await tester.scrollUntilVisible(
          tile,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump(const Duration(milliseconds: 400));
        final gauge = tester.widget<DialGauge>(find.byType(DialGauge));
        expect(gauge.value, state == 'missing' ? isNull : 1234);
        expect(gauge.isStale, state != 'fresh');
        await tester.ensureVisible(tile);
        await tester.pump(const Duration(milliseconds: 400));
        // Tap the badge itself, rather than invoking a callback directly.
        await tester.tap(
          find.descendant(of: tile, matching: find.text(gauge.footnote!)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text(entry.value), findsOneWidget);
        expect(
          find.descendant(of: tile, matching: find.byIcon(Icons.info_outline)),
          findsOneWidget,
        );
        final dialog = find.byType(AlertDialog);
        final badgeText = tester
            .widgetList<Text>(
              find.descendant(of: dialog, matching: find.byType(Text)),
            )
            .map((text) => text.data ?? '')
            .join(' ');
        expect(badgeText, isNot(contains('Field-verified')));
        expect(badgeText, isNot(contains('已驗證')));
        if (state == 'stale') {
          expect(
            badgeText,
            contains(switch (entry.key.languageCode) {
              'en' => 'Stale',
              'de' => 'Veraltet',
              _ => '過期',
            }),
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
