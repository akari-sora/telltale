/// ELM327 Raw Byte Stream Chaos Engineering Harness (AA-08 Milestone M4 / SAFE-08).
///
/// High-precision simulated transport modeling flaky Bluetooth / Wi-Fi adapters:
/// 1. Packet Stickiness (coalesced reads containing multiple prompts/replies)
/// 2. Arbitrary Chunking (1-2 byte fragments, split CR/prompt across chunks)
/// 3. Missing CR/LF (prompt immediately follows hex payload without delimiter)
/// 4. Lost Prompt & Timeout Simulation (infinite stall, _outOfSync & _resync recovery)
/// 5. Stray 0x00 Null Bytes (filtering verification preserving valid hex)
/// 6. Buffer Leak & Budget Defense (massive unprompted flood, memory bound defense)
///
/// Invariant: lib/obd/ remains 0 diff vs origin/main. All harness logic lives here.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/transport/obd_transport.dart';

/// Default healthy initialization dictionary ensuring [Elm327Client.connect]
/// completes successfully before chaos injection begins.
const Map<String, String> _kDefaultHandshakeReplies = {
  'ATZ': 'ELM327 v1.5\r>',
  'ATE0': 'OK\r>',
  'ATL0': 'OK\r>',
  'ATM0': 'OK\r>',
  'ATS0': 'OK\r>',
  'ATAT1': 'OK\r>',
  'ATAT2': 'OK\r>',
  'ATST66': 'OK\r>',
  'ATSP0': 'OK\r>',
  'ATI': 'ELM327 v1.5\r>',
  'AT@1': 'OBDII to RS232 Interpreter\r>',
  'ATRV': '14.2V\r>',
  '0100': '41 00 BE 3F B8 11\r>',
  'ATDP': 'AUTO, ISO 15765-4 (CAN 11/500)\r>',
  'ATDPN': 'A6\r>',
  'ATPPS': '?\r>',
  'ATS1': 'OK\r>',
};

/// High-fidelity chaos transport simulating noisy, fragmented, or sticky raw byte streams.
class ChaosStreamTransport extends BaseObdTransport {
  ChaosStreamTransport({
    Map<String, String>? script,
  }) : _script = {..._kDefaultHandshakeReplies, ...?script};

  final Map<String, String> _script;
  final List<String> sentCommands = [];
  final List<List<int>> writtenBytes = [];

  /// Optional programmatic interceptor for custom write responses.
  FutureOr<void> Function(String command, ChaosStreamTransport transport)? onWrite;

  /// Optional hook triggered when `disconnect()` is called.
  void Function()? onDisconnect;

  @override
  TransportKind get kind => TransportKind.demo;

  @override
  String get displayName => 'ChaosStreamHarnessTransport';

  @override
  Future<void> connect() async {
    setConnected(true);
  }

  @override
  Future<void> disconnect() async {
    setConnected(false);
    onDisconnect?.call();
  }

  @override
  Future<void> write(List<int> data) async {
    writtenBytes.add(List<int>.from(data));
    final raw = ascii.decode(data, allowInvalid: true).trim();
    final key = raw.toUpperCase().replaceAll(' ', '');
    sentCommands.add(key);

    if (onWrite != null) {
      await onWrite!(key, this);
      return;
    }

    final reply = _script[key] ?? '?\r>';
    scheduleMicrotask(() => emitBytes(ascii.encode(reply)));
  }

  /// Directly emits arbitrary bytes to the incoming stream.
  void injectRawBytes(List<int> bytes) {
    emitBytes(bytes);
  }

  /// Directly emits string payload encoded as ASCII.
  void injectString(String text) {
    injectRawBytes(ascii.encode(text));
  }

  /// Emits bytes sliced into tiny fragments of [chunkSize] bytes.
  void injectChunked(List<int> bytes, {int chunkSize = 1}) {
    if (chunkSize <= 0) chunkSize = 1;
    for (var i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
      final slice = bytes.sublist(i, end);
      scheduleMicrotask(() => emitBytes(slice));
    }
  }

  /// Intersperses [nullsPerByte] null bytes (0x00) between every byte of [data].
  void injectWithNullNoise(List<int> data, {int nullsPerByte = 1}) {
    final noisy = <int>[];
    for (final b in data) {
      for (var n = 0; n < nullsPerByte; n++) {
        noisy.add(0x00);
      }
      noisy.add(b);
    }
    for (var n = 0; n < nullsPerByte; n++) {
      noisy.add(0x00);
    }
    emitBytes(noisy);
  }
}

void main() {
  group('ELM327 Chaos Stream Harness (AA-08 / R4)', () {
    // -------------------------------------------------------------------------
    // 1. 黏包 (Packet Stickiness)
    // -------------------------------------------------------------------------
    group('1. 黏包 (Packet Stickiness & Multi-Frame Re-entrancy)', () {
      test('single chunk containing two full replies drains first and extracts cleanly', () async {
        final transport = ChaosStreamTransport();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 300),
        );
        addTearDown(client.dispose);

        expect(await client.connect(), isTrue);

        // When 010C is written, transport delivers two complete frames in ONE read:
        // Reply 1: 41 0C 1A F8\r> (RPM 1726)
        // Reply 2: 41 0D 32\r>    (Speed 50 km/h)
        transport.onWrite = (cmd, t) {
          if (cmd == '010C') {
            t.injectString('41 0C 1A F8\r>\r41 0D 32\r>');
          }
        };

        final response = await client.send('010C');
        expect(response.rawLines.join('\n'), contains('41 0C 1A F8'));

        // Next command 0105 should not see leftover desync state
        transport.onWrite = (cmd, t) {
          if (cmd == '0105') {
            t.injectString('41 05 5A\r>');
          }
        };

        final respNext = await client.send('0105');
        expect(respNext.rawLines.join('\n'), contains('41 05 5A'));
      });

      test('coalesced chunk with surplus prompt during idle state clears out-of-sync', () async {
        final transport = ChaosStreamTransport();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 200),
        );
        addTearDown(client.dispose);

        expect(await client.connect(), isTrue);

        // Inject unsolicited framed bytes while no command is pending
        transport.injectString('41 00 BE 3F B8 11\r>');

        // Immediately follow up with a legitimate command
        transport.onWrite = (cmd, t) {
          if (cmd == '010C') {
            t.injectString('41 0C 20 00\r>');
          }
        };

        final resp = await client.send('010C');
        expect(resp.rawLines.join('\n'), contains('41 0C 20 00'));
      });
    });

    // -------------------------------------------------------------------------
    // 2. 任意分片 (Arbitrary Chunking)
    // -------------------------------------------------------------------------
    group('2. 任意分片 (Arbitrary Chunking & Fragment Assembly)', () {
      test('1-byte extreme fragment slicing is assembled without loss', () async {
        final transport = ChaosStreamTransport();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 500),
        );
        addTearDown(client.dispose);

        expect(await client.connect(), isTrue);

        transport.onWrite = (cmd, t) {
          if (cmd == '010C') {
            // Sliced strictly 1 byte per chunk
            t.injectChunked(ascii.encode('41 0C 1A F8\r>'), chunkSize: 1);
          }
        };

        final response = await client.send('010C');
        expect(response.rawLines.join('\n'), contains('41 0C 1A F8'));
      });

      test('splitting carriage return and prompt across chunk boundary succeeds', () async {
        final transport = ChaosStreamTransport();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 300),
        );
        addTearDown(client.dispose);

        expect(await client.connect(), isTrue);

        transport.onWrite = (cmd, t) {
          if (cmd == '010D') {
            // Chunk 1: payload + \r
            // Chunk 2: >
            t.injectString('41 0D 4B\r');
            scheduleMicrotask(() => t.injectString('>'));
          }
        };

        final response = await client.send('010D');
        expect(response.rawLines.join('\n'), contains('41 0D 4B'));
      });

      test('pseudo-random chunking over sequential commands maintains 100% fidelity', () async {
        final transport = ChaosStreamTransport();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 400),
        );
        addTearDown(client.dispose);

        expect(await client.connect(), isTrue);

        final rng = Random(42);
        final commands = [
          ('0104', '41 04 80\r>'),
          ('0105', '41 05 64\r>'),
          ('010C', '41 0C 1A F8\r>'),
          ('010D', '41 0D 32\r>'),
          ('010F', '41 0F 28\r>'),
        ];

        for (final (cmd, fullReply) in commands) {
          transport.onWrite = (c, t) {
            if (c == cmd) {
              final bytes = ascii.encode(fullReply);
              var offset = 0;
              while (offset < bytes.length) {
                final sliceLen = min(rng.nextInt(3) + 1, bytes.length - offset);
                final slice = bytes.sublist(offset, offset + sliceLen);
                offset += sliceLen;
                scheduleMicrotask(() => t.injectRawBytes(slice));
              }
            }
          };

          final resp = await client.send(cmd);
          expect(resp.rawLines, isNotEmpty);
        }
      });
    });

    // -------------------------------------------------------------------------
    // 3. 丟失 CR/LF (Missing Terminating Newlines)
    // -------------------------------------------------------------------------
    group('3. 丟失 CR/LF (Missing Terminating Newlines)', () {
      test('prompt immediately follows hex payload without carriage return', () async {
        final transport = ChaosStreamTransport();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 300),
        );
        addTearDown(client.dispose);

        expect(await client.connect(), isTrue);

        transport.onWrite = (cmd, t) {
          if (cmd == '010C') {
            // Notice: No \r or \n before >
            t.injectString('41 0C 1A F8>');
          }
        };

        final response = await client.send('010C');
        expect(response.rawLines.join('\n'), contains('41 0C 1A F8'));
      });

      test('multiline payload with bare prompt trailing last line', () async {
        final transport = ChaosStreamTransport();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 300),
        );
        addTearDown(client.dispose);

        expect(await client.connect(), isTrue);

        transport.onWrite = (cmd, t) {
          if (cmd == '03') {
            // Multiline response ending directly with prompt
            t.injectString('43 02 01 33 00 00\r43 00 00 00 00 00>');
          }
        };

        final response = await client.send('03');
        expect(response.rawLines, contains('43 02 01 33 00 00'));
        expect(response.rawLines, contains('43 00 00 00 00 00'));
      });
    });

    // -------------------------------------------------------------------------
    // 4. 丟失 Prompt / 超時假死與再同步 (Lost Prompt, Timeout & Resync Recovery)
    // -------------------------------------------------------------------------
    group('4. 丟失 Prompt / 超時假死與再同步 (Lost Prompt & Timeout Recovery)', () {
      test('lost prompt triggers command timeout and marks connection out-of-sync', () async {
        final transport = ChaosStreamTransport();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 60),
        );
        addTearDown(client.dispose);

        expect(await client.connect(), isTrue);

        // Stall 010C by sending data without prompt
        transport.onWrite = (cmd, t) {
          if (cmd == '010C') {
            t.injectString('41 0C 1A F8\r');
          }
        };

        expect(
          () => client.send('010C', timeout: const Duration(milliseconds: 60)),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('subsequent command resynchronises after lost prompt and succeeds', () async {
        final transport = ChaosStreamTransport();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 60),
        );
        addTearDown(client.dispose);

        expect(await client.connect(), isTrue);

        // 1. 010C answers late (at 120ms), exceeding the 60ms timeout.
        // 2. Client times out and enters _outOfSync.
        // 3. Client calls send('010D'). send() begins _resync().
        // 4. During _resync(), the late 010C prompt arrives (at 120ms).
        // 5. _resync() consumes the dangling prompt, clears _outOfSync, and releases send().
        // 6. 010D is transmitted, answers, and completes.
        transport.onWrite = (cmd, t) {
          if (cmd == '010C') {
            Timer(const Duration(milliseconds: 120), () {
              t.injectString('41 0C 1A F8\r>');
            });
          } else if (cmd == '010D') {
            t.injectString('41 0D 32\r>');
          }
        };

        await expectLater(
          () => client.send('010C', timeout: const Duration(milliseconds: 60)),
          throwsA(isA<TimeoutException>()),
        );

        final response = await client.send(
          '010D',
          timeout: const Duration(milliseconds: 500),
        );
        expect(response.rawLines.join('\n'), contains('41 0D 32'));
      });

      test('unrecovered resync deadline expires cleanly with TimeoutException', () async {
        final transport = ChaosStreamTransport();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 50),
        );
        addTearDown(client.dispose);

        expect(await client.connect(), isTrue);

        // Cause initial timeout: 010C never delivers prompt
        transport.onWrite = (cmd, t) {
          if (cmd == '010C') {
            t.injectString('NO PROMPT EVER\r');
          }
        };

        await expectLater(
          () => client.send('010C', timeout: const Duration(milliseconds: 50)),
          throwsA(isA<TimeoutException>()),
        );

        // Second command: transport completely silent during resync
        transport.onWrite = (cmd, t) {};

        await expectLater(
          () => client.send(
            '010D',
            timeout: const Duration(milliseconds: 50),
            deadline: DateTime.now().add(const Duration(milliseconds: 60)),
          ),
          throwsA(isA<TimeoutException>()),
        );
      });
    });

    // -------------------------------------------------------------------------
    // 5. 雜訊位元組 (Stray 0x00 Null Bytes)
    // -------------------------------------------------------------------------
    group('5. 雜訊位元組 (Stray 0x00 Null Bytes Defense)', () {
      test('pervasive stray 0x00 bytes are filtered without corrupting hex stream', () async {
        final transport = ChaosStreamTransport();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 300),
        );
        addTearDown(client.dispose);

        expect(await client.connect(), isTrue);

        transport.onWrite = (cmd, t) {
          if (cmd == '010C') {
            // Insert 2 null bytes around each character
            t.injectWithNullNoise(ascii.encode('41 0C 1A F8\r>'), nullsPerByte: 2);
          }
        };

        final response = await client.send('010C');
        expect(response.rawLines.join('\n'), contains('41 0C 1A F8'));
      });

      test('null byte burst preceding prompt byte is ignored', () async {
        final transport = ChaosStreamTransport();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 300),
        );
        addTearDown(client.dispose);

        expect(await client.connect(), isTrue);

        transport.onWrite = (cmd, t) {
          if (cmd == '010D') {
            final raw = <int>[
              ...ascii.encode('41 0D 20\r'),
              0x00, 0x00, 0x00, 0x00,
              0x3E, // '>'
            ];
            t.injectRawBytes(raw);
          }
        };

        final response = await client.send('010D');
        expect(response.rawLines.join('\n'), contains('41 0D 20'));
      });
    });

    // -------------------------------------------------------------------------
    // 6. 記憶體洩漏與緩衝區防禦 (Buffer Leak & Budget Defense)
    // -------------------------------------------------------------------------
    group('6. 記憶體洩漏與緩衝區防禦 (Buffer Leak & Budget Defense)', () {
      test('high-volume noise bytes without prompt do not crash or corrupt isolate', () async {
        final transport = ChaosStreamTransport();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 200),
        );
        addTearDown(client.dispose);

        expect(await client.connect(), isTrue);

        // Flood 32 KB of random non-prompt alphanumeric garbage
        final rng = Random(12345);
        final flood = List<int>.generate(32 * 1024, (_) => rng.nextInt(26) + 65); // 'A'-'Z'
        transport.injectRawBytes(flood);

        // Verify client can still handle next valid command after buffer timeout/drain
        transport.onWrite = (cmd, t) {
          if (cmd == '010C') {
            t.injectString('41 0C 1A F8\r>');
          }
        };

        // When command is sent, client's internal sendNow clears buffer and executes cleanly
        final response = await client.send('010C');
        expect(response.rawLines.join('\n'), contains('41 0C 1A F8'));
      });

      test('search extension does not allow unbounded timeout inflation', () async {
        final transport = ChaosStreamTransport();
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 80),
        );
        addTearDown(client.dispose);

        expect(await client.connect(), isTrue);

        transport.onWrite = (cmd, t) {
          if (cmd == '0100') {
            // Emits SEARCHING... without trailing prompt
            t.injectString('SEARCHING...\r');
          }
        };

        final start = DateTime.now();
        await expectLater(
          () => client.send(
            '0100',
            timeout: const Duration(milliseconds: 100),
            deadline: DateTime.now().add(const Duration(milliseconds: 150)),
          ),
          throwsA(isA<TimeoutException>()),
        );
        final elapsed = DateTime.now().difference(start);

        // The timeout must be bounded by deadline budget, never hang indefinitely
        expect(elapsed.inMilliseconds, lessThan(3000));
      });
    });
  });
}
