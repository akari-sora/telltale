# AA-04 規劃與 DHU 實車機走查驗證指引

狀態：DRAFT / PROVISIONAL (AA-03 驗證合入後推進)  
關聯規範：[AA-00 車載適格性與隔離契約](file:///Users/iml1s/Documents/mine/apps/auto/torque/docs/android-auto/aa-00-eligibility.md)

---

## 第一部分：AA-03 DHU 實車機走查操作指南 (Desktop Head Unit Walkthrough)

### 1. 走查環境拓撲與前置條件
- **測試手機**：已連接之實體 Android 裝置（如 Samsung Galaxy S24 Ultra `SM-S9280` 或 Galaxy S21+ `SM-G9960`）。
- **車載模擬主機**：MacBook 本地 Google Desktop Head Unit (`/Users/iml1s/Library/Android/sdk/extras/google/auto/desktop-head-unit`)，版本 2.0-mac-arm64。
- **目標安裝包**：`app-carProto-debug.apk`（ApplicationId: `com.cbstudio.telltale.carproto`）。

### 2. 連線與啟動步驟
1. **安裝車載原型 APK**：
   ```bash
   adb -s R5CX10VFFBA install -r build/app/outputs/apk/carProto/debug/app-carProto-debug.apk
   ```
2. **手機端開啟 Android Auto Head Unit Server**：
   - 進入手機「設定」→「進階功能」→「Android Auto」或直接搜尋 Android Auto 設定。
   - 連續點擊「版本資訊」10 次開啟開發人員模式。
   - 點擊右上角三點選單，選取「啟動總機伺服器 (Start Head Unit Server)」。
3. **ADB 端口轉發**：
   ```bash
   adb -s R5CX10VFFBA forward tcp:5277 tcp:5277
   ```
4. **啟動 DHU 模擬器**：
   ```bash
   /Users/iml1s/Library/Android/sdk/extras/google/auto/desktop-head-unit
   ```

### 3. AA-03 核心驗收場景檢核清單 (Walkthrough Checklist)
- [ ] **場景 1：車速與信號刷新頻率限制（1Hz Cadence Gating）**
  - **驗收條件**：車輛遙測訊號在畫面刷新時，UI 畫面刷新頻率上限嚴格鎖定於 1 秒 1 次（1Hz），絕無高頻閃爍或造成駕駛人視覺干擾。
- [ ] **場景 2：負零數值清理（Negative Zero Sanitization）**
  - **驗收條件**：當感測器傳入 `-0.0` 或零下微小浮點數（例如冷卻水溫 `-0.4°C` 經取整四捨五入）時，儀表顯示必須為 `0 °C`、`0 km/h`、`0 RPM`、`0.0 V`，絕對不得出現 `-0` 或 `-0.0`。
- [ ] **場景 3：Stale 歷史幀降級契約（Refined Stale Contract）**
  - **驗收條件**：
    - 連線中斷但曾有歷史幀時：各列顯示既有讀數並附帶「逾時 (Stale)」標籤。
    - 連線中斷且從未收到有效幀時：各列顯示 `--`（無資料），不虛構過期狀態。
- [ ] **場景 4：主機容量限制防禦（Host Content Limit Defense）**
  - **驗收條件**：
    - 當 DHU 主機配置 Pane 限制為 4 列時，僅顯示前 4 列關鍵行車信號。
    - 當 DHU 主機配置限制為 1 列時，自動收斂至單列（車速）。
    - 即使 ContentLimit Provider 發生例外，畫面平穩降級至預設 4 列，不發生 Crash。
- [ ] **場景 5：駕駛分心安全（Driver Distraction Safety）**
  - **驗收條件**：儀表為純檢視 PaneTemplate，無任何點擊、切換、編輯按鈕，不干擾駕駛行為。

---

## 第二部分：Phase AA-04 實作與架構 (Health / Powertrain / Parked DTC)

### 1. 核心定位與設計原則
- **階段目標**：在車載螢幕上提供車況健康度（`CarHealthScreen`）、動力概覽（`CarPowertrainScreen`）與靜止故障診斷碼檢視（`CarDtcSummaryScreen`, `CarDtcDetailScreen`），滿足車主行車前後對車輛健康狀況之掌握需求。
- **嚴格不變量 (Strict Invariants)**：
  1. **絕對唯讀 (Strictly Read-Only)**：僅提供車載 DTC 與健康度資訊展示，**絕對禁止**在車載介面提供「清除故障碼 (Clear DTC)」、「主動測試 (Active Test)」、「適應值重設 (Adaptation Reset)」等任何反向控制指令。
  2. **停車狀態雙重門禁 (Parked-Only Navigation & Auto-Pop Motion Gate)**：
     - **行駛中 (Moving / In-Drive)**：僅允許顯示車況健康概覽（`CarHealthScreen`）與動力數據（`CarPowertrainScreen`）；DTC 按鈕包覆 `ParkedOnlyOnClickListener`。
     - **停車中 (Stationary, 0 km/h)**：允許進入檢視詳細故障碼清單與凍結幀。
     - **動態退回保護**：若在檢視 DTC 清單或凍結幀期間車輛開始移動，`CarDtcSummaryScreen` 與 `CarDtcDetailScreen` 立即主動退回（`popTo(CarHealthScreen.CAR_HEALTH_MARKER)`）。
  3. **駕駛安全嚴謹語義 (No Observed Warnings Contract)**：
     - 車況健康評級絕不虛構「車況健康」或「安全可行駛」；僅依據客觀觀測結果評估為「無已知警告 (No observed warnings)」、「注意 (Attention)」、「未知 (Unknown)」。
     - 只有在遙測連線正常、DTC 掃描完整完成（`coverageComplete == true`）、`verdict == COMPLETE_CLEAN`、MIL 燈熄滅、`totalCodes == 0L` 且 DTC 清單為空時，才判定為 `No observed warnings`。
  4. **告警遲滯防抖 (Alert Hysteresis Engine)**：
     - 實作雙閾值與保持時間防抖狀態機（`CarAlertEvaluator`），高溫警報進入需連續超過閾值 3 秒，解除需連續低於閾值 10 秒。
     - 遙測 `connectionEpoch` 變更（換車或重新連線）時立即重設遲滯狀態機，避免舊車高溫警報延續至新車。
  5. **獨立 Diagnostics Bridge 與跨語言 Wire Contract**：
     - 獨立於遙測橋接，建立專屬 `pigeons/car_diagnostics.dart`（`CarDiagnosticsHostApi`），事件驅動單向傳遞。
     - 建立真實雙向 Wire Contract 測試（`CarDiagnosticsWireContractTest`），以固定 `.hex` 檔案驗證 Dart Pigeon 位元組與 Kotlin 解碼一致性，包含 64 位元整數（> 2^32）、nullable MIL、凍結幀與信號列舉。
  6. **主機清單容量限制防禦與截斷提示 (Host Content Limit Compliance)**：
     - 超過 host list limit 時不無聲截斷，保留最後一列提示「尚有 N 項診斷碼未顯示」或「凍結幀訊號未完整顯示」。
  7. **架構無污染 (0 Diff in lib/obd/)**：
     - `lib/obd/` 保持嚴格 0 變更；生產 Flavor（`field`, `rig`, `wear`）Manifest 與原始碼零車載污染隔離。

### 2. 資料模型與 Pigeon 介面 (`pigeons/car_diagnostics.dart`)
```dart
class CarDtcReportMessage {
  final int schemaVersion;
  final int reportSequence;
  final int connectionEpoch;
  final CarDtcScanPhaseMessage phase;
  final CarDtcVerdictMessage verdict;
  final bool coverageComplete;
  final bool? milOn;
  final int? totalCodes;
  final bool freezeFrameReadIncomplete;
  final List<CarDtcItemMessage> items;
  final List<CarFreezeFrameMessage> freezeFrames;
}
```

### 3. 車機端 Screen 架構
- **CarHealthScreen (`android/car-core`)**：
  - 統一透過 `matchingDtcReport(telemetryState, dtcState)` 確保遙測與診斷之 `connectionEpoch` 隔離一致性。
  - 呈報 `Observed Status`、`MIL`、`Fault Codes`、`Coolant`、`Module Voltage`。
  - 提供前往 `CarPowertrainScreen` 與 `CarDtcSummaryScreen`（ParkedOnly）之動作按鈕。
- **CarPowertrainScreen (`android/car-core`)**：
  - 駕駛安全的動力即時概覽：RPM、Coolant、Intake Air、MAP、Voltage、Speed。
- **CarDtcSummaryScreen (`android/car-core`)**：
  - Verdict-aware 狀態呈現：COMPLETE_CLEAN 顯示「無觀測到的診斷碼」，NOT_SCANNED、SCANNING、PARTIAL_CLEAN、FAILED 呈現精準對應狀態。
  - 超出 host limit 時顯示剩餘數量。
- **CarDtcDetailScreen (`android/car-core`)**：
  - 凍結幀比對嚴格依據 `causeCode`、`causeKind`、`causeSourceId`。
  - 呈現凍結幀數值，並對不完整、未讀取或被截斷之訊號顯示摘要行提示。

### 4. 驗證體系與門禁設計
- **全方位自動化驗證**：
  - Dart 單元測試（`test/car/`）：64/64 全綠。
  - Kotlin 單元測試（`testDebugUnitTest`, `testCarProtoDebugUnitTest`）：全綠。
  - 跨語言 Wire Contract 雙向二進制校驗：全綠。
  - 隔離門禁（`verify_car_manifest_isolation.py`）：全綠。
  - Pigeon 代碼生成飄移檢核（`verify_car_pigeon_codegen.sh`）：0 drift。
  - 隱私收據審計（`validate_privacy_contract.py`）：0 errors。

