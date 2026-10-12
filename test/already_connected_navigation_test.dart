/// Navigation coverage for sessions established before the phone wizard.
///
/// Android Auto can create and connect the shared OBD session before
/// MainActivity exists. These tests keep that ordering separate from the
/// phone-initiated connect tests, whose successful `connect*()` future already
/// performs the navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/app_runtime.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/ui/screens/connect/connect_screen.dart';
import 'package:torque_obd/ui/screens/dashboard/dashboard_screen.dart';

import 'support/localized_app.dart';

final class _ControllableSession extends ObdSession {
  _ControllableSession(this.initial);

  final ObdConnectionState initial;

  @override
  ObdConnectionState build() => initial;

  void publish(ObdConnectionState next) => state = next;
}

ObdConnectionState _connectedState({String detail = ''}) => ObdConnectionState(
  phase: ConnectionPhase.connected,
  kind: TransportKind.wifi,
  deviceName: 'Android Auto ELM327',
  protocol: 'ISO 15765-4 CAN',
  detail: detail,
  initSteps: List.generate(
    14,
    (index) => InitProgress(
      step: InitStep('AT$index'),
      index: index,
      total: 14,
      status: InitStatus.ok,
    ),
  ),
);

const _disconnectedState = ObdConnectionState(
  phase: ConnectionPhase.disconnected,
);

Future<
  ({
    _ControllableSession session,
    GoRouter router,
    int Function() dashboardBuilds,
    int Function() dashboardRedirects,
  })
>
_pumpApp(WidgetTester tester, {required ObdConnectionState initial}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  late _ControllableSession session;
  var dashboardBuilds = 0;
  var dashboardRedirects = 0;
  final router = GoRouter(
    routes: [
      GoRoute(
        path: ConnectScreen.path,
        builder: (_, _) => const ConnectScreen(),
      ),
      GoRoute(
        path: DashboardScreen.path,
        redirect: (_, _) {
          dashboardRedirects += 1;
          return null;
        },
        builder: (_, _) {
          dashboardBuilds += 1;
          return const Scaffold(body: Text('dashboard reached'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appSharePolicyProvider.overrideWith(
          (ref) => ref.watch(productionAppSharePolicyProvider),
        ),
        obdSessionProvider.overrideWith(
          () => session = _ControllableSession(initial),
        ),
      ],
      child: localizedMaterialAppRouter(routerConfig: router),
    ),
  );

  return (
    session: session,
    router: router,
    dashboardBuilds: () => dashboardBuilds,
    dashboardRedirects: () => dashboardRedirects,
  );
}

void main() {
  testWidgets('AA-first connected session opens dashboard on first frame', (
    tester,
  ) async {
    final harness = await _pumpApp(tester, initial: _connectedState());

    await tester.pumpAndSettle();

    expect(find.text('dashboard reached'), findsOneWidget);
    expect(
      harness.router.routeInformationProvider.value.uri.path,
      '/dashboard',
    );
    expect(harness.dashboardBuilds(), 1);
  });

  testWidgets('connection established after wizard opens navigates dashboard', (
    tester,
  ) async {
    final harness = await _pumpApp(tester, initial: _disconnectedState);
    await tester.pumpAndSettle();
    expect(find.byType(ConnectScreen), findsOneWidget);

    harness.session.publish(_connectedState());
    await tester.pumpAndSettle();

    expect(find.text('dashboard reached'), findsOneWidget);
    expect(harness.dashboardBuilds(), 1);
  });

  testWidgets('unmounted wizard ignores a queued connected navigation', (
    tester,
  ) async {
    final harness = await _pumpApp(tester, initial: _disconnectedState);
    await tester.pumpAndSettle();

    harness.session.publish(_connectedState());
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(harness.dashboardBuilds(), 0);
  });

  testWidgets(
    'same-frame connected updates schedule one dashboard navigation',
    (tester) async {
      final harness = await _pumpApp(tester, initial: _disconnectedState);
      await tester.pumpAndSettle();

      harness.session.publish(_connectedState(detail: 'first notification'));
      harness.session.publish(_connectedState(detail: 'second notification'));
      await tester.pumpAndSettle();

      expect(find.text('dashboard reached'), findsOneWidget);
      expect(harness.dashboardBuilds(), 1);
      expect(harness.dashboardRedirects(), 1);
    },
  );

  testWidgets('disconnected state before the queued frame cancels navigation', (
    tester,
  ) async {
    final harness = await _pumpApp(tester, initial: _disconnectedState);
    await tester.pumpAndSettle();

    harness.session.publish(_connectedState());
    harness.session.publish(_disconnectedState);
    await tester.pump();

    expect(find.byType(ConnectScreen), findsOneWidget);
    expect(harness.dashboardBuilds(), 0);
  });
}
