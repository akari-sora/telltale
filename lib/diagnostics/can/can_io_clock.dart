/// Clock abstraction for monotonic deadline and elapsed time evaluation.
abstract class CanIoClock {
  const CanIoClock();

  /// Returns current monotonic/wall time (guaranteed never to rewind).
  DateTime now();

  /// Elapsed duration since clock epoch or initialization.
  Duration get elapsed;

  /// Default system clock implementation backed by a monotonic stopwatch.
  factory CanIoClock.system() = _SystemCanIoClock;

  /// Calculates the effective remaining duration until [deadline], or null if no deadline.
  ///
  /// If the current time is greater than or equal to [deadline], returns [Duration.zero].
  Duration? remaining(DateTime? deadline) {
    if (deadline == null) return null;
    final current = now();
    if (current.isAfter(deadline) || current.isAtSameMomentAs(deadline)) {
      return Duration.zero;
    }
    return deadline.difference(current);
  }

  /// Returns `true` if [deadline] is non-null and [now] is at or after [deadline].
  bool isExpired(DateTime? deadline) {
    if (deadline == null) return false;
    final current = now();
    return current.isAfter(deadline) || current.isAtSameMomentAs(deadline);
  }

  /// Computes the tightest deadline among the given non-null deadlines.
  static DateTime? minDeadline(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  /// Computes the effective remaining duration constrained by phase, total, and outer budgets.
  ///
  /// Effective remaining = min(phase remaining, total remaining, outer remaining).
  Duration effectiveRemaining({
    required Duration phaseBudget,
    required DateTime? totalDeadline,
    required DateTime? outerDeadline,
  }) {
    var effective = phaseBudget;
    final totalRem = remaining(totalDeadline);
    if (totalRem != null && totalRem < effective) {
      effective = totalRem;
    }
    final outerRem = remaining(outerDeadline);
    if (outerRem != null && outerRem < effective) {
      effective = outerRem;
    }
    return effective < Duration.zero ? Duration.zero : effective;
  }
}

class _SystemCanIoClock extends CanIoClock {
  final Stopwatch _stopwatch;
  final DateTime _startUtc;

  _SystemCanIoClock({Stopwatch? stopwatch, DateTime? startUtc})
      : _stopwatch = (stopwatch ?? Stopwatch())..start(),
        _startUtc = (startUtc ?? DateTime.now().toUtc());

  @override
  Duration get elapsed => _stopwatch.elapsed;

  @override
  DateTime now() => _startUtc.add(_stopwatch.elapsed);
}

/// Fake monotonic clock for deterministic unit and boundary testing.
class FakeCanIoClock extends CanIoClock {
  final DateTime _startUtc;
  Duration _elapsed = Duration.zero;

  FakeCanIoClock([DateTime? initial])
      : _startUtc = initial ?? DateTime.utc(2026, 9, 26, 0, 0, 0);

  @override
  Duration get elapsed => _elapsed;

  @override
  DateTime now() => _startUtc.add(_elapsed);

  void advance(Duration duration) {
    if (duration < Duration.zero) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Cannot rewind monotonic clock.',
      );
    }
    _elapsed += duration;
  }

  void setTime(DateTime time) {
    if (time.isBefore(now())) {
      throw ArgumentError.value(
        time,
        'time',
        'Cannot set clock backwards in monotonic mode.',
      );
    }
    _elapsed = time.difference(_startUtc);
  }
}
