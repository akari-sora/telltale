/// Controller and Riverpod providers coordinating HUD state, frame projection, and display session.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/obd_session.dart';
import '../state/telemetry_recorder.dart' show authoritativeTelemetryValue;
import 'hud_display_platform.dart';
import 'hud_display_session.dart';
import 'hud_frame.dart';
import 'hud_projector.dart';
import 'hud_render_throttle.dart';

/// Provider for the [HudDisplaySession] coordinator.
final hudDisplaySessionProvider = Provider<HudDisplaySession>((ref) {
  final platform = ref.watch(hudDisplayPlatformProvider);
  return HudDisplaySession(platform: platform);
});

/// Riverpod notifier managing the throttled (<= 10Hz) HUD frame stream.
class HudFrameNotifier extends Notifier<HudFrame> {
  late final HudRenderThrottle _throttle;

  @override
  HudFrame build() {
    _throttle = HudRenderThrottle(
      interval: const Duration(milliseconds: 100), // 10 Hz
      onRender: (frame) {
        state = frame;
      },
    );
    ref.onDispose(_throttle.dispose);

    ref.listen(telemetryProvider, (_, _) => _recompute());
    ref.listen(obdSessionProvider, (_, _) => _recompute());

    final telemetryAsync = ref.read(telemetryProvider);
    final telemetry = authoritativeTelemetryValue(telemetryAsync);
    final isConnected = ref.read(obdSessionProvider).isConnected;

    return projectHudFrame(
      telemetry: telemetry,
      isConnected: isConnected,
    );
  }

  void _recompute() {
    final telemetryAsync = ref.read(telemetryProvider);
    final telemetry = authoritativeTelemetryValue(telemetryAsync);
    final isConnected = ref.read(obdSessionProvider).isConnected;

    final frame = projectHudFrame(
      telemetry: telemetry,
      isConnected: isConnected,
    );
    _throttle.push(frame);
  }
}

/// Global provider for the throttled [HudFrame] currently rendered on screen.
final currentHudFrameProvider =
    NotifierProvider<HudFrameNotifier, HudFrame>(
  HudFrameNotifier.new,
);
