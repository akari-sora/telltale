import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/uds/uds_nrc.dart';
import 'package:torque_obd/diagnostics/uds/uds_read_codec.dart';
import 'package:torque_obd/diagnostics/uds/uds_read_types.dart';

void main() {
  group('UdsReadCodec request encoding', () {
    test('encodes canonical 16-bit DID into exact 3-byte payload', () {
      const did = UdsDid(0x0100);
      final bytes = UdsReadCodec.encodeRequestBytes(did);
      expect(bytes, equals([0x22, 0x01, 0x00]));
      expect(UdsReadCodec.encodeRequestHex(did), equals('220100'));
    });

    test('encodes boundary 0x0000 and 0xFFFF DIDs correctly', () {
      const minDid = UdsDid(0x0000);
      expect(UdsReadCodec.encodeRequestBytes(minDid), equals([0x22, 0x00, 0x00]));
      expect(UdsReadCodec.encodeRequestHex(minDid), equals('220000'));

      const maxDid = UdsDid(0xFFFF);
      expect(UdsReadCodec.encodeRequestBytes(maxDid), equals([0x22, 0xFF, 0xFF]));
      expect(UdsReadCodec.encodeRequestHex(maxDid), equals('22FFFF'));
    });

    test('request object properties are consistent', () {
      const did = UdsDid(0xF190);
      const req = UdsReadDataByIdentifierRequest(did);
      expect(req.serviceId, equals(0x22));
      expect(req.did, equals(did));
      expect(req.encode(), equals([0x22, 0xF1, 0x90]));
      expect(req.toHexString(), equals('22F190'));
      expect(req.toString(), contains('F190'));
    });
  });

  group('UdsReadCodec response parsing unit tests', () {
    const testDid = UdsDid(0x0100);

    test('parses canonical positive response with exact DID echo', () {
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x01, 0x00, 0x12, 0x34],
      );
      expect(res, isA<UdsReadSuccess>());
      final success = res as UdsReadSuccess;
      expect(success.did, equals(testDid));
      expect(success.dataRecord, equals([0x12, 0x34]));
      expect(success.decoded, isA<UdsReadRawValue>());
      expect(success.decoded.rawBytes, equals([0x12, 0x34]));
    });

    test('parses negative response 7F 22 31 (requestOutOfRange)', () {
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x7F, 0x22, 0x31],
      );
      expect(res, isA<UdsReadNegative>());
      final neg = res as UdsReadNegative;
      expect(neg.did, equals(testDid));
      expect(neg.originalSid, equals(0x22));
      expect(neg.nrc, equals(UdsNrc.requestOutOfRange));
      expect(neg.nrc.isRequestOutOfRange, isTrue);
      expect(neg.nrc.isTerminal, isTrue);
    });

    test('parses negative response 7F 22 21 (busyRepeatRequest)', () {
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x7F, 0x22, 0x21],
      );
      expect(res, isA<UdsReadNegative>());
      final neg = res as UdsReadNegative;
      expect(neg.nrc.isBusyRepeatRequest, isTrue);
      expect(neg.nrc.isTerminal, isFalse);
    });

    test('parses negative response 7F 22 78 (responsePending)', () {
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x7F, 0x22, 0x78],
      );
      expect(res, isA<UdsReadNegative>());
      final neg = res as UdsReadNegative;
      expect(neg.nrc.isResponsePending, isTrue);
      expect(neg.nrc.isTerminal, isFalse);
    });

    test('preserves unknown NRC in negative response without coercion', () {
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x7F, 0x22, 0x99],
      );
      expect(res, isA<UdsReadNegative>());
      final neg = res as UdsReadNegative;
      expect(neg.nrc.code, equals(0x99));
      expect(neg.nrc.isKnown, isFalse);
      expect(neg.nrc.isTerminal, isTrue);
    });

    test('rejects negative response echoing wrong original SID (7F 2F 31)', () {
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x7F, 0x2F, 0x31],
      );
      expect(res, isA<UdsReadMalformed>());
      final mal = res as UdsReadMalformed;
      expect(mal.reason, equals(UdsReadMalformedReason.wrongNegativeOriginalSid));
    });

    test('rejects truncated negative response (7F 22)', () {
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x7F, 0x22],
      );
      expect(res, isA<UdsReadMalformed>());
      final mal = res as UdsReadMalformed;
      expect(mal.reason, equals(UdsReadMalformedReason.missingNrc));
    });

    test('rejects wrong positive SID (0x61 instead of 0x62)', () {
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x61, 0x01, 0x00, 0x12],
      );
      expect(res, isA<UdsReadMalformed>());
      final mal = res as UdsReadMalformed;
      expect(mal.reason, equals(UdsReadMalformedReason.wrongPositiveSid));
    });

    test('rejects wrong echoed DID (0x0200 vs requested 0x0100)', () {
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x02, 0x00, 0x12],
      );
      expect(res, isA<UdsReadMalformed>());
      final mal = res as UdsReadMalformed;
      expect(mal.reason, equals(UdsReadMalformedReason.wrongDidEcho));
    });

    test('rejects truncated positive response (fewer than 3 bytes)', () {
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x01],
      );
      expect(res, isA<UdsReadMalformed>());
      final mal = res as UdsReadMalformed;
      expect(mal.reason, equals(UdsReadMalformedReason.truncated));
    });

    test('rejects empty response', () {
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: const [],
      );
      expect(res, isA<UdsReadMalformed>());
      final mal = res as UdsReadMalformed;
      expect(mal.reason, equals(UdsReadMalformedReason.emptyResponse));
    });

    test('rejects invalid hex string in parseResponseHex', () {
      final res = UdsReadCodec.parseResponseHex(
        requestedDid: testDid,
        rawHex: '6201ZZ',
      );
      expect(res, isA<UdsReadMalformed>());
      final mal = res as UdsReadMalformed;
      expect(mal.reason, equals(UdsReadMalformedReason.invalidHex));
    });
  });

  group('UdsReadCodec DID definition validation & decoding', () {
    const testDid = UdsDid(0x0102);

    test('enforces exact response length constraint', () {
      const defn = UdsDidDefinition<double>(
        did: testDid,
        exactByteLength: 2,
      );

      // Overlong (3 bytes)
      final overlong = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x01, 0x02, 0x01, 0x02, 0x03],
        definition: defn,
      );
      expect(overlong, isA<UdsReadMalformed>());
      expect((overlong as UdsReadMalformed).reason, equals(UdsReadMalformedReason.unexpectedLength));

      // Short (1 byte)
      final shortRes = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x01, 0x02, 0x01],
        definition: defn,
      );
      expect(shortRes, isA<UdsReadMalformed>());
      expect((shortRes as UdsReadMalformed).reason, equals(UdsReadMalformedReason.unexpectedLength));

      // Exact (2 bytes)
      final exactRes = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x01, 0x02, 0x01, 0x00],
        definition: defn,
      );
      expect(exactRes, isA<UdsReadSuccess>());
    });

    test('decodes big-endian scaled numeric value correctly', () {
      const defn = UdsDidDefinition<double>(
        did: testDid,
        exactByteLength: 2,
        byteOrder: UdsDidByteOrder.bigEndian,
        scale: 0.1,
        offset: -40.0,
        unit: 'degC',
      );

      // raw 0x0258 = 600 -> (600 * 0.1) - 40 = 20.0 degC
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x01, 0x02, 0x02, 0x58],
        definition: defn,
      );
      expect(res, isA<UdsReadSuccess>());
      final success = res as UdsReadSuccess;
      expect(success.decoded, isA<UdsReadDecodedValue<double>>());
      final decoded = success.decoded as UdsReadDecodedValue<double>;
      expect(decoded.value, closeTo(20.0, 1e-4));
      expect(decoded.unit, equals('degC'));
    });

    test('decodes little-endian scaled numeric value correctly', () {
      const defn = UdsDidDefinition<double>(
        did: testDid,
        exactByteLength: 2,
        byteOrder: UdsDidByteOrder.littleEndian,
        scale: 1.0,
        offset: 0.0,
        unit: 'counts',
      );

      // little-endian bytes 0x00 0x01 -> 0x0100 = 256
      final res = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x01, 0x02, 0x00, 0x01],
        definition: defn,
      );
      expect(res, isA<UdsReadSuccess>());
      final success = res as UdsReadSuccess;
      final decoded = success.decoded as UdsReadDecodedValue<double>;
      expect(decoded.value, equals(256.0));
      expect(decoded.unit, equals('counts'));
    });

    test('rejects non-finite decoded values (NaN / Infinity) fail-closed', () {
      final nanDefn = UdsDidDefinition<double>(
        did: testDid,
        exactByteLength: 2,
        customDecoder: (bytes) => double.nan,
      );

      final nanRes = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x01, 0x02, 0x7F, 0xFF],
        definition: nanDefn,
      );
      expect(nanRes, isA<UdsReadMalformed>());
      expect((nanRes as UdsReadMalformed).reason, equals(UdsReadMalformedReason.nonFiniteDecodedValue));

      final infDefn = UdsDidDefinition<double>(
        did: testDid,
        exactByteLength: 2,
        customDecoder: (bytes) => double.infinity,
      );

      final infRes = UdsReadCodec.parseResponseBytes(
        requestedDid: testDid,
        responseBytes: [0x62, 0x01, 0x02, 0x7F, 0xFF],
        definition: infDefn,
      );
      expect(infRes, isA<UdsReadMalformed>());
      expect((infRes as UdsReadMalformed).reason, equals(UdsReadMalformedReason.nonFiniteDecodedValue));
    });
  });

  group('UdsReadCodec literal vector parity against JSON fixture', () {
    late Map<String, dynamic> fixtureData;
    late List<dynamic> vectors;

    setUpAll(() {
      final file = File('tool/uds_reference/uds_readonly_vectors.json');
      expect(file.existsSync(), isTrue, reason: 'uds_readonly_vectors.json must exist');
      fixtureData = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      vectors = fixtureData['vectors'] as List<dynamic>;
      expect(vectors, isNotEmpty);
    });

    test('all fixture vectors produce expected Dart outcomes', () {
      var passedCount = 0;
      for (final rawVec in vectors) {
        final vec = rawVec as Map<String, dynamic>;
        final id = vec['id'] as String;
        final category = vec['category'] as String;

        if (category == 'request_encode') {
          final did = UdsDid(vec['did'] as int);
          final expectedBytes = (vec['expected_request_bytes'] as List<dynamic>).cast<int>();
          final expectedHex = vec['expected_request_hex'] as String;

          final encoded = UdsReadCodec.encodeRequestBytes(did);
          expect(encoded, equals(expectedBytes), reason: '$id byte mismatch');
          expect(UdsReadCodec.encodeRequestHex(did), equals(expectedHex), reason: '$id hex mismatch');
          passedCount++;
        } else if (category == 'positive_response') {
          final did = UdsDid(vec['requested_did'] as int);
          final responseBytes = (vec['response_bytes'] as List<dynamic>).cast<int>();
          final expectedData = (vec['expected_data_record'] as List<dynamic>).cast<int>();

          final res = UdsReadCodec.parseResponseBytes(
            requestedDid: did,
            responseBytes: responseBytes,
          );
          expect(res, isA<UdsReadSuccess>(), reason: '$id expected success');
          final success = res as UdsReadSuccess;
          expect(success.did, equals(did), reason: '$id did mismatch');
          expect(success.dataRecord, equals(expectedData), reason: '$id data record mismatch');
          passedCount++;
        } else if (category == 'negative_response') {
          final did = UdsDid(vec['requested_did'] as int);
          final responseBytes = (vec['response_bytes'] as List<dynamic>).cast<int>();
          final expectedOrigSid = vec['expected_original_sid'] as int;
          final expectedNrcCode = vec['expected_nrc_code'] as int;

          final res = UdsReadCodec.parseResponseBytes(
            requestedDid: did,
            responseBytes: responseBytes,
          );
          expect(res, isA<UdsReadNegative>(), reason: '$id expected negative');
          final neg = res as UdsReadNegative;
          expect(neg.did, equals(did), reason: '$id did mismatch');
          expect(neg.originalSid, equals(expectedOrigSid), reason: '$id orig SID mismatch');
          expect(neg.nrc.code, equals(expectedNrcCode), reason: '$id nrc code mismatch');

          final isKnown = vec['expected_nrc_is_known'];
          if (isKnown is bool) {
            expect(neg.nrc.isKnown, equals(isKnown), reason: '$id isKnown mismatch');
          }
          passedCount++;
        } else if (category == 'malformed_response') {
          final did = UdsDid(vec['requested_did'] as int);
          final responseBytes = (vec['response_bytes'] as List<dynamic>).cast<int>();
          final expectedReasonStr = vec['expected_malformed_reason'] as String;

          UdsDidDefinition<Object?>? defn;
          if (vec.containsKey('definition')) {
            final dMap = vec['definition'] as Map<String, dynamic>;
            defn = UdsDidDefinition(
              did: UdsDid(dMap['did'] as int),
              exactByteLength: dMap['exact_byte_length'] as int?,
              customDecoder: expectedReasonStr == 'nonFiniteDecodedValue'
                  ? (_) => double.nan
                  : null,
            );
          }

          final res = UdsReadCodec.parseResponseBytes(
            requestedDid: did,
            responseBytes: responseBytes,
            definition: defn,
          );
          expect(res, isA<UdsReadMalformed>(), reason: '$id expected malformed');
          final mal = res as UdsReadMalformed;
          expect(mal.reason.name, equals(expectedReasonStr), reason: '$id reason mismatch');
          passedCount++;
        } else if (category == 'did_decode') {
          final did = UdsDid(vec['requested_did'] as int);
          final responseBytes = (vec['response_bytes'] as List<dynamic>).cast<int>();
          final dMap = vec['definition'] as Map<String, dynamic>;
          final byteOrderStr = dMap['byte_order'] as String? ?? 'big';

          final defn = UdsDidDefinition<double>(
            did: did,
            name: dMap['name'] as String?,
            exactByteLength: dMap['exact_byte_length'] as int?,
            byteOrder: byteOrderStr == 'little'
                ? UdsDidByteOrder.littleEndian
                : UdsDidByteOrder.bigEndian,
            scale: (dMap['scale'] as num?)?.toDouble(),
            offset: (dMap['offset'] as num?)?.toDouble(),
            unit: dMap['unit'] as String?,
          );

          final res = UdsReadCodec.parseResponseBytes(
            requestedDid: did,
            responseBytes: responseBytes,
            definition: defn,
          );
          expect(res, isA<UdsReadSuccess>(), reason: '$id expected success');
          final success = res as UdsReadSuccess;
          expect(success.decoded, isA<UdsReadDecodedValue<double>>());
          final decoded = success.decoded as UdsReadDecodedValue<double>;
          final expectedScaled = (vec['expected_scaled_value'] as num).toDouble();
          expect(decoded.value, closeTo(expectedScaled, 1e-4), reason: '$id value mismatch');
          if (vec.containsKey('expected_unit')) {
            expect(decoded.unit, equals(vec['expected_unit']), reason: '$id unit mismatch');
          }
          passedCount++;
        }
      }
      expect(passedCount, equals(vectors.length));
    });
  });
}
