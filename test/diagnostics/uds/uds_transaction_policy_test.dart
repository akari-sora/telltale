import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/diagnostics/uds/uds_transaction_policy.dart';

void main() {
  group('UdsTransactionPolicy', () {
    test('standard profile has correct ISO 14229 defaults', () {
      const policy = UdsTransactionPolicy.standard;
      expect(policy.p2Timeout, const Duration(milliseconds: 50));
      expect(policy.p2StarTimeout, const Duration(milliseconds: 5000));
      expect(policy.totalTimeout, const Duration(milliseconds: 10000));
      expect(policy.maxBusyRepeatRetries, 3);
      expect(policy.busyRepeatDelay, const Duration(milliseconds: 100));
      expect(policy.maxResponsePendingCount, 10);
    });

    test('default constructor matches standard', () {
      final policy = UdsTransactionPolicy();
      expect(policy, UdsTransactionPolicy.standard);
    });

    test('throws ArgumentError on invalid timeout parameters', () {
      expect(
        () => UdsTransactionPolicy(p2Timeout: Duration.zero),
        throwsArgumentError,
      );
      expect(
        () => UdsTransactionPolicy(p2Timeout: const Duration(milliseconds: -1)),
        throwsArgumentError,
      );
      expect(
        () => UdsTransactionPolicy(p2StarTimeout: Duration.zero),
        throwsArgumentError,
      );
      expect(
        () => UdsTransactionPolicy(totalTimeout: Duration.zero),
        throwsArgumentError,
      );
      expect(
        () => UdsTransactionPolicy(
          p2Timeout: const Duration(milliseconds: 200),
          totalTimeout: const Duration(milliseconds: 100),
        ),
        throwsArgumentError,
      );
      expect(
        () => UdsTransactionPolicy(maxBusyRepeatRetries: -1),
        throwsArgumentError,
      );
      expect(
        () => UdsTransactionPolicy(busyRepeatDelay: Duration.zero),
        throwsArgumentError,
      );
      expect(
        () => UdsTransactionPolicy(maxResponsePendingCount: -1),
        throwsArgumentError,
      );
    });

    test('copyWith modifies designated fields and preserves others', () {
      const base = UdsTransactionPolicy.standard;
      final modified = base.copyWith(
        p2Timeout: const Duration(milliseconds: 100),
        maxBusyRepeatRetries: 5,
      );

      expect(modified.p2Timeout, const Duration(milliseconds: 100));
      expect(modified.maxBusyRepeatRetries, 5);
      expect(modified.p2StarTimeout, base.p2StarTimeout);
      expect(modified.totalTimeout, base.totalTimeout);
      expect(modified.busyRepeatDelay, base.busyRepeatDelay);
      expect(modified.maxResponsePendingCount, base.maxResponsePendingCount);
    });

    test('equality and hashCode contract', () {
      final a = UdsTransactionPolicy(
        p2Timeout: const Duration(milliseconds: 25),
        maxBusyRepeatRetries: 2,
      );
      final b = UdsTransactionPolicy(
        p2Timeout: const Duration(milliseconds: 25),
        maxBusyRepeatRetries: 2,
      );
      final c = UdsTransactionPolicy(
        p2Timeout: const Duration(milliseconds: 30),
        maxBusyRepeatRetries: 2,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('toString formatting contains key parameters', () {
      final str = UdsTransactionPolicy.standard.toString();
      expect(str, contains('P2: 50ms'));
      expect(str, contains('P2*: 5000ms'));
      expect(str, contains('Total: 10000ms'));
      expect(str, contains('retries: 3'));
    });
  });
}
