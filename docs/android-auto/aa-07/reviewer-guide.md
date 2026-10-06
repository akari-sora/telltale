# Google Play Reviewer Guide: Zero-Hardware Testing & Compliance (AA-07)

**Application Name:** Telltale (Car Module)  
**Package Name:** `com.cbstudio.telltale`  
**Automotive Categories:** `androidx.car.app.category.IOT`  
**Distribution Targets:** Android Auto (Phone Projection) & Android Automotive OS (Embedded Head Unit)  
**Review Target:** Google Play App Review Team  

---

## 1. Overview for Reviewers

Telltale provides a real-time, non-distracting vehicle health and telemetry monitor for drivers. It projects critical vehicle diagnostic telemetry (RPM, vehicle speed, coolant temperature, module voltage) and diagnostic trouble codes onto vehicle head unit displays using Google's official **Android for Cars App Library** (`androidx.car.app`).

### Fundamental Safety Principles
1. **100% Read-Only:** The car screen interface contains **zero vehicle actuation or clearing commands**. OBD-II Mode 04 ("Clear Diagnostic Trouble Codes") is physically omitted from the `:car-core` car module codebase.
2. **Strict Driver Distraction Gating:** Detailed diagnostic trouble codes (DTCs) and freeze-frame sensor values can **only be opened when the vehicle is completely stationary (speed = 0 km/h / Parked)**. While moving, only glanceable tabular gauge metrics are displayed.
3. **No Audio Distraction:** The app generates zero audio output and requests zero audio focus.

---

## 2. Zero-Hardware Testing Instructions (Testing Without a Physical Car)

Reviewers do **not** need a physical vehicle or an ELM327 OBD-II adapter to review and verify all features of Telltale. The application contains a built-in, fully autonomous physics engine simulator.

### Method A: Testing on Desktop Head Unit (DHU) with Phone
1. Install `app-carProto-debug.apk` (or production package) onto an Android phone or phone emulator.
2. Launch Telltale on the phone. On the connection screen, tap **"啟動模擬器" / "Start Demo Simulator"**.
   - The simulator dynamically models a 2.0L turbocharged 4-cylinder engine with correlated physical signals (idle, acceleration, cruising, deceleration, coolant warming, and active DTCs `P0300`, `P0301`).
3. Connect the phone to your computer running the Google Android Auto Desktop Head Unit (DHU):
   ```bash
   adb forward tcp:5277 tcp:5277
   ./desktop-head-unit
   ```
4. Telltale will automatically appear on the DHU head unit home screen. Click the app icon to launch.
5. You can now freely inspect:
   - **Vehicle Monitor Home Screen:** Live speed, RPM, coolant, module voltage.
   - **Vehicle Health Screen:** Observed status ("無觀測到警示" / "No observed warnings"), MIL status, DTC count.
   - **Powertrain Screen:** Detailed live powertrain signals.

### Method B: Testing on Standalone Android Automotive OS (AAOS) Emulator
1. Launch an Android Automotive OS system image (e.g., `Android Automotive 14/15 1080p Landscape` in Android Studio AVD Manager).
2. Install the automotive package:
   ```bash
   adb install -r automotive-debug.apk
   ```
3. Grant the automotive vehicle speed permission to the active user (User 10):
   ```bash
   adb shell pm grant --user 10 com.cbstudio.telltale.carproto.aaos android.car.permission.CAR_SPEED
   ```
4. Launch Telltale from the AAOS App Drawer. The app will launch directly into the car interface with active system status bars.

---

## 3. Testing Motion Gating (Moving vs. Parked Behavior)

Reviewers can verify driver distraction compliance by simulating vehicle movement:

### In Desktop Head Unit (DHU):
1. In the DHU terminal console, simulate vehicle movement (note: DHU `speed` command takes meters per second, e.g. `15` m/s ≈ 54 km/h):
   ```text
   speed 15
   ```
2. On the DHU screen, navigate to **Fault Codes** (`Diagnostic Codes`).
3. Attempt to click on any diagnostic trouble code (e.g. `P0300 · Stored`).
   - **Expected Result (Compliant):** The click is intercepted by the Car App Library host framework (`ParkedOnlyOnClickListener`) and suppressed by `CarDtcMotionGate`. The host prevents opening the detail screen while in motion.
4. Set speed back to stationary:
   ```text
   speed 0
   ```
5. Click on the diagnostic code again.
   - **Expected Result (Compliant):** The code details and freeze-frame sensor values immediately open for inspection.

### In Android Automotive OS (AAOS Emulator):
Inject vehicle speed directly into the Vehicle Hardware Abstraction Layer (VHAL) using the standard `PERF_VEHICLE_SPEED` property ID (`0x11600207`):
```bash
# Inject ~50 km/h (13.89 m/s)
adb shell cmd car_service inject-vhal-event 0x11600207 13.89

# Return to 0 km/h (Stationary)
adb shell cmd car_service inject-vhal-event 0x11600207 0.0
```

---

## 4. Demonstration Video & Privacy Disclosure

A complete walkthrough video is archived in the repository at:
`store/preview-gt86-vin-redacted.mp4`

### Video Walkthrough Timeline:
- **00:00 - 00:15:** Connection to vehicle telemetry bus via Bluetooth OBD adapter.
- **00:15 - 00:45:** Real-time projected dashboard on head unit (glanceable RPM, speed, coolant, voltage).
- **00:45 - 01:10:** Dynamic day/night theme transition responding to vehicle headlight sensor.
- **01:10 - 01:40:** Stationary diagnostic scanning: displaying Mode 03 / Mode 07 / Mode 0A diagnostic trouble codes.
- **01:40 - 02:00:** Freeze frame inspection and driver distraction speed lockout demonstration.

### Privacy & Vehicle Safety Disclosure:
- The video was recorded using an authentic Toyota GT86 vehicle.
- The vehicle's Vehicle Identification Number (VIN) has been completely redacted/blurred in the video frames to protect owner privacy.
- No personal identifying information (PII) or location coordinates are collected or transmitted by the application.

---

## 5. Non-Binary Review Appeal & Escalation Fallback Playbook

If a Google Play reviewer issues an automated or preliminary rejection, use the following pre-formulated escalation responses:

### Scenario 1: Rejection citing "Category Mismatch (IoT category cannot be used for car telemetry)"
- **Technical Position:** Telltale acts as a display and monitor for an external connected OBD-II peripheral adapter (an off-board IoT sensor). In the Android for Cars App Library, non-navigation, non-media external hardware sensor monitors declare `androidx.car.app.category.IOT` as the standard category for peripheral status display.
- **Response Text for Play Console Appeal:**
  > "Dear Google Play Review Team,  
  > Our application 'Telltale' operates as a display and monitor for an external connected OBD-II peripheral adapter (an off-board IoT sensor hardware). In the Android for Cars App Library (androidx.car.app), non-navigation, non-media external hardware sensor monitors declare `androidx.car.app.category.IOT` as the architectural fit for reading and displaying status from connected peripheral hardware. The application is 100% read-only (Mode 04 DTC clearing is physically excluded from the car module codebase), strictly adheres to Google's standard templated UI (PaneTemplate and ListTemplate), and implements complete stationary driver distraction gating. We kindly request that our category declaration be evaluated under this connected peripheral sensor architecture."

### Scenario 2: Rejection citing "Hardware Required / Cannot Test App"
- **Response Text for Play Console Appeal:**
  > "Dear Google Play Review Team,  
  > The application includes a full-fidelity built-in simulator engine specifically created for automated testing and store review without physical OBD-II hardware. To activate, launch the application on the phone and tap 'Start Demo Simulator' on the initial connection screen. When connected to the Desktop Head Unit (DHU) via `adb forward tcp:5277 tcp:5277`, the application immediately displays live simulated telemetry and diagnostic fault codes without requiring any physical vehicle or adapter. Step-by-step instructions and command lines are provided in our reviewer notes."

### Scenario 3: Rejection citing "Driver Distraction (Displays Fault Codes)"
- **Response Text for Play Console Appeal:**
  > "Dear Google Play Review Team,  
  > All diagnostic fault code inspection, freeze frame analysis, and deep list navigation are strictly gated behind a stationary vehicle speed lock (`speed == 0 km/h` or Parked). As verified by our motion gate tests, any attempt to browse fault codes while the vehicle is in motion is intercepted by `ParkedOnlyOnClickListener` and suppressed by `CarDtcMotionGate`. When moving, only 4 glanceable gauge figures are rendered within a standard PaneTemplate, adhering strictly to the <2-second glanceability rule."
