/// Data types and contracts for read-only UDS Service 0x19 (ReadDTCInformation).
///
/// Ref: Issue #13 ([WS-09][P1]), ISO 14229-1:2020.
///
/// SAFETY CONTRACT:
/// - Public request builders construct ONLY Service 0x19 subfunctions 0x02 and 0x0A.
/// - Suppress-positive-response bit (0x80) is strictly disallowed.
/// - DTC identity is strictly 24-bit unsigned integer (0x000000..0xFFFFFF).
/// - 24-bit UDS DTC numbers are isolated from J1979 two-byte Dtc models.
/// - DTCStatusAvailabilityMask and DTC status bytes are strictly validated.
library;

import 'uds_nrc.dart';

/// 24-bit Diagnostic Trouble Code (DTC) defined by ISO 14229-1.
///
/// Represents an unsigned 24-bit integer (0x000000..0xFFFFFF), typically
/// structured as 2-byte DTC number + 1-byte failure type byte (FTB).
final class UdsDtcCode24 implements Comparable<UdsDtcCode24> {
  /// Constructs an immutable 24-bit [UdsDtcCode24].
  ///
  /// Throws [ArgumentError] if [value] is outside 0x000000..0xFFFFFF.
  const UdsDtcCode24(this.value)
      : assert(
          value >= 0 && value <= 0xFFFFFF,
          'DTC value must be a 24-bit unsigned integer (0x000000..0xFFFFFF)',
        );

  /// Constructs a [UdsDtcCode24] from three 8-bit bytes ([hi], [mid], [lo]).
  factory UdsDtcCode24.fromBytes(int hi, int mid, int lo) {
    if (hi < 0 || hi > 0xFF || mid < 0 || mid > 0xFF || lo < 0 || lo > 0xFF) {
      throw ArgumentError(
        'DTC high, middle, and low bytes must each be 0x00..0xFF',
      );
    }
    return UdsDtcCode24((hi << 16) | (mid << 8) | lo);
  }

  /// Parses a 6-character hex string (e.g., "010203" or "0x010203") into a [UdsDtcCode24].
  factory UdsDtcCode24.parse(String hexStr) {
    final cleaned = hexStr.trim().replaceAll('0x', '').replaceAll('0X', '');
    if (cleaned.length != 6 || !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(cleaned)) {
      throw FormatException('Invalid 24-bit DTC hex representation: "$hexStr"');
    }
    return UdsDtcCode24(int.parse(cleaned, radix: 16));
  }

  /// The raw 24-bit unsigned value (0x000000..0xFFFFFF).
  final int value;

  /// High byte (bits 23..16).
  int get hiByte => (value >> 16) & 0xFF;

  /// Middle byte (bits 15..8).
  int get midByte => (value >> 8) & 0xFF;

  /// Low byte / Failure Type Byte (bits 7..0).
  int get loByte => value & 0xFF;

  /// Three-byte payload representation `[hiByte, midByte, loByte]`.
  List<int> get bytes => [hiByte, midByte, loByte];

  /// Canonical uppercase hex representation (e.g. "0x010203" or "010203").
  String toHex({bool prefix = true}) {
    final hex = value.toRadixString(16).padLeft(6, '0').toUpperCase();
    return prefix ? '0x$hex' : hex;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UdsDtcCode24 && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  int compareTo(UdsDtcCode24 other) => value.compareTo(other.value);

  @override
  String toString() => toHex();
}

/// Request status mask for Service 0x19 0x02 (reportDTCByStatusMask).
final class UdsDtcStatusMask implements Comparable<UdsDtcStatusMask> {
  const UdsDtcStatusMask(this.raw)
      : assert(
          raw >= 0 && raw <= 0xFF,
          'DTC status mask must be an 8-bit unsigned integer (0x00..0xFF)',
        );

  final int raw;

  /// Bit 0: testFailed
  bool get testFailed => (raw & 0x01) != 0;

  /// Bit 1: testFailedThisOperationCycle
  bool get testFailedThisOperationCycle => (raw & 0x02) != 0;

  /// Bit 2: pendingDTC
  bool get pendingDTC => (raw & 0x04) != 0;

  /// Bit 3: confirmedDTC
  bool get confirmedDTC => (raw & 0x08) != 0;

  /// Bit 4: testNotCompletedSinceLastClear
  bool get testNotCompletedSinceLastClear => (raw & 0x10) != 0;

  /// Bit 5: testFailedSinceLastClear
  bool get testFailedSinceLastClear => (raw & 0x20) != 0;

  /// Bit 6: testNotCompletedThisOperationCycle
  bool get testNotCompletedThisOperationCycle => (raw & 0x40) != 0;

  /// Bit 7: warningIndicatorRequested
  bool get warningIndicatorRequested => (raw & 0x80) != 0;

  String toHex({bool prefix = true}) {
    final hex = raw.toRadixString(16).padLeft(2, '0').toUpperCase();
    return prefix ? '0x$hex' : hex;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UdsDtcStatusMask && other.raw == raw);

  @override
  int get hashCode => raw.hashCode;

  @override
  int compareTo(UdsDtcStatusMask other) => raw.compareTo(other.raw);

  @override
  String toString() => toHex();
}

/// DTC status availability mask returned by server in positive response.
final class UdsDtcStatusAvailabilityMask
    implements Comparable<UdsDtcStatusAvailabilityMask> {
  const UdsDtcStatusAvailabilityMask(this.raw)
      : assert(
          raw >= 0 && raw <= 0xFF,
          'DTC status availability mask must be an 8-bit unsigned integer (0x00..0xFF)',
        );

  final int raw;

  /// Bit 0: testFailed supported
  bool get testFailed => (raw & 0x01) != 0;

  /// Bit 1: testFailedThisOperationCycle supported
  bool get testFailedThisOperationCycle => (raw & 0x02) != 0;

  /// Bit 2: pendingDTC supported
  bool get pendingDTC => (raw & 0x04) != 0;

  /// Bit 3: confirmedDTC supported
  bool get confirmedDTC => (raw & 0x08) != 0;

  /// Bit 4: testNotCompletedSinceLastClear supported
  bool get testNotCompletedSinceLastClear => (raw & 0x10) != 0;

  /// Bit 5: testFailedSinceLastClear supported
  bool get testFailedSinceLastClear => (raw & 0x20) != 0;

  /// Bit 6: testNotCompletedThisOperationCycle supported
  bool get testNotCompletedThisOperationCycle => (raw & 0x40) != 0;

  /// Bit 7: warningIndicatorRequested supported
  bool get warningIndicatorRequested => (raw & 0x80) != 0;

  String toHex({bool prefix = true}) {
    final hex = raw.toRadixString(16).padLeft(2, '0').toUpperCase();
    return prefix ? '0x$hex' : hex;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UdsDtcStatusAvailabilityMask && other.raw == raw);

  @override
  int get hashCode => raw.hashCode;

  @override
  int compareTo(UdsDtcStatusAvailabilityMask other) => raw.compareTo(other.raw);

  @override
  String toString() => toHex();
}

/// Status byte for a specific DTC record.
final class UdsDtcStatus implements Comparable<UdsDtcStatus> {
  const UdsDtcStatus(this.raw)
      : assert(
          raw >= 0 && raw <= 0xFF,
          'DTC status must be an 8-bit unsigned integer (0x00..0xFF)',
        );

  final int raw;

  /// Bit 0: testFailed
  bool get testFailed => (raw & 0x01) != 0;

  /// Bit 1: testFailedThisOperationCycle
  bool get testFailedThisOperationCycle => (raw & 0x02) != 0;

  /// Bit 2: pendingDTC
  bool get pendingDTC => (raw & 0x04) != 0;

  /// Bit 3: confirmedDTC
  bool get confirmedDTC => (raw & 0x08) != 0;

  /// Bit 4: testNotCompletedSinceLastClear
  bool get testNotCompletedSinceLastClear => (raw & 0x10) != 0;

  /// Bit 5: testFailedSinceLastClear
  bool get testFailedSinceLastClear => (raw & 0x20) != 0;

  /// Bit 6: testNotCompletedThisOperationCycle
  bool get testNotCompletedThisOperationCycle => (raw & 0x40) != 0;

  /// Bit 7: warningIndicatorRequested
  bool get warningIndicatorRequested => (raw & 0x80) != 0;

  String toHex({bool prefix = true}) {
    final hex = raw.toRadixString(16).padLeft(2, '0').toUpperCase();
    return prefix ? '0x$hex' : hex;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UdsDtcStatus && other.raw == raw);

  @override
  int get hashCode => raw.hashCode;

  @override
  int compareTo(UdsDtcStatus other) => raw.compareTo(other.raw);

  @override
  String toString() => toHex();
}

/// Immutable record combining a 24-bit DTC and its status byte.
final class UdsDtcAndStatusRecord {
  const UdsDtcAndStatusRecord({
    required this.code,
    required this.status,
  });

  /// 24-bit Diagnostic Trouble Code.
  final UdsDtcCode24 code;

  /// Associated 8-bit status byte.
  final UdsDtcStatus status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UdsDtcAndStatusRecord &&
          other.code == code &&
          other.status == status);

  @override
  int get hashCode => Object.hash(code, status);

  @override
  String toString() => '${code.toHex()}:${status.toHex()}';
}

/// Constants and constraints for Service 0x19 subfunctions.
final class UdsDtcSubfunction {
  const UdsDtcSubfunction._();

  /// reportDTCByStatusMask (0x02)
  static const int reportDTCByStatusMask = 0x02;

  /// reportSupportedDTC (0x0A)
  static const int reportSupportedDTC = 0x0A;

  /// Strictly allowed subfunctions in Slice 2.
  static const Set<int> allowed = {
    reportDTCByStatusMask,
    reportSupportedDTC,
  };

  /// Returns true if [subfunction] is permitted in Slice 2.
  static bool isAllowed(int subfunction) => allowed.contains(subfunction);
}

/// Base sealed class for Service 0x19 requests.
///
/// SAFETY INVARIANT:
/// Only subclasses [UdsReportDtcByStatusMaskRequest] and
/// [UdsReportSupportedDtcRequest] can be constructed. Generic SID/subfunction
/// injection is structurally impossible.
sealed class UdsReadDtcRequest {
  const UdsReadDtcRequest();

  /// Standard ISO 14229-1 Service ID for ReadDTCInformation (0x19).
  int get serviceId => 0x19;

  /// Subfunction identifier (strictly 0x02 or 0x0A).
  int get subFunction;

  /// Encodes the request to exact raw bytes.
  List<int> encode();

  /// Canonical hex representation (e.g. "1902FF" or "190A").
  String toHexString();
}

/// Request for Service 0x19 Subfunction 0x02 (reportDTCByStatusMask).
final class UdsReportDtcByStatusMaskRequest extends UdsReadDtcRequest {
  const UdsReportDtcByStatusMaskRequest(this.mask);

  /// Status mask filter.
  final UdsDtcStatusMask mask;

  @override
  int get subFunction => UdsDtcSubfunction.reportDTCByStatusMask;

  @override
  List<int> encode() => [0x19, 0x02, mask.raw];

  @override
  String toHexString() => '1902${mask.toHex(prefix: false)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UdsReportDtcByStatusMaskRequest && other.mask == mask);

  @override
  int get hashCode => mask.hashCode;

  @override
  String toString() => 'ReportDTCByStatusMask(${mask.toHex()})';
}

/// Request for Service 0x19 Subfunction 0x0A (reportSupportedDTC).
final class UdsReportSupportedDtcRequest extends UdsReadDtcRequest {
  const UdsReportSupportedDtcRequest();

  @override
  int get subFunction => UdsDtcSubfunction.reportSupportedDTC;

  @override
  List<int> encode() => const [0x19, 0x0A];

  @override
  String toHexString() => '190A';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UdsReportSupportedDtcRequest;

  @override
  int get hashCode => 0x0A;

  @override
  String toString() => 'ReportSupportedDTC()';
}

/// Failure reasons for malformed UDS Service 0x19 responses.
enum UdsDtcMalformedReason {
  emptyResponse,
  truncated,
  invalidHex,
  wrongPositiveSid,
  wrongSubfunctionEcho,
  wrongNegativeOriginalSid,
  missingNrc,
  recordStrideMismatch,
  statusOutsideAvailabilityMask,
  statusDoesNotMatchRequestMask,
}

/// Sealed base class for UDS Service 0x19 parse outcomes.
sealed class UdsDtcParseResult {
  const UdsDtcParseResult();
}

/// Positive response for Service 0x19 (positive SID 0x59).
final class UdsDtcSuccess extends UdsDtcParseResult {
  UdsDtcSuccess({
    required this.requestedSubfunction,
    required this.availabilityMask,
    required Iterable<UdsDtcAndStatusRecord> records,
    this.requestedMask,
  }) : records = List.unmodifiable(records);

  /// Echoed subfunction (0x02 or 0x0A).
  final int requestedSubfunction;

  /// ECU-declared DTC status availability mask.
  final UdsDtcStatusAvailabilityMask availabilityMask;

  /// Ordered list of DTC records (duplicates preserved).
  final List<UdsDtcAndStatusRecord> records;

  /// Effective requested status mask, present if subfunction == 0x02.
  final UdsDtcStatusMask? requestedMask;

  @override
  String toString() =>
      'UdsDtcSuccess(subfunction=0x${requestedSubfunction.toRadixString(16).padLeft(2, '0').toUpperCase()}, '
      'avail=${availabilityMask.toHex()}, records=${records.length})';
}

/// Negative response for Service 0x19 (`7F 19 <NRC>`).
final class UdsDtcNegative extends UdsDtcParseResult {
  const UdsDtcNegative({
    required this.requestedSubfunction,
    required this.originalSid,
    required this.nrc,
  });

  /// Subfunction context of the request that failed.
  final int requestedSubfunction;

  /// Echoed original service ID (strictly 0x19 for ReadDTCInformation).
  final int originalSid;

  /// The parsed negative response code.
  final UdsNrc nrc;

  @override
  String toString() =>
      'UdsDtcNegative(subfunction=0x${requestedSubfunction.toRadixString(16).padLeft(2, '0').toUpperCase()}, '
      'origSid=0x${originalSid.toRadixString(16).padLeft(2, '0').toUpperCase()}, nrc=$nrc)';
}

/// Malformed or structurally invalid response for Service 0x19.
final class UdsDtcMalformed extends UdsDtcParseResult {
  const UdsDtcMalformed({
    required this.reason,
    required this.message,
    this.rawBytes,
    this.rawString,
  });

  /// The specific rejection reason.
  final UdsDtcMalformedReason reason;

  /// Descriptive explanation of the validation failure.
  final String message;

  /// Raw bytes received, if available.
  final List<int>? rawBytes;

  /// Raw string received, if available.
  final String? rawString;

  @override
  String toString() => 'UdsDtcMalformed($reason: $message)';
}
