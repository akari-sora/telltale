import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:torque_obd/car/car_projection_session_runtime.dart';
import 'package:torque_obd/car/generated/car_projection_session.g.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';

const _currentLeaseChannel =
    'dev.flutter.pigeon.torque_obd.CarProjectionSessionHostApi.currentLease';
const _armContinuityChannel =
    'dev.flutter.pigeon.torque_obd.CarProjectionSessionHostApi.armContinuity';
const _retireContinuityChannel =
    'dev.flutter.pigeon.torque_obd.CarProjectionSessionHostApi.retireContinuity';
const _acknowledgeReleaseChannel =
    'dev.flutter.pigeon.torque_obd.CarProjectionSessionHostApi.acknowledgeRelease';
const _leaseChangedChannel =
    'dev.flutter.pigeon.torque_obd.CarProjectionSessionFlutterApi.onLeaseChanged';

CarProjectionLeaseMessage _lease({
  required bool active,
  required int generation,
  required bool armed,
  int? connectionGeneration,
}) => CarProjectionLeaseMessage(
  active: active,
  generation: generation,
  armed: armed,
  connectionGeneration: connectionGeneration,
);

Future<void> _eventually(
  bool Function() condition, {
  String? reason,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail(reason ?? 'condition did not become true before $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void _background(TestWidgetsFlutterBinding binding) {
  binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
}

final class _NativeProjectionHost {
  _NativeProjectionHost(this.messenger);

  final TestDefaultBinaryMessenger messenger;
  late Future<CarProjectionLeaseMessage> Function() currentLease;
  late Future<CarProjectionLeaseMessage> Function(
    int projectionGeneration,
    int connectionGeneration,
  )
  armContinuity;
  Future<void> Function(int projectionGeneration)? onAcknowledgeRelease;
  Future<void> Function(int projectionGeneration, int connectionGeneration)?
  onRetireContinuity;

  int currentLeaseCalls = 0;
  int armContinuityCalls = 0;
  final acknowledgedGenerations = <int>[];
  final retiredGenerations = <int>[];

  static const codec = CarProjectionSessionHostApi.pigeonChannelCodec;

  void install() {
    messenger.setMockMessageHandler(_currentLeaseChannel, (data) async {
      currentLeaseCalls++;
      try {
        return codec.encodeMessage(<Object?>[await currentLease()]);
      } on PlatformException catch (error) {
        return codec.encodeMessage(<Object?>[
          error.code,
          error.message,
          error.details,
        ]);
      }
    });
    messenger.setMockMessageHandler(_armContinuityChannel, (data) async {
      final arguments = codec.decodeMessage(data)! as List<Object?>;
      armContinuityCalls++;
      try {
        final response = await armContinuity(
          arguments[0]! as int,
          arguments[1]! as int,
        );
        return codec.encodeMessage(<Object?>[response]);
      } on PlatformException catch (error) {
        return codec.encodeMessage(<Object?>[
          error.code,
          error.message,
          error.details,
        ]);
      }
    });
    messenger.setMockMessageHandler(_retireContinuityChannel, (data) async {
      final arguments = codec.decodeMessage(data)! as List<Object?>;
      final projectionGeneration = arguments[0]! as int;
      final connectionGeneration = arguments[1]! as int;
      retiredGenerations.add(projectionGeneration);
      try {
        await onRetireContinuity?.call(
          projectionGeneration,
          connectionGeneration,
        );
        return codec.encodeMessage(<Object?>[]);
      } on PlatformException catch (error) {
        return codec.encodeMessage(<Object?>[
          error.code,
          error.message,
          error.details,
        ]);
      }
    });
    messenger.setMockMessageHandler(_acknowledgeReleaseChannel, (data) async {
      final arguments = codec.decodeMessage(data)! as List<Object?>;
      final generation = arguments.single! as int;
      acknowledgedGenerations.add(generation);
      try {
        await onAcknowledgeRelease?.call(generation);
        return codec.encodeMessage(<Object?>[]);
      } on PlatformException catch (error) {
        return codec.encodeMessage(<Object?>[
          error.code,
          error.message,
          error.details,
        ]);
      }
    });
  }

  Future<void> sendLease(CarProjectionLeaseMessage lease) async {
    final ByteData? reply = await messenger.handlePlatformMessage(
      _leaseChangedChannel,
      CarProjectionSessionFlutterApi.pigeonChannelCodec.encodeMessage(<Object?>[
        lease,
      ]),
      null,
    );
    expect(
      CarProjectionSessionFlutterApi.pigeonChannelCodec.decodeMessage(reply),
      isEmpty,
    );
  }

  void uninstall() {
    messenger.setMockMessageHandler(_currentLeaseChannel, null);
    messenger.setMockMessageHandler(_armContinuityChannel, null);
    messenger.setMockMessageHandler(_retireContinuityChannel, null);
    messenger.setMockMessageHandler(_acknowledgeReleaseChannel, null);
  }
}

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  tearDown(() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  test(
    'accepts a confirmed armed lease when HOME reconciles during confirmation',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(await session.connectDemo(), isTrue);
      final connectionGeneration = session.connectionGeneration;
      final armed = _lease(
        active: true,
        generation: 10,
        armed: true,
        connectionGeneration: connectionGeneration,
      );
      final confirmation = Completer<CarProjectionLeaseMessage>();
      final host = _NativeProjectionHost(messenger);
      host.currentLease = () {
        if (host.currentLeaseCalls == 1) return Future.value(armed);
        return confirmation.future;
      };
      host.armContinuity = (_, _) async => armed;
      host.install();
      addTearDown(host.uninstall);

      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      await _eventually(() => host.currentLeaseCalls == 2);

      _background(binding);
      confirmation.complete(armed);

      await _eventually(
        () => session.hasArmedProjectionContinuity && session.engine!.isRunning,
        reason: 'HOME reconciliation must not discard native confirmation',
      );
      expect(session.isForeground, isFalse);
    },
  );

  test(
    'a stale release cannot cancel a newer lease awaiting confirmation',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(await session.connectDemo(), isTrue);
      _background(binding);
      await _eventually(() => !session.engine!.isRunning);

      final generation2 = _lease(
        active: true,
        generation: 2,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      final confirmation = Completer<CarProjectionLeaseMessage>();
      final host = _NativeProjectionHost(messenger);
      host.currentLease = () {
        if (host.currentLeaseCalls == 1) {
          throw PlatformException(code: 'not-ready');
        }
        return confirmation.future;
      };
      host.armContinuity = (_, _) async => generation2;
      host.install();
      addTearDown(host.uninstall);
      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      await _eventually(() => host.currentLeaseCalls == 1);

      await host.sendLease(generation2);
      await _eventually(() => host.currentLeaseCalls == 2);
      await host.sendLease(_lease(active: false, generation: 1, armed: false));
      confirmation.complete(generation2);

      await _eventually(
        () => session.hasArmedProjectionContinuity && session.engine!.isRunning,
        reason:
            'a rejected stale callback must not invalidate the in-flight '
            'confirmation for the current generation',
      );
      expect(host.acknowledgedGenerations, isNot(contains(1)));
    },
  );

  test('an active unarmed lease stops hidden Dart polling', () async {
    final container = await _container();
    addTearDown(container.dispose);
    final session = container.read(obdSessionProvider.notifier);
    expect(await session.connectDemo(), isTrue);
    final armed = _lease(
      active: true,
      generation: 20,
      armed: true,
      connectionGeneration: session.connectionGeneration,
    );
    final host = _NativeProjectionHost(messenger)
      ..currentLease = (() async => armed)
      ..armContinuity = ((_, _) async => armed);
    host.install();
    addTearDown(host.uninstall);
    expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
    await _eventually(
      () => session.hasArmedProjectionContinuity && session.engine!.isRunning,
    );
    _background(binding);
    expect(session.engine!.isRunning, isTrue);

    var drainedAtAcknowledgement = false;
    host.onAcknowledgeRelease = (_) async {
      drainedAtAcknowledgement =
          !session.hasArmedProjectionContinuity && !session.engine!.isRunning;
    };

    await host.sendLease(_lease(active: true, generation: 20, armed: false));

    await _eventually(() => host.acknowledgedGenerations.contains(20));
    expect(drainedAtAcknowledgement, isTrue);
    expect(session.hasArmedProjectionContinuity, isFalse);
  });

  test(
    'a released generation cannot be revived by its late armed callback',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(await session.connectDemo(), isTrue);
      final armed = _lease(
        active: true,
        generation: 30,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      final host = _NativeProjectionHost(messenger)
        ..currentLease = (() async => armed)
        ..armContinuity = ((_, _) async => armed);
      host.install();
      addTearDown(host.uninstall);
      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      await _eventually(() => session.hasArmedProjectionContinuity);

      await host.sendLease(_lease(active: false, generation: 30, armed: false));
      await _eventually(() => host.acknowledgedGenerations.contains(30));
      await host.sendLease(armed);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(session.hasArmedProjectionContinuity, isFalse);
      expect(host.currentLeaseCalls, 2);
    },
  );

  test(
    'a host exception does not poison a later legitimate lease event',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(await session.connectDemo(), isTrue);
      final first = _lease(
        active: true,
        generation: 40,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      final second = _lease(
        active: true,
        generation: 41,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      final host = _NativeProjectionHost(messenger);
      host.currentLease = () async {
        return switch (host.currentLeaseCalls) {
          1 => first,
          2 => throw PlatformException(
            code: 'transient-host-failure',
            message: 'confirmation failed',
          ),
          _ => second,
        };
      };
      host.armContinuity = (_, _) async => second;
      host.install();
      addTearDown(host.uninstall);
      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      await _eventually(() => host.currentLeaseCalls == 2);

      await host.sendLease(second);

      await _eventually(
        () => session.hasArmedProjectionContinuity,
        reason: 'one failed HostApi call must not reject all later events',
      );
      expect(host.currentLeaseCalls, 3);
    },
  );

  test(
    'a retire HostApi exception does not poison the next lease event',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(await session.connectDemo(), isTrue);
      final rejected = _lease(
        active: true,
        generation: 45,
        armed: true,
        connectionGeneration: session.connectionGeneration + 1,
      );
      final accepted = _lease(
        active: true,
        generation: 46,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      var current = rejected;
      final host = _NativeProjectionHost(messenger)
        ..currentLease = (() async => current)
        ..armContinuity = ((_, _) async => current)
        ..onRetireContinuity = ((_, _) async {
          throw PlatformException(code: 'retire-failed');
        });
      host.install();
      addTearDown(host.uninstall);
      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      await _eventually(() => host.retiredGenerations.contains(45));

      current = accepted;
      await host.sendLease(accepted);

      await _eventually(() => session.hasArmedProjectionContinuity);
      expect(host.currentLeaseCalls, 3);
    },
  );

  test(
    'an acknowledge exception leaves authority closed and reducer usable',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(await session.connectDemo(), isTrue);
      final first = _lease(
        active: true,
        generation: 47,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      final second = _lease(
        active: true,
        generation: 48,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      var current = first;
      var authorityClosedAtAcknowledgement = false;
      final host = _NativeProjectionHost(messenger)
        ..currentLease = (() async => current)
        ..armContinuity = ((_, _) async => current)
        ..onAcknowledgeRelease = ((_) async {
          authorityClosedAtAcknowledgement =
              !session.hasArmedProjectionContinuity;
          throw PlatformException(code: 'ack-failed');
        });
      host.install();
      addTearDown(host.uninstall);
      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      await _eventually(() => session.hasArmedProjectionContinuity);

      await host.sendLease(_lease(active: false, generation: 47, armed: false));
      await _eventually(() => host.acknowledgedGenerations.contains(47));
      expect(authorityClosedAtAcknowledgement, isTrue);

      current = second;
      await host.sendLease(second);
      await _eventually(() => session.hasArmedProjectionContinuity);
      expect(host.currentLeaseCalls, 3);
    },
  );

  test(
    'release acknowledgement follows the in-flight hidden ATRV drain',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(
        await session.connectDemo(
          responseLatency: const Duration(milliseconds: 250),
        ),
        isTrue,
      );
      _background(binding);
      await _eventually(() => !session.engine!.isRunning);
      final armed = _lease(
        active: true,
        generation: 50,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      final host = _NativeProjectionHost(messenger);
      host.currentLease = () async {
        if (host.currentLeaseCalls == 1) {
          throw PlatformException(code: 'not-ready');
        }
        return armed;
      };
      host.armContinuity = (_, _) async => armed;
      var drainedAtAcknowledgement = false;
      host.onAcknowledgeRelease = (_) async {
        drainedAtAcknowledgement =
            !session.hasArmedProjectionContinuity && !session.engine!.isRunning;
      };
      host.install();
      addTearDown(host.uninstall);
      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      await _eventually(() => host.currentLeaseCalls == 1);

      await host.sendLease(armed);
      await _eventually(() => host.currentLeaseCalls == 2);
      await host.sendLease(_lease(active: false, generation: 50, armed: false));

      await _eventually(() => host.acknowledgedGenerations.contains(50));
      expect(drainedAtAcknowledgement, isTrue);
    },
  );

  test('a stale release cannot tear down a newer armed lease', () async {
    final container = await _container();
    addTearDown(container.dispose);
    final session = container.read(obdSessionProvider.notifier);
    expect(await session.connectDemo(), isTrue);
    final lease60 = _lease(
      active: true,
      generation: 60,
      armed: true,
      connectionGeneration: session.connectionGeneration,
    );
    final lease61 = _lease(
      active: true,
      generation: 61,
      armed: true,
      connectionGeneration: session.connectionGeneration,
    );
    var current = lease60;
    final host = _NativeProjectionHost(messenger)
      ..currentLease = (() async => current)
      ..armContinuity = ((_, _) async => current);
    host.install();
    addTearDown(host.uninstall);
    expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
    await _eventually(() => session.hasArmedProjectionContinuity);

    current = lease61;
    await host.sendLease(lease61);
    await _eventually(() => host.currentLeaseCalls == 3);
    _background(binding);
    await _eventually(() => session.engine!.isRunning);
    await host.sendLease(_lease(active: false, generation: 60, armed: false));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(session.hasArmedProjectionContinuity, isTrue);
    expect(session.engine!.isRunning, isTrue);
    expect(host.acknowledgedGenerations, isNot(contains(60)));
  });
}
