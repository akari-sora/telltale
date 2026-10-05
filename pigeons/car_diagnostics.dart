// AA-04: the one-way, read-only car diagnostics and DTC projection contract.
//
// Regenerate (exact Pigeon version pinned in pubspec.yaml):
//
//     dart run pigeon --input pigeons/car_diagnostics.dart
//
// Direction is Flutter -> Kotlin only. This file MUST declare exactly one
// @HostApi and MUST NOT declare any @FlutterApi.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/car/generated/car_diagnostics.g.dart',
    dartOptions: DartOptions(),
    dartPackageName: 'torque_obd',
    kotlinOut:
        'android/app/src/carProto/kotlin/com/cbstudio/telltale/carbridge/generated/CarDiagnostics.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.cbstudio.telltale.carbridge.generated',
      includeErrorClass: false,
    ),
  ),
)
enum CarDtcKindMessage {
  stored,
  pending,
  permanent,
}

enum CarDtcObservationCompletenessMessage {
  complete,
  partial,
}

enum CarDtcVerdictMessage {
  notScanned,
  completeClean,
  partialClean,
  faultsFound,
  failed,
}

enum CarDtcScanPhaseMessage {
  idle,
  scanning,
  interrupted,
}

class CarDtcItemMessage {
  CarDtcItemMessage({
    required this.code,
    required this.kind,
    this.sourceId,
    required this.manufacturerSpecific,
    required this.completeness,
  });

  String code;
  CarDtcKindMessage kind;
  String? sourceId;
  bool manufacturerSpecific;
  CarDtcObservationCompletenessMessage completeness;
}

enum CarFreezeSignalKindMessage {
  speedKmh,
  rpm,
  coolantC,
  intakeAirC,
  engineLoadPct,
  mapKpa,
  controlModuleVoltageV,
}

class CarFreezeReadingMessage {
  CarFreezeReadingMessage({
    required this.signal,
    required this.value,
  });

  CarFreezeSignalKindMessage signal;
  double value;
}

class CarFreezeFrameMessage {
  CarFreezeFrameMessage({
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

  String sourceId;
  int frameNumber;

  String causeCode;
  CarDtcKindMessage causeKind;
  String? causeSourceId;

  List<CarFreezeReadingMessage> readings;

  int undecodableCount;
  int unreadCount;
  int omittedByProjectionCount;
  bool contentsUnknown;
}

class CarDtcReportMessage {
  CarDtcReportMessage({
    required this.schemaVersion,
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
  });

  int schemaVersion;
  int reportSequence;
  int connectionEpoch;

  CarDtcScanPhaseMessage phase;
  CarDtcVerdictMessage verdict;

  bool coverageComplete;

  bool? milOn;
  int? totalCodes;

  bool freezeFrameReadIncomplete;

  List<CarDtcItemMessage> items;
  List<CarFreezeFrameMessage> freezeFrames;
}

@HostApi()
abstract class CarDiagnosticsHostApi {
  void publishDtcReport(CarDtcReportMessage report);
}
