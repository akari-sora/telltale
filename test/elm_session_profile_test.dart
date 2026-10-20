/// Session-profile batch caps for #110. Offline; not vehicle validation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm_session_profile.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/pid/priority_scheduler.dart';

void main() {
  group('ElmSessionProfile.batchSizeCap', () {
    test('genuine and single-ECU clones keep the six-PID ceiling', () {
      expect(
        ElmSessionProfile.batchSizeCap(
          cloneSelfInconsistent: false,
          multiEcuFunctional: false,
          promptlessCompletes: 0,
        ),
        PriorityScheduler.maxBatchSize,
      );
      expect(
        ElmSessionProfile.batchSizeCap(
          cloneSelfInconsistent: true,
          multiEcuFunctional: false,
          promptlessCompletes: 0,
        ),
        6,
      );
    });

    test('a clone on functional multi-ECU addressing starts at three', () {
      expect(
        ElmSessionProfile.batchSizeCap(
          cloneSelfInconsistent: true,
          multiEcuFunctional: true,
          promptlessCompletes: 0,
        ),
        3,
      );
    });

    test('promptless completes demote 6→3→1 and stay at 1', () {
      expect(
        ElmSessionProfile.batchSizeCap(
          cloneSelfInconsistent: false,
          multiEcuFunctional: false,
          promptlessCompletes: 1,
        ),
        3,
      );
      expect(
        ElmSessionProfile.batchSizeCap(
          cloneSelfInconsistent: true,
          multiEcuFunctional: true,
          promptlessCompletes: 1,
        ),
        1,
      );
      expect(
        ElmSessionProfile.batchSizeCap(
          cloneSelfInconsistent: true,
          multiEcuFunctional: true,
          promptlessCompletes: 2,
        ),
        1,
      );
    });
  });

  test('popBatch honours the live cap without turning fast mode off', () {
    final scheduler = PriorityScheduler()
      ..canBatch = true
      ..batchSizeCap = 3;
    for (final pid in [
      PidLibrary.engineRpm,
      PidLibrary.vehicleSpeed,
      PidLibrary.engineLoad,
      PidLibrary.throttlePosition,
      PidLibrary.manifoldPressure,
      PidLibrary.mafRate,
    ]) {
      scheduler.enqueue(pid, pid.priority);
    }
    expect(scheduler.popBatch(), hasLength(3));
    expect(scheduler.fastModeEnabled, isTrue);
    scheduler.demoteAfterPromptlessComplete();
    expect(scheduler.batchSizeCap, 1);
  });
}
