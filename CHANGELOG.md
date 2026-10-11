# Changelog

Versions read `x.y.z+N`. The left half is what a person sees; `N` is the
Android `versionCode`, which Google Play requires to increase strictly and
which therefore does not always move in step with the name.

Dates are the date the build was made, not the date it reached anyone.

## Unreleased

## 1.0.18 — 2026-10-12

Android Auto / AAOS preview readability and lifecycle work merged after `v1.0.17`:

- Added consistent car metric icons and clearer Home, Health, and Powertrain
  preview telemetry surfaces, with high coolant temperature emphasis and safer
  glanceable layouts.
- Added projection session ownership and foreground continuity handling across
  connect, pause, resume, and disconnect transitions.
- Kept the user-connected OBD transport alive across Android Auto disconnects,
  pausing car sampling until a new projection validates the same connection.
  Only a foreground phone may start its connected-device service.
- Added parked-only guidance when fault inspection lacks speed evidence and
  when vehicle-speed permission must be completed on the phone.
- Fixed the issue #106 post-connect path to publish the handshake voltage,
  restore PID capability census state, and retire or retry in-flight polling
  work correctly across lifecycle interruption.
- Added Android Auto / AAOS contract, lifecycle, graphics, and issue #106
  regression coverage.
- Fixed Android 13 locale API guards so Android lint can verify older-device
  compatibility without suppressing unsupported API access.

Validation for source `93c4708861ac9f4c1c1c9d4ae983dbfa44bafc85`
(tree `102f4b146fe94cb332b48255f199fad1abc63839`) passed 4,364 Flutter tests
with 23 opt-in skips, `flutter analyze` with no issues, 62 native carProto
tests, and Android lint with zero errors and 12 warnings. All six field/carProto
ABI APKs passed maintainer-signature, ZIP integrity and 16 KiB alignment checks.
The exact arm64 APKs accepted below were `field` SHA-256
`1d0f23f816cd9c176fc54a5c4c6d3d4779cd0d099f36a42681a628e9134eb4da`
and `carProto` SHA-256
`f31b7d949b1a3883e69a37c1207b0e4646fab4140338814fc704ce5a77526466`.

On an isolated Android 16 emulator, signed `1.0.17` → exact signed `1.0.18`
retained system-language selection, Light theme, Minimal gauge style, six enabled
PIDs, and a 254 KB prior transcript. Dashboard, trend chart, PID manager, custom
PID create/edit, fault codes with freeze frame, timing, settings, Light and Dark
themes, and controlled software ELM/TCP disconnect/reconnect passed. Custom PID
retention across the update was not exercised. In the Android Auto walk, explicit
phone HOME followed by 20 seconds without DHU produced zero fixture commands
while the same TCP connection, foreground service, and app process remained
alive. DHU reconnect reused that socket and resumed with `ATRV` before PID reads.
Fault Codes stayed put with moving and unknown speed and opened for the
stationary control; no toast text is claimed because none was persistently
captured. See `docs/verification/device-verification.md` for the evidence boundary.

The exact signed field ARM64 build also passed a physical Samsung Note9
(Android 10 / API 29) walk. A same-certificate 1.0.17 → 1.0.18 update retained
the installation time, theme, gauge style, language selection, six enabled PIDs,
and a 624 KB Demo transcript. Both themes, rendered trend curves and axes,
custom-PID create/edit/delete, fault freeze frames, timing, settings, and
controlled software TCP connect/disconnect/saved-adapter reconnect passed.
Cross-version custom-PID retention was not exercised. Installed-APK readback
matched the accepted SHA-256 above, and the app-scoped stability scan found no
crash, Flutter error, overflow, out-of-memory error, or ANR.

Release CI, issue #106 reporter hardware, Play update compatibility, and store
rollout remain separate checks. These software-fixture receipts do not prove
Bluetooth, a real vehicle, or Google approval. Android Auto / AAOS remains an
engineering preview; the production `field` APK has no car app service.

## 1.0.17 — 2026-10-07

Google Play production target `1.0.17` / versionCode 18. GitLab annotated
tag `v1.0.17`. Play production release prepared with versionCode 18.
GitLab Release `v1.0.17` published with 4 assets attached: `telltale-v1.0.17-arm64-v8a.apk`,
`telltale-v1.0.17-armeabi-v7a.apk`, `telltale-v1.0.17-x86_64.apk`, and `SHA256SUMS`.

CI full-gate [pipeline #2918920306](https://gitlab.com/aa22396584/telltale/-/pipelines/2918920306)
on `a97594a5` and local full test suite validation: 4,316 tests passed (`+4316 ~23: All tests passed!` for `flutter test`),
7 Linux HUD Golden visual tests 100% passed, and `flutter analyze` clean with 0 issues.
Physical device smoke test completed and attested on Samsung Galaxy S24 Ultra (`R5CX10VFFBA`,
Android 16, API 36; see `docs/verification/device-verification.md` for `Device walk attested: 1.0.17`),
confirming subpixel geometry alignment error < 0.7px, zero white border / Chrome bleeding,
and zero RenderFlex overflow across full lifecycle (Enter, Pause, Resume, Exit).
Emulator walk on Pixel 9 Pro Fold (Android 16, `emulator-5554`) validated folded (0°),
unfolded (180°), tabletop (90°), and dynamic folding/unfolding posture continuity without restart.
Vehicle and hardware testing boundary: physical device walks and simulated ELM327/BLE GATT test rigs
are verified; live vehicle road testing remains bounded per `docs/verification/` (not attested across all vehicle generations).

### Added

- Head-Up Display (HUD) Mode / 抬頭顯示模式 (HUD-01):
  - **繁體中文**：
    - 全黑 OLED 極致對比：採用純黑底色（`#000000`），完全隱藏 Android 系統狀態列與導航列（`IMMERSIVE_STICKY` 粘性沉浸模式），消除擋風玻璃反光與邊框雜光。
    - 光學鏡像幾何反轉：內建光學鏡像翻轉（`scaleX(-1)`），專為手機平放儀表台擋風玻璃投影反射設計，確保駕駛視線直覺清晰。
    - 視圖層防誤觸觸摸隔離：全螢幕觸摸事件隔離保護，杜絕行車顛簸造成的非預期誤觸。
    - 700ms 防分心長按退出機制：設置直覺式 700ms 長按退出防護，避免誤碰跳出，兼顧駕駛專注與操作安全性。
    - 三套高對比光學配色：提供競速綠（Green）、琥珀橙（Amber）、冰藍（Ice Blue）三款高對比主題配色，適應白天強光與夜間低照度環境。
    - 等寬字型與防溢出保護：數值採等寬字型排版避免位數跳動閃爍，並整合動態縮放防溢出保護，適配各類螢幕長寬比。
  - **English**:
    - Pure Black OLED Canvas: High-contrast true black background (`#000000`) with system bars hidden (`IMMERSIVE_STICKY`), eliminating windshield glare and frame bleeding.
    - Optical Mirror Projection: Geometric horizontal reflection (`scaleX(-1)`) engineered specifically for dashboard windshield projection.
    - Touch Isolation: Viewport-level touch event isolation prevents accidental taps caused by road vibration.
    - 700ms Long-Press Exit Protection: Distraction-free safety exit requiring a deliberate 700ms long press, guarding driver focus while maintaining graceful navigation.
    - Triple High-Contrast Palettes: Green, Amber, and Ice Blue color schemes optimized for both bright daylight and night driving conditions.
    - Tabular Digits & Overflow Guard: Monospaced tabular figures eliminate digit jitter, coupled with responsive scale bounds to prevent UI overflows.
- Android Auto & AAOS Automotive Surfaces / 車載系統深度整合 (AA-01 ~ AA-07, AAOS-01):
  - **繁體中文**：
    - Google 車規防分心規範 (DDG)：嚴格遵循 Google Driver Distraction Guidelines，行駛中強制限制清單為 6-item 分頁瀏覽，保障駕駛安全。
    - 行駛唯讀即時遙測：車載螢幕呈現高易讀性即時遙測數據橋接（車速、轉速、水溫），行駛中維持嚴格唯讀，禁止危險干預。
    - 靜止限定 DTC 故障碼檢視：故障碼掃描與詳細檢視僅限 P 檔或車速為 0 km/h 靜止狀態；一旦車輛移動（> 0 km/h）立即自動退回主畫面，防止行駛分心。
    - 高溫冷卻液遲滯防抖告警引擎：引入專用冷卻液溫度遲滯防抖演算法（105°C 觸發告警 / 降至 100°C 延時解除），徹底消除臨界溫度震盪引發的頻繁跳報。
    - 車載三語系完整對齊：車機端完整對齊英文（en-US）、繁體中文（zh-TW）、簡體中文（zh-CN），並支援雙向文字（BiDi）鏡像排版佈局。
  - **English**:
    - Google Driver Distraction Guidelines (DDG): Strict automotive compliance restricting list items to 6-item pagination when driving.
    - Drive-Safe Read-Only Telemetry: Real-time powertrain telemetry bridge (Speed, RPM, Coolant) formatted for glanceable in-car projection.
    - Stationary-Only DTC Inspection: Diagnostic Trouble Code review is strictly locked to Park (P) or stationary (0 km/h) conditions, with automatic dismissal back to home if vehicle movement is detected.
    - Coolant Temperature Hysteresis Engine: Advanced debouncing hysteresis threshold (triggers at 105°C, clears only below 100°C with 10s hold) preventing fluttering alert spam near threshold boundaries.
    - Tri-Locale Alignment: Complete parity across `en-US`, `zh-TW`, and `zh-CN` with full BiDi mirroring compliance.
- Foldable & Multi-Surface Adaptivity / 摺疊機與多螢幕形態自適應 (FOLD-01 ~ FOLD-08):
  - **繁體中文**：
    - 全形態動態姿態自適應：無縫適配常規手機直橫屏、折疊機封面外螢幕（Cover Screen）、展開大螢幕（Unfolded Inner Display）與 90° Tabletop 半折疊懸停姿態。
    - 雙窗格 (Master-Detail) 與鉸鏈物理迴避：寬螢幕自動切換為雙窗格導航與側邊欄；偵測實體鉸鏈（Hinge）與折痕區域進行物理安全避讓，絕不跨鉸鏈割裂任何儀表或按鈕。
    - 連續性狀態保持：旋轉、展開或折疊時，完整保持已選 PID、故障碼掃描結果、儀表排列與零百加速測試進度，無須重新連線。
    - 40 項折疊品質門禁 100% 通過：通過包含鉸鏈分割、子像素對齊、邊界溢出在內的 40 項折疊品質門禁測試。
  - **English**:
    - Continuous Adaptive Form Factors: Seamless continuity across phone portrait/landscape, foldable cover screens, unfolded inner tablets, and 90° Tabletop postures without restarting sessions.
    - Master-Detail Layout & Physical Hinge Avoidance: Two-pane navigation on wide screens with hardware hinge and crease avoidance, guaranteeing no gauges or action buttons span across display seams.
    - Runtime State Preservation: Folding, unfolding, or rotating preserves active telemetry, DTC inspection results, dashboard gauges, and active acceleration timers without adapter renegotiation.
    - 40 Foldable Quality Gates: 100% pass rate across 40 automated foldable and multi-window quality verification gates.

### Refined & Fixed

- Dashboard & Polling Refinements / 儀表板與採樣加固 (#106):
  - **繁體中文**：
    - 狀態膠囊垂直幾何置中：Dashboard 頂部狀態膠囊（批次讀取、電壓、連線狀態）修正為幾何垂直中心對齊（`WrapCrossAlignment.center`），消除字元下沉錯位。
    - ATSP0 / 0100 搜尋預算防護：針對慢速 ELM327 轉接器延長自動協議搜尋超時寬限至 25 秒，初次接收 `NO DATA` 提供單次即時重試，大幅提升藍牙連接握手成功率。
  - **English**:
    - Vertical Center Alignment for Status Capsules: Polling mode, voltage, and connection pills on the Dashboard status strip are vertically centered (`WrapCrossAlignment.center`), eliminating baseline misalignment.
    - ATSP0 / 0100 Protocol Search Budget: Extended automatic protocol negotiation budget to 25s for slow ELM327 adapters, with immediate retry for initial `NO DATA` responses, preventing premature handshake terminations.

### Verification & Downloads

| File | Architecture | Size | SHA-256 Digest |
| :--- | :--- | :--- | :--- |
| `telltale-v1.0.17-arm64-v8a.apk` | arm64-v8a (modern 64-bit) | 24M | `e903a6e51b3b44a7854b2aec5d116cb96e7e8c9f193f09dc2395a6b7ce05998c` |
| `telltale-v1.0.17-armeabi-v7a.apk` | armeabi-v7a (legacy 32-bit) | 22M | `99c4e47f443c5d40da424571c2c61eba93da260028622d5ab0a09e465c080e3f` |
| `telltale-v1.0.17-x86_64.apk` | x86_64 (emulators) | 25M | `b43855e283a18608bf6fa1746e4ceb7e078f4899bf00223775ea5f661ccdcd59` |

Checksum verification command: `sha256sum -c SHA256SUMS`


## 1.0.16 — 2026-10-03

Google Play production target `1.0.16` / versionCode 17. GitLab annotated
tag `v1.0.16` on `85af0e94` (`Merge branch 'release/1.0.16' into 'main'`,
2026-10-03 15:43 +08). Play production release promoted with versionCode 17
(status: `completed`, 100% rollout, edit committed; undergoing Google Play review propagation).
GitLab Release `v1.0.16` published with 4 assets attached: `telltale-v1.0.16-arm64-v8a.apk`,
`telltale-v1.0.16-armeabi-v7a.apk`, `telltale-v1.0.16-x86_64.apk`, and `SHA256SUMS`.

CI full-gate
[pipeline #2908857286](https://gitlab.com/aa22396584/telltale/-/pipelines/2908857286)
on MR !99 printed `+4180 ~23: All tests passed!` for `flutter test`.
Physical device smoke test completed and attested on Samsung Galaxy S24 Ultra (`R5CX10VFFBA`,
Android 16; see `docs/verification/device-verification.md` for `Device walk attested: 1.0.16`).
Emulator walk on Pixel 9 Pro Fold (Android 16, `emulator-5554`) validated folded (0°),
unfolded (180°), tabletop (90°), and dynamic folding/unfolding posture continuity without restart.

### Added

- Foldable and large-screen layouts. Window width decides the layout:
  below 600 dp is the existing phone layout with a bottom navigation
  bar; 600–839 dp switches to a navigation rail; 840 dp and up allows
  two panes. A separating hinge reported by the system is treated as
  unusable space: no gauge, list row, or button is placed across it.
  This is width- and hinge-driven, not a per-model list. (FOLD-01)
- Dashboard caps the gauge grid at 6 columns, so a wide window gives
  readable tiles rather than many tiny ones. Across a vertical hinge the
  gauges are split into two contiguous halves in the same order; in a
  right-to-left language the first half sits on the right. (FOLD-02)
- PID manager, fault codes, and the acceleration timer show a list and
  a detail side by side on wide windows and across a vertical hinge.
  Selecting a row shows its detail; the dashboard switch on a PID row
  still only toggles the gauge. A fault code is identified by its code,
  kind, and reporting controller, so the same code from two controllers
  stays two rows. The fault-code list never auto-selects the first entry.
  The PID editor is still a full screen, not an inline pane. (FOLD-03,
  FOLD-05, FOLD-06)
- Pickers that used to be bottom sheets open as a side sheet or a dialog
  on wide windows, and avoid a hinge. Destructive confirmations (clearing
  fault codes) are still ordinary dialogs. (FOLD-04, FOLD-07)
- The connection screen keeps a single column at most 600 dp wide,
  centred, instead of stretching across a tablet or an unfolded screen.
  (FOLD-07)

### Fixed

- Folding, unfolding, or rotating keeps the selected PID, the selected
  fault code, the dashboard mode and scroll position, and a running
  acceleration run. A layout change does not reconnect to the adapter.
- The first `0100` after `ATSP0` gets up to 25 seconds instead of the
  4-second budget used for local AT commands. Automatic protocol search
  on a slow adapter can take that long, and the old budget ended the
  handshake right after the battery voltage appeared. A first `NO DATA`
  gets exactly one immediate retry inside the same 25-second deadline;
  `UNABLE TO CONNECT`, `CAN ERROR`, and a timeout are not retried. (#106)
- Found on the release device walk, before tagging: the new adaptive
  pickers were laid out against the whole window but placed inside the
  tab area, so on a phone the bottom of a sheet slid under the navigation
  bar (the last row could not be tapped) and on a wide window a dialog
  was shifted sideways by the navigation rail's width. They now open
  over the whole window like any other modal.
  (`test/ui/adaptive/adaptive_modal_nested_navigator_test.dart`)

### Known, and not fixed here

- On a phone-width PID manager the header's overflow menu wraps onto its
  own line and the supported-PID card does not span the full width. Same
  layout as 1.0.15; cosmetic.
- The foldable layouts are covered by widget tests that inject display
  features (`test/ui/foldable_quality_gate_test.dart`) and were run on an
  Android emulator configured as a Pixel 9 Pro Fold. They have not been
  run on a physical foldable phone.
- A horizontal (tabletop) hinge keeps a single pane on the screens that
  split; there is no dedicated top/bottom posture mode.

## 1.0.15 — 2026-10-02

Google Play production target `1.0.15` / versionCode 16. GitLab annotated
tag `v1.0.15` on `8409ae26` (`fix(android): remove splits.abi config conflicting with Flutter ndk.abiFilters`,
2026-10-02 00:31 +08). Play production release promoted with versionCode 16
(status: `completed`, 100% rollout, edit committed; undergoing Google Play review propagation).
GitLab Release `v1.0.15` published with 4 assets attached: `telltale-v1.0.15-arm64-v8a.apk`,
`telltale-v1.0.15-armeabi-v7a.apk`, `telltale-v1.0.15-x86_64.apk`, and `SHA256SUMS`.

CI full-gate
[pipeline #2900188749](https://gitlab.com/aa22396584/telltale/-/pipelines/2900188749)
on `4b35a1a` printed `+3909 ~23: All tests passed!` for `flutter test`.
Physical device smoke test completed and attested on Samsung Galaxy S24 Ultra (`R5CX10VFFBA`,
Android 16; see `docs/verification/device-verification.md` for `Device walk attested: 1.0.15`).

### Added

- Settings opens a Service Recipes & Active Tests screen. On a live CAN
  connection it can ask which Mode 08 test IDs the ECU reports as
  supported, using only the standard base TID queries (`$00`, `$20`, …).
  It does not send a runnable TID to find out whether the function
  exists. Silence or `NO DATA` is unknown, not unsupported. Discovery
  takes exclusive ownership of the diagnostic link, so live telemetry
  polling is held for that window. The three bundled recipes are
  synthetic fixtures (Mode 08 EVAP, UDS IO control, UDS routine). The
  banner says zero live candidates: nothing in this catalog is qualified
  to actuate a physical vehicle. (#9, #104 leftover)
- Settings can pick a Canada-market identity from the Natural Resources
  Canada Fuel Consumption Ratings snapshot, beside the U.S. EPA and
  Taiwan MOEA lists. The three markets are not namesakes of each other.
  ICE, battery-electric, and plug-in hybrid stay separate classes.
  Displacement in litres is the same quantity and is applied when it is
  in range; motor kilowatts is not wheel horsepower and is not applied;
  consumption, range, and CO2 are never copied. Fuel is copied only from
  an exact single NRCan letter on a non-hybrid ICE row (`X` regular, `Z`
  premium, `D` diesel, `E` E85). Dual codes, electricity, natural gas,
  BEV/PHEV rows, and conventional hybrids sitting in the ICE file stay
  unresolved. 1995–2014 5-cycle approximations are not in the bundle.
  The year is the NRCan model year, not a U.S. EPA configuration and not
  a Taiwan certification year. (#348, #352)
- A bounded read-only UDS (ISO 14229) path on the existing ELM session:
  Service `0x22` ReadDataByIdentifier and Service `0x19`
  ReadDTCInformation (subfunctions `0x02` and `0x0A`). NRC `0x78` waits
  without retransmitting the trigger. This is not a new connection type,
  not DoIP, and not a workshop actuation screen. The synthetic UDS `0x2F`
  / `0x31` recipes in the catalog remain blocked on a live vehicle. (#13)
- Typed ELM327 CAN addressing and host-visible ISO-TP on that same
  session: `ATCEA` / `ATCP` / `ATCRA` apply and restore, and `ATCAF0`
  with a bounded assembler. Vehicle profiles cannot inject AT text. An
  adapter that answers `?` is unavailable, not a success. (#334, #367)

### Fixed

- Acceleration timing uses the monotonic observation clock on the speed
  reading, not `DateTime.now()`. A wall-clock step must not change a run
  whose observation ticks did not change. The start is still a threshold
  after standstill, not a physically measured 0–100. (#349)
- Experimental battery reads that pass their checks are still labelled
  unverified on Wear and in the probe-result dialog. A passing check is
  not a vehicle qualification. (#345, #333 leftover, #87 leftover)
- Formula-engine exception messages that still spoke Traditional Chinese
  in an English build are English. (#38 leftover, #72 leftover)
- Switching language while an error, SnackBar, or history-export notice
  is on screen redraws that sentence. It does not re-send the command or
  re-export the file. The CSV/JSON payload stays byte-identical across
  locales; the share subject is allowed to translate. Switching language
  during a recording or an in-flight artifact is still refused.
  (#34, #36, #39, #40, #72)
- Fault-code banners that used to collapse MIL disagreement, unresolved
  identities, and J1939 bus refusal into a generic kind now name those
  through structured fields. (#369, #370, #372)
- An unattested session export stays unverified. Attestation is not
  inferred from a successful write. (#379)
- Debug Android builds no longer enable ABI splits. Splits plus Flutter's
  `ndk.abiFilters` were a Gradle “Conflicting configuration” on
  `flutter run`; per-ABI APKs remain a Release-task concern.

### Changed

- Development home, issues, and CI are GitLab
  (`aa22396584/telltale`). In-tree GitHub badges and clone URLs were
  dropped or retargeted. Community APKs continue to be advertised from
  GitLab Releases and Codeberg; this tag has not published those assets
  yet.
- Release Android packaging can emit per-ABI APKs (`armeabi-v7a`,
  `arm64-v8a`, `x86_64`) with `versionCodeOverride`. That is packaging
  for an F-Droid recipe, not an F-Droid listing.

### Known, and not fixed here

- Demo ECU still identifies as `Demo ECU (2.0L Turbo I4)`. That string
  was already in `1.0.14`; this build did not add the simulator.
- CAN Mode 06 records can be decoded fail-closed in code. There is no
  Mode 06 screen. (#359)
- Typed CAN / ISO-TP contracts and a native ISO-TP CTest matrix exist
  under the diagnostic bridge. SocketCAN is not a connection method in
  the app. (#14)

## 1.0.14 — 2026-09-11

Google Play production target `1.0.14` / versionCode 15. GitHub community
release `v1.0.14`. Play production is `1.0.13` / versionCode 14 as of this
writing.

### Added

- Settings can pick a Taiwan passenger-car identity from the Ministry of
  Economic Affairs Energy Administration snapshot, beside the existing U.S.
  EPA list. The two markets are not namesakes of each other: a Taiwan row
  that is missing is missing, not an EPA car with a similar name. The
  bundled table is the monthly certification CSV (open-data dataset 6032).
  The annual 車輛油耗指南 PDF (dataset 11163) is pinned as the guide, not
  used as the configuration table. Displacement in cubic centimetres is
  converted to litres because that unit is the same quantity; 參考車重 is
  left as reference mass, not renamed as curb mass. The year on a row is
  the certification calendar year (ROC year + 1911), not a U.S. model year.
  (#331 Stage A, #337)
- Torque-wiki `LOOKUP()` and `CLOSEST()` now evaluate. `LOOKUP` is exact
  and range matching; a key that is not in the table is not the nearest
  neighbour. `CLOSEST` is the nearest key. (#318–#323, #79 leftover)
- A connection failure now names one next step instead of a transcript.
  Missing a permission opens settings. A radio that is off asks to be
  turned on. An adapter that never answers may be out of range or unpowered.
  An adapter that is up while the ECU is silent points at ignition,
  protocol, or the adapter. `BUS INIT` offers retry or Auto. A BLE scan
  that failed is that scan, not a later protocol problem. `0100` returning
  `NO DATA` is ECU silence — not proof the vehicle has no OBD. Other
  `NO DATA` replies stay unmapped. (#51 leftover, #330, #336)

### Fixed

- KWP: the 5-baud and fast subtypes are distinguished from `ATDPN` 4 and 5.
  A FAST line from `ATDP` alone does not settle the subtype. (#325)
- `BARO()` with parentheses is a different quantity (phone barometer / ECU
  baro in psi) and is refused rather than evaluated as the ECU's kPa cache.
  (#326, #79 leftover)
- `INT16` stays unclaimed. The wiki's `(A*255)+B` is not what a signed
  16-bit word is, and inventing `(A*256)+B` here would still be a guess.
  (#327, #79 leftover)
- Delay and average wiki names (`TDLY`, `RDLY`, `TAVG`, `RAVG`, `AVG`,
  `EWMAF`) are refused instead of being computed as `MIN`/`MAX`/0.
  `TOT` is named as a totalizer, not as another delay or average. (#328, #329)
- The four-row connection diagnostic can be copied as four lines. (#324)

## 1.0.13 — 2026-09-11

Google Play production target `1.0.13` / versionCode 14. GitHub community
release `v1.0.13`. Play production is still `1.0.11` / versionCode 12 as of
this writing — `1.0.12` shipped only as the community APK — so a Play
install jumping here also receives everything listed under `1.0.12`.

### Added

- A German interface. The picker on the Connect screen and in Settings now lists
  Deutsch beside English and 繁體中文, and a phone set to German — including
  `de-AT` and `de-CH` — starts in German without being asked. A stored language
  this build does not know still falls back to following the system, so moving
  between versions cannot strand somebody in a language they cannot read.

  It is a machine translation, and this is the part worth stating plainly. Every
  ICU argument and every token on `docs/i18n/do-not-translate.md` — `NO DATA`,
  `ATZ`, `VIN`, `Wi-Fi`, every mode and PID number — was held out of the
  translation request and verified in the result, so a command is still a
  command and an adapter reply is still matched literally. Then all 1112 strings
  were read and about a hundred corrected: `Port` had become *Hafen*, `Mass`
  *Messe*, `Displacement` *Verdrängung*, `Stopped by you` *Ich habe bei Ihnen
  vorbeigeschaut*; `read-only` had become *schreibgeschützt*, which says
  something else entirely about a query this app promises never to write with;
  `clear` drifted between *löschen*, *Freigabe* and *Bereinigung* across the six
  screens that talk about clearing fault codes; and `The ECU did not answer` had
  turned into *Der Befehl „ECU“ wurde nicht beantwortet*, which is a different
  claim about a different thing. Every plural branch was rewritten, because the
  translator glues the argument to the noun and opens new sentences inside a
  branch.

  What that pass cannot establish is the one thing this project cares most about
  in prose: whether a hedge still lands with the force the English gives it.
  Until a native speaker has read these screens in a car, a German sentence that
  reads wrongly is a defect worth reporting rather than a matter of taste, and
  `docs/i18n/README.md` says so where a translator will look.
- The connect handshake now shows four separate facts: the transport, the
  protocol that answered, which ECUs replied, and what that is based on.
  Demo is named as software, never as a field adapter. An empty protocol is
  unknown. No ECU answers is not observed. Link loss does not wipe a fact
  that was already seen. (#51 leftover, #306, #307)
- The dashboard reports how many Mode 01 sensors the adapter actually packed
  in one reply, not only whether fast mode is allowed. That count survives
  resume, and a reply that times out after the write still counts as a
  packed batch rather than as a silent miss. (#94 leftover, #297, #298,
  #300, #301)

### Fixed

- The community APK died at launch on a Samsung Note 3 (`hlte`, Adreno 330)
  running DivestOS 18.1. The phone reports Android 11, which is past the
  engine's API 29 Impeller gate, so Flutter chose Impeller, found no Vulkan
  driver, fell to its own OpenGL ES backend and crashed in the GPU driver's
  shader linker before the first frame. Telltale now reads
  `ro.board.platform` and `ro.hardware.vulkan` before the engine starts and,
  on the one SoC with a tombstone (`msm8974`), starts the engine with Impeller
  disabled so it renders with Skia. Every other phone keeps whatever the
  engine chooses for it — Impeller from Android 10 up, apart from the
  engine's own exception for Vivante GPUs, Skia below that. One thing does
  change on them: in release builds a launch Intent can no longer switch the
  renderer, because the app now owns the engine's start-up arguments. The
  decision and its reason are written into
  evidence file headers as `# 渲染：…`, beside what the engine itself reports.
  Not yet run on the reporter's phone: the emulator and a Galaxy S24 Ultra
  show the two sides of the switch; the Note 3 row is the reporter's. (#121,
  #104)
- Year-range confirm refusals used diagnostic copy. They now use the
  authorization wording. (#45 leftover, #299)

## 1.0.12 — 2026-09-07

Google Play production target `1.0.12` / versionCode 13. GitHub community
release `v1.0.12` — the first one without a pre-release suffix since
`v1.0.6`, and the reason is below.

### Fixed

- When a command failed on the adapter, the manual command box in Settings
  printed the engine's Traditional Chinese whatever language the app was in.
  So did the estimate details dialog — an English screen rendering
  `質量 1500 kg（通用預設值）` — and a scan refused on an older bus.
- Refusing a permission could name the wrong one: the screen said Bluetooth
  when the switch the user had declined was Location.
- The affiliate line on the connect screen read 蝦皮 in an English build.

### Known, and not fixed here

- The manual command box's *own* refusals are still Traditional Chinese in an
  English build — the sentence it prints when it declines to send a command at
  all, as opposed to relaying what the adapter said. Found on the phone during
  the walk for this release, after the changelog had already been written from
  the diff and claimed otherwise.

### Changed

- A GitHub release is marked pre-release when
  `docs/verification/device-verification.md` carries no `Device walk attested:`
  line for its version, and a full release when it does. That is the whole of
  the flag, and CI refuses a full-release tag without the line.

  It used to carry a second claim as well — "never run against a real car" —
  which one person cannot clear, so every release from `v1.0.7` to `v1.0.11`
  was a pre-release and GitHub's Latest badge sat on `v1.0.6` for nine days
  while the same commit was on Play production at 100%. The adapter and
  vehicle boundary has not gone away; it now prints in the release notes of
  **every** build, full or pre-release, where it is something to state rather
  than something to block on.

## 1.0.11 — 2026-09-07

Google Play production target `1.0.11` / versionCode 12. GitHub community
pre-release `v1.0.11-beta.1` (separate signing lineage). iOS App Store remains
deferred until 2027.

This is the release where the English interface is real. See the correction
under `1.0.10` below.

### Added

- The interface reads in English. Connect, dashboard, gauges, fault codes,
  freeze frame, the PID manager and editor, the powertrain battery catalog,
  the telemetry screens, acceleration, settings and the Wear OS shell. The
  message catalogue went from 14 entries to 934, counted at the `v1.0.10-beta.1`
  tag and at this commit.
- An English Play Store listing. There has never been one; the app has been on
  Play in Traditional Chinese only.
- Store screenshots in both listing languages, under `store/en-US/` and
  `store/zh-TW/`.
- The store listing copy is now in the repository under `store/metadata/`,
  with `store/upload.sh` to publish it. It used to exist only inside a web
  form, where no one could diff it or say when a sentence changed.
- The project site is one page per language —
  `iml1s.github.io/telltale/` stays Traditional Chinese and
  `index.en.html` is English. The privacy policy stays one bilingual document
  with an anchor per language, because Google Play registers exactly one
  privacy-policy URL and a reader of either language has to be able to read it.

### Fixed

- The estimated-values panel named its air-mass and fuel sources in Chinese in
  the English build — 「MAF 感測器」 in the middle of an otherwise English
  dashboard, and in the screenshot on the store page. The gauge skin names had
  the same problem, and so did the source label on a recorded telemetry
  session.
- A status pill with a long label overflowed at 320dp with large text instead
  of wrapping. It wraps rather than truncates, because these pills give a
  reason — "estimated", "unverified", "stale" — and half a reason is worse
  than a taller pill.
- The powertrain battery catalog joined command lists with the fullwidth
  separator 「、」 in both languages, so an English reader saw
  `Battery temperature 1、Battery temperature 2`. This one had shipped.
- The estimate details dialog listed the vehicle assumptions it rests on in
  Chinese — `車重 1500 kg（通用預設）；Cd 0.30…` — in the English build. The
  sentence is composed for the telemetry export, where it stays Traditional
  Chinese so that two people can compare one evidence file; rendering the
  stored sentence on screen was the mistake. The exported text is unchanged,
  byte for byte.
- Settings offered its fuel types as 汽油 / 柴油 / 液化石油氣 (LPG) /
  E85 酒精汽油 regardless of the chosen language.

### Known

- Wi-Fi route-binding failures and the Bluetooth and location permission labels
  are still Chinese. They reach the connect screen when Android refuses to bind
  a route or the reader declines a permission. Tracked in #45.
- Some load-bearing sentences ship correct English with no guard that would fail
  if a translation reversed them, and some have a guard that checks the wrong
  property. Named individually in #47, along with the reason a count is the
  wrong shape for this: a reviewer defeated a structural guard on the replay
  notice by changing 「已」 to 「未」, which moved no position it was checking.
  A sentence with a guard that agrees with a reversal is worse than one with no
  guard, because the green tick is what the next translator will trust.
- Transcripts, evidence headers and telemetry CSV/JSON exports stay in
  Traditional Chinese on purpose. An evidence file whose language depends on a
  phone setting is one that two readers cannot compare. Tracked in #46.

## 1.0.10 — 2026-09-06

Google Play production target `1.0.10` / versionCode 11. GitHub community
pre-release `v1.0.10-beta.1` (separate signing lineage). iOS App Store remains
deferred until 2027.

### Added

- A language control on the connect screen (`Language / 語言`) and in Settings:
  English, Traditional Chinese, or follow the system — and the locale
  resolution behind it.

### Fixed

- Retryable startup failure uses its own title, not the “checking” copy.

### Correction

This entry originally read “English UI, with a language control…”. That was
wrong, and it is left here rather than rewritten because the build carrying the
claim is on Google Play production and people read it.

What `1.0.10` actually shipped was the switch and the machinery: **14**
translated messages, against an interface that needs 934. Choosing English moved
the startup copy, the language control itself and little else; every screen
stayed in Traditional Chinese. The English interface arrives in `1.0.11`.

The first draft of this correction said 53 and 907. Both were wrong — 53 was the
count on `main` at the moment I measured, months of groundwork after `1.0.10`
went out, and 907 predated the last change to the key set. A reviewer counted
`lib/l10n/app_en.arb` at the `v1.0.10-beta.1` tag itself and got 14. Putting an
unchecked number inside the paragraph that corrects an overclaim is the same
mistake twice, and it is recorded here for the same reason the overclaim is.

## 1.0.9 — 2026-09-06

Google Play production `1.0.9` / versionCode 10 (`PUBLISHED`). GitHub community
pre-release `v1.0.9-beta.1` (separate signing lineage). Next Play upload must
be `> 10`. iOS App Store remains deferred until 2027.

### Added

- Settings shows the maintainer-recommended adapter catalog (currently the
  existing Shopee affiliate listing) with commission disclosure and model/NCC
  check. Connect keeps a secondary text link below the transports so it does
  not compete with 直接連線 / 啟動模擬器 / 上次轉接器.

## 1.0.8 — 2026-09-06

Google Play production `1.0.8` / versionCode 9 (`PUBLISHED`). GitHub community
pre-release `v1.0.8-beta.1` (separate signing lineage). iOS App Store is deferred
until 2027. S24 Ultra 1.0.8 release APK reached bonded OBDBLE but the dongle was
unpowered (`無法連線到 OBDBLE`).

### Added

- Unverified labelled reads stay usable: generic OBD without VIN or catalog match, community/experimental/user PIDs, partial ECU success, and disclosed 馬力/油耗 estimates. Field verification adds 已驗證; it is not a use gate. Clear/actuate/program keep their own preconditions. Bad packets stay raw/error, never a number.

- Three more installable community battery profiles, each cross-corroborated
  by two mutually independent, license-pinned implementations: MG4 Electric
  (OVMS × OBDb on functional 7DF/7ED; not the Mk1 ZS EV 781/789 map), MG5 EV
  2020–2023 (OVMS × WiCAN on physical 7E5/7ED; identity from OVMS, not
  WiCAN's MG5/Marvel/ZS union; B046 excluded because the scales disagree),
  and BYD Atto 3 before the 2024.10 firmware (OVMS × WiCAN little-endian
  0005/0008/0009 on 7E7/7EF; the short `atto3.json` big-endian 0008 window
  is not used; 0032 temperature uses the sibling WiCAN file).
- A Toyota bZ4X / Subaru Solterra (e-TNGA, first gen) experimental profile
  for the one-shot laboratory: capture-verified 7D2/7DA `1F5B` and `106C`.
  Community is blocked by a 7D2 vs 747 header split on the same DID; `1F9A`
  is not shipped. Year ceiling 2024.
- Recorded honest exclusions on the affected research entries — MINI Cooper
  SE F56 (i3-grade extended addressing), Nissan Ariya (29-bit ISO-TP), Fiat
  500e Type 332 (no open DID map; SGW is not the read blocker) — plus a
  pointer from the bZ4X EPA stub to the experimental sibling.
- A wire-contract regression suite for the new profiles: synthetic
  source-agreed responses through catalog → installer → engine, including
  the Atto 3 little-endian voltage (so a big-endian misread cannot hide)
  and the pinned e-TNGA capture bytes through the one-shot probe path.

### Changed

- Wave-3 review closeout: MG4 pack current is ±400 A (was a copied Mk1
  ZS EV 200 A bound that would have discarded DC-charge readings as
  formula errors); pack voltage ceiling 500 V and DC-bus 1000 V follow
  OBDb. A second ECU answering functional 7DF now has a wire-contract
  fail-closed test. Atto 3 expected responder 7EF is recorded as the
  same ISO 15765 request+8 inference as Mk1 ZS EV 789. OVMS lock-while-
  charging alarm warning is on the MG4/MG5 entries.

- Four more installable community battery profiles, each cross-corroborated
  by two mutually independent, license-pinned implementations: Hyundai
  Ioniq 6 (the proven E-GMP 59/43-byte contract, verified byte-for-byte
  against a pinned real capture), Kia Soul EV (SK3, narrowed to its
  attested 2020 model year, adding dual-source minimum cell deterioration;
  its three battery temperatures are excluded because both model-explicit
  sources decode them unsigned, leaving signed sub-zero semantics without
  a second source), Renault Zoe Ph1 (CanZE × WiCAN; pack
  voltage deliberately excluded because it never cleared the two-source
  independence bar — one DID has a single independent source, the other
  only a WiCAN window with a recorded indexing bug), and
  VW e-up! gen2 (OVMS × WiCAN; pack current excluded — two sources, two
  formulas, no tiebreaker).
- A Kia EV9 experimental profile for the one-shot laboratory: the only
  evidence family is OBDb, whose signalset labels pack current unsigned
  while its own capture then reads an absurd 6540 A; the entry ships the
  physically coherent signed decode and records the upstream flaw.
- Recorded honest transport-level exclusions on the affected research
  entries — BMW i3 (extended addressing), VW ID.3/ID.4 (29-bit gateway),
  Renault Zoe Ph2 (29-bit-only DIDs) — plus the e-Golf's
  three-sources-three-formulas SoC and the year-unattested Genesis pair,
  so the next reviewer starts from evidence instead of a blank map.
- A wire-contract regression suite for the new profiles: synthetic
  source-agreed responses driven through catalog → installer → engine,
  including a charging (negative) Zoe current, an out-of-physics e-up!
  voltage that must be refused, and the Ioniq 5 capture replayed
  identically through the separate Ioniq 6 entry.

- A standalone Wear OS shell: the watch runs the same engine and
  transports and gets glance-first pages — one large cycling dial
  (speed/RPM/coolant, long-press to disconnect) and a four-number glance
  grid. Demo connects in one tap; BLE adapters in two. Bluetooth Classic
  and Wi-Fi are deliberately absent (a watch cannot open RFCOMM), all
  write paths stay phone-only, and the screen holds awake while
  connected. A battery page behind the same per-connection vehicle
  confirmation as the phone is code-complete and widget-tested, but
  profile installation is phone-only and the watch app is standalone, so
  no provisioning path reaches it on a real watch yet — it is a
  follow-up, not a shipped claim. Ships as a `wear` flavor whose
  manifest declares the watch form factor for the Play Wear OS track;
  see docs/wearos.md for the verified/unverified boundary.
- Opened a gated installation path for reviewed battery profiles: `community`
  is a new cross-corroborated tier whose every formula and byte window must
  agree across at least two mutually independent, license-pinned sources
  (disagreements are excluded, not averaged). Installation adds read-only
  BMS PIDs to the PID manager after an identity acknowledgement, and polling
  still requires a fresh per-connection vehicle confirmation bound to the
  connection generation and source revision.
- Promoted MG ZS EV Mk1 (2019–2021) to installable community status, with
  OVMS `vehicle_mgev` and WiCAN as recorded corroborating sources and the
  weakly corroborated range DID removed.
- Added installable community BMS profiles for Hyundai Ioniq 5 (E-GMP),
  Kia EV6 (E-GMP), Hyundai Kona Electric (OS), and Kia Niro EV / e-Niro (DE),
  verified against pinned real-vehicle response captures (exact 59/43-byte
  payload contracts on 7E4/7EC).
- Added a Toyota Prius (TNGA) experimental profile — capture-verified SoC,
  pack voltage/current, and block SoC from the hybrid control ECU — kept at
  the one-shot tier because all licensed evidence is a single organization.
- Community profiles are also probe-eligible in the laboratory, so a driver
  can try one consented read before installing.
- Installed profiles persist as references only and are rebuilt from the
  SHA-256-verified catalog on every start; a catalog that withdraws a
  profile uninstalls it cleanly.

### Documentation

- Recorded why researched vehicles ship nothing: Nissan Leaf and Mitsubishi
  Outlander PHEV need custom ELM327 flow control the app does not implement;
  Hyundai Ioniq Electric lacks exact payload-length evidence; the Lexus
  RX450hL byte windows found no independent confirmation and stay
  experimental.
- Registered OVMS (MIT) and GPL-3.0 licence texts with the in-app licence
  page and extended the third-party notices for the new corroborating
  sources.

## 1.0.7+8 — 2026-08-31

### Added

- Added an evidence-gated, offline powertrain-battery catalog with 205
  source-backed PHEV, HEV, BEV, MHEV, REEV, and FCEV profiles. The 203
  research-only entries are non-executable indexes; two opt-in experimental
  entries provide bounded, read-only one-shot queries and none can be installed
  into normal polling.
- Added a disabled-by-default experimental battery laboratory with explicit
  evidence and wire-access consent, single-flight execution, bounded
  per-connection attempts, structural-mismatch quarantine, fail-closed response
  validation, and no persistence into dashboard telemetry.
- Added bundled source manifests, checksums, third-party notices, and in-app
  license access for auditing the catalog independently.

### Documentation

- Clarified that equivalent-version paid Google Play, self-built, and community
  editions have the same app feature set and no paid-only unlocks; Play rollout
  may lag. The purchase pays for Play-managed installation and updates and
  supports ongoing development.
- Documented the catalog's evidence levels and limitations. Source-backed data,
  synthetic rigs, and phone tests do not claim validation on a physical vehicle,
  battery ECU, CAN bus, or adapter.

## 1.0.6+7 — 2026-08-29

### Added

- Added a hash-checked, offline U.S. EPA Find-a-Car catalog containing 50,242
  configurations, 146 make labels, and model years 1984–2027, plus exact
  year/make/model/configuration browsing in Settings. Only unambiguous engine
  displacement and compatible conventional gasoline/diesel fields are applied;
  hybrid fuel, mass, torque, drag, VE, and transmission-efficiency inputs remain
  unknown.
- Added an auditable U.S. NHTSA vPIC make-identity snapshot with 12,351
  vPIC make records. It is intentionally not described as a complete global
  consumer-brand list or as vehicle specification evidence.
- Added session-only VIN identity state. It is reset at every connection
  boundary, while the existing raw diagnostic transcript may still contain the
  VIN as disclosed in the privacy policy; conflicting controllers leave
  identity unknown.
- Added per-field vehicle-profile provenance with source, revision, market,
  record locator, retrieval time, and snapshot SHA-256 in saved assumptions and
  exported session evidence.

### Changed

- Vehicle-profile evidence now distinguishes generic defaults, user input,
  exact official records, ambiguity, and conflicts. A manual value is not
  marked session-confirmed until the driver explicitly reviews the full profile.
- The supported engine-displacement range now includes the 8.4 L factory
  configurations present in the official EPA Find-a-Car snapshot.

## 1.0.5+6 — 2026-08-29

### Added

- Added an explicit whole-profile confirmation state. Any raw PID the vehicle
  answers remains available, while horsepower, torque, and consumption
  estimates stay hidden until the driver reviews the vehicle assumptions for
  the current connection; editing any field or starting another connection
  invalidates confirmation so one car's profile cannot silently reach another.
- Added a privacy-safe GT86 field-shape regression covering split BLE
  notifications, a stray reset byte, chained PID support masks, `7F 01 12`, and
  a padded numbered three-segment ELM327 batch through parser and polling
  publication without publishing the source VIN or device identifiers.

### Fixed

- Explicit real-car event markers now have their own bounded retention lane,
  so a long polling session cannot evict the event needed to interpret the
  surviving wire traffic.

### Documentation

- Added a bounded Toyota GT86 field observation for the exact purchased BLE
  adapter, with an adjacent Shopee affiliate disclosure and no publication of
  the identifier-bearing raw vehicle transcript.
- Added a verification-rig matrix separating project fixtures, the independent
  Ircama oracle, a project-owned hash-pinned research oracle, physical
  Android/BLE paths, identified commercial OBD simulators, and the single
  real-vehicle observation.

## 1.0.4+5 — 2026-08-24

This is the field-evidence build: a real-car failure should come home with
enough context to reproduce and explain it, without a laptop or a second app.

### Added

- **Every connection now carries a versioned evidence header.** The exported
  transcript records the app/build, phone and Android version, configured
  vehicle profile, transport endpoint or adapter identifier, BLE scan RSSI,
  MTU/subscription outcome, protocol, adapter identity and bus facts. Missing
  facts stay `unknown`; the app does not infer a successful result.
- **Four one-tap real-car event markers** — ignition on, engine started,
  throttle blip and road test started — place physical events on the same
  monotonic timeline as the raw OBD bytes and request an immediate snapshot,
  reporting if it remains memory-only. Demo sessions cannot create these
  markers. They live in Settings → Diagnostic records and are intended for a
  stopped vehicle or a passenger.
- Lifecycle and link events are recorded automatically: app background/resume,
  user disconnect and unexpected adapter loss.
- Added isolated Android BLE and Wi-Fi rig drivers. The explicit `rig` flavor
  uses `com.cbstudio.telltale.rig`, clears only its own state, and labels
  exported transcripts as simulated; the `field` flavor keeps physical
  adapter debugging under `com.cbstudio.telltale`.
- Added a deterministic TCP chaos proxy and CI oracle for fragmented replies,
  peer close, missing prompt, and corrupted critical initialization replies.
- Added a hash-locked macOS CoreBluetooth-to-Ircama rig with owner-only logs,
  exact process ownership, bounded lifetime, and fail-closed single-central
  notification routing.
- Added a conventional public documentation index, security policy, conduct
  policy, and a source-controlled privacy policy.

### Fixed

- Remembered-adapter direct connect now opens the dashboard after a successful
  handshake instead of leaving the connected session behind the connect page.
- Android rig evidence now fails closed when the native application-identity
  channel is unavailable or times out, so an unverified `.rig` session cannot
  create real-car markers or replace stored physical evidence.
- A transport that closes during the handshake or its post-handshake probes is
  reported immediately and cannot briefly commit an already-dead session.
- Interrupted, expired, or failed rig commands now remove only their owned
  bridge, emulator, and listener state, then release the OS advisory controller
  lock; no orphaned test service or stale held mutex is left running.
- Rig stop now rediscovers exact kernel identities when PID files are missing or
  partial, and evidence cleanup runs through `--purge-evidence` without
  unlinking live controller-lock inodes.
- Rig startup now retries the complete ownership/listener/advertising snapshot
  when LaunchServices exposes a still-settling process identity, instead of
  tearing down a healthy bridge after one transient check.
- The macOS BLE host now runs owner-private staged scripts outside protected
  source folders and keeps one stable bundle/venv identity across custom
  `TMPDIR` runs, avoiding LaunchServices file-access stalls and stale
  CoreBluetooth TCC grants.
- The physical BLE integration test now scrolls the discovered rig's actionable
  tile into a narrow phone viewport and taps only a hit-testable `InkWell`, so
  an off-screen text finder cannot report a successful tap without attempting
  GATT.

### Changed

- Long recordings preserve the first 200 handshake entries and the newest
  traffic instead of evicting the handshake first. Any omitted middle range is
  labelled with its count and elapsed-time range.
- Snapshot and share operations freeze one atomic transcript/header pair before
  awaiting storage, so later traffic or a new connection cannot relabel or
  extend the evidence being written.
- The evidence header warns that raw OBD traffic can contain VIN and device or
  adapter identifiers. The app never proactively uploads it; operating-system
  backup follows the device's settings, and sharing remains an explicit action.
- Public-facing guides, maintainer notes, and historical verification records
  now live under `docs/`; the repository root keeps only standard project files.
- The README now leads with APK download, supported transports, signing-lineage
  warnings, privacy, and the exact boundary between a physical BLE rig and a
  purchased adapter or vehicle.
- Field and rig guides now work from both the private `torque/app/` layout and
  the public `telltale` repository root, and the field guide identifies GitHub
  APKs as community-signed rather than Play-signed.
- Corrected the recorded `SM-S9280` model name to Galaxy S24 Ultra and pinned
  the Gradle 9.3.1 distribution checksum used by Android builds.

These are no-car test facilities. They do not upgrade simulated sessions into
real adapter, ECU, or vehicle evidence.

## 1.0.3+4 — 2026-08-20

Two defects found by driving 1.0.2 on a phone against real Bluetooth hardware
that misbehaves. Both were true statements a person standing at a car could do
nothing with — the same shape as the empty-scan panel fixed in 1.0.2, and found
the same way.

### Fixed

- **A raw Dart exception is no longer shown to the driver.** Connecting to a
  peripheral that accepts the link and then answers nothing produced
  `TimeoutException after 0:00:10.000000: Future not completed` on screen. The
  message now names the two causes worth checking — an adapter on a switched
  socket has no power until the ignition is on, and another app may be holding
  the link. The exception itself is kept in the transcript, which is where it
  is useful.
- **A recording under a kilobyte is no longer labelled `0 KB`.** A failed
  handshake is a few hundred bytes, so the recording with the most diagnostic
  value in it was the one displayed as empty — directly beneath a sentence
  promising it had been kept. Nobody exports a file the app has called empty.

## 1.0.2+3 — 2026-08-20

Both fixes are failures that only show up where nobody can watch them: a car,
with the app in one hand.

### Fixed

- **A BLE scan that finds nothing now says so, and says what to do.** The panel
  returned to exactly the state it was in before the tap: no message, no
  result, no next step. Bluetooth Classic has had an equivalent since it was
  written. This is the connect screen's worst moment to be silent — somebody is
  at a car with an adapter plugged in, and the three things that actually cause
  it (no power until the ignition is on, out of range, or a Classic adapter
  that can never appear in a BLE list) are all invisible from a blank panel.
  The guidance is ordered by how often each one is the answer.

- **A crash no longer takes the recording with it.** The snapshot that lets a
  session be read after the app dies was written only by the pause and
  teardown handlers, so it covered the app being backgrounded and then killed
  — and covered nothing at all when the process died in the foreground.
  Measured on a Pixel 9: home then `am force-stop` left the recording intact
  and offered on the next launch; `am crash` from the foreground left nothing.
  The second is the app crashing in a car, which is the session most worth
  sending back. A live session now writes every 30 seconds, and only when
  there are new bytes to write, so the most a crash can cost is one interval.

## 1.0.1+2 — 2026-08-18

Published to Google Play's internal testing track, replacing 1.0.0+1, and
attached to the production draft. The production submission is still a draft.

### Changed

- **Bluetooth LE now runs on `universal_ble` 2.1.1 (BSD-3-Clause).** The
  previous package's licence requires a paid commercial licence for "any use …
  by or for a for-profit company or corporation — including commercial use by
  individuals", and this app is sold; the code declared a non-profit licence,
  which was false. The same licence also reserves the right to send build-time
  telemetry — package name, app name, version, date — which does not sit with a
  privacy policy that says nothing is collected. The replacement has neither
  term, and the merged `AndroidManifest.xml` is byte-for-byte unchanged, so no
  permission the app asks for has changed. Rationale in `docs/protocol-deviations.zh-TW.md` §5.

  Four behavioural differences between the two packages had to be handled.
  Three of them would otherwise have been real bugs and are listed under Fixed
  below. The fourth changed only what the app must not do: the new package
  emits one event per advertisement rather than an accumulated list, so a
  consumer that appends would now duplicate every repeat advertisement. The
  scan screen already upserted by id, so nothing about the list changed.

### Fixed

- **Adapters that only support `indicate` now connect.** In the previous
  package one call subscribed either way; in the new one notify and indicate
  are separate calls that throw when the property is absent. A clone that
  indicates rather than notifies would never have completed a connection.
- **Adapters with a non-ASCII name are shown by name.** `BleDevice` strips
  non-ASCII characters in its constructor, so every Chinese-named adapter would
  have appeared as `未命名裝置`. The name now falls back through the raw
  advertisement before giving up, and giving up prints the address rather than
  nothing.
- **A refused MTU negotiation costs throughput, not the connection.** MTU is
  requested after the link is up rather than as part of `connect()`, so an
  adapter that refuses 185 bytes still works, more slowly.
- **A safety refusal is no longer reported as a fact about the car.** When the
  allowlist rejected a service that is not read-only, the screen said
  `此車輛不支援` — a claim about the vehicle with no evidence about the vehicle
  behind it. It has its own fault state now.
- **Horsepower and torque disappear together when acceleration is missing.**
  The rule that hides an unmeasured figure lived in one widget that no test
  loaded by any path.

### Internal

No user-visible change, recorded because they are the reason to trust the rest.

- `BleTransport` has unit tests for the first time — 18, against a scripted
  peripheral that emits a banner during the CCCD write, indicates instead of
  notifying, advertises a CJK name, advertises nothing, refuses an MTU, and
  drops the link mid-discovery. The new package's `setInstance` is what made a
  seam possible; the previous one had none.
- **The reference implementations' assertions were never running.**
  `dart run file.dart` disables assertions, so all three Dart examples printed
  their success banner and exited 0 with deliberately broken expectations.
  They now use throwing checks, which are honest with or without the flag.
- **An oracle had silently stopped checking.** One integration test armed its
  completer 400 ms after `ATZ`, shorter than the emulator's modelled reset, so
  a late banner satisfied it and the identifying answer never arrived: five
  tests skipped and the suite still exited 0 — three of six consecutive runs
  did that, and all six were green. Fixed by waiting for evidence in both
  phases: the polling drain its sibling already used for the second phase,
  extended to the reset as well, rather than a bigger constant.
- The three-language parity contract in `CLAUDE.md` claimed identical class
  names, method decomposition and test cases; eight places said otherwise. The
  implementations were aligned to the claim rather than the claim weakened, and
  the two exceptions that remain on purpose are now named.
- 44 findings from a 13-agent adversarial audit closed.
- CI runs on both repositories: analyze, the full test suite, an Android build,
  and the Ircama ELM327 oracle behind a guard that fails the job if its tests
  were skipped rather than run. The private repository additionally runs the
  three-language reference suite and the second, freeze-frame oracle, whose
  simulator lives on a branch that cannot be published.

## 1.0.0+1 — 2026-08-17

Google Play internal testing only. Never published publicly, and superseded by
1.0.1 before it was.

First release. Real-time telemetry over an ELM327 adapter, on Android, iOS and
macOS:

- Four transports — Bluetooth Classic (RFCOMM/SPP), Bluetooth LE (GATT UART),
  Wi-Fi (TCP), and a built-in demo simulator that models a 2.0 L turbo four so
  every screen can be used without hardware.
- ELM327 handshake with the adapter's self-report treated as a claim rather
  than a fact, an error matrix over the adapter's refusals, and a watchdog.
- The J1979 PID library with a formula engine, priority scheduling, and
  `fastMode` batching that refuses a batched response it cannot attribute.
- Diagnostic trouble codes over Modes 03, 07 and 0A, clearing over Mode 04,
  and freeze-frame data over Mode 02 — gated on the cause code, because a
  controller with no stored frame answers every PID with zeros rather than
  refusing, and those zeros decode to a precise, entirely fictional record.
- Emissions readiness monitors, VIN over Mode 09.
- Derived figures — speed-density mass air flow, fuel consumption, wheel
  horsepower and torque — each hidden rather than guessed when an input is
  missing.
- Custom PIDs with a formula editor, import and export.
- A verbatim transcript of every exchange with the adapter, kept across an app
  kill and exportable as a file, which is the way to bring a failure home from
  a car park.
- Five gauge skins that differ in geometry rather than colour, and light and
  dark palettes that are separately designed rather than inversions.
