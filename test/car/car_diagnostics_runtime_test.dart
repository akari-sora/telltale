import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/car/car_diagnostics_runtime.dart';
import 'package:torque_obd/car/car_dtc_report.dart';
import 'package:torque_obd/car/car_projection_runtime.dart';
import 'package:torque_obd/car/generated/car_diagnostics.g.dart';
import 'package:torque_obd/state/dtc_scan.dart';

CarDtcReport _testReport({
  int sequence = 1,
  int epoch = 1,
  CarDtcScanPhase phase = CarDtcScanPhase.idle,
  CarDtcVerdict verdict = CarDtcVerdict.notScanned,
  bool coverageComplete = false,
  bool? milOn,
  int? totalCodes,
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

final class _TestDtcNotifier extends DtcScanNotifier {
  void setState(DtcScanState newState) => state = newState;
}

void main() {
  group('CarDiagnosticsCoordinator', () {
    test('deduplicates identical reports without sending redundant messages',
        () async {
      final sent = <CarDtcReportMessage>[];
      var phase = CarDtcScanPhase.idle;

      final coordinator = CarDiagnosticsCoordinator(
        transport: (msg) async => sent.add(msg),
        project: (seq, epoch) => _testReport(
          sequence: seq,
          epoch: epoch,
          phase: phase,
        ),
      );

      coordinator.onInputChanged(connectionEpoch: 1);
      await pumpEventQueue();
      expect(sent.length, equals(1));
      expect(sent.first.reportSequence, equals(1));

      // Identical report should be deduplicated
      coordinator.onInputChanged(connectionEpoch: 1);
      await pumpEventQueue();
      expect(sent.length, equals(1));

      // Changed phase should trigger new report
      phase = CarDtcScanPhase.scanning;
      coordinator.onInputChanged(connectionEpoch: 1);
      await pumpEventQueue();
      expect(sent.length, equals(2));
      expect(sent[1].reportSequence, equals(2));
      expect(sent[1].phase, equals(CarDtcScanPhaseMessage.scanning));

      coordinator.dispose();
    });

    test('resets sequence when connection epoch changes', () async {
      final sent = <CarDtcReportMessage>[];
      final coordinator = CarDiagnosticsCoordinator(
        transport: (msg) async => sent.add(msg),
        project: (seq, epoch) => _testReport(
          sequence: seq,
          epoch: epoch,
          phase: seq == 1 ? CarDtcScanPhase.idle : CarDtcScanPhase.scanning,
        ),
      );

      coordinator.onInputChanged(connectionEpoch: 1);
      await pumpEventQueue();
      expect(sent.first.connectionEpoch, equals(1));
      expect(sent.first.reportSequence, equals(1));

      coordinator.onInputChanged(connectionEpoch: 1);
      await pumpEventQueue();
      expect(sent.last.reportSequence, equals(2));

      // Connection epoch changes to 2
      coordinator.onInputChanged(connectionEpoch: 2);
      await pumpEventQueue();
      expect(sent.last.connectionEpoch, equals(2));
      expect(sent.last.reportSequence, equals(1));

      coordinator.dispose();
    });

    test(
        'publishes new epoch report even if content is identical to last epoch (epoch-edge dedup regression)',
        () async {
      final sent = <CarDtcReportMessage>[];
      final coordinator = CarDiagnosticsCoordinator(
        transport: (msg) async => sent.add(msg),
        project: (seq, epoch) => _testReport(
          sequence: seq,
          epoch: epoch,
          phase: CarDtcScanPhase.idle,
        ),
      );

      // Epoch 1 idle
      coordinator.onInputChanged(connectionEpoch: 1);
      await pumpEventQueue();
      expect(sent.length, equals(1));
      expect(sent.last.connectionEpoch, equals(1));

      // Same idle report on Epoch 2 MUST be published
      coordinator.onInputChanged(connectionEpoch: 2);
      await pumpEventQueue();
      expect(sent.length, equals(2));
      expect(sent.last.connectionEpoch, equals(2));
      expect(sent.last.reportSequence, equals(1));

      coordinator.dispose();
    });
  });

  group('carDiagnosticsRuntimeProvider', () {
    test('returns null when projection is disabled', () {
      final container = ProviderContainer(
        overrides: [
          carProjectionEnabledProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      final coordinator = container.read(carDiagnosticsRuntimeProvider);
      expect(coordinator, isNull);
    });

    test('publishes initial snapshot when enabled and reacts to state changes',
        () async {
      final sent = <CarDtcReportMessage>[];
      final dtcNotifier = _TestDtcNotifier();
      final container = ProviderContainer(
        overrides: [
          carProjectionEnabledProvider.overrideWith((ref) => true),
          dtcScanProvider.overrideWith(() => dtcNotifier),
          carDiagnosticsTransportProvider.overrideWithValue(
            (msg) async => sent.add(msg),
          ),
        ],
      );
      addTearDown(container.dispose);

      final coordinator = container.read(carDiagnosticsRuntimeProvider);
      expect(coordinator, isNotNull);
      await pumpEventQueue();

      // Initial snapshot was sent
      expect(sent.length, equals(1));
      expect(sent.first.schemaVersion, equals(1));

      // Update dtcScanProvider state
      dtcNotifier.setState(const DtcScanState(loading: true));
      await pumpEventQueue();

      expect(sent.length, equals(2));
      expect(sent.last.phase, equals(CarDtcScanPhaseMessage.scanning));
    });
  });
}
