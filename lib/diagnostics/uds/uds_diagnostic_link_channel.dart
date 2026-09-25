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
    this.outerDeadline,
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

  /// Optional caller-provided outer deadline constraining the overall transaction.
  final DateTime? outerDeadline;

  @override
  Future<DiagnosticMessage> send(
    DiagnosticRequestId id,
    ApplicationPdu pdu,
    Duration timeout,
  ) async {
    _checkPreconditions();
    clearContinuationQueue();

    // 1. Physical target pre-send admission check (R56-1)
    final expResponderId = target.expectedResponderIdentifier;
    if (expResponderId == null) {
      clearContinuationQueue();
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message: 'Channel targeting requires physical CAN addressing target.',
      );
    }

    // 2. Wire owner admission check
    if (wireOwnerToken == null) {
      clearContinuationQueue();
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message: 'Channel requires valid wireOwnerToken for admission.',
      );
    }

    // 3. Exact 3-shape Request Grammar Admission (R56-1 / F1):
    // Read DID: [0x22, hi, lo] (strictly 3 bytes)
    // DTC by status mask: [0x19, 0x02, mask] (strictly 3 bytes)
    // Supported DTC: [0x19, 0x0A] (strictly 2 bytes)
    final bytes = pdu.bytes;
    final bool isAdmittedGrammar;
    if (bytes.length == 3 && bytes[0] == 0x22) {
      isAdmittedGrammar = true;
    } else if (bytes.length == 3 && bytes[0] == 0x19 && bytes[1] == 0x02) {
      isAdmittedGrammar = true;
    } else if (bytes.length == 2 && bytes[0] == 0x19 && bytes[1] == 0x0A) {
      isAdmittedGrammar = true;
    } else {
      isAdmittedGrammar = false;
    }

    if (!isAdmittedGrammar) {
      clearContinuationQueue();
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message:
            'PDU [${bytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}').join(', ')}] does not match approved read-only UDS grammar.',
      );
    }

    // 4. Pre-send outer deadline check (R56-2)
    if (outerDeadline != null && !DateTime.now().isBefore(outerDeadline!)) {
      clearContinuationQueue();
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.deadlineExpired,
        message: 'Outer deadline expired prior to transmission.',
      );
    }

    final localDeadline = DateTime.now().add(timeout);
    final effectiveDeadline = outerDeadline != null && outerDeadline!.isBefore(localDeadline)
        ? outerDeadline!
        : localDeadline;
    final request = DiagnosticRequest(
      id: id,
      pdu: pdu,
      target: target,
      requiredCapabilities: requiredCapabilities,
      connectionGeneration: connectionGeneration,
      responseTimeout: timeout,
      deadline: effectiveDeadline,
      cancellation: cancellation,
      ownership: DiagnosticOwnership(
        mode: DiagnosticOwnershipMode.oneShot,
        token: wireOwnerToken,
      ),
      includePendingObservations: true,
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
      _checkPostconditions(deadline: effectiveDeadline, timeout: timeout);
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
