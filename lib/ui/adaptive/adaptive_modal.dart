/// Adaptive modal presentation for foldable and large-screen devices.
///
/// Dispatches between a Material Bottom Sheet (compact/medium),
/// a Trailing Side Sheet (expanded default), or a Centered Dialog (dialog preference or horizontal hinge).
///
/// Hinge-aware: never spans physical separating hinges and always constrains
/// the modal within a single physical region.
library;

import 'dart:math' as math;
import 'dart:ui' show DisplayFeature;

import 'package:flutter/material.dart';

import 'adaptive_layout.dart';
import 'app_breakpoints.dart';

/// Presentation preference for expanded or hinged screens.
enum AdaptiveModalWidePresentation {
  /// Trailing side drawer/sheet anchored to the screen edge.
  sideSheet,

  /// Centered dialog window.
  dialog,
}

/// Preferred physical region when a separating hinge is present.
enum AdaptiveModalRegionPreference {
  /// Leading region (left in LTR, right in RTL).
  leading,

  /// Trailing region (right in LTR, left in RTL).
  trailing,

  /// The region with the largest area.
  largest,
}

/// The actual surface chosen by [AdaptiveModalPolicy].
enum AdaptiveModalSurface {
  /// Material Bottom Sheet pinned to bottom.
  bottomSheet,

  /// Trailing Side Sheet aligned to end.
  sideSheet,

  /// Centered Dialog window.
  dialog,
}

/// Resolved layout geometry for an adaptive modal.
@immutable
class AdaptiveModalLayout {
  const AdaptiveModalLayout({
    required this.surface,
    required this.region,
    required this.panelConstraints,
  });

  /// The surface type to render.
  final AdaptiveModalSurface surface;

  /// The global physical-safe rectangle allocated to the modal.
  final Rect region;

  /// Box constraints for the modal panel inside [region].
  final BoxConstraints panelConstraints;
}

/// Pure geometry and placement policy for adaptive modals.
abstract final class AdaptiveModalPolicy {
  static const double sideSheetTargetWidth = 520.0;
  static const double sideSheetMinWidth = 360.0;
  static const double sideSheetMaxWidth = 560.0;
  static const double dialogMaxWidth = 560.0;
  static const double wideMargin = 16.0;
  static const double mediumMaxWidth = 600.0;

  /// Safely intersects caller-requested constraints with safe bounds.
  ///
  /// Caller constraints can only shrink the panel; they can never expand past
  /// the safe region or hinge boundary.
  @visibleForTesting
  static BoxConstraints applyCallerConstraints({
    required BoxConstraints safe,
    BoxConstraints? requested,
  }) {
    if (requested == null) return safe;

    final maxWidth = math.min(safe.maxWidth, requested.maxWidth);
    final maxHeight = math.min(safe.maxHeight, requested.maxHeight);

    final minWidth = math.min(
      math.max(safe.minWidth, requested.minWidth),
      maxWidth,
    );

    final minHeight = math.min(
      math.max(safe.minHeight, requested.minHeight),
      maxHeight,
    );

    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }

  /// Resolves modal surface and constraints given device metrics and display features.
  static AdaptiveModalLayout resolve({
    required Size size,
    required EdgeInsets viewPadding,
    required EdgeInsets viewInsets,
    required List<DisplayFeature> displayFeatures,
    required TextDirection textDirection,
    required bool isScrollControlled,
    required AdaptiveModalWidePresentation widePresentation,
    required AdaptiveModalRegionPreference regionPreference,
    BoxConstraints? constraints,
    double scrollControlledHeightFactor = 0.86,
  }) {
    // 1. Physical safe area excluding permanent system padding and IME keyboard
    final safeBottomInset = math.max(viewPadding.bottom, viewInsets.bottom);
    final safeRect = Rect.fromLTRB(
      viewPadding.left,
      viewPadding.top,
      math.max(viewPadding.left, size.width - viewPadding.right),
      math.max(viewPadding.top, size.height - safeBottomInset),
    );

    // 2. Base layout analysis from AdaptiveLayout
    final adaptive = AdaptiveLayout.fromValues(
      size: size,
      displayFeatures: displayFeatures,
    );

    // 3. Vertical separating hinge: strictly isolate modal to one physical region
    if (adaptive.hasVerticalSeparator && adaptive.regions.length >= 2) {
      final isRtl = textDirection == TextDirection.rtl;
      Rect chosenRegion;
      switch (regionPreference) {
        case AdaptiveModalRegionPreference.trailing:
          chosenRegion = isRtl ? adaptive.regions.first : adaptive.regions.last;
          break;
        case AdaptiveModalRegionPreference.leading:
          chosenRegion = isRtl ? adaptive.regions.last : adaptive.regions.first;
          break;
        case AdaptiveModalRegionPreference.largest:
          chosenRegion = adaptive.regions.reduce(
            (a, b) => (a.width * a.height) >= (b.width * b.height) ? a : b,
          );
          break;
      }

      final usableRegion = chosenRegion.intersect(safeRect);
      final surface = widePresentation == AdaptiveModalWidePresentation.dialog
          ? AdaptiveModalSurface.dialog
          : AdaptiveModalSurface.sideSheet;

      final maxAllowedW = math.max(
        0.0,
        math.min(
          surface == AdaptiveModalSurface.dialog
              ? dialogMaxWidth
              : sideSheetMaxWidth,
          usableRegion.width - (wideMargin * 2),
        ),
      );
      final maxAllowedH = math.max(0.0, usableRegion.height - (wideMargin * 2));

      final panelConstraints = applyCallerConstraints(
        safe: BoxConstraints(
          minWidth: 0,
          maxWidth: maxAllowedW,
          minHeight: 0,
          maxHeight: maxAllowedH,
        ),
        requested: constraints,
      );

      return AdaptiveModalLayout(
        surface: surface,
        region: usableRegion,
        panelConstraints: panelConstraints,
      );
    }

    // 4. Horizontal separating hinge (Tabletop mode): force single-region Dialog
    if (adaptive.hasHorizontalSeparator && adaptive.regions.length >= 2) {
      final topRegion = adaptive.regions.first.intersect(safeRect);
      final bottomRegion = adaptive.regions.last.intersect(safeRect);

      // Choose region with larger usable height; ties go to top region
      final chosenRegion =
          bottomRegion.height > topRegion.height ? bottomRegion : topRegion;

      final maxAllowedW = math.max(
        0.0,
        math.min(dialogMaxWidth, chosenRegion.width - (wideMargin * 2)),
      );
      final maxAllowedH =
          math.max(0.0, chosenRegion.height - (wideMargin * 2));

      final panelConstraints = applyCallerConstraints(
        safe: BoxConstraints(
          minWidth: 0,
          maxWidth: maxAllowedW,
          minHeight: 0,
          maxHeight: maxAllowedH,
        ),
        requested: constraints,
      );

      return AdaptiveModalLayout(
        surface: AdaptiveModalSurface.dialog,
        region: chosenRegion,
        panelConstraints: panelConstraints,
      );
    }

    // 5. Normal expanded screen (width >= 840, no separating hinge)
    if (size.width >= AppBreakpoints.expanded) {
      final usableRegion = safeRect;
      final surface = widePresentation == AdaptiveModalWidePresentation.dialog
          ? AdaptiveModalSurface.dialog
          : AdaptiveModalSurface.sideSheet;

      final maxAllowedW = math.max(
        0.0,
        math.min(
          surface == AdaptiveModalSurface.dialog
              ? dialogMaxWidth
              : sideSheetMaxWidth,
          usableRegion.width - (wideMargin * 2),
        ),
      );
      final maxAllowedH = math.max(0.0, usableRegion.height - (wideMargin * 2));

      final panelConstraints = applyCallerConstraints(
        safe: BoxConstraints(
          minWidth: 0,
          maxWidth: maxAllowedW,
          minHeight: 0,
          maxHeight: maxAllowedH,
        ),
        requested: constraints,
      );

      return AdaptiveModalLayout(
        surface: surface,
        region: usableRegion,
        panelConstraints: panelConstraints,
      );
    }

    // 6. Compact (< 600) and Medium (600..839) screens: Bottom Sheet
    final isMedium = size.width >= AppBreakpoints.medium;
    final maxAllowedW =
        isMedium ? math.min(mediumMaxWidth, safeRect.width) : safeRect.width;
    final isShortLandscape =
        size.width > size.height &&
        size.height <= AppBreakpoints.shortLandscapeHeight;
    final maxAllowedH = isShortLandscape
        ? safeRect.height
        : (isScrollControlled
            ? safeRect.height * scrollControlledHeightFactor
            : safeRect.height * 0.90);

    final panelConstraints = applyCallerConstraints(
      safe: BoxConstraints(
        minWidth: 0,
        maxWidth: maxAllowedW,
        minHeight: 0,
        maxHeight: maxAllowedH,
      ),
      requested: constraints,
    );

    return AdaptiveModalLayout(
      surface: AdaptiveModalSurface.bottomSheet,
      region: safeRect,
      panelConstraints: panelConstraints,
    );
  }
}

/// Displays an adaptive modal that conforms to device form factor and hinge features.
///
/// On Compact (<600) and Medium (600..839) devices, this renders a Material Bottom Sheet
/// constrained to width <= 600 on medium.
///
/// On Expanded (>=840) or hinged devices, this renders a Side Sheet or Dialog
/// strictly confined within a single safe physical region, preventing hinge intersection.
///
/// Across fold/unfold dynamic transitions, all surfaces share a single unified route,
/// dynamically recalculating geometry and morphing between BottomSheet, SideSheet,
/// and Dialog without destroying child widget state.
///
/// [useRootNavigator] defaults to `true`, unlike Material's modal sheet. The
/// layout policy measures the full window (`MediaQuery` size, padding and
/// display features), so the route has to be laid out in the full-window
/// overlay. The app's tabs live inside go_router's ShellRoute navigator, which
/// is smaller than the window: pushed there, a compact sheet slid under the
/// bottom NavigationBar and an expanded dialog was shifted by the rail width
/// (found on the 1.0.16 release device walk).
Future<T?> showAdaptiveModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  BoxConstraints? constraints,
  AdaptiveModalWidePresentation widePresentation =
      AdaptiveModalWidePresentation.sideSheet,
  AdaptiveModalRegionPreference regionPreference =
      AdaptiveModalRegionPreference.trailing,
  bool? enableDrag,
  bool showDragHandle = true,
  bool useSafeArea = true,
  double scrollControlledHeightFactor = 0.86,
  Color? barrierColor,
  String? barrierLabel,
  RouteSettings? routeSettings,
}) {
  final textDirection = Directionality.of(context);
  final localizations = MaterialLocalizations.of(context);
  final effectiveBarrierLabel =
      barrierLabel ?? localizations.modalBarrierDismissLabel;

  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    _AdaptiveModalRoute<T>(
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _AdaptiveModalHost(
          builder: builder,
          isScrollControlled: isScrollControlled,
          widePresentation: widePresentation,
          regionPreference: regionPreference,
          constraints: constraints,
          scrollControlledHeightFactor: scrollControlledHeightFactor,
          barrierDismissible: barrierDismissible,
          showDragHandle: showDragHandle,
          textDirection: textDirection,
        );
      },
      barrierDismissible: barrierDismissible,
      barrierLabel: effectiveBarrierLabel,
      barrierColor: barrierColor ?? Colors.black54,
      settings: routeSettings,
      transitionDuration: const Duration(milliseconds: 200),
    ),
  );
}

class _AdaptiveModalRoute<T> extends PopupRoute<T> {
  _AdaptiveModalRoute({
    required this.pageBuilder,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.barrierColor = Colors.black54,
    this.transitionDuration = const Duration(milliseconds: 200),
    super.settings,
  });

  final RoutePageBuilder pageBuilder;

  @override
  final bool barrierDismissible;

  @override
  final String? barrierLabel;

  @override
  final Color? barrierColor;

  @override
  final Duration transitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: pageBuilder(context, animation, secondaryAnimation),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: child,
    );
  }
}

class _AdaptiveModalHost extends StatefulWidget {
  const _AdaptiveModalHost({
    required this.builder,
    required this.isScrollControlled,
    required this.widePresentation,
    required this.regionPreference,
    required this.scrollControlledHeightFactor,
    required this.barrierDismissible,
    required this.showDragHandle,
    required this.textDirection,
    this.constraints,
  });

  final WidgetBuilder builder;
  final bool isScrollControlled;
  final AdaptiveModalWidePresentation widePresentation;
  final AdaptiveModalRegionPreference regionPreference;
  final double scrollControlledHeightFactor;
  final bool barrierDismissible;
  final bool showDragHandle;
  final TextDirection textDirection;
  final BoxConstraints? constraints;

  @override
  State<_AdaptiveModalHost> createState() => _AdaptiveModalHostState();
}

class _AdaptiveModalHostState extends State<_AdaptiveModalHost> {
  final GlobalKey _contentKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textDir = widget.textDirection;

    final layout = AdaptiveModalPolicy.resolve(
      size: media.size,
      viewPadding: media.viewPadding,
      viewInsets: media.viewInsets,
      displayFeatures: media.displayFeatures,
      textDirection: textDir,
      isScrollControlled: widget.isScrollControlled,
      widePresentation: widget.widePresentation,
      regionPreference: widget.regionPreference,
      constraints: widget.constraints,
      scrollControlledHeightFactor: widget.scrollControlledHeightFactor,
    );

    final theme = Theme.of(context);

    final content = KeyedSubtree(
      key: _contentKey,
      child: Builder(builder: widget.builder),
    );

    Widget buildPanel() {
      switch (layout.surface) {
        case AdaptiveModalSurface.bottomSheet:
          final childContent = widget.isScrollControlled
              ? SizedBox(
                  height: layout.panelConstraints.maxHeight,
                  width: layout.panelConstraints.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showDragHandle) _buildDragHandle(theme),
                      Expanded(child: content),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showDragHandle) _buildDragHandle(theme),
                    Flexible(child: content),
                  ],
                );

          return Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: layout.panelConstraints,
              child: BottomSheet(
                key: const ValueKey('adaptive-modal-bottom-sheet'),
                elevation: 8,
                backgroundColor: theme.colorScheme.surface,
                clipBehavior: Clip.antiAlias,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                enableDrag: false,
                onClosing: () {},
                builder: (context) => childContent,
              ),
            ),
          );

        case AdaptiveModalSurface.sideSheet:
          return Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ConstrainedBox(
              constraints: layout.panelConstraints,
              child: Material(
                key: const ValueKey('adaptive-modal-side-sheet'),
                elevation: 6,
                color: theme.colorScheme.surface,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: layout.panelConstraints.maxHeight,
                  width: layout.panelConstraints.maxWidth,
                  child: content,
                ),
              ),
            ),
          );

        case AdaptiveModalSurface.dialog:
          return Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: layout.panelConstraints,
              child: Material(
                key: const ValueKey('adaptive-modal-dialog'),
                elevation: 6,
                color: theme.colorScheme.surface,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(24),
                child: widget.isScrollControlled
                    ? SizedBox(
                        height: layout.panelConstraints.maxHeight,
                        child: content,
                      )
                    : content,
              ),
            ),
          );
      }
    }

    final isBottomSheet = layout.surface == AdaptiveModalSurface.bottomSheet;

    return Directionality(
      textDirection: widget.textDirection,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.barrierDismissible ? () => Navigator.of(context).pop() : null,
        child: Stack(
          children: [
            Positioned.fromRect(
              key: const ValueKey('adaptive-modal-region'),
              rect: layout.region,
              child: Padding(
                padding: EdgeInsets.all(
                  isBottomSheet ? 0.0 : AdaptiveModalPolicy.wideMargin,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.deferToChild,
                  onTap: () {},
                  child: buildPanel(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(ThemeData theme) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
