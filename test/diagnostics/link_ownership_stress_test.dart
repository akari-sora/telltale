import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';
import 'package:torque_obd/diagnostics/diagnostic_link_ownership.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';

import '../support/fake_elm327.dart';

Future<ProviderContainer> _createContainer(Map<String, Object> prefsValues) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
}

FakeElm327 _createStressAdapter() => FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: const {
            '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
            '010D': [0x41, 0x0D, 0x3C],
            '015E': [0x41, 0x5E, 0x00, 0x64],
          },
        ),
        FakeEcu(
          name: 'BMS',
          requestId: '781',
          responseId: '789',
          responses: const {
            '22B046': [0x62, 0xB0, 0x46, 0x01, 0xF4],
          },
        ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DiagnosticLinkOwnershipAuthority Concurrency & Stress Tests', () {
    test('Stress 1: 50 concurrent one-shots enforce strict FIFO and zero active collision', () async {
      const taskCount = 50;
      bool pollingRunning = true;
      int maxConcurrent = 0;
      int pauseCount = 0;
      int resumeCount = 0;

      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => pollingRunning,
        pausePolling: () async {
          pauseCount++;
          await Future<void>.delayed(const Duration(microseconds: 50));
          pollingRunning = false;
        },
        resumePolling: () {
          resumeCount++;
          pollingRunning = true;
        },
        canRestorePolling: () => true,
      );

      final executionOrder = <int>[];
      final futures = <Future<int>>[];

      for (var i = 0; i < taskCount; i++) {
        final id = i;
        futures.add(
          authority.runOneShot<int>(
            operationName: 'stress_task_$id',
            action: () async {
              if (authority.activeTakeovers > maxConcurrent) {
                maxConcurrent = authority.activeTakeovers;
              }
              expect(authority.activeTakeovers, 1, reason: 'Active takeover must be strictly 1');
              expect(pollingRunning, isFalse, reason: 'Polling must be paused during takeover');
              executionOrder.add(id);
              await Future<void>.delayed(Duration(microseconds: (id % 5) * 100));
              return id * 2;
            },
          ),
        );
      }

      final results = await Future.wait(futures);

      expect(results.length, taskCount);
      for (var i = 0; i < taskCount; i++) {
        expect(results[i], i * 2);
      }

      expect(executionOrder, List.generate(taskCount, (i) => i));
      expect(maxConcurrent, 1, reason: 'Zero concurrency collision allowed');
      expect(authority.activeTakeovers, 0);
      expect(authority.queuedCount, 0);
      expect(pollingRunning, isTrue);
      expect(pauseCount, taskCount);
      expect(resumeCount, taskCount);
    });

    test('Stress 2: 30 interleaved throwing and succeeding actions isolate errors without poisoning queue', () async {
      const taskCount = 30;
      bool pollingRunning = true;
      int successfulCompleted = 0;
      int failedCompleted = 0;

      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => pollingRunning,
        pausePolling: () async {
          await Future<void>.delayed(const Duration(microseconds: 50));
          pollingRunning = false;
        },
        resumePolling: () {
          pollingRunning = true;
        },
        canRestorePolling: () => true,
      );

      final results = <int, Object>{};
      final futures = <Future<void>>[];

      for (var i = 0; i < taskCount; i++) {
        final id = i;
        final isFailure = id % 3 != 0;

        final future = authority.runOneShot<int>(
          operationName: 'chaos_task_$id',
          action: () async {
            await Future<void>.delayed(const Duration(microseconds: 100));
            if (isFailure) {
              if (id % 3 == 1) {
                throw StateError('StateError in task $id');
              } else {
                throw DiagnosticLinkException(
                  kind: DiagnosticFailureKind.transportFailure,
                  message: 'Transport issue in task $id',
                );
              }
            }
            return id;
          },
        ).then<void>((val) {
          results[id] = val;
          successfulCompleted++;
        }, onError: (Object err) {
          results[id] = err;
          failedCompleted++;
        });

        futures.add(future);
      }

      await Future.wait(futures);

      expect(successfulCompleted, 10);
      expect(failedCompleted, 20);
      expect(results.length, taskCount);

      for (var i = 0; i < taskCount; i++) {
        if (i % 3 == 0) {
          expect(results[i], i);
        } else if (i % 3 == 1) {
          expect(results[i], isA<StateError>());
        } else {
          expect(
            results[i],
            isA<DiagnosticLinkException>().having(
              (e) => e.kind,
              'kind',
              DiagnosticFailureKind.transportFailure,
            ),
          );
        }
      }

      expect(authority.activeTakeovers, 0);
      expect(authority.queuedCount, 0);
      expect(pollingRunning, isTrue, reason: 'Polling must be restored even after multiple consecutive errors');
    });

    test('Stress 3: Mid-flight dispose cleanly aborts queue and prevents polling restoration', () async {
      bool pollingRunning = true;
      bool resumeCalled = false;

      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => pollingRunning,
        pausePolling: () async {
          pollingRunning = false;
        },
        resumePolling: () {
          resumeCalled = true;
          pollingRunning = true;
        },
        canRestorePolling: () => true,
      );

      final inFlightCompleter = Completer<void>();
      final queuedErrors = <Object>[];

      // Action 0: in-flight slow action
      final action0Future = authority.runOneShot<String>(
        operationName: 'in_flight_action',
        action: () async {
          inFlightCompleter.complete();
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return 'action0_done';
        },
      );

      await inFlightCompleter.future;
      expect(authority.activeTakeovers, 1);
      expect(authority.hasDisplacedPolling, isTrue);

      // Queue 10 subsequent actions while action0 is in flight
      final queuedFutures = <Future<void>>[];
      for (var i = 1; i <= 10; i++) {
        final f = authority.runOneShot<int>(
          operationName: 'queued_$i',
          action: () async => i,
        ).then<void>((_) {
          fail('Queued action $i should not have succeeded after dispose');
        }, onError: (Object err) {
          queuedErrors.add(err);
        });
        queuedFutures.add(f);
      }

      expect(authority.queuedCount, 10);

      // Trigger dispose while action0 is actively in-flight
      authority.dispose();

      // Action0 completes its execution
      final action0Result = await action0Future;
      expect(action0Result, 'action0_done');

      // Wait for all queued futures to resolve
      await Future.wait(queuedFutures);

      expect(queuedErrors.length, 10);
      for (final err in queuedErrors) {
        expect(
          err,
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.retiredOperation,
          ),
        );
      }

      expect(resumeCalled, isFalse, reason: 'resumePolling must NOT be called if authority was disposed');
      expect(pollingRunning, isFalse);
      expect(authority.activeTakeovers, 0);
      expect(authority.queuedCount, 0);

      // Any new request after dispose is immediately rejected
      await expectLater(
        authority.runOneShot<void>(
          operationName: 'post_dispose',
          action: () async {},
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.retiredOperation,
          ),
        ),
      );
    });

    test('Stress 4: Mid-queue cancellation selectively cancels targeted actions without disturbing neighbors', () async {
      bool pollingRunning = true;
      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => pollingRunning,
        pausePolling: () async => pollingRunning = false,
        resumePolling: () => pollingRunning = true,
        canRestorePolling: () => true,
      );

      final inFlightCompleter = Completer<void>();
      final f0 = authority.runOneShot<int>(
        operationName: 'f0',
        action: () async {
          inFlightCompleter.complete();
          await Future<void>.delayed(const Duration(milliseconds: 40));
          return 0;
        },
      );

      await inFlightCompleter.future;

      // Queue 5 actions; cancel #2 and #4 while waiting in queue
      final cts1 = DiagnosticCancellationTokenSource();
      final cts2 = DiagnosticCancellationTokenSource();
      final cts3 = DiagnosticCancellationTokenSource();
      final cts4 = DiagnosticCancellationTokenSource();
      final cts5 = DiagnosticCancellationTokenSource();

      final f1 = authority.runOneShot<int>(operationName: 'f1', action: () async => 1, cancellation: cts1.token);
      final f2 = authority.runOneShot<int>(operationName: 'f2', action: () async => 2, cancellation: cts2.token);
      final f3 = authority.runOneShot<int>(operationName: 'f3', action: () async => 3, cancellation: cts3.token);
      final f4 = authority.runOneShot<int>(operationName: 'f4', action: () async => 4, cancellation: cts4.token);
      final f5 = authority.runOneShot<int>(operationName: 'f5', action: () async => 5, cancellation: cts5.token);

      // Immediately attach expectations / error catches to f2 and f4 to prevent unhandled zone errors
      final f2Expectation = expectLater(
        f2,
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.cancelled,
          ),
        ),
      );

      final f4Expectation = expectLater(
        f4,
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.cancelled,
          ),
        ),
      );

      // Cancel f2 and f4 while f0 is still in flight
      cts2.cancel();
      cts4.cancel();

      final r0 = await f0;
      final r1 = await f1;
      final r3 = await f3;
      final r5 = await f5;

      expect(r0, 0);
      expect(r1, 1);
      expect(r3, 3);
      expect(r5, 5);

      await Future.wait([f2Expectation, f4Expectation]);

      expect(authority.activeTakeovers, 0);
      expect(authority.queuedCount, 0);
      expect(pollingRunning, isTrue);
    });

    test('Stress 5: Pause failure stops action execution and maintains queue liveness for next task', () async {
      int pauseAttempts = 0;
      bool pollingRunning = true;

      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => pollingRunning,
        pausePolling: () async {
          pauseAttempts++;
          if (pauseAttempts == 1) {
            // First pause attempt fails to stop polling
            pollingRunning = true;
          } else {
            // Subsequent attempts succeed
            pollingRunning = false;
          }
        },
        resumePolling: () {
          pollingRunning = true;
        },
        canRestorePolling: () => true,
      );

      bool action1Executed = false;
      bool action2Executed = false;

      final f1 = authority.runOneShot<void>(
        operationName: 'f1_pause_fail',
        action: () async {
          action1Executed = true;
        },
      );

      final f2 = authority.runOneShot<void>(
        operationName: 'f2_pause_succeed',
        action: () async {
          action2Executed = true;
        },
      );

      await expectLater(
        f1,
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.transportFailure,
          ),
        ),
      );

      await f2;

      expect(action1Executed, isFalse);
      expect(action2Executed, isTrue);
      expect(authority.activeTakeovers, 0);
      expect(authority.queuedCount, 0);
    });

    test('Stress 6: ObdSession concurrent responder census stress serializes without wire conflict', () async {
      final container = await _createContainer({});
      addTearDown(container.dispose);

      final adapter = _createStressAdapter();
      adapter.slowCommands['0100'] = const Duration(milliseconds: 25);

      final session = container.read(obdSessionProvider.notifier);
      expect(await session.connectForTest(adapter, TransportKind.demo), isTrue);

      expect(session.engine?.isRunning, isTrue);

      // Fire 5 concurrent census requests
      final futures = List.generate(5, (_) => session.ensureResponderCensus());
      await Future.wait(futures);

      expect(session.engine?.responders, contains('7E8'));
      expect(session.engine?.isRunning, isTrue);

      // Verify wire traffic on adapter:
      final wireLog = adapter.commandLog;
      expect(wireLog.where((c) => c == '0100').length, greaterThanOrEqualTo(1));

      await session.disconnect();
    });

    test('Stress 7 (Adversarial Probe): Mid-flight cancellation behavior of active action', () async {
      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => false,
        pausePolling: () async {},
        resumePolling: () {},
        canRestorePolling: () => true,
      );

      final cts = DiagnosticCancellationTokenSource();
      final inFlight = Completer<void>();

      final future = authority.runOneShot<String>(
        operationName: 'cancel_during_action',
        action: () async {
          inFlight.complete();
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return 'completed_value';
        },
        cancellation: cts.token,
      );

      await inFlight.future;
      cts.cancel(); // Cancelled while in flight!

      final result = await future;
      // EMPIRICAL OBSERVATION: Authority returns result if action finishes, because runOneShot does not check cancellation after action().
      expect(result, 'completed_value');
    });

    test('Stress 8 (Adversarial Probe): Queued action cancellation latency bound by preceding slow action', () async {
      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => false,
        pausePolling: () async {},
        resumePolling: () {},
        canRestorePolling: () => true,
      );

      final inFlight = Completer<void>();
      final f1 = authority.runOneShot<int>(
        operationName: 'slow_head',
        action: () async {
          inFlight.complete();
          await Future<void>.delayed(const Duration(milliseconds: 80));
          return 1;
        },
      );

      await inFlight.future;

      final cts2 = DiagnosticCancellationTokenSource();
      final startTime = DateTime.now();
      final f2 = authority.runOneShot<int>(
        operationName: 'cancelled_queue',
        action: () async => 2,
        cancellation: cts2.token,
      );

      final f2Expectation = expectLater(
        f2,
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.cancelled,
          ),
        ),
      );

      // Cancel f2 at 10ms
      await Future<void>.delayed(const Duration(milliseconds: 10));
      cts2.cancel();

      // Check whether f2 has completed or is still waiting for f1
      // Because f2 is suspended at `await previousTail`, it only resolves when f1 finishes!
      await Future.wait([f1, f2Expectation]);
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;

      // EMPIRICAL OBSERVATION: elapsed is at least 70ms because f2 waits for f1's tail
      expect(elapsed, greaterThanOrEqualTo(65));
    });
  });
}
