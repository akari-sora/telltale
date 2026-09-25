/// Data types and contracts for read-only Unified Diagnostic Services (ISO 14229-1).
///
/// Ref: Issue #13 ([WS-09][P1]), ISO 14229-1:2020.
///
/// SAFETY CONTRACT:
/// - Public request builders construct ONLY Service 0x22 ReadDataByIdentifier.
/// - DID is strictly 16-bit (0x0000..0xFFFF).
/// - Non-finite decoded values (NaN, Infinity) are rejected.
/// - Unrecognized DIDs fallback to raw byte preservation without failing sibling decodes.
library;

import 'uds_nrc.dart';

/// Typed 16-bit Data Identifier (DID) defined by ISO 14229-1.
final class UdsDid implements Comparable<UdsDid> {
  /// Constructs an immutable 16-bit [UdsDid].
  ///
  /// Throws [ArgumentError] if [value] is outside 0x0000..0xFFFF.
  const UdsDid(this.value)
      : assert(
          value >= 0 && value <= 0xFFFF,
          'DID value must be a 16-bit unsigned integer (0x0000..0xFFFF)',
        );

  /// Constructs a [UdsDid] from two 8-bit bytes ([hi], [lo]).
  factory UdsDid.fromBytes(int hi, int lo) {
    if (hi < 0 || hi > 0xFF || lo < 0 || lo > 0xFF) {
      throw ArgumentError('DID high and low bytes must each be 0x00..0xFF');
    }
    return UdsDid((hi << 8) | lo);
  }

  /// Parses a 4-character hex string (e.g., "0100" or "0x0100") into a [UdsDid].
  factory UdsDid.parse(String hexStr) {
    final cleaned = hexStr.trim().replaceAll('0x', '').replaceAll('0X', '');
    if (cleaned.length != 4 || !RegExp(r'^[0-9a-fA-F]{4}$').hasMatch(cleaned)) {
      throw FormatException('Invalid 16-bit DID hex representation: "$hexStr"');
    }
    return UdsDid(int.parse(cleaned, radix: 16));
  }

  /// The raw 16-bit unsigned value (0x0000..0xFFFF).
  final int value;

  /// High byte (bits 15..8).
  int get hiByte => (value >> 8) & 0xFF;

  /// Low byte (bits 7..0).
  int get loByte => value & 0xFF;

  /// Two-byte payload representation `[hiByte, loByte]`.
  List<int> get bytes => [hiByte, loByte];

  /// Canonical hex representation, uppercase (e.g. "0x0100" or "0100").
  String toHex({bool prefix = true}) {
    final hex = value.toRadixString(16).padLeft(4, '0').toUpperCase();
    return prefix ? '0x$hex' : hex;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UdsDid && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  int compareTo(UdsDid other) => value.compareTo(other.value);

  @override
  String toString() => toHex();
}

/// Byte endianness for multi-byte DID field decoding.
enum UdsDidByteOrder {
  bigEndian,
  littleEndian,
}

/// Typed definition for decoding and validating a known UDS DID.
final class UdsDidDefinition<T> {
  const UdsDidDefinition({
    required this.did,
    this.name,
    this.exactByteLength,
    this.minByteLength,
    this.maxByteLength,
    this.unit,
    this.byteOrder = UdsDidByteOrder.bigEndian,
    this.scale,
    this.offset,
    this.customDecoder,
  }) : assert(
          exactByteLength == null ||
              (minByteLength == null && maxByteLength == null),
          'Cannot specify both exactByteLength and min/maxByteLength',
        );

  /// Target 16-bit DID.
  final UdsDid did;

  /// Human-readable label / signal name.
  final String? name;

  /// Exact expected response byte length for the data record.
  final int? exactByteLength;

  /// Minimum acceptable response byte length for the data record.
  final int? minByteLength;

  /// Maximum acceptable response byte length for the data record.
  final int? maxByteLength;

  /// Engineering unit string (e.g., "degC", "counts", "V").
  final String? unit;

  /// Byte order for numeric decoding.
  final UdsDidByteOrder byteOrder;

  /// Scaling factor applied to raw integer value.
  final double? scale;

  /// Additive offset applied after scaling.
  final double? offset;

  /// Optional custom decode lambda.
  final T Function(List<int> dataRecord)? customDecoder;

  /// Checks if [dataLength] conforms to the declared length constraints.
  bool isValidLength(int dataLength) {
    if (exactByteLength != null && dataLength != exactByteLength) return false;
    if (minByteLength != null && dataLength < minByteLength!) return false;
    if (maxByteLength != null && dataLength > maxByteLength!) return false;
    return true;
  }
}

/// Sealed base class for decoded DID data values.
sealed class UdsReadDecodeResult {
  const UdsReadDecodeResult();

  /// Target DID.
  UdsDid get did;

  /// Raw bytes received from the ECU for this DID record.
  List<int> get rawBytes;
}

/// Decoded typed value from a known DID definition.
final class UdsReadDecodedValue<T> extends UdsReadDecodeResult {
  const UdsReadDecodedValue({
    required this.did,
    required this.value,
    required this.rawBytes,
    this.unit,
  });

  @override
  final UdsDid did;

  @override
  final List<int> rawBytes;

  /// The decoded typed value.
  final T value;

  /// The associated engineering unit, if declared.
  final String? unit;

  @override
  String toString() => unit != null ? '$value $unit' : '$value';
}

/// Raw uninterpreted byte payload when no definition is registered.
final class UdsReadRawValue extends UdsReadDecodeResult {
  UdsReadRawValue({
    required this.did,
    required Iterable<int> rawBytes,
  }) : rawBytes = List.unmodifiable(rawBytes);

  @override
  final UdsDid did;

  @override
  final List<int> rawBytes;

  @override
  String toString() =>
      rawBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
}

/// Request for Service 0x22 (ReadDataByIdentifier).
///
/// SAFETY INVARIANT:
/// This builder ONLY constructs Service 0x22. It does NOT take an arbitrary
/// Service ID parameter and cannot encode write, control, or programming services.
final class UdsReadDataByIdentifierRequest {
  const UdsReadDataByIdentifierRequest(this.did);

  /// Target 16-bit DID.
  final UdsDid did;

  /// Standard ISO 14229-1 Service ID for ReadDataByIdentifier (0x22).
  int get serviceId => 0x22;

  /// Encodes the request to exact 3-byte payload `[0x22, hiByte, loByte]`.
  List<int> encode() => [0x22, did.hiByte, did.loByte];

  /// Canonical hex request string (e.g. "220100").
  String toHexString() => '22${did.toHex(prefix: false)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UdsReadDataByIdentifierRequest && other.did == did);

  @override
  int get hashCode => did.hashCode;

  @override
  String toString() => 'ReadDataByIdentifier(${did.toHex()})';
}

/// Structural and semantic failure reasons for UDS read responses.
enum UdsReadMalformedReason {
  emptyResponse,
  truncated,
  invalidHex,
  wrongPositiveSid,
  wrongDidEcho,
  wrongNegativeOriginalSid,
  missingNrc,
  unexpectedLength,
  nonFiniteDecodedValue,
  decodeError,
}

/// Sealed base class for UDS Service 0x22 parse outcomes.
sealed class UdsReadParseResult {
  const UdsReadParseResult();
}

/// Positive response for Service 0x22 (positive SID 0x62 + exact DID echo).
final class UdsReadSuccess extends UdsReadParseResult {
  UdsReadSuccess({
    required this.did,
    required Iterable<int> dataRecord,
    required this.decoded,
  }) : dataRecord = List.unmodifiable(dataRecord);

  /// The echoed DID.
  final UdsDid did;

  /// Raw data record payload (excluding 0x62 and DID echo).
  final List<int> dataRecord;

  /// Decoded representation (either typed value or raw fallback).
  final UdsReadDecodeResult decoded;

  @override
  String toString() => 'UdsReadSuccess(${did.toHex()}: $decoded)';
}

/// Negative response for Service 0x22 (`7F 22 <NRC>`).
final class UdsReadNegative extends UdsReadParseResult {
  const UdsReadNegative({
    required this.did,
    required this.originalSid,
    required this.nrc,
  });

  /// The requested DID.
  final UdsDid did;

  /// Echoed original service ID (strictly 0x22 for ReadDataByIdentifier).
  final int originalSid;

  /// The parsed negative response code.
  final UdsNrc nrc;

  @override
  String toString() => 'UdsReadNegative(${did.toHex()}: $nrc)';
}

/// Malformed or structurally invalid response for Service 0x22.
final class UdsReadMalformed extends UdsReadParseResult {
  const UdsReadMalformed({
    required this.reason,
    required this.message,
    this.rawBytes,
    this.rawString,
  });

  /// The specific rejection reason.
  final UdsReadMalformedReason reason;

  /// Descriptive explanation of the validation failure.
  final String message;

  /// Raw bytes received, if available.
  final List<int>? rawBytes;

  /// Raw string received, if available.
  final String? rawString;

  @override
  String toString() => 'UdsReadMalformed($reason: $message)';
}
