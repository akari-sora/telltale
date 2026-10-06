/// Pure projection from read-only application state to a [HudFrame].
///
/// Rules:
/// - Pure function: no provider access, no clock side-effects beyond passed-in [now].
/// - Source authority is TelemetrySnapshot with its built-in freshness rules.
/// - When not connected or snapshot is null, values are missing or stale (never 0.0 unless live).
library;

import '../obd/pid/pid.dart';
import '../obd/pid/pid_library.dart';
import '../obd/telemetry.dart';
import 'hud_frame.dart';

/// The standard OBD PIDs projected into HUD display items.
abstract final class HudSignalSources {
  /// Mode 01 PID 0D: Vehicle speed in km/h.
  static const Pid speedKmh = PidLibrary.vehicleSpeed;

  /// Mode 01 PID 0C: Engine speed in RPM.
  static const Pid rpm = PidLibrary.engineRpm;

  /// Mode 01 PID 05: Engine coolant temperature in °C.
  static const Pid coolantC = PidLibrary.coolantTemp;
}

/// Projects a [TelemetrySnapshot] and connection state into an authoritative [HudFrame].
HudFrame projectHudFrame({
  required TelemetrySnapshot? telemetry,
  required bool isConnected,
  DateTime? now,
}) {
  if (!isConnected || telemetry == null) {
    return HudFrame(
      speedKmh: telemetry == null
          ? const HudValue.missing()
          : _projectValue(telemetry, HudSignalSources.speedKmh, isConnected: false, now: now),
      rpm: telemetry == null
          ? const HudValue.missing()
          : _projectValue(telemetry, HudSignalSources.rpm, isConnected: false, now: now),
      coolantC: telemetry == null
          ? const HudValue.missing()
          : _projectValue(telemetry, HudSignalSources.coolantC, isConnected: false, now: now),
      connected: isConnected,
      capturedAt: telemetry?.capturedAt,
    );
  }

  return HudFrame(
    speedKmh: _projectValue(telemetry, HudSignalSources.speedKmh, isConnected: true, now: now),
    rpm: _projectValue(telemetry, HudSignalSources.rpm, isConnected: true, now: now),
    coolantC: _projectValue(telemetry, HudSignalSources.coolantC, isConnected: true, now: now),
    connected: true,
    capturedAt: telemetry.capturedAt,
  );
}

HudValue _projectValue(
  TelemetrySnapshot telemetry,
  Pid pid, {
  required bool isConnected,
  DateTime? now,
}) {
  final fault = telemetry.faults[pid.id];
  if (fault != null) {
    return const HudValue.unavailable();
  }

  final reading = telemetry[pid.id];
  if (reading == null) {
    return const HudValue.missing();
  }

  if (!isConnected) {
    return HudValue.stale(reading.value);
  }

  if (telemetry.isStale(pid, now: now)) {
    return HudValue.stale(reading.value);
  }

  return HudValue.live(reading.value);
}
