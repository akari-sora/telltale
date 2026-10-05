/// AA-04 car diagnostics and DTC projection model (schema v1).
///
/// A read-only, versioned view of the phone's diagnostic scan results,
/// built for the one-way Dart -> Kotlin car bridge.
library;

import 'package:flutter/foundation.dart';

/// The only schema this diagnostics producer emits.
const int carDiagnosticsSchemaVersion = 1;

enum CarDtcKind {
  stored,
  pending,
  permanent,
}

enum CarDtcObservationCompleteness {
  complete,
  partial,
}

enum CarDtcVerdict {
  notScanned,
  completeClean,
  partialClean,
  faultsFound,
  failed,
}

enum CarDtcScanPhase {
  idle,
  scanning,
  interrupted,
}

@immutable
final class CarDtcItem {
  const CarDtcItem({
    required this.code,
    required this.kind,
    this.sourceId,
    required this.manufacturerSpecific,
    required this.completeness,
  });

  final String code;
  final CarDtcKind kind;
  final String? sourceId;
  final bool manufacturerSpecific;
  final CarDtcObservationCompleteness completeness;

  @override
  bool operator ==(Object other) =>
      other is CarDtcItem &&
      other.code == code &&
      other.kind == kind &&
      other.sourceId == sourceId &&
      other.manufacturerSpecific == manufacturerSpecific &&
      other.completeness == completeness;

  @override
  int get hashCode => Object.hash(
        code,
        kind,
        sourceId,
        manufacturerSpecific,
        completeness,
      );

  @override
  String toString() =>
      'CarDtcItem($code, $kind, source: $sourceId, $completeness)';
}

enum CarFreezeSignalKind {
  speedKmh,
  rpm,
  coolantC,
  intakeAirC,
  engineLoadPct,
  mapKpa,
  controlModuleVoltageV,
}

@immutable
final class CarFreezeReading {
  const CarFreezeReading({
    required this.signal,
    required this.value,
  });

  final CarFreezeSignalKind signal;
  final double value;

  @override
  bool operator ==(Object other) =>
      other is CarFreezeReading &&
      other.signal == signal &&
      other.value == value;

  @override
  int get hashCode => Object.hash(signal, value);

  @override
  String toString() => 'CarFreezeReading($signal, $value)';
}

@immutable
final class CarFreezeFrame {
  const CarFreezeFrame({
    required this.sourceId,
    required this.frameNumber,
    required this.causeCode,
    required this.causeKind,
    this.causeSourceId,
    required this.readings,
    required this.undecodableCount,
    required this.unreadCount,
    required this.omittedByProjectionCount,
    required this.contentsUnknown,
  });

  final String sourceId;
  final int frameNumber;
  final String causeCode;
  final CarDtcKind causeKind;
  final String? causeSourceId;
  final List<CarFreezeReading> readings;
  final int undecodableCount;
  final int unreadCount;
  final int omittedByProjectionCount;
  final bool contentsUnknown;

  @override
  bool operator ==(Object other) =>
      other is CarFreezeFrame &&
      other.sourceId == sourceId &&
      other.frameNumber == frameNumber &&
      other.causeCode == causeCode &&
      other.causeKind == causeKind &&
      other.causeSourceId == causeSourceId &&
      listEquals(other.readings, readings) &&
      other.undecodableCount == undecodableCount &&
      other.unreadCount == unreadCount &&
      other.omittedByProjectionCount == omittedByProjectionCount &&
      other.contentsUnknown == contentsUnknown;

  @override
  int get hashCode => Object.hash(
        sourceId,
        frameNumber,
        causeCode,
        causeKind,
        causeSourceId,
        Object.hashAll(readings),
        undecodableCount,
        unreadCount,
        omittedByProjectionCount,
        contentsUnknown,
      );

  @override
  String toString() =>
      'CarFreezeFrame($sourceId, cause: $causeCode, readings: ${readings.length})';
}

@immutable
final class CarDtcReport {
  const CarDtcReport({
    required this.reportSequence,
    required this.connectionEpoch,
    required this.phase,
    required this.verdict,
    required this.coverageComplete,
    this.milOn,
    this.totalCodes,
    required this.freezeFrameReadIncomplete,
    required this.items,
    required this.freezeFrames,
  }) : schemaVersion = carDiagnosticsSchemaVersion;

  final int schemaVersion;
  final int reportSequence;
  final int connectionEpoch;

  final CarDtcScanPhase phase;
  final CarDtcVerdict verdict;
  final bool coverageComplete;

  final bool? milOn;
  final int? totalCodes;

  final bool freezeFrameReadIncomplete;

  final List<CarDtcItem> items;
  final List<CarFreezeFrame> freezeFrames;

  @override
  bool operator ==(Object other) =>
      other is CarDtcReport &&
      other.schemaVersion == schemaVersion &&
      other.reportSequence == reportSequence &&
      other.connectionEpoch == connectionEpoch &&
      other.phase == phase &&
      other.verdict == verdict &&
      other.coverageComplete == coverageComplete &&
      other.milOn == milOn &&
      other.totalCodes == totalCodes &&
      other.freezeFrameReadIncomplete == freezeFrameReadIncomplete &&
      listEquals(other.items, items) &&
      listEquals(other.freezeFrames, freezeFrames);

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        reportSequence,
        connectionEpoch,
        phase,
        verdict,
        coverageComplete,
        milOn,
        totalCodes,
        freezeFrameReadIncomplete,
        Object.hashAll(items),
        Object.hashAll(freezeFrames),
      );

  @override
  String toString() =>
      'CarDtcReport(seq: $reportSequence, epoch: $connectionEpoch, phase: $phase, '
      'verdict: $verdict, totalCodes: $totalCodes, items: ${items.length})';
}
