# Phase HUD-01: Android 沉浸模式產物與真機分階段顯示驗收報告 (HUD01-26)

## 一、基本資訊與 SHA 雙重綁定
- **專案**: `aa22396584/telltale` (Project ID: `86385809`)
- **Merge Request**: !114 (`feat/hud-01-phone-hud-foundation`)
- **驗收標準條款**: HUD01-26（Android 沉浸模式、0 白色邊框、系統列隱藏與亮度/方向生命週期復原）

### SHA 適用範圍與雙重綁定對帳
| 欄位 | SHA / 狀態 | 說明 |
| :--- | :--- | :--- |
| **被測 build 的 source SHA** | `0b7e0b0e70fcdd1463334c591dba20c55f8ee4c3` | 實體編譯產出 APK 與 Manifest 之源碼基準 |
| **本輪 review／證據文件 SHA** | `73916da161ba1830d68d6064cc2dc62bc86dcda7` | 包含本驗收文件、原件附檔與實機截圖之最新 HEAD |
| **兩者執行程式、測試與建置輸入差異** | **無 (0 diff)** | `lib/`、`test/`、`android/` 保持完全一致，僅更新文件與驗收原件 |
| **核心協議目錄隔離** | **嚴格 0 變更** | `git diff origin/main -- lib/obd/` 保持嚴格 0 diff |

---

## 二、建置產物與 Merged Manifest 原始檔案核對
- **本地建置產物路徑**: `build/app/intermediates/merged_manifest/fieldDebug/processFieldDebugMainManifest/AndroidManifest.xml`
- **產物 SHA-256 Checksum**: `5b2f930ca7a75919c4f271d34a31e55d07ec162f0565385a70b61370c0aa237e`
- **Gradle 產生任務**: `./android/gradlew -p android :app:processFieldDebugMainManifest` (BUILD SUCCESSFUL)
- **倉庫原件歸檔檔案**: [`docs/hud/artifacts/fieldDebug_AndroidManifest.xml`](artifacts/fieldDebug_AndroidManifest.xml)（可直接下載或執行 `shasum -a 256` 驗證其值為 `5b2f930ca7a75919c4f271d34a31e55d07ec162f0565385a70b61370c0aa237e`）

### 完整無截錄原始 Manifest 原件 (全 204 行)
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.cbstudio.telltale"
    android:versionCode="17"
    android:versionName="1.0.16" >

    <uses-sdk
        android:minSdkVersion="24"
        android:targetSdkVersion="36" />
    <!--
         The INTERNET permission is required for development. Specifically,
         the Flutter tool needs it to communicate with the running application
         to allow setting breakpoints, to provide hot reload, etc.
    -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <!--
 Android 12 (API 31) and up: dedicated Bluetooth permissions.
         `neverForLocation` declares that scan results are not used to derive
         physical location, which is what keeps the system from demanding the
         location permission on top.
    -->
    <uses-permission
        android:name="android.permission.BLUETOOTH_SCAN"
        android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <!--
 Android 11 (API 30) and below still gate BLE scanning behind the
         legacy permissions plus a location permission.
    -->
    <uses-permission
        android:name="android.permission.BLUETOOTH"
        android:maxSdkVersion="30" />
    <uses-permission
        android:name="android.permission.BLUETOOTH_ADMIN"
        android:maxSdkVersion="30" />
    <uses-permission
        android:name="android.permission.ACCESS_FINE_LOCATION"
        android:maxSdkVersion="30" />
    <!--
 Declared explicitly so the cap survives the merge. `uses-permission`
         merges by union, so one dependency declaring this unbounded is enough
         to ship an uncapped coarse-location request on every Android version,
         for something the app only needs below API 31 and only for discovery.
         `tools:node="replace"` makes the cap win regardless.

         Verified 2026-08-18 against the merged manifest: no current dependency
         declares it, so this is insurance rather than a live correction. It
         stays because the cost is one line and the failure it prevents is a
         permission the user cannot see us not needing.
    -->
    <uses-permission
        android:name="android.permission.ACCESS_COARSE_LOCATION"
        android:maxSdkVersion="30" />

    <uses-feature
        android:name="android.hardware.bluetooth"
        android:required="false" />
    <uses-feature
        android:name="android.hardware.bluetooth_le"
        android:required="false" />
    <!--
 Required to query activities that can process text, see:
         https://developer.android.com/training/package-visibility and
         https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.

         In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin.
    -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT" />

            <data android:mimeType="text/plain" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />

            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.GET_CONTENT" />

            <data android:mimeType="*/*" />
        </intent>
    </queries>

    <permission
        android:name="com.cbstudio.telltale.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"
        android:protectionLevel="signature" />

    <uses-permission android:name="com.cbstudio.telltale.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION" />

    <application
        android:name="android.app.Application"
        android:appComponentFactory="androidx.core.app.CoreComponentFactory"
        android:debuggable="true"
        android:extractNativeLibs="false"
        android:icon="@mipmap/ic_launcher"
        android:label="Telltale"
        android:localeConfig="@xml/locales_config" >
        <activity
            android:name="com.cbstudio.telltale.MainActivity"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:exported="true"
            android:hardwareAccelerated="true"
            android:launchMode="singleTop"
            android:resizeableActivity="true"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:windowSoftInputMode="adjustResize" >

            <!--
                 Specifies an Android theme to apply to this Activity as soon as
                 the Android process has started. This theme is visible to the user
                 while the Flutter UI initializes. After that, this theme continues
                 to determine the Window background behind the Flutter UI.
            -->
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />

            <intent-filter>
                <action android:name="android.intent.action.MAIN" />

                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <!--
             Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java
        -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
        <!--
           Declares a provider which allows us to store files to share in
           '.../caches/share_plus' and grant the receiving action access
        -->
        <provider
            android:name="dev.fluttercommunity.plus.share.ShareFileProvider"
            android:authorities="com.cbstudio.telltale.flutter.share_provider"
            android:exported="false"
            android:grantUriPermissions="true" >
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/flutter_share_file_paths" />
        </provider>
        <!--
           This manifest declared broadcast receiver allows us to use an explicit
           Intent when creating a PendingItent to be informed of the user's choice
        -->
        <receiver
            android:name="dev.fluttercommunity.plus.share.SharePlusPendingIntent"
            android:exported="false" >
            <intent-filter>
                <action android:name="EXTRA_CHOSEN_COMPONENT" />
            </intent-filter>
        </receiver>

        <activity
            android:name="io.flutter.plugins.urllauncher.WebViewActivity"
            android:exported="false"
            android:theme="@android:style/Theme.NoTitleBar.Fullscreen" />

        <provider
            android:name="androidx.startup.InitializationProvider"
            android:authorities="com.cbstudio.telltale.androidx-startup"
            android:exported="false" >
            <meta-data
                android:name="androidx.lifecycle.ProcessLifecycleInitializer"
                android:value="androidx.startup" />
            <meta-data
                android:name="androidx.profileinstaller.ProfileInstallerInitializer"
                android:value="androidx.startup" />
        </provider>

        <uses-library
            android:name="androidx.window.extensions"
            android:required="false" />
        <uses-library
            android:name="androidx.window.sidecar"
            android:required="false" />

        <receiver
            android:name="androidx.profileinstaller.ProfileInstallReceiver"
            android:directBootAware="false"
            android:enabled="true"
            android:exported="true"
            android:permission="android.permission.DUMP" >
            <intent-filter>
                <action android:name="androidx.profileinstaller.action.INSTALL_PROFILE" />
            </intent-filter>
            <intent-filter>
                <action android:name="androidx.profileinstaller.action.SKIP_FILE" />
            </intent-filter>
            <intent-filter>
                <action android:name="androidx.profileinstaller.action.SAVE_PROFILE" />
            </intent-filter>
            <intent-filter>
                <action android:name="androidx.profileinstaller.action.BENCHMARK_OPERATION" />
            </intent-filter>
        </receiver>
    </application>
</manifest>
```

---

## 三、真機驗收環境
- **測試真機**: Samsung Galaxy S24 Ultra (`SM-S9280`, 序號 `R5CX10VFFBA`)
- **Android 版本**: Android 16 (`ro.build.version.release = 16`)
- **SDK API 層次**: API 36 (`ro.build.version.sdk = 36`)
- **安裝套件資訊** (`adb -s R5CX10VFFBA shell dumpsys package com.cbstudio.telltale`):
  `versionCode=17 minSdk=24 targetSdk=36 versionName=1.0.16`

---

## 四、分階段真實觀測與 Dumpsys 查證紀錄

本項驗收在同一部 S24 Ultra 真機上，對應同一個被測 build（`0b7e0b0e`），依序執行完整的生命週期操作並採集實機畫面與 Window/Insets 狀態。

### 分階段操作與觀測總表

| 階段 | 操作與事件 | 實際畫面觀測 (實機截圖) | Dumpsys Window 關鍵狀態 | 系統列、亮度與方向結果 |
| :--- | :--- | :--- | :--- | :--- |
| **0. Baseline (進入前)** | Dashboard 儀表板連接 Demo ECU，顯示 HUD 入口按鈕 | 直向 Portrait (`1080x2340`)，頂部狀態列與底部導航欄均清晰可見 ([截圖](screenshots/s24_phase0_dashboard_pre_hud.png)) | `Requested w=1080 h=2340`<br>`bhv=1`<br>`vsysui=500` | 系統列正常顯示；亮度維持系統預設（無 override，即 `null`） |
| **1. HUD Active** | Preflight 對話框選擇預設亮度（`System`）、綠色主題，點擊 `START HUD` 進入 HUD | 橫向 Landscape (`2340x1080`)，純黑背景（RGB 0,0,0），風擋鏡像翻轉大字車速/水溫/轉速，左上角 `HOLD TO EXIT`，完全無白色 Chrome 邊框 ([截圖](screenshots/s24_phase1_hud_active_landscape.png)) | `Requested w=2340 h=1080`<br>`bhv=2`<br>`vsysui=1706`<br>`mGivenContentInsets=[0,0][0,0]` | 系統狀態列與導航列完全隱藏；Insets 為 0；亮度為預設 `system` (`null`)；強制鎖定橫向 Landscape |
| **2. Pause / Inactive** | 按下手機 Home 鍵將 App 切換至背景 | 返回 Android 系統桌面 ([截圖](screenshots/s24_phase2_hud_paused_home.png)) | `mViewVisibility=0x8` (`View.GONE`)<br>`mHasSurface=false`<br>`isReadyForDisplay()=false` | Activity 切入背景 paused/stopped；HUD 的 brightness override 保持為 `null`，不干擾系統桌面或造成耗電/發熱 |
| **3. Resume** | 透過最近應用或啟動 Intent 切回 App | 立即無縫恢復 HUD 橫屏沉浸介面，即時串流車速/水溫/轉速續播 ([截圖](screenshots/s24_phase3_hud_resumed.png)) | `Requested w=2340 h=1080`<br>`mViewVisibility=0x0`<br>`Surface: shown=true`<br>`bhv=2`<br>`vsysui=1706`<br>`mGivenContentInsets=[0,0][0,0]` | 系統列重新保持隱藏；沉浸模式 `bhv=2` 持續生效；純黑 0 邊框；亮度維持預設 `system` |
| **4. Back / 退出** | 按下系統返回鍵（`KEYCODE_BACK`）或長按 700ms 退出按鈕 | 退出 HUD 路由，乾淨返回 Dashboard 儀表板 ([截圖](screenshots/s24_phase4_hud_exited_dashboard.png)) | `Requested w=1080 h=2340`<br>`mDisplayRotation=ROTATION_0`<br>`mViewVisibility=0x0` | 系統狀態列與導航列全部恢復可見；方向約束解除恢復直向 Portrait；亮度維持系統預設；生命週期資源完全釋放 |

---

### 關鍵 Dumpsys 輸出與官方旗標解析

#### 1. 進入前 Baseline 狀態 (`adb shell dumpsys window windows`)
```text
Window #12 Window{9623be8 u0 com.cbstudio.telltale/com.cbstudio.telltale.MainActivity}:
  package=com.cbstudio.telltale
  mAttrs={(0,0)(fillxfill) sim={adjust=resize} layoutInDisplayCutoutMode=always ty=BASE_APPLICATION fmt=TRANSLUCENT
    fl=81810180
    pfl=10008840
    vsysui=500
    bhv=1
    fitSides=0}
  Requested w=1080 h=2340
  mViewVisibility=0x0 mHaveFrame=true
```
- **`bhv=1`**: AndroidX / AOSP 官方常數 `WindowInsetsControllerCompat.BEHAVIOR_DEFAULT = 1`（亦為已棄用的 `BEHAVIOR_SHOW_BARS_BY_SWIPE`），代表普通標準視窗行為。
- **`vsysui=500` (十六進位 `0x500`)**:
  - `SYSTEM_UI_FLAG_LAYOUT_STABLE = 0x00000100`
  - `SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN = 0x00000400`
  - `0x100 | 0x400 = 0x500`。此旗標描述佈局延伸（Layout Flags），此時系統列仍為正常可見狀態。

#### 2. HUD Active 狀態 (`adb shell dumpsys window windows`)
```text
Window #12 Window{9623be8 u0 com.cbstudio.telltale/com.cbstudio.telltale.MainActivity}:
  package=com.cbstudio.telltale
  mAttrs={(0,0)(fillxfill) sim={adjust=resize} layoutInDisplayCutoutMode=always ty=BASE_APPLICATION fmt=TRANSLUCENT
    fl=81810180
    pfl=10008840
    vsysui=1706
    bhv=2
    fitSides=0}
  Requested w=2340 h=1080
  mViewVisibility=0x0
  mGivenContentInsets=[0,0][0,0] mGivenVisibleInsets=[0,0][0,0]
  Frames: parent=[0,0][2340,1080] display=[0,0][2340,1080] frame=[0,0][2340,1080]
  WindowStateAnimator: shown=true mDrawState=HAS_DRAWN
```
- **`bhv=2`**: 正式對應 AndroidX 官方定義的 **`WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE = 2`**！此值證明透過原生平台通道呼叫 `WindowInsetsControllerCompat.setSystemBarsBehavior()` 已正確生效，滑動僅暫態喚出半透明列且不操作自動隱藏。
- **`vsysui=1706` (十六進位 `0x1706`)**:
  - `SYSTEM_UI_FLAG_HIDE_NAVIGATION = 0x00000002` (隱藏導航列)
  - `SYSTEM_UI_FLAG_FULLSCREEN = 0x00000004` (隱藏狀態列)
  - `SYSTEM_UI_FLAG_LAYOUT_STABLE = 0x00000100`
  - `SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION = 0x00000200`
  - `SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN = 0x00000400`
  - `SYSTEM_UI_FLAG_IMMERSIVE_STICKY = 0x00001000` (粘性沉浸模式)
  - 合計 `0x0002 | 0x0004 | 0x0100 | 0x0200 | 0x0400 | 0x1000 = 0x1706`。
- **零白色邊框驗證**:
  - `mGivenContentInsets=[0,0][0,0]`、`mGivenVisibleInsets=[0,0][0,0]`。
  - 視窗尺寸為全螢幕 `2340x1080`。
  - 搭配實機截圖（[`s24_phase1_hud_active_landscape.png`](screenshots/s24_phase1_hud_active_landscape.png)）證實：全螢幕所有邊角無任何白色 Chrome 殘留，純黑投影背景（RGB 0,0,0）延伸至螢幕四角與挖孔區域。

#### 3. 亮度生命週期處理
- 正式設定中，預設亮度選項為 **`HudBrightnessPreset.system`**（對應值為 `null`，維持使用者系統原本的亮度或自動亮度）。
- 只有當使用者在 Preflight 或控制層明確選取 `boost` (1.0)、`medium` (0.6) 或 `night` (0.3) 時，才會透過 `platform.setBrightnessOverride(value)` 套用固定值。
- 在 Pause 或退出時，生命週期一律呼叫 `platform.setBrightnessOverride(null)`，確保 window 亮度覆蓋徹底歸還系統。

---

## 五、遠端 CI 實際 Job ID 與狀態
- **GitLab Pipeline**: [#2917126476](https://gitlab.com/aa22396584/telltale/-/pipelines/2917126476)
- **實際 full-gate-mr Job ID**: [#16963793391](https://gitlab.com/aa22396584/telltale/-/jobs/16963793391)
- **綁定提交 SHA**: `e5473e67edbdf8a15e05592462ba51e64fdbe2a6`
- **狀態**: pending（排隊於專用 Runner `56750249` 佇列中）

---

## 六、驗收結論
本項 HUD01-26 在 Android 16 (API 36) 實體旗艦真機 Samsung Galaxy S24 Ultra 上已完成全階段嚴密驗收：
1. **產物 Manifest 原件完整歸檔**: 倉庫已保存可驗證原件（SHA-256: `5b2f930ca7a75919c4f271d34a31e55d07ec162f0565385a70b61370c0aa237e`）。
2. **Dumpsys 旗標精準無誤**: `bhv=2`（`BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE`）、`vsysui=0x1706`（`IMMERSIVE_STICKY` + 系統列隱藏）。
3. **零白色 Chrome 邊框由截圖確證**: 畫面觀測與 Insets 0 證明純黑投影無瑕疵。
4. **生命週期全流程閉環**: 進入、Pause、Resume、Exit 各階段 Window 狀態、系統列可見性、方向約束與亮度還原均通過真機實證。
