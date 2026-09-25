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

  /// Underlying transport link.
  final DiagnosticLink link;

  /// Addressing target for all transactions sent through this channel.
  final PhysicalCanDiagnosticTarget target;

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
      if (e.kind == DiagnosticFailureKind.responseTimeout ||
          e.kind == DiagnosticFailureKind.deadlineExpired) {
        throw TimeoutException(e.message, timeout);
      }
      rethrow;
    }

    _checkPostconditions(deadline: deadline, timeout: timeout);

    // Strict Envelope Validation (R1):
    // 1. Request ID must match requested ID.
    if (response.requestId != id) {
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredOperation,
        message:
            'Response requestId (${response.requestId}) does not match request id ($id).',
      );
    }

    // 2. Accepted generation must match channel connectionGeneration.
    if (response.acceptedGeneration != connectionGeneration) {
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredGeneration,
        message:
            'Response acceptedGeneration (${response.acceptedGeneration}) does not match expected generation ($connectionGeneration).',
      );
    }

    // 3. Provenance connection generation must match expected connectionGeneration.
    if (response.provenance.connectionGeneration != connectionGeneration) {
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredGeneration,
        message:
            'Response provenance connectionGeneration (${response.provenance.connectionGeneration}) does not match expected generation ($connectionGeneration).',
      );
    }

    // 4. Provenance target must match requested target.
    if (response.provenance.target != target) {
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message: 'Response provenance target does not match requested target.',
      );
    }

    // 5. Response status must be success (not error, rejected, or unmapped).
    if (response.status != DiagnosticResponseStatus.success) {
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
      throw TimeoutException(
        'Diagnostic link returned no data within timeout.',
        timeout,
      );
    }

    final expectedResponder =
        target.expectedResponderIdentifier.value.toUpperCase();

    if (!response.provenance.sourceAttributionAvailable) {
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message:
            'Physical CAN targeting requires source attribution from underlying link.',
      );
    }

    // Fail-closed defense (R1): If any frame is from an unexpected or unattributed source,
    // reject the entire batch immediately. Never filter out wrong sources to pick a single matching frame.
    for (final msg in response.messages) {
      final src = msg.sourceAddress?.value.toUpperCase();
      if (src == null || src != expectedResponder) {
        throw DiagnosticLinkException(
          kind: DiagnosticFailureKind.unsupportedTarget,
          message:
              'Response contains frame from unexpected source ($src; expected $expectedResponder).',
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
      // Half-duplex link receives multi-frame responses during initial send().
      // If the buffer is empty, no unsolicited continuation frames can arrive.
      throw TimeoutException(
        'No continuation messages available in channel buffer.',
        timeout,
      );
    }

    final msg = _continuationQueue.removeFirst();
    _checkPostconditions(deadline: deadline, timeout: timeout);
    _validateContinuationAttribution(msg);
    return msg;
  }

  void _validateContinuationAttribution(DiagnosticMessage msg) {
    final expectedResponder =
        target.expectedResponderIdentifier.value.toUpperCase();
    if (msg.sourceAddress?.value.toUpperCase() != expectedResponder) {
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message:
            'Continuation message source (${msg.sourceAddress?.value}) does not match expected responder ($expectedResponder).',
      );
    }
  }

  void _checkPreconditions() {
    if (cancellation.isCancelled) {
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.cancelled,
        message: 'Channel operation was cancelled.',
      );
    }
    if (link.connectionGeneration != connectionGeneration) {
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredGeneration,
        message:
            'Channel generation ($connectionGeneration) does not match link generation (${link.connectionGeneration}).',
      );
    }
  }

  void _checkPostconditions({DateTime? deadline, Duration? timeout}) {
    if (cancellation.isCancelled) {
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.cancelled,
        message: 'Channel operation was cancelled in flight.',
      );
    }
    if (link.connectionGeneration != connectionGeneration) {
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredGeneration,
        message:
            'Link generation changed during channel operation (expected $connectionGeneration, got ${link.connectionGeneration}).',
      );
    }
    if (deadline != null && DateTime.now().isAfter(deadline)) {
      throw TimeoutException(
        'Operation deadline expired after transmission.',
        timeout,
      );
    }
  }
}
