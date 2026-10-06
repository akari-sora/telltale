/// Floating, un-mirrored interactive overlay for HUD control.
///
/// Rules (Strictly conforming to HUD01-27 & P1/P2 audit):
/// - NEVER mirrored: touch coordinates remain 100% aligned with physical display pixels.
/// - NO in-HUD settings toggles: all customizations (mirroring, palette, brightness, orientation)
///   are established prior to entering HUD via [HudPreflightDialog].
/// - Short tap anywhere on driving surface is intentionally no-op to prevent accidental taps while driving.
/// - Exit action requires deliberate Long-Press (>= 700ms) within the exit button bounds.
/// - Pointer movements outside the exit button, early releases (< 700ms),
///   or pointer cancel events abort the exit countdown immediately.
/// - Active Pointer Locking: the primary pointer is locked upon touch-down. Secondary
///   pointers within or outside the button are ignored and will not interrupt the countdown.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../hud/hud_settings.dart';
import 'hud_theme.dart';

class HudControlOverlay extends ConsumerStatefulWidget {
  final VoidCallback onExitRequested;

  const HudControlOverlay({
    super.key,
    required this.onExitRequested,
  });

  @override
  ConsumerState<HudControlOverlay> createState() => _HudControlOverlayState();
}

class _HudControlOverlayState extends ConsumerState<HudControlOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _longPressAnim;
  Timer? _exitTimer;
  int? _activePointerId;
  bool _exitFired = false;
  final GlobalKey _exitButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _longPressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _activePointerId = null;
    _exitTimer?.cancel();
    _exitTimer = null;
    _longPressAnim.dispose();
    super.dispose();
  }

  void _cancelLongPress() {
    _activePointerId = null;
    _exitTimer?.cancel();
    _exitTimer = null;
    if (!mounted) return;
    if (_longPressAnim.isAnimating || _longPressAnim.value > 0.0) {
      _longPressAnim.reverse();
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    // Only one pointer controls exit at a time (ignore secondary fingers)
    if (_activePointerId != null) return;
    _activePointerId = event.pointer;
    _exitFired = false;
    _exitTimer?.cancel();
    _exitTimer = Timer(const Duration(milliseconds: 700), () {
      if (_exitFired) return;
      _exitFired = true;
      _activePointerId = null;
      _exitTimer = null;
      widget.onExitRequested();
    });
    _longPressAnim.forward(from: 0.0);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointerId) return;

    // Check if pointer dragged outside the exit button boundary
    final renderBox = _exitButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPos = renderBox.globalToLocal(event.position);
      // Allow slight slop (10 logical pixels) around the button
      final slopBounds = Rect.fromLTWH(0, 0, renderBox.size.width, renderBox.size.height).inflate(10.0);
      if (!slopBounds.contains(localPos)) {
        _cancelLongPress();
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer == _activePointerId) {
      _cancelLongPress();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _activePointerId) {
      _cancelLongPress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(hudSettingsProvider);
    final colors = HudTheme.colorsOf(settings.palette);

    return SafeArea(
      child: Stack(
        children: [
          // 1. Long-press exit detector on top-left exit button (Strictly 700ms boundary-checked)
          Positioned(
            top: 12.0,
            left: 12.0,
            child: Listener(
              key: _exitButtonKey,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              behavior: HitTestBehavior.opaque,
              child: AnimatedBuilder(
                animation: _longPressAnim,
                builder: (context, child) {
                  final progress = _longPressAnim.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: progress > 0
                            ? colors.alert
                            : colors.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.power_settings_new,
                          size: 16.0,
                          color: progress > 0 ? colors.alert : colors.primary,
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          progress > 0
                              ? 'HOLD ${(700 * (1 - progress)).toInt()}ms'
                              : 'HOLD TO EXIT',
                          style: HudTheme.baseStyle(
                            color: progress > 0 ? colors.alert : colors.primary,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
