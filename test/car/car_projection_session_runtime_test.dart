import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:torque_obd/car/car_projection_runtime.dart';
import 'package:torque_obd/car/car_projection_session_runtime.dart';
import 'package:torque_obd/car/generated/car_projection_session.g.dart';
import 'package:torque_obd/car/generated/car_telemetry.g.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/telemetry_demand.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/obd/transport/demo_transport.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/settings.dart';

const _currentLeaseChannel =
    'dev.flutter.pigeon.torque_obd.CarProjectionSessionHostApi.currentLease';
const _claimProducerChannel =
    'dev.flutter.pigeon.torque_obd.CarProjectionSessionHostApi.claimProducerConnection';
const _retireProducerChannel =
    'dev.flutter.pigeon.torque_obd.CarProjectionSessionHostApi.retireProducerConnection';
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
  int? producerConnectionGeneration,
}) => CarProjectionLeaseMessage(
  active: active,
  generation: generation,
  armed: armed,
  connectionGeneration: connectionGeneration,
  producerConnectionGeneration:
      producerConnectionGeneration ?? connectionGeneration,
);

bool _hasLiveCoreValues(CarTelemetryMessage frame) =>
    frame.speedKmh.status == CarSignalStatusMessage.live &&
    frame.speedKmh.value != null &&
    frame.rpm.status == CarSignalStatusMessage.live &&
    frame.rpm.value != null &&
    frame.coolantC.status == CarSignalStatusMessage.live &&
    frame.coolantC.value != null;

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

void _foreground(TestWidgetsFlutterBinding binding) {
  binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
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
  Future<CarProjectionLeaseMessage> Function(int connectionGeneration)?
  onClaimProducer;
  Future<void> Function(int connectionGeneration)? onRetireProducer;
  CarProjectionLeaseMessage? lastLease;
  int? producerOwner;

  int currentLeaseCalls = 0;
  int armContinuityCalls = 0;
  final acknowledgedGenerations = <int>[];
  final retiredGenerations = <int>[];
  final claimedProducers = <int>[];
  final retiredProducers = <int>[];

  static const codec = CarProjectionSessionHostApi.pigeonChannelCodec;

  void install() {
    messenger.setMockMessageHandler(_currentLeaseChannel, (data) async {
      currentLeaseCalls++;
      try {
        final response = await currentLease();
        lastLease = response;
        producerOwner = response.producerConnectionGeneration;
        return codec.encodeMessage(<Object?>[response]);
      } on PlatformException catch (error) {
        return codec.encodeMessage(<Object?>[
          error.code,
          error.message,
          error.details,
        ]);
      }
    });
    messenger.setMockMessageHandler(_claimProducerChannel, (data) async {
      final arguments = codec.decodeMessage(data)! as List<Object?>;
      final generation = arguments.single! as int;
      claimedProducers.add(generation);
      try {
        final response =
            await onClaimProducer?.call(generation) ??
            _lease(
              active: lastLease?.active ?? false,
              generation: lastLease?.generation ?? 0,
              armed: lastLease?.armed ?? false,
              connectionGeneration: lastLease?.connectionGeneration,
              producerConnectionGeneration: generation,
            );
        producerOwner = response.producerConnectionGeneration;
        lastLease = response;
        return codec.encodeMessage(<Object?>[response]);
      } on PlatformException catch (error) {
        return codec.encodeMessage(<Object?>[
          error.code,
          error.message,
          error.details,
        ]);
      }
    });
    messenger.setMockMessageHandler(_retireProducerChannel, (data) async {
      final arguments = codec.decodeMessage(data)! as List<Object?>;
      final generation = arguments.single! as int;
      retiredProducers.add(generation);
      if (producerOwner == generation) producerOwner = null;
      await onRetireProducer?.call(generation);
      return codec.encodeMessage(<Object?>[]);
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
    lease.producerConnectionGeneration ??= producerOwner;
    lastLease = lease;
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
    messenger.setMockMessageHandler(_claimProducerChannel, null);
    messenger.setMockMessageHandler(_retireProducerChannel, null);
    messenger.setMockMessageHandler(_armContinuityChannel, null);
    messenger.setMockMessageHandler(_retireContinuityChannel, null);
    messenger.setMockMessageHandler(_acknowledgeReleaseChannel, null);
  }
}

Future<ProviderContainer> _container({
  Map<String, Object> preferences = const {},
  CarProjectionReconnect? reconnect,
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (reconnect != null)
        carProjectionReconnectProvider.overrideWithValue(reconnect),
    ],
  );
}

Future<bool> _connectFixture(ObdSession session, {Duration? responseLatency}) =>
    session.connectForTest(
      DemoTransport(
        responseLatency: responseLatency ?? const Duration(milliseconds: 18),
      ),
      TransportKind.wifi,
    );

const _projectedModeAndPids = <String>{
  '010D',
  '010C',
  '0105',
  '010F',
  '0142',
  '010B',
  '0104',
};

Iterable<TelemetryDemand> _projectionDemands(ObdSession session) => session
    .engine!
    .demands
    .leases
    .where((demand) => demand.owner == DemandOwner.projection);

/// Counts the session's own automatic reconnects (#112). Projection reconnects
/// go through `carProjectionReconnectProvider`, which each test overrides, so
/// every call that arrives here is the automatic one.
class _AutoReconnectSession extends ObdSession {
  _AutoReconnectSession(this._transport);

  final ObdTransport Function() _transport;
  int automaticReconnects = 0;

  @override
  Future<bool> reconnectRememberedAdapter(LastAdapter adapter) {
    automaticReconnects++;
    return connectForTest(_transport(), adapter.kind, adapter: adapter);
  }
}

class _HeldDemoTransport extends DemoTransport {
  final gate = Completer<void>();

  @override
  Future<void> connect() async {
    await gate.future;
    await super.connect();
  }
}

class _SlowToCloseDemoTransport extends DemoTransport {
  final release = Completer<void>();

  @override
  Future<void> disconnect() async {
    await release.future;
    await super.disconnect();
  }
}

const _rememberedClassic = LastAdapter(
  id: '00:1D:A5:68:98:8B',
  name: 'OBDII',
  kind: TransportKind.bluetoothClassic,
);

Future<(ProviderContainer, _AutoReconnectSession)> _autoReconnectContainer({
  required ObdTransport Function() automaticTransport,
  required CarProjectionReconnect projectionReconnect,
}) async {
  SharedPreferences.setMockInitialValues({
    'last_adapter_v1': _rememberedClassic.encode(),
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      obdSessionProvider.overrideWith(
        () => _AutoReconnectSession(automaticTransport),
      ),
      carProjectionReconnectProvider.overrideWithValue(projectionReconnect),
    ],
  );
  return (
    container,
    container.read(obdSessionProvider.notifier) as _AutoReconnectSession,
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

  test('foreground user connection owns transport before projection', () async {
    final container = await _container();
    final session = container.read(obdSessionProvider.notifier);
    final inactive = _lease(active: false, generation: 0, armed: false);
    final host = _NativeProjectionHost(messenger)
      ..currentLease = (() async => inactive)
      ..armContinuity = ((_, _) async => inactive);
    host.install();
    addTearDown(host.uninstall);
    addTearDown(container.dispose);
    expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
    await _eventually(() => host.currentLeaseCalls == 1);
    expect(host.claimedProducers, isEmpty);

    expect(await _connectFixture(session), isTrue);
    final generation = session.connectionGeneration;
    await _eventually(() => host.claimedProducers.isNotEmpty);
    expect(host.claimedProducers, [generation]);
    expect(host.armContinuityCalls, 0);

    _background(binding);
    await _eventually(() => !session.engine!.isRunning);
    expect(container.read(obdSessionProvider).isConnected, isTrue);
    expect(host.retiredProducers, isEmpty);
    expect(session.hasArmedProjectionContinuity, isFalse);

    await session.disconnect();
    await _eventually(() => host.retiredProducers.contains(generation));
    expect(host.retiredProducers, [generation]);
  });

  test(
    'active projection acquires its complete telemetry set with an empty dashboard',
    () async {
      final container = await _container(
        preferences: {'active_pid_ids_v1': <String>[]},
      );
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(container.read(activePidsProvider), isEmpty);
      expect(await _connectFixture(session), isTrue);
      final armed = _lease(
        active: true,
        generation: 60,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      final host = _NativeProjectionHost(messenger)
        ..currentLease = (() async => armed)
        ..armContinuity = ((_, _) async => armed);
      host.install();
      addTearDown(host.uninstall);

      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      await _eventually(() => _projectionDemands(session).length == 7);

      expect(
        _projectionDemands(session).map((demand) => demand.modeAndPid).toSet(),
        _projectedModeAndPids,
      );
    },
  );

  test(
    'projection demand unions with a custom phone dashboard without duplicate wire requests',
    () async {
      final container = await _container(
        preferences: {
          'active_pid_ids_v1': <String>[
            PidLibrary.throttlePosition.id,
            PidLibrary.vehicleSpeed.id,
          ],
        },
      );
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(container.read(activePidsProvider), [
        PidLibrary.throttlePosition,
        PidLibrary.vehicleSpeed,
      ]);
      expect(await _connectFixture(session), isTrue);
      final armed = _lease(
        active: true,
        generation: 61,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      final host = _NativeProjectionHost(messenger)
        ..currentLease = (() async => armed)
        ..armContinuity = ((_, _) async => armed);
      host.install();
      addTearDown(host.uninstall);

      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      await _eventually(() => _projectionDemands(session).length == 7);

      expect(
        _projectionDemands(session).map((demand) => demand.modeAndPid).toSet(),
        _projectedModeAndPids,
      );
      expect(
        session.engine!.demands.uniqueWireRequests().where(
          (demand) => demand.modeAndPid == PidLibrary.vehicleSpeed.modeAndPid,
        ),
        hasLength(1),
      );
      expect(
        session.engine!.demands.leases.where(
          (demand) =>
              demand.modeAndPid == PidLibrary.vehicleSpeed.modeAndPid &&
              demand.owner == DemandOwner.dashboard,
        ),
        hasLength(1),
      );
      expect(
        session.engine!.demands.leases.where(
          (demand) =>
              demand.modeAndPid == PidLibrary.vehicleSpeed.modeAndPid &&
              demand.owner == DemandOwner.projection,
        ),
        hasLength(1),
      );
    },
  );

  test(
    'projection release and runtime disposal drop every projection hold',
    () async {
      final container = await _container(
        preferences: {'active_pid_ids_v1': <String>[]},
      );
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(await _connectFixture(session), isTrue);
      var current = _lease(
        active: true,
        generation: 62,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      final host = _NativeProjectionHost(messenger)
        ..currentLease = (() async => current)
        ..armContinuity = ((_, _) async => current);
      host.install();
      addTearDown(host.uninstall);
      final runtime = container.read(carProjectionSessionRuntimeProvider)!;
      await _eventually(() => _projectionDemands(session).length == 7);

      current = _lease(active: false, generation: 62, armed: false);
      await host.sendLease(current);
      await _eventually(() => _projectionDemands(session).isEmpty);

      current = _lease(
        active: true,
        generation: 63,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      await host.sendLease(current);
      await _eventually(() => _projectionDemands(session).length == 7);
      runtime.dispose();
      await _eventually(() => _projectionDemands(session).isEmpty);
    },
  );

  test(
    'session disposal drops projection holds from its detached engine',
    () async {
      final container = await _container(
        preferences: {'active_pid_ids_v1': <String>[]},
      );
      final session = container.read(obdSessionProvider.notifier);
      expect(await _connectFixture(session), isTrue);
      final engine = session.engine!;
      expect(session.acquireProjectionTelemetryDemand(65), isTrue);
      expect(
        engine.demands.leases.where(
          (demand) => demand.owner == DemandOwner.projection,
        ),
        hasLength(7),
      );

      container.dispose();

      expect(
        engine.demands.leases.where(
          (demand) => demand.owner == DemandOwner.projection,
        ),
        isEmpty,
      );
    },
  );

  test(
    'runtime invalidation releases projection holds while the session stays alive',
    () async {
      final container = await _container(
        preferences: {'active_pid_ids_v1': <String>[]},
      );
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(await _connectFixture(session), isTrue);
      final current = _lease(
        active: true,
        generation: 66,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      final host = _NativeProjectionHost(messenger)
        ..currentLease = (() async => current)
        ..armContinuity = ((_, _) async => current);
      host.install();
      addTearDown(host.uninstall);
      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      await _eventually(() => _projectionDemands(session).length == 7);

      expect(
        () => container.invalidate(carProjectionSessionRuntimeProvider),
        returnsNormally,
      );

      await _eventually(() => _projectionDemands(session).isEmpty);
      expect(container.read(obdSessionProvider.notifier), same(session));
      expect(container.read(obdSessionProvider).isConnected, isTrue);
    },
  );

  test(
    'explicit disconnect releases projection and suppresses same-lease auto reconnect',
    () async {
      const remembered = LastAdapter(
        id: '192.168.0.10',
        name: 'Wi-Fi 192.168.0.10',
        kind: TransportKind.wifi,
        port: 35000,
      );
      var reconnects = 0;
      final container = await _container(
        preferences: {
          'active_pid_ids_v1': <String>[],
          'last_adapter_v1': remembered.encode(),
        },
        reconnect: (_) async {
          reconnects++;
          return false;
        },
      );
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(await _connectFixture(session), isTrue);
      var current = _lease(
        active: true,
        generation: 64,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      final host = _NativeProjectionHost(messenger)
        ..currentLease = (() async => current)
        ..armContinuity = ((_, _) async => current);
      host.install();
      addTearDown(host.uninstall);
      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      await _eventually(() => _projectionDemands(session).length == 7);
      final disconnectedEngine = session.engine!;
      final connectionGeneration = session.connectionGeneration;

      await session.disconnect();
      await _eventually(
        () => disconnectedEngine.demands.leases.every(
          (demand) => demand.owner != DemandOwner.projection,
        ),
      );
      await _eventually(
        () => host.retiredProducers.contains(connectionGeneration),
      );
      current = _lease(active: true, generation: 64, armed: false);
      await host.sendLease(current);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(reconnects, 0);
    },
  );

  // #112: the session reconnects a silent adapter once by itself, and an
  // active lease reconnects the remembered adapter too. Both reach the same
  // physical adapter, which accepts exactly one link.
  test(
    'an automatic reconnect in flight keeps a lease from starting another',
    () async {
      final held = _HeldDemoTransport();
      var projectionReconnects = 0;
      final (container, session) = await _autoReconnectContainer(
        automaticTransport: () => held,
        projectionReconnect: (_) async {
          projectionReconnects++;
          return false;
        },
      );
      addTearDown(container.dispose);
      var now = Duration.zero;
      session.automaticReconnectClock = () => now;
      final inactive = _lease(active: false, generation: 0, armed: false);
      final host = _NativeProjectionHost(messenger)
        ..currentLease = (() async => inactive)
        ..armContinuity = ((_, _) async => inactive);
      host.install();
      addTearDown(host.uninstall);
      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);

      expect(
        await session.connectForTest(
          DemoTransport(),
          TransportKind.bluetoothClassic,
          adapter: _rememberedClassic,
        ),
        isTrue,
      );
      now += const Duration(seconds: 11);
      session.client!.reportConnectionLostForTest(
        ConnectionLossCause.adapterSilent,
      );
      await _eventually(
        () =>
            session.automaticReconnects == 1 &&
            container.read(obdSessionProvider).isBusy,
      );

      await host.sendLease(_lease(active: true, generation: 80, armed: false));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(projectionReconnects, 0);

      held.gate.complete();
      await _eventually(() => container.read(obdSessionProvider).isConnected);
      expect(session.client!.transport, same(held));
      expect(projectionReconnects, 0);
      expect(session.automaticReconnects, 1);
    },
  );

  test(
    "a lease that reconnects during the drop's teardown is the only reconnect",
    () async {
      final slow = _SlowToCloseDemoTransport();
      late _AutoReconnectSession session;
      final projected = DemoTransport();
      var projectionReconnects = 0;
      final (container, built) = await _autoReconnectContainer(
        automaticTransport: DemoTransport.new,
        projectionReconnect: (adapter) {
          projectionReconnects++;
          return session.connectForTest(
            projected,
            adapter.kind,
            adapter: adapter,
          );
        },
      );
      session = built;
      addTearDown(container.dispose);
      var now = Duration.zero;
      session.automaticReconnectClock = () => now;
      final inactive = _lease(active: false, generation: 0, armed: false);
      final host = _NativeProjectionHost(messenger)
        ..currentLease = (() async => inactive)
        ..armContinuity = ((_, _) async => inactive);
      host.install();
      addTearDown(host.uninstall);
      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);

      expect(
        await session.connectForTest(
          slow,
          TransportKind.bluetoothClassic,
          adapter: _rememberedClassic,
        ),
        isTrue,
      );
      now += const Duration(seconds: 11);
      session.client!.reportConnectionLostForTest(
        ConnectionLossCause.adapterSilent,
      );
      expect(container.read(obdSessionProvider).phase, ConnectionPhase.failed);

      await host.sendLease(_lease(active: true, generation: 81, armed: false));
      await _eventually(() => projectionReconnects == 1);
      slow.release.complete();

      await _eventually(() => container.read(obdSessionProvider).isConnected);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(session.client!.transport, same(projected));
      expect(session.automaticReconnects, 0);
      expect(projectionReconnects, 1);
    },
  );

  test(
    'cold active projection reconnects remembered adapter once per generation',
    () async {
      _background(binding);
      final reconnects = <LastAdapter>[];
      const remembered = LastAdapter(
        id: '192.168.0.10',
        name: 'Wi-Fi 192.168.0.10',
        kind: TransportKind.wifi,
        port: 35000,
      );
      late ProviderContainer container;
      container = await _container(
        preferences: {'last_adapter_v1': remembered.encode()},
        reconnect: (adapter) async {
          reconnects.add(adapter);
          return _connectFixture(container.read(obdSessionProvider.notifier));
        },
      );
      var active = _lease(active: true, generation: 70, armed: false);
      final host = _NativeProjectionHost(messenger)
        ..currentLease = (() async => active)
        ..armContinuity = ((projection, connection) async {
          active = _lease(
            active: true,
            generation: projection,
            armed: true,
            connectionGeneration: connection,
          );
          return active;
        });
      host.install();
      addTearDown(host.uninstall);
      addTearDown(container.dispose);

      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      await _eventually(() => reconnects.length == 1);
      expect(reconnects.single.encode(), remembered.encode());
      await _eventually(() => host.claimedProducers.length == 1);
      await _eventually(() => host.armContinuityCalls == 1);
      await _eventually(
        () => container
            .read(obdSessionProvider.notifier)
            .hasArmedProjectionContinuity,
      );

      await host.sendLease(active);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(reconnects, hasLength(1));
    },
  );

  test('lease loss during cold reconnect cannot claim a producer', () async {
    _background(binding);
    const remembered = LastAdapter(
      id: '192.168.0.10',
      name: 'Wi-Fi 192.168.0.10',
      kind: TransportKind.wifi,
      port: 35000,
    );
    final reconnectStarted = Completer<void>();
    final finishReconnect = Completer<void>();
    late ProviderContainer container;
    container = await _container(
      preferences: {'last_adapter_v1': remembered.encode()},
      reconnect: (_) async {
        reconnectStarted.complete();
        await finishReconnect.future;
        return _connectFixture(container.read(obdSessionProvider.notifier));
      },
    );
    final active = _lease(active: true, generation: 71, armed: false);
    final inactive = _lease(active: false, generation: 71, armed: false);
    final host = _NativeProjectionHost(messenger)
      ..currentLease = (() async => active)
      ..armContinuity = ((_, _) async => active);
    host.install();
    addTearDown(host.uninstall);
    addTearDown(container.dispose);

    expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
    await reconnectStarted.future;
    await host.sendLease(inactive);
    finishReconnect.complete();
    await _eventually(() => host.acknowledgedGenerations.contains(71));

    final session = container.read(obdSessionProvider.notifier);
    expect(container.read(obdSessionProvider).isConnected, isTrue);
    expect(session.isForeground, isFalse);
    expect(session.engine!.isRunning, isFalse);
    expect(host.claimedProducers, isEmpty);
    expect(host.armContinuityCalls, 0);
  });

  test(
    'a reconnect provider exception fails closed without poisoning the reducer',
    () async {
      _background(binding);
      const remembered = LastAdapter(
        id: '192.168.0.10',
        name: 'Wi-Fi 192.168.0.10',
        kind: TransportKind.wifi,
        port: 35000,
      );
      late ProviderContainer container;
      var reconnectCalls = 0;
      container = await _container(
        preferences: {'last_adapter_v1': remembered.encode()},
        reconnect: (_) async {
          reconnectCalls++;
          await _connectFixture(container.read(obdSessionProvider.notifier));
          throw StateError('unexpected reconnect provider failure');
        },
      );
      var active = _lease(active: true, generation: 72, armed: false);
      final host = _NativeProjectionHost(messenger)
        ..currentLease = (() async => active)
        ..armContinuity = ((projection, connection) async {
          active = _lease(
            active: true,
            generation: projection,
            armed: true,
            connectionGeneration: connection,
          );
          return active;
        });
      host.install();
      addTearDown(host.uninstall);
      addTearDown(container.dispose);

      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      await _eventually(() => reconnectCalls == 1);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(host.claimedProducers, isEmpty);
      expect(host.armContinuityCalls, 0);

      active = _lease(active: true, generation: 73, armed: false);
      await host.sendLease(active);
      await _eventually(() => host.claimedProducers.length == 1);
      await _eventually(() => host.armContinuityCalls == 1);
      await _eventually(
        () => container
            .read(obdSessionProvider.notifier)
            .hasArmedProjectionContinuity,
      );
      expect(reconnectCalls, 1);
    },
  );

  test('a connection completing hidden never claims a producer', () async {
    final container = await _container();
    final session = container.read(obdSessionProvider.notifier);
    final inactive = _lease(active: false, generation: 0, armed: false);
    final host = _NativeProjectionHost(messenger)
      ..currentLease = (() async => inactive)
      ..armContinuity = ((_, _) async => inactive);
    host.install();
    addTearDown(host.uninstall);
    addTearDown(container.dispose);
    expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
    await _eventually(() => host.currentLeaseCalls == 1);
    final connecting = _connectFixture(
      session,
      responseLatency: const Duration(milliseconds: 30),
    );
    _background(binding);
    expect(await connecting, isTrue);
    await _eventually(() => !session.engine!.isRunning);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(session.isForeground, isFalse);
    expect(host.claimedProducers, isEmpty);
    expect(host.armContinuityCalls, 0);
  });

  test('projection waits for a confirmed producer across HOME', () async {
    final container = await _container();
    final session = container.read(obdSessionProvider.notifier);
    var current = _lease(active: true, generation: 70, armed: false);
    final host = _NativeProjectionHost(messenger)
      ..currentLease = (() async => current)
      ..onClaimProducer = ((_) async => current)
      ..armContinuity = ((projection, connection) async {
        current = _lease(
          active: true,
          generation: projection,
          armed: true,
          connectionGeneration: connection,
        );
        return current;
      });
    host.install();
    addTearDown(host.uninstall);
    addTearDown(container.dispose);
    expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
    await _eventually(() => host.currentLeaseCalls == 1);
    expect(await _connectFixture(session), isTrue);
    final generation = session.connectionGeneration;
    await _eventually(() => host.claimedProducers.contains(generation));
    expect(host.armContinuityCalls, 0);
    _background(binding);
    await _eventually(() => !session.engine!.isRunning);

    current = _lease(
      active: true,
      generation: 70,
      armed: false,
      producerConnectionGeneration: generation,
    );
    await host.sendLease(current);
    await _eventually(() => session.hasArmedProjectionContinuity);
    expect(session.isForeground, isFalse);
    expect(host.claimedProducers, [generation]);
    expect(host.armContinuityCalls, 1);
  });

  test('link loss retires the exact producer once', () async {
    final container = await _container();
    final session = container.read(obdSessionProvider.notifier);
    final inactive = _lease(active: false, generation: 0, armed: false);
    final host = _NativeProjectionHost(messenger)
      ..currentLease = (() async => inactive)
      ..armContinuity = ((_, _) async => inactive);
    host.install();
    addTearDown(host.uninstall);
    addTearDown(container.dispose);
    expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
    expect(await _connectFixture(session), isTrue);
    final generation = session.connectionGeneration;
    await _eventually(() => host.claimedProducers.contains(generation));
    session.client!.onConnectionLost!();
    await _eventually(() => host.retiredProducers.contains(generation));
    expect(container.read(obdSessionProvider).isConnected, isFalse);
    expect(host.retiredProducers, [generation]);
  });

  test('replacement and disposal retire only their producer owners', () async {
    final container = await _container();
    final session = container.read(obdSessionProvider.notifier);
    final inactive = _lease(active: false, generation: 0, armed: false);
    final host = _NativeProjectionHost(messenger)
      ..currentLease = (() async => inactive)
      ..armContinuity = ((_, _) async => inactive);
    host.install();
    addTearDown(host.uninstall);
    addTearDown(container.dispose);
    final runtime = container.read(carProjectionSessionRuntimeProvider)!;
    expect(await _connectFixture(session), isTrue);
    final first = session.connectionGeneration;
    await _eventually(() => host.claimedProducers.contains(first));
    expect(await _connectFixture(session), isTrue);
    final replacement = session.connectionGeneration;
    expect(replacement, greaterThan(first));
    await _eventually(() => host.claimedProducers.contains(replacement));
    expect(host.retiredProducers, [first]);
    expect(host.producerOwner, replacement);
    runtime.dispose();
    await _eventually(() => host.retiredProducers.contains(replacement));
    expect(host.retiredProducers, [first, replacement]);
  });

  test(
    'active projection may reclaim producer but cannot poll before native arms',
    () async {
      final container = await _container();
      final session = container.read(obdSessionProvider.notifier);
      expect(await _connectFixture(session), isTrue);
      var current = _lease(
        active: true,
        generation: 80,
        armed: true,
        connectionGeneration: session.connectionGeneration,
      );
      final host = _NativeProjectionHost(messenger)
        ..currentLease = (() async => current)
        ..armContinuity = ((_, _) async => current);
      host.install();
      addTearDown(host.uninstall);
      addTearDown(container.dispose);
      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      await _eventually(() => session.hasArmedProjectionContinuity);
      _background(binding);
      current = _lease(active: true, generation: 80, armed: false);
      host.producerOwner = null;
      await host.sendLease(current);
      await _eventually(
        () =>
            !session.hasArmedProjectionContinuity && !session.engine!.isRunning,
      );
      expect(session.hasArmedProjectionContinuity, isFalse);
      expect(host.claimedProducers, [session.connectionGeneration]);
      expect(host.armContinuityCalls, 0);
      expect(session.engine!.isRunning, isFalse);
    },
  );

  test(
    'accepts a confirmed armed lease when HOME reconciles during confirmation',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(await _connectFixture(session), isTrue);
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
    'late and reconnected leases restore paused polling and bridge frames',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final bridged = <CarTelemetryMessage>[];
      late CarProjectionLeaseMessage armed;
      final host = _NativeProjectionHost(messenger);
      host.currentLease = () async {
        if (host.currentLeaseCalls == 1) {
          throw PlatformException(code: 'not-ready');
        }
        return armed;
      };
      host.armContinuity = (projectionGeneration, requestedConnection) async {
        expect(projectionGeneration, armed.generation);
        expect(requestedConnection, armed.connectionGeneration);
        return armed;
      };
      host.install();
      addTearDown(host.uninstall);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          carProjectionEnabledProvider.overrideWithValue(true),
          carTelemetryTransportProvider.overrideWithValue(
            (frame) async => bridged.add(frame),
          ),
        ],
      );
      addTearDown(container.dispose);
      final projection = container.listen(
        carProjectionRuntimeProvider,
        (_, _) {},
      );
      addTearDown(projection.close);
      expect(projection.read(), isNotNull);
      await _eventually(() => host.currentLeaseCalls == 1);

      final session = container.read(obdSessionProvider.notifier);
      expect(await _connectFixture(session), isTrue);
      final connectionGeneration = session.connectionGeneration;
      await _eventually(
        () => bridged.any(_hasLiveCoreValues),
        reason: 'the connected fixture must publish a live bridge frame',
      );

      _background(binding);
      await _eventually(
        () => !session.engine!.isRunning,
        reason: 'the phone lifecycle must drain polling before the late lease',
      );

      armed = _lease(
        active: true,
        generation: 11,
        armed: true,
        connectionGeneration: connectionGeneration,
      );
      await host.sendLease(_lease(active: true, generation: 11, armed: false));

      await _eventually(
        () =>
            session.hasArmedProjectionContinuity &&
            session.engine!.isRunning &&
            bridged.last.connectionEpoch == connectionGeneration &&
            _hasLiveCoreValues(bridged.last),
        reason: 'the projection-attested lease must resume hidden polling',
      );
      expect(session.isForeground, isFalse);
      expect(host.armContinuityCalls, 1);
      expect(session.connectionGeneration, connectionGeneration);

      await host.sendLease(_lease(active: false, generation: 11, armed: false));
      await _eventually(
        () =>
            host.acknowledgedGenerations.contains(11) &&
            !session.engine!.isRunning,
        reason: 'disconnect must retire and drain the first lease',
      );

      armed = _lease(
        active: true,
        generation: 12,
        armed: true,
        connectionGeneration: connectionGeneration,
      );
      await host.sendLease(_lease(active: true, generation: 12, armed: false));
      await _eventually(
        () =>
            host.armContinuityCalls == 2 &&
            session.hasArmedProjectionContinuity &&
            session.engine!.isRunning &&
            _hasLiveCoreValues(bridged.last),
        reason: 'a newer reconnected projection must reacquire while paused',
      );
      expect(session.isForeground, isFalse);
      expect(session.connectionGeneration, connectionGeneration);
      expect(host.claimedProducers, [connectionGeneration]);
      expect(host.retiredProducers, isEmpty);
      expect(host.producerOwner, connectionGeneration);
    },
  );

  test('a failed paused arm is consumed until foreground resumes', () async {
    final container = await _container();
    addTearDown(container.dispose);
    final session = container.read(obdSessionProvider.notifier);
    expect(await _connectFixture(session), isTrue);
    final connectionGeneration = session.connectionGeneration;
    final unarmed = _lease(active: true, generation: 15, armed: false);
    final armed = _lease(
      active: true,
      generation: 15,
      armed: true,
      connectionGeneration: connectionGeneration,
    );
    var succeed = false;
    final host = _NativeProjectionHost(messenger);
    host.currentLease = () async {
      if (host.currentLeaseCalls == 1) {
        throw PlatformException(code: 'not-ready');
      }
      return armed;
    };
    host.armContinuity = (_, _) async => succeed ? armed : unarmed;
    host.install();
    addTearDown(host.uninstall);
    expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
    await _eventually(() => host.currentLeaseCalls == 1);

    await _eventually(
      () => host.claimedProducers.contains(connectionGeneration),
    );
    _background(binding);
    await _eventually(() => !session.engine!.isRunning);
    await host.sendLease(unarmed);
    await _eventually(() => host.armContinuityCalls == 1);

    await host.sendLease(unarmed);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(host.armContinuityCalls, 1);
    expect(session.hasArmedProjectionContinuity, isFalse);

    succeed = true;
    _foreground(binding);
    await _eventually(
      () => session.isForeground,
      reason: 'resume validation must reopen the foreground retry gate',
      timeout: const Duration(seconds: 12),
    );
    if (host.armContinuityCalls == 1) {
      await host.sendLease(unarmed);
    }
    await _eventually(
      () =>
          host.armContinuityCalls >= 2 && session.hasArmedProjectionContinuity,
      reason: 'foreground resume may retry the consumed generation',
    );
  });

  test(
    'a stale release cannot cancel a newer lease awaiting confirmation',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(await _connectFixture(session), isTrue);
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
    expect(await _connectFixture(session), isTrue);
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
    await host.sendLease(_lease(active: true, generation: 20, armed: false));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(host.armContinuityCalls, 0);
  });

  test('disposal retires after an in-flight producer claim commits', () async {
    final container = await _container();
    final session = container.read(obdSessionProvider.notifier);
    final inactive = _lease(active: false, generation: 0, armed: false);
    final claim = Completer<CarProjectionLeaseMessage>();
    final events = <String>[];
    final host = _NativeProjectionHost(messenger)
      ..currentLease = (() async => inactive)
      ..armContinuity = ((_, _) async => inactive)
      ..onClaimProducer = ((_) async {
        events.add('claim started');
        final response = await claim.future;
        events.add('claim committed');
        return response;
      })
      ..onRetireProducer = ((_) async => events.add('producer retired'));
    host.install();
    addTearDown(host.uninstall);
    addTearDown(container.dispose);
    final runtime = container.read(carProjectionSessionRuntimeProvider)!;
    expect(await _connectFixture(session), isTrue);
    final generation = session.connectionGeneration;
    await _eventually(() => host.claimedProducers.contains(generation));
    runtime.dispose();
    expect(host.retiredProducers, isEmpty);
    claim.complete(
      _lease(
        active: false,
        generation: 0,
        armed: false,
        producerConnectionGeneration: generation,
      ),
    );
    await _eventually(() => host.retiredProducers.contains(generation));
    expect(events, ['claim started', 'claim committed', 'producer retired']);
    expect(host.producerOwner, isNull);
  });

  test(
    'disconnect during old-owner retirement cannot claim a stale session',
    () async {
      final container = await _container();
      final session = container.read(obdSessionProvider.notifier);
      final inactive = _lease(active: false, generation: 0, armed: false);
      final retirement = Completer<void>();
      final host = _NativeProjectionHost(messenger)
        ..currentLease = (() async => inactive)
        ..armContinuity = ((_, _) async => inactive);
      host.install();
      addTearDown(host.uninstall);
      addTearDown(container.dispose);
      expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
      expect(await _connectFixture(session), isTrue);
      final first = session.connectionGeneration;
      await _eventually(() => host.claimedProducers.contains(first));
      host.onRetireProducer = (_) => retirement.future;
      expect(await _connectFixture(session), isTrue);
      await _eventually(() => host.retiredProducers.contains(first));
      await session.disconnect();
      retirement.complete();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(host.claimedProducers, [first]);
      expect(host.producerOwner, isNull);
    },
  );

  test('built-in demo does not create a connected-device service', () async {
    final container = await _container();
    final session = container.read(obdSessionProvider.notifier);
    final inactive = _lease(active: false, generation: 0, armed: false);
    final host = _NativeProjectionHost(messenger)
      ..currentLease = (() async => inactive)
      ..armContinuity = ((_, _) async => inactive);
    host.install();
    addTearDown(host.uninstall);
    addTearDown(container.dispose);
    expect(container.read(carProjectionSessionRuntimeProvider), isNotNull);
    expect(await session.connectDemo(), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(container.read(obdSessionProvider).isConnected, isTrue);
    expect(host.claimedProducers, isEmpty);
    expect(host.armContinuityCalls, 0);
  });

  test(
    'a released generation cannot be revived by its late armed callback',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(await _connectFixture(session), isTrue);
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
      expect(await _connectFixture(session), isTrue);
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
      expect(await _connectFixture(session), isTrue);
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
      expect(host.currentLeaseCalls, greaterThanOrEqualTo(3));
    },
  );

  test(
    'an acknowledge exception leaves authority closed and reducer usable',
    () async {
      final container = await _container();
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      expect(await _connectFixture(session), isTrue);
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
        await _connectFixture(
          session,
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
    expect(await _connectFixture(session), isTrue);
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
