// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get adapterErrorActivityAlert => 'バスアクティビティ警告。';

  @override
  String get adapterErrorBufferFull => 'アダプターのバッファがオーバーフローしました。';

  @override
  String get adapterErrorBus => 'バスエラーです。配線に問題がある可能性があります。';

  @override
  String get adapterErrorBusBusy => 'バスがビジー状態です。';

  @override
  String get adapterErrorBusInit => 'バスの初期化に失敗しました。';

  @override
  String get adapterErrorCan => 'CANバスエラーです。';

  @override
  String get adapterErrorData => '受信したデータが正しくありません。';

  @override
  String get adapterErrorFeedback => '信号フィードバックエラーです。';

  @override
  String get adapterErrorInternal => 'アダプターの内部エラーです。';

  @override
  String get adapterErrorLowPowerAlert => 'アダプターがまもなく省電力モードに入ります。';

  @override
  String get adapterErrorLowVoltageReset => '低電圧によりアダプターがリセットされました。';

  @override
  String get adapterErrorNoData =>
      '応答がありませんでした。一時的に応答がないだけか、車両がこの項目に対応していない可能性があります。';

  @override
  String get adapterErrorStopped => '通信が中断されました。';

  @override
  String get adapterErrorUnableToConnect =>
      'ECUと通信できません。イグニッションがONになっているか確認してください。';

  @override
  String get adapterErrorUnknownCommand => 'アダプターはこのコマンドに対応していません。';

  @override
  String get appTagline => '車両リアルタイムテレメトリー';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => '外観';

  @override
  String get connectActivityAbortingPreviousConnection =>
      '前の接続を停止しています。少々お待ちください…';

  @override
  String get connectAnswerBleWithClassic =>
      'Bluetooth LE を選んでください。事前のペアリングは不要です。アプリ内で直接スキャンしてください。システムのBluetoothペアリング一覧に表示されても、そこではペアリングしないでください（その方法では接続できません）。スキャンしても見つからない場合、箱の「4.0」という表記はチップの規格にすぎないため、代わりに Bluetooth Classic を使ってください。';

  @override
  String get connectAnswerBleWithoutClassic =>
      'Bluetooth LE を選んでください。事前のペアリングは不要です。アプリ内で直接スキャンしてください。システムのBluetoothペアリング一覧に表示されても、そこではペアリングしないでください（その方法では接続できません）。スキャンしても見つからない場合は、アダプターの電源が入っているか確認するか、代わりに Wi-Fi を試してください（この端末は Bluetooth Classic に対応していません）。';

  @override
  String get connectAnswerClassic =>
      'Bluetooth Classic を選んでください。先にシステム設定でペアリングを完了してください（アプリ側でペアリングを行うことはできません）。パスキーは通常 1234 または 0000 です。';

  @override
  String get connectAnswerWifiDesktop =>
      'Wi-Fi を選んでください。先にこの端末をそのネットワークに接続してから、この画面に戻ってアドレスを入力してください。';

  @override
  String get connectAnswerWifiPhone =>
      'Wi-Fi を選んでください。先にスマートフォンをそのネットワークに接続してから、この画面に戻ってアドレスを入力してください。';

  @override
  String get connectBleBody =>
      'BLE アダプターは事前のペアリングが不要です。検索してデバイスを選んでください（よくある名前は OBDII、V-LINK、Vgate、IOS-Vlink です）。';

  @override
  String connectBleEmptyScan(String next) {
    return 'スキャンが完了しましたが、BLE アダプターは見つかりませんでした。次の順に確認してください。まずアダプターのランプが点灯しているか（多くのOBDソケットはイグニッションがONになるまで給電されません）、次に距離です（車内に座ってからスキャンしてください）。$next BLE アダプターはシステム設定でのペアリングが不要なだけでなく、そこではペアリングしてはいけません（その方法では動作しません）。';
  }

  @override
  String get connectBleEmptyScanNextClassic =>
      '最後に箱の仕様を確認してください。2.0 または 3.0 と記載されていれば Bluetooth Classic であり、この一覧には一切表示されないため、代わりに上の Bluetooth Classic を使ってください。';

  @override
  String get connectBleEmptyScanNextWifi =>
      '最後に箱の仕様を確認してください。2.0／3.0 または Wi-Fi のみと記載されている場合は、代わりに Wi-Fi を試してください（この端末は Bluetooth Classic に対応していません）。';

  @override
  String get connectBlePermissionDeniedForever =>
      'Bluetooth権限が永久に拒否されています。システムから再度確認ダイアログは表示されないため、アプリの設定画面から有効にしてください。';

  @override
  String get connectBlePermissionNeeded => '検索にはBluetooth権限が必要です。';

  @override
  String get connectBleScan => 'BLE デバイスを検索';

  @override
  String get connectBleScanning => '検索中…';

  @override
  String get connectBleUnavailableHost => 'この端末では Bluetooth LE はまだ利用できません';

  @override
  String get connectBluetoothOff =>
      'Bluetoothがオフです。先にシステム設定でBluetoothをオンにしてください。';

  @override
  String get connectBluetoothPermissionDeniedForever =>
      'Bluetooth権限が永久に拒否されています。システム設定で有効にしてから、もう一度お試しください。';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      'ペアリング済みアダプターの一覧表示にはBluetooth権限が必要です。';

  @override
  String get connectBody =>
      'ELM327 アダプターを差し込んでイグニッションをONにするか、内蔵シミュレーターを使用してください。';

  @override
  String get connectCancel => 'キャンセル';

  @override
  String get connectClassicEmptyLinuxPort =>
      'Bluetoothシリアルポート（/dev/rfcomm*）が見つかりません。先に BlueZ で ELM327 をペアリングし、rfcomm bind（または同等の方法）で RFCOMM TTY を作成してから再試行してください。';

  @override
  String get connectClassicEmptyPaired =>
      'ペアリング済みのアダプターが見つかりません。先にシステムのBluetooth設定でペアリングしてください（多くの ELM327 のパスキーは 1234 または 0000 です）。';

  @override
  String get connectClassicEmptyWindowsPort =>
      'Bluetoothシリアルポート（COMx）が見つかりません。先にWindowsのBluetooth設定で ELM327 をペアリングし、デバイスマネージャーに「Standard Serial over Bluetooth link」が表示されているか確認してください。';

  @override
  String get connectClassicListLinuxPort =>
      'ここには BlueZ がバインドしたBluetoothシリアルポート（/dev/rfcomm* または同等）が一覧表示されます。一覧が空の場合は、システム側でまだ RFCOMM ノードが作成されていない状態であり、アプリの不具合ではありません。';

  @override
  String get connectClassicListPaired =>
      'ここにはシステムとペアリング済みのすべてのデバイス（イヤホンやスピーカーを含む）が表示され、アダプターと思われるものが先頭に並びます。別のデバイスを誤って選んだ場合は、接続失敗を待たずに「キャンセル」を押せば、すぐに選び直せます。';

  @override
  String get connectClassicListWindowsPort =>
      'ここにはBluetoothに関連付けられたCOMポート（「Standard Serial over Bluetooth link」）が一覧表示されます。一覧が空の場合は、システム側でまだ仮想シリアルポートが作成されていない状態であり、アプリの不具合ではありません。';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic（SPP）は現在 Android、macOS（IOBluetooth RFCOMM）、Windows（COM）、Linux（/dev/rfcomm*）で利用可能です';

  @override
  String get connectClassicUnavailableIos =>
      'iOS はサードパーティ製アプリに Bluetooth SPP を開放していません';

  @override
  String get connectConnect => '接続';

  @override
  String get connectDemoBody =>
      '2.0 L ターボ4気筒エンジンのアイドリング、加速、巡航、減速サイクルをシミュレートし、各信号は物理的な整合性を保って変化します（シフトアップ時にはエンジン回転数が下がり、車速は上がり続けます）。故障コード、VIN の読み取り、fastMode の一括クエリもすべてそのまま動作します。';

  @override
  String get connectDemoStart => 'シミュレーターを起動';

  @override
  String get connectHandshakeTitle => 'ELM327 初期化';

  @override
  String get connectHandshakeTitleLastAttempt => 'ELM327 初期化（前回の試行）';

  @override
  String get connectHeadline => '接続方法を選択';

  @override
  String get connectIssueAdapterAcceptedThenSilent =>
      'アダプターは接続を受け入れましたが、時間内に応答がありませんでした。多くの場合、まだ給電されていないか（大半のOBDソケットはイグニッションON時のみ給電されます）、別のアプリがすでにこのアダプターに接続しています。他のアプリが接続している場合は、そのアプリを終了してから再試行してください。';

  @override
  String connectIssueAdapterSilentOnReset(String command) {
    return 'アダプターがリセットコマンド（$command）に応答しませんでした。このデバイスが ELM327 アダプターではないか、別のデバイスに誤って接続した可能性があります。';
  }

  @override
  String get connectIssueAdapterStoppedResponding =>
      'アダプターの応答が停止したため、接続が切断されました。';

  @override
  String get connectIssueConnectionSetupFailed =>
      '接続を確立する途中で失敗しました。アダプターの電源が入っており、近くにあることを確認してから再試行してください。エラーの全文は下の通信記録に残されています。';

  @override
  String get connectIssueHandshakeIncomplete =>
      '初期化が完了しませんでした。アダプターが非対応である可能性があります。';

  @override
  String connectIssueHandshakeStepFailed(String command, String reason) {
    return '初期化が $command で失敗しました（$reason）。アダプターがしっかり差し込まれ、車両のイグニッションがONになっているか確認してください。';
  }

  @override
  String get connectIssuePreviousConnectionStillAborting =>
      '前の接続の停止処理がまだ続いており、アダプターがまだ解放されていません。数秒待ってからもう一度お試しください。';

  @override
  String get connectLastAdapterConnect => '今すぐ接続';

  @override
  String get connectLastAdapterForget => '登録解除';

  @override
  String get connectLastAdapterTitle => '前回使用したアダプター';

  @override
  String get connectOpenAppSettings => 'アプリの設定を開く';

  @override
  String get connectOpenSystemSettings => 'システム設定を開く';

  @override
  String get connectOpeningConnection => '接続を開いています…';

  @override
  String get connectPairedPill => 'ペアリング済み';

  @override
  String get connectQuestionBle => '箱や販売ページ、またはデバイス名に BLE、4.0、5.0 の表記がありますか？';

  @override
  String get connectQuestionClassic =>
      'どれにも当てはまらない場合：少し古い製品で、箱に 2.0 または 3.0 と印刷されていますか？';

  @override
  String get connectQuestionWifiDesktop =>
      'システムの Wi-Fi 一覧に新しいネットワーク（V-LINK や WiFi_OBDII など）が増えていますか？';

  @override
  String get connectQuestionWifiPhone =>
      'スマートフォンの Wi-Fi 一覧に新しいネットワーク（V-LINK や WiFi_OBDII など）が増えていますか？';

  @override
  String get connectSearchAgain => '再検索';

  @override
  String connectSignalStrength(int bars, int total) {
    return '信号強度 $bars/$total';
  }

  @override
  String get connectTranscriptKept =>
      '今回の試行の完全な通信記録が保存されました。1行のメッセージよりも、この記録を持ち帰る方が原因調査に役立ちます。';

  @override
  String get connectTransportBleDescription => 'GATT UART — 近年の省電力アダプター';

  @override
  String get connectTransportBleTitle => 'Bluetooth LE';

  @override
  String get connectTransportClassicDescription =>
      'RFCOMM / SPP — 最も一般的な廉価版 ELM327';

  @override
  String get connectTransportClassicTitle => 'Bluetooth Classic';

  @override
  String get connectTransportDemoDescription =>
      '内蔵シミュレート ECU — ハードウェアなしで全機能を体験';

  @override
  String get connectTransportDemoTitle => 'デモシミュレーター';

  @override
  String get connectTransportWifiDescription =>
      'TCP ポート（通常は 192.168.0.10:35000）';

  @override
  String get connectTransportWifiTitle => 'Wi-Fi';

  @override
  String get connectWhichIntro =>
      'SPP や GATT といった用語は気にしなくて構いません。アダプターを差し込んだ後の挙動で判断してください：';

  @override
  String get connectWhichNoteGuessing =>
      '間違えても問題ありません。接続できなければ戻って別の方法を試せます。どうしても進めない場合は、一番下の「デモシミュレーター」でアプリ自体が正常に動作するか確認してください。';

  @override
  String get connectWhichNoteIos =>
      'iPhone では Wi-Fi または BLE のみ使用できます。一般的な Bluetooth ELM327 は iOS では一切動作しません。これはOSの制限であり、他のアプリでも同じです。';

  @override
  String get connectWhichTitle => 'どれを選べばよいかわかりませんか？';

  @override
  String get connectWifiHostLabel => 'IPアドレス';

  @override
  String get connectWifiHostRequired => 'アダプターのIPアドレスを入力してください。';

  @override
  String get connectWifiInstructionsDesktop =>
      '先にこのコンピューターをアダプターが発信する Wi-Fi ホットスポットに接続してから、アドレスを入力してください。インターネットに接続できないという警告が表示された場合は、接続を維持することを選択してください。デスクトップ環境では通常ホットスポットがデフォルトルートとして扱われるため、Androidのような Wi-Fi ルート固定は不要です。';

  @override
  String get connectWifiInstructionsPhone =>
      '先にスマートフォンをアダプターが発信する Wi-Fi ホットスポットに接続してから、アドレスを入力してください。「この Wi-Fi はインターネットに接続できません。接続を維持しますか？」と尋ねられたら、維持を選択してください。Androidでは、Telltale は接続中の通信を Wi-Fi ルートに固定するよう試み、モバイルデータ通信へ切り替わらないようにします。';

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '「$value」は有効なポート番号ではありません。範囲は $min–$max です。';
  }

  @override
  String get connectWifiPortLabel => 'ポート';

  @override
  String connectWifiPortRequired(int port) {
    return 'ポート番号を入力してください（多くのアダプターは $port です）。';
  }

  @override
  String get dashboardBatchedPolling => '一括ポーリング';

  @override
  String get dashboardBatchingEnabled => '一括要求有効';

  @override
  String get dashboardChoosePids => 'PIDを選択';

  @override
  String get dashboardEmptyBody => 'PID画面で監視したい信号を選ぶと、ここに表示されます。';

  @override
  String get dashboardEmptyTitle => 'ダッシュボードは空です';

  @override
  String get dashboardGenericObd => '汎用OBD';

  @override
  String get dashboardLocalRecordings => 'ローカル記録';

  @override
  String get dashboardNotConnected => '未接続';

  @override
  String get dashboardPollingModeHelpAction => 'ポーリングモードについて';

  @override
  String get dashboardPollingModeHelpBatching =>
      '「一括要求有効」は、往復回数を減らすために Telltale が複数のPID要求を1回の通信にまとめられる状態であることを示します（一括要求が許可されており、無効化もされていません）。ただし、実際に1回の通信で複数がまとめられたかどうかは、車両側で対応が確認されたPIDや待機中の要求数にも依存するため、これは許可状態を示すものであり、実測された動作の記録ではありません。';

  @override
  String get dashboardPollingModeHelpObserved =>
      '「一括ポーリング」は、今回の接続で Mode 01 コマンドが実際に複数のPIDを1回の通信で運んだことを示します。これはその通信の記録であり、次回もまとめられることの保証やスループットの主張ではありません。';

  @override
  String get dashboardPollingModeHelpRate =>
      'PIDs/s は直近1秒間に観測されたレートであり、遅延、鮮度、精度を保証するものではありません。アダプター、バス、ECU、選択したPID、各応答のサイズ、およびエラーの有無によって変動します。';

  @override
  String get dashboardPollingModeHelpSingle =>
      '「単一要求モード」は、各 Mode 01 PID を1つずつ個別に読み取ることを意味します。Telltale は次の3つの場合にこのモードを使用します。バスが一括要求を一切受け付けない場合（すべての非CAN車両）、サポートブロックの応答がまだなく未確認PIDをまとめると応答が短く切れるため保留している場合、そして一括要求の応答が個別PIDに分割できる形で返らなかった場合（途中切断、アダプターのバッファフルによる拒否、または無応答）です。読み取り値の更新は継続し、これ自体は接続失敗ではありません。';

  @override
  String get dashboardPollingModeHelpTitle => 'ポーリングモード';

  @override
  String get dashboardSingleRequestMode => '単一要求モード';

  @override
  String get dashboardVinRead => 'VIN 読み取り済み';

  @override
  String get dashboardWorkspaceGauges => 'メーター';

  @override
  String get dashboardWorkspaceTrends => 'トレンド';

  @override
  String get datumBadgeCommunityDecode => 'コミュニティデコード';

  @override
  String get datumBadgeDemo => 'シミュレート値';

  @override
  String get datumBadgeEstimated => '推定';

  @override
  String get datumBadgeExperimental => '実験的';

  @override
  String get datumBadgeFieldVerified => '実車検証済み';

  @override
  String get datumBadgeInvalid => '無効';

  @override
  String get datumBadgeJustUpdated => '更新直後';

  @override
  String get datumBadgeOutOfReferenceRange => '基準範囲外';

  @override
  String get datumBadgePartial => '一部のみ';

  @override
  String get datumBadgeStale => '更新停止';

  @override
  String get datumBadgeTentativeDecode => '暫定デコード';

  @override
  String get datumBadgeUnverified => '未検証';

  @override
  String get datumBadgeUnverifiedOnThisVehicle => 'この車両では未検証';

  @override
  String get datumBadgeUserSupplied => 'ユーザー定義';

  @override
  String get datumGapModelYearUnknown => '年式不明';

  @override
  String get datumGapNoCatalogMatch => 'カタログ一致なし';

  @override
  String get datumGapVinNotRead => 'VIN 未読み取り';

  @override
  String get datumNextStepEstimateOnly => 'この推定値にのみ影響し、他の読み取り値はそのまま有効です。';

  @override
  String get datumNextStepGenericObd =>
      'このまま汎用OBDを続けるか、手動で車両を選択してパラメータを入力できます。';

  @override
  String get datumNextStepOtherReadings => '失敗はこの項目にのみ影響し、他の読み取り値はそのまま有効です。';

  @override
  String get datumNextStepRawOnly => '生の応答とエラーを確認できますが、どちらも通常の値として扱うことはできません。';

  @override
  String get datumReasonAssumptionsUnconfirmed => '前提条件は未確認ですが、推定値を表示しています。';

  @override
  String get datumReasonBusError => 'バスエラーです。';

  @override
  String get datumReasonFormulaError => '計算式エラーです。';

  @override
  String get datumReasonFuelEstimateMissingInputs => '燃料消費量の推定に必要な入力が不足しています。';

  @override
  String get datumReasonHeaderNotOnThisBus => 'ヘッダーがこの車両の使用しているバスと一致しません。';

  @override
  String get datumReasonHorsepowerEstimateMissingInputs =>
      '馬力の推定に必要な入力が不足しています。';

  @override
  String get datumReasonMalformedPacket => '不正なパケットです。生の応答のみ確認できます。';

  @override
  String get datumReasonNoAnswer => '無応答です。約1分後に自動で再試行します。';

  @override
  String get datumReasonNoReadingYet => 'まだ読み取り値がありません。';

  @override
  String get datumReasonNonFiniteValue => '有限の数値ではありません。';

  @override
  String get datumReasonOutOfReferenceRangeKept =>
      '通常の基準範囲外ですが、読み取ったまま保持しています。';

  @override
  String get datumReasonPidUnsupported => 'この車両はこのPIDに対応していません。';

  @override
  String get datumReasonUnsafeService => 'このサービスは読み取り専用クエリではありません。';

  @override
  String get datumReasonUnsafeServiceStopped =>
      'このサービスは読み取り専用クエリではないため、送信されませんでした。';

  @override
  String get datumStatusAssumptions => '前提条件';

  @override
  String get datumStatusClose => '閉じる';

  @override
  String get datumStatusFollowsData => '状態はデータに追従';

  @override
  String get datumStatusDetailsHint => 'タップして読み取り値の状態詳細を表示';

  @override
  String get datumStatusUnverifiedExplanation =>
      '「未検証」とは、お使いの車両でこのデコーダーを実車比較した記録がここに文書化されていないことを意味します。読み取り値が誤っているという意味ではなく、精度を保証するものでもありません。鮮度と異常は個別に表示されます。';

  @override
  String get datumStatusFormula => '計算式';

  @override
  String get derivedAirflow => '空気流量';

  @override
  String get derivedEcuFuelTitle => 'ECU 燃料データ';

  @override
  String get derivedEcuReported => 'ECU 報告値';

  @override
  String get derivedEngineHorsepower => 'エンジン馬力';

  @override
  String get derivedEstimatedFuelTitle => '推定燃料消費量';

  @override
  String get derivedEstimatesDetailsTitle => '推定の計算式と前提条件';

  @override
  String get derivedEstimatesTitle => '推定値';

  @override
  String get derivedFuelUse => '燃料消費量';

  @override
  String get derivedTorque => 'トルク';

  @override
  String get derivedUnavailableMessage => '車速と加速度のデータが届くまで馬力は推定できません';

  @override
  String dtcBothSilentDetail(Object mode) {
    return '車両が Mode $mode クエリに応答せず、Mode 03 にも応答しなかったため、車両が非対応なのか今回の接続で読み取れなかっただけなのかを判断できません。';
  }

  @override
  String dtcCategoryFault(Object category) {
    return '$categoryに関連する故障';
  }

  @override
  String get dtcClear => '消去';

  @override
  String get dtcClearCancel => 'キャンセル';

  @override
  String get dtcClearConfirm => '消去する';

  @override
  String get dtcClearDialogBody =>
      '保存済みおよび保留中の故障コードを消去して故障警告灯を消灯し、同時に排ガスレディネスもリセットします。車検や検査に通るには、車両が一通りの自己診断を再び完了する必要があります。永久故障コード（Mode 0A）は消去できません。';

  @override
  String get dtcClearDialogFrameUnread =>
      '今回のスキャンではフリーズフレームを読み取れませんでした。車両にフリーズフレームがないという意味ではありません。先に再スキャンしてから、消去するかどうかを決めてください。';

  @override
  String dtcClearDialogFrames(Object codes) {
    return '$codes のフリーズフレーム（故障発生時のエンジン回転数、水温、負荷の全記録）も同時に失われ、再び故障が発生するまで読み取ることはできません。';
  }

  @override
  String get dtcClearDialogTitle => '故障コードを消去しますか？';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今回のスキャンでは$count個のカテゴリ',
      one: '今回のスキャンでは1つのカテゴリ',
    );
    return '$_temp0（$categories）から完全な応答が得られなかったため、まだ表示されていない故障コードが存在する可能性があります。消去すると二度と読み取れません。';
  }

  @override
  String get dtcClearCancelledBeforeSend =>
      'アプリからコマンドが一切送信される前に消去がキャンセルされました。再スキャンしてから、まだ消去したい場合はもう一度お試しください。';

  @override
  String get dtcClearConfirmed => '消去コマンドを送信しました。';

  @override
  String get dtcClearFailureDoNotRepeat =>
      '消去コマンドがすでに車両に届いている可能性があります。もう一度送信しないでください。2回目の一括消去を送ると、すでにコードの消去を終えた可能性のあるコントローラーの排ガスレディネスまで再びリセットされるおそれがあります。再スキャンして残っているコードを確認してください。';

  @override
  String get dtcClearFailureGeneric =>
      '消去が完了しませんでした。再試行するかどうかを決める前に、まず再スキャンして現在の故障コードを確認してください。';

  @override
  String get dtcClearNotAccepted =>
      '消去に失敗しました。コマンドを受け付けたコントローラーはありません。もう一度お試しいただけます。';

  @override
  String get dtcClearPartiallyConfirmed =>
      '少なくとも1つのコントローラーが消去完了を報告しましたが、残りは確認できませんでした。消去コマンドを再送信しないでください。繰り返すと、すでに完了したコントローラーの排ガスレディネスが再びリセットされます。再スキャンして結果を確認してください。';

  @override
  String get dtcClearPreviousConnectionUnconfirmed =>
      '前回の接続で送信した消去コマンドの結果が未確認です。先に再スキャンしてどの故障コードが残っているか確認してから、消去するかどうかを決めてください。';

  @override
  String get dtcClearRescanSettled =>
      '前回の消去結果は完全には確認できませんでした。以下は今回の再スキャン後の実際の状態です。';

  @override
  String get dtcClearSentUnconfirmed =>
      '消去コマンドは送信されましたが、応答が通信中に破損したため、車両側で消去されたかどうかは不明です。再スキャンして確認してください。消去コマンドを再送信しないでください。すでに消去されていた場合、繰り返すと排ガスレディネスがリセットされます。';

  @override
  String get dtcClearTimeout =>
      '消去コマンドの送信後に応答がなかったため、車両側で消去されたかどうかは不明です。再スキャンして確認してください。むやみに消去コマンドを再送信しないでください。';

  @override
  String get dtcClearUnexpected =>
      '消去処理が正常に完了しなかったため、車両側で消去されたかどうかは不明です。再スキャンして確認してください。むやみに消去コマンドを再送信しないでください。';

  @override
  String get dtcClearing => '消去中…';

  @override
  String get dtcScanDisconnectedMidScan =>
      'スキャン中に接続が切断されたため、今回のスキャンは完了しませんでした。';

  @override
  String get dtcScanInterrupted =>
      'スキャンが途中で中断されたため（アプリがバックグラウンドに移行したか、接続が変化した可能性があります）、完全な結果を取得できませんでした。もう一度スキャンしてください。';

  @override
  String get dtcCompleteCleanBody =>
      'これは、応答したすべてのコントローラーが故障コードなしと報告したことを意味します。車両上のすべてのモジュールに問い合わせたという意味ではありません。';

  @override
  String get dtcCompleteCleanTitle => '応答したコントローラーはいずれも故障コードを報告しませんでした。';

  @override
  String dtcControllerLabel(Object controller) {
    return 'コントローラー $controller';
  }

  @override
  String get dtcDismiss => '閉じる';

  @override
  String dtcFreezeFrameBody(Object code) {
    return '$code が確定した瞬間にこのコントローラーが記録した値です。故障コードを消去すると、この記録も一緒に破棄されます。';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      'このコントローラーにはフリーズフレームがありますが、含まれる項目を尋ねるクエリに応答しなかったため、内容を読み取れませんでした。再スキャンすると読み取れる場合があります。';

  @override
  String get dtcFreezeFrameNothingDecodable =>
      'このコントローラーにはフリーズフレームがありますが、このアプリでデコードできる項目が含まれていません。';

  @override
  String get dtcFreezeFrameTitle => '故障発生時の車両状態';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'このフリーズフレームには他に$count項目ありますが、本アプリには対応する換算式がないため表示されていません。',
      one: 'このフリーズフレームには他に1項目ありますが、本アプリには対応する換算式がないため表示されていません。',
    );
    return '$_temp0';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '今回$count項目を読み取れませんでした（時間不足またはコントローラーの無応答の可能性があります）。再スキャンで読み取れる場合があります。',
      one: '今回1項目を読み取れませんでした（時間不足またはコントローラーの無応答の可能性があります）。再スキャンで読み取れる場合があります。',
    );
    return '$_temp0';
  }

  @override
  String get dtcFreezeFrameUnreadPanel =>
      '今回のスキャンではフリーズフレームを読み取れませんでした。車両にフリーズフレームがないという意味ではありません。故障コードを消去すると故障発生時の記録が永久に破棄されるため、先に再スキャンしてから消去するかどうかを決めてください。何度スキャンしても同じ場合は、この車両がフリーズフレームを提供していない可能性があります。';

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label（Mode $mode）· $count';
  }

  @override
  String get dtcHeadline => '故障コード';

  @override
  String get dtcListSeparator => '、';

  @override
  String get dtcManufacturerSpecific => 'メーカー固有コード — この車両のサービスマニュアルを確認してください';

  @override
  String get dtcMilOff => '故障警告灯は消灯しています';

  @override
  String get dtcMilOn => '故障警告灯が点灯しています';

  @override
  String get dtcMonitorBoostPressure => '過給圧';

  @override
  String get dtcMonitorCatalyst => '触媒';

  @override
  String get dtcMonitorComponents => '総合コンポーネント';

  @override
  String get dtcMonitorEgr => 'EGR / VVT システム';

  @override
  String get dtcMonitorEvaporative => 'エバポシステム（蒸発ガス）';

  @override
  String get dtcMonitorExhaustSensor => '排気ガスセンサー';

  @override
  String get dtcMonitorFuelSystem => '燃料システム';

  @override
  String get dtcMonitorGasolineParticulateFilter => 'ガソリン微粒子フィルター（GPF）';

  @override
  String get dtcMonitorHeatedCatalyst => '加熱式触媒';

  @override
  String get dtcMonitorMisfire => '失火';

  @override
  String get dtcMonitorNmhcCatalyst => 'NMHC 触媒';

  @override
  String get dtcMonitorNoxAftertreatment => 'NOx / SCR 後処理';

  @override
  String get dtcMonitorOxygenSensor => 'O2センサー';

  @override
  String get dtcMonitorOxygenSensorHeater => 'O2センサーヒーター';

  @override
  String get dtcMonitorParticulateFilter => '微粒子フィルター';

  @override
  String get dtcMonitorSecondaryAir => '二次空気噴射システム';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — このコードの詳細説明は本アプリに登録されていません';
  }

  @override
  String get dtcNotConnectedBody =>
      '故障コードを読み取るには、ELM327 アダプターに接続するか、シミュレーターを起動する必要があります。';

  @override
  String get dtcNotConnectedTitle => '未接続';

  @override
  String get dtcNotScanned => '未スキャン';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個のコントローラー',
      one: '1つのコントローラー',
    );
    return '3つのカテゴリすべてのクエリが完了しました。$_temp0（$controllers）は保留中および永久故障コードを実装していません。これは多くの車両で正常な仕様ですが、同時に車両全体に故障がないと断定できない理由でもあります。';
  }

  @override
  String get dtcPartialCleanTitle => '応答したカテゴリでは故障コードは報告されませんでした。';

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories からは応答がなかったため、状態を確認できません。車両に問題がないという意味ではありません。';
  }

  @override
  String dtcPartialCodesRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の故障コードが読み取られました',
      one: '1件の故障コードが読み取られました',
    );
    return 'このカテゴリの読み取りが中断される前に$_temp0が、対象範囲は不完全です：';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return 'このカテゴリでは一部のコントローラーのみが応答し、残りは応答しなかったため、車両全体の結果とすることはできません。$message';
  }

  @override
  String get dtcReadFailed => '読み取り失敗';

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label（Mode $mode）：$message';
  }

  @override
  String get dtcReadinessAllComplete => 'このコントローラーが担当するすべてのレディネスモニターが完了しています。';

  @override
  String dtcReadinessIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count項目のモニターがまだ完了していません',
      one: '1項目のモニターがまだ完了していません',
    );
    return '$_temp0。今すぐ検査を受けても合格しない可能性があります。';
  }

  @override
  String get dtcReadinessSaysNothing =>
      'このコントローラーはレディネスモニターを1つも報告しませんでした。排ガス監視を担当していない可能性があり、レディネスが完了しているという意味ではありません。';

  @override
  String get dtcReadinessTitle => '排ガスレディネス';

  @override
  String get dtcRescanFirst => '先に再スキャン';

  @override
  String get dtcRetry => '再試行';

  @override
  String get dtcScanBody =>
      'Mode 03（保存済み）、Mode 07（保留中）、Mode 0A（永久）の故障コードを読み取ります。';

  @override
  String get dtcScanTitle => '車両の故障コードをスキャン';

  @override
  String get dtcScanning => 'スキャン中…';

  @override
  String dtcSelfReportedCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'このコントローラーは確定した故障コードが$count件あると自己報告しています。',
      one: 'このコントローラーは確定した故障コードが1件あると自己報告しています。',
    );
    return '$_temp0';
  }

  @override
  String get dtcSelfReportedNoCodes => 'このコントローラーは確定した故障コードがないと自己報告しています。';

  @override
  String get dtcSilentCategoryHeadline => 'このカテゴリからは応答がありませんでした';

  @override
  String get dtcSilentPendingDetail =>
      '保留中の故障コード（Mode 07）からは応答がありませんでした。この ECU がこのサービスを実装していないか、今回読み取れなかっただけの可能性があります。無応答からは両者を区別できず、「保留中の故障がない」と解釈してはなりません。保存済み故障コードの結果には影響しません。';

  @override
  String get dtcSilentPermanentDetail =>
      '永久故障コード（Mode 0A）からは応答がありませんでした。このカテゴリは2010年頃の OBD-II 世代で導入されたため、古い車両では対応していない場合があります。ただし無応答は今回読み取れなかっただけの可能性もあり、両者を区別することはできません。保存済み故障コードの結果には影響しません。';

  @override
  String get dtcStartScan => 'スキャン開始';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return '車両が Mode $mode クエリに応答しなかったため、保存済みの故障コードがあるかどうかを確認できません。これは「故障コードがない」こととは異なります。';
  }

  @override
  String dtcTotalCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のコード',
      one: '1件のコード',
    );
    return '$_temp0';
  }

  @override
  String get dtcUnconfirmed => '確認不可';

  @override
  String get dtcUnknownError => '不明なエラー';

  @override
  String get dtcUnknownMonitor => '不明なモニター';

  @override
  String get dtcVerdictCompleteClean => '応答したコントローラーからの故障コードなし';

  @override
  String get dtcVerdictPartialClean => '一部未確認';

  @override
  String get fieldEventBody =>
      '車両が完全に停止しているときにのみ、同乗者または駐車中の操作者が押してください。イベントは生のOBDデータと同じタイムライン上に記録され、直ちに保存が試行されます。';

  @override
  String get fieldEventEngineStarted => 'エンジン始動';

  @override
  String get fieldEventHeading => '実車イベントマーカー';

  @override
  String get fieldEventIgnitionOn => 'イグニッション ON';

  @override
  String get fieldEventMemoryOnly =>
      'このセッションに記録されましたが、自動保存に失敗しました。今すぐ通信記録をエクスポートしてください。';

  @override
  String fieldEventRecorded(String marker) {
    return '記録・保存済み：$marker';
  }

  @override
  String get fieldEventRoadTestStarted => '走行テスト開始';

  @override
  String get fieldEventThrottleBlip => 'スロットルブリップ（空吹かし）';

  @override
  String get fieldEventUnavailable => '記録対象となる実車とのライブ接続がありません。';

  @override
  String get gaugeNoData => 'データなし';

  @override
  String gaugeNoDataBecause(String reason) {
    return 'データなし — $reason';
  }

  @override
  String gaugeReadingStale(String reading) {
    return '$reading（データの更新停止）';
  }

  @override
  String get gaugeUnsupportedByVehicle => 'この車両は非対応';

  @override
  String get handshakeNoteAborted => '前のステップが失敗したため中止されました。';

  @override
  String get handshakeNoteEcuRefusedSupportQuery =>
      'ECUがサポート照会を拒否しました（ネガティブレスポンス）。';

  @override
  String get handshakeNoteEcuSilent => 'ECUが応答しませんでした。';

  @override
  String get handshakeNoteNotAcknowledged => 'アダプターがこのコマンドに確認応答しませんでした。';

  @override
  String get handshakeNoteNotModeOnePositiveReply =>
      '応答が Mode 01 のポジティブレスポンスではありません。';

  @override
  String get handshakeNotePidEchoMismatch => '要求したPIDとは異なるPIDが応答でエコーされました。';

  @override
  String get handshakeNoteSupportMaskTooShort =>
      'サポート応答が短すぎます（41 00 とさらに4バイトが必要です）。';

  @override
  String get handshakeNoteTimedOut => 'タイムアウトしました。';

  @override
  String get handshakeStepAdapterVersion => 'アダプターのバージョンを読み取る';

  @override
  String get handshakeStepAdaptiveTiming => 'データシート推奨のアダプティブタイミングを有効化する';

  @override
  String get handshakeStepBatteryVoltage => 'バッテリー電圧を読み取る';

  @override
  String get handshakeStepDeviceIdentity => 'デバイス識別文字列を読み取る';

  @override
  String get handshakeStepEchoOff => 'コマンドエコーをオフにする';

  @override
  String get handshakeStepLinefeedsOff => '改行文字をオフにする';

  @override
  String get handshakeStepMemoryOff => 'メモリ書き込みをオフにする';

  @override
  String get handshakeStepNoReason => '応答なし';

  @override
  String get handshakeStepProtocolAuto => 'バスプロトコルを自動検出する';

  @override
  String get handshakeStepProtocolDescription => 'プロトコル説明を読み取る';

  @override
  String get handshakeStepProtocolNumber => 'プロトコル番号を読み取る';

  @override
  String get handshakeStepReset => 'アダプターをソフトウェアリセットする';

  @override
  String get handshakeStepResponseTimeout => '応答タイムアウトを約 408 ms に設定する';

  @override
  String get handshakeStepSpacesOff => '空白文字をオフにして通信量を3分の1削減する';

  @override
  String get handshakeStepSupportProbe => 'ECUが対応するPIDを照会し、車両の応答を確認する';

  @override
  String get languageSaveFailed => '言語設定を保存できませんでした。もう一度お試しください。';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get navDashboard => 'ダッシュボード';

  @override
  String get navDtc => '故障コード';

  @override
  String get navPerformance => '計測';

  @override
  String get navPid => 'PID';

  @override
  String get navSettings => '設定';

  @override
  String get performanceArm => 'タイマーをセット';

  @override
  String get performanceDisclaimer =>
      'タイムはOBDの車速信号に基づいています。多くの車両のスピードメーター自体に 1–3 km/h 高めの誤差があり、信号の更新頻度も毎秒約 10–20 回であるため、ここでの結果はあくまで目安であり、専門の計測機器と同等ではありません。';

  @override
  String get performanceHeadline => '加速テスト';

  @override
  String get performanceNoSpeedSignal =>
      '現在有効な車速信号（PID 010D）がありません。加速テストは車速信号なしでは計測できません。';

  @override
  String get performanceNotConnectedBody =>
      '加速テストにはリアルタイムの車速が必要です。アダプターを接続するか、内蔵シミュレーターを起動してください。';

  @override
  String get performanceNotConnectedTitle => '未接続';

  @override
  String get performancePeakSpeed => '最高車速';

  @override
  String get performanceReset => 'リセット';

  @override
  String get performanceSecondsUnit => '秒';

  @override
  String get performanceSpeedGaugeLabel => '車速';

  @override
  String get performanceSpeedTraceHeading => '車速トレース';

  @override
  String get performanceSplitsHeading => 'スプリット';

  @override
  String get performanceStateAborted => 'この計測は完了しませんでした。以下は停止前に記録された内容です';

  @override
  String get performanceStateAwaitingSpeedSignal => '車速信号を待機中';

  @override
  String performanceStateAwaitingStandstill(String speed) {
    return '先に完全停止してください — 現在 $speed km/h';
  }

  @override
  String performanceStateFinished(int target) {
    return '0 → $target km/h 完了';
  }

  @override
  String get performanceStateIdle => '目標車速を選択して開始してください';

  @override
  String get performanceStateRunning => '計測中';

  @override
  String get performanceStateStaged => '準備完了 — 発進すると計測が始まります';

  @override
  String get performanceSubhead => '完全停止状態から目標車速までの到達時間を計測します';

  @override
  String get performanceTargetSpeedHeading => '目標車速';

  @override
  String get pidActionCancel => 'キャンセル';

  @override
  String get pidActionDelete => '削除';

  @override
  String get pidArrangeBody =>
      'ドラッグして並び替えます。ダッシュボードは左から右、上から下の順に並ぶため、先頭の項目が最初に表示されます。';

  @override
  String get pidArrangeEmptyMessage => '先に一覧でいくつか有効にしてから、ここで並び替えてください。';

  @override
  String get pidArrangeEmptyTitle => '有効なPIDがまだありません';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return '確認済みの $count 件を追加';
  }

  @override
  String get pidBulkActionAllActive => 'すべて有効化済み';

  @override
  String get pidBulkActionIncomplete => 'スキャンデータが不完全です';

  @override
  String get pidBulkActionLocked => '記録中は変更できません';

  @override
  String get pidBulkActionPending => 'スキャン結果を待機中';

  @override
  String get pidBulkActionZero => '確認済みの対応PIDなし';

  @override
  String pidBulkAddCount(int count) {
    return '$count 件を追加';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return '確認済みの対応PID $count 件を追加しますか？';
  }

  @override
  String pidBulkAdded(int count) {
    return '確認済みの対応PID $count 件を追加しました。';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '$count 個のサポートブロックが未確認のままです。今回は対応を示す証拠がある項目のみを追加します。';
  }

  @override
  String pidBulkWillAdd(int count) {
    return '$count 件を追加します。有効なPIDが増えるほど、各PIDの更新頻度は下がる可能性があります。';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '$confirmed 件確認済み';
  }

  @override
  String get pidCapabilityCoverageNone => '連続した確認範囲はまだ確立されていません';

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return '連続確認範囲 01–$through（終端まで到達）';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return '連続確認範囲 01–$through（これ以降は不明）';
  }

  @override
  String get pidCapabilityPhaseAttemptFinished => '今回のサポートスキャンが完了しました';

  @override
  String get pidCapabilityPhaseInterrupted => 'サポートスキャンが中断されました';

  @override
  String get pidCapabilityPhaseNotStarted => 'スキャン未開始';

  @override
  String get pidCapabilityPhaseRunning => 'この車両の対応項目を確認中';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return '車両対応PID。$phase。$confirmed 件確認済み。不明ブロック $unknown 個。';
  }

  @override
  String get pidCapabilityTitle => '車両対応PID';

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '不明ブロック $unknown 個';
  }

  @override
  String pidEditorCollision(String name) {
    return 'この組み合わせはすでに別のカスタムPID（$name）で使用されています。別のモード+PID、ヘッダー、または名前の接尾辞を使用してください。';
  }

  @override
  String pidEditorDeleteBody(String name) {
    return '「$name」の定義が削除され、ダッシュボードからそのメーターも消えます。この操作は元に戻せません。';
  }

  @override
  String get pidEditorDeleteTitle => 'このPIDを削除しますか？';

  @override
  String get pidEditorDiscard => '破棄';

  @override
  String get pidEditorDiscardBody => 'このPIDへの変更はまだ保存されていません。画面を離れると変更内容は失われます。';

  @override
  String get pidEditorDiscardTitle => '未保存の変更を破棄しますか？';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N は応答バイトに対応します。SIGNED()、ABS()、LOG10()、$valSyntax、BARO が使用可能です';
  }

  @override
  String get pidEditorFieldEquation => '計算式';

  @override
  String get pidEditorFieldHeader => 'CANヘッダー';

  @override
  String get pidEditorFieldMax => '最大値';

  @override
  String get pidEditorFieldMin => '最小値';

  @override
  String get pidEditorFieldModeAndPid => 'モード + PID';

  @override
  String get pidEditorFieldName => '名前';

  @override
  String get pidEditorFieldSample => 'テスト用応答バイト';

  @override
  String get pidEditorFieldShortName => '短縮名（メーター上に表示）';

  @override
  String get pidEditorFieldUnits => '単位';

  @override
  String get pidEditorHeaderHelper => '7E0 = エンジン';

  @override
  String get pidEditorKeepEditing => '編集を続ける';

  @override
  String get pidEditorModeAndPidHelper => '例：010C または 221101';

  @override
  String get pidEditorSampleHelper => '16進数を入力すると計算結果をリアルタイムにプレビューできます';

  @override
  String get pidEditorSave => '保存';

  @override
  String get pidEditorSectionFormula => '計算式';

  @override
  String get pidEditorSectionIdentity => '識別情報';

  @override
  String get pidEditorSectionQuery => 'クエリ';

  @override
  String get pidEditorSectionRangeAndPriority => 'メーター範囲と優先度';

  @override
  String get pidEditorTitleEdit => 'PIDを編集';

  @override
  String get pidEditorTitleNew => '新規カスタムPID';

  @override
  String pidExportFailed(String error) {
    return 'エクスポートに失敗しました：$error';
  }

  @override
  String get pidExportNoCustomPids => 'エクスポートできるカスタムPIDがありません。';

  @override
  String get pidImportNothingToImport => 'インポートできる定義がありません。';

  @override
  String pidImportLandedClean(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のカスタムPIDをインポートしました。',
      one: '1件のカスタムPIDをインポートしました。',
    );
    return '$_temp0';
  }

  @override
  String pidImportLandedWithNotes(int count, String notes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件をインポートしました（$notes）。',
      one: '1件をインポートしました（$notes）。',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteSkippedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count行に問題がありスキップされました',
      one: '1行に問題がありスキップされました',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDefaultedRanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count行にデフォルトのメーター範囲が適用されました',
      one: '1行にデフォルトのメーター範囲が適用されました',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '既存の定義$count件を上書きしました',
      one: '既存の定義1件を上書きしました',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDuplicatesInFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count行がファイル内の別の行と重複していたためスキップされました',
      one: '1行がファイル内の別の行と重複していたためスキップされました',
    );
    return '$_temp0';
  }

  @override
  String get pidImportPickerFailed => 'ファイル選択画面を開けませんでした。';

  @override
  String get pidImportReadFailed => 'ファイルを読み取れませんでした。';

  @override
  String get pidListSeparator => '、';

  @override
  String get pidManagerActiveOnly => '有効のみ';

  @override
  String get pidManagerAdd => '新規';

  @override
  String get pidManagerArrangeDashboard => 'ダッシュボード配置';

  @override
  String pidManagerCounts(int active, int total) {
    return '$active 件有効 · 全 $total 件';
  }

  @override
  String get pidManagerExportCsv => 'カスタムPIDをエクスポート';

  @override
  String get pidManagerExportTorqueCsv => 'Torque 互換CSVをエクスポート';

  @override
  String get pidManagerExportHumanReport => '人間向けPIDレポートをエクスポート';

  @override
  String get pidManagerHeadline => 'PID管理';

  @override
  String get pidManagerImportCsv => 'CSVをインポート';

  @override
  String get pidManagerMoreActions => 'その他';

  @override
  String get pidManagerNoMatchMessage => '別のキーワードを試すか、カスタムPIDを作成してください。';

  @override
  String get pidManagerNoMatchTitle => '一致するPIDがありません';

  @override
  String get pidManagerPowertrainBatteryCatalog => '駆動用バッテリーカタログ';

  @override
  String get pidManagerSearchHint => '名前またはPIDコードで検索…';

  @override
  String get pidPickCsvDialogTitle => 'PID定義CSVを選択';

  @override
  String get pidPillCustom => 'カスタム';

  @override
  String get pidPillUnsupported => '非対応';

  @override
  String get pidPreviewCannotEvaluate => '計算不可';

  @override
  String get pidPreviewResultLabel => '計算結果';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'プレビューでは $dependencies に仮の値 $valueString を代入しています。実際の値は接続後にそのPIDから取得されます。';
  }

  @override
  String get pidPreviewTitle => 'ライブプレビュー';

  @override
  String get pidPriorityHigh => '高';

  @override
  String get pidPriorityLow => '低';

  @override
  String get pidPriorityMedium => '中';

  @override
  String get pidPriorityVeryLow => '最低';

  @override
  String get pidRowEdit => '編集';

  @override
  String pidRowShowOnDashboard(String name) {
    return '$name をダッシュボードに表示';
  }

  @override
  String pidRowStaleUnits(String units) {
    return '$units · 更新停止';
  }

  @override
  String powertrainAuthorizationGranted(String profile) {
    return '$profile のバッテリー信号が今回の接続で有効になりました';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return '有効化できませんでした：$reason';
  }

  @override
  String get powertrainCancel => 'キャンセル';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return 'プロファイル：$profiles · 単発読み取り：$probeable';
  }

  @override
  String get powertrainCatalogLoadFailedBody =>
      '整合性検証を通過しなかったため、車両データの表示およびインストールは行われませんでした。';

  @override
  String get powertrainCatalogLoadFailedTitle => 'オフラインカタログを読み込めませんでした';

  @override
  String get powertrainCatalogNotVerified => 'カタログが検証を通過していないため、何もインストールできません。';

  @override
  String get powertrainCatalogRevalidate => '再検証';

  @override
  String get powertrainCatalogScopeNote =>
      'カタログの対象は広範ですが、「データが見つかった」ことは「お使いの車両に対応している」という意味ではありません。調査専用の項目にはコマンドが含まれません。Mode 22 の実験項目はインストールしてポーリングできますが、すべての値に「未検証」と表示されます。Mode 21 の実験項目は確認ごとに1回だけ読み取られます。';

  @override
  String get powertrainCatalogSearchHint => 'メーカー、車種、グレード、市場を検索…';

  @override
  String get powertrainCatalogTitle => '駆動用バッテリーカタログ';

  @override
  String get powertrainChooseCommandNote =>
      '1回の試行につき1コマンドのみ送信します（スキャンなし、一括要求なし、自動再試行なし）。';

  @override
  String get powertrainChooseCommandTitle => '固定の読み取り専用クエリを1つ選択';

  @override
  String get powertrainClose => '閉じる';

  @override
  String get powertrainConfirmAccept => 'この車両で間違いありません';

  @override
  String get powertrainConfirmBody =>
      'インストール済みのプロファイル信号は、この車両がその車種であると確認した後にのみ読み取られ、その確認は今回の接続に限り有効です。';

  @override
  String get powertrainConfirmButton => '車両を確認';

  @override
  String get powertrainConfirmDialogBody =>
      '確認すると、今回の接続が終わるまでこのプロファイルの読み取り専用バッテリークエリが定期的にポーリングされます。誤ったプロファイルでは、もっともらしい見た目でありながら誤った数値が表示されるおそれがあります。確信が持てない場合はキャンセルしてください。';

  @override
  String get powertrainConfirmDialogTitle => '接続中の車両を確認';

  @override
  String get powertrainConfirmTitle => '車両バッテリー信号は確認待ちです';

  @override
  String get powertrainConnectFirst =>
      '先に接続してください。実験機能の承認が接続をまたいで保持されることはありません。';

  @override
  String get powertrainConnectionChanged =>
      '接続が変わりました。新しい接続に対してもう一度車両を確認してください。';

  @override
  String get powertrainEnableLabInSettings => '先に「設定」で実験用バッテリーラボをオンにしてください。';

  @override
  String get powertrainEvidencePhysicalVehicle => 'プロジェクト実車';

  @override
  String get powertrainEvidenceSourceBacked => '出典データ';

  @override
  String get powertrainEvidenceSyntheticRig => '合成テストリグ';

  @override
  String get powertrainExperimentalDataDisclosure =>
      'これは出典の著者が記載した候補の読み取りであり、メーカー保証や車種間の安全保証ではありません（ELM327 はコマンドを転送するだけです）。生のコマンドと応答はローカルの診断通信記録に残り、この機能によって自動的にアップロードされることはありません。また、デコードされた値がPIDとしてインストールされたりメーターに追加されたりすることもありません。キャンセルしても通常のOBD機能には影響しません。';

  @override
  String get powertrainExperimentalDialogTitle => '単発の実験的読み取り専用クエリの確認';

  @override
  String get powertrainExperimentalIdentityAck =>
      '出典に記載された市場、車種、年式を確認し、未確認の項目があることを承知しました';

  @override
  String get powertrainExperimentalParkedAck =>
      '車両は安全な場所に駐車しています。これは1回限りの読み取りであり、数値がこの車両に当てはまらない可能性があることを理解しています';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return 'RX $responder のみを受け入れ、ペイロード長は $bytes bytes';
  }

  @override
  String get powertrainFieldListSeparator => '、';

  @override
  String get powertrainFieldMarket => '市場';

  @override
  String get powertrainFieldModel => '車種';

  @override
  String get powertrainFieldModelYear => '年式';

  @override
  String get powertrainFieldVariant => 'グレード／仕様';

  @override
  String get powertrainFilterAll => 'すべて';

  @override
  String get powertrainIdentityEvidenceExact => '直接証拠あり';

  @override
  String get powertrainIdentityEvidenceNone => 'なし';

  @override
  String get powertrainIdentityEvidenceSourcePartial => '部分的な証拠';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return '出典の車両識別証拠：$fields\n未確認の項目：$unconfirmed';
  }

  @override
  String get powertrainIdentityEvidenceUnknown => '不明';

  @override
  String get powertrainInstallButton => 'バッテリー信号をインストール';

  @override
  String get powertrainInstallConfirm => 'インストール';

  @override
  String get powertrainInstallDialogTitle => 'この車種のバッテリー信号をインストール';

  @override
  String get powertrainInstallDisclosureCommunity =>
      'インストールしても、読み取り専用のバッテリーPIDがPID管理に追加されるだけです。読み取りが始まる前に、接続するたびにダッシュボードで「この車両がその車種である」ことの確認を求められます。データはコミュニティの出典に基づき独立した裏付けがありますが、メーカーの保証ではありません。';

  @override
  String get powertrainInstallDisclosureExperimental =>
      'インストールしても、読み取り専用のバッテリーPIDがPID管理に追加されるだけです。読み取りが始まる前に、接続するたびにダッシュボードで「この車両がその車種である」ことの確認を求められます。これは独立した裏付け要件のない実験的なデコードであり、この車両では未検証で、メーカーの保証でもありません。';

  @override
  String get powertrainInstallDisclosureReady =>
      'インストールしても、読み取り専用のバッテリーPIDがPID管理に追加されるだけです。読み取りが始まる前に、接続するたびにダッシュボードで「この車両がその車種である」ことの確認を求められます。出典データはより充実していますが、それでもメーカーの保証ではありません。';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      'インストールしても、読み取り専用のバッテリーPIDがPID管理に追加されるだけです。読み取りが始まる前に、接続するたびにダッシュボードで「この車両がその車種である」ことの確認を求められます。この項目は調査専用であり、インストールすべきではありません。';

  @override
  String get powertrainInstallCatalogShaMissing =>
      'インストール不可：このカタログスナップショットには検証済みの SHA-256 がないため、内容を信頼できません。';

  @override
  String get powertrainInstallPersistFailed =>
      'インストール不可：インストール済みプロファイル一覧を保存できませんでした。もう一度お試しください（PID管理には何も追加されていません）。';

  @override
  String get powertrainInstallProfileNotInCatalog =>
      'インストール不可：そのプロファイルは検証済みカタログに存在しません。';

  @override
  String get powertrainInstallProfileNotInstallable =>
      'インストール不可：このプロファイルは実際のPIDとして使用できる状態ではありません。';

  @override
  String get powertrainInstallYearOutOfRange =>
      'インストール不可：その年式はこのプロファイルに記載された年式範囲外です。';

  @override
  String get powertrainInstallIdentityAck => '私の車両は上記の市場、車種、年式と一致しています';

  @override
  String get powertrainInstalledRemoveButton => 'インストール済み · 信号を削除';

  @override
  String powertrainInstalledSignalsSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の信号をインストールしました。PID画面からダッシュボードに追加してください（接続ごとに車両確認が必要です）。',
      one: '1件の信号をインストールしました。PID画面からダッシュボードに追加してください（接続ごとに車両確認が必要です）。',
    );
    return '$_temp0';
  }

  @override
  String get powertrainNoMatchBody => 'メーカー名や車種名を試すか、別のパワートレイン種別に切り替えてください。';

  @override
  String get powertrainNoMatchTitle => '一致する車両がありません';

  @override
  String get powertrainNotInstallableInThisRelease => 'このリリースではインストール不可';

  @override
  String powertrainPrimarySource(String name, String license) {
    return '主な出典：$name（$license）';
  }

  @override
  String get powertrainProbeChecksPassed =>
      '応答元（responder）、エコー（echo）、正確な長さ（exact length）、計算式、および範囲のチェックを通過しました。';

  @override
  String get powertrainProbeConnectForOneShot => '接続して単発の読み取り専用クエリを実行';

  @override
  String get powertrainProbeConnectToTryOnce => '接続してまず1回だけ読み取りを試す';

  @override
  String get powertrainProbeDidNotFinish => '単発クエリが完了しませんでした。値の公開や保持は行われていません。';

  @override
  String get powertrainProbeEnableLabFirst => '先に設定でバッテリーラボを有効にしてください';

  @override
  String get powertrainProbeInProgress => '単発読み取り中…';

  @override
  String get powertrainProbeNoValuePublished =>
      '値は公開されませんでした。構造エラーまたはデコードエラーは再接続するまで隔離されます。';

  @override
  String get powertrainProbeOnceButton => '1回だけ読み取る';

  @override
  String get powertrainProbePassedTitle => '単発クエリ通過';

  @override
  String get powertrainProbePickOneRead => 'コマンドを1つ選んで1回だけ読み取る';

  @override
  String get powertrainProbeReconnectFirst => '再接続してからもう一度試してください';

  @override
  String get powertrainProbeRefusedTitle => '単発クエリ拒否';

  @override
  String get powertrainProbeTryOnceFirst => 'まず1回だけ試す';

  @override
  String get powertrainProfileNotVerified => 'このプロファイルは検証済みカタログに含まれていません';

  @override
  String get powertrainQuarantinedPill => '隔離中 · 要再接続';

  @override
  String get powertrainRefusedCatalogHashInvalid =>
      '未承認：カタログの整合性ハッシュが無効であるため、内容を一切読み取れません。';

  @override
  String get powertrainRefusedCommandNotInProfile =>
      '未承認：そのコマンドはこの検証済みプロファイルに属するコマンドではありません。';

  @override
  String get powertrainRefusedLabClosed => 'この読み取りが承認される前に実験用バッテリーラボがオフにされました。';

  @override
  String get powertrainRefusedProfileFailedValidation =>
      '未承認：このプロファイルは選択された年式でのカタログ検証を通過しませんでした。';

  @override
  String get powertrainRefusedProfileNotInCatalog =>
      '未承認：このプロファイルは検証済みカタログに含まれていません。';

  @override
  String get powertrainRefusedProfileNotProbeable =>
      '未承認：このプロファイルは実験的に単発読み取りできる対象ではありません。';

  @override
  String get powertrainRefusedQuarantinedAfterRejectedRead =>
      '今回の接続では隔離されています：前回の単発読み取りが構造チェックを通過しませんでした。再試行する前に再接続してください。';

  @override
  String get powertrainRefusedNotConnectedOrNotInForeground =>
      '単発読み取りは開始されませんでした：未接続であるか、アプリがフォアグラウンドにありませんでした。';

  @override
  String get powertrainRefusedNoLiveAuthorization =>
      '単発読み取りは開始されませんでした：有効な1回限りの承認がありません（承認されていない、期限切れ、クールダウン中、または隔離済みです）。';

  @override
  String get powertrainRefusedDiscardedAtLifecycleBoundary =>
      '単発読み取りの実行中に接続またはフォアグラウンド状態が変化したため、応答は表示されずに破棄されました。失敗ではなく、何も保持されていません。';

  @override
  String powertrainRefusedQuarantinedAtAttemptCap(int attemptCap) {
    return '今回の接続では隔離されています：同じコマンドがすでに $attemptCap 回試行されました。再試行する前に再接続してください。';
  }

  @override
  String get powertrainResearchOnlyNeverQueries => '調査専用 — クエリは送信しません';

  @override
  String get powertrainRestoreStorageErrorRetry =>
      '以前のインストール状態の復元中にストレージエラーが発生しました。再スケジュールされたため、もう一度お試しください。';

  @override
  String powertrainSecondarySource(String name, String license) {
    return '独立した裏付け：$name（$license）';
  }

  @override
  String powertrainSignalCount(int count) {
    return '信号数：$count';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return '出典ファイル SHA-256：$hash…';
  }

  @override
  String get powertrainStatusCommunity => 'コミュニティ · 未検証';

  @override
  String get powertrainStatusExperimental => '実験的 · 未検証';

  @override
  String get powertrainStatusExperimentalProbeOnly => '実験的 · 単発読み取りのみ';

  @override
  String get powertrainStatusReady => 'より充実した出典データ';

  @override
  String get powertrainStatusResearchOnly => '調査専用';

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return '$name のインストール済み信号を削除しました。';
  }

  @override
  String powertrainVehicleYearFixed(int year) {
    return '年式：$year';
  }

  @override
  String get powertrainVehicleYearLabel => '年式';

  @override
  String get recommendedPurchaseDisclosure =>
      'これはメンテナーのアフィリエイトリンクであり、条件を満たす購入によりメンテナーに紹介料（コミッション）が支払われる場合があります。アダプターの認証や購入保証ではありません。販売ページの内容やハードウェアのリビジョンは変更される可能性があるため、購入前に完全な型番とNCC番号を確認してください。他の販売店をご自身で探していただいても構いません。';

  @override
  String get recommendedPurchaseHeading => '推奨アダプター';

  @override
  String recommendedPurchaseModelLine(String model, String approval) {
    return '型番 $model · NCC $approval';
  }

  @override
  String recommendedPurchaseNoAdapterYet(String store) {
    return 'アダプターをまだお持ちでない場合：$storeで推奨モデルを見る';
  }

  @override
  String recommendedPurchaseOpenFailed(String store) {
    return '$storeのリンクを開けませんでした';
  }

  @override
  String get recommendedPurchaseShortDisclosureAction => '設定で開示情報の全文を見る';

  @override
  String get recommendedPurchaseShortDisclosureLead =>
      'これはアフィリエイトリンクであり、アダプターの認証ではありません。';

  @override
  String get recommendedPurchaseStoreShopee => 'Shopee';

  @override
  String recommendedPurchaseViewOnStore(String store) {
    return '$storeで見る';
  }

  @override
  String get semanticsFieldSeparator => '、';

  @override
  String get settingsAdapterConcernsFooter =>
      'これらはアダプターの自己記述に矛盾がある箇所であり、車両の読み取り値を誤って取得したという証拠ではありません。値を確認する唯一の方法は、2つ目の独立した計測と照らし合わせることです（フィールドガイド参照）。';

  @override
  String get settingsAdapterNoContradictions =>
      '自己記述の矛盾は見つかりませんでした。これは自己記述が一貫していることだけを意味し、チップが純正であることの証拠でも、報告される数値が正しいことの証拠でもありません。クローン品のバージョン文字列は、誰かが選んだ単なるテキストです。';

  @override
  String get settingsAdapterNoVersion => '（バージョン未報告）';

  @override
  String get settingsAdapterSelfReportTitle => 'アダプターの自己報告内容';

  @override
  String get settingsBatteryLabDialogBody =>
      'これらはリバースエンジニアリング由来の候補データであり、メーカーの公式文書ではなく、Telltale がお使いの車両に対応していることを示すものでもありません。読み取り専用クエリであってもコントローラーを起動させる可能性があり、デコードされた数値がもっともらしい値に見えても実際には適用できない場合があります。';

  @override
  String get settingsBatteryLabDialogTitle => 'バッテリーラボを有効にする';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      '今回の実行ではバッテリーラボをオフにしましたが、設定を保存できませんでした。次回起動時に再びラボが表示される可能性があり、各クエリには引き続き個別の確認が必要です。';

  @override
  String get settingsBatteryLabEnableNotSaved =>
      'バッテリーラボの設定を保存できませんでした。機能はオフのままです。';

  @override
  String get settingsBatteryLabEvidenceAck =>
      '出典データおよび合成テストは、自分の車両に適用できることの証明にはならないと理解しています';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      '出典が完全でハッシュ拘束された単発の読み取り専用クエリを表示するだけです。PIDのインストール、ポーリング、メーターの追加、および調査データを対応済みとして扱うことは一切行いません。';

  @override
  String get settingsBatteryLabSwitchTitle => 'バッテリーラボ（実験的）';

  @override
  String get settingsBatteryLabUnlockReadOnly => '単発の読み取り専用クエリのみを解放する';

  @override
  String get settingsBatteryLabWireAck =>
      'これにより解放されるのはカタログ内の固定された Mode 21/22 アドレスへの単発クエリのみであり、スキャン、診断セッション、セキュリティアクセス、書き込み、制御は一切行われないことを理解しています';

  @override
  String get settingsCancel => 'キャンセル';

  @override
  String get settingsCatalogChoose => '公式カタログから選択';

  @override
  String get settingsCatalogCorrupt =>
      '公式オフラインカタログが破損しているか読み込めませんでした。何も適用されていません。';

  @override
  String get settingsCatalogNothingApplicable =>
      'この公式構成には現在の計算式に安全に適用できる項目がありません。既存のプロファイルは変更されません。';

  @override
  String get settingsCatalogScope =>
      '公式カタログ：米国 EPA、台湾 MOEA、カナダ NRCan。各スナップショットはその市場のみを対象としており、世界中のすべてのブランドや年式を網羅するものではありません。';

  @override
  String get settingsCatalogVerifying => 'オフラインカタログを検証中…';

  @override
  String get settingsCatalogChooseMarket => '閲覧する公式カタログを選択';

  @override
  String get settingsCatalogMarketTw => '台湾（経済部能源署 MOEA）';

  @override
  String get settingsCatalogMarketUs => '米国（EPA）';

  @override
  String get settingsTwCertificationYear => '認証年';

  @override
  String get settingsTwMake => '台湾メーカー表記';

  @override
  String settingsTwPickerScope(int firstYear, int lastYear) {
    return '台湾市場の $firstYear–$lastYear 年の認証データのみを含みます。この年は経済部能源署の認証暦年であり、米国のモデルイヤー（model year）ではありません。メーカー名と車名の文字列が一致しても、それは EPA の構成ではありません。';
  }

  @override
  String get settingsTwPickerTitle => '台湾公式車両カタログ';

  @override
  String get settingsTwReferenceMassNotCurb =>
      '参考車両重量は curb mass（空車重量）とは異なり、適用されません。';

  @override
  String settingsTwWillApplyOnly(String fields) {
    return '適用されるのは $fields のみです。参考車両重量、VE、Cd、前面投影面積、Crr、および伝達効率は未解決のまま残ります。';
  }

  @override
  String get settingsClose => '閉じる';

  @override
  String get settingsConnectionSection => '接続';

  @override
  String get settingsDiagnosticsSection => '診断通信記録';

  @override
  String get settingsDisconnect => '切断';

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return '伝達効率 $percent %';
  }

  @override
  String settingsEpaApplyFields(int count) {
    return '公式項目 $count 件を適用';
  }

  @override
  String get settingsEpaChooseExact => '正確な構成を選択';

  @override
  String get settingsEpaCloseNoFields => '閉じる（適用できる項目なし）';

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'EPA 構成 $epaId';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count 気筒';
  }

  @override
  String get settingsEpaDriveUnknown => '駆動方式不明';

  @override
  String get settingsEpaFuelUnknown => '燃料不明';

  @override
  String get settingsEpaMake => 'メーカー（EPA make）';

  @override
  String get settingsEpaModel => '車種';

  @override
  String get settingsEpaNoConfigurations => 'この車種で利用可能な構成がありません';

  @override
  String get settingsEpaNoSafeFields =>
      'この構成には現在の計算式に安全に適用できる項目がありません。推測は行われません。';

  @override
  String get settingsEpaPickInOrder => '年式、メーカー、車種の順に選択してください';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return '米国市場の $firstYear–$lastYear 年のスナップショット構成のみが対象です。同名の車種であっても、年式、トランスミッション、燃料、および EPA ID で区別する必要があります。';
  }

  @override
  String get settingsEpaPickerTitle => '米国 EPA 公式車両カタログ';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return '適用されるのは $fields のみです。車両重量、VE、Cd、前面投影面積、Crr、および伝達効率は未解決のまま残ります。';
  }

  @override
  String get settingsEpaYear => '年式';

  @override
  String get settingsExperimentalSection => '実験機能';

  @override
  String get settingsFieldDisplacement => '排気量';

  @override
  String get settingsFieldDragCoefficient => '空気抵抗係数 Cd';

  @override
  String get settingsFieldDrivetrain => '駆動方式';

  @override
  String get settingsFieldFrontalArea => '前面投影面積';

  @override
  String get settingsFieldFuel => '燃料';

  @override
  String get settingsFieldMass => '車両重量';

  @override
  String get settingsFieldMassWithDriver => '車両重量（運転者含む）';

  @override
  String get settingsFieldRollingResistance => '転がり抵抗係数 Crr';

  @override
  String get settingsFieldVolumetricEfficiency => '体積効率 VE';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return '空燃比 $afr · 密度 $density g/L';
  }

  @override
  String get settingsFuelAndDrivetrainSection => '燃料と駆動方式';

  @override
  String get settingsFuelTypeLabel => '燃料種別';

  @override
  String get settingsGaugeSkinBody =>
      '単なる色違いではなく、それぞれ文字盤の形状、針、動きが異なります。すべてダーク・ライト両方の背景で使用できます。';

  @override
  String get settingsGaugeSkinTitle => 'メータースタイル';

  @override
  String get settingsGoToConnect => '接続画面へ移動';

  @override
  String get settingsHeadline => '設定';

  @override
  String get settingsLicenseLegalese =>
      '駆動用バッテリーデータの出典、変換方式、および再利用条件は本アプリに同梱されています。';

  @override
  String get settingsListSeparator => '、';

  @override
  String get settingsManualCommandBody =>
      'アダプターにコマンドを1つ直接送信します（例：ATI、ATDPN、0100）。通常のポーリングと同じキューに並び、割り込みはしません。';

  @override
  String get settingsManualCommandFieldLabel => 'コマンド';

  @override
  String get settingsManualCommandNoContent => '（応答内容なし）';

  @override
  String get settingsManualCommandSend => '送信';

  @override
  String get settingsManualCommandTitle => '手動コマンド';

  @override
  String get settingsNotConnected => '未接続';

  @override
  String get settingsOpenSourceLicenses => 'オープンソースとデータのライセンス';

  @override
  String get settingsProfileConfirmAfterConnect => '接続してこの車両を確認';

  @override
  String get settingsProfileConfirmButton => '今回の接続でこの車両プロファイルを確認';

  @override
  String get settingsProfileConfirmedButton => '今回の接続で確認済み';

  @override
  String get settingsProfileConfirmedDetail =>
      'このプロファイルは今回の接続で確認済みです。いずれかの値を変更した場合や再接続した場合は、再度確認が必要です。';

  @override
  String get settingsProfileEstimatesIntro =>
      '馬力、トルク、燃料消費量はこれらのパラメータから推定されます。実際の車両に近い値を入力するほど、より意味のある推定値になります。';

  @override
  String get settingsProfileNameProvesNothing =>
      'ブランド名や VIN だけでは、車両重量、空気抵抗、VE、伝達効率を証明することはできません。';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      '今回の接続では未確認です。OBDの実測値は引き続き表示されますが、車両重量、VE、空気抵抗から推定される値は表示されません。';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      '確認する前にこの車両に接続してください。確認状態は再接続のたびに失効するため、前の車両のプロファイルが次の車両に適用されることはありません。';

  @override
  String get settingsProvenanceNoneExact =>
      'この車両に対して正確に解決された項目はまだありません。汎用デフォルト値、手動入力値、および古い出典の値はすべて確認が必要です。';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return '正確な公式出典がある項目：$fields。その他の項目はすべて個別に確認が必要です。';
  }

  @override
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  ) {
    return '出典：公式／メーカー $official / $total 項目 · 手動入力 $user / $total · 汎用デフォルト $generic / $total · 科学モデル $scientific / $total';
  }

  @override
  String settingsProvenancePublishers(String publishers) {
    return '出典元：$publishers';
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
    return '解決状態：公式一致 $exact / $total 項目 · 今回確認済み $sessionConfirmed / $total · 未解決 $unresolved / $total · 曖昧 $ambiguous / $total · 競合 $conflict / $total';
  }

  @override
  String get settingsStandardsFooter =>
      '本アプリの OBD2 実装は SAE J1979 および ELM327 データシートなどの公開規格に基づいています。ハードウェアの挙動に影響するすべての計算式とATコマンドはクロス検証されており、その結果は docs/protocol-deviations.zh-TW.md に記録されています。本アプリは Torque または Torque Pro とは無関係です。';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeSystem => 'システム設定に従う';

  @override
  String get settingsVehicleProfileSection => '車両プロファイル';

  @override
  String get settingsVinConflict => 'VIN の競合';

  @override
  String get settingsVinConflictDetail =>
      '複数のコントローラーが異なる VIN を報告したため、車両の識別情報を確認できません。すべての候補が破棄されました。';

  @override
  String get settingsVinNotRead => 'VIN 未読み取り';

  @override
  String get settingsVinNotReadConnectedDetail =>
      '現在接続中の車両から Mode 09 VIN を読み取ることができます。識別状態は今回の接続でのみ保持されます。生の診断通信記録には VIN が含まれる場合があります。';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      '接続すると、車両が自己報告する VIN を読み取ることができます。識別状態は次の接続には引き継がれません。生の診断通信記録には VIN が含まれる場合があります。';

  @override
  String get settingsVinRead => 'VIN を読み取る';

  @override
  String get settingsVinReading => '読み取り中…';

  @override
  String get settingsVinReportedDetail =>
      'VIN は車両が自己報告する識別番号であり、車種のスペックが検証されたことを意味しません。識別状態は接続をまたいで保持されませんが、診断通信記録には VIN が含まれる場合があります。';

  @override
  String get settingsVinSimulatorReported => 'シミュレーター報告 VIN';

  @override
  String get settingsVinUnavailable => 'VIN 取得不可';

  @override
  String get settingsVinUnavailableDetail =>
      '車両が提供していないか、応答が不完全だったか、今回の接続で読み取れなかった可能性があります。推測や文字の補完は一切行いません。';

  @override
  String get settingsVinVehicleReported => '車両報告 VIN';

  @override
  String get startupCannotComplete => '起動チェックを完了できません';

  @override
  String get startupChecking => 'ローカルの共有キャッシュとテレメトリー記録を確認しています';

  @override
  String get startupRestartHint =>
      'ローカルの共有キャッシュまたはテレメトリー記録の状態を確認できませんでした。誤ったファイルの上書き、削除、共有を防ぐため、Telltale を完全に終了して再度開いてください。';

  @override
  String get startupRestartRequired => '安全に続行するには再起動が必要です';

  @override
  String get startupRetry => '再試行';

  @override
  String get startupRetryHint =>
      'Telltale をフォアグラウンドに保ち、他のファイル処理が終わってから再試行してください。起動が完了するまで、記録、再生、エクスポート、削除は利用できません。';

  @override
  String get telemetryArtifactRestartRequired =>
      'ローカルファイル処理の状態を確認できません。続行する前に Telltale を完全に終了して再度開いてください';

  @override
  String get telemetryBlockedByRecorder => '先に記録を停止して保存してください';

  @override
  String get telemetryCancel => 'キャンセル';

  @override
  String get telemetryDamagedCollision =>
      '完了済みファイルと未完了ファイルで同じIDが重複しています。どちらも選択されませんでした';

  @override
  String get telemetryDamagedCorrupt => '記録が破損しており、安全に読み取れません';

  @override
  String telemetryDamagedFileTime(String time) {
    return 'ファイル時刻 $time';
  }

  @override
  String get telemetryDelete => '削除';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return '$id（ファイル時刻 $time）を削除します。この操作は元に戻せません。';
  }

  @override
  String get telemetryDeleteDamagedTitle => 'この破損した記録を削除しますか？';

  @override
  String get telemetryDeleteDamagedTooltip => '破損した記録を削除';

  @override
  String telemetryDeleteFailed(String reason) {
    return '削除が完了しませんでした：$reason';
  }

  @override
  String get telemetryDeleteNeedsConfirmation => '先にこの削除操作を確認してください';

  @override
  String telemetryDeleteSessionBody(String time) {
    return '$time の記録を削除します。この操作は元に戻せません。';
  }

  @override
  String get telemetryDeleteSessionTitle => 'このローカル記録を削除しますか？';

  @override
  String get telemetryDemoData => '内蔵シミュレーターデータ';

  @override
  String get telemetryDismissNotice => '閉じる';

  @override
  String get telemetryEndedByBackground => 'Telltale がバックグラウンドに移行したため停止しました';

  @override
  String get telemetryEndedByConfigurationChanged => 'PIDの選択が変更されました';

  @override
  String get telemetryEndedByDisconnect => '接続が切断されたため停止しました';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return '$minutes 分の上限に達しました';
  }

  @override
  String get telemetryEndedByLibrarySizeLimit => 'ローカル記録の保存容量がいっぱいです';

  @override
  String get telemetryEndedByRecoveredAfterInterruption => '前回の中断後に復元されました';

  @override
  String get telemetryEndedBySessionReplacement => '接続セッションが切り替わりました';

  @override
  String get telemetryEndedBySessionSizeLimit => 'この記録の容量上限に達しました';

  @override
  String get telemetryEndedByStorageBackpressure => 'ストレージの書き込みが追いつきませんでした';

  @override
  String get telemetryEndedByStorageFailure => '保存に失敗しました';

  @override
  String get telemetryEndedByUser => 'ユーザーにより停止されました';

  @override
  String get telemetryExport => 'エクスポート';

  @override
  String get telemetryExportCsv => 'CSVをエクスポート';

  @override
  String telemetryExportFailed(String reason) {
    return 'エクスポートが完了しませんでした：$reason';
  }

  @override
  String get telemetryExportJson => 'JSONをエクスポート';

  @override
  String get telemetryExportSheetTitle => 'ローカル記録をエクスポート';

  @override
  String telemetryGapCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countか所の欠落',
      one: '1か所の欠落',
    );
    return '$_temp0';
  }

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countグループ保存済み — オフラインで再生・エクスポート可能',
      one: '1グループ保存済み — オフラインで再生・エクスポート可能',
    );
    return '$_temp0';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit グループ';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '他$countグループは表示されていません',
      one: '他1グループは表示されていません',
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
    return 'ローカルストレージ：$groupLimit グループ中 $groups グループ、$byteLimit MiB 中 $used MiB';
  }

  @override
  String get telemetryNotConnected => '未接続';

  @override
  String get telemetryOfflineSampledReplay => 'オフラインのサンプリング再生';

  @override
  String get telemetryOpenHistory => 'ローカル記録を開く';

  @override
  String get telemetryPause => '一時停止';

  @override
  String get telemetryPendingOwnerRecovery =>
      'このプロセスがまだ操作を保持しています。この状態が続く場合は、Telltale を完全に終了して再度開いてください';

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first、$second';
  }

  @override
  String get telemetryPlay => '再生';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return '有効にしたOBD信号のみを記録します（位置情報、VIN、アカウントデータは含まれません）。トレンドチャートには最大 $laneLimit 項目が表示されますが、記録には有効な全 $activeCount 項目の信号が保持され、さらに車両の前提条件に基づく推定馬力と推定燃料消費率が追加されます。';
  }

  @override
  String get telemetryRecorderPhaseAwaitingValues => '記録中 — まだ値が届いていません';

  @override
  String get telemetryRecorderPhaseCompleted => '記録を保存しました';

  @override
  String get telemetryRecorderPhaseFailed => '記録の保存に失敗しました';

  @override
  String get telemetryRecorderPhaseFinalizing => '記録を保存しています';

  @override
  String get telemetryRecorderPhaseIdle => 'フォアグラウンドでのローカル記録';

  @override
  String get telemetryRecorderPhasePreparing => '記録を準備しています';

  @override
  String get telemetryRecorderPhaseRecording => '記録中';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return '記録中 $duration';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有効な値を含まない未完了ファイル$count件を整理しました',
      one: '有効な値を含まない未完了ファイル1件を整理しました',
    );
    return '$_temp0';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '破損または競合しているファイル$count件をそのまま残しました',
      one: '破損または競合しているファイル1件をそのまま残しました',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryDamagedNote =>
      '破損した内容は再生やエクスポートには決して使用されず、安全な状態のときに手動でのみ削除できます。';

  @override
  String telemetryRecoveryInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '中断された記録$count件を安全に封印・保存しました',
      one: '中断された記録1件を安全に封印・保存しました',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryTitle => '起動時の記録チェックが完了しました';

  @override
  String get telemetryReload => '再読み込み';

  @override
  String telemetryReplayBreakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countか所の中断',
      one: '1か所の中断',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayLoadFailed => '記録を読み込めませんでした';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return '再生位置 $percent%';
  }

  @override
  String telemetryReplaySampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個のサンプリング点',
      one: '1個のサンプリング点',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayTitle => '記録の再生';

  @override
  String get telemetryReplayUnreadable => '記録が破損しているか読み取れません';

  @override
  String get telemetryRestartToRepairSave =>
      '保存が完了しませんでした — 記録を修復するには Telltale を再起動してください';

  @override
  String get telemetryRestartToRepairStartup =>
      '起動時の整理が完了しませんでした — 記録を修復するには Telltale を再起動してください';

  @override
  String get telemetryReturnToTrends => 'トレンドに戻る';

  @override
  String get telemetryRigData => 'テストリグデータ';

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first。$second';
  }

  @override
  String get telemetrySessionsDamaged => '破損した記録ファイル';

  @override
  String get telemetrySessionsEmpty => 'ローカル記録がまだありません\n接続してから記録を開始してください';

  @override
  String get telemetrySessionsLoadFailed => '読み込めませんでした — 再試行してください';

  @override
  String get telemetrySessionsReplayable => '再生可能な記録';

  @override
  String get telemetrySessionsTitle => 'ローカル記録';

  @override
  String telemetrySignalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count項目の信号',
      one: '1項目の信号',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStartBusy => '別の記録またはファイル操作がまだ完了していません';

  @override
  String get telemetryStartCannotCreateFile => '記録ファイルを作成できませんでした';

  @override
  String get telemetryStartInvalidConfiguration =>
      'このPID選択は安全に記録できません — 定義を確認してください';

  @override
  String get telemetryStartInvalidatedBackground =>
      'Telltale がバックグラウンドに移行しました — 記録は開始されませんでした';

  @override
  String get telemetryStartInvalidatedDisconnect =>
      '接続が切断されました — 記録は開始されませんでした';

  @override
  String get telemetryStartInvalidatedSessionReplacement =>
      '接続セッションが切り替わりました — 記録は開始されませんでした';

  @override
  String get telemetryStartLibraryByteLimit =>
      '記録用のローカル保存容量が不足しています — 先にエクスポートまたは削除してください';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return 'ローカル記録が上限の $limit グループに達しました — 先にエクスポートまたは削除してください';
  }

  @override
  String get telemetryStartMoving => '先に車両を駐車してください';

  @override
  String get telemetryStartNeedsActivePid => '先に少なくとも1つのPIDを有効にしてください';

  @override
  String get telemetryStartNeedsConnection => '記録を開始する前に接続してください';

  @override
  String get telemetryStartNeedsForeground =>
      '記録を開始する前に Telltale をフォアグラウンドに表示してください';

  @override
  String get telemetryStartRecording => '記録を開始しました';

  @override
  String get telemetryStartRecordingButton => '記録開始';

  @override
  String get telemetryStartSpeedUnknown =>
      '車両が停止していることを確認できません — 先に接続を切断してください';

  @override
  String get telemetryStartTooManyPids =>
      '記録では推定馬力と推定燃料消費率の列も確保されます。先にいくつかのPIDをオフにしてください';

  @override
  String get telemetryStarting => '開始中';

  @override
  String get telemetryStatusBusError => 'バスエラー';

  @override
  String telemetryStatusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の状態イベント',
      one: '1件の状態イベント',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStatusFormulaError => '計算式エラー';

  @override
  String get telemetryStatusHeaderMismatch => 'ヘッダーがこのバスと一致しません';

  @override
  String get telemetryStatusNoAnswer => '無応答 — 再試行します';

  @override
  String get telemetryStatusStale => 'データの更新が停止しています';

  @override
  String get telemetryStatusUnsafeServiceRefusal =>
      '読み取り専用クエリではありません — 送信されませんでした';

  @override
  String get telemetryStatusUnsupported => 'コントローラーがこの項目に非対応であると応答しました';

  @override
  String get telemetryStopAndSave => '停止して保存';

  @override
  String telemetryValueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の有効値',
      one: '1件の有効値',
    );
    return '$_temp0';
  }

  @override
  String get transcriptDelete => '削除';

  @override
  String get transcriptDeleteBusy => '別のファイル操作がまだ完了していません。';

  @override
  String get transcriptDeleteFailed => '前回の接続の通信記録を削除できませんでした。';

  @override
  String get transcriptDeleteRefusedBySafety => '現在の車速または接続状態では通信記録を削除できません。';

  @override
  String get transcriptExport => 'エクスポート';

  @override
  String get transcriptExportButton => '通信記録をエクスポート';

  @override
  String get transcriptExportExplanation =>
      '今回の接続では開始時のハンドシェイクと直近の生の通信内容が保持されます。長時間の接続で中間の通信が省略された場合は、ファイル内にその旨が明記されます。実車で値が読み取れない場合、画面の1行のメッセージよりも通信記録をエクスポートして持ち帰る方がはるかに役立ちます。';

  @override
  String transcriptExportFailed(String error) {
    return 'エクスポートに失敗しました：$error';
  }

  @override
  String get transcriptExportWithHex => '16進数を含める';

  @override
  String get transcriptNothingToExport => 'エクスポートできる通信記録がありません。';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return '$timestamp に残された記録（$size）です。システムによる Telltale の強制終了やスマートフォンの電源切れから保護されました。';
  }

  @override
  String get transcriptRecoveredChanged => '前回の接続の通信記録が更新されました — もう一度確認してください。';

  @override
  String get transcriptRecoveredTitle => '前回の接続の通信記録';

  @override
  String transcriptSizeBytes(int bytes) {
    String _temp0 = intl.Intl.pluralLogic(
      bytes,
      locale: localeName,
      other: '$bytes バイト',
      one: '1 バイト',
    );
    return '$_temp0';
  }

  @override
  String get trendAxisNow => '現在';

  @override
  String get trendChooseSignals => '信号を選択';

  @override
  String get trendLiveData => 'ライブデータ';

  @override
  String get trendNoSignalsBody => '先にPID画面で監視したい信号を有効にしてください。';

  @override
  String get trendNoSignalsTitle => '利用可能なトレンド信号がありません';

  @override
  String get trendNoUnits => '単位なし';

  @override
  String trendPickSignalsBody(int limit) {
    return '最大 $limit 項目の信号を比較できます。これによりポーリング対象のPIDが変わることはありません。';
  }

  @override
  String get trendPickSignalsTitle => 'トレンド信号を選択';

  @override
  String trendRemoveSignal(String name) {
    return '$name を除外';
  }

  @override
  String get trendSelectionSaveFailed => 'トレンド表示の選択を保存できませんでした';

  @override
  String trendSheetBody(int limit) {
    return '最大 $limit 項目まで選択できます。これはチャートの表示のみを変更し、PIDのポーリングや進行中の記録には影響しません。';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return '完了 · $selected/$limit';
  }

  @override
  String get trendSignalNoLongerActive => '選択された信号のうち1つがPID監視リストから外れました';

  @override
  String get trendSignalsHeading => 'トレンド信号';

  @override
  String trendTooManySelected(int limit) {
    return '最大 $limit 項目まで選択してください';
  }

  @override
  String trendWindowSemantics(int seconds) {
    return '直近 $seconds 秒間を表示中';
  }

  @override
  String get wearBack => '戻る';

  @override
  String get wearBatteryVoltageLabel => '補機バッテリー';

  @override
  String get wearBleAdapters => 'BLE アダプター';

  @override
  String get wearCancel => 'キャンセル';

  @override
  String get wearConfirmVehicle => '車両を確認';

  @override
  String get wearConfirmVehicleAccept => 'この車両です';

  @override
  String get wearConfirmVehicleBody =>
      '確認すると、今回の接続が終わるまでこの車種の読み取り専用バッテリークエリがポーリングされます。車種が異なると、もっともらしい見た目でありながら誤った数値が返されるおそれがあります。確信が持てない場合はキャンセルしてください。';

  @override
  String wearConnectFailed(String adapter) {
    return '接続できませんでした：$adapter';
  }

  @override
  String get wearConnecting => '接続中…';

  @override
  String get wearDemoSimulator => 'デモシミュレーター';

  @override
  String get wearDisconnect => '切断';

  @override
  String get wearDisconnectQuestion => '切断しますか？';

  @override
  String get wearNoDevicesFound => 'デバイスが見つかりません';

  @override
  String get wearPermissionBluetooth => 'Bluetooth';

  @override
  String get wearPermissionLocation => '位置情報';

  @override
  String get wearScanAgain => '再スキャン';

  @override
  String get wearScanFailed => 'スキャン失敗 — 再試行してください';

  @override
  String wearScanPermissionNeeded(String permission) {
    return 'スキャンには$permissionの権限が必要です';
  }

  @override
  String wearScanPermissionPermanentlyDenied(String permission) {
    return '$permissionの権限が永久に拒否されています — システム設定で有効にしてから再試行してください';
  }

  @override
  String get wearScanning => 'スキャン中…';

  @override
  String get telemetryRecorderNotRecording => '未記録';

  @override
  String get dtcKindStored => '保存済み';

  @override
  String get dtcKindPending => '保留中';

  @override
  String get dtcKindPermanent => '永久';

  @override
  String get dtcKindStoredExplanation => '確定した故障です。通常、メーターパネルの故障警告灯が点灯します。';

  @override
  String get dtcKindPendingExplanation => '1回検出されましたが、まだ確定のしきい値には達していません。';

  @override
  String get dtcKindPermanentExplanation =>
      'スキャンツールでは消去できません。ECU が修理を確認した後にのみ、ECU 自身が消去します。';

  @override
  String get dtcSystemPowertrain => 'パワートレイン';

  @override
  String get dtcSystemChassis => 'シャシー';

  @override
  String get dtcSystemBody => 'ボディ';

  @override
  String get dtcSystemNetwork => 'ネットワーク';

  @override
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions =>
      '燃料・空気計量および補助排ガス制御';

  @override
  String get dtcSubsystemFuelAirMetering => '燃料および空気計量';

  @override
  String get dtcSubsystemFuelAirMeteringInjectorCircuit =>
      '燃料および空気計量（インジェクター回路）';

  @override
  String get dtcSubsystemIgnitionOrMisfire => '点火システムまたは失火';

  @override
  String get dtcSubsystemAuxiliaryEmissionControls => '補助排ガス制御';

  @override
  String get dtcSubsystemSpeedAndIdleControl => '車速制御およびアイドル制御システム';

  @override
  String get dtcSubsystemComputerOutputCircuit => 'コンピューター出力回路';

  @override
  String get dtcSubsystemTransmission => 'トランスミッション';

  @override
  String get dtcSubsystemControlModuleSignals => '制御モジュール、入力および出力信号';

  @override
  String get dtcDescriptionB0001 => '運転席エアバッグ展開制御の異常';

  @override
  String get dtcDescriptionP0011 => 'カムシャフト位置 A — タイミング進角過大またはシステム性能異常（バンク1）';

  @override
  String get dtcDescriptionP0014 => 'カムシャフト位置 B — タイミング進角過大またはシステム性能異常（バンク1）';

  @override
  String get dtcDescriptionP0016 => 'クランクシャフト位置・カムシャフト位置の相関異常（バンク1 センサーA）';

  @override
  String get dtcDescriptionP0087 => '燃料レール／システム圧力の過小';

  @override
  String get dtcDescriptionP0088 => '燃料レール／システム圧力の過大';

  @override
  String get dtcDescriptionP0100 => 'エアフロセンサー（MAF）回路の異常';

  @override
  String get dtcDescriptionP0101 => 'エアフロセンサーの範囲／性能異常';

  @override
  String get dtcDescriptionP0102 => 'エアフロセンサー回路の低入力';

  @override
  String get dtcDescriptionP0103 => 'エアフロセンサー回路の高入力';

  @override
  String get dtcDescriptionP0105 => '吸気管絶対圧／大気圧センサー回路の異常';

  @override
  String get dtcDescriptionP0106 => '吸気管絶対圧センサーの範囲／性能異常';

  @override
  String get dtcDescriptionP0107 => '吸気管絶対圧センサー回路の低入力';

  @override
  String get dtcDescriptionP0108 => '吸気管絶対圧センサー回路の高入力';

  @override
  String get dtcDescriptionP0110 => '吸気温度センサー回路の異常';

  @override
  String get dtcDescriptionP0111 => '吸気温度センサーの範囲／性能異常';

  @override
  String get dtcDescriptionP0112 => '吸気温度センサー回路の低入力';

  @override
  String get dtcDescriptionP0113 => '吸気温度センサー回路の高入力';

  @override
  String get dtcDescriptionP0115 => 'エンジン水温センサー回路の異常';

  @override
  String get dtcDescriptionP0116 => 'エンジン水温センサーの範囲／性能異常';

  @override
  String get dtcDescriptionP0117 => 'エンジン水温センサー回路の低入力';

  @override
  String get dtcDescriptionP0118 => 'エンジン水温センサー回路の高入力';

  @override
  String get dtcDescriptionP0120 => 'スロットルポジションセンサー回路の異常';

  @override
  String get dtcDescriptionP0121 => 'スロットルポジションセンサーの範囲／性能異常';

  @override
  String get dtcDescriptionP0122 => 'スロットルポジションセンサー回路の低入力';

  @override
  String get dtcDescriptionP0123 => 'スロットルポジションセンサー回路の高入力';

  @override
  String get dtcDescriptionP0125 => 'クローズドループ燃料制御に必要な水温の不足';

  @override
  String get dtcDescriptionP0128 => '水温がサーモスタット規定温度未満';

  @override
  String get dtcDescriptionP0130 => 'O2センサー回路の異常（バンク1 センサー1）';

  @override
  String get dtcDescriptionP0131 => 'O2センサー回路の低電圧（バンク1 センサー1）';

  @override
  String get dtcDescriptionP0132 => 'O2センサー回路の高電圧（バンク1 センサー1）';

  @override
  String get dtcDescriptionP0133 => 'O2センサー回路の応答遅れ（バンク1 センサー1）';

  @override
  String get dtcDescriptionP0134 => 'O2センサー回路の信号変化なし（バンク1 センサー1）';

  @override
  String get dtcDescriptionP0135 => 'O2センサーヒーター回路の異常（バンク1 センサー1）';

  @override
  String get dtcDescriptionP0136 => 'O2センサー回路の異常（バンク1 センサー2）';

  @override
  String get dtcDescriptionP0137 => 'O2センサー回路の低電圧（バンク1 センサー2）';

  @override
  String get dtcDescriptionP0138 => 'O2センサー回路の高電圧（バンク1 センサー2）';

  @override
  String get dtcDescriptionP0140 => 'O2センサー回路の信号変化なし（バンク1 センサー2）';

  @override
  String get dtcDescriptionP0141 => 'O2センサーヒーター回路の異常（バンク1 センサー2）';

  @override
  String get dtcDescriptionP0150 => 'O2センサー回路の異常（バンク2 センサー1）';

  @override
  String get dtcDescriptionP0155 => 'O2センサーヒーター回路の異常（バンク2 センサー1）';

  @override
  String get dtcDescriptionP0156 => 'O2センサー回路の異常（バンク2 センサー2）';

  @override
  String get dtcDescriptionP0161 => 'O2センサーヒーター回路の異常（バンク2 センサー2）';

  @override
  String get dtcDescriptionP0170 => '燃料トリムの異常（バンク1）';

  @override
  String get dtcDescriptionP0171 => 'システム過希薄（リーン）（バンク1）';

  @override
  String get dtcDescriptionP0172 => 'システム過濃（リッチ）（バンク1）';

  @override
  String get dtcDescriptionP0173 => '燃料トリムの異常（バンク2）';

  @override
  String get dtcDescriptionP0174 => 'システム過希薄（リーン）（バンク2）';

  @override
  String get dtcDescriptionP0175 => 'システム過濃（リッチ）（バンク2）';

  @override
  String get dtcDescriptionP0190 => '燃料レール圧力センサー回路の異常';

  @override
  String get dtcDescriptionP0201 => 'インジェクター回路の異常または断線 — 第1気筒';

  @override
  String get dtcDescriptionP0202 => 'インジェクター回路の異常または断線 — 第2気筒';

  @override
  String get dtcDescriptionP0203 => 'インジェクター回路の異常または断線 — 第3気筒';

  @override
  String get dtcDescriptionP0204 => 'インジェクター回路の異常または断線 — 第4気筒';

  @override
  String get dtcDescriptionP0217 => 'エンジンのオーバーヒート状態';

  @override
  String get dtcDescriptionP0221 => 'スロットル／ペダルポジションセンサー B の範囲／性能異常';

  @override
  String get dtcDescriptionP0222 => 'スロットル／ペダルポジションセンサー B 回路の低入力';

  @override
  String get dtcDescriptionP0223 => 'スロットル／ペダルポジションセンサー B 回路の高入力';

  @override
  String get dtcDescriptionP0234 => 'ターボチャージャー／スーパーチャージャーの過給圧過大（オーバーブースト）';

  @override
  String get dtcDescriptionP0299 => 'ターボチャージャー／スーパーチャージャー A の過給圧不足（アンダーブースト）';

  @override
  String get dtcDescriptionP0300 => 'ランダムまたは複数気筒の失火を検出';

  @override
  String get dtcDescriptionP0301 => '第1気筒の失火を検出';

  @override
  String get dtcDescriptionP0302 => '第2気筒の失火を検出';

  @override
  String get dtcDescriptionP0303 => '第3気筒の失火を検出';

  @override
  String get dtcDescriptionP0304 => '第4気筒の失火を検出';

  @override
  String get dtcDescriptionP0305 => '第5気筒の失火を検出';

  @override
  String get dtcDescriptionP0306 => '第6気筒の失火を検出';

  @override
  String get dtcDescriptionP0307 => '第7気筒の失火を検出';

  @override
  String get dtcDescriptionP0308 => '第8気筒の失火を検出';

  @override
  String get dtcDescriptionP0316 => '始動直後の失火を検出';

  @override
  String get dtcDescriptionP0325 => 'ノックセンサー回路の異常（バンク1）';

  @override
  String get dtcDescriptionP0326 => 'ノックセンサーの範囲／性能異常（バンク1）';

  @override
  String get dtcDescriptionP0327 => 'ノックセンサー回路の低入力（バンク1）';

  @override
  String get dtcDescriptionP0328 => 'ノックセンサー回路の高入力（バンク1）';

  @override
  String get dtcDescriptionP0330 => 'ノックセンサー回路の異常（バンク2）';

  @override
  String get dtcDescriptionP0335 => 'クランクシャフトポジションセンサー回路の異常';

  @override
  String get dtcDescriptionP0336 => 'クランクシャフトポジションセンサーの範囲／性能異常';

  @override
  String get dtcDescriptionP0340 => 'カムシャフトポジションセンサー回路の異常';

  @override
  String get dtcDescriptionP0341 => 'カムシャフトポジションセンサーの範囲／性能異常';

  @override
  String get dtcDescriptionP0351 => 'イグニッションコイル A 一次／二次回路の異常';

  @override
  String get dtcDescriptionP0352 => 'イグニッションコイル B 一次／二次回路の異常';

  @override
  String get dtcDescriptionP0353 => 'イグニッションコイル C 一次／二次回路の異常';

  @override
  String get dtcDescriptionP0354 => 'イグニッションコイル D 一次／二次回路の異常';

  @override
  String get dtcDescriptionP0355 => 'イグニッションコイル E 一次／二次回路の異常';

  @override
  String get dtcDescriptionP0356 => 'イグニッションコイル F 一次／二次回路の異常';

  @override
  String get dtcDescriptionP0400 => '排気ガス再循環（EGR）流量の異常';

  @override
  String get dtcDescriptionP0401 => '排気ガス再循環（EGR）流量の不足';

  @override
  String get dtcDescriptionP0402 => '排気ガス再循環（EGR）流量の過大';

  @override
  String get dtcDescriptionP0403 => '排気ガス再循環（EGR）制御回路の異常';

  @override
  String get dtcDescriptionP0404 => '排気ガス再循環（EGR）制御回路の範囲／性能異常';

  @override
  String get dtcDescriptionP0410 => '二次空気噴射システムの異常';

  @override
  String get dtcDescriptionP0411 => '二次空気噴射システムの流量異常を検出';

  @override
  String get dtcDescriptionP0412 => '二次空気噴射システム切替バルブ A 回路の異常';

  @override
  String get dtcDescriptionP0420 => '触媒システムの浄化効率がしきい値未満（バンク1）';

  @override
  String get dtcDescriptionP0430 => '触媒システムの浄化効率がしきい値未満（バンク2）';

  @override
  String get dtcDescriptionP0440 => 'エバポ（蒸発ガス）排出制御システムの異常';

  @override
  String get dtcDescriptionP0441 => 'エバポ（蒸発ガス）排出システムのパージ流量異常';

  @override
  String get dtcDescriptionP0442 => 'エバポ（蒸発ガス）排出システムの漏れを検出（少量の漏れ）';

  @override
  String get dtcDescriptionP0443 => 'エバポ（蒸発ガス）排出パージ制御バルブ回路の異常';

  @override
  String get dtcDescriptionP0446 => 'エバポ（蒸発ガス）排出ベント制御回路の異常';

  @override
  String get dtcDescriptionP0447 => 'エバポ（蒸発ガス）排出ベント制御回路の断線';

  @override
  String get dtcDescriptionP0449 => 'エバポ（蒸発ガス）排出ベントバルブ／ソレノイド回路の異常';

  @override
  String get dtcDescriptionP0451 => 'エバポ（蒸発ガス）排出システム圧力センサーの範囲／性能異常';

  @override
  String get dtcDescriptionP0452 => 'エバポ（蒸発ガス）排出システム圧力センサー回路の低入力';

  @override
  String get dtcDescriptionP0453 => 'エバポ（蒸発ガス）排出システム圧力センサー回路の高入力';

  @override
  String get dtcDescriptionP0455 => 'エバポ（蒸発ガス）排出システムの漏れを検出（大量の漏れ）';

  @override
  String get dtcDescriptionP0456 => 'エバポ（蒸発ガス）排出システムの漏れを検出（ごく少量の漏れ）';

  @override
  String get dtcDescriptionP0480 => '冷却ファン 1 制御回路の異常';

  @override
  String get dtcDescriptionP0500 => '車速センサーの異常';

  @override
  String get dtcDescriptionP0505 => 'アイドル制御システムの異常';

  @override
  String get dtcDescriptionP0506 => 'アイドル制御システムの回転数が規定値未満';

  @override
  String get dtcDescriptionP0507 => 'アイドル制御システムの回転数が規定値超過';

  @override
  String get dtcDescriptionP0508 => 'アイドル制御システム回路の低入力';

  @override
  String get dtcDescriptionP0509 => 'アイドル制御システム回路の高入力';

  @override
  String get dtcDescriptionP0560 => 'システム電圧の異常';

  @override
  String get dtcDescriptionP0562 => 'システム電圧の低下';

  @override
  String get dtcDescriptionP0563 => 'システム電圧の過大';

  @override
  String get dtcDescriptionP0603 => '制御モジュール内部キープアライブメモリ（KAM）エラー';

  @override
  String get dtcDescriptionP0605 => '制御モジュール内部読み取り専用メモリ（ROM）エラー';

  @override
  String get dtcDescriptionP0606 => 'ECM/PCM プロセッサーの異常';

  @override
  String get dtcDescriptionP0700 =>
      'トランスミッション制御モジュールが故障警告灯の点灯を要求しました。故障コード自体はトランスミッションモジュール内にあり、個別に読み取る必要があります';

  @override
  String get dtcDescriptionP0701 => 'トランスミッション制御システムの範囲／性能異常';

  @override
  String get dtcDescriptionP0702 => 'トランスミッション制御システムの電気的異常';

  @override
  String get dtcDescriptionP0705 => 'トランスミッションレンジセンサー回路の異常';

  @override
  String get dtcDescriptionP0715 => '入力軸／タービン回転数センサー回路の異常';

  @override
  String get dtcDescriptionP0720 => '出力軸回転数センサー回路の異常';

  @override
  String get dtcDescriptionP0730 => '不適切なギア比';

  @override
  String get dtcDescriptionP0740 => 'トルクコンバータークラッチ回路の異常';

  @override
  String get dtcDescriptionP0741 => 'トルクコンバータークラッチのオフ固着';

  @override
  String get dtcDescriptionP0750 => 'シフトソレノイド A の異常';

  @override
  String get dtcDescriptionP0755 => 'シフトソレノイド B の異常';

  @override
  String get dtcDescriptionP2135 => 'スロットルポジションセンサー A/B の電圧相関異常';

  @override
  String get dtcDescriptionU0100 => 'ECM/PCM との通信喪失';

  @override
  String get dtcDescriptionU0101 => 'トランスミッション制御モジュールとの通信喪失';

  @override
  String get dtcDescriptionU0121 => 'ABS制御モジュールとの通信喪失';

  @override
  String get dtcDescriptionU0140 => 'ボディ制御モジュールとの通信喪失';

  @override
  String get dtcDescriptionU0155 => 'メーターパネル制御モジュールとの通信喪失';

  @override
  String get gaugeSkinCluster => 'クラスター';

  @override
  String get gaugeSkinClusterDescription =>
      '純正メータークラスターのような外観です。針、270度の文字盤、奥行きのある盤面を備えています。';

  @override
  String get gaugeSkinMinimal => 'ミニマル';

  @override
  String get gaugeSkinMinimalDescription =>
      '半円の弧のみ、針なし、目盛りなし。動きではなく数値を読み取るためのデザインです。';

  @override
  String get gaugeSkinTrack => 'トラック';

  @override
  String get gaugeSkinTrackDescription =>
      'セグメントバー表示、スムージングなし。中間の補間を一切行わず、届いた値をそのまま即座に表示します。';

  @override
  String get gaugeSkinClassic => 'クラシック';

  @override
  String get gaugeSkinClassicDescription =>
      '印刷風の文字盤、全周に配置された数字、機械式時計のようにゆっくりと落ち着く針を備えています。';

  @override
  String get gaugeSkinNight => 'ナイト';

  @override
  String get gaugeSkinNightDescription =>
      '夜間走行向けです。低輝度、浅い弧、アニメーションなしで、運転中の注意を極力奪わないように設計されています。';

  @override
  String get derivedAirflowSourceMaf => 'MAF センサー';

  @override
  String get derivedAirflowSourceSpeedDensity => 'スピードデンシティ推定';

  @override
  String get derivedAirflowSourceUnavailable => '吸入空気量を取得できません';

  @override
  String get derivedFuelSourceStoichiometric => '理論空燃比による推定';

  @override
  String get derivedFuelSourceUnavailable => '燃料消費率を取得できません';

  @override
  String get telemetrySourceDemo => '内蔵シミュレーター';

  @override
  String get telemetrySourceRig => 'テストリグ';

  @override
  String get telemetrySourceFieldApp => '通常の実車接続（fieldアプリ）';

  @override
  String get fuelTypeGasoline => 'ガソリン';

  @override
  String get fuelTypeDiesel => '軽油（ディーゼル）';

  @override
  String get fuelTypeLpg => 'LPG（液化石油ガス）';

  @override
  String get fuelTypeEthanolE85 => 'E85 エタノール';

  @override
  String get drivetrainFwd => '前輪駆動（FWD）';

  @override
  String get drivetrainRwd => '後輪駆動（RWD）';

  @override
  String get drivetrainAwd => '四輪駆動（AWD）';

  @override
  String get assumptionFieldMass => '車両重量';

  @override
  String get assumptionFieldDragCoefficient => 'Cd';

  @override
  String get assumptionFieldFrontalArea => '前面投影面積';

  @override
  String get assumptionFieldRollingResistance => '転がり抵抗係数';

  @override
  String get assumptionFieldDrivetrainEfficiency => '駆動系効率';

  @override
  String get assumptionFieldFuelType => '燃料';

  @override
  String get assumptionFieldStoichAfr => 'AFR';

  @override
  String get assumptionFieldFuelDensity => '密度';

  @override
  String get assumptionFieldDisplacement => '排気量';

  @override
  String get assumptionFieldVolumetricEfficiency => 'VE';

  @override
  String get vehicleFieldOriginGenericDefault => '汎用デフォルト値';

  @override
  String get vehicleFieldOriginUserEntered => '手動入力';

  @override
  String get vehicleFieldOriginOfficialRegistry => '公式カタログ登録値';

  @override
  String get vehicleFieldOriginManufacturerPublication => 'メーカー公表値';

  @override
  String get vehicleFieldOriginScientificModel => 'モデル係数';

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
      'L/h = (MAF g/s) / (AFR × fuel density g/L) × 3600; MAF は PID 0110 または speed-density（RPM × MAP × 排気量 × VE / T_K）; L/100km = (L/h) / speed_kmh × 100';

  @override
  String get datumAssumptionsFromRecording => 'この推定には、記録当時の車両設定が使用されています。';

  @override
  String adapterConcernFirmwareNeverReleasedSummary(String version) {
    return '公開されたことのないファームウェア v$version を報告しています';
  }

  @override
  String get adapterConcernFirmwareNeverReleasedDetail =>
      'Elm Electronics はこのバージョンを公開したことがないため、このアダプターのファームウェアは自称しているものではありません。この種の製品でも多くは動作しますが、自己記述は信頼できず、読み取れない項目がある場合はまずこのアダプターを疑ってみる価値があります。';

  @override
  String adapterConcernPpsRefusedSummary(String version) {
    return 'v$version と自称していますが、v1.1 からある ATPPS を認識しません';
  }

  @override
  String get adapterConcernPpsRefusedDetail =>
      'プログラマブルパラメータ要約（ATPPS）は ELM327 v1.1 から存在し、OBDLink などの上位アダプターでもサポートされています。自称するバージョンと実際に実装されているコマンドが一致していません。';

  @override
  String get adapterConcernNoIdentitySummary =>
      '初期リリースから存在するデバイス識別コマンド AT@1 に応答しません';

  @override
  String get adapterConcernNoIdentityDetail =>
      'このコマンドは ELM327 v1.0 から存在します。応答しないということは、このチップのコマンドセットがいずれの公式ファームウェアよりも少ないことを意味します。';

  @override
  String get telemetryReplaySampled =>
      'プレビューはサンプリング済みです。エクスポートには記録されたすべてのイベントが保持されます。';

  @override
  String get telemetryExportDisclosure =>
      'エクスポートには、信号名、値、観測時刻と発生元時刻、通信種別、プロトコル、固定されたPIDのラベル・単位・計算式、および推定の前提条件（車両重量、空気抵抗、排気量、燃料などのパラメータ）が含まれます。JSONには、独自のカスタムラベル、単位、計算式、および完全な固定定義も含まれる場合があります。エクスポートには VIN、GPS、アカウント、アダプターのアドレス、完全な車両プロファイル、および生の診断通信データは含まれません。';

  @override
  String get connectTransportCancelled => '接続の試行が完了前に停止されました。';

  @override
  String get connectTransportWifiRouteNoNetwork =>
      'スマートフォンがいずれの Wi-Fi ネットワークにも接続されていないため、アダプターへの通信経路がありません。アダプターの Wi-Fi ホットスポットに接続してから再試行してください。';

  @override
  String get connectTransportWifiRouteAmbiguous =>
      'スマートフォンが複数の Wi-Fi ネットワークに接続されており、どれがアダプターのものか判別できないため、いずれも選択されませんでした。アダプター以外の Wi-Fi 接続を切断してから再試行してください。';

  @override
  String get connectTransportWifiRouteRefused =>
      'この接続を Wi-Fi 経由で通信させる要求がシステムに拒否されました。スマートフォンは Wi-Fi に接続されていますが、この通信での使用が許可されませんでした。';

  @override
  String get connectTransportWifiRouteTimeout =>
      'この接続を Wi-Fi 経由で通信させる要求にシステムが応答しませんでした。数秒待ってから再試行してください。';

  @override
  String get connectTransportWifiRouteUnclassified =>
      'システムから理由が示されないまま、この接続を Wi-Fi 経由で通信させることができませんでした。エラーの全文は下の通信記録に残されています。';

  @override
  String get connectTransportWifiHostUnreachable =>
      'そのアドレスからの応答がありませんでした。スマートフォンがアダプターの Wi-Fi ホットスポットに接続されているか確認してください。システムから「インターネットに接続できません。接続を維持しますか？」と尋ねられた場合は、維持を選択してください。モバイルデータ通信をオフにすると改善する場合もあります。';

  @override
  String get connectTransportWifiConnectTimeout =>
      '制限時間内にそのアドレスからの応答がありませんでした。';

  @override
  String get connectTransportWifiRouteRestoreFailed =>
      '接続自体は成功しましたが、スマートフォンのネットワークルーティングを元に戻せなかったため、変更されたまま残るのを防ぐために接続を切断しました。アプリを再起動してからもう一度お試しください。';

  @override
  String get connectTransportBleLinkFailed =>
      'アダプターに接続できませんでした。電源が入っており、通信範囲内にあることを確認してください。';

  @override
  String get connectTransportBleNoSerialCharacteristic =>
      'デバイスに接続できましたが、シリアルポートが見つからなかったため、ELM327 アダプターではない可能性があります。';

  @override
  String get connectTransportClassicAllTiersRefused =>
      'アダプターに接続できませんでした。先にシステムのBluetooth設定でペアリングを済ませ、アダプターがOBDソケットに差し込まれてイグニッションがONになっていることを確認してください。';

  @override
  String get connectTransportClassicConnectTimeout =>
      'アダプターへの接続がタイムアウトしました。まだ応答途中の可能性があるため、すぐに再試行せず数秒待ってからお試しください。';

  @override
  String get connectTransportSerialPortOpenFailed =>
      'シリアルポートを開けませんでした。システムがこのアダプター用のポート（Windows では COMx、Linux では /dev/rfcomm*）を作成しており、イグニッションがONになっていることを確認してください。';

  @override
  String get connectTransportSerialDroppedOnOpen => 'シリアルポートが開いた直後に再び閉じられました。';

  @override
  String get settingsManualCommandNotConnected =>
      '何も接続されていないため、コマンドは送信されませんでした。';

  @override
  String get settingsManualCommandLinkDropped =>
      'このコマンドの応答待ち中にアダプターとの接続が切断されたため、応答はありませんでした。アダプターがこのコマンドを受信したかどうかは不明です。';

  @override
  String get settingsManualCommandDisconnectedByApp =>
      'このコマンドの応答待ち中にアプリが接続を閉じたため、応答はありませんでした。アダプターや車両に異常はありません。';

  @override
  String get settingsManualCommandAdapterSilentOnResync =>
      'アダプターの応答が送信したコマンドとずれてしまい、再同期のための確認にも応答しなかったため、接続を切断しました。再試行する前に再接続してください。';

  @override
  String get settingsManualCommandLinkStoppedResponding =>
      'アダプターから一定時間何も届かなかったため、接続が切断されました。電源はまだ入っている可能性があり、確実なのは無応答が続いたことだけです。';

  @override
  String get settingsManualCommandWriteFailed =>
      'アダプターとの接続へコマンドを送出できませんでした。アダプターにどこまで届いたかは不明です。';

  @override
  String get settingsManualCommandTimedOut =>
      '制限時間内に応答が届きませんでした。アダプターが接続されており、イグニッションがONになっているか確認してください。';

  @override
  String get settingsManualCommandOperationRetired =>
      'このセッションが終了したかバックグラウンドに移行したため、コマンドは送信されませんでした。';

  @override
  String get settingsManualCommandRequestUnaddressable =>
      'この要求はこの車両が使用しているバス上ではアドレッシングできないため、送信されませんでした。再試行しても結果は変わりません。';

  @override
  String get commandFailureBusJ1939 =>
      'このバスは SAE J1939（大型商用車・建機用）であり、本アプリが読み取る OBD2 診断プロトコルではないため、このクエリは読み取れません。';

  @override
  String commandFailureUserCanFramingUnknown(
    String protocol,
    String parameter,
  ) {
    return 'このアダプターはユーザー定義CANプロトコル $protocol に設定されており、そのフレーミングは $parameter によって決まります。アダプターがその設定を報告しなかったため、バス形式を確認できず、このクエリを安全にデコードできません。';
  }

  @override
  String get commandFailureBusUndetermined =>
      '車両のバスプロトコルがまだ確定していないため、このクエリを安全にデコードできません。再接続してください。';

  @override
  String get settingsManualCommandCustomFlowControlRejected =>
      'アダプターがカスタム Flow Control コマンドを拒否したため、要求されたモードは適用されず、測定値も生成されませんでした。';

  @override
  String get settingsManualCommandFlowControlRestoreFailed =>
      'アダプターがデフォルトの Flow Control（ATFCSM0）への復元を拒否したため、再接続するまでポーリングを停止しました。';

  @override
  String get settingsManualCommandExtendedAddressingUnavailable =>
      'この ELM327 経路では拡張アドレッシングを利用できません。';

  @override
  String get settingsManualCommandRawIsoTpModeUnavailable =>
      'この ELM327 経路では、ホスト側から参照可能な ISO-TP 再構成は利用できません。';

  @override
  String get settingsManualCommandCanPriorityUnavailable =>
      'この ELM327 経路ではCAN優先度プログラミングを利用できません。';

  @override
  String get settingsManualCommandCanReceiveFilterUnavailable =>
      'この ELM327 経路ではCAN受信フィルタリングを利用できません。';

  @override
  String get settingsManualCommandHeaderRestoreFailed =>
      'アダプターがヘッダー（ATSH）の復元を拒否したため、再接続するまでポーリングを停止しました。';

  @override
  String get manualCommandRefusedEmpty => '何も入力されていないため、何も送信されませんでした。';

  @override
  String get manualCommandRefusedMoreThanOneCommand =>
      'このテキストには改行または制御文字が含まれており、一度に複数のコマンドを送信してしまいます。アダプターは改行でコマンドを区切るため、2つ目のコマンドはここで行われるすべてのチェック（故障コード消去を拒否するチェックを含む）をすり抜けてしまいます。コマンドは1つずつ送信してください。';

  @override
  String manualCommandRefusedAdapterStateWouldChange(
    Object command,
    Object allowed,
  ) {
    return 'この入力欄は問い合わせのみを受け付け、アダプターの設定状態を変更するコマンドは受け付けません。「$command」はアダプターの状態を変更してしまいますが、アプリ側の認識は元のまま残るため、その後の読み取りが別のコントローラーからのものになっても、画面にはそのことが何も示されないおそれがあります。\n送信可能なクエリ：$allowed。';
  }

  @override
  String get manualCommandRefusedClearHasItsOwnButton =>
      '故障コードを消去するには、故障コード画面の「消去」ボタンを使用してください。ここから送信すると、確認ダイアログ、対象範囲チェック、および応答検証をすべてスキップし、現在選択されている1つのコントローラーにしか届きません。';

  @override
  String manualCommandRefusedCharactersNoObdCommandHas(Object command) {
    return 'コマンド「$command」にはOBDコマンドで使われない文字が含まれています。この入力欄では16進数のサービスコードとパラメータ（0100、03、2211A6 など）、または AT で始まるアダプター照会のみを受け付けます。';
  }

  @override
  String manualCommandRefusedNotAReadOnlyQuery(Object command, Object allowed) {
    return '「$command」はこの入力欄で認識できないコマンドです。読み取り専用クエリ（Mode $allowed）およびアダプター照会のみを受け付けます。';
  }

  @override
  String commandFailureQueryHeaderRefused(Object header) {
    return 'この要求の宛先をコントローラー $header に設定することをアダプターが拒否したため、送信されませんでした。アダプターが現在保持しているアドレスのまま送信すると、問い合わせていない別のコントローラーから応答が返ってきてしまいます。';
  }

  @override
  String commandFailureWholeVehicleHeaderRefused(Object address) {
    return 'アダプターが車両全体への問い合わせに必要なアドレス $address への切り替えを拒否しました。このアドレスなしでは応答を送信元のコントローラーに紐付けられないため、要求は送信されませんでした。';
  }

  @override
  String commandFailureLegacyScanWouldBePartial(Object installed) {
    return 'この車両はすべてのコントローラーに届く標準アドレスを持たない旧式のバスを使用しており、アダプターは現在コントローラー $installed に設定されています。このままスキャンすると1つのコントローラーのみを対象としながら車両全体の結果として表示されてしまうため、送信されませんでした。再接続してからもう一度スキャンしてください。';
  }

  @override
  String get pidFormulaEmpty => '計算式が空です。';

  @override
  String get pidFormulaEmptySubExpression =>
      '計算式の一部が空です。演算子の後ろに何もないか、括弧の中が空になっています。';

  @override
  String get pidFormulaUnbalancedParentheses =>
      '括弧が対応していません：すべての ( に対応する ) が必要です。';

  @override
  String pidFormulaUnparsableTerm(String term) {
    return '「$term」はこのエディターで認識できる数値、演算子、または名前ではありません。';
  }

  @override
  String get pidFormulaFunctionNestingTooDeep =>
      'ABS()、LOG10()、LOG()、SQRT() の入れ子が深すぎるため計算できません。計算式を簡略化してください。';

  @override
  String get pidFormulaParenthesisNestingTooDeep =>
      '括弧の入れ子が深すぎるため計算できません。計算式を簡略化してください。';

  @override
  String get pidFormulaDivisionByZero => '計算式でゼロ除算が行われています。';

  @override
  String get pidFormulaModuloByZero => '計算式でゼロによる剰余演算が行われています。';

  @override
  String pidFormulaLog10NonPositiveArgument(double argument) {
    return 'LOG10 の引数は 0 より大きい必要がありますが、計算結果は $argument でした。';
  }

  @override
  String pidFormulaLogNonPositiveArgument(double argument) {
    return 'LOG の引数は 0 より大きい必要がありますが、計算結果は $argument でした。';
  }

  @override
  String pidFormulaSqrtNegativeArgument(double argument) {
    return 'SQRT の引数は 0 以上である必要がありますが、計算結果は $argument でした。';
  }

  @override
  String get pidFormulaResultNotFinite =>
      '演算結果が有効な数値にならなかったため、表示できる読み取り値がありません。';

  @override
  String pidFormulaByteBeyondResponse(String letter, int count) {
    return '計算式はバイト $letter を参照していますが、応答には $count バイトしか含まれていませんでした。';
  }

  @override
  String get pidFormulaBaroControllerUnknown =>
      'どのコントローラーの大気圧を指しているか判別できないため、ここでは BARO を使用できません。';

  @override
  String get pidFormulaBaroTwoDefinitions =>
      '2つの定義がどちらも大気圧を提供しているため、値がどちらのものか判別できず、どちらも使用できません。大気圧を測定するメーターの片方を削除してください。';

  @override
  String get pidFormulaBaroNotYetMeasured => '大気圧がまだ読み取られていないため、計算できません。';

  @override
  String get pidFormulaBaroMeasurementStale => '大気圧の読み取り値の更新が停止しているため、計算できません。';

  @override
  String get pidFormulaBaroParenFormUnsupported =>
      'BARO() は Android 気圧計／ECU 大気圧（psi）であり、この方言では実装されていません。キャッシュされた大気圧を使用するには、括弧なしの BARO を記述してください。';

  @override
  String get pidFormulaInt16Unclaimed =>
      'INT16 はこの方言では定義されていません：wiki には (A*255)+B の代替と書かれていますが、それは (A*256)+B とは異なります。どちらかの計算式を直接記述してください。';

  @override
  String pidFormulaTimeWindowUnsupported(String term) {
    return '$term はこの方言で未実装の遅延、平均、または積算（totalizer）用の Torque 関数であるため、ここでは計算できません。0 ではなく、MIN や MAX でもありません。';
  }

  @override
  String pidFormulaDependencyControllerUnknown(String reference) {
    return 'そのPIDがどのコントローラーに属しているか判別できないため、ここでは $reference を解決できません。';
  }

  @override
  String pidFormulaDependencyTwoDefinitions(String key) {
    return '2つの定義がどちらも $key をデコードしているため、値がどちらのものか判別できず、どちらも使用できません。片方を別のモード+PIDに変更してください。注：推定値に必要なPID（010B、010C、010D）は常に読み取られるため、ダッシュボードからメーターを外しても読み取りは停止しません。';
  }

  @override
  String pidFormulaDependencyNotYetMeasured(String key) {
    return '$key の有効な値がまだ読み取られていません。';
  }

  @override
  String get pidFormulaUnidentified => 'この計算式は計算できず、エディターでこれ以上具体的な理由を特定できません。';

  @override
  String get pidRejectionMalformedModeAndPid =>
      '有効なモード+PIDではありません：16進数文字のみで、2桁（バイト単位）のペアで入力してください。';

  @override
  String pidRejectionServiceNotReadOnly(String service, String services) {
    return 'サービス $service は読み取り専用クエリではないため、車両へ繰り返し送信することはできません。許可されているのは $services（現在値、フリーズフレーム、車両情報、および ReadDataByIdentifier）のみです。';
  }

  @override
  String get pidRejectionFreezeFrameNeedsFrame =>
      'フリーズフレームのクエリにはPIDとフレーム番号の2バイトが必要です（例：020500 は PID 05、フレーム 0）。';

  @override
  String get pidRejectionIdentifierNeedsTwoBytes =>
      'ReadDataByIdentifier には2バイトの識別子が必要です（例：221101）。';

  @override
  String pidRejectionIdentifierWrongLength(String service, int bytes) {
    return 'サービス $service のクエリには $bytes バイトの識別子が必要です。';
  }

  @override
  String get pidRejectionNameRequired => '名前を入力してください。';

  @override
  String pidRejectionInvalidHeader(String text) {
    return '「$text」は有効なヘッダーではありません（11-bit CAN は3桁、旧プロトコルは6桁、29-bit CAN は8桁です）。';
  }

  @override
  String get pidRejectionBoundsRequired => 'メーター範囲の上限と下限の両方を入力してください。';

  @override
  String pidRejectionMinNotANumber(String text) {
    return 'メーター範囲の下限「$text」は有効な数値ではありません。';
  }

  @override
  String pidRejectionMaxNotANumber(String text) {
    return 'メーター範囲の上限「$text」は有効な数値ではありません。';
  }

  @override
  String get pidRejectionMinNotFinite => 'メーター範囲の下限は有限の数値である必要があります。';

  @override
  String get pidRejectionMaxNotFinite => 'メーター範囲の上限は有限の数値である必要があります。';

  @override
  String pidRejectionRedlineNotANumber(String text) {
    return 'レッドゾーン開始値「$text」は有効な数値ではありません。';
  }

  @override
  String get pidRejectionRedlineNotFinite => 'レッドゾーン開始値は有限の数値である必要があります。';

  @override
  String get pidRejectionMaxNotAboveMin => 'メーター範囲の上限は下限より大きい値にする必要があります。';

  @override
  String pidImportMalformedCsv(String detail) {
    return 'このファイルをCSVとして読み取れませんでした：$detail';
  }

  @override
  String get pidImportNoRows => 'ファイルにデータ行がありません。';

  @override
  String pidImportDuplicateHeaderColumns(String columns) {
    return 'ヘッダー行に同じ列名が重複しています：$columns。どちらの列を使用すべきか判別できないため、先にファイルを修正してください。';
  }

  @override
  String pidImportMissingRequiredColumns(String columns, String required) {
    return 'ヘッダー行に必須の列が不足しています：$columns。$required がすべて必要です。';
  }

  @override
  String pidImportRowTooFewColumns(int line) {
    return '$line行目：セルが不足しています。名前、短縮名、PID、計算式が最低限必要です。';
  }

  @override
  String pidImportRowInvalidModeAndPid(int line, String text) {
    return '$line行目：「$text」は有効なモード+PIDではありません（16進数文字のみで、バイト単位のペアである必要があります）。';
  }

  @override
  String pidImportRowEmptyEquation(int line) {
    return '$line行目：計算式のセルが空です。';
  }

  @override
  String pidImportRowRejected(int line, String reason) {
    return '$line行目：$reason';
  }

  @override
  String pidImportRowRangeDefaulted(int line, double min, double max) {
    return '$line行目：メーター範囲が空欄だったため、デフォルトの $min–$max が適用されました。この目盛りがこのセンサーに適しているか確認してください。';
  }

  @override
  String get pidImportNothingImportable =>
      'ファイルに行は含まれていますが、PID定義として読み取れる行が1つもありません。';

  @override
  String get dtcCategoryNoAnswer => 'このカテゴリからは応答がありませんでした。もう一度スキャンしてください。';

  @override
  String get dtcCategoryError => 'このカテゴリを読み取れませんでした。エラーの詳細は通信記録に保存されています。';

  @override
  String get dtcCategoryDisconnected => 'このカテゴリの読み取り中に接続が切断されました。';

  @override
  String get dtcCategoryPending =>
      'コントローラーが要求を受け取り、まだ処理中です。少し待ってからもう一度スキャンしてください。これは拒否ではありません。';

  @override
  String get dtcCategoryUnattributed =>
      '故障コードが返されましたが、応答ヘッダーがオフになっていたため、どのコントローラーが応答したか不明です。異常なしではなく、部分的な結果として扱ってください。';

  @override
  String dtcCategorySilentControllers(int count, String controllers) {
    return '$count 個のコントローラー（$controllers）がこのクエリに応答しませんでした。返ってきた応答は有効ですが、これを車両全体の結果とすることはできません。';
  }

  @override
  String dtcCategoryUnresolvedSources(int count, String addresses) {
    return '$count 件の応答（$addresses）について送信元のコントローラーを特定できませんでした。読み取られたコード自体は有効ですが、これを車両全体の結果とすることはできません。もう一度スキャンしてください。';
  }

  @override
  String dtcCategoryPendingControllers(int count, int answered) {
    return '$count 個のコントローラーがまだこの要求を処理中です（$answered 個は応答済み）。結果は不完全です。少し待ってからもう一度スキャンしてください。';
  }

  @override
  String dtcCategoryRefusedControllers(int refused, int answered) {
    return '$refused 個のコントローラーが応答を拒否しました（$answered 個は応答済み）。今回のスキャンは車両全体を網羅できていません。';
  }

  @override
  String dtcCategoryUnrecognisedResponses(int count, int answered) {
    return '$count 件の応答を読み取れませんでした（$answered 個は応答済み）。残りの結果は有効ですが、今回のスキャンは不完全です。';
  }

  @override
  String dtcCategoryMilCountMismatch(
    String controller,
    int claimed,
    int observed,
  ) {
    return '$controller は確定した故障コードが $claimed 件あると報告しましたが、今回のスキャンでは $observed 件しか読み取れませんでした。車両のメーターパネルの警告灯を優先し、整備工場にご相談ください。';
  }

  @override
  String dtcCategoryMilLitNoCodes(String controller) {
    return '$controller は故障警告灯が点灯していると報告しましたが、そのモジュールに属する故障コードは1件も読み取れませんでした。車両のメーターパネルの警告灯を優先し、整備工場にご相談ください。';
  }

  @override
  String dtcCategoryMilDisagreement(String controllers) {
    return '車両側が報告するステータスと読み取られた故障コードが一致しません（$controllers）。車両のメーターパネルの警告灯を優先し、整備工場にご相談ください。';
  }

  @override
  String get connectPairedListFailed =>
      'ペアリング済みのBluetooth一覧を読み取れませんでした。Bluetoothがオンになっているか確認してから再試行してください。';

  @override
  String get connectBleScanUnavailable =>
      '現在Bluetoothを使用できません。少し待ってから再検索してください。';

  @override
  String get connectBleScanBluez =>
      '利用可能な BlueZ/D-Bus Bluetooth サービスが見つかりませんでした。bluetooth サービスをインストールして起動してから再試行してください。';

  @override
  String get connectBleScanUnclassified => 'BLE の検索に失敗しました。';

  @override
  String dtcClearNrcConditions(String controller) {
    return '車両の状態が条件を満たしていないため、$controller が消去を拒否しました。多くのコントローラーはエンジン回転中には故障メモリを消去しません。エンジンを停止した状態でイグニッションをONにしてから、もう一度お試しください。';
  }

  @override
  String dtcClearNrcUnsupported(String controller) {
    return '$controller は Mode 04 の消去に対応していません。メーカー純正またはディーラー専用の診断機が必要になる場合があります。';
  }

  @override
  String dtcClearNrcBusy(String controller) {
    return '$controller はビジー状態です。少し待ってから再試行してください。';
  }

  @override
  String dtcClearNrcSecurity(String controller) {
    return '$controller は消去の前にセキュリティアクセスを要求しています。メーカー純正またはディーラー専用の診断機が必要です。';
  }

  @override
  String dtcClearNrcOther(String controller, String code) {
    return '$controller が消去を拒否しました（理由コード $code）。少し待ってから再試行してください。';
  }

  @override
  String dtcClearSilentControllers(int count, String controllers) {
    return '$count 個のコントローラー（$controllers）が消去コマンドに応答しませんでした。応答したコントローラーではコードが消去されましたが、他のコントローラーにはコードが残っている可能性があります。再スキャンしてください。消去コマンドを再送信しないでください。';
  }

  @override
  String dtcClearUnresolvedSources(int count, String addresses) {
    return '今回のスキャンで送信元を特定できない応答が $count 件（$addresses）あったため、消去コマンドがどのコントローラーに届くか判別できません。再スキャンしてください。そのアドレスが再度現れない場合は、再接続してからお試しください。';
  }

  @override
  String dtcClearUnresolvedSourcesDoNotRepeat(int count, String addresses) {
    return '消去の応答に送信元を特定できないデータが $count 件（$addresses）含まれていました。消去コマンドを再送信しないでください。再スキャンしてどのコードが残っているか確認してください。';
  }

  @override
  String dtcClearNrcConditionsDoNotRepeat(String controller) {
    return '車両の状態が条件を満たしていないため、$controller が消去を拒否しました。多くのコントローラーはエンジン回転中には故障メモリを消去しません。エンジンを停止した状態でイグニッションをONにしてから、再スキャンしてどのコードが残っているか確認してください。一括消去コマンドを再送信しないでください。2回目を送ると、すでにコードを消去した可能性のあるコントローラーの排ガスレディネスが再びリセットされるおそれがあります。';
  }

  @override
  String dtcClearNrcUnsupportedDoNotRepeat(String controller) {
    return '$controller は Mode 04 の消去に対応していません。メーカーまたはディーラーの診断機が必要になる場合があります。一括消去コマンドを再送信しないでください。2回目を送ると、すでにコードを消去した可能性のあるコントローラーの排ガスレディネスが再びリセットされるおそれがあります。再スキャンしてどのコードが残っているか確認してください。';
  }

  @override
  String dtcClearNrcBusyDoNotRepeat(String controller) {
    return '$controller はビジー状態です。一括消去コマンドを再送信しないでください。2回目を送ると、すでにコードを消去した可能性のあるコントローラーの排ガスレディネスが再びリセットされるおそれがあります。再スキャンしてどのコードが残っているか確認してください。';
  }

  @override
  String dtcClearNrcSecurityDoNotRepeat(String controller) {
    return '$controller は消去の前にセキュリティアクセスを要求しています。メーカーまたはディーラーの診断機が必要です。一括消去コマンドを再送信しないでください。2回目を送ると、すでにコードを消去した可能性のあるコントローラーの排ガスレディネスが再びリセットされるおそれがあります。';
  }

  @override
  String dtcClearNrcOtherDoNotRepeat(String controller, String code) {
    return '$controller が消去を拒否しました（理由コード $code）。一括消去コマンドを再送信しないでください。2回目を送ると、すでにコードを消去した可能性のあるコントローラーの排ガスレディネスが再びリセットされるおそれがあります。再スキャンしてどのコードが残っているか確認してください。';
  }

  @override
  String get sharePolicyDenied => '現在の接続状態または走行状態ではエクスポートできません。';

  @override
  String get shareSafetyChanged => 'エクスポートの準備中に状態が変化したため、共有画面を開きませんでした。';

  @override
  String get shareSizeLimit => 'エクスポートファイルが 32 MiB の上限を超えています。';

  @override
  String get shareStagingBusy => '前回の共有ファイルがまだ保持期間中です。しばらくしてからもう一度お試しください。';

  @override
  String get shareCleanupRequired => '再起動後に共有ステージング領域のチェックが必要です。';

  @override
  String get shareSpaceUnknown => '共有ファイルに必要な空き容量を確認できませんでした。';

  @override
  String get shareNoSpace => '共有ファイルを準備するためのストレージ空き容量が不足しています。';

  @override
  String get shareHandoffFailed => 'ファイルの準備は完了しましたが、システムの共有シートを開けませんでした。';

  @override
  String get shareStorageFailure => '共有の準備または記録中にストレージエラーが発生しました。';

  @override
  String shareTelemetrySubject(String sessionId) {
    return 'ローカルOBD記録 $sessionId';
  }

  @override
  String shareRawTranscriptSubject(String stamp) {
    return 'Telltale 通信記録 $stamp';
  }

  @override
  String get shareRecoveredTranscriptSubject => 'Telltale 通信記録（前回の接続）';

  @override
  String get sharePidCsvSubject => 'Telltale カスタムPID定義';

  @override
  String get shareTorqueSubsetCsvSubject => 'Torque 互換PID定義';

  @override
  String get shareHumanReportCsvSubject => 'Telltale 人間向けPIDレポート';

  @override
  String get transcriptExportUnidentified => 'エクスポートに失敗しました。';

  @override
  String get handshakeNoteUnexpected =>
      'このステップは予期しないエラーで失敗しました。エラーの詳細は通信記録に保存されています。';

  @override
  String pidFormulaUnsupportedConstruct(String term) {
    return '$term はこの方言で未実装の Torque 関数であるため、ここでは計算できません。';
  }

  @override
  String pidImportRowFormulaRejected(int line, String reason) {
    return '$line行目：$reason';
  }

  @override
  String get telemetryHistoryNeedsForeground => '続行する前に Telltale の画面に戻ってください。';

  @override
  String get telemetrySessionPolicyChanged => '操作中に走行状態または接続状態が変化しました。';

  @override
  String get telemetrySessionInvalidId => 'この記録IDは無効です。';

  @override
  String get telemetrySessionNotFound => 'このローカル記録が見つかりませんでした。';

  @override
  String get telemetrySessionStorageFailed => 'ローカルストレージの操作に失敗しました。';

  @override
  String get telemetrySessionShareFailed => '共有の準備または起動ができませんでした。';

  @override
  String get pidMutationPersistFailed => 'カスタムPID一覧を保存できませんでした。変更は適用されていません。';

  @override
  String get powertrainAuthorizeYearOutOfRange => 'その年式はこのプロファイルに記載された年式範囲外です。';

  @override
  String get connectionLayerTransport => '接続方式';

  @override
  String get connectionLayerProtocol => 'プロトコル';

  @override
  String get connectionLayerEcu => 'ECU 応答';

  @override
  String get connectionLayerEvidence => '証拠種別';

  @override
  String get connectionLayerUnknown => '不明';

  @override
  String get connectionLayerNotObserved => '未観測';

  @override
  String get connectionLayerObserved => '観測済み';

  @override
  String get connectionLayerAnswered => '応答あり';

  @override
  String get connectionLayerSoftware => 'ソフトウェア';

  @override
  String get connectionLayerDemo => '内蔵シミュレーター';

  @override
  String get connectionLayerBle => 'Bluetooth LE';

  @override
  String get connectionLayerClassic => 'Bluetooth Classic';

  @override
  String get connectionLayerWifi => 'Wi-Fi';

  @override
  String connectionLayerRequestedObserved(String requested, String observed) {
    return '要求 $requested、観測 $observed';
  }

  @override
  String get connectionLayerKwpSubtypeUnknown => 'KWP（5-baud と fast の判別不可）';

  @override
  String get connectionFailureOpenSettings => 'システム設定を開いてください。';

  @override
  String get connectionFailureTurnRadioOn => 'Bluetoothをオンにしてください。';

  @override
  String get connectionFailureCheckDistanceOrPower =>
      'アダプターが離れすぎているか、給電されていない可能性があります。これは考えられる原因であり、確定した診断結果ではありません。';

  @override
  String get connectionFailureCheckIgnitionProtocolAdapter =>
      'イグニッション、プロトコル、またはアダプターの対応状況を確認してください。無応答は車両に OBD がないことの証明にはなりません。';

  @override
  String get connectionFailureRetryOrAuto => '再試行するか、プロトコルを Auto に設定してください。';

  @override
  String get connectionFailureKeepInvalidAndExport =>
      'この応答は無効です。無効のまま保持し、限定的な診断データをエクスポートしてください。これは読み取り値ではありません。';

  @override
  String get settingsCatalogMarketCa => 'カナダ（NRCan）';

  @override
  String get settingsCaPickerTitle => 'カナダ公式車両カタログ';

  @override
  String settingsCaPickerScope(int firstYear, int lastYear) {
    return 'カナダ市場の $firstYear–$lastYear 年の燃費表示データのみが対象です。内燃機関、バッテリー式電気自動車、プラグインハイブリッドは個別のクラスとして扱われます。メーカー名と車名の文字列が一致しても、それは EPA または台湾の構成ではありません。';
  }

  @override
  String get settingsCaMotorNotPower => 'モーター出力（kW）はホイール馬力とは異なり、適用されません。';

  @override
  String get settingsCaClassIce => '内燃機関（ICE）';

  @override
  String get settingsCaClassBev => 'バッテリー式電気自動車（BEV）';

  @override
  String get settingsCaClassPhev => 'プラグインハイブリッド（PHEV）';

  @override
  String settingsCaWillApplyOnly(String fields) {
    return '適用されるのは $fields のみです。モーター kW、燃料消費率、航続距離、CO2、VE、Cd、前面投影面積、Crr、および伝達効率は未解決のまま残ります。';
  }

  @override
  String get serviceRecipesTitle => 'サービスレシピとアクティブ診断';

  @override
  String get serviceRecipesSubtitle => '標準規格に基づくサービスレシピおよび非駆動（非アクチュエート）機能探索';

  @override
  String get serviceRecipesSafetyBannerTitle => '実車対象ゼロ（Zero Live Candidates）';

  @override
  String get serviceRecipesSafetyBannerBody =>
      '実車に対する駆動実行（アクチュエーション）は厳格に禁止されています（適格実車数：0）。利用可能なレシピはすべてシミュレーション用のフィクスチャです。';

  @override
  String get serviceRecipesDiscoverySection => 'Mode 08 非駆動（非アクチュエート）機能探索';

  @override
  String get serviceRecipesDiscoveryDescription =>
      'コンポーネントを一切駆動（アクチュエート）せずに、CAN経由で標準のベーステストID（\$00、\$20…）を照会します。';

  @override
  String get serviceRecipesDiscoveryButton => 'Mode 08 対応TIDを探索';

  @override
  String get serviceRecipesDiscovering => '対応TIDを照会中...';

  @override
  String serviceRecipesDiscoverySuccess(String tids) {
    return 'ECU は Mode 08 に対応しています。対応TID：$tids';
  }

  @override
  String get serviceRecipesDiscoveryUnsupported => 'この ECU は Mode 08 に対応していません';

  @override
  String serviceRecipesDiscoveryUnknown(String reason) {
    return 'Mode 08 の対応状態は不明です：$reason';
  }

  @override
  String serviceRecipesDiscoveryPartialWarning(String reason, String blocks) {
    return '探索が一部のみ完了しました（$reason）。未完了ブロック：$blocks。注：検出されなかったことは非対応を意味しません。';
  }

  @override
  String get serviceRecipesCatalogSection => '利用可能なサービスレシピ';

  @override
  String get serviceRecipesSimulationBadge => 'シミュレーション対応';

  @override
  String get serviceRecipesLiveBlockedBadge => '実車ブロック済み（実車対象 0）';

  @override
  String serviceRecipesStandard(String standard) {
    return '準拠規格：$standard';
  }

  @override
  String serviceRecipesEcuHeader(String header) {
    return 'ECU ヘッダー：$header';
  }

  @override
  String serviceRecipesHash(String hash) {
    return '正規ハッシュ：$hash';
  }

  @override
  String get serviceRecipesDetailTitle => 'サービスレシピの詳細';

  @override
  String get serviceRecipesPreconditions => '安全上の前提条件';

  @override
  String get serviceRecipesRecovery => '制御解放／復帰コマンド';

  @override
  String get serviceRecipesClose => '閉じる';

  @override
  String get serviceRecipesDiscoveryRequiresCan => '有効な OBD-II CANバス接続が必要です。';

  @override
  String serviceRecipesLoadError(String error) {
    return 'サービスレシピの読み込みエラー：$error';
  }

  @override
  String get serviceRecipesNoPreconditions => 'なし';

  @override
  String get settingsServiceRecipesEntry => 'サービスレシピとアクティブテスト';

  @override
  String get settingsServiceRecipesDesc =>
      '整備用サービスレシピを確認し、対応する Mode 08 テストを探索します';

  @override
  String get mode08ReasonUnheaderedLimitation =>
      '送信元の特定と網羅範囲は未確認です：ヘッダーなしの応答ではブロックをまたぐ ECU の同一性を確立できません';

  @override
  String mode08ReasonNoResponseWithEcu(
    String block,
    String ecu,
    String marker,
  ) {
    return '$ecu からブロック $block の応答なし：$marker';
  }

  @override
  String mode08ReasonNoResponse(String block, String marker) {
    return 'ブロック $block の応答なし：$marker';
  }

  @override
  String mode08ReasonNegativeWithEcu(String block, String ecu, String nrc) {
    return '$ecu からブロック $block にネガティブレスポンス（NRC $nrc）';
  }

  @override
  String mode08ReasonNegative(String block, String nrc) {
    return 'ブロック $block にネガティブレスポンス（NRC $nrc）';
  }

  @override
  String mode08ReasonMalformedWithEcu(
    String block,
    String ecu,
    String details,
  ) {
    return '$ecu からのブロック $block の応答形式が不正です：$details';
  }

  @override
  String mode08ReasonMalformed(String block, String details) {
    return 'ブロック $block の応答形式が不正です：$details';
  }

  @override
  String mode08ReasonTimeout(String block) {
    return 'ブロック $block のクエリがタイムアウトしました';
  }

  @override
  String get mode08ReasonBudgetExceeded => 'すべてのブロックを照会する前に探索の上限に達しました';

  @override
  String get mode08ReasonSessionDisconnected => '探索中にセッションが切断されたか切り替わりました';

  @override
  String mode08ReasonUnqueriedAnnounced(String blocks) {
    return 'ECU が通知した未照会ブロック：$blocks';
  }

  @override
  String get mode08ReasonRequiresCanBus =>
      'Mode 08 の機能探索には解決済みの OBD-II CANバスが必要です';

  @override
  String get mode08ReasonUnexpectedExecution => '対応TID照会に対して予期しない実行応答が返されました';

  @override
  String get pidDetailEmptyTitle => 'PIDを選択';

  @override
  String get pidDetailEmptyBody => '一覧からPIDを選択して、定義とリアルタイムの状態を確認してください。';

  @override
  String get pidDetailRangeLabel => '範囲';

  @override
  String get pidDetailPriorityLabel => '優先度';

  @override
  String pidDetailHeaderDefault(String header) {
    return 'デフォルト（$header）';
  }

  @override
  String get dtcSystemOverview => 'システム概要';

  @override
  String get dtcPartialObservationBadge => '一部スキャン';

  @override
  String get dtcPartialObservationBody =>
      'この故障コードは読み取られましたが、このカテゴリのスキャンはすべてのコントローラーに対して完了していません。';

  @override
  String get dtcLinkedFreezeFrameTitle => '関連するフリーズフレーム';

  @override
  String get dtcNoLinkedFreezeFrame =>
      '今回のスキャンには、この故障コードとコントローラーに安全に関連付けられるフリーズフレームがありません。';

  @override
  String get performanceGuideTitle => '加速テストの手順';

  @override
  String get performanceGuideStep1 => '1. 目標車速を選択し、タイマーをセットします';

  @override
  String get performanceGuideStep2 => '2. 車両を完全に停止させ、準備完了になるまで待ちます';

  @override
  String get performanceGuideStep3 => '3. 加速を開始します（動きを検知すると自動的に計測が始まります）';

  @override
  String get performanceGuideStep4 => '4. 目標車速に到達すると計測完了です';

  @override
  String get performanceRecordingTrace => '加速中... 車速トレースを記録しています';

  @override
  String get performanceNoAnalysisTitle => '分析データなし';

  @override
  String get performanceNoAnalysisBody =>
      '車速トレースやスプリット結果を作成するのに十分な車速サンプルが記録される前に計測が停止しました。';

  @override
  String get connectActivityReconnectingAutomatically =>
      'アダプターの応答が停止しました。自動的に再接続しています…';
}
