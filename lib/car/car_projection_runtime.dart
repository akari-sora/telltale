/// Riverpod wiring for the AA-02 car telemetry projection.
///
/// Active in the unified field app and the carProto compatibility flavor.
/// Everywhere else the runtime provider returns null without listening to anything,
/// arming a timer, or creating the Pigeon client.
///
/// Vehicle data remains read-only. The companion lifecycle runtime may grant
/// or retire periodic polling authority, but it never exposes diagnostic or
/// destructive OBD operations to the car host.
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
import 'car_projection_session_runtime.dart';
import 'car_telemetry_bridge.dart';
import 'car_telemetry_projector.dart';

/// applicationId of the projected Android Auto compatibility flavor.
const String androidCarProtoApplicationId = 'com.cbstudio.telltale.carproto';

/// Reasons emitted by [isCarProjectionEligible].
abstract final class CarProjectionReason {
  /// Android host with a supported flavor and its matching applicationId.
  static const String identityVerified = 'identity_verified';

  /// Android host with a supported flavor, but platform metadata was unavailable
  /// (e.g. timeout / fallback). Fail open for projection so car screen works.
  static const String metadataUnavailable = 'metadata_unavailable';

  /// Android host with a supported flavor, but platform metadata reports a
  /// conflicting applicationId.
  static const String identityConflict = 'identity_conflict';

  /// Process flavor is not projected (e.g. rig or wear).
  static const String flavorIneligible = 'flavor_ineligible';

  /// Platform is not Android (e.g. iOS, Web, desktop).
  static const String nonAndroid = 'non_android';
}

/// Decision returned by [isCarProjectionEligible].
@immutable
final class CarProjectionDecision {
  const CarProjectionDecision({required this.enabled, required this.reason});

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
/// Android projection is enabled only for a matching flavor/application pair:
/// `field` + `com.cbstudio.telltale`, or `carProto` +
/// `com.cbstudio.telltale.carproto`. Unknown metadata fails open for these two
/// flavors so a metadata timeout cannot blank the car screen.
///
/// Returns a [CarProjectionDecision] containing `enabled` and `reason`:
/// - [CarProjectionReason.nonAndroid]: platform is not Android.
/// - [CarProjectionReason.flavorIneligible]: flavor is neither `field` nor `carProto`.
/// - [CarProjectionReason.identityVerified]: Android + supported flavor + matching applicationId.
/// - [CarProjectionReason.metadataUnavailable]: Android + supported flavor + metadata timed out / unknown.
/// - [CarProjectionReason.identityConflict]: Android + supported flavor + conflicting applicationId.
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
  final expectedApplicationId = switch (effectiveFlavor) {
    'field' => androidFieldApplicationId,
    'carProto' => androidCarProtoApplicationId,
    _ => null,
  };
  if (expectedApplicationId == null) {
    return const CarProjectionDecision(
      enabled: false,
      reason: CarProjectionReason.flavorIneligible,
    );
  }

  if (metadata.applicationId == expectedApplicationId) {
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

final carProjectionRuntimeProvider = Provider<CarProjectionCoordinator?>((ref) {
  if (!ref.watch(carProjectionEnabledProvider)) return null;

  ref.watch(carProjectionSessionRuntimeProvider);

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
