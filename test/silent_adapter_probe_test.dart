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

  /// Takes the bytes and answers them, but the write Future never settles:
  /// a Wi-Fi `socket.add` that went out followed by a `flush` that hangs.
  bool stallAfterAccepting = false;
  final Set<String> stallAfterAcceptingFor = {};
  void Function(String command)? onWrite;

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
    if (!isConnected) {
      throw const WriteRefusedException('quiet adapter not connected');
    }
    if (stallWrites) return Completer<void>().future;
    final key = ascii
        .decode(data, allowInvalid: true)
        .trim()
        .toUpperCase()
        .replaceAll(' ', '');
    sent.add(key);
    onWrite?.call(key);
    final pending = queued[key];
    final List<(String, Duration)>? reply;
    if (pending != null && pending.isNotEmpty) {
      reply = pending.removeAt(0);
    } else {
      reply = [(_handshake[key] ?? '?\r\r>', Duration.zero)];
    }
    if (reply != null) {
      for (final (bytes, delay) in reply) {
        if (delay == Duration.zero) {
          scheduleMicrotask(() => emitBytes(ascii.encode(bytes)));
        } else {
          Timer(delay, () => emitBytes(ascii.encode(bytes)));
        }
      }
    }
    if (stallAfterAccepting || stallAfterAcceptingFor.contains(key)) {
      return Completer<void>().future;
    }
  }
}

Future<(Elm327Client, _QuietAdapter, List<int>)> _connected({
  Duration writeTimeout = const Duration(seconds: 2),
}) async {
  final transport = _QuietAdapter();
  final lost = <int>[];
  final client = Elm327Client(
    transport,
    commandTimeout: const Duration(milliseconds: 150),
    writeTimeout: writeTimeout,
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

    test(
      'a watchdog tick that beats the reply timer still leads to the probe',
      () async {
        // Rig, heavy load: the isolate stalled, the watchdog tick and the
        // reply timer were both overdue, and the tick ran first. It read a
        // wall clock past the limit and dropped the link before any probe.
        // Forced here by putting the last byte far in the past while the
        // command is still owed its reply.
        final (client, transport, lost) = await _connected();
        addTearDown(client.dispose);
        transport.once('011F', null);
        final owed = client
            .send('011F', timeout: const Duration(seconds: 5))
            .then<Object?>((_) => null, onError: (Object e) => e);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        client.lastRxAt = DateTime.now().subtract(const Duration(seconds: 30));

        expect(await owed.timeout(const Duration(seconds: 3)), isA<TimeoutException>());
        expect(lost, isEmpty);
        final next = await client.send('0105');

        expect(transport.sent, contains('ATI'));
        expect(next.hexPayload, '410564');
        expect(lost, isEmpty);
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

    test('a chip that answers only the probe is dropped on the third answer',
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
      // The adapter answered the check; what stopped responding is
      // everything sent through it. Not the "did not answer" sentence.
      await expectLater(
        client.send('0105'),
        throwsA(
          isA<TransportException>()
              .having(
                (e) => e.issue,
                'issue',
                TransportIssue.linkStoppedResponding,
              )
              .having(
                (e) => e.message,
                'message',
                'The connection stopped responding.',
              ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(lost, [1]);
      expect(
        _noted(
          client,
          'Probe answered 3 times with no reply to any command in between; '
          'the link is not carrying replies',
        ),
        isTrue,
      );
    });

    test('stalls with a reply between them keep the session', () async {
      // The #112 exports: a random reply lost every 40-140 s, ordinary
      // replies in between. Each stall is recovered, and the reply after it
      // shows the link is carrying replies, so the count starts again.
      final (client, transport, lost) = await _connected();
      addTearDown(client.dispose);
      for (var i = 0; i < 5; i++) {
        transport.once('011F', null);
        await expectLater(
          client.send('011F'),
          throwsA(isA<TimeoutException>()),
        );
        final ok = await client.send('0105');
        expect(ok.hexPayload, '410564');
      }
      expect(lost, isEmpty);
      expect(client.isInitialized, isTrue);
    });

    test(
      'a probe answered after its caller gave up still holds the next write',
      () async {
        final (client, transport, lost) = await _connected(
        writeTimeout: const Duration(milliseconds: 500),
      );
        addTearDown(client.dispose);
        // The caller's deadline ends after the probe is written but before
        // it is answered. The answer (and a second prompt behind it) must
        // still be treated as the probe's, not as the next command's reply.
        transport
          ..once('011F', null)
          ..once('ATI', [
            ('STOPPED\r\r>', const Duration(milliseconds: 900)),
            ('?\r\r>', const Duration(milliseconds: 920)),
          ])
          ..once('010D', [('410D3C\r\r>', const Duration(milliseconds: 60))]);

        await expectLater(
          client.send('011F'),
          throwsA(isA<TimeoutException>()),
        );
        await expectLater(
          client.send(
            '0105',
            deadline: DateTime.now().add(const Duration(milliseconds: 1800)),
          ),
          throwsA(isA<TimeoutException>()),
        );
        expect(transport.sent.last, 'ATI');
        final next = await client.send('010D');

        expect(next.hexPayload, '410D3C');
        expect(lost, isEmpty);
      },
    );

    test('a stalled probe write drops the link even if a prompt arrived',
        () async {
      final (client, transport, lost) = await _connected(
        writeTimeout: const Duration(milliseconds: 500),
      );
      addTearDown(client.dispose);
      transport.once('011F', null);

      await expectLater(client.send('011F'), throwsA(isA<TimeoutException>()));
      // The probe goes out and is answered, but its write never completes.
      // That prompt may be an older reply's; the probe's own answer may
      // still be on its way. The stream cannot be called in step.
      transport.stallAfterAccepting = true;
      await expectLater(
        client.send('0105'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.writeFailed,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(transport.sent, ['011F', 'ATI']);
      expect(lost, [1]);
    });

    test(
      'a caller without budget for the whole probe write is refused without it',
      () async {
        final (client, transport, lost) = await _connected();
        addTearDown(client.dispose);
        // After the one-second listen only 300 ms of this caller remain, less
        // than the probe's two-second write limit. A write cut short has an
        // unknown outcome, so the probe is not sent for this caller at all;
        // the next resync, with no deadline, sends it.
        transport.once('011F', null);

        await expectLater(
          client.send('011F'),
          throwsA(isA<TimeoutException>()),
        );
        await expectLater(
          client.send(
            '0105',
            deadline: DateTime.now().add(const Duration(milliseconds: 1300)),
          ),
          throwsA(isA<TimeoutException>()),
        );
        expect(transport.sent, isNot(contains('ATI')));
        expect(client.isOutOfSync, isTrue);
        final next = await client.send('010D');

        expect(transport.sent, contains('ATI'));
        expect(next.hexPayload, '410D3C');
        expect(lost, isEmpty);
      },
    );

    test('a client disconnect during the hold writes nothing after it',
        () async {
      final (client, transport, lost) = await _connected(
        writeTimeout: const Duration(milliseconds: 500),
      );
      addTearDown(client.dispose);
      transport
        ..once('011F', null)
        ..once('ATI', [('ELM327 v1.5\r\r>', const Duration(milliseconds: 900))]);

      await expectLater(client.send('011F'), throwsA(isA<TimeoutException>()));
      await expectLater(
        client.send(
          '0105',
          deadline: DateTime.now().add(const Duration(milliseconds: 1800)),
        ),
        throwsA(isA<TimeoutException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      transport.sent.clear();

      final parked = expectLater(
        client.send('010D'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.notConnected,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await client.disconnect();

      await parked;
      expect(transport.sent, isNot(contains('010D')));
    });

    test('a session retired during the hold sends nothing after it', () async {
      final (client, transport, lost) = await _connected(
        writeTimeout: const Duration(milliseconds: 500),
      );
      addTearDown(client.dispose);
      var live = true;
      client.mayTransmit = (_) => live;
      // Caller gives up after the probe is written; its single prompt then
      // arrives with nothing waiting and arms the hold.
      transport
        ..once('011F', null)
        ..once('ATI', [('ELM327 v1.5\r\r>', const Duration(milliseconds: 900))]);

      await expectLater(client.send('011F'), throwsA(isA<TimeoutException>()));
      await expectLater(
        client.send(
          '0105',
          deadline: DateTime.now().add(const Duration(milliseconds: 1800)),
        ),
        throwsA(isA<TimeoutException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      transport.sent.clear();

      final parked = client.send('010D');
      // The app goes to the background while the write waits out the hold.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      live = false;

      await expectLater(parked, throwsA(isA<OperationRetiredException>()));
      expect(transport.sent, isNot(contains('010D')));
    });

    test('the probe answer is not charged to a transaction budget', () async {
      final (client, transport, lost) = await _connected();
      addTearDown(client.dispose);
      // Flow-control and ISO-TP restores add drained bytes to a 256-byte
      // budget that refuses, and then sticks, when exceeded. Nothing of the
      // owed reply arrived here; the drained prompt is the probe's.
      transport.once('011F', null);

      await expectLater(client.send('011F'), throwsA(isA<TimeoutException>()));
      await client.send('0105');

      expect(transport.sent, contains('ATI'));
      expect(client.resyncDrainedWireBytesForTest, 0);
    });

    test('a deadline that passes during the hold refuses before writing',
        () async {
      final (client, transport, lost) = await _connected(
        writeTimeout: const Duration(milliseconds: 500),
      );
      addTearDown(client.dispose);
      // Caller gives up after the probe is written; the probe's single
      // prompt then arrives with nothing waiting and arms the hold.
      transport
        ..once('011F', null)
        ..once('ATI', [('ELM327 v1.5\r\r>', const Duration(milliseconds: 900))]);

      await expectLater(client.send('011F'), throwsA(isA<TimeoutException>()));
      await expectLater(
        client.send(
          '0105',
          deadline: DateTime.now().add(const Duration(milliseconds: 1800)),
        ),
        throwsA(isA<TimeoutException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      transport.sent.clear();

      await expectLater(
        client.send(
          '010D',
          deadline: DateTime.now().add(const Duration(milliseconds: 100)),
        ),
        throwsA(
          isA<TimeoutException>().having(
            (e) => e.message,
            'message',
            contains('was not sent'),
          ),
        ),
      );
      expect(transport.sent, isNot(contains('010D')));
      expect(lost, isEmpty);
    });

    test('a disconnect during the post-probe hold does not strand a send',
        () async {
      final (client, transport, lost) = await _connected();
      addTearDown(client.dispose);
      transport
        ..once('011F', null)
        ..onWrite = (command) {
          if (command != 'ATI') return;
          // After the probe's answer arrives and the hold is armed, before
          // the hold's own timer would release it.
          Timer(const Duration(milliseconds: 100), () {
            transport.disconnect();
          });
        };

      await expectLater(client.send('011F'), throwsA(isA<TimeoutException>()));
      final outcome = await client
          .send('0105')
          .then((_) => 'answered', onError: (Object _) => 'failed')
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => 'stranded',
          );

      expect(outcome, isNot('stranded'));
    });

    test('a probe write that never completes ends the wait without the drain',
        () async {
      // Short enough that the drain would still have time left after it:
      // listen 1 s, write gives up at 1.5 s, the window runs to 3 s.
      final (client, transport, lost) = await _connected(
        writeTimeout: const Duration(milliseconds: 500),
      );
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
            TransportIssue.writeFailed,
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
      // Listen plus the write's own limit, not the rest of the window.
      expect(watch.elapsed, lessThan(const Duration(milliseconds: 2500)));
    });
  });
}
