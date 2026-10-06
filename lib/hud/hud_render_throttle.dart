/// Latest-wins render throttle for HUD UI updates.
///
/// Rules:
/// - Maximum rendering cadence = 10 Hz (interval = 100ms).
/// - Latest-wins: unrendered intermediate frames are dropped; never queued.
/// - Clock-agnostic and leak-free: safe under fakeAsync and real time.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'hud_frame.dart';

/// Throttle coordinator enforcing the <= 10Hz HUD rendering budget.
class HudRenderThrottle {
  final Duration interval;
  final ValueChanged<HudFrame> onRender;

  Timer? _timer;
  HudFrame? _pendingFrame;
  bool _isDisposed = false;

  HudRenderThrottle({
    this.interval = const Duration(milliseconds: 100), // 10 Hz
    required this.onRender,
  });

  /// Ingests a new incoming [frame].
  ///
  /// If no throttle timer is active, emits immediately and starts the throttle window.
  /// If a timer is already running, saves [frame] as [_pendingFrame] (latest-wins).
  void push(HudFrame frame) {
    if (_isDisposed) return;

    if (_timer == null) {
      onRender(frame);
      _timer = Timer(interval, _onWindowExpired);
    } else {
      _pendingFrame = frame;
    }
  }

  void _onWindowExpired() {
    if (_isDisposed) return;

    if (_pendingFrame != null) {
      final frameToRender = _pendingFrame!;
      _pendingFrame = null;
      onRender(frameToRender);
      _timer = Timer(interval, _onWindowExpired);
    } else {
      _timer = null;
    }
  }

  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
    _pendingFrame = null;
  }
}
