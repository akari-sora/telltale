/// Types and contracts for UDS transaction execution, clock abstractions, and outcomes.
///
/// Ref: Issue #13 ([WS-09][P1]), ISO 14229-1:2020.
///
/// SAFETY CONTRACT:
/// - Public request surface is sealed to Service 0x22 and bounded Service 0x19 (0x02, 0x0A).
/// - Transaction channels exchange strictly complete ApplicationPdu frames; no ISO-TP PCI parsing.
/// - Clock seam permits deterministic monotonic time injection in tests.
/// - Terminal outcomes are strongly typed, immutable, and fail-closed.
library;

import '../diagnostic_link.dart';
import 'uds_dtc_types.dart';
import 'uds_nrc.dart';
import 'uds_read_types.dart';

// -----------------------------------------------------------------------------
// Clock Seam
// -----------------------------------------------------------------------------

/// Monotonic clock and delay interface for UDS transactions.
abstract interface class UdsClock {
  /// Wall-clock timestamp for logging/metadata only.
  DateTime get now;

  /// Monotonic elapsed duration since clock creation or baseline.
  Duration get elapsed;

  /// Asynchronously advances or delays execution by [duration].
  Future<void> delay(Duration duration);
}

/// Production clock backed by system [Stopwatch] and [Future.delayed].
final class SystemUdsClock implements UdsClock {
  SystemUdsClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  DateTime get now => DateTime.now();

  @override
  Duration get elapsed => _stopwatch.elapsed;

  @override
  Future<void> delay(Duration duration) => Future<void>.delayed(duration);
}

/// Deterministic monotonic clock for unit and vector testing.
final class FakeUdsClock implements UdsClock {
  FakeUdsClock({DateTime? initialTime})
      : _now = initialTime ?? DateTime.utc(2026, 9, 25, 12, 0, 0);

  DateTime _now;
  Duration _elapsed = Duration.zero;
  final List<Duration> recordedDelays = [];
  bool autoAdvanceDelay = true;

  @override
  DateTime get now => _now;

  @override
  Duration get elapsed => _elapsed;

  /// Manually advances the clock by [duration].
  void advance(Duration duration) {
    if (duration <= Duration.zero) return;
    _now = _now.add(duration);
    _elapsed += duration;
  }

  @override
  Future<void> delay(Duration duration) async {
    recordedDelays.add(duration);
    if (autoAdvanceDelay && duration > Duration.zero) {
      advance(duration);
    }
  }
}

// -----------------------------------------------------------------------------
// Sealed Request Hierarchy
// -----------------------------------------------------------------------------

/// Sealed base class for UDS requests admitted into the transaction engine.
///
/// SAFETY CONTRACT:
/// Only Service 0x22 (ReadDataByIdentifier) and Service 0x19 (ReadDTCInformation)
/// subfunctions 0x02 and 0x0A can be constructed. Generic SID, routine control,
/// write-DID, security access, or programming requests are structurally prohibited.
sealed class UdsTransactionRequest {
  const UdsTransactionRequest();

  /// Target ISO 14229-1 Service ID (0x22 or 0x19).
  int get serviceId;

  /// Encodes the complete application request payload.
  List<int> encode();

  /// Converts the encoded request to an immutable [ApplicationPdu].
  ApplicationPdu toPdu() => ApplicationPdu(encode());

  /// Request builder for Service 0x22 ReadDataByIdentifier.
  factory UdsTransactionRequest.readDid(UdsDid did) =>
      UdsReadDataByIdentifierTransactionRequest(
        UdsReadDataByIdentifierRequest(did),
      );

  /// Request builder for Service 0x19 0x02 reportDTCByStatusMask.
  factory UdsTransactionRequest.reportDtcByStatusMask(UdsDtcStatusMask mask) =>
      UdsReportDtcByStatusMaskTransactionRequest(
        UdsReportDtcByStatusMaskRequest(mask),
      );

  /// Request builder for Service 0x19 0x0A reportSupportedDTC.
  factory UdsTransactionRequest.reportSupportedDtc() =>
      const UdsReportSupportedDtcTransactionRequest(
        UdsReportSupportedDtcRequest(),
      );

  /// Wraps an existing [UdsReadDataByIdentifierRequest].
  factory UdsTransactionRequest.fromReadDid(
    UdsReadDataByIdentifierRequest request,
  ) =>
      UdsReadDataByIdentifierTransactionRequest(request);

  /// Wraps an existing sealed [UdsReadDtcRequest].
  factory UdsTransactionRequest.fromReadDtc(UdsReadDtcRequest request) {
    return switch (request) {
      final UdsReportDtcByStatusMaskRequest r =>
        UdsReportDtcByStatusMaskTransactionRequest(r),
      final UdsReportSupportedDtcRequest r =>
        UdsReportSupportedDtcTransactionRequest(r),
    };
  }
}

/// Transaction request wrapper for Service 0x22.
final class UdsReadDataByIdentifierTransactionRequest
    extends UdsTransactionRequest {
  const UdsReadDataByIdentifierTransactionRequest(this.request);

  final UdsReadDataByIdentifierRequest request;

  UdsDid get did => request.did;

  @override
  int get serviceId => 0x22;

  @override
  List<int> encode() => request.encode();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UdsReadDataByIdentifierTransactionRequest &&
          other.request == request);

  @override
  int get hashCode => request.hashCode;

  @override
  String toString() => 'UdsTransactionRequest.readDid(${did.toHex()})';
}

/// Transaction request wrapper for Service 0x19 0x02.
final class UdsReportDtcByStatusMaskTransactionRequest
    extends UdsTransactionRequest {
  const UdsReportDtcByStatusMaskTransactionRequest(this.request);

  final UdsReportDtcByStatusMaskRequest request;

  UdsDtcStatusMask get mask => request.mask;

  @override
  int get serviceId => 0x19;

  int get subFunction => 0x02;

  @override
  List<int> encode() => request.encode();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UdsReportDtcByStatusMaskTransactionRequest &&
          other.request == request);

  @override
  int get hashCode => request.hashCode;

  @override
  String toString() =>
      'UdsTransactionRequest.reportDtcByStatusMask(${mask.toHex()})';
}

/// Transaction request wrapper for Service 0x19 0x0A.
final class UdsReportSupportedDtcTransactionRequest
    extends UdsTransactionRequest {
  const UdsReportSupportedDtcTransactionRequest(this.request);

  final UdsReportSupportedDtcRequest request;

  @override
  int get serviceId => 0x19;

  int get subFunction => 0x0A;

  @override
  List<int> encode() => request.encode();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UdsReportSupportedDtcTransactionRequest &&
          other.request == request);

  @override
  int get hashCode => request.hashCode;

  @override
  String toString() => 'UdsTransactionRequest.reportSupportedDtc()';
}

// -----------------------------------------------------------------------------
// Transport Channel Contract
// -----------------------------------------------------------------------------

/// Abstract exchange channel used by the transaction engine.
///
/// Isolates the transaction state machine from underlying link transport.
abstract interface class UdsTransactionChannel {
  /// Transmits [pdu] with identifier [id] and awaits the response within [timeout].
  Future<DiagnosticMessage> send(
    DiagnosticRequestId id,
    ApplicationPdu pdu,
    Duration timeout,
  );

  /// Awaits a continuation response without sending any wire data, within [timeout].
  ///
  /// Used exclusively during NRC 0x78 (responsePending) continuation phases.
  Future<DiagnosticMessage> receiveContinuation(
    Duration timeout,
  );
}

/// Channel adapter constructed from individual callback closures.
final class CallbackUdsTransactionChannel implements UdsTransactionChannel {
  const CallbackUdsTransactionChannel({
    required this.onSend,
    required this.onReceiveContinuation,
  });

  final Future<DiagnosticMessage> Function(
    DiagnosticRequestId id,
    ApplicationPdu pdu,
    Duration timeout,
  ) onSend;

  final Future<DiagnosticMessage> Function(
    Duration timeout,
  ) onReceiveContinuation;

  @override
  Future<DiagnosticMessage> send(
    DiagnosticRequestId id,
    ApplicationPdu pdu,
    Duration timeout,
  ) =>
      onSend(id, pdu, timeout);

  @override
  Future<DiagnosticMessage> receiveContinuation(Duration timeout) =>
      onReceiveContinuation(timeout);
}

// -----------------------------------------------------------------------------
// Transaction State & Classification
// -----------------------------------------------------------------------------

/// Finite states of a UDS transaction lifecycle.
enum UdsTransactionState {
  created,
  sendingInitial,
  awaitingP2,
  busyRepeatDelay,
  sendingRetry,
  awaitingP2Star,
  completed,
}

/// Specific timeout category that triggered transaction termination.
enum UdsTimeoutType {
  /// Server failed to respond within standard P2 timeout.
  p2,

  /// Server failed to respond within enhanced P2* timeout following NRC 0x78.
  p2Star,

  /// Entire transaction exceeded the configured total timeout budget.
  total,
}

// -----------------------------------------------------------------------------
// Transaction Outcomes (Sealed Hierarchy)
// -----------------------------------------------------------------------------

/// Sealed base class for all terminal outcomes of a UDS application transaction.
sealed class UdsTransactionResult {
  const UdsTransactionResult({
    required this.request,
    required this.attempts,
    required this.retries,
    required this.responsePendingCount,
    required this.elapsed,
  });

  /// The original request submitted to the transaction engine.
  final UdsTransactionRequest request;

  /// Total number of outgoing wire sends initiated (initial + retries).
  final int attempts;

  /// Total retry attempts performed (0 on initial success).
  final int retries;

  /// Total number of NRC 0x78 (responsePending) responses received.
  final int responsePendingCount;

  /// Total monotonic elapsed duration of the transaction.
  final Duration elapsed;

  /// Whether the transaction resolved successfully.
  bool get isSuccess => this is UdsTransactionSuccess;
}

/// Positive terminal outcome for a UDS transaction.
final class UdsTransactionSuccess extends UdsTransactionResult {
  const UdsTransactionSuccess({
    required super.request,
    required super.attempts,
    required super.retries,
    required super.responsePendingCount,
    required super.elapsed,
    required this.responsePdu,
    this.sourceAddress,
    this.readResult,
    this.dtcResult,
  });

  /// Raw response application PDU.
  final ApplicationPdu responsePdu;

  /// Attributed source address of the responding ECU.
  final DiagnosticSourceAddress? sourceAddress;

  /// Parsed Service 0x22 result, if applicable.
  final UdsReadSuccess? readResult;

  /// Parsed Service 0x19 result, if applicable.
  final UdsDtcSuccess? dtcResult;

  /// Shortcut to raw response payload bytes.
  List<int> get responseBytes => responsePdu.bytes;

  @override
  String toString() =>
      'UdsTransactionSuccess(attempts: $attempts, pending: $responsePendingCount, elapsed: ${elapsed.inMilliseconds}ms)';
}

/// Sealed base class for all non-successful transaction outcomes.
sealed class UdsTransactionFailure extends UdsTransactionResult {
  const UdsTransactionFailure({
    required super.request,
    required super.attempts,
    required super.retries,
    required super.responsePendingCount,
    required super.elapsed,
  });
}

/// Terminal negative response received from server (e.g. 0x22 conditionsNotCorrect, 0x31 requestOutOfRange).
final class UdsTransactionTerminalNegative extends UdsTransactionFailure {
  const UdsTransactionTerminalNegative({
    required super.request,
    required super.attempts,
    required super.retries,
    required super.responsePendingCount,
    required super.elapsed,
    required this.nrc,
    required this.originalSid,
  });

  /// The parsed negative response code.
  final UdsNrc nrc;

  /// Echoed original service ID.
  final int originalSid;

  @override
  String toString() =>
      'UdsTransactionTerminalNegative(NRC: $nrc, originalSid: 0x${originalSid.toRadixString(16).toUpperCase()})';
}

/// Max retries for NRC 0x21 (busyRepeatRequest) exceeded.
final class UdsTransactionBusyRetryExhausted extends UdsTransactionFailure {
  const UdsTransactionBusyRetryExhausted({
    required super.request,
    required super.attempts,
    required super.retries,
    required super.responsePendingCount,
    required super.elapsed,
    required this.maxRetries,
  });

  final int maxRetries;
  UdsNrc get lastNrc => UdsNrc.busyRepeatRequest;

  @override
  String toString() =>
      'UdsTransactionBusyRetryExhausted(retries: $retries/$maxRetries)';
}

/// Max consecutive NRC 0x78 (responsePending) received.
final class UdsTransactionResponsePendingExhausted
    extends UdsTransactionFailure {
  const UdsTransactionResponsePendingExhausted({
    required super.request,
    required super.attempts,
    required super.retries,
    required super.responsePendingCount,
    required super.elapsed,
    required this.maxPending,
  });

  final int maxPending;
  UdsNrc get lastNrc => UdsNrc.requestCorrectlyReceivedResponsePending;

  @override
  String toString() =>
      'UdsTransactionResponsePendingExhausted(pendingCount: $responsePendingCount/$maxPending)';
}

/// Timeout exceeded during the transaction (P2, P2*, or Total).
final class UdsTransactionTimedOut extends UdsTransactionFailure {
  const UdsTransactionTimedOut({
    required super.request,
    required super.attempts,
    required super.retries,
    required super.responsePendingCount,
    required super.elapsed,
    required this.timeoutType,
  });

  /// Which timeout deadline was exceeded.
  final UdsTimeoutType timeoutType;

  @override
  String toString() =>
      'UdsTransactionTimedOut($timeoutType, elapsed: ${elapsed.inMilliseconds}ms)';
}

/// Transaction was cancelled via [DiagnosticCancellation].
final class UdsTransactionCancelled extends UdsTransactionFailure {
  const UdsTransactionCancelled({
    required super.request,
    required super.attempts,
    required super.retries,
    required super.responsePendingCount,
    required super.elapsed,
    this.reason,
  });

  final String? reason;

  @override
  String toString() =>
      'UdsTransactionCancelled(${reason ?? "token cancelled"}, elapsed: ${elapsed.inMilliseconds}ms)';
}

/// Transaction retired due to connection reconnect or generation mismatch.
final class UdsTransactionRetired extends UdsTransactionFailure {
  const UdsTransactionRetired({
    required super.request,
    required super.attempts,
    required super.retries,
    required super.responsePendingCount,
    required super.elapsed,
    required this.expectedGeneration,
    required this.actualGeneration,
  });

  final int expectedGeneration;
  final int actualGeneration;

  @override
  String toString() =>
      'UdsTransactionRetired(expectedGen: $expectedGeneration, actualGen: $actualGeneration)';
}

/// Response received from an ECU address different than expected responder.
final class UdsTransactionSourceMismatch extends UdsTransactionFailure {
  const UdsTransactionSourceMismatch({
    required super.request,
    required super.attempts,
    required super.retries,
    required super.responsePendingCount,
    required super.elapsed,
    required this.expectedSource,
    required this.actualSource,
  });

  final DiagnosticSourceAddress? expectedSource;
  final DiagnosticSourceAddress? actualSource;

  @override
  String toString() =>
      'UdsTransactionSourceMismatch(expected: $expectedSource, actual: $actualSource)';
}

/// Response payload was structurally malformed, truncated, or contained invalid echoes.
final class UdsTransactionMalformed extends UdsTransactionFailure {
  const UdsTransactionMalformed({
    required super.request,
    required super.attempts,
    required super.retries,
    required super.responsePendingCount,
    required super.elapsed,
    required this.message,
    this.rawBytes,
  });

  final String message;
  final List<int>? rawBytes;

  @override
  String toString() => 'UdsTransactionMalformed($message)';
}
