# Design

## Source of truth

Status: Active for the existing phone design and Android for Cars prototype.
Last refreshed: 2026-10-11. This change focuses on Android Auto/AAOS metric
graphics; it does not establish Google Play category eligibility.

Evidence reviewed: `lib/core/theme/app_colors.dart`, `app_theme.dart`, the
Home/Health/Powertrain screens and tests in `android/car-core`,
`docs/android-auto/aa-00-eligibility.md`, and the actual 800×480 DHU dashboard
captured during the October 11 baseline device run. That baseline gave each
metric a title and secondary reading, without a metric graphic.

Official references checked on this date:

- [IoT guide](https://developer.android.com/training/cars/apps/iot)
- [Pane refresh rules](https://developer.android.com/reference/androidx/car/app/model/PaneTemplate)
- [Row image and text APIs](https://developer.android.com/reference/androidx/car/app/model/Row.Builder)
- [Car quality guidelines](https://developer.android.com/docs/quality-guidelines/car-app-quality)
- [Android Auto color](https://developers.google.com/cars/design/android-auto/design-system/color)

## Brand

Telltale is a calm, precise vehicle diagnostic instrument. Trust comes from
explicit units, data freshness, and the distinction between observed and
unavailable readings. The phone uses aqua accents, amber caution, and red faults.
Car displays use the host's semantic colors and typography. Avoid decorative
imagery, simulated readings, flashing alerts, and unverified safety claims.

## Product goals

Help drivers locate a metric quickly and distinguish a valid reading from a
warning or absent data. Retain read-only telemetry and parked diagnostic flows.
This pass adds recognizable metric graphics and redundant warning cues. It
does not add chart history, pairing, custom driving surfaces, or new navigation.
Success means clear actual DHU captures, preserved telemetry semantics, and
passing native template, localization, lifecycle, and boundary tests.

## Personas and jobs

Assumption: the primary user is a vehicle owner monitoring an OBD adapter,
with detailed diagnosis performed while parked or on the phone. Locate speed,
RPM, temperature, or voltage in a short glance; identify a high-temperature
warning without depending on color. Demo/fixture screenshots are promotional
assets with explicit provenance, not evidence from a real vehicle.

## Information architecture

Keep Home → Health → Powertrain and the existing parked DTC summary/detail.
Keep metric order and host content limits. Each metric has a stable localized
title, a unit-bearing secondary reading, and a matching semantic icon. Stable
titles are a functional requirement: changing them consumes Pane task steps.

## Design principles

Use graphics to identify the metric, not to invent its range or history.
Retain text alongside icons, and warning text alongside semantic color.
Favor a stable layout over moving needles, animations, or continuously changing
icons. The host owns layout and sizing, so phone gauge styling is not copied.
The tradeoff is fewer visual chart details in exchange for predictable template
refreshes and readable metrics across head units.

## Visual language

Use simple monochrome vector metric symbols in the standard Row icon slot:
speedometer, tachometer, thermometer, battery, pressure, and engine/status.
Use `CarColor.DEFAULT` normally; use a semantic warning color only when the
existing alert/diagnostic state establishes that warning. Do not dim unavailable
text or claim that an absent value equals zero. The host controls type, spacing,
row size, corners, elevation, and day/night theme. No new animation or palette.

## Components

Reuse `PaneTemplate`, `Row`, existing localized text and alert state. A small
car-core metric icon helper owns resource selection and host-tinted `CarIcon`
creation. Screens own metric/state mapping; telemetry repositories retain data
ownership. Shared Home, Health and Powertrain changes apply to both projected
Android Auto and AAOS. No bitmap charts or custom surface permissions.

## Accessibility

Target readable host contrast in day/night mode; do not override font sizes or
force phone color tokens onto a head unit. Row text retains the metric name,
value, unit and warning/freshness text for host accessibility. Icons are
redundant cues, never the only explanation. Preserve localized RTL numeric
isolation, existing focus/navigation, and read-only rows. No motion is added.

## Responsive behavior

Support the host's small landscape, wide and portrait layouts, plus AAOS.
The host chooses icon size, row placement and input behavior. Honor the queried
Pane content limit and current fallback; do not increase row counts for graphics.
Check scrolling and rotary/touch navigation using the actual host.

## Interaction states

Loading/empty/unavailable show the existing `--` text. Stale readings remain
explicitly stale and do not become plausible numbers. Connected live readings
retain units and formatting. Established coolant warnings retain `High` text
with a redundant warning-colored metric icon. Diagnostic health states use the
existing coordinator/repository decision, not guessed numeric thresholds.
Parked-only disabled diagnostics, disconnect and recovery behavior are retained.

## Content voice

Use short localized metric names and established warning terms. Keep units
consistent; do not add prose summaries, inferred trends, or new abbreviations.
Promotional captions identify Demo/controlled fixture data and actual app source.

## Implementation constraints

AndroidX Car App Library remains pinned at 1.8.0-rc01; use established Row/CarIcon
APIs, no new dependencies or experimental chart/progress APIs. Keep approximately
1 Hz model-diff refresh, stable row titles, lifecycle ownership, speed arbitration,
read-only bridge and motion gates. Do not promote the prototype category into
production. Test icon presence/state mapping, title stability, missing/stale
data, RTL and existing behavioral tests. Build projected and automotive variants;
capture actual DHU day/night and screen-size evidence with APK/source hashes.
The device pass also found a late projection handoff rejected after phone
pause. Repair that existing handoff with exact native lease identity and the
existing background ATRV proof; do not create a second OBD/Flutter session.

## Open questions

- Google Play eligibility for OBD telemetry under IoT remains unresolved; owner:
  product/release. See AA-00. This does not block local prototype improvements.
- A supported future template may allow richer telemetry charts; owner: car UI.
  Revisit only with category/API support and host evidence. Full curves currently
  remain on the phone.
