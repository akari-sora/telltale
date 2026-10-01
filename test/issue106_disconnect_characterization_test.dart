/// Issue #106 Slice 1: Connection & Disconnect Causal Characterization Test Suite.
///
/// Implements finite causal triage across four major scenarios and their required
/// sub-cases defined in `test/fixtures/issue106/connection_cases.json`:
///
///   - CASE-01-TRANSPORT-EOF:
///       * CASE-01-A-REMOTE-EOF (stream onDone)
///       * CASE-01-B-SOCKET-RESET (stream onError)
///       * CASE-01-C-CALLER-CANCEL (active caller disconnect with awaited cancellation)
///   - CASE-02-HANDSHAKE-TIMEOUT:
///       * CASE-02-A-CRITICAL-AT-TIMEOUT (unresponsive critical ATSP0 command with step-handoff deadline)
///       * CASE-02-B-NON-CRITICAL-AT-FAIL (non-critical probe returns '?')
///   - CASE-03-SLOW-RESPONSE:
///       * CASE-03-A-BEFORE-DEADLINE (0100 within 4s budget)
///       * CASE-03-B-AFTER-DEADLINE (late 0100 arrival & fresh transport generation fencing)
///       * CASE-03-C-CHUNKED-LITERAL (fragmented SPP stream framing with async chunk join)
///   - CASE-04-HEALTHY-CONTROL:
///       * CASE-04-A-FULL-CYCLE (nominal connect, 13.9V, 0100, PollingEngine speed reading, clean closure)
///       * CASE-04-B-OBSERVER-TX-EQUIVALENCE (fixed demand TX equivalence between observer on and off)
///
/// Enforces R81-1 ~ R81-4 review requirements:
///   - R81-1: Explicit runId, attemptId, generation, and awaited caller disconnect.
///   - R81-2: Step-handoff ATSP0 measurement, fresh transport generation fencing, observer TX equivalence.
///   - R81-3: Immutable target socket controller capture & async chunk join on teardown.
///   - R81-4: M106-01~04 mutation killing, N106-05 schema + execution negative controls.
///   - 0 lib/ changes (characterization & causal evidence only).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';

import 'support/issue106_trace_probe.dart';

/// Maps raw low-level causes into normalized fixture cause classifications.
String normalizeFirstCause(String? rawCause, {String? command}) {
  if (rawCause == null) return 'None';
  if (rawCause == 'StreamDone' || rawCause == 'TransportDrop') return 'TransportDrop';
  if (rawCause == 'StreamError' || rawCause == 'SocketReset') return 'SocketReset';
  if (rawCause == 'CallerDisconnect' || rawCause == 'CallerInitiated') return 'CallerInitiated';
  if (rawCause == 'HandshakeTimeout') {
    if (command == '0100') return 'SlowResponseTimeout';
    return 'HandshakeTimeout';
  }
  return rawCause;
}

/// Maps raw TransportIssue and raw InitNote into normalized product issue category (R81-4).
String normalizeProductIssueCategory({
  TransportIssue? rawIssue,
  InitNote? rawNote,
}) {
  if (rawIssue != null) return rawIssue.name;
  if (rawNote == InitNote.timedOut) return 'commandReplyTimeout';
  return 'none';
}

/// Validates the structure and content of connection_cases.json.
void validateCasesFixture(Map<String, dynamic> content) {
  if (content['task_id'] != 'TELLTALE-CONNECT106-CAUSAL-TRIAGE') {
    throw FormatException('Invalid task_id: ${content['task_id']}');
  }
  if (content['issue_ref'] != 106) {
    throw FormatException('Invalid issue_ref: ${content['issue_ref']}');
  }
  final scenarios = content['scenarios'] as List?;
  if (scenarios == null || scenarios.length != 4) {
    throw FormatException('Expected 4 scenarios, got ${scenarios?.length}');
  }
  final expectedSuffixes = {
    'CASE-01-A-REMOTE-EOF',
    'CASE-01-B-SOCKET-RESET',
    'CASE-01-C-CALLER-CANCEL',
    'CASE-02-A-CRITICAL-AT-TIMEOUT',
    'CASE-02-B-NON-CRITICAL-AT-FAIL',
    'CASE-03-A-BEFORE-DEADLINE',
    'CASE-03-B-AFTER-DEADLINE',
    'CASE-03-C-CHUNKED-LITERAL',
    'CASE-04-A-FULL-CYCLE',
  };
  final foundSuffixes = <String>{};
  for (final s in scenarios) {
    final subs = (s['sub_cases'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final sub in subs) {
      final suffix = sub['suffix'] as String?;
      if (suffix == null) throw const FormatException('Missing suffix in sub_case');
      foundSuffixes.add(suffix);
      if (sub['first_cause_classification'] == null) {
        throw FormatException('Missing first_cause_classification in $suffix');
      }
      if (sub['expected_terminal_state'] == null) {
        throw FormatException('Missing expected_terminal_state in $suffix');
      }
      final cleanups = sub['cleanup_obligations'] as List?;
      if (cleanups == null || cleanups.isEmpty) {
        throw FormatException('Empty cleanup_obligations in $suffix');
      }
    }
  }
  for (final req in expectedSuffixes) {
    if (!foundSuffixes.contains(req)) {
      throw FormatException('Missing required sub_case: $req');
    }
  }
}

/// Retrieves a specific sub-case specification from connection_cases.json.
Map<String, dynamic> getSubCaseSpec(String suffix) {
  final fixtureFile = File('test/fixtures/issue106/connection_cases.json');
  final content = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
  for (final s in content['scenarios'] as List) {
    for (final sub in (s['sub_cases'] as List)) {
      if (sub['suffix'] == suffix) return sub as Map<String, dynamic>;
    }
  }
  throw ArgumentError('Sub-case not found: $suffix');
}

/// Validates runtime execution against fixture sub-case specification (N106-05).
void validateSubCaseExecution({
  required Map<String, dynamic> subCaseSpec,
  required Issue106TraceProbe probe,
  required bool connectOk,
  String? attemptId,
}) {
  final fault = subCaseSpec['injected_fault'] as String?;
  final expectedTerminal = subCaseSpec['expected_terminal_state'] as String?;
  final expectedFirstCause = subCaseSpec['first_cause_classification'] as String?;
  final expectedIssue = subCaseSpec['product_reported_issue'] as String?;
  final expectedNote = subCaseSpec['product_reported_note'] as String?;

  // 1. Verify injected fault was triggered during execution (if not 'none')
  // Strict check: Must have an actual fired event matching the fault type and attempt.
  // Configuration (probe.injectedFault) alone is NOT evidence of triggering.
  if (fault != null && fault != 'none') {
    final faultFired = probe.records.any((r) =>
        r.kind == TraceEventKind.injectedFaultFired &&
        r.details['type'] == fault &&
        (attemptId == null || r.attemptId == attemptId));
    if (!faultFired) {
      throw StateError(
        'Injected fault "$fault" was never triggered during execution'
        '${attemptId != null ? ' for attempt $attemptId' : ''}',
      );
    }
  }

  // 2. Verify terminal connection state matches fixture
  // Positive terminals must strictly require connectOk == true
  if ((expectedTerminal == 'handshake_success' ||
          expectedTerminal == 'handshake_continued' ||
          expectedTerminal == 'connected_then_closed') &&
      !connectOk) {
    throw StateError('Expected $expectedTerminal but connect returned false');
  }
  // Failure terminals must strictly require connectOk == false
  if ((expectedTerminal == 'disconnected' ||
          expectedTerminal == 'handshake_failed' ||
          expectedTerminal == 'disconnected_by_app') &&
      connectOk) {
    throw StateError('Expected failure ($expectedTerminal) but connect returned true');
  }

  // 3. Verify first terminal cause classification for failure scenarios
  if (expectedTerminal != 'handshake_success' &&
      expectedTerminal != 'handshake_continued' &&
      expectedTerminal != 'connected_then_closed') {
    if (expectedFirstCause != null && expectedFirstCause != 'None') {
      if (probe.firstTerminalCause == null) {
        throw StateError(
          'Expected first_cause_classification "$expectedFirstCause" but probe recorded no first terminal cause',
        );
      }
      final normalizedCause = normalizeFirstCause(
        probe.firstTerminalCause,
        command: probe.failedStepCommand,
      );
      if (normalizedCause != expectedFirstCause &&
          probe.firstTerminalCause != expectedFirstCause) {
        throw StateError(
          'First cause mismatch: expected $expectedFirstCause, got actual=${probe.firstTerminalCause}',
        );
      }
    }
  }

  // 4. Verify product reported issue (R81-4)
  final rawIssue = probe.productReportedIssue;
  final rawNote = probe.failedStepNote;
  final normalizedCategory = normalizeProductIssueCategory(
    rawIssue: rawIssue,
    rawNote: rawNote,
  );

  if (expectedIssue != null) {
    final bool issueMatches;
    if (expectedIssue == 'commandReplyTimeout') {
      // commandReplyTimeout matches IF AND ONLY IF rawNote is timedOut AND rawIssue is null
      issueMatches = rawNote == InitNote.timedOut && rawIssue == null;
    } else if (expectedIssue == 'none') {
      // When expecting no issue, normalized category must be 'none'
      issueMatches = normalizedCategory == 'none';
    } else {
      // For all other expected issues, raw issue must strictly match expectedIssue.
      // timedOut can never exempt a product issue mismatch.
      issueMatches = rawIssue?.name == expectedIssue;
    }

    if (!issueMatches) {
      throw StateError(
        'Product issue mismatch: expected $expectedIssue, got normalizedCategory=$normalizedCategory actualRawIssue=${rawIssue?.name} actualRawNote=${rawNote?.name}',
      );
    }
  }

  // 5. Verify product reported note if specified
  if (expectedNote != null && probe.failedStepNote?.name != expectedNote) {
    throw StateError(
      'Product note mismatch: expected $expectedNote, got ${probe.failedStepNote?.name}',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue #106 Slice 1: Fixture Integrity & Negative Control (N106-05)', () {
    test('connection_cases.json fixture contains all required sub-cases', () {
      final fixtureFile = File('test/fixtures/issue106/connection_cases.json');
      expect(fixtureFile.existsSync(), isTrue, reason: 'Fixture must exist');

      final content = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
      expect(() => validateCasesFixture(content), returnsNormally);
    });

    test('N106-05 negative control: Missing sub-case is detected and rejected', () {
      final fixtureFile = File('test/fixtures/issue106/connection_cases.json');
      final content = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      // Tamper: remove CASE-01-A-REMOTE-EOF
      final tampered = jsonDecode(jsonEncode(content)) as Map<String, dynamic>;
      final scenarios = tampered['scenarios'] as List;
      final s0 = scenarios[0] as Map<String, dynamic>;
      final subs = s0['sub_cases'] as List;
      subs.removeAt(0);

      expect(
        () => validateCasesFixture(tampered),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Missing required sub_case: CASE-01-A-REMOTE-EOF'),
        )),
        reason: 'Negative control must fail when required sub-case is missing',
      );
    });

    test('N106-05 negative control: Empty cleanup obligations is rejected', () {
      final fixtureFile = File('test/fixtures/issue106/connection_cases.json');
      final content = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      // Tamper: set cleanup_obligations to empty list
      final tampered = jsonDecode(jsonEncode(content)) as Map<String, dynamic>;
      final scenarios = tampered['scenarios'] as List;
      final s0 = scenarios[0] as Map<String, dynamic>;
      final subs = s0['sub_cases'] as List;
      (subs[0] as Map<String, dynamic>)['cleanup_obligations'] = [];

      expect(
        () => validateCasesFixture(tampered),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Empty cleanup_obligations'),
        )),
        reason: 'Negative control must fail when cleanup obligations are empty',
      );
    });

    test('N106-05 negative control: Fault not triggered is rejected', () {
      final subCase = getSubCaseSpec('CASE-01-A-REMOTE-EOF');

      // Probe where fault was configured ('stream_done') but never fired, and connectOk is true
      final probe = Issue106TraceProbe(
        runId: 'RUN-NEG-NO-FAULT',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );

      expect(
        () => validateSubCaseExecution(
          subCaseSpec: subCase,
          probe: probe,
          connectOk: true,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('was never triggered'),
        )),
        reason: 'Harness must reject when configured fault was never triggered',
      );
    });

    test('N106-05 negative control: Execution result mismatch is rejected', () {
      final subCase = getSubCaseSpec('CASE-01-A-REMOTE-EOF');

      // Probe where fault fired, but reported issue mismatches fixture
      final probe = Issue106TraceProbe(
        runId: 'RUN-NEG-MISMATCH',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.record(
        kind: TraceEventKind.injectedFaultFired,
        component: 'transport',
        phase: 'inject',
        details: {'type': 'stream_done'},
      );
      probe.record(
        kind: TraceEventKind.streamDoneObserved,
        component: 'transport',
        phase: 'rx',
        details: {'cause': 'StreamDone'},
      );
      // Mismatch: set productReportedIssue to cancelled instead of linkDroppedMidSession
      probe.productReportedIssue = TransportIssue.cancelled;

      expect(
        () => validateSubCaseExecution(
          subCaseSpec: subCase,
          probe: probe,
          connectOk: false,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Product issue mismatch'),
        )),
        reason: 'Harness must reject when execution outcome does not match fixture specification',
      );
    });

    test('N106-05 negative control: timedOut does not bypass issue mismatch for linkDroppedMidSession', () {
      final subCase = getSubCaseSpec('CASE-01-A-REMOTE-EOF');
      final probe = Issue106TraceProbe(
        runId: 'RUN-NEG-TIMEDOUT-BYPASS',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'stream_done';
      probe.record(
        kind: TraceEventKind.injectedFaultFired,
        component: 'transport',
        phase: 'inject',
        details: {'type': 'stream_done'},
      );
      probe.record(
        kind: TraceEventKind.streamDoneObserved,
        component: 'transport',
        phase: 'rx',
        details: {'cause': 'StreamDone'},
      );
      // Counterexample: probe erroneously reports cancelled issue with timedOut note
      probe.productReportedIssue = TransportIssue.cancelled;
      probe.failedStepNote = InitNote.timedOut;

      expect(
        () => validateSubCaseExecution(
          subCaseSpec: subCase,
          probe: probe,
          connectOk: false,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Product issue mismatch'),
        )),
        reason: 'timedOut must never exempt an issue mismatch for linkDroppedMidSession',
      );
    });

    test('N106-05 negative control: Fault type mismatch is rejected', () {
      final subCase = getSubCaseSpec('CASE-01-A-REMOTE-EOF');
      final probe = Issue106TraceProbe(
        runId: 'RUN-NEG-FAULT-MISMATCH',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      // Configured fault does not match CASE-01-A ('stream_done')
      probe.injectedFault = 'silent_stall';
      probe.record(
        kind: TraceEventKind.injectedFaultFired,
        component: 'transport',
        phase: 'inject',
        details: {'type': 'silent_stall'},
      );

      expect(
        () => validateSubCaseExecution(
          subCaseSpec: subCase,
          probe: probe,
          connectOk: false,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('was never triggered'),
        )),
        reason: 'Harness must reject when wrong fault type was triggered',
      );
    });

    test('N106-05 negative control: First terminal cause mismatch is rejected', () {
      final subCase = getSubCaseSpec('CASE-01-A-REMOTE-EOF');
      final probe = Issue106TraceProbe(
        runId: 'RUN-NEG-CAUSE-MISMATCH',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'stream_done';
      probe.record(
        kind: TraceEventKind.injectedFaultFired,
        component: 'transport',
        phase: 'inject',
        details: {'type': 'stream_done'},
      );
      // Erroneously recorded StreamError instead of StreamDone / TransportDrop
      probe.record(
        kind: TraceEventKind.streamErrorObserved,
        component: 'transport',
        phase: 'rx',
        details: {'cause': 'StreamError'},
      );
      probe.productReportedIssue = TransportIssue.linkDroppedMidSession;

      expect(
        () => validateSubCaseExecution(
          subCaseSpec: subCase,
          probe: probe,
          connectOk: false,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('First cause mismatch'),
        )),
        reason: 'Harness must reject when first terminal cause does not match fixture classification',
      );
    });

    test('N106-05 negative control: unexpected product issue on nominal case expecting none is rejected', () {
      final subCase = getSubCaseSpec('CASE-04-A-FULL-CYCLE');
      final probe = Issue106TraceProbe(
        runId: 'RUN-NEG-UNEXPECTED-ISSUE',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      // Nominal case expects 'none', but an unexpected linkDroppedMidSession occurred
      probe.productReportedIssue = TransportIssue.linkDroppedMidSession;

      expect(
        () => validateSubCaseExecution(
          subCaseSpec: subCase,
          probe: probe,
          connectOk: true,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Product issue mismatch'),
        )),
        reason: 'Harness must reject when an unexpected product issue occurs on a case expecting none',
      );
    });

    test('N106-05 negative control: timedOut cannot match commandReplyTimeout when raw issue is present', () {
      final subCase = getSubCaseSpec('CASE-02-A-CRITICAL-AT-TIMEOUT');
      final probe = Issue106TraceProbe(
        runId: 'RUN-NEG-TIMEDOUT-CONFLICT',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'silent_stall';
      probe.record(
        kind: TraceEventKind.injectedFaultFired,
        component: 'transport',
        phase: 'inject',
        details: {'type': 'silent_stall'},
      );
      probe.record(
        kind: TraceEventKind.firstTerminalObserved,
        component: 'transport',
        phase: 'rx',
        details: {'cause': 'HandshakeTimeout'},
      );
      probe.failedStepNote = InitNote.timedOut;
      // Conflicting raw transport issue: cancelled
      probe.productReportedIssue = TransportIssue.cancelled;

      expect(
        () => validateSubCaseExecution(
          subCaseSpec: subCase,
          probe: probe,
          connectOk: false,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Product issue mismatch'),
        )),
        reason: 'commandReplyTimeout must strictly require raw issue to be null',
      );
    });

    test('N106-05 negative control: Configured probe fault matches but fired event has wrong type is rejected', () {
      final subCase = getSubCaseSpec('CASE-01-A-REMOTE-EOF');
      final probe = Issue106TraceProbe(
        runId: 'RUN-NEG-WRONG-FIRED-TYPE',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      // Probe configured with expected fault:
      probe.injectedFault = 'stream_done';
      // But actual fired event has mismatched type:
      probe.record(
        kind: TraceEventKind.injectedFaultFired,
        component: 'transport',
        phase: 'inject',
        attemptId: 'ATTEMPT-01',
        details: {'type': 'unexpected_fault_type'},
      );
      probe.record(
        kind: TraceEventKind.streamDoneObserved,
        component: 'transport',
        phase: 'rx',
        attemptId: 'ATTEMPT-01',
        details: {'cause': 'StreamDone'},
      );
      probe.productReportedIssue = TransportIssue.linkDroppedMidSession;

      expect(
        () => validateSubCaseExecution(
          subCaseSpec: subCase,
          probe: probe,
          connectOk: false,
          attemptId: 'ATTEMPT-01',
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('was never triggered'),
        )),
        reason: 'Harness must reject when configured fault matches but fired event type does not',
      );
    });

    test('N106-05 negative control: connectOk is false on handshake_continued is rejected', () {
      final subCase = getSubCaseSpec('CASE-02-B-NON-CRITICAL-AT-FAIL');
      final probe = Issue106TraceProbe(
        runId: 'RUN-NEG-CONTINUED-FALSE',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'unknown_command_probe';
      probe.record(
        kind: TraceEventKind.injectedFaultFired,
        component: 'transport',
        phase: 'inject',
        attemptId: 'ATTEMPT-01',
        details: {'type': 'unknown_command_probe'},
      );

      expect(
        () => validateSubCaseExecution(
          subCaseSpec: subCase,
          probe: probe,
          connectOk: false,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Expected handshake_continued but connect returned false'),
        )),
        reason: 'Harness must reject handshake_continued when connectOk is false',
      );
    });

    test('N106-05 negative control: connectOk is false on connected_then_closed is rejected', () {
      final subCase = getSubCaseSpec('CASE-04-A-FULL-CYCLE');
      final probe = Issue106TraceProbe(
        runId: 'RUN-NEG-FULL-CYCLE-FALSE',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'none';

      expect(
        () => validateSubCaseExecution(
          subCaseSpec: subCase,
          probe: probe,
          connectOk: false,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Expected connected_then_closed but connect returned false'),
        )),
        reason: 'Harness must reject connected_then_closed when connectOk is false',
      );
    });

    test('N106-05 negative control: Injected fault on mismatched attempt is rejected', () {
      final subCase = getSubCaseSpec('CASE-01-A-REMOTE-EOF');
      final probe = Issue106TraceProbe(
        runId: 'RUN-NEG-ATTEMPT-MISMATCH',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'stream_done';
      // Fired on ATTEMPT-02 instead of requested ATTEMPT-01
      probe.record(
        kind: TraceEventKind.injectedFaultFired,
        component: 'transport',
        phase: 'inject',
        attemptId: 'ATTEMPT-02',
        details: {'type': 'stream_done', 'attemptId': 'ATTEMPT-02'},
      );

      expect(
        () => validateSubCaseExecution(
          subCaseSpec: subCase,
          probe: probe,
          connectOk: false,
          attemptId: 'ATTEMPT-01',
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('was never triggered during execution for attempt ATTEMPT-01'),
        )),
        reason: 'Harness must reject when fault was fired on a different attempt',
      );
    });
  });

  group('CASE-01-TRANSPORT-EOF', () {
    test('CASE-01-A-REMOTE-EOF: Remote stream onDone triggers linkDroppedMidSession and preserves first cause', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-CASE-01-A',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'stream_done';

      final transport = ScriptedCausalTransport(name: 'eof_test', probe: probe);
      final client = Elm327Client(transport);

      StreamSubscription<InitProgress>? progressSub;
      progressSub = client.initProgress.listen(probe.observeInitProgress);

      addTearDown(() async {
        await progressSub?.cancel();
        await client.dispose();
        await transport.dispose();
      });

      // Inject EOF right when 0100 is written (after ATRV succeeded)
      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100')) {
          t.injectRemoteDone();
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();
      expect(connectOk, isFalse, reason: 'Connect must fail when link drops on 0100');

      // First terminal cause must be StreamDone (from real onDone subscription)
      expect(probe.firstTerminalCause, 'StreamDone');
      expect(probe.verifyFirstTerminalIntact('StreamDone'), isTrue);

      // Product reported issue on Elm327Client
      expect(client.isInitialized, isFalse);
      expect(transport.isConnected, isFalse);
      expect(probe.productReportedIssue, TransportIssue.linkDroppedMidSession);

      // M106-01: Explicit cleanup does NOT overwrite the first terminal cause
      await client.dispose();
      expect(
        probe.firstTerminalCause,
        'StreamDone',
        reason: 'Cleanup must not overwrite first terminal cause',
      );

      validateSubCaseExecution(
        subCaseSpec: getSubCaseSpec('CASE-01-A-REMOTE-EOF'),
        probe: probe,
        connectOk: connectOk,
      );
    });

    test('CASE-01-B-SOCKET-RESET: Remote stream onError triggers linkDroppedMidSession and handles error safely', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-CASE-01-B',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'stream_error';

      final transport = ScriptedCausalTransport(name: 'reset_test', probe: probe);
      final client = Elm327Client(transport);

      StreamSubscription<InitProgress>? progressSub;
      progressSub = client.initProgress.listen(probe.observeInitProgress);

      addTearDown(() async {
        await progressSub?.cancel();
        await client.dispose();
        await transport.dispose();
      });

      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100')) {
          t.injectRemoteError(const SocketException('Connection reset by peer'));
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();
      expect(connectOk, isFalse);

      expect(probe.firstTerminalCause, 'StreamError');
      expect(probe.verifyFirstTerminalIntact('StreamError'), isTrue);
      expect(client.isInitialized, isFalse);
      expect(transport.isConnected, isFalse);
      expect(probe.productReportedIssue, TransportIssue.linkDroppedMidSession);

      await client.dispose();
      expect(probe.firstTerminalCause, 'StreamError');

      validateSubCaseExecution(
        subCaseSpec: getSubCaseSpec('CASE-01-B-SOCKET-RESET'),
        probe: probe,
        connectOk: connectOk,
      );
    });

    test('CASE-01-C-CALLER-CANCEL: Active caller disconnect cleanly disposes resources with awaited cancellation', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-CASE-01-C',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'caller_disconnect';

      final transport = ScriptedCausalTransport(name: 'cancel_test', probe: probe);
      final client = Elm327Client(transport);

      StreamSubscription<InitProgress>? progressSub;
      progressSub = client.initProgress.listen(probe.observeInitProgress);

      addTearDown(() async {
        await progressSub?.cancel();
        await client.dispose();
        await transport.dispose();
      });

      Future<void>? callerDisconnectFuture;
      transport.onCommandHook = (cmd, t) async {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100')) {
          probe.record(
            kind: TraceEventKind.injectedFaultFired,
            component: 'caller',
            phase: 'cancel',
            command: '0100',
            attemptId: probe.attemptId,
            generation: probe.generation,
            details: {
              'type': 'caller_disconnect',
              'generation': probe.generation,
              'attemptId': probe.attemptId,
            },
          );
          probe.record(
            kind: TraceEventKind.firstTerminalObserved,
            component: 'caller',
            phase: 'cancel',
            command: '0100',
            details: {'cause': 'CallerDisconnect'},
          );
          // R81-1: Explicitly await client.disconnect() to confirm exact cancellation/cleanup completion point
          callerDisconnectFuture = client.disconnect();
          await callerDisconnectFuture;
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();
      expect(connectOk, isFalse);
      expect(callerDisconnectFuture, isNotNull, reason: 'Caller disconnect must have been initiated');
      await callerDisconnectFuture; // fully awaited and confirmed

      expect(probe.firstTerminalCause, 'CallerDisconnect');
      expect(transport.isConnected, isFalse);
      expect(probe.productReportedIssue, TransportIssue.disconnectedByApp);
      expect(probe.failedStepCommand, '0100');

      validateSubCaseExecution(
        subCaseSpec: getSubCaseSpec('CASE-01-C-CALLER-CANCEL'),
        probe: probe,
        connectOk: connectOk,
      );
    });
  });

  group('CASE-02-HANDSHAKE-TIMEOUT', () {
    test('CASE-02-A-CRITICAL-AT-TIMEOUT: Unresponsive critical command aborts negotiation at 4s boundary from step handoff', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-CASE-02-A',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'silent_stall';

      final transport = ScriptedCausalTransport(name: 'timeout_test', probe: probe);
      final client = Elm327Client(transport);

      int? atsp0HandoffMs;
      final sw = Stopwatch()..start();

      bool checkedBeforeDeadline = false;
      bool timeoutObservedBeforeDeadline = true;
      bool terminalCausePresentBeforeDeadline = true;
      Timer? beforeDeadlineTimer;

      StreamSubscription<InitProgress>? progressSub;
      progressSub = client.initProgress.listen((progress) {
        probe.observeInitProgress(progress);
        // R81-2: Record precise step handoff time when ATSP0 begins running
        if (progress.status == InitStatus.running &&
            progress.step.command.toUpperCase().replaceAll(' ', '') == 'ATSP0') {
          atsp0HandoffMs = sw.elapsedMilliseconds;
          // Phase-deadline verification: Sample mid-window at 2000ms from ATSP0 step handoff
          // (well before 4s deadline) to confirm no early/premature timeout event is triggered.
          beforeDeadlineTimer = Timer(const Duration(milliseconds: 2000), () {
            checkedBeforeDeadline = true;
            timeoutObservedBeforeDeadline = probe.records.any(
              (r) => r.kind == TraceEventKind.timeoutObserved && r.command == 'ATSP0',
            );
            terminalCausePresentBeforeDeadline = probe.firstTerminalCause != null;
          });
        }
      });

      addTearDown(() async {
        beforeDeadlineTimer?.cancel();
        await progressSub?.cancel();
        await client.dispose();
        await transport.dispose();
      });

      // R81-2: Stall on critical ATSP0 (isCritical: true, validate: _requireOk)
      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('ATSP0')) {
          // Go silent: no reply, no prompt
          probe.record(
            kind: TraceEventKind.injectedFaultFired,
            component: 'transport',
            phase: 'atsp0',
            command: 'ATSP0',
            details: {'type': 'silent_stall'},
          );
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();
      final atsp0EndMs = sw.elapsedMilliseconds;
      sw.stop();

      expect(connectOk, isFalse);
      expect(atsp0HandoffMs, isNotNull, reason: 'ATSP0 step handoff must have occurred');

      // 1. Phase-deadline: Verification BEFORE deadline (mid-window checkpoint at ~2000ms)
      expect(checkedBeforeDeadline, isTrue, reason: 'Mid-window checkpoint must have executed');
      expect(
        timeoutObservedBeforeDeadline,
        isFalse,
        reason: 'Typed timeout event must NOT be triggered before deadline expires',
      );
      expect(
        terminalCausePresentBeforeDeadline,
        isFalse,
        reason: 'First terminal cause must remain unsealed before deadline expires',
      );

      // 2. Phase-deadline: Verification AT TIMEOUT boundary (first typed timeout event)
      final atsp0StartRecord = probe.records.firstWhere(
        (r) => r.kind == TraceEventKind.initStepStarted && r.command == 'ATSP0',
      );
      final atsp0TimeoutRecord = probe.records.firstWhere(
        (r) => r.kind == TraceEventKind.timeoutObserved && r.command == 'ATSP0',
      );
      final atsp0FailedRecord = probe.records.firstWhere(
        (r) =>
            r.kind == TraceEventKind.initStepCompleted &&
            r.command == 'ATSP0' &&
            r.details['status'] == 'failed',
      );

      expect(atsp0TimeoutRecord.details['cause'], 'HandshakeTimeout');
      expect(atsp0TimeoutRecord.details['cmd'], 'ATSP0');

      // ATSP0 sends command with timeout: const Duration(seconds: 4).
      // Bounding measured strictly from step handoff in consistent clock domain to the typed timeout event.
      final handoffToTimeoutMs = atsp0TimeoutRecord.elapsedMs - atsp0StartRecord.elapsedMs;
      expect(
        handoffToTimeoutMs,
        greaterThanOrEqualTo(3800),
        reason: 'First typed timeout event must respect 4s deadline measured from step handoff',
      );
      expect(
        handoffToTimeoutMs,
        lessThan(4800),
        reason: 'First typed timeout event must trigger at 4s boundary without hanging (M106-02)',
      );

      // 3. Phase-deadline: Verification AFTER TIMEOUT boundary
      // Timeout event must strictly precede failed step completion record
      expect(
        atsp0StartRecord.sequence,
        lessThan(atsp0TimeoutRecord.sequence),
        reason: 'initStepStarted must precede timeoutObserved',
      );
      expect(
        atsp0TimeoutRecord.sequence,
        lessThan(atsp0FailedRecord.sequence),
        reason: 'First typed timeout event must precede initStepCompleted (failed)',
      );

      final atsp0DurationMs = atsp0EndMs - atsp0HandoffMs!;
      expect(
        atsp0DurationMs,
        greaterThanOrEqualTo(3800),
        reason: 'Overall connect() return must respect 4s deadline measured from step handoff',
      );
      expect(
        atsp0DurationMs,
        lessThan(4800),
        reason: 'Overall connect() return must not hang or drift beyond 4s budget (M106-02)',
      );

      expect(client.isInitialized, isFalse);
      expect(probe.failedStepCommand, 'ATSP0');
      expect(probe.failedStepNote, InitNote.timedOut);
      expect(probe.firstTerminalCause, 'HandshakeTimeout');

      // Verify that subsequent steps (such as 0100) were skipped and never sent to wire
      expect(
        transport.writtenCommands.any((c) => c.startsWith('0100')),
        isFalse,
        reason: 'Subsequent steps must not reach the wire after critical failure',
      );

      validateSubCaseExecution(
        subCaseSpec: getSubCaseSpec('CASE-02-A-CRITICAL-AT-TIMEOUT'),
        probe: probe,
        connectOk: connectOk,
      );
    });

    test('CASE-02-A boundary: ATSP0 reply arriving before deadline succeeds and triggers no timeoutObserved', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-CASE-02-A-BEFORE-DEADLINE',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );

      final transport = ScriptedCausalTransport(name: 'atsp0_early_ok', probe: probe);
      final client = Elm327Client(transport);

      StreamSubscription<InitProgress>? progressSub;
      progressSub = client.initProgress.listen(probe.observeInitProgress);

      addTearDown(() async {
        await progressSub?.cancel();
        await client.dispose();
        await transport.dispose();
      });

      // ATSP0 answers OK after 250ms (well before the 4s deadline)
      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('ATSP0')) {
          t.scheduleDelayed(const Duration(milliseconds: 250), () {
            t.sendReply('OK\r\n>');
          });
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();
      expect(connectOk, isTrue);

      // Verify ATSP0 completed OK
      final atsp0Record = probe.records.firstWhere(
        (r) => r.kind == TraceEventKind.initStepCompleted && r.command == 'ATSP0',
      );
      expect(atsp0Record.details['status'], 'ok');

      // Verify NO timeoutObserved was ever emitted
      expect(
        probe.records.any((r) => r.kind == TraceEventKind.timeoutObserved),
        isFalse,
        reason: 'Reply before deadline must never trigger a timeout event',
      );
      expect(probe.firstTerminalCause, isNull);
    });

    test('CASE-02-A controlled boundary PRE: ATSP0 reply arriving at D - epsilon (3999ms) completes step without timeout', () {
      fakeAsync((async) {
        final startTime = DateTime(2026, 9, 28, 10, 0, 0);
        final probe = Issue106TraceProbe(
          runId: 'RUN-CASE-02-A-PRE',
          attemptId: 'ATTEMPT-01',
          generation: 1,
          clock: () => startTime.add(async.elapsed),
          elapsedMsProvider: () => async.elapsed.inMilliseconds,
        );

        final transport = ScriptedCausalTransport(name: 'atsp0_pre_deadline', probe: probe);
        final client = Elm327Client(
          transport,
          clock: () => startTime.add(async.elapsed),
          elapsed: () => async.elapsed,
        );

        final progressSub = client.initProgress.listen(probe.observeInitProgress);
        try {
          bool atsp0Reached = false;
          transport.onCommandHook = (cmd, t) {
            final norm = cmd.toUpperCase().replaceAll(' ', '');
            if (norm.startsWith('ATSP0')) {
              atsp0Reached = true;
              // Hold reply; do not answer immediately
            } else {
              t.defaultAnswer(cmd);
            }
          };

          bool? connectResult;
          unawaited(client.connect().then((val) => connectResult = val));

          int pumpCount = 0;
          while (!atsp0Reached && pumpCount < 100) {
            async.elapse(const Duration(milliseconds: 10));
            pumpCount++;
          }
          expect(atsp0Reached, isTrue, reason: 'ATSP0 must have reached wire and entered reply-wait');
          expect(client.isInitialized, isFalse);

          final atsp0StartRecord = probe.records.firstWhere(
            (r) => r.kind == TraceEventKind.initStepStarted && r.command == 'ATSP0',
          );
          final t0Ms = atsp0StartRecord.elapsedMs;

          final elapsedSinceT0Ms = async.elapsed.inMilliseconds - t0Ms;
          expect(elapsedSinceT0Ms, lessThan(3999), reason: 'ATSP0 handoff must be reached before deadline');

          // Advance to D - epsilon (3999ms from T0): still pending, no timeout
          async.elapse(Duration(milliseconds: 3999 - elapsedSinceT0Ms));

          expect(connectResult, isNull, reason: 'connect() must still be pending at D - epsilon');
          expect(
            probe.records.any((r) => r.kind == TraceEventKind.timeoutObserved),
            isFalse,
            reason: 'No timeoutObserved must be recorded before deadline (at D - epsilon)',
          );
          expect(probe.firstTerminalCause, isNull);
          expect(probe.failedStepCommand, isNull);

          // Deliver reply at D - epsilon
          transport.sendReply('OK\r\n>');
          int finishCount = 0;
          while (connectResult == null && finishCount < 100) {
            async.elapse(const Duration(milliseconds: 10));
            finishCount++;
          }

          expect(connectResult, isTrue, reason: 'connect() must succeed when reply delivered at D - epsilon');
          expect(client.isInitialized, isTrue);

          final atsp0Completed = probe.records.firstWhere(
            (r) => r.kind == TraceEventKind.initStepCompleted && r.command == 'ATSP0',
          );
          expect(atsp0Completed.details['status'], 'ok');
          expect(atsp0StartRecord.elapsedMs, t0Ms);

          expect(
            probe.records.any((r) => r.kind == TraceEventKind.timeoutObserved),
            isFalse,
            reason: 'Reply processed before deadline must result in zero timeout events',
          );
          expect(probe.firstTerminalCause, isNull);

          expect(
            transport.writtenCommands.any((c) => c.startsWith('0100')),
            isTrue,
            reason: 'Subsequent handshake steps must reach wire upon ATSP0 success',
          );
        } finally {
          progressSub.cancel();
          if (!transport.isDisposed) {
            bool disposed = false;
            Object? disposeError;
            transport.dispose().then(
              (_) => disposed = true,
              onError: (e) {
                disposed = true;
                disposeError = e;
              },
            );
            async.flushMicrotasks();
            expect(disposed, isTrue, reason: 'Transport dispose must complete cleanly within fakeAsync');
            if (disposeError != null) {
              throw disposeError!;
            }
          }
        }
      });
    });

    test('CASE-02-A controlled boundary DUE & LATE: ATSP0 reaches exact deadline D (4000ms) with typed timeout, and late reply at D + epsilon (4001ms) cannot reverse failure', () {
      fakeAsync((async) {
        final startTime = DateTime(2026, 9, 28, 10, 0, 0);
        final probe = Issue106TraceProbe(
          runId: 'RUN-CASE-02-A-DUE-LATE',
          attemptId: 'ATTEMPT-01',
          generation: 1,
          clock: () => startTime.add(async.elapsed),
          elapsedMsProvider: () => async.elapsed.inMilliseconds,
        );
        probe.injectedFault = 'silent_stall';

        final transport = ScriptedCausalTransport(name: 'atsp0_due_late', probe: probe);
        final client = Elm327Client(
          transport,
          clock: () => startTime.add(async.elapsed),
          elapsed: () => async.elapsed,
        );

        final progressSub = client.initProgress.listen(probe.observeInitProgress);
        try {
          bool atsp0Reached = false;
          transport.onCommandHook = (cmd, t) {
            final norm = cmd.toUpperCase().replaceAll(' ', '');
            if (norm.startsWith('ATSP0')) {
              atsp0Reached = true;
              probe.record(
                kind: TraceEventKind.injectedFaultFired,
                component: 'transport',
                phase: 'atsp0',
                command: 'ATSP0',
                details: {'type': 'silent_stall'},
              );
              // Go silent: hold reply indefinitely
            } else {
              t.defaultAnswer(cmd);
            }
          };

          bool? connectResult;
          unawaited(client.connect().then((val) => connectResult = val));

          int pumpCount = 0;
          while (!atsp0Reached && pumpCount < 100) {
            async.elapse(const Duration(milliseconds: 10));
            pumpCount++;
          }
          expect(atsp0Reached, isTrue, reason: 'ATSP0 must have reached wire and entered reply-wait');
          expect(client.isInitialized, isFalse);

          final atsp0StartRecord = probe.records.firstWhere(
            (r) => r.kind == TraceEventKind.initStepStarted && r.command == 'ATSP0',
          );
          final t0Ms = atsp0StartRecord.elapsedMs;

          final elapsedSinceT0Ms = async.elapsed.inMilliseconds - t0Ms;
          expect(elapsedSinceT0Ms, lessThan(3999), reason: 'ATSP0 handoff must be reached before deadline');

          const epsilon = Duration(milliseconds: 1);

          // 1. Advance to D - epsilon (3999ms from T0): still pending, no timeout
          async.elapse(Duration(milliseconds: 3999 - elapsedSinceT0Ms));
          expect(connectResult, isNull, reason: 'connect() must not have completed at D - epsilon');
          expect(
            probe.records.any((r) => r.kind == TraceEventKind.timeoutObserved),
            isFalse,
            reason: 'Typed timeout event must NOT be triggered before deadline D',
          );
          expect(probe.firstTerminalCause, isNull);

          // 2. Advance by epsilon (1ms) to exact deadline D (4000ms from T0)
          async.elapse(epsilon);

          // DUE verification: First typed timeout event occurs precisely at D
          expect(connectResult, isFalse, reason: 'connect() must return false at deadline D');
          final timeoutRecords = probe.records
              .where((r) => r.kind == TraceEventKind.timeoutObserved && r.command == 'ATSP0')
              .toList();
          expect(timeoutRecords.length, 1, reason: 'Exactly one typed timeout event must be recorded at deadline D');
          final timeoutRec = timeoutRecords.first;
          expect(timeoutRec.details['cause'], 'HandshakeTimeout');
          expect(timeoutRec.details['cmd'], 'ATSP0');
          expect(
            timeoutRec.elapsedMs - t0Ms,
            4000,
            reason: 'Typed timeout event must fire at exactly 4000ms from ATSP0 handoff (T0)',
          );

          final failedRecords = probe.records
              .where((r) =>
                  r.kind == TraceEventKind.initStepCompleted &&
                  r.command == 'ATSP0' &&
                  r.details['status'] == 'failed')
              .toList();
          expect(failedRecords.length, 1, reason: 'ATSP0 step must complete failed exactly once');
          expect(timeoutRec.sequence, lessThan(failedRecords.first.sequence),
              reason: 'timeoutObserved must precede initStepCompleted (failed)');

          expect(client.isInitialized, isFalse);
          expect(probe.failedStepCommand, 'ATSP0');
          expect(probe.failedStepNote, InitNote.timedOut);
          expect(probe.firstTerminalCause, 'HandshakeTimeout');

          // Subsequent steps (such as 0100) are skipped and never sent to wire
          expect(
            transport.writtenCommands.any((c) => c.startsWith('0100')),
            isFalse,
            reason: 'Subsequent steps must not reach the wire after critical failure at DUE',
          );

          // 3. LATE verification: Advance to D + epsilon (4001ms from T0) and deliver stranded reply
          async.elapse(epsilon);
          transport.sendReply('OK\r\n>');
          async.elapse(const Duration(milliseconds: 10));

          // Late reply must NOT reverse failure, must NOT re-complete step, and must NOT start subsequent commands
          expect(client.isInitialized, isFalse, reason: 'Late reply must not mark client initialized');
          expect(probe.failedStepCommand, 'ATSP0');
          expect(probe.failedStepNote, InitNote.timedOut);
          expect(probe.firstTerminalCause, 'HandshakeTimeout');

          final allAtsp0Completed = probe.records
              .where((r) => r.kind == TraceEventKind.initStepCompleted && r.command == 'ATSP0')
              .toList();
          expect(
            allAtsp0Completed.length,
            1,
            reason: 'Late reply must not re-complete the already timed out step',
          );
          expect(allAtsp0Completed.first.details['status'], 'failed');

          expect(
            transport.writtenCommands.any((c) => c.startsWith('0100')),
            isFalse,
            reason: 'Late reply must not launch subsequent initialization commands',
          );

          validateSubCaseExecution(
            subCaseSpec: getSubCaseSpec('CASE-02-A-CRITICAL-AT-TIMEOUT'),
            probe: probe,
            connectOk: connectResult!,
          );
        } finally {
          progressSub.cancel();
          if (!transport.isDisposed) {
            bool disposed = false;
            Object? disposeError;
            transport.dispose().then(
              (_) => disposed = true,
              onError: (e) {
                disposed = true;
                disposeError = e;
              },
            );
            async.flushMicrotasks();
            expect(disposed, isTrue, reason: 'Transport dispose must complete cleanly within fakeAsync');
            if (disposeError != null) {
              throw disposeError!;
            }
          }
        }
      });
    });

    test('CASE-02-B-NON-CRITICAL-AT-FAIL: Non-critical AT probe refusal does not abort handshake', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-CASE-02-B',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'unknown_command_probe';

      final transport = ScriptedCausalTransport(name: 'soft_fail_test', probe: probe);
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      // AT@1 responds with '?' (unknown command)
      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('AT@1')) {
          probe.record(
            kind: TraceEventKind.injectedFaultFired,
            component: 'transport',
            phase: 'at@1',
            command: 'AT@1',
            details: {'type': 'unknown_command_probe'},
          );
          t.sendReply('?\r\n>');
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();
      expect(
        connectOk,
        isTrue,
        reason: 'Non-critical failure (? on AT@1) must allow handshake to succeed',
      );
      expect(client.isInitialized, isTrue);
      expect(client.batteryVoltage, 13.9);

      validateSubCaseExecution(
        subCaseSpec: getSubCaseSpec('CASE-02-B-NON-CRITICAL-AT-FAIL'),
        probe: probe,
        connectOk: connectOk,
      );
    });
  });

  group('CASE-03-SLOW-RESPONSE', () {
    test('CASE-03-A-BEFORE-DEADLINE: 0100 arriving within deadline completes handshake successfully', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-CASE-03-A',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'bounded_delay';

      final transport = ScriptedCausalTransport(name: 'slow_ok_test', probe: probe);
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100')) {
          probe.record(
            kind: TraceEventKind.injectedFaultFired,
            component: 'transport',
            phase: '0100',
            command: '0100',
            details: {'type': 'bounded_delay'},
          );
          // Delay reply by 250ms (managed timer, well within 4s deadline)
          t.scheduleDelayed(const Duration(milliseconds: 250), () {
            t.sendReply('41 00 BE 1F B8 10\r\n>');
          });
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();
      expect(connectOk, isTrue);
      expect(client.isInitialized, isTrue);
      expect(client.protocolDescription, isNotEmpty);

      validateSubCaseExecution(
        subCaseSpec: getSubCaseSpec('CASE-03-A-BEFORE-DEADLINE'),
        probe: probe,
        connectOk: connectOk,
      );
    });

    test('CASE-03-B-AFTER-DEADLINE: 0100 arriving after 4s timeout is discarded and fenced from new session', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-CASE-03-B',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'excessive_delay';

      // R81-2: Production ObdSession owner manages attempt lifecycle and retirement
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      final session = container.read(obdSessionProvider.notifier);

      addTearDown(() async {
        await session.disconnect();
        container.dispose();
      });

      // Attempt 1 uses transport1 bound to ATTEMPT-01
      final transport1 = ScriptedCausalTransport(
        name: 'late_reply_test_t1',
        probe: probe,
        initialGeneration: 0, // connect() will advance to 1
        attemptId: 'ATTEMPT-01',
      );
      addTearDown(transport1.dispose);

      final sessionSub1 = bindSessionToProbe(
        container,
        probe,
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      addTearDown(sessionSub1.close);

      void Function()? releaseOldCallback;
      transport1.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100') && releaseOldCallback == null) {
          probe.record(
            kind: TraceEventKind.injectedFaultFired,
            component: 'transport',
            phase: '0100',
            command: '0100',
            attemptId: 'ATTEMPT-01',
            generation: 1,
            details: {
              'type': 'excessive_delay',
              'generation': 1,
              'attemptId': 'ATTEMPT-01',
            },
          );
          final capturedGen = t.connectionGeneration;
          // Capture the old generation's reply callback
          releaseOldCallback = () {
            t.sendReply('41 00 BE 1F B8 10\r\n>', forGeneration: capturedGen);
          };
        } else {
          t.defaultAnswer(cmd);
        }
      };

      // 1. Initial attempt: 0100 times out at 4s boundary via session owner
      final connectOk1 = await session.connectForTest(
        transport1,
        TransportKind.bluetoothClassic,
      );
      expect(
        connectOk1,
        isFalse,
        reason: 'Initial connection must fail due to 4s timeout on 0100',
      );
      expect(probe.firstTerminalCause, 'HandshakeTimeout');
      expect(probe.failedStepCommand, '0100');
      expect(probe.failedStepNote, InitNote.timedOut);
      expect(releaseOldCallback, isNotNull, reason: 'Old request was received and captured');

      // 2. Retire the first attempt on the session owner
      sessionSub1.close();
      await session.disconnect();
      expect(transport1.isConnected, isFalse);
      expect(session.generation, 2, reason: 'Disconnect advances session generation to 2');

      // 3. R81-2: Establish fresh attempt with new transport instance on the SAME session owner
      // Production ObdSession increments generation on connect:
      // Session generation was 0 initially, 1 on Attempt 1 connect, 2 on disconnect, and will be 3 on Attempt 2 connect.
      final attempt2Gen = session.generation + 1; // 2 + 1 = 3
      probe.attemptId = 'ATTEMPT-02';
      probe.generation = attempt2Gen;
      final transport2 = ScriptedCausalTransport(
        name: 'late_reply_test_t2',
        probe: probe,
        initialGeneration: session.generation, // connect() will advance to attempt2Gen (3)
        attemptId: 'ATTEMPT-02',
      );
      addTearDown(transport2.dispose);

      final sessionSub2 = bindSessionToProbe(
        container,
        probe,
        attemptId: 'ATTEMPT-02',
        generation: attempt2Gen,
      );
      addTearDown(sessionSub2.close);

      final connectOk2 = await session.connectForTest(
        transport2,
        TransportKind.bluetoothClassic,
      );
      expect(connectOk2, isTrue, reason: 'Fresh session attempt on same owner must establish clean connection');
      expect(session.client, isNotNull);
      expect(session.client!.isInitialized, isTrue);
      expect(transport2.isConnected, isTrue);
      expect(session.generation, attempt2Gen);
      expect(transport2.connectionGeneration, attempt2Gen);

      // 4. Release old callback while new session attempt (Attempt 2) is active
      releaseOldCallback!();

      // 5. Verify old event was safely fenced at transport boundary:
      expect(
        probe.secondaryCleanupOutcome,
        'StaleGenerationDiscarded',
        reason: 'Late reply from prior generation must be rejected at transport boundary',
      );

      // 6. R81-2: Verify new attempt state, dispatch, and numerical polling are unpoisoned:
      // Must assert new attempt (session.client) did NOT take 'BE 1F B8 10' as its reply,
      // and smoothly obtains 010D (50 km/h)
      final speedReply = await session.client!.send('010D');
      expect(speedReply.isSuccess, isTrue);
      expect(
        speedReply.rawLines.any((l) => l.contains('BE 1F B8 10')),
        isFalse,
        reason: 'New attempt must not take stale Attempt 1 response (BE 1F B8 10) as its reply',
      );
      expect(
        speedReply.rawLines,
        contains('41 0D 32'),
        reason: 'New attempt must smoothly obtain genuine 50 km/h response',
      );

      // 7. Verify probe record generation consistency:
      // Discarded Attempt 1 event must have generation == 1 in both top-level and details
      final staleRecord = probe.records.firstWhere(
        (r) =>
            r.kind == TraceEventKind.secondaryErrorObserved &&
            r.details['outcome'] == 'StaleGenerationDiscarded',
      );
      expect(staleRecord.generation, 1);
      expect(staleRecord.attemptId, 'ATTEMPT-01');
      expect(staleRecord.details['generation'], 1);
      expect(staleRecord.details['attemptId'], 'ATTEMPT-01');

      // Records from attempt 2 must have record.generation == attempt2Gen (both top-level and details)
      final attempt2Records = probe.records.where((r) => r.attemptId == 'ATTEMPT-02').toList();
      expect(attempt2Records, isNotEmpty);
      for (final r in attempt2Records) {
        expect(r.generation, attempt2Gen, reason: 'Attempt 2 records must have generation == $attempt2Gen');
        if (r.details.containsKey('generation')) {
          expect(r.details['generation'], attempt2Gen, reason: 'Details generation must match top-level');
        }
      }

      // Positive control assertions (R81-1 / R81-2):
      // Verify Attempt 2 genuine initStepStarted and initStepCompleted were received by session observer
      expect(
        attempt2Records.any((r) => r.kind == TraceEventKind.initStepStarted),
        isTrue,
        reason: 'Attempt 2 must record genuine initStepStarted events via session observer',
      );
      expect(
        attempt2Records.any((r) => r.kind == TraceEventKind.initStepCompleted),
        isTrue,
        reason: 'Attempt 2 must record genuine initStepCompleted events via session observer',
      );
      expect(
        attempt2Records.where((r) => r.kind == TraceEventKind.initStepCompleted).length,
        greaterThanOrEqualTo(10),
        reason: 'Attempt 2 must record completed handshake steps through session observer',
      );

      // Verify no ATTEMPT-01 records were generated during Attempt 2
      final attempt1RecordsDuringAttempt2 = probe.records.where(
        (r) => r.attemptId == 'ATTEMPT-01' && r.kind == TraceEventKind.initStepStarted && r.generation > 1,
      );
      expect(
        attempt1RecordsDuringAttempt2,
        isEmpty,
        reason: 'Attempt 1 subscription must not record events for Attempt 2',
      );

      validateSubCaseExecution(
        subCaseSpec: getSubCaseSpec('CASE-03-B-AFTER-DEADLINE'),
        probe: probe,
        connectOk: connectOk1,
        attemptId: 'ATTEMPT-01',
      );
    });

    test('CASE-03-C-CHUNKED-LITERAL: 0100 split across fragmented chunks reassembles cleanly', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-CASE-03-C',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'fragmented_delivery';

      final transport = ScriptedCausalTransport(name: 'chunked_test', probe: probe);
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100')) {
          probe.record(
            kind: TraceEventKind.injectedFaultFired,
            component: 'transport',
            phase: '0100',
            command: '0100',
            details: {'type': 'fragmented_delivery'},
          );
          // Send response in fragmented chunks across classic RFCOMM stream (awaitable)
          t.sendChunks([
            '41 ',
            '00 BE ',
            '1F B8',
            ' 10\r',
            '\n>'
          ], interval: const Duration(milliseconds: 15));
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final connectOk = await client.connect();
      expect(connectOk, isTrue);
      expect(client.isInitialized, isTrue);
      expect(client.protocolDescription, isNotEmpty);

      validateSubCaseExecution(
        subCaseSpec: getSubCaseSpec('CASE-03-C-CHUNKED-LITERAL'),
        probe: probe,
        connectOk: connectOk,
      );
    });
  });

  group('CASE-04-HEALTHY-CONTROL', () {
    test('CASE-04-A-FULL-CYCLE: Nominal handshake, 13.9V ATRV, 0100, PollingEngine speed reading, and clean closure', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-CASE-04-A',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.injectedFault = 'none';

      final transport = ScriptedCausalTransport(
        name: 'nominal_test',
        probe: probe,
        initialVoltage: '13.9V',
      );
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      final connectOk = await client.connect();
      expect(connectOk, isTrue);
      expect(client.isInitialized, isTrue);
      expect(client.batteryVoltage, 13.9);

      // R81-2: Connect real PollingEngine and obtain a genuine vehicleSpeed reading
      final engine = PollingEngine(client)..setActivePids([PidLibrary.vehicleSpeed]);
      addTearDown(() async {
        if (engine.isRunning) await engine.stop();
        await engine.dispose();
      });

      engine.start();
      expect(engine.isRunning, isTrue);

      final snapshot = await engine.snapshots.firstWhere(
        (s) => s.readings.containsKey(PidLibrary.vehicleSpeed.id),
      );
      final reading = snapshot.readings[PidLibrary.vehicleSpeed.id]!;
      expect(reading.value, 50.0); // 0x32 = 50 km/h
      expect(reading.pid.units, 'km/h');

      // Gracefully stop engine and close client
      await engine.stop();
      expect(engine.isRunning, isFalse);
      await engine.dispose();

      await client.disconnect();
      expect(transport.isConnected, isFalse);
      expect(client.isInitialized, isFalse);

      validateSubCaseExecution(
        subCaseSpec: getSubCaseSpec('CASE-04-A-FULL-CYCLE'),
        probe: probe,
        connectOk: connectOk,
      );
    });

    test('CASE-04-B-OBSERVER-TX-EQUIVALENCE: Fixed demand traffic is identical with probe/observer enabled vs disabled', () async {
      // R81-2: Fixed demand sequence: handshake + query 0100, 010C, 010D, then disconnect

      // Run A: Observer / Probe ENABLED
      final probeA = Issue106TraceProbe(
        runId: 'RUN-CASE-04-B-OBSERVED',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      final transportA = ScriptedCausalTransport(
        name: 'tx_equiv_observed',
        probe: probeA,
      );
      final clientA = Elm327Client(transportA);
      final subA = clientA.initProgress.listen(probeA.observeInitProgress);

      addTearDown(() async {
        await subA.cancel();
        await clientA.dispose();
        await transportA.dispose();
      });

      final okA = await clientA.connect();
      expect(okA, isTrue);
      await clientA.send('0100');
      await clientA.send('010C');
      await clientA.send('010D');
      await clientA.disconnect();
      final txA = List<String>.from(transportA.writtenCommands);

      // Run B: Observer / Probe DISABLED
      final transportB = ScriptedCausalTransport(
        name: 'tx_equiv_baseline',
        probe: null,
      );
      final clientB = Elm327Client(transportB);

      addTearDown(() async {
        await clientB.dispose();
        await transportB.dispose();
      });

      final okB = await clientB.connect();
      expect(okB, isTrue);
      await clientB.send('0100');
      await clientB.send('010C');
      await clientB.send('010D');
      await clientB.disconnect();
      final txB = List<String>.from(transportB.writtenCommands);

      // Verify TX equivalence
      expect(txA, isNotEmpty);
      expect(
        txA,
        equals(txB),
        reason: 'Observer presence must have zero side-effects on TX wire transmission',
      );
    });
  });

  group('Mutations & Negative Controls (M106-01 ~ M106-04)', () {
    test('M106-01: First terminal cause cannot be overwritten by secondary cleanup', () {
      final probe = Issue106TraceProbe(
        runId: 'RUN-M106-01',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      probe.record(
        kind: TraceEventKind.streamDoneObserved,
        component: 'transport',
        phase: 'rx',
        details: {'cause': 'StreamDone'},
      );
      expect(probe.firstTerminalCause, 'StreamDone');

      // Routine cleanup started event occurs
      probe.record(
        kind: TraceEventKind.cleanupStarted,
        component: 'transport',
        phase: 'disconnect',
      );

      // Subsequent actual cleanup error event
      probe.recordCleanupError('CleanupSocketClosed');

      // Verify firstTerminalCause remains intact and secondary error is preserved
      expect(probe.firstTerminalCause, 'StreamDone');
      expect(probe.cleanupError, 'CleanupSocketClosed');
      expect(probe.secondaryCleanupOutcome, 'CleanupSocketClosed');
    });

    test('M106-02: Fixed deadline bounding prevents timer drift or budget refresh', () async {
      final transport = ScriptedCausalTransport(name: 'deadline_drift_check');
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      // Hook 0100 to never answer: must fail strictly within 4000ms deadline,
      // not drifting or granting an additional 4000ms.
      transport.onCommandHook = (cmd, t) {
        final normalized = cmd.toUpperCase().replaceAll(' ', '');
        if (normalized.startsWith('0100')) {
          // Stay silent
        } else {
          t.defaultAnswer(cmd);
        }
      };

      final sw = Stopwatch()..start();
      final ok = await client.connect();
      sw.stop();

      expect(ok, isFalse);
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(3800));
      expect(
        sw.elapsedMilliseconds,
        lessThan(6500),
        reason: 'Must fail within fixed 4s budget without unexpected refresh',
      );
    });

    test('M106-03: Retired client rejects wire dispatch without sending new requests', () async {
      final transport = ScriptedCausalTransport(name: 'retire_check');
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      await client.connect();
      await client.disconnect();

      expect(transport.isConnected, isFalse);
      final wireCountBefore = transport.writtenCommands.length;

      // R81-3: Await expectLater explicitly
      await expectLater(
        client.send('0100'),
        throwsA(isA<TransportException>()),
      );

      expect(
        transport.writtenCommands.length,
        wireCountBefore,
        reason: 'No command must reach the wire after disconnect',
      );
    });

    test('M106-04: Chunk without prompt does not trigger early completion', () async {
      final transport = ScriptedCausalTransport(name: 'no_prompt_check');
      final client = Elm327Client(transport);

      addTearDown(() async {
        await client.dispose();
        await transport.dispose();
      });

      await client.connect();

      // Send raw chunk without prompt
      transport.onCommandHook = (cmd, t) {
        if (cmd == '010C') {
          t.sendReply('41 0C 1A'); // missing \r\n>
        } else {
          t.defaultAnswer(cmd);
        }
      };

      // R81-3: Explicitly await expectLater so the 500ms timeout completes before cleanup
      await expectLater(
        client.send('010C', timeout: const Duration(milliseconds: 500)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('R81-3: Controlled sendChunks mid-stream abort and clean async join', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-R81-3-ABORT-JOIN',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      final transport = ScriptedCausalTransport(
        name: 'chunks_abort_test',
        probe: probe,
      );

      addTearDown(transport.dispose);

      await transport.connect();
      expect(transport.isConnected, isTrue);

      final receivedChunks = <String>[];
      final sub = transport.incoming.listen((bytes) {
        receivedChunks.add(String.fromCharCodes(bytes));
      });
      addTearDown(sub.cancel);

      // Start multi-chunk transmission with substantial interval (5 chunks, 100ms each)
      final sendFuture = transport.sendChunks(
        ['chunk_0;', 'chunk_1;', 'chunk_2;', 'chunk_3;', 'chunk_4;'],
        interval: const Duration(milliseconds: 100),
      );

      // Ensure first chunk is emitted and interval timer is active
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(receivedChunks, isNotEmpty);
      expect(transport.activeTimersCount, greaterThan(0));
      expect(transport.activeAsyncOpsCount, greaterThan(0));

      // Trigger mid-stream disconnect/abort while chunks are in flight
      probe.record(
        kind: TraceEventKind.firstTerminalObserved,
        component: 'caller',
        phase: 'cancel',
        details: {'cause': 'CallerInitiated'},
      );
      final sw = Stopwatch()..start();
      await transport.disconnect();
      sw.stop();

      // Ensure sendFuture resolves promptly (unblocked by canceller, joined by disconnect)
      await sendFuture;

      // Assert clean state invariants:
      // 1. Disconnect completes quickly (not waiting for full 500ms duration)
      expect(sw.elapsedMilliseconds, lessThan(250),
          reason: 'Disconnect must cleanly unblock chunk timers without waiting for full schedule');
      // 2. No active timers remain
      expect(transport.activeTimersCount, 0,
          reason: 'All active interval timers must be cancelled');
      // 3. No active async ops remain
      expect(transport.activeAsyncOpsCount, 0,
          reason: 'All active async operations must be cleanly joined');
      // 4. Remaining chunks after abort are never emitted
      expect(receivedChunks.length, lessThan(5),
          reason: 'Chunks scheduled after abort must be safely suppressed');
      // 5. Probe records clean lifecycle
      expect(probe.firstTerminalCause, 'CallerInitiated');
    });

    test('R84-01: Permanent dispose restores stream completion and in-flight chunk join', () async {
      final probe = Issue106TraceProbe(
        runId: 'RUN-R84-01-DISPOSE-JOIN',
        attemptId: 'ATTEMPT-01',
        generation: 1,
      );
      final transport = ScriptedCausalTransport(
        name: 'regression_dispose_join',
        probe: probe,
      );
      addTearDown(() async {
        if (!transport.isDisposed) {
          await transport.dispose();
        }
      });

      await transport.connect();
      expect(transport.isConnected, isTrue);

      bool incomingDone = false;
      bool connChangesDone = false;
      transport.incoming.listen(null, onDone: () => incomingDone = true);
      transport.connectionChanges.listen(null, onDone: () => connChangesDone = true);

      // Start multi-chunk transmission with 100ms interval
      final sendFuture = transport.sendChunks(
        ['chunk_0;', 'chunk_1;', 'chunk_2;', 'chunk_3;'],
        interval: const Duration(milliseconds: 100),
      );

      // Let chunk 0 be sent
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(transport.activeTimersCount, greaterThan(0));
      expect(transport.activeAsyncOpsCount, greaterThan(0));

      bool sendCompleted = false;
      unawaited(sendFuture.then((_) => sendCompleted = true));

      // Call permanent dispose()
      final sw = Stopwatch()..start();
      await transport.dispose();
      sw.stop();

      // Assert completion immediately upon dispose() return, before any secondary await
      expect(
        sendCompleted,
        isTrue,
        reason: 'In-flight chunk operation must already be cleanly settled when dispose() returns',
      );
      expect(incomingDone, isTrue, reason: 'incoming stream must be closed on dispose');
      expect(connChangesDone, isTrue, reason: 'connectionChanges stream must be closed on dispose');
      expect(transport.activeTimersCount, 0, reason: 'Timers must be cleared');
      expect(transport.activeAsyncOpsCount, 0, reason: 'Async ops must be cleared');
      expect(transport.isDisposed, isTrue);
      expect(transport.isConnected, isFalse);
      expect(sw.elapsedMilliseconds, lessThan(250), reason: 'Dispose must cancel chunk interval without waiting full duration');

      // Secondary join for error propagation/clean exit
      await sendFuture;
    });
  });
}
