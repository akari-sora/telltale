import "dart:ui" show DisplayFeature, DisplayFeatureState, DisplayFeatureType, Rect, Size;

import "package:flutter_test/flutter_test.dart";
import "package:torque_obd/obd/dtc/dtc.dart";
import "package:torque_obd/obd/freeze_frame.dart";
import "package:torque_obd/state/dtc_scan.dart";
import "package:torque_obd/ui/adaptive/adaptive_layout.dart";
import "package:torque_obd/ui/screens/dtc/dtc_layout.dart";

void main() {
  group("DtcLayout pure tests (FOLD-05)", () {
    test("F05-01: 599 width compact window yields single pane", () {
      final layout = AdaptiveLayout.fromValues(
        size: const Size(599, 800),
        displayFeatures: const [],
      );
      expect(DtcLayout.useTwoPane(layout), isFalse);
    });

    test("F05-02: 600–839 width medium window yields single pane", () {
      final layout600 = AdaptiveLayout.fromValues(
        size: const Size(600, 800),
        displayFeatures: const [],
      );
      final layout839 = AdaptiveLayout.fromValues(
        size: const Size(839, 800),
        displayFeatures: const [],
      );
      expect(DtcLayout.useTwoPane(layout600), isFalse);
      expect(DtcLayout.useTwoPane(layout839), isFalse);
    });

    test("F05-03: 840 width expanded window yields two-pane", () {
      final layout = AdaptiveLayout.fromValues(
        size: const Size(840, 800),
        displayFeatures: const [],
      );
      expect(DtcLayout.useTwoPane(layout), isTrue);
    });

    test("F05-04: Medium width with vertical separating hinge yields two-pane", () {
      final layout = AdaptiveLayout.fromValues(
        size: const Size(700, 800),
        displayFeatures: const [
          DisplayFeature(
            bounds: Rect.fromLTWH(340, 0, 20, 800),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );
      expect(layout.hasVerticalSeparator, isTrue);
      expect(DtcLayout.useTwoPane(layout), isTrue);
    });

    test("F05-05: Expanded width with horizontal separating hinge yields single pane", () {
      final layout = AdaptiveLayout.fromValues(
        size: const Size(1000, 800),
        displayFeatures: const [
          DisplayFeature(
            bounds: Rect.fromLTWH(0, 390, 1000, 20),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );
      expect(layout.hasHorizontalSeparator, isTrue);
      expect(DtcLayout.useTwoPane(layout), isFalse);
    });

    test("F05-06: Selection identity distinguishes controllers and DTC kinds", () {
      const storedEcm = Dtc(
        code: "P0300",
        category: DtcCategory.powertrain,
        kind: DtcKind.stored,
        sourceId: "7E8",
        isManufacturerSpecific: false,
      );
      const storedTcm = Dtc(
        code: "P0300",
        category: DtcCategory.powertrain,
        kind: DtcKind.stored,
        sourceId: "7E9",
        isManufacturerSpecific: false,
      );
      const pendingEcm = Dtc(
        code: "P0300",
        category: DtcCategory.powertrain,
        kind: DtcKind.pending,
        sourceId: "7E8",
        isManufacturerSpecific: false,
      );

      final keyStoredEcm = dtcSelectionKey(storedEcm);
      final keyStoredTcm = dtcSelectionKey(storedTcm);
      final keyPendingEcm = dtcSelectionKey(pendingEcm);

      expect(keyStoredEcm, isNot(equals(keyStoredTcm)));
      expect(keyStoredEcm, isNot(equals(keyPendingEcm)));
      expect(keyStoredTcm, isNot(equals(keyPendingEcm)));

      // Identical values evaluate equal
      const storedEcmDuplicate = Dtc(
        code: "P0300",
        category: DtcCategory.powertrain,
        kind: DtcKind.stored,
        sourceId: "7E8",
        isManufacturerSpecific: false,
      );
      expect(keyStoredEcm, equals(dtcSelectionKey(storedEcmDuplicate)));
    });

    test("F05-07: Complete and partial observations both collected into read model", () {
      const completeCode = Dtc(
        code: "P0300",
        category: DtcCategory.powertrain,
        kind: DtcKind.stored,
        sourceId: "7E8",
        isManufacturerSpecific: false,
      );
      const partialCode = Dtc(
        code: "P0420",
        category: DtcCategory.powertrain,
        kind: DtcKind.pending,
        sourceId: "7E8",
        isManufacturerSpecific: false,
      );

      final results = {
        DtcKind.stored: const DtcCategoryResult.codes([completeCode]),
        DtcKind.pending: const DtcCategoryResult.failed(
          DtcReadException(
            "timeout",
            kind: DtcReadFailure.error,
            partial: [partialCode],
          ),
        ),
      };

      final observations = collectDtcObservations(results);
      expect(observations.length, 2);
      expect(observations[0].dtc, completeCode);
      expect(observations[0].completeness, DtcObservationCompleteness.complete);
      expect(observations[1].dtc, partialCode);
      expect(observations[1].completeness, DtcObservationCompleteness.partial);
    });

    test("F05-08: Duplicate identity between complete and partial results in complete winning", () {
      const code = Dtc(
        code: "P0300",
        category: DtcCategory.powertrain,
        kind: DtcKind.stored,
        sourceId: "7E8",
        isManufacturerSpecific: false,
      );

      final combined = {
        DtcKind.stored: const DtcCategoryResult.codes([code]),
        DtcKind.pending: const DtcCategoryResult.failed(
          DtcReadException(
            "partial",
            kind: DtcReadFailure.error,
            partial: [code],
          ),
        ),
      };

      final observations = collectDtcObservations(combined);
      expect(observations.length, 1);
      expect(observations.first.completeness, DtcObservationCompleteness.complete);
    });

    test("F05-09: Selected P0300/stored/7E8 exact-matches freeze frame cause", () {
      const dtc = Dtc(
        code: "P0300",
        category: DtcCategory.powertrain,
        kind: DtcKind.stored,
        sourceId: "7E8",
        isManufacturerSpecific: false,
      );
      const frame = FreezeFrame(
        source: "7E8",
        frameNumber: 0,
        cause: dtc,
        readings: [],
        undecodable: 0,
        unread: 0,
      );

      expect(frame.cause == dtc, isTrue);
    });

    test("F05-10: Same code but different source does not link freeze frame", () {
      const dtc7e8 = Dtc(
        code: "P0300",
        category: DtcCategory.powertrain,
        kind: DtcKind.stored,
        sourceId: "7E8",
        isManufacturerSpecific: false,
      );
      const dtc7e9 = Dtc(
        code: "P0300",
        category: DtcCategory.powertrain,
        kind: DtcKind.stored,
        sourceId: "7E9",
        isManufacturerSpecific: false,
      );
      const frame = FreezeFrame(
        source: "7E8",
        frameNumber: 0,
        cause: dtc7e8,
        readings: [],
        undecodable: 0,
        unread: 0,
      );

      expect(frame.cause == dtc7e9, isFalse);
    });

    test("F05-11: Same code and source but Pending kind does not link stored freeze frame", () {
      const storedDtc = Dtc(
        code: "P0300",
        category: DtcCategory.powertrain,
        kind: DtcKind.stored,
        sourceId: "7E8",
        isManufacturerSpecific: false,
      );
      const pendingDtc = Dtc(
        code: "P0300",
        category: DtcCategory.powertrain,
        kind: DtcKind.pending,
        sourceId: "7E8",
        isManufacturerSpecific: false,
      );
      const frame = FreezeFrame(
        source: "7E8",
        frameNumber: 0,
        cause: storedDtc,
        readings: [],
        undecodable: 0,
        unread: 0,
      );

      expect(frame.cause == pendingDtc, isFalse);
    });
  });
}
