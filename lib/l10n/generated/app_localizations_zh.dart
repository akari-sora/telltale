// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get adapterErrorActivityAlert => '匯流排活動警示';

  @override
  String get adapterErrorBufferFull => '轉接器緩衝區溢位';

  @override
  String get adapterErrorBus => '匯流排錯誤，可能是接線問題';

  @override
  String get adapterErrorBusBusy => '匯流排忙碌';

  @override
  String get adapterErrorBusInit => '匯流排初始化失敗';

  @override
  String get adapterErrorCan => 'CAN 匯流排錯誤';

  @override
  String get adapterErrorData => '收到的資料不正確';

  @override
  String get adapterErrorFeedback => '訊號回授錯誤';

  @override
  String get adapterErrorInternal => '轉接器內部錯誤';

  @override
  String get adapterErrorLowPowerAlert => '轉接器即將進入低功耗模式';

  @override
  String get adapterErrorLowVoltageReset => '電壓過低導致轉接器重置';

  @override
  String get adapterErrorNoData => '沒有收到回應（可能是暫時無回應，或車輛不支援）';

  @override
  String get adapterErrorStopped => '傳輸被中斷';

  @override
  String get adapterErrorUnableToConnect => '無法與 ECU 通訊，請確認電門已開啟';

  @override
  String get adapterErrorUnknownCommand => '轉接器不支援此指令';

  @override
  String get appTagline => '車輛即時遙測';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => '外觀';

  @override
  String get connectActivityAbortingPreviousConnection => '正在中止上一個連線，請稍候…';

  @override
  String get connectAnswerBleWithClassic =>
      '選 Bluetooth LE。不需要事先配對，直接在 App 裡掃描 —— 就算它出現在系統的藍牙配對清單裡，也不要去配對，那條路走不通。如果掃描不到，那盒子上的 4.0 只是晶片規格，改用 Bluetooth Classic。';

  @override
  String get connectAnswerBleWithoutClassic =>
      '選 Bluetooth LE。不需要事先配對，直接在 App 裡掃描 —— 就算它出現在系統的藍牙配對清單裡，也不要去配對，那條路走不通。如果掃描不到，先確認轉接器有通電，或改試 Wi‑Fi；此主機未開放 Bluetooth Classic。';

  @override
  String get connectAnswerClassic =>
      '選 Bluetooth Classic。先在系統設定裡配對完成，App 不能代替你配對。配對碼多半是 1234 或 0000。';

  @override
  String get connectAnswerWifiDesktop => '選 Wi-Fi。先把這台裝置連上那個網路，再回來輸入位址。';

  @override
  String get connectAnswerWifiPhone => '選 Wi-Fi。先把手機連上那個網路，再回來輸入位址。';

  @override
  String get connectBleBody =>
      'BLE 轉接器不需事先配對。搜尋後選擇你的裝置即可，常見名稱為 OBDII、V-LINK、Vgate 或 IOS-Vlink。';

  @override
  String connectBleEmptyScan(String next) {
    return '搜尋結束，沒有找到 BLE 轉接器。依序確認：轉接器的燈有沒有亮 —— 多數 OBD 插座要電門轉到 ON 才供電；再來是距離，先坐進車裡再搜尋；${next}BLE 轉接器不需要、也不應該在系統設定裡配對，那條路走不通。';
  }

  @override
  String get connectBleEmptyScanNextClassic =>
      '最後看盒子上的規格，如果寫的是 2.0 或 3.0，那是 Bluetooth Classic，不會出現在這份清單裡，請改用上面的 Bluetooth Classic。';

  @override
  String get connectBleEmptyScanNextWifi =>
      '最後看盒子上的規格：若寫的是 2.0／3.0 或只有 Wi‑Fi，請改試 Wi‑Fi（此主機未開放 Bluetooth Classic）。';

  @override
  String get connectBlePermissionDeniedForever =>
      '藍牙權限已被永久拒絕。系統不會再顯示授權對話框，請到應用程式設定開啟。';

  @override
  String get connectBlePermissionNeeded => '需要藍牙權限才能搜尋。';

  @override
  String get connectBleScan => '搜尋 BLE 裝置';

  @override
  String get connectBleScanning => '搜尋中…';

  @override
  String get connectBleUnavailableHost => 'Bluetooth LE 在此主機尚不可用';

  @override
  String get connectBluetoothOff => '藍牙未開啟，請先在系統設定開啟藍牙。';

  @override
  String get connectBluetoothPermissionDeniedForever =>
      '藍牙權限已被永久拒絕，請到系統設定開啟後再試。';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      '需要藍牙權限才能列出已配對的轉接器。';

  @override
  String get connectBody => '插上 ELM327 轉接器並開啟電門，或直接使用內建模擬器體驗完整功能。';

  @override
  String get connectCancel => '取消';

  @override
  String get connectClassicEmptyLinuxPort =>
      '找不到藍牙序列埠（/dev/rfcomm*）。請先以 BlueZ 配對 ELM327，再用 rfcomm bind（或等效）建立 RFCOMM TTY 後重試。';

  @override
  String get connectClassicEmptyPaired =>
      '找不到已配對的轉接器。請先到系統藍牙設定完成配對（多數 ELM327 的配對碼為 1234 或 0000）。';

  @override
  String get connectClassicEmptyWindowsPort =>
      '找不到藍牙序列埠（COMx）。請先在 Windows 藍牙設定配對 ELM327，確認裝置管理員出現「Standard Serial over Bluetooth link」。';

  @override
  String get connectClassicListLinuxPort =>
      '這裡列出 BlueZ 已綁定的藍牙序列埠（/dev/rfcomm* 或等效）。空清單代表系統尚未建立 RFCOMM 節點，不是 App 壞掉。';

  @override
  String get connectClassicListPaired =>
      '這裡列出系統上所有已配對的裝置 — 耳機、喇叭也會在內，看起來像轉接器的排在前面。選錯了就按「取消」，不必等它自己失敗，取消後可以馬上改選別的。';

  @override
  String get connectClassicListWindowsPort =>
      '這裡列出與藍牙關聯的 COM 埠（「Standard Serial over Bluetooth link」）。空清單代表系統尚未建立虛擬序列埠，不是 App 壞掉。';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic（SPP）目前在 Android、macOS（IOBluetooth RFCOMM）、Windows（COM）與 Linux（/dev/rfcomm*）可用';

  @override
  String get connectClassicUnavailableIos => 'iOS 不開放第三方 App 使用藍牙 SPP';

  @override
  String get connectConnect => '連線';

  @override
  String get connectDemoBody =>
      '模擬一具 2.0L 渦輪四缸引擎，含怠速、加速、巡航與減速循環，訊號彼此物理相關（換檔時轉速下降但車速續增）。故障碼、VIN 讀取與 fastMode 批次查詢皆可完整操作。';

  @override
  String get connectDemoStart => '啟動模擬器';

  @override
  String get connectHandshakeTitle => 'ELM327 初始化';

  @override
  String get connectHandshakeTitleLastAttempt => 'ELM327 初始化（上次嘗試）';

  @override
  String get connectHeadline => '選擇連線方式';

  @override
  String get connectIssueAdapterAcceptedThenSilent =>
      '轉接器接受了連線，但在時限內沒有回應。通常是它還沒通電 —— 多數 OBD 插座要電門轉到 ON 才供電；也可能是它正被另一個 App 連著，先關掉那個再試。';

  @override
  String connectIssueAdapterSilentOnReset(String command) {
    return '轉接器沒有回應重置指令（$command）。這個裝置可能不是 ELM327 轉接器，或是連到了錯誤的裝置。';
  }

  @override
  String get connectIssueAdapterStoppedResponding => '轉接器停止回應，連線已中斷。';

  @override
  String get connectIssueConnectionSetupFailed =>
      '連線在建立過程中失敗了。請確認轉接器已通電、就在附近，然後再試一次。完整的錯誤留在下方的紀錄裡。';

  @override
  String get connectIssueHandshakeIncomplete => '初始化未通過，轉接器可能不相容。';

  @override
  String connectIssueHandshakeStepFailed(String command, String reason) {
    return '初始化在 $command 失敗（$reason）。請確認轉接器已插好、車輛電門已開啟。';
  }

  @override
  String get connectIssuePreviousConnectionStillAborting =>
      '上一個連線仍在中止中，轉接器還沒有釋放。請等幾秒再試一次。';

  @override
  String get connectLastAdapterConnect => '直接連線';

  @override
  String get connectLastAdapterForget => '忘記';

  @override
  String get connectLastAdapterTitle => '上次用的轉接器';

  @override
  String get connectOpenAppSettings => '開啟應用程式設定';

  @override
  String get connectOpenSystemSettings => '開啟系統設定';

  @override
  String get connectOpeningConnection => '建立連線中…';

  @override
  String get connectPairedPill => '已配對';

  @override
  String get connectQuestionBle => '盒子、賣場標題或裝置名稱上有 BLE、4.0、5.0 這些字？';

  @override
  String get connectQuestionClassic => '都不是 —— 比較舊、盒子上寫 2.0 或 3.0？';

  @override
  String get connectQuestionWifiDesktop =>
      '系統的 Wi-Fi 清單裡多出一個網路（像 V-LINK、WiFi_OBDII）？';

  @override
  String get connectQuestionWifiPhone =>
      '手機的 Wi-Fi 清單裡多出一個網路（像 V-LINK、WiFi_OBDII）？';

  @override
  String get connectSearchAgain => '重新搜尋';

  @override
  String connectSignalStrength(int bars, int total) {
    return '訊號強度 $bars/$total';
  }

  @override
  String get connectTranscriptKept => '這次嘗試的完整往返紀錄留著了。帶回來比一句訊息有用。';

  @override
  String get connectTransportBleDescription => 'GATT UART — 較新的低功耗轉接器';

  @override
  String get connectTransportBleTitle => 'Bluetooth LE';

  @override
  String get connectTransportClassicDescription =>
      'RFCOMM / SPP — 最常見的平價 ELM327';

  @override
  String get connectTransportClassicTitle => 'Bluetooth Classic';

  @override
  String get connectTransportDemoDescription => '內建模擬 ECU，無需硬體即可完整體驗';

  @override
  String get connectTransportDemoTitle => 'Demo 模擬器';

  @override
  String get connectTransportWifiDescription => 'TCP 通訊埠，多為 192.168.0.10:35000';

  @override
  String get connectTransportWifiTitle => 'Wi-Fi';

  @override
  String get connectWhichIntro => '不用管 SPP、GATT 這些名詞。看你的轉接器插上去之後怎麼運作就好：';

  @override
  String get connectWhichNoteGuessing =>
      '猜錯不會怎麼樣 —— 連不上就退回來換另一個試。真的卡住，先用最下面的「Demo 模擬器」確認 App 本身正常。';

  @override
  String get connectWhichNoteIos =>
      'iPhone 只能用 Wi-Fi 或 BLE —— 一般的藍牙 ELM327 在 iOS 上完全不能用，這是系統限制，換 App 也一樣。';

  @override
  String get connectWhichTitle => '不確定要選哪一個？';

  @override
  String get connectWifiHostLabel => 'IP 位址';

  @override
  String get connectWifiHostRequired => '請輸入轉接器的 IP 位址。';

  @override
  String get connectWifiInstructionsDesktop =>
      '請先將這台電腦連上轉接器發出的 Wi-Fi 熱點，再輸入其位址。系統若提示此網路無法連上網際網路，請選擇繼續使用。桌面系統通常會把熱點當預設路由；不需要 Android 那套 Wi-Fi 路由綁定。';

  @override
  String get connectWifiInstructionsPhone =>
      '請先將手機連上轉接器發出的 Wi-Fi 熱點，再輸入其位址。系統若問「此 Wi-Fi 無法連上網際網路，是否繼續使用」，選繼續使用。在 Android 上，App 連線時會嘗試把流量固定在 Wi-Fi 路由，避免被行動數據搶走。';

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '「$value」不是有效的通訊埠，範圍是 $min–$max。';
  }

  @override
  String get connectWifiPortLabel => '埠';

  @override
  String connectWifiPortRequired(int port) {
    return '請輸入通訊埠（多數轉接器為 $port）。';
  }

  @override
  String get dashboardBatchedPolling => '批次讀取';

  @override
  String get dashboardBatchingEnabled => '已啟用批次';

  @override
  String get dashboardChoosePids => '選擇 PID';

  @override
  String get dashboardEmptyBody => '到 PID 頁面挑選想要監看的訊號，它們會出現在這裡。';

  @override
  String get dashboardEmptyTitle => '儀表板是空的';

  @override
  String get dashboardGenericObd => '通用 OBD';

  @override
  String get dashboardLocalRecordings => '本機紀錄';

  @override
  String get dashboardNotConnected => '未連線';

  @override
  String get dashboardPollingModeHelpAction => '關於讀取模式';

  @override
  String get dashboardPollingModeHelpBatching =>
      '「已啟用批次」代表 Telltale 可以把多個 PID 請求併成一次交握，以減少來回次數：這條匯流排允許嘗試併批，而且併批沒有被關掉。它仍然是授權而不是量測，因為某一次交握到底有沒有併起來，還要看這輛車確認支援哪些 PID，以及當下排了幾筆。';

  @override
  String get dashboardPollingModeHelpObserved =>
      '「批次讀取」代表這次連線裡，有一筆 Mode 01 指令在線路上一次帶了超過一個 PID。那是對那一次交握的紀錄，不是下一筆也會併批的保證，也不是對吞吐量的主張。';

  @override
  String get dashboardPollingModeHelpRate =>
      'PIDs/s 是過去一秒觀測到的速率，不是對延遲、新鮮度或準確度的保證。它會隨轉接器、匯流排、ECU、你選的 PID、每次回覆的大小以及錯誤而變動。';

  @override
  String get dashboardPollingModeHelpSingle =>
      '「單筆模式」代表每個 Mode 01 PID 各自讀取。三種情況會用到它：匯流排根本不接受併批請求（所有非 CAN 車輛都是如此）；還沒有任何支援區塊回應過，因為把車輛尚未確認的 PID 併起來問，正是回覆會過短的原因；以及併批的請求沒有回來成一份能拆回各 PID 的答覆（被截斷、轉接器回報緩衝區已滿，或根本沒有回應）。讀數仍會持續更新，這本身不等於連線失敗。';

  @override
  String get dashboardPollingModeHelpTitle => '讀取模式';

  @override
  String get dashboardSingleRequestMode => '單筆模式';

  @override
  String get dashboardVinRead => '已讀 VIN';

  @override
  String get dashboardWorkspaceGauges => '儀表';

  @override
  String get dashboardWorkspaceTrends => '趨勢';

  @override
  String get datumBadgeCommunityDecode => '社群解碼';

  @override
  String get datumBadgeDemo => '示範';

  @override
  String get datumBadgeEstimated => '估算';

  @override
  String get datumBadgeExperimental => '實驗';

  @override
  String get datumBadgeFieldVerified => '已驗證';

  @override
  String get datumBadgeInvalid => '無效';

  @override
  String get datumBadgeJustUpdated => '剛更新';

  @override
  String get datumBadgeOutOfReferenceRange => '異常';

  @override
  String get datumBadgePartial => '部分';

  @override
  String get datumBadgeStale => '過期';

  @override
  String get datumBadgeTentativeDecode => '暫定解碼';

  @override
  String get datumBadgeUnverified => '未驗證';

  @override
  String get datumBadgeUnverifiedOnThisVehicle => '本車未驗證';

  @override
  String get datumBadgeUserSupplied => '使用者提供';

  @override
  String get datumGapModelYearUnknown => '年式未知';

  @override
  String get datumGapNoCatalogMatch => '型錄無匹配';

  @override
  String get datumGapVinNotRead => 'VIN 未讀到';

  @override
  String get datumNextStepEstimateOnly => '只影響此估算，其他讀值照用';

  @override
  String get datumNextStepGenericObd => '可繼續通用 OBD，或手動選車、補參數';

  @override
  String get datumNextStepOtherReadings => '失敗只影響此項，其他讀值照用';

  @override
  String get datumNextStepRawOnly => '可看 raw / error，不可當成正常數值';

  @override
  String get datumReasonAssumptionsUnconfirmed => '假設尚未確認，仍可估算';

  @override
  String get datumReasonBusError => '匯流排錯誤';

  @override
  String get datumReasonFormulaError => '公式錯誤';

  @override
  String get datumReasonFuelEstimateMissingInputs => '油耗缺少必要輸入';

  @override
  String get datumReasonHeaderNotOnThisBus => '標頭不符本車匯流排';

  @override
  String get datumReasonHorsepowerEstimateMissingInputs => '馬力缺少必要輸入';

  @override
  String get datumReasonMalformedPacket => '壞封包，只可查看原文';

  @override
  String get datumReasonNoAnswer => '無回應，稍後重試';

  @override
  String get datumReasonNoReadingYet => '尚無讀值';

  @override
  String get datumReasonNonFiniteValue => '非有限數值';

  @override
  String get datumReasonOutOfReferenceRangeKept => '超出一般參考範圍，已保留';

  @override
  String get datumReasonPidUnsupported => '此車輛不支援這個 PID';

  @override
  String get datumReasonUnsafeService => '此服務不是唯讀查詢';

  @override
  String get datumReasonUnsafeServiceStopped => '此服務不是唯讀查詢，已停止發送';

  @override
  String get datumStatusAssumptions => '假設';

  @override
  String get datumStatusClose => '關閉';

  @override
  String get datumStatusFollowsData => '狀態隨資料';

  @override
  String get datumStatusDetailsHint => '點按查看讀值狀態說明';

  @override
  String get datumStatusUnverifiedExplanation =>
      '未驗證表示此處沒有這個解碼與本車實際比對的驗證紀錄，不代表讀值錯誤，也不保證讀值準確。更新狀態與異常會另外標示。';

  @override
  String get datumStatusFormula => '公式';

  @override
  String get derivedAirflow => '空氣流量';

  @override
  String get derivedEcuFuelTitle => 'ECU 油耗資料';

  @override
  String get derivedEcuReported => 'ECU 回報';

  @override
  String get derivedEngineHorsepower => '引擎馬力';

  @override
  String get derivedEstimatedFuelTitle => '估算油耗';

  @override
  String get derivedEstimatesDetailsTitle => '估算公式與假設';

  @override
  String get derivedEstimatesTitle => '推算數值';

  @override
  String get derivedFuelUse => '油耗';

  @override
  String get derivedTorque => '扭力';

  @override
  String get derivedUnavailableMessage => '等待車速與加速度資料後才能推算馬力';

  @override
  String dtcBothSilentDetail(Object mode) {
    return '車輛沒有回應 Mode $mode 查詢，而 Mode 03 同樣沒有回應 — 因此無法判斷這是車輛不支援，還是這次連線沒有讀到。';
  }

  @override
  String dtcCategoryFault(Object category) {
    return '$category相關故障';
  }

  @override
  String get dtcClear => '清除';

  @override
  String get dtcClearCancel => '取消';

  @override
  String get dtcClearConfirm => '確定清除';

  @override
  String get dtcClearDialogBody =>
      '這會清掉已儲存與待確認的故障碼並熄滅故障燈，同時重置排放就緒狀態 — 車輛需要重新完成一輪自我診斷才能通過驗車。永久故障碼（Mode 0A）無法清除。';

  @override
  String get dtcClearDialogFrameUnread =>
      '這次沒有讀到凍結幀，但不代表車上沒有。先重新掃描一次，再決定要不要清除。';

  @override
  String dtcClearDialogFrames(Object codes) {
    return '連同 $codes 的凍結幀 —— 故障發生當下的轉速、水溫、負荷那一整份紀錄 —— 也會一起消失，而且故障再次發生前讀不回來。';
  }

  @override
  String get dtcClearDialogTitle => '清除故障碼？';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    return '這次掃描有 $count 個類別沒有得到完整回應（$categories），可能還有你沒看到的故障碼。清除後就再也讀不到了。';
  }

  @override
  String get dtcClearCancelledBeforeSend => '清除已取消，指令還沒送出到車上。可以重新掃描後再試一次。';

  @override
  String get dtcClearConfirmed => '已送出清除指令。';

  @override
  String get dtcClearFailureDoNotRepeat =>
      '清除指令可能已經送到車上。不要再送一次 —— 第二次全車清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認還剩下什麼。';

  @override
  String get dtcClearFailureGeneric => '清除沒有完成。請先重新掃描，看目前的故障碼，再決定要不要再試。';

  @override
  String get dtcClearNotAccepted => '清除失敗，沒有控制器接受指令。可以再試一次。';

  @override
  String get dtcClearPartiallyConfirmed =>
      '已有控制器回報清除完成，但其餘控制器無法確認。不要再送一次清除 —— 重複清除會讓已完成的控制器再一次重置排放就緒狀態。請重新掃描確認結果。';

  @override
  String get dtcClearPreviousConnectionUnconfirmed =>
      '上一次連線送出過清除指令，結果沒有確認。請先重新掃描，確認哪些故障碼還在，再決定要不要清除。';

  @override
  String get dtcClearRescanSettled => '上一次清除的結果無法完全確認，以下是重新掃描後的實際狀況。';

  @override
  String get dtcClearSentUnconfirmed =>
      '清除指令已送出，但回應在傳輸過程中損毀，無法確認車輛是否已清除。請重新掃描確認結果，不要直接再清除一次 —— 如果其實已經清除成功，再清一次會重置排放就緒狀態。';

  @override
  String get dtcClearTimeout => '清除指令送出後沒有回應，無法確認是否已清除。請重新掃描確認。不要直接再清除一次。';

  @override
  String get dtcClearUnexpected => '清除失敗，無法確認車輛是否已清除，請重新掃描確認。不要直接再清除一次。';

  @override
  String get dtcClearing => '清除中…';

  @override
  String get dtcScanDisconnectedMidScan => '連線在掃描途中中斷，這次掃描沒有完成。';

  @override
  String get dtcScanInterrupted =>
      '掃描在中途被中斷（可能是切換到其他 App 或連線變更），沒有得到完整結果。請重新掃描。';

  @override
  String get dtcCompleteCleanBody => '這代表每個回覆的控制器都回報無故障碼，不代表車上每個模組都已被問到。';

  @override
  String get dtcCompleteCleanTitle => '已回應的控制器都沒有故障碼。';

  @override
  String dtcControllerLabel(Object controller) {
    return '控制器 $controller';
  }

  @override
  String get dtcDismiss => '關閉';

  @override
  String dtcFreezeFrameBody(Object code) {
    return '$code 被確認的那一刻，這個控制器記下的數值。清除故障碼會一併銷毀這份紀錄。';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      '這個控制器有凍結幀，但沒有回應「裡面有哪些項目」的查詢，所以讀不到內容。可以重新掃描再試一次。';

  @override
  String get dtcFreezeFrameNothingDecodable => '這個控制器有凍結幀，但其中沒有本 App 能解讀的項目。';

  @override
  String get dtcFreezeFrameTitle => '故障發生當下的車況';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    return '另有 $count 個項目在這份凍結幀裡，本 App 沒有對應的換算公式，所以沒有列出。';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    return '有 $count 個項目這次沒有讀回來（可能是時間不夠或控制器沒回應）。重新掃描可能會讀到。';
  }

  @override
  String get dtcFreezeFrameUnreadPanel =>
      '這次沒有讀到凍結幀 —— 不代表車上沒有。請先重新掃描再決定要不要清除故障碼，因為清除會永久銷毀故障當下的紀錄。如果每次掃描都一樣，可能是這台車不提供。';

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label（Mode $mode）· $count';
  }

  @override
  String get dtcHeadline => '故障碼';

  @override
  String get dtcListSeparator => '、';

  @override
  String get dtcManufacturerSpecific => '原廠自訂碼 — 需查閱該車系維修手冊';

  @override
  String get dtcMilOff => '故障燈沒有亮';

  @override
  String get dtcMilOn => '故障燈亮著';

  @override
  String get dtcMonitorBoostPressure => '增壓壓力';

  @override
  String get dtcMonitorCatalyst => '觸媒轉換器';

  @override
  String get dtcMonitorComponents => '綜合元件監控';

  @override
  String get dtcMonitorEgr => 'EGR / VVT 系統';

  @override
  String get dtcMonitorEvaporative => '蒸發排放系統';

  @override
  String get dtcMonitorExhaustSensor => '排氣感知器';

  @override
  String get dtcMonitorFuelSystem => '燃油系統監控';

  @override
  String get dtcMonitorGasolineParticulateFilter => '汽油微粒濾清器（GPF）';

  @override
  String get dtcMonitorHeatedCatalyst => '觸媒加熱';

  @override
  String get dtcMonitorMisfire => '失火監控';

  @override
  String get dtcMonitorNmhcCatalyst => 'NMHC 觸媒';

  @override
  String get dtcMonitorNoxAftertreatment => 'NOx / SCR 後處理';

  @override
  String get dtcMonitorOxygenSensor => '含氧感知器';

  @override
  String get dtcMonitorOxygenSensorHeater => '含氧感知器加熱';

  @override
  String get dtcMonitorParticulateFilter => '微粒濾清器';

  @override
  String get dtcMonitorSecondaryAir => '二次空氣噴射';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — 本 App 沒有這一碼的詳細說明';
  }

  @override
  String get dtcNotConnectedBody => '需要連上 ELM327 轉接器或啟動模擬器才能讀取故障碼。';

  @override
  String get dtcNotConnectedTitle => '尚未連線';

  @override
  String get dtcNotScanned => '尚未掃描';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    return '三個類別都查詢完成了。有 $count 個控制器（$controllers）沒有實作待確認或永久故障碼 —— 這在很多車上是正常的，但也因此不能宣告全車都沒有故障碼。';
  }

  @override
  String get dtcPartialCleanTitle => '已回應的項目沒有故障碼。';

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories 沒有回應，狀態無法確認 — 這不等於車輛沒有問題。';
  }

  @override
  String dtcPartialCodesRead(int count) {
    return '這個類別中止前已讀到 $count 筆故障碼，但涵蓋範圍不完整：';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return '這個類別只有部分控制器回應，其餘沒有回覆，因此不能當作全車的結果。$message';
  }

  @override
  String get dtcReadFailed => '讀取失敗';

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label（Mode $mode）：$message';
  }

  @override
  String get dtcReadinessAllComplete => '這個控制器負責的監控項目都已完成。';

  @override
  String dtcReadinessIncomplete(int count) {
    return '還有 $count 項沒有完成，現在去驗車可能不會過。';
  }

  @override
  String get dtcReadinessSaysNothing =>
      '這個控制器沒有回報任何監控項目 —— 它可能不負責排放監控，這不代表已經就緒。';

  @override
  String get dtcReadinessTitle => '排放就緒狀態';

  @override
  String get dtcRescanFirst => '請先重新掃描';

  @override
  String get dtcRetry => '重試';

  @override
  String get dtcScanBody => '讀取 Mode 03 已儲存、Mode 07 待確認與 Mode 0A 永久故障碼。';

  @override
  String get dtcScanTitle => '掃描車輛故障碼';

  @override
  String get dtcScanning => '掃描中…';

  @override
  String dtcSelfReportedCodes(int count) {
    return '這個控制器自報有 $count 個已確認的故障碼。';
  }

  @override
  String get dtcSelfReportedNoCodes => '這個控制器自報沒有已確認的故障碼。';

  @override
  String get dtcSilentCategoryHeadline => '這個類別沒有回應';

  @override
  String get dtcSilentPendingDetail =>
      '待確認故障碼（Mode 07）沒有回應。可能是這具 ECU 未實作這個服務，也可能是這次沒有讀到 —— 沒有回應無法分辨兩者，也不能當作「沒有待確認故障」。已儲存故障碼的結果不受影響。';

  @override
  String get dtcSilentPermanentDetail =>
      '永久故障碼（Mode 0A）沒有回應。這個類別在 2010 年前後才隨新一代 OBD-II 導入，較舊的車輛不一定支援 —— 但沒有回應也可能只是這次沒讀到，兩者無法分辨。已儲存故障碼的結果不受影響。';

  @override
  String get dtcStartScan => '開始掃描';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return '車輛沒有回應 Mode $mode 查詢，因此無法確認是否有已儲存的故障碼。這與「沒有故障碼」不是同一件事。';
  }

  @override
  String dtcTotalCodes(int count) {
    return '共 $count 筆';
  }

  @override
  String get dtcUnconfirmed => '無法確認';

  @override
  String get dtcUnknownError => '未知錯誤';

  @override
  String get dtcUnknownMonitor => '未知監控項目';

  @override
  String get dtcVerdictCompleteClean => '已回應的控制器沒有故障碼';

  @override
  String get dtcVerdictPartialClean => '部分未確認';

  @override
  String get fieldEventBody =>
      '只在車輛完全停妥時，由乘客或停車中的操作人員按下。事件會與 OBD 原始資料使用同一條時間軸並嘗試立即保存。';

  @override
  String get fieldEventEngineStarted => '引擎發動';

  @override
  String get fieldEventHeading => '實車事件標記';

  @override
  String get fieldEventIgnitionOn => '電門 ON';

  @override
  String get fieldEventMemoryOnly => '已記在目前工作階段，但自動保存失敗；請立刻匯出紀錄。';

  @override
  String fieldEventRecorded(String marker) {
    return '已記錄並保存：$marker';
  }

  @override
  String get fieldEventRoadTestStarted => '道路測試開始';

  @override
  String get fieldEventThrottleBlip => '輕踩油門';

  @override
  String get fieldEventUnavailable => '目前沒有可記錄的實車連線。';

  @override
  String get gaugeNoData => '無資料';

  @override
  String gaugeNoDataBecause(String reason) {
    return '無資料 — $reason';
  }

  @override
  String gaugeReadingStale(String reading) {
    return '$reading（資料已過期）';
  }

  @override
  String get gaugeUnsupportedByVehicle => '此車輛不支援';

  @override
  String get handshakeNoteAborted => '已中止';

  @override
  String get handshakeNoteEcuRefusedSupportQuery =>
      'ECU 拒絕了支援度查詢（negative response）';

  @override
  String get handshakeNoteEcuSilent => 'ECU 沒有回應';

  @override
  String get handshakeNoteNotAcknowledged => '轉接器未確認此指令';

  @override
  String get handshakeNoteNotModeOnePositiveReply => '回應不是 Mode 01 的正向回覆';

  @override
  String get handshakeNotePidEchoMismatch => '回應的 PID 與查詢不符';

  @override
  String get handshakeNoteSupportMaskTooShort => '支援度回應過短（需要 41 00 加四個位元組）';

  @override
  String get handshakeNoteTimedOut => '逾時';

  @override
  String get handshakeStepAdapterVersion => '讀取轉接器版本';

  @override
  String get handshakeStepAdaptiveTiming => '啟用自適應計時（datasheet 建議值）';

  @override
  String get handshakeStepBatteryVoltage => '讀取電瓶電壓';

  @override
  String get handshakeStepDeviceIdentity => '讀取裝置識別字串';

  @override
  String get handshakeStepEchoOff => '關閉指令回音';

  @override
  String get handshakeStepLinefeedsOff => '關閉換行字元';

  @override
  String get handshakeStepMemoryOff => '關閉記憶體寫入';

  @override
  String get handshakeStepNoReason => '無回應';

  @override
  String get handshakeStepProtocolAuto => '自動偵測匯流排協定';

  @override
  String get handshakeStepProtocolDescription => '讀取協定描述';

  @override
  String get handshakeStepProtocolNumber => '讀取協定編號';

  @override
  String get handshakeStepReset => '軟體重置轉接器';

  @override
  String get handshakeStepResponseTimeout => '設定回應逾時 ~408ms';

  @override
  String get handshakeStepSpacesOff => '關閉空白字元，減少 33% 傳輸量';

  @override
  String get handshakeStepSupportProbe => '查詢 ECU 支援的 PID（確認車輛已回應）';

  @override
  String get languageSaveFailed => '無法儲存語言設定，請再試一次。';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get navDashboard => '儀表板';

  @override
  String get navDtc => '故障碼';

  @override
  String get navPerformance => '性能';

  @override
  String get navPid => 'PID';

  @override
  String get navSettings => '設定';

  @override
  String get performanceArm => '準備計時';

  @override
  String get performanceDisclaimer =>
      '成績以 OBD 車速訊號為準。多數車輛的車速表本身有 1–3 km/h 的正偏差，且訊號更新率約每秒 10–20 次，因此結果僅供參考，不等同於專業測試設備。';

  @override
  String get performanceHeadline => '加速測試';

  @override
  String get performanceNoSpeedSignal => '目前沒有有效的車速訊號（PID 010D）。加速測試需要它才能計時。';

  @override
  String get performanceNotConnectedBody => '加速測試需要即時車速資料，請先連線或啟動模擬器。';

  @override
  String get performanceNotConnectedTitle => '尚未連線';

  @override
  String get performancePeakSpeed => '最高車速';

  @override
  String get performanceReset => '重置';

  @override
  String get performanceSecondsUnit => '秒';

  @override
  String get performanceSpeedGaugeLabel => '車速';

  @override
  String get performanceSpeedTraceHeading => '速度軌跡';

  @override
  String get performanceSplitsHeading => '分段成績';

  @override
  String get performanceStateAborted => '這次計時未完成，以下為中止前的紀錄';

  @override
  String get performanceStateAwaitingSpeedSignal => '等待車速訊號';

  @override
  String performanceStateAwaitingStandstill(String speed) {
    return '請先完全停車 — 目前 $speed km/h';
  }

  @override
  String performanceStateFinished(int target) {
    return '完成 0 → $target km/h';
  }

  @override
  String get performanceStateIdle => '選擇目標車速後開始';

  @override
  String get performanceStateRunning => '計時中';

  @override
  String get performanceStateStaged => '已就緒 — 起步即開始計時';

  @override
  String get performanceSubhead => '由靜止起步計時至目標車速';

  @override
  String get performanceTargetSpeedHeading => '目標車速';

  @override
  String get pidActionCancel => '取消';

  @override
  String get pidActionDelete => '刪除';

  @override
  String get pidArrangeBody => '拖曳調整順序。儀表板由左至右、由上而下填滿，排在前面的最先看到。';

  @override
  String get pidArrangeEmptyMessage => '先在清單中啟用幾項，再回來排列順序。';

  @override
  String get pidArrangeEmptyTitle => '還沒有啟用任何 PID';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return '加入已確認的 $count 項';
  }

  @override
  String get pidBulkActionAllActive => '已全部啟用';

  @override
  String get pidBulkActionIncomplete => '掃描資料不完整';

  @override
  String get pidBulkActionLocked => '錄製中無法變更';

  @override
  String get pidBulkActionPending => '等待掃描結果';

  @override
  String get pidBulkActionZero => '沒有確認支援項目';

  @override
  String pidBulkAddCount(int count) {
    return '加入 $count 項';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return '加入 $count 項已確認支援 PID？';
  }

  @override
  String pidBulkAdded(int count) {
    return '已加入 $count 項已確認支援 PID。';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '仍有 $count 個支援區塊未確認，這次只加入已有正面證據的項目。';
  }

  @override
  String pidBulkWillAdd(int count) {
    return '將加入 $count 項。啟用越多 PID，單項資料的更新頻率可能降低。';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '確認 $confirmed 項';
  }

  @override
  String get pidCapabilityCoverageNone => '連續涵蓋尚未建立';

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return '連續涵蓋 01–$through（已到終點）';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return '連續涵蓋 01–$through（後續未知）';
  }

  @override
  String get pidCapabilityPhaseAttemptFinished => '本次支援掃描已完成';

  @override
  String get pidCapabilityPhaseInterrupted => '支援掃描已中斷';

  @override
  String get pidCapabilityPhaseNotStarted => '尚未開始掃描';

  @override
  String get pidCapabilityPhaseRunning => '正在確認車輛支援項目';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return '車輛支援 PID。$phase。確認 $confirmed 項。未知區塊 $unknown 個。';
  }

  @override
  String get pidCapabilityTitle => '車輛支援 PID';

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '未知區塊 $unknown';
  }

  @override
  String pidEditorCollision(String name) {
    return '已經有一個自訂 PID 使用這組設定（$name）。請改用不同的模式 + PID、標頭或名稱後綴。';
  }

  @override
  String pidEditorDeleteBody(String name) {
    return '「$name」的定義會被移除，儀表板上的這個錶也會一起消失，而且無法復原。';
  }

  @override
  String get pidEditorDeleteTitle => '刪除這個 PID？';

  @override
  String get pidEditorDiscard => '放棄';

  @override
  String get pidEditorDiscardBody => '這個 PID 的修改還沒有儲存，離開後會遺失。';

  @override
  String get pidEditorDiscardTitle => '放棄未儲存的變更？';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N 對應回應位元組；可用 SIGNED()、ABS()、LOG10()、$valSyntax、BARO';
  }

  @override
  String get pidEditorFieldEquation => '運算式';

  @override
  String get pidEditorFieldHeader => 'CAN 標頭';

  @override
  String get pidEditorFieldMax => '最大值';

  @override
  String get pidEditorFieldMin => '最小值';

  @override
  String get pidEditorFieldModeAndPid => '模式 + PID';

  @override
  String get pidEditorFieldName => '名稱';

  @override
  String get pidEditorFieldSample => '測試用回應位元組';

  @override
  String get pidEditorFieldShortName => '簡稱（顯示於錶面）';

  @override
  String get pidEditorFieldUnits => '單位';

  @override
  String get pidEditorHeaderHelper => '7E0 = 引擎';

  @override
  String get pidEditorKeepEditing => '繼續編輯';

  @override
  String get pidEditorModeAndPidHelper => '例如 010C 或 221101';

  @override
  String get pidEditorSampleHelper => '輸入十六進位，即時預覽計算結果';

  @override
  String get pidEditorSave => '儲存';

  @override
  String get pidEditorSectionFormula => '公式';

  @override
  String get pidEditorSectionIdentity => '識別';

  @override
  String get pidEditorSectionQuery => '查詢';

  @override
  String get pidEditorSectionRangeAndPriority => '錶面範圍與優先權';

  @override
  String get pidEditorTitleEdit => '編輯 PID';

  @override
  String get pidEditorTitleNew => '新增自訂 PID';

  @override
  String pidExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String get pidExportNoCustomPids => '目前沒有自訂 PID 可匯出。';

  @override
  String get pidImportNothingToImport => '沒有可匯入的定義。';

  @override
  String pidImportLandedClean(int count) {
    return '已匯入 $count 項自訂 PID。';
  }

  @override
  String pidImportLandedWithNotes(int count, String notes) {
    return '匯入 $count 項，$notes。';
  }

  @override
  String pidImportNoteSkippedRows(int count) {
    return '$count 行有問題已略過';
  }

  @override
  String pidImportNoteDefaultedRanges(int count) {
    return '$count 行套用了預設量程';
  }

  @override
  String pidImportNoteReplaced(int count) {
    return '$count 項覆蓋了現有定義';
  }

  @override
  String pidImportNoteDuplicatesInFile(int count) {
    return '$count 行與檔案內其他行重複已略過';
  }

  @override
  String get pidImportPickerFailed => '無法開啟檔案選擇器。';

  @override
  String get pidImportReadFailed => '讀取檔案失敗。';

  @override
  String get pidListSeparator => '、';

  @override
  String get pidManagerActiveOnly => '只顯示已啟用';

  @override
  String get pidManagerAdd => '新增';

  @override
  String get pidManagerArrangeDashboard => '排列儀表板';

  @override
  String pidManagerCounts(int active, int total) {
    return '已啟用 $active 項 · 共 $total 項可用';
  }

  @override
  String get pidManagerExportCsv => '匯出自訂 PID';

  @override
  String get pidManagerExportTorqueCsv => '匯出 Torque 相容 CSV';

  @override
  String get pidManagerExportHumanReport => '匯出人類可讀 PID 報表';

  @override
  String get pidManagerHeadline => 'PID 管理';

  @override
  String get pidManagerImportCsv => '匯入 CSV';

  @override
  String get pidManagerMoreActions => '更多';

  @override
  String get pidManagerNoMatchMessage => '換個關鍵字，或建立一個自訂 PID。';

  @override
  String get pidManagerNoMatchTitle => '沒有符合的 PID';

  @override
  String get pidManagerPowertrainBatteryCatalog => '大電池目錄';

  @override
  String get pidManagerSearchHint => '搜尋名稱或 PID 代碼…';

  @override
  String get pidPickCsvDialogTitle => '選擇 PID 定義 CSV';

  @override
  String get pidPillCustom => '自訂';

  @override
  String get pidPillUnsupported => '不支援';

  @override
  String get pidPreviewCannotEvaluate => '無法計算';

  @override
  String get pidPreviewResultLabel => '計算結果';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '預覽時以 $valueString 代入 $dependencies；實際數值會在連線後由該 PID 提供。';
  }

  @override
  String get pidPreviewTitle => '即時預覽';

  @override
  String get pidPriorityHigh => '高';

  @override
  String get pidPriorityLow => '低';

  @override
  String get pidPriorityMedium => '中';

  @override
  String get pidPriorityVeryLow => '極低';

  @override
  String get pidRowEdit => '編輯';

  @override
  String pidRowShowOnDashboard(String name) {
    return '在儀表板顯示 $name';
  }

  @override
  String pidRowStaleUnits(String units) {
    return '$units · 已過期';
  }

  @override
  String powertrainAuthorizationGranted(String profile) {
    return '已啟用 $profile 的電池訊號（本次連線）';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return '無法啟用：$reason';
  }

  @override
  String get powertrainCancel => '取消';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return '$profiles 個車型 · $probeable 個可單次讀取';
  }

  @override
  String get powertrainCatalogLoadFailedBody => '完整性驗證沒有通過，因此沒有顯示或安裝任何車型資料。';

  @override
  String get powertrainCatalogLoadFailedTitle => '離線目錄無法載入';

  @override
  String get powertrainCatalogNotVerified => '目錄尚未通過驗證，無法安裝。';

  @override
  String get powertrainCatalogRevalidate => '重新驗證';

  @override
  String get powertrainCatalogScopeNote =>
      '目錄很廣，但「找到資料」不等於「已支援」。僅研究項目永遠沒有指令。Mode 22 實驗項目可安裝並輪詢，但每個數值都標為未驗證；Mode 21 實驗項目每次確認後只讀一次。';

  @override
  String get powertrainCatalogSearchHint => '搜尋品牌、車型、版本或市場…';

  @override
  String get powertrainCatalogTitle => '大電池車型目錄';

  @override
  String get powertrainChooseCommandNote => '每次只送一條，不掃描、不批次、不自動重試。';

  @override
  String get powertrainChooseCommandTitle => '選擇一條固定唯讀查詢';

  @override
  String get powertrainClose => '關閉';

  @override
  String get powertrainConfirmAccept => '就是這台車';

  @override
  String get powertrainConfirmBody =>
      '已安裝的車型訊號要先確認這台車就是該車型，本次連線才會開始讀取。確認只對這次連線有效。';

  @override
  String get powertrainConfirmButton => '確認車輛';

  @override
  String get powertrainConfirmDialogBody =>
      '確認後，這個車型的唯讀電池查詢會在本次連線內定期輪詢。接錯車型可能得到看似合理但錯誤的數字——不確定就取消。';

  @override
  String get powertrainConfirmDialogTitle => '確認連線中的車輛';

  @override
  String get powertrainConfirmTitle => '車輛電池訊號待確認';

  @override
  String get powertrainConnectFirst => '請先連線；實驗授權不會跨連線保留。';

  @override
  String get powertrainConnectionChanged => '連線已改變，請對新的連線重新確認車輛。';

  @override
  String get powertrainEnableLabInSettings => '請先到設定開啟「大電池證據實驗室」。';

  @override
  String get powertrainEvidencePhysicalVehicle => '專案實車';

  @override
  String get powertrainEvidenceSourceBacked => '來源資料';

  @override
  String get powertrainEvidenceSyntheticRig => '合成測試台';

  @override
  String get powertrainExperimentalDataDisclosure =>
      '這是來源作者標示的候選讀取，不是原廠或跨車款安全保證；ELM327 只負責轉送命令。原始指令與回覆會留在本機診斷紀錄，不會由此功能自動上傳；解碼值不會安裝成 PID 或加入儀表。取消不影響一般 OBD 功能。';

  @override
  String get powertrainExperimentalDialogTitle => '單次實驗唯讀確認';

  @override
  String get powertrainExperimentalIdentityAck => '我已核對來源已知的市場、車型與年式，並接受未證實欄位';

  @override
  String get powertrainExperimentalParkedAck => '車輛已安全停妥；我知道這只讀一次，數字仍可能不適用';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return '只接受 RX $responder，資料長度 $bytes bytes';
  }

  @override
  String get powertrainFieldListSeparator => '、';

  @override
  String get powertrainFieldMarket => '市場';

  @override
  String get powertrainFieldModel => '車型';

  @override
  String get powertrainFieldModelYear => '年式';

  @override
  String get powertrainFieldVariant => '版本';

  @override
  String get powertrainFilterAll => '全部';

  @override
  String get powertrainIdentityEvidenceExact => '直接證據';

  @override
  String get powertrainIdentityEvidenceNone => '無';

  @override
  String get powertrainIdentityEvidenceSourcePartial => '部分證據';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return '來源身分證據：$fields\n未證實欄位：$unconfirmed';
  }

  @override
  String get powertrainIdentityEvidenceUnknown => '未知';

  @override
  String get powertrainInstallButton => '安裝電池訊號';

  @override
  String get powertrainInstallConfirm => '安裝';

  @override
  String get powertrainInstallDialogTitle => '安裝車型電池訊號';

  @override
  String get powertrainInstallDisclosureCommunity =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。資料來自社群來源並經獨立比對，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureExperimental =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。這是實驗解碼，沒有獨立佐證要求，本車未驗證，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureReady =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。來源資料較完整，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。此列僅供研究，不應安裝。';

  @override
  String get powertrainInstallCatalogShaMissing =>
      '無法安裝：這份目錄快照沒有已驗證的 SHA-256，因此其中任何內容都不能信任。';

  @override
  String get powertrainInstallPersistFailed =>
      '無法安裝：已安裝設定檔清單無法寫入。請再試一次；PID 管理沒有新增任何項目。';

  @override
  String get powertrainInstallProfileNotInCatalog => '無法安裝：這個設定檔不在已驗證的目錄中。';

  @override
  String get powertrainInstallProfileNotInstallable =>
      '無法安裝：這個設定檔目前不能變成實際的 PID。';

  @override
  String get powertrainInstallYearOutOfRange => '無法安裝：該年式不在這個設定檔記載的年份範圍內。';

  @override
  String get powertrainInstallIdentityAck => '我的車輛符合上述市場、車型與年式';

  @override
  String get powertrainInstalledRemoveButton => '已安裝 · 移除訊號';

  @override
  String powertrainInstalledSignalsSnack(int count) {
    return '已安裝 $count 個訊號。到 PID 頁面加入儀表板；每次連線需確認車輛。';
  }

  @override
  String get powertrainNoMatchBody => '改用品牌、車型名稱，或切換其他動力型式。';

  @override
  String get powertrainNoMatchTitle => '沒有符合的車型';

  @override
  String get powertrainNotInstallableInThisRelease => '此版本不可安裝';

  @override
  String powertrainPrimarySource(String name, String license) {
    return '主要來源：$name（$license）';
  }

  @override
  String get powertrainProbeChecksPassed =>
      '已通過 responder、echo、exact length、公式與範圍檢查。';

  @override
  String get powertrainProbeConnectForOneShot => '連線後單次唯讀';

  @override
  String get powertrainProbeConnectToTryOnce => '連線後可先單次試讀';

  @override
  String get powertrainProbeDidNotFinish => '單次查詢沒有完成；沒有發布或保留數值。';

  @override
  String get powertrainProbeEnableLabFirst => '先在設定開啟實驗室';

  @override
  String get powertrainProbeInProgress => '單次查詢中…';

  @override
  String get powertrainProbeNoValuePublished => '沒有發布數值；結構或解碼錯誤會隔離到重新連線。';

  @override
  String get powertrainProbeOnceButton => '只讀這一次';

  @override
  String get powertrainProbePassedTitle => '單次查詢通過';

  @override
  String get powertrainProbePickOneRead => '選一條，唯讀一次';

  @override
  String get powertrainProbeReconnectFirst => '重新連線後再試';

  @override
  String get powertrainProbeRefusedTitle => '單次查詢已拒絕';

  @override
  String get powertrainProbeTryOnceFirst => '先試讀一次';

  @override
  String get powertrainProfileNotVerified => '設定檔不在已驗證目錄中';

  @override
  String get powertrainQuarantinedPill => '本次連線已隔離';

  @override
  String get powertrainRefusedCatalogHashInvalid =>
      '未授權：目錄的完整性雜湊無效，因此其中任何內容都不能讀取。';

  @override
  String get powertrainRefusedCommandNotInProfile =>
      '未授權：這個指令不屬於這份已驗證設定檔本身的指令。';

  @override
  String get powertrainRefusedLabClosed => '在這次讀取取得授權之前，大電池證據實驗室已被關閉。';

  @override
  String get powertrainRefusedProfileFailedValidation =>
      '未授權：這個設定檔沒有通過你所選車輛年份的目錄驗證。';

  @override
  String get powertrainRefusedProfileNotInCatalog => '未授權：這個設定檔不在已驗證的目錄中。';

  @override
  String get powertrainRefusedProfileNotProbeable => '未授權：這個設定檔不是可以單次實驗讀取的設定檔。';

  @override
  String get powertrainRefusedQuarantinedAfterRejectedRead =>
      '本次連線已隔離：先前一次單次讀取沒有通過結構檢查。請重新連線後再試。';

  @override
  String get powertrainRefusedNotConnectedOrNotInForeground =>
      '這次單次讀取沒有開始：目前沒有連線，或 App 不在前景。';

  @override
  String get powertrainRefusedNoLiveAuthorization =>
      '這次單次讀取沒有開始：目前沒有持有單次授權。授權不存在、已過期、冷卻中或已被隔離。';

  @override
  String get powertrainRefusedDiscardedAtLifecycleBoundary =>
      '單次讀取進行中，連線或前景狀態改變了，因此它的結果被丟棄而沒有顯示。沒有任何失敗，也沒有保留任何結果。';

  @override
  String powertrainRefusedQuarantinedAtAttemptCap(int attemptCap) {
    return '本次連線已隔離：同一個指令已經嘗試 $attemptCap 次。請重新連線後再試。';
  }

  @override
  String get powertrainResearchOnlyNeverQueries => '僅研究，不會查詢';

  @override
  String get powertrainRestoreStorageErrorRetry => '還原先前安裝時發生儲存錯誤，已重新排程，請再試一次。';

  @override
  String powertrainSecondarySource(String name, String license) {
    return '獨立佐證：$name（$license）';
  }

  @override
  String powertrainSignalCount(int count) {
    return '$count 個訊號';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return '來源檔 SHA-256：$hash…';
  }

  @override
  String get powertrainStatusCommunity => '社群資料 · 未驗證';

  @override
  String get powertrainStatusExperimental => '實驗 · 未驗證';

  @override
  String get powertrainStatusExperimentalProbeOnly => '實驗單次唯讀';

  @override
  String get powertrainStatusReady => '來源較完整';

  @override
  String get powertrainStatusResearchOnly => '僅研究';

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return '已移除 $name 的已安裝訊號。';
  }

  @override
  String powertrainVehicleYearFixed(int year) {
    return '車輛年式：$year';
  }

  @override
  String get powertrainVehicleYearLabel => '車輛年式';

  @override
  String get recommendedPurchaseDisclosure =>
      '這是維護者的推廣分潤連結；符合條件的購買可能產生佣金。不是轉接器認證或購買保證。賣場內容與硬體版本可能變更，購買前請核對完整型號與 NCC 號碼。你也可以自行搜尋其他通路。';

  @override
  String get recommendedPurchaseHeading => '推薦轉接器';

  @override
  String recommendedPurchaseModelLine(String model, String approval) {
    return '型號 $model · NCC $approval';
  }

  @override
  String recommendedPurchaseNoAdapterYet(String store) {
    return '還沒有轉接器？在$store看推薦款';
  }

  @override
  String recommendedPurchaseOpenFailed(String store) {
    return '無法開啟$store連結';
  }

  @override
  String get recommendedPurchaseShortDisclosureAction => '完整說明在設定';

  @override
  String get recommendedPurchaseShortDisclosureLead => '這是推廣分潤連結，不是轉接器認證。';

  @override
  String get recommendedPurchaseStoreShopee => '蝦皮';

  @override
  String recommendedPurchaseViewOnStore(String store) {
    return '在$store查看';
  }

  @override
  String get semanticsFieldSeparator => '，';

  @override
  String get settingsAdapterConcernsFooter =>
      '這些是轉接器對自己的描述對不起來，不是它讀錯了車。要確認數值，只能拿第二個獨立量測去對（見速查表）。';

  @override
  String get settingsAdapterNoContradictions =>
      '沒有發現自述矛盾。這只表示它對自己的描述前後一致 —— 既不代表它是原廠晶片，也不代表它回報的數值正確。版本號在仿製品上就是一段可以任意填的文字。';

  @override
  String get settingsAdapterNoVersion => '（未回報版本）';

  @override
  String get settingsAdapterSelfReportTitle => '轉接器自述';

  @override
  String get settingsBatteryLabDialogBody =>
      '這些是逆向工程來源的候選資料，不是原廠文件，也不是 Telltale 實車支援。即使是唯讀查詢也可能喚醒控制器；解碼後的數字可能看似合理但其實不適用。';

  @override
  String get settingsBatteryLabDialogTitle => '開啟大電池證據實驗室';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      '本次執行已關閉大電池實驗功能，但無法儲存設定；下次啟動可能再顯示實驗入口，每條查詢仍需重新確認。';

  @override
  String get settingsBatteryLabEnableNotSaved => '無法儲存大電池實驗功能設定，功能維持關閉。';

  @override
  String get settingsBatteryLabEvidenceAck => '我知道來源資料與合成測試不能證明我的實車適用';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      '只顯示來源完整、受雜湊約束的單次唯讀查詢。不會自動安裝 PID、輪詢、加入儀表或把研究資料當成支援。';

  @override
  String get settingsBatteryLabSwitchTitle => '大電池證據實驗室（實驗）';

  @override
  String get settingsBatteryLabUnlockReadOnly => '只解鎖單次唯讀查詢';

  @override
  String get settingsBatteryLabWireAck =>
      '我知道只會解鎖目錄內固定 Mode 21/22 的單次查詢；不會解鎖掃描、診斷 session、安全存取、寫入或控制';

  @override
  String get settingsCancel => '取消';

  @override
  String get settingsCatalogChoose => '從官方目錄選擇';

  @override
  String get settingsCatalogCorrupt => '官方離線目錄損壞或無法載入，沒有套用任何資料。';

  @override
  String get settingsCatalogNothingApplicable =>
      '這筆官方配置沒有可安全套用到目前公式的欄位，原設定保持不變。';

  @override
  String get settingsCatalogScope =>
      '官方目錄：美國 EPA、臺灣經濟部能源署、加拿大 NRCan。各快照只代表該市場，不是全球所有品牌或年式。';

  @override
  String get settingsCatalogVerifying => '驗證離線目錄中…';

  @override
  String get settingsCatalogChooseMarket => '選擇要瀏覽的官方目錄';

  @override
  String get settingsCatalogMarketTw => '臺灣（經濟部能源署）';

  @override
  String get settingsCatalogMarketUs => '美國（EPA）';

  @override
  String get settingsTwCertificationYear => '核發年份';

  @override
  String get settingsTwMake => '臺灣廠牌';

  @override
  String settingsTwPickerScope(int firstYear, int lastYear) {
    return '僅含 $firstYear–$lastYear 的臺灣核發列。這個年份是能源署核發西元年，不是美國 model year。名稱相同也不等於 EPA 配置。';
  }

  @override
  String get settingsTwPickerTitle => '臺灣官方車輛目錄';

  @override
  String get settingsTwReferenceMassNotCurb => '參考車重不是 curb mass，不會套用。';

  @override
  String settingsTwWillApplyOnly(String fields) {
    return '只會套用：$fields。參考車重、VE、Cd、正面面積、Crr 與傳動效率仍保持未解析。';
  }

  @override
  String get settingsClose => '關閉';

  @override
  String get settingsConnectionSection => '連線';

  @override
  String get settingsDiagnosticsSection => '診斷紀錄';

  @override
  String get settingsDisconnect => '中斷連線';

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return '傳動效率 $percent %';
  }

  @override
  String settingsEpaApplyFields(int count) {
    return '套用 $count 個官方欄位';
  }

  @override
  String get settingsEpaChooseExact => '選擇一個精確配置';

  @override
  String get settingsEpaCloseNoFields => '關閉（沒有可套用欄位）';

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'EPA 配置 $epaId';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count 缸';
  }

  @override
  String get settingsEpaDriveUnknown => '驅動未知';

  @override
  String get settingsEpaFuelUnknown => '燃料未知';

  @override
  String get settingsEpaMake => '廠牌（EPA make）';

  @override
  String get settingsEpaModel => '車型';

  @override
  String get settingsEpaNoConfigurations => '這個車型沒有可用配置';

  @override
  String get settingsEpaNoSafeFields => '此配置沒有能安全套用到目前公式的欄位；不會猜測。';

  @override
  String get settingsEpaPickInOrder => '依序選擇年式、品牌與車型';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return '僅限美國市場 $firstYear–$lastYear 的快照配置。選到同名車系仍要以年式、變速箱、燃料與 EPA ID 消歧。';
  }

  @override
  String get settingsEpaPickerTitle => '美國 EPA 官方車型目錄';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return '只會套用：$fields。車重、VE、Cd、正面面積、Crr 與傳動效率仍保持未解析。';
  }

  @override
  String get settingsEpaYear => '年式';

  @override
  String get settingsExperimentalSection => '實驗功能';

  @override
  String get settingsFieldDisplacement => '排氣量';

  @override
  String get settingsFieldDragCoefficient => '風阻係數 Cd';

  @override
  String get settingsFieldDrivetrain => '驅動方式';

  @override
  String get settingsFieldFrontalArea => '正面投影面積';

  @override
  String get settingsFieldFuel => '燃料';

  @override
  String get settingsFieldMass => '車重';

  @override
  String get settingsFieldMassWithDriver => '車重（含駕駛）';

  @override
  String get settingsFieldRollingResistance => '滾動阻力係數 Crr';

  @override
  String get settingsFieldVolumetricEfficiency => '容積效率 VE';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return '空燃比 $afr · 密度 $density g/L';
  }

  @override
  String get settingsFuelAndDrivetrainSection => '燃料與驅動';

  @override
  String get settingsFuelTypeLabel => '燃料種類';

  @override
  String get settingsGaugeSkinBody =>
      '不只是換顏色 —— 每一種的刻度盤形狀、指針、動態都不一樣。深色與淺色底下都可以用。';

  @override
  String get settingsGaugeSkinTitle => '儀表樣式';

  @override
  String get settingsGoToConnect => '前往連線';

  @override
  String get settingsHeadline => '設定';

  @override
  String get settingsLicenseLegalese => '大電池資料的來源、轉換方式與重用條款都隨本 App 一併附上。';

  @override
  String get settingsListSeparator => '、';

  @override
  String get settingsManualCommandBody =>
      '直接送一條指令給轉接器，例如 ATI、ATDPN、0100。會排在一般輪詢的同一條佇列上，不會插隊。';

  @override
  String get settingsManualCommandFieldLabel => '指令';

  @override
  String get settingsManualCommandNoContent => '（沒有回應內容）';

  @override
  String get settingsManualCommandSend => '送出';

  @override
  String get settingsManualCommandTitle => '手動指令';

  @override
  String get settingsNotConnected => '未連線';

  @override
  String get settingsOpenSourceLicenses => '開放原始碼與資料授權';

  @override
  String get settingsProfileConfirmAfterConnect => '連線後確認此車資料';

  @override
  String get settingsProfileConfirmButton => '確認本次連線車輛資料';

  @override
  String get settingsProfileConfirmedButton => '本次連線資料已確認';

  @override
  String get settingsProfileConfirmedDetail => '已確認本次連線的設定。修改任一項或重新連線後都要再確認。';

  @override
  String get settingsProfileEstimatesIntro =>
      '馬力、扭力與油耗都是由這些參數推算出來的，填得越接近實車，推算值才越有意義。';

  @override
  String get settingsProfileNameProvesNothing =>
      '品牌名稱或 VIN 本身都不能證明重量、風阻、VE 與傳動效率。';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      '本次連線尚未確認。仍可讀取 OBD 實測資料，但不顯示依車重、VE 與風阻推算的數值。';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      '先連上目前這台車再確認。每次重新連線都會自動失效，避免把上一台車的設定套到下一台。';

  @override
  String get settingsProvenanceNoneExact =>
      '目前沒有欄位已精確解析到這次車輛；通用值、手動值或舊來源值仍須確認。';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return '目前只有$fields有官方精確來源；其他欄位仍須逐項確認。';
  }

  @override
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  ) {
    return '來源：官方／原廠 $official / $total 欄 · 手動 $user / $total 欄 · 通用 $generic / $total 欄 · 科學模型 $scientific / $total 欄';
  }

  @override
  String settingsProvenancePublishers(String publishers) {
    return '來源：$publishers';
  }

  @override
  String settingsProvenanceResolution(
    int exact,
    int sessionConfirmed,
    int unresolved,
    int ambiguous,
    int conflict,
    int total,
  ) {
    return '解析：官方精確 $exact / $total 欄 · 本次確認 $sessionConfirmed / $total 欄 · 未解析 $unresolved / $total 欄 · 歧義 $ambiguous / $total 欄 · 衝突 $conflict / $total 欄';
  }

  @override
  String get settingsStandardsFooter =>
      '本 App 的 OBD2 實作依據 SAE J1979 與 ELM327 datasheet 等公開標準；每一條影響硬體行為的公式與 AT 指令都經過交叉驗證，結果記錄於 docs/protocol-deviations.zh-TW.md。本 App 與 Torque / Torque Pro 無關聯。';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeLight => '淺色';

  @override
  String get settingsThemeSystem => '跟隨系統';

  @override
  String get settingsVehicleProfileSection => '車輛設定檔';

  @override
  String get settingsVinConflict => 'VIN 衝突';

  @override
  String get settingsVinConflictDetail => '不同控制器回報不同 VIN，無法確認車輛身分；所有候選都已丟棄。';

  @override
  String get settingsVinNotRead => 'VIN 尚未讀取';

  @override
  String get settingsVinNotReadConnectedDetail =>
      '可向目前車輛讀取 Mode 09 VIN；身分狀態只保留在這次連線中。原始診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      '連線後可讀取目前車輛自報的 VIN；身分狀態不會帶到下一次連線。原始診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinRead => '讀取 VIN';

  @override
  String get settingsVinReading => '讀取中…';

  @override
  String get settingsVinReportedDetail =>
      'VIN 是車輛自報身分，不代表車型規格已驗證。身分狀態不跨連線；診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinSimulatorReported => '模擬器回報 VIN';

  @override
  String get settingsVinUnavailable => 'VIN 無法取得';

  @override
  String get settingsVinUnavailableDetail => '可能是車輛未提供、回覆不完整或這次連線沒有讀到；不會猜測或補字。';

  @override
  String get settingsVinVehicleReported => '車輛回報 VIN';

  @override
  String get startupCannotComplete => '目前無法完成啟動檢查';

  @override
  String get startupChecking => '正在檢查本機分享暫存與遙測紀錄';

  @override
  String get startupRestartHint =>
      '本機分享暫存或遙測紀錄的狀態無法確認。為避免覆寫、刪除或分享錯誤檔案，請完全關閉後重新開啟 Telltale。';

  @override
  String get startupRestartRequired => '需要重新啟動才能安全繼續';

  @override
  String get startupRetry => '重試';

  @override
  String get startupRetryHint =>
      '請讓 Telltale 保持在前景，並在其他檔案作業完成後重試。啟動完成前不會開放紀錄、回放、匯出或刪除。';

  @override
  String get telemetryArtifactRestartRequired =>
      '本機檔案作業狀態無法確認；請完全關閉並重新啟動 App 後再操作';

  @override
  String get telemetryBlockedByRecorder => '請先停止並儲存';

  @override
  String get telemetryCancel => '取消';

  @override
  String get telemetryDamagedCollision => '同一識別碼同時存在完成與未完成檔，未選擇任何一份';

  @override
  String get telemetryDamagedCorrupt => '紀錄損壞，無法安全讀取';

  @override
  String telemetryDamagedFileTime(String time) {
    return '檔案時間 $time';
  }

  @override
  String get telemetryDelete => '刪除';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return '將刪除 $id（檔案時間 $time）。刪除後無法復原。';
  }

  @override
  String get telemetryDeleteDamagedTitle => '刪除損壞紀錄？';

  @override
  String get telemetryDeleteDamagedTooltip => '刪除損壞紀錄';

  @override
  String telemetryDeleteFailed(String reason) {
    return '刪除未完成：$reason';
  }

  @override
  String get telemetryDeleteNeedsConfirmation => '請先確認這個刪除操作';

  @override
  String telemetryDeleteSessionBody(String time) {
    return '將刪除 $time 的紀錄。此操作無法復原。';
  }

  @override
  String get telemetryDeleteSessionTitle => '刪除本機紀錄？';

  @override
  String get telemetryDemoData => '內建模擬資料';

  @override
  String get telemetryDismissNotice => '關閉提示';

  @override
  String get telemetryEndedByBackground => 'App 進入背景後已停止';

  @override
  String get telemetryEndedByConfigurationChanged => 'PID 設定已變更';

  @override
  String get telemetryEndedByDisconnect => '連線中斷後已停止';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return '已達 $minutes 分鐘上限';
  }

  @override
  String get telemetryEndedByLibrarySizeLimit => '本機紀錄空間已滿';

  @override
  String get telemetryEndedByRecoveredAfterInterruption => '上次中斷後已復原';

  @override
  String get telemetryEndedBySessionReplacement => '連線工作階段已更換';

  @override
  String get telemetryEndedBySessionSizeLimit => '已達單筆紀錄容量上限';

  @override
  String get telemetryEndedByStorageBackpressure => '儲存速度不足';

  @override
  String get telemetryEndedByStorageFailure => '儲存失敗';

  @override
  String get telemetryEndedByUser => '已手動停止';

  @override
  String get telemetryExport => '匯出';

  @override
  String get telemetryExportCsv => '匯出 CSV';

  @override
  String telemetryExportFailed(String reason) {
    return '匯出未完成：$reason';
  }

  @override
  String get telemetryExportJson => '匯出 JSON';

  @override
  String get telemetryExportSheetTitle => '匯出本機紀錄';

  @override
  String telemetryGapCount(int count) {
    return '$count 個缺口';
  }

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    return '已儲存 $count 組，可離線回放與匯出';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit 組';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    return '另有 $count 組未顯示';
  }

  @override
  String telemetryLibraryQuotaSemantics(
    int groups,
    int groupLimit,
    String used,
    int byteLimit,
  ) {
    return '本機儲存 $groups / $groupLimit 組，$used / $byteLimit MiB';
  }

  @override
  String get telemetryNotConnected => '目前未連線';

  @override
  String get telemetryOfflineSampledReplay => '離線抽樣回放';

  @override
  String get telemetryOpenHistory => '查看本機紀錄';

  @override
  String get telemetryPause => '暫停';

  @override
  String get telemetryPendingOwnerRecovery =>
      '作業仍由目前程序持有；若持續停在此狀態，請完全關閉並重新啟動 App';

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first，$second';
  }

  @override
  String get telemetryPlay => '播放';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return '只紀錄已啟用的 OBD 訊號，不含位置、VIN 或帳號資料。趨勢圖最多顯示 $laneLimit 項，錄製會保留全部 $activeCount 項已啟用訊號，並自動加上估算馬力與估算油耗（含車輛假設）。';
  }

  @override
  String get telemetryRecorderPhaseAwaitingValues => '準備錄製';

  @override
  String get telemetryRecorderPhaseCompleted => '紀錄已儲存';

  @override
  String get telemetryRecorderPhaseFailed => '紀錄儲存失敗';

  @override
  String get telemetryRecorderPhaseFinalizing => '正在儲存紀錄';

  @override
  String get telemetryRecorderPhaseIdle => '前景本機紀錄';

  @override
  String get telemetryRecorderPhasePreparing => '正在準備錄製';

  @override
  String get telemetryRecorderPhaseRecording => '紀錄中';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return '錄製中 $duration';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    return '$count 組沒有有效值的未完成檔已清理';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    return '$count 組損壞或衝突檔未自動修改';
  }

  @override
  String get telemetryRecoveryDamagedNote => '損壞內容不會用於回放或匯出，只能在安全狀態下手動刪除。';

  @override
  String telemetryRecoveryInstalled(int count) {
    return '$count 組中斷紀錄已完成安全封存';
  }

  @override
  String get telemetryRecoveryTitle => '啟動紀錄檢查已完成';

  @override
  String get telemetryReload => '重新載入';

  @override
  String telemetryReplayBreakCount(int count) {
    return '$count 個中斷';
  }

  @override
  String get telemetryReplayLoadFailed => '無法載入紀錄';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return '回放位置 $percent%';
  }

  @override
  String telemetryReplaySampleCount(int count) {
    return '$count 個抽樣節點';
  }

  @override
  String get telemetryReplayTitle => '紀錄回放';

  @override
  String get telemetryReplayUnreadable => '紀錄損壞或無法讀取';

  @override
  String get telemetryRestartToRepairSave => '儲存作業未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryRestartToRepairStartup => '啟動清理未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryReturnToTrends => '返回趨勢';

  @override
  String get telemetryRigData => '測試馬具資料';

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first。$second';
  }

  @override
  String get telemetrySessionsDamaged => '損壞的紀錄檔';

  @override
  String get telemetrySessionsEmpty => '還沒有本機紀錄\n連線後開始錄製';

  @override
  String get telemetrySessionsLoadFailed => '無法載入，請重試';

  @override
  String get telemetrySessionsReplayable => '可回放的紀錄';

  @override
  String get telemetrySessionsTitle => '本機紀錄';

  @override
  String telemetrySignalCount(int count) {
    return '$count 項訊號';
  }

  @override
  String get telemetryStartBusy => '另一個紀錄或檔案作業尚未完成';

  @override
  String get telemetryStartCannotCreateFile => '無法建立紀錄檔';

  @override
  String get telemetryStartInvalidConfiguration => 'PID 設定無法安全紀錄，請檢查定義';

  @override
  String get telemetryStartInvalidatedBackground => 'App 已進入背景，未開始紀錄';

  @override
  String get telemetryStartInvalidatedDisconnect => '連線已中斷，未開始紀錄';

  @override
  String get telemetryStartInvalidatedSessionReplacement => '連線工作階段已更換，未開始紀錄';

  @override
  String get telemetryStartLibraryByteLimit => '本機紀錄空間不足，請先匯出或刪除';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return '本機紀錄已達 $limit 組上限，請先匯出或刪除';
  }

  @override
  String get telemetryStartMoving => '請停車後操作';

  @override
  String get telemetryStartNeedsActivePid => '請先啟用至少一項 PID';

  @override
  String get telemetryStartNeedsConnection => '請先連線再開始紀錄';

  @override
  String get telemetryStartNeedsForeground => '請回到 App 前景再開始紀錄';

  @override
  String get telemetryStartRecording => '已開始紀錄';

  @override
  String get telemetryStartRecordingButton => '開始紀錄';

  @override
  String get telemetryStartSpeedUnknown => '無法確認車輛已停止；請先中斷連線';

  @override
  String get telemetryStartTooManyPids => '錄製需保留估算馬力與估算油耗欄位，請先停用 PID';

  @override
  String get telemetryStarting => '正在開始';

  @override
  String get telemetryStatusBusError => '匯流排錯誤';

  @override
  String telemetryStatusCount(int count) {
    return '$count 個狀態';
  }

  @override
  String get telemetryStatusFormulaError => '公式錯誤';

  @override
  String get telemetryStatusHeaderMismatch => '標頭不符目前匯流排';

  @override
  String get telemetryStatusNoAnswer => '無回應，稍後重試';

  @override
  String get telemetryStatusStale => '資料已過期';

  @override
  String get telemetryStatusUnsafeServiceRefusal => '此服務不是唯讀查詢，已停止發送';

  @override
  String get telemetryStatusUnsupported => '目前引擎控制器已確認不支援';

  @override
  String get telemetryStopAndSave => '停止並儲存';

  @override
  String telemetryValueCount(int count) {
    return '$count 筆有效值';
  }

  @override
  String get transcriptDelete => '刪除';

  @override
  String get transcriptDeleteBusy => '另一個檔案作業尚未完成。';

  @override
  String get transcriptDeleteFailed => '無法刪除上一次連線的紀錄。';

  @override
  String get transcriptDeleteRefusedBySafety => '目前車速或連線狀態不允許刪除紀錄。';

  @override
  String get transcriptExport => '匯出';

  @override
  String get transcriptExportButton => '匯出紀錄';

  @override
  String get transcriptExportExplanation =>
      '這次連線會保留開頭握手與最新的原始往返資料；長時間連線若省略中段，檔案會明確標出。在車上遇到讀不到、判斷不出來的情況時，把紀錄匯出帶回來，比畫面上的一句訊息有用得多。';

  @override
  String transcriptExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String get transcriptExportWithHex => '含十六進位';

  @override
  String get transcriptNothingToExport => '沒有可匯出的紀錄。';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return '$timestamp 留下的，$size。App 被系統關掉或手機沒電時，紀錄還是留下來了。';
  }

  @override
  String get transcriptRecoveredChanged => '上一次連線的紀錄已更新，請再確認。';

  @override
  String get transcriptRecoveredTitle => '上一次連線的紀錄';

  @override
  String transcriptSizeBytes(int bytes) {
    return '$bytes 位元組';
  }

  @override
  String get trendAxisNow => '現在';

  @override
  String get trendChooseSignals => '選擇訊號';

  @override
  String get trendLiveData => '即時資料';

  @override
  String get trendNoSignalsBody => '先到 PID 頁面啟用想要監看的訊號。';

  @override
  String get trendNoSignalsTitle => '沒有可用的趨勢訊號';

  @override
  String get trendNoUnits => '無單位';

  @override
  String trendPickSignalsBody(int limit) {
    return '最多可以比較 $limit 項訊號，不會改變已啟用的 PID 輪詢。';
  }

  @override
  String get trendPickSignalsTitle => '選擇趨勢訊號';

  @override
  String trendRemoveSignal(String name) {
    return '移除 $name';
  }

  @override
  String get trendSelectionSaveFailed => '無法儲存趨勢顯示選擇';

  @override
  String trendSheetBody(int limit) {
    return '最多選擇 $limit 項。這只會改變圖表，不會改變 PID 輪詢或正在進行的紀錄。';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return '完成 · $selected/$limit';
  }

  @override
  String get trendSignalNoLongerActive => '其中一項訊號已不在 PID 監看清單';

  @override
  String get trendSignalsHeading => '趨勢訊號';

  @override
  String trendTooManySelected(int limit) {
    return '最多選擇 $limit 項';
  }

  @override
  String trendWindowSemantics(int seconds) {
    return '顯示最近 $seconds 秒趨勢';
  }

  @override
  String get wearBack => '返回';

  @override
  String get wearBatteryVoltageLabel => '電瓶';

  @override
  String get wearBleAdapters => 'BLE 轉接器';

  @override
  String get wearCancel => '取消';

  @override
  String get wearConfirmVehicle => '確認車輛';

  @override
  String get wearConfirmVehicleAccept => '就是這台車';

  @override
  String get wearConfirmVehicleBody =>
      '確認後，這個車型的唯讀電池查詢會在本次連線內定期輪詢。接錯車型可能得到看似合理但錯誤的數字——不確定就取消。';

  @override
  String wearConnectFailed(String adapter) {
    return '連線失敗：$adapter';
  }

  @override
  String get wearConnecting => '連線中…';

  @override
  String get wearDemoSimulator => 'Demo 模擬器';

  @override
  String get wearDisconnect => '中斷';

  @override
  String get wearDisconnectQuestion => '中斷連線？';

  @override
  String get wearNoDevicesFound => '沒有找到裝置';

  @override
  String get wearPermissionBluetooth => '藍牙';

  @override
  String get wearPermissionLocation => '位置';

  @override
  String get wearScanAgain => '重新掃描';

  @override
  String get wearScanFailed => '掃描失敗，請再試一次';

  @override
  String wearScanPermissionNeeded(String permission) {
    return '需要$permission權限才能掃描';
  }

  @override
  String wearScanPermissionPermanentlyDenied(String permission) {
    return '$permission權限已被永久拒絕，請到系統設定開啟後再試';
  }

  @override
  String get wearScanning => '掃描中…';

  @override
  String get telemetryRecorderNotRecording => '未錄製';

  @override
  String get dtcKindStored => '已儲存';

  @override
  String get dtcKindPending => '待確認';

  @override
  String get dtcKindPermanent => '永久';

  @override
  String get dtcKindStoredExplanation => '已確認的故障，儀表板故障燈通常亮起';

  @override
  String get dtcKindPendingExplanation => '偵測到一次，尚未達到確認門檻';

  @override
  String get dtcKindPermanentExplanation => '無法用診斷儀清除，需修復後由 ECU 自行確認';

  @override
  String get dtcSystemPowertrain => '動力系統';

  @override
  String get dtcSystemChassis => '底盤';

  @override
  String get dtcSystemBody => '車身';

  @override
  String get dtcSystemNetwork => '網路';

  @override
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions =>
      '燃油與空氣計量、輔助排放控制';

  @override
  String get dtcSubsystemFuelAirMetering => '燃油與空氣計量';

  @override
  String get dtcSubsystemFuelAirMeteringInjectorCircuit => '燃油與空氣計量（噴油嘴迴路）';

  @override
  String get dtcSubsystemIgnitionOrMisfire => '點火系統或失火';

  @override
  String get dtcSubsystemAuxiliaryEmissionControls => '輔助排放控制';

  @override
  String get dtcSubsystemSpeedAndIdleControl => '車速控制與怠速系統';

  @override
  String get dtcSubsystemComputerOutputCircuit => '電腦輸出迴路';

  @override
  String get dtcSubsystemTransmission => '變速箱';

  @override
  String get dtcSubsystemControlModuleSignals => '控制模組輸入／輸出訊號';

  @override
  String get dtcDescriptionB0001 => '駕駛座安全氣囊裝置故障';

  @override
  String get dtcDescriptionP0011 => '「A」凸輪軸正時過前或系統效能異常（Bank 1）';

  @override
  String get dtcDescriptionP0014 => '「B」凸輪軸正時過前或系統效能異常（Bank 1）';

  @override
  String get dtcDescriptionP0016 => '曲軸與凸輪軸位置訊號不同步（Bank 1 感知器 A）';

  @override
  String get dtcDescriptionP0087 => '燃油軌／系統壓力過低';

  @override
  String get dtcDescriptionP0088 => '燃油軌／系統壓力過高';

  @override
  String get dtcDescriptionP0100 => '空氣流量感知器 (MAF) 電路故障';

  @override
  String get dtcDescriptionP0101 => '空氣流量感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0102 => '空氣流量感知器電路輸入過低';

  @override
  String get dtcDescriptionP0103 => '空氣流量感知器電路輸入過高';

  @override
  String get dtcDescriptionP0105 => '進氣歧管絕對壓力／大氣壓力感知器電路故障';

  @override
  String get dtcDescriptionP0106 => '進氣歧管絕對壓力感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0107 => '進氣歧管絕對壓力感知器電路輸入過低';

  @override
  String get dtcDescriptionP0108 => '進氣歧管絕對壓力感知器電路輸入過高';

  @override
  String get dtcDescriptionP0110 => '進氣溫度感知器電路故障';

  @override
  String get dtcDescriptionP0111 => '進氣溫度感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0112 => '進氣溫度感知器電路輸入過低';

  @override
  String get dtcDescriptionP0113 => '進氣溫度感知器電路輸入過高';

  @override
  String get dtcDescriptionP0115 => '冷卻液溫度感知器電路故障';

  @override
  String get dtcDescriptionP0116 => '冷卻液溫度感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0117 => '冷卻液溫度感知器電路輸入過低';

  @override
  String get dtcDescriptionP0118 => '冷卻液溫度感知器電路輸入過高';

  @override
  String get dtcDescriptionP0120 => '節氣門位置感知器電路故障';

  @override
  String get dtcDescriptionP0121 => '節氣門位置感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0122 => '節氣門位置感知器電路輸入過低';

  @override
  String get dtcDescriptionP0123 => '節氣門位置感知器電路輸入過高';

  @override
  String get dtcDescriptionP0125 => '冷卻液溫度不足以進入閉迴路燃油控制';

  @override
  String get dtcDescriptionP0128 => '冷卻液溫度低於節溫器調節溫度';

  @override
  String get dtcDescriptionP0130 => '含氧感知器電路故障 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0131 => '含氧感知器電路電壓過低 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0132 => '含氧感知器電路電壓過高 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0133 => '含氧感知器反應過慢 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0134 => '含氧感知器無活性訊號 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0135 => '含氧感知器加熱器電路故障 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0136 => '含氧感知器電路故障 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0137 => '含氧感知器電路電壓過低 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0138 => '含氧感知器電路電壓過高 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0140 => '含氧感知器無活性訊號 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0141 => '含氧感知器加熱器電路故障 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0150 => '含氧感知器電路故障 (Bank 2 Sensor 1)';

  @override
  String get dtcDescriptionP0155 => '含氧感知器加熱器電路故障 (Bank 2 Sensor 1)';

  @override
  String get dtcDescriptionP0156 => '含氧感知器電路故障 (Bank 2 Sensor 2)';

  @override
  String get dtcDescriptionP0161 => '含氧感知器加熱器電路故障 (Bank 2 Sensor 2)';

  @override
  String get dtcDescriptionP0170 => '燃油修正異常 (Bank 1)';

  @override
  String get dtcDescriptionP0171 => '混合比過稀 (Bank 1)';

  @override
  String get dtcDescriptionP0172 => '混合比過濃 (Bank 1)';

  @override
  String get dtcDescriptionP0173 => '燃油修正異常 (Bank 2)';

  @override
  String get dtcDescriptionP0174 => '混合比過稀 (Bank 2)';

  @override
  String get dtcDescriptionP0175 => '混合比過濃 (Bank 2)';

  @override
  String get dtcDescriptionP0190 => '燃油軌壓力感知器電路故障';

  @override
  String get dtcDescriptionP0201 => '噴油嘴電路故障／開路 — 第 1 缸';

  @override
  String get dtcDescriptionP0202 => '噴油嘴電路故障／開路 — 第 2 缸';

  @override
  String get dtcDescriptionP0203 => '噴油嘴電路故障／開路 — 第 3 缸';

  @override
  String get dtcDescriptionP0204 => '噴油嘴電路故障／開路 — 第 4 缸';

  @override
  String get dtcDescriptionP0217 => '引擎過熱';

  @override
  String get dtcDescriptionP0221 => '節氣門／油門踏板位置感知器 B 範圍或效能異常';

  @override
  String get dtcDescriptionP0222 => '節氣門／油門踏板位置感知器 B 電路輸入過低';

  @override
  String get dtcDescriptionP0223 => '節氣門／油門踏板位置感知器 B 電路輸入過高';

  @override
  String get dtcDescriptionP0234 => '渦輪／機械增壓過壓';

  @override
  String get dtcDescriptionP0299 => '渦輪／機械增壓「A」增壓不足';

  @override
  String get dtcDescriptionP0300 => '偵測到隨機/多缸失火';

  @override
  String get dtcDescriptionP0301 => '第 1 缸失火';

  @override
  String get dtcDescriptionP0302 => '第 2 缸失火';

  @override
  String get dtcDescriptionP0303 => '第 3 缸失火';

  @override
  String get dtcDescriptionP0304 => '第 4 缸失火';

  @override
  String get dtcDescriptionP0305 => '第 5 缸失火';

  @override
  String get dtcDescriptionP0306 => '第 6 缸失火';

  @override
  String get dtcDescriptionP0307 => '第 7 缸失火';

  @override
  String get dtcDescriptionP0308 => '第 8 缸失火';

  @override
  String get dtcDescriptionP0316 => '起動後隨即偵測到失火';

  @override
  String get dtcDescriptionP0325 => '爆震感知器電路故障 (Bank 1)';

  @override
  String get dtcDescriptionP0326 => '爆震感知器範圍/效能異常 (Bank 1)';

  @override
  String get dtcDescriptionP0327 => '爆震感知器電路輸入過低 (Bank 1)';

  @override
  String get dtcDescriptionP0328 => '爆震感知器電路輸入過高 (Bank 1)';

  @override
  String get dtcDescriptionP0330 => '爆震感知器電路故障 (Bank 2)';

  @override
  String get dtcDescriptionP0335 => '曲軸位置感知器電路故障';

  @override
  String get dtcDescriptionP0336 => '曲軸位置感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0340 => '凸輪軸位置感知器電路故障';

  @override
  String get dtcDescriptionP0341 => '凸輪軸位置感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0351 => '點火線圈 A 一次/二次電路故障';

  @override
  String get dtcDescriptionP0352 => '點火線圈 B 一次/二次電路故障';

  @override
  String get dtcDescriptionP0353 => '點火線圈 C 一次/二次電路故障';

  @override
  String get dtcDescriptionP0354 => '點火線圈 D 一次/二次電路故障';

  @override
  String get dtcDescriptionP0355 => '點火線圈 E 一次/二次電路故障';

  @override
  String get dtcDescriptionP0356 => '點火線圈 F 一次/二次電路故障';

  @override
  String get dtcDescriptionP0400 => '廢氣再循環 (EGR) 流量故障';

  @override
  String get dtcDescriptionP0401 => '廢氣再循環 (EGR) 流量不足';

  @override
  String get dtcDescriptionP0402 => '廢氣再循環 (EGR) 流量過大';

  @override
  String get dtcDescriptionP0403 => '廢氣再循環 (EGR) 控制電路故障';

  @override
  String get dtcDescriptionP0404 => '廢氣再循環 (EGR) 控制電路範圍/效能異常';

  @override
  String get dtcDescriptionP0410 => '二次空氣噴射系統故障';

  @override
  String get dtcDescriptionP0411 => '二次空氣噴射系統流量不正確';

  @override
  String get dtcDescriptionP0412 => '二次空氣噴射切換閥 A 電路故障';

  @override
  String get dtcDescriptionP0420 => '觸媒轉換器效率低於門檻 (Bank 1)';

  @override
  String get dtcDescriptionP0430 => '觸媒轉換器效率低於門檻 (Bank 2)';

  @override
  String get dtcDescriptionP0440 => '蒸發排放控制系統故障';

  @override
  String get dtcDescriptionP0441 => '蒸發排放系統清除流量不正確';

  @override
  String get dtcDescriptionP0442 => '蒸發排放系統偵測到小漏氣';

  @override
  String get dtcDescriptionP0443 => '蒸發排放清除閥控制電路故障';

  @override
  String get dtcDescriptionP0446 => '蒸發排放通風控制電路故障';

  @override
  String get dtcDescriptionP0447 => '蒸發排放通風控制電路開路';

  @override
  String get dtcDescriptionP0449 => '蒸發排放通風閥/電磁閥電路故障';

  @override
  String get dtcDescriptionP0451 => '蒸發排放壓力感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0452 => '蒸發排放壓力感知器電路輸入過低';

  @override
  String get dtcDescriptionP0453 => '蒸發排放壓力感知器電路輸入過高';

  @override
  String get dtcDescriptionP0455 => '蒸發排放系統偵測到大漏氣';

  @override
  String get dtcDescriptionP0456 => '蒸發排放系統偵測到極小漏氣';

  @override
  String get dtcDescriptionP0480 => '冷卻風扇 1 控制電路故障';

  @override
  String get dtcDescriptionP0500 => '車速感知器故障';

  @override
  String get dtcDescriptionP0505 => '怠速控制系統故障';

  @override
  String get dtcDescriptionP0506 => '怠速轉速低於預期';

  @override
  String get dtcDescriptionP0507 => '怠速轉速高於預期';

  @override
  String get dtcDescriptionP0508 => '怠速控制電路輸入過低';

  @override
  String get dtcDescriptionP0509 => '怠速控制電路輸入過高';

  @override
  String get dtcDescriptionP0560 => '系統電壓故障';

  @override
  String get dtcDescriptionP0562 => '系統電壓過低';

  @override
  String get dtcDescriptionP0563 => '系統電壓過高';

  @override
  String get dtcDescriptionP0603 => '控制模組內部記憶體（KAM）錯誤';

  @override
  String get dtcDescriptionP0605 => '控制模組內部唯讀記憶體（ROM）錯誤';

  @override
  String get dtcDescriptionP0606 => 'ECM/PCM 處理器故障';

  @override
  String get dtcDescriptionP0700 => '變速箱控制模組要求點亮故障燈 —— 故障碼在變速箱模組裡，請另外讀取';

  @override
  String get dtcDescriptionP0701 => '變速箱控制系統範圍/效能異常';

  @override
  String get dtcDescriptionP0702 => '變速箱控制系統電氣故障';

  @override
  String get dtcDescriptionP0705 => '排檔位置感知器電路故障';

  @override
  String get dtcDescriptionP0715 => '輸入軸／渦輪轉速感知器電路故障';

  @override
  String get dtcDescriptionP0720 => '輸出軸轉速感知器電路故障';

  @override
  String get dtcDescriptionP0730 => '檔位比不正確';

  @override
  String get dtcDescriptionP0740 => '扭力轉換器離合器電路故障';

  @override
  String get dtcDescriptionP0741 => '扭力轉換器離合器卡在未鎖定狀態';

  @override
  String get dtcDescriptionP0750 => '換檔電磁閥 A 故障';

  @override
  String get dtcDescriptionP0755 => '換檔電磁閥 B 故障';

  @override
  String get dtcDescriptionP2135 => '節氣門位置感知器 A/B 電壓不一致';

  @override
  String get dtcDescriptionU0100 => '與 ECM/PCM 失去通訊';

  @override
  String get dtcDescriptionU0101 => '與變速箱控制模組失去通訊';

  @override
  String get dtcDescriptionU0121 => '與 ABS 控制模組失去通訊';

  @override
  String get dtcDescriptionU0140 => '與車身控制模組失去通訊';

  @override
  String get dtcDescriptionU0155 => '與儀表板控制模組失去通訊';

  @override
  String get gaugeSkinCluster => '儀表艙';

  @override
  String get gaugeSkinClusterDescription => '車廠儀表板的樣子。指針、270 度刻度盤、凹陷的面盤。';

  @override
  String get gaugeSkinMinimal => '極簡';

  @override
  String get gaugeSkinMinimalDescription => '半圓弧、沒有指針、沒有刻度。要看的是數字，不是動作。';

  @override
  String get gaugeSkinTrack => '賽道';

  @override
  String get gaugeSkinTrackDescription => '分段燈條、無平滑動畫。數值到哪就是哪，不做過渡。';

  @override
  String get gaugeSkinClassic => '經典';

  @override
  String get gaugeSkinClassicDescription => '印刷式面盤、整圈數字、指針像機械錶一樣慢慢定位。';

  @override
  String get gaugeSkinNight => '夜視';

  @override
  String get gaugeSkinNightDescription => '夜間駕駛用。低亮度、淺弧、不做動畫，盡量不搶走注意力。';

  @override
  String get derivedAirflowSourceMaf => 'MAF 感測器';

  @override
  String get derivedAirflowSourceSpeedDensity => 'Speed-Density 推算';

  @override
  String get derivedAirflowSourceUnavailable => '進氣量無法取得';

  @override
  String get derivedFuelSourceStoichiometric => '化學計量比推算';

  @override
  String get derivedFuelSourceUnavailable => '油耗無法取得';

  @override
  String get telemetrySourceDemo => '內建模擬';

  @override
  String get telemetrySourceRig => '測試馬具';

  @override
  String get telemetrySourceFieldApp => '一般 field App 連線';

  @override
  String get fuelTypeGasoline => '汽油';

  @override
  String get fuelTypeDiesel => '柴油';

  @override
  String get fuelTypeLpg => '液化石油氣 (LPG)';

  @override
  String get fuelTypeEthanolE85 => 'E85 酒精汽油';

  @override
  String get drivetrainFwd => '前輪驅動';

  @override
  String get drivetrainRwd => '後輪驅動';

  @override
  String get drivetrainAwd => '四輪驅動';

  @override
  String get assumptionFieldMass => '車重';

  @override
  String get assumptionFieldDragCoefficient => 'Cd';

  @override
  String get assumptionFieldFrontalArea => '迎風面積';

  @override
  String get assumptionFieldRollingResistance => '滾動阻力';

  @override
  String get assumptionFieldDrivetrainEfficiency => '傳動效率';

  @override
  String get assumptionFieldFuelType => '燃料';

  @override
  String get assumptionFieldStoichAfr => 'AFR';

  @override
  String get assumptionFieldFuelDensity => '密度';

  @override
  String get assumptionFieldDisplacement => '排氣量';

  @override
  String get assumptionFieldVolumetricEfficiency => 'VE';

  @override
  String get vehicleFieldOriginGenericDefault => '通用預設';

  @override
  String get vehicleFieldOriginUserEntered => '手動輸入';

  @override
  String get vehicleFieldOriginOfficialRegistry => '官方型錄';

  @override
  String get vehicleFieldOriginManufacturerPublication => '原廠資料';

  @override
  String get vehicleFieldOriginScientificModel => '模型係數';

  @override
  String assumptionWithOrigin(String field, String value, String origin) {
    return '$field $value（$origin）';
  }

  @override
  String assumptionWithoutOrigin(String field, String value) {
    return '$field $value';
  }

  @override
  String get assumptionSeparator => '；';

  @override
  String get datumFormulaHorsepower =>
      'wheelWatts = (m·a + ½ρ·Cd·A·v² + Crr·m·g)·v; engineHp = wheelHp / drivetrainEfficiency';

  @override
  String get datumFormulaFuelRate =>
      'L/h = (MAF g/s) / (AFR × fuel density g/L) × 3600; MAF 可為 PID 0110 或 speed-density（RPM×MAP×排氣量×VE / T_K）; L/100km = (L/h) / speed_kmh × 100';

  @override
  String get datumAssumptionsFromRecording => '估算使用記錄當下的車輛設定';

  @override
  String adapterConcernFirmwareNeverReleasedSummary(String version) {
    return '回報的韌體版本 v$version 官方從未發行';
  }

  @override
  String get adapterConcernFirmwareNeverReleasedDetail =>
      'ELM327 的原廠 Elm Electronics 沒有出過這個版本 —— 這台轉接器上的韌體不是它自稱的那一份。很多這種轉接器仍然可用，但它對自己的描述已經不可靠，遇到讀不到的狀況時值得先懷疑它。';

  @override
  String adapterConcernPpsRefusedSummary(String version) {
    return '自稱 v$version，卻不認得 v1.1 就有的 ATPPS 指令';
  }

  @override
  String get adapterConcernPpsRefusedDetail =>
      '可程式參數摘要（ATPPS）從 ELM327 v1.1 起就存在，連 OBDLink 這類高階轉接器也支援。自稱的版本與實際實作的指令對不起來。';

  @override
  String get adapterConcernNoIdentitySummary => '不回應 AT@1（第一版就有的裝置識別指令）';

  @override
  String get adapterConcernNoIdentityDetail =>
      '這條指令從 ELM327 v1.0 就存在。不回應代表這顆晶片的指令集比任何一版官方韌體都少。';

  @override
  String get telemetryReplaySampled => '預覽已抽樣；匯出保留完整已記錄事件';

  @override
  String get telemetryExportDisclosure =>
      '匯出內容包含訊號名稱、數值、觀測與來源時間、傳輸類型、通訊協定、凍結的 PID 標籤／單位／公式，以及估算假設（車重、空氣阻力、排氣量、燃料等參數）。JSON 可能包含使用者自訂標籤、單位、公式與完整凍結定義。匯出內容不含 VIN、GPS、帳號、轉接器位址、完整車輛設定檔或原始診斷流量。';

  @override
  String get connectTransportCancelled => '連線嘗試在完成前被停止了。';

  @override
  String get connectTransportWifiRouteNoNetwork =>
      '手機沒有連上任何 Wi-Fi 網路，沒有通往轉接器的路由。請先連上轉接器的 Wi-Fi 熱點再試一次。';

  @override
  String get connectTransportWifiRouteAmbiguous =>
      '手機同時連著多個 Wi-Fi，無法判斷哪一個通往轉接器，所以沒有選任何一個。請先關閉不是轉接器的那些連線再試一次。';

  @override
  String get connectTransportWifiRouteRefused =>
      '系統拒絕讓這個連線走 Wi-Fi。手機是連著 Wi-Fi 的，只是不被允許用於這個連線。';

  @override
  String get connectTransportWifiRouteTimeout =>
      '系統沒有回應「讓這個連線走 Wi-Fi」的請求。請等幾秒再試一次。';

  @override
  String get connectTransportWifiRouteUnclassified =>
      '這個連線無法走 Wi-Fi，而系統沒有說明原因。完整的錯誤留在下方的紀錄裡。';

  @override
  String get connectTransportWifiHostUnreachable =>
      '那個位址沒有回應。請確認手機已連上轉接器的 Wi-Fi 熱點 —— 若系統問過「無法連上網際網路，是否繼續使用」，要選繼續使用。關閉行動數據也可能有幫助。';

  @override
  String get connectTransportWifiConnectTimeout => '那個位址在時限內沒有任何回應。';

  @override
  String get connectTransportWifiRouteRestoreFailed =>
      '連線本身成功了，但手機的網路路由無法恢復，所以連線被中斷，而不是把它改過的狀態留著。請重新開啟 App 再試一次。';

  @override
  String get connectTransportBleLinkFailed => '無法連線到轉接器。請確認它已通電且在範圍內。';

  @override
  String get connectTransportBleNoSerialCharacteristic =>
      '裝置連上了，但在它身上沒有找到序列埠，可能不是 ELM327 轉接器。';

  @override
  String get connectTransportClassicAllTiersRefused =>
      '無法連線到轉接器。請先在系統藍牙設定完成配對，並確認它已插上 OBD 埠且電門已開啟。';

  @override
  String get connectTransportClassicConnectTimeout =>
      '連線到轉接器逾時。它可能仍在回應中 —— 請等幾秒再試，不要立刻重試。';

  @override
  String get connectTransportSerialPortOpenFailed =>
      '無法開啟序列埠。請確認系統已為這個轉接器建立序列埠（Windows COMx / Linux /dev/rfcomm*），且電門已開啟。';

  @override
  String get connectTransportSerialDroppedOnOpen => '序列埠開啟後立刻又關閉了。';

  @override
  String get settingsManualCommandNotConnected => '目前沒有連線，這條指令沒有送出。';

  @override
  String get settingsManualCommandLinkDropped =>
      '這條指令還在等待回應時，與轉接器的連線中斷了，所以沒有任何回應。轉接器是否收到這條指令並不確定。';

  @override
  String get settingsManualCommandDisconnectedByApp =>
      '這條指令還在等待回應時，App 主動關閉了連線，所以沒有任何回應。轉接器與車輛都沒有問題。';

  @override
  String get settingsManualCommandAdapterSilentOnResync =>
      '轉接器的回應已經和送出的指令對不上，而它也沒有回應用來重新對齊的檢查，所以連線已中斷。請重新連線後再試一次。';

  @override
  String get settingsManualCommandLinkStoppedResponding =>
      '轉接器安靜得夠久，連線已被中斷。它可能仍有電；能確定的只有這段沉默。';

  @override
  String get settingsManualCommandWriteFailed =>
      '這條指令無法交給轉接器的連線。有多少內容送達轉接器並不確定。';

  @override
  String get settingsManualCommandTimedOut => '在時限內沒有收到回應。請確認轉接器已連線，且車輛電門已開啟。';

  @override
  String get settingsManualCommandOperationRetired => '這個工作階段已經結束或退到背景，指令沒有送出。';

  @override
  String get settingsManualCommandRequestUnaddressable =>
      '這條要求在這輛車使用的匯流排上無法定址，因此沒有送出。再試一次也不會改變。';

  @override
  String get commandFailureBusJ1939 =>
      '這條匯流排是 SAE J1939（重型商用車與機械），不是本 App 讀取的 OBD2 診斷協定，因此無法讀取這次查詢。';

  @override
  String commandFailureUserCanFramingUnknown(
    String protocol,
    String parameter,
  ) {
    return '轉接器設成自訂 CAN 協定 $protocol，其框架由 $parameter 決定。轉接器沒有回報該設定，因此無法確認匯流排格式，也不能安全解碼這次查詢。';
  }

  @override
  String get commandFailureBusUndetermined => '車輛匯流排協定尚未確定，因此無法安全解碼這次查詢。請重新連線。';

  @override
  String get settingsManualCommandCustomFlowControlRejected =>
      '轉接器拒絕了自訂 Flow Control 指令，因此未套用所要求的模式，也沒有產生任何量測值。';

  @override
  String get settingsManualCommandFlowControlRestoreFailed =>
      '轉接器拒絕還原預設 Flow Control（ATFCSM0），因此已停止輪詢，請重新連線後再試。';

  @override
  String get settingsManualCommandExtendedAddressingUnavailable =>
      '此 ELM327 路徑不提供延伸定址。';

  @override
  String get settingsManualCommandRawIsoTpModeUnavailable =>
      '此 ELM327 路徑不提供主機可見的 ISO-TP 重組。';

  @override
  String get settingsManualCommandCanPriorityUnavailable =>
      '此 ELM327 路徑不提供 CAN 優先權程式設計。';

  @override
  String get settingsManualCommandCanReceiveFilterUnavailable =>
      '此 ELM327 路徑不提供 CAN 接收過濾。';

  @override
  String get settingsManualCommandHeaderRestoreFailed =>
      '轉接器拒絕還原標頭（ATSH），無法歸屬回應，重連前拒絕後續指令。';

  @override
  String get manualCommandRefusedEmpty => '沒有輸入指令。';

  @override
  String get manualCommandRefusedMoreThanOneCommand =>
      '指令裡有換行或控制字元，這樣會一次送出多個指令。轉接器以換行分隔指令，所以第二個指令不會經過這裡的任何檢查 —— 包括禁止清除故障碼的那一項。請一次只輸入一個指令。';

  @override
  String manualCommandRefusedAdapterStateWouldChange(
    Object command,
    Object allowed,
  ) {
    return '手動指令只接受查詢，不接受會改變轉接器設定的指令。「$command」會改動轉接器狀態，而 App 對轉接器的認知不會跟著更新 —— 接下來的讀數可能來自另一個控制器，而畫面上看不出來。\n可用的查詢：$allowed。';
  }

  @override
  String get manualCommandRefusedClearHasItsOwnButton =>
      '清除故障碼請用故障碼畫面的「清除」按鈕。從這裡送出會跳過確認、覆蓋率檢查與回應驗證，而且只會清到目前選中的那一個控制器。';

  @override
  String manualCommandRefusedCharactersNoObdCommandHas(Object command) {
    return '指令「$command」含有 OBD 指令不會出現的字元。這裡只接受十六進位的服務碼與參數（例如 0100、03、2211A6），或 AT 開頭的轉接器查詢。';
  }

  @override
  String manualCommandRefusedNotAReadOnlyQuery(Object command, Object allowed) {
    return '不認得的指令「$command」。這裡只接受唯讀查詢（Mode $allowed）與轉接器查詢指令。';
  }

  @override
  String commandFailureQueryHeaderRefused(Object header) {
    return '轉接器拒絕將這條要求對準到控制器 $header，因此它沒有送出。如果留在轉接器實際持有的位址上，回應會來自沒有人詢問的控制器。';
  }

  @override
  String commandFailureWholeVehicleHeaderRefused(Object address) {
    return '轉接器拒絕切換到 $address 這個位址，而向全車提出的問題必須從它送出。沒有它，回應就無法對應到送出它們的控制器，因此這個要求沒有送出。';
  }

  @override
  String commandFailureLegacyScanWouldBePartial(Object installed) {
    return '這輛車使用的舊式匯流排沒有能觸及每個控制器的標準位址，而轉接器目前指定在控制器 $installed。掃描只會涵蓋那一個控制器，卻會被當成全車結果呈現，因此沒有送出。請重新連線後再掃描一次。';
  }

  @override
  String get pidFormulaEmpty => '公式是空的。';

  @override
  String get pidFormulaEmptySubExpression => '公式有一段是空的 —— 運算子後面沒有東西，或括號裡沒有內容。';

  @override
  String get pidFormulaUnbalancedParentheses => '括號沒有配對：每一個 ( 都需要一個對應的 )。';

  @override
  String pidFormulaUnparsableTerm(String term) {
    return '「$term」不是數值、運算子，也不是這個編輯器認得的名稱。';
  }

  @override
  String get pidFormulaFunctionNestingTooDeep =>
      'ABS()、LOG10()、LOG() 與 SQRT() 巢狀太深，無法求值。請簡化公式。';

  @override
  String get pidFormulaParenthesisNestingTooDeep => '括號巢狀太深，無法求值。請簡化公式。';

  @override
  String get pidFormulaDivisionByZero => '公式除以零。';

  @override
  String get pidFormulaModuloByZero => '公式對零取餘數。';

  @override
  String pidFormulaLog10NonPositiveArgument(double argument) {
    return 'LOG10 的引數必須大於 0，這裡算出來的是 $argument。';
  }

  @override
  String pidFormulaLogNonPositiveArgument(double argument) {
    return 'LOG 的引數必須大於 0，這裡算出來的是 $argument。';
  }

  @override
  String pidFormulaSqrtNegativeArgument(double argument) {
    return 'SQRT 的引數必須大於或等於 0，這裡算出來的是 $argument。';
  }

  @override
  String get pidFormulaResultNotFinite => '這串運算沒有得出可用的數值，因此沒有讀數可顯示。';

  @override
  String pidFormulaByteBeyondResponse(String letter, int count) {
    return '公式參照位元組 $letter，但回應只有 $count 個位元組。';
  }

  @override
  String get pidFormulaBaroControllerUnknown =>
      '這裡無法使用 BARO，因為無法判斷指的是哪一個控制器的大氣壓力。';

  @override
  String get pidFormulaBaroTwoDefinitions =>
      '有兩個定義同時提供大氣壓力，數值可能是其中任何一個，因此無法採用。請移除其中一個測量大氣壓力的錶。';

  @override
  String get pidFormulaBaroNotYetMeasured => '尚未取得大氣壓力量測值，無法計算。';

  @override
  String get pidFormulaBaroMeasurementStale => '大氣壓力量測值已過期，無法計算。';

  @override
  String get pidFormulaBaroParenFormUnsupported =>
      'BARO() 是 Android 氣壓計／ECU 大氣壓（psi），這個方言沒有實作。要用快取的大氣壓力請寫不帶括號的 BARO。';

  @override
  String get pidFormulaInt16Unclaimed =>
      'INT16 尚未被這個方言認領：wiki 寫可代替 (A*255)+B，那不是 (A*256)+B。請把其中一個等式直接寫進公式。';

  @override
  String pidFormulaTimeWindowUnsupported(String term) {
    return '$term 是這個方言尚未實作的延遲、平均或 totalizer Torque 函式，因此無法在這裡求值。它不是 0，也不是 MIN 或 MAX。';
  }

  @override
  String pidFormulaDependencyControllerUnknown(String reference) {
    return '這裡無法解析 $reference，因為無法判斷那個 PID 屬於哪一個控制器。';
  }

  @override
  String pidFormulaDependencyTwoDefinitions(String key) {
    return '有兩個定義同時解讀 $key，數值可能是其中任何一個，因此無法採用。請讓其中一個改用不同的模式+PID。注意：推算數值需要的 PID（010B、010C、010D）本 App 一定會讀取，把面板上的錶移掉不會停止讀取它們。';
  }

  @override
  String pidFormulaDependencyNotYetMeasured(String key) {
    return '尚未取得相依 PID $key 的有效數值。';
  }

  @override
  String get pidFormulaUnidentified => '這個公式無法求值，而編輯器沒有更具體的原因可顯示。';

  @override
  String get pidRejectionMalformedModeAndPid =>
      '不是有效的模式+PID（只接受十六進位字元，且位元組須成對）。';

  @override
  String pidRejectionServiceNotReadOnly(String service, String services) {
    return '服務 $service 不是唯讀查詢，不能週期性發送到車上。只允許 $services（現值、凍結幀、車輛資訊、ReadDataByIdentifier）。';
  }

  @override
  String get pidRejectionFreezeFrameNeedsFrame =>
      '凍結幀查詢需要 PID 與幀編號兩個位元組，例如 020500（PID 05、第 0 幀）。';

  @override
  String get pidRejectionIdentifierNeedsTwoBytes =>
      'ReadDataByIdentifier 需要兩個位元組的識別碼，例如 221101。';

  @override
  String pidRejectionIdentifierWrongLength(String service, int bytes) {
    return '服務 $service 的查詢需要 $bytes 個位元組的識別碼。';
  }

  @override
  String get pidRejectionNameRequired => '請輸入名稱。';

  @override
  String pidRejectionInvalidHeader(String text) {
    return '「$text」不是有效的標頭（11-bit CAN 為 3 碼、舊協定為 6 碼、29-bit CAN 為 8 碼）。';
  }

  @override
  String get pidRejectionBoundsRequired => '請填寫量程的上下限。';

  @override
  String pidRejectionMinNotANumber(String text) {
    return '量程下限「$text」不是有效的數值。';
  }

  @override
  String pidRejectionMaxNotANumber(String text) {
    return '量程上限「$text」不是有效的數值。';
  }

  @override
  String get pidRejectionMinNotFinite => '量程下限必須是有限的數值。';

  @override
  String get pidRejectionMaxNotFinite => '量程上限必須是有限的數值。';

  @override
  String pidRejectionRedlineNotANumber(String text) {
    return '紅線起點「$text」不是有效的數值。';
  }

  @override
  String get pidRejectionRedlineNotFinite => '紅線起點必須是有限的數值。';

  @override
  String get pidRejectionMaxNotAboveMin => '量程上限必須大於下限。';

  @override
  String pidImportMalformedCsv(String detail) {
    return '這個檔案無法以 CSV 讀取：$detail';
  }

  @override
  String get pidImportNoRows => '檔案沒有任何資料列。';

  @override
  String pidImportDuplicateHeaderColumns(String columns) {
    return '標題列有重複的欄位名稱：$columns。無法判斷該用哪一欄，請先修正檔案。';
  }

  @override
  String pidImportMissingRequiredColumns(String columns, String required) {
    return '標題列缺少必要欄位：$columns。$required 都是必要的。';
  }

  @override
  String pidImportRowTooFewColumns(int line) {
    return '第 $line 行：欄位不足，至少需要名稱、簡稱、PID、公式。';
  }

  @override
  String pidImportRowInvalidModeAndPid(int line, String text) {
    return '第 $line 行：「$text」不是有效的模式+PID（只接受十六進位字元，且位元組須成對）。';
  }

  @override
  String pidImportRowEmptyEquation(int line) {
    return '第 $line 行：公式為空。';
  }

  @override
  String pidImportRowRejected(int line, String reason) {
    return '第 $line 行：$reason';
  }

  @override
  String pidImportRowRangeDefaulted(int line, double min, double max) {
    return '第 $line 行：量程留空，已套用預設 $min–$max。請確認這個刻度適合這個感測器。';
  }

  @override
  String get pidImportNothingImportable => '檔案裡有資料列，但沒有任何一列是 PID 定義。';

  @override
  String get dtcCategoryNoAnswer => '這個類別沒有回應。請重新掃描。';

  @override
  String get dtcCategoryError => '這個類別讀取失敗。完整錯誤保留在紀錄裡。';

  @override
  String get dtcCategoryDisconnected => '讀取這個類別時連線中斷。';

  @override
  String get dtcCategoryPending => '控制器已收到請求、仍在處理中。請稍候再掃描一次——這不是拒絕。';

  @override
  String get dtcCategoryUnattributed =>
      '有讀到故障碼，但回應標頭是關閉的，因此不知道是哪些控制器回答。這是部分結果，不是車輛正常。';

  @override
  String dtcCategorySilentControllers(int count, String controllers) {
    return '有 $count 個控制器沒有回應這次查詢（$controllers）。已回應的部分仍然有效，但不能當作全車結果。';
  }

  @override
  String dtcCategoryUnresolvedSources(int count, String addresses) {
    return '有 $count 筆回應無法判斷是哪個控制器送出的（$addresses）。已讀到的結果仍然有效，但不能當作全車結果。請重新掃描。';
  }

  @override
  String dtcCategoryPendingControllers(int count, int answered) {
    return '有 $count 個控制器還在處理這次查詢，$answered 個已回應。結果尚不完整，請稍候再掃描一次。';
  }

  @override
  String dtcCategoryRefusedControllers(int refused, int answered) {
    return '有 $refused 個控制器拒絕回答（$answered 個已回應）。這次掃描無法涵蓋全車，結果並不完整。';
  }

  @override
  String dtcCategoryUnrecognisedResponses(int count, int answered) {
    return '有 $count 筆回應無法辨識（$answered 個已回應）。其餘結果仍然有效，但這次掃描並不完整。';
  }

  @override
  String dtcCategoryMilCountMismatch(
    String controller,
    int claimed,
    int observed,
  ) {
    return '$controller 回報有 $claimed 筆已確認故障碼，但這次掃描只讀到 $observed 筆。請以車輛儀表為準，並洽維修廠。';
  }

  @override
  String dtcCategoryMilLitNoCodes(String controller) {
    return '$controller 回報故障燈亮著，但沒有讀到它所屬的故障碼。請以車輛儀表為準，並洽維修廠。';
  }

  @override
  String dtcCategoryMilDisagreement(String controllers) {
    return '車輛自身狀態與讀到的故障碼不符（$controllers）。請以車輛儀表為準，並洽維修廠。';
  }

  @override
  String get connectPairedListFailed => '無法讀取已配對的藍牙清單。請確認藍牙已開啟後再試。';

  @override
  String get connectBleScanUnavailable => '藍牙目前無法使用。請稍後再搜尋。';

  @override
  String get connectBleScanBluez =>
      '找不到可用的 BlueZ／D-Bus 藍牙服務。請確認系統已安裝並啟動 bluetooth 服務後再試。';

  @override
  String get connectBleScanUnclassified => 'BLE 搜尋失敗。';

  @override
  String dtcClearNrcConditions(String controller) {
    return '$controller 拒絕清除，因為目前的車輛狀態不允許。多數控制器在引擎運轉時不會清除故障記憶。請將電門轉到 ON 但不要發動引擎，然後再試一次。';
  }

  @override
  String dtcClearNrcUnsupported(String controller) {
    return '$controller 不支援清除服務（Mode 04）。這輛車的故障碼可能要用原廠或專用診斷設備才能清除。';
  }

  @override
  String dtcClearNrcBusy(String controller) {
    return '$controller 目前忙碌中。請稍候再試一次。';
  }

  @override
  String dtcClearNrcSecurity(String controller) {
    return '$controller 要求先通過安全認證才允許清除，這需要原廠或專用診斷設備。';
  }

  @override
  String dtcClearNrcOther(String controller, String code) {
    return '$controller 拒絕清除（原因碼 $code）。請稍候再試一次。';
  }

  @override
  String dtcClearSilentControllers(int count, String controllers) {
    return '有 $count 個控制器沒有回應清除指令（$controllers）。已回應的控制器已清除，其餘可能仍有故障碼。請重新掃描，不要再送一次清除。';
  }

  @override
  String dtcClearUnresolvedSources(int count, String addresses) {
    return '掃描時有 $count 筆回應無法判斷是哪個控制器送出的（$addresses），因此無法確認清除指令會送到哪些控制器。請重新掃描；若該位址一直沒有再出現，請重新連線後再試。';
  }

  @override
  String dtcClearUnresolvedSourcesDoNotRepeat(int count, String addresses) {
    return '清除指令的回應中有 $count 筆無法判斷來源的資料（$addresses）。不要再送一次清除。請重新掃描確認哪些故障碼還在。';
  }

  @override
  String dtcClearNrcConditionsDoNotRepeat(String controller) {
    return '$controller 拒絕清除，因為目前的車輛狀態不允許。多數控制器在引擎運轉時不會清除故障記憶。請將電門轉到 ON 但不要發動引擎，再重新掃描確認哪些故障碼還在。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。';
  }

  @override
  String dtcClearNrcUnsupportedDoNotRepeat(String controller) {
    return '$controller 不支援清除服務（Mode 04）。這輛車的故障碼可能要用原廠或專用診斷設備才能清除。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認哪些故障碼還在。';
  }

  @override
  String dtcClearNrcBusyDoNotRepeat(String controller) {
    return '$controller 目前忙碌中。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認哪些故障碼還在。';
  }

  @override
  String dtcClearNrcSecurityDoNotRepeat(String controller) {
    return '$controller 要求先通過安全認證才允許清除，這需要原廠或專用診斷設備。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。';
  }

  @override
  String dtcClearNrcOtherDoNotRepeat(String controller, String code) {
    return '$controller 拒絕清除（原因碼 $code）。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認哪些故障碼還在。';
  }

  @override
  String get sharePolicyDenied => '目前的連線或行車狀態不允許匯出。';

  @override
  String get shareSafetyChanged => '準備匯出期間狀態已改變，未開啟分享。';

  @override
  String get shareSizeLimit => '匯出檔超過 32 MiB 上限。';

  @override
  String get shareStagingBusy => '先前的分享檔仍在保留期內，請稍後再試。';

  @override
  String get shareCleanupRequired => '分享暫存區需要在重新啟動後檢查。';

  @override
  String get shareSpaceUnknown => '無法確認分享檔所需的可用空間。';

  @override
  String get shareNoSpace => '儲存空間不足，無法準備分享檔。';

  @override
  String get shareHandoffFailed => '檔案已準備完成，但系統分享介面無法開啟。';

  @override
  String get shareStorageFailure => '準備或記錄分享結果時發生儲存錯誤。';

  @override
  String shareTelemetrySubject(String sessionId) {
    return '本機 OBD 紀錄 $sessionId';
  }

  @override
  String shareRawTranscriptSubject(String stamp) {
    return 'Telltale 傳輸紀錄 $stamp';
  }

  @override
  String get shareRecoveredTranscriptSubject => 'Telltale 傳輸紀錄（上一次連線）';

  @override
  String get sharePidCsvSubject => 'Telltale 自訂 PID 定義';

  @override
  String get shareTorqueSubsetCsvSubject => 'Torque 相容 PID 定義';

  @override
  String get shareHumanReportCsvSubject => 'Telltale 人類可讀 PID 報表';

  @override
  String get transcriptExportUnidentified => '匯出失敗。';

  @override
  String get handshakeNoteUnexpected => '此步驟發生未預期的錯誤。完整錯誤保留在紀錄裡。';

  @override
  String pidFormulaUnsupportedConstruct(String term) {
    return '$term 是這個方言尚未實作的 Torque 函式，因此無法在這裡求值。';
  }

  @override
  String pidImportRowFormulaRejected(int line, String reason) {
    return '第 $line 行：$reason';
  }

  @override
  String get telemetryHistoryNeedsForeground => '請回到 App 後再操作';

  @override
  String get telemetrySessionPolicyChanged => '操作期間行車或連線狀態已改變';

  @override
  String get telemetrySessionInvalidId => '紀錄識別碼無效';

  @override
  String get telemetrySessionNotFound => '找不到這筆本機紀錄';

  @override
  String get telemetrySessionStorageFailed => '本機儲存作業失敗';

  @override
  String get telemetrySessionShareFailed => '無法準備或開啟分享';

  @override
  String get pidMutationPersistFailed => '自訂 PID 清單無法寫入。沒有任何變更。';

  @override
  String get powertrainAuthorizeYearOutOfRange => '該年式不在這個設定檔記載的年份範圍內。';

  @override
  String get connectionLayerTransport => '連線方式';

  @override
  String get connectionLayerProtocol => '協定';

  @override
  String get connectionLayerEcu => '控制器回應';

  @override
  String get connectionLayerEvidence => '證據';

  @override
  String get connectionLayerUnknown => '未知';

  @override
  String get connectionLayerNotObserved => '未觀察到';

  @override
  String get connectionLayerObserved => '已觀察';

  @override
  String get connectionLayerAnswered => '有回應';

  @override
  String get connectionLayerSoftware => '軟體';

  @override
  String get connectionLayerDemo => '內建模擬器';

  @override
  String get connectionLayerBle => '藍牙 LE';

  @override
  String get connectionLayerClassic => '藍牙 Classic';

  @override
  String get connectionLayerWifi => '無線網路';

  @override
  String connectionLayerRequestedObserved(String requested, String observed) {
    return '要求 $requested，實際 $observed';
  }

  @override
  String get connectionLayerKwpSubtypeUnknown => 'KWP，5-baud 與 fast 無法分辨';

  @override
  String get connectionFailureOpenSettings => '開啟系統設定。';

  @override
  String get connectionFailureTurnRadioOn => '請開啟藍牙。';

  @override
  String get connectionFailureCheckDistanceOrPower =>
      '適配器可能太遠或沒有供電。那是可能的原因，不是已確認的發現。';

  @override
  String get connectionFailureCheckIgnitionProtocolAdapter =>
      '請檢查電門、協定或適配器能力。沒有回應不能當成這輛車沒有 OBD。';

  @override
  String get connectionFailureRetryOrAuto => '請重試，或把協定設成 Auto。';

  @override
  String get connectionFailureKeepInvalidAndExport =>
      '這筆回應無效。維持無效並匯出有限診斷；它不是讀數。';

  @override
  String get settingsCatalogMarketCa => '加拿大（NRCan）';

  @override
  String get settingsCaPickerTitle => '加拿大官方車輛目錄';

  @override
  String settingsCaPickerScope(int firstYear, int lastYear) {
    return '僅 $firstYear–$lastYear 的加拿大油耗標示列。內燃機、電池電動與插電混合動力維持分開的資源類。相同廠牌／車名不是 EPA 或臺灣認證列。';
  }

  @override
  String get settingsCaMotorNotPower => '電機功率（kW）不是輪馬力，不會套用。';

  @override
  String get settingsCaClassIce => '內燃機';

  @override
  String get settingsCaClassBev => '電池電動';

  @override
  String get settingsCaClassPhev => '插電混合動力';

  @override
  String settingsCaWillApplyOnly(String fields) {
    return '只會套用 $fields。電機 kW、油耗、續航、CO2、VE、Cd、迎風面積、Crr 與傳動效率維持未解。';
  }

  @override
  String get serviceRecipesTitle => '診斷配方與主動測試';

  @override
  String get serviceRecipesSubtitle => '標準規範服務配方與非致動能力探索';

  @override
  String get serviceRecipesSafetyBannerTitle => '零實車候選（Zero Live Candidates）';

  @override
  String get serviceRecipesSafetyBannerBody =>
      '嚴禁實車雙向致動執行（合格實車數：0）。現有配方僅限模擬與基準測試。';

  @override
  String get serviceRecipesDiscoverySection => 'Mode 08 非致動能力探索';

  @override
  String get serviceRecipesDiscoveryDescription =>
      '僅透過 CAN 查詢標準基準 TID（\$00、\$20…），絕不發送致動指令探測。';

  @override
  String get serviceRecipesDiscoveryButton => '探索 Mode 08 支援項目';

  @override
  String get serviceRecipesDiscovering => '正在查詢支援項目…';

  @override
  String serviceRecipesDiscoverySuccess(String tids) {
    return 'ECU 支援 Mode 08。支援 TID：$tids';
  }

  @override
  String get serviceRecipesDiscoveryUnsupported => '此 ECU 不支援 Mode 08';

  @override
  String serviceRecipesDiscoveryUnknown(String reason) {
    return 'Mode 08 支援狀態未知：$reason';
  }

  @override
  String serviceRecipesDiscoveryPartialWarning(String reason, String blocks) {
    return '探索未完全完成（$reason）。未完成區塊：$blocks。未查到不代表不支援。';
  }

  @override
  String get serviceRecipesCatalogSection => '可用服務配方清單';

  @override
  String get serviceRecipesSimulationBadge => '模擬可用';

  @override
  String get serviceRecipesLiveBlockedBadge => '禁止實車（0 實車候選）';

  @override
  String serviceRecipesStandard(String standard) {
    return '標準規範：$standard';
  }

  @override
  String serviceRecipesEcuHeader(String header) {
    return '目標 ECU 標頭：$header';
  }

  @override
  String serviceRecipesHash(String hash) {
    return '標準 SHA-256：$hash';
  }

  @override
  String get serviceRecipesDetailTitle => '服務配方詳細資訊';

  @override
  String get serviceRecipesPreconditions => '安全前置條件';

  @override
  String get serviceRecipesRecovery => '控制權釋放／恢復指令';

  @override
  String get serviceRecipesClose => '關閉';

  @override
  String get serviceRecipesDiscoveryRequiresCan => '需要作用中的 OBD-II CAN 匯流排連線。';

  @override
  String serviceRecipesLoadError(String error) {
    return '載入服務配方時發生錯誤：$error';
  }

  @override
  String get serviceRecipesNoPreconditions => '無';

  @override
  String get settingsServiceRecipesEntry => '車行診斷配方與主動測試';

  @override
  String get settingsServiceRecipesDesc => '檢視工作站服務配方並安全探索 Mode 08 支援項目';

  @override
  String get mode08ReasonUnheaderedLimitation =>
      '來源歸因與覆蓋完整度未確認：無標頭回應無法建立跨區塊 ECU 身分';

  @override
  String mode08ReasonNoResponseWithEcu(
    String block,
    String ecu,
    String marker,
  ) {
    return '區塊 $block 來自 $ecu 無回應：$marker';
  }

  @override
  String mode08ReasonNoResponse(String block, String marker) {
    return '區塊 $block 無回應：$marker';
  }

  @override
  String mode08ReasonNegativeWithEcu(String block, String ecu, String nrc) {
    return '區塊 $block 來自 $ecu 負回應 (NRC $nrc)';
  }

  @override
  String mode08ReasonNegative(String block, String nrc) {
    return '區塊 $block 負回應 (NRC $nrc)';
  }

  @override
  String mode08ReasonMalformedWithEcu(
    String block,
    String ecu,
    String details,
  ) {
    return '區塊 $block 來自 $ecu 格式錯誤：$details';
  }

  @override
  String mode08ReasonMalformed(String block, String details) {
    return '區塊 $block 格式錯誤：$details';
  }

  @override
  String mode08ReasonTimeout(String block) {
    return '區塊 $block 查詢逾時';
  }

  @override
  String get mode08ReasonBudgetExceeded => '在查詢所有區塊前已超出預算時間';

  @override
  String get mode08ReasonSessionDisconnected => '探索期間連線中斷或被取代';

  @override
  String mode08ReasonUnqueriedAnnounced(String blocks) {
    return 'ECU 宣告但未查詢的區塊：$blocks';
  }

  @override
  String get mode08ReasonRequiresCanBus => 'Mode 08 功能探索需要解析的 OBD-II CAN 匯流排';

  @override
  String get mode08ReasonUnexpectedExecution => '查詢支援 TID 時收到非預期的執行回應';

  @override
  String get pidDetailEmptyTitle => '選取 PID';

  @override
  String get pidDetailEmptyBody => '從清單中選取一個 PID 以檢視其定義與即時狀態。';

  @override
  String get pidDetailRangeLabel => '範圍';

  @override
  String get pidDetailPriorityLabel => '優先權';

  @override
  String pidDetailHeaderDefault(String header) {
    return '預設 ($header)';
  }

  @override
  String get dtcSystemOverview => '系統總覽';

  @override
  String get dtcPartialObservationBadge => '部分掃描';

  @override
  String get dtcPartialObservationBody => '此故障碼已讀取，但該類別在所有控制器間的掃描未完整完成。';

  @override
  String get dtcLinkedFreezeFrameTitle => '關聯凍結幀';

  @override
  String get dtcNoLinkedFreezeFrame => '這次掃描沒有可安全歸屬於此故障碼與控制器的凍結幀。';

  @override
  String get performanceGuideTitle => '起步加速測試指南';

  @override
  String get performanceGuideStep1 => '1. 選擇目標車速，然後準備計時';

  @override
  String get performanceGuideStep2 => '2. 將車輛完全停妥，等待畫面顯示已就緒';

  @override
  String get performanceGuideStep3 => '3. 開始加速；偵測到起步後會自動開始計時';

  @override
  String get performanceGuideStep4 => '4. 到達目標車速後即完成本次計時';

  @override
  String get performanceRecordingTrace => '加速中... 正在記錄速度點位';

  @override
  String get performanceNoAnalysisTitle => '沒有足夠的分析資料';

  @override
  String get performanceNoAnalysisBody => '本次計時在取得足夠的車速樣本前已中止，因此無法產生速度軌跡或分段成績。';

  @override
  String get connectActivityReconnectingAutomatically => '轉接器停止回應，正在自動重新連線…';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get adapterErrorActivityAlert => '总线活动警示';

  @override
  String get adapterErrorBufferFull => '适配器缓冲区溢出';

  @override
  String get adapterErrorBus => '总线错误，可能是接线问题';

  @override
  String get adapterErrorBusBusy => '总线忙碌';

  @override
  String get adapterErrorBusInit => '总线初始化失败';

  @override
  String get adapterErrorCan => 'CAN 总线错误';

  @override
  String get adapterErrorData => '收到的数据不正确';

  @override
  String get adapterErrorFeedback => '信号反馈错误';

  @override
  String get adapterErrorInternal => '适配器内部错误';

  @override
  String get adapterErrorLowPowerAlert => '适配器即将进入低功耗模式';

  @override
  String get adapterErrorLowVoltageReset => '电压过低导致适配器重置';

  @override
  String get adapterErrorNoData => '没有收到回应（可能是暂时无回应，或车辆不支持）';

  @override
  String get adapterErrorStopped => '传输被中断';

  @override
  String get adapterErrorUnableToConnect => '无法与 ECU 通信，请确认点火开关已打开';

  @override
  String get adapterErrorUnknownCommand => '适配器不支持此指令';

  @override
  String get appTagline => '车辆实时遥测';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => '外观';

  @override
  String get connectActivityAbortingPreviousConnection => '正在中止上一个连接，请稍候…';

  @override
  String get connectAnswerBleWithClassic =>
      '选 Bluetooth LE。不需要事先配对，直接在 App 里扫描 —— 就算它出现在系统的蓝牙配对清单里，也不要去配对，那条路走不通。如果扫描不到，那盒子上的 4.0 只是芯片规格，改用 Bluetooth Classic。';

  @override
  String get connectAnswerBleWithoutClassic =>
      '选 Bluetooth LE。不需要事先配对，直接在 App 里扫描 —— 就算它出现在系统的蓝牙配对清单里，也不要去配对，那条路走不通。如果扫描不到，先确认适配器有通电，或改试 Wi‑Fi；此主机未开放 Bluetooth Classic。';

  @override
  String get connectAnswerClassic =>
      '选 Bluetooth Classic。先在系统设置里配对完成，App 不能代替你配对。配对码多半是 1234 或 0000。';

  @override
  String get connectAnswerWifiDesktop => '选 Wi-Fi。先把这台设备连上那个网络，再回来输入地址。';

  @override
  String get connectAnswerWifiPhone => '选 Wi-Fi。先把手机连上那个网络，再回来输入地址。';

  @override
  String get connectBleBody =>
      'BLE 适配器不需事先配对。搜索后选择你的设备即可，多见名称为 OBDII、V-LINK、Vgate 或 IOS-Vlink。';

  @override
  String connectBleEmptyScan(String next) {
    return '搜索结束，没有找到 BLE 适配器。请依次确认：适配器的灯是否亮起 —— 多数 OBD 插座要将点火开关转到 ON 才供电；接着检查距离，先坐进车里再搜索。${next}BLE 适配器不需要、也不应该在系统设置里配对，那条路走不通。';
  }

  @override
  String get connectBleEmptyScanNextClassic =>
      '最后看盒子上的规格，如果写的是 2.0 或 3.0，那是 Bluetooth Classic，不会出现在这份清单里，请改用上面的 Bluetooth Classic。';

  @override
  String get connectBleEmptyScanNextWifi =>
      '最后看盒子上的规格：若写的是 2.0／3.0 或只有 Wi‑Fi，请改试 Wi‑Fi（此主机未开放 Bluetooth Classic）。';

  @override
  String get connectBlePermissionDeniedForever =>
      '蓝牙权限已被永久拒绝。系统不会再显示授权对话框，请到应用程序设置打开。';

  @override
  String get connectBlePermissionNeeded => '需要蓝牙权限才能搜索。';

  @override
  String get connectBleScan => '搜索 BLE 设备';

  @override
  String get connectBleScanning => '搜索中…';

  @override
  String get connectBleUnavailableHost => 'Bluetooth LE 在此主机尚不可用';

  @override
  String get connectBluetoothOff => '蓝牙未打开，请先在系统设置打开蓝牙。';

  @override
  String get connectBluetoothPermissionDeniedForever =>
      '蓝牙权限已被永久拒绝，请到系统设置打开后再试。';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      '需要蓝牙权限才能列出已配对的适配器。';

  @override
  String get connectBody => '插上 ELM327 适配器并打开点火开关，或使用内置模拟器。';

  @override
  String get connectCancel => '取消';

  @override
  String get connectClassicEmptyLinuxPort =>
      '找不到蓝牙串行端口（/dev/rfcomm*）。请先以 BlueZ 配对 ELM327，再用 rfcomm bind（或等效）创建 RFCOMM TTY 后重试。';

  @override
  String get connectClassicEmptyPaired =>
      '找不到已配对的适配器。请先到系统蓝牙设置完成配对（多数 ELM327 的配对码为 1234 或 0000）。';

  @override
  String get connectClassicEmptyWindowsPort =>
      '找不到蓝牙串行端口（COMx）。请先在 Windows 蓝牙设置中配对 ELM327，确认设备管理器中显示「Standard Serial over Bluetooth link」。';

  @override
  String get connectClassicListLinuxPort =>
      '这里列出 BlueZ 已绑定的蓝牙串行端口（/dev/rfcomm* 或等效）。空清单代表系统尚未创建 RFCOMM 节点，不是 App 坏掉。';

  @override
  String get connectClassicListPaired =>
      '这里列出系统上所有已配对的设备 — 耳机、喇叭也会在内，看起来像适配器的排在前面。选错了就按「取消」，不必等它自己失败，取消后可以马上改选别的。';

  @override
  String get connectClassicListWindowsPort =>
      '这里列出与蓝牙关联的 COM 端口（「Standard Serial over Bluetooth link」）。空清单代表系统尚未创建虚拟串行端口，不是 App 坏掉。';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic（SPP）目前在 Android、macOS（IOBluetooth RFCOMM）、Windows（COM）与 Linux（/dev/rfcomm*）可用';

  @override
  String get connectClassicUnavailableIos => 'iOS 不开放第三方 App 使用蓝牙 SPP';

  @override
  String get connectConnect => '连接';

  @override
  String get connectDemoBody =>
      '模拟一台 2.0 L 涡轮增压四缸发动机，包含怠速、加速、巡航和减速循环，各信号保持物理关联（换挡时转速下降，但车速继续上升）。故障码、VIN 读取和 fastMode 批量查询均可完整使用。';

  @override
  String get connectDemoStart => '启动模拟器';

  @override
  String get connectHandshakeTitle => 'ELM327 初始化';

  @override
  String get connectHandshakeTitleLastAttempt => 'ELM327 初始化（上次尝试）';

  @override
  String get connectHeadline => '选择连接方式';

  @override
  String get connectIssueAdapterAcceptedThenSilent =>
      '适配器接受了连接，但在时限内没有回应。通常是它还没通电 —— 多数 OBD 插座要将点火开关转到 ON 才供电；也可能是另一个 App 已连接它，请先关闭那个 App 再试。';

  @override
  String connectIssueAdapterSilentOnReset(String command) {
    return '适配器没有回应重置指令（$command）。这个设备可能不是 ELM327 适配器，或是连到了错误的设备。';
  }

  @override
  String get connectIssueAdapterStoppedResponding => '适配器停止回应，连接已中断。';

  @override
  String get connectIssueConnectionSetupFailed =>
      '连接在创建过程中失败了。请确认适配器已通电、就在附近，然后再试一次。完整的错误留在下方的记录里。';

  @override
  String get connectIssueHandshakeIncomplete => '初始化未通过，适配器可能不兼容。';

  @override
  String connectIssueHandshakeStepFailed(String command, String reason) {
    return '初始化在 $command 失败（$reason）。请确认适配器已插好、车辆点火开关已打开。';
  }

  @override
  String get connectIssuePreviousConnectionStillAborting =>
      '上一个连接仍在中止中，适配器还没有释放。请等几秒再试一次。';

  @override
  String get connectLastAdapterConnect => '直接连接';

  @override
  String get connectLastAdapterForget => '忘记';

  @override
  String get connectLastAdapterTitle => '上次用的适配器';

  @override
  String get connectOpenAppSettings => '打开应用程序设置';

  @override
  String get connectOpenSystemSettings => '打开系统设置';

  @override
  String get connectOpeningConnection => '创建连接中…';

  @override
  String get connectPairedPill => '已配对';

  @override
  String get connectQuestionBle => '包装盒、商品页面或设备名称上是否标有 BLE、4.0 或 5.0？';

  @override
  String get connectQuestionClassic => '都不是 —— 比较旧、盒子上写 2.0 或 3.0？';

  @override
  String get connectQuestionWifiDesktop =>
      '系统的 Wi-Fi 清单里多出一个网络（像 V-LINK、WiFi_OBDII）？';

  @override
  String get connectQuestionWifiPhone =>
      '手机的 Wi-Fi 清单里多出一个网络（像 V-LINK、WiFi_OBDII）？';

  @override
  String get connectSearchAgain => '重新搜索';

  @override
  String connectSignalStrength(int bars, int total) {
    return '信号强度 $bars/$total';
  }

  @override
  String get connectTranscriptKept => '这次尝试的完整往返记录留着了。带回来比一句信息有用。';

  @override
  String get connectTransportBleDescription => 'GATT UART — 较新的低功耗适配器';

  @override
  String get connectTransportBleTitle => 'Bluetooth LE';

  @override
  String get connectTransportClassicDescription =>
      'RFCOMM / SPP — 最多见的平价 ELM327';

  @override
  String get connectTransportClassicTitle => 'Bluetooth Classic';

  @override
  String get connectTransportDemoDescription => '内置模拟 ECU，无需硬件即可完整体验';

  @override
  String get connectTransportDemoTitle => 'Demo 模拟器';

  @override
  String get connectTransportWifiDescription =>
      'TCP 通信端口，多为 192.168.0.10:35000';

  @override
  String get connectTransportWifiTitle => 'Wi-Fi';

  @override
  String get connectWhichIntro => '不用管 SPP、GATT 这些名词。看你的适配器插上去之后怎么运作就好：';

  @override
  String get connectWhichNoteGuessing =>
      '猜错不会怎么样 —— 连不上就退回来换另一个试。真的卡住，先用最下面的「Demo 模拟器」确认 App 本身没问题。';

  @override
  String get connectWhichNoteIos =>
      'iPhone 只能用 Wi-Fi 或 BLE —— 一般的蓝牙 ELM327 在 iOS 上完全不能用，这是系统限制，换 App 也一样。';

  @override
  String get connectWhichTitle => '不确定要选哪一个？';

  @override
  String get connectWifiHostLabel => 'IP 地址';

  @override
  String get connectWifiHostRequired => '请输入适配器的 IP 地址。';

  @override
  String get connectWifiInstructionsDesktop =>
      '请先将这台电脑连上适配器发出的 Wi-Fi 热点，再输入其地址。系统若提示此网络连不上互联网，请选择继续使用。桌面系统一般会把热点当默认路由；不需要 Android 那套 Wi-Fi 路由绑定。';

  @override
  String get connectWifiInstructionsPhone =>
      '请先将手机连上适配器发出的 Wi-Fi 热点，再输入其地址。系统若问「此 Wi-Fi 连不上互联网，是否继续使用」，选继续使用。在 Android 上，Telltale 连接时会尝试把流量固定在 Wi-Fi 路由，避免被移动数据抢走。';

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '「$value」不是有效的通信端口，范围是 $min–$max。';
  }

  @override
  String get connectWifiPortLabel => '端口';

  @override
  String connectWifiPortRequired(int port) {
    return '请输入通信端口（多数适配器为 $port）。';
  }

  @override
  String get dashboardBatchedPolling => '批量读取';

  @override
  String get dashboardBatchingEnabled => '已启用批量';

  @override
  String get dashboardChoosePids => '选择 PID';

  @override
  String get dashboardEmptyBody => '到 PID 页面挑选想要监看的信号，它们会出现在这里。';

  @override
  String get dashboardEmptyTitle => '仪表盘为空';

  @override
  String get dashboardGenericObd => '通用 OBD';

  @override
  String get dashboardLocalRecordings => '本机记录';

  @override
  String get dashboardNotConnected => '未连接';

  @override
  String get dashboardPollingModeHelpAction => '关于读取模式';

  @override
  String get dashboardPollingModeHelpBatching =>
      '「已启用批量」表示 Telltale 可以将多个 PID 请求合并为一次交互，以减少往返次数：允许尝试合并请求，且批量功能没有被关闭。这仍只是许可，而非实测，因为某次交互是否合并请求，还取决于车辆确认支持哪些 PID，以及有多少请求正在等待。';

  @override
  String get dashboardPollingModeHelpObserved =>
      '「批量读取」表示本次连接中有一条 Mode 01 指令实际携带了多个 PID。这是对那次交互的记录，不保证下一次也会合并请求，也不是对吞吐量的主张。';

  @override
  String get dashboardPollingModeHelpRate =>
      'PIDs/s 是过去一秒观测到的速率，不是对延迟、新鲜度或准确度的保证。它会随适配器、总线、ECU、你选的 PID、每次回复的大小以及错误而变动。';

  @override
  String get dashboardPollingModeHelpSingle =>
      '「单次请求模式」表示每个 Mode 01 PID 都单独读取。Telltale 会在以下情况使用该模式：总线完全不接受合并请求（所有非 CAN 车辆都是如此）；尚无支持块回应，因为合并查询车辆尚未确认的 PID 会导致回复过短；或者合并请求的回复无法拆分，可能是回复被截断、适配器报告缓冲区已满而拒绝请求，或根本没有回应。读数仍会继续更新，这本身不代表连接失败。';

  @override
  String get dashboardPollingModeHelpTitle => '读取模式';

  @override
  String get dashboardSingleRequestMode => '单次请求模式';

  @override
  String get dashboardVinRead => '已读 VIN';

  @override
  String get dashboardWorkspaceGauges => '仪表';

  @override
  String get dashboardWorkspaceTrends => '趋势';

  @override
  String get datumBadgeCommunityDecode => '社区解码';

  @override
  String get datumBadgeDemo => '模拟';

  @override
  String get datumBadgeEstimated => '估算';

  @override
  String get datumBadgeExperimental => '实验';

  @override
  String get datumBadgeFieldVerified => '已实车验证';

  @override
  String get datumBadgeInvalid => '无效';

  @override
  String get datumBadgeJustUpdated => '刚更新';

  @override
  String get datumBadgeOutOfReferenceRange => '超出参考范围';

  @override
  String get datumBadgePartial => '部分';

  @override
  String get datumBadgeStale => '过期';

  @override
  String get datumBadgeTentativeDecode => '暂定解码';

  @override
  String get datumBadgeUnverified => '未验证';

  @override
  String get datumBadgeUnverifiedOnThisVehicle => '本车未验证';

  @override
  String get datumBadgeUserSupplied => '用户提供';

  @override
  String get datumGapModelYearUnknown => '车型年份未知';

  @override
  String get datumGapNoCatalogMatch => '目录无匹配';

  @override
  String get datumGapVinNotRead => 'VIN 未读到';

  @override
  String get datumNextStepEstimateOnly => '只影响此估算，其他读数照用';

  @override
  String get datumNextStepGenericObd => '可继续通用 OBD，或手动选车、补参数';

  @override
  String get datumNextStepOtherReadings => '失败只影响此项，其他读数照用';

  @override
  String get datumNextStepRawOnly => '可查看原始回复和错误，但两者均不可当作正常数值。';

  @override
  String get datumReasonAssumptionsUnconfirmed => '假设尚未确认，仍会显示估算值。';

  @override
  String get datumReasonBusError => '总线错误';

  @override
  String get datumReasonFormulaError => '公式错误';

  @override
  String get datumReasonFuelEstimateMissingInputs => '油耗估算缺少必要输入';

  @override
  String get datumReasonHeaderNotOnThisBus => '标头不符本车总线';

  @override
  String get datumReasonHorsepowerEstimateMissingInputs => '马力估算缺少必要输入';

  @override
  String get datumReasonMalformedPacket => '坏数据包，只可查看原文';

  @override
  String get datumReasonNoAnswer => '无回应，应用将在约一分钟后重试';

  @override
  String get datumReasonNoReadingYet => '尚无读数';

  @override
  String get datumReasonNonFiniteValue => '非有限数值';

  @override
  String get datumReasonOutOfReferenceRangeKept => '超出正常参考范围，保留原始读数';

  @override
  String get datumReasonPidUnsupported => '此车辆不支持这个 PID';

  @override
  String get datumReasonUnsafeService => '此服务不是只读查询';

  @override
  String get datumReasonUnsafeServiceStopped => '此服务不是只读查询，因此未发送。';

  @override
  String get datumStatusAssumptions => '假设';

  @override
  String get datumStatusClose => '关闭';

  @override
  String get datumStatusFollowsData => '状态随数据';

  @override
  String get datumStatusDetailsHint => '点按查看读数状态说明';

  @override
  String get datumStatusUnverifiedExplanation =>
      '未验证表示此处没有该解码器在本车上进行实车比对的记录。这不代表读数错误，也不构成对其准确性的认证。数据新鲜程度和故障状态会分别显示。';

  @override
  String get datumStatusFormula => '公式';

  @override
  String get derivedAirflow => '空气流量';

  @override
  String get derivedEcuFuelTitle => 'ECU 油耗数据';

  @override
  String get derivedEcuReported => 'ECU 回报';

  @override
  String get derivedEngineHorsepower => '发动机功率';

  @override
  String get derivedEstimatedFuelTitle => '估算油耗';

  @override
  String get derivedEstimatesDetailsTitle => '估算公式与假设';

  @override
  String get derivedEstimatesTitle => '推算数值';

  @override
  String get derivedFuelUse => '油耗';

  @override
  String get derivedTorque => '扭矩';

  @override
  String get derivedUnavailableMessage => '等待车速与加速度数据后才能推算马力';

  @override
  String dtcBothSilentDetail(Object mode) {
    return '车辆没有回应 Mode $mode 查询，而 Mode 03 同样没有回应 — 因此不能判断这是车辆不支持，还是这次连接没有读到。';
  }

  @override
  String dtcCategoryFault(Object category) {
    return '$category相关故障';
  }

  @override
  String get dtcClear => '清除';

  @override
  String get dtcClearCancel => '取消';

  @override
  String get dtcClearConfirm => '确定清除';

  @override
  String get dtcClearDialogBody =>
      '这会清掉已保存与待确认的故障码并熄灭故障灯，同时重置排放就绪状态 — 车辆需要重新完成一轮自我诊断才能通过验车。永久故障码（Mode 0A）不能清除。';

  @override
  String get dtcClearDialogFrameUnread =>
      '这次没有读到冻结帧，但不代表车上没有。先重新扫描一次，再决定要不要清除。';

  @override
  String dtcClearDialogFrames(Object codes) {
    return '连同 $codes 的冻结帧 —— 故障发生当下的转速、水温、负荷那一整份记录 —— 也会一起消失，而且故障再次发生前读不回来。';
  }

  @override
  String get dtcClearDialogTitle => '清除故障码？';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '这次扫描有 $count 个类别没有得到完整回应（$categories），可能还有你没看到的故障码。清除后就再也读不到了。',
    );
    return '$_temp0';
  }

  @override
  String get dtcClearCancelledBeforeSend => '清除已取消，指令尚未从应用发出。请重新扫描，如果仍想清除再试一次。';

  @override
  String get dtcClearConfirmed => '已送出清除指令。';

  @override
  String get dtcClearFailureDoNotRepeat =>
      '清除指令可能已经送到车上。不要再发送清除指令 —— 第二次全车清除可能会重置可能已经清除故障码的控制器的排放就绪状态。请重新扫描，查看还剩哪些故障码。';

  @override
  String get dtcClearFailureGeneric => '清除没有完成。请先重新扫描，看目前的故障码，再决定要不要再试。';

  @override
  String get dtcClearNotAccepted => '清除失败，没有控制器接受指令。可以再试一次。';

  @override
  String get dtcClearPartiallyConfirmed =>
      '已有控制器回报清除完成，但其余控制器未能确认。不要再送一次清除 —— 重复清除会让已完成的控制器再一次重置排放就绪状态。请重新扫描确认结果。';

  @override
  String get dtcClearPreviousConnectionUnconfirmed =>
      '上一次连接送出过清除指令，结果没有确认。请先重新扫描，确认哪些故障码还在，再决定要不要清除。';

  @override
  String get dtcClearRescanSettled => '上一次清除的结果未能完全确认，以下是重新扫描后的实际状况。';

  @override
  String get dtcClearSentUnconfirmed =>
      '清除指令已发送，但响应在传输过程中损坏，无法确定车辆是否已清除故障码。请重新扫描确认；不要再发送清除指令 —— 如果已经成功，重复清除会重置排放就绪状态。';

  @override
  String get dtcClearTimeout => '清除指令送出后没有回应，未能确认是否已清除。请重新扫描确认。不要直接再清除一次。';

  @override
  String get dtcClearUnexpected => '清除失败，未能确认车辆是否已清除，请重新扫描确认。不要直接再清除一次。';

  @override
  String get dtcClearing => '清除中…';

  @override
  String get dtcScanDisconnectedMidScan => '连接在扫描途中中断，这次扫描没有完成。';

  @override
  String get dtcScanInterrupted =>
      '扫描在中途被中断（可能是切换到其他 App 或连接变更），没有得到完整结果。请重新扫描。';

  @override
  String get dtcCompleteCleanBody => '这代表每个回复的控制器都回报无故障码，不代表车上每个模块都已被问到。';

  @override
  String get dtcCompleteCleanTitle => '已回应的控制器均未报告故障码。';

  @override
  String dtcControllerLabel(Object controller) {
    return '控制器 $controller';
  }

  @override
  String get dtcDismiss => '关闭';

  @override
  String dtcFreezeFrameBody(Object code) {
    return '$code 被确认的那一刻，这个控制器记下的数值。清除故障码会一并销毁这份记录。';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      '这个控制器有冻结帧，但没有回应询问其中有哪些项目的查询，因此无法读取内容。重新扫描可能有效。';

  @override
  String get dtcFreezeFrameNothingDecodable => '这个控制器有冻结帧，但其中没有本 App 能解读的项目。';

  @override
  String get dtcFreezeFrameTitle => '故障发生当下的车况';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '另有 $count 个项目在这份冻结帧里，本 App 没有对应的换算公式，所以没有列出。',
    );
    return '$_temp0';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个项目这次没有读回来（可能是时间不够或控制器没回应）。重新扫描可能会读到。',
    );
    return '$_temp0';
  }

  @override
  String get dtcFreezeFrameUnreadPanel =>
      '这次没有读到冻结帧 —— 不代表车上没有。请先重新扫描再决定要不要清除故障码，因为清除会永久销毁故障当下的记录。如果每次扫描都一样，可能是这台车不提供。';

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label（Mode $mode）· $count';
  }

  @override
  String get dtcHeadline => '故障码';

  @override
  String get dtcListSeparator => '、';

  @override
  String get dtcManufacturerSpecific => '原厂自定义码 — 需查阅该车系维修手册';

  @override
  String get dtcMilOff => '故障灯没有亮';

  @override
  String get dtcMilOn => '故障灯亮着';

  @override
  String get dtcMonitorBoostPressure => '增压压力';

  @override
  String get dtcMonitorCatalyst => '催化转化器';

  @override
  String get dtcMonitorComponents => '综合组件监控';

  @override
  String get dtcMonitorEgr => 'EGR / VVT 系统';

  @override
  String get dtcMonitorEvaporative => '蒸发排放系统';

  @override
  String get dtcMonitorExhaustSensor => '排气传感器';

  @override
  String get dtcMonitorFuelSystem => '燃油系统监控';

  @override
  String get dtcMonitorGasolineParticulateFilter => '汽油微粒滤清器（GPF）';

  @override
  String get dtcMonitorHeatedCatalyst => '加热型催化转化器';

  @override
  String get dtcMonitorMisfire => '失火监控';

  @override
  String get dtcMonitorNmhcCatalyst => 'NMHC 催化转化器';

  @override
  String get dtcMonitorNoxAftertreatment => 'NOx / SCR 后处理';

  @override
  String get dtcMonitorOxygenSensor => '氧传感器';

  @override
  String get dtcMonitorOxygenSensorHeater => '氧传感器加热';

  @override
  String get dtcMonitorParticulateFilter => '微粒滤清器';

  @override
  String get dtcMonitorSecondaryAir => '二次空气喷射';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — 本 App 没有这一码的详细说明';
  }

  @override
  String get dtcNotConnectedBody => '需要连上 ELM327 适配器或启动模拟器才能读取故障码。';

  @override
  String get dtcNotConnectedTitle => '尚未连接';

  @override
  String get dtcNotScanned => '尚未扫描';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '三个类别的查询均已完成。有 $count 个控制器（$controllers）既未实现待确认故障码，也未实现永久故障码 —— 这在许多车辆上属于正常情况，但也因此无法断言这辆车没有故障。',
    );
    return '$_temp0';
  }

  @override
  String get dtcPartialCleanTitle => '已回应的类别均未报告故障码。';

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories 没有回应，状态未能确认 — 这不等于车辆没有问题。';
  }

  @override
  String dtcPartialCodesRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '这个类别中止前已读到 $count 个故障码，但覆盖范围不完整：',
    );
    return '$_temp0';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return '这个类别只有部分控制器回应，其余没有回复，因此不能当作全车的结果。$message';
  }

  @override
  String get dtcReadFailed => '读取失败';

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label（Mode $mode）：$message';
  }

  @override
  String get dtcReadinessAllComplete => '这个控制器负责的监控项目都已完成。';

  @override
  String dtcReadinessIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还有 $count 项没有完成，现在去验车可能不会过。',
    );
    return '$_temp0';
  }

  @override
  String get dtcReadinessSaysNothing =>
      '这个控制器没有回报任何监控项目 —— 它可能不负责排放监控，这不代表已经就绪。';

  @override
  String get dtcReadinessTitle => '排放就绪状态';

  @override
  String get dtcRescanFirst => '请先重新扫描';

  @override
  String get dtcRetry => '重试';

  @override
  String get dtcScanBody => '读取 Mode 03 已保存、Mode 07 待确认与 Mode 0A 永久故障码。';

  @override
  String get dtcScanTitle => '扫描车辆故障码';

  @override
  String get dtcScanning => '扫描中…';

  @override
  String dtcSelfReportedCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '这个控制器自报有 $count 个已确认的故障码。',
    );
    return '$_temp0';
  }

  @override
  String get dtcSelfReportedNoCodes => '这个控制器自报没有已确认的故障码。';

  @override
  String get dtcSilentCategoryHeadline => '这个类别没有回应';

  @override
  String get dtcSilentPendingDetail =>
      '待确认故障码（Mode 07）没有回应。可能是这具 ECU 未实现这个服务，也可能是这次没有读到 —— 没有回应不能分辨两者，也不能当作「没有待确认故障」。已保存故障码的结果不受影响。';

  @override
  String get dtcSilentPermanentDetail =>
      '永久故障码（Mode 0A）没有回应。这个类别在 2010 年前后才随新一代 OBD-II 导入，较旧的车辆不一定支持 —— 但没有回应也可能只是这次没读到，两者不能分辨。已保存故障码的结果不受影响。';

  @override
  String get dtcStartScan => '开始扫描';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return '车辆没有回应 Mode $mode 查询，因此未能确认是否有已保存的故障码。这与「没有故障码」不是同一件事。';
  }

  @override
  String dtcTotalCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '共 $count 个故障码',
    );
    return '$_temp0';
  }

  @override
  String get dtcUnconfirmed => '未能确认';

  @override
  String get dtcUnknownError => '未知错误';

  @override
  String get dtcUnknownMonitor => '未知监控项目';

  @override
  String get dtcVerdictCompleteClean => '已回应的控制器没有故障码';

  @override
  String get dtcVerdictPartialClean => '部分未确认';

  @override
  String get fieldEventBody =>
      '只在车辆完全停妥时，由乘客或停车中的操作人员按下。事件会与 OBD 原始数据使用同一条时间轴并尝试立即保存。';

  @override
  String get fieldEventEngineStarted => '发动机启动';

  @override
  String get fieldEventHeading => '实车事件标记';

  @override
  String get fieldEventIgnitionOn => '点火开关 ON';

  @override
  String get fieldEventMemoryOnly => '已记录在本次会话中，但自动保存失败 —— 请立即导出通信记录。';

  @override
  String fieldEventRecorded(String marker) {
    return '已记录并保存：$marker';
  }

  @override
  String get fieldEventRoadTestStarted => '道路测试开始';

  @override
  String get fieldEventThrottleBlip => '轻踩油门';

  @override
  String get fieldEventUnavailable => '目前没有可记录的实车连接。';

  @override
  String get gaugeNoData => '无数据';

  @override
  String gaugeNoDataBecause(String reason) {
    return '无数据 — $reason';
  }

  @override
  String gaugeReadingStale(String reading) {
    return '$reading（数据已过期）';
  }

  @override
  String get gaugeUnsupportedByVehicle => '此车辆不支持';

  @override
  String get handshakeNoteAborted => '前面的步骤失败后已停止';

  @override
  String get handshakeNoteEcuRefusedSupportQuery => 'ECU 拒绝了支持情况查询（否定响应）';

  @override
  String get handshakeNoteEcuSilent => 'ECU 没有回应';

  @override
  String get handshakeNoteNotAcknowledged => '适配器未确认此指令';

  @override
  String get handshakeNoteNotModeOnePositiveReply => '回应不是 Mode 01 的正向回复';

  @override
  String get handshakeNotePidEchoMismatch => '回复中回显的 PID 与请求的不符';

  @override
  String get handshakeNoteSupportMaskTooShort => '支持度回应过短（需要 41 00 加四个字节）';

  @override
  String get handshakeNoteTimedOut => '超时';

  @override
  String get handshakeStepAdapterVersion => '读取适配器版本';

  @override
  String get handshakeStepAdaptiveTiming => '启用自适应计时，采用数据手册推荐的设置';

  @override
  String get handshakeStepBatteryVoltage => '读取电瓶电压';

  @override
  String get handshakeStepDeviceIdentity => '读取设备识别字符串';

  @override
  String get handshakeStepEchoOff => '关闭指令回音';

  @override
  String get handshakeStepLinefeedsOff => '关闭换行字符';

  @override
  String get handshakeStepMemoryOff => '关闭内存写入';

  @override
  String get handshakeStepNoReason => '无回应';

  @override
  String get handshakeStepProtocolAuto => '自动检测总线协议';

  @override
  String get handshakeStepProtocolDescription => '读取协议描述';

  @override
  String get handshakeStepProtocolNumber => '读取协议编号';

  @override
  String get handshakeStepReset => '软件重置适配器';

  @override
  String get handshakeStepResponseTimeout => '设置回应超时 ~408ms';

  @override
  String get handshakeStepSpacesOff => '关闭空格，减少三分之一的传输量';

  @override
  String get handshakeStepSupportProbe => '查询 ECU 支持的 PID（确认车辆已回应）';

  @override
  String get languageSaveFailed => '未能保存语言设置，请再试一次。';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get navDashboard => '仪表盘';

  @override
  String get navDtc => '故障码';

  @override
  String get navPerformance => '计时';

  @override
  String get navPid => 'PID';

  @override
  String get navSettings => '设置';

  @override
  String get performanceArm => '准备计时';

  @override
  String get performanceDisclaimer =>
      '成绩以 OBD 车速信号为准。多数车辆的车速表本身有 1–3 km/h 的正偏差，且信号更新率约每秒 10–20 次，因此结果仅供参考，不等同于专业测试设备。';

  @override
  String get performanceHeadline => '加速测试';

  @override
  String get performanceNoSpeedSignal => '目前没有有效的车速信号（PID 010D）。加速测试需要它才能计时。';

  @override
  String get performanceNotConnectedBody => '加速测试需要实时车速数据，请先连接或启动模拟器。';

  @override
  String get performanceNotConnectedTitle => '尚未连接';

  @override
  String get performancePeakSpeed => '最高车速';

  @override
  String get performanceReset => '重置';

  @override
  String get performanceSecondsUnit => '秒';

  @override
  String get performanceSpeedGaugeLabel => '车速';

  @override
  String get performanceSpeedTraceHeading => '速度轨迹';

  @override
  String get performanceSplitsHeading => '分段成绩';

  @override
  String get performanceStateAborted => '这次计时未完成，以下为中止前的记录';

  @override
  String get performanceStateAwaitingSpeedSignal => '等待车速信号';

  @override
  String performanceStateAwaitingStandstill(String speed) {
    return '请先完全停车 — 目前 $speed km/h';
  }

  @override
  String performanceStateFinished(int target) {
    return '完成 0 → $target km/h';
  }

  @override
  String get performanceStateIdle => '选择目标车速后开始';

  @override
  String get performanceStateRunning => '计时中';

  @override
  String get performanceStateStaged => '已就绪 — 起步即开始计时';

  @override
  String get performanceSubhead => '由静止起步计时至目标车速';

  @override
  String get performanceTargetSpeedHeading => '目标车速';

  @override
  String get pidActionCancel => '取消';

  @override
  String get pidActionDelete => '删除';

  @override
  String get pidArrangeBody => '拖动调整顺序。仪表盘从左到右、从上到下排列，排在前面的会最先看到。';

  @override
  String get pidArrangeEmptyMessage => '先在清单中激活几项，再回来排列顺序。';

  @override
  String get pidArrangeEmptyTitle => '还没有激活任何 PID';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return '加入已确认的 $count 项';
  }

  @override
  String get pidBulkActionAllActive => '已全部激活';

  @override
  String get pidBulkActionIncomplete => '扫描数据不完整';

  @override
  String get pidBulkActionLocked => '录制中不能变更';

  @override
  String get pidBulkActionPending => '等待扫描结果';

  @override
  String get pidBulkActionZero => '没有已确认支持的 PID';

  @override
  String pidBulkAddCount(int count) {
    return '加入 $count 项';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return '加入 $count 项已确认支持 PID？';
  }

  @override
  String pidBulkAdded(int count) {
    return '已加入 $count 项已确认支持 PID。';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '仍有 $count 个支持区块未确认，这次只加入已有正面证据的项目。';
  }

  @override
  String pidBulkWillAdd(int count) {
    return '将加入 $count 项。激活越多 PID，单项数据的更新频率可能降低。';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '确认 $confirmed 项';
  }

  @override
  String get pidCapabilityCoverageNone => '尚未确定连续覆盖范围';

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return '连续覆盖 01–$through（已到末尾）';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return '连续覆盖 01–$through（后续未知）';
  }

  @override
  String get pidCapabilityPhaseAttemptFinished => '本次支持扫描已完成';

  @override
  String get pidCapabilityPhaseInterrupted => '支持扫描已中断';

  @override
  String get pidCapabilityPhaseNotStarted => '尚未开始扫描';

  @override
  String get pidCapabilityPhaseRunning => '正在确认车辆支持项目';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return '车辆支持 PID。$phase。确认 $confirmed 项。未知区块 $unknown 个。';
  }

  @override
  String get pidCapabilityTitle => '车辆支持 PID';

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '未知区块 $unknown';
  }

  @override
  String pidEditorCollision(String name) {
    return '已经有一个自定义 PID 使用这组设置（$name）。请改用不同的模式 + PID、标头或名称后缀。';
  }

  @override
  String pidEditorDeleteBody(String name) {
    return '「$name」的定义将被删除，仪表盘上的对应仪表也会消失，此操作无法撤销。';
  }

  @override
  String get pidEditorDeleteTitle => '删除这个 PID？';

  @override
  String get pidEditorDiscard => '放弃';

  @override
  String get pidEditorDiscardBody => '这个 PID 的修改还没有保存，离开后会遗失。';

  @override
  String get pidEditorDiscardTitle => '放弃未保存的变更？';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N 对应回应字节；可用 SIGNED()、ABS()、LOG10()、$valSyntax、BARO';
  }

  @override
  String get pidEditorFieldEquation => '表达式';

  @override
  String get pidEditorFieldHeader => 'CAN 标头';

  @override
  String get pidEditorFieldMax => '最大值';

  @override
  String get pidEditorFieldMin => '最小值';

  @override
  String get pidEditorFieldModeAndPid => '模式 + PID';

  @override
  String get pidEditorFieldName => '名称';

  @override
  String get pidEditorFieldSample => '测试用回应字节';

  @override
  String get pidEditorFieldShortName => '简称（显示在仪表上）';

  @override
  String get pidEditorFieldUnits => '单位';

  @override
  String get pidEditorHeaderHelper => '7E0 = 发动机';

  @override
  String get pidEditorKeepEditing => '继续编辑';

  @override
  String get pidEditorModeAndPidHelper => '例如 010C 或 221101';

  @override
  String get pidEditorSampleHelper => '输入十六进制，实时预览计算结果';

  @override
  String get pidEditorSave => '保存';

  @override
  String get pidEditorSectionFormula => '公式';

  @override
  String get pidEditorSectionIdentity => '识别';

  @override
  String get pidEditorSectionQuery => '查询';

  @override
  String get pidEditorSectionRangeAndPriority => '仪表量程与优先级';

  @override
  String get pidEditorTitleEdit => '编辑 PID';

  @override
  String get pidEditorTitleNew => '添加自定义 PID';

  @override
  String pidExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get pidExportNoCustomPids => '目前没有自定义 PID 可导出。';

  @override
  String get pidImportNothingToImport => '没有可导入的定义。';

  @override
  String pidImportLandedClean(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已导入 $count 项自定义 PID。',
    );
    return '$_temp0';
  }

  @override
  String pidImportLandedWithNotes(int count, String notes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '导入 $count 项，$notes。',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteSkippedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 行有问题已略过',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDefaultedRanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 行应用了默认量程',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项覆盖了现有定义',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDuplicatesInFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 行与文件内其他行重复已略过',
    );
    return '$_temp0';
  }

  @override
  String get pidImportPickerFailed => '未能打开文件选择器。';

  @override
  String get pidImportReadFailed => '读取文件失败。';

  @override
  String get pidListSeparator => '、';

  @override
  String get pidManagerActiveOnly => '只显示已激活';

  @override
  String get pidManagerAdd => '添加';

  @override
  String get pidManagerArrangeDashboard => '排列仪表盘';

  @override
  String pidManagerCounts(int active, int total) {
    return '已激活 $active 项 · 共 $total 项可用';
  }

  @override
  String get pidManagerExportCsv => '导出自定义 PID';

  @override
  String get pidManagerExportTorqueCsv => '导出 Torque 兼容 CSV';

  @override
  String get pidManagerExportHumanReport => '导出人类可读 PID 报表';

  @override
  String get pidManagerHeadline => 'PID 管理';

  @override
  String get pidManagerImportCsv => '导入 CSV';

  @override
  String get pidManagerMoreActions => '更多';

  @override
  String get pidManagerNoMatchMessage => '换个关键字，或创建一个自定义 PID。';

  @override
  String get pidManagerNoMatchTitle => '没有符合的 PID';

  @override
  String get pidManagerPowertrainBatteryCatalog => '大电池目录';

  @override
  String get pidManagerSearchHint => '搜索名称或 PID 代码…';

  @override
  String get pidPickCsvDialogTitle => '选择 PID 定义 CSV';

  @override
  String get pidPillCustom => '自定义';

  @override
  String get pidPillUnsupported => '不支持';

  @override
  String get pidPreviewCannotEvaluate => '不能计算';

  @override
  String get pidPreviewResultLabel => '计算结果';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '预览时以 $valueString 代入 $dependencies；实际数值会在连接后由该 PID 提供。';
  }

  @override
  String get pidPreviewTitle => '实时预览';

  @override
  String get pidPriorityHigh => '高';

  @override
  String get pidPriorityLow => '低';

  @override
  String get pidPriorityMedium => '中';

  @override
  String get pidPriorityVeryLow => '极低';

  @override
  String get pidRowEdit => '编辑';

  @override
  String pidRowShowOnDashboard(String name) {
    return '在仪表盘显示 $name';
  }

  @override
  String pidRowStaleUnits(String units) {
    return '$units · 已过期';
  }

  @override
  String powertrainAuthorizationGranted(String profile) {
    return '已激活 $profile 的电池信号（本次连接）';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return '无法启用：$reason';
  }

  @override
  String get powertrainCancel => '取消';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return '$profiles 个车型 · $probeable 个可单次读取';
  }

  @override
  String get powertrainCatalogLoadFailedBody => '完整性验证没有通过，因此没有显示或安装任何车型数据。';

  @override
  String get powertrainCatalogLoadFailedTitle => '离线目录未能加载';

  @override
  String get powertrainCatalogNotVerified => '目录尚未通过验证，不能安装。';

  @override
  String get powertrainCatalogRevalidate => '重新验证';

  @override
  String get powertrainCatalogScopeNote =>
      '目录很广，但「找到数据」不等于「支持你的车」。仅供研究的条目永远没有指令。Mode 22 实验条目可安装并轮询，但每个数值都标为未验证；Mode 21 实验条目每次确认后只读一次。';

  @override
  String get powertrainCatalogSearchHint => '搜索品牌、车型、版本或市场…';

  @override
  String get powertrainCatalogTitle => '大电池车型目录';

  @override
  String get powertrainChooseCommandNote => '每次只送一条，不扫描、不批量、不自动重试。';

  @override
  String get powertrainChooseCommandTitle => '选择一条固定只读查询';

  @override
  String get powertrainClose => '关闭';

  @override
  String get powertrainConfirmAccept => '就是这台车';

  @override
  String get powertrainConfirmBody =>
      '已安装的车型信号要先确认这台车就是该车型，本次连接才会开始读取。确认只对这次连接有效。';

  @override
  String get powertrainConfirmButton => '确认车辆';

  @override
  String get powertrainConfirmDialogBody =>
      '确认后，这个车型配置的只读电池查询会在本次连接内定期轮询。车型配置不符可能得到看似合理但错误的数字——不确定就取消。';

  @override
  String get powertrainConfirmDialogTitle => '确认连接中的车辆';

  @override
  String get powertrainConfirmTitle => '车辆电池信号待确认';

  @override
  String get powertrainConnectFirst => '请先连接；实验授权不会跨连接保留。';

  @override
  String get powertrainConnectionChanged => '连接已改变，请对新的连接重新确认车辆。';

  @override
  String get powertrainEnableLabInSettings => '请先到设置打开「大电池证据实验室」（实验功能）。';

  @override
  String get powertrainEvidencePhysicalVehicle => '项目实车';

  @override
  String get powertrainEvidenceSourceBacked => '来源数据';

  @override
  String get powertrainEvidenceSyntheticRig => '合成测试台';

  @override
  String get powertrainExperimentalDataDisclosure =>
      '这是来源作者标示的候选读取，不是原厂或跨车款安全保证；ELM327 只负责转送命令。原始指令与回复会留在本机诊断记录，不会由此功能自动上传；解码值不会安装成 PID 或加入仪表。取消不影响一般 OBD 功能。';

  @override
  String get powertrainExperimentalDialogTitle => '单次实验只读确认';

  @override
  String get powertrainExperimentalIdentityAck =>
      '我已核对来源已知的市场、车型与车型年份，并接受未证实字段';

  @override
  String get powertrainExperimentalParkedAck => '车辆已安全停妥；我知道这只读一次，数字仍可能不适用';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return '只接受 RX $responder，有效载荷长度 $bytes 字节';
  }

  @override
  String get powertrainFieldListSeparator => '、';

  @override
  String get powertrainFieldMarket => '市场';

  @override
  String get powertrainFieldModel => '车型';

  @override
  String get powertrainFieldModelYear => '车型年份';

  @override
  String get powertrainFieldVariant => '版本';

  @override
  String get powertrainFilterAll => '全部';

  @override
  String get powertrainIdentityEvidenceExact => '直接证据';

  @override
  String get powertrainIdentityEvidenceNone => '无';

  @override
  String get powertrainIdentityEvidenceSourcePartial => '部分证据';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return '来源身份证据：$fields\n未证实字段：$unconfirmed';
  }

  @override
  String get powertrainIdentityEvidenceUnknown => '未知';

  @override
  String get powertrainInstallButton => '安装电池信号';

  @override
  String get powertrainInstallConfirm => '安装';

  @override
  String get powertrainInstallDialogTitle => '安装车型电池信号';

  @override
  String get powertrainInstallDisclosureCommunity =>
      '安装只是把只读电池 PID 加进 PID 管理。开始读取前，每次连接都要在仪表盘确认「这台车就是这个车型」。数据来自社区来源并经独立比对，仍非原厂保证。';

  @override
  String get powertrainInstallDisclosureExperimental =>
      '安装只是把只读电池 PID 加进 PID 管理。开始读取前，每次连接都要在仪表盘确认「这台车就是这个车型」。这是实验解码，没有独立佐证要求，本车未验证，仍非原厂保证。';

  @override
  String get powertrainInstallDisclosureReady =>
      '安装只是把只读电池 PID 加进 PID 管理。开始读取前，每次连接都要在仪表盘确认「这台车就是这个车型」。来源数据较完整，仍非原厂保证。';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      '安装只是把只读电池 PID 加进 PID 管理。开始读取前，每次连接都要在仪表盘确认「这台车就是这个车型」。此条目仅供研究，不应安装。';

  @override
  String get powertrainInstallCatalogShaMissing =>
      '不能安装：这份目录快照没有已验证的 SHA-256，因此其中任何内容都不能信任。';

  @override
  String get powertrainInstallPersistFailed =>
      '无法安装：无法保存已安装车型配置列表。请再试一次；PID 管理没有添加任何项目。';

  @override
  String get powertrainInstallProfileNotInCatalog => '无法安装：此车型配置不在已验证的目录中。';

  @override
  String get powertrainInstallProfileNotInstallable =>
      '无法安装：此车型配置的状态不允许将其转为实时 PID。';

  @override
  String get powertrainInstallYearOutOfRange => '无法安装：该车型年份不在此车型配置记载的年份范围内。';

  @override
  String get powertrainInstallIdentityAck => '我的车辆符合上述市场、车型与车型年份';

  @override
  String get powertrainInstalledRemoveButton => '已安装 · 移除信号';

  @override
  String powertrainInstalledSignalsSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已安装 $count 个信号。到 PID 页面加入仪表盘；每次连接需确认车辆。',
    );
    return '$_temp0';
  }

  @override
  String get powertrainNoMatchBody => '改用品牌、车型名称，或切换其他动力型式。';

  @override
  String get powertrainNoMatchTitle => '没有符合的车型';

  @override
  String get powertrainNotInstallableInThisRelease => '此版本不可安装';

  @override
  String powertrainPrimarySource(String name, String license) {
    return '主要来源：$name（$license）';
  }

  @override
  String get powertrainProbeChecksPassed => '已通过响应方、回显、精确长度、公式与范围检查。';

  @override
  String get powertrainProbeConnectForOneShot => '连接后单次只读';

  @override
  String get powertrainProbeConnectToTryOnce => '连接后可先单次试读';

  @override
  String get powertrainProbeDidNotFinish => '单次查询没有完成；没有发布或保留数值。';

  @override
  String get powertrainProbeEnableLabFirst => '先在设置打开实验室';

  @override
  String get powertrainProbeInProgress => '单次查询中…';

  @override
  String get powertrainProbeNoValuePublished => '没有发布数值；结构或解码错误会隔离到重新连接。';

  @override
  String get powertrainProbeOnceButton => '只读这一次';

  @override
  String get powertrainProbePassedTitle => '单次查询通过';

  @override
  String get powertrainProbePickOneRead => '选一条，只读一次';

  @override
  String get powertrainProbeReconnectFirst => '重新连接后再试';

  @override
  String get powertrainProbeRefusedTitle => '单次查询已拒绝';

  @override
  String get powertrainProbeTryOnceFirst => '先试读一次';

  @override
  String get powertrainProfileNotVerified => '车型配置不在已验证目录中';

  @override
  String get powertrainQuarantinedPill => '本次隔离 · 请重连';

  @override
  String get powertrainRefusedCatalogHashInvalid =>
      '未授权：目录的完整性哈希无效，因此其中任何内容都不能读取。';

  @override
  String get powertrainRefusedCommandNotInProfile => '未授权：这个指令不属于此已验证车型配置的指令。';

  @override
  String get powertrainRefusedLabClosed => '在这次读取取得授权之前，大电池证据实验室已被关闭。';

  @override
  String get powertrainRefusedProfileFailedValidation =>
      '未授权：此车型配置未通过所选车型年份的目录验证。';

  @override
  String get powertrainRefusedProfileNotInCatalog => '未授权：此车型配置不在已验证的目录中。';

  @override
  String get powertrainRefusedProfileNotProbeable => '未授权：此车型配置不允许进行单次实验读取。';

  @override
  String get powertrainRefusedQuarantinedAfterRejectedRead =>
      '本次连接已隔离：先前一次单次读取没有通过结构检查。请重新连接后再试。';

  @override
  String get powertrainRefusedNotConnectedOrNotInForeground =>
      '这次单次读取没有开始：目前没有连接，或 App 不在前景。';

  @override
  String get powertrainRefusedNoLiveAuthorization =>
      '这次单次读取没有开始：目前没有持有单次授权。授权不存在、已过期、冷却中或已被隔离。';

  @override
  String get powertrainRefusedDiscardedAtLifecycleBoundary =>
      '单次读取进行中，连接或前景状态改变了，因此它的结果被丢弃而没有显示。没有任何失败，也没有保留任何结果。';

  @override
  String powertrainRefusedQuarantinedAtAttemptCap(int attemptCap) {
    return '本次连接已隔离：同一个指令已经尝试 $attemptCap 次。请重新连接后再试。';
  }

  @override
  String get powertrainResearchOnlyNeverQueries => '仅供研究，不会查询';

  @override
  String get powertrainRestoreStorageErrorRetry => '还原先前安装时发生保存错误，已重新调度，请再试一次。';

  @override
  String powertrainSecondarySource(String name, String license) {
    return '独立佐证：$name（$license）';
  }

  @override
  String powertrainSignalCount(int count) {
    return '$count 个信号';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return '源文件 SHA-256：$hash…';
  }

  @override
  String get powertrainStatusCommunity => '社区数据 · 未验证';

  @override
  String get powertrainStatusExperimental => '实验 · 未验证';

  @override
  String get powertrainStatusExperimentalProbeOnly => '实验单次只读';

  @override
  String get powertrainStatusReady => '来源较完整';

  @override
  String get powertrainStatusResearchOnly => '仅研究';

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return '已移除 $name 的已安装信号。';
  }

  @override
  String powertrainVehicleYearFixed(int year) {
    return '车辆车型年份：$year';
  }

  @override
  String get powertrainVehicleYearLabel => '车辆车型年份';

  @override
  String get recommendedPurchaseDisclosure =>
      '这是维护者的推广分成链接；符合条件的购买可能为维护者带来佣金。这不是适配器认证或购买保证。商品页面内容与硬件版本可能变更，购买前请核对完整型号与 NCC 号码。你也可以自行寻找其他卖家。';

  @override
  String get recommendedPurchaseHeading => '推荐适配器';

  @override
  String recommendedPurchaseModelLine(String model, String approval) {
    return '型号 $model · NCC $approval';
  }

  @override
  String recommendedPurchaseNoAdapterYet(String store) {
    return '还没有适配器？在$store看推荐款';
  }

  @override
  String recommendedPurchaseOpenFailed(String store) {
    return '未能打开$store链接';
  }

  @override
  String get recommendedPurchaseShortDisclosureAction => '完整说明在设置';

  @override
  String get recommendedPurchaseShortDisclosureLead => '这是推广分成链接，不是适配器认证。';

  @override
  String get recommendedPurchaseStoreShopee => 'Shopee';

  @override
  String recommendedPurchaseViewOnStore(String store) {
    return '在$store查看';
  }

  @override
  String get semanticsFieldSeparator => '，';

  @override
  String get settingsAdapterConcernsFooter =>
      '这些是适配器自述中不一致之处，并非它读错车辆数据的证据。要确认数值，唯一方法是进行第二次独立测量（见实车指南）。';

  @override
  String get settingsAdapterNoContradictions =>
      '没有发现自述矛盾。这只表示它对自己的描述前后一致 —— 既不代表它是原厂芯片，也不代表它回报的数值正确。版本号在仿制品上就是一段可以任意填的文本。';

  @override
  String get settingsAdapterNoVersion => '（未回报版本）';

  @override
  String get settingsAdapterSelfReportTitle => '适配器自述';

  @override
  String get settingsBatteryLabDialogBody =>
      '这些是逆向工程来源的候选数据，不是原厂文档，也不代表 Telltale 支持你的车辆。即使是只读查询也可能唤醒控制器；解码后的数字可能看似合理，但仍可能不适用。';

  @override
  String get settingsBatteryLabDialogTitle => '打开大电池证据实验室';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      '本次运行已关闭大电池实验功能，但未能保存设置；下次启动可能再显示实验入口，每条查询仍需单独确认。';

  @override
  String get settingsBatteryLabEnableNotSaved => '未能保存大电池实验功能设置，功能维持关闭。';

  @override
  String get settingsBatteryLabEvidenceAck => '我知道来源数据与合成测试不能证明我的实车适用';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      '只显示来源完整、受哈希约束的单次只读查询。不会安装 PID、轮询、加入仪表或把研究数据当成支持。';

  @override
  String get settingsBatteryLabSwitchTitle => '大电池证据实验室（实验）';

  @override
  String get settingsBatteryLabUnlockReadOnly => '只解锁单次只读查询';

  @override
  String get settingsBatteryLabWireAck =>
      '我知道只会解锁目录内固定 Mode 21/22 地址的单次查询；不会解锁扫描、诊断会话、安全访问、写入或控制';

  @override
  String get settingsCancel => '取消';

  @override
  String get settingsCatalogChoose => '从官方目录选择';

  @override
  String get settingsCatalogCorrupt => '官方离线目录损坏或未能加载，没有应用任何数据。';

  @override
  String get settingsCatalogNothingApplicable =>
      '这笔官方配置没有可安全应用到目前公式的字段，原设置保持不变。';

  @override
  String get settingsCatalogScope =>
      '官方目录：美国 EPA、台湾经济部能源署、加拿大 NRCan。各快照只代表该市场，不是全球所有品牌或车型年份。';

  @override
  String get settingsCatalogVerifying => '验证离线目录中…';

  @override
  String get settingsCatalogChooseMarket => '选择要浏览的官方目录';

  @override
  String get settingsCatalogMarketTw => '台湾（经济部能源署）';

  @override
  String get settingsCatalogMarketUs => '美国（EPA）';

  @override
  String get settingsTwCertificationYear => '核发年份';

  @override
  String get settingsTwMake => '台湾厂牌';

  @override
  String settingsTwPickerScope(int firstYear, int lastYear) {
    return '仅含 $firstYear–$lastYear 年的台湾市场认证条目。年份是能源署认证的公历年份，不是美国车型年份。品牌和车型名称相同也不等于 EPA 配置。';
  }

  @override
  String get settingsTwPickerTitle => '台湾官方车辆目录';

  @override
  String get settingsTwReferenceMassNotCurb => '参考车重不是 curb mass，不会应用。';

  @override
  String settingsTwWillApplyOnly(String fields) {
    return '只会应用：$fields。参考车重、VE、Cd、正面面积、Crr 与传动效率仍保持未解析。';
  }

  @override
  String get settingsClose => '关闭';

  @override
  String get settingsConnectionSection => '连接';

  @override
  String get settingsDiagnosticsSection => '诊断记录';

  @override
  String get settingsDisconnect => '中断连接';

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return '传动效率 $percent %';
  }

  @override
  String settingsEpaApplyFields(int count) {
    return '应用 $count 个官方字段';
  }

  @override
  String get settingsEpaChooseExact => '选择一个精确配置';

  @override
  String get settingsEpaCloseNoFields => '关闭（没有可应用字段）';

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'EPA 配置 $epaId';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count 缸';
  }

  @override
  String get settingsEpaDriveUnknown => '驱动未知';

  @override
  String get settingsEpaFuelUnknown => '燃料未知';

  @override
  String get settingsEpaMake => 'EPA make（制造商部门）';

  @override
  String get settingsEpaModel => '车型';

  @override
  String get settingsEpaNoConfigurations => '这个车型没有可用配置';

  @override
  String get settingsEpaNoSafeFields => '此配置没有能安全应用到目前公式的字段；不会猜测。';

  @override
  String get settingsEpaPickInOrder => '依次选择车型年份、品牌与车型';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return '仅限美国市场 $firstYear–$lastYear 的快照配置。同名车型仍需通过车型年份、变速箱、燃料与 EPA ID 加以区分。';
  }

  @override
  String get settingsEpaPickerTitle => '美国 EPA 官方车型目录';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return '只会应用：$fields。车重、VE、Cd、正面面积、Crr 与传动效率仍保持未解析。';
  }

  @override
  String get settingsEpaYear => '车型年份';

  @override
  String get settingsExperimentalSection => '实验功能';

  @override
  String get settingsFieldDisplacement => '排气量';

  @override
  String get settingsFieldDragCoefficient => '风阻系数 Cd';

  @override
  String get settingsFieldDrivetrain => '驱动方式';

  @override
  String get settingsFieldFrontalArea => '正面投影面积';

  @override
  String get settingsFieldFuel => '燃料';

  @override
  String get settingsFieldMass => '车重';

  @override
  String get settingsFieldMassWithDriver => '车重（含驾驶）';

  @override
  String get settingsFieldRollingResistance => '滚动阻力系数 Crr';

  @override
  String get settingsFieldVolumetricEfficiency => '容积效率 VE';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return '空燃比 $afr · 密度 $density g/L';
  }

  @override
  String get settingsFuelAndDrivetrainSection => '燃料与驱动';

  @override
  String get settingsFuelTypeLabel => '燃料种类';

  @override
  String get settingsGaugeSkinBody =>
      '不只是换颜色 —— 每一种的刻度盘形状、指针、动态都不一样。深色与浅色底下都可以用。';

  @override
  String get settingsGaugeSkinTitle => '仪表样式';

  @override
  String get settingsGoToConnect => '前往连接';

  @override
  String get settingsHeadline => '设置';

  @override
  String get settingsLicenseLegalese => '大电池数据的来源、转换方式与重用条款都随本 App 一并附上。';

  @override
  String get settingsListSeparator => '、';

  @override
  String get settingsManualCommandBody =>
      '直接送一条指令给适配器，例如 ATI、ATDPN、0100。会排在一般轮询的同一条队列上，不会插队。';

  @override
  String get settingsManualCommandFieldLabel => '指令';

  @override
  String get settingsManualCommandNoContent => '（没有回应内容）';

  @override
  String get settingsManualCommandSend => '送出';

  @override
  String get settingsManualCommandTitle => '手动指令';

  @override
  String get settingsNotConnected => '未连接';

  @override
  String get settingsOpenSourceLicenses => '开源软件和数据许可';

  @override
  String get settingsProfileConfirmAfterConnect => '连接后确认此车数据';

  @override
  String get settingsProfileConfirmButton => '确认本次连接车辆数据';

  @override
  String get settingsProfileConfirmedButton => '本次连接数据已确认';

  @override
  String get settingsProfileConfirmedDetail => '已确认本次连接的设置。修改任一项或重新连接后都要再确认。';

  @override
  String get settingsProfileEstimatesIntro =>
      '马力、扭矩与油耗都是由这些参数推算出来的，填得越接近实车，推算值才越有意义。';

  @override
  String get settingsProfileNameProvesNothing =>
      '品牌名称或 VIN 本身都不能证明重量、风阻、VE 与传动效率。';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      '本次连接尚未确认。仍会显示 OBD 实测数据，但不显示根据车重、VE 与风阻推算的数值。';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      '请先连接此车辆再确认。每次重新连接都会使确认失效，因此上一辆车的配置绝不会应用于下一辆车。';

  @override
  String get settingsProvenanceNoneExact =>
      '目前没有字段已精确解析到这次车辆；通用值、手动值或旧来源值仍须确认。';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return '目前只有$fields有官方精确来源；其他字段仍须逐项确认。';
  }

  @override
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  ) {
    return '来源：官方／原厂 $official / $total 栏 · 手动 $user / $total 栏 · 通用 $generic / $total 栏 · 科学模型 $scientific / $total 栏';
  }

  @override
  String settingsProvenancePublishers(String publishers) {
    return '来源：$publishers';
  }

  @override
  String settingsProvenanceResolution(
    int exact,
    int sessionConfirmed,
    int unresolved,
    int ambiguous,
    int conflict,
    int total,
  ) {
    return '解析：官方精确 $exact / $total 栏 · 本次确认 $sessionConfirmed / $total 栏 · 未解析 $unresolved / $total 栏 · 歧义 $ambiguous / $total 栏 · 冲突 $conflict / $total 栏';
  }

  @override
  String get settingsStandardsFooter =>
      '本 App 的 OBD2 实现依据 SAE J1979 与 ELM327 数据手册 等公开标准；每一条影响硬件行为的公式与 AT 指令都经过交叉验证，结果记录于 docs/protocol-deviations.zh-TW.md。本 App 与 Torque / Torque Pro 无关联。';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsVehicleProfileSection => '车辆配置';

  @override
  String get settingsVinConflict => 'VIN 冲突';

  @override
  String get settingsVinConflictDetail => '不同控制器回报不同 VIN，未能确认车辆身份；所有候选都已丢弃。';

  @override
  String get settingsVinNotRead => 'VIN 尚未读取';

  @override
  String get settingsVinNotReadConnectedDetail =>
      '可向目前车辆读取 Mode 09 VIN；身份状态只保留在这次连接中。原始诊断记录仍可能包含 VIN。';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      '连接后可读取目前车辆自报的 VIN；身份状态不会带到下一次连接。原始诊断记录仍可能包含 VIN。';

  @override
  String get settingsVinRead => '读取 VIN';

  @override
  String get settingsVinReading => '读取中…';

  @override
  String get settingsVinReportedDetail =>
      'VIN 是车辆自报身份，不代表车型规格已验证。身份状态不跨连接；诊断记录仍可能包含 VIN。';

  @override
  String get settingsVinSimulatorReported => '模拟器回报 VIN';

  @override
  String get settingsVinUnavailable => '无法获取 VIN';

  @override
  String get settingsVinUnavailableDetail => '可能是车辆未提供、回复不完整或这次连接没有读到；不会猜测或补字。';

  @override
  String get settingsVinVehicleReported => '车辆回报 VIN';

  @override
  String get startupCannotComplete => '目前未能完成启动检查';

  @override
  String get startupChecking => '正在检查本机分享暂存与遥测记录';

  @override
  String get startupRestartHint =>
      '本地分享缓存或遥测记录的状态无法确认。为避免覆盖、删除或分享错误文件，请完全退出后重新打开 Telltale。';

  @override
  String get startupRestartRequired => '需要重新启动才能安全继续';

  @override
  String get startupRetry => '重试';

  @override
  String get startupRetryHint =>
      '请让 Telltale 保持在前景，并在其他文件作业完成后重试。启动完成前不会开放记录、回放、导出或删除。';

  @override
  String get telemetryArtifactRestartRequired =>
      '本机文件作业状态未能确认；请完全关闭并重新打开 Telltale 后再操作';

  @override
  String get telemetryBlockedByRecorder => '请先停止并保存';

  @override
  String get telemetryCancel => '取消';

  @override
  String get telemetryDamagedCollision => '同一标识符对应已完成和未完成的文件，未选择任何一份';

  @override
  String get telemetryDamagedCorrupt => '记录损坏，无法安全读取';

  @override
  String telemetryDamagedFileTime(String time) {
    return '文件时间 $time';
  }

  @override
  String get telemetryDelete => '删除';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return '将删除 $id（文件时间 $time）。删除后不能复原。';
  }

  @override
  String get telemetryDeleteDamagedTitle => '删除损坏记录？';

  @override
  String get telemetryDeleteDamagedTooltip => '删除损坏记录';

  @override
  String telemetryDeleteFailed(String reason) {
    return '删除未完成：$reason';
  }

  @override
  String get telemetryDeleteNeedsConfirmation => '请先确认这个删除操作';

  @override
  String telemetryDeleteSessionBody(String time) {
    return '将删除 $time 的记录。此操作不能复原。';
  }

  @override
  String get telemetryDeleteSessionTitle => '删除本机记录？';

  @override
  String get telemetryDemoData => '内置模拟数据';

  @override
  String get telemetryDismissNotice => '关闭提示';

  @override
  String get telemetryEndedByBackground => 'Telltale 进入后台后已停止';

  @override
  String get telemetryEndedByConfigurationChanged => 'PID 设置已变更';

  @override
  String get telemetryEndedByDisconnect => '连接中断后已停止';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return '已达 $minutes 分钟上限';
  }

  @override
  String get telemetryEndedByLibrarySizeLimit => '本机记录空间已满';

  @override
  String get telemetryEndedByRecoveredAfterInterruption => '上次中断后已复原';

  @override
  String get telemetryEndedBySessionReplacement => '连接会话已更换';

  @override
  String get telemetryEndedBySessionSizeLimit => '已达单笔记录容量上限';

  @override
  String get telemetryEndedByStorageBackpressure => '保存速度不足';

  @override
  String get telemetryEndedByStorageFailure => '保存失败';

  @override
  String get telemetryEndedByUser => '已手动停止';

  @override
  String get telemetryExport => '导出';

  @override
  String get telemetryExportCsv => '导出 CSV';

  @override
  String telemetryExportFailed(String reason) {
    return '导出未完成：$reason';
  }

  @override
  String get telemetryExportJson => '导出 JSON';

  @override
  String get telemetryExportSheetTitle => '导出本机记录';

  @override
  String telemetryGapCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个缺口',
    );
    return '$_temp0';
  }

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已保存 $count 组，可离线回放与导出',
    );
    return '$_temp0';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit 组';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '另有 $count 组未显示',
    );
    return '$_temp0';
  }

  @override
  String telemetryLibraryQuotaSemantics(
    int groups,
    int groupLimit,
    String used,
    int byteLimit,
  ) {
    return '本机保存 $groups / $groupLimit 组，$used / $byteLimit MiB';
  }

  @override
  String get telemetryNotConnected => '目前未连接';

  @override
  String get telemetryOfflineSampledReplay => '离线抽样回放';

  @override
  String get telemetryOpenHistory => '查看本机记录';

  @override
  String get telemetryPause => '暂停';

  @override
  String get telemetryPendingOwnerRecovery =>
      '作业仍由目前进程持有；若持续停在此状态，请完全关闭并重新打开 Telltale';

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first，$second';
  }

  @override
  String get telemetryPlay => '播放';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return '只记录已启用的 OBD 信号，不含位置、VIN 或账号数据。趋势图最多显示 $laneLimit 项信号；录制会保留全部 $activeCount 项已启用信号，并加入依赖车辆假设的估算马力与估算油耗。';
  }

  @override
  String get telemetryRecorderPhaseAwaitingValues => '录制中，尚无数值';

  @override
  String get telemetryRecorderPhaseCompleted => '记录已保存';

  @override
  String get telemetryRecorderPhaseFailed => '记录保存失败';

  @override
  String get telemetryRecorderPhaseFinalizing => '正在保存记录';

  @override
  String get telemetryRecorderPhaseIdle => '前景本机记录';

  @override
  String get telemetryRecorderPhasePreparing => '正在准备录制';

  @override
  String get telemetryRecorderPhaseRecording => '记录中';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return '录制中 $duration';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个没有有效值的未完成文件已清理',
    );
    return '$_temp0';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个损坏或冲突文件保持原样',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryDamagedNote => '损坏内容不会用于回放或导出，只能在安全状态下手动删除。';

  @override
  String telemetryRecoveryInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 组中断记录已完成安全封存',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryTitle => '启动记录检查已完成';

  @override
  String get telemetryReload => '重新加载';

  @override
  String telemetryReplayBreakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个中断',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayLoadFailed => '未能加载记录';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return '回放位置 $percent%';
  }

  @override
  String telemetryReplaySampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个抽样节点',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayTitle => '记录回放';

  @override
  String get telemetryReplayUnreadable => '记录损坏或未能读取';

  @override
  String get telemetryRestartToRepairSave => '保存作业未完成；请重新启动 Telltale 以修复记录';

  @override
  String get telemetryRestartToRepairStartup => '启动清理未完成；请重新启动 Telltale 以修复记录';

  @override
  String get telemetryReturnToTrends => '返回趋势';

  @override
  String get telemetryRigData => '测试台架数据';

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first。$second';
  }

  @override
  String get telemetrySessionsDamaged => '损坏的记录文件';

  @override
  String get telemetrySessionsEmpty => '还没有本机记录\n连接后开始录制';

  @override
  String get telemetrySessionsLoadFailed => '未能加载，请重试';

  @override
  String get telemetrySessionsReplayable => '可回放的记录';

  @override
  String get telemetrySessionsTitle => '本机记录';

  @override
  String telemetrySignalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项信号',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStartBusy => '另一个记录或文件作业尚未完成';

  @override
  String get telemetryStartCannotCreateFile => '无法创建记录文件';

  @override
  String get telemetryStartInvalidConfiguration => '所选 PID 无法安全记录，请检查定义';

  @override
  String get telemetryStartInvalidatedBackground => 'Telltale 已进入后台，未开始记录';

  @override
  String get telemetryStartInvalidatedDisconnect => '连接已中断，未开始记录';

  @override
  String get telemetryStartInvalidatedSessionReplacement => '连接会话已更换，未开始记录';

  @override
  String get telemetryStartLibraryByteLimit => '本机记录空间不足，请先导出或删除';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return '本机记录已达 $limit 组上限，请先导出或删除';
  }

  @override
  String get telemetryStartMoving => '请停车后操作';

  @override
  String get telemetryStartNeedsActivePid => '请先激活至少一项 PID';

  @override
  String get telemetryStartNeedsConnection => '请先连接再开始记录';

  @override
  String get telemetryStartNeedsForeground => '请将 Telltale 切回前台再开始记录';

  @override
  String get telemetryStartRecording => '已开始记录';

  @override
  String get telemetryStartRecordingButton => '开始记录';

  @override
  String get telemetryStartSpeedUnknown => '无法确认车辆已停止；请先断开连接';

  @override
  String get telemetryStartTooManyPids => '录制会保留估算功率与估算油耗字段，请先停用部分 PID';

  @override
  String get telemetryStarting => '正在开始';

  @override
  String get telemetryStatusBusError => '总线错误';

  @override
  String telemetryStatusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个状态',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStatusFormulaError => '公式错误';

  @override
  String get telemetryStatusHeaderMismatch => '标头不符目前总线';

  @override
  String get telemetryStatusNoAnswer => '无回应，稍后重试';

  @override
  String get telemetryStatusStale => '数据已过期';

  @override
  String get telemetryStatusUnsafeServiceRefusal => '不是只读查询，未发送任何内容';

  @override
  String get telemetryStatusUnsupported => '控制器回复不支持此项';

  @override
  String get telemetryStopAndSave => '停止并保存';

  @override
  String telemetryValueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔有效值',
    );
    return '$_temp0';
  }

  @override
  String get transcriptDelete => '删除';

  @override
  String get transcriptDeleteBusy => '另一个文件作业尚未完成。';

  @override
  String get transcriptDeleteFailed => '未能删除上一次连接的记录。';

  @override
  String get transcriptDeleteRefusedBySafety => '目前车速或连接状态不允许删除记录。';

  @override
  String get transcriptExport => '导出';

  @override
  String get transcriptExportButton => '导出记录';

  @override
  String get transcriptExportExplanation =>
      '这次连接会保留开头握手与最新的原始往返数据；长时间连接若省略中段，文件会明确标出。在车上遇到读不到、判断不出来的情况时，把记录导出带回来，比画面上的一句信息有用得多。';

  @override
  String transcriptExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get transcriptExportWithHex => '含十六进制';

  @override
  String get transcriptNothingToExport => '没有可导出的记录。';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return '$timestamp 留下的，$size。系统关掉 Telltale 或手机没电时，记录还是留下来了。';
  }

  @override
  String get transcriptRecoveredChanged => '上一次连接的记录已更新，请再确认。';

  @override
  String get transcriptRecoveredTitle => '上一次连接的记录';

  @override
  String transcriptSizeBytes(int bytes) {
    String _temp0 = intl.Intl.pluralLogic(
      bytes,
      locale: localeName,
      other: '$bytes 字节',
    );
    return '$_temp0';
  }

  @override
  String get trendAxisNow => '现在';

  @override
  String get trendChooseSignals => '选择信号';

  @override
  String get trendLiveData => '实时数据';

  @override
  String get trendNoSignalsBody => '先到 PID 页面激活想要监看的信号。';

  @override
  String get trendNoSignalsTitle => '没有可用的趋势信号';

  @override
  String get trendNoUnits => '无单位';

  @override
  String trendPickSignalsBody(int limit) {
    return '最多可以比较 $limit 项信号，不会改变哪些 PID 被轮询。';
  }

  @override
  String get trendPickSignalsTitle => '选择趋势信号';

  @override
  String trendRemoveSignal(String name) {
    return '移除 $name';
  }

  @override
  String get trendSelectionSaveFailed => '未能保存趋势显示选择';

  @override
  String trendSheetBody(int limit) {
    return '最多选择 $limit 项。这只会改变图表，不会改变 PID 轮询或正在进行的记录。';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return '完成 · $selected/$limit';
  }

  @override
  String get trendSignalNoLongerActive => '其中一项信号已不在 PID 监看清单';

  @override
  String get trendSignalsHeading => '趋势信号';

  @override
  String trendTooManySelected(int limit) {
    return '最多选择 $limit 项';
  }

  @override
  String trendWindowSemantics(int seconds) {
    return '显示最近 $seconds 秒趋势';
  }

  @override
  String get wearBack => '返回';

  @override
  String get wearBatteryVoltageLabel => '电瓶';

  @override
  String get wearBleAdapters => 'BLE 适配器';

  @override
  String get wearCancel => '取消';

  @override
  String get wearConfirmVehicle => '确认车辆';

  @override
  String get wearConfirmVehicleAccept => '就是这台车';

  @override
  String get wearConfirmVehicleBody =>
      '确认后，这个车型的只读电池查询会在本次连接内定期轮询。车型不符可能得到看似合理但错误的数字——不确定就取消。';

  @override
  String wearConnectFailed(String adapter) {
    return '连接失败：$adapter';
  }

  @override
  String get wearConnecting => '连接中…';

  @override
  String get wearDemoSimulator => 'Demo 模拟器';

  @override
  String get wearDisconnect => '中断';

  @override
  String get wearDisconnectQuestion => '中断连接？';

  @override
  String get wearNoDevicesFound => '没有找到设备';

  @override
  String get wearPermissionBluetooth => '蓝牙';

  @override
  String get wearPermissionLocation => '位置';

  @override
  String get wearScanAgain => '重新扫描';

  @override
  String get wearScanFailed => '扫描失败，请再试一次';

  @override
  String wearScanPermissionNeeded(String permission) {
    return '需要$permission权限才能扫描';
  }

  @override
  String wearScanPermissionPermanentlyDenied(String permission) {
    return '$permission权限已被永久拒绝，请到系统设置打开后再试';
  }

  @override
  String get wearScanning => '扫描中…';

  @override
  String get telemetryRecorderNotRecording => '未录制';

  @override
  String get dtcKindStored => '已保存';

  @override
  String get dtcKindPending => '待确认';

  @override
  String get dtcKindPermanent => '永久';

  @override
  String get dtcKindStoredExplanation => '已确认的故障，仪表盘故障灯一般亮起';

  @override
  String get dtcKindPendingExplanation => '检测到一次，尚未达到确认门槛';

  @override
  String get dtcKindPermanentExplanation => '无法用诊断仪清除。只有 ECU 确认修复后，才会自行清除此故障码。';

  @override
  String get dtcSystemPowertrain => '动力系统';

  @override
  String get dtcSystemChassis => '底盘';

  @override
  String get dtcSystemBody => '车身';

  @override
  String get dtcSystemNetwork => '网络';

  @override
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions =>
      '燃油与空气计量、辅助排放控制';

  @override
  String get dtcSubsystemFuelAirMetering => '燃油与空气计量';

  @override
  String get dtcSubsystemFuelAirMeteringInjectorCircuit => '燃油与空气计量（喷油嘴回路）';

  @override
  String get dtcSubsystemIgnitionOrMisfire => '点火系统或失火';

  @override
  String get dtcSubsystemAuxiliaryEmissionControls => '辅助排放控制';

  @override
  String get dtcSubsystemSpeedAndIdleControl => '车速控制与怠速系统';

  @override
  String get dtcSubsystemComputerOutputCircuit => '电脑输出回路';

  @override
  String get dtcSubsystemTransmission => '变速箱';

  @override
  String get dtcSubsystemControlModuleSignals => '控制模块输入／输出信号';

  @override
  String get dtcDescriptionB0001 => '驾驶员安全气囊展开控制故障';

  @override
  String get dtcDescriptionP0011 => '凸轮轴位置 A — 正时过度提前或系统性能问题（第 1 缸组）';

  @override
  String get dtcDescriptionP0014 => '凸轮轴位置 B — 正时过度提前或系统性能问题（第 1 缸组）';

  @override
  String get dtcDescriptionP0016 => '曲轴位置与凸轮轴位置相关性（第 1 缸组传感器 A）';

  @override
  String get dtcDescriptionP0087 => '燃油轨／系统压力过低';

  @override
  String get dtcDescriptionP0088 => '燃油轨／系统压力过高';

  @override
  String get dtcDescriptionP0100 => '空气流量传感器 (MAF) 电路故障';

  @override
  String get dtcDescriptionP0101 => '空气流量传感器范围/性能问题';

  @override
  String get dtcDescriptionP0102 => '空气流量传感器电路输入过低';

  @override
  String get dtcDescriptionP0103 => '空气流量传感器电路输入过高';

  @override
  String get dtcDescriptionP0105 => '进气歧管绝对压力／大气压力传感器电路故障';

  @override
  String get dtcDescriptionP0106 => '进气歧管绝对压力传感器范围/性能问题';

  @override
  String get dtcDescriptionP0107 => '进气歧管绝对压力传感器电路输入过低';

  @override
  String get dtcDescriptionP0108 => '进气歧管绝对压力传感器电路输入过高';

  @override
  String get dtcDescriptionP0110 => '进气温度传感器电路故障';

  @override
  String get dtcDescriptionP0111 => '进气温度传感器范围/性能问题';

  @override
  String get dtcDescriptionP0112 => '进气温度传感器电路输入过低';

  @override
  String get dtcDescriptionP0113 => '进气温度传感器电路输入过高';

  @override
  String get dtcDescriptionP0115 => '冷却液温度传感器电路故障';

  @override
  String get dtcDescriptionP0116 => '冷却液温度传感器范围/性能问题';

  @override
  String get dtcDescriptionP0117 => '冷却液温度传感器电路输入过低';

  @override
  String get dtcDescriptionP0118 => '冷却液温度传感器电路输入过高';

  @override
  String get dtcDescriptionP0120 => '节气门位置传感器电路故障';

  @override
  String get dtcDescriptionP0121 => '节气门位置传感器范围/性能问题';

  @override
  String get dtcDescriptionP0122 => '节气门位置传感器电路输入过低';

  @override
  String get dtcDescriptionP0123 => '节气门位置传感器电路输入过高';

  @override
  String get dtcDescriptionP0125 => '冷却液温度不足以进行闭环燃油控制';

  @override
  String get dtcDescriptionP0128 => '冷却液温度低于节温器调节温度';

  @override
  String get dtcDescriptionP0130 => '氧传感器电路故障 (第 1 缸组 传感器 1)';

  @override
  String get dtcDescriptionP0131 => '氧传感器电路电压过低 (第 1 缸组 传感器 1)';

  @override
  String get dtcDescriptionP0132 => '氧传感器电路电压过高 (第 1 缸组 传感器 1)';

  @override
  String get dtcDescriptionP0133 => '氧传感器电路响应过慢（第 1 缸组，传感器 1）';

  @override
  String get dtcDescriptionP0134 => '氧传感器电路未检测到活动（第 1 缸组，传感器 1）';

  @override
  String get dtcDescriptionP0135 => '氧传感器加热器电路故障 (第 1 缸组 传感器 1)';

  @override
  String get dtcDescriptionP0136 => '氧传感器电路故障 (第 1 缸组 传感器 2)';

  @override
  String get dtcDescriptionP0137 => '氧传感器电路电压过低 (第 1 缸组 传感器 2)';

  @override
  String get dtcDescriptionP0138 => '氧传感器电路电压过高 (第 1 缸组 传感器 2)';

  @override
  String get dtcDescriptionP0140 => '氧传感器电路未检测到活动（第 1 缸组，传感器 2）';

  @override
  String get dtcDescriptionP0141 => '氧传感器加热器电路故障 (第 1 缸组 传感器 2)';

  @override
  String get dtcDescriptionP0150 => '氧传感器电路故障 (第 2 缸组 传感器 1)';

  @override
  String get dtcDescriptionP0155 => '氧传感器加热器电路故障 (第 2 缸组 传感器 1)';

  @override
  String get dtcDescriptionP0156 => '氧传感器电路故障 (第 2 缸组 传感器 2)';

  @override
  String get dtcDescriptionP0161 => '氧传感器加热器电路故障 (第 2 缸组 传感器 2)';

  @override
  String get dtcDescriptionP0170 => '燃油修正故障 (第 1 缸组)';

  @override
  String get dtcDescriptionP0171 => '混合比过稀 (第 1 缸组)';

  @override
  String get dtcDescriptionP0172 => '混合比过浓 (第 1 缸组)';

  @override
  String get dtcDescriptionP0173 => '燃油修正故障 (第 2 缸组)';

  @override
  String get dtcDescriptionP0174 => '混合比过稀 (第 2 缸组)';

  @override
  String get dtcDescriptionP0175 => '混合比过浓 (第 2 缸组)';

  @override
  String get dtcDescriptionP0190 => '燃油轨压力传感器电路故障';

  @override
  String get dtcDescriptionP0201 => '喷油嘴电路故障／开路 — 第 1 缸';

  @override
  String get dtcDescriptionP0202 => '喷油嘴电路故障／开路 — 第 2 缸';

  @override
  String get dtcDescriptionP0203 => '喷油嘴电路故障／开路 — 第 3 缸';

  @override
  String get dtcDescriptionP0204 => '喷油嘴电路故障／开路 — 第 4 缸';

  @override
  String get dtcDescriptionP0217 => '发动机过热';

  @override
  String get dtcDescriptionP0221 => '节气门／油门踏板位置传感器 B 范围或性能问题';

  @override
  String get dtcDescriptionP0222 => '节气门／油门踏板位置传感器 B 电路输入过低';

  @override
  String get dtcDescriptionP0223 => '节气门／油门踏板位置传感器 B 电路输入过高';

  @override
  String get dtcDescriptionP0234 => '涡轮／机械增压过压';

  @override
  String get dtcDescriptionP0299 => '涡轮／机械增压「A」增压不足';

  @override
  String get dtcDescriptionP0300 => '检测到随机/多缸失火';

  @override
  String get dtcDescriptionP0301 => '第 1 缸失火';

  @override
  String get dtcDescriptionP0302 => '第 2 缸失火';

  @override
  String get dtcDescriptionP0303 => '第 3 缸失火';

  @override
  String get dtcDescriptionP0304 => '第 4 缸失火';

  @override
  String get dtcDescriptionP0305 => '第 5 缸失火';

  @override
  String get dtcDescriptionP0306 => '第 6 缸失火';

  @override
  String get dtcDescriptionP0307 => '第 7 缸失火';

  @override
  String get dtcDescriptionP0308 => '第 8 缸失火';

  @override
  String get dtcDescriptionP0316 => '起动后随即检测到失火';

  @override
  String get dtcDescriptionP0325 => '爆震传感器电路故障 (第 1 缸组)';

  @override
  String get dtcDescriptionP0326 => '爆震传感器范围/性能问题 (第 1 缸组)';

  @override
  String get dtcDescriptionP0327 => '爆震传感器电路输入过低 (第 1 缸组)';

  @override
  String get dtcDescriptionP0328 => '爆震传感器电路输入过高 (第 1 缸组)';

  @override
  String get dtcDescriptionP0330 => '爆震传感器电路故障 (第 2 缸组)';

  @override
  String get dtcDescriptionP0335 => '曲轴位置传感器电路故障';

  @override
  String get dtcDescriptionP0336 => '曲轴位置传感器范围/性能问题';

  @override
  String get dtcDescriptionP0340 => '凸轮轴位置传感器电路故障';

  @override
  String get dtcDescriptionP0341 => '凸轮轴位置传感器范围/性能问题';

  @override
  String get dtcDescriptionP0351 => '点火线圈 A 一次/二次电路故障';

  @override
  String get dtcDescriptionP0352 => '点火线圈 B 一次/二次电路故障';

  @override
  String get dtcDescriptionP0353 => '点火线圈 C 一次/二次电路故障';

  @override
  String get dtcDescriptionP0354 => '点火线圈 D 一次/二次电路故障';

  @override
  String get dtcDescriptionP0355 => '点火线圈 E 一次/二次电路故障';

  @override
  String get dtcDescriptionP0356 => '点火线圈 F 一次/二次电路故障';

  @override
  String get dtcDescriptionP0400 => '废气再循环 (EGR) 流量故障';

  @override
  String get dtcDescriptionP0401 => '废气再循环 (EGR) 流量不足';

  @override
  String get dtcDescriptionP0402 => '废气再循环 (EGR) 流量过大';

  @override
  String get dtcDescriptionP0403 => '废气再循环 (EGR) 控制电路故障';

  @override
  String get dtcDescriptionP0404 => '废气再循环 (EGR) 控制电路范围/性能问题';

  @override
  String get dtcDescriptionP0410 => '二次空气喷射系统故障';

  @override
  String get dtcDescriptionP0411 => '二次空气喷射系统流量不正确';

  @override
  String get dtcDescriptionP0412 => '二次空气喷射切换阀 A 电路故障';

  @override
  String get dtcDescriptionP0420 => '催化器系统效率低于阈值（第 1 缸组）';

  @override
  String get dtcDescriptionP0430 => '催化器系统效率低于阈值（第 2 缸组）';

  @override
  String get dtcDescriptionP0440 => '蒸发排放控制系统故障';

  @override
  String get dtcDescriptionP0441 => '蒸发排放系统吹扫流量不正确';

  @override
  String get dtcDescriptionP0442 => '蒸发排放系统检测到小漏气';

  @override
  String get dtcDescriptionP0443 => '蒸发排放系统吹扫控制阀电路故障';

  @override
  String get dtcDescriptionP0446 => '蒸发排放通风控制电路故障';

  @override
  String get dtcDescriptionP0447 => '蒸发排放通风控制电路开路';

  @override
  String get dtcDescriptionP0449 => '蒸发排放通风阀/电磁阀电路故障';

  @override
  String get dtcDescriptionP0451 => '蒸发排放压力传感器范围/性能问题';

  @override
  String get dtcDescriptionP0452 => '蒸发排放压力传感器电路输入过低';

  @override
  String get dtcDescriptionP0453 => '蒸发排放压力传感器电路输入过高';

  @override
  String get dtcDescriptionP0455 => '蒸发排放系统检测到大漏气';

  @override
  String get dtcDescriptionP0456 => '蒸发排放系统检测到极小漏气';

  @override
  String get dtcDescriptionP0480 => '冷却风扇 1 控制电路故障';

  @override
  String get dtcDescriptionP0500 => '车速传感器故障';

  @override
  String get dtcDescriptionP0505 => '怠速控制系统故障';

  @override
  String get dtcDescriptionP0506 => '怠速转速低于预期';

  @override
  String get dtcDescriptionP0507 => '怠速转速高于预期';

  @override
  String get dtcDescriptionP0508 => '怠速控制系统电路电压过低';

  @override
  String get dtcDescriptionP0509 => '怠速控制系统电路电压过高';

  @override
  String get dtcDescriptionP0560 => '系统电压故障';

  @override
  String get dtcDescriptionP0562 => '系统电压过低';

  @override
  String get dtcDescriptionP0563 => '系统电压过高';

  @override
  String get dtcDescriptionP0603 => '内部控制模块可保持存储器（KAM）错误';

  @override
  String get dtcDescriptionP0605 => '控制模块内部只读内存（ROM）错误';

  @override
  String get dtcDescriptionP0606 => 'ECM/PCM 处理器故障';

  @override
  String get dtcDescriptionP0700 => '变速箱控制模块要求点亮故障灯 —— 故障码在变速箱模块里，请另外读取';

  @override
  String get dtcDescriptionP0701 => '变速箱控制系统范围/性能问题';

  @override
  String get dtcDescriptionP0702 => '变速箱控制系统电气故障';

  @override
  String get dtcDescriptionP0705 => '变速器挡位传感器电路故障';

  @override
  String get dtcDescriptionP0715 => '输入轴／涡轮转速传感器电路故障';

  @override
  String get dtcDescriptionP0720 => '输出轴转速传感器电路故障';

  @override
  String get dtcDescriptionP0730 => '传动比不正确';

  @override
  String get dtcDescriptionP0740 => '变矩器离合器电路故障';

  @override
  String get dtcDescriptionP0741 => '变矩器离合器卡在未锁定状态';

  @override
  String get dtcDescriptionP0750 => '换挡电磁阀 A 故障';

  @override
  String get dtcDescriptionP0755 => '换挡电磁阀 B 故障';

  @override
  String get dtcDescriptionP2135 => '节气门位置传感器 A/B 电压相关性';

  @override
  String get dtcDescriptionU0100 => '与 ECM/PCM 失去通信';

  @override
  String get dtcDescriptionU0101 => '与变速箱控制模块失去通信';

  @override
  String get dtcDescriptionU0121 => '与 ABS 控制模块失去通信';

  @override
  String get dtcDescriptionU0140 => '与车身控制模块失去通信';

  @override
  String get dtcDescriptionU0155 => '与仪表板控制模块失去通信';

  @override
  String get gaugeSkinCluster => '组合仪表';

  @override
  String get gaugeSkinClusterDescription => '原厂组合仪表的样式。指针、270 度刻度盘、内凹表盘。';

  @override
  String get gaugeSkinMinimal => '极简';

  @override
  String get gaugeSkinMinimalDescription => '半圆弧、没有指针、没有刻度。要看的是数字，不是动作。';

  @override
  String get gaugeSkinTrack => '赛道';

  @override
  String get gaugeSkinTrackDescription => '分段灯条、无平滑动画。数值到哪就是哪，不做过渡。';

  @override
  String get gaugeSkinClassic => '经典';

  @override
  String get gaugeSkinClassicDescription => '印刷式面盘、整圈数字、指针像机械表一样慢慢定位。';

  @override
  String get gaugeSkinNight => '夜视';

  @override
  String get gaugeSkinNightDescription => '夜间驾驶用。低亮度、浅弧、不做动画，尽量不抢走注意力。';

  @override
  String get derivedAirflowSourceMaf => 'MAF 传感器';

  @override
  String get derivedAirflowSourceSpeedDensity => '速度密度法推算';

  @override
  String get derivedAirflowSourceUnavailable => '无法获取进气质量';

  @override
  String get derivedFuelSourceStoichiometric => '化学计量比推算';

  @override
  String get derivedFuelSourceUnavailable => '无法获取油耗';

  @override
  String get telemetrySourceDemo => '内置模拟';

  @override
  String get telemetrySourceRig => '测试台架';

  @override
  String get telemetrySourceFieldApp => '一般 field App 连接';

  @override
  String get fuelTypeGasoline => '汽油';

  @override
  String get fuelTypeDiesel => '柴油';

  @override
  String get fuelTypeLpg => '液化石油气 (LPG)';

  @override
  String get fuelTypeEthanolE85 => 'E85 酒精汽油';

  @override
  String get drivetrainFwd => '前轮驱动';

  @override
  String get drivetrainRwd => '后轮驱动';

  @override
  String get drivetrainAwd => '四轮驱动';

  @override
  String get assumptionFieldMass => '车重';

  @override
  String get assumptionFieldDragCoefficient => 'Cd';

  @override
  String get assumptionFieldFrontalArea => '迎风面积';

  @override
  String get assumptionFieldRollingResistance => '滚动阻力';

  @override
  String get assumptionFieldDrivetrainEfficiency => '传动效率';

  @override
  String get assumptionFieldFuelType => '燃料';

  @override
  String get assumptionFieldStoichAfr => 'AFR';

  @override
  String get assumptionFieldFuelDensity => '密度';

  @override
  String get assumptionFieldDisplacement => '排气量';

  @override
  String get assumptionFieldVolumetricEfficiency => 'VE';

  @override
  String get vehicleFieldOriginGenericDefault => '通用默认';

  @override
  String get vehicleFieldOriginUserEntered => '手动输入';

  @override
  String get vehicleFieldOriginOfficialRegistry => '官方登记目录';

  @override
  String get vehicleFieldOriginManufacturerPublication => '原厂数据';

  @override
  String get vehicleFieldOriginScientificModel => '模型系数';

  @override
  String assumptionWithOrigin(String field, String value, String origin) {
    return '$field $value（$origin）';
  }

  @override
  String assumptionWithoutOrigin(String field, String value) {
    return '$field $value';
  }

  @override
  String get assumptionSeparator => '；';

  @override
  String get datumFormulaHorsepower =>
      'wheelWatts = (m·a + ½ρ·Cd·A·v² + Crr·m·g)·v; engineHp = wheelHp / drivetrainEfficiency';

  @override
  String get datumFormulaFuelRate =>
      'L/h = (MAF g/s) / (AFR × 燃油密度 g/L) × 3600; MAF 可为 PID 0110 或 速度密度法推算（RPM×MAP×排气量×VE / T_K）; L/100km = (L/h) / speed_kmh × 100';

  @override
  String get datumAssumptionsFromRecording => '估算使用记录当下的车辆设置';

  @override
  String adapterConcernFirmwareNeverReleasedSummary(String version) {
    return '回报的固件版本 v$version 官方从未发行';
  }

  @override
  String get adapterConcernFirmwareNeverReleasedDetail =>
      'ELM327 的原厂 Elm Electronics 没有出过这个版本 —— 这台适配器上的固件不是它自称的那一份。很多这种适配器仍然可用，但它对自己的描述已经不可靠，遇到读不到的状况时值得先怀疑它。';

  @override
  String adapterConcernPpsRefusedSummary(String version) {
    return '自称 v$version，却不认得 v1.1 就有的 ATPPS 指令';
  }

  @override
  String get adapterConcernPpsRefusedDetail =>
      '可编程参数摘要（ATPPS）从 ELM327 v1.1 起就存在，连 OBDLink 这类高端适配器也支持。自称的版本与实际实现的指令对不起来。';

  @override
  String get adapterConcernNoIdentitySummary => '不回应 AT@1（第一版就有的设备识别指令）';

  @override
  String get adapterConcernNoIdentityDetail =>
      '这条指令从 ELM327 v1.0 就存在。不回应代表这颗芯片的指令集比任何一版官方固件都少。';

  @override
  String get telemetryReplaySampled => '预览已抽样；导出保留完整已记录事件';

  @override
  String get telemetryExportDisclosure =>
      '导出内容包含信号名称、数值、观测与来源时间、传输类型、通信协议、冻结的 PID 标签／单位／公式，以及估算假设（车重、空气阻力、排气量、燃料等参数）。JSON 可能包含用户自定义标签、单位、公式与完整冻结定义。导出内容不含 VIN、GPS、账号、适配器地址、完整车辆配置或原始诊断流量。';

  @override
  String get connectTransportCancelled => '连接尝试在完成前被停止了。';

  @override
  String get connectTransportWifiRouteNoNetwork =>
      '手机没有连上任何 Wi-Fi 网络，没有通往适配器的路由。请先连上适配器的 Wi-Fi 热点再试一次。';

  @override
  String get connectTransportWifiRouteAmbiguous =>
      '手机同时连着多个 Wi-Fi，不能判断哪一个通往适配器，所以没有选任何一个。请先关闭不是适配器的那些连接再试一次。';

  @override
  String get connectTransportWifiRouteRefused =>
      '系统拒绝让这个连接走 Wi-Fi。手机是连着 Wi-Fi 的，只是不被允许用于这个连接。';

  @override
  String get connectTransportWifiRouteTimeout =>
      '系统没有回应「让这个连接走 Wi-Fi」的请求。请等几秒再试一次。';

  @override
  String get connectTransportWifiRouteUnclassified =>
      '这个连接未能走 Wi-Fi，而系统没有说明原因。完整的错误留在下方的记录里。';

  @override
  String get connectTransportWifiHostUnreachable =>
      '那个地址没有回应。请确认手机已连上适配器的 Wi-Fi 热点 —— 若系统问过「连不上互联网，是否继续使用」，要选继续使用。关闭移动数据也可能有帮助。';

  @override
  String get connectTransportWifiConnectTimeout => '那个地址在时限内没有任何回应。';

  @override
  String get connectTransportWifiRouteRestoreFailed =>
      '连接本身成功了，但手机的网络路由未能恢复，所以连接被中断，而不是把它改过的状态留着。请重新打开 App 再试一次。';

  @override
  String get connectTransportBleLinkFailed => '未能连接到适配器。请确认它已通电且在范围内。';

  @override
  String get connectTransportBleNoSerialCharacteristic =>
      '设备连上了，但在它身上没有找到串行端口，可能不是 ELM327 适配器。';

  @override
  String get connectTransportClassicAllTiersRefused =>
      '未能连接到适配器。请先在系统蓝牙设置完成配对，并确认它已插上 OBD 端口且点火开关已打开。';

  @override
  String get connectTransportClassicConnectTimeout =>
      '连接到适配器超时。它可能仍在回应中 —— 请等几秒再试，不要立刻重试。';

  @override
  String get connectTransportSerialPortOpenFailed =>
      '未能打开串行端口。请确认系统已为这个适配器创建串行端口（Windows COMx / Linux /dev/rfcomm*），且点火开关已打开。';

  @override
  String get connectTransportSerialDroppedOnOpen => '串行端口打开后立刻又关闭了。';

  @override
  String get settingsManualCommandNotConnected => '目前没有连接，这条指令没有送出。';

  @override
  String get settingsManualCommandLinkDropped =>
      '这条指令还在等待回应时，与适配器的连接中断了，所以没有任何回应。适配器是否收到这条指令并不确定。';

  @override
  String get settingsManualCommandDisconnectedByApp =>
      '这条指令还在等待回应时，App 主动关闭了连接，所以没有任何回应。适配器与车辆都没有问题。';

  @override
  String get settingsManualCommandAdapterSilentOnResync =>
      '适配器的回应已经和送出的指令对不上，而它也没有回应用来重新对齐的检查，所以连接已中断。请重新连接后再试一次。';

  @override
  String get settingsManualCommandLinkStoppedResponding =>
      '适配器安静得够久，连接已被中断。它可能仍有电；能确定的只有这段沉默。';

  @override
  String get settingsManualCommandWriteFailed =>
      '这条指令未能交给适配器的连接。有多少内容送达适配器并不确定。';

  @override
  String get settingsManualCommandTimedOut =>
      '在时限内没有收到回应。请确认适配器已连接，且车辆点火开关已打开。';

  @override
  String get settingsManualCommandOperationRetired => '本次会话已经结束或进入后台，因此未发送指令。';

  @override
  String get settingsManualCommandRequestUnaddressable =>
      '这条要求在这辆车使用的总线上未能寻址，因此没有送出。再试一次也不会改变。';

  @override
  String get commandFailureBusJ1939 =>
      '这条总线是 SAE J1939（重型商用车与机械），不是本 App 读取的 OBD2 诊断协议，因此未能读取这次查询。';

  @override
  String commandFailureUserCanFramingUnknown(
    String protocol,
    String parameter,
  ) {
    return '适配器设成自定义 CAN 协议 $protocol，其帧格式由 $parameter 决定。适配器没有回报该设置，因此未能确认总线格式，也不能安全解码这次查询。';
  }

  @override
  String get commandFailureBusUndetermined => '车辆总线协议尚未确定，因此不能安全解码这次查询。请重新连接。';

  @override
  String get settingsManualCommandCustomFlowControlRejected =>
      '适配器拒绝了自定义 Flow Control 指令，因此未应用所要求的模式，也没有产生任何测量值。';

  @override
  String get settingsManualCommandFlowControlRestoreFailed =>
      '适配器拒绝还原默认 Flow Control（ATFCSM0），因此轮询已停止，重新连接前不会恢复。';

  @override
  String get settingsManualCommandExtendedAddressingUnavailable =>
      '此 ELM327 路径不提供延伸寻址。';

  @override
  String get settingsManualCommandRawIsoTpModeUnavailable =>
      '此 ELM327 路径不提供主机可见的 ISO-TP 重组。';

  @override
  String get settingsManualCommandCanPriorityUnavailable =>
      '此 ELM327 路径不提供 CAN 优先级编程。';

  @override
  String get settingsManualCommandCanReceiveFilterUnavailable =>
      '此 ELM327 路径不提供 CAN 接收过滤。';

  @override
  String get settingsManualCommandHeaderRestoreFailed =>
      '适配器拒绝恢复标头（ATSH），因此轮询已停止，直到重新连接。';

  @override
  String get manualCommandRefusedEmpty => '没有输入任何内容，因此没有发送任何指令。';

  @override
  String get manualCommandRefusedMoreThanOneCommand =>
      '指令里有换行或控制字符，这样会一次送出多个指令。适配器以换行分隔指令，所以第二个指令不会经过这里的任何检查 —— 包括禁止清除故障码的那一项。请一次只输入一个指令。';

  @override
  String manualCommandRefusedAdapterStateWouldChange(
    Object command,
    Object allowed,
  ) {
    return '手动指令只接受查询，不接受会改变适配器设置的指令。「$command」会改动适配器状态，而 App 对适配器的认知不会跟着更新 —— 接下来的读数可能来自另一个控制器，而画面上看不出来。\n可用的查询：$allowed。';
  }

  @override
  String get manualCommandRefusedClearHasItsOwnButton =>
      '清除故障码请用故障码界面的「清除」按钮。从这里发送会跳过确认、覆盖范围检查与响应验证，而且只会发送到目前选中的那一个控制器。';

  @override
  String manualCommandRefusedCharactersNoObdCommandHas(Object command) {
    return '指令「$command」含有 OBD 指令不会出现的字符。这里只接受十六进制的服务码与参数（例如 0100、03、2211A6），或 AT 开头的适配器查询。';
  }

  @override
  String manualCommandRefusedNotAReadOnlyQuery(Object command, Object allowed) {
    return '不认得的指令「$command」。这里只接受只读查询（Mode $allowed）与适配器查询指令。';
  }

  @override
  String commandFailureQueryHeaderRefused(Object header) {
    return '适配器拒绝将这条要求对准到控制器 $header，因此它没有送出。如果留在适配器实际持有的地址上，回应会来自没有人询问的控制器。';
  }

  @override
  String commandFailureWholeVehicleHeaderRefused(Object address) {
    return '适配器拒绝切换到 $address 这个地址，而向全车提出的问题必须从它送出。没有它，回应就未能对应到送出它们的控制器，因此这个要求没有送出。';
  }

  @override
  String commandFailureLegacyScanWouldBePartial(Object installed) {
    return '这辆车使用的旧式总线没有能触及每个控制器的标准地址，而适配器目前指定在控制器 $installed。扫描只会涵盖那一个控制器，却会被当成全车结果呈现，因此没有送出。请重新连接后再扫描一次。';
  }

  @override
  String get pidFormulaEmpty => '公式是空的。';

  @override
  String get pidFormulaEmptySubExpression => '公式有一段是空的 —— 操作符后面没有东西，或括号里没有内容。';

  @override
  String get pidFormulaUnbalancedParentheses => '括号没有配对：每一个 ( 都需要一个对应的 )。';

  @override
  String pidFormulaUnparsableTerm(String term) {
    return '「$term」不是数值、操作符，也不是这个编辑器认得的名称。';
  }

  @override
  String get pidFormulaFunctionNestingTooDeep =>
      'ABS()、LOG10()、LOG() 与 SQRT() 嵌套太深，不能求值。请简化公式。';

  @override
  String get pidFormulaParenthesisNestingTooDeep => '括号嵌套太深，不能求值。请简化公式。';

  @override
  String get pidFormulaDivisionByZero => '公式除以零。';

  @override
  String get pidFormulaModuloByZero => '公式对零取余数。';

  @override
  String pidFormulaLog10NonPositiveArgument(double argument) {
    return 'LOG10 的参数必须大于 0，这里算出来的是 $argument。';
  }

  @override
  String pidFormulaLogNonPositiveArgument(double argument) {
    return 'LOG 的参数必须大于 0，这里算出来的是 $argument。';
  }

  @override
  String pidFormulaSqrtNegativeArgument(double argument) {
    return 'SQRT 的参数必须大于或等于 0，这里算出来的是 $argument。';
  }

  @override
  String get pidFormulaResultNotFinite => '这串运算没有得出可用的数值，因此没有读数可显示。';

  @override
  String pidFormulaByteBeyondResponse(String letter, int count) {
    return '公式参照字节 $letter，但回应只有 $count 个字节。';
  }

  @override
  String get pidFormulaBaroControllerUnknown =>
      '这里不能使用 BARO，因为不能判断指的是哪一个控制器的大气压力。';

  @override
  String get pidFormulaBaroTwoDefinitions =>
      '有两个定义同时提供大气压力，数值可能是其中任何一个，因此不能采用。请移除其中一个测量大气压力的表。';

  @override
  String get pidFormulaBaroNotYetMeasured => '尚未取得大气压力测量值，不能计算。';

  @override
  String get pidFormulaBaroMeasurementStale => '大气压力测量值已过期，不能计算。';

  @override
  String get pidFormulaBaroParenFormUnsupported =>
      'BARO() 是 Android 气压计／ECU 大气压（psi），这个方言没有实现。要用缓存的大气压力请写不带括号的 BARO。';

  @override
  String get pidFormulaInt16Unclaimed =>
      '此方言尚未定义 INT16 的含义：wiki 说它可替代 (A*255)+B，但这并不等于 (A*256)+B。请在公式中明确写出其中一个等式。';

  @override
  String pidFormulaTimeWindowUnsupported(String term) {
    return '$term 是这个方言尚未实现的延迟、平均或 totalizer Torque 函数，因此不能在这里求值。它不是 0，也不是 MIN 或 MAX。';
  }

  @override
  String pidFormulaDependencyControllerUnknown(String reference) {
    return '这里未能解析 $reference，因为不能判断那个 PID 属于哪一个控制器。';
  }

  @override
  String pidFormulaDependencyTwoDefinitions(String key) {
    return '有两个定义同时解读 $key，数值可能是其中任何一个，因此不能采用。请让其中一个改用不同的模式+PID。注意：推算数值需要的 PID（010B、010C、010D）本 App 一定会读取，把面板上的表移掉不会停止读取它们。';
  }

  @override
  String pidFormulaDependencyNotYetMeasured(String key) {
    return '尚未读取到 $key 的有效数值。';
  }

  @override
  String get pidFormulaUnidentified => '这个公式不能求值，而编辑器没有更具体的原因可显示。';

  @override
  String get pidRejectionMalformedModeAndPid =>
      '不是有效的模式+PID（只接受十六进制字符，每两个字符组成一个完整字节）。';

  @override
  String pidRejectionServiceNotReadOnly(String service, String services) {
    return '服务 $service 不是只读查询，不得反复发送到车上。只允许 $services（现值、冻结帧、车辆信息、ReadDataByIdentifier）。';
  }

  @override
  String get pidRejectionFreezeFrameNeedsFrame =>
      '冻结帧查询需要 PID 与帧编号两个字节，例如 020500（PID 05、第 0 帧）。';

  @override
  String get pidRejectionIdentifierNeedsTwoBytes =>
      'ReadDataByIdentifier 需要两个字节的识别码，例如 221101。';

  @override
  String pidRejectionIdentifierWrongLength(String service, int bytes) {
    return '服务 $service 的查询需要 $bytes 个字节的识别码。';
  }

  @override
  String get pidRejectionNameRequired => '请输入名称。';

  @override
  String pidRejectionInvalidHeader(String text) {
    return '「$text」不是有效的标头（11-bit CAN 为 3 码、旧协议为 6 码、29-bit CAN 为 8 码）。';
  }

  @override
  String get pidRejectionBoundsRequired => '请填写量程的上下限。';

  @override
  String pidRejectionMinNotANumber(String text) {
    return '量程下限「$text」不是有效的数值。';
  }

  @override
  String pidRejectionMaxNotANumber(String text) {
    return '量程上限「$text」不是有效的数值。';
  }

  @override
  String get pidRejectionMinNotFinite => '量程下限必须是有限的数值。';

  @override
  String get pidRejectionMaxNotFinite => '量程上限必须是有限的数值。';

  @override
  String pidRejectionRedlineNotANumber(String text) {
    return '红线起点「$text」不是有效的数值。';
  }

  @override
  String get pidRejectionRedlineNotFinite => '红线起点必须是有限的数值。';

  @override
  String get pidRejectionMaxNotAboveMin => '量程上限必须大于下限。';

  @override
  String pidImportMalformedCsv(String detail) {
    return '这个文件未能以 CSV 读取：$detail';
  }

  @override
  String get pidImportNoRows => '文件没有任何数据行。';

  @override
  String pidImportDuplicateHeaderColumns(String columns) {
    return '表头行有重复的列名：$columns。无法判断应使用哪一列，请先修正文件。';
  }

  @override
  String pidImportMissingRequiredColumns(String columns, String required) {
    return '表头行缺少必需的列：$columns。$required 都是必需的。';
  }

  @override
  String pidImportRowTooFewColumns(int line) {
    return '第 $line 行：字段不足，至少需要名称、简称、PID、公式。';
  }

  @override
  String pidImportRowInvalidModeAndPid(int line, String text) {
    return '第 $line 行：「$text」不是有效的模式+PID（只接受十六进制字符，每两个字符组成一个完整字节）。';
  }

  @override
  String pidImportRowEmptyEquation(int line) {
    return '第 $line 行：公式为空。';
  }

  @override
  String pidImportRowRejected(int line, String reason) {
    return '第 $line 行：$reason';
  }

  @override
  String pidImportRowRangeDefaulted(int line, double min, double max) {
    return '第 $line 行：量程留空，已应用默认 $min–$max。请确认这个刻度适合这个传感器。';
  }

  @override
  String get pidImportNothingImportable => '文件里有数据行，但没有任何一行是 PID 定义。';

  @override
  String get dtcCategoryNoAnswer => '这个类别没有回应。请重新扫描。';

  @override
  String get dtcCategoryError => '这个类别读取失败。完整错误保留在记录里。';

  @override
  String get dtcCategoryDisconnected => '读取这个类别时连接中断。';

  @override
  String get dtcCategoryPending => '控制器已收到请求、仍在处理中。请稍候再扫描一次——这不是拒绝。';

  @override
  String get dtcCategoryUnattributed =>
      '有读到故障码，但响应标头已关闭，因此无法确定哪些控制器作出了响应。请将此视为部分结果，而不是无故障的完整结果。';

  @override
  String dtcCategorySilentControllers(int count, String controllers) {
    return '有 $count 个控制器没有回应这次查询（$controllers）。已回应的部分仍然有效，但不能当作全车结果。';
  }

  @override
  String dtcCategoryUnresolvedSources(int count, String addresses) {
    return '有 $count 笔回应不能判断是哪个控制器送出的（$addresses）。已读到的结果仍然有效，但不能当作全车结果。请重新扫描。';
  }

  @override
  String dtcCategoryPendingControllers(int count, int answered) {
    return '有 $count 个控制器还在处理这次查询，$answered 个已回应。结果尚不完整，请稍候再扫描一次。';
  }

  @override
  String dtcCategoryRefusedControllers(int refused, int answered) {
    return '有 $refused 个控制器拒绝回答（$answered 个已回应）。这次扫描未能涵盖全车，结果并不完整。';
  }

  @override
  String dtcCategoryUnrecognisedResponses(int count, int answered) {
    return '有 $count 笔回应未能辨识（$answered 个已回应）。其余结果仍然有效，但这次扫描并不完整。';
  }

  @override
  String dtcCategoryMilCountMismatch(
    String controller,
    int claimed,
    int observed,
  ) {
    return '$controller 报告有 $claimed 笔已确认故障码，但这次扫描只读到 $observed 笔。请以仪表盘上的故障灯为准，并前往维修厂检查。';
  }

  @override
  String dtcCategoryMilLitNoCodes(String controller) {
    return '$controller 报告故障灯亮着，但没有读到它所属的故障码。请以仪表盘上的故障灯为准，并前往维修厂检查。';
  }

  @override
  String dtcCategoryMilDisagreement(String controllers) {
    return '车辆自身状态与读到的故障码不符（$controllers）。请以仪表盘上的故障灯为准，并前往维修厂检查。';
  }

  @override
  String get connectPairedListFailed => '未能读取已配对的蓝牙清单。请确认蓝牙已打开后再试。';

  @override
  String get connectBleScanUnavailable => '蓝牙目前不能使用。请稍后再搜索。';

  @override
  String get connectBleScanBluez =>
      '找不到可用的 BlueZ／D-Bus 蓝牙服务。请确认系统已安装并启动 bluetooth 服务后再试。';

  @override
  String get connectBleScanUnclassified => 'BLE 搜索失败。';

  @override
  String dtcClearNrcConditions(String controller) {
    return '$controller 拒绝清除，因为车辆当前状态不允许。多数控制器不会在发动机运转时清除故障码。请关闭发动机，将点火开关转至 ON，然后重试。';
  }

  @override
  String dtcClearNrcUnsupported(String controller) {
    return '$controller 不支持 Mode 04 清除。可能需要制造商或经销商的设备。';
  }

  @override
  String dtcClearNrcBusy(String controller) {
    return '$controller 目前忙碌中。请稍候再试一次。';
  }

  @override
  String dtcClearNrcSecurity(String controller) {
    return '$controller 要求先获得安全访问权限才允许清除。这需要制造商或经销商的设备。';
  }

  @override
  String dtcClearNrcOther(String controller, String code) {
    return '$controller 拒绝清除（原因码 $code）。请稍候再试一次。';
  }

  @override
  String dtcClearSilentControllers(int count, String controllers) {
    return '有 $count 个控制器没有回应清除指令（$controllers）。已回应的控制器已清除，其余可能仍有故障码。请重新扫描，不要再送一次清除。';
  }

  @override
  String dtcClearUnresolvedSources(int count, String addresses) {
    return '扫描时有 $count 个响应无法归属于具体控制器（$addresses），因此无法确认清除指令会送达哪些控制器。请重新扫描；如果该地址没有再次出现，请重新连接后再试。';
  }

  @override
  String dtcClearUnresolvedSourcesDoNotRepeat(int count, String addresses) {
    return '清除指令的回应中有 $count 笔不能判断来源的数据（$addresses）。不要再送一次清除。请重新扫描确认哪些故障码还在。';
  }

  @override
  String dtcClearNrcConditionsDoNotRepeat(String controller) {
    return '$controller 拒绝清除，因为车辆当前状态不允许。多数控制器不会在发动机运转时清除故障码。请关闭发动机，将点火开关转至 ON，然后重新扫描以确认哪些故障码仍然存在。不要再次发送全车清除指令 —— 第二次清除可能会重置可能已经清除故障码的控制器的排放就绪状态。';
  }

  @override
  String dtcClearNrcUnsupportedDoNotRepeat(String controller) {
    return '$controller 不支持清除服务（Mode 04）。可能需要制造商或经销商的设备。不要再送一次全车清除 —— 重复清除可能会重置可能已经清除故障码的控制器的排放就绪状态。请重新扫描确认哪些故障码还在。';
  }

  @override
  String dtcClearNrcBusyDoNotRepeat(String controller) {
    return '$controller 目前忙碌中。不要再送一次全车清除 —— 重复清除可能会重置可能已经清除故障码的控制器的排放就绪状态。请重新扫描确认哪些故障码还在。';
  }

  @override
  String dtcClearNrcSecurityDoNotRepeat(String controller) {
    return '$controller 要求先获得安全访问权限才允许清除。这需要制造商或经销商的设备。不要再送一次全车清除 —— 重复清除可能会重置可能已经清除故障码的控制器的排放就绪状态。';
  }

  @override
  String dtcClearNrcOtherDoNotRepeat(String controller, String code) {
    return '$controller 拒绝清除（原因码 $code）。不要再送一次全车清除 —— 重复清除可能会重置可能已经清除故障码的控制器的排放就绪状态。请重新扫描确认哪些故障码还在。';
  }

  @override
  String get sharePolicyDenied => '目前的连接或行车状态不允许导出。';

  @override
  String get shareSafetyChanged => '准备导出期间状态已改变，未打开分享。';

  @override
  String get shareSizeLimit => '导出文件超过 32 MiB 上限。';

  @override
  String get shareStagingBusy => '先前的分享文件仍在保留期内，请稍后再试。';

  @override
  String get shareCleanupRequired => '分享暂存区需要在重新启动后检查。';

  @override
  String get shareSpaceUnknown => '无法确认分享文件所需的可用空间。';

  @override
  String get shareNoSpace => '存储空间不足，无法准备分享文件。';

  @override
  String get shareHandoffFailed => '文件已准备好，但无法打开系统分享面板。';

  @override
  String get shareStorageFailure => '准备或记录分享结果时发生保存错误。';

  @override
  String shareTelemetrySubject(String sessionId) {
    return '本机 OBD 记录 $sessionId';
  }

  @override
  String shareRawTranscriptSubject(String stamp) {
    return 'Telltale 传输记录 $stamp';
  }

  @override
  String get shareRecoveredTranscriptSubject => 'Telltale 传输记录（上一次连接）';

  @override
  String get sharePidCsvSubject => 'Telltale 自定义 PID 定义';

  @override
  String get shareTorqueSubsetCsvSubject => 'Torque 兼容 PID 定义';

  @override
  String get shareHumanReportCsvSubject => 'Telltale 人类可读 PID 报表';

  @override
  String get transcriptExportUnidentified => '导出失败。';

  @override
  String get handshakeNoteUnexpected => '此步骤发生未预期的错误。完整错误保留在记录里。';

  @override
  String pidFormulaUnsupportedConstruct(String term) {
    return '$term 是这个方言尚未实现的 Torque 函数，因此不能在这里求值。';
  }

  @override
  String pidImportRowFormulaRejected(int line, String reason) {
    return '第 $line 行：$reason';
  }

  @override
  String get telemetryHistoryNeedsForeground => '请先回到 Telltale 再继续。';

  @override
  String get telemetrySessionPolicyChanged => '操作期间行车或连接状态已改变';

  @override
  String get telemetrySessionInvalidId => '记录识别码无效';

  @override
  String get telemetrySessionNotFound => '找不到这笔本机记录';

  @override
  String get telemetrySessionStorageFailed => '本机保存作业失败';

  @override
  String get telemetrySessionShareFailed => '未能准备或打开分享';

  @override
  String get pidMutationPersistFailed => '自定义 PID 清单未能写入。没有任何变更。';

  @override
  String get powertrainAuthorizeYearOutOfRange => '该车型年份不在此车型配置记载的年份范围内。';

  @override
  String get connectionLayerTransport => '连接方式';

  @override
  String get connectionLayerProtocol => '协议';

  @override
  String get connectionLayerEcu => 'ECU 回复';

  @override
  String get connectionLayerEvidence => '证据';

  @override
  String get connectionLayerUnknown => '未知';

  @override
  String get connectionLayerNotObserved => '未观察到';

  @override
  String get connectionLayerObserved => '已观察';

  @override
  String get connectionLayerAnswered => '有回应';

  @override
  String get connectionLayerSoftware => '软件';

  @override
  String get connectionLayerDemo => '内置模拟器';

  @override
  String get connectionLayerBle => 'Bluetooth LE';

  @override
  String get connectionLayerClassic => '蓝牙 Classic';

  @override
  String get connectionLayerWifi => '无线网络';

  @override
  String connectionLayerRequestedObserved(String requested, String observed) {
    return '要求 $requested，实际 $observed';
  }

  @override
  String get connectionLayerKwpSubtypeUnknown => 'KWP，5-baud 与 fast 无法区分';

  @override
  String get connectionFailureOpenSettings => '打开系统设置。';

  @override
  String get connectionFailureTurnRadioOn => '请打开蓝牙。';

  @override
  String get connectionFailureCheckDistanceOrPower =>
      '适配器可能太远或没有供电。那是可能的原因，不是已确认的发现。';

  @override
  String get connectionFailureCheckIgnitionProtocolAdapter =>
      '请检查点火开关、协议或适配器的能力。没有响应并不能证明车辆没有 OBD。';

  @override
  String get connectionFailureRetryOrAuto => '请重试，或把协议设成 Auto。';

  @override
  String get connectionFailureKeepInvalidAndExport =>
      '这笔回应无效。维持无效并导出有限诊断；它不是读数。';

  @override
  String get settingsCatalogMarketCa => '加拿大（NRCan）';

  @override
  String get settingsCaPickerTitle => '加拿大官方车辆目录';

  @override
  String settingsCaPickerScope(int firstYear, int lastYear) {
    return '仅包含 $firstYear–$lastYear 年加拿大市场的燃油消耗评级数据行。内燃机车、纯电动车和插电式混合动力车仍为独立类别。品牌／车型名称相同不代表是 EPA 或台湾配置。';
  }

  @override
  String get settingsCaMotorNotPower => '电机功率（kW）不是轮马力，不会应用。';

  @override
  String get settingsCaClassIce => '内燃机';

  @override
  String get settingsCaClassBev => 'BEV';

  @override
  String get settingsCaClassPhev => 'PHEV';

  @override
  String settingsCaWillApplyOnly(String fields) {
    return '只会应用 $fields。电机功率（kW）、油耗、续航里程、CO2、VE、Cd、迎风面积、Crr 和传动效率仍未确定。';
  }

  @override
  String get serviceRecipesTitle => '诊断配方与主动测试';

  @override
  String get serviceRecipesSubtitle => '标准规范服务配方与非致动能力探索';

  @override
  String get serviceRecipesSafetyBannerTitle => '零实车候选（Zero Live Candidates）';

  @override
  String get serviceRecipesSafetyBannerBody =>
      '严禁对实车进行物理致动（符合条件的车辆数：0）。可用配方仅为模拟测试用例。';

  @override
  String get serviceRecipesDiscoverySection => 'Mode 08 非致动能力探索';

  @override
  String get serviceRecipesDiscoveryDescription =>
      '仅通过 CAN 查询标准基础测试 ID（\$00、\$20 等），不致动任何部件。';

  @override
  String get serviceRecipesDiscoveryButton => '查询 Mode 08 支持的 TID';

  @override
  String get serviceRecipesDiscovering => '正在查询支持的 TID…';

  @override
  String serviceRecipesDiscoverySuccess(String tids) {
    return 'ECU 支持 Mode 08。支持 TID：$tids';
  }

  @override
  String get serviceRecipesDiscoveryUnsupported => '此 ECU 不支持 Mode 08';

  @override
  String serviceRecipesDiscoveryUnknown(String reason) {
    return 'Mode 08 支持状态未知：$reason';
  }

  @override
  String serviceRecipesDiscoveryPartialWarning(String reason, String blocks) {
    return '探索未完全完成（$reason）。未完成区块：$blocks。未查到不代表不支持。';
  }

  @override
  String get serviceRecipesCatalogSection => '可用服务配方清单';

  @override
  String get serviceRecipesSimulationBadge => '模拟可用';

  @override
  String get serviceRecipesLiveBlockedBadge => '禁止实车（0 实车候选）';

  @override
  String serviceRecipesStandard(String standard) {
    return '标准规范：$standard';
  }

  @override
  String serviceRecipesEcuHeader(String header) {
    return 'ECU 标头：$header';
  }

  @override
  String serviceRecipesHash(String hash) {
    return '规范化哈希：$hash';
  }

  @override
  String get serviceRecipesDetailTitle => '服务配方详细信息';

  @override
  String get serviceRecipesPreconditions => '安全前置条件';

  @override
  String get serviceRecipesRecovery => '恢复指令';

  @override
  String get serviceRecipesClose => '关闭';

  @override
  String get serviceRecipesDiscoveryRequiresCan => '需要有效的 OBD-II CAN 总线连接。';

  @override
  String serviceRecipesLoadError(String error) {
    return '加载服务配方时发生错误：$error';
  }

  @override
  String get serviceRecipesNoPreconditions => '无';

  @override
  String get settingsServiceRecipesEntry => '车行诊断配方与主动测试';

  @override
  String get settingsServiceRecipesDesc => '查看维修服务配方并查询支持的 Mode 08 测试';

  @override
  String get mode08ReasonUnheaderedLimitation =>
      '来源归属和覆盖范围尚未确认：无标头的响应无法确定跨区块的 ECU 身份';

  @override
  String mode08ReasonNoResponseWithEcu(
    String block,
    String ecu,
    String marker,
  ) {
    return '$ecu 在区块 $block 上没有响应：$marker';
  }

  @override
  String mode08ReasonNoResponse(String block, String marker) {
    return '区块 $block 无回应：$marker';
  }

  @override
  String mode08ReasonNegativeWithEcu(String block, String ecu, String nrc) {
    return '$ecu 在区块 $block 上返回否定响应（NRC $nrc）';
  }

  @override
  String mode08ReasonNegative(String block, String nrc) {
    return '区块 $block 负回应 (NRC $nrc)';
  }

  @override
  String mode08ReasonMalformedWithEcu(
    String block,
    String ecu,
    String details,
  ) {
    return '$ecu 在区块 $block 上返回格式错误的响应：$details';
  }

  @override
  String mode08ReasonMalformed(String block, String details) {
    return '区块 $block 的响应格式错误：$details';
  }

  @override
  String mode08ReasonTimeout(String block) {
    return '区块 $block 查询超时';
  }

  @override
  String get mode08ReasonBudgetExceeded => '尚未查询所有区块，已达到探索预算上限';

  @override
  String get mode08ReasonSessionDisconnected => '探索期间连接中断或被取代';

  @override
  String mode08ReasonUnqueriedAnnounced(String blocks) {
    return 'ECU 声明但未查询的区块：$blocks';
  }

  @override
  String get mode08ReasonRequiresCanBus => 'Mode 08 能力查询需要已确定的 OBD-II CAN 总线';

  @override
  String get mode08ReasonUnexpectedExecution => '查询支持 TID 时收到非预期的运行回应';

  @override
  String get pidDetailEmptyTitle => '选取 PID';

  @override
  String get pidDetailEmptyBody => '从清单中选取一个 PID 以查看其定义与实时状态。';

  @override
  String get pidDetailRangeLabel => '范围';

  @override
  String get pidDetailPriorityLabel => '优先级';

  @override
  String pidDetailHeaderDefault(String header) {
    return '默认 ($header)';
  }

  @override
  String get dtcSystemOverview => '系统总览';

  @override
  String get dtcPartialObservationBadge => '部分扫描';

  @override
  String get dtcPartialObservationBody => '此故障码已读取，但该类别在所有控制器间的扫描未完整完成。';

  @override
  String get dtcLinkedFreezeFrameTitle => '关联冻结帧';

  @override
  String get dtcNoLinkedFreezeFrame => '这次扫描没有可安全归属于此故障码与控制器的冻结帧。';

  @override
  String get performanceGuideTitle => '起步加速测试指南';

  @override
  String get performanceGuideStep1 => '1. 选择目标车速，然后准备计时';

  @override
  String get performanceGuideStep2 => '2. 将车辆完全停妥，等待画面显示已就绪';

  @override
  String get performanceGuideStep3 => '3. 开始加速；检测到起步后会自动开始计时';

  @override
  String get performanceGuideStep4 => '4. 到达目标车速后即完成本次计时';

  @override
  String get performanceRecordingTrace => '加速中... 正在记录速度点位';

  @override
  String get performanceNoAnalysisTitle => '没有分析数据';

  @override
  String get performanceNoAnalysisBody => '本次计时在取得足够的车速样本前已中止，因此未能产生速度轨迹或分段成绩。';

  @override
  String get connectActivityReconnectingAutomatically => '适配器停止回应，正在自动重新连接…';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get adapterErrorActivityAlert => '匯流排活動警示';

  @override
  String get adapterErrorBufferFull => '轉接器緩衝區溢位';

  @override
  String get adapterErrorBus => '匯流排錯誤，可能是接線問題';

  @override
  String get adapterErrorBusBusy => '匯流排忙碌';

  @override
  String get adapterErrorBusInit => '匯流排初始化失敗';

  @override
  String get adapterErrorCan => 'CAN 匯流排錯誤';

  @override
  String get adapterErrorData => '收到的資料不正確';

  @override
  String get adapterErrorFeedback => '訊號回授錯誤';

  @override
  String get adapterErrorInternal => '轉接器內部錯誤';

  @override
  String get adapterErrorLowPowerAlert => '轉接器即將進入低功耗模式';

  @override
  String get adapterErrorLowVoltageReset => '電壓過低導致轉接器重置';

  @override
  String get adapterErrorNoData => '沒有收到回應（可能是暫時無回應，或車輛不支援）';

  @override
  String get adapterErrorStopped => '傳輸被中斷';

  @override
  String get adapterErrorUnableToConnect => '無法與 ECU 通訊，請確認電門已開啟';

  @override
  String get adapterErrorUnknownCommand => '轉接器不支援此指令';

  @override
  String get appTagline => '車輛即時遙測';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => '外觀';

  @override
  String get connectActivityAbortingPreviousConnection => '正在中止上一個連線，請稍候…';

  @override
  String get connectAnswerBleWithClassic =>
      '選 Bluetooth LE。不需要事先配對，直接在 App 裡掃描 —— 就算它出現在系統的藍牙配對清單裡，也不要去配對，那條路走不通。如果掃描不到，那盒子上的 4.0 只是晶片規格，改用 Bluetooth Classic。';

  @override
  String get connectAnswerBleWithoutClassic =>
      '選 Bluetooth LE。不需要事先配對，直接在 App 裡掃描 —— 就算它出現在系統的藍牙配對清單裡，也不要去配對，那條路走不通。如果掃描不到，先確認轉接器有通電，或改試 Wi‑Fi；此主機未開放 Bluetooth Classic。';

  @override
  String get connectAnswerClassic =>
      '選 Bluetooth Classic。先在系統設定裡配對完成，App 不能代替你配對。配對碼多半是 1234 或 0000。';

  @override
  String get connectAnswerWifiDesktop => '選 Wi-Fi。先把這台裝置連上那個網路，再回來輸入位址。';

  @override
  String get connectAnswerWifiPhone => '選 Wi-Fi。先把手機連上那個網路，再回來輸入位址。';

  @override
  String get connectBleBody =>
      'BLE 轉接器不需事先配對。搜尋後選擇你的裝置即可，常見名稱為 OBDII、V-LINK、Vgate 或 IOS-Vlink。';

  @override
  String connectBleEmptyScan(String next) {
    return '搜尋結束，沒有找到 BLE 轉接器。依序確認：轉接器的燈有沒有亮 —— 多數 OBD 插座要電門轉到 ON 才供電；再來是距離，先坐進車裡再搜尋；${next}BLE 轉接器不需要、也不應該在系統設定裡配對，那條路走不通。';
  }

  @override
  String get connectBleEmptyScanNextClassic =>
      '最後看盒子上的規格，如果寫的是 2.0 或 3.0，那是 Bluetooth Classic，不會出現在這份清單裡，請改用上面的 Bluetooth Classic。';

  @override
  String get connectBleEmptyScanNextWifi =>
      '最後看盒子上的規格：若寫的是 2.0／3.0 或只有 Wi‑Fi，請改試 Wi‑Fi（此主機未開放 Bluetooth Classic）。';

  @override
  String get connectBlePermissionDeniedForever =>
      '藍牙權限已被永久拒絕。系統不會再顯示授權對話框，請到應用程式設定開啟。';

  @override
  String get connectBlePermissionNeeded => '需要藍牙權限才能搜尋。';

  @override
  String get connectBleScan => '搜尋 BLE 裝置';

  @override
  String get connectBleScanning => '搜尋中…';

  @override
  String get connectBleUnavailableHost => 'Bluetooth LE 在此主機尚不可用';

  @override
  String get connectBluetoothOff => '藍牙未開啟，請先在系統設定開啟藍牙。';

  @override
  String get connectBluetoothPermissionDeniedForever =>
      '藍牙權限已被永久拒絕，請到系統設定開啟後再試。';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      '需要藍牙權限才能列出已配對的轉接器。';

  @override
  String get connectBody => '插上 ELM327 轉接器並開啟電門，或直接使用內建模擬器體驗完整功能。';

  @override
  String get connectCancel => '取消';

  @override
  String get connectClassicEmptyLinuxPort =>
      '找不到藍牙序列埠（/dev/rfcomm*）。請先以 BlueZ 配對 ELM327，再用 rfcomm bind（或等效）建立 RFCOMM TTY 後重試。';

  @override
  String get connectClassicEmptyPaired =>
      '找不到已配對的轉接器。請先到系統藍牙設定完成配對（多數 ELM327 的配對碼為 1234 或 0000）。';

  @override
  String get connectClassicEmptyWindowsPort =>
      '找不到藍牙序列埠（COMx）。請先在 Windows 藍牙設定配對 ELM327，確認裝置管理員出現「Standard Serial over Bluetooth link」。';

  @override
  String get connectClassicListLinuxPort =>
      '這裡列出 BlueZ 已綁定的藍牙序列埠（/dev/rfcomm* 或等效）。空清單代表系統尚未建立 RFCOMM 節點，不是 App 壞掉。';

  @override
  String get connectClassicListPaired =>
      '這裡列出系統上所有已配對的裝置 — 耳機、喇叭也會在內，看起來像轉接器的排在前面。選錯了就按「取消」，不必等它自己失敗，取消後可以馬上改選別的。';

  @override
  String get connectClassicListWindowsPort =>
      '這裡列出與藍牙關聯的 COM 埠（「Standard Serial over Bluetooth link」）。空清單代表系統尚未建立虛擬序列埠，不是 App 壞掉。';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic（SPP）目前在 Android、macOS（IOBluetooth RFCOMM）、Windows（COM）與 Linux（/dev/rfcomm*）可用';

  @override
  String get connectClassicUnavailableIos => 'iOS 不開放第三方 App 使用藍牙 SPP';

  @override
  String get connectConnect => '連線';

  @override
  String get connectDemoBody =>
      '模擬一具 2.0L 渦輪四缸引擎，含怠速、加速、巡航與減速循環，訊號彼此物理相關（換檔時轉速下降但車速續增）。故障碼、VIN 讀取與 fastMode 批次查詢皆可完整操作。';

  @override
  String get connectDemoStart => '啟動模擬器';

  @override
  String get connectHandshakeTitle => 'ELM327 初始化';

  @override
  String get connectHandshakeTitleLastAttempt => 'ELM327 初始化（上次嘗試）';

  @override
  String get connectHeadline => '選擇連線方式';

  @override
  String get connectIssueAdapterAcceptedThenSilent =>
      '轉接器接受了連線，但在時限內沒有回應。通常是它還沒通電 —— 多數 OBD 插座要電門轉到 ON 才供電；也可能是它正被另一個 App 連著，先關掉那個再試。';

  @override
  String connectIssueAdapterSilentOnReset(String command) {
    return '轉接器沒有回應重置指令（$command）。這個裝置可能不是 ELM327 轉接器，或是連到了錯誤的裝置。';
  }

  @override
  String get connectIssueAdapterStoppedResponding => '轉接器停止回應，連線已中斷。';

  @override
  String get connectIssueConnectionSetupFailed =>
      '連線在建立過程中失敗了。請確認轉接器已通電、就在附近，然後再試一次。完整的錯誤留在下方的紀錄裡。';

  @override
  String get connectIssueHandshakeIncomplete => '初始化未通過，轉接器可能不相容。';

  @override
  String connectIssueHandshakeStepFailed(String command, String reason) {
    return '初始化在 $command 失敗（$reason）。請確認轉接器已插好、車輛電門已開啟。';
  }

  @override
  String get connectIssuePreviousConnectionStillAborting =>
      '上一個連線仍在中止中，轉接器還沒有釋放。請等幾秒再試一次。';

  @override
  String get connectLastAdapterConnect => '直接連線';

  @override
  String get connectLastAdapterForget => '忘記';

  @override
  String get connectLastAdapterTitle => '上次用的轉接器';

  @override
  String get connectOpenAppSettings => '開啟應用程式設定';

  @override
  String get connectOpenSystemSettings => '開啟系統設定';

  @override
  String get connectOpeningConnection => '建立連線中…';

  @override
  String get connectPairedPill => '已配對';

  @override
  String get connectQuestionBle => '盒子、賣場標題或裝置名稱上有 BLE、4.0、5.0 這些字？';

  @override
  String get connectQuestionClassic => '都不是 —— 比較舊、盒子上寫 2.0 或 3.0？';

  @override
  String get connectQuestionWifiDesktop =>
      '系統的 Wi-Fi 清單裡多出一個網路（像 V-LINK、WiFi_OBDII）？';

  @override
  String get connectQuestionWifiPhone =>
      '手機的 Wi-Fi 清單裡多出一個網路（像 V-LINK、WiFi_OBDII）？';

  @override
  String get connectSearchAgain => '重新搜尋';

  @override
  String connectSignalStrength(int bars, int total) {
    return '訊號強度 $bars/$total';
  }

  @override
  String get connectTranscriptKept => '這次嘗試的完整往返紀錄留著了。帶回來比一句訊息有用。';

  @override
  String get connectTransportBleDescription => 'GATT UART — 較新的低功耗轉接器';

  @override
  String get connectTransportBleTitle => 'Bluetooth LE';

  @override
  String get connectTransportClassicDescription =>
      'RFCOMM / SPP — 最常見的平價 ELM327';

  @override
  String get connectTransportClassicTitle => 'Bluetooth Classic';

  @override
  String get connectTransportDemoDescription => '內建模擬 ECU，無需硬體即可完整體驗';

  @override
  String get connectTransportDemoTitle => 'Demo 模擬器';

  @override
  String get connectTransportWifiDescription => 'TCP 通訊埠，多為 192.168.0.10:35000';

  @override
  String get connectTransportWifiTitle => 'Wi-Fi';

  @override
  String get connectWhichIntro => '不用管 SPP、GATT 這些名詞。看你的轉接器插上去之後怎麼運作就好：';

  @override
  String get connectWhichNoteGuessing =>
      '猜錯不會怎麼樣 —— 連不上就退回來換另一個試。真的卡住，先用最下面的「Demo 模擬器」確認 App 本身正常。';

  @override
  String get connectWhichNoteIos =>
      'iPhone 只能用 Wi-Fi 或 BLE —— 一般的藍牙 ELM327 在 iOS 上完全不能用，這是系統限制，換 App 也一樣。';

  @override
  String get connectWhichTitle => '不確定要選哪一個？';

  @override
  String get connectWifiHostLabel => 'IP 位址';

  @override
  String get connectWifiHostRequired => '請輸入轉接器的 IP 位址。';

  @override
  String get connectWifiInstructionsDesktop =>
      '請先將這台電腦連上轉接器發出的 Wi-Fi 熱點，再輸入其位址。系統若提示此網路無法連上網際網路，請選擇繼續使用。桌面系統通常會把熱點當預設路由；不需要 Android 那套 Wi-Fi 路由綁定。';

  @override
  String get connectWifiInstructionsPhone =>
      '請先將手機連上轉接器發出的 Wi-Fi 熱點，再輸入其位址。系統若問「此 Wi-Fi 無法連上網際網路，是否繼續使用」，選繼續使用。在 Android 上，App 連線時會嘗試把流量固定在 Wi-Fi 路由，避免被行動數據搶走。';

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '「$value」不是有效的通訊埠，範圍是 $min–$max。';
  }

  @override
  String get connectWifiPortLabel => '埠';

  @override
  String connectWifiPortRequired(int port) {
    return '請輸入通訊埠（多數轉接器為 $port）。';
  }

  @override
  String get dashboardBatchedPolling => '批次讀取';

  @override
  String get dashboardBatchingEnabled => '已啟用批次';

  @override
  String get dashboardChoosePids => '選擇 PID';

  @override
  String get dashboardEmptyBody => '到 PID 頁面挑選想要監看的訊號，它們會出現在這裡。';

  @override
  String get dashboardEmptyTitle => '儀表板是空的';

  @override
  String get dashboardGenericObd => '通用 OBD';

  @override
  String get dashboardLocalRecordings => '本機紀錄';

  @override
  String get dashboardNotConnected => '未連線';

  @override
  String get dashboardPollingModeHelpAction => '關於讀取模式';

  @override
  String get dashboardPollingModeHelpBatching =>
      '「已啟用批次」代表 Telltale 可以把多個 PID 請求併成一次交握，以減少來回次數：這條匯流排允許嘗試併批，而且併批沒有被關掉。它仍然是授權而不是量測，因為某一次交握到底有沒有併起來，還要看這輛車確認支援哪些 PID，以及當下排了幾筆。';

  @override
  String get dashboardPollingModeHelpObserved =>
      '「批次讀取」代表這次連線裡，有一筆 Mode 01 指令在線路上一次帶了超過一個 PID。那是對那一次交握的紀錄，不是下一筆也會併批的保證，也不是對吞吐量的主張。';

  @override
  String get dashboardPollingModeHelpRate =>
      'PIDs/s 是過去一秒觀測到的速率，不是對延遲、新鮮度或準確度的保證。它會隨轉接器、匯流排、ECU、你選的 PID、每次回覆的大小以及錯誤而變動。';

  @override
  String get dashboardPollingModeHelpSingle =>
      '「單筆模式」代表每個 Mode 01 PID 各自讀取。三種情況會用到它：匯流排根本不接受併批請求（所有非 CAN 車輛都是如此）；還沒有任何支援區塊回應過，因為把車輛尚未確認的 PID 併起來問，正是回覆會過短的原因；以及併批的請求沒有回來成一份能拆回各 PID 的答覆（被截斷、轉接器回報緩衝區已滿，或根本沒有回應）。讀數仍會持續更新，這本身不等於連線失敗。';

  @override
  String get dashboardPollingModeHelpTitle => '讀取模式';

  @override
  String get dashboardSingleRequestMode => '單筆模式';

  @override
  String get dashboardVinRead => '已讀 VIN';

  @override
  String get dashboardWorkspaceGauges => '儀表';

  @override
  String get dashboardWorkspaceTrends => '趨勢';

  @override
  String get datumBadgeCommunityDecode => '社群解碼';

  @override
  String get datumBadgeDemo => '示範';

  @override
  String get datumBadgeEstimated => '估算';

  @override
  String get datumBadgeExperimental => '實驗';

  @override
  String get datumBadgeFieldVerified => '已驗證';

  @override
  String get datumBadgeInvalid => '無效';

  @override
  String get datumBadgeJustUpdated => '剛更新';

  @override
  String get datumBadgeOutOfReferenceRange => '異常';

  @override
  String get datumBadgePartial => '部分';

  @override
  String get datumBadgeStale => '過期';

  @override
  String get datumBadgeTentativeDecode => '暫定解碼';

  @override
  String get datumBadgeUnverified => '未驗證';

  @override
  String get datumBadgeUnverifiedOnThisVehicle => '本車未驗證';

  @override
  String get datumBadgeUserSupplied => '使用者提供';

  @override
  String get datumGapModelYearUnknown => '年式未知';

  @override
  String get datumGapNoCatalogMatch => '型錄無匹配';

  @override
  String get datumGapVinNotRead => 'VIN 未讀到';

  @override
  String get datumNextStepEstimateOnly => '只影響此估算，其他讀值照用';

  @override
  String get datumNextStepGenericObd => '可繼續通用 OBD，或手動選車、補參數';

  @override
  String get datumNextStepOtherReadings => '失敗只影響此項，其他讀值照用';

  @override
  String get datumNextStepRawOnly => '可看 raw / error，不可當成正常數值';

  @override
  String get datumReasonAssumptionsUnconfirmed => '假設尚未確認，仍可估算';

  @override
  String get datumReasonBusError => '匯流排錯誤';

  @override
  String get datumReasonFormulaError => '公式錯誤';

  @override
  String get datumReasonFuelEstimateMissingInputs => '油耗缺少必要輸入';

  @override
  String get datumReasonHeaderNotOnThisBus => '標頭不符本車匯流排';

  @override
  String get datumReasonHorsepowerEstimateMissingInputs => '馬力缺少必要輸入';

  @override
  String get datumReasonMalformedPacket => '壞封包，只可查看原文';

  @override
  String get datumReasonNoAnswer => '無回應，稍後重試';

  @override
  String get datumReasonNoReadingYet => '尚無讀值';

  @override
  String get datumReasonNonFiniteValue => '非有限數值';

  @override
  String get datumReasonOutOfReferenceRangeKept => '超出一般參考範圍，已保留';

  @override
  String get datumReasonPidUnsupported => '此車輛不支援這個 PID';

  @override
  String get datumReasonUnsafeService => '此服務不是唯讀查詢';

  @override
  String get datumReasonUnsafeServiceStopped => '此服務不是唯讀查詢，已停止發送';

  @override
  String get datumStatusAssumptions => '假設';

  @override
  String get datumStatusClose => '關閉';

  @override
  String get datumStatusFollowsData => '狀態隨資料';

  @override
  String get datumStatusDetailsHint => '點按查看讀值狀態說明';

  @override
  String get datumStatusUnverifiedExplanation =>
      '未驗證表示此處沒有這個解碼與本車實際比對的驗證紀錄，不代表讀值錯誤，也不保證讀值準確。更新狀態與異常會另外標示。';

  @override
  String get datumStatusFormula => '公式';

  @override
  String get derivedAirflow => '空氣流量';

  @override
  String get derivedEcuFuelTitle => 'ECU 油耗資料';

  @override
  String get derivedEcuReported => 'ECU 回報';

  @override
  String get derivedEngineHorsepower => '引擎馬力';

  @override
  String get derivedEstimatedFuelTitle => '估算油耗';

  @override
  String get derivedEstimatesDetailsTitle => '估算公式與假設';

  @override
  String get derivedEstimatesTitle => '推算數值';

  @override
  String get derivedFuelUse => '油耗';

  @override
  String get derivedTorque => '扭力';

  @override
  String get derivedUnavailableMessage => '等待車速與加速度資料後才能推算馬力';

  @override
  String dtcBothSilentDetail(Object mode) {
    return '車輛沒有回應 Mode $mode 查詢，而 Mode 03 同樣沒有回應 — 因此無法判斷這是車輛不支援，還是這次連線沒有讀到。';
  }

  @override
  String dtcCategoryFault(Object category) {
    return '$category相關故障';
  }

  @override
  String get dtcClear => '清除';

  @override
  String get dtcClearCancel => '取消';

  @override
  String get dtcClearConfirm => '確定清除';

  @override
  String get dtcClearDialogBody =>
      '這會清掉已儲存與待確認的故障碼並熄滅故障燈，同時重置排放就緒狀態 — 車輛需要重新完成一輪自我診斷才能通過驗車。永久故障碼（Mode 0A）無法清除。';

  @override
  String get dtcClearDialogFrameUnread =>
      '這次沒有讀到凍結幀，但不代表車上沒有。先重新掃描一次，再決定要不要清除。';

  @override
  String dtcClearDialogFrames(Object codes) {
    return '連同 $codes 的凍結幀 —— 故障發生當下的轉速、水溫、負荷那一整份紀錄 —— 也會一起消失，而且故障再次發生前讀不回來。';
  }

  @override
  String get dtcClearDialogTitle => '清除故障碼？';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    return '這次掃描有 $count 個類別沒有得到完整回應（$categories），可能還有你沒看到的故障碼。清除後就再也讀不到了。';
  }

  @override
  String get dtcClearCancelledBeforeSend => '清除已取消，指令還沒送出到車上。可以重新掃描後再試一次。';

  @override
  String get dtcClearConfirmed => '已送出清除指令。';

  @override
  String get dtcClearFailureDoNotRepeat =>
      '清除指令可能已經送到車上。不要再送一次 —— 第二次全車清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認還剩下什麼。';

  @override
  String get dtcClearFailureGeneric => '清除沒有完成。請先重新掃描，看目前的故障碼，再決定要不要再試。';

  @override
  String get dtcClearNotAccepted => '清除失敗，沒有控制器接受指令。可以再試一次。';

  @override
  String get dtcClearPartiallyConfirmed =>
      '已有控制器回報清除完成，但其餘控制器無法確認。不要再送一次清除 —— 重複清除會讓已完成的控制器再一次重置排放就緒狀態。請重新掃描確認結果。';

  @override
  String get dtcClearPreviousConnectionUnconfirmed =>
      '上一次連線送出過清除指令，結果沒有確認。請先重新掃描，確認哪些故障碼還在，再決定要不要清除。';

  @override
  String get dtcClearRescanSettled => '上一次清除的結果無法完全確認，以下是重新掃描後的實際狀況。';

  @override
  String get dtcClearSentUnconfirmed =>
      '清除指令已送出，但回應在傳輸過程中損毀，無法確認車輛是否已清除。請重新掃描確認結果，不要直接再清除一次 —— 如果其實已經清除成功，再清一次會重置排放就緒狀態。';

  @override
  String get dtcClearTimeout => '清除指令送出後沒有回應，無法確認是否已清除。請重新掃描確認。不要直接再清除一次。';

  @override
  String get dtcClearUnexpected => '清除失敗，無法確認車輛是否已清除，請重新掃描確認。不要直接再清除一次。';

  @override
  String get dtcClearing => '清除中…';

  @override
  String get dtcScanDisconnectedMidScan => '連線在掃描途中中斷，這次掃描沒有完成。';

  @override
  String get dtcScanInterrupted =>
      '掃描在中途被中斷（可能是切換到其他 App 或連線變更），沒有得到完整結果。請重新掃描。';

  @override
  String get dtcCompleteCleanBody => '這代表每個回覆的控制器都回報無故障碼，不代表車上每個模組都已被問到。';

  @override
  String get dtcCompleteCleanTitle => '已回應的控制器都沒有故障碼。';

  @override
  String dtcControllerLabel(Object controller) {
    return '控制器 $controller';
  }

  @override
  String get dtcDismiss => '關閉';

  @override
  String dtcFreezeFrameBody(Object code) {
    return '$code 被確認的那一刻，這個控制器記下的數值。清除故障碼會一併銷毀這份紀錄。';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      '這個控制器有凍結幀，但沒有回應「裡面有哪些項目」的查詢，所以讀不到內容。可以重新掃描再試一次。';

  @override
  String get dtcFreezeFrameNothingDecodable => '這個控制器有凍結幀，但其中沒有本 App 能解讀的項目。';

  @override
  String get dtcFreezeFrameTitle => '故障發生當下的車況';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    return '另有 $count 個項目在這份凍結幀裡，本 App 沒有對應的換算公式，所以沒有列出。';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    return '有 $count 個項目這次沒有讀回來（可能是時間不夠或控制器沒回應）。重新掃描可能會讀到。';
  }

  @override
  String get dtcFreezeFrameUnreadPanel =>
      '這次沒有讀到凍結幀 —— 不代表車上沒有。請先重新掃描再決定要不要清除故障碼，因為清除會永久銷毀故障當下的紀錄。如果每次掃描都一樣，可能是這台車不提供。';

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label（Mode $mode）· $count';
  }

  @override
  String get dtcHeadline => '故障碼';

  @override
  String get dtcListSeparator => '、';

  @override
  String get dtcManufacturerSpecific => '原廠自訂碼 — 需查閱該車系維修手冊';

  @override
  String get dtcMilOff => '故障燈沒有亮';

  @override
  String get dtcMilOn => '故障燈亮著';

  @override
  String get dtcMonitorBoostPressure => '增壓壓力';

  @override
  String get dtcMonitorCatalyst => '觸媒轉換器';

  @override
  String get dtcMonitorComponents => '綜合元件監控';

  @override
  String get dtcMonitorEgr => 'EGR / VVT 系統';

  @override
  String get dtcMonitorEvaporative => '蒸發排放系統';

  @override
  String get dtcMonitorExhaustSensor => '排氣感知器';

  @override
  String get dtcMonitorFuelSystem => '燃油系統監控';

  @override
  String get dtcMonitorGasolineParticulateFilter => '汽油微粒濾清器（GPF）';

  @override
  String get dtcMonitorHeatedCatalyst => '觸媒加熱';

  @override
  String get dtcMonitorMisfire => '失火監控';

  @override
  String get dtcMonitorNmhcCatalyst => 'NMHC 觸媒';

  @override
  String get dtcMonitorNoxAftertreatment => 'NOx / SCR 後處理';

  @override
  String get dtcMonitorOxygenSensor => '含氧感知器';

  @override
  String get dtcMonitorOxygenSensorHeater => '含氧感知器加熱';

  @override
  String get dtcMonitorParticulateFilter => '微粒濾清器';

  @override
  String get dtcMonitorSecondaryAir => '二次空氣噴射';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — 本 App 沒有這一碼的詳細說明';
  }

  @override
  String get dtcNotConnectedBody => '需要連上 ELM327 轉接器或啟動模擬器才能讀取故障碼。';

  @override
  String get dtcNotConnectedTitle => '尚未連線';

  @override
  String get dtcNotScanned => '尚未掃描';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    return '三個類別都查詢完成了。有 $count 個控制器（$controllers）沒有實作待確認或永久故障碼 —— 這在很多車上是正常的，但也因此不能宣告全車都沒有故障碼。';
  }

  @override
  String get dtcPartialCleanTitle => '已回應的項目沒有故障碼。';

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories 沒有回應，狀態無法確認 — 這不等於車輛沒有問題。';
  }

  @override
  String dtcPartialCodesRead(int count) {
    return '這個類別中止前已讀到 $count 筆故障碼，但涵蓋範圍不完整：';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return '這個類別只有部分控制器回應，其餘沒有回覆，因此不能當作全車的結果。$message';
  }

  @override
  String get dtcReadFailed => '讀取失敗';

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label（Mode $mode）：$message';
  }

  @override
  String get dtcReadinessAllComplete => '這個控制器負責的監控項目都已完成。';

  @override
  String dtcReadinessIncomplete(int count) {
    return '還有 $count 項沒有完成，現在去驗車可能不會過。';
  }

  @override
  String get dtcReadinessSaysNothing =>
      '這個控制器沒有回報任何監控項目 —— 它可能不負責排放監控，這不代表已經就緒。';

  @override
  String get dtcReadinessTitle => '排放就緒狀態';

  @override
  String get dtcRescanFirst => '請先重新掃描';

  @override
  String get dtcRetry => '重試';

  @override
  String get dtcScanBody => '讀取 Mode 03 已儲存、Mode 07 待確認與 Mode 0A 永久故障碼。';

  @override
  String get dtcScanTitle => '掃描車輛故障碼';

  @override
  String get dtcScanning => '掃描中…';

  @override
  String dtcSelfReportedCodes(int count) {
    return '這個控制器自報有 $count 個已確認的故障碼。';
  }

  @override
  String get dtcSelfReportedNoCodes => '這個控制器自報沒有已確認的故障碼。';

  @override
  String get dtcSilentCategoryHeadline => '這個類別沒有回應';

  @override
  String get dtcSilentPendingDetail =>
      '待確認故障碼（Mode 07）沒有回應。可能是這具 ECU 未實作這個服務，也可能是這次沒有讀到 —— 沒有回應無法分辨兩者，也不能當作「沒有待確認故障」。已儲存故障碼的結果不受影響。';

  @override
  String get dtcSilentPermanentDetail =>
      '永久故障碼（Mode 0A）沒有回應。這個類別在 2010 年前後才隨新一代 OBD-II 導入，較舊的車輛不一定支援 —— 但沒有回應也可能只是這次沒讀到，兩者無法分辨。已儲存故障碼的結果不受影響。';

  @override
  String get dtcStartScan => '開始掃描';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return '車輛沒有回應 Mode $mode 查詢，因此無法確認是否有已儲存的故障碼。這與「沒有故障碼」不是同一件事。';
  }

  @override
  String dtcTotalCodes(int count) {
    return '共 $count 筆';
  }

  @override
  String get dtcUnconfirmed => '無法確認';

  @override
  String get dtcUnknownError => '未知錯誤';

  @override
  String get dtcUnknownMonitor => '未知監控項目';

  @override
  String get dtcVerdictCompleteClean => '已回應的控制器沒有故障碼';

  @override
  String get dtcVerdictPartialClean => '部分未確認';

  @override
  String get fieldEventBody =>
      '只在車輛完全停妥時，由乘客或停車中的操作人員按下。事件會與 OBD 原始資料使用同一條時間軸並嘗試立即保存。';

  @override
  String get fieldEventEngineStarted => '引擎發動';

  @override
  String get fieldEventHeading => '實車事件標記';

  @override
  String get fieldEventIgnitionOn => '電門 ON';

  @override
  String get fieldEventMemoryOnly => '已記在目前工作階段，但自動保存失敗；請立刻匯出紀錄。';

  @override
  String fieldEventRecorded(String marker) {
    return '已記錄並保存：$marker';
  }

  @override
  String get fieldEventRoadTestStarted => '道路測試開始';

  @override
  String get fieldEventThrottleBlip => '輕踩油門';

  @override
  String get fieldEventUnavailable => '目前沒有可記錄的實車連線。';

  @override
  String get gaugeNoData => '無資料';

  @override
  String gaugeNoDataBecause(String reason) {
    return '無資料 — $reason';
  }

  @override
  String gaugeReadingStale(String reading) {
    return '$reading（資料已過期）';
  }

  @override
  String get gaugeUnsupportedByVehicle => '此車輛不支援';

  @override
  String get handshakeNoteAborted => '已中止';

  @override
  String get handshakeNoteEcuRefusedSupportQuery =>
      'ECU 拒絕了支援度查詢（negative response）';

  @override
  String get handshakeNoteEcuSilent => 'ECU 沒有回應';

  @override
  String get handshakeNoteNotAcknowledged => '轉接器未確認此指令';

  @override
  String get handshakeNoteNotModeOnePositiveReply => '回應不是 Mode 01 的正向回覆';

  @override
  String get handshakeNotePidEchoMismatch => '回應的 PID 與查詢不符';

  @override
  String get handshakeNoteSupportMaskTooShort => '支援度回應過短（需要 41 00 加四個位元組）';

  @override
  String get handshakeNoteTimedOut => '逾時';

  @override
  String get handshakeStepAdapterVersion => '讀取轉接器版本';

  @override
  String get handshakeStepAdaptiveTiming => '啟用自適應計時（datasheet 建議值）';

  @override
  String get handshakeStepBatteryVoltage => '讀取電瓶電壓';

  @override
  String get handshakeStepDeviceIdentity => '讀取裝置識別字串';

  @override
  String get handshakeStepEchoOff => '關閉指令回音';

  @override
  String get handshakeStepLinefeedsOff => '關閉換行字元';

  @override
  String get handshakeStepMemoryOff => '關閉記憶體寫入';

  @override
  String get handshakeStepNoReason => '無回應';

  @override
  String get handshakeStepProtocolAuto => '自動偵測匯流排協定';

  @override
  String get handshakeStepProtocolDescription => '讀取協定描述';

  @override
  String get handshakeStepProtocolNumber => '讀取協定編號';

  @override
  String get handshakeStepReset => '軟體重置轉接器';

  @override
  String get handshakeStepResponseTimeout => '設定回應逾時 ~408ms';

  @override
  String get handshakeStepSpacesOff => '關閉空白字元，減少 33% 傳輸量';

  @override
  String get handshakeStepSupportProbe => '查詢 ECU 支援的 PID（確認車輛已回應）';

  @override
  String get languageSaveFailed => '無法儲存語言設定，請再試一次。';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get navDashboard => '儀表板';

  @override
  String get navDtc => '故障碼';

  @override
  String get navPerformance => '性能';

  @override
  String get navPid => 'PID';

  @override
  String get navSettings => '設定';

  @override
  String get performanceArm => '準備計時';

  @override
  String get performanceDisclaimer =>
      '成績以 OBD 車速訊號為準。多數車輛的車速表本身有 1–3 km/h 的正偏差，且訊號更新率約每秒 10–20 次，因此結果僅供參考，不等同於專業測試設備。';

  @override
  String get performanceHeadline => '加速測試';

  @override
  String get performanceNoSpeedSignal => '目前沒有有效的車速訊號（PID 010D）。加速測試需要它才能計時。';

  @override
  String get performanceNotConnectedBody => '加速測試需要即時車速資料，請先連線或啟動模擬器。';

  @override
  String get performanceNotConnectedTitle => '尚未連線';

  @override
  String get performancePeakSpeed => '最高車速';

  @override
  String get performanceReset => '重置';

  @override
  String get performanceSecondsUnit => '秒';

  @override
  String get performanceSpeedGaugeLabel => '車速';

  @override
  String get performanceSpeedTraceHeading => '速度軌跡';

  @override
  String get performanceSplitsHeading => '分段成績';

  @override
  String get performanceStateAborted => '這次計時未完成，以下為中止前的紀錄';

  @override
  String get performanceStateAwaitingSpeedSignal => '等待車速訊號';

  @override
  String performanceStateAwaitingStandstill(String speed) {
    return '請先完全停車 — 目前 $speed km/h';
  }

  @override
  String performanceStateFinished(int target) {
    return '完成 0 → $target km/h';
  }

  @override
  String get performanceStateIdle => '選擇目標車速後開始';

  @override
  String get performanceStateRunning => '計時中';

  @override
  String get performanceStateStaged => '已就緒 — 起步即開始計時';

  @override
  String get performanceSubhead => '由靜止起步計時至目標車速';

  @override
  String get performanceTargetSpeedHeading => '目標車速';

  @override
  String get pidActionCancel => '取消';

  @override
  String get pidActionDelete => '刪除';

  @override
  String get pidArrangeBody => '拖曳調整順序。儀表板由左至右、由上而下填滿，排在前面的最先看到。';

  @override
  String get pidArrangeEmptyMessage => '先在清單中啟用幾項，再回來排列順序。';

  @override
  String get pidArrangeEmptyTitle => '還沒有啟用任何 PID';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return '加入已確認的 $count 項';
  }

  @override
  String get pidBulkActionAllActive => '已全部啟用';

  @override
  String get pidBulkActionIncomplete => '掃描資料不完整';

  @override
  String get pidBulkActionLocked => '錄製中無法變更';

  @override
  String get pidBulkActionPending => '等待掃描結果';

  @override
  String get pidBulkActionZero => '沒有確認支援項目';

  @override
  String pidBulkAddCount(int count) {
    return '加入 $count 項';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return '加入 $count 項已確認支援 PID？';
  }

  @override
  String pidBulkAdded(int count) {
    return '已加入 $count 項已確認支援 PID。';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '仍有 $count 個支援區塊未確認，這次只加入已有正面證據的項目。';
  }

  @override
  String pidBulkWillAdd(int count) {
    return '將加入 $count 項。啟用越多 PID，單項資料的更新頻率可能降低。';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '確認 $confirmed 項';
  }

  @override
  String get pidCapabilityCoverageNone => '連續涵蓋尚未建立';

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return '連續涵蓋 01–$through（已到終點）';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return '連續涵蓋 01–$through（後續未知）';
  }

  @override
  String get pidCapabilityPhaseAttemptFinished => '本次支援掃描已完成';

  @override
  String get pidCapabilityPhaseInterrupted => '支援掃描已中斷';

  @override
  String get pidCapabilityPhaseNotStarted => '尚未開始掃描';

  @override
  String get pidCapabilityPhaseRunning => '正在確認車輛支援項目';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return '車輛支援 PID。$phase。確認 $confirmed 項。未知區塊 $unknown 個。';
  }

  @override
  String get pidCapabilityTitle => '車輛支援 PID';

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '未知區塊 $unknown';
  }

  @override
  String pidEditorCollision(String name) {
    return '已經有一個自訂 PID 使用這組設定（$name）。請改用不同的模式 + PID、標頭或名稱後綴。';
  }

  @override
  String pidEditorDeleteBody(String name) {
    return '「$name」的定義會被移除，儀表板上的這個錶也會一起消失，而且無法復原。';
  }

  @override
  String get pidEditorDeleteTitle => '刪除這個 PID？';

  @override
  String get pidEditorDiscard => '放棄';

  @override
  String get pidEditorDiscardBody => '這個 PID 的修改還沒有儲存，離開後會遺失。';

  @override
  String get pidEditorDiscardTitle => '放棄未儲存的變更？';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N 對應回應位元組；可用 SIGNED()、ABS()、LOG10()、$valSyntax、BARO';
  }

  @override
  String get pidEditorFieldEquation => '運算式';

  @override
  String get pidEditorFieldHeader => 'CAN 標頭';

  @override
  String get pidEditorFieldMax => '最大值';

  @override
  String get pidEditorFieldMin => '最小值';

  @override
  String get pidEditorFieldModeAndPid => '模式 + PID';

  @override
  String get pidEditorFieldName => '名稱';

  @override
  String get pidEditorFieldSample => '測試用回應位元組';

  @override
  String get pidEditorFieldShortName => '簡稱（顯示於錶面）';

  @override
  String get pidEditorFieldUnits => '單位';

  @override
  String get pidEditorHeaderHelper => '7E0 = 引擎';

  @override
  String get pidEditorKeepEditing => '繼續編輯';

  @override
  String get pidEditorModeAndPidHelper => '例如 010C 或 221101';

  @override
  String get pidEditorSampleHelper => '輸入十六進位，即時預覽計算結果';

  @override
  String get pidEditorSave => '儲存';

  @override
  String get pidEditorSectionFormula => '公式';

  @override
  String get pidEditorSectionIdentity => '識別';

  @override
  String get pidEditorSectionQuery => '查詢';

  @override
  String get pidEditorSectionRangeAndPriority => '錶面範圍與優先權';

  @override
  String get pidEditorTitleEdit => '編輯 PID';

  @override
  String get pidEditorTitleNew => '新增自訂 PID';

  @override
  String pidExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String get pidExportNoCustomPids => '目前沒有自訂 PID 可匯出。';

  @override
  String get pidImportNothingToImport => '沒有可匯入的定義。';

  @override
  String pidImportLandedClean(int count) {
    return '已匯入 $count 項自訂 PID。';
  }

  @override
  String pidImportLandedWithNotes(int count, String notes) {
    return '匯入 $count 項，$notes。';
  }

  @override
  String pidImportNoteSkippedRows(int count) {
    return '$count 行有問題已略過';
  }

  @override
  String pidImportNoteDefaultedRanges(int count) {
    return '$count 行套用了預設量程';
  }

  @override
  String pidImportNoteReplaced(int count) {
    return '$count 項覆蓋了現有定義';
  }

  @override
  String pidImportNoteDuplicatesInFile(int count) {
    return '$count 行與檔案內其他行重複已略過';
  }

  @override
  String get pidImportPickerFailed => '無法開啟檔案選擇器。';

  @override
  String get pidImportReadFailed => '讀取檔案失敗。';

  @override
  String get pidListSeparator => '、';

  @override
  String get pidManagerActiveOnly => '只顯示已啟用';

  @override
  String get pidManagerAdd => '新增';

  @override
  String get pidManagerArrangeDashboard => '排列儀表板';

  @override
  String pidManagerCounts(int active, int total) {
    return '已啟用 $active 項 · 共 $total 項可用';
  }

  @override
  String get pidManagerExportCsv => '匯出自訂 PID';

  @override
  String get pidManagerExportTorqueCsv => '匯出 Torque 相容 CSV';

  @override
  String get pidManagerExportHumanReport => '匯出人類可讀 PID 報表';

  @override
  String get pidManagerHeadline => 'PID 管理';

  @override
  String get pidManagerImportCsv => '匯入 CSV';

  @override
  String get pidManagerMoreActions => '更多';

  @override
  String get pidManagerNoMatchMessage => '換個關鍵字，或建立一個自訂 PID。';

  @override
  String get pidManagerNoMatchTitle => '沒有符合的 PID';

  @override
  String get pidManagerPowertrainBatteryCatalog => '大電池目錄';

  @override
  String get pidManagerSearchHint => '搜尋名稱或 PID 代碼…';

  @override
  String get pidPickCsvDialogTitle => '選擇 PID 定義 CSV';

  @override
  String get pidPillCustom => '自訂';

  @override
  String get pidPillUnsupported => '不支援';

  @override
  String get pidPreviewCannotEvaluate => '無法計算';

  @override
  String get pidPreviewResultLabel => '計算結果';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '預覽時以 $valueString 代入 $dependencies；實際數值會在連線後由該 PID 提供。';
  }

  @override
  String get pidPreviewTitle => '即時預覽';

  @override
  String get pidPriorityHigh => '高';

  @override
  String get pidPriorityLow => '低';

  @override
  String get pidPriorityMedium => '中';

  @override
  String get pidPriorityVeryLow => '極低';

  @override
  String get pidRowEdit => '編輯';

  @override
  String pidRowShowOnDashboard(String name) {
    return '在儀表板顯示 $name';
  }

  @override
  String pidRowStaleUnits(String units) {
    return '$units · 已過期';
  }

  @override
  String powertrainAuthorizationGranted(String profile) {
    return '已啟用 $profile 的電池訊號（本次連線）';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return '無法啟用：$reason';
  }

  @override
  String get powertrainCancel => '取消';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return '$profiles 個車型 · $probeable 個可單次讀取';
  }

  @override
  String get powertrainCatalogLoadFailedBody => '完整性驗證沒有通過，因此沒有顯示或安裝任何車型資料。';

  @override
  String get powertrainCatalogLoadFailedTitle => '離線目錄無法載入';

  @override
  String get powertrainCatalogNotVerified => '目錄尚未通過驗證，無法安裝。';

  @override
  String get powertrainCatalogRevalidate => '重新驗證';

  @override
  String get powertrainCatalogScopeNote =>
      '目錄很廣，但「找到資料」不等於「已支援」。僅研究項目永遠沒有指令。Mode 22 實驗項目可安裝並輪詢，但每個數值都標為未驗證；Mode 21 實驗項目每次確認後只讀一次。';

  @override
  String get powertrainCatalogSearchHint => '搜尋品牌、車型、版本或市場…';

  @override
  String get powertrainCatalogTitle => '大電池車型目錄';

  @override
  String get powertrainChooseCommandNote => '每次只送一條，不掃描、不批次、不自動重試。';

  @override
  String get powertrainChooseCommandTitle => '選擇一條固定唯讀查詢';

  @override
  String get powertrainClose => '關閉';

  @override
  String get powertrainConfirmAccept => '就是這台車';

  @override
  String get powertrainConfirmBody =>
      '已安裝的車型訊號要先確認這台車就是該車型，本次連線才會開始讀取。確認只對這次連線有效。';

  @override
  String get powertrainConfirmButton => '確認車輛';

  @override
  String get powertrainConfirmDialogBody =>
      '確認後，這個車型的唯讀電池查詢會在本次連線內定期輪詢。接錯車型可能得到看似合理但錯誤的數字——不確定就取消。';

  @override
  String get powertrainConfirmDialogTitle => '確認連線中的車輛';

  @override
  String get powertrainConfirmTitle => '車輛電池訊號待確認';

  @override
  String get powertrainConnectFirst => '請先連線；實驗授權不會跨連線保留。';

  @override
  String get powertrainConnectionChanged => '連線已改變，請對新的連線重新確認車輛。';

  @override
  String get powertrainEnableLabInSettings => '請先到設定開啟「大電池證據實驗室」。';

  @override
  String get powertrainEvidencePhysicalVehicle => '專案實車';

  @override
  String get powertrainEvidenceSourceBacked => '來源資料';

  @override
  String get powertrainEvidenceSyntheticRig => '合成測試台';

  @override
  String get powertrainExperimentalDataDisclosure =>
      '這是來源作者標示的候選讀取，不是原廠或跨車款安全保證；ELM327 只負責轉送命令。原始指令與回覆會留在本機診斷紀錄，不會由此功能自動上傳；解碼值不會安裝成 PID 或加入儀表。取消不影響一般 OBD 功能。';

  @override
  String get powertrainExperimentalDialogTitle => '單次實驗唯讀確認';

  @override
  String get powertrainExperimentalIdentityAck => '我已核對來源已知的市場、車型與年式，並接受未證實欄位';

  @override
  String get powertrainExperimentalParkedAck => '車輛已安全停妥；我知道這只讀一次，數字仍可能不適用';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return '只接受 RX $responder，資料長度 $bytes bytes';
  }

  @override
  String get powertrainFieldListSeparator => '、';

  @override
  String get powertrainFieldMarket => '市場';

  @override
  String get powertrainFieldModel => '車型';

  @override
  String get powertrainFieldModelYear => '年式';

  @override
  String get powertrainFieldVariant => '版本';

  @override
  String get powertrainFilterAll => '全部';

  @override
  String get powertrainIdentityEvidenceExact => '直接證據';

  @override
  String get powertrainIdentityEvidenceNone => '無';

  @override
  String get powertrainIdentityEvidenceSourcePartial => '部分證據';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return '來源身分證據：$fields\n未證實欄位：$unconfirmed';
  }

  @override
  String get powertrainIdentityEvidenceUnknown => '未知';

  @override
  String get powertrainInstallButton => '安裝電池訊號';

  @override
  String get powertrainInstallConfirm => '安裝';

  @override
  String get powertrainInstallDialogTitle => '安裝車型電池訊號';

  @override
  String get powertrainInstallDisclosureCommunity =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。資料來自社群來源並經獨立比對，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureExperimental =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。這是實驗解碼，沒有獨立佐證要求，本車未驗證，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureReady =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。來源資料較完整，仍非原廠保證。';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      '安裝只是把唯讀電池 PID 加進 PID 管理。開始讀取前，每次連線都要在儀表板確認「這台車就是這個車型」。此列僅供研究，不應安裝。';

  @override
  String get powertrainInstallCatalogShaMissing =>
      '無法安裝：這份目錄快照沒有已驗證的 SHA-256，因此其中任何內容都不能信任。';

  @override
  String get powertrainInstallPersistFailed =>
      '無法安裝：已安裝設定檔清單無法寫入。請再試一次；PID 管理沒有新增任何項目。';

  @override
  String get powertrainInstallProfileNotInCatalog => '無法安裝：這個設定檔不在已驗證的目錄中。';

  @override
  String get powertrainInstallProfileNotInstallable =>
      '無法安裝：這個設定檔目前不能變成實際的 PID。';

  @override
  String get powertrainInstallYearOutOfRange => '無法安裝：該年式不在這個設定檔記載的年份範圍內。';

  @override
  String get powertrainInstallIdentityAck => '我的車輛符合上述市場、車型與年式';

  @override
  String get powertrainInstalledRemoveButton => '已安裝 · 移除訊號';

  @override
  String powertrainInstalledSignalsSnack(int count) {
    return '已安裝 $count 個訊號。到 PID 頁面加入儀表板；每次連線需確認車輛。';
  }

  @override
  String get powertrainNoMatchBody => '改用品牌、車型名稱，或切換其他動力型式。';

  @override
  String get powertrainNoMatchTitle => '沒有符合的車型';

  @override
  String get powertrainNotInstallableInThisRelease => '此版本不可安裝';

  @override
  String powertrainPrimarySource(String name, String license) {
    return '主要來源：$name（$license）';
  }

  @override
  String get powertrainProbeChecksPassed =>
      '已通過 responder、echo、exact length、公式與範圍檢查。';

  @override
  String get powertrainProbeConnectForOneShot => '連線後單次唯讀';

  @override
  String get powertrainProbeConnectToTryOnce => '連線後可先單次試讀';

  @override
  String get powertrainProbeDidNotFinish => '單次查詢沒有完成；沒有發布或保留數值。';

  @override
  String get powertrainProbeEnableLabFirst => '先在設定開啟實驗室';

  @override
  String get powertrainProbeInProgress => '單次查詢中…';

  @override
  String get powertrainProbeNoValuePublished => '沒有發布數值；結構或解碼錯誤會隔離到重新連線。';

  @override
  String get powertrainProbeOnceButton => '只讀這一次';

  @override
  String get powertrainProbePassedTitle => '單次查詢通過';

  @override
  String get powertrainProbePickOneRead => '選一條，唯讀一次';

  @override
  String get powertrainProbeReconnectFirst => '重新連線後再試';

  @override
  String get powertrainProbeRefusedTitle => '單次查詢已拒絕';

  @override
  String get powertrainProbeTryOnceFirst => '先試讀一次';

  @override
  String get powertrainProfileNotVerified => '設定檔不在已驗證目錄中';

  @override
  String get powertrainQuarantinedPill => '本次連線已隔離';

  @override
  String get powertrainRefusedCatalogHashInvalid =>
      '未授權：目錄的完整性雜湊無效，因此其中任何內容都不能讀取。';

  @override
  String get powertrainRefusedCommandNotInProfile =>
      '未授權：這個指令不屬於這份已驗證設定檔本身的指令。';

  @override
  String get powertrainRefusedLabClosed => '在這次讀取取得授權之前，大電池證據實驗室已被關閉。';

  @override
  String get powertrainRefusedProfileFailedValidation =>
      '未授權：這個設定檔沒有通過你所選車輛年份的目錄驗證。';

  @override
  String get powertrainRefusedProfileNotInCatalog => '未授權：這個設定檔不在已驗證的目錄中。';

  @override
  String get powertrainRefusedProfileNotProbeable => '未授權：這個設定檔不是可以單次實驗讀取的設定檔。';

  @override
  String get powertrainRefusedQuarantinedAfterRejectedRead =>
      '本次連線已隔離：先前一次單次讀取沒有通過結構檢查。請重新連線後再試。';

  @override
  String get powertrainRefusedNotConnectedOrNotInForeground =>
      '這次單次讀取沒有開始：目前沒有連線，或 App 不在前景。';

  @override
  String get powertrainRefusedNoLiveAuthorization =>
      '這次單次讀取沒有開始：目前沒有持有單次授權。授權不存在、已過期、冷卻中或已被隔離。';

  @override
  String get powertrainRefusedDiscardedAtLifecycleBoundary =>
      '單次讀取進行中，連線或前景狀態改變了，因此它的結果被丟棄而沒有顯示。沒有任何失敗，也沒有保留任何結果。';

  @override
  String powertrainRefusedQuarantinedAtAttemptCap(int attemptCap) {
    return '本次連線已隔離：同一個指令已經嘗試 $attemptCap 次。請重新連線後再試。';
  }

  @override
  String get powertrainResearchOnlyNeverQueries => '僅研究，不會查詢';

  @override
  String get powertrainRestoreStorageErrorRetry => '還原先前安裝時發生儲存錯誤，已重新排程，請再試一次。';

  @override
  String powertrainSecondarySource(String name, String license) {
    return '獨立佐證：$name（$license）';
  }

  @override
  String powertrainSignalCount(int count) {
    return '$count 個訊號';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return '來源檔 SHA-256：$hash…';
  }

  @override
  String get powertrainStatusCommunity => '社群資料 · 未驗證';

  @override
  String get powertrainStatusExperimental => '實驗 · 未驗證';

  @override
  String get powertrainStatusExperimentalProbeOnly => '實驗單次唯讀';

  @override
  String get powertrainStatusReady => '來源較完整';

  @override
  String get powertrainStatusResearchOnly => '僅研究';

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return '已移除 $name 的已安裝訊號。';
  }

  @override
  String powertrainVehicleYearFixed(int year) {
    return '車輛年式：$year';
  }

  @override
  String get powertrainVehicleYearLabel => '車輛年式';

  @override
  String get recommendedPurchaseDisclosure =>
      '這是維護者的推廣分潤連結；符合條件的購買可能產生佣金。不是轉接器認證或購買保證。賣場內容與硬體版本可能變更，購買前請核對完整型號與 NCC 號碼。你也可以自行搜尋其他通路。';

  @override
  String get recommendedPurchaseHeading => '推薦轉接器';

  @override
  String recommendedPurchaseModelLine(String model, String approval) {
    return '型號 $model · NCC $approval';
  }

  @override
  String recommendedPurchaseNoAdapterYet(String store) {
    return '還沒有轉接器？在$store看推薦款';
  }

  @override
  String recommendedPurchaseOpenFailed(String store) {
    return '無法開啟$store連結';
  }

  @override
  String get recommendedPurchaseShortDisclosureAction => '完整說明在設定';

  @override
  String get recommendedPurchaseShortDisclosureLead => '這是推廣分潤連結，不是轉接器認證。';

  @override
  String get recommendedPurchaseStoreShopee => '蝦皮';

  @override
  String recommendedPurchaseViewOnStore(String store) {
    return '在$store查看';
  }

  @override
  String get semanticsFieldSeparator => '，';

  @override
  String get settingsAdapterConcernsFooter =>
      '這些是轉接器對自己的描述對不起來，不是它讀錯了車。要確認數值，只能拿第二個獨立量測去對（見速查表）。';

  @override
  String get settingsAdapterNoContradictions =>
      '沒有發現自述矛盾。這只表示它對自己的描述前後一致 —— 既不代表它是原廠晶片，也不代表它回報的數值正確。版本號在仿製品上就是一段可以任意填的文字。';

  @override
  String get settingsAdapterNoVersion => '（未回報版本）';

  @override
  String get settingsAdapterSelfReportTitle => '轉接器自述';

  @override
  String get settingsBatteryLabDialogBody =>
      '這些是逆向工程來源的候選資料，不是原廠文件，也不是 Telltale 實車支援。即使是唯讀查詢也可能喚醒控制器；解碼後的數字可能看似合理但其實不適用。';

  @override
  String get settingsBatteryLabDialogTitle => '開啟大電池證據實驗室';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      '本次執行已關閉大電池實驗功能，但無法儲存設定；下次啟動可能再顯示實驗入口，每條查詢仍需重新確認。';

  @override
  String get settingsBatteryLabEnableNotSaved => '無法儲存大電池實驗功能設定，功能維持關閉。';

  @override
  String get settingsBatteryLabEvidenceAck => '我知道來源資料與合成測試不能證明我的實車適用';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      '只顯示來源完整、受雜湊約束的單次唯讀查詢。不會自動安裝 PID、輪詢、加入儀表或把研究資料當成支援。';

  @override
  String get settingsBatteryLabSwitchTitle => '大電池證據實驗室（實驗）';

  @override
  String get settingsBatteryLabUnlockReadOnly => '只解鎖單次唯讀查詢';

  @override
  String get settingsBatteryLabWireAck =>
      '我知道只會解鎖目錄內固定 Mode 21/22 的單次查詢；不會解鎖掃描、診斷 session、安全存取、寫入或控制';

  @override
  String get settingsCancel => '取消';

  @override
  String get settingsCatalogChoose => '從官方目錄選擇';

  @override
  String get settingsCatalogCorrupt => '官方離線目錄損壞或無法載入，沒有套用任何資料。';

  @override
  String get settingsCatalogNothingApplicable =>
      '這筆官方配置沒有可安全套用到目前公式的欄位，原設定保持不變。';

  @override
  String get settingsCatalogScope =>
      '官方目錄：美國 EPA、臺灣經濟部能源署、加拿大 NRCan。各快照只代表該市場，不是全球所有品牌或年式。';

  @override
  String get settingsCatalogVerifying => '驗證離線目錄中…';

  @override
  String get settingsCatalogChooseMarket => '選擇要瀏覽的官方目錄';

  @override
  String get settingsCatalogMarketTw => '臺灣（經濟部能源署）';

  @override
  String get settingsCatalogMarketUs => '美國（EPA）';

  @override
  String get settingsTwCertificationYear => '核發年份';

  @override
  String get settingsTwMake => '臺灣廠牌';

  @override
  String settingsTwPickerScope(int firstYear, int lastYear) {
    return '僅含 $firstYear–$lastYear 的臺灣核發列。這個年份是能源署核發西元年，不是美國 model year。名稱相同也不等於 EPA 配置。';
  }

  @override
  String get settingsTwPickerTitle => '臺灣官方車輛目錄';

  @override
  String get settingsTwReferenceMassNotCurb => '參考車重不是 curb mass，不會套用。';

  @override
  String settingsTwWillApplyOnly(String fields) {
    return '只會套用：$fields。參考車重、VE、Cd、正面面積、Crr 與傳動效率仍保持未解析。';
  }

  @override
  String get settingsClose => '關閉';

  @override
  String get settingsConnectionSection => '連線';

  @override
  String get settingsDiagnosticsSection => '診斷紀錄';

  @override
  String get settingsDisconnect => '中斷連線';

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return '傳動效率 $percent %';
  }

  @override
  String settingsEpaApplyFields(int count) {
    return '套用 $count 個官方欄位';
  }

  @override
  String get settingsEpaChooseExact => '選擇一個精確配置';

  @override
  String get settingsEpaCloseNoFields => '關閉（沒有可套用欄位）';

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'EPA 配置 $epaId';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count 缸';
  }

  @override
  String get settingsEpaDriveUnknown => '驅動未知';

  @override
  String get settingsEpaFuelUnknown => '燃料未知';

  @override
  String get settingsEpaMake => '廠牌（EPA make）';

  @override
  String get settingsEpaModel => '車型';

  @override
  String get settingsEpaNoConfigurations => '這個車型沒有可用配置';

  @override
  String get settingsEpaNoSafeFields => '此配置沒有能安全套用到目前公式的欄位；不會猜測。';

  @override
  String get settingsEpaPickInOrder => '依序選擇年式、品牌與車型';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return '僅限美國市場 $firstYear–$lastYear 的快照配置。選到同名車系仍要以年式、變速箱、燃料與 EPA ID 消歧。';
  }

  @override
  String get settingsEpaPickerTitle => '美國 EPA 官方車型目錄';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return '只會套用：$fields。車重、VE、Cd、正面面積、Crr 與傳動效率仍保持未解析。';
  }

  @override
  String get settingsEpaYear => '年式';

  @override
  String get settingsExperimentalSection => '實驗功能';

  @override
  String get settingsFieldDisplacement => '排氣量';

  @override
  String get settingsFieldDragCoefficient => '風阻係數 Cd';

  @override
  String get settingsFieldDrivetrain => '驅動方式';

  @override
  String get settingsFieldFrontalArea => '正面投影面積';

  @override
  String get settingsFieldFuel => '燃料';

  @override
  String get settingsFieldMass => '車重';

  @override
  String get settingsFieldMassWithDriver => '車重（含駕駛）';

  @override
  String get settingsFieldRollingResistance => '滾動阻力係數 Crr';

  @override
  String get settingsFieldVolumetricEfficiency => '容積效率 VE';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return '空燃比 $afr · 密度 $density g/L';
  }

  @override
  String get settingsFuelAndDrivetrainSection => '燃料與驅動';

  @override
  String get settingsFuelTypeLabel => '燃料種類';

  @override
  String get settingsGaugeSkinBody =>
      '不只是換顏色 —— 每一種的刻度盤形狀、指針、動態都不一樣。深色與淺色底下都可以用。';

  @override
  String get settingsGaugeSkinTitle => '儀表樣式';

  @override
  String get settingsGoToConnect => '前往連線';

  @override
  String get settingsHeadline => '設定';

  @override
  String get settingsLicenseLegalese => '大電池資料的來源、轉換方式與重用條款都隨本 App 一併附上。';

  @override
  String get settingsListSeparator => '、';

  @override
  String get settingsManualCommandBody =>
      '直接送一條指令給轉接器，例如 ATI、ATDPN、0100。會排在一般輪詢的同一條佇列上，不會插隊。';

  @override
  String get settingsManualCommandFieldLabel => '指令';

  @override
  String get settingsManualCommandNoContent => '（沒有回應內容）';

  @override
  String get settingsManualCommandSend => '送出';

  @override
  String get settingsManualCommandTitle => '手動指令';

  @override
  String get settingsNotConnected => '未連線';

  @override
  String get settingsOpenSourceLicenses => '開放原始碼與資料授權';

  @override
  String get settingsProfileConfirmAfterConnect => '連線後確認此車資料';

  @override
  String get settingsProfileConfirmButton => '確認本次連線車輛資料';

  @override
  String get settingsProfileConfirmedButton => '本次連線資料已確認';

  @override
  String get settingsProfileConfirmedDetail => '已確認本次連線的設定。修改任一項或重新連線後都要再確認。';

  @override
  String get settingsProfileEstimatesIntro =>
      '馬力、扭力與油耗都是由這些參數推算出來的，填得越接近實車，推算值才越有意義。';

  @override
  String get settingsProfileNameProvesNothing =>
      '品牌名稱或 VIN 本身都不能證明重量、風阻、VE 與傳動效率。';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      '本次連線尚未確認。仍可讀取 OBD 實測資料，但不顯示依車重、VE 與風阻推算的數值。';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      '先連上目前這台車再確認。每次重新連線都會自動失效，避免把上一台車的設定套到下一台。';

  @override
  String get settingsProvenanceNoneExact =>
      '目前沒有欄位已精確解析到這次車輛；通用值、手動值或舊來源值仍須確認。';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return '目前只有$fields有官方精確來源；其他欄位仍須逐項確認。';
  }

  @override
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  ) {
    return '來源：官方／原廠 $official / $total 欄 · 手動 $user / $total 欄 · 通用 $generic / $total 欄 · 科學模型 $scientific / $total 欄';
  }

  @override
  String settingsProvenancePublishers(String publishers) {
    return '來源：$publishers';
  }

  @override
  String settingsProvenanceResolution(
    int exact,
    int sessionConfirmed,
    int unresolved,
    int ambiguous,
    int conflict,
    int total,
  ) {
    return '解析：官方精確 $exact / $total 欄 · 本次確認 $sessionConfirmed / $total 欄 · 未解析 $unresolved / $total 欄 · 歧義 $ambiguous / $total 欄 · 衝突 $conflict / $total 欄';
  }

  @override
  String get settingsStandardsFooter =>
      '本 App 的 OBD2 實作依據 SAE J1979 與 ELM327 datasheet 等公開標準；每一條影響硬體行為的公式與 AT 指令都經過交叉驗證，結果記錄於 docs/protocol-deviations.zh-TW.md。本 App 與 Torque / Torque Pro 無關聯。';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeLight => '淺色';

  @override
  String get settingsThemeSystem => '跟隨系統';

  @override
  String get settingsVehicleProfileSection => '車輛設定檔';

  @override
  String get settingsVinConflict => 'VIN 衝突';

  @override
  String get settingsVinConflictDetail => '不同控制器回報不同 VIN，無法確認車輛身分；所有候選都已丟棄。';

  @override
  String get settingsVinNotRead => 'VIN 尚未讀取';

  @override
  String get settingsVinNotReadConnectedDetail =>
      '可向目前車輛讀取 Mode 09 VIN；身分狀態只保留在這次連線中。原始診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      '連線後可讀取目前車輛自報的 VIN；身分狀態不會帶到下一次連線。原始診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinRead => '讀取 VIN';

  @override
  String get settingsVinReading => '讀取中…';

  @override
  String get settingsVinReportedDetail =>
      'VIN 是車輛自報身分，不代表車型規格已驗證。身分狀態不跨連線；診斷紀錄仍可能包含 VIN。';

  @override
  String get settingsVinSimulatorReported => '模擬器回報 VIN';

  @override
  String get settingsVinUnavailable => 'VIN 無法取得';

  @override
  String get settingsVinUnavailableDetail => '可能是車輛未提供、回覆不完整或這次連線沒有讀到；不會猜測或補字。';

  @override
  String get settingsVinVehicleReported => '車輛回報 VIN';

  @override
  String get startupCannotComplete => '目前無法完成啟動檢查';

  @override
  String get startupChecking => '正在檢查本機分享暫存與遙測紀錄';

  @override
  String get startupRestartHint =>
      '本機分享暫存或遙測紀錄的狀態無法確認。為避免覆寫、刪除或分享錯誤檔案，請完全關閉後重新開啟 Telltale。';

  @override
  String get startupRestartRequired => '需要重新啟動才能安全繼續';

  @override
  String get startupRetry => '重試';

  @override
  String get startupRetryHint =>
      '請讓 Telltale 保持在前景，並在其他檔案作業完成後重試。啟動完成前不會開放紀錄、回放、匯出或刪除。';

  @override
  String get telemetryArtifactRestartRequired =>
      '本機檔案作業狀態無法確認；請完全關閉並重新啟動 App 後再操作';

  @override
  String get telemetryBlockedByRecorder => '請先停止並儲存';

  @override
  String get telemetryCancel => '取消';

  @override
  String get telemetryDamagedCollision => '同一識別碼同時存在完成與未完成檔，未選擇任何一份';

  @override
  String get telemetryDamagedCorrupt => '紀錄損壞，無法安全讀取';

  @override
  String telemetryDamagedFileTime(String time) {
    return '檔案時間 $time';
  }

  @override
  String get telemetryDelete => '刪除';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return '將刪除 $id（檔案時間 $time）。刪除後無法復原。';
  }

  @override
  String get telemetryDeleteDamagedTitle => '刪除損壞紀錄？';

  @override
  String get telemetryDeleteDamagedTooltip => '刪除損壞紀錄';

  @override
  String telemetryDeleteFailed(String reason) {
    return '刪除未完成：$reason';
  }

  @override
  String get telemetryDeleteNeedsConfirmation => '請先確認這個刪除操作';

  @override
  String telemetryDeleteSessionBody(String time) {
    return '將刪除 $time 的紀錄。此操作無法復原。';
  }

  @override
  String get telemetryDeleteSessionTitle => '刪除本機紀錄？';

  @override
  String get telemetryDemoData => '內建模擬資料';

  @override
  String get telemetryDismissNotice => '關閉提示';

  @override
  String get telemetryEndedByBackground => 'App 進入背景後已停止';

  @override
  String get telemetryEndedByConfigurationChanged => 'PID 設定已變更';

  @override
  String get telemetryEndedByDisconnect => '連線中斷後已停止';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return '已達 $minutes 分鐘上限';
  }

  @override
  String get telemetryEndedByLibrarySizeLimit => '本機紀錄空間已滿';

  @override
  String get telemetryEndedByRecoveredAfterInterruption => '上次中斷後已復原';

  @override
  String get telemetryEndedBySessionReplacement => '連線工作階段已更換';

  @override
  String get telemetryEndedBySessionSizeLimit => '已達單筆紀錄容量上限';

  @override
  String get telemetryEndedByStorageBackpressure => '儲存速度不足';

  @override
  String get telemetryEndedByStorageFailure => '儲存失敗';

  @override
  String get telemetryEndedByUser => '已手動停止';

  @override
  String get telemetryExport => '匯出';

  @override
  String get telemetryExportCsv => '匯出 CSV';

  @override
  String telemetryExportFailed(String reason) {
    return '匯出未完成：$reason';
  }

  @override
  String get telemetryExportJson => '匯出 JSON';

  @override
  String get telemetryExportSheetTitle => '匯出本機紀錄';

  @override
  String telemetryGapCount(int count) {
    return '$count 個缺口';
  }

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    return '已儲存 $count 組，可離線回放與匯出';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit 組';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    return '另有 $count 組未顯示';
  }

  @override
  String telemetryLibraryQuotaSemantics(
    int groups,
    int groupLimit,
    String used,
    int byteLimit,
  ) {
    return '本機儲存 $groups / $groupLimit 組，$used / $byteLimit MiB';
  }

  @override
  String get telemetryNotConnected => '目前未連線';

  @override
  String get telemetryOfflineSampledReplay => '離線抽樣回放';

  @override
  String get telemetryOpenHistory => '查看本機紀錄';

  @override
  String get telemetryPause => '暫停';

  @override
  String get telemetryPendingOwnerRecovery =>
      '作業仍由目前程序持有；若持續停在此狀態，請完全關閉並重新啟動 App';

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first，$second';
  }

  @override
  String get telemetryPlay => '播放';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return '只紀錄已啟用的 OBD 訊號，不含位置、VIN 或帳號資料。趨勢圖最多顯示 $laneLimit 項，錄製會保留全部 $activeCount 項已啟用訊號，並自動加上估算馬力與估算油耗（含車輛假設）。';
  }

  @override
  String get telemetryRecorderPhaseAwaitingValues => '準備錄製';

  @override
  String get telemetryRecorderPhaseCompleted => '紀錄已儲存';

  @override
  String get telemetryRecorderPhaseFailed => '紀錄儲存失敗';

  @override
  String get telemetryRecorderPhaseFinalizing => '正在儲存紀錄';

  @override
  String get telemetryRecorderPhaseIdle => '前景本機紀錄';

  @override
  String get telemetryRecorderPhasePreparing => '正在準備錄製';

  @override
  String get telemetryRecorderPhaseRecording => '紀錄中';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return '錄製中 $duration';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    return '$count 組沒有有效值的未完成檔已清理';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    return '$count 組損壞或衝突檔未自動修改';
  }

  @override
  String get telemetryRecoveryDamagedNote => '損壞內容不會用於回放或匯出，只能在安全狀態下手動刪除。';

  @override
  String telemetryRecoveryInstalled(int count) {
    return '$count 組中斷紀錄已完成安全封存';
  }

  @override
  String get telemetryRecoveryTitle => '啟動紀錄檢查已完成';

  @override
  String get telemetryReload => '重新載入';

  @override
  String telemetryReplayBreakCount(int count) {
    return '$count 個中斷';
  }

  @override
  String get telemetryReplayLoadFailed => '無法載入紀錄';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return '回放位置 $percent%';
  }

  @override
  String telemetryReplaySampleCount(int count) {
    return '$count 個抽樣節點';
  }

  @override
  String get telemetryReplayTitle => '紀錄回放';

  @override
  String get telemetryReplayUnreadable => '紀錄損壞或無法讀取';

  @override
  String get telemetryRestartToRepairSave => '儲存作業未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryRestartToRepairStartup => '啟動清理未完成；請重新啟動 App 以修復紀錄';

  @override
  String get telemetryReturnToTrends => '返回趨勢';

  @override
  String get telemetryRigData => '測試馬具資料';

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first。$second';
  }

  @override
  String get telemetrySessionsDamaged => '損壞的紀錄檔';

  @override
  String get telemetrySessionsEmpty => '還沒有本機紀錄\n連線後開始錄製';

  @override
  String get telemetrySessionsLoadFailed => '無法載入，請重試';

  @override
  String get telemetrySessionsReplayable => '可回放的紀錄';

  @override
  String get telemetrySessionsTitle => '本機紀錄';

  @override
  String telemetrySignalCount(int count) {
    return '$count 項訊號';
  }

  @override
  String get telemetryStartBusy => '另一個紀錄或檔案作業尚未完成';

  @override
  String get telemetryStartCannotCreateFile => '無法建立紀錄檔';

  @override
  String get telemetryStartInvalidConfiguration => 'PID 設定無法安全紀錄，請檢查定義';

  @override
  String get telemetryStartInvalidatedBackground => 'App 已進入背景，未開始紀錄';

  @override
  String get telemetryStartInvalidatedDisconnect => '連線已中斷，未開始紀錄';

  @override
  String get telemetryStartInvalidatedSessionReplacement => '連線工作階段已更換，未開始紀錄';

  @override
  String get telemetryStartLibraryByteLimit => '本機紀錄空間不足，請先匯出或刪除';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return '本機紀錄已達 $limit 組上限，請先匯出或刪除';
  }

  @override
  String get telemetryStartMoving => '請停車後操作';

  @override
  String get telemetryStartNeedsActivePid => '請先啟用至少一項 PID';

  @override
  String get telemetryStartNeedsConnection => '請先連線再開始紀錄';

  @override
  String get telemetryStartNeedsForeground => '請回到 App 前景再開始紀錄';

  @override
  String get telemetryStartRecording => '已開始紀錄';

  @override
  String get telemetryStartRecordingButton => '開始紀錄';

  @override
  String get telemetryStartSpeedUnknown => '無法確認車輛已停止；請先中斷連線';

  @override
  String get telemetryStartTooManyPids => '錄製需保留估算馬力與估算油耗欄位，請先停用 PID';

  @override
  String get telemetryStarting => '正在開始';

  @override
  String get telemetryStatusBusError => '匯流排錯誤';

  @override
  String telemetryStatusCount(int count) {
    return '$count 個狀態';
  }

  @override
  String get telemetryStatusFormulaError => '公式錯誤';

  @override
  String get telemetryStatusHeaderMismatch => '標頭不符目前匯流排';

  @override
  String get telemetryStatusNoAnswer => '無回應，稍後重試';

  @override
  String get telemetryStatusStale => '資料已過期';

  @override
  String get telemetryStatusUnsafeServiceRefusal => '此服務不是唯讀查詢，已停止發送';

  @override
  String get telemetryStatusUnsupported => '目前引擎控制器已確認不支援';

  @override
  String get telemetryStopAndSave => '停止並儲存';

  @override
  String telemetryValueCount(int count) {
    return '$count 筆有效值';
  }

  @override
  String get transcriptDelete => '刪除';

  @override
  String get transcriptDeleteBusy => '另一個檔案作業尚未完成。';

  @override
  String get transcriptDeleteFailed => '無法刪除上一次連線的紀錄。';

  @override
  String get transcriptDeleteRefusedBySafety => '目前車速或連線狀態不允許刪除紀錄。';

  @override
  String get transcriptExport => '匯出';

  @override
  String get transcriptExportButton => '匯出紀錄';

  @override
  String get transcriptExportExplanation =>
      '這次連線會保留開頭握手與最新的原始往返資料；長時間連線若省略中段，檔案會明確標出。在車上遇到讀不到、判斷不出來的情況時，把紀錄匯出帶回來，比畫面上的一句訊息有用得多。';

  @override
  String transcriptExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String get transcriptExportWithHex => '含十六進位';

  @override
  String get transcriptNothingToExport => '沒有可匯出的紀錄。';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return '$timestamp 留下的，$size。App 被系統關掉或手機沒電時，紀錄還是留下來了。';
  }

  @override
  String get transcriptRecoveredChanged => '上一次連線的紀錄已更新，請再確認。';

  @override
  String get transcriptRecoveredTitle => '上一次連線的紀錄';

  @override
  String transcriptSizeBytes(int bytes) {
    return '$bytes 位元組';
  }

  @override
  String get trendAxisNow => '現在';

  @override
  String get trendChooseSignals => '選擇訊號';

  @override
  String get trendLiveData => '即時資料';

  @override
  String get trendNoSignalsBody => '先到 PID 頁面啟用想要監看的訊號。';

  @override
  String get trendNoSignalsTitle => '沒有可用的趨勢訊號';

  @override
  String get trendNoUnits => '無單位';

  @override
  String trendPickSignalsBody(int limit) {
    return '最多可以比較 $limit 項訊號，不會改變已啟用的 PID 輪詢。';
  }

  @override
  String get trendPickSignalsTitle => '選擇趨勢訊號';

  @override
  String trendRemoveSignal(String name) {
    return '移除 $name';
  }

  @override
  String get trendSelectionSaveFailed => '無法儲存趨勢顯示選擇';

  @override
  String trendSheetBody(int limit) {
    return '最多選擇 $limit 項。這只會改變圖表，不會改變 PID 輪詢或正在進行的紀錄。';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return '完成 · $selected/$limit';
  }

  @override
  String get trendSignalNoLongerActive => '其中一項訊號已不在 PID 監看清單';

  @override
  String get trendSignalsHeading => '趨勢訊號';

  @override
  String trendTooManySelected(int limit) {
    return '最多選擇 $limit 項';
  }

  @override
  String trendWindowSemantics(int seconds) {
    return '顯示最近 $seconds 秒趨勢';
  }

  @override
  String get wearBack => '返回';

  @override
  String get wearBatteryVoltageLabel => '電瓶';

  @override
  String get wearBleAdapters => 'BLE 轉接器';

  @override
  String get wearCancel => '取消';

  @override
  String get wearConfirmVehicle => '確認車輛';

  @override
  String get wearConfirmVehicleAccept => '就是這台車';

  @override
  String get wearConfirmVehicleBody =>
      '確認後，這個車型的唯讀電池查詢會在本次連線內定期輪詢。接錯車型可能得到看似合理但錯誤的數字——不確定就取消。';

  @override
  String wearConnectFailed(String adapter) {
    return '連線失敗：$adapter';
  }

  @override
  String get wearConnecting => '連線中…';

  @override
  String get wearDemoSimulator => 'Demo 模擬器';

  @override
  String get wearDisconnect => '中斷';

  @override
  String get wearDisconnectQuestion => '中斷連線？';

  @override
  String get wearNoDevicesFound => '沒有找到裝置';

  @override
  String get wearPermissionBluetooth => '藍牙';

  @override
  String get wearPermissionLocation => '位置';

  @override
  String get wearScanAgain => '重新掃描';

  @override
  String get wearScanFailed => '掃描失敗，請再試一次';

  @override
  String wearScanPermissionNeeded(String permission) {
    return '需要$permission權限才能掃描';
  }

  @override
  String wearScanPermissionPermanentlyDenied(String permission) {
    return '$permission權限已被永久拒絕，請到系統設定開啟後再試';
  }

  @override
  String get wearScanning => '掃描中…';

  @override
  String get telemetryRecorderNotRecording => '未錄製';

  @override
  String get dtcKindStored => '已儲存';

  @override
  String get dtcKindPending => '待確認';

  @override
  String get dtcKindPermanent => '永久';

  @override
  String get dtcKindStoredExplanation => '已確認的故障，儀表板故障燈通常亮起';

  @override
  String get dtcKindPendingExplanation => '偵測到一次，尚未達到確認門檻';

  @override
  String get dtcKindPermanentExplanation => '無法用診斷儀清除，需修復後由 ECU 自行確認';

  @override
  String get dtcSystemPowertrain => '動力系統';

  @override
  String get dtcSystemChassis => '底盤';

  @override
  String get dtcSystemBody => '車身';

  @override
  String get dtcSystemNetwork => '網路';

  @override
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions =>
      '燃油與空氣計量、輔助排放控制';

  @override
  String get dtcSubsystemFuelAirMetering => '燃油與空氣計量';

  @override
  String get dtcSubsystemFuelAirMeteringInjectorCircuit => '燃油與空氣計量（噴油嘴迴路）';

  @override
  String get dtcSubsystemIgnitionOrMisfire => '點火系統或失火';

  @override
  String get dtcSubsystemAuxiliaryEmissionControls => '輔助排放控制';

  @override
  String get dtcSubsystemSpeedAndIdleControl => '車速控制與怠速系統';

  @override
  String get dtcSubsystemComputerOutputCircuit => '電腦輸出迴路';

  @override
  String get dtcSubsystemTransmission => '變速箱';

  @override
  String get dtcSubsystemControlModuleSignals => '控制模組輸入／輸出訊號';

  @override
  String get dtcDescriptionB0001 => '駕駛座安全氣囊裝置故障';

  @override
  String get dtcDescriptionP0011 => '「A」凸輪軸正時過前或系統效能異常（Bank 1）';

  @override
  String get dtcDescriptionP0014 => '「B」凸輪軸正時過前或系統效能異常（Bank 1）';

  @override
  String get dtcDescriptionP0016 => '曲軸與凸輪軸位置訊號不同步（Bank 1 感知器 A）';

  @override
  String get dtcDescriptionP0087 => '燃油軌／系統壓力過低';

  @override
  String get dtcDescriptionP0088 => '燃油軌／系統壓力過高';

  @override
  String get dtcDescriptionP0100 => '空氣流量感知器 (MAF) 電路故障';

  @override
  String get dtcDescriptionP0101 => '空氣流量感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0102 => '空氣流量感知器電路輸入過低';

  @override
  String get dtcDescriptionP0103 => '空氣流量感知器電路輸入過高';

  @override
  String get dtcDescriptionP0105 => '進氣歧管絕對壓力／大氣壓力感知器電路故障';

  @override
  String get dtcDescriptionP0106 => '進氣歧管絕對壓力感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0107 => '進氣歧管絕對壓力感知器電路輸入過低';

  @override
  String get dtcDescriptionP0108 => '進氣歧管絕對壓力感知器電路輸入過高';

  @override
  String get dtcDescriptionP0110 => '進氣溫度感知器電路故障';

  @override
  String get dtcDescriptionP0111 => '進氣溫度感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0112 => '進氣溫度感知器電路輸入過低';

  @override
  String get dtcDescriptionP0113 => '進氣溫度感知器電路輸入過高';

  @override
  String get dtcDescriptionP0115 => '冷卻液溫度感知器電路故障';

  @override
  String get dtcDescriptionP0116 => '冷卻液溫度感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0117 => '冷卻液溫度感知器電路輸入過低';

  @override
  String get dtcDescriptionP0118 => '冷卻液溫度感知器電路輸入過高';

  @override
  String get dtcDescriptionP0120 => '節氣門位置感知器電路故障';

  @override
  String get dtcDescriptionP0121 => '節氣門位置感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0122 => '節氣門位置感知器電路輸入過低';

  @override
  String get dtcDescriptionP0123 => '節氣門位置感知器電路輸入過高';

  @override
  String get dtcDescriptionP0125 => '冷卻液溫度不足以進入閉迴路燃油控制';

  @override
  String get dtcDescriptionP0128 => '冷卻液溫度低於節溫器調節溫度';

  @override
  String get dtcDescriptionP0130 => '含氧感知器電路故障 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0131 => '含氧感知器電路電壓過低 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0132 => '含氧感知器電路電壓過高 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0133 => '含氧感知器反應過慢 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0134 => '含氧感知器無活性訊號 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0135 => '含氧感知器加熱器電路故障 (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0136 => '含氧感知器電路故障 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0137 => '含氧感知器電路電壓過低 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0138 => '含氧感知器電路電壓過高 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0140 => '含氧感知器無活性訊號 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0141 => '含氧感知器加熱器電路故障 (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0150 => '含氧感知器電路故障 (Bank 2 Sensor 1)';

  @override
  String get dtcDescriptionP0155 => '含氧感知器加熱器電路故障 (Bank 2 Sensor 1)';

  @override
  String get dtcDescriptionP0156 => '含氧感知器電路故障 (Bank 2 Sensor 2)';

  @override
  String get dtcDescriptionP0161 => '含氧感知器加熱器電路故障 (Bank 2 Sensor 2)';

  @override
  String get dtcDescriptionP0170 => '燃油修正異常 (Bank 1)';

  @override
  String get dtcDescriptionP0171 => '混合比過稀 (Bank 1)';

  @override
  String get dtcDescriptionP0172 => '混合比過濃 (Bank 1)';

  @override
  String get dtcDescriptionP0173 => '燃油修正異常 (Bank 2)';

  @override
  String get dtcDescriptionP0174 => '混合比過稀 (Bank 2)';

  @override
  String get dtcDescriptionP0175 => '混合比過濃 (Bank 2)';

  @override
  String get dtcDescriptionP0190 => '燃油軌壓力感知器電路故障';

  @override
  String get dtcDescriptionP0201 => '噴油嘴電路故障／開路 — 第 1 缸';

  @override
  String get dtcDescriptionP0202 => '噴油嘴電路故障／開路 — 第 2 缸';

  @override
  String get dtcDescriptionP0203 => '噴油嘴電路故障／開路 — 第 3 缸';

  @override
  String get dtcDescriptionP0204 => '噴油嘴電路故障／開路 — 第 4 缸';

  @override
  String get dtcDescriptionP0217 => '引擎過熱';

  @override
  String get dtcDescriptionP0221 => '節氣門／油門踏板位置感知器 B 範圍或效能異常';

  @override
  String get dtcDescriptionP0222 => '節氣門／油門踏板位置感知器 B 電路輸入過低';

  @override
  String get dtcDescriptionP0223 => '節氣門／油門踏板位置感知器 B 電路輸入過高';

  @override
  String get dtcDescriptionP0234 => '渦輪／機械增壓過壓';

  @override
  String get dtcDescriptionP0299 => '渦輪／機械增壓「A」增壓不足';

  @override
  String get dtcDescriptionP0300 => '偵測到隨機/多缸失火';

  @override
  String get dtcDescriptionP0301 => '第 1 缸失火';

  @override
  String get dtcDescriptionP0302 => '第 2 缸失火';

  @override
  String get dtcDescriptionP0303 => '第 3 缸失火';

  @override
  String get dtcDescriptionP0304 => '第 4 缸失火';

  @override
  String get dtcDescriptionP0305 => '第 5 缸失火';

  @override
  String get dtcDescriptionP0306 => '第 6 缸失火';

  @override
  String get dtcDescriptionP0307 => '第 7 缸失火';

  @override
  String get dtcDescriptionP0308 => '第 8 缸失火';

  @override
  String get dtcDescriptionP0316 => '起動後隨即偵測到失火';

  @override
  String get dtcDescriptionP0325 => '爆震感知器電路故障 (Bank 1)';

  @override
  String get dtcDescriptionP0326 => '爆震感知器範圍/效能異常 (Bank 1)';

  @override
  String get dtcDescriptionP0327 => '爆震感知器電路輸入過低 (Bank 1)';

  @override
  String get dtcDescriptionP0328 => '爆震感知器電路輸入過高 (Bank 1)';

  @override
  String get dtcDescriptionP0330 => '爆震感知器電路故障 (Bank 2)';

  @override
  String get dtcDescriptionP0335 => '曲軸位置感知器電路故障';

  @override
  String get dtcDescriptionP0336 => '曲軸位置感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0340 => '凸輪軸位置感知器電路故障';

  @override
  String get dtcDescriptionP0341 => '凸輪軸位置感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0351 => '點火線圈 A 一次/二次電路故障';

  @override
  String get dtcDescriptionP0352 => '點火線圈 B 一次/二次電路故障';

  @override
  String get dtcDescriptionP0353 => '點火線圈 C 一次/二次電路故障';

  @override
  String get dtcDescriptionP0354 => '點火線圈 D 一次/二次電路故障';

  @override
  String get dtcDescriptionP0355 => '點火線圈 E 一次/二次電路故障';

  @override
  String get dtcDescriptionP0356 => '點火線圈 F 一次/二次電路故障';

  @override
  String get dtcDescriptionP0400 => '廢氣再循環 (EGR) 流量故障';

  @override
  String get dtcDescriptionP0401 => '廢氣再循環 (EGR) 流量不足';

  @override
  String get dtcDescriptionP0402 => '廢氣再循環 (EGR) 流量過大';

  @override
  String get dtcDescriptionP0403 => '廢氣再循環 (EGR) 控制電路故障';

  @override
  String get dtcDescriptionP0404 => '廢氣再循環 (EGR) 控制電路範圍/效能異常';

  @override
  String get dtcDescriptionP0410 => '二次空氣噴射系統故障';

  @override
  String get dtcDescriptionP0411 => '二次空氣噴射系統流量不正確';

  @override
  String get dtcDescriptionP0412 => '二次空氣噴射切換閥 A 電路故障';

  @override
  String get dtcDescriptionP0420 => '觸媒轉換器效率低於門檻 (Bank 1)';

  @override
  String get dtcDescriptionP0430 => '觸媒轉換器效率低於門檻 (Bank 2)';

  @override
  String get dtcDescriptionP0440 => '蒸發排放控制系統故障';

  @override
  String get dtcDescriptionP0441 => '蒸發排放系統清除流量不正確';

  @override
  String get dtcDescriptionP0442 => '蒸發排放系統偵測到小漏氣';

  @override
  String get dtcDescriptionP0443 => '蒸發排放清除閥控制電路故障';

  @override
  String get dtcDescriptionP0446 => '蒸發排放通風控制電路故障';

  @override
  String get dtcDescriptionP0447 => '蒸發排放通風控制電路開路';

  @override
  String get dtcDescriptionP0449 => '蒸發排放通風閥/電磁閥電路故障';

  @override
  String get dtcDescriptionP0451 => '蒸發排放壓力感知器範圍/效能異常';

  @override
  String get dtcDescriptionP0452 => '蒸發排放壓力感知器電路輸入過低';

  @override
  String get dtcDescriptionP0453 => '蒸發排放壓力感知器電路輸入過高';

  @override
  String get dtcDescriptionP0455 => '蒸發排放系統偵測到大漏氣';

  @override
  String get dtcDescriptionP0456 => '蒸發排放系統偵測到極小漏氣';

  @override
  String get dtcDescriptionP0480 => '冷卻風扇 1 控制電路故障';

  @override
  String get dtcDescriptionP0500 => '車速感知器故障';

  @override
  String get dtcDescriptionP0505 => '怠速控制系統故障';

  @override
  String get dtcDescriptionP0506 => '怠速轉速低於預期';

  @override
  String get dtcDescriptionP0507 => '怠速轉速高於預期';

  @override
  String get dtcDescriptionP0508 => '怠速控制電路輸入過低';

  @override
  String get dtcDescriptionP0509 => '怠速控制電路輸入過高';

  @override
  String get dtcDescriptionP0560 => '系統電壓故障';

  @override
  String get dtcDescriptionP0562 => '系統電壓過低';

  @override
  String get dtcDescriptionP0563 => '系統電壓過高';

  @override
  String get dtcDescriptionP0603 => '控制模組內部記憶體（KAM）錯誤';

  @override
  String get dtcDescriptionP0605 => '控制模組內部唯讀記憶體（ROM）錯誤';

  @override
  String get dtcDescriptionP0606 => 'ECM/PCM 處理器故障';

  @override
  String get dtcDescriptionP0700 => '變速箱控制模組要求點亮故障燈 —— 故障碼在變速箱模組裡，請另外讀取';

  @override
  String get dtcDescriptionP0701 => '變速箱控制系統範圍/效能異常';

  @override
  String get dtcDescriptionP0702 => '變速箱控制系統電氣故障';

  @override
  String get dtcDescriptionP0705 => '排檔位置感知器電路故障';

  @override
  String get dtcDescriptionP0715 => '輸入軸／渦輪轉速感知器電路故障';

  @override
  String get dtcDescriptionP0720 => '輸出軸轉速感知器電路故障';

  @override
  String get dtcDescriptionP0730 => '檔位比不正確';

  @override
  String get dtcDescriptionP0740 => '扭力轉換器離合器電路故障';

  @override
  String get dtcDescriptionP0741 => '扭力轉換器離合器卡在未鎖定狀態';

  @override
  String get dtcDescriptionP0750 => '換檔電磁閥 A 故障';

  @override
  String get dtcDescriptionP0755 => '換檔電磁閥 B 故障';

  @override
  String get dtcDescriptionP2135 => '節氣門位置感知器 A/B 電壓不一致';

  @override
  String get dtcDescriptionU0100 => '與 ECM/PCM 失去通訊';

  @override
  String get dtcDescriptionU0101 => '與變速箱控制模組失去通訊';

  @override
  String get dtcDescriptionU0121 => '與 ABS 控制模組失去通訊';

  @override
  String get dtcDescriptionU0140 => '與車身控制模組失去通訊';

  @override
  String get dtcDescriptionU0155 => '與儀表板控制模組失去通訊';

  @override
  String get gaugeSkinCluster => '儀表艙';

  @override
  String get gaugeSkinClusterDescription => '車廠儀表板的樣子。指針、270 度刻度盤、凹陷的面盤。';

  @override
  String get gaugeSkinMinimal => '極簡';

  @override
  String get gaugeSkinMinimalDescription => '半圓弧、沒有指針、沒有刻度。要看的是數字，不是動作。';

  @override
  String get gaugeSkinTrack => '賽道';

  @override
  String get gaugeSkinTrackDescription => '分段燈條、無平滑動畫。數值到哪就是哪，不做過渡。';

  @override
  String get gaugeSkinClassic => '經典';

  @override
  String get gaugeSkinClassicDescription => '印刷式面盤、整圈數字、指針像機械錶一樣慢慢定位。';

  @override
  String get gaugeSkinNight => '夜視';

  @override
  String get gaugeSkinNightDescription => '夜間駕駛用。低亮度、淺弧、不做動畫，盡量不搶走注意力。';

  @override
  String get derivedAirflowSourceMaf => 'MAF 感測器';

  @override
  String get derivedAirflowSourceSpeedDensity => 'Speed-Density 推算';

  @override
  String get derivedAirflowSourceUnavailable => '進氣量無法取得';

  @override
  String get derivedFuelSourceStoichiometric => '化學計量比推算';

  @override
  String get derivedFuelSourceUnavailable => '油耗無法取得';

  @override
  String get telemetrySourceDemo => '內建模擬';

  @override
  String get telemetrySourceRig => '測試馬具';

  @override
  String get telemetrySourceFieldApp => '一般 field App 連線';

  @override
  String get fuelTypeGasoline => '汽油';

  @override
  String get fuelTypeDiesel => '柴油';

  @override
  String get fuelTypeLpg => '液化石油氣 (LPG)';

  @override
  String get fuelTypeEthanolE85 => 'E85 酒精汽油';

  @override
  String get drivetrainFwd => '前輪驅動';

  @override
  String get drivetrainRwd => '後輪驅動';

  @override
  String get drivetrainAwd => '四輪驅動';

  @override
  String get assumptionFieldMass => '車重';

  @override
  String get assumptionFieldDragCoefficient => 'Cd';

  @override
  String get assumptionFieldFrontalArea => '迎風面積';

  @override
  String get assumptionFieldRollingResistance => '滾動阻力';

  @override
  String get assumptionFieldDrivetrainEfficiency => '傳動效率';

  @override
  String get assumptionFieldFuelType => '燃料';

  @override
  String get assumptionFieldStoichAfr => 'AFR';

  @override
  String get assumptionFieldFuelDensity => '密度';

  @override
  String get assumptionFieldDisplacement => '排氣量';

  @override
  String get assumptionFieldVolumetricEfficiency => 'VE';

  @override
  String get vehicleFieldOriginGenericDefault => '通用預設';

  @override
  String get vehicleFieldOriginUserEntered => '手動輸入';

  @override
  String get vehicleFieldOriginOfficialRegistry => '官方型錄';

  @override
  String get vehicleFieldOriginManufacturerPublication => '原廠資料';

  @override
  String get vehicleFieldOriginScientificModel => '模型係數';

  @override
  String assumptionWithOrigin(String field, String value, String origin) {
    return '$field $value（$origin）';
  }

  @override
  String assumptionWithoutOrigin(String field, String value) {
    return '$field $value';
  }

  @override
  String get assumptionSeparator => '；';

  @override
  String get datumFormulaHorsepower =>
      'wheelWatts = (m·a + ½ρ·Cd·A·v² + Crr·m·g)·v; engineHp = wheelHp / drivetrainEfficiency';

  @override
  String get datumFormulaFuelRate =>
      'L/h = (MAF g/s) / (AFR × fuel density g/L) × 3600; MAF 可為 PID 0110 或 speed-density（RPM×MAP×排氣量×VE / T_K）; L/100km = (L/h) / speed_kmh × 100';

  @override
  String get datumAssumptionsFromRecording => '估算使用記錄當下的車輛設定';

  @override
  String adapterConcernFirmwareNeverReleasedSummary(String version) {
    return '回報的韌體版本 v$version 官方從未發行';
  }

  @override
  String get adapterConcernFirmwareNeverReleasedDetail =>
      'ELM327 的原廠 Elm Electronics 沒有出過這個版本 —— 這台轉接器上的韌體不是它自稱的那一份。很多這種轉接器仍然可用，但它對自己的描述已經不可靠，遇到讀不到的狀況時值得先懷疑它。';

  @override
  String adapterConcernPpsRefusedSummary(String version) {
    return '自稱 v$version，卻不認得 v1.1 就有的 ATPPS 指令';
  }

  @override
  String get adapterConcernPpsRefusedDetail =>
      '可程式參數摘要（ATPPS）從 ELM327 v1.1 起就存在，連 OBDLink 這類高階轉接器也支援。自稱的版本與實際實作的指令對不起來。';

  @override
  String get adapterConcernNoIdentitySummary => '不回應 AT@1（第一版就有的裝置識別指令）';

  @override
  String get adapterConcernNoIdentityDetail =>
      '這條指令從 ELM327 v1.0 就存在。不回應代表這顆晶片的指令集比任何一版官方韌體都少。';

  @override
  String get telemetryReplaySampled => '預覽已抽樣；匯出保留完整已記錄事件';

  @override
  String get telemetryExportDisclosure =>
      '匯出內容包含訊號名稱、數值、觀測與來源時間、傳輸類型、通訊協定、凍結的 PID 標籤／單位／公式，以及估算假設（車重、空氣阻力、排氣量、燃料等參數）。JSON 可能包含使用者自訂標籤、單位、公式與完整凍結定義。匯出內容不含 VIN、GPS、帳號、轉接器位址、完整車輛設定檔或原始診斷流量。';

  @override
  String get connectTransportCancelled => '連線嘗試在完成前被停止了。';

  @override
  String get connectTransportWifiRouteNoNetwork =>
      '手機沒有連上任何 Wi-Fi 網路，沒有通往轉接器的路由。請先連上轉接器的 Wi-Fi 熱點再試一次。';

  @override
  String get connectTransportWifiRouteAmbiguous =>
      '手機同時連著多個 Wi-Fi，無法判斷哪一個通往轉接器，所以沒有選任何一個。請先關閉不是轉接器的那些連線再試一次。';

  @override
  String get connectTransportWifiRouteRefused =>
      '系統拒絕讓這個連線走 Wi-Fi。手機是連著 Wi-Fi 的，只是不被允許用於這個連線。';

  @override
  String get connectTransportWifiRouteTimeout =>
      '系統沒有回應「讓這個連線走 Wi-Fi」的請求。請等幾秒再試一次。';

  @override
  String get connectTransportWifiRouteUnclassified =>
      '這個連線無法走 Wi-Fi，而系統沒有說明原因。完整的錯誤留在下方的紀錄裡。';

  @override
  String get connectTransportWifiHostUnreachable =>
      '那個位址沒有回應。請確認手機已連上轉接器的 Wi-Fi 熱點 —— 若系統問過「無法連上網際網路，是否繼續使用」，要選繼續使用。關閉行動數據也可能有幫助。';

  @override
  String get connectTransportWifiConnectTimeout => '那個位址在時限內沒有任何回應。';

  @override
  String get connectTransportWifiRouteRestoreFailed =>
      '連線本身成功了，但手機的網路路由無法恢復，所以連線被中斷，而不是把它改過的狀態留著。請重新開啟 App 再試一次。';

  @override
  String get connectTransportBleLinkFailed => '無法連線到轉接器。請確認它已通電且在範圍內。';

  @override
  String get connectTransportBleNoSerialCharacteristic =>
      '裝置連上了，但在它身上沒有找到序列埠，可能不是 ELM327 轉接器。';

  @override
  String get connectTransportClassicAllTiersRefused =>
      '無法連線到轉接器。請先在系統藍牙設定完成配對，並確認它已插上 OBD 埠且電門已開啟。';

  @override
  String get connectTransportClassicConnectTimeout =>
      '連線到轉接器逾時。它可能仍在回應中 —— 請等幾秒再試，不要立刻重試。';

  @override
  String get connectTransportSerialPortOpenFailed =>
      '無法開啟序列埠。請確認系統已為這個轉接器建立序列埠（Windows COMx / Linux /dev/rfcomm*），且電門已開啟。';

  @override
  String get connectTransportSerialDroppedOnOpen => '序列埠開啟後立刻又關閉了。';

  @override
  String get settingsManualCommandNotConnected => '目前沒有連線，這條指令沒有送出。';

  @override
  String get settingsManualCommandLinkDropped =>
      '這條指令還在等待回應時，與轉接器的連線中斷了，所以沒有任何回應。轉接器是否收到這條指令並不確定。';

  @override
  String get settingsManualCommandDisconnectedByApp =>
      '這條指令還在等待回應時，App 主動關閉了連線，所以沒有任何回應。轉接器與車輛都沒有問題。';

  @override
  String get settingsManualCommandAdapterSilentOnResync =>
      '轉接器的回應已經和送出的指令對不上，而它也沒有回應用來重新對齊的檢查，所以連線已中斷。請重新連線後再試一次。';

  @override
  String get settingsManualCommandLinkStoppedResponding =>
      '轉接器安靜得夠久，連線已被中斷。它可能仍有電；能確定的只有這段沉默。';

  @override
  String get settingsManualCommandWriteFailed =>
      '這條指令無法交給轉接器的連線。有多少內容送達轉接器並不確定。';

  @override
  String get settingsManualCommandTimedOut => '在時限內沒有收到回應。請確認轉接器已連線，且車輛電門已開啟。';

  @override
  String get settingsManualCommandOperationRetired => '這個工作階段已經結束或退到背景，指令沒有送出。';

  @override
  String get settingsManualCommandRequestUnaddressable =>
      '這條要求在這輛車使用的匯流排上無法定址，因此沒有送出。再試一次也不會改變。';

  @override
  String get commandFailureBusJ1939 =>
      '這條匯流排是 SAE J1939（重型商用車與機械），不是本 App 讀取的 OBD2 診斷協定，因此無法讀取這次查詢。';

  @override
  String commandFailureUserCanFramingUnknown(
    String protocol,
    String parameter,
  ) {
    return '轉接器設成自訂 CAN 協定 $protocol，其框架由 $parameter 決定。轉接器沒有回報該設定，因此無法確認匯流排格式，也不能安全解碼這次查詢。';
  }

  @override
  String get commandFailureBusUndetermined => '車輛匯流排協定尚未確定，因此無法安全解碼這次查詢。請重新連線。';

  @override
  String get settingsManualCommandCustomFlowControlRejected =>
      '轉接器拒絕了自訂 Flow Control 指令，因此未套用所要求的模式，也沒有產生任何量測值。';

  @override
  String get settingsManualCommandFlowControlRestoreFailed =>
      '轉接器拒絕還原預設 Flow Control（ATFCSM0），因此已停止輪詢，請重新連線後再試。';

  @override
  String get settingsManualCommandExtendedAddressingUnavailable =>
      '此 ELM327 路徑不提供延伸定址。';

  @override
  String get settingsManualCommandRawIsoTpModeUnavailable =>
      '此 ELM327 路徑不提供主機可見的 ISO-TP 重組。';

  @override
  String get settingsManualCommandCanPriorityUnavailable =>
      '此 ELM327 路徑不提供 CAN 優先權程式設計。';

  @override
  String get settingsManualCommandCanReceiveFilterUnavailable =>
      '此 ELM327 路徑不提供 CAN 接收過濾。';

  @override
  String get settingsManualCommandHeaderRestoreFailed =>
      '轉接器拒絕還原標頭（ATSH），無法歸屬回應，重連前拒絕後續指令。';

  @override
  String get manualCommandRefusedEmpty => '沒有輸入指令。';

  @override
  String get manualCommandRefusedMoreThanOneCommand =>
      '指令裡有換行或控制字元，這樣會一次送出多個指令。轉接器以換行分隔指令，所以第二個指令不會經過這裡的任何檢查 —— 包括禁止清除故障碼的那一項。請一次只輸入一個指令。';

  @override
  String manualCommandRefusedAdapterStateWouldChange(
    Object command,
    Object allowed,
  ) {
    return '手動指令只接受查詢，不接受會改變轉接器設定的指令。「$command」會改動轉接器狀態，而 App 對轉接器的認知不會跟著更新 —— 接下來的讀數可能來自另一個控制器，而畫面上看不出來。\n可用的查詢：$allowed。';
  }

  @override
  String get manualCommandRefusedClearHasItsOwnButton =>
      '清除故障碼請用故障碼畫面的「清除」按鈕。從這裡送出會跳過確認、覆蓋率檢查與回應驗證，而且只會清到目前選中的那一個控制器。';

  @override
  String manualCommandRefusedCharactersNoObdCommandHas(Object command) {
    return '指令「$command」含有 OBD 指令不會出現的字元。這裡只接受十六進位的服務碼與參數（例如 0100、03、2211A6），或 AT 開頭的轉接器查詢。';
  }

  @override
  String manualCommandRefusedNotAReadOnlyQuery(Object command, Object allowed) {
    return '不認得的指令「$command」。這裡只接受唯讀查詢（Mode $allowed）與轉接器查詢指令。';
  }

  @override
  String commandFailureQueryHeaderRefused(Object header) {
    return '轉接器拒絕將這條要求對準到控制器 $header，因此它沒有送出。如果留在轉接器實際持有的位址上，回應會來自沒有人詢問的控制器。';
  }

  @override
  String commandFailureWholeVehicleHeaderRefused(Object address) {
    return '轉接器拒絕切換到 $address 這個位址，而向全車提出的問題必須從它送出。沒有它，回應就無法對應到送出它們的控制器，因此這個要求沒有送出。';
  }

  @override
  String commandFailureLegacyScanWouldBePartial(Object installed) {
    return '這輛車使用的舊式匯流排沒有能觸及每個控制器的標準位址，而轉接器目前指定在控制器 $installed。掃描只會涵蓋那一個控制器，卻會被當成全車結果呈現，因此沒有送出。請重新連線後再掃描一次。';
  }

  @override
  String get pidFormulaEmpty => '公式是空的。';

  @override
  String get pidFormulaEmptySubExpression => '公式有一段是空的 —— 運算子後面沒有東西，或括號裡沒有內容。';

  @override
  String get pidFormulaUnbalancedParentheses => '括號沒有配對：每一個 ( 都需要一個對應的 )。';

  @override
  String pidFormulaUnparsableTerm(String term) {
    return '「$term」不是數值、運算子，也不是這個編輯器認得的名稱。';
  }

  @override
  String get pidFormulaFunctionNestingTooDeep =>
      'ABS()、LOG10()、LOG() 與 SQRT() 巢狀太深，無法求值。請簡化公式。';

  @override
  String get pidFormulaParenthesisNestingTooDeep => '括號巢狀太深，無法求值。請簡化公式。';

  @override
  String get pidFormulaDivisionByZero => '公式除以零。';

  @override
  String get pidFormulaModuloByZero => '公式對零取餘數。';

  @override
  String pidFormulaLog10NonPositiveArgument(double argument) {
    return 'LOG10 的引數必須大於 0，這裡算出來的是 $argument。';
  }

  @override
  String pidFormulaLogNonPositiveArgument(double argument) {
    return 'LOG 的引數必須大於 0，這裡算出來的是 $argument。';
  }

  @override
  String pidFormulaSqrtNegativeArgument(double argument) {
    return 'SQRT 的引數必須大於或等於 0，這裡算出來的是 $argument。';
  }

  @override
  String get pidFormulaResultNotFinite => '這串運算沒有得出可用的數值，因此沒有讀數可顯示。';

  @override
  String pidFormulaByteBeyondResponse(String letter, int count) {
    return '公式參照位元組 $letter，但回應只有 $count 個位元組。';
  }

  @override
  String get pidFormulaBaroControllerUnknown =>
      '這裡無法使用 BARO，因為無法判斷指的是哪一個控制器的大氣壓力。';

  @override
  String get pidFormulaBaroTwoDefinitions =>
      '有兩個定義同時提供大氣壓力，數值可能是其中任何一個，因此無法採用。請移除其中一個測量大氣壓力的錶。';

  @override
  String get pidFormulaBaroNotYetMeasured => '尚未取得大氣壓力量測值，無法計算。';

  @override
  String get pidFormulaBaroMeasurementStale => '大氣壓力量測值已過期，無法計算。';

  @override
  String get pidFormulaBaroParenFormUnsupported =>
      'BARO() 是 Android 氣壓計／ECU 大氣壓（psi），這個方言沒有實作。要用快取的大氣壓力請寫不帶括號的 BARO。';

  @override
  String get pidFormulaInt16Unclaimed =>
      'INT16 尚未被這個方言認領：wiki 寫可代替 (A*255)+B，那不是 (A*256)+B。請把其中一個等式直接寫進公式。';

  @override
  String pidFormulaTimeWindowUnsupported(String term) {
    return '$term 是這個方言尚未實作的延遲、平均或 totalizer Torque 函式，因此無法在這裡求值。它不是 0，也不是 MIN 或 MAX。';
  }

  @override
  String pidFormulaDependencyControllerUnknown(String reference) {
    return '這裡無法解析 $reference，因為無法判斷那個 PID 屬於哪一個控制器。';
  }

  @override
  String pidFormulaDependencyTwoDefinitions(String key) {
    return '有兩個定義同時解讀 $key，數值可能是其中任何一個，因此無法採用。請讓其中一個改用不同的模式+PID。注意：推算數值需要的 PID（010B、010C、010D）本 App 一定會讀取，把面板上的錶移掉不會停止讀取它們。';
  }

  @override
  String pidFormulaDependencyNotYetMeasured(String key) {
    return '尚未取得相依 PID $key 的有效數值。';
  }

  @override
  String get pidFormulaUnidentified => '這個公式無法求值，而編輯器沒有更具體的原因可顯示。';

  @override
  String get pidRejectionMalformedModeAndPid =>
      '不是有效的模式+PID（只接受十六進位字元，且位元組須成對）。';

  @override
  String pidRejectionServiceNotReadOnly(String service, String services) {
    return '服務 $service 不是唯讀查詢，不能週期性發送到車上。只允許 $services（現值、凍結幀、車輛資訊、ReadDataByIdentifier）。';
  }

  @override
  String get pidRejectionFreezeFrameNeedsFrame =>
      '凍結幀查詢需要 PID 與幀編號兩個位元組，例如 020500（PID 05、第 0 幀）。';

  @override
  String get pidRejectionIdentifierNeedsTwoBytes =>
      'ReadDataByIdentifier 需要兩個位元組的識別碼，例如 221101。';

  @override
  String pidRejectionIdentifierWrongLength(String service, int bytes) {
    return '服務 $service 的查詢需要 $bytes 個位元組的識別碼。';
  }

  @override
  String get pidRejectionNameRequired => '請輸入名稱。';

  @override
  String pidRejectionInvalidHeader(String text) {
    return '「$text」不是有效的標頭（11-bit CAN 為 3 碼、舊協定為 6 碼、29-bit CAN 為 8 碼）。';
  }

  @override
  String get pidRejectionBoundsRequired => '請填寫量程的上下限。';

  @override
  String pidRejectionMinNotANumber(String text) {
    return '量程下限「$text」不是有效的數值。';
  }

  @override
  String pidRejectionMaxNotANumber(String text) {
    return '量程上限「$text」不是有效的數值。';
  }

  @override
  String get pidRejectionMinNotFinite => '量程下限必須是有限的數值。';

  @override
  String get pidRejectionMaxNotFinite => '量程上限必須是有限的數值。';

  @override
  String pidRejectionRedlineNotANumber(String text) {
    return '紅線起點「$text」不是有效的數值。';
  }

  @override
  String get pidRejectionRedlineNotFinite => '紅線起點必須是有限的數值。';

  @override
  String get pidRejectionMaxNotAboveMin => '量程上限必須大於下限。';

  @override
  String pidImportMalformedCsv(String detail) {
    return '這個檔案無法以 CSV 讀取：$detail';
  }

  @override
  String get pidImportNoRows => '檔案沒有任何資料列。';

  @override
  String pidImportDuplicateHeaderColumns(String columns) {
    return '標題列有重複的欄位名稱：$columns。無法判斷該用哪一欄，請先修正檔案。';
  }

  @override
  String pidImportMissingRequiredColumns(String columns, String required) {
    return '標題列缺少必要欄位：$columns。$required 都是必要的。';
  }

  @override
  String pidImportRowTooFewColumns(int line) {
    return '第 $line 行：欄位不足，至少需要名稱、簡稱、PID、公式。';
  }

  @override
  String pidImportRowInvalidModeAndPid(int line, String text) {
    return '第 $line 行：「$text」不是有效的模式+PID（只接受十六進位字元，且位元組須成對）。';
  }

  @override
  String pidImportRowEmptyEquation(int line) {
    return '第 $line 行：公式為空。';
  }

  @override
  String pidImportRowRejected(int line, String reason) {
    return '第 $line 行：$reason';
  }

  @override
  String pidImportRowRangeDefaulted(int line, double min, double max) {
    return '第 $line 行：量程留空，已套用預設 $min–$max。請確認這個刻度適合這個感測器。';
  }

  @override
  String get pidImportNothingImportable => '檔案裡有資料列，但沒有任何一列是 PID 定義。';

  @override
  String get dtcCategoryNoAnswer => '這個類別沒有回應。請重新掃描。';

  @override
  String get dtcCategoryError => '這個類別讀取失敗。完整錯誤保留在紀錄裡。';

  @override
  String get dtcCategoryDisconnected => '讀取這個類別時連線中斷。';

  @override
  String get dtcCategoryPending => '控制器已收到請求、仍在處理中。請稍候再掃描一次——這不是拒絕。';

  @override
  String get dtcCategoryUnattributed =>
      '有讀到故障碼，但回應標頭是關閉的，因此不知道是哪些控制器回答。這是部分結果，不是車輛正常。';

  @override
  String dtcCategorySilentControllers(int count, String controllers) {
    return '有 $count 個控制器沒有回應這次查詢（$controllers）。已回應的部分仍然有效，但不能當作全車結果。';
  }

  @override
  String dtcCategoryUnresolvedSources(int count, String addresses) {
    return '有 $count 筆回應無法判斷是哪個控制器送出的（$addresses）。已讀到的結果仍然有效，但不能當作全車結果。請重新掃描。';
  }

  @override
  String dtcCategoryPendingControllers(int count, int answered) {
    return '有 $count 個控制器還在處理這次查詢，$answered 個已回應。結果尚不完整，請稍候再掃描一次。';
  }

  @override
  String dtcCategoryRefusedControllers(int refused, int answered) {
    return '有 $refused 個控制器拒絕回答（$answered 個已回應）。這次掃描無法涵蓋全車，結果並不完整。';
  }

  @override
  String dtcCategoryUnrecognisedResponses(int count, int answered) {
    return '有 $count 筆回應無法辨識（$answered 個已回應）。其餘結果仍然有效，但這次掃描並不完整。';
  }

  @override
  String dtcCategoryMilCountMismatch(
    String controller,
    int claimed,
    int observed,
  ) {
    return '$controller 回報有 $claimed 筆已確認故障碼，但這次掃描只讀到 $observed 筆。請以車輛儀表為準，並洽維修廠。';
  }

  @override
  String dtcCategoryMilLitNoCodes(String controller) {
    return '$controller 回報故障燈亮著，但沒有讀到它所屬的故障碼。請以車輛儀表為準，並洽維修廠。';
  }

  @override
  String dtcCategoryMilDisagreement(String controllers) {
    return '車輛自身狀態與讀到的故障碼不符（$controllers）。請以車輛儀表為準，並洽維修廠。';
  }

  @override
  String get connectPairedListFailed => '無法讀取已配對的藍牙清單。請確認藍牙已開啟後再試。';

  @override
  String get connectBleScanUnavailable => '藍牙目前無法使用。請稍後再搜尋。';

  @override
  String get connectBleScanBluez =>
      '找不到可用的 BlueZ／D-Bus 藍牙服務。請確認系統已安裝並啟動 bluetooth 服務後再試。';

  @override
  String get connectBleScanUnclassified => 'BLE 搜尋失敗。';

  @override
  String dtcClearNrcConditions(String controller) {
    return '$controller 拒絕清除，因為目前的車輛狀態不允許。多數控制器在引擎運轉時不會清除故障記憶。請將電門轉到 ON 但不要發動引擎，然後再試一次。';
  }

  @override
  String dtcClearNrcUnsupported(String controller) {
    return '$controller 不支援清除服務（Mode 04）。這輛車的故障碼可能要用原廠或專用診斷設備才能清除。';
  }

  @override
  String dtcClearNrcBusy(String controller) {
    return '$controller 目前忙碌中。請稍候再試一次。';
  }

  @override
  String dtcClearNrcSecurity(String controller) {
    return '$controller 要求先通過安全認證才允許清除，這需要原廠或專用診斷設備。';
  }

  @override
  String dtcClearNrcOther(String controller, String code) {
    return '$controller 拒絕清除（原因碼 $code）。請稍候再試一次。';
  }

  @override
  String dtcClearSilentControllers(int count, String controllers) {
    return '有 $count 個控制器沒有回應清除指令（$controllers）。已回應的控制器已清除，其餘可能仍有故障碼。請重新掃描，不要再送一次清除。';
  }

  @override
  String dtcClearUnresolvedSources(int count, String addresses) {
    return '掃描時有 $count 筆回應無法判斷是哪個控制器送出的（$addresses），因此無法確認清除指令會送到哪些控制器。請重新掃描；若該位址一直沒有再出現，請重新連線後再試。';
  }

  @override
  String dtcClearUnresolvedSourcesDoNotRepeat(int count, String addresses) {
    return '清除指令的回應中有 $count 筆無法判斷來源的資料（$addresses）。不要再送一次清除。請重新掃描確認哪些故障碼還在。';
  }

  @override
  String dtcClearNrcConditionsDoNotRepeat(String controller) {
    return '$controller 拒絕清除，因為目前的車輛狀態不允許。多數控制器在引擎運轉時不會清除故障記憶。請將電門轉到 ON 但不要發動引擎，再重新掃描確認哪些故障碼還在。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。';
  }

  @override
  String dtcClearNrcUnsupportedDoNotRepeat(String controller) {
    return '$controller 不支援清除服務（Mode 04）。這輛車的故障碼可能要用原廠或專用診斷設備才能清除。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認哪些故障碼還在。';
  }

  @override
  String dtcClearNrcBusyDoNotRepeat(String controller) {
    return '$controller 目前忙碌中。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認哪些故障碼還在。';
  }

  @override
  String dtcClearNrcSecurityDoNotRepeat(String controller) {
    return '$controller 要求先通過安全認證才允許清除，這需要原廠或專用診斷設備。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。';
  }

  @override
  String dtcClearNrcOtherDoNotRepeat(String controller, String code) {
    return '$controller 拒絕清除（原因碼 $code）。不要再送一次全車清除 —— 重複清除會讓可能已經清除的控制器再一次重置排放就緒狀態。請重新掃描確認哪些故障碼還在。';
  }

  @override
  String get sharePolicyDenied => '目前的連線或行車狀態不允許匯出。';

  @override
  String get shareSafetyChanged => '準備匯出期間狀態已改變，未開啟分享。';

  @override
  String get shareSizeLimit => '匯出檔超過 32 MiB 上限。';

  @override
  String get shareStagingBusy => '先前的分享檔仍在保留期內，請稍後再試。';

  @override
  String get shareCleanupRequired => '分享暫存區需要在重新啟動後檢查。';

  @override
  String get shareSpaceUnknown => '無法確認分享檔所需的可用空間。';

  @override
  String get shareNoSpace => '儲存空間不足，無法準備分享檔。';

  @override
  String get shareHandoffFailed => '檔案已準備完成，但系統分享介面無法開啟。';

  @override
  String get shareStorageFailure => '準備或記錄分享結果時發生儲存錯誤。';

  @override
  String shareTelemetrySubject(String sessionId) {
    return '本機 OBD 紀錄 $sessionId';
  }

  @override
  String shareRawTranscriptSubject(String stamp) {
    return 'Telltale 傳輸紀錄 $stamp';
  }

  @override
  String get shareRecoveredTranscriptSubject => 'Telltale 傳輸紀錄（上一次連線）';

  @override
  String get sharePidCsvSubject => 'Telltale 自訂 PID 定義';

  @override
  String get shareTorqueSubsetCsvSubject => 'Torque 相容 PID 定義';

  @override
  String get shareHumanReportCsvSubject => 'Telltale 人類可讀 PID 報表';

  @override
  String get transcriptExportUnidentified => '匯出失敗。';

  @override
  String get handshakeNoteUnexpected => '此步驟發生未預期的錯誤。完整錯誤保留在紀錄裡。';

  @override
  String pidFormulaUnsupportedConstruct(String term) {
    return '$term 是這個方言尚未實作的 Torque 函式，因此無法在這裡求值。';
  }

  @override
  String pidImportRowFormulaRejected(int line, String reason) {
    return '第 $line 行：$reason';
  }

  @override
  String get telemetryHistoryNeedsForeground => '請回到 App 後再操作';

  @override
  String get telemetrySessionPolicyChanged => '操作期間行車或連線狀態已改變';

  @override
  String get telemetrySessionInvalidId => '紀錄識別碼無效';

  @override
  String get telemetrySessionNotFound => '找不到這筆本機紀錄';

  @override
  String get telemetrySessionStorageFailed => '本機儲存作業失敗';

  @override
  String get telemetrySessionShareFailed => '無法準備或開啟分享';

  @override
  String get pidMutationPersistFailed => '自訂 PID 清單無法寫入。沒有任何變更。';

  @override
  String get powertrainAuthorizeYearOutOfRange => '該年式不在這個設定檔記載的年份範圍內。';

  @override
  String get connectionLayerTransport => '連線方式';

  @override
  String get connectionLayerProtocol => '協定';

  @override
  String get connectionLayerEcu => '控制器回應';

  @override
  String get connectionLayerEvidence => '證據';

  @override
  String get connectionLayerUnknown => '未知';

  @override
  String get connectionLayerNotObserved => '未觀察到';

  @override
  String get connectionLayerObserved => '已觀察';

  @override
  String get connectionLayerAnswered => '有回應';

  @override
  String get connectionLayerSoftware => '軟體';

  @override
  String get connectionLayerDemo => '內建模擬器';

  @override
  String get connectionLayerBle => '藍牙 LE';

  @override
  String get connectionLayerClassic => '藍牙 Classic';

  @override
  String get connectionLayerWifi => '無線網路';

  @override
  String connectionLayerRequestedObserved(String requested, String observed) {
    return '要求 $requested，實際 $observed';
  }

  @override
  String get connectionLayerKwpSubtypeUnknown => 'KWP，5-baud 與 fast 無法分辨';

  @override
  String get connectionFailureOpenSettings => '開啟系統設定。';

  @override
  String get connectionFailureTurnRadioOn => '請開啟藍牙。';

  @override
  String get connectionFailureCheckDistanceOrPower =>
      '適配器可能太遠或沒有供電。那是可能的原因，不是已確認的發現。';

  @override
  String get connectionFailureCheckIgnitionProtocolAdapter =>
      '請檢查電門、協定或適配器能力。沒有回應不能當成這輛車沒有 OBD。';

  @override
  String get connectionFailureRetryOrAuto => '請重試，或把協定設成 Auto。';

  @override
  String get connectionFailureKeepInvalidAndExport =>
      '這筆回應無效。維持無效並匯出有限診斷；它不是讀數。';

  @override
  String get settingsCatalogMarketCa => '加拿大（NRCan）';

  @override
  String get settingsCaPickerTitle => '加拿大官方車輛目錄';

  @override
  String settingsCaPickerScope(int firstYear, int lastYear) {
    return '僅 $firstYear–$lastYear 的加拿大油耗標示列。內燃機、電池電動與插電混合動力維持分開的資源類。相同廠牌／車名不是 EPA 或臺灣認證列。';
  }

  @override
  String get settingsCaMotorNotPower => '電機功率（kW）不是輪馬力，不會套用。';

  @override
  String get settingsCaClassIce => '內燃機';

  @override
  String get settingsCaClassBev => '電池電動';

  @override
  String get settingsCaClassPhev => '插電混合動力';

  @override
  String settingsCaWillApplyOnly(String fields) {
    return '只會套用 $fields。電機 kW、油耗、續航、CO2、VE、Cd、迎風面積、Crr 與傳動效率維持未解。';
  }

  @override
  String get serviceRecipesTitle => '診斷配方與主動測試';

  @override
  String get serviceRecipesSubtitle => '標準規範服務配方與非致動能力探索';

  @override
  String get serviceRecipesSafetyBannerTitle => '零實車候選（Zero Live Candidates）';

  @override
  String get serviceRecipesSafetyBannerBody =>
      '嚴禁實車雙向致動執行（合格實車數：0）。現有配方僅限模擬與基準測試。';

  @override
  String get serviceRecipesDiscoverySection => 'Mode 08 非致動能力探索';

  @override
  String get serviceRecipesDiscoveryDescription =>
      '僅透過 CAN 查詢標準基準 TID（\$00、\$20…），絕不發送致動指令探測。';

  @override
  String get serviceRecipesDiscoveryButton => '探索 Mode 08 支援項目';

  @override
  String get serviceRecipesDiscovering => '正在查詢支援項目…';

  @override
  String serviceRecipesDiscoverySuccess(String tids) {
    return 'ECU 支援 Mode 08。支援 TID：$tids';
  }

  @override
  String get serviceRecipesDiscoveryUnsupported => '此 ECU 不支援 Mode 08';

  @override
  String serviceRecipesDiscoveryUnknown(String reason) {
    return 'Mode 08 支援狀態未知：$reason';
  }

  @override
  String serviceRecipesDiscoveryPartialWarning(String reason, String blocks) {
    return '探索未完全完成（$reason）。未完成區塊：$blocks。未查到不代表不支援。';
  }

  @override
  String get serviceRecipesCatalogSection => '可用服務配方清單';

  @override
  String get serviceRecipesSimulationBadge => '模擬可用';

  @override
  String get serviceRecipesLiveBlockedBadge => '禁止實車（0 實車候選）';

  @override
  String serviceRecipesStandard(String standard) {
    return '標準規範：$standard';
  }

  @override
  String serviceRecipesEcuHeader(String header) {
    return '目標 ECU 標頭：$header';
  }

  @override
  String serviceRecipesHash(String hash) {
    return '標準 SHA-256：$hash';
  }

  @override
  String get serviceRecipesDetailTitle => '服務配方詳細資訊';

  @override
  String get serviceRecipesPreconditions => '安全前置條件';

  @override
  String get serviceRecipesRecovery => '控制權釋放／恢復指令';

  @override
  String get serviceRecipesClose => '關閉';

  @override
  String get serviceRecipesDiscoveryRequiresCan => '需要作用中的 OBD-II CAN 匯流排連線。';

  @override
  String serviceRecipesLoadError(String error) {
    return '載入服務配方時發生錯誤：$error';
  }

  @override
  String get serviceRecipesNoPreconditions => '無';

  @override
  String get settingsServiceRecipesEntry => '車行診斷配方與主動測試';

  @override
  String get settingsServiceRecipesDesc => '檢視工作站服務配方並安全探索 Mode 08 支援項目';

  @override
  String get mode08ReasonUnheaderedLimitation =>
      '來源歸因與覆蓋完整度未確認：無標頭回應無法建立跨區塊 ECU 身分';

  @override
  String mode08ReasonNoResponseWithEcu(
    String block,
    String ecu,
    String marker,
  ) {
    return '區塊 $block 來自 $ecu 無回應：$marker';
  }

  @override
  String mode08ReasonNoResponse(String block, String marker) {
    return '區塊 $block 無回應：$marker';
  }

  @override
  String mode08ReasonNegativeWithEcu(String block, String ecu, String nrc) {
    return '區塊 $block 來自 $ecu 負回應 (NRC $nrc)';
  }

  @override
  String mode08ReasonNegative(String block, String nrc) {
    return '區塊 $block 負回應 (NRC $nrc)';
  }

  @override
  String mode08ReasonMalformedWithEcu(
    String block,
    String ecu,
    String details,
  ) {
    return '區塊 $block 來自 $ecu 格式錯誤：$details';
  }

  @override
  String mode08ReasonMalformed(String block, String details) {
    return '區塊 $block 格式錯誤：$details';
  }

  @override
  String mode08ReasonTimeout(String block) {
    return '區塊 $block 查詢逾時';
  }

  @override
  String get mode08ReasonBudgetExceeded => '在查詢所有區塊前已超出預算時間';

  @override
  String get mode08ReasonSessionDisconnected => '探索期間連線中斷或被取代';

  @override
  String mode08ReasonUnqueriedAnnounced(String blocks) {
    return 'ECU 宣告但未查詢的區塊：$blocks';
  }

  @override
  String get mode08ReasonRequiresCanBus => 'Mode 08 功能探索需要解析的 OBD-II CAN 匯流排';

  @override
  String get mode08ReasonUnexpectedExecution => '查詢支援 TID 時收到非預期的執行回應';

  @override
  String get pidDetailEmptyTitle => '選取 PID';

  @override
  String get pidDetailEmptyBody => '從清單中選取一個 PID 以檢視其定義與即時狀態。';

  @override
  String get pidDetailRangeLabel => '範圍';

  @override
  String get pidDetailPriorityLabel => '優先權';

  @override
  String pidDetailHeaderDefault(String header) {
    return '預設 ($header)';
  }

  @override
  String get dtcSystemOverview => '系統總覽';

  @override
  String get dtcPartialObservationBadge => '部分掃描';

  @override
  String get dtcPartialObservationBody => '此故障碼已讀取，但該類別在所有控制器間的掃描未完整完成。';

  @override
  String get dtcLinkedFreezeFrameTitle => '關聯凍結幀';

  @override
  String get dtcNoLinkedFreezeFrame => '這次掃描沒有可安全歸屬於此故障碼與控制器的凍結幀。';

  @override
  String get performanceGuideTitle => '起步加速測試指南';

  @override
  String get performanceGuideStep1 => '1. 選擇目標車速，然後準備計時';

  @override
  String get performanceGuideStep2 => '2. 將車輛完全停妥，等待畫面顯示已就緒';

  @override
  String get performanceGuideStep3 => '3. 開始加速；偵測到起步後會自動開始計時';

  @override
  String get performanceGuideStep4 => '4. 到達目標車速後即完成本次計時';

  @override
  String get performanceRecordingTrace => '加速中... 正在記錄速度點位';

  @override
  String get performanceNoAnalysisTitle => '沒有足夠的分析資料';

  @override
  String get performanceNoAnalysisBody => '本次計時在取得足夠的車速樣本前已中止，因此無法產生速度軌跡或分段成績。';

  @override
  String get connectActivityReconnectingAutomatically => '轉接器停止回應，正在自動重新連線…';
}
