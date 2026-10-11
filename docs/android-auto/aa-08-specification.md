# Phase AA-08 規格藍圖：車載安全架構規範與 L0~L6 分層測試金字塔門禁 (SAFE-01 ~ SAFE-10)

狀態：APPROVED / IN-IMPLEMENTATION  
基準 Commit：`2bffec2696bf1f387651e064bfb7a69bafb99cae`  
適用範疇：Android Auto 投影（Projection）與 AAOS 原生車機（Automotive OS Native）  
關聯規範：[AA-00 車載適格性與隔離契約](aa-00-eligibility.md)、[AA-04 規劃與 DHU 走查指引](aa-04-planning-and-dhu-walkthrough.md)、[AA-05 規格藍圖](aa-05-planning-and-spec.md)、[AA-06 總驗收報告](aa-06-verification-report.md)、[AA-07 應用商店審核與推廣矩陣](aa-07/category-fit.md)

---

## 一、規範背景與核心定位

本規範（AA-08）為 Telltale (Torque) 車載 OBD-II 監控系統的權威車規安全標準。本系統於車載投影（Android Auto / `carProto`）與原生車機（AAOS / `automotive`）運行時，必須嚴格遵守 Google 駕駛防分心指南（Google Driver Distraction Guidelines, DDG）以及航空/車載級最高安全防護原則。

車載診斷系統（OBD-II）涉及即時遙測傳輸、故障診斷代碼（DTC）查詢與凍結幀分析。行車操作若出現狀態誤判或延遲反彈漏洞，極易分散駕駛人視線，引發嚴重交通意外。為確保代碼層面杜絕任何安全漏洞，本規範建立：
1. **L0～L6 分層測試金字塔體系**：涵蓋純記憶體單元、跨語言 Wire Golden、Fake Host 模擬、Session 併發、無頭化自動跑道、混亂工程與實車驗證。
2. **SAFE-01～SAFE-10 十大核心安全不變條件矩陣**：明確定義代碼守衛切面、違規危害與驗收門禁。

---

## 二、L0～L6 分層測試金字塔架構 (Tiered Testing Pyramid)

為達成 100% 可復現、零盲區之車規驗收標準，本架構定義由底層至頂層的 7 級分層驗證金字塔：

```
       ▲
      / \        L6: Real Device / Hardware-in-the-Loop & Bench Walkthrough
     /   \       L5: Chaos Engineering & Targeted Mutation Harness
    /     \      L4: Headless DHU & AAOS VHAL Automated Simulation Runways
   /       \     L3: Session Runtime & Multi-Source Concurrency Testing
  /         \    L2: Fake Host Component & UI Screen Lifecycle Testing
 /           \   L1: Cross-Language Wire Contracts & Golden Fixtures
/_____________\  L0: In-Memory Unit & Mathematical Invariants
```

### 1. L0: In-Memory Unit & Mathematical Invariants（純記憶體單元與數值不變量）
- **範圍**：JVM / Kotlin 與 Dart 之純記憶體數據結構、數值包絡（Envelopes）、狀態機轉移。
- **特徵**：完全無 Android OS、Car App Library 或硬體依賴，執行時間以毫秒計。
- **核心驗證**：
  - 數值淨化（Sanitization）：負零 `-0.0` 歸零消除、非有限浮點數（`NaN`, `Infinity`）降級為 `UNAVAILABLE`。
  - 傳輸包絡門禁：`SPEED_KMH_ENVELOPE`、`RPM_ENVELOPE`、`COOLANT_C_ENVELOPE` 邊界校驗。
  - 運動融合數學推導：`CarVehicleMotionResolver` 嚴格保守判定（`freshSpeeds.any { it != 0.0 || it < 0.0 }` 判定為 `MOVING`）。

### 2. L1: Cross-Language Wire Contracts & Golden Fixtures（跨語言 Wire 契約與 Golden 比對）
- **範圍**：Flutter Dart 與 Android Native (Kotlin) 間之 Pigeon 二進制通訊、OBD `.hex` 封包交換。
- **特徵**：驗證兩端序列化/反序列化一致性，雙向 0 代碼漂移。
- **核心驗證**：
  - `bash tool/ci/verify_car_pigeon_codegen.sh`：確認 Pigeon 生成產物完全無 Git diff。
  - Telemetry Frame 跨語言時間戳與世代欄位（`connectionEpoch`, `sequence`, `producedAtMonotonicUs`）無損傳遞。
  - 診斷通道 `CarDiagnosticsHostApi` 唯讀契約校驗（僅向 Host 派發 DTC 數據，禁止反向寫入控制指令）。

### 3. L2: Fake Host Component & UI Screen Lifecycle Testing（Fake Host 元件與畫面生命週期）
- **範圍**：Car App Library UI Screen（`CarHomeScreen`, `CarHealthScreen`, `CarDtcSummaryScreen`, `CarDtcDetailScreen`）。
- **特徵**：使用 `androidx.car.app.testing.FakeCarContext` 與 Mockito/Robolectric 模擬宿主車機環境。
- **核心驗證**：
  - 1Hz 畫面刷新節流閥（SAFE-08）：模擬高頻遙測更新，驗證 1 秒內 `invalidate()` 觸發次數 ≤ 1。
  - 主機行數上限截斷（SAFE-10）：在 4/6 列限制下驗證尾項顯示「尚有 N 項未顯示」溢出列。
  - 停駐點擊監聽器（SAFE-03）：驗證 `ParkedOnlyOnClickListener` 於行駛狀態下點擊無效。

### 4. L3: Session Runtime & Multi-Source Concurrency Testing（Session 作用域與多源併發）
- **範圍**：`CarSessionRuntime`、`CarTelemetryRepository`、`CarHostSpeedRepository`、`CarAlertCoordinator`。
- **特徵**：虛擬時鐘協同（Virtual Coroutine Clock）、多資料來源競爭與非同步協同調度。
- **核心驗證**：
  - 跨來源仲裁優先序（AA05-09~13）：OBD > Host Display > Host Raw > Unavailable。
  - 連線世代隔離（SAFE-05）：OBD 斷線重連遞增 Epoch 時，舊 DTC 報告立即失效並撤銷准入。
  - 併發寫入無競爭：多協程同時觸發新鮮度過期、硬體回報與遙測幀注入時維持狀態機線性一致。

### 5. L4: Headless DHU & AAOS VHAL Automated Simulation Runways（無頭化自動跑道）
- **範圍**：Android Auto Desktop Headed/Headless Unit (DHU 2.0) 與 AAOS 無頭模擬器（AVD）。
- **特徵**：完全在無 GUI / CI 環境下透過 stdin 與 ADB 管道注入行車指令，全自動化執行。
- **核心驗證**：
  - 6 大螢幕規格（480p, 720p, 1080p Wide, Portrait, High-DPI, Insets）自動走查無黑畫面、無文字截斷。
  - AAOS VHAL 感測器注入：透過 `dumpsys car_service inject-vhal-event` 注入車速 (`0x11600207`) 與檔位 (`0x11400400 GEAR_SELECTION`)，驗證儀表與門禁狀態機聯動。
  - 像素級亮度與變異數分析保證無黑畫面閃爍。

### 6. L5: Chaos Engineering & Targeted Mutation Harness（混亂工程與定向變異馬具）
- **範圍**：ELM327 原始位元組串流、底層 Transport 異常注入、關鍵安全代碼變異。
- **特徵**：模擬真實世界惡劣環境，對協議層實施高壓攻擊，同時驗證測試套件的防禦能力。
- **核心驗證**：
  - 原始串流混亂馬具（`test/chaos_stream_harness_test.dart`）：模擬封包黏包、分片、缺失 `\r\n`、百毫秒級非對稱延遲與假死超時，驗證狀態機絕不死鎖或洩漏記憶體。
  - 恪守 `lib/obd/` 嚴格 0 變更不變量。
  - 定向變異測試（`tool/ci/run_targeted_mutations.py`）：對倒車判定、起步回彈、Epoch 隔離等核心邏輯植入人為變異，驗證測試套件 100% 擊殺變異體（Mutant Killed Rate = 100%）。

### 7. L6: Real Device / Hardware-in-the-Loop & Bench Walkthrough（真機台架與實車驗收）
- **範圍**：Samsung Galaxy S24 Ultra 真機、AAOS 實體車機台架、OBD-II 物理轉接器（vLinker MC+ / OBDLink CX）。
- **特徵**：子像素級渲染驗收、熱插拔抗干擾與實車長程路測。
- **核心驗證**：
  - 儀表狀態膠囊垂直幾何對齊誤差 < 0.7px。
  - 實體藍牙/Wi-Fi 斷連重連時，車機與手機 UI 狀態平滑恢復。
  - 三語系（en-US, zh-TW, zh-CN）字體與排版車載實景走查。

---

## 三、SAFE-01～SAFE-10 車載安全核心不變條件矩陣

| 編號 | 不變條件名稱 | 核心定義與規則 | 違規危害 | 代碼守衛切面 | 驗收測試方法 |
|:---|:---|:---|:---|:---|:---|
| **SAFE-01** | **嚴格唯讀性與控制面封鎖** | 車載 UI 絕對禁止發送清除故障碼 (Mode 04)、主動測試 (Mode 08) 或重設參數等寫入指令。 | 誤觸引發行車動力中斷或破壞排放系統證據。 | `:car-core` 嚴格 0 寫入通道；`CarDiagnosticsHostApi` 僅接收。 | 代碼審查 + AST 符號掃描確認無 OBD 寫入 API。 |
| **SAFE-02** | **倒車運動保守判定** | 任何來源回報 `rawSpeed < 0`、負車速或非零速度，明確且無條件判定為 `MOVING`。 | 倒車時誤判靜止，致使駕駛人分心操作 DTC 造成碰撞。 | `CarVehicleMotionResolver.kt`、`CarDtcMotionGate.kt`。 | `CarDtcMotionGateTest` 注入負速度驗證回傳 `MOVING`。 |
| **SAFE-03** | **停車限定雙重門禁** | 進入 DTC 摘要與詳情介面必須同時通過主機 `ParkedOnlyOnClickListener` 與應用 `CarDtcMotionGate.isStationary`。 | 繞過主機停駐狀態進入高分心介面。 | `CarHealthScreen.kt`、`CarDtcSummaryScreen.kt`。 | 單元測試模擬主機解除停駐與車速不為 0 時點擊無效。 |
| **SAFE-04** | **非同步延遲二次校驗** | DTC 結果回傳與 `onGetTemplate()` 渲染前，必須二次校驗即時車速；若已起步立即拋棄並退回安全首頁。 | 靜止時發起查詢，起步後才回傳結果，造成行駛中突然跳出故障碼。 | `CarDtcSummaryScreen.kt`、`CarDtcDetailScreen.kt`。 | 協程延遲測試：在結果回傳前注入運動信號，驗證自動退回。 |
| **SAFE-05** | **連線世代 Session 隔離** | 連線中斷、重連或 Session 重置（Epoch 變更或 `onProducerAttached`）時，舊准入憑證與舊診斷資料立即失效。 | 舊車故障碼殘留顯示在另一台車，或拿著過期憑證滯留子畫面。 | `CarDtcRepository.kt`、`CarSessionRuntime.kt`、`CarTelemetryRepository.kt`。 | 跨 Epoch 提交測試，驗證舊資料丟棄與畫面自動退出。 |
| **SAFE-06** | **動態起步即刻回彈** | 處於 DTC 相關畫面時持續監聽車速；一旦車輛移動，立即執行 `popTo(CAR_HEALTH_MARKER)`。 | 行駛中持續滯留於詳細檢修介面。 | `CarDtcSummaryScreen`、`CarDtcDetailScreen` 之運動流監聽。 | 模擬車速由 0 變更為 1 km/h，驗證立即觸發 `popTo`。 |
| **SAFE-07** | **駕駛分心語義客觀性** | 健康度絕不主觀宣稱「車況優良 (Safe to Drive)」，僅客觀判定 `No observed warnings`、`Attention`、`Unknown`。 | 給予駕駛人不實安全背書，忽視隱性機械故障。 | `CarHealthEvaluator.kt`。 | 邊界測試：僅在無故障、MIL 關閉且掃描完全時判定無警告。 |
| **SAFE-08** | **畫面刷新 1Hz 節流防閃爍** | 螢幕畫面刷新頻率上限嚴格鎖定於 ≤ 1Hz，重大安全告警相位轉移允許一次立即刷新。 | 高頻數值閃爍掠奪駕駛人眼球視線。 | `CarHealthScreen.kt` 節流閥。 | 時間步進測試：高頻注入訊號驗證 1 秒至多 1 次 `invalidate`。 |
| **SAFE-09** | **數值淨化與負零防禦** | 浮點數四捨五入後若為 `-0` 或 `-0.0`，必須強制消除負號，呈現為 `0 km/h`、`0 °C`。 | 儀表呈現 `-0 km/h` 造成駕駛人困惑與專業度質疑。 | `CarTextIsolation.kt`、各畫面格式化器。 | 注入 `-0.0`、`-0.4`，斷言格式化輸出嚴格無負號。 |
| **SAFE-10** | **主機容量防禦與截斷指示** | 遵守主機行數限制（4~6 列），資料超量時最後一列必須顯示「尚有 N 項未顯示」，禁止無聲丟棄。 | 隱藏重要故障碼，駕駛人誤以為無其他故障。 | `CarDtcSummaryScreen.resolveListLimit`。 | 注入 10 筆 DTC 於 6 列主機，斷言第 6 列為溢出提示。 |

---

## 四、代碼架構切面加固細節

### 4.1 倒車速度判定加固 (SAFE-02)
- **`CarVehicleMotionResolver`**：
  任何來源速度（OBD 速度、Host raw 速度、Host display 速度）若為有限數值且滿足 `it != 0.0 || it < 0.0`（排除 `-0.0`），一律判定為 `CarMotionEvidence.MOVING`。
- **`CarDtcMotionGate`**：
  消除非 CONNECTED 狀態下的 `||` 寬鬆判斷。必須所有有效來源嚴格為 0，且不得有任何負速度或正速度回報，方可給出 `STATIONARY`。
- **`CarTelemetryFrame.SPEED_KMH_ENVELOPE`**：
   envelope 允許負車速（如 `-100.0..400.0`），確保倒車遙測數據保留有限負值，使運動門禁精準辨識為 `MOVING`。

### 4.2 非同步延遲二次校驗與即刻回彈 (SAFE-04, SAFE-06)
- **非同步回調切面**：
  當 `dtcRepository.state` 發射新診斷數據時，必須再次檢驗 `CarDtcMotionGate.isStationary(...)`。若車輛已非靜止，立即拋棄結果並呼叫 `screenManager.popTo(CAR_HEALTH_MARKER)`。
- **模板渲染切面**：
  在 `CarDtcSummaryScreen.onGetTemplate()` 與 `CarDtcDetailScreen.onGetTemplate()` 進入點，實施即時運動檢驗。若非靜止狀態，立即發起 `popTo` 並回傳不可用模板降級，杜絕任何行駛中渲染故障碼之風險。

### 4.3 世代 Epoch 隔離與重置 (SAFE-05)
- **生命週期重置**：
  `CarSessionRuntime.stop()` 與 `destroy()` 必須同步呼叫 `dtcRepository.reset()`。
- **重連與生產者重置**：
  `CarTelemetryRepository.onProducerAttached()` 於生產者重新附著或連線重置時，聯動重設 `dtcRepository.reset()`。
- **畫面准入撤銷**：
  `CarDtcSummaryScreen` 與 `CarDtcDetailScreen` 偵測到 `matchingDtcReport(...) == null`（代表連線斷開或 Epoch 不匹配）時，主動呼叫 `screenManager.popTo(CAR_HEALTH_MARKER)`，徹底撤銷過期准入。

---

## 五、合規驗證門禁清單

所有程式碼變更與發布版本必須通過以下門禁：
1. `./android/gradlew -p android :car-core:testDebugUnitTest --rerun-tasks`：100% PASS（0 failures, 0 errors）。
2. `fvm flutter test`：100% PASS。
3. `python3 tool/ci/verify_car_manifest_isolation.py`：`carProto`、`fieldRelease`、`automotive` 隔離契約 100% PASS。
4. `bash tool/ci/verify_car_pigeon_codegen.sh`：Pigeon 生成契約 0 漂移。
5. `git diff origin/main -- lib/obd/`：嚴格 0 變更。
