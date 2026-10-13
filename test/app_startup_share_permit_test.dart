/// Startup screen path for a share permit lost during cache reconstruction.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:torque_obd/app.dart';
import 'package:torque_obd/core/share/app_share_platform_bridge.dart';
import 'package:torque_obd/l10n/app_locales_sync.dart';
import 'package:torque_obd/l10n/generated/app_localizations_en.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/telemetry_runtime.dart';
import 'package:torque_obd/state/telemetry_sessions.dart';
import 'package:torque_obd/telemetry/session/telemetry_session_store.dart';

void main() {
  testWidgets(
    'permit lost after freeze offers retry, and resume reaches the router',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
        kLocaleOsMigratedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
        (message) async =>
            const StandardMessageCodec().encodeMessage(<Object?>[null]),
      );
      final shareDir = Directory.systemTemp.createTempSync('startup-share-');
      final telemetryDir = Directory.systemTemp.createTempSync(
        'startup-telemetry-',
      );
      addTearDown(() {
        shareDir.deleteSync(recursive: true);
        telemetryDir.deleteSync(recursive: true);
      });
      final root = Completer<Directory>();
      final policy = _RevocablePolicy();
      final l10n = AppLocalizationsEn();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appSharePolicyProvider.overrideWithValue(policy),
            appShareCoordinatorProvider.overrideWith(
              (ref) => AppShareCoordinator(
                rootDirectory: () => root.future,
                policy: ref.watch(appSharePolicyProvider),
                artifactGate: ref.watch(artifactOperationGateProvider),
                platform: _Platform(),
                idSource: () => 'fedcba9876543210fedcba9876543210',
                nowUtc: () => DateTime.utc(2026),
                availableBytes: (_) async => 64 * 1024 * 1024,
              ),
            ),
            telemetrySessionStoreProvider.overrideWithValue(
              TelemetrySessionStore(
                documentsDirectory: () async => telemetryDir,
              ),
            ),
            telemetrySessionLibraryServiceProvider.overrideWithValue(
              TelemetrySessionLibraryService(
                documentsDirectory: () async => telemetryDir,
              ),
            ),
          ],
          child: const TorqueApp(),
        ),
      );
      await tester.pump();
      expect(find.text(l10n.startupChecking), findsOneWidget);

      // Freeze succeeded; the shared engine then loses the foreground before
      // the cache directory lookup returns.
      policy.revoked = true;
      root.complete(shareDir);
      await tester.pump();
      await tester.pump();

      expect(find.text(l10n.startupRestartRequired), findsNothing);
      expect(find.text(l10n.startupCannotComplete), findsOneWidget);
      expect(find.text(l10n.startupRetry), findsOneWidget);

      // The phone UI opens later: the resume edge retries startup.
      policy.revoked = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(
        await _pumpUntil(
          tester,
          () => find.byType(InheritedGoRouter).evaluate().isNotEmpty,
        ),
        isTrue,
      );
      expect(find.text(l10n.startupRetry), findsNothing);
    },
  );
}

Future<bool> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return true;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  return condition();
}

class _RevocablePolicy implements AppSharePolicy {
  bool revoked = false;

  @override
  SharePreparationPermit? freeze() => const SharePreparationPermit(
    recorderEpoch: 1,
    foregroundEpoch: 1,
    connectionEpoch: 1,
    safetyEpoch: 1,
    connectionClass: ShareConnectionClass.disconnected,
  );

  @override
  SharePermitValidation validate(SharePreparationPermit permit) => revoked
      ? const SharePermitValidation.invalid(SharePermitCause.foreground)
      : const SharePermitValidation.valid();
}

class _Platform implements AppSharePlatform {
  @override
  Future<AppShareResult> share(AppSharePlatformRequest request) async =>
      AppShareResult.selected;
}
