/// Issue #106 Slice 2: Protocol Search Regression Test Suite.
///
/// Validates that the `0100` OBD support probe — the first real vehicle
/// request after `ATSP0` arms automatic protocol search — now receives
/// [Elm327Client.protocolSearchTimeout] (25 s) instead of the generic
/// 4-second AT-command budget.
///
/// Also validates the narrow NO DATA retry policy: exactly one immediate
/// retry when `0100` returns `NO DATA`, no retry for any other error code.
///
/// Test cases:
///   S2-01: >4s silence, no SEARCHING, 0100 eventually succeeds (root cause kill)
///   S2-02: chunked SEARCHING... + slow success
///   S2-03: first 0100 → NO DATA, second → valid 4100 (ECU warm-up retry)
///   S2-04: two consecutive NO DATA → connect fails
///   S2-05: UNABLE TO CONNECT → no retry, connect fails
///   S2-06: CAN ERROR → no retry, connect fails
///   S2-07: >25s silence → bounded fail (protocolSearchTimeout honoured)
///   S2-08: NO DATA retry shares budget — never grants a fresh 25s window
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'support/issue106_trace_probe.dart';

void main() {
  group('Issue 106 Slice 2 — Protocol Search Regression', () {
    test('S2-01: >4s silence, no SEARCHING, 0100 eventually gets valid 4100 response within 25s', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-S2-01',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      final transport = ScriptedCausalTransport(name: 's2_01_slow_search', probe: probe);
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      var tx0100Count = 0;
      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100')) {
          tx0100Count++;
          // Reply after 6 seconds — exceeds the old 4s budget but is well
          // within the new 25s protocolSearchTimeout.
          t.scheduleDelayed(const Duration(seconds: 6), () {
            t.sendReply('41 00 BE 1F B8 10\r\n>');
          });
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();

      expect(connectOk, isTrue,
          reason: 'Should connect successfully after a 6s delay on 0100');
      expect(client.isInitialized, isTrue);
      expect(tx0100Count, 1,
          reason: '0100 should only be sent once (no premature retry)');
    });

    test('S2-02: chunked SEARCHING... + slow success', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-S2-02',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      final transport = ScriptedCausalTransport(name: 's2_02_searching', probe: probe);
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100')) {
          // Emit SEARCHING... after 500ms (partial, no prompt)
          t.scheduleDelayed(const Duration(milliseconds: 500), () {
            t.sendReply('SEARCHING...\r\n');
            // Then the final valid response after 8s total
            t.scheduleDelayed(const Duration(seconds: 8), () {
              t.sendReply('41 00 BE 1F B8 10\r\n>');
            });
          });
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();

      expect(connectOk, isTrue,
          reason: 'Should tolerate SEARCHING... and wait for final response');
      expect(client.isInitialized, isTrue);
    });

    test('S2-03: First 0100 returns NO DATA, second 0100 returns valid 4100', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-S2-03',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      final transport = ScriptedCausalTransport(name: 's2_03_nodata_retry', probe: probe);
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      var tx0100Count = 0;
      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100')) {
          tx0100Count++;
          if (tx0100Count == 1) {
            t.sendReply('NO DATA\r\n>');
          } else {
            t.sendReply('41 00 BE 1F B8 10\r\n>');
          }
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();

      expect(connectOk, isTrue,
          reason: 'Should retry 0100 once on NO DATA and succeed on second');
      expect(client.isInitialized, isTrue);
      expect(tx0100Count, 2,
          reason: '0100 should be sent exactly twice');
    });

    test('S2-04: Both 0100 attempts return NO DATA → connect fails', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-S2-04',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      final transport = ScriptedCausalTransport(name: 's2_04_nodata_twice', probe: probe);
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      var tx0100Count = 0;
      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100')) {
          tx0100Count++;
          t.sendReply('NO DATA\r\n>');
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();

      expect(connectOk, isFalse,
          reason: 'Should fail after both 0100 attempts yield NO DATA');
      expect(client.isInitialized, isFalse);
      expect(tx0100Count, 2,
          reason: '0100 should be sent exactly twice (one retry)');
    });

    test('S2-05: UNABLE TO CONNECT → no retry, connect fails', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-S2-05',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      final transport = ScriptedCausalTransport(name: 's2_05_unable', probe: probe);
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      var tx0100Count = 0;
      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100')) {
          tx0100Count++;
          t.sendReply('UNABLE TO CONNECT\r\n>');
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();

      expect(connectOk, isFalse,
          reason: 'Should fail immediately on UNABLE TO CONNECT');
      expect(client.isInitialized, isFalse);
      expect(tx0100Count, 1,
          reason: 'UNABLE TO CONNECT is fatal — must not retry');
    });

    test('S2-06: CAN ERROR → no retry, connect fails', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-S2-06',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      final transport = ScriptedCausalTransport(name: 's2_06_can_error', probe: probe);
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      var tx0100Count = 0;
      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100')) {
          tx0100Count++;
          t.sendReply('CAN ERROR\r\n>');
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();

      expect(connectOk, isFalse,
          reason: 'Should fail immediately on CAN ERROR');
      expect(client.isInitialized, isFalse);
      expect(tx0100Count, 1,
          reason: 'CAN ERROR is fatal — must not retry');
    });

    test('S2-07: >25s timeout — 0100 silence exceeds protocolSearchTimeout', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-S2-07',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      final transport = ScriptedCausalTransport(name: 's2_07_timeout', probe: probe);
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100')) {
          // Never reply — must time out after protocolSearchTimeout (25s)
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();

      expect(connectOk, isFalse,
          reason: 'Should time out after protocolSearchTimeout');
      expect(client.isInitialized, isFalse);
    }, timeout: const Timeout(Duration(seconds: 40)));

    test('S2-08: NO DATA retry shares the 25s budget — never grants a fresh window', () async {
      // GPT-6 Pro review requirement: prove that a retry after a late
      // NO DATA does not refresh the 25-second budget. The first attempt
      // consumes 20 of 25 seconds before returning NO DATA, leaving only
      // ~5 s for the retry. If the retry got a fresh 25 s budget, the
      // total would be ~45 s; with shared budget it must be < 30 s.
      final probe = Issue106TraceProbe(
        runId: 'RUN-S2-08',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      final transport = ScriptedCausalTransport(name: 's2_08_shared_budget', probe: probe);
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      var tx0100Count = 0;
      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100')) {
          tx0100Count++;
          if (tx0100Count == 1) {
            // First attempt: consume 20 of 25 seconds then return NO DATA.
            t.scheduleDelayed(const Duration(seconds: 20), () {
              t.sendReply('NO DATA\r\n>');
            });
          } else {
            // Second attempt: stay silent — will time out with only the
            // remaining ~5 s budget, not a fresh 25 s window.
          }
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final sw = Stopwatch()..start();
      final connectOk = await client.connect();
      sw.stop();

      expect(connectOk, isFalse,
          reason: 'Should fail — second attempt has only ~5s left');
      expect(tx0100Count, 2,
          reason: 'Should have attempted 0100 twice');
      // With shared deadline: ~20s (first NO DATA) + ~5s (retry, clamped
      // by same deadline) = ~25s total, never more.
      // With fresh budget: ~20s + ~25s = ~45s — must never reach this.
      expect(sw.elapsedMilliseconds, lessThan(28000),
          reason: 'Total must stay within one 25s deadline envelope');
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(24000),
          reason: 'Must have consumed most of the 25s budget');
    }, timeout: const Timeout(Duration(seconds: 45)));
  });
}
