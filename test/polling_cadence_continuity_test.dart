library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elapsed_clock.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

class _CadenceTransport extends BaseObdTransport {
  final List<void Function()> _pendingRpmReplies = [];
  final List<String> commands = [];
  bool gateRpm = false;
  bool autoReplyRpm = false;
  bool silenceNextRpm = false;
  int rpmRequestCount = 0;

  @override
  TransportKind get kind => TransportKind.bluetoothLe;

  @override
  String get displayName => 'cadence continuity fixture';

  @override
  Future<void> connect() async => setConnected(true);

  @override
  Future<void> disconnect() async => setConnected(false);

  @override
  Future<void> write(List<int> data) async {
    final command = ascii
        .decode(data, allowInvalid: true)
        .trim()
        .replaceAll(' ', '')
        .toUpperCase();
    commands.add(command);
    if (command == 'ATZ') {
      emitBytes(ascii.encode('ATZ\r'));
      await Future<void>.delayed(Duration.zero);
      emitBytes(ascii.encode('ELM327 v1.5\r>'));
      return;
    }
    if (command == '010C') {
      void reply() => emitBytes(ascii.encode('410C1AF8\r>'));
      if (!gateRpm) {
        reply();
      } else if (silenceNextRpm) {
        silenceNextRpm = false;
        rpmRequestCount++;
      } else if (autoReplyRpm) {
        rpmRequestCount++;
        reply();
      } else {
        rpmRequestCount++;
        _pendingRpmReplies.add(reply);
      }
      return;
    }
    final reply = switch (command) {
      'ATE0' ||
      'ATL0' ||
      'ATM0' ||
      'ATS0' ||
      'ATAT1' ||
      'ATST66' ||
      'ATSP0' ||
      'ATH0' ||
      'ATH1' ||
      'ATSH7E0' => 'OK',
      'ATI' => 'ELM327 v1.5',
      'AT@1' => 'cadence fixture',
      'ATRV' => '14.2V',
      'ATDP' => 'AUTO, ISO 15765-4 (CAN 11/500)',
      'ATDPN' => 'A6',
      'ATPPS' => '?',
      '0100' => '410000100000',
      '0120' => '4120A007B011',
      '0140' => '4140FED08410',
      '0160' => '416000000000',
      _ => 'NO DATA',
    };
    emitBytes(ascii.encode('$reply\r>'));
  }

  Future<void> waitForRpmRequestCount(int expected) async {
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (rpmRequestCount < expected && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(rpmRequestCount, greaterThanOrEqualTo(expected));
  }

  Future<void> waitForRpmRequest() async {
    final deadline = DateTime.now().add(const Duration(seconds: 6));
    while (_pendingRpmReplies.isEmpty && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(
      _pendingRpmReplies,
      isNotEmpty,
      reason: 'RPM request never arrived; commands: ${jsonEncode(commands)}',
    );
  }

  void replyToRpm() => _pendingRpmReplies.removeAt(0)();
}

Future<void> _waitForElapsed(PollingEngine engine, Duration expected) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (engine.current.readings[PidLibrary.engineRpm.id]?.receivedElapsed !=
          expected &&
      DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(
    engine.current.readings[PidLibrary.engineRpm.id]?.receivedElapsed,
    expected,
  );
}

void main() {
  test('pause time does not become the resumed PID cadence', () async {
    var elapsedMs = 1000;
    final clock = NativeElapsedCache(
      readMs: () async => elapsedMs,
      tick: () => Duration.zero,
    );
    final transport = _CadenceTransport();
    final client = Elm327Client(
      transport,
      commandTimeout: const Duration(milliseconds: 500),
    );
    addTearDown(client.dispose);
    expect(await client.connect(), isTrue);
    transport.gateRpm = true;

    final engine = PollingEngine(client, elapsedClock: clock);
    addTearDown(engine.dispose);
    engine
      ..setActivePids(const [
        PidLibrary.engineRpm,
      ], includeProfileDerivedInputs: false)
      ..start();
    engine.scheduler.fastModeEnabled = false;

    await transport.waitForRpmRequest();
    transport.replyToRpm();
    await _waitForElapsed(engine, const Duration(seconds: 1));

    elapsedMs = 2000;
    await transport.waitForRpmRequest();
    transport.replyToRpm();
    await _waitForElapsed(engine, const Duration(seconds: 2));
    expect(
      engine.current.readings[PidLibrary.engineRpm.id]?.observedInterval,
      const Duration(seconds: 1),
    );

    transport.autoReplyRpm = true;
    await engine.stop();
    transport.autoReplyRpm = false;

    elapsedMs = 62000;
    engine.start();
    await transport.waitForRpmRequest();
    transport.replyToRpm();
    await _waitForElapsed(engine, const Duration(seconds: 62));
    expect(
      engine.current.readings[PidLibrary.engineRpm.id]?.observedInterval,
      isNull,
      reason: 'the first answer after a pause only re-establishes continuity',
    );

    elapsedMs = 63000;
    await transport.waitForRpmRequest();
    transport.replyToRpm();
    await _waitForElapsed(engine, const Duration(seconds: 63));
    expect(
      engine.current.readings[PidLibrary.engineRpm.id]?.observedInterval,
      const Duration(seconds: 1),
      reason: 'cadence is measured again from two post-resume answers',
    );
  });

  test(
    'one timeout restarts cadence for every definition on the wire',
    () async {
      var elapsedMs = 1000;
      final clock = NativeElapsedCache(
        readMs: () async => elapsedMs,
        tick: () => Duration.zero,
      );
      final transport = _CadenceTransport();
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 500),
      );
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      transport.gateRpm = true;

      final sibling = PidLibrary.engineRpm.copyWith(
        name: 'Half RPM',
        shortName: 'Half RPM',
        equation: '((A*256)+B)/8',
        variant: 'half',
      );
      final engine = PollingEngine(client, elapsedClock: clock);
      addTearDown(engine.dispose);
      engine
        ..setActivePids([
          PidLibrary.engineRpm,
          sibling,
        ], includeProfileDerivedInputs: false)
        ..start();
      engine.scheduler.fastModeEnabled = false;

      await transport.waitForRpmRequest();
      transport.replyToRpm();
      await _waitForElapsed(engine, const Duration(seconds: 1));
      expect(
        engine.current.readings[sibling.id]?.receivedElapsed,
        const Duration(seconds: 1),
      );

      elapsedMs = 61000;
      transport.silenceNextRpm = true;
      final timedOutRequest = transport.rpmRequestCount + 1;
      await transport.waitForRpmRequestCount(timedOutRequest);
      await transport.waitForRpmRequest();
      transport.replyToRpm();
      await _waitForElapsed(engine, const Duration(seconds: 61));

      for (final id in [PidLibrary.engineRpm.id, sibling.id]) {
        final reading = engine.current.readings[id];
        expect(
          reading?.observedInterval,
          isNull,
          reason: 'the first answer after an interrupted wire restarts $id',
        );
        expect(reading?.maxAge, const Duration(seconds: 2));
      }

      elapsedMs = 62000;
      await transport.waitForRpmRequest();
      transport.replyToRpm();
      await _waitForElapsed(engine, const Duration(seconds: 62));
      for (final id in [PidLibrary.engineRpm.id, sibling.id]) {
        expect(
          engine.current.readings[id]?.observedInterval,
          const Duration(seconds: 1),
          reason: 'two clean answers establish the new cadence for $id',
        );
      }
    },
  );

  test('re-enabling an inactive PID restarts its cadence', () async {
    var elapsedMs = 1000;
    final clock = NativeElapsedCache(
      readMs: () async => elapsedMs,
      tick: () => Duration.zero,
    );
    final transport = _CadenceTransport();
    final client = Elm327Client(
      transport,
      commandTimeout: const Duration(milliseconds: 500),
    );
    addTearDown(client.dispose);
    expect(await client.connect(), isTrue);
    transport.gateRpm = true;

    final engine = PollingEngine(client, elapsedClock: clock);
    addTearDown(engine.dispose);
    engine
      ..setActivePids(const [
        PidLibrary.engineRpm,
      ], includeProfileDerivedInputs: false)
      ..start();
    engine.scheduler.fastModeEnabled = false;

    await transport.waitForRpmRequest();
    transport.replyToRpm();
    await _waitForElapsed(engine, const Duration(seconds: 1));

    engine.setActivePids(const [], includeProfileDerivedInputs: false);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    elapsedMs = 61000;
    engine.setActivePids(const [
      PidLibrary.engineRpm,
    ], includeProfileDerivedInputs: false);
    await transport.waitForRpmRequest();
    transport.replyToRpm();
    await _waitForElapsed(engine, const Duration(seconds: 61));

    expect(
      engine.current.readings[PidLibrary.engineRpm.id]?.observedInterval,
      isNull,
    );
  });
}
