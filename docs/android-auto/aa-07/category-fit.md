# Android for Cars Category Fit Analysis (AA-07)

**Document Status:** PROVISIONAL SPECIFICATION & QUALIFICATION PROBE  
**Target Package:** `com.cbstudio.telltale` / `com.cbstudio.telltale.carproto` / `com.cbstudio.telltale.carproto.aaos`  
**Distribution Category:** `androidx.car.app.category.IOT` (IoT Peripheral Telemetry Candidate)  
**Exit Qualification Verdict:** `ELIGIBLE_CANDIDATE (CATEGORY_FIT_UNRESOLVED / READY_FOR_CLOSED_REVIEW)`  
**Evaluation Standard:** Google Android for Cars Quality Guidelines (v1.7+)  

---

## 1. Executive Summary & Category Fit Rationale

Telltale provides a non-distracting, read-only vehicle telemetry and diagnostics monitor on Android Auto and Android Automotive OS (AAOS).

Under Google Play's Android for Cars application categories:
1. **Navigation** (`androidx.car.app.category.NAVIGATION`): Not applicable. Telltale does not provide turn-by-turn routing or map drawing.
2. **Media** (`androidx.car.app.category.MEDIA`): Not applicable. Telltale produces zero audio or playback media sessions.
3. **Point of Interest / POI** (`androidx.car.app.category.POI`): Not applicable. Telltale does not browse charging stations or commercial locations.
4. **Internet of Things / Connected Peripheral Telemetry** (`androidx.car.app.category.IOT`): **CANDIDATE HYPOTHESIS**.
   - **Architectural Fit:** Telltale connects to an external OBD-II adapter hardware device operating as an off-board IoT peripheral sensor. The car module monitors real-time telemetry (RPM, coolant temperature, vehicle speed, module voltage) and diagnostic trouble codes emitted by this connected hardware.
   - **Honest Policy Disclosure:** Google Play's published Android for Cars guidelines define `androidx.car.app.category.IOT` primarily with smart home / device control and status in mind. Google has not published an explicit "Vehicle Telemetry" category for third-party OBD-II monitors. While treating an OBD-II adapter as a connected IoT peripheral is architecturally sound and template-compliant, it has not been canonized as an officially endorsed category mapping by Google Play review.
   - **Qualification Verdict:** **`ELIGIBLE_CANDIDATE (CATEGORY_FIT_UNRESOLVED / READY_FOR_CLOSED_REVIEW)`**. The application is packaged and structured for a Google Play **Closed Testing Track probe** to gather formal reviewer determinations while maintaining complete appeal documentation and phone app isolation.

---

## 2. Google Android for Cars Standard Alignment (Canonical Criteria)

The application has been audited and verified against the canonical Google Android for Cars review criteria (Tier 1 Core App Quality and Tier 2 / Car Ready Criteria applicable to IOT, Android Auto, and AAOS):

### 2.1 Core Quality & Driving Safety Criteria

#### PC-1: Permitted Car App Categories
- **Google Standard:** App does not contain features outside permitted car app categories.
- **Implementation:** App strictly confines its functionality to vehicle telemetry monitoring and connected OBD-II peripheral sensor data under `androidx.car.app.category.IOT`. Contains zero unpermitted category features (no video playback, games, or social feeds). The manifest category declaration `<category android:name="androidx.car.app.category.IOT" />` is declared in `<intent-filter>` of `TelltaleCarAppService` in `android/car-core/src/main/AndroidManifest.xml` per Car App Library IoT implementation specifications.
- **Compliance Status:** **PROVISIONAL CANDIDATE (`READY_FOR_CLOSED_REVIEW`)**.

#### PE-1: Parked-Only Activities
- **Google Standard:** Activities declared for AAOS are restricted to parked setup/settings/sign-in.
- **Implementation:** Zero custom driving activities are declared for AAOS. App delegates 100% of car UI rendering to the host `CarAppService` via official templates. Diagnostic trouble code inspection (`CarDtcSummaryScreen`) and freeze-frame sensor inspection (`CarDtcDetailScreen`) are strictly gated behind `CarDtcMotionGate.isStationary()` and `ParkedOnlyOnClickListener`.
- **Compliance Status:** **PASS**.

#### AC-1: Task Completion Limits
- **Google Standard:** Tasks can be completed in ≤ 5 screens.
- **Implementation:** All user tasks complete within 1 to 2 screens. Launch -> Home telemetry dashboard (1 screen); Home -> DTC Summary (2 screens); Home -> Powertrain telemetry (2 screens). No deep screen nesting exists (max navigation stack depth = 2).
- **Compliance Status:** **PASS**.

#### DR-1: Interaction Response Time
- **Google Standard:** Button and action response time must be ≤ 2 seconds.
- **Implementation:** All UI interactions (screen switching, back actions, tab selection) respond within < 100 ms via reactive `StateFlow` and in-memory caches.
- **Compliance Status:** **PASS**.

#### DR-2: Startup Performance
- **Google Standard:** App must launch and display interactive content within 10 seconds.
- **Implementation:** Screen session initializes and renders the primary gauge screen within ~800 ms in both DHU and AAOS emulator soak runs.
- **Compliance Status:** **PASS**.

#### DR-3: Content Loading Time
- **Google Standard:** Content must load within 10 seconds of user request.
- **Implementation:** Real-time telemetry is streamed continuously via coroutines bound to `Lifecycle.State.RESUMED`. Screen switches and template invalidations complete within < 200 ms.
- **Compliance Status:** **PASS**.

#### EP-1: Expected Performance (Store Description & Functionality Alignment)
- **Google Standard:** App functionality must match what is described in store listings and promotional text.
- **Implementation:** Store listing metadata and reviewer notes accurately state that Telltale provides read-only vehicle telemetry monitoring and stationary DTC fault inspection.
- **Compliance Status:** **PASS**.

#### EP-2: State Preservation & Restoration
- **Google Standard:** App must preserve and restore user state across backgrounding/foregrounding and projection reconnects.
- **Implementation:** Reactive architecture maintains active session state; head unit disconnect cleanly halts collectors, and reconnect restores active screen without crashing or data corruption.
- **Compliance Status:** **PASS**.

#### EP-4: Automotive Store Assets
- **Google Standard:** Minimum 2 portrait (800×1280) and 2 landscape (1024×768) 24-bit RGB PNG screenshots displaying generic AAOS system UI from actual emulator captures.
- **Implementation:** 6 unique standardized 24-bit RGB PNG screenshots natively captured from running Android Automotive OS emulators (3 portrait 800×1280 on `AAOS_Portrait_800x1280` and 3 landscape 1024×768 on `AAOS_Landscape_1024x768`) executing the actual automotive debug APK with VHAL speed events injected. Shared across listing locales (`en-US` and `zh-TW`). Showcases real generic AAOS system UI with system status bars, HVAC navigation bars, vehicle speed, and diagnostic telemetry. Direct `adb exec-out screencap -p` captures with zero synthetic overlays, zero resizing, and zero pasted content.
  *(Note on API distribution: Google Play Developer API officially supports `automotiveScreenshots`. However, currently used `gplay` CLI binary and Fastlane Supply default auto-discovery do not yet auto-upload this directory; staged for manual upload via Play Console or direct API script).*
- **Compliance Status:** **PASS (Emulator Native Captures Verified)**.

#### IN-1: Notifications & Interruptions
- **Google Standard:** Non-driving-related notifications are prohibited; no unsolicited intrusive audio or pop-up interruptions while driving.
- **Implementation:** Requests 0 audio focus, plays 0 audio streams, and posts 0 disruptive popup notifications. Alerts are strictly rendered within the active template view.
- **Compliance Status:** **PASS**.

---

### 2.2 Applicable Tier 2 / Car Ready Quality Criteria Matrix

| ID | Official Criterion Name | Official Criterion Summary | IOT Applicable | Applicable Surface | Implementation & Defense Mechanism | Verification Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **PC-1** | Permitted Car App Categories | App must belong to a supported category and cannot include features outside permitted car app categories | Yes | Android Auto / AAOS | Declared `androidx.car.app.category.IOT` in `TelltaleCarAppService` `<intent-filter>`. Confined to read-only vehicle telemetry & OBD-II peripheral sensor monitoring; zero unpermitted features | **PROVISIONAL CANDIDATE** |
| **PE-1** | Parked-Only Activities | AAOS: App-implemented activities must not provide functionality beyond parked setup, settings, or sign-in | Yes | AAOS | Zero custom driving activities declared for AAOS; 100% templated UI rendered by host via `CarAppService`. In-motion code inspection and deep diagnostic data strictly gated behind `CarDtcMotionGate` and `ParkedOnlyOnClickListener` | **PASS** |
| **AC-1** | Task Completion Limits | Users must be able to complete tasks within 5 screens | Yes | Android Auto / AAOS | Max backstack depth is 2 across entire car app. Primary telemetry completed in 1 screen, health overview in 1 screen, DTC fault summary/detail in 2 screens (well under 5-screen limit) | **PASS** |
| **DR-1** | Action Response Time | Action responses must complete in ≤ 2 seconds | Yes | Android Auto / AAOS | Reactive `StateFlow` local template updates execute < 100 ms; verified via DHU baseline walkthrough | **PASS** |
| **DR-2** | App Startup Time | App session initialization and first frame render must complete within 10 seconds | Yes | Android Auto / AAOS | `onCreateSession` and initial `CarHomeScreen` render complete in ~800 ms in both DHU and AAOS emulator | **PASS** |
| **DR-3** | Content Loading Time | Content loading time must complete within 10 seconds | Yes | Android Auto / AAOS | Telemetry data streams continuously with coroutine dispatcher; screen refresh rate < 200 ms | **PASS** |
| **EP-1** | Store Description Match | App functionality must match what is described in store listings and promotional text | Yes | Play Store | Store descriptions strictly state read-only vehicle telemetry monitoring and stationary DTC fault inspection | **PASS** |
| **EP-2** | State Preservation | App must preserve and restore user state across backgrounding/foregrounding and projection reconnects | Yes | Android Auto / AAOS | Active session state maintained via reactive architecture; clean teardown on stop and seamless restoration on reconnect without crash | **PASS** |
| **EP-4** | Automotive Screenshots | AAOS: App must provide actual capture screenshots on generic AAOS emulator (portrait 800×1280 & landscape 1024×768) reflecting actual app appearance | Yes | Play Store (AAOS) | Natively captured 6 unique screenshots (3 portrait 800×1280 and 3 landscape 1024×768) 24-bit RGB PNG from generic AAOS emulators without resizing or synthetic post-processing; shared across listing locales | **PASS** |
| **IN-1** | Notifications & Interruptions | Non-driving notifications prohibited; no unsolicited intrusive audio or pop-up interruptions while driving | Yes | Android Auto / AAOS | Zero notifications posted while driving; zero audio focus requested; alerts displayed only as in-template status badges | **PASS** |
| **AR-1** | Activity Region & System Cutouts | AAOS: App-implemented Activity interactive UI must not be obscured by system bars or cutouts | Yes | AAOS | Implements 0 custom activities on AAOS; renders 100% via `CarAppService` official Car App Library templates; host layout engine guarantees zero obstruction by system bars or cutouts | **PASS** |
| **SA-1** | Surface Animation | Must not display animated elements while driving; exception for parked Canvas animation directly related to driving task | Yes | Android Auto / AAOS | Zero animations rendered in any template; static text, standard metrics, and static status badges only | **PASS** |
| **AD-1** | In-Car Advertising | Visual and text advertising restrictions on car display; strictly no commercial advertisements while driving | Yes | Android Auto / AAOS | 100% ad-free; zero ad SDKs or promotional text in `:car-core` | **PASS** |
| **IU-1** | Image Usage | Image usage rules on car display; images and icons must be relevant, driver-safe, and obey sizing/contrast standards (not input handling) | Yes | Android Auto / AAOS | Home/Health/Powertrain use app-owned monochrome metric vector resources through `CarIcon`; host-default tint with redundant warning text and semantic warning tint. No bitmap charts or custom surface; see `DESIGN.md` and AA-09 graphics verification | **PASS** |
| **VI-1** | Visual / Phone Flow Prompts | Android Auto: If directing user to interact with phone, car screen must display a prompt indicating to check phone only when safe/parked | Yes | Android Auto | **N/A (Condition Not Triggered / Compliant by Design)**: Telltale car projection never directs the user to interact with or check the phone while driving or projected. Zero phone-handoff flows, modal prompts, or permission delegations to the phone on the car display; car app is a self-contained read-only telemetry and stationary DTC monitor | **N/A** |
| **ST-1** | Scrolling Text | Must not display auto-scrolling (marquee) text | Yes | Android Auto / AAOS | Zero auto-scrolling/marquee text widgets; all strings are static or user-scrolled when permitted | **PASS** |
| **VD-1** | Visual Distraction / Contrast | Icons and colors must meet Android Auto contrast requirements; no distracting high-contrast flashes or non-compliant palettes | Yes | Android Auto / AAOS | Uses host-selected `CarColor.DEFAULT` and semantic warning tokens; actual host day/night rendering is verified separately in AA-09, without claiming a measured contrast ratio from token use alone | **PASS** |
| **TH-1** | Custom Theming | AAOS / Android Auto: If using Car App Library 1.9+ custom theming, app must support both light and dark themes | Yes | Android Auto / AAOS | **N/A (Condition Not Triggered)**: Telltale pins Car App Library 1.8.0-rc01 and does not implement custom theming (`androidx.car.app.theme`); relies entirely on host system day/night semantic color palette (`CarColor`) | **N/A** |
| **NA-1** | Notification Advertising | Prohibits displaying advertisements or commercial messages through notifications | Yes | Android Auto / AAOS | Generates zero notifications; no push notification service in `:car-core` | **PASS** |
| **PA-1** | In-Car Payments | Restricts payment flows in-car; driving payments must comply with strict automotive payment policies | No | Android Auto / AAOS | Telltale contains zero in-car purchasing, checkout, or billing flows | **N/A** |
| **IT-1** | IoT Device Interaction | Driving: view connected device state & simple one-touch control; prohibited from device setup, complex automation flow creation/modification, or fine-grained control while driving | Yes | Android Auto / AAOS | In-motion UI strictly restricted to read-only glanceable vehicle telemetry. Device setup/pairing is offloaded to mobile app; diagnostic DTC troubleshooting and freeze-frame inspection locked behind stationary gate (`speed == 0 km/h` via `CarDtcMotionGate`); Mode 04 clear fault 100% excluded | **PASS** |

---

## 3. Operational Matrix: Driving vs. Parked State Differentiator

| Operational Capability | Driving State (`speed > 0 km/h`) | Parked / Stationary State (`speed == 0 km/h`) | Review Justification |
| :--- | :--- | :--- | :--- |
| **Telemetry Home Dashboard** | Active (Glanceable 4-row Pane) | Active (Glanceable 4-row Pane) | Primary monitor safe at all speeds (<2s glanceability) |
| **Coolant Overheat Alert** | Active In-Template Badge (`High`) | Active In-Template Badge (`High`) | Critical safety alert visible to driver without modal dialog |
| **Vehicle Health Overview** | Active (MIL On/Off, Code count) | Active (Full status breakdown) | High-level summary allowed while driving |
| **Diagnostic Code List** | **LOCKED / BLOCKED** (`Parked only`) | **ACCESSIBLE** (Up to list limit) | Prevents reading lengthy codes while driving (Host & Gate locked) |
| **Freeze Frame Sensor Inspection** | **LOCKED / BLOCKED** | **ACCESSIBLE** (Parked diagnostic tool) | Detailed engineering data restricted to park |
| **Clear DTC (Fault Reset)** | **FORBIDDEN (0% Code in `:car-core`)** | **FORBIDDEN (0% Code in `:car-core`)** | Car module is 100% read-only; zero clearing commands |
| **Adapter Pairing / Reconnect** | **LOCKED** (Read-only status) | **LOCKED** (Managed on phone app) | Head unit is strictly a projection surface |

---

## 4. Exit Qualification Verdict

**Final Assessment: `ELIGIBLE_CANDIDATE (CATEGORY_FIT_UNRESOLVED / READY_FOR_CLOSED_REVIEW)`**  
The Telltale Android for Cars implementation strictly complies with all Google Play driver distraction, template constraint, and performance mandates. The category fit (`androidx.car.app.category.IOT`) is established as a sound candidate hypothesis and is ready for closed testing track review with escalation playbooks prepared.
