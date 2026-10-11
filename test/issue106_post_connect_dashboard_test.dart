/// Issue #106 follow-up: handshake succeeds, then the dashboard is empty
/// and the session dies.
///
/// v1.0.16 (MR !88) lets a slow `0100` finish the handshake. After that the
/// reporter's cheap ELM327 clone still showed `-- V`, inactive gauges, the
/// stopped-vehicle history gate, and dropped back to Choose a connection
/// about a second later.
///
/// These tests are synthetic. They do not claim the reporter's car or
/// adapter was on the other end of the fixture.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/telemetry_demand.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';

import 'support/fake_elm327.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

FakeEcu _dashboardEcu() => FakeEcu(
  name: 'ECM',
  requestId: '7E0',
  responseId: '7E8',
  responses: {
    '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
    '0120': [0x41, 0x20, 0x80, 0x00, 0x00, 0x01],
    '010C': [0x41, 0x0C, 0x1A, 0xF8],
    '010D': [0x41, 0x0D, 0x00],
    '0105': [0x41, 0x05, 0x7B],
    '0104': [0x41, 0x04, 0x7F],
    '0111': [0x41, 0x11, 0x80],
    '010F': [0x41, 0x0F, 0x4E],
    '010B': [0x41, 0x0B, 0x1E],
    '0110': [0x41, 0x10, 0x12, 0x34],
    '015E': [0x41, 0x5E, 0x00, 0x80],
  },
);

FakeElm327 _adapter({AdapterFaults faults = const AdapterFaults()}) =>
    FakeElm327(
      protocol: BusProtocol.can11,
      faults: faults,
      ecus: [_dashboardEcu()],
    );

String _norm(String command) => command.toUpperCase().replaceAll(' ', '');

bool _isCensus0100(List<String> log) {
  for (final command in log.reversed) {
    final normalised = _norm(command);
    if (normalised == '0100') continue;
    if (normalised == 'ATH1' || normalised == 'ATSH7DF') return true;
    if (normalised.startsWith('AT')) return false;
  }
  return false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // ObdSession samples the binding once at build. A non-resumed harness
    // leaves shouldContinue false, so discovery exits before 0120 and the
    // clone-teardown case cannot fail on the old connect path.
    TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
  });

  test('connect publishes handshake voltage before any poll cycle', () async {
    final container = await _container();
    addTearDown(container.dispose);
    final session = container.read(obdSessionProvider.notifier);
    final adapter = _adapter(faults: const AdapterFaults(voltageText: '14.3V'));

    final snapshots = <TelemetrySnapshot>[];
    final sub = container.listen(telemetryProvider, (_, next) {
      final value = next.value;
      if (value != null) snapshots.add(value);
    }, fireImmediately: true);
    addTearDown(sub.close);

    expect(await session.connectForTest(adapter, TransportKind.wifi), isTrue);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(obdSessionProvider).phase, ConnectionPhase.connected);
    expect(
      container.read(obdSessionProvider).batteryVoltage,
      closeTo(14.3, 0.001),
    );
    expect(
      snapshots.where((s) => s.batteryVoltage != null),
      isNotEmpty,
      reason:
          'the shell already owns telemetryProvider, so a connect that '
          'never publishes engine.current leaves the dashboard on -- V',
    );
    expect(
      snapshots.firstWhere((s) => s.batteryVoltage != null).batteryVoltage,
      closeTo(14.3, 0.001),
    );
    expect(
      snapshots.firstWhere((s) => s.batteryVoltage != null).readings,
      isEmpty,
      reason: 'handshake voltage must not wait for the first PID poll',
    );

    await session.disconnect();
  });

  test(
    'connect syncs default dashboard PIDs including speed before census',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      final holdCensus = Completer<void>();
      addTearDown(() {
        if (!holdCensus.isCompleted) holdCensus.complete();
      });

      final adapter = _adapter();
      final log = <String>[];
      adapter.onCommandWritten = log.add;
      adapter.responseBarrier = (command) {
        if (_norm(command) == '0100' && _isCensus0100(log)) {
          return holdCensus.future;
        }
        return null;
      };

      expect(await session.connectForTest(adapter, TransportKind.wifi), isTrue);

      final engine = session.engine;
      expect(engine, isNotNull);
      final dashboardModeAndPid = {
        for (final demand in engine!.demands.leases)
          if (demand.owner == DemandOwner.dashboard) demand.modeAndPid,
      };
      expect(
        dashboardModeAndPid,
        containsAll([
          PidLibrary.engineRpm.modeAndPid,
          PidLibrary.vehicleSpeed.modeAndPid,
          PidLibrary.coolantTemp.modeAndPid,
        ]),
        reason:
            'activePidsProvider is already populated before connect, so the '
            'listen does not fire; census used to be the first sync',
      );
      expect(
        engine.capabilitySummary.phase,
        isNot(ObdCapabilityDiscoveryPhase.running),
        reason: 'PID support discovery must not start beside the census',
      );
      expect(
        log.where((c) => _norm(c) == '0120'),
        isEmpty,
        reason: 'support-block 0120 is discovery, not the responder census',
      );

      holdCensus.complete();
      await session.disconnect();
    },
  );

  test(
    'a clone that dies on physically addressed 0100 stays up through census',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      final holdCensus = Completer<void>();
      addTearDown(() {
        if (!holdCensus.isCompleted) holdCensus.complete();
      });

      final adapter = _adapter(
        faults: const AdapterFaults(voltageText: '14.5V'),
      );
      final log = <String>[];
      var discovery0100 = 0;
      var lethalPhysical0100 = true;
      adapter.onCommandWritten = (command) {
        log.add(command);
        if (_norm(command) == '0100' &&
            log.length >= 2 &&
            _norm(log[log.length - 2]) == 'ATSH7E0') {
          discovery0100++;
          if (lethalPhysical0100) {
            adapter.forceReply('0100', 'UNABLE TO CONNECT');
          }
        }
      };
      adapter.responseBarrier = (command) {
        if (_norm(command) == '0100' && _isCensus0100(log)) {
          return holdCensus.future;
        }
        return null;
      };

      expect(await session.connectForTest(adapter, TransportKind.wifi), isTrue);

      final deadline = DateTime.now().add(const Duration(milliseconds: 400));
      while (DateTime.now().isBefore(deadline) &&
          container.read(obdSessionProvider).isConnected) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      expect(
        container.read(obdSessionProvider).phase,
        ConnectionPhase.connected,
        reason:
            'eager discoverSupportedPids sends ATSH 7E0 then 0100 on the same '
            'cheap adapter as the census; UNABLE TO CONNECT tears the session down',
      );
      expect(session.engine, isNotNull);
      expect(session.engine!.current.batteryVoltage, closeTo(14.5, 0.001));
      expect(
        discovery0100,
        0,
        reason: 'PID support discovery must not share the bus with the census',
      );

      // A physically addressed 0100 is still how support discovery talks
      // once the census has left. The lethal reply modelled the race, not
      // a clone that can never answer ATSH 7E0.
      lethalPhysical0100 = false;
      holdCensus.complete();
      final afterCensus = DateTime.now().add(const Duration(seconds: 2));
      while (DateTime.now().isBefore(afterCensus) &&
          discovery0100 == 0 &&
          container.read(obdSessionProvider).isConnected) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(
        container.read(obdSessionProvider).phase,
        ConnectionPhase.connected,
        reason:
            'support discovery must still run after census, and a clone that '
            'answers the physically addressed 0100 must not be torn down',
      );
      expect(
        discovery0100,
        greaterThan(0),
        reason: 'census remaining does not mean support discovery is dropped',
      );

      await session.disconnect();
    },
  );

  test('pausing the poller does not drop the in-flight PID from the schedule', () async {
    final adapter = _adapter();
    adapter.slowCommands['010C'] = const Duration(milliseconds: 350);
    final client = Elm327Client(
      adapter,
      commandTimeout: const Duration(seconds: 2),
    );
    addTearDown(client.dispose);
    expect(await client.connect(), isTrue);

    final engine = PollingEngine(client);
    addTearDown(engine.dispose);
    engine.setActivePids([
      PidLibrary.engineRpm,
      PidLibrary.vehicleSpeed,
      PidLibrary.engineLoad,
    ]);
    engine.start();

    final deadline = DateTime.now().add(const Duration(milliseconds: 200));
    while (DateTime.now().isBefore(deadline) &&
        !adapter.commandLog.any((c) => _norm(c) == '010C')) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(
      adapter.commandLog.where((c) => _norm(c) == '010C'),
      isNotEmpty,
      reason: 'RPM must have been the in-flight poll',
    );

    await engine.stop();
    final afterStop = adapter.commandLog.length;
    engine.start();
    final restartDeadline = DateTime.now().add(
      const Duration(milliseconds: 400),
    );
    while (DateTime.now().isBefore(restartDeadline) &&
        !adapter.commandLog
            .skip(afterStop)
            .any((c) => _norm(c).startsWith('01'))) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final firstMode01AfterRestart = adapter.commandLog
        .skip(afterStop)
        .map(_norm)
        .firstWhere((c) => c.startsWith('01'), orElse: () => '');
    expect(
      firstMode01AfterRestart,
      '010C',
      reason:
          'stop() used to leave the rest of the queue in place, so the '
          'next start sent leftover 010D/0104 and skipped the interrupted 010C',
    );
  });
}
