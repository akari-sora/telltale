/// Manages the HUD viewing session lifecycle, system UI, orientation, and brightness.
///
/// State machine:
/// IDLE -> ENTERING -> ACTIVE -> SUSPENDED -> ACTIVE -> EXITING -> IDLE
///
/// Rules:
/// - Screen brightness override is restored immediately upon app pause/background.
/// - Full screen immersive mode and orientation locks are restored on route exit.
/// - All restoration methods must be completely idempotent.
library;

import 'package:flutter/services.dart';
import 'hud_display_platform.dart';
import 'hud_settings.dart';

/// Lifecycle state of a HUD viewing session.
enum HudSessionState {
  idle,
  entering,
  active,
  suspended,
  exiting,
}

/// Controller managing HUD display session attributes and system UI integration.
class HudDisplaySession {
  final HudDisplayPlatform platform;

  int _currentGeneration = 0;
  int _activeRouteTicket = 0;
  HudSessionState _state = HudSessionState.idle;

  HudSessionState get state => _state;
  int get activeRouteTicket => _activeRouteTicket;
  int get currentGeneration => _currentGeneration;

  HudBrightnessPreset _currentPreset = HudBrightnessPreset.system;
  HudOrientationMode _currentOrientation = HudOrientationMode.landscape;

  HudDisplaySession({
    required this.platform,
  });

  /// Starts a HUD display session with the given settings and optional route ticket.
  Future<void> enter({
    int ticket = 0,
    required HudBrightnessPreset brightnessPreset,
    required HudOrientationMode orientationMode,
  }) async {
    final gen = ++_currentGeneration;
    _activeRouteTicket = ticket;
    _state = HudSessionState.entering;
    _currentPreset = brightnessPreset;
    _currentOrientation = orientationMode;

    // Apply orientation policy.
    await _applyOrientationPolicy(_currentOrientation);
    if (gen != _currentGeneration) return;

    // Enter immersive sticky full screen mode and native system bars hidden.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (gen != _currentGeneration) return;
    await platform.setSystemBarsHidden(true);
    if (gen != _currentGeneration) return;

    // Apply window brightness override.
    await platform.setBrightnessOverride(_currentPreset.brightnessValue);
    if (gen != _currentGeneration) return;

    _state = HudSessionState.active;
  }

  /// Updates HUD brightness preset dynamically while session is active.
  Future<void> updateBrightness(HudBrightnessPreset preset) async {
    _currentPreset = preset;
    if (_state == HudSessionState.active) {
      await platform.setBrightnessOverride(preset.brightnessValue);
    }
  }

  /// Updates HUD orientation dynamically while session is active.
  Future<void> updateOrientation(HudOrientationMode mode) async {
    _currentOrientation = mode;
    if (_state == HudSessionState.active) {
      await _applyOrientationPolicy(mode);
    }
  }

  /// Invoked when host app moves to background or loses focus.
  ///
  /// Immediately restores user / system brightness so other apps and lock screen
  /// are not subjected to HUD night/boost overrides.
  /// Works across active, entering, or resuming states.
  Future<void> onAppSuspended() async {
    if (_state == HudSessionState.idle || _state == HudSessionState.exiting) return;
    ++_currentGeneration;
    _state = HudSessionState.suspended;
    await platform.setBrightnessOverride(null);
  }

  /// Invoked when host app resumes and returns to the active HUD route.
  Future<void> onAppResumed() async {
    if (_state != HudSessionState.suspended) return;
    final gen = ++_currentGeneration;
    _state = HudSessionState.entering;

    await _applyOrientationPolicy(_currentOrientation);
    if (gen != _currentGeneration) return;

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (gen != _currentGeneration) return;
    await platform.setSystemBarsHidden(true);
    if (gen != _currentGeneration) return;

    await platform.setBrightnessOverride(_currentPreset.brightnessValue);
    if (gen != _currentGeneration) return;

    _state = HudSessionState.active;
  }

  /// Exits the HUD session and restores all default platform/system attributes.
  ///
  /// If [ticket] is provided, only proceeds if it matches [_activeRouteTicket]
  /// to prevent delayed route disposal from killing a newer active session.
  /// Guaranteed to be idempotent: safe to call multiple times.
  Future<void> exit({int? ticket}) async {
    if (_state == HudSessionState.idle) return;
    if (ticket != null && ticket != _activeRouteTicket) {
      // Stale route disposal; ignore.
      return;
    }
    final gen = ++_currentGeneration;
    _state = HudSessionState.exiting;

    // 1. Restore brightness immediately.
    await platform.setBrightnessOverride(null);
    if (gen != _currentGeneration) return;

    // 2. Restore system UI edge-to-edge chrome and native system bars.
    await platform.setSystemBarsHidden(false);
    if (gen != _currentGeneration) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (gen != _currentGeneration) return;

    // 3. Restore device orientation to unconstrained.
    await SystemChrome.setPreferredOrientations(const []);
    if (gen != _currentGeneration) return;

    _state = HudSessionState.idle;
  }

  static Future<void> _applyOrientationPolicy(HudOrientationMode mode) async {
    switch (mode) {
      case HudOrientationMode.auto:
        await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
        break;
      case HudOrientationMode.landscape:
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case HudOrientationMode.portrait:
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        break;
    }
  }
}
