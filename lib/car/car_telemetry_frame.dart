/// AA-02 car telemetry projection model (schema v2).
///
/// A read-only, versioned view of the phone's telemetry, built for the
/// one-way Dart -> Kotlin car bridge. Nothing here can reach back into the OBD
/// session: this library only describes values.
library;

import 'package:flutter/foundation.dart';

import '../state/obd_session.dart' show ConnectionPhase;

/// The only schema this producer emits. The Kotlin repository rejects any
/// other version as Incompatible.
const int carTelemetrySchemaVersion = 2;

/// Why a projected signal does or does not carry a number.
enum CarSignalStatus { live, stale, unsupported, unavailable }

/// One projected signal.
///
/// Invariant (by construction): [value] is non-null exactly when [status] is
/// [CarSignalStatus.live]. The only way to get a numeric signal is
/// [CarSignal.live], and that refuses non-finite numbers.
@immutable
final class CarSignal {
  const CarSignal._(this.status, this.value);

  /// A presentable number; a non-finite one becomes [unavailable].
  factory CarSignal.live(double value) =>
      value.isFinite ? CarSignal._(CarSignalStatus.live, value) : unavailable;

  static const CarSignal stale = CarSignal._(CarSignalStatus.stale, null);
  static const CarSignal unsupported = CarSignal._(
    CarSignalStatus.unsupported,
    null,
  );
  static const CarSignal unavailable = CarSignal._(
    CarSignalStatus.unavailable,
    null,
  );

  final CarSignalStatus status;
  final double? value;

  @override
  bool operator ==(Object other) =>
      other is CarSignal && other.status == status && other.value == value;

  @override
  int get hashCode => Object.hash(status, value);

  @override
  String toString() => 'CarSignal($status, $value)';
}

/// DTC / MIL summary as last scanned on this connection.
///
/// Unknown stays unknown: a scan that could not read the MIL keeps
/// [milOn] null and never turns it into "off".
@immutable
final class CarDiagnosticsSummary {
  const CarDiagnosticsSummary.scanned({required this.dtcCount, this.milOn})
    : available = true;

  const CarDiagnosticsSummary._unavailable()
    : available = false,
      milOn = null,
      dtcCount = null;

  static const CarDiagnosticsSummary unavailable =
      CarDiagnosticsSummary._unavailable();

  final bool available;
  final bool? milOn;
  final int? dtcCount;

  @override
  bool operator ==(Object other) =>
      other is CarDiagnosticsSummary &&
      other.available == available &&
      other.milOn == milOn &&
      other.dtcCount == dtcCount;

  @override
  int get hashCode => Object.hash(available, milOn, dtcCount);

  @override
  String toString() =>
      'CarDiagnosticsSummary(available: $available, milOn: $milOn, '
      'dtcCount: $dtcCount)';
}

/// Everything one frame says, before the bridge stamps a sequence on it.
@immutable
final class CarTelemetryProjection {
  const CarTelemetryProjection({
    required this.connectionPhase,
    required this.connectionEpoch,
    required this.lifecycleEpoch,
    required this.producedAtMonotonicUs,
    required this.speedKmh,
    required this.rpm,
    required this.coolantC,
    required this.intakeAirC,
    required this.controlModuleVoltageV,
    required this.mapKpa,
    required this.diagnostics,
    this.engineLoadPct = CarSignal.unavailable,
  });

  final ConnectionPhase connectionPhase;

  /// `ObdSession.generation`: one value per connection attempt.
  final int connectionEpoch;

  /// `ObdSession.pauseEpoch`. Named for the app process lifecycle, not
  /// "foreground": a phone Activity in the background says nothing about
  /// whether the vehicle UI is showing.
  final int lifecycleEpoch;

  /// Producer monotonic time. Evidence only; never host freshness authority.
  final int producedAtMonotonicUs;

  final CarSignal speedKmh;
  final CarSignal rpm;
  final CarSignal coolantC;
  final CarSignal intakeAirC;
  final CarSignal controlModuleVoltageV;
  final CarSignal mapKpa;
  final CarSignal engineLoadPct;

  final CarDiagnosticsSummary diagnostics;

  List<CarSignal> get signals => [
    speedKmh,
    rpm,
    coolantC,
    intakeAirC,
    controlModuleVoltageV,
    mapKpa,
    engineLoadPct,
  ];

  /// Whether going from [previous] to this frame must bypass the normal
  /// 500 ms cadence: first activation, a phase or connection change, or a new
  /// diagnostics summary.
  bool isEdgeFrom(CarTelemetryProjection? previous) =>
      previous == null ||
      previous.connectionPhase != connectionPhase ||
      previous.connectionEpoch != connectionEpoch ||
      previous.diagnostics != diagnostics;
}

/// A projection with the header the bridge assigns at transmit time.
@immutable
final class CarTelemetryFrame {
  const CarTelemetryFrame({required this.sequence, required this.projection})
    : schemaVersion = carTelemetrySchemaVersion;

  final int schemaVersion;
  final int sequence;
  final CarTelemetryProjection projection;
}
