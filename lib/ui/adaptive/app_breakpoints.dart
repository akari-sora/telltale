/// Width-class breakpoints for Torque adaptive layouts.
///
/// These follow Material 3 guidance (compact < 600, medium 600–839,
/// expanded ≥ 840) with a Torque-specific short-landscape rule for
/// windscreen-mounted usage where vertical pixels are scarce.
library;

/// The three Material 3 width classes, extended with awareness of
/// short-landscape (vehicle-mounted) scenarios.
enum AppWindowClass {
  /// < 600 logical px wide.
  compact,

  /// 600–839 logical px wide.
  medium,

  /// ≥ 840 logical px wide.
  expanded,
}

/// Canonical breakpoint constants and classification helpers.
///
/// All values are in logical pixels. Never hard-code `720`, `600`, or
/// `840` elsewhere — reference this class instead.
abstract final class AppBreakpoints {
  /// Width at which the app transitions from compact to medium.
  static const double medium = 600;

  /// Width at which the app transitions from medium to expanded.
  static const double expanded = 840;

  /// Height below which a landscape window is considered "short".
  ///
  /// Torque-specific: a phone mounted on a windscreen in landscape has
  /// very limited vertical space. In this mode the shell switches to a
  /// [NavigationRail] regardless of width class, and gauges use a
  /// denser layout.
  static const double shortLandscapeHeight = 480;

  /// Returns the [AppWindowClass] for the given logical [width].
  static AppWindowClass widthClass(double width) {
    if (width < medium) return AppWindowClass.compact;
    if (width < expanded) return AppWindowClass.medium;
    return AppWindowClass.expanded;
  }
}

/// Torque navigation policy: determines whether to show a
/// [NavigationRail] (true) or [NavigationBar] (false).
///
/// This is the single source of truth for the shell's navigation
/// chrome decision. Both [AppShell] and tests reference this function.
///
/// Rules (per GPT-6 Pro foldable adaptation plan):
/// - Compact portrait → NavigationBar
/// - Compact short landscape → NavigationRail (vertical pixels scarce)
/// - Medium → NavigationRail
/// - Expanded → NavigationRail
bool shouldUseNavigationRail(AppWindowClass windowClass, bool isShortLandscape) {
  return windowClass != AppWindowClass.compact || isShortLandscape;
}
