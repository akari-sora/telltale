import 'dart:async';

import 'diagnostic_link.dart';

/// Authority that coordinates half-duplex access to the diagnostic link
/// within a single connection lifecycle.
///
/// Serializes one-shot diagnostic actions (such as responder census and
/// experimental BMS probes) with exclusive link ownership, pausing active
/// polling beforehand and conditionally restoring it upon completion.
abstract interface class DiagnosticLinkOwnershipAuthority {
  /// Creates a connection-scoped ownership authority.
  factory DiagnosticLinkOwnershipAuthority({
    required bool Function() pollingIsRunning,
    required Future<void> Function() pausePolling,
    required void Function() resumePolling,
    required bool Function() canRestorePolling,
    void Function()? onDisplacedPollingRestored,
  }) = _DiagnosticLinkOwnershipAuthority;

  /// Executes [action] with exclusive half-duplex access to the diagnostic link.
  ///
  /// If polling is running when this action is admitted, polling is paused via
  /// [pausePolling] and verified stopped before [action] begins. Once [action]
  /// completes (either with success or error), polling is restored via
  /// [resumePolling] if and only if [canRestorePolling] returns `true` and polling
  /// was originally displaced by this takeover.
  ///
  /// Concurrent one-shots are strictly serialized in FIFO order with max active = 1.
  /// An error thrown by one action does not poison subsequent queued actions.
  Future<T> runOneShot<T>({
    required String operationName,
    required Future<T> Function() action,
    DiagnosticCancellation? cancellation,
    DateTime? deadline,
  });

  /// Executes [action] with exclusive half-duplex access to the diagnostic link.
  ///
  /// Serialized in the same FIFO queue as [runOneShot] (max active = 1).
  /// Holds link ownership until the returned Future completes, keeping polling
  /// paused throughout multi-step transactional sequences.
  Future<T> runExclusive<T>({
    required String operationName,
    required Future<T> Function() action,
    DiagnosticCancellation? cancellation,
    DateTime? deadline,
  });

  /// Releases resources, revokes pending actions, and prevents future takeovers.
  void dispose();

  /// Whether an admitted takeover has currently displaced running polling.
  bool get hasDisplacedPolling;

  /// Current number of actively running takeover actions (at most 1).
  int get activeTakeovers;

  /// Active diagnostic ownership mode if an action is currently running, or null.
  DiagnosticOwnershipMode? get activeMode;

  /// Number of takeover actions currently waiting in the FIFO queue.
  int get queuedCount;

  /// Callback invoked whenever displaced polling is successfully restored.
  void Function()? get onDisplacedPollingRestored;
  set onDisplacedPollingRestored(void Function()? callback);

  /// Total count of successfully completed displaced polling restorations.
  int get displacedRestorationCount;
}

class _DiagnosticLinkOwnershipAuthority
    implements DiagnosticLinkOwnershipAuthority {
  final bool Function() pollingIsRunning;
  final Future<void> Function() pausePolling;
  final void Function() resumePolling;
  final bool Function() canRestorePolling;
  @override
  void Function()? onDisplacedPollingRestored;

  Future<void> _tail = Future<void>.value();
  bool _disposed = false;
  bool _hasDisplacedPolling = false;
  int _activeTakeovers = 0;
  DiagnosticOwnershipMode? _activeMode;
  int _queuedCount = 0;
  int _displacedRestorationCount = 0;

  _DiagnosticLinkOwnershipAuthority({
    required this.pollingIsRunning,
    required this.pausePolling,
    required this.resumePolling,
    required this.canRestorePolling,
    this.onDisplacedPollingRestored,
  });

  @override
  bool get hasDisplacedPolling => _hasDisplacedPolling;

  @override
  int get activeTakeovers => _activeTakeovers;

  @override
  DiagnosticOwnershipMode? get activeMode => _activeMode;

  @override
  int get queuedCount => _queuedCount;

  @override
  int get displacedRestorationCount => _displacedRestorationCount;

  @override
  void dispose() {
    _disposed = true;
  }

  @override
  Future<T> runOneShot<T>({
    required String operationName,
    required Future<T> Function() action,
    DiagnosticCancellation? cancellation,
    DateTime? deadline,
  }) =>
      _runTakeover<T>(
        mode: DiagnosticOwnershipMode.oneShot,
        operationName: operationName,
        action: action,
        cancellation: cancellation,
        deadline: deadline,
      );

  @override
  Future<T> runExclusive<T>({
    required String operationName,
    required Future<T> Function() action,
    DiagnosticCancellation? cancellation,
    DateTime? deadline,
  }) =>
      _runTakeover<T>(
        mode: DiagnosticOwnershipMode.exclusive,
        operationName: operationName,
        action: action,
        cancellation: cancellation,
        deadline: deadline,
      );

  Future<T> _runTakeover<T>({
    required DiagnosticOwnershipMode mode,
    required String operationName,
    required Future<T> Function() action,
    DiagnosticCancellation? cancellation,
    DateTime? deadline,
  }) {
    if (_disposed) {
      return Future<T>.error(
        const DiagnosticLinkException(
          kind: DiagnosticFailureKind.retiredOperation,
          message: 'DiagnosticLinkOwnershipAuthority is disposed.',
        ),
      );
    }
    if (cancellation?.isCancelled ?? false) {
      return Future<T>.error(
        const DiagnosticLinkException(
          kind: DiagnosticFailureKind.cancelled,
          message:
              'Diagnostic takeover request was cancelled before admission.',
        ),
      );
    }
    if (deadline != null && !deadline.isAfter(DateTime.now())) {
      return Future<T>.error(
        const DiagnosticLinkException(
          kind: DiagnosticFailureKind.deadlineExpired,
          message: 'Diagnostic takeover deadline expired before admission.',
        ),
      );
    }

    final completer = Completer<T>();
    final previousTail = _tail;
    final nextTailCompleter = Completer<void>();
    _tail = nextTailCompleter.future;

    _queuedCount++;

    void run() async {
      try {
        await previousTail;
      } catch (_) {
        // A failed previous action must never poison subsequent queued actions.
      } finally {
        _queuedCount--;
      }

      if (_disposed) {
        completer.completeError(
          const DiagnosticLinkException(
            kind: DiagnosticFailureKind.retiredOperation,
            message:
                'DiagnosticLinkOwnershipAuthority was disposed while waiting in queue.',
          ),
        );
        nextTailCompleter.complete();
        return;
      }

      if (cancellation?.isCancelled ?? false) {
        completer.completeError(
          const DiagnosticLinkException(
            kind: DiagnosticFailureKind.cancelled,
            message:
                'Diagnostic takeover was cancelled while waiting in queue.',
          ),
        );
        nextTailCompleter.complete();
        return;
      }

      if (deadline != null && !deadline.isAfter(DateTime.now())) {
        completer.completeError(
          const DiagnosticLinkException(
            kind: DiagnosticFailureKind.deadlineExpired,
            message:
                'Diagnostic takeover deadline expired while waiting in queue.',
          ),
        );
        nextTailCompleter.complete();
        return;
      }

      _activeTakeovers++;
      _activeMode = mode;
      bool displaced = false;
      try {
        displaced = pollingIsRunning();
        if (displaced) {
          _hasDisplacedPolling = true;
          await pausePolling();
          if (pollingIsRunning()) {
            throw const DiagnosticLinkException(
              kind: DiagnosticFailureKind.transportFailure,
              message: 'Polling could not be paused for diagnostic takeover.',
            );
          }
        }

        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _hasDisplacedPolling = false;
        try {
          if (displaced &&
              !pollingIsRunning() &&
              !_disposed &&
              canRestorePolling()) {
            resumePolling();
            _displacedRestorationCount++;
            onDisplacedPollingRestored?.call();
          }
        } catch (_) {
          // Restoration failure should not mask the original action error.
        } finally {
          _activeTakeovers--;
          _activeMode = null;
          nextTailCompleter.complete();
        }
      }
    }

    run();
    return completer.future;
  }
}
