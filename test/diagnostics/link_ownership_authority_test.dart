import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';
import 'package:torque_obd/diagnostics/diagnostic_link_ownership.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_catalog.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/powertrain_battery_profiles.dart';

import '../support/fake_elm327.dart';

Future<ProviderContainer> _createContainer(Map<String, Object> prefsValues) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
}

FakeElm327 _createBmsAdapter({
  String responder = '789',
  List<int>? response,
}) =>
    FakeElm327(
      protocol: BusProtocol.can11,
      ecus: [
        FakeEcu(
          name: 'ECM',
          requestId: '7E0',
          responseId: '7E8',
          responses: const {
            '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x13],
            '010D': [0x41, 0x0D, 0x3C],
            '015E': [0x41, 0x5E, 0x00, 0x64],
          },
        ),
        FakeEcu(
          name: 'BMS',
          requestId: '781',
          responseId: responder,
          responses: response == null ? const {} : {'22B046': response},
        ),
      ],
    );

Future<void> _waitForWireCommand(
  FakeElm327 adapter,
  String command, {
  int afterCount = 0,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  int count() => adapter.commandLog.where((wire) => wire == command).length;
  while (count() <= afterCount && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(count(), greaterThan(afterCount));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DiagnosticLinkOwnershipAuthority Unit Contract (B1~B7)', () {
    test('B1 & B2: oneShot pauses polling before action and restores after success', () async {
      final timeline = <String>[];
      bool pollingRunning = true;
      bool canRestore = true;
      bool restoredCallbackFired = false;

      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => pollingRunning,
        pausePolling: () async {
          timeline.add('pause');
          pollingRunning = false;
        },
        resumePolling: () {
          timeline.add('resume');
          pollingRunning = true;
        },
        canRestorePolling: () => canRestore,
        onDisplacedPollingRestored: () {
          restoredCallbackFired = true;
        },
      );

      final result = await authority.runOneShot<String>(
        operationName: 'testAction',
        action: () async {
          expect(pollingRunning, isFalse, reason: 'Polling must be stopped before action begins');
          expect(authority.hasDisplacedPolling, isTrue);
          expect(authority.activeTakeovers, 1);
          timeline.add('action');
          return 'done';
        },
      );

      expect(result, 'done');
      expect(timeline, ['pause', 'action', 'resume']);
      expect(pollingRunning, isTrue);
      expect(restoredCallbackFired, isTrue);
      expect(authority.displacedRestorationCount, 1);
      expect(authority.activeTakeovers, 0);
      expect(authority.hasDisplacedPolling, isFalse);
    });

    test('B2: action does not begin if pause fails to stop polling', () async {
      bool pollingRunning = true;
      bool restoredCallbackFired = false;
      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => pollingRunning,
        pausePolling: () async {
          // Intentional failure: leaves pollingRunning true
        },
        resumePolling: () {},
        canRestorePolling: () => true,
        onDisplacedPollingRestored: () {
          restoredCallbackFired = true;
        },
      );

      bool actionExecuted = false;
      await expectLater(
        authority.runOneShot<void>(
          operationName: 'failingPause',
          action: () async {
            actionExecuted = true;
          },
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.transportFailure,
          ),
        ),
      );

      expect(actionExecuted, isFalse);
      expect(restoredCallbackFired, isFalse, reason: 'Must not fire callback if pause fails');
      expect(authority.displacedRestorationCount, 0);
      expect(authority.activeTakeovers, 0);
    });

    test('B3: concurrent oneShots serialize FIFO and never overlap with max active = 1', () async {
      final timeline = <String>[];
      int maxConcurrent = 0;
      bool pollingRunning = true;

      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => pollingRunning,
        pausePolling: () async {
          timeline.add('pause');
          pollingRunning = false;
        },
        resumePolling: () {
          timeline.add('resume');
          pollingRunning = true;
        },
        canRestorePolling: () => true,
      );

      Future<int> scheduleTask(int id, int delayMs) {
        return authority.runOneShot<int>(
          operationName: 'task$id',
          action: () async {
            if (authority.activeTakeovers > maxConcurrent) {
              maxConcurrent = authority.activeTakeovers;
            }
            timeline.add('action$id-start');
            await Future<void>.delayed(Duration(milliseconds: delayMs));
            timeline.add('action$id-end');
            return id;
          },
        );
      }

      final f1 = scheduleTask(1, 30);
      final f2 = scheduleTask(2, 20);
      final f3 = scheduleTask(3, 10);

      final results = await Future.wait([f1, f2, f3]);
      expect(results, [1, 2, 3]);
      expect(maxConcurrent, 1, reason: 'Max active takeover actions must be 1');

      expect(
        timeline,
        [
          'pause', 'action1-start', 'action1-end', 'resume',
          'pause', 'action2-start', 'action2-end', 'resume',
          'pause', 'action3-start', 'action3-end', 'resume',
        ],
      );
    });

    test('B4: failed first action does not poison queued second action', () async {
      bool pollingRunning = true;
      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => pollingRunning,
        pausePolling: () async {
          pollingRunning = false;
        },
        resumePolling: () {
          pollingRunning = true;
        },
        canRestorePolling: () => true,
      );

      final f1 = authority.runOneShot<String>(
        operationName: 'failingAction',
        action: () async {
          throw StateError('Action 1 failed');
        },
      );

      final f2 = authority.runOneShot<String>(
        operationName: 'succeedingAction',
        action: () async {
          return 'Action 2 success';
        },
      );

      await expectLater(f1, throwsA(isA<StateError>()));
      expect(await f2, 'Action 2 success');
      expect(pollingRunning, isTrue);
    });

    test('B5: action failure restores displaced polling and preserves original error', () async {
      bool pollingRunning = true;
      bool resumed = false;
      bool restoredCallbackFired = false;

      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => pollingRunning,
        pausePolling: () async {
          pollingRunning = false;
        },
        resumePolling: () {
          resumed = true;
          pollingRunning = true;
        },
        canRestorePolling: () => true,
        onDisplacedPollingRestored: () {
          restoredCallbackFired = true;
        },
      );

      await expectLater(
        authority.runOneShot<void>(
          operationName: 'errorAction',
          action: () async {
            throw const FormatException('Corrupt ECU payload');
          },
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Corrupt ECU payload',
          ),
        ),
      );

      expect(resumed, isTrue, reason: 'Displaced polling must be restored on error');
      expect(restoredCallbackFired, isTrue, reason: 'onDisplacedPollingRestored must be invoked when displaced polling is restored after error');
      expect(authority.displacedRestorationCount, 1);
      expect(pollingRunning, isTrue);
    });

    test('B6: already-stopped polling is not paused or resumed', () async {
      final timeline = <String>[];
      bool pollingRunning = false;
      bool restoredCallbackFired = false;

      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => pollingRunning,
        pausePolling: () async {
          timeline.add('pause');
        },
        resumePolling: () {
          timeline.add('resume');
          pollingRunning = true;
        },
        canRestorePolling: () => true,
        onDisplacedPollingRestored: () {
          restoredCallbackFired = true;
        },
      );

      final result = await authority.runOneShot<int>(
        operationName: 'quietAction',
        action: () async {
          timeline.add('action');
          return 42;
        },
      );

      expect(result, 42);
      expect(timeline, ['action'], reason: 'No pause or resume fabricated if polling was already stopped');
      expect(pollingRunning, isFalse);
      expect(restoredCallbackFired, isFalse, reason: 'onDisplacedPollingRestored must not fire when polling was not displaced');
      expect(authority.displacedRestorationCount, 0);
    });

    test('B7: retired boundary suppresses polling restoration', () async {
      bool pollingRunning = true;
      bool resumed = false;
      bool canRestore = true;
      bool restoredCallbackFired = false;

      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => pollingRunning,
        pausePolling: () async {
          pollingRunning = false;
        },
        resumePolling: () {
          resumed = true;
          pollingRunning = true;
        },
        canRestorePolling: () => canRestore,
        onDisplacedPollingRestored: () {
          restoredCallbackFired = true;
        },
      );

      await authority.runOneShot<void>(
        operationName: 'lifecycleRetiredAction',
        action: () async {
          // Simulate boundary event (e.g. background pause, disconnect)
          canRestore = false;
        },
      );

      expect(resumed, isFalse, reason: 'Polling must NOT be resumed if canRestorePolling is false');
      expect(restoredCallbackFired, isFalse, reason: 'onDisplacedPollingRestored must not fire when polling restoration is suppressed');
      expect(authority.displacedRestorationCount, 0);
      expect(pollingRunning, isFalse);
    });

    test('onDisplacedPollingRestored contract: triggered iff displaced polling is successfully restored', () async {
      int callbackCount = 0;
      bool running = true;
      bool canRestore = true;

      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => running,
        pausePolling: () async => running = false,
        resumePolling: () => running = true,
        canRestorePolling: () => canRestore,
        onDisplacedPollingRestored: () => callbackCount++,
      );

      // 1. Displaced + canRestore true -> triggers callback and increments counter
      await authority.runOneShot(operationName: 'successRestore', action: () async => 'ok');
      expect(callbackCount, 1);
      expect(authority.displacedRestorationCount, 1);

      // 2. Not displaced (polling is already stopped) -> does NOT trigger callback
      running = false;
      await authority.runOneShot(operationName: 'notDisplaced', action: () async => 'ok');
      expect(callbackCount, 1, reason: 'Must not trigger if polling was not displaced');
      expect(authority.displacedRestorationCount, 1);

      // 3. Displaced but restoration suppressed by canRestorePolling returning false -> does NOT trigger callback
      running = true;
      canRestore = false;
      await authority.runOneShot(operationName: 'suppressedRestore', action: () async => 'ok');
      expect(callbackCount, 1, reason: 'Must not trigger if restoration is suppressed');
      expect(authority.displacedRestorationCount, 1);

      // 4. Displaced but authority is disposed during action execution -> does NOT trigger callback
      running = true;
      canRestore = true;
      await authority.runOneShot(
        operationName: 'disposedMidFlight',
        action: () async {
          authority.dispose();
        },
      );
      expect(callbackCount, 1, reason: 'Must not trigger if authority was disposed');
      expect(authority.displacedRestorationCount, 1);
    });

    test('Pre-admission cancellation throws cancelled without running pause or action', () async {
      bool pauseCalled = false;
      bool actionCalled = false;
      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => true,
        pausePolling: () async => pauseCalled = true,
        resumePolling: () {},
        canRestorePolling: () => true,
      );

      final cts = DiagnosticCancellationTokenSource();
      cts.cancel();

      await expectLater(
        authority.runOneShot<void>(
          operationName: 'cancelledAction',
          action: () async => actionCalled = true,
          cancellation: cts.token,
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.cancelled,
          ),
        ),
      );

      expect(pauseCalled, isFalse);
      expect(actionCalled, isFalse);
    });

    test('Pre-admission expired deadline throws deadlineExpired without running pause or action', () async {
      bool pauseCalled = false;
      bool actionCalled = false;
      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => true,
        pausePolling: () async => pauseCalled = true,
        resumePolling: () {},
        canRestorePolling: () => true,
      );

      await expectLater(
        authority.runOneShot<void>(
          operationName: 'expiredAction',
          action: () async => actionCalled = true,
          deadline: DateTime.now().subtract(const Duration(milliseconds: 10)),
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.deadlineExpired,
          ),
        ),
      );

      expect(pauseCalled, isFalse);
      expect(actionCalled, isFalse);
    });

    test('In-queue cancellation throws cancelled without running action', () async {
      bool pollingRunning = true;
      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => pollingRunning,
        pausePolling: () async => pollingRunning = false,
        resumePolling: () => pollingRunning = true,
        canRestorePolling: () => true,
      );

      final cts = DiagnosticCancellationTokenSource();

      final first = authority.runOneShot<void>(
        operationName: 'longFirst',
        action: () async {
          await Future<void>.delayed(const Duration(milliseconds: 40));
        },
      );

      final second = authority.runOneShot<void>(
        operationName: 'cancelledSecond',
        action: () async {},
        cancellation: cts.token,
      );

      cts.cancel();
      await first;

      await expectLater(
        second,
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.cancelled,
          ),
        ),
      );
    });

    test('Disposed authority rejects new takeovers with retiredOperation', () async {
      final authority = DiagnosticLinkOwnershipAuthority(
        pollingIsRunning: () => true,
        pausePolling: () async {},
        resumePolling: () {},
        canRestorePolling: () => true,
      );

      authority.dispose();

      await expectLater(
        authority.runOneShot<void>(
          operationName: 'afterDispose',
          action: () async {},
        ),
        throwsA(
          isA<DiagnosticLinkException>().having(
            (e) => e.kind,
            'kind',
            DiagnosticFailureKind.retiredOperation,
          ),
        ),
      );
    });
  });

  group('ObdSession DiagnosticLinkOwnership Authority Integration (B8~B13)', () {
    test(
      'B8 & B9: slow BMS one-shot pauses polling in-flight, returns same result, and restores polling',
      () async {
        final container = await _createContainer({
          'powertrain_battery_experiments_enabled_v1': true,
        });
        addTearDown(container.dispose);

        final snapshot = await PowertrainBatteryCatalogAsset.load();
        final profile = snapshot.catalog.profiles.singleWhere(
          (p) => p.id == 'mg-zs-ev-au-2021',
        );
        final command = profile.commands.singleWhere(
          (c) => c.modeAndIdentifier == '22B046',
        );

        final adapter = _createBmsAdapter(
          response: const [0x62, 0xB0, 0x46, 0x01, 0xF4],
        );
        adapter.slowCommands[command.modeAndIdentifier] = const Duration(
          milliseconds: 150,
        );

        final session = container.read(obdSessionProvider.notifier);
        expect(await session.connectForTest(adapter, TransportKind.demo), isTrue);

        final consents = container.read(
          powertrainExperimentalProbeConsentsProvider.notifier,
        );
        consents.authorize(
          snapshot: snapshot,
          profileId: profile.id,
          commandKey: command.wireKey,
          vehicleYear: 2021,
          connectionGeneration: session.connectionGeneration,
        );

        // Before probe: polling engine is running
        expect(session.engine?.isRunning, isTrue);

        final pending = session.probePowertrainBatteryCommand(
          snapshot: snapshot,
          profileId: profile.id,
          commandKey: command.wireKey,
          vehicleYear: 2021,
        );

        // Wait for the BMS command to reach the wire
        await _waitForWireCommand(adapter, command.modeAndIdentifier);

        // While BMS probe is in flight: polling engine MUST be stopped
        expect(session.engine?.isRunning, isFalse);

        final result = await pending;
        expect(result.failure, isNull);

        // After BMS probe completes: polling engine MUST be restored
        expect(session.engine?.isRunning, isTrue);

        await session.disconnect();
      },
    );

    test(
      'B11: BMS + lifecycle pause discards result, clears consent, and does not restart polling in background',
      () async {
        final container = await _createContainer({
          'powertrain_battery_experiments_enabled_v1': true,
        });
        addTearDown(container.dispose);

        final snapshot = await PowertrainBatteryCatalogAsset.load();
        final profile = snapshot.catalog.profiles.singleWhere(
          (p) => p.id == 'mg-zs-ev-au-2021',
        );
        final command = profile.commands.singleWhere(
          (c) => c.modeAndIdentifier == '22B046',
        );

        final adapter = _createBmsAdapter(
          response: const [0x62, 0xB0, 0x46, 0x01, 0xF4],
        );
        adapter.slowCommands[command.modeAndIdentifier] = const Duration(
          milliseconds: 200,
        );

        final session = container.read(obdSessionProvider.notifier);
        expect(await session.connectForTest(adapter, TransportKind.demo), isTrue);

        final consents = container.read(
          powertrainExperimentalProbeConsentsProvider.notifier,
        );
        consents.authorize(
          snapshot: snapshot,
          profileId: profile.id,
          commandKey: command.wireKey,
          vehicleYear: 2021,
          connectionGeneration: session.connectionGeneration,
        );

        final pending = session.probePowertrainBatteryCommand(
          snapshot: snapshot,
          profileId: profile.id,
          commandKey: command.wireKey,
          vehicleYear: 2021,
        );

        await _waitForWireCommand(adapter, command.modeAndIdentifier);

        final binding = TestWidgetsFlutterBinding.ensureInitialized();
        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

        await expectLater(
          pending,
          throwsA(
            isA<PowertrainProbeRefusedException>().having(
              (e) => e.refusal,
              'refusal',
              PowertrainProbeRefusal.discardedAtLifecycleBoundary,
            ),
          ),
        );

        expect(
          container.read(powertrainExperimentalProbeConsentsProvider),
          isEmpty,
        );

        // While in background: polling must NOT be running
        expect(session.engine?.isRunning, isFalse);

        binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await session.disconnect();
      },
    );

    test('B12: session responder census pauses polling in-flight and restores polling', () async {
      final container = await _createContainer({});
      addTearDown(container.dispose);

      final adapter = _createBmsAdapter();
      adapter.slowCommands['0100'] = const Duration(milliseconds: 100);

      final session = container.read(obdSessionProvider.notifier);
      expect(await session.connectForTest(adapter, TransportKind.demo), isTrue);

      expect(session.engine?.isRunning, isTrue);

      // Trigger census explicitly
      final censusFuture = session.ensureResponderCensus();
      await _waitForWireCommand(adapter, '0100');

      // While census is running on wire, polling engine is paused
      expect(session.engine?.isRunning, isFalse);

      await censusFuture;
      expect(session.engine?.responders, contains('7E8'));

      // After census finishes, polling engine is restored
      expect(session.engine?.isRunning, isTrue);

      await session.disconnect();
    });

    test('B13: restoration restarts incomplete support discovery', () async {
      final container = await _createContainer({});
      addTearDown(container.dispose);

      final adapter = _createBmsAdapter();
      // Ensure support queries allow interruption before completion
      adapter.slowCommands['0120'] = const Duration(milliseconds: 100);

      final session = container.read(obdSessionProvider.notifier);
      expect(await session.connectForTest(adapter, TransportKind.demo), isTrue);

      final engine = session.engine!;
      expect(engine.isRunning, isTrue);

      final authority = session.linkOwnership;
      expect(authority, isNotNull);
      expect(authority!.displacedRestorationCount, 0);

      // Interrupt discovery to enforce that support discovery is genuinely incomplete
      engine.interruptCapabilityDiscovery();
      expect(
        engine.supportDiscoveryComplete,
        isFalse,
        reason: 'Support discovery must be incomplete before diagnostic takeover',
      );
      expect(
        engine.capabilitySummary.phase,
        ObdCapabilityDiscoveryPhase.interrupted,
      );

      // Hook onDisplacedPollingRestored to verify callback invocation
      bool onRestoredFired = false;
      final originalOnRestored = authority.onDisplacedPollingRestored;
      authority.onDisplacedPollingRestored = () {
        onRestoredFired = true;
        originalOnRestored?.call();
      };

      // Perform one-shot takeover (responder census)
      await session.ensureResponderCensus();

      // Assert onDisplacedPollingRestored was invoked and displaced polling was restored
      expect(
        onRestoredFired,
        isTrue,
        reason: 'onDisplacedPollingRestored must be invoked when displaced polling is restored',
      );
      expect(
        authority.displacedRestorationCount,
        1,
        reason: 'Displaced restoration count must increment to 1',
      );
      expect(
        engine.isRunning,
        isTrue,
        reason: 'Polling engine must be running after restoration',
      );

      // Assert that onDisplacedPollingRestored triggered support PID re-discovery
      expect(
        engine.capabilitySummary.phase,
        anyOf(
          ObdCapabilityDiscoveryPhase.running,
          ObdCapabilityDiscoveryPhase.attemptFinished,
        ),
        reason: 'Restoration must restart incomplete support discovery',
      );

      // Await discovery completion and verify supportDiscoveryComplete becomes true
      await engine.discoverSupportedPids();
      expect(
        engine.supportDiscoveryComplete,
        isTrue,
        reason: 'Support discovery must complete after being restarted',
      );
      expect(
        engine.capabilitySummary.phase,
        ObdCapabilityDiscoveryPhase.attemptFinished,
      );

      await session.disconnect();
    });
  });
}
