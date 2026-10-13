# Free APK installation and Android Auto launcher troubleshooting

[繁體中文](#繁體中文) · [English](#english)

## 繁體中文

### 手機已裝好，Android Auto 卻沒有 Telltale？

1.0.19 起，官方 GitLab 免費 APK 在同一個 `com.cbstudio.telltale` 內包含手機
與 Android Auto，不必另外裝 `carproto`。**包含車用元件不代表每台手機的 AA
清單都會顯示它。** AA 也會檢查安裝來源；手機 Demo 正常不能證明車機投影正常。

2026-10-13 在 **Samsung Galaxy Note9／Android 10／Android Auto
17.8.663874-release** 的實測：直接安裝官方 GitLab **1.0.19 arm64-v8a** 後，
自訂啟動器沒有 Telltale，目標 `CAR.VALIDATOR` 紀錄出現 `Package DENIED`。
同一份 APK 用 KingInstaller 2.3 的一般 classic／Google installer 方法覆蓋後，
Telltale 出現且已勾選；撤回工具的臨時權限後仍可見。

最新公開版在本頁更新時是 [1.0.20](https://gitlab.com/aa22396584/telltale/-/releases/v1.0.20)。
**本次 Note9／KingInstaller 方法沒有測過 1.0.20**，也不保證其他手機、Android
或 AA 版本。不要為了重現紀錄而降版。完整版本、校驗碼與結果見
[簡化測試紀錄](evidence/free-apk-installation-20261013/README.md)。

### 可選的 KingInstaller 方法

KingInstaller 是第三方工具，並非 Google 或 Telltale 的官方安裝程式；此方法會
改變 Android 記錄的安裝來源。本次從 `null` 變為 `com.android.vending`，
**不表示 APK 是從 Play 下載、已購買或已通過 Google 車用審核**。使用前先判斷
是否接受第三方工具與下列暫時權限。

1. 保留已安裝的 Telltale，先匯出重要紀錄。從
   [官方 GitLab Releases](https://gitlab.com/aa22396584/telltale/-/releases)
   取得符合手機 ABI、與既有 App 簽章相容的 APK；多數手機使用 arm64-v8a。
   修復清單可用已安裝的同版本 APK，不需要先卸載或清資料。若選新版，須另行
   檢查更新後結果；Play、GitLab、GitHub community 的簽章可能不同。
2. 只從作者的 [KingInstaller 2.3 release](https://github.com/fcaronte/KingInstaller/releases/tag/2.3)
   取得工具。此次資產實際為 2.3／versionCode 10。安裝工具若需開啟瀏覽器或
   檔案管理員的「允許此來源」，只授予該來源，裝完即關閉。
3. 只用一般 **classic／Google package installer** 方法。**Root、Shizuku、
   Oppo／Realme／OnePlus 選項保持關閉**；不按 Reset Default 或 Reinstall
   Google Installer，不更換系統安裝程式。
4. 選取官方 Telltale APK。先看清楚檔案權限範圍：本次 Android 10 的「相片、
   媒體和檔案」授予共用儲存讀寫，**不限於單一 APK**；只在接受這個範圍時
   暫時允許。另只為 KingInstaller 開啟「允許此來源的應用程式」，讓它交給
   系統安裝程式完成更新。
5. 點 **Install as king**，核對系統對話框是更新既有 Telltale、保留資料，再
   安裝。若簽章不符、要求先卸載、Root／Shizuku／所有檔案存取，或關閉
   Play Protect／Auto Blocker 等安全防護，**停止這套方法，保留既有 App**。
6. 到 **Android Auto 設定 → 自訂啟動器**，確認 Telltale 出現且已勾選。
   安裝成功訊息或工具綠燈不能代替這一步；清單顯示也不能代替車機實際啟動。
7. 測完到 Android 系統 App 設定，撤回 KingInstaller 的檔案／媒體／儲存權限，
   並關閉它的「安裝未知應用程式／允許此來源」。刪除不再需要的測試 APK，
   再確認 AA 清單。工具可自行移除；本次留下工具但撤回了儲存讀寫與來源安裝
   權限，沒有清除 Telltale 資料。

未出現時，不要反覆卸載或擴大權限。記下手機型號、Android／AA／Telltale／
工具版本、APK 來源與更新是否被拒絕，再向維護者回報；不要公開裝置序號、
帳戶、完整 logcat 或個人診斷紀錄。日後用一般安裝程式更新 APK **可能改變
來源標記**，更新後請重看清單；這是注意事項，本次未測出它必然重置。

### FAQ 與驗收邊界

**只開 Android Auto「未知來源」就能用嗎？** 本次依序開啟 AA 開發模式、
Application mode = Developer、再開 Unknown sources，三階段都沒有改善。
測後已退出 AA 開發模式、選回 Release 並關閉 Unknown sources。Google 的
[車用 App 測試文件](https://developer.android.com/training/cars/testing#unknown-sources)
也說這個開關不適用於 Car App Library App；它與 Android 系統「允許某 App
安裝 APK」的權限是兩件事。

**一定要買 Google Play 版嗎？** GitLab APK 仍免費。不想使用第三方工具，可
向維護者詢問 Play **internal testing** 名單；有名額且取得邀請才可加入。
[Google 的規則](https://support.google.com/googleplay/android-developer/answer/9845334)
允許最多 100 名內測者免費安裝付費 App；open／closed testing 不同。這不是
公開的免費 Play 通道，也不等同 Internal App Sharing。Play 與 GitLab 簽章可能
不相容，切勿為加入內測而盲目卸載既有 App。

**看到 Telltale 就全部通過了嗎？** 本次證明的是手機 AA 清單可見且勾選。
APK hash、UID、資料 inode、首次安裝時間及權限均保留，但未逐項核對 App
內資料內容。覆蓋後未擷取到新的目標 validator 紀錄，**沒有 validator PASS
的證據**。本次 DHU、實體車機、真車與 OBD 連線均 **NOT_RUN**；
OBD 是否適合 IoT 類別的 [Google 車用審核問題](aa-07/category-fit.md) 仍未解。
1.0.20 release 的其他 DHU 驗收有自己的環境與範圍，不能當成本方法的 Note9
驗收。

## English

### Installed on the phone, but missing from Android Auto?

Since 1.0.19, the free official GitLab APK includes phone and Android Auto
components in `com.cbstudio.telltale`; a separate `carproto` installation is no
longer needed. **Including the component does not guarantee a launcher entry.**
AA also checks installation sources. A working phone Demo does not verify projection.

On 2026-10-13, a **Samsung Galaxy Note9, Android 10, Android Auto
17.8.663874-release** did not list the directly installed official GitLab
**1.0.19 arm64-v8a** APK. Target `CAR.VALIDATOR` logs showed `Package DENIED`.
Updating in place with the **same APK** through KingInstaller 2.3's classic /
Google installer method made Telltale visible and checked. It remained visible
after the tool's temporary permissions were revoked.

The latest public version when this page was updated is
[1.0.20](https://gitlab.com/aa22396584/telltale/-/releases/v1.0.20).
**This Note9 / KingInstaller experiment did not test 1.0.20**, other phones,
Android versions, or AA versions. Do not downgrade to reproduce the record.
See the [public test record](evidence/free-apk-installation-20261013/README.md)
for exact versions, hashes, and results.

### Optional KingInstaller procedure

KingInstaller is a third-party tool, not an official Google or Telltale
installer. It changes Android's recorded installation source: the observed
value changed from `null` to `com.android.vending`. **That does not mean the
APK came from Play, was purchased, or received Google's automotive approval.**
Decide whether you accept the tool and temporary access below.

1. Keep the installed app and export important recordings first. Get an APK for
   your phone's ABI, compatible with the installed app's signer, from
   [official GitLab Releases](https://gitlab.com/aa22396584/telltale/-/releases).
   Most phones use arm64-v8a. The same version can repair visibility; do not
   uninstall or clear data first. A newer version needs its own outcome check.
   Play, GitLab, and GitHub community signers can differ.
2. Obtain the tool only from its author's
   [KingInstaller 2.3 release](https://github.com/fcaronte/KingInstaller/releases/tag/2.3).
   The tested asset reports version 2.3 / versionCode 10. If installing it
   requires allowing your browser or file manager to install apps, permit only
   that source and turn it off afterwards.
3. Use only **classic / Google package installer**. Keep **Root, Shizuku, and
   Oppo / Realme / OnePlus unchecked**. Do not use Reset Default or Reinstall
   Google Installer, or replace a system installer.
4. Select the official Telltale APK and read the file-access prompt. On the
   tested Android 10 phone, photos/media/files granted shared-storage read/write
   access, **not access limited to one APK**. Allow it temporarily only if you
   accept that scope. Separately allow KingInstaller as an app-installation
   source so it can hand the update to the system installer.
5. Choose **Install as king**. Verify the system dialog offers to update existing
   Telltale while keeping data, then install. **Stop and keep your app** if
   signatures conflict, an uninstall is requested, or the flow requires Root,
   Shizuku, all-files access, or disabling Play Protect / Auto Blocker or other
   security protections.
6. Open **Android Auto settings → Customize launcher**. Confirm Telltale is
   listed and checked. An installation message or a green tool indicator does
   not establish this result; a launcher entry does not verify head-unit startup.
7. In Android app settings, revoke KingInstaller's file/media/storage access
   and its permission to install unknown apps. Delete the test APK copy if no
   longer needed, then check the AA list again. You may remove the tool. In this
   experiment it remained installed with storage read/write and installation
   access revoked; Telltale data was not cleared.

If it is still missing, do not repeatedly uninstall or expand access. Report
phone model, Android / AA / Telltale / tool versions, APK source, and update
rejections. Do not publish serials, accounts, full logcat, or personal exports.
Updating later through an ordinary installer **may change the source marker**;
recheck the launcher. This is a precaution, not a reset reproduced in this test.

### FAQ and acceptance limits

**Does AA unknown sources fix it?** Enabling AA developer mode, then Application
mode = Developer, then Unknown sources did not fix any of the three stages.
Afterwards, AA developer mode was exited, Application mode set to Release, and
Unknown sources turned off. Google's
[car-app testing guidance](https://developer.android.com/training/cars/testing#unknown-sources)
says that switch does not apply to Car App Library apps. It is separate from
Android's permission allowing an individual app to install APKs.

**Must I buy the Play edition?** GitLab APKs remain free. If you prefer not to
use a third-party installer, ask about an available invitation to Play
**internal testing**. [Google permits up to 100 internal testers to install paid
apps for free](https://support.google.com/googleplay/android-developer/answer/9845334);
open / closed tests differ. This is invitation-only, not a public free Play
channel or Internal App Sharing. Play and GitLab signatures may be incompatible;
do not blindly uninstall your app to join.

**Does a launcher entry prove everything works?** This experiment establishes
phone AA launcher visibility and selection. APK hash, UID, data inode,
first-install time, and permissions were retained; individual app-data contents
were not audited. No new target validator entries were captured after the
overlay, so **validator PASS was not established**. DHU, physical head units,
real vehicles, and OBD connections were **NOT_RUN in this experiment**.
[OBD / IoT category eligibility](aa-07/category-fit.md) remains unresolved.
The separate 1.0.20 release DHU acceptance has its own scope and environment;
it does not qualify this installation method on Note9.
