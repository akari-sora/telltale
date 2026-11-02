// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get adapterErrorActivityAlert => '버스 활동 경고가 발생했습니다.';

  @override
  String get adapterErrorBufferFull => '어댑터 버퍼가 오버플로되었습니다.';

  @override
  String get adapterErrorBus => '버스 오류입니다. 배선 문제일 수 있습니다.';

  @override
  String get adapterErrorBusBusy => '버스가 사용 중입니다.';

  @override
  String get adapterErrorBusInit => '버스 초기화에 실패했습니다.';

  @override
  String get adapterErrorCan => 'CAN 버스 오류입니다.';

  @override
  String get adapterErrorData => '수신된 데이터가 올바르지 않습니다.';

  @override
  String get adapterErrorFeedback => '신호 피드백 오류입니다.';

  @override
  String get adapterErrorInternal => '어댑터 내부 오류입니다.';

  @override
  String get adapterErrorLowPowerAlert => '어댑터가 곧 저전력 모드로 전환됩니다.';

  @override
  String get adapterErrorLowVoltageReset => '저전압으로 인해 어댑터가 리셋되었습니다.';

  @override
  String get adapterErrorNoData =>
      '응답이 도착하지 않았습니다 — 일시적인 무응답이거나 차량이 이 항목을 지원하지 않을 수 있습니다.';

  @override
  String get adapterErrorStopped => '전송이 중단되었습니다.';

  @override
  String get adapterErrorUnableToConnect =>
      'ECU와 통신할 수 없습니다. 시동 스위치(IG)가 켜져 있는지 확인하십시오.';

  @override
  String get adapterErrorUnknownCommand => '어댑터가 이 명령을 지원하지 않습니다.';

  @override
  String get appTagline => '실시간 차량 텔레메트리';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => '화면 스타일';

  @override
  String get connectActivityAbortingPreviousConnection =>
      '이전 연결을 중단하는 중입니다. 잠시만 기다려 주십시오…';

  @override
  String get connectAnswerBleWithClassic =>
      'Bluetooth LE를 선택하십시오. 사전 페어링이 필요하지 않으며 앱 안에서 직접 스캔하면 됩니다. 시스템 블루투스 페어링 목록에 나타나더라도 거기서 페어링하지 마십시오 — 그 경로로는 작동하지 않습니다. 스캔해도 아무것도 나오지 않는다면 박스에 적힌 4.0은 칩 사양일 뿐이므로 대신 Bluetooth Classic을 사용하십시오.';

  @override
  String get connectAnswerBleWithoutClassic =>
      'Bluetooth LE를 선택하십시오. 사전 페어링이 필요하지 않으며 앱 안에서 직접 스캔하면 됩니다. 시스템 블루투스 페어링 목록에 나타나더라도 거기서 페어링하지 마십시오 — 그 경로로는 작동하지 않습니다. 스캔해도 아무것도 나오지 않는다면 어댑터에 전원이 들어왔는지 확인하거나 대신 Wi-Fi를 시도해 보십시오(이 호스트에서는 Bluetooth Classic을 제공하지 않습니다).';

  @override
  String get connectAnswerClassic =>
      'Bluetooth Classic을 선택하십시오. 먼저 시스템 설정에서 페어링을 완료해야 하며, 앱이 대신 페어링해 줄 수 없습니다. 핀 번호는 보통 1234 또는 0000입니다.';

  @override
  String get connectAnswerWifiDesktop =>
      'Wi-Fi를 선택하십시오. 먼저 이 기기를 해당 네트워크에 연결한 뒤 돌아와서 주소를 입력하십시오.';

  @override
  String get connectAnswerWifiPhone =>
      'Wi-Fi를 선택하십시오. 먼저 휴대폰을 해당 네트워크에 연결한 뒤 돌아와서 주소를 입력하십시오.';

  @override
  String get connectBleBody =>
      'BLE 어댑터는 사전 페어링이 필요하지 않습니다. 검색 후 기기를 선택하십시오 — 흔한 이름은 OBDII, V-LINK, Vgate 또는 IOS-Vlink입니다.';

  @override
  String connectBleEmptyScan(String next) {
    return '검색이 끝났지만 BLE 어댑터를 찾지 못했습니다. 순서대로 확인하십시오: 먼저 어댑터의 표시등이 켜져 있는지 보십시오(대부분의 OBD 단자는 시동 스위치를 ON으로 돌려야 전원이 공급됩니다). 다음은 거리이므로 차 안에 앉아서 검색하십시오. $next BLE 어댑터는 시스템 설정에서 페어링할 필요가 없으며 페어링해서도 안 됩니다 — 그 경로로는 작동하지 않습니다.';
  }

  @override
  String get connectBleEmptyScanNextClassic =>
      '마지막으로 박스의 사양을 확인하십시오: 2.0 또는 3.0이라고 적혀 있다면 Bluetooth Classic이므로 이 목록에는 절대 나타나지 않습니다. 위쪽의 Bluetooth Classic을 대신 사용하십시오.';

  @override
  String get connectBleEmptyScanNextWifi =>
      '마지막으로 박스의 사양을 확인하십시오: 2.0/3.0이거나 Wi-Fi 전용이라고 적혀 있다면 대신 Wi-Fi를 시도해 보십시오(이 호스트에서는 Bluetooth Classic을 제공하지 않습니다).';

  @override
  String get connectBlePermissionDeniedForever =>
      '블루투스 권한이 영구적으로 거부되었습니다. 시스템이 다시 권한을 묻지 않으므로 앱 설정에서 직접 켜 주십시오.';

  @override
  String get connectBlePermissionNeeded => '검색하려면 블루투스 권한이 필요합니다.';

  @override
  String get connectBleScan => 'BLE 기기 검색';

  @override
  String get connectBleScanning => '검색 중…';

  @override
  String get connectBleUnavailableHost =>
      '이 호스트에서는 아직 Bluetooth LE를 사용할 수 없습니다';

  @override
  String get connectBluetoothOff => '블루투스가 꺼져 있습니다. 먼저 시스템 설정에서 블루투스를 켜 주십시오.';

  @override
  String get connectBluetoothPermissionDeniedForever =>
      '블루투스 권한이 영구적으로 거부되었습니다. 시스템 설정에서 권한을 켠 뒤 다시 시도하십시오.';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      '페어링된 어댑터 목록을 보려면 블루투스 권한이 필요합니다.';

  @override
  String get connectBody => 'ELM327 어댑터를 꽂고 시동 스위치를 켜거나, 내장 시뮬레이터를 사용하십시오.';

  @override
  String get connectCancel => '취소';

  @override
  String get connectClassicEmptyLinuxPort =>
      '블루투스 직렬 포트(/dev/rfcomm*)를 찾을 수 없습니다. 먼저 BlueZ로 ELM327을 페어링한 다음 rfcomm bind(또는 이에 상응하는 명령)로 RFCOMM TTY를 생성한 후 다시 시도하십시오.';

  @override
  String get connectClassicEmptyPaired =>
      '페어링된 어댑터를 찾을 수 없습니다. 먼저 시스템 블루투스 설정에서 페어링하십시오(대부분의 ELM327 핀 번호는 1234 또는 0000입니다).';

  @override
  String get connectClassicEmptyWindowsPort =>
      '블루투스 직렬 포트(COMx)를 찾을 수 없습니다. 먼저 Windows 블루투스 설정에서 ELM327을 페어링하고, 장치 관리자에 “Standard Serial over Bluetooth link”가 표시되는지 확인하십시오.';

  @override
  String get connectClassicListLinuxPort =>
      '여기에 BlueZ가 바인딩한 블루투스 직렬 포트(/dev/rfcomm* 등)가 표시됩니다. 목록이 비어 있다는 것은 시스템이 아직 RFCOMM 노드를 생성하지 않았다는 뜻이지 앱이 고장 난 것이 아닙니다.';

  @override
  String get connectClassicListPaired =>
      '시스템에 페어링된 모든 기기가 표시됩니다 — 이어폰과 스피커도 포함되며, 어댑터로 보이는 기기가 앞에 정렬됩니다. 잘못 골랐다면 실패할 때까지 기다리지 말고 취소를 누르십시오. 곧바로 다른 기기를 선택할 수 있습니다.';

  @override
  String get connectClassicListWindowsPort =>
      '블루투스와 연결된 COM 포트(“Standard Serial over Bluetooth link”)가 표시됩니다. 목록이 비어 있다는 것은 시스템이 아직 가상 직렬 포트를 생성하지 않았다는 뜻이지 앱이 고장 난 것이 아닙니다.';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic (SPP)은 현재 Android, macOS (IOBluetooth RFCOMM), Windows (COM) 및 Linux (/dev/rfcomm*)에서 사용할 수 있습니다';

  @override
  String get connectClassicUnavailableIos => 'iOS는 서드파티 앱에 블루투스 SPP를 개방하지 않습니다';

  @override
  String get connectConnect => '연결';

  @override
  String get connectDemoBody =>
      '아이들링, 가속, 정속 주행, 감속 사이클을 거치는 2.0 L 터보차저 4기통 엔진을 시뮬레이션하며, 각 신호는 물리적 상관관계를 유지합니다(변속 시 엔진 회전수는 떨어지지만 차속은 계속 상승). 고장 코드, VIN 판독, fastMode 일괄 쿼리가 모두 온전히 작동합니다.';

  @override
  String get connectDemoStart => '시뮬레이터 시작';

  @override
  String get connectHandshakeTitle => 'ELM327 초기화';

  @override
  String get connectHandshakeTitleLastAttempt => 'ELM327 초기화 (지난 시도)';

  @override
  String get connectHeadline => '연결 방식 선택';

  @override
  String get connectIssueAdapterAcceptedThenSilent =>
      '어댑터가 연결은 수락했지만 제한 시간 내에 아무 응답도 하지 않았습니다. 대개 아직 전원이 들어오지 않은 상태이거나(대부분의 OBD 단자는 시동 스위치가 ON이어야 전원이 공급됨) 다른 앱이 이미 어댑터에 연결되어 있습니다. 다른 앱이 연결된 경우 해당 앱을 닫고 다시 시도하십시오.';

  @override
  String connectIssueAdapterSilentOnReset(String command) {
    return '어댑터가 리셋 명령($command)에 응답하지 않았습니다. 이 기기가 ELM327 어댑터가 아니거나, 잘못된 기기에 연결되었을 수 있습니다.';
  }

  @override
  String get connectIssueAdapterStoppedResponding =>
      '어댑터의 응답이 중단되어 연결이 끊어졌습니다.';

  @override
  String get connectIssueConnectionSetupFailed =>
      '연결을 수립하는 도중 실패했습니다. 어댑터에 전원이 들어와 있고 가까이에 있는지 확인한 뒤 다시 시도하십시오. 전체 오류 내용은 아래 로그에 보관되어 있습니다.';

  @override
  String get connectIssueHandshakeIncomplete =>
      '초기화를 통과하지 못했습니다. 어댑터가 호환되지 않을 수 있습니다.';

  @override
  String connectIssueHandshakeStepFailed(String command, String reason) {
    return '$command 단계에서 초기화에 실패했습니다($reason). 어댑터가 단단히 꽂혀 있고 차량 시동 스위치가 켜져 있는지 확인하십시오.';
  }

  @override
  String get connectIssuePreviousConnectionStillAborting =>
      '이전 연결을 아직 중단하는 중이어서 어댑터가 해제되지 않았습니다. 몇 초 기다린 뒤 다시 시도하십시오.';

  @override
  String get connectLastAdapterConnect => '지금 연결';

  @override
  String get connectLastAdapterForget => '삭제';

  @override
  String get connectLastAdapterTitle => '마지막으로 사용한 어댑터';

  @override
  String get connectOpenAppSettings => '앱 설정 열기';

  @override
  String get connectOpenSystemSettings => '시스템 설정 열기';

  @override
  String get connectOpeningConnection => '연결 여는 중…';

  @override
  String get connectPairedPill => '페어링됨';

  @override
  String get connectQuestionBle =>
      '박스, 판매 페이지 또는 기기 이름에 BLE, 4.0 또는 5.0이라고 적혀 있습니까?';

  @override
  String get connectQuestionClassic =>
      '둘 다 아님 — 구형 모델이며 박스에 2.0 또는 3.0이라고 인쇄되어 있습니까?';

  @override
  String get connectQuestionWifiDesktop =>
      '시스템의 Wi-Fi 목록에 새로운 네트워크(예: V-LINK 또는 WiFi_OBDII)가 나타납니까?';

  @override
  String get connectQuestionWifiPhone =>
      '휴대폰의 Wi-Fi 목록에 새로운 네트워크(예: V-LINK 또는 WiFi_OBDII)가 나타납니까?';

  @override
  String get connectSearchAgain => '다시 검색';

  @override
  String connectSignalStrength(int bars, int total) {
    return '신호 강도 $bars/$total';
  }

  @override
  String get connectTranscriptKept =>
      '이번 시도의 전체 진단 통신 기록이 보관되었습니다. 한 줄짜리 메시지보다 이 기록을 가져오시는 편이 훨씬 도움이 됩니다.';

  @override
  String get connectTransportBleDescription => 'GATT UART — 신형 저전력 어댑터';

  @override
  String get connectTransportBleTitle => 'Bluetooth LE';

  @override
  String get connectTransportClassicDescription =>
      'RFCOMM / SPP — 가장 흔한 보급형 ELM327';

  @override
  String get connectTransportClassicTitle => 'Bluetooth Classic';

  @override
  String get connectTransportDemoDescription =>
      '내장 시뮬레이션 ECU — 하드웨어 없이 앱 전체 기능 체험';

  @override
  String get connectTransportDemoTitle => '데모 시뮬레이터';

  @override
  String get connectTransportWifiDescription => 'TCP 포트, 보통 192.168.0.10:35000';

  @override
  String get connectTransportWifiTitle => 'Wi-Fi';

  @override
  String get connectWhichIntro =>
      'SPP나 GATT 같은 용어는 신경 쓰지 마십시오. 어댑터를 꽂았을 때 어떻게 동작하는지만 보십시오:';

  @override
  String get connectWhichNoteGuessing =>
      '잘못 골라도 아무 문제 없습니다 — 연결되지 않으면 돌아와서 다른 방식을 시험해 보십시오. 정말 막히면 맨 아래의 「데모 시뮬레이터」로 앱 자체가 정상 작동하는지 먼저 확인하십시오.';

  @override
  String get connectWhichNoteIos =>
      'iPhone은 Wi-Fi 또는 BLE만 사용할 수 있습니다 — 일반 블루투스 ELM327은 iOS에서 전혀 작동하지 않습니다. 이는 OS 제한이므로 다른 앱을 써도 마찬가지입니다.';

  @override
  String get connectWhichTitle => '어느 것을 골라야 할지 모르겠나요?';

  @override
  String get connectWifiHostLabel => 'IP 주소';

  @override
  String get connectWifiHostRequired => '어댑터의 IP 주소를 입력하십시오.';

  @override
  String get connectWifiInstructionsDesktop =>
      '먼저 이 컴퓨터를 어댑터가 송출하는 Wi-Fi 핫스팟에 연결한 뒤 주소를 입력하십시오. 인터넷에 연결할 수 없는 네트워크라는 경고가 뜨면 연결 유지를 선택하십시오. 데스크톱 시스템은 대개 핫스팟을 기본 경로로 처리하므로 Android와 같은 별도의 Wi-Fi 경로 바인딩이 필요하지 않습니다.';

  @override
  String get connectWifiInstructionsPhone =>
      '먼저 휴대폰에서 어댑터가 송출하는 Wi-Fi 핫스팟에 연결한 뒤 주소를 입력하십시오. 인터넷에 연결할 수 없는 Wi-Fi 네트워크를 계속 사용할지 시스템이 물으면 연결 유지를 선택하십시오. Android에서는 연결 중에 트래픽이 모바일 데이터로 넘어가지 않도록 Telltale이 Wi-Fi 경로에 고정하려고 시도합니다.';

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '“$value”은(는) 유효한 포트가 아닙니다. 허용 범위는 $min–$max입니다.';
  }

  @override
  String get connectWifiPortLabel => '포트';

  @override
  String connectWifiPortRequired(int port) {
    return '포트를 입력하십시오(대부분의 어댑터는 $port 사용).';
  }

  @override
  String get dashboardBatchedPolling => '일괄 폴링됨';

  @override
  String get dashboardBatchingEnabled => '일괄 요청 허용됨';

  @override
  String get dashboardChoosePids => 'PID 선택';

  @override
  String get dashboardEmptyBody => 'PID 페이지에서 모니터링할 신호를 선택하면 여기에 표시됩니다.';

  @override
  String get dashboardEmptyTitle => '대시보드가 비어 있습니다';

  @override
  String get dashboardGenericObd => '범용 OBD';

  @override
  String get dashboardLocalRecordings => '로컬 기록';

  @override
  String get dashboardNotConnected => '연결 안 됨';

  @override
  String get dashboardPollingModeHelpAction => '폴링 모드 안내';

  @override
  String get dashboardPollingModeHelpBatching =>
      '「일괄 요청 허용됨」은 왕복 횟수를 줄이기 위해 Telltale이 여러 PID 요청을 한 번의 교환으로 묶을 수 있음을 뜻합니다. 즉, 일괄 시도가 허용되어 있고 비활성화되지 않은 상태입니다. 다만 이는 측정 결과가 아니라 허용 상태를 뜻하는데, 실제 교환에서 묶여서 전송되었는지는 차량이 어떤 PID 지원을 확인해 주었는지와 대기 중인 요청 수에 따라 달라지기 때문입니다.';

  @override
  String get dashboardPollingModeHelpObserved =>
      '「일괄 폴링됨」은 이번 연결에서 실제로 두 개 이상의 PID를 담은 Mode 01 명령이 전송되었음을 뜻합니다. 이는 해당 교환에 대한 기록일 뿐 다음 요청도 묶인다는 보장이 아니며, 처리량에 대한 주장도 아닙니다.';

  @override
  String get dashboardPollingModeHelpRate =>
      'PIDs/s는 지난 1초 동안 관측된 속도일 뿐 지연 시간, 최신성 또는 정확도에 대한 보장이 아닙니다. 어댑터, 버스, ECU, 선택한 PID, 응답 크기 및 오류 여부에 따라 계속 변합니다.';

  @override
  String get dashboardPollingModeHelpSingle =>
      '「단일 요청 모드」는 각 Mode 01 PID를 개별적으로 읽어옴을 뜻합니다. Telltale은 세 가지 경우에 이 모드를 사용합니다: 버스가 일괄 요청을 아예 받지 않는 경우(모든 비-CAN 차량); 아직 응답한 지원 블록이 없는 경우(차량이 확인해 주지 않은 PID를 묶어서 요청하면 응답이 잘려서 돌아오는 원인이 됨); 그리고 묶어서 보낸 요청이 다시 각 PID로 분리할 수 있는 형태로 돌아오지 않은 경우(응답이 잘렸거나, 어댑터가 버퍼 가득 참을 보고하며 거부했거나, 응답이 없었을 때). 판독값은 계속 갱신되며, 이것만으로는 연결 실패를 뜻하지 않습니다.';

  @override
  String get dashboardPollingModeHelpTitle => '폴링 모드';

  @override
  String get dashboardSingleRequestMode => '단일 요청 모드';

  @override
  String get dashboardVinRead => 'VIN 판독됨';

  @override
  String get dashboardWorkspaceGauges => '게이지';

  @override
  String get dashboardWorkspaceTrends => '트렌드';

  @override
  String get datumBadgeCommunityDecode => '커뮤니티 디코드';

  @override
  String get datumBadgeDemo => '시뮬레이션';

  @override
  String get datumBadgeEstimated => '추정';

  @override
  String get datumBadgeExperimental => '실험적';

  @override
  String get datumBadgeFieldVerified => '실차 검증됨';

  @override
  String get datumBadgeInvalid => '무효';

  @override
  String get datumBadgeJustUpdated => '방금 갱신됨';

  @override
  String get datumBadgeOutOfReferenceRange => '범위 벗어남';

  @override
  String get datumBadgePartial => '부분';

  @override
  String get datumBadgeStale => '오래됨';

  @override
  String get datumBadgeTentativeDecode => '잠정 디코드';

  @override
  String get datumBadgeUnverified => '미검증';

  @override
  String get datumBadgeUnverifiedOnThisVehicle => '이 차량에서 미검증';

  @override
  String get datumBadgeUserSupplied => '사용자 제공';

  @override
  String get datumGapModelYearUnknown => '연식 알 수 없음';

  @override
  String get datumGapNoCatalogMatch => '카탈로그 일치 항목 없음';

  @override
  String get datumGapVinNotRead => 'VIN 미판독';

  @override
  String get datumNextStepEstimateOnly => '이 추정값에만 영향을 미치며 다른 판독값은 계속 유효합니다.';

  @override
  String get datumNextStepGenericObd =>
      '범용 OBD를 계속 사용하거나, 직접 차량을 선택하고 파라미터를 입력할 수 있습니다.';

  @override
  String get datumNextStepOtherReadings =>
      '실패는 이 항목에만 영향을 미치며 다른 판독값은 계속 유효합니다.';

  @override
  String get datumNextStepRawOnly =>
      '원본 응답과 오류는 확인할 수 있으나, 둘 다 정상 값으로 간주해서는 안 됩니다.';

  @override
  String get datumReasonAssumptionsUnconfirmed =>
      '가정이 아직 확인되지 않았으나 추정값은 계속 표시됩니다.';

  @override
  String get datumReasonBusError => '버스 오류입니다.';

  @override
  String get datumReasonFormulaError => '공식 오류입니다.';

  @override
  String get datumReasonFuelEstimateMissingInputs =>
      '연료 소모량 추정에 필요한 필수 입력값이 누락되었습니다.';

  @override
  String get datumReasonHeaderNotOnThisBus => '헤더가 이 차량이 사용하는 버스와 일치하지 않습니다.';

  @override
  String get datumReasonHorsepowerEstimateMissingInputs =>
      '마력 추정에 필요한 필수 입력값이 누락되었습니다.';

  @override
  String get datumReasonMalformedPacket => '손상된 패킷입니다. 원본 응답만 확인할 수 있습니다.';

  @override
  String get datumReasonNoAnswer => '응답 없음 — 앱이 약 1분 후에 자동으로 다시 시도합니다.';

  @override
  String get datumReasonNoReadingYet => '아직 판독값이 없습니다.';

  @override
  String get datumReasonNonFiniteValue => '유한한 숫자가 아닙니다.';

  @override
  String get datumReasonOutOfReferenceRangeKept =>
      '일반적인 기준 범위를 벗어났으나 읽힌 그대로 유지되었습니다.';

  @override
  String get datumReasonPidUnsupported => '이 차량은 이 PID를 지원하지 않습니다.';

  @override
  String get datumReasonUnsafeService => '이 서비스는 읽기 전용 쿼리가 아닙니다.';

  @override
  String get datumReasonUnsafeServiceStopped =>
      '이 서비스는 읽기 전용 쿼리가 아니므로 전송하지 않았습니다.';

  @override
  String get datumStatusAssumptions => '가정';

  @override
  String get datumStatusClose => '닫기';

  @override
  String get datumStatusFollowsData => '상태는 데이터를 따름';

  @override
  String get datumStatusDetailsHint => '탭하여 판독값 상태 상세 보기';

  @override
  String get datumStatusUnverifiedExplanation =>
      '미검증은 이 차량에서 해당 디코더를 실제 차량과 대조한 검증 기록이 여기에 문서화되어 있지 않음을 뜻합니다. 판독값이 틀렸다는 뜻도 아니고 정확성을 보증한다는 뜻도 아닙니다. 최신성 및 오류 상태는 별도로 표시됩니다.';

  @override
  String get datumStatusFormula => '공식';

  @override
  String get derivedAirflow => '공기 유량';

  @override
  String get derivedEcuFuelTitle => 'ECU 연료 소모 데이터';

  @override
  String get derivedEcuReported => 'ECU 보고값';

  @override
  String get derivedEngineHorsepower => '엔진 마력';

  @override
  String get derivedEstimatedFuelTitle => '추정 연료 소모량';

  @override
  String get derivedEstimatesDetailsTitle => '추정 공식 및 가정';

  @override
  String get derivedEstimatesTitle => '추정값';

  @override
  String get derivedFuelUse => '연료 소모량';

  @override
  String get derivedTorque => '토크';

  @override
  String get derivedUnavailableMessage =>
      '차량 속도와 가속도 데이터가 도착해야만 마력을 추정할 수 있습니다';

  @override
  String dtcBothSilentDetail(Object mode) {
    return '차량이 Mode $mode 쿼리에 응답하지 않았고 Mode 03 역시 응답하지 않았습니다 — 따라서 차량이 기능을 지원하지 않는 것인지, 이번 연결에서 단순히 읽지 못한 것인지 판단할 수 없습니다.';
  }

  @override
  String dtcCategoryFault(Object category) {
    return '$category 관련 고장';
  }

  @override
  String get dtcClear => '삭제';

  @override
  String get dtcClearCancel => '취소';

  @override
  String get dtcClearConfirm => '코드 삭제';

  @override
  String get dtcClearDialogBody =>
      '이 작업은 저장됨 및 보류 중 고장 코드를 지우고 고장 표시등을 끄며, 동시에 배출가스 준비 상태를 초기화합니다 — 정기 검사를 통과하려면 차량이 자기진단 주기를 처음부터 다시 완료해야 합니다. 영구 고장 코드(Mode 0A)는 삭제할 수 없습니다.';

  @override
  String get dtcClearDialogFrameUnread =>
      '이번 스캔에서 프리즈 프레임을 읽지 못했습니다 — 차량에 프리즈 프레임이 없다는 뜻은 아닙니다. 먼저 다시 스캔한 뒤 삭제 여부를 결정하십시오.';

  @override
  String dtcClearDialogFrames(Object codes) {
    return '$codes의 프리즈 프레임 — 고장이 발생한 순간의 엔진 회전수, 냉각수 온도, 부하를 담은 전체 기록 — 도 함께 삭제되며, 고장이 다시 발생하기 전까지는 다시 읽어올 수 없습니다.';
  }

  @override
  String get dtcClearDialogTitle => '고장 코드를 삭제하시겠습니까?';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이번 스캔에서 $count개 범주가 완전히 응답하지 않았습니다',
    );
    return '$_temp0($categories). 따라서 아직 확인하지 못한 고장 코드가 남아 있을 수 있습니다. 삭제한 뒤에는 다시 읽어올 수 없습니다.';
  }

  @override
  String get dtcClearCancelledBeforeSend =>
      '앱에서 명령을 전송하기 전에 삭제가 취소되었습니다. 여전히 삭제하려면 다시 스캔한 뒤 시도하십시오.';

  @override
  String get dtcClearConfirmed => '삭제 명령을 전송했습니다.';

  @override
  String get dtcClearFailureDoNotRepeat =>
      '삭제 명령이 이미 차량에 전달되었을 수 있습니다. 다시 보내지 마십시오 — 전체 삭제 명령을 한 번 더 보내면 이미 삭제를 마쳤을 수 있는 제어기의 배출가스 준비 상태가 다시 초기화될 수 있습니다. 무엇이 남았는지 확인하려면 다시 스캔하십시오.';

  @override
  String get dtcClearFailureGeneric =>
      '삭제가 완료되지 않았습니다. 다시 시도할지 결정하기 전에 먼저 다시 스캔하여 현재 고장 코드를 확인하십시오.';

  @override
  String get dtcClearNotAccepted =>
      '삭제에 실패했습니다. 명령을 수락한 제어기가 없습니다. 다시 시도할 수 있습니다.';

  @override
  String get dtcClearPartiallyConfirmed =>
      '최소 한 제어기가 삭제 완료를 보고했으나 나머지 제어기는 확인할 수 없었습니다. 삭제 명령을 다시 보내지 마십시오 — 반복 전송하면 이미 완료된 제어기의 배출가스 준비 상태가 다시 초기화됩니다. 결과를 확인하려면 다시 스캔하십시오.';

  @override
  String get dtcClearPreviousConnectionUnconfirmed =>
      '이전 연결에서 삭제 명령을 보냈으나 결과가 확인되지 않았습니다. 먼저 다시 스캔하여 남아 있는 고장 코드를 확인한 뒤 삭제 여부를 결정하십시오.';

  @override
  String get dtcClearRescanSettled =>
      '이전 삭제 결과를 완전히 확인할 수 없었습니다. 아래는 이번 재스캔 이후의 실제 상태입니다.';

  @override
  String get dtcClearSentUnconfirmed =>
      '삭제 명령을 보냈으나 전송 도중 응답이 손상되어 차량에서 삭제되었는지 알 수 없습니다. 다시 스캔하여 확인하십시오. 다시 삭제 명령을 보내지 마십시오 — 이미 삭제된 상태라면 반복 전송 시 배출가스 준비 상태가 초기화됩니다.';

  @override
  String get dtcClearTimeout =>
      '삭제 명령을 보낸 뒤 아무 응답이 없어 차량에서 삭제되었는지 알 수 없습니다. 다시 스캔하여 확인하십시오. 무작정 삭제 명령을 다시 보내지 마십시오.';

  @override
  String get dtcClearUnexpected =>
      '삭제에 실패하여 차량에서 삭제되었는지 알 수 없습니다. 다시 스캔하여 확인하십시오. 무작정 삭제 명령을 다시 보내지 마십시오.';

  @override
  String get dtcClearing => '삭제 중…';

  @override
  String get dtcScanDisconnectedMidScan => '스캔 도중 연결이 끊어져 이번 스캔이 완료되지 않았습니다.';

  @override
  String get dtcScanInterrupted =>
      '스캔이 도중에 중단되어(앱이 백그라운드로 전환되었거나 연결이 변경되었을 수 있음) 완전한 결과를 얻지 못했습니다. 다시 스캔하십시오.';

  @override
  String get dtcCompleteCleanBody =>
      '이는 응답한 모든 제어기가 고장 코드 없음을 보고했다는 뜻입니다. 차량의 모든 모듈에 질의했다는 뜻은 아닙니다.';

  @override
  String get dtcCompleteCleanTitle => '응답한 제어기 중 고장 코드를 보고한 곳이 없습니다.';

  @override
  String dtcControllerLabel(Object controller) {
    return '제어기 $controller';
  }

  @override
  String get dtcDismiss => '닫기';

  @override
  String dtcFreezeFrameBody(Object code) {
    return '$code가 확정된 순간 이 제어기가 기록한 값입니다. 고장 코드를 삭제하면 이 기록도 함께 영구 삭제됩니다.';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      '이 제어기에 프리즈 프레임이 있지만 어떤 항목이 들어 있는지 묻는 쿼리에 응답하지 않아 내용을 읽을 수 없었습니다. 다시 스캔하면 읽힐 수 있습니다.';

  @override
  String get dtcFreezeFrameNothingDecodable =>
      '이 제어기에 프리즈 프레임이 있지만 이 앱이 해독할 수 있는 항목이 없습니다.';

  @override
  String get dtcFreezeFrameTitle => '고장 발생 순간의 차량 상태';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이 프리즈 프레임의 다른 항목 $count개는 이 앱에 변환 공식이 없어 목록에 표시되지 않았습니다.',
    );
    return '$_temp0';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '이번에 항목 $count개를 읽어오지 못했습니다(시간이 부족했거나 제어기가 응답하지 않았을 수 있음). 다시 스캔하면 읽힐 수 있습니다.',
    );
    return '$_temp0';
  }

  @override
  String get dtcFreezeFrameUnreadPanel =>
      '이번 스캔에서 프리즈 프레임을 읽지 못했습니다 — 차량에 프리즈 프레임이 없다는 뜻은 아닙니다. 고장 코드를 삭제하면 고장 발생 순간의 기록이 영구적으로 소멸하므로, 먼저 다시 스캔한 뒤 고장 코드 삭제 여부를 결정하십시오. 매번 스캔 결과가 같다면 이 차량이 프리즈 프레임을 제공하지 않는 것일 수 있습니다.';

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label (Mode $mode) · $count';
  }

  @override
  String get dtcHeadline => '고장 코드';

  @override
  String get dtcListSeparator => ', ';

  @override
  String get dtcManufacturerSpecific => '제조사 고유 코드 — 이 차량의 정비 지침서를 확인하십시오';

  @override
  String get dtcMilOff => '고장 표시등이 켜져 있지 않습니다';

  @override
  String get dtcMilOn => '고장 표시등이 켜져 있습니다';

  @override
  String get dtcMonitorBoostPressure => '부스트 압력';

  @override
  String get dtcMonitorCatalyst => '촉매 변환기';

  @override
  String get dtcMonitorComponents => '종합 부품 모니터';

  @override
  String get dtcMonitorEgr => 'EGR / VVT 시스템';

  @override
  String get dtcMonitorEvaporative => '증발가스 제어 시스템';

  @override
  String get dtcMonitorExhaustSensor => '배기 센서';

  @override
  String get dtcMonitorFuelSystem => '연료 시스템 모니터';

  @override
  String get dtcMonitorGasolineParticulateFilter => '가솔린 미립자 필터 (GPF)';

  @override
  String get dtcMonitorHeatedCatalyst => '가열식 촉매';

  @override
  String get dtcMonitorMisfire => '실화 모니터';

  @override
  String get dtcMonitorNmhcCatalyst => 'NMHC 촉매';

  @override
  String get dtcMonitorNoxAftertreatment => 'NOx / SCR 후처리';

  @override
  String get dtcMonitorOxygenSensor => '산소 센서';

  @override
  String get dtcMonitorOxygenSensorHeater => '산소 센서 히터';

  @override
  String get dtcMonitorParticulateFilter => '미립자 필터';

  @override
  String get dtcMonitorSecondaryAir => '2차 공기 분사 시스템';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — 이 앱에는 이 코드에 대한 상세 설명이 없습니다';
  }

  @override
  String get dtcNotConnectedBody =>
      '고장 코드를 읽으려면 ELM327 어댑터를 연결하거나 시뮬레이터를 실행해야 합니다.';

  @override
  String get dtcNotConnectedTitle => '연결되지 않음';

  @override
  String get dtcNotScanned => '아직 스캔하지 않음';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '제어기 $count개',
    );
    return '세 범주 모두 끝까지 쿼리했습니다. $_temp0($controllers)가 보류 중 또는 영구 고장 코드를 구현하지 않습니다 — 많은 차량에서 정상적인 현상이지만, 바로 이 때문에 차량 전체에 고장이 없다고 단정할 수 없습니다.';
  }

  @override
  String get dtcPartialCleanTitle => '응답한 범주에서는 고장 코드가 보고되지 않았습니다.';

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories에서 응답이 없어 상태를 확인할 수 없습니다 — 이는 차량에 문제가 없다는 것과 같지 않습니다.';
  }

  @override
  String dtcPartialCodesRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '고장 코드 $count개를 읽었으나',
    );
    return '이 범주가 중단되기 전에 $_temp0 조회 범위가 불완전합니다:';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return '이 범주에서 일부 제어기만 응답하고 나머지는 응답하지 않았으므로, 이를 차량 전체의 결과로 간주할 수 없습니다. $message';
  }

  @override
  String get dtcReadFailed => '읽기 실패';

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label (Mode $mode): $message';
  }

  @override
  String get dtcReadinessAllComplete =>
      '이 제어기가 담당하는 모든 배출가스 준비 상태 모니터가 완료되었습니다.';

  @override
  String dtcReadinessIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '모니터 항목 $count개가 아직 완료되지 않았습니다',
    );
    return '$_temp0 — 지금 정기 검사를 받으면 통과하지 못할 수 있습니다.';
  }

  @override
  String get dtcReadinessSaysNothing =>
      '이 제어기는 배출가스 준비 상태 모니터를 전혀 보고하지 않았습니다 — 배출가스 모니터링을 담당하지 않는 제어기일 수 있으며, 이것이 준비 완료를 뜻하지는 않습니다.';

  @override
  String get dtcReadinessTitle => '배출가스 준비 상태';

  @override
  String get dtcRescanFirst => '먼저 다시 스캔';

  @override
  String get dtcRetry => '다시 시도';

  @override
  String get dtcScanBody =>
      'Mode 03 저장됨, Mode 07 보류 중 및 Mode 0A 영구 고장 코드를 읽습니다.';

  @override
  String get dtcScanTitle => '차량 고장 코드 스캔';

  @override
  String get dtcScanning => '스캔 중…';

  @override
  String dtcSelfReportedCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '이 제어기는 확정된 고장 코드 $count개를 자체 보고합니다.',
    );
    return '$_temp0';
  }

  @override
  String get dtcSelfReportedNoCodes => '이 제어기는 확정된 고장 코드가 없다고 자체 보고합니다.';

  @override
  String get dtcSilentCategoryHeadline => '이 범주가 응답하지 않았습니다';

  @override
  String get dtcSilentPendingDetail =>
      '보류 중 고장 코드(Mode 07)가 응답하지 않았습니다. 이 ECU가 해당 서비스를 구현하지 않았거나 단순히 이번에 읽히지 않은 것일 수 있습니다 — 무응답만으로는 두 경우를 구분할 수 없으며, 보류 중인 고장이 없다는 뜻으로 받아들여서는 안 됩니다. 저장된 고장 코드 결과에는 영향이 없습니다.';

  @override
  String get dtcSilentPermanentDetail =>
      '영구 고장 코드(Mode 0A)가 응답하지 않았습니다. 이 범주는 2010년경 OBD-II 세대부터 도입되었으므로 구형 차량은 지원하지 않는 경우가 있습니다 — 하지만 무응답은 단순히 이번에 읽히지 않았다는 뜻일 수도 있으며 두 경우는 구분할 수 없습니다. 저장된 고장 코드 결과에는 영향이 없습니다.';

  @override
  String get dtcStartScan => '스캔 시작';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return '차량이 Mode $mode 쿼리에 응답하지 않았으므로 저장된 고장 코드가 있는지 확인할 수 없습니다. 이는 고장 코드가 없다는 것과 같지 않습니다.';
  }

  @override
  String dtcTotalCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '코드 $count개',
    );
    return '$_temp0';
  }

  @override
  String get dtcUnconfirmed => '확인 불가';

  @override
  String get dtcUnknownError => '알 수 없는 오류';

  @override
  String get dtcUnknownMonitor => '알 수 없는 모니터 항목';

  @override
  String get dtcVerdictCompleteClean => '응답한 제어기에서 보고된 고장 코드 없음';

  @override
  String get dtcVerdictPartialClean => '일부 미확인';

  @override
  String get fieldEventBody =>
      '차량이 완전히 정차했을 때만 동승자나 주차 상태의 운전자가 누르십시오. 이벤트는 원본 OBD 데이터와 동일한 타임라인을 공유하며 즉시 저장을 시도합니다.';

  @override
  String get fieldEventEngineStarted => '엔진 시동';

  @override
  String get fieldEventHeading => '실차 이벤트 마커';

  @override
  String get fieldEventIgnitionOn => '시동 스위치 ON';

  @override
  String get fieldEventMemoryOnly =>
      '현재 세션에 기록되었으나 자동 저장에 실패했습니다 — 지금 진단 통신 기록을 내보내십시오.';

  @override
  String fieldEventRecorded(String marker) {
    return '기록 및 저장 완료: $marker';
  }

  @override
  String get fieldEventRoadTestStarted => '주행 테스트 시작';

  @override
  String get fieldEventThrottleBlip => '가속 페달 짧게 밟기';

  @override
  String get fieldEventUnavailable => '기록할 실시간 차량 연결이 없습니다.';

  @override
  String get gaugeNoData => '데이터 없음';

  @override
  String gaugeNoDataBecause(String reason) {
    return '데이터 없음 — $reason';
  }

  @override
  String gaugeReadingStale(String reading) {
    return '$reading (데이터 오래됨)';
  }

  @override
  String get gaugeUnsupportedByVehicle => '이 차량에서 지원하지 않음';

  @override
  String get handshakeNoteAborted => '이전 단계 실패 후 중단되었습니다.';

  @override
  String get handshakeNoteEcuRefusedSupportQuery =>
      'ECU가 지원 여부 쿼리를 거부했습니다(부정 응답).';

  @override
  String get handshakeNoteEcuSilent => 'ECU가 응답하지 않았습니다.';

  @override
  String get handshakeNoteNotAcknowledged => '어댑터가 이 명령을 확인(ACK)하지 않았습니다.';

  @override
  String get handshakeNoteNotModeOnePositiveReply => '응답이 Mode 01 긍정 응답이 아닙니다.';

  @override
  String get handshakeNotePidEchoMismatch => '응답에 에코된 PID가 요청한 PID와 다릅니다.';

  @override
  String get handshakeNoteSupportMaskTooShort =>
      '지원 여부 응답이 너무 짧습니다(41 00과 추가 4바이트가 필요함).';

  @override
  String get handshakeNoteTimedOut => '시간이 초과되었습니다.';

  @override
  String get handshakeStepAdapterVersion => '어댑터 버전 읽기';

  @override
  String get handshakeStepAdaptiveTiming => '적응형 타이밍 활성화 (데이터시트 권장 설정)';

  @override
  String get handshakeStepBatteryVoltage => '배터리 전압 읽기';

  @override
  String get handshakeStepDeviceIdentity => '기기 식별 문자열 읽기';

  @override
  String get handshakeStepEchoOff => '명령 에코 끄기';

  @override
  String get handshakeStepLinefeedsOff => '줄바꿈 문자 끄기';

  @override
  String get handshakeStepMemoryOff => '메모리 쓰기 끄기';

  @override
  String get handshakeStepNoReason => '응답 없음';

  @override
  String get handshakeStepProtocolAuto => '버스 프로토콜 자동 감지';

  @override
  String get handshakeStepProtocolDescription => '프로토콜 설명 읽기';

  @override
  String get handshakeStepProtocolNumber => '프로토콜 번호 읽기';

  @override
  String get handshakeStepReset => '어댑터 소프트웨어 리셋';

  @override
  String get handshakeStepResponseTimeout => '응답 제한 시간을 약 408 ms로 설정';

  @override
  String get handshakeStepSpacesOff => '공백 문자 끄기 (전송량 약 1/3 절감)';

  @override
  String get handshakeStepSupportProbe => 'ECU가 지원하는 PID를 질의하여 차량 응답 확인';

  @override
  String get languageSaveFailed => '언어 설정을 저장할 수 없습니다. 다시 시도하십시오.';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get navDashboard => '대시보드';

  @override
  String get navDtc => '고장 코드';

  @override
  String get navPerformance => '계측';

  @override
  String get navPid => 'PID';

  @override
  String get navSettings => '설정';

  @override
  String get performanceArm => '타이머 준비';

  @override
  String get performanceDisclaimer =>
      '기록은 OBD 차속 신호를 기준으로 측정됩니다. 대부분의 차량 속도계는 실제보다 1–3 km/h 높게 표시되며 신호 갱신 주기도 초당 약 10–20회에 불과하므로, 이 결과는 참고용일 뿐 전문 계측 장비와 동등하지 않습니다.';

  @override
  String get performanceHeadline => '가속 테스트';

  @override
  String get performanceNoSpeedSignal =>
      '현재 유효한 차속 신호(PID 010D)가 없습니다. 차속 신호 없이는 가속 테스트 시간을 측정할 수 없습니다.';

  @override
  String get performanceNotConnectedBody =>
      '가속 테스트에는 실시간 차속 데이터가 필요합니다. 어댑터를 연결하거나 내장 시뮬레이터를 시작하십시오.';

  @override
  String get performanceNotConnectedTitle => '연결되지 않음';

  @override
  String get performancePeakSpeed => '최고 속도';

  @override
  String get performanceReset => '초기화';

  @override
  String get performanceSecondsUnit => '초';

  @override
  String get performanceSpeedGaugeLabel => '속도';

  @override
  String get performanceSpeedTraceHeading => '속도 궤적';

  @override
  String get performanceSplitsHeading => '구간 기록';

  @override
  String get performanceStateAborted =>
      '이번 측정은 완료되지 않았으며, 아래는 중단되기 전까지 기록된 내용입니다';

  @override
  String get performanceStateAwaitingSpeedSignal => '차속 신호 대기 중';

  @override
  String performanceStateAwaitingStandstill(String speed) {
    return '먼저 완전히 정차하십시오 — 현재 $speed km/h';
  }

  @override
  String performanceStateFinished(int target) {
    return '0 → $target km/h 완료';
  }

  @override
  String get performanceStateIdle => '목표 속도를 선택한 후 시작하십시오';

  @override
  String get performanceStateRunning => '계측 중';

  @override
  String get performanceStateStaged => '준비 완료 — 출발하면 타이머가 시작됩니다';

  @override
  String get performanceSubhead => '정지 상태에서 목표 속도까지 도달하는 시간을 측정합니다';

  @override
  String get performanceTargetSpeedHeading => '목표 속도';

  @override
  String get pidActionCancel => '취소';

  @override
  String get pidActionDelete => '삭제';

  @override
  String get pidArrangeBody =>
      '드래그하여 순서를 변경하십시오. 대시보드는 왼쪽에서 오른쪽, 위에서 아래 순서로 채워지므로 앞에 배치한 항목이 가장 먼저 보입니다.';

  @override
  String get pidArrangeEmptyMessage =>
      '먼저 목록에서 몇 개 항목을 활성화한 뒤 돌아와서 순서를 정렬하십시오.';

  @override
  String get pidArrangeEmptyTitle => '아직 활성화된 PID가 없습니다';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return '확인된 $count개 추가';
  }

  @override
  String get pidBulkActionAllActive => '모두 이미 활성화됨';

  @override
  String get pidBulkActionIncomplete => '스캔 데이터가 불완전함';

  @override
  String get pidBulkActionLocked => '기록 중에는 변경할 수 없음';

  @override
  String get pidBulkActionPending => '스캔 결과 대기 중';

  @override
  String get pidBulkActionZero => '지원 확인된 PID 없음';

  @override
  String pidBulkAddCount(int count) {
    return '$count개 추가';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return '지원이 확인된 PID $count개를 추가하시겠습니까?';
  }

  @override
  String pidBulkAdded(int count) {
    return '지원이 확인된 PID $count개를 추가했습니다.';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '지원 블록 $count개가 아직 미확인 상태입니다 — 이번에는 지원이 명확히 확인된 항목만 추가합니다.';
  }

  @override
  String pidBulkWillAdd(int count) {
    return '$count개를 추가합니다. 활성화된 PID가 많아질수록 각 항목의 갱신 주기가 길어질 수 있습니다.';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '$confirmed개 확인됨';
  }

  @override
  String get pidCapabilityCoverageNone => '연속된 조회 범위가 아직 확인되지 않음';

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return '연속 조회 범위 01–$through (끝까지 도달함)';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return '연속 조회 범위 01–$through (이후 알 수 없음)';
  }

  @override
  String get pidCapabilityPhaseAttemptFinished => '이번 지원 여부 스캔이 끝났습니다';

  @override
  String get pidCapabilityPhaseInterrupted => '지원 여부 스캔이 중단되었습니다';

  @override
  String get pidCapabilityPhaseNotStarted => '스캔 시작 안 됨';

  @override
  String get pidCapabilityPhaseRunning => '이 차량이 지원하는 항목을 확인하는 중';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return '차량 지원 PID. $phase. $confirmed개 확인됨. 알 수 없는 블록 $unknown개.';
  }

  @override
  String get pidCapabilityTitle => '차량 지원 PID';

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '알 수 없는 블록 $unknown개';
  }

  @override
  String pidEditorCollision(String name) {
    return '다른 사용자 정의 PID가 이미 이 조합($name)을 사용하고 있습니다. 다른 모드 + PID, 헤더 또는 이름 접미사를 사용하십시오.';
  }

  @override
  String pidEditorDeleteBody(String name) {
    return '“$name”의 정의가 제거되고 대시보드에서 해당 게이지가 사라지며, 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get pidEditorDeleteTitle => '이 PID를 삭제하시겠습니까?';

  @override
  String get pidEditorDiscard => '변경 취소';

  @override
  String get pidEditorDiscardBody =>
      '이 PID의 변경 사항이 아직 저장되지 않았으며, 화면을 나가면 변경 사항이 사라집니다.';

  @override
  String get pidEditorDiscardTitle => '저장하지 않은 변경 사항을 버리시겠습니까?';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N은 응답 바이트에 대응하며 SIGNED(), ABS(), LOG10(), $valSyntax, BARO를 사용할 수 있습니다';
  }

  @override
  String get pidEditorFieldEquation => '수식';

  @override
  String get pidEditorFieldHeader => 'CAN 헤더';

  @override
  String get pidEditorFieldMax => '최댓값';

  @override
  String get pidEditorFieldMin => '최솟값';

  @override
  String get pidEditorFieldModeAndPid => '모드 + PID';

  @override
  String get pidEditorFieldName => '이름';

  @override
  String get pidEditorFieldSample => '테스트 응답 바이트';

  @override
  String get pidEditorFieldShortName => '약칭 (게이지에 표시됨)';

  @override
  String get pidEditorFieldUnits => '단위';

  @override
  String get pidEditorHeaderHelper => '7E0 = 엔진';

  @override
  String get pidEditorKeepEditing => '계속 편집';

  @override
  String get pidEditorModeAndPidHelper => '예: 010C 또는 221101';

  @override
  String get pidEditorSampleHelper => '16진수를 입력하면 입력하는 즉시 계산 결과를 미리 볼 수 있습니다';

  @override
  String get pidEditorSave => '저장';

  @override
  String get pidEditorSectionFormula => '공식';

  @override
  String get pidEditorSectionIdentity => '식별 정보';

  @override
  String get pidEditorSectionQuery => '쿼리';

  @override
  String get pidEditorSectionRangeAndPriority => '게이지 범위 및 우선순위';

  @override
  String get pidEditorTitleEdit => 'PID 편집';

  @override
  String get pidEditorTitleNew => '새 사용자 정의 PID';

  @override
  String pidExportFailed(String error) {
    return '내보내기 실패: $error';
  }

  @override
  String get pidExportNoCustomPids => '내보낼 사용자 정의 PID가 없습니다.';

  @override
  String get pidImportNothingToImport => '가져올 정의가 없습니다.';

  @override
  String pidImportLandedClean(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '사용자 정의 PID $count개를 가져왔습니다.',
    );
    return '$_temp0';
  }

  @override
  String pidImportLandedWithNotes(int count, String notes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '항목 $count개를 가져왔습니다($notes).',
      one: '항목 1개를 가져왔습니다($notes).',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteSkippedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 행에 문제가 있어 건너뛰었습니다',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDefaultedRanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 행에 기본 게이지 범위를 적용했습니다',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 항목이 기존 정의를 대체했습니다',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDuplicatesInFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 행이 파일 내 다른 행과 중복되어 건너뛰었습니다',
    );
    return '$_temp0';
  }

  @override
  String get pidImportPickerFailed => '파일 선택기를 열 수 없습니다.';

  @override
  String get pidImportReadFailed => '파일을 읽을 수 없습니다.';

  @override
  String get pidListSeparator => ', ';

  @override
  String get pidManagerActiveOnly => '활성 항목만';

  @override
  String get pidManagerAdd => '추가';

  @override
  String get pidManagerArrangeDashboard => '대시보드 정렬';

  @override
  String pidManagerCounts(int active, int total) {
    return '$active개 활성화됨 · 총 $total개 사용 가능';
  }

  @override
  String get pidManagerExportCsv => '사용자 정의 PID 내보내기';

  @override
  String get pidManagerExportTorqueCsv => 'Torque 호환 CSV 내보내기';

  @override
  String get pidManagerExportHumanReport => '사람이 읽기 쉬운 PID 보고서 내보내기';

  @override
  String get pidManagerHeadline => 'PID 관리';

  @override
  String get pidManagerImportCsv => 'CSV 가져오기';

  @override
  String get pidManagerMoreActions => '더보기';

  @override
  String get pidManagerNoMatchMessage => '다른 검색어를 입력하거나 사용자 정의 PID를 만드십시오.';

  @override
  String get pidManagerNoMatchTitle => '일치하는 PID 없음';

  @override
  String get pidManagerPowertrainBatteryCatalog => '고전압 배터리 카탈로그';

  @override
  String get pidManagerSearchHint => '이름 또는 PID 코드로 검색…';

  @override
  String get pidPickCsvDialogTitle => 'PID 정의 CSV 파일 선택';

  @override
  String get pidPillCustom => '사용자 정의';

  @override
  String get pidPillUnsupported => '지원 안 됨';

  @override
  String get pidPreviewCannotEvaluate => '계산 불가';

  @override
  String get pidPreviewResultLabel => '계산 결과';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '미리보기에서는 $dependencies 자리에 임시 값 $valueString을(를) 대입하며, 실제 값은 연결 후 해당 PID에서 읽어옵니다.';
  }

  @override
  String get pidPreviewTitle => '실시간 미리보기';

  @override
  String get pidPriorityHigh => '높음';

  @override
  String get pidPriorityLow => '낮음';

  @override
  String get pidPriorityMedium => '보통';

  @override
  String get pidPriorityVeryLow => '매우 낮음';

  @override
  String get pidRowEdit => '편집';

  @override
  String pidRowShowOnDashboard(String name) {
    return '대시보드에 $name 표시';
  }

  @override
  String pidRowStaleUnits(String units) {
    return '$units · 오래됨';
  }

  @override
  String powertrainAuthorizationGranted(String profile) {
    return '이번 연결에서 $profile의 배터리 신호가 활성화되었습니다';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return '활성화할 수 없음: $reason';
  }

  @override
  String get powertrainCancel => '취소';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return '프로필: $profiles개 · 단발 판독 가능: $probeable개';
  }

  @override
  String get powertrainCatalogLoadFailedBody =>
      '무결성 검증을 통과하지 못하여 어떠한 차량 데이터도 표시하거나 설치하지 않았습니다.';

  @override
  String get powertrainCatalogLoadFailedTitle => '오프라인 카탈로그를 불러올 수 없음';

  @override
  String get powertrainCatalogNotVerified =>
      '카탈로그가 아직 검증을 통과하지 못하여 아무것도 설치할 수 없습니다.';

  @override
  String get powertrainCatalogRevalidate => '다시 검증';

  @override
  String get powertrainCatalogScopeNote =>
      '카탈로그의 범위는 넓지만 “데이터를 찾았다”는 것이 곧 “이 차량을 지원한다”는 뜻은 아닙니다. 연구 전용(researchOnly) 항목에는 명령이 포함되어 있지 않습니다. Mode 22 실험적 항목은 설치 및 폴링이 가능하지만 모든 값에 미검증 라벨이 붙으며, Mode 21 실험적 항목은 확인할 때마다 한 번씩만 읽습니다.';

  @override
  String get powertrainCatalogSearchHint => '제조사, 모델, 세부 모델 또는 출시 국가 검색…';

  @override
  String get powertrainCatalogTitle => '고전압 배터리 카탈로그';

  @override
  String get powertrainChooseCommandNote =>
      '시도당 명령 1개만 전송: 스캔 없음, 일괄 요청 없음, 자동 재시도 없음.';

  @override
  String get powertrainChooseCommandTitle => '고정된 읽기 전용 쿼리 1개 선택';

  @override
  String get powertrainClose => '닫기';

  @override
  String get powertrainConfirmAccept => '이 차량이 맞습니다';

  @override
  String get powertrainConfirmBody =>
      '설치된 프로필 신호는 이 차량이 해당 모델임을 확인한 뒤에만 읽어오며, 이 확인은 이번 연결에서만 유효합니다.';

  @override
  String get powertrainConfirmButton => '차량 확인';

  @override
  String get powertrainConfirmDialogBody =>
      '확인하면 이번 연결이 유지되는 동안 이 프로필의 읽기 전용 배터리 쿼리를 주기적으로 폴링합니다. 잘못된 프로필을 선택하면 그럴듯해 보이지만 틀린 숫자가 나올 수 있으므로 확실하지 않으면 취소하십시오.';

  @override
  String get powertrainConfirmDialogTitle => '연결된 차량 확인';

  @override
  String get powertrainConfirmTitle => '차량 배터리 신호 확인 대기 중';

  @override
  String get powertrainConnectFirst =>
      '먼저 연결하십시오. 실험적 권한 부여는 연결이 바뀌면 절대 유지되지 않습니다.';

  @override
  String get powertrainConnectionChanged =>
      '연결이 변경되었습니다 — 새 연결에 대해 차량을 다시 확인해 주십시오.';

  @override
  String get powertrainEnableLabInSettings =>
      '먼저 설정에서 실험적 고전압 배터리 실험실을 켜 주십시오.';

  @override
  String get powertrainEvidencePhysicalVehicle => '프로젝트 실차';

  @override
  String get powertrainEvidenceSourceBacked => '출처 자료';

  @override
  String get powertrainEvidenceSyntheticRig => '합성 테스트 리그';

  @override
  String get powertrainExperimentalDataDisclosure =>
      '이는 출처 작성자가 표시한 후보 판독값일 뿐 제조사 보증이나 타 차종 호환 및 안전 보증이 아니며, ELM327은 명령을 전달하기만 합니다. 원본 명령과 응답은 로컬 진단 통신 기록에만 남고 이 기능에 의해 자동으로 업로드되지 않으며, 해독된 값은 PID로 설치되거나 게이지에 추가되지 않습니다. 취소하더라도 일반 OBD 기능에는 아무 영향이 없습니다.';

  @override
  String get powertrainExperimentalDialogTitle => '단발 실험적 읽기 전용 확인';

  @override
  String get powertrainExperimentalIdentityAck =>
      '출처에 기록된 출시 국가, 모델, 연식을 대조해 보았으며 미확인 필드를 감수하는 것에 동의합니다';

  @override
  String get powertrainExperimentalParkedAck =>
      '차량이 안전하게 주차되어 있으며, 이 작업은 한 번만 읽고 그 숫자도 내 차량에 맞지 않을 수 있음을 이해합니다';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return 'RX $responder 응답만 수락, 페이로드 길이 $bytes bytes';
  }

  @override
  String get powertrainFieldListSeparator => ', ';

  @override
  String get powertrainFieldMarket => '출시 국가';

  @override
  String get powertrainFieldModel => '모델';

  @override
  String get powertrainFieldModelYear => '연식';

  @override
  String get powertrainFieldVariant => '세부 모델';

  @override
  String get powertrainFilterAll => '전체';

  @override
  String get powertrainIdentityEvidenceExact => '직접 증거';

  @override
  String get powertrainIdentityEvidenceNone => '없음';

  @override
  String get powertrainIdentityEvidenceSourcePartial => '부분 증거';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return '출처 식별 증거: $fields\n미확인 필드: $unconfirmed';
  }

  @override
  String get powertrainIdentityEvidenceUnknown => '알 수 없음';

  @override
  String get powertrainInstallButton => '배터리 신호 설치';

  @override
  String get powertrainInstallConfirm => '설치';

  @override
  String get powertrainInstallDialogTitle => '이 모델의 배터리 신호 설치';

  @override
  String get powertrainInstallDisclosureCommunity =>
      '설치하면 읽기 전용 배터리 PID가 PID 관리에 추가될 뿐입니다. 판독을 시작하기 전에 매 연결마다 대시보드에서 이 차량이 해당 모델인지 확인을 요청합니다. 데이터는 커뮤니티 출처에서 왔으며 독립적인 교차 검증을 거쳤으나 여전히 제조사 보증이 아닙니다.';

  @override
  String get powertrainInstallDisclosureExperimental =>
      '설치하면 읽기 전용 배터리 PID가 PID 관리에 추가될 뿐입니다. 판독을 시작하기 전에 매 연결마다 대시보드에서 이 차량이 해당 모델인지 확인을 요청합니다. 이는 독립적 교차 검증 요건이 없는 실험적 디코드이며, 이 차량에서 미검증 상태이고 제조사 보증도 아닙니다.';

  @override
  String get powertrainInstallDisclosureReady =>
      '설치하면 읽기 전용 배터리 PID가 PID 관리에 추가될 뿐입니다. 판독을 시작하기 전에 매 연결마다 대시보드에서 이 차량이 해당 모델인지 확인을 요청합니다. 출처 데이터는 더 충실하지만 여전히 제조사 보증이 아닙니다.';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      '설치하면 읽기 전용 배터리 PID가 PID 관리에 추가될 뿐입니다. 판독을 시작하기 전에 매 연결마다 대시보드에서 이 차량이 해당 모델인지 확인을 요청합니다. 이 항목은 연구 전용이므로 설치해서는 안 됩니다.';

  @override
  String get powertrainInstallCatalogShaMissing =>
      '설치 불가: 이 카탈로그 스냅샷에는 검증된 SHA-256이 없으므로 내부의 어떠한 내용도 신뢰할 수 없습니다.';

  @override
  String get powertrainInstallPersistFailed =>
      '설치 불가: 설치된 프로필 목록을 저장할 수 없었습니다. 다시 시도하십시오. PID 관리에는 아무 항목도 추가되지 않았습니다.';

  @override
  String get powertrainInstallProfileNotInCatalog =>
      '설치 불가: 해당 프로필이 검증된 카탈로그에 없습니다.';

  @override
  String get powertrainInstallProfileNotInstallable =>
      '설치 불가: 이 프로필은 실제 PID로 전환할 수 있는 상태가 아닙니다.';

  @override
  String get powertrainInstallYearOutOfRange =>
      '설치 불가: 선택한 연식이 이 프로필에 문서화된 연도 범위를 벗어납니다.';

  @override
  String get powertrainInstallIdentityAck => '내 차량이 위의 출시 국가, 모델 및 연식과 일치합니다';

  @override
  String get powertrainInstalledRemoveButton => '설치됨 · 신호 제거';

  @override
  String powertrainInstalledSignalsSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '신호 $count개를 설치했습니다. PID 페이지에서 대시보드에 추가하십시오. 매 연결마다 차량 확인이 필요합니다.',
    );
    return '$_temp0';
  }

  @override
  String get powertrainNoMatchBody =>
      '제조사나 모델 이름을 바꾸어 보거나 다른 파워트레인 유형으로 전환해 보십시오.';

  @override
  String get powertrainNoMatchTitle => '일치하는 차량 없음';

  @override
  String get powertrainNotInstallableInThisRelease => '이 릴리스에서는 설치 불가';

  @override
  String powertrainPrimarySource(String name, String license) {
    return '주요 출처: $name ($license)';
  }

  @override
  String get powertrainProbeChecksPassed =>
      '응답자(responder), 에코(echo), 정확한 길이(exact length), 공식 및 범위 검사를 통과했습니다.';

  @override
  String get powertrainProbeConnectForOneShot => '연결 후 단발 읽기 전용 쿼리 실행';

  @override
  String get powertrainProbeConnectToTryOnce => '연결하여 먼저 1회 시험 판독';

  @override
  String get powertrainProbeDidNotFinish =>
      '단발 쿼리가 완료되지 않았습니다. 어떠한 값도 게시되거나 보관되지 않았습니다.';

  @override
  String get powertrainProbeEnableLabFirst => '먼저 설정에서 실험실을 켜 주십시오';

  @override
  String get powertrainProbeInProgress => '1회 판독 중…';

  @override
  String get powertrainProbeNoValuePublished =>
      '어떠한 값도 게시되지 않았습니다. 구조 또는 디코드 오류는 다시 연결할 때까지 격리됩니다.';

  @override
  String get powertrainProbeOnceButton => '1회만 읽기';

  @override
  String get powertrainProbePassedTitle => '단발 쿼리 통과';

  @override
  String get powertrainProbePickOneRead => '명령 1개를 선택하여 1회 판독';

  @override
  String get powertrainProbeReconnectFirst => '다시 연결한 후 재시도';

  @override
  String get powertrainProbeRefusedTitle => '단발 쿼리 거부됨';

  @override
  String get powertrainProbeTryOnceFirst => '먼저 1회 시험 판독';

  @override
  String get powertrainProfileNotVerified => '프로필이 검증된 카탈로그에 없습니다';

  @override
  String get powertrainQuarantinedPill => '격리됨 · 재연결 필요';

  @override
  String get powertrainRefusedCatalogHashInvalid =>
      '승인되지 않음: 카탈로그의 무결성 해시가 유효하지 않으므로 내부의 어떠한 내용도 읽을 수 없습니다.';

  @override
  String get powertrainRefusedCommandNotInProfile =>
      '승인되지 않음: 해당 명령은 이 검증된 프로필에 속한 명령이 아닙니다.';

  @override
  String get powertrainRefusedLabClosed =>
      '이번 판독이 승인되기 전에 실험적 고전압 배터리 실험실이 꺼졌습니다.';

  @override
  String get powertrainRefusedProfileFailedValidation =>
      '승인되지 않음: 이 프로필이 선택한 연식에 대한 카탈로그 검증을 통과하지 못했습니다.';

  @override
  String get powertrainRefusedProfileNotInCatalog =>
      '승인되지 않음: 이 프로필이 검증된 카탈로그에 없습니다.';

  @override
  String get powertrainRefusedProfileNotProbeable =>
      '승인되지 않음: 이 프로필은 실험적 1회 판독이 가능한 프로필이 아닙니다.';

  @override
  String get powertrainRefusedQuarantinedAfterRejectedRead =>
      '이번 연결에서 격리됨: 이전 1회 판독이 구조 검사를 통과하지 못했습니다. 다시 시도하려면 먼저 재연결하십시오.';

  @override
  String get powertrainRefusedNotConnectedOrNotInForeground =>
      '1회 판독이 시작되지 않았습니다: 아무것도 연결되어 있지 않거나 앱이 포그라운드 상태가 아니었습니다.';

  @override
  String get powertrainRefusedNoLiveAuthorization =>
      '1회 판독이 시작되지 않았습니다: 유효한 일회성 권한이 없습니다. 권한이 부여되지 않았거나, 만료되었거나, 쿨다운 중이거나, 격리되었습니다.';

  @override
  String get powertrainRefusedDiscardedAtLifecycleBoundary =>
      '1회 판독이 실행되는 도중 연결 또는 포그라운드 상태가 변경되어 응답을 표시하지 않고 폐기했습니다. 오류가 발생한 것은 아니며 보관된 결과도 없습니다.';

  @override
  String powertrainRefusedQuarantinedAtAttemptCap(int attemptCap) {
    return '이번 연결에서 격리됨: 동일한 명령을 이미 $attemptCap회 시도했습니다. 다시 시도하려면 먼저 재연결하십시오.';
  }

  @override
  String get powertrainResearchOnlyNeverQueries => '연구 전용 — 쿼리하지 않음';

  @override
  String get powertrainRestoreStorageErrorRetry =>
      '이전 설치 항목을 복원하는 중 저장소 오류가 발생하여 다시 예약되었습니다 — 다시 시도하십시오.';

  @override
  String powertrainSecondarySource(String name, String license) {
    return '독립 교차 검증: $name ($license)';
  }

  @override
  String powertrainSignalCount(int count) {
    return '신호: $count개';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return '원본 파일 SHA-256: $hash…';
  }

  @override
  String get powertrainStatusCommunity => '커뮤니티 · 미검증';

  @override
  String get powertrainStatusExperimental => '실험 · 미검증';

  @override
  String get powertrainStatusExperimentalProbeOnly => '실험 · 1회 읽기';

  @override
  String get powertrainStatusReady => '더 충실한 출처 자료';

  @override
  String get powertrainStatusResearchOnly => '연구 전용';

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return '$name의 설치된 신호를 제거했습니다.';
  }

  @override
  String powertrainVehicleYearFixed(int year) {
    return '연식: $year';
  }

  @override
  String get powertrainVehicleYearLabel => '연식';

  @override
  String get recommendedPurchaseDisclosure =>
      '이 링크는 메인테이너의 제휴 수익 링크이며, 조건에 부합하는 구매가 이루어지면 메인테이너가 수수료를 받을 수 있습니다. 이는 어댑터 인증이나 구매 보증이 아닙니다. 판매 페이지 내용과 하드웨어 리비전은 변경될 수 있으므로 구매 전에 전체 모델 번호와 NCC 인증 번호를 직접 확인하십시오. 다른 판매처를 직접 검색하여 구매하셔도 됩니다.';

  @override
  String get recommendedPurchaseHeading => '추천 어댑터';

  @override
  String recommendedPurchaseModelLine(String model, String approval) {
    return '모델 $model · NCC $approval';
  }

  @override
  String recommendedPurchaseNoAdapterYet(String store) {
    return '아직 어댑터가 없으신가요? $store에서 추천 모델 보기';
  }

  @override
  String recommendedPurchaseOpenFailed(String store) {
    return '$store 링크를 열 수 없습니다';
  }

  @override
  String get recommendedPurchaseShortDisclosureAction => '설정에서 전체 고지 사항 보기';

  @override
  String get recommendedPurchaseShortDisclosureLead =>
      '이 링크는 제휴 수익 링크이며, 어댑터 인증이 아닙니다.';

  @override
  String get recommendedPurchaseStoreShopee => 'Shopee';

  @override
  String recommendedPurchaseViewOnStore(String store) {
    return '$store에서 보기';
  }

  @override
  String get semanticsFieldSeparator => ', ';

  @override
  String get settingsAdapterConcernsFooter =>
      '이 항목들은 어댑터의 자기 설명이 앞뒤가 맞지 않는 부분일 뿐 차량 데이터를 잘못 읽었다는 증거는 아닙니다. 판독값을 확인하는 유일한 방법은 두 번째 독립적인 계측값과 대조하는 것입니다(실차 가이드 참조).';

  @override
  String get settingsAdapterNoContradictions =>
      '자기 설명에서 모순이 발견되지 않았습니다. 이는 어댑터의 자기 설명이 일관된다는 뜻일 뿐 정품 칩이라는 증거도 아니고 보고하는 수치가 정확하다는 증거도 아닙니다. 복제품(클론)의 버전 문자열은 누군가 임의로 적어 넣은 텍스트에 불과합니다.';

  @override
  String get settingsAdapterNoVersion => '(보고된 버전 없음)';

  @override
  String get settingsAdapterSelfReportTitle => '어댑터 자체 보고 정보';

  @override
  String get settingsBatteryLabDialogBody =>
      '이 데이터는 리버스 엔지니어링 출처의 후보 자료일 뿐 제조사 문서가 아니며, 내 차량에 대한 Telltale의 지원도 아닙니다. 읽기 전용 쿼리라도 제어기를 깨울 수 있으며, 해독된 숫자가 그럴듯해 보여도 실제 차량에는 맞지 않을 수 있습니다.';

  @override
  String get settingsBatteryLabDialogTitle => '고전압 배터리 실험실 켜기';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      '이번 실행에서는 고전압 배터리 실험실이 꺼졌지만 설정을 저장할 수 없었습니다. 다음 실행 시 실험실이 다시 표시될 수 있으며, 모든 쿼리는 여전히 개별 확인을 거쳐야 합니다.';

  @override
  String get settingsBatteryLabEnableNotSaved =>
      '고전압 배터리 실험실 설정을 저장할 수 없어 꺼진 상태로 유지됩니다.';

  @override
  String get settingsBatteryLabEvidenceAck =>
      '출처 자료와 합성 테스트가 내 실제 차량에 적용됨을 증명하지 않는다는 점을 이해합니다';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      '출처가 완전하고 해시로 묶인 단발 읽기 전용 쿼리만 표시합니다. PID 설치, 폴링, 게이지 추가를 하지 않으며 연구 자료를 지원으로 간주하지도 않습니다.';

  @override
  String get settingsBatteryLabSwitchTitle => '고전압 배터리 실험실 (실험적)';

  @override
  String get settingsBatteryLabUnlockReadOnly => '단발 읽기 전용 쿼리만 잠금 해제';

  @override
  String get settingsBatteryLabWireAck =>
      '이 설정은 카탈로그 내 고정된 Mode 21/22 주소에 대한 단발 쿼리만 잠금 해제하며, 스캔, 진단 세션, 보안 액세스, 쓰기 또는 제어는 잠금 해제하지 않음을 이해합니다';

  @override
  String get settingsCancel => '취소';

  @override
  String get settingsCatalogChoose => '공식 카탈로그에서 선택';

  @override
  String get settingsCatalogCorrupt =>
      '공식 오프라인 카탈로그가 손상되었거나 불러올 수 없어 아무 데이터도 적용하지 않았습니다.';

  @override
  String get settingsCatalogNothingApplicable =>
      '이 공식 구성에는 현재 공식에 안전하게 적용할 수 있는 필드가 없어 기존 프로필을 그대로 유지합니다.';

  @override
  String get settingsCatalogScope =>
      '공식 카탈로그: 미국 EPA, 대만 경제부 에너지서(MOEA), 캐나다 NRCan. 각 스냅샷은 해당 출시 국가만 다루며 전 세계 모든 브랜드나 연식을 포함하지 않습니다.';

  @override
  String get settingsCatalogVerifying => '오프라인 카탈로그 검증 중…';

  @override
  String get settingsCatalogChooseMarket => '탐색할 공식 카탈로그 선택';

  @override
  String get settingsCatalogMarketTw => '대만 (MOEA 에너지서)';

  @override
  String get settingsCatalogMarketUs => '미국 (EPA)';

  @override
  String get settingsTwCertificationYear => '인증 연도';

  @override
  String get settingsTwMake => '대만 제조사(make)';

  @override
  String settingsTwPickerScope(int firstYear, int lastYear) {
    return '$firstYear–$lastYear 대만 시장 인증 행만 포함됩니다. 이 연도는 에너지서 인증 서기 연도이며 미국식 모델 연도(model year)가 아닙니다. 제조사/모델 문자열이 일치한다는 사실만으로 EPA 구성이 확인되는 것은 아닙니다.';
  }

  @override
  String get settingsTwPickerTitle => '대만 공식 차량 카탈로그';

  @override
  String get settingsTwReferenceMassNotCurb =>
      '기준 차량 중량은 curb mass(공차 중량)가 아니며 적용되지 않습니다.';

  @override
  String settingsTwWillApplyOnly(String fields) {
    return '$fields 항목만 적용됩니다. 기준 중량, VE, Cd, 전면 투영 면적, Crr 및 동력 전달 효율은 미결정 상태로 남습니다.';
  }

  @override
  String get settingsClose => '닫기';

  @override
  String get settingsConnectionSection => '연결';

  @override
  String get settingsDiagnosticsSection => '진단 통신 기록';

  @override
  String get settingsDisconnect => '연결 해제';

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return '동력 전달 효율 $percent %';
  }

  @override
  String settingsEpaApplyFields(int count) {
    return '공식 필드 $count개 적용';
  }

  @override
  String get settingsEpaChooseExact => '정확한 세부 구성 선택';

  @override
  String get settingsEpaCloseNoFields => '닫기 (적용할 필드 없음)';

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'EPA 구성 $epaId';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count기통';
  }

  @override
  String get settingsEpaDriveUnknown => '구동 방식 알 수 없음';

  @override
  String get settingsEpaFuelUnknown => '연료 알 수 없음';

  @override
  String get settingsEpaMake => '제조사 부문 (EPA make)';

  @override
  String get settingsEpaModel => '모델';

  @override
  String get settingsEpaNoConfigurations => '이 모델에 사용 가능한 구성이 없습니다';

  @override
  String get settingsEpaNoSafeFields =>
      '이 구성에는 현재 공식에 안전하게 적용할 수 있는 필드가 없으며, 어떠한 값도 추측하여 채우지 않습니다.';

  @override
  String get settingsEpaPickInOrder => '연식, 제조사 부문, 모델을 순서대로 선택하십시오';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return '$firstYear–$lastYear 미국 시장 스냅샷 구성만 포함됩니다. 이름이 같은 모델이라도 연식, 변속기, 연료 및 EPA ID로 구분해야 합니다.';
  }

  @override
  String get settingsEpaPickerTitle => '미국 EPA 공식 차량 카탈로그';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return '$fields 항목만 적용됩니다. 차량 중량, VE, Cd, 전면 투영 면적, Crr 및 동력 전달 효율은 미결정 상태로 남습니다.';
  }

  @override
  String get settingsEpaYear => '연식';

  @override
  String get settingsExperimentalSection => '실험적 기능';

  @override
  String get settingsFieldDisplacement => '배기량';

  @override
  String get settingsFieldDragCoefficient => '공기저항계수 Cd';

  @override
  String get settingsFieldDrivetrain => '구동 방식';

  @override
  String get settingsFieldFrontalArea => '전면 투영 면적';

  @override
  String get settingsFieldFuel => '연료';

  @override
  String get settingsFieldMass => '차량 중량';

  @override
  String get settingsFieldMassWithDriver => '차량 중량 (운전자 포함)';

  @override
  String get settingsFieldRollingResistance => '구름 저항 계수 Crr';

  @override
  String get settingsFieldVolumetricEfficiency => '체적 효율 VE';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return '공연비 $afr · 밀도 $density g/L';
  }

  @override
  String get settingsFuelAndDrivetrainSection => '연료 및 구동 방식';

  @override
  String get settingsFuelTypeLabel => '연료 종류';

  @override
  String get settingsGaugeSkinBody =>
      '단순히 색상만 바뀌는 것이 아닙니다 — 각 스킨마다 다이얼 형태, 바늘, 움직임이 모두 다릅니다. 다크 모드와 라이트 모드 배경 모두에서 작동합니다.';

  @override
  String get settingsGaugeSkinTitle => '게이지 스타일';

  @override
  String get settingsGoToConnect => '연결 화면으로 이동';

  @override
  String get settingsHeadline => '설정';

  @override
  String get settingsLicenseLegalese =>
      '고전압 배터리 데이터 출처, 변환 방식 및 재사용 조건이 이 앱에 함께 포함되어 있습니다.';

  @override
  String get settingsListSeparator => ', ';

  @override
  String get settingsManualCommandBody =>
      '어댑터에 명령 한 줄을 직접 보냅니다 — 예: ATI, ATDPN, 0100. 일반 폴링과 동일한 대기열에 들어가며 새치기하지 않습니다.';

  @override
  String get settingsManualCommandFieldLabel => '명령';

  @override
  String get settingsManualCommandNoContent => '(응답 내용 없음)';

  @override
  String get settingsManualCommandSend => '전송';

  @override
  String get settingsManualCommandTitle => '수동 명령';

  @override
  String get settingsNotConnected => '연결 안 됨';

  @override
  String get settingsOpenSourceLicenses => '오픈 소스 및 데이터 라이선스';

  @override
  String get settingsProfileConfirmAfterConnect => '연결 후 이 차량 확인';

  @override
  String get settingsProfileConfirmButton => '이번 연결에 대해 이 차량 확인';

  @override
  String get settingsProfileConfirmedButton => '이번 연결에서 확인됨';

  @override
  String get settingsProfileConfirmedDetail =>
      '이번 연결에 대해 프로필이 확인되었습니다. 값을 변경하거나 다시 연결하면 새로 확인해야 합니다.';

  @override
  String get settingsProfileEstimatesIntro =>
      '마력, 토크, 연료 소모량은 모두 이 파라미터들로부터 추정됩니다. 실제 차량에 가까울수록 추정값의 의미가 커집니다.';

  @override
  String get settingsProfileNameProvesNothing =>
      '브랜드 이름이나 VIN만으로는 차량 중량, 공기 저항, VE 또는 동력 전달 효율이 증명되지 않습니다.';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      '이번 연결에서 아직 확인되지 않았습니다. 실측 OBD 판독값은 계속 표시되지만 차량 중량, VE, 공기 저항으로 추정한 값은 표시되지 않습니다.';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      '확인하기 전에 먼저 이 차량에 연결하십시오. 확인 상태는 다시 연결할 때마다 만료되므로 이전 차량의 프로필이 다음 차량에 그대로 적용되는 일은 없습니다.';

  @override
  String get settingsProvenanceNoneExact =>
      '이 차량에 정확히 일치하는 것으로 결정된 필드가 없습니다. 범용 기본값, 직접 입력한 값, 이전 출처 값 모두 여전히 확인이 필요합니다.';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return '정확한 공식 출처가 있는 필드: $fields. 나머지 모든 필드는 여전히 하나씩 확인해야 합니다.';
  }

  @override
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  ) {
    return '출처: 공식/제조사 $official / $total개 필드 · 직접 입력 $user / $total · 범용 기본값 $generic / $total · 과학 모델 $scientific / $total';
  }

  @override
  String settingsProvenancePublishers(String publishers) {
    return '출처 기관: $publishers';
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
    return '결정 상태: 공식 정확 일치 $exact / $total개 필드 · 이번 세션 확인됨 $sessionConfirmed / $total · 미결정 $unresolved / $total · 모호함 $ambiguous / $total · 충돌 $conflict / $total';
  }

  @override
  String get settingsStandardsFooter =>
      '이 앱의 OBD2 구현은 SAE J1979 및 ELM327 데이터시트를 포함한 공개 표준을 따릅니다. 하드웨어 동작에 영향을 미치는 모든 공식과 AT 명령은 교차 검증을 거쳤으며 그 결과는 docs/protocol-deviations.zh-TW.md에 기록되어 있습니다. 이 앱은 Torque 또는 Torque Pro와 무관합니다.';

  @override
  String get settingsThemeDark => '다크';

  @override
  String get settingsThemeLight => '라이트';

  @override
  String get settingsThemeSystem => '시스템 설정 따름';

  @override
  String get settingsVehicleProfileSection => '차량 프로필';

  @override
  String get settingsVinConflict => 'VIN 충돌';

  @override
  String get settingsVinConflictDetail =>
      '제어기들이 서로 다른 VIN을 보고하여 차량 식별 정보를 확인할 수 없습니다. 모든 후보 값을 폐기했습니다.';

  @override
  String get settingsVinNotRead => '아직 VIN을 읽지 않음';

  @override
  String get settingsVinNotReadConnectedDetail =>
      '현재 차량에서 Mode 09 VIN을 읽을 수 있으며 식별 상태는 이번 연결에서만 유지됩니다. 단, 원본 진단 통신 기록에는 여전히 VIN이 포함될 수 있습니다.';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      '연결되면 차량이 자체 보고하는 VIN을 읽을 수 있으며, 식별 정보는 다음 연결로 넘어가지 않습니다. 단, 원본 진단 통신 기록에는 여전히 VIN이 포함될 수 있습니다.';

  @override
  String get settingsVinRead => 'VIN 읽기';

  @override
  String get settingsVinReading => '읽는 중…';

  @override
  String get settingsVinReportedDetail =>
      'VIN은 차량이 스스로 보고하는 식별 정보일 뿐 모델 사양을 검증해 주지 않습니다. 식별 상태는 다음 연결로 이어지지 않으나 진단 통신 기록에는 여전히 VIN이 포함될 수 있습니다.';

  @override
  String get settingsVinSimulatorReported => '시뮬레이터 보고 VIN';

  @override
  String get settingsVinUnavailable => 'VIN 확인 불가';

  @override
  String get settingsVinUnavailableDetail =>
      '차량이 VIN을 제공하지 않거나, 응답이 불완전했거나, 이번 연결에서 읽히지 않았을 수 있습니다. 어떠한 값도 추측하거나 임의로 글자를 채워 넣지 않습니다.';

  @override
  String get settingsVinVehicleReported => '차량 보고 VIN';

  @override
  String get startupCannotComplete => '시작 검사를 완료할 수 없습니다';

  @override
  String get startupChecking => '로컬 공유 캐시 및 텔레메트리 기록 확인 중';

  @override
  String get startupRestartHint =>
      '로컬 공유 캐시 또는 텔레메트리 기록의 상태를 확인할 수 없습니다. 잘못된 파일을 덮어쓰거나 삭제하거나 공유하지 않도록 Telltale을 완전히 종료한 뒤 다시 실행해 주십시오.';

  @override
  String get startupRestartRequired => '안전하게 계속하려면 앱을 다시 시작해야 합니다';

  @override
  String get startupRetry => '다시 시도';

  @override
  String get startupRetryHint =>
      'Telltale을 포그라운드 상태로 유지한 채 다른 파일 작업이 끝난 뒤 다시 시도하십시오. 시작 검사가 완료될 때까지 기록, 재생, 내보내기 및 삭제 기능은 닫혀 있습니다.';

  @override
  String get telemetryArtifactRestartRequired =>
      '로컬 파일 작업 상태를 확인할 수 없습니다. 계속하기 전에 Telltale을 완전히 종료한 뒤 다시 여십시오';

  @override
  String get telemetryBlockedByRecorder => '먼저 기록을 중지하고 저장하십시오';

  @override
  String get telemetryCancel => '취소';

  @override
  String get telemetryDamagedCollision =>
      '완료된 파일과 미완료 파일이 동일한 ID를 공유하고 있어 어느 쪽도 선택하지 않았습니다';

  @override
  String get telemetryDamagedCorrupt => '기록이 손상되어 안전하게 읽을 수 없습니다';

  @override
  String telemetryDamagedFileTime(String time) {
    return '파일 시간 $time';
  }

  @override
  String get telemetryDelete => '삭제';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return '$id(파일 시간 $time) 항목을 삭제합니다. 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get telemetryDeleteDamagedTitle => '이 손상된 기록을 삭제하시겠습니까?';

  @override
  String get telemetryDeleteDamagedTooltip => '손상된 기록 삭제';

  @override
  String telemetryDeleteFailed(String reason) {
    return '삭제가 완료되지 않았습니다: $reason';
  }

  @override
  String get telemetryDeleteNeedsConfirmation => '먼저 이 삭제 작업을 확인하십시오';

  @override
  String telemetryDeleteSessionBody(String time) {
    return '$time의 기록을 삭제합니다. 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get telemetryDeleteSessionTitle => '이 로컬 기록을 삭제하시겠습니까?';

  @override
  String get telemetryDemoData => '내장 시뮬레이터 데이터';

  @override
  String get telemetryDismissNotice => '닫기';

  @override
  String get telemetryEndedByBackground => 'Telltale이 백그라운드로 전환되어 중지됨';

  @override
  String get telemetryEndedByConfigurationChanged => 'PID 선택이 변경됨';

  @override
  String get telemetryEndedByDisconnect => '연결이 끊어져 중지됨';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return '$minutes분 제한에 도달함';
  }

  @override
  String get telemetryEndedByLibrarySizeLimit => '로컬 기록 저장 공간이 가득 참';

  @override
  String get telemetryEndedByRecoveredAfterInterruption => '이전 중단 이후 복구됨';

  @override
  String get telemetryEndedBySessionReplacement => '연결 세션이 교체됨';

  @override
  String get telemetryEndedBySessionSizeLimit => '이 기록의 용량 제한에 도달함';

  @override
  String get telemetryEndedByStorageBackpressure => '저장소 쓰기 속도가 따라가지 못함';

  @override
  String get telemetryEndedByStorageFailure => '저장 실패';

  @override
  String get telemetryEndedByUser => '사용자가 중지함';

  @override
  String get telemetryExport => '내보내기';

  @override
  String get telemetryExportCsv => 'CSV 내보내기';

  @override
  String telemetryExportFailed(String reason) {
    return '내보내기가 완료되지 않았습니다: $reason';
  }

  @override
  String get telemetryExportJson => 'JSON 내보내기';

  @override
  String get telemetryExportSheetTitle => '로컬 기록 내보내기';

  @override
  String telemetryGapCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '공백 $count개',
    );
    return '$_temp0';
  }

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '저장된 그룹 $count개 — 오프라인 재생 및 내보내기 가능',
    );
    return '$_temp0';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit개 그룹';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '추가 그룹 $count개 미표시',
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
    return '로컬 저장소: 그룹 $groupLimit개 중 $groups개, $byteLimit MiB 중 $used MiB 사용';
  }

  @override
  String get telemetryNotConnected => '연결 안 됨';

  @override
  String get telemetryOfflineSampledReplay => '오프라인 샘플링 재생';

  @override
  String get telemetryOpenHistory => '로컬 기록 열기';

  @override
  String get telemetryPause => '일시정지';

  @override
  String get telemetryPendingOwnerRecovery =>
      '현재 프로세스가 아직 작업을 보유하고 있습니다. 이 상태가 계속되면 Telltale을 완전히 종료한 뒤 다시 여십시오';

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetryPlay => '재생';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return '활성화한 OBD 신호만 기록하며 위치, VIN 또는 계정 데이터는 포함하지 않습니다. 트렌드 차트는 최대 $laneLimit개 신호를 표시하지만, 기록 파일은 활성화된 신호 $activeCount개를 모두 보관하고 차량 가정치에 기반한 추정 마력과 추정 연료 소모율을 함께 추가합니다.';
  }

  @override
  String get telemetryRecorderPhaseAwaitingValues => '기록 중 — 아직 수신된 값 없음';

  @override
  String get telemetryRecorderPhaseCompleted => '기록 저장됨';

  @override
  String get telemetryRecorderPhaseFailed => '기록 저장 실패';

  @override
  String get telemetryRecorderPhaseFinalizing => '기록 저장 중';

  @override
  String get telemetryRecorderPhaseIdle => '포그라운드 로컬 기록';

  @override
  String get telemetryRecorderPhasePreparing => '기록 준비 중';

  @override
  String get telemetryRecorderPhaseRecording => '기록 중';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return '기록 중 $duration';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '유효한 값이 없는 미완료 파일 $count개를 정리했습니다',
    );
    return '$_temp0';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '손상되었거나 충돌하는 파일 $count개는 변경하지 않고 그대로 두었습니다',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryDamagedNote =>
      '손상된 내용은 재생이나 내보내기에 절대 사용되지 않으며, 안전한 상태에서만 수동으로 삭제할 수 있습니다.';

  @override
  String telemetryRecoveryInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '중단되었던 기록 $count개를 안전하게 봉인했습니다',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryTitle => '시작 시 기록 파일 검사를 마쳤습니다';

  @override
  String get telemetryReload => '다시 불러오기';

  @override
  String telemetryReplayBreakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '끊김 $count회',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayLoadFailed => '기록을 불러올 수 없습니다';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return '재생 위치 $percent%';
  }

  @override
  String telemetryReplaySampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '샘플링 지점 $count개',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayTitle => '기록 재생';

  @override
  String get telemetryReplayUnreadable => '기록이 손상되었거나 읽을 수 없습니다';

  @override
  String get telemetryRestartToRepairSave =>
      '저장이 완료되지 않았습니다 — 기록을 복구하려면 Telltale을 다시 시작하십시오';

  @override
  String get telemetryRestartToRepairStartup =>
      '시작 정리 작업이 완료되지 않았습니다 — 기록을 복구하려면 Telltale을 다시 시작하십시오';

  @override
  String get telemetryReturnToTrends => '트렌드로 돌아가기';

  @override
  String get telemetryRigData => '테스트 리그 데이터';

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetrySessionsDamaged => '손상된 기록 파일';

  @override
  String get telemetrySessionsEmpty => '아직 로컬 기록이 없습니다\n연결한 후 기록을 시작하십시오';

  @override
  String get telemetrySessionsLoadFailed => '불러올 수 없음 — 다시 시도하십시오';

  @override
  String get telemetrySessionsReplayable => '재생 가능한 기록';

  @override
  String get telemetrySessionsTitle => '로컬 기록';

  @override
  String telemetrySignalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '신호 $count개',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStartBusy => '다른 기록 또는 파일 작업이 아직 끝나지 않았습니다';

  @override
  String get telemetryStartCannotCreateFile => '기록 파일을 생성할 수 없습니다';

  @override
  String get telemetryStartInvalidConfiguration =>
      '이 PID 선택은 안전하게 기록할 수 없습니다 — 정의를 확인하십시오';

  @override
  String get telemetryStartInvalidatedBackground =>
      'Telltale이 백그라운드로 전환되어 기록이 시작되지 않았습니다';

  @override
  String get telemetryStartInvalidatedDisconnect => '연결이 끊어져 기록이 시작되지 않았습니다';

  @override
  String get telemetryStartInvalidatedSessionReplacement =>
      '연결 세션이 교체되어 기록이 시작되지 않았습니다';

  @override
  String get telemetryStartLibraryByteLimit =>
      '기록할 로컬 저장 공간이 부족합니다 — 먼저 일부 기록을 내보내거나 삭제하십시오';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return '로컬 기록이 최대 한도($limit개)에 도달했습니다 — 먼저 일부 기록을 내보내거나 삭제하십시오';
  }

  @override
  String get telemetryStartMoving => '먼저 차량을 주차하십시오';

  @override
  String get telemetryStartNeedsActivePid => '먼저 최소 1개의 PID를 활성화하십시오';

  @override
  String get telemetryStartNeedsConnection => '기록을 시작하기 전에 먼저 연결하십시오';

  @override
  String get telemetryStartNeedsForeground =>
      '기록을 시작하기 전에 Telltale을 포그라운드로 전환하십시오';

  @override
  String get telemetryStartRecording => '기록이 시작되었습니다';

  @override
  String get telemetryStartRecordingButton => '기록 시작';

  @override
  String get telemetryStartSpeedUnknown =>
      '차량이 정차 상태인지 확인할 수 없습니다 — 먼저 연결을 해제하십시오';

  @override
  String get telemetryStartTooManyPids =>
      '기록에는 추정 마력과 추정 연료 소모량 열이 유지됩니다 — 먼저 일부 PID를 비활성화하십시오';

  @override
  String get telemetryStarting => '시작 중';

  @override
  String get telemetryStatusBusError => '버스 오류';

  @override
  String telemetryStatusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '상태 $count개',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStatusFormulaError => '공식 오류';

  @override
  String get telemetryStatusHeaderMismatch => '헤더가 현재 버스와 일치하지 않음';

  @override
  String get telemetryStatusNoAnswer => '응답 없음 — 다시 시도 예정';

  @override
  String get telemetryStatusStale => '데이터 오래됨';

  @override
  String get telemetryStatusUnsafeServiceRefusal => '읽기 전용 쿼리가 아님 — 전송하지 않았습니다';

  @override
  String get telemetryStatusUnsupported => '제어기가 이 항목을 지원하지 않는다고 응답했습니다';

  @override
  String get telemetryStopAndSave => '중지 및 저장';

  @override
  String telemetryValueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '유효 값 $count개',
    );
    return '$_temp0';
  }

  @override
  String get transcriptDelete => '삭제';

  @override
  String get transcriptDeleteBusy => '다른 파일 작업이 아직 끝나지 않았습니다.';

  @override
  String get transcriptDeleteFailed => '이전 연결의 진단 통신 기록을 삭제할 수 없습니다.';

  @override
  String get transcriptDeleteRefusedBySafety =>
      '현재 차량 속도 또는 연결 상태에서는 진단 통신 기록을 삭제할 수 없습니다.';

  @override
  String get transcriptExport => '내보내기';

  @override
  String get transcriptExportButton => '통신 기록 내보내기';

  @override
  String get transcriptExportExplanation =>
      '이번 연결의 초기 핸드셰이크와 가장 최근의 원본 통신 데이터를 보관하며, 장시간 연결로 인해 중간 부분이 생략된 경우 파일에 그 사실이 명시됩니다. 차량에서 데이터를 읽지 못할 때는 화면의 한 줄짜리 메시지보다 이 통신 기록을 내보내어 가져오시는 것이 훨씬 큰 도움이 됩니다.';

  @override
  String transcriptExportFailed(String error) {
    return '내보내기 실패: $error';
  }

  @override
  String get transcriptExportWithHex => '16진수(hex) 포함';

  @override
  String get transcriptNothingToExport => '내보낼 진단 통신 기록이 없습니다.';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return '$timestamp에 기록됨, $size. 시스템이 Telltale을 강제 종료했거나 휴대폰 전원이 꺼졌을 때도 보존된 기록입니다.';
  }

  @override
  String get transcriptRecoveredChanged =>
      '이전 연결의 진단 통신 기록이 변경되었습니다 — 다시 확인하십시오.';

  @override
  String get transcriptRecoveredTitle => '이전 연결의 진단 통신 기록';

  @override
  String transcriptSizeBytes(int bytes) {
    String _temp0 = intl.Intl.pluralLogic(
      bytes,
      locale: localeName,
      other: '$bytes바이트',
    );
    return '$_temp0';
  }

  @override
  String get trendAxisNow => '현재';

  @override
  String get trendChooseSignals => '신호 선택';

  @override
  String get trendLiveData => '실시간 데이터';

  @override
  String get trendNoSignalsBody => '먼저 PID 페이지에서 모니터링할 신호를 활성화하십시오.';

  @override
  String get trendNoSignalsTitle => '사용 가능한 트렌드 신호 없음';

  @override
  String get trendNoUnits => '단위 없음';

  @override
  String trendPickSignalsBody(int limit) {
    return '최대 $limit개의 신호를 비교할 수 있습니다. 이 선택은 폴링되는 PID 목록을 변경하지 않습니다.';
  }

  @override
  String get trendPickSignalsTitle => '트렌드 신호 선택';

  @override
  String trendRemoveSignal(String name) {
    return '$name 제거';
  }

  @override
  String get trendSelectionSaveFailed => '트렌드 표시 선택을 저장할 수 없습니다';

  @override
  String trendSheetBody(int limit) {
    return '최대 $limit개까지 선택하십시오. 이 선택은 차트 표시만 변경하며 PID 폴링이나 진행 중인 기록은 변경하지 않습니다.';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return '완료 · $selected/$limit';
  }

  @override
  String get trendSignalNoLongerActive => '선택한 신호 중 하나가 더 이상 PID 모니터링 목록에 없습니다';

  @override
  String get trendSignalsHeading => '트렌드 신호';

  @override
  String trendTooManySelected(int limit) {
    return '최대 $limit개까지 선택 가능';
  }

  @override
  String trendWindowSemantics(int seconds) {
    return '최근 $seconds초 표시 중';
  }

  @override
  String get wearBack => '뒤로';

  @override
  String get wearBatteryVoltageLabel => '배터리';

  @override
  String get wearBleAdapters => 'BLE 어댑터';

  @override
  String get wearCancel => '취소';

  @override
  String get wearConfirmVehicle => '차량 확인';

  @override
  String get wearConfirmVehicleAccept => '예, 이 차량';

  @override
  String get wearConfirmVehicleBody =>
      '확인하면 이번 연결이 유지되는 동안 이 모델의 읽기 전용 배터리 쿼리를 주기적으로 폴링합니다. 잘못된 모델을 선택하면 그럴듯해 보이지만 틀린 숫자가 반환될 수 있으므로 확실하지 않으면 취소하십시오.';

  @override
  String wearConnectFailed(String adapter) {
    return '연결 실패: $adapter';
  }

  @override
  String get wearConnecting => '연결 중…';

  @override
  String get wearDemoSimulator => '데모 시뮬레이터';

  @override
  String get wearDisconnect => '연결 해제';

  @override
  String get wearDisconnectQuestion => '연결을 해제하시겠습니까?';

  @override
  String get wearNoDevicesFound => '기기를 찾지 못함';

  @override
  String get wearPermissionBluetooth => '블루투스';

  @override
  String get wearPermissionLocation => '위치';

  @override
  String get wearScanAgain => '재스캔';

  @override
  String get wearScanFailed => '스캔 실패 — 다시 시도하십시오';

  @override
  String wearScanPermissionNeeded(String permission) {
    return '스캔하려면 $permission 권한이 필요합니다';
  }

  @override
  String wearScanPermissionPermanentlyDenied(String permission) {
    return '$permission 권한이 영구적으로 거부되었습니다 — 시스템 설정에서 켠 뒤 다시 시도하십시오';
  }

  @override
  String get wearScanning => '스캔 중…';

  @override
  String get telemetryRecorderNotRecording => '기록 중 아님';

  @override
  String get dtcKindStored => '저장됨';

  @override
  String get dtcKindPending => '보류 중';

  @override
  String get dtcKindPermanent => '영구';

  @override
  String get dtcKindStoredExplanation => '확정된 고장이며 대시보드 고장 표시등이 대개 켜집니다.';

  @override
  String get dtcKindPendingExplanation => '한 번 감지되었으나 아직 확정 임계치에 도달하지 않았습니다.';

  @override
  String get dtcKindPermanentExplanation =>
      '진단기로 삭제할 수 없습니다. 수리가 완료된 것을 ECU가 스스로 확인한 뒤에만 직접 지웁니다.';

  @override
  String get dtcSystemPowertrain => '파워트레인';

  @override
  String get dtcSystemChassis => '섀시';

  @override
  String get dtcSystemBody => '바디';

  @override
  String get dtcSystemNetwork => '네트워크';

  @override
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions =>
      '연료 및 공기 계량, 보조 배출가스 제어';

  @override
  String get dtcSubsystemFuelAirMetering => '연료 및 공기 계량';

  @override
  String get dtcSubsystemFuelAirMeteringInjectorCircuit =>
      '연료 및 공기 계량 (인젝터 회로)';

  @override
  String get dtcSubsystemIgnitionOrMisfire => '점화 시스템 또는 실화';

  @override
  String get dtcSubsystemAuxiliaryEmissionControls => '보조 배출가스 제어';

  @override
  String get dtcSubsystemSpeedAndIdleControl => '차속 제어 및 공회전(아이들) 제어 시스템';

  @override
  String get dtcSubsystemComputerOutputCircuit => '컴퓨터 출력 회로';

  @override
  String get dtcSubsystemTransmission => '변속기';

  @override
  String get dtcSubsystemControlModuleSignals => '제어 모듈, 입력 및 출력 신호';

  @override
  String get dtcDescriptionB0001 => '운전석 에어백 전개 제어 고장';

  @override
  String get dtcDescriptionP0011 => '캠축 위치 A — 타이밍 과진각 또는 시스템 성능 이상 (뱅크 1)';

  @override
  String get dtcDescriptionP0014 => '캠축 위치 B — 타이밍 과진각 또는 시스템 성능 이상 (뱅크 1)';

  @override
  String get dtcDescriptionP0016 => '크랭크축 위치 – 캠축 위치 상관관계 이상 (뱅크 1 센서 A)';

  @override
  String get dtcDescriptionP0087 => '연료 레일/시스템 압력 너무 낮음';

  @override
  String get dtcDescriptionP0088 => '연료 레일/시스템 압력 너무 높음';

  @override
  String get dtcDescriptionP0100 => '질량 공기 유량 (MAF) 센서 회로 고장';

  @override
  String get dtcDescriptionP0101 => '질량 공기 유량 센서 범위/성능 문제';

  @override
  String get dtcDescriptionP0102 => '질량 공기 유량 센서 회로 낮은 입력';

  @override
  String get dtcDescriptionP0103 => '질량 공기 유량 센서 회로 높은 입력';

  @override
  String get dtcDescriptionP0105 => '흡기 매니폴드 절대 압력/대기압 센서 회로 고장';

  @override
  String get dtcDescriptionP0106 => '흡기 매니폴드 절대 압력 센서 범위/성능 문제';

  @override
  String get dtcDescriptionP0107 => '흡기 매니폴드 절대 압력 센서 회로 낮은 입력';

  @override
  String get dtcDescriptionP0108 => '흡기 매니폴드 절대 압력 센서 회로 높은 입력';

  @override
  String get dtcDescriptionP0110 => '흡기 온도 센서 회로 고장';

  @override
  String get dtcDescriptionP0111 => '흡기 온도 센서 범위/성능 문제';

  @override
  String get dtcDescriptionP0112 => '흡기 온도 센서 회로 낮은 입력';

  @override
  String get dtcDescriptionP0113 => '흡기 온도 센서 회로 높은 입력';

  @override
  String get dtcDescriptionP0115 => '엔진 냉각수 온도 센서 회로 고장';

  @override
  String get dtcDescriptionP0116 => '엔진 냉각수 온도 센서 범위/성능 문제';

  @override
  String get dtcDescriptionP0117 => '엔진 냉각수 온도 센서 회로 낮은 입력';

  @override
  String get dtcDescriptionP0118 => '엔진 냉각수 온도 센서 회로 높은 입력';

  @override
  String get dtcDescriptionP0120 => '스로틀 위치 센서 회로 고장';

  @override
  String get dtcDescriptionP0121 => '스로틀 위치 센서 범위/성능 문제';

  @override
  String get dtcDescriptionP0122 => '스로틀 위치 센서 회로 낮은 입력';

  @override
  String get dtcDescriptionP0123 => '스로틀 위치 센서 회로 높은 입력';

  @override
  String get dtcDescriptionP0125 => '폐루프 연료 제어를 위한 냉각수 온도 불충분';

  @override
  String get dtcDescriptionP0128 => '냉각수 온도가 서모스탯 조절 온도보다 낮음';

  @override
  String get dtcDescriptionP0130 => '산소 센서 회로 고장 (뱅크 1 센서 1)';

  @override
  String get dtcDescriptionP0131 => '산소 센서 회로 낮은 전압 (뱅크 1 센서 1)';

  @override
  String get dtcDescriptionP0132 => '산소 센서 회로 높은 전압 (뱅크 1 센서 1)';

  @override
  String get dtcDescriptionP0133 => '산소 센서 회로 응답 지연 (뱅크 1 센서 1)';

  @override
  String get dtcDescriptionP0134 => '산소 센서 회로에서 신호 활동이 감지되지 않음 (뱅크 1 센서 1)';

  @override
  String get dtcDescriptionP0135 => '산소 센서 히터 회로 고장 (뱅크 1 센서 1)';

  @override
  String get dtcDescriptionP0136 => '산소 센서 회로 고장 (뱅크 1 센서 2)';

  @override
  String get dtcDescriptionP0137 => '산소 센서 회로 낮은 전압 (뱅크 1 센서 2)';

  @override
  String get dtcDescriptionP0138 => '산소 센서 회로 높은 전압 (뱅크 1 센서 2)';

  @override
  String get dtcDescriptionP0140 => '산소 센서 회로에서 신호 활동이 감지되지 않음 (뱅크 1 센서 2)';

  @override
  String get dtcDescriptionP0141 => '산소 센서 히터 회로 고장 (뱅크 1 센서 2)';

  @override
  String get dtcDescriptionP0150 => '산소 센서 회로 고장 (뱅크 2 센서 1)';

  @override
  String get dtcDescriptionP0155 => '산소 센서 히터 회로 고장 (뱅크 2 센서 1)';

  @override
  String get dtcDescriptionP0156 => '산소 센서 회로 고장 (뱅크 2 센서 2)';

  @override
  String get dtcDescriptionP0161 => '산소 센서 히터 회로 고장 (뱅크 2 센서 2)';

  @override
  String get dtcDescriptionP0170 => '연료 보정(Fuel Trim) 고장 (뱅크 1)';

  @override
  String get dtcDescriptionP0171 => '혼합기 너무 희박함 (뱅크 1)';

  @override
  String get dtcDescriptionP0172 => '혼합기 너무 농후함 (뱅크 1)';

  @override
  String get dtcDescriptionP0173 => '연료 보정(Fuel Trim) 고장 (뱅크 2)';

  @override
  String get dtcDescriptionP0174 => '혼합기 너무 희박함 (뱅크 2)';

  @override
  String get dtcDescriptionP0175 => '혼합기 너무 농후함 (뱅크 2)';

  @override
  String get dtcDescriptionP0190 => '연료 레일 압력 센서 회로 고장';

  @override
  String get dtcDescriptionP0201 => '인젝터 회로 고장 또는 단선 — 실린더 1';

  @override
  String get dtcDescriptionP0202 => '인젝터 회로 고장 또는 단선 — 실린더 2';

  @override
  String get dtcDescriptionP0203 => '인젝터 회로 고장 또는 단선 — 실린더 3';

  @override
  String get dtcDescriptionP0204 => '인젝터 회로 고장 또는 단선 — 실린더 4';

  @override
  String get dtcDescriptionP0217 => '엔진 과열 상태';

  @override
  String get dtcDescriptionP0221 => '스로틀/페달 위치 센서 B 범위/성능 문제';

  @override
  String get dtcDescriptionP0222 => '스로틀/페달 위치 센서 B 회로 낮은 입력';

  @override
  String get dtcDescriptionP0223 => '스로틀/페달 위치 센서 B 회로 높은 입력';

  @override
  String get dtcDescriptionP0234 => '터보차저/슈퍼차저 과급 압력 과다(오버부스트) 상태';

  @override
  String get dtcDescriptionP0299 => '터보차저/슈퍼차저 A 과급 압력 부족(언더부스트) 상태';

  @override
  String get dtcDescriptionP0300 => '무작위 또는 다중 실린더 실화 감지';

  @override
  String get dtcDescriptionP0301 => '실린더 1 실화 감지';

  @override
  String get dtcDescriptionP0302 => '실린더 2 실화 감지';

  @override
  String get dtcDescriptionP0303 => '실린더 3 실화 감지';

  @override
  String get dtcDescriptionP0304 => '실린더 4 실화 감지';

  @override
  String get dtcDescriptionP0305 => '실린더 5 실화 감지';

  @override
  String get dtcDescriptionP0306 => '실린더 6 실화 감지';

  @override
  String get dtcDescriptionP0307 => '실린더 7 실화 감지';

  @override
  String get dtcDescriptionP0308 => '실린더 8 실화 감지';

  @override
  String get dtcDescriptionP0316 => '시동 직후 실화 감지';

  @override
  String get dtcDescriptionP0325 => '노크 센서 회로 고장 (뱅크 1)';

  @override
  String get dtcDescriptionP0326 => '노크 센서 범위/성능 문제 (뱅크 1)';

  @override
  String get dtcDescriptionP0327 => '노크 센서 회로 낮은 입력 (뱅크 1)';

  @override
  String get dtcDescriptionP0328 => '노크 센서 회로 높은 입력 (뱅크 1)';

  @override
  String get dtcDescriptionP0330 => '노크 센서 회로 고장 (뱅크 2)';

  @override
  String get dtcDescriptionP0335 => '크랭크축 위치 센서 회로 고장';

  @override
  String get dtcDescriptionP0336 => '크랭크축 위치 센서 범위/성능 문제';

  @override
  String get dtcDescriptionP0340 => '캠축 위치 센서 회로 고장';

  @override
  String get dtcDescriptionP0341 => '캠축 위치 센서 범위/성능 문제';

  @override
  String get dtcDescriptionP0351 => '점화 코일 A 1차/2차 회로 고장';

  @override
  String get dtcDescriptionP0352 => '점화 코일 B 1차/2차 회로 고장';

  @override
  String get dtcDescriptionP0353 => '점화 코일 C 1차/2차 회로 고장';

  @override
  String get dtcDescriptionP0354 => '점화 코일 D 1차/2차 회로 고장';

  @override
  String get dtcDescriptionP0355 => '점화 코일 E 1차/2차 회로 고장';

  @override
  String get dtcDescriptionP0356 => '점화 코일 F 1차/2차 회로 고장';

  @override
  String get dtcDescriptionP0400 => '배기가스 재순환 (EGR) 유량 고장';

  @override
  String get dtcDescriptionP0401 => '배기가스 재순환 (EGR) 유량 부족';

  @override
  String get dtcDescriptionP0402 => '배기가스 재순환 (EGR) 유량 과다';

  @override
  String get dtcDescriptionP0403 => '배기가스 재순환 (EGR) 제어 회로 고장';

  @override
  String get dtcDescriptionP0404 => '배기가스 재순환 (EGR) 제어 회로 범위/성능 문제';

  @override
  String get dtcDescriptionP0410 => '2차 공기 분사 시스템 고장';

  @override
  String get dtcDescriptionP0411 => '2차 공기 분사 시스템 부적절한 유량 감지';

  @override
  String get dtcDescriptionP0412 => '2차 공기 분사 시스템 전환 밸브 A 회로 고장';

  @override
  String get dtcDescriptionP0420 => '촉매 시스템 효율 임계치 미달 (뱅크 1)';

  @override
  String get dtcDescriptionP0430 => '촉매 시스템 효율 임계치 미달 (뱅크 2)';

  @override
  String get dtcDescriptionP0440 => '증발가스 제어 시스템 고장';

  @override
  String get dtcDescriptionP0441 => '증발가스 제어 시스템 부적절한 퍼지 유량';

  @override
  String get dtcDescriptionP0442 => '증발가스 제어 시스템 누출 감지 (소량 누출)';

  @override
  String get dtcDescriptionP0443 => '증발가스 제어 시스템 퍼지 제어 밸브 회로 고장';

  @override
  String get dtcDescriptionP0446 => '증발가스 제어 시스템 벤트 제어 회로 고장';

  @override
  String get dtcDescriptionP0447 => '증발가스 제어 시스템 벤트 제어 회로 단선';

  @override
  String get dtcDescriptionP0449 => '증발가스 제어 시스템 벤트 밸브/솔레노이드 회로 고장';

  @override
  String get dtcDescriptionP0451 => '증발가스 제어 시스템 압력 센서 범위/성능 문제';

  @override
  String get dtcDescriptionP0452 => '증발가스 제어 시스템 압력 센서 회로 낮은 입력';

  @override
  String get dtcDescriptionP0453 => '증발가스 제어 시스템 압력 센서 회로 높은 입력';

  @override
  String get dtcDescriptionP0455 => '증발가스 제어 시스템 누출 감지 (대량 누출)';

  @override
  String get dtcDescriptionP0456 => '증발가스 제어 시스템 누출 감지 (극소량 누출)';

  @override
  String get dtcDescriptionP0480 => '냉각 팬 1 제어 회로 고장';

  @override
  String get dtcDescriptionP0500 => '차속 센서 고장';

  @override
  String get dtcDescriptionP0505 => '공회전(아이들) 제어 시스템 고장';

  @override
  String get dtcDescriptionP0506 => '공회전(아이들) 제어 시스템 RPM이 예상보다 낮음';

  @override
  String get dtcDescriptionP0507 => '공회전(아이들) 제어 시스템 RPM이 예상보다 높음';

  @override
  String get dtcDescriptionP0508 => '공회전(아이들) 제어 시스템 회로 낮은 입력';

  @override
  String get dtcDescriptionP0509 => '공회전(아이들) 제어 시스템 회로 높은 입력';

  @override
  String get dtcDescriptionP0560 => '시스템 전압 고장';

  @override
  String get dtcDescriptionP0562 => '시스템 전압 낮음';

  @override
  String get dtcDescriptionP0563 => '시스템 전압 높음';

  @override
  String get dtcDescriptionP0603 => '내부 제어 모듈 상시 유지 메모리 (KAM) 오류';

  @override
  String get dtcDescriptionP0605 => '내부 제어 모듈 읽기 전용 메모리 (ROM) 오류';

  @override
  String get dtcDescriptionP0606 => 'ECM/PCM 프로세서 고장';

  @override
  String get dtcDescriptionP0700 =>
      '변속기 제어 모듈(TCM)이 고장 표시등 점등을 요청함 — 실제 고장 코드는 변속기 모듈에 있으므로 별도로 읽어야 합니다';

  @override
  String get dtcDescriptionP0701 => '변속기 제어 시스템 범위/성능 문제';

  @override
  String get dtcDescriptionP0702 => '변속기 제어 시스템 전기 고장';

  @override
  String get dtcDescriptionP0705 => '변속기 레인지(인히비터) 센서 회로 고장';

  @override
  String get dtcDescriptionP0715 => '입력축/터빈 속도 센서 회로 고장';

  @override
  String get dtcDescriptionP0720 => '출력축 속도 센서 회로 고장';

  @override
  String get dtcDescriptionP0730 => '부적절한 기어비';

  @override
  String get dtcDescriptionP0740 => '토크 컨버터 클러치 회로 고장';

  @override
  String get dtcDescriptionP0741 => '토크 컨버터 클러치 해제 상태 고착';

  @override
  String get dtcDescriptionP0750 => '변속 솔레노이드 A 고장';

  @override
  String get dtcDescriptionP0755 => '변속 솔레노이드 B 고장';

  @override
  String get dtcDescriptionP2135 => '스로틀 위치 센서 A/B 전압 상관관계 이상';

  @override
  String get dtcDescriptionU0100 => 'ECM/PCM과 통신 두절';

  @override
  String get dtcDescriptionU0101 => '변속기 제어 모듈과 통신 두절';

  @override
  String get dtcDescriptionU0121 => 'ABS 제어 모듈과 통신 두절';

  @override
  String get dtcDescriptionU0140 => '바디 제어 모듈(BCM)과 통신 두절';

  @override
  String get dtcDescriptionU0155 => '계기판(클러스터) 제어 모듈과 통신 두절';

  @override
  String get gaugeSkinCluster => '클러스터';

  @override
  String get gaugeSkinClusterDescription =>
      '순정 계기판과 같은 모습입니다. 바늘, 270도 다이얼, 깊이감 있는 문자판을 갖췄습니다.';

  @override
  String get gaugeSkinMinimal => '미니멀';

  @override
  String get gaugeSkinMinimalDescription =>
      '반원형 호만 있고 바늘이나 눈금이 없습니다. 움직임이 아니라 숫자를 바로 읽도록 설계되었습니다.';

  @override
  String get gaugeSkinTrack => '트랙';

  @override
  String get gaugeSkinTrackDescription =>
      '분할 바 형태이며 보간 애니메이션(스무딩)이 없습니다. 중간 과정 없이 들어온 값의 위치에 즉시 표시됩니다.';

  @override
  String get gaugeSkinClassic => '클래식';

  @override
  String get gaugeSkinClassicDescription =>
      '인쇄된 문자판과 원형 전체에 배치된 숫자, 기계식 시계처럼 차분하게 자리 잡는 바늘을 갖췄습니다.';

  @override
  String get gaugeSkinNight => '나이트';

  @override
  String get gaugeSkinNightDescription =>
      '야간 주행용입니다. 낮은 밝기, 완만한 호, 애니메이션 없음 — 운전자의 주의를 최소한으로만 끕니다.';

  @override
  String get derivedAirflowSourceMaf => 'MAF 센서';

  @override
  String get derivedAirflowSourceSpeedDensity => 'Speed-Density 추정';

  @override
  String get derivedAirflowSourceUnavailable => '공기 질량 사용 불가';

  @override
  String get derivedFuelSourceStoichiometric => '이론공연비(Stoichiometric) 추정';

  @override
  String get derivedFuelSourceUnavailable => '연료 소모율 사용 불가';

  @override
  String get telemetrySourceDemo => '내장 시뮬레이터';

  @override
  String get telemetrySourceRig => '테스트 리그';

  @override
  String get telemetrySourceFieldApp => '실차용 field 앱 연결';

  @override
  String get fuelTypeGasoline => '가솔린 (휘발유)';

  @override
  String get fuelTypeDiesel => '디젤 (경유)';

  @override
  String get fuelTypeLpg => 'LPG';

  @override
  String get fuelTypeEthanolE85 => 'E85 에탄올';

  @override
  String get drivetrainFwd => '전륜 구동 (FWD)';

  @override
  String get drivetrainRwd => '후륜 구동 (RWD)';

  @override
  String get drivetrainAwd => '사륜 구동 (AWD)';

  @override
  String get assumptionFieldMass => '차량 중량';

  @override
  String get assumptionFieldDragCoefficient => 'Cd';

  @override
  String get assumptionFieldFrontalArea => '전면 투영 면적';

  @override
  String get assumptionFieldRollingResistance => '구름 저항 계수';

  @override
  String get assumptionFieldDrivetrainEfficiency => '동력 전달 효율';

  @override
  String get assumptionFieldFuelType => '연료';

  @override
  String get assumptionFieldStoichAfr => 'AFR';

  @override
  String get assumptionFieldFuelDensity => '밀도';

  @override
  String get assumptionFieldDisplacement => '배기량';

  @override
  String get assumptionFieldVolumetricEfficiency => 'VE';

  @override
  String get vehicleFieldOriginGenericDefault => '범용 기본값';

  @override
  String get vehicleFieldOriginUserEntered => '사용자 직접 입력';

  @override
  String get vehicleFieldOriginOfficialRegistry => '공식 등록부';

  @override
  String get vehicleFieldOriginManufacturerPublication => '제조사 자료';

  @override
  String get vehicleFieldOriginScientificModel => '모델 계수';

  @override
  String assumptionWithOrigin(String field, String value, String origin) {
    return '$field $value ($origin)';
  }

  @override
  String assumptionWithoutOrigin(String field, String value) {
    return '$field $value';
  }

  @override
  String get assumptionSeparator => '; ';

  @override
  String get datumFormulaHorsepower =>
      'wheelWatts = (m·a + ½ρ·Cd·A·v² + Crr·m·g)·v; engineHp = wheelHp / drivetrainEfficiency';

  @override
  String get datumFormulaFuelRate =>
      'L/h = (MAF g/s) / (AFR × 연료 밀도 g/L) × 3600; MAF는 PID 0110 또는 speed-density(RPM × MAP × 배기량 × VE / T_K); L/100km = (L/h) / speed_kmh × 100';

  @override
  String get datumAssumptionsFromRecording => '이 추정값은 기록 당시의 차량 설정을 사용합니다.';

  @override
  String adapterConcernFirmwareNeverReleasedSummary(String version) {
    return '출시된 적이 없는 펌웨어 버전 v$version을(를) 보고함';
  }

  @override
  String get adapterConcernFirmwareNeverReleasedDetail =>
      'Elm Electronics는 이 버전을 출시한 적이 없으므로 이 어댑터의 펌웨어는 스스로 주장하는 버전이 아닙니다. 이런 어댑터 중 상당수는 여전히 작동하지만, 자기 자신에 대한 설명은 신뢰할 수 없으므로 데이터가 읽히지 않을 때 가장 먼저 의심해 볼 만합니다.';

  @override
  String adapterConcernPpsRefusedSummary(String version) {
    return 'v$version이라고 주장하지만 v1.1부터 있었던 ATPPS 명령을 인식하지 못함';
  }

  @override
  String get adapterConcernPpsRefusedDetail =>
      '프로그래머블 파라미터 요약(ATPPS) 명령은 ELM327 v1.1부터 존재했으며 OBDLink 같은 고급 어댑터도 이를 지원합니다. 어댑터가 주장하는 버전과 실제로 구현된 명령 세트가 일치하지 않습니다.';

  @override
  String get adapterConcernNoIdentitySummary =>
      '첫 릴리스부터 있었던 기기 식별 명령 AT@1에 응답하지 않음';

  @override
  String get adapterConcernNoIdentityDetail =>
      '이 명령은 ELM327 v1.0부터 존재했습니다. 이에 응답하지 않는다는 것은 이 칩이 어느 공식 펌웨어보다도 적은 명령 세트만 구현하고 있음을 뜻합니다.';

  @override
  String get telemetryReplaySampled =>
      '미리보기는 샘플링된 데이터이며, 내보내기 파일에는 기록된 모든 이벤트가 온전히 보존됩니다.';

  @override
  String get telemetryExportDisclosure =>
      '내보내기 파일에는 신호 이름, 값, 관측 및 소스 시간, 전송 방식, 프로토콜, 고정된 PID 라벨·단위·공식, 그리고 추정 가정치(차량 중량, 공기 저항, 배기량, 연료 등의 파라미터)가 포함됩니다. JSON에는 사용자가 직접 만든 라벨, 단위, 공식 및 전체 고정 정의도 포함될 수 있습니다. 내보내기 파일에는 VIN, GPS, 계정, 어댑터 주소, 전체 차량 프로필 또는 원본 진단 통신 트래픽이 포함되지 않습니다.';

  @override
  String get connectTransportCancelled => '연결 시도가 완료되기 전에 중지되었습니다.';

  @override
  String get connectTransportWifiRouteNoNetwork =>
      '휴대폰이 어떠한 Wi-Fi 네트워크에도 연결되어 있지 않아 어댑터로 가는 경로가 없습니다. 어댑터의 Wi-Fi 핫스팟에 연결한 뒤 다시 시도하십시오.';

  @override
  String get connectTransportWifiRouteAmbiguous =>
      '휴대폰이 둘 이상의 Wi-Fi 네트워크에 연결되어 있고 어느 쪽이 어댑터인지 명확하지 않아 아무 경로도 선택하지 않았습니다. 어댑터가 아닌 네트워크 연결을 끊은 뒤 다시 시도하십시오.';

  @override
  String get connectTransportWifiRouteRefused =>
      '시스템이 이 연결을 Wi-Fi로 보내는 것을 거부했습니다. 휴대폰은 Wi-Fi에 연결되어 있지만, 이 용도로 Wi-Fi를 사용하는 것은 허용되지 않았습니다.';

  @override
  String get connectTransportWifiRouteTimeout =>
      '이 연결을 Wi-Fi로 보내 달라는 요청에 시스템이 응답하지 않았습니다. 몇 초 기다린 뒤 다시 시도하십시오.';

  @override
  String get connectTransportWifiRouteUnclassified =>
      '시스템이 밝히지 않은 이유로 인해 이 연결을 Wi-Fi로 보낼 수 없었습니다. 전체 오류 내용은 아래 로그에 보관되어 있습니다.';

  @override
  String get connectTransportWifiHostUnreachable =>
      '해당 주소에서 아무 응답이 없었습니다. 휴대폰이 어댑터의 Wi-Fi 핫스팟에 연결되어 있는지 확인하십시오 — 인터넷 없이 연결을 유지할지 시스템이 물었다면 연결 유지를 선택해야 합니다. 모바일 데이터를 끄는 것도 도움이 될 수 있습니다.';

  @override
  String get connectTransportWifiConnectTimeout =>
      '해당 주소에서 제한 시간 내에 아무 응답이 없었습니다.';

  @override
  String get connectTransportWifiRouteRestoreFailed =>
      '연결 자체는 작동했으나 휴대폰의 네트워크 라우팅을 원래대로 되돌릴 수 없어, 변경된 채로 두는 대신 연결을 끊었습니다. 앱을 다시 시작하고 재시도하십시오.';

  @override
  String get connectTransportBleLinkFailed =>
      '어댑터에 연결할 수 없습니다. 전원이 들어와 있고 통신 범위 안에 있는지 확인하십시오.';

  @override
  String get connectTransportBleNoSerialCharacteristic =>
      '기기에 연결되었으나 직렬 포트를 찾을 수 없어 ELM327 어댑터가 아닐 수 있습니다.';

  @override
  String get connectTransportClassicAllTiersRefused =>
      '어댑터에 연결할 수 없습니다. 먼저 시스템 블루투스 설정에서 페어링하고, 어댑터가 OBD 단자에 꽂혀 있으며 시동 스위치가 켜져 있는지 확인하십시오.';

  @override
  String get connectTransportClassicConnectTimeout =>
      '어댑터 연결 시간이 초과되었습니다. 어댑터가 아직 응답 중일 수 있으므로 곧바로 다시 시도하지 말고 몇 초 기다린 뒤 시도하십시오.';

  @override
  String get connectTransportSerialPortOpenFailed =>
      '직렬 포트를 열 수 없습니다. 시스템이 이 어댑터용 직렬 포트(Windows의 COMx, Linux의 /dev/rfcomm*)를 생성했는지, 그리고 시동 스위치가 켜져 있는지 확인하십시오.';

  @override
  String get connectTransportSerialDroppedOnOpen => '직렬 포트가 열리자마자 즉시 다시 닫혔습니다.';

  @override
  String get settingsManualCommandNotConnected =>
      '아무것도 연결되어 있지 않아 명령을 전송하지 않았습니다.';

  @override
  String get settingsManualCommandLinkDropped =>
      '이 명령이 전송 중일 때 어댑터와의 연결이 끊어져 아무 응답도 받지 못했습니다. 어댑터가 이 명령을 수신했는지는 알 수 없습니다.';

  @override
  String get settingsManualCommandDisconnectedByApp =>
      '이 명령이 전송 중일 때 앱이 연결을 닫았으므로 아무 응답도 받지 못했습니다. 어댑터나 차량에는 아무 문제가 없습니다.';

  @override
  String get settingsManualCommandAdapterSilentOnResync =>
      '어댑터의 응답이 전송된 명령과 어긋났으며, 이를 다시 맞추기 위한 확인 요청에도 응답하지 않아 연결을 끊었습니다. 다시 연결한 후 재시도하십시오.';

  @override
  String get settingsManualCommandLinkStoppedResponding =>
      '어댑터에서 오랫동안 아무 데이터도 오지 않아 연결을 끊었습니다. 전원은 여전히 켜져 있을 수 있으며, 확실히 알 수 있는 것은 침묵뿐입니다.';

  @override
  String get settingsManualCommandWriteFailed =>
      '명령을 어댑터 연결로 전달할 수 없었습니다. 명령의 어느 정도가 어댑터에 도달했는지는 알 수 없습니다.';

  @override
  String get settingsManualCommandTimedOut =>
      '제한 시간 내에 응답이 도착하지 않았습니다. 어댑터가 연결되어 있고 차량 시동 스위치가 켜져 있는지 확인하십시오.';

  @override
  String get settingsManualCommandOperationRetired =>
      '이 세션이 종료되었거나 백그라운드로 전환되어 명령을 전송하지 않았습니다.';

  @override
  String get settingsManualCommandRequestUnaddressable =>
      '이 요청은 현재 차량이 사용 중인 버스에서 주소를 지정할 수 없어 전송하지 않았습니다. 다시 시도해도 결과는 달라지지 않습니다.';

  @override
  String get commandFailureBusJ1939 =>
      '이 버스는 SAE J1939(대형 상용차 및 중장비 규격)이며 이 앱이 읽는 OBD2 진단 프로토콜이 아니므로 이 쿼리를 읽을 수 없습니다.';

  @override
  String commandFailureUserCanFramingUnknown(
    String protocol,
    String parameter,
  ) {
    return '이 어댑터는 사용자 정의 CAN 프로토콜 $protocol(프레임 형식은 $parameter에 의해 결정됨)로 설정되어 있습니다. 어댑터가 해당 설정을 보고하지 않아 버스 형식을 확인할 수 없으며 이 쿼리를 안전하게 해독할 수 없습니다.';
  }

  @override
  String get commandFailureBusUndetermined =>
      '차량 버스 프로토콜이 아직 결정되지 않아 이 쿼리를 안전하게 해독할 수 없습니다. 다시 연결하십시오.';

  @override
  String get settingsManualCommandCustomFlowControlRejected =>
      '어댑터가 사용자 정의 Flow Control 명령을 거부하여 요청한 모드가 적용되지 않았으며 어떠한 계측값도 생성되지 않았습니다.';

  @override
  String get settingsManualCommandFlowControlRestoreFailed =>
      '어댑터가 기본 Flow Control 복원(ATFCSM0)을 거부하여 다시 연결할 때까지 폴링이 중지됩니다.';

  @override
  String get settingsManualCommandExtendedAddressingUnavailable =>
      '이 ELM327 경로에서는 확장 주소 지정(ATCEA)을 사용할 수 없습니다.';

  @override
  String get settingsManualCommandRawIsoTpModeUnavailable =>
      '이 ELM327 경로에서는 호스트 가시적 ISO-TP 재조립을 사용할 수 없습니다.';

  @override
  String get settingsManualCommandCanPriorityUnavailable =>
      '이 ELM327 경로에서는 CAN 우선순위 프로그래밍(ATCP/ATCP18)을 사용할 수 없습니다.';

  @override
  String get settingsManualCommandCanReceiveFilterUnavailable =>
      '이 ELM327 경로에서는 CAN 수신 필터링(ATCRA)을 사용할 수 없습니다.';

  @override
  String get settingsManualCommandHeaderRestoreFailed =>
      '어댑터가 헤더 복원(ATSH)을 거부하여 다시 연결할 때까지 폴링이 중지됩니다.';

  @override
  String get manualCommandRefusedEmpty => '입력된 내용이 없어 아무것도 전송하지 않았습니다.';

  @override
  String get manualCommandRefusedMoreThanOneCommand =>
      '이 텍스트에는 줄바꿈이나 제어 문자가 포함되어 있어 한 번에 여러 명령을 보내게 됩니다. 어댑터는 줄바꿈으로 명령을 구분하므로 두 번째 명령은 고장 코드 삭제 차단을 포함한 이곳의 모든 안전 검사를 건너뛰게 됩니다. 한 번에 명령 하나만 보내십시오.';

  @override
  String manualCommandRefusedAdapterStateWouldChange(
    Object command,
    Object allowed,
  ) {
    return '이 입력란은 어댑터 상태를 바꾸는 명령이 아니라 질의만 수락합니다. “$command” 명령은 어댑터 상태를 변경하지만 앱이 알고 있는 어댑터 모델은 그대로 남기 때문에, 이후 판독값이 화면에 아무런 표시도 없이 다른 제어기에서 들어올 수 있습니다.\n전송 가능한 질의: $allowed.';
  }

  @override
  String get manualCommandRefusedClearHasItsOwnButton =>
      '고장 코드를 삭제하려면 고장 코드 화면의 「삭제」 버튼을 사용하십시오. 여기서 직접 보내면 확인 절차, 조회 범위 검사, 응답 검증을 모두 건너뛰게 되며 현재 선택된 단일 제어기에만 전달됩니다.';

  @override
  String manualCommandRefusedCharactersNoObdCommandHas(Object command) {
    return '“$command” 명령에 OBD 명령에는 절대 쓰이지 않는 문자가 포함되어 있습니다. 이 입력란은 16진수 서비스 코드 및 파라미터(예: 0100, 03, 2211A6) 또는 AT로 시작하는 어댑터 질의만 수락합니다.';
  }

  @override
  String manualCommandRefusedNotAReadOnlyQuery(Object command, Object allowed) {
    return '“$command”은(는) 이 입력란에서 인식하는 명령이 아닙니다. 읽기 전용 쿼리(Mode $allowed)와 어댑터 질의만 수락합니다.';
  }

  @override
  String commandFailureQueryHeaderRefused(Object header) {
    return '어댑터가 이 요청의 대상을 제어기 $header(으)로 지정하는 것을 거부하여 전송하지 않았습니다. 어댑터가 기존에 유지하던 주소로 그대로 보내면 질의하지도 않은 엉뚱한 제어기에서 응답이 돌아오게 됩니다.';
  }

  @override
  String commandFailureWholeVehicleHeaderRefused(Object address) {
    return '차량 전체에 질의할 때 사용해야 하는 주소 $address(으)로의 전환을 어댑터가 거부했습니다. 이 주소 없이는 응답을 보낸 제어기를 식별할 수 없으므로 요청을 전송하지 않았습니다.';
  }

  @override
  String commandFailureLegacyScanWouldBePartial(Object installed) {
    return '이 차량은 모든 제어기에 도달하는 표준 주소가 없는 구형 버스를 사용하며, 어댑터가 현재 제어기 $installed에 고정되어 있습니다. 이대로 스캔하면 해당 제어기 하나만 조회하면서도 차량 전체의 결과처럼 보이게 되므로 전송하지 않았습니다. 다시 연결한 뒤 스캔하십시오.';
  }

  @override
  String get pidFormulaEmpty => '공식이 비어 있습니다.';

  @override
  String get pidFormulaEmptySubExpression =>
      '공식의 일부가 비어 있습니다 — 연산자 뒤에 아무것도 없거나 괄호 안이 비어 있습니다.';

  @override
  String get pidFormulaUnbalancedParentheses =>
      '괄호 짝이 맞지 않습니다: 모든 (에는 닫는 )가 필요합니다.';

  @override
  String pidFormulaUnparsableTerm(String term) {
    return '“$term”은(는) 이 편집기가 이해할 수 있는 숫자, 연산자 또는 이름이 아닙니다.';
  }

  @override
  String get pidFormulaFunctionNestingTooDeep =>
      'ABS(), LOG10(), LOG() 및 SQRT()가 너무 깊게 중첩되어 계산할 수 없습니다. 공식을 단순화하십시오.';

  @override
  String get pidFormulaParenthesisNestingTooDeep =>
      '괄호가 너무 깊게 중첩되어 계산할 수 없습니다. 공식을 단순화하십시오.';

  @override
  String get pidFormulaDivisionByZero => '공식이 0으로 나눕니다.';

  @override
  String get pidFormulaModuloByZero => '공식이 0으로 나눈 나머지를 구하려고 합니다.';

  @override
  String pidFormulaLog10NonPositiveArgument(double argument) {
    return 'LOG10의 인수는 0보다 커야 하지만 계산된 값은 $argument입니다.';
  }

  @override
  String pidFormulaLogNonPositiveArgument(double argument) {
    return 'LOG의 인수는 0보다 커야 하지만 계산된 값은 $argument입니다.';
  }

  @override
  String pidFormulaSqrtNegativeArgument(double argument) {
    return 'SQRT의 인수는 0 이상이어야 하지만 계산된 값은 $argument입니다.';
  }

  @override
  String get pidFormulaResultNotFinite => '연산 결과 유효한 숫자가 나오지 않아 표시할 판독값이 없습니다.';

  @override
  String pidFormulaByteBeyondResponse(String letter, int count) {
    return '공식이 바이트 $letter을(를) 참조하지만 응답에는 $count바이트만 포함되어 있습니다.';
  }

  @override
  String get pidFormulaBaroControllerUnknown =>
      '어느 제어기의 대기압을 뜻하는지 알 수 없으므로 여기서 BARO를 사용할 수 없습니다.';

  @override
  String get pidFormulaBaroTwoDefinitions =>
      '두 개의 정의가 동시에 대기압을 제공하고 있어 값이 어느 쪽인지 알 수 없으므로 둘 다 사용할 수 없습니다. 대기압을 측정하는 게이지 중 하나를 제거하십시오.';

  @override
  String get pidFormulaBaroNotYetMeasured => '아직 대기압을 읽지 못해 계산할 수 없습니다.';

  @override
  String get pidFormulaBaroMeasurementStale => '대기압 판독값이 오래되어 계산할 수 없습니다.';

  @override
  String get pidFormulaBaroParenFormUnsupported =>
      'BARO()는 psi 단위의 Android 기압계 / ECU 대기압이며 이 방언에서는 구현하지 않습니다. 캐시된 대기압을 사용하려면 괄호 없이 BARO를 쓰십시오.';

  @override
  String get pidFormulaInt16Unclaimed =>
      'INT16은 이 방언에서 확정되지 않았습니다: 위키에서는 (A*255)+B를 대체할 수 있다고 하지만 이는 (A*256)+B와 다릅니다. 두 등식 중 하나를 공식에 직접 명시하십시오.';

  @override
  String pidFormulaTimeWindowUnsupported(String term) {
    return '$term은(는) 이 방언에서 구현하지 않는 지연, 평균 또는 totalizer Torque 함수이므로 여기서 계산할 수 없습니다. 이 값은 0이 아니며 MIN이나 MAX도 아닙니다.';
  }

  @override
  String pidFormulaDependencyControllerUnknown(String reference) {
    return '해당 PID가 어느 제어기에 속하는지 알 수 없으므로 여기서 $reference을(를) 해석할 수 없습니다.';
  }

  @override
  String pidFormulaDependencyTwoDefinitions(String key) {
    return '두 개의 정의가 동시에 $key을(를) 해독하고 있어 값이 어느 쪽인지 알 수 없으므로 둘 다 사용할 수 없습니다. 둘 중 하나를 다른 모드+PID로 변경하십시오. 참고: 추정값 계산에 필요한 PID(010B, 010C, 010D)는 항상 읽으므로 대시보드에서 게이지를 제거해도 읽기가 중단되지 않습니다.';
  }

  @override
  String pidFormulaDependencyNotYetMeasured(String key) {
    return '아직 $key에 대해 사용할 수 있는 유효 값을 읽지 못했습니다.';
  }

  @override
  String get pidFormulaUnidentified =>
      '이 공식은 계산할 수 없으며, 편집기에 표시할 더 구체적인 원인이 없습니다.';

  @override
  String get pidRejectionMalformedModeAndPid =>
      '유효한 모드+PID가 아닙니다: 16진수 문자만 온전한 바이트 쌍 단위로 입력해야 합니다.';

  @override
  String pidRejectionServiceNotReadOnly(String service, String services) {
    return '서비스 $service은(는) 읽기 전용 쿼리가 아니므로 차량에 반복 전송해서는 안 됩니다. $services(현재 데이터, 프리즈 프레임, 차량 정보 및 ReadDataByIdentifier)만 허용됩니다.';
  }

  @override
  String get pidRejectionFreezeFrameNeedsFrame =>
      '프리즈 프레임 쿼리에는 PID와 프레임 번호 두 바이트가 필요합니다 — 예: 020500 (PID 05, 프레임 0).';

  @override
  String get pidRejectionIdentifierNeedsTwoBytes =>
      'ReadDataByIdentifier에는 2바이트 식별자가 필요합니다 — 예: 221101.';

  @override
  String pidRejectionIdentifierWrongLength(String service, int bytes) {
    return '서비스 $service 쿼리에는 $bytes바이트 식별자가 필요합니다.';
  }

  @override
  String get pidRejectionNameRequired => '이름을 입력하십시오.';

  @override
  String pidRejectionInvalidHeader(String text) {
    return '“$text”은(는) 유효한 헤더가 아닙니다: 11-bit CAN은 3자리, 구형 프로토콜은 6자리, 29-bit CAN은 8자리여야 합니다.';
  }

  @override
  String get pidRejectionBoundsRequired => '게이지 범위의 최솟값과 최댓값을 모두 입력하십시오.';

  @override
  String pidRejectionMinNotANumber(String text) {
    return '하한값 “$text”은(는) 유효한 숫자가 아닙니다.';
  }

  @override
  String pidRejectionMaxNotANumber(String text) {
    return '상한값 “$text”은(는) 유효한 숫자가 아닙니다.';
  }

  @override
  String get pidRejectionMinNotFinite => '하한값은 유한한 숫자여야 합니다.';

  @override
  String get pidRejectionMaxNotFinite => '상한값은 유한한 숫자여야 합니다.';

  @override
  String pidRejectionRedlineNotANumber(String text) {
    return '레드존 시작값 “$text”은(는) 유효한 숫자가 아닙니다.';
  }

  @override
  String get pidRejectionRedlineNotFinite => '레드존 시작값은 유한한 숫자여야 합니다.';

  @override
  String get pidRejectionMaxNotAboveMin => '상한값은 하한값보다 커야 합니다.';

  @override
  String pidImportMalformedCsv(String detail) {
    return '이 파일을 CSV로 읽을 수 없습니다: $detail';
  }

  @override
  String get pidImportNoRows => '파일에 데이터 행이 없습니다.';

  @override
  String pidImportDuplicateHeaderColumns(String columns) {
    return '헤더 행에 동일한 열 이름이 두 번 나타납니다: $columns. 어느 열을 사용해야 할지 알 수 없으므로 먼저 파일을 수정하십시오.';
  }

  @override
  String pidImportMissingRequiredColumns(String columns, String required) {
    return '헤더 행에 필수 열이 누락되었습니다: $columns. $required 열이 모두 필요합니다.';
  }

  @override
  String pidImportRowTooFewColumns(int line) {
    return '$line행: 셀 개수가 부족합니다 — 최소한 이름, 약칭, PID 및 공식이 필요합니다.';
  }

  @override
  String pidImportRowInvalidModeAndPid(int line, String text) {
    return '$line행: “$text”은(는) 유효한 모드+PID가 아닙니다(16진수 문자만 온전한 바이트 쌍 단위로 허용됨).';
  }

  @override
  String pidImportRowEmptyEquation(int line) {
    return '$line행: 공식 셀이 비어 있습니다.';
  }

  @override
  String pidImportRowRejected(int line, String reason) {
    return '$line행: $reason';
  }

  @override
  String pidImportRowRangeDefaulted(int line, double min, double max) {
    return '$line행: 게이지 범위가 비어 있어 기본값 $min–$max을(를) 적용했습니다. 이 눈금 범위가 해당 센서에 맞는지 확인하십시오.';
  }

  @override
  String get pidImportNothingImportable =>
      '파일에 행이 들어 있지만 PID 정의에 해당하는 행이 하나도 없습니다.';

  @override
  String get dtcCategoryNoAnswer => '이 범주가 응답하지 않았습니다. 다시 스캔하십시오.';

  @override
  String get dtcCategoryError =>
      '이 범주를 읽을 수 없었습니다. 전체 오류 내용은 진단 통신 기록에 보관되어 있습니다.';

  @override
  String get dtcCategoryDisconnected => '이 범주를 읽는 도중 연결이 끊어졌습니다.';

  @override
  String get dtcCategoryPending =>
      '제어기가 요청을 수신하여 아직 처리 중입니다. 잠시 기다린 뒤 다시 스캔하십시오 — 이는 거부가 아닙니다.';

  @override
  String get dtcCategoryUnattributed =>
      '고장 코드가 반환되었으나 응답 헤더가 꺼져 있어 어느 제어기가 응답했는지 알 수 없습니다. 정상 결과가 아니라 불완전한 부분 결과로 취급하십시오.';

  @override
  String dtcCategorySilentControllers(int count, String controllers) {
    return '제어기 $count개가 이번 쿼리에 응답하지 않았습니다($controllers). 돌아온 응답은 유효하지만 이를 차량 전체의 결과로 간주할 수 없습니다.';
  }

  @override
  String dtcCategoryUnresolvedSources(int count, String addresses) {
    return '응답 $count건의 발신 제어기를 식별할 수 없었습니다($addresses). 읽힌 고장 코드는 여전히 유효하지만 이를 차량 전체의 결과로 간주할 수 없습니다. 다시 스캔하십시오.';
  }

  @override
  String dtcCategoryPendingControllers(int count, int answered) {
    return '제어기 $count개가 아직 이 요청을 처리 중입니다($answered개 응답 완료). 결과가 불완전하므로 잠시 기다린 뒤 다시 스캔하십시오.';
  }

  @override
  String dtcCategoryRefusedControllers(int refused, int answered) {
    return '제어기 $refused개가 응답을 거부했습니다($answered개 응답 완료). 이번 스캔은 차량 전체를 포괄할 수 없습니다.';
  }

  @override
  String dtcCategoryUnrecognisedResponses(int count, int answered) {
    return '응답 $count건을 읽을 수 없었습니다($answered개 응답 완료). 나머지 결과는 유효하지만 이번 스캔은 불완전합니다.';
  }

  @override
  String dtcCategoryMilCountMismatch(
    String controller,
    int claimed,
    int observed,
  ) {
    return '$controller 제어기는 확정된 고장 코드 $claimed개를 보고했으나 이번 스캔에서는 $observed개만 읽혔습니다. 차량 계기판의 경고등을 기준으로 삼고 정비소를 방문하십시오.';
  }

  @override
  String dtcCategoryMilLitNoCodes(String controller) {
    return '$controller 제어기는 고장 표시등(MIL) 점등을 보고했으나 해당 제어기의 고장 코드가 하나도 읽히지 않았습니다. 차량 계기판의 경고등을 기준으로 삼고 정비소를 방문하십시오.';
  }

  @override
  String dtcCategoryMilDisagreement(String controllers) {
    return '차량 자체 상태가 읽힌 고장 코드와 일치하지 않습니다($controllers). 차량 계기판의 경고등을 기준으로 삼고 정비소를 방문하십시오.';
  }

  @override
  String get connectPairedListFailed =>
      '페어링된 블루투스 목록을 읽을 수 없습니다. 블루투스가 켜져 있는지 확인한 뒤 다시 시도하십시오.';

  @override
  String get connectBleScanUnavailable =>
      '지금 블루투스를 사용할 수 없습니다. 잠시 기다린 뒤 다시 검색하십시오.';

  @override
  String get connectBleScanBluez =>
      '사용 가능한 BlueZ/D-Bus 블루투스 서비스를 찾을 수 없습니다. bluetooth 서비스를 설치 및 시작한 뒤 다시 시도하십시오.';

  @override
  String get connectBleScanUnclassified => 'BLE 검색에 실패했습니다.';

  @override
  String dtcClearNrcConditions(String controller) {
    return '현재 차량 상태가 허용하지 않아 $controller 제어기가 삭제를 거부했습니다. 대부분의 제어기는 엔진이 작동 중일 때 고장 메모리를 삭제하지 않습니다. 엔진을 끄고 시동 스위치만 ON으로 돌린 뒤 다시 시도하십시오.';
  }

  @override
  String dtcClearNrcUnsupported(String controller) {
    return '$controller 제어기는 Mode 04 삭제를 지원하지 않습니다. 제조사 또는 딜러 전용 진단 장비가 필요할 수 있습니다.';
  }

  @override
  String dtcClearNrcBusy(String controller) {
    return '$controller 제어기가 사용 중입니다. 잠시 기다린 뒤 다시 시도하십시오.';
  }

  @override
  String dtcClearNrcSecurity(String controller) {
    return '$controller 제어기는 삭제 전에 보안 액세스(Security Access)를 요구합니다. 제조사 또는 딜러 전용 진단 장비가 필요합니다.';
  }

  @override
  String dtcClearNrcOther(String controller, String code) {
    return '$controller 제어기가 삭제를 거부했습니다(사유 코드 $code). 잠시 기다린 뒤 다시 시도하십시오.';
  }

  @override
  String dtcClearSilentControllers(int count, String controllers) {
    return '제어기 $count개가 삭제 명령에 응답하지 않았습니다($controllers). 응답한 제어기에서는 고장 코드가 삭제되었으나 나머지 제어기에는 여전히 코드가 남아 있을 수 있습니다. 다시 스캔하십시오. 삭제 명령을 또 보내지 마십시오.';
  }

  @override
  String dtcClearUnresolvedSources(int count, String addresses) {
    return '이번 스캔의 응답 $count건에 대해 발신 제어기를 식별할 수 없어($addresses) 삭제 명령이 어느 제어기에 도달할지 알 수 없습니다. 다시 스캔하십시오. 해당 주소가 다시 나타나지 않으면 재연결한 뒤 시도하십시오.';
  }

  @override
  String dtcClearUnresolvedSourcesDoNotRepeat(int count, String addresses) {
    return '삭제 응답 중 $count건의 발신 제어기를 식별할 수 없었습니다($addresses). 삭제 명령을 다시 보내지 마십시오. 남아 있는 코드를 확인하려면 다시 스캔하십시오.';
  }

  @override
  String dtcClearNrcConditionsDoNotRepeat(String controller) {
    return '현재 차량 상태가 허용하지 않아 $controller 제어기가 삭제를 거부했습니다. 대부분의 제어기는 엔진이 작동 중일 때 고장 메모리를 삭제하지 않습니다. 엔진을 끄고 시동 스위치만 ON으로 돌린 뒤 다시 스캔하여 남아 있는 코드를 확인하십시오. 전체 삭제 명령을 다시 보내지 마십시오 — 한 번 더 보내면 이미 삭제를 마쳤을 수 있는 제어기의 배출가스 준비 상태가 다시 초기화될 수 있습니다.';
  }

  @override
  String dtcClearNrcUnsupportedDoNotRepeat(String controller) {
    return '$controller 제어기는 Mode 04 삭제를 지원하지 않습니다. 제조사 또는 딜러 전용 진단 장비가 필요할 수 있습니다. 전체 삭제 명령을 다시 보내지 마십시오 — 한 번 더 보내면 이미 삭제를 마쳤을 수 있는 제어기의 배출가스 준비 상태가 다시 초기화될 수 있습니다. 남아 있는 코드를 확인하려면 다시 스캔하십시오.';
  }

  @override
  String dtcClearNrcBusyDoNotRepeat(String controller) {
    return '$controller 제어기가 사용 중입니다. 전체 삭제 명령을 다시 보내지 마십시오 — 한 번 더 보내면 이미 삭제를 마쳤을 수 있는 제어기의 배출가스 준비 상태가 다시 초기화될 수 있습니다. 남아 있는 코드를 확인하려면 다시 스캔하십시오.';
  }

  @override
  String dtcClearNrcSecurityDoNotRepeat(String controller) {
    return '$controller 제어기는 삭제 전에 보안 액세스(Security Access)를 요구합니다. 제조사 또는 딜러 전용 진단 장비가 필요합니다. 전체 삭제 명령을 다시 보내지 마십시오 — 한 번 더 보내면 이미 삭제를 마쳤을 수 있는 제어기의 배출가스 준비 상태가 다시 초기화될 수 있습니다.';
  }

  @override
  String dtcClearNrcOtherDoNotRepeat(String controller, String code) {
    return '$controller 제어기가 삭제를 거부했습니다(사유 코드 $code). 전체 삭제 명령을 다시 보내지 마십시오 — 한 번 더 보내면 이미 삭제를 마쳤을 수 있는 제어기의 배출가스 준비 상태가 다시 초기화될 수 있습니다. 남아 있는 코드를 확인하려면 다시 스캔하십시오.';
  }

  @override
  String get sharePolicyDenied => '현재 연결 또는 주행 상태에서는 내보내기가 허용되지 않습니다.';

  @override
  String get shareSafetyChanged => '내보내기를 준비하는 도중 상태가 변경되어 공유 창을 열지 않았습니다.';

  @override
  String get shareSizeLimit => '내보내기 파일이 32 MiB 제한을 초과합니다.';

  @override
  String get shareStagingBusy => '이전 공유 파일이 아직 보존 기간 내에 있습니다. 잠시 후 다시 시도하십시오.';

  @override
  String get shareCleanupRequired => '다시 시작한 후 공유 임시 영역을 검사해야 합니다.';

  @override
  String get shareSpaceUnknown => '공유 파일에 필요한 여유 공간을 확인할 수 없습니다.';

  @override
  String get shareNoSpace => '공유 파일을 준비할 저장 공간이 부족합니다.';

  @override
  String get shareHandoffFailed => '파일은 준비되었으나 시스템 공유 시트를 열 수 없었습니다.';

  @override
  String get shareStorageFailure => '공유를 준비하거나 기록하는 도중 저장소 오류가 발생했습니다.';

  @override
  String shareTelemetrySubject(String sessionId) {
    return '로컬 OBD 기록 $sessionId';
  }

  @override
  String shareRawTranscriptSubject(String stamp) {
    return 'Telltale 통신 로그 $stamp';
  }

  @override
  String get shareRecoveredTranscriptSubject => 'Telltale 통신 로그 (지난 연결)';

  @override
  String get sharePidCsvSubject => 'Telltale 사용자 정의 PID 정의';

  @override
  String get shareTorqueSubsetCsvSubject => 'Torque 호환 PID 정의';

  @override
  String get shareHumanReportCsvSubject => 'Telltale 사람이 읽기 쉬운 PID 보고서';

  @override
  String get transcriptExportUnidentified => '내보내기에 실패했습니다.';

  @override
  String get handshakeNoteUnexpected =>
      '예기치 않은 오류로 인해 이 단계가 실패했습니다. 전체 오류 내용은 진단 통신 기록에 보관되어 있습니다.';

  @override
  String pidFormulaUnsupportedConstruct(String term) {
    return '$term은(는) 이 방언에서 구현하지 않는 Torque 함수이므로 여기서 공식을 계산할 수 없습니다.';
  }

  @override
  String pidImportRowFormulaRejected(int line, String reason) {
    return '$line행: $reason';
  }

  @override
  String get telemetryHistoryNeedsForeground => '계속하기 전에 Telltale 화면으로 돌아오십시오.';

  @override
  String get telemetrySessionPolicyChanged => '이 작업 도중 주행 또는 연결 상태가 변경되었습니다.';

  @override
  String get telemetrySessionInvalidId => '이 기록 ID는 유효하지 않습니다.';

  @override
  String get telemetrySessionNotFound => '이 로컬 기록을 찾을 수 없습니다.';

  @override
  String get telemetrySessionStorageFailed => '로컬 저장소 작업에 실패했습니다.';

  @override
  String get telemetrySessionShareFailed => '공유를 준비하거나 열 수 없었습니다.';

  @override
  String get pidMutationPersistFailed =>
      '사용자 정의 PID 목록을 저장할 수 없었습니다. 아무것도 변경되지 않았습니다.';

  @override
  String get powertrainAuthorizeYearOutOfRange =>
      '선택한 연식이 이 프로필에 문서화된 연도 범위를 벗어납니다.';

  @override
  String get connectionLayerTransport => '연결 방식';

  @override
  String get connectionLayerProtocol => '프로토콜';

  @override
  String get connectionLayerEcu => 'ECU 응답';

  @override
  String get connectionLayerEvidence => '증거';

  @override
  String get connectionLayerUnknown => '알 수 없음';

  @override
  String get connectionLayerNotObserved => '관측되지 않음';

  @override
  String get connectionLayerObserved => '관측됨';

  @override
  String get connectionLayerAnswered => '응답함';

  @override
  String get connectionLayerSoftware => '소프트웨어';

  @override
  String get connectionLayerDemo => '데모 시뮬레이터';

  @override
  String get connectionLayerBle => 'Bluetooth LE';

  @override
  String get connectionLayerClassic => 'Bluetooth Classic';

  @override
  String get connectionLayerWifi => 'Wi-Fi';

  @override
  String connectionLayerRequestedObserved(String requested, String observed) {
    return '요청 $requested, 확정 $observed';
  }

  @override
  String get connectionLayerKwpSubtypeUnknown => 'KWP, 5-baud와 fast 구분 불가';

  @override
  String get connectionFailureOpenSettings => '시스템 설정을 여십시오.';

  @override
  String get connectionFailureTurnRadioOn => '블루투스를 켜십시오.';

  @override
  String get connectionFailureCheckDistanceOrPower =>
      '어댑터가 통신 범위를 벗어났거나 전원이 공급되지 않았을 수 있습니다. 이는 가능한 원인일 뿐 확정된 진단 결과가 아닙니다.';

  @override
  String get connectionFailureCheckIgnitionProtocolAdapter =>
      '시동 스위치, 프로토콜 또는 어댑터 성능을 확인하십시오. 응답이 없다는 것이 차량에 OBD가 없다는 증거는 아닙니다.';

  @override
  String get connectionFailureRetryOrAuto => '다시 시도하거나 프로토콜을 Auto로 설정하십시오.';

  @override
  String get connectionFailureKeepInvalidAndExport =>
      '응답이 유효하지 않습니다. 무효 상태로 유지하고 제한된 진단 기록을 내보내십시오 — 이는 판독값이 아닙니다.';

  @override
  String get settingsCatalogMarketCa => '캐나다 (NRCan)';

  @override
  String get settingsCaPickerTitle => '캐나다 공식 차량 카탈로그';

  @override
  String settingsCaPickerScope(int firstYear, int lastYear) {
    return '$firstYear–$lastYear 캐나다 시장 연비 등급 행만 포함됩니다. 내연기관(ICE), 배터리 전기차(BEV), 플러그인 하이브리드(PHEV)는 별도 분류로 유지됩니다. 제조사/모델 문자열이 일치한다는 사실만으로 EPA 또는 대만 구성이 확인되는 것은 아닙니다.';
  }

  @override
  String get settingsCaMotorNotPower =>
      '킬로와트(kW) 단위의 모터 출력은 휠 마력이 아니며 적용되지 않습니다.';

  @override
  String get settingsCaClassIce => '내연기관 (ICE)';

  @override
  String get settingsCaClassBev => '배터리 전기차 (BEV)';

  @override
  String get settingsCaClassPhev => '플러그인 하이브리드 (PHEV)';

  @override
  String settingsCaWillApplyOnly(String fields) {
    return '$fields 항목만 적용됩니다. 모터 kW, 연비, 주행 가능 거리, CO2, VE, Cd, 전면 투영 면적, Crr 및 동력 전달 효율은 미결정 상태로 남습니다.';
  }

  @override
  String get serviceRecipesTitle => '서비스 레시피 및 능동 진단';

  @override
  String get serviceRecipesSubtitle =>
      '표준 참조 서비스 레시피 및 비작동(Non-Actuating) 기능 탐색';

  @override
  String get serviceRecipesSafetyBannerTitle =>
      '실차 실행 대상 없음 (Zero Live Candidates)';

  @override
  String get serviceRecipesSafetyBannerBody =>
      '실제 차량에 대한 물리적 구동(액추에이션)은 엄격히 금지됩니다(적격 차량 0대). 제공되는 레시피는 시뮬레이션 픽스처 전용입니다.';

  @override
  String get serviceRecipesDiscoverySection =>
      'Mode 08 비작동(Non-Actuating) 기능 탐색';

  @override
  String get serviceRecipesDiscoveryDescription =>
      '어떠한 부품도 작동시키지 않고 CAN을 통해 표준 기본 테스트 ID(\$00, \$20, ...) 지원 여부만 쿼리합니다.';

  @override
  String get serviceRecipesDiscoveryButton => 'Mode 08 지원 TID 탐색';

  @override
  String get serviceRecipesDiscovering => '지원되는 TID 쿼리 중...';

  @override
  String serviceRecipesDiscoverySuccess(String tids) {
    return 'ECU가 Mode 08을 지원합니다. 지원 TID: $tids';
  }

  @override
  String get serviceRecipesDiscoveryUnsupported => '이 ECU는 Mode 08을 지원하지 않습니다';

  @override
  String serviceRecipesDiscoveryUnknown(String reason) {
    return 'Mode 08 지원 여부를 알 수 없음: $reason';
  }

  @override
  String serviceRecipesDiscoveryPartialWarning(String reason, String blocks) {
    return '탐색이 일부만 완료되었습니다($reason). 미완료 블록: $blocks. 참고: 조회되지 않았다는 것이 지원하지 않는다는 뜻은 아닙니다.';
  }

  @override
  String get serviceRecipesCatalogSection => '사용 가능한 서비스 레시피';

  @override
  String get serviceRecipesSimulationBadge => '시뮬레이션 가능';

  @override
  String get serviceRecipesLiveBlockedBadge => '실차 차단됨 (실차 대상 0대)';

  @override
  String serviceRecipesStandard(String standard) {
    return '표준 규격: $standard';
  }

  @override
  String serviceRecipesEcuHeader(String header) {
    return 'ECU 헤더: $header';
  }

  @override
  String serviceRecipesHash(String hash) {
    return '정규 형식 해시: $hash';
  }

  @override
  String get serviceRecipesDetailTitle => '서비스 레시피 상세 정보';

  @override
  String get serviceRecipesPreconditions => '안전 전제 조건';

  @override
  String get serviceRecipesRecovery => '복구 명령';

  @override
  String get serviceRecipesClose => '닫기';

  @override
  String get serviceRecipesDiscoveryRequiresCan =>
      '활성화된 OBD-II CAN 버스 연결이 필요합니다.';

  @override
  String serviceRecipesLoadError(String error) {
    return '서비스 레시피를 불러오는 중 오류 발생: $error';
  }

  @override
  String get serviceRecipesNoPreconditions => '없음';

  @override
  String get settingsServiceRecipesEntry => '서비스 레시피 및 능동 테스트';

  @override
  String get settingsServiceRecipesDesc =>
      '정비 서비스 레시피를 살펴보고 지원되는 Mode 08 테스트를 탐색합니다';

  @override
  String get mode08ReasonUnheaderedLimitation =>
      '출처 귀속 및 조회 범위 미확인: 헤더가 없는 응답으로는 블록 간 ECU 신원을 확립할 수 없습니다';

  @override
  String mode08ReasonNoResponseWithEcu(
    String block,
    String ecu,
    String marker,
  ) {
    return '$ecu에서 블록 $block 응답 없음: $marker';
  }

  @override
  String mode08ReasonNoResponse(String block, String marker) {
    return '블록 $block 응답 없음: $marker';
  }

  @override
  String mode08ReasonNegativeWithEcu(String block, String ecu, String nrc) {
    return '$ecu에서 블록 $block 부정 응답 (NRC $nrc)';
  }

  @override
  String mode08ReasonNegative(String block, String nrc) {
    return '블록 $block 부정 응답 (NRC $nrc)';
  }

  @override
  String mode08ReasonMalformedWithEcu(
    String block,
    String ecu,
    String details,
  ) {
    return '$ecu에서 블록 $block 형식 오류 응답: $details';
  }

  @override
  String mode08ReasonMalformed(String block, String details) {
    return '블록 $block 형식 오류 응답: $details';
  }

  @override
  String mode08ReasonTimeout(String block) {
    return '블록 $block 쿼리 시간 초과';
  }

  @override
  String get mode08ReasonBudgetExceeded => '모든 블록을 쿼리하기 전에 탐색 한도에 도달함';

  @override
  String get mode08ReasonSessionDisconnected => '탐색 도중 세션 연결이 끊어졌거나 대체됨';

  @override
  String mode08ReasonUnqueriedAnnounced(String blocks) {
    return 'ECU가 알렸으나 아직 쿼리하지 않은 블록: $blocks';
  }

  @override
  String get mode08ReasonRequiresCanBus =>
      'Mode 08 기능 탐색에는 확인된 OBD-II CAN 버스가 필요합니다';

  @override
  String get mode08ReasonUnexpectedExecution =>
      '지원 TID 쿼리에 대해 예기치 않은 실행 응답이 수신됨';

  @override
  String get pidDetailEmptyTitle => 'PID 선택';

  @override
  String get pidDetailEmptyBody => '목록에서 PID를 선택하여 정의와 실시간 상태를 확인하십시오.';

  @override
  String get pidDetailRangeLabel => '범위';

  @override
  String get pidDetailPriorityLabel => '우선순위';

  @override
  String pidDetailHeaderDefault(String header) {
    return '기본값 ($header)';
  }

  @override
  String get dtcSystemOverview => '시스템 개요';

  @override
  String get dtcPartialObservationBadge => '부분 스캔';

  @override
  String get dtcPartialObservationBody =>
      '이 고장 코드는 읽혔으나, 이 범주에 대한 전체 제어기 스캔이 끝까지 완료되지 않았습니다.';

  @override
  String get dtcLinkedFreezeFrameTitle => '연관된 프리즈 프레임';

  @override
  String get dtcNoLinkedFreezeFrame =>
      '이번 스캔에는 이 고장 코드 및 제어기와 안전하게 연결할 수 있는 프리즈 프레임이 없습니다.';

  @override
  String get performanceGuideTitle => '가속 측정 가이드';

  @override
  String get performanceGuideStep1 => '1. 목표 속도를 선택한 후 타이머를 준비합니다';

  @override
  String get performanceGuideStep2 => '2. 차량을 완전히 정차시키고 준비 완료 표시가 뜰 때까지 기다립니다';

  @override
  String get performanceGuideStep3 =>
      '3. 출발하여 가속합니다. 움직임이 감지되면 자동으로 타이머가 시작됩니다';

  @override
  String get performanceGuideStep4 => '4. 목표 속도에 도달하면 측정이 완료됩니다';

  @override
  String get performanceRecordingTrace => '가속 중... 속도 궤적 기록 중';

  @override
  String get performanceNoAnalysisTitle => '분석 데이터 없음';

  @override
  String get performanceNoAnalysisBody =>
      '속도 궤적이나 구간 기록을 생성하기에 충분한 속도 샘플이 기록되기 전에 측정이 중지되었습니다.';

  @override
  String get connectActivityReconnectingAutomatically =>
      '어댑터 응답이 중단되어 자동으로 다시 연결하는 중입니다…';
}
