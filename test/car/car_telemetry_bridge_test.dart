import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/car/car_telemetry_bridge.dart';
import 'package:torque_obd/car/car_telemetry_frame.dart';
import 'package:torque_obd/car/generated/car_telemetry.g.dart';
import 'package:torque_obd/state/obd_session.dart' show ConnectionPhase;

CarTelemetryProjection _projection({
  int epoch = 1,
  ConnectionPhase phase = ConnectionPhase.connected,
  double speed = 10,
  CarDiagnosticsSummary diagnostics = CarDiagnosticsSummary.unavailable,
}) => CarTelemetryProjection(
  connectionPhase: phase,
  connectionEpoch: epoch,
  lifecycleEpoch: 0,
  producedAtMonotonicUs: 5,
  speedKmh: CarSignal.live(speed),
  rpm: CarSignal.stale,
  coolantC: CarSignal.unsupported,
  intakeAirC: CarSignal.unavailable,
  controlModuleVoltageV: CarSignal.live(13.9),
  mapKpa: CarSignal.live(40),
  diagnostics: diagnostics,
);

/// A transport whose calls complete only when the test says so.
final class _GatedTransport {
  final List<CarTelemetryMessage> sent = [];
  final List<Completer<void>> _gates = [];

  Future<void> call(CarTelemetryMessage message) {
    sent.add(message);
    final gate = Completer<void>();
    _gates.add(gate);
    return gate.future;
  }

  void completeNext() => _gates.removeAt(0).complete();

  void failNext(Object error) => _gates.removeAt(0).completeError(error);

  int get outstanding => _gates.length;
}

void main() {
  group('encoding (schema v1)', () {
    test('AA02-04 every frame is schemaVersion 1 with a stamped sequence', () {
      final message = encodeCarTelemetryFrame(
        CarTelemetryFrame(sequence: 7, projection: _projection(epoch: 3)),
      );
      expect(message.schemaVersion, 1);
      expect(carTelemetrySchemaVersion, 1);
      expect(message.sequence, 7);
      expect(message.connectionEpoch, 3);
      expect(message.lifecycleEpoch, 0);
      expect(message.producedAtMonotonicUs, 5);
      expect(message.connectionPhase, CarConnectionPhaseMessage.connected);
      expect(message.speedKmh.status, CarSignalStatusMessage.live);
      expect(message.speedKmh.value, 10);
      expect(message.controlModuleVoltageV.value, 13.9);
      expect(message.mapKpa.value, 40);
    });

    test('AA02-15 non-live signals transport no number', () {
      final message = encodeCarTelemetryFrame(
        CarTelemetryFrame(sequence: 1, projection: _projection()),
      );
      expect(message.rpm.status, CarSignalStatusMessage.stale);
      expect(message.rpm.value, isNull);
      expect(message.coolantC.status, CarSignalStatusMessage.unsupported);
      expect(message.coolantC.value, isNull);
      expect(message.intakeAirC.status, CarSignalStatusMessage.unavailable);
      expect(message.intakeAirC.value, isNull);
    });

    test('every connection phase maps one-to-one', () {
      final seen = <CarConnectionPhaseMessage>{};
      for (final phase in ConnectionPhase.values) {
        final message = encodeCarTelemetryFrame(
          CarTelemetryFrame(sequence: 1, projection: _projection(phase: phase)),
        );
        expect(message.connectionPhase.name, phase.name);
        seen.add(message.connectionPhase);
      }
      expect(seen, hasLength(CarConnectionPhaseMessage.values.length));
    });

    test('diagnostics: unavailable sends nulls; scanned keeps exact values', () {
      final none = encodeCarTelemetryFrame(
        CarTelemetryFrame(sequence: 1, projection: _projection()),
      );
      expect(none.diagnosticsAvailable, isFalse);
      expect(none.dtcCount, isNull);
      expect(none.milOn, isNull);

      final scanned = encodeCarTelemetryFrame(
        CarTelemetryFrame(
          sequence: 1,
          projection: _projection(
            diagnostics: const CarDiagnosticsSummary.scanned(dtcCount: 3),
          ),
        ),
      );
      expect(scanned.diagnosticsAvailable, isTrue);
      expect(scanned.dtcCount, 3);
      expect(scanned.milOn, isNull);
    });

    test('a live signal cannot be built from a non-finite number', () {
      expect(CarSignal.live(double.nan), CarSignal.unavailable);
      expect(CarSignal.live(double.infinity).value, isNull);
    });
  });

  group('single-flight latest-wins (AA02-20)', () {
    test('backlog collapses to the newest projection', () async {
      final transport = _GatedTransport();
      final bridge = CarTelemetryBridge(transport: transport.call);

      bridge.offer(_projection(speed: 1));
      for (var speed = 2.0; speed <= 50; speed++) {
        bridge.offer(_projection(speed: speed));
      }
      expect(transport.sent, hasLength(1), reason: 'only one call in flight');
      expect(transport.outstanding, 1);

      transport.completeNext();
      await pumpEventQueue();

      expect(transport.sent, hasLength(2));
      expect(transport.sent.last.speedKmh.value, 50, reason: 'latest wins');
      expect(transport.outstanding, 1);

      transport.completeNext();
      await pumpEventQueue();
      expect(transport.sent, hasLength(2), reason: 'nothing left pending');
      expect(bridge.inFlight, isFalse);
    });

    test('sequence advances only on actual transmissions', () async {
      final transport = _GatedTransport();
      final bridge = CarTelemetryBridge(transport: transport.call);

      bridge.offer(_projection(speed: 1));
      bridge.offer(_projection(speed: 2)); // replaced
      bridge.offer(_projection(speed: 3)); // replaced
      bridge.offer(_projection(speed: 4));
      transport.completeNext();
      await pumpEventQueue();
      transport.completeNext();
      await pumpEventQueue();

      expect(transport.sent.map((m) => m.sequence), [1, 2]);
      expect(bridge.lastSequence, 2);
    });

    test('a transient host error does not stop the bridge', () async {
      final logs = <String>[];
      final transport = _GatedTransport();
      final bridge = CarTelemetryBridge(
        transport: transport.call,
        log: logs.add,
      );

      bridge.offer(_projection(speed: 1));
      transport.failNext(PlatformException(code: 'bad-frame'));
      await pumpEventQueue();
      bridge.offer(_projection(speed: 2));
      transport.failNext(StateError('boom'));
      await pumpEventQueue();
      bridge.offer(_projection(speed: 3));

      expect(bridge.disabled, isFalse);
      expect(transport.sent, hasLength(3));
      expect(logs, hasLength(1), reason: 'transient errors log once');
      transport.completeNext();
      await pumpEventQueue();
    });
  });

  group('missing host (AA02-21)', () {
    for (final (name, error) in [
      ('MissingPluginException', MissingPluginException('none')),
      (
        'PlatformException(channel-error)',
        PlatformException(code: 'channel-error', message: 'no handler'),
      ),
    ]) {
      test('$name disables permanently, drops pending, no retry', () async {
        final logs = <String>[];
        var disabledCalls = 0;
        final transport = _GatedTransport();
        final bridge = CarTelemetryBridge(
          transport: transport.call,
          onDisabled: () => disabledCalls++,
          log: logs.add,
        );

        bridge.offer(_projection(speed: 1));
        bridge.offer(_projection(speed: 2)); // pending
        transport.failNext(error);
        await pumpEventQueue();

        expect(bridge.disabled, isTrue);
        expect(disabledCalls, 1);
        expect(transport.sent, hasLength(1), reason: 'pending was dropped');

        for (var i = 0; i < 20; i++) {
          bridge.offer(_projection(speed: i.toDouble()));
        }
        await pumpEventQueue();
        expect(transport.sent, hasLength(1), reason: 'never retried');
        expect(logs, hasLength(1), reason: 'one diagnostic line, no spam');
        expect(logs.single, contains('disabled'));
      });
    }

    test('the real generated client with no host handler disables', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // No mock handler registered for the Pigeon channel: this is what a
      // misregistered host looks like.
      final logs = <String>[];
      final bridge = CarTelemetryBridge(
        transport: pigeonCarTelemetryTransport(),
        log: logs.add,
      );
      bridge.offer(_projection());
      await pumpEventQueue();
      expect(bridge.disabled, isTrue);
      expect(logs.single, contains('disabled'));
    });

    test('the real generated client reaches a registered host', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel =
          'dev.flutter.pigeon.torque_obd.CarTelemetryHostApi.publishTelemetryFrame';
      final received = <CarTelemetryMessage>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const codec = CarTelemetryHostApi.pigeonChannelCodec;
      messenger.setMockMessageHandler(channel, (data) async {
        final args = codec.decodeMessage(data)! as List<Object?>;
        received.add(args.single! as CarTelemetryMessage);
        return codec.encodeMessage(<Object?>[]);
      });
      addTearDown(() => messenger.setMockMessageHandler(channel, null));

      final bridge = CarTelemetryBridge(
        transport: pigeonCarTelemetryTransport(),
      );
      bridge.offer(_projection(epoch: 9, speed: 77));
      await pumpEventQueue();

      expect(bridge.disabled, isFalse);
      expect(received, hasLength(1));
      expect(received.single.schemaVersion, 1);
      expect(received.single.sequence, 1);
      expect(received.single.connectionEpoch, 9);
      expect(received.single.speedKmh.value, 77);
    });
  });

  test('dispose stops accepting and drops pending', () async {
    final transport = _GatedTransport();
    final bridge = CarTelemetryBridge(transport: transport.call);
    bridge.offer(_projection(speed: 1));
    bridge.offer(_projection(speed: 2));
    bridge.dispose();
    transport.completeNext();
    await pumpEventQueue();
    bridge.offer(_projection(speed: 3));
    expect(transport.sent, hasLength(1));
  });
}
