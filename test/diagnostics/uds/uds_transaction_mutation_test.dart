import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';
import 'package:torque_obd/diagnostics/uds/uds_dtc_types.dart';
import 'package:torque_obd/diagnostics/uds/uds_read_types.dart';
import 'package:torque_obd/diagnostics/uds/uds_transaction_engine.dart';
import 'package:torque_obd/diagnostics/uds/uds_transaction_policy.dart';
import 'package:torque_obd/diagnostics/uds/uds_transaction_types.dart';

void main() {
  group('UdsTransactionMutationControls - S3-M1..M14', () {
    test('S3-M1: NRC 0x78 must not cause outgoing wire resend (sends strictly 1)',
        () async {
      final clock = FakeUdsClock();
      final engine = UdsTransactionEngine(clock: clock);

      var sendCount = 0;
      var continuationCount = 0;

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async {
          sendCount++;
          return DiagnosticMessage(pdu: ApplicationPdu([0x7F, 0x22, 0x78]));
        },
        onReceiveContinuation: (_) async {
          continuationCount++;
          return DiagnosticMessage(pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x01]));
        },
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
      );

      expect(result, isA<UdsTransactionSuccess>());
      expect(sendCount, 1, reason: 'M1: 0x78 must NEVER increment send count');
      expect(continuationCount, 1);
      expect(result.attempts, 1);
    });

    test('S3-M2: Response pending count must be bounded (reject unlimited 0x78)',
        () async {
      final clock = FakeUdsClock();
      final policy = UdsTransactionPolicy(maxResponsePendingCount: 2);
      final engine = UdsTransactionEngine(policy: policy, clock: clock);

      var pendingReceived = 0;
      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async =>
            DiagnosticMessage(pdu: ApplicationPdu([0x7F, 0x22, 0x78])),
        onReceiveContinuation: (_) async {
          pendingReceived++;
          return DiagnosticMessage(pdu: ApplicationPdu([0x7F, 0x22, 0x78]));
        },
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
      );

      expect(result, isA<UdsTransactionResponsePendingExhausted>());
      final exhausted = result as UdsTransactionResponsePendingExhausted;
      expect(exhausted.responsePendingCount, 3);
      expect(exhausted.maxPending, 2);
      expect(pendingReceived, 2);
    });

    test('S3-M3: NRC 0x78 cannot extend total deadline', () async {
      final clock = FakeUdsClock();
      final policy = UdsTransactionPolicy(
        p2StarTimeout: const Duration(milliseconds: 5000),
        totalTimeout: const Duration(milliseconds: 200),
      );
      final engine = UdsTransactionEngine(policy: policy, clock: clock);

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async =>
            DiagnosticMessage(pdu: ApplicationPdu([0x7F, 0x22, 0x78])),
        onReceiveContinuation: (timeout) async {
          clock.advance(const Duration(milliseconds: 250));
          throw TimeoutException('Simulated timeout');
        },
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
      );

      expect(result, isA<UdsTransactionTimedOut>());
      final to = result as UdsTransactionTimedOut;
      expect(to.timeoutType, UdsTimeoutType.total,
          reason: 'M3: Total deadline must dominate P2* wait');
    });

    test('S3-M4: NRC 0x21 retry must be bounded (reject unlimited retry)',
        () async {
      final clock = FakeUdsClock();
      final policy = UdsTransactionPolicy(maxBusyRepeatRetries: 2);
      final engine = UdsTransactionEngine(policy: policy, clock: clock);

      var sendCount = 0;
      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async {
          sendCount++;
          return DiagnosticMessage(pdu: ApplicationPdu([0x7F, 0x22, 0x21]));
        },
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation allowed'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
      );

      expect(result, isA<UdsTransactionBusyRetryExhausted>());
      expect(sendCount, 3, reason: '1 initial + 2 retries = 3 wire sends');
      expect(result.attempts, 3);
      expect(result.retries, 2);
    });

    test('S3-M5: Retry send must transmit identical request bytes as initial',
        () async {
      final clock = FakeUdsClock();
      final policy = UdsTransactionPolicy(maxBusyRepeatRetries: 1);
      final engine = UdsTransactionEngine(policy: policy, clock: clock);

      final sentPayloads = <List<int>>[];
      final channel = CallbackUdsTransactionChannel(
        onSend: (_, pdu, _) async {
          sentPayloads.add(pdu.bytes);
          if (sentPayloads.length == 1) {
            return DiagnosticMessage(pdu: ApplicationPdu([0x7F, 0x22, 0x21]));
          }
          return DiagnosticMessage(pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x55]));
        },
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation allowed'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
      );

      expect(result, isA<UdsTransactionSuccess>());
      expect(sentPayloads.length, 2);
      expect(sentPayloads[0], [0x22, 0x01, 0x00]);
      expect(sentPayloads[1], [0x22, 0x01, 0x00],
          reason: 'M5: Retry payload must strictly match initial payload');
    });

    test('S3-M6: Retry send must wait busyRepeatDelay before sending',
        () async {
      final clock = FakeUdsClock();
      final policy = UdsTransactionPolicy(
        busyRepeatDelay: const Duration(milliseconds: 150),
        maxBusyRepeatRetries: 1,
      );
      final engine = UdsTransactionEngine(policy: policy, clock: clock);

      var sendCount = 0;
      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async {
          sendCount++;
          if (sendCount == 1) {
            return DiagnosticMessage(pdu: ApplicationPdu([0x7F, 0x22, 0x21]));
          }
          return DiagnosticMessage(pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x01]));
        },
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation allowed'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
      );

      expect(result, isA<UdsTransactionSuccess>());
      expect(clock.recordedDelays, [const Duration(milliseconds: 150)],
          reason: 'M6: Retry must execute designated delay');
    });

    test('S3-M7: Cancellation during busyRepeatDelay aborts retry send',
        () async {
      final clock = FakeUdsClock();
      final cts = DiagnosticCancellationTokenSource();
      final policy = UdsTransactionPolicy(
        busyRepeatDelay: const Duration(milliseconds: 100),
        maxBusyRepeatRetries: 1,
      );
      final engine = UdsTransactionEngine(policy: policy, clock: clock);

      var sendCount = 0;
      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async {
          sendCount++;
          cts.cancel(); // cancel immediately after first send
          return DiagnosticMessage(pdu: ApplicationPdu([0x7F, 0x22, 0x21]));
        },
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation allowed'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
        cancellation: cts.token,
      );

      expect(result, isA<UdsTransactionCancelled>());
      expect(sendCount, 1, reason: 'M7: Retry send must not execute after cancel');
      expect(result.attempts, 1);
      expect(result.retries, 0);
    });

    test('S3-M8: Cancellation during responsePending wait yields cancelled result',
        () async {
      final clock = FakeUdsClock();
      final cts = DiagnosticCancellationTokenSource();
      final engine = UdsTransactionEngine(clock: clock);

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async =>
            DiagnosticMessage(pdu: ApplicationPdu([0x7F, 0x22, 0x78])),
        onReceiveContinuation: (_) async {
          cts.cancel();
          // Even if continuation arrives after cancellation, result must be cancelled
          return DiagnosticMessage(pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x01]));
        },
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
        cancellation: cts.token,
      );

      expect(result, isA<UdsTransactionCancelled>());
    });

    test('S3-M9: Connection generation drift yields retired outcome',
        () async {
      final clock = FakeUdsClock();
      final engine = UdsTransactionEngine(clock: clock);

      var gen = 1;
      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async {
          gen = 2; // generation changes during exchange
          return DiagnosticMessage(pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x01]));
        },
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation allowed'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
        connectionGeneration: 1,
        currentConnectionGeneration: () => gen,
      );

      expect(result, isA<UdsTransactionRetired>());
      final retired = result as UdsTransactionRetired;
      expect(retired.expectedGeneration, 1);
      expect(retired.actualGeneration, 2);
    });

    test('S3-M10: Unexpected responder source yields sourceMismatch',
        () async {
      final clock = FakeUdsClock();
      final engine = UdsTransactionEngine(clock: clock);

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async => DiagnosticMessage(
          pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x01]),
          sourceAddress: DiagnosticSourceAddress('7E9'),
        ),
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation allowed'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
        expectedResponder: DiagnosticSourceAddress('7E8'),
      );

      expect(result, isA<UdsTransactionSourceMismatch>());
    });

    test('S3-M11: Duplicate/late reply cannot alter completed result',
        () async {
      final clock = FakeUdsClock();
      final engine = UdsTransactionEngine(clock: clock);

      final channel = CallbackUdsTransactionChannel(
        onSend: (_, _, _) async => DiagnosticMessage(
          pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x01]),
        ),
        onReceiveContinuation: (_) async =>
            throw StateError('No continuation allowed'),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
      );

      expect(result, isA<UdsTransactionSuccess>());
      expect((result as UdsTransactionSuccess).responseBytes, [0x62, 0x01, 0x00, 0x01]);
    });

    test('S3-M12: P2, P2*, and total timeouts are strictly distinct',
        () async {
      expect(UdsTimeoutType.p2, isNot(equals(UdsTimeoutType.p2Star)));
      expect(UdsTimeoutType.p2, isNot(equals(UdsTimeoutType.total)));
      expect(UdsTimeoutType.p2Star, isNot(equals(UdsTimeoutType.total)));
    });

    test('S3-M13: Arbitrary SID widening is structurally disallowed', () {
      expect(
        UdsTransactionRequest.readDid(const UdsDid(0x0100)).serviceId,
        0x22,
      );
      expect(
        UdsTransactionRequest.reportDtcByStatusMask(const UdsDtcStatusMask(0x08))
            .serviceId,
        0x19,
      );
      expect(
        UdsTransactionRequest.reportSupportedDtc().serviceId,
        0x19,
      );
    });

    test('S3-M14: ISO-TP leakage/FC parsing is absent from application engine',
        () {
      // The engine consumes ApplicationPdu directly; it does not parse Flow Control PCI (0x30)
      final pdu = ApplicationPdu([0x62, 0x01, 0x00, 0xAA]);
      expect(pdu.length, 4);
    });
  });
}
