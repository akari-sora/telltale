import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/can/can_endpoint.dart';
import 'package:torque_obd/diagnostics/diagnostic_link.dart';

void main() {
  group('CanBitrate', () {
    test('tracks known and unknown bitrate states', () {
      const unknown = CanBitrate.unknown();
      expect(unknown.isKnown, isFalse);
      expect(unknown.value, isNull);
      expect(unknown.toString(), 'unknown');

      final known500k = CanBitrate(500000);
      expect(known500k.isKnown, isTrue);
      expect(known500k.value, 500000);
      expect(known500k.toString(), '500000bps');

      expect(CanBitrate(500000), equals(known500k));
      expect(CanBitrate(250000), isNot(equals(known500k)));
    });

    test('rejects non-positive bitrates', () {
      expect(() => CanBitrate(0), throwsArgumentError);
      expect(() => CanBitrate(-500000), throwsArgumentError);
    });
  });

  group('CanEndpoint: L01 Interface, Identifier Width & Capabilities', () {
    final stdTx = DiagnosticCanIdentifier.standard(0x7E0);
    final stdRx = DiagnosticCanIdentifier.standard(0x7E8);
    final extTx = DiagnosticCanIdentifier.extended(0x18DA10F1);
    final extRx = DiagnosticCanIdentifier.extended(0x18DAF110);

    test('creates valid standard 11-bit endpoint', () {
      final endpoint = CanEndpoint(
        interfaceName: 'vcan0',
        generation: 0,
        physicalTxId: stdTx,
        physicalRxId: stdRx,
        configuredBitrate: CanBitrate(500000),
      );

      expect(endpoint.interfaceName, 'vcan0');
      expect(endpoint.generation, 0);
      expect(endpoint.physicalTxId.isExtended, isFalse);
      expect(endpoint.physicalRxId.isExtended, isFalse);
      expect(endpoint.isFd, isFalse);
      expect(endpoint.addressingMode, CanAddressingMode.normal);
      expect(endpoint.framePayloadLimit, 8);
      expect(endpoint.backendCapability, CanBackendCapability.classicalLoopback);

      expect(() => endpoint.assertSupportedInS1(), returnsNormally);
    });

    test('creates valid extended 29-bit endpoint', () {
      final endpoint = CanEndpoint(
        interfaceName: 'can0',
        generation: 1,
        physicalTxId: extTx,
        physicalRxId: extRx,
      );

      expect(endpoint.physicalTxId.isExtended, isTrue);
      expect(endpoint.physicalRxId.isExtended, isTrue);
      expect(() => endpoint.assertSupportedInS1(), returnsNormally);
    });

    test('rejects mismatched identifier widths between TX and RX', () {
      expect(
        () => CanEndpoint(
          interfaceName: 'vcan0',
          generation: 0,
          physicalTxId: stdTx,
          physicalRxId: extRx,
        ),
        throwsArgumentError,
      );

      expect(
        () => CanEndpoint(
          interfaceName: 'vcan0',
          generation: 0,
          physicalTxId: extTx,
          physicalRxId: stdRx,
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty, blank, or wildcard interface names', () {
      expect(
        () => CanEndpoint(
          interfaceName: '',
          generation: 0,
          physicalTxId: stdTx,
          physicalRxId: stdRx,
        ),
        throwsArgumentError,
      );

      expect(
        () => CanEndpoint(
          interfaceName: '   ',
          generation: 0,
          physicalTxId: stdTx,
          physicalRxId: stdRx,
        ),
        throwsArgumentError,
      );

      expect(
        () => CanEndpoint(
          interfaceName: 'can*',
          generation: 0,
          physicalTxId: stdTx,
          physicalRxId: stdRx,
        ),
        throwsArgumentError,
      );

      expect(
        () => CanEndpoint(
          interfaceName: 'can?0',
          generation: 0,
          physicalTxId: stdTx,
          physicalRxId: stdRx,
        ),
        throwsArgumentError,
      );
    });

    test('rejects negative generation or non-positive payload limits', () {
      expect(
        () => CanEndpoint(
          interfaceName: 'vcan0',
          generation: -1,
          physicalTxId: stdTx,
          physicalRxId: stdRx,
        ),
        throwsArgumentError,
      );

      expect(
        () => CanEndpoint(
          interfaceName: 'vcan0',
          generation: 0,
          physicalTxId: stdTx,
          physicalRxId: stdRx,
          framePayloadLimit: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects classical payload limit exceeding 8 bytes', () {
      expect(
        () => CanEndpoint(
          interfaceName: 'vcan0',
          generation: 0,
          physicalTxId: stdTx,
          physicalRxId: stdRx,
          isFd: false,
          framePayloadLimit: 64,
        ),
        throwsArgumentError,
      );
    });

    test('normal addressing mode prohibits address extensions', () {
      expect(
        () => CanEndpoint(
          interfaceName: 'vcan0',
          generation: 0,
          physicalTxId: stdTx,
          physicalRxId: stdRx,
          addressingMode: CanAddressingMode.normal,
          txAddressExtension: 0x10,
        ),
        throwsArgumentError,
      );
    });

    test('assertSupportedInS1 fails closed for FD, extended addressing, and non-L0 backends', () {
      // 1. CAN FD is unsupported in S1 L0
      final fdEndpoint = CanEndpoint(
        interfaceName: 'can0',
        generation: 0,
        physicalTxId: stdTx,
        physicalRxId: stdRx,
        isFd: true,
        framePayloadLimit: 64,
      );
      expect(
        () => fdEndpoint.assertSupportedInS1(),
        throwsUnsupportedError,
      );

      // 2. Extended addressing is unsupported in S1 L0
      final extAddrEndpoint = CanEndpoint(
        interfaceName: 'can0',
        generation: 0,
        physicalTxId: stdTx,
        physicalRxId: stdRx,
        addressingMode: CanAddressingMode.extended,
        txAddressExtension: 0x50,
      );
      expect(
        () => extAddrEndpoint.assertSupportedInS1(),
        throwsUnsupportedError,
      );

      // 3. SocketCAN / Kernel ISOTP are not admitted as L0 loopback in S1
      final socketCanEndpoint = CanEndpoint(
        interfaceName: 'can0',
        generation: 0,
        physicalTxId: stdTx,
        physicalRxId: stdRx,
        backendCapability: CanBackendCapability.linuxSocketCan,
      );
      expect(
        () => socketCanEndpoint.assertSupportedInS1(),
        throwsUnsupportedError,
      );
    });
  });
}
