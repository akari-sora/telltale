# MR !81（Commit `99ea29c4`）GPT-6 Pro 審查裁定與修復卡 (R81-1 ~ R81-4)

- **審查標的**: GitLab MR !81 (`https://gitlab.com/aa22396584/telltale/-/merge_requests/81`)
- **分支**: `test/obd106-connection-causal-trace`
- **Reviewed HEAD**: `99ea29c46615b6df981455c52e4700796d1fe097`
- **BASE Commit**: `7f50996d9ed9a1211500d84070530a2a28464d8b` (MR !80 Exact-Main Merge Commit)
- **Reviewer / Advisor**: ChatGPT (GPT-6 Pro)
- **審查裁定**: **`CHANGES REQUESTED`（尚不予 SIGNED-OFF）**
- **M0 狀態**: **`OPERATION_RECEIPT_DELIVERED -> ISSUE101_COMPLETE` 正式結案成立（不重開）**

---

## 審查裁定核心摘要

1. **M0 交付結案成立**：
   - Exact-Main Pipeline #2887183910 / Job #16764170772 100% 綠燈 SUCCESS。
   - Issue #101 已 CLOSED，4/4 checklist 完成，結案 Note #3912889000 確認生效。
   - 不因 MR !81 重新審查或打開 #101。
2. **MR !81 現狀與邊界維持**：
   - 確實維持四個測試／文件檔案、`lib/` 0 行修改。
   - 但目前的 14 項測試尚不足以支持 `CONNECT106_SLICE1_CHARACTERIZATION_ACCEPTED`。
   - 將剩餘工作固定為 **R81-1 ～ R81-4**，不新增實車、完整原生 BLE 或全協定驗收，維持四檔白名單。

---

## 四項修復卡 (Repair Card: R81-1 ~ R81-4)

### R81-1：注入故障不等於觀測故障（真實觀測與接線）

1. **Reset 案例未真正產生 Stream Error**：
   - `ScriptedCausalTransport.injectRemoteError()` 直接記錄 `streamErrorObserved / cause=StreamError` 並呼叫 `setConnected(false)`，未向 input stream 拋出 error，也未觸發 `ClassicTransport.onError`。
   - **修法**：注入故障只記錄「安排／發起」，真實觀測點（stream onDone/onError、connectionChanges、InitProgress/typed exception、client/engine 終態）各自獨立回填。
2. **productReportedIssue 未接入產品輸出**：
   - Probe 宣告了欄位但未由真實產品輸出賦值；需明確區分 command reply timeout、adapterSilentOnResync 與 watchdog 的 linkStoppedResponding。
3. **Probe 缺乏容量限制與清理錯誤隔離**：
   - `_records` 需有容量限制（bounded）、截斷標記，並將 secondary cleanup error 與首因明確分離。

### R81-2：關鍵步驟逾時、健康輪詢與跨世代隔離語意修復

1. **ATRV 在當前版本非 Critical Step**：
   - `Elm327Client.initSequence` 中 `InitStep('ATRV')` 預設 `isCritical: false`。
   - 真正的 critical step 為 `ATSP0` 或 `ATE0`。
   - **修法**：改用已核對的 critical `ATSP0` / `ATE0` 觀測 deadline 邊界與 typed timeout。
2. **健康對照 010D 需取得真正數值 Observation**：
   - `defaultAnswer()` 對 010D 回覆 `OK\r\n>`，`isSuccess` 僅代表無 ELM error，未獲得有效車速數值。
   - **修法**：使用合法 PID 回覆（如 `41 0D 32\r\n>`）與支援遮罩，經由真實 `PollingEngine` 取得一筆包含 value/unit/source 的 observation，再優雅關閉。
3. **舊回覆與新 Session 真正跨世代重疊隔離**：
   - 建立新 attempt 時釋放舊 callback，驗證舊資料在邊界被安全拒絕，新 session 狀態與派發不受污染。

### R81-3：非同步斷言時序與清理順序固定

1. **非同步 Matcher 需以 `expectLater` 明確 await**：
   - 修正 `M106-04` 中 `expect(() => client.send(...), throwsA(...))` 未等待即執行 `client.dispose()` 的競態問題，改為 `await expectLater(...)`。
2. **非同步作業可 Join 與計時器清理**：
   - `sendChunks()` 需提供可 await 的 completion。
   - `delayedReply` 等定時器需納入管理與 teardown 清理，避免 dangling timers。
   - 測試拆卸明確標記 `TEST_CLEANUP`。

### R81-4：真實 Mutation 紀錄與工件交付

1. **落實驗證性 Mutation**：
   - M106-01～04 需產出實際 patch，記錄 mutant-fail 與 restored-pass 的真實 exit code 與日誌，不以普通 regression test 充當 mutation 驗證。
2. **N106-05 負控制實測**：
   - 實測缺少 case、未啟動 fault 或錯誤結果時的真實拒絕。
3. **文檔標記更新**：
   - `issue106-connection-triage.md` 狀態改為 `IN_REVIEW`。
   - 移除本機路徑（`file:///Users/...`）。
   - 澄清 13.9V、ATRV 為合成測試設定，HCI snoop / 實機 dump 非前置條件。

---

## 審查結論與指示

- **MR !81／`99ea29c4` 暫不簽核、不合併。**
- **續用 MR !81 分支 `test/obd106-connection-causal-trace`，維持四檔白名單，`lib/` 保持 0 變更。**
- 完成 R81-1～R81-4 後，重新執行驗證並提交增量審查！
