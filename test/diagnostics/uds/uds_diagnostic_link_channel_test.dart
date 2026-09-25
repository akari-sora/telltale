library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';
import 'package:torque_obd/diagnostics/elm327_diagnostic_link.dart';
import 'package:torque_obd/diagnostics/uds/uds_diagnostic_link_channel.dart';
import 'package:torque_obd/diagnostics/uds/uds_dtc_types.dart';
import 'package:torque_obd/diagnostics/uds/uds_read_types.dart';
import 'package:torque_obd/diagnostics/uds/uds_transaction_engine.dart';
import 'package:torque_obd/diagnostics/uds/uds_transaction_policy.dart';
import 'package:torque_obd/diagnostics/uds/uds_transaction_types.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/obd/transport/wifi_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';

import '../../support/fake_elm327.dart';

List<FakeEcu> _withHandshakeEcus(List<FakeEcu>? ecus) {
  final list = ecus ??
      [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: {
            // 0100 needed for Elm327Client handshake/protocol discovery
            '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
            // 0x22 0x01 0x00 (read DID 0x0100) -> 62 01 00 12 34
            '220100': [0x62, 0x01, 0x00, 0x12, 0x34],
            // 0x19 0x02 0x08 (reportDTCByStatusMask) -> 59 02 2F + 2 DTC records
            '190208': [
              0x59, 0x02, 0x2F,
              0x01, 0x23, 0x45, 0x2F,
              0x06, 0x78, 0x9A, 0x28,
            ],
          },
        ),
      ];

  if (!list.any((e) => e.responses.containsKey('0100'))) {
    final first = list.first;
    final merged = Map<String, List<int>>.from(first.responses)
      ..putIfAbsent('0100', () => [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13]);
    return [
      FakeEcu(
        name: first.name,
        requestId: first.requestId,
        responseId: first.responseId,
        responses: merged,
        literalResponses: first.literalResponses,
        missesFunctionalFor: first.missesFunctionalFor,
      ),
      ...list.skip(1),
    ];
  }
  return list;
}

/// Helper to spin up a fully connected Elm327Client + Elm327DiagnosticLink stack.
Future<
    ({
      Elm327Client client,
      FakeElm327 transport,
      Elm327DiagnosticLink link,
    })> _createProductionStack({
  BusProtocol protocol = BusProtocol.can11,
  List<FakeEcu>? ecus,
  Duration commandTimeout = const Duration(milliseconds: 500),
  AdapterFaults faults = const AdapterFaults(),
}) async {
  final transport = FakeElm327(
    protocol: protocol,
    faults: faults,
    ecus: _withHandshakeEcus(ecus),
  );

  final client = Elm327Client(
    transport,
    commandTimeout: commandTimeout,
    responsePendingTimeout: const Duration(milliseconds: 600),
  );

  final connected = await client.connect();
  expect(connected, isTrue, reason: 'Elm327Client handshake must succeed');
  transport.commandLog.clear();

  final link = Elm327DiagnosticLink(client);
  return (client: client, transport: transport, link: link);
}

/// Helper to spin up a fully connected Elm327Client + Elm327DiagnosticLink stack over a true OS TCP socket.
Future<
    ({
      Elm327Client client,
      FakeElm327 transport,
      Elm327DiagnosticLink link,
      ServerSocket server,
      WifiTransport wifiTransport,
      List<Socket> clientSockets,
    })> _createProductionTcpStack({
  BusProtocol protocol = BusProtocol.can11,
  List<FakeEcu>? ecus,
  Duration commandTimeout = const Duration(milliseconds: 500),
  AdapterFaults faults = const AdapterFaults(),
}) async {
  final transport = FakeElm327(
    protocol: protocol,
    faults: faults,
    ecus: _withHandshakeEcus(ecus),
  );

  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final clientSockets = <Socket>[];

  server.listen((clientSocket) {
    clientSockets.add(clientSocket);
    final sub1 = clientSocket.listen(
      (data) => transport.write(data),
      onError: (e) {},
      cancelOnError: true,
    );
    final sub2 = transport.incoming.listen(
      (data) {
        try {
          clientSocket.add(data);
        } catch (_) {}
      },
      onError: (e) {},
    );
    clientSocket.done.then((_) {
      sub1.cancel();
      sub2.cancel();
    }, onError: (_) {
      sub1.cancel();
      sub2.cancel();
    });
  }, onError: (e) {});

  // Transport must be connected so its write() method accepts socket bytes
  await transport.connect();

  final wifiTransport = WifiTransport(
    host: InternetAddress.loopbackIPv4.host,
    port: server.port,
  );

  final client = Elm327Client(
    wifiTransport,
    commandTimeout: commandTimeout,
    responsePendingTimeout: const Duration(milliseconds: 600),
  );

  final connected = await client.connect();
  expect(connected, isTrue, reason: 'Elm327Client TCP handshake must succeed');
  transport.commandLog.clear();

  final link = Elm327DiagnosticLink(client);
  return (
    client: client,
    transport: transport,
    link: link,
    server: server,
    wifiTransport: wifiTransport,
    clientSockets: clientSockets,
  );
}

Future<void> _teardownTcpStack(dynamic stack) async {
  await stack.client.disconnect();
  await stack.wifiTransport.disconnect();
  for (final s in stack.clientSockets as List<Socket>) {
    s.destroy();
  }
  await stack.server.close();
}

Future<ProviderContainer> _createContainer(Map<String, Object> prefsValues) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
}

Future<void> _waitForWireCommand(
  FakeElm327 adapter,
  String command, {
  int afterCount = 0,
  Duration timeout = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  int count() => adapter.commandLog.where((wire) => wire == command).length;
  while (count() <= afterCount && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(count(), greaterThan(afterCount), reason: 'Timed out waiting for wire command $command');
}

Future<void> _waitForInitialCensus(ObdSession session) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while ((session.engine?.responders == null ||
          session.linkOwnership?.activeTakeovers != 0 ||
          session.engine?.supportDiscoveryComplete != true) &&
      DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  group('DiagnosticLinkUdsTransactionChannel Unit Contracts', () {
    test('default required capabilities match PhysicalCanDiagnosticTarget', () async {
      final stack = await _createProductionStack();
      addTearDown(() => stack.client.disconnect());

      final physicalTarget = DiagnosticTarget.physicalCan(
        requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
        expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
      );

      final chPhys = DiagnosticLinkUdsTransactionChannel(
        link: stack.link,
        target: physicalTarget,
        connectionGeneration: stack.link.connectionGeneration,
      );
      expect(chPhys.requiredCapabilities, contains(DiagnosticCapability.applicationPdu));
      expect(chPhys.requiredCapabilities, contains(DiagnosticCapability.physicalEcuAddressing));
      expect(chPhys.requiredCapabilities, isNot(contains(DiagnosticCapability.wholeVehicleObd)));
    });

    test('precondition checks: cancelled before send throws immediately', () async {
      final stack = await _createProductionStack();
      addTearDown(() => stack.client.disconnect());

      final cts = DiagnosticCancellationTokenSource()..cancel();
      final physicalTarget = DiagnosticTarget.physicalCan(
        requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
        expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
      );

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: stack.link,
        target: physicalTarget,
        connectionGeneration: stack.link.connectionGeneration,
        cancellation: cts.token,
      );

      expect(
        () => channel.send(
          const DiagnosticRequestId('req-1'),
          ApplicationPdu([0x22, 0x01, 0x00]),
          const Duration(milliseconds: 200),
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.cancelled,
          ),
        ),
      );
    });

    test('precondition checks: retired generation throws immediately', () async {
      final stack = await _createProductionStack();
      addTearDown(() => stack.client.disconnect());

      final physicalTarget = DiagnosticTarget.physicalCan(
        requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
        expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
      );

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: stack.link,
        target: physicalTarget,
        connectionGeneration: stack.link.connectionGeneration + 99, // Mismatched generation
      );

      expect(
        () => channel.send(
          const DiagnosticRequestId('req-1'),
          ApplicationPdu([0x22, 0x01, 0x00]),
          const Duration(milliseconds: 200),
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.retiredGeneration,
          ),
        ),
      );
    });

    test('noData or empty response converts to TimeoutException', () async {
      final stack = await _createProductionStack();
      addTearDown(() => stack.client.disconnect());

      // Force NO DATA response from adapter
      stack.transport.forceReplySequence('220100', ['NO DATA']);

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: stack.link,
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        ),
        connectionGeneration: stack.link.connectionGeneration,
      );

      expect(
        () => channel.send(
          const DiagnosticRequestId('req-1'),
          ApplicationPdu([0x22, 0x01, 0x00]),
          const Duration(milliseconds: 200),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('continuation buffer: multi-message response from link enqueues subsequent frames', () async {
      final link = _MultiFrameDiagnosticLink(
        messages: [
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x12, 0x34]),
            sourceAddress: DiagnosticSourceAddress('7E8'),
          ),
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0xAA, 0xBB]),
            sourceAddress: DiagnosticSourceAddress('7E8'),
          ),
        ],
      );

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: link,
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        ),
        connectionGeneration: link.connectionGeneration,
      );

      final first = await channel.send(
        const DiagnosticRequestId('req-multi'),
        ApplicationPdu([0x22, 0x01, 0x00]),
        const Duration(milliseconds: 500),
      );
      expect(first.pdu.bytes, [0x62, 0x01, 0x00, 0x12, 0x34]);
      expect(channel.bufferedContinuationCount, 1);

      final cont = await channel.receiveContinuation(const Duration(milliseconds: 200));
      expect(cont.pdu.bytes, [0x62, 0x01, 0x00, 0xAA, 0xBB]);
      expect(channel.bufferedContinuationCount, 0);
    });

    test('continuation buffer: clears on new send to prevent cross-request leakage', () async {
      final link = _MultiFrameDiagnosticLink(
        messages: [
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x12, 0x34]),
            sourceAddress: DiagnosticSourceAddress('7E8'),
          ),
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0xAA, 0xBB]),
            sourceAddress: DiagnosticSourceAddress('7E8'),
          ),
        ],
      );

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: link,
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        ),
        connectionGeneration: link.connectionGeneration,
      );

      // First send leaves 1 continuation in buffer
      await channel.send(
        const DiagnosticRequestId('req-1'),
        ApplicationPdu([0x22, 0x01, 0x00]),
        const Duration(milliseconds: 500),
      );
      expect(channel.bufferedContinuationCount, 1);

      // Second send clears continuation buffer and populates fresh continuation
      final second = await channel.send(
        const DiagnosticRequestId('req-2'),
        ApplicationPdu([0x22, 0x02, 0x00]),
        const Duration(milliseconds: 500),
      );

      expect(second.pdu.bytes, [0x62, 0x01, 0x00, 0x12, 0x34]);
      expect(channel.bufferedContinuationCount, 1);
    });

    test('continuation buffer: receiveContinuation with empty buffer throws TimeoutException', () async {
      final stack = await _createProductionStack();
      addTearDown(() => stack.client.disconnect());

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: stack.link,
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        ),
        connectionGeneration: stack.link.connectionGeneration,
      );

      expect(
        () => channel.receiveContinuation(const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('continuation buffer: clearContinuationQueue resets buffer count', () async {
      final link = _MultiFrameDiagnosticLink(
        messages: [
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x12, 0x34]),
            sourceAddress: DiagnosticSourceAddress('7E8'),
          ),
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0xAA, 0xBB]),
            sourceAddress: DiagnosticSourceAddress('7E8'),
          ),
        ],
      );

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: link,
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        ),
        connectionGeneration: link.connectionGeneration,
      );

      await channel.send(
        const DiagnosticRequestId('req-clear'),
        ApplicationPdu([0x22, 0x01, 0x00]),
        const Duration(milliseconds: 500),
      );
      expect(channel.bufferedContinuationCount, 1);

      channel.clearContinuationQueue();
      expect(channel.bufferedContinuationCount, 0);
    });
  });

  group('DiagnosticLinkUdsTransactionChannel Response Attribution & Deadlines', () {
    test('physical targeting rejects response when source attribution is unavailable', () async {
      final stack = await _createProductionStack();
      addTearDown(() => stack.client.disconnect());

      final target = DiagnosticTarget.physicalCan(
        requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
        expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
      );

      // Wrapper returning sourceAttributionAvailable: false
      final unassistedLink = _AttributionDisabledDiagnosticLink(stack.link);

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: unassistedLink,
        target: target,
        connectionGeneration: stack.link.connectionGeneration,
      );

      expect(
        () => channel.send(
          const DiagnosticRequestId('req-attr'),
          ApplicationPdu([0x22, 0x01, 0x00]),
          const Duration(milliseconds: 500),
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.unsupportedTarget,
          ),
        ),
      );
    });

    test('R1: response batch containing foreign frame is rejected fail-closed', () async {
      final link = _MultiFrameDiagnosticLink(
        messages: [
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x12, 0x34]),
            sourceAddress: DiagnosticSourceAddress('7E8'),
          ),
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x55, 0x66]),
            sourceAddress: DiagnosticSourceAddress('7E9'), // Foreign responder frame mixed in batch
          ),
        ],
      );

      final target = DiagnosticTarget.physicalCan(
        requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
        expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
      );

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: link,
        target: target,
        connectionGeneration: link.connectionGeneration,
      );

      expect(
        () => channel.send(
          const DiagnosticRequestId('req-r1'),
          ApplicationPdu([0x22, 0x01, 0x00]),
          const Duration(milliseconds: 500),
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.unsupportedTarget,
          ),
        ),
      );
    });

    test('envelope defense: requestId mismatch throws DiagnosticLinkException', () async {
      final link = _EnvelopeConfigurableLink(
        overrideRequestId: const DiagnosticRequestId('foreign-req-id'),
        messages: [
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x12, 0x34]),
            sourceAddress: DiagnosticSourceAddress('7E8'),
          ),
        ],
      );

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: link,
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        ),
        connectionGeneration: 1,
      );

      expect(
        () => channel.send(
          const DiagnosticRequestId('expected-req-id'),
          ApplicationPdu([0x22, 0x01, 0x00]),
          const Duration(milliseconds: 500),
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.retiredOperation,
          ),
        ),
      );
    });

    test('envelope defense: acceptedGeneration mismatch throws DiagnosticLinkException', () async {
      final link = _EnvelopeConfigurableLink(
        overrideAcceptedGeneration: 99,
        messages: [
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x12, 0x34]),
            sourceAddress: DiagnosticSourceAddress('7E8'),
          ),
        ],
      );

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: link,
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        ),
        connectionGeneration: 1,
      );

      expect(
        () => channel.send(
          const DiagnosticRequestId('req-1'),
          ApplicationPdu([0x22, 0x01, 0x00]),
          const Duration(milliseconds: 500),
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.retiredGeneration,
          ),
        ),
      );
    });

    test('envelope defense: provenance connectionGeneration mismatch throws DiagnosticLinkException', () async {
      final link = _EnvelopeConfigurableLink(
        overrideProvenanceGeneration: 99,
        messages: [
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x12, 0x34]),
            sourceAddress: DiagnosticSourceAddress('7E8'),
          ),
        ],
      );

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: link,
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        ),
        connectionGeneration: 1,
      );

      expect(
        () => channel.send(
          const DiagnosticRequestId('req-1'),
          ApplicationPdu([0x22, 0x01, 0x00]),
          const Duration(milliseconds: 500),
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.retiredGeneration,
          ),
        ),
      );
    });

    test('envelope defense: provenance target mismatch throws DiagnosticLinkException', () async {
      final link = _EnvelopeConfigurableLink(
        overrideProvenanceTarget: DiagnosticTarget.wholeVehicleObd,
        messages: [
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x12, 0x34]),
            sourceAddress: DiagnosticSourceAddress('7E8'),
          ),
        ],
      );

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: link,
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        ),
        connectionGeneration: 1,
      );

      expect(
        () => channel.send(
          const DiagnosticRequestId('req-1'),
          ApplicationPdu([0x22, 0x01, 0x00]),
          const Duration(milliseconds: 500),
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.unsupportedTarget,
          ),
        ),
      );
    });

    test('envelope defense: error status with non-empty messages throws DiagnosticLinkException', () async {
      final link = _EnvelopeConfigurableLink(
        status: DiagnosticResponseStatus.error,
        messages: [
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x12, 0x34]),
            sourceAddress: DiagnosticSourceAddress('7E8'),
          ),
        ],
      );

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: link,
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        ),
        connectionGeneration: 1,
      );

      expect(
        () => channel.send(
          const DiagnosticRequestId('req-1'),
          ApplicationPdu([0x22, 0x01, 0x00]),
          const Duration(milliseconds: 500),
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.unsupportedTarget,
          ),
        ),
      );
    });

    test('envelope defense: single-frame message from wrong source throws DiagnosticLinkException', () async {
      final link = _EnvelopeConfigurableLink(
        messages: [
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x12, 0x34]),
            sourceAddress: DiagnosticSourceAddress('7E9'),
          ),
        ],
      );

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: link,
        target: DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        ),
        connectionGeneration: 1,
      );

      expect(
        () => channel.send(
          const DiagnosticRequestId('req-1'),
          ApplicationPdu([0x22, 0x01, 0x00]),
          const Duration(milliseconds: 500),
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.unsupportedTarget,
          ),
        ),
      );
    });

    test('R1: response batch with wrong source first [wrong, good] is rejected fail-closed', () async {
      final link = _MultiFrameDiagnosticLink(
        messages: [
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x55, 0x66]),
            sourceAddress: DiagnosticSourceAddress('7E9'), // Foreign responder frame first
          ),
          DiagnosticMessage(
            pdu: ApplicationPdu([0x62, 0x01, 0x00, 0x12, 0x34]),
            sourceAddress: DiagnosticSourceAddress('7E8'),
          ),
        ],
      );

      final target = DiagnosticTarget.physicalCan(
        requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
        expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
      );

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: link,
        target: target,
        connectionGeneration: link.connectionGeneration,
      );

      expect(
        () => channel.send(
          const DiagnosticRequestId('req-r1-rev'),
          ApplicationPdu([0x22, 0x01, 0x00]),
          const Duration(milliseconds: 500),
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.unsupportedTarget,
          ),
        ),
      );
    });

    test('post-response deadline enforcement: total timeout exceeded returns UdsTransactionTimedOut', () async {
      final stack = await _createProductionStack();
      addTearDown(() => stack.client.disconnect());

      // Adapter delays reply by 150ms
      stack.transport.slowCommands['220100'] = const Duration(milliseconds: 150);

      final target = DiagnosticTarget.physicalCan(
        requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
        expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
      );

      final channel = DiagnosticLinkUdsTransactionChannel(
        link: stack.link,
        target: target,
        connectionGeneration: stack.link.connectionGeneration,
      );

      // Policy totalTimeout (100ms) dominates p2Timeout (50ms), wire delay is 150ms
      final engine = UdsTransactionEngine(
        policy: UdsTransactionPolicy(
          p2Timeout: const Duration(milliseconds: 50),
          p2StarTimeout: const Duration(milliseconds: 500),
          totalTimeout: const Duration(milliseconds: 100),
          busyRepeatDelay: const Duration(milliseconds: 10),
          maxBusyRepeatRetries: 1,
          maxResponsePendingCount: 1,
        ),
      );

      final result = await engine.execute(
        request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
        channel: channel,
        target: target,
        connectionGeneration: stack.link.connectionGeneration,
      );

      expect(result, isA<UdsTransactionTimedOut>());
      final timedOut = result as UdsTransactionTimedOut;
      expect(timedOut.timeoutType, UdsTimeoutType.total);
    });
  });

  group('Issue #13 Slice 4: Wire Contract Matrix (W01~W07)', () {
    test(
      'W01: Clean single-frame 0x22 echo over real TCP Elm327 link',
      () async {
        final stack = await _createProductionTcpStack();
        addTearDown(() => _teardownTcpStack(stack));

        final target = DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        );

        final channel = DiagnosticLinkUdsTransactionChannel(
          link: stack.link,
          target: target,
          connectionGeneration: stack.link.connectionGeneration,
          wireOwnerToken: 'w01-token',
        );

        const engine = UdsTransactionEngine();
        final request = UdsTransactionRequest.readDid(const UdsDid(0x0100));

        final result = await engine.execute(
          request: request,
          channel: channel,
          target: target,
          connectionGeneration: stack.link.connectionGeneration,
          correlationId: 'w01-single-frame',
        );

        expect(result, isA<UdsTransactionSuccess>());
        final success = result as UdsTransactionSuccess;
        expect(success.readResult, isNotNull);
        expect(success.readResult!.did, const UdsDid(0x0100));
        expect(success.readResult!.dataRecord, [0x12, 0x34]);
        expect(success.sourceAddress, DiagnosticSourceAddress('7E8'));
        expect(success.attempts, 1);
        expect(success.retries, 0);

        final wireCommands = stack.transport.commandLog;
        expect(wireCommands, anyOf(contains('ATSH7E0'), contains('ATSH 7E0')));
        expect(wireCommands, contains('220100'));
      },
    );

    test(
      'W02: Clean multi-frame 0x19 DTC response over real TCP Elm327 link',
      () async {
        final stack = await _createProductionTcpStack();
        addTearDown(() => _teardownTcpStack(stack));

        final target = DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        );

        final channel = DiagnosticLinkUdsTransactionChannel(
          link: stack.link,
          target: target,
          connectionGeneration: stack.link.connectionGeneration,
          wireOwnerToken: 'w02-token',
        );

        const engine = UdsTransactionEngine();
        final request = UdsTransactionRequest.reportDtcByStatusMask(
          const UdsDtcStatusMask(0x08),
        );

        final result = await engine.execute(
          request: request,
          channel: channel,
          target: target,
          connectionGeneration: stack.link.connectionGeneration,
          correlationId: 'w02-multi-dtc',
        );

        expect(result, isA<UdsTransactionSuccess>());
        final success = result as UdsTransactionSuccess;
        expect(success.dtcResult, isNotNull);
        expect(success.dtcResult!.availabilityMask.raw, 0x2F);
        expect(success.dtcResult!.records.length, 2);

        final dtc1 = success.dtcResult!.records[0];
        expect(dtc1.code.toHex(prefix: false), '012345');
        expect(dtc1.status.raw, 0x2F);

        final dtc2 = success.dtcResult!.records[1];
        expect(dtc2.code.toHex(prefix: false), '06789A');
        expect(dtc2.status.raw, 0x28);

        expect(success.sourceAddress, DiagnosticSourceAddress('7E8'));
        expect(success.attempts, 1);

        final wireCommands = stack.transport.commandLog;
        expect(wireCommands, anyOf(contains('ATSH7E0'), contains('ATSH 7E0')));
        expect(wireCommands, contains('190208'));
      },
    );

    test(
      'W03: NRC21 busy repeat over real TCP Elm327 link: retries, distinct IDs, succeeds on retry',
      () async {
        final stack = await _createProductionTcpStack();
        addTearDown(() => _teardownTcpStack(stack));

        // First two attempts reply NRC 0x21, third attempt succeeds
        stack.transport.forceReplySequence('220100', [
          '7E8 03 7F 22 21',
          '7E8 03 7F 22 21',
          '7E8 05 62 01 00 12 34',
        ]);

        final target = DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        );

        final channel = DiagnosticLinkUdsTransactionChannel(
          link: stack.link,
          target: target,
          connectionGeneration: stack.link.connectionGeneration,
          wireOwnerToken: 'w03-token',
        );

        final engine = UdsTransactionEngine(
          policy: UdsTransactionPolicy(
            p2Timeout: const Duration(milliseconds: 500),
            p2StarTimeout: const Duration(milliseconds: 500),
            totalTimeout: const Duration(seconds: 3),
            busyRepeatDelay: const Duration(milliseconds: 10),
            maxBusyRepeatRetries: 3,
            maxResponsePendingCount: 1,
          ),
        );

        final request = UdsTransactionRequest.readDid(const UdsDid(0x0100));

        final result = await engine.execute(
          request: request,
          channel: channel,
          target: target,
          connectionGeneration: stack.link.connectionGeneration,
          correlationId: 'w03-run',
        );

        expect(result, isA<UdsTransactionSuccess>());
        final success = result as UdsTransactionSuccess;
        expect(success.attempts, 3);
        expect(success.retries, 2);
        expect(success.readResult?.did, const UdsDid(0x0100));
        expect(success.readResult?.dataRecord, [0x12, 0x34]);

        final sentCommands = stack.transport.commandLog.where((c) => c == '220100').length;
        expect(sentCommands, 3, reason: 'Must send 3 wire requests due to 2 retries');
      },
    );

    test(
      'W04: NRC78 pending over real TCP Elm327 link: zero retry, wire continuation, succeeds on final response',
      () async {
        final stack = await _createProductionTcpStack();
        addTearDown(() => _teardownTcpStack(stack));

        stack.transport.forceReplySequence('220100', [
          '7E8 03 7F 22 78\r7E8 05 62 01 00 99 88',
        ]);

        final target = DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        );

        final channel = DiagnosticLinkUdsTransactionChannel(
          link: stack.link,
          target: target,
          connectionGeneration: stack.link.connectionGeneration,
          wireOwnerToken: 'w04-token',
        );

        const engine = UdsTransactionEngine();
        final request = UdsTransactionRequest.readDid(const UdsDid(0x0100));

        final result = await engine.execute(
          request: request,
          channel: channel,
          target: target,
          connectionGeneration: stack.link.connectionGeneration,
          correlationId: 'w04-pending',
        );

        expect(result, isA<UdsTransactionSuccess>());
        final success = result as UdsTransactionSuccess;
        expect(success.attempts, 1, reason: 'Zero wire retry on NRC 78');
        expect(success.retries, 0);
        expect(success.responsePendingCount, anyOf(0, 1));
        expect(success.readResult?.dataRecord, [0x99, 0x88]);
        expect(success.sourceAddress, DiagnosticSourceAddress('7E8'));

        final sentCommands = stack.transport.commandLog.where((c) => c == '220100').length;
        expect(sentCommands, 1, reason: 'Zero wire retry on NRC 78');
      },
    );

    test(
      'W05: Wrong responder rejection: peer sends non-matching header, rejected fail-closed',
      () async {
        final stack = await _createProductionStack(
          ecus: [
            FakeEcu(
              name: 'ECM',
              requestId: '7E0',
              responseId: '7E8',
              responses: const {
                '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
              },
            ),
          ],
        );
        addTearDown(() => stack.client.disconnect());

        // Wire response arrives with foreign header 7E9 instead of expected 7E8
        stack.transport.forceReplySequence('220100', [
          '7E9 05 62 01 00 12 34',
        ]);

        final target = DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        );

        final channel = DiagnosticLinkUdsTransactionChannel(
          link: stack.link,
          target: target,
          connectionGeneration: stack.link.connectionGeneration,
          wireOwnerToken: 'w05-token',
        );

        const engine = UdsTransactionEngine();
        final request = UdsTransactionRequest.readDid(const UdsDid(0x0100));

        expect(
          () => engine.execute(
            request: request,
            channel: channel,
            target: target,
            connectionGeneration: stack.link.connectionGeneration,
            correlationId: 'w05-wrong-responder',
          ),
          throwsA(
            isA<DiagnosticLinkException>().having(
              (e) => e.kind,
              'kind',
              DiagnosticFailureKind.unsupportedTarget,
            ),
          ),
        );
      },
    );

    test(
      'W06: Response without source header / attribution: fail-closed rejection',
      () async {
        final stack = await _createProductionStack();
        addTearDown(() => stack.client.disconnect());

        // Wire response without header
        stack.transport.forceReplySequence('220100', [
          '62 01 00 12 34',
        ]);

        final target = DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        );

        final channel = DiagnosticLinkUdsTransactionChannel(
          link: stack.link,
          target: target,
          connectionGeneration: stack.link.connectionGeneration,
          wireOwnerToken: 'w06-token',
        );

        const engine = UdsTransactionEngine();
        final request = UdsTransactionRequest.readDid(const UdsDid(0x0100));

        expect(
          () => engine.execute(
            request: request,
            channel: channel,
            target: target,
            connectionGeneration: stack.link.connectionGeneration,
            correlationId: 'w06-no-header',
          ),
          throwsA(
            isA<DiagnosticLinkException>().having(
              (e) => e.kind,
              'kind',
              DiagnosticFailureKind.unsupportedTarget,
            ),
          ),
        );
      },
    );

    test(
      'W07: Generation change during in-flight wire transaction aborts fail-closed',
      () async {
        final stack = await _createProductionStack();
        addTearDown(() => stack.client.disconnect());

        final initialGen = stack.link.connectionGeneration;

        final target = DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        );

        final channel = DiagnosticLinkUdsTransactionChannel(
          link: stack.link,
          target: target,
          connectionGeneration: initialGen,
          wireOwnerToken: 'w07-token',
        );

        // Delay 220100 and disconnect in flight to increment connectionGeneration
        stack.transport.slowCommands['220100'] = const Duration(milliseconds: 60);
        Future<void>.delayed(const Duration(milliseconds: 15), () async {
          await stack.client.disconnect();
        });

        const engine = UdsTransactionEngine();
        final request = UdsTransactionRequest.readDid(const UdsDid(0x0100));

        final result = await engine.execute(
          request: request,
          channel: channel,
          target: target,
          connectionGeneration: initialGen,
          currentConnectionGeneration: () => stack.link.connectionGeneration,
        );

        expect(result, isA<UdsTransactionRetired>());
        final retired = result as UdsTransactionRetired;
        expect(retired.expectedGeneration, initialGen);
      },
    );
  });

  group('ObdSession.runDiagnosticExclusive E2E Wire Integration', () {
    test(
      'Full production path: ObdSession.runDiagnosticExclusive pauses polling, executes UDS read, and restores polling',
      () async {
        final container = await _createContainer({});
        addTearDown(container.dispose);

        final adapter = FakeElm327(
          protocol: BusProtocol.can11,
          ecus: [
            FakeEcu(
              name: 'ECM',
              requestId: '7E0',
              responseId: '7E8',
              responses: const {
                '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x10],
                '010D': [0x41, 0x0D, 0x3C], // Speed = 60 km/h
                '220100': [0x62, 0x01, 0x00, 0xAA, 0xBB],
              },
            ),
          ],
        );

        final session = container.read(obdSessionProvider.notifier);
        expect(await session.connectForTest(adapter, TransportKind.demo), isTrue);
        await _waitForInitialCensus(session);

        // Sync 010D to start normal polling on wire
        session.syncActivePids(const [PidLibrary.vehicleSpeed]);
        await _waitForWireCommand(adapter, '010D');
        final baseline010DCount = adapter.commandLog.where((c) => c == '010D').length;
        expect(baseline010DCount, greaterThan(0));

        final target = DiagnosticTarget.physicalCan(
          requestIdentifier: DiagnosticCanIdentifier.standard(0x7E0),
          expectedResponderIdentifier: DiagnosticCanIdentifier.standard(0x7E8),
        );

        // Execute exclusive UDS transaction via production ObdSession.runReadOnlyUdsTransaction facade
        final result = await session.runReadOnlyUdsTransaction(
          request: UdsTransactionRequest.readDid(const UdsDid(0x0100)),
          target: target,
        );

        expect(result, isA<UdsTransactionSuccess>());
        final success = result as UdsTransactionSuccess;
        expect(success.readResult?.did, const UdsDid(0x0100));
        expect(success.readResult?.dataRecord, [0xAA, 0xBB]);
        expect(success.sourceAddress, DiagnosticSourceAddress('7E8'));

        // Verify UDS request 220100 was transmitted on wire
        final udsCommands = adapter.commandLog.where((c) => c == '220100').length;
        expect(udsCommands, 1, reason: '220100 must be sent on the wire');

        // Verify normal polling resumes after exclusive action completes
        await _waitForWireCommand(adapter, '010D', afterCount: baseline010DCount);
        expect(session.engine?.isRunning, isTrue, reason: 'Polling must be restored after exclusive action completes');
        expect(session.linkOwnership?.displacedRestorationCount, greaterThanOrEqualTo(1));

        await session.disconnect();
      },
    );
  });
}

class _AttributionDisabledDiagnosticLink implements DiagnosticLink {
  _AttributionDisabledDiagnosticLink(this._inner);

  final DiagnosticLink _inner;

  @override
  Set<DiagnosticCapability> get capabilities => _inner.capabilities;

  @override
  int get connectionGeneration => _inner.connectionGeneration;

  @override
  Future<DiagnosticResponse> send(DiagnosticRequest request) async {
    final response = await _inner.send(request);
    return DiagnosticResponse(
      requestId: response.requestId,
      acceptedGeneration: response.acceptedGeneration,
      messages: response.messages,
      status: response.status,
      provenance: DiagnosticResponseProvenance(
        backendId: response.provenance.backendId,
        connectionGeneration: response.provenance.connectionGeneration,
        target: response.provenance.target,
        sourceAttributionAvailable: false, // Forces attribution unavailable
      ),
    );
  }
}

class _MultiFrameDiagnosticLink implements DiagnosticLink {
  _MultiFrameDiagnosticLink({
    required this.messages,
  });

  @override
  final int connectionGeneration = 1;
  final List<DiagnosticMessage> messages;
  final bool sourceAttributionAvailable = true;

  @override
  Set<DiagnosticCapability> get capabilities => const {
        DiagnosticCapability.physicalEcuAddressing,
        DiagnosticCapability.applicationPdu,
      };

  @override
  Future<DiagnosticResponse> send(DiagnosticRequest request) async {
    return DiagnosticResponse(
      requestId: request.id,
      acceptedGeneration: connectionGeneration,
      status: DiagnosticResponseStatus.success,
      provenance: DiagnosticResponseProvenance(
        backendId: 'test-multi',
        connectionGeneration: connectionGeneration,
        target: request.target,
        sourceAttributionAvailable: sourceAttributionAvailable,
      ),
      messages: messages,
    );
  }
}

class _EnvelopeConfigurableLink implements DiagnosticLink {
  _EnvelopeConfigurableLink({
    this.overrideRequestId,
    this.overrideAcceptedGeneration,
    this.overrideProvenanceGeneration,
    this.overrideProvenanceTarget,
    this.status = DiagnosticResponseStatus.success,
    this.messages = const [],
  });

  @override
  final int connectionGeneration = 1;
  final DiagnosticRequestId? overrideRequestId;
  final int? overrideAcceptedGeneration;
  final int? overrideProvenanceGeneration;
  final DiagnosticTarget? overrideProvenanceTarget;
  final DiagnosticResponseStatus status;
  final List<DiagnosticMessage> messages;
  final bool sourceAttributionAvailable = true;

  @override
  Set<DiagnosticCapability> get capabilities => const {
        DiagnosticCapability.physicalEcuAddressing,
        DiagnosticCapability.applicationPdu,
      };

  @override
  Future<DiagnosticResponse> send(DiagnosticRequest request) async {
    return DiagnosticResponse(
      requestId: overrideRequestId ?? request.id,
      acceptedGeneration: overrideAcceptedGeneration ?? connectionGeneration,
      status: status,
      provenance: DiagnosticResponseProvenance(
        backendId: 'test-envelope',
        connectionGeneration:
            overrideProvenanceGeneration ?? connectionGeneration,
        target: overrideProvenanceTarget ?? request.target,
        sourceAttributionAvailable: sourceAttributionAvailable,
      ),
      messages: messages,
    );
  }
}
