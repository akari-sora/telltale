import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:torque_obd/diagnostics/can/can_endpoint.dart';
import 'package:torque_obd/diagnostics/can/can_io_clock.dart';
import 'package:torque_obd/diagnostics/can/can_io_contract.dart';
import 'package:torque_obd/diagnostics/can/can_io_core.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';

import '../../support/fake_can_pdu_backend.dart';

void main() {
  group('CanIoCoordinator Core Tests', () {
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

    CanReadBinding createBinding({
      required List<int> pduBytes,
      DiagnosticRequestId? requestId,
      int generation = 1,
      DiagnosticTarget? target,
      DiagnosticCancellation cancellation = DiagnosticCancellation.none,
    }) {
      final req = DiagnosticRequest(
        id: requestId ?? const DiagnosticRequestId('req_01'),
        pdu: ApplicationPdu(pduBytes),
        target: target ?? validTarget,
        requiredCapabilities: {DiagnosticCapability.rawCanFrame},
        connectionGeneration: generation,
        cancellation: cancellation,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.exclusive),
      );
      return CanReadBinding.fromUdsRequest(
        request: req,
        endpoint: endpoint,
        wireOwnerToken: wireOwner,
      );
    }

    test('L02: Admits canonical read PDUs and rejects malformed/non-read PDUs with 0 backend sends', () {
      // 1. Valid 0x22
      final valid22 = createBinding(pduBytes: [0x22, 0x01, 0x00]);
      expect(valid22.canonicalPdu.bytes, [0x22, 0x01, 0x00]);

      // 2. Valid 0x19 0x02
      final valid19_02 = createBinding(pduBytes: [0x19, 0x02, 0xFF]);
      expect(valid19_02.canonicalPdu.bytes, [0x19, 0x02, 0xFF]);

      // 3. Valid 0x19 0x0A
      final valid19_0A = createBinding(pduBytes: [0x19, 0x0A]);
      expect(valid19_0A.canonicalPdu.bytes, [0x19, 0x0A]);

      // 4. Short 0x22 rejected before send
      expect(
        () => createBinding(pduBytes: [0x22, 0x01]),
        throwsArgumentError,
      );

      // 5. Multi-DID 0x22 rejected before send
      expect(
        () => createBinding(pduBytes: [0x22, 0x01, 0x00, 0x02, 0x00]),
        throwsArgumentError,
      );

      // 6. Trailing bytes 0x22 rejected before send
      expect(
        () => createBinding(pduBytes: [0x22, 0x01, 0x00, 0xFF]),
        throwsArgumentError,
      );

      // 7. Non-read SID (0x2E WriteDataByIdentifier) rejected before send
      expect(
        () => createBinding(pduBytes: [0x2E, 0x01, 0x00, 0x00]),
        throwsArgumentError,
      );

      // 8. Unsupported 0x19 subfunction rejected before send
      expect(
        () => createBinding(pduBytes: [0x19, 0x01, 0xFF]),
        throwsArgumentError,
      );

      // Verify backend was never called
      expect(backend.writeLog, isEmpty);
    });

    test('L03: Single active lease, FIFO queue serialization, and 9th queued rejected', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);
      final activeStarted = Completer<void>();
      final releaseActive = Completer<void>();

      // Start active lease that holds lock until releaseActive completes
      final activeFuture = coordinator.withReadLease<int>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          activeStarted.complete();
          await releaseActive.future;
          return 42;
        },
      );

      await activeStarted.future;
      expect(coordinator.activeLeaseCount, 1);
      expect(coordinator.queuedLeaseCount, 0);

      // Queue 8 leases (max allowed queue)
      final queuedFutures = <Future<CanLeaseOutcome<int>>>[];
      for (var i = 1; i <= 8; i++) {
        queuedFutures.add(
          coordinator.withReadLease<int>(
            binding: binding,
            budget: CanIoBudget(),
            cancellation: DiagnosticCancellation.none,
            action: (lease) async => i,
          ),
        );
      }
      expect(coordinator.queuedLeaseCount, 8);

      // 9th lease must be immediately rejected with queue capacity exceeded
      final overflowOutcome = await coordinator.withReadLease<int>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async => 999,
      );
      expect(overflowOutcome, isA<CanLeaseRejected<int>>());
      expect(
        (overflowOutcome as CanLeaseRejected<int>).reason,
        contains('Queue capacity exceeded'),
      );

      // Release active lease and let queued leases complete in FIFO order
      releaseActive.complete();
      final activeOutcome = await activeFuture;
      expect(activeOutcome.valueOrNull, 42);

      final results = await Future.wait(queuedFutures);
      for (var i = 0; i < 8; i++) {
        expect(results[i].valueOrNull, i + 1);
      }
      expect(coordinator.activeLeaseCount, 0);
      expect(coordinator.queuedLeaseCount, 0);
    });

    test('L04: Foreign or released lease throws StateError and executes 0 backend calls', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);
      CanReadLease? capturedLease;

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          capturedLease = lease;
        },
      );
      expect(outcome.isSuccess, isTrue);
      expect(capturedLease, isNotNull);
      expect(capturedLease!.state, LeaseState.released);

      // Attempting to send or receive on a released lease must fail with StateError
      expect(
        () => capturedLease!.sendApproved(const DiagnosticRequestId('req_late')),
        throwsStateError,
      );
      expect(
        () => capturedLease!.receiveNext(const Duration(seconds: 1)),
        throwsStateError,
      );
      expect(backend.writeLog, isEmpty);
    });

    test('L06: Monotonic clock and non-resetting deadline across queueing', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);
      final activeBlocked = Completer<void>();
      final releaseActive = Completer<void>();

      // Active lease starts
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

      // Queued lease with 1 second total budget
      final queuedOutcomeFuture = coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(totalTimeout: const Duration(seconds: 1)),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {},
      );

      // Advance clock past the queued lease deadline (1.5s) while still queued
      clock.advance(const Duration(milliseconds: 1500));

      final outcome = await queuedOutcomeFuture;
      expect(outcome, isA<CanLeaseTimedOut<void>>());
      expect((outcome as CanLeaseTimedOut<void>).reason, contains('Timed out'));

      releaseActive.complete();
    });

    test('L07: Prioritized termination: cancellation > retirement > timeout', () async {
      // 1. Pre-cancelled binding prioritizes over expired deadline
      final cts = DiagnosticCancellationTokenSource();
      cts.cancel();

      // Expired deadline
      clock.setTime(DateTime.utc(2026, 9, 26, 12, 0, 0));
      final expiredReq = DiagnosticRequest(
        id: const DiagnosticRequestId('req_expired'),
        pdu: ApplicationPdu([0x22, 0x01, 0x00]),
        target: validTarget,
        requiredCapabilities: {DiagnosticCapability.rawCanFrame},
        connectionGeneration: 1,
        deadline: DateTime.utc(2026, 9, 26, 11, 0, 0),
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.exclusive),
      );
      final binding = CanReadBinding.fromUdsRequest(
        request: expiredReq,
        endpoint: endpoint,
        wireOwnerToken: wireOwner,
      );

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: cts.token,
        action: (lease) async {},
      );

      expect(outcome, isA<CanLeaseCancelled<void>>());
      expect(backend.writeLog, isEmpty);
    });

    test('L08: Source attribution mismatch is rejected and does not pollute results', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);

      // Enqueue observation from a foreign ECU (0x7E9 instead of expected 0x7E8)
      backend.enqueueSimpleObservation(
        payload: [0x62, 0x01, 0x00, 0xAA],
        sourceId: DiagnosticCanIdentifier.standard(0x7E9),
      );

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          await lease.sendApproved(const DiagnosticRequestId('req_01'));
          await lease.receiveNext(const Duration(seconds: 1));
        },
      );

      expect(outcome, isA<CanLeaseTransportFailure<void>>());
      expect(
        (outcome as CanLeaseTransportFailure<void>).error.toString(),
        contains('Observation source'),
      );
    });

    test('L09: Send ceiling enforces max explicit attempts and core has 0 auto-retry', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(maxExplicitAttempts: 2),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          await lease.sendApproved(const DiagnosticRequestId('attempt_1'));
          await lease.sendApproved(const DiagnosticRequestId('attempt_2'));
          // 3rd attempt exceeds ceiling of 2
          await lease.sendApproved(const DiagnosticRequestId('attempt_3'));
        },
      );

      expect(outcome, isA<CanLeaseTransportFailure<void>>());
      expect(
        (outcome as CanLeaseTransportFailure<void>).error.toString(),
        contains('Send ceiling exceeded'),
      );
      expect(backend.writeLog.length, 2);
    });

    test('L10: Truthful write disposition reflects backend state accurately without auto-replay', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);
      backend.dispositionToReturn = CanSendDisposition.partialOrUnknown;

      late CanWriteReceipt receipt;
      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          receipt = await lease.sendApproved(const DiagnosticRequestId('req_01'));
        },
      );

      expect(outcome.isSuccess, isTrue);
      expect(receipt.disposition, CanSendDisposition.partialOrUnknown);
      expect(backend.writeLog.single.disposition, CanSendDisposition.partialOrUnknown);
    });

    test('L11: Cleanup runs bounded drain and coordinator close is idempotent', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);

      final outcome = await coordinator.withReadLease<int>(
        binding: binding,
        budget: CanIoBudget(cleanupBudget: const Duration(milliseconds: 150)),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async => 100,
      );

      expect(outcome.valueOrNull, 100);
      expect(backend.drainCallCount, 1);
      expect(backend.lastDrainTimeout, const Duration(milliseconds: 150));

      // Double-close coordinator safely
      await coordinator.close();
      expect(backend.closeCallCount, 1);
      expect(coordinator.state, CoordinatorState.closed);

      await coordinator.close();
      expect(backend.closeCallCount, 1);
    });

    test('L11: Cleanup timeout forces coordinator retirement and prevents queued lease release', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);
      backend.simulatedDrainDelay = const Duration(milliseconds: 300);

      final activeBlocked = Completer<void>();
      final releaseActive = Completer<void>();

      final activeFuture = coordinator.withReadLease<int>(
        binding: binding,
        budget: CanIoBudget(cleanupBudget: const Duration(milliseconds: 50)),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          activeBlocked.complete();
          await releaseActive.future;
          return 42;
        },
      );

      await activeBlocked.future;

      final queuedFuture = coordinator.withReadLease<int>(
        binding: binding,
        budget: CanIoBudget(cleanupBudget: const Duration(milliseconds: 50)),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async => 99,
      );

      expect(coordinator.queuedLeaseCount, 1);
      releaseActive.complete();

      final activeOutcome = await activeFuture;
      final queuedOutcome = await queuedFuture;

      expect(activeOutcome, isA<CanLeaseRetired<int>>());
      expect(coordinator.state, CoordinatorState.retiring);
      expect(queuedOutcome, isA<CanLeaseRetired<int>>());
      expect(coordinator.queuedLeaseCount, 0);
    });

    test('L11: Cleanup drain failure forces coordinator retirement and evicts queued leases', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);
      backend.simulatedDrainError = StateError('Drain hardware error');

      final activeBlocked = Completer<void>();
      final releaseActive = Completer<void>();

      final activeFuture = coordinator.withReadLease<int>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          activeBlocked.complete();
          await releaseActive.future;
          return 77;
        },
      );

      await activeBlocked.future;

      final queuedFuture = coordinator.withReadLease<int>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async => 88,
      );

      releaseActive.complete();

      final activeOutcome = await activeFuture;
      final queuedOutcome = await queuedFuture;

      expect(activeOutcome, isA<CanLeaseRetired<int>>());
      expect(coordinator.state, CoordinatorState.retiring);
      expect(queuedOutcome, isA<CanLeaseRetired<int>>());
    });

    test('Success revalidation: clock advance past deadline during action yields timeout', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);
      final budget = CanIoBudget(totalTimeout: const Duration(milliseconds: 500));

      final outcome = await coordinator.withReadLease<int>(
        binding: binding,
        budget: budget,
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          // Advance clock beyond lease total deadline
          clock.advance(const Duration(milliseconds: 600));
          return 123;
        },
      );

      expect(outcome, isA<CanLeaseTimedOut<int>>());
      expect(outcome.valueOrNull, isNull);
    });

    test('Success revalidation: cancellation during action yields cancelled outcome', () async {
      final cts = DiagnosticCancellationTokenSource();
      final binding = createBinding(
        pduBytes: [0x22, 0x01, 0x00],
        cancellation: cts.token,
      );

      final outcome = await coordinator.withReadLease<int>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: cts.token,
        action: (lease) async {
          cts.cancel();
          return 456;
        },
      );

      expect(outcome, isA<CanLeaseCancelled<int>>());
      expect(outcome.valueOrNull, isNull);
    });

    test('Success revalidation: coordinator close during action yields retired outcome', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);

      final outcome = await coordinator.withReadLease<int>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          unawaited(coordinator.close());
          return 789;
        },
      );

      expect(outcome, isA<CanLeaseRetired<int>>());
      expect(outcome.valueOrNull, isNull);
    });

    test('Attempt ID uniqueness: duplicate attemptId within lease throws ArgumentError', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);
      backend.enqueueSimpleObservation(
        payload: [0x62, 0x01, 0x00, 0x11],
        sourceId: stdRx,
      );

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(phaseBudget: const Duration(seconds: 1)),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          await lease.sendApproved(const DiagnosticRequestId('req_unique_01'));
          expect(
            () => lease.sendApproved(const DiagnosticRequestId('req_unique_01')),
            throwsArgumentError,
          );
        },
      );

      expect(outcome, isA<CanLeaseSuccess<void>>());
    });

    test('Concurrent close: multiple close calls share single Future and execute once', () async {
      final f1 = coordinator.close();
      final f2 = coordinator.close();
      final f3 = coordinator.close();

      await Future.wait([f1, f2, f3]);
      expect(coordinator.state, CoordinatorState.closed);
      expect(backend.closeCallCount, 1);
    });

    test('CanReadBinding fail-closed: outerDeadline cannot extend request.deadline', () {
      final reqDeadline = DateTime.utc(2026, 9, 26, 12, 0, 0);
      final outerExtended = DateTime.utc(2026, 9, 26, 12, 5, 0);

      final req = DiagnosticRequest(
        id: const DiagnosticRequestId('req_dl'),
        pdu: ApplicationPdu(const [0x22, 0x01, 0x00]),
        target: validTarget,
        requiredCapabilities: {DiagnosticCapability.rawCanFrame},
        connectionGeneration: 1,
        deadline: reqDeadline,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.exclusive),
      );

      final binding = CanReadBinding.fromUdsRequest(
        request: req,
        endpoint: endpoint,
        wireOwnerToken: wireOwner,
        outerDeadline: outerExtended,
      );

      expect(binding.outerDeadline, reqDeadline);
    });

    test('Monotonic clock stability: system clock elapsed increases monotonically', () {
      final sysClock = CanIoClock.system();
      final t1 = sysClock.now();
      final e1 = sysClock.elapsed;
      expect(e1, greaterThanOrEqualTo(Duration.zero));
      expect(sysClock.now().isAfter(t1) || sysClock.now().isAtSameMomentAs(t1), isTrue);

      final fakeClock = FakeCanIoClock(DateTime.utc(2026, 1, 1));
      fakeClock.advance(const Duration(seconds: 10));
      expect(fakeClock.elapsed, const Duration(seconds: 10));
      expect(() => fakeClock.advance(const Duration(seconds: -1)), throwsArgumentError);
      expect(
        () => fakeClock.setTime(DateTime.utc(2025, 12, 31)),
        throwsArgumentError,
      );
    });
  });
}
