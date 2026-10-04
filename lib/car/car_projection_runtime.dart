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
import 'package:flutter/services.dart' show appFlavor;
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

/// Reasons emitted by [isCarProjectionEligible].
abstract final class CarProjectionReason {
  /// Android host, `carProto` flavor, and confirmed carProto applicationId.
  static const String identityVerified = 'identity_verified';

  /// Android host and `carProto` flavor, but platform metadata was unavailable
  /// (e.g. timeout / fallback). Fail open for projection so car screen works.
  static const String metadataUnavailable = 'metadata_unavailable';

  /// Android host and `carProto` flavor, but platform metadata reports a
  /// conflicting applicationId (e.g. field, rig, or AAOS).
  static const String identityConflict = 'identity_conflict';

  /// Process flavor is not `carProto` (e.g. field, rig, wear).
  static const String flavorIneligible = 'flavor_ineligible';

  /// Platform is not Android (e.g. iOS, Web, desktop).
  static const String nonAndroid = 'non_android';
}

/// Decision returned by [isCarProjectionEligible].
@immutable
final class CarProjectionDecision {
  const CarProjectionDecision({
    required this.enabled,
    required this.reason,
  });

  final bool enabled;
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarProjectionDecision &&
          other.enabled == enabled &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(enabled, reason);

  @override
  String toString() =>
      'CarProjectionDecision(enabled: $enabled, reason: $reason)';
}

/// Evaluates whether this process hosts the car projection producer.
///
/// Arbitration rule:
/// `isAndroid && appFlavor == 'carProto' && (metadata.applicationId == 'com.cbstudio.telltale.carproto' || metadata.applicationId == unknownPlatformMetadata)`
///
/// Returns a [CarProjectionDecision] containing `enabled` and `reason`:
/// - [CarProjectionReason.nonAndroid]: platform is not Android.
/// - [CarProjectionReason.flavorIneligible]: flavor is not `'carProto'`.
/// - [CarProjectionReason.identityVerified]: Android + `carProto` + verified applicationId.
/// - [CarProjectionReason.metadataUnavailable]: Android + `carProto` + metadata timed out / unknown.
/// - [CarProjectionReason.identityConflict]: Android + `carProto` + conflicting applicationId.
CarProjectionDecision isCarProjectionEligible(
  PlatformMetadata metadata, {
  bool? isAndroid,
  String? flavor,
}) {
  final android = isAndroid ?? (!kIsWeb && Platform.isAndroid);
  if (!android) {
    return const CarProjectionDecision(
      enabled: false,
      reason: CarProjectionReason.nonAndroid,
    );
  }

  final effectiveFlavor = flavor ?? appFlavor;
  if (effectiveFlavor != 'carProto') {
    return const CarProjectionDecision(
      enabled: false,
      reason: CarProjectionReason.flavorIneligible,
    );
  }

  if (metadata.applicationId == androidCarProtoApplicationId) {
    return const CarProjectionDecision(
      enabled: true,
      reason: CarProjectionReason.identityVerified,
    );
  }

  if (metadata.applicationId == unknownPlatformMetadata) {
    return const CarProjectionDecision(
      enabled: true,
      reason: CarProjectionReason.metadataUnavailable,
    );
  }

  return const CarProjectionDecision(
    enabled: false,
    reason: CarProjectionReason.identityConflict,
  );
}

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
