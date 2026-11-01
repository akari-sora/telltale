# Design

## Source of truth

Status: Active for the existing phone design and Android for Cars prototype.
Last refreshed: 2026-11-01 (Grid gauge visual pass). The 2026-10-13 change added
a GridTemplate dashboard with supplementary gauge images and retains the numerical
Pane dashboard. Host acceptance is partial (DHU, demo data); it does not establish
Google Play category eligibility.

Evidence reviewed: `lib/core/theme/app_colors.dart`, `app_theme.dart`, the
Home/Health/Powertrain screens and tests in `android/car-core`,
`docs/android-auto/aa-00-eligibility.md`, the Grid implementation in
`CarHomeScreen.kt` / `CarGaugeGraphic.kt`, and the historical October 11–12
host evidence recorded in AA-09. Those Pane captures are historical evidence,
not acceptance of the new Grid dashboard. See AA-10 for the new verification record.

Official references checked on this date:

- [IoT guide](https://developer.android.com/training/cars/apps/iot)
- [Grid template UX](https://developer.android.com/design/ui/cars/guides/templates/grid-template)
- [Grid refresh rules](https://developer.android.com/reference/androidx/car/app/model/GridTemplate)
- [Task template restrictions](https://developer.android.com/training/cars/apps/library/template-restrictions)
- [Grid item image and text APIs](https://developer.android.com/reference/androidx/car/app/model/GridItem.Builder)
- [Pane refresh rules](https://developer.android.com/reference/androidx/car/app/model/PaneTemplate)
- [Row image and text APIs](https://developer.android.com/reference/androidx/car/app/model/Row.Builder)
- [Car quality guidelines](https://developer.android.com/docs/quality-guidelines/car-app-quality)
- [Android Auto color](https://developers.google.com/cars/design/android-auto/design-system/color)

## Brand

Telltale is a calm, precise vehicle diagnostic instrument. Trust comes from
explicit units, data freshness, and the distinction between observed and
unavailable readings. The phone uses aqua accents, amber caution, and red faults.
Car displays use the host's typography and native text. Pane icons use semantic
host colors; Grid images use the phone's aqua and red hues on a dark instrument
face, with separate day and night palettes. Avoid decorative
imagery, fabricated readings, flashing alerts, and unverified safety claims.

## Product goals

Help drivers locate a metric quickly and distinguish a valid reading from a
warning or absent data. Retain read-only telemetry and parked diagnostic flows.
This pass adds a grid of static gauge snapshots and redundant warning cues. It
does not add chart history, pairing, custom driving surfaces, or new navigation.
Success requires preserved telemetry semantics, passing native template,
localization, lifecycle and boundary tests, and actual host evidence. Unit/model
or bitmap tests alone do not establish head-unit acceptance. The 2026-11-01 DHU
run (Android Auto 17.9, demo data) is partial evidence; see AA-10.

## Personas and jobs

Assumption: the primary user is a vehicle owner monitoring an OBD adapter,
with detailed diagnosis performed while parked or on the phone. Locate speed,
RPM, temperature, or voltage in a short glance; identify a high-temperature
warning without depending on color. Demo/fixture screenshots are promotional
assets with explicit provenance, not evidence from a real vehicle.

## Information architecture

Session launch selects graphical Home. Its fixed priority is Speed, RPM,
Coolant and Module Voltage, capped by the host's Grid item limit. Each tile opens
the existing numerical Values Home with Back and Powertrain actions. Grid's
named Health header action opens Health directly, retaining Powertrain and
the parked DTC summary/detail. The deepest path, Grid → Health → DTC Summary →
Detail, uses four templates; Grid → Values → Powertrain uses three. Values has
no Health intermediate action. The fifth task template has a restricted terminal
type list that excludes ListTemplate, so diagnostics must not be pushed into
that slot. No quota-reset workaround is used. These paths do not by themselves
prove quota acceptance: non-refresh DTC list updates also need host validation.
Direct construction of Home still defaults to Pane with Health access for the
baseline and numerical fallback. Each metric retains a stable localized title and a
unit-bearing secondary reading. Template titles, tile count and tile titles
remain stable across live, missing, stale, unsupported and disconnected states.

## Design principles

Use graphics as a supplementary view of the current reading, with explicit
display scales rather than inferred vehicle limits or history. Retain native
text alongside images, and warning text alongside color and shape. Do not add
needle interpolation, animated transitions or autonomous animation timers.
Snapshots change only with the existing model-diff refresh. The host owns layout
and displayed image size, so a specific four-circle or 2 × 2 layout is not promised.

## Visual language

Grid images are 128 dp Bitmap snapshots at the car screen's density (capped at
2.5×). The reading is the dominant element: a bold numeral with its unit, a value
arc with a pointer, ticks, and a small metric symbol. The numeral repeats the
native text's formatted reading from the same model; native title, reading, unit
and freshness text stay authoritative. Endpoint labels are not drawn because
Android Auto 17.9 shows Grid images at 64 dp. Day and night palettes follow
`CarContext.isDarkMode`; both use a dark face, and night is dimmer. Display scales
are 0–240 km/h, 0–8000 RPM, −40–215 °C and 0–24 V. These are visual scales, not
redlines, supported PID limits or health thresholds. The only zone is the existing
coolant alert region (105 °C upward), drawn as a hatched band. Out-of-scale values
clamp only the arc. Absent, unsupported or stale values draw `--`, no value arc
and never zero; stale adds a clock and dotted track, unsupported a prohibition
glyph. Established coolant warnings add a triangle, red rim and red numeral while
retaining existing text.

Numerical Home, Health and Powertrain retain monochrome vector Row icons with
`CarColor.DEFAULT` or an established semantic warning tint. The host may override
colors; images and tint never replace a native-text explanation. No chart history,
animated needle or custom driving Surface is added.

## Components

Reuse existing localized text, alert state and telemetry ownership.
`CarHomeScreen` renders `GridTemplate` / `GridItem` in graphical mode and
`PaneTemplate` / `Row` in numerical mode. `CarGaugeGraphic` owns the supplementary
Bitmap snapshots and a bounded eight-entry CarIcon cache. The existing metric
icon helper remains responsible for host-tinted Pane icons. Shared car-core
applies to projected Android Auto and AAOS. No Surface permission, category
change, dependency or experimental chart/progress API is added.

## Accessibility

Target readable host contrast in day/night mode; do not override font sizes or
force phone typography onto a head unit. Native Grid/Row text retains the metric
name, value, unit and warning/freshness text for host accessibility. Image labels
are supplementary and may shrink; they are not the only explanation. Preserve
localized RTL numeric isolation and existing parked diagnostic gates. Grid clicks
only open numerical telemetry; they issue no vehicle command. Day/night contrast
and focus/readability need actual host verification.

## Responsive behavior

Support the host's small landscape, wide and portrait layouts, plus AAOS.
The host chooses image size, grid columns, row placement and input behavior.
Query `CONTENT_LIMIT_TYPE_GRID` once per graphical screen, use a positive limit
capped at four, and retain that count for its lifetime. A failed query or nonpositive
limit selects the original Pane fallback; the Pane path still queries its own
content limit. Large Grid items are requested only on Car API 8 hosts; Android
Auto 17.9 still drew 64 dp images. At that size the in-image numeral is about a
23 dp font, below the 24 dp minimum in the Android for Cars visual principles, so
a Pane with one large composite image is the open alternative (AA-10).
Check scaling, scrolling and rotary/touch navigation using the actual host.

## Interaction states

Loading/empty/unavailable show the existing `--` text. Stale readings remain
explicitly stale and do not become plausible numbers. Connected live readings
retain units and formatting. Current coolant warnings retain `High` text with
redundant warning color and shape. A same-stream-epoch stale timeout retains
the established warning state alongside explicit stale text and no current-value
arc; an unrelated epoch must not inherit that warning. Diagnostic health states use the
existing coordinator/repository decision, not guessed numeric thresholds.
Parked-only disabled diagnostics, disconnect and recovery behavior are retained.

## Content voice

Use short localized metric names and established warning terms. Keep units
consistent; do not add prose summaries, inferred trends, or new abbreviations.
Promotional captions identify Demo/controlled fixture data and actual app source.

## Implementation constraints

AndroidX Car App Library remains pinned at 1.8.0-rc01; use established Grid,
Pane and CarIcon APIs. Keep approximately 1 Hz model-diff refresh, immediate
semantic alert refresh, stable titles/counts, lifecycle ownership, speed
arbitration, read-only bridge and motion gates. Collectors and pending refresh
jobs stop with the screen lifecycle; no infinite graphics loop is introduced.
Do not promote the prototype category into production. Test image/state mapping,
title/count stability, scale clamping, missing/stale data, bounded caching, RTL,
navigation, constraints/fallback and existing behavioral contracts. Build/lint
projected and automotive variants, run Flutter regressions and protected contract
gates, and record exact source/APK hashes with host screenshots where available.
Preserve the earlier exact native lease identity and background ATRV handoff
repair documented in AA-09; do not create a second OBD/Flutter session.

## Open questions

- Google Play eligibility for OBD telemetry under IoT remains unresolved; owner:
  product/release. See AA-00. This does not block local prototype improvements.
- New Grid host acceptance, screenshot readability and image-policy review remain
  pending; owner: car UI/release. Owner decision pending on whether Home should
  become a Pane with a large 2 × 2 gauge image (measured 185–289 dp on the DHU)
  to reach readable numeral sizes. AAOS validation is limited to owned read-only
  simulation. No physical vehicle/head-unit acceptance is claimed.
- Richer charts require category/API support and host evidence. Full curves
  remain on the phone.
