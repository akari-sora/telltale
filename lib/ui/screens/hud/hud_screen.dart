/// Top-level full-screen HUD route orchestrating display session, mirroring, and touch isolation.
///
/// Rules:
/// - Pure black background, edge-to-edge immersive full-screen.
/// - The numeric HUD viewport is wrapped in Transform (horizontal flip when mirrored) and IgnorePointer.
/// - Controls and exit touch targets remain strictly outside the mirror transform.
/// - App pause/resume lifecycle automatically suspends and restores brightness override.
/// - Route exit idempotently restores SystemChrome UI and device orientation with ticket-based ownership protection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../hud/hud_controller.dart';
import '../../../hud/hud_display_session.dart';
import '../../../hud/hud_settings.dart';
import 'hud_control_overlay.dart';
import 'hud_theme.dart';
import 'hud_viewport.dart';

class HudScreen extends ConsumerStatefulWidget {
  static const path = '/hud';

  const HudScreen({super.key});

  @override
  ConsumerState<HudScreen> createState() => _HudScreenState();
}

class _HudScreenState extends ConsumerState<HudScreen>
    with WidgetsBindingObserver {
  static int _ticketSequence = 1;
  late final int _ticket;
  late final HudDisplaySession _session;

  @override
  void initState() {
    super.initState();
    _ticket = _ticketSequence++;
    WidgetsBinding.instance.addObserver(this);
    _session = ref.read(hudDisplaySessionProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSession();
    });
  }

  Future<void> _startSession() async {
    if (!mounted) return;
    final settings = ref.read(hudSettingsProvider);
    await _session.enter(
      ticket: _ticket,
      brightnessPreset: settings.brightnessPreset,
      orientationMode: settings.orientationMode,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _session.onAppSuspended();
    } else if (state == AppLifecycleState.resumed) {
      _session.onAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.exit(ticket: _ticket);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = ref.watch(currentHudFrameProvider);
    final settings = ref.watch(hudSettingsProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _session.exit(ticket: _ticket);
        }
      },
      child: Scaffold(
        backgroundColor: HudTheme.background,
        body: Stack(
          children: [
            // 1. Mirrored HUD Viewport: IgnorePointer prevents reverse hit-testing anomalies
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(
                settings.mirrored ? -1.0 : 1.0,
                1.0,
                1.0,
              ),
              child: IgnorePointer(
                child: HudViewport(
                  frame: frame,
                  palette: settings.palette,
                ),
              ),
            ),

            // 2. Un-mirrored Floating Control Overlay: touch coordinates remain 1:1 with screen
            HudControlOverlay(
              onExitRequested: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
