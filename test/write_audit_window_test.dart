/// Write-audit windows are per operation, not a shared cleared set.
///
/// Dashboard polling and Mode 04 both ask "did these bytes leave?". Clearing
/// one shared set from each poll batch would let a later `beginWriteAudit`
/// hide a Mode 04 that had already reached the adapter, and the screen would
/// offer an unsafe retry.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/obd/dtc/dtc.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/dtc_scan.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';

import 'support/fake_elm327.dart';

/// Test-only spy transport tracking precise write calls, byte counts,
/// and simulating partial-byte transport resets.
class _PartialWriteSpyTransport extends FakeElm327 {
  _PartialWriteSpyTransport({
    required super.protocol,
    required super.ecus,
  });

  int writeCalls = 0;
  int acceptedBytes = 0;
  int completeCommands = 0;
  bool failWithPartialBytesFor04 = false;

  @override
  Future<void> write(List<int> data) async {
    writeCalls++;
    final raw = ascii.decode(data, allowInvalid: true).trim().toUpperCase();
    if (failWithPartialBytesFor04 && raw == '04') {
      acceptedBytes += 1;
      throw const TransportException(
        'socket write truncated / connection reset',
        issue: null,
      );
    }
    acceptedBytes += data.length;
    completeCommands++;
    return super.write(data);
  }
}

void main() {
  test(
    'a later poll write-audit does not hide a Mode 04 that already left',
    () async {
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: {
              '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
              '04': [0x44],
            },
          ),
        ],
      );
      transport.silenceFor.add('04');
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 400),
      );
      expect(await client.connect(), isTrue);

      final clearAudit = client.beginWriteAudit();
      final pending = client.sendGlobal('04', writeAudit: clearAudit);
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (!transport.commandLog.contains('04')) {
        if (DateTime.now().isAfter(deadline)) {
          fail(
            '04 never reached the adapter. Commands: ${transport.commandLog}',
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      // A dashboard poll batch starts its own window while 04 is in flight.
      client.beginWriteAudit();
      expect(
        client.wroteSinceAudit(clearAudit, '04'),
        isTrue,
        reason:
            'Mode 04 already left; a later poll audit must not permit a retry. '
            'Commands: ${transport.commandLog}',
      );
      await expectLater(pending, throwsA(anything));
    },
  );

  test('a queued send cannot be borrowed by a later audit', () async {
    final transport = FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: {
            '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
            '04': [0x44],
          },
        ),
      ],
    );
    final client = Elm327Client(transport);
    expect(await client.connect(), isTrue);
    addTearDown(client.disconnect);
    final first = client.beginWriteAudit();
    final pending = client.sendGlobal('04', writeAudit: first);
    final unrelated = client.beginWriteAudit();
    await pending;
    expect(client.wroteSinceAudit(first, '04'), isTrue);
    expect(
      client.wroteSinceAudit(unrelated, '04'),
      isFalse,
      reason: 'the later operation did not enqueue or write this command',
    );
  });

  test('a new window does not inherit a previous Mode 04 write', () async {
    final transport = FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: {
            '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
            '04': [0x44],
          },
        ),
      ],
    );
    final client = Elm327Client(
      transport,
      commandTimeout: const Duration(milliseconds: 400),
    );
    expect(await client.connect(), isTrue);
    final first = client.beginWriteAudit();
    await client.sendGlobal('04', writeAudit: first);
    expect(client.wroteSinceAudit(first, '04'), isTrue);
    final second = client.beginWriteAudit();
    expect(
      client.wroteSinceAudit(second, '04'),
      isFalse,
      reason: 'the second attempt must not lock a retry on the first write',
    );
  });
  for (final protocol in BusProtocol.values) {
    test(
      'receipts follow global and default sends on ${protocol.name}',
      () async {
        final transport = FakeElm327(
          protocol: protocol,
          ecus: [
            FakeEcu(
              name: 'ECM',
              requestId: protocol.engineHeader,
              responseId: protocol.isCan
                  ? (protocol.is29Bit ? '18DAF110' : '7E8')
                  : '486B10',
              responses: {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
                '04': [0x44],
              },
            ),
          ],
        );
        final client = Elm327Client(transport);
        expect(await client.connect(), isTrue);
        addTearDown(client.disconnect);
        final global = client.beginWriteAudit();
        final defaultSend = client.beginWriteAudit();
        await client.sendGlobal('04', writeAudit: global);
        await client.sendAddressed('7E0', '0100', writeAudit: defaultSend);
        expect(client.wroteSinceAudit(global, '04'), isTrue);
        expect(client.wroteSinceAudit(global, '0100'), isFalse);
        expect(client.wroteSinceAudit(defaultSend, '0100'), isTrue);
        expect(client.wroteSinceAudit(defaultSend, '04'), isFalse);
      },
    );
  }

  test('a synchronously refused addressed send consumes its receipt', () async {
    final transport = FakeElm327(
      protocol: BusProtocol.j1850vpw,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '6C10F1',
          responseId: '486B10',
          responses: {
            '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
          },
        ),
      ],
    );
    final client = Elm327Client(transport);
    expect(await client.connect(), isTrue);
    addTearDown(client.disconnect);
    await client.sendOnHeader('6C10F1', '0100');
    final refused = client.beginWriteAudit();
    final before = List<String>.of(transport.commandLog);
    expect(
      () => client.sendAddressed('7E0', '0100', writeAudit: refused),
      throwsA(isA<UnaddressableRequestException>()),
    );
    expect(client.wroteSinceAudit(refused, '0100'), isFalse);
    await expectLater(
      Future.sync(() => client.send('0100', writeAudit: refused)),
      throwsArgumentError,
    );
    expect(transport.commandLog, before);
    expect(client.wroteSinceAudit(refused, '0100'), isFalse);
  });

  group('explicit operation receipts', () {
    late FakeElm327 transport;
    late Elm327Client client;
    setUp(() async {
      transport = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: {
              '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
              '04': [0x44],
            },
          ),
        ],
      );
      client = Elm327Client(transport);
      expect(await client.connect(), isTrue);
    });
    tearDown(() => client.disconnect());

    test('unassociated commands never populate an open receipt', () async {
      final audit = client.beginWriteAudit();
      await client.sendGlobal('04');
      expect(client.wroteSinceAudit(audit, '04'), isFalse);
    });

    test(
      'receipt belongs to its send, not audit creation or queue order',
      () async {
        final first = client.beginWriteAudit();
        final second = client.beginWriteAudit();
        await client.sendGlobal('04', writeAudit: second);
        transport.refuseWriteBeforeAcceptingFor = const {'04'};
        await expectLater(
          client.sendGlobal('04', writeAudit: first),
          throwsA(anything),
        );
        expect(client.wroteSinceAudit(first, '04'), isFalse);
        expect(client.wroteSinceAudit(second, ' 04 '), isTrue);
      },
    );

    test('direct and addressed sends record only their own receipt', () async {
      final direct = client.beginWriteAudit();
      final addressed = client.beginWriteAudit();
      await client.send('0100', writeAudit: direct);
      expect(client.wroteSinceAudit(direct, '0100'), isTrue);
      expect(client.wroteSinceAudit(addressed, '0100'), isFalse);
      await client.sendAddressed('7E0', '0100', writeAudit: addressed);
      expect(client.wroteSinceAudit(addressed, '0100'), isTrue);
      expect(client.wroteSinceAudit(addressed, 'ATSH7E0'), isTrue);
    });

    test(
      'reusing a receipt is refused before another wire operation',
      () async {
        final audit = client.beginWriteAudit();
        await client.sendGlobal('04', writeAudit: audit);
        // Wait until the global exchange has restored headers.
        await client.send('ATRV');
        final before = List<String>.of(transport.commandLog);
        expect(
          () => client.sendGlobal('04', writeAudit: audit),
          throwsArgumentError,
        );
        expect(transport.commandLog, before);
        expect(client.wroteSinceAudit(audit, '04'), isTrue);
        expect(client.wroteSinceAudit(audit, 'ATH0'), isTrue);
      },
    );

    test('a receipt cannot be used or read through a different client', () {
      final other = Elm327Client(
        FakeElm327(protocol: BusProtocol.can11, ecus: []),
      );
      final foreign = other.beginWriteAudit();
      final before = List<String>.of(transport.commandLog);
      expect(() => client.send('04', writeAudit: foreign), throwsArgumentError);
      expect(() => client.wroteSinceAudit(foreign, '04'), throwsArgumentError);
      expect(transport.commandLog, before);
    });
  });

  group('W101 finite acceptance matrix', () {
    late FakeElm327 transport;
    late Elm327Client client;

    setUp(() async {
      transport = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: {
              '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
              '010C': [0x41, 0x0C, 0x1A, 0xF8],
              '04': [0x44],
            },
          ),
        ],
      );
      client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 400),
      );
      expect(await client.connect(), isTrue);
    });

    tearDown(() async {
      await client.disconnect();
    });

    test(
      'W101-01: historical repair and current source token contract reconciliation',
      () {
        // Reconciles commit 4c575f63 with current source in elm327_client.dart.
        final audit = client.beginWriteAudit();
        expect(audit, isA<ElmWriteAudit>());
        expect(client.wroteSinceAudit(audit, '04'), isFalse);
        expect(client.wroteSinceAudit(audit, ' 04 '), isFalse);
        expect(client.wroteSinceAudit(audit, ''), isFalse);

        final otherClient = Elm327Client(
          FakeElm327(protocol: BusProtocol.can11, ecus: const []),
        );
        addTearDown(otherClient.disconnect);
        expect(
          () => otherClient.wroteSinceAudit(audit, '04'),
          throwsArgumentError,
          reason: 'a receipt cannot be inspected by a different client',
        );
      },
    );

    test(
      'W101-02: same-command and different-command A/B interleaving isolation',
      () async {
        // 1. Same-command in-flight queueing isolation:
        // Both operations request '04'. A is in-flight on the wire awaiting response;
        // B is queued behind A. B's receipt must remain false until B is actually dispatched.
        final aBarrier = Completer<void>();
        var barrierActive = true;
        transport.responseBarrier =
            (cmd) => (cmd == '04' && barrierActive) ? aBarrier.future : null;

        final auditA = client.beginWriteAudit();
        final auditB = client.beginWriteAudit();

        final fA = client.sendGlobal('04', writeAudit: auditA);
        // Allow A to reach wire and hold at barrier
        await Future<void>.delayed(const Duration(milliseconds: 25));

        expect(
          transport.commandLog.where((c) => c.trim() == '04').length,
          equals(1),
        );
        expect(client.wroteSinceAudit(auditA, '04'), isTrue);

        // Queue B behind A for the exact same command ('04')
        final fB = client.sendGlobal('04', writeAudit: auditB);
        await Future<void>.delayed(const Duration(milliseconds: 25));

        // Mid-flight assertion: B is queued but NOT dispatched.
        // Proves A's write does NOT contaminate B's receipt even with identical commands!
        expect(
          transport.commandLog.where((c) => c.trim() == '04').length,
          equals(1),
        );
        expect(client.wroteSinceAudit(auditA, '04'), isTrue);
        expect(
          client.wroteSinceAudit(auditB, '04'),
          isFalse,
          reason: 'B is queued and has not reached wire; A must not contaminate B',
        );

        // Release A's barrier so A finishes and B is dispatched
        barrierActive = false;
        aBarrier.complete();
        await fA;
        await fB;

        final cmd04Count =
            transport.commandLog.where((c) => c.trim() == '04').length;
        expect(cmd04Count, equals(2), reason: 'both operations reached wire');
        expect(client.wroteSinceAudit(auditA, '04'), isTrue);
        expect(client.wroteSinceAudit(auditB, '04'), isTrue);

        // 2. Different-command interleaving: '0100' and '010C' stay strictly isolated.
        final auditC = client.beginWriteAudit();
        final auditD = client.beginWriteAudit();

        await client.send('0100', writeAudit: auditC);
        await client.send('010C', writeAudit: auditD);

        expect(client.wroteSinceAudit(auditC, '0100'), isTrue);
        expect(client.wroteSinceAudit(auditC, '010C'), isFalse);
        expect(client.wroteSinceAudit(auditD, '010C'), isTrue);
        expect(client.wroteSinceAudit(auditD, '0100'), isFalse);
      },
    );

    test(
      'W101-03: queued operation is not dispatched while wire is held (barrier proof)',
      () async {
        final blockerBarrier = Completer<void>();
        transport.responseBarrier =
            (cmd) => cmd == '0100' ? blockerBarrier.future : null;

        final auditBlocker = client.beginWriteAudit();
        final auditQueued = client.beginWriteAudit();

        final fBlocker = client.send('0100', writeAudit: auditBlocker);
        final fQueued = client.send('04', writeAudit: auditQueued);

        // Allow microtasks to run and blocker to enter wire.
        await Future<void>.delayed(const Duration(milliseconds: 25));

        expect(transport.commandLog, contains('0100'));
        expect(transport.commandLog, isNot(contains('04')));
        expect(client.wroteSinceAudit(auditBlocker, '0100'), isTrue);
        expect(
          client.wroteSinceAudit(auditQueued, '04'),
          isFalse,
          reason:
              'queued send has not been dispatched; false is not a terminal unsent proof',
        );

        blockerBarrier.complete();
        await fBlocker;
        await fQueued;

        expect(transport.commandLog, contains('04'));
        expect(client.wroteSinceAudit(auditQueued, '04'), isTrue);
        expect(client.wroteSinceAudit(auditBlocker, '04'), isFalse);
      },
    );

    test(
      'W101-04: single-use token rejection across queued, completed, and synchronous refusal states',
      () async {
        final blockerBarrier = Completer<void>();
        transport.responseBarrier =
            (cmd) => cmd == '0100' ? blockerBarrier.future : null;

        final audit = client.beginWriteAudit();
        final f1 = client.send('0100', writeAudit: audit);

        // Re-use while queued / in-flight
        expect(
          () => client.send('04', writeAudit: audit),
          throwsArgumentError,
          reason: 'cannot reuse token that is currently in flight',
        );

        blockerBarrier.complete();
        await f1;

        // Re-use after completion
        expect(
          () => client.send('010C', writeAudit: audit),
          throwsArgumentError,
          reason: 'cannot reuse token after completion',
        );

        // Re-use after synchronous legacy refusal
        final legacyTransport = FakeElm327(
          protocol: BusProtocol.j1850vpw,
          ecus: [
            FakeEcu(
              name: 'ECM',
              requestId: '6C10F1',
              responseId: '486B10',
              responses: {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
              },
            ),
          ],
        );
        final legacyClient = Elm327Client(legacyTransport);
        expect(await legacyClient.connect(), isTrue);
        addTearDown(legacyClient.disconnect);
        await legacyClient.sendOnHeader('6C10F1', '0100');

        final auditRefused = legacyClient.beginWriteAudit();
        expect(
          () => legacyClient.sendAddressed(
            '7E0',
            '0100',
            writeAudit: auditRefused,
          ),
          throwsA(isA<UnaddressableRequestException>()),
        );
        expect(
          () => legacyClient.send('0100', writeAudit: auditRefused),
          throwsArgumentError,
          reason:
              'synchronously refused token is consumed and cannot be reused',
        );

        // Positive control: fresh token works normally
        final freshAudit = client.beginWriteAudit();
        await client.send('010C', writeAudit: freshAudit);
        expect(client.wroteSinceAudit(freshAudit, '010C'), isTrue);
      },
    );

    test(
      'W101-05: foreign token rejection with zero contamination of both clients',
      () async {
        final transport2 = FakeElm327(
          protocol: BusProtocol.can11,
          ecus: [
            FakeEcu(
              name: 'ECM',
              requestId: '7E0',
              responseId: '7E8',
              responses: {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
              },
            ),
          ],
        );
        final client2 = Elm327Client(transport2);
        expect(await client2.connect(), isTrue);
        addTearDown(client2.disconnect);

        final audit1 = client.beginWriteAudit();
        final wireBefore2 = List<String>.of(transport2.commandLog);

        expect(
          () => client2.send('0100', writeAudit: audit1),
          throwsArgumentError,
        );
        expect(
          () => client2.wroteSinceAudit(audit1, '0100'),
          throwsArgumentError,
        );
        expect(
          transport2.commandLog,
          equals(wireBefore2),
          reason: 'client2 wire untouched',
        );

        // Client 1's token is intact and can be claimed by client 1
        await client.send('0100', writeAudit: audit1);
        expect(client.wroteSinceAudit(audit1, '0100'), isTrue);
      },
    );

    test(
      'W101-06: pre-handoff retirement while queued produces zero wire delivery and preserves generation separation',
      () async {
        var allowOwner1 = true;
        client.mayTransmit = (owner) {
          if (owner == 'owner-1') return allowOwner1;
          return true;
        };

        final blockerBarrier = Completer<void>();
        transport.responseBarrier =
            (cmd) => cmd == '0100' ? blockerBarrier.future : null;

        final blockerAudit = client.beginWriteAudit();
        final queuedAudit = client.beginWriteAudit();

        // 1. Dispatch in-flight blocker
        final fBlocker = client.send('0100', writeAudit: blockerAudit);
        await Future<void>.delayed(const Duration(milliseconds: 25));

        // 2. Queue Operation B behind blocker under owner-1
        final wireBeforeB = List<String>.of(transport.commandLog);
        final fQueued = client.sendGlobal(
          '04',
          owner: 'owner-1',
          writeAudit: queuedAudit,
        );
        await Future<void>.delayed(const Duration(milliseconds: 25));

        // Verify B is in queue and has NOT reached wire
        expect(transport.commandLog, equals(wireBeforeB));
        expect(client.wroteSinceAudit(queuedAudit, '04'), isFalse);

        // 3. Revoke owner-1 authorization while B is already waiting in queue!
        allowOwner1 = false;

        // 4. Release blocker
        blockerBarrier.complete();
        await fBlocker;

        // 5. B is dequeued, pre-handoff check fails and throws OperationRetiredException
        await expectLater(
          fQueued,
          throwsA(isA<OperationRetiredException>()),
          reason: 'B was retired while queued before wire handoff',
        );

        // Verify B never reached wire and its token cannot be reused
        expect(
          transport.commandLog.where((c) => c.trim() == '04').length,
          equals(0),
          reason: 'zero wire commands dispatched for retired queued operation',
        );
        expect(client.wroteSinceAudit(queuedAudit, '04'), isFalse);
        expect(
          () => client.send('0100', writeAudit: queuedAudit),
          throwsArgumentError,
          reason: 'retired token is consumed and cannot be reused',
        );

        // 6. Subsequent active owner with fresh token succeeds cleanly
        final freshAudit = client.beginWriteAudit();
        await client.sendGlobal(
          '04',
          owner: 'owner-2',
          writeAudit: freshAudit,
        );
        expect(
          transport.commandLog.where((c) => c.trim() == '04').length,
          equals(1),
        );
        expect(client.wroteSinceAudit(freshAudit, '04'), isTrue);
      },
    );

    test(
      'W101-07: proven-zero rollback on WriteRefusedException preserves consumed token and prior writes',
      () async {
        transport.refuseWriteBeforeAcceptingFor = const {'04'};
        final audit = client.beginWriteAudit();

        await expectLater(
          client.sendAddressed('7E0', '04', writeAudit: audit),
          throwsA(isA<WriteRefusedException>()),
        );

        expect(
          client.wroteSinceAudit(audit, '04'),
          isFalse,
          reason:
              'proven zero-byte refusal rolls back the rejected command',
        );
        expect(
          client.wroteSinceAudit(audit, 'ATSH7E0'),
          isTrue,
          reason:
              'prior write within the same receipt is preserved and not rolled back',
        );
        expect(
          () => client.send('0100', writeAudit: audit),
          throwsArgumentError,
          reason: 'receipt remains consumed and cannot be reused',
        );
      },
    );

    test(
      'W101-08: partial byte and write completion stall maintain conservative evidence with zero replay',
      () async {
        // Sub-case A: Partial byte write failure
        final spyTransport = _PartialWriteSpyTransport(
          protocol: BusProtocol.can11,
          ecus: [
            FakeEcu(
              name: 'ECM',
              requestId: '7E0',
              responseId: '7E8',
              responses: {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
                '04': [0x44],
              },
            ),
          ],
        );
        final spyClient = Elm327Client(spyTransport);
        expect(await spyClient.connect(), isTrue);
        addTearDown(spyClient.disconnect);

        final writesBefore = spyTransport.writeCalls;
        final bytesBefore = spyTransport.acceptedBytes;
        final commandsBefore = spyTransport.completeCommands;

        spyTransport.failWithPartialBytesFor04 = true;
        final auditPartial = spyClient.beginWriteAudit();

        await expectLater(
          spyClient.send('04', writeAudit: auditPartial),
          throwsA(isA<TransportException>()),
        );

        // Verify spy tracking:
        // - exactly 1 write call was attempted (no automatic replay)
        // - acceptedBytes > 0 (partial bytes entered wire buffer)
        // - completeCommands == 0 (command was NOT completely delivered)
        // - wroteSinceAudit is CONSERVATIVELY true because bytes were partially accepted
        expect(
          spyTransport.writeCalls - writesBefore,
          equals(1),
          reason: 'no automatic replay on write failure',
        );
        expect(
          spyTransport.acceptedBytes - bytesBefore,
          greaterThan(0),
          reason: 'partial bytes entered wire',
        );
        expect(
          spyTransport.completeCommands - commandsBefore,
          equals(0),
          reason: 'complete command count is 0',
        );
        expect(
          spyClient.wroteSinceAudit(auditPartial, '04'),
          isTrue,
          reason: 'partial write conservatively records possibly-sent receipt',
        );

        // Sub-case B: Write completion stall
        // Transport accepts bytes and generates reply, but transport.write Future hangs
        final stallTransport = FakeElm327(
          protocol: BusProtocol.can11,
          ecus: [
            FakeEcu(
              name: 'ECM',
              requestId: '7E0',
              responseId: '7E8',
              responses: {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
                '04': [0x44],
              },
            ),
          ],
        );
        final stallClient = Elm327Client(
          stallTransport,
          commandTimeout: const Duration(milliseconds: 200),
          writeTimeout: const Duration(milliseconds: 80),
        );
        expect(await stallClient.connect(), isTrue);
        addTearDown(stallClient.disconnect);

        stallTransport.stallWriteCompletion = true;
        final auditStall = stallClient.beginWriteAudit();

        // The call will time out because write Future never completes
        await expectLater(
          stallClient.send('04', writeAudit: auditStall),
          throwsA(isA<TimeoutException>()),
        );

        // Even though write Future never settled, bytes reached the adapter!
        expect(stallTransport.commandLog, contains('04'));
        expect(
          stallClient.wroteSinceAudit(auditStall, '04'),
          isTrue,
          reason: 'write completion stall maintains conservative write receipt',
        );
      },
    );

    test(
      'W101-09: caller wrapper timeout isolation and late reply queueing isolation',
      () async {
        final delayedReply = Completer<void>();
        transport.responseBarrier =
            (cmd) => cmd == '04' ? delayedReply.future : null;
        final audit1 = client.beginWriteAudit();
        final audit2 = client.beginWriteAudit();

        final logLengthBefore = transport.commandLog.length;
        final rawFuture1 = client.sendGlobal('04', writeAudit: audit1);
        await Future<void>.delayed(const Duration(milliseconds: 25));

        // Caller wrapper times out early while command is on the wire
        await expectLater(
          rawFuture1.timeout(const Duration(milliseconds: 30)),
          throwsA(isA<TimeoutException>()),
        );

        expect(
          client.wroteSinceAudit(audit1, '04'),
          isTrue,
          reason: 'bytes left the app before caller wrapper timed out',
        );

        // Queue Operation 2 ('ATRV') WHILE Operation 1's reply is STILL HELD at barrier!
        final rawFuture2 = client.send('ATRV', writeAudit: audit2);
        await Future<void>.delayed(const Duration(milliseconds: 25));

        // Mid-flight isolation verification:
        // Operation 2 is queued behind Operation 1.
        // Operation 2 has NOT dispatched ATRV yet.
        // Operation 2 does NOT borrow Operation 1's '04' receipt.
        expect(client.wroteSinceAudit(audit2, 'ATRV'), isFalse);
        expect(
          client.wroteSinceAudit(audit2, '04'),
          isFalse,
          reason: 'queued operation does not borrow pending operation receipt',
        );

        // Now release Operation 1's late reply
        delayedReply.complete();

        final res1 = await rawFuture1;
        final res2 = await rawFuture2;

        // Both operations completed with their distinct responses and semantic attribution:
        expect(
          res1.rawLines.any((l) => l.contains('44')),
          isTrue,
          reason: 'res1 contains positive Mode 04 payload',
        );
        expect(
          res1.rawLines.any((l) => l.contains('13.9V')),
          isFalse,
          reason: 'res1 does not contain voltage output from ATRV',
        );
        expect(
          res2.rawLines.any((l) => l.contains('13.9V')),
          isTrue,
          reason: 'res2 contains designated ATRV voltage text',
        );
        expect(
          res2.rawLines.any((l) => l.contains('44')),
          isFalse,
          reason: 'res2 does not contain Mode 04 payload',
        );

        // Wire dispatch order and count: 04 dispatched before ATRV, exactly 1 each in this scope
        final testCommands = transport.commandLog.sublist(logLengthBefore);
        final idx04 = testCommands.indexOf('04');
        final idxAtrv = testCommands.indexOf('ATRV');
        expect(idx04, greaterThanOrEqualTo(0));
        expect(idxAtrv, greaterThan(idx04), reason: '04 dispatched before ATRV');
        expect(
          testCommands.where((c) => c.trim() == '04').length,
          equals(1),
        );
        expect(
          testCommands.where((c) => c.trim() == 'ATRV').length,
          equals(1),
        );

        // Final receipt isolation verification:
        expect(client.wroteSinceAudit(audit1, '04'), isTrue);
        expect(client.wroteSinceAudit(audit1, 'ATRV'), isFalse);
        expect(client.wroteSinceAudit(audit2, 'ATRV'), isTrue);
        expect(client.wroteSinceAudit(audit2, '04'), isFalse);
      },
    );

    test(
      'W101-10: setup, service, and restore boundaries in composite exchanges',
      () async {
        // Sub-case A: Setup refusal: ATH1 refused before wire
        transport.refuseWriteBeforeAcceptingFor = const {'ATH1'};
        final auditRefused = client.beginWriteAudit();

        await expectLater(
          client.sendGlobal('04', writeAudit: auditRefused),
          throwsA(isA<WriteRefusedException>()),
        );
        expect(client.wroteSinceAudit(auditRefused, 'ATH1'), isFalse);
        expect(client.wroteSinceAudit(auditRefused, '04'), isFalse);

        // Sub-case B: Service success and restore: restore ATH0 does not erase 04
        transport.refuseWriteBeforeAcceptingFor = const {};
        final ath0Entered = Completer<void>();
        final ath0Release = Completer<void>();
        transport.responseBarrier = (cmd) {
          if (cmd.trim() == 'ATH0') {
            if (!ath0Entered.isCompleted) ath0Entered.complete();
            return ath0Release.future;
          }
          return null;
        };

        final auditSuccess = client.beginWriteAudit();
        final resultFuture = client.sendGlobal('04', writeAudit: auditSuccess);

        // 1. The public Future completes with the service response:
        final result = await resultFuture;
        expect(result.rawLines, isNotEmpty);

        // 2. At this point, the finally block has initiated restore ATH0,
        // which entered transport and is held at the response barrier.
        await ath0Entered.future;
        expect(
          client.headersOn,
          isTrue,
          reason: 'headers remain on in client state until restore ATH0 is acknowledged',
        );
        expect(
          client.wroteSinceAudit(auditSuccess, 'ATH0'),
          isTrue,
          reason: 'ATH0 handoff evidence is already recorded',
        );

        // 3. Release the ATH0 reply ('OK') and observe client model convergence:
        ath0Release.complete();
        final deadline = DateTime.now().add(const Duration(milliseconds: 500));
        while (client.headersOn && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        expect(
          client.headersOn,
          isFalse,
          reason: 'client state converged: headers successfully restored to off',
        );

        // 4. Verify complete exact sub-sequence in commandLog: ATH1 -> ATSH 7DF -> 04 -> ATH0
        final log = transport.commandLog.map((c) => c.trim()).toList();
        final idxAth1 = log.indexOf('ATH1');
        final idxAtsh = log.indexWhere((c) => c.startsWith('ATSH'));
        final idx04 = log.indexOf('04');
        final idxAth0 = log.lastIndexOf('ATH0');

        expect(idxAth1, greaterThanOrEqualTo(0));
        expect(idxAtsh, greaterThan(idxAth1), reason: 'ATSH follows ATH1');
        expect(idx04, greaterThan(idxAtsh), reason: '04 follows ATSH');
        expect(idxAth0, greaterThan(idx04), reason: 'ATH0 follows 04');

        expect(client.wroteSinceAudit(auditSuccess, 'ATH1'), isTrue);
        expect(client.wroteSinceAudit(auditSuccess, '04'), isTrue);
        expect(client.wroteSinceAudit(auditSuccess, 'ATH0'), isTrue);
      },
    );

    test(
      'W101-11: real consumer engine verification (clear retry lock, subsequent polling observation, and latch retention)',
      () async {
        // Part 1: Clear dropped after 04 sent -> repeatWouldHarm is true
        final transportDropped = FakeElm327(
          protocol: BusProtocol.can11,
          ecus: [
            FakeEcu(
              name: 'ECM',
              requestId: '7E0',
              responseId: '7E8',
              responses: {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
                '010C': [0x41, 0x0C, 0x1A, 0xF8],
                '04': [0x44],
              },
            ),
          ],
        );
        transportDropped.failWriteAfterAcceptingFor = const {'04'};
        final clientDropped = Elm327Client(
          transportDropped,
          commandTimeout: const Duration(milliseconds: 300),
        );
        expect(await clientDropped.connect(), isTrue);
        final engineDropped = PollingEngine(clientDropped);
        addTearDown(() async {
          await engineDropped.dispose();
          await clientDropped.disconnect();
        });

        await expectLater(
          engineDropped.clearDtcs(),
          throwsA(
            isA<DtcReadException>()
                .having((e) => e.repeatWouldHarm, 'repeatWouldHarm', isTrue)
                .having(
                  (e) => e.message,
                  'message',
                  contains('do not send another clear'),
                ),
          ),
          reason:
              'clear was on the wire; retry must be locked to prevent emissions reset',
        );

        // Part 2: Subsequent polling observation:
        // Normal sensor polling runs subsequent queries (Mode 01).
        // This must NOT wipe or reset the clear audit evidence!
        final postClearAudit = clientDropped.beginWriteAudit();
        await clientDropped.send('0100', writeAudit: postClearAudit);
        expect(clientDropped.wroteSinceAudit(postClearAudit, '0100'), isTrue);
        expect(clientDropped.wroteSinceAudit(postClearAudit, '04'), isFalse);

        // Part 3: Consumer State Latch Retention (DtcScanState):
        // Exercises Riverpod dtcScanProvider latch retention across reconnection and polling
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final latchAdapter = FakeElm327(
          protocol: BusProtocol.can11,
          ecus: [
            FakeEcu(
              name: 'ECM',
              requestId: '7E0',
              responseId: '7E8',
              responses: {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
                '03': [0x43, 0x01, 0x03, 0x01],
                '07': [0x47, 0x00],
                '0A': [0x4A, 0x00],
                '04': [0x44],
              },
            ),
          ],
        )..dropLinkAfterWritingFor = const {'04'};

        final session = container.read(obdSessionProvider.notifier);
        await session.connectForTest(latchAdapter, TransportKind.wifi);

        final scan = container.read(dtcScanProvider.notifier);
        await scan.scan();
        expect(container.read(dtcScanProvider).totalCodes, greaterThan(0));

        // Clear fails because link dropped after '04' was sent
        await scan.clear();
        final scanState = container.read(dtcScanProvider);
        expect(
          scanState.clearRepeatWouldHarm,
          isTrue,
          reason: 'latch locked because bytes went out',
        );
        expect(
          scanState.clearNotice?.kind,
          equals(DtcClearNoticeKind.engineFailure),
        );

        // Subsequent state / reconnect / polling must NOT unlock the latch!
        final reconnectAdapter = FakeElm327(
          protocol: BusProtocol.can11,
          ecus: [
            FakeEcu(
              name: 'ECM',
              requestId: '7E0',
              responseId: '7E8',
              responses: {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
                '010C': [0x41, 0x0C, 0x1A, 0xF8],
                '03': [0x43, 0x00],
                '07': [0x47, 0x00],
                '0A': [0x4A, 0x00],
              },
            ),
          ],
        );
        await session.connectForTest(reconnectAdapter, TransportKind.wifi);
        final reconnectedState = container.read(dtcScanProvider);
        expect(
          reconnectedState.clearRepeatWouldHarm,
          isTrue,
          reason:
              'latch is retained across reconnect and cannot be cleared by subsequent connection',
        );

        // Execute an actual polling batch in this same session & container flow:
        final snapshotFuture = session.engine!.snapshots.first;
        session.engine!.setActivePids([PidLibrary.engineRpm]);
        session.engine!.start();
        final snapshot = await snapshotFuture;
        await session.engine!.stop();

        // 1. Polling batch actually dispatched to wire and completed:
        expect(
          snapshot.readings.isNotEmpty,
          isTrue,
          reason: 'polling batch successfully produced telemetry readings',
        );
        expect(
          reconnectAdapter.commandLog.any((c) => c.contains('010C')),
          isTrue,
          reason: 'polling query 010C dispatched to wire',
        );

        // 2. Receipt belongs to that polling batch; no extra 04 was transmitted:
        expect(
          reconnectAdapter.commandLog.where((c) => c.trim() == '04'),
          isEmpty,
          reason: 'no additional Mode 04 was transmitted during or after polling',
        );

        // 3. The same clearRepeatWouldHarm latch remains firmly locked across the polling cycle:
        final postPollState = container.read(dtcScanProvider);
        expect(
          postPollState.clearRepeatWouldHarm,
          isTrue,
          reason:
              'polling does not unlock or wipe the vehicle clear latch on the same session',
        );

        // Part 4: Case B: Transport refused '04' before wire -> safe to retry
        final transportRefused = FakeElm327(
          protocol: BusProtocol.can11,
          ecus: [
            FakeEcu(
              name: 'ECM',
              requestId: '7E0',
              responseId: '7E8',
              responses: {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
                '04': [0x44],
              },
            ),
          ],
        );
        transportRefused.refuseWriteBeforeAcceptingFor = const {'04'};
        final clientRefused = Elm327Client(transportRefused);
        expect(await clientRefused.connect(), isTrue);
        final engineRefused = PollingEngine(clientRefused);
        addTearDown(() async {
          await engineRefused.dispose();
          await clientRefused.disconnect();
        });

        await expectLater(
          engineRefused.clearDtcs(),
          throwsA(
            isA<DtcReadException>()
                .having((e) => e.repeatWouldHarm, 'repeatWouldHarm', isFalse)
                .having(
                  (e) => e.message,
                  'message',
                  contains('failed before it was sent'),
                ),
          ),
          reason: 'transport refused write before wire; safe to retry',
        );
      },
    );

    test('W101-12: gate and resource cleanup', () async {
      expect(transport.isConnected, isTrue);
      await client.disconnect();
      expect(transport.isConnected, isFalse);
    });
  });
}
