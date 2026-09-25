/// Timing and retry policy for ISO 14229-1 UDS application transactions.
///
/// Ref: Issue #13 ([WS-09][P1]), ISO 14229-1:2020, ISO 14229-2:2013.
///
/// SAFETY CONTRACT:
/// - Explicit immutable policy parameters; no hidden infinite defaults.
/// - p2Timeout, p2StarTimeout, totalTimeout, and busyRepeatDelay must be strictly positive.
/// - totalTimeout must dominate inner timeouts (totalTimeout >= p2Timeout).
/// - maxBusyRepeatRetries and maxResponsePendingCount must be finite and >= 0.
/// - Total deadline cannot be extended by retries or pending responses.
library;

/// Immutable timing and retry configuration for UDS read transactions.
final class UdsTransactionPolicy {
  /// Standard constructor validating all policy invariants.
  UdsTransactionPolicy({
    this.p2Timeout = const Duration(milliseconds: 50),
    this.p2StarTimeout = const Duration(milliseconds: 5000),
    this.totalTimeout = const Duration(milliseconds: 10000),
    this.maxBusyRepeatRetries = 3,
    this.busyRepeatDelay = const Duration(milliseconds: 100),
    this.maxResponsePendingCount = 10,
  }) {
    if (p2Timeout <= Duration.zero) {
      throw ArgumentError.value(p2Timeout, 'p2Timeout', 'Must be positive');
    }
    if (p2StarTimeout <= Duration.zero) {
      throw ArgumentError.value(p2StarTimeout, 'p2StarTimeout', 'Must be positive');
    }
    if (totalTimeout <= Duration.zero) {
      throw ArgumentError.value(totalTimeout, 'totalTimeout', 'Must be positive');
    }
    if (totalTimeout < p2Timeout) {
      throw ArgumentError.value(totalTimeout, 'totalTimeout', 'Must be >= p2Timeout');
    }
    if (maxBusyRepeatRetries < 0) {
      throw ArgumentError.value(maxBusyRepeatRetries, 'maxBusyRepeatRetries', 'Must be >= 0');
    }
    if (busyRepeatDelay <= Duration.zero) {
      throw ArgumentError.value(busyRepeatDelay, 'busyRepeatDelay', 'Must be positive');
    }
    if (maxResponsePendingCount < 0) {
      throw ArgumentError.value(maxResponsePendingCount, 'maxResponsePendingCount', 'Must be >= 0');
    }
  }

  const UdsTransactionPolicy._({
    required this.p2Timeout,
    required this.p2StarTimeout,
    required this.totalTimeout,
    required this.maxBusyRepeatRetries,
    required this.busyRepeatDelay,
    required this.maxResponsePendingCount,
  });

  /// Standard ISO 14229 baseline constant.
  static const standard = UdsTransactionPolicy._(
    p2Timeout: Duration(milliseconds: 50),
    p2StarTimeout: Duration(milliseconds: 5000),
    totalTimeout: Duration(milliseconds: 10000),
    maxBusyRepeatRetries: 3,
    busyRepeatDelay: Duration(milliseconds: 100),
    maxResponsePendingCount: 10,
  );

  /// Standard server response timeout (P2_server_max).
  final Duration p2Timeout;

  /// Enhanced server response timeout after NRC 0x78 (P2*_server_max).
  final Duration p2StarTimeout;

  /// Absolute maximum wall-clock timeout for the entire multi-phase transaction.
  final Duration totalTimeout;

  /// Maximum retry attempts permitted for NRC 0x21 (busyRepeatRequest).
  final int maxBusyRepeatRetries;

  /// Delay elapsed before retrying on NRC 0x21.
  final Duration busyRepeatDelay;

  /// Maximum number of consecutive NRC 0x78 (responsePending) permitted.
  final int maxResponsePendingCount;

  /// Creates a copy of this policy with replaced fields.
  UdsTransactionPolicy copyWith({
    Duration? p2Timeout,
    Duration? p2StarTimeout,
    Duration? totalTimeout,
    int? maxBusyRepeatRetries,
    Duration? busyRepeatDelay,
    int? maxResponsePendingCount,
  }) {
    return UdsTransactionPolicy(
      p2Timeout: p2Timeout ?? this.p2Timeout,
      p2StarTimeout: p2StarTimeout ?? this.p2StarTimeout,
      totalTimeout: totalTimeout ?? this.totalTimeout,
      maxBusyRepeatRetries: maxBusyRepeatRetries ?? this.maxBusyRepeatRetries,
      busyRepeatDelay: busyRepeatDelay ?? this.busyRepeatDelay,
      maxResponsePendingCount: maxResponsePendingCount ?? this.maxResponsePendingCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UdsTransactionPolicy &&
          other.p2Timeout == p2Timeout &&
          other.p2StarTimeout == p2StarTimeout &&
          other.totalTimeout == totalTimeout &&
          other.maxBusyRepeatRetries == maxBusyRepeatRetries &&
          other.busyRepeatDelay == busyRepeatDelay &&
          other.maxResponsePendingCount == maxResponsePendingCount);

  @override
  int get hashCode => Object.hash(
        p2Timeout,
        p2StarTimeout,
        totalTimeout,
        maxBusyRepeatRetries,
        busyRepeatDelay,
        maxResponsePendingCount,
      );

  @override
  String toString() =>
      'UdsTransactionPolicy(P2: ${p2Timeout.inMilliseconds}ms, P2*: ${p2StarTimeout.inMilliseconds}ms, Total: ${totalTimeout.inMilliseconds}ms, retries: $maxBusyRepeatRetries, delay: ${busyRepeatDelay.inMilliseconds}ms, maxPending: $maxResponsePendingCount)';
}
