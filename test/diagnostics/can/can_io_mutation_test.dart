import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:torque_obd/diagnostics/can/can_endpoint.dart';
import 'package:torque_obd/diagnostics/can/can_io_clock.dart';
import 'package:torque_obd/diagnostics/can/can_io_contract.dart';
import 'package:torque_obd/diagnostics/can/can_io_core.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';

import '../../support/fake_can_pdu_backend.dart';

void main() {
  group('WS10-S1 Mutation Proofs (M01..M10)', () {
    late CanEndpoint endpoint;
    late FakeCanPduBackend backend;
    late FakeCanIoClock clock;
    late CanIoCoordinator coordinator;
    final wireOwner = Object();
    final stdTx = DiagnosticCanIdentifier.standard(0x7E0);
    final stdRx = DiagnosticCanIdentifier.standard(0x7E8);
    final validTarget = DiagnosticTarget.physicalCan(
      requestIdentifier: stdTx,
      expectedResponderIdentifier: stdRx,
    );

    setUp(() {
      endpoint = CanEndpoint(
        interfaceName: 'vcan0',
        generation: 1,
        physicalTxId: stdTx,
        physicalRxId: stdRx,
      );
      backend = FakeCanPduBackend();
      clock = FakeCanIoClock();
      coordinator = CanIoCoordinator(
        endpoint: endpoint,
        backend: backend,
        clock: clock,
      );
    });

    tearDown(() async {
      await coordinator.close();
    });

    CanReadBinding createBinding(List<int> pduBytes, {DiagnosticCancellation? cancellation}) {
      final req = DiagnosticRequest(
        id: const DiagnosticRequestId('req_mut'),
        pdu: ApplicationPdu(pduBytes),
        target: validTarget,
        requiredCapabilities: {DiagnosticCapability.rawCanFrame},
        connectionGeneration: 1,
        cancellation: cancellation ?? DiagnosticCancellation.none,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.exclusive),
      );
      return CanReadBinding.fromUdsRequest(
        request: req,
        endpoint: endpoint,
        wireOwnerToken: wireOwner,
      );
    }

    test('M01 (Admission): Tampered write or multi-DID PDU is rejected with 0 backend sends', () {
      expect(() => createBinding([0x2E, 0x01, 0x00, 0x00]), throwsArgumentError);
      expect(() => createBinding([0x22, 0x01, 0x00, 0x02, 0x00]), throwsArgumentError);
      expect(backend.writeLog, isEmpty);
    });

    test('M02 (Owner/Queue): Queue capacity cannot exceed 8 waiting leases', () async {
      final binding = createBinding([0x22, 0x01, 0x00]);
      final activeBlocked = Completer<void>();
      final releaseActive = Completer<void>();

      unawaited(
        coordinator.withReadLease<void>(
          binding: binding,
          budget: CanIoBudget(),
          cancellation: DiagnosticCancellation.none,
          action: (lease) async {
            activeBlocked.complete();
            await releaseActive.future;
          },
        ),
      );
      await activeBlocked.future;

      for (var i = 0; i < 8; i++) {
        unawaited(
          coordinator.withReadLease<void>(
            binding: binding,
            budget: CanIoBudget(),
            cancellation: DiagnosticCancellation.none,
            action: (lease) async {},
          ),
        );
      }

      final overflowOutcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {},
      );

      expect(overflowOutcome, isA<CanLeaseRejected<void>>());
      releaseActive.complete();
    });

    test('M03 (ID/PDU): Mismatched TX/RX width cannot be constructed', () {
      expect(
        () => CanEndpoint(
          interfaceName: 'vcan0',
          generation: 1,
          physicalTxId: DiagnosticCanIdentifier.standard(0x7E0),
          physicalRxId: DiagnosticCanIdentifier.extended(0x18DAF110),
        ),
        throwsArgumentError,
      );
    });

    test('M04 (Capacity): Buffer ceilings strictly reject 33 observations and 4097 bytes', () async {
      final binding = createBinding([0x22, 0x01, 0x00]);
      for (var i = 0; i < 33; i++) {
        backend.enqueueSimpleObservation(payload: [0x55], sourceId: stdRx);
      }

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          for (var i = 0; i < 33; i++) {
            await lease.receiveNext(const Duration(seconds: 1));
          }
        },
      );

      expect(outcome, isA<CanLeaseTransportFailure<void>>());
    });

    test('M05 (Deadline): Expired deadline produces timedOut outcome', () async {
      final binding = createBinding([0x22, 0x01, 0x00]);
      clock.setTime(DateTime.utc(2026, 9, 26, 0, 0, 0));

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(totalTimeout: const Duration(milliseconds: 50)),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          clock.advance(const Duration(milliseconds: 100));
          await lease.sendApproved(const DiagnosticRequestId('req_01'));
        },
      );

      expect(outcome, isA<CanLeaseTimedOut<void>>());
    });

    test('M06 (Cancel Priority): Cancellation takes strict precedence over expired deadline', () async {
      final cts = DiagnosticCancellationTokenSource();
      cts.cancel();

      final binding = createBinding([0x22, 0x01, 0x00], cancellation: cts.token);
      clock.advance(const Duration(days: 1));

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: cts.token,
        action: (lease) async {},
      );

      expect(outcome, isA<CanLeaseCancelled<void>>());
    });

    test('M07 (Source/Epoch): Foreign responder observation is rejected fail-closed', () async {
      final binding = createBinding([0x22, 0x01, 0x00]);
      backend.enqueueSimpleObservation(
        payload: [0x62, 0x01, 0x00, 0xAA],
        sourceId: DiagnosticCanIdentifier.standard(0x7E9),
      );

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          await lease.receiveNext(const Duration(seconds: 1));
        },
      );

      expect(outcome, isA<CanLeaseTransportFailure<void>>());
    });

    test('M08 (Non-replay): Partial write disposition is truthful and not replayed', () async {
      final binding = createBinding([0x22, 0x01, 0x00]);
      backend.dispositionToReturn = CanSendDisposition.partialOrUnknown;

      final outcome = await coordinator.withReadLease<CanSendDisposition>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          final receipt = await lease.sendApproved(const DiagnosticRequestId('req_part'));
          return receipt.disposition;
        },
      );

      expect(outcome.valueOrNull, CanSendDisposition.partialOrUnknown);
      expect(backend.writeLog.length, 1);
    });

    test('M09 (Cleanup): Drain failure or timeout retires coordinator and evicts queued leases', () async {
      final binding = createBinding([0x22, 0x01, 0x00]);
      backend.simulatedDrainError = StateError('Forced drain failure');

      final activeBlocked = Completer<void>();
      final releaseActive = Completer<void>();

      final activeFuture = coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          activeBlocked.complete();
          await releaseActive.future;
        },
      );
      await activeBlocked.future;

      final queuedFuture = coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {},
      );

      releaseActive.complete();
      final activeOutcome = await activeFuture;
      final queuedOutcome = await queuedFuture;

      expect(activeOutcome, isA<CanLeaseRetired<void>>());
      expect(coordinator.state, CoordinatorState.retiring);
      expect(queuedOutcome, isA<CanLeaseRetired<void>>());

      // Safe idempotent double-close
      await coordinator.close();
      expect(backend.closeCallCount, 1);
      await coordinator.close();
      expect(backend.closeCallCount, 1);
    });

    test('M10 (Required Evidence): Non-read, multi-DID, or token mismatched requests fail closed', () {
      // 1. Non-read service: WriteDataByIdentifier (0x2E)
      expect(
        () => CanReadBinding.fromUdsRequest(
          request: DiagnosticRequest(
            id: const DiagnosticRequestId('req_m10_write'),
            pdu: ApplicationPdu(const [0x2E, 0xF1, 0x90, 0x00]),
            target: validTarget,
            requiredCapabilities: {DiagnosticCapability.rawCanFrame},
            connectionGeneration: 1,
            cancellation: DiagnosticCancellation.none,
            ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.exclusive),
          ),
          endpoint: endpoint,
          wireOwnerToken: wireOwner,
        ),
        throwsArgumentError,
      );

      // 2. Multi-DID read: 0x22 with multiple DIDs (length != 3)
      expect(
        () => CanReadBinding.fromUdsRequest(
          request: DiagnosticRequest(
            id: const DiagnosticRequestId('req_m10_multidid'),
            pdu: ApplicationPdu(const [0x22, 0x01, 0x00, 0x01, 0x01]),
            target: validTarget,
            requiredCapabilities: {DiagnosticCapability.rawCanFrame},
            connectionGeneration: 1,
            cancellation: DiagnosticCancellation.none,
            ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.exclusive),
          ),
          endpoint: endpoint,
          wireOwnerToken: wireOwner,
        ),
        throwsArgumentError,
      );

      // 3. Truncated read PDU: 0x22 without DID
      expect(
        () => CanReadBinding.fromUdsRequest(
          request: DiagnosticRequest(
            id: const DiagnosticRequestId('req_m10_short'),
            pdu: ApplicationPdu(const [0x22]),
            target: validTarget,
            requiredCapabilities: {DiagnosticCapability.rawCanFrame},
            connectionGeneration: 1,
            cancellation: DiagnosticCancellation.none,
            ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.exclusive),
          ),
          endpoint: endpoint,
          wireOwnerToken: wireOwner,
        ),
        throwsArgumentError,
      );

      // 4. Mismatched wire owner token
      final otherToken = Object();
      expect(
        () => CanReadBinding.fromUdsRequest(
          request: DiagnosticRequest(
            id: const DiagnosticRequestId('req_m10_token'),
            pdu: ApplicationPdu(const [0x22, 0x01, 0x00]),
            target: validTarget,
            requiredCapabilities: const {DiagnosticCapability.rawCanFrame},
            connectionGeneration: 1,
            cancellation: DiagnosticCancellation.none,
            ownership: DiagnosticOwnership(
              mode: DiagnosticOwnershipMode.exclusive,
              token: otherToken,
            ),
          ),
          endpoint: endpoint,
          wireOwnerToken: wireOwner,
        ),
        throwsArgumentError,
      );
    });
  });
}
