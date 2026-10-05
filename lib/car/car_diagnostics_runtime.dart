/// Riverpod wiring for the AA-04 car diagnostics and DTC projection.
///
/// Event-driven: publishes only when scan state or connection epoch changes.
/// Single-flight, latest-wins. No timer, no keepalive.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/dtc_scan.dart';
import '../state/obd_session.dart';
import 'car_dtc_bridge.dart';
import 'car_dtc_projector.dart';
import 'car_dtc_report.dart';
import 'car_projection_runtime.dart';

/// The diagnostics host transport provider. Overridable in tests.
final carDiagnosticsTransportProvider = Provider<CarDiagnosticsTransport>(
  (ref) => pigeonCarDiagnosticsTransport(),
);

final class CarDiagnosticsCoordinator {
  CarDiagnosticsCoordinator({
    required this._project,
    required CarDiagnosticsTransport transport,
    void Function(String message)? log,
  }) : _bridge = CarDtcBridge(transport: transport, log: log);

  final CarDtcReport Function(int sequence, int epoch) _project;
  final CarDtcBridge _bridge;

  int _reportSequence = 0;
  int _lastEpoch = -1;
  CarDtcReport? _lastReport;

  void onInputChanged({required int connectionEpoch}) {
    if (connectionEpoch != _lastEpoch) {
      _lastEpoch = connectionEpoch;
      _reportSequence = 0;
      _lastReport = null;
    }
    final next = _project(++_reportSequence, connectionEpoch);
    if (_lastReport != null &&
        _lastReport!.verdict == next.verdict &&
        _lastReport!.phase == next.phase &&
        _lastReport!.coverageComplete == next.coverageComplete &&
        _lastReport!.milOn == next.milOn &&
        _lastReport!.totalCodes == next.totalCodes &&
        _lastReport!.freezeFrameReadIncomplete ==
            next.freezeFrameReadIncomplete &&
        listEquals(_lastReport!.items, next.items) &&
        listEquals(_lastReport!.freezeFrames, next.freezeFrames)) {
      _reportSequence--;
      return;
    }
    _lastReport = next;
    _bridge.offer(next);
  }

  void dispose() {
    _bridge.dispose();
  }
}

final carDiagnosticsRuntimeProvider =
    Provider<CarDiagnosticsCoordinator?>((ref) {
  if (!ref.watch(carProjectionEnabledProvider)) return null;

  final coordinator = CarDiagnosticsCoordinator(
    transport: ref.read(carDiagnosticsTransportProvider),
    project: (sequence, epoch) {
      return projectCarDtcReport(
        dtc: ref.read(dtcScanProvider),
        connectionEpoch: epoch,
        reportSequence: sequence,
      );
    },
  );

  void notify() {
    final session = ref.read(obdSessionProvider.notifier);
    coordinator.onInputChanged(connectionEpoch: session.generation);
  }

  ref.listen(dtcScanProvider, (_, _) => notify());
  ref.listen(obdSessionProvider, (_, _) => notify());
  ref.onDispose(coordinator.dispose);

  // Send initial snapshot
  notify();

  return coordinator;
});
