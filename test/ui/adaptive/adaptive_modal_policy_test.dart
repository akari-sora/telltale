import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/ui/adaptive/adaptive_modal.dart';

void main() {
  group('AdaptiveModalPolicy pure tests (FOLD-04)', () {
    test('F04-01: 599x800 without hinge resolves to bottomSheet', () {
      final layout = AdaptiveModalPolicy.resolve(
        size: const Size(599, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
      );

      expect(layout.surface, AdaptiveModalSurface.bottomSheet);
      expect(layout.panelConstraints.maxWidth, 599.0);
    });

    test('F04-02: 600x800 and 839x800 resolve to medium constrained bottomSheet', () {
      final layout600 = AdaptiveModalPolicy.resolve(
        size: const Size(600, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
      );

      expect(layout600.surface, AdaptiveModalSurface.bottomSheet);
      expect(layout600.panelConstraints.maxWidth, 600.0);

      final layout839 = AdaptiveModalPolicy.resolve(
        size: const Size(839, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
      );

      expect(layout839.surface, AdaptiveModalSurface.bottomSheet);
      expect(layout839.panelConstraints.maxWidth, 600.0);
    });

    test('F04-03: 840x800 resolves to sideSheet', () {
      final layout = AdaptiveModalPolicy.resolve(
        size: const Size(840, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
      );

      expect(layout.surface, AdaptiveModalSurface.sideSheet);
      expect(layout.panelConstraints.maxWidth, AdaptiveModalPolicy.sideSheetMaxWidth);
    });

    test('F04-04: 700 wide with vertical separating hinge resolves to single region sideSheet', () {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(340, 0, 360, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.unknown,
      );

      final layout = AdaptiveModalPolicy.resolve(
        size: const Size(700, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [hinge],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
      );

      expect(layout.surface, AdaptiveModalSurface.sideSheet);
      expect(layout.region.left, 360.0);
      expect(layout.region.right, 700.0);
      expect(layout.region.overlaps(hinge.bounds), isFalse);
    });

    test('F04-05: LTR vertical hinge trailing preference selects right physical region', () {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(490, 0, 510, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.unknown,
      );

      final layout = AdaptiveModalPolicy.resolve(
        size: const Size(1000, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [hinge],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
      );

      expect(layout.region, const Rect.fromLTRB(510, 0, 1000, 800));
    });

    test('F04-06: RTL vertical hinge trailing preference selects left physical region', () {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(490, 0, 510, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.unknown,
      );

      final layout = AdaptiveModalPolicy.resolve(
        size: const Size(1000, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [hinge],
        textDirection: TextDirection.rtl,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
      );

      expect(layout.region, const Rect.fromLTRB(0, 0, 490, 800));
    });

    test('F04-07: horizontal separating hinge forces dialog even when sideSheet requested', () {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(0, 390, 800, 410),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.unknown,
      );

      final layout = AdaptiveModalPolicy.resolve(
        size: const Size(800, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [hinge],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
      );

      expect(layout.surface, AdaptiveModalSurface.dialog);
      expect(layout.region.overlaps(hinge.bounds), isFalse);
    });

    test('F04-08: horizontal unequal region selects larger usable region', () {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(0, 200, 800, 220),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.unknown,
      );

      final layout = AdaptiveModalPolicy.resolve(
        size: const Size(800, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [hinge],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
      );

      // Top region is 0..200 (height 200), bottom region is 220..800 (height 580)
      expect(layout.surface, AdaptiveModalSurface.dialog);
      expect(layout.region, const Rect.fromLTRB(0, 220, 800, 800));
    });

    test('F04-09: SafeArea viewPadding shrinks available region', () {
      final layout = AdaptiveModalPolicy.resolve(
        size: const Size(1000, 800),
        viewPadding: const EdgeInsets.only(left: 40, top: 50, right: 30, bottom: 60),
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
      );

      expect(layout.region, const Rect.fromLTRB(40, 50, 970, 740));
    });

    test('F04-10: IME viewInsets bounds region above keyboard', () {
      final layout = AdaptiveModalPolicy.resolve(
        size: const Size(1000, 800),
        viewPadding: const EdgeInsets.only(bottom: 20),
        viewInsets: const EdgeInsets.only(bottom: 300),
        displayFeatures: const [],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
      );

      expect(layout.region.bottom, 500.0);
    });

    test('F04-11: caller maxWidth smaller than default constrains panel width', () {
      final layout = AdaptiveModalPolicy.resolve(
        size: const Size(1000, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
        constraints: const BoxConstraints(maxWidth: 400),
      );

      expect(layout.panelConstraints.maxWidth, 400.0);
    });

    test('F04-12: caller maxWidth larger than physical region does not overflow region', () {
      const hinge = DisplayFeature(
        bounds: Rect.fromLTRB(700, 0, 720, 800),
        type: DisplayFeatureType.hinge,
        state: DisplayFeatureState.unknown,
      );

      final layout = AdaptiveModalPolicy.resolve(
        size: const Size(1000, 800),
        viewPadding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        displayFeatures: const [hinge],
        textDirection: TextDirection.ltr,
        isScrollControlled: false,
        widePresentation: AdaptiveModalWidePresentation.sideSheet,
        regionPreference: AdaptiveModalRegionPreference.trailing,
        constraints: const BoxConstraints(maxWidth: 900),
      );

      // Trailing region is 720..1000 (width 280), margin is 16 on each side -> 280 - 32 = 248
      expect(layout.panelConstraints.maxWidth, 248.0);
      expect(layout.panelConstraints.maxWidth, lessThan(300.0));
    });

    test('F04-12b: caller minWidth 500 does not push beyond safe region maxWidth 300', () {
      const safe = BoxConstraints(
        minWidth: 0,
        maxWidth: 300,
        minHeight: 0,
        maxHeight: 600,
      );
      const caller = BoxConstraints(
        minWidth: 500,
        maxWidth: 600,
      );

      final merged = AdaptiveModalPolicy.applyCallerConstraints(
        safe: safe,
        requested: caller,
      );

      expect(merged.maxWidth, lessThanOrEqualTo(300.0));
      expect(merged.minWidth, lessThanOrEqualTo(300.0));
    });

    test('F04-12c: caller maxWidth 420 properly shrinks safe maxWidth 560', () {
      const safe = BoxConstraints(
        minWidth: 0,
        maxWidth: 560,
        minHeight: 0,
        maxHeight: 800,
      );
      const caller = BoxConstraints(
        maxWidth: 420,
      );

      final merged = AdaptiveModalPolicy.applyCallerConstraints(
        safe: safe,
        requested: caller,
      );

      expect(merged.maxWidth, 420.0);
    });
  });
}
