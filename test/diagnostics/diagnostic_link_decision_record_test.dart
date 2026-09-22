import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiagnosticLink Architecture Decision Record Contract', () {
    late String adrPath;
    late File adrFile;
    late String content;

    setUpAll(() {
      adrPath = 'docs/architecture/diagnostic-link-decision.md';
      adrFile = File(adrPath);
      expect(adrFile.existsSync(), isTrue, reason: '$adrPath must exist.');
      content = adrFile.readAsStringSync();
    });

    test('ADR file exists and records Accepted status for existing ELM scope only', () {
      expect(content, contains('Accepted for the existing ELM-backed architecture only'));
      expect(content, contains('Parent Issue'));
      expect(content, contains('[#9]'));
      expect(content, contains('ccb3281c309ea417a90e80008e6dc0137cf1d42f'));
      expect(
        content,
        contains('This ADR does not choose implementations for #14, #15, or #16.'),
      );
    });

    test('ADR records unambiguous core decisions and rejects unmeasured sidecars', () {
      // 1. Existing ELM path remains Native Dart
      expect(
        content,
        contains('Existing ELM path: Native Dart / Flutter remains adopted.'),
      );

      // 2. Desktop sidecar for ELM is strictly NOT ADOPTED
      expect(
        content,
        contains('Desktop sidecar for the existing ELM path: NOT ADOPTED.'),
      );

      // Fail-close: if someone claims desktop sidecar is adopted without NOT ADOPTED
      final falseAdoptionPattern = RegExp(
        r'Desktop sidecar for the existing ELM path:\s*ADOPTED\b',
        caseSensitive: false,
      );
      expect(
        falseAdoptionPattern.hasMatch(content),
        isFalse,
        reason: 'Desktop sidecar must never be marked ADOPTED for existing ELM path.',
      );

      // 3. Future sidecars are candidate-only and issue-owned
      expect(
        content,
        contains('Future sidecar: candidate-only and issue-owned; requires independent evidence before adoption.'),
      );

      // 4. Explicit negative declaration preventing universal overclaims
      expect(
        content,
        contains('claim that Native Dart is universally superior'),
      );
    });

    test('ADR references future transport candidates and classifies them honestly', () {
      expect(content, contains('#14'));
      expect(content, contains('SocketCAN'));

      expect(content, contains('#15'));
      expect(content, contains('DoIP'));

      expect(content, contains('#16'));
      expect(content, contains('J2534'));

      // Ledger classifications
      expect(content, contains('`MEASURED / VERIFIED`'));
      expect(content, contains('`CANDIDATE / NOT ADOPTED`'));
      expect(content, contains('`NOT MEASURED`'));
    });

    test('ADR contains mandatory IPC and security contract for any future sidecar', () {
      final requiredIpcTerms = <String>[
        'Typed protocol version',
        'Request ID',
        'Connection generation',
        'Absolute deadline + cancellation',
        'Authenticated client',
        'Local-only endpoint by default',
        'Bounded message sizes',
        'Bounded queue / resource owner',
        'No arbitrary shell execution',
        'No arbitrary DLL/library path',
        'Pinned dependencies + hashes/lockfiles',
        'Clean shutdown and stale-request retirement',
        'No uncertain auto-replay',
      ];

      for (final term in requiredIpcTerms) {
        expect(
          content.toLowerCase(),
          contains(term.toLowerCase()),
          reason: 'ADR must enforce IPC contract requirement: "$term"',
        );
      }
    });

    test('ADR contains mandatory benchmark contract before any future sidecar adoption', () {
      final requiredBenchmarkTerms = <String>[
        'Process startup / ready time',
        'Bounded request IPC round-trip',
        'p50',
        'p95',
        'App + worker memory / RSS delta',
        'Package / archive size delta',
        'Worker crash / restart recovery behavior',
        'Exact environment provenance',
        'Raw log and artifact hashes',
      ];

      for (final term in requiredBenchmarkTerms) {
        expect(
          content.toLowerCase(),
          contains(term.toLowerCase()),
          reason: 'ADR must enforce benchmark requirement: "$term"',
        );
      }
    });

    test('ADR enforces strict capability, safety, and no-flashing boundaries', () {
      expect(
        content,
        contains('DiagnosticLink capability does not imply raw CAN, raw ISO-TP, UDS, DoIP, or J2534'),
      );
      expect(
        content,
        contains('Transport and link availability does not imply an OEM command exists'),
      );
      expect(
        content,
        contains('Discovery and support does not imply actuation authorization'),
      );
      expect(
        content,
        contains('No flashing or programming capability'),
      );
      expect(
        content,
        contains('no flashing, calibration, bootloader entry, memory writing, or ECU reflashing capability whatsoever'),
      );
      expect(
        content,
        contains('Issue #10 (Service Classification) and the separate active-test authorization and qualification gates remain authoritative'),
      );
    });

    test('ADR records rollback and compatibility boundaries', () {
      expect(content, contains('Zero runtime code changes'));
      expect(content, contains('Zero transport migration'));
      expect(content, contains('Zero schema changes'));
      expect(content, contains('Zero Demo fallback impact'));
      expect(content, contains('reverting this documentation file and its associated contract test'));
    });

    test('All local evidence and script paths referenced in ADR exist in repository', () {
      final referencedPaths = <String>[
        'test/emulator_integration_test.dart',
        'tool/desktop_wifi_oracle/run.sh',
        'docs/verification/rig-matrix.md',
        'docs/platform-support.md',
        'tool/packaging/macos_dmg.sh',
        'tool/packaging/windows_zip.sh',
        'tool/packaging/linux_tarball.sh',
      ];

      for (final path in referencedPaths) {
        expect(
          content,
          contains(path),
          reason: 'ADR must reference evidence path: "$path"',
        );

        final entity = File(path).existsSync() ? File(path) : Directory(path);
        expect(
          entity.existsSync(),
          isTrue,
          reason: 'Referenced repo path "$path" must exist on disk.',
        );
      }
    });

    test('ADR strictly rejects unmeasured metric drift, invalid symbol names, and enforces evidence boundaries', () {
      // 1. Prohibit unmeasured numeric claims in cost matrix / findings
      expect(
        content,
        isNot(contains('0 ms additional startup')),
        reason: 'ADR must not fabricate unmeasured 0 ms sidecar startup metrics.',
      );
      expect(
        content,
        isNot(contains('60–120 MB RSS')),
        reason: 'ADR must not cite unmeasured RSS numbers without project artifacts.',
      );
      expect(
        content,
        isNot(contains('zero measurable benefit')),
        reason: 'ADR must not claim zero measurable benefit when no prototype was benchmarked.',
      );

      // 2. Prohibit non-existent symbol names and enforce delivered types
      expect(
        content,
        isNot(contains('DiagnosticOwnershipKind')),
        reason: 'DiagnosticOwnershipKind does not exist in codebase (use DiagnosticOwnershipMode).',
      );
      expect(
        content,
        isNot(contains('DiagnosticOwnershipToken')),
        reason: 'DiagnosticOwnershipToken does not exist in codebase (use DiagnosticOwnership).',
      );
      expect(
        content,
        contains('DiagnosticOwnershipMode'),
        reason: 'ADR must cite correct delivered enum DiagnosticOwnershipMode.',
      );
      expect(
        content,
        contains('DiagnosticOwnership'),
        reason: 'ADR must cite correct delivered class DiagnosticOwnership.',
      );

      // 3. Pin physical L4 field evidence to BLE on GT86
      expect(
        content,
        contains('Toyota GT86'),
        reason: 'Physical field evidence must reference the actual GT86 test vehicle.',
      );
      expect(
        content,
        contains('Bluetooth Low Energy'),
        reason: 'Physical field evidence must pin L4 medium to BLE.',
      );

      // 4. Pin that Ircama functional path does not overclaim Mode 08 discovery or freeze frame
      expect(
        content,
        contains('does not claim Mode 08 discovery or freeze-frame execution'),
        reason: 'Ircama loopback evidence must not overclaim Mode 08 discovery or freeze-frame read.',
      );
    });
  });
}
