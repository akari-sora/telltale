/// Issue #109: a clone that answers 0100 on functional addressing, then goes
/// silent once the app installs `ATSH 7E0`.
///
/// Offline replay of one user-exported session (app 1.0.17, Sony XQ-DQ72,
/// ELM327 clone reporting `v1.5` / `ICSolution`, BLE, CAN 11/500, ATDPN=A6).
/// Device identifiers were already redacted in the source transcript.
///
/// This is not real-adapter or on-vehicle evidence. The fixture feeds the
/// byte exchange from that log through a fake transport and asserts the
/// addressing the client settles on.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

import 'support/fake_elm327.dart';

/// Handshake and 0100 bodies taken from the issue #109 transcript.
///
/// Compact, unspaced, ATS0-style, matching the capture. The two 0100 payloads
/// are the engine (`BE3FA813`) and the second controller (`98188011`).
const _searching0100 = 'SEARCHING...\r4100BE3FA813\r410098188011\r\r>';
const _headerless0100 = '4100BE3FA813\r410098188011\r\r>';
const _headered0100 = '7E8064100BE3FA813\r7E906410098188011\r\r>';
const _noData = 'NO DATA\r\r>';
const _ok = 'OK\r\r>';

/// ATPPS body from the same transcript. Programmable-parameter summary only;
/// no device identifier.
const _atpps =
    '00:FF F  01:FF F  02:FF F  03:32 F\r'
    '04:01 F  05:FF F  06:F1 F  07:09 F\r'
    '08:FF F  09:00 F  0A:0A F  0B:FF F\r'
    '0C:68 F  0D:0D F  0E:9A F  0F:FF F\r'
    '10:0D F  11:00 F  12:FF F  13:32 F\r'
    '14:FF F  15:0A F  16:FF F  17:92 F\r'
    '18:00 F  19:28 F  1A:FF F  1B:FF F\r'
    '1C:FF F  1D:FF F  1E:FF F  1F:FF F\r'
    '20:FF F  21:FF F  22:FF F  23:FF F\r'
    '24:00 F  25:00 F  26:00 F  27:FF F\r'
    '28:FF F  29:FF F  2A:38 F  2B:02 F\r'
    '2C:E0 F  2D:04 F  2E:80 F  2F:0A F\r\r>';

/// Live Mode 01 replies the capture never obtained — every PID poll after
/// `ATSH 7E0` was `NO DATA`. These are standard J1979 encodings used only
/// after the client has switched off the silent physical header: 1726 rpm
/// and 60 km/h from the engine, never from a guessed controller.
const _rpm = '410C1AF8\r>';
const _speed = '410D3C\r>';
const _headeredRpm = '7E804410C1AF8\r>';
const _headeredSpeed = '7E803410D3C\r>';

/// Clone that ACKs `ATSH 7E0` and then answers every physically addressed
/// query with `NO DATA`, while the adapter default / `7DF` still works —
/// the addressing behaviour in the issue #109 log.
class _Issue109CloneTransport extends BaseObdTransport {
  _Issue109CloneTransport({
    this.livePidsSilentOnFunctional = false,
    this.secondControllerAnswersRpm = false,
    this.livePidsCanErrorOnFunctional = false,
  });

  /// When true, 7DF / default addressing also returns `NO DATA` for live
  /// PIDs. Handshake `0100` still succeeds so the session can connect.
  final bool livePidsSilentOnFunctional;

  /// When true, a functional `010C` is answered by two controllers with
  /// different values. The client must not pick one.
  final bool secondControllerAnswersRpm;

  /// When true, 7DF answers live PIDs with `CAN ERROR` rather than data.
  /// Handshake `0100` still succeeds so the session can connect.
  final bool livePidsCanErrorOnFunctional;

  final List<String> sent = [];

  bool _echo = true;
  bool _headersOn = false;
  bool _searchPending = true;
  String? _header;

  /// The adapter's default after `ATSP0` is functional `7DF`.
  String get activeHeader => _header ?? '7DF';

  bool get _physical => activeHeader == '7E0';

  @override
  TransportKind get kind => TransportKind.bluetoothLe;

  @override
  String get displayName => 'OBDBLE';

  @override
  Future<void> connect() async => setConnected(true);

  @override
  Future<void> disconnect() async => setConnected(false);

  @override
  Future<void> write(List<int> data) async {
    final raw = ascii.decode(data, allowInvalid: true).trim();
    final key = raw.toUpperCase().replaceAll(' ', '');
    sent.add(key);
    final body = _respond(key);
    final reply = _echo && raw.isNotEmpty ? '$raw\r$body' : body;
    if (key == 'ATE0') _echo = false;
    scheduleMicrotask(() => emitBytes(ascii.encode(reply)));
  }

  String _respond(String command) {
    if (command == 'ATZ' || command == 'ATD') {
      _echo = true;
      _headersOn = false;
      _header = null;
      _searchPending = true;
      return 'ELM327 v1.5\r\r>';
    }
    if (command == 'ATE0' ||
        command == 'ATL0' ||
        command == 'ATM0' ||
        command == 'ATS0' ||
        command == 'ATAT1' ||
        command == 'ATST66') {
      return _ok;
    }
    if (command == 'ATSP0') {
      _searchPending = true;
      _header = null;
      return _ok;
    }
    if (command == 'ATI') return 'ELM327 v1.5\r\r>';
    if (command == 'AT@1') return 'ICSolution\r\r>';
    if (command == 'ATRV') return '15.3V\r\r>';
    if (command == 'ATDP') {
      return _searchPending
          ? 'AUTO\r\r>'
          : 'AUTO, ISO 15765-4 (CAN 11/500)\r\r>';
    }
    if (command == 'ATDPN') return _searchPending ? 'A0\r\r>' : 'A6\r\r>';
    if (command == 'ATPPS') return _atpps;
    if (command == 'ATH1') {
      _headersOn = true;
      return _ok;
    }
    if (command == 'ATH0') {
      _headersOn = false;
      return _ok;
    }
    if (command.startsWith('ATSH')) {
      final value = command.substring(4);
      if (value.length != 3 || !RegExp(r'^[0-9A-F]+$').hasMatch(value)) {
        return '?\r>';
      }
      _header = value;
      return _ok;
    }
    if (command.startsWith('AT')) return '?\r>';

    if (command == '0100') {
      if (_physical) return _noData;
      if (_searchPending) {
        _searchPending = false;
        return _searching0100;
      }
      return _headersOn ? _headered0100 : _headerless0100;
    }

    if (_physical) return _noData;
    if (livePidsSilentOnFunctional) return _noData;
    if (livePidsCanErrorOnFunctional) return 'CAN ERROR\r\r>';

    if (command == '010C') {
      if (secondControllerAnswersRpm && !_headersOn) {
        return '410C1AF8\r410C2EE0\r>';
      }
      if (secondControllerAnswersRpm && _headersOn) {
        return '7E804410C1AF8\r7E904410C2EE0\r>';
      }
      return _headersOn ? _headeredRpm : _rpm;
    }
    if (command == '010D') {
      return _headersOn ? _headeredSpeed : _speed;
    }
    return _noData;
  }
}

Future<Elm327Client> _connect(_Issue109CloneTransport transport) async {
  final client = Elm327Client(
    transport,
    commandTimeout: const Duration(milliseconds: 200),
  );
  expect(
    await client.connect(),
    isTrue,
    reason: 'handshake 0100 on the adapter default must still succeed, as in the log',
  );
  return client;
}

Future<PollingEngine> _pollUntilDecided(
  Elm327Client client, {
  required List<Pid> pids,
}) async {
  final engine = PollingEngine(client)..setActivePids(pids);
  engine.start();
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  bool decided() => pids.every(
    (pid) =>
        engine.current.readings.containsKey(pid.id) ||
        engine.current.faults.containsKey(pid.id),
  );
  while (!decided() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  await engine.stop();
  return engine;
}

void main() {
  group('issue #109 clone: physical 7E0 silent, functional 7DF works', () {
    test(
      'the capture bytes: 7E0 is NO DATA, default and 7DF answer 0100',
      () async {
        final transport = _Issue109CloneTransport();
        await transport.connect();

        Future<String> roundtrip(String command) async {
          final collected = <int>[];
          final sub = transport.incoming.listen(collected.addAll);
          await transport.write(ascii.encode('$command\r'));
          await Future<void>.delayed(Duration.zero);
          await sub.cancel();
          return ascii.decode(collected, allowInvalid: true);
        }

        await roundtrip('ATE0');
        expect(await roundtrip('0100'), _searching0100);
        expect(await roundtrip('ATSH 7E0'), _ok);
        expect(await roundtrip('0100'), _noData);
        expect(await roundtrip('ATH1'), _ok);
        expect(await roundtrip('ATSH 7DF'), _ok);
        expect(await roundtrip('0100'), _headered0100);
        expect(await roundtrip('ATH0'), _ok);
        expect(await roundtrip('ATSH 7E0'), _ok);
        expect(await roundtrip('0100'), _noData);
        await transport.disconnect();
      },
    );

    test(
      'sendOnHeader 7E0 with no fallback stays NO DATA — the pre-fix poll loop',
      () async {
        final transport = _Issue109CloneTransport();
        final client = await _connect(transport);
        final stuck = await client.sendOnHeader('7E0', '010C');
        expect(
          stuck.errorCode,
          Elm327ErrorCode.noData,
          reason:
              'before the recovery, every Mode 01 poll on 7E0 was silence; '
              'this is that loop, not a decoded rpm',
        );
        expect(stuck.isSuccess, isFalse);
        expect(
          transport.sent.where((c) => c == 'ATSH7DF'),
          isEmpty,
          reason: 'sendOnHeader without a fallback must not guess 7DF',
        );
        await client.dispose();
      },
    );

    test(
      'sendOnHeader with a guessed 7E1 fallback is ignored — only 7DF is legal',
      () async {
        final transport = _Issue109CloneTransport();
        final client = await _connect(transport);
        final stuck = await client.sendOnHeader(
          '7E0',
          '010C',
          noDataFallbackHeader: '7E1',
        );
        expect(
          stuck.errorCode,
          Elm327ErrorCode.noData,
          reason: 'a named other controller is not a recovery address',
        );
        expect(
          transport.sent.where((c) => c == 'ATSH7E1' || c == 'ATSH7DF'),
          isEmpty,
          reason:
              'fail-closed: the fallback argument is not an address to try; '
              'it must already be this bus\'s documented functional ID',
        );
        await client.dispose();
      },
    );

    test(
      'after the fix, polling settles on working addressing and decoded PIDs',
      () async {
        final transport = _Issue109CloneTransport();
        final client = await _connect(transport);
        const rpm = PidLibrary.engineRpm;
        const speed = PidLibrary.vehicleSpeed;
        final engine = await _pollUntilDecided(client, pids: [rpm, speed]);

        expect(
          engine.current.readings[rpm.id]?.value,
          closeTo(1726, 1),
          reason:
              'functional 010C is 41 0C 1A F8 = 1726 rpm; a 7E0 loop '
              'would have left this gauge dark',
        );
        expect(
          engine.current.readings[speed.id]?.value,
          closeTo(60, 0.001),
          reason: 'functional 010D is 41 0D 3C = 60 km/h',
        );

        final log = transport.sent;
        expect(
          log,
          contains('ATSH7E0'),
          reason:
              'physical engine addressing is still tried; it is not a guess',
        );
        expect(
          log,
          contains('ATSH7DF'),
          reason:
              'once 7E0 is silent, the documented functional header is used',
        );

        final lastPhysical = log.lastIndexOf('ATSH7E0');
        final lastRpm = log.lastIndexWhere((c) => c == '010C' || c == '010D');
        expect(lastRpm, greaterThan(lastPhysical));
        expect(
          log.sublist(lastPhysical, lastRpm + 1),
          contains('ATSH7DF'),
          reason:
              'the app must not keep polling on 7E0 after that header '
              'produced NO DATA while 7DF worked',
        );

        await engine.dispose();
        await client.dispose();
      },
    );

    test(
      '7E0 and 7DF both NO DATA for live PIDs must not invent a reading',
      () async {
        final transport = _Issue109CloneTransport(
          livePidsSilentOnFunctional: true,
        );
        final client = await _connect(transport);
        const rpm = PidLibrary.engineRpm;
        final engine = await _pollUntilDecided(client, pids: [rpm]);

        expect(
          engine.current.readings[rpm.id],
          isNull,
          reason: 'silence on both addressing modes is not a value',
        );
        expect(
          engine.current.faults[rpm.id],
          isNotNull,
          reason: 'the gauge must show a fault, not a fabricated rpm',
        );

        await engine.dispose();
        await client.dispose();
      },
    );

    test('two different functional 010C replies are not attributed at random', () async {
      final transport = _Issue109CloneTransport(
        secondControllerAnswersRpm: true,
      );
      final client = await _connect(transport);
      const rpm = PidLibrary.engineRpm;
      final engine = await _pollUntilDecided(client, pids: [rpm]);

      expect(
        engine.current.readings[rpm.id],
        isNull,
        reason:
            '1726 rpm is not more true than 3000 rpm for having printed first',
      );

      await engine.dispose();
      await client.dispose();
    });

    test(
      'CAN ERROR on 7DF is not a vehicle reply and must not skip 7E0 later',
      () async {
        final transport = _Issue109CloneTransport(
          livePidsCanErrorOnFunctional: true,
        );
        final client = await _connect(transport);
        final first = await client.sendAddressed('7E0', '010C');
        expect(first.errorCode, Elm327ErrorCode.canError);
        expect(transport.sent, contains('ATSH7E0'));
        expect(transport.sent, contains('ATSH7DF'));

        final before = transport.sent.length;
        await client.sendAddressed('7E0', '010C');
        expect(
          transport.sent.skip(before),
          contains('ATSH7E0'),
          reason:
              'an adapter error on the functional ID is not proof that 7E0 '
              'is silent; the next engine poll must still try it',
        );
        await client.dispose();
      },
    );

    test('reconnect forgets the functional preference', () async {
      final transport = _Issue109CloneTransport();
      final client = await _connect(transport);
      final recovered = await client.sendAddressed('7E0', '010C');
      expect(recovered.isSuccess, isTrue);
      expect(transport.sent, contains('ATSH7DF'));

      await client.disconnect();
      expect(
        await client.connect(),
        isTrue,
        reason: 'the same client object is what reconnect uses in tests',
      );
      final before = transport.sent.length;
      await client.sendAddressed('7E0', '010C');
      expect(
        transport.sent.skip(before),
        contains('ATSH7E0'),
        reason:
            'a new connection must not inherit the previous session\'s '
            'conclusion that 7E0 is silent',
      );
      await client.dispose();
    });
  });

  group('physical engine addressing still used when it actually answers', () {
    test('a working 7E0 adapter is not forced onto 7DF', () async {
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: {
              '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
              '010C': [0x41, 0x0C, 0x1A, 0xF8],
            },
          ),
        ],
      );
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 200),
      );
      expect(await client.connect(), isTrue);
      final response = await client.sendAddressed('7E0', '010C');
      expect(response.isSuccess, isTrue);
      expect(response.bytes, [0x41, 0x0C, 0x1A, 0xF8]);
      expect(
        transport.commandLog.where((c) => c == 'ATSH7DF'),
        isEmpty,
        reason: 'falling back when 7E0 worked would broadcast a unicast query',
      );
      expect(transport.commandLog, contains('ATSH7E0'));
      await client.dispose();
    });
  });

  group('custom headers are not recovered via 7DF', () {
    test('a silent 7E1 PID is not retried on the functional ID', () async {
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: {
              '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
              '010C': [0x41, 0x0C, 0x1A, 0xF8],
            },
          ),
        ],
      );
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 200),
      );
      expect(await client.connect(), isTrue);
      final response = await client.sendAddressed('7E1', '010C');
      expect(
        response.errorCode,
        Elm327ErrorCode.noData,
        reason: 'no TCM is present; silence is the answer, not a 7DF guess',
      );
      expect(
        transport.commandLog.where((c) => c == 'ATSH7DF'),
        isEmpty,
        reason: '7E1 names a controller; broadcasting would misattribute',
      );
      expect(transport.commandLog, contains('ATSH7E1'));
      await client.dispose();
    });
  });

  group('header refusal is unchanged', () {
    test(
      'ATSH 7E0 answered ? is still queryHeaderRefused, not a 7DF guess',
      () async {
        final transport = FakeElm327(
          protocol: BusProtocol.can11,
          faults: const AdapterFaults(refuseHeaderSwitch: true),
          ecus: [
            FakeEcu(
              name: 'ECM',
              requestId: '7E0',
              responseId: '7E8',
              responses: {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
                '010C': [0x41, 0x0C, 0x1A, 0xF8],
              },
            ),
          ],
        );
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 200),
        );
        expect(await client.connect(), isTrue);
        await expectLater(
          client.sendAddressed('7E0', '010C'),
          throwsA(
            isA<TransportException>().having(
              (e) => e.issue,
              'issue',
              TransportIssue.queryHeaderRefused,
            ),
          ),
        );
        expect(
          transport.commandLog.where((c) => c == 'ATSH7DF'),
          isEmpty,
          reason: 'a refused physical header is not recovered by guessing 7DF',
        );
        await client.dispose();
      },
    );
  });
}
