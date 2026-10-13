# AA-10 — Grid dashboard prototype

Status: implementation selected; branch verification **PENDING** (2026-10-13).
Google production category review remains **CATEGORY_FIT_UNRESOLVED**.
This record is separate from the historical [AA-09 Pane evidence](aa-09-graphics-verification.md).

## Implementation

`TelltaleCarSession` launches `CarHomeScreen(graphicalDashboard = true)`.
Graphical Home builds the official `GridTemplate` with fixed-priority Speed,
RPM, Coolant and Module Voltage items. Each item has a localized stable title,
a native secondary reading/status, and a supplementary Bitmap gauge image.
No custom driving Surface, navigation category, permission, dependency or
experimental chart/progress API is added. Car App Library remains pinned at
`1.8.0-rc01`.

The graphical screen queries `ConstraintManager.CONTENT_LIMIT_TYPE_GRID` once
and uses a positive limit capped at four. The resulting count is fixed for the
screen's lifetime, including unsupported PID, missing, stale and disconnected
states. An exception or nonpositive result selects the existing numerical Pane
fallback. The numerical path still uses its own Pane content limit. Direct Home
construction defaults to Pane, retaining baseline behavior and regression coverage.

Each Grid item opens numerical Values Home with Back and Powertrain actions.
Grid's named Health header action opens Health directly, retaining Powertrain
and parked diagnostic navigation. The deepest static path is Grid → Health →
DTC Summary → Detail: four templates. Grid → Values → Powertrain uses three,
and Values has no Health intermediate action. The original numerical fallback
Home retains Health access. These clicks browse read-only data; adapter setup,
PID editing/reordering, DTC
clearing and vehicle commands are not added. Existing motion gates remain in effect.

## Official template constraints

The [IoT guide](https://developer.android.com/training/cars/apps/iot) recommends
GridTemplate for device lists and interaction. This supports the template choice;
it does not resolve OBD telemetry's IoT category fit.

The [task template restrictions](https://developer.android.com/training/cars/apps/library/template-restrictions)
allow up to five templates, but require the fifth to be NavigationTemplate,
PaneTemplate, MessageTemplate, MediaPlaybackTemplate, SignInTemplate or
LongMessageTemplate. ListTemplate is absent from that terminal list. Both DTC
Summary and Detail remain ListTemplate, so the static diagnostic path uses at
most four templates by opening Health directly from Grid. Counting screens alone
is insufficient: non-refresh template changes also consume steps. The design
does not call quota-reset APIs or alter the protected DTC contracts to evade this
limit. Existing changes to a non-loading DTC Summary's item count can consume
additional steps; that behavior remains a host-validation gap. A four-template
static path is not a claim that the entire task quota behavior passed acceptance.
Actual host task-step and Back behavior remain verification requirements.

[GridTemplate refresh rules](https://developer.android.com/reference/androidx/car/app/model/GridTemplate)
require an unchanged template title, item count and item titles, except when the
previous template was loading. Readings and state stay in secondary text and
images. Missing/unsupported signals do not remove items, and live values do not
change titles. The implementation retains approximately 1 Hz model-diff refresh,
immediate refresh for semantic alert transitions, and cancellation of collectors
and pending refresh work when the screen stops. There is no autonomous graphics
refresh loop.

The [Grid UX guidance](https://developer.android.com/design/ui/cars/guides/templates/grid-template)
recommends an action for each item and short primary/secondary text. Item clicks
open the retained values page. Secondary text is a single line and can truncate;
localized warning/freshness copy and RTL numeric isolation need verification.

The official Grid content limit is at least six, but apps still query the actual
host limit and must not rely on overflow items: the host can ignore them.
Verification includes smaller positive limits defensively; implementation caps at four.
[ConstraintManager](https://developer.android.com/reference/androidx/car/app/constraints/ConstraintManager)
also documents host query failure. A successful model construction is not proof
that every head unit supports the same layout.

[GridItem](https://developer.android.com/reference/androidx/car/app/model/GridItem)
recommends a 128 × 128 **dp** image bounding box, with proportional downscaling
when needed. This implementation supplies 128 × 128 **pixel** Bitmap sources;
the host controls their displayed size and column count. A specific 2 × 2 layout,
four large circles, fixed labels or full phone-gauge styling is not guaranteed.
`setItemSize` / image-shape APIs require Car API 8 and are not required here.
`CarProgressBar` requires Car API 9, is experimental and excludes secondary text;
it is not used.

The [GridItem.Builder reference](https://developer.android.com/reference/androidx/car/app/model/GridItem.Builder)
permits Bitmap-backed CarIcon images. Snapshots use Bitmap rather than mutating
the contents of a reused URI, which can be cached by the host. Current online
references include APIs newer than the pinned library; implementation must stay
within the existing dependency and host API contract.

## Graphics and data truth

`CarGaugeGraphic` draws one static snapshot for a formatted current value, with
a metric symbol, labelled endpoints and an arc. A bounded eight-entry CarIcon
cache avoids unbounded retained images. Light/dark pixel palettes follow
`CarContext.isDarkMode`. A warning includes a redundant shape as well as color;
native metric/reading/status text remains the accessible source of information.

| Metric | Labelled display scale | Meaning |
| --- | --- | --- |
| Speed | 0–240 km/h | Visual scale only; not a speed limit or vehicle capability claim |
| RPM | 0–8000 RPM | Visual scale only; not a redline or engine health threshold |
| Coolant | −40–215 °C | Visual scale only; warning decisions remain with the existing alert repository |
| Module Voltage | 0–24 V | Visual scale only; not an inferred charging-system normal range |

Values outside these scales clamp only the arc; native formatted readings are
not clamped to image endpoints. Images do not create telemetry, interpolate
between samples, infer history, or label a vehicle healthy. The existing speed
resolver remains responsible for OBD/host source arbitration. A valid host speed
can still appear when an OBD signal is absent; its source follows the existing
resolver contract, not a guessed substitute.

Missing, unavailable, unsupported, awaiting and incompatible data keep the
existing `--` native text and no value arc. Stale readings keep explicit `Stale`
text and no current-value arc. Zero remains a valid value only when it is an
actual finite live reading; an empty arc at a scale minimum alone does not
distinguish that value from missing, so native text is always retained. Existing
coolant warning lifecycle, including unknown-after-warning state, is preserved.
`matchingAlertSnapshot` permits the matching stream epoch's stale state to retain
an established warning after timeout; a different epoch must not inherit it.
Stale data still has explicit stale text and no current-value arc. Images do not
introduce new thresholds or suppress warning state merely because telemetry
stops being Current.

The [car quality guidelines](https://developer.android.com/docs/quality-guidelines/car-app-quality)
prohibit animated elements while driving and restrict image usage. These
snapshots have no animation timer, interpolated needle, flashing or animated
transition, but approximately 1 Hz live-image updates are not asserted to be an
official policy exemption. Image relevance, glanceability and host behavior
remain review/acceptance questions. The [map Surface guide](https://developer.android.com/training/cars/apps/library/draw-maps)
is for Navigation, POI and Weather map content; it is not used for this IoT prototype.

## Verification matrix

The entries below are planned checks, not executed results. Record commands,
source SHA, output counts and artifact paths before replacing PENDING. Unit/model
and image tests do not establish projected Android Auto or physical head-unit
acceptance. Do not relax protected contracts to obtain a pass.

| Check | Required evidence | Result |
| --- | --- | --- |
| Grid structure and navigation | Fixed metric order; native title/text/image; every item reaches numerical Values Home with Back/Powertrain; named Grid Health action goes directly to Health; Grid -> Health -> DTC Summary -> Detail uses at most four static templates; Grid -> Values -> Powertrain uses three; Values has no Health action; numerical fallback retains Health; no quota-reset workaround | PENDING |
| Host task-quota behavior | Actual host steps including changing non-loading DTC Summary item counts, loading/refresh transitions and Back operations; ListTemplate never placed at the fifth task step | PENDING — existing dynamic DTC-list behavior remains a host-validation gap |
| Host constraints and fallback | Positive limits including below four; cap at four; query once; exception/nonpositive query returns Pane; unsupported/disconnected state preserves title/count | PENDING |
| Signal semantics and speed arbitration | Live/missing/unavailable/unsupported/stale/incompatible/awaiting cases; no invented zero; existing OBD/host source rules; warning/unknown-after-warning state; same-epoch stale timeout retains established warning and a new epoch does not inherit it | PENDING |
| Snapshot renderer | 128 × 128 source dimensions; labelled endpoints; out-of-scale arc clamp with native reading intact; nonfinite value handling; light/dark pixels; warning shape; cache bound | PENDING |
| Refresh and lifecycle | Approximately 1 Hz model-diff updates; unchanged model stays quiet; semantic alerts; stopped/destroyed screen cancels collectors and pending work | PENDING |
| Localization and readability | English/zh-TW/zh-CN native copy; RTL numeric isolation; secondary reading/unit/status retained; no dynamic title | PENDING |
| Native regression | car-core plus projected field/carProto unit suites; preserve baseline Pane tests and hardware/alert/diagnostic/lease contracts | PENDING |
| Android builds and lint | Projected field/carProto and standalone automotive variants; relevant lint output; APK source/hash provenance | PENDING |
| Flutter regression | Relevant car telemetry/diagnostics/lifecycle tests and applicable analyzer/regression gates | PENDING |
| Protected contract gates | Car skeleton, read-only bridge, hardware, manifest isolation and generated-code drift checks; no gate relaxation | PENDING |
| Owned AAOS simulator | Read-only simulated inputs; exact APK/source hashes; unmodified screenshots; title/text/image layout; navigation/motion gates; actual display sizes and host theme behavior | PENDING |
| Projected DHU acceptance | Actual Android Auto host screenshots and navigation/task-step behavior across display sizes and day/night modes | NOT_RUN — installed phone image exposes only an Android Auto stub; no functioning projection host was available |
| Physical vehicle/head unit | Actual device compatibility and acceptance | NOT_RUN — no real vehicle operation is authorized or performed in this task |
| Google category/image-policy review | Formal acceptance of OBD telemetry under the provisional IoT category and new dashboard image usage | NOT_RUN — CATEGORY_FIT_UNRESOLVED; production promotion is outside this task |

AAOS work is limited to an owned read-only simulator, with any injected VHAL or
fixture values explicitly labelled simulated. Simulator results do not become
DHU results or evidence from a real vehicle. Preserve historical AA-09 captures;
save new raw screenshots and logs separately. If a host ignores theme commands
or a size cannot be tested, record that observation or NOT_RUN rather than
claiming day/night or responsive acceptance from pure UI tests.

## Evidence receipt

- Source commit: PENDING
- Remote branch/SHA: PENDING
- APK variant and SHA-256: PENDING
- Commands, results and artifact paths: PENDING
- Actual simulator display sizes/theme observations: PENDING
- Projected DHU: NOT_RUN (Android Auto stub only)
- Production category review: CATEGORY_FIT_UNRESOLVED
