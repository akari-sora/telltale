/// Codec for ISO 14229-1 Service 0x22 (ReadDataByIdentifier).
///
/// Ref: Issue #13 ([WS-09][P1]), ISO 14229-1:2020.
///
/// SAFETY CONTRACT:
/// - Encoding is strictly constrained to Service 0x22; arbitrary SIDs cannot be produced.
/// - Positive response strictly requires SID 0x62 and exact 16-bit DID echo.
/// - Negative response strictly requires `7F 22 <NRC>`; non-matching original SIDs fail closed.
/// - Non-finite decoded values (NaN, Infinity) are rejected as malformed.
/// - Missing definitions fall back to raw byte preservation without aborting sibling decodes.
library;

import 'uds_nrc.dart';
import 'uds_read_types.dart';

/// Stateless codec for encoding Service 0x22 requests and parsing responses.
final class UdsReadCodec {
  const UdsReadCodec._();

  // ---------------------------------------------------------------------------
  // Request Encoding
  // ---------------------------------------------------------------------------

  /// Encodes a Service 0x22 request for the specified 16-bit [did].
  ///
  /// Always produces exactly 3 bytes: `[0x22, did.hiByte, did.loByte]`.
  static List<int> encodeRequestBytes(UdsDid did) =>
      UdsReadDataByIdentifierRequest(did).encode();

  /// Encodes a Service 0x22 request as a canonical uppercase hex string (e.g. "220100").
  static String encodeRequestHex(UdsDid did) =>
      UdsReadDataByIdentifierRequest(did).toHexString();

  // ---------------------------------------------------------------------------
  // Response Parsing
  // ---------------------------------------------------------------------------

  /// Parses raw byte response [responseBytes] for a previously issued [requestedDid].
  ///
  /// If a [definition] is provided, validates exact/min/max data record lengths
  /// and applies typed decoding.
  static UdsReadParseResult parseResponseBytes({
    required UdsDid requestedDid,
    required List<int> responseBytes,
    UdsDidDefinition<Object?>? definition,
  }) {
    if (responseBytes.isEmpty) {
      return const UdsReadMalformed(
        reason: UdsReadMalformedReason.emptyResponse,
        message: 'Empty UDS response received',
        rawBytes: [],
      );
    }

    final firstByte = responseBytes[0];

    // 1. Negative Response Handling (0x7F)
    if (firstByte == 0x7F) {
      if (responseBytes.length < 2) {
        return UdsReadMalformed(
          reason: UdsReadMalformedReason.truncated,
          message: 'Negative response truncated before original SID byte',
          rawBytes: responseBytes,
        );
      }

      final originalSid = responseBytes[1];
      if (originalSid != 0x22) {
        return UdsReadMalformed(
          reason: UdsReadMalformedReason.wrongNegativeOriginalSid,
          message:
              'Negative response echoed original SID 0x${originalSid.toRadixString(16).padLeft(2, '0').toUpperCase()}, expected 0x22',
          rawBytes: responseBytes,
        );
      }

      if (responseBytes.length < 3) {
        return UdsReadMalformed(
          reason: UdsReadMalformedReason.missingNrc,
          message: 'Negative response truncated before NRC byte',
          rawBytes: responseBytes,
        );
      }

      final nrcByte = responseBytes[2];
      final nrc = UdsNrc.fromCode(nrcByte);
      return UdsReadNegative(
        did: requestedDid,
        originalSid: originalSid,
        nrc: nrc,
      );
    }

    // 2. Positive Response Validation (0x62)
    if (firstByte != 0x62) {
      return UdsReadMalformed(
        reason: UdsReadMalformedReason.wrongPositiveSid,
        message:
            'Expected positive SID 0x62, got 0x${firstByte.toRadixString(16).padLeft(2, '0').toUpperCase()}',
        rawBytes: responseBytes,
      );
    }

    if (responseBytes.length < 3) {
      return UdsReadMalformed(
        reason: UdsReadMalformedReason.truncated,
        message:
            'Positive response truncated before full 16-bit DID echo: got ${responseBytes.length} bytes',
        rawBytes: responseBytes,
      );
    }

    final echoedDidValue = (responseBytes[1] << 8) | responseBytes[2];
    if (echoedDidValue != requestedDid.value) {
      final echoedHex =
          '0x${echoedDidValue.toRadixString(16).padLeft(4, '0').toUpperCase()}';
      return UdsReadMalformed(
        reason: UdsReadMalformedReason.wrongDidEcho,
        message:
            'Echoed DID $echoedHex does not match requested DID ${requestedDid.toHex()}',
        rawBytes: responseBytes,
      );
    }

    final dataRecord = responseBytes.sublist(3);

    // 3. Length Constraint Verification
    if (definition != null && !definition.isValidLength(dataRecord.length)) {
      return UdsReadMalformed(
        reason: UdsReadMalformedReason.unexpectedLength,
        message:
            'Data record length (${dataRecord.length} bytes) does not satisfy definition constraints for ${requestedDid.toHex()}',
        rawBytes: responseBytes,
      );
    }

    // 4. Data Record Decoding
    final UdsReadDecodeResult decoded;
    if (definition != null) {
      if (definition.customDecoder != null) {
        try {
          final val = definition.customDecoder!(dataRecord);
          if (val is num && !val.isFinite) {
            return UdsReadMalformed(
              reason: UdsReadMalformedReason.nonFiniteDecodedValue,
              message: 'Decoded numeric value is non-finite: $val',
              rawBytes: responseBytes,
            );
          }
          decoded = UdsReadDecodedValue(
            did: requestedDid,
            value: val,
            unit: definition.unit,
            rawBytes: dataRecord,
          );
        } catch (e) {
          return UdsReadMalformed(
            reason: UdsReadMalformedReason.decodeError,
            message: 'Custom decoder error: $e',
            rawBytes: responseBytes,
          );
        }
      } else if (definition.scale != null || definition.offset != null) {
        // Built-in integer scaling decoder
        if (dataRecord.length == 1) {
          final rawInt = dataRecord[0];
          final scale = definition.scale ?? 1.0;
          final offset = definition.offset ?? 0.0;
          final scaledVal = (rawInt * scale) + offset;
          if (!scaledVal.isFinite) {
            return UdsReadMalformed(
              reason: UdsReadMalformedReason.nonFiniteDecodedValue,
              message: 'Decoded numeric value is non-finite: $scaledVal',
              rawBytes: responseBytes,
            );
          }
          decoded = UdsReadDecodedValue<double>(
            did: requestedDid,
            value: scaledVal,
            unit: definition.unit,
            rawBytes: dataRecord,
          );
        } else if (dataRecord.length == 2) {
          final rawInt = definition.byteOrder == UdsDidByteOrder.bigEndian
              ? ((dataRecord[0] << 8) | dataRecord[1])
              : ((dataRecord[1] << 8) | dataRecord[0]);
          final scale = definition.scale ?? 1.0;
          final offset = definition.offset ?? 0.0;
          final scaledVal = (rawInt * scale) + offset;
          if (!scaledVal.isFinite) {
            return UdsReadMalformed(
              reason: UdsReadMalformedReason.nonFiniteDecodedValue,
              message: 'Decoded numeric value is non-finite: $scaledVal',
              rawBytes: responseBytes,
            );
          }
          decoded = UdsReadDecodedValue<double>(
            did: requestedDid,
            value: scaledVal,
            unit: definition.unit,
            rawBytes: dataRecord,
          );
        } else {
          decoded = UdsReadRawValue(
            did: requestedDid,
            rawBytes: dataRecord,
          );
        }
      } else {
        decoded = UdsReadRawValue(
          did: requestedDid,
          rawBytes: dataRecord,
        );
      }
    } else {
      decoded = UdsReadRawValue(
        did: requestedDid,
        rawBytes: dataRecord,
      );
    }

    return UdsReadSuccess(
      did: requestedDid,
      dataRecord: dataRecord,
      decoded: decoded,
    );
  }

  /// Parses hex string response [rawHex] for [requestedDid].
  static UdsReadParseResult parseResponseHex({
    required UdsDid requestedDid,
    required String rawHex,
    UdsDidDefinition<Object?>? definition,
  }) {
    final bytes = _parseHex(rawHex);
    if (bytes == null) {
      return UdsReadMalformed(
        reason: UdsReadMalformedReason.invalidHex,
        message: 'Invalid hex representation: "$rawHex"',
        rawString: rawHex,
      );
    }
    return parseResponseBytes(
      requestedDid: requestedDid,
      responseBytes: bytes,
      definition: definition,
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
