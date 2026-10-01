Mr78 Postmerge Review and Issue101 Execution Card.zh TW
MR !78 合併後複核與 Issue #101 執行卡

日期：2026-09-27（Asia/Taipei）
專案：aa22396584/telltale，Project 86385809

0. 裁定

不予 MR !78 / 72a618ba SIGNED-OFF；承認 source CI 成功與已合併事實。
這不是重新執行原生驗收，也不是補發 C1a 或整個 #36/#40/#34 的接受。

本輪 GitLab 讀回：!78 已於 2026-09-27 19:09:17 台北時間合併。

Source SHA：72a618ba6a3524c713427987857aaca364f41ebc
Squash SHA：966ecb79c67ac41a8f6cad96f05c25d2ba206c1b
Main merge SHA：c39efcd270fba83128ffd84db0b26b1cb9a8efae
Source pipeline/job：2886788770 / 16762044715，SUCCESS，1537.48095 秒。
Main pipeline：2886819993，最後讀回 RUNNING，綁定 c39efcd2。
原 BASE 8adb3fd6 的 pipeline 2886737458 仍為 FAILED。
straight compare 72a618ba → c39efcd2：diffs=[]，compare_timeout=false。

因此新增的是 CI 完成與 merge 記錄，不是前次 CHANGES REQUESTED 後的修補版本。
不倒填簽核，不要求僅因審查尚未完成便自動 revert 全部歷史；採具名最小 post-merge repair。
其他工作可以準備與測試，不能把尚未完成的 main gate 或 native cases 填成 PASS。

來源：[G1][G2][G3][G4]。JSON 附件是本輪選取欄位與已核對摘錄，不是完整原始 API dump。

1. CI 證據的實際範圍

Job 16762044715 trace：

Flutter 3.47.0 / Dart 3.13.0，analyze 0 issues。
Python tools 759 OK；Mode08 Python 17 OK。
Flutter 3864 passed / 23 skipped / 0 failed。
Native CTest Debug 11、Release 11；l10n-required 12/12。
assembleFieldDebug 完成三個 ABI APK；artifact upload 成功。
最終行：
“All gate commands and required replay passed. This is NOT Android device acceptance.”

759 是全域 Python tools 計數，不是 test_android_locale_candidate.py 一檔的計數。
本輪沒有下載 APK bytes 或獨立重算 APK SHA-256，不能把建置與 upload log 當作 binary 審查。
普通全域 suite 的 23 skips 必須和各 required lane 分開；不是「全部案例零跳過」。
來源：[G2][G10]。

2. 延續既有 R78-1～R78-3，不重開新一輪無界審查
R78-1：候選參數與執行路徑

固定 source 的 main() 解析 --profile、--candidate-apk，卻沒有讓它們決定 candidate 執行或核對 APK。
離線 dispatcher 依待驗 report.profile 選 validator；缺少 candidate profile 可落回 legacy。
live --execute 仍走 legacy _execute：固定 .rig、shell 補 LocaleConfig、force-stop/relaunch。

修法：

expected profile 由 CLI／受控 run manifest 決定，待驗報告不能選擇較弱 verifier。
candidate mode 必須核對實際 APK 與獨立期待值、target manifest、原始資源。
candidate executor 未實作時，裝置寫入前回 NOT_RUN/NOT_IMPLEMENTED、非零；不能退回 legacy 成功。
--report 若只是 schema 檢查，就只輸出 SCHEMA_VALID，不得輸出 native ACCEPTED。
legacy 歷史流程與證據標籤保留，不把它重新命名為新候選完成。
R78-2：報告與證據不能互相自證

僅有 true flags、SHA 字串、case 名稱與輸入的 ACCEPTED，不能證明原生執行。
原先指出的 de 必需語系、40-hex Git identity、exit 型別、duplicate keys 等防線仍需封閉。
應分開 schema、raw evidence integrity、候選身分與審查接受；摘要由證據衍生，不是自行宣告。

N00～N07 必須映射原 N-L01～N-L06，不能以 process_recreated 或 state_retained 單一布林
代替 configuration change、Activity recreation、process restart，以及 draft/recording/share 各自的證據。
有效 Flutter locale 與 persisted preference/migration/reconcile 狀態亦不能混成一個抽象欄位。

文件的未執行 cases 改 NOT_RUN；已聲稱執行但缺原始證據的欄位改 PENDING_EVIDENCE。
保留真實歷史檔案，不覆寫已存原始失敗記錄；新增有日期的更正與 successor mapping。

R78-3：時間裕量不是階段證明

目前 R11 固定 source 實際為：

engine.readDtcs(...)，caller deadline 450ms。
先保存 expectLater(read, throwsA(anything)) 的 Future。
delay 300ms → markAlive() → await expectation。
fake reply 480ms。

不是這次封包所寫的 await expectLater(client.sendGlobal(...)) 搭配 500ms。
「先掛 expectation」與「先 await 到它完成」不是同一個時序：不能先等操作結束才觸發 resume。

R11 需要 Mode03 已送、markAlive 當時仍為該 pending、指定 timeout phase，以及移除 clamp 會失敗。
R15/R13 需要實際 resync 進入、watchdog 關鍵 tick、grace 內恢復與到期終止的正反控制。
250～300ms 只能增加裕量，不能保證任何 CI 排程下 100% 到达 _resync。

先對帳既有 Draft !65 的同題修補與 mutation 主張；本輪沒有簽核 !65，不能盲目 cherry-pick 或關閉它。
保留原有產品 timeout/guard，避免讓 !78 的測試修正被當成 #106 已修好。
官方 Timer 語意：[D2]。原固定 source：[G5]；!65：[G11]。

3. 最短 post-merge repair 卡

Task：TELLTALE-R78-POSTMERGE-EVIDENCE-REPAIR
Branch：fix/l02-candidate-evidence-postmerge
Refs：#36, #40, #34；追蹤 R78-1～R78-3。
Base：開工時讀取 current main，保存 SHA/tree 與 gate 真實狀態，不使用浮動 main 當證據身份。

預設修改白名單：

tool/l10n_rig/android_os_locale.py
tool/l10n_rig/run.py
test/tool/test_android_locale_candidate.py
test/tool/test_android_os_locale.py
test/tool/test_l10n_rig_run.py
docs/verification/l02-candidate-native-locale.md
docs/verification/batch1l-c1b-native-locale.md
docs/verification/mr78-postmerge-disposition.md（新增）

時序修正可以由單一 OBD owner 另開窄 MR，與 !65 對帳；不要和 #101 同時編輯 client。
本卡預設不改 lib/、Android 生產 manifest／Activity、SDK、release／簽章、設備設定或 Runner。

有限出口：C1B_N1_TOOLING_REVIEWED。
要求 profile 路由、失敗分類、schema/integrity 負控制及文件一致；不要求沒有裝置時假造 native PASS。
真正 NATIVE_OS_LOCALE_ACCEPTED_FOR_TARGET 留待具名候選與 OS run 證據後獨立審查。

4. Issue #101 現況對帳

[G6] 是現行 Issue 的四項有限 acceptance；硬體不是這個 software contract 的前置。

本輪已確認：

4c575f634040ef3db546063fdc73f69f343fc059 可取得；該 commit API 的 last_pipeline=null。
這不代表從未測過，只代表本次該欄位没有提供 pipeline 證據。
c39efcd2 已有 ElmWriteAudit、_claimWriteAudit、beginWriteAudit、wroteSinceAudit。
_claimWriteAudit 拒絕不同 client 或已 claim 的 receipt，並在合法 claim 後消耗它。
_sendNow 將 command 放入本 receipt，在 WriteRefusedException 時僅撤回本次新增值。
clear 與 poll 呼叫顯式傳入自己的 writeAudit。
test/write_audit_window_test.dart 已有 queue borrowing、creation order、foreign/reused token、
legacy 同步拒絕消耗與 BusProtocol.values 的合成覆蓋。
關鍵 claim/inspection 函式的當前 blame 指向 974a4fc78838cbb9c5c10b14b1331e5e57a58d61。

這些是 source 存在與接線的確認，不等於原 #384 審查／59 tests／歷史交付已完整對帳，
亦不等於本輪已跑 #101 測試。不能為了「落實架構」再製作第二套 receipt manager。
來源：[G6][G7][G8][G9]。

5. 正式 Execution Card — #101
5.1 身分、範圍、非目標

Task ID：TELLTALE-101-OPERATION-RECEIPT-CLOSEOUT
Branch：test/obd101-operation-receipt-closeout
主責：#101；Parent #100；Refs #101, #100。
不提前寫 Closes #101。

第一個 commit 凍結 BASE SHA/tree、四項 issue acceptance、現有 case mapping、white/denylist。
c39efcd2 可以作研究／開發基準；其 main gate 最後讀回 RUNNING，不能寫 accepted PASS。
開工若 main 已更新，重新固定，不繼承舊 SHA 的接受或 APK hash。

非目標：
不做 #106 根因推定，不改 fastMode 算法，不新增診斷 recipe／raw／manual／remote 入口，
不新增 ECU actuation 權限，不以 receipt 當 consent，不擴充 persistent audit database。

5.2 白名單

預設（測試與交付）：

test/write_audit_window_test.dart
test/support/fake_elm327.dart（限有界 barrier、fault 與獨立 wire 觀測）
test/mode01_batch_observation_test.dart（限既有 consumer 意義）
test/write_audit_consumer_journey_test.dart（必要時新增；有既有等價 owner 則不重複）
docs/verification/issue101-operation-receipt-closeout.md（新增）

唯有 red test 證明既有產品缺口才開啟：

lib/obd/elm327_client.dart（receipt claim/handoff/inspection 的最小範圍）
lib/obd/polling_engine.dart（clear/poll 對 receipt 的 consumer）
lib/obd/transport/obd_transport.dart（只有確實需要修正 zero-byte 合約時）
docs/privacy/sdk-audit-receipt.json（受審源碼改動所需的對應 digest）
docs/i18n/glossary.md（只有已被移動的既有 source anchor）

其餘檔案先只讀；必要扩充先在執行卡列明 failing case／owner，不做全目錄格式化。
test/round5_triggers_test.dart 與 test/lifecycle_test.dart 作必跑相關回歸，預設不在本卡改時序。

Denylist：
全域 timeout/retry/watchdog 調整、刪 guard、寬鬆 parser、production fake/native mock，
Android/iOS plugin/SDK 升級、依賴與 lock 大改、任意 clear/Mode08 實機實驗，
主網／實車／BLE／Wear 資格宣稱、公開私密 VIN/MAC/raw transcript，
更改 Runner/CI secrets、商店 upload、另開 private product PR。

5.3 架構契約：歸屬不等於結果

沿用一份 client-owned、single-use receipt 綁一個 admitted public send。
一個 public send 內的 header/setup/service/restore 可共用 receipt；不能因此授權第二個 public send。

必要概念狀態（不是要求新增公共 enum 或替換既有 API）：

OPEN
→ CLAIMED / QUEUED
→ REFUSED_BEFORE_HANDOFF
→ HANDOFF_PENDING
→ PROVEN_ZERO_BYTE_REFUSAL
→ MAY_HAVE_BEEN_SENT
→ 對應操作終止；receipt 不再能 claim

證據可以在精確 zero-byte refusal 時撤回本次暫記；不能撤回同 receipt 的先前寫入，
不能修改其他 receipt，也不能讓已消耗 token 因失敗復活。
拒絕 foreign token 時，不污染它在原 owner 的 evidence。

wroteSinceAudit(receipt, command)：

未派發、未 settle 的 false 是「目前未見」，不是未送出的最終結論。
handoff 後 true 只表示保守寫入證據，不等於完整 bytes、ECU accepted、或 ECU completed。
setup/restore bytes 不等於服務 bytes。ATH1/ATSH/ATH0 存在，不代表 04 曾交付。
原有 normalize 語意保留，但不能用 command string 作跨操作 identity。
receipt 不是 ownership/consent/generation 檢查的替代品。

三個完成點分開：

UI/caller wrapper Future 結束。
對應 send 的派發資格已終止，該 service 不會再新派發。
既有 transaction restoration／底層未完成 write 的後續狀態已可交代。

Future.timeout 不取消 source future；超時後顯示 outcome unknown 不需要無界等待，
但不能因 wrapper 已結束就宣告 source 沒送出。[D1]
保留目前既有 cleanup 次序與合理 restore；不得為了宣告 receipt 完全凍結而另造一套交易流程。
若測 ATH0/全部 receipt bytes 的終態，用有界 cleanup barrier；
不要只 await UI future，也不要加一個真實額外 OBD 命令只為測試同步。

5.4 W101 驗收矩陣
Case	測試目標	必要觀測
W101-01	歷史 repair 與 current source 對帳	原 commit、現行承接 commit/函式、逐项 acceptance、現行 case；未知歷史只標未知
W101-02	同／不同 command 的 A/B 隔離	A/B 的建立、queue、執行順序交错，兩份 receipt 與實際 write 歸屬正確
W101-03	確實排隊而未 dispatch	barrier 證明 blocker 已 entered、B 已 queued；false 不被當最終 unsent；釋放後只有 B 收到自己的 evidence
W101-04	single-use	排隊中重用、完成後重用、legacy 同步拒絕後重用皆拒絕；無額外 wire；fresh receipt 的正控制能正常用
W101-05	foreign token	use/read 都拒絕，原 owner evidence 不變，不污染本 client；合法對照成立
W101-06	pre-handoff retirement	owner/lifecycle/generation 退役時，該 queued service 零新增交付；新 generation 不被舊 callback 關閉
W101-07	proven-zero rollback	真正的 transport precondition refusal，acceptedBytes=0；撤回僅本次暫記，token 維持 consumed
W101-08	partial / unknown	partial bytes、接受後拋錯、flush timeout／completion stall 保持保守；沒有自動 replay
W101-09	timeout / late completion	caller wrapper 超時與實際 source 分開；晚回覆／底層完成不重播、不借給新操作
W101-10	setup / service / restore	header refusal 與 service possibly-sent 分開；restore 不抹除先前 service 證據；清理 barrier 與 finally 完成可觀測
W101-11	真 consumer	engine 的 clear 風險旗標與 polling observation 使用自己的 receipt；later polling 不解鎖 unknown clear；UI 若涉及需走既有真 consumer
W101-12	gate 與資源收尾	新增 required cases 零 skip，缺 case／錯退出／截斷結果不能宣告PASS；每一測試有 teardown，無殘留 timer、subscription、child

不必做全部 case × 全部 protocol 的笛卡兒積。
保留現有 BusProtocol.values 的合成 happy-path，故障覆蓋至少涵蓋 CAN 與有獨立 refusal/restore 分支的 legacy。
分開 transport.write 呼叫次數、實際接收的 bytes、完整 command 數；partial write 可能沒有完整 command，
不能因 completeCommandCount=0 就宣告 zero-byte。

測試使用 literal expected values／独立 spy，不讓同一套 helper 同時生成 expected 與 actual。
每個 fault 必須驗證它真的在預期 command／phase 觸發；入口就失敗不充當深層 guard 被驗證。
提前綁 Future 錯誤監聽，採 request-entered、queue-release、write-result 等 bounded barrier。
若 clock 可注入，clock 與 timer 同一時間域；不要只改 DateTime 又讓 Timer 走 real clock。

5.5 有限 mutation 證明

至少以下五種 semantic mutations，按實際 owner 選精確 anchor：

M101-1：讓另一 operation 的同命令寫入污染 receipt。
M101-2：移除 single-use 或 foreign-client 檢查。
M101-3：改成 write 完成後才記錄，造成 pending/partial evidence 消失。
M101-4：把一般 transport error/timeout 當 zero-byte rollback。
M101-5：consumer 把未 settle 的 false 判成未送，或讓 later poll evidence 取代 clear evidence。

每種先確認 mutation diff 真正生效；比較同一 scoped case 清冊。
compile fail、runner找不到檔案、privacy digest drift、setup fail 不算 semantic kill。
還原后同清冊必須再次綠燈。Mutants 只在隔離 worktree、純軟體 transport 跑，
不能進 main/candidate 或接任何實體設備。
本要求承接 CONTRIBUTING 的既有 mutation 契約。[G10]

5.6 命令與 CI

以 repository pin Flutter 3.47.0 / Dart 3.13.0 起跑；BASE 若有正式 pin 改動則依該版，
不因別的專案使用較新版本而混用。以下是執行卡命令，不是本輪已執行：

Bash
set -euo pipefail
fvm flutter --version
fvm flutter analyze
python3 tool/workshop/validate_privacy_contract.py --repo-root .

fvm flutter test \
  test/write_audit_window_test.dart \
  test/mode01_batch_observation_test.dart \
  test/round5_triggers_test.dart \
  test/lifecycle_test.dart \
  test/obd_session_test.dart \
  --reporter json

若新增 consumer journey，將其實際路徑明列加入命令，不能只靠未發現的檔名或固定測試總數。
保存 stdout/stderr/原始exit與 case清單。現有 full gate 仍需執行，不把 focused 測試取代全門禁。

依 CONTRIBUTING：

改 lib/obd/ → 必跑適用 Ircama oracle。
動到 socket framing／timeouts／init → 加 TCP chaos oracle。
不把專案自製 fake 宣稱第三方 oracle，更不宣稱實體驗收。
UI 有改才追加受影響畫面的真路徑 walk；純receipt補測不擴成全App UI campaign。

優先利用现有 CI case/exit 工件；只有實際證明 lane 無法發現缺案例時才開具名 gate 修正，
不為本次 closeout 再做一套重複通用 verifier 或 CI 平台。

5.7 交付與結案

每份證據帶 source SHA/tree、SDK、命令、原始exit、case清冊、控制/mutation結果、artifact hashes。
新增 manifest 的 expected cases 固定且由獨立可審來源決定，不由結果自己生成。

出口順序：

OPERATION_RECEIPT_SOFTWARE_ACCEPTED：目前 source 契約、consumer 與 required cases／mutation 通過並經審查。
OPERATION_RECEIPT_DELIVERED：accepted exact-head 合併，actual-main gate通過，source/squash/main 對帳完成。
ISSUE101_COMPLETE：原四項 acceptance 各有現行證據與交付映射，才關 #101。

若實作完全正確，只補 tests/docs／closure evidence 是合格交付；不為了讓 MR 有產品 diff 而重寫。
#101 不需要等 #36 原生完整矩陣、#106 reporter 回覆或實體 Wear/車輛。
反之，本卡亦不提供 #106 修復、#34全Epic或任何hardware資格的結案證據。

合併只針對新 MR 已審 SHA：執行時核對 current source SHA、required CI、unresolved review／approvals。
merge API 用 source sha 與 squash=true；SHA mismatch 停止，不去掉sha重試。[D3]
合併後記錄實際 squash/main SHA，不能把 source SHA 當 main SHA。
本卡是規劃，沒有執行遠端 merge、CI派發或Issue關閉。

6. 工作順序

A. 先封閉 R78 candidate 路徑與不實接受標籤；時序缺口由單一 OBD owner 與 !65 對帳。
B. #101 可平行做 source mapping／測試；若要改 shared client，與 A/#106串行合流。
C. #106 延續先前 causal-triage 卡，未知根因不先改 MTU/watchdog，不以 #101補測等於修好。
D. #36/#40/#34 維持既有未完成責任；本輪不做全域 backlog 重新排序或遠端狀態變更。

7. 本輪可稽核來源

[G1] MR !78（本輪 GitLab get_merge_request）

https://gitlab.com/aa22396584/telltale/-/merge_requests/78

[G2] Source job 16762044715（get_job、get_job_trace；trace讀取從 byte 12000至末尾）

https://gitlab.com/aa22396584/telltale/-/jobs/16762044715

[G3] Source → main straight compare（diffs=[]，未逾時）

https://gitlab.com/aa22396584/telltale/-/compare/72a618ba6a3524c713427987857aaca364f41ebc..c39efcd270fba83128ffd84db0b26b1cb9a8efae

[G4] Main pipeline與原BASE pipeline（各自 get_pipeline）

https://gitlab.com/aa22396584/telltale/-/pipelines/2886819993

https://gitlab.com/aa22396584/telltale/-/pipelines/2886737458

[G5] 原固定 source（前輪完整來源已在對話；本輪送審SHA未變，且straight compare確認合併樹無差）

https://gitlab.com/aa22396584/telltale/-/blob/72a618ba6a3524c713427987857aaca364f41ebc/tool/l10n_rig/android_os_locale.py

https://gitlab.com/aa22396584/telltale/-/blob/72a618ba6a3524c713427987857aaca364f41ebc/test/round5_triggers_test.dart

[G6] Issue #101及歷史repair commit（本輪get_issue / get_commit）

https://gitlab.com/aa22396584/telltale/-/work_items/101

https://gitlab.com/aa22396584/telltale/-/commit/4c575f634040ef3db546063fdc73f69f343fc059

[G7] 現行 client（本輪search與blame，1476–1563、5328–5365）

https://gitlab.com/aa22396584/telltale/-/blob/c39efcd270fba83128ffd84db0b26b1cb9a8efae/lib/obd/elm327_client.dart

[G8] 現行 consumers（本輪search：clear 2520起、wroteSinceAudit 2549起，poll 4171起）

https://gitlab.com/aa22396584/telltale/-/blob/c39efcd270fba83128ffd84db0b26b1cb9a8efae/lib/obd/polling_engine.dart

[G9] 現行既有receipt suite（本輪完整get_repository_file_raw）

https://gitlab.com/aa22396584/telltale/-/blob/c39efcd270fba83128ffd84db0b26b1cb9a8efae/test/write_audit_window_test.dart

[G10] CONTRIBUTING（本輪完整get_repository_file_raw；其中歷史skip數不作當前CI實測值）

https://gitlab.com/aa22396584/telltale/-/blob/c39efcd270fba83128ffd84db0b26b1cb9a8efae/CONTRIBUTING.md

[G11] Draft !65（本輪MR搜尋讀回描述；不是其程式碼的獨立簽核）

https://gitlab.com/aa22396584/telltale/-/merge_requests/65

[D1] Dart Future.timeout

https://api.dart.dev/dart-async/Future/timeout.html

[D2] Dart Timer.periodic

https://api.dart.dev/dart-async/Timer/Timer.periodic.html

[D3] GitLab merge requests API

https://docs.gitlab.com/api/merge_requests/

本輪未執行 Flutter/Dart/Python反例重跑、native/device操作、APK重新雜湊、
repository／Issue／approval修改、merge、CI派發或Runner變更。
