# Design

## Source of truth

Status: Active for the existing phone design and Android for Cars prototype.
Last refreshed: 2026-11-01 (AA-11). Home is a PaneTemplate whose rows carry the
readings, plus one large Speed/RPM gauge image. It replaces the 2026-10-13 Grid
Home (AA-10), whose 64 dp images were too small to read. Host acceptance is
partial (DHU, demo data); it does not establish Google Play category eligibility.

Evidence reviewed: `lib/core/theme/app_colors.dart`, `app_theme.dart`, the
Home/Health/Powertrain screens and tests in `android/car-core`,
`docs/android-auto/aa-00-eligibility.md`, the Grid implementation in
`CarHomeScreen.kt` / `CarGaugeGraphic.kt`, and the historical October 11–12
host evidence recorded in AA-09. Those Pane captures are historical evidence,
not acceptance of the Pane dashboard. See AA-11 for the current verification
record and AA-10 for the superseded Grid.

Official references checked on this date:

- [IoT guide](https://developer.android.com/training/cars/apps/iot)
- [Task template restrictions](https://developer.android.com/training/cars/apps/library/template-restrictions)
- [Pane refresh rules](https://developer.android.com/reference/androidx/car/app/model/PaneTemplate)
- [Pane image size](https://developer.android.com/reference/androidx/car/app/model/Pane.Builder)
- [Android for Cars visual principles](https://developers.google.com/cars/design/design-foundations/visual-principles)
- [Row image and text APIs](https://developer.android.com/reference/androidx/car/app/model/Row.Builder)
- [Car quality guidelines](https://developer.android.com/docs/quality-guidelines/car-app-quality)
- [Android Auto color](https://developers.google.com/cars/design/android-auto/design-system/color)

## Brand

Telltale is a calm, precise vehicle diagnostic instrument. Trust comes from
explicit units, data freshness, and the distinction between observed and
unavailable readings. The phone uses aqua accents, amber caution, and red faults.
Car displays use the host's typography and native text. Pane icons use semantic
host colors; the Home gauge image uses the phone's aqua and red hues on a dark
panel, with separate day and night palettes. Avoid decorative
imagery, fabricated readings, flashing alerts, and unverified safety claims.

## Product goals

Help drivers locate a metric quickly and distinguish a valid reading from a
warning or absent data. Retain read-only telemetry and parked diagnostic flows.
This pass makes the two most-glanced readings large in one static image beside
the native rows. It does not add chart history, pairing, custom driving surfaces,
or new navigation.
Success requires preserved telemetry semantics, passing native template,
localization, lifecycle and boundary tests, and actual host evidence. Unit/model
or bitmap tests alone do not establish head-unit acceptance. The 2026-11-01 DHU
run (Android Auto 17.9, demo data) is partial evidence; see AA-11.

## Personas and jobs

Assumption: the primary user is a vehicle owner monitoring an OBD adapter,
with detailed diagnosis performed while parked or on the phone. Locate speed,
RPM, temperature, or voltage in a short glance; identify a high-temperature
warning without depending on color. Demo/fixture screenshots are promotional
assets with explicit provenance, not evidence from a real vehicle.

## Information architecture

Session launch selects graphical Home: a PaneTemplate with Speed, RPM, Coolant,
Module Voltage, MAP and Engine Load rows (Pane content limit, capped at six,
resolved once per screen) and one Speed/RPM gauge image. Its Health header action
opens Health, which keeps Powertrain and the parked DTC summary/detail. The
former Grid tile → Values hop is gone: Values showed the same rows. The deepest
path, Home → Health → DTC Summary → Detail, uses four templates; Home → Health →
Powertrain uses three. The fifth task template has a restricted terminal
type list that excludes ListTemplate, so diagnostics must not be pushed into
that slot. No quota-reset workaround is used. These paths do not by themselves
prove quota acceptance: non-refresh DTC list updates also need host validation.
Direct construction of Home defaults to the same Pane without an image. Each
metric retains a stable localized title and a unit-bearing secondary reading.
Template title, row count and row titles remain stable across live, missing,
stale, unsupported and disconnected states (the PaneTemplate refresh rule).

## Design principles

Use graphics as a supplementary view of the current reading, with explicit
display scales rather than inferred vehicle limits or history. Retain native
text alongside images, and warning text alongside color and shape. Do not add
needle interpolation, animated transitions or autonomous animation timers.
Snapshots change only with the existing model-diff refresh. The host owns layout
and displayed image size, so a specific four-circle or 2 × 2 layout is not promised.

## Visual language

The Home image is one 320 dp bitmap at the car screen's density (capped at 2×),
with Speed above RPM. Each readout is a bold numeral that dominates its panel, the
unit or a state marker above it, and a thin half-circle arc with a pointer; no
decorative icons or scale labels. On the DHU the numerals measured 39–61 dp cap
height (AA-11), against 16 dp in the former Grid. The numeral repeats the native
row's formatted reading from the same model; the rows stay authoritative. Day and
night palettes follow `CarContext.isDarkMode`; both use a dark panel, and night is
dimmer. Arc scales (0–240 km/h, 0–8000 RPM) are visual, not redlines or health
thresholds. Out-of-scale values clamp only the arc. Absent, unsupported or stale
values draw `--`, no arc and never zero; stale adds a clock and dotted track,
unsupported a prohibition sign. Warnings add a red frame, triangle and red numeral.
Coolant and voltage appear as rows; an established coolant warning keeps its red
row icon and `High` text. The renderer's only zone is the coolant alert region.

Numerical Home, Health and Powertrain retain monochrome vector Row icons with
`CarColor.DEFAULT` or an established semantic warning tint. The host may override
colors; images and tint never replace a native-text explanation. No chart history,
animated needle or custom driving Surface is added.

## Components

Reuse existing localized text, alert state and telemetry ownership.
`CarHomeScreen` renders `PaneTemplate` / `Row`, adding the gauge image in
graphical mode on Car API 4+ hosts. `CarGaugeGraphic` owns the image and a bounded
two-entry CarIcon cache; a rendering failure leaves the Pane without an image. The existing metric
icon helper remains responsible for host-tinted Pane icons. Shared car-core
applies to projected Android Auto and AAOS. No Surface permission, category
change, dependency or experimental chart/progress API is added.

## Accessibility

Target readable host contrast in day/night mode; do not override font sizes or
force phone typography onto a head unit. Native Row text retains the metric
name, value, unit and warning/freshness text for host accessibility. The image is
supplementary; it is not the only explanation. Preserve localized RTL numeric
isolation and existing parked diagnostic gates. Home issues no vehicle command.
Day/night contrast and focus/readability need physical head-unit verification.

## Responsive behavior

Support the host's small landscape, wide and portrait layouts, plus AAOS.
The host chooses image size, row placement and input behavior. Query
`CONTENT_LIMIT_TYPE_PANE` once per Home screen (capped at six) and keep that row
count for its lifetime. Android Auto 17.9 drew the Pane image at 185–289 dp; on
800 × 480 the rows scroll beside it. Check scaling, scrolling and rotary/touch
navigation using the actual host.

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

AndroidX Car App Library remains pinned at 1.8.0-rc01; use established Pane,
List and CarIcon APIs. Keep approximately 1 Hz model-diff refresh, immediate
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
- Pane Home acceptance on AAOS and physical head units, and image-policy review,
  remain pending; owner: car UI/release. Only the DHU with demo data was checked
  (AA-11). No physical vehicle/head-unit acceptance is claimed.
- Richer charts require category/API support and host evidence. Full curves
  remain on the phone.
