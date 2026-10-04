/// Riverpod wiring for the AA-02 car telemetry projection.
///
/// Active only in the projected Android Auto prototype (carProto). Everywhere
/// else the runtime provider returns null without listening to anything,
/// arming a timer, or creating the Pigeon client.
///
/// Read-only by construction: it reads telemetry, session and DTC state and
/// never calls a notifier mutation.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/field_evidence/platform_metadata.dart';
import '../state/dtc_scan.dart';
import '../state/obd_session.dart';
import '../state/telemetry_recorder.dart' show authoritativeTelemetryValue;
import 'car_projection_coordinator.dart';
import 'car_telemetry_bridge.dart';
import 'car_telemetry_projector.dart';

/// applicationId of the projected Android Auto prototype flavor.
const String androidCarProtoApplicationId = 'com.cbstudio.telltale.carproto';

/// Whether this process hosts the car projection producer.
///
/// Gated on the exact applicationId (not on a failed channel call), so field /
/// rig / wear never even try. Overridden once in main.dart.
/// [isAndroid] exists for tests; production uses the real platform.
bool isCarProjectionEligible(PlatformMetadata metadata, {bool? isAndroid}) =>
    (isAndroid ?? (!kIsWeb && Platform.isAndroid)) &&
    metadata.applicationId == androidCarProtoApplicationId;

final carProjectionEnabledProvider = Provider<bool>((ref) => false);

/// The host transport. Only read when the projection is enabled.
final carTelemetryTransportProvider = Provider<CarTelemetryTransport>(
  (ref) => pigeonCarTelemetryTransport(),
);

final carProjectionRuntimeProvider = Provider<CarProjectionCoordinator?>((
  ref,
) {
  if (!ref.watch(carProjectionEnabledProvider)) return null;

  final stopwatch = Stopwatch()..start();
  final coordinator = CarProjectionCoordinator(
    transport: ref.read(carTelemetryTransportProvider),
    project: () {
      final session = ref.read(obdSessionProvider.notifier);
      return projectCarTelemetry(
        telemetry: authoritativeTelemetryValue(ref.read(telemetryProvider)),
        connectionPhase: ref.read(obdSessionProvider).phase,
        connectionEpoch: session.generation,
        lifecycleEpoch: session.pauseEpoch,
        dtc: ref.read(dtcScanProvider),
        monotonicUs: stopwatch.elapsedMicroseconds,
      );
    },
  );

  void changed() => coordinator.onInputChanged();
  ref.listen(telemetryProvider, (_, _) => changed());
  ref.listen(obdSessionProvider, (_, _) => changed());
  ref.listen(dtcScanProvider, (_, _) => changed());
  ref.onDispose(coordinator.dispose);

  coordinator.start();
  return coordinator;
});
