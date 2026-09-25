import 'dart:async';

import '../diagnostic_link.dart';
import 'can_endpoint.dart';
import 'can_io_clock.dart';

/// Bounded limits and budgets for CAN I/O execution.
class CanIoBudget {
  /// Maximum number of active leases per coordinator authority (strictly 1).
  static const int maxActiveLeases = 1;

  /// Maximum number of waiting leases in the FIFO queue (strictly 8, excluding active).
  static const int maxQueuedLeases = 8;

  /// Minimum permitted application PDU length in bytes.
  static const int minPduBytes = 1;

  /// Maximum permitted application PDU length in bytes (4095).
  static const int maxPduBytes = 4095;

  /// Maximum number of buffered incoming observations per lease (32).
  static const int maxBufferedObservations = 32;

  /// Maximum cumulative bytes across all buffered observations for a lease (4096).
  static const int maxAggregateBufferedBytes = 4096;

  /// Total monotonic timeout for the entire lease (including queuing and execution).
  final Duration totalTimeout;

  /// Maximum duration permitted for an individual phase (e.g. single send or receive).
  final Duration phaseBudget;

  /// Dedicated cleanup duration when cancelling, timing out, or releasing resources.
  ///
  /// This budget does NOT extend send authorization.
  final Duration cleanupBudget;

  /// Maximum explicit send attempts permitted for this lease (1..4).
  final int maxExplicitAttempts;

  CanIoBudget({
    this.totalTimeout = const Duration(seconds: 2),
    this.phaseBudget = const Duration(seconds: 1),
    this.cleanupBudget = const Duration(milliseconds: 250),
    this.maxExplicitAttempts = 1,
  }) {
    if (totalTimeout <= Duration.zero) {
      throw ArgumentError.value(
        totalTimeout,
        'totalTimeout',
        'Total timeout must be positive.',
      );
    }
    if (phaseBudget <= Duration.zero) {
      throw ArgumentError.value(
        phaseBudget,
        'phaseBudget',
        'Phase budget must be positive.',
      );
    }
    if (cleanupBudget <= Duration.zero) {
      throw ArgumentError.value(
        cleanupBudget,
        'cleanupBudget',
        'Cleanup budget must be positive.',
      );
    }
    if (maxExplicitAttempts < 1 || maxExplicitAttempts > 4) {
      throw ArgumentError.value(
        maxExplicitAttempts,
        'maxExplicitAttempts',
        'Explicit send attempts ceiling must be between 1 and 4.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanIoBudget &&
          runtimeType == other.runtimeType &&
          totalTimeout == other.totalTimeout &&
          phaseBudget == other.phaseBudget &&
          cleanupBudget == other.cleanupBudget &&
          maxExplicitAttempts == other.maxExplicitAttempts;

  @override
  int get hashCode => Object.hash(
        totalTimeout,
        phaseBudget,
        cleanupBudget,
        maxExplicitAttempts,
      );

  @override
  String toString() =>
      'CanIoBudget(total: $totalTimeout, phase: $phaseBudget, cleanup: $cleanupBudget, maxAttempts: $maxExplicitAttempts)';
}

/// Truthful status of an explicit send submission to the CAN backend.
enum CanSendDisposition {
  /// Confirmed not submitted to wire/backend (e.g. pre-check rejected, cancelled).
  provenNotSubmitted,

  /// Full PDU frame(s) successfully accepted and submitted by backend.
  submitted,

  /// Transmission was interrupted, partially accepted, or backend outcome unknown.
  ///
  /// Neither `submitted` nor `partialOrUnknown` may be automatically replayed.
  partialOrUnknown,
}

/// Immutable receipt returned following an approved send operation.
class CanWriteReceipt {
  final DiagnosticRequestId attemptId;
  final DateTime timestamp;
  final CanSendDisposition disposition;
  final int bytesWritten;

  const CanWriteReceipt({
    required this.attemptId,
    required this.timestamp,
    required this.disposition,
    required this.bytesWritten,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanWriteReceipt &&
          runtimeType == other.runtimeType &&
          attemptId == other.attemptId &&
          timestamp == other.timestamp &&
          disposition == other.disposition &&
          bytesWritten == other.bytesWritten;

  @override
  int get hashCode => Object.hash(attemptId, timestamp, disposition, bytesWritten);

  @override
  String toString() =>
      'CanWriteReceipt(attempt: $attemptId, disp: $disposition, bytes: $bytesWritten)';
}

/// Raw payload and metadata of a message received from the CAN backend.
class CanBackendObservation {
  final List<int> payload;
  final DiagnosticCanIdentifier sourceId;
  final DateTime timestamp;
  final int sequenceNumber;

  CanBackendObservation({
    required List<int> payload,
    required this.sourceId,
    required this.timestamp,
    required this.sequenceNumber,
  }) : payload = List.unmodifiable(_validatePayload(payload)) {
    if (sequenceNumber < 0) {
      throw ArgumentError.value(
        sequenceNumber,
        'sequenceNumber',
        'Sequence number cannot be negative.',
      );
    }
  }

  static List<int> _validatePayload(List<int> bytes) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(
        bytes,
        'payload',
        'Backend observation payload cannot be empty.',
      );
    }
    if (bytes.length > CanIoBudget.maxPduBytes) {
      throw ArgumentError.value(
        bytes.length,
        'payload',
        'Backend observation exceeds maximum permitted size of ${CanIoBudget.maxPduBytes} bytes.',
      );
    }
    for (final b in bytes) {
      if (b < 0 || b > 255) {
        throw ArgumentError.value(
          b,
          'payload',
          'Payload byte must be between 0 and 255.',
        );
      }
    }
    return bytes;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanBackendObservation &&
          runtimeType == other.runtimeType &&
          sourceId == other.sourceId &&
          sequenceNumber == other.sequenceNumber &&
          _listEquals(payload, other.payload);

  @override
  int get hashCode => Object.hash(
        sourceId,
        sequenceNumber,
        Object.hashAll(payload),
      );

  @override
  String toString() =>
      'CanBackendObservation(src: $sourceId, seq: $sequenceNumber, len: ${payload.length})';
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Lifecycle state of the coordinator authority.
enum CoordinatorState {
  ready,
  retiring,
  closed,
}

/// Lifecycle state of an individual lease.
enum LeaseState {
  queued,
  admitted,
  active,
  terminating,
  released,
}

/// Terminal outcome of an executed CAN read lease.
sealed class CanLeaseOutcome<T> {
  const CanLeaseOutcome();

  bool get isSuccess => this is CanLeaseSuccess<T>;
  T? get valueOrNull =>
      this is CanLeaseSuccess<T> ? (this as CanLeaseSuccess<T>).value : null;

  const factory CanLeaseOutcome.success(T value) = CanLeaseSuccess<T>;
  const factory CanLeaseOutcome.rejected(String reason) = CanLeaseRejected<T>;
  const factory CanLeaseOutcome.cancelled(String reason) = CanLeaseCancelled<T>;
  const factory CanLeaseOutcome.retired(String reason) = CanLeaseRetired<T>;
  const factory CanLeaseOutcome.timedOut(String reason) = CanLeaseTimedOut<T>;
  const factory CanLeaseOutcome.transportFailure(
    Object error, [
    StackTrace? stackTrace,
  ]) = CanLeaseTransportFailure<T>;
}

class CanLeaseSuccess<T> extends CanLeaseOutcome<T> {
  final T value;
  const CanLeaseSuccess(this.value);

  @override
  String toString() => 'CanLeaseOutcome.success($value)';
}

class CanLeaseRejected<T> extends CanLeaseOutcome<T> {
  final String reason;
  const CanLeaseRejected(this.reason);

  @override
  String toString() => 'CanLeaseOutcome.rejected($reason)';
}

class CanLeaseCancelled<T> extends CanLeaseOutcome<T> {
  final String reason;
  const CanLeaseCancelled(this.reason);

  @override
  String toString() => 'CanLeaseOutcome.cancelled($reason)';
}

class CanLeaseRetired<T> extends CanLeaseOutcome<T> {
  final String reason;
  const CanLeaseRetired(this.reason);

  @override
  String toString() => 'CanLeaseOutcome.retired($reason)';
}

class CanLeaseTimedOut<T> extends CanLeaseOutcome<T> {
  final String reason;
  const CanLeaseTimedOut(this.reason);

  @override
  String toString() => 'CanLeaseOutcome.timedOut($reason)';
}

class CanLeaseTransportFailure<T> extends CanLeaseOutcome<T> {
  final Object error;
  final StackTrace? stackTrace;
  const CanLeaseTransportFailure(this.error, [this.stackTrace]);

  @override
  String toString() => 'CanLeaseOutcome.transportFailure($error)';
}

/// Scoped handle provided to the lease action during execution.
abstract interface class CanReadLease {
  /// Current state of this lease.
  LeaseState get state;

  /// Current attempt request ID.
  DiagnosticRequestId get currentAttemptId;

  /// Number of explicit send attempts performed so far.
  int get sendAttemptsCount;

  /// Sends the approved captured read PDU.
  ///
  /// Does NOT take a payload parameter: strictly sends the captured canonical read.
  Future<CanWriteReceipt> sendApproved(DiagnosticRequestId attemptId);

  /// Receives the next backend observation within [phaseBudget].
  ///
  /// Does NOT submit any new application request.
  Future<CanBackendObservation> receiveNext(Duration phaseBudget);
}

/// Sealed, authenticated read binding tying an approved UDS read request
/// to a CAN endpoint and wire authority context.
class CanReadBinding {
  final ApplicationPdu canonicalPdu;
  final CanEndpoint endpoint;
  final DiagnosticRequestId requestIdentifier;
  final Object wireOwnerToken;
  final int connectionGeneration;
  final PhysicalCanDiagnosticTarget target;
  final DateTime? outerDeadline;
  final DiagnosticCancellation requestCancellation;

  const CanReadBinding._({
    required this.canonicalPdu,
    required this.endpoint,
    required this.requestIdentifier,
    required this.wireOwnerToken,
    required this.connectionGeneration,
    required this.target,
    this.outerDeadline,
    this.requestCancellation = DiagnosticCancellation.none,
  });

  /// Captures an approved canonical read binding from an existing [DiagnosticRequest].
  ///
  /// Strictly admits only canonical read services:
  /// - `0x22` ReadDataByIdentifier (strictly 3 bytes: `22 [DID_HI] [DID_LO]`)
  /// - `0x19 0x02` ReportDTCByStatusMask (strictly 3 bytes: `19 02 [MASK]`)
  /// - `0x19 0x0A` ReportSupportedDTC (strictly 2 bytes: `19 0A`)
  ///
  /// Rejects multi-DID, trailing bytes, short/long PDUs, and non-read SIDs before
  /// any wire transmission can occur.
  factory CanReadBinding.fromUdsRequest({
    required DiagnosticRequest request,
    required CanEndpoint endpoint,
    required Object wireOwnerToken,
    DateTime? outerDeadline,
  }) {
    if (request.target is! PhysicalCanDiagnosticTarget) {
      throw ArgumentError.value(
        request.target,
        'target',
        'CanReadBinding requires a PhysicalCanDiagnosticTarget, got ${request.target.runtimeType}.',
      );
    }
    final target = request.target as PhysicalCanDiagnosticTarget;

    // Validate endpoint identifier width matches request target
    if (endpoint.physicalTxId != target.requestIdentifier ||
        endpoint.physicalRxId != target.expectedResponderIdentifier) {
      throw ArgumentError(
        'Endpoint IDs (${endpoint.physicalTxId} -> ${endpoint.physicalRxId}) '
        'do not match target IDs (${target.requestIdentifier} -> ${target.expectedResponderIdentifier}).',
      );
    }

    if (endpoint.generation != request.connectionGeneration) {
      throw ArgumentError(
        'Endpoint generation (${endpoint.generation}) does not match request generation (${request.connectionGeneration}).',
      );
    }

    // Validate wire owner token matches request ownership token when defined
    if (request.ownership.token != null &&
        !identical(wireOwnerToken, request.ownership.token) &&
        wireOwnerToken != request.ownership.token) {
      throw ArgumentError(
        'Wire owner token ($wireOwnerToken) does not match request ownership token (${request.ownership.token}).',
      );
    }

    _validateCanonicalReadPdu(request.pdu);

    // Fail-closed deadline resolution: outer deadline cannot extend request deadline
    final effectiveOuter =
        CanIoClock.minDeadline(request.deadline, outerDeadline);

    return CanReadBinding._(
      canonicalPdu: request.pdu,
      endpoint: endpoint,
      requestIdentifier: request.id,
      wireOwnerToken: wireOwnerToken,
      connectionGeneration: request.connectionGeneration,
      target: target,
      outerDeadline: effectiveOuter,
      requestCancellation: request.cancellation,
    );
  }

  static void _validateCanonicalReadPdu(ApplicationPdu pdu) {
    if (pdu.length < 2) {
      throw ArgumentError.value(
        pdu.length,
        'pdu',
        'PDU is too short to be a valid UDS read request.',
      );
    }

    final sid = pdu[0];
    if (sid == 0x22) {
      // 0x22 ReadDataByIdentifier must be exactly 3 bytes (1 SID + 2 DID)
      if (pdu.length != 3) {
        throw ArgumentError.value(
          pdu.length,
          'pdu',
          'ReadDataByIdentifier (0x22) requires exactly 3 bytes (single DID). Multi-DID or trailing bytes prohibited.',
        );
      }
    } else if (sid == 0x19) {
      final subfunction = pdu[1];
      if (subfunction == 0x02) {
        // ReportDTCByStatusMask: 19 02 [statusMask]
        if (pdu.length != 3) {
          throw ArgumentError.value(
            pdu.length,
            'pdu',
            'ReportDTCByStatusMask (0x19 0x02) requires exactly 3 bytes.',
          );
        }
      } else if (subfunction == 0x0A) {
        // ReportSupportedDTC: 19 0A
        if (pdu.length != 2) {
          throw ArgumentError.value(
            pdu.length,
            'pdu',
            'ReportSupportedDTC (0x19 0x0A) requires exactly 2 bytes.',
          );
        }
      } else {
        throw ArgumentError.value(
          subfunction,
          'subfunction',
          'Unsupported 0x19 subfunction: 0x${subfunction.toRadixString(16).padLeft(2, '0').toUpperCase()}.',
        );
      }
    } else {
      throw ArgumentError.value(
        sid,
        'sid',
        'Unsupported service ID for CAN read binding: 0x${sid.toRadixString(16).padLeft(2, '0').toUpperCase()}. Only 0x22 and 0x19 are approved.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanReadBinding &&
          runtimeType == other.runtimeType &&
          canonicalPdu == other.canonicalPdu &&
          endpoint == other.endpoint &&
          requestIdentifier == other.requestIdentifier &&
          identical(wireOwnerToken, other.wireOwnerToken) &&
          connectionGeneration == other.connectionGeneration &&
          target == other.target &&
          outerDeadline == other.outerDeadline &&
          requestCancellation == other.requestCancellation;

  @override
  int get hashCode => Object.hash(
        canonicalPdu,
        endpoint,
        requestIdentifier,
        identityHashCode(wireOwnerToken),
        connectionGeneration,
        target,
        outerDeadline,
        requestCancellation,
      );

  @override
  String toString() =>
      'CanReadBinding(pdu: $canonicalPdu, ep: ${endpoint.interfaceName}, req: $requestIdentifier, gen: $connectionGeneration)';
}
