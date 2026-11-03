# Translation glossary

Every pairing below is one this project **already made** somewhere in the tree, not a
preference invented for this file. The Evidence column names where, so a reviewer can
check a translation against the repository instead of against taste.

`test/l10n/glossary_evidence_test.dart` reads this file and fails when a cited file no
longer contains the Chinese term. That is deliberate: a glossary nobody can verify decays
into folklore, and this one is checked on every run.

**Status.** `evidenced` means both languages appear together at the cited place — the same
file, or the two language versions of one document. On a `T3` row the "English" is usually a
Dart identifier rather than shipped English copy: `無回應，稍後重試 / no answer` is evidenced
by `PidFault.noAnswer`, and the app has never rendered the string "no answer". That is a
convention this project already uses, not a loophole, but it is worth knowing which kind of
artefact you are looking at.

`inferred` means both languages exist in the tree but were never written side by side, so
the pairing is this glossary's reasoning rather than the project's own.

`proposed` means **the English has not been confirmed by a maintainer**. It is a statement
about review, not about the repository. An earlier draft of this file claimed the status was
"written by hand, never computed", which was both unfalsifiable and untrue in effect: the
`proposed` rows were exactly the rows the test could not evidence. Two rows make the point —
`化學計量比推算 / stoichiometric estimate` counts as evidenced and `Speed-Density 推算 /
Speed-Density estimate` does not, purely because one enum is spelled `stoichiometricEstimate`
and the other `speedDensity`. Same Chinese head word, same English word, opposite status. So
`proposed` may disagree with what the test can prove, in either direction, and a maintainer
moving a row to `evidenced` without changing the code is a legitimate act. The status is written by
hand, never computed — a generator that marked rows using the same rule the test checks
would only be agreeing with itself.

**How to read Evidence.** `T1` means the same sentence appears in both `README.md` and
`README.zh-TW.md`. `T2` means the same table row. `T3` means a Dart identifier sitting
next to its Chinese label in `lib/`. Anything else names the file directly.

**Traditional Chinese glossary.** Simplified Chinese uses a separate ARB
(`lib/l10n/app_zh_Hans.arb`); no entry here defines a zh-Hans form, so none should
be added.


See also [do-not-translate.md](do-not-translate.md) and [hedge-register.md](hedge-register.md).

## OBD2 and protocol

| 繁體中文 | English | Evidence | Status | Note |
|---|---|---|---|---|
| Demo ECU | Demo ECU | README.md:96 ↔ README.zh-TW.md:83 (T1 — unchanged in zh) | evidenced | Kept English on both sides. But see 內建模擬器 and 'Demo 模擬器' (docs/field-guide.zh-TW.md:30) — three renderings of one feature. |
| Flow Control | flow control | docs/protocol-deviations.zh-TW.md:83 '停住等一個永遠不會送出的 Flow Control 幀' (T1 — kept English inside zh prose) | evidenced | DO NOT translate to 流量控制. The zh doc deliberately keeps the ELM327 datasheet term; 幀 is appended as the classifier. |
| MAF 感測器 | MAF sensor | lib/l10n/app_en.arb:2942 ↔ lib/l10n/app_zh_Hant.arb:954 (T1 same ARB key) | evidenced | INCONSISTENCY: this uses 感測器 while the readiness monitor label uses 感知器 for oxygen sensor (lib/l10n/app_zh_Hant.arb:192 '含氧感知器', dtcMonitorOxygenSensor). Both ship. Label moved out of AirflowSource.label into the ARBs so lib/obd stays Flutter-free; the enum still carries the identity. |
| OBD2 故障診斷 | OBD2 fault diagnosis | README.md:21-22 ↔ README.zh-TW.md:20-21 (T1 same sentence) | evidenced |  |
| Speed-Density 推算 | Speed-density estimate | lib/l10n/app_en.arb:2946 ↔ lib/l10n/app_zh_Hant.arb:955 (T1 same ARB key) | evidenced | Was proposed while the label lived in physics_engine.dart, which had no English at all. The English now ships and says estimate — the load-bearing half, because this figure is computed from RPM, MAP and IAT rather than read off a sensor. |
| transports | transports | README.md:216 ↔ README.zh-TW.md:183 (T1 — unchanged in zh) | evidenced | INCONSISTENCY: kept English in the repo-layout table and at README.md:166, whose zh counterpart README.zh-TW.md:138 renders it '轉接器列表'; the user-facing concept is '連線方式' (app_zh_Hant.arb:9, store/README.md:26). Engineering doc = transports; UI = 連線方式. |
| 二次空氣噴射 | secondary air | lib/l10n/app_en.arb:2884 ↔ lib/l10n/app_zh_Hant.arb:195 (T1 same ARB key) | evidenced | Label moved out of ReadinessMonitor.secondaryAir into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 內建模擬器 | built-in simulator | lib/l10n/app_en.arb:83 ↔ lib/l10n/app_zh_Hant.arb:42 (T1 same ARB key) | evidenced | The in-app label is 'Demo 模擬器' (docs/field-guide.zh-TW.md:30); the ARB says 內建模擬器; README says Demo ECU. Pick per surface, do not unify silently. |
| 公式錯誤 | formula error | lib/l10n/app_en.arb:888 ↔ lib/l10n/app_zh_Hant.arb:121 (T1 same ARB key) | evidenced |  |
| 凍結幀 | freeze frame | README.md:97 'freeze frames' ↔ README.zh-TW.md:84 '凍結幀' (T1); docs/field-guide.zh-TW.md:216 heading | evidenced |  |
| 動力系統 | powertrain | lib/l10n/app_en.arb:1389 ↔ lib/l10n/app_zh_Hant.arb:794 (T1 same ARB key) | evidenced | Distinct from '大電池' used for 'powertrain battery' at README.md:99 ↔ README.zh-TW.md:86. Same English word, two zh renderings by domain. |
| 化學計量比推算 | Stoichiometric estimate | lib/l10n/app_en.arb:2954 ↔ lib/l10n/app_zh_Hant.arb:957 (T1 same ARB key) | evidenced |  |
| 匯流排 | bus | lib/l10n/app_en.arb:8 ↔ lib/l10n/app_zh_Hant.arb:8 (T1 same ARB key `adapterErrorCan`); lib/l10n/app_en.arb:6 ↔ lib/l10n/app_zh_Hant.arb:6 (`adapterErrorBusBusy`); lib/l10n/app_en.arb:5 ↔ lib/l10n/app_zh_Hant.arb:5 (`adapterErrorBus`) | evidenced | Adapter-error copy moved out of elm327_client.dart into the ARBs so lib/obd stays locale-free; the enum still carries the identity. |
| 協定 | protocol | README.md:216 'ELM327 protocol' ↔ README.zh-TW.md:183 'ELM327 協定' (T1); docs/protocol-deviations.zh-TW.md:152 '各種匯流排協定' | evidenced |  |
| 即時 PID 儀表 | Live PID dashboards | README.md:97 ↔ README.zh-TW.md:84 (T1) | evidenced | INCONSISTENCY: 'dashboard' is '儀表板' at README.md:36/README.zh-TW.md:34 and store/README.md:27, but 'PID dashboards' is 儀表 here and 'BMS gauges' is also '儀表' (README.md:105 ↔ README.zh-TW.md:91). 儀表 does double duty for gauge and dashboard-of-gauges. |
| 含氧感知器 | oxygen sensor | lib/l10n/app_en.arb:703 ↔ lib/l10n/app_zh_Hant.arb:192 (T1 same ARB key `dtcMonitorOxygenSensor`) | evidenced | 感知器 (TW) not 傳感器 (CN). Label moved out of ReadinessMonitor.oxygenSensor into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 增壓壓力 | boost pressure | lib/l10n/app_en.arb:655 ↔ lib/l10n/app_zh_Hant.arb:180 (T1 same ARB key `dtcMonitorBoostPressure`) | evidenced | Label moved out of ReadinessMonitor.boostPressure into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 多幀 | multi-frame | docs/verification/review-log.md:41 '### C2 · 多幀長度行被當成資料' + :43 naming `_parse` ↔ lib/obd/elm327_client.dart:4 'multi-frame reassembly' and :6753 "a multi-frame envelope's total length" (T3, same named function) | inferred | zh at docs/verification/review-log.md:41; en at lib/obd/elm327_client.dart:4. Both are this project's words, never written side by side. |
| 失火監控 | misfire | lib/l10n/app_en.arb:2774 ↔ lib/l10n/app_zh_Hant.arb:189 (T1 same ARB key) | evidenced | Label moved out of ReadinessMonitor.misfire into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 定址 | addressing | docs/protocol-deviations.zh-TW.md:101 '正確定址被丟掉了' ↔ docs/protocol-deviations.zh-TW.md:107 names `lib/obd/addressing.dart:1` and 'addressing' (T3) | evidenced | 'functional addressing' = 功能定址 (field-guide:214); 'physical header' = 實體標頭 (protocol-deviations:107). |
| 已儲存 | stored | lib/l10n/app_en.arb:494 ↔ lib/l10n/app_zh_Hant.arb:788 (T1 same ARB key) | evidenced | Moved out of DtcKind when lib/obd/ stopped carrying screen copy. The enum still holds 已儲存 as `transcriptLabel`, which is export copy and stays Chinese in every locale — do not cite that as the UI translation. |
| 底盤 | chassis | lib/l10n/app_en.arb:2756 ↔ lib/l10n/app_zh_Hant.arb:795 (T1 same ARB key `dtcSystemChassis`) | evidenced |  |
| 待確認 | pending | lib/l10n/app_en.arb:494 ↔ lib/l10n/app_zh_Hant.arb:789 (T1 same ARB key) | evidenced | Not 'detected' and not 'confirmed': a Mode 07 code has been seen once and has not reached the confirmation threshold. |
| 微粒濾清器 | particulate filter | lib/l10n/app_en.arb:683 ↔ lib/l10n/app_zh_Hant.arb:194 (T1 same ARB key) | evidenced |  |
| 批次 | batch | README.md:128 'no identifier scan, batch, automatic retry' ↔ README.zh-TW.md:108 '不掃描 identifier、不批次、不自動重試' (T1); docs/protocol-deviations.zh-TW.md:83 'fastMode 批次查詢' | evidenced |  |
| 排放就緒 | readiness | README.md:97 'readiness' ↔ README.zh-TW.md:84 '排放就緒' (T1); docs/field-guide.zh-TW.md:241 '排放就緒狀態' | evidenced | zh adds 排放 (emissions) that bare English 'readiness' omits; keep it — the field guide relies on the emissions sense. |
| 排氣感知器 | exhaust sensor | lib/l10n/app_en.arb:675 ↔ lib/l10n/app_zh_Hant.arb:185 (T1 same ARB key `dtcMonitorExhaustSensor`) | evidenced | Label moved out of ReadinessMonitor.exhaustSensor into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 控制器 | controller | lib/state/dtc_scan.dart:47 'Controllers that gave this category a terminal answer.' ↔ docs/field-guide.zh-TW.md:203 '標出是哪一個控制器' (T3); docs/field-guide.zh-TW.md:209 | inferred | Engine scan sentences moved to English transcript-only; zh remains at docs/field-guide.zh-TW.md:203, en at dtc_scan.dart:47. |
| 故障碼 | fault code | README.md:97 'fault codes' ↔ README.zh-TW.md:84 '故障碼' (T1) | evidenced | DTC as an acronym stays English (see doNotTranslate); the spelled-out concept is 故障碼. |
| 標頭 | header | lib/l10n/app_en.arb:33 ↔ lib/l10n/app_zh_Hant.arb:123 (T1 same ARB key) | evidenced |  |
| 故障燈 | MIL | lib/obd/polling_engine.dart:3418 'whose MIL is lit' (T3) | inferred | The app ships 故障燈 in Chinese prose and MIL in this comment (and in the English PID name `Distance Travelled With MIL On`); no place writes both, so the pairing is this glossary's. Spell it out on first mention in English if the audience may not know the acronym |
| 永久 | permanent | lib/l10n/app_en.arb:2736 ↔ lib/l10n/app_zh_Hant.arb:790 (T1 same ARB key) | evidenced | A permanent code is NOT clearable, and English copy must never imply that pressing Clear removes it. dtcKindPermanentExplanation (lib/l10n/app_en.arb:2748 ↔ lib/l10n/app_zh_Hant.arb:793) carries 無法用診斷儀清除，需修復後由 ECU 自行確認 and its English; dtcClearDialogBody (lib/l10n/app_en.arb:494 ↔ lib/l10n/app_zh_Hant.arb:144) repeats it beside the Clear button. #45 names this explicitly |
| 汽油微粒濾清器（GPF） | gasoline particulate filter (GPF) | lib/l10n/app_en.arb:683 ↔ lib/l10n/app_zh_Hant.arb:187 (T1 same ARB key `dtcMonitorGasolineParticulateFilter`) | evidenced | LOAD-BEARING: field-guide:250-252 says many OBD tables mistranslate this bit as 空調冷媒 (A/C refrigerant) and that is wrong. Keep GPF in the string. |
| 無回應，稍後重試 | no answer | lib/l10n/app_en.arb:817 ↔ lib/l10n/app_zh_Hant.arb:126 (T1 same ARB key) | evidenced |  |
| 燃油系統監控 | fuel system | lib/l10n/app_en.arb:679 ↔ lib/l10n/app_zh_Hant.arb:186 (T1 same ARB key `dtcMonitorFuelSystem`) | evidenced | Label moved out of ReadinessMonitor.fuelSystem into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 監控項目 | readiness monitor | lib/obd/readiness.dart:1 'The emissions readiness monitors' + enum `ReadinessMonitor` :41 ↔ docs/field-guide.zh-TW.md:243,246-248 '監控項目' (T3 identifier ↔ zh prose) | inferred | zh at docs/field-guide.zh-TW.md:243; en at lib/obd/readiness.dart:1. Assembled from two documents. |
| 綜合元件監控 | components | lib/l10n/app_en.arb:663 ↔ lib/l10n/app_zh_Hant.arb:182 (T1 same ARB key) | evidenced |  |
| 網路 | network | lib/l10n/app_en.arb:52 ↔ lib/l10n/app_zh_Hant.arb:797 (T1 same ARB key) | evidenced |  |
| 自訂 PID | custom PID | README.md:97 'custom PIDs' ↔ README.zh-TW.md:84 '自訂 PID' (T1) | evidenced |  |
| 蒸發排放系統 | evaporative | lib/l10n/app_en.arb:673 ↔ lib/l10n/app_zh_Hant.arb:184 (T1 same ARB key) | evidenced | The English ships as "Evaporative system" — the evaporative emission system, not the exhaust. Label moved out of ReadinessMonitor.evaporative into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 觸媒轉換器 | catalyst | lib/l10n/app_en.arb:687 ↔ lib/l10n/app_zh_Hant.arb:181 (T1 same ARB key) | evidenced | Label moved out of ReadinessMonitor.catalyst into the ARBs (L04) so lib/obd stays Flutter-free; the enum still carries the identity. |
| 診斷紀錄 | diagnostic transcript | README.md:98 ↔ README.zh-TW.md:85 (T1); also README.md:137 ↔ README.zh-TW.md:114; docs/field-guide.zh-TW.md:125,292 UI path 設定 → 診斷紀錄 | evidenced |  |
| 車身 | body | lib/l10n/app_en.arb:2760 ↔ lib/l10n/app_zh_Hant.arb:796 (T1 same ARB key) | evidenced |  |
| 車輛即時遙測 | Live vehicle telemetry | lib/l10n/app_en.arb:30 ↔ lib/l10n/app_zh_Hant.arb:18 (T1 same ARB key) | evidenced | Also the Google Play store name suffix. Use verbatim for appTagline. |
| 輪詢 | polling | README.md:129 'scheduled polling' ↔ README.zh-TW.md:108 '排程輪詢' (T1); README.md:201 'idle polling' ↔ README.zh-TW.md:169 '閒置輪詢' | evidenced |  |
| 轉接器 | adapter | README.md:22 'ELM327-compatible adapter' ↔ README.zh-TW.md:20 'ELM327 相容轉接器' (T1); lib/l10n/app_en.arb:44 ↔ lib/l10n/app_zh_Hant.arb:26 | evidenced | Never 適配器/配接器. 轉接器 is used throughout README.zh-TW, field-guide and lib/. |
| 選擇連線方式 | Choose a connection | lib/l10n/app_en.arb:110 ↔ lib/l10n/app_zh_Hant.arb:57 (T1 same ARB key) | evidenced |  |
| 電門 | ignition | lib/l10n/app_en.arb:58 ↔ lib/l10n/app_zh_Hant.arb:31 (T1 same ARB key) | evidenced | 電門 (not 點火/鑰匙門). Reused throughout docs/field-guide.zh-TW.md:62,148,149,270,301. |


## Hardware and transport

| 繁體中文 | English | Evidence | Status | Note |
|---|---|---|---|---|
| Bluetooth Classic | Bluetooth Classic | README.md:93 ↔ README.zh-TW.md:80 (T1 — unchanged) | evidenced | Transport product names stay English; generic 'bluetooth' becomes 藍牙 (docs/field-guide.zh-TW.md:21 '系統藍牙設定', :70 '藍牙配對清單'). Context rule, not one pair. |
| Bluetooth LE | Bluetooth LE | README.md:94 ↔ README.zh-TW.md:81 (T1 — unchanged); docs/field-guide.zh-TW.md:23 'App 裡選 Bluetooth LE' | evidenced |  |
| GATT UART service | GATT UART service | README.md:94 'a GATT UART service' ↔ README.zh-TW.md:81 '（GATT UART service）' (T1 — unchanged) | evidenced |  |
| RFCOMM/SPP | RFCOMM/SPP | README.md:93 ↔ README.zh-TW.md:80 (T1 — unchanged) | evidenced |  |
| Wi-Fi 轉接器 | Wi-Fi adapter | README.md:95 'Wi-Fi adapters using a local TCP connection' ↔ README.zh-TW.md:82 'Wi-Fi 轉接器的區域 TCP 連線' (T1) | evidenced |  |
| 區域 TCP 連線 | local TCP connection | README.md:95 ↔ README.zh-TW.md:82 (T1) | evidenced |  |
| 工作階段 | session | README.md:160 'session dated 2026-08-27' ↔ README.zh-TW.md:134 '復原工作階段紀錄' (T1); README.md:198 ↔ README.zh-TW.md:168 | evidenced | Not 會話/場次. lib/obd/session_evidence.dart:139 ships '# Telltale OBD 工作階段紀錄 v1'. |
| 已實車連線的轉接器 | Field-tested adapter | README.md:155 '## Field-tested adapter' ↔ README.zh-TW.md:129 '## 已實車連線的轉接器' (T1 heading) | evidenced | zh deliberately says 'has connected to a real car', weaker than English 'field-tested'. Preserve the weaker claim. |
| 維護者簽章 | maintainer-signed | README.md:54 'maintainer-signed APKs' ↔ README.zh-TW.md:50 '維護者簽章的 APK' (T1) | evidenced | Current GitLab release-channel wording; distinct from older GitHub community builds and Google Play signing. |
| 解除安裝 | uninstall | README.md:84 'without uninstalling' ↔ README.zh-TW.md:72 '不解除安裝' (T1) | evidenced |  |
| 轉接器緩衝區溢位 | buffer full | lib/l10n/app_en.arb:4 ↔ lib/l10n/app_zh_Hant.arb:4 (T1 same ARB key `adapterErrorBufferFull`) | evidenced | Adapter-error copy moved out of elm327_client.dart into the ARBs so lib/obd stays locale-free; the enum still carries the identity. |
| 電壓過低導致轉接器重置 | low voltage reset | lib/l10n/app_en.arb:16 ↔ lib/l10n/app_zh_Hant.arb:13 (T1 same ARB key `adapterErrorLowVoltageReset`) | evidenced | Adapter-error copy moved out of elm327_client.dart into the ARBs so lib/obd stays locale-free; the enum still carries the identity. |


## Interface

| 繁體中文 | English | Evidence | Status | Note |
|---|---|---|---|---|
| App 截圖與實車示範 | Screenshots and vehicle demo | README.md:32 ↔ README.zh-TW.md:30 (T1 heading) | evidenced |  |
| Language / 語言 | Language / 語言 | lib/l10n/app_en.arb:974 ↔ lib/l10n/app_zh_Hant.arb:265 (T1 same ARB key) | evidenced | Keep bilingual; zh-Hans uses `Language / 语言`. app_en.arb `@languageSectionTitle` description: 'Bilingual label for the language picker. Options use self-names.' |
| 主打圖片（feature graphic） | feature graphic | store/README.md:25 '主打圖片（feature graphic）' (T1 — the project's own inline gloss) | evidenced |  |
| 儀表 | gauge | README.md:105 'read-only BMS gauges' ↔ README.zh-TW.md:91 '唯讀 BMS 儀表' (T1) | evidenced | See the 即時 PID 儀表 note: 儀表 renders both 'gauge' and 'PID dashboard'. |
| 儀表板 | dashboard | README.md:36 alt 'Telltale live telemetry dashboard' ↔ README.zh-TW.md:34 alt 'Telltale 即時遙測儀表板' (T1); store/README.md:27 | evidenced |  |
| 刪除 | delete | lib/l10n/app_en.arb:2134 ↔ lib/l10n/app_zh_Hant.arb:293 (T1 same ARB key) | evidenced |  |
| 匯出 | export | lib/l10n/app_en.arb:2215 ↔ lib/l10n/app_zh_Hant.arb:631 (T1); README.md:98 'export' ↔ README.zh-TW.md:84 '匯出' | evidenced |  |
| 回放 | replay | lib/l10n/app_en.arb:2137 ↔ lib/l10n/app_zh_Hant.arb:604 (T1 same ARB key) | evidenced |  |
| 外觀 | Appearance | lib/l10n/app_en.arb:35 ↔ lib/l10n/app_zh_Hant.arb:23 (T1 same ARB key) | evidenced |  |
| 性能量測 | performance | store/README.md:29 '`05-performance.png` … 手機截圖：性能量測' (T1) | evidenced |  |
| 應用程式圖示 | app icon | store/README.md:24 '`icon-512.png` … 應用程式圖示' (T1) | proposed | English has no source in the tree; the cited file is Chinese-only |
| 手機截圖 | phone screenshot | store/README.md:26-30 (T1 table, paired with the English PNG filenames) | proposed | English has no source in the tree; the cited file is Chinese-only |
| 設定 | Settings | lib/l10n/app_en.arb:45 settingsHeadline ↔ lib/l10n/app_zh_Hant.arb:27 (T1) | evidenced |  |
| 設定頁 | Settings | README.md:165 'Settings shows the full disclosure card' ↔ README.zh-TW.md:138 '設定頁是完整揭露卡' (T1) | evidenced | context: screen |
| 連線頁 | Connect | README.md:166 'Connect keeps a secondary text link' ↔ README.zh-TW.md:138-139 '連線頁只在轉接器列表下方放次要文字連結' (T1) | evidenced | context: screen |
| 重試 | Retry | lib/l10n/app_en.arb:793 ↔ lib/l10n/app_zh_Hant.arb:212 (T1 same ARB key) | evidenced |  |
| 面盤外觀 | skins | store/README.md:30 '`06-skins.png` … 手機截圖：語言與面盤外觀' (T1 filename ↔ zh gloss in the same table row) | evidenced | 面盤 = the dial face. Related: README.md:105 'BMS gauges' ↔ README.zh-TW.md:91 'BMS 儀表'. |


## Data, evidence and status

| 繁體中文 | English | Evidence | Status | Note |
|---|---|---|---|---|
| 資料已過期 | stale | lib/l10n/app_en.arb:337 ↔ lib/l10n/app_zh_Hant.arb:701 (T1 same ARB key) | evidenced | #45 names this explicitly: stale ≠ live. A reading that stopped updating is not a current one, and must never render as though it were |
| ECU 回報 | ECU reported | lib/l10n/app_en.arb:456 ↔ lib/l10n/app_zh_Hant.arb:765 (T1 same ARB key, `derivedEcuReported`) | evidenced | The identifier for the fuel case says `measured`; both shipped strings say the ECU reported it. #44 forbids rendering 推算/estimate as measured, and using the bare word for the true case invites exactly that slip, so the English names the reporter rather than the act of measuring. `derivedFuelSourceEcu` briefly held a second, byte-identical copy of this sentence and was merged away. |
| VE | VE | README.md:117 ↔ README.zh-TW.md:100 (T1 — unchanged); spelled out as 容積效率 in lib/obd/session_evidence.dart:217 'volumetricEfficiency' | evidenced |  |
| make／廠牌（製造商部門） | make label | README.md:115 '146 make labels' ↔ README.zh-TW.md:99 '146 個 make／廠牌（製造商部門）標籤' (T1 — the project's own inline gloss) | evidenced | zh keeps the English token AND glosses it, because EPA 'make' means a manufacturer division, not a brand. Keep both halves. |
| 來源 | provenance | README.md:232 'evidence, provenance, and real-vehicle limits' ↔ README.zh-TW.md:199 '證據、來源與實車限制' (T2) | evidenced |  |
| 來源 revision | source revision | README.md:133 ↔ README.zh-TW.md:112 (T1 — 'revision' kept English) | evidenced |  |
| 傳動效率 | transmission efficiency | README.md:117 ↔ README.zh-TW.md:100 (T1) | evidenced |  |
| 原廠資料 | manufacturer data | lib/l10n/app_en.arb:3021 ↔ lib/l10n/app_zh_Hant.arb:982 (T1 same ARB key) | evidenced | The English was 'manufacturer publication' here while nothing shipped it. What ships is 'manufacturer data': shorter, and 'publication' invites the reader to expect a document they can go and read. |
| 大電池目錄 | powertrain-battery catalog | README.md:99 'powertrain-battery catalog' ↔ README.zh-TW.md:86 '大電池目錄' (T1) | evidenced |  |
| 大電池車型設定 | powertrain battery profiles | README.md:232 doc table ↔ README.zh-TW.md:199 doc table (T2 same table row) | evidenced |  |
| 官方型錄 | official registry | lib/l10n/app_en.arb:3017 ↔ lib/l10n/app_zh_Hant.arb:981 (T1 same ARB key) | evidenced | The strongest of the five origins. It must not be worded so as to sound like a measurement of this car — it is a record about this model. |
| 容積效率 | volumetric efficiency | lib/obd/session_evidence.dart:217 'volumetricEfficiency' => '容積效率' (T3) | evidenced |  |
| 實驗室 | laboratory | README.md:111 'the one-shot laboratory' ↔ README.zh-TW.md:95 '單次實驗室' (T1); README.md:123 ↔ README.zh-TW.md:105 | evidenced |  |
| 年式 | model year | README.md:115 'model years 1984–2027' ↔ README.zh-TW.md:99 '年式 1984–2027' (T1); README.md:126 'selected year' ↔ README.zh-TW.md:107 '所選年式' | evidenced |  |
| 快照 | snapshot | README.md:114 'EPA Find-a-Car snapshot' ↔ README.zh-TW.md:98 'EPA Find-a-Car 快照' (T1); README.md:221 ↔ README.zh-TW.md:188 | evidenced |  |
| 手動輸入 | entered by you | lib/l10n/app_en.arb:3013 ↔ lib/l10n/app_zh_Hant.arb:980 (T1 same ARB key) | evidenced | 'user entered' was the glossary's own coinage and read like a database column. The shipped English addresses the reader, because the point of the word is that the app did not check this number — they typed it. |
| 扭力 | torque | README.md:117 ↔ README.zh-TW.md:100 (T1); README.md:117 ↔ README.zh-TW.md:100 | evidenced | 扭力 (TW) not 扭矩 (CN). Distinct from the Torque/Torque Pro product name at README.md:259 ↔ README.zh-TW.md:217 'Torque / Torque Pro', which is never translated. |
| 排氣量 | displacement | lib/obd/session_evidence.dart:215 'displacementL' => '排氣量' (T3 key ↔ label); docs/field-guide.zh-TW.md:167 | evidenced |  |
| 正面投影面積 | frontal area | lib/obd/session_evidence.dart:221 'frontalAreaM2' => '正面投影面積' (T3) | evidenced |  |
| 油耗 | fuel estimate | README.md:120 ↔ README.zh-TW.md:102 (T1); docs/field-guide.zh-TW.md:166 '推算數值（馬力、扭力、油耗）' | evidenced |  |
| 滾動阻力係數 | rolling resistance | lib/obd/session_evidence.dart:222 'rollingResistance' => '滾動阻力係數' (T3) | evidenced |  |
| 燃料種類 | fuel type | lib/obd/session_evidence.dart:218 'fuelType' => '燃料種類' (T3) | evidenced |  |
| 經完整性檢查 | integrity-checked | README.md:99 ↔ README.zh-TW.md:86 (T1); README.md:114 ↔ README.zh-TW.md:98 | evidenced |  |
| 車輛設定 | vehicle profile | README.md:118 'every configured vehicle profile' ↔ README.zh-TW.md:101 '每組車輛設定' (T1) | evidenced | INCONSISTENCY: 'profile' is 車輛設定 here, 'profiles' ↔ '車型設定' at README.md:232 ↔ README.zh-TW.md:199, and kept as bare `profile` at README.zh-TW.md:112. Three renderings. |
| 車重 | mass | README.md:117 'does not infer mass, torque, drag, VE' ↔ README.zh-TW.md:100 '不推測車重、扭力、風阻、VE' (T1); lib/obd/session_evidence.dart:216 'massKg' => '車重' | evidenced |  |
| 通用預設 | generic default | lib/l10n/app_en.arb:3009 ↔ lib/l10n/app_zh_Hant.arb:979 (T1 same ARB key) | evidenced | The weakest of the five origins, and the one a reader most needs to spot: it means the estimate is about a car, not about their car. |
| 模型係數 | model coefficient | lib/l10n/app_en.arb:3025 ↔ lib/l10n/app_zh_Hant.arb:983 (T1 same ARB key) | evidenced | A number from a physical model rather than from this vehicle. Never 'measured' and never 'official' — #44's rule about 推算 applies to it directly. |
| 雜湊 | hash | README.md:133 'verified catalog hash' ↔ README.zh-TW.md:112 '已驗證的目錄雜湊' (T1); README.md:231 'hashes' ↔ README.zh-TW.md:198 '雜湊' | evidenced |  |
| 風阻 | drag | README.md:117 ↔ README.zh-TW.md:100 (T1); lib/obd/session_evidence.dart:220 'dragCoefficient' => '風阻係數' | evidenced |  |
| 馬力 | horsepower | README.md:119-120 'profile-derived horsepower, torque, and fuel estimates' ↔ README.zh-TW.md:102 '實車的馬力、扭力或油耗' (T1) | evidenced |  |
| 驅動方式 | drivetrain | lib/obd/session_evidence.dart:219 'drivetrain' => '驅動方式' (T3); README.zh-TW.md:101 '風阻與驅動方式' | evidenced |  |


## Safety and refusal

| 繁體中文 | English | Evidence | Status | Note |
|---|---|---|---|---|
| cooldown | cooldown | README.md:135 'a five-second cooldown' ↔ README.zh-TW.md:113 '五秒 cooldown' (T1 — kept English) | evidenced |  |
| single-flight | single-flight | README.md:136 ↔ README.zh-TW.md:113 (T1 — kept English) | evidenced |  |
| 一次性同意 | one-use consent | README.md:133 'The one-use consent is bound to…' ↔ README.zh-TW.md:112 '一次性同意會綁定…' (T1) | evidenced |  |
| 同意規則 | consent rules | README.md:141 ↔ README.zh-TW.md:116 (T1) | evidenced |  |
| 唯讀 | read-only | README.md:105 'read-only BMS gauges' ↔ README.zh-TW.md:91 '唯讀 BMS 儀表' (T1); README.md:112 ↔ README.zh-TW.md:96; docs/field-guide.zh-TW.md:336 '只接受唯讀查詢' | evidenced |  |
| 大電池證據實驗室 | battery laboratory | README.md:123 'The experimental battery laboratory is off by default.' ↔ README.zh-TW.md:105 '大電池證據實驗室預設關閉。' (T1) | evidenced |  |
| 清除 | clear | README.md:244-245 'before clearing DTCs' ↔ README.zh-TW.md:210 '清除 DTC 前' (T1); docs/field-guide.zh-TW.md:254 '### 清除' | evidenced | context: DTCs |
| 確認 | acknowledgement | README.md:106 'install-time identity acknowledgement' ↔ README.zh-TW.md:92 '安裝時需確認車輛身分' (T1); README.md:126 ↔ README.zh-TW.md:107 | evidenced |  |
| 證據 | evidence | README.md:138 'as evidence' ↔ README.zh-TW.md:114-115 '作為證據' (T1); README.md:206 ↔ README.zh-TW.md:174 | evidenced |  |
| 證據邊界 | evidence boundary | README.md:171-172 'for the evidence boundary' ↔ README.zh-TW.md:143 '證據邊界見' (T1) | evidenced |  |
| 車輛已安全停妥 | safely parked vehicle | README.md:127 'a safely parked vehicle' ↔ README.zh-TW.md:107 '車輛已安全停妥' (T1) | evidenced | Safety-critical. docs/field-guide.zh-TW.md:304 '只在車輛完全停妥時操作，行進中交給乘客。' |
| 連線世代 | connection generation | README.md:134 'connection generation' ↔ README.zh-TW.md:112-113 '連線世代' (T1) | evidenced |  |
| 閘門 | gate | README.md:232 'install gates' ↔ README.zh-TW.md:199 '安裝閘門' (T1); README.md:144 'public compile gates' ↔ README.zh-TW.md:120 '公開編譯閘門' | evidenced |  |
| 隔離 | quarantine | README.md:136 'structural-mismatch quarantine' ↔ README.zh-TW.md:114 '結構錯誤隔離' (T1) | evidenced | Same zh word also renders 'isolated' at README.md:190 ↔ README.zh-TW.md:161 ('isolated `rig` flavor' / '隔離的 `rig` flavor'). |
| 驗證邊界 | verification boundary | README.md:192 '## Verification boundary' ↔ README.zh-TW.md:163 '## 驗證邊界' (T1 heading); README.md:141 'validation boundary' ↔ README.zh-TW.md:116 '驗證邊界' | evidenced |  |


## Licence, store and disclosure

| 繁體中文 | English | Evidence | Status | Note |
|---|---|---|---|---|
| 佣金 | commission | README.md:163-164 'may pay the maintainer a commission' ↔ README.zh-TW.md:137 '可能讓維護者取得佣金' (T1) | evidenced | Keep the modal: 'may pay' / '可能…取得', never 'will'. |
| 來源與重用聲明 | source and reuse notices | README.md:261 ↔ README.zh-TW.md:219 (T1) | evidenced |  |
| 授權與聲明 | Licence and disclaimer | README.md:255 '## Licence and disclaimer' ↔ README.zh-TW.md:214 '## 授權與聲明' (T1 heading) | evidenced | British 'Licence' in prose (README.md:141,255); the SPDX id GPL-3.0 and the LICENSE filename stay as-is. |
| 推廣分潤連結 | affiliate link | README.md:162-163 'this is a maintainer affiliate link' ↔ README.zh-TW.md:136-137 '這是維護者的推廣分潤連結' (T1) | evidenced | Disclosure copy — regulated. Do not shorten to 推薦連結. |
| 揭露卡 | disclosure card | README.md:165 'the full disclosure card' ↔ README.zh-TW.md:138 '完整揭露卡' (T1) | evidenced |  |
| 版本紀錄 | Changelog | README.md:233 doc table ↔ README.zh-TW.md:200 (T2) | evidenced |  |
| 社群互動規範 | community expectations | README.md:247 'for community expectations' ↔ README.zh-TW.md:211 '社群互動規範見' (T1) | evidenced | also written: Code of Conduct |
| 第三方來源聲明 | third-party notices | README.md:262-263 'separate third-party notices' ↔ README.zh-TW.md:219-220 '另有第三方來源聲明' (T1) | evidenced |  |
| 自行承擔使用風險 | at your own risk | README.md:263-264 'Use the app at your own risk' ↔ README.zh-TW.md:220 '請自行承擔使用風險' (T1) | evidenced |  |
| 貢獻指南 | Contributing | README.md:234 doc table ↔ README.zh-TW.md:201 (T2); README.md:257 'the contributor guide' ↔ README.zh-TW.md:216 '貢獻指南' | evidenced | also written: contributor guide |
| 隱私權政策 | privacy policy | README.md:242 'published privacy policy' ↔ README.zh-TW.md:208 '已發布的隱私權政策' (T1) | evidenced |  |
| 隱私與安全使用 | Privacy and safe use | README.md:236 heading ↔ README.zh-TW.md:203 heading (T1) | evidenced |  |


## Build, release and tooling

| 繁體中文 | English | Evidence | Status | Note |
|---|---|---|---|---|
| flavor | flavor | README.md:189-190 'The `field` flavor … the isolated `rig` flavor' ↔ README.zh-TW.md:160-161 (T1 — unchanged) | evidenced |  |
| 協定差異 | Protocol deviations | README.md:232 doc table ↔ README.zh-TW.md:199 (T2); the zh doc's own H1 is '公式與 AT 指令的交叉驗證記錄' (docs/protocol-deviations.zh-TW.md:1) | evidenced |  |
| 可重現的模擬器 | deterministic simulators | README.md:219 ↔ README.zh-TW.md:186 (T1) | evidenced |  |
| 契約 | contract | README.md:217 'Unit, contract, parser, and widget tests' ↔ README.zh-TW.md:184 '單元、契約、parser 與 widget 測試' (T1) | evidenced | 'parser' and 'widget' stay English inside the zh row; 'unit' and 'contract' are translated.; context: test |
| 實車指南 | Field guide | README.md:231 doc table ↔ README.zh-TW.md:198 (T2); the zh doc's own H1 is '上車前速查' (docs/field-guide.zh-TW.md:1) | evidenced | The doc's H1 (上車前速查) and its table label (實車指南) differ on purpose. Do not unify. |
| 專案目錄 | Repository layout | README.md:212 heading ↔ README.zh-TW.md:179 heading (T1) | evidenced |  |
| 工具鏈 | toolchain | README.md:176 'Use the pinned Flutter 3.47.0 toolchain' ↔ README.zh-TW.md:147 '使用固定的 Flutter 3.47.0 工具鏈' (T1) | evidenced |  |
| 平台整合 | platform integration | README.md:220 ↔ README.zh-TW.md:187 (T1) | evidenced |  |
| 文件索引 | Documentation index | README.md:227 doc table ↔ README.zh-TW.md:194 (T2) | evidenced |  |
| 測試證據 | test evidence | README.md:207 'Start with [test evidence]' ↔ README.zh-TW.md:175 '[測試證據]' (T1) | evidenced |  |
| 裝置驗證 | device verification | README.md:208 ↔ README.zh-TW.md:176 (T1) | evidenced |  |
| 車輛資料來源 | Vehicle data sources | README.md:231 doc table ↔ README.zh-TW.md:198 (T2) | evidenced |  |
| 驗證馬具矩陣 | verification rig matrix | README.md:209-210 'verification rig matrix' ↔ README.zh-TW.md:179 '驗證馬具矩陣' (T1) | evidenced | 'rig' = 馬具 in prose but stays `rig` as a flavor/identifier (README.zh-TW.md:163,187). |

## Known gaps

One concept this project relies on has **no Traditional Chinese term anywhere in the
tree**, and inventing one inside a translation PR would put a coined term in front of users
without anybody deciding it.

| Concept | English | Status |
|---|---|---|
| A component that refuses rather than guesses when it cannot confirm something | fail-closed | **no established Chinese** |

`安全確認流程` at `README.zh-TW.md:101` is sometimes mistaken for the equivalent. It is not:
it names one specific confirmation flow, while *fail-closed* is a property the whole app is
built on — the transport, the clear-DTC gate, the startup checks and the freeze-frame gate
all fail closed. Translating the property as the name of one flow would shrink it.

A translator who needs it must coin a term, use it consistently, and flag it for
maintainer sign-off in the pull request rather than settling it in review comments.
