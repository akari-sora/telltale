import 'dart:async';

// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/car/car_projection_coordinator.dart';
import 'package:torque_obd/car/car_projection_runtime.dart';
import 'package:torque_obd/car/car_telemetry_frame.dart';
import 'package:torque_obd/car/generated/car_telemetry.g.dart';
import 'package:torque_obd/core/field_evidence/platform_metadata.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart' show sharedPreferencesProvider;

CarTelemetryProjection _projection({
  ConnectionPhase phase = ConnectionPhase.connected,
  int epoch = 1,
  double speed = 0,
  CarDiagnosticsSummary diagnostics = CarDiagnosticsSummary.unavailable,
}) => CarTelemetryProjection(
  connectionPhase: phase,
  connectionEpoch: epoch,
  lifecycleEpoch: 0,
  producedAtMonotonicUs: 0,
  speedKmh: CarSignal.live(speed),
  rpm: CarSignal.unavailable,
  coolantC: CarSignal.unavailable,
  intakeAirC: CarSignal.unavailable,
  controlModuleVoltageV: CarSignal.unavailable,
  mapKpa: CarSignal.unavailable,
  diagnostics: diagnostics,
);

void main() {
  group('cadence', () {
    test('AA02-18 normal telemetry coalesces to at most 2 Hz', () {
      fakeAsync((async) {
        final sent = <CarTelemetryMessage>[];
        var speed = 0.0;
        final coordinator = CarProjectionCoordinator(
          project: () => _projection(speed: speed),
          transport: (m) async => sent.add(m),
        );
        coordinator.start();
        async.flushMicrotasks();
        expect(sent, hasLength(1), reason: 'first activation is immediate');

        // 100 telemetry updates per second for 3 seconds.
        for (var i = 0; i < 300; i++) {
          speed = i.toDouble();
          coordinator.onInputChanged();
          async.elapse(const Duration(milliseconds: 10));
        }
        // 1 activation + one per 500 ms tick.
        expect(sent, hasLength(1 + 6));
        // Every tick carried the newest value at that moment.
        expect(sent.last.speedKmh.value, 299);
        coordinator.dispose();
      });
    });

    test('AA02-18 the tick keeps an unchanged producer alive at 2 Hz', () {
      fakeAsync((async) {
        final sent = <CarTelemetryMessage>[];
        final coordinator = CarProjectionCoordinator(
          project: _projection,
          transport: (m) async => sent.add(m),
        );
        coordinator.start();
        async.elapse(const Duration(seconds: 2));
        expect(sent, hasLength(1 + 4));
        expect(sent.map((m) => m.sequence), [1, 2, 3, 4, 5]);
        coordinator.dispose();
      });
    });

    test('AA02-19 phase / epoch / diagnostics edges bypass the tick', () {
      fakeAsync((async) {
        final sent = <CarTelemetryMessage>[];
        var current = _projection();
        final coordinator = CarProjectionCoordinator(
          project: () => current,
          transport: (m) async => sent.add(m),
        );
        coordinator.start();
        async.elapse(const Duration(milliseconds: 100));
        expect(sent, hasLength(1));

        current = _projection(phase: ConnectionPhase.disconnected);
        coordinator.onInputChanged();
        async.flushMicrotasks();
        expect(sent, hasLength(2));
        expect(sent.last.connectionPhase, CarConnectionPhaseMessage.disconnected);

        async.elapse(const Duration(milliseconds: 50));
        current = _projection(phase: ConnectionPhase.disconnected, epoch: 2);
        coordinator.onInputChanged();
        async.flushMicrotasks();
        expect(sent, hasLength(3));
        expect(sent.last.connectionEpoch, 2);

        async.elapse(const Duration(milliseconds: 50));
        current = _projection(
          phase: ConnectionPhase.disconnected,
          epoch: 2,
          diagnostics: const CarDiagnosticsSummary.scanned(dtcCount: 1),
        );
        coordinator.onInputChanged();
        async.flushMicrotasks();
        expect(sent, hasLength(4));
        expect(sent.last.dtcCount, 1);

        // An unchanged edge state does not resend outside the tick.
        coordinator.onInputChanged();
        async.flushMicrotasks();
        expect(sent, hasLength(4));
        coordinator.dispose();
      });
    });

    test('AA02-19 an edge during an in-flight call goes out right after it', () {
        fakeAsync((async) {
          final sent = <CarTelemetryMessage>[];
          final gates = <Completer<void>>[];
          var current = _projection();
          final coordinator = CarProjectionCoordinator(
            project: () => current,
            transport: (m) {
              sent.add(m);
              final gate = Completer<void>();
              gates.add(gate);
              return gate.future;
            },
          );
          coordinator.start();
          async.flushMicrotasks();
          current = _projection(phase: ConnectionPhase.failed);
          coordinator.onInputChanged();
          async.flushMicrotasks();
          expect(sent, hasLength(1), reason: 'single-flight');

          gates.removeAt(0).complete();
          async.flushMicrotasks();
          expect(sent, hasLength(2));
          expect(sent.last.connectionPhase, CarConnectionPhaseMessage.failed);
          gates.removeAt(0).complete();
          coordinator.dispose();
        });
    });

    test('AA02-21 a missing host stops the tick and all further projection', () {
        fakeAsync((async) {
          var projections = 0;
          var calls = 0;
          final coordinator = CarProjectionCoordinator(
            project: () {
              projections++;
              return _projection();
            },
            transport: (m) async {
              calls++;
              throw MissingPluginException('none');
            },
            log: (_) {},
          );
          coordinator.start();
          async.flushMicrotasks();
          expect(coordinator.bridge.disabled, isTrue);
          expect(coordinator.isTicking, isFalse);
          expect(coordinator.isStopped, isTrue);

          async.elapse(const Duration(seconds: 10));
          coordinator.onInputChanged();
          async.flushMicrotasks();
          expect(calls, 1);
          expect(projections, 1);
        });
    });

    test('dispose cancels the tick', () {
      fakeAsync((async) {
        var calls = 0;
        final coordinator = CarProjectionCoordinator(
          project: _projection,
          transport: (m) async => calls++,
        );
        coordinator.start();
        coordinator.dispose();
        async.elapse(const Duration(seconds: 5));
        expect(calls, 1);
        expect(coordinator.isTicking, isFalse);
      });
    });
  });

  group('runtime gating (AA02-05 / AA02-06)', () {
    test(
      'arbitration gate matrix returns decision object and enforces rules',
      () {
        PlatformMetadata meta(String id) => PlatformMetadata(
          applicationId: id,
          appVersion: 'v',
          appBuild: '1',
          platform: 'android',
          osVersion: '16',
          manufacturer: 'm',
          model: 'm',
          sdkInt: '36',
        );
        expect(androidCarProtoApplicationId, 'com.cbstudio.telltale.carproto');

        // 1. identity_verified: both projected flavors require their own exact id.
        for (final pair in [
          ('field', androidFieldApplicationId),
          ('carProto', androidCarProtoApplicationId),
        ]) {
          final verified = isCarProjectionEligible(
            meta(pair.$2),
            isAndroid: true,
            flavor: pair.$1,
          );
          expect(verified.enabled, isTrue, reason: pair.$1);
          expect(
            verified.reason,
            CarProjectionReason.identityVerified,
            reason: pair.$1,
          );
          expect(
            verified,
            const CarProjectionDecision(
              enabled: true,
              reason: 'identity_verified',
            ),
          );
        }

        // 2. metadata_unavailable: both projected flavors keep the car screen alive.
        for (final flavor in ['field', 'carProto']) {
          final fallback = isCarProjectionEligible(
            meta(unknownPlatformMetadata),
            isAndroid: true,
            flavor: flavor,
          );
          expect(fallback.enabled, isTrue, reason: flavor);
          expect(fallback.reason, CarProjectionReason.metadataUnavailable);
        }

        // 3. identity_conflict: cross-flavor and unrelated ids fail closed.
        for (final pair in [
          ('field', androidCarProtoApplicationId),
          ('field', androidRigApplicationId),
          ('carProto', androidFieldApplicationId),
          ('carProto', 'com.cbstudio.telltale.carproto.aaos'),
          ('carProto', 'com.example.conflicting'),
        ]) {
          final conflict = isCarProjectionEligible(
            meta(pair.$2),
            isAndroid: true,
            flavor: pair.$1,
          );
          expect(conflict.enabled, isFalse, reason: '$pair');
          expect(
            conflict.reason,
            CarProjectionReason.identityConflict,
            reason: '$pair',
          );
        }

        // 4. flavor_ineligible: rig/wear and unknown flavors never project.
        for (final flavor in ['rig', 'wear', '', 'other']) {
          final ineligible = isCarProjectionEligible(
            meta(androidCarProtoApplicationId),
            isAndroid: true,
            flavor: flavor,
          );
          expect(ineligible.enabled, isFalse, reason: 'flavor: $flavor');
          expect(
            ineligible.reason,
            CarProjectionReason.flavorIneligible,
            reason: 'flavor: $flavor',
          );

          // Even with unknown metadata, ineligible flavor fails closed.
          final unknownWithWrongFlavor = isCarProjectionEligible(
            meta(unknownPlatformMetadata),
            isAndroid: true,
            flavor: flavor,
          );
          expect(
            unknownWithWrongFlavor.enabled,
            isFalse,
            reason: 'flavor: $flavor',
          );
          expect(
            unknownWithWrongFlavor.reason,
            CarProjectionReason.flavorIneligible,
            reason: 'flavor: $flavor',
          );
        }

        // 5. non_android: non-Android platform always fails closed
        for (final flavor in ['carProto', 'field', 'rig', null]) {
          final nonAndroid = isCarProjectionEligible(
            meta(androidCarProtoApplicationId),
            isAndroid: false,
            flavor: flavor,
          );
          expect(nonAndroid.enabled, isFalse);
          expect(nonAndroid.reason, CarProjectionReason.nonAndroid);
        }

        // Real host running this test is not Android.
        final hostDecision = isCarProjectionEligible(
          meta(androidCarProtoApplicationId),
          flavor: 'carProto',
        );
        expect(hostDecision.enabled, isFalse);
        expect(hostDecision.reason, CarProjectionReason.nonAndroid);

        // 6. Decision object equality, hashCode, and toString
        const d1 = CarProjectionDecision(
          enabled: true,
          reason: 'identity_verified',
        );
        const d2 = CarProjectionDecision(
          enabled: true,
          reason: 'identity_verified',
        );
        const d3 = CarProjectionDecision(
          enabled: false,
          reason: 'flavor_ineligible',
        );
        expect(d1, equals(d2));
        expect(d1.hashCode, equals(d2.hashCode));
        expect(d1, isNot(equals(d3)));
        expect(
          d1.toString(),
          'CarProjectionDecision(enabled: true, reason: identity_verified)',
        );
      },
    );

    test('disabled: no coordinator, no transport, no listeners', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var transportCreated = false;
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          carTelemetryTransportProvider.overrideWith((ref) {
            transportCreated = true;
            return (_) async {};
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(carProjectionRuntimeProvider), isNull);
      expect(transportCreated, isFalse, reason: 'no Pigeon client created');
      expect(
        container.exists(telemetryProvider),
        isFalse,
        reason: 'disabled runtime must not subscribe to telemetry',
      );
      expect(container.exists(obdSessionProvider), isFalse);
    });

    test('enabled: a demo connection reaches the host as live v2 frames', () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final sent = <CarTelemetryMessage>[];
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            carProjectionEnabledProvider.overrideWithValue(true),
            carTelemetryTransportProvider.overrideWithValue(
              (m) async => sent.add(m),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Held the way TorqueApp holds it: a live subscription. A bare read
        // leaves the provider paused, and its telemetry listener with it.
        final subscription = container.listen(
          carProjectionRuntimeProvider,
          (_, _) {},
        );
        addTearDown(subscription.close);
        expect(subscription.read(), isNotNull);
        await pumpEventQueue();
        expect(sent, isNotEmpty, reason: 'first activation');
        expect(sent.first.schemaVersion, 2);
      expect(sent.first.connectionPhase, CarConnectionPhaseMessage.disconnected);
        expect(sent.first.diagnosticsAvailable, isFalse);

        final session = container.read(obdSessionProvider.notifier);
        expect(await session.connectDemo(), isTrue);
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (DateTime.now().isBefore(deadline) &&
            !sent.any(
              (m) =>
                  m.connectionPhase == CarConnectionPhaseMessage.connected &&
                  m.speedKmh.status == CarSignalStatusMessage.live,
            )) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        final live = sent.lastWhere(
          (m) => m.connectionPhase == CarConnectionPhaseMessage.connected,
        );
        expect(live.speedKmh.status, CarSignalStatusMessage.live);
        expect(live.speedKmh.value, isNotNull);
        expect(live.connectionEpoch, session.generation);

        // Sequences strictly increase across the whole run.
        final sequences = sent.map((m) => m.sequence).toList();
        for (var i = 1; i < sequences.length; i++) {
          expect(sequences[i], greaterThan(sequences[i - 1]));
        }

        await session.disconnect();
        await pumpEventQueue();
        expect(
          sent.last.connectionPhase,
          isNot(CarConnectionPhaseMessage.connected),
          reason: 'disconnect is an edge and goes out immediately',
        );
        expect(sent.last.speedKmh.status, isNot(CarSignalStatusMessage.live));
    });
  });
}
