/// Live ELM session policy: batch size, quiet-complete, clone vs genuine.
///
/// Identity concerns are a capability hint, not a reading-fidelity claim.
/// See `docs/architecture/elm-session-pipeline.md`.
library;

import 'pid/priority_scheduler.dart';

/// Timing and batch-size policy for one connected ELM session.
abstract final class ElmSessionProfile {
  /// Adapter response window after the last bus frame.
  ///
  /// `ATST66` is 0x66 × 4 ms = 408 ms. The #110 log shows data then `>`
  /// ~412–423 ms later on healthy replies (3192→3615, 3750→4169,
  /// 1673→2085). Completing inside this window and writing again aborts
  /// the adapter with `STOPPED`.
  static const Duration adapterResponseWindow = Duration(milliseconds: 450);

  /// Idle time before a promptless OBD buffer may complete, used only after
  /// this session has already seen a missing prompt. Longer than
  /// [adapterResponseWindow] so a healthy late `>` still wins.
  static const Duration quietCompleteTimeout = Duration(milliseconds: 550);

  /// Cap on how long a promptless complete holds the next write waiting for
  /// a late `>`. The live wait is the remainder of [adapterResponseWindow]
  /// after the last received byte; this is that window's length.
  static const Duration promptlessWriteHold = adapterResponseWindow;

  /// Consecutive prompted OBD replies that forgive one promptless demotion.
  ///
  /// At batched rates this is roughly one to two seconds of healthy traffic;
  /// at single-PID rates it is a few seconds. A missing prompt is an event,
  /// not a property of the session (#114): Wade's log shows one promptless
  /// reply at 13.9 s followed by 28 s of replies that all closed on `>`.
  static const int promptlessRecoveryStreak = 12;

  /// Adaptive Mode 01 batch size for this session.
  ///
  /// [PriorityScheduler.maxBatchSize] is the hardware ceiling (6). This is
  /// the live cap. A self-inconsistent clone on functional multi-ECU
  /// addressing starts at 3; each unit of live [promptlessPenalty] demotes
  /// 6→3→1. The penalty decays on prompted replies (see
  /// [promptlessRecoveryStreak]), so the cap climbs back.
  static int batchSizeCap({
    required bool cloneSelfInconsistent,
    required bool multiEcuFunctional,
    required int promptlessPenalty,
  }) {
    var cap = PriorityScheduler.maxBatchSize;
    if (cloneSelfInconsistent && multiEcuFunctional) {
      cap = 3;
    }
    final demotions = promptlessPenalty < 0 ? 0 : promptlessPenalty;
    for (var i = 0; i < demotions; i++) {
      cap = cap <= 3 ? 1 : 3;
    }
    if (cap < 1) return 1;
    if (cap > PriorityScheduler.maxBatchSize) {
      return PriorityScheduler.maxBatchSize;
    }
    return cap;
  }
}
