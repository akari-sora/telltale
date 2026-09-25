library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';
import 'package:torque_obd/diagnostics/elm327_diagnostic_link.dart';
import 'package:torque_obd/obd/elm327_client.dart';

import '../support/fake_elm327.dart';

Future<({Elm327Client client, FakeElm327 transport})> _createConnectedPair({
  BusProtocol protocol = BusProtocol.can11,
  List<FakeEcu>? ecus,
  String? forceProtocolNumber,
  AdapterFaults faults = const AdapterFaults(),
  Duration commandTimeout = const Duration(milliseconds: 500),
  Duration latency = Duration.zero,
}) async {
  final transport = FakeElm327(
    protocol: protocol,
    responseLatency: latency,
    forceProtocolNumber: forceProtocolNumber,
    faults: faults,
    ecus: ecus ?? (protocol == BusProtocol.can29 || forceProtocolNumber == '7' || forceProtocolNumber == '9'
        ? [
            FakeEcu(
              name: '29-bit ECM',
              requestId: '18DA10F1',
              responseId: '18DAF110',
              responses: {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
                '22B046': [0x62, 0xB0, 0x46, 0x01, 0xF4],
              },
            ),
          ]
        : [
            FakeEcu(
              name: 'ECM',
              requestId: '7E0',
              responseId: '7E8',
              responses: {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
              },
            ),
            FakeEcu(
              name: 'BMS',
              requestId: '781',
              responseId: '789',
              responses: {
                '22B046': [0x62, 0xB0, 0x46, 0x01, 0xF4],
              },
            ),
          ]),
  );
  final client = Elm327Client(
    transport,
    commandTimeout: commandTimeout,
    responsePendingTimeout: const Duration(milliseconds: 600),
  );
  final ok = await client.connect();
  expect(ok, isTrue, reason: 'handshake must complete');
  transport.commandLog.clear();
  return (client: client, transport: transport);
}

void main() {
  group('DiagnosticCanIdentifier validation & bounds', () {
    test('CAN11 ID validation', () {
      final id0 = DiagnosticCanIdentifier.standard(0x000);
      expect(id0.id, 0);
      expect(id0.value, '000');
      expect(id0.isStandard, isTrue);
      expect(id0.isExtended, isFalse);

      final id781 = DiagnosticCanIdentifier.standard(0x781);
      expect(id781.id, 0x781);
      expect(id781.value, '781');

      final id7FF = DiagnosticCanIdentifier.standard(0x7FF);
      expect(id7FF.id, 0x7FF);
      expect(id7FF.value, '7FF');

      expect(() => DiagnosticCanIdentifier.standard(-1), throwsArgumentError);
      expect(() => DiagnosticCanIdentifier.standard(0x800), throwsArgumentError);

      expect(() => DiagnosticCanIdentifier.parse(''), throwsArgumentError);
      expect(() => DiagnosticCanIdentifier.parse('7F'), throwsArgumentError);
      expect(() => DiagnosticCanIdentifier.parse('07E0'), throwsArgumentError);
      expect(() => DiagnosticCanIdentifier.parse('800'), throwsArgumentError);
      expect(() => DiagnosticCanIdentifier.parse('FFF'), throwsArgumentError);
      expect(() => DiagnosticCanIdentifier.parse('XYZ'), throwsArgumentError);
    });

    test('CAN29 ID validation', () {
      final id0 = DiagnosticCanIdentifier.extended(0x00000000);
      expect(id0.id, 0);
      expect(id0.value, '00000000');
      expect(id0.isStandard, isFalse);
      expect(id0.isExtended, isTrue);

      final idExt = DiagnosticCanIdentifier.extended(0x18DA10F1);
      expect(idExt.id, 0x18DA10F1);
      expect(idExt.value, '18DA10F1');

      final idMax = DiagnosticCanIdentifier.extended(0x1FFFFFFF);
      expect(idMax.id, 0x1FFFFFFF);
      expect(idMax.value, '1FFFFFFF');

      expect(() => DiagnosticCanIdentifier.extended(-1), throwsArgumentError);
      expect(() => DiagnosticCanIdentifier.extended(0x20000000), throwsArgumentError);

      expect(() => DiagnosticCanIdentifier.parse('18DA10F'), throwsArgumentError);
      expect(() => DiagnosticCanIdentifier.parse('018DA10F1'), throwsArgumentError);
      expect(() => DiagnosticCanIdentifier.parse('20000000'), throwsArgumentError);
      expect(() => DiagnosticCanIdentifier.parse('FFFFFFFF'), throwsArgumentError);
      expect(() => DiagnosticCanIdentifier.parse('XXXXXXXX'), throwsArgumentError);
    });

    test('lowercase canonicalization', () {
      final id11 = DiagnosticCanIdentifier.parse('7e0');
      expect(id11.value, '7E0');
      expect(id11.id, 0x7E0);
      expect(id11, equals(DiagnosticCanIdentifier.standard(0x7E0)));

      final id29 = DiagnosticCanIdentifier.parse('18daf110');
      expect(id29.value, '18DAF110');
      expect(id29.id, 0x18DAF110);
      expect(id29, equals(DiagnosticCanIdentifier.extended(0x18DAF110)));
    });
  });

  group('DiagnosticTarget.physicalCan', () {
    test('target holds request and expected responder identifiers without forced width equality', () {
      final req11 = DiagnosticCanIdentifier.standard(0x781);
      final exp11 = DiagnosticCanIdentifier.standard(0x789);
      final target = DiagnosticTarget.physicalCan(
        requestIdentifier: req11,
        expectedResponderIdentifier: exp11,
      );

      expect(target.requestIdentifier, equals(req11));
      expect(target.expectedResponderIdentifier, equals(exp11));
      expect(
        target,
        equals(
          DiagnosticTarget.physicalCan(
            requestIdentifier: req11,
            expectedResponderIdentifier: exp11,
          ),
        ),
      );
    });

    test('mixed-width construction is permitted by value type, admission decided by link', () {
      final req11 = DiagnosticCanIdentifier.standard(0x781);
      final exp29 = DiagnosticCanIdentifier.extended(0x18DAF110);
      final target = DiagnosticTarget.physicalCan(
        requestIdentifier: req11,
        expectedResponderIdentifier: exp29,
      );

      expect(target.requestIdentifier!.isStandard, isTrue);
      expect(target.expectedResponderIdentifier!.isExtended, isTrue);
      expect(target.requestIdentifier!.value, '781');
      expect(target.expectedResponderIdentifier!.value, '18DAF110');
    });
  });

  group('Elm327DiagnosticLink capability matrix', () {
    test('physical capability CAN11', () async {
      final pair = await _createConnectedPair(protocol: BusProtocol.can11);
      final link = Elm327DiagnosticLink(pair.client);

      expect(link.capabilities.contains(DiagnosticCapability.applicationPdu), isTrue);
      expect(link.capabilities.contains(DiagnosticCapability.wholeVehicleObd), isTrue);
      expect(link.capabilities.contains(DiagnosticCapability.physicalEcuAddressing), isTrue);
      expect(link.capabilities.contains(DiagnosticCapability.rawCanFrame), isFalse);
      expect(link.capabilities.contains(DiagnosticCapability.rawIsoTpPayload), isFalse);
    });

    test('physical capability CAN29', () async {
      final pair = await _createConnectedPair(protocol: BusProtocol.can29);
      final link = Elm327DiagnosticLink(pair.client);

      expect(link.capabilities.contains(DiagnosticCapability.applicationPdu), isTrue);
      expect(link.capabilities.contains(DiagnosticCapability.wholeVehicleObd), isTrue);
      expect(link.capabilities.contains(DiagnosticCapability.physicalEcuAddressing), isTrue);
      expect(link.capabilities.contains(DiagnosticCapability.rawCanFrame), isFalse);
      expect(link.capabilities.contains(DiagnosticCapability.rawIsoTpPayload), isFalse);
    });

    test('no physical capability legacy', () async {
      final pair = await _createConnectedPair(
        protocol: BusProtocol.iso9141,
        forceProtocolNumber: '3',
      );
      final link = Elm327DiagnosticLink(pair.client);

      expect(link.capabilities.contains(DiagnosticCapability.applicationPdu), isTrue);
      expect(link.capabilities.contains(DiagnosticCapability.wholeVehicleObd), isTrue);
      expect(link.capabilities.contains(DiagnosticCapability.physicalEcuAddressing), isFalse);
      expect(link.capabilities.contains(DiagnosticCapability.rawCanFrame), isFalse);
      expect(link.capabilities.contains(DiagnosticCapability.rawIsoTpPayload), isFalse);
    });

    test('no physical capability J1939/unknown', () async {
      final pair = await _createConnectedPair(
        protocol: BusProtocol.can29,
        forceProtocolNumber: 'B', // J1939 CAN 29/250
      );
      final link = Elm327DiagnosticLink(pair.client);

      expect(link.capabilities.contains(DiagnosticCapability.physicalEcuAddressing), isFalse);
      expect(link.capabilities.contains(DiagnosticCapability.wholeVehicleObd), isFalse);
      expect(link.capabilities, isEmpty);
    });
  });

  group('Physical CAN Wire Mapping & Execution', () {
    test('781 + 22B046 exact wire mapping', () async {
      final pair = await _createConnectedPair(protocol: BusProtocol.can11);
      final link = Elm327DiagnosticLink(pair.client);

      final req = DiagnosticRequest(
        id: const DiagnosticRequestId('bms-test-1'),
        pdu: ApplicationPdu(const [0x22, 0xB0, 0x46]),
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x781),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x789),
        ),
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.physicalEcuAddressing,
        },
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      final response = await link.send(req);
      expect(response.isSuccess, isTrue);
      expect(response.messages, hasLength(1));
      expect(response.messages.single.sourceAddress?.value, '789');
      expect(response.messages.single.pdu.bytes, [0x62, 0xB0, 0x46, 0x01, 0xF4]);

      // Wire verification
      expect(pair.transport.commandLog, contains('ATSH781'));
      expect(pair.transport.commandLog, contains('22B046'));
    });

    test('29-bit exact ATSH mapping', () async {
      final pair = await _createConnectedPair(
        protocol: BusProtocol.can29,
        ecus: [
          FakeEcu(
            name: '29-bit ECU',
            requestId: '18DA10F1',
            responseId: '18DAF110',
            responses: {
              '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
              '22B046': [0x62, 0xB0, 0x46, 0x01, 0xF4],
            },
          ),
        ],
      );
      final link = Elm327DiagnosticLink(pair.client);

      final req = DiagnosticRequest(
        id: const DiagnosticRequestId('bms-29bit-1'),
        pdu: ApplicationPdu(const [0x22, 0xB0, 0x46]),
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.extended(0x18DA10F1),
          expectedResponderIdentifier: DiagnosticCanIdentifier.extended(0x18DAF110),
        ),
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.physicalEcuAddressing,
        },
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      final response = await link.send(req);
      expect(response.isSuccess, isTrue);
      expect(pair.transport.commandLog, contains('ATSH18DA10F1'));
      expect(pair.transport.commandLog, contains('22B046'));
    });

    test('request width mismatch wire-zero', () async {
      final pair = await _createConnectedPair(protocol: BusProtocol.can11);
      final link = Elm327DiagnosticLink(pair.client);

      final req = DiagnosticRequest(
        id: const DiagnosticRequestId('mismatch-req'),
        pdu: ApplicationPdu(const [0x22, 0xB0, 0x46]),
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.extended(0x18DA10F1),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x789),
        ),
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.physicalEcuAddressing,
        },
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      try {
        await link.send(req);
        fail('must throw unsupportedTarget');
      } on DiagnosticLinkException catch (e) {
        expect(e.kind, DiagnosticFailureKind.unsupportedTarget);
      }
      expect(pair.transport.commandLog, isEmpty, reason: 'wire-zero guaranteed');
    });

    test('responder width mismatch wire-zero', () async {
      final pair = await _createConnectedPair(protocol: BusProtocol.can11);
      final link = Elm327DiagnosticLink(pair.client);

      final req = DiagnosticRequest(
        id: const DiagnosticRequestId('mismatch-exp'),
        pdu: ApplicationPdu(const [0x22, 0xB0, 0x46]),
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x781),
          expectedResponderIdentifier: DiagnosticCanIdentifier.extended(0x18DAF110),
        ),
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.physicalEcuAddressing,
        },
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      try {
        await link.send(req);
        fail('must throw unsupportedTarget');
      } on DiagnosticLinkException catch (e) {
        expect(e.kind, DiagnosticFailureKind.unsupportedTarget);
      }
      expect(pair.transport.commandLog, isEmpty, reason: 'wire-zero guaranteed');
    });

    test('no functional-header fallback', () async {
      final pair = await _createConnectedPair(protocol: BusProtocol.can11);
      final link = Elm327DiagnosticLink(pair.client);

      final req = DiagnosticRequest(
        id: const DiagnosticRequestId('no-fallback'),
        pdu: ApplicationPdu(const [0x22, 0xB0, 0x46]),
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x781),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x789),
        ),
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.physicalEcuAddressing,
        },
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      await link.send(req);
      expect(pair.transport.commandLog, isNot(contains('ATSH7DF')));
      expect(pair.transport.commandLog, isNot(contains('ATSH 7DF')));
    });

    test('responseTimeout independent of deadline', () async {
      final pair = await _createConnectedPair(
        protocol: BusProtocol.can11,
        faults: const AdapterFaults(swallowPromptFor: {'22B046'}),
      );
      final link = Elm327DiagnosticLink(pair.client);

      final req = DiagnosticRequest(
        id: const DiagnosticRequestId('timeout-test'),
        pdu: ApplicationPdu(const [0x22, 0xB0, 0x46]),
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x781),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x789),
        ),
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.physicalEcuAddressing,
        },
        connectionGeneration: link.connectionGeneration,
        responseTimeout: const Duration(milliseconds: 50),
        deadline: DateTime.now().add(const Duration(minutes: 5)),
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      try {
        await link.send(req);
        fail('must throw responseTimeout');
      } on DiagnosticLinkException catch (e) {
        expect(
          e.kind,
          DiagnosticFailureKind.responseTimeout,
          reason: 'responseTimeout fired while deadline is still in the future',
        );
      }
    });

    test('physical stale generation throws retiredGeneration and wire-zero', () async {
      final pair = await _createConnectedPair(protocol: BusProtocol.can11);
      final link = Elm327DiagnosticLink(pair.client);

      final req = DiagnosticRequest(
        id: const DiagnosticRequestId('stale-gen'),
        pdu: ApplicationPdu(const [0x22, 0xB0, 0x46]),
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x781),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x789),
        ),
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.physicalEcuAddressing,
        },
        connectionGeneration: link.connectionGeneration - 1,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      try {
        await link.send(req);
        fail('must throw retiredGeneration');
      } on DiagnosticLinkException catch (e) {
        expect(e.kind, DiagnosticFailureKind.retiredGeneration);
      }
      expect(pair.transport.commandLog, isEmpty);
    });

    test('physical pre-cancel throws cancelled and wire-zero', () async {
      final pair = await _createConnectedPair(protocol: BusProtocol.can11);
      final link = Elm327DiagnosticLink(pair.client);

      final cts = DiagnosticCancellationTokenSource();
      cts.cancel();

      final req = DiagnosticRequest(
        id: const DiagnosticRequestId('pre-cancel'),
        pdu: ApplicationPdu(const [0x22, 0xB0, 0x46]),
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x781),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x789),
        ),
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.physicalEcuAddressing,
        },
        connectionGeneration: link.connectionGeneration,
        cancellation: cts.token,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      try {
        await link.send(req);
        fail('must throw cancelled');
      } on DiagnosticLinkException catch (e) {
        expect(e.kind, DiagnosticFailureKind.cancelled);
      }
      expect(pair.transport.commandLog, isEmpty);
    });

    test('physical retired owner throws retiredOperation and wire-zero', () async {
      final pair = await _createConnectedPair(protocol: BusProtocol.can11);
      pair.client.mayTransmit = (owner) => false;
      final link = Elm327DiagnosticLink(pair.client);

      final req = DiagnosticRequest(
        id: const DiagnosticRequestId('retired-owner'),
        pdu: ApplicationPdu(const [0x22, 0xB0, 0x46]),
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x781),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x789),
        ),
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.physicalEcuAddressing,
        },
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      try {
        await link.send(req);
        fail('must throw retiredOperation');
      } on DiagnosticLinkException catch (e) {
        expect(e.kind, DiagnosticFailureKind.retiredOperation);
      }
      expect(pair.transport.commandLog, isEmpty);
    });

    test('wrong responder remains visible to caller', () async {
      // ECU answers with 7E8 instead of expected 789
      final pair = await _createConnectedPair(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: {
              '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
            },
          ),
          FakeEcu(
            name: 'Wrong ECU',
            requestId: '781',
            responseId: '7E8',
            responses: {
              '22B046': [0x62, 0xB0, 0x46, 0x01, 0xF4],
            },
          ),
        ],
      );
      final link = Elm327DiagnosticLink(pair.client);

      final req = DiagnosticRequest(
        id: const DiagnosticRequestId('wrong-responder'),
        pdu: ApplicationPdu(const [0x22, 0xB0, 0x46]),
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x781),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x789),
        ),
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.physicalEcuAddressing,
        },
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      final response = await link.send(req);
      expect(response.isSuccess, isTrue);
      expect(response.messages, hasLength(1));
      // The adapter did NOT filter out 7E8
      expect(response.messages.single.sourceAddress?.value, '7E8');
    });

    test('multiple responders remain visible to caller', () async {
      // Multiple ECUs answer
      final pair = await _createConnectedPair(
        protocol: BusProtocol.can11,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '7E0',
            responseId: '7E8',
            responses: {
              '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
            },
          ),
          FakeEcu(
            name: 'Expected ECU',
            requestId: '781',
            responseId: '789',
            responses: {
              '22B046': [0x62, 0xB0, 0x46, 0x01, 0xF4],
            },
          ),
          FakeEcu(
            name: 'Other ECU',
            requestId: '781',
            responseId: '7E8',
            responses: {
              '22B046': [0x62, 0xB0, 0x46, 0x01, 0xF4],
            },
          ),
        ],
      );
      final link = Elm327DiagnosticLink(pair.client);

      final req = DiagnosticRequest(
        id: const DiagnosticRequestId('multi-responder'),
        pdu: ApplicationPdu(const [0x22, 0xB0, 0x46]),
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x781),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x789),
        ),
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.physicalEcuAddressing,
        },
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      final response = await link.send(req);
      expect(response.isSuccess, isTrue);
      // Both responders remain visible, adapter does NOT pick first
      expect(response.messages.length, greaterThanOrEqualTo(2));
      final sourceIds = response.messages.map((m) => m.sourceAddress?.value).toSet();
      expect(sourceIds, contains('789'));
      expect(sourceIds, contains('7E8'));
    });
  });
}
