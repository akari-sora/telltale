/// Comprehensive contract and integration tests for Exclusive Link Ownership
/// and Non-actuating Mode 08 Capability Discovery (WS-05 / #9 Slice 4).
///
/// Ref: Issue #9 (WS-05), Note #3883276863.
/// Verifies:
/// - E1: runOneShot legacy behaviour unchanged.
/// - E2: oneShot and exclusive share the exact same FIFO queue (max-active=1).
/// - E3: oneShot -> exclusive and exclusive -> oneShot execute in strict arrival order.
/// - E4: Failure in one takeover mode does not poison subsequent actions.
/// - E5: Polling engine is verified stopped before exclusive action begins.
/// - E6: Multi-block wire invariant (0800 -> 0820): no normal polling between blocks.
/// - E7: Displaced polling is restored exactly once upon discovery completion.
/// - E8: Lifecycle/background pause retires wire owner and prevents poller restart.
/// - E9: Reconnect retires prior wire owner, preventing stale wire contamination.
/// - E10: Concurrent runDiscovery calls while discovering are ignored (no duplicate exclusive).
/// - E11: Support discovery restart contract is preserved upon restoration.
/// - M1: Premature exclusive release mutation is detectable (polling command interleaving).
/// - M2: Ignoring canRestorePolling mutation is detectable (background poller restart).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';
import 'package:torque_obd/diagnostics/diagnostic_link_ownership.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/service_recipes_provider.dart';

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

FakeElm327 _createMultiBlockMode08Adapter({
  Duration block00Delay = Duration.zero,
  Duration block20Delay = Duration.zero,
}) {
  final fake = FakeElm327(
    protocol: BusProtocol.can11,
    ecus: [
      FakeEcu(
        name: 'ECM',
        requestId: '7E0',
        responseId: '7E8',
        responses: const {
          '0100': [0x41, 0x00, 0xBE, 0x1F, 0xA8, 0x10],
          '010D': [0x41, 0x0D, 0x3C], // Speed = 60 km/h
          '010C': [0x41, 0x0C, 0x1A, 0xF8], // RPM = 1726
        },
        literalResponses: const {
          // 0800: bit 1 (TID 0x01) supported, bit 32 (next block 0x20) supported
          '0800': ['48 00 80 00 00 01'],
          // 0820: bit 1 (TID 0x21) supported, bit 32 (next block) not supported
          '0820': ['48 20 80 00 00 00'],
        },
      ),
    ],
  );

  if (block00Delay > Duration.zero) {
    fake.slowCommands['0800'] = block00Delay;
  }
  if (block20Delay > Duration.zero) {
    fake.slowCommands['0820'] = block20Delay;
  }
  return fake;
}

Future<void> _waitForWireCommand(
  FakeElm327 adapter,
  String command, {
  int afterCount = 0,
  Duration timeout = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  int count() => adapter.commandLog.where((wire) => wire == command).length;
  while (count() <= afterCount && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(count(), greaterThan(afterCount), reason: 'Timed out waiting for wire command $command');
}

Future<void> _waitForInitialCensus(ObdSession session) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while ((session.engine?.responders == null ||
          session.linkOwnership?.activeTakeovers != 0 ||
          session.engine?.supportDiscoveryComplete != true) &&
      DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(session.engine?.responders, isNotNull, reason: 'Initial census must discover responders');
  expect(session.engine?.isRunning, isTrue, reason: 'Polling engine must be running after initial census');
  expect(session.engine?.supportDiscoveryComplete, isTrue, reason: 'Support discovery must complete');
  expect(session.linkOwnership?.displacedRestorationCount, equals(1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DiagnosticLinkOwnershipAuthority Shared FIFO Contract (E1~E4)', () {
    test('E1 & E2 & E3: oneShot and exclusive share same FIFO queue and execute in arrival order', () async {
      final timeline = <String>[];
      final observedModes = <DiagnosticOwnershipMode?>[];
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

      final f1 = authority.runOneShot<String>(
        operationName: 'oneShot1',
        action: () async {
          timeline.add('oneShot1:start');
          observedModes.add(authority.activeMode);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          timeline.add('oneShot1:end');
          return 'res1';
        },
      );

      final f2 = authority.runExclusive<String>(
        operationName: 'exclusive1',
        action: () async {
          timeline.add('exclusive1:start');
          observedModes.add(authority.activeMode);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          timeline.add('exclusive1:end');
          return 'res2';
        },
      );

      final f3 = authority.runOneShot<String>(
        operationName: 'oneShot2',
        action: () async {
          timeline.add('oneShot2:start');
          observedModes.add(authority.activeMode);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          timeline.add('oneShot2:end');
          return 'res3';
        },
      );

      final results = await Future.wait([f1, f2, f3]);
      expect(results, ['res1', 'res2', 'res3']);

      expect(observedModes, [
        DiagnosticOwnershipMode.oneShot,
        DiagnosticOwnershipMode.exclusive,
        DiagnosticOwnershipMode.oneShot,
      ]);

      expect(timeline, [
        'pause',
        'oneShot1:start',
        'oneShot1:end',
        'resume',
        'pause',
        'exclusive1:start',
        'exclusive1:end',
        'resume',
        'pause',
        'oneShot2:start',
        'oneShot2:end',
        'resume',
      ]);
      expect(authority.activeTakeovers, equals(0));
      expect(authority.activeMode, isNull);
      expect(authority.displacedRestorationCount, equals(3));
    });

    test('E4: failed exclusive action does not poison subsequent oneShot or exclusive in queue', () async {
      final timeline = <String>[];
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

      final f1 = authority.runExclusive<String>(
        operationName: 'failingExclusive',
        action: () async {
          timeline.add('failingExclusive:start');
          throw const DiagnosticLinkException(
            kind: DiagnosticFailureKind.transportFailure,
            message: 'Boom in exclusive',
          );
        },
      );

      final f2 = authority.runOneShot<String>(
        operationName: 'subsequentOneShot',
        action: () async {
          timeline.add('subsequentOneShot:start');
          return 'oneShot-ok';
        },
      );

      final f3 = authority.runExclusive<String>(
        operationName: 'subsequentExclusive',
        action: () async {
          timeline.add('subsequentExclusive:start');
          return 'exclusive-ok';
        },
      );

      await expectLater(f1, throwsA(isA<DiagnosticLinkException>()));
      expect(await f2, equals('oneShot-ok'));
      expect(await f3, equals('exclusive-ok'));

      expect(timeline, [
        'pause',
        'failingExclusive:start',
        'resume',
        'pause',
        'subsequentOneShot:start',
        'resume',
        'pause',
        'subsequentExclusive:start',
        'resume',
      ]);
      expect(authority.activeTakeovers, equals(0));
    });

    test('E4: failed oneShot action does not poison subsequent exclusive in queue', () async {
      final timeline = <String>[];
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

      final f1 = authority.runOneShot<String>(
        operationName: 'failingOneShot',
        action: () async {
          timeline.add('failingOneShot:start');
          throw StateError('raw failure in oneShot');
        },
      );

      final f2 = authority.runExclusive<String>(
        operationName: 'subsequentExclusive',
        action: () async {
          timeline.add('subsequentExclusive:start');
          return 'exclusive-ok';
        },
      );

      await expectLater(f1, throwsA(isA<StateError>()));
      expect(await f2, equals('exclusive-ok'));

      expect(timeline, [
        'pause',
        'failingOneShot:start',
        'resume',
        'pause',
        'subsequentExclusive:start',
        'resume',
      ]);
      expect(authority.activeTakeovers, equals(0));
    });
  });

  group('Exclusive Mode 08 Multi-Block Wire Invariant (E5~E7, E12, M1)', () {
    test(
      'E5, E6, E7: multi-block discovery (0800 -> 0820) pauses polling, prevents interleaving, and restores polling exactly once',
      () async {
        final container = await _createContainer({});
        addTearDown(container.dispose);

        final adapter = _createMultiBlockMode08Adapter(
          block00Delay: const Duration(milliseconds: 100),
          block20Delay: const Duration(milliseconds: 100),
        );

        final session = container.read(obdSessionProvider.notifier);
        expect(await session.connectForTest(adapter, TransportKind.demo), isTrue);
        await _waitForInitialCensus(session);

        // Sync 010D so that normal polling dispatches it onto wire
        session.syncActivePids(const [PidLibrary.vehicleSpeed]);

        // 1. Wait for at least one 010D on the wire before discovery
        await _waitForWireCommand(adapter, '010D');
        final baseline010DCount = adapter.commandLog.where((c) => c == '010D').length;
        expect(baseline010DCount, greaterThan(0), reason: 'Normal 010D polling must be active on wire before exclusive takeover');

        final initialRestorations = session.linkOwnership?.displacedRestorationCount ?? 0;

        final discoveryNotifier = container.read(mode08DiscoveryStateProvider.notifier);
        final discoveryFuture = discoveryNotifier.runDiscovery();

        // 2. Wait for 0800 on wire
        await _waitForWireCommand(adapter, '0800');
        final countDuring0800 = adapter.commandLog.where((c) => c == '010D').length;

        // Verify polling is stopped during 0800
        expect(session.engine?.isRunning, isFalse, reason: 'E5: Engine must be stopped during 0800');

        // 3. Wait for 0820 on wire
        await _waitForWireCommand(adapter, '0820');
        final countDuring0820 = adapter.commandLog.where((c) => c == '010D').length;

        // Verify 010D count did not increase while exclusive discovery is in flight
        expect(
          countDuring0820,
          equals(countDuring0800),
          reason: 'Normal 010D polling must NOT be dispatched on wire while exclusive discovery is in flight',
        );

        // Verify polling is still stopped during 0820
        expect(session.engine?.isRunning, isFalse, reason: 'E6: Engine must remain stopped during 0820');

        // Await full completion
        await discoveryFuture;

        // 4. Inspect final state
        final discoveryState = container.read(mode08DiscoveryStateProvider);
        expect(discoveryState.isCompleted, isTrue);
        expect(discoveryState.result?.isSupported, isTrue);
        expect(discoveryState.result?.supportedTids, containsAll([0x01, 0x21]));
        expect(discoveryState.result?.queriedBlocks, equals([0x00, 0x20]));

        // 5. Verify wire sequence: no normal polling (01xx) between 0800 and 0820
        final log = adapter.commandLog;
        final index0800 = log.lastIndexOf('0800');
        final index0820 = log.lastIndexOf('0820');
        expect(index0800, greaterThanOrEqualTo(0));
        expect(index0820, greaterThan(index0800));

        final commandsBetween = log.sublist(index0800 + 1, index0820);
        expect(
          commandsBetween.where((cmd) => cmd.startsWith('01')),
          isEmpty,
          reason: 'E6 / M1 Invariant: No PID polling commands may appear between 0800 and 0820',
        );

        // 6. E7: Verify polling is restored after discovery completes and dispatches on wire again
        await _waitForWireCommand(adapter, '010D', afterCount: countDuring0820);
        final postDiscovery010DCount = adapter.commandLog.where((c) => c == '010D').length;
        expect(
          postDiscovery010DCount,
          greaterThan(countDuring0820),
          reason: 'Normal 010D polling must resume and dispatch on wire after Mode 08 discovery completes',
        );
        expect(session.engine?.isRunning, isTrue, reason: 'E7: Polling must be restored after completion');
        expect(session.linkOwnership?.displacedRestorationCount, equals(initialRestorations + 1));

        await session.disconnect();
      },
    );
  });

  group('Lifecycle, Background, and Reconnect Safety (E8, E9, M2)', () {
    test(
      'E8 & M2: background transition during discovery retires wire owner and strictly prevents polling restart',
      () async {
        final container = await _createContainer({});
        addTearDown(container.dispose);

        final adapter = _createMultiBlockMode08Adapter(
          block00Delay: const Duration(milliseconds: 200),
        );

        final session = container.read(obdSessionProvider.notifier);
        expect(await session.connectForTest(adapter, TransportKind.demo), isTrue);
        await _waitForInitialCensus(session);
        final initialRestorations = session.linkOwnership?.displacedRestorationCount ?? 0;

        final discoveryNotifier = container.read(mode08DiscoveryStateProvider.notifier);
        final discoveryFuture = discoveryNotifier.runDiscovery();

        // Wait until 0800 is active on wire
        await _waitForWireCommand(adapter, '0800');
        expect(session.engine?.isRunning, isFalse);

        // Trigger background lifecycle states
        final binding = TestWidgetsFlutterBinding.ensureInitialized();
        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

        // Await discovery completion (it should retire/fail gracefully)
        await discoveryFuture;

        // E8 & M2 check: polling engine MUST NOT be restarted in background!
        expect(
          session.engine?.isRunning,
          isFalse,
          reason: 'E8 & M2: Polling MUST NOT be restarted while app is in background',
        );

        // Verify restoration was prevented (restoration count did not increment)
        expect(session.linkOwnership?.displacedRestorationCount, equals(initialRestorations));

        await session.disconnect();
      },
    );

    test(
      'E9: reconnect during in-flight discovery retires wire owner and prevents stale wire transmission',
      () async {
        final container = await _createContainer({});
        addTearDown(container.dispose);

        final adapter1 = _createMultiBlockMode08Adapter(
          block00Delay: const Duration(milliseconds: 200),
        );

        final session = container.read(obdSessionProvider.notifier);
        expect(await session.connectForTest(adapter1, TransportKind.demo), isTrue);
        await _waitForInitialCensus(session);

        final discoveryNotifier = container.read(mode08DiscoveryStateProvider.notifier);
        final discoveryFuture = discoveryNotifier.runDiscovery();

        await _waitForWireCommand(adapter1, '0800');

        // Simulate reconnect with fresh adapter (bumps generation)
        final adapter2 = _createMultiBlockMode08Adapter();
        await session.disconnect();
        expect(await session.connectForTest(adapter2, TransportKind.demo), isTrue);

        await discoveryFuture;

        // Verify adapter2 received NO stale 0820 from the old discovery run
        expect(
          adapter2.commandLog.where((cmd) => cmd == '0820'),
          isEmpty,
          reason: 'E9: Reconnection must prevent prior discovery from polluting new session',
        );

        await session.disconnect();
      },
    );
  });

  group('Provider Concurrency & Restart Contract (E10, E11)', () {
    test('E10: concurrent runDiscovery calls while discovering are no-op and do not enqueue a second exclusive action', () async {
      final container = await _createContainer({});
      addTearDown(container.dispose);

      final adapter = _createMultiBlockMode08Adapter(
        block00Delay: const Duration(milliseconds: 150),
      );

      final session = container.read(obdSessionProvider.notifier);
      expect(await session.connectForTest(adapter, TransportKind.demo), isTrue);
      await _waitForInitialCensus(session);
      final initialRestorations = session.linkOwnership?.displacedRestorationCount ?? 0;

      final discoveryNotifier = container.read(mode08DiscoveryStateProvider.notifier);
      final f1 = discoveryNotifier.runDiscovery();

      await _waitForWireCommand(adapter, '0800');

      // Second call while f1 is discovering
      final f2 = discoveryNotifier.runDiscovery();

      // Ensure no second exclusive action was queued in authority
      expect(session.linkOwnership?.queuedCount, equals(0));

      await Future.wait([f1, f2]);

      expect(session.linkOwnership?.displacedRestorationCount, equals(initialRestorations + 1));
      await session.disconnect();
    });

    test('E11: onDisplacedPollingRestored restarts incomplete support discovery after exclusive takeover', () async {
      final container = await _createContainer({});
      addTearDown(container.dispose);

      final adapter = _createMultiBlockMode08Adapter();
      adapter.slowCommands['0100'] = const Duration(milliseconds: 150);

      final session = container.read(obdSessionProvider.notifier);
      expect(await session.connectForTest(adapter, TransportKind.demo), isTrue);

      final engine = session.engine!;
      expect(engine.isRunning, isTrue);

      // Interrupt discovery to enforce that support discovery is genuinely incomplete
      engine.interruptCapabilityDiscovery();
      expect(engine.supportDiscoveryComplete, isFalse);

      final authority = session.linkOwnership;
      bool onRestoredFired = false;
      final originalOnRestored = authority?.onDisplacedPollingRestored;
      authority?.onDisplacedPollingRestored = () {
        onRestoredFired = true;
        originalOnRestored?.call();
      };

      final discoveryNotifier = container.read(mode08DiscoveryStateProvider.notifier);
      await discoveryNotifier.runDiscovery();

      expect(onRestoredFired, isTrue, reason: 'onDisplacedPollingRestored must be invoked');
      expect(engine.isRunning, isTrue, reason: 'Polling engine must be running after restoration');
      expect(
        engine.capabilitySummary.phase,
        anyOf(
          ObdCapabilityDiscoveryPhase.running,
          ObdCapabilityDiscoveryPhase.attemptFinished,
        ),
        reason: 'Restoration must restart incomplete support discovery',
      );

      await session.disconnect();
    });
  });
}
