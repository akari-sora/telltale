# TellTale Native Storage Mapping & Platform OS Backup Evidence (A11 / A12)

## 1. 範疇與目的
本文件提供 TellTale (WS-07 Slice 4) 針對 Android (原 A11) 與 iOS / macOS (原 A12) 之原生本機儲存與 OS 備份行為的不可變映射材料，對應 `docs/privacy/policy-data-flow-contract.md` 與 `docs/privacy/data-flow-inventory.json`，鎖定底層 plugin、engine 與原生 API 實作路徑。

---

## 2. 鎖定相依套件與平台實作版本 (pubspec.lock 驗證)

| 套件名稱 | 鎖定版本 | SHA-256 Digest | 平台原生實作庫與鎖定版本 |
|---|---|---|---|
| `shared_preferences` | `2.5.5` | `c3025c5534b01739267eb7d76959bbc25a6d10f6988e1c2a3036940133dd10bf` | `shared_preferences_android: 2.4.27`<br>`shared_preferences_foundation: 2.5.6`<br>`shared_preferences_linux: 2.4.1`<br>`shared_preferences_windows: 2.4.1` |
| `path_provider` | `2.1.6` | `a7f4874f987173da295a61c181b8ee71dab59b332a486b391babf26a1b884825` | `path_provider_android: 2.3.1`<br>`path_provider_foundation: 2.6.0`<br>`path_provider_linux: 2.2.2`<br>`path_provider_windows: 2.3.0` |

---

## 3. Android 原生儲存與 OS 備份映射 (A11)

### 3.1 儲存流與底層 API 映射
1. **SharedPreferences (Key-Value 偏好設定)**:
   - **Flutter 呼叫**: `SharedPreferences.getInstance()`
   - **原生實作**: `shared_preferences_android-2.4.27` 透過 `android.content.Context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)`。
   - **實體路徑**: `/data/user/0/com.cbstudio.telltale/shared_prefs/FlutterSharedPreferences.xml`（對應 Android Auto Backup XML `<sharedpref/>` domain）。
   - **存放內容**: 儲存使用者設定與運作狀態，包括最近連線適配器參數（`last_adapter_v1`: id/name/kind/port）、單位換算偏好及 UI 佈景主題。不主動收集個人身分資料（如姓名、電話、身分證號）。
2. **App 內部檔案目錄 (Documents)**:
   - **Flutter 呼叫**: `path_provider.getApplicationDocumentsDirectory()`
   - **原生實作**: `path_provider_android-2.3.1`（透過 Flutter Engine `PathUtils.getDataDirectory(context)` / `context.getDir("flutter", Context.MODE_PRIVATE)`）。
   - **實體路徑**: `/data/user/0/com.cbstudio.telltale/app_flutter/`（對應 Android Auto Backup XML `<root path="app_flutter"/>` domain，與 `docs/privacy/data-flow-inventory.json` 及合約鎖定之 `root` domain 完全一致）。
3. **App 快取目錄 (Cache)**:
   - **Flutter 呼叫**: `path_provider.getTemporaryDirectory()`
   - **原生實作**: `path_provider_android-2.3.1` 透過 `Context.getCacheDir()`。
   - **實體路徑**: `/data/user/0/com.cbstudio.telltale/cache/`（對應 Android Auto Backup XML `<cache/>` domain，預設由系統備份排除）。

### 3.2 AndroidManifest 合併與備份行為證明
依據已提交之公開去敏 Blame 報告 `docs/privacy/evidence/field-release-manifest-merger-blame-report.txt`：
- **Blame 第 143–156 行（對應 Merged Manifest 第 92–98 行）**：
  ```text
  92    <application
  92-->INJECTED
  93        android:name="android.app.Application"
  93-->INJECTED
  94        android:appComponentFactory="androidx.core.app.CoreComponentFactory"
  94-->[androidx.core:core:1.18.0] <GRADLE_USER_HOME>/caches/9.3.1/transforms/d093bb2eca2532b7d20813ec3c4a0c68/transformed/core-1.18.0/AndroidManifest.xml:28:18-86
  95        android:extractNativeLibs="false"
  95-->INJECTED
  96        android:icon="@mipmap/ic_launcher"
  96--><REPO_ROOT>/android/app/src/main/AndroidManifest.xml:60:9-43
  97        android:label="Telltale"
  97--><REPO_ROOT>/android/app/src/main/AndroidManifest.xml:58:9-33
  98        android:localeConfig="@xml/locales_config" >
  ```
- **Blame 溯源證明**：
  - `<application>` 標籤中無任何自訂 `android:fullBackupContent` 或 `android:dataExtractionRules`，亦無顯式配置 `android:allowBackup`（屬性完全缺省，系統維持預設無自訂備份規則狀態）。
  - 本次 Manifest 查核未見上述備份或同步元件宣告；這不單獨證明沒有網路通訊。OBD-II Socket 的目的主機與連接埠由使用者設定，通常為區域網路轉接器；本文件不宣稱存在全域 LAN-only 防火牆。資料收集、分享與 SDK 掃描的結論以既有資料流清冊及其明訂的有限驗證範圍為準。

---

## 4. Apple (iOS / macOS) 原生儲存與 OS 備份映射 (A12)

### 4.1 儲存流與底層 API 映射
1. **UserDefaults (Key-Value 偏好設定)**:
   - **Flutter 呼叫**: `SharedPreferences.getInstance()`
   - **原生實作**: `shared_preferences_foundation-2.5.6` 透過 `[NSUserDefaults standardUserDefaults]`。
   - **實體路徑**:
     - iOS: `<App_Sandbox>/Library/Preferences/com.cbstudio.telltale.plist`
     - macOS: `~/Library/Containers/com.cbstudio.telltale/Data/Library/Preferences/com.cbstudio.telltale.plist`
   - **存放內容**: 車輛診斷設定與介面偏好（與 Android SharedPreferences 對應之本機設定）。
2. **Documents 目錄**:
   - **Flutter 呼叫**: `path_provider.getApplicationDocumentsDirectory()`
   - **原生實作**: `path_provider_foundation-2.6.0` 透過 `NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)`。
   - **實體路徑**: `<App_Sandbox>/Documents/`。
3. **Caches 目錄**:
   - **Flutter 呼叫**: `path_provider.getTemporaryDirectory()`
   - **原生實作**: `path_provider_foundation-2.6.0` 透過 `NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)`。
   - **實體路徑**: `<App_Sandbox>/Library/Caches/`。

### 4.2 Apple 平台 Entitlements 與系統備份行為
- **Entitlements 查核**:
  - iOS 專案目錄 `ios/Runner/` 中**無自訂 entitlements 檔案**（未建立 `Runner.entitlements`），未啟用任何自訂 Apple Capability（如 iCloud / CloudKit 容器、背景推送同步等）。`ios/Runner/Info.plist` 亦無宣告任何 iCloud 相關鍵值。
  - macOS `macos/Runner/Release.entitlements` 僅宣告標準沙盒、網路客戶端、藍牙與使用者選取檔案唯讀權限，**未宣告** `com.apple.developer.ubiquity-kvstore-identifier`（iCloud Key-Value Store）或 `com.apple.developer.icloud-container-identifiers`（CloudKit Containers）。
- **系統 OS 備份與 App 雲端隔離**:
  - 明確區分「App 自行連線 iCloud 同步」與「Apple 系統層級 OS 備份」：
    1. **App 自身零雲端外傳**：App 未宣告 iCloud entitlements，無任何程式碼連線 Apple CloudKit 或第三方伺服器上傳車載遙測數據。
    2. **iOS／iPadOS 系統備份：**App 的本機資料可能依系統排除規則與使用者設定，納入 Finder／iTunes 裝置備份，或在啟用 iCloud Backup 後由系統自動備份。手動備份並非唯一觸發方式；這與 App 自行使用 CloudKit／iCloud 同步是不同機制。快取目錄（`Library/Caches`）依平台規範被系統自動排除於備份之外。
    3. **macOS 備份：**Mac 的本機資料是否被複製，取決於使用者設定的 Time Machine 或其他備份工具及其排除規則。iCloud Drive／App 資料同步不等同 iOS 的整機 iCloud Backup。真實備份／還原實驗維持 NOT_RUN。

---

## 5. 結論
TellTale 內部資料儲存機制 100% 局限於本機沙盒原生路徑，無任何外發第三方追蹤或遙測伺服器。原生 Android 與 Apple 儲存映射與隱私合約一致。
