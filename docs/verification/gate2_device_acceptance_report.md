# Gate 2 限定裝置驗收實測綜合報告
## Limited Device Acceptance Comprehensive Report: D02, D05, D08

- **專案名稱**: Telltale (`ImL1s/telltale`)
- **驗收標的**: Gate 2 候選版本限定裝置實測驗收（Limited Device Acceptance）
- **關聯議題**: GitLab Issue #104 (Note 3858619704 / Note 3857735494)
- **基準版本 (Commit HEAD)**: `1ad08253e86ec6a6aef2b706cd0b6729372da3b3`
- **Git Tree SHA**: `23fef0783e9cb6ca783de677ecc3196bebb498d8`
- **文件交付版本 (Docs Commit)**: `candidate/boost-gate2-candidate-20260917` (Commit `2da601377bfd97f943bc2720ba0a0ab23fd67f12`)
- **分支名稱**: `candidate/boost-gate2-candidate-20260917`
- **候選 APK SHA-256**: `acc80f75b599d7f85e5c11416ec6c2e92f774f6b9e1699584414ca35abbade9e`
- **候選 APK 大小**: `173856260` bytes (~165.8 MiB)
- **實測日期**: 2026-09-18
- **驗收判定**: **執行團隊回報 PASS（附完整實證數據待審查端獨立複核，#104 維持開啟）**

---

## 1. 執行綱要與零實車候選約束 (Executive Summary & Zero Live Candidates)

### 1.1 驗收目的與範圍
本報告針對 Telltale Gate 2 候選 APK（版本 `1.0.14`，Build `15`）在限定裝置測試環境（Limited Device Bench）下的實測結果提供權威、可審計的實證數據。驗收重點全面涵蓋 GitLab Issue #104 審查要求，聚焦三大核心驗收情境：
1. **D02（標頭協商與拒絕後備容錯）**：驗證 `ATH1` 協商成功時之多區塊 ECU 來源歸因（`7E8`），以及當配接器明確拒絕（`?`）時，客戶端保留先前狀態、安全降級無標頭查詢、於 UI 揭示限制說明且維持零崩潰。
2. **D05（生命週期韌性與事件映射）**：驗證在三次連續作業系統中斷與恢復（HOME 鍵、螢幕關閉/睡眠、HOME 鍵）期間，`pauseEpoch` 單調遞增（0 -> 1 -> 2 -> 3）、在途查詢 2 秒內安全排空、背景暫停期間完全凍結輪詢、前景恢復瞬間清空遙測殘留，並以 `ATRV` 探針成功重驗鏈路。
3. **D08（雙語介面語意對稱性與協定標記保護）**：驗證英文（`en`）與繁體中文（`zh-Hant`）介面在成功、部分警告與未知狀態下具備 100% 語意對等，且所有底層原始協定標記（如 `NO DATA`、`0x00`、`0x20`、`NRC 0x22`、`BUFFER FULL`、`7E8`、`ATRV`）嚴格保持原文，未受翻譯侵蝕。

### 1.2 零實車候選人 (Zero Live Candidates) 絕對邊界驗證
本實測嚴格執行 Gate 2 之「零實車候選人」防護策略，稽核事實如下：
- **實體隔離與無車環境**：所有裝置測試均部署於隔離之 Android 模擬器（`emulator-5554`，Pixel 9，Android 16，API 36）與專案原生回環測試伺服器（`tool/obd_test_rig/mode08_replay_reference.py`，TCP 端口 35000）。
- **嚴禁實車接線**：測試過程中，測試裝置未連接任何實體車輛之 OBD-II / CAN 匯流排介面。
- **無 Gate 3 擴展**：驗證範疇嚴格限制於限定裝置台架，未向 Gate 3（車載現場驗收）延伸。
- **Gate 1 基線完好保持**：原 Gate 1 與 MR !4 之驗收基線、封裝檔案及歷史紀錄完全保持不變。
- **UI 實車防護徽章實測生效**：在所有實測截圖中，Workshop 服務配方介面均恆常渲染 `serviceRecipesLiveBlockedBadge`（「禁止實車（0 實車候選）」/「Live Blocked (0 Live Candidates)」），確保操作安全合約在實機環境中 100% 被兌現。

---

## 2. 候選 APK 密碼學指紋與環境識別 (Candidate APK Cryptographic Identity)

候選 APK 係由固化原始碼 Commit `1ad08253e86ec6a6aef2b706cd0b6729372da3b3` 透過固定之 Flutter 3.47.0 工具鏈建置，並於隔離環境中完成二進位指紋固定與部署驗證。

### 2.1 產物密碼學指紋 (Cryptographic Checksums)
| 項目 | 數值 / 說明 |
|---|---|
| **檔案名稱** | `app-field-debug.apk` |
| **隔離路徑** | `export/candidate_apks/app-field-debug-acc80f75b599.apk` |
| **檔案大小 (Bytes)** | `173856260` bytes (173,856,260 B / ~165.8 MiB) |
| **SHA-256 雜湊** | `acc80f75b599d7f85e5c11416ec6c2e92f774f6b9e1699584414ca35abbade9e` |
| **SHA-1 雜湊** | `2be659150f6afa42af5c3a8359789b363bc2f9c4` |
| **MD5 雜湊** | `cc14c39dad2573d815f092aa0eea3ada` |

### 2.2 Android 套件屬性與 SDK 目標 (Package & Manifest Metadata)
經 `aapt dump badging` 提取之二進位資訊如下：
- **Package ID**: `com.cbstudio.telltale`
- **Version Name**: `1.0.14`
- **Version Code**: `15`
- **minSdkVersion**: `24` (Android 7.0 Nougat)
- **targetSdkVersion**: `36` (Android 16)
- **compileSdkVersion**: `36` (Android 16)
- **Debuggable**: `true` (`android:debuggable="true"`)
- **Target Flavor**: `field`
- **Launchable Activity**: `com.cbstudio.telltale.MainActivity`
- **支援原生架構**: `arm64-v8a`, `armeabi-v7a`, `x86_64`

### 2.3 簽章與對齊驗證 (Signature & Alignment)
- **簽名機制**: APK Signature Scheme v2 驗證通過 (`true`)，未篡改。
- **簽署憑證 SHA-256**: `64500eefad1aeb8e163c2ceeaa78b39ce013849f1a75596dd1b477fc5d023736`
- **公鑰 SHA-256**: `656802a4ba3c520752184032cb935422cc30170f1b32c1290bc4263e9382b9b6`
- **Zipalign 對齊**: 經 `zipalign -c -v 4` 驗證，4-byte 邊界對齊 100% 成功。

### 2.4 實機部署一致性證明
候選 APK 安裝至目標模擬器後，直接在裝置上執行校驗：
```bash
$ adb -s emulator-5554 shell "sha256sum /data/app/~~Cur8h3aHP_zlELOjHYVcVg==/com.cbstudio.telltale-DLXpWiNlN7CJ5_IDRMO-MA==/base.apk"
acc80f75b599d7f85e5c11416ec6c2e92f774f6b9e1699584414ca35abbade9e  /data/app/.../base.apk
```
證明實測執行之目標即為固化之 Gate 2 候選 APK。

---

## 3. D02 驗收成果：標頭協商成功與優雅拒絕後備 (D02 Acceptance Results)

D02 測試驗證 `lib/obd/elm327_client.dart` 中修復的協定狀態機邏輯：配接器回覆明確拒絕 `?` 時，客戶端保留先前已知 `_headersOn`，嚴禁翻轉為相反設定，不將配接器錯誤誤降級為乾淨拒絕，且不產生偽性警告。

### 3.1 D02-1: 標頭協商成功情境 (ATH1 Negotiated Success)
- **測試場景識別碼**: `normal_headered_multi_block`
- **通訊歷程審計 (`d02_1_traffic.jsonl`)**:
  - 發送標頭啟用指令：`ATH1\r`
  - 配接器確認支援：回傳 `OK\r\r>`
  - 客略狀態機確認 `_headersOn = true` 且 `_responseHeadersUncertain = false`
  - 查詢區塊 0：發送 `0800\r`，配接器回傳 `7E8 06 48 00 80 00 00 01\r\r>`（宣告支援 TID $01 與接續區塊 $20）
  - 查詢區塊 1：發送 `0820\r`，配接器回傳 `7E8 06 48 20 40 00 00 00\r\r>`（宣告支援 TID $22，無後續區塊）
  - 復原標頭狀態：發送 `ATH0\r`，配接器回傳 `OK\r\r>`
- **來源歸因結果**:
  - 多區塊幀成功關聯至單一實體 ECU `7E8`。
  - 解析支援清單完整包含 TID `$01`, `$20`, `$22`。
- **UI 實機表現與無假性警告驗證**:
  - 介面正確渲染 `mode08_discovery_success_container`（綠色成功容器）。
  - 顯示核心文字：「`ECU 支援 Mode 08。支援 TID：$01, $20, $22`」。
  - 渲染三枚 TID 晶片標籤：`TID $01`、`TID $20`、`TID $22`。
  - **嚴格確認**：介面上完全無 `mode08_discovery_partial_warning`，無任何假性警告或不完全提示。
- **實證產物**:
  - 截圖檔案: `docs/verification/evidence/d02_1/d02_1_success.png`
  - 截圖 SHA-256: `1a77f34f0c0f4118c584298944a120df0b41a738d01340120cdc6cae6c4d765f`
  - 通訊記綠: `docs/verification/evidence/d02_1/d02_1_traffic.jsonl` (SHA-256: `f031d26359eef22d665171fdcc21e42bb81c7c7c1eb2b5379251d7da2ce49f85`)
  - Logcat 追蹤: `docs/verification/evidence/d02_1/d02_1_logcat.log` (SHA-256: `d61fd73778ddd4602f5dad9b80e5bbe3112372779fdfdab8c9eb30bc0e518d9f`)

### 3.2 D02-2: 標頭明確拒絕後備情境 (ATH1 Refused Graceful Fallback)
- **測試場景識別碼**: `source_attribution_anonymous_multi_block`
- **通訊歷程審計 (`d02_2_traffic.jsonl`)**:
  - 發送標頭啟用指令：`ATH1\r`
  - 配接器明確拒絕：回傳 `?\r\r>`
  - 客戶端狀態機判定：`_saidRefused` 成立（無配接器錯誤代碼），保持 `_headersOn = false`，不倒轉為相反假設，不設定 `_responseHeadersUncertain`。
  - 優雅降級：交易轉為匿名無標頭模式繼續進行，不拋出中斷異常。
  - 查詢區塊 0：發送 `0800\r`，配接器回傳 `48 00 80 00 00 01\r\r>`（無 CAN ID 標頭）。
  - 查詢區塊 1：發送 `0820\r`，配接器回傳 `48 20 40 00 00 00\r\r>`。
- **跨區塊限制檢測與 UI 揭露**:
  - 依據 `Mode08DiscoveryService` 合約，跨區塊在缺少標頭時無法證明來自同一 ECU，因此標記 `isComplete = false`，中斷原因為 `unheaderedCrossBlockLimitation`。
  - 介面渲染 `mode08_discovery_partial_warning`（橘黃色警示卡片）。
  - 介面明確揭示限制文字：「`探索未完全完成（來源歸因與覆蓋完整度未確認：無標頭回應無法建立跨區塊 ECU 身分）。未完成區塊：$20。未查到不代表不支援。`」
  - 同時容錯渲染已解析之 TID 晶片（`TID $01`, `$20`, `$22`），向技師提供最大可用診斷資訊。
- **穩定性指標**:
  - 應用程式全程穩定運作，Logcat 顯示 0 次未攔截例外、0 次 ANR、零崩潰（Zero Crashes）。
- **實證產物**:
  - 截圖檔案: `docs/verification/evidence/d02_2/d02_2_refusal_fallback.png`
  - 截圖 SHA-256: `eb908d3f9ffb7383c6910d02285bdb425408446d4f43fdee54fbe82b98f41342`
  - 通訊記綠: `docs/verification/evidence/d02_2/d02_2_traffic.jsonl` (SHA-256: `3448917ded6f1c4f8f9b43da24147b9ce6d3115ef55c8a922a505f53570711df`)
  - Logcat 追蹤: `docs/verification/evidence/d02_2/d02_2_logcat.log` (SHA-256: `6a7f42531b682531e928e26ee2f84d5f8cd4d0c5221712ad9622fa6797aa2978`)

---

## 4. D05 驗收成果：雙軌生命週期韌性與事件映射 (D05 Acceptance Results)

D05 測試嚴格驗證 Android 系統生命週期事件（切換桌面、螢幕關閉、重新喚醒）期間，遙測狀態機之排空暫停、單調 epoch 推進、防殘留保護及探針恢復能力。依據驗收合約，本項成果明確劃分為兩條獨立軌道呈現：

### 4.1 軌道 A: 一般 OBD-II 遙測工作階段之生命週期實測 (Track A: General Telemetry Poller Bench)
實測執行 3 次連續系統生命週期中斷與恢復序列：
```text
[Baseline: Epoch 0] 活躍輪詢儀表 (Mode 01 PIDs: 010C, 010D...)
       │
       ▼ (中斷 1: 按下 HOME 鍵回到桌面)
[Pause: Epoch 1] 在途查詢 2s 內排空，背景輪詢完全凍結 (Wire 0 查詢)
       │
       ▼ (恢復 1: 點擊圖示回到前景)
[Resume 1: Epoch 1] 儀表遙測清空防殘留，發送 ATRV 探針重驗，通過後重啟輪詢
       │
       ▼ (中斷 2: 按下 Power 鍵進入睡眠 / Screen-off)
[Pause: Epoch 2] PowerManager 進入 Asleep，輪詢安全掛起
       │
       ▼ (恢復 2: 點擊螢幕喚醒並解鎖)
[Resume 2: Epoch 2] 進入 Probe Guard，發送 ATRV 探針重驗，通過後重啟輪詢
       │
       ▼ (中斷 3: 再次按下 HOME 鍵回到桌面)
[Pause: Epoch 3] 進入第三次掛起
       │
       ▼ (恢復 3: 回到前景)
[Resume 3: Epoch 3] 完成三次循環，系統完全穩定
```

### 4.2 軌道 A 關鍵檢驗指標驗證事實
1. **單調遞增 `pauseEpoch` (Monotonic Epoch)**:
   - 內部計數器嚴格自 `0` -> `1` -> `2` -> `3` 遞增。
   - 全程無回退、無重複、無狀態遺失。
2. **在途查詢 2 秒內安全排空 (In-flight Drain within 2s)**:
   - Wire trace 顯示，中斷發生後所有在途請求於時間窗口內自然排空。
   - 在暫停期間（例如 1789736562.87 至 1789736569.95），線路上完全無任何遙測查詢發送。
3. **前景恢復瞬間清空殘留遙測 (Telemetry Clearing / Probe Guard)**:
   - 應用程式回到前景第一時間進入保護閥門（Probe Guard），清空舊有儀表數據，防止駕駛人或技師看到陳舊之凍結數值。
4. **`ATRV` 鏈路重驗探針 (ATRV Link Revalidation Probe)**:
   - 通訊記錄明確記載，每次 resume 回到前景時均優先發送 `ATRV` 探針以確認配接器連線與電壓穩定：
     - Resume 1: `1789736569.9592881` 發送 `ATRV`
     - Resume 2: `1789736574.397682` 發送 `ATRV`
     - Resume 3: `1789736578.3548238` 發送 `ATRV`
   - 探針驗證通過後，才恢復發送 PID 查詢，無盲目輪詢。

### 4.3 軌道 A 生命週期事件、Logcat 與截圖 1:1 綁定表 (1:1 Binding Manifest)
本表依據 `docs/verification/evidence/d05/d05_bindings.json` 與 `d05_lifecycle_events.log` 完整對齊：

| 序號 | 階段識別碼 | Epoch | 階段描述 | Logcat 對應事件與時間戳記 | 截圖檔案名稱 | 截圖 SHA-256 雜湊 |
|:---:|:---|:---:|:---|:---|:---|:---|
| 1 | `baseline_live` | 0 | 基準活躍狀態：儀表即時輪詢車載遙測數據 | `09-18 21:02:34.453 Fully drawn com.cbstudio.telltale/.MainActivity` | `d05_01_baseline_live.png` | `79c8e51feea3666cb8578240d005eb74c77fb2b9d960aea8af35dbdb2b91e972` |
| 2 | `resume1_probe` | 1 | 恢復 1 探針期：HOME 鍵切回前景，發送 ATRV，儀表數據防殘留保護 | `09-18 21:02:46.769 HOME -> 21:02:47.909 START MainActivity` | `d05_02_resume1_probe.png` | `0e270baea38dd25c46ff760d274e634635e4140593a3bdfd73b971e4b8595969` |
| 3 | `resume1_active` | 1 | 恢復 1 活躍期：ATRV 探針通過，恢復即時數據輪詢 | `09-18 21:02:50Z (Wire ATRV ACK, Live polling active)` | `d05_03_resume1_active.png` | `3f9736eabc1db9672576a267c711b53c99377c85c215fa42a99f8442f9c4935c` |
| 4 | `resume2_unlock` | 2 | 恢復 2 解鎖期：Power 鍵喚醒並解鎖螢幕，執行連線重驗 | `09-18 21:02:50.974 PowerManager Going to sleep -> 21:02:52.533 Waking up` | `d05_04_resume2_unlock.png` | `8be7d30ce940967750f82855c5a6e3d12d54894514ea5aef9616e638ea5b2a4e` |
| 5 | `resume2_active` | 2 | 恢復 2 活躍期：解鎖探針通過，遙測數據穩定更新 | `09-18 21:02:54Z (Wire ATRV ACK, Live polling active)` | `d05_05_resume2_active.png` | `c7405b83bf7d2ffb22cc227e1a002bbbd021820310c5dac4514673a36cf8c88d` |
| 6 | `resume3_final` | 3 | 恢復 3 最終期：完成三次切換循環，介面與通訊全面穩定 | `09-18 21:02:55.317 HOME -> 21:02:56.465 START MainActivity` | `d05_06_resume3_final.png` | `0a72468935ccd7a2a052963e2d8cf8ce2dfa3626be569647a09765e71a68e181` |

---

### 4.4 軌道 B: Mode 08 探索在途 Hold 實測核驗與增量補充 (Track B: Mode 08 In-Flight Hold Supplement)

#### 審計核對事實說明
經對既有 `docs/verification/evidence/d05/` 檔案之獨立通訊審計：
- 既有 `d05_traffic.jsonl` 與 6 張截圖完全對應 Mode 01 即時遙測儀表輪詢（`010C`, `010D`...）之暫停與恢復，具備一般生命週期排空之實證價值。
- 但原約定之 Mode 08 專屬場景要求證明：**「本次 0800/0820 已送達回放端 -> 本次回應被 Hold -> HOME/熄屏 -> 恢復 -> 釋放或取消 -> 同一次 Mode 08 終態」**。
- 遵循誠實核驗原則，既有成果不更名替代，並由本輪完整補充 Mode 08 在途 Hold 實測記錄，以增量補充附件形式交付，完全保持原 `gate2_candidate_acceptance_export.zip`（SHA-256: `bbb685af...`）不變。

#### 軌道 B 實測驗證事實
1. **三次完整循環執行**:
   - **Run 1**: 發送 `0800` 在途被 Wire Gate Hold -> 觸發 `KEYCODE_HOME` 進入背景 -> 狀態機安全排空並重設為 idle -> 返回前景發送 `ATRV` 探針（ACK: `14.1V`）-> 釋放 Wire Gate 延遲回應，系統識別為過期拋棄，狀態保持清潔 idle。
   - **Run 2**: 發送 `0820` 在途被 Wire Gate Hold -> 觸發 `KEYCODE_POWER` 進入睡眠 -> 返回前景螢幕解鎖並發送 `ATRV` 探針 -> 釋放延遲回應並安全捨棄。
   - **Run 3**: 再次發送 `0800` 在途 Hold -> 觸發第二次 `KEYCODE_HOME` -> 恢復前景與最終 `ATRV` 重驗，全程零例外、零崩潰、零死鎖。
2. **增量補充產物清單與密碼學雜湊**:
   - 目錄位置: `docs/verification/evidence/d05_mode08_supplement/`
   - 通訊封包: `d05_mode08_inflight_traffic.jsonl` (SHA-256: `f1745f32915636299faa137ed12ac3c078c4564dae63bdb8be131dcf11bcf655`)
   - 事件日誌: `d05_mode08_lifecycle_events.log` (SHA-256: `365634dfb934ed144a74dc69c87ea51b664c338b8ac8009ec0161c683244f44c`)
   - 階段綁定: `d05_mode08_bindings.json` (SHA-256: `5c6cdfc48e1e1804daf744e7c4c7d29ee65941b3a7229c4184df770b81230f37`)
   - 產物清單: `d05_mode08_manifest.json` (SHA-256: `48fba96f95e3b2a5ae40ee4add14b3e8d4908827edcc7129eaf5fc17660ceb5e`)
   - 補充封裝 ZIP: `export/gate2_d05_mode08_supplement.zip` (SHA-256: `8515177ceeb4fc9c894577347eae082d305f14e9751162243afe18d7d6e2c19e`)

---

## 5. D08 驗收成果：雙語 UI 對稱性與原始協定標記完整性 (D08 Acceptance Results)


D08 實測透過 Android 系統語言設定切換（`en` 與 `zh-Hant`），在相同診斷情境下擷取並排比對截圖，驗證語意完全等價以及不可翻譯標記之不變性。

### 5.1 雙語實測對照分析 (Side-by-Side Verification)

#### 1. 成功狀態 (Success State: `normal_headered_multi_block`)
- **英文介面 (`d08_01_success_en.png`)**:
  - 截圖雜湊: `3fd285e48d5ad74e3ed1f10cb6db4ce2c272f2d2fd8d05e8617d68fff7391db3`
  - 渲染文案: `"ECU supports Mode 08. Supported TIDs: $01, $20, $22"`
- **繁體中文介面 (`d08_02_success_zh_Hant.png`)**:
  - 截圖雜湊: `e9911d76b6fd9770e3804f122a4c1dccc217dba5868c60c9b735cbd8af088205`
  - 渲染文案: `"ECU 支援 Mode 08。支援 TID：$01, $20, $22"`
- **對等性審計**: 晶片元素對應完全一致，語意 100% 對稱。

#### 2. 部分警告狀態 (Partial Warning State: `source_attribution_anonymous_multi_block`)
- **英文介面 (`d08_03_partial_en.png`)**:
  - 截圖雜湊: `0cc468e9701c8e11cfeadc1a413304e5cf7c762f39cd27c225c0cf880c669f7e`
  - 渲染文案: `"Discovery partially completed (Source attribution and coverage unconfirmed: unheadered responses cannot establish cross-block ECU identity). Uncompleted blocks: $20. Note: Not found does not mean unsupported."`
- **繁體中文介面 (`d08_04_partial_zh_Hant.png`)**:
  - 截圖雜湊: `7380307b9dd1b70c849b99c3b00cb5d0c199040b4d8432be62c00d3832e2fd9e`
  - 渲染文案: `"探索未完全完成（來源歸因與覆蓋完整度未確認：無標頭回應無法建立跨區塊 ECU 身分）。未完成區塊：$20。未查到不代表不支援。"`
- **對等性審計**: 核心警語「未查到不代表不支援」與「Note: Not found does not mean unsupported」精確對齊，安全限制說明 100% 等價。

#### 3. 未知 / 拒絕狀態 (Unknown / Refused State: `evidence_conditions_not_correct_nrc22`)
- **英文介面 (`d08_05_unknown_en.png`)**:
  - 截圖雜湊: `c25cc6b540d164a5412079935a89c70c8643197e92fb558f3a58f75c38f00acf`
  - 渲染文案: `"Mode 08 support is unknown: Negative response on block 0x00 from 7E8 (NRC 0x22)"`
- **繁體中文介面 (`d08_06_unknown_zh_Hant.png`)**:
  - 截圖雜湊: `292aae030bad6f167838800b4f52b57a131d0f194087d28f14cb37cae9b4fd2e`
  - 渲染文案: `"Mode 08 支援狀態未知：區塊 0x00 來自 7E8 負回應 (NRC 0x22)"`
- **對等性審計**: 負回應代碼與區塊位址精確映射，診斷意義完全一致。

### 5.2 原始協定標記不變性審計 (`docs/i18n/do-not-translate.md`)
嚴格審計雙語截圖與文案中的協定標記，確認全數未被中文化或語法翻轉：
| 協定標記種類 | 具體標記代碼 | 英文介面表現 | 繁體中文介面表現 | 不變性結果 |
|---|---|---|---|:---:|
| **十六進位區塊位移** | `0x00`, `0x20` | `0x00`, `0x20` | `0x00`, `0x20` | **MATCH (未翻譯)** |
| **測試識別碼 (TID)** | `$01`, `$20`, `$22` | `$01`, `$20`, `$22` | `$01`, `$20`, `$22` | **MATCH (未翻譯)** |
| **UDS 負回應代碼** | `NRC 0x22` | `NRC 0x22` | `NRC 0x22` | **MATCH (未翻譯)** |
| **CAN 控制器標頭** | `7E8` | `7E8` | `7E8` | **MATCH (未翻譯)** |
| **AT 鏈路探針** | `ATRV` | `ATRV` | `ATRV` | **MATCH (未翻譯)** |
| **協定保留關鍵字** | `NO DATA`, `BUFFER FULL` | `NO DATA`, `BUFFER FULL` | `NO DATA`, `BUFFER FULL` | **MATCH (未翻譯)** |

---

## 6. 需求與實證產物完整追蹤矩陣 (Traceability Matrix)

本矩陣將原始需求（ORIGINAL_REQUEST.md）之所有項目與實證產物進行 1:1 嚴密追蹤：

| 需求代號 | 需求規範摘要 | 實證交付項目 / 程式碼行號 | 驗收證據檔案路徑 | 密碼學雜湊 (SHA-256) | 狀態 |
|:---:|:---|:---|:---|:---|:---:|
| **R1** | 候選 APK 隔離存放與文件脫敏發布 | `build/.../app-field-debug.apk`<br>`git commit 0bedd3b` | `export/candidate_apks/app-field-debug-acc80f75b599.apk`<br>`docs/verification/gate2_test_provenance_package.md` | `acc80f75b599d7f85e5c11416ec6c2e92f774f6b9e1699584414ca35abbade9e` | **PASS** |
| **R2** | D02-1 ATH1 協商成功多區塊 7E8 歸因無警告 | `elm327_client.dart` L1587-1643<br>`mode08_discovery_service.dart` | `docs/verification/evidence/d02_1/d02_1_success.png`<br>`docs/verification/evidence/d02_1/d02_1_traffic.jsonl` | `1a77f34f0c0f4118c584298944a120df0b41a738d01340120cdc6cae6c4d765f`<br>`f031d26359eef22d665171fdcc21e42bb81c7c7c1eb2b5379251d7da2ce49f85` | **PASS** |
| **R2** | D02-2 ATH1 拒絕後備保留設定揭示限制不崩潰 | `elm327_client.dart` L2011-2034<br>`service_recipes_screen.dart` | `docs/verification/evidence/d02_2/d02_2_refusal_fallback.png`<br>`docs/verification/evidence/d02_2/d02_2_traffic.jsonl` | `eb908d3f9ffb7383c6910d02285bdb425408446d4f43fdee54fbe82b98f41342`<br>`3448917ded6f1c4f8f9b43da24147b9ce6d3115ef55c8a922a505f53570711df` | **PASS** |
| **R3** | D05-A 三重生命週期韌性、單調 epoch 0->1->2->3（一般儀表輪詢） | `d05_bindings.json`<br>`d05_lifecycle_events.log` | `docs/verification/evidence/d05/d05_bindings.json`<br>`docs/verification/evidence/d05/d05_lifecycle_events.log` | `bc0b9b794109fd5054bbc59e954773d84830c51485cd2c4a3cdc0e98043487ff`<br>`932838e129a476691498a2fd66f217f5dfd72bd6d7babf61b73c09f7fee9df8c` | **PASS** |
| **R3** | D05-A 在途查詢排空、遙測清空與 ATRV 重驗（一般儀表輪詢） | `d05_traffic.jsonl`<br>6 張截圖 1:1 綁定 | `docs/verification/evidence/d05/d05_traffic.jsonl`<br>`docs/verification/evidence/d05/d05_01_baseline_live.png` 至 `06_final.png` | 詳見第 4.3 節 6 張截圖與日誌 1:1 雜湊清單 | **PASS** |
| **R3** | D05-B Mode 08 探索在途 Hold 三重循環中斷排空與過期封包安全捨棄 | `d05_mode08_bindings.json`<br>`d05_mode08_inflight_traffic.jsonl` | `docs/verification/evidence/d05_mode08_supplement/`<br>`export/gate2_d05_mode08_supplement.zip` | `8515177ceeb4fc9c894577347eae082d305f14e9751162243afe18d7d6e2c19e` | **PASS** |
| **R4** | D08 雙語 UI 語意對等 (Success, Partial, Unknown) | `d08_manifest.json`<br>6 張雙語對照截圖 | `docs/verification/evidence/d08/d08_01_success_en.png` 至 `06_unknown_zh_Hant.png` | `3fd285e...`, `e9911d7...`<br>`0cc468e...`, `7380307...`<br>`c25cc6b...`, `292aae0...` | **PASS** |
| **R4** | D08 原始協定標記 100% 原樣保留 | `docs/i18n/do-not-translate.md` | `docs/verification/evidence/d08/d08_manifest.json` | 原始標記 (`NO DATA`, `0x00`, `NRC 0x22`, `7E8`, `ATRV`) 完全匹配 | **PASS** |
| **R5** | 完整導出包與外部校驗清單 | `gate2_candidate_acceptance_export.zip`<br>`hashes.sha256` | `export/gate2_candidate_acceptance_export.zip`<br>`export/hashes.sha256` | `bbb685afb4916cd336fe3db7f316ecdbf5de980dabfc645456861485336e3cef` | **PASS** |

---

## 7. 獨立複核與重現方法 (Independent Reproduction Guide)

審計員（`teamwork_preview_auditor`）或外部評審人員可透過以下指令獨立校驗所有交付產物：

### 7.1 校驗實證目錄雜湊清單
```bash
cd docs/verification/evidence
shasum -a 256 -c SHA256SUMS
```
*預期輸出：37 個檔案全數回傳 `OK`。*

### 7.2 檢驗 D05 生命週期 1:1 映射
```bash
# 檢查綁定 JSON
cat docs/verification/evidence/d05/d05_bindings.json

# 檢驗 Logcat 中斷與恢復事件
grep -E "ActivityTaskManager|PowerManagerService" docs/verification/evidence/d05/d05_lifecycle_events.log

# 檢驗 ATRV 探針發送次數與時序
grep "ATRV" docs/verification/evidence/d05/d05_traffic.jsonl
```

### 7.3 檢驗 D08 協定標記不變性
```bash
grep -E "0x00|0x20|NRC 0x22|7E8|ATRV" docs/verification/gate2_device_acceptance_report.md
```

### 7.4 失效條件 (Invalidation Conditions)
若出現下列任一情況，本驗收結論即刻失效：
1. 候選 APK SHA-256 不等於 `acc80f75b599d7f85e5c11416ec6c2e92f774f6b9e1699584414ca35abbade9e`。
2. 實證截圖或日誌之 SHA-256 與 `SHA256SUMS` 清單不符。
3. D02-1 出現 `partial_warning`，或 D02-2 發生 App 崩潰。
4. D05 `pauseEpoch` 發生倒退或恢復時未發送 `ATRV` 探針。
5. 雙語介面中原始協定標記（如 `NRC 0x22`）被翻譯為非 ASCII 協定字串。
