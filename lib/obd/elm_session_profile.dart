/// Live ELM session policy: batch size, quiet-complete, clone vs genuine.
///
/// Identity concerns are a capability hint, not a reading-fidelity claim.
/// See `docs/architecture/elm-session-pipeline.md`.
library;

import 'pid/priority_scheduler.dart';

/// Timing and batch-size policy for one connected ELM session.
abstract final class ElmSessionProfile {
  /// How long an OBD buffer may sit without new bytes or a `>` before the
  /// client will complete it, if the parser already has a conclusive reply.
  static const Duration quietCompleteTimeout = Duration(milliseconds: 100);

  /// Pause after a promptless complete so a late empty `>` is discarded
  /// instead of closing the next command.
  static const Duration promptlessWriteHold = Duration(milliseconds: 120);

  /// Adaptive Mode 01 batch size for this session.
  ///
  /// [PriorityScheduler.maxBatchSize] is the hardware ceiling (6). This is
  /// the live cap. A self-inconsistent clone on functional multi-ECU
  /// addressing starts at 3; each promptless complete demotes 6→3→1.
  static int batchSizeCap({
    required bool cloneSelfInconsistent,
    required bool multiEcuFunctional,
    required int promptlessCompletes,
  }) {
    var cap = PriorityScheduler.maxBatchSize;
    if (cloneSelfInconsistent && multiEcuFunctional) {
      cap = 3;
    }
    final demotions = promptlessCompletes < 0 ? 0 : promptlessCompletes;
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
