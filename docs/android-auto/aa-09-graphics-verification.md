# AA-09 — Android Auto metric graphics

Status: implementation and verification in progress (2026-10-11).

Home, Health and Powertrain previously presented metrics as text-only rows.
The graphic pass adds monochrome vector symbols for each metric and redundant
semantic warning tint while retaining each localized title, reading and unit.
The shared car-core implementation also applies to AAOS.

## Design decision

See [DESIGN.md](../../DESIGN.md), especially Information architecture,
Visual language, Accessibility and Implementation constraints.

[Pane refresh rules](https://developer.android.com/reference/androidx/car/app/model/PaneTemplate)
require stable template titles, row counts and row titles. Live values therefore
remain secondary text. The IoT prototype uses established templates; no custom
Surface, animated gauge, bitmap chart, range assumption or fabricated history
is introduced. Full curves remain on the phone. The existing read-only
bridge, approximately 1 Hz model-diff refresh, speed arbitration, localization
and parked-only diagnostic behavior are retained.

Icons use resource-backed CarIcon with host-default tint. Established warning
states request semantic warning tint and preserve warning text because the host
may override color. Missing/stale readings retain their existing text; icon
presence does not claim a current reading or healthy vehicle.

This local engineering result does not resolve the [AA-00 category gate](aa-00-eligibility.md)
or establish production Google Play approval.

## Verification record

Exact source/APK binding, native tests, projected/automotive builds, current DHU
screen profiles, host day/night behavior, and owned cleanup will be recorded
here after execution. Prior AA-06 evidence retains its historical source and
is not treated as a capture of this change.
