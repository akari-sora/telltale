/// Issue #117: a 2022 Hyundai IONIQ 5 has no `7E8`. Four other modules answer
/// the functional `0100`, and each one's support mask describes only itself.
///
/// Offline replay of the reporter's exported session (app 1.0.25 (2082),
/// Samsung SM-S9480, Bluetooth Classic `OBDBLE`, adapter `ELM327 v1.5` /
/// `ICSolution`, ISO 15765-4 CAN 11/500, ATDPN `A6`). The masked copy of that
/// export is in the #117 internal note; line numbers below are lines of that
/// export.
///
/// Mode 01 replies are verbatim from the export:
///
///   * line 81: first `0100` on the adapter default, headers off
///   * line 131: `0100` on `7DF` with headers on (`7EC`, `7EE`, `7EA`, `7EB`)
///   * line 217: `0120` on `7DF` (`7EC`, `7EB`)
///   * line 285: `0140` on `7DF` (`7EC`)
///   * line 621: `0160` on `7DF` (`7EC`)
///   * line 1505: `0121` on `7DF` (`7EC`, `7EB`, `7ED`)
///   * every physical `7E0` request: `NO DATA`
///   * the 22 Mode 01 PIDs the app polled: `NO DATA` on `7E0` and on `7DF`
///
/// The headerless forms of the `0120`–`0160` and `0121` replies, and every AT
/// reply except `ATDP`, `ATDPN`, `ATI`, `AT@1` and `ATRV`, are not in the
/// export; they follow the same adapter's documented behaviour. The `ATPPS`
/// body is the same clone's, as recorded for issue #109.
///
/// This is not real-adapter or on-vehicle evidence of the fix.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

const _noData = 'NO DATA\r\r>';
const _ok = 'OK\r\r>';

const _searching0100 =
    'SEARCHING...\r410080000001\r410080000000\r410080000001\r410000000000\r\r>';
const _headerless0100 =
    '410080000001\r410080000000\r410080000001\r410000000000\r\r>';
const _headered0100 =
    '7EC06410080000001\r7EE06410080000000\r7EA06410000000000\r'
    '7EB06410080000001\r\r>';
const _headered0120 = '7EC06412080018001\r7EB06412080018000\r\r>';
const _headered0120WithoutMcu = '7EC06412080018001\r\r>';
const _headerless0120 = '412080018001\r412080018000\r\r>';
const _headered0140 = '7EC06414000000021\r\r>';
const _headerless0140 = '414000000021\r\r>';
const _headered0160 = '7EC06416000000001\r\r>';
const _headerless0160 = '416000000001\r\r>';
const _headered0121 = '7EC0441210000\r7EB0441210000\r7ED0441210000\r\r>';
const _headerless0121 = '41210000\r41210000\r41210000\r\r>';

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

/// The 22 Mode 01 PIDs the export shows the app polling, every one of them
/// `NO DATA` from every controller.
const _polledInExport = {
  '0104',
  '0105',
  '0106',
  '0107',
  '010A',
  '010B',
  '010C',
  '010D',
  '010E',
  '010F',
  '0110',
  '0111',
  '011F',
  '012C',
  '012F',
  '0133',
  '0142',
  '0143',
  '0145',
  '0146',
  '015C',
  '015E',
};

/// The adapter from the #117 export: physical `7E0` is never answered, the
/// functional `7DF` reaches four modules, none of them `7E8`.
class _Ioniq5Transport extends BaseObdTransport {
  _Ioniq5Transport({this.mcuMissesFunctional0120 = false});

  /// When true, `7EB` does not answer the functional `0120` although its
  /// `0100` mask says the block exists. Not in the export; used to show that
  /// an unaccounted claimer leaves the block undecided.
  final bool mcuMissesFunctional0120;

  final List<String> sent = [];

  bool _echo = true;
  bool _headersOn = false;
  bool _searchPending = true;
  String? _header;

  String get activeHeader => _header ?? '7DF';

  bool get _physical => activeHeader == '7E0';

  @override
  TransportKind get kind => TransportKind.bluetoothClassic;

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
    if (const {
      'ATE0',
      'ATL0',
      'ATM0',
      'ATS0',
      'ATAT1',
      'ATST66',
    }.contains(command)) {
      return _ok;
    }
    if (command == 'ATSP0') {
      _searchPending = true;
      _header = null;
      return _ok;
    }
    if (command == 'ATI') return 'ELM327 v1.5\r\r>';
    if (command == 'AT@1') return 'ICSolution\r\r>';
    if (command == 'ATRV') return '13.9V\r\r>';
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

    if (_physical) return _noData;
    switch (command) {
      case '0100':
        if (_searchPending) {
          _searchPending = false;
          return _searching0100;
        }
        return _headersOn ? _headered0100 : _headerless0100;
      case '0120':
        if (mcuMissesFunctional0120) {
          return _headersOn ? _headered0120WithoutMcu : '412080018001\r\r>';
        }
        return _headersOn ? _headered0120 : _headerless0120;
      case '0140':
        return _headersOn ? _headered0140 : _headerless0140;
      case '0160':
        return _headersOn ? _headered0160 : _headerless0160;
      case '0121':
        return _headersOn ? _headered0121 : _headerless0121;
    }
    return _noData;
  }
}

Future<Elm327Client> _connect(_Ioniq5Transport transport) async {
  final client = Elm327Client(
    transport,
    commandTimeout: const Duration(milliseconds: 200),
  );
  expect(await client.connect(), isTrue);
  return client;
}

Future<PollingEngine> _discovered(
  _Ioniq5Transport transport, {
  bool census = true,
}) async {
  final client = await _connect(transport);
  final engine = PollingEngine(client);
  addTearDown(engine.dispose);
  if (census) await engine.discoverResponders();
  await engine.discoverSupportedPids();
  return engine;
}

Iterable<Pid> get _exportPolledPids => PidLibrary.all.where(
  (pid) => _polledInExport.contains(pid.modeAndPid.toUpperCase()),
);

void main() {
  group('issue #117 IONIQ 5: no 7E8, four other Mode 01 responders', () {
    test('the census finds the four modules from the export', () async {
      final engine = await _discovered(_Ioniq5Transport());
      expect(engine.responders, {'7EA', '7EB', '7EC', '7EE'});
    });

    test(
      'a PID no responder claims is known unsupported in every block',
      () async {
        final engine = await _discovered(_Ioniq5Transport());
        final pids = _exportPolledPids.toList();
        expect(pids, isNotEmpty);
        for (final pid in pids) {
          expect(
            engine.isKnownUnsupported(pid),
            isTrue,
            reason: '${pid.modeAndPid}: no mask from 7EA/7EB/7EC/7EE claims it',
          );
        }
      },
    );

    test('a PID another module claims is not called unsupported, and its value '
        'is not taken from any of the three modules that answer it', () async {
      final engine = await _discovered(_Ioniq5Transport());
      const pid = PidLibrary.distanceWithMil;
      expect(engine.isKnownUnsupported(pid), isFalse);
      expect(
        engine.capabilitySummary.statusFor(pid),
        isNot(PidCapabilityStatus.unsupported),
      );
    });

    test('the PID manager status agrees with the poll loop', () async {
      final engine = await _discovered(_Ioniq5Transport());
      final summary = engine.capabilitySummary;
      for (final pid in _exportPolledPids) {
        expect(
          summary.statusFor(pid),
          PidCapabilityStatus.unsupported,
          reason: pid.modeAndPid,
        );
      }
      // The engine-scoped evidence is unchanged: nothing claims to be the
      // engine, so no block is engine-verified and nothing is positive.
      expect(summary.verifiedBlockIds, isEmpty);
      expect(
        summary.statusFor(PidLibrary.engineRpm),
        isNot(PidCapabilityStatus.positive),
      );
    });

    test('the dashboard gauges read 此車輛不支援 and are not polled again '
        'within the recheck interval', () async {
      final transport = _Ioniq5Transport();
      final engine = await _discovered(transport);
      const gauges = [PidLibrary.engineRpm, PidLibrary.vehicleSpeed];
      final sentBefore = transport.sent.length;
      engine.setActivePids(gauges);
      engine.start();
      final deadline = DateTime.now().add(const Duration(seconds: 3));
      bool decided() => gauges.every(
        (pid) => engine.current.faults[pid.id] == PidFault.unsupported,
      );
      while (!decided() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await engine.stop();
      for (final pid in gauges) {
        expect(engine.current.faults[pid.id], PidFault.unsupported);
        expect(engine.current.readings.containsKey(pid.id), isFalse);
      }
      final afterStart = transport.sent.sublist(sentBefore);
      expect(afterStart, isNot(contains('010C')));
      expect(afterStart, isNot(contains('010D')));
    });

    test('a claimer that did not answer leaves its block undecided', () async {
      final engine = await _discovered(
        _Ioniq5Transport(mcuMissesFunctional0120: true),
      );
      // 0100 was fully answered, so its block is still decided.
      expect(engine.isKnownUnsupported(PidLibrary.engineRpm), isTrue);
      // 7EB said 0120 exists and then did not answer it: 0121-0140 stay
      // unknown, so they are still asked.
      expect(engine.isKnownUnsupported(PidLibrary.fuelLevel), isFalse);
      expect(
        engine.capabilitySummary.statusFor(PidLibrary.fuelLevel),
        PidCapabilityStatus.unknown,
      );
    });

    test('without a census nothing is concluded', () async {
      final engine = await _discovered(_Ioniq5Transport(), census: false);
      for (final pid in _exportPolledPids) {
        expect(engine.isKnownUnsupported(pid), isFalse, reason: pid.modeAndPid);
      }
    });
  });
}
