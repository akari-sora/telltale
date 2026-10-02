# Issue #106 Slice 1: Connection & Disconnect Causal Characterization Triage

## 1. 任務與審計身分 (Audit Identity)

- **Parent Task**: `TELLTALE-CONNECT106-CAUSAL-TRIAGE`
- **Slice**: `S1 — Characterization & First-Terminal Attribution`
- **Work Branch**: `test/obd106-connection-causal-trace`
- **Issue Reference**: `#106` (`Not able to connect`)
- **Reviewer / Advisor**: ChatGPT (GPT-6 Pro)
- **Base Commit**: `7f50996d9ed9a1211500d84070530a2a28464d8b` (MR !80 Exact-Main Merge Commit)
- **Head Commit**: `41ac51444470bdb7505da0faa484b0472216aa6b`
- **Slice Exit State**: `IN_REVIEW` (目標退出水準: `CONNECT106_SLICE1_CHARACTERIZATION_ACCEPTED`)
- **Reporter Root Cause**: `REPORTER_ROOT_CAUSE = PENDING_EVIDENCE`
- **Codebase Integrity Boundary**: **`lib/` 0 lines modified (Strict zero diff)**

---

## 2. 業務背景與問題分層 (Context & Triaging Boundary)

Issue #106 使用者回報：在 Android 車機使用廉價藍牙 ELM327 轉接器時，畫面顯示電壓後立即斷線，其他 App 正常，重複嘗試皆在相同步驟斷線。

**審計邊界澄清 (R81-4)**：
1. **合成參數 vs 現場數據**：測試中的 13.9V、ATRV 電壓讀數及 4 秒逾時均為合成測試環境與原始碼預設之參數設定，非 reporter 本人提供的實體車輛 dump。
2. **無需 HCI Snoop 前置條件**：Bluetooth HCI snoop 或實體韌體 dump 不是本 Slice 1 特徵化切片的前置依賴；本切片以既有代碼狀態機與合成 byte-stream 契約為基礎進行有限觀測。
3. **Critical AT 命令邊界**：原始碼中 `InitStep('ATRV')` 預設 `isCritical: false`，非關鍵逾時步驟；關鍵握手步驟為 `ATSP0`、`ATE0`、`ATZ` 與 `0100`。
4. **真實 Polling 與數值觀測**：CASE-04 採用真實 `PollingEngine` 訂閱 PID 010D（車速），回傳合法數值 payload（`41 0D 32` -> 50 km/h），非僅檢驗 ELM `OK` 標記。

---

## 3. 四維度因果架構防線 (Causal Attribution Matrix)

本切片嚴格劃分四種資訊維度，避免將測試馬具的注入假設冒稱為產品已有的觀測能力：

| 維度 | 定義與邊界 | 本切片落地位置 |
| :--- | :--- | :--- |
| **`injectedFault`** | 測試端主動注入的故障類型（馬具已知輸入） | `Issue106TraceProbe.injectedFault` |
| **`observedEvents`** | 實際從 transport 串流與 wire 觀測到的底層位元組與訊號事件流（含 stream onError / onDone） | `Issue106TraceProbe.records` |
| **`productReportedReason`** | 產品代碼（`Elm327Client`）目前對外暴露的真實錯誤與連線狀態（`TransportIssue` / `InitNote`） | `Issue106TraceProbe.productReportedIssue` / `failedStepNote` |
| **`inference`** | 從實證能夠確鑿推論的結論與尚不可知的未知邊界 | 本報告第 5 節（已知 Observability Gap） |

---

## 4. 驗收矩陣與子情境實測結果 (Verification Matrix)

所有測試實作於 [`test/issue106_disconnect_characterization_test.dart`](test/issue106_disconnect_characterization_test.dart)，規格定義於 [`test/fixtures/issue106/connection_cases.json`](test/fixtures/issue106/connection_cases.json)：

| 主案例 ID | 子情境 Suffix | 測試行為與驗收重點 | 實測結果 |
| :--- | :--- | :--- | :--- |
| **CASE-01** | `CASE-01-A-REMOTE-EOF` | 遠端串流 `onDone` (EOF)，經由 stream controller 自然觸發，`firstTerminalCause` 鎖定為 `StreamDone`，`productReportedIssue` 綁定為 `linkDroppedMidSession` | **PASS** |
| **CASE-01** | `CASE-01-B-SOCKET-RESET` | 遠端串流 `onError` (Socket reset)，經由 stream controller 自然觸發，`firstTerminalCause` 鎖定為 `StreamError`，`productReportedIssue` 綁定為 `linkDroppedMidSession` | **PASS** |
| **CASE-01** | `CASE-01-C-CALLER-CANCEL` | 呼叫端於關鍵步驟 `0100` 發起並主動 `await client.disconnect()`，明確確認取消完成點，報告 typed `disconnectedByApp`，資源釋放 0 dangling futures | **PASS** |
| **CASE-02** | `CASE-02-A-CRITICAL-AT-TIMEOUT` | 關鍵 AT 命令（`ATSP0`）沉默逾時，以 step handoff/running 為起點於一致時鐘域驗證嚴格遵守 4s 邊界，後續步驟（如 0100）正確 skipped 且不上 wire | **PASS** |
| **CASE-02** | `CASE-02-B-NON-CRITICAL-AT-FAIL` | 非關鍵 AT 命令（`AT@1`）回覆 `?`，不中斷連線，握手正常通過 | **PASS** |
| **CASE-03** | `CASE-03-A-BEFORE-DEADLINE` | `0100` 在 250ms 內合法回覆，握手通過並完成協定解析 | **PASS** |
| **CASE-03** | `CASE-03-B-AFTER-DEADLINE` | `0100` 在 Attempt 1 保存回覆 callback 並觸發 4s 逾時斷線退役；Attempt 2 建立 fresh transport 成功連線後釋放 Attempt 1 的舊 callback，驗證跨世代邊界防線阻止其污染 Attempt 2（無 4.2s 背景 timer 漂移，`StaleGenerationDiscarded` 邊界丟棄） | **PASS** |
| **CASE-03** | `CASE-03-C-CHUNKED-LITERAL` | `0100` 經由 Classic RFCOMM 拆分為多個片段（包含 CR/LF/>），可等待之 `sendChunks` 重組正確，teardown join 零洩漏 | **PASS** |
| **CASE-04** | `CASE-04-A-FULL-CYCLE` | 正常連線對照：13.9V ATRV -> 0100 -> 真實 `PollingEngine` 輪詢 PID 0D (50 km/h) -> 優雅關閉，資源 0 洩漏 | **PASS** |
| **CASE-04** | `CASE-04-B-OBSERVER-TX-EQUIVALENCE` | 正常控制對照：固定 demand/排程下，Probe/Observer 開與關之 TX wire 指令完全等價，證明觀測無侵入副作用 | **PASS** |

---

## 5. 已知觀測缺口與產品特徵 (Observability Gaps)

1. **ClassicTransport 連線斷線原因塌縮 (Reason Collapse)**：
   - 在 `lib/obd/transport/classic_transport.dart` 中：
     ```dart
     onError: (Object _) => setConnected(false),
     onDone: () => setConnected(false),
     ```
   - 無論底層發生 socket reset 還是 EOF，皆直接呼叫 `setConnected(false)`。
   - `Elm327Client` 接收到 `connectionChanges` 為 `false` 後，一律收斂為：
     ```dart
     TransportIssue.linkDroppedMidSession
     ```
   - **實證推論**：現場使用者遇到「讀取電壓後斷線」時，App 目前無法從日誌區分是硬體轉接器自己 EOF 重置，還是作業系統 BluetoothSocket 報出 reset。此缺口需在後續窄幅 observer 切片中考慮暴露更具體細節，而非在 Slice 1 盲目修改。
2. **Reporter 根因待證 (Pending Evidence)**：
   - 由於目前仍未取得 reporter 的實體 Bluetooth HCI snoop log 或車機型號/ELM327 韌體版本 dump，本切片將根因狀態忠實標註為：
     `REPORTER_ROOT_CAUSE = PENDING_EVIDENCE`
   - 不把單一合成的 4s 逾時或 EOF 冒稱為已徹底解決 Issue #106。

---

## 6. 突變防線與負控制 (Mutations & Negative Controls)

測試套件包含專屬的突變防線群組，全數實測通過：

- **M106-01 (首因防覆寫)**：證明 `Issue106TraceProbe` 能封裝首個終止事件，後續 `cleanupStarted` 或 secondary error 不會覆蓋 `firstTerminalCause`，且能正確記錄清理錯誤。
- **M106-02 (固定預算邊界)**：證明握手步驟嚴格綁定 4000ms 預算，不會因重試或時鐘漂移而無限展期至 8000ms。
- **M106-03 (退役拒絕派發)**：證明 client 退役/disconnect 後，任何嘗試 `send()` 的命令皆以 `await expectLater` 驗證在進入 wire 前被立即拒絕，wire 命令數維持不變。
- **M106-04 (完整性訊框檢查)**：證明未帶 prompt `>` 的不完整片段以 `await expectLater` 驗證指定 timeout 到期，不會因早於 dispose 終止。
- **R81-3 Unit Test (受控分段中止與異步匯流)**：證明 `sendChunks` 在多分段發送期間遭遇 caller disconnect 時，可被即時 canceller 解鎖、異步操作安全 join，且剩餘未發送分段與計時器全數歸零，無 dangling timers 或 unhandled async errors。
- **N106-05 (馬具負控制矩陣 - 13 條嚴格校驗)**：
  - 正向校驗：`test/fixtures/issue106/connection_cases.json` 包含所有 9 個子情境 suffix 與必要欄位。
  - Schema 負控制：竄改測試證明缺少必要 sub-case 或清空 cleanup_obligations 時，驗證函式皆拋出 `FormatException` 拒絕執行。
  - Fault 未觸發負控制：實測證明「配置 fault 但未執行觸發」被 `validateSubCaseExecution` 拋出 `StateError` 嚴格拒絕。
  - 執行結果不符負控制：實測證明「回報 issue 與規格不符」被 `validateSubCaseExecution` 拋出 `StateError` 嚴格拒絕。
  - 逾時漏洞負控制：實測證明 `timedOut` 不得繞過 `linkDroppedMidSession` 的 issue 不符檢查。
  - 故障類型不符負控制：實測證明 `injectedFault` 與規格不一致時立即拒絕。
  - 終止主因不符負控制：實測證明 `firstTerminalCause` 與規格不一致時立即拒絕。
  - 意外 issue 負控制：實測證明 nominal case 預期 none 時發生 issue 立即拒絕。
  - 衝突 raw issue 負控制：實測證明 raw issue 存在時 timedOut 不得冒充 commandReplyTimeout。
  - 配置正確但 fired event 錯誤負控制：實測證明配置正確但實際 fired event 的 type 錯誤時被 `validateSubCaseExecution` 拋出 `StateError` 嚴格拒絕。
  - 正向 terminal (handshake_continued) 失敗負控制：實測證明 expectedTerminal 為 `handshake_continued` 時若 connectOk 為 false 立即拒絕。
  - 正向 terminal (connected_then_closed) 失敗負控制：實測證明 expectedTerminal 為 `connected_then_closed` 時若 connectOk 為 false 立即拒絕。
  - Attempt 隔離負控制：實測證明 injected fault 發生在不同 attempt 時被 `validateSubCaseExecution` 拋出 `StateError` 嚴格拒絕。

---

## 7. 驗證指令與工件清單

- **測試指令**：
  ```bash
  fvm flutter analyze
  fvm flutter test test/issue106_disconnect_characterization_test.dart
  python3 scratch/run_m106_mutations.py
  ```
- **執行結果**：
  - `flutter analyze`: **No issues found!**
  - `flutter test`: **30/30 passed, 0 failed, 0 skipped**
  - `M106-01 ~ M106-04`: **4/4 mutations killed & restored pass**
  - `N106-05`: **13/13 negative controls passed (2 schema, 11 execution)**
- **工件套件 (GitLab 託管連結)**：
  - `M106-evidence.tar.gz`:
    - **Hosted URL**: [M106-evidence.tar.gz](https://gitlab.com/-/project/86385809/uploads/ffe3c8b6b2c3cb5da835fe09dc32ba0f/M106-evidence.tar.gz)
    - **SHA256**: `4dd46473c3d432f991c176e6d5543c9c895fb4c18aaf116f98927ccf325c28d4`
  - `M106-evidence.zip`:
    - **Hosted URL**: [M106-evidence.zip](https://gitlab.com/-/project/86385809/uploads/cdf3eb9086062b662c7483aea4d75168/M106-evidence.zip)
    - **SHA256**: `905d06e105cec668a2e799f96249571be25b25ff8612b3bde0b8d55af1c3ce70`
  - 內部結構：`manifest.json`, `SHA256SUMS`, `control/`, `M106-01/` ~ `M106-04/`, `N106-05/`
  - 本地鏡像：`docs/verification/M106-evidence/`
- **涉及檔案清單**：
  - `test/fixtures/issue106/connection_cases.json`
  - `test/support/issue106_trace_probe.dart`
  - `test/issue106_disconnect_characterization_test.dart`
  - `docs/verification/issue106-connection-triage.md`
  - **`lib/` 變更：0 lines (Strict zero diff)**

---

## 8. GPT-6 Pro 審計 5 項 Closeout 改善落地總結

| 項目 | 審計關注點 | 改善方案與落地代碼 |
| :--- | :--- | :--- |
| **Item 1 (R81-4)** | `timedOut` 短路漏洞 | 重構 `validateSubCaseExecution`：引入 `normalizeProductIssueCategory`，嚴格分離底層原始 `TransportIssue`、`InitNote` 與正規化 issue category。`commandReplyTimeout` 嚴格要求 `timedOut` 且 raw issue 必須為 null；當預期為 `none` 時嚴格禁止任何 issue 或 timeout；補齊 5 組執行負測試（共 7 組）。 |
| **Item 2 (R81-1)** | 操作關聯性與 Attempt 隔離 | 於 `Issue106TraceProbe` 引入 `currentOperationId` 關聯同一步驟之 write/rx/completion；於 `ScriptedCausalTransport` 綁定不可變 `boundAttemptId`，並於 `disconnect()` 清除 `_activeWriteOpId`；於 `bindSessionToProbe` 依 generation 嚴格過濾，並於 CASE-03-B 退休 Attempt 1 時即時關閉 subscription，徹底杜絕跨 attempt 污染。 |
| **Item 3 (R81-2)** | 統一 Session 擁有者與斷言修正 | CASE-03-B 改用真實 `ObdSession` notifier 管理 attempt 生命週期；修正斷言為驗證 Attempt 2 未接收 Attempt 1 的 `BE 1F B8 10` 殘餘回覆，並順利獲取 `41 0D 32`（50 km/h），並斷言 Attempt 1 記錄完全不滲透至 Attempt 2。 |
| **Item 4 (R81-3)** | Chunks 異步錯誤追蹤與匯流 | `sendChunks` 新增 stepCompleter 與取消器，在 `disconnect()` 時即時解除 timer 等待並以 `Future.wait` 匯流；test tearDown 全面升級為終止性 `transport.dispose()`；重構 `sendChunks` 異常拋出架構，防止未等待時的 unhandled zone exception；新增專屬中斷匯流單元測試。 |
| **Item 5 (R81-4)** | 託管上傳連結與校驗 | 透過 GitLab API 上傳 `M106-evidence.tar.gz` 與 `.zip` 至專案託管空間（URL: `/uploads/ffe3c8b6...` 與 `/uploads/cdf3eb90...`），並記錄於文檔與 MR Note。 |

---

## 9. GPT-6 Pro 最終增量審核 3 項確認點落地總結

| 項目 | 審計確認點 | 改善方案與落地代碼 |
| :--- | :--- | :--- |
| **Point 1** | Fault／Terminal 驗證器收尾 (`validateSubCaseExecution`) | 移除 `\|\| probe.injectedFault == fault` 與 `firstTerminalObserved` 備援，嚴格要求實際 fired event 匹配 `type == fault` 與對應 `attemptId`；正向 terminal（`handshake_continued`、`connected_then_closed`）嚴格強制 `connectOk == true`；新增 4 組專屬負測試（包含配置正確但事件錯誤、正向 terminal 為 false、attempt 跨代不符）。 |
| **Point 2** | Session Generation 實際計數對齊 (`CASE-03-B`) | 對齊 production `ObdSession` 計數規則（初始 0，首次連線 1，中斷 2，二次連線 3），動態計算 `attempt2Gen = session.generation + 1` 並綁定 transport 與 observer；補齊正控制斷言，驗證 Attempt 2 真 `initStepStarted` 與 `initStepCompleted` 確實被 observer 接收。 |
| **Point 3** | Phase-deadline 邊界確認 (`CASE-02-A`) | 於 `CASE-02-A` 補齊三個時序階段確認：(1) deadline 前（2000ms mid-window）無 timeoutObserved 事件觸發；(2) 剛超時（~4000ms）首個 typed `TraceEventKind.timeoutObserved` 觸發並命中 [3800, 4800]ms 邊界；(3) 超時後 sequence 嚴格小於 failed completion 且後續指令不上 wire；並補齊早於 deadline 回覆的對照測試。 |

---

## 10. Slice 2 實作與根因修復總結 (MR !88)

### 10.1 根因判定提升 (Root-Cause Promotion)
- **分析與歸因定位**：
  在 Slice 1 的因果特徵分析基礎上，確認了代碼層級的脆弱點：`ATSP0` 僅武裝自動協定搜尋，ELM327 直到收到第一個實際車載探測 `0100` 時才真正遍歷所有協定（CAN、K-Line、J1850 等）。在 Android 車機搭配廉價 Bluetooth clone 上，此搜尋過程可長達 15–30 秒。
- **舊代碼缺失**：
  1. `_runInitSequence()` 原先對所有步驟無差別套用 4 秒逾時；只有轉接器在 4 秒內先吐出 `SEARCHING...` 時，`_extendTimeoutIfSearching()` 才有機會續期至 25 秒。若轉接器搜尋時完全靜默或 `SEARCHING...` 因緩衝片斷延遲，即在 4 秒被強制斷線。
  2. 部分 ECU 於冷車喚醒初期可能先回傳一次暫態 `NO DATA`，原代碼直接判定 critical step 失敗中斷握手。
- **歸因邊界**：
  *Root-cause candidate promoted from plausible to code-confirmed vulnerability; reporter-specific attribution remains pending physical reproduction.* （代碼層級漏洞已完全確認並根治；特定回報者實機歸因仍待實體重現數據進一步印證）。

### 10.2 Production 修改範圍 (`lib/obd/elm327_client.dart` 嚴格 1 個檔案)
1. **InitStep 逾時覆蓋契約**：
   `InitStep` 增加可選 `timeout` 參數。初始化序列中的 `0100` 探測設定為 `protocolSearchTimeout`（25 秒）；其餘本機 AT 指令仍維持預設 4 秒。
2. **單次窄域 NO DATA 重試與絕對截止時間共用**：
   僅在步驟為 `0100` 且回應為 `Elm327ErrorCode.noData` 時進行單次立即重試。兩次嘗試透過 `send(deadline: stepDeadline)` 嚴格共用同一個 25 秒絕對 deadline，確保包含底層寫入逾時（`_withinDeadline`）在內的整體耗時絕不超過 25 秒封套（杜絕 25s + 25s 漂移）。
3. **未觸碰範圍 (Zero Collateral)**：
   未更動任何通用 `send()` / `_resync()`、`PollingEngine`、watchdog 政策、`_requireSupportMask()` 驗證邏輯或 transport 傳輸層。

### 10.3 迴歸測試套件 (`test/issue106_protocol_search_regression_test.dart`)
新增 8 組專屬迴歸測試，覆蓋率 100% 通過：
- **S2-01**：超過舊 4 秒邊界（6s 延遲）、無 `SEARCHING...`、0100 最終獲取合法 `4100` 成功（0100 TX 嚴格為 1 次）。
- **S2-02**：片斷 `SEARCHING...` chunk + 8s 慢速協定搜尋成功。
- **S2-03**：第 1 次 0100 回傳 `NO DATA`，第 2 次回傳合法 `4100`，連線成功（0100 TX 嚴格為 2 次）。
- **S2-04**：連續 2 次 `NO DATA`，握手判定失敗（0100 TX 嚴格為 2 次）。
- **S2-05**：0100 回傳 `UNABLE TO CONNECT` 致命錯誤，立即失敗不重試（0100 TX 嚴格為 1 次）。
- **S2-06**：0100 回傳 `CAN ERROR` 致命錯誤，立即失敗不重試（0100 TX 嚴格為 1 次）。
- **S2-07**：0100 超過 25 秒持續靜默，有界逾時判定失敗。
- **S2-08**：0100 第 1 次耗費 20 秒取得 `NO DATA`，第 2 次嘗試僅獲剩餘 ~5 秒預算後逾時，總耗時小於 28 秒（證明絕無刷新 25s 預算）。
- **M106-02**：更新 Slice 1 characterization suite 中的 M106-02 邊界斷言以適配 25s 預算，33/33 tests 維持全綠。

### 10.4 GPT-6 Pro 審查與 GitLab MR !88 簽核
- **審查迭代**：
  - Round 1: 提出 Blocking 問題（`send()` 直接帶 25s 導致 retry 重新刷新整個 25 秒預算，違反 M106-02 邊界不變性）→ 裁定 `REQUEST CHANGES`。
  - Round 2: 指出 Stopwatch 方案未能約束底層 `_withinDeadline(writeTimeout)`，建議改用原生的 `stepDeadline` 傳入兩次 `send()` → 裁定 `REQUEST CHANGES`。
  - Round 3: 確認 `stepDeadline` 徹底封閉寫入超時溢出漏洞，S2-08 收緊至 `< 28s`，程式碼與測試全數合規 → 正式授予 **`APPROVE`**。
- **合併結果**：
  GitLab MR [!88](https://gitlab.com/aa22396584/telltale/-/merge_requests/88) 透過 `glab mr merge 88 --squash --remove-source-branch` 順利 Squash Merge 合入 `main`。



