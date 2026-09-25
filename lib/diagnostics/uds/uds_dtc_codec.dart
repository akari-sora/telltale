/// Codec for ISO 14229-1 Service 0x19 (ReadDTCInformation).
///
/// Ref: Issue #13 ([WS-09][P1]), ISO 14229-1:2020.
///
/// SAFETY CONTRACT:
/// - Request encoding strictly produces subfunctions 0x02 or 0x0A.
/// - Suppress-positive-response bit (0x80) cannot be set.
/// - Positive responses require exact SID 0x59, subfunction echo, and availability mask.
/// - Negative responses require exact `7F 19 <NRC>`.
/// - DTC records must have 4-byte stride (3-byte DTC + 1-byte status).
/// - Availability mask consistency and request mask intersection are strictly enforced.
/// - Wire order and duplicate records are preserved without deduplication.
library;

import 'uds_dtc_types.dart';
import 'uds_nrc.dart';

/// Stateless codec for encoding Service 0x19 requests and parsing responses.
final class UdsDtcCodec {
  const UdsDtcCodec._();

  // ---------------------------------------------------------------------------
  // Request Encoding
  // ---------------------------------------------------------------------------

  /// Encodes a Service 0x19 0x02 request for the specified [mask].
  ///
  /// Produces exactly 3 bytes: `[0x19, 0x02, mask.raw]`.
  static List<int> encodeReportDtcByStatusMaskBytes(UdsDtcStatusMask mask) =>
      UdsReportDtcByStatusMaskRequest(mask).encode();

  /// Encodes a Service 0x19 0x02 request as a canonical uppercase hex string (e.g. "1902FF").
  static String encodeReportDtcByStatusMaskHex(UdsDtcStatusMask mask) =>
      UdsReportDtcByStatusMaskRequest(mask).toHexString();

  /// Encodes a Service 0x19 0x0A request.
  ///
  /// Produces exactly 2 bytes: `[0x19, 0x0A]`.
  static List<int> encodeReportSupportedDtcBytes() =>
      const UdsReportSupportedDtcRequest().encode();

  /// Encodes a Service 0x19 0x0A request as a canonical uppercase hex string ("190A").
  static String encodeReportSupportedDtcHex() =>
      const UdsReportSupportedDtcRequest().toHexString();

  // ---------------------------------------------------------------------------
  // Response Parsing
  // ---------------------------------------------------------------------------

  /// Parses raw byte response [responseBytes] for a previously issued [requestedSubfunction].
  ///
  /// If [requestedSubfunction] is 0x02, [requestedMask] may be provided to enforce
  /// request-mask intersection validation against returned DTC status bytes.
  static UdsDtcParseResult parseResponseBytes({
    required int requestedSubfunction,
    required List<int> responseBytes,
    UdsDtcStatusMask? requestedMask,
  }) {
    if (!UdsDtcSubfunction.isAllowed(requestedSubfunction)) {
      throw ArgumentError(
        'Disallowed subfunction 0x${requestedSubfunction.toRadixString(16).padLeft(2, '0').toUpperCase()}. '
        'Only 0x02 and 0x0A are supported.',
      );
    }

    if (responseBytes.isEmpty) {
      return const UdsDtcMalformed(
        reason: UdsDtcMalformedReason.emptyResponse,
        message: 'Empty UDS DTC response received',
        rawBytes: [],
      );
    }

    final firstByte = responseBytes[0];

    // 1. Negative Response Handling (0x7F)
    if (firstByte == 0x7F) {
      if (responseBytes.length < 2) {
        return UdsDtcMalformed(
          reason: UdsDtcMalformedReason.truncated,
          message: 'Negative response truncated before original SID byte',
          rawBytes: responseBytes,
        );
      }

      final originalSid = responseBytes[1];
      if (originalSid != 0x19) {
        return UdsDtcMalformed(
          reason: UdsDtcMalformedReason.wrongNegativeOriginalSid,
          message:
              'Negative response echoed original SID 0x${originalSid.toRadixString(16).padLeft(2, '0').toUpperCase()}, expected 0x19',
          rawBytes: responseBytes,
        );
      }

      if (responseBytes.length < 3) {
        return UdsDtcMalformed(
          reason: UdsDtcMalformedReason.missingNrc,
          message: 'Negative response truncated before NRC byte',
          rawBytes: responseBytes,
        );
      }

      final nrcByte = responseBytes[2];
      final nrc = UdsNrc.fromCode(nrcByte);
      return UdsDtcNegative(
        requestedSubfunction: requestedSubfunction,
        originalSid: originalSid,
        nrc: nrc,
      );
    }

    // 2. Positive Response Validation (0x59)
    if (firstByte != 0x59) {
      return UdsDtcMalformed(
        reason: UdsDtcMalformedReason.wrongPositiveSid,
        message:
            'Expected positive SID 0x59, got 0x${firstByte.toRadixString(16).padLeft(2, '0').toUpperCase()}',
        rawBytes: responseBytes,
      );
    }

    if (responseBytes.length < 2) {
      return UdsDtcMalformed(
        reason: UdsDtcMalformedReason.truncated,
        message: 'Positive response truncated before subfunction echo',
        rawBytes: responseBytes,
      );
    }

    final echoedSubfunction = responseBytes[1];
    if (echoedSubfunction != requestedSubfunction) {
      return UdsDtcMalformed(
        reason: UdsDtcMalformedReason.wrongSubfunctionEcho,
        message:
            'Echoed subfunction 0x${echoedSubfunction.toRadixString(16).padLeft(2, '0').toUpperCase()} '
            'does not match requested subfunction 0x${requestedSubfunction.toRadixString(16).padLeft(2, '0').toUpperCase()}',
        rawBytes: responseBytes,
      );
    }

    if (responseBytes.length < 3) {
      return UdsDtcMalformed(
        reason: UdsDtcMalformedReason.truncated,
        message:
            'Positive response truncated before DTC status availability mask',
        rawBytes: responseBytes,
      );
    }

    final availabilityMaskByte = responseBytes[2];
    final availabilityMask =
        UdsDtcStatusAvailabilityMask(availabilityMaskByte);
    final payload = responseBytes.sublist(3);

    // 3. 4-byte Stride Verification (3-byte DTC + 1-byte status)
    if (payload.length % 4 != 0) {
      return UdsDtcMalformed(
        reason: UdsDtcMalformedReason.recordStrideMismatch,
        message:
            'DTC records payload length (${payload.length} bytes) is not a multiple of 4 bytes',
        rawBytes: responseBytes,
      );
    }

    // 4. Record Parsing and Integrity Checks
    final records = <UdsDtcAndStatusRecord>[];
    final numRecords = payload.length ~/ 4;

    for (var i = 0; i < numRecords; i++) {
      final offset = i * 4;
      final b0 = payload[offset];
      final b1 = payload[offset + 1];
      final b2 = payload[offset + 2];
      final statusByte = payload[offset + 3];

      final dtcValue = (b0 << 16) | (b1 << 8) | b2;

      // Check: statusOfDTC must not set bits declared unavailable by ECU
      if ((statusByte & ~availabilityMaskByte) != 0) {
        final invalidBits = statusByte & ~availabilityMaskByte;
        return UdsDtcMalformed(
          reason: UdsDtcMalformedReason.statusOutsideAvailabilityMask,
          message:
              'DTC 0x${dtcValue.toRadixString(16).padLeft(6, '0').toUpperCase()} '
              'status 0x${statusByte.toRadixString(16).padLeft(2, '0').toUpperCase()} '
              'contains unsupported bits (0x${invalidBits.toRadixString(16).padLeft(2, '0').toUpperCase()}) '
              'outside availability mask 0x${availabilityMaskByte.toRadixString(16).padLeft(2, '0').toUpperCase()}',
          rawBytes: responseBytes,
        );
      }

      // Check: For 0x02, record must intersect the effective requested status mask
      if (requestedSubfunction == UdsDtcSubfunction.reportDTCByStatusMask &&
          requestedMask != null) {
        final effectiveMask = requestedMask.raw & availabilityMaskByte;
        if (effectiveMask != 0 && (statusByte & effectiveMask) == 0) {
          return UdsDtcMalformed(
            reason: UdsDtcMalformedReason.statusDoesNotMatchRequestMask,
            message:
                'DTC 0x${dtcValue.toRadixString(16).padLeft(6, '0').toUpperCase()} '
                'status 0x${statusByte.toRadixString(16).padLeft(2, '0').toUpperCase()} '
                'does not intersect effective requested status mask 0x${effectiveMask.toRadixString(16).padLeft(2, '0').toUpperCase()}',
            rawBytes: responseBytes,
          );
        }
      }

      records.add(
        UdsDtcAndStatusRecord(
          code: UdsDtcCode24(dtcValue),
          status: UdsDtcStatus(statusByte),
        ),
      );
    }

    return UdsDtcSuccess(
      requestedSubfunction: requestedSubfunction,
      availabilityMask: availabilityMask,
      records: records,
      requestedMask: requestedMask,
    );
  }

  /// Parses hex string response [rawHex] for [requestedSubfunction].
  static UdsDtcParseResult parseResponseHex({
    required int requestedSubfunction,
    required String rawHex,
    UdsDtcStatusMask? requestedMask,
  }) {
    final bytes = _parseHex(rawHex);
    if (bytes == null) {
      return UdsDtcMalformed(
        reason: UdsDtcMalformedReason.invalidHex,
        message: 'Invalid hex representation: "$rawHex"',
        rawString: rawHex,
      );
    }
    return parseResponseBytes(
      requestedSubfunction: requestedSubfunction,
      responseBytes: bytes,
      requestedMask: requestedMask,
    );
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  static List<int>? _parseHex(String raw) {
    final cleaned = raw.replaceAll(' ', '').trim();
    if (cleaned.isEmpty) return const <int>[];
    if (cleaned.length.isOdd) return null;
    if (!RegExp(r'^[0-9a-fA-F]*$').hasMatch(cleaned)) return null;
    final bytes = <int>[];
    for (var i = 0; i < cleaned.length; i += 2) {
      final b = int.tryParse(cleaned.substring(i, i + 2), radix: 16);
      if (b == null) return null;
      bytes.add(b);
    }
    return bytes;
  }
}
