import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../obd/pid/pid.dart';
import '../../../obd/telemetry.dart';
import '../../widgets/panel.dart';
import 'pid_editor_screen.dart';

/// Placeholder displayed in the secondary pane of the PID manager when no PID
/// is selected.
class PidDetailPlaceholder extends StatelessWidget {
  const PidDetailPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: EmptyState(
          icon: Icons.tune,
          title: l10n.pidDetailEmptyTitle,
          message: l10n.pidDetailEmptyBody,
        ),
      ),
    );
  }
}

/// Secondary detail pane displaying a selected PID's live reading, definition,
/// and management controls.
class PidDetailPane extends StatelessWidget {
  const PidDetailPane({
    required this.pid,
    required this.isActive,
    required this.reading,
    required this.isStale,
    required this.isUnsupported,
    required this.onToggle,
    this.onEdit,
    super.key,
  });

  final Pid pid;
  final bool isActive;
  final Reading? reading;
  final bool isStale;
  final bool isUnsupported;
  final Future<void> Function() onToggle;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final accent = context.gaugeColors(GaugeHue.forKey(pid.id)).bright;

    return ListView(
      key: PageStorageKey('pid-detail-${pid.id}'),
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        // 1. Identity & Actions Panel
        Panel(
          accent: accent,
          isActive: isActive,
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isActive ? accent : palette.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pid.name,
                          style: context.texts.headlineSmall,
                        ),
                        if (pid.shortName.isNotEmpty &&
                            pid.shortName != pid.name) ...[
                          const SizedBox(height: Spacing.xs),
                          Text(
                            pid.shortName,
                            style: context.texts.bodySmall?.copyWith(
                              color: palette.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (pid.isCustom || isUnsupported) ...[
                const SizedBox(height: Spacing.md),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.xs,
                  children: [
                    if (pid.isCustom)
                      StatusPill(
                        label: l10n.pidPillCustom,
                        tone: StatusTone.accent,
                        dense: true,
                      ),
                    if (isUnsupported)
                      StatusPill(
                        label: l10n.pidPillUnsupported,
                        tone: StatusTone.warn,
                        dense: true,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: Spacing.lg),
              const Divider(),
              const SizedBox(height: Spacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.pidRowShowOnDashboard(pid.name),
                      style: context.texts.bodyMedium,
                    ),
                  ),
                  Semantics(
                    label: l10n.pidRowShowOnDashboard(pid.name),
                    child: Switch(
                      value: isActive,
                      onChanged: (_) => unawaited(onToggle()),
                    ),
                  ),
                ],
              ),
              if (pid.isCustom && onEdit != null) ...[
                const SizedBox(height: Spacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(l10n.pidRowEdit),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),

        // 2. Live Reading Panel
        Panel(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.pidPreviewTitle,
                style: context.texts.titleSmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: Spacing.md),
              if (reading != null)
                Opacity(
                  opacity: isStale ? kStaleOpacity : 1.0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        reading!.formatted,
                        style: AppTypography.readout(palette, 32),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        isStale
                            ? l10n.pidRowStaleUnits(pid.units)
                            : pid.units,
                        style: context.texts.bodyMedium?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '—',
                  style: AppTypography.readout(palette, 32),
                ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.md),

        // 3. Definition Details Panel
        Panel(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.pidEditorSectionFormula,
                style: context.texts.titleSmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: Spacing.md),
              _DetailRow(
                label: l10n.pidEditorFieldModeAndPid,
                value: pid.modeAndPid,
                isCode: true,
              ),
              const SizedBox(height: Spacing.sm),
              _DetailRow(
                label: l10n.pidEditorFieldEquation,
                value: pid.equation,
                isCode: true,
              ),
              const SizedBox(height: Spacing.sm),
              _DetailRow(
                label: l10n.pidEditorFieldUnits,
                value: pid.units.isEmpty ? '—' : pid.units,
              ),
              const SizedBox(height: Spacing.sm),
              _DetailRow(
                label: l10n.pidDetailRangeLabel,
                value: '${pid.minValue} — ${pid.maxValue}',
              ),
              const SizedBox(height: Spacing.sm),
              _DetailRow(
                label: l10n.pidEditorFieldHeader,
                value: pid.header.isEmpty || pid.header == kDefaultHeader
                    ? l10n.pidDetailHeaderDefault(kDefaultHeader)
                    : pid.header,
                isCode: true,
              ),
              const SizedBox(height: Spacing.sm),
              _DetailRow(
                label: l10n.pidDetailPriorityLabel,
                value: priorityTierLabel(l10n, pid.priority),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isCode = false,
  });

  final String label;
  final String value;
  final bool isCode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: context.texts.bodySmall?.copyWith(
              color: palette.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: isCode
                ? AppTypography.code(palette, size: 12)
                : context.texts.bodySmall,
          ),
        ),
      ],
    );
  }
}
