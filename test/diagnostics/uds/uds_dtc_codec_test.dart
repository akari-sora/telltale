import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/uds/uds_dtc_codec.dart';
import 'package:torque_obd/diagnostics/uds/uds_dtc_types.dart';
import 'package:torque_obd/diagnostics/uds/uds_nrc.dart';

void main() {
  group('UdsDtcCodec request encoding', () {
    test('encodes canonical 0x02 request with mask', () {
      const mask = UdsDtcStatusMask(0xFF);
      final bytes = UdsDtcCodec.encodeReportDtcByStatusMaskBytes(mask);
      expect(bytes, equals([0x19, 0x02, 0xFF]));
      expect(UdsDtcCodec.encodeReportDtcByStatusMaskHex(mask), equals('1902FF'));
    });

    test('encodes canonical 0x0A request without payload', () {
      final bytes = UdsDtcCodec.encodeReportSupportedDtcBytes();
      expect(bytes, equals([0x19, 0x0A]));
      expect(UdsDtcCodec.encodeReportSupportedDtcHex(), equals('190A'));
    });
  });

  group('UdsDtcCodec response parsing unit tests', () {
    test('parses canonical 0x02 response with single record', () {
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        requestedMask: const UdsDtcStatusMask(0x09),
        responseBytes: [0x59, 0x02, 0xFF, 0x01, 0x02, 0x03, 0x09],
      );
      expect(res, isA<UdsDtcSuccess>());
      final success = res as UdsDtcSuccess;
      expect(success.requestedSubfunction, equals(0x02));
      expect(success.availabilityMask.raw, equals(0xFF));
      expect(success.records.length, equals(1));
      expect(success.records[0].code.value, equals(0x010203));
      expect(success.records[0].code.toHex(), equals('0x010203'));
      expect(success.records[0].status.raw, equals(0x09));
    });

    test('parses canonical 0x0A response with multiple records', () {
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x0A,
        responseBytes: [
          0x59, 0x0A, 0xFF,
          0x01, 0x02, 0x03, 0x09,
          0xA0, 0xB0, 0xC0, 0x20,
        ],
      );
      expect(res, isA<UdsDtcSuccess>());
      final success = res as UdsDtcSuccess;
      expect(success.requestedSubfunction, equals(0x0A));
      expect(success.records.length, equals(2));
      expect(success.records[0].code.toHex(), equals('0x010203'));
      expect(success.records[1].code.toHex(), equals('0xA0B0C0'));
      expect(success.records[1].status.raw, equals(0x20));
    });

    test('parses negative response 7F 19 31 (requestOutOfRange)', () {
      final res = UdsDtcCodec.parseResponseBytes(
        requestedSubfunction: 0x02,
        responseBytes: [0x7F, 0x19, 0x31],
      );
      expect(res, isA<UdsDtcNegative>());
      final neg = res as UdsDtcNegative;
      expect(neg.requestedSubfunction, equals(0x02));
      expect(neg.originalSid, equals(0x19));
      expect(neg.nrc, equals(UdsNrc.requestOutOfRange));
    });

    test('parses hex string response', () {
      final res = UdsDtcCodec.parseResponseHex(
        requestedSubfunction: 0x02,
        requestedMask: const UdsDtcStatusMask(0xFF),
        rawHex: '59 02 FF 01 02 03 09',
      );
      expect(res, isA<UdsDtcSuccess>());
      final success = res as UdsDtcSuccess;
      expect(success.records.length, equals(1));
    });

    test('rejects disallowed subfunctions at entry point', () {
      expect(
        () => UdsDtcCodec.parseResponseBytes(
          requestedSubfunction: 0x01,
          responseBytes: [0x59, 0x01, 0xFF],
        ),
        throwsArgumentError,
      );
      expect(
        () => UdsDtcCodec.parseResponseBytes(
          requestedSubfunction: 0x82,
          responseBytes: [0x59, 0x82, 0xFF],
        ),
        throwsArgumentError,
      );
    });
  });

  group('UdsDtcCodec literal vectors fixture verification', () {
    late final Map<String, dynamic> fixtureData;

    setUpAll(() {
      final fixtureFile = File('tool/uds_reference/uds_dtc_vectors.json');
      expect(fixtureFile.existsSync(), isTrue, reason: 'Vector fixture must exist');
      fixtureData = json.decode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('all 28 literal vectors pass against UdsDtcCodec', () {
      final vectors = fixtureData['vectors'] as List<dynamic>;
      expect(vectors.length, equals(28));

      for (final rawVec in vectors) {
        final vec = rawVec as Map<String, dynamic>;
        final id = vec['id'] as String;
        final category = vec['category'] as String;
        final subfunc = vec['subfunction'] as int;

        if (category == 'request_encode') {
          final expBytes = (vec['expected_request_bytes'] as List).cast<int>();
          final expHex = vec['expected_request_hex'] as String;

          if (subfunc == 0x02) {
            final mask = UdsDtcStatusMask(vec['status_mask'] as int);
            expect(
              UdsDtcCodec.encodeReportDtcByStatusMaskBytes(mask),
              equals(expBytes),
              reason: '[$id] encoded bytes mismatch',
            );
            expect(
              UdsDtcCodec.encodeReportDtcByStatusMaskHex(mask),
              equals(expHex),
              reason: '[$id] encoded hex mismatch',
            );
          } else if (subfunc == 0x0A) {
            expect(
              UdsDtcCodec.encodeReportSupportedDtcBytes(),
              equals(expBytes),
              reason: '[$id] encoded bytes mismatch',
            );
            expect(
              UdsDtcCodec.encodeReportSupportedDtcHex(),
              equals(expHex),
              reason: '[$id] encoded hex mismatch',
            );
          }
        } else if (category == 'positive_response') {
          final respBytes = (vec['response_bytes'] as List).cast<int>();
          final reqMask = vec['requested_mask'] != null
              ? UdsDtcStatusMask(vec['requested_mask'] as int)
              : null;
          final expAvail = vec['expected_availability_mask'] as int;
          final expRecords = vec['expected_records'] as List<dynamic>;

          final res = UdsDtcCodec.parseResponseBytes(
            requestedSubfunction: subfunc,
            responseBytes: respBytes,
            requestedMask: reqMask,
          );
          expect(res, isA<UdsDtcSuccess>(), reason: '[$id] expected UdsDtcSuccess');
          final success = res as UdsDtcSuccess;
          expect(success.availabilityMask.raw, equals(expAvail), reason: '[$id] avail mismatch');
          expect(success.records.length, equals(expRecords.length), reason: '[$id] record count mismatch');

          for (var i = 0; i < expRecords.length; i++) {
            final expRec = expRecords[i] as Map<String, dynamic>;
            expect(success.records[i].code.value, equals(expRec['code']), reason: '[$id] code mismatch at $i');
            expect(success.records[i].status.raw, equals(expRec['status']), reason: '[$id] status mismatch at $i');
          }
        } else if (category == 'negative_response') {
          final respBytes = (vec['response_bytes'] as List).cast<int>();
          final expOrigSid = vec['expected_original_sid'] as int;
          final expNrcCode = vec['expected_nrc_code'] as int;

          final res = UdsDtcCodec.parseResponseBytes(
            requestedSubfunction: subfunc,
            responseBytes: respBytes,
          );
          expect(res, isA<UdsDtcNegative>(), reason: '[$id] expected UdsDtcNegative');
          final neg = res as UdsDtcNegative;
          expect(neg.originalSid, equals(expOrigSid), reason: '[$id] orig SID mismatch');
          expect(neg.nrc.code, equals(expNrcCode), reason: '[$id] NRC code mismatch');
        } else if (category == 'malformed_response') {
          final respBytes = (vec['response_bytes'] as List).cast<int>();
          final expReason = vec['expected_malformed_reason'] as String;
          final reqMask = vec['requested_mask'] != null
              ? UdsDtcStatusMask(vec['requested_mask'] as int)
              : null;

          final res = UdsDtcCodec.parseResponseBytes(
            requestedSubfunction: subfunc,
            responseBytes: respBytes,
            requestedMask: reqMask,
          );
          expect(res, isA<UdsDtcMalformed>(), reason: '[$id] expected UdsDtcMalformed');
          final mal = res as UdsDtcMalformed;
          expect(mal.reason.name, equals(expReason), reason: '[$id] malformed reason mismatch');
        }
      }
    });
  });
}
