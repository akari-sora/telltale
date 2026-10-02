/// Unit tests for [AppBreakpoints] and [AppWindowClass].
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/ui/adaptive/app_breakpoints.dart';

void main() {
  group('AppBreakpoints.widthClass', () {
    test('returns compact for width < 600', () {
      expect(AppBreakpoints.widthClass(0), AppWindowClass.compact);
      expect(AppBreakpoints.widthClass(360), AppWindowClass.compact);
      expect(AppBreakpoints.widthClass(412), AppWindowClass.compact);
      expect(AppBreakpoints.widthClass(599), AppWindowClass.compact);
      expect(AppBreakpoints.widthClass(599.9), AppWindowClass.compact);
    });

    test('returns medium for width 600–839', () {
      expect(AppBreakpoints.widthClass(600), AppWindowClass.medium);
      expect(AppBreakpoints.widthClass(720), AppWindowClass.medium);
      expect(AppBreakpoints.widthClass(839), AppWindowClass.medium);
      expect(AppBreakpoints.widthClass(839.9), AppWindowClass.medium);
    });

    test('returns expanded for width >= 840', () {
      expect(AppBreakpoints.widthClass(840), AppWindowClass.expanded);
      expect(AppBreakpoints.widthClass(1000), AppWindowClass.expanded);
      expect(AppBreakpoints.widthClass(1400), AppWindowClass.expanded);
      expect(AppBreakpoints.widthClass(1812), AppWindowClass.expanded);
    });

    // Boundary-exact tests per GPT-6 Pro test strategy: breakpoint ±1
    test('boundary at 599/600', () {
      expect(AppBreakpoints.widthClass(599), AppWindowClass.compact);
      expect(AppBreakpoints.widthClass(600), AppWindowClass.medium);
    });

    test('boundary at 839/840', () {
      expect(AppBreakpoints.widthClass(839), AppWindowClass.medium);
      expect(AppBreakpoints.widthClass(840), AppWindowClass.expanded);
    });
  });

  group('AppBreakpoints constants', () {
    test('medium is 600', () {
      expect(AppBreakpoints.medium, 600);
    });

    test('expanded is 840', () {
      expect(AppBreakpoints.expanded, 840);
    });

    test('shortLandscapeHeight is 480', () {
      expect(AppBreakpoints.shortLandscapeHeight, 480);
    });
  });
}
