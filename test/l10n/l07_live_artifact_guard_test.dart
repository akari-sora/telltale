import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:torque_obd/core/app_locales_platform.dart';
import 'package:torque_obd/core/share/app_share_platform_bridge.dart';
import 'package:torque_obd/core/share/share_lease_ledger.dart';
import 'package:torque_obd/l10n/app_locales_sync.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/app_share_coordinator.dart';
import 'package:torque_obd/state/artifact_operation_gate.dart';
import 'package:torque_obd/state/language_switch_guard.dart';
import 'package:torque_obd/state/locale_settings.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/telemetry_recorder.dart';
import 'package:torque_obd/telemetry/session/telemetry_recorder.dart';
import 'package:torque_obd/ui/widgets/language_picker.dart';

class _CountingSharedPreferencesStore extends SharedPreferencesStorePlatform {
  _CountingSharedPreferencesStore(this._delegate);
  final SharedPreferencesStorePlatform _delegate;
  final Map<String, int> writeCounts = {};

  int getWriteCount(String key) =>
      (writeCounts[key] ?? 0) + (writeCounts['flutter.$key'] ?? 0);

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    writeCounts[key] = (writeCounts[key] ?? 0) + 1;
    return _delegate.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) {
    writeCounts[key] = (writeCounts[key] ?? 0) + 1;
    return _delegate.remove(key);
  }

  @override
  Future<bool> clear() => _delegate.clear();

  @override
  Future<Map<String, Object>> getAll() => _delegate.getAll();
}

class _FixedProgress extends TelemetryRecorderProgressNotifier {
  @override
  TelemetryRecorderProgress build() => const TelemetryRecorderProgress(
        state: TelemetryRecorderState(phase: TelemetryRecorderPhase.idle),
        elapsedUs: 0,
        bytesBeforeFooter: 0,
        effectiveSessionLimit: null,
        sessionId: null,
      );
}

class _TestAppShareCoordinator extends AppShareCoordinator {
  _TestAppShareCoordinator({
    required super.policy,
    required super.artifactGate,
  }) : super(
          rootDirectory: () async => Directory.systemTemp,
          platform: const AppSharePlatformBridge(),
          idSource: () => 'test-id',
          nowUtc: () => DateTime.now().toUtc(),
          availableBytes: (_) async => 1024 * 1024,
        );
}

class _ControllableSharePlatform implements AppSharePlatform {
  _ControllableSharePlatform({required this.onShare});
  final Future<AppShareResult> Function(AppSharePlatformRequest request) onShare;

  @override
  Future<AppShareResult> share(AppSharePlatformRequest request) => onShare(request);
}

class _ValidSharePolicy implements AppSharePolicy {
  @override
  SharePreparationPermit? freeze() => const SharePreparationPermit(
        recorderEpoch: 1,
        foregroundEpoch: 1,
        connectionEpoch: 1,
        safetyEpoch: 1,
        connectionClass: ShareConnectionClass.disconnected,
      );

  @override
  SharePermitValidation validate(SharePreparationPermit permit) =>
      const SharePermitValidation.valid();
}

class TerminalStateTracker<T> {
  TerminalStateTracker(Future<T> future) {
    _future = future.then(
      (val) {
        result = val;
        isTerminated = true;
        hasError = false;
        return val;
      },
      onError: (Object err, StackTrace stack) {
        error = err;
        stackTrace = stack;
        isTerminated = true;
        hasError = true;
      },
    );
  }

  late final Future<dynamic> _future;
  bool isTerminated = false;
  bool hasError = false;
  T? result;
  Object? error;
  StackTrace? stackTrace;

  Future<bool> awaitTermination(Duration timeout) async {
    if (isTerminated) return true;
    try {
      await _future.timeout(timeout);
    } catch (_) {}
    return isTerminated;
  }
}

/// Represents a structured test failure entry preserving phase/source,
/// the original error object, and original stack trace.
class TestFailureEntry {
  const TestFailureEntry({
    required this.phase,
    required this.error,
    required this.stackTrace,
  });

  final String phase;
  final Object error;
  final StackTrace stackTrace;

  @override
  String toString() => '[$phase] $error\n$stackTrace';
}

/// Test-only aggregate failure thrown when multiple errors occur during a test
/// (e.g. primary body failure, tracked operation error, and/or cleanup failure),
/// preserving all individual error objects and stack traces.
class AggregateTestFailure extends Error {
  AggregateTestFailure(this.failures);

  final List<TestFailureEntry> failures;

  @override
  String toString() {
    final buffer = StringBuffer('AggregateTestFailure (${failures.length} errors):\n');
    for (var i = 0; i < failures.length; i++) {
      buffer.writeln('--- Failure #${i + 1} (${failures[i].phase}) ---');
      buffer.writeln(failures[i].error);
      buffer.writeln(failures[i].stackTrace);
    }
    return buffer.toString();
  }
}

/// Test-only cleanup executor enforcing fail-closed resource preservation
/// when an asynchronous operation is still pending, observing terminal errors,
/// preserving primary body assertion failures, and executing teardown actions
/// in strict order without silent catch-alls or error squashing.
class SafeCleanupRunner<T> {
  SafeCleanupRunner({
    required this.name,
    this.tracker,
    this.trackerSource,
    this.onPreTeardown,
    this.teardownActions = const [],
  });

  final String name;
  final TerminalStateTracker<T>? tracker;
  final TerminalStateTracker<T>? Function()? trackerSource;
  final FutureOr<void> Function()? onPreTeardown;
  final List<void Function()> teardownActions;

  TerminalStateTracker<T>? get effectiveTracker =>
      trackerSource != null ? trackerSource!() : tracker;

  /// Executes [body] and then reliably runs cleanup, preserving any failure from [body]
  /// alongside errors from the tracked operation or teardown actions.
  Future<void> runGuarded({
    required Future<void> Function() body,
    Duration budget = const Duration(seconds: 5),
    Future<bool> Function(Duration)? terminationAwaiter,
  }) async {
    TestFailureEntry? primaryFailure;
    try {
      await body();
    } catch (e, s) {
      primaryFailure = TestFailureEntry(phase: 'body', error: e, stackTrace: s);
    }

    await runCleanup(
      primaryFailure: primaryFailure,
      budget: budget,
      terminationAwaiter: terminationAwaiter,
    );
  }

  /// Runs cleanup directly. If [primaryFailure] is provided, it is retained
  /// and aggregated with any teardown or tracked-operation errors.
  Future<void> runCleanup({
    TestFailureEntry? primaryFailure,
    Duration budget = const Duration(seconds: 5),
    Future<bool> Function(Duration)? terminationAwaiter,
  }) async {
    final List<TestFailureEntry> failures = [];
    if (primaryFailure != null) {
      failures.add(primaryFailure);
    }

    // 1. Pre-teardown action (e.g. unblocking barriers so pending worker can advance)
    if (onPreTeardown != null) {
      try {
        await onPreTeardown!();
      } catch (e, s) {
        failures.add(TestFailureEntry(phase: 'pre-teardown', error: e, stackTrace: s));
      }
    }

    // 2. Await terminal state of tracked future
    final t = effectiveTracker;
    bool terminated = false;
    try {
      if (t == null) {
        terminated = true;
      } else if (terminationAwaiter != null) {
        terminated = await terminationAwaiter(budget);
      } else {
        terminated = await t.awaitTermination(budget);
      }
    } catch (e, s) {
      failures.add(TestFailureEntry(phase: 'termination-await', error: e, stackTrace: s));
    }

    if (!terminated) {
      // Pending state: Strictly fail-closed.
      // Do NOT release token, delete directory, dispose container, or restore platform mocks!
      failures.add(TestFailureEntry(
        phase: 'pending-timeout',
        error: StateError('$name: operation failed to reach terminal state within cleanup budget of $budget'),
        stackTrace: StackTrace.current,
      ));
    } else {
      // 3. Normal or error termination: Execute cleanup actions in order, capturing both error and stackTrace.
      for (var i = 0; i < teardownActions.length; i++) {
        try {
          teardownActions[i]();
        } catch (e, s) {
          failures.add(TestFailureEntry(phase: 'teardown-action-$i', error: e, stackTrace: s));
        }
      }

      // 4. If the original operation ended in error termination, preserve the error and stackTrace
      if (t != null && t.hasError) {
        failures.add(TestFailureEntry(
          phase: 'tracked-operation',
          error: t.error!,
          stackTrace: t.stackTrace ?? StackTrace.current,
        ));
      }
    }

    // 5. Throw failures according to policy:
    if (failures.isEmpty) {
      return;
    }
    if (failures.length == 1) {
      Error.throwWithStackTrace(failures.first.error, failures.first.stackTrace);
    } else {
      throw AggregateTestFailure(failures);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task TELLTALE-L02-LIVE-ARTIFACT-GUARD (Refs #36, #40, #34)', () {
    // LG01: 在真Gate上先讀none，acquire後無手動invalidate即讀到artifactBusy；release後恢復none
    test('LG01: live Gate reactivity updates languageSwitchBlock without manual invalidation', () {
      final container = ProviderContainer(
        overrides: [
          telemetryRecorderProgressProvider.overrideWith(_FixedProgress.new),
        ],
      );
      addTearDown(container.dispose);

      // Initial read establishes cache in Riverpod
      expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.none);
      expect(container.read(artifactOperationSnapshotProvider).isIdle, isTrue);

      final gate = container.read(artifactOperationGateProvider);

      // Acquire gate
      final acquireResult = gate.tryAcquire('test-export-owner', ArtifactOperation.export);
      expect(acquireResult.acquired, isTrue);
      final token = acquireResult.token!;

      // Directly read without any container.invalidate()
      expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.artifactBusy);
      final busySnapshot = container.read(artifactOperationSnapshotProvider);
      expect(busySnapshot.isIdle, isFalse);
      expect(busySnapshot.ownerId, 'test-export-owner');
      expect(busySnapshot.operation, ArtifactOperation.export);

      // Release gate
      gate.release(token);

      // Directly read without any container.invalidate()
      expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.none);
    });

    // LG02: gate/coordinator identity與active token在通知前後不被替換；foreign/reused release仍拒絕
    test('LG02: gate/coordinator identity and active token preserved across notifications; foreign/reused release rejected', () {
      final container = ProviderContainer(
        overrides: [
          telemetryRecorderProgressProvider.overrideWith(_FixedProgress.new),
          appShareCoordinatorProvider.overrideWith(
            (ref) => _TestAppShareCoordinator(
              policy: ref.watch(appSharePolicyProvider),
              artifactGate: ref.watch(artifactOperationGateProvider),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Establish initial snapshot and guard subscriptions before first acquire
      // to verify identity preservation during active notification
      expect(container.read(artifactOperationSnapshotProvider).isIdle, isTrue);
      expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.none);

      final initialGate = container.read(artifactOperationGateProvider);
      final initialCoordinator = container.read(appShareCoordinatorProvider);

      final acquireResult = initialGate.tryAcquire('owner-primary', ArtifactOperation.rawTranscriptShare);
      expect(acquireResult.acquired, isTrue);
      final token = acquireResult.token!;

      // Identity MUST not change across notification
      expect(identical(container.read(artifactOperationGateProvider), initialGate), isTrue);
      expect(identical(container.read(appShareCoordinatorProvider), initialCoordinator), isTrue);

      // Contending acquire is rejected and does not mutate owner
      final contenderResult = initialGate.tryAcquire('owner-contender', ArtifactOperation.delete);
      expect(contenderResult.acquired, isFalse);
      expect(contenderResult.failure, ArtifactAcquireFailure.artifactBusy);
      expect(container.read(artifactOperationSnapshotProvider).ownerId, 'owner-primary');

      // Foreign release rejected
      final foreignGate = ArtifactOperationGate();
      addTearDown(foreignGate.dispose);
      final foreignToken = foreignGate.tryAcquire('owner-foreign', ArtifactOperation.install).token!;
      expect(() => initialGate.release(foreignToken), throwsStateError);

      // State remains busy with original token
      expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.artifactBusy);

      // Legitimate release
      initialGate.release(token);
      expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.none);

      // Reused release rejected
      expect(() => initialGate.release(token), throwsStateError);

      // Identity still intact
      expect(identical(container.read(artifactOperationGateProvider), initialGate), isTrue);
      expect(identical(container.read(appShareCoordinatorProvider), initialCoordinator), isTrue);
    });

    // LG03: LanguagePicker 元件在 busy 時點擊被擋、不改 locale、不呼叫額外 OS setter 或 store；idle 後可合法切換
    testWidgets('LG03: LanguagePicker component action blocked during artifactBusy, unblocked when idle', (tester) async {
      final previousStore = SharedPreferencesStorePlatform.instance;
      addTearDown(() {
        SharedPreferencesStorePlatform.instance = previousStore;
      });

      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
        kLocaleOsMigratedKey: true,
      });
      final countingStore = _CountingSharedPreferencesStore(SharedPreferencesStorePlatform.instance);
      SharedPreferencesStorePlatform.instance = countingStore;
      final prefs = await SharedPreferences.getInstance();

      final osSetCalls = <List<String>>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        (call) async {
          if (call.method == kAppLocalesGetMethod) {
            return {
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': false,
              'overrideTags': ['en'],
              'configurationTags': ['en'],
            };
          }
          if (call.method == kAppLocalesSetMethod) {
            final args = call.arguments as Map?;
            final tags = (args?['tags'] as List?)?.cast<String>() ?? [];
            osSetCalls.add(tags);
            return {
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': false,
              'overrideTags': tags,
              'configurationTags': tags,
            };
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(AppLocalesPlatform.channel, null);
        AppLocalesPlatform.live = false;
      });
      AppLocalesPlatform.live = true;

      late WidgetRef widgetRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            telemetryRecorderProgressProvider.overrideWith(_FixedProgress.new),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              final locale = resolveAppLocale(
                preference: ref.watch(localePreferenceProvider),
                deviceLocales: const [Locale('en')],
              );
              return MaterialApp(
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: const Scaffold(body: LanguagePicker()),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gate = widgetRef.read(artifactOperationGateProvider);

      // Record baseline write count
      final baselineWrites = countingStore.getWriteCount(kLocalePreferenceKey);

      // Acquire gate to make it busy
      final token = gate.tryAcquire('active-export', ArtifactOperation.export).token!;
      await tester.pump();

      // Attempt to change language to Traditional Chinese while busy
      await tester.tap(find.byKey(const Key('locale_traditionalChinese')));
      await tester.pumpAndSettle();

      // Block message shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(AppLocalizations.of(tester.element(find.byType(LanguagePicker))).telemetryBlockedByRecorder), findsOneWidget);

      // Store NOT written (0 delta writes, stays 'en'), OS NOT called (0 calls)
      expect(countingStore.getWriteCount(kLocalePreferenceKey) - baselineWrites, 0);
      expect(countingStore.getWriteCount(kLocaleOsMigratedKey), 0);
      expect(prefs.getString(kLocalePreferenceKey), 'en');
      expect(osSetCalls, isEmpty);
      expect(widgetRef.read(localePreferenceProvider), LocalePreference.english);

      // Release gate
      gate.release(token);
      await tester.pumpAndSettle();

      // Now tap again when idle
      await tester.tap(find.byKey(const Key('locale_traditionalChinese')));
      await tester.pumpAndSettle();

      // Successfully switched! Positive control: write count increased by exactly 1
      expect(countingStore.getWriteCount(kLocalePreferenceKey) - baselineWrites, 1);
      expect(prefs.getString(kLocalePreferenceKey), 'zh_Hant');
      expect(osSetCalls.length, 1);
      expect(osSetCalls.first, ['zh-Hant']);
      expect(widgetRef.read(localePreferenceProvider), LocalePreference.traditionalChinese);
    });

    // LG04a: queued setter在排隊後、開始執行前由idle→busy，實際下一步尊重最新guard
    test('LG04a: queued setter aborts before execution if gate becomes busy while queued', () async {
      final previousStore = SharedPreferencesStorePlatform.instance;
      addTearDown(() {
        SharedPreferencesStorePlatform.instance = previousStore;
      });

      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
        kLocaleOsMigratedKey: true,
      });
      final countingStore = _CountingSharedPreferencesStore(SharedPreferencesStorePlatform.instance);
      SharedPreferencesStorePlatform.instance = countingStore;
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          telemetryRecorderProgressProvider.overrideWith(_FixedProgress.new),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(localePreferenceProvider.notifier);
      final gate = container.read(artifactOperationGateProvider);

      // Start set operation (queued on _persistQueue microtask)
      final setFuture = controller.set(LocalePreference.traditionalChinese);

      // Acquire gate synchronously before microtask executes
      final token = gate.tryAcquire('queued-barrier-task', ArtifactOperation.export).token!;

      // The set should fail and roll back state because guard detected busy
      final success = await setFuture;
      expect(success, isFalse);
      expect(container.read(localePreferenceProvider), LocalePreference.english);
      expect(controller.committed, LocalePreference.english);
      expect(countingStore.getWriteCount(kLocalePreferenceKey), 0);
      expect(prefs.getString(kLocalePreferenceKey), 'en');
      expect(controller.needsReconcile, isFalse);

      gate.release(token);
    });

    // LG04b: queued setter在OS-get await期間由idle→busy，跨await檢查guard立即讓位abort，0次OS set、0次store寫入
    test('LG04b: queued setter aborts across OS-get await if gate becomes busy, zero OS set and zero store writes', () async {
      final previousStore = SharedPreferencesStorePlatform.instance;
      // Note: previousStore restoration is explicitly registered in SafeCleanupRunner
      // rather than unconditional addTearDown, ensuring no store replacement occurs if setter remains pending!

      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
        kLocaleOsMigratedKey: true,
      });
      final countingStore = _CountingSharedPreferencesStore(SharedPreferencesStorePlatform.instance);
      SharedPreferencesStorePlatform.instance = countingStore;
      final prefs = await SharedPreferences.getInstance();

      var osGetCalls = 0;
      var osSetCalls = 0;
      final getEntered = Completer<void>();
      final releaseGet = Completer<Map<String, Object>>();

      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppLocalesPlatform.channel,
        (call) async {
          if (call.method == kAppLocalesGetMethod) {
            osGetCalls++;
            if (!getEntered.isCompleted) {
              getEntered.complete();
            }
            return releaseGet.future;
          }
          if (call.method == kAppLocalesSetMethod) {
            osSetCalls++;
            return {
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': false,
              'overrideTags': ['zh-Hant'],
              'configurationTags': ['zh-Hant'],
            };
          }
          return null;
        },
      );
      AppLocalesPlatform.live = true;

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          telemetryRecorderProgressProvider.overrideWith(_FixedProgress.new),
        ],
      );

      ArtifactOperationToken? token;
      Future<bool>? setFuture;
      TerminalStateTracker<bool>? setTracker;
      final gate = container.read(artifactOperationGateProvider);

      final cleanup = SafeCleanupRunner<bool>(
        name: 'LG04b',
        trackerSource: () => setTracker,
        onPreTeardown: () {
          // Unblock OS get barrier if pending so setter can resume
          if (!releaseGet.isCompleted) {
            releaseGet.complete({
              'apiSupported': true,
              'sdkInt': 36,
              'followsSystem': false,
              'overrideTags': ['en'],
              'configurationTags': ['en'],
            });
          }
        },
        teardownActions: [
          () {
            if (token != null && !gate.snapshot.isIdle) {
              gate.release(token!);
            }
          },
          () => container.dispose(),
          () => binding.defaultBinaryMessenger.setMockMethodCallHandler(AppLocalesPlatform.channel, null),
          () => AppLocalesPlatform.live = false,
          () => SharedPreferencesStorePlatform.instance = previousStore,
        ],
      );

      await cleanup.runGuarded(
        budget: const Duration(seconds: 5),
        body: () async {
          final controller = container.read(localePreferenceProvider.notifier);

          // Verify gate is initially idle
          expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.none);

          // Begin setter: enters AppLocalesPlatform.get() and awaits
          setFuture = controller.set(LocalePreference.traditionalChinese);
          setTracker = TerminalStateTracker<bool>(setFuture!);

          // Wait until AppLocalesPlatform.get() is genuinely entered and suspended (bounded wait)
          await getEntered.future.timeout(const Duration(seconds: 10));
          expect(osGetCalls, 1);
          expect(osSetCalls, 0);
          expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.none);

          // Gate becomes busy during the in-flight OS-get await window
          token = gate.tryAcquire('live-barrier-task', ArtifactOperation.export).token!;
          expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.artifactBusy);

          // Now release the OS get handler with valid snapshot
          releaseGet.complete({
            'apiSupported': true,
            'sdkInt': 36,
            'followsSystem': false,
            'overrideTags': ['en'],
            'configurationTags': ['en'],
          });

          // The setter resumes, evaluates guard across await, and immediately aborts (bounded wait)
          final success = await setFuture!.timeout(const Duration(seconds: 10));
          expect(success, isFalse);

          // Exact boundaries:
          // OS get = 1, OS set = 0
          expect(osGetCalls, 1);
          expect(osSetCalls, 0);

          // Preference store write = 0 verified via counting store
          expect(countingStore.getWriteCount(kLocalePreferenceKey), 0);
          expect(countingStore.getWriteCount(kLocaleOsMigratedKey), 0);
          expect(prefs.getString(kLocalePreferenceKey), 'en');

          // State and committed rolled back to English
          expect(container.read(localePreferenceProvider), LocalePreference.english);
          expect(controller.committed, LocalePreference.english);

          // No unnecessary reconcile flag set because OS setter was never invoked
          expect(controller.needsReconcile, isFalse);
        },
      );
    });

    // LG05a: gate owner與token專屬權在UI掛載與移除期間保持不變
    testWidgets('LG05a: gate owner and token exclusivity persist across UI mount and unmount', (tester) async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
        kLocaleOsMigratedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          telemetryRecorderProgressProvider.overrideWith(_FixedProgress.new),
        ],
      );
      addTearDown(container.dispose);

      final gate = container.read(artifactOperationGateProvider);

      // Export begins with token
      final token = gate.tryAcquire('export-session-42', ArtifactOperation.export).token!;
      expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.artifactBusy);

      // Mount and unmount UI
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: Text('Screen A')),
          ),
        ),
      );
      await tester.pump();

      // Replace UI with empty container (simulate route pop / screen dispose)
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // Gate owner still intact and valid
      expect(container.read(artifactOperationSnapshotProvider).ownerId, 'export-session-42');
      expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.artifactBusy);

      // Language switch attempt blocked
      final blockedOk = await container.read(localePreferenceProvider.notifier).set(LocalePreference.traditionalChinese);
      expect(blockedOk, isFalse);

      // Export completes normally and releases
      gate.release(token);
      expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.none);

      // Language switch now succeeds
      final ok = await container.read(localePreferenceProvider.notifier).set(LocalePreference.traditionalChinese);
      expect(ok, isTrue);
    });

    // LG05b: 真 pending export coordinator 交易在 UI unmount 後由原 owner 自行收尾，測試不手動 release
    testWidgets('LG05b: real pending export coordinator transaction completes after UI unmount and owner self-releases', (tester) async {
      final previousStore = SharedPreferencesStorePlatform.instance;
      addTearDown(() {
        SharedPreferencesStorePlatform.instance = previousStore;
      });

      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
        kLocaleOsMigratedKey: true,
      });
      final countingStore = _CountingSharedPreferencesStore(SharedPreferencesStorePlatform.instance);
      SharedPreferencesStorePlatform.instance = countingStore;
      final prefs = await SharedPreferences.getInstance();

      final tempDir = Directory.systemTemp.createTempSync('l07_pending_export_');

      final enteredBarrier = Completer<void>.sync();
      final releaseBarrier = Completer<AppShareResult>.sync();

      var platformCalls = 0;
      String? handedOffPath;

      final fakePlatform = _ControllableSharePlatform(
        onShare: (req) async {
          platformCalls++;
          handedOffPath = req.path;
          enteredBarrier.complete();
          return await releaseBarrier.future;
        },
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          telemetryRecorderProgressProvider.overrideWith(_FixedProgress.new),
          appShareCoordinatorProvider.overrideWith(
            (ref) => AppShareCoordinator(
              rootDirectory: () async => tempDir,
              policy: _ValidSharePolicy(),
              artifactGate: ref.watch(artifactOperationGateProvider),
              platform: fakePlatform,
              idSource: () => '0123456789abcdef0123456789abcdef',
              nowUtc: () => DateTime.utc(2026, 9, 27),
              availableBytes: (_) async => 64 * 1024 * 1024,
            ),
          ),
        ],
      );

      Future<AppShareOutcome>? shareFuture;
      TerminalStateTracker<AppShareOutcome>? shareTracker;

      final cleanup = SafeCleanupRunner<AppShareOutcome>(
        name: 'LG05b',
        trackerSource: () => shareTracker,
        onPreTeardown: () {
          // Release platform barrier if not completed
          if (!releaseBarrier.isCompleted) {
            releaseBarrier.complete(AppShareResult.dismissed);
          }
        },
        teardownActions: [
          () => container.dispose(),
          () {
            if (tempDir.existsSync()) {
              tempDir.deleteSync(recursive: true);
            }
          },
        ],
      );

      await cleanup.runGuarded(
        budget: const Duration(seconds: 5),
        terminationAwaiter: (budget) async {
          final t = cleanup.effectiveTracker;
          if (t == null) return true;
          final res = await tester.runAsync(() => t.awaitTermination(budget));
          return res ?? false;
        },
        body: () async {
          final initialGate = container.read(artifactOperationGateProvider);
          final initialCoordinator = container.read(appShareCoordinatorProvider);

          late AppShareInitializationOutcome initOutcome;
          await tester.runAsync(() async {
            initOutcome = await initialCoordinator.initialize();
          });
          expect(initOutcome, AppShareInitializationOutcome.ready);

          // Mount UI holding the scope
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                home: Scaffold(body: Text('Pending Export Screen')),
              ),
            ),
          );
          await tester.pump();

          // Launch real share transaction via coordinator and wait for platform barrier inside real async event loop
          const literalPayload = 'time,rpm,speed\n0,800,0\n';
          await tester.runAsync(() async {
            final f = initialCoordinator.share(
              AppShareRequest(
                sourceKind: ShareSourceKind.pidCsv,
                subject: 'Engine PID Log',
                streamFactory: () => Stream.value(literalPayload.codeUnits),
              ),
            );
            shareTracker = TerminalStateTracker<AppShareOutcome>(f);
            shareFuture = f;
            await enteredBarrier.future.timeout(const Duration(seconds: 10));
          });

          // Assert gate is actively held by the real coordinator owner
          expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.artifactBusy);
          final activeSnapshot = container.read(artifactOperationSnapshotProvider);
          expect(activeSnapshot.isIdle, isFalse);
          expect(activeSnapshot.ownerId, startsWith('share-'));
          expect(activeSnapshot.operation, ArtifactOperation.pidCsvShare);

          // Identity preservation during pending operation
          expect(identical(container.read(artifactOperationGateProvider), initialGate), isTrue);
          expect(identical(container.read(appShareCoordinatorProvider), initialCoordinator), isTrue);

          // Unmount UI while transaction is still pending in platform handoff
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();

          // Gate owner and coordinator are still active in root scope; language switch remains blocked
          expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.artifactBusy);
          expect(identical(container.read(artifactOperationGateProvider), initialGate), isTrue);
          expect(identical(container.read(appShareCoordinatorProvider), initialCoordinator), isTrue);

          final blocked = await container.read(localePreferenceProvider.notifier).set(LocalePreference.traditionalChinese);
          expect(blocked, isFalse);

          // Release platform barrier so coordinator can complete its handoff lifecycle
          late AppShareOutcome outcome;
          await tester.runAsync(() async {
            releaseBarrier.complete(AppShareResult.selected);
            outcome = await shareFuture!.timeout(const Duration(seconds: 10));
          });

          // Await real transaction outcome
          expect(outcome.result, AppShareResult.selected);
          expect(outcome.error, isNull);
          expect(platformCalls, 1);
          expect(handedOffPath, isNotNull);
          expect(File(handedOffPath!).existsSync(), isTrue);

          // Verify exact byte contents match literal payload
          expect(File(handedOffPath!).readAsBytesSync(), literalPayload.codeUnits);

          // Original owner (AppShareCoordinator._shareAdmitted) self-released its token upon exit!
          // Notice: test did NOT invoke gate.release() manually!
          expect(container.read(artifactOperationSnapshotProvider).isIdle, isTrue);
          expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.none);

          // Identity intact after release
          expect(identical(container.read(artifactOperationGateProvider), initialGate), isTrue);
          expect(identical(container.read(appShareCoordinatorProvider), initialCoordinator), isTrue);

          // Language switch now succeeds cleanly
          final allowed = await container.read(localePreferenceProvider.notifier).set(LocalePreference.traditionalChinese);
          expect(allowed, isTrue);
          expect(container.read(localePreferenceProvider), LocalePreference.traditionalChinese);
          expect(prefs.getString(kLocalePreferenceKey), 'zh_Hant');
        },
      );
    });

    // LG06: 無變化／拒絕contender／teardown／provider scope retirement不重複通知、不越代改狀態
    test('LG06: contender refusal, teardown and scope retirement do not cause duplicate notifications', () {
      final container = ProviderContainer(
        overrides: [
          telemetryRecorderProgressProvider.overrideWith(_FixedProgress.new),
        ],
      );
      final gate = container.read(artifactOperationGateProvider);

      var gateNotificationCount = 0;
      gate.addListener(() {
        gateNotificationCount++;
      });

      var snapshotListenerCount = 0;
      final sub = container.listen<ArtifactOperationSnapshot>(
        artifactOperationSnapshotProvider,
        (previous, next) {
          snapshotListenerCount++;
        },
      );

      // 1. Initial acquire -> 1 event
      final res = gate.tryAcquire('first-owner', ArtifactOperation.record);
      expect(res.acquired, isTrue);
      expect(gateNotificationCount, 1);
      expect(snapshotListenerCount, 1);

      // 2. Contender rejection -> 0 events
      final cont = gate.tryAcquire('second-owner', ArtifactOperation.install);
      expect(cont.acquired, isFalse);
      expect(gateNotificationCount, 1);
      expect(snapshotListenerCount, 1);

      // 3. Foreign release -> 0 events
      final rogueGate = ArtifactOperationGate();
      addTearDown(rogueGate.dispose);
      final rogueToken = rogueGate.tryAcquire('rogue', ArtifactOperation.record).token!;
      expect(() => gate.release(rogueToken), throwsStateError);
      expect(gateNotificationCount, 1);
      expect(snapshotListenerCount, 1);

      // 4. Legitimate release -> 1 event
      gate.release(res.token!);
      expect(gateNotificationCount, 2);
      expect(snapshotListenerCount, 2);

      // 5. Reused release -> 0 events
      expect(() => gate.release(res.token!), throwsStateError);
      expect(gateNotificationCount, 2);
      expect(snapshotListenerCount, 2);

      // 6. Teardown / dispose
      sub.close();
      container.dispose();

      // Subsequent gate mutation does not invoke retired subscription
      final postToken = gate.tryAcquire('post-teardown', ArtifactOperation.record).token!;
      expect(snapshotListenerCount, 2);
      gate.release(postToken);
      expect(snapshotListenerCount, 2);

      // New container creates a distinct, fresh, idle gate
      final freshContainer = ProviderContainer(
        overrides: [
          telemetryRecorderProgressProvider.overrideWith(_FixedProgress.new),
        ],
      );
      addTearDown(freshContainer.dispose);
      expect(freshContainer.read(languageSwitchBlockProvider), LanguageSwitchBlock.none);
      expect(freshContainer.read(artifactOperationSnapshotProvider).isIdle, isTrue);
    });

    // LG07: 正控制遍歷九種操作，確保反應橋樑即時反應且無過期快取
    test('LG07: positive control proving reactive bridge eliminates stale snapshot caching across all 9 operations', () {
      final container = ProviderContainer(
        overrides: [
          telemetryRecorderProgressProvider.overrideWith(_FixedProgress.new),
        ],
      );
      addTearDown(container.dispose);

      final gate = container.read(artifactOperationGateProvider);

      // Verify all 9 supported ArtifactOperations properly notify through the reactive bridge
      const operations = [
        ArtifactOperation.record,
        ArtifactOperation.finalize,
        ArtifactOperation.recovery,
        ArtifactOperation.install,
        ArtifactOperation.delete,
        ArtifactOperation.export,
        ArtifactOperation.rawTranscriptShare,
        ArtifactOperation.recoveredTranscriptShare,
        ArtifactOperation.pidCsvShare,
      ];

      for (final op in operations) {
        // Must start idle
        expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.none);

        // Acquire
        final res = gate.tryAcquire('op-${op.name}', op);
        expect(res.acquired, isTrue);

        // Reactive bridge immediately reflects busy without manual invalidate
        expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.artifactBusy, reason: 'Failed for ${op.name}');
        expect(container.read(artifactOperationSnapshotProvider).operation, op);

        // Release
        gate.release(res.token!);
        expect(container.read(languageSwitchBlockProvider), LanguageSwitchBlock.none, reason: 'Failed to clear for ${op.name}');
      }
    });

    // LG08: SafeCleanupRunner preserves resources when operation remains pending, cleans up when terminated, and preserves multi-failure stacks
    test('LG08: safe cleanup runner preserves resources when operation remains pending, cleans up when terminated, and preserves multi-failure stacks', () async {
      // Branch 1: Operation remains pending -> timeout -> strictly fail-closed: resources preserved, StateError thrown
      final barrier1 = Completer<void>();
      final tracker1 = TerminalStateTracker<void>(barrier1.future);
      var gateReleased1 = false;
      var resourcesCleaned1 = false;
      var storeRestored1 = false;

      final runner1 = SafeCleanupRunner<void>(
        name: 'LG08-branch1-pending',
        tracker: tracker1,
        teardownActions: [
          () => gateReleased1 = true,
          () => resourcesCleaned1 = true,
          () => storeRestored1 = true,
        ],
      );

      expect(tracker1.isTerminated, isFalse);
      await expectLater(
        runner1.runCleanup(budget: const Duration(milliseconds: 50)),
        throwsStateError,
      );
      expect(gateReleased1, isFalse);
      expect(resourcesCleaned1, isFalse);
      expect(storeRestored1, isFalse);
      expect(tracker1.isTerminated, isFalse);
      barrier1.complete(); // unblock

      // Branch 2: Normal completion -> reaches normal terminal state -> clean up proceeds safely in order
      final barrier2 = Completer<void>()..complete();
      final tracker2 = TerminalStateTracker<void>(barrier2.future);
      var gateReleased2 = false;
      var resourcesCleaned2 = false;
      var storeRestored2 = false;

      final runner2 = SafeCleanupRunner<void>(
        name: 'LG08-branch2-normal',
        tracker: tracker2,
        teardownActions: [
          () => gateReleased2 = true,
          () => resourcesCleaned2 = true,
          () => storeRestored2 = true,
        ],
      );

      await runner2.runCleanup();
      expect(tracker2.isTerminated, isTrue);
      expect(tracker2.hasError, isFalse);
      expect(gateReleased2, isTrue);
      expect(resourcesCleaned2, isTrue);
      expect(storeRestored2, isTrue);

      // Branch 3: Single operation error -> resources cleaned up, original error and stack trace preserved
      final errorCompleter3 = Completer<void>();
      final errorTracker3 = TerminalStateTracker<void>(errorCompleter3.future);
      const sentinelError3 = FormatException('sentinel-tracker-failure-3');
      final sentinelStack3 = StackTrace.fromString('sentinel-stack-trace-line-3\nanother-line-3');
      errorCompleter3.completeError(sentinelError3, sentinelStack3);

      var errorResourcesCleaned3 = false;
      final errorRunner3 = SafeCleanupRunner<void>(
        name: 'LG08-branch3-op-error',
        tracker: errorTracker3,
        teardownActions: [
          () => errorResourcesCleaned3 = true,
        ],
      );

      Object? actualError3;
      StackTrace? actualStack3;
      try {
        await errorRunner3.runCleanup();
      } catch (e, s) {
        actualError3 = e;
        actualStack3 = s;
      }
      expect(identical(actualError3, sentinelError3), isTrue,
          reason: 'Expected sentinel error but caught: $actualError3\n$actualStack3');
      expect(actualStack3.toString(), contains('sentinel-stack-trace-line-3'));
      expect(errorResourcesCleaned3, isTrue);
      expect(errorTracker3.isTerminated, isTrue);
      expect(errorTracker3.hasError, isTrue);

      // Branch 4: Single teardown action error -> surfaces cleanup error and stack trace
      final normalCompleter4 = Completer<void>()..complete();
      final normalTracker4 = TerminalStateTracker<void>(normalCompleter4.future);
      final sentinelTeardownError4 = StateError('teardown-action-fault-4');

      final runner4 = SafeCleanupRunner<void>(
        name: 'LG08-branch4-teardown-error',
        tracker: normalTracker4,
        teardownActions: [
          () => throw sentinelTeardownError4,
        ],
      );

      Object? actualError4;
      StackTrace? actualStack4;
      try {
        await runner4.runCleanup();
      } catch (e, s) {
        actualError4 = e;
        actualStack4 = s;
      }
      expect(identical(actualError4, sentinelTeardownError4), isTrue,
          reason: 'Expected teardown error but caught: $actualError4\n$actualStack4');
      expect(actualStack4.toString(), isNotEmpty);

      // Branch 5: Operation error + teardown error -> AggregateTestFailure preserves both errors & stacks
      final errorCompleter5 = Completer<void>();
      final errorTracker5 = TerminalStateTracker<void>(errorCompleter5.future);
      const sentinelOpError5 = FormatException('sentinel-op-error-5');
      final sentinelOpStack5 = StackTrace.fromString('stack-trace-op-5');
      errorCompleter5.completeError(sentinelOpError5, sentinelOpStack5);

      final sentinelTeardownError5 = StateError('sentinel-teardown-error-5');
      var actionCleaned5 = false;

      final runner5 = SafeCleanupRunner<void>(
        name: 'LG08-branch5-op-plus-teardown',
        tracker: errorTracker5,
        teardownActions: [
          () => actionCleaned5 = true,
          () => throw sentinelTeardownError5,
        ],
      );

      Object? actualError5;
      try {
        await runner5.runCleanup();
      } catch (e) {
        actualError5 = e;
      }
      expect(actualError5, isA<AggregateTestFailure>(),
          reason: 'Expected AggregateTestFailure but caught: $actualError5');
      final agg5 = actualError5 as AggregateTestFailure;
      expect(agg5.failures.length, 2);
      // Teardown error
      final teardownEntry5 = agg5.failures.firstWhere((f) => f.phase.startsWith('teardown-action'));
      expect(identical(teardownEntry5.error, sentinelTeardownError5), isTrue);
      expect(teardownEntry5.stackTrace.toString(), isNotEmpty);
      // Tracked operation error
      final opEntry5 = agg5.failures.firstWhere((f) => f.phase == 'tracked-operation');
      expect(identical(opEntry5.error, sentinelOpError5), isTrue);
      expect(opEntry5.stackTrace.toString(), contains('stack-trace-op-5'));
      expect(actionCleaned5, isTrue);

      // Branch 6: Primary body failure + teardown cleanup error -> AggregateTestFailure preserves primary assertion
      final normalCompleter6 = Completer<void>()..complete();
      final normalTracker6 = TerminalStateTracker<void>(normalCompleter6.future);
      final sentinelBodyError6 = TestFailure('primary-assertion-failed-6');
      final sentinelTeardownError6 = StateError('sentinel-teardown-error-6');

      final runner6 = SafeCleanupRunner<void>(
        name: 'LG08-branch6-body-plus-teardown',
        tracker: normalTracker6,
        teardownActions: [
          () => throw sentinelTeardownError6,
        ],
      );

      Object? actualError6;
      try {
        await runner6.runGuarded(
          body: () async {
            throw sentinelBodyError6;
          },
        );
      } catch (e) {
        actualError6 = e;
      }
      expect(actualError6, isA<AggregateTestFailure>(),
          reason: 'Expected AggregateTestFailure but caught: $actualError6');
      final agg6 = actualError6 as AggregateTestFailure;
      expect(agg6.failures.length, 2);
      // Primary assertion failure
      final bodyEntry6 = agg6.failures.firstWhere((f) => f.phase == 'body');
      expect(identical(bodyEntry6.error, sentinelBodyError6), isTrue);
      expect(bodyEntry6.stackTrace.toString(), isNotEmpty);
      // Teardown error
      final teardownEntry6 = agg6.failures.firstWhere((f) => f.phase.startsWith('teardown-action'));
      expect(identical(teardownEntry6.error, sentinelTeardownError6), isTrue);
      expect(teardownEntry6.stackTrace.toString(), isNotEmpty);


      // Branch 7: Primary body failure + pending timeout -> AggregateTestFailure preserves primary assertion, strictly fail-closed (no cleanup)
      final barrier7 = Completer<void>();
      final tracker7 = TerminalStateTracker<void>(barrier7.future);
      final sentinelBodyError7 = TestFailure('primary-assertion-failed-7');
      var resourcesCleaned7 = false;

      final runner7 = SafeCleanupRunner<void>(
        name: 'LG08-branch7-body-plus-pending',
        tracker: tracker7,
        teardownActions: [
          () => resourcesCleaned7 = true,
        ],
      );

      try {
        await runner7.runGuarded(
          body: () async {
            throw sentinelBodyError7;
          },
          budget: const Duration(milliseconds: 50),
        );
        fail('Expected AggregateTestFailure');
      } on AggregateTestFailure catch (agg) {
        expect(agg.failures.length, 2);
        // Primary assertion failure
        final bodyEntry = agg.failures.firstWhere((f) => f.phase == 'body');
        expect(identical(bodyEntry.error, sentinelBodyError7), isTrue);
        expect(bodyEntry.stackTrace.toString(), isNotEmpty);
        // Pending timeout failure
        final pendingEntry = agg.failures.firstWhere((f) => f.phase == 'pending-timeout');
        expect(pendingEntry.error, isA<StateError>());
        expect((pendingEntry.error as StateError).message, contains('failed to reach terminal state'));
      }
      expect(resourcesCleaned7, isFalse);
      barrier7.complete(); // unblock
    });
  });
}
