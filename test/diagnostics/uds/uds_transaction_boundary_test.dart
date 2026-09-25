import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';
import 'package:torque_obd/diagnostics/uds/uds_nrc.dart';
import 'package:torque_obd/diagnostics/uds/uds_read_types.dart';
import 'package:torque_obd/diagnostics/uds/uds_transaction_engine.dart';
import 'package:torque_obd/diagnostics/uds/uds_transaction_policy.dart';
import 'package:torque_obd/diagnostics/uds/uds_transaction_types.dart';

void main() {
  group('UdsTransactionBoundaryTest - Boundary & Corner Cases', () {
    test('Boundary: maxBusyRepeatRetries == 0 rejects 0x21 immediately',
        () async {
      final clock = FakeUdsClock();
      final policy = UdsTransactionPolicy(
        maxBusyRepeatRetries: 0,
      );
      final engine = UdsTransactionEngine(policy: policy, clock: clock);

      var sendCount = 0;
      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async {
          sendCount++;
          return DiagnosticMessage(
            pdu: ApplicationPdu([0x7F, 0x22, 0x21]),
          );
        },
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation allowed'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
      );

      expect(sendCount, 1);
      expect(result, isA<UdsTransactionBusyRetryExhausted>());
      final exhausted = result as UdsTransactionBusyRetryExhausted;
      expect(exhausted.attempts, 1);
      expect(exhausted.retries, 0);
      expect(exhausted.maxRetries, 0);
      expect(exhausted.lastNrc, UdsNrc.busyRepeatRequest);
    });

    test('Boundary: maxResponsePendingCount == 0 rejects 0x78 immediately',
        () async {
      final clock = FakeUdsClock();
      final policy = UdsTransactionPolicy(
        maxResponsePendingCount: 0,
      );
      final engine = UdsTransactionEngine(policy: policy, clock: clock);

      var sendCount = 0;
      var continuationCount = 0;
      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async {
          sendCount++;
          return DiagnosticMessage(
            pdu: ApplicationPdu([0x7F, 0x22, 0x78]),
          );
        },
        onReceiveContinuation: (_) async {
          continuationCount++;
          return DiagnosticMessage(pdu: ApplicationPdu([0x62, 0x01, 0x00]));
        },
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
      );

      expect(sendCount, 1);
      expect(continuationCount, 0);
      expect(result, isA<UdsTransactionResponsePendingExhausted>());
      final exhausted = result as UdsTransactionResponsePendingExhausted;
      expect(exhausted.attempts, 1);
      expect(exhausted.responsePendingCount, 1);
      expect(exhausted.maxPending, 0);
      expect(exhausted.lastNrc, UdsNrc.requestCorrectlyReceivedResponsePending);
    });

    test('Boundary: >7-byte ApplicationPdu handled identically without transport leaks',
        () async {
      final clock = FakeUdsClock();
      final engine = UdsTransactionEngine(clock: clock);

      // Large 32-byte payload simulating multi-frame ISO-TP reassembled PDU
      final largePayload = List<int>.generate(32, (i) => i % 256);
      final fullResponseBytes = [0x62, 0xF1, 0x90, ...largePayload];

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async => DiagnosticMessage(
          pdu: ApplicationPdu(fullResponseBytes),
          sourceAddress: DiagnosticSourceAddress('7E8'),
        ),
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation expected'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0xF190)),
        channel: channel,
      );

      expect(result, isA<UdsTransactionSuccess>());
      final success = result as UdsTransactionSuccess;
      expect(success.responseBytes.length, 3 + 32);
      expect(success.attempts, 1);
    });

    test('Boundary: Unknown NRC (0x99) preserved as terminal negative',
        () async {
      final clock = FakeUdsClock();
      final engine = UdsTransactionEngine(clock: clock);

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async => DiagnosticMessage(
          pdu: ApplicationPdu([0x7F, 0x22, 0x99]),
        ),
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation expected'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
      );

      expect(result, isA<UdsTransactionTerminalNegative>());
      final neg = result as UdsTransactionTerminalNegative;
      expect(neg.nrc.code, 0x99);
      expect(neg.nrc.isKnown, isFalse);
      expect(neg.originalSid, 0x22);
    });

    test('Boundary: Correlation ID and sequential request IDs across retries',
        () async {
      final clock = FakeUdsClock();
      final policy = UdsTransactionPolicy(
        busyRepeatDelay: const Duration(milliseconds: 50),
        maxBusyRepeatRetries: 2,
      );
      final engine = UdsTransactionEngine(policy: policy, clock: clock);

      final capturedRequestIds = <DiagnosticRequestId>[];
      var sendCount = 0;

      final channel = CallbackUdsTransactionChannel(
        onSend: (id, pdu, _) async {
          capturedRequestIds.add(id);
          sendCount++;
          if (sendCount < 3) {
            return DiagnosticMessage(pdu: ApplicationPdu([0x7F, 0x22, 0x21]));
          }
          return DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x99]),
          );
        },
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation expected'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
        correlationId: 'tx-test',
      );

      expect(result, isA<UdsTransactionSuccess>());
      expect(capturedRequestIds.length, 3);
      expect(capturedRequestIds[0].value, 'tx-test-1');
      expect(capturedRequestIds[1].value, 'tx-test-2');
      expect(capturedRequestIds[2].value, 'tx-test-3');
    });

    test('Boundary: State transitions follow strict deterministic sequence',
        () async {
      final clock = FakeUdsClock();
      final policy = UdsTransactionPolicy(
        busyRepeatDelay: const Duration(milliseconds: 50),
      );
      final engine = UdsTransactionEngine(policy: policy, clock: clock);

      final recordedStates = <UdsTransactionState>[];
      var sendCount = 0;

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async {
          sendCount++;
          if (sendCount == 1) {
            return DiagnosticMessage(pdu: ApplicationPdu([0x7F, 0x22, 0x21]));
          }
          return DiagnosticMessage(pdu: ApplicationPdu([0x7F, 0x22, 0x78]));
        },
        onReceiveContinuation: (_) async =>
            DiagnosticMessage(pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x11])),
      );

      await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
        onStateChange: recordedStates.add,
      );

      expect(recordedStates, [
        UdsTransactionState.created,
        UdsTransactionState.sendingInitial,
        UdsTransactionState.awaitingP2,
        UdsTransactionState.busyRepeatDelay,
        UdsTransactionState.sendingRetry,
        UdsTransactionState.awaitingP2,
        UdsTransactionState.awaitingP2Star,
        UdsTransactionState.completed,
      ]);
    });

    test('Boundary: expectedResponder rejects null sourceAddress as sourceMismatch',
        () async {
      final clock = FakeUdsClock();
      final engine = UdsTransactionEngine(clock: clock);

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async => DiagnosticMessage(
          pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x11]),
          sourceAddress: null,
        ),
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation expected'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
        expectedResponder: DiagnosticSourceAddress('7E8'),
      );

      expect(result, isA<UdsTransactionSourceMismatch>());
      final mismatch = result as UdsTransactionSourceMismatch;
      expect(mismatch.expectedSource, DiagnosticSourceAddress('7E8'));
      expect(mismatch.actualSource, isNull);
    });

    test('Boundary: target as PhysicalCanDiagnosticTarget automatically binds expectedResponder',
        () async {
      final clock = FakeUdsClock();
      final engine = UdsTransactionEngine(clock: clock);

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async => DiagnosticMessage(
          pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x11]),
          sourceAddress: DiagnosticSourceAddress('7E9'),
        ),
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation expected'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        ),
      );

      expect(result, isA<UdsTransactionSourceMismatch>());
      final mismatch = result as UdsTransactionSourceMismatch;
      expect(mismatch.expectedSource, DiagnosticSourceAddress('7E8'));
      expect(mismatch.actualSource, DiagnosticSourceAddress('7E9'));
    });

    test('Boundary: unhandled exception in channel.send finalizes state to completed',
        () async {
      final clock = FakeUdsClock();
      final engine = UdsTransactionEngine(clock: clock);
      final recordedStates = <UdsTransactionState>[];

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async => throw StateError('Transport send error'),
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation expected'),
      );

      await expectLater(
        engine.execute(
          request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
          channel: channel,
          onStateChange: recordedStates.add,
        ),
        throwsA(isA<StateError>()),
      );

      expect(recordedStates.last, UdsTransactionState.completed);
    });

    test('Boundary: unhandled exception in channel.receiveContinuation finalizes state to completed',
        () async {
      final clock = FakeUdsClock();
      final engine = UdsTransactionEngine(clock: clock);
      final recordedStates = <UdsTransactionState>[];

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async =>
            DiagnosticMessage(pdu: ApplicationPdu([0x7F, 0x22, 0x78])),
        onReceiveContinuation: (_) async =>
            throw StateError('Continuation socket error'),
      );

      await expectLater(
        engine.execute(
          request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
          channel: channel,
          onStateChange: recordedStates.add,
        ),
        throwsA(isA<StateError>()),
      );

      expect(recordedStates.last, UdsTransactionState.completed);
    });

    test('Boundary: conflicting expectedResponder and PhysicalCanDiagnosticTarget fails closed with ArgumentError',
        () async {
      final clock = FakeUdsClock();
      final engine = UdsTransactionEngine(clock: clock);

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async => DiagnosticMessage(
          pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x11]),
          sourceAddress: DiagnosticSourceAddress('7E8'),
        ),
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation expected'),
      );

      await expectLater(
        engine.execute(
          request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
          channel: channel,
          target: DiagnosticTarget.physicalCan(
            requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
            expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
          ),
          expectedResponder: DiagnosticSourceAddress('7E9'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Boundary: consistent explicit expectedResponder matching PhysicalCanDiagnosticTarget succeeds',
        () async {
      final clock = FakeUdsClock();
      final engine = UdsTransactionEngine(clock: clock);

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async => DiagnosticMessage(
          pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x11]),
          sourceAddress: DiagnosticSourceAddress('7E8'),
        ),
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation expected'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        ),
        expectedResponder: DiagnosticSourceAddress('7E8'),
      );

      expect(result, isA<UdsTransactionSuccess>());
      final pos = result as UdsTransactionSuccess;
      expect(pos.responseBytes, [0x62, 0x01, 0x00, 0x11]);
    });
  });
}
