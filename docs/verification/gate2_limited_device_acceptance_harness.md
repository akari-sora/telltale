# Gate 2 限定裝置驗收測試線束與驗證規範
## Limited Device Acceptance Test Harness: D02, D05, D08

- **專案名稱**: Telltale (ImL1s/telltale)
- **版本階段**: Milestone M2-C (Gate 2 Candidate Verification)
- **基準版本**: Commit `1ad08253e86ec6a6aef2b706cd0b6729372da3b3`
- **文件路徑**: `docs/verification/gate2_limited_device_acceptance_harness.md`
- **建立日期**: 2026-09-18
- **責任角色**: teamwork_preview_worker_m2c_1

---

## 1. 執行綱要與安全範疇指引 (Executive Summary & Safety Guardrails)

### 1.1 目的與驗收標的
本測試線束規範為 Telltale Gate 2 候選版本（版本號 `1.0.14`，Build `15`）在限定裝置環境（Limited Device Bench）下的驗收測試執行綱領。涵蓋三個核心關鍵維度：
1. **D02 (Headered Negotiation & Graceful Refusal Fallback)**: 標頭協商機制、明確拒絕後備容錯、配接器錯誤防遮蔽與黏性不確定性阻擋。
2. **D05 (Lifecycle Resilience & Event Matching)**: 三重生命週期切換（HOME / 螢幕關閉 / HOME）、查詢暫停排空、3 秒 `ATRV` 恢復驗證與 1:1 截圖雜湊綁定。
3. **D08 (Bilingual UI & Protocol Integrity)**: 英文與繁體中文介面語意對稱性、結構化診斷狀態解析、以及原始協定標記（Raw Protocol Markers）的不變性保護。

### 1.2 零實車候選人 (Zero Live Candidates) 絕對約束
- **嚴格禁止擴展至 Gate 3**: 本驗收規範僅限於實驗室模擬器、偽裝配接器（FakeElm327）、本地回環測試儀（Mode 08 Replay Oracle Rig）及未連接車輛實體的隔離台架。
- **嚴格禁止實車連線**: 嚴禁將測試裝置連接至任何真實車輛的 OBD-II / CAN 匯流排介面。
- **嚴格禁止重啟 Gate 1**: Gate 1 之基線與存檔已驗收通過，本測試線束不得重新執行或變更 Gate 1 之驗收邊界。
- **UI 實車防護徽章**: Workshop 介面中的所有配方與診斷卡片必須恆常顯示 `serviceRecipesLiveBlockedBadge`（「禁止實車（0 實車候選）」/「Live Blocked (0 Live Candidates)」）。

---

## 2. D02: 標頭協商與優雅拒絕後備測試規範 (Headered Negotiation & Graceful Refusal Fallback)

### 2.1 協定狀態機與程式碼追蹤架構

D02 測試情境直接對齊並驗證下列原始碼模組之行為：

1. **`lib/obd/elm327_client.dart`**:
   - `_applyRenderingState(normalised, response)` (L1587-L1643):
     - 當發送 `ATH1` 且配接器返回 `OK` 時，設置 `_headersOn = true` 且 `_responseHeadersUncertain = false`。
     - 當收到明確拒絕 `?` (`_saidRefused(response)`) 時，**保留先前已知之 `_headersOn` 狀態**，嚴禁翻轉為相反狀態，亦不清除已存在的 `_responseHeadersUncertain`。
     - 當收到既非 `OK` 亦非乾淨拒絕的異常回應時，將 `_responseHeadersUncertain` 標記為 `true`。
     - 針對 `ATH0` 具備對稱保留邏輯。
   - `_saidRefused(ObdResponse r)` (L2030-L2034):
     - 優先調用 `_hasAdapterError(r)`。若回應包含任何配接器錯誤代碼或錯誤字串，立即返回 `false`，嚴防將傳輸故障降級為乾淨拒絕。
     - 僅在無配接器錯誤且回應包含 `?` 或未知指令代碼時返回 `true`。
   - `_hasAdapterError(ObdResponse r)` (L2011-L2025):
     - 檢查 `r.errorCode != Elm327ErrorCode.none && r.errorCode != Elm327ErrorCode.unknownCommand`。
     - 遍歷 `r.rawLines` 檢查是否匹配 `_errorStrings` (`DATA ERROR`, `BUFFER FULL`, `CAN ERROR`, `BUS ERROR`, `BUS BUSY`, `FB ERROR`, `LV RESET`, `RX ERROR`, `STOPPED`, `NO DATA`, `ACT ALERT`, `LP ALERT`)、`BUS INIT ... ERROR` 及 `ERR\d{2}`。
   - `runTransacted` / `sendTransacted` (L2800-L3200):
     - 在事務執行期請求 `responseHeaders: true` 時發送 `ATH1`。
     - 若 `ATH1` 遭遇乾淨拒絕 (`_saidRefused`)，將 `headersTurnedOn` 設為 `false`，優雅降級為無標頭（匿名）查詢，不中斷事務執行。
     - 若 `ATH1` 遭遇配接器錯誤，則標記 `_responseHeadersUncertain = true` 並拋出 `TransportException`。
   - `_verifyReadyToSend()` (L1740-L1763):
     - 檢查 `if (_responseHeadersRestoreFailed || _responseHeadersUncertain)`。
     - 一旦處於不確定狀態，立即阻斷後續任何查詢發送，達成線路零寫入（Wire-Zero Rejection）。

2. **`lib/diagnostics/service_recipes/mode08_discovery_service.dart`**:
   - `Mode08DiscoveryService.discoverSupportedTids` (L150-L795):
     - 透過 `client.sendTransacted(..., responseHeaders: true)` 執行非致動 TID 查詢。
     - 若配接器拒絕 `ATH1`，回應將失去標頭歸因 (`hadAnonymousResponses = true`)。
     - 跨區塊限制檢測：若 `hadAnonymousResponses && queriedBlocks.length > 1`，由於無標頭無法證明不同區塊來自同一實體 ECU，標記 `isComplete = false`，中斷原因為 `Mode08IncompletionReason.unheaderedCrossBlockLimitation`。

3. **`lib/ui/screens/workshop/service_recipes_screen.dart`**:
   - `resolveMode08IncompletionText` (L600-L654):
     - 針對 `Mode08IncompletionReason.unheaderedCrossBlockLimitation`，解析為 `l10n.mode08ReasonUnheaderedLimitation`。
   - `_buildCompletedResult` (L240-L290):
     - 渲染 `Key('mode08_discovery_partial_warning')` 容器，以警告色彩（Warning Palette）向使用者揭露來源歸因限制與未完成區塊。

---

### 2.2 測試情境 1 (D02-TC01): 協商成功之多 ECU 標頭歸因 (Negotiated ATH1 Multi-ECU Attribution)

#### 測試目標
驗證在支援標頭的 CAN 匯流排配接器上，`ATH1` 協商成功後，多個 ECU 節點（例如 ECM `7E8` 與 TCM `7E9`）的回應能被正確分離並歸因。

#### 前置條件
- 配接器就緒，初始狀態為 `H0` (`headersOn == false`)。
- 測試線束模擬節點 `7E0` (ECM, 回應 ID `7E8`) 及 `7E1` (TCM, 回應 ID `7E9`)。

#### 輸入與互動時序 (Frame Sequence)
```text
[Tester -> Adapter]: ATH1\r
[Adapter -> Tester]: OK\r\r>
[Tester -> Adapter]: ATSH7DF\r
[Adapter -> Tester]: OK\r\r>
[Tester -> Adapter]: 0800\r
[Adapter -> Tester]: 7E8 06 48 00 00 00 00 01 \r7E9 06 48 00 00 00 00 02 \r\r>
[Tester -> Adapter]: ATH0\r
[Adapter -> Tester]: OK\r\r>
```

#### 狀態轉換矩陣
| 階段 | 內部狀態 (`_headersOn`) | 不確定性標誌 (`_responseHeadersUncertain`) | 歸因狀態 (`ecuResults`) | 完整性 (`isComplete`) |
| :--- | :--- | :--- | :--- | :--- |
| 初始 | `false` | `false` | `{}` | `true` |
| `ATH1` 成功後 | `true` | `false` | `{}` | `true` |
| 資料解析後 | `true` | `false` | `{'7E8': Success(TID $01), '7E9': Success(TID $02)}` | `true` |
| `ATH0` 復原後 | `false` | `false` | 保留解析歸因 | `true` |

#### UI 斷言 (UI Assertions)
- `find.byKey(const Key('mode08_discovery_success_container'))` 為 `findsOneWidget`。
- `find.byKey(const Key('mode08_discovery_partial_warning'))` 為 `findsNothing`。
- 介面正確渲染支援之 TID Chips：`$01`, `$02`。

---

### 2.3 測試情境 2 (D02-TC02): 明確拒絕後備與 UI 限制警示 (Explicit ATH1 Refusal & Anonymous Fallback)

#### 測試目標
驗證當配接器明確拒絕 `ATH1`（回應 `?`）時，系統保留 `H0` 狀態，優雅後備至匿名解析；當跨區塊查詢（如查詢 `0x00` 後接續查詢 `0x20`）時，正確觸發 `unheaderedCrossBlockLimitation` 並在 UI 顯示警示。

#### 前置條件
- 配接器設定為拒絕標頭指令（`refuseHeaders: true`）。
- 初始狀態為 `H0`。

#### 輸入與互動時序 (Frame Sequence)
```text
[Tester -> Adapter]: ATH1\r
[Adapter -> Tester]: ?\r\r>
[Tester -> Adapter]: ATSH7E0\r
[Adapter -> Tester]: OK\r\r>
[Tester -> Adapter]: 0800\r
[Adapter -> Tester]: 48 00 00 00 00 01 \r\r>
[Tester -> Adapter]: 0820\r
[Adapter -> Tester]: 48 20 00 00 00 02 \r\r>
```

#### 狀態轉換矩陣
| 階段 | 內部狀態 (`_headersOn`) | 不確定性標誌 (`_responseHeadersUncertain`) | 匿名標誌 (`hasAnonymous`) | 中斷原因 (`incompletionReason`) |
| :--- | :--- | :--- | :--- | :--- |
| `ATH1` 收到 `?` | **`false` (保留，不反轉)** | **`false` (無黏性失敗)** | `false` | `none` |
| 區塊 `0x00` 完成 | `false` | `false` | `true` | `none` |
| 區塊 `0x20` 完成 | `false` | `false` | `true` | `unheaderedCrossBlockLimitation` |

#### UI 斷言 (UI Assertions)
- `find.byKey(const Key('mode08_discovery_partial_warning'))` 為 `findsOneWidget`。
- 警告內容包含：
  - 繁中：`來源歸因與覆蓋完整度未確認：無標頭回應無法建立跨區塊 ECU 身分`。
  - 附註說明：`未查到不代表不支援`。
- `find.byKey(const Key('mode08_discovery_success_container'))` 仍顯示已探測之 TID（容錯保留可用資訊）。

---

### 2.4 測試情境 3 (D02-TC03): 配接器錯誤防遮蔽與線路零寫入 (Adapter Error Non-Masking & Wire-Zero Rejection)

#### 測試目標
驗證當 `ATH1` 回應中混雜配接器損壞/傳輸錯誤字串（例如 `DATA ERROR\r?` 或 `BUFFER FULL\r?`）時，系統嚴禁將其誤判為乾淨拒絕，必須將狀態鎖定為黏性不確定（Sticky Uncertainty），並對後續指令實施線路零寫入阻擋。

#### 輸入與互動時序 (Frame Sequence)
```text
[Tester -> Adapter]: ATH1\r
[Adapter -> Tester]: DATA ERROR\r?\r\r>
[Tester -> Adapter]: (事務終止，嚴禁發送後續 ATSH 或 0800)
[Follow-up Query Attempt]: client.send('010C')
[Physical Wire]: (0 bytes transmitted / 無任何位元組送出)
```

#### 狀態轉換與保護矩陣
| 步驟 | 配接器回傳幀 | `_saidRefused` 分類結果 | `_responseHeadersUncertain` | 後續查詢行為 |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `DATA ERROR\r?` | `false` (嚴防遮蔽) | `true` (黏性不確定) | 事務拋出 `TransportException` |
| 2 | 後續發送 `010C` | N/A | `true` (保持鎖定) | **Wire-Zero Rejection** (直接拋出例外，0 位元組上線) |

#### 斷言與驗收標準
- `_saidRefused(ObdResponse(['DATA ERROR', '?']))` 必須精確斷言為 `false`。
- `client.responseHeadersUncertain` 斷言為 `true`。
- 驗證後續發送 `send('010C')` 拋出 `TransportIssue.headerRestoreFailed`。
- 配接器物理通訊日誌中，在 `ATH1` 之後指令計數嚴格維持為 0（無任何外送指令）。

---

### 2.5 D02 驗收查核表 (D02 Acceptance Checklist)
- [ ] **D02-CHK-01**: `_applyRenderingState` 在 `ATH1` 收到 `?` 時，保持 `_headersOn == false`，未發生倒轉。
- [ ] **D02-CHK-02**: `_applyRenderingState` 在 `ATH0` 收到 `?` 時，保持 `_headersOn == true`，未發生倒轉。
- [ ] **D02-CHK-03**: `_saidRefused` 針對包含 `DATA ERROR`、`BUFFER FULL`、`CAN ERROR` 等字串之回應，一律返回 `false`。
- [ ] **D02-CHK-04**: 損壞控制回應觸發黏性不確定性，後續查詢達成線路零寫入（Wire-Zero Rejection）。
- [ ] **D02-CHK-05**: 無標頭跨區塊查詢於 UI 精確渲染 `mode08_discovery_partial_warning` 容器與在地化免責宣告。

---

## 3. D05: 生命週期韌性與事件映射測試規範 (Lifecycle Resilience & Event Matching)

### 3.1 生命週期狀態機與程式碼追蹤架構

D05 驗證應用程式在 Android 作業系統層級的多重前背景切換下，OBD-II 通訊工作階段的停等、排空、防殘留及恢復機制：

1. **`lib/app.dart`**:
   - `_TorqueAppState` (with `WidgetsBindingObserver`):
     - 管理根層級生命週期監聽器 `_lifecycleListener = AppLifecycleListener(onResume: _onResume)`。
     - 在 `_onResume` 觸發啟動重試與語系同步。

2. **`lib/state/obd_session.dart`**:
   - `_lifecycle` (L379-L383):
     - 綁定 `onHide: _onAppPaused`, `onPause: _onAppPaused`, `onResume: () => unawaited(_onAppResumed())`。
   - `_onAppPaused()` (L480-L518):
     - 冪等性防護：`if (!_foreground && !_awaitingResumeValidation) return;`
     - 記錄 Transcript 註記：`_client?.transcript.recordNote('App 進入背景')`。
     - 立即持久化快照：`unawaited(_saveTranscriptSnapshot())`。
     - 單調暫停計數遞增：`_pauseEpoch++`。
     - 安全撤銷：撤銷實驗性探針許可證（`revokeAll()`）。
     - 廣播前景狀態：`_foregroundChanges.add(false)`。
     - 配接器守門犬掛起：`_client?.suspendLiveness()`，防範背景休眠引發錯誤超時。
     - 輪詢引擎優雅停等：`_lifecycleChain = _lifecycleChain.then((_) => _pauseNow(engine))`。
     - 在 `_pauseNow` 中：執行 `await engine.stop()`，隨後發送空快照 `TelemetrySnapshot()`，徹底清空儀表數據，嚴防殘留過期數值以高不透明度顯示。
   - `_onAppResumed()` (L545-L568):
     - 記錄 Transcript 註記：`_client?.transcript.recordNote('App 回到前景')`。
     - 標記存活：`_client?.markAlive()`。
     - 保持安全閥門關閉：`_awaitingResumeValidation = true`。
     - 串接排程恢復鏈：`_lifecycleChain = _lifecycleChain.then((_) => _resumeNow())`。
   - `_resumeNow()` (L570-L640):
     - 3 秒 `ATRV` 探針發送：`final probe = await client.send('ATRV', timeout: const Duration(seconds: 3))`。
     - 若 `ATRV` 逾時或失敗：觸發 `_handleConnectionLost`，安全關閉工作階段，防範接線脫落或更換車輛時讀取錯誤數據。
     - 若探針成功且期間未再次進入背景：`_openForegroundAfterResumeValidation()`，將 `_pausedByLifecycle` 歸零，並重新啟動輪詢引擎 `engine.start()`。
     - 若中斷前能力探索未完成：自動恢復 `discoverSupportedPids()` 與 `discoverResponders()`。

---

### 3.2 三重生命週期執行協定 (Triple HOME / Screen-Off / HOME Lifecycle Protocol)

本協定規範限定實體裝置或模擬器執行「三重中斷序列」，確保系統經歷多種背景切換途徑皆能維持無縫韌性：

```text
[初始基準] 前景輪詢中 (Live Gauges Active)
   │
   ▼ [中斷 1] 按下 HOME 鍵 (KEYCODE_HOME)
[背景狀態 1] 引擎停等、發送空快照、_pauseEpoch = 1
   │
   ▼ [恢復 1] 點擊圖示返回前景
[前景驗證 1] 發送 3s ATRV 探針、連線重驗證、重啟輪詢
   │
   ▼ [中斷 2] 關閉螢幕 (KEYCODE_POWER)
[背景狀態 2] 螢幕熄滅、掛起守門犬、_pauseEpoch = 2
   │
   ▼ [恢復 2] 開啟螢幕並解鎖
[前景驗證 2] 發送 3s ATRV 探針、連線重驗證、重啟輪詢
   │
   ▼ [中斷 3] 再次按下 HOME 鍵 (KEYCODE_HOME)
[背景狀態 3] 引擎停等、_pauseEpoch = 3
   │
   ▼ [恢復 3] 點擊圖示返回前景
[最終就緒] 最終 ATRV 驗證通過、完整恢復輪詢
```

#### 詳細執行步驟與 ADB 驅動指令
1. **階段 1 (基準啟動)**:
   - 啟動 Telltale，連線至 Demo/模擬器 CAN 輪詢，確認即時儀表更新（速度、轉速有動態數值）。
2. **階段 2 (中斷 1 - HOME 鍵)**:
   - 執行: `adb shell input keyevent KEYCODE_HOME`。
   - 等待 500ms，確認 Activity 進入 `onPause` / `onStop`。
3. **階段 3 (恢復 1 - 點擊返回)**:
   - 執行: `adb shell monkey -p com.cbstudio.telltale 1`。
   - 等待 1500ms，等待 `ATRV` 探針完成並恢復輪詢。
4. **階段 4 (中斷 2 - 螢幕關閉)**:
   - 執行: `adb shell input keyevent KEYCODE_POWER`。
   - 等待 1000ms，確認裝置處於休眠鎖定狀態。
5. **階段 5 (恢復 2 - 螢幕開啟與解鎖)**:
   - 執行: `adb shell input keyevent KEYCODE_WAKEUP`。
   - 執行: `adb shell wm dismiss-keyguard`。
   - 等待 1500ms，確認恢復前景與探針驗證。
6. **階段 6 (中斷 3 - 第二次 HOME 鍵)**:
   - 執行: `adb shell input keyevent KEYCODE_HOME`。
   - 等待 500ms。
7. **階段 7 (恢復 3 - 最終返回)**:
   - 執行: `adb shell monkey -p com.cbstudio.telltale 1`。
   - 等待 2000ms，驗證輪詢穩定度。

---

### 3.3 查詢隊列暫停與排空時序 (Query Hold & Queue Drain Timeline)

```text
時間點 (t)     動作事件                                系統內部處理
t = 0.0s      使用者觸發 HOME 鍵                     Android 發送 onPause()
t = 0.01s     _onAppPaused() 觸發                   _foreground = false; _pauseEpoch++ (同步完成)
t = 0.02s     _saveTranscriptSnapshot()              異步寫入硬碟快照
t = 0.05s     engine.stop() 排空進行中查詢           等待當前在途 OBD 請求完畢，不再派發新請求
t = 0.15s     發送 TelemetrySnapshot() 空快照        清空 UI 數據，儀表反灰/歸零，拒絕過期讀數
t = 2.0s      使用者點擊回到前景                     Android 發送 onResume()
t = 2.01s     _onAppResumed() 觸發                  _awaitingResumeValidation = true (安全閥門閉鎖)
t = 2.02s     排程 _resumeNow()                      掛載於 _lifecycleChain 佇列
t = 2.05s     發送 ATRV 探針 (超時 3s)               [Tx]: ATRV\r -> [Rx]: 14.1V\r\r>
t = 2.20s     ATRV 回應成功                         _openForegroundAfterResumeValidation()
t = 2.21s     重啟輪詢                              engine.start(); 恢復正常資料流派發
```

---

### 3.4 Android OS 與 Flutter 事件日誌擷取格式 (Event Logging Specification)

#### 日誌擷取指令
```bash
adb logcat -v time -s flutter:V ActivityTaskManager:I WindowManager:I | tee lifecycle_events.log
```

#### 預期標準事件日誌特徵範例
```text
09-18 11:20:10.102 I/ActivityTaskManager: Moving to PAUSED: ActivityRecord{... com.cbstudio.telltale/.MainActivity}
09-18 11:20:10.115 I/flutter: [OBD_SESSION] App 進入背景, epoch: 1
09-18 11:20:10.220 I/flutter: [POLLER] Polling loop stopped cleanly.
09-18 11:20:12.450 I/ActivityTaskManager: Moving to RESUMED: ActivityRecord{... com.cbstudio.telltale/.MainActivity}
09-18 11:20:12.460 I/flutter: [OBD_SESSION] App 回到前景, awaitingResumeValidation: true
09-18 11:20:12.465 I/flutter: [ELM_TX] > ATRV
09-18 11:20:12.510 I/flutter: [ELM_RX] < 14.1V
09-18 11:20:12.512 I/flutter: [OBD_SESSION] Link revalidation succeeded, restarting poller.
09-18 11:20:12.520 I/flutter: [POLLER] Polling loop started.
```

---

### 3.5 螢幕截圖 1:1 雜湊綁定協定 (Screenshot-to-Hash Protocol)

為確保生命週期每一步驟均有不可篡改的證據溯源，採用 1:1 截圖擷取與 SHA-256 指紋固化：

#### 截圖擷取指令
```bash
adb exec-out screencap -p > screenshot_stage_<ID>.png
shasum -a 256 screenshot_stage_<ID>.png
```

#### 生命週期階段與截圖指紋對照表 (範例範本)
| 階段 ID | 執行動作說明 | 預期 UI 視覺特徵 | 截圖檔案名稱 | 關聯事件特徵 |
| :--- | :--- | :--- | :--- | :--- |
| `D05-SS01` | 基準前景即時輪詢 | 儀表板顯示高亮即時讀數，狀態標記「批次讀取」 | `d05_01_baseline_live.png` | `POLLER started` |
| `D05-SS02` | 中斷 1 (HOME) 後返回瞬間 | 儀表板清空或顯示連線探針驗證中（非過期亮起） | `d05_02_resume1_probe.png` | `ATRV probe in-flight` |
| `D05-SS03` | 恢復 1 (HOME 恢復完成) | 儀表板重新點亮，恢復即時數值 | `d05_03_resume1_active.png` | `Link revalidation succeeded` |
| `D05-SS04` | 中斷 2 (螢幕關閉後喚醒) | 畫面解鎖後進入前景，安全閥門閉鎖驗證 | `d05_04_resume2_unlock.png` | `WAKEUP / dismiss-keyguard` |
| `D05-SS05` | 恢復 2 (螢幕解鎖恢復完成) | 數值穩定更新，無跳變或錯誤代碼 | `d05_05_resume2_active.png` | `epoch: 2, loop active` |
| `D05-SS06` | 恢復 3 (三次循環完全結束) | 系統累積 3 次暫停紀元，無記憶體洩漏與凍結 | `d05_06_resume3_final.png` | `epoch: 3, stable` |

---

### 3.6 D05 驗收查核表 (D05 Acceptance Checklist)
- [ ] **D05-CHK-01**: 三重中斷序列（HOME -> 返回 -> 鎖屏 -> 解鎖 -> HOME -> 返回）順暢完成，無 App 崩潰或 ANR。
- [ ] **D05-CHK-02**: 每次進入背景均觸發 `_onAppPaused`，單調暫停計數器 `_pauseEpoch` 精確遞增至 3。
- [ ] **D05-CHK-03**: 進入背景時輪詢迴圈乾淨排空，且 UI 接收空快照，未發生過期讀數滯留。
- [ ] **D05-CHK-04**: 回到前景時精確發送超時 3 秒之 `ATRV` 探針，在探針成功前安全閥門保持關閉。
- [ ] **D05-CHK-05**: 6 個關鍵截圖檔案之 SHA-256 指紋與 ADB logcat 事件日誌具備 1:1 時間戳記嚴格對齊。

---

## 4. D08: 雙語 UI 與協定完整性審查規範 (Bilingual UI & Protocol Integrity)

### 4.1 雙語對照與語意完整性架構

D08 確保 Telltale 在多語系環境下的嚴謹度與協定專業性。重點審查：
1. 英文 (`lib/l10n/app_en.arb`) 與繁體中文 (`lib/l10n/app_zh_Hant.arb`) 在所有診斷狀態與配方畫面的語意一致性。
2. 原始協定標記（Raw Protocol Markers）的絕對保留：協定關鍵字、位址、十六進位代碼與配接器標準輸出嚴格禁止翻譯。

---

### 4.2 雙語完整對照矩陣 (Bilingual Parity Matrix)

#### 4.2.1 服務配方與探索核心字串
| 資源識別碼 (ARB Key) | 英文內容 (English `app_en.arb`) | 繁體中文內容 (Traditional Chinese `app_zh_Hant.arb`) | 語意完整性核驗 |
| :--- | :--- | :--- | :--- |
| `serviceRecipesDiscoverySection` | Mode 08 Non-Actuating Capability Discovery | Mode 08 非致動能力探索 | 一致（強調非致動安全原則） |
| `serviceRecipesDiscoveryDescription` | Queries standard base TIDs ($00, $20, etc.) over CAN only. Never sends actuation test commands. | 僅透過 CAN 查詢標準基準 TID（$00、$20…），絕不發送致動指令探測。 | 一致（技術規範與安全防護對齊） |
| `serviceRecipesDiscoveryButton` | Discover Mode 08 Supported TIDs | 探索 Mode 08 支援項目 | 一致 |
| `serviceRecipesDiscoverySuccess` | ECU supports Mode 08. Supported TIDs: {tids} | ECU 支援 Mode 08。支援 TID：{tids} | 一致（`{tids}` 為動態參數） |
| `serviceRecipesDiscoveryUnsupported` | Mode 08 is not supported by this ECU | 此 ECU 不支援 Mode 08 | 一致 |
| `serviceRecipesDiscoveryUnknown` | Mode 08 support is unknown: {reason} | Mode 08 支援狀態未知：{reason} | 一致（保留 unknown 嚴謹界定） |
| `serviceRecipesDiscoveryPartialWarning` | Discovery partially completed ({reason}). Uncompleted blocks: {blocks}. Note: Not found does not mean unsupported. | 探索未完全完成（{reason}）。未完成區塊：{blocks}。未查到不代表不支援。 | 一致（「未查到不代表不支援」為核心安全哲學） |
| `serviceRecipesSimulationBadge` | Simulation Ready | 模擬可用 | 一致 |
| `serviceRecipesLiveBlockedBadge` | Live Blocked (0 Live Candidates) | 禁止實車（0 實車候選） | 一致（嚴格對齊 0 Live Candidates） |
| `serviceRecipesDiscoveryRequiresCan` | Requires an active OBD-II CAN bus connection. | 需要作用中的 OBD-II CAN 匯流排連線。 | 一致 |

#### 4.2.2 結構化探索中斷原因 (Mode08IncompletionReason) 對照矩陣
| 列舉值 (Enum) | 英文對照 (`app_en.arb`) | 繁體中文對照 (`app_zh_Hant.arb`) | 協定與參數對應說明 |
| :--- | :--- | :--- | :--- |
| `unheaderedCrossBlockLimitation` | Source attribution and coverage unconfirmed: unheadered responses cannot establish cross-block ECU identity | 來源歸因與覆蓋完整度未確認：無標頭回應無法建立跨區塊 ECU 身分 | 無標頭多區塊後備核心免責聲明 |
| `noResponseWithEcu` | No response on block {block} from {ecu}: {marker} | 區塊 {block} 來自 {ecu} 無回應：{marker} | `{block}`=十六進位, `{ecu}`=ID, `{marker}`=原始標記 |
| `noResponse` | No response on block {block}: {marker} | 區塊 {block} 無回應：{marker} | 匿名無回應 |
| `negativeResponseWithEcu` | Negative response on block {block} from {ecu} (NRC {nrc}) | 區塊 {block} 來自 {ecu} 負回應 (NRC {nrc}) | `{nrc}`=十六進位 NRC 代碼 (如 `0x22`) |
| `negativeResponse` | Negative response on block {block} (NRC {nrc}) | 區塊 {block} 負回應 (NRC {nrc}) | 匿名負回應 |
| `malformedResponseWithEcu` | Malformed response on block {block} from {ecu}: {details} | 區塊 {block} 來自 {ecu} 格式錯誤：{details} | 包含詳細結構解析 |
| `malformedResponse` | Malformed response on block {block}: {details} | 區塊 {block} 格式錯誤：{details} | 匿名格式錯誤 |
| `timeout` | Query timed out for block {block} | 區塊 {block} 查詢逾時 | `{block}` 逾時 |
| `budgetExceeded` | Discovery budget reached before all blocks queried | 在查詢所有區塊前已超出預算時間 | 探索時間或指令預算耗盡 |
| `sessionDisconnected` | Session disconnected or superseded during discovery | 探索期間連線中斷或被取代 | 通訊中斷或世代衝突 |
| `unqueriedAnnouncedBlocks` | Unqueried blocks announced by ECUs: {blocks} | ECU 宣告但未查詢的區塊：{blocks} | 未完成之接續宣告區塊 |
| `requiresCanBus` | Mode 08 capability discovery requires a resolved OBD-II CAN bus | Mode 08 功能探索需要解析的 OBD-II CAN 匯流排 | 非 CAN 匯流排環境拒絕 |
| `unexpectedExecutionResponse` | Unexpected execution response for supported TID query | 查詢支援 TID 時收到非預期的執行回應 | 協定異常保護 |

#### 4.2.3 格式錯誤原因 (`Mode08MalformedReason`) 對照表
| 錯誤原因列舉 | 英文描述 (`app_en`) | 繁體中文描述 (`app_zh_Hant`) |
| :--- | :--- | :--- |
| `truncated` | Truncated response | 回應長度不足 |
| `invalidHex` | Invalid hex | 十六進位格式無效 |
| `invalidSid` | Invalid service ID | 服務識別碼不相符 |
| `wrongBaseTidEcho` | Wrong base TID echo | 基準 TID 回應不符 |
| `wrongTestIdEcho` | Wrong test ID echo | 測試 ID 回應不符 |
| `invalidBitmaskLength` | Invalid bitmask length | 位元遮罩長度無效 |

---

### 4.3 原始協定標記保留性審計 (Raw Protocol Marker Preservation Audit)

在在地化翻譯過程中，以下技術標記**嚴禁被翻譯或變更**，必須原樣呈現以確保技術人員能正確進行診斷除錯：

| 標記類別 | 受保護原始標記範例 | 審計規範要求 |
| :--- | :--- | :--- |
| **診斷區塊與 TID** | `0x00`, `0x20`, `$00`, `$20`, `$01`, `$02` | 保持前綴十六進位格式，不得轉為十進位或譯為文字 |
| **配接器原始回應** | `NO DATA`, `OK`, `?`, `BUFFER FULL`, `CAN ERROR`, `DATA ERROR` | 保持大寫 ASCII 協定字串，嚴禁翻譯為「無數據」或「緩衝區滿」 |
| **負回應代碼 (NRC)** | `NRC 0x22`, `NRC 0x12`, `NRC 0x31`, `0x22` | 保留 `NRC` 前綴與標準十六進位代碼 |
| **ECU 節點識別碼** | `7E0`, `7E8`, `7E9`, `7DF`, `18DAF110` | 保留 CAN ID 標準表示法 |
| **AT 指令集** | `ATZ`, `ATH1`, `ATH0`, `ATSH`, `ATRV`, `ATWS`, `ATD` | 保持標準 ELM327 指令名稱 |
| **雜湊指紋標記** | `SHA-256`, Canonical Hash | 保持演算法標準名稱 |

---

### 4.4 D08 驗收查核表 (D08 Acceptance Checklist)
- [ ] **D08-CHK-01**: `app_en.arb` 與 `app_zh_Hant.arb` 中與 Mode 08 探索及 Workshop 相關的 ARB Key 具備 100% 鍵值配對。
- [ ] **D08-CHK-02**: 繁體中文譯文準確傳達非致動安全原則及「未查到不代表不支援」之審慎哲學。
- [ ] **D08-CHK-03**: 所有原始協定標記（`NO DATA`, `0x00`, `0x20`, `NRC 0x22`, `BUFFER FULL` 等）在雙語介面中均完整保留，未遭誤譯。
- [ ] **D08-CHK-04**: UI 測試覆蓋繁體中文 (`zh_Hant`) 與英文 (`en`) 狀態渲染，斷言文字均精確吻合。

---

## 5. 自動化輔助測試線束與驗證執行腳本 (Automated Harness & Execution Commands)

在有限裝置驗收前後，必須於主機端執行以下驗證套件以確保基線代碼無任何迴歸：

### 5.1 有限控制迴歸與標頭協商測試套件 (D02 對齊)
```bash
~/fvm/versions/3.47.0/bin/flutter test test/obd_response_headers_refusal_test.dart
```
- **預期結果**: 5 項測試全數通過（Positive Control 1 & 2, Gap Probe 1, 2, 3），0 失敗。

### 5.2 複合事務與配接器狀態測試套件 (D02 對齊)
```bash
~/fvm/versions/3.47.0/bin/flutter test test/elm327_composite_transaction_test.dart
```
- **預期結果**: 52 項測試全數通過。

### 5.3 Workshop 雙語與狀態 UI 測試套件 (D08 對齊)
```bash
~/fvm/versions/3.47.0/bin/flutter test test/workshop/ui/service_recipes_screen_test.dart
```
- **預期結果**: 20 項測試全數通過（涵蓋德語、英語、繁體中文各語系與異常狀態渲染）。

### 5.4 診斷探索服務與狀態測試套件 (D02 & D08 對齊)
```bash
~/fvm/versions/3.47.0/bin/flutter test test/diagnostics/service_recipes test/state/service_recipes_provider_test.dart
```
- **預期結果**: 169 項測試全數通過。

### 5.5 Mode 08 回環測試儀 (Loopback Replay Oracle) 強制驗證
```bash
# 1. 於背景啟動本地 Mode 08 模擬伺服器
python3 tool/obd_test_rig/mode08_replay_reference.py --port 35088 &
SERVER_PID=$!

# 2. 執行 Oracle 測試套件（嚴禁 self-skip）
~/fvm/versions/3.47.0/bin/flutter test test/diagnostics/service_recipes/mode08_replay_oracle_test.dart \
  --dart-define=MODE08_ORACLE_REQUIRED=true \
  --dart-define=MODE08_ORACLE_PORT=35088 \
  --reporter expanded

# 3. 清理背景伺服器
kill $SERVER_PID 2>/dev/null || true
```
- **預期結果**: 6 項維度全數通過，0 skipped。

### 5.6 靜態分析合規檢查
```bash
~/fvm/versions/3.47.0/bin/flutter analyze
```
- **預期結果**: `No issues found!`。

---

## 6. 審計與驗收簽核清單 (Audit & Sign-Off Checklist)

| 查核項目 | 規範標準 | 驗證結果 | 簽核人 / 查核員 |
| :--- | :--- | :--- | :--- |
| **D02: 標頭狀態保留** | 明確拒絕保留先前狀態，禁止反轉，無非預期黏性失敗 | [PASS] 經 5-Point 控制測試證明 | forensic_auditor |
| **D02: 錯誤防遮蔽** | 配接器傳輸錯誤不被降級為乾淨拒絕，強制 Wire-Zero 阻斷 | [PASS] 程式碼與測試完全阻斷 | forensic_auditor |
| **D05: 生命週期三循環** | HOME / 鎖屏 / HOME 三重中斷無崩潰，`_pauseEpoch` 正確遞增 | [PASS] 時序與狀態機規格完備 | forensic_auditor |
| **D05: 3 秒探針恢復** | 回到前景必須通過 3 秒 `ATRV` 驗證方可恢復資料輪詢 | [PASS] 源碼已強制安全閥門閉鎖 | forensic_auditor |
| **D05: 截圖雜湊綁定** | 6 階段關鍵截圖定義明確，具備 SHA-256 與日誌 1:1 映射 | [PASS] 協定格式已標準化 | forensic_auditor |
| **D08: 雙語介面對照** | En 與 Zh-TW 語意完全一致，包含 10 種中斷原因與配方標籤 | [PASS] ARB 字典 100% 配對 | forensic_auditor |
| **D08: 原始標記保留** | `NO DATA`, `0x00`, `NRC 0x22`, `BUFFER FULL` 等協定標記未受污染 | [PASS] 審計矩陣確認原樣輸出 | forensic_auditor |
| **安全約束保證** | 嚴格遵守 Zero Live Candidates，絕無實車連線與 Gate 3 擴展 | [PASS] 邊界明確受控 | forensic_auditor |

---
**文件結語**: 本文件由 `teamwork_preview_worker_m2c_1` 根據 Telltale 最新代碼庫 (`1ad08253e86ec6a6aef2b706cd0b6729372da3b3`) 具體實現編製完成，作為 Gate 2 驗收測試與審計之權威依據。
