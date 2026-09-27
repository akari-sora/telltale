Mr76 Handoff Readback 8adb3fd6.zh TW
MR !76 交接核對與 C1b-N1 規劃基線

日期：2026-09-27（Asia/Taipei）。專案：aa22396584/telltale。

裁定的範圍

本輪確認 MR !76 合併事實、source CI、main CI 的實際狀態，並核對 C1b 原生語系工作將使用的來源。這是一份交接／執行規格，不是重新執行或追認 C1A_SOFTWARE_ACCEPTED 的完整審查。沒有執行 native、Flutter、裝置、APK 安裝、ADB 寫入或遠端 repository mutations。

正確身分
欄位	實際值
MR source HEAD	cb3f9289ad0a3d8e574eae01199e16ab3e76da66
Squash commit	1950cc1f69dcc09a1a7b22b504a1aa550551f0f2
Main merge commit	8adb3fd66588001075054e21f94c5a7e6bb23859
合併時間	2026-09-27 17:57:09 台北
Source pipeline/job	2886704057 / 16761583484：SUCCESS
Source pipeline 完成	2026-09-27 17:56:04 台北
Source trace tree	a3dd7e4c4a005bc36ea44ce09b811c45c18e5381
Main pipeline/job	2886737458 / 16761769337：FAILED
Main job 完成	2026-09-27 18:09:20 台北
Main runner	56750249

Source trace：Flutter 3864 passed / 23 skipped / 0 failed；Python tools 727 OK、Mode08 Python17 OK；native Debug11 / Release11；l10n-required12/12；三個 field debug ABI APK 建置與上傳完成。這些來自遠端 trace，不是 reviewer 重跑。

Main trace：analyze0、Python tools727、Mode08 Python17 OK；Flutter3863 passed /23 skipped /1 failed。失敗案例：

Plain text
test/round5_triggers_test.dart
response pending is not a refusal
R11-codex 06: a suspension does not hand back a spent budget

此 Job 在 flutter-tests 停止，後續 scoped required stages 與 APK 步驟未執行。Python-tools 內部顯示的 CTest 或 l10n fixture PASS 不能充當後續 production stage 已執行的證據。失敗 artifact archive 存在，但本輪只讀到 trace 的命名失敗摘要，沒有其完整 assertion/stack，不判斷 flaky、根因或產品回歸。

由既有測試／deadline owner 核對原始 flutter-tests.stdout/stderr/exit，再做有限重現與處置。不要自動 skip、放寬時間、重寫 native locale 以處理這個非本切片失敗。本輪不要求 revert 已合併 MR，也不重新開 !77 或舊軟體驗收。

Review／merge／execution 不互相替代

讀回 MR notes 共12筆（含system notes）。最後讀到的非system review 是 note3912053981，針對02ef3bd6，標示 CHANGES REQUESTED；其後看到 cb6f266a/cb3f9289 的提交系統紀錄。本輪沒有取得針對 cb3f9289 的最終 source/visual acceptance 收據，也沒有執行對其全量修補的複審。因此不得把本文件當作補發 C1a 簽核。

已合併內容不被抹除；source CI 成功也保留。C1b 的程式／馬具可準備與實作；正式 accepted BASE 的證據欄需如實處理既定 C1a review 對帳和 exact-main failure，不提前填 PASS。

原生來源查核重點
MainActivity extends FlutterActivity；現有 framework LocaleManager bridge 已存在，無須改成 AppCompatActivity。
main manifest 的 configChanges 包含 locale、layoutDirection、fontScale、orientation 等。原生語系變化與 Activity recreation 不是必然一對一。
locales_config.xml、AppLocalePolicy.supportedTags、Dart supportedAppLocales 對應 en／zh-Hant／de。不是把每一個 ARB 檔案都變成系統設定可選 locale。
空 applicationLocales 表示 follow-system；supported fallback 仍可能顯示英文，不能因此說 override 被寫成英文。de及zh-Hant可用來做非英文system正控制。
field package 是 com.cbstudio.telltale；rig 是 com.cbstudio.telltale.rig；wear 使用相同 phone applicationId但不同variant。不能用 rig 代替 field 候選。
Gradle 分 ABI versionCodeOverride 為基礎 versionCode*10+ABI code（1/2/3）；候選身分從實際 APK 讀取，不只讀 pubspec 或 Gradle comment。
integration_test/locale_platform_test.dart 目前只是2個純 Dart planSync 測試，檔頭明示不是OS recreation。platform_locale_bridge_test.dart 也主要使用 fake OS。它們保留作 software regression，不充抵native cases。
tool/l10n_rig/android_os_locale.py 是既有 rig／process-restart lane：固定rig package及允許serial，shell補寫LocaleConfig，force-stop/relaunch，回報apk_matches_runner_head=false。其歷史結果不能當成本次field APK的manifest/continuous-recording/native acceptance。
既有 AndroidJUnitRunner 與 UIAutomator dependencies 已在 Gradle；androidTest tree 目前只有 ShareChooserInstrumentedTest.kt。可在同一test source set新增受限locale lifecycle test，不需更换生產Activity。
app_locales_platform.dart 的 live旗標在widget tests預設off，get/set有500ms adapter timeout。native lane 必須使用實際entry/真channel，不注入mock，不以加長adapter timeout來換PASS。
#101 標題與邊界

實際 OPEN Issue：[BUG][P2] Bind write-audit receipts to the queued operation, not a global window。不是 write-after-read timeout。

先核對歷史repair head4c575f634040ef3db546063fdc73f69f343fc059的現行source/review/merge/evidence。逐操作single-use receipt；foreign/reused拒絕；associated send settle前不以pending=false推論無write；only proven-zero rollback；partial/unknown保守且不重播；later polling不抹除。

本輪實際來源索引

MR !76

Source pipeline

Source job

Main pipeline

Main job

最後讀到的 review note

Issue #36

Issue #40

Issue #34

Issue #101

android/app/src/main/AndroidManifest.xml

android/app/src/main/kotlin/com/cbstudio/telltale/MainActivity.kt

android/app/src/main/kotlin/com/cbstudio/telltale/AppLocalePolicy.kt

android/app/src/main/res/xml/locales_config.xml

android/app/build.gradle.kts

lib/l10n/locale_resolution.dart

lib/core/app_locales_platform.dart

integration_test/locale_platform_test.dart

test/l10n/platform_locale_bridge_test.dart

tool/l10n_rig/android_os_locale.py

tool/l10n_rig/run.py

tool/i18n_verify/README.md
