library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../state/telemetry_sessions.dart';
import '../../../telemetry/session/telemetry_session_store.dart';
import '../../widgets/panel.dart';
import '../../widgets/telemetry/telemetry_session_action_feedback.dart';
import '../../widgets/telemetry/telemetry_status_copy.dart';
import 'telemetry_source_copy.dart';

/// The library quota, in the units the two chips render.
///
/// Read from [TelemetryQuota] rather than written into the copy: the number a
/// sentence claims and the number the store enforces have to be the same one.
const _libraryMiBLimit = TelemetryQuota.libraryByteLimit ~/ (1024 * 1024);

class TelemetrySessionsScreen extends ConsumerWidget {
  const TelemetrySessionsScreen({super.key});

  static const path = '/sessions';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final access = ref.watch(telemetryHistoryAccessProvider);
    if (access != TelemetryHistoryAccess.permitted) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.telemetrySessionsTitle)),
        body: Center(child: Text(access.message(l10n)!)),
      );
    }
    final library = ref.watch(telemetrySessionLibraryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.telemetrySessionsTitle),
        actions: [
          IconButton(
            tooltip: l10n.telemetryReload,
            onPressed: () => ref.invalidate(telemetrySessionLibraryProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: library.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(telemetrySessionLibraryProvider),
            child: Text(l10n.telemetrySessionsLoadFailed),
          ),
        ),
        data: (data) => _LibraryBody(data: data),
      ),
    );
  }
}

class _LibraryBody extends StatelessWidget {
  const _LibraryBody({required this.data});

  final TelemetrySessionLibrary data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final usedMiB = data.recognizedBytes / (1024 * 1024);
    final used = usedMiB.toStringAsFixed(1);
    if (data.sessions.isEmpty && data.damaged.isEmpty) {
      return Center(child: Text(l10n.telemetrySessionsEmpty));
    }
    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Semantics(
          label: l10n.telemetryLibraryQuotaSemantics(
            data.groupCount,
            TelemetryQuota.groupLimit,
            used,
            _libraryMiBLimit,
          ),
          child: Panel(
            child: Wrap(
              spacing: Spacing.lg,
              runSpacing: Spacing.sm,
              children: [
                Text(
                  l10n.telemetryLibraryGroupCount(
                    data.groupCount,
                    TelemetryQuota.groupLimit,
                  ),
                ),
                Text(l10n.telemetryLibraryBytes(used, _libraryMiBLimit)),
                if (data.omittedCount > 0)
                  Text(l10n.telemetryLibraryOmitted(data.omittedCount)),
              ],
            ),
          ),
        ),
        if (data.sessions.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          SectionHeading(l10n.telemetrySessionsReplayable),
          for (final session in data.sessions) ...[
            _SessionTile(
              key: ValueKey('telemetry-session-tile-${session.id}'),
              session: session,
            ),
            const SizedBox(height: Spacing.sm),
          ],
        ],
        if (data.damaged.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          SectionHeading(l10n.telemetrySessionsDamaged),
          for (final artifact in data.damaged) ...[
            _DamagedTile(
              key: ValueKey('telemetry-damaged-tile-${artifact.id}'),
              artifact: artifact,
            ),
            const SizedBox(height: Spacing.sm),
          ],
        ],
      ],
    );
  }
}

class _DamagedTile extends ConsumerStatefulWidget {
  const _DamagedTile({super.key, required this.artifact});

  final DamagedTelemetryProjection artifact;

  @override
  ConsumerState<_DamagedTile> createState() => _DamagedTileState();
}

class _DamagedTileState extends ConsumerState<_DamagedTile> {
  Future<void> _delete() async {
    final targetId = widget.artifact.id;
    final route = ModalRoute.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          scrollable: true,
          title: Text(dialogL10n.telemetryDeleteDamagedTitle),
          content: Text(
            dialogL10n.telemetryDeleteDamagedBody(
              targetId,
              _localTime(widget.artifact.filesystemModifiedAtUtc),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogL10n.telemetryCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dialogL10n.telemetryDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted || widget.artifact.id != targetId) return;
    if (route != null && !route.isCurrent) return;
    final result = await ref
        .read(telemetrySessionActionsProvider)
        .delete(targetId, confirmed: true);
    if (!mounted || widget.artifact.id != targetId) return;

    if (result.isSuccess) {
      ref.invalidate(telemetrySessionLibraryProvider);
      return;
    }

    if (route != null && !route.isCurrent) return;
    if (result.failure == TelemetrySessionActionFailure.restartRequired) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TelemetrySessionActionFeedback(
          result: result,
          kind: TelemetrySessionActionKind.delete,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Panel(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.warning_amber_rounded),
        title: Text(widget.artifact.id),
        subtitle: Text(
          '${widget.artifact.kind == DamagedTelemetryKind.collision ? l10n.telemetryDamagedCollision : l10n.telemetryDamagedCorrupt}\n'
          '${l10n.telemetryDamagedFileTime(_localTime(widget.artifact.filesystemModifiedAtUtc))}',
        ),
        trailing: IconButton(
          tooltip: l10n.telemetryDeleteDamagedTooltip,
          onPressed: _delete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({super.key, required this.session});

  final TelemetrySessionProjection session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Panel(
      onTap: () =>
          context.push('${TelemetrySessionsScreen.path}/${session.id}'),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_localTime(session.startedAtUtc)),
        subtitle: Text(
          '${telemetrySourceLabel(l10n, session.source)} · ${session.transport} · ${session.protocol}\n'
          '${_durationLabel(session.duration)} · '
          '${l10n.telemetrySignalCount(session.signalCount)}\n'
          '${l10n.telemetryValueCount(session.valueCount)} · '
          '${l10n.telemetryStatusCount(session.statusCount)} · '
          '${l10n.telemetryGapCount(session.gapCount)}\n'
          '${telemetryTerminalReasonLabel(l10n, session.terminalReason)}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

String _localTime(DateTime utc) => utc.toLocal().toString().substring(0, 16);

String _durationLabel(Duration duration) {
  final seconds = duration.inSeconds.clamp(0, 24 * 60 * 60 - 1);
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainder = seconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainder.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${remainder.toString().padLeft(2, '0')}';
}
