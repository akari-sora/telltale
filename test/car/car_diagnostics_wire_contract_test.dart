// AA-04 cross-language wire contract, Dart half.
//
// Pins the exact bytes the production Dart diagnostics client sends
// (resources/carbridge/car_diagnostics_v1_report.hex) and verifies against
// the Kotlin reply (resources/carbridge/car_diagnostics_v1_reply.hex).
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/car/car_dtc_bridge.dart';
import 'package:torque_obd/car/car_dtc_report.dart';
import 'package:torque_obd/car/generated/car_diagnostics.g.dart';

const _channel =
    'dev.flutter.pigeon.torque_obd.CarDiagnosticsHostApi.publishDtcReport';
const _fixtures = 'android/app/src/testCarProto/resources/carbridge';
const _reportFixture = '$_fixtures/car_diagnostics_v1_report.hex';
const _replyFixture = '$_fixtures/car_diagnostics_v1_reply.hex';

CarDtcReport goldenReport() => const CarDtcReport(
  reportSequence: 5000000000,
  connectionEpoch: 7,
  phase: CarDtcScanPhase.idle,
  verdict: CarDtcVerdict.faultsFound,
  coverageComplete: true,
  milOn: true,
  totalCodes: 3,
  freezeFrameReadIncomplete: false,
  items: [
    CarDtcItem(
      code: 'P0300',
      kind: CarDtcKind.stored,
      sourceId: '7E8',
      manufacturerSpecific: false,
      completeness: CarDtcObservationCompleteness.complete,
    ),
    CarDtcItem(
      code: 'P0171',
      kind: CarDtcKind.pending,
      sourceId: null,
      manufacturerSpecific: false,
      completeness: CarDtcObservationCompleteness.partial,
    ),
    CarDtcItem(
      code: 'C0035',
      kind: CarDtcKind.permanent,
      sourceId: '7E0',
      manufacturerSpecific: true,
      completeness: CarDtcObservationCompleteness.complete,
    ),
  ],
  freezeFrames: [
    CarFreezeFrame(
      sourceId: '7E8',
      frameNumber: 0,
      causeCode: 'P0300',
      causeKind: CarDtcKind.stored,
      causeSourceId: '7E8',
      readings: [
        CarFreezeReading(signal: CarFreezeSignalKind.speedKmh, value: 65.0),
        CarFreezeReading(signal: CarFreezeSignalKind.rpm, value: 2200.0),
        CarFreezeReading(signal: CarFreezeSignalKind.coolantC, value: 98.0),
        CarFreezeReading(signal: CarFreezeSignalKind.intakeAirC, value: 30.0),
        CarFreezeReading(signal: CarFreezeSignalKind.engineLoadPct, value: 45.0),
        CarFreezeReading(signal: CarFreezeSignalKind.mapKpa, value: 70.0),
        CarFreezeReading(
          signal: CarFreezeSignalKind.controlModuleVoltageV,
          value: 13.8,
        ),
      ],
      undecodableCount: 1,
      unreadCount: 2,
      omittedByProjectionCount: 3,
      contentsUnknown: false,
    ),
  ],
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

  test('the production client puts exactly the pinned v1 bytes on the channel',
      () async {
    ByteData? sent;
    messenger.setMockMessageHandler(_channel, (data) async {
      sent = data;
      return _bytes(File(_replyFixture).readAsStringSync());
    });

    await pigeonCarDiagnosticsTransport()(encodeCarDtcReport(goldenReport()));

    expect(sent, isNotNull);
    final actual = _hex(sent!);
    if (Platform.environment['UPDATE_CAR_WIRE_GOLDEN'] == '1' ||
        !File(_reportFixture).existsSync()) {
      File(_reportFixture).writeAsStringSync('$actual\n');
    }
    expect(
      actual,
      File(_reportFixture).readAsStringSync().trim(),
      reason:
          'Dart wire bytes drifted from $_reportFixture. If the schema or '
          'Pigeon changed on purpose, regenerate and make the Kotlin '
          'CarDiagnosticsWireContractTest pass against it.',
    );
  });

  test('the pinned report decodes back to every field it was built from', () {
    const codec = CarDiagnosticsHostApi.pigeonChannelCodec;
    final args =
        codec.decodeMessage(_bytes(File(_reportFixture).readAsStringSync()))!
            as List<Object?>;
    final report = args.single! as CarDtcReportMessage;
    expect(report.schemaVersion, 1);
    expect(report.reportSequence, 5000000000);
    expect(report.connectionEpoch, 7);
    expect(report.phase, CarDtcScanPhaseMessage.idle);
    expect(report.verdict, CarDtcVerdictMessage.faultsFound);
    expect(report.coverageComplete, isTrue);
    expect(report.milOn, isTrue);
    expect(report.totalCodes, 3);
    expect(report.freezeFrameReadIncomplete, isFalse);

    expect(report.items.length, 3);
    expect(report.items[0].code, 'P0300');
    expect(report.items[0].kind, CarDtcKindMessage.stored);
    expect(report.items[0].sourceId, '7E8');
    expect(report.items[0].manufacturerSpecific, isFalse);
    expect(
      report.items[0].completeness,
      CarDtcObservationCompletenessMessage.complete,
    );

    expect(report.items[1].code, 'P0171');
    expect(report.items[1].kind, CarDtcKindMessage.pending);
    expect(report.items[1].sourceId, isNull);
    expect(report.items[1].manufacturerSpecific, isFalse);
    expect(
      report.items[1].completeness,
      CarDtcObservationCompletenessMessage.partial,
    );

    expect(report.items[2].code, 'C0035');
    expect(report.items[2].kind, CarDtcKindMessage.permanent);
    expect(report.items[2].sourceId, '7E0');
    expect(report.items[2].manufacturerSpecific, isTrue);
    expect(
      report.items[2].completeness,
      CarDtcObservationCompletenessMessage.complete,
    );

    expect(report.freezeFrames.length, 1);
    final ff = report.freezeFrames[0];
    expect(ff.sourceId, '7E8');
    expect(ff.frameNumber, 0);
    expect(ff.causeCode, 'P0300');
    expect(ff.causeKind, CarDtcKindMessage.stored);
    expect(ff.causeSourceId, '7E8');
    expect(ff.readings.length, 7);
    expect(ff.readings[0].signal, CarFreezeSignalKindMessage.speedKmh);
    expect(ff.readings[0].value, 65.0);
    expect(ff.readings[1].signal, CarFreezeSignalKindMessage.rpm);
    expect(ff.readings[1].value, 2200.0);
    expect(ff.readings[2].signal, CarFreezeSignalKindMessage.coolantC);
    expect(ff.readings[2].value, 98.0);
    expect(ff.readings[3].signal, CarFreezeSignalKindMessage.intakeAirC);
    expect(ff.readings[3].value, 30.0);
    expect(ff.readings[4].signal, CarFreezeSignalKindMessage.engineLoadPct);
    expect(ff.readings[4].value, 45.0);
    expect(ff.readings[5].signal, CarFreezeSignalKindMessage.mapKpa);
    expect(ff.readings[5].value, 70.0);
    expect(
      ff.readings[6].signal,
      CarFreezeSignalKindMessage.controlModuleVoltageV,
    );
    expect(ff.readings[6].value, 13.8);
    expect(ff.undecodableCount, 1);
    expect(ff.unreadCount, 2);
    expect(ff.omittedByProjectionCount, 3);
    expect(ff.contentsUnknown, isFalse);
  });

  test('the reply the Kotlin handler really sends is a success, not a disable',
      () async {
    final logs = <String>[];
    var replies = 0;
    messenger.setMockMessageHandler(_channel, (_) async {
      replies++;
      return _bytes(File(_replyFixture).readAsStringSync());
    });

    final bridge = CarDtcBridge(
      transport: pigeonCarDiagnosticsTransport(),
      log: logs.add,
    );
    bridge.offer(goldenReport());
    await pumpEventQueue();
    bridge.offer(goldenReport());
    await pumpEventQueue();

    expect(replies, 2);
    expect(bridge.disabled, isFalse);
    expect(bridge.inFlight, isFalse);
    expect(logs, isEmpty, reason: 'a real host reply must not log an error');
  });
}
