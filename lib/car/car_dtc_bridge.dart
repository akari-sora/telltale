/// The Dart (producer) end of the one-way car diagnostics bridge.
///
/// Single-flight and latest-wins: at most one host call is outstanding, and
/// while it is, only the newest report waits.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'car_dtc_report.dart';
import 'generated/car_diagnostics.g.dart';

/// Delivers one encoded diagnostics report to the host. Production: Pigeon.
typedef CarDiagnosticsTransport = Future<void> Function(CarDtcReportMessage);

/// The production transport over the generated Pigeon host API.
CarDiagnosticsTransport pigeonCarDiagnosticsTransport() {
  final api = CarDiagnosticsHostApi();
  return api.publishDtcReport;
}

final class CarDtcBridge {
  CarDtcBridge({
    required this._transport,
    this._onDisabled,
    void Function(String message)? log,
  }) : _log = log ?? debugPrint;

  final CarDiagnosticsTransport _transport;
  final void Function()? _onDisabled;
  final void Function(String message) _log;

  bool _inFlight = false;
  bool _disabled = false;
  bool _disposed = false;
  bool _loggedTransientError = false;
  CarDtcReport? _pending;

  bool get disabled => _disabled;
  bool get inFlight => _inFlight;

  /// Offers the newest report. Sent now if idle; otherwise replaces
  /// whatever was already waiting and goes out when the current call ends.
  void offer(CarDtcReport report) {
    if (_disabled || _disposed) return;
    if (_inFlight) {
      _pending = report;
      return;
    }
    unawaited(_send(report));
  }

  Future<void> _send(CarDtcReport report) async {
    _inFlight = true;
    try {
      await _transport(encodeCarDtcReport(report));
    } on MissingPluginException {
      _disable('no host handler (MissingPluginException)');
    } on PlatformException catch (error) {
      if (error.code == 'channel-error') {
        _disable('no host handler (channel-error)');
      } else {
        _logTransientOnce('host rejected report: ${error.code}');
      }
    } catch (error) {
      _logTransientOnce('host call failed: ${error.runtimeType}');
    } finally {
      _inFlight = false;
    }
    final next = _pending;
    _pending = null;
    if (next != null && !_disabled && !_disposed) {
      unawaited(_send(next));
    }
  }

  void _disable(String reason) {
    if (_disabled) return;
    _disabled = true;
    _pending = null;
    _log('car diagnostics bridge disabled: $reason');
    _onDisabled?.call();
  }

  void _logTransientOnce(String message) {
    if (_loggedTransientError) return;
    _loggedTransientError = true;
    _log('car diagnostics bridge: $message');
  }

  void dispose() {
    _disposed = true;
    _pending = null;
  }
}

CarDtcKindMessage _encodeKind(CarDtcKind kind) => switch (kind) {
      CarDtcKind.stored => CarDtcKindMessage.stored,
      CarDtcKind.pending => CarDtcKindMessage.pending,
      CarDtcKind.permanent => CarDtcKindMessage.permanent,
    };

CarDtcObservationCompletenessMessage _encodeCompleteness(
  CarDtcObservationCompleteness completeness,
) =>
    switch (completeness) {
      CarDtcObservationCompleteness.complete =>
        CarDtcObservationCompletenessMessage.complete,
      CarDtcObservationCompleteness.partial =>
        CarDtcObservationCompletenessMessage.partial,
    };

CarDtcVerdictMessage _encodeVerdict(CarDtcVerdict verdict) => switch (verdict) {
      CarDtcVerdict.notScanned => CarDtcVerdictMessage.notScanned,
      CarDtcVerdict.completeClean => CarDtcVerdictMessage.completeClean,
      CarDtcVerdict.partialClean => CarDtcVerdictMessage.partialClean,
      CarDtcVerdict.faultsFound => CarDtcVerdictMessage.faultsFound,
      CarDtcVerdict.failed => CarDtcVerdictMessage.failed,
    };

CarDtcScanPhaseMessage _encodePhase(CarDtcScanPhase phase) => switch (phase) {
      CarDtcScanPhase.idle => CarDtcScanPhaseMessage.idle,
      CarDtcScanPhase.scanning => CarDtcScanPhaseMessage.scanning,
      CarDtcScanPhase.interrupted => CarDtcScanPhaseMessage.interrupted,
    };

CarFreezeSignalKindMessage _encodeFreezeSignal(CarFreezeSignalKind signal) =>
    switch (signal) {
      CarFreezeSignalKind.speedKmh => CarFreezeSignalKindMessage.speedKmh,
      CarFreezeSignalKind.rpm => CarFreezeSignalKindMessage.rpm,
      CarFreezeSignalKind.coolantC => CarFreezeSignalKindMessage.coolantC,
      CarFreezeSignalKind.intakeAirC => CarFreezeSignalKindMessage.intakeAirC,
      CarFreezeSignalKind.engineLoadPct =>
        CarFreezeSignalKindMessage.engineLoadPct,
      CarFreezeSignalKind.mapKpa => CarFreezeSignalKindMessage.mapKpa,
      CarFreezeSignalKind.controlModuleVoltageV =>
        CarFreezeSignalKindMessage.controlModuleVoltageV,
    };

CarDtcReportMessage encodeCarDtcReport(CarDtcReport report) {
  final items = report.items
      .map(
        (i) => CarDtcItemMessage(
          code: i.code,
          kind: _encodeKind(i.kind),
          sourceId: i.sourceId,
          manufacturerSpecific: i.manufacturerSpecific,
          completeness: _encodeCompleteness(i.completeness),
        ),
      )
      .toList();

  final freezeFrames = report.freezeFrames
      .map(
        (ff) => CarFreezeFrameMessage(
          sourceId: ff.sourceId,
          frameNumber: ff.frameNumber,
          causeCode: ff.causeCode,
          causeKind: _encodeKind(ff.causeKind),
          causeSourceId: ff.causeSourceId,
          readings: ff.readings
              .map(
                (r) => CarFreezeReadingMessage(
                  signal: _encodeFreezeSignal(r.signal),
                  value: r.value,
                ),
              )
              .toList(),
          undecodableCount: ff.undecodableCount,
          unreadCount: ff.unreadCount,
          omittedByProjectionCount: ff.omittedByProjectionCount,
          contentsUnknown: ff.contentsUnknown,
        ),
      )
      .toList();

  return CarDtcReportMessage(
    schemaVersion: report.schemaVersion,
    reportSequence: report.reportSequence,
    connectionEpoch: report.connectionEpoch,
    phase: _encodePhase(report.phase),
    verdict: _encodeVerdict(report.verdict),
    coverageComplete: report.coverageComplete,
    milOn: report.milOn,
    totalCodes: report.totalCodes,
    freezeFrameReadIncomplete: report.freezeFrameReadIncomplete,
    items: items,
    freezeFrames: freezeFrames,
  );
}
