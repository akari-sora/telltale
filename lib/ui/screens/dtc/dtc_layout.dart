import '../../../obd/dtc/dtc.dart';
import '../../../state/dtc_scan.dart';
import '../../adaptive/adaptive_layout.dart';

/// Selection key uniquely identifying an observed DTC.
///
/// DTC identity consists of code + kind + sourceId.
/// Same code reported by two controllers (e.g. ECM vs TCM) or in two modes
/// (Stored vs Pending) are distinct diagnostic observations.
typedef DtcSelectionKey = ({
  String code,
  DtcKind kind,
  String? sourceId,
});

/// Computes the unique [DtcSelectionKey] for an observed [Dtc].
DtcSelectionKey dtcSelectionKey(Dtc dtc) => (
  code: dtc.code,
  kind: dtc.kind,
  sourceId: dtc.sourceId,
);

/// Completeness of an observed DTC.
enum DtcObservationCompleteness {
  complete,
  partial,
}

/// An observed DTC read during a scan, tagged with completeness.
class DtcObservation {
  const DtcObservation({
    required this.dtc,
    required this.completeness,
  });

  final Dtc dtc;
  final DtcObservationCompleteness completeness;

  DtcSelectionKey get key => dtcSelectionKey(dtc);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DtcObservation &&
          runtimeType == other.runtimeType &&
          dtc == other.dtc &&
          completeness == other.completeness;

  @override
  int get hashCode => Object.hash(dtc, completeness);
}

/// Collects complete and partial DTC observations from category results.
///
/// Complete observations take precedence: if a DTC with the exact same identity
/// appears in both [codes] and [partial], the complete observation wins.
List<DtcObservation> collectDtcObservations(
  Map<DtcKind, DtcCategoryResult> results,
) {
  final list = <DtcObservation>[];
  final seen = <DtcSelectionKey>{};

  // Complete codes take precedence:
  for (final kind in DtcKind.values) {
    final result = results[kind];
    if (result == null) continue;
    for (final dtc in result.codes) {
      final key = dtcSelectionKey(dtc);
      if (seen.add(key)) {
        list.add(DtcObservation(
          dtc: dtc,
          completeness: DtcObservationCompleteness.complete,
        ));
      }
    }
  }

  // Partial codes added if not already present in complete:
  for (final kind in DtcKind.values) {
    final result = results[kind];
    if (result == null) continue;
    for (final dtc in result.partial) {
      final key = dtcSelectionKey(dtc);
      if (seen.add(key)) {
        list.add(DtcObservation(
          dtc: dtc,
          completeness: DtcObservationCompleteness.partial,
        ));
      }
    }
  }

  return list;
}

/// Layout decisions for DTC screen across foldable and adaptive window classes.
abstract final class DtcLayout {
  /// Target fixed width for the master DTC list pane in a two-pane layout.
  static const double masterWidth = 400.0;

  /// Returns true when the DTC screen should present a master-detail two-pane
  /// layout instead of a single-pane list.
  ///
  /// Contract:
  /// - Horizontal separating hinge (tabletop posture) forces single-pane.
  /// - Vertical separating hinge (book posture) enables two-pane regardless of
  ///   window class.
  /// - Expanded window class (usable width >= 840) enables two-pane when no
  ///   horizontal separator exists.
  static bool useTwoPane(AdaptiveLayout layout) {
    if (layout.hasHorizontalSeparator) {
      return false;
    }

    return layout.hasVerticalSeparator || layout.isExpanded;
  }
}
