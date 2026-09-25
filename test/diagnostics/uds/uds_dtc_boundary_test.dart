import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/uds/uds_dtc_codec.dart';
import 'package:torque_obd/diagnostics/uds/uds_dtc_types.dart';

void main() {
  group('UdsDtc boundary & malformed response handling', () {
    test('rejects empty response payload', () {
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        responseBytes: [],
      );
      expect(res, isA<UdsDtcMalformed>());
      expect((res as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.emptyResponse));
    });

    test('rejects truncated negative responses', () {
      final res1 = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        responseBytes: [0x7F],
      );
      expect(res1, isA<UdsDtcMalformed>());
      expect((res1 as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.truncated));

      final res2 = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        responseBytes: [0x7F, 0x19],
      );
      expect(res2, isA<UdsDtcMalformed>());
      expect((res2 as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.missingNrc));
    });

    test('rejects negative response with wrong original SID', () {
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        responseBytes: [0x7F, 0x22, 0x31],
      );
      expect(res, isA<UdsDtcMalformed>());
      expect((res as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.wrongNegativeOriginalSid));
    });

    test('rejects wrong positive SID', () {
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        responseBytes: [0x62, 0x02, 0xFF],
      );
      expect(res, isA<UdsDtcMalformed>());
      expect((res as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.wrongPositiveSid));
    });

    test('rejects truncated positive responses before availability mask', () {
      final res1 = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        responseBytes: [0x59],
      );
      expect(res1, isA<UdsDtcMalformed>());
      expect((res1 as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.truncated));

      final res2 = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        responseBytes: [0x59, 0x02],
      );
      expect(res2, isA<UdsDtcMalformed>());
      expect((res2 as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.truncated));
    });

    test('rejects wrong subfunction echo', () {
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        responseBytes: [0x59, 0x0A, 0xFF],
      );
      expect(res, isA<UdsDtcMalformed>());
      expect((res as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.wrongSubfunctionEcho));
    });

    test('rejects incomplete record strides (not multiple of 4 bytes)', () {
      for (var extra = 1; extra <= 3; extra++) {
        final payload = [0x59, 0x02, 0xFF, 0x01, 0x02, 0x03, 0x09];
        for (var i = 0; i < extra; i++) {
          payload.add(0xAA);
        }
        final res = UdsDtcCodec.parseResponseBytes(
          requestedSubfunction: 0x02,
          requestedMask: const UdsDtcStatusMask(0xFF),
          responseBytes: payload,
        );
        expect(res, isA<UdsDtcMalformed>(), reason: 'extra $extra bytes');
        expect((res as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.recordStrideMismatch));
      }
    });

    test('rejects DTC status setting bits outside availability mask', () {
      // Availability = 0x0F (bits 0..3 supported), status = 0x11 (bit 4 set)
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        requestedMask: const UdsDtcStatusMask(0xFF),
        responseBytes: [0x59, 0x02, 0x0F, 0x01, 0x02, 0x03, 0x11],
      );
      expect(res, isA<UdsDtcMalformed>());
      expect((res as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.statusOutsideAvailabilityMask));
    });

    test('rejects 0x02 record that does not intersect effective requested mask', () {
      // Requested mask = 0x04 (pending), availability = 0xFF, returned status = 0x08 (confirmed only)
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        requestedMask: const UdsDtcStatusMask(0x04),
        responseBytes: [0x59, 0x02, 0xFF, 0x01, 0x02, 0x03, 0x08],
      );
      expect(res, isA<UdsDtcMalformed>());
      expect((res as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.statusDoesNotMatchRequestMask));
    });

    test('accepts empty response when effective mask is zero', () {
      // Requested mask = 0x80, availability = 0x7F -> effectiveMask == 0
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        requestedMask: const UdsDtcStatusMask(0x80),
        responseBytes: [0x59, 0x02, 0x7F],
      );
      expect(res, isA<UdsDtcSuccess>());
      expect((res as UdsDtcSuccess).records, isEmpty);
    });

    test('rejects invalid hex strings in parseResponseHex', () {
      final resOdd = UdsDtcCodec.parseResponseHex(
        requestedSubfunction: 0x02,
        rawHex: '59 02 F',
      );
      expect(resOdd, isA<UdsDtcMalformed>());
      expect((resOdd as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.invalidHex));

      final resNonHex = UdsDtcCodec.parseResponseHex(
        requestedSubfunction: 0x02,
        rawHex: '59 02 GG',
      );
      expect(resNonHex, isA<UdsDtcMalformed>());
      expect((resNonHex as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.invalidHex));
    });
  });

  group('Mutation Controls S2-M1..M10', () {
    test('S2-M1: arbitrary subfunction widening is prevented', () {
      expect(
        () => UdsDtcCodec.parseResponseBytes(
          requestedSubfunction: 0x01,
          responseBytes: [0x59, 0x01, 0x00],
        ),
        throwsArgumentError,
      );
      expect(
        () => UdsDtcCodec.parseResponseBytes(
          requestedSubfunction: 0x03,
          responseBytes: [0x59, 0x03, 0x00],
        ),
        throwsArgumentError,
      );
      expect(
        () => UdsDtcCodec.parseResponseBytes(
          requestedSubfunction: 0x15,
          responseBytes: [0x59, 0x15, 0x00],
        ),
        throwsArgumentError,
      );
    });

    test('S2-M2: suppress-positive bit cannot be parsed or produced', () {
      expect(
        () => UdsDtcCodec.parseResponseBytes(
          requestedSubfunction: 0x82,
          responseBytes: [0x59, 0x82, 0xFF],
        ),
        throwsArgumentError,
      );
      expect(
        () => UdsDtcCodec.parseResponseBytes(
          requestedSubfunction: 0x8A,
          responseBytes: [0x59, 0x8A, 0xFF],
        ),
        throwsArgumentError,
      );
    });

    test('S2-M3: generic positive SID acceptance is rejected', () {
      // Trying arbitrary SID like 0x62 or 0x58
      final res1 = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        responseBytes: [0x62, 0x02, 0xFF],
      );
      expect(res1, isA<UdsDtcMalformed>());
      expect((res1 as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.wrongPositiveSid));

      final res2 = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        responseBytes: [0x58, 0x02, 0xFF],
      );
      expect(res2, isA<UdsDtcMalformed>());
      expect((res2 as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.wrongPositiveSid));
    });

    test('S2-M4: subfunction echo bypass is rejected', () {
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        responseBytes: [0x59, 0x0A, 0xFF],
      );
      expect(res, isA<UdsDtcMalformed>());
      expect((res as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.wrongSubfunctionEcho));
    });

    test('S2-M5: record stride bypass is rejected', () {
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x0A,
        responseBytes: [0x59, 0x0A, 0xFF, 0x01, 0x02, 0x03], // 3 bytes instead of 4
      );
      expect(res, isA<UdsDtcMalformed>());
      expect((res as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.recordStrideMismatch));
    });

    test('S2-M6: DTC width is strictly 24-bit (not truncated to 16-bit)', () {
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x0A,
        responseBytes: [0x59, 0x0A, 0xFF, 0xA1, 0xB2, 0xC3, 0x01],
      );
      expect(res, isA<UdsDtcSuccess>());
      final record = (res as UdsDtcSuccess).records.first;
      expect(record.code.value, equals(0xA1B2C3));
      expect(record.code.hiByte, equals(0xA1));
      expect(record.code.midByte, equals(0xB2));
      expect(record.code.loByte, equals(0xC3));
      expect(record.code.toHex(), equals('0xA1B2C3'));
    });

    test('S2-M7: availability fail-open is rejected', () {
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x0A,
        responseBytes: [0x59, 0x0A, 0x01, 0x00, 0x00, 0x01, 0x02], // bit 1 set but avail only has bit 0
      );
      expect(res, isA<UdsDtcMalformed>());
      expect((res as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.statusOutsideAvailabilityMask));
    });

    test('S2-M8: request-mask fail-open is rejected', () {
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        requestedMask: const UdsDtcStatusMask(0x01), // testFailed
        responseBytes: [0x59, 0x02, 0xFF, 0x00, 0x00, 0x01, 0x08], // confirmed only (no bit 0)
      );
      expect(res, isA<UdsDtcMalformed>());
      expect((res as UdsDtcMalformed).reason, equals(UdsDtcMalformedReason.statusDoesNotMatchRequestMask));
    });

    test('S2-M9: duplicate collapse is rejected (wire order & duplicates preserved)', () {
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x0A,
        responseBytes: [
          0x59, 0x0A, 0xFF,
          0x01, 0x02, 0x03, 0x09,
          0x01, 0x02, 0x03, 0x09,
        ],
      );
      expect(res, isA<UdsDtcSuccess>());
      final records = (res as UdsDtcSuccess).records;
      expect(records.length, equals(2));
      expect(records[0].code.value, equals(0x010203));
      expect(records[1].code.value, equals(0x010203));
    });

    test('S2-M10: UdsDtcAndStatusRecord does not expose or infer J1979 DtcKind', () {
      const record = UdsDtcAndStatusRecord(
        code: UdsDtcCode24(0x010203),
        status: UdsDtcStatus(0x89),
      );
      // Status bits: warningIndicatorRequested (bit 7), confirmedDTC (bit 3), testFailed (bit 0)
      expect(record.status.warningIndicatorRequested, isTrue);
      expect(record.status.confirmedDTC, isTrue);
      expect(record.status.testFailed, isTrue);
      // Confirms type isolation: code is strictly UdsDtcCode24, status is strictly UdsDtcStatus
      expect(record.code, isA<UdsDtcCode24>());
      expect(record.status, isA<UdsDtcStatus>());
    });
  });
}
