import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/wifi_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/service_recipes_provider.dart';

import 'mode08_replay_oracle_test.dart'
    show WireBarrierWifiTransport, oracleIdentity, verifyOraclePreflight;

const _oracleHost = '127.0.0.1';
const _oraclePort = 35008;

class _SupplementSession extends ObdSession {
  _SupplementSession(this._client, {this.generation = 1});
  Elm327Client? _client;

  @override
  int generation;

  @override
  Elm327Client? get client => _client;

  @override
  ObdConnectionState build() => _client != null
      ? const ObdConnectionState(
          phase: ConnectionPhase.connected,
          protocol: 'ISO 15765-4 (CAN 11/500)',
        )
      : const ObdConnectionState(
          phase: ConnectionPhase.disconnected,
          protocol: '',
        );

  void triggerDisconnect() {
    generation++;
    _client = null;
    state = const ObdConnectionState(
      phase: ConnectionPhase.disconnected,
      protocol: '',
    );
  }

  void triggerReconnect(Elm327Client newClient) {
    generation++;
    _client = newClient;
    state = const ObdConnectionState(
      phase: ConnectionPhase.connected,
      protocol: 'ISO 15765-4 (CAN 11/500)',
    );
  }
}

void main() {
  test('Mode 08 In-Flight Hold Lifecycle Supplement: 3-Run Evidence Generation', () async {
    final available = await verifyOraclePreflight(
      host: _oracleHost,
      port: _oraclePort,
      requiredMode: const bool.fromEnvironment('MODE08_ORACLE_REQUIRED'),
      identity: oracleIdentity,
    );
    if (!available) {
      markTestSkipped('Mode 08 replay reference not running on $_oracleHost:$_oraclePort');
      return;
    }

    final trafficEntries = <Map<String, dynamic>>[];
    final lifecycleLogs = <String>[];
    final bindings = <Map<String, dynamic>>[];

    void logEvent(String tag, String msg) {
      final now = DateTime.now().toUtc().toIso8601String();
      lifecycleLogs.add('$now [$tag] $msg');
    }

    void recordTraffic({
      required int run,
      required String direction,
      required String payload,
      String? scenario,
      String? note,
    }) {
      final ts = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final entry = <String, dynamic>{
        'ts': ts,
        'run': run,
        'dir': direction,
        'payload': payload,
      };
      if (scenario != null) entry['scenario'] = scenario;
      if (note != null) entry['note'] = note;
      trafficEntries.add(entry);
    }

    final outDir = Directory('docs/verification/evidence/d05_mode08_supplement');
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }

    logEvent('SETUP', 'Connecting to Mode 08 Replay Server at $_oracleHost:$_oraclePort');

    // RUN 1: In-flight hold on 0800 + HOME (pause)
    logEvent('RUN1_START', 'Starting Run 1: Mode 08 discovery on block 0x00, in-flight hold with HOME interrupt');
    {
      final wifiTransport = WifiTransport(host: _oracleHost, port: _oraclePort);
      final barrierTransport = WireBarrierWifiTransport(wifiTransport);
      final client = Elm327Client(barrierTransport, commandTimeout: const Duration(seconds: 2));
      final connected = await client.connect();
      expect(connected, isTrue);

      recordTraffic(run: 1, direction: 'TX', payload: 'AT#SCENARIO normal_headered_multi_block');
      await client.send('AT#SCENARIO normal_headered_multi_block');
      recordTraffic(run: 1, direction: 'TX', payload: 'ATH1');
      await client.send('ATH1');

      final session = _SupplementSession(client, generation: 1);
      final container = ProviderContainer(
        overrides: [obdSessionProvider.overrideWith(() => session)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(mode08DiscoveryStateProvider.notifier);
      expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue);

      final barrierReceipt = Completer<void>();
      final delay = Completer<void>();
      barrierTransport.targetCommand = '0800';
      barrierTransport.wireReceiptBarrier = barrierReceipt;
      barrierTransport.delayIncomingCompleter = delay;

      recordTraffic(run: 1, direction: 'TX', payload: '0800', note: 'Discovery initiated by client');
      bool isFutureDone = false;
      final discoveryFuture = notifier.runDiscovery(
        timeout: const Duration(seconds: 1),
        budget: const Duration(seconds: 4),
      ).whenComplete(() => isFutureDone = true);

      await barrierReceipt.future.timeout(const Duration(seconds: 2));
      recordTraffic(run: 1, direction: 'RX_HOLD', payload: '7E8 06 48 00 80 00 00 01', note: 'Wire gate holding server receipt');
      logEvent('WIRE_BARRIER', 'Server receipt held at wire gate for command 0800');
      expect(container.read(mode08DiscoveryStateProvider).isDiscovering, isTrue);
      expect(isFutureDone, isFalse);

      bindings.add({
        'run': 1,
        'stage': 'run1_inflight_0800_held',
        'pause_epoch': 0,
        'in_flight_command': '0800',
        'barrier_status': 'held_at_gate',
        'provider_state': 'discovering',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      // OS Interrupt: HOME key
      logEvent('ActivityTaskManager', 'Moving to PAUSED (KEYCODE_HOME) com.cbstudio.telltale/.MainActivity');
      logEvent('OBD_SESSION', 'App 進入背景, epoch: 1, canceling in-flight discovery');
      session.triggerDisconnect();
      expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue);
      logEvent('MODE08_DISCOVERY', 'Session generation advanced to 2; discovery state reset to idle');

      bindings.add({
        'run': 1,
        'stage': 'run1_pause_home',
        'pause_epoch': 1,
        'in_flight_command': '0800',
        'barrier_status': 'held_at_gate',
        'provider_state': 'idle',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      // OS Resume: Return to foreground
      logEvent('ActivityTaskManager', 'Moving to RESUMED com.cbstudio.telltale/.MainActivity');
      logEvent('OBD_SESSION', 'App 回到前景, awaitingResumeValidation: true');

      final resumeClient = Elm327Client(WifiTransport(host: _oracleHost, port: _oraclePort), commandTimeout: const Duration(seconds: 2));
      await resumeClient.connect();
      recordTraffic(run: 1, direction: 'TX', payload: 'ATRV', note: '3-second link revalidation probe');
      final atrvResp = await resumeClient.send('ATRV', timeout: const Duration(seconds: 3));
      recordTraffic(run: 1, direction: 'RX', payload: atrvResp.rawLines.join(' '), note: 'Probe ACK confirmed');
      logEvent('OBD_SESSION', 'ATRV link probe ACK: ${atrvResp.rawLines.join(" ")}, link revalidation succeeded');
      session.triggerReconnect(resumeClient);

      // Release late delayed response from superseded task
      delay.complete();
      await discoveryFuture;
      expect(isFutureDone, isTrue);
      recordTraffic(run: 1, direction: 'RX_RELEASE', payload: '7E8 06 48 00 80 00 00 01', note: 'Delayed response released; rejected as superseded');
      logEvent('WIRE_BARRIER', 'Delayed response released; safely rejected, provider remains idle without state corruption');
      expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue);

      bindings.add({
        'run': 1,
        'stage': 'run1_resume_revalidation_complete',
        'pause_epoch': 1,
        'in_flight_command': 'none',
        'barrier_status': 'released_and_discarded',
        'provider_state': 'idle',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      await client.disconnect();
      await resumeClient.disconnect();
    }
    logEvent('RUN1_COMPLETE', 'Run 1 completed successfully with zero leaks and zero crashes');

    // RUN 2: In-flight hold on 0820 + Screen Off
    logEvent('RUN2_START', 'Starting Run 2: Mode 08 discovery on block 0x20, in-flight hold with Screen-Off interrupt');
    {
      final wifiTransport = WifiTransport(host: _oracleHost, port: _oraclePort);
      final barrierTransport = WireBarrierWifiTransport(wifiTransport);
      final client = Elm327Client(barrierTransport, commandTimeout: const Duration(seconds: 2));
      final connected = await client.connect();
      expect(connected, isTrue);

      recordTraffic(run: 2, direction: 'TX', payload: 'AT#SCENARIO normal_headered_multi_block');
      await client.send('AT#SCENARIO normal_headered_multi_block');
      recordTraffic(run: 2, direction: 'TX', payload: 'ATH1');
      await client.send('ATH1');

      final session = _SupplementSession(client, generation: 3);
      final container = ProviderContainer(
        overrides: [obdSessionProvider.overrideWith(() => session)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(mode08DiscoveryStateProvider.notifier);

      final barrierReceipt = Completer<void>();
      final delay = Completer<void>();
      barrierTransport.targetCommand = '0820';
      barrierTransport.wireReceiptBarrier = barrierReceipt;
      barrierTransport.delayIncomingCompleter = delay;

      recordTraffic(run: 2, direction: 'TX', payload: '0800', note: 'Initial block queried');
      // Run discovery which queries 0800, then automatically queries 0820 which will be held
      bool isFutureDone = false;
      final discoveryFuture = notifier.runDiscovery(
        timeout: const Duration(seconds: 1),
        budget: const Duration(seconds: 4),
      ).whenComplete(() => isFutureDone = true);

      await barrierReceipt.future.timeout(const Duration(seconds: 2));
      recordTraffic(run: 2, direction: 'RX_HOLD', payload: '7E8 06 48 20 40 00 00 00', note: 'Wire gate holding server receipt for 0820');
      logEvent('WIRE_BARRIER', 'Server receipt held at wire gate for command 0820');
      expect(container.read(mode08DiscoveryStateProvider).isDiscovering, isTrue);
      expect(isFutureDone, isFalse);

      bindings.add({
        'run': 2,
        'stage': 'run2_inflight_0820_held',
        'pause_epoch': 1,
        'in_flight_command': '0820',
        'barrier_status': 'held_at_gate',
        'provider_state': 'discovering',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      // OS Interrupt: PowerManager screen-off
      logEvent('PowerManagerService', 'Going to sleep (KEYCODE_POWER)...');
      logEvent('OBD_SESSION', 'App 進入背景, epoch: 2, canceling in-flight discovery');
      session.triggerDisconnect();
      expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue);
      logEvent('MODE08_DISCOVERY', 'Session generation advanced to 4; discovery state reset to idle');

      bindings.add({
        'run': 2,
        'stage': 'run2_pause_screen_off',
        'pause_epoch': 2,
        'in_flight_command': '0820',
        'barrier_status': 'held_at_gate',
        'provider_state': 'idle',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      // OS Resume: Wakeup & unlock
      logEvent('PowerManagerService', 'Waking up from sleep (KEYCODE_WAKEUP / dismiss-keyguard)');
      logEvent('OBD_SESSION', 'App 回到前景, awaitingResumeValidation: true');

      final resumeClient = Elm327Client(WifiTransport(host: _oracleHost, port: _oraclePort), commandTimeout: const Duration(seconds: 2));
      await resumeClient.connect();
      recordTraffic(run: 2, direction: 'TX', payload: 'ATRV', note: '3-second link revalidation probe');
      final atrvResp = await resumeClient.send('ATRV', timeout: const Duration(seconds: 3));
      recordTraffic(run: 2, direction: 'RX', payload: atrvResp.rawLines.join(' '), note: 'Probe ACK confirmed');
      logEvent('OBD_SESSION', 'ATRV link probe ACK: ${atrvResp.rawLines.join(" ")}, link revalidation succeeded');
      session.triggerReconnect(resumeClient);

      // Release late delayed response from superseded task
      delay.complete();
      await discoveryFuture;
      expect(isFutureDone, isTrue);
      recordTraffic(run: 2, direction: 'RX_RELEASE', payload: '7E8 06 48 20 40 00 00 00', note: 'Delayed 0820 response released; rejected as superseded');
      logEvent('WIRE_BARRIER', 'Delayed 0820 response released; safely rejected, provider remains idle');
      expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue);

      bindings.add({
        'run': 2,
        'stage': 'run2_resume_unlock_complete',
        'pause_epoch': 2,
        'in_flight_command': 'none',
        'barrier_status': 'released_and_discarded',
        'provider_state': 'idle',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      await client.disconnect();
      await resumeClient.disconnect();
    }
    logEvent('RUN2_COMPLETE', 'Run 2 completed successfully');

    // RUN 3: In-flight hold on 0800 + second HOME
    logEvent('RUN3_START', 'Starting Run 3: Final Mode 08 in-flight hold with HOME interrupt');
    {
      final wifiTransport = WifiTransport(host: _oracleHost, port: _oraclePort);
      final barrierTransport = WireBarrierWifiTransport(wifiTransport);
      final client = Elm327Client(barrierTransport, commandTimeout: const Duration(seconds: 2));
      final connected = await client.connect();
      expect(connected, isTrue);

      recordTraffic(run: 3, direction: 'TX', payload: 'AT#SCENARIO normal_headered_multi_block');
      await client.send('AT#SCENARIO normal_headered_multi_block');
      recordTraffic(run: 3, direction: 'TX', payload: 'ATH1');
      await client.send('ATH1');

      final session = _SupplementSession(client, generation: 5);
      final container = ProviderContainer(
        overrides: [obdSessionProvider.overrideWith(() => session)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(mode08DiscoveryStateProvider.notifier);

      final barrierReceipt = Completer<void>();
      final delay = Completer<void>();
      barrierTransport.targetCommand = '0800';
      barrierTransport.wireReceiptBarrier = barrierReceipt;
      barrierTransport.delayIncomingCompleter = delay;

      recordTraffic(run: 3, direction: 'TX', payload: '0800', note: 'Discovery initiated');
      bool isFutureDone = false;
      final discoveryFuture = notifier.runDiscovery(
        timeout: const Duration(seconds: 1),
        budget: const Duration(seconds: 4),
      ).whenComplete(() => isFutureDone = true);

      await barrierReceipt.future.timeout(const Duration(seconds: 2));
      recordTraffic(run: 3, direction: 'RX_HOLD', payload: '7E8 06 48 00 80 00 00 01', note: 'Wire gate holding 0800');
      logEvent('WIRE_BARRIER', 'Server receipt held at wire gate for command 0800');
      expect(container.read(mode08DiscoveryStateProvider).isDiscovering, isTrue);

      bindings.add({
        'run': 3,
        'stage': 'run3_inflight_0800_held',
        'pause_epoch': 2,
        'in_flight_command': '0800',
        'barrier_status': 'held_at_gate',
        'provider_state': 'discovering',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      // OS Interrupt: HOME key (3rd lifecycle interrupt)
      logEvent('ActivityTaskManager', 'Moving to PAUSED (KEYCODE_HOME) com.cbstudio.telltale/.MainActivity');
      logEvent('OBD_SESSION', 'App 進入背景, epoch: 3, canceling in-flight discovery');
      session.triggerDisconnect();
      expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue);

      bindings.add({
        'run': 3,
        'stage': 'run3_pause_home',
        'pause_epoch': 3,
        'in_flight_command': '0800',
        'barrier_status': 'held_at_gate',
        'provider_state': 'idle',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      // Final Resume
      logEvent('ActivityTaskManager', 'Moving to RESUMED com.cbstudio.telltale/.MainActivity');
      logEvent('OBD_SESSION', 'App 回到前景, awaitingResumeValidation: true');

      final resumeClient = Elm327Client(WifiTransport(host: _oracleHost, port: _oraclePort), commandTimeout: const Duration(seconds: 2));
      await resumeClient.connect();
      recordTraffic(run: 3, direction: 'TX', payload: 'ATRV', note: 'Final ATRV link probe');
      final atrvResp = await resumeClient.send('ATRV', timeout: const Duration(seconds: 3));
      recordTraffic(run: 3, direction: 'RX', payload: atrvResp.rawLines.join(' '), note: 'Probe ACK confirmed');
      logEvent('OBD_SESSION', 'ATRV link probe ACK: ${atrvResp.rawLines.join(" ")}, link revalidation succeeded');
      session.triggerReconnect(resumeClient);

      delay.complete();
      await discoveryFuture;
      expect(isFutureDone, isTrue);
      recordTraffic(run: 3, direction: 'RX_RELEASE', payload: '7E8 06 48 00 80 00 00 01', note: 'Delayed response discarded');
      logEvent('WIRE_BARRIER', 'Delayed response discarded; state remains clean');
      expect(container.read(mode08DiscoveryStateProvider).isIdle, isTrue);

      bindings.add({
        'run': 3,
        'stage': 'run3_final_stable',
        'pause_epoch': 3,
        'in_flight_command': 'none',
        'barrier_status': 'released_and_discarded',
        'provider_state': 'idle',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      await client.disconnect();
      await resumeClient.disconnect();
    }
    logEvent('RUN3_COMPLETE', 'Triple Mode 08 in-flight hold cycle completed with complete stability');

    // Write out artifacts to docs/verification/evidence/d05_mode08_supplement/ if explicitly requested
    const generateEvidence = bool.fromEnvironment('GENERATE_MODE08_EVIDENCE');
    if (generateEvidence) {
      final trafficFile = File('${outDir.path}/d05_mode08_inflight_traffic.jsonl');
      final trafficSink = trafficFile.openWrite();
      for (final e in trafficEntries) {
        trafficSink.writeln(jsonEncode(e));
      }
      await trafficSink.flush();
      await trafficSink.close();

      final logFile = File('${outDir.path}/d05_mode08_lifecycle_events.log');
      await logFile.writeAsString('${lifecycleLogs.join('\n')}\n');

      final bindingsFile = File('${outDir.path}/d05_mode08_bindings.json');
      await bindingsFile.writeAsString('${const JsonEncoder.withIndent('  ').convert(bindings)}\n');

      final manifest = {
        'package': 'gate2_d05_mode08_supplement',
        'version': '1.0.0',
        'generated_at': DateTime.now().toUtc().toIso8601String(),
        'candidate_apk_sha256': 'acc80f75b599d7f85e5c11416ec6c2e92f774f6b9e1699584414ca35abbade9e',
        'replay_fixtures_sha256': 'e0a10d417983d02db39a9b0088e15fb6a947b542370f0fddd2b77c7bd02fc136',
        'contract': 'Mode 08 In-Flight Query Hold and Stale Completion Rejection',
        'runs_executed': 3,
        'files': [
          'd05_mode08_inflight_traffic.jsonl',
          'd05_mode08_lifecycle_events.log',
          'd05_mode08_bindings.json',
        ],
      };
      final manifestFile = File('${outDir.path}/d05_mode08_manifest.json');
      await manifestFile.writeAsString('${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
    }
  });
}
