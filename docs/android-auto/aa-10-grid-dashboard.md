# AA-10 — Grid dashboard prototype

Status: **PARTIAL** (2026-10-13). Local native/Flutter regressions, protected
contracts and three debug builds passed. AAOS lint remains **FAIL_FATAL** with
one reproduced baseline error; host acceptance and feature CI remain incomplete.
Google production category review remains **CATEGORY_FIT_UNRESOLVED**.
This record is separate from the historical [AA-09 Pane evidence](aa-09-graphics-verification.md).

## Implementation

`TelltaleCarSession` launches `CarHomeScreen(graphicalDashboard = true)`.
Graphical Home builds the official `GridTemplate` with fixed-priority Speed,
RPM, Coolant and Voltage items. The English Grid uses the shorter Voltage title
to avoid observed host ellipsis; the numerical Pane retains Module Voltage, and
zh-TW/zh-CN retain 模組電壓/模块电压. Each item has a localized stable title,
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
actual finite live reading. A live minimum gets an endpoint marker; missing
readings get neither an arc nor a marker. Native text is always retained. Existing
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

## Local verification

The clean statistics and log-name index are recorded in
[local-verification.json](aa-10/evidence/local-verification.json). Raw logs remain
in the task's sibling `evidence/` directory (`../evidence/` from the repository
root); they are not copied into the repository. No runner network address,
token, credential or absolute personal path is included in the clean receipt.

The feature is based on integrated main `75bc622a0d4e5aa6cc7837b58ae7cfbe69c3bbf1`.
Implementation commits are `2a70ed15e5952b6c5d67fb482b703f7429fb5e6b` and
`89acccfbbb914774fd38f49250906b4498e1038c`; CI configuration is separately
recorded at `4aea4710f98c18afe89855e9c6a615d599b2dfb2`. Results below are local
execution evidence, not a latest feature-pipeline result. The earlier broad
tool gates ran in the initial uncommitted feature working tree based on
`7edc00761886efe092d85a668c5a75b13e14e2b8`. They attest neither a clean baseline
nor the final snapshot; their scope is retained separately.

| Check and scope | Result | Evidence names |
| --- | --- | --- |
| Integrated Flutter regression | PASS — 4386 passed, 23 opt-in skips; analyzer 0 issues | `merged-flutter-tests.log`, `merged-flutter-analyze.log` |
| Required localization | PASS — 12/12; receipt source is `2a70ed15e5952b6c5d67fb482b703f7429fb5e6b` | `merged-l10n-required.log`, `merged-l10n-required/receipt.json` |
| Feature native regression | PASS — car-core 260, field 66, carProto 66; 0 failures/errors/skips in each suite. Includes Grid structure, constraints/fallback, data/warning semantics, stale timeout, renderer and refresh/lifecycle regressions | `android-final-summary.json`, `merged-android-final.log`, `short-title-final.log` |
| Native lint and debug builds | PASS — car-core lint 0 errors/6 warnings; field and carProto lint each 0 errors/12 warnings; field, carProto and automotive debug APK builds passed | `android-final-summary.json`, `merged-android-final.log`, `short-title-final.log` |
| AAOS lint | FAIL_FATAL — 1 `Instantiatable` error: `CarAppActivity` must extend Activity; 3 warnings. The unchanged `7edc0076` baseline reproduces the same error in an isolated copy; integration at `75bc622a` did not modify Android sources. This remains a failed gate, without suppression or relaxation | `aaos-lint-final.log`, `baseline-aaos-lint.log` |
| Integrated protected car gates | PASS — car contracts 32; merged-manifest isolation; Pigeon generated-code drift 0 | `final-car-contracts.log`, `merged-manifest-isolation.log`, `merged-pigeon-codegen.log` |
| Earlier feature-working-tree tooling | PASS with HEAD `7edc0076` and initial uncommitted Grid changes — Python tool suite 914, AA-08 pytest 20, mode08 unit 17; mode08-required and WS10-S1 required checks; WS10-S2 native Debug 11/11 and Release 11/11 | `python-tools.log`, `python-aa08-pytest.log`, `python-mode08.log`, `mode08-required.log`, `ws10-s1-required.log`, `ws10-s2-native/summary.json` |
| Project CI configuration | PASS — project CI lint valid, 0 warnings. Tags select existing project runner 57287642 (`r9700x-docker`, online): `r9700x`, `grok-box`, `ondemand`, `telltale`. Main pipeline 2941350409/job 17131555614 demonstrates that runner's Docker executor only; it is not a feature-run result | `ci-lint-result.json`, `runner-9700x.json`, `main-pipeline-jobs.json`, `main-9700x-job-trace.log` |

## Remaining acceptance matrix

Unit/model, renderer and local build checks do not establish projected Android
Auto or physical head-unit acceptance. No protected gate was relaxed.

| Check | Observed evidence and remaining scope | Result |
| --- | --- | --- |
| Owned AAOS layout/function | Final v3 APK installed hash matched on 1024×768 landscape and 800×1280 portrait. Complete day Grid, live host zero marker, tile → numerical Pane → Powertrain, direct Health, unknown-speed block and zero-speed Diagnostic Codes entry observed. No OBD values or codes invented | PASS for these observed simulator cases; other lanes remain unverified |
| Host text and day/night | One bounded change to the documented host GPU produced complete day frames. Night still lost static native/system text while dark gauges remained visible; final portrait night was not repeated | PARTIAL — night readability NOT_VERIFIED; portrait night NOT_RUN |
| Host task quota | Verify actual steps for non-loading DTC Summary item-count changes, loading/refresh transitions and Back operations; static path depth alone does not establish quota acceptance | PENDING — existing dynamic DTC-list behavior remains a host-validation gap |
| Feature CI execution | Project configuration is valid; no feature pipeline result has been created/claimed in this receipt | PENDING |
| Projected DHU | Installed phone image exposes only an Android Auto stub; no functioning projection host is available | NOT_RUN |
| Physical vehicle/head unit | No real vehicle operation or compatibility acceptance in this task | NOT_RUN |
| Google category/image-policy review | Formal IoT/OBD eligibility and dashboard image review remain unresolved; production promotion is outside this task | NOT_RUN — CATEGORY_FIT_UNRESOLVED |

AAOS work is limited to an owned read-only simulator. Injected VHAL or fixture
values are simulated; they do not become DHU results or real-vehicle evidence.
Historical AA-09 captures remain separate. Theme or size cases without usable
host evidence remain PARTIAL/PENDING or NOT_RUN, not a pass inferred from UI tests.

## Candidate and publication receipt

- AAOS final candidate source: `89acccfbbb914774fd38f49250906b4498e1038c`
- Native-file manifest SHA-256: `683fdb118e9fc9f6c19b458438bb42ecffca1db28ad40729d0000dabee334e2d`
- AAOS candidate v3 APK SHA-256: `45e38320d45ff09edbd66a19d7764bd1e9fa2c818e425ea93f2ae9df149feb70`
- Published code branch: `feature/aa-grid-instruments-20261013`; code push/readback matched `4aea4710f98c18afe89855e9c6a615d599b2dfb2`. Final documentation-tip readback is retained in the task completion receipt.
- Simulator evidence and raw image hashes: [AAOS receipt](aa-10/evidence/aaos/receipt.json). Owned processes, private ADB and runtime data were removed; original AVDs/global ADB were not changed.
- Projected DHU: NOT_RUN (Android Auto stub only)
- Production category review: CATEGORY_FIT_UNRESOLVED


## Actual AAOS host captures

These unmodified images come from the owned API33 Automotive simulator and the
exact APK above. They do not establish Android Auto or physical vehicle acceptance.
The host chose four tiles in a single row at both tested sizes.

![Landscape day with missing readings](aa-10/evidence/aaos/landscape-day-missing.png)

![Portrait day with missing readings](aa-10/evidence/aaos/portrait-day-missing.png)

![Simulated live host zero, with a minimum marker](aa-10/evidence/aaos/landscape-day-live-zero.png)

[Transient 48 km/h diagnostic image](aa-10/evidence/aaos/landscape-transient-48-diagnostic.png)
shows a real callback-driven reading and proportional arc, but includes missing
static text. Injection/readback/capture timing did not prove a synchronized
0 → 48 → 0 sequence, and the backing read-only VHAL values stayed zero. Steady
moving-entry rejection remains NOT_VERIFIED. The read-only property write attempt
was rejected and was not escalated to new permissions or root.

[Night diagnostic image](aa-10/evidence/aaos/landscape-night-diagnostic.png)
shows the dark gauge palette while native/system text is absent. It is retained
as a failure observation, not a night-readability pass. Host OBD warning, stale
and unsupported-PID lanes were NOT_RUN; their native/model tests are separate.
