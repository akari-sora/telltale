import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/car/car_dtc_projector.dart';
import 'package:torque_obd/car/car_dtc_report.dart';
import 'package:torque_obd/obd/dtc/dtc.dart';
import 'package:torque_obd/obd/freeze_frame.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart' show MilStatus, MilSummary;
import 'package:torque_obd/state/dtc_scan.dart';

void main() {
  group('CarDtcProjector', () {
    test('projects initial idle state without scan', () {
      const state = DtcScanState();
      final report = projectCarDtcReport(
        dtc: state,
        connectionEpoch: 2,
        reportSequence: 1,
      );

      expect(report.schemaVersion, equals(1));
      expect(report.connectionEpoch, equals(2));
      expect(report.reportSequence, equals(1));
      expect(report.phase, equals(CarDtcScanPhase.idle));
      expect(report.verdict, equals(CarDtcVerdict.notScanned));
      expect(report.coverageComplete, isFalse);
      expect(report.milOn, isNull);
      expect(report.totalCodes, isNull);
      expect(report.items, isEmpty);
      expect(report.freezeFrames, isEmpty);
      expect(report.freezeFrameReadIncomplete, isFalse);
    });

    test('projects scanning and interrupted phases', () {
      const scanningState = DtcScanState(loading: true);
      final scanningReport = projectCarDtcReport(
        dtc: scanningState,
        connectionEpoch: 1,
        reportSequence: 1,
      );
      expect(scanningReport.phase, equals(CarDtcScanPhase.scanning));

      const interruptedState = DtcScanState(
        scanBanner: DtcScanBanner.interrupted,
      );
      final interruptedReport = projectCarDtcReport(
        dtc: interruptedState,
        connectionEpoch: 1,
        reportSequence: 2,
      );
      expect(interruptedReport.phase, equals(CarDtcScanPhase.interrupted));
    });

    test('projects MIL status and clean verdict', () {
      final state = DtcScanState(
        scannedAt: DateTime.utc(2026, 10, 5),
        results: {
          DtcKind.stored: const DtcCategoryResult.codes([]),
          DtcKind.pending: const DtcCategoryResult.codes([]),
          DtcKind.permanent: const DtcCategoryResult.codes([]),
        },
        mil: const MilStatus({
          '7E8': MilSummary(milOn: false, confirmedCount: 0),
        }),
      );

      final report = projectCarDtcReport(
        dtc: state,
        connectionEpoch: 3,
        reportSequence: 1,
      );

      expect(report.verdict, equals(CarDtcVerdict.completeClean));
      expect(report.coverageComplete, isTrue);
      expect(report.milOn, isFalse);
      expect(report.totalCodes, equals(0));
      expect(report.items, isEmpty);
    });

    test('projects DTC items with kind, sourceId, and completeness', () {
      const failure = DtcReadException(
        'read error',
        kind: DtcReadFailure.error,
        partial: [
          Dtc(
            code: 'P0171',
            category: DtcCategory.powertrain,
            kind: DtcKind.stored,
            sourceId: '7E8',
            isManufacturerSpecific: false,
          ),
        ],
      );

      final state = DtcScanState(
        scannedAt: DateTime.utc(2026, 10, 5),
        results: {
          DtcKind.stored: const DtcCategoryResult.failed(failure),
          DtcKind.pending: const DtcCategoryResult.codes([
            Dtc(
              code: 'P0420',
              category: DtcCategory.powertrain,
              kind: DtcKind.pending,
              sourceId: '7E8',
              isManufacturerSpecific: false,
            ),
          ]),
        },
        mil: const MilStatus({
          '7E8': MilSummary(milOn: true, confirmedCount: 2),
        }),
      );

      final report = projectCarDtcReport(
        dtc: state,
        connectionEpoch: 1,
        reportSequence: 1,
      );

      expect(report.verdict, equals(CarDtcVerdict.faultsFound));
      expect(report.coverageComplete, isFalse);
      expect(report.milOn, isTrue);
      expect(report.totalCodes, equals(2));
      expect(report.items.length, equals(2));

      final p0171 = report.items.firstWhere((i) => i.code == 'P0171');
      expect(p0171.kind, equals(CarDtcKind.stored));
      expect(p0171.sourceId, equals('7E8'));
      expect(p0171.completeness, equals(CarDtcObservationCompleteness.partial));

      final p0420 = report.items.firstWhere((i) => i.code == 'P0420');
      expect(p0420.kind, equals(CarDtcKind.pending));
      expect(p0420.completeness, equals(CarDtcObservationCompleteness.complete));
    });

    test('deduplicates DTC items by identity with complete winning over partial',
        () {
      const dtc = Dtc(
        code: 'P0300',
        category: DtcCategory.powertrain,
        kind: DtcKind.stored,
        sourceId: '7E8',
        isManufacturerSpecific: false,
      );

      final state = DtcScanState(
        scannedAt: DateTime.utc(2026, 10, 5),
        results: {
          DtcKind.stored: const DtcCategoryResult.codes([dtc]),
          DtcKind.pending: const DtcCategoryResult.failed(
            DtcReadException(
              'error',
              kind: DtcReadFailure.error,
              partial: [dtc],
            ),
          ),
        },
      );

      final report = projectCarDtcReport(
        dtc: state,
        connectionEpoch: 1,
        reportSequence: 1,
      );

      expect(report.items.length, equals(1));
      expect(report.items.first.code, equals('P0300'));
      expect(
        report.items.first.completeness,
        equals(CarDtcObservationCompleteness.complete),
      );
    });

    test('whitelists freeze frame signals and tracks omitted/undecodable', () {
      final state = DtcScanState(
        scannedAt: DateTime.utc(2026, 10, 5),
        freezeFrameUnread: true,
        freezeFrames: const [
          FreezeFrame(
            source: '7E8',
            frameNumber: 0,
            cause: Dtc(
              code: 'P0300',
              category: DtcCategory.powertrain,
              kind: DtcKind.stored,
              sourceId: '7E8',
              isManufacturerSpecific: false,
            ),
            readings: [
              FreezeReading(
                pid: PidLibrary.vehicleSpeed,
                value: 65.0,
                raw: [0x41],
              ),
              FreezeReading(
                pid: PidLibrary.coolantTemp,
                value: 95.0,
                raw: [0x87],
              ),
              FreezeReading(
                pid: PidLibrary.throttlePosition,
                value: 20.0,
                raw: [0x33],
              ),
            ],
            undecodable: 1,
            unread: 0,
          ),
        ],
      );

      final report = projectCarDtcReport(
        dtc: state,
        connectionEpoch: 1,
        reportSequence: 1,
      );

      expect(report.freezeFrames.length, equals(1));
      final ff = report.freezeFrames.first;
      expect(ff.sourceId, equals('7E8'));
      expect(ff.frameNumber, equals(0));
      expect(ff.causeCode, equals('P0300'));
      expect(ff.causeKind, equals(CarDtcKind.stored));
      expect(ff.readings.length, equals(2));
      expect(ff.readings[0].signal, equals(CarFreezeSignalKind.speedKmh));
      expect(ff.readings[0].value, equals(65.0));
      expect(ff.readings[1].signal, equals(CarFreezeSignalKind.coolantC));
      expect(ff.readings[1].value, equals(95.0));
      expect(ff.omittedByProjectionCount, equals(1));
      expect(ff.undecodableCount, equals(1));
      expect(report.freezeFrameReadIncomplete, isTrue);
    });
  });
}
