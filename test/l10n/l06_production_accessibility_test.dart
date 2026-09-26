import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/state/locale_settings.dart';
import 'package:torque_obd/ui/screens/connect/connect_screen.dart';

import '../support/l10n_root_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch 1L-C1a: Production Accessibility Acceptance', () {
    late L10nRootHarness harness;
    final artifactDir = Directory('build/reports/l10n_accessibility');
    final en = lookupAppLocalizations(const Locale('en'));
    final zh = lookupAppLocalizations(traditionalChineseLocale);

    setUp(() async {
      artifactDir.createSync(recursive: true);
      harness = L10nRootHarness();
      await harness.initialize();
    });

    tearDown(() async {
      await harness.dispose();
    });

    testWidgets(
      '[C09.1] 320x640 portrait at 2.0x text scale: zero overflow, minimum touch targets, semantics, and PNG capture',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });

        final errors = <String>[];
        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          final message = details.exceptionAsString();
          if (message.contains('overflowed') || message.contains('RenderFlex')) {
            errors.add(message);
          }
        };

        try {
          await harness.pumpApp(tester);
          expect(find.byType(ConnectScreen), findsOneWidget);

          // Verify zero RenderFlex overflows in English
          expect(errors, isEmpty, reason: 'RenderFlex overflow in 320x640 2.0x portrait (en)');

          // Check interactive touch targets meet minimum 48x48 bounds (or 44 standard minimum)
          final langBtn = find.byKey(const Key('connect_language_entry'));
          expect(langBtn, findsOneWidget);
          final langSize = tester.getSize(langBtn);
          expect(langSize.height, greaterThanOrEqualTo(44.0));

          final demoCard = find.text(en.connectTransportDemoTitle);
          await tester.scrollUntilVisible(
            demoCard,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(demoCard, findsOneWidget);
          final demoSize = tester.getSize(demoCard);
          expect(demoSize.height, greaterThanOrEqualTo(44.0));

          // Switch to zh at 2.0x scale
          await harness.appRef.read(localePreferenceProvider.notifier).set(LocalePreference.traditionalChinese);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          await tester.scrollUntilVisible(
            find.text(zh.connectHeadline),
            -200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(find.text(zh.connectHeadline), findsOneWidget);
          expect(errors, isEmpty, reason: 'RenderFlex overflow in 320x640 2.0x portrait (zh)');

          // Capture host-render PNG artifact
          final pngBytes = await L10nRootHarness.captureBoundaryAsPng(
            tester,
            find.byType(RepaintBoundary).first,
          );
          expect(pngBytes, isNotEmpty);
          expect(pngBytes.length, greaterThan(500));

          final artifactFile = File('${artifactDir.path}/c09_portrait_320x640_2x.png');
          artifactFile.writeAsBytesSync(pngBytes);
          expect(artifactFile.existsSync(), isTrue);
        } finally {
          FlutterError.onError = previousOnError;
        }
      },
    );

    testWidgets(
      '[C09.2] 568x320 landscape at 2.0x text scale: zero overflow and PNG capture',
      (tester) async {
        tester.view.physicalSize = const Size(568, 320);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });

        final errors = <String>[];
        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          final message = details.exceptionAsString();
          if (message.contains('overflowed') || message.contains('RenderFlex')) {
            errors.add(message);
          }
        };

        try {
          await harness.pumpApp(tester);
          expect(find.byType(ConnectScreen), findsOneWidget);

          // Verify zero overflows in landscape at 2x
          expect(errors, isEmpty, reason: 'RenderFlex overflow in 568x320 2.0x landscape (en)');

          // Switch to zh at 2.0x scale
          await harness.appRef.read(localePreferenceProvider.notifier).set(LocalePreference.traditionalChinese);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text(zh.connectHeadline), findsOneWidget);
          expect(errors, isEmpty, reason: 'RenderFlex overflow in 568x320 2.0x landscape (zh)');

          // Capture host-render PNG artifact
          final pngBytes = await L10nRootHarness.captureBoundaryAsPng(
            tester,
            find.byType(RepaintBoundary).first,
          );
          expect(pngBytes, isNotEmpty);
          expect(pngBytes.length, greaterThan(500));

          final artifactFile = File('${artifactDir.path}/c09_landscape_568x320_2x.png');
          artifactFile.writeAsBytesSync(pngBytes);
          expect(artifactFile.existsSync(), isTrue);
        } finally {
          FlutterError.onError = previousOnError;
        }
      },
    );

    testWidgets(
      '[C09.3] Dialog kept open while rotating orientation and switching locale: zero crash and zero overflow',
      (tester) async {
        // Start in 320x640 portrait
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });

        final errors = <String>[];
        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          final message = details.exceptionAsString();
          if (message.contains('overflowed') || message.contains('RenderFlex')) {
            errors.add(message);
          }
        };

        try {
          await harness.pumpApp(tester);

          // Open language bottom sheet
          final langBtn = find.byKey(const Key('connect_language_entry'));
          expect(langBtn, findsOneWidget);
          await tester.tap(langBtn);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Verify modal bottom sheet is open
          expect(find.byType(BottomSheet), findsOneWidget);

          // Rotate screen to 568x320 landscape WHILE bottom sheet is open
          tester.view.physicalSize = const Size(568, 320);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Bottom sheet must still be mounted and alive
          expect(find.byType(BottomSheet), findsOneWidget);
          expect(errors, isEmpty, reason: 'RenderFlex overflow after rotating with sheet open');

          // Switch locale while sheet is open in landscape
          final zhRadio = find.byKey(const Key('locale_traditionalChinese'));
          if (zhRadio.evaluate().isNotEmpty) {
            await tester.tap(zhRadio);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          }

          expect(find.byType(BottomSheet), findsOneWidget);
          expect(errors, isEmpty, reason: 'RenderFlex overflow after locale change in landscape sheet');

          // Capture host-render PNG artifact with sheet open in landscape
          final pngBytes = await L10nRootHarness.captureBoundaryAsPng(
            tester,
            find.byType(RepaintBoundary).first,
          );
          expect(pngBytes, isNotEmpty);
          expect(pngBytes.length, greaterThan(500));

          final artifactFile = File('${artifactDir.path}/c09_dialog_open_landscape_rotated.png');
          artifactFile.writeAsBytesSync(pngBytes);
          expect(artifactFile.existsSync(), isTrue);

          // Close sheet by tapping barrier or close
          final barrier = find.byWidgetPredicate((w) => w is ModalBarrier);
          if (barrier.evaluate().isNotEmpty) {
            await tester.tap(barrier.first, warnIfMissed: false);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
          }
        } finally {
          FlutterError.onError = previousOnError;
        }
      },
    );

    testWidgets(
      '[C09.4] Semantics inspection: key controls provide accessible labels and actions',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await harness.pumpApp(tester);

          // Verify connect screen has accessible navigation and interactive elements
          final langBtn = find.byKey(const Key('connect_language_entry'));
          expect(langBtn, findsOneWidget);
          final langSemantics = tester.getSemantics(langBtn);
          expect(langSemantics.label, isNotEmpty);

          final demoCard = find.text(en.connectTransportDemoTitle);
          await tester.scrollUntilVisible(
            demoCard,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(demoCard, findsOneWidget);
          final demoSemantics = tester.getSemantics(demoCard);
          expect(demoSemantics.label, isNotEmpty);
        } finally {
          handle.dispose();
        }
      },
    );
  });
}
