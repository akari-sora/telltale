/// Pure projection from read-only app state to a [CarTelemetryProjection].
///
/// No provider access, no clock reads beyond what the caller passes in, no
/// mutation: given the same inputs it always yields the same projection.
library;

import '../obd/pid/pid.dart';
import '../obd/pid/pid_library.dart';
import '../obd/telemetry.dart';
import '../state/dtc_scan.dart';
import '../state/obd_session.dart' show ConnectionPhase;
import 'car_telemetry_frame.dart';

/// The six schema-v1 signals and the existing PID each one reads.
///
/// Boost is deliberately absent: deriving MAP - baro here would copy a domain
/// formula into the car layer. Adapter supply voltage is absent too; PID 0142
/// is the only voltage with a vehicle provenance.
abstract final class CarTelemetrySignalSources {
  static const Pid speedKmh = PidLibrary.vehicleSpeed; // 010D
  static const Pid rpm = PidLibrary.engineRpm; // 010C
  static const Pid coolantC = PidLibrary.coolantTemp; // 0105
  static const Pid intakeAirC = PidLibrary.intakeAirTemp; // 010F
  static const Pid controlModuleVoltageV =
      PidLibrary.controlModuleVoltage; // 0142
  static const Pid mapKpa = PidLibrary.manifoldPressure; // 010B
}

/// Projects one PID.
///
/// - Only a `connected` session may produce [CarSignalStatus.live]; any other
///   phase turns a retained reading into [CarSignal.stale] and claims nothing
///   about the vehicle otherwise.
/// - [PidFault.unsupported] is the only state that becomes
///   [CarSignal.unsupported].
/// - Any other fault, a missing reading, or an unauthoritative snapshot is
///   [CarSignal.unavailable].
/// - A reading too old to show as live (the snapshot's own staleness rule) is
///   [CarSignal.stale].
CarSignal projectCarSignal({
  required TelemetrySnapshot? telemetry,
  required ConnectionPhase connectionPhase,
  required Pid pid,
  DateTime? now,
}) {
  if (telemetry == null) return CarSignal.unavailable;
  final reading = telemetry[pid.id];
  if (connectionPhase != ConnectionPhase.connected) {
    return reading == null ? CarSignal.unavailable : CarSignal.stale;
  }
  final fault = telemetry.faults[pid.id];
  if (fault == PidFault.unsupported) return CarSignal.unsupported;
  if (fault != null) return CarSignal.unavailable;
  if (reading == null) return CarSignal.unavailable;
  if (telemetry.isStale(pid, now: now)) return CarSignal.stale;
  return CarSignal.live(reading.value);
}

/// Projects the DTC scan summary. Not scanned means not known.
CarDiagnosticsSummary projectCarDiagnostics(DtcScanState dtc) {
  if (!dtc.hasScanned) return CarDiagnosticsSummary.unavailable;
  return CarDiagnosticsSummary.scanned(
    dtcCount: dtc.totalCodes,
    milOn: dtc.mil?.milOn,
  );
}

/// Builds the whole projection from already-read inputs.
///
/// [telemetry] must be the *authoritative* snapshot
/// (`authoritativeTelemetryValue`), or null when there is none: a value
/// Riverpod retained across loading/error is not live data.
CarTelemetryProjection projectCarTelemetry({
  required TelemetrySnapshot? telemetry,
  required ConnectionPhase connectionPhase,
  required int connectionEpoch,
  required int lifecycleEpoch,
  required DtcScanState dtc,
  required int monotonicUs,
  DateTime? now,
}) {
  CarSignal signal(Pid pid) => projectCarSignal(
    telemetry: telemetry,
    connectionPhase: connectionPhase,
    pid: pid,
    now: now,
  );
  return CarTelemetryProjection(
    connectionPhase: connectionPhase,
    connectionEpoch: connectionEpoch,
    lifecycleEpoch: lifecycleEpoch,
    producedAtMonotonicUs: monotonicUs,
    speedKmh: signal(CarTelemetrySignalSources.speedKmh),
    rpm: signal(CarTelemetrySignalSources.rpm),
    coolantC: signal(CarTelemetrySignalSources.coolantC),
    intakeAirC: signal(CarTelemetrySignalSources.intakeAirC),
    controlModuleVoltageV: signal(
      CarTelemetrySignalSources.controlModuleVoltageV,
    ),
    mapKpa: signal(CarTelemetrySignalSources.mapKpa),
    diagnostics: projectCarDiagnostics(dtc),
  );
}
