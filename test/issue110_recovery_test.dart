/// Issue #110 recovery: missing prompt after a complete ISO-TP batch, and
/// repeated `015E` `NO DATA`.
///
/// Offline fixture replay of the sanitized excerpt under
/// `test/fixtures/issue109/`. Not adapter or on-vehicle validation.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/adapter_identity.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/elm_session_profile.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/telemetry.dart';

import 'support/fake_elm327.dart';

/// Third `010C0D04110B10` body from the sanitized excerpt (complete ISO-TP,
/// no prompt on the wire).
const _issue110ThirdBatch =
    '7E8100F410C0B560D00\r'
    '7E821042011250B6110\r'
    '7E8220158AAAAAAAAAA\r'
    '7E9100A410C0B5C0D00\r'
    '7E92104201125AAAAAA';

const _issue110PromptedBatch =
    '7E8100F410C0B520D00\r'
    '7E821042011250B6110\r'
    '7E8220160AAAAAAAAAA\r'
    '7E9100A410C0B380D00\r'
    '7E92104201125AAAAAA';

FakeEcu _ecm() => FakeEcu(
  name: 'ECM',
  requestId: '7FF',
  responseId: '7E8',
  responses: {
    '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
    '0120': [0x41, 0x20, 0xA0, 0x07, 0xB0, 0x11],
    '0140': [0x41, 0x40, 0xFE, 0xD0, 0x84, 0x10],
    '010C': [0x41, 0x0C, 0x0B, 0x56],
    '010D': [0x41, 0x0D, 0x00],
    '0104': [0x41, 0x04, 0x20],
    '0111': [0x41, 0x11, 0x25],
    '010B': [0x41, 0x0B, 0x61],
    '0110': [0x41, 0x10, 0x01, 0x58],
  },
);

FakeEcu _tcm() => FakeEcu(
  name: 'TCM',
  requestId: '7E1',
  responseId: '7E9',
  responses: {
    '0100': [0x41, 0x00, 0x98, 0x18, 0x80, 0x11],
    '010C': [0x41, 0x0C, 0x0B, 0x5C],
    '010D': [0x41, 0x0D, 0x00],
  },
);

FakeElm327 _issue110Adapter() => FakeElm327(
  protocol: BusProtocol.can11,
  identity: 'ELM327 v1.5',
  deviceDescription: 'ICSolution',
  ecus: [_ecm(), _tcm()],
);

void main() {
  group('missing prompt after a complete multi-ECU batch', () {
    test('recovers on the third 010C0D04110B10 and keeps the link', () async {
      final transport = _issue110Adapter();
      var lost = 0;
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 800),
      )..onConnectionLost = () => lost++;
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      expect(
        client.adapterIdentity.concerns.map((c) => c.kind),
        contains(AdapterConcernKind.firmwareNeverReleased),
      );

      final ath1 = await client.send('ATH1');
      expect(ath1.isSuccess, isTrue);

      transport.forceReplySequence('010C0D04110B10', [
        _issue110PromptedBatch,
        _issue110PromptedBatch,
        _issue110ThirdBatch,
        _issue110PromptedBatch,
      ]);
      transport.omitPromptOnOccurrence['010C0D04110B10'] = 3;

      final first = await client.send('010C0D04110B10');
      expect(first.isSuccess, isTrue);
      expect(first.frames.map((f) => f.sourceId).toSet(), {'7E8', '7E9'});

      final second = await client.send('010C0D04110B10');
      expect(second.isSuccess, isTrue);

      final third = await client.send('010C0D04110B10');
      expect(
        third.isSuccess,
        isTrue,
        reason:
            'complete ISO-TP without `>` must complete at timeout, not drop. '
            'error=${third.errorCode} lines=${third.rawLines}',
      );
      expect(client.promptlessCompleteCount, greaterThanOrEqualTo(1));
      expect(client.isInitialized, isTrue);
      expect(lost, 0);
      expect(
        client.transcript.render(),
        contains('Reply completed without a prompt'),
      );
      expect(
        client.transcript.render(),
        isNot(contains('adapter link dropped')),
      );

      final fourth = await client.send('010C0D04110B10');
      expect(
        fourth.isSuccess,
        isTrue,
        reason: 'polling continues after recovery',
      );
      expect(lost, 0);
      expect(client.isInitialized, isTrue);
    });

    test('a late empty prompt does not close the next command', () async {
      final transport = _issue110Adapter();
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 800),
      );
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      await client.send('ATH1');

      transport.forceReplySequence('010C0D04110B10', [_issue110ThirdBatch]);
      transport.omitPromptFor.add('010C0D04110B10');
      final promptless = await client.send('010C0D04110B10');
      expect(promptless.isSuccess, isTrue);

      // Late `>` from the previous exchange, then a real 010C.
      unawaited(
        Future<void>.delayed(
          ElmSessionProfile.promptlessWriteHold,
          () => transport.emitBytes([0x0D, 0x3E]),
        ),
      );
      final rpm = await client.sendAddressed('7DF', '010C');
      expect(rpm.isSuccess, isTrue);
      expect(rpm.bytes.take(3).toList(), [0x41, 0x0C, 0x0B]);
    });

    test('headers off: a late second-ECU line joins before complete', () async {
      final transport = _issue110Adapter();
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 900),
      );
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      await client.send('ATH1');
      transport.forceReplySequence('010C', ['7E804410C0B56\r7E904410C0B5C']);
      final primed = await client.send('010C');
      expect(primed.frames.map((f) => f.sourceId).toSet(), {'7E8', '7E9'});
      expect(client.lastResponderCount, greaterThanOrEqualTo(2));

      transport.omitPromptFor.add('010D');
      transport.forceReplySequence('010D', ['7E803410D00\r7E903410D00']);
      final firstMissing = await client.send(
        '010D',
        timeout: const Duration(milliseconds: 220),
      );
      expect(firstMissing.isSuccess, isTrue);
      expect(client.promptlessCompleteCount, greaterThanOrEqualTo(1));
      transport.omitPromptFor.remove('010D');
      await client.send('ATH0');

      transport.omitPromptFor.add('010C');
      transport.forceReplySequence('010C', ['410C0B56']);
      final pending = client.send('010C');
      var finished = false;
      unawaited(pending.then((_) => finished = true));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(
        finished,
        isFalse,
        reason: 'one unheadered line is not enough while a second ECU is owed',
      );
      transport.emitBytes(ascii.encode('410C0B5C\r>'));
      final joined = await pending;
      expect(joined.isSuccess, isTrue);
    });

    test(
      'headers off: lastResponderCount is derived without ATH1',
      () async {
        final transport = _issue110Adapter();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 900),
        );
        addTearDown(client.dispose);
        expect(await client.connect(), isTrue);
        // Handshake `0100` stays ATH0. Two ECUs print two hex lines, not CAN
        // ids; the line count must still arm the second-ECU guard.
        expect(client.lastResponderCount, greaterThanOrEqualTo(2));

        transport.omitPromptFor.add('010D');
        final firstMissing = await client.send(
          '010D',
          timeout: const Duration(milliseconds: 220),
        );
        expect(firstMissing.isSuccess, isTrue);
        expect(client.promptlessCompleteCount, greaterThanOrEqualTo(1));
        transport.omitPromptFor.remove('010D');

        transport.omitPromptFor.add('010C');
        transport.forceReplySequence('010C', ['410C0B56']);
        final pending = client.send('010C');
        var finished = false;
        unawaited(pending.then((_) => finished = true));
        await Future<void>.delayed(const Duration(milliseconds: 600));
        expect(
          finished,
          isFalse,
          reason:
              'one unheadered line is not enough while a second ECU is owed',
        );
        transport.emitBytes(ascii.encode('410C0B5C\r>'));
        final joined = await pending;
        expect(joined.isSuccess, isTrue);
      },
    );

    test('STOPPED after a promptless close is not the next command', () async {
      final transport = _issue110Adapter();
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 300),
      );
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      await client.send('ATH1');
      transport.omitPromptFor.add('010C');
      transport.forceReplySequence('010C', ['7E804410C0B56']);
      final first = await client.send('010C');
      expect(first.isSuccess, isTrue);
      expect(client.promptlessCompleteCount, greaterThanOrEqualTo(1));

      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 20), () {
          transport.emitBytes(ascii.encode('STOPPED\r>'));
        }),
      );
      final rpm = await client.sendAddressed('7DF', '010D');
      expect(rpm.errorCode, isNot(Elm327ErrorCode.stopped));
      expect(rpm.isSuccess, isTrue);
      expect(rpm.bytes.take(2).toList(), [0x41, 0x0D]);
    });

    test('quiet-complete waits for a second ECU that already spoke', () async {
      final transport = _issue110Adapter();
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 900),
      );
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      await client.send('ATH1');
      transport.forceReplySequence('010C', ['7E804410C0B56\r7E904410C0B5C']);
      final primed = await client.send('010C');
      expect(primed.frames.map((f) => f.sourceId).toSet(), {'7E8', '7E9'});
      expect(client.lastResponderCount, greaterThanOrEqualTo(2));

      transport.omitPromptFor.add('010D');
      transport.forceReplySequence('010D', ['7E803410D00\r7E903410D00']);
      final firstMissing = await client.send(
        '010D',
        timeout: const Duration(milliseconds: 220),
      );
      expect(firstMissing.isSuccess, isTrue);
      expect(client.promptlessCompleteCount, greaterThanOrEqualTo(1));
      transport.omitPromptFor.remove('010D');

      transport.omitPromptFor.add('010C');
      transport.forceReplySequence('010C', ['7E804410C0B56']);
      final pending = client.send('010C');
      var finished = false;
      unawaited(pending.then((_) => finished = true));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(
        finished,
        isFalse,
        reason: '7E8 alone is not conclusive while 7E9 is still owed',
      );
      transport.emitBytes(ascii.encode('7E904410C0B5C\r>'));
      final joined = await pending;
      expect(joined.isSuccess, isTrue);
      expect(joined.frames.map((f) => f.sourceId).toSet(), {'7E8', '7E9'});
    });

    test(
      'command timeout still completes one ECU so the link is kept',
      () async {
        final transport = _issue110Adapter();
        var lost = 0;
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 280),
        )..onConnectionLost = () => lost++;
        addTearDown(client.dispose);
        expect(await client.connect(), isTrue);
        await client.send('ATH1');
        transport.forceReplySequence('010C', ['7E804410C0B56\r7E904410C0B5C']);
        await client.send('010C');
        expect(client.lastResponderCount, greaterThanOrEqualTo(2));

        transport.omitPromptFor.add('010C');
        transport.forceReplySequence('010C', ['7E804410C0B56']);
        final lonely = await client.send('010C');
        expect(lonely.isSuccess, isTrue);
        expect(lonely.frames.map((f) => f.sourceId).toSet(), {'7E8'});
        expect(client.promptlessCompleteCount, greaterThanOrEqualTo(1));
        expect(lost, 0);
        expect(client.isInitialized, isTrue);
      },
    );

    test('SEARCHING without payload is not a quiet-complete', () async {
      final transport = _issue110Adapter();
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 800),
      );
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      transport.omitPromptFor.add('0120');
      transport.forceReplySequence('0120', ['SEARCHING...']);
      final pending = client.send('0120');
      var finished = false;
      unawaited(pending.then((_) => finished = true));
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(finished, isFalse);
      transport.emitBytes(ascii.encode('4120A007B011\r>'));
      final hunted = await pending;
      expect(hunted.isSuccess, isTrue);
      expect(hunted.bytes.take(2).toList(), [0x41, 0x20]);
    });

    test('AT still completes only on a prompt', () async {
      final transport = _issue110Adapter();
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 250),
      );
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      transport.omitPromptFor.add('ATH1');
      await expectLater(client.send('ATH1'), throwsA(isA<TimeoutException>()));
      expect(client.promptlessCompleteCount, 0);
    });

    test('partial bytes on timeout probe with ATI, never a bare CR', () async {
      final transport = _issue110Adapter();
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 200),
      );
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      await client.send('ATH1');
      transport.silenceFor.add('010C');
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 20), () {
          transport.emitBytes(ascii.encode('7E8100F410C0B56'));
        }),
      );
      await expectLater(client.send('010C'), throwsA(isA<TimeoutException>()));
      transport.silenceFor.remove('010C');
      transport.commandLog.clear();
      final next = await client.send('010D');
      expect(transport.commandLog, contains('ATI'));
      expect(transport.commandLog, isNot(contains('')));
      expect(
        transport.commandLog.indexOf('ATI'),
        lessThan(transport.commandLog.indexOf('010D')),
      );
      expect(next.isSuccess, isTrue);
      expect(client.isInitialized, isTrue);
    });
  });

  group('015E NO DATA', () {
    test(
      'three unanswered reads mark the PID unsupported, not a hot loop',
      () async {
        final transport = FakeElm327(
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
              },
            ),
          ],
        );
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 200),
        );
        addTearDown(client.dispose);
        expect(await client.connect(), isTrue);
        final engine = PollingEngine(client)
          ..recheckInterval = const Duration(minutes: 5)
          ..setActivePids(const [PidLibrary.engineFuelRate]);
        addTearDown(engine.dispose);
        engine.start();
        final deadline = DateTime.now().add(const Duration(seconds: 4));
        while (engine.current.faults[PidLibrary.engineFuelRate.id] !=
                PidFault.unsupported &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        await engine.stop();
        expect(
          engine.current.faults[PidLibrary.engineFuelRate.id],
          PidFault.unsupported,
        );
        expect(
          engine.current.faults[PidLibrary.engineFuelRate.id],
          isNot(PidFault.noAnswer),
        );
        final tries = transport.commandLog.where((c) => c == '015E').length;
        // A 7E0 `NO DATA` still tries documented 7DF once, so two wire reads
        // can count as one strike.
        expect(
          tries,
          inInclusiveRange(3, 6),
          reason: 'commands: ${transport.commandLog}',
        );
      },
    );

    test(
      'genuine adapter keeps noAnswer and the 60 s rest',
      () async {
        final transport = FakeElm327(
          protocol: BusProtocol.can11,
          identity: 'ELM327 v2.1',
          deviceDescription: 'ELM327 v2.1',
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
        addTearDown(client.dispose);
        expect(await client.connect(), isTrue);
        expect(
          client.adapterIdentity.concerns.map((c) => c.kind),
          isNot(contains(AdapterConcernKind.firmwareNeverReleased)),
        );
        final engine = PollingEngine(client)
          ..recheckInterval = const Duration(minutes: 5)
          ..setActivePids(const [PidLibrary.engineFuelRate]);
        addTearDown(engine.dispose);
        engine.start();
        final deadline = DateTime.now().add(const Duration(seconds: 4));
        while (engine.current.faults[PidLibrary.engineFuelRate.id] !=
                PidFault.noAnswer &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        await engine.stop();
        expect(
          engine.current.faults[PidLibrary.engineFuelRate.id],
          PidFault.noAnswer,
        );
        expect(
          engine.current.faults[PidLibrary.engineFuelRate.id],
          isNot(PidFault.unsupported),
        );
        final tries = transport.commandLog.where((c) => c == '015E').length;
        expect(
          tries,
          inInclusiveRange(3, 6),
          reason: 'commands: ${transport.commandLog}',
        );
      },
    );

    test(
      '015E after a promptless complete uses the five-minute recheck',
      () async {
        final transport = FakeElm327(
          protocol: BusProtocol.can11,
          identity: 'ELM327 v2.1',
          deviceDescription: 'ELM327 v2.1',
          ecus: [
            FakeEcu(
              name: 'ECM',
              requestId: '7E0',
              responseId: '7E8',
              responses: {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
                '010C': [0x41, 0x0C, 0x1A, 0xF8],
                '010D': [0x41, 0x0D, 0x00],
              },
            ),
          ],
        );
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 200),
        );
        addTearDown(client.dispose);
        expect(await client.connect(), isTrue);
        expect(
          client.adapterIdentity.concerns.map((c) => c.kind),
          isNot(contains(AdapterConcernKind.firmwareNeverReleased)),
        );
        // The first unanswered `015E` itself is the missing prompt. Later
        // strikes then see `promptlessCompleteCount > 0` on a genuine chip.
        transport.omitPromptFor.add('015E');
        final engine = PollingEngine(client)
          ..recheckInterval = const Duration(minutes: 5)
          ..setActivePids(
            const [PidLibrary.engineFuelRate],
            includeProfileDerivedInputs: false,
          );
        addTearDown(engine.dispose);
        engine.start();
        final deadline = DateTime.now().add(const Duration(seconds: 6));
        while (engine.current.faults[PidLibrary.engineFuelRate.id] !=
                PidFault.unsupported &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        await engine.stop();
        expect(client.promptlessCompleteCount, greaterThanOrEqualTo(1));
        expect(
          engine.current.faults[PidLibrary.engineFuelRate.id],
          PidFault.unsupported,
          reason: 'commands: ${transport.commandLog}',
        );
        expect(
          engine.current.faults[PidLibrary.engineFuelRate.id],
          isNot(PidFault.noAnswer),
        );
        final tries = transport.commandLog.where((c) => c == '015E').length;
        expect(
          tries,
          inInclusiveRange(3, 6),
          reason: 'commands: ${transport.commandLog}',
        );
      },
    );

    test(
      'clone NO DATA on a PID other than 015E stays noAnswer',
      () async {
        final transport = FakeElm327(
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
              },
            ),
          ],
        );
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 200),
        );
        addTearDown(client.dispose);
        expect(await client.connect(), isTrue);
        expect(
          client.adapterIdentity.concerns.map((c) => c.kind),
          contains(AdapterConcernKind.firmwareNeverReleased),
        );
        final engine = PollingEngine(client)
          ..recheckInterval = const Duration(minutes: 5)
          ..setActivePids(const [PidLibrary.coolantTemp]);
        addTearDown(engine.dispose);
        engine.start();
        final deadline = DateTime.now().add(const Duration(seconds: 4));
        while (engine.current.faults[PidLibrary.coolantTemp.id] !=
                PidFault.noAnswer &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        await engine.stop();
        expect(
          engine.current.faults[PidLibrary.coolantTemp.id],
          PidFault.noAnswer,
        );
        expect(
          engine.current.faults[PidLibrary.coolantTemp.id],
          isNot(PidFault.unsupported),
        );
        final tries = transport.commandLog.where((c) => c == '0105').length;
        expect(
          tries,
          inInclusiveRange(3, 6),
          reason: 'commands: ${transport.commandLog}',
        );
      },
    );
  });

  group('batch policy', () {
    test('clone + two 7DF responders caps Mode 01 batches at 3', () async {
      final transport = _issue110Adapter();
      final client = Elm327Client(transport);
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      await client.send('ATH1');
      final rpm = await client.sendAddressed('7E0', '010C');
      expect(rpm.isSuccess, isTrue);
      expect(client.enginePhysicalSilent, isTrue);
      expect(client.lastResponderCount, greaterThanOrEqualTo(2));

      final engine = PollingEngine(client);
      addTearDown(engine.dispose);
      await engine.discoverSupportedPids();
      engine.setActivePids(const [
        PidLibrary.engineRpm,
        PidLibrary.vehicleSpeed,
        PidLibrary.engineLoad,
        PidLibrary.throttlePosition,
        PidLibrary.manifoldPressure,
        PidLibrary.mafRate,
      ]);
      engine.start();
      final deadline = DateTime.now().add(const Duration(seconds: 3));
      while ((engine.current.lastMode01PidCount ?? 0) < 1 &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await engine.stop();
      final grouped = transport.commandLog
          .where((c) => c.startsWith('01') && c.length > 4)
          .where((c) => c != '0100' && c != '0120' && c != '0140')
          .toList();
      expect(grouped, isNotEmpty);
      for (final command in grouped) {
        final pids = command.length ~/ 2 - 1;
        expect(
          pids,
          lessThanOrEqualTo(3),
          reason: 'clone+7DF must not emit a 6-PID batch, got $command',
        );
      }
    });
  });
}
