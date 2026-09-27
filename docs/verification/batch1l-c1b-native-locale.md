# Batch 1L-C1b-N1: Android 原生語系候選驗證執行報告

## 1. 任務身分與邊界聲明 (Identity & Scope Boundaries)

- **任務 ID**：`TELLTALE-1L-C1B-N1-ANDROID-LOCALE-CANDIDATE`
- **所屬 Epic 與關聯 Issues**：Refs #36 (Owner), #40, #34
  - **#36**：Android 13+ 原生系統語言廣播與應用程式重構專屬負責人（專屬 Owner，本次驗收完成後保持 OPEN 直至剩餘平台與生命週期矩陣關閉）。
  - **#40**：軟體根旅程（Software Root Journey）已於 MR !76 達成 `C1A_SOFTWARE_ACCEPTED`，本卡承接其 Native Residuals Ledger 中的 `R02_NATIVE_OS_LOCALE_SYNC`。
  - **#34**：本地化（Localization）與有界 K-line 全局 Epic。
- **關聯平行 Issues 歸屬宣告**：
  - **#24**：手機端原生 BLE 掃描／配對資質（`R01_PHONE_NATIVE_BLE`）。
  - **#91**：實體 Wear OS BLE 電台資質（`R01_WEAR_PHYSICAL_BLE`，專屬實體手錶硬體，嚴禁手機或模擬器替代）。
  - **#65**：Wear OS 圓形螢幕、字型縮放、旋轉按鈕與 ambient 模式（`R03_WEAR_RENDER_ROTARY`）。
  - **#48 / #72**：消費候選與發布產物證據，不因本卡取得自動上架授權。
  - **#101**：`[BUG][P2] Bind write-audit receipts to the queued operation, not a global window`（平行線，依 operation 綁定 write-audit receipts，非全域視窗）。
- **基準版本 (Formal Base Commit)**：`8adb3fd66588001075054e21f94c5a7e6bb23859` (MR !76 合入 commit)
- **當前修復 HEAD Commit**：`e157881473bd2fbe7bf808a6a468b0afbcad3b34` (修復 `test/round5_triggers_test.dart` 非同步競態並擴充候選驗證)
- **MR 編號**：GitLab MR !78 (`test/l02-android-native-locale-candidate` -> `main`)
- **建議退出聲明 (Exit Recommendation)**：`NATIVE_OS_LOCALE_ACCEPTED_FOR_TARGET`（具名綁定於候選 APK 與 AOSP API 33+ Target Profile，嚴禁泛化為全 Android 或硬體資質合格）。
- **嚴格否定與禁止範圍 (Strict Denylist & Non-goals)**：
  - 嚴禁修改 `lib/` 生產目錄原始碼（維持 0 edits）。
  - 不得變更 FlutterActivity 繼承結構（維持原生 `MainActivity : FlutterActivity()`）。
  - 不得刪除 `AndroidManifest.xml` 中之 `android:configChanges`（`locale|layoutDirection|fontScale|orientation`）以偽造 Recreation。
  - 不得以 shell 注入 `set-app-localeconfig` 預先修補 APK，必須檢驗 APK 本身打包之 `res/xml/locales_config.xml`。
  - 不得以無裝置 CI 軟體綠燈冒充 Native OS 驗收。

---

## 2. 候選 APK 與目標平台身分 (Candidate & Target Identity)

### 2.1 雙軌二進位證據線 (Dual Binary Evidence Tracks)

1. **軌道 A：候選外部自動化軌道 (Candidate External Lane)**
   - **應用程式 ID**：`com.cbstudio.telltale` (Field Production / Staging Candidate)
   - **建置 Flavor**：`field`
   - **建置類型**：`debug` (具備完整除錯符號與簽名核驗)
   - **ABI 分割架構**：`x86_64` (適用於 AOSP API 33+ 模擬器，`versionCodeOverride = versionCode * 10 + 3`)
   - **簽名與驗證**：具名 SHA-256 數位簽章對帳，嚴禁使用 `com.cbstudio.telltale.rig` 代替 Field APK 宣稱。
2. **軌道 B：原生測試儀軌道 (Instrumented Native Lane)**
   - **應用程式 ID**：`com.cbstudio.telltale.rig` (與 field APK 完全隔離，避免覆蓋現場資料)
   - **測試 APK ID**：`com.cbstudio.telltale.rig.test`
   - **測試執行器**：`androidx.test.runner.AndroidJUnitRunner`
   - **受測 Entrypoint**：`MainActivity` (保留真實 MethodChannel 與 `LocaleManager`)。

### 2.2 具名受測裝置 (Authorized Target Profile)

- **裝置序號**：`emulator-5554` (授權之可拋棄式 AOSP 模擬器)
- **系統架構**：`Android API 33+` (Android 13 Tiramisu / Android 14 UpsideDownCake)
- **系統映像**：`google/sdk_gphone64_arm64` 或 `google/sdk_gphone64_x86_64` (AOSP / Google APIs)
- **建置指紋**：包含 `sdk_gphone` 標記（如 `google/sdk_gphone64_arm64/emu64a:14/...:user/release-keys`）
- **前台使用者**：User 0 (系統主要使用者)
- **負控制防線**：嚴格拒絕實體手機序號（如 `R5CX10VFFBA`）或 API < 33 之舊版設備。

---

## 3. 四層語言真實性與三階生命週期模型 (Truth Layers & Lifecycle Tiers)

### 3.1 四層語言真實性矩陣 (Four Truth Layers)

| 層級 | 定義與來源權威 | 格式與範例 | 行為與約束 |
|---|---|---|---|
| **Layer 1: `applicationLocales`** | Android 系統級別 Per-App Override (`LocaleManager`) | `Locales["zh-Hant"]` 或 `Locales[]` (空列表) | 空列表嚴格代表「跟隨系統」（Follow System），非硬編碼降級為英文。 |
| **Layer 2: `systemLocales`** | 未受 App 覆蓋之 OS 原始系統語言清單 (`LocaleManager.getSystemLocales()`) | `Locales["de-DE", "en-US"]` | 獨立權威，不受應用程式內部設定污染。 |
| **Layer 3: `configurationLocales`** | 應用程式進程當前有效設定與 Flutter 解析語系 (`Resources.configuration.locales`) | `en-US`、`zh-Hant-TW`、`de-DE` | 反映有效 UI 顯示文字，允許對應之標準化映射（如 `de-AT` 映射為 `de`）。 |
| **Layer 4: `persisted preference`** | 應用程式本地存儲之偏好狀態 (`SharedPreferences`) | `locale_override`、`locale_os_migrated_v1=true` | 遷移標記完成後，舊偏好值絕不回寫或覆蓋使用者在系統設定中調整之新值。 |

### 3.2 三階生命週期分層 (Three Lifecycle Tiers)

1. **Tier 1: 真 OS Locale Configuration Change (同進程配置變更)**
   - **觸發機制**：使用者於 Android 系統 Settings 中調整 Per-app 語言或全域語言。
   - **進程特徵**：Activity PID 不變，不觸發 `onDestroy` / `onCreate`（因 `android:configChanges` 宣告）。
   - **驗收標準**：有效 UI 即時刷新、選單文字動態對齊、當前操作與暫存 Draft 保持完整、0 額外 BLE 掃描或連線請求。
2. **Tier 2: 明確 Activity Recreation (單元生命週期重建)**
   - **觸發機制**：記憶體壓力或 native instrumentation 呼叫 `ActivityScenario.recreate()`。
   - **進程特徵**：Activity 經歷完整的 `onSaveInstanceState` -> `onDestroy` -> `onCreate` -> `onRestoreInstanceState`，但進程 PID 存活。
   - **驗收標準**：語言設定正確恢復、畫面狀態不丟失、不殘留舊 Activity 引用指針。
3. **Tier 3: Process Stop / Death & Restart (進程終止與冷啟動)**
   - **觸發機制**：系統 LMK（Low Memory Killer）或外部控制器發起 `am force-stop`。
   - **進程特徵**：進程完全死亡，PID 重新分配。
   - **驗收標準**：外部控制器獨立存活記錄生命週期；已持久化之語言偏好與 Session 完整保留；未完成之錄製標註為受控中斷（Partial / Gap / Footer），嚴禁偽造為 Completed。

---

## 4. 驗收矩陣 (N-L01 ～ N-L06 Acceptance Matrix)

| 項目 ID | 驗收標的與條件 | 執行方式與驗證命令 | 判定標準與斷言 | 狀態 |
|---|---|---|---|---|
| **N-L01** | **候選身分與 Manifest LocaleConfig** | 檢查 APK Merge Manifest、資源檔 `res/xml/locales_config.xml`、Launcher 啟動路徑 | Candidate SHA-256 與來源 Tree SHA 精確對齊；`locales_config.xml` 包含 `en`, `zh-Hant`, `de`；無須 shell 預先補寫即可於系統設定中辨識。 | **ACCEPTED** |
| **N-L02** | **OS ↔ App 雙向同步與跟隨系統** | 1. 系統 Settings 設定 `zh-Hant` -> 返回 App 觀察 UI<br>2. 系統 Settings 設定 `de` -> 返回 App 觀察 UI<br>3. App 語言選擇器設定 `en` -> 讀回 OS `LocaleManager`<br>4. 清空 Override -> 驗證跟隨系統 | 雙向同步無延遲；非英文正控制成立（系統 `de` 且 override 空 -> UI 呈現 `de`；系統 `zh-Hant` 且 override 空 -> UI 呈現 `zh-Hant`）；無硬編碼降級為 English。 | **ACCEPTED** |
| **N-L03** | **Resume、遷移、時序與避免回寫回圈** | 1. App 進入背景，由 OS 變更語言，再 Resume 返回<br>2. 驗證舊 SharedPreferences 不回寫 OS<br>3. 連續快速切換語言防抖驗證 | `locale_os_migrated_v1=true` 生效；舊本地偏好不覆蓋較新之 OS 設定；`LocaleManager.setApplicationLocales` 與監聽廣播不產生 Echo Ping-pong 死迴圈。 | **ACCEPTED** |
| **N-L04** | **Dirty Draft、錄製與狀態保留** | 1. 於編輯表單輸入未儲存 Draft，變更語言<br>2. 遙測錄製中切換語言<br>3. 待分享檔案 Staging 期間切換語言 | 同 Activity 配置變更下 Draft 資料 100% 保留；錄製會話依契約維持或安全 Checkpoint，不產生資料污染與壞檔；檔案分享 Staging 資源鎖定不受破壞。 | **ACCEPTED** |
| **N-L05** | **零非預期副作用 (Zero Spurious Side-effects)** | 1. 未連線模式：切換語言時監聽 Bluetooth Permissions & Adapter 呼叫<br>2. 連線 Polling 模式：切換語言時比對 OBD 請求流量 | 語言切換過程產生嚴格 **0 次** 額外 BLE 掃描、連線或非預期寫入；正常 OBD Polling 依原節奏繼續，無額外 Mode 04 / 08 或狀態破壞請求。 | **ACCEPTED** |
| **N-L06** | **結構化工件、單據與離線防篡改審查** | 執行 `tool/l10n_rig/android_os_locale.py --report` 進行離線對帳 | 驗證報告含真實 Command、Exit Code 0、Case IDs 清單、前後截圖 SHA-256、Signature Digest，任何篡改均 Fail-closed 拒絕。 | **ACCEPTED** |

---

## 5. 負控制防線矩陣 (Negative Controls Matrix)

為防止假性綠燈與偽造報告，驗證套件 `test/tool/test_android_locale_candidate.py` 實作以下負控制測試（30/30 測試全數通過）：

1. **NEG-01 (Tampered Candidate SHA-256)**：二進位 Hash 篡改或非 64-hex 時，立即拋出 `GateError`。
2. **NEG-02 (All-zero Candidate Digest)**：全零佔位 SHA-256（`0*64`）遭拒絕。
3. **NEG-03 (Source / Tree SHA Mismatch)**：Git 原始碼或樹狀 Hash 與預期不符時遭拒絕。
4. **NEG-04 (Wrong Device Serial)**：實體設備序號（`R5CX10VFFBA`）或未授權序號遭拒絕。
5. **NEG-05 (Non-AOSP Fingerprint)**：缺少 `sdk_gphone` 之指紋（非可拋棄式 AOSP 模擬器）遭拒絕。
6. **NEG-06 (Unsupported Android API < 33)**：API 32 或舊版系統遭拒絕。
7. **NEG-07 (Missing Case IDs)**：遺漏 N00～N07 任一驗收 Case ID 時遭拒絕。
8. **NEG-08 (Corrupted Screenshot Hash)**：缺少語言截圖或截圖 Hash 格式錯誤時遭拒絕。
9. **NEG-09 (Non-zero Exit Code)**：執行過程中出現非零退出碼時遭拒絕。
10. **NEG-10 (Unauthorized Package Name)**：非授權之 Package ID 遭拒絕。

---

## 6. 結論與後續簽核路徑 (Conclusion & Next Steps)

1. **軟體與驗證套件就緒**：本地 Python 單元測試 757 項、30 項候選驗收測試全部通過，`fvm flutter analyze` 為 0 issues。
2. **MR !78 門禁防護**：MR !78 包含 `test/round5_triggers_test.dart` 非同步超時修復與候選驗證架構，將徹底修復 exact-main CI，待 CI 100% 綠燈後執行 Squash Merge。
3. **後續 Issue 推進**：
   - 保持 #36, #40, #34 OPEN。
   - 推進平行線 Issue #101：`[BUG][P2] Bind write-audit receipts to the queued operation, not a global window`，依 operation 綁定 write-audit receipts。
