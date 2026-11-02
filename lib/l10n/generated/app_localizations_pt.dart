// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get adapterErrorActivityAlert => 'Alerta de atividade no barramento.';

  @override
  String get adapterErrorBufferFull => 'O buffer do adaptador estourou.';

  @override
  String get adapterErrorBus =>
      'Erro no barramento; a fiação pode ser a causa.';

  @override
  String get adapterErrorBusBusy => 'O barramento está ocupado.';

  @override
  String get adapterErrorBusInit => 'Falha na inicialização do barramento.';

  @override
  String get adapterErrorCan => 'Erro no barramento CAN.';

  @override
  String get adapterErrorData => 'Os dados que chegaram não estão corretos.';

  @override
  String get adapterErrorFeedback => 'Erro de realimentação do sinal.';

  @override
  String get adapterErrorInternal => 'Erro interno do adaptador.';

  @override
  String get adapterErrorLowPowerAlert =>
      'O adaptador está prestes a entrar em modo de baixo consumo.';

  @override
  String get adapterErrorLowVoltageReset =>
      'Baixa tensão reiniciou o adaptador.';

  @override
  String get adapterErrorNoData =>
      'Nenhuma resposta chegou — pode ser silêncio temporário, ou o veículo pode não oferecer suporte a isso.';

  @override
  String get adapterErrorStopped => 'A transferência foi interrompida.';

  @override
  String get adapterErrorUnableToConnect =>
      'Não é possível alcançar a ECU. Verifique se a ignição está ligada.';

  @override
  String get adapterErrorUnknownCommand =>
      'O adaptador não oferece suporte a este comando.';

  @override
  String get appTagline => 'Telemetria veicular ao vivo';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => 'Aparência';

  @override
  String get connectActivityAbortingPreviousConnection =>
      'Encerrando a conexão anterior, um momento…';

  @override
  String get connectAnswerBleWithClassic =>
      'Escolha Bluetooth LE. Não precisa emparelhar antes — busque dentro do app. Mesmo que apareça na lista de emparelhamento Bluetooth do sistema, não emparelhe; esse caminho não funciona. Se a busca não encontrar nada, o 4.0 na caixa era só a especificação do chip — use Bluetooth Classic em vez disso.';

  @override
  String get connectAnswerBleWithoutClassic =>
      'Escolha Bluetooth LE. Não precisa emparelhar antes — busque dentro do app. Mesmo que apareça na lista de emparelhamento Bluetooth do sistema, não emparelhe; esse caminho não funciona. Se a busca não encontrar nada, verifique se o adaptador tem energia, ou tente Wi‑Fi em vez disso; este host não oferece Bluetooth Classic.';

  @override
  String get connectAnswerClassic =>
      'Escolha Bluetooth Classic. Emparelhe nas configurações do sistema primeiro; o app não pode emparelhar por você. O código costuma ser 1234 ou 0000.';

  @override
  String get connectAnswerWifiDesktop =>
      'Escolha Wi-Fi. Conecte este dispositivo a essa rede primeiro, depois volte e informe o endereço.';

  @override
  String get connectAnswerWifiPhone =>
      'Escolha Wi-Fi. Entre nessa rede no telefone primeiro, depois volte e informe o endereço.';

  @override
  String get connectBleBody =>
      'Um adaptador BLE não precisa ser emparelhado antes. Busque e escolha o dispositivo — nomes comuns são OBDII, V-LINK, Vgate ou IOS-Vlink.';

  @override
  String connectBleEmptyScan(String next) {
    return 'A busca terminou sem encontrar um adaptador BLE. Verifique nesta ordem: a luz do adaptador está acesa — a maioria das tomadas OBD só tem energia com a ignição em ON; depois o alcance, então sente-se no carro antes de buscar. $next Um adaptador BLE não precisa e não deve ter emparelhamento nas configurações do sistema; esse caminho não funciona.';
  }

  @override
  String get connectBleEmptyScanNextClassic =>
      'Por último, confira a especificação na caixa: se diz 2.0 ou 3.0, isso é Bluetooth Classic, que nunca aparece nesta lista, então use Bluetooth Classic acima em vez disso.';

  @override
  String get connectBleEmptyScanNextWifi =>
      'Por último, confira a especificação na caixa: se diz 2.0/3.0, ou só Wi‑Fi, tente Wi‑Fi em vez disso (este host não oferece Bluetooth Classic).';

  @override
  String get connectBlePermissionDeniedForever =>
      'A permissão de Bluetooth foi permanentemente negada. O sistema não vai pedir de novo, então ative-a nas configurações do app.';

  @override
  String get connectBlePermissionNeeded =>
      'É necessária permissão de Bluetooth para buscar.';

  @override
  String get connectBleScan => 'Buscar dispositivos BLE';

  @override
  String get connectBleScanning => 'Buscando…';

  @override
  String get connectBleUnavailableHost =>
      'Bluetooth LE ainda não está disponível neste host';

  @override
  String get connectBluetoothOff =>
      'O Bluetooth está desligado. Ligue o Bluetooth nas configurações do sistema primeiro.';

  @override
  String get connectBluetoothPermissionDeniedForever =>
      'A permissão de Bluetooth foi negada permanentemente. Ative-a nas configurações do sistema e tente de novo.';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      'É necessária permissão de Bluetooth para listar adaptadores emparelhados.';

  @override
  String get connectBody =>
      'Conecte um adaptador ELM327 e ligue a ignição, ou use o simulador embutido.';

  @override
  String get connectCancel => 'Cancelar';

  @override
  String get connectClassicEmptyLinuxPort =>
      'Nenhuma porta serial Bluetooth (/dev/rfcomm*) encontrada. Emparelhe o ELM327 com o BlueZ primeiro, depois crie um TTY RFCOMM com rfcomm bind (ou equivalente) e tente de novo.';

  @override
  String get connectClassicEmptyPaired =>
      'Nenhum adaptador emparelhado encontrado. Emparelhe-o nas configurações de Bluetooth do sistema primeiro (o código da maioria dos ELM327 é 1234 ou 0000).';

  @override
  String get connectClassicEmptyWindowsPort =>
      'Nenhuma porta serial Bluetooth (COMx) encontrada. Emparelhe o ELM327 nas configurações de Bluetooth do Windows primeiro e verifique se o Gerenciador de Dispositivos mostra “Standard Serial over Bluetooth link”.';

  @override
  String get connectClassicListLinuxPort =>
      'Isto lista as portas seriais Bluetooth que o BlueZ vinculou (/dev/rfcomm* ou equivalente). Uma lista vazia significa que o sistema ainda não criou um nó RFCOMM, não que o app esteja quebrado.';

  @override
  String get connectClassicListPaired =>
      'Isto lista todos os dispositivos emparelhados com o sistema — fones e alto-falantes incluídos, com os que parecem adaptadores primeiro. Se escolher o errado, toque em Cancelar em vez de esperar falhar; você pode escolher outro na hora.';

  @override
  String get connectClassicListWindowsPort =>
      'Isto lista as portas COM associadas ao Bluetooth (“Standard Serial over Bluetooth link”). Uma lista vazia significa que o sistema ainda não criou uma porta serial virtual, não que o app esteja quebrado.';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic (SPP) está disponível atualmente no Android, macOS (IOBluetooth RFCOMM), Windows (COM) e Linux (/dev/rfcomm*)';

  @override
  String get connectClassicUnavailableIos =>
      'O iOS não abre Bluetooth SPP para apps de terceiros';

  @override
  String get connectConnect => 'Conectar';

  @override
  String get connectDemoBody =>
      'Simula um motor turbo de quatro cilindros 2.0 L em ciclos de marcha lenta, aceleração, cruzeiro e desaceleração, com sinais que permanecem fisicamente relacionados entre si (a rotação cai numa troca de marcha enquanto a velocidade na estrada continua subindo). Códigos de falha, leituras de VIN e consultas em lote fastMode funcionam por completo.';

  @override
  String get connectDemoStart => 'Iniciar o simulador';

  @override
  String get connectHandshakeTitle => 'Inicialização ELM327';

  @override
  String get connectHandshakeTitleLastAttempt =>
      'Inicialização ELM327 (última tentativa)';

  @override
  String get connectHeadline => 'Escolha uma conexão';

  @override
  String get connectIssueAdapterAcceptedThenSilent =>
      'O adaptador aceitou a conexão, mas não respondeu a tempo. Em geral ainda não tem energia — a maioria das tomadas OBD só alimenta com a ignição ligada — ou outro app já está conectado a ele; nesse caso feche o outro e tente de novo.';

  @override
  String connectIssueAdapterSilentOnReset(String command) {
    return 'O adaptador não respondeu ao comando de reinício ($command). Este dispositivo pode não ser um adaptador ELM327, ou a conexão pode ter ido para o dispositivo errado.';
  }

  @override
  String get connectIssueAdapterStoppedResponding =>
      'O adaptador parou de responder e a conexão foi encerrada.';

  @override
  String get connectIssueConnectionSetupFailed =>
      'A conexão falhou enquanto estava sendo estabelecida. Verifique se o adaptador tem energia e está por perto, depois tente de novo. O erro completo fica no registro abaixo.';

  @override
  String get connectIssueHandshakeIncomplete =>
      'A inicialização não passou. O adaptador pode não ser compatível.';

  @override
  String connectIssueHandshakeStepFailed(String command, String reason) {
    return 'A inicialização falhou em $command ($reason). Verifique se o adaptador está bem encaixado e se a ignição do veículo está ligada.';
  }

  @override
  String get connectIssuePreviousConnectionStillAborting =>
      'A conexão anterior ainda está sendo encerrada e o adaptador ainda não foi liberado. Espere alguns segundos e tente de novo.';

  @override
  String get connectLastAdapterConnect => 'Conectar agora';

  @override
  String get connectLastAdapterForget => 'Esquecer';

  @override
  String get connectLastAdapterTitle => 'Último adaptador usado';

  @override
  String get connectOpenAppSettings => 'Abrir configurações do app';

  @override
  String get connectOpenSystemSettings => 'Abrir configurações do sistema';

  @override
  String get connectOpeningConnection => 'Abrindo a conexão…';

  @override
  String get connectPairedPill => 'Emparelhado';

  @override
  String get connectQuestionBle =>
      'A caixa, o anúncio da loja ou o nome do dispositivo diz BLE, 4.0 ou 5.0?';

  @override
  String get connectQuestionClassic =>
      'Nenhum dos dois — um mais antigo, com 2.0 ou 3.0 impresso na caixa?';

  @override
  String get connectQuestionWifiDesktop =>
      'Há uma rede nova na lista de Wi-Fi do sistema (algo como V-LINK ou WiFi_OBDII)?';

  @override
  String get connectQuestionWifiPhone =>
      'Há uma rede nova na lista de Wi-Fi do telefone (algo como V-LINK ou WiFi_OBDII)?';

  @override
  String get connectSearchAgain => 'Buscar de novo';

  @override
  String connectSignalStrength(int bars, int total) {
    return 'Intensidade do sinal $bars/$total';
  }

  @override
  String get connectTranscriptKept =>
      'A transcrição completa desta tentativa foi guardada. Trazer isso de volta ajuda mais do que uma mensagem de uma linha.';

  @override
  String get connectTransportBleDescription =>
      'GATT UART — um adaptador mais recente de baixo consumo';

  @override
  String get connectTransportBleTitle => 'Bluetooth LE';

  @override
  String get connectTransportClassicDescription =>
      'RFCOMM / SPP — o ELM327 econômico mais comum';

  @override
  String get connectTransportClassicTitle => 'Bluetooth Classic';

  @override
  String get connectTransportDemoDescription =>
      'Uma ECU simulada embutida — o app inteiro sem hardware';

  @override
  String get connectTransportDemoTitle => 'Simulador Demo';

  @override
  String get connectTransportWifiDescription =>
      'Uma porta TCP, em geral 192.168.0.10:35000';

  @override
  String get connectTransportWifiTitle => 'Wi-Fi';

  @override
  String get connectWhichIntro =>
      'Não se preocupe com as palavras SPP e GATT. Vá pelo que o adaptador faz depois de plugado:';

  @override
  String get connectWhichNoteGuessing =>
      'Errar o palpite não custa nada — se não conectar, volte e tente outro. Se estiver realmente travado, use o simulador Demo no final para confirmar que o próprio app está funcionando.';

  @override
  String get connectWhichNoteIos =>
      'Um iPhone só pode usar Wi-Fi ou BLE — um ELM327 Bluetooth comum não funciona de jeito nenhum no iOS. Isso é um limite do sistema operacional, e nenhum outro app contorna.';

  @override
  String get connectWhichTitle => 'Não tem certeza de qual escolher?';

  @override
  String get connectWifiHostLabel => 'Endereço IP';

  @override
  String get connectWifiHostRequired => 'Informe o endereço IP do adaptador.';

  @override
  String get connectWifiInstructionsDesktop =>
      'Conecte este computador ao ponto de acesso Wi-Fi que o adaptador transmite primeiro, depois informe o endereço. Se o sistema avisar que a rede não alcança a internet, escolha permanecer nela. Sistemas desktop em geral tratam o ponto de acesso como rota padrão; a vinculação de rota Wi-Fi do Android não é necessária.';

  @override
  String get connectWifiInstructionsPhone =>
      'Primeiro, conecte o telefone ao ponto de acesso Wi-Fi transmitido pelo adaptador e depois informe o endereço. Se o sistema perguntar se deseja permanecer numa rede Wi-Fi sem acesso à internet, escolha permanecer nela. No Android, o Telltale tenta manter o tráfego vinculado à rota Wi-Fi enquanto estiver conectado, para que os dados móveis não desviem esse tráfego.';

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '“$value” não é uma porta válida. O intervalo é $min–$max.';
  }

  @override
  String get connectWifiPortLabel => 'Porta';

  @override
  String connectWifiPortRequired(int port) {
    return 'Informe a porta (a maioria dos adaptadores usa $port).';
  }

  @override
  String get dashboardBatchedPolling => 'Varredura em lote';

  @override
  String get dashboardBatchingEnabled => 'Agrupamento ativado';

  @override
  String get dashboardChoosePids => 'Escolher PIDs';

  @override
  String get dashboardEmptyBody =>
      'Escolha os sinais que quer acompanhar na página de PID e eles aparecerão aqui.';

  @override
  String get dashboardEmptyTitle => 'O painel está vazio';

  @override
  String get dashboardGenericObd => 'OBD genérico';

  @override
  String get dashboardLocalRecordings => 'Gravações locais';

  @override
  String get dashboardNotConnected => 'Não conectado';

  @override
  String get dashboardPollingModeHelpAction => 'Sobre o modo de varredura';

  @override
  String get dashboardPollingModeHelpBatching =>
      'Agrupamento ativado significa que o Telltale pode agrupar pedidos de PID num único intercâmbio, para reduzir o número de idas e voltas: tentativas agrupadas são permitidas e nada desativou o agrupamento. Ainda é permissão, não medição, porque se um intercâmbio agrupou algo também depende de quais PIDs o veículo confirmou e de quantos estão na fila.';

  @override
  String get dashboardPollingModeHelpObserved =>
      'Varredura em lote significa que um comando Mode 01 nesta conexão de fato carregou mais de um PID. É um registro desse intercâmbio, não uma promessa de que o próximo vai agrupar, e não uma afirmação sobre vazão.';

  @override
  String get dashboardPollingModeHelpRate =>
      'PIDs/s é uma taxa observada no último segundo, não uma promessa sobre latência, atualidade ou precisão. Ela muda com o adaptador, o barramento, a ECU, os PIDs que você selecionou, o tamanho de cada resposta e quaisquer erros.';

  @override
  String get dashboardPollingModeHelpSingle =>
      'Modo de pedido único significa que cada PID Mode 01 é lido sozinho. O Telltale usa isso quando o barramento não aceita pedidos agrupados de jeito nenhum, o que vale para todo veículo que não é CAN; enquanto nenhum bloco de suporte respondeu ainda, porque agrupar PIDs que o veículo não confirmou é o que faz a resposta voltar curta; e depois que um pedido agrupado falha em voltar numa forma que se possa separar de novo, seja truncado, recusado porque o adaptador reportou buffer cheio, ou sem resposta. As leituras continuam atualizando, e por si só isso não é uma falha de conexão.';

  @override
  String get dashboardPollingModeHelpTitle => 'Modo de varredura';

  @override
  String get dashboardSingleRequestMode => 'Modo de pedido único';

  @override
  String get dashboardVinRead => 'VIN lido';

  @override
  String get dashboardWorkspaceGauges => 'Medidores';

  @override
  String get dashboardWorkspaceTrends => 'Tendências';

  @override
  String get datumBadgeCommunityDecode => 'Decodificação da comunidade';

  @override
  String get datumBadgeDemo => 'Simulado';

  @override
  String get datumBadgeEstimated => 'Estimado';

  @override
  String get datumBadgeExperimental => 'Experimental';

  @override
  String get datumBadgeFieldVerified => 'Verificado em campo';

  @override
  String get datumBadgeInvalid => 'Inválido';

  @override
  String get datumBadgeJustUpdated => 'Acabou de atualizar';

  @override
  String get datumBadgeOutOfReferenceRange => 'Fora da faixa';

  @override
  String get datumBadgePartial => 'Parcial';

  @override
  String get datumBadgeStale => 'Desatualizado';

  @override
  String get datumBadgeTentativeDecode => 'Decodificação provisória';

  @override
  String get datumBadgeUnverified => 'Não verificado';

  @override
  String get datumBadgeUnverifiedOnThisVehicle =>
      'Não verificado neste veículo';

  @override
  String get datumBadgeUserSupplied => 'Fornecido pelo usuário';

  @override
  String get datumGapModelYearUnknown => 'Ano do modelo desconhecido';

  @override
  String get datumGapNoCatalogMatch => 'Sem correspondência no catálogo';

  @override
  String get datumGapVinNotRead => 'VIN não lido';

  @override
  String get datumNextStepEstimateOnly =>
      'Isso afeta só a estimativa; as outras leituras ainda valem.';

  @override
  String get datumNextStepGenericObd =>
      'Você pode seguir com OBD genérico, ou escolher o veículo manualmente e preencher os parâmetros.';

  @override
  String get datumNextStepOtherReadings =>
      'A falha afeta só este item; as outras leituras ainda valem.';

  @override
  String get datumNextStepRawOnly =>
      'A resposta bruta e o erro podem ser inspecionados; nenhum dos dois pode ser lido como um valor normal.';

  @override
  String get datumReasonAssumptionsUnconfirmed =>
      'As premissas não estão confirmadas; ainda assim uma estimativa é exibida.';

  @override
  String get datumReasonBusError => 'Erro no barramento.';

  @override
  String get datumReasonFormulaError => 'Erro na fórmula.';

  @override
  String get datumReasonFuelEstimateMissingInputs =>
      'A estimativa de consumo de combustível está sem uma entrada necessária.';

  @override
  String get datumReasonHeaderNotOnThisBus =>
      'O cabeçalho não corresponde ao barramento que este veículo usa.';

  @override
  String get datumReasonHorsepowerEstimateMissingInputs =>
      'A estimativa de potência está sem uma entrada necessária.';

  @override
  String get datumReasonMalformedPacket =>
      'Pacote malformado; só a resposta bruta pode ser inspecionada.';

  @override
  String get datumReasonNoAnswer =>
      'Sem resposta — o app tenta de novo em cerca de um minuto.';

  @override
  String get datumReasonNoReadingYet => 'Ainda sem leitura.';

  @override
  String get datumReasonNonFiniteValue => 'Não é um número finito.';

  @override
  String get datumReasonOutOfReferenceRangeKept =>
      'Fora da faixa de referência usual; mantido como foi lido.';

  @override
  String get datumReasonPidUnsupported =>
      'Este veículo não oferece suporte a este PID.';

  @override
  String get datumReasonUnsafeService =>
      'Este serviço não é uma consulta somente leitura.';

  @override
  String get datumReasonUnsafeServiceStopped =>
      'Este serviço não é uma consulta somente leitura, então não foi enviado.';

  @override
  String get datumStatusAssumptions => 'Premissas';

  @override
  String get datumStatusClose => 'Fechar';

  @override
  String get datumStatusFollowsData => 'O status segue os dados';

  @override
  String get datumStatusDetailsHint =>
      'Toque para detalhes do status dos dados';

  @override
  String get datumStatusUnverifiedExplanation =>
      'Não verificado significa que nenhuma comparação em veículo real para este decodificador no seu veículo está documentada aqui. Não significa que a leitura está errada, e não certifica a precisão. Atualidade e falhas são mostradas à parte.';

  @override
  String get datumStatusFormula => 'Fórmula';

  @override
  String get derivedAirflow => 'Fluxo de ar';

  @override
  String get derivedEcuFuelTitle => 'Dados de combustível da ECU';

  @override
  String get derivedEcuReported => 'Reportado pela ECU';

  @override
  String get derivedEngineHorsepower => 'Potência do motor';

  @override
  String get derivedEstimatedFuelTitle => 'Consumo de combustível estimado';

  @override
  String get derivedEstimatesDetailsTitle =>
      'Fórmulas e premissas das estimativas';

  @override
  String get derivedEstimatesTitle => 'Valores estimados';

  @override
  String get derivedFuelUse => 'Consumo';

  @override
  String get derivedTorque => 'Torque';

  @override
  String get derivedUnavailableMessage =>
      'A potência só pode ser estimada quando chegarem dados de velocidade do veículo e aceleração';

  @override
  String dtcBothSilentDetail(Object mode) {
    return 'O veículo não respondeu à consulta Mode $mode, e o Mode 03 também não respondeu — então não dá para saber se o veículo não oferece suporte ou se esta conexão simplesmente não leu.';
  }

  @override
  String dtcCategoryFault(Object category) {
    return 'Uma falha relacionada a $category';
  }

  @override
  String get dtcClear => 'Limpar';

  @override
  String get dtcClearCancel => 'Cancelar';

  @override
  String get dtcClearConfirm => 'Limpar mesmo';

  @override
  String get dtcClearDialogBody =>
      'Isso limpa os códigos de falha armazenados e pendentes e desliga a luz de falha, e também reinicia a prontidão de emissões — o veículo precisa completar de novo uma rodada inteira de autodiagnóstico antes de poder passar numa inspeção. Códigos de falha permanentes (Mode 0A) não podem ser limpos.';

  @override
  String get dtcClearDialogFrameUnread =>
      'Este escaneamento não leu um quadro congelado — isso não significa que o veículo não tenha nenhum. Escaneie de novo primeiro e só então decida se vai limpar.';

  @override
  String dtcClearDialogFrames(Object codes) {
    return 'O quadro congelado de $codes vai junto — o registro inteiro de rotação do motor, temperatura do líquido de arrefecimento e carga no momento em que a falha ocorreu — e não pode ser lido de novo até a falha acontecer outra vez.';
  }

  @override
  String get dtcClearDialogTitle => 'Limpar códigos de falha?';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categorias nesta varredura não responderam por completo',
      one: 'Uma categoria nesta varredura não respondeu por completo',
    );
    return '$_temp0 ($categories), então pode haver códigos de falha que você ainda não viu. Depois de limpar, eles nunca mais poderão ser lidos.';
  }

  @override
  String get dtcClearCancelledBeforeSend =>
      'A limpeza foi cancelada antes de qualquer comando sair do app. Escaneie de novo e tente outra vez se ainda quiser limpar.';

  @override
  String get dtcClearConfirmed => 'O comando de limpeza foi enviado.';

  @override
  String get dtcClearFailureDoNotRepeat =>
      'Uma limpeza pode já ter chegado ao veículo. Não envie outra — uma segunda limpeza global pode reiniciar a prontidão de emissões num controlador que pode já ter limpo. Escaneie de novo para ver o que restou.';

  @override
  String get dtcClearFailureGeneric =>
      'A limpeza não terminou. Escaneie de novo para ver os códigos atuais antes de decidir se tenta outra vez.';

  @override
  String get dtcClearNotAccepted =>
      'A limpeza falhou; nenhum controlador aceitou o comando. Você pode tentar de novo.';

  @override
  String get dtcClearPartiallyConfirmed =>
      'Pelo menos um controlador reportou que a limpeza terminou, e o restante não pôde ser confirmado. Não envie outra limpeza — repetir reinicia a prontidão de emissões em controladores que já terminaram. Escaneie de novo para ver o resultado.';

  @override
  String get dtcClearPreviousConnectionUnconfirmed =>
      'Uma conexão anterior enviou uma limpeza cujo resultado não foi confirmado. Escaneie de novo primeiro, veja quais códigos restam, depois decida se limpa.';

  @override
  String get dtcClearRescanSettled =>
      'A limpeza anterior não pôde ser confirmada por completo. O que segue é o estado real depois desta nova varredura.';

  @override
  String get dtcClearSentUnconfirmed =>
      'O comando de limpeza foi enviado, mas a resposta foi danificada no trânsito, então não se sabe se o veículo limpou. Escaneie de novo para verificar; não envie outra limpeza — se já tiver funcionado, repetir reinicia a prontidão de emissões.';

  @override
  String get dtcClearTimeout =>
      'Nada respondeu depois que a limpeza foi enviada, então não se sabe se o veículo limpou. Escaneie de novo para verificar. Não envie outra limpeza às cegas.';

  @override
  String get dtcClearUnexpected =>
      'A limpeza falhou, então não se sabe se o veículo limpou. Escaneie de novo para verificar. Não envie outra limpeza às cegas.';

  @override
  String get dtcClearing => 'Limpando…';

  @override
  String get dtcScanDisconnectedMidScan =>
      'A conexão caiu durante a varredura, então esta varredura não terminou.';

  @override
  String get dtcScanInterrupted =>
      'A varredura foi interrompida (o app pode ter ido para segundo plano, ou a conexão mudou) e não obteve um resultado completo. Escaneie de novo.';

  @override
  String get dtcCompleteCleanBody =>
      'Isso significa que todos os controladores que responderam informaram não haver códigos de falha. Não significa que todos os módulos do veículo tenham sido consultados.';

  @override
  String get dtcCompleteCleanTitle =>
      'Nenhum dos controladores que responderam reportou um código de falha.';

  @override
  String dtcControllerLabel(Object controller) {
    return 'Controlador $controller';
  }

  @override
  String get dtcDismiss => 'Dispensar';

  @override
  String dtcFreezeFrameBody(Object code) {
    return 'Os valores que este controlador registrou no instante em que $code foi confirmado. Limpar códigos de falha destrói este registro junto.';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      'Este controlador tem um quadro congelado, mas não respondeu à consulta perguntando quais itens estão nele, então o conteúdo não pôde ser lido. Uma nova varredura pode funcionar.';

  @override
  String get dtcFreezeFrameNothingDecodable =>
      'Este controlador tem um quadro congelado, mas nenhum dos itens nele é dos que este app consegue decodificar.';

  @override
  String get dtcFreezeFrameTitle => 'O veículo no momento da falha';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Mais $count itens neste quadro congelado não têm fórmula de conversão neste app, então não estão listados.',
      one: 'Mais um item neste quadro congelado não tem fórmula de conversão neste app, então não está listado.',
    );
    return '$_temp0';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count itens não voltaram desta vez (pode não ter havido tempo suficiente, ou o controlador não respondeu). Uma nova varredura pode lê-los.',
      one: 'Um item não voltou desta vez (pode não ter havido tempo suficiente, ou o controlador não respondeu). Uma nova varredura pode lê-lo.',
    );
    return '$_temp0';
  }

  @override
  String get dtcFreezeFrameUnreadPanel =>
      'Este escaneamento não leu um quadro congelado — isso não significa que o veículo não tenha nenhum. Escaneie de novo primeiro e só então decida se vai limpar os códigos de falha, porque limpar destrói permanentemente o registro do momento da falha. Se todos os escaneamentos forem iguais, este veículo pode não fornecer um.';

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label (Mode $mode) · $count';
  }

  @override
  String get dtcHeadline => 'Códigos de falha';

  @override
  String get dtcListSeparator => ', ';

  @override
  String get dtcManufacturerSpecific =>
      'Código específico do fabricante — consulte o manual de serviço deste veículo';

  @override
  String get dtcMilOff => 'A luz de falha não está acesa';

  @override
  String get dtcMilOn => 'A luz de falha está acesa';

  @override
  String get dtcMonitorBoostPressure => 'Pressão de sobrealimentação';

  @override
  String get dtcMonitorCatalyst => 'Catalisador';

  @override
  String get dtcMonitorComponents => 'Monitor de componentes';

  @override
  String get dtcMonitorEgr => 'Sistema EGR / VVT';

  @override
  String get dtcMonitorEvaporative => 'Sistema evaporativo';

  @override
  String get dtcMonitorExhaustSensor => 'Sensor de escape';

  @override
  String get dtcMonitorFuelSystem => 'Sistema de combustível';

  @override
  String get dtcMonitorGasolineParticulateFilter =>
      'Filtro de partículas de gasolina (GPF)';

  @override
  String get dtcMonitorHeatedCatalyst => 'Catalisador aquecido';

  @override
  String get dtcMonitorMisfire => 'Falha de ignição';

  @override
  String get dtcMonitorNmhcCatalyst => 'Catalisador NMHC';

  @override
  String get dtcMonitorNoxAftertreatment => 'Pós-tratamento NOx / SCR';

  @override
  String get dtcMonitorOxygenSensor => 'Sensor de oxigênio';

  @override
  String get dtcMonitorOxygenSensorHeater => 'Aquecedor do sensor de oxigênio';

  @override
  String get dtcMonitorParticulateFilter => 'Filtro de partículas';

  @override
  String get dtcMonitorSecondaryAir => 'Sistema de ar secundário';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — este app não tem descrição detalhada para este código';
  }

  @override
  String get dtcNotConnectedBody =>
      'Ler códigos de falha precisa de um adaptador ELM327 conectado, ou do simulador em execução.';

  @override
  String get dtcNotConnectedTitle => 'Não conectado';

  @override
  String get dtcNotScanned => 'Ainda não escaneado';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count controladores',
      one: 'Um controlador',
    );
    return 'As três categorias foram consultadas até o fim. $_temp0 ($controllers): nenhum implementa códigos de falha pendentes nem permanentes — isso é normal em muitos veículos e também impede declarar que este veículo não tem falhas.';
  }

  @override
  String get dtcPartialCleanTitle =>
      'As categorias que responderam não reportaram códigos de falha.';

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories não responderam, então o estado delas não pode ser confirmado — isso não é o mesmo que o veículo não ter problema.';
  }

  @override
  String dtcPartialCodesRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count códigos de falha foram lidos',
      one: 'Um código de falha foi lido',
    );
    return '$_temp0 antes desta categoria parar, mas a cobertura está incompleta:';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return 'Só alguns controladores nesta categoria responderam e o restante não respondeu, então isso não pode valer como resultado para o veículo inteiro. $message';
  }

  @override
  String get dtcReadFailed => 'Leitura falhou';

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label (Mode $mode): $message';
  }

  @override
  String get dtcReadinessAllComplete =>
      'Todo monitor de prontidão pelo qual este controlador é responsável está completo.';

  @override
  String dtcReadinessIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monitores ainda estão incompletos',
      one: '1 monitor ainda está incompleto',
    );
    return '$_temp0 — uma inspeção agora pode não passar.';
  }

  @override
  String get dtcReadinessSaysNothing =>
      'Este controlador não reportou nenhum monitor de prontidão — pode não ser responsável pelo monitoramento de emissões, e isso não significa que está pronto.';

  @override
  String get dtcReadinessTitle => 'Prontidão de emissões';

  @override
  String get dtcRescanFirst => 'Escaneie de novo primeiro';

  @override
  String get dtcRetry => 'Tentar de novo';

  @override
  String get dtcScanBody =>
      'Lê códigos de falha armazenados Mode 03, pendentes Mode 07 e permanentes Mode 0A.';

  @override
  String get dtcScanTitle => 'Escanear o veículo em busca de códigos de falha';

  @override
  String get dtcScanning => 'Escaneando…';

  @override
  String dtcSelfReportedCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Este controlador reporta por si mesmo $count códigos de falha confirmados.',
      one:
          'Este controlador reporta por si mesmo 1 código de falha confirmado.',
    );
    return '$_temp0';
  }

  @override
  String get dtcSelfReportedNoCodes =>
      'Segundo este controlador, não há códigos de falha confirmados.';

  @override
  String get dtcSilentCategoryHeadline => 'Esta categoria não respondeu';

  @override
  String get dtcSilentPendingDetail =>
      'Códigos de falha pendentes (Mode 07) não responderam. Esta ECU pode não implementar o serviço, ou a leitura simplesmente pode não ter sido obtida desta vez — a ausência de resposta não permite distinguir as duas possibilidades e não deve ser interpretada como ausência de falhas pendentes. O resultado dos códigos de falha armazenados não é afetado.';

  @override
  String get dtcSilentPermanentDetail =>
      'Códigos de falha permanentes (Mode 0A) não responderam. Esta categoria chegou com a geração OBD-II por volta de 2010, então veículos mais antigos nem sempre a suportam — mas a ausência de resposta também pode significar que a leitura simplesmente não foi obtida desta vez, e não é possível distinguir as duas possibilidades. O resultado dos códigos de falha armazenados não é afetado.';

  @override
  String get dtcStartScan => 'Iniciar varredura';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return 'O veículo não respondeu à consulta Mode $mode, então não se pode confirmar se ele tem códigos de falha armazenados. Isso não é a mesma coisa que não ter códigos de falha.';
  }

  @override
  String dtcTotalCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count códigos',
      one: '1 código',
    );
    return '$_temp0';
  }

  @override
  String get dtcUnconfirmed => 'Não é possível confirmar';

  @override
  String get dtcUnknownError => 'Erro desconhecido';

  @override
  String get dtcUnknownMonitor => 'Monitor desconhecido';

  @override
  String get dtcVerdictCompleteClean =>
      'Nenhum código de falha dos controladores que responderam';

  @override
  String get dtcVerdictPartialClean => 'Parcialmente não confirmado';

  @override
  String get fieldEventBody =>
      'Toque somente com o veículo completamente parado. A ação deve ser feita por um passageiro ou por um operador com o veículo estacionado. Os eventos compartilham uma linha do tempo com os dados OBD brutos, e o app tenta salvá-los imediatamente.';

  @override
  String get fieldEventEngineStarted => 'Motor ligado';

  @override
  String get fieldEventHeading => 'Marcadores de evento de campo';

  @override
  String get fieldEventIgnitionOn => 'Ignição ligada';

  @override
  String get fieldEventMemoryOnly =>
      'Registrado nesta sessão, mas a gravação automática falhou — exporte a transcrição agora.';

  @override
  String fieldEventRecorded(String marker) {
    return 'Registrado e salvo: $marker';
  }

  @override
  String get fieldEventRoadTestStarted => 'Teste de estrada iniciado';

  @override
  String get fieldEventThrottleBlip => 'Toque no acelerador';

  @override
  String get fieldEventUnavailable =>
      'Não há conexão ao vivo com o veículo para registrar.';

  @override
  String get gaugeNoData => 'Sem dados';

  @override
  String gaugeNoDataBecause(String reason) {
    return 'Sem dados — $reason';
  }

  @override
  String gaugeReadingStale(String reading) {
    return '$reading (dados desatualizados)';
  }

  @override
  String get gaugeUnsupportedByVehicle => 'Não suportado por este veículo';

  @override
  String get handshakeNoteAborted =>
      'Interrompido depois que um passo anterior falhou.';

  @override
  String get handshakeNoteEcuRefusedSupportQuery =>
      'A ECU recusou a consulta de suporte (resposta negativa).';

  @override
  String get handshakeNoteEcuSilent => 'A ECU não respondeu.';

  @override
  String get handshakeNoteNotAcknowledged =>
      'O adaptador não enviou uma confirmação para este comando.';

  @override
  String get handshakeNoteNotModeOnePositiveReply =>
      'A resposta não é uma resposta positiva Mode 01.';

  @override
  String get handshakeNotePidEchoMismatch =>
      'A resposta ecoa um PID diferente do que foi pedido.';

  @override
  String get handshakeNoteSupportMaskTooShort =>
      'A resposta de suporte é curta demais; são necessários 41 00 e mais quatro bytes.';

  @override
  String get handshakeNoteTimedOut => 'Tempo esgotado.';

  @override
  String get handshakeStepAdapterVersion => 'Ler a versão do adaptador';

  @override
  String get handshakeStepAdaptiveTiming =>
      'Ativar temporização adaptativa, o ajuste que a folha de dados recomenda';

  @override
  String get handshakeStepBatteryVoltage => 'Ler a tensão da bateria';

  @override
  String get handshakeStepDeviceIdentity =>
      'Ler a string de identificação do dispositivo';

  @override
  String get handshakeStepEchoOff => 'Desligar o eco de comandos';

  @override
  String get handshakeStepLinefeedsOff => 'Desligar quebras de linha';

  @override
  String get handshakeStepMemoryOff => 'Desligar gravações na memória';

  @override
  String get handshakeStepNoReason => 'sem resposta';

  @override
  String get handshakeStepProtocolAuto =>
      'Detectar o protocolo do barramento automaticamente';

  @override
  String get handshakeStepProtocolDescription => 'Ler a descrição do protocolo';

  @override
  String get handshakeStepProtocolNumber => 'Ler o número do protocolo';

  @override
  String get handshakeStepReset => 'Reiniciar o adaptador por software';

  @override
  String get handshakeStepResponseTimeout =>
      'Definir o tempo limite de resposta em cerca de 408 ms';

  @override
  String get handshakeStepSpacesOff =>
      'Desligar espaços, cortando um terço do tráfego';

  @override
  String get handshakeStepSupportProbe =>
      'Perguntar a quais PIDs a ECU oferece suporte, comprovando que um veículo respondeu';

  @override
  String get languageSaveFailed =>
      'Não foi possível salvar o idioma. Tente de novo.';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get navDashboard => 'Painel';

  @override
  String get navDtc => 'Códigos de falha';

  @override
  String get navPerformance => 'Tempo';

  @override
  String get navPid => 'PID';

  @override
  String get navSettings => 'Configurações';

  @override
  String get performanceArm => 'Armar o cronômetro';

  @override
  String get performanceDisclaimer =>
      'Os tempos vêm do sinal OBD de velocidade na estrada. A maioria dos veículos lê 1–3 km/h a mais no próprio velocímetro, e o sinal atualiza só cerca de 10–20 vezes por segundo, então um resultado aqui é apenas indicativo — não equivalente a equipamento de teste profissional.';

  @override
  String get performanceHeadline => 'Teste de aceleração';

  @override
  String get performanceNoSpeedSignal =>
      'Não há sinal válido de velocidade na estrada agora (PID 010D). O teste de aceleração não consegue cronometrar uma corrida sem ele.';

  @override
  String get performanceNotConnectedBody =>
      'O teste de aceleração precisa de velocidade na estrada ao vivo. Conecte um adaptador, ou inicie o simulador embutido.';

  @override
  String get performanceNotConnectedTitle => 'Não conectado';

  @override
  String get performancePeakSpeed => 'Velocidade máxima';

  @override
  String get performanceReset => 'Reiniciar';

  @override
  String get performanceSecondsUnit => 'segundos';

  @override
  String get performanceSpeedGaugeLabel => 'Velocidade';

  @override
  String get performanceSpeedTraceHeading => 'Traçado de velocidade';

  @override
  String get performanceSplitsHeading => 'Parciais';

  @override
  String get performanceStateAborted =>
      'Esta corrida não foi concluída; abaixo está o que foi registrado antes de parar';

  @override
  String get performanceStateAwaitingSpeedSignal =>
      'Aguardando um sinal de velocidade';

  @override
  String performanceStateAwaitingStandstill(String speed) {
    return 'Pare completamente primeiro — agora $speed km/h';
  }

  @override
  String performanceStateFinished(int target) {
    return 'Concluído 0 → $target km/h';
  }

  @override
  String get performanceStateIdle => 'Escolha uma velocidade alvo e comece';

  @override
  String get performanceStateRunning => 'Cronometrando';

  @override
  String get performanceStateStaged =>
      'Pronto — o cronômetro começa quando você sair';

  @override
  String get performanceSubhead =>
      'Uma corrida cronometrada de partida parada até uma velocidade alvo';

  @override
  String get performanceTargetSpeedHeading => 'Velocidade alvo';

  @override
  String get pidActionCancel => 'Cancelar';

  @override
  String get pidActionDelete => 'Excluir';

  @override
  String get pidArrangeBody =>
      'Arraste para reordenar. O painel preenche da esquerda para a direita e de cima para baixo, então o que estiver primeiro é visto primeiro.';

  @override
  String get pidArrangeEmptyMessage =>
      'Ative alguns na lista primeiro, depois volte para ordená-los.';

  @override
  String get pidArrangeEmptyTitle => 'Nenhum PID está ativado ainda';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return 'Adicionar os $count confirmados';
  }

  @override
  String get pidBulkActionAllActive => 'Todos já ativados';

  @override
  String get pidBulkActionIncomplete =>
      'Os dados da varredura estão incompletos';

  @override
  String get pidBulkActionLocked => 'Não é possível alterar durante a gravação';

  @override
  String get pidBulkActionPending => 'Aguardando resultados da varredura';

  @override
  String get pidBulkActionZero => 'Sem PIDs com suporte confirmado';

  @override
  String pidBulkAddCount(int count) {
    return 'Adicionar $count';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return 'Adicionar $count PIDs com suporte confirmado?';
  }

  @override
  String pidBulkAdded(int count) {
    return 'Adicionados $count PIDs com suporte confirmado.';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '$count blocos de suporte ainda não estão confirmados — isto adiciona só os itens com evidência positiva.';
  }

  @override
  String pidBulkWillAdd(int count) {
    return 'Vai adicionar $count. Quanto mais PIDs estiverem ativados, menos vezes cada um pode atualizar.';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '$confirmed confirmados';
  }

  @override
  String get pidCapabilityCoverageNone =>
      'Nenhuma cobertura contígua estabelecida ainda';

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return 'Cobertura contígua 01–$through (chegou ao fim)';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return 'Cobertura contígua 01–$through (desconhecido além)';
  }

  @override
  String get pidCapabilityPhaseAttemptFinished =>
      'Esta varredura de suporte terminou';

  @override
  String get pidCapabilityPhaseInterrupted =>
      'A varredura de suporte foi interrompida';

  @override
  String get pidCapabilityPhaseNotStarted => 'Varredura não iniciada';

  @override
  String get pidCapabilityPhaseRunning =>
      'Confirmando a que este veículo oferece suporte';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return 'PIDs com suporte do veículo. $phase. $confirmed confirmados. $unknown blocos desconhecidos.';
  }

  @override
  String get pidCapabilityTitle => 'PIDs com suporte do veículo';

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '$unknown blocos desconhecidos';
  }

  @override
  String pidEditorCollision(String name) {
    return 'Um PID personalizado já usa esta combinação ($name). Use outro mode + PID, cabeçalho ou sufixo de nome.';
  }

  @override
  String pidEditorDeleteBody(String name) {
    return 'A definição de “$name” é removida, o medidor some do painel, e isso não pode ser desfeito.';
  }

  @override
  String get pidEditorDeleteTitle => 'Excluir este PID?';

  @override
  String get pidEditorDiscard => 'Descartar';

  @override
  String get pidEditorDiscardBody =>
      'As alterações neste PID não foram salvas, e sair as perde.';

  @override
  String get pidEditorDiscardTitle => 'Descartar alterações não salvas?';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N mapeiam para os bytes da resposta; SIGNED(), ABS(), LOG10(), $valSyntax e BARO estão disponíveis';
  }

  @override
  String get pidEditorFieldEquation => 'Expressão';

  @override
  String get pidEditorFieldHeader => 'Cabeçalho CAN';

  @override
  String get pidEditorFieldMax => 'Máximo';

  @override
  String get pidEditorFieldMin => 'Mínimo';

  @override
  String get pidEditorFieldModeAndPid => 'Mode + PID';

  @override
  String get pidEditorFieldName => 'Nome';

  @override
  String get pidEditorFieldSample => 'Bytes de resposta de teste';

  @override
  String get pidEditorFieldShortName => 'Nome curto (mostrado no medidor)';

  @override
  String get pidEditorFieldUnits => 'Unidades';

  @override
  String get pidEditorHeaderHelper => '7E0 = motor';

  @override
  String get pidEditorKeepEditing => 'Continuar editando';

  @override
  String get pidEditorModeAndPidHelper => 'Por exemplo 010C ou 221101';

  @override
  String get pidEditorSampleHelper =>
      'Digite hex para pré-visualizar o resultado enquanto digita';

  @override
  String get pidEditorSave => 'Salvar';

  @override
  String get pidEditorSectionFormula => 'Fórmula';

  @override
  String get pidEditorSectionIdentity => 'Identidade';

  @override
  String get pidEditorSectionQuery => 'Consulta';

  @override
  String get pidEditorSectionRangeAndPriority =>
      'Faixa do medidor e prioridade';

  @override
  String get pidEditorTitleEdit => 'Editar PID';

  @override
  String get pidEditorTitleNew => 'Novo PID personalizado';

  @override
  String pidExportFailed(String error) {
    return 'Falha na exportação: $error';
  }

  @override
  String get pidExportNoCustomPids =>
      'Não há PIDs personalizados para exportar.';

  @override
  String get pidImportNothingToImport => 'Nenhuma definição para importar.';

  @override
  String pidImportLandedClean(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importados $count PIDs personalizados.',
      one: 'Importado 1 PID personalizado.',
    );
    return '$_temp0';
  }

  @override
  String pidImportLandedWithNotes(int count, String notes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importados $count itens, $notes.',
      one: 'Importado 1 item, $notes.',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteSkippedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count linhas tiveram problemas e foram ignoradas',
      one: '1 linha teve problemas e foi ignorada',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDefaultedRanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count linhas usaram a faixa padrão do medidor',
      one: '1 linha usou a faixa padrão do medidor',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens substituíram definições existentes',
      one: '1 item substituiu uma definição existente',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDuplicatesInFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count linhas duplicavam outra linha no arquivo e foram ignoradas',
      one: '1 linha duplicava outra linha no arquivo e foi ignorada',
    );
    return '$_temp0';
  }

  @override
  String get pidImportPickerFailed =>
      'Não foi possível abrir o seletor de arquivos.';

  @override
  String get pidImportReadFailed => 'Não foi possível ler o arquivo.';

  @override
  String get pidListSeparator => ', ';

  @override
  String get pidManagerActiveOnly => 'Só ativos';

  @override
  String get pidManagerAdd => 'Novo';

  @override
  String get pidManagerArrangeDashboard => 'Organizar painel';

  @override
  String pidManagerCounts(int active, int total) {
    return '$active ativos · $total disponíveis';
  }

  @override
  String get pidManagerExportCsv => 'Exportar PIDs personalizados';

  @override
  String get pidManagerExportTorqueCsv => 'Exportar CSV compatível com Torque';

  @override
  String get pidManagerExportHumanReport =>
      'Exportar relatório de PIDs para leitura';

  @override
  String get pidManagerHeadline => 'Gerenciador de PIDs';

  @override
  String get pidManagerImportCsv => 'Importar CSV';

  @override
  String get pidManagerMoreActions => 'Mais';

  @override
  String get pidManagerNoMatchMessage =>
      'Tente outra palavra-chave ou crie um PID personalizado.';

  @override
  String get pidManagerNoMatchTitle => 'Nenhum PID correspondente';

  @override
  String get pidManagerPowertrainBatteryCatalog =>
      'Catálogo de bateria do trem de força';

  @override
  String get pidManagerSearchHint => 'Buscar por nome ou código PID…';

  @override
  String get pidPickCsvDialogTitle => 'Escolher um CSV de definição de PID';

  @override
  String get pidPillCustom => 'Personalizado';

  @override
  String get pidPillUnsupported => 'Não suportado';

  @override
  String get pidPreviewCannotEvaluate => 'Não é possível avaliar';

  @override
  String get pidPreviewResultLabel => 'Resultado';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'A prévia usa $valueString no lugar de $dependencies; o valor real vem desse PID após a conexão.';
  }

  @override
  String get pidPreviewTitle => 'Prévia ao vivo';

  @override
  String get pidPriorityHigh => 'Alta';

  @override
  String get pidPriorityLow => 'Baixa';

  @override
  String get pidPriorityMedium => 'Média';

  @override
  String get pidPriorityVeryLow => 'Muito baixa';

  @override
  String get pidRowEdit => 'Editar';

  @override
  String pidRowShowOnDashboard(String name) {
    return 'Mostrar $name no painel';
  }

  @override
  String pidRowStaleUnits(String units) {
    return '$units · desatualizado';
  }

  @override
  String powertrainAuthorizationGranted(String profile) {
    return 'Sinais de bateria de $profile estão ativos nesta conexão';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return 'Não foi possível ativar: $reason';
  }

  @override
  String get powertrainCancel => 'Cancelar';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return 'Perfis: $profiles · Leituras únicas: $probeable';
  }

  @override
  String get powertrainCatalogLoadFailedBody =>
      'A verificação de integridade não passou, então nenhum dado de veículo é exibido ou instalado.';

  @override
  String get powertrainCatalogLoadFailedTitle =>
      'O catálogo offline não pôde ser carregado';

  @override
  String get powertrainCatalogNotVerified =>
      'O catálogo não passou na verificação, por isso nada pode ser instalado.';

  @override
  String get powertrainCatalogRevalidate => 'Verificar de novo';

  @override
  String get powertrainCatalogScopeNote =>
      'O catálogo é amplo, mas “encontramos dados” não é “seu carro é suportado”. Entradas somente para pesquisa nunca carregam um comando. Entradas experimentais Mode 22 podem ser instaladas e varridas, mas cada valor é rotulado como não verificado; Mode 21 experimental é lido uma vez por confirmação.';

  @override
  String get powertrainCatalogSearchHint =>
      'Buscar marca, modelo, variante ou mercado…';

  @override
  String get powertrainCatalogTitle => 'Catálogo de bateria do trem de força';

  @override
  String get powertrainChooseCommandNote =>
      'Um comando por tentativa: sem varredura, sem lote, sem nova tentativa automática.';

  @override
  String get powertrainChooseCommandTitle =>
      'Escolher uma consulta somente leitura fixa';

  @override
  String get powertrainClose => 'Fechar';

  @override
  String get powertrainConfirmAccept => 'Este é o carro';

  @override
  String get powertrainConfirmBody =>
      'Os sinais do perfil instalado só são lidos depois que você confirma que este carro é aquele modelo, e a confirmação vale só para esta conexão.';

  @override
  String get powertrainConfirmButton => 'Confirmar veículo';

  @override
  String get powertrainConfirmDialogBody =>
      'Depois de confirmado, as consultas somente leitura de bateria deste perfil são varridas pelo resto desta conexão. O perfil errado pode produzir números que parecem plausíveis e estão errados — cancele se não tiver certeza.';

  @override
  String get powertrainConfirmDialogTitle => 'Confirmar o veículo conectado';

  @override
  String get powertrainConfirmTitle =>
      'Sinais da bateria do veículo aguardam confirmação';

  @override
  String get powertrainConnectFirst =>
      'Conecte primeiro; a autorização experimental nunca é mantida entre conexões.';

  @override
  String get powertrainConnectionChanged =>
      'A conexão mudou — confirme o veículo de novo para a nova conexão.';

  @override
  String get powertrainEnableLabInSettings =>
      'Ative primeiro o laboratório experimental de bateria em Configurações.';

  @override
  String get powertrainEvidencePhysicalVehicle => 'Veículo do projeto';

  @override
  String get powertrainEvidenceSourceBacked => 'Dados de origem';

  @override
  String get powertrainEvidenceSyntheticRig => 'Bancada sintética';

  @override
  String get powertrainExperimentalDataDisclosure =>
      'Esta é uma leitura candidata rotulada pelos autores da fonte, não uma garantia do fabricante nem de segurança entre modelos; o ELM327 apenas encaminha o comando. O comando bruto e a resposta ficam na transcrição diagnóstica local e não são enviados automaticamente por este recurso; valores decodificados nunca são instalados como PID nem adicionados a um medidor. Cancelar não afeta as funções OBD comuns.';

  @override
  String get powertrainExperimentalDialogTitle =>
      'Confirmar consulta experimental única e somente leitura';

  @override
  String get powertrainExperimentalIdentityAck =>
      'Verifiquei o mercado, o modelo e o ano-modelo que a fonte conhece, e aceito os campos não confirmados';

  @override
  String get powertrainExperimentalParkedAck =>
      'O veículo está estacionado com segurança; entendo que isto lê uma vez e o número ainda pode não se aplicar';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return 'Aceita RX $responder apenas, comprimento do payload $bytes bytes';
  }

  @override
  String get powertrainFieldListSeparator => ', ';

  @override
  String get powertrainFieldMarket => 'Mercado';

  @override
  String get powertrainFieldModel => 'Modelo';

  @override
  String get powertrainFieldModelYear => 'Ano-modelo';

  @override
  String get powertrainFieldVariant => 'Variante';

  @override
  String get powertrainFilterAll => 'Todos';

  @override
  String get powertrainIdentityEvidenceExact => 'evidência direta';

  @override
  String get powertrainIdentityEvidenceNone => 'nenhum';

  @override
  String get powertrainIdentityEvidenceSourcePartial => 'evidência parcial';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return 'Evidência de identidade da fonte: $fields\nCampos não confirmados: $unconfirmed';
  }

  @override
  String get powertrainIdentityEvidenceUnknown => 'desconhecido';

  @override
  String get powertrainInstallButton => 'Instalar sinais de bateria';

  @override
  String get powertrainInstallConfirm => 'Instalar';

  @override
  String get powertrainInstallDialogTitle =>
      'Instalar os sinais de bateria deste modelo';

  @override
  String get powertrainInstallDisclosureCommunity =>
      'Instalar só adiciona PIDs de bateria somente leitura ao gerenciamento de PIDs. Antes de qualquer leitura começar, cada conexão pede que você confirme no painel que este carro é aquele modelo. Os dados vêm de fontes da comunidade e foram corroborados de forma independente; ainda assim não são uma garantia do fabricante.';

  @override
  String get powertrainInstallDisclosureExperimental =>
      'Instalar só adiciona PIDs de bateria somente leitura ao gerenciamento de PIDs. Antes de qualquer leitura começar, cada conexão pede que você confirme no painel que este carro é aquele modelo. Esta é uma decodificação experimental sem exigência de corroboração independente, não verificada neste veículo, e ainda assim não é uma garantia do fabricante.';

  @override
  String get powertrainInstallDisclosureReady =>
      'Instalar só adiciona PIDs de bateria somente leitura ao gerenciamento de PIDs. Antes de qualquer leitura começar, cada conexão pede que você confirme no painel que este carro é aquele modelo. Os dados de origem são mais completos; ainda assim não são uma garantia do fabricante.';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      'Instalar só adiciona PIDs de bateria somente leitura ao gerenciamento de PIDs. Antes de qualquer leitura começar, cada conexão pede que você confirme no painel que este carro é aquele modelo. Esta entrada é só para pesquisa e não deve ser instalada.';

  @override
  String get powertrainInstallCatalogShaMissing =>
      'Não é possível instalar: este snapshot do catálogo não tem SHA-256 verificado, por isso não é possível confiar em nenhum dado dele.';

  @override
  String get powertrainInstallPersistFailed =>
      'Não é possível instalar: a lista de perfis instalados não pôde ser salva. Tente de novo; nada foi adicionado ao gerenciamento de PIDs.';

  @override
  String get powertrainInstallProfileNotInCatalog =>
      'Não é possível instalar: esse perfil não está no catálogo verificado.';

  @override
  String get powertrainInstallProfileNotInstallable =>
      'Não é possível instalar: este perfil não está em um estado que possa se tornar PIDs ativos.';

  @override
  String get powertrainInstallYearOutOfRange =>
      'Não é possível instalar: esse ano-modelo está fora da faixa de anos documentada deste perfil.';

  @override
  String get powertrainInstallIdentityAck =>
      'Meu veículo corresponde ao mercado, modelo e ano-modelo acima';

  @override
  String get powertrainInstalledRemoveButton => 'Instalado · remover sinais';

  @override
  String powertrainInstalledSignalsSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Instalados $count sinais. Adicione-os ao painel na página de PIDs; cada conexão precisa de uma confirmação do veículo.',
      one: 'Instalado 1 sinal. Adicione-o ao painel na página de PIDs; cada conexão precisa de uma confirmação do veículo.',
    );
    return '$_temp0';
  }

  @override
  String get powertrainNoMatchBody =>
      'Tente um nome de marca ou modelo, ou mude para outro tipo de trem de força.';

  @override
  String get powertrainNoMatchTitle => 'Nenhum veículo correspondente';

  @override
  String get powertrainNotInstallableInThisRelease =>
      'Não instalável nesta versão';

  @override
  String powertrainPrimarySource(String name, String license) {
    return 'Fonte principal: $name ($license)';
  }

  @override
  String get powertrainProbeChecksPassed =>
      'Passou nas verificações do emissor da resposta, do eco, do comprimento exato, da fórmula e da faixa.';

  @override
  String get powertrainProbeConnectForOneShot =>
      'Conecte para uma consulta única somente leitura';

  @override
  String get powertrainProbeConnectToTryOnce =>
      'Conecte para tentar uma leitura primeiro';

  @override
  String get powertrainProbeDidNotFinish =>
      'A consulta única não terminou; nenhum valor foi publicado ou mantido.';

  @override
  String get powertrainProbeEnableLabFirst =>
      'Ative primeiro o laboratório em Configurações';

  @override
  String get powertrainProbeInProgress => 'Lendo uma vez…';

  @override
  String get powertrainProbeNoValuePublished =>
      'Nenhum valor foi publicado; um erro estrutural ou de decodificação fica em quarentena até você reconectar.';

  @override
  String get powertrainProbeOnceButton => 'Ler só uma vez';

  @override
  String get powertrainProbePassedTitle => 'Consulta única passou';

  @override
  String get powertrainProbePickOneRead => 'Escolha um comando, leia uma vez';

  @override
  String get powertrainProbeReconnectFirst => 'Reconecte e tente de novo';

  @override
  String get powertrainProbeRefusedTitle => 'Consulta única recusada';

  @override
  String get powertrainProbeTryOnceFirst => 'Tente uma leitura primeiro';

  @override
  String get powertrainProfileNotVerified =>
      'O perfil não está no catálogo verificado';

  @override
  String get powertrainQuarantinedPill => 'Em quarentena · reconectar';

  @override
  String get powertrainRefusedCatalogHashInvalid =>
      'Não autorizado: o hash de integridade do catálogo não é válido, por isso nada nele pode ser lido.';

  @override
  String get powertrainRefusedCommandNotInProfile =>
      'Não autorizado: esse comando não é um dos comandos próprios deste perfil verificado.';

  @override
  String get powertrainRefusedLabClosed =>
      'O laboratório experimental de bateria foi desligado antes que esta leitura pudesse ser autorizada.';

  @override
  String get powertrainRefusedProfileFailedValidation =>
      'Não autorizado: este perfil não passou na validação do catálogo com o ano-modelo que você escolheu.';

  @override
  String get powertrainRefusedProfileNotInCatalog =>
      'Não autorizado: este perfil não está no catálogo verificado.';

  @override
  String get powertrainRefusedProfileNotProbeable =>
      'Não autorizado: este perfil não é um que possa ser lido uma vez experimentalmente.';

  @override
  String get powertrainRefusedQuarantinedAfterRejectedRead =>
      'Em quarentena nesta conexão: uma leitura única anterior não passou nas verificações estruturais. Reconecte antes de tentar de novo.';

  @override
  String get powertrainRefusedNotConnectedOrNotInForeground =>
      'A leitura única não foi iniciada: nada está conectado, ou o app não estava em primeiro plano.';

  @override
  String get powertrainRefusedNoLiveAuthorization =>
      'A leitura única não foi iniciada: nenhuma autorização de uso único está sendo mantida. Nenhuma foi dada, ou expirou, entrou em cooldown, ou foi colocada em quarentena.';

  @override
  String get powertrainRefusedDiscardedAtLifecycleBoundary =>
      'A conexão ou o estado em primeiro plano mudou enquanto a leitura única estava em andamento, por isso a resposta foi descartada em vez de mostrada. Nada falhou, e nada foi mantido.';

  @override
  String powertrainRefusedQuarantinedAtAttemptCap(int attemptCap) {
    return 'Em quarentena nesta conexão: o mesmo comando já foi tentado $attemptCap vezes. Reconecte antes de tentar de novo.';
  }

  @override
  String get powertrainResearchOnlyNeverQueries =>
      'Somente pesquisa — nunca consulta';

  @override
  String get powertrainRestoreStorageErrorRetry =>
      'Ocorreu um erro de armazenamento ao restaurar instalações anteriores. Foi reagendado — tente de novo.';

  @override
  String powertrainSecondarySource(String name, String license) {
    return 'Corroboração independente: $name ($license)';
  }

  @override
  String powertrainSignalCount(int count) {
    return 'Sinais: $count';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return 'Arquivo de origem SHA-256: $hash…';
  }

  @override
  String get powertrainStatusCommunity => 'Comunidade · não verificado';

  @override
  String get powertrainStatusExperimental => 'Experimental · não verificado';

  @override
  String get powertrainStatusExperimentalProbeOnly =>
      'Experimental · ler uma vez';

  @override
  String get powertrainStatusReady => 'Dados de origem mais completos';

  @override
  String get powertrainStatusResearchOnly => 'Somente pesquisa';

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return 'Removidos os sinais instalados de $name.';
  }

  @override
  String powertrainVehicleYearFixed(int year) {
    return 'Ano-modelo: $year';
  }

  @override
  String get powertrainVehicleYearLabel => 'Ano-modelo';

  @override
  String get recommendedPurchaseDisclosure =>
      'Este é um link de afiliado do mantenedor; uma compra qualificada pode pagar uma comissão ao mantenedor. Não é uma certificação de adaptador nem uma garantia de compra. O conteúdo do anúncio e as revisões do hardware podem mudar, então confira o número completo do modelo e o número NCC antes de comprar. Você também é livre para procurar outros vendedores por conta própria.';

  @override
  String get recommendedPurchaseHeading => 'Adaptador recomendado';

  @override
  String recommendedPurchaseModelLine(String model, String approval) {
    return 'Modelo $model · NCC $approval';
  }

  @override
  String recommendedPurchaseNoAdapterYet(String store) {
    return 'Ainda sem adaptador? Veja o recomendado na $store';
  }

  @override
  String recommendedPurchaseOpenFailed(String store) {
    return 'Não foi possível abrir o link da $store';
  }

  @override
  String get recommendedPurchaseShortDisclosureAction =>
      'Divulgação completa em Configurações';

  @override
  String get recommendedPurchaseShortDisclosureLead =>
      'Este é um link de afiliado, não uma certificação de adaptador.';

  @override
  String get recommendedPurchaseStoreShopee => 'Shopee';

  @override
  String recommendedPurchaseViewOnStore(String store) {
    return 'Ver na $store';
  }

  @override
  String get semanticsFieldSeparator => ', ';

  @override
  String get settingsAdapterConcernsFooter =>
      'Estes são pontos em que o relato do adaptador sobre si mesmo não fecha — não são evidência de que ele leu o carro errado. A única forma de confirmar um valor é uma segunda medição independente (veja o guia de campo).';

  @override
  String get settingsAdapterNoContradictions =>
      'Nenhuma contradição de autodescrição encontrada. Isso só significa que ele é consistente sobre si mesmo — não é evidência de que o chip é genuíno, e não é evidência de que os números que ele reporta estão corretos. Em um clone, a string de versão é só um texto que alguém escolheu.';

  @override
  String get settingsAdapterNoVersion => '(nenhuma versão reportada)';

  @override
  String get settingsAdapterSelfReportTitle =>
      'O que o adaptador diz sobre si mesmo';

  @override
  String get settingsBatteryLabDialogBody =>
      'Estas são fontes candidatas obtidas por engenharia reversa, não documentação do fabricante, e não suporte do Telltale ao seu veículo. Mesmo uma consulta somente leitura pode acordar um controlador; um número decodificado pode parecer plausível e ainda assim não se aplicar.';

  @override
  String get settingsBatteryLabDialogTitle => 'Ativar o laboratório de bateria';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      'O laboratório de bateria está desligado nesta execução, mas a configuração não pôde ser salva; a próxima abertura pode mostrar o laboratório de novo, e cada consulta ainda precisa da própria confirmação.';

  @override
  String get settingsBatteryLabEnableNotSaved =>
      'Não foi possível salvar a configuração do laboratório de bateria; ele permanece desligado.';

  @override
  String get settingsBatteryLabEvidenceAck =>
      'Entendo que os dados de origem e os testes sintéticos não provam que isso se aplica ao meu próprio veículo';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      'Só revela consultas únicas somente leitura cujas fontes estão completas e vinculadas a hash. Não instala PIDs, não varre, não adiciona medidores nem trata dados de pesquisa como suporte.';

  @override
  String get settingsBatteryLabSwitchTitle =>
      'Laboratório de bateria (experimental)';

  @override
  String get settingsBatteryLabUnlockReadOnly =>
      'Desbloquear apenas consultas únicas somente leitura';

  @override
  String get settingsBatteryLabWireAck =>
      'Entendo que isto desbloqueia apenas consultas únicas em endereços Mode 21/22 fixos do catálogo — não varredura, não sessão diagnóstica, não acesso de segurança, não escrita, não controle';

  @override
  String get settingsCancel => 'Cancelar';

  @override
  String get settingsCatalogChoose => 'Escolher no catálogo oficial';

  @override
  String get settingsCatalogCorrupt =>
      'O catálogo oficial offline está danificado ou não pôde ser carregado; nada foi aplicado.';

  @override
  String get settingsCatalogNothingApplicable =>
      'Esta configuração oficial não tem nenhum campo que possa ser aplicado com segurança às fórmulas atuais; o perfil existente permanece inalterado.';

  @override
  String get settingsCatalogScope =>
      'Catálogos oficiais: U.S. EPA, Taiwan MOEA, Canada NRCan. Cada snapshot é só daquele mercado, não de todas as marcas ou anos no mundo.';

  @override
  String get settingsCatalogVerifying => 'Verificando o catálogo offline…';

  @override
  String get settingsCatalogChooseMarket =>
      'Escolher o catálogo oficial para consultar';

  @override
  String get settingsCatalogMarketTw => 'Taiwan (MOEA Energy Administration)';

  @override
  String get settingsCatalogMarketUs => 'Estados Unidos (EPA)';

  @override
  String get settingsTwCertificationYear => 'Ano de certificação';

  @override
  String get settingsTwMake => 'Marca de Taiwan';

  @override
  String settingsTwPickerScope(int firstYear, int lastYear) {
    return 'Somente linhas de certificação do mercado de Taiwan para $firstYear–$lastYear. O ano é o ano-calendário de certificação da Energy Administration, não um ano-modelo dos EUA. Uma coincidência nos nomes de marca/modelo não corresponde a uma configuração EPA.';
  }

  @override
  String get settingsTwPickerTitle => 'Catálogo oficial de veículos de Taiwan';

  @override
  String get settingsTwReferenceMassNotCurb =>
      'A massa de referência do veículo não é curb mass e não é aplicada.';

  @override
  String settingsTwWillApplyOnly(String fields) {
    return 'Só $fields serão aplicados. Massa de referência, VE, Cd, área frontal, Crr e eficiência de transmissão permanecem sem resolução.';
  }

  @override
  String get settingsClose => 'Fechar';

  @override
  String get settingsConnectionSection => 'Conexão';

  @override
  String get settingsDiagnosticsSection => 'Transcrição diagnóstica';

  @override
  String get settingsDisconnect => 'Desconectar';

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return 'Eficiência da transmissão $percent %';
  }

  @override
  String settingsEpaApplyFields(int count) {
    return 'Aplicar $count campos oficiais';
  }

  @override
  String get settingsEpaChooseExact => 'Escolher uma configuração exata';

  @override
  String get settingsEpaCloseNoFields => 'Fechar (nenhum campo a aplicar)';

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'Configuração EPA $epaId';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count cil';
  }

  @override
  String get settingsEpaDriveUnknown => 'Tração desconhecida';

  @override
  String get settingsEpaFuelUnknown => 'Combustível desconhecido';

  @override
  String get settingsEpaMake => 'Marca EPA';

  @override
  String get settingsEpaModel => 'Modelo';

  @override
  String get settingsEpaNoConfigurations =>
      'Nenhuma configuração disponível para este modelo';

  @override
  String get settingsEpaNoSafeFields =>
      'Esta configuração não tem nenhum campo que possa ser aplicado com segurança às fórmulas atuais; nada é adivinhado.';

  @override
  String get settingsEpaPickInOrder =>
      'Escolha ano-modelo, marca e modelo nesta ordem';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return 'Somente configurações de snapshot do mercado dos EUA para $firstYear–$lastYear. Modelos que compartilham um nome ainda precisam do ano-modelo, transmissão, combustível e EPA ID para distingui-los.';
  }

  @override
  String get settingsEpaPickerTitle => 'Catálogo oficial de veículos U.S. EPA';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return 'Só $fields serão aplicados. Massa, VE, Cd, área frontal, Crr e eficiência de transmissão permanecem sem resolução.';
  }

  @override
  String get settingsEpaYear => 'Ano-modelo';

  @override
  String get settingsExperimentalSection => 'Experimental';

  @override
  String get settingsFieldDisplacement => 'Cilindrada';

  @override
  String get settingsFieldDragCoefficient => 'Coeficiente de arrasto Cd';

  @override
  String get settingsFieldDrivetrain => 'Tração';

  @override
  String get settingsFieldFrontalArea => 'Área frontal';

  @override
  String get settingsFieldFuel => 'Combustível';

  @override
  String get settingsFieldMass => 'Massa';

  @override
  String get settingsFieldMassWithDriver => 'Massa (com motorista)';

  @override
  String get settingsFieldRollingResistance => 'Resistência ao rolamento Crr';

  @override
  String get settingsFieldVolumetricEfficiency => 'Eficiência volumétrica VE';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return 'Relação ar-combustível $afr · densidade $density g/L';
  }

  @override
  String get settingsFuelAndDrivetrainSection => 'Combustível e tração';

  @override
  String get settingsFuelTypeLabel => 'Tipo de combustível';

  @override
  String get settingsGaugeSkinBody =>
      'Não é só uma mudança de cor — cada um tem face do medidor, ponteiro e movimento diferentes. Todos funcionam em fundos escuros e claros.';

  @override
  String get settingsGaugeSkinTitle => 'Estilo do medidor';

  @override
  String get settingsGoToConnect => 'Ir para Conectar';

  @override
  String get settingsHeadline => 'Configurações';

  @override
  String get settingsLicenseLegalese =>
      'Fontes de bateria do trem de força, transformações e termos de reuso vêm empacotados com este app.';

  @override
  String get settingsListSeparator => ', ';

  @override
  String get settingsManualCommandBody =>
      'Envie um comando direto ao adaptador — por exemplo ATI, ATDPN, 0100. Ele entra na mesma fila da varredura normal e não fura a fila.';

  @override
  String get settingsManualCommandFieldLabel => 'Comando';

  @override
  String get settingsManualCommandNoContent => '(sem conteúdo de resposta)';

  @override
  String get settingsManualCommandSend => 'Enviar';

  @override
  String get settingsManualCommandTitle => 'Comando manual';

  @override
  String get settingsNotConnected => 'Não conectado';

  @override
  String get settingsOpenSourceLicenses =>
      'Licenças de código aberto e de dados';

  @override
  String get settingsProfileConfirmAfterConnect =>
      'Conecte para confirmar este veículo';

  @override
  String get settingsProfileConfirmButton =>
      'Confirmar este veículo nesta conexão';

  @override
  String get settingsProfileConfirmedButton => 'Confirmado nesta conexão';

  @override
  String get settingsProfileConfirmedDetail =>
      'O perfil está confirmado para esta conexão. Alterar qualquer valor, ou reconectar, exige confirmar de novo.';

  @override
  String get settingsProfileEstimatesIntro =>
      'Potência, torque e consumo de combustível são estimados a partir destes parâmetros; quanto mais próximos do veículo real, mais as estimativas significam.';

  @override
  String get settingsProfileNameProvesNothing =>
      'Um nome de marca ou um VIN sozinho não estabelece massa, arrasto, VE ou eficiência de transmissão.';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      'Não confirmado nesta conexão. Leituras OBD medidas ainda são exibidas, mas valores estimados a partir de massa, VE e arrasto não.';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      'Conecte a este veículo antes de confirmar. A confirmação expira a cada reconexão, para que o perfil de um carro nunca seja aplicado ao próximo.';

  @override
  String get settingsProvenanceNoneExact =>
      'Nenhum campo foi resolvido exatamente para este veículo; valores genéricos, digitados à mão e de fontes mais antigas ainda precisam de confirmação.';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return 'Campos com fonte oficial exata: $fields. Todos os outros campos ainda precisam ser confirmados um a um.';
  }

  @override
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  ) {
    return 'Proveniência: oficial ou fabricante $official / $total campos · informado pelo usuário $user / $total · padrão genérico $generic / $total · modelo científico $scientific / $total';
  }

  @override
  String settingsProvenancePublishers(String publishers) {
    return 'Fontes: $publishers';
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
    return 'Resolução: oficial exata $exact / $total campos · confirmado nesta sessão $sessionConfirmed / $total · não resolvido $unresolved / $total · ambíguo $ambiguous / $total · conflitante $conflict / $total';
  }

  @override
  String get settingsStandardsFooter =>
      'A implementação OBD2 deste app segue padrões públicos, incluindo SAE J1979 e a folha de dados do ELM327; todas as fórmulas e todos os comandos AT que afetam o comportamento do hardware são verificados de forma cruzada, e os resultados são registrados em docs/protocol-deviations.zh-TW.md. Este app não é afiliado ao Torque ou Torque Pro.';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeSystem => 'Seguir o sistema';

  @override
  String get settingsVehicleProfileSection => 'Perfil do veículo';

  @override
  String get settingsVinConflict => 'Conflito de VIN';

  @override
  String get settingsVinConflictDetail =>
      'Os controladores reportaram VINs diferentes, por isso a identidade do veículo não pode ser confirmada; todos os candidatos foram descartados.';

  @override
  String get settingsVinNotRead => 'VIN ainda não lido';

  @override
  String get settingsVinNotReadConnectedDetail =>
      'O VIN Mode 09 pode ser lido do veículo agora; a identidade é mantida só nesta conexão. A transcrição diagnóstica bruta ainda pode conter o VIN.';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      'Depois de conectar, o VIN que o veículo reporta sobre si mesmo pode ser lido; a identidade não passa para a próxima conexão. A transcrição diagnóstica bruta ainda pode conter o VIN.';

  @override
  String get settingsVinRead => 'Ler VIN';

  @override
  String get settingsVinReading => 'Lendo…';

  @override
  String get settingsVinReportedDetail =>
      'Um VIN é o que o veículo reporta sobre si mesmo; ele não verifica as especificações do modelo. A identidade não atravessa conexões; a transcrição diagnóstica ainda pode conter o VIN.';

  @override
  String get settingsVinSimulatorReported => 'VIN reportado pelo simulador';

  @override
  String get settingsVinUnavailable => 'VIN indisponível';

  @override
  String get settingsVinUnavailableDetail =>
      'O veículo pode não oferecer um, a resposta pode ter ficado incompleta, ou não foi lido nesta conexão; nada é adivinhado e nenhum caractere é preenchido.';

  @override
  String get settingsVinVehicleReported => 'VIN reportado pelo veículo';

  @override
  String get startupCannotComplete =>
      'Não é possível concluir as verificações de inicialização';

  @override
  String get startupChecking =>
      'Verificando cache local de compartilhamento e registros de telemetria';

  @override
  String get startupRestartHint =>
      'Não foi possível confirmar o cache local de compartilhamento ou os registros de telemetria. Feche o Telltale por completo e abra de novo para que o arquivo errado não seja sobrescrito, excluído ou compartilhado.';

  @override
  String get startupRestartRequired =>
      'Reinício necessário para continuar com segurança';

  @override
  String get startupRetry => 'Tentar de novo';

  @override
  String get startupRetryHint =>
      'Mantenha o Telltale em primeiro plano e tente de novo depois que outros trabalhos com arquivos terminarem. Gravação, reprodução, exportação e exclusão permanecem fechadas até a inicialização concluir.';

  @override
  String get telemetryArtifactRestartRequired =>
      'O estado do trabalho local com arquivos não pode ser confirmado. Feche o Telltale por completo e abra de novo antes de continuar';

  @override
  String get telemetryBlockedByRecorder => 'Pare e salve a gravação primeiro';

  @override
  String get telemetryCancel => 'Cancelar';

  @override
  String get telemetryDamagedCollision =>
      'Um arquivo concluído e um inacabado compartilham este id — nenhum dos dois foi escolhido';

  @override
  String get telemetryDamagedCorrupt =>
      'A gravação está danificada e não pode ser lida com segurança';

  @override
  String telemetryDamagedFileTime(String time) {
    return 'Hora do arquivo $time';
  }

  @override
  String get telemetryDelete => 'Excluir';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return 'Isto exclui $id (hora do arquivo $time). Não pode ser desfeito.';
  }

  @override
  String get telemetryDeleteDamagedTitle => 'Excluir esta gravação danificada?';

  @override
  String get telemetryDeleteDamagedTooltip => 'Excluir gravação danificada';

  @override
  String telemetryDeleteFailed(String reason) {
    return 'A exclusão não terminou: $reason';
  }

  @override
  String get telemetryDeleteNeedsConfirmation =>
      'Confirme esta exclusão primeiro';

  @override
  String telemetryDeleteSessionBody(String time) {
    return 'Isto exclui a gravação de $time. Não pode ser desfeito.';
  }

  @override
  String get telemetryDeleteSessionTitle => 'Excluir esta gravação local?';

  @override
  String get telemetryDemoData => 'Dados do simulador embutido';

  @override
  String get telemetryDismissNotice => 'Dispensar';

  @override
  String get telemetryEndedByBackground =>
      'Parou quando o Telltale foi para segundo plano';

  @override
  String get telemetryEndedByConfigurationChanged => 'A seleção de PIDs mudou';

  @override
  String get telemetryEndedByDisconnect => 'Parou quando a conexão caiu';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return 'Atingiu o limite de $minutes minutos';
  }

  @override
  String get telemetryEndedByLibrarySizeLimit =>
      'O armazenamento local de gravações está cheio';

  @override
  String get telemetryEndedByRecoveredAfterInterruption =>
      'Recuperado após a última interrupção';

  @override
  String get telemetryEndedBySessionReplacement =>
      'A sessão de conexão foi substituída';

  @override
  String get telemetryEndedBySessionSizeLimit =>
      'Esta gravação atingiu o limite de tamanho';

  @override
  String get telemetryEndedByStorageBackpressure =>
      'O armazenamento não conseguiu acompanhar';

  @override
  String get telemetryEndedByStorageFailure => 'Falha ao salvar';

  @override
  String get telemetryEndedByUser => 'Parado por você';

  @override
  String get telemetryExport => 'Exportar';

  @override
  String get telemetryExportCsv => 'Exportar CSV';

  @override
  String telemetryExportFailed(String reason) {
    return 'A exportação não terminou: $reason';
  }

  @override
  String get telemetryExportJson => 'Exportar JSON';

  @override
  String get telemetryExportSheetTitle => 'Exportar uma gravação local';

  @override
  String telemetryGapCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lacunas',
      one: '1 lacuna',
    );
    return '$_temp0';
  }

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grupos salvos — reproduzir e exportar offline',
      one: '1 grupo salvo — reproduzir e exportar offline',
    );
    return '$_temp0';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit grupos';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grupos a mais não mostrados',
      one: '1 grupo a mais não mostrado',
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
    return 'Armazenamento local: $groups de $groupLimit grupos, $used de $byteLimit MiB';
  }

  @override
  String get telemetryNotConnected => 'Não conectado';

  @override
  String get telemetryOfflineSampledReplay => 'Reprodução amostrada offline';

  @override
  String get telemetryOpenHistory => 'Abrir gravações locais';

  @override
  String get telemetryPause => 'Pausar';

  @override
  String get telemetryPendingOwnerRecovery =>
      'Este processo ainda mantém a operação. Se ficar assim, feche o Telltale por completo e abra de novo';

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetryPlay => 'Reproduzir';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return 'Grava apenas os sinais OBD que você ativou — sem localização, VIN ou dados de conta. As tendências mostram no máximo $laneLimit sinais; uma gravação guarda todos os $activeCount sinais ativos e adiciona potência estimada e vazão de combustível estimada, que se apoiam nas premissas do veículo.';
  }

  @override
  String get telemetryRecorderPhaseAwaitingValues =>
      'Gravando — ainda sem valores';

  @override
  String get telemetryRecorderPhaseCompleted => 'Gravação salva';

  @override
  String get telemetryRecorderPhaseFailed => 'Falha ao salvar a gravação';

  @override
  String get telemetryRecorderPhaseFinalizing => 'Salvando a gravação';

  @override
  String get telemetryRecorderPhaseIdle => 'Gravação local em primeiro plano';

  @override
  String get telemetryRecorderPhasePreparing => 'Preparando para gravar';

  @override
  String get telemetryRecorderPhaseRecording => 'Gravando';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return 'Gravando $duration';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arquivos inacabados sem valores válidos foram limpos',
      one: '1 arquivo inacabado sem valores válidos foi limpo',
    );
    return '$_temp0';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count arquivos danificados ou conflitantes foram deixados inalterados',
      one: '1 arquivo danificado ou conflitante foi deixado inalterado',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryDamagedNote =>
      'Conteúdo danificado nunca é usado para reprodução ou exportação, e só pode ser excluído manualmente quando for seguro fazê-lo.';

  @override
  String telemetryRecoveryInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gravações interrompidas foram seladas com segurança',
      one: '1 gravação interrompida foi selada com segurança',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryTitle =>
      'Verificação de inicialização das gravações concluída';

  @override
  String get telemetryReload => 'Recarregar';

  @override
  String telemetryReplayBreakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count interrupções',
      one: '1 interrupção',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayLoadFailed =>
      'Não foi possível carregar a gravação';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return 'Posição da reprodução $percent%';
  }

  @override
  String telemetryReplaySampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pontos amostrados',
      one: '1 ponto amostrado',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayTitle => 'Reprodução da gravação';

  @override
  String get telemetryReplayUnreadable =>
      'A gravação está danificada ou não pode ser lida';

  @override
  String get telemetryRestartToRepairSave =>
      'O salvamento não terminou — reinicie o Telltale para reparar as gravações';

  @override
  String get telemetryRestartToRepairStartup =>
      'A limpeza de inicialização não terminou — reinicie o Telltale para reparar as gravações';

  @override
  String get telemetryReturnToTrends => 'Voltar às tendências';

  @override
  String get telemetryRigData => 'Dados da bancada de teste';

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetrySessionsDamaged => 'Arquivos de gravação danificados';

  @override
  String get telemetrySessionsEmpty =>
      'Ainda sem gravações locais\nConecte e depois comece a gravar';

  @override
  String get telemetrySessionsLoadFailed =>
      'Não foi possível carregar — tentar de novo';

  @override
  String get telemetrySessionsReplayable =>
      'Gravações que você pode reproduzir';

  @override
  String get telemetrySessionsTitle => 'Gravações locais';

  @override
  String telemetrySignalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sinais',
      one: '1 sinal',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStartBusy =>
      'Outra gravação ou operação de arquivo ainda não terminou';

  @override
  String get telemetryStartCannotCreateFile =>
      'Não foi possível criar o arquivo de gravação';

  @override
  String get telemetryStartInvalidConfiguration =>
      'Esta seleção de PID não pode ser gravada com segurança — verifique as definições';

  @override
  String get telemetryStartInvalidatedBackground =>
      'O Telltale foi para segundo plano — nenhuma gravação começou';

  @override
  String get telemetryStartInvalidatedDisconnect =>
      'A conexão caiu — nenhuma gravação começou';

  @override
  String get telemetryStartInvalidatedSessionReplacement =>
      'A sessão de conexão foi substituída — nenhuma gravação começou';

  @override
  String get telemetryStartLibraryByteLimit =>
      'Armazenamento local insuficiente para uma gravação — exporte ou exclua algumas primeiro';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return 'As gravações locais atingiram o limite de $limit — exporte ou exclua algumas primeiro';
  }

  @override
  String get telemetryStartMoving => 'Estacione o veículo primeiro';

  @override
  String get telemetryStartNeedsActivePid => 'Ative pelo menos um PID primeiro';

  @override
  String get telemetryStartNeedsConnection =>
      'Conecte antes de iniciar uma gravação';

  @override
  String get telemetryStartNeedsForeground =>
      'Traga o Telltale para o primeiro plano antes de iniciar uma gravação';

  @override
  String get telemetryStartRecording => 'Gravação iniciada';

  @override
  String get telemetryStartRecordingButton => 'Iniciar gravação';

  @override
  String get telemetryStartSpeedUnknown =>
      'Não é possível confirmar que o veículo está parado — desconecte primeiro';

  @override
  String get telemetryStartTooManyPids =>
      'A gravação mantém as colunas de potência estimada e combustível estimado — desative alguns PIDs primeiro';

  @override
  String get telemetryStarting => 'Iniciando';

  @override
  String get telemetryStatusBusError => 'Erro de barramento';

  @override
  String telemetryStatusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count status',
      one: '1 status',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStatusFormulaError => 'Erro de fórmula';

  @override
  String get telemetryStatusHeaderMismatch =>
      'Cabeçalho não corresponde a este barramento';

  @override
  String get telemetryStatusNoAnswer => 'Sem resposta — tentará de novo';

  @override
  String get telemetryStatusStale => 'Dados desatualizados';

  @override
  String get telemetryStatusUnsafeServiceRefusal =>
      'Não é uma consulta somente leitura — nada foi enviado';

  @override
  String get telemetryStatusUnsupported =>
      'O controlador respondeu que não oferece suporte a isto';

  @override
  String get telemetryStopAndSave => 'Parar e salvar';

  @override
  String telemetryValueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count valores válidos',
      one: '1 valor válido',
    );
    return '$_temp0';
  }

  @override
  String get transcriptDelete => 'Excluir';

  @override
  String get transcriptDeleteBusy =>
      'Outra operação de arquivo ainda não terminou.';

  @override
  String get transcriptDeleteFailed =>
      'Não foi possível excluir a transcrição da conexão anterior.';

  @override
  String get transcriptDeleteRefusedBySafety =>
      'A velocidade ou o estado da conexão atuais não permitem excluir a transcrição.';

  @override
  String get transcriptExport => 'Exportar';

  @override
  String get transcriptExportButton => 'Exportar transcrição';

  @override
  String get transcriptExportExplanation =>
      'Esta conexão guarda o handshake inicial e o tráfego bruto mais recente; se uma conexão longa omitir o meio, o arquivo informa isso. Quando algo não puder ser lido no carro, exportar a transcrição e trazê-la de volta vale muito mais do que uma mensagem na tela.';

  @override
  String transcriptExportFailed(String error) {
    return 'Falha na exportação: $error';
  }

  @override
  String get transcriptExportWithHex => 'Com hex';

  @override
  String get transcriptNothingToExport => 'Não há transcrição para exportar.';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return 'Deixada em $timestamp, $size. Sobreviveu ao sistema encerrar o Telltale ou ao celular perder energia.';
  }

  @override
  String get transcriptRecoveredChanged =>
      'A transcrição da conexão anterior mudou — verifique de novo.';

  @override
  String get transcriptRecoveredTitle => 'Transcrição da conexão anterior';

  @override
  String transcriptSizeBytes(int bytes) {
    String _temp0 = intl.Intl.pluralLogic(
      bytes,
      locale: localeName,
      other: '$bytes bytes',
      one: '1 byte',
    );
    return '$_temp0';
  }

  @override
  String get trendAxisNow => 'Agora';

  @override
  String get trendChooseSignals => 'Escolher sinais';

  @override
  String get trendLiveData => 'Dados ao vivo';

  @override
  String get trendNoSignalsBody =>
      'Ative primeiro, na página de PID, os sinais que deseja acompanhar.';

  @override
  String get trendNoSignalsTitle => 'Nenhum sinal de tendência disponível';

  @override
  String get trendNoUnits => 'Sem unidades';

  @override
  String trendPickSignalsBody(int limit) {
    return 'Compare até $limit sinais. Isso não altera quais PIDs são varridos.';
  }

  @override
  String get trendPickSignalsTitle => 'Escolher sinais de tendência';

  @override
  String trendRemoveSignal(String name) {
    return 'Remover $name';
  }

  @override
  String get trendSelectionSaveFailed =>
      'Não foi possível salvar a seleção de exibição da tendência';

  @override
  String trendSheetBody(int limit) {
    return 'Escolha no máximo $limit. Isso só muda o gráfico, não a varredura de PID nem uma gravação em andamento.';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return 'Pronto · $selected/$limit';
  }

  @override
  String get trendSignalNoLongerActive =>
      'Um desses sinais não está mais na lista de observação de PID';

  @override
  String get trendSignalsHeading => 'Sinais de tendência';

  @override
  String trendTooManySelected(int limit) {
    return 'Escolha no máximo $limit';
  }

  @override
  String trendWindowSemantics(int seconds) {
    return 'Mostrando os últimos $seconds segundos';
  }

  @override
  String get wearBack => 'Voltar';

  @override
  String get wearBatteryVoltageLabel => 'Bateria';

  @override
  String get wearBleAdapters => 'Adaptadores BLE';

  @override
  String get wearCancel => 'Cancelar';

  @override
  String get wearConfirmVehicle => 'Confirmar veículo';

  @override
  String get wearConfirmVehicleAccept => 'Sim, este carro';

  @override
  String get wearConfirmVehicleBody =>
      'Depois de confirmado, as consultas somente leitura da bateria deste modelo são varridas pelo restante desta conexão. O modelo errado pode devolver um número que parece plausível, mas está errado — cancele se não tiver certeza.';

  @override
  String wearConnectFailed(String adapter) {
    return 'Não foi possível conectar: $adapter';
  }

  @override
  String get wearConnecting => 'Conectando…';

  @override
  String get wearDemoSimulator => 'Simulador Demo';

  @override
  String get wearDisconnect => 'Desconectar';

  @override
  String get wearDisconnectQuestion => 'Desconectar?';

  @override
  String get wearNoDevicesFound => 'Nenhum dispositivo encontrado';

  @override
  String get wearPermissionBluetooth => 'Bluetooth';

  @override
  String get wearPermissionLocation => 'Localização';

  @override
  String get wearScanAgain => 'Rescanear';

  @override
  String get wearScanFailed => 'Falha no escaneamento — tente de novo';

  @override
  String wearScanPermissionNeeded(String permission) {
    return 'O escaneamento precisa da permissão de $permission';
  }

  @override
  String wearScanPermissionPermanentlyDenied(String permission) {
    return 'A permissão de $permission foi negada permanentemente — ative-a nas configurações do sistema e tente de novo';
  }

  @override
  String get wearScanning => 'Escaneando…';

  @override
  String get telemetryRecorderNotRecording => 'Não gravando';

  @override
  String get dtcKindStored => 'Armazenado';

  @override
  String get dtcKindPending => 'Pendente';

  @override
  String get dtcKindPermanent => 'Permanente';

  @override
  String get dtcKindStoredExplanation =>
      'Uma falha confirmada; a luz de falha do painel costuma estar acesa.';

  @override
  String get dtcKindPendingExplanation =>
      'Detectada uma vez e ainda não atingiu o limiar de confirmação.';

  @override
  String get dtcKindPermanentExplanation =>
      'Não pode ser limpo com um scanner. A ECU o limpa sozinha, e só depois de ter confirmado o reparo.';

  @override
  String get dtcSystemPowertrain => 'Trem de força';

  @override
  String get dtcSystemChassis => 'Chassi';

  @override
  String get dtcSystemBody => 'Carroceria';

  @override
  String get dtcSystemNetwork => 'Rede';

  @override
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions =>
      'Dosagem de combustível e ar, e controles auxiliares de emissões';

  @override
  String get dtcSubsystemFuelAirMetering => 'Dosagem de combustível e ar';

  @override
  String get dtcSubsystemFuelAirMeteringInjectorCircuit =>
      'Dosagem de combustível e ar (circuito do injetor)';

  @override
  String get dtcSubsystemIgnitionOrMisfire =>
      'Sistema de ignição ou falha de ignição';

  @override
  String get dtcSubsystemAuxiliaryEmissionControls =>
      'Controles auxiliares de emissões';

  @override
  String get dtcSubsystemSpeedAndIdleControl =>
      'Controle de velocidade do veículo e sistema de marcha lenta';

  @override
  String get dtcSubsystemComputerOutputCircuit =>
      'Circuito de saída do computador';

  @override
  String get dtcSubsystemTransmission => 'Transmissão';

  @override
  String get dtcSubsystemControlModuleSignals =>
      'Módulos de controle, sinais de entrada e saída';

  @override
  String get dtcDescriptionB0001 =>
      'Falha no controle de acionamento do airbag do motorista';

  @override
  String get dtcDescriptionP0011 =>
      'Posição do comando A — avanço excessivo ou desempenho do sistema (Banco 1)';

  @override
  String get dtcDescriptionP0014 =>
      'Posição do comando B — avanço excessivo ou desempenho do sistema (Banco 1)';

  @override
  String get dtcDescriptionP0016 =>
      'Correlação entre posição do virabrequim e posição do comando (Banco 1 Sensor A)';

  @override
  String get dtcDescriptionP0087 =>
      'Pressão da galeria/sistema de combustível muito baixa';

  @override
  String get dtcDescriptionP0088 =>
      'Pressão da galeria/sistema de combustível muito alta';

  @override
  String get dtcDescriptionP0100 =>
      'Mau funcionamento do circuito do sensor de massa de ar (MAF)';

  @override
  String get dtcDescriptionP0101 =>
      'Problema de faixa/desempenho do sensor de massa de ar';

  @override
  String get dtcDescriptionP0102 =>
      'Entrada baixa no circuito do sensor de massa de ar';

  @override
  String get dtcDescriptionP0103 =>
      'Entrada alta no circuito do sensor de massa de ar';

  @override
  String get dtcDescriptionP0105 =>
      'Mau funcionamento do circuito do sensor de pressão absoluta do coletor/pressão barométrica';

  @override
  String get dtcDescriptionP0106 =>
      'Problema de faixa/desempenho do sensor de pressão absoluta do coletor';

  @override
  String get dtcDescriptionP0107 =>
      'Entrada baixa no circuito do sensor de pressão absoluta do coletor';

  @override
  String get dtcDescriptionP0108 =>
      'Entrada alta no circuito do sensor de pressão absoluta do coletor';

  @override
  String get dtcDescriptionP0110 =>
      'Mau funcionamento do circuito do sensor de temperatura do ar de admissão';

  @override
  String get dtcDescriptionP0111 =>
      'Problema de faixa/desempenho do sensor de temperatura do ar de admissão';

  @override
  String get dtcDescriptionP0112 =>
      'Entrada baixa no circuito do sensor de temperatura do ar de admissão';

  @override
  String get dtcDescriptionP0113 =>
      'Entrada alta no circuito do sensor de temperatura do ar de admissão';

  @override
  String get dtcDescriptionP0115 =>
      'Mau funcionamento do circuito do sensor de temperatura do líquido de arrefecimento';

  @override
  String get dtcDescriptionP0116 =>
      'Problema de faixa/desempenho do sensor de temperatura do líquido de arrefecimento';

  @override
  String get dtcDescriptionP0117 =>
      'Entrada baixa no circuito do sensor de temperatura do líquido de arrefecimento';

  @override
  String get dtcDescriptionP0118 =>
      'Entrada alta no circuito do sensor de temperatura do líquido de arrefecimento';

  @override
  String get dtcDescriptionP0120 =>
      'Mau funcionamento do circuito do sensor de posição da borboleta';

  @override
  String get dtcDescriptionP0121 =>
      'Problema de faixa/desempenho do sensor de posição da borboleta';

  @override
  String get dtcDescriptionP0122 =>
      'Entrada baixa no circuito do sensor de posição da borboleta';

  @override
  String get dtcDescriptionP0123 =>
      'Entrada alta no circuito do sensor de posição da borboleta';

  @override
  String get dtcDescriptionP0125 =>
      'Temperatura do líquido de arrefecimento insuficiente para controle de combustível em malha fechada';

  @override
  String get dtcDescriptionP0128 =>
      'Temperatura do líquido de arrefecimento abaixo da temperatura de regulagem do termostato';

  @override
  String get dtcDescriptionP0130 =>
      'Mau funcionamento do circuito do sensor de oxigênio (Banco 1 Sensor 1)';

  @override
  String get dtcDescriptionP0131 =>
      'Tensão baixa no circuito do sensor de oxigênio (Banco 1 Sensor 1)';

  @override
  String get dtcDescriptionP0132 =>
      'Tensão alta no circuito do sensor de oxigênio (Banco 1 Sensor 1)';

  @override
  String get dtcDescriptionP0133 =>
      'Resposta lenta do circuito do sensor de oxigênio (Banco 1 Sensor 1)';

  @override
  String get dtcDescriptionP0134 =>
      'Nenhuma atividade detectada no circuito do sensor de oxigênio (Banco 1 Sensor 1)';

  @override
  String get dtcDescriptionP0135 =>
      'Mau funcionamento do circuito do aquecedor do sensor de oxigênio (Banco 1 Sensor 1)';

  @override
  String get dtcDescriptionP0136 =>
      'Mau funcionamento do circuito do sensor de oxigênio (Banco 1 Sensor 2)';

  @override
  String get dtcDescriptionP0137 =>
      'Tensão baixa no circuito do sensor de oxigênio (Banco 1 Sensor 2)';

  @override
  String get dtcDescriptionP0138 =>
      'Tensão alta no circuito do sensor de oxigênio (Banco 1 Sensor 2)';

  @override
  String get dtcDescriptionP0140 =>
      'Nenhuma atividade detectada no circuito do sensor de oxigênio (Banco 1 Sensor 2)';

  @override
  String get dtcDescriptionP0141 =>
      'Mau funcionamento do circuito do aquecedor do sensor de oxigênio (Banco 1 Sensor 2)';

  @override
  String get dtcDescriptionP0150 =>
      'Mau funcionamento do circuito do sensor de oxigênio (Banco 2 Sensor 1)';

  @override
  String get dtcDescriptionP0155 =>
      'Mau funcionamento do circuito do aquecedor do sensor de oxigênio (Banco 2 Sensor 1)';

  @override
  String get dtcDescriptionP0156 =>
      'Mau funcionamento do circuito do sensor de oxigênio (Banco 2 Sensor 2)';

  @override
  String get dtcDescriptionP0161 =>
      'Mau funcionamento do circuito do aquecedor do sensor de oxigênio (Banco 2 Sensor 2)';

  @override
  String get dtcDescriptionP0170 =>
      'Mau funcionamento do ajuste de combustível (Banco 1)';

  @override
  String get dtcDescriptionP0171 => 'Sistema muito pobre (Banco 1)';

  @override
  String get dtcDescriptionP0172 => 'Sistema muito rico (Banco 1)';

  @override
  String get dtcDescriptionP0173 =>
      'Mau funcionamento do ajuste de combustível (Banco 2)';

  @override
  String get dtcDescriptionP0174 => 'Sistema muito pobre (Banco 2)';

  @override
  String get dtcDescriptionP0175 => 'Sistema muito rico (Banco 2)';

  @override
  String get dtcDescriptionP0190 =>
      'Mau funcionamento do circuito do sensor de pressão da galeria de combustível';

  @override
  String get dtcDescriptionP0201 =>
      'Mau funcionamento ou circuito aberto do injetor — cilindro 1';

  @override
  String get dtcDescriptionP0202 =>
      'Mau funcionamento ou circuito aberto do injetor — cilindro 2';

  @override
  String get dtcDescriptionP0203 =>
      'Mau funcionamento ou circuito aberto do injetor — cilindro 3';

  @override
  String get dtcDescriptionP0204 =>
      'Mau funcionamento ou circuito aberto do injetor — cilindro 4';

  @override
  String get dtcDescriptionP0217 => 'Condição de superaquecimento do motor';

  @override
  String get dtcDescriptionP0221 =>
      'Problema de faixa/desempenho do sensor B de posição da borboleta/pedal';

  @override
  String get dtcDescriptionP0222 =>
      'Entrada baixa no circuito do sensor B de posição da borboleta/pedal';

  @override
  String get dtcDescriptionP0223 =>
      'Entrada alta no circuito do sensor B de posição da borboleta/pedal';

  @override
  String get dtcDescriptionP0234 =>
      'Condição de pressão de sobrealimentação excessiva do turbocompressor/compressor';

  @override
  String get dtcDescriptionP0299 =>
      'Condição de pressão de sobrealimentação insuficiente do turbocompressor/compressor A';

  @override
  String get dtcDescriptionP0300 =>
      'Falha de ignição aleatória ou em vários cilindros detectada';

  @override
  String get dtcDescriptionP0301 => 'Falha de ignição no cilindro 1 detectada';

  @override
  String get dtcDescriptionP0302 => 'Falha de ignição no cilindro 2 detectada';

  @override
  String get dtcDescriptionP0303 => 'Falha de ignição no cilindro 3 detectada';

  @override
  String get dtcDescriptionP0304 => 'Falha de ignição no cilindro 4 detectada';

  @override
  String get dtcDescriptionP0305 => 'Falha de ignição no cilindro 5 detectada';

  @override
  String get dtcDescriptionP0306 => 'Falha de ignição no cilindro 6 detectada';

  @override
  String get dtcDescriptionP0307 => 'Falha de ignição no cilindro 7 detectada';

  @override
  String get dtcDescriptionP0308 => 'Falha de ignição no cilindro 8 detectada';

  @override
  String get dtcDescriptionP0316 =>
      'Falha de ignição detectada imediatamente após a partida';

  @override
  String get dtcDescriptionP0325 =>
      'Mau funcionamento do circuito do sensor de detonação (Banco 1)';

  @override
  String get dtcDescriptionP0326 =>
      'Problema de faixa/desempenho do sensor de detonação (Banco 1)';

  @override
  String get dtcDescriptionP0327 =>
      'Entrada baixa no circuito do sensor de detonação (Banco 1)';

  @override
  String get dtcDescriptionP0328 =>
      'Entrada alta no circuito do sensor de detonação (Banco 1)';

  @override
  String get dtcDescriptionP0330 =>
      'Mau funcionamento do circuito do sensor de detonação (Banco 2)';

  @override
  String get dtcDescriptionP0335 =>
      'Mau funcionamento do circuito do sensor de posição do virabrequim';

  @override
  String get dtcDescriptionP0336 =>
      'Problema de faixa/desempenho do sensor de posição do virabrequim';

  @override
  String get dtcDescriptionP0340 =>
      'Mau funcionamento do circuito do sensor de posição do comando';

  @override
  String get dtcDescriptionP0341 =>
      'Problema de faixa/desempenho do sensor de posição do comando';

  @override
  String get dtcDescriptionP0351 =>
      'Mau funcionamento do circuito primário/secundário da bobina de ignição A';

  @override
  String get dtcDescriptionP0352 =>
      'Mau funcionamento do circuito primário/secundário da bobina de ignição B';

  @override
  String get dtcDescriptionP0353 =>
      'Mau funcionamento do circuito primário/secundário da bobina de ignição C';

  @override
  String get dtcDescriptionP0354 =>
      'Mau funcionamento do circuito primário/secundário da bobina de ignição D';

  @override
  String get dtcDescriptionP0355 =>
      'Mau funcionamento do circuito primário/secundário da bobina de ignição E';

  @override
  String get dtcDescriptionP0356 =>
      'Mau funcionamento do circuito primário/secundário da bobina de ignição F';

  @override
  String get dtcDescriptionP0400 =>
      'Mau funcionamento do fluxo de recirculação dos gases de escape (EGR)';

  @override
  String get dtcDescriptionP0401 =>
      'Fluxo de recirculação dos gases de escape (EGR) insuficiente';

  @override
  String get dtcDescriptionP0402 =>
      'Fluxo de recirculação dos gases de escape (EGR) excessivo';

  @override
  String get dtcDescriptionP0403 =>
      'Mau funcionamento do circuito de controle da recirculação dos gases de escape (EGR)';

  @override
  String get dtcDescriptionP0404 =>
      'Problema de faixa/desempenho do circuito de controle da recirculação dos gases de escape (EGR)';

  @override
  String get dtcDescriptionP0410 =>
      'Mau funcionamento do sistema de injeção de ar secundário';

  @override
  String get dtcDescriptionP0411 =>
      'Fluxo incorreto detectado no sistema de injeção de ar secundário';

  @override
  String get dtcDescriptionP0412 =>
      'Mau funcionamento do circuito da válvula de comutação A do sistema de injeção de ar secundário';

  @override
  String get dtcDescriptionP0420 =>
      'Eficiência do sistema catalisador abaixo do limiar (Banco 1)';

  @override
  String get dtcDescriptionP0430 =>
      'Eficiência do sistema catalisador abaixo do limiar (Banco 2)';

  @override
  String get dtcDescriptionP0440 =>
      'Mau funcionamento do sistema de controle de emissões evaporativas';

  @override
  String get dtcDescriptionP0441 =>
      'Fluxo de purga incorreto no sistema de emissões evaporativas';

  @override
  String get dtcDescriptionP0442 =>
      'Vazamento detectado no sistema de emissões evaporativas (vazamento pequeno)';

  @override
  String get dtcDescriptionP0443 =>
      'Mau funcionamento do circuito da válvula de controle de purga do sistema de emissões evaporativas';

  @override
  String get dtcDescriptionP0446 =>
      'Mau funcionamento do circuito de controle de ventilação do sistema de emissões evaporativas';

  @override
  String get dtcDescriptionP0447 =>
      'Circuito de controle de ventilação do sistema de emissões evaporativas aberto';

  @override
  String get dtcDescriptionP0449 =>
      'Mau funcionamento do circuito da válvula/solenoide de ventilação do sistema de emissões evaporativas';

  @override
  String get dtcDescriptionP0451 =>
      'Problema de faixa/desempenho do sensor de pressão do sistema de emissões evaporativas';

  @override
  String get dtcDescriptionP0452 =>
      'Entrada baixa no circuito do sensor de pressão do sistema de emissões evaporativas';

  @override
  String get dtcDescriptionP0453 =>
      'Entrada alta no circuito do sensor de pressão do sistema de emissões evaporativas';

  @override
  String get dtcDescriptionP0455 =>
      'Vazamento detectado no sistema de emissões evaporativas (vazamento grande)';

  @override
  String get dtcDescriptionP0456 =>
      'Vazamento detectado no sistema de emissões evaporativas (vazamento muito pequeno)';

  @override
  String get dtcDescriptionP0480 =>
      'Mau funcionamento do circuito de controle da ventoinha de arrefecimento 1';

  @override
  String get dtcDescriptionP0500 =>
      'Mau funcionamento do sensor de velocidade do veículo';

  @override
  String get dtcDescriptionP0505 =>
      'Mau funcionamento do sistema de controle de marcha lenta';

  @override
  String get dtcDescriptionP0506 =>
      'RPM do sistema de marcha lenta mais baixa do que o esperado';

  @override
  String get dtcDescriptionP0507 =>
      'RPM do sistema de marcha lenta mais alta do que o esperado';

  @override
  String get dtcDescriptionP0508 =>
      'Sinal baixo no circuito do sistema de controle de marcha lenta';

  @override
  String get dtcDescriptionP0509 =>
      'Sinal alto no circuito do sistema de controle de marcha lenta';

  @override
  String get dtcDescriptionP0560 => 'Mau funcionamento da tensão do sistema';

  @override
  String get dtcDescriptionP0562 => 'Tensão do sistema baixa';

  @override
  String get dtcDescriptionP0563 => 'Tensão do sistema alta';

  @override
  String get dtcDescriptionP0603 =>
      'Erro de memória de retenção (KAM) do módulo de controle interno';

  @override
  String get dtcDescriptionP0605 =>
      'Erro de memória somente leitura (ROM) do módulo de controle interno';

  @override
  String get dtcDescriptionP0606 => 'Falha no processador ECM/PCM';

  @override
  String get dtcDescriptionP0700 =>
      'O módulo de controle da transmissão pediu a luz de falha — o código de falha em si está no módulo da transmissão e precisa ser lido separadamente';

  @override
  String get dtcDescriptionP0701 =>
      'Problema de faixa/desempenho do sistema de controle da transmissão';

  @override
  String get dtcDescriptionP0702 =>
      'Falha elétrica do sistema de controle da transmissão';

  @override
  String get dtcDescriptionP0705 =>
      'Mau funcionamento do circuito do sensor de faixa da transmissão';

  @override
  String get dtcDescriptionP0715 =>
      'Mau funcionamento do circuito do sensor de velocidade de entrada/turbina';

  @override
  String get dtcDescriptionP0720 =>
      'Mau funcionamento do circuito do sensor de velocidade de saída';

  @override
  String get dtcDescriptionP0730 => 'Relação de marcha incorreta';

  @override
  String get dtcDescriptionP0740 =>
      'Mau funcionamento do circuito da embreagem do conversor de torque';

  @override
  String get dtcDescriptionP0741 =>
      'Embreagem do conversor de torque travada na posição desacoplada';

  @override
  String get dtcDescriptionP0750 =>
      'Mau funcionamento do solenoide de mudança A';

  @override
  String get dtcDescriptionP0755 =>
      'Mau funcionamento do solenoide de mudança B';

  @override
  String get dtcDescriptionP2135 =>
      'Correlação de tensão dos sensores A/B de posição da borboleta';

  @override
  String get dtcDescriptionU0100 => 'Comunicação perdida com ECM/PCM';

  @override
  String get dtcDescriptionU0101 =>
      'Comunicação perdida com o módulo de controle da transmissão';

  @override
  String get dtcDescriptionU0121 =>
      'Comunicação perdida com o módulo de controle ABS';

  @override
  String get dtcDescriptionU0140 =>
      'Comunicação perdida com o módulo de controle da carroceria';

  @override
  String get dtcDescriptionU0155 =>
      'Comunicação perdida com o módulo de controle do painel de instrumentos';

  @override
  String get gaugeSkinCluster => 'Cluster';

  @override
  String get gaugeSkinClusterDescription =>
      'Parece um cluster de instrumentos de fábrica. Ponteiro, escala de 270 graus, face rebaixada.';

  @override
  String get gaugeSkinMinimal => 'Minimalista';

  @override
  String get gaugeSkinMinimalDescription =>
      'Meio arco, sem ponteiro, sem marcas. O número é o que você lê, não o movimento.';

  @override
  String get gaugeSkinTrack => 'Pista';

  @override
  String get gaugeSkinTrackDescription =>
      'Barra segmentada, sem suavização. O valor cai onde cai, sem nada no meio.';

  @override
  String get gaugeSkinClassic => 'Clássico';

  @override
  String get gaugeSkinClassicDescription =>
      'Escala impressa, números ao redor, um ponteiro que assenta lentamente como um relógio mecânico.';

  @override
  String get gaugeSkinNight => 'Noite';

  @override
  String get gaugeSkinNightDescription =>
      'Para dirigir depois do escurecer. Baixo brilho, arco raso, sem animação — o mínimo possível da sua atenção.';

  @override
  String get derivedAirflowSourceMaf => 'Sensor MAF';

  @override
  String get derivedAirflowSourceSpeedDensity => 'Estimativa speed-density';

  @override
  String get derivedAirflowSourceUnavailable => 'Massa de ar indisponível';

  @override
  String get derivedFuelSourceStoichiometric => 'Estimativa estequiométrica';

  @override
  String get derivedFuelSourceUnavailable =>
      'Vazão de combustível indisponível';

  @override
  String get telemetrySourceDemo => 'Simulador embutido';

  @override
  String get telemetrySourceRig => 'Bancada de teste';

  @override
  String get telemetrySourceFieldApp => 'Conexão do app de campo';

  @override
  String get fuelTypeGasoline => 'Gasolina';

  @override
  String get fuelTypeDiesel => 'Diesel';

  @override
  String get fuelTypeLpg => 'GLP';

  @override
  String get fuelTypeEthanolE85 => 'Etanol E85';

  @override
  String get drivetrainFwd => 'Tração dianteira';

  @override
  String get drivetrainRwd => 'Tração traseira';

  @override
  String get drivetrainAwd => 'Tração integral';

  @override
  String get assumptionFieldMass => 'Massa';

  @override
  String get assumptionFieldDragCoefficient => 'Cd';

  @override
  String get assumptionFieldFrontalArea => 'Área frontal';

  @override
  String get assumptionFieldRollingResistance => 'Resistência ao rolamento';

  @override
  String get assumptionFieldDrivetrainEfficiency =>
      'Eficiência do trem de força';

  @override
  String get assumptionFieldFuelType => 'Combustível';

  @override
  String get assumptionFieldStoichAfr => 'AFR';

  @override
  String get assumptionFieldFuelDensity => 'Densidade';

  @override
  String get assumptionFieldDisplacement => 'Cilindrada';

  @override
  String get assumptionFieldVolumetricEfficiency => 'VE';

  @override
  String get vehicleFieldOriginGenericDefault => 'padrão genérico';

  @override
  String get vehicleFieldOriginUserEntered => 'informado por você';

  @override
  String get vehicleFieldOriginOfficialRegistry => 'registro oficial';

  @override
  String get vehicleFieldOriginManufacturerPublication => 'dados do fabricante';

  @override
  String get vehicleFieldOriginScientificModel => 'coeficiente de modelo';

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
      'L/h = (MAF g/s) / (AFR × densidade do combustível g/L) × 3600; MAF é PID 0110 ou speed-density (RPM × MAP × cilindrada × VE / T_K); L/100km = (L/h) / speed_kmh × 100';

  @override
  String get datumAssumptionsFromRecording =>
      'A estimativa usa as configurações do veículo como estavam quando isto foi gravado.';

  @override
  String adapterConcernFirmwareNeverReleasedSummary(String version) {
    return 'Informa firmware v$version, que nunca foi lançado';
  }

  @override
  String get adapterConcernFirmwareNeverReleasedDetail =>
      'A Elm Electronics nunca publicou esta versão, então o firmware neste adaptador não é o que ele afirma. Muitos desses ainda funcionam — mas a descrição que ele faz de si mesmo não é confiável, e vale a pena suspeitar dele primeiro quando algo não for lido.';

  @override
  String adapterConcernPpsRefusedSummary(String version) {
    return 'Afirma v$version, mas não conhece ATPPS, que o v1.1 já tinha';
  }

  @override
  String get adapterConcernPpsRefusedDetail =>
      'O resumo de parâmetros programáveis (ATPPS) existe desde o ELM327 v1.1, e até adaptadores de ponta como OBDLink o suportam. A versão que ele afirma e os comandos que realmente implementa não batem.';

  @override
  String get adapterConcernNoIdentitySummary =>
      'Não responde a AT@1, o comando de identidade do dispositivo desde a primeira versão';

  @override
  String get adapterConcernNoIdentityDetail =>
      'Este comando existe desde o ELM327 v1.0. Não respondê-lo significa que este chip implementa um conjunto de comandos menor do que qualquer firmware oficial.';

  @override
  String get telemetryReplaySampled =>
      'A prévia é amostrada; a exportação guarda todos os eventos registrados.';

  @override
  String get telemetryExportDisclosure =>
      'A exportação contém nomes de sinal, valores, horários de observação e de origem, tipo de transporte, protocolo, rótulos/unidades/fórmulas de PID congelados e as premissas da estimativa (massa, arrasto, cilindrada, combustível e parâmetros semelhantes). O JSON também pode conter seus próprios rótulos, unidades, fórmulas e definições congeladas completas. A exportação não contém o VIN, GPS, uma conta, o endereço do adaptador, o perfil completo do veículo nem o tráfego diagnóstico bruto.';

  @override
  String get connectTransportCancelled =>
      'A tentativa de conexão foi interrompida antes de terminar.';

  @override
  String get connectTransportWifiRouteNoNetwork =>
      'O telefone não está em nenhuma rede Wi-Fi, então não há rota até o adaptador. Conecte-se ao hotspot Wi-Fi do adaptador e tente de novo.';

  @override
  String get connectTransportWifiRouteAmbiguous =>
      'O telefone está em mais de uma rede Wi-Fi e nenhuma é claramente a do adaptador, então nenhuma foi escolhida. Desconecte as que não são do adaptador e tente de novo.';

  @override
  String get connectTransportWifiRouteRefused =>
      'O sistema recusou enviar esta conexão pelo Wi-Fi. O telefone está no Wi-Fi; não foi permitido usá-lo para isto.';

  @override
  String get connectTransportWifiRouteTimeout =>
      'O sistema não respondeu ao pedido para enviar esta conexão pelo Wi-Fi. Espere alguns segundos e tente de novo.';

  @override
  String get connectTransportWifiRouteUnclassified =>
      'A conexão não pôde ser enviada pelo Wi-Fi, por um motivo que o sistema não nomeou. O erro completo está no log abaixo.';

  @override
  String get connectTransportWifiHostUnreachable =>
      'Nada respondeu nesse endereço. Confira se o telefone está no hotspot Wi-Fi do adaptador — se o sistema perguntou se deve permanecer conectado sem internet, escolha permanecer. Desligar os dados móveis também pode ajudar.';

  @override
  String get connectTransportWifiConnectTimeout =>
      'Nada respondeu nesse endereço a tempo.';

  @override
  String get connectTransportWifiRouteRestoreFailed =>
      'A conexão funcionou, mas o roteamento de rede do telefone não pôde ser restaurado, então a conexão foi encerrada em vez de ser deixada alterada. Reinicie o app e tente de novo.';

  @override
  String get connectTransportBleLinkFailed =>
      'Não foi possível conectar ao adaptador. Confira se ele tem energia e está ao alcance.';

  @override
  String get connectTransportBleNoSerialCharacteristic =>
      'O dispositivo conectou, mas nenhuma porta serial foi encontrada nele, então pode não ser um adaptador ELM327.';

  @override
  String get connectTransportClassicAllTiersRefused =>
      'Não foi possível conectar ao adaptador. Emparelhe-o primeiro nas configurações de Bluetooth do sistema e confira se está plugado na tomada OBD com a ignição ligada.';

  @override
  String get connectTransportClassicConnectTimeout =>
      'A conexão com o adaptador esgotou o tempo. Ele ainda pode estar respondendo — espere alguns segundos em vez de tentar de novo imediatamente.';

  @override
  String get connectTransportSerialPortOpenFailed =>
      'Não foi possível abrir a porta serial. Confira se o sistema criou uma para este adaptador (COMx no Windows, /dev/rfcomm* no Linux) e se a ignição está ligada.';

  @override
  String get connectTransportSerialDroppedOnOpen =>
      'A porta serial abriu e fechou de novo imediatamente.';

  @override
  String get settingsManualCommandNotConnected =>
      'Nada está conectado, então o comando não foi enviado.';

  @override
  String get settingsManualCommandLinkDropped =>
      'A conexão com o adaptador caiu enquanto este comando estava em andamento, então nada o respondeu. Não se sabe se o adaptador recebeu o comando.';

  @override
  String get settingsManualCommandDisconnectedByApp =>
      'O app fechou a conexão enquanto este comando estava em andamento, então nada o respondeu. Não há nada de errado com o adaptador ou o veículo.';

  @override
  String get settingsManualCommandAdapterSilentOnResync =>
      'As respostas do adaptador tinham saído de sincronia com os comandos enviados a ele, e ele não respondeu à verificação que as colocaria de novo em sincronia, então a conexão foi encerrada. Conecte de novo antes de tentar outra vez.';

  @override
  String get settingsManualCommandLinkStoppedResponding =>
      'Nada chegou do adaptador por tempo suficiente para a conexão ser encerrada. Ele ainda pode ter energia; o que se sabe é o silêncio.';

  @override
  String get settingsManualCommandWriteFailed =>
      'O comando não pôde ser entregue à conexão do adaptador. Não se sabe quanto dele chegou ao adaptador.';

  @override
  String get settingsManualCommandTimedOut =>
      'Nenhuma resposta chegou antes do limite de tempo. Confirme que o adaptador está conectado e a ignição ligada.';

  @override
  String get settingsManualCommandOperationRetired =>
      'Esta sessão terminou ou foi para segundo plano, então o comando não foi enviado.';

  @override
  String get settingsManualCommandRequestUnaddressable =>
      'Este pedido não pode ser endereçado no barramento que este veículo está usando, então não foi enviado. Tentar de novo não muda isso.';

  @override
  String get commandFailureBusJ1939 =>
      'Este barramento é SAE J1939 (veículos comerciais pesados e máquinas), não o protocolo diagnóstico OBD2 que este app lê, então esta consulta não pode ser lida.';

  @override
  String commandFailureUserCanFramingUnknown(
    String protocol,
    String parameter,
  ) {
    return 'Este adaptador está configurado no protocolo CAN definido pelo usuário $protocol, cujo enquadramento é decidido por $parameter. O adaptador não informou essa configuração, então o formato do barramento não pode ser confirmado e esta consulta não pode ser decodificada com segurança.';
  }

  @override
  String get commandFailureBusUndetermined =>
      'O protocolo do barramento do veículo ainda não foi determinado, então esta consulta não pode ser decodificada com segurança. Reconecte.';

  @override
  String get settingsManualCommandCustomFlowControlRejected =>
      'O adaptador recusou um comando personalizado de controle de fluxo, então o modo solicitado não foi aplicado e nenhuma medição foi produzida.';

  @override
  String get settingsManualCommandFlowControlRestoreFailed =>
      'O adaptador recusou restaurar o controle de fluxo padrão (ATFCSM0), então a varredura fica parada até você reconectar.';

  @override
  String get settingsManualCommandExtendedAddressingUnavailable =>
      'Endereçamento estendido não está disponível neste caminho ELM327.';

  @override
  String get settingsManualCommandRawIsoTpModeUnavailable =>
      'Remontagem ISO-TP visível ao host não está disponível neste caminho ELM327.';

  @override
  String get settingsManualCommandCanPriorityUnavailable =>
      'Programação de prioridade CAN não está disponível neste caminho ELM327.';

  @override
  String get settingsManualCommandCanReceiveFilterUnavailable =>
      'Filtragem de recepção CAN não está disponível neste caminho ELM327.';

  @override
  String get settingsManualCommandHeaderRestoreFailed =>
      'O adaptador recusou restaurar o cabeçalho (ATSH), então a varredura fica parada até você reconectar.';

  @override
  String get manualCommandRefusedEmpty =>
      'Nada foi digitado, então nada foi enviado.';

  @override
  String get manualCommandRefusedMoreThanOneCommand =>
      'Este texto traz uma quebra de linha ou outro caractere de controle, o que envia mais de um comando de uma vez. O adaptador separa comandos por quebra de linha, então o segundo pularia todas as verificações feitas aqui — inclusive a que se recusa a limpar códigos de falha. Envie um comando por vez.';

  @override
  String manualCommandRefusedAdapterStateWouldChange(
    Object command,
    Object allowed,
  ) {
    return 'Esta caixa aceita perguntas, não comandos que mudam o que o adaptador é. “$command” mudaria o estado do adaptador enquanto o modelo que o app tem dele permaneceria como estava — as leituras depois disso poderiam vir de outro controlador, sem nada na tela dizer isso.\nConsultas que você pode enviar: $allowed.';
  }

  @override
  String get manualCommandRefusedClearHasItsOwnButton =>
      'Para limpar códigos de falha, use o botão Limpar na tela de códigos de falha. Enviado daqui, pularia a confirmação, a verificação de cobertura e a validação da resposta, e chegaria só ao único controlador selecionado no momento.';

  @override
  String manualCommandRefusedCharactersNoObdCommandHas(Object command) {
    return 'O comando “$command” contém caracteres que um comando OBD nunca tem. Esta caixa aceita códigos de serviço e parâmetros hexadecimais — 0100, 03, 2211A6 — ou uma consulta ao adaptador começando com AT.';
  }

  @override
  String manualCommandRefusedNotAReadOnlyQuery(Object command, Object allowed) {
    return '“$command” não é um comando que esta caixa conhece. Ela aceita consultas somente leitura (Mode $allowed) e consultas ao adaptador.';
  }

  @override
  String commandFailureQueryHeaderRefused(Object header) {
    return 'O adaptador recusou direcionar este pedido ao controlador $header, então o pedido não foi enviado. Se fosse mantido o endereço que o adaptador realmente está usando, a resposta viria de um controlador que não foi consultado.';
  }

  @override
  String commandFailureWholeVehicleHeaderRefused(Object address) {
    return 'O adaptador recusou mudar para o endereço $address, que é o que uma pergunta feita ao veículo inteiro precisa usar. Sem isso, as respostas não podem ser associadas aos controladores que as enviaram, então o pedido não foi feito.';
  }

  @override
  String commandFailureLegacyScanWouldBePartial(Object installed) {
    return 'Este veículo usa um barramento mais antigo sem endereço padrão que alcance todos os controladores, e o adaptador está definido no momento para o controlador $installed. Uma varredura teria coberto só esse controlador enquanto seria apresentada como o veículo inteiro, então não foi enviada. Reconecte e escaneie de novo.';
  }

  @override
  String get pidFormulaEmpty => 'A fórmula está vazia.';

  @override
  String get pidFormulaEmptySubExpression =>
      'Parte da fórmula está vazia — um operador sem nada depois, ou parênteses sem nada dentro.';

  @override
  String get pidFormulaUnbalancedParentheses =>
      'Os parênteses não batem: cada ( precisa de um ) de fechamento.';

  @override
  String pidFormulaUnparsableTerm(String term) {
    return '“$term” não é um número, um operador nem um nome que este editor entende.';
  }

  @override
  String get pidFormulaFunctionNestingTooDeep =>
      'ABS(), LOG10(), LOG() e SQRT() estão aninhados demais para avaliar. Simplifique a fórmula.';

  @override
  String get pidFormulaParenthesisNestingTooDeep =>
      'Os parênteses estão aninhados demais para avaliar. Simplifique a fórmula.';

  @override
  String get pidFormulaDivisionByZero => 'A fórmula divide por zero.';

  @override
  String get pidFormulaModuloByZero => 'A fórmula calcula resto módulo zero.';

  @override
  String pidFormulaLog10NonPositiveArgument(double argument) {
    return 'LOG10 precisa de um argumento maior que 0, e este resultou em $argument.';
  }

  @override
  String pidFormulaLogNonPositiveArgument(double argument) {
    return 'LOG precisa de um argumento maior que 0, e este resultou em $argument.';
  }

  @override
  String pidFormulaSqrtNegativeArgument(double argument) {
    return 'SQRT precisa de um argumento de 0 ou maior, e este resultou em $argument.';
  }

  @override
  String get pidFormulaResultNotFinite =>
      'A aritmética não produziu um número utilizável, então não há leitura para mostrar.';

  @override
  String pidFormulaByteBeyondResponse(String letter, int count) {
    return 'A fórmula se refere ao byte $letter, mas a resposta trouxe só $count bytes.';
  }

  @override
  String get pidFormulaBaroControllerUnknown =>
      'BARO não pode ser usado aqui, porque não se sabe de qual controlador é a pressão ambiente pretendida.';

  @override
  String get pidFormulaBaroTwoDefinitions =>
      'Duas definições fornecem pressão ambiente, então o valor poderia ser qualquer uma e nenhuma pode ser usada. Remova um dos medidores que medem pressão ambiente.';

  @override
  String get pidFormulaBaroNotYetMeasured =>
      'A pressão ambiente ainda não foi lida, então isto não pode ser calculado.';

  @override
  String get pidFormulaBaroMeasurementStale =>
      'A leitura de pressão ambiente está desatualizada, então isto não pode ser calculado.';

  @override
  String get pidFormulaBaroParenFormUnsupported =>
      'BARO() é o barômetro Android / baro da ECU em psi, que este dialeto não implementa. Use BARO sem parênteses para a pressão ambiente em cache.';

  @override
  String get pidFormulaInt16Unclaimed =>
      'INT16 ainda não tem uma interpretação definida neste dialeto: a wiki diz que pode substituir (A*255)+B, o que não é (A*256)+B. Escreva uma dessas identidades explicitamente.';

  @override
  String pidFormulaTimeWindowUnsupported(String term) {
    return '$term é uma função Torque de atraso, média ou totalizer que este dialeto não implementa, então não pode ser avaliada aqui. Não é 0 e não é MIN ou MAX.';
  }

  @override
  String pidFormulaDependencyControllerUnknown(String reference) {
    return '$reference não pode ser resolvido aqui, porque não se sabe a qual controlador esse PID pertence.';
  }

  @override
  String pidFormulaDependencyTwoDefinitions(String key) {
    return 'Duas definições decodificam $key, então o valor poderia ser qualquer uma e nenhuma pode ser usada. Mude uma delas para outro mode+PID. Observação: os PIDs de que as estimativas precisam (010B, 010C, 010D) são sempre lidos, então tirar um medidor do painel não os interrompe.';
  }

  @override
  String pidFormulaDependencyNotYetMeasured(String key) {
    return 'Ainda não foi lido nenhum valor utilizável para $key.';
  }

  @override
  String get pidFormulaUnidentified =>
      'Esta fórmula não pode ser avaliada, e o editor não tem motivo mais específico para isso.';

  @override
  String get pidRejectionMalformedModeAndPid =>
      'Não é um mode+PID válido: só caracteres hexadecimais, em pares de dígitos que formam bytes completos.';

  @override
  String pidRejectionServiceNotReadOnly(String service, String services) {
    return 'O serviço $service não é uma consulta somente leitura e não deve ser enviado ao veículo repetidamente. Só $services são permitidos — dados atuais, quadro congelado, informações do veículo e ReadDataByIdentifier.';
  }

  @override
  String get pidRejectionFreezeFrameNeedsFrame =>
      'Uma consulta de quadro congelado precisa de dois bytes, o PID e o número do quadro — por exemplo 020500 (PID 05, quadro 0).';

  @override
  String get pidRejectionIdentifierNeedsTwoBytes =>
      'ReadDataByIdentifier precisa de um identificador de dois bytes — por exemplo 221101.';

  @override
  String pidRejectionIdentifierWrongLength(String service, int bytes) {
    return 'Uma consulta do serviço $service precisa de um identificador de $bytes bytes.';
  }

  @override
  String get pidRejectionNameRequired => 'Informe um nome.';

  @override
  String pidRejectionInvalidHeader(String text) {
    return '“$text” não é um cabeçalho válido: 3 dígitos para CAN de 11 bits, 6 para os protocolos legados, 8 para CAN de 29 bits.';
  }

  @override
  String get pidRejectionBoundsRequired =>
      'Preencha as duas extremidades da faixa do medidor.';

  @override
  String pidRejectionMinNotANumber(String text) {
    return 'O limite inferior “$text” não é um número válido.';
  }

  @override
  String pidRejectionMaxNotANumber(String text) {
    return 'O limite superior “$text” não é um número válido.';
  }

  @override
  String get pidRejectionMinNotFinite =>
      'O limite inferior tem de ser um número finito.';

  @override
  String get pidRejectionMaxNotFinite =>
      'O limite superior tem de ser um número finito.';

  @override
  String pidRejectionRedlineNotANumber(String text) {
    return 'O início da zona vermelha “$text” não é um número válido.';
  }

  @override
  String get pidRejectionRedlineNotFinite =>
      'O início da zona vermelha tem de ser um número finito.';

  @override
  String get pidRejectionMaxNotAboveMin =>
      'O limite superior tem de ser maior que o limite inferior.';

  @override
  String pidImportMalformedCsv(String detail) {
    return 'Este arquivo não pôde ser lido como CSV: $detail';
  }

  @override
  String get pidImportNoRows => 'O arquivo não tem linhas.';

  @override
  String pidImportDuplicateHeaderColumns(String columns) {
    return 'A linha de cabeçalho nomeia a mesma coluna duas vezes: $columns. Não há como saber qual usar, então corrija o arquivo primeiro.';
  }

  @override
  String pidImportMissingRequiredColumns(String columns, String required) {
    return 'A linha de cabeçalho está sem colunas obrigatórias: $columns. $required são todas necessárias.';
  }

  @override
  String pidImportRowTooFewColumns(int line) {
    return 'Linha $line: células insuficientes — nome, nome curto, PID e fórmula são o mínimo.';
  }

  @override
  String pidImportRowInvalidModeAndPid(int line, String text) {
    return 'Linha $line: “$text” não é um mode+PID válido (só caracteres hexadecimais, em pares de dígitos que formam bytes completos).';
  }

  @override
  String pidImportRowEmptyEquation(int line) {
    return 'Linha $line: a célula da fórmula está vazia.';
  }

  @override
  String pidImportRowRejected(int line, String reason) {
    return 'Linha $line: $reason';
  }

  @override
  String pidImportRowRangeDefaulted(int line, double min, double max) {
    return 'Linha $line: a faixa do medidor estava em branco, então $min–$max foi aplicado. Confira se esta escala serve para este sensor.';
  }

  @override
  String get pidImportNothingImportable =>
      'O arquivo tem linhas, mas nenhuma delas é uma definição de PID.';

  @override
  String get dtcCategoryNoAnswer =>
      'Esta categoria não respondeu. Escaneie de novo.';

  @override
  String get dtcCategoryError =>
      'Esta categoria não pôde ser lida. O erro completo está na transcrição.';

  @override
  String get dtcCategoryDisconnected =>
      'A conexão caiu enquanto esta categoria estava sendo lida.';

  @override
  String get dtcCategoryPending =>
      'Um controlador recebeu o pedido e ainda está processando. Espere e escaneie de novo — isto não é uma recusa.';

  @override
  String get dtcCategoryUnattributed =>
      'Códigos foram retornados, mas os cabeçalhos de resposta estavam desativados, então não se sabe quais controladores responderam. Trate isto como parcial, não como um resultado limpo.';

  @override
  String dtcCategorySilentControllers(int count, String controllers) {
    return '$count controlador(es) não responderam a esta consulta ($controllers). As respostas que chegaram são válidas, mas isto não pode valer como resultado do veículo inteiro.';
  }

  @override
  String dtcCategoryUnresolvedSources(int count, String addresses) {
    return '$count resposta(s) não puderam ser atribuídas a um controlador ($addresses). Os códigos que foram lidos ainda são válidos, mas isto não pode valer como resultado do veículo inteiro. Escaneie de novo.';
  }

  @override
  String dtcCategoryPendingControllers(int count, int answered) {
    return '$count controlador(es) ainda estão processando este pedido ($answered já responderam). O resultado está incompleto. Espere e escaneie de novo.';
  }

  @override
  String dtcCategoryRefusedControllers(int refused, int answered) {
    return '$refused controlador(es) recusaram ($answered responderam). Esta varredura não cobre o veículo inteiro.';
  }

  @override
  String dtcCategoryUnrecognisedResponses(int count, int answered) {
    return '$count resposta(s) não puderam ser lidas ($answered responderam). O restante ainda é válido, mas esta varredura está incompleta.';
  }

  @override
  String dtcCategoryMilCountMismatch(
    String controller,
    int claimed,
    int observed,
  ) {
    return '$controller informou $claimed códigos de falha confirmados, mas esta varredura só leu $observed. Confie na luz do painel e procure uma oficina.';
  }

  @override
  String dtcCategoryMilLitNoCodes(String controller) {
    return '$controller informou que o indicador de mau funcionamento está aceso, mas nenhum dos seus códigos de falha foi lido. Confie na luz do painel e procure uma oficina.';
  }

  @override
  String dtcCategoryMilDisagreement(String controllers) {
    return 'O próprio status do veículo não bate com os códigos de falha que foram lidos ($controllers). Confie na luz do painel e procure uma oficina.';
  }

  @override
  String get connectPairedListFailed =>
      'A lista de Bluetooth emparelhados não pôde ser lida. Confira se o Bluetooth está ligado e tente de novo.';

  @override
  String get connectBleScanUnavailable =>
      'O Bluetooth não está utilizável agora. Espere um momento e busque de novo.';

  @override
  String get connectBleScanBluez =>
      'Nenhum serviço Bluetooth BlueZ/D-Bus utilizável foi encontrado. Instale e inicie o serviço bluetooth e tente de novo.';

  @override
  String get connectBleScanUnclassified => 'A busca BLE falhou.';

  @override
  String dtcClearNrcConditions(String controller) {
    return '$controller recusou a limpeza porque o estado do veículo não permite. A maioria dos controladores não limpa com o motor ligado. Ligue a ignição com o motor parado e tente de novo.';
  }

  @override
  String dtcClearNrcUnsupported(String controller) {
    return '$controller não oferece limpeza Mode 04. Pode ser necessário equipamento do fabricante ou da concessionária.';
  }

  @override
  String dtcClearNrcBusy(String controller) {
    return '$controller está ocupado. Espere e tente de novo.';
  }

  @override
  String dtcClearNrcSecurity(String controller) {
    return '$controller exige acesso de segurança antes de limpar. É necessário equipamento do fabricante ou da concessionária.';
  }

  @override
  String dtcClearNrcOther(String controller, String code) {
    return '$controller recusou a limpeza (código de motivo $code). Espere e tente de novo.';
  }

  @override
  String dtcClearSilentControllers(int count, String controllers) {
    return '$count controlador(es) não responderam à limpeza ($controllers). Os controladores que responderam limparam; outros ainda podem ter códigos. Escaneie de novo. Não envie outra limpeza.';
  }

  @override
  String dtcClearUnresolvedSources(int count, String addresses) {
    return '$count resposta(s) desta varredura não puderam ser atribuídas ($addresses), então não se sabe quais controladores uma limpeza alcançaria. Escaneie de novo; se esse endereço não aparecer de novo, reconecte antes de tentar.';
  }

  @override
  String dtcClearUnresolvedSourcesDoNotRepeat(int count, String addresses) {
    return '$count resposta(s) na resposta da limpeza não puderam ser atribuídas ($addresses). Não envie outra limpeza. Escaneie de novo para ver quais códigos restam.';
  }

  @override
  String dtcClearNrcConditionsDoNotRepeat(String controller) {
    return '$controller recusou a limpeza porque o estado do veículo não permite. A maioria dos controladores não limpa com o motor ligado. Ligue a ignição com o motor parado e escaneie de novo para ver quais códigos restam. Não envie outra limpeza global — uma segunda pode zerar a prontidão de emissões em um controlador que já pode ter limpo.';
  }

  @override
  String dtcClearNrcUnsupportedDoNotRepeat(String controller) {
    return '$controller não oferece limpeza Mode 04. Pode ser necessário equipamento do fabricante ou da concessionária. Não envie outra limpeza global — uma segunda pode zerar a prontidão de emissões em um controlador que já pode ter limpo. Escaneie de novo para ver quais códigos restam.';
  }

  @override
  String dtcClearNrcBusyDoNotRepeat(String controller) {
    return '$controller está ocupado. Não envie outra limpeza global — uma segunda pode zerar a prontidão de emissões em um controlador que já pode ter limpo. Escaneie de novo para ver quais códigos restam.';
  }

  @override
  String dtcClearNrcSecurityDoNotRepeat(String controller) {
    return '$controller exige acesso de segurança antes de limpar. É necessário equipamento do fabricante ou da concessionária. Não envie outra limpeza global — uma segunda pode zerar a prontidão de emissões em um controlador que já pode ter limpo.';
  }

  @override
  String dtcClearNrcOtherDoNotRepeat(String controller, String code) {
    return '$controller recusou a limpeza (código de motivo $code). Não envie outra limpeza global — uma segunda pode zerar a prontidão de emissões em um controlador que já pode ter limpo. Escaneie de novo para ver quais códigos restam.';
  }

  @override
  String get sharePolicyDenied =>
      'A conexão ou o estado de condução atuais não permitem exportar.';

  @override
  String get shareSafetyChanged =>
      'O estado mudou enquanto a exportação era preparada, então o compartilhamento não foi aberto.';

  @override
  String get shareSizeLimit => 'A exportação ultrapassa o limite de 32 MiB.';

  @override
  String get shareStagingBusy =>
      'Um arquivo de compartilhamento anterior ainda está no período de retenção. Tente de novo mais tarde.';

  @override
  String get shareCleanupRequired =>
      'A área de preparação de compartilhamento precisa ser verificada após uma reinicialização.';

  @override
  String get shareSpaceUnknown =>
      'Não foi possível confirmar o espaço livre de que o arquivo de compartilhamento precisa.';

  @override
  String get shareNoSpace =>
      'Não há armazenamento suficiente para preparar o arquivo de compartilhamento.';

  @override
  String get shareHandoffFailed =>
      'O arquivo está pronto, mas o painel de compartilhamento do sistema não pôde ser aberto.';

  @override
  String get shareStorageFailure =>
      'Ocorreu um erro de armazenamento ao preparar ou registrar o compartilhamento.';

  @override
  String shareTelemetrySubject(String sessionId) {
    return 'Registro OBD local $sessionId';
  }

  @override
  String shareRawTranscriptSubject(String stamp) {
    return 'Log de transporte Telltale $stamp';
  }

  @override
  String get shareRecoveredTranscriptSubject =>
      'Log de transporte Telltale (última conexão)';

  @override
  String get sharePidCsvSubject => 'Definições de PID personalizadas Telltale';

  @override
  String get shareTorqueSubsetCsvSubject =>
      'Definições de PID compatíveis com Torque';

  @override
  String get shareHumanReportCsvSubject =>
      'Relatório de PIDs Telltale para leitura';

  @override
  String get transcriptExportUnidentified => 'A exportação falhou.';

  @override
  String get handshakeNoteUnexpected =>
      'Esta etapa falhou com um erro inesperado. O erro completo está na transcrição.';

  @override
  String pidFormulaUnsupportedConstruct(String term) {
    return '$term é uma função Torque que este dialeto não implementa, então a fórmula não pode ser avaliada aqui.';
  }

  @override
  String pidImportRowFormulaRejected(int line, String reason) {
    return 'Linha $line: $reason';
  }

  @override
  String get telemetryHistoryNeedsForeground =>
      'Volte ao Telltale antes de continuar.';

  @override
  String get telemetrySessionPolicyChanged =>
      'O estado de condução ou de conexão mudou durante esta operação.';

  @override
  String get telemetrySessionInvalidId => 'Este id de gravação não é válido.';

  @override
  String get telemetrySessionNotFound =>
      'Esta gravação local não foi encontrada.';

  @override
  String get telemetrySessionStorageFailed =>
      'Uma operação de armazenamento local falhou.';

  @override
  String get telemetrySessionShareFailed =>
      'Não foi possível preparar ou abrir o compartilhamento.';

  @override
  String get pidMutationPersistFailed =>
      'A lista de PIDs personalizados não pôde ser salva. Nada foi alterado.';

  @override
  String get powertrainAuthorizeYearOutOfRange =>
      'Esse ano-modelo está fora da faixa de anos documentada neste perfil.';

  @override
  String get connectionLayerTransport => 'Transporte';

  @override
  String get connectionLayerProtocol => 'Protocolo';

  @override
  String get connectionLayerEcu => 'Respostas da ECU';

  @override
  String get connectionLayerEvidence => 'Evidência';

  @override
  String get connectionLayerUnknown => 'Desconhecido';

  @override
  String get connectionLayerNotObserved => 'Não observado';

  @override
  String get connectionLayerObserved => 'Observado';

  @override
  String get connectionLayerAnswered => 'Respondeu';

  @override
  String get connectionLayerSoftware => 'Software';

  @override
  String get connectionLayerDemo => 'Demo';

  @override
  String get connectionLayerBle => 'Bluetooth LE';

  @override
  String get connectionLayerClassic => 'Bluetooth Classic';

  @override
  String get connectionLayerWifi => 'Wi-Fi';

  @override
  String connectionLayerRequestedObserved(String requested, String observed) {
    return 'pedido $requested, estabelecido $observed';
  }

  @override
  String get connectionLayerKwpSubtypeUnknown =>
      'KWP, 5-baud vs fast não distinguidos';

  @override
  String get connectionFailureOpenSettings => 'Abrir configurações do sistema.';

  @override
  String get connectionFailureTurnRadioOn => 'Ligue o Bluetooth.';

  @override
  String get connectionFailureCheckDistanceOrPower =>
      'O adaptador pode estar fora de alcance ou sem energia. Isso é uma causa possível, não um achado.';

  @override
  String get connectionFailureCheckIgnitionProtocolAdapter =>
      'Verifique a ignição, o protocolo ou a capacidade do adaptador. Silêncio não prova que o veículo não tem OBD.';

  @override
  String get connectionFailureRetryOrAuto =>
      'Tente de novo, ou defina o protocolo como Auto.';

  @override
  String get connectionFailureKeepInvalidAndExport =>
      'A resposta é inválida. Mantenha-a inválida e exporte o diagnóstico limitado; não é uma leitura.';

  @override
  String get settingsCatalogMarketCa => 'Canadá (NRCan)';

  @override
  String get settingsCaPickerTitle => 'Catálogo oficial de veículos do Canadá';

  @override
  String settingsCaPickerScope(int firstYear, int lastYear) {
    return 'Somente linhas de Fuel Consumption Ratings do mercado canadense para $firstYear–$lastYear. ICE, elétrico a bateria e híbrido plug-in permanecem classes separadas. Uma string de marca/modelo correspondente não é uma configuração EPA nem de Taiwan.';
  }

  @override
  String get settingsCaMotorNotPower =>
      'Potência do motor em quilowatts não é potência nas rodas e não é aplicada.';

  @override
  String get settingsCaClassIce => 'ICE';

  @override
  String get settingsCaClassBev => 'BEV';

  @override
  String get settingsCaClassPhev => 'PHEV';

  @override
  String settingsCaWillApplyOnly(String fields) {
    return 'Só $fields serão aplicados. kW do motor, consumo de combustível, autonomia, CO2, VE, Cd, área frontal, Crr e eficiência da transmissão permanecem sem resolver.';
  }

  @override
  String get serviceRecipesTitle =>
      'Procedimentos de serviço e diagnóstico ativo';

  @override
  String get serviceRecipesSubtitle =>
      'Procedimentos de serviço com referência a normas e descoberta de recursos sem acionamento';

  @override
  String get serviceRecipesSafetyBannerTitle =>
      'Zero candidatos para veículos reais';

  @override
  String get serviceRecipesSafetyBannerBody =>
      'O acionamento físico em veículos reais é estritamente proibido (0 veículos qualificados). Os procedimentos disponíveis são apenas casos de teste para simulação.';

  @override
  String get serviceRecipesDiscoverySection =>
      'Descoberta Mode 08 sem acionamento';

  @override
  String get serviceRecipesDiscoveryDescription =>
      'Consulta os IDs de teste básicos padrão (\$00, \$20, ...) pelo CAN sem acionar nenhum componente.';

  @override
  String get serviceRecipesDiscoveryButton =>
      'Descobrir TIDs Mode 08 suportados';

  @override
  String get serviceRecipesDiscovering => 'Consultando TIDs suportados...';

  @override
  String serviceRecipesDiscoverySuccess(String tids) {
    return 'Mode 08 é suportado pela ECU. TIDs suportados: $tids';
  }

  @override
  String get serviceRecipesDiscoveryUnsupported =>
      'Mode 08 não é suportado por esta ECU';

  @override
  String serviceRecipesDiscoveryUnknown(String reason) {
    return 'O suporte a Mode 08 é desconhecido: $reason';
  }

  @override
  String serviceRecipesDiscoveryPartialWarning(String reason, String blocks) {
    return 'Descoberta parcialmente concluída ($reason). Blocos não concluídos: $blocks. Observação: Não encontrado não significa sem suporte.';
  }

  @override
  String get serviceRecipesCatalogSection =>
      'Procedimentos de serviço disponíveis';

  @override
  String get serviceRecipesSimulationBadge => 'Pronto para Simulação';

  @override
  String get serviceRecipesLiveBlockedBadge =>
      'Uso real bloqueado (0 candidatos)';

  @override
  String serviceRecipesStandard(String standard) {
    return 'Padrão: $standard';
  }

  @override
  String serviceRecipesEcuHeader(String header) {
    return 'Cabeçalho ECU: $header';
  }

  @override
  String serviceRecipesHash(String hash) {
    return 'Hash Canônico: $hash';
  }

  @override
  String get serviceRecipesDetailTitle => 'Detalhes do procedimento de serviço';

  @override
  String get serviceRecipesPreconditions => 'Pré-condições de Segurança';

  @override
  String get serviceRecipesRecovery => 'Comando de Recuperação';

  @override
  String get serviceRecipesClose => 'Fechar';

  @override
  String get serviceRecipesDiscoveryRequiresCan =>
      'Requer uma conexão ativa no barramento CAN OBD-II.';

  @override
  String serviceRecipesLoadError(String error) {
    return 'Erro ao carregar procedimentos de serviço: $error';
  }

  @override
  String get serviceRecipesNoPreconditions => 'Nenhuma';

  @override
  String get settingsServiceRecipesEntry =>
      'Procedimentos de serviço e testes ativos';

  @override
  String get settingsServiceRecipesDesc =>
      'Inspecionar procedimentos de serviço de oficina e descobrir testes Mode 08 suportados';

  @override
  String get mode08ReasonUnheaderedLimitation =>
      'Atribuição de origem e cobertura não confirmadas: respostas sem cabeçalho não estabelecem identidade de ECU entre blocos';

  @override
  String mode08ReasonNoResponseWithEcu(
    String block,
    String ecu,
    String marker,
  ) {
    return 'Sem resposta no bloco $block de $ecu: $marker';
  }

  @override
  String mode08ReasonNoResponse(String block, String marker) {
    return 'Sem resposta no bloco $block: $marker';
  }

  @override
  String mode08ReasonNegativeWithEcu(String block, String ecu, String nrc) {
    return 'Resposta negativa no bloco $block de $ecu (NRC $nrc)';
  }

  @override
  String mode08ReasonNegative(String block, String nrc) {
    return 'Resposta negativa no bloco $block (NRC $nrc)';
  }

  @override
  String mode08ReasonMalformedWithEcu(
    String block,
    String ecu,
    String details,
  ) {
    return 'Resposta malformada no bloco $block de $ecu: $details';
  }

  @override
  String mode08ReasonMalformed(String block, String details) {
    return 'Resposta malformada no bloco $block: $details';
  }

  @override
  String mode08ReasonTimeout(String block) {
    return 'Consulta esgotou o tempo no bloco $block';
  }

  @override
  String get mode08ReasonBudgetExceeded =>
      'Limite da descoberta atingido antes de consultar todos os blocos';

  @override
  String get mode08ReasonSessionDisconnected =>
      'Sessão desconectada ou substituída durante a descoberta';

  @override
  String mode08ReasonUnqueriedAnnounced(String blocks) {
    return 'Blocos não consultados anunciados pelas ECUs: $blocks';
  }

  @override
  String get mode08ReasonRequiresCanBus =>
      'A descoberta de recursos Mode 08 requer um barramento CAN OBD-II identificado';

  @override
  String get mode08ReasonUnexpectedExecution =>
      'Resposta de execução inesperada para consulta de TID suportado';

  @override
  String get pidDetailEmptyTitle => 'Selecione um PID';

  @override
  String get pidDetailEmptyBody =>
      'Escolha um PID na lista para inspecionar sua definição e status ao vivo.';

  @override
  String get pidDetailRangeLabel => 'Faixa';

  @override
  String get pidDetailPriorityLabel => 'Prioridade';

  @override
  String pidDetailHeaderDefault(String header) {
    return 'Padrão ($header)';
  }

  @override
  String get dtcSystemOverview => 'Visão geral do sistema';

  @override
  String get dtcPartialObservationBadge => 'Varredura parcial';

  @override
  String get dtcPartialObservationBody =>
      'Este código de falha foi lido, mas a varredura desta categoria não foi concluída em todos os controladores.';

  @override
  String get dtcLinkedFreezeFrameTitle => 'Quadro congelado associado';

  @override
  String get dtcNoLinkedFreezeFrame =>
      'Esta varredura não tem quadro congelado que possa ser associado com segurança a este código de falha e controlador.';

  @override
  String get performanceGuideTitle => 'Guia de corrida de aceleração';

  @override
  String get performanceGuideStep1 =>
      '1. Escolha uma velocidade-alvo e arme o cronômetro';

  @override
  String get performanceGuideStep2 =>
      '2. Pare o veículo por completo e espere até a corrida estar pronta';

  @override
  String get performanceGuideStep3 =>
      '3. Comece a acelerar; a contagem inicia automaticamente quando o movimento é detectado';

  @override
  String get performanceGuideStep4 =>
      '4. Alcance a velocidade-alvo para concluir a corrida';

  @override
  String get performanceRecordingTrace =>
      'Acelerando... gravando traço de velocidade';

  @override
  String get performanceNoAnalysisTitle => 'Sem dados de análise';

  @override
  String get performanceNoAnalysisBody =>
      'Esta corrida parou antes de haver amostras de velocidade suficientes para montar um traço ou resultado por trechos.';

  @override
  String get connectActivityReconnectingAutomatically =>
      'O adaptador parou de responder. Reconectando automaticamente…';
}
