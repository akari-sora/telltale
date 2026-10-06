/// Immutable, authoritative HUD telemetry frame and signal values.
///
/// HUD-01 contract:
/// - HUD presentation projection only, independent of CarTelemetryFrame.
/// - Speed, RPM, Coolant follow explicit freshness contract (live, stale, missing, unavailable).
/// - Missing or unavailable data is never reported as zero.
library;

import 'package:flutter/foundation.dart';

/// Freshness state of an individual HUD signal reading.
enum HudValueState {
  /// Live reading within authoritative freshness window.
  live,

  /// Stale reading: previous value exists but exceeds staleness TTL.
  stale,

  /// Missing reading: sensor not queried or no observation ever received.
  missing,

  /// Unavailable: ECU explicitly reported fault, unsupported, or sensor error.
  unavailable,
}

/// A single numeric HUD signal value paired with its freshness state.
@immutable
class HudValue {
  /// Numeric reading in standard display units (km/h, RPM, °C).
  ///
  /// Null when [state] is [HudValueState.missing] or [HudValueState.unavailable].
  /// When [state] is [HudValueState.stale], may retain the last observed value
  /// for diagnostics/testing, but presentation layer must display stale treatment ('--').
  final double? value;

  /// Authoritative freshness state.
  final HudValueState state;

  const HudValue({
    this.value,
    required this.state,
  });

  const HudValue.live(double val)
      : value = val,
        state = HudValueState.live;

  const HudValue.stale([this.value])
      : state = HudValueState.stale;

  const HudValue.missing()
      : value = null,
        state = HudValueState.missing;

  const HudValue.unavailable()
      : value = null,
        state = HudValueState.unavailable;

  bool get isLive => state == HudValueState.live;
  bool get isStale => state == HudValueState.stale;
  bool get isMissing => state == HudValueState.missing;
  bool get isUnavailable => state == HudValueState.unavailable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HudValue &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          state == other.state;

  @override
  int get hashCode => Object.hash(value, state);

  @override
  String toString() => 'HudValue($state, value: $value)';
}

/// Pure data frame consumed by HUD rendering components.
@immutable
class HudFrame {
  /// Road speed in km/h.
  final HudValue speedKmh;

  /// Engine speed in RPM.
  final HudValue rpm;

  /// Engine coolant temperature in °C.
  final HudValue coolantC;

  /// True when OBD connection is actively established and authoritative.
  final bool connected;

  /// Timestamp when underlying snapshot was published.
  final DateTime? capturedAt;

  const HudFrame({
    required this.speedKmh,
    required this.rpm,
    required this.coolantC,
    required this.connected,
    this.capturedAt,
  });

  const HudFrame.empty()
      : speedKmh = const HudValue.missing(),
        rpm = const HudValue.missing(),
        coolantC = const HudValue.missing(),
        connected = false,
        capturedAt = null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HudFrame &&
          runtimeType == other.runtimeType &&
          speedKmh == other.speedKmh &&
          rpm == other.rpm &&
          coolantC == other.coolantC &&
          connected == other.connected &&
          capturedAt == other.capturedAt;

  @override
  int get hashCode =>
      Object.hash(speedKmh, rpm, coolantC, connected, capturedAt);

  @override
  String toString() =>
      'HudFrame(connected: $connected, speed: $speedKmh, rpm: $rpm, coolant: $coolantC)';
}
