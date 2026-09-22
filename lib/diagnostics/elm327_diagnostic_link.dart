library;

import 'dart:async';

import '../obd/elm327_client.dart';
import '../obd/transport/obd_transport.dart';
import 'diagnostic_link.dart';

/// Thin adapter bridging [DiagnosticLink] to [Elm327Client].
class Elm327DiagnosticLink implements DiagnosticLink {
  final Elm327Client client;

  Elm327DiagnosticLink(this.client);

  @override
  Set<DiagnosticCapability> get capabilities {
    if (!client.addressing.supportsObd2) {
      return const {};
    }
    if (client.addressing.isCan) {
      return const {
        DiagnosticCapability.applicationPdu,
        DiagnosticCapability.wholeVehicleObd,
        DiagnosticCapability.physicalEcuAddressing,
      };
    }
    return const {
      DiagnosticCapability.applicationPdu,
      DiagnosticCapability.wholeVehicleObd,
    };
  }

  @override
  int get connectionGeneration => client.connectionGeneration;

  @override
  Future<DiagnosticResponse> send(DiagnosticRequest request) async {
    if (request.cancellation.isCancelled) {
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.cancelled,
        message: 'Request was cancelled before admission.',
      );
    }

    if (request.connectionGeneration != client.connectionGeneration) {
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredGeneration,
        message:
            'Request connection generation (${request.connectionGeneration}) does not match current link generation (${client.connectionGeneration}).',
      );
    }

    if (request.deadline != null && !request.deadline!.isAfter(DateTime.now())) {
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.deadlineExpired,
        message: 'Request deadline has already expired before transmission.',
      );
    }

    for (final cap in request.requiredCapabilities) {
      if (!capabilities.contains(cap)) {
        throw DiagnosticLinkException(
          kind: DiagnosticFailureKind.capabilityUnavailable,
          message: 'Link does not support required capability: $cap.',
        );
      }
    }

    final String? header;
    if (request.target == DiagnosticTarget.wholeVehicleObd) {
      header = null;
    } else if (request.target is PhysicalCanDiagnosticTarget) {
      final physicalTarget = request.target as PhysicalCanDiagnosticTarget;
      if (!client.addressing.isCan || !client.addressing.supportsObd2) {
        throw const DiagnosticLinkException(
          kind: DiagnosticFailureKind.unsupportedTarget,
          message:
              'Physical CAN addressing requires a resolved OBD2 CAN bus.',
        );
      }
      if (!client.addressing.acceptsHeader(physicalTarget.requestIdentifier.value)) {
        throw DiagnosticLinkException(
          kind: DiagnosticFailureKind.unsupportedTarget,
          message:
              'Request identifier ${physicalTarget.requestIdentifier.value} does not match the resolved CAN bus header width.',
        );
      }
      if (!client.addressing.acceptedReceiveWidths.contains(
        physicalTarget.expectedResponderIdentifier.value.length,
      )) {
        throw DiagnosticLinkException(
          kind: DiagnosticFailureKind.unsupportedTarget,
          message:
              'Expected responder identifier ${physicalTarget.expectedResponderIdentifier.value} does not match accepted receive widths for the resolved CAN bus.',
        );
      }
      header = physicalTarget.requestIdentifier.value;
    } else {
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.unsupportedTarget,
        message: 'Target ${request.target} is not supported by Elm327DiagnosticLink.',
      );
    }

    if (request.ownership.mode != DiagnosticOwnershipMode.oneShot) {
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.capabilityUnavailable,
        message:
            'Ownership mode ${request.ownership.mode} is not supported in Slice 1.',
      );
    }

    if (client.mayTransmit != null && !client.mayTransmit!(request.ownership.token)) {
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredOperation,
        message: 'Operation owner is retired or not permitted to transmit.',
      );
    }

    final commandHex = request.pdu.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join();
    final elmAscii = ElmAsciiCommand(commandHex);

    final admissionGeneration = client.connectionGeneration;

    final ObdResponse obdResponse;
    try {
      obdResponse = await client.sendGlobal(
        elmAscii.text,
        header: header,
        timeout: request.responseTimeout,
        owner: request.ownership.token,
        deadline: request.deadline,
      );
    } on OperationRetiredException catch (e) {
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredOperation,
        message: e.message,
        cause: e,
      );
    } on TimeoutException catch (e) {
      final deadline = request.deadline;
      final isDeadline = deadline != null && !deadline.isAfter(DateTime.now());
      throw DiagnosticLinkException(
        kind: isDeadline
            ? DiagnosticFailureKind.deadlineExpired
            : DiagnosticFailureKind.responseTimeout,
        message: e.message ??
            (isDeadline
                ? 'Operation deadline expired'
                : 'Timed out waiting for response'),
        cause: e,
      );
    } on TransportException catch (e) {
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.transportFailure,
        message: e.message,
        transportIssue: e.issue,
        cause: e,
      );
    }

    if (request.cancellation.isCancelled) {
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.cancelled,
        message: 'Request was cancelled while in flight.',
      );
    }

    if (client.connectionGeneration != admissionGeneration ||
        request.connectionGeneration != client.connectionGeneration) {
      throw DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredGeneration,
        message:
            'Connection generation changed during execution (expected $admissionGeneration, current ${client.connectionGeneration}).',
      );
    }

    if (client.mayTransmit != null && !client.mayTransmit!(request.ownership.token)) {
      throw const DiagnosticLinkException(
        kind: DiagnosticFailureKind.retiredOperation,
        message: 'Operation owner was retired during transmission.',
      );
    }

    final status = obdResponse.isSuccess
        ? DiagnosticResponseStatus.success
        : (obdResponse.errorCode == Elm327ErrorCode.noData
            ? DiagnosticResponseStatus.noData
            : DiagnosticResponseStatus.error);

    final messages = <DiagnosticMessage>[
      for (final frame in obdResponse.frames)
        if (frame.bytes.isNotEmpty)
          DiagnosticMessage(
            pdu: ApplicationPdu(frame.bytes),
            sourceAddress: DiagnosticSourceAddress.tryParse(frame.sourceId),
          ),
    ];

    final provenance = DiagnosticResponseProvenance(
      backendId: 'elm327',
      connectionGeneration: admissionGeneration,
      target: request.target,
      sourceAttributionAvailable: obdResponse.headersEnabled,
    );

    return DiagnosticResponse(
      requestId: request.id,
      acceptedGeneration: admissionGeneration,
      messages: List.unmodifiable(messages),
      status: status,
      provenance: provenance,
    );
  }
}
