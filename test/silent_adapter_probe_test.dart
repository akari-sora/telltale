/// An adapter that goes quiet after a command, with nothing in the buffer.
///
/// Three user exports from one car (two ICSolution `ELM327 v1.5` adapters,
/// Bluetooth Classic) all ended the same way: a command was written, no byte
/// came back, and the session was dropped. Twice it was a single-PID read
/// (`011F`, a repeated `015E`) — not the multi-ECU batch #110 was about — and
/// the reporter recovered every time by reconnecting by hand, so the chip was
/// still alive.
///
/// A live ELM327 answers the next line it receives, and any byte aborts one
/// that is still busy. Waiting passively for a prompt that is never coming
/// cannot tell those cases from a dead link, so the client probes with `ATI`
/// and records what happened.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

const Map<String, String> _handshake = {
  'ATZ': 'ELM327 v1.5\r\r>',
  'ATE0': 'OK\r\r>',
  'ATL0': 'OK\r\r>',
  'ATM0': 'OK\r\r>',
  'ATS0': 'OK\r\r>',
  'ATAT1': 'OK\r\r>',
  'ATAT2': 'OK\r\r>',
  'ATST66': 'OK\r\r>',
  'ATSP0': 'OK\r\r>',
  'ATI': 'ELM327 v1.5\r\r>',
  'AT@1': 'ICSolution\r\r>',
  'ATRV': '15.3V\r\r>',
  '0100': '4100BE3FA813\r\r>',
  'ATDP': 'AUTO, ISO 15765-4 (CAN 11/500)\r\r>',
  'ATDPN': 'A6\r\r>',
  'ATSH7E0': 'OK\r\r>',
  '0105': '410564\r\r>',
  '010D': '410D3C\r\r>',
  '011F': '411F0120\r\r>',
  '015E': 'NO DATA\r\r>',
};

/// Replies per command; a queued reply for a command is used once, before
/// the standing one. `null` in the queue means "no byte at all".
class _QuietAdapter extends BaseObdTransport {
  final Map<String, List<List<(String, Duration)>?>> queued = {};
  final List<String> sent = [];
  bool stallWrites = false;

  void once(String command, List<(String, Duration)>? reply) =>
      (queued[command] ??= []).add(reply);

  @override
  TransportKind get kind => TransportKind.demo;

  @override
  String get displayName => 'Quiet ICSolution';

  @override
  Future<void> connect() async => setConnected(true);

  @override
  Future<void> disconnect() async => setConnected(false);

  @override
  Future<void> write(List<int> data) async {
    if (stallWrites) return Completer<void>().future;
    final key = ascii
        .decode(data, allowInvalid: true)
        .trim()
        .toUpperCase()
        .replaceAll(' ', '');
    sent.add(key);
    final pending = queued[key];
    final List<(String, Duration)>? reply;
    if (pending != null && pending.isNotEmpty) {
      reply = pending.removeAt(0);
    } else {
      reply = [(_handshake[key] ?? '?\r\r>', Duration.zero)];
    }
    if (reply == null) return;
    for (final (bytes, delay) in reply) {
      if (delay == Duration.zero) {
        scheduleMicrotask(() => emitBytes(ascii.encode(bytes)));
      } else {
        Timer(delay, () => emitBytes(ascii.encode(bytes)));
      }
    }
  }
}

Future<(Elm327Client, _QuietAdapter, List<int>)> _connected() async {
  final transport = _QuietAdapter();
  final lost = <int>[];
  final client = Elm327Client(
    transport,
    commandTimeout: const Duration(milliseconds: 150),
  )..onConnectionLost = () => lost.add(1);
  expect(await client.connect(), isTrue);
  transport.sent.clear();
  return (client, transport, lost);
}

bool _noted(Elm327Client client, String note) =>
    client.transcript.entries.any((e) => e.note == note);

void main() {
  group('silence after a write, empty buffer', () {
    test(
      'a single-PID read that gets no byte is probed and the session lives',
      () async {
        final (client, transport, lost) = await _connected();
        addTearDown(client.dispose);
        // Log A: `011F` written, nothing back. The probe is what tells a live
        // chip from a dead link.
        transport.once('011F', null);

        await expectLater(
          client.send('011F'),
          throwsA(isA<TimeoutException>()),
        );
        final next = await client.send('0105');

        expect(transport.sent, ['011F', 'ATI', '0105']);
        expect(next.hexPayload, '410564');
        expect(client.isInitialized, isTrue);
        expect(lost, isEmpty);
        expect(
          _noted(client, 'Adapter silent after the last command; probing with ATI'),
          isTrue,
        );
        expect(_noted(client, 'Probe answered; the link is back in step'), isTrue);
      },
    );

    test('a chip still waiting for a lost line end answers the probe with ?',
        () async {
      final (client, transport, lost) = await _connected();
      addTearDown(client.dispose);
      // Log B: `015E` again, nothing back. If the command's `\r` never reached
      // the chip, `ATI\r` ends that line and the chip answers `?`.
      transport
        ..once('015E', null)
        ..once('ATI', [('?\r\r>', Duration.zero)]);

      await expectLater(client.send('015E'), throwsA(isA<TimeoutException>()));
      final next = await client.send('010D');

      expect(next.hexPayload, '410D3C');
      expect(lost, isEmpty);
      expect(client.isInitialized, isTrue);
    });

    test('a second prompt after the probe does not answer the next command',
        () async {
      final (client, transport, lost) = await _connected();
      addTearDown(client.dispose);
      // A chip that was still busy: the probe's first byte aborts it
      // (`STOPPED`), and the rest of the line is answered on its own. Two
      // prompts for one probe. The drain releases on the first; the second
      // must not be read as the next command's reply.
      // The order on real hardware: the chip answers the rest of the probe
      // line before it reads the next command, so the stray `?` lands first
      // and the next command's own reply follows its usual ~47 ms later.
      transport
        ..once('011F', null)
        ..once('ATI', [
          ('STOPPED\r\r>', Duration.zero),
          ('?\r\r>', const Duration(milliseconds: 20)),
        ])
        ..once('010D', [('410D3C\r\r>', const Duration(milliseconds: 60))]);

      await expectLater(client.send('011F'), throwsA(isA<TimeoutException>()));
      final next = await client.send('010D');

      expect(next.hexPayload, '410D3C');
      expect(next.isSuccess, isTrue);
      expect(lost, isEmpty);
    });

    test('a probe that gets no answer drops the link and says so', () async {
      final (client, transport, lost) = await _connected();
      addTearDown(client.dispose);
      transport
        ..once('011F', null)
        ..once('ATI', null);

      await expectLater(client.send('011F'), throwsA(isA<TimeoutException>()));
      await expectLater(
        client.send('0105'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.adapterSilentOnResync,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(transport.sent, ['011F', 'ATI']);
      expect(lost, [1]);
      expect(_noted(client, 'Probe got no answer'), isTrue);
    });

    test(
      'a watchdog tick before the next command does not drop the link first',
      () async {
        // Found on the rig, not in these unit tests: the command timer clears
        // the pending reply, and before the next command's resync starts the
        // watchdog ticks, measures silence since the last byte, and drops the
        // session. The probe never runs. Both 1.0.21 exports ended exactly
        // five seconds after the write, which is this path.
        final transport = _QuietAdapter();
        final lost = <int>[];
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 300),
          watchdogTimeout: const Duration(milliseconds: 300),
        )..onConnectionLost = () => lost.add(1);
        addTearDown(client.dispose);
        expect(await client.connect(), isTrue);
        transport.once('011F', null);

        await expectLater(
          client.send('011F'),
          throwsA(isA<TimeoutException>()),
        );
        // Longer than one watchdog tick: the poll loop's next command is
        // not always immediate.
        await Future<void>.delayed(const Duration(milliseconds: 1300));
        expect(lost, isEmpty);
        final next = await client.send('0105');

        expect(next.hexPayload, '410564');
        expect(lost, isEmpty);
        expect(client.isInitialized, isTrue);
      },
    );

    test('a chip that answers only the probe is dropped after three tries',
        () async {
      final (client, transport, lost) = await _connected();
      addTearDown(client.dispose);
      // ATI keeps answering, every OBD read stays silent. Recovering forever
      // would be a connected screen with nothing on it.
      for (var i = 0; i < 4; i++) {
        transport.once('0105', null);
      }

      for (var i = 0; i < 3; i++) {
        await expectLater(
          client.send('0105'),
          throwsA(isA<TimeoutException>()),
        );
        expect(lost, isEmpty);
      }
      await expectLater(
        client.send('0105'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.adapterSilentOnResync,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(lost, [1]);
      expect(
        _noted(client, 'Probe answered three times with no vehicle reply in between'),
        isTrue,
      );
    });

    test('a probe write that never completes ends the wait without the drain',
        () async {
      final (client, transport, lost) = await _connected();
      addTearDown(client.dispose);
      transport.once('011F', null);

      await expectLater(client.send('011F'), throwsA(isA<TimeoutException>()));
      // RFCOMM with its credits exhausted: the bytes are never taken.
      transport.stallWrites = true;
      final watch = Stopwatch()..start();
      await expectLater(
        client.send('0105'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.adapterSilentOnResync,
          ),
        ),
      );
      watch.stop();
      await Future<void>.delayed(Duration.zero);

      expect(lost, [1]);
      expect(
        _noted(client, 'Probe write did not complete; the link is not taking bytes'),
        isTrue,
      );
      // The write's own two-second limit, not that plus the three-second drain.
      expect(watch.elapsed, lessThan(Elm327Client.resyncTimeout + client.writeTimeout));
    });
  });
}
