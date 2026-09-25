import '../diagnostic_link.dart';

/// Addressing mode for CAN / ISO-TP communication.
enum CanAddressingMode {
  /// Standard physical addressing (11-bit or 29-bit CAN ID, no extension).
  normal,

  /// ISO-TP extended addressing (first data byte carries target address).
  extended,

  /// ISO-TP mixed addressing (uses address extension byte).
  mixed,
}

/// Bitrate representation with explicit known/unknown tracking.
class CanBitrate {
  final int? value;

  CanBitrate(this.value) {
    if (value != null && value! <= 0) {
      throw ArgumentError.value(value, 'value', 'Bitrate must be positive.');
    }
  }

  const CanBitrate.unknown() : value = null;

  bool get isKnown => value != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanBitrate && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => isKnown ? '${value}bps' : 'unknown';
}

/// Backend link capability for CAN endpoints.
enum CanBackendCapability {
  /// In-memory/L0 loopback or virtual queue.
  classicalLoopback,

  /// Linux SocketCAN raw socket (CAN 2.0B / Classical).
  linuxSocketCan,

  /// Linux kernel CAN_ISOTP socket.
  linuxCanIsoTp,
}

/// Strongly-typed specification of a CAN diagnostic endpoint.
///
/// Encapsulates interface, addressing, identifier width, classical/FD mode,
/// and bitrate attributes without silent fallback or implicit conversions.
class CanEndpoint {
  final String interfaceName;
  final String namespace;
  final int generation;
  final DiagnosticCanIdentifier physicalTxId;
  final DiagnosticCanIdentifier physicalRxId;
  final bool isFd;
  final CanAddressingMode addressingMode;
  final int? txAddressExtension;
  final int? rxAddressExtension;
  final CanBitrate configuredBitrate;
  final CanBitrate observedBitrate;
  final int framePayloadLimit;
  final CanBackendCapability backendCapability;

  CanEndpoint({
    required this.interfaceName,
    this.namespace = 'default',
    required this.generation,
    required this.physicalTxId,
    required this.physicalRxId,
    this.isFd = false,
    this.addressingMode = CanAddressingMode.normal,
    this.txAddressExtension,
    this.rxAddressExtension,
    this.configuredBitrate = const CanBitrate.unknown(),
    this.observedBitrate = const CanBitrate.unknown(),
    this.framePayloadLimit = 8,
    this.backendCapability = CanBackendCapability.classicalLoopback,
  }) {
    if (interfaceName.trim().isEmpty) {
      throw ArgumentError.value(
        interfaceName,
        'interfaceName',
        'CAN interface name cannot be empty.',
      );
    }
    if (interfaceName.contains('*') ||
        interfaceName.contains('?') ||
        interfaceName.contains(' ') ||
        interfaceName.contains('\t')) {
      throw ArgumentError.value(
        interfaceName,
        'interfaceName',
        'CAN interface name cannot contain wildcards or whitespace.',
      );
    }
    if (namespace.trim().isEmpty) {
      throw ArgumentError.value(
        namespace,
        'namespace',
        'Endpoint namespace cannot be empty.',
      );
    }
    if (generation < 0) {
      throw ArgumentError.value(
        generation,
        'generation',
        'Generation cannot be negative.',
      );
    }
    if (physicalTxId.isExtended != physicalRxId.isExtended) {
      throw ArgumentError(
        'Physical CAN TX (isExtended: ${physicalTxId.isExtended}) and RX (isExtended: ${physicalRxId.isExtended}) must have matching identifier width.',
      );
    }
    if (framePayloadLimit < 1) {
      throw ArgumentError.value(
        framePayloadLimit,
        'framePayloadLimit',
        'Payload limit must be at least 1.',
      );
    }
    if (!isFd && framePayloadLimit > 8) {
      throw ArgumentError.value(
        framePayloadLimit,
        'framePayloadLimit',
        'Classical CAN payload limit cannot exceed 8 bytes.',
      );
    }
    if (addressingMode == CanAddressingMode.normal) {
      if (txAddressExtension != null || rxAddressExtension != null) {
        throw ArgumentError(
          'Normal addressing mode cannot define address extensions.',
        );
      }
    } else {
      if (txAddressExtension != null &&
          (txAddressExtension! < 0 || txAddressExtension! > 255)) {
        throw ArgumentError.value(
          txAddressExtension,
          'txAddressExtension',
          'Address extension must be between 0 and 255.',
        );
      }
      if (rxAddressExtension != null &&
          (rxAddressExtension! < 0 || rxAddressExtension! > 255)) {
        throw ArgumentError.value(
          rxAddressExtension,
          'rxAddressExtension',
          'Address extension must be between 0 and 255.',
        );
      }
    }
  }

  /// Verifies that this endpoint is strictly supported within the WS10-S1 L0 scope.
  ///
  /// WS10-S1 explicitly rejects CAN FD, non-normal addressing modes, and unapproved
  /// capabilities, failing closed rather than performing a silent downgrade.
  void assertSupportedInS1() {
    if (isFd) {
      throw UnsupportedError(
        'CAN FD is not supported in WS10-S1 L0 core. Silent downgrade prohibited.',
      );
    }
    if (addressingMode != CanAddressingMode.normal) {
      throw UnsupportedError(
        'Addressing mode $addressingMode is not supported in WS10-S1 L0 core. Silent downgrade prohibited.',
      );
    }
    if (backendCapability != CanBackendCapability.classicalLoopback) {
      throw UnsupportedError(
        'Backend capability $backendCapability is not supported in WS10-S1 L0 core.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanEndpoint &&
          runtimeType == other.runtimeType &&
          interfaceName == other.interfaceName &&
          namespace == other.namespace &&
          generation == other.generation &&
          physicalTxId == other.physicalTxId &&
          physicalRxId == other.physicalRxId &&
          isFd == other.isFd &&
          addressingMode == other.addressingMode &&
          txAddressExtension == other.txAddressExtension &&
          rxAddressExtension == other.rxAddressExtension &&
          configuredBitrate == other.configuredBitrate &&
          observedBitrate == other.observedBitrate &&
          framePayloadLimit == other.framePayloadLimit &&
          backendCapability == other.backendCapability;

  @override
  int get hashCode => Object.hash(
        interfaceName,
        namespace,
        generation,
        physicalTxId,
        physicalRxId,
        isFd,
        addressingMode,
        txAddressExtension,
        rxAddressExtension,
        configuredBitrate,
        observedBitrate,
        framePayloadLimit,
        backendCapability,
      );

  @override
  String toString() =>
      'CanEndpoint($interfaceName, ns: $namespace, gen: $generation, tx: $physicalTxId, rx: $physicalRxId, fd: $isFd, addr: $addressingMode, cap: $backendCapability)';
}
