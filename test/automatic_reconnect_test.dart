/// One automatic reconnect after the adapter stops answering (#112).
///
/// Three exports from ICSolution "ELM327 v1.5" adapters on Bluetooth Classic
/// ended the same way: a command written, no byte back, the probe unanswered,
/// the session dropped — and every time the user's own tap on reconnect
/// worked. The session now makes that tap once by itself, and only when doing
/// so cannot be wrong: the same remembered adapter, a session that had settled,
/// at most twice in ten minutes, in the foreground, and never over something
/// the user did meanwhile.
///
/// Most cases drive the drop the way `Elm327Client` reports it, through
/// `onConnectionLost`, against a session whose reconnect goes through the real
/// `_connect`. The last group runs a real silence end to end over a loopback
/// Wi-Fi socket, through the production `connectWifi` and
/// `reconnectRememberedAdapter`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transcript_store.dart';
import 'package:torque_obd/obd/transport/demo_transport.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/pid_registry.dart';
import 'package:torque_obd/state/settings.dart';

const _adapter = LastAdapter(
  id: '00:1D:A5:68:98:8B',
  name: 'OBDII',
  kind: TransportKind.bluetoothClassic,
);

const _droppedSentence =
    'The adapter stopped responding and the connection has been dropped.';

/// A session whose remembered-adapter reconnect is observable and scriptable.
///
/// The override still goes through `connectForTest`, so the real `_connect`
/// claims its generation exactly as `connectClassic` would; only the
/// transport is chosen here, because a host test cannot open RFCOMM.
class _Session extends ObdSession {
  final reconnects = <LastAdapter>[];

  /// What the next reconnect connects through. Null refuses the connection.
  ObdTransport Function()? nextTransport = () => DemoTransport();

  Future<bool>? lastReconnect;

  @override
  Future<bool> reconnectRememberedAdapter(LastAdapter adapter) {
    reconnects.add(adapter);
    final make = nextTransport;
    return lastReconnect = connectForTest(
      make == null ? _RefusingTransport() : make(),
      adapter.kind,
      adapter: adapter,
    );
  }
}

/// Refuses the link the way a Bluetooth Classic cascade does when every tier
/// fails.
class _RefusingTransport extends BaseObdTransport {
  @override
  TransportKind get kind => TransportKind.bluetoothClassic;

  @override
  String get displayName => 'OBDII';

  @override
  Future<void> connect() async => throw const TransportException(
    'Every connection method was refused.',
    issue: TransportIssue.classicAllTiersRefused,
  );

  @override
  Future<void> disconnect() async => setConnected(false);

  @override
  Future<void> write(List<int> data) async {}
}

/// A simulator whose link only opens when the test says so, to hold an
/// attempt in flight.
class _HeldTransport extends DemoTransport {
  final gate = Completer<void>();

  /// Every command written, so a test can say none went out.
  final written = <String>[];

  @override
  Future<void> connect() async {
    await gate.future;
    await super.connect();
  }

  @override
  Future<void> write(List<int> data) async {
    written.add(ascii.decode(data, allowInvalid: true).trim());
    await super.write(data);
  }
}

/// Holds the vehicle-boundary invalidation a new connection awaits before it
/// publishes its own state, when [gate] is set.
class _GatedProfile extends VehicleProfileController {
  static Completer<void>? gate;

  @override
  Future<void> invalidateForVehicleBoundary() async {
    await super.invalidateForVehicleBoundary();
    await gate?.future;
  }
}

/// A simulator that takes a fault-code clear and never answers it, so the
/// clear is still on the wire when the link goes.
class _SwallowsClearTransport extends DemoTransport {
  bool clearSent = false;

  @override
  Future<void> write(List<int> data) async {
    if (ascii.decode(data, allowInvalid: true).trim().toUpperCase() == '04') {
      clearSent = true;
      return;
    }
    await super.write(data);
  }
}

/// A simulator that reports a low-voltage reset to the handshake's `0100`, the
/// way an adapter browning out during the attempt does.
class _ResetsAtHandshake extends DemoTransport {
  @override
  Future<void> write(List<int> data) async {
    if (ascii.decode(data, allowInvalid: true).trim().toUpperCase() == '0100') {
      Timer(Duration.zero, () => emitBytes(ascii.encode('LV RESET\r\r>')));
      return;
    }
    await super.write(data);
  }
}

/// A simulator that answers a fault-code clear, and says whether one was sent.
class _RecordsClearTransport extends DemoTransport {
  bool clearSent = false;

  @override
  Future<void> write(List<int> data) async {
    if (ascii.decode(data, allowInvalid: true).trim().toUpperCase() == '04') {
      clearSent = true;
    }
    await super.write(data);
  }
}

/// A simulator whose link takes as long as the test says to close, to hold a
/// teardown open.
class _SlowToCloseTransport extends DemoTransport {
  final release = Completer<void>();

  @override
  Future<void> disconnect() async {
    await release.future;
    await super.disconnect();
  }
}

Future<void> _eventually(
  bool Function() condition, {
  String? reason,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail(reason ?? 'condition did not become true before $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// Long enough for an unwanted attempt to have started and published.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 300));

/// Every field a screen can render, so "the same failure" means all of them.
List<Object?> _fields(ObdConnectionState s) => [
  s.phase,
  s.kind,
  s.deviceName,
  s.protocol,
  s.requestedProtocol,
  s.protocolNumber,
  s.simulatedEvidence,
  s.detail,
  s.batteryVoltage,
  s.error,
  s.issue,
  s.issueStep,
  s.transportIssue,
  s.activity,
  s.initSteps.length,
];

final class _Rig {
  _Rig(this.container, this.session);

  final ProviderContainer container;
  final _Session session;
  final states = <ObdConnectionState>[];
  Duration now = Duration.zero;

  ObdConnectionState get state => container.read(obdSessionProvider);

  Future<void> connect({
    ObdTransport? transport,
    TransportKind kind = TransportKind.bluetoothClassic,
    LastAdapter? adapter = _adapter,
  }) async {
    expect(
      await session.connectForTest(
        transport ?? DemoTransport(),
        kind,
        adapter: adapter,
      ),
      isTrue,
    );
  }

  /// What `Elm327Client` does once its probe has gone unanswered, or, with
  /// another [cause], once the link went some other way.
  void dropLink([
    ConnectionLossCause cause = ConnectionLossCause.adapterSilent,
  ]) => session.client!.reportConnectionLostForTest(cause);

  /// The notes in what the export button would hand over right now.
  Iterable<String> get exportedNotes => session
      .exportableRecord!
      .transcript
      .entries
      .map((e) => e.note)
      .whereType<String>();

  Iterable<String> get notes =>
      session.client!.transcript.entries.map((e) => e.note).whereType<String>();
}

void _background(TestWidgetsFlutterBinding binding) => binding
  ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
  ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
  ..handleAppLifecycleStateChanged(AppLifecycleState.paused);

/// Back to the foreground the way the platform reports it; `resumed` straight
/// after `paused` is not a transition the lifecycle listener acts on.
void _foregroundAgain(TestWidgetsFlutterBinding binding) => binding
  ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
  ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
  ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);

Future<_Rig> _rig({LastAdapter? remembered = _adapter}) async {
  SharedPreferences.setMockInitialValues({
    if (remembered != null) 'last_adapter_v1': remembered.encode(),
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      obdSessionProvider.overrideWith(_Session.new),
      vehicleProfileProvider.overrideWith(_GatedProfile.new),
    ],
  );
  addTearDown(container.dispose);
  _GatedProfile.gate = null;
  final session = container.read(obdSessionProvider.notifier) as _Session;
  final rig = _Rig(container, session);
  session.automaticReconnectClock = () => rig.now;
  container.listen(obdSessionProvider, (_, next) => rig.states.add(next));
  return rig;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  tearDown(() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  group('a settled session that stops answering', () {
    test('is reconnected once, by itself, and says so', () async {
      final rig = await _rig();
      await rig.connect();
      rig.now += const Duration(seconds: 11);
      final lost = rig.session.client;

      rig.dropLink();
      // The drop is still reported first, exactly as before.
      expect(rig.state.phase, ConnectionPhase.failed);
      expect(rig.state.issue, ObdConnectionIssue.adapterStoppedResponding);

      await _eventually(() => rig.state.isConnected);
      expect(rig.session.reconnects, hasLength(1));
      expect(rig.session.reconnects.single.encode(), _adapter.encode());
      expect(rig.session.client, isNot(same(lost)));
      expect(
        rig.states.where(
          (s) =>
              s.isBusy &&
              s.activity == ObdConnectionActivity.reconnectingAutomatically,
        ),
        isNotEmpty,
        reason: 'the wait has to say why a connection started by itself',
      );
      expect(rig.state.activity, isNull);
      expect(rig.state.error, isNull);
      expect(rig.notes, contains(startsWith('Automatic reconnect 1 of 2')));
      expect(
        rig.notes,
        contains(contains('Connection event: adapter link dropped')),
        reason: 'the export has to carry why the previous session ended',
      );

      await _settle();
      expect(rig.session.reconnects, hasLength(1));
    });

    test('is busy from the moment the attempt starts', () async {
      // The drop leaves the screen on `failed`, and the new connection only
      // publishes its own state after awaits of its own. In between, an
      // Android Auto lease would find the session neither connected nor busy
      // and start a second reconnect to the same adapter.
      final rig = await _rig();
      await rig.connect();
      rig.now += const Duration(seconds: 11);
      final held = Completer<void>();
      _GatedProfile.gate = held;
      addTearDown(() {
        if (!held.isCompleted) held.complete();
      });

      rig.dropLink();
      await _eventually(() => rig.session.reconnects.length == 1);
      await _settle();
      expect(rig.session.client, isNull, reason: 'still before the handshake');
      expect(rig.state.isBusy, isTrue);
      expect(
        rig.state.activity,
        ObdConnectionActivity.reconnectingAutomatically,
      );

      held.complete();
      await _eventually(() => rig.state.isConnected);
    });

    test(
      'a reconnect that fails ends on the failure the drop showed',
      () async {
        final rig = await _rig();
        await rig.connect();
        rig.now += const Duration(seconds: 11);
        rig.session.nextTransport = null;

        rig.dropLink();
        final dropped = rig.state;
        expect(dropped.issue, ObdConnectionIssue.adapterStoppedResponding);

        await _eventually(
          () =>
              rig.session.reconnects.length == 1 &&
              rig.session.lastReconnect != null &&
              !rig.state.isBusy,
        );
        await rig.session.lastReconnect;
        await _settle();
        expect(_fields(rig.state), _fields(dropped));
        expect(rig.state.error, _droppedSentence);
        // Not even for a frame: the attempt's own refusal is a reason for the
        // transcript, not a second failure on screen.
        expect(
          rig.states.where((s) => s.phase == ConnectionPhase.failed),
          everyElement(
            predicate<ObdConnectionState>(
              (s) => s.issue == ObdConnectionIssue.adapterStoppedResponding,
            ),
          ),
        );
      },
    );

    test('a reconnect that fails leaves the dropped session as the record, '
        'in memory and on disk', () async {
      // The attempt's teardown filed its own dozen lines over the session that
      // stopped answering, while the screen went back to that session's
      // failure: the export from that screen was the wrong session.
      final dir = Directory.systemTemp.createTempSync('auto-reconnect-record');
      addTearDown(() => dir.deleteSync(recursive: true));
      TranscriptStore store() => TranscriptStore(directory: () async => dir);
      final rig = await _rig();
      rig.session.transcriptStore = store();
      await rig.connect();
      rig.now += const Duration(seconds: 11);
      rig.session.nextTransport = null;
      rig.session.client!.transcript.recordNote('the session that dropped');
      final header = rig.session.exportableRecord!.header;

      rig.dropLink();
      await _eventually(() => rig.session.reconnects.length == 1);
      expect(await rig.session.lastReconnect, isFalse);
      await _settle();
      await rig.session.drainTranscriptSnapshotsForTest();

      expect(rig.exportedNotes, contains('the session that dropped'));
      expect(
        rig.exportedNotes,
        contains('Automatic reconnect 1 of 2 did not connect'),
      );
      expect(
        rig.exportedNotes,
        contains(startsWith('Reconnect attempt, last')),
        reason: 'the attempt is kept, quoted, at the end',
      );
      expect(rig.session.exportableRecord!.header, header);
      final stored = await store().load();
      expect(stored, isNotNull);
      // Not just a line the attempt quoted from it: the note only the
      // restored record carries.
      expect(
        stored!.body,
        contains('Automatic reconnect 1 of 2 did not connect'),
      );
      expect(stored.header, header);
    });

    test('a reconnect that loses its own link before connecting ends on the '
        "drop's failure", () async {
      // An `LV RESET` mid-handshake fires the attempt's own connection-lost
      // callback. That moved the generation, which read as somebody else
      // taking over, so the drop's screen was never put back and a failure
      // carrying the reconnecting line stayed up.
      final rig = await _rig();
      await rig.connect();
      rig.now += const Duration(seconds: 11);
      final held = _HeldTransport();
      rig.session.nextTransport = () => held;

      rig.dropLink();
      final dropped = rig.state;
      await _eventually(
        () =>
            rig.state.activity ==
                ObdConnectionActivity.reconnectingAutomatically &&
            rig.session.client != null,
      );
      rig.session.client!.reportConnectionLostForTest(
        ConnectionLossCause.adapterError,
      );
      expect(
        _fields(rig.state),
        _fields(dropped),
        reason: 'back on the drop at once, not when the attempt unwinds',
      );
      held.gate.complete();
      expect(await rig.session.lastReconnect, isFalse);
      await _settle();

      expect(_fields(rig.state), _fields(dropped));
      expect(
        rig.states.where((s) => s.phase == ConnectionPhase.failed),
        everyElement(predicate<ObdConnectionState>((s) => s.activity == null)),
        reason: 'no failure may carry the reconnecting line',
      );
      expect(rig.session.reconnects, hasLength(1));
      expect(rig.session.client, isNull);
      expect(
        rig.exportedNotes,
        contains('Automatic reconnect 1 of 2 did not connect'),
      );
    });
  });

  group('a reconnect that resets during its handshake', () {
    test('leaves none of its handshake on the drop it put back', () async {
      // The client schedules the connection-lost callback, then completes
      // the `0100` that carried the reset; the handshake goes on emitting
      // failed and skipped steps until the teardown cancels the listener,
      // several awaits later. The drop's screen must not collect them.
      final rig = await _rig();
      await rig.connect();
      rig.now += const Duration(seconds: 11);
      rig.session.nextTransport = _ResetsAtHandshake.new;

      rig.dropLink();
      final dropped = rig.state;
      final afterDrop = rig.states.length;
      await _eventually(() => rig.session.reconnects.length == 1);
      expect(await rig.session.lastReconnect, isFalse);
      await _settle();

      expect(_fields(rig.state), _fields(dropped));
      // Not even for a moment: the attempt's end puts the failure back once
      // more, which would hide steps that had landed on it in between.
      expect(
        rig.states
            .skip(afterDrop)
            .where((s) => s.phase == ConnectionPhase.failed),
        everyElement(
          predicate<ObdConnectionState>(
            (s) => identical(s.initSteps, dropped.initSteps),
          ),
        ),
      );
    });
  });

  group('is bounded', () {
    test('two automatic reconnects in ten minutes, then the failure', () async {
      final rig = await _rig();
      await rig.connect();

      for (var drop = 1; drop <= 2; drop++) {
        rig.now += const Duration(seconds: 11);
        rig.dropLink();
        await _eventually(
          () => rig.state.isConnected && rig.session.reconnects.length == drop,
        );
      }

      rig.now += const Duration(seconds: 11);
      rig.dropLink();
      await _settle();
      expect(rig.session.reconnects, hasLength(2));
      expect(rig.state.phase, ConnectionPhase.failed);
      expect(rig.state.issue, ObdConnectionIssue.adapterStoppedResponding);

      // The window rolls rather than counting for the life of the process:
      // the user reconnects by hand, and a drop ten minutes after the first
      // automatic attempt earns one again.
      await rig.connect();
      rig.now = const Duration(seconds: 11) + const Duration(minutes: 10);
      rig.dropLink();
      await _eventually(
        () => rig.state.isConnected && rig.session.reconnects.length == 3,
      );
    });

    test('a failed attempt counts toward the two', () async {
      final rig = await _rig();
      rig.session.nextTransport = null;
      for (var drop = 1; drop <= 2; drop++) {
        await rig.connect();
        rig.now += const Duration(seconds: 11);
        rig.dropLink();
        await _eventually(() => rig.session.reconnects.length == drop);
        expect(await rig.session.lastReconnect, isFalse);
        await _settle();
        expect(rig.state.phase, ConnectionPhase.failed);
      }

      await rig.connect();
      rig.now += const Duration(seconds: 11);
      rig.dropLink();
      await _settle();
      expect(rig.session.reconnects, hasLength(2));
    });

    test('a session that dies within ten seconds is not retried', () async {
      final rig = await _rig();
      await rig.connect();
      rig.now += const Duration(seconds: 9);

      rig.dropLink();
      await _settle();
      expect(rig.session.reconnects, isEmpty);
      expect(rig.state.phase, ConnectionPhase.failed);
      expect(rig.state.issue, ObdConnectionIssue.adapterStoppedResponding);
    });
  });

  group('the user wins', () {
    test(
      'a disconnect before the attempt starts leaves nothing to start',
      () async {
        final rig = await _rig();
        final slow = _SlowToCloseTransport();
        await rig.connect(transport: slow);
        rig.now += const Duration(seconds: 11);

        rig.dropLink();
        final disconnecting = rig.session.disconnect();
        slow.release.complete();
        await disconnecting;
        await _settle();

        expect(rig.session.reconnects, isEmpty);
        expect(rig.state.phase, ConnectionPhase.disconnected);
        expect(rig.state.error, isNull);
        expect(rig.session.client, isNull);
      },
    );

    test('a disconnect during the attempt is not answered with a failure, '
        'and leaves no session behind', () async {
      final rig = await _rig();
      await rig.connect();
      rig.now += const Duration(seconds: 11);
      final held = _HeldTransport();
      rig.session.nextTransport = () => held;

      rig.dropLink();
      await _eventually(
        () =>
            rig.state.isBusy &&
            rig.state.activity ==
                ObdConnectionActivity.reconnectingAutomatically &&
            rig.session.client != null,
      );
      await rig.session.disconnect();
      final afterTap = rig.states.length;
      // The link opens anyway, after the user has walked away from it — the
      // way a Bluetooth Classic tier that was already in flight does.
      held.gate.complete();
      expect(await rig.session.lastReconnect, isFalse);
      await _settle();

      expect(rig.session.reconnects, hasLength(1));
      expect(rig.state.phase, ConnectionPhase.disconnected);
      expect(rig.state.error, isNull);
      expect(
        rig.states
            .skip(afterTap)
            .where((s) => s.phase != ConnectionPhase.disconnected),
        isEmpty,
        reason: 'nothing may be published over the disconnect',
      );
      expect(rig.session.client, isNull);
      expect(held.isConnected, isFalse, reason: 'no zombie link');
      expect(
        held.written,
        isEmpty,
        reason: 'no handshake on a link nobody owns',
      );
    });

    test(
      'a cancel during the attempt keeps the dropped session as the record',
      () async {
        // The attempt's busy screen has a cancel button, which is a disconnect.
        // It ends on idle, and the export from idle must still be the session
        // that stopped answering, not an attempt nobody asked for.
        final dir = Directory.systemTemp.createTempSync(
          'auto-reconnect-cancel',
        );
        addTearDown(() => dir.deleteSync(recursive: true));
        TranscriptStore store() => TranscriptStore(directory: () async => dir);
        final rig = await _rig();
        rig.session.transcriptStore = store();
        await rig.connect();
        rig.now += const Duration(seconds: 11);
        final held = _HeldTransport();
        rig.session.nextTransport = () => held;
        rig.session.client!.transcript.recordNote('the session that dropped');

        rig.dropLink();
        await _eventually(
          () =>
              rig.state.activity ==
                  ObdConnectionActivity.reconnectingAutomatically &&
              rig.session.client != null,
        );
        await rig.session.disconnect();
        await rig.session.drainTranscriptSnapshotsForTest();
        expect(rig.exportedNotes, contains('the session that dropped'));
        expect(
          (await store().load())!.body,
          contains('the session that dropped'),
          reason: 'on disk too, before the attempt has unwound',
        );

        held.gate.complete();
        expect(await rig.session.lastReconnect, isFalse);
        await _settle();
        await rig.session.drainTranscriptSnapshotsForTest();
        expect(rig.state.phase, ConnectionPhase.disconnected);
        expect(
          rig.exportedNotes,
          contains('Automatic reconnect 1 of 2 did not connect'),
        );
        expect(
          (await store().load())!.body,
          contains('Automatic reconnect 1 of 2 did not connect'),
        );
      },
    );

    test('a connect during the attempt is the one that ends up live', () async {
      final rig = await _rig();
      await rig.connect();
      rig.now += const Duration(seconds: 11);
      final held = _HeldTransport();
      rig.session.nextTransport = () => held;

      rig.dropLink();
      await _eventually(
        () =>
            rig.state.activity ==
                ObdConnectionActivity.reconnectingAutomatically &&
            rig.session.client != null,
      );
      final chosen = DemoTransport();
      final tapped = rig.session.connectForTest(
        chosen,
        TransportKind.wifi,
        adapter: const LastAdapter(
          id: '192.168.0.10',
          name: 'Wi-Fi 192.168.0.10',
          kind: TransportKind.wifi,
          port: 35000,
        ),
      );
      final afterTap = rig.states.length;
      held.gate.complete();
      expect(await tapped, isTrue);
      await _settle();

      expect(rig.state.isConnected, isTrue);
      expect(rig.state.kind, TransportKind.wifi);
      expect(rig.session.client!.transport, same(chosen));
      expect(
        rig.states
            .skip(afterTap)
            .where((s) => s.phase == ConnectionPhase.failed),
        isEmpty,
        reason: 'the abandoned automatic attempt may not report over the tap',
      );
      expect(rig.session.reconnects, hasLength(1));
      expect(held.isConnected, isFalse);
    });
  });

  group('only in the foreground', () {
    test(
      'not when the app leaves while the drop is still tearing down',
      () async {
        // Checked once at the drop, the rule let a teardown that ends in a
        // platform Bluetooth close finish after the user had left, and the
        // cascade started behind them.
        final rig = await _rig();
        final slow = _SlowToCloseTransport();
        await rig.connect(transport: slow);
        rig.now += const Duration(seconds: 11);

        rig.dropLink();
        final dropped = rig.state;
        _background(binding);
        slow.release.complete();
        await _settle();

        expect(rig.session.reconnects, isEmpty);
        expect(_fields(rig.state), _fields(dropped));

        // Nor did it spend one of the two.
        _foregroundAgain(binding);
        expect(rig.session.isForeground, isTrue);
        for (var drop = 1; drop <= 2; drop++) {
          await rig.connect();
          rig.now += const Duration(seconds: 11);
          rig.dropLink();
          await _eventually(
            () =>
                rig.state.isConnected && rig.session.reconnects.length == drop,
          );
        }
      },
    );

    test(
      'an attempt that leaves before it has a record keeps the full header',
      () async {
        // Held in the vehicle-profile invalidation, before the attempt has made
        // its own record. Its connect's teardown has already re-rendered the
        // stored header without the client's facts; the captured one is what
        // the export and the disk must carry.
        final dir = Directory.systemTemp.createTempSync('auto-reconnect-early');
        addTearDown(() => dir.deleteSync(recursive: true));
        TranscriptStore store() => TranscriptStore(directory: () async => dir);
        final rig = await _rig();
        rig.session.transcriptStore = store();
        await rig.connect();
        rig.now += const Duration(seconds: 11);
        final header = rig.session.exportableRecord!.header;
        final held = Completer<void>();
        _GatedProfile.gate = held;
        addTearDown(() {
          if (!held.isCompleted) held.complete();
        });

        rig.dropLink();
        final dropped = rig.state;
        await _eventually(() => rig.session.reconnects.length == 1);
        await _settle();
        expect(rig.session.client, isNull, reason: 'still before the record');
        _background(binding);
        await rig.session.drainTranscriptSnapshotsForTest();
        expect(rig.session.exportableRecord!.header, header);
        expect((await store().load())!.header, header);

        held.complete();
        expect(await rig.session.lastReconnect, isFalse);
        await _settle();
        await rig.session.drainTranscriptSnapshotsForTest();
        expect(_fields(rig.state), _fields(dropped));
        expect(rig.session.exportableRecord!.header, header);
        expect((await store().load())!.header, header);
        expect(
          rig.exportedNotes,
          contains('Automatic reconnect 1 of 2 did not connect'),
        );
      },
    );

    test(
      'an attempt still connecting when the app leaves stands down',
      () async {
        final dir = Directory.systemTemp.createTempSync('auto-reconnect-pause');
        addTearDown(() => dir.deleteSync(recursive: true));
        TranscriptStore store() => TranscriptStore(directory: () async => dir);
        final rig = await _rig();
        rig.session.transcriptStore = store();
        await rig.connect();
        rig.now += const Duration(seconds: 11);
        final held = _HeldTransport();
        rig.session.nextTransport = () => held;
        rig.session.client!.transcript.recordNote('the session that dropped');

        rig.dropLink();
        final dropped = rig.state;
        await _eventually(
          () =>
              rig.state.activity ==
                  ObdConnectionActivity.reconnectingAutomatically &&
              rig.session.client != null,
        );
        _background(binding);
        // At once, not when the attempt has unwound: a user back by then
        // would find "reconnecting" and a cancel button on nothing.
        expect(_fields(rig.state), _fields(dropped));
        // And on disk before the attempt unwinds, in case the process is
        // killed in the meantime.
        await rig.session.drainTranscriptSnapshotsForTest();
        expect(
          (await store().load())!.body,
          contains('the session that dropped'),
        );
        expect(rig.exportedNotes, contains('the session that dropped'));
        // The link opens anyway, as a Bluetooth tier already in flight does.
        held.gate.complete();
        expect(await rig.session.lastReconnect, isFalse);
        await _settle();

        expect(_fields(rig.state), _fields(dropped));
        expect(rig.session.client, isNull);
        expect(
          held.isConnected,
          isFalse,
          reason: 'no link left open behind it',
        );
        expect(
          held.written,
          isEmpty,
          reason: 'not one byte of handshake after the app left',
        );
        expect(rig.exportedNotes, contains('the session that dropped'));
        expect(
          rig.exportedNotes,
          contains(contains('the automatic reconnect stands down')),
        );
      },
    );
  });

  group('is never attempted', () {
    test('for the simulator', () async {
      const demo = LastAdapter(
        id: 'demo',
        name: 'Demo',
        kind: TransportKind.demo,
      );
      final rig = await _rig(remembered: demo);
      await rig.connect(kind: TransportKind.demo, adapter: demo);
      rig.now += const Duration(seconds: 11);

      rig.dropLink();
      await _settle();
      expect(rig.session.reconnects, isEmpty);
      expect(rig.state.phase, ConnectionPhase.failed);
    });

    test('with no remembered adapter', () async {
      final rig = await _rig(remembered: null);
      await rig.connect();
      rig.now += const Duration(seconds: 11);

      rig.dropLink();
      await _settle();
      expect(rig.session.reconnects, isEmpty);
      expect(rig.state.phase, ConnectionPhase.failed);
    });

    test('when the remembered adapter is not the one that was lost', () async {
      final rig = await _rig(
        remembered: const LastAdapter(
          id: '00:1D:A5:00:00:01',
          name: 'OBDII',
          kind: TransportKind.bluetoothClassic,
        ),
      );
      await rig.connect();
      rig.now += const Duration(seconds: 11);

      rig.dropLink();
      await _settle();
      expect(rig.session.reconnects, isEmpty);
      expect(rig.state.phase, ConnectionPhase.failed);
    });

    test('for an adapter of another kind under the same id', () async {
      final rig = await _rig(
        remembered: LastAdapter(
          id: _adapter.id,
          name: _adapter.name,
          kind: TransportKind.bluetoothLe,
        ),
      );
      await rig.connect();
      rig.now += const Duration(seconds: 11);

      rig.dropLink();
      await _settle();
      expect(rig.session.reconnects, isEmpty);
    });

    test('after the transport closed', () async {
      // Unplugged, out of range or switched off: a cascade against nothing,
      // under a line saying the adapter stopped answering.
      final rig = await _rig();
      await rig.connect();
      rig.now += const Duration(seconds: 11);

      rig.dropLink(ConnectionLossCause.transportClosed);
      await _settle();
      expect(rig.session.reconnects, isEmpty);
      expect(rig.state.phase, ConnectionPhase.failed);
    });

    test('after an adapter error', () async {
      // `UNABLE TO CONNECT`, `LV RESET`: a new handshake meets it at `0100`.
      final rig = await _rig();
      await rig.connect();
      rig.now += const Duration(seconds: 11);

      rig.dropLink(ConnectionLossCause.adapterError);
      await _settle();
      expect(rig.session.reconnects, isEmpty);
      expect(rig.state.phase, ConnectionPhase.failed);
    });

    test('for the same Wi-Fi host on another port', () async {
      final rig = await _rig(
        remembered: const LastAdapter(
          id: '192.168.0.10',
          name: 'Wi-Fi 192.168.0.10',
          kind: TransportKind.wifi,
          port: 35001,
        ),
      );
      await rig.connect(
        kind: TransportKind.wifi,
        adapter: const LastAdapter(
          id: '192.168.0.10',
          name: 'Wi-Fi 192.168.0.10',
          kind: TransportKind.wifi,
          port: 35000,
        ),
      );
      rig.now += const Duration(seconds: 11);

      rig.dropLink();
      await _settle();
      expect(rig.session.reconnects, isEmpty);
    });

    test('while a fault-code clear is on the wire', () async {
      // The clear's verdict — it may have happened, do not send another — is
      // discarded once a new connection begins. The driver reads it first.
      final rig = await _rig();
      final adapter = _SwallowsClearTransport();
      await rig.connect(transport: adapter);
      rig.now += const Duration(seconds: 11);
      final clearing = rig.session.clearDtcs().then<Object?>(
        (outcome) => outcome,
        onError: (Object error) => error,
      );
      await _eventually(() => adapter.clearSent);

      rig.dropLink();
      await clearing;
      await _settle();
      expect(rig.session.reconnects, isEmpty);
      expect(rig.state.phase, ConnectionPhase.failed);
      expect(rig.state.issue, ObdConnectionIssue.adapterStoppedResponding);
    });

    test('after a clear that has already returned', () async {
      // The clear's future completes before `sendGlobal` restores `ATH0`, and
      // a `04` that times out with headers already on throws without a
      // resync, so the probe that ends the link can run after the clear has
      // returned. The session that sent one is what counts.
      final rig = await _rig();
      final adapter = _RecordsClearTransport();
      await rig.connect(transport: adapter);
      rig.now += const Duration(seconds: 11);
      await rig.session.clearDtcs();
      expect(adapter.clearSent, isTrue);

      rig.dropLink();
      await _settle();
      expect(rig.session.reconnects, isEmpty);
      expect(rig.state.phase, ConnectionPhase.failed);
    });

    test('from the background', () async {
      final rig = await _rig();
      await rig.connect();
      rig.now += const Duration(seconds: 11);
      _background(binding);
      expect(rig.session.isForeground, isFalse);

      rig.dropLink();
      await _settle();
      expect(rig.session.reconnects, isEmpty);
      expect(rig.state.phase, ConnectionPhase.failed);
    });
  });

  group('end to end over Wi-Fi', () {
    test('a socket that closes is not reconnected', () async {
      // The production cause, not a set one: an adapter switched off or out
      // of range reaches the session as a closed link, and that is not the
      // silent adapter this is for.
      final bridge = await _SimulatorBridge.start();
      addTearDown(bridge.close);
      final remembered = LastAdapter(
        id: InternetAddress.loopbackIPv4.address,
        name: 'Wi-Fi ${InternetAddress.loopbackIPv4.address}',
        kind: TransportKind.wifi,
        port: bridge.port,
      );
      SharedPreferences.setMockInitialValues({
        'last_adapter_v1': remembered.encode(),
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      var now = Duration.zero;
      session.automaticReconnectClock = () => now;

      expect(
        await session.connectWifi(host: remembered.id, port: remembered.port),
        isTrue,
      );
      now += const Duration(seconds: 11);
      bridge.closeFirst();

      await _eventually(
        () =>
            container.read(obdSessionProvider).phase == ConnectionPhase.failed,
        reason: 'the closed socket was not noticed',
      );
      await _settle();
      expect(bridge.connections, 1);
      expect(container.read(obdSessionProvider).isBusy, isFalse);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('a real silence is probed, dropped, and reconnected once', () async {
      final bridge = await _SimulatorBridge.start();
      addTearDown(bridge.close);
      final remembered = LastAdapter(
        id: InternetAddress.loopbackIPv4.address,
        name: 'Wi-Fi ${InternetAddress.loopbackIPv4.address}',
        kind: TransportKind.wifi,
        port: bridge.port,
      );
      SharedPreferences.setMockInitialValues({
        'last_adapter_v1': remembered.encode(),
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final session = container.read(obdSessionProvider.notifier);
      var now = Duration.zero;
      session.automaticReconnectClock = () => now;

      expect(
        await session.connectWifi(host: remembered.id, port: remembered.port),
        isTrue,
      );
      final lost = session.client;
      now += const Duration(seconds: 11);
      bridge.deafen();

      await _eventually(
        () =>
            container.read(obdSessionProvider).isConnected &&
            session.client != null &&
            !identical(session.client, lost),
        timeout: const Duration(seconds: 30),
        reason: 'the silent link was not reconnected',
      );
      expect(bridge.connections, 2);
      final notes = session.client!.transcript.entries
          .map((e) => e.note)
          .whereType<String>()
          .toList();
      expect(notes, contains(startsWith('Automatic reconnect 1 of 2')));
      expect(
        notes,
        contains(contains('Probe got no answer')),
        reason: 'the probe outcome is what #112 needs from the next export',
      );
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}

/// The shipped simulator behind a loopback socket, so the production Wi-Fi
/// path is what connects. [deafen] stops the first connection answering
/// anything while its socket stays open: the #112 shape, a write and then no
/// byte at all.
final class _SimulatorBridge {
  _SimulatorBridge._(this._server) {
    _server.listen(_accept);
  }

  static Future<_SimulatorBridge> start() async => _SimulatorBridge._(
    await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
  );

  final ServerSocket _server;
  final _sockets = <Socket>[];
  final _simulators = <DemoTransport>[];
  int connections = 0;
  bool _firstIsDeaf = false;

  int get port => _server.port;

  void deafen() => _firstIsDeaf = true;

  /// Closes the first connection from the adapter's side.
  void closeFirst() => _sockets.first.destroy();

  Future<void> _accept(Socket socket) async {
    final index = connections++;
    _sockets.add(socket);
    final simulator = DemoTransport();
    _simulators.add(simulator);
    await simulator.connect();
    bool deaf() => index == 0 && _firstIsDeaf;
    simulator.incoming.listen((bytes) {
      if (!deaf()) socket.add(bytes);
    });
    socket.listen(
      (data) {
        if (!deaf()) unawaited(simulator.write(data));
      },
      onError: (_) {},
      onDone: () => unawaited(simulator.disconnect()),
    );
  }

  Future<void> close() async {
    for (final socket in _sockets) {
      socket.destroy();
    }
    for (final simulator in _simulators) {
      await simulator.disconnect();
    }
    await _server.close();
  }
}
