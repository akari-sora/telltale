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
      DateTime? deadline,
    }) {
      final req = DiagnosticRequest(
        id: requestId ?? const DiagnosticRequestId('req_01'),
        pdu: ApplicationPdu(pduBytes),
        target: target ?? validTarget,
        requiredCapabilities: {DiagnosticCapability.rawCanFrame},
        connectionGeneration: generation,
        cancellation: cancellation,
        deadline: deadline,
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

    test('C03: Phase deadline expiration rejects late backend return with TimeoutException', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);
      backend.simulatedReadDelay = const Duration(milliseconds: 60);

      backend.enqueueSimpleObservation(
        payload: [0x62, 0x01, 0x00, 0xAA],
        sourceId: stdRx,
      );

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(
          phaseBudget: const Duration(milliseconds: 20),
          totalTimeout: const Duration(seconds: 2),
        ),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          await lease.receiveNext(const Duration(milliseconds: 20));
        },
      );

      expect(outcome, isA<CanLeaseTimedOut<void>>());
      expect(
        (outcome as CanLeaseTimedOut<void>).reason,
        contains('Timed out'),
      );
    });

    test('C03: Unreturning action is bounded by total timeout and does not hang', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);
      final neverCompletes = Completer<int>();

      final outcome = await coordinator.withReadLease<int>(
        binding: binding,
        budget: CanIoBudget(totalTimeout: const Duration(milliseconds: 50)),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async => neverCompletes.future,
      );

      expect(outcome, isA<CanLeaseTimedOut<int>>());
    });

    test('C03: Operations on active lease after coordinator close throw StateError without backend call', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          await coordinator.close();
          // Attempting send after coordinator closed must fail immediately in _assertActive
          expect(
            () => lease.sendApproved(const DiagnosticRequestId('req_late_closed')),
            throwsStateError,
          );
          expect(
            () => lease.receiveNext(const Duration(seconds: 1)),
            throwsStateError,
          );
        },
      );

      expect(outcome, isA<CanLeaseRetired<void>>());
      expect(backend.writeLog, isEmpty);
    });

    test('C04: Concurrent close failure is shared across all concurrent callers', () async {
      backend.simulatedCloseDelay = const Duration(milliseconds: 30);
      backend.simulatedCloseError = StateError('Hardware close failure');

      final f1 = coordinator.close();
      final f2 = coordinator.close();
      final f3 = coordinator.close();

      Object? err1;
      Object? err2;
      Object? err3;

      await Future.wait([
        f1.catchError((e) {
          err1 = e;
        }),
        f2.catchError((e) {
          err2 = e;
        }),
        f3.catchError((e) {
          err3 = e;
        }),
      ]);

      expect(err1, isA<StateError>());
      expect(err2, isA<StateError>());
      expect(err3, isA<StateError>());
      expect((err1 as StateError).message, 'Hardware close failure');
      expect((err2 as StateError).message, 'Hardware close failure');
      expect((err3 as StateError).message, 'Hardware close failure');
      expect(coordinator.state, CoordinatorState.closed);
    });

    test('C04: Cancellation or retirement during cleanup drain invalidates prior success', () async {
      final cts = DiagnosticCancellationTokenSource();
      final binding = createBinding(
        pduBytes: [0x22, 0x01, 0x00],
        cancellation: cts.token,
      );
      backend.simulatedDrainDelay = const Duration(milliseconds: 60);

      final outcomeFuture = coordinator.withReadLease<int>(
        binding: binding,
        budget: CanIoBudget(cleanupBudget: const Duration(milliseconds: 200)),
        cancellation: cts.token,
        action: (lease) async {
          // Trigger cancellation during drain
          Future<void>.delayed(const Duration(milliseconds: 20), () {
            cts.cancel();
          });
          return 999;
        },
      );

      final outcome = await outcomeFuture;
      expect(outcome, isA<CanLeaseCancelled<int>>());
      expect(outcome.valueOrNull, isNull);
    });

    test('C05: Write receipt with mismatched attemptId throws StateError', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);
      backend.customReceiptToReturn = CanWriteReceipt(
        attemptId: const DiagnosticRequestId('foreign_attempt_id'),
        timestamp: DateTime.now(),
        disposition: CanSendDisposition.submitted,
        bytesWritten: 3,
      );

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          await lease.sendApproved(const DiagnosticRequestId('req_01'));
        },
      );

      expect(outcome, isA<CanLeaseTransportFailure<void>>());
      expect(
        (outcome as CanLeaseTransportFailure<void>).error.toString(),
        contains('does not match expected attempt ID'),
      );
    });

    test('C05: Write receipt with inconsistent byte count throws StateError', () async {
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);
      backend.customReceiptToReturn = CanWriteReceipt(
        attemptId: const DiagnosticRequestId('req_01'),
        timestamp: DateTime.now(),
        disposition: CanSendDisposition.submitted,
        bytesWritten: 1, // PDU has length 3, 1 byte is inconsistent
      );

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          await lease.sendApproved(const DiagnosticRequestId('req_01'));
        },
      );

      expect(outcome, isA<CanLeaseTransportFailure<void>>());
      expect(
        (outcome as CanLeaseTransportFailure<void>).error.toString(),
        contains('does not match PDU length'),
      );
    });

    test('C06: Synchronous throw in backend.close() is safely surfaced via Future and shared across all concurrent callers', () async {
      final syncBackend = _SynchronousThrowBackend();
      final syncCoordinator = CanIoCoordinator(
        backend: syncBackend,
        endpoint: endpoint,
        clock: clock,
      );

      final closeFuture1 = syncCoordinator.close();
      final closeFuture2 = syncCoordinator.close();

      expect(closeFuture1, throwsA(isA<StateError>()));
      expect(closeFuture2, throwsA(isA<StateError>()));

      try {
        await closeFuture1;
      } catch (e) {
        expect(e, isA<StateError>());
      }

      expect(syncCoordinator.state, equals(CoordinatorState.closed));
    });

    test('C06: remainingUntilDeadline <= 0 immediately throws TimeoutException before action execution', () async {
      final scriptedClock = _ScriptedAdvancingClock(
        triggerCallIndex: 4,
        advanceAfterCalls: const Duration(seconds: 10),
      );
      final scriptedCoordinator = CanIoCoordinator(
        endpoint: endpoint,
        backend: backend,
        clock: scriptedClock,
      );
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);
      bool actionExecuted = false;

      final outcome = await scriptedCoordinator.withReadLease<int>(
        binding: binding,
        budget: CanIoBudget(totalTimeout: const Duration(seconds: 1)),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          actionExecuted = true;
          return 42;
        },
      );

      expect(actionExecuted, isFalse);
      expect(outcome, isA<CanLeaseTimedOut<int>>());
      expect((outcome as CanLeaseTimedOut<int>).reason, contains('Total lease deadline expired before action execution'));
    });

    test('C06 Barrier: success -> cancel during drain -> drain error yields cancelled outcome', () async {
      final drainEntered = Completer<void>();
      final drainRelease = Completer<void>();

      backend.simulatedDrainCallback = () async {
        drainEntered.complete();
        await drainRelease.future;
        throw StateError('Simulated hardware drain crash');
      };

      bool isCancelled = false;
      final cancellation = DiagnosticCancellation(() => isCancelled);

      final outcomeFuture = coordinator.withReadLease<int>(
        binding: createBinding(pduBytes: [0x22, 0x01, 0x00]),
        budget: CanIoBudget(),
        cancellation: cancellation,
        action: (lease) async => 42,
      );

      await drainEntered.future;
      isCancelled = true;
      drainRelease.complete();

      final outcome = await outcomeFuture;
      expect(outcome, isA<CanLeaseCancelled<int>>());
      final cancelled = outcome as CanLeaseCancelled<int>;
      expect(cancelled.reason, contains('Cancelled during lease cleanup'));
      expect(cancelled.reason, contains('cleanup failure: Bad state: Simulated hardware drain crash'));
      expect(coordinator.state, equals(CoordinatorState.retiring));
    });

    test('C06 Barrier: action error -> retire during drain -> drain error yields retired outcome', () async {
      final drainEntered = Completer<void>();
      final drainRelease = Completer<void>();

      backend.simulatedDrainCallback = () async {
        drainEntered.complete();
        await drainRelease.future;
        throw StateError('Simulated hardware drain crash');
      };

      final outcomeFuture = coordinator.withReadLease<int>(
        binding: createBinding(pduBytes: [0x22, 0x01, 0x00]),
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          throw StateError('Action transport failure');
        },
      );

      await drainEntered.future;
      unawaited(coordinator.close());
      drainRelease.complete();

      final outcome = await outcomeFuture;
      expect(outcome, isA<CanLeaseRetired<int>>());
      final retired = outcome as CanLeaseRetired<int>;
      expect(retired.reason, contains('Coordinator closed during cleanup'));
      expect(retired.reason, contains('cleanup failure: Bad state: Simulated hardware drain crash'));
      expect(coordinator.state, equals(CoordinatorState.closed));
    });

    test('C06: Cleanup drain failure does not regress closed coordinator back to retiring', () async {
      backend.simulatedDrainError = StateError('Drain failed');
      final binding = createBinding(pduBytes: [0x22, 0x01, 0x00]);

      final outcome = await coordinator.withReadLease<int>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          unawaited(coordinator.close());
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return 123;
        },
      );

      expect(coordinator.state, equals(CoordinatorState.closed));
      expect(outcome, isA<CanLeaseRetired<int>>());
    });
  });
}

class _SynchronousThrowBackend extends FakeCanPduBackend {
  @override
  Future<void> close() {
    throw StateError('Synchronous driver crash during close()');
  }
}

class _ScriptedAdvancingClock extends FakeCanIoClock {
  int _callCount = 0;
  final Duration advanceAfterCalls;
  final int triggerCallIndex;

  _ScriptedAdvancingClock({
    required this.triggerCallIndex,
    required this.advanceAfterCalls,
    DateTime? initial,
  }) : super(initial);

  @override
  DateTime now() {
    _callCount++;
    if (_callCount >= triggerCallIndex) {
      advance(advanceAfterCalls);
    }
    return super.now();
  }
}
