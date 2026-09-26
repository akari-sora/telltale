library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../state/telemetry_sessions.dart';

/// Process-lifetime warning for an indeterminate artifact mutation.
///
/// There is intentionally no dismiss action: the retained ownership gate can
/// only be reconstructed by a fresh process, so hiding this copy would imply a
/// recovery that did not occur.
class TelemetryArtifactRestartNotice extends ConsumerWidget {
  const TelemetryArtifactRestartNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = ref.watch(telemetryArtifactNoticeProvider);
    if (notice == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final message = notice.localizedMessage(l10n);
    return SafeArea(
      bottom: false,
      child: Material(
        key: const ValueKey('telemetry-artifact-restart-notice'),
        color: context.palette.danger,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.restart_alt, color: Colors.white),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: context.texts.bodyMedium?.copyWith(
                    color: Colors.white,
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
