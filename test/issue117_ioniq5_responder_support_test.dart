/// Issue #117: a 2022 Hyundai IONIQ 5 has no `7E8`. Four other modules answer
/// the functional `0100`, and each one's support mask describes only itself.
///
/// Offline replay of the reporter's exported session (app 1.0.25 (2082),
/// Samsung SM-S9480, Bluetooth Classic `OBDBLE`, adapter `ELM327 v1.5` /
/// `ICSolution`, ISO 15765-4 CAN 11/500, ATDPN `A6`). The masked copy of that
/// export is in the #117 internal note; line numbers below count the export's
/// own first line (`# [MASKED COPY] ...`) as line 1, not lines of the note.
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
import 'package:torque_obd/ui/screens/pids/pid_manager_screen.dart';

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
  _Ioniq5Transport({
    this.mcuMissesFunctional0120 = false,
    this.census0100,
    this.later0100,
    this.physical = const {},
    this.functional0101,
  });

  /// When true, `7EB` does not answer the functional `0120` although its
  /// `0100` mask says the block exists. Not in the export; used to show that
  /// an unaccounted claimer leaves the block undecided.
  final bool mcuMissesFunctional0120;

  /// Synthetic replies for the first headered functional `0100` (the
  /// census) and every later one. Default: the export's line 131.
  final String? census0100;
  final String? later0100;

  /// Synthetic headerless replies on physical `7E0`. Default: `NO DATA`, as
  /// in the export. Pass a mutable map to make the engine answer later.
  final Map<String, String> physical;

  /// Synthetic reply to a functional `0101`. Default: `NO DATA`.
  final String? functional0101;

  /// While set, a headered functional `0100` after the census is held until
  /// it completes.
  Completer<void>? holdLater0100;
  bool laterHeld = false;

  final List<String> sent = [];

  bool _echo = true;
  bool _headersOn = false;
  bool _searchPending = true;
  String? _header;
  int _headered0100Count = 0;

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
    final heldBefore = _headered0100Count;
    final body = _respond(key);
    final reply = _echo && raw.isNotEmpty ? '$raw\r$body' : body;
    if (key == 'ATE0') _echo = false;
    final hold = holdLater0100;
    if (hold != null && heldBefore >= 1 && _headered0100Count > heldBefore) {
      laterHeld = true;
      unawaited(hold.future.then((_) => emitBytes(ascii.encode(reply))));
      return;
    }
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

    if (_physical) {
      final reply = physical[command];
      return reply == null ? _noData : '$reply\r\r>';
    }
    switch (command) {
      case '0100':
        if (_searchPending) {
          _searchPending = false;
          return _searching0100;
        }
        if (!_headersOn) return _headerless0100;
        _headered0100Count++;
        if (_headered0100Count == 1 && census0100 != null) return census0100!;
        return later0100 ?? _headered0100;
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
      case '0101':
        return functional0101 ?? _noData;
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

    test('the export covers 22 distinct requests, all in the library', () {
      expect({
        for (final pid in _exportPolledPids) pid.modeAndPid.toUpperCase(),
      }, _polledInExport);
    });

    test(
      'a PID no responder claims is known unsupported in every block',
      () async {
        final engine = await _discovered(_Ioniq5Transport());
        for (final pid in _exportPolledPids) {
          expect(
            engine.isKnownUnsupported(pid),
            isTrue,
            reason: '${pid.modeAndPid}: no mask from 7EA/7EB/7EC/7EE claims it',
          );
        }
      },
    );

    test('a PID other modules claim stays unknown, and none of their three '
        'answers becomes a reading', () async {
      final transport = _Ioniq5Transport();
      final engine = await _discovered(transport);
      const pid = PidLibrary.distanceWithMil;
      expect(engine.isKnownUnsupported(pid), isFalse);
      expect(
        engine.capabilitySummary.statusFor(pid),
        PidCapabilityStatus.unknown,
      );
      final sentBefore = transport.sent.length;
      engine.setActivePids(const [pid]);
      engine.start();
      final deadline = DateTime.now().add(const Duration(seconds: 3));
      while (!engine.current.faults.containsKey(pid.id) &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await engine.stop();
      expect(transport.sent.sublist(sentBefore), contains('0121'));
      expect(engine.current.faults.containsKey(pid.id), isTrue);
      expect(engine.current.readings.containsKey(pid.id), isFalse);
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
      expect(summary.positivelyConfirmedShippedDirectPids, isEmpty);
      // Every block is accounted for, so the bulk action says nothing is
      // confirmed rather than that the scan is incomplete.
      expect(summary.unknownOrUnverifiedBlockCount, 0);
      expect(
        supportedPidBulkPresentation(
          summary: summary,
          active: const <Pid>[],
          mutationLocked: false,
        ).state,
        SupportedPidBulkUiState.zero,
      );
      // 7EC's 0160 mask claims the 0180 block, which is never asked: the
      // panel reads 連續涵蓋 01–80（後續未知）, not 連續涵蓋尚未建立.
      expect(summary.contiguousCoverageThroughPid, 0x80);
      expect(summary.contiguousCoverageReachedVerifiedTerminal, isFalse);
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

    test('a responder chain that ends at 0100 is not asked again', () async {
      // Synthetic: one controller whose 0100 mask is empty.
      const onlyBms = '7EC06410000000000\r\r>';
      final transport = _Ioniq5Transport(
        census0100: onlyBms,
        later0100: onlyBms,
      );
      final engine = await _discovered(transport);
      expect(engine.isKnownUnsupported(PidLibrary.engineRpm), isTrue);
      expect(transport.sent, isNot(contains('0120')));
      // Nobody claims 0120, so the later blocks are settled too.
      expect(engine.isKnownUnsupported(PidLibrary.fuelLevel), isTrue);
      expect(engine.isKnownUnsupported(PidLibrary.engineFuelRate), isTrue);
      final summary = engine.capabilitySummary;
      expect(summary.unknownOrUnverifiedBlockCount, 0);
      expect(summary.contiguousCoverageThroughPid, 0x20);
      expect(summary.contiguousCoverageReachedVerifiedTerminal, isTrue);
    });

    test(
      'polling that starts before discovery stops asking once it lands',
      () async {
        // ObdSession starts polling and then runs discovery after the census,
        // so the queue already holds the gauges and their physics inputs.
        final transport = _Ioniq5Transport();
        final client = await _connect(transport);
        final engine = PollingEngine(client);
        addTearDown(engine.dispose);
        await engine.discoverResponders();
        const gauges = [PidLibrary.engineRpm, PidLibrary.vehicleSpeed];
        engine.setActivePids(gauges);
        engine.start();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await engine.discoverSupportedPids();
        final settled = transport.sent.length;
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        await engine.stop();
        final deadAfter = [
          for (final command in transport.sent.sublist(settled))
            if (_polledInExport.contains(command)) command,
        ];
        // At most the one request already on the wire when discovery
        // returned: once on 7E0, once on 7DF.
        expect(deadAfter.length, lessThanOrEqualTo(2), reason: '$deadAfter');
        for (final pid in gauges) {
          expect(engine.current.faults[pid.id], PidFault.unsupported);
        }
      },
    );

    test('the dashboard stream itself says 此車輛不支援', () async {
      final engine = await _discovered(_Ioniq5Transport());
      const gauges = [PidLibrary.engineRpm, PidLibrary.vehicleSpeed];
      Map<String, PidFault>? lastFaults;
      final sub = engine.snapshots.listen((s) => lastFaults = s.faults);
      addTearDown(sub.cancel);
      engine.setActivePids(gauges);
      engine.start();
      final deadline = DateTime.now().add(const Duration(seconds: 3));
      bool shown() =>
          gauges.every((pid) => lastFaults?[pid.id] == PidFault.unsupported);
      while (!shown() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await engine.stop();
      for (final pid in gauges) {
        expect(lastFaults?[pid.id], PidFault.unsupported, reason: pid.id);
      }
    });

    test('a refused reply records nothing', () async {
      // Synthetic: the census heard only 7EC; its later 0100 line has no PCI
      // byte, so the parser refuses it, and those six raw bytes must not
      // become an empty mask.
      final transport = _Ioniq5Transport(
        census0100: '7EC06410080000001\r\r>',
        later0100: '7EC410000000000\r\r>',
      );
      final engine = await _discovered(transport);
      expect(engine.capabilitySummary.responderAccountedBlockIds, isEmpty);
      expect(engine.isKnownUnsupported(PidLibrary.engineRpm), isFalse);
      expect(
        engine.capabilitySummary.statusFor(PidLibrary.engineRpm),
        PidCapabilityStatus.unknown,
      );
    });

    test('an interrupted discovery commits nothing', () async {
      final transport = _Ioniq5Transport();
      final client = await _connect(transport);
      final engine = PollingEngine(client);
      addTearDown(engine.dispose);
      await engine.discoverResponders();
      final hold = transport.holdLater0100 = Completer<void>();
      final discovery = engine.discoverSupportedPids();
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (!transport.laterHeld && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(transport.laterHeld, isTrue);
      engine.interruptCapabilityDiscovery();
      hold.complete();
      await discovery;
      expect(engine.capabilitySummary.responderAccountedBlockIds, isEmpty);
      expect(engine.isKnownUnsupported(PidLibrary.engineRpm), isFalse);
    });
  });

  group('an engine the census missed is still the engine', () {
    // Synthetic. The engine masks are the issue #109 export's 7E8 masks
    // (0100 BE3FA813, 0120 A007B011, 0140 FED08410); 7EB is this export's.
    test('a refusal keeps its backoff when an engine shows', () async {
      // Synthetic, from the Codex round-4 review: with no engine in the
      // census, 0121 is refused with 7F 01 12, then a MIL read is answered by
      // 7E8. The refusal has nothing to do with the no-engine reading and
      // keeps its backoff.
      final transport = _Ioniq5Transport(
        physical: const {'0100': '410080000000', '0121': '7F0112'},
        functional0101: '7E806410100000000\r\r>',
      );
      final engine = await _discovered(transport);
      const pid = PidLibrary.distanceWithMil;
      expect(engine.isKnownUnsupported(pid), isFalse);
      engine.setActivePids(const [pid]);
      engine.start();
      final deadline = DateTime.now().add(const Duration(seconds: 4));
      while (engine.current.faults[pid.id] != PidFault.unsupported &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await engine.stop();
      expect(engine.current.faults[pid.id], PidFault.unsupported);
      final before = transport.sent.where((c) => c == '0121').length;
      expect(await engine.readMilStatus(), isNotNull);
      engine.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await engine.stop();
      expect(transport.sent.where((c) => c == '0121').length, before);
    });

    test('a refusal at the recheck keeps its own backoff', () async {
      // Synthetic, from the Codex final review: rpm is rested by the
      // no-engine reading, its recheck is refused with 7F 01 12, then a MIL
      // read is answered by 7E8. The refusal set its own rest, which the
      // engine showing up must not cut short.
      final physical = <String, String>{};
      final transport = _Ioniq5Transport(
        physical: physical,
        functional0101: '7E806410100000000\r\r>',
      );
      final engine = await _discovered(transport);
      const rpm = PidLibrary.engineRpm;
      engine.recheckInterval = const Duration(milliseconds: 1500);
      engine.setActivePids(const [rpm]);
      engine.start();
      var deadline = DateTime.now().add(const Duration(seconds: 3));
      while (engine.current.faults[rpm.id] != PidFault.unsupported &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(engine.current.faults[rpm.id], PidFault.unsupported);
      physical['010C'] = '7F0112';
      final sentBefore = transport.sent.length;
      deadline = DateTime.now().add(const Duration(seconds: 4));
      while (!transport.sent.sublist(sentBefore).contains('010C') &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      // Let the refusal be handled before the engine shows.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await engine.stop();
      final refused = transport.sent.where((c) => c == '010C').length;
      expect(refused, greaterThanOrEqualTo(1));
      expect(engine.current.faults[rpm.id], PidFault.unsupported);
      expect(await engine.readMilStatus(), isNotNull);
      engine.start();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await engine.stop();
      expect(transport.sent.where((c) => c == '010C').length, refused);
    });

    test('a 7E8 heard by a MIL read reaches capability subscribers', () async {
      // Synthetic: discovery heard no engine, then a MIL read is answered by
      // 7E8 (06 41 01 00 00 00 00).
      final transport = _Ioniq5Transport(
        functional0101: '7E806410100000000\r\r>',
      );
      final engine = await _discovered(transport);
      const rpm = PidLibrary.engineRpm;
      ObdCapabilitySummary? last;
      final sub = engine.capabilitySummaries.listen((s) => last = s);
      addTearDown(sub.cancel);
      expect(
        engine.capabilitySummary.statusFor(rpm),
        PidCapabilityStatus.unsupported,
      );
      final mil = await engine.readMilStatus();
      expect(mil, isNotNull);
      expect(
        engine.capabilitySummary.statusFor(rpm),
        PidCapabilityStatus.unknown,
      );
      expect(last, isNotNull);
      expect(last!.responderAccountedBlockIds, isEmpty);
      expect(last!.statusFor(rpm), PidCapabilityStatus.unknown);
    });

    test(
      'engine evidence after discovery releases what it had rested',
      () async {
        // Synthetic: the engine starts answering physical requests only after
        // discovery has finished. With the default five-minute recheck, rpm
        // must not stay dark until then.
        final physical = <String, String>{};
        final transport = _Ioniq5Transport(physical: physical);
        final engine = await _discovered(transport);
        const rpm = PidLibrary.engineRpm;
        const mil = PidLibrary.distanceWithMil;
        engine.setActivePids(const [rpm, mil]);
        engine.start();
        var deadline = DateTime.now().add(const Duration(seconds: 3));
        while (engine.current.faults[rpm.id] != PidFault.unsupported &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        expect(engine.current.faults[rpm.id], PidFault.unsupported);
        physical['0121'] = '41210005';
        physical['010C'] = '410C1AF8';
        deadline = DateTime.now().add(const Duration(seconds: 5));
        while (!engine.current.readings.containsKey(rpm.id) &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        await engine.stop();
        expect(engine.current.readings[mil.id]?.value, closeTo(5, 0.01));
        expect(engine.current.readings[rpm.id]?.value, closeTo(1726, 0.5));
      },
    );

    test('its mask in the discovery reply restores the engine rule', () async {
      final transport = _Ioniq5Transport(
        census0100: '7EB06410080000001\r\r>',
        later0100: '7E8064100BE3FA813\r7EB06410080000001\r\r>',
        physical: const {'0120': '4120A007B011', '0140': '4140FED08410'},
      );
      final engine = await _discovered(transport);
      final summary = engine.capabilitySummary;
      expect(summary.verifiedBlockIds, containsAll(['0100', '0120', '0140']));
      expect(summary.responderAccountedBlockIds, isEmpty);
      expect(
        summary.statusFor(PidLibrary.engineRpm),
        PidCapabilityStatus.positive,
      );
      expect(
        summary.statusFor(PidLibrary.mafRate),
        PidCapabilityStatus.positive,
      );
      expect(engine.isKnownUnsupported(PidLibrary.mafRate), isFalse);
    });

    test(
      'a direct answer at recheck wins and ends the no-engine reading',
      () async {
        final physical = <String, String>{};
        final transport = _Ioniq5Transport(physical: physical);
        final engine = await _discovered(transport);
        const rpm = PidLibrary.engineRpm;
        expect(engine.isKnownUnsupported(rpm), isTrue);
        engine.recheckInterval = const Duration(milliseconds: 200);
        // Standard J1979 encoding, 1726 rpm, as in the issue #109 test.
        physical['010C'] = '410C1AF8';
        engine.setActivePids(const [rpm]);
        engine.start();
        final deadline = DateTime.now().add(const Duration(seconds: 4));
        while (!engine.current.readings.containsKey(rpm.id) &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        await engine.stop();
        expect(engine.current.readings[rpm.id]?.value, closeTo(1726, 0.5));
        expect(engine.capabilitySummary.responderAccountedBlockIds, isEmpty);
        expect(engine.isKnownUnsupported(PidLibrary.vehicleSpeed), isFalse);
      },
    );
  });
}
