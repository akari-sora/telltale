import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';
import 'package:torque_obd/diagnostics/uds/uds_dtc_types.dart';
import 'package:torque_obd/diagnostics/uds/uds_read_types.dart';
import 'package:torque_obd/diagnostics/uds/uds_transaction_engine.dart';
import 'package:torque_obd/diagnostics/uds/uds_transaction_policy.dart';
import 'package:torque_obd/diagnostics/uds/uds_transaction_types.dart';

void main() {
  group('UdsTransactionEngine - Unit Tests', () {
    test('Service 0x22 immediate success', () async {
      final clock = FakeUdsClock();
      const policy = UdsTransactionPolicy.standard;
      final engine = UdsTransactionEngine(policy: policy, clock: clock);

      final channel = CallbackUdsTransactionChannel(
        onSend: (id, pdu, timeout) async {
          expect(pdu.bytes, [0x22, 0x01, 0x00]);
          expect(timeout, policy.p2Timeout);
          clock.advance(const Duration(milliseconds: 10));
          return DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x12, 0x34]),
            sourceAddress: DiagnosticSourceAddress('7E8'),
          );
        },
        onReceiveContinuation: (_) async =>
            throw StateError('Continuation should not be called'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
      );

      expect(result, isA<UdsTransactionSuccess>());
      final success = result as UdsTransactionSuccess;
      expect(success.attempts, 1);
      expect(success.retries, 0);
      expect(success.responsePendingCount, 0);
      expect(success.responseBytes, [0x62, 0x01, 0x00, 0x12, 0x34]);
      expect(success.sourceAddress, DiagnosticSourceAddress('7E8'));
      expect(success.readResult, isNotNull);
    });

    test('NRC 0x21 busyRepeatRequest triggers delay and retry send', () async {
      final clock = FakeUdsClock();
      final policy = UdsTransactionPolicy(
        p2Timeout: const Duration(milliseconds: 50),
        busyRepeatDelay: const Duration(milliseconds: 100),
        maxBusyRepeatRetries: 2,
      );
      final engine = UdsTransactionEngine(policy: policy, clock: clock);

      var sendCount = 0;
      final channel = CallbackUdsTransactionChannel(
        onSend: (id, pdu, timeout) async {
          sendCount++;
          clock.advance(const Duration(milliseconds: 10));
          if (sendCount == 1) {
            return DiagnosticMessage(
              pdu: ApplicationPdu([0x7F, 0x22, 0x21]), // busyRepeatRequest
            );
          }
          return DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x55]),
          );
        },
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation expected'),
      );

      final states = <UdsTransactionState>[];
      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
        onStateChange: states.add,
      );

      expect(result, isA<UdsTransactionSuccess>());
      final success = result as UdsTransactionSuccess;
      expect(success.attempts, 2);
      expect(success.retries, 1);
      expect(success.responsePendingCount, 0);
      expect(clock.recordedDelays, [const Duration(milliseconds: 100)]);
      expect(states, [
        UdsTransactionState.created,
        UdsTransactionState.sendingInitial,
        UdsTransactionState.awaitingP2,
        UdsTransactionState.busyRepeatDelay,
        UdsTransactionState.sendingRetry,
        UdsTransactionState.awaitingP2,
        UdsTransactionState.completed,
      ]);
    });

    test('NRC 0x78 responsePending awaits continuation without wire resend',
        () async {
      final clock = FakeUdsClock();
      final policy = UdsTransactionPolicy(
        p2Timeout: const Duration(milliseconds: 50),
        p2StarTimeout: const Duration(milliseconds: 500),
      );
      final engine = UdsTransactionEngine(policy: policy, clock: clock);

      var sendCount = 0;
      var continuationCount = 0;

      final channel = CallbackUdsTransactionChannel(
        onSend: (id, pdu, timeout) async {
          sendCount++;
          clock.advance(const Duration(milliseconds: 10));
          return DiagnosticMessage(
            pdu: ApplicationPdu([0x7F, 0x22, 0x78]), // responsePending
          );
        },
        onReceiveContinuation: (timeout) async {
          continuationCount++;
          expect(timeout, policy.p2StarTimeout);
          clock.advance(const Duration(milliseconds: 150));
          return DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0xAA, 0xBB]),
          );
        },
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
      );

      expect(result, isA<UdsTransactionSuccess>());
      final success = result as UdsTransactionSuccess;
      expect(sendCount, 1);
      expect(continuationCount, 1);
      expect(success.attempts, 1); // strictly 1 outgoing send
      expect(success.retries, 0);
      expect(success.responsePendingCount, 1);
    });

    test('Cancellation during execution cleanly terminates without send',
        () async {
      final clock = FakeUdsClock();
      final engine = UdsTransactionEngine(clock: clock);
      final cts = DiagnosticCancellationTokenSource();
      cts.cancel();

      var sendCalled = false;
      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async {
          sendCalled = true;
          return DiagnosticMessage(pdu: ApplicationPdu([0x62, 0x01, 0x00]));
        },
        onReceiveContinuation: (_) async =>
            throw StateError('Should not be called'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
        cancellation: cts.token,
      );

      expect(sendCalled, isFalse);
      expect(result, isA<UdsTransactionCancelled>());
      expect(result.attempts, 0);
    });

    test('Source mismatch rejects unauthorized responder', () async {
      final clock = FakeUdsClock();
      final engine = UdsTransactionEngine(clock: clock);

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async => DiagnosticMessage(
          pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x00]),
          sourceAddress: DiagnosticSourceAddress('7E9'), // wrong ECU
        ),
        onReceiveContinuation: (_) async =>
            throw StateError('Should not be called'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
        expectedResponder: DiagnosticSourceAddress('7E8'),
      );

      expect(result, isA<UdsTransactionSourceMismatch>());
      final mismatch = result as UdsTransactionSourceMismatch;
      expect(mismatch.expectedSource, DiagnosticSourceAddress('7E8'));
      expect(mismatch.actualSource, DiagnosticSourceAddress('7E9'));
    });
  });

  group('UdsTransactionEngine - Fixture Vectors (24/24)', () {
    final fixtureFile = File('tool/uds_reference/uds_transaction_vectors.json');
    final fixtureData = jsonDecode(fixtureFile.readAsStringSync())
        as Map<String, dynamic>;
    final vectors = fixtureData['vectors'] as List<dynamic>;

    for (final rawVec in vectors) {
      final vec = rawVec as Map<String, dynamic>;
      final id = vec['id'] as String;
      final desc = vec['description'] as String;

      test('[$id] $desc', () async {
        final policyData = vec['policy'] as Map<String, dynamic>;
        final policy = UdsTransactionPolicy(
          p2Timeout: Duration(milliseconds: policyData['p2_timeout_ms'] as int),
          p2StarTimeout:
              Duration(milliseconds: policyData['p2_star_timeout_ms'] as int),
          totalTimeout:
              Duration(milliseconds: policyData['total_timeout_ms'] as int),
          maxBusyRepeatRetries: policyData['max_busy_repeat_retries'] as int,
          busyRepeatDelay:
              Duration(milliseconds: policyData['busy_repeat_delay_ms'] as int),
          maxResponsePendingCount:
              policyData['max_response_pending_count'] as int,
        );

        final clock = FakeUdsClock();
        final engine = UdsTransactionEngine(policy: policy, clock: clock);

        // Build typed request
        final reqType = vec['request_type'] as String;
        final UdsTransactionRequest req = switch (reqType) {
          'read_did' =>
            UdsTransactionRequest.readDid(UdsDid(vec['did'] as int)),
          'report_dtc_by_status_mask' =>
            UdsTransactionRequest.reportDtcByStatusMask(
              UdsDtcStatusMask(vec['status_mask'] as int),
            ),
          'report_supported_dtc' =>
            UdsTransactionRequest.reportSupportedDtc(),
          _ => throw UnsupportedError('Unknown request type: $reqType'),
        };

        expect(
          req.encode(),
          (vec['expected_request_bytes'] as List).cast<int>(),
        );

        final timeline = (vec['timeline'] as List).cast<Map<String, dynamic>>();
        var timelineIndex = 0;

        final cancelAt = vec['cancel_at'] as String?;
        final retireAt = vec['retire_at'] as String?;
        final expectedResponderStr = vec['expected_responder'] as String?;
        final expectedResponder = expectedResponderStr != null
            ? DiagnosticSourceAddress(expectedResponderStr)
            : null;

        final cts = DiagnosticCancellationTokenSource();
        if (cancelAt == 'before_initial') {
          cts.cancel();
        }

        var currentGen = (vec['generation'] as int?) ?? 1;

        final channel = CallbackUdsTransactionChannel(
          onSend: (reqId, pdu, timeout) async {
            if (timelineIndex >= timeline.length) {
              clock.advance(timeout);
              throw TimeoutException('Simulated send timeout');
            }
            final event = timeline[timelineIndex++];
            final eventType = event['type'] as String;
            final delay = Duration(milliseconds: (event['delay_ms'] as int?) ?? 0);

            if (eventType == 'send_timeout') {
              clock.advance(delay);
              throw TimeoutException('Simulated send timeout');
            }

            clock.advance(delay);

            if (cancelAt == 'during_busy_delay') {
              cts.cancel();
            }

            if (retireAt == 'after_send') {
              currentGen = currentGen + 1;
            }

            final respBytes = (event['response_bytes'] as List).cast<int>();
            final src = event['source_address'] != null
                ? DiagnosticSourceAddress(event['source_address'] as String)
                : null;

            return DiagnosticMessage(
              pdu: ApplicationPdu(respBytes),
              sourceAddress: src,
            );
          },
          onReceiveContinuation: (timeout) async {
            if (cancelAt == 'during_pending_wait') {
              cts.cancel();
            }

            if (timelineIndex >= timeline.length) {
              clock.advance(timeout);
              throw TimeoutException('Simulated continuation timeout');
            }
            final event = timeline[timelineIndex++];
            final eventType = event['type'] as String;
            final delay = Duration(milliseconds: (event['delay_ms'] as int?) ?? 0);

            if (eventType == 'continuation_timeout') {
              clock.advance(delay);
              throw TimeoutException('Simulated continuation timeout');
            }

            clock.advance(delay);

            final respBytes = (event['response_bytes'] as List).cast<int>();
            final src = event['source_address'] != null
                ? DiagnosticSourceAddress(event['source_address'] as String)
                : null;

            return DiagnosticMessage(
              pdu: ApplicationPdu(respBytes),
              sourceAddress: src,
            );
          },
        );

        final result = await engine.execute(
          request: req,
          channel: channel,
          expectedResponder: expectedResponder,
          connectionGeneration: currentGen,
          currentConnectionGeneration: () => currentGen,
          cancellation: cts.token,
        );

        final expectedOutcome = vec['expected_outcome'] as String;
        expect(result.attempts, vec['expected_attempts']);
        expect(result.retries, vec['expected_retries']);
        expect(result.responsePendingCount, vec['expected_pending_count']);

        switch (expectedOutcome) {
          case 'success':
            expect(result, isA<UdsTransactionSuccess>());
            final success = result as UdsTransactionSuccess;
            final hex = success.responseBytes
                .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                .join();
            expect(hex, vec['expected_response_hex']);
          case 'terminal_negative':
            expect(result, isA<UdsTransactionTerminalNegative>());
            final neg = result as UdsTransactionTerminalNegative;
            expect(neg.nrc.code, vec['expected_nrc']);
            expect(neg.originalSid, vec['expected_original_sid']);
          case 'busy_retry_exhausted':
            expect(result, isA<UdsTransactionBusyRetryExhausted>());
          case 'response_pending_exhausted':
            expect(result, isA<UdsTransactionResponsePendingExhausted>());
          case 'timed_out':
            expect(result, isA<UdsTransactionTimedOut>());
            final to = result as UdsTransactionTimedOut;
            final expectedType = vec['expected_timeout_type'] as String;
            final actualType = switch (to.timeoutType) {
              UdsTimeoutType.p2 => 'p2',
              UdsTimeoutType.p2Star => 'p2Star',
              UdsTimeoutType.total => 'total',
            };
            expect(actualType, expectedType);
          case 'cancelled':
            expect(result, isA<UdsTransactionCancelled>());
          case 'retired':
            expect(result, isA<UdsTransactionRetired>());
          case 'source_mismatch':
            expect(result, isA<UdsTransactionSourceMismatch>());
          case 'malformed':
            expect(result, isA<UdsTransactionMalformed>());
          default:
            fail('Unhandled expected outcome: $expectedOutcome');
        }
      });
    }
  });
}
