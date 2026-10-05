/// Pure projection from read-only [DtcScanState] to a [CarDtcReport].
library;

import '../obd/dtc/dtc.dart';
import '../obd/pid/pid_library.dart';
import '../state/dtc_scan.dart';
import 'car_dtc_report.dart';

CarDtcKind _mapDtcKind(DtcKind kind) => switch (kind) {
      DtcKind.stored => CarDtcKind.stored,
      DtcKind.pending => CarDtcKind.pending,
      DtcKind.permanent => CarDtcKind.permanent,
    };

CarFreezeSignalKind? _mapPidToFreezeSignal(String pidId) {
  if (pidId == PidLibrary.vehicleSpeed.id) return CarFreezeSignalKind.speedKmh;
  if (pidId == PidLibrary.engineRpm.id) return CarFreezeSignalKind.rpm;
  if (pidId == PidLibrary.coolantTemp.id) return CarFreezeSignalKind.coolantC;
  if (pidId == PidLibrary.intakeAirTemp.id) {
    return CarFreezeSignalKind.intakeAirC;
  }
  if (pidId == PidLibrary.engineLoad.id) {
    return CarFreezeSignalKind.engineLoadPct;
  }
  if (pidId == PidLibrary.manifoldPressure.id) return CarFreezeSignalKind.mapKpa;
  if (pidId == PidLibrary.controlModuleVoltage.id) {
    return CarFreezeSignalKind.controlModuleVoltageV;
  }
  return null;
}

CarDtcScanPhase _projectPhase(DtcScanState dtc) {
  if (dtc.loading) return CarDtcScanPhase.scanning;
  if (dtc.scanBanner != null) return CarDtcScanPhase.interrupted;
  return CarDtcScanPhase.idle;
}

CarDtcVerdict _projectVerdict(DtcScanState dtc) {
  if (!dtc.hasScanned) return CarDtcVerdict.notScanned;
  return switch (dtc.verdict) {
    ScanVerdict.notScanned => CarDtcVerdict.notScanned,
    ScanVerdict.completeClean => CarDtcVerdict.completeClean,
    ScanVerdict.partialClean => CarDtcVerdict.partialClean,
    ScanVerdict.faultsFound => CarDtcVerdict.faultsFound,
    ScanVerdict.failed => CarDtcVerdict.failed,
  };
}

List<CarDtcItem> _projectItems(DtcScanState dtc) {
  final items = <CarDtcItem>[];
  final seen = <(String, CarDtcKind, String?)>{};

  // Complete codes take precedence:
  for (final kind in DtcKind.values) {
    final result = dtc.results[kind];
    if (result == null) continue;
    for (final code in result.codes) {
      final carKind = _mapDtcKind(code.kind);
      final key = (code.code, carKind, code.sourceId);
      if (seen.add(key)) {
        items.add(
          CarDtcItem(
            code: code.code,
            kind: carKind,
            sourceId: code.sourceId,
            manufacturerSpecific: code.isManufacturerSpecific,
            completeness: CarDtcObservationCompleteness.complete,
          ),
        );
      }
    }
  }

  // Partial codes added only if exact identity has not appeared yet:
  for (final kind in DtcKind.values) {
    final result = dtc.results[kind];
    if (result == null) continue;
    for (final code in result.partial) {
      final carKind = _mapDtcKind(code.kind);
      final key = (code.code, carKind, code.sourceId);
      if (seen.add(key)) {
        items.add(
          CarDtcItem(
            code: code.code,
            kind: carKind,
            sourceId: code.sourceId,
            manufacturerSpecific: code.isManufacturerSpecific,
            completeness: CarDtcObservationCompleteness.partial,
          ),
        );
      }
    }
  }

  return List.unmodifiable(items);
}

List<CarFreezeFrame> _projectFreezeFrames(DtcScanState dtc) {
  final frames = <CarFreezeFrame>[];
  for (final ff in dtc.freezeFrames) {
    final readings = <CarFreezeReading>[];
    var omittedCount = 0;
    for (final reading in ff.readings) {
      final signal = _mapPidToFreezeSignal(reading.pid.id);
      if (signal != null) {
        readings.add(CarFreezeReading(signal: signal, value: reading.value));
      } else {
        omittedCount++;
      }
    }
    frames.add(
      CarFreezeFrame(
        sourceId: ff.source,
        frameNumber: ff.frameNumber,
        causeCode: ff.cause.code,
        causeKind: _mapDtcKind(ff.cause.kind),
        causeSourceId: ff.cause.sourceId,
        readings: List.unmodifiable(readings),
        undecodableCount: ff.undecodable,
        unreadCount: ff.unread,
        omittedByProjectionCount: omittedCount,
        contentsUnknown: ff.contentsUnknown,
      ),
    );
  }
  return List.unmodifiable(frames);
}

/// Projects a [DtcScanState] to a [CarDtcReport].
CarDtcReport projectCarDtcReport({
  required DtcScanState dtc,
  required int connectionEpoch,
  required int reportSequence,
}) {
  final coverageComplete = dtc.hasScanned &&
      dtc.unanswered.isEmpty &&
      dtc.optionalNotCovered.values.every((s) => s.isEmpty);

  return CarDtcReport(
    reportSequence: reportSequence,
    connectionEpoch: connectionEpoch,
    phase: _projectPhase(dtc),
    verdict: _projectVerdict(dtc),
    coverageComplete: coverageComplete,
    milOn: dtc.mil?.milOn,
    totalCodes: dtc.hasScanned ? dtc.totalCodes : null,
    freezeFrameReadIncomplete: dtc.freezeFrameUnread,
    items: _projectItems(dtc),
    freezeFrames: _projectFreezeFrames(dtc),
  );
}
