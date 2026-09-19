/// Host-only TCP/Notifier regression. This does not install or execute an APK,
/// press Android HOME/POWER, or capture Android logcat/screenshots.
/// Historical exported files are retained separately with a provenance erratum.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/wifi_transport.dart';
import 'package:torque_obd/state/obd_session.dart';
import 'package:torque_obd/state/service_recipes_provider.dart';

import 'mode08_replay_oracle_test.dart'
    show WireBarrierWifiTransport, oracleIdentity, verifyOraclePreflight;

const _host = '127.0.0.1';
const _port = int.fromEnvironment('MODE08_ORACLE_PORT', defaultValue: 35008);
const _required = bool.fromEnvironment('MODE08_ORACLE_REQUIRED');

class _SupplementSession extends ObdSession {
  _SupplementSession(this._client);
  Elm327Client? _client;

  @override
  int generation = 1;

  @override
  Elm327Client? get client => _client;

  @override
  ObdConnectionState build() => const ObdConnectionState(
    phase: ConnectionPhase.connected,
    protocol: 'ISO 15765-4 (CAN 11/500)',
  );

  void invalidate() {
    generation++;
    _client = null;
    state = const ObdConnectionState(
      phase: ConnectionPhase.disconnected,
      protocol: '',
    );
  }

  void replaceWith(Elm327Client client) {
    generation++;
    _client = client;
    state = const ObdConnectionState(
      phase: ConnectionPhase.connected,
      protocol: 'ISO 15765-4 (CAN 11/500)',
    );
  }
}

void main() {
  late bool available;
  setUpAll(() async {
    available = await verifyOraclePreflight(
      host: _host,
      port: _port,
      requiredMode: _required,
      identity: oracleIdentity,
    );
  });

  // These are three host regressions, not three Android lifecycle runs.
  const targets = ['0800', '0820', '0800'];
  for (var index = 0; index < targets.length; index++) {
    final target = targets[index];
    test('host-only session retirement ${index + 1}: held $target', () async {
      if (!available) {
        if (_required) fail('Required Mode 08 reference is unavailable');
        markTestSkipped('Mode 08 replay reference is not running');
        return;
      }

      final transport = WireBarrierWifiTransport(
        WifiTransport(host: _host, port: _port),
      );
      final original = Elm327Client(
        transport,
        commandTimeout: const Duration(seconds: 2),
      );
      final replacement = Elm327Client(
        WifiTransport(host: _host, port: _port),
        commandTimeout: const Duration(seconds: 2),
      );
      final release = Completer<void>();
      final received = Completer<void>();
      ProviderContainer? container;
      Future<void>? pending;
      var disposed = false;

      try {
        expect(await original.connect(), isTrue);
        expect(
          (await original.send('AT#SCENARIO normal_headered_multi_block')).isSuccess,
          isTrue,
        );
        expect((await original.send('ATH1')).isSuccess, isTrue);

        final session = _SupplementSession(original);
        final scope = ProviderContainer(
          overrides: [obdSessionProvider.overrideWith(() => session)],
        );
        container = scope;
        final notifier = scope.read(mode08DiscoveryStateProvider.notifier);
        transport.targetCommand = target;
        transport.wireReceiptBarrier = received;
        transport.delayIncomingCompleter = release;

        var finished = false;
        pending = notifier.runDiscovery(
          timeout: const Duration(seconds: 5),
          budget: const Duration(seconds: 8),
        ).whenComplete(() => finished = true);

        await received.future.timeout(const Duration(seconds: 3));
        expect(
          transport.observedEvents,
          contains('server_receipt_held_at_gate: $target'),
        );
        expect(finished, isFalse);
        expect(scope.read(mode08DiscoveryStateProvider).isDiscovering, isTrue);

        // Explicit synthetic session invalidation, NOT an Android OS event.
        session.invalidate();
        expect(scope.read(mode08DiscoveryStateProvider).isIdle, isTrue);
        expect(await replacement.connect(), isTrue);
        session.replaceWith(replacement);
        expect(session.generation, 3);
        expect(finished, isFalse, reason: 'Old result must still be held');

        release.complete();
        await pending.timeout(const Duration(seconds: 3));
        expect(scope.read(mode08DiscoveryStateProvider).isIdle, isTrue);

        // The new connection remains usable after the old result is discarded.
        await notifier.runDiscovery();
        final current = scope.read(mode08DiscoveryStateProvider);
        expect(current.isCompleted, isTrue);
        expect(current.result!.supportedTids, equals({1}));
        scope.dispose();
        disposed = true;
      } finally {
        if (!disposed) container?.dispose();
        if (!release.isCompleted) release.complete();
        try {
          if (pending != null) {
            await pending.timeout(const Duration(seconds: 4));
          }
        } finally {
          try {
            await original.disconnect().timeout(const Duration(seconds: 3));
          } finally {
            await replacement.disconnect().timeout(const Duration(seconds: 3));
          }
        }
      }
    });
  }
}
