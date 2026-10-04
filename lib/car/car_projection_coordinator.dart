/// Cadence for the car telemetry projection.
///
/// Normal telemetry goes out on a fixed 500 ms tick (2 Hz ceiling), always
/// carrying the newest projection. Edges — first activation, a connection
/// phase or epoch change, a new diagnostics summary — go out immediately.
/// The steady tick also keeps the host's 3 s staleness window fed while the
/// phone side is alive, so host "Stale" means the producer stopped, not that
/// nothing changed.
library;

import 'dart:async';

import 'car_telemetry_bridge.dart';
import 'car_telemetry_frame.dart';

/// Normal-telemetry interval: at most 2 frames per second.
const Duration carTelemetryInterval = Duration(milliseconds: 500);

final class CarProjectionCoordinator {
  CarProjectionCoordinator({
    required this._project,
    required CarTelemetryTransport transport,
    this._interval = carTelemetryInterval,
    void Function(String message)? log,
  }) {
    _bridge = CarTelemetryBridge(
      transport: transport,
      onDisabled: _stop,
      log: log,
    );
  }

  final CarTelemetryProjection Function() _project;
  final Duration _interval;
  late final CarTelemetryBridge _bridge;

  Timer? _timer;
  bool _started = false;
  bool _stopped = false;
  CarTelemetryProjection? _lastOffered;

  CarTelemetryBridge get bridge => _bridge;

  /// Whether the periodic tick is armed.
  bool get isTicking => _timer?.isActive ?? false;

  bool get isStopped => _stopped;

  /// First activation: one frame now, then the steady tick.
  void start() {
    if (_started || _stopped) return;
    _started = true;
    _offer(_project());
    if (_stopped) return;
    _timer = Timer.periodic(_interval, (_) => _offer(_project()));
  }

  /// Some read-only input changed. Only an edge bypasses the tick; ordinary
  /// telemetry waits for the next tick, which will carry the latest value.
  void onInputChanged() {
    if (!_started || _stopped) return;
    final projection = _project();
    if (projection.isEdgeFrom(_lastOffered)) _offer(projection);
  }

  void _offer(CarTelemetryProjection projection) {
    if (_stopped) return;
    _lastOffered = projection;
    _bridge.offer(projection);
  }

  void _stop() {
    _stopped = true;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _stop();
    _bridge.dispose();
  }
}
