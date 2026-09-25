import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/uds/uds_nrc.dart';
import 'package:torque_obd/diagnostics/uds/uds_read_codec.dart';
import 'package:torque_obd/diagnostics/uds/uds_read_types.dart';
import 'package:torque_obd/obd/pid/pid.dart';

void main() {
  group('UDS Read-Only Architecture & Security Boundary (S1-A1..A14, S1-M1..M8)', () {
    const testDid = UdsDid(0x1234);

    // -------------------------------------------------------------------------
    // S1-A2 & S1-M1: Public request builder can construct ONLY Service 0x22
    // -------------------------------------------------------------------------
    test('S1-A2 & S1-M1: request encoder constructs only Service 0x22 (ReadDataByIdentifier)', () {
      const request = UdsReadDataByIdentifierRequest(testDid);
      expect(request.serviceId, equals(0x22));
      expect(request.encode().first, equals(0x22));
      expect(request.toHexString().startsWith('22'), isTrue);

      // Verify canonical byte length is always exactly 3 bytes: 22 <hi> <lo>
      final bytes = UdsReadCodec.encodeRequestBytes(testDid);
      expect(bytes.length, equals(3));
      expect(bytes, equals([0x22, 0x12, 0x34]));
    });

    // -------------------------------------------------------------------------
    // S1-A3: DID is strictly 16-bit unsigned (0x0000..0xFFFF)
    // -------------------------------------------------------------------------
    test('S1-A3: DID value strictly enforces 16-bit boundaries', () {
      expect(const UdsDid(0x0000).value, equals(0));
      expect(const UdsDid(0xFFFF).value, equals(0xFFFF));

      expect(() => UdsDid.fromBytes(-1, 0), throwsArgumentError);
      expect(() => UdsDid.fromBytes(256, 0), throwsArgumentError);
      expect(() => UdsDid.fromBytes(0, -1), throwsArgumentError);
      expect(() => UdsDid.fromBytes(0, 256), throwsArgumentError);

      expect(() => UdsDid.parse(''), throwsFormatException);
      expect(() => UdsDid.parse('01'), throwsFormatException);
      expect(() => UdsDid.parse('01000'), throwsFormatException);
      expect(() => UdsDid.parse('010G'), throwsFormatException);
    });

    // -------------------------------------------------------------------------
    // S1-A4 & S1-M2: Positive response requires exact SID 0x62 + exact DID echo
    // -------------------------------------------------------------------------
    test('S1-A4 & S1-M2: parser rejects generic SID + 0x40 responses and wrong DID echo', () {
      // 0x10 DiagnosticSessionControl -> 0x50 positive response must be rejected
      final resSession = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x50, 0x01],
      );
      expect(resSession, isA<UdsReadMalformed>());
      expect((resSession as UdsReadMalformed).reason, equals(UdsReadMalformedReason.wrongPositiveSid));

      // 0x2F InputOutputControl -> 0x6F positive response must be rejected
      final resIo = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x6F, 0x12, 0x34, 0x03],
      );
      expect(resIo, isA<UdsReadMalformed>());
      expect((resIo as UdsReadMalformed).reason, equals(UdsReadMalformedReason.wrongPositiveSid));

      // 0x31 RoutineControl -> 0x71 positive response must be rejected
      final resRoutine = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x71, 0x01, 0x12, 0x34],
      );
      expect(resRoutine, isA<UdsReadMalformed>());
      expect((resRoutine as UdsReadMalformed).reason, equals(UdsReadMalformedReason.wrongPositiveSid));

      // Positive SID 0x62 with mismatching DID echo must be rejected
      final resWrongDid = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x56, 0x78, 0x00],
      );
      expect(resWrongDid, isA<UdsReadMalformed>());
      expect((resWrongDid as UdsReadMalformed).reason, equals(UdsReadMalformedReason.wrongDidEcho));
    });

    // -------------------------------------------------------------------------
    // S1-A5: Negative response requires 7F 22 NRC; wrong original SID is rejected
    // -------------------------------------------------------------------------
    test('S1-A5: negative parser requires original SID 0x22', () {
      // 7F 31 31 (echoing RoutineControl) must fail closed
      final resRoutineNeg = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x7F, 0x31, 0x31],
      );
      expect(resRoutineNeg, isA<UdsReadMalformed>());
      expect((resRoutineNeg as UdsReadMalformed).reason, equals(UdsReadMalformedReason.wrongNegativeOriginalSid));

      // 7F 2F 33 (echoing IOCBI) must fail closed
      final resIoNeg = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x7F, 0x2F, 0x33],
      );
      expect(resIoNeg, isA<UdsReadMalformed>());
      expect((resIoNeg as UdsReadMalformed).reason, equals(UdsReadMalformedReason.wrongNegativeOriginalSid));

      // Correct 7F 22 31 succeeds in parsing negative response
      final resCorrectNeg = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x7F, 0x22, 0x31],
      );
      expect(resCorrectNeg, isA<UdsReadNegative>());
      final neg = resCorrectNeg as UdsReadNegative;
      expect(neg.originalSid, equals(0x22));
      expect(neg.nrc.code, equals(0x31));
    });

    // -------------------------------------------------------------------------
    // S1-A6: NRC 0x21 and 0x78 are typed non-terminal states; no retry/resend
    // -------------------------------------------------------------------------
    test('S1-A6: NRC 0x21 and 0x78 are classified as typed non-terminal states', () {
      final nrc21 = UdsNrc.fromCode(0x21);
      expect(nrc21.isBusyRepeatRequest, isTrue);
      expect(nrc21.isTerminal, isFalse);

      final nrc78 = UdsNrc.fromCode(0x78);
      expect(nrc78.isResponsePending, isTrue);
      expect(nrc78.isTerminal, isFalse);

      final nrc31 = UdsNrc.fromCode(0x31);
      expect(nrc31.isTerminal, isTrue);
    });

    // -------------------------------------------------------------------------
    // S1-A7 & S1-M3: Unknown NRC remains raw/unknown and never coerces to success/unsupported
    // -------------------------------------------------------------------------
    test('S1-A7 & S1-M3: unknown NRC remains raw code and never coerces to success or unsupported', () {
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x7F, 0x22, 0xAA],
      );
      expect(res, isA<UdsReadNegative>());
      final neg = res as UdsReadNegative;
      expect(neg.nrc.code, equals(0xAA));
      expect(neg.nrc.isKnown, isFalse);
      expect(neg.nrc.isServiceNotSupported, isFalse);
      expect(neg.nrc.isSubFunctionNotSupported, isFalse);
      expect(neg.nrc.isTerminal, isTrue);
    });

    // -------------------------------------------------------------------------
    // S1-A8 & S1-M5, S1-M6: DID length enforcement and non-finite rejection
    // -------------------------------------------------------------------------
    test('S1-A8, S1-M5, S1-M6: length mismatch and non-finite decode are rejected fail-closed', () {
      const exactDefn = UdsDidDefinition<double>(
        did: testDid,
        exactByteLength: 2,
        scale: 1.0,
      );

      // S1-M5: Length bypass rejection (short 1 byte)
      final shortRes = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x12, 0x34, 0xAA],
        definition: exactDefn,
      );
      expect(shortRes, isA<UdsReadMalformed>());
      expect((shortRes as UdsReadMalformed).reason, equals(UdsReadMalformedReason.unexpectedLength));

      // S1-M5: Length bypass rejection (overlong 3 bytes)
      final longRes = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x12, 0x34, 0xAA, 0xBB, 0xCC],
        definition: exactDefn,
      );
      expect(longRes, isA<UdsReadMalformed>());
      expect((longRes as UdsReadMalformed).reason, equals(UdsReadMalformedReason.unexpectedLength));

      // S1-M6: Non-finite decoded value (NaN)
      final nanDefn = UdsDidDefinition<double>(
        did: testDid,
        exactByteLength: 2,
        customDecoder: (_) => double.nan,
      );
      final nanRes = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x12, 0x34, 0x00, 0x00],
        definition: nanDefn,
      );
      expect(nanRes, isA<UdsReadMalformed>());
      expect((nanRes as UdsReadMalformed).reason, equals(UdsReadMalformedReason.nonFiniteDecodedValue));

      // S1-M6: Non-finite decoded value (Infinity)
      final infDefn = UdsDidDefinition<double>(
        did: testDid,
        exactByteLength: 2,
        customDecoder: (_) => double.infinity,
      );
      final infRes = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x12, 0x34, 0x00, 0x00],
        definition: infDefn,
      );
      expect(infRes, isA<UdsReadMalformed>());
      expect((infRes as UdsReadMalformed).reason, equals(UdsReadMalformedReason.nonFiniteDecodedValue));
    });

    // -------------------------------------------------------------------------
    // S1-A9 & S1-M4: Missing DID definition produces typed raw/unknown result
    // -------------------------------------------------------------------------
    test('S1-A9 & S1-M4: missing definition preserves raw bytes and never invents zero or defaults', () {
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x12, 0x34, 0xCA, 0xFE, 0xBA, 0xBE],
      );
      expect(res, isA<UdsReadSuccess>());
      final success = res as UdsReadSuccess;
      expect(success.decoded, isA<UdsReadRawValue>());
      final raw = success.decoded as UdsReadRawValue;
      expect(raw.rawBytes, equals([0xCA, 0xFE, 0xBA, 0xBE]));
      expect(raw.toString(), equals('CAFEBABE'));
    });

    // -------------------------------------------------------------------------
    // S1-A13 & S1-M8: PollableServices.allowed remains strictly {'01', '02', '09', '22'}
    // -------------------------------------------------------------------------
    test('S1-A13 & S1-M8: safety allowlist is strictly {"01", "02", "09", "22"}', () {
      expect(
        PollableServices.allowed,
        equals(const {'01', '02', '09', '22'}),
        reason: 'PollableServices.allowed must not be modified or widened in Slice 1',
      );

      // Verify active, routine, programming, control services are disallowed
      for (final forbidden in ['10', '11', '14', '27', '28', '2E', '2F', '31', '34', '35', '36', '37']) {
        expect(
          PollableServices.allowed.contains(forbidden),
          isFalse,
          reason: 'Service 0x$forbidden must never be in PollableServices.allowed',
        );
        expect(
          PollableServices.isPollable('${forbidden}0000'),
          isFalse,
          reason: 'Service 0x$forbidden must not be pollable',
        );
      }
    });
  });
}
