Batch1l C1b N1 Execution Card 8adb3fd6.zh TW
Batch 1L-C1b-N1 — Android 原生語系候選驗證執行卡

日期：2026-09-27（Asia/Taipei）。
研究來源：8adb3fd66588001075054e21f94c5a7e6bb23859。

本卡是規格與方向確認，不是已執行驗收或新的 C1a 簽核。Native cases 初始均 NOT_RUN。

1. 身分與有限退出
Branch：test/i18n-c1b-native-locale-proof。
主责：#36；Refs #36,#40,#34。#24彙整native資格，#48/#72消費候選聲明。
第一個target：一個已明確授權、可拋棄的AOSP API33+ emulator；固定實際API/system-image/fingerprint/ABI/current Android user。優先以已有可用且支援之target完成，不升級SDK只為選最新。
候選：明確的field debug APK，或另行明訂的候選variant。任何test-entry APK分開識別。
退出建議值：NATIVE_OS_LOCALE_ACCEPTED_FOR_TARGET，必附target/candidate/profile。不可簡寫成全Android NATIVE_QUALIFIED，不充抵physical BLE、Wear、API32、iOS/desktop或release。
Formal BASE：8adb3fd6的exact-main目前FAILED；本卡可以準備/實作，正式接受的BASE狀態不得提前填PASS。C1a source/visual review亦需保留其原本獨立對帳，不因merge自動追認。
#36/#40/#34仍OPEN；個別原生格完成可以獨立簽核，不以所有平台/實體設備未到無限阻擋這一格。
2. 不可混用的現有證據
現有項目	能證明	不能證明
integration_test/locale_platform_test.dart	兩項planSync軟體語意	真的啟動App、LocaleManager、Settings或OS recreation
test/l10n/platform_locale_bridge_test.dart	假OS／adapter／guard回歸	原生事件與候選binary資格
C1a root widget suites	Production Dart journey的受控軟體行為	實體BLE或Android OS事件
舊android_os_locale.py	其具名rig/process-restart歷史scope	本次field APK、原始LocaleConfig、不中斷錄製
新external candidate lane	被核對APK的系統設定/UI/重新啟動	尚未觀測的內部狀態或其他build
新instrumented lane	真Android Activity/LocaleManager與必要內部觀察	自動等於既有field APK之相同bytes

保留舊測試與真實scope，不刪改歷史測試來把它們重新命名為native。

3. 測試控制架構
Plain text
具名candidate/target manifest
  → Host側有界controller（不隨App process死亡）
      → 原APK的OS Settings / UI Automator / UI檢視
      → 必要androidTest instrumentation／只觀察的test probe
      → 真MainActivity → 真MethodChannel → 真locale owner
      → 真本地store；Demo或受控software peer（明确source）

Native acceptance不安裝mock MethodChannel，不把AppLocalesPlatform.get/set換成fake，不呼叫Dart lifecycle callback冒充OS事件。OS/error-storage拒絕難以在正常OS製造的案例保留為具名fault-injection lane，和正常native完成分開。

UI Automator可操作系統Settings與目標App；使用實際資源/semantics定位並驗證目標package，不用固定座標或「找到en文字」就認定設定成功。若使用cmd locale，先以該target的help/實際回應核對子命令與權限，不假設所有API33+版本皆支援舊shell參數。[S4]

3.1 兩條binary證據線

A. Candidate external lane：安裝/使用明確hash的既有field APK，由host及外部UI自動化操作。記錄安裝後package/version/signature/code paths與原APK的關係。

B. Instrumented native lane：需要ActivityScenario/精準內部barrier時，記錄target app APK及test APK兩個hash、Dart entrypoint與instrumentation runner。若Flutter integration_test重建了test-entry APK，不聲稱它就是A的原APK。可用同一source構建並連結證據，但不能合併兩個artifact identity。[S5]

正式process-death測試不得只把控制器放在將被殺掉的App process內。ActivityScenario.recreate()可驗真Activity save/destroy/create，不等於process death；呼叫後不要沿用舊Activity引用。[S3]

4. 檔案邊界
優先重用/窄改
tool/l10n_rig/android_os_locale.py、tool/l10n_rig/run.py：如擴充，新增明確candidate profile與參數，不默默改掉既有legacy lane語意。不得直接重用其force-stop/LocaleConfig補寫作為所有case的共同前置。
integration_test/locale_platform_test.dart：保留software回歸或清楚分組；不以路徑名稱提升證據層。
integration_test/localization_journey_test.dart、integration_test/rig_support.dart：只改本次必需target/entry/observation子集合。
test/l10n/platform_locale_bridge_test.dart：若共用adapter有必要修正，保留舊truth-table及false/throw/unsupported/mismatch/pending回歸。
既有record/export/replay/lifecycle integration只做必要case reuse與artifact mapping，不整批重寫。
可以新增的具名檔案
integration_test/native_locale_journey_test.dart：實際native binding、真main入口與具名cases；已有同義suite可擴充而不重複。
android/app/src/androidTest/kotlin/com/cbstudio/telltale/LocaleLifecycleInstrumentedTest.kt：只負責本次native locale/lifecycle觀察與控制。
test/tool/test_android_native_locale_candidate.py：只測新增candidate runner契約；若現有套件已有對應owner就原地擴充。
docs/verification/batch1l-c1b-native-locale.md：本卡的candidate、truth table、case/command/結果與residual。
tool/l10n_rig/native_locale_candidate.py：僅當擴充既有legacy runner會混淆其歷史契約時，允許這一個受限candidate executor；它與既有runner的candidate mode二選一，不建立兩套相同流程。

第一個commit凍結實際allowlist與CLI。上列可新增不是要求每一檔必須有修改。

原則只讀；重現缺陷後才具名窄修

MainActivity.kt、AppLocalePolicy.kt、AndroidManifest.xml、locales_config.xml、app_locales_platform.dart、Dart synchronizer/controller/plan。不得改FlutterActivity繼承、刪configChanges來製造recreation、放寬guard、調大500ms adapter timeout或替换SharedPreferences框架來換PASS。

禁止範圍

SDK全量升級、release簽章/keystore、商店upload/tag、host root/sysctl/DNS/安全策略、production設備wipe/pm clear/uninstall、任意ADB命令入口、Mode04/Mode08/寫ECU、實車與實體Wear資格。不得force-stop其他共用系統App作為清理捷徑。

5. 前置安全與candidate identity
工程批准精確target、APK、安裝/設定/重啟能力；沒有授權只讀檢查，NOT_RUN/BLOCKED，不自動尋找另一台裝置。
serial不是權限或身分的充分條件。核對AVD/system-image/fingerprint/API/ABI/current-user與run manifest；不要只信emulator-5554或手機外觀。
field=com.cbstudio.telltale；rig=com.cbstudio.telltale.rig。現有wear同applicationId，不能只以package宣稱phone variant。
從實際APK讀versionCode/name、ABI、merged manifest、localeConfig、signing certificate與SHA-256。此repo的ABI versionCodeOverride=base*10+ABIcode；不只讀pubspec，也不沿用Gradle comment的另一種計算。
確認安裝物與送驗artifact。若從CI source APK取樣，而main又重建出不同APK，兩者各自記錄；同TREE不保證zip byte-identical。
簽章不合或已有使用者資料時停止，不能先uninstall讓安裝成功。乾淨測試使用明確授權的新disposable AVD，不破壞既有field installation。
native localeConfig驗收禁止先用shell set-app-localeconfig修補候選，否則只驗到override結果。需要測runtime override時另標case，還原已觀測原值，不能默認清成空。
所有已授權改動都要有before/after與有界cleanup；只回收本次資源。清理失敗也保留結果，不覆寫既有成功歷史。

可讀取的官方工具包括apkanalyzer與apksigner；本卡沒有執行這些命令或任何APK檢查。[S6][S7]

6. 四層locale truth與生命週期分類
6.1 分開記錄
applicationLocales：OS per-app override，空list表示跟隨系統。
systemLocales：未被App override替換的system list；由受測foreground user的OS authority觀測。
configurationLocales與Flutter resolved locale：本程序實際收到/使用的有效設定。
persisted preference / migration / acknowledged write / needsReconcile：App持久化與協調狀態。

不要要求四層字串字面永遠相同：system偏好與空override可合法對應有效UI=de；de-AT映射為de，zh-Hant-TW映射為zh-Hant，storage的zh_Hant也是既定編碼。先固定獨立truth table再比較。

OS設定en/zh-Hant/de、App picker反向設定與Reset-to-system，各有真正入口。getSystemLocales()忽略App override；不要用已override的configuration/Locale.getDefault去猜原system list。[S1]

使用非英文system正控制：system=de、override=[] → UI=de；再依授權改system=zh-Hant → UI=zh-Hant。只有system=en時清空override看到英文，不能证明follow-system映射正確。

system=[ja]且App沒有日文時，UI依既定fallback顯示en可以合法；override仍須空、偏好仍system，不能悄悄persist en。OS明確unknown override與App主動送unsupported tag也是不同測試：前者保留authority、不擅自覆寫；後者依現有policy拒絕。

6.2 三種事件分列
事件	如何驗證	不得宣稱
實際locale configuration change	OS前後值、configuration事件、UI；記錄Activity/PID是否改變	不必然有Activity新實例
明確Activity recreation	native instrumentation驅動實際save/destroy/create、identity變更、恢復	不是process death，也不是自然locale必然造成
process stop/death＋relaunch	外部controller、PID/啟動代次、原始檔/恢復狀態	不是不中斷錄製；force-stop不是LMK同義

現有manifest處理locale/layoutDirection；尊重它，先量測實際生命週期。對locale不recreate的結果不要判fail，也不要去掉configChanges改造測試目標。[S2][S3]

7. N-L01～N-L06 凍結矩陣
N-L01 — Candidate、原始宣告與啟動
真APK與testAPK（若有）完整身分；有效manifest含localeConfig；原始compiled resource的en/zh-Hant/de與native/Dart resolver一致。
對同一APK從真launcher啟動，在未連車/未VIN/未permission時看到Language。
至少錯APK/hash/package/ABI/target與缺工具負控制應由對應preflight拒絕；不要改目標去適配wrong artifact。
各測試記載是否外部candidate/原生instrumentation/軟體fake，不混合成同一次run。
N-L02 — OS ↔ App 與 Follow System
OS Settings中選en/zh-Hant/de，返回App驗有效UI/OS/store；App picker切換再由獨立OS觀察readback。
follow-system至少使用非英文system；含supported locale list順序與region/script normalization的有限控制。
app setter unsupported/mismatch用真bridge適用case與既有software負例分層；不能在unsupported時假稱OS API成功。
不在測試之前override LocaleConfig來補洞；de只認證同步/呈現機制，不宣稱母語品質審核。
N-L03 — Resume、遷移、時序與重建
程式先穩定在en；由OS改de，再resume；驗證舊prefs不寫回OS，非由startup恰巧已完成代替resume。
新fresh follow-system不得憑空handoff舊語言；legacy explicit preference在適用OS第一次確認後才完成marker；marker=true後OS後續選擇權威不被舊值蓋掉。
真migration最好使用已識別同簽章前版建立偏好後upgrade；若採專用測試資料注入，標synthetic migration setup，不宣稱已做真舊版升級。
兩次有限快速選擇、回到App/設定頁、post-frame/resume交錯：末次適用意圖與authority一致；getter可多次但有界，無echo setter loop。不要硬套所有排程getter只能+1。
明確Activity recreation獨立case；process restart作具名子case。既有migration false/throw/unsupported/pending軟體回歸保留。
N-L04 — Dirty、recording、pending share 與恢復
同Activity configuration change：dirty內容、selection/位置及當前工作owner維持；App內picker的dirty/recording/artifact guard仍阻擋不安全改變。
OS Settings是外部authority；App guard不能保證阻止使用者更改OS。回App時依既有owner保留、延後呈現或如實checkpoint/recover，不在blocked時自動寫回OS試圖撤销。
明確recreation／restart：凍結原本可保留/可恢復的狀態承諾；dirty draft不能靜默變空並冒称恢復。若原契約要求保留而丟失，該case FAIL並獨立小修，不用NOT_RUN掩蓋。
錄製可以依既有契約checkpoint/recover；驗證sessionID/已記錄事件、partial/gap/footer/狀態，不能將中斷檔標completed，不能補造丟失測量。
加一個既有pending share/staging owner代表case，驗證owned資源/guard與unknown outcome；不新增報表或exporter。
process death的零遺失不是本卡新承諾；force-stop前未提交RAM資料不能被宣稱已持久化。可以truthful recovery不等於允許任意丟失既定保障。
N-L05 — 零非預期副作用
無線/未連線控制：真permissions/scan/connect/write facade的有效正控制與locale操作增量。
有資料活動控制：使用具名Demo或本機software peer，觀察其實際transport/transcript與request ownership；BLEcounter不代替Demo traffic。
正常polling照常依已宣告budget运行。以確定的request/observation身分、baseline或受控phase區分正常流量與locale誘發的額外流量，不能停止引擎為得到零。
不主動執行Mode04/Mode08/clear或其他狀態變更。重建/重連退役舊context，不重播unknown操作或恢復別台設備同意。
emulator的零副作用證據不等於physical radio資格。
N-L06 — 真工件、有限runner與審查

每run最少保留：candidate/target manifest、runner/SDK/entrypoint、APK與testAPK哈希、原始commands/stdout/stderr/exit、OS前後locale/config、UI/screenshots、事件timeline、必要request counters、狀態保存/恢復摘要、case結果及cleanup。

時間线至少可分辨action開始/確認/發出/OS生效/App觀察/收尾，區分wall clock與monotonic elapsed；不把不同clock epoch硬相減。

Screenshot要真App/真Settings來源，decode/dimensions與可讀性檢視；hash是完整性摘要，不是作者/執行/視覺審查證明。Native/Demo/physical列明標示。

Required native lane：缺target/tool/授權為NOT_RUN或BLOCKED，非零；執行失敗為FAIL；只有固定manifest required cases完整才PASS。Zero case、全skip、壞/截斷報告、wrong source/target、missing required screenshot不能放行。無裝置的普通unit lane不必假裝跑native，兩條gate分開。

進程死亡測試的證據控制器須存活於App之外；不以sleep代替ready/entered/return，所有等待有明確budget。不要改既有500ms產品adapter timeout來換取native通過；host等待budget與產品deadline分開。

8. 實作與交付節奏
核對current main、既有C1a review/CI處置與本卡SOURCE；開Draft MR，凍結scope/profile與candidate/target規格。
先做read-only preflight與identity負控制，盤點現有runner；不要立即啟動舊rig腳本。
完成N-L01／02的外部candidate OS往返，以獨立readback串接UI，不使用mock native。
完成N-L03／04：實際configuration＋顯式recreation，必要process restart獨立；有限state/owner cases。
完成N-L05與N-L06，重用既有軟體回歸，執行同source的native profile。
exact-head requiredCI＋具名native evidence＋限定review，再按原SHA-bound授權合併；actual-main gate後更新對應cell，不關閉整個#36/#40/#34。

可以先做read-only/馬具提交，再做可執行native提交，不要求每個commit都完成全部target；最終exit則以凍結的N-L01..06子集合真執行為準。先跑既有test API/runner支援檢查；新增API/dependency只有具體必要時才列allowlist。

9. 平行#101與residual ownership

#101正確責任：operation-bound write-audit receipts，不是write-after-read timeout。先核對歷史4c575f...repair與現行ownership；軟體可在沒有硬體時完成有限測試，不增加raw/manual入口。Foreign/reused/refused token、同命令交錯、queued send settle、later polling、partial/unknown都要保守。

Phone BLE由實際phone transport owner執行，#24彙整；#91只做一次具名實體Wear BLE；#65管wear provisioning/render/rotary/ambient；#36管locale/lifecycle。#48/#72消費候選聲明，不等同store upload授權。這些與N1不同scope，不互相借PASS。

10. 本輪界線與停止條件
本卡沒有執行任何candidate、emulator、安裝、OS/ADB變更、原生測試、Flutter測試或實體操作。
沒有target授權、APK不符、簽章衝突、現有field資料風險：停止native動作，保留原因。
只靠mock、source字串、get回顯、缺case/skip、shell補LocaleConfig或force-stop假冒configuration才能綠：修馬具，不接受。
確認產品state loss/extra send/loop：獨立具名最小修補，不擴成全面locale重寫。
Native文檔來源或CI資料不完整：保留PENDING_EVIDENCE，不編造。已合併歷史不自動revert、不倒填sign-off。
官方技術來源

[S1] Android LocaleManager — 
https://developer.android.com/reference/android/app/LocaleManager

[S2] Handle configuration changes — 
https://developer.android.com/guide/topics/resources/runtime-changes

[S3] ActivityScenario — 
https://developer.android.com/reference/androidx/test/core/app/ActivityScenario

[S4] UI Automator — 
https://developer.android.com/training/testing/other-components/ui-automator

[S5] Flutter integration tests — 
https://docs.flutter.dev/testing/integration-tests

[S6] apkanalyzer — 
https://developer.android.com/tools/apkanalyzer

[S7] apksigner — 
https://developer.android.com/tools/apksigner

以上官方文件用於核對API語意，不代表本專案已執行相應測試。原專案scope來自既有C1b-N1卡與本轮讀取的#36/#40/#101。
