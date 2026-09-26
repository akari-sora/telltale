library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../state/telemetry_sessions.dart';

enum TelemetrySessionActionKind {
  export,
  delete,
}

/// Pure presentation widget that renders localized feedback for telemetry
/// session actions (such as export or delete failures) at render time.
///
/// Because it resolves [AppLocalizations.of(context)] inside [build], any active
/// SnackBar holding this widget will dynamically update its displayed text if the
/// user switches locales while the feedback is visible on-screen.
class TelemetrySessionActionFeedback extends StatelessWidget {
  const TelemetrySessionActionFeedback({
    super.key,
    required this.result,
    required this.kind,
  });

  final TelemetrySessionActionResult result;
  final TelemetrySessionActionKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = result.message(l10n);
    final message = switch (kind) {
      TelemetrySessionActionKind.export => l10n.telemetryExportFailed(detail),
      TelemetrySessionActionKind.delete => l10n.telemetryDeleteFailed(detail),
    };
    return Text(message);
  }
}
