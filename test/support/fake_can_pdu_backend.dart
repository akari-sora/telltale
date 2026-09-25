import 'dart:async';

import 'package:torque_obd/diagnostics/can/can_endpoint.dart';
import 'package:torque_obd/diagnostics/can/can_io_contract.dart';
import 'package:torque_obd/diagnostics/can/can_io_core.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';

/// Fake in-memory implementation of [CanPduBackend] for testing WS10-S1 contracts.
class FakeCanPduBackend implements CanPduBackend {
  final List<CanPduWriteRecord> writeLog = [];
  final List<CanBackendObservation> incomingQueue = [];

  CanSendDisposition dispositionToReturn = CanSendDisposition.submitted;
  Duration simulatedWriteDelay = Duration.zero;
  Duration simulatedReadDelay = Duration.zero;
  Object? simulatedWriteError;
  Object? simulatedReadError;

  int drainCallCount = 0;
  Duration? lastDrainTimeout;
  Duration simulatedDrainDelay = Duration.zero;
  Object? simulatedDrainError;
  Future<void> Function()? simulatedDrainCallback;
  int closeCallCount = 0;
  bool isClosed = false;
  Duration simulatedCloseDelay = Duration.zero;
  Object? simulatedCloseError;
  CanWriteReceipt? customReceiptToReturn;
  int readCallCount = 0;

  void enqueueObservation(CanBackendObservation observation) {
    incomingQueue.add(observation);
  }

  void enqueueSimpleObservation({
    required List<int> payload,
    required DiagnosticCanIdentifier sourceId,
    DateTime? timestamp,
  }) {
    incomingQueue.add(
      CanBackendObservation(
        payload: payload,
        sourceId: sourceId,
        timestamp: timestamp ?? DateTime.now(),
        sequenceNumber: incomingQueue.length,
      ),
    );
  }

  @override
  Future<CanWriteReceipt> writePdu({
    required CanEndpoint endpoint,
    required ApplicationPdu pdu,
    required DiagnosticRequestId attemptId,
    required Duration phaseBudget,
    DiagnosticCancellation? cancellation,
  }) async {
    if (isClosed) {
      throw StateError('Cannot write to closed backend.');
    }
    if (cancellation?.isCancelled ?? false) {
      return CanWriteReceipt(
        attemptId: attemptId,
        timestamp: DateTime.now(),
        disposition: CanSendDisposition.provenNotSubmitted,
        bytesWritten: 0,
      );
    }
    if (simulatedWriteDelay > Duration.zero) {
      await Future<void>.delayed(simulatedWriteDelay);
    }
    if (simulatedWriteError != null) {
      throw simulatedWriteError!;
    }

    final record = CanPduWriteRecord(
      endpoint: endpoint,
      pdu: pdu,
      attemptId: attemptId,
      timestamp: DateTime.now(),
      disposition: dispositionToReturn,
    );
    writeLog.add(record);

    final bytesWritten =
        dispositionToReturn == CanSendDisposition.provenNotSubmitted
            ? 0
            : (dispositionToReturn == CanSendDisposition.partialOrUnknown
                ? pdu.length ~/ 2
                : pdu.length);

    if (customReceiptToReturn != null) {
      return customReceiptToReturn!;
    }

    return CanWriteReceipt(
      attemptId: attemptId,
      timestamp: record.timestamp,
      disposition: dispositionToReturn,
      bytesWritten: bytesWritten,
    );
  }

  @override
  Future<CanBackendObservation> readObservation({
    required CanEndpoint endpoint,
    required Duration phaseBudget,
    DiagnosticCancellation? cancellation,
  }) async {
    readCallCount++;
    if (isClosed) {
      throw StateError('Cannot read from closed backend.');
    }
    if (cancellation?.isCancelled ?? false) {
      throw StateError('Read cancelled.');
    }
    if (simulatedReadDelay > Duration.zero) {
      await Future<void>.delayed(simulatedReadDelay);
    }
    if (simulatedReadError != null) {
      throw simulatedReadError!;
    }
    if (incomingQueue.isEmpty) {
      throw TimeoutException('No observations available in queue within phase budget.');
    }
    return incomingQueue.removeAt(0);
  }

  @override
  Future<void> drain({Duration? timeout}) async {
    drainCallCount++;
    lastDrainTimeout = timeout;
    if (simulatedDrainCallback != null) {
      await simulatedDrainCallback!();
    }
    if (simulatedDrainDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDrainDelay);
    }
    if (simulatedDrainError != null) {
      throw simulatedDrainError!;
    }
    incomingQueue.clear();
  }

  @override
  Future<void> close() async {
    closeCallCount++;
    isClosed = true;
    incomingQueue.clear();
    if (simulatedCloseDelay > Duration.zero) {
      await Future<void>.delayed(simulatedCloseDelay);
    }
    if (simulatedCloseError != null) {
      throw simulatedCloseError!;
    }
  }
}

class CanPduWriteRecord {
  final CanEndpoint endpoint;
  final ApplicationPdu pdu;
  final DiagnosticRequestId attemptId;
  final DateTime timestamp;
  final CanSendDisposition disposition;

  const CanPduWriteRecord({
    required this.endpoint,
    required this.pdu,
    required this.attemptId,
    required this.timestamp,
    required this.disposition,
  });
}
