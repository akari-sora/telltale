// AA-02 cross-language wire contract, Dart half.
//
// The Dart bridge tests and the Kotlin adapter tests each stop at their own
// language boundary: Dart decodes its own bytes with its own codec, and Kotlin
// builds `CarTelemetryMessage` objects directly. Neither proves that the bytes
// the real Dart client puts on the channel are what the generated Kotlin
// handler can decode, or that the reply Kotlin really sends is accepted.
//
// Both halves therefore pin the same committed bytes, kept in the carProto
// unit-test resources (android/app/src/testCarProto/resources/carbridge/) so
// Gradle tracks them as test inputs and re-runs the Kotlin half on any edit:
//
// - car_telemetry_v1_frame.hex — what the production Dart client sends for
//   one fixed schema-v1 frame. Asserted here; decoded by the real generated
//   Kotlin handler in
//   android/app/src/testCarProto/.../CarTelemetryWireContractTest.kt.
// - car_telemetry_v1_reply.hex — what that Kotlin handler replies. Asserted
//   there; fed back to the real Dart client here.
//
// Regenerate the frame (only after an intentional schema / Pigeon change):
//
//     UPDATE_CAR_WIRE_GOLDEN=1 fvm flutter test \
//         test/car/car_telemetry_wire_contract_test.dart
//
// The reply fixture is owned by the Kotlin test and is never rewritten here.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/car/car_telemetry_bridge.dart';
import 'package:torque_obd/car/car_telemetry_frame.dart';
import 'package:torque_obd/car/generated/car_telemetry.g.dart';
import 'package:torque_obd/state/obd_session.dart' show ConnectionPhase;

const _channel =
    'dev.flutter.pigeon.torque_obd.CarTelemetryHostApi.publishTelemetryFrame';
const _fixtures = 'android/app/src/testCarProto/resources/carbridge';
const _frameFixture = '$_fixtures/car_telemetry_v1_frame.hex';
const _replyFixture = '$_fixtures/car_telemetry_v1_reply.hex';

/// The one frame both languages agree on. Every field is distinct and every
/// signal status appears, so a swapped field or enum ordinal cannot pass.
///
/// The sequence is above 2^32 on purpose: a codec that narrowed integers to
/// 32 bits on either side would corrupt it.
CarTelemetryFrame goldenFrame() => CarTelemetryFrame(
  sequence: 5000000000,
  projection: CarTelemetryProjection(
    connectionPhase: ConnectionPhase.connected,
    connectionEpoch: 7,
    lifecycleEpoch: 2,
    producedAtMonotonicUs: 123456789012,
    speedKmh: CarSignal.live(42.5),
    rpm: CarSignal.live(1800),
    coolantC: CarSignal.stale,
    intakeAirC: CarSignal.unsupported,
    controlModuleVoltageV: CarSignal.unavailable,
    mapKpa: CarSignal.live(35.25),
    diagnostics: const CarDiagnosticsSummary.scanned(dtcCount: 3, milOn: true),
  ),
);

String _hex(ByteData data) => data.buffer
    .asUint8List(data.offsetInBytes, data.lengthInBytes)
    .map((b) => b.toRadixString(16).padLeft(2, '0'))
    .join();

ByteData _bytes(String hex) {
  final clean = hex.trim();
  final out = Uint8List(clean.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return ByteData.sublistView(out);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMessageHandler(_channel, null));

  test('the production client puts exactly the pinned v1 bytes on the '
      'channel', () async {
    ByteData? sent;
    messenger.setMockMessageHandler(_channel, (data) async {
      sent = data;
      return _bytes(File(_replyFixture).readAsStringSync());
    });

    // Through the real encoder and the real generated client, not a
    // hand-built message.
    await pigeonCarTelemetryTransport()(encodeCarTelemetryFrame(goldenFrame()));

    expect(sent, isNotNull);
    final actual = _hex(sent!);
    if (Platform.environment['UPDATE_CAR_WIRE_GOLDEN'] == '1') {
      File(_frameFixture).writeAsStringSync('$actual\n');
    }
    expect(
      actual,
      File(_frameFixture).readAsStringSync().trim(),
      reason:
          'Dart wire bytes drifted from $_frameFixture. If the schema or '
          'Pigeon changed on purpose, regenerate (see file header) and make '
          'the Kotlin CarTelemetryWireContractTest pass against it.',
    );
  });

  test('the pinned frame decodes back to every field it was built from', () {
    const codec = CarTelemetryHostApi.pigeonChannelCodec;
    final args =
        codec.decodeMessage(_bytes(File(_frameFixture).readAsStringSync()))!
            as List<Object?>;
    final m = args.single! as CarTelemetryMessage;
    expect(m.schemaVersion, 1);
    expect(m.sequence, 5000000000);
    expect(m.connectionEpoch, 7);
    expect(m.lifecycleEpoch, 2);
    expect(m.producedAtMonotonicUs, 123456789012);
    expect(m.connectionPhase, CarConnectionPhaseMessage.connected);
    expect(m.speedKmh.status, CarSignalStatusMessage.live);
    expect(m.speedKmh.value, 42.5);
    expect(m.rpm.value, 1800);
    expect(m.coolantC.status, CarSignalStatusMessage.stale);
    expect(m.coolantC.value, isNull);
    expect(m.intakeAirC.status, CarSignalStatusMessage.unsupported);
    expect(m.intakeAirC.value, isNull);
    expect(m.controlModuleVoltageV.status, CarSignalStatusMessage.unavailable);
    expect(m.controlModuleVoltageV.value, isNull);
    expect(m.mapKpa.value, 35.25);
    expect(m.diagnosticsAvailable, isTrue);
    expect(m.milOn, isTrue);
    expect(m.dtcCount, 3);
  });

  test('the reply the Kotlin handler really sends is a success, not a '
      'disable or a transient error', () async {
    final logs = <String>[];
    var replies = 0;
    messenger.setMockMessageHandler(_channel, (_) async {
      replies++;
      return _bytes(File(_replyFixture).readAsStringSync());
    });

    final bridge = CarTelemetryBridge(
      transport: pigeonCarTelemetryTransport(),
      log: logs.add,
    );
    bridge.offer(goldenFrame().projection);
    await pumpEventQueue();
    bridge.offer(goldenFrame().projection);
    await pumpEventQueue();

    expect(replies, 2);
    expect(bridge.disabled, isFalse);
    expect(bridge.inFlight, isFalse);
    expect(logs, isEmpty, reason: 'a real host reply must not log an error');
  });
}
