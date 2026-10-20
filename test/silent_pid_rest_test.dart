/// A PID the adapter swallows every time, after #112.
///
/// Before #112 a silent reply dropped the session, so a PID that was always
/// swallowed ended it too. Now the adapter is probed and the session lives,
/// which means such a PID would cost a command timeout plus a probe on every
/// cycle, forever. Two timeouts in a row rest it the way `NO DATA` does. One
/// alone does not: the #112 exports lost a random reply every 40-140 s, and
/// that must not grey a working gauge.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/telemetry.dart';

import 'support/fake_elm327.dart';

FakeElm327 _adapter() => FakeElm327(
  protocol: BusProtocol.can11,
  identity: 'ELM327 v1.5',
  deviceDescription: 'ICSolution',
  ecus: [
    FakeEcu(
      name: 'ECM',
      requestId: '7E0',
      responseId: '7E8',
      responses: {
        '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
        '010C': [0x41, 0x0C, 0x1A, 0xF8],
        '010D': [0x41, 0x0D, 0x3C],
      },
    ),
  ],
);

Future<(PollingEngine, FakeElm327, List<int>)> _polling() async {
  final transport = _adapter();
  final lost = <int>[];
  final client = Elm327Client(
    transport,
    commandTimeout: const Duration(milliseconds: 200),
  )..onConnectionLost = () => lost.add(1);
  addTearDown(client.dispose);
  expect(await client.connect(), isTrue);
  final engine = PollingEngine(client)
    ..recheckInterval = const Duration(minutes: 5)
    ..setActivePids(
      const [PidLibrary.engineRpm, PidLibrary.vehicleSpeed],
      includeProfileDerivedInputs: false,
    );
  addTearDown(engine.dispose);
  return (engine, transport, lost);
}

Future<void> _until(bool Function() done, Duration limit) async {
  final deadline = DateTime.now().add(limit);
  while (!done() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  test('a PID swallowed twice in a row rests and the session lives', () async {
    final (engine, transport, lost) = await _polling();
    transport.silenceFor.add('010D');
    engine.start();

    await _until(
      () =>
          engine.current.faults[PidLibrary.vehicleSpeed.id] ==
          PidFault.noAnswer,
      const Duration(seconds: 8),
    );
    final restedAt = transport.commandLog.length;
    // The rest holds: no more speed reads, rpm keeps coming.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await engine.stop();

    expect(
      engine.current.faults[PidLibrary.vehicleSpeed.id],
      PidFault.noAnswer,
    );
    expect(transport.commandLog.where((c) => c == '010D').length, 2);
    expect(
      transport.commandLog.skip(restedAt).where((c) => c == '010C'),
      isNotEmpty,
    );
    expect(lost, isEmpty);
  });

  test('one swallowed reply does not rest a working PID', () async {
    final (engine, transport, lost) = await _polling();
    var speedReads = 0;
    transport.onCommandWritten = (command) {
      if (command != '010D') return;
      speedReads++;
      // Silent the first time only, as in the #112 exports.
      if (speedReads == 1) {
        transport.silenceFor.add('010D');
      } else {
        transport.silenceFor.remove('010D');
      }
    };
    engine.start();

    await _until(() => speedReads >= 4, const Duration(seconds: 8));
    await engine.stop();

    expect(speedReads, greaterThanOrEqualTo(4));
    expect(
      engine.current.faults[PidLibrary.vehicleSpeed.id],
      isNot(PidFault.noAnswer),
    );
    expect(lost, isEmpty);
  });
}
