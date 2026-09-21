library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';
import 'package:torque_obd/diagnostics/elm327_diagnostic_link.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/polling_engine.dart';

import '../support/fake_elm327.dart';

Future<Elm327Client> _createConnectedClient({
  Duration latency = Duration.zero,
  BusProtocol protocol = BusProtocol.can11,
  List<FakeEcu>? ecus,
  String? forceProtocolNumber,
}) async {
  final transport = FakeElm327(
    protocol: protocol,
    responseLatency: latency,
    forceProtocolNumber: forceProtocolNumber,
    ecus: ecus ?? [
      FakeEcu(
        name: 'ECM',
        requestId: '7E0',
        responseId: '7E8',
        responses: {
          '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
        },
      ),
    ],
  );
  final client = Elm327Client(
    transport,
    commandTimeout: const Duration(milliseconds: 500),
    responsePendingTimeout: const Duration(milliseconds: 600),
  );
  final ok = await client.connect();
  expect(ok, isTrue, reason: 'handshake must complete');
  transport.commandLog.clear();
  return client;
}

void main() {
  group('Layer-type bounds and immutability', () {
    test('ElmAsciiCommand enforces non-empty, no CR/LF, printable ASCII and immutability', () {
      expect(() => ElmAsciiCommand(''), throwsArgumentError);
      expect(() => ElmAsciiCommand('0100\r'), throwsArgumentError);
      expect(() => ElmAsciiCommand('0100\n'), throwsArgumentError);
      expect(() => ElmAsciiCommand('0100\r\n'), throwsArgumentError);
      expect(() => ElmAsciiCommand('0100\u0000'), throwsArgumentError);
      expect(() => ElmAsciiCommand('0100測試'), throwsArgumentError);

      final cmd1 = ElmAsciiCommand('  0100  ');
      expect(cmd1.text, equals('  0100  '));
      expect(cmd1.normalized, equals('0100'));

      final cmd2 = ElmAsciiCommand('  0100  ');
      final cmd3 = ElmAsciiCommand('0100');
      expect(cmd1, equals(cmd2));
      expect(cmd1.hashCode, equals(cmd2.hashCode));
      expect(cmd1 == cmd3, isFalse);
      expect(cmd1.toString(), contains('ElmAsciiCommand'));
    });

    test('CanFrame enforces ID limits, 8-byte max, byte bounds and unmodifiable data', () {
      expect(() => CanFrame(id: -1, data: [0x01]), throwsArgumentError);
      expect(() => CanFrame(id: 0x800, isExtended: false, data: [0x01]), throwsArgumentError);
      expect(() => CanFrame(id: 0x20000000, isExtended: true, data: [0x01]), throwsArgumentError);
      expect(() => CanFrame(id: 0x7DF, data: [1, 2, 3, 4, 5, 6, 7, 8, 9]), throwsArgumentError);
      expect(() => CanFrame(id: 0x7DF, data: [-1]), throwsArgumentError);
      expect(() => CanFrame(id: 0x7DF, data: [256]), throwsArgumentError);

      final validStd = CanFrame(id: 0x7FF, isExtended: false, data: [1, 2, 3]);
      expect(validStd.id, equals(0x7FF));
      expect(validStd.isExtended, isFalse);
      expect(() => (validStd.data as dynamic)[0] = 99, throwsUnsupportedError);

      final validExt = CanFrame(id: 0x1FFFFFFF, isExtended: true, data: [0xAA]);
      expect(validExt.id, equals(0x1FFFFFFF));
      expect(validExt.isExtended, isTrue);

      final copyStd = CanFrame(id: 0x7FF, isExtended: false, data: [1, 2, 3]);
      expect(validStd, equals(copyStd));
      expect(validStd.hashCode, equals(copyStd.hashCode));
      expect(validStd.toString(), contains('0x7FF'));
    });

    test('IsoTpPayload enforces 4095-byte max, byte bounds and unmodifiable payload', () {
      expect(() => IsoTpPayload(List.filled(4096, 0)), throwsArgumentError);
      expect(() => IsoTpPayload([-1]), throwsArgumentError);
      expect(() => IsoTpPayload([256]), throwsArgumentError);

      final valid = IsoTpPayload(List.filled(4095, 0x55));
      expect(valid.length, equals(4095));
      expect(valid.isNotEmpty, isTrue);
      expect(() => (valid.bytes as dynamic)[0] = 0x11, throwsUnsupportedError);

      final empty = IsoTpPayload([]);
      expect(empty.isEmpty, isTrue);
      expect(empty.length, equals(0));

      final a = IsoTpPayload([1, 2, 3]);
      final b = IsoTpPayload([1, 2, 3]);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.toString(), contains('3 bytes'));
    });

    test('ApplicationPdu enforces non-empty, byte bounds, and unmodifiable payload', () {
      expect(() => ApplicationPdu([]), throwsArgumentError);
      expect(() => ApplicationPdu([-1]), throwsArgumentError);
      expect(() => ApplicationPdu([256]), throwsArgumentError);

      final pdu = ApplicationPdu([0x01, 0x00]);
      expect(pdu.length, equals(2));
      expect(pdu[0], equals(0x01));
      expect(pdu[1], equals(0x00));
      expect(() => (pdu.bytes as dynamic)[0] = 0x99, throwsUnsupportedError);

      final pdu2 = ApplicationPdu([0x01, 0x00]);
      expect(pdu, equals(pdu2));
      expect(pdu.hashCode, equals(pdu2.hashCode));
      expect(pdu.toString(), contains('01 00'));
    });
  });

  group('Elm327DiagnosticLink capability absence and projection', () {
    test('T-CAP-01: Elm327DiagnosticLink reports no raw-CAN, raw-ISO-TP or physical-ECU capability', () async {
      final client = await _createConnectedClient();
      final link = Elm327DiagnosticLink(client);

      expect(link.capabilities.contains(DiagnosticCapability.rawCanFrame), isFalse);
      expect(link.capabilities.contains(DiagnosticCapability.rawIsoTpPayload), isFalse);
      expect(link.capabilities.contains(DiagnosticCapability.physicalEcuAddressing), isFalse);
      expect(link.capabilities.contains(DiagnosticCapability.applicationPdu), isTrue);
      expect(link.capabilities.contains(DiagnosticCapability.wholeVehicleObd), isTrue);
    });

    test('T-CAP-02: requesting rawCanFrame throws capabilityUnavailable with wire-zero', () async {
      final client = await _createConnectedClient();
      final transport = client.transport as FakeElm327;
      final link = Elm327DiagnosticLink(client);
      final logBefore = transport.commandLog.length;

      final request = DiagnosticRequest(
        id: const DiagnosticRequestId('req-raw-can'),
        pdu: ApplicationPdu(const [0x01, 0x00]),
        target: DiagnosticTarget.wholeVehicleObd,
        requiredCapabilities: const {DiagnosticCapability.rawCanFrame},
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      await expectLater(
        link.send(request),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            equals(DiagnosticFailureKind.capabilityUnavailable),
          ),
        ),
      );
      expect(transport.commandLog.length, equals(logBefore));
      expect(transport.commandLog.contains('0100'), isFalse);
    });

    test('T-CAP-03: requesting rawIsoTpPayload throws capabilityUnavailable with wire-zero', () async {
      final client = await _createConnectedClient();
      final transport = client.transport as FakeElm327;
      final link = Elm327DiagnosticLink(client);
      final logBefore = transport.commandLog.length;

      final request = DiagnosticRequest(
        id: const DiagnosticRequestId('req-raw-isotp'),
        pdu: ApplicationPdu(const [0x01, 0x00]),
        target: DiagnosticTarget.wholeVehicleObd,
        requiredCapabilities: const {DiagnosticCapability.rawIsoTpPayload},
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      await expectLater(
        link.send(request),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            equals(DiagnosticFailureKind.capabilityUnavailable),
          ),
        ),
      );
      expect(transport.commandLog.length, equals(logBefore));
      expect(transport.commandLog.contains('0100'), isFalse);
    });

    test('T-CAP-04: non-OBD2 addressing advertises empty capabilities and refuses wholeVehicleObd with wire-zero', () async {
      final client = await _createConnectedClient(
        protocol: BusProtocol.can29,
        forceProtocolNumber: 'B',
      );
      final transport = client.transport as FakeElm327;
      final link = Elm327DiagnosticLink(client);

      expect(link.capabilities, isEmpty);
      final logBefore = transport.commandLog.length;

      final request = DiagnosticRequest(
        id: const DiagnosticRequestId('req-j1939'),
        pdu: ApplicationPdu(const [0x01, 0x00]),
        target: DiagnosticTarget.wholeVehicleObd,
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.wholeVehicleObd,
        },
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      await expectLater(
        link.send(request),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            equals(DiagnosticFailureKind.capabilityUnavailable),
          ),
        ),
      );
      expect(transport.commandLog.length, equals(logBefore));
      expect(transport.commandLog.contains('0100'), isFalse);
    });
  });

  group('Elm327DiagnosticLink typed admission failures (wire-zero)', () {
    test('T-ADM-PHYS: physical target typed refusal throws unsupportedTarget and wire-zero', () async {
      final client = await _createConnectedClient();
      final transport = client.transport as FakeElm327;
      final link = Elm327DiagnosticLink(client);
      final logBefore = transport.commandLog.length;

      final request = DiagnosticRequest(
        id: const DiagnosticRequestId('req-phys'),
        pdu: ApplicationPdu(const [0x01, 0x00]),
        target: const DiagnosticTarget.physical(0x7E0),
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.wholeVehicleObd,
        },
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      await expectLater(
        link.send(request),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            equals(DiagnosticFailureKind.unsupportedTarget),
          ),
        ),
      );
      expect(transport.commandLog.length, equals(logBefore));
      expect(transport.commandLog.contains('0100'), isFalse);
    });

    test('T-ADM-GEN: stale generation throws retiredGeneration and wire-zero', () async {
      final client = await _createConnectedClient();
      final transport = client.transport as FakeElm327;
      final link = Elm327DiagnosticLink(client);
      final logBefore = transport.commandLog.length;

      final request = DiagnosticRequest(
        id: const DiagnosticRequestId('req-stale-gen'),
        pdu: ApplicationPdu(const [0x01, 0x00]),
        target: DiagnosticTarget.wholeVehicleObd,
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.wholeVehicleObd,
        },
        connectionGeneration: link.connectionGeneration + 1,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      await expectLater(
        link.send(request),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            equals(DiagnosticFailureKind.retiredGeneration),
          ),
        ),
      );
      expect(transport.commandLog.length, equals(logBefore));
      expect(transport.commandLog.contains('0100'), isFalse);
    });

    test('T-ADM-DL: expired deadline throws deadlineExpired and wire-zero', () async {
      final client = await _createConnectedClient();
      final transport = client.transport as FakeElm327;
      final link = Elm327DiagnosticLink(client);
      final logBefore = transport.commandLog.length;

      final request = DiagnosticRequest(
        id: const DiagnosticRequestId('req-expired-dl'),
        pdu: ApplicationPdu(const [0x01, 0x00]),
        target: DiagnosticTarget.wholeVehicleObd,
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.wholeVehicleObd,
        },
        connectionGeneration: link.connectionGeneration,
        deadline: DateTime.now().subtract(const Duration(seconds: 5)),
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      await expectLater(
        link.send(request),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            equals(DiagnosticFailureKind.deadlineExpired),
          ),
        ),
      );
      expect(transport.commandLog.length, equals(logBefore));
      expect(transport.commandLog.contains('0100'), isFalse);
    });

    test('T-ADM-CANCEL: pre-cancelled request throws cancelled and wire-zero', () async {
      final client = await _createConnectedClient();
      final transport = client.transport as FakeElm327;
      final link = Elm327DiagnosticLink(client);
      final logBefore = transport.commandLog.length;

      final request = DiagnosticRequest(
        id: const DiagnosticRequestId('req-precancel'),
        pdu: ApplicationPdu(const [0x01, 0x00]),
        target: DiagnosticTarget.wholeVehicleObd,
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.wholeVehicleObd,
        },
        connectionGeneration: link.connectionGeneration,
        cancellation: const DiagnosticCancellation(_alwaysCancelled),
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      await expectLater(
        link.send(request),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            equals(DiagnosticFailureKind.cancelled),
          ),
        ),
      );
      expect(transport.commandLog.length, equals(logBefore));
      expect(transport.commandLog.contains('0100'), isFalse);
    });

    test('T-ADM-OWNER: retired owner via client.mayTransmit throws retiredOperation and wire-zero', () async {
      final client = await _createConnectedClient();
      final transport = client.transport as FakeElm327;
      final link = Elm327DiagnosticLink(client);
      client.mayTransmit = (owner) => false;
      final logBefore = transport.commandLog.length;

      final request = DiagnosticRequest(
        id: const DiagnosticRequestId('req-retired-owner'),
        pdu: ApplicationPdu(const [0x01, 0x00]),
        target: DiagnosticTarget.wholeVehicleObd,
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.wholeVehicleObd,
        },
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(
          mode: DiagnosticOwnershipMode.oneShot,
          token: 42,
        ),
      );

      await expectLater(
        link.send(request),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            equals(DiagnosticFailureKind.retiredOperation),
          ),
        ),
      );
      expect(transport.commandLog.length, equals(logBefore));
      expect(transport.commandLog.contains('0100'), isFalse);
    });
  });

  group('Elm327DiagnosticLink in-flight cancellation and retirement', () {
    test('T-INFLIGHT-CANCEL: in-flight cancellation while request is awaiting delayed reply cannot become success', () async {
      final client = await _createConnectedClient(
        latency: const Duration(milliseconds: 150),
      );
      final link = Elm327DiagnosticLink(client);

      final cts = DiagnosticCancellationTokenSource();
      final request = DiagnosticRequest(
        id: const DiagnosticRequestId('req-inflight-cancel'),
        pdu: ApplicationPdu(const [0x01, 0x00]),
        target: DiagnosticTarget.wholeVehicleObd,
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.wholeVehicleObd,
        },
        connectionGeneration: link.connectionGeneration,
        cancellation: cts.token,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      final future = link.send(request);
      await Future.delayed(const Duration(milliseconds: 30));
      cts.cancel();

      await expectLater(
        future,
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            equals(DiagnosticFailureKind.cancelled),
          ),
        ),
      );
    });

    test('T-INFLIGHT-GEN: in-flight connection generation change while request is awaiting delayed reply throws retiredGeneration', () async {
      final client = await _createConnectedClient(
        latency: const Duration(milliseconds: 150),
      );
      final link = Elm327DiagnosticLink(client);

      final request = DiagnosticRequest(
        id: const DiagnosticRequestId('req-inflight-gen'),
        pdu: ApplicationPdu(const [0x01, 0x00]),
        target: DiagnosticTarget.wholeVehicleObd,
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.wholeVehicleObd,
        },
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      final expectation = expectLater(
        link.send(request),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            equals(DiagnosticFailureKind.retiredGeneration),
          ),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 30));
      // Reconnecting bumps the connection generation
      await client.connect();
      await expectation;
    });
  });

  group('Elm327DiagnosticLink positive integration and responder provenance', () {
    test('T-LINK-0100: exact 0100 mapping, request-id echo, status success, response messages', () async {
      final client = await _createConnectedClient();
      final link = Elm327DiagnosticLink(client);

      const reqId = DiagnosticRequestId('req-0100-success');
      final request = DiagnosticRequest(
        id: reqId,
        pdu: ApplicationPdu(const [0x01, 0x00]),
        target: DiagnosticTarget.wholeVehicleObd,
        requiredCapabilities: const {
          DiagnosticCapability.applicationPdu,
          DiagnosticCapability.wholeVehicleObd,
        },
        connectionGeneration: link.connectionGeneration,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.oneShot),
      );

      final response = await link.send(request);
      expect(response.requestId, equals(reqId));
      expect(response.acceptedGeneration, equals(link.connectionGeneration));
      expect(response.isSuccess, isTrue);
      expect(response.status, equals(DiagnosticResponseStatus.success));

      expect(response.messages, isNotEmpty);
      final firstMsg = response.messages.first;
      expect(firstMsg.sourceAddress, equals('7E8'));
      expect(firstMsg.pdu.bytes, equals([0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13]));

      expect(response.provenance.backendId, equals('elm327'));
      expect(response.provenance.connectionGeneration, equals(link.connectionGeneration));
      expect(response.provenance.target, equals(DiagnosticTarget.wholeVehicleObd));
      expect(response.provenance.sourceAttributionAvailable, isTrue);
    });
  });

  group('PollingEngine.discoverResponders() integration', () {
    test('T-ENG-DEFAULT: production PollingEngine through default Elm327DiagnosticLink returns expected responders', () async {
      final client = await _createConnectedClient(
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
            name: 'TCM',
            requestId: '7E1',
            responseId: '7E9',
            responses: {
              '0100': [0x41, 0x00, 0x80, 0x00, 0x00, 0x01],
            },
          ),
        ],
      );

      final engine = PollingEngine(client);
      expect(engine.diagnosticLink, isA<Elm327DiagnosticLink>());

      final responders = await engine.discoverResponders();
      expect(responders, equals({'7E8', '7E9'}));
    });

    test('T-ENG-LEGACY: legacy bus responder discovery attribution behavior preserved', () async {
      final client = await _createConnectedClient(
        protocol: BusProtocol.iso9141,
        ecus: [
          FakeEcu(
            name: 'ECM',
            requestId: '6810F1',
            responseId: '486B10',
            responses: {
              '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
            },
          ),
        ],
      );

      final engine = PollingEngine(client);
      final responders = await engine.discoverResponders();
      expect(responders, equals({'10'}));
    });
  });
}

bool _alwaysCancelled() => true;
