# Telltale 隱私權政策

最後更新：2026 年 9 月 24 日

## 一句話版本

**Telltale 本身不收集資料，也不會主動上傳資料。** 沒有帳號、沒有廣告、沒有分析、
沒有當機回報服務。App 唯一自己建立的連線是你設定的 ELM327 轉接器。
推薦轉接器連結只有在你點下去時，才會交給系統開啟蝦皮或瀏覽器。

---

## 我們收集哪些資料

<!-- claim: CLAIM-DEVELOPER-NO-COLLECTION -->
**沒有。**

Telltale 不會收集個人資料，也不會把任何資料傳送到我們或第三方的伺服器。
我們沒有伺服器。Telltale 本身不收集資料，也不會主動上傳資料。

## App 在你裝置上儲存哪些東西

<!-- claim: CLAIM-LOCAL-STORAGE-PARTITION -->
以下內容會寫入 App 的私有儲存空間，依功能獨立分區存放，不會傳送到我們的伺服器：

| 內容 | 分區與位置 | 為什麼 |
|---|---|---|
| 你的車輛設定（排氣量、車重、風阻係數與逐欄來源等） | `SharedPreferences` | 推算馬力與油耗需要；來源資訊用來避免把預設值說成官方規格 |
| 你自訂的 PID 定義 | `SharedPreferences` | 這是你寫的東西 |
| 上次使用的轉接器與 Wi-Fi 位址 | `SharedPreferences` | 下次不用再找一遍 |
| 介面設定（深色／淺色、儀表樣式） | `SharedPreferences` | 記住你的選擇 |
| 診斷紀錄（最後一次連線快照） | `Documents/last-session.log` | 連不上時可以匯出給人看 |
| 遙測工作階段歷史 | `Documents/telltale-telemetry/` | 本機重播、檢視時間軸，或手動匯出 CSV／JSON |
| 分享暫存檔案與租約紀錄 | `Caches/telltale-app-shares/` | 匯出時供系統分享面板讀取之暫存副本 |

<!-- claim: CLAIM-DIAGNOSTIC-RAW-BYTES -->
**診斷紀錄**值得特別說明：它記錄 App 與轉接器之間往返的原始位元組，包括車輛
回報的 VIN 與故障碼，儲存於 Documents/last-session.log。App 僅保留最近一次連線的本機快照，不會自行上傳；只有你按下「匯出」時，
才會交給你選擇的其他 App。

<!-- claim: CLAIM-TELEMETRY-NDJSON -->
**遙測工作階段**記錄行車時的數值時間軸（`.ndjson` 格式），儲存於本機 Documents/telltale-telemetry/ 目錄。
你可以在 App 的遙測紀錄中檢視、手動刪除單筆紀錄，或匯出為 CSV／JSON 檔案。匯出時，結構化欄位會自動排除車輛識別碼（VIN）、GPS 定位座標與使用者帳號；但請注意，自訂訊號名稱、公式、單位與備註是由使用者自行編寫，將依原文保留在匯出檔案中，不會進行自動文字遮蔽。

<!-- claim: CLAIM-SHARE-CACHE-LIFECYCLE -->
**分享暫存檔案**存放於 App 快取目錄（`telltale-app-shares/`）。暫存檔於匯出產生時標記
15 分鐘可清理與 24 小時到期時間戳記。App 於每次啟動及進入分享流程時會檢查並清理過期租約；
這是本機啟動時的維護程序，非作業系統背景排程保證。

<!-- claim: CLAIM-USER-CONTROLLED-SHARE -->
**使用者主動分享與匯出**：App 提供五種正式匯出（原始診斷紀錄、復原診斷紀錄、遙測 CSV、
遙測 JSON、PID CSV）。所有分享均須由使用者主動觸發，未操作前零外傳（零 handoff）。
檔案交給系統分享面板後，接收端 App 如何處理依該 App 政策辦理。在 Telltale 內刪除本機檔案，
無法召回或刪除已交付給外部 App 的副本。

<!-- claim: CLAIM-OS-BACKUP-BEHAVIOR -->
Android、iOS 或 macOS 的作業系統備份可能依你的裝置與雲端備份設定，複製 App 的
私有資料（例如 Documents 與 SharedPreferences；快取目錄通常會被系統排除）。解除安裝會移除裝置上的本機副本，
但不一定會刪除作業系統先前建立的雲端或裝置間移轉（D2D）備份。若不希望備份這些資料，請在裝置設定中停用 Telltale 或整台裝置的備份。

## 網路連線

<!-- claim: CLAIM-NETWORK-ADAPTER-ONLY -->
Telltale 需要 `INTERNET` 權限，用以對使用者設定之 Wi-Fi 型 ELM327 轉接器端點（通常為區域網路位址如
`192.168.0.10:35000`）建立 TCP Socket 連線。App 沒有內建開發者資料收集或遙測上傳服務；轉接器連線目的地由使用者自行設定，Android 系統並無更細緻之權限以限制 Socket 僅能連線至特定私網位址。

<!-- claim: CLAIM-EXTERNAL-AFFILIATE-LINKS -->
連線與設定頁的推薦轉接器是維護者的推廣分潤連結：只有你點下去時，系統才會開啟蝦皮或瀏覽器，
站台政策歸該賣場。點擊外部連結時絕不附加車輛 VIN、診斷紀錄、裝置識別碼或任何個人資料。
其餘功能可以在飛航模式下（開著藍牙）完整使用。

官方車型目錄與字型等資源已完整打包於 App 內，安裝在手機上的 App 採完全離線運作，不會在執行階段發送聯網查詢或下載目錄。僅有開發維護者於開發機上執行的目錄更新工具（`tool/update_us_vehicle_catalog.py`）會自公開政府機關來源下載公開車型資料，與使用者手機上的 App 完全隔離。

## 權限說明

<!-- claim: CLAIM-PERMISSIONS-MINIMAL -->
| 權限 | 用途 |
|---|---|
| `BLUETOOTH_CONNECT` | 連線到已配對的 ELM327 轉接器 |
| `BLUETOOTH_SCAN` | 搜尋尚未配對的 BLE 轉接器（宣告 `neverForLocation`） |
| `BLUETOOTH` / `BLUETOOTH_ADMIN` | Android 11 以下的等效權限 |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | **僅限 Android 11 以下**（`maxSdkVersion="30"`）。舊版 Android 把 BLE 掃描歸在位置權限底下，這是系統規定，不是我們要你的位置。App 不讀取、不儲存、不傳送任何位置資訊 |
| `INTERNET` / `ACCESS_NETWORK_STATE` | 連線 Wi-Fi 型轉接器（見上） |

`BLUETOOTH_ADVERTISE` 在本 App 的資訊清單中以 `tools:node="remove"` 明確移除。這個 App
只當客戶端 —— 它連到轉接器，從不讓手機自己變成可被發現的裝置。移除而非單純不寫，是因為
Android 的資訊清單以聯集合併：只要任何一個相依套件宣告了它，不寫就等於預設帶上。
（2026-08-18 實測合併後的資訊清單：目前沒有任何相依套件宣告它，所以這是保險而不是修正。）

## 第三方服務

<!-- claim: CLAIM-NO-THIRD-PARTY-SDKS -->
**沒有。** App 沒有整合任何分析、廣告、當機回報或行銷 SDK。你可以在
[原始碼](https://github.com/aa22396584/telltale) 的 `pubspec.yaml` 裡自行確認相依套件清單。

## 兒童

本 App 不針對兒童設計，也不會在知情的情況下收集兒童資料 —— 事實上它不收集
任何人的資料。

## 付費與退款

Google Play 處理所有付款。我們看不到你的付款資訊。退款依 Google Play 的政策辦理。

## 開放原始碼

<!-- claim: CLAIM-OPEN-SOURCE-VERIFIABLE -->
Telltale 以 GPL-3.0 授權開放原始碼。本政策所述的每一項，你都可以在
[原始碼](https://github.com/aa22396584/telltale) 中自行驗證 —— 這比任何一份隱私權
政策的文字都更值得相信。

## 變更

本政策若有變更，會更新本頁的日期並在 GitHub 的版本紀錄中留下完整差異。

## 聯絡

有疑問請開 issue：https://github.com/aa22396584/telltale/issues

---

# Telltale Privacy Policy

Last updated: 24 September 2026

## In one sentence

**Telltale itself collects nothing and proactively uploads nothing.** There are
no accounts, ads, analytics, or crash reporting. The only connection the app
itself initiates is to the ELM327 adapter you configure. Recommended-adapter
links open Shopee or a browser only after you tap them.

## What we collect

<!-- claim: CLAIM-DEVELOPER-NO-COLLECTION -->
**Nothing.** Telltale collects nothing and does not collect personal data, and does not send any data
to our servers or to third parties. We have no servers.

## What the app stores on your device

<!-- claim: CLAIM-LOCAL-STORAGE-PARTITION -->
The following are written to the app's private storage, strictly segregated across functional partitions, and are not sent to our servers:

| What | Partition & Location | Why |
|---|---|---|
| Your vehicle profile (displacement, mass, drag coefficient, and the per-field source of each) | `SharedPreferences` | Estimating power and fuel use needs them; the source references exist so a default is never presented as a manufacturer specification |
| Your custom PID definitions | `SharedPreferences` | You wrote them |
| The last adapter and Wi-Fi address used | `SharedPreferences` | So you do not have to find it again |
| Interface preferences (dark/light, gauge skin) | `SharedPreferences` | To remember what you chose |
| The diagnostic transcript (most recent session snapshot) | `Documents/last-session.log` | So you can export it for someone to read when a connection fails |
| Telemetry session history | `Documents/telltale-telemetry/` | For local replay, timeline inspection, or manual export to CSV/JSON |
| Share cache staging & lease ledger | `Caches/telltale-app-shares/` | Temporary staging copies read by system share sheet during export |

<!-- claim: CLAIM-DIAGNOSTIC-RAW-BYTES -->
The **diagnostic transcript** records the raw bytes exchanged with the adapter,
including the VIN and fault codes the vehicle reports, stored locally in Documents/last-session.log. The app retains only the most recent session snapshot locally and never uploads it on its own; pressing Export hands it to another app that you choose.

<!-- claim: CLAIM-TELEMETRY-NDJSON -->
**Telemetry sessions** store numerical signal timeseries (`.ndjson` format) in local Documents/telltale-telemetry/ storage.
You can review sessions in the app, delete individual records, or export CSV/JSON files where structured fields exclude VIN, GPS coordinates, and user accounts; please note that user-authored signal names, equations, units, and notes are preserved in the export as written without automatic text redaction.

<!-- claim: CLAIM-SHARE-CACHE-LIFECYCLE -->
**Share staging artifacts** reside in the application cache directory (`telltale-app-shares/`). Staged files
carry 15-minute cleanup-eligible and 24-hour cleanup-due timestamps upon creation. The app audits and purges eligible staging files upon startup and during share flow entry; this is a local app startup routine, not an OS background daemon guarantee.

<!-- claim: CLAIM-USER-CONTROLLED-SHARE -->
**User-initiated export and sharing**: The app provides five formal export channels (raw transcript, recovered transcript, telemetry CSV, telemetry JSON, PID CSV). All exports require explicit user initiation, with zero pre-action handoff. Once handed to the system share sheet, data is governed by the recipient app's policies. Deleting files locally within Telltale cannot recall or erase copies already delivered to external apps.

<!-- claim: CLAIM-OS-BACKUP-BEHAVIOR -->
Android, iOS, or macOS system backup may copy the app's private data (such as Documents and SharedPreferences; cache folders are typically excluded by the OS) according to your device and cloud-backup settings. Uninstalling removes the local copy from the device, but may not erase a cloud or device-to-device (D2D) backup the operating system already made. Disable backup for Telltale or the device in system settings if you do not want this data backed up.

## Network access

<!-- claim: CLAIM-NETWORK-ADAPTER-ONLY -->
The `INTERNET` permission is used to establish a TCP socket connection to a user-configured Wi-Fi ELM327 adapter endpoint (typically a local network address like `192.168.0.10:35000`). The app has no built-in developer data collection or telemetry upload services; adapter connection destination endpoints depend on user settings, as Android has no narrower permission to restrict socket operations strictly to local subnets.

<!-- claim: CLAIM-EXTERNAL-AFFILIATE-LINKS -->
Recommended-adapter links on Connect and Settings are maintainer affiliate listings:
they open Shopee or a browser only after you tap them, and that store's policy applies
there. Clicking external links never appends VIN, telemetry, device identifiers, or personal data. Everything else works fully in aeroplane mode with Bluetooth on.

The official vehicle catalog and fonts are bundled directly with the app; the installed mobile app operates strictly offline without issuing network queries or downloading catalogs at runtime. Only the maintainer's source-update tool (`tool/update_us_vehicle_catalog.py`) running on developer machines downloads public official catalog data, completely isolated from user devices.

## Permissions

<!-- claim: CLAIM-PERMISSIONS-MINIMAL -->
| Permission | What it is for |
|---|---|
| `BLUETOOTH_CONNECT` | Connecting to a paired ELM327 adapter |
| `BLUETOOTH_SCAN` | Finding an unpaired BLE adapter (declared `neverForLocation`) |
| `BLUETOOTH` / `BLUETOOTH_ADMIN` | The equivalents on Android 11 and below |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | **Android 11 and below only** (`maxSdkVersion="30"`). Older Android files BLE scanning under the location permission. That is the system's rule, not us asking where you are: the app never reads, stores or transmits any location. |
| `INTERNET` / `ACCESS_NETWORK_STATE` | Reaching a Wi-Fi adapter (see above) |

`BLUETOOTH_ADVERTISE` is explicitly removed from this app's manifest with
`tools:node="remove"`. This app is a client — it connects to an adapter and never
makes your phone discoverable. Removed rather than merely omitted, because Android
merges manifests by union: one dependency declaring it would be enough to ship it.
(Checked against the merged manifest on 2026-08-18: no current dependency declares
it, so this is insurance rather than a correction.)

## Third-party services

<!-- claim: CLAIM-NO-THIRD-PARTY-SDKS -->
None. No analytics, advertising, crash reporting or marketing SDKs. You can
verify this yourself in `pubspec.yaml` in the [source](https://github.com/aa22396584/telltale).

## Children

This app is not directed at children and does not knowingly collect data from
them — in fact it collects data from no one.

## Payment and refunds

Google Play handles all payments. We never see your payment details. Refunds
follow Google Play's policy.

## Open source

<!-- claim: CLAIM-OPEN-SOURCE-VERIFIABLE -->
Telltale is GPL-3.0. Every claim in this policy is verifiable in the source,
which is worth more than the policy text.

## Changes

If this policy changes, the date on this page changes with it and the full diff
stays in the GitHub history.

## Contact

https://github.com/aa22396584/telltale/issues
