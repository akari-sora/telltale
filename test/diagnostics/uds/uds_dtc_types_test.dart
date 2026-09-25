import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/uds/uds_dtc_types.dart';
import 'package:torque_obd/diagnostics/uds/uds_nrc.dart';

void main() {
  group('UdsDtcCode24', () {
    test('constructs valid 24-bit DTC codes', () {
      const minDtc = UdsDtcCode24(0x000000);
      expect(minDtc.value, equals(0));
      expect(minDtc.hiByte, equals(0));
      expect(minDtc.midByte, equals(0));
      expect(minDtc.loByte, equals(0));
      expect(minDtc.bytes, equals([0, 0, 0]));
      expect(minDtc.toHex(), equals('0x000000'));
      expect(minDtc.toHex(prefix: false), equals('000000'));

      const maxDtc = UdsDtcCode24(0xFFFFFF);
      expect(maxDtc.value, equals(0xFFFFFF));
      expect(maxDtc.hiByte, equals(0xFF));
      expect(maxDtc.midByte, equals(0xFF));
      expect(maxDtc.loByte, equals(0xFF));
      expect(maxDtc.bytes, equals([0xFF, 0xFF, 0xFF]));
      expect(maxDtc.toHex(), equals('0xFFFFFF'));
      expect(maxDtc.toHex(prefix: false), equals('FFFFFF'));

      const midDtc = UdsDtcCode24(0x010203);
      expect(midDtc.hiByte, equals(0x01));
      expect(midDtc.midByte, equals(0x02));
      expect(midDtc.loByte, equals(0x03));
      expect(midDtc.bytes, equals([0x01, 0x02, 0x03]));
      expect(midDtc.toHex(), equals('0x010203'));
      expect(midDtc.toHex(prefix: false), equals('010203'));
    });

    test('rejects out of range values via assertion', () {
      expect(() => UdsDtcCode24(-1), throwsA(isA<AssertionError>()));
      expect(() => UdsDtcCode24(0x1000000), throwsA(isA<AssertionError>()));
    });

    test('fromBytes creates correct codes and validates ranges', () {
      final code = UdsDtcCode24.fromBytes(0x12, 0x34, 0x56);
      expect(code.value, equals(0x123456));

      expect(() => UdsDtcCode24.fromBytes(-1, 0, 0), throwsArgumentError);
      expect(() => UdsDtcCode24.fromBytes(0, 256, 0), throwsArgumentError);
      expect(() => UdsDtcCode24.fromBytes(0, 0, -1), throwsArgumentError);
      expect(() => UdsDtcCode24.fromBytes(0, 0, 256), throwsArgumentError);
    });

    test('parse handles canonical and prefixed 6-hex strings', () {
      expect(UdsDtcCode24.parse('010203'), equals(const UdsDtcCode24(0x010203)));
      expect(UdsDtcCode24.parse('0x010203'), equals(const UdsDtcCode24(0x010203)));
      expect(UdsDtcCode24.parse('0XABCDEF'), equals(const UdsDtcCode24(0xABCDEF)));

      expect(() => UdsDtcCode24.parse('01020'), throwsFormatException);
      expect(() => UdsDtcCode24.parse('01020304'), throwsFormatException);
      expect(() => UdsDtcCode24.parse('GGGGGG'), throwsFormatException);
    });

    test('equality, hashCode, and compareTo behave correctly', () {
      const a = UdsDtcCode24(0x010203);
      const b = UdsDtcCode24(0x010203);
      const c = UdsDtcCode24(0x010204);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);

      expect(a.compareTo(b), equals(0));
      expect(a.compareTo(c), isNegative);
      expect(c.compareTo(a), isPositive);
    });
  });

  group('UdsDtcStatusMask', () {
    test('extracts all 8 named status bits accurately', () {
      for (var bit = 0; bit < 8; bit++) {
        final mask = UdsDtcStatusMask(1 << bit);
        expect(mask.testFailed, equals(bit == 0));
        expect(mask.testFailedThisOperationCycle, equals(bit == 1));
        expect(mask.pendingDTC, equals(bit == 2));
        expect(mask.confirmedDTC, equals(bit == 3));
        expect(mask.testNotCompletedSinceLastClear, equals(bit == 4));
        expect(mask.testFailedSinceLastClear, equals(bit == 5));
        expect(mask.testNotCompletedThisOperationCycle, equals(bit == 6));
        expect(mask.warningIndicatorRequested, equals(bit == 7));
      }
    });

    test('validates 8-bit bounds', () {
      expect(() => UdsDtcStatusMask(-1), throwsA(isA<AssertionError>()));
      expect(() => UdsDtcStatusMask(256), throwsA(isA<AssertionError>()));
    });

    test('hex formatting and equality', () {
      const mask = UdsDtcStatusMask(0x09);
      expect(mask.toHex(), equals('0x09'));
      expect(mask.toHex(prefix: false), equals('09'));
      expect(mask, equals(const UdsDtcStatusMask(0x09)));
      expect(mask.hashCode, equals(const UdsDtcStatusMask(0x09).hashCode));
    });
  });

  group('UdsDtcStatusAvailabilityMask', () {
    test('extracts all 8 named availability bits', () {
      const avail = UdsDtcStatusAvailabilityMask(0x29);
      expect(avail.testFailed, isTrue); // bit 0
      expect(avail.testFailedThisOperationCycle, isFalse); // bit 1
      expect(avail.pendingDTC, isFalse); // bit 2
      expect(avail.confirmedDTC, isTrue); // bit 3
      expect(avail.testNotCompletedSinceLastClear, isFalse); // bit 4
      expect(avail.testFailedSinceLastClear, isTrue); // bit 5
      expect(avail.testNotCompletedThisOperationCycle, isFalse); // bit 6
      expect(avail.warningIndicatorRequested, isFalse); // bit 7
      expect(avail.toHex(), equals('0x29'));
    });
  });

  group('UdsDtcStatus', () {
    test('extracts all 8 named DTC status bits', () {
      const status = UdsDtcStatus(0x88);
      expect(status.confirmedDTC, isTrue);
      expect(status.warningIndicatorRequested, isTrue);
      expect(status.pendingDTC, isFalse);
      expect(status.testFailed, isFalse);
      expect(status.toHex(), equals('0x88'));
    });
  });

  group('UdsDtcAndStatusRecord', () {
    test('holds code and status with value equality', () {
      const rec1 = UdsDtcAndStatusRecord(
        code: UdsDtcCode24(0x010203),
        status: UdsDtcStatus(0x09),
      );
      const rec2 = UdsDtcAndStatusRecord(
        code: UdsDtcCode24(0x010203),
        status: UdsDtcStatus(0x09),
      );
      const rec3 = UdsDtcAndStatusRecord(
        code: UdsDtcCode24(0x010203),
        status: UdsDtcStatus(0x08),
      );

      expect(rec1, equals(rec2));
      expect(rec1.hashCode, equals(rec2.hashCode));
      expect(rec1 == rec3, isFalse);
      expect(rec1.toString(), equals('0x010203:0x09'));
    });
  });

  group('UdsDtcSubfunction', () {
    test('strictly enforces allowed set {0x02, 0x0A}', () {
      expect(UdsDtcSubfunction.allowed, equals({0x02, 0x0A}));
      expect(UdsDtcSubfunction.isAllowed(0x02), isTrue);
      expect(UdsDtcSubfunction.isAllowed(0x0A), isTrue);

      expect(UdsDtcSubfunction.isAllowed(0x01), isFalse);
      expect(UdsDtcSubfunction.isAllowed(0x03), isFalse);
      expect(UdsDtcSubfunction.isAllowed(0x04), isFalse);
      expect(UdsDtcSubfunction.isAllowed(0x15), isFalse);
      expect(UdsDtcSubfunction.isAllowed(0x82), isFalse);
      expect(UdsDtcSubfunction.isAllowed(0x8A), isFalse);
    });
  });

  group('UdsReadDtcRequest builders', () {
    test('UdsReportDtcByStatusMaskRequest produces exact 3-byte payload', () {
      const req = UdsReportDtcByStatusMaskRequest(UdsDtcStatusMask(0xFF));
      expect(req.serviceId, equals(0x19));
      expect(req.subFunction, equals(0x02));
      expect(req.encode(), equals([0x19, 0x02, 0xFF]));
      expect(req.toHexString(), equals('1902FF'));
      expect(req.toString(), contains('0xFF'));
    });

    test('UdsReportSupportedDtcRequest produces exact 2-byte payload', () {
      const req = UdsReportSupportedDtcRequest();
      expect(req.serviceId, equals(0x19));
      expect(req.subFunction, equals(0x0A));
      expect(req.encode(), equals([0x19, 0x0A]));
      expect(req.toHexString(), equals('190A'));
      expect(req.toString(), equals('ReportSupportedDTC()'));
    });
  });

  group('UdsDtcParseResult hierarchy', () {
    test('UdsDtcSuccess preserves order and duplicate records', () {
      const rec = UdsDtcAndStatusRecord(
        code: UdsDtcCode24(0x010203),
        status: UdsDtcStatus(0x09),
      );
      final success = UdsDtcSuccess(
        requestedSubfunction: 0x02,
        availabilityMask: const UdsDtcStatusAvailabilityMask(0xFF),
        records: [rec, rec],
        requestedMask: const UdsDtcStatusMask(0x09),
      );
      expect(success.requestedSubfunction, equals(0x02));
      expect(success.availabilityMask.raw, equals(0xFF));
      expect(success.records.length, equals(2));
      expect(identical(success.records[0], success.records[1]), isTrue);
    });

    test('UdsDtcNegative carries context and NRC', () {
      const neg = UdsDtcNegative(
        requestedSubfunction: 0x02,
        originalSid: 0x19,
        nrc: UdsNrc.requestOutOfRange,
      );
      expect(neg.requestedSubfunction, equals(0x02));
      expect(neg.originalSid, equals(0x19));
      expect(neg.nrc, equals(UdsNrc.requestOutOfRange));
      expect(neg.toString(), contains('requestOutOfRange'));
    });

    test('UdsDtcMalformed carries reason and message', () {
      const mal = UdsDtcMalformed(
        reason: UdsDtcMalformedReason.wrongPositiveSid,
        message: 'Wrong SID',
        rawBytes: [0x62],
      );
      expect(mal.reason, equals(UdsDtcMalformedReason.wrongPositiveSid));
      expect(mal.message, equals('Wrong SID'));
      expect(mal.rawBytes, equals([0x62]));
    });
  });
}
