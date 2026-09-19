/// Five-Point Finite Control Regression Test Suite for ELM327 Response Headers Clean Refusal.
///
/// Requirement R3:
/// 1. Positive Control 1: H0 receives clean ATH1 ? -> retains H0, anonymous query proceeds.
/// 2. Positive Control 2: Established H1 receives clean ATH0 ? -> retains H1, subsequent queries succeed with headered parsing.
/// 3. Gap Probe 1: H1 repeated ATH1 ? via sendGlobal('03') -> retains H1 with correct attribution.
/// 4. Gap Probe 2: H0 repeated ATH0 ? -> retains H0.
/// 5. Gap Probe 3: ATH1 returns DATA ERROR\r? -> aborts query dispatch, sets uncertainty, and subsequent plain queries are wire-zero rejected.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

import 'support/fake_elm327.dart';

Map<String, List<int>> _standardPhysicsReplies() => {
  '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
  '0105': [0x41, 0x05, 0x7B],
  '010C': [0x41, 0x0C, 0x1A, 0xF8],
};

FakeElm327 _createCan11Transport({
  AdapterFaults faults = const AdapterFaults(),
  Map<String, List<int>> extraReplies = const {},
}) => FakeElm327(
  protocol: BusProtocol.can11,
  faults: faults,
  ecus: [
    FakeEcu(
      name: 'ECM',
      requestId: '7E0',
      responseId: '7E8',
      responses: {
        ..._standardPhysicsReplies(),
        '03': [0x43, 0x01, 0x01, 0x33, 0x00, 0x00],
        ...extraReplies,
      },
    ),
  ],
);

Future<Elm327Client> _connect(
  ObdTransport transport, {
  Duration commandTimeout = const Duration(milliseconds: 200),
}) async {
  final client = Elm327Client(transport, commandTimeout: commandTimeout);
  expect(await client.connect(), isTrue, reason: 'Transport handshake must succeed');
  return client;
}

void main() {
  group('R3: Five-Point Finite Control Regression Test Suite', () {
    test('Positive Control 1: H0 receives clean ATH1 ? -> retains H0, anonymous query proceeds', () async {
      final transport = _createCan11Transport(
        faults: const AdapterFaults(refuseHeaders: true),
      );
      final client = await _connect(transport);

      expect(client.headersOn, isFalse, reason: 'Initial client state is H0');
      expect(transport.headersOn, isFalse, reason: 'Initial adapter state is H0');
      expect(client.responseHeadersUncertain, isFalse);

      final before = transport.commandLog.length;
      final reply = await client.sendTransacted(
        '010C',
        header: '7E0',
        responseHeaders: true,
      );

      expect(reply.isSuccess, isTrue);
      expect(reply.headersEnabled, isFalse, reason: 'Reply is anonymous due to clean refusal fallback');

      final log = transport.commandLog.skip(before).toList();
      expect(log, contains('ATH1'));
      expect(log, contains('ATSH7E0'));
      expect(log, contains('010C'));
      expect(log, isNot(contains('ATH0')), reason: 'No ATH0 restore when headers were never turned on');

      expect(client.headersOn, isFalse, reason: 'Must retain H0 without inverting');
      expect(transport.headersOn, isFalse, reason: 'Adapter physically remains H0');
      expect(client.responseHeadersUncertain, isFalse, reason: 'Clean refusal must not set uncertainty');
      expect(client.responseHeadersRestoreFailed, isFalse);

      // Subsequent anonymous query proceeds normally
      final next = await client.send('010C');
      expect(next.isSuccess, isTrue);
      expect(client.headersOn, isFalse);

      await client.disconnect();
    });

    test('Positive Control 2: Established H1 receives clean ATH0 ? -> retains H1, subsequent queries succeed with headered parsing', () async {
      final transport = _createCan11Transport(
        faults: const AdapterFaults(refuseHeadersOff: true),
      );
      final client = await _connect(transport);

      expect(client.headersOn, isFalse);

      // Transaction establishes H1 via ATH1, then ATH0 restore in finally is refused (?)
      final reply = await client.sendTransacted(
        '010C',
        header: '7E0',
        responseHeaders: true,
      );

      expect(reply.isSuccess, isTrue);
      expect(client.headersOn, isTrue, reason: 'Client model truthfully retains H1');
      expect(transport.headersOn, isTrue, reason: 'Adapter physically stays in H1');
      expect(client.responseHeadersRestoreFailed, isFalse);
      expect(client.responseHeadersUncertain, isFalse);

      // Subsequent ordinary send succeeds with headered parsing
      final nextReply = await client.send('010C');
      expect(nextReply.isSuccess, isTrue);
      expect(client.headersOn, isTrue);

      await client.disconnect();
    });

    test('Gap Probe 1: H1 repeated ATH1 ? via sendGlobal(\'03\') -> retains H1 with correct attribution', () async {
      final transport = _createCan11Transport();
      final client = await _connect(transport);

      // Establish H1 state explicitly
      final initH1 = await client.send('ATH1');
      expect(initH1.isSuccess, isTrue);
      expect(client.headersOn, isTrue);
      expect(transport.headersOn, isTrue);

      // Adapter will refuse subsequent repeated ATH1
      transport.forceReply('ATH1', '?');

      final before = transport.commandLog.length;
      final reply = await client.sendGlobal('03');

      expect(reply.isSuccess, isTrue);
      expect(reply.headersEnabled, isTrue, reason: 'Attribution retained via H1 headered parsing');
      expect(reply.rawLines.any((l) => l.contains('7E8')), isTrue, reason: 'Attributed to ECM 7E8');

      final log = transport.commandLog.skip(before).toList();
      expect(log, contains('ATH1'));
      expect(log, contains('ATSH7DF'));
      expect(log, contains('03'));
      expect(log, isNot(contains('ATH0')), reason: 'Must not restore ATH0 when already in H1');

      // Crucial assertion: repeated ATH1 ? must NOT invert or corrupt _headersOn to false
      expect(client.headersOn, isTrue, reason: 'Must retain H1 state upon repeated ATH1 refusal');
      expect(transport.headersOn, isTrue);
      expect(client.responseHeadersUncertain, isFalse);

      // Subsequent queries continue with headered parsing without desynchronization
      final next = await client.send('010C');
      expect(next.isSuccess, isTrue);
      expect(client.headersOn, isTrue);

      await client.disconnect();
    });

    test('Gap Probe 2: H0 repeated ATH0 ? -> retains H0', () async {
      final transport = _createCan11Transport(
        faults: const AdapterFaults(refuseHeadersOff: true),
      );
      final client = await _connect(transport);

      expect(client.headersOn, isFalse, reason: 'Initial state is H0');
      expect(transport.headersOn, isFalse);

      // Send repeated ATH0 while already in H0; adapter returns '?'
      final resp = await client.send('ATH0');
      expect(resp.rawLines.any((l) => l.trim() == '?'), isTrue);

      // Crucial assertion: refusal of ATH0 while in H0 must NOT invert _headersOn to true
      expect(client.headersOn, isFalse, reason: 'Must retain H0 without opposite assumption');
      expect(transport.headersOn, isFalse);
      expect(client.responseHeadersUncertain, isFalse);
      expect(client.responseHeadersRestoreFailed, isFalse);

      // Subsequent anonymous queries proceed without sticky failure
      final next = await client.send('010C');
      expect(next.isSuccess, isTrue);
      expect(client.headersOn, isFalse);

      await client.disconnect();
    });

    test('Gap Probe 3: ATH1 returns DATA ERROR\\r? -> aborts query dispatch, sets uncertainty, and subsequent plain queries are wire-zero rejected', () async {
      final transport = _createCan11Transport();
      final client = await _connect(transport);

      expect(client.headersOn, isFalse);

      // Force corrupted response on ATH1
      transport.forceReply('ATH1', 'DATA ERROR\r?');

      final countBefore = transport.commandLog.length;

      // Transaction must fail-closed on corrupt control response
      await expectLater(
        client.sendTransacted(
          '010C',
          header: '7E0',
          responseHeaders: true,
        ),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.queryHeaderRefused,
          ),
        ),
      );

      // Verify query dispatch was ABORTED: neither ATSH7E0 nor 010C reached the wire
      final logAfterTx = transport.commandLog.skip(countBefore).toList();
      expect(logAfterTx, contains('ATH1'));
      expect(logAfterTx, isNot(contains('ATSH7E0')), reason: 'ATSH dispatch must be aborted');
      expect(logAfterTx, isNot(contains('010C')), reason: 'Data query dispatch must be aborted');

      // Sticky uncertainty must be set
      expect(client.responseHeadersUncertain, isTrue, reason: 'Corrupt response must set sticky uncertainty');

      // Subsequent plain query must be rejected with wire-zero writes
      final countBeforePlain = transport.commandLog.length;
      await expectLater(
        client.send('010C'),
        throwsA(
          isA<TransportException>().having(
            (e) => e.issue,
            'issue',
            TransportIssue.headerRestoreFailed,
          ),
        ),
      );

      expect(
        transport.commandLog.length,
        countBeforePlain,
        reason: 'Subsequent query must be rejected with wire-zero writes',
      );

      await client.disconnect();
    });
  });
}
