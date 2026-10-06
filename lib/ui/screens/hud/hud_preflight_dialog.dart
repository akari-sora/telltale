import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../hud/hud_settings.dart';
import 'hud_theme.dart';

/// Preflight dialog allowing drivers to configure HUD preferences safely
/// before activating the full-screen driving display.
///
/// Complies with HUD01-27: all customizations (mirroring, palette, brightness,
/// orientation) must be established prior to entering the driving surface.
class HudPreflightDialog extends ConsumerWidget {
  const HudPreflightDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const HudPreflightDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(hudSettingsProvider);
    final notifier = ref.read(hudSettingsProvider.notifier);
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header (Fixed)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: HudTheme.green.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flip,
                      color: HudTheme.green.primary,
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HUD Head-Up Display',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Pre-drive setup',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Scrollable Settings Area
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Mirror Mode Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Windshield Mirroring',
                          style: TextStyle(color: Colors.white, fontSize: 14.0),
                        ),
                        subtitle: Text(
                          settings.mirrored ? 'Flipped for windshield reflection' : 'Normal direct-view display',
                          style: const TextStyle(color: Colors.white60, fontSize: 12.0),
                        ),
                        value: settings.mirrored,
                        activeThumbColor: HudTheme.green.primary,
                        onChanged: (val) => notifier.setMirrored(val),
                      ),
                      const Divider(color: Colors.white12, height: 16.0),

                      // 2. Palette Selector
                      const Text(
                        'COLOR PALETTE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          _paletteButton(
                            context,
                            label: 'Green',
                            color: HudTheme.green.primary,
                            selected: settings.palette == HudThemePalette.green,
                            onTap: () => notifier.setPalette(HudThemePalette.green),
                          ),
                          const SizedBox(width: 8.0),
                          _paletteButton(
                            context,
                            label: 'Amber',
                            color: HudTheme.amber.primary,
                            selected: settings.palette == HudThemePalette.amber,
                            onTap: () => notifier.setPalette(HudThemePalette.amber),
                          ),
                          const SizedBox(width: 8.0),
                          _paletteButton(
                            context,
                            label: 'Ice Blue',
                            color: HudTheme.iceBlue.primary,
                            selected: settings.palette == HudThemePalette.iceBlue,
                            onTap: () => notifier.setPalette(HudThemePalette.iceBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14.0),

                      // 3. Brightness Preset
                      const Text(
                        'DISPLAY BRIGHTNESS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 6.0,
                        children: HudBrightnessPreset.values.map((preset) {
                          final isSel = settings.brightnessPreset == preset;
                          return ChoiceChip(
                            label: Text(
                              preset.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w600,
                                color: isSel ? Colors.black : Colors.white70,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: HudTheme.colorsOf(settings.palette).primary,
                            backgroundColor: const Color(0xFF2A2A2A),
                            onSelected: (_) => notifier.setBrightnessPreset(preset),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14.0),

                      // 4. Orientation Mode
                      const Text(
                        'SCREEN ORIENTATION',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      SegmentedButton<HudOrientationMode>(
                        segments: const [
                          ButtonSegment(
                            value: HudOrientationMode.auto,
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Auto'),
                            ),
                            icon: Icon(Icons.screen_rotation, size: 16.0),
                          ),
                          ButtonSegment(
                            value: HudOrientationMode.landscape,
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Landscape'),
                            ),
                            icon: Icon(Icons.stay_current_landscape, size: 16.0),
                          ),
                          ButtonSegment(
                            value: HudOrientationMode.portrait,
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Portrait'),
                            ),
                            icon: Icon(Icons.stay_current_portrait, size: 16.0),
                          ),
                        ],
                        selected: {settings.orientationMode},
                        onSelectionChanged: (set) {
                          if (set.isNotEmpty) {
                            notifier.setOrientationMode(set.first);
                          }
                        },
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return HudTheme.colorsOf(settings.palette).primary.withValues(alpha: 0.25);
                            }
                            return const Color(0xFF2A2A2A);
                          }),
                          foregroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return HudTheme.colorsOf(settings.palette).primary;
                            }
                            return Colors.white70;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // Actions (Fixed with Wrap for narrow/scaled viewports)
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('start-hud-btn'),
                    style: FilledButton.styleFrom(
                      backgroundColor: HudTheme.colorsOf(settings.palette).primary,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/hud');
                    },
                    icon: const Icon(Icons.play_arrow, size: 18.0),
                    label: const Text('START HUD', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paletteButton(
    BuildContext context, {
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.2) : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: selected ? color : Colors.white12,
              width: selected ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4.0),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? color : Colors.white70,
                      fontSize: 12.0,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
