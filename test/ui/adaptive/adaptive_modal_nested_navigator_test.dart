// Regression for the 1.0.16 release device walk (Galaxy S24 Ultra, Pixel 9
// Pro Fold emulator): showAdaptiveModal computes its geometry from the
// full-window MediaQuery, but the app shell hosts every tab inside go_router's
// ShellRoute navigator, which is smaller than the window — minus the bottom
// NavigationBar on phones, minus the NavigationRail on unfolded screens.
//
// Pushed onto that nested navigator, a compact bottom sheet slid underneath the
// NavigationBar (its last row could not be tapped) and an expanded dialog was
// shifted sideways by the rail width. The modal must be laid out in the same
// coordinate space it measures, i.e. on the root navigator.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/ui/adaptive/adaptive_modal.dart';

void main() {
  Future<void> setWindow(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget nestedTab(void Function(BuildContext) onOpen) => Navigator(
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (context) => Center(
            child: ElevatedButton(
              key: const Key('open'),
              onPressed: () => onOpen(context),
              child: const Text('Open'),
            ),
          ),
        ),
      );

  Widget options(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final label in ['First', 'Second', 'Third', 'Last'])
            ListTile(
              title: Text(label),
              onTap: () => Navigator.of(context).pop(label),
            ),
        ],
      );

  testWidgets(
    'compact sheet opened from a nested tab navigator is not hidden under '
    'the bottom NavigationBar',
    (tester) async {
      await setWindow(tester, const Size(400, 800));
      String? popped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: nestedTab((context) {
              showAdaptiveModal<String>(
                context: context,
                builder: options,
              ).then((value) => popped = value);
            }),
            bottomNavigationBar: const SizedBox(
              key: Key('nav-bar'),
              height: 80,
              child: ColoredBox(color: Colors.blue),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      final sheet =
          tester.getRect(find.byKey(const ValueKey('adaptive-modal-bottom-sheet')));
      expect(sheet.bottom, lessThanOrEqualTo(800));
      expect(tester.getRect(find.text('Last')).bottom, lessThanOrEqualTo(800));

      // The row that used to sit behind the bar must be the thing a tap hits.
      await tester.tap(find.text('Last'));
      await tester.pumpAndSettle();
      expect(popped, 'Last');
    },
  );

  testWidgets(
    'expanded dialog opened beside a NavigationRail is centred in the window '
    'and stays on screen',
    (tester) async {
      await setWindow(tester, const Size(1200, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const SizedBox(width: 200, child: ColoredBox(color: Colors.blue)),
                Expanded(
                  child: nestedTab((context) {
                    showAdaptiveModal<String>(
                      context: context,
                      widePresentation: AdaptiveModalWidePresentation.dialog,
                      builder: options,
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      final dialog =
          tester.getRect(find.byKey(const ValueKey('adaptive-modal-dialog')));
      expect(dialog.left, greaterThanOrEqualTo(0));
      expect(dialog.right, lessThanOrEqualTo(1200));
      expect(dialog.center.dx, moreOrLessEquals(600, epsilon: 1));
    },
  );
}
