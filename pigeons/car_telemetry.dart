// AA-02: the one-way, read-only car telemetry projection contract.
//
// Regenerate (exact Pigeon version pinned in pubspec.yaml):
//
//     dart run pigeon --input pigeons/car_telemetry.dart
//
// Both outputs are committed. tool/ci/verify_car_pigeon_codegen.sh regenerates
// them in CI and fails on any drift.
//
// Direction is Flutter -> Kotlin only. This file MUST declare exactly one
// @HostApi and MUST NOT declare any @FlutterApi: the car side never commands
// the phone side (test/tool/test_car_bridge_contract.py enforces both).
//
// The generated Kotlin lands in the carProto source set only; field, rig and
// wear never compile it.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/car/generated/car_telemetry.g.dart',
    dartOptions: DartOptions(),
    dartPackageName: 'torque_obd',
    // One literal: Pigeon's annotation reader does not join adjacent strings.
    kotlinOut: 'android/app/src/carProto/kotlin/com/cbstudio/telltale/carbridge/generated/CarTelemetry.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.cbstudio.telltale.carbridge.generated',
    ),
  ),
)
/// Mirrors the app's connection phase without exposing app internals.
enum CarConnectionPhaseMessage {
  disconnected,
  connecting,
  handshaking,
  connected,
  failed,
}

/// Why a signal does or does not carry a value.
///
/// Only [live] may carry a number. Every other status transports null.
enum CarSignalStatusMessage { live, stale, unsupported, unavailable }

class CarSignalDoubleMessage {
  CarSignalDoubleMessage({required this.status, this.value});

  CarSignalStatusMessage status;
  double? value;
}

/// Schema version 2 of the projected telemetry frame.
class CarTelemetryMessage {
  CarTelemetryMessage({
    required this.schemaVersion,
    required this.sequence,
    required this.connectionEpoch,
    required this.lifecycleEpoch,
    required this.producedAtMonotonicUs,
    required this.connectionPhase,
    required this.speedKmh,
    required this.rpm,
    required this.coolantC,
    required this.intakeAirC,
    required this.controlModuleVoltageV,
    required this.mapKpa,
    required this.diagnosticsAvailable,
    this.milOn,
    this.dtcCount,
    required this.engineLoadPct,
  });

  int schemaVersion;
  int sequence;

  int connectionEpoch;
  int lifecycleEpoch;

  /// Producer-side monotonic time. Diagnostics and ordering evidence only;
  /// never a host-side freshness authority.
  int producedAtMonotonicUs;

  CarConnectionPhaseMessage connectionPhase;

  CarSignalDoubleMessage speedKmh;
  CarSignalDoubleMessage rpm;
  CarSignalDoubleMessage coolantC;
  CarSignalDoubleMessage intakeAirC;
  CarSignalDoubleMessage controlModuleVoltageV;
  CarSignalDoubleMessage mapKpa;

  bool diagnosticsAvailable;
  bool? milOn;
  int? dtcCount;

  CarSignalDoubleMessage engineLoadPct;
}

@HostApi()
abstract class CarTelemetryHostApi {
  void publishTelemetryFrame(CarTelemetryMessage frame);
}
