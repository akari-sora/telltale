import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:torque_obd/diagnostics/can/can_endpoint.dart';
import 'package:torque_obd/diagnostics/can/can_io_contract.dart';
import 'package:torque_obd/diagnostics/can/can_io_core.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';

import '../../support/fake_can_pdu_backend.dart';

void main() {
  group('CanIoBoundaryTests', () {
    late CanEndpoint endpoint;
    late FakeCanPduBackend backend;
    late CanIoCoordinator coordinator;
    final wireOwner = Object();
    final stdTx = DiagnosticCanIdentifier.standard(0x7E0);
    final stdRx = DiagnosticCanIdentifier.standard(0x7E8);
    final validTarget = DiagnosticTarget.physicalCan(
      requestIdentifier: stdTx,
      expectedResponderIdentifier: stdRx,
    );

    setUp(() {
      endpoint = CanEndpoint(
        interfaceName: 'vcan0',
        generation: 1,
        physicalTxId: stdTx,
        physicalRxId: stdRx,
      );
      backend = FakeCanPduBackend();
      coordinator = CanIoCoordinator(
        endpoint: endpoint,
        backend: backend,
      );
    });

    tearDown(() async {
      await coordinator.close();
    });

    CanReadBinding createBinding(List<int> pduBytes) {
      final req = DiagnosticRequest(
        id: const DiagnosticRequestId('req_boundary'),
        pdu: ApplicationPdu(pduBytes),
        target: validTarget,
        requiredCapabilities: {DiagnosticCapability.rawCanFrame},
        connectionGeneration: 1,
        ownership: const DiagnosticOwnership(mode: DiagnosticOwnershipMode.exclusive),
      );
      return CanReadBinding.fromUdsRequest(
        request: req,
        endpoint: endpoint,
        wireOwnerToken: wireOwner,
      );
    }

    test('L05: PDU size boundaries (1..4095 allowed, 4096 rejected)', () {
      expect(() => ApplicationPdu([]), throwsArgumentError);
      expect(ApplicationPdu([0x01]).length, 1);
      expect(ApplicationPdu(List.filled(7, 0xAA)).length, 7);
      expect(ApplicationPdu(List.filled(8, 0x55)).length, 8);
      expect(ApplicationPdu(List.filled(4095, 0x00)).length, 4095);

      // IsoTpPayload enforces <= 4095 bytes
      expect(() => IsoTpPayload(List.filled(4096, 0x00)), throwsArgumentError);
    });

    test('L05: Buffered observations limit (strictly max 32 observations, 33 rejected)', () async {
      final binding = createBinding([0x22, 0x01, 0x00]);

      // Enqueue 33 observations of 1 byte each
      for (var i = 0; i < 33; i++) {
        backend.enqueueSimpleObservation(
          payload: [0x55],
          sourceId: stdRx,
        );
      }

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          // Read 32 observations successfully
          for (var i = 0; i < 32; i++) {
            await lease.receiveNext(const Duration(seconds: 1));
          }
          // 33rd observation must violate the buffer ceiling
          await lease.receiveNext(const Duration(seconds: 1));
        },
      );

      expect(outcome, isA<CanLeaseTransportFailure<void>>());
      expect(
        (outcome as CanLeaseTransportFailure<void>).error.toString(),
        contains('Buffered observations ceiling exceeded'),
      );
    });

    test('C02 / Exact Boundary: 16, 17, 31, 32 succeed, 33 rejected, backend read count is 32', () async {
      final binding = createBinding([0x22, 0x01, 0x00]);

      // Enqueue 35 observations of 1 byte each
      for (var i = 0; i < 35; i++) {
        backend.enqueueSimpleObservation(
          payload: [0x55],
          sourceId: stdRx,
        );
      }

      int readCount = 0;
      Object? failureError;

      final outcome = await coordinator.withReadLease<int>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          for (var i = 1; i <= 35; i++) {
            try {
              final obs = await lease.receiveNext(const Duration(seconds: 1));
              expect(obs.payload, [0x55]);
              readCount = i;
            } catch (e) {
              failureError = e;
              rethrow;
            }
          }
          return readCount;
        },
      );

      expect(outcome, isA<CanLeaseTransportFailure<int>>());
      expect(
        failureError.toString(),
        contains('Buffered observations ceiling exceeded'),
      );
      // Strictly verify 16, 17, 31, and 32 succeeded, and 33 failed
      expect(readCount, 32, reason: 'Must successfully complete 32 observations');
      // The 33rd attempt must fail before dispatching backend read, so backend read count is exactly 32
      expect(backend.readCallCount, 32, reason: 'Backend read count must be exactly 32');
    });

    test('L05: Aggregate buffered bytes limit (strictly max 4096 bytes, 4097 rejected)', () async {
      final binding = createBinding([0x22, 0x01, 0x00]);

      // Enqueue two observations: 4095 bytes + 2 bytes = 4097 bytes (exceeds 4096 ceiling)
      backend.enqueueSimpleObservation(
        payload: List.filled(4095, 0xAA),
        sourceId: stdRx,
      );
      backend.enqueueSimpleObservation(
        payload: [0x01, 0x02],
        sourceId: stdRx,
      );

      final outcome = await coordinator.withReadLease<void>(
        binding: binding,
        budget: CanIoBudget(),
        cancellation: DiagnosticCancellation.none,
        action: (lease) async {
          await lease.receiveNext(const Duration(seconds: 1));
          await lease.receiveNext(const Duration(seconds: 1));
        },
      );

      expect(outcome, isA<CanLeaseTransportFailure<void>>());
      expect(
        (outcome as CanLeaseTransportFailure<void>).error.toString(),
        contains('Aggregate buffered bytes ceiling exceeded'),
      );
    });

    test('L12: Validates literal fixture test cases from literal_pdu_cases.json', () {
      final file = File('test/fixtures/ws10_s1/literal_pdu_cases.json');
      expect(file.existsSync(), isTrue, reason: 'literal_pdu_cases.json must exist');

      final content = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(content['schema_version'], 1);
      expect(content['milestone'], 'WS10-S1');

      final validCases = content['canonical_valid_cases'] as List<dynamic>;
      expect(validCases.length, 4);

      for (final c in validCases) {
        final bytes = (c['pdu_bytes'] as List<dynamic>).cast<int>();
        final binding = createBinding(bytes);
        expect(binding.canonicalPdu.bytes, bytes);
        expect(binding.canonicalPdu.length, c['length']);
      }

      final rejectedCases = content['rejected_illegal_cases'] as List<dynamic>;
      expect(rejectedCases.length, 10);

      for (final c in rejectedCases) {
        final bytes = (c['pdu_bytes'] as List<dynamic>).cast<int>();
        expect(
          () => createBinding(bytes),
          throwsArgumentError,
          reason: 'Expected rejection for test case: ${c['id']}',
        );
      }
    });
  });
}
