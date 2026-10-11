// carProto-only Android Auto session continuity contract.
//
// Unlike telemetry and diagnostics, this contract is deliberately two-way:
// Android owns the projected CarSession lifetime, while Dart owns the
// user-started OBD connection whose read-only poller may continue.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/car/generated/car_projection_session.g.dart',
    dartOptions: DartOptions(),
    dartPackageName: 'torque_obd',
    kotlinOut: 'android/app/src/carProto/kotlin/com/cbstudio/telltale/carbridge/generated/CarProjectionSession.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.cbstudio.telltale.carbridge.generated.session',
    ),
  ),
)
class CarProjectionLeaseMessage {
  CarProjectionLeaseMessage({
    required this.active,
    required this.generation,
    required this.armed,
    required this.connectionGeneration,
    this.producerConnectionGeneration,
  });

  bool active;
  int generation;
  bool armed;
  int? connectionGeneration;
  int? producerConnectionGeneration;
}

@HostApi()
abstract class CarProjectionSessionHostApi {
  CarProjectionLeaseMessage currentLease();
  CarProjectionLeaseMessage claimProducerConnection(int connectionGeneration);
  void retireProducerConnection(int connectionGeneration);
  CarProjectionLeaseMessage armContinuity(
    int projectionGeneration,
    int connectionGeneration,
  );
  void retireContinuity(int projectionGeneration, int connectionGeneration);
  void acknowledgeRelease(int projectionGeneration);
}

@FlutterApi()
abstract class CarProjectionSessionFlutterApi {
  void onLeaseChanged(CarProjectionLeaseMessage lease);
}
