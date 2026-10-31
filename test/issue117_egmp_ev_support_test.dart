import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/uds/uds_read_codec.dart';
import 'package:torque_obd/diagnostics/uds/uds_read_types.dart';
import 'package:torque_obd/obd/addressing.dart';
import 'package:torque_obd/obd/elm327_client.dart';
import 'package:torque_obd/obd/elm_can_addressing.dart';
import 'package:torque_obd/obd/elm_flow_control.dart';
import 'package:torque_obd/obd/iso_tp_assembler.dart';
import 'package:torque_obd/obd/polling_engine.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_catalog.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_probe.dart';
import 'package:torque_obd/obd/powertrain_battery/powertrain_battery_profile.dart';
import 'package:torque_obd/obd/powertrain_battery/profile_pid_installer.dart';
import 'package:torque_obd/obd/transport/ble_transport.dart';
import 'package:universal_ble/universal_ble.dart';

import 'support/fake_elm327.dart';

const _bms0101Full = <int>[
  0x62, 0x01, 0x01, 0xEF, 0xFB, 0xE7, 0xEF, 0x8E, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x0F, 0x1D, 0x3E, 0x21, 0x1E, 0x20, 0x1F, 0x20, 0x1E, 0x1F,
  0x00, 0x4B, 0xC3, 0x11, 0xC2, 0xA9, 0x00, 0x00, 0x87, 0x00, 0x05, 0x95,
  0x71, 0x00, 0x05, 0x8B, 0x78, 0x00, 0x04, 0x2F, 0x41, 0x00, 0x04, 0x08,
  0xA2, 0x02, 0xB4, 0xC8, 0xC0, 0x00, 0x02, 0xE8, 0x00, 0x00, 0x00, 0x00,
  0x0B, 0xB8,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue #117 Hyundai/Kia e-GMP EV support', () {
    test(
      'Mode 09 0902 NO DATA falls back to UDS 22F190 on 7E2/7EA and restores 7DF',
      () async {
        const vin = 'KMHKR81AFPU123456';
        final vinPayload = <int>[0x62, 0xF1, 0x90, ...ascii.encode(vin)];
        final transport = FakeElm327(
          protocol: BusProtocol.can11,
          ecus: [
            FakeEcu(
              name: 'VCU',
              requestId: '7E2',
              responseId: '7EA',
              responses: {
                '0100': const [0x41, 0x00, 0x98, 0x18, 0x00, 0x01],
                '22F190': vinPayload,
              },
            ),
          ],
        );
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 300),
        );
        expect(await client.connect(), isTrue);
        final engine = PollingEngine(client);
        addTearDown(engine.dispose);

        final decodedVin = await engine.readVin();
        expect(decodedVin, vin);

        // Verify ATCRA 7EA and flow control were used for physical 7E2 query,
        // and ATCRA + ATSH 7DF were restored afterward.
        expect(transport.commandLog, contains('ATSH7E2'));
        expect(transport.commandLog, contains('ATCRA7EA'));
        expect(transport.commandLog, contains('ATFCSH7E2'));
        expect(transport.commandLog, contains('ATFCSD300000'));
        expect(transport.commandLog, contains('ATFCSM1'));
        expect(transport.commandLog, contains('22F190'));
        final lastAtsh = transport.commandLog.lastWhere(
          (cmd) => cmd.startsWith('ATSH'),
        );
        expect(lastAtsh, 'ATSH7DF');
      },
    );

    test(
      'Issue #117 clone 0100 frame 7EA 03 41 00 98 18 00 01 is recovered and detects e-GMP EV',
      () async {
        // Reassemble raw clone PCI=03 frame with 6 payload bytes.
        final reassembled = IsoTpAssembler.reassemble(const [
          [0x03, 0x41, 0x00, 0x98, 0x18, 0x00, 0x01],
        ]);
        expect(reassembled, [0x41, 0x00, 0x98, 0x18, 0x00, 0x01]);

        final transport = FakeElm327(
          protocol: BusProtocol.can11,
          ecus: [
            FakeEcu(
              name: 'VCU',
              requestId: '7E2',
              responseId: '7EA',
              responses: const {
                '0100': [0x41, 0x00, 0x98, 0x18, 0x00, 0x01],
              },
            ),
            FakeEcu(
              name: 'BMS',
              requestId: '7E4',
              responseId: '7EC',
              responses: const {
                '220101': _bms0101Full,
              },
            ),
          ],
        );
        final client = Elm327Client(
          transport,
          commandTimeout: const Duration(milliseconds: 300),
        );
        expect(await client.connect(), isTrue);
        final engine = PollingEngine(client);
        addTearDown(engine.dispose);

        final supported = await engine.discoverSupportedPids();
        expect(supported, containsAll(['0101', '0104', '0105', '010C', '010D']));
        expect(engine.isEvOrEgmpDetected, isTrue);
        expect(
          engine.detectedPowertrainProfileId,
          PowertrainBatteryCatalog.hyundaiKiaEgmpProfileId,
        );
        expect(
          PowertrainBatteryCatalog.resolveProfileId('hyundai_kia_egmp'),
          PowertrainBatteryCatalog.hyundaiKiaEgmpProfileId,
        );

        final probed = await PowertrainBatteryProbe.probeEgmpBms(client);
        expect(probed, isTrue);
      },
    );

    test(
      'ISO-TP assembler and UdsReadCodec strip intermediate 7F 22 78 ResponsePending frames',
      () {
        final framesWithPending = <List<int>>[
          [0x03, 0x7F, 0x22, 0x78, 0xAA, 0xAA, 0xAA, 0xAA],
          [0x10, 0x09, 0x62, 0x01, 0x01, 0x11, 0x22, 0x33],
          [0x21, 0x44, 0x55, 0x66, 0x00, 0x00, 0x00, 0x00],
        ];
        final reassembled = IsoTpAssembler.reassemble(framesWithPending);
        expect(reassembled, [
          0x62, 0x01, 0x01, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66,
        ]);

        final udsParsed = UdsReadCodec.parseResponseBytes(
          requestedDid: const UdsDid(0xF190),
          responseBytes: const [
            0x7F, 0x22, 0x78,
            0x62, 0xF1, 0x90, 0x4B, 0x4D, 0x48,
          ],
        );
        expect(udsParsed, isA<UdsReadSuccess>());
        final success = udsParsed as UdsReadSuccess;
        expect(success.did.value, 0xF190);
        expect(success.dataRecord, [0x4B, 0x4D, 0x48]);
      },
    );

    test(
      'Truncated multi-frame BMS 220101 response recovers contiguous prefix and decodes prefix signals',
      () async {
        // Build 9-frame ISO-TP sequence for 62-byte _bms0101Full, then drop
        // the last two Consecutive Frames (27 and 28) to simulate a slow BLE
        // ELM327 v1.5 UART buffer drop.
        final fullFrames = <List<int>>[
          [0x10, _bms0101Full.length, ..._bms0101Full.sublist(0, 6)],
        ];
        var offset = 6;
        var seq = 1;
        while (offset < _bms0101Full.length) {
          final end = (offset + 7 <= _bms0101Full.length)
              ? offset + 7
              : _bms0101Full.length;
          fullFrames.add([0x20 | (seq & 0x0F), ..._bms0101Full.sublist(offset, end)]);
          offset = end;
          seq++;
        }
        // Drop trailing 2 frames (leaves FF + CF 21..26 = 6 + 6*7 = 48 bytes).
        final truncatedFrames = fullFrames.sublist(0, fullFrames.length - 2);

        // Fail-closed by default when allowPartialPrefix is false.
        expect(IsoTpAssembler.reassemble(truncatedFrames), isNull);

        // Recovers contiguous 48-byte prefix when allowPartialPrefix is true.
        final meta = IsoTpAssembler.reassembleWithMetadata(
          truncatedFrames,
          allowPartialPrefix: true,
        );
        expect(meta, isNotNull);
        expect(meta!.isPartialPrefix, isTrue);
        expect(meta.declaredLength, 62);
        expect(meta.bytes.length, 48);
        expect(meta.bytes, _bms0101Full.sublist(0, 48));

        final snapshot = await PowertrainBatteryCatalogAsset.load(rootBundle);
        final ioniq5 = snapshot.byId('hyundai_kia_egmp')!;
        final cmd0101 = ioniq5.commands.singleWhere(
          (cmd) => cmd.requestHeader == '7E4' && cmd.identifier == '0101',
        );

        final probeResult = PowertrainBatteryProbe.decode(
          profile: ioniq5,
          command: cmd0101,
          catalogSha256: snapshot.catalogSha256,
          allowPartialPrefix: true,
          response: ObdResponse(
            bytes: meta.bytes,
            frames: [
              ObdFrame(
                meta.bytes,
                sourceId: '7EC',
                isPartialPrefix: true,
                declaredPayloadLength: meta.declaredLength,
              ),
            ],
            headersEnabled: true,
          ),
        );
        expect(probeResult.passed, isTrue, reason: probeResult.detail);
        final bySignal = {
          for (final r in probeResult.readings) r.signal.id: r.value,
        };
        expect(bySignal['soc_bms'], closeTo(71.0, 0.0001));
        expect(bySignal['pack_current'], closeTo(1.5, 0.0001));
        expect(bySignal['pack_voltage'], closeTo(748.6, 0.0001));
        expect(bySignal['pack_power'], closeTo(1.1229, 0.0001));
        expect(bySignal['batt_temp_max'], closeTo(33.0, 0.0001));
        expect(bySignal['batt_temp_min'], closeTo(30.0, 0.0001));
        expect(bySignal['cell_volt_max'], closeTo(3.9, 0.0001));
        expect(bySignal['cell_volt_min'], closeTo(3.88, 0.0001));
        expect(bySignal['aux_batt_voltage'], closeTo(13.5, 0.0001));
        // Trailing isolation_resistance at offset 57..58 is beyond the 45-byte
        // data prefix (48 - 3 header bytes) and is cleanly omitted rather than
        // synthesized.
        expect(bySignal.containsKey('isolation_resistance'), isFalse);
      },
    );

    test(
      'Physical 11-bit CAN addressing maps e-GMP ECUs to header+0x08 and configures flow control',
      () {
        const expectedPairs = <String, String>{
          '7E4': '7EC',
          '7E2': '7EA',
          '7E0': '7E8',
          '744': '74C',
          '770': '778',
          '7A0': '7A8',
          '7C6': '7CE',
          '7D1': '7D9',
          '7B3': '7BB',
        };
        final can11 = BusAddressing.forProtocolNumber('6');
        for (final entry in expectedPairs.entries) {
          expect(
            ElmPhysicalCanAddressing.responseFor11BitRequest(entry.key),
            entry.value,
          );
          expect(
            ElmPhysicalCanAddressing.requestFor11BitResponse(entry.value),
            entry.key,
          );
          final filter = ElmCanReceiveFilterConfig.forPhysical11Bit(
            requestHeader: entry.key,
            addressing: can11,
          );
          expect(filter.toAtCommand(), 'ATCRA${entry.value}');
          final fc = ElmFlowControlConfig.standard11Bit(
            header: entry.key,
            addressing: can11,
          );
          expect(fc.toAtCommands(), [
            'ATFCSH${entry.key}',
            'ATFCSD300000',
            'ATFCSM1',
          ]);
        }
        expect(ElmPhysicalCanAddressing.responseFor11BitRequest('7DF'), isNull);
        expect(
          () => ElmCanReceiveFilterConfig.forPhysical11Bit(
            requestHeader: '7DF',
            addressing: can11,
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      'BleTransport writes short commands atomically and chunks/paces long payloads',
      () async {
        final fakeBle = _FakeBlePlatform();
        UniversalBle.setInstance(fakeBle);
        const handle = BleAdapterHandle(id: 'AA:BB:CC:DD:EE:FF', name: 'OBDII');
        final transport = BleTransport(
          handle,
          interChunkDelay: const Duration(milliseconds: 10),
          interWriteDelay: const Duration(milliseconds: 10),
        );
        await transport.connect();
        addTearDown(transport.disconnect);

        // Short command (<= 20 bytes) is written in a single atomic GATT write.
        await transport.write(Uint8List.fromList(ascii.encode('ATZ\r')));
        expect(fakeBle.writes, hasLength(1));
        expect(ascii.decode(fakeBle.writes.single), 'ATZ\r');

        // Long payload (> 20 bytes) is split into <= 20-byte chunks with pacing.
        fakeBle.writes.clear();
        final longPayload = Uint8List.fromList(
          ascii.encode('0123456789ABCDEFGHIJ01234\r'),
        );
        await transport.write(longPayload);
        expect(fakeBle.writes, hasLength(2));
        expect(fakeBle.writes[0].length, 20);
        expect(fakeBle.writes[1].length, 6);

        // Verify expanded e-GMP profile installs cleanly.
        final snapshot = await PowertrainBatteryCatalogAsset.load(rootBundle);
        final egmp = snapshot.byId('hyundai_kia_egmp')!;
        final pids = PowertrainProfilePidInstaller.build(egmp);
        expect(pids.length, greaterThanOrEqualTo(40));
      },
    );
  });
}

class _FakeBlePlatform extends UniversalBlePlatform {
  final List<Uint8List> writes = [];
  bool _connected = false;

  @override
  Future<AvailabilityState> getBluetoothAvailabilityState() async =>
      AvailabilityState.poweredOn;

  @override
  Future<bool> enableBluetooth() async => true;

  @override
  Future<bool> disableBluetooth() async => true;

  @override
  Future<void> startScan({
    ScanFilter? scanFilter,
    PlatformConfig? platformConfig,
  }) async {}

  @override
  Future<void> stopScan() async {}

  @override
  Future<bool> isScanning() async => false;

  @override
  Future<void> connect(
    String deviceId, {
    Duration? connectionTimeout,
    bool autoConnect = false,
    ConnectionPlatformConfig? platformConfig,
  }) async {
    _connected = true;
    updateConnection(deviceId, true);
  }

  @override
  Future<void> disconnect(String deviceId) async {
    _connected = false;
    updateConnection(deviceId, false);
  }

  @override
  Future<List<BleService>> discoverServices(
    String deviceId,
    bool withDescriptors,
  ) async => [
    BleService('0000fff0-0000-1000-8000-00805f9b34fb', [
      BleCharacteristic.withMetaData(
        deviceId: deviceId,
        serviceId: '0000fff0-0000-1000-8000-00805f9b34fb',
        uuid: '0000fff1-0000-1000-8000-00805f9b34fb',
        properties: const [CharacteristicProperty.notify],
        descriptors: const [],
      ),
      BleCharacteristic.withMetaData(
        deviceId: deviceId,
        serviceId: '0000fff0-0000-1000-8000-00805f9b34fb',
        uuid: '0000fff2-0000-1000-8000-00805f9b34fb',
        properties: const [CharacteristicProperty.writeWithoutResponse],
        descriptors: const [],
      ),
    ]),
  ];

  @override
  Future<void> setNotifiable(
    String deviceId,
    String service,
    String characteristic,
    BleInputProperty bleInputProperty,
  ) async {}

  @override
  Future<Uint8List> readValue(
    String deviceId,
    String service,
    String characteristic, {
    Duration? timeout,
  }) async => Uint8List(0);

  @override
  Future<void> writeValue(
    String deviceId,
    String service,
    String characteristic,
    Uint8List value,
    BleOutputProperty bleOutputProperty,
  ) async {
    writes.add(Uint8List.fromList(value));
  }

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) async => expectedMtu;

  @override
  Future<int> readRssi(String deviceId) async => -60;

  @override
  Future<void> requestConnectionPriority(
    String deviceId,
    BleConnectionPriority priority,
  ) async {}

  @override
  Future<bool> isPaired(String deviceId) async => false;

  @override
  Future<bool> pair(String deviceId) async => true;

  @override
  Future<void> unpair(String deviceId) async {}

  @override
  Future<BleConnectionState> getConnectionState(String deviceId) async =>
      _connected
          ? BleConnectionState.connected
          : BleConnectionState.disconnected;

  @override
  Future<List<BleDevice>> getSystemDevices(List<String>? withServices) async =>
      const [];
}
