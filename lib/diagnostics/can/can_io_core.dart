import 'dart:async';

import '../diagnostic_link.dart';
import 'can_endpoint.dart';
import 'can_io_clock.dart';
import 'can_io_contract.dart';

/// Low-level interface for physical or virtual CAN PDU transmission and reception.
abstract interface class CanPduBackend {
  /// Submits an approved PDU to the underlying CAN link.
  Future<CanWriteReceipt> writePdu({
    required CanEndpoint endpoint,
    required ApplicationPdu pdu,
    required DiagnosticRequestId attemptId,
    required Duration phaseBudget,
    DiagnosticCancellation? cancellation,
  });

  /// Reads the next observation from the underlying link.
  Future<CanBackendObservation> readObservation({
    required CanEndpoint endpoint,
    required Duration phaseBudget,
    DiagnosticCancellation? cancellation,
  });

  /// Drains any in-flight frames or queues within [timeout].
  Future<void> drain({Duration? timeout});

  /// Closes the backend and releases OS resources.
  Future<void> close();
}

/// Authority coordinating bounded, single-owner CAN I/O execution.
class CanIoCoordinator {
  final CanEndpoint endpoint;
  final CanPduBackend backend;
  final CanIoClock clock;

  CoordinatorState _state = CoordinatorState.ready;
  CoordinatorState get state => _state;

  int _activeLeaseCount = 0;
  int get activeLeaseCount => _activeLeaseCount;

  final List<_QueuedLeaseEntry> _queue = [];
  int get queuedLeaseCount => _queue.length;

  int _coordinatorGeneration = 0;
  int get coordinatorGeneration => _coordinatorGeneration;

  CanIoCoordinator({
    required this.endpoint,
    required this.backend,
    CanIoClock? clock,
  }) : clock = clock ?? CanIoClock.system() {
    endpoint.assertSupportedInS1();
  }

  /// Executes [action] with a bounded, authenticated read lease.
  ///
  /// Serializes operations in strict FIFO order (max active = 1, max queue = 8).
  /// Enforces monotonic deadline evaluation, prioritized termination, and
  /// guaranteed resource cleanup.
  Future<CanLeaseOutcome<T>> withReadLease<T>({
    required CanReadBinding binding,
    required CanIoBudget budget,
    required DiagnosticCancellation cancellation,
    required Future<T> Function(CanReadLease lease) action,
  }) async {
    // 1. Validate coordinator state
    if (_state != CoordinatorState.ready) {
      return CanLeaseOutcome.retired(
        'Coordinator is ${_state.name}. Cannot admit new read leases.',
      );
    }

    // 2. Validate endpoint and generation compatibility
    if (binding.endpoint != endpoint) {
      return const CanLeaseOutcome.rejected(
        'Binding endpoint does not match coordinator endpoint.',
      );
    }
    if (binding.connectionGeneration != endpoint.generation) {
      return CanLeaseOutcome.rejected(
        'Binding generation (${binding.connectionGeneration}) does not match coordinator generation (${endpoint.generation}).',
      );
    }

    // 3. Validate S1 compatibility of endpoint
    try {
      binding.endpoint.assertSupportedInS1();
    } on UnsupportedError catch (e) {
      return CanLeaseOutcome.rejected(e.message ?? 'Unsupported endpoint configuration.');
    }

    // 4. Calculate total deadline
    final totalDeadline = clock.now().add(budget.totalTimeout);
    final effectiveTotalDeadline =
        CanIoClock.minDeadline(totalDeadline, binding.outerDeadline);

    final effectiveCancellation = DiagnosticCancellation(
      () => cancellation.isCancelled || binding.requestCancellation.isCancelled,
    );

    // 5. Pre-admission checks: priority cancellation > timeout
    if (effectiveCancellation.isCancelled) {
      return const CanLeaseOutcome.cancelled('Pre-cancelled prior to admission.');
    }
    if (clock.isExpired(effectiveTotalDeadline)) {
      return const CanLeaseOutcome.timedOut('Deadline expired prior to admission.');
    }

    // 6. Queue admission or wait
    final leaseId = DiagnosticRequestId('lease_${DateTime.now().microsecondsSinceEpoch}');
    final queueCompleter = Completer<bool>();
    final entry = _QueuedLeaseEntry(
      leaseId: leaseId,
      completer: queueCompleter,
      cancellation: effectiveCancellation,
      effectiveDeadline: effectiveTotalDeadline,
    );

    if (_activeLeaseCount >= CanIoBudget.maxActiveLeases || _queue.isNotEmpty) {
      if (_queue.length >= CanIoBudget.maxQueuedLeases) {
        return const CanLeaseOutcome.rejected(
          'Queue capacity exceeded (max 8 queued).',
        );
      }
      _queue.add(entry);

      // Await queue turn while respecting cancellation, timeout, and coordinator retirement
      final admitted = await _awaitQueueTurn(entry, effectiveTotalDeadline);
      if (!admitted) {
        _queue.remove(entry);
        if (effectiveCancellation.isCancelled) {
          return const CanLeaseOutcome.cancelled('Cancelled while queued.');
        }
        if (_state != CoordinatorState.ready) {
          return CanLeaseOutcome.retired('Coordinator ${_state.name} while queued.');
        }
        return const CanLeaseOutcome.timedOut('Timed out while waiting in queue.');
      }
    }

    // 7. Transition to active lease
    _activeLeaseCount = 1;
    final admissionGeneration = _coordinatorGeneration;
    _ActiveCanReadLease? activeLease;
    CanLeaseOutcome<T>? outcome;
    var cleanupSucceeded = true;
    Object? cleanupError;

    try {
      // Re-verify priority upon admission
      if (effectiveCancellation.isCancelled) {
        outcome = const CanLeaseOutcome.cancelled('Cancelled upon admission.');
      } else if (_state != CoordinatorState.ready ||
          _coordinatorGeneration != admissionGeneration) {
        outcome = CanLeaseOutcome.retired('Coordinator ${_state.name} upon admission.');
      } else if (clock.isExpired(effectiveTotalDeadline)) {
        outcome = const CanLeaseOutcome.timedOut('Deadline expired upon admission.');
      } else {
        activeLease = _ActiveCanReadLease(
          binding: binding,
          budget: budget,
          cancellation: effectiveCancellation,
          effectiveTotalDeadline: effectiveTotalDeadline,
          backend: backend,
          clock: clock,
          endpoint: endpoint,
          isCoordinatorActive: () =>
              _state == CoordinatorState.ready &&
              _coordinatorGeneration == admissionGeneration,
        );

        final remainingUntilDeadline = clock.remaining(effectiveTotalDeadline);
        if (remainingUntilDeadline != null && remainingUntilDeadline <= Duration.zero) {
          throw TimeoutException(
            'Total lease deadline expired before action execution.',
            budget.totalTimeout,
          );
        }
        final actionTimeout = remainingUntilDeadline ?? budget.totalTimeout;

        final result = await action(activeLease).timeout(actionTimeout);

        // Success revalidation: verify terminal state after action completes
        if (effectiveCancellation.isCancelled) {
          outcome = const CanLeaseOutcome.cancelled(
            'Cancelled during lease execution.',
          );
        } else if (_state != CoordinatorState.ready ||
            _coordinatorGeneration != admissionGeneration) {
          outcome = CanLeaseOutcome.retired(
            'Coordinator ${_state.name} upon lease completion.',
          );
        } else if (clock.isExpired(effectiveTotalDeadline)) {
          outcome = const CanLeaseOutcome.timedOut(
            'Total lease deadline expired during action execution.',
          );
        } else {
          outcome = CanLeaseOutcome.success(result);
        }
      }
    } catch (error, stackTrace) {
      // Strict priority handling: cancellation > retirement > timeout > failure
      if (effectiveCancellation.isCancelled) {
        outcome = CanLeaseOutcome.cancelled('Cancelled during execution: $error');
      } else if (_state != CoordinatorState.ready ||
          _coordinatorGeneration != admissionGeneration) {
        outcome = CanLeaseOutcome.retired('Coordinator ${_state.name}: $error');
      } else if (clock.isExpired(effectiveTotalDeadline) || error is TimeoutException) {
        outcome = CanLeaseOutcome.timedOut('Timed out during execution: $error');
      } else {
        outcome = CanLeaseOutcome.transportFailure(error, stackTrace);
      }
    } finally {
      // 8. Revoke lease authorization FIRST before cleanup
      activeLease?.markTerminating();
      try {
        await backend.drain(timeout: budget.cleanupBudget).timeout(
          budget.cleanupBudget,
        );
        cleanupSucceeded = true;
      } catch (e) {
        cleanupSucceeded = false;
        cleanupError = e;
      }

      if (!cleanupSucceeded) {
        if (_state != CoordinatorState.closed) {
          _state = CoordinatorState.retiring;
        }
        while (_queue.isNotEmpty) {
          final queued = _queue.removeAt(0);
          if (!queued.completer.isCompleted) {
            queued.completer.complete(false);
          }
        }
      }

      // Re-evaluate cancellation, retirement, and deadline after cleanup
      // regardless of whether drain succeeded or failed.
      // Priority: cancellation > retirement > deadline > cleanup failure > prior outcome
      final cleanupSuffix = cleanupSucceeded ? '' : ' (cleanup failure: $cleanupError)';
      if (effectiveCancellation.isCancelled) {
        outcome = CanLeaseOutcome<T>.cancelled(
          'Cancelled during lease cleanup$cleanupSuffix.',
        );
      } else if (_state != CoordinatorState.ready ||
          _coordinatorGeneration != admissionGeneration) {
        outcome = CanLeaseOutcome<T>.retired(
          'Coordinator ${_state.name} during cleanup$cleanupSuffix.',
        );
      } else if (clock.isExpired(effectiveTotalDeadline)) {
        if (outcome is! CanLeaseTimedOut<T>) {
          outcome = CanLeaseOutcome<T>.timedOut(
            'Total lease deadline expired during cleanup$cleanupSuffix.',
          );
        }
      } else if (!cleanupSucceeded) {
        outcome = CanLeaseOutcome<T>.retired(
          'Coordinator retired due to cleanup failure: $cleanupError',
        );
      }

      if (cleanupSucceeded) {
        activeLease?.markReleased();
        _promoteNextQueued();
      }
      _activeLeaseCount = 0;
    }
    return outcome ?? CanLeaseOutcome<T>.retired('Terminated without outcome.');
  }

  Future<bool> _awaitQueueTurn(
    _QueuedLeaseEntry entry,
    DateTime? effectiveDeadline,
  ) async {
    Timer? pollTimer;
    final completer = Completer<bool>();

    void check() {
      if (completer.isCompleted) return;
      if (entry.cancellation.isCancelled ||
          _state != CoordinatorState.ready ||
          clock.isExpired(effectiveDeadline)) {
        pollTimer?.cancel();
        if (!completer.isCompleted) completer.complete(false);
      }
    }

    pollTimer = Timer.periodic(const Duration(milliseconds: 10), (_) => check());

    unawaited(entry.completer.future.then((admitted) {
      pollTimer?.cancel();
      if (!completer.isCompleted) completer.complete(admitted);
    }));

    final result = await completer.future;
    pollTimer.cancel();
    return result;
  }

  void _promoteNextQueued() {
    while (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      if (next.cancellation.isCancelled ||
          clock.isExpired(next.effectiveDeadline) ||
          _state != CoordinatorState.ready) {
        if (!next.completer.isCompleted) {
          next.completer.complete(false);
        }
        continue;
      }
      if (!next.completer.isCompleted) {
        next.completer.complete(true);
      }
      break;
    }
  }

  Completer<void>? _closeCompleter;

  /// Closes the coordinator authority, terminating active and queued leases.
  Future<void> close({Duration timeout = const Duration(milliseconds: 250)}) {
    if (_state == CoordinatorState.closed) {
      return Future.value();
    }
    if (_closeCompleter != null) {
      return _closeCompleter!.future;
    }
    final completer = Completer<void>();
    _closeCompleter = completer;
    _state = CoordinatorState.retiring;
    _coordinatorGeneration++;

    // Evict all queued entries
    while (_queue.isNotEmpty) {
      final entry = _queue.removeAt(0);
      if (!entry.completer.isCompleted) {
        entry.completer.complete(false);
      }
    }

    Future<void>.sync(() => backend.close()).timeout(timeout).then((_) {
      _state = CoordinatorState.closed;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }, onError: (Object e, StackTrace st) {
      _state = CoordinatorState.closed;
      if (!completer.isCompleted) {
        completer.completeError(e, st);
      }
    });

    return completer.future;
  }
}

class _QueuedLeaseEntry {
  final DiagnosticRequestId leaseId;
  final Completer<bool> completer;
  final DiagnosticCancellation cancellation;
  final DateTime? effectiveDeadline;

  _QueuedLeaseEntry({
    required this.leaseId,
    required this.completer,
    required this.cancellation,
    required this.effectiveDeadline,
  });
}

class _ActiveCanReadLease implements CanReadLease {
  final CanReadBinding binding;
  final CanIoBudget budget;
  final DiagnosticCancellation cancellation;
  final DateTime? effectiveTotalDeadline;
  final CanPduBackend backend;
  final CanIoClock clock;
  final CanEndpoint endpoint;
  final bool Function() isCoordinatorActive;
  final Set<DiagnosticRequestId> _usedAttemptIds = {};

  LeaseState _state = LeaseState.active;
  @override
  LeaseState get state => _state;

  int _sendAttemptsCount = 0;
  @override
  int get sendAttemptsCount => _sendAttemptsCount;

  DiagnosticRequestId _currentAttemptId;
  @override
  DiagnosticRequestId get currentAttemptId => _currentAttemptId;

  int _inFlightReads = 0;
  int _bufferedObservationsCount = 0;
  int _aggregateBufferedBytes = 0;

  _ActiveCanReadLease({
    required this.binding,
    required this.budget,
    required this.cancellation,
    required this.effectiveTotalDeadline,
    required this.backend,
    required this.clock,
    required this.endpoint,
    required this.isCoordinatorActive,
  }) : _currentAttemptId = binding.requestIdentifier;

  void markTerminating() {
    _state = LeaseState.terminating;
  }

  void markReleased() {
    _state = LeaseState.released;
  }

  void _assertActive() {
    if (_state != LeaseState.active) {
      throw StateError('Lease is not active (state: ${_state.name}).');
    }
    if (!isCoordinatorActive()) {
      throw StateError('Coordinator is no longer active.');
    }
    if (cancellation.isCancelled || binding.requestCancellation.isCancelled) {
      throw StateError('Lease operation cancelled.');
    }
    if (clock.isExpired(effectiveTotalDeadline)) {
      throw TimeoutException('Total lease deadline expired.');
    }
  }

  @override
  Future<CanWriteReceipt> sendApproved(DiagnosticRequestId attemptId) async {
    _assertActive();

    if (_usedAttemptIds.contains(attemptId)) {
      throw ArgumentError(
        'Attempt ID $attemptId has already been used in this lease.',
      );
    }

    if (_sendAttemptsCount >= budget.maxExplicitAttempts) {
      throw StateError(
        'Send ceiling exceeded: attempt ${_sendAttemptsCount + 1} exceeds max ${budget.maxExplicitAttempts}.',
      );
    }
    _usedAttemptIds.add(attemptId);

    // Synchronously reserve send attempt count before await
    _sendAttemptsCount++;
    _currentAttemptId = attemptId;

    final phaseDeadline = clock.now().add(budget.phaseBudget);
    final effectivePhaseDeadline =
        CanIoClock.minDeadline(phaseDeadline, effectiveTotalDeadline);
    final effectivePhaseRemaining =
        clock.remaining(effectivePhaseDeadline) ?? budget.phaseBudget;

    if (effectivePhaseRemaining <= Duration.zero) {
      throw TimeoutException('Effective deadline expired prior to send.');
    }

    final receipt = await backend.writePdu(
      endpoint: endpoint,
      pdu: binding.canonicalPdu,
      attemptId: attemptId,
      phaseBudget: effectivePhaseRemaining,
      cancellation: cancellation,
    ).timeout(effectivePhaseRemaining);

    if (clock.isExpired(effectivePhaseDeadline)) {
      throw TimeoutException('Phase deadline expired during send operation.');
    }

    _assertActive();

    // Validate receipt identity & consistency (C05)
    if (receipt.attemptId != attemptId) {
      throw StateError(
        'Receipt attempt ID (${receipt.attemptId}) does not match expected attempt ID ($attemptId).',
      );
    }
    if (receipt.disposition == CanSendDisposition.submitted &&
        receipt.bytesWritten != binding.canonicalPdu.length) {
      throw StateError(
        'Submitted receipt byte count (${receipt.bytesWritten}) does not match PDU length (${binding.canonicalPdu.length}).',
      );
    }
    if (receipt.disposition == CanSendDisposition.provenNotSubmitted &&
        receipt.bytesWritten != 0) {
      throw StateError(
        'Proven-not-submitted receipt byte count must be 0, got ${receipt.bytesWritten}.',
      );
    }
    if (receipt.bytesWritten < 0 || receipt.bytesWritten > binding.canonicalPdu.length) {
      throw StateError(
        'Receipt bytes written (${receipt.bytesWritten}) is out of bounds [0, ${binding.canonicalPdu.length}].',
      );
    }

    return receipt;
  }

  @override
  Future<CanBackendObservation> receiveNext(Duration phaseBudget) async {
    _assertActive();

    // Check observation buffering boundaries before await
    if (_bufferedObservationsCount + _inFlightReads >=
        CanIoBudget.maxBufferedObservations) {
      throw StateError(
        'Buffered observations ceiling exceeded (max ${CanIoBudget.maxBufferedObservations}).',
      );
    }
    _inFlightReads++;

    final phaseDeadline = clock.now().add(phaseBudget);
    final effectiveDeadline = CanIoClock.minDeadline(
      phaseDeadline,
      CanIoClock.minDeadline(effectiveTotalDeadline, binding.outerDeadline),
    );
    final effectiveRemaining = clock.remaining(effectiveDeadline) ?? Duration.zero;

    if (effectiveRemaining <= Duration.zero) {
      _inFlightReads--;
      throw TimeoutException('Effective deadline expired prior to receive.');
    }

    try {
      final observation = await backend.readObservation(
        endpoint: endpoint,
        phaseBudget: effectiveRemaining,
        cancellation: cancellation,
      ).timeout(effectiveRemaining);

      if (clock.isExpired(effectiveDeadline)) {
        throw TimeoutException('Phase deadline expired during receive operation.');
      }

      _assertActive();

      // Validate buffer limits
      if (_aggregateBufferedBytes + observation.payload.length >
          CanIoBudget.maxAggregateBufferedBytes) {
        throw StateError(
          'Aggregate buffered bytes ceiling exceeded (max ${CanIoBudget.maxAggregateBufferedBytes} bytes).',
        );
      }

      // Validate source attribution matches expected responder
      if (observation.sourceId != endpoint.physicalRxId) {
        throw StateError(
          'Observation source ${observation.sourceId} does not match expected responder ${endpoint.physicalRxId}.',
        );
      }

      _bufferedObservationsCount++;
      _aggregateBufferedBytes += observation.payload.length;

      return observation;
    } finally {
      _inFlightReads--;
    }
  }
}
