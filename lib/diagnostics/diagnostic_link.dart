library;

import '../obd/transport/obd_transport.dart' show TransportIssue;

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// ELM adapter ASCII command representation only.
///
/// No CR/LF; non-empty ASCII; normalized spelling is explicit.
/// This type is not the public application-request payload.
class ElmAsciiCommand {
  final String text;

  ElmAsciiCommand(String input) : text = _validate(input);

  static String _validate(String input) {
    if (input.isEmpty) {
      throw ArgumentError.value(input, 'input', 'ELM command must not be empty.');
    }
    for (var i = 0; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      if (code == 0x0D || code == 0x0A) {
        throw ArgumentError.value(
          input,
          'input',
          'ELM command must not contain CR or LF.',
        );
      }
      if (code < 0x20 || code > 0x7E) {
        throw ArgumentError.value(
          input,
          'input',
          'ELM command must contain only printable ASCII characters.',
        );
      }
    }
    return input;
  }

  String get normalized => text.trim().toUpperCase();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElmAsciiCommand &&
          runtimeType == other.runtimeType &&
          text == other.text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'ElmAsciiCommand($text)';
}

/// Classic CAN representation only: standard ID <= 0x7FF, extended ID <= 0x1FFFFFFF,
/// data bytes 0..255, max 8 bytes.
///
/// This does not claim a raw-CAN backend or CAN-FD support.
class CanFrame {
  final int id;
  final bool isExtended;
  final List<int> data;

  CanFrame({
    required this.id,
    this.isExtended = false,
    required List<int> data,
  }) : data = List.unmodifiable(_validateData(data)) {
    if (id < 0) {
      throw ArgumentError.value(id, 'id', 'CAN ID cannot be negative.');
    }
    if (isExtended) {
      if (id > 0x1FFFFFFF) {
        throw ArgumentError.value(
          id,
          'id',
          'Extended CAN ID must be <= 0x1FFFFFFF.',
        );
      }
    } else {
      if (id > 0x7FF) {
        throw ArgumentError.value(
          id,
          'id',
          'Standard CAN ID must be <= 0x7FF.',
        );
      }
    }
  }

  static List<int> _validateData(List<int> bytes) {
    if (bytes.length > 8) {
      throw ArgumentError.value(
        bytes.length,
        'data',
        'Classic CAN frame data cannot exceed 8 bytes.',
      );
    }
    for (final b in bytes) {
      if (b < 0 || b > 255) {
        throw ArgumentError.value(
          b,
          'data',
          'CAN frame byte must be between 0 and 255.',
        );
      }
    }
    return bytes;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanFrame &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isExtended == other.isExtended &&
          _listEquals(data, other.data);

  @override
  int get hashCode => Object.hash(id, isExtended, Object.hashAll(data));

  @override
  String toString() =>
      'CanFrame(id: 0x${id.toRadixString(16).toUpperCase()}, extended: $isExtended, data: $data)';
}

/// ISO-TP reassembled payload bytes, immutable, <= 4095 bytes.
///
/// Contains no CAN identifier and no implicit PCI interpretation by callers.
class IsoTpPayload {
  final List<int> bytes;

  IsoTpPayload(List<int> bytes) : bytes = List.unmodifiable(_validate(bytes));

  static List<int> _validate(List<int> bytes) {
    if (bytes.length > 4095) {
      throw ArgumentError.value(
        bytes.length,
        'bytes',
        'ISO-TP payload length cannot exceed 4095 bytes.',
      );
    }
    for (final b in bytes) {
      if (b < 0 || b > 255) {
        throw ArgumentError.value(b, 'bytes', 'Byte must be between 0 and 255.');
      }
    }
    return bytes;
  }

  int get length => bytes.length;
  bool get isEmpty => bytes.isEmpty;
  bool get isNotEmpty => bytes.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IsoTpPayload &&
          runtimeType == other.runtimeType &&
          _listEquals(bytes, other.bytes);

  @override
  int get hashCode => Object.hashAll(bytes);

  @override
  String toString() => 'IsoTpPayload(${bytes.length} bytes)';
}

/// Application-layer bytes, immutable and non-empty.
///
/// Callers never infer CAN/ISO-TP framing from this type.
class ApplicationPdu {
  final List<int> bytes;

  ApplicationPdu(List<int> bytes) : bytes = List.unmodifiable(_validate(bytes));

  static List<int> _validate(List<int> input) {
    if (input.isEmpty) {
      throw ArgumentError.value(input, 'input', 'Application PDU cannot be empty.');
    }
    for (final b in input) {
      if (b < 0 || b > 255) {
        throw ArgumentError.value(b, 'input', 'PDU byte must be between 0 and 255.');
      }
    }
    return input;
  }

  int get length => bytes.length;
  int operator [](int index) => bytes[index];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApplicationPdu &&
          runtimeType == other.runtimeType &&
          _listEquals(bytes, other.bytes);

  @override
  int get hashCode => Object.hashAll(bytes);

  @override
  String toString() =>
      'ApplicationPdu(${bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')})';
}

/// Opaque request correlation identity echoed in the reply.
class DiagnosticRequestId {
  final String value;

  const DiagnosticRequestId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticRequestId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DiagnosticRequestId($value)';
}

/// Target destination for diagnostic exchange.
abstract class DiagnosticTarget {
  const DiagnosticTarget();

  static const DiagnosticTarget wholeVehicleObd = _WholeVehicleObdTarget();

  const factory DiagnosticTarget.physicalCan({
    required DiagnosticCanIdentifier requestIdentifier,
    required DiagnosticCanIdentifier expectedResponderIdentifier,
  }) = PhysicalCanDiagnosticTarget;

  DiagnosticCanIdentifier? get requestIdentifier => null;
  DiagnosticCanIdentifier? get expectedResponderIdentifier => null;
}

class _WholeVehicleObdTarget extends DiagnosticTarget {
  const _WholeVehicleObdTarget();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _WholeVehicleObdTarget && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'DiagnosticTarget.wholeVehicleObd';
}

class PhysicalCanDiagnosticTarget extends DiagnosticTarget {
  @override
  final DiagnosticCanIdentifier requestIdentifier;
  @override
  final DiagnosticCanIdentifier expectedResponderIdentifier;

  const PhysicalCanDiagnosticTarget({
    required this.requestIdentifier,
    required this.expectedResponderIdentifier,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhysicalCanDiagnosticTarget &&
          runtimeType == other.runtimeType &&
          requestIdentifier == other.requestIdentifier &&
          expectedResponderIdentifier == other.expectedResponderIdentifier;

  @override
  int get hashCode => Object.hash(
        PhysicalCanDiagnosticTarget,
        requestIdentifier,
        expectedResponderIdentifier,
      );

  @override
  String toString() =>
      'DiagnosticTarget.physicalCan(req: $requestIdentifier, exp: $expectedResponderIdentifier)';
}

/// Strongly-typed CAN routing identifier for diagnostic addressing.
///
/// 11-bit standard identifiers: 000..7FF, canonicalized to 3 uppercase hex digits.
/// 29-bit extended identifiers: 00000000..1FFFFFFF, canonicalized to 8 uppercase hex digits.
///
/// Rejects empty input, non-hex strings, invalid character widths, and out-of-range IDs.
class DiagnosticCanIdentifier {
  final int id;
  final bool isExtended;
  final String value;

  bool get isStandard => !isExtended;

  const DiagnosticCanIdentifier._({
    required this.id,
    required this.isExtended,
    required this.value,
  });

  factory DiagnosticCanIdentifier.standard(int id) {
    if (id < 0 || id > 0x7FF) {
      throw ArgumentError.value(
        id,
        'id',
        'Standard 11-bit CAN ID must be between 0x000 and 0x7FF (got 0x${id.toRadixString(16)}).',
      );
    }
    final value = id.toRadixString(16).padLeft(3, '0').toUpperCase();
    return DiagnosticCanIdentifier._(
      id: id,
      isExtended: false,
      value: value,
    );
  }

  factory DiagnosticCanIdentifier.extended(int id) {
    if (id < 0 || id > 0x1FFFFFFF) {
      throw ArgumentError.value(
        id,
        'id',
        'Extended 29-bit CAN ID must be between 0x00000000 and 0x1FFFFFFF (got 0x${id.toRadixString(16)}).',
      );
    }
    final value = id.toRadixString(16).padLeft(8, '0').toUpperCase();
    return DiagnosticCanIdentifier._(
      id: id,
      isExtended: true,
      value: value,
    );
  }

  factory DiagnosticCanIdentifier.parse(String raw) {
    final trimmed = raw.trim().toUpperCase();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'CAN identifier cannot be empty.');
    }
    final length = trimmed.length;
    if (length != 3 && length != 8) {
      throw ArgumentError.value(
        raw,
        'raw',
        'CAN identifier must be 3 or 8 hex characters, got length $length.',
      );
    }
    final int? parsed = int.tryParse(trimmed, radix: 16);
    if (parsed == null) {
      throw ArgumentError.value(
        raw,
        'raw',
        'CAN identifier must contain only valid hexadecimal characters.',
      );
    }
    if (length == 3) {
      if (parsed > 0x7FF) {
        throw ArgumentError.value(
          raw,
          'raw',
          'Standard 11-bit CAN identifier must be <= 0x7FF (got 0x$trimmed).',
        );
      }
      return DiagnosticCanIdentifier._(
        id: parsed,
        isExtended: false,
        value: trimmed,
      );
    } else {
      if (parsed > 0x1FFFFFFF) {
        throw ArgumentError.value(
          raw,
          'raw',
          'Extended 29-bit CAN identifier must be <= 0x1FFFFFFF (got 0x$trimmed).',
        );
      }
      return DiagnosticCanIdentifier._(
        id: parsed,
        isExtended: true,
        value: trimmed,
      );
    }
  }

  static DiagnosticCanIdentifier? tryParse(String? raw) {
    if (raw == null) return null;
    try {
      return DiagnosticCanIdentifier.parse(raw);
    } on ArgumentError {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticCanIdentifier &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isExtended == other.isExtended &&
          value == other.value;

  @override
  int get hashCode => Object.hash(id, isExtended, value);

  @override
  String toString() => 'DiagnosticCanIdentifier($value)';
}

/// Capabilities exposed by diagnostic links.
enum DiagnosticCapability {
  applicationPdu,
  wholeVehicleObd,
  physicalEcuAddressing,
  rawCanFrame,
  rawIsoTpPayload,
}

/// Ownership execution mode.
enum DiagnosticOwnershipMode {
  polling,
  oneShot,
  exclusive,
}

/// Ownership claim carrying execution mode and lifecycle token.
class DiagnosticOwnership {
  final DiagnosticOwnershipMode mode;
  final Object? token;

  const DiagnosticOwnership({
    required this.mode,
    this.token,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticOwnership &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          token == other.token;

  @override
  int get hashCode => Object.hash(mode, token);

  @override
  String toString() => 'DiagnosticOwnership(mode: $mode, token: $token)';
}

/// Explicit cancellation state token.
class DiagnosticCancellation {
  final bool Function()? _isCancelled;

  const DiagnosticCancellation([bool Function()? isCancelled])
      : _isCancelled = isCancelled;

  static const DiagnosticCancellation none = DiagnosticCancellation();

  bool get isCancelled => _isCancelled?.call() ?? false;

  @override
  String toString() => 'DiagnosticCancellation(isCancelled: $isCancelled)';
}

/// Controller source for [DiagnosticCancellation].
class DiagnosticCancellationTokenSource {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
  }

  DiagnosticCancellation get token => DiagnosticCancellation(() => _cancelled);
}

/// Request sent through [DiagnosticLink].
class DiagnosticRequest {
  final DiagnosticRequestId id;
  final ApplicationPdu pdu;
  final DiagnosticTarget target;
  final Set<DiagnosticCapability> requiredCapabilities;
  final int connectionGeneration;
  final DateTime? deadline;
  final Duration? responseTimeout;
  final DiagnosticCancellation cancellation;
  final DiagnosticOwnership ownership;

  const DiagnosticRequest({
    required this.id,
    required this.pdu,
    required this.target,
    required this.requiredCapabilities,
    required this.connectionGeneration,
    this.deadline,
    this.responseTimeout,
    this.cancellation = DiagnosticCancellation.none,
    required this.ownership,
  });

  @override
  String toString() =>
      'DiagnosticRequest(id: $id, pdu: $pdu, target: $target, gen: $connectionGeneration, deadline: $deadline, responseTimeout: $responseTimeout)';
}

/// Immutable, typed diagnostic source address (ECU responder address).
///
/// Accepts the three standard forms produced by ELM327 attribution:
/// - 2 hex digits: legacy source byte (00..FF)
/// - 3 hex digits: standard CAN 11-bit ID (000..7FF)
/// - 8 hex digits: extended CAN 29-bit ID (00000000..1FFFFFFF)
///
/// Canonicalized to uppercase hex. Rejects empty, non-hex, invalid width,
/// and out-of-range IDs.
class DiagnosticSourceAddress {
  final String value;

  DiagnosticSourceAddress(String raw) : value = _validateAndCanonicalize(raw);

  static DiagnosticSourceAddress? tryParse(String? raw) {
    if (raw == null) return null;
    try {
      return DiagnosticSourceAddress(raw);
    } on ArgumentError {
      return null;
    }
  }

  static String _validateAndCanonicalize(String raw) {
    final trimmed = raw.trim().toUpperCase();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'Source address cannot be empty.');
    }
    final length = trimmed.length;
    if (length != 2 && length != 3 && length != 8) {
      throw ArgumentError.value(
        raw,
        'raw',
        'Source address must be 2, 3, or 8 hex characters, got length $length.',
      );
    }
    final int? parsed = int.tryParse(trimmed, radix: 16);
    if (parsed == null) {
      throw ArgumentError.value(
        raw,
        'raw',
        'Source address must contain valid hexadecimal characters.',
      );
    }
    if (length == 3 && parsed > 0x7FF) {
      throw ArgumentError.value(
        raw,
        'raw',
        'Standard 11-bit CAN address must be <= 0x7FF (got 0x$trimmed).',
      );
    }
    if (length == 8 && parsed > 0x1FFFFFFF) {
      throw ArgumentError.value(
        raw,
        'raw',
        'Extended 29-bit CAN address must be <= 0x1FFFFFFF (got 0x$trimmed).',
      );
    }
    return trimmed;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticSourceAddress &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DiagnosticSourceAddress($value)';
}

/// Single application message from a diagnostic response.
class DiagnosticMessage {
  final ApplicationPdu pdu;
  final DiagnosticSourceAddress? sourceAddress;

  const DiagnosticMessage({
    required this.pdu,
    this.sourceAddress,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticMessage &&
          runtimeType == other.runtimeType &&
          pdu == other.pdu &&
          sourceAddress == other.sourceAddress;

  @override
  int get hashCode => Object.hash(pdu, sourceAddress);

  @override
  String toString() => 'DiagnosticMessage(pdu: $pdu, source: $sourceAddress)';
}

/// Provenance metadata describing how a response was obtained.
class DiagnosticResponseProvenance {
  final String backendId;
  final int connectionGeneration;
  final DiagnosticTarget target;
  final bool sourceAttributionAvailable;

  const DiagnosticResponseProvenance({
    this.backendId = 'elm327',
    required this.connectionGeneration,
    required this.target,
    required this.sourceAttributionAvailable,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticResponseProvenance &&
          runtimeType == other.runtimeType &&
          backendId == other.backendId &&
          connectionGeneration == other.connectionGeneration &&
          target == other.target &&
          sourceAttributionAvailable == other.sourceAttributionAvailable;

  @override
  int get hashCode => Object.hash(
        backendId,
        connectionGeneration,
        target,
        sourceAttributionAvailable,
      );

  @override
  String toString() =>
      'DiagnosticResponseProvenance(backend: $backendId, gen: $connectionGeneration, target: $target, attribution: $sourceAttributionAvailable)';
}

/// Response status classification.
enum DiagnosticResponseStatus {
  success,
  noData,
  error,
}

/// Structured response returned by [DiagnosticLink].
class DiagnosticResponse {
  final DiagnosticRequestId requestId;
  final int acceptedGeneration;
  final List<DiagnosticMessage> messages;
  final DiagnosticResponseStatus status;
  final DiagnosticResponseProvenance provenance;

  const DiagnosticResponse({
    required this.requestId,
    required this.acceptedGeneration,
    required this.messages,
    required this.status,
    required this.provenance,
  });

  bool get isSuccess => status == DiagnosticResponseStatus.success;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticResponse &&
          runtimeType == other.runtimeType &&
          requestId == other.requestId &&
          acceptedGeneration == other.acceptedGeneration &&
          status == other.status &&
          provenance == other.provenance &&
          _listEquals(messages, other.messages);

  @override
  int get hashCode => Object.hash(
        requestId,
        acceptedGeneration,
        status,
        provenance,
        Object.hashAll(messages),
      );

  @override
  String toString() =>
      'DiagnosticResponse(id: $requestId, gen: $acceptedGeneration, status: $status, messages: ${messages.length})';
}

/// Failure kinds for diagnostic link operations.
enum DiagnosticFailureKind {
  capabilityUnavailable,
  unsupportedTarget,
  cancelled,
  deadlineExpired,
  responseTimeout,
  retiredGeneration,
  retiredOperation,
  transportFailure,
}

/// Typed exception thrown by [DiagnosticLink] on failure.
class DiagnosticLinkException implements Exception {
  final DiagnosticFailureKind kind;
  final String message;
  final TransportIssue? transportIssue;
  final Object? cause;
  final StackTrace? stackTrace;

  const DiagnosticLinkException({
    required this.kind,
    required this.message,
    this.transportIssue,
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() =>
      'DiagnosticLinkException($kind, "$message"${transportIssue != null ? ', issue: $transportIssue' : ''})';
}

/// Minimal transport-independent diagnostic link abstraction.
abstract class DiagnosticLink {
  Set<DiagnosticCapability> get capabilities;
  int get connectionGeneration;
  Future<DiagnosticResponse> send(DiagnosticRequest request);
}
