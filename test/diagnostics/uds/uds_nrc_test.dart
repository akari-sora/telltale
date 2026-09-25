import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/uds/uds_nrc.dart';

void main() {
  group('UdsNrc normative standard codes', () {
    test('0x21 busyRepeatRequest is typed non-terminal state', () {
      final nrc = UdsNrc.fromCode(0x21);
      expect(nrc.code, equals(0x21));
      expect(nrc.isKnown, isTrue);
      expect(nrc.isBusyRepeatRequest, isTrue);
      expect(nrc.isResponsePending, isFalse);
      expect(nrc.isTerminal, isFalse);
      expect(nrc.toHex(), equals('0x21'));
      expect(nrc.name, equals('busyRepeatRequest'));
    });

    test('0x78 responsePending is typed non-terminal pending state', () {
      final nrc = UdsNrc.fromCode(0x78);
      expect(nrc.code, equals(0x78));
      expect(nrc.isKnown, isTrue);
      expect(nrc.isResponsePending, isTrue);
      expect(nrc.isBusyRepeatRequest, isFalse);
      expect(nrc.isTerminal, isFalse);
      expect(nrc.toHex(), equals('0x78'));
      expect(nrc.name, equals('responsePending'));
    });

    test('0x31 requestOutOfRange is typed terminal negative state', () {
      final nrc = UdsNrc.fromCode(0x31);
      expect(nrc.code, equals(0x31));
      expect(nrc.isKnown, isTrue);
      expect(nrc.isRequestOutOfRange, isTrue);
      expect(nrc.isTerminal, isTrue);
      expect(nrc.isResponsePending, isFalse);
      expect(nrc.isBusyRepeatRequest, isFalse);
      expect(nrc.toHex(), equals('0x31'));
    });

    test('0x22 conditionsNotCorrect is typed terminal negative state', () {
      final nrc = UdsNrc.fromCode(0x22);
      expect(nrc.code, equals(0x22));
      expect(nrc.isKnown, isTrue);
      expect(nrc.isConditionsNotCorrect, isTrue);
      expect(nrc.isTerminal, isTrue);
      expect(nrc.toHex(), equals('0x22'));
    });

    test('0x33 securityAccessDenied is typed terminal negative state', () {
      final nrc = UdsNrc.fromCode(0x33);
      expect(nrc.code, equals(0x33));
      expect(nrc.isKnown, isTrue);
      expect(nrc.isSecurityAccessDenied, isTrue);
      expect(nrc.isTerminal, isTrue);
      expect(nrc.toHex(), equals('0x33'));
    });

    test('0x11 serviceNotSupported and 0x12 subFunctionNotSupported are distinguished', () {
      final nrc11 = UdsNrc.fromCode(0x11);
      final nrc12 = UdsNrc.fromCode(0x12);
      expect(nrc11.isServiceNotSupported, isTrue);
      expect(nrc11.isSubFunctionNotSupported, isFalse);
      expect(nrc12.isSubFunctionNotSupported, isTrue);
      expect(nrc12.isServiceNotSupported, isFalse);
    });

    test('equality and hashCode are based on code value', () {
      final a = UdsNrc.fromCode(0x31);
      final b = UdsNrc.fromCode(0x31);
      final c = UdsNrc.fromCode(0x21);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('UdsNrc raw/unknown code preservation', () {
    test('unassigned NRC code 0x99 is preserved as unknown with exact code', () {
      final nrc = UdsNrc.fromCode(0x99);
      expect(nrc.code, equals(0x99));
      expect(nrc.isKnown, isFalse);
      expect(nrc.isBusyRepeatRequest, isFalse);
      expect(nrc.isResponsePending, isFalse);
      expect(nrc.isTerminal, isTrue);
      expect(nrc.toHex(), equals('0x99'));
      expect(nrc.name, contains('0x99'));
      expect(nrc.toString(), contains('0x99'));
    });

    test('unassigned NRC code 0x05 is preserved as unknown without coercion', () {
      final nrc = UdsNrc.fromCode(0x05);
      expect(nrc.code, equals(0x05));
      expect(nrc.isKnown, isFalse);
      expect(nrc.toHex(), equals('0x05'));
    });

    test('out of byte range throws ArgumentError', () {
      expect(() => UdsNrc.fromCode(-1), throwsArgumentError);
      expect(() => UdsNrc.fromCode(256), throwsArgumentError);
      expect(() => UdsNrc.fromCode(0x100), throwsArgumentError);
    });
  });
}
