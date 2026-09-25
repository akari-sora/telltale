/// Diagnostic link channel adapter for UDS transaction execution.
///
/// Ref: Issue #13 ([WS-09][P1]), ISO 14229-1:2020, ISO 14229-2:2013.
///
/// SAFETY CONTRACT:
/// - Adapts [DiagnosticLink.send] into [UdsTransactionChannel].
/// - Enforces half-duplex wire ownership using oneShot ownership mode with caller's owner token.
/// - Validates generation consistency and cancellation before and after link operations.
/// - Buffers continuation messages received in multi-frame responses for NRC 0x78 processing.
/// - Fail-closed: empty messages, response timeouts, disconnected links, or mismatched addresses are rejected.
library;

import 'dart:async';
import 'dart:collection';

import '../diagnostic_link.dart';
import 'uds_transaction_types.dart';

/// Adapter connecting [UdsTransactionEngine] to an underlying [DiagnosticLink].
/// Exception thrown when no continuation frame is available in the channel buffer.
class DiagnosticLinkContinuationUnavailableException implements Exception {
  final String message;
  const DiagnosticLinkContinuationUnavailableException([
    this.message = 'No continuation messages available in channel buffer.',
  ]);

  @override
  String toString() => 'DiagnosticLinkContinuationUnavailableException: $message';
}

/// Adapter connecting [UdsTransactionEngine] to an underlying [DiagnosticLink].
final class DiagnosticLinkUdsTransactionChannel implements UdsTransactionChannel {
  DiagnosticLinkUdsTransactionChannel({
    required this.link,
    required this.target,
    required this.connectionGeneration,
    this.wireOwnerToken,
    this.cancellation = DiagnosticCancellation.none,
  }) : requiredCapabilities = const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.physicalEcuAddressing,
        };

  /// Maximum number of continuation messages allowed in the channel buffer.
  static const int maxContinuationMessages = 32;

  /// Maximum aggregate bytes allowed across buffered continuation messages.
  static const int maxContinuationBytes = 4096;

  /// Underlying transport link.
  final DiagnosticLink link;

  /// Addressing target for all transactions sent through this channel.
  final DiagnosticTarget target;

  /// Expected connection generation at admission.
  final int connectionGeneration;

  /// Opaque token identifying the exclusive wire owner.
  final Object? wireOwnerToken;

  /// Cancellation token governing channel operations.
  final DiagnosticCancellation cancellation;

  /// Capabilities required by this channel.
  final Set<DiagnosticCapability> requiredCapabilities;

  final ListQueue<DiagnosticMessage> _continuationQueue =
      ListQueue<DiagnosticMessage>();

  /// Number of buffered continuation messages waiting to be consumed.
  int get bufferedContinuationCount => _continuationQueue.length;

  /// Clears buffered continuation messages.
  void clearContinuationQueue() {
    _continuationQueue.clear();
  }

  @override
  Future<DiagnosticMessage> send(
    DiagnosticRequestId id,
    ApplicationPdu pdu,
    Duration timeout,
  ) async {
    _checkPreconditions();
    clearContinuationQueue();

    // Read-only admission & owner verification (A9)
    if (wireOwnerToken == null) {
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message: 'Channel requires valid wireOwnerToken for admission.',
      );
    }

    if (pdu.bytes.isEmpty) {
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message: 'Empty PDU rejected.',
      );
    }

    final sid = pdu.bytes.first;
    if (sid != 0x22 && sid != 0x19) {
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message:
            'Service 0x${sid.toRadixString(16).toUpperCase()} is not admitted for read-only UDS transaction.',
      );
    }

    if (sid == 0x22 && pdu.bytes.length < 3) {
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message: 'Service 0x22 requires at least 2 DID bytes.',
      );
    }

    if (sid == 0x19) {
      if (pdu.bytes.length < 2) {
        throw const DiagnosticLinkException(
          kind: DiagnosticFailureKind.unsupportedTarget,
          message: 'Service 0x19 requires at least 1 sub-function byte.',
        );
      }
      final subfunc = pdu.bytes[1];
      if (subfunc != 0x02 && subfunc != 0x0A) {
        throw DiagnosticLinkException(
          kind: DiagnosticFailureKind.unsupportedTarget,
          message:
              'Service 0x19 subfunction 0x${subfunc.toRadixString(16).toUpperCase()} is not admitted for read-only UDS transaction.',
        );
      }
      if (subfunc == 0x02 && pdu.bytes.length < 3) {
        throw const DiagnosticLinkException(
          kind: DiagnosticFailureKind.unsupportedTarget,
          message: 'Service 0x19 0x02 requires status mask byte.',
        );
      }
    }

    final deadline = DateTime.now().add(timeout);
    final request = DiagnosticRequest(
      id: id,
      pdu: pdu,
      target: target,
      requiredCapabilities: requiredCapabilities,
      connectionGeneration: connectionGeneration,
      responseTimeout: timeout,
      deadline: deadline,
      cancellation: cancellation,
      ownership: DiagnosticOwnership(
        mode: DiagnosticOwnershipMode.oneShot,
        token: wireOwnerToken,
      ),
    );

    final DiagnosticResponse response;
    try {
      response = await link.send(request);
    } on DiagnosticLinkException catch (e) {
      clearContinuationQueue();
      if (e.kind == DiagnosticFailureKind.responseTimeout ||
          e.kind == DiagnosticFailureKind.deadlineExpired) {
        throw TimeoutException(e.message, timeout);
      }
      rethrow;
    } catch (_) {
      clearContinuationQueue();
      rethrow;
    }

    try {
      _checkPostconditions(deadline: deadline, timeout: timeout);
    } catch (_) {
      clearContinuationQueue();
      rethrow;
    }

    // Strict Envelope Validation (R1 / A2):
    // 1. Request ID must match requested ID.
    if (response.requestId != id) {
      clearContinuationQueue();
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredOperation,
        message:
            'Response requestId (${response.requestId}) does not match request id ($id).',
      );
    }

    // 2. Accepted generation must match channel connectionGeneration.
    if (response.acceptedGeneration != connectionGeneration) {
      clearContinuationQueue();
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredGeneration,
        message:
            'Response acceptedGeneration (${response.acceptedGeneration}) does not match expected generation ($connectionGeneration).',
      );
    }

    // 3. Provenance connection generation must match expected connectionGeneration.
    if (response.provenance.connectionGeneration != connectionGeneration) {
      clearContinuationQueue();
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredGeneration,
        message:
            'Response provenance connectionGeneration (${response.provenance.connectionGeneration}) does not match expected generation ($connectionGeneration).',
      );
    }

    // 4. Provenance target must match requested target.
    if (response.provenance.target != target) {
      clearContinuationQueue();
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message: 'Response provenance target does not match requested target.',
      );
    }

    // 5. Response status must be success (not error, rejected, or unmapped).
    if (response.status != DiagnosticResponseStatus.success) {
      clearContinuationQueue();
      if (response.status == DiagnosticResponseStatus.noData ||
          response.messages.isEmpty) {
        throw TimeoutException(
          'Diagnostic link returned no data within timeout.',
          timeout,
        );
      }
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message:
            'Diagnostic link returned non-success response status (${response.status.name}).',
      );
    }

    if (response.messages.isEmpty) {
      clearContinuationQueue();
      throw TimeoutException(
        'Diagnostic link returned no data within timeout.',
        timeout,
      );
    }

    // 6. Capacity constraints (A8)
    if (response.messages.length > maxContinuationMessages) {
      clearContinuationQueue();
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message: 'Response exceeded maximum message count limit.',
      );
    }

    var aggregateBytes = 0;
    for (final m in response.messages) {
      aggregateBytes += m.pdu.bytes.length;
    }
    if (aggregateBytes > maxContinuationBytes) {
      clearContinuationQueue();
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message: 'Response exceeded maximum aggregate byte capacity limit.',
      );
    }

    final expResponderId = target.expectedResponderIdentifier;
    if (expResponderId == null) {
      clearContinuationQueue();
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message: 'Channel targeting requires physical CAN addressing target.',
      );
    }
    final expectedResponder = expResponderId.value.toUpperCase();

    if (!response.provenance.sourceAttributionAvailable) {
      clearContinuationQueue();
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message:
            'Physical CAN targeting requires source attribution from underlying link.',
      );
    }

    // Fail-closed defense (R1 / A3): If any frame is from an unexpected or unattributed source,
    // reject the entire batch immediately. Never filter out wrong sources to pick a single matching frame.
    for (final msg in response.messages) {
      final src = msg.sourceAddress?.value.toUpperCase();
      if (src == null || src != expectedResponder) {
        clearContinuationQueue();
        throw DiagnosticLinkException(
          kind: DiagnosticFailureKind.unsupportedTarget,
          message:
              'Response contains frame from unexpected or missing source ($src; expected $expectedResponder).',
        );
      }
    }

    final firstMessage = response.messages.first;
    for (var i = 1; i < response.messages.length; i++) {
      _continuationQueue.add(response.messages[i]);
    }
    return firstMessage;
  }

  @override
  Future<DiagnosticMessage> receiveContinuation(Duration timeout) async {
    _checkPreconditions();
    final deadline = DateTime.now().add(timeout);

    if (_continuationQueue.isEmpty) {
      // Clear unavailable continuation without pretending to have waited or timed out
      throw const DiagnosticLinkContinuationUnavailableException();
    }

    final msg = _continuationQueue.removeFirst();
    try {
      _checkPostconditions(deadline: deadline, timeout: timeout);
    } catch (_) {
      clearContinuationQueue();
      rethrow;
    }
    _validateContinuationAttribution(msg);
    return msg;
  }

  void _validateContinuationAttribution(DiagnosticMessage msg) {
    final expResponderId = target.expectedResponderIdentifier;
    final expectedResponder = expResponderId?.value.toUpperCase();
    if (msg.sourceAddress?.value.toUpperCase() != expectedResponder) {
      clearContinuationQueue();
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message:
            'Continuation message source (${msg.sourceAddress?.value}) does not match expected responder ($expectedResponder).',
      );
    }
  }

  void _checkPreconditions() {
    if (cancellation.isCancelled) {
      clearContinuationQueue();
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.cancelled,
        message: 'Channel operation was cancelled.',
      );
    }
    if (link.connectionGeneration != connectionGeneration) {
      clearContinuationQueue();
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredGeneration,
        message:
            'Channel generation ($connectionGeneration) does not match link generation (${link.connectionGeneration}).',
      );
    }
  }

  void _checkPostconditions({DateTime? deadline, Duration? timeout}) {
    if (cancellation.isCancelled) {
      clearContinuationQueue();
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.cancelled,
        message: 'Channel operation was cancelled in flight.',
      );
    }
    if (link.connectionGeneration != connectionGeneration) {
      clearContinuationQueue();
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredGeneration,
        message:
            'Link generation changed during channel operation (expected $connectionGeneration, got ${link.connectionGeneration}).',
      );
    }
    if (deadline != null && !DateTime.now().isBefore(deadline)) {
      clearContinuationQueue();
      throw TimeoutException(
        'Operation deadline expired after transmission.',
        timeout,
      );
    }
  }
}
