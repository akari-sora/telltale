# Phase HUD-01: Phone HUD Foundation Specification

> **Architect**: ChatGPT (GPT-6 Pro)
> **Status**: APPROVED ARCHITECTURE & IMPLEMENTATION BLUEPRINT

我剛核對目前 main，確實已到 eda7392c0880f55d25c2016b7471f36d601dcce3，而 AA-07 的正式狀態現在是：

ELIGIBLE_CANDIDATE (CATEGORY_FIT_UNRESOLVED / READY_FOR_CLOSED_REVIEW)

所以我會把下一步拆成「產品決策 lane」和「工程開發 lane」，而不是三選一。

優先級裁定
優先	方向	裁定
1	C：Google Play Closed Track 車載探針	立刻做，定義為 AA-08
2	A：Phone HUD	送審後立即並行開 HUD-01
3	B：Deep OBD / Extended PID	HUD 基礎穩定後再開

C 排第一不是因為它工程量最大，而是它現在能消除最大的未知數：Google 到底接受不接受 Telltale 這種 OBD telemetry / diagnostics 以 IOT 類別存在。

而且現在正是送的最好時點：Google 明確規定 Closed Testing 的 car form-factor review 是 non-blocking；同樣的 artifact 到 Open Testing 或 Production 才會變成 blocking review。AAOS templated app則應走 dedicated Android Automotive OS track。
Android Developers
+1

所以我的執行順序是：

今天先凍結一個 AA-08 review artifact 丟 Closed Track；等待人工 review期間，不停工，直接開始 HUD-01。

這比「先做 HUD 幾週再送審」資訊效率高很多。

AA-08：Closed Track Qualification Probe

這一階段不要加功能，只做真實 Google reviewer probe。

固定 tag，例如：

Plain text
car-review-probe/2026-10-06

review artifact之後不隨 main漂移。

Android Auto仍由 phone app artifact交付；AAOS走 dedicated Automotive OS track，這正是 Google目前的正式 distribution topology。
Android Developers
+1

成功條件不是「一定要 APPROVED」，而是：

Plain text
REVIEW_ACCEPTED
或
REVIEW_REJECTED_WITH_ACTIONABLE_REASON

兩者都有價值。

如果 Google回：

Plain text
OBD telemetry is not a permitted IOT use case

就停止 production-car promotion，不再用工程手段硬解 policy。

HUD-01：Phone HUD Foundation

HUD是下一個我真正建議寫 code 的切片。

但第一個架構決策很重要：

不要直接復用 CarTelemetryFrame

CarTelemetryFrame 是：

Flutter → Kotlin car projection transport DTO

HUD跟 Dashboard都在 Flutter/mobile process內，若 HUD直接依賴 lib/car/**，反而把手機 UI綁到車載 wire schema。

正確 authority應該是：

Plain text
                    PollingEngine
                         │
                         ▼
                 TelemetrySnapshot
                         │
                  telemetryProvider
                         │
          ┌──────────────┴──────────────┐
          ▼                             ▼
   DashboardScreen                 HudProjector
                                         │
                                         ▼
                                      HudFrame
                                         │
                                         ▼
                                     HudScreen

                         │
                         └──────────► Car Projector
                                      ↓
                                CarTelemetryFrame

也就是：

Dashboard、HUD、Car bridge是三個 presentation projection，共享 TelemetrySnapshot，互相不依賴。

這會是 HUD 架構最重要的不變量。

HUD-01 Scope

第一版只做：

Plain text
Speed           primary
RPM             secondary
Coolant         secondary/status
Data authority  live/stale/missing
Mirror mode
HUD color theme
HUD display session lifecycle

HUD-01 不新增新的 vehicle alert演算法。

這點我刻意限制。

AAOS現在的105°C / 100°C hysteresis是在 Kotlin CarAlertEvaluator；如果現在另外在 Dart寫一套105/100，很快就會出現：

Plain text
Android Auto says Attention
Phone HUD says Normal

所以 HUD-01先把 UI slot留下：

Plain text
HudAlertIndicator

但只處理：

Plain text
NO LIVE DATA
STALE
SIGNAL UNAVAILABLE

真正 coolant critical alert應在 HUD-02做「跨 Dart/Kotlin alert policy contract統一」後再啟用。

模組配置

建議新增：

Plain text
lib/hud/
  hud_frame.dart
  hud_projector.dart
  hud_settings.dart
  hud_controller.dart
  hud_display_session.dart

lib/ui/screens/hud/
  hud_screen.dart
  hud_viewport.dart
  hud_control_overlay.dart
  hud_theme.dart

不要放：

Plain text
lib/obd/hud/**

HUD不是協議能力。

HudFrame

建議：

dart
enum HudValueState {
  live,
  stale,
  missing,
  unavailable,
}

class HudValue {
  final double? value;
  final HudValueState state;
}

class HudFrame {
  final HudValue speedKmh;
  final HudValue rpm;
  final HudValue coolantC;

  final bool connected;
  final DateTime? capturedAt;
}

不要：

dart
double speed = 0;

缺資料永遠不是0。

Live 0 km/h則仍必須：

Plain text
0 km/h
HudProjector

純函數：

Plain text
TelemetrySnapshot?
+ connection state
+ observation clock
        │
        ▼
     HudFrame

規則沿用現有 TelemetrySnapshot 自己的 freshness authority。

你們現在 TelemetrySnapshot.valueOf() 已經會檢查 Reading的 stale狀態，這是很好的一層，不要在 HUD重新發明 TTL。

更重要的是，不要直接用：

dart
ref.watch(telemetryProvider).value

因為 Riverpod loading/error時可能保留舊值。

使用現在專案已經有的 authoritative rule：

Plain text
AsyncData
AND !isLoading
AND !hasError

才可投影為 live HUD資料。

HUD-01 不改 polling policy

這輪我要求：

Plain text
lib/obd/** = 0 diff

HUD只能觀察既有 telemetry。

不要 HUD一開就：

Plain text
activePidsProvider.add(speed/rpm/coolant)

因為那會偷偷改使用者 Dashboard設定。

未來如果實車驗證發現 HUD無法保證速度 PID一直被poll，再開 HUD-02 Telemetry Demand Lease，正式新增 DemandOwner.hud。

不要偷借：

Plain text
DemandOwner.dashboard
DemandOwner.alert
Render cadence

OBD source可能比 UI快很多。

HUD renderer：

Plain text
latest-wins
max render cadence = 10 Hz

不做 interpolation，不做 predicted speed，不做 smoothing產生假值。

也就是：

Plain text
20Hz telemetry
→ HUD最多10Hz重繪
→ 每次拿最新真實 observation

車速HUD 5–10Hz已足夠肉眼連續。

HUD 視覺規格

第一版只允許三個 palette：

Plain text
HUD Green
HUD Amber
HUD Ice Blue

背景：

Plain text
#000000

不要 gradient、陰影、動畫、玻璃材質。

佈局：

Plain text
┌────────────────────────────────────┐
│                                    │
│             88                     │
│            km/h                    │  ← 約55~60% visual weight
│                                    │
│       2850 RPM      92 °C          │
│                                    │
│        [ status / warning ]        │
└────────────────────────────────────┘

Speed必須壓倒性最大。

建議比例：

元件	視覺比重
Speed numeral	55–60%
Unit	8–10%
RPM	15–18%
Coolant	15–18%
status	≤10%

數字用 tabular figures：

dart
FontFeature.tabularFigures()

避免：

Plain text
88 → 101

造成整個 layout橫向跳動。

Mirror Mode

不要 mirror整個 Screen。

正確做法：

Plain text
Stack
├─ Transform(mirrorX)
│    └─ IgnorePointer
│         └─ HudViewport
│
└─ HudControlOverlay   // NOT mirrored

Transform：

dart
Matrix4.diagonal3Values(
  mirrored ? -1.0 : 1.0,
  1.0,
  1.0,
)

alignment = Alignment.center

核心原則：

畫面鏡像，但 hit-test座標系不能鏡像。

所以 mirrored subtree：

Plain text
IgnorePointer

HUD active狀態下，數字本身完全不接受 tap。

防反向觸控

鏡像HUD最常見的 UX bug就是：

右邊看到按鈕，但實際 hitbox跑到左邊。

HUD-01直接禁止這種架構。

Driving HUD active後：

Plain text
short tap = no-op

只留下：

Plain text
system Back
或
非鏡像 control overlay中的長按 Exit

建議：

Plain text
Long press 700 ms → Exit HUD

不要讓駕駛在行進時調：

Plain text
palette
brightness
mirror
layout

這些全部在進入 HUD前設定。

Brightness：不要自動強制100%

這一點我會修改你們初始想法。

預設絕對不要進 HUD就 max brightness。

擋風玻璃HUD主要是夜間場景，100% OLED brightness：

刺眼；
熱；
耗電；
可能讓擋風玻璃反光過強。

Android有 per-window screenBrightness，可以覆寫當前 window而不改使用者的系統亮度；-1可以恢復 system policy，1.0才是 full brightness。
Android Developers
+1

HUD-01建議 preset：

Plain text
System  = no override
Night   = 0.30
Medium  = 0.55
Boost   = 1.00  // user explicit opt-in only

第一進入預設：

Plain text
System
Wakelock

你們 repo其實已經有：

Plain text
lib/core/app_wakelock.dart
wakelock_plus

而 AppShell在 OBD connected時本來就會保持螢幕亮著。

所以：

HUD-01 不要新增第二個 WakeLock authority。

更不要新增：

Plain text
PowerManager.PARTIAL_WAKE_LOCK

Android官方也建議需要保持畫面開啟時使用 foreground Activity的 FLAG_KEEP_SCREEN_ON，而不是舊式 screen wake lock。
Android Developers
+1

HUD只管理：

Plain text
brightness override
immersive mode
mirror/render state

不管理 OBD lifecycle。

Display Session State Machine
Plain text
IDLE
  │
  │ enter HUD
  ▼
ENTERING
  │
  ├─ apply brightness override
  ├─ apply system UI policy
  └─ create HUD renderer
  ▼
ACTIVE
  │
  ├─ app inactive/paused
  ▼
SUSPENDED
  │   restore brightness immediately
  │
  └─ resume while route still active
      → ACTIVE

ACTIVE
  │
  │ back / long press exit
  ▼
EXITING
  │
  ├─ restore brightness
  ├─ restore SystemChrome
  └─ cancel render throttle
  ▼
IDLE

所有 restore必須：

Plain text
idempotent

連續呼叫兩次不得出問題。

Platform bridge

Telemetry不走Pigeon。

只有顯示控制需要 native能力。

建議一個很小的 API：

dart
abstract interface class HudDisplayPlatform {
  Future<void> setBrightnessOverride(double? value);
}

Android：

Plain text
null
→ BRIGHTNESS_OVERRIDE_NONE (-1)

0.0...1.0
→ window.attributes.screenBrightness

不要改：

Plain text
Settings.System.SCREEN_BRIGHTNESS

所以不需要 WRITE_SETTINGS。

Orientation

HUD-01不要硬鎖整個 app landscape。

只在 HUD route有 option：

Plain text
Auto
Landscape
Portrait

第一版 default：

Plain text
Landscape

但離開HUD必須：

Plain text
SystemChrome.setPreferredOrientations([])

恢復 app預設。

foldable / tablet之後可以自然延伸。

Burn-in

HUD-01 不要做 pixel shifting animation。

理由：為了防 burn-in加一個每60秒漂移的 driving UI，收益低、驗證成本高。

第一版只做：

Plain text
pure black background
lower default brightness
no permanent decorative chrome
no animations

HUD-03再做長時OLED soak之後決定是否需要 micro-shift。

HUD-01 Navigation

Dashboard新增：

Plain text
HUD

但只作 navigation：

Plain text
/dashboard
  ↓
/hud

不要塞進底部主要 navigation destination。

HUD是一種 viewing mode，不是產品主要工作區。

HUD-01 驗收矩陣
ID	驗收
HUD01-01	lib/obd/** 0 diff
HUD01-02	不依賴 CarTelemetryFrame
HUD01-03	source authority = telemetryProvider
HUD01-04	live speed 0顯示 0 km/h
HUD01-05	missing speed顯示 --，不得0
HUD01-06	stale speed不得繼續顯示舊 numeric
HUD01-07	RPM / coolant遵循同一 freshness contract
HUD01-08	mirror OFF幾何正常
HUD01-09	mirror ON只翻X、不翻Y
HUD01-10	mirror content不可接收 pointer
HUD01-11	non-mirrored exit overlay hitbox位置不變
HUD01-12	mirror切換不改 telemetry值
HUD01-13	System/Night/Medium/Boost brightness設定正確
HUD01-14	route exit必恢復 system brightness
HUD01-15	app pause必恢復 brightness
HUD01-16	resume HUD route後正確重新套用
HUD01-17	dispose兩次不造成平台錯誤
HUD01-18	HUD不改 activePidsProvider
HUD01-19	HUD不增加 OBD command
HUD01-20	UI rebuild ≤10Hz
HUD01-21	latest-wins，不 queue舊 frames
HUD01-22	Green / Amber / Ice Blue golden tests
HUD01-23	portrait / landscape golden tests
HUD01-24	textScale 1.0 / 1.3不 overflow
HUD01-25	speed 3位數 (188)不 layout shift
HUD01-26	dark background無非HUD白色 chrome
HUD01-27	screen active短tap不改任何設定
HUD01-28	long-press Exit可退出
HUD01-29	Back可退出並完整恢復 display state
HUD01-30	Demo ECU能完整跑 HUD
HUD01-31	physical adapter smoke test
HUD01-32	flutter analyze / full tests green
必須寫的測試

純 Dart：

Plain text
test/hud/hud_projector_test.dart
test/hud/hud_frame_test.dart
test/hud/hud_settings_test.dart
test/hud/hud_render_throttle_test.dart

Widget：

Plain text
test/hud/hud_screen_test.dart
test/hud/hud_mirror_geometry_test.dart
test/hud/hud_touch_isolation_test.dart
test/hud/hud_lifecycle_test.dart

Golden：

Plain text
test/goldens/hud/
  landscape-green.png
  landscape-green-mirrored.png
  landscape-amber.png
  landscape-blue.png
  portrait-green.png
  stale.png
  missing.png
Mirror geometry 必測

不要只測 widget tree上有 Transform。

至少驗：

Plain text
normal:
left = x
right = width - x

mirrored:
left point → width - x
right point → x

y unchanged

並測：

Plain text
mirror(mirror(frame)) == frame

視覺上可以做 golden image與其 horizontal flip像素比較。

Lifecycle mutation test

做假的 platform adapter：

Plain text
enter
→ brightness(0.30)

pause
→ brightness(null)

resume
→ brightness(0.30)

exit
→ brightness(null)

assert exact call order。

這種測試比「最後值正確」重要，因為真正容易出 bug的是：

route已離開但 brightness卡在30%。

不應進 HUD-01 的東西

第一張 MR我會直接拒絕以下內容：

Plain text
new manufacturer PID
new OBD command
active PID mutation
speed interpolation
GPS speed fallback
audio warning / TTS
105°C duplicated alert state machine
background service
foreground service
partial CPU WakeLock
automatic forced max brightness
touchable mirrored controls

這些全都會讓第一片失去邊界。

後續 HUD roadmap

HUD-01完成後：

Plain text
HUD-02
Telemetry Demand Lease
+ unified cross-platform Alert Policy
+ critical coolant visual warning

HUD-03
real windshield field validation
+ glare/brightness presets
+ OLED thermal/burn-in soak
+ vehicle mount ergonomics

HUD-04
optional speed source arbitration
OBD vs GPS

GPS fallback我也不會放第一版，因為它會引進第二個 speed authority及 location permission。

最終執行建議

正式下一個產品里程碑：AA-08 Closed Track Qualification Probe。

今天就送，因為 Closed Testing car review本來就是 non-blocking，正適合驗證你們尚未解決的 IOT category假說。
Android Developers
+1

正式下一個工程里程碑：HUD-01。

兩條並行：

Plain text
Lane 1
AA-08 Closed Track
→ 等 Google external decision

Lane 2
HUD-01
→ mobile-only
→ no car dependency
→ no lib/obd change

B「Extended PID」則等 HUD-01 merge後再開。它的產品價值可能最終比 HUD更大，但 manufacturer-specific PID的資料正確性、車型適配、fixture corpus與實車驗證成本都高很多；現在先做會把團隊帶回底層協議深水區，而你們剛建立好的 mobile/car presentation能力還沒真正轉成新的使用者功能。

所以順序我會鎖成：

C → A → B；其中 C送出去之後，A立即並行。