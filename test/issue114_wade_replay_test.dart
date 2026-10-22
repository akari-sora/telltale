/// Issue #114: values flash 「過期」 because polling falls back to slow
/// single-PID requests after one missing prompt.
///
/// Offline replay modelled on a user-exported 1.0.24 session (ELM327 v1.5
/// clone, `AT@1` = ICSolution, CAN 11/500, physical `7E0` silent, `7E8` and
/// `7E9` answer functional `7DF`). The raw log is not committed: it carries
/// device identifiers. Values below are copied from its replies.
///
/// In the field log the fifth `010C0D04` was sent at ~8.9 s and completed
/// without `>` at ~13.9 s. The remaining 55 commands stayed single-PID through
/// ~42.3 s, with a median 521 ms interval (about 4.2 s per round of 8), even
/// though those replies closed on a real `>`.
///
/// Not adapter or on-vehicle validation.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/adapter_identity.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/elm_session_profile.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/telemetry.dart';

import 'support/fake_elm327.dart';

FakeEcu _ecm() => FakeEcu(
  name: 'ECM',
  // Physical 7E0 is silent in the field log (`010C` -> NO DATA).
  requestId: '7FF',
  responseId: '7E8',
  responses: {
    '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
    '0120': [0x41, 0x20, 0xA0, 0x07, 0xB0, 0x11],
    '0140': [0x41, 0x40, 0xFE, 0xD0, 0x84, 0x10],
    '010C': [0x41, 0x0C, 0x0B, 0x2E],
    '010D': [0x41, 0x0D, 0x00],
    '0104': [0x41, 0x04, 0x26],
    '0111': [0x41, 0x11, 0x26],
    '010B': [0x41, 0x0B, 0x60],
    '0110': [0x41, 0x10, 0x01, 0x90],
    '0105': [0x41, 0x05, 0x85],
    '010F': [0x41, 0x0F, 0x5C],
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
    '0104': [0x41, 0x04, 0x26],
    '0105': [0x41, 0x05, 0x83],
    '0111': [0x41, 0x11, 0x26],
  },
);

FakeElm327 _wadeAdapter() => FakeElm327(
  protocol: BusProtocol.can11,
  identity: 'ELM327 v1.5',
  deviceDescription: 'ICSolution',
  ecus: [_ecm(), _tcm()],
);

const _wadePids = <Pid>[
  PidLibrary.engineRpm,
  PidLibrary.vehicleSpeed,
  PidLibrary.engineLoad,
  PidLibrary.throttlePosition,
  PidLibrary.manifoldPressure,
  PidLibrary.mafRate,
  PidLibrary.coolantTemp,
  PidLibrary.intakeAirTemp,
];

bool _isGrouped(String c) =>
    c.startsWith('01') &&
    c.length > 4 &&
    !const {'0100', '0120', '0140', '0160'}.contains(c);

bool _isMode01Poll(String c) =>
    c.startsWith('01') && !const {'0100', '0120', '0140', '0160'}.contains(c);

void main() {
  group('#114 Wade replay: one missing prompt', () {
    test(
      'batched polling resumes, no 450 ms pacing, values stay live',
      () async {
        final transport = _wadeAdapter();
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
        await client.send('ATH1');
        final rpm = await client.sendAddressed('7E0', '010C');
        expect(rpm.isSuccess, isTrue);
        expect(client.enginePhysicalSilent, isTrue);

        final engine = PollingEngine(client);
        addTearDown(engine.dispose);
        await engine.discoverSupportedPids();
        engine.setActivePids(_wadePids);

        // The field log's fifth batch lost its `>`; the replay drops it on the
        // third so the test stays short. The position is not the point.
        transport.omitPromptOnGroupedMode01 = 3;
        final pollStart = transport.commandLog.length;
        engine.start();

        final deadline = DateTime.now().add(const Duration(seconds: 8));
        var recoveredAt = -1;
        final livePids = <String>{};
        final staleTransitions = <String>{};
        while (DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          final current = engine.current;
          for (final pid in _wadePids) {
            if (current.readings.containsKey(pid.id) && !current.isStale(pid)) {
              livePids.add(pid.id);
            } else if (livePids.contains(pid.id)) {
              staleTransitions.add(pid.modeAndPid);
            }
          }
          if (client.promptlessCompleteCount < 1) continue;
          if (recoveredAt < 0) recoveredAt = transport.commandLog.length;
        }

        // Freshness is judged while the loop is still running.
        final snapshot = engine.current;
        final staleNow = [
          for (final pid in _wadePids)
            if (snapshot.isStale(pid)) pid.modeAndPid,
        ];
        final delay = engine.scheduler.interCommandDelay;
        final cap = engine.scheduler.batchSizeCap;
        await engine.stop();

        expect(client.promptlessCompleteCount, 1, reason: 'one missing prompt');
        expect(lost, 0);
        expect(recoveredAt, greaterThan(pollStart));

        final afterRecovery = transport.commandLog
            .skip(recoveredAt)
            .where(_isMode01Poll)
            .toList();
        expect(afterRecovery.length, greaterThanOrEqualTo(40));
        final tail = afterRecovery.skip(afterRecovery.length - 20).toList();
        final groupedTail = tail.where(_isGrouped).length;
        expect(
          groupedTail,
          greaterThanOrEqualTo(tail.length ~/ 2),
          reason:
              'polling must return to grouped Mode 01 after recovery, not stay '
              'on single PIDs for the rest of the session. tail=$tail',
        );
        expect(cap, greaterThanOrEqualTo(3));
        expect(
          delay,
          lessThan(const Duration(milliseconds: 100)),
          reason: 'no session-wide adapter-window pacing after recovery',
        );
        expect(client.promptlessPenalty, 0);
        expect(livePids, containsAll(_wadePids.map((pid) => pid.id)));
        expect(
          staleTransitions,
          isEmpty,
          reason: 'an already-live value must stay live throughout recovery',
        );
        expect(staleNow, isEmpty, reason: 'no value flashes 過期 while polling');
      },
    );
  });

  group('#114 promptless penalty decays on prompted replies', () {
    test(
      'one promptless complete is forgiven after a healthy streak',
      () async {
        final transport = _wadeAdapter();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 400),
        );
        addTearDown(client.dispose);
        expect(await client.connect(), isTrue);
        await client.send('ATH1');
        transport.omitPromptOnOccurrence['010C0D04'] = 1;
        final promptless = await client.send('010C0D04');
        expect(promptless.isSuccess, isTrue);
        expect(client.promptlessCompleteCount, 1);
        expect(client.promptlessPenalty, 1);
        expect(
          ElmSessionProfile.batchSizeCap(
            cloneSelfInconsistent: true,
            multiEcuFunctional: true,
            promptlessPenalty: client.promptlessPenalty,
          ),
          1,
        );
        transport.omitPromptOnOccurrence.remove('010C0D04');
        for (var i = 0; i < ElmSessionProfile.promptlessRecoveryStreak; i++) {
          final r = await client.send('0105');
          expect(r.isSuccess, isTrue);
        }
        expect(client.promptlessPenalty, 0);
        expect(
          client.promptlessCompleteCount,
          1,
          reason: 'lifetime evidence kept',
        );
        expect(
          ElmSessionProfile.batchSizeCap(
            cloneSelfInconsistent: true,
            multiEcuFunctional: true,
            promptlessPenalty: client.promptlessPenalty,
          ),
          3,
        );
      },
    );

    test('AT replies and NO DATA do not count toward recovery', () async {
      final transport = _wadeAdapter();
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 400),
      );
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      await client.send('ATH1');
      transport.omitPromptOnOccurrence['010C0D04'] = 1;
      await client.send('010C0D04');
      transport.omitPromptOnOccurrence.remove('010C0D04');
      for (var i = 0; i < ElmSessionProfile.promptlessRecoveryStreak + 2; i++) {
        await client.send('ATRV');
        await client.send('015E');
      }
      expect(client.promptlessPenalty, 1);
    });

    for (final failure in ['NO DATA', 'CAN ERROR', 'timeout']) {
      test('$failure interrupts the healthy recovery streak', () async {
        final transport = _wadeAdapter();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 400),
        );
        addTearDown(client.dispose);
        expect(await client.connect(), isTrue);
        await client.send('ATH1');
        transport.omitPromptOnOccurrence['010C0D04'] = 1;
        await client.send('010C0D04');
        transport.omitPromptOnOccurrence.remove('010C0D04');
        for (
          var i = 0;
          i < ElmSessionProfile.promptlessRecoveryStreak - 1;
          i++
        ) {
          expect((await client.send('0105')).isSuccess, isTrue);
        }

        if (failure == 'timeout') {
          transport.silenceFor.add('015E');
          await expectLater(
            client.send('015E'),
            throwsA(isA<TimeoutException>()),
          );
          transport.silenceFor.remove('015E');
        } else {
          transport.forceReply('015E', failure);
          expect((await client.send('015E')).isSuccess, isFalse);
        }
        expect(client.promptlessPenalty, 1);
        expect(client.promptedStreak, 0);
        for (var i = 1; i < ElmSessionProfile.promptlessRecoveryStreak; i++) {
          expect((await client.send('0105')).isSuccess, isTrue);
          expect(client.promptlessPenalty, 1, reason: 'need a new full streak');
        }
        expect((await client.send('0105')).isSuccess, isTrue);
        expect(client.promptlessPenalty, 0);
      });
    }
  });

  group('#114 freshness follows the observed round', () {
    final t0 = DateTime.utc(2026, 10, 21);
    Reading reading({Duration? interval}) => Reading(
      pid: PidLibrary.engineRpm,
      value: 800,
      rawBytes: const [0x0C, 0x80],
      timestamp: t0,
      receivedElapsed: const Duration(seconds: 10),
      observedInterval: interval,
    );

    test('without an observed cadence the 2 s floor is unchanged', () {
      final r = reading();
      expect(r.maxAge, const Duration(seconds: 2));
      expect(
        r.isStaleAt(t0, elapsed: const Duration(seconds: 12, milliseconds: 1)),
        isTrue,
      );
    });

    test('a 3.6 s round is live between updates, stale after 3 misses', () {
      final r = reading(interval: const Duration(milliseconds: 3600));
      expect(
        r.isStaleAt(
          t0,
          elapsed: const Duration(seconds: 13, milliseconds: 700),
        ),
        isFalse,
      );
      // 3 x 3.6 s is clamped to the 10 s ceiling.
      expect(r.maxAge, const Duration(seconds: 10));
      expect(
        r.isStaleAt(t0, elapsed: const Duration(seconds: 20, milliseconds: 1)),
        isTrue,
      );
    });

    test('a 1 s cadence gives three rounds of grace', () {
      final r = reading(interval: const Duration(seconds: 1));
      expect(r.maxAge, const Duration(seconds: 3));
    });

    test('cadence never stretches freshness past the 10 s ceiling', () {
      final r = reading(interval: const Duration(seconds: 9));
      expect(r.maxAge, const Duration(seconds: 10));
      expect(
        r.isStaleAt(t0, elapsed: const Duration(seconds: 20, milliseconds: 1)),
        isTrue,
      );
    });
  });
}
