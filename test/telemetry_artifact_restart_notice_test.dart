import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/core/theme/app_theme.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/telemetry_sessions.dart';
import 'package:torque_obd/ui/widgets/telemetry/telemetry_artifact_restart_notice.dart';
import 'support/localized_app.dart';

void main() {
  testWidgets('restart-owned artifact warning is exact and not dismissible (zh-Hant)', (
    tester,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context, listen: false);
            return localizedMaterialApp(
              theme: AppTheme.dark(),
              locale: traditionalChineseLocale,
              home: const Scaffold(body: TelemetryArtifactRestartNotice()),
            );
          },
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('telemetry-artifact-restart-notice')),
      findsNothing,
    );
    container.read(telemetryArtifactNoticeProvider.notifier).requireRestart();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('telemetry-artifact-restart-notice')),
      findsOneWidget,
    );
    expect(find.text(telemetryArtifactRestartRequiredCopy), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('restart-owned artifact warning renders English copy without Chinese', (
    tester,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context, listen: false);
            return localizedMaterialApp(
              theme: AppTheme.dark(),
              locale: englishLocale,
              home: const Scaffold(body: TelemetryArtifactRestartNotice()),
            );
          },
        ),
      ),
    );

    container.read(telemetryArtifactNoticeProvider.notifier).requireRestart();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('telemetry-artifact-restart-notice')),
      findsOneWidget,
    );
    expect(
      find.text(
        'The state of local file work cannot be confirmed. Quit Telltale completely and reopen it before continuing',
      ),
      findsOneWidget,
    );
    expect(find.text(telemetryArtifactRestartRequiredCopy), findsNothing);
  });

  testWidgets('restart notice dynamically updates copy on locale change without dismissing', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(telemetryArtifactNoticeProvider.notifier).requireRestart();

    var currentLocale = englishLocale;
    late StateSetter setLocaleState;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: StatefulBuilder(
          builder: (context, setState) {
            setLocaleState = setState;
            return localizedMaterialApp(
              locale: currentLocale,
              home: const Scaffold(body: TelemetryArtifactRestartNotice()),
            );
          },
        ),
      ),
    );

    expect(
      find.text(
        'The state of local file work cannot be confirmed. Quit Telltale completely and reopen it before continuing',
      ),
      findsOneWidget,
    );

    // Switch locale to Traditional Chinese
    setLocaleState(() {
      currentLocale = traditionalChineseLocale;
    });
    await tester.pump();

    // Now renders Chinese copy dynamically, notice remains present and active
    expect(
      find.text(
        'The state of local file work cannot be confirmed. Quit Telltale completely and reopen it before continuing',
      ),
      findsNothing,
    );
    expect(find.text(telemetryArtifactRestartRequiredCopy), findsOneWidget);
    expect(
      find.byKey(const ValueKey('telemetry-artifact-restart-notice')),
      findsOneWidget,
    );
    expect(container.read(telemetryArtifactNoticeProvider), isNotNull);
  });
}
