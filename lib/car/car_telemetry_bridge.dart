/// The Dart (producer) end of the one-way car telemetry bridge.
///
/// Single-flight and latest-wins: at most one host call is outstanding, and
/// while it is, only the newest projection waits. The bridge can therefore
/// never build a latency queue toward the car.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../state/obd_session.dart' show ConnectionPhase;
import 'car_telemetry_frame.dart';
import 'generated/car_telemetry.g.dart';

/// Delivers one encoded frame to the host. Production: Pigeon.
typedef CarTelemetryTransport = Future<void> Function(CarTelemetryMessage);

/// The production transport over the generated Pigeon host API.
CarTelemetryTransport pigeonCarTelemetryTransport() {
  final api = CarTelemetryHostApi();
  return api.publishTelemetryFrame;
}

final class CarTelemetryBridge {
  CarTelemetryBridge({
    required this._transport,
    this._onDisabled,
    void Function(String message)? log,
  }) : _log = log ?? debugPrint;

  final CarTelemetryTransport _transport;
  final void Function()? _onDisabled;
  final void Function(String message) _log;

  int _lastSequence = 0;
  bool _inFlight = false;
  bool _disabled = false;
  bool _disposed = false;
  bool _loggedTransientError = false;
  CarTelemetryProjection? _pending;

  /// True once the host proved absent. Permanent for this bridge instance.
  bool get disabled => _disabled;

  /// The sequence of the most recent *attempted* transmission (0 = none).
  int get lastSequence => _lastSequence;

  bool get inFlight => _inFlight;

  /// Offers the newest projection. Sent now if idle; otherwise it replaces
  /// whatever was already waiting and goes out when the current call ends.
  void offer(CarTelemetryProjection projection) {
    if (_disabled || _disposed) return;
    if (_inFlight) {
      _pending = projection;
      return;
    }
    unawaited(_send(projection));
  }

  Future<void> _send(CarTelemetryProjection projection) async {
    _inFlight = true;
    // The sequence advances only when a frame actually goes to the host.
    final frame = CarTelemetryFrame(
      sequence: ++_lastSequence,
      projection: projection,
    );
    try {
      await _transport(encodeCarTelemetryFrame(frame));
    } on MissingPluginException {
      _disable('no host handler (MissingPluginException)');
    } on PlatformException catch (error) {
      if (error.code == 'channel-error') {
        _disable('no host handler (channel-error)');
      } else {
        _logTransientOnce('host rejected frame: ${error.code}');
      }
    } catch (error) {
      _logTransientOnce('host call failed: ${error.runtimeType}');
    } finally {
      _inFlight = false;
    }
    final next = _pending;
    _pending = null;
    if (next != null && !_disabled && !_disposed) {
      unawaited(_send(next));
    }
  }

  void _disable(String reason) {
    if (_disabled) return;
    _disabled = true;
    _pending = null;
    // One diagnostic line, then silence: a misconfigured host is not retried.
    _log('car telemetry bridge disabled: $reason');
    _onDisabled?.call();
  }

  void _logTransientOnce(String message) {
    if (_loggedTransientError) return;
    _loggedTransientError = true;
    _log('car telemetry bridge: $message');
  }

  /// Stops accepting projections. An in-flight call is left to finish; its
  /// result no longer schedules anything.
  void dispose() {
    _disposed = true;
    _pending = null;
  }
}

/// Encodes a frame into the generated schema-v1 message.
///
/// The live-iff-numeric invariant is re-asserted here as the last line before
/// the wire: a non-live signal never transports a number.
CarTelemetryMessage encodeCarTelemetryFrame(CarTelemetryFrame frame) {
  final p = frame.projection;
  return CarTelemetryMessage(
    schemaVersion: frame.schemaVersion,
    sequence: frame.sequence,
    connectionEpoch: p.connectionEpoch,
    lifecycleEpoch: p.lifecycleEpoch,
    producedAtMonotonicUs: p.producedAtMonotonicUs,
    connectionPhase: _phase(p.connectionPhase),
    speedKmh: _signal(p.speedKmh),
    rpm: _signal(p.rpm),
    coolantC: _signal(p.coolantC),
    intakeAirC: _signal(p.intakeAirC),
    controlModuleVoltageV: _signal(p.controlModuleVoltageV),
    mapKpa: _signal(p.mapKpa),
    diagnosticsAvailable: p.diagnostics.available,
    milOn: p.diagnostics.available ? p.diagnostics.milOn : null,
    dtcCount: p.diagnostics.available ? p.diagnostics.dtcCount : null,
  );
}

CarConnectionPhaseMessage _phase(ConnectionPhase phase) => switch (phase) {
  ConnectionPhase.disconnected => CarConnectionPhaseMessage.disconnected,
  ConnectionPhase.connecting => CarConnectionPhaseMessage.connecting,
  ConnectionPhase.handshaking => CarConnectionPhaseMessage.handshaking,
  ConnectionPhase.connected => CarConnectionPhaseMessage.connected,
  ConnectionPhase.failed => CarConnectionPhaseMessage.failed,
};

CarSignalDoubleMessage _signal(CarSignal signal) => switch (signal.status) {
  CarSignalStatus.live => CarSignalDoubleMessage(
    status: CarSignalStatusMessage.live,
    value: signal.value,
  ),
  CarSignalStatus.stale => CarSignalDoubleMessage(
    status: CarSignalStatusMessage.stale,
  ),
  CarSignalStatus.unsupported => CarSignalDoubleMessage(
    status: CarSignalStatusMessage.unsupported,
  ),
  CarSignalStatus.unavailable => CarSignalDoubleMessage(
    status: CarSignalStatusMessage.unavailable,
  ),
};
