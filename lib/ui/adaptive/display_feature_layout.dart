/// Convenience widget that rebuilds with [AdaptiveLayout] data.
///
/// Screens that need adaptive branching wrap their content in this
/// widget instead of calling [MediaQuery] directly. This ensures all
/// display-feature and breakpoint logic is centralised.
library;

import 'package:flutter/material.dart';

import 'adaptive_layout.dart';

/// A widget that provides an [AdaptiveLayout] to its [builder].
///
/// Usage:
/// ```dart
/// DisplayFeatureLayout(
///   builder: (context, layout) {
///     if (layout.hasSeparatingFeature) {
///       return _buildHingedLayout(layout);
///     }
///     if (layout.isExpanded) {
///       return _buildExpandedLayout(layout);
///     }
///     return _buildCompactLayout(layout);
///   },
/// )
/// ```
class DisplayFeatureLayout extends StatelessWidget {
  /// Creates a [DisplayFeatureLayout].
  const DisplayFeatureLayout({
    required this.builder,
    super.key,
  });

  /// Called with the current [AdaptiveLayout] whenever the window
  /// metrics or display features change.
  final Widget Function(
    BuildContext context,
    AdaptiveLayout layout,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, AdaptiveLayout.of(context));
  }
}

/// A two-pane layout that respects hinge position.
///
/// When a separating hinge is present, panes are placed on either
/// side of the physical gap. Otherwise, panes are separated by a
/// thin divider at [primaryFraction] of the available width.
///
/// This widget handles both scenarios described in the GPT-6 Pro plan:
/// ```
/// normal expanded: [ primary ][ divider ][ secondary ]
/// hinged:          [ primary ][ physical hinge ][ secondary ]
/// ```
class AdaptiveTwoPane extends StatelessWidget {
  /// Creates an [AdaptiveTwoPane].
  const AdaptiveTwoPane({
    required this.primary,
    required this.secondary,
    this.primaryWidth,
    this.primaryFraction = 0.4,
    super.key,
  });

  /// The leading pane (typically list or main content).
  final Widget primary;

  /// The trailing pane (typically detail or secondary content).
  final Widget secondary;

  /// Fixed logical width for the primary pane. When non-null, takes
  /// precedence over [primaryFraction].
  final double? primaryWidth;

  /// Fraction of available width allocated to the primary pane when
  /// [primaryWidth] is null.
  final double primaryFraction;

  @override
  Widget build(BuildContext context) {
    final layout = AdaptiveLayout.of(context);

    if (layout.hasSeparatingFeature && layout.regions.length >= 2) {
      return _buildHinged(context, layout);
    }

    return _buildNormal(layout);
  }

  Widget _buildHinged(BuildContext context, AdaptiveLayout layout) {
    final feature = layout.separatingFeature!;
    final regions = layout.regions;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    if (layout.hasVerticalSeparator) {
      // Physical Left | hinge | Physical Right
      return Row(
        textDirection: TextDirection.ltr,
        children: [
          SizedBox(
            width: regions[0].width,
            child: isRtl ? secondary : primary,
          ),
          SizedBox(width: feature.bounds.width),
          SizedBox(
            width: regions[1].width,
            child: isRtl ? primary : secondary,
          ),
        ],
      );
    }

    // Top / hinge / Bottom (horizontal separator, e.g. tabletop posture)
    return Column(
      children: [
        SizedBox(
          height: regions[0].height,
          child: primary,
        ),
        SizedBox(height: feature.bounds.height),
        SizedBox(
          height: regions[1].height,
          child: secondary,
        ),
      ],
    );
  }

  Widget _buildNormal(AdaptiveLayout layout) {
    final totalWidth = layout.size.width;
    final pWidth = primaryWidth ?? totalWidth * primaryFraction;

    return Row(
      children: [
        SizedBox(
          width: pWidth,
          child: primary,
        ),
        const VerticalDivider(width: 1),
        Expanded(child: secondary),
      ],
    );
  }
}
