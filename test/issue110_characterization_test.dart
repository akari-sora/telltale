/// Issue #110 non-regression characterization: lock behaviour that already
/// works, before any session-pipeline redesign.
///
/// Consumes the fixtures named in #110: `test/fixtures/issue106/`,
/// `test/fixtures/issue109/`, `test/fixtures/ws10_s1/`,
/// `docs/verification/evidence/*_traffic.jsonl`, FakeElm327, and the GT86 /
/// clone-quirk / transcript shapes. This is offline fixture replay, not
/// adapter or on-vehicle validation.
///
/// It does **not** lock the defect (a missing prompt after a complete
/// multi-ECU batch dropping the link). That path is covered by the later
/// recovery suite.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/adapter_identity.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/pid/pid_library.dart';
import 'package:torque_obd/obd/pid/priority_scheduler.dart';
import 'package:torque_obd/obd/polling_engine.dart';

import 'support/fake_elm327.dart';

final Map<String, dynamic> _issue110Fixture = jsonDecode(
  File('test/fixtures/issue109/issue110_followup.json').readAsStringSync(),
) as Map<String, dynamic>;

/// Third `010C0D04110B10` body from the sanitized #110 excerpt, with the
/// trailing prompt restored so this locks the *working* parse — not the
/// missing-prompt defect.
const _headeredBatchWithPrompt =
    '7E8100F410C0B560D00\r'
    '7E821042011250B6110\r'
    '7E8220158AAAAAAAAAA\r'
    '7E9100A410C0B5C0D00\r'
    '7E92104201125AAAAAA';

FakeEcu _singleEcm() => FakeEcu(
      name: 'ECM',
      requestId: '7E0',
      responseId: '7E8',
      responses: {
        '0100': [0x41, 0x00, 0xBE, 0x3F, 0xA8, 0x13],
        '0120': [0x41, 0x20, 0xA0, 0x07, 0xB0, 0x11],
        '0140': [0x41, 0x40, 0xFE, 0xD0, 0x84, 0x10],
        '010C': [0x41, 0x0C, 0x1A, 0xF8],
        '010D': [0x41, 0x0D, 0x3C],
        '0104': [0x41, 0x04, 0x33],
        '0111': [0x41, 0x11, 0x20],
        '010B': [0x41, 0x0B, 0x64],
        '0110': [0x41, 0x10, 0x01, 0x90],
        '0105': [0x41, 0x05, 0x64],
        '010F': [0x41, 0x0F, 0x54],
      },
    );

void main() {
  group('fixtures named by issue #110 are present and redacted', () {
    test('issue106 connection matrix still has the four causal scenarios', () {
      final json = jsonDecode(
        File('test/fixtures/issue106/connection_cases.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(json['task_id'], 'TELLTALE-CONNECT106-CAUSAL-TRIAGE');
      expect(json['issue_ref'], 106);
      final scenarios = json['scenarios'] as List<dynamic>;
      expect(
        scenarios.map((s) => (s as Map)['id']).toList(),
        [
          'CASE-01-TRANSPORT-EOF',
          'CASE-02-HANDSHAKE-TIMEOUT',
          'CASE-03-SLOW-RESPONSE',
          'CASE-04-HEALTHY-CONTROL',
        ],
      );
    });

    test('issue109 excerpts still describe 7E0 silence and 7DF answers', () {
      final off = File('test/fixtures/issue109/engine_off_excerpt.log')
          .readAsStringSync();
      expect(off, contains('>> ATSH 7E0'));
      expect(off, contains('<< NO DATA'));
      expect(off, contains('>> ATSH 7DF'));
      expect(off, contains('7E8064100BE3FA813'));
      expect(off, contains('015E'));
      final on = File('test/fixtures/issue109/engine_on_excerpt.log')
          .readAsStringSync();
      expect(on, contains('410C14F6'));
      final followup = jsonDecode(
        File('test/fixtures/issue109/v1.0.21_followup.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(followup['atdpn'], 'A6');
      expect((followup['adapter'] as Map)['ati'], 'ELM327 v1.5');
    });

    test('issue110 excerpt is sanitized and keeps the missing-prompt shape', () {
      final excerpt = File(
        'test/fixtures/issue109/issue110_missing_prompt_excerpt.log',
      ).readAsStringSync();
      expect(excerpt, isNot(contains(RegExp(r'[0-9A-F]{2}(:[0-9A-F]{2}){5}'))));
      expect(excerpt, isNot(contains('20261020T')));
      expect(excerpt, isNot(contains('deviceIdentifier')));
      expect(excerpt, contains('ICSolution'));
      expect(excerpt, contains('010C0D04110B10'));
      expect(excerpt, contains('# no prompt'));
      expect(excerpt, contains('starting realignment'));
      expect(_issue110Fixture['follows'], 109);
      expect(
        (_issue110Fixture['batch_010C0D04110B10'] as Map)['third_reply_prompt'],
        'missing',
      );
    });

    test('ws10_s1 literal PDU cases still admit only canonical reads', () {
      final json = jsonDecode(
        File('test/fixtures/ws10_s1/literal_pdu_cases.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(json['milestone'], 'WS10-S1');
      final valid = json['canonical_valid_cases'] as List<dynamic>;
      expect(valid, isNotEmpty);
      expect(
        valid.map((c) => (c as Map)['pdu_hex']),
        containsAll(['220100', '22F190', '1902FF', '190A']),
      );
    });

    test(
      'evidence traffic jsonl still records the AT handshake then ATSH 7E0',
      () {
        final files = Directory('docs/verification/evidence')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('_traffic.jsonl'))
            .toList();
        expect(files, isNotEmpty);
        var handshakeMatches = 0;
        for (final file in files) {
          final commands = file
              .readAsLinesSync()
              .map((line) {
                if (line.isEmpty) return null;
                final row = jsonDecode(line) as Map<String, dynamic>;
                return row['command'] as String?;
              })
              .whereType<String>()
              .toList();
          if (commands.isEmpty) continue;
          final atz = commands.indexOf('ATZ');
          final probe = commands.indexOf('0100');
          final sh = commands.indexOf('ATSH 7E0');
          if (atz < 0 || probe < 0 || sh < 0) continue;
          expect(probe, greaterThan(atz));
          expect(sh, greaterThan(probe));
          handshakeMatches++;
        }
        expect(
          handshakeMatches,
          greaterThan(0),
          reason: 'at least one evidence capture must show ATZ → 0100 → ATSH 7E0',
        );
      },
    );

    test('transcript, clone_quirks and gt86 suites are still in the tree', () {
      const required = [
        'test/transcript_test.dart',
        'test/transcript_store_test.dart',
        'test/transcript_survives_test.dart',
        'test/transcript_periodic_snapshot_test.dart',
        'test/transcript_export_smoke_test.dart',
        'test/transcript_size_label_test.dart',
        'test/clone_quirks_test.dart',
        'test/gt86_field_trace_contract_test.dart',
        'test/issue106_disconnect_characterization_test.dart',
        'test/issue106_protocol_search_regression_test.dart',
        'test/issue106_post_connect_dashboard_test.dart',
        'test/issue109_functional_fallback_test.dart',
        'test/support/fake_elm327.dart',
      ];
      for (final path in required) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });
  });

  group('direct 7E0 success (no functional fallback)', () {
    test('a working physical engine header is not forced onto 7DF', () async {
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        identity: 'ELM327 v2.1',
        deviceDescription: 'Genuine fixture',
        ecus: [_singleEcm()],
      );
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 400),
      );
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      expect(client.adapterIdentity.concerns, isEmpty);
      expect(client.adapterIdentity.versionNumber, '2.1');

      final rpm = await client.sendAddressed('7E0', '010C');
      expect(rpm.isSuccess, isTrue);
      expect(rpm.bytes, [0x41, 0x0C, 0x1A, 0xF8]);
      expect(transport.commandLog, contains('ATSH7E0'));
      expect(
        transport.commandLog.where((c) => c == 'ATSH7DF'),
        isEmpty,
        reason: '7E0 answered; broadcasting would mix controllers',
      );
      expect(transport.commandLog.where((c) => c == 'ATH1'), isEmpty);
    });

    test('single-ECU polling publishes RPM without 7DF', () async {
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        identity: 'ELM327 v2.1',
        ecus: [_singleEcm()],
      );
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 400),
      );
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      final engine = PollingEngine(client)
        ..setActivePids(const [PidLibrary.engineRpm]);
      addTearDown(engine.dispose);
      engine.start();
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (!engine.current.readings.containsKey(PidLibrary.engineRpm.id) &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await engine.stop();
      expect(
        engine.current.readings[PidLibrary.engineRpm.id]?.value,
        closeTo(1726, 1),
      );
      expect(transport.commandLog.where((c) => c == 'ATSH7DF'), isEmpty);
    });
  });

  group('genuine vs clone self-description (detection only)', () {
    test('v2.1 FakeElm327 is self-consistent', () async {
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        identity: 'ELM327 v2.1',
        deviceDescription: 'ELM327 v2.1',
        ecus: [_singleEcm()],
      );
      final client = Elm327Client(transport);
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      expect(client.adapterIdentity.isSelfConsistent, isTrue);
      expect(
        client.adapterIdentity.concerns.where(
          (c) => c.kind == AdapterConcernKind.firmwareNeverReleased,
        ),
        isEmpty,
      );
    });

    test('v1.5 banner is firmwareNeverReleased, not a reading-fidelity claim',
        () async {
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        identity: 'ELM327 v1.5',
        deviceDescription: 'ICSolution',
        ecus: [_singleEcm()],
      );
      final client = Elm327Client(transport);
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      expect(
        client.adapterIdentity.concerns.map((c) => c.kind),
        contains(AdapterConcernKind.firmwareNeverReleased),
      );
      final rpm = await client.sendAddressed('7E0', '010C');
      expect(rpm.isSuccess, isTrue);
      expect(rpm.bytes, [0x41, 0x0C, 0x1A, 0xF8]);
    });
  });

  group('CAN batching gate on a single-ECU car', () {
    test('max batch remains six PIDs on a working physical path', () {
      expect(PriorityScheduler.maxBatchSize, 6);
    });

    test('a prompted headered ISO-TP batch from the #110 wire shape parses',
        () async {
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        identity: 'ELM327 v1.5',
        deviceDescription: 'ICSolution',
        ecus: [_singleEcm()],
      );
      final client = Elm327Client(
        transport,
        commandTimeout: const Duration(milliseconds: 400),
      );
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      final ath1 = await client.send('ATH1');
      expect(ath1.isSuccess, isTrue);
      expect(client.headersOn, isTrue);
      expect(client.protocolNumber.toUpperCase(), contains('6'));
      expect(client.addressing.acceptedReceiveWidths, {3});

      // Driven through send(), not parseFrameForTest, because a completed AT
      // command leaves the parser's pending-command echo filter on that AT
      // verb until the next OBD write. The working path is a data command
      // with ATH1 already on, which is how the #110 batches were read.
      transport.forceReplySequence('010C0D04110B10', [
        _headeredBatchWithPrompt,
      ]);
      final parsed = await client.send('010C0D04110B10');
      expect(
        parsed.isSuccess,
        isTrue,
        reason:
            'error=${parsed.errorCode} lines=${parsed.rawLines} '
            'headersOn=${client.headersOn}',
      );
      expect(
        parsed.frames.map((f) => f.sourceId).toSet(),
        {'7E8', '7E9'},
      );
      final engine = parsed.frames.firstWhere((f) => f.sourceId == '7E8');
      expect(engine.bytes.take(6).toList(), [0x41, 0x0C, 0x0B, 0x56, 0x0D, 0x00]);
      // ((0x0B << 8) + 0x56) / 4 = 725.5 rpm — third-batch engine value
      // in the sanitized fixture.
      expect((256 * 0x0B + 0x56) / 4, 725.5);
    });
  });

  group('clone quirks that already work', () {
    test('numeric echo after ATE0 does not prepend payload bytes', () async {
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [_singleEcm()],
        faults: const AdapterFaults(echoNumericCommands: true),
      );
      final client = Elm327Client(transport);
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      final response = await client.send('010C');
      expect(response.bytes, [0x41, 0x0C, 0x1A, 0xF8]);
    });

    test('a prompt arriving in its own BLE chunk still completes', () async {
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        ecus: [_singleEcm()],
        faults: const AdapterFaults(maxChunkBytes: 1),
      );
      final client = Elm327Client(transport);
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      final response = await client.send('010C');
      expect(response.bytes, [0x41, 0x0C, 0x1A, 0xF8]);
    });
  });

  group('transcript recording on a healthy connect', () {
    test('ATZ and the prompt are in the live transcript', () async {
      final transport = FakeElm327(
        protocol: BusProtocol.can11,
        identity: 'ELM327 v2.1',
        ecus: [_singleEcm()],
      );
      final client = Elm327Client(transport);
      addTearDown(client.dispose);
      expect(await client.connect(), isTrue);
      final rendered = client.transcript.render();
      expect(rendered, contains('ATZ'));
      expect(rendered, contains('ELM327 v2.1'));
      expect(client.transcript.entries, isNotEmpty);
    });
  });
}
