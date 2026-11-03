# AA-11 — Pane Home with one large gauge image

Status: **PARTIAL** (2026-11-01). Native tests, protected car gates and debug builds
passed. Projected DHU checked with Demo simulator data. AAOS, physical head units and
vehicles were not run. Google category and image-policy review remain
**CATEGORY_FIT_UNRESOLVED**. This record supersedes the Grid Home in
[AA-10](aa-10-grid-dashboard.md); AA-10 stays as the history and Grid measurements.

## Why the Grid was replaced

On the DHU with Android Auto 17.9.664044, every Grid image was drawn at 64 × 64 dp,
at 800 × 480, 1280 × 720 and 1920 × 1080 (160 and 240 dpi). `ITEM_SIZE_LARGE` with
negotiated Car API 8 made no difference. In-image numerals were about 16 dp cap
height, the same size as the host's own secondary text. The owner's feedback was
that the readings were too small to read while driving.

The [Android for Cars visual principles](https://developers.google.com/cars/design/design-foundations/visual-principles)
give 32 dp for primary text, 24 dp for secondary text and a 4.5:1 contrast ratio.
They are written for Android Automotive OS and are the closest official guidance for
projection. The target for this change was a numeral cap height of at least 32 dp at
1280 × 720 and at least 24 dp at every other measured configuration.

## Implementation

`TelltaleCarSession` launches `CarHomeScreen(graphicalDashboard = true)`. Home is a
`PaneTemplate`:

- Rows: Speed, RPM, Coolant, Module Voltage, MAP and Engine Load, limited by
  `CONTENT_LIMIT_TYPE_PANE` and capped at six. The limit is resolved once per screen.
  Titles are fixed labels; the secondary text is the reading, `--`, `Stale`, or
  `· High` for an established coolant warning. Row icons keep the existing host
  tint, red for a coolant warning.
- Image: `Pane.Builder.setImage` with one bitmap holding two wide readouts, Speed
  above RPM. Each readout is a large numeral, its unit (or a state marker) above it
  and a thin half-circle arc with a pointer. Coolant and voltage are rows only.
- Header: app icon, title and the existing Health action. Health still opens
  Powertrain and the parked-only DTC summary and detail.

The Grid tile → Values page hop is removed. Values showed the same six rows and a
Powertrain action. Home now shows those rows, and Powertrain is one tap from Health,
so Values added nothing. The Grid-only `car_grid_voltage_title` string is removed.

The image is optional. It is added only when the negotiated Car API level is at least
4 (`Pane.Builder.setImage` requirement). An unknown level, an older host, a renderer
exception or an out-of-memory error leaves the same Pane without an image.

### Image rules

- The numeral is the native row's formatted reading, from the same `MetricRow`. The
  rows stay authoritative and accessible.
- Only a LIVE reading with a finite value draws a numeral, value arc or pointer.
  Missing, unavailable, unsupported, awaiting and incompatible data draw `--`.
  Unsupported adds a prohibition sign. Stale adds a clock and a dotted track. A
  remembered value is never drawn, and zero is never substituted.
- A live minimum keeps its pointer, so a real zero differs from missing data.
- Warning state (from the existing alert repository) adds a red frame, a triangle
  marker and a red numeral. The only zone the renderer can draw is the coolant
  alert region from `CarAlertPolicy.DEFAULT_COOLANT`. Home does not pass coolant
  to the image.
- Arc ranges are unlabelled visual scales (0–240 km/h, 0–8000 RPM), not redlines.
- Separate day and night palettes follow `CarContext.isDarkMode`. Both use a dark
  panel, because the projected template background stayed dark in day mode; night
  is dimmer. `TelltaleCarSession` re-renders the top screen when day/night or
  density changes.
- The bitmap is 320 dp × car density, capped at 2× (640 px). The two-entry cache is
  bounded to about 3.3 MB at the cap. No animation, timer, Surface, permission or
  category change is added.

## Official template rules checked

- [PaneTemplate](https://developer.android.com/reference/androidx/car/app/model/PaneTemplate):
  a new Pane is a refresh when the previous one was loading, or when the template title,
  row count and each row's title are unchanged. Row text and the image may change.
  Unit tests assert that the title, row count and row titles stay the same across live,
  missing, unsupported, stale, disconnected and timed-out data.
- [Pane.Builder.setImage](https://developer.android.com/reference/androidx/car/app/model/Pane.Builder):
  Car API 4; target a 480 × 480 dp bounding box, larger images are scaled down.
- [Template restrictions](https://developer.android.com/training/cars/apps/library/template-restrictions):
  at most five templates per task, and the fifth must be one of NavigationTemplate,
  PaneTemplate, MessageTemplate, MediaPlaybackTemplate, SignInTemplate or
  LongMessageTemplate. Popping back restores quota; the screen popped to must send the same
  template type it last sent. The page does not describe refresh throttling.
- [Car app quality](https://developer.android.com/docs/quality-guidelines/car-app-quality):
  no animated elements (SA-1), contrast (VD-1). IU-1 image usage remains part of the
  unresolved category and image-policy review.

## DHU measurements

Setup: DHU 2.0 (mac-arm64) over ADB to a Galaxy Note9 (Android 10, Android Auto
17.9.664044). carProto debug builds of this branch in their own `.carproto` package,
with Demo simulator readings. The table was measured with APK SHA-256 `9d5cf314…`,
built before the rejected 2 × 2 code and comments were removed. The final tree's
APK `d6bfcb31…` was spot-checked at 1280 × 720 and gave the same 39 dp numerals.
The 2 × 2 row used a temporary, uncommitted build. HostConfig: library 1.8.0-rc01,
host max Car API 8. Screen pixels are converted with the configuration's dpi.

| Configuration | Pane image on screen | 2 × 1 numeral cap height (speed / 4-digit RPM) | 2 × 2 numeral cap height |
| --- | --- | --- | --- |
| 800 × 480 @ 160 | 194 dp | 40 / 41 dp | not run on the host (scaled estimate ≈ 25 dp for 4 digits) |
| 1280 × 720 @ 160 | 187 dp | 39 / 39 dp | measured: 28–29 dp up to 3 digits, **24 dp** for 4-digit RPM |
| 1920 × 1080 @ 160 | 289 dp | 60–61 / 59–61 dp | not run on the host (≈ 37 dp) |
| 1920 × 1080 @ 240 | 280 px = 187 dp | 39 / 39 dp | not run on the host (≈ 24 dp) |

The 2 × 2 layout (four square readouts) missed the 32 dp target at 1280 × 720, so the
2 × 1 layout was kept and the 2 × 2 code removed. For comparison, the previous Grid
showed about 16 dp. The night captures at all four configurations used the night
panel colour (#0B0F14), and the day captures used the day colour (#151B23).

Refresh: over 37.3 s at 1280 × 720 the host received 38 PaneTemplates from Home, at
intervals of 0.972 s minimum, 1.005 s median and 1.109 s maximum. There were no
rejection, quota or exception logs. Every template logged a host-side
`Selectable lists disallowed for template this list` warning. That warning was also
logged for other Pane templates, and rendering was unaffected.

Task path (CAR_SPEED granted to the debug build only, DHU unrestricted, read-only DTC
scan of the Demo ECU on the phone): Home (Pane) → Health (Pane) → DTC summary (List,
three stored codes) → detail (List). The host accepted all four templates without a
quota error. The existing motion gate then closed the DTC screens when the Demo
vehicle began moving, and Back from Health returned to the Home PaneTemplate. The
detail screen was not captured, and no fifth template was pushed.

Not covered on the host: warning, stale and unsupported images (unit tests and review
PNGs only), Car API levels below 4, AAOS, physical head units and vehicles.

## Local verification

| Check | Result |
| --- | --- |
| `:car-core:testDebugUnitTest` | PASS — 270 tests, 0 failures |
| `:app:testFieldDebugUnitTest`, `:app:testCarProtoDebugUnitTest` | PASS — 66 and 66 |
| `:car-core:lintDebug` | 0 errors, 6 warnings (same as before this change) |
| `flutter analyze`; `flutter test test/car` | 0 issues; 98 passed |
| Car contract Python tests, Pigeon drift, merged-manifest isolation | PASS — 39 tests; no drift; isolation verified |
| Field, carProto and automotive debug builds | PASS |

Unrun: the full Flutter suite, AAOS lint (known baseline failure in AA-10) and any
feature CI pipeline.
