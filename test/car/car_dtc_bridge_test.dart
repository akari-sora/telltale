import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/car/car_dtc_bridge.dart';
import 'package:torque_obd/car/car_dtc_report.dart';
import 'package:torque_obd/car/generated/car_diagnostics.g.dart';

CarDtcReport _testReport({
  int sequence = 1,
  int epoch = 1,
  CarDtcScanPhase phase = CarDtcScanPhase.idle,
  CarDtcVerdict verdict = CarDtcVerdict.completeClean,
  bool coverageComplete = true,
  bool? milOn = false,
  int? totalCodes = 0,
  List<CarDtcItem> items = const [],
  List<CarFreezeFrame> freezeFrames = const [],
}) =>
    CarDtcReport(
      reportSequence: sequence,
      connectionEpoch: epoch,
      phase: phase,
      verdict: verdict,
      coverageComplete: coverageComplete,
      milOn: milOn,
      totalCodes: totalCodes,
      freezeFrameReadIncomplete: false,
      items: items,
      freezeFrames: freezeFrames,
    );

final class _GatedTransport {
  final List<CarDtcReportMessage> sent = [];
  final List<Completer<void>> _gates = [];

  Future<void> call(CarDtcReportMessage message) {
    sent.add(message);
    final gate = Completer<void>();
    _gates.add(gate);
    return gate.future;
  }

  void completeNext() => _gates.removeAt(0).complete();

  void failNext(Object error) => _gates.removeAt(0).completeError(error);

  int get outstanding => _gates.length;
}

void main() {
  group('CarDtcBridge encoding', () {
    test('encodes all fields into CarDtcReportMessage with schemaVersion 1', () {
      final report = _testReport(
        sequence: 42,
        epoch: 7,
        phase: CarDtcScanPhase.scanning,
        verdict: CarDtcVerdict.faultsFound,
        coverageComplete: false,
        milOn: true,
        totalCodes: 1,
        items: const [
          CarDtcItem(
            code: 'P0301',
            kind: CarDtcKind.stored,
            sourceId: '7E8',
            manufacturerSpecific: false,
            completeness: CarDtcObservationCompleteness.complete,
          ),
        ],
        freezeFrames: const [
          CarFreezeFrame(
            sourceId: '7E8',
            frameNumber: 0,
            causeCode: 'P0301',
            causeKind: CarDtcKind.stored,
            causeSourceId: '7E8',
            readings: [
              CarFreezeReading(
                signal: CarFreezeSignalKind.coolantC,
                value: 102.0,
              ),
            ],
            undecodableCount: 0,
            unreadCount: 0,
            omittedByProjectionCount: 0,
            contentsUnknown: false,
          ),
        ],
      );

      final message = encodeCarDtcReport(report);
      expect(message.schemaVersion, equals(1));
      expect(message.reportSequence, equals(42));
      expect(message.connectionEpoch, equals(7));
      expect(message.phase, equals(CarDtcScanPhaseMessage.scanning));
      expect(message.verdict, equals(CarDtcVerdictMessage.faultsFound));
      expect(message.coverageComplete, isFalse);
      expect(message.milOn, isTrue);
      expect(message.totalCodes, equals(1));
      expect(message.items.length, equals(1));
      expect(message.items.first.code, equals('P0301'));
      expect(message.items.first.kind, equals(CarDtcKindMessage.stored));
      expect(
        message.items.first.completeness,
        equals(CarDtcObservationCompletenessMessage.complete),
      );
      expect(message.freezeFrames.length, equals(1));
      expect(message.freezeFrames.first.causeCode, equals('P0301'));
      expect(
        message.freezeFrames.first.readings.first.signal,
        equals(CarFreezeSignalKindMessage.coolantC),
      );
      expect(message.freezeFrames.first.readings.first.value, equals(102.0));
    });
  });

  group('CarDtcBridge flow control (single-flight and latest-wins)', () {
    test('single-flight sends immediately when idle', () async {
      final transport = _GatedTransport();
      final bridge = CarDtcBridge(transport: transport.call);

      bridge.offer(_testReport(sequence: 1));
      expect(transport.sent.length, equals(1));
      expect(transport.outstanding, equals(1));
      expect(bridge.inFlight, isTrue);

      transport.completeNext();
      await pumpEventQueue();

      expect(bridge.inFlight, isFalse);
    });

    test('latest-wins coalesces intermediate offers while in flight', () async {
      final transport = _GatedTransport();
      final bridge = CarDtcBridge(transport: transport.call);

      bridge.offer(_testReport(sequence: 1));
      expect(transport.sent.length, equals(1));

      // In flight: queue sequence 2, then replace with sequence 3
      bridge.offer(_testReport(sequence: 2));
      bridge.offer(_testReport(sequence: 3));

      expect(transport.sent.length, equals(1)); // Still only report 1 on wire

      // Complete report 1
      transport.completeNext();
      await pumpEventQueue();

      // Report 3 should be on wire now, report 2 dropped
      expect(transport.sent.length, equals(2));
      expect(transport.sent[1].reportSequence, equals(3));

      transport.completeNext();
      await pumpEventQueue();

      expect(bridge.inFlight, isFalse);
    });

    test('MissingPluginException permanently disables bridge', () async {
      final transport = _GatedTransport();
      var disabledNotified = false;
      final bridge = CarDtcBridge(
        transport: transport.call,
        onDisabled: () => disabledNotified = true,
      );

      bridge.offer(_testReport(sequence: 1));
      transport.failNext(MissingPluginException());
      await pumpEventQueue();

      expect(bridge.disabled, isTrue);
      expect(disabledNotified, isTrue);

      // Subsequent offers must be ignored
      bridge.offer(_testReport(sequence: 2));
      expect(transport.sent.length, equals(1));
    });

    test('channel-error PlatformException permanently disables bridge',
        () async {
      final transport = _GatedTransport();
      var disabledNotified = false;
      final bridge = CarDtcBridge(
        transport: transport.call,
        onDisabled: () => disabledNotified = true,
      );

      bridge.offer(_testReport(sequence: 1));
      transport.failNext(PlatformException(code: 'channel-error'));
      await pumpEventQueue();

      expect(bridge.disabled, isTrue);
      expect(disabledNotified, isTrue);
    });

    test('transient error does not disable bridge', () async {
      final transport = _GatedTransport();
      var disabledNotified = false;
      final bridge = CarDtcBridge(
        transport: transport.call,
        onDisabled: () => disabledNotified = true,
      );

      bridge.offer(_testReport(sequence: 1));
      transport.failNext(PlatformException(code: 'timeout'));
      await pumpEventQueue();

      expect(bridge.disabled, isFalse);
      expect(disabledNotified, isFalse);

      // Can send next report
      bridge.offer(_testReport(sequence: 2));
      expect(transport.sent.length, equals(2));
      transport.completeNext();
      await pumpEventQueue();
    });

    test('dispose cancels pending and prevents offers', () async {
      final transport = _GatedTransport();
      final bridge = CarDtcBridge(transport: transport.call);

      bridge.offer(_testReport(sequence: 1));
      bridge.offer(_testReport(sequence: 2));

      bridge.dispose();

      transport.completeNext();
      await pumpEventQueue();

      // Pending report 2 must not be sent after dispose
      expect(transport.sent.length, equals(1));
    });
  });
}
