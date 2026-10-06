/// Pure presentation viewport rendering the primary HUD layout.
///
/// Visual weights:
/// - Speed numeral: ~55-60% dominant visual presence.
/// - Speed unit: ~8-10%.
/// - RPM & Coolant: ~15-18% each in lower quadrants.
/// - Status/Alert slot: <= 10% bottom center.
library;

import 'package:flutter/material.dart';
import '../../../hud/hud_frame.dart';
import '../../../hud/hud_settings.dart';
import 'hud_theme.dart';

class HudViewport extends StatelessWidget {
  final HudFrame frame;
  final HudThemePalette palette;

  const HudViewport({
    super.key,
    required this.frame,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final colors = HudTheme.colorsOf(palette);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final scaleFactor = textScaler.scale(1.0).clamp(1.0, 3.0);
        final isShort = constraints.maxHeight < 400;
        final isPortrait = constraints.maxWidth < constraints.maxHeight;
        final baseDimension = isPortrait ? constraints.maxWidth * 0.9 : constraints.maxHeight;

        final rawSpeedSize = baseDimension * (isShort ? 0.34 : 0.38);
        final speedFontSize = (rawSpeedSize / scaleFactor).clamp(32.0, 192.0);
        final unitFontSize = (speedFontSize * 0.18).clamp(12.0, 32.0);
        final secondaryFontSize = (speedFontSize * 0.22).clamp(14.0, 36.0);
        final labelFontSize = (secondaryFontSize * 0.65).clamp(10.0, 20.0);

        final speedText = _formatValue(frame.speedKmh, isSpeed: true);
        final rpmText = _formatValue(frame.rpm);
        final coolantText = _formatValue(frame.coolantC);

        final speedColor = frame.speedKmh.isLive ? colors.primary : colors.dim;
        final rpmColor = frame.rpm.isLive ? colors.secondary : colors.dim;
        final coolantColor = frame.coolantC.isLive ? colors.secondary : colors.dim;

        final statusMessage = _resolveStatusMessage(frame);

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: HudTheme.background,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top buffer
              const SizedBox(height: 4.0),

              // Center: Dominant Speed & Unit (wrapped in FittedBox)
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          speedText,
                          style: HudTheme.baseStyle(
                            color: speedColor,
                            fontSize: speedFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'km/h',
                          style: HudTheme.baseStyle(
                            color: speedColor.withValues(alpha: 0.8),
                            fontSize: unitFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Section: RPM, Status, Coolant (wrapped in FittedBox)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: constraints.maxWidth - 48.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status indicator line (if any active condition)
                        if (statusMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Text(
                              statusMessage,
                              style: HudTheme.baseStyle(
                                color: colors.alert,
                                fontSize: labelFontSize * 1.1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          SizedBox(height: labelFontSize * 1.1 + 6.0),

                        // Secondary telemetry row: RPM (left) vs Coolant (right)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // RPM gauge
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.bottomLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      rpmText,
                                      style: HudTheme.baseStyle(
                                        color: rpmColor,
                                        fontSize: secondaryFontSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'RPM',
                                      style: HudTheme.baseStyle(
                                        color: rpmColor.withValues(alpha: 0.7),
                                        fontSize: labelFontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            // Coolant gauge
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.bottomRight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      coolantText,
                                      style: HudTheme.baseStyle(
                                        color: coolantColor,
                                        fontSize: secondaryFontSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'COOLANT °C',
                                      style: HudTheme.baseStyle(
                                        color: coolantColor.withValues(alpha: 0.7),
                                        fontSize: labelFontSize,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatValue(HudValue val, {bool isSpeed = false}) {
    if (val.isLive && val.value != null) {
      final v = val.value!;
      if (isSpeed && v.abs() < 0.05) return '0';
      return v.round().toString();
    }
    // Missing, stale, or unavailable
    return '--';
  }

  static String? _resolveStatusMessage(HudFrame frame) {
    if (!frame.connected) {
      return 'DISCONNECTED';
    }
    if (frame.speedKmh.isMissing && frame.rpm.isMissing) {
      return 'NO LIVE DATA';
    }
    if (frame.speedKmh.isStale || frame.rpm.isStale) {
      return 'STALE TELEMETRY';
    }
    if (frame.speedKmh.isUnavailable) {
      return 'SPEED UNAVAILABLE';
    }
    return null;
  }
}
