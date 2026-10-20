/// Why the link went, as `Elm327Client` reports it (#112).
///
/// The session reconnects by itself only after an adapter that went silent.
/// These drive each cause through the client's own path rather than setting
/// it, so a call site that reports the wrong one shows here: an unplugged
/// adapter must not read as a silent one.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

import 'support/fake_elm327.dart';

FakeElm327 _adapter() => FakeElm327(
  protocol: BusProtocol.can11,
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

Future<(Elm327Client, FakeElm327, List<ConnectionLossCause?>)>
_connected() async {
  final transport = _adapter();
  final causes = <ConnectionLossCause?>[];
  late final Elm327Client client;
  client = Elm327Client(
    transport,
    commandTimeout: const Duration(milliseconds: 150),
  )..onConnectionLost = () => causes.add(client.connectionLossCause);
  addTearDown(client.dispose);
  expect(await client.connect(), isTrue);
  return (client, transport, causes);
}

/// [inner], except that once [stallProbe] is set an `ATI` write never
/// completes.
class _StallsProbe extends BaseObdTransport {
  _StallsProbe(this.inner) {
    inner.incoming.listen(emitBytes);
    inner.connectionChanges.listen(setConnected);
  }

  final FakeElm327 inner;
  bool stallProbe = false;

  @override
  TransportKind get kind => inner.kind;

  @override
  String get displayName => inner.displayName;

  @override
  Future<void> connect() => inner.connect();

  @override
  Future<void> disconnect() => inner.disconnect();

  @override
  Future<void> write(List<int> data) {
    if (stallProbe && String.fromCharCodes(data).trim() == 'ATI') {
      return Completer<void>().future;
    }
    return inner.write(data);
  }
}

/// A link that opens only when the test says so, and records what is written
/// to it.
class _HeldLink extends BaseObdTransport {
  final gate = Completer<void>();
  final written = <List<int>>[];

  @override
  TransportKind get kind => TransportKind.wifi;

  @override
  String get displayName => 'Held';

  @override
  Future<void> connect() async {
    await gate.future;
    setConnected(true);
  }

  @override
  Future<void> disconnect() async => setConnected(false);

  @override
  Future<void> write(List<int> data) async => written.add(data);
}

void main() {
  test('the transport closing is transportClosed', () async {
    final (_, transport, causes) = await _connected();

    await transport.disconnect();
    await pumpEventQueue();

    expect(causes, [ConnectionLossCause.transportClosed]);
  });

  test('an adapter reset in a reply is adapterError', () async {
    final (client, transport, causes) = await _connected();
    transport.forceReply('010D', 'LV RESET');

    await client.send('010D').then<void>((_) {}, onError: (_) {});
    await pumpEventQueue();

    expect(causes, [ConnectionLossCause.adapterError]);
  });

  test('a probe nobody answers is adapterSilent', () async {
    final (client, transport, causes) = await _connected();
    transport.goSilent = true;

    await expectLater(client.send('010D'), throwsA(isA<TimeoutException>()));
    await client.send('010C').then<void>((_) {}, onError: (_) {});
    await pumpEventQueue();

    expect(causes, [ConnectionLossCause.adapterSilent]);
  });

  test('a probe that cannot be written is writeStalled', () async {
    // A link that will not take a write is a transport fault, often Bluetooth
    // out of range before the OS says so, not an adapter that went quiet.
    final transport = _StallsProbe(_adapter());
    final causes = <ConnectionLossCause?>[];
    late final Elm327Client client;
    client = Elm327Client(
      transport,
      commandTimeout: const Duration(milliseconds: 150),
      writeTimeout: const Duration(milliseconds: 200),
    )..onConnectionLost = () => causes.add(client.connectionLossCause);
    addTearDown(client.dispose);
    expect(await client.connect(), isTrue);
    transport.inner.goSilent = true;
    transport.stallProbe = true;

    await expectLater(client.send('010D'), throwsA(isA<TimeoutException>()));
    await client.send('010C').then<void>((_) {}, onError: (_) {});
    await pumpEventQueue();

    expect(causes, [ConnectionLossCause.writeStalled]);
  });

  test(
    'a resync gives its verdict even when its window outlasts the grace',
    () async {
      // The grace is published at the resync's start on the wall clock; the
      // drain timer is armed after the pre-wait and the probe, for what is left
      // of the window on the client's clock. When those drift, a watchdog tick
      // lands between them and drops the link before the resync can say "Probe
      // got no answer" — the line #112's next export is for. Seen once under
      // load in the full suite. A clock that stops at the resync's start makes
      // the drift a whole second, so a tick always lands in it.
      final transport = _adapter();
      DateTime? frozen;
      final notesAtLoss = <String>[];
      final causes = <ConnectionLossCause?>[];
      late final Elm327Client client;
      client =
          Elm327Client(
              transport,
              commandTimeout: const Duration(milliseconds: 150),
              clock: () => frozen ?? DateTime.now(),
            )
            ..onConnectionLost = () {
              causes.add(client.connectionLossCause);
              // The record as the first loss saw it: a second callback would
              // carry the resync's note in and hide a first one without it.
              if (causes.length > 1) return;
              notesAtLoss.addAll(
                client.transcript.entries
                    .map((e) => e.note)
                    .whereType<String>(),
              );
            };
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      transport.goSilent = true;
      // Idle first, as between polls: the watchdog only drops past its five
      // seconds of silence, and the tick that lands in the drift must be past
      // them, as it was in the run that showed this.
      await Future<void>.delayed(const Duration(milliseconds: 2500));

      await expectLater(client.send('010D'), throwsA(isA<TimeoutException>()));
      client.onResyncStarted = () => frozen ??= DateTime.now();
      await client.send('010C').then<void>((_) {}, onError: (_) {});
      await pumpEventQueue();

      // The outcome first: it is what the record is for.
      expect(notesAtLoss, contains('Probe got no answer'));
      expect(causes, [ConnectionLossCause.adapterSilent]);
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  test('a link closed while it was opening gets no handshake', () async {
    // A Wi-Fi socket still connecting has nothing for a close to act on, so
    // it opened anyway and the handshake went out for a client nobody owned.
    final link = _HeldLink();
    final client = Elm327Client(link);
    final connecting = client.connect();
    await pumpEventQueue();

    await client.disconnect();
    link.gate.complete();

    expect(await connecting, isFalse);
    expect(link.written, isEmpty);
    expect(link.isConnected, isFalse);
    await client.dispose();
  });
}
