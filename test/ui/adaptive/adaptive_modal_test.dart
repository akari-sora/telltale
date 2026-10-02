import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/ui/adaptive/adaptive_modal.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    required Size size,
    List<DisplayFeature> displayFeatures = const [],
    EdgeInsets viewPadding = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
    TextDirection textDirection = TextDirection.ltr,
    ValueNotifier<MediaQueryData>? mediaQueryNotifier,
    required void Function(BuildContext) onOpenModal,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.view.displayFeatures = displayFeatures;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetDisplayFeatures);

    final initialMedia = MediaQueryData(
      size: size,
      displayFeatures: displayFeatures,
      viewPadding: viewPadding,
      viewInsets: viewInsets,
    );

    final notifier =
        mediaQueryNotifier ?? ValueNotifier<MediaQueryData>(initialMedia);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return Directionality(
            textDirection: textDirection,
            child: ValueListenableBuilder<MediaQueryData>(
              valueListenable: notifier,
              builder: (context, mediaData, _) {
                return MediaQuery(
                  data: mediaData,
                  child: child!,
                );
              },
            ),
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const Key('open_button'),
                onPressed: () => onOpenModal(context),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );
  }

  group('AdaptiveModal widget tests (FOLD-04)', () {
    testWidgets('F04-13: Compact (<600) presents Material Bottom Sheet', (tester) async {
      await pumpApp(
        tester,
        size: const Size(400, 800),
        onOpenModal: (context) {
          showAdaptiveModal<void>(
            context: context,
            builder: (ctx) => const Text('Compact Content'),
          );
        },
      );

      await tester.tap(find.byKey(const Key('open_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsNothing);
      expect(find.byKey(const ValueKey('adaptive-modal-dialog')), findsNothing);
      expect(find.text('Compact Content'), findsOneWidget);
    });

    testWidgets('F04-14: Medium (700x800) presents constrained Bottom Sheet <= 600', (tester) async {
      await pumpApp(
        tester,
        size: const Size(700, 800),
        onOpenModal: (context) {
          showAdaptiveModal<void>(
            context: context,
            builder: (ctx) => const Text('Medium Content'),
          );
        },
      );

      await tester.tap(find.byKey(const Key('open_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsNothing);

      final sheetRender = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('adaptive-modal-bottom-sheet')),
      );
      expect(sheetRender.size.width, lessThanOrEqualTo(600.0));
    });

    testWidgets('F04-15: Expanded (1000x800) presents Trailing Side Sheet <= 560', (tester) async {
      await pumpApp(
        tester,
        size: const Size(1000, 800),
        onOpenModal: (context) {
          showAdaptiveModal<void>(
            context: context,
            builder: (ctx) => const Text('Expanded Content'),
          );
        },
      );

      await tester.tap(find.byKey(const Key('open_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsNothing);

      final sheetRender = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('adaptive-modal-side-sheet')),
      );
      expect(sheetRender.size.width, lessThanOrEqualTo(560.0));

      final sheetTopRight = tester.getTopRight(
        find.byKey(const ValueKey('adaptive-modal-side-sheet')),
      );
      expect(sheetTopRight.dx, closeTo(1000 - 16.0, 1.0));
    });

    testWidgets('F04-16: Vertical separating hinge in LTR isolates modal to right region', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(490, 0, 510, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.unknown,
      );

      await pumpApp(
        tester,
        size: const Size(1000, 800),
        displayFeatures: const [hinge],
        textDirection: TextDirection.ltr,
        onOpenModal: (context) {
          showAdaptiveModal<void>(
            context: context,
            builder: (ctx) => const Text('Hinged LTR Content'),
          );
        },
      );

      await tester.tap(find.byKey(const Key('open_button')));
      await tester.pumpAndSettle();

      final modalRect = tester.getRect(
        find.byKey(const ValueKey('adaptive-modal-side-sheet')),
      );

      expect(modalRect.left, greaterThanOrEqualTo(510.0));
      expect(modalRect.overlaps(hinge.bounds), isFalse);
    });

    testWidgets('F04-17: Vertical separating hinge in RTL isolates modal to left region', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(490, 0, 510, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.unknown,
      );

      await pumpApp(
        tester,
        size: const Size(1000, 800),
        displayFeatures: const [hinge],
        textDirection: TextDirection.rtl,
        onOpenModal: (context) {
          showAdaptiveModal<void>(
            context: context,
            builder: (ctx) => const Text('Hinged RTL Content'),
          );
        },
      );

      await tester.tap(find.byKey(const Key('open_button')));
      await tester.pumpAndSettle();

      final modalRect = tester.getRect(
        find.byKey(const ValueKey('adaptive-modal-side-sheet')),
      );
      expect(modalRect.right, lessThanOrEqualTo(490.0));
      expect(modalRect.overlaps(hinge.bounds), isFalse);
    });

    testWidgets('F04-18: Horizontal hinge forces dialog in safe region without overlap', (tester) async {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(0, 390, 800, 410),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.unknown,
      );

      await pumpApp(
        tester,
        size: const Size(800, 800),
        displayFeatures: const [hinge],
        onOpenModal: (context) {
          showAdaptiveModal<void>(
            context: context,
            builder: (ctx) => const Text('Tabletop Content'),
          );
        },
      );

      await tester.tap(find.byKey(const Key('open_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adaptive-modal-dialog')), findsOneWidget);

      final modalRect = tester.getRect(
        find.byKey(const ValueKey('adaptive-modal-dialog')),
      );
      expect(modalRect.overlaps(hinge.bounds), isFalse);
    });

    testWidgets('F04-19: Result propagation preserves generic value on pop', (tester) async {
      int? result;

      await pumpApp(
        tester,
        size: const Size(1000, 800),
        onOpenModal: (context) async {
          result = await showAdaptiveModal<int>(
            context: context,
            builder: (ctx) => ElevatedButton(
              key: const Key('dialog_select'),
              onPressed: () => Navigator.pop(ctx, 42),
              child: const Text('Select 42'),
            ),
          );
        },
      );

      await tester.tap(find.byKey(const Key('open_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dialog_select')));
      await tester.pumpAndSettle();

      expect(result, 42);
      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsNothing);
    });

    testWidgets('F04-20: Barrier dismiss on tap outside returns null when dismissible', (tester) async {
      int? result = 999;

      await pumpApp(
        tester,
        size: const Size(1000, 800),
        onOpenModal: (context) async {
          result = await showAdaptiveModal<int>(
            context: context,
            barrierDismissible: true,
            builder: (ctx) => const SizedBox(
              width: 300,
              height: 300,
              child: Text('Panel'),
            ),
          );
        },
      );

      await tester.tap(find.byKey(const Key('open_button')));
      await tester.pumpAndSettle();

      expect(find.text('Panel'), findsOneWidget);

      // Tap on the left side of the screen outside the side sheet
      await tester.tapAt(const Offset(100, 400));
      await tester.pumpAndSettle();

      expect(find.text('Panel'), findsNothing);
      expect(result, isNull);
    });

    testWidgets('F04-21: Non-dismissible barrier ignores taps outside', (tester) async {
      await pumpApp(
        tester,
        size: const Size(1000, 800),
        onOpenModal: (context) {
          showAdaptiveModal<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const SizedBox(
              width: 300,
              height: 300,
              child: Text('Strict Panel'),
            ),
          );
        },
      );

      await tester.tap(find.byKey(const Key('open_button')));
      await tester.pumpAndSettle();

      expect(find.text('Strict Panel'), findsOneWidget);

      // Tap outside
      await tester.tapAt(const Offset(100, 400));
      await tester.pumpAndSettle();

      expect(find.text('Strict Panel'), findsOneWidget);
    });

    testWidgets('F04-22: Fold/unfold resize while modal open recalculates geometry and keeps state', (tester) async {
      final textController = TextEditingController(text: 'Initial text');
      addTearDown(textController.dispose);

      final mediaNotifier = ValueNotifier<MediaQueryData>(
        const MediaQueryData(size: Size(1000, 800)),
      );
      addTearDown(mediaNotifier.dispose);

      await pumpApp(
        tester,
        size: const Size(1000, 800),
        mediaQueryNotifier: mediaNotifier,
        onOpenModal: (context) {
          showAdaptiveModal<void>(
            context: context,
            builder: (ctx) => TextField(
              key: const Key('modal_input'),
              controller: textController,
            ),
          );
        },
      );

      await tester.tap(find.byKey(const Key('open_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsOneWidget);

      // Enter additional text
      await tester.enterText(find.byKey(const Key('modal_input')), 'Draft saved');
      await tester.pump();

      // Now fold device: inject vertical hinge
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(490, 0, 510, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.unknown,
      );

      tester.view.displayFeatures = const [hinge];
      mediaNotifier.value = const MediaQueryData(
        size: Size(1000, 800),
        displayFeatures: [hinge],
      );
      await tester.pumpAndSettle();

      // Modal is still open and within right region
      final rectAfterFold = tester.getRect(
        find.byKey(const ValueKey('adaptive-modal-side-sheet')),
      );
      expect(rectAfterFold.left, greaterThanOrEqualTo(510.0));
      expect(rectAfterFold.overlaps(hinge.bounds), isFalse);

      // Controller input text preserved
      expect(find.text('Draft saved'), findsOneWidget);
    });

    testWidgets('F04-23: IME viewInsets dynamically bounds modal above keyboard', (tester) async {
      await pumpApp(
        tester,
        size: const Size(1000, 800),
        viewInsets: EdgeInsets.zero,
        onOpenModal: (context) {
          showAdaptiveModal<void>(
            context: context,
            builder: (ctx) => const SizedBox(
              width: 400,
              height: 700,
              child: Text('IME Modal'),
            ),
          );
        },
      );

      await tester.tap(find.byKey(const Key('open_button')));
      await tester.pumpAndSettle();

      // Keyboard appears (300px at bottom)
      await pumpApp(
        tester,
        size: const Size(1000, 800),
        viewInsets: const EdgeInsets.only(bottom: 300),
        onOpenModal: (context) {},
      );
      await tester.pumpAndSettle();

      final modalRect = tester.getRect(
        find.byKey(const ValueKey('adaptive-modal-side-sheet')),
      );
      expect(modalRect.bottom, lessThanOrEqualTo(500.0));
    });

    testWidgets('F04-24: Modal morphs from SideSheet to BottomSheet on fold (1000x800 -> 500x800) preserving child state', (tester) async {
      final textController = TextEditingController(text: 'Initial wide state');
      addTearDown(textController.dispose);

      final mediaNotifier = ValueNotifier<MediaQueryData>(
        const MediaQueryData(size: Size(1000, 800)),
      );
      addTearDown(mediaNotifier.dispose);

      await pumpApp(
        tester,
        size: const Size(1000, 800),
        mediaQueryNotifier: mediaNotifier,
        onOpenModal: (context) {
          showAdaptiveModal<void>(
            context: context,
            builder: (ctx) => TextField(
              key: const Key('morph_input_1'),
              controller: textController,
            ),
          );
        },
      );

      await tester.tap(find.byKey(const Key('open_button')));
      await tester.pumpAndSettle();

      // Starts as SideSheet on expanded screen
      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsNothing);

      await tester.enterText(find.byKey(const Key('morph_input_1')), 'Preserved wide to narrow');
      await tester.pump();

      // Fold to compact 500x800
      tester.view.physicalSize = const Size(500, 800);
      mediaNotifier.value = const MediaQueryData(size: Size(500, 800));
      await tester.pumpAndSettle();

      // Morphs seamlessly to BottomSheet
      expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsNothing);
      expect(find.text('Preserved wide to narrow'), findsOneWidget);
    });

    testWidgets('F04-25: Modal morphs from BottomSheet to SideSheet on unfold (500x800 -> 1000x800) preserving child state', (tester) async {
      final textController = TextEditingController(text: 'Initial compact state');
      addTearDown(textController.dispose);

      final mediaNotifier = ValueNotifier<MediaQueryData>(
        const MediaQueryData(size: Size(500, 800)),
      );
      addTearDown(mediaNotifier.dispose);

      await pumpApp(
        tester,
        size: const Size(500, 800),
        mediaQueryNotifier: mediaNotifier,
        onOpenModal: (context) {
          showAdaptiveModal<void>(
            context: context,
            builder: (ctx) => TextField(
              key: const Key('morph_input_2'),
              controller: textController,
            ),
          );
        },
      );

      await tester.tap(find.byKey(const Key('open_button')));
      await tester.pumpAndSettle();

      // Starts as BottomSheet on compact screen
      expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsNothing);

      await tester.enterText(find.byKey(const Key('morph_input_2')), 'Preserved narrow to wide');
      await tester.pump();

      // Unfold to expanded 1000x800
      tester.view.physicalSize = const Size(1000, 800);
      mediaNotifier.value = const MediaQueryData(size: Size(1000, 800));
      await tester.pumpAndSettle();

      // Morphs seamlessly to SideSheet
      expect(find.byKey(const ValueKey('adaptive-modal-side-sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')), findsNothing);
      expect(find.text('Preserved narrow to wide'), findsOneWidget);
    });
  });
}
