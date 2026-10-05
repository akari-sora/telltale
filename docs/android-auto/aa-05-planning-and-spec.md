# Phase AA-05 規格藍圖：AAOS 原生車機系統整合、VHAL 感測器對接、即時通知橫幅與告警架構

狀態：APPROVED BY GPT-6 Pro  
基準 Commit：`afab093f4e1901d85409759c13f50353672031ae`（main HEAD）  
分支：`feat/aa-05-aaos-sensors-alerts`  
關聯規範：[AA-00 車載適格性與隔離契約](file:///Users/iml1s/Documents/mine/apps/auto/torque/docs/android-auto/aa-00-eligibility.md)、[AA-04 規劃與 DHU 走查指引](file:///Users/iml1s/Documents/mine/apps/auto/torque/docs/android-auto/aa-04-planning-and-dhu-walkthrough.md)

---

## 一、核心定位與設計原則

1. **API 糾偏與統一抽象 (CarInfo over CarSensors)**：
   - 車速**不在** `CarSensors`（`CarSensors` 僅包含加速度計、陀螺儀、指南針、位置，且在 AAOS 上會回傳 `STATUS_UNIMPLEMENTED`）。
   - 車速由 `CarHardwareManager.carInfo.addSpeedListener()` 提供（包含 `rawSpeedMetersPerSecond` 與 `displaySpeedMetersPerSecond`）。
   - Android Auto 與 AAOS 共用同一套 Car App Library 抽象（`androidx.car.app:app:1.7.0`），無需升級未穩定的 1.8.0 RC。

2. **資料架構與仲裁權威 (Independent Authority & Explicit Arbitration)**：
   - 保持 `CarTelemetryRepository` 語意純粹（專屬於 Flutter/OBD Pigeon producer），絕不污染寫入 VHAL 資料。
   - 新增平行權威 `CarHostSpeedRepository` 與仲裁器 `CarSpeedResolver`：
     - **顯示速度優先序**：
       1. OBD `010D` 車速且狀態為 LIVE → 採 OBD
       2. OBD 不可用或 Stale，且 Host `displaySpeed` 為 SUCCESS/LIVE → 採 `HOST_DISPLAY`
       3. Host `displaySpeed` 不可用，但 Host `rawSpeed` 為 SUCCESS/LIVE → 採 `HOST_RAW`
       4. 兩者皆無可靠資料 → 依契約呈現 `--` 或 `Stale`，**絕不虛構 0**。
     - **不做數值校準**：`displaySpeedMetersPerSecond` 為車廠儀表顯示值，本身預期略高於 raw speed，二者皆具客觀來源意義。
     - 保留來源枚舉 `CarSpeedSource { OBD, HOST_DISPLAY, HOST_RAW }` 以供測試與日誌記錄，但 UI 呈現不增添多餘文字，維護車載掃視性 (Glanceability)。

3. **行車運動安全門禁雙軌判定 (Motion Safety Conservative Fusion)**：
   - DTC safety gate 與顯示仲裁分離，採保守融合原則（Conservative Fusion）：
     - 任何 fresh 來源（OBD 或 Host raw/display）明確非零（包含倒車 `rawSpeed < 0`）→ `MOVING`。
     - 無任何來源回報 moving，且至少一個 fresh 來源為嚴格 0 → `STATIONARY`。
     - 無任何 fresh 速度證據 → `UNKNOWN`。
   - 車輛靜止與 DTC 進入門禁維持雙重檢核：主機 `ParkedOnlyOnClickListener` AND 輔助 `CarMotionEvidence.STATIONARY`。

4. **宿主速度狀態合約 (Host Speed State Contract)**：
   - `CarHostSpeedStatus`：`LIVE`, `STALE`, `UNAVAILABLE`, `UNIMPLEMENTED`, `PERMISSION_DENIED`。
   - `STATUS_SUCCESS` 且有限浮點數 → `LIVE`；其餘情況數值必須為 null。
   - 宿主速度新鮮度窗口（`maxAgeMs`）：預設 3,000ms（可注入）。

5. **Session 級生命週期作用域 (`CarSessionRuntime`)**：
   - 車載硬體監聽器與告警協調器置於 `TelltaleCarSession` 作用域，不隨 Screen 切換重複註冊或丟失狀態。
   - Screen 僅消費唯讀 StateFlow。
   - Car App API 門禁：當主機 API 等級 < 3 時，安全降級為 `UNIMPLEMENTED`，退回純 OBD 模式。

6. **葉端 Manifest 權限隔離 (Leaf Artifact Manifest Isolation)**：
   - `carProto`（Android Auto 投影）：宣告 `com.google.android.gms.permission.CAR_SPEED`。
   - `automotive`（AAOS 原生）：宣告 `android.car.permission.CAR_SPEED` 與 `android.car.permission.READ_CAR_DISPLAY_UNITS`。
   - `:car-core` 與生產 Flavor（`field`, `rig`, `wear`）：嚴格 0 車載權限宣告。

7. **車載 DDG 告警呈現架構 (In-Template Alert Surface)**：
   - 排除 `Alert` / `AppManager.showAlert()`（官方限定 `NavigationTemplate`）。
   - 排除 1.8 實驗性 `Banner` 與全系統 `HUN/Notification`。
   - 採用 **In-Template Alert Surface**：在既有 `CarHomeScreen` 與 `CarHealthScreen` 之特定行（如 Coolant 行）中標註警示文字（如 `108 °C · High`），維持固定 Row 數量與佈局。
   - 告警狀態轉移（`NORMAL -> ACTIVE`, `ACTIVE -> UNKNOWN_AFTER_WARNING`, `PENDING_CLEAR -> NORMAL`）可立即觸發一次 `invalidate()`，正常遙測保持 ≤ 1Hz 節流。
   - AA-05 不擴展未定標準之通用電壓告警，電壓維持純顯示。

8. **純 AAOS 原生範疇界定**：
   - 純 `:automotive` standalone artifact 原生提供車速來源；RPM、水溫、DTC 等 OBD 專屬欄位在無 OBD 連線時平穩降級為 `--` 或 `Unknown`，不製造虛假資訊。

---

## 二、AA05 驗收矩陣 (Acceptance Matrix)

| 編號 | 驗收條款 (Acceptance Criterion) |
|---|---|
| **AA05-01** | Car App Library 維持 exact `1.7.0`，不引進 1.8.0 RC。 |
| **AA05-02** | 車速透過 `CarInfo.addSpeedListener()` 取得，絕不使用 `CarSensors`。 |
| **AA05-03** | Car App API < 3 時安全降級為 `UNIMPLEMENTED`，退回純 OBD 運作。 |
| **AA05-04** | `carProto` 僅宣告 `com.google.android.gms.permission.CAR_SPEED`。 |
| **AA05-05** | `automotive` 宣告 `android.car.permission.CAR_SPEED` 與 `android.car.permission.READ_CAR_DISPLAY_UNITS`。 |
| **AA05-06** | `field`/`rig`/`wear` 保持 0 車載權限污染。 |
| **AA05-07** | 僅在 `STATUS_SUCCESS` 且數值為有限浮點數時判定為 `LIVE` speed。 |
| **AA05-08** | unavailable/unimplemented/denied 狀態永遠不產生虛假 `0 km/h`。 |
| **AA05-09** | OBD live speed 優先作為顯示來源。 |
| **AA05-10** | OBD unavailable/stale 時，若 Host display speed 可用則平滑 fallback。 |
| **AA05-11** | Host display speed 不可用時，才進一步 fallback 至 Host raw speed。 |
| **AA05-12** | 解析後之車速保留明確之來源枚舉（`CarSpeedSource`）。 |
| **AA05-13** | 不對 OBD 與 VHAL 車速進行人為強制校準。 |
| **AA05-14** | 宿主車速具備時效檢查契約（3,000ms），支援虛擬時鐘測試。 |
| **AA05-15** | 倒車 raw speed < 0 明確判定為 `MOVING`。 |
| **AA05-16** | 任一 fresh 來源非零即判定為 `MOVING`。 |
| **AA05-17** | 無任何 fresh 車速證據時判定為 `UNKNOWN`。 |
| **AA05-18** | DTC 檢視門禁仍必須同時滿足主機 `ParkedOnly` 與輔助 `STATIONARY`。 |
| **AA05-19** | `CarTelemetryRepository` 之架構、順序與 Stale 契約嚴格維持 0 修改。 |
| **AA05-20** | 既有 Pigeon 定義、代碼生成檔與二進制 Wire Golden 保持 byte-for-byte 0 diff。 |
| **AA05-21** | 車速監聽器由 Session 級 runtime 統一註冊與解註冊。 |
| **AA05-22** | 任何 Screen 均不直接持有 `CarHardware` 監聽器。 |
| **AA05-23** | 冷卻水溫 evaluator 移至 Session 級 `CarAlertCoordinator` 統一管理。 |
| **AA05-24** | 遙測 `connectionEpoch` 變更時立即重設告警狀態機。 |
| **AA05-25** | 訊號 stale 絕不把 active 高溫告警誤清除為 `NORMAL`（進入 `UNKNOWN_AFTER_WARNING`）。 |
| **AA05-26** | AA-05 不新增非標的通用電壓告警。 |
| **AA05-27** | 不使用 Navigation 專屬之 `Alert` / `AppManager.showAlert()`。 |
| **AA05-28** | 不使用 1.8 實驗性 `Banner` API。 |
| **AA05-29** | 不新增跨應用侵入性 Notification / HUN 路徑。 |
| **AA05-30** | 告警狀態 edge 轉移可立即觸發 invalidate，正常遙測刷新維持 ≤ 1Hz。 |
| **AA05-31** | `CarHomeScreen`、`CarHealthScreen`、`CarPowertrainScreen` 統一消費 `CarAlertRepository`。 |
| **AA05-32** | AAOS raw/display speed 在 emulator VHAL 變更下可實際更新。 |
| **AA05-33** | projected DHU speed 注入能正常觸發 host fallback。 |
| **AA05-34** | AAOS 原生產物不虛構已實作原生 RPM/Coolant/DTC。 |
| **AA05-35** | `lib/obd/**` 保持嚴格 0 變更。 |
| **AA05-36** | 生產 flavor（field）Manifest 保持嚴格 0 車載污染。 |
