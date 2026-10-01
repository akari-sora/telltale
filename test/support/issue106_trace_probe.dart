/// Support probe and causal attribution tracker for Issue #106 Slice 1.
///
/// Implements finite event-stream observation, distinguishing:
///   1. Injected fault (the test harness intent)
///   2. Observed events (real bytes/signals seen on wire/transport)
///   3. Product-reported issue (the TransportIssue/state exposed by Elm327Client)
///   4. Inferred attribution and observation gaps
///
/// Designed to satisfy R81-1 ~ R81-4 review requirements:
///   - Real stream controller error/done propagation
///   - Genuine productReportedIssue binding
///   - Bounded event capacity and distinct cleanup error tracking
///   - Managed async completion and timers
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';

enum TraceEventKind {
  socketConnecting,
  socketConnected,
  initStepStarted,
  initStepCompleted,
  injectedFaultFired,
  rawBytesReceived,
  rawBytesWritten,
  streamDoneObserved,
  streamErrorObserved,
  timeoutObserved,
  firstTerminalObserved,
  secondaryErrorObserved,
  cleanupStarted,
  cleanupCompleted,
}

class TraceRecord {
  final int sequence;
  final DateTime timestamp;
  final int elapsedMs;
  final TraceEventKind kind;
  final String component;
  final String phase;
  final String runId;
  final String attemptId;
  final int generation;
  final String operationId;
  final String? command;
  final Map<String, Object?> details;

  const TraceRecord({
    required this.sequence,
    required this.timestamp,
    required this.elapsedMs,
    required this.kind,
    required this.component,
    required this.phase,
    required this.runId,
    required this.attemptId,
    required this.generation,
    required this.operationId,
    this.command,
    required this.details,
  });

  @override
  String toString() =>
      '[$elapsedMs ms #$sequence] $kind ($component/$phase run=$runId att=$attemptId gen=$generation op=$operationId cmd=$command): $details';
}

/// Bounded in-memory recorder for causal trace events (R81-1 & R81-3).
class Issue106TraceProbe {
  Issue106TraceProbe({
    this.maxCapacity = 256,
    this.runId = 'RUN-UNSPECIFIED',
    this.attemptId = 'ATTEMPT-01',
    this.generation = 1,
    this.clock,
    this.elapsedMsProvider,
  });

  final int maxCapacity;
  String runId;
  String attemptId;
  int generation;
  final DateTime Function()? clock;
  final int Function()? elapsedMsProvider;

  final Stopwatch _stopwatch = Stopwatch()..start();
  final List<TraceRecord> _records = [];
  int _sequenceCounter = 0;

  bool isTruncated = false;
  String? injectedFault;
  String? firstTerminalCause;
  int? firstTerminalSequence;
  String? secondaryCleanupOutcome;
  Object? cleanupError;

  TransportIssue? productReportedIssue;
  String? failedStepCommand;
  InitNote? failedStepNote;
  Elm327ErrorCode? failedStepErrorCode;

  String? currentOperationId;
  bool _isFirstTerminalSealed = false;
  bool get isFirstTerminalSealed => _isFirstTerminalSealed;

  List<TraceRecord> get records => List.unmodifiable(_records);

  void record({
    required TraceEventKind kind,
    required String component,
    required String phase,
    String? runId,
    String? attemptId,
    int? generation,
    String? operationId,
    String? command,
    Map<String, Object?> details = const {},
  }) {
    final seq = ++_sequenceCounter;
    final now = clock?.call() ?? DateTime.now();
    final elapsed = elapsedMsProvider?.call() ?? _stopwatch.elapsedMilliseconds;
    final effRunId = runId ?? this.runId;
    final effAttemptId = attemptId ?? this.attemptId;
    final effGen = generation ?? (details['generation'] as int?) ?? this.generation;
    final effOpId = operationId ?? details['operationId']?.toString() ?? currentOperationId ?? 'unattributed';
    final effCmd = command ?? details['cmd']?.toString();

    if (_records.length < maxCapacity) {
      final rec = TraceRecord(
        sequence: seq,
        timestamp: now,
        elapsedMs: elapsed,
        kind: kind,
        component: component,
        phase: phase,
        runId: effRunId,
        attemptId: effAttemptId,
        generation: effGen,
        operationId: effOpId,
        command: effCmd,
        details: details,
      );
      _records.add(rec);
    } else {
      isTruncated = true;
    }

    if (kind == TraceEventKind.cleanupStarted) {
      currentOperationId = null;
    }

    // M106-01: First terminal event cannot be overwritten by subsequent cleanup events.
    if ((kind == TraceEventKind.streamDoneObserved ||
            kind == TraceEventKind.streamErrorObserved ||
            kind == TraceEventKind.timeoutObserved ||
            kind == TraceEventKind.firstTerminalObserved) &&
        !_isFirstTerminalSealed) {
      _isFirstTerminalSealed = true;
      firstTerminalCause = details['cause']?.toString() ?? kind.name;
      firstTerminalSequence = seq;
    } else if (_isFirstTerminalSealed) {
      // R81-1: Distinguish secondary errors from routine cleanup started/completed,
      // ensuring cleanupStarted does not permanently mask actual cleanup failures.
      if (kind == TraceEventKind.secondaryErrorObserved) {
        secondaryCleanupOutcome = details['outcome']?.toString() ?? kind.name;
      } else if (kind == TraceEventKind.cleanupStarted ||
          kind == TraceEventKind.cleanupCompleted) {
        secondaryCleanupOutcome ??= details['outcome']?.toString() ?? kind.name;
      }
    }
  }

  /// Observes actual production [InitProgress] stream emissions (R81-1).
  void observeInitProgress(
    InitProgress progress, {
    String? attemptId,
    int? generation,
  }) {
    final effAttemptId = attemptId ?? this.attemptId;
    final effGen = generation ?? this.generation;
    final cmdNorm = progress.step.command.toUpperCase().replaceAll(' ', '');
    final opId = 'op-$cmdNorm-${progress.index}';

    if (progress.status == InitStatus.running) {
      currentOperationId = opId;
      record(
        kind: TraceEventKind.initStepStarted,
        component: 'client',
        phase: 'handshake',
        command: progress.step.command,
        attemptId: effAttemptId,
        generation: effGen,
        operationId: opId,
        details: {
          'cmd': progress.step.command,
          'index': progress.index,
          'operationId': opId,
          'attemptId': effAttemptId,
          'generation': effGen,
        },
      );
    } else if (progress.status == InitStatus.failed) {
      failedStepCommand = progress.step.command;
      failedStepNote = progress.note;
      failedStepErrorCode = progress.errorCode;
      if (progress.transportIssue != null) {
        productReportedIssue = progress.transportIssue;
      }
      if (progress.note == InitNote.timedOut) {
        record(
          kind: TraceEventKind.timeoutObserved,
          component: 'client',
          phase: 'handshake',
          command: progress.step.command,
          attemptId: effAttemptId,
          generation: effGen,
          operationId: opId,
          details: {
            'cause': 'HandshakeTimeout',
            'cmd': progress.step.command,
            'index': progress.index,
            'operationId': opId,
            'attemptId': effAttemptId,
            'generation': effGen,
          },
        );
      }
      record(
        kind: TraceEventKind.initStepCompleted,
        component: 'client',
        phase: 'handshake',
        command: progress.step.command,
        attemptId: effAttemptId,
        generation: effGen,
        operationId: opId,
        details: {
          'cmd': progress.step.command,
          'status': 'failed',
          'note': progress.note?.name,
          'errorCode': progress.errorCode?.name,
          'transportIssue': progress.transportIssue?.name,
          'operationId': opId,
          'attemptId': effAttemptId,
          'generation': effGen,
        },
      );
      currentOperationId = null;
    } else {
      record(
        kind: TraceEventKind.initStepCompleted,
        component: 'client',
        phase: 'handshake',
        command: progress.step.command,
        attemptId: effAttemptId,
        generation: effGen,
        operationId: opId,
        details: {
          'cmd': progress.step.command,
          'status': progress.status.name,
          'operationId': opId,
          'attemptId': effAttemptId,
          'generation': effGen,
        },
      );
      currentOperationId = null;
    }
  }

  /// Records typed [TransportException] from product layer.
  void recordTransportException(TransportException e) {
    productReportedIssue = e.issue;
  }

  /// Explicitly records isolated cleanup error without polluting secondary outcome.
  void recordCleanupError(Object err) {
    cleanupError = err;
    record(
      kind: TraceEventKind.secondaryErrorObserved,
      component: 'cleanup',
      phase: 'teardown',
      details: {'outcome': err.toString()},
    );
  }

  /// Verifies that the first terminal cause was NOT replaced by cleanup.
  bool verifyFirstTerminalIntact(String expectedFirstCause) {
    return firstTerminalCause == expectedFirstCause;
  }
}

/// Binds session state initSteps stream changes to the trace probe (R81-1 & R81-2).
ProviderSubscription<ObdConnectionState> bindSessionToProbe(
  ProviderContainer container,
  Issue106TraceProbe probe, {
  String? attemptId,
  int? generation,
}) {
  final seenSteps = <int, InitStatus>{};
  return container.listen<ObdConnectionState>(
    obdSessionProvider,
    (previous, current) {
      if (generation != null) {
        final currentGen = container.read(obdSessionProvider.notifier).generation;
        if (currentGen != generation) {
          return;
        }
      }
      for (final step in current.initSteps) {
        final lastStatus = seenSteps[step.index];
        if (lastStatus != step.status) {
          seenSteps[step.index] = step.status;
          probe.observeInitProgress(
            step,
            attemptId: attemptId,
            generation: generation,
          );
        }
      }
    },
    fireImmediately: true,
  );
}

/// Scripted Transport specifically instrumented for Issue #106 Causal Triage.
///
/// Features:
/// - Real socket input stream error/done callback wiring (R81-1)
/// - Managed async operations, chunk immutability, and cancellable timers (R81-3)
/// - Authentic Mode 01 PID 0D (speed) numerical literal payload (R81-2)
/// - Rejection of unknown commands with '?' instead of blanket 'OK' (R81-2)
class ScriptedCausalTransport extends BaseObdTransport {
  ScriptedCausalTransport({
    required this.name,
    this.probe,
    this.initialVoltage = '13.9V',
    this.initialGeneration = 0,
    String? attemptId,
  })  : connectionGeneration = initialGeneration,
        boundAttemptId = attemptId ??
            'ATTEMPT-${(initialGeneration == 0 ? 1 : initialGeneration).toString().padLeft(2, '0')}';

  final String name;
  final Issue106TraceProbe? probe;
  final String initialVoltage;
  final int initialGeneration;
  final String boundAttemptId;

  StreamController<List<int>>? _socketController;
  StreamSubscription<List<int>>? _socketSub;

  final List<Timer> _activeTimers = [];
  final List<Future<void>> _activeAsyncOps = [];
  final List<void Function()> _activeChunkCancellers = [];
  bool _aborted = false;

  int get activeTimersCount => _activeTimers.length;
  int get activeAsyncOpsCount => _activeAsyncOps.length;

  final List<String> writtenCommands = [];
  bool isDisposed = false;
  int connectionGeneration;
  String? _activeWriteOpId;
  int _opCounter = 0;

  FutureOr<void> Function(String cmd, ScriptedCausalTransport transport)? onCommandHook;

  @override
  TransportKind get kind => TransportKind.bluetoothClassic;

  @override
  String get displayName => 'ScriptedCausalTransport ($name)';

  @override
  Future<void> connect() async {
    _aborted = false;
    connectionGeneration++;
    if (probe != null) {
      probe!.generation = connectionGeneration;
      probe!.attemptId = boundAttemptId;
    }
    probe?.record(
      kind: TraceEventKind.socketConnecting,
      component: 'transport',
      phase: 'connect',
      generation: connectionGeneration,
      attemptId: boundAttemptId,
      details: {'generation': connectionGeneration, 'attemptId': boundAttemptId},
    );

    _socketController = StreamController<List<int>>();

    // R81-1: Mirror ClassicTransport wiring:
    // Listen to the underlying stream and propagate data to emitBytes,
    // onError to setConnected(false), onDone to setConnected(false).
    _socketSub = _socketController!.stream.listen(
      (bytes) {
        final opId = probe?.currentOperationId ?? _activeWriteOpId ?? 'unattributed';
        probe?.record(
          kind: TraceEventKind.rawBytesReceived,
          component: 'transport',
          phase: 'rx',
          generation: connectionGeneration,
          attemptId: boundAttemptId,
          operationId: opId,
          details: {
            'length': bytes.length,
            'generation': connectionGeneration,
            'attemptId': boundAttemptId,
            'operationId': opId,
          },
        );
        emitBytes(bytes);
      },
      onError: (Object error) {
        probe?.record(
          kind: TraceEventKind.streamErrorObserved,
          component: 'transport',
          phase: 'rx',
          generation: connectionGeneration,
          attemptId: boundAttemptId,
          details: {
            'cause': 'StreamError',
            'error': error.toString(),
            'generation': connectionGeneration,
            'attemptId': boundAttemptId,
          },
        );
        setConnected(false);
      },
      onDone: () {
        probe?.record(
          kind: TraceEventKind.streamDoneObserved,
          component: 'transport',
          phase: 'rx',
          generation: connectionGeneration,
          attemptId: boundAttemptId,
          details: {
            'cause': 'StreamDone',
            'generation': connectionGeneration,
            'attemptId': boundAttemptId,
          },
        );
        setConnected(false);
      },
      cancelOnError: false,
    );

    setConnected(true);
    probe?.record(
      kind: TraceEventKind.socketConnected,
      component: 'transport',
      phase: 'connect',
      generation: connectionGeneration,
      attemptId: boundAttemptId,
      details: {'connected': true, 'generation': connectionGeneration, 'attemptId': boundAttemptId},
    );
  }

  @override
  Future<void> disconnect() async {
    if (!isConnected && _socketController == null) {
      return;
    }
    _aborted = true;
    _activeWriteOpId = null;
    probe?.record(
      kind: TraceEventKind.cleanupStarted,
      component: 'transport',
      phase: 'disconnect',
      generation: connectionGeneration,
      attemptId: boundAttemptId,
      details: {'generation': connectionGeneration, 'attemptId': boundAttemptId},
    );
    setConnected(false);

    for (final cancel in List<void Function()>.from(_activeChunkCancellers)) {
      cancel();
    }
    _activeChunkCancellers.clear();

    // R81-3: Managed timer cancellation (cancels interval timers as well)
    for (final timer in List<Timer>.from(_activeTimers)) {
      timer.cancel();
    }
    _activeTimers.clear();

    // R81-3: Join running async chunk operations and capture any errors
    if (_activeAsyncOps.isNotEmpty) {
      try {
        await Future.wait(List<Future<void>>.from(_activeAsyncOps));
      } catch (err) {
        probe?.record(
          kind: TraceEventKind.secondaryErrorObserved,
          component: 'transport',
          phase: 'join',
          generation: connectionGeneration,
          attemptId: boundAttemptId,
          details: {
            'outcome': 'JoinError',
            'error': err.toString(),
            'generation': connectionGeneration,
            'attemptId': boundAttemptId,
          },
        );
      }
    }
    _activeAsyncOps.clear();

    if (_socketController != null && !_socketController!.isClosed) {
      unawaited(_socketController!.close());
    }
    await _socketSub?.cancel();
    _socketSub = null;
    _socketController = null;

    probe?.record(
      kind: TraceEventKind.cleanupCompleted,
      component: 'transport',
      phase: 'disconnect',
      generation: connectionGeneration,
      attemptId: boundAttemptId,
      details: {'generation': connectionGeneration, 'attemptId': boundAttemptId},
    );
  }

  /// Synchronous cleanup of transport resources, safe for FakeAsync environments.
  void disposeSync() {
    if (isDisposed) return;
    isDisposed = true;
    _aborted = true;
    _activeWriteOpId = null;
    setConnected(false);
    for (final cancel in List<void Function()>.from(_activeChunkCancellers)) {
      cancel();
    }
    _activeChunkCancellers.clear();
    for (final timer in List<Timer>.from(_activeTimers)) {
      timer.cancel();
    }
    _activeTimers.clear();
    _activeAsyncOps.clear();
    _socketSub?.cancel();
    _socketSub = null;
    _socketController?.close();
    _socketController = null;
  }

  /// Permanent teardown of transport stream controllers.
  Future<void> dispose() async {
    disposeSync();
  }

  @override
  Future<void> write(List<int> bytes) async {
    final cmd = String.fromCharCodes(bytes).trim();
    writtenCommands.add(cmd);
    final opId = probe?.currentOperationId ??
        'op-${cmd.toUpperCase().replaceAll(' ', '')}-${++_opCounter}';
    _activeWriteOpId = opId;

    probe?.record(
      kind: TraceEventKind.rawBytesWritten,
      component: 'transport',
      phase: 'write',
      command: cmd,
      generation: connectionGeneration,
      attemptId: boundAttemptId,
      operationId: opId,
      details: {
        'cmd': cmd,
        'bytes': bytes,
        'generation': connectionGeneration,
        'attemptId': boundAttemptId,
        'operationId': opId,
      },
    );

    if (onCommandHook != null) {
      await onCommandHook!(cmd, this);
      return;
    }

    defaultAnswer(cmd);
  }

  /// Provides authentic ELM327 replies (R81-2).
  /// Rejects unknown commands with '?' instead of blanket 'OK'.
  void defaultAnswer(String cmd) {
    final normalized = cmd.toUpperCase().replaceAll(' ', '');
    if (normalized.startsWith('ATDPN')) {
      sendReply('A6\r\n>');
    } else if (normalized.startsWith('ATDP')) {
      sendReply('ISO 15765-4 (CAN 11/500)\r\n>');
    } else if (normalized.startsWith('ATRV')) {
      sendReply('$initialVoltage\r\n>');
    } else if (normalized.startsWith('ATI')) {
      sendReply('ELM327 v1.5\r\n>');
    } else if (normalized.startsWith('AT@1')) {
      sendReply('OBDII to RS232 Interpreter\r\n>');
    } else if (normalized.startsWith('ATZ') ||
        normalized.startsWith('ATE') ||
        normalized.startsWith('ATL') ||
        normalized.startsWith('ATM') ||
        normalized.startsWith('ATS') ||
        normalized.startsWith('ATAT') ||
        normalized.startsWith('ATST') ||
        normalized.startsWith('ATSP') ||
        normalized.startsWith('ATSH') ||
        normalized.startsWith('ATH') ||
        normalized.startsWith('ATCRA') ||
        normalized.startsWith('ATCAF') ||
        normalized.startsWith('ATD')) {
      sendReply('OK\r\n>');
    } else if (normalized.startsWith('0100')) {
      sendReply('41 00 BE 1F B8 10\r\n>');
    } else if (normalized.startsWith('010D')) {
      // R81-2: 0x32 = 50 km/h vehicle speed literal payload
      sendReply('41 0D 32\r\n>');
    } else if (normalized.startsWith('010C')) {
      sendReply('41 0C 1A F8\r\n>');
    } else if (normalized.startsWith('0120') ||
        normalized.startsWith('0140') ||
        normalized.startsWith('0160')) {
      sendReply('41 ${normalized.substring(2, 4)} 00 00 00 00\r\n>');
    } else {
      // R81-2: Unknown commands are rejected with '?' rather than blanket 'OK'
      sendReply('?\r\n>');
    }
  }

  void sendReply(String text, {int? forGeneration}) {
    final gen = forGeneration ?? connectionGeneration;
    final attId = (forGeneration != null && forGeneration != connectionGeneration)
        ? 'ATTEMPT-${gen.toString().padLeft(2, '0')}'
        : boundAttemptId;
    if (forGeneration != null && forGeneration != connectionGeneration) {
      probe?.record(
        kind: TraceEventKind.secondaryErrorObserved,
        component: 'transport',
        phase: 'fencing',
        generation: forGeneration,
        attemptId: attId,
        operationId: 'unattributed',
        details: {
          'outcome': 'StaleGenerationDiscarded',
          'staleGeneration': forGeneration,
          'currentGeneration': connectionGeneration,
          'generation': forGeneration,
          'attemptId': attId,
          'operationId': 'unattributed',
        },
      );
      return;
    }
    if (_aborted || isDisposed || _socketController == null || _socketController!.isClosed) {
      if (_aborted) {
        probe?.record(
          kind: TraceEventKind.secondaryErrorObserved,
          component: 'transport',
          phase: 'fencing',
          generation: gen,
          attemptId: attId,
          operationId: 'unattributed',
          details: {
            'outcome': 'StaleGenerationDiscarded',
            'reason': 'TransportAborted',
            'generation': gen,
            'attemptId': attId,
            'operationId': 'unattributed',
          },
        );
      }
      return;
    }
    _socketController!.add(text.codeUnits);
  }

  /// Sends reply across multiple chunks with an awaitable Future (R81-3).
  Future<void> sendChunks(
    List<String> chunks, {
    Duration interval = const Duration(milliseconds: 10),
  }) {
    final targetController = _socketController;
    final targetGen = connectionGeneration;
    final targetAttempt = boundAttemptId;
    if (targetController == null || targetController.isClosed || isDisposed || _aborted) {
      return Future<void>.value();
    }

    final completer = Completer<void>();
    completer.future.catchError((_) {});
    _activeAsyncOps.add(completer.future);

    Timer? intervalTimer;
    Completer<void>? stepCompleter;
    void cancelInterval() {
      if (intervalTimer != null) {
        intervalTimer!.cancel();
        _activeTimers.remove(intervalTimer);
        intervalTimer = null;
      }
      if (stepCompleter != null && !stepCompleter!.isCompleted) {
        stepCompleter!.complete();
      }
    }
    _activeChunkCancellers.add(cancelInterval);

    Future<void> run() async {
      try {
        for (final c in chunks) {
          if (isDisposed ||
              _aborted ||
              targetController.isClosed ||
              targetGen != connectionGeneration) {
            break;
          }
          targetController.add(c.codeUnits);
          if (interval > Duration.zero) {
            stepCompleter = Completer<void>();
            intervalTimer = Timer(interval, () {
              _activeTimers.remove(intervalTimer);
              intervalTimer = null;
              if (stepCompleter != null && !stepCompleter!.isCompleted) {
                stepCompleter!.complete();
              }
            });
            _activeTimers.add(intervalTimer!);
            await stepCompleter!.future;
            stepCompleter = null;
          }
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      } catch (e, st) {
        cancelInterval();
        probe?.record(
          kind: TraceEventKind.secondaryErrorObserved,
          component: 'transport',
          phase: 'chunks',
          generation: targetGen,
          attemptId: targetAttempt,
          details: {
            'outcome': 'ChunkError',
            'error': e.toString(),
            'generation': targetGen,
            'attemptId': targetAttempt,
          },
        );
        if (!completer.isCompleted) {
          completer.completeError(e, st);
        }
      } finally {
        cancelInterval();
        _activeChunkCancellers.remove(cancelInterval);
        _activeAsyncOps.remove(completer.future);
      }
    }

    run();
    return completer.future;
  }

  /// Managed delayed execution that cleans up automatically on disconnect (R81-3).
  Timer scheduleDelayed(Duration delay, void Function() action) {
    late Timer timer;
    timer = Timer(delay, () {
      _activeTimers.remove(timer);
      if (!isDisposed && !_aborted) {
        action();
      }
    });
    _activeTimers.add(timer);
    return timer;
  }

  /// Triggers a remote stream EOF (onDone) via the stream controller (R81-1).
  void injectRemoteDone() {
    probe?.record(
      kind: TraceEventKind.injectedFaultFired,
      component: 'transport',
      phase: 'inject',
      generation: connectionGeneration,
      attemptId: boundAttemptId,
      details: {
        'type': 'stream_done',
        'generation': connectionGeneration,
        'attemptId': boundAttemptId,
      },
    );
    if (_socketController != null && !_socketController!.isClosed) {
      _socketController!.close();
    }
  }

  /// Triggers a remote socket reset error (onError) via the stream controller (R81-1).
  void injectRemoteError(Object error) {
    probe?.record(
      kind: TraceEventKind.injectedFaultFired,
      component: 'transport',
      phase: 'inject',
      generation: connectionGeneration,
      attemptId: boundAttemptId,
      details: {
        'type': 'stream_error',
        'error': error.toString(),
        'generation': connectionGeneration,
        'attemptId': boundAttemptId,
      },
    );
    if (_socketController != null && !_socketController!.isClosed) {
      _socketController!.addError(error);
    }
  }
}
