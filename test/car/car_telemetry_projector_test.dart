import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/car/car_telemetry_frame.dart';
import 'package:torque_obd/car/car_telemetry_projector.dart';
import 'package:torque_obd/obd/dtc/dtc.dart';
import 'package:torque_obd/obd/pid/pid.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart' show MilStatus, MilSummary;
import 'package:torque_obd/obd/telemetry.dart';
import 'package:torque_obd/state/dtc_scan.dart';
import 'package:torque_obd/state/obd_session.dart' show ConnectionPhase;

final _t0 = DateTime.utc(2026, 10, 4, 12);

/// A snapshot whose clock sits at [elapsed] since connect, with readings
/// received at the given elapsed ticks.
TelemetrySnapshot _snapshot({
  Map<Pid, (double, Duration)> readings = const {},
  Map<Pid, PidFault> faults = const {},
  Duration elapsed = const Duration(seconds: 10),
}) {
  return TelemetrySnapshot(
    readings: {
      for (final entry in readings.entries)
        entry.key.id: Reading(
          pid: entry.key,
          value: entry.value.$1,
          rawBytes: const [],
          timestamp: _t0.add(entry.value.$2),
          receivedElapsed: entry.value.$2,
        ),
    },
    faults: {for (final entry in faults.entries) entry.key.id: entry.value},
    capturedAt: _t0.add(elapsed),
    elapsedNow: () => elapsed,
  );
}

CarSignal _signal(
  TelemetrySnapshot? snapshot,
  Pid pid, {
  ConnectionPhase phase = ConnectionPhase.connected,
  Duration nowOffset = const Duration(seconds: 10),
}) => projectCarSignal(
  telemetry: snapshot,
  connectionPhase: phase,
  pid: pid,
  now: _t0.add(nowOffset),
);

CarTelemetryProjection _project({
  TelemetrySnapshot? telemetry,
  ConnectionPhase phase = ConnectionPhase.connected,
  DtcScanState dtc = const DtcScanState(),
}) => projectCarTelemetry(
  telemetry: telemetry,
  connectionPhase: phase,
  connectionEpoch: 4,
  lifecycleEpoch: 2,
  dtc: dtc,
  monotonicUs: 77,
  now: _t0.add(const Duration(seconds: 10)),
);

void main() {
  const fresh = Duration(seconds: 9, milliseconds: 900);

  group('signal sources (AA02-09..11)', () {
    test('schema v1 reads exactly the six agreed PIDs', () {
      expect(CarTelemetrySignalSources.speedKmh.modeAndPid, '010D');
      expect(CarTelemetrySignalSources.rpm.modeAndPid, '010C');
      expect(CarTelemetrySignalSources.coolantC.modeAndPid, '0105');
      expect(CarTelemetrySignalSources.intakeAirC.modeAndPid, '010F');
      expect(CarTelemetrySignalSources.controlModuleVoltageV.modeAndPid, '0142');
      expect(CarTelemetrySignalSources.mapKpa.modeAndPid, '010B');
      // km/h source, not the mph display variant sharing 010D.
      expect(CarTelemetrySignalSources.speedKmh.units, 'km/h');
    });

    test('AA02-09 speed 010D projects live', () {
      final s = _snapshot(readings: {PidLibrary.vehicleSpeed: (63, fresh)});
      expect(_signal(s, PidLibrary.vehicleSpeed), CarSignal.live(63));
    });

    test('AA02-10 rpm 010C projects live', () {
      final s = _snapshot(readings: {PidLibrary.engineRpm: (2150.5, fresh)});
      expect(_signal(s, PidLibrary.engineRpm), CarSignal.live(2150.5));
    });

    test('AA02-11 coolant / IAT / 0142 / MAP project live into their fields', () {
      final p = _project(
        telemetry: _snapshot(
          readings: {
            PidLibrary.coolantTemp: (91, fresh),
            PidLibrary.intakeAirTemp: (-12, fresh),
            PidLibrary.controlModuleVoltage: (14.2, fresh),
            PidLibrary.manifoldPressure: (34, fresh),
          },
        ),
      );
      expect(p.coolantC, CarSignal.live(91));
      expect(p.intakeAirC, CarSignal.live(-12));
      expect(p.controlModuleVoltageV, CarSignal.live(14.2));
      expect(p.mapKpa, CarSignal.live(34));
      // Fields are not cross-wired: absent PIDs stay unavailable.
      expect(p.speedKmh, CarSignal.unavailable);
      expect(p.rpm, CarSignal.unavailable);
    });

    test('adapter supply voltage is never projected as 0142', () {
      const s = TelemetrySnapshot(batteryVoltage: 12.6);
      expect(
        _signal(s, PidLibrary.controlModuleVoltage),
        CarSignal.unavailable,
      );
    });
  });

  group('freshness (AA02-12..15)', () {
    test('AA02-12 a reading past its max age is stale with no value', () {
      // vehicleSpeed is high priority: max age floors at 2 s.
      final s = _snapshot(
        readings: {PidLibrary.vehicleSpeed: (80, const Duration(seconds: 7))},
      );
      final signal = _signal(s, PidLibrary.vehicleSpeed);
      expect(signal, CarSignal.stale);
      expect(signal.value, isNull);
    });

    test('AA02-13 only PidFault.unsupported becomes unsupported', () {
      final s = _snapshot(faults: {PidLibrary.engineRpm: PidFault.unsupported});
      expect(_signal(s, PidLibrary.engineRpm), CarSignal.unsupported);
    });

    test('unsupported wins over a retained reading', () {
      final s = _snapshot(
        readings: {PidLibrary.engineRpm: (900, fresh)},
        faults: {PidLibrary.engineRpm: PidFault.unsupported},
      );
      expect(_signal(s, PidLibrary.engineRpm), CarSignal.unsupported);
    });

    test('AA02-14 missing reading and every other fault are unavailable', () {
      expect(
        _signal(_snapshot(), PidLibrary.vehicleSpeed),
        CarSignal.unavailable,
      );
      for (final fault in PidFault.values.where(
        (f) => f != PidFault.unsupported,
      )) {
        final s = _snapshot(
          readings: {PidLibrary.vehicleSpeed: (50, fresh)},
          faults: {PidLibrary.vehicleSpeed: fault},
        );
        expect(
          _signal(s, PidLibrary.vehicleSpeed),
          CarSignal.unavailable,
          reason: '$fault',
        );
      }
    });

    test('no authoritative snapshot means every signal is unavailable', () {
      final p = _project(telemetry: null);
      expect(p.signals, everyElement(CarSignal.unavailable));
    });

    test('a session that is not connected never projects live', () {
      final s = _snapshot(readings: {PidLibrary.vehicleSpeed: (50, fresh)});
      for (final phase in ConnectionPhase.values.where(
        (p) => p != ConnectionPhase.connected,
      )) {
        expect(
          _signal(s, PidLibrary.vehicleSpeed, phase: phase),
          CarSignal.stale,
          reason: '$phase with a retained reading',
        );
        expect(
          _signal(_snapshot(), PidLibrary.vehicleSpeed, phase: phase),
          CarSignal.unavailable,
          reason: '$phase without a reading',
        );
      }
      // And an unsupported verdict from a link that is gone is not repeated.
      final unsupported = _snapshot(
        faults: {PidLibrary.vehicleSpeed: PidFault.unsupported},
      );
      expect(
        _signal(
          unsupported,
          PidLibrary.vehicleSpeed,
          phase: ConnectionPhase.disconnected,
        ),
        CarSignal.unavailable,
      );
    });

    test('a non-finite reading is unavailable, never live', () {
      for (final bad in [double.nan, double.infinity, double.negativeInfinity]) {
        final s = _snapshot(readings: {PidLibrary.vehicleSpeed: (bad, fresh)});
        expect(_signal(s, PidLibrary.vehicleSpeed), CarSignal.unavailable);
      }
    });

    test('AA02-15 non-live status never carries a number', () {
      final cases = <TelemetrySnapshot?>[
        null,
        _snapshot(),
        _snapshot(
          readings: {
            PidLibrary.vehicleSpeed: (80, const Duration(seconds: 1)),
            PidLibrary.engineRpm: (900, fresh),
            PidLibrary.coolantTemp: (90, fresh),
          },
          faults: {
            PidLibrary.engineRpm: PidFault.unsupported,
            PidLibrary.coolantTemp: PidFault.noAnswer,
          },
        ),
      ];
      for (final telemetry in cases) {
        for (final phase in ConnectionPhase.values) {
          final p = _project(telemetry: telemetry, phase: phase);
          for (final signal in p.signals) {
            expect(
              signal.value != null,
              signal.status == CarSignalStatus.live,
              reason: '$signal',
            );
          }
        }
      }
    });
  });

  group('diagnostics (AA02-16..17)', () {
    test('AA02-16 no scan: unavailable, null count, null MIL', () {
      final d = projectCarDiagnostics(const DtcScanState());
      expect(d.available, isFalse);
      expect(d.dtcCount, isNull);
      expect(d.milOn, isNull);
    });

    test('a scan still loading without results is still unavailable', () {
      final d = projectCarDiagnostics(const DtcScanState(loading: true));
      expect(d, CarDiagnosticsSummary.unavailable);
    });

    test('AA02-17 completed scan keeps exact totalCodes and nullable MIL', () {
      final stored = DtcDecoder.decodePair(0x03, 0x00, DtcKind.stored)!;
      final pending = DtcDecoder.decodePair(0x01, 0x71, DtcKind.pending)!;
      final scanned = DtcScanState(
        scannedAt: _t0,
        results: {
          DtcKind.stored: DtcCategoryResult.codes([stored]),
          DtcKind.pending: DtcCategoryResult.codes([pending]),
          DtcKind.permanent: const DtcCategoryResult.codes([]),
        },
      );
      final unknownMil = projectCarDiagnostics(scanned);
      expect(unknownMil.available, isTrue);
      expect(unknownMil.dtcCount, 2);
      expect(unknownMil.dtcCount, scanned.totalCodes);
      expect(unknownMil.milOn, isNull, reason: 'unread MIL must not be false');

      final milOff = projectCarDiagnostics(
        DtcScanState(
          scannedAt: _t0,
          mil: const MilStatus({
            '7E8': MilSummary(milOn: false, confirmedCount: 0),
          }),
        ),
      );
      expect(milOff.milOn, isFalse);
      expect(milOff.dtcCount, 0);

      final milOn = projectCarDiagnostics(
        DtcScanState(
          scannedAt: _t0,
          mil: const MilStatus({
            '7E8': MilSummary(milOn: true, confirmedCount: 1),
          }),
        ),
      );
      expect(milOn.milOn, isTrue);
    });
  });

  group('projection header', () {
    test('carries epochs, phase and producer time verbatim', () {
      final p = _project(phase: ConnectionPhase.handshaking);
      expect(p.connectionEpoch, 4);
      expect(p.lifecycleEpoch, 2);
      expect(p.producedAtMonotonicUs, 77);
      expect(p.connectionPhase, ConnectionPhase.handshaking);
    });

    test('edges: first, phase, epoch, diagnostics; not plain telemetry', () {
      final base = _project();
      expect(base.isEdgeFrom(null), isTrue);
      expect(_project().isEdgeFrom(base), isFalse);
      expect(
        _project(
          telemetry: _snapshot(readings: {PidLibrary.vehicleSpeed: (9, fresh)}),
        ).isEdgeFrom(base),
        isFalse,
      );
      expect(
        _project(phase: ConnectionPhase.disconnected).isEdgeFrom(base),
        isTrue,
      );
      expect(
        projectCarTelemetry(
          telemetry: null,
          connectionPhase: ConnectionPhase.connected,
          connectionEpoch: 5,
          lifecycleEpoch: 2,
          dtc: const DtcScanState(),
          monotonicUs: 1,
        ).isEdgeFrom(base),
        isTrue,
      );
      expect(
        _project(dtc: DtcScanState(scannedAt: _t0)).isEdgeFrom(base),
        isTrue,
      );
    });
  });
}
