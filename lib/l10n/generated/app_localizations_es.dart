// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get adapterErrorActivityAlert => 'Alerta de actividad del bus.';

  @override
  String get adapterErrorBufferFull => 'El búfer del adaptador se desbordó.';

  @override
  String get adapterErrorBus => 'Error de bus; el cableado puede ser la causa.';

  @override
  String get adapterErrorBusBusy => 'El bus está ocupado.';

  @override
  String get adapterErrorBusInit => 'Falló la inicialización del bus.';

  @override
  String get adapterErrorCan => 'Error del bus CAN.';

  @override
  String get adapterErrorData => 'Los datos recibidos no son correctos.';

  @override
  String get adapterErrorFeedback => 'Error de realimentación de la señal.';

  @override
  String get adapterErrorInternal => 'Error interno del adaptador.';

  @override
  String get adapterErrorLowPowerAlert =>
      'El adaptador está a punto de entrar en modo de bajo consumo.';

  @override
  String get adapterErrorLowVoltageReset =>
      'Un bajo voltaje reinició el adaptador.';

  @override
  String get adapterErrorNoData =>
      'No llegó ninguna respuesta: puede ser silencio temporal, o el vehículo puede no admitir esto.';

  @override
  String get adapterErrorStopped => 'La transferencia se interrumpió.';

  @override
  String get adapterErrorUnableToConnect =>
      'No se puede alcanzar la ECU. Compruebe que el encendido esté activado.';

  @override
  String get adapterErrorUnknownCommand =>
      'El adaptador no admite este comando.';

  @override
  String get appTagline => 'Telemetría del vehículo en vivo';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => 'Apariencia';

  @override
  String get connectActivityAbortingPreviousConnection =>
      'Deteniendo la conexión anterior, un momento…';

  @override
  String get connectAnswerBleWithClassic =>
      'Elija Bluetooth LE. No necesita emparejamiento previo: búsquelo dentro de la aplicación. Aunque aparezca en la lista de emparejamiento Bluetooth del sistema, no lo empareje; esa vía no funciona. Si la búsqueda no encuentra nada, el 4.0 de la caja era solo la especificación del chip: use Bluetooth Classic en su lugar.';

  @override
  String get connectAnswerBleWithoutClassic =>
      'Elija Bluetooth LE. No necesita emparejamiento previo: búsquelo dentro de la aplicación. Aunque aparezca en la lista de emparejamiento Bluetooth del sistema, no lo empareje; esa vía no funciona. Si la búsqueda no encuentra nada, compruebe que el adaptador tenga alimentación, o pruebe con Wi‑Fi en su lugar; este host no ofrece Bluetooth Classic.';

  @override
  String get connectAnswerClassic =>
      'Elija Bluetooth Classic. Emparéjelo primero en los ajustes del sistema; la aplicación no puede emparejarlo por usted. El código suele ser 1234 o 0000.';

  @override
  String get connectAnswerWifiDesktop =>
      'Elija Wi-Fi. Conecte primero este dispositivo a esa red y luego vuelva e introduzca la dirección.';

  @override
  String get connectAnswerWifiPhone =>
      'Elija Wi-Fi. Únase primero a esa red en el teléfono y luego vuelva e introduzca la dirección.';

  @override
  String get connectBleBody =>
      'Un adaptador BLE no necesita emparejarse primero. Busque y luego elija su dispositivo; nombres habituales son OBDII, V-LINK, Vgate o IOS-Vlink.';

  @override
  String connectBleEmptyScan(String next) {
    return 'La búsqueda terminó sin encontrar un adaptador BLE. Compruebe en este orden: ¿está encendida la luz del adaptador? La mayoría de los conectores OBD no tienen alimentación hasta que el encendido está en ON; luego la distancia, así que siéntese en el vehículo antes de buscar. $next Un adaptador BLE no necesita, y no debería tener, emparejamiento en los ajustes del sistema; esa vía no funciona.';
  }

  @override
  String get connectBleEmptyScanNextClassic =>
      'Por último, revise la especificación de la caja: si indica 2.0 o 3.0, es Bluetooth Classic, que nunca aparece en esta lista, así que use Bluetooth Classic arriba en su lugar.';

  @override
  String get connectBleEmptyScanNextWifi =>
      'Por último, revise la especificación de la caja: si indica 2.0/3.0, o solo Wi‑Fi, pruebe con Wi‑Fi en su lugar (este host no ofrece Bluetooth Classic).';

  @override
  String get connectBlePermissionDeniedForever =>
      'El permiso de Bluetooth está denegado de forma permanente. El sistema no volverá a preguntar, así que actívelo en los ajustes de la aplicación.';

  @override
  String get connectBlePermissionNeeded =>
      'Se necesita el permiso de Bluetooth para buscar.';

  @override
  String get connectBleScan => 'Buscar dispositivos BLE';

  @override
  String get connectBleScanning => 'Buscando…';

  @override
  String get connectBleUnavailableHost =>
      'Bluetooth LE aún no está disponible en este host';

  @override
  String get connectBluetoothOff =>
      'Bluetooth está desactivado. Active Bluetooth primero en los ajustes del sistema.';

  @override
  String get connectBluetoothPermissionDeniedForever =>
      'El permiso de Bluetooth está denegado de forma permanente. Actívelo en los ajustes del sistema y vuelva a intentarlo.';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      'Se necesita el permiso de Bluetooth para listar los adaptadores emparejados.';

  @override
  String get connectBody =>
      'Conecte un adaptador ELM327 y active el encendido, o use el simulador integrado.';

  @override
  String get connectCancel => 'Cancelar';

  @override
  String get connectClassicEmptyLinuxPort =>
      'No se encontró ningún puerto serie Bluetooth (/dev/rfcomm*). Empareje primero el ELM327 con BlueZ, luego cree un TTY RFCOMM con rfcomm bind (o el equivalente) y vuelva a intentarlo.';

  @override
  String get connectClassicEmptyPaired =>
      'No se encontró ningún adaptador emparejado. Emparéjelo primero en los ajustes Bluetooth del sistema (el código de la mayoría de los ELM327 es 1234 o 0000).';

  @override
  String get connectClassicEmptyWindowsPort =>
      'No se encontró ningún puerto serie Bluetooth (COMx). Empareje primero el ELM327 en los ajustes Bluetooth de Windows y compruebe que el Administrador de dispositivos muestre “Standard Serial over Bluetooth link”.';

  @override
  String get connectClassicListLinuxPort =>
      'Esto enumera los puertos serie Bluetooth que BlueZ ha vinculado (/dev/rfcomm* o el equivalente). Una lista vacía significa que el sistema aún no ha creado un nodo RFCOMM, no que la aplicación esté rota.';

  @override
  String get connectClassicListPaired =>
      'Esto enumera todos los dispositivos emparejados con el sistema —auriculares y altavoces incluidos—, con los que parecen adaptadores primero. Si elige el equivocado, pulse Cancelar en lugar de esperar a que falle; puede elegir otro de inmediato.';

  @override
  String get connectClassicListWindowsPort =>
      'Esto enumera los puertos COM asociados a Bluetooth (“Standard Serial over Bluetooth link”). Una lista vacía significa que el sistema aún no ha creado un puerto serie virtual, no que la aplicación esté rota.';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic (SPP) está disponible actualmente en Android, macOS (IOBluetooth RFCOMM), Windows (COM) y Linux (/dev/rfcomm*)';

  @override
  String get connectClassicUnavailableIos =>
      'iOS no abre Bluetooth SPP a aplicaciones de terceros';

  @override
  String get connectConnect => 'Conectar';

  @override
  String get connectDemoBody =>
      'Simula un motor turbo de cuatro cilindros de 2,0 L a través de ciclos de ralentí, aceleración, crucero y deceleración, con señales que se mantienen físicamente relacionadas entre sí (la velocidad del motor baja en un cambio de marcha mientras la velocidad de carretera sigue subiendo). Los códigos de fallo, las lecturas de VIN y las consultas por lotes de fastMode funcionan por completo.';

  @override
  String get connectDemoStart => 'Iniciar el simulador';

  @override
  String get connectHandshakeTitle => 'Inicialización ELM327';

  @override
  String get connectHandshakeTitleLastAttempt =>
      'Inicialización ELM327 (último intento)';

  @override
  String get connectHeadline => 'Elija una conexión';

  @override
  String get connectIssueAdapterAcceptedThenSilent =>
      'El adaptador aceptó la conexión pero no respondió a tiempo. Por lo general aún no tiene alimentación —la mayoría de los conectores OBD solo suministran corriente con el encendido activado— u otra aplicación ya está conectada a él; en ese caso cierre esa y vuelva a intentarlo.';

  @override
  String connectIssueAdapterSilentOnReset(String command) {
    return 'El adaptador no respondió al comando de reinicio ($command). Este dispositivo puede no ser un adaptador ELM327, o la conexión puede haber ido al dispositivo equivocado.';
  }

  @override
  String get connectIssueAdapterStoppedResponding =>
      'El adaptador dejó de responder y se ha cortado la conexión.';

  @override
  String get connectIssueConnectionSetupFailed =>
      'La conexión falló mientras se estaba estableciendo. Compruebe que el adaptador tenga alimentación y esté cerca, y vuelva a intentarlo. El error completo se conserva en el registro de abajo.';

  @override
  String get connectIssueHandshakeIncomplete =>
      'La inicialización no se completó. Es posible que el adaptador no sea compatible.';

  @override
  String connectIssueHandshakeStepFailed(String command, String reason) {
    return 'La inicialización falló en $command ($reason). Compruebe que el adaptador esté bien asentado y que el encendido del vehículo esté activado.';
  }

  @override
  String get connectIssuePreviousConnectionStillAborting =>
      'La conexión anterior aún se está deteniendo y el adaptador aún no se ha liberado. Espere unos segundos y vuelva a intentarlo.';

  @override
  String get connectLastAdapterConnect => 'Conectar ahora';

  @override
  String get connectLastAdapterForget => 'Olvidar';

  @override
  String get connectLastAdapterTitle => 'Último adaptador usado';

  @override
  String get connectOpenAppSettings => 'Abrir ajustes de la aplicación';

  @override
  String get connectOpenSystemSettings => 'Abrir ajustes del sistema';

  @override
  String get connectOpeningConnection => 'Abriendo la conexión…';

  @override
  String get connectPairedPill => 'Emparejado';

  @override
  String get connectQuestionBle =>
      '¿La caja, el anuncio de la tienda o el nombre del dispositivo dicen BLE, 4.0 o 5.0?';

  @override
  String get connectQuestionClassic =>
      'Ninguno: ¿uno más antiguo, con 2.0 o 3.0 impreso en la caja?';

  @override
  String get connectQuestionWifiDesktop =>
      '¿Hay una red nueva en la lista Wi-Fi del sistema (algo como V-LINK o WiFi_OBDII)?';

  @override
  String get connectQuestionWifiPhone =>
      '¿Hay una red nueva en la lista Wi-Fi del teléfono (algo como V-LINK o WiFi_OBDII)?';

  @override
  String get connectSearchAgain => 'Buscar de nuevo';

  @override
  String connectSignalStrength(int bars, int total) {
    return 'Intensidad de la señal $bars/$total';
  }

  @override
  String get connectTranscriptKept =>
      'Se conservó la transcripción completa de este intento. Recuperarla ayuda más que un mensaje de una sola línea.';

  @override
  String get connectTransportBleDescription =>
      'GATT UART — un adaptador de baja energía más reciente';

  @override
  String get connectTransportBleTitle => 'Bluetooth LE';

  @override
  String get connectTransportClassicDescription =>
      'RFCOMM / SPP — el ELM327 económico más habitual';

  @override
  String get connectTransportClassicTitle => 'Bluetooth Classic';

  @override
  String get connectTransportDemoDescription =>
      'Una ECU simulada integrada — toda la aplicación sin hardware';

  @override
  String get connectTransportDemoTitle => 'Simulador Demo';

  @override
  String get connectTransportWifiDescription =>
      'Un puerto TCP, normalmente 192.168.0.10:35000';

  @override
  String get connectTransportWifiTitle => 'Wi-Fi';

  @override
  String get connectWhichIntro =>
      'No se preocupe por las palabras SPP y GATT. Guíese por lo que hace su adaptador una vez enchufado:';

  @override
  String get connectWhichNoteGuessing =>
      'Equivocarse no cuesta nada — si no conecta, vuelva y pruebe otro. Si realmente se atasca, use el simulador Demo al final para confirmar que la propia aplicación funciona.';

  @override
  String get connectWhichNoteIos =>
      'Un iPhone solo puede usar Wi-Fi o BLE: un ELM327 Bluetooth ordinario no funciona en absoluto en iOS. Es un límite del sistema operativo, y ninguna otra aplicación lo evita.';

  @override
  String get connectWhichTitle => '¿No está seguro de cuál elegir?';

  @override
  String get connectWifiHostLabel => 'Dirección IP';

  @override
  String get connectWifiHostRequired =>
      'Introduzca la dirección IP del adaptador.';

  @override
  String get connectWifiInstructionsDesktop =>
      'Conecte primero este equipo al punto de acceso Wi-Fi que emite el adaptador y luego introduzca su dirección. Si el sistema advierte que la red no puede acceder a Internet, elija permanecer en ella. Los sistemas de escritorio suelen tratar el punto de acceso como la ruta predeterminada; no se necesita el enlace de ruta Wi-Fi de Android.';

  @override
  String get connectWifiInstructionsPhone =>
      'Únase primero al punto de acceso Wi-Fi que emite el adaptador en el teléfono y luego introduzca su dirección. Si el sistema pregunta si desea permanecer en una red Wi-Fi que no puede acceder a Internet, elija permanecer en ella. En Android, Telltale intenta fijar su tráfico a la ruta Wi-Fi mientras está conectado, para que los datos móviles no se lo lleven.';

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '“$value” no es un puerto válido. El rango es $min–$max.';
  }

  @override
  String get connectWifiPortLabel => 'Puerto';

  @override
  String connectWifiPortRequired(int port) {
    return 'Introduzca el puerto (la mayoría de los adaptadores usan $port).';
  }

  @override
  String get dashboardBatchedPolling => 'Sondeo por lotes';

  @override
  String get dashboardBatchingEnabled => 'Agrupación activada';

  @override
  String get dashboardChoosePids => 'Elegir PID';

  @override
  String get dashboardEmptyBody =>
      'Elija en la página de PID las señales que quiere observar y aparecerán aquí.';

  @override
  String get dashboardEmptyTitle => 'El panel está vacío';

  @override
  String get dashboardGenericObd => 'OBD genérico';

  @override
  String get dashboardLocalRecordings => 'Grabaciones locales';

  @override
  String get dashboardNotConnected => 'No conectado';

  @override
  String get dashboardPollingModeHelpAction => 'Acerca del modo de sondeo';

  @override
  String get dashboardPollingModeHelpBatching =>
      'Agrupación activada significa que Telltale puede agrupar solicitudes de PID en un solo intercambio, para reducir el número de idas y vueltas: los intentos agrupados están permitidos y nada ha desactivado la agrupación. Sigue siendo un permiso más que una medición, porque si un intercambio concreto agrupó algo también depende de qué PID haya confirmado el vehículo y de cuántos estén en espera.';

  @override
  String get dashboardPollingModeHelpObserved =>
      'Sondeo por lotes significa que un comando Mode 01 de esta conexión llevó realmente más de un PID. Es un registro de ese intercambio, no una promesa de que el siguiente agrupará, ni una afirmación sobre el rendimiento.';

  @override
  String get dashboardPollingModeHelpRate =>
      'PIDs/s es una tasa observada durante el último segundo, no una promesa sobre latencia, actualidad o exactitud. Varía con el adaptador, el bus, la ECU, los PID que seleccionó, el tamaño de cada respuesta y cualquier error.';

  @override
  String get dashboardPollingModeHelpSingle =>
      'El modo de solicitud única significa que cada PID de Mode 01 se lee por separado. Telltale lo usa cuando el bus no admite en absoluto solicitudes agrupadas, que es todo vehículo que no es CAN; mientras aún no ha respondido ningún bloque de compatibilidad, porque agrupar PID que el vehículo no ha confirmado es lo que hace que una respuesta vuelva corta; y después de que una solicitud agrupada no regresa en una forma que se pueda volver a separar, ya sea truncada, rechazada porque el adaptador informó su búfer lleno, o sin respuesta. Las lecturas siguen actualizándose, y por sí solo esto no es un fallo de conexión.';

  @override
  String get dashboardPollingModeHelpTitle => 'Modo de sondeo';

  @override
  String get dashboardSingleRequestMode => 'Modo de solicitud única';

  @override
  String get dashboardVinRead => 'VIN leído';

  @override
  String get dashboardWorkspaceGauges => 'Indicadores';

  @override
  String get dashboardWorkspaceTrends => 'Tendencias';

  @override
  String get datumBadgeCommunityDecode => 'Decodificación comunitaria';

  @override
  String get datumBadgeDemo => 'Simulado';

  @override
  String get datumBadgeEstimated => 'Estimado';

  @override
  String get datumBadgeExperimental => 'Experimental';

  @override
  String get datumBadgeFieldVerified => 'Verificado en campo';

  @override
  String get datumBadgeInvalid => 'No válido';

  @override
  String get datumBadgeJustUpdated => 'Recién actualizado';

  @override
  String get datumBadgeOutOfReferenceRange => 'Fuera de rango';

  @override
  String get datumBadgePartial => 'Parcial';

  @override
  String get datumBadgeStale => 'Desactualizado';

  @override
  String get datumBadgeTentativeDecode => 'Decodificación provisional';

  @override
  String get datumBadgeUnverified => 'No verificado';

  @override
  String get datumBadgeUnverifiedOnThisVehicle =>
      'No verificado en este vehículo';

  @override
  String get datumBadgeUserSupplied => 'Facilitado por el usuario';

  @override
  String get datumGapModelYearUnknown => 'Año de modelo desconocido';

  @override
  String get datumGapNoCatalogMatch => 'Sin coincidencia en el catálogo';

  @override
  String get datumGapVinNotRead => 'VIN no leído';

  @override
  String get datumNextStepEstimateOnly =>
      'Esto afecta solo a la estimación; las demás lecturas siguen aplicando.';

  @override
  String get datumNextStepGenericObd =>
      'Puede continuar con OBD genérico, o elegir el vehículo a mano y completar los parámetros.';

  @override
  String get datumNextStepOtherReadings =>
      'El fallo afecta solo a este elemento; las demás lecturas siguen aplicando.';

  @override
  String get datumNextStepRawOnly =>
      'La respuesta en bruto y el error se pueden inspeccionar; ninguno puede tomarse como un valor normal.';

  @override
  String get datumReasonAssumptionsUnconfirmed =>
      'Los supuestos no están confirmados; aún se muestra una estimación.';

  @override
  String get datumReasonBusError => 'Error de bus.';

  @override
  String get datumReasonFormulaError => 'Error de fórmula.';

  @override
  String get datumReasonFuelEstimateMissingInputs =>
      'A la estimación de consumo de combustible le falta una entrada requerida.';

  @override
  String get datumReasonHeaderNotOnThisBus =>
      'El encabezado no coincide con el bus que usa este vehículo.';

  @override
  String get datumReasonHorsepowerEstimateMissingInputs =>
      'A la estimación de potencia le falta una entrada requerida.';

  @override
  String get datumReasonMalformedPacket =>
      'Paquete malformado; solo se puede inspeccionar la respuesta en bruto.';

  @override
  String get datumReasonNoAnswer =>
      'Sin respuesta: la aplicación reintenta en aproximadamente un minuto.';

  @override
  String get datumReasonNoReadingYet => 'Aún no hay lectura.';

  @override
  String get datumReasonNonFiniteValue => 'No es un número finito.';

  @override
  String get datumReasonOutOfReferenceRangeKept =>
      'Fuera del rango de referencia habitual; se conserva tal como se leyó.';

  @override
  String get datumReasonPidUnsupported =>
      'Este vehículo no es compatible con este PID.';

  @override
  String get datumReasonUnsafeService =>
      'Este servicio no es una consulta de solo lectura.';

  @override
  String get datumReasonUnsafeServiceStopped =>
      'Este servicio no es una consulta de solo lectura, por lo que no se envió.';

  @override
  String get datumStatusAssumptions => 'Supuestos';

  @override
  String get datumStatusClose => 'Cerrar';

  @override
  String get datumStatusFollowsData => 'El estado sigue a los datos';

  @override
  String get datumStatusDetailsHint =>
      'Toque para ver detalles del estado de los datos';

  @override
  String get datumStatusUnverifiedExplanation =>
      'No verificado significa que aquí no hay documentada ninguna comparación en un vehículo real para este decodificador en su vehículo. No significa que la lectura sea incorrecta, y no certifica su exactitud. La actualidad y los fallos se muestran por separado.';

  @override
  String get datumStatusFormula => 'Fórmula';

  @override
  String get derivedAirflow => 'Flujo de aire';

  @override
  String get derivedEcuFuelTitle => 'Datos de combustible de la ECU';

  @override
  String get derivedEcuReported => 'Informado por la ECU';

  @override
  String get derivedEngineHorsepower => 'Potencia del motor';

  @override
  String get derivedEstimatedFuelTitle => 'Consumo de combustible estimado';

  @override
  String get derivedEstimatesDetailsTitle =>
      'Fórmulas y supuestos de la estimación';

  @override
  String get derivedEstimatesTitle => 'Valores estimados';

  @override
  String get derivedFuelUse => 'Consumo';

  @override
  String get derivedTorque => 'Par';

  @override
  String get derivedUnavailableMessage =>
      'La potencia solo se puede estimar cuando llegan datos de velocidad del vehículo y de aceleración';

  @override
  String dtcBothSilentDetail(Object mode) {
    return 'El vehículo no respondió a la consulta Mode $mode, y Mode 03 tampoco respondió, así que no hay forma de saber si el vehículo carece de compatibilidad o si esta conexión simplemente no lo leyó.';
  }

  @override
  String dtcCategoryFault(Object category) {
    return 'Un fallo relacionado con $category';
  }

  @override
  String get dtcClear => 'Borrar';

  @override
  String get dtcClearCancel => 'Cancelar';

  @override
  String get dtcClearConfirm => 'Borrarlos';

  @override
  String get dtcClearDialogBody =>
      'Esto borra los códigos de fallo almacenados y pendientes y apaga la lámpara de fallo, y también reinicia la preparación de emisiones — el vehículo tiene que completar de nuevo una ronda completa de autodiagnóstico antes de poder pasar una inspección. Los códigos de fallo permanentes (Mode 0A) no se pueden borrar.';

  @override
  String get dtcClearDialogFrameUnread =>
      'Este escaneo no leyó un fotograma congelado — eso no significa que el vehículo no tenga ninguno. Vuelva a escanear primero y luego decida si borra.';

  @override
  String dtcClearDialogFrames(Object codes) {
    return 'El fotograma congelado de $codes se va con ellos: todo el registro de la velocidad del motor, la temperatura del refrigerante y la carga en el momento en que ocurrió el fallo, y no se puede volver a leer hasta que el fallo ocurra de nuevo.';
  }

  @override
  String get dtcClearDialogTitle => '¿Borrar códigos de fallo?';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categorías de este escaneo no respondieron por completo',
      one: 'Una categoría de este escaneo no respondió por completo',
    );
    return '$_temp0 ($categories), así que puede haber códigos de fallo que no haya visto. Tras un borrado nunca se podrán leer de nuevo.';
  }

  @override
  String get dtcClearCancelledBeforeSend =>
      'El borrado se canceló antes de que ningún comando saliera de la aplicación. Vuelva a escanear y luego inténtelo de nuevo si aún desea borrar.';

  @override
  String get dtcClearConfirmed => 'Se envió el comando de borrado.';

  @override
  String get dtcClearFailureDoNotRepeat =>
      'Es posible que un borrado ya haya llegado al vehículo. No envíe otro: un segundo borrado global puede restablecer la preparación de emisiones en un controlador que puede que ya haya borrado. Vuelva a escanear para ver qué queda.';

  @override
  String get dtcClearFailureGeneric =>
      'El borrado no terminó. Vuelva a escanear para ver los códigos actuales antes de decidir si intentarlo de nuevo.';

  @override
  String get dtcClearNotAccepted =>
      'El borrado falló; ningún controlador aceptó el comando. Puede intentarlo de nuevo.';

  @override
  String get dtcClearPartiallyConfirmed =>
      'Al menos un controlador informó de que el borrado terminó, y el resto no se pudo confirmar. No envíe otro borrado: repetirlo restablece la preparación de emisiones en los controladores que ya terminaron. Vuelva a escanear para ver el resultado.';

  @override
  String get dtcClearPreviousConnectionUnconfirmed =>
      'Una conexión anterior envió un borrado cuyo resultado no se confirmó. Vuelva a escanear primero, vea qué códigos quedan y luego decida si borrar.';

  @override
  String get dtcClearRescanSettled =>
      'El borrado anterior no se pudo confirmar por completo. Lo que sigue es el estado real tras este nuevo escaneo.';

  @override
  String get dtcClearSentUnconfirmed =>
      'Se envió el comando de borrado, pero la respuesta se dañó en tránsito, así que no se sabe si el vehículo borró. Vuelva a escanear para comprobarlo; no envíe otro borrado: si ya tuvo éxito, repetirlo restablece la preparación de emisiones.';

  @override
  String get dtcClearTimeout =>
      'Nada respondió tras enviar el borrado, así que no se sabe si el vehículo borró. Vuelva a escanear para comprobarlo. No envíe otro borrado a ciegas.';

  @override
  String get dtcClearUnexpected =>
      'El borrado falló, así que no se sabe si el vehículo borró. Vuelva a escanear para comprobarlo. No envíe otro borrado a ciegas.';

  @override
  String get dtcClearing => 'Borrando…';

  @override
  String get dtcScanDisconnectedMidScan =>
      'La conexión se cortó durante el escaneo, así que este escaneo no terminó.';

  @override
  String get dtcScanInterrupted =>
      'El escaneo se interrumpió (es posible que la aplicación haya pasado a segundo plano, o que la conexión haya cambiado) y no obtuvo un resultado completo. Escanee de nuevo.';

  @override
  String get dtcCompleteCleanBody =>
      'Eso significa que cada controlador que respondió informó de que no hay ningún código de fallo. No significa que se haya preguntado a todos los módulos del vehículo.';

  @override
  String get dtcCompleteCleanTitle =>
      'Ninguno de los controladores que respondieron reportó un código de fallo.';

  @override
  String dtcControllerLabel(Object controller) {
    return 'Controlador $controller';
  }

  @override
  String get dtcDismiss => 'Descartar';

  @override
  String dtcFreezeFrameBody(Object code) {
    return 'Los valores que este controlador registró en el instante en que se confirmó $code. Borrar los códigos de fallo destruye también este registro.';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      'Este controlador tiene un fotograma congelado, pero no respondió a la consulta sobre qué elementos contiene, así que no se pudieron leer los contenidos. Un nuevo escaneo puede funcionar.';

  @override
  String get dtcFreezeFrameNothingDecodable =>
      'Este controlador tiene un fotograma congelado, pero ninguno de sus elementos es de los que esta aplicación puede decodificar.';

  @override
  String get dtcFreezeFrameTitle => 'El vehículo en el momento del fallo';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count elementos adicionales de este fotograma congelado no tienen fórmula de conversión en esta aplicación, así que no se listan.',
      one: 'Un elemento adicional de este fotograma congelado no tiene fórmula de conversión en esta aplicación, así que no se lista.',
    );
    return '$_temp0';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count elementos no volvieron esta vez (puede que no hubiera tiempo suficiente, o que el controlador no respondiera). Un nuevo escaneo puede leerlos.',
      one: 'Un elemento no volvió esta vez (puede que no hubiera tiempo suficiente, o que el controlador no respondiera). Un nuevo escaneo puede leerlo.',
    );
    return '$_temp0';
  }

  @override
  String get dtcFreezeFrameUnreadPanel =>
      'Este escaneo no leyó un fotograma congelado — eso no significa que el vehículo no tenga ninguno. Vuelva a escanear primero y luego decida si borra los códigos de fallo, porque borrar destruye de forma permanente el registro del momento del fallo. Si cada escaneo se ve igual, es posible que este vehículo no proporcione uno.';

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label (Mode $mode) · $count';
  }

  @override
  String get dtcHeadline => 'Códigos de fallo';

  @override
  String get dtcListSeparator => ', ';

  @override
  String get dtcManufacturerSpecific =>
      'Código específico del fabricante: consulte el manual de servicio de este vehículo';

  @override
  String get dtcMilOff => 'La lámpara de fallo no está encendida';

  @override
  String get dtcMilOn => 'La lámpara de fallo está encendida';

  @override
  String get dtcMonitorBoostPressure => 'Presión de sobrealimentación';

  @override
  String get dtcMonitorCatalyst => 'Catalizador';

  @override
  String get dtcMonitorComponents => 'Componentes integrales';

  @override
  String get dtcMonitorEgr => 'Sistema EGR / VVT';

  @override
  String get dtcMonitorEvaporative => 'Sistema evaporativo';

  @override
  String get dtcMonitorExhaustSensor => 'Sensor de escape';

  @override
  String get dtcMonitorFuelSystem => 'Sistema de combustible';

  @override
  String get dtcMonitorGasolineParticulateFilter =>
      'Filtro de partículas de gasolina (GPF)';

  @override
  String get dtcMonitorHeatedCatalyst => 'Catalizador calentado';

  @override
  String get dtcMonitorMisfire => 'Fallos de encendido';

  @override
  String get dtcMonitorNmhcCatalyst => 'Catalizador NMHC';

  @override
  String get dtcMonitorNoxAftertreatment => 'Postratamiento NOx / SCR';

  @override
  String get dtcMonitorOxygenSensor => 'Sensor de oxígeno';

  @override
  String get dtcMonitorOxygenSensorHeater => 'Calentador del sensor de oxígeno';

  @override
  String get dtcMonitorParticulateFilter => 'Filtro de partículas';

  @override
  String get dtcMonitorSecondaryAir => 'Sistema de aire secundario';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem: esta aplicación no tiene una descripción detallada de este código';
  }

  @override
  String get dtcNotConnectedBody =>
      'Leer códigos de fallo requiere un adaptador ELM327 conectado, o el simulador en ejecución.';

  @override
  String get dtcNotConnectedTitle => 'No conectado';

  @override
  String get dtcNotScanned => 'Aún no se ha escaneado';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count controladores',
      one: 'un controlador',
    );
    return 'Las tres categorías se consultaron hasta el final. En $_temp0 ($controllers) no se implementan códigos de fallo pendientes ni permanentes — normal en muchos vehículos, y también por eso no se puede declarar un vehículo libre de fallos.';
  }

  @override
  String get dtcPartialCleanTitle =>
      'Las categorías que respondieron no informaron de códigos de fallo.';

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories no respondieron, así que su estado no se puede confirmar: eso no es lo mismo que el vehículo no tenga ningún problema.';
  }

  @override
  String dtcPartialCodesRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se leyeron $count códigos de fallo',
      one: 'Se leyó un código de fallo',
    );
    return '$_temp0 antes de que esta categoría se detuviera, pero la cobertura es incompleta:';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return 'Solo algunos controladores de esta categoría respondieron y el resto no contestó, así que esto no puede valer como resultado para todo el vehículo. $message';
  }

  @override
  String get dtcReadFailed => 'Lectura fallida';

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label (Mode $mode): $message';
  }

  @override
  String get dtcReadinessAllComplete =>
      'Todos los monitores de preparación de los que este controlador es responsable están completos.';

  @override
  String dtcReadinessIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monitores siguen sin terminar',
      one: '1 monitor sigue sin terminar',
    );
    return '$_temp0 — una inspección ahora puede no pasar.';
  }

  @override
  String get dtcReadinessSaysNothing =>
      'Este controlador no informó de ningún monitor de preparación: puede que no sea responsable del seguimiento de emisiones, y eso no significa que esté listo.';

  @override
  String get dtcReadinessTitle => 'Preparación de emisiones';

  @override
  String get dtcRescanFirst => 'Vuelva a escanear primero';

  @override
  String get dtcRetry => 'Reintentar';

  @override
  String get dtcScanBody =>
      'Lee códigos de fallo almacenados Mode 03, pendientes Mode 07 y permanentes Mode 0A.';

  @override
  String get dtcScanTitle =>
      'Escanear el vehículo en busca de códigos de fallo';

  @override
  String get dtcScanning => 'Escaneando…';

  @override
  String dtcSelfReportedCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Este controlador autoinforma $count códigos de fallo confirmados.',
      one: 'Este controlador autoinforma 1 código de fallo confirmado.',
    );
    return '$_temp0';
  }

  @override
  String get dtcSelfReportedNoCodes =>
      'Este controlador informa por sí mismo de que no hay códigos de fallo confirmados.';

  @override
  String get dtcSilentCategoryHeadline => 'Esta categoría no respondió';

  @override
  String get dtcSilentPendingDetail =>
      'Los códigos de fallo pendientes (Mode 07) no respondieron. Esta ECU puede no implementar el servicio, o simplemente puede no haberse leído esta vez: la ausencia de respuesta no permite distinguir las dos cosas y no debe tomarse como que no hay fallos pendientes. El resultado de códigos de fallo almacenados no se ve afectado.';

  @override
  String get dtcSilentPermanentDetail =>
      'Los códigos de fallo permanentes (Mode 0A) no respondieron. Esta categoría llegó con la generación OBD-II alrededor de 2010, así que los vehículos más antiguos no siempre la admiten; pero la ausencia de respuesta puede significar igualmente que simplemente no se leyó esta vez, y no se pueden distinguir. El resultado de códigos de fallo almacenados no se ve afectado.';

  @override
  String get dtcStartScan => 'Iniciar escaneo';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return 'El vehículo no respondió a la consulta Mode $mode, así que no se puede confirmar si tiene códigos de fallo almacenados. Eso no es lo mismo que no tener códigos de fallo.';
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
  String get dtcUnconfirmed => 'No se puede confirmar';

  @override
  String get dtcUnknownError => 'Error desconocido';

  @override
  String get dtcUnknownMonitor => 'Monitor desconocido';

  @override
  String get dtcVerdictCompleteClean =>
      'Sin códigos de fallo de los controladores que respondieron';

  @override
  String get dtcVerdictPartialClean => 'Parcialmente sin confirmar';

  @override
  String get fieldEventBody =>
      'Solo debe pulsarse cuando el vehículo esté completamente detenido, por un pasajero o por un operador que esté estacionado. Los eventos comparten una sola línea temporal con los datos OBD en bruto, y se intenta un guardado inmediato.';

  @override
  String get fieldEventEngineStarted => 'Motor arrancado';

  @override
  String get fieldEventHeading => 'Marcadores de evento de campo';

  @override
  String get fieldEventIgnitionOn => 'Encendido activado';

  @override
  String get fieldEventMemoryOnly =>
      'Registrado en esta sesión, pero falló el guardado automático: exporte la transcripción ahora.';

  @override
  String fieldEventRecorded(String marker) {
    return 'Registrado y guardado: $marker';
  }

  @override
  String get fieldEventRoadTestStarted => 'Prueba en carretera iniciada';

  @override
  String get fieldEventThrottleBlip => 'Toque de acelerador';

  @override
  String get fieldEventUnavailable =>
      'No hay una conexión en vivo al vehículo contra la que registrar.';

  @override
  String get gaugeNoData => 'Sin datos';

  @override
  String gaugeNoDataBecause(String reason) {
    return 'Sin datos: $reason';
  }

  @override
  String gaugeReadingStale(String reading) {
    return '$reading (los datos están desactualizados)';
  }

  @override
  String get gaugeUnsupportedByVehicle => 'No compatible con este vehículo';

  @override
  String get handshakeNoteAborted => 'Detenido tras fallar un paso anterior.';

  @override
  String get handshakeNoteEcuRefusedSupportQuery =>
      'La ECU rechazó la consulta de compatibilidad (respuesta negativa).';

  @override
  String get handshakeNoteEcuSilent => 'La ECU no respondió.';

  @override
  String get handshakeNoteNotAcknowledged =>
      'El adaptador no acusó recibo de este comando.';

  @override
  String get handshakeNoteNotModeOnePositiveReply =>
      'La respuesta no es una respuesta positiva de Mode 01.';

  @override
  String get handshakeNotePidEchoMismatch =>
      'La respuesta hace eco de un PID distinto del que se solicitó.';

  @override
  String get handshakeNoteSupportMaskTooShort =>
      'La respuesta de compatibilidad es demasiado corta; se requieren 41 00 y cuatro bytes más.';

  @override
  String get handshakeNoteTimedOut => 'Tiempo agotado.';

  @override
  String get handshakeStepAdapterVersion => 'Leer la versión del adaptador';

  @override
  String get handshakeStepAdaptiveTiming =>
      'Activar la temporización adaptativa, el ajuste que recomienda la hoja de datos';

  @override
  String get handshakeStepBatteryVoltage => 'Leer el voltaje de la batería';

  @override
  String get handshakeStepDeviceIdentity =>
      'Leer la cadena de identificador del dispositivo';

  @override
  String get handshakeStepEchoOff => 'Desactivar el eco de comandos';

  @override
  String get handshakeStepLinefeedsOff => 'Desactivar los saltos de línea';

  @override
  String get handshakeStepMemoryOff => 'Desactivar las escrituras en memoria';

  @override
  String get handshakeStepNoReason => 'sin respuesta';

  @override
  String get handshakeStepProtocolAuto =>
      'Detectar el protocolo del bus automáticamente';

  @override
  String get handshakeStepProtocolDescription =>
      'Leer la descripción del protocolo';

  @override
  String get handshakeStepProtocolNumber => 'Leer el número de protocolo';

  @override
  String get handshakeStepReset => 'Reiniciar por software el adaptador';

  @override
  String get handshakeStepResponseTimeout =>
      'Establecer el tiempo de espera de respuesta en unos 408 ms';

  @override
  String get handshakeStepSpacesOff =>
      'Desactivar los espacios, reduciendo un tercio del tráfico';

  @override
  String get handshakeStepSupportProbe =>
      'Preguntar qué PID admite la ECU, demostrando que un vehículo respondió';

  @override
  String get languageSaveFailed =>
      'No se pudo guardar el idioma. Inténtelo de nuevo.';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navDtc => 'Fallos';

  @override
  String get navPerformance => 'Tiempos';

  @override
  String get navPid => 'PID';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get performanceArm => 'Armar el temporizador';

  @override
  String get performanceDisclaimer =>
      'Los tiempos proceden de la señal OBD de velocidad de carretera. La mayoría de los vehículos marcan 1–3 km/h de más en su propio velocímetro, y la señal solo se actualiza unas 10–20 veces por segundo, así que un resultado aquí es solo indicativo: no equivale a un equipo de prueba profesional.';

  @override
  String get performanceHeadline => 'Prueba de aceleración';

  @override
  String get performanceNoSpeedSignal =>
      'No hay una señal válida de velocidad de carretera en este momento (PID 010D). La prueba de aceleración no puede cronometrar una pasada sin ella.';

  @override
  String get performanceNotConnectedBody =>
      'La prueba de aceleración necesita velocidad de carretera en vivo. Conecte un adaptador, o inicie el simulador integrado.';

  @override
  String get performanceNotConnectedTitle => 'No conectado';

  @override
  String get performancePeakSpeed => 'Velocidad máxima';

  @override
  String get performanceReset => 'Restablecer';

  @override
  String get performanceSecondsUnit => 'segundos';

  @override
  String get performanceSpeedGaugeLabel => 'Velocidad';

  @override
  String get performanceSpeedTraceHeading => 'Trazado de velocidad';

  @override
  String get performanceSplitsHeading => 'Parciales';

  @override
  String get performanceStateAborted =>
      'Esta prueba no se completó; a continuación está lo registrado antes de detenerse';

  @override
  String get performanceStateAwaitingSpeedSignal =>
      'Esperando una señal de velocidad';

  @override
  String performanceStateAwaitingStandstill(String speed) {
    return 'Deténgase por completo primero — ahora $speed km/h';
  }

  @override
  String performanceStateFinished(int target) {
    return 'Completado 0 → $target km/h';
  }

  @override
  String get performanceStateIdle =>
      'Elija una velocidad objetivo y luego inicie';

  @override
  String get performanceStateRunning => 'Cronometrando';

  @override
  String get performanceStateStaged =>
      'Listo — el cronómetro empieza cuando se ponga en movimiento';

  @override
  String get performanceSubhead =>
      'Una prueba cronometrada desde parado hasta una velocidad objetivo';

  @override
  String get performanceTargetSpeedHeading => 'Velocidad objetivo';

  @override
  String get pidActionCancel => 'Cancelar';

  @override
  String get pidActionDelete => 'Eliminar';

  @override
  String get pidArrangeBody =>
      'Arrastre para reordenar. El panel se llena de izquierda a derecha y de arriba abajo, así que lo primero es lo que se ve primero.';

  @override
  String get pidArrangeEmptyMessage =>
      'Active primero algunos en la lista y luego vuelva para ordenarlos.';

  @override
  String get pidArrangeEmptyTitle => 'Aún no hay ningún PID activado';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return 'Añadir los $count confirmados';
  }

  @override
  String get pidBulkActionAllActive => 'Todos ya están activados';

  @override
  String get pidBulkActionIncomplete =>
      'Los datos del escaneo están incompletos';

  @override
  String get pidBulkActionLocked => 'No se puede cambiar durante la grabación';

  @override
  String get pidBulkActionPending => 'Esperando resultados del escaneo';

  @override
  String get pidBulkActionZero => 'No hay PID compatibles confirmados';

  @override
  String pidBulkAddCount(int count) {
    return 'Añadir $count';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return '¿Añadir $count PID compatibles confirmados?';
  }

  @override
  String pidBulkAdded(int count) {
    return 'Se añadieron $count PID compatibles confirmados.';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '$count bloques de compatibilidad siguen sin confirmar — esto añade solo los elementos con evidencia positiva.';
  }

  @override
  String pidBulkWillAdd(int count) {
    return 'Se añadirán $count. Cuantos más PID estén activados, con menos frecuencia puede actualizarse cada uno.';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '$confirmed confirmados';
  }

  @override
  String get pidCapabilityCoverageNone =>
      'Aún no se ha establecido una cobertura continua';

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return 'Cobertura continua 01–$through (se alcanzó el final)';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return 'Cobertura continua 01–$through (desconocido más allá)';
  }

  @override
  String get pidCapabilityPhaseAttemptFinished =>
      'Este escaneo de compatibilidad terminó';

  @override
  String get pidCapabilityPhaseInterrupted =>
      'El escaneo de compatibilidad se interrumpió';

  @override
  String get pidCapabilityPhaseNotStarted => 'Escaneo no iniciado';

  @override
  String get pidCapabilityPhaseRunning =>
      'Confirmando lo que admite este vehículo';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return 'PID admitidos por el vehículo. $phase. $confirmed confirmados. $unknown bloques desconocidos.';
  }

  @override
  String get pidCapabilityTitle => 'PID admitidos por el vehículo';

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '$unknown bloques desconocidos';
  }

  @override
  String pidEditorCollision(String name) {
    return 'Un PID personalizado ya usa esta combinación ($name). Use otro modo + PID, encabezado o sufijo de nombre.';
  }

  @override
  String pidEditorDeleteBody(String name) {
    return 'Se elimina la definición de “$name”, su indicador desaparece del panel y esto no se puede deshacer.';
  }

  @override
  String get pidEditorDeleteTitle => '¿Eliminar este PID?';

  @override
  String get pidEditorDiscard => 'Descartar';

  @override
  String get pidEditorDiscardBody =>
      'Los cambios de este PID no se han guardado y al salir se perderán.';

  @override
  String get pidEditorDiscardTitle => '¿Descartar los cambios sin guardar?';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N se corresponden con los bytes de respuesta; están disponibles SIGNED(), ABS(), LOG10(), $valSyntax y BARO';
  }

  @override
  String get pidEditorFieldEquation => 'Expresión';

  @override
  String get pidEditorFieldHeader => 'Encabezado CAN';

  @override
  String get pidEditorFieldMax => 'Máximo';

  @override
  String get pidEditorFieldMin => 'Mínimo';

  @override
  String get pidEditorFieldModeAndPid => 'Modo + PID';

  @override
  String get pidEditorFieldName => 'Nombre';

  @override
  String get pidEditorFieldSample => 'Bytes de respuesta de prueba';

  @override
  String get pidEditorFieldShortName =>
      'Nombre corto (se muestra en el indicador)';

  @override
  String get pidEditorFieldUnits => 'Unidades';

  @override
  String get pidEditorHeaderHelper => '7E0 = motor';

  @override
  String get pidEditorKeepEditing => 'Seguir editando';

  @override
  String get pidEditorModeAndPidHelper => 'Por ejemplo 010C o 221101';

  @override
  String get pidEditorSampleHelper =>
      'Introduzca hex para previsualizar el resultado mientras escribe';

  @override
  String get pidEditorSave => 'Guardar';

  @override
  String get pidEditorSectionFormula => 'Fórmula';

  @override
  String get pidEditorSectionIdentity => 'Identidad';

  @override
  String get pidEditorSectionQuery => 'Consulta';

  @override
  String get pidEditorSectionRangeAndPriority =>
      'Rango del indicador y prioridad';

  @override
  String get pidEditorTitleEdit => 'Editar PID';

  @override
  String get pidEditorTitleNew => 'Nuevo PID personalizado';

  @override
  String pidExportFailed(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String get pidExportNoCustomPids =>
      'No hay PID personalizados para exportar.';

  @override
  String get pidImportNothingToImport => 'No hay definiciones para importar.';

  @override
  String pidImportLandedClean(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se importaron $count PID personalizados.',
      one: 'Se importó 1 PID personalizado.',
    );
    return '$_temp0';
  }

  @override
  String pidImportLandedWithNotes(int count, String notes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se importaron $count elementos, $notes.',
      one: 'Se importó 1 elemento, $notes.',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteSkippedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas tenían problemas y se omitieron',
      one: '1 fila tenía problemas y se omitió',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDefaultedRanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas usaron el rango de indicador predeterminado',
      one: '1 fila usó el rango de indicador predeterminado',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos sustituyeron definiciones existentes',
      one: '1 elemento sustituyó una definición existente',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDuplicatesInFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas duplicaban otra fila del archivo y se omitieron',
      one: '1 fila duplicaba otra fila del archivo y se omitió',
    );
    return '$_temp0';
  }

  @override
  String get pidImportPickerFailed =>
      'No se pudo abrir el selector de archivos.';

  @override
  String get pidImportReadFailed => 'No se pudo leer el archivo.';

  @override
  String get pidListSeparator => ', ';

  @override
  String get pidManagerActiveOnly => 'Solo activados';

  @override
  String get pidManagerAdd => 'Nuevo';

  @override
  String get pidManagerArrangeDashboard => 'Organizar el panel';

  @override
  String pidManagerCounts(int active, int total) {
    return '$active activados · $total disponibles';
  }

  @override
  String get pidManagerExportCsv => 'Exportar PID personalizados';

  @override
  String get pidManagerExportTorqueCsv => 'Exportar CSV compatible con Torque';

  @override
  String get pidManagerExportHumanReport => 'Exportar informe PID legible';

  @override
  String get pidManagerHeadline => 'Gestor de PID';

  @override
  String get pidManagerImportCsv => 'Importar CSV';

  @override
  String get pidManagerMoreActions => 'Más';

  @override
  String get pidManagerNoMatchMessage =>
      'Pruebe otra palabra clave o cree un PID personalizado.';

  @override
  String get pidManagerNoMatchTitle => 'Ningún PID coincide';

  @override
  String get pidManagerPowertrainBatteryCatalog =>
      'Catálogo de batería del tren motriz';

  @override
  String get pidManagerSearchHint => 'Buscar por nombre o código PID…';

  @override
  String get pidPickCsvDialogTitle => 'Elija un CSV de definiciones de PID';

  @override
  String get pidPillCustom => 'Personalizado';

  @override
  String get pidPillUnsupported => 'No compatible';

  @override
  String get pidPreviewCannotEvaluate => 'No se puede evaluar';

  @override
  String get pidPreviewResultLabel => 'Resultado';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'La vista previa sustituye $valueString por $dependencies; el valor real proviene de ese PID una vez conectado.';
  }

  @override
  String get pidPreviewTitle => 'Vista previa en vivo';

  @override
  String get pidPriorityHigh => 'Alta';

  @override
  String get pidPriorityLow => 'Baja';

  @override
  String get pidPriorityMedium => 'Media';

  @override
  String get pidPriorityVeryLow => 'Muy baja';

  @override
  String get pidRowEdit => 'Editar';

  @override
  String pidRowShowOnDashboard(String name) {
    return 'Mostrar $name en el panel';
  }

  @override
  String pidRowStaleUnits(String units) {
    return '$units · desactualizado';
  }

  @override
  String powertrainAuthorizationGranted(String profile) {
    return 'Las señales de batería de $profile están activas para esta conexión';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return 'No se pudo activar: $reason';
  }

  @override
  String get powertrainCancel => 'Cancelar';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return 'Perfiles: $profiles · Lecturas de un solo intento: $probeable';
  }

  @override
  String get powertrainCatalogLoadFailedBody =>
      'La verificación de integridad no pasó, por lo que no se muestra ni se instala ningún dato del vehículo.';

  @override
  String get powertrainCatalogLoadFailedTitle =>
      'No se pudo cargar el catálogo sin conexión';

  @override
  String get powertrainCatalogNotVerified =>
      'El catálogo no ha pasado la verificación, por lo que no se puede instalar nada.';

  @override
  String get powertrainCatalogRevalidate => 'Verificar de nuevo';

  @override
  String get powertrainCatalogScopeNote =>
      'El catálogo es amplio, pero «encontramos datos» no es «su vehículo es compatible». Las entradas solo de investigación nunca llevan un comando. Las entradas experimentales de Mode 22 pueden instalarse y sondearse, pero cada valor se etiqueta como no verificado; Mode 21 experimental se lee una vez por cada confirmación.';

  @override
  String get powertrainCatalogSearchHint =>
      'Buscar marca, modelo, variante o mercado…';

  @override
  String get powertrainCatalogTitle => 'Catálogo de batería del tren motriz';

  @override
  String get powertrainChooseCommandNote =>
      'Un comando por intento: sin escaneo, sin lote, sin reintento automático.';

  @override
  String get powertrainChooseCommandTitle =>
      'Elija una consulta de solo lectura fijada';

  @override
  String get powertrainClose => 'Cerrar';

  @override
  String get powertrainConfirmAccept => 'Este es el vehículo';

  @override
  String get powertrainConfirmBody =>
      'Las señales del perfil instalado se leen solo después de que usted confirme que este vehículo es ese modelo, y la confirmación dura únicamente esta conexión.';

  @override
  String get powertrainConfirmButton => 'Confirmar vehículo';

  @override
  String get powertrainConfirmDialogBody =>
      'Una vez confirmado, las consultas de batería de solo lectura de este perfil se sondean durante el resto de esta conexión. Un perfil incorrecto puede producir números que parecen plausibles y son erróneos — cancele si no está seguro.';

  @override
  String get powertrainConfirmDialogTitle => 'Confirme el vehículo conectado';

  @override
  String get powertrainConfirmTitle =>
      'Las señales de la batería del vehículo aguardan confirmación';

  @override
  String get powertrainConnectFirst =>
      'Conecte primero; la autorización experimental nunca se conserva entre conexiones.';

  @override
  String get powertrainConnectionChanged =>
      'La conexión cambió — confirme el vehículo de nuevo para la nueva conexión.';

  @override
  String get powertrainEnableLabInSettings =>
      'Active primero el laboratorio experimental de batería en Ajustes.';

  @override
  String get powertrainEvidencePhysicalVehicle => 'Vehículo del proyecto';

  @override
  String get powertrainEvidenceSourceBacked => 'Datos de origen';

  @override
  String get powertrainEvidenceSyntheticRig => 'Banco sintético';

  @override
  String get powertrainExperimentalDataDisclosure =>
      'Esta es una lectura candidata etiquetada por los autores de la fuente, no una garantía de seguridad del fabricante ni entre modelos; ELM327 solo reenvía el comando. El comando y la respuesta en bruto permanecen en la transcripción diagnóstica local y esta función no los carga automáticamente; los valores decodificados nunca se instalan como PID ni se añaden a un indicador. Cancelar no afecta a las funciones OBD habituales.';

  @override
  String get powertrainExperimentalDialogTitle =>
      'Confirmación experimental de solo lectura de un solo intento';

  @override
  String get powertrainExperimentalIdentityAck =>
      'He comprobado el mercado, el modelo y el año de modelo que conoce la fuente, y acepto los campos no confirmados';

  @override
  String get powertrainExperimentalParkedAck =>
      'El vehículo está estacionado de forma segura; entiendo que esto se lee una vez y que el número puede no aplicar igualmente';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return 'Acepta solo RX $responder, longitud de carga útil $bytes bytes';
  }

  @override
  String get powertrainFieldListSeparator => ', ';

  @override
  String get powertrainFieldMarket => 'Mercado';

  @override
  String get powertrainFieldModel => 'Modelo';

  @override
  String get powertrainFieldModelYear => 'Año de modelo';

  @override
  String get powertrainFieldVariant => 'Variante';

  @override
  String get powertrainFilterAll => 'Todos';

  @override
  String get powertrainIdentityEvidenceExact => 'evidencia directa';

  @override
  String get powertrainIdentityEvidenceNone => 'ninguno';

  @override
  String get powertrainIdentityEvidenceSourcePartial => 'evidencia parcial';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return 'Evidencia de identidad de la fuente: $fields\nCampos no confirmados: $unconfirmed';
  }

  @override
  String get powertrainIdentityEvidenceUnknown => 'desconocido';

  @override
  String get powertrainInstallButton => 'Instalar señales de batería';

  @override
  String get powertrainInstallConfirm => 'Instalar';

  @override
  String get powertrainInstallDialogTitle =>
      'Instalar las señales de batería de este modelo';

  @override
  String get powertrainInstallDisclosureCommunity =>
      'Instalar solo añade PID de batería de solo lectura a la gestión de PID. Antes de que empiece cualquier lectura, cada conexión le pide que confirme en el panel que este vehículo es ese modelo. Los datos proceden de fuentes de la comunidad y se han corroborado de forma independiente; sigue sin ser una garantía del fabricante.';

  @override
  String get powertrainInstallDisclosureExperimental =>
      'Instalar solo añade PID de batería de solo lectura a la gestión de PID. Antes de que empiece cualquier lectura, cada conexión le pide que confirme en el panel que este vehículo es ese modelo. Esta es una decodificación experimental sin requisito de corroboración independiente, no verificada en este vehículo, y sigue sin ser una garantía del fabricante.';

  @override
  String get powertrainInstallDisclosureReady =>
      'Instalar solo añade PID de batería de solo lectura a la gestión de PID. Antes de que empiece cualquier lectura, cada conexión le pide que confirme en el panel que este vehículo es ese modelo. Los datos de origen son más completos; sigue sin ser una garantía del fabricante.';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      'Instalar solo añade PID de batería de solo lectura a la gestión de PID. Antes de que empiece cualquier lectura, cada conexión le pide que confirme en el panel que este vehículo es ese modelo. Esta entrada es solo para investigación y no debería instalarse.';

  @override
  String get powertrainInstallCatalogShaMissing =>
      'No se puede instalar: esta instantánea del catálogo no tiene un SHA-256 verificado, por lo que no se puede confiar en nada de ella.';

  @override
  String get powertrainInstallPersistFailed =>
      'No se puede instalar: no se pudo guardar la lista de perfiles instalados. Inténtelo de nuevo; no se añadió nada a la gestión de PID.';

  @override
  String get powertrainInstallProfileNotInCatalog =>
      'No se puede instalar: ese perfil no está en el catálogo verificado.';

  @override
  String get powertrainInstallProfileNotInstallable =>
      'No se puede instalar: este perfil no está en un estado que pueda convertirse en PID en vivo.';

  @override
  String get powertrainInstallYearOutOfRange =>
      'No se puede instalar: ese año de modelo está fuera del rango de años documentado de este perfil.';

  @override
  String get powertrainInstallIdentityAck =>
      'Mi vehículo coincide con el mercado, el modelo y el año de modelo anteriores';

  @override
  String get powertrainInstalledRemoveButton => 'Instalado · quitar señales';

  @override
  String powertrainInstalledSignalsSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se instalaron $count señales. Añádalas al panel desde la página de PID; cada conexión necesita una confirmación del vehículo.',
      one: 'Se instaló 1 señal. Añádala al panel desde la página de PID; cada conexión necesita una confirmación del vehículo.',
    );
    return '$_temp0';
  }

  @override
  String get powertrainNoMatchBody =>
      'Pruebe un nombre de marca o modelo, o cambie a otro tipo de tren motriz.';

  @override
  String get powertrainNoMatchTitle => 'Ningún vehículo coincide';

  @override
  String get powertrainNotInstallableInThisRelease =>
      'No instalable en esta versión';

  @override
  String powertrainPrimarySource(String name, String license) {
    return 'Fuente principal: $name ($license)';
  }

  @override
  String get powertrainProbeChecksPassed =>
      'Pasó las comprobaciones de respondedor, eco, longitud exacta, fórmula y rango.';

  @override
  String get powertrainProbeConnectForOneShot =>
      'Conéctese para una consulta de solo lectura de un solo intento';

  @override
  String get powertrainProbeConnectToTryOnce =>
      'Conéctese para probar primero una lectura';

  @override
  String get powertrainProbeDidNotFinish =>
      'La consulta única no terminó; no se publicó ni se conservó ningún valor.';

  @override
  String get powertrainProbeEnableLabFirst =>
      'Active primero el laboratorio en Ajustes';

  @override
  String get powertrainProbeInProgress => 'Leyendo una vez…';

  @override
  String get powertrainProbeNoValuePublished =>
      'No se publicó ningún valor; un error estructural o de decodificación queda en cuarentena hasta que se vuelva a conectar.';

  @override
  String get powertrainProbeOnceButton => 'Leer solo una vez';

  @override
  String get powertrainProbePassedTitle =>
      'Consulta de un solo intento superada';

  @override
  String get powertrainProbePickOneRead => 'Elija un comando, lea una vez';

  @override
  String get powertrainProbeReconnectFirst =>
      'Vuelva a conectar e inténtelo de nuevo';

  @override
  String get powertrainProbeRefusedTitle =>
      'Consulta de un solo intento rechazada';

  @override
  String get powertrainProbeTryOnceFirst => 'Pruebe primero una lectura';

  @override
  String get powertrainProfileNotVerified =>
      'El perfil no está en el catálogo verificado';

  @override
  String get powertrainQuarantinedPill => 'En cuarentena · reconectar';

  @override
  String get powertrainRefusedCatalogHashInvalid =>
      'No autorizado: el hash de integridad del catálogo no es válido, por lo que no se puede leer nada de él.';

  @override
  String get powertrainRefusedCommandNotInProfile =>
      'No autorizado: ese comando no es uno de los comandos propios de este perfil verificado.';

  @override
  String get powertrainRefusedLabClosed =>
      'El laboratorio experimental de batería se desactivó antes de que se pudiera autorizar esta lectura.';

  @override
  String get powertrainRefusedProfileFailedValidation =>
      'No autorizado: este perfil no pasó la validación del catálogo con el año de modelo que eligió.';

  @override
  String get powertrainRefusedProfileNotInCatalog =>
      'No autorizado: este perfil no está en el catálogo verificado.';

  @override
  String get powertrainRefusedProfileNotProbeable =>
      'No autorizado: este perfil no es de los que se pueden leer una vez de forma experimental.';

  @override
  String get powertrainRefusedQuarantinedAfterRejectedRead =>
      'En cuarentena para esta conexión: una lectura previa de un solo intento no pasó sus comprobaciones estructurales. Vuelva a conectar antes de intentarlo de nuevo.';

  @override
  String get powertrainRefusedNotConnectedOrNotInForeground =>
      'La lectura de un solo intento no se inició: no hay nada conectado, o la aplicación no estaba en primer plano.';

  @override
  String get powertrainRefusedNoLiveAuthorization =>
      'La lectura de un solo intento no se inició: no se está reteniendo ninguna autorización de un solo uso. No se otorgó, o ha caducado, entró en un período de espera o quedó en cuarentena.';

  @override
  String get powertrainRefusedDiscardedAtLifecycleBoundary =>
      'La conexión o el estado en primer plano cambió mientras corría la lectura de un solo intento, por lo que su respuesta se descartó en lugar de mostrarse. Nada falló y nada se conservó.';

  @override
  String powertrainRefusedQuarantinedAtAttemptCap(int attemptCap) {
    return 'En cuarentena para esta conexión: el mismo comando ya se ha intentado $attemptCap veces. Vuelva a conectar antes de intentarlo de nuevo.';
  }

  @override
  String get powertrainResearchOnlyNeverQueries =>
      'Solo investigación — nunca consulta';

  @override
  String get powertrainRestoreStorageErrorRetry =>
      'Ocurrió un error de almacenamiento al restaurar instalaciones anteriores. Se ha reprogramado — inténtelo de nuevo.';

  @override
  String powertrainSecondarySource(String name, String license) {
    return 'Corroboración independiente: $name ($license)';
  }

  @override
  String powertrainSignalCount(int count) {
    return 'Señales: $count';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return 'SHA-256 del archivo de origen: $hash…';
  }

  @override
  String get powertrainStatusCommunity => 'Comunidad · no verificado';

  @override
  String get powertrainStatusExperimental => 'Experimental · no verificado';

  @override
  String get powertrainStatusExperimentalProbeOnly =>
      'Experimental · leer una vez';

  @override
  String get powertrainStatusReady => 'Datos de origen más completos';

  @override
  String get powertrainStatusResearchOnly => 'Solo investigación';

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return 'Se quitaron las señales instaladas de $name.';
  }

  @override
  String powertrainVehicleYearFixed(int year) {
    return 'Año de modelo: $year';
  }

  @override
  String get powertrainVehicleYearLabel => 'Año de modelo';

  @override
  String get recommendedPurchaseDisclosure =>
      'Este es un enlace de afiliado del mantenedor; una compra que cumpla los requisitos puede pagar una comisión al mantenedor. No es una certificación del adaptador ni una garantía de compra. El contenido del anuncio y las revisiones del hardware pueden cambiar, así que compruebe el número de modelo completo y el número NCC antes de comprar. También puede buscar usted mismo otros vendedores.';

  @override
  String get recommendedPurchaseHeading => 'Adaptador recomendado';

  @override
  String recommendedPurchaseModelLine(String model, String approval) {
    return 'Modelo $model · NCC $approval';
  }

  @override
  String recommendedPurchaseNoAdapterYet(String store) {
    return '¿Aún no tiene adaptador? Vea el recomendado en $store';
  }

  @override
  String recommendedPurchaseOpenFailed(String store) {
    return 'No se pudo abrir el enlace de $store';
  }

  @override
  String get recommendedPurchaseShortDisclosureAction =>
      'Divulgación completa en Ajustes';

  @override
  String get recommendedPurchaseShortDisclosureLead =>
      'Este es un enlace de afiliado, no una certificación del adaptador.';

  @override
  String get recommendedPurchaseStoreShopee => 'Shopee';

  @override
  String recommendedPurchaseViewOnStore(String store) {
    return 'Ver en $store';
  }

  @override
  String get semanticsFieldSeparator => ', ';

  @override
  String get settingsAdapterConcernsFooter =>
      'Estos son puntos en los que el relato del adaptador sobre sí mismo no cuadra, no evidencia de que haya leído mal el vehículo. La única forma de confirmar un valor es una segunda medición independiente (véase la guía de campo).';

  @override
  String get settingsAdapterNoContradictions =>
      'No se encontraron contradicciones en la autodescripción. Eso solo significa que es coherente consigo mismo — no es evidencia de que el chip sea genuino, ni evidencia de que los números que reporta sean correctos. En un clon, la cadena de versión es solo texto que alguien eligió.';

  @override
  String get settingsAdapterNoVersion => '(ninguna versión reportada)';

  @override
  String get settingsAdapterSelfReportTitle =>
      'Lo que el adaptador dice de sí mismo';

  @override
  String get settingsBatteryLabDialogBody =>
      'Estas son fuentes candidatas obtenidas por ingeniería inversa, no documentación del fabricante, y no son soporte de Telltale para su vehículo. Incluso una consulta de solo lectura puede despertar un controlador; un número decodificado puede parecer plausible y aun así no aplicar.';

  @override
  String get settingsBatteryLabDialogTitle =>
      'Activar el laboratorio de batería';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      'El laboratorio de batería está desactivado en esta ejecución, pero no se pudo guardar el ajuste; el próximo arranque puede volver a mostrar el laboratorio, y cada consulta sigue necesitando su propia confirmación.';

  @override
  String get settingsBatteryLabEnableNotSaved =>
      'No se pudo guardar el ajuste del laboratorio de batería; permanece desactivado.';

  @override
  String get settingsBatteryLabEvidenceAck =>
      'Entiendo que los datos de origen y las pruebas sintéticas no demuestran que esto se aplique a mi propio vehículo';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      'Solo revela consultas de solo lectura de un solo intento cuyas fuentes están completas y vinculadas por hash. No instala PID, no sondea, no añade indicadores ni trata los datos de investigación como compatibilidad.';

  @override
  String get settingsBatteryLabSwitchTitle =>
      'Laboratorio de batería (experimental)';

  @override
  String get settingsBatteryLabUnlockReadOnly =>
      'Desbloquear solo consultas de solo lectura de un solo intento';

  @override
  String get settingsBatteryLabWireAck =>
      'Entiendo que esto desbloquea solo consultas de un solo intento en direcciones fijas Mode 21/22 del catálogo — no escaneo, no una sesión de diagnóstico, no acceso de seguridad, no escritura, no control';

  @override
  String get settingsCancel => 'Cancelar';

  @override
  String get settingsCatalogChoose => 'Elegir del catálogo oficial';

  @override
  String get settingsCatalogCorrupt =>
      'El catálogo oficial sin conexión está dañado o no se pudo cargar; no se aplicó nada.';

  @override
  String get settingsCatalogNothingApplicable =>
      'Esta configuración oficial no tiene ningún campo que se pueda aplicar de forma segura a las fórmulas actuales; el perfil existente no cambia.';

  @override
  String get settingsCatalogScope =>
      'Catálogos oficiales: EPA de EE. UU., MOEA de Taiwán, NRCan de Canadá. Cada instantánea es solo de ese mercado, no de todas las marcas ni años del mundo.';

  @override
  String get settingsCatalogVerifying =>
      'Verificando el catálogo sin conexión…';

  @override
  String get settingsCatalogChooseMarket =>
      'Elija qué catálogo oficial explorar';

  @override
  String get settingsCatalogMarketTw =>
      'Taiwán (Administración de Energía MOEA)';

  @override
  String get settingsCatalogMarketUs => 'Estados Unidos (EPA)';

  @override
  String get settingsTwCertificationYear => 'Año de certificación';

  @override
  String get settingsTwMake => 'Marca de Taiwán';

  @override
  String settingsTwPickerScope(int firstYear, int lastYear) {
    return 'Solo filas de certificación del mercado de Taiwán para $firstYear–$lastYear. El año es el año calendario de certificación de la Administración de Energía, no un año de modelo de EE. UU. Una cadena coincidente de marca/modelo no es una configuración EPA.';
  }

  @override
  String get settingsTwPickerTitle => 'Catálogo oficial de vehículos de Taiwán';

  @override
  String get settingsTwReferenceMassNotCurb =>
      'La masa de referencia del vehículo no es curb mass y no se aplica.';

  @override
  String settingsTwWillApplyOnly(String fields) {
    return 'Solo se aplicarán: $fields. Masa de referencia, VE, Cd, área frontal, Crr y eficiencia de la transmisión siguen sin resolverse.';
  }

  @override
  String get settingsClose => 'Cerrar';

  @override
  String get settingsConnectionSection => 'Conexión';

  @override
  String get settingsDiagnosticsSection => 'Transcripción diagnóstica';

  @override
  String get settingsDisconnect => 'Desconectar';

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return 'Eficiencia de la transmisión $percent %';
  }

  @override
  String settingsEpaApplyFields(int count) {
    return 'Aplicar $count campos oficiales';
  }

  @override
  String get settingsEpaChooseExact => 'Elegir una configuración exacta';

  @override
  String get settingsEpaCloseNoFields => 'Cerrar (no hay campos que aplicar)';

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'Configuración EPA $epaId';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count cil.';
  }

  @override
  String get settingsEpaDriveUnknown => 'Tracción desconocida';

  @override
  String get settingsEpaFuelUnknown => 'Combustible desconocido';

  @override
  String get settingsEpaMake => 'Marca EPA';

  @override
  String get settingsEpaModel => 'Modelo';

  @override
  String get settingsEpaNoConfigurations =>
      'No hay configuraciones disponibles para este modelo';

  @override
  String get settingsEpaNoSafeFields =>
      'Esta configuración no tiene ningún campo que se pueda aplicar de forma segura a las fórmulas actuales; no se adivina nada.';

  @override
  String get settingsEpaPickInOrder =>
      'Elija año de modelo, marca y modelo en orden';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return 'Configuraciones de la instantánea del mercado de EE. UU. solo para $firstYear–$lastYear. Los modelos que comparten nombre siguen necesitando el año de modelo, la transmisión, el combustible y el ID EPA para distinguirlos.';
  }

  @override
  String get settingsEpaPickerTitle =>
      'Catálogo oficial de vehículos EPA de EE. UU.';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return 'Solo se aplicarán: $fields. Masa, VE, Cd, área frontal, Crr y eficiencia de la transmisión siguen sin resolverse.';
  }

  @override
  String get settingsEpaYear => 'Año de modelo';

  @override
  String get settingsExperimentalSection => 'Experimental';

  @override
  String get settingsFieldDisplacement => 'Cilindrada';

  @override
  String get settingsFieldDragCoefficient => 'Coeficiente de resistencia Cd';

  @override
  String get settingsFieldDrivetrain => 'Tren de transmisión';

  @override
  String get settingsFieldFrontalArea => 'Área frontal';

  @override
  String get settingsFieldFuel => 'Combustible';

  @override
  String get settingsFieldMass => 'Masa';

  @override
  String get settingsFieldMassWithDriver => 'Masa (con conductor)';

  @override
  String get settingsFieldRollingResistance => 'Resistencia a la rodadura Crr';

  @override
  String get settingsFieldVolumetricEfficiency => 'Eficiencia volumétrica VE';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return 'Relación aire-combustible $afr · densidad $density g/L';
  }

  @override
  String get settingsFuelAndDrivetrainSection =>
      'Combustible y tren de transmisión';

  @override
  String get settingsFuelTypeLabel => 'Tipo de combustible';

  @override
  String get settingsGaugeSkinBody =>
      'No es solo un cambio de color: cada uno tiene una cara de dial, una aguja y un movimiento distintos. Todos funcionan sobre fondos oscuros y claros.';

  @override
  String get settingsGaugeSkinTitle => 'Estilo del indicador';

  @override
  String get settingsGoToConnect => 'Ir a Conectar';

  @override
  String get settingsHeadline => 'Ajustes';

  @override
  String get settingsLicenseLegalese =>
      'Las fuentes de batería del tren motriz, las transformaciones y los términos de reutilización se incluyen con esta aplicación.';

  @override
  String get settingsListSeparator => ', ';

  @override
  String get settingsManualCommandBody =>
      'Envíe un comando directamente al adaptador — por ejemplo ATI, ATDPN, 0100. Entra en la misma cola que el sondeo normal y no se adelanta.';

  @override
  String get settingsManualCommandFieldLabel => 'Comando';

  @override
  String get settingsManualCommandNoContent => '(sin contenido de respuesta)';

  @override
  String get settingsManualCommandSend => 'Enviar';

  @override
  String get settingsManualCommandTitle => 'Comando manual';

  @override
  String get settingsNotConnected => 'No conectado';

  @override
  String get settingsOpenSourceLicenses =>
      'Licencias de código abierto y de datos';

  @override
  String get settingsProfileConfirmAfterConnect =>
      'Conéctese para confirmar este vehículo';

  @override
  String get settingsProfileConfirmButton =>
      'Confirmar este vehículo para esta conexión';

  @override
  String get settingsProfileConfirmedButton => 'Confirmado para esta conexión';

  @override
  String get settingsProfileConfirmedDetail =>
      'El perfil está confirmado para esta conexión. Cambiar cualquier valor, o volver a conectar, implica confirmar de nuevo.';

  @override
  String get settingsProfileEstimatesIntro =>
      'La potencia, el par y el consumo de combustible se estiman a partir de estos parámetros; cuanto más se acerquen al vehículo real, más significan las estimaciones.';

  @override
  String get settingsProfileNameProvesNothing =>
      'Un nombre de marca o un VIN por sí solos no establecen la masa, la resistencia aerodinámica, VE ni la eficiencia de la transmisión.';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      'No confirmado en esta conexión. Las lecturas OBD medidas se siguen mostrando, pero los valores estimados a partir de masa, VE y resistencia aerodinámica no.';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      'Conéctese a este vehículo antes de confirmar. La confirmación caduca en cada reconexión, de modo que el perfil de un vehículo nunca se aplica al siguiente.';

  @override
  String get settingsProvenanceNoneExact =>
      'Ningún campo se ha resuelto de forma exacta para este vehículo; los valores genéricos, introducidos a mano y de orígenes anteriores siguen necesitando confirmación.';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return 'Campos con una fuente oficial exacta: $fields. Todos los demás campos siguen necesitando confirmación uno por uno.';
  }

  @override
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  ) {
    return 'Procedencia: oficial o del fabricante $official / $total campos · introducido por el usuario $user / $total · valor predeterminado genérico $generic / $total · modelo científico $scientific / $total';
  }

  @override
  String settingsProvenancePublishers(String publishers) {
    return 'Fuentes: $publishers';
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
    return 'Resolución: exacto oficial $exact / $total campos · confirmado en esta sesión $sessionConfirmed / $total · sin resolver $unresolved / $total · ambiguo $ambiguous / $total · en conflicto $conflict / $total';
  }

  @override
  String get settingsStandardsFooter =>
      'La implementación OBD2 de esta aplicación sigue estándares públicos, entre ellos SAE J1979 y la hoja de datos ELM327; cada fórmula y cada comando AT que afecta el comportamiento del hardware se verifica de forma cruzada, y los resultados se registran en docs/protocol-deviations.zh-TW.md. Esta aplicación no está afiliada a Torque ni a Torque Pro.';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeSystem => 'Seguir el sistema';

  @override
  String get settingsVehicleProfileSection => 'Perfil del vehículo';

  @override
  String get settingsVinConflict => 'Conflicto de VIN';

  @override
  String get settingsVinConflictDetail =>
      'Los controladores informaron VIN distintos, por lo que no se puede confirmar la identidad del vehículo; todos los candidatos se descartaron.';

  @override
  String get settingsVinNotRead => 'VIN aún no leído';

  @override
  String get settingsVinNotReadConnectedDetail =>
      'El VIN de Mode 09 se puede leer del vehículo ahora; la identidad se conserva solo para esta conexión. La transcripción de diagnóstico en bruto aún puede contener el VIN.';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      'Una vez conectado, se puede leer el VIN que el vehículo informa sobre sí mismo; la identidad no se traslada a la siguiente conexión. La transcripción de diagnóstico en bruto aún puede contener el VIN.';

  @override
  String get settingsVinRead => 'Leer VIN';

  @override
  String get settingsVinReading => 'Leyendo…';

  @override
  String get settingsVinReportedDetail =>
      'Un VIN es lo que el vehículo informa sobre sí mismo; no verifica las especificaciones del modelo. La identidad no cruza conexiones; la transcripción de diagnóstico aún puede contener el VIN.';

  @override
  String get settingsVinSimulatorReported => 'VIN informado por el simulador';

  @override
  String get settingsVinUnavailable => 'VIN no disponible';

  @override
  String get settingsVinUnavailableDetail =>
      'El vehículo puede no ofrecer uno, la respuesta puede haber estado incompleta, o no se leyó en esta conexión; no se adivina nada y no se rellenan caracteres.';

  @override
  String get settingsVinVehicleReported => 'VIN informado por el vehículo';

  @override
  String get startupCannotComplete =>
      'No se pueden terminar las comprobaciones de arranque';

  @override
  String get startupChecking =>
      'Comprobando la caché local de uso compartido y los registros de telemetría';

  @override
  String get startupRestartHint =>
      'No se pudo confirmar el estado de la caché de uso compartido local o de los registros de telemetría. Cierre por completo y vuelva a abrir Telltale para que no se sobrescriba, elimine o comparta el archivo equivocado.';

  @override
  String get startupRestartRequired =>
      'Se requiere reiniciar para continuar con seguridad';

  @override
  String get startupRetry => 'Reintentar';

  @override
  String get startupRetryHint =>
      'Mantenga Telltale en primer plano y reintente cuando termine otro trabajo con archivos. La grabación, la reproducción, la exportación y la eliminación permanecen cerradas hasta que termine el inicio.';

  @override
  String get telemetryArtifactRestartRequired =>
      'No se puede confirmar el estado del trabajo local con archivos. Cierre Telltale por completo y vuelva a abrirlo antes de continuar';

  @override
  String get telemetryBlockedByRecorder =>
      'Detenga y guarde la grabación primero';

  @override
  String get telemetryCancel => 'Cancelar';

  @override
  String get telemetryDamagedCollision =>
      'Un archivo terminado y otro sin terminar comparten este id — no se eligió ninguno';

  @override
  String get telemetryDamagedCorrupt =>
      'La grabación está dañada y no se puede leer con seguridad';

  @override
  String telemetryDamagedFileTime(String time) {
    return 'Hora del archivo $time';
  }

  @override
  String get telemetryDelete => 'Eliminar';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return 'Esto elimina $id (hora del archivo $time). No se puede deshacer.';
  }

  @override
  String get telemetryDeleteDamagedTitle => '¿Eliminar esta grabación dañada?';

  @override
  String get telemetryDeleteDamagedTooltip => 'Eliminar grabación dañada';

  @override
  String telemetryDeleteFailed(String reason) {
    return 'La eliminación no terminó: $reason';
  }

  @override
  String get telemetryDeleteNeedsConfirmation =>
      'Confirme esta eliminación primero';

  @override
  String telemetryDeleteSessionBody(String time) {
    return 'Esto elimina la grabación de $time. No se puede deshacer.';
  }

  @override
  String get telemetryDeleteSessionTitle => '¿Eliminar esta grabación local?';

  @override
  String get telemetryDemoData => 'Datos del simulador integrado';

  @override
  String get telemetryDismissNotice => 'Descartar';

  @override
  String get telemetryEndedByBackground =>
      'Se detuvo cuando Telltale pasó a segundo plano';

  @override
  String get telemetryEndedByConfigurationChanged =>
      'La selección de PID cambió';

  @override
  String get telemetryEndedByDisconnect =>
      'Se detuvo cuando se perdió la conexión';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return 'Se alcanzó el límite de $minutes minutos';
  }

  @override
  String get telemetryEndedByLibrarySizeLimit =>
      'El almacenamiento local de grabaciones está lleno';

  @override
  String get telemetryEndedByRecoveredAfterInterruption =>
      'Recuperado tras la última interrupción';

  @override
  String get telemetryEndedBySessionReplacement =>
      'Se sustituyó la sesión de conexión';

  @override
  String get telemetryEndedBySessionSizeLimit =>
      'Esta grabación alcanzó su límite de tamaño';

  @override
  String get telemetryEndedByStorageBackpressure =>
      'El almacenamiento no pudo seguir el ritmo';

  @override
  String get telemetryEndedByStorageFailure => 'Error al guardar';

  @override
  String get telemetryEndedByUser => 'Detenido por usted';

  @override
  String get telemetryExport => 'Exportar';

  @override
  String get telemetryExportCsv => 'Exportar CSV';

  @override
  String telemetryExportFailed(String reason) {
    return 'La exportación no terminó: $reason';
  }

  @override
  String get telemetryExportJson => 'Exportar JSON';

  @override
  String get telemetryExportSheetTitle => 'Exportar una grabación local';

  @override
  String telemetryGapCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count huecos',
      one: '1 hueco',
    );
    return '$_temp0';
  }

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count grupos guardados — reproducción y exportación sin conexión',
      one: '1 grupo guardado — reproducción y exportación sin conexión',
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
      other: '$count grupos más no mostrados',
      one: '1 grupo más no mostrado',
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
    return 'Almacenamiento local: $groups de $groupLimit grupos, $used de $byteLimit MiB';
  }

  @override
  String get telemetryNotConnected => 'Sin conexión';

  @override
  String get telemetryOfflineSampledReplay =>
      'Reproducción muestreada sin conexión';

  @override
  String get telemetryOpenHistory => 'Abrir grabaciones locales';

  @override
  String get telemetryPause => 'Pausar';

  @override
  String get telemetryPendingOwnerRecovery =>
      'Este proceso sigue reteniendo la operación. Si permanece así, cierre Telltale por completo y vuelva a abrirlo';

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetryPlay => 'Reproducir';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return 'Registra solo las señales OBD que usted ha habilitado — sin ubicación, VIN ni datos de cuenta. Las tendencias muestran como máximo $laneLimit señales; una grabación conserva las $activeCount señales habilitadas y añade potencia estimada y caudal de combustible estimado, que se basan en los supuestos del vehículo.';
  }

  @override
  String get telemetryRecorderPhaseAwaitingValues =>
      'Grabando — aún no hay valores';

  @override
  String get telemetryRecorderPhaseCompleted => 'Grabación guardada';

  @override
  String get telemetryRecorderPhaseFailed => 'Error al guardar la grabación';

  @override
  String get telemetryRecorderPhaseFinalizing => 'Guardando la grabación';

  @override
  String get telemetryRecorderPhaseIdle => 'Grabación local en primer plano';

  @override
  String get telemetryRecorderPhasePreparing => 'Preparando para grabar';

  @override
  String get telemetryRecorderPhaseRecording => 'Grabando';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return 'Grabando $duration';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se limpiaron $count archivos sin terminar sin valores válidos',
      one: 'Se limpió 1 archivo sin terminar sin valores válidos',
    );
    return '$_temp0';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos dañados o en conflicto se dejaron sin cambios',
      one: '1 archivo dañado o en conflicto se dejó sin cambios',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryDamagedNote =>
      'El contenido dañado nunca se usa para reproducción ni exportación, y solo se puede eliminar a mano cuando es seguro hacerlo.';

  @override
  String telemetryRecoveryInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se sellaron con seguridad $count grabaciones interrumpidas',
      one: 'Se selló con seguridad 1 grabación interrumpida',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryTitle =>
      'Terminó la comprobación de inicio de las grabaciones';

  @override
  String get telemetryReload => 'Recargar';

  @override
  String telemetryReplayBreakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count interrupciones',
      one: '1 interrupción',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayLoadFailed => 'No se pudo cargar la grabación';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return 'Posición de reproducción $percent%';
  }

  @override
  String telemetryReplaySampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puntos muestreados',
      one: '1 punto muestreado',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayTitle => 'Reproducción de la grabación';

  @override
  String get telemetryReplayUnreadable =>
      'La grabación está dañada o no se puede leer';

  @override
  String get telemetryRestartToRepairSave =>
      'El guardado no terminó — reinicie Telltale para reparar las grabaciones';

  @override
  String get telemetryRestartToRepairStartup =>
      'La limpieza de inicio no terminó — reinicie Telltale para reparar las grabaciones';

  @override
  String get telemetryReturnToTrends => 'Volver a las tendencias';

  @override
  String get telemetryRigData => 'Datos del banco de pruebas';

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetrySessionsDamaged => 'Archivos de grabación dañados';

  @override
  String get telemetrySessionsEmpty =>
      'Aún no hay grabaciones locales\nConéctese y luego inicie la grabación';

  @override
  String get telemetrySessionsLoadFailed => 'No se pudo cargar — reintentar';

  @override
  String get telemetrySessionsReplayable => 'Grabaciones que puede reproducir';

  @override
  String get telemetrySessionsTitle => 'Grabaciones locales';

  @override
  String telemetrySignalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count señales',
      one: '1 señal',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStartBusy =>
      'Otra grabación u operación de archivo no ha terminado';

  @override
  String get telemetryStartCannotCreateFile =>
      'No se pudo crear el archivo de grabación';

  @override
  String get telemetryStartInvalidConfiguration =>
      'Esta selección de PID no se puede grabar con seguridad — revise las definiciones';

  @override
  String get telemetryStartInvalidatedBackground =>
      'Telltale pasó a segundo plano — no se inició ninguna grabación';

  @override
  String get telemetryStartInvalidatedDisconnect =>
      'Se perdió la conexión — no se inició ninguna grabación';

  @override
  String get telemetryStartInvalidatedSessionReplacement =>
      'Se sustituyó la sesión de conexión — no se inició ninguna grabación';

  @override
  String get telemetryStartLibraryByteLimit =>
      'No hay suficiente almacenamiento local para una grabación — exporte o elimine algunas primero';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return 'Las grabaciones locales alcanzaron el límite de $limit — exporte o elimine algunas primero';
  }

  @override
  String get telemetryStartMoving => 'Estacione el vehículo primero';

  @override
  String get telemetryStartNeedsActivePid => 'Habilite al menos un PID primero';

  @override
  String get telemetryStartNeedsConnection =>
      'Conéctese antes de iniciar una grabación';

  @override
  String get telemetryStartNeedsForeground =>
      'Ponga Telltale en primer plano antes de iniciar una grabación';

  @override
  String get telemetryStartRecording => 'Grabación iniciada';

  @override
  String get telemetryStartRecordingButton => 'Iniciar grabación';

  @override
  String get telemetryStartSpeedUnknown =>
      'No se puede confirmar que el vehículo esté detenido — desconecte primero';

  @override
  String get telemetryStartTooManyPids =>
      'La grabación conserva las columnas de potencia estimada y combustible estimado — desactive algunos PID primero';

  @override
  String get telemetryStarting => 'Iniciando';

  @override
  String get telemetryStatusBusError => 'Error de bus';

  @override
  String telemetryStatusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estados',
      one: '1 estado',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStatusFormulaError => 'Error de fórmula';

  @override
  String get telemetryStatusHeaderMismatch =>
      'El encabezado no coincide con este bus';

  @override
  String get telemetryStatusNoAnswer => 'Sin respuesta — se reintentará';

  @override
  String get telemetryStatusStale => 'Los datos están desactualizados';

  @override
  String get telemetryStatusUnsafeServiceRefusal =>
      'No es una consulta de solo lectura — no se envió nada';

  @override
  String get telemetryStatusUnsupported =>
      'El controlador respondió que no es compatible con esto';

  @override
  String get telemetryStopAndSave => 'Detener y guardar';

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
  String get transcriptDelete => 'Eliminar';

  @override
  String get transcriptDeleteBusy =>
      'Otra operación de archivo no ha terminado.';

  @override
  String get transcriptDeleteFailed =>
      'No se pudo eliminar la transcripción de la conexión anterior.';

  @override
  String get transcriptDeleteRefusedBySafety =>
      'La velocidad o el estado de la conexión actuales no permiten eliminar la transcripción.';

  @override
  String get transcriptExport => 'Exportar';

  @override
  String get transcriptExportButton => 'Exportar transcripción';

  @override
  String get transcriptExportExplanation =>
      'Esta conexión conserva la inicialización y el tráfico en bruto más reciente; si una conexión larga pierde el tramo intermedio, el archivo lo indica. Cuando algo no se lee en el vehículo, exportar la transcripción y traerla de vuelta vale mucho más que un solo mensaje en pantalla.';

  @override
  String transcriptExportFailed(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String get transcriptExportWithHex => 'Con hex';

  @override
  String get transcriptNothingToExport => 'No hay transcripción para exportar.';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return 'Quedó a las $timestamp, $size. Sobrevivió a que el sistema cerrara Telltale o a que el teléfono se quedara sin energía.';
  }

  @override
  String get transcriptRecoveredChanged =>
      'La transcripción de la conexión anterior ha cambiado — compruébela de nuevo.';

  @override
  String get transcriptRecoveredTitle =>
      'Transcripción de la conexión anterior';

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
  String get trendAxisNow => 'Ahora';

  @override
  String get trendChooseSignals => 'Elegir señales';

  @override
  String get trendLiveData => 'Datos en vivo';

  @override
  String get trendNoSignalsBody =>
      'Habilite primero en la página PID las señales que desea observar.';

  @override
  String get trendNoSignalsTitle => 'No hay señales de tendencia disponibles';

  @override
  String get trendNoUnits => 'Sin unidades';

  @override
  String trendPickSignalsBody(int limit) {
    return 'Compare hasta $limit señales. Esto no cambia qué PID se sondean.';
  }

  @override
  String get trendPickSignalsTitle => 'Elegir señales de tendencia';

  @override
  String trendRemoveSignal(String name) {
    return 'Quitar $name';
  }

  @override
  String get trendSelectionSaveFailed =>
      'No se pudo guardar la selección de visualización de tendencias';

  @override
  String trendSheetBody(int limit) {
    return 'Elija como máximo $limit. Esto solo cambia el gráfico, no el sondeo de PID ni una grabación en curso.';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return 'Listo · $selected/$limit';
  }

  @override
  String get trendSignalNoLongerActive =>
      'Una de esas señales ya no está en la lista de observación de PID';

  @override
  String get trendSignalsHeading => 'Señales de tendencia';

  @override
  String trendTooManySelected(int limit) {
    return 'Elija como máximo $limit';
  }

  @override
  String trendWindowSemantics(int seconds) {
    return 'Mostrando los últimos $seconds segundos';
  }

  @override
  String get wearBack => 'Atrás';

  @override
  String get wearBatteryVoltageLabel => 'Batería';

  @override
  String get wearBleAdapters => 'Adaptadores BLE';

  @override
  String get wearCancel => 'Cancelar';

  @override
  String get wearConfirmVehicle => 'Confirmar vehículo';

  @override
  String get wearConfirmVehicleAccept => 'Sí, este vehículo';

  @override
  String get wearConfirmVehicleBody =>
      'Una vez confirmado, las consultas de batería de solo lectura de este modelo se sondean durante el resto de esta conexión. Un modelo incorrecto puede devolver un número plausible pero erróneo — cancele si no está seguro.';

  @override
  String wearConnectFailed(String adapter) {
    return 'No se pudo conectar: $adapter';
  }

  @override
  String get wearConnecting => 'Conectando…';

  @override
  String get wearDemoSimulator => 'Simulador Demo';

  @override
  String get wearDisconnect => 'Desconectar';

  @override
  String get wearDisconnectQuestion => '¿Desconectar?';

  @override
  String get wearNoDevicesFound => 'No se encontraron dispositivos';

  @override
  String get wearPermissionBluetooth => 'Bluetooth';

  @override
  String get wearPermissionLocation => 'Ubicación';

  @override
  String get wearScanAgain => 'Reescanear';

  @override
  String get wearScanFailed => 'Error en el escaneo — inténtelo de nuevo';

  @override
  String wearScanPermissionNeeded(String permission) {
    return 'El escaneo necesita el permiso de $permission';
  }

  @override
  String wearScanPermissionPermanentlyDenied(String permission) {
    return 'El permiso de $permission está denegado de forma permanente — actívelo en los ajustes del sistema e inténtelo de nuevo';
  }

  @override
  String get wearScanning => 'Escaneando…';

  @override
  String get telemetryRecorderNotRecording => 'Sin grabar';

  @override
  String get dtcKindStored => 'Almacenado';

  @override
  String get dtcKindPending => 'Pendiente';

  @override
  String get dtcKindPermanent => 'Permanente';

  @override
  String get dtcKindStoredExplanation =>
      'Un fallo confirmado; la lámpara de fallo del panel suele estar encendida.';

  @override
  String get dtcKindPendingExplanation =>
      'Detectado una vez y aún no ha alcanzado el umbral de confirmación.';

  @override
  String get dtcKindPermanentExplanation =>
      'No se puede borrar con un instrumento de diagnóstico. La ECU lo borra ella misma, y solo cuando ha confirmado la reparación.';

  @override
  String get dtcSystemPowertrain => 'Tren motriz';

  @override
  String get dtcSystemChassis => 'Chasis';

  @override
  String get dtcSystemBody => 'Carrocería';

  @override
  String get dtcSystemNetwork => 'Red';

  @override
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions =>
      'Dosificación de combustible y aire, y controles auxiliares de emisiones';

  @override
  String get dtcSubsystemFuelAirMetering =>
      'Dosificación de combustible y aire';

  @override
  String get dtcSubsystemFuelAirMeteringInjectorCircuit =>
      'Dosificación de combustible y aire (circuito del inyector)';

  @override
  String get dtcSubsystemIgnitionOrMisfire =>
      'Sistema de encendido o fallos de encendido';

  @override
  String get dtcSubsystemAuxiliaryEmissionControls =>
      'Controles auxiliares de emisiones';

  @override
  String get dtcSubsystemSpeedAndIdleControl =>
      'Sistema de control de velocidad del vehículo y de ralentí';

  @override
  String get dtcSubsystemComputerOutputCircuit =>
      'Circuito de salida de la computadora';

  @override
  String get dtcSubsystemTransmission => 'Transmisión';

  @override
  String get dtcSubsystemControlModuleSignals =>
      'Módulos de control, señales de entrada y salida';

  @override
  String get dtcDescriptionB0001 =>
      'Fallo del control de despliegue del airbag del conductor';

  @override
  String get dtcDescriptionP0011 =>
      'Posición del árbol de levas A — avance excesivo de la sincronización o rendimiento del sistema (banco 1)';

  @override
  String get dtcDescriptionP0014 =>
      'Posición del árbol de levas B — avance excesivo de la sincronización o rendimiento del sistema (banco 1)';

  @override
  String get dtcDescriptionP0016 =>
      'Correlación entre la posición del cigüeñal y la del árbol de levas (banco 1, sensor A)';

  @override
  String get dtcDescriptionP0087 =>
      'Presión del rail/sistema de combustible demasiado baja';

  @override
  String get dtcDescriptionP0088 =>
      'Presión del rail/sistema de combustible demasiado alta';

  @override
  String get dtcDescriptionP0100 =>
      'Mal funcionamiento del circuito del sensor de masa de aire (MAF)';

  @override
  String get dtcDescriptionP0101 =>
      'Problema de rango/rendimiento del sensor de masa de aire';

  @override
  String get dtcDescriptionP0102 =>
      'Entrada baja del circuito del sensor de masa de aire';

  @override
  String get dtcDescriptionP0103 =>
      'Entrada alta del circuito del sensor de masa de aire';

  @override
  String get dtcDescriptionP0105 =>
      'Mal funcionamiento del circuito del sensor de presión absoluta del colector/presión barométrica';

  @override
  String get dtcDescriptionP0106 =>
      'Problema de rango/rendimiento del sensor de presión absoluta del colector';

  @override
  String get dtcDescriptionP0107 =>
      'Entrada baja del circuito del sensor de presión absoluta del colector';

  @override
  String get dtcDescriptionP0108 =>
      'Entrada alta del circuito del sensor de presión absoluta del colector';

  @override
  String get dtcDescriptionP0110 =>
      'Mal funcionamiento del circuito del sensor de temperatura del aire de admisión';

  @override
  String get dtcDescriptionP0111 =>
      'Problema de rango/rendimiento del sensor de temperatura del aire de admisión';

  @override
  String get dtcDescriptionP0112 =>
      'Entrada baja del circuito del sensor de temperatura del aire de admisión';

  @override
  String get dtcDescriptionP0113 =>
      'Entrada alta del circuito del sensor de temperatura del aire de admisión';

  @override
  String get dtcDescriptionP0115 =>
      'Mal funcionamiento del circuito del sensor de temperatura del refrigerante del motor';

  @override
  String get dtcDescriptionP0116 =>
      'Problema de rango/rendimiento del sensor de temperatura del refrigerante del motor';

  @override
  String get dtcDescriptionP0117 =>
      'Entrada baja del circuito del sensor de temperatura del refrigerante del motor';

  @override
  String get dtcDescriptionP0118 =>
      'Entrada alta del circuito del sensor de temperatura del refrigerante del motor';

  @override
  String get dtcDescriptionP0120 =>
      'Mal funcionamiento del circuito del sensor de posición del acelerador';

  @override
  String get dtcDescriptionP0121 =>
      'Problema de rango/rendimiento del sensor de posición del acelerador';

  @override
  String get dtcDescriptionP0122 =>
      'Entrada baja del circuito del sensor de posición del acelerador';

  @override
  String get dtcDescriptionP0123 =>
      'Entrada alta del circuito del sensor de posición del acelerador';

  @override
  String get dtcDescriptionP0125 =>
      'Temperatura del refrigerante insuficiente para el control de combustible en lazo cerrado';

  @override
  String get dtcDescriptionP0128 =>
      'Temperatura del refrigerante por debajo de la temperatura de regulación del termostato';

  @override
  String get dtcDescriptionP0130 =>
      'Mal funcionamiento del circuito del sensor de oxígeno (banco 1, sensor 1)';

  @override
  String get dtcDescriptionP0131 =>
      'Voltaje bajo del circuito del sensor de oxígeno (banco 1, sensor 1)';

  @override
  String get dtcDescriptionP0132 =>
      'Voltaje alto del circuito del sensor de oxígeno (banco 1, sensor 1)';

  @override
  String get dtcDescriptionP0133 =>
      'Respuesta lenta del circuito del sensor de oxígeno (banco 1, sensor 1)';

  @override
  String get dtcDescriptionP0134 =>
      'Sin actividad detectada en el circuito del sensor de oxígeno (banco 1, sensor 1)';

  @override
  String get dtcDescriptionP0135 =>
      'Mal funcionamiento del circuito del calentador del sensor de oxígeno (banco 1, sensor 1)';

  @override
  String get dtcDescriptionP0136 =>
      'Mal funcionamiento del circuito del sensor de oxígeno (banco 1, sensor 2)';

  @override
  String get dtcDescriptionP0137 =>
      'Voltaje bajo del circuito del sensor de oxígeno (banco 1, sensor 2)';

  @override
  String get dtcDescriptionP0138 =>
      'Voltaje alto del circuito del sensor de oxígeno (banco 1, sensor 2)';

  @override
  String get dtcDescriptionP0140 =>
      'Sin actividad detectada en el circuito del sensor de oxígeno (banco 1, sensor 2)';

  @override
  String get dtcDescriptionP0141 =>
      'Mal funcionamiento del circuito del calentador del sensor de oxígeno (banco 1, sensor 2)';

  @override
  String get dtcDescriptionP0150 =>
      'Mal funcionamiento del circuito del sensor de oxígeno (banco 2, sensor 1)';

  @override
  String get dtcDescriptionP0155 =>
      'Mal funcionamiento del circuito del calentador del sensor de oxígeno (banco 2, sensor 1)';

  @override
  String get dtcDescriptionP0156 =>
      'Mal funcionamiento del circuito del sensor de oxígeno (banco 2, sensor 2)';

  @override
  String get dtcDescriptionP0161 =>
      'Mal funcionamiento del circuito del calentador del sensor de oxígeno (banco 2, sensor 2)';

  @override
  String get dtcDescriptionP0170 =>
      'Mal funcionamiento del ajuste de combustible (banco 1)';

  @override
  String get dtcDescriptionP0171 => 'Sistema demasiado pobre (banco 1)';

  @override
  String get dtcDescriptionP0172 => 'Sistema demasiado rico (banco 1)';

  @override
  String get dtcDescriptionP0173 =>
      'Mal funcionamiento del ajuste de combustible (banco 2)';

  @override
  String get dtcDescriptionP0174 => 'Sistema demasiado pobre (banco 2)';

  @override
  String get dtcDescriptionP0175 => 'Sistema demasiado rico (banco 2)';

  @override
  String get dtcDescriptionP0190 =>
      'Mal funcionamiento del circuito del sensor de presión del rail de combustible';

  @override
  String get dtcDescriptionP0201 =>
      'Mal funcionamiento o circuito abierto del inyector — cilindro 1';

  @override
  String get dtcDescriptionP0202 =>
      'Mal funcionamiento o circuito abierto del inyector — cilindro 2';

  @override
  String get dtcDescriptionP0203 =>
      'Mal funcionamiento o circuito abierto del inyector — cilindro 3';

  @override
  String get dtcDescriptionP0204 =>
      'Mal funcionamiento o circuito abierto del inyector — cilindro 4';

  @override
  String get dtcDescriptionP0217 => 'Condición de sobretemperatura del motor';

  @override
  String get dtcDescriptionP0221 =>
      'Problema de rango/rendimiento del sensor B de posición del acelerador/pedal';

  @override
  String get dtcDescriptionP0222 =>
      'Entrada baja del circuito del sensor B de posición del acelerador/pedal';

  @override
  String get dtcDescriptionP0223 =>
      'Entrada alta del circuito del sensor B de posición del acelerador/pedal';

  @override
  String get dtcDescriptionP0234 =>
      'Condición de sobrealimentación excesiva del turbocompresor/compresor';

  @override
  String get dtcDescriptionP0299 =>
      'Condición de subalimentación del turbocompresor/compresor A';

  @override
  String get dtcDescriptionP0300 =>
      'Fallos de encendido aleatorios o en varios cilindros detectados';

  @override
  String get dtcDescriptionP0301 =>
      'Fallos de encendido detectados en el cilindro 1';

  @override
  String get dtcDescriptionP0302 =>
      'Fallos de encendido detectados en el cilindro 2';

  @override
  String get dtcDescriptionP0303 =>
      'Fallos de encendido detectados en el cilindro 3';

  @override
  String get dtcDescriptionP0304 =>
      'Fallos de encendido detectados en el cilindro 4';

  @override
  String get dtcDescriptionP0305 =>
      'Fallos de encendido detectados en el cilindro 5';

  @override
  String get dtcDescriptionP0306 =>
      'Fallos de encendido detectados en el cilindro 6';

  @override
  String get dtcDescriptionP0307 =>
      'Fallos de encendido detectados en el cilindro 7';

  @override
  String get dtcDescriptionP0308 =>
      'Fallos de encendido detectados en el cilindro 8';

  @override
  String get dtcDescriptionP0316 =>
      'Fallos de encendido detectados inmediatamente después del arranque';

  @override
  String get dtcDescriptionP0325 =>
      'Mal funcionamiento del circuito del sensor de detonación (banco 1)';

  @override
  String get dtcDescriptionP0326 =>
      'Problema de rango/rendimiento del sensor de detonación (banco 1)';

  @override
  String get dtcDescriptionP0327 =>
      'Entrada baja del circuito del sensor de detonación (banco 1)';

  @override
  String get dtcDescriptionP0328 =>
      'Entrada alta del circuito del sensor de detonación (banco 1)';

  @override
  String get dtcDescriptionP0330 =>
      'Mal funcionamiento del circuito del sensor de detonación (banco 2)';

  @override
  String get dtcDescriptionP0335 =>
      'Mal funcionamiento del circuito del sensor de posición del cigüeñal';

  @override
  String get dtcDescriptionP0336 =>
      'Problema de rango/rendimiento del sensor de posición del cigüeñal';

  @override
  String get dtcDescriptionP0340 =>
      'Mal funcionamiento del circuito del sensor de posición del árbol de levas';

  @override
  String get dtcDescriptionP0341 =>
      'Problema de rango/rendimiento del sensor de posición del árbol de levas';

  @override
  String get dtcDescriptionP0351 =>
      'Mal funcionamiento del circuito primario/secundario de la bobina de encendido A';

  @override
  String get dtcDescriptionP0352 =>
      'Mal funcionamiento del circuito primario/secundario de la bobina de encendido B';

  @override
  String get dtcDescriptionP0353 =>
      'Mal funcionamiento del circuito primario/secundario de la bobina de encendido C';

  @override
  String get dtcDescriptionP0354 =>
      'Mal funcionamiento del circuito primario/secundario de la bobina de encendido D';

  @override
  String get dtcDescriptionP0355 =>
      'Mal funcionamiento del circuito primario/secundario de la bobina de encendido E';

  @override
  String get dtcDescriptionP0356 =>
      'Mal funcionamiento del circuito primario/secundario de la bobina de encendido F';

  @override
  String get dtcDescriptionP0400 =>
      'Mal funcionamiento del flujo de recirculación de gases de escape (EGR)';

  @override
  String get dtcDescriptionP0401 =>
      'Flujo insuficiente de recirculación de gases de escape (EGR)';

  @override
  String get dtcDescriptionP0402 =>
      'Flujo excesivo de recirculación de gases de escape (EGR)';

  @override
  String get dtcDescriptionP0403 =>
      'Mal funcionamiento del circuito de control de recirculación de gases de escape (EGR)';

  @override
  String get dtcDescriptionP0404 =>
      'Problema de rango/rendimiento del circuito de control de recirculación de gases de escape (EGR)';

  @override
  String get dtcDescriptionP0410 =>
      'Mal funcionamiento del sistema de inyección de aire secundario';

  @override
  String get dtcDescriptionP0411 =>
      'Flujo incorrecto detectado en el sistema de inyección de aire secundario';

  @override
  String get dtcDescriptionP0412 =>
      'Mal funcionamiento del circuito de la válvula de conmutación A del sistema de inyección de aire secundario';

  @override
  String get dtcDescriptionP0420 =>
      'Eficiencia del sistema del catalizador por debajo del umbral (banco 1)';

  @override
  String get dtcDescriptionP0430 =>
      'Eficiencia del sistema del catalizador por debajo del umbral (banco 2)';

  @override
  String get dtcDescriptionP0440 =>
      'Mal funcionamiento del sistema de control de emisiones evaporativas';

  @override
  String get dtcDescriptionP0441 =>
      'Flujo de purga incorrecto del sistema de emisiones evaporativas';

  @override
  String get dtcDescriptionP0442 =>
      'Fuga detectada en el sistema de emisiones evaporativas (fuga pequeña)';

  @override
  String get dtcDescriptionP0443 =>
      'Mal funcionamiento del circuito de la válvula de control de purga del sistema de emisiones evaporativas';

  @override
  String get dtcDescriptionP0446 =>
      'Mal funcionamiento del circuito de control de ventilación del sistema de emisiones evaporativas';

  @override
  String get dtcDescriptionP0447 =>
      'Circuito de control de ventilación del sistema de emisiones evaporativas abierto';

  @override
  String get dtcDescriptionP0449 =>
      'Mal funcionamiento del circuito de la válvula/solenoide de ventilación del sistema de emisiones evaporativas';

  @override
  String get dtcDescriptionP0451 =>
      'Problema de rango/rendimiento del sensor de presión del sistema de emisiones evaporativas';

  @override
  String get dtcDescriptionP0452 =>
      'Entrada baja del circuito del sensor de presión del sistema de emisiones evaporativas';

  @override
  String get dtcDescriptionP0453 =>
      'Entrada alta del circuito del sensor de presión del sistema de emisiones evaporativas';

  @override
  String get dtcDescriptionP0455 =>
      'Fuga detectada en el sistema de emisiones evaporativas (fuga grande)';

  @override
  String get dtcDescriptionP0456 =>
      'Fuga detectada en el sistema de emisiones evaporativas (fuga muy pequeña)';

  @override
  String get dtcDescriptionP0480 =>
      'Mal funcionamiento del circuito de control del ventilador de refrigeración 1';

  @override
  String get dtcDescriptionP0500 =>
      'Mal funcionamiento del sensor de velocidad del vehículo';

  @override
  String get dtcDescriptionP0505 =>
      'Mal funcionamiento del sistema de control de ralentí';

  @override
  String get dtcDescriptionP0506 =>
      'RPM del sistema de control de ralentí más bajas de lo esperado';

  @override
  String get dtcDescriptionP0507 =>
      'RPM del sistema de control de ralentí más altas de lo esperado';

  @override
  String get dtcDescriptionP0508 =>
      'Circuito del sistema de control de ralentí bajo';

  @override
  String get dtcDescriptionP0509 =>
      'Circuito del sistema de control de ralentí alto';

  @override
  String get dtcDescriptionP0560 =>
      'Mal funcionamiento del voltaje del sistema';

  @override
  String get dtcDescriptionP0562 => 'Voltaje del sistema bajo';

  @override
  String get dtcDescriptionP0563 => 'Voltaje del sistema alto';

  @override
  String get dtcDescriptionP0603 =>
      'Error de la memoria de retención (KAM) del módulo de control interno';

  @override
  String get dtcDescriptionP0605 =>
      'Error de memoria de solo lectura (ROM) del módulo de control interno';

  @override
  String get dtcDescriptionP0606 => 'Fallo del procesador ECM/PCM';

  @override
  String get dtcDescriptionP0700 =>
      'El módulo de control de la transmisión solicitó la lámpara de fallo — el código de fallo en sí está en el módulo de transmisión y debe leerse por separado';

  @override
  String get dtcDescriptionP0701 =>
      'Problema de rango/rendimiento del sistema de control de la transmisión';

  @override
  String get dtcDescriptionP0702 =>
      'Fallo eléctrico del sistema de control de la transmisión';

  @override
  String get dtcDescriptionP0705 =>
      'Mal funcionamiento del circuito del sensor de rango de la transmisión';

  @override
  String get dtcDescriptionP0715 =>
      'Mal funcionamiento del circuito del sensor de velocidad de entrada/turbina';

  @override
  String get dtcDescriptionP0720 =>
      'Mal funcionamiento del circuito del sensor de velocidad de salida';

  @override
  String get dtcDescriptionP0730 => 'Relación de marcha incorrecta';

  @override
  String get dtcDescriptionP0740 =>
      'Mal funcionamiento del circuito del embrague del convertidor de par';

  @override
  String get dtcDescriptionP0741 =>
      'Embrague del convertidor de par bloqueado en desactivado';

  @override
  String get dtcDescriptionP0750 =>
      'Mal funcionamiento del solenoide de cambio A';

  @override
  String get dtcDescriptionP0755 =>
      'Mal funcionamiento del solenoide de cambio B';

  @override
  String get dtcDescriptionP2135 =>
      'Correlación de voltaje de los sensores de posición del acelerador A/B';

  @override
  String get dtcDescriptionU0100 => 'Comunicación perdida con ECM/PCM';

  @override
  String get dtcDescriptionU0101 =>
      'Comunicación perdida con el módulo de control de la transmisión';

  @override
  String get dtcDescriptionU0121 =>
      'Comunicación perdida con el módulo de control ABS';

  @override
  String get dtcDescriptionU0140 =>
      'Comunicación perdida con el módulo de control de la carrocería';

  @override
  String get dtcDescriptionU0155 =>
      'Comunicación perdida con el módulo de control del panel de instrumentos';

  @override
  String get gaugeSkinCluster => 'Cuadro';

  @override
  String get gaugeSkinClusterDescription =>
      'Se parece a un cuadro de instrumentos de fábrica. Aguja, esfera de 270 grados, cara hundida.';

  @override
  String get gaugeSkinMinimal => 'Minimal';

  @override
  String get gaugeSkinMinimalDescription =>
      'Medio arco, sin aguja, sin marcas. El número es lo que se lee, no el movimiento.';

  @override
  String get gaugeSkinTrack => 'Pista';

  @override
  String get gaugeSkinTrackDescription =>
      'Barra segmentada, sin suavizado. El valor cae donde cae, sin nada intermedio.';

  @override
  String get gaugeSkinClassic => 'Clásico';

  @override
  String get gaugeSkinClassicDescription =>
      'Esfera impresa, números en todo el círculo, una aguja que se asienta despacio como un reloj mecánico.';

  @override
  String get gaugeSkinNight => 'Noche';

  @override
  String get gaugeSkinNightDescription =>
      'Para conducir de noche. Bajo brillo, un arco poco profundo, sin animación: la menor atención posible.';

  @override
  String get derivedAirflowSourceMaf => 'Sensor MAF';

  @override
  String get derivedAirflowSourceSpeedDensity =>
      'Estimación por velocidad-densidad';

  @override
  String get derivedAirflowSourceUnavailable => 'Masa de aire no disponible';

  @override
  String get derivedFuelSourceStoichiometric => 'Estimación estequiométrica';

  @override
  String get derivedFuelSourceUnavailable =>
      'Caudal de combustible no disponible';

  @override
  String get telemetrySourceDemo => 'Simulador integrado';

  @override
  String get telemetrySourceRig => 'Banco de prueba';

  @override
  String get telemetrySourceFieldApp => 'Conexión de la app de campo';

  @override
  String get fuelTypeGasoline => 'Gasolina';

  @override
  String get fuelTypeDiesel => 'Diésel';

  @override
  String get fuelTypeLpg => 'LPG';

  @override
  String get fuelTypeEthanolE85 => 'Etanol E85';

  @override
  String get drivetrainFwd => 'Tracción delantera';

  @override
  String get drivetrainRwd => 'Tracción trasera';

  @override
  String get drivetrainAwd => 'Tracción total';

  @override
  String get assumptionFieldMass => 'Masa';

  @override
  String get assumptionFieldDragCoefficient => 'Cd';

  @override
  String get assumptionFieldFrontalArea => 'Área frontal';

  @override
  String get assumptionFieldRollingResistance => 'Resistencia a la rodadura';

  @override
  String get assumptionFieldDrivetrainEfficiency =>
      'Eficiencia del tren de transmisión';

  @override
  String get assumptionFieldFuelType => 'Combustible';

  @override
  String get assumptionFieldStoichAfr => 'AFR';

  @override
  String get assumptionFieldFuelDensity => 'Densidad';

  @override
  String get assumptionFieldDisplacement => 'Cilindrada';

  @override
  String get assumptionFieldVolumetricEfficiency => 'VE';

  @override
  String get vehicleFieldOriginGenericDefault =>
      'valor predeterminado genérico';

  @override
  String get vehicleFieldOriginUserEntered => 'introducido por usted';

  @override
  String get vehicleFieldOriginOfficialRegistry => 'registro oficial';

  @override
  String get vehicleFieldOriginManufacturerPublication =>
      'datos del fabricante';

  @override
  String get vehicleFieldOriginScientificModel => 'coeficiente del modelo';

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
      'L/h = (MAF g/s) / (AFR × densidad del combustible g/L) × 3600; MAF es PID 0110 o velocidad-densidad (RPM × MAP × cilindrada × VE / T_K); L/100km = (L/h) / speed_kmh × 100';

  @override
  String get datumAssumptionsFromRecording =>
      'La estimación usa los ajustes del vehículo tal como estaban cuando se grabó esto.';

  @override
  String adapterConcernFirmwareNeverReleasedSummary(String version) {
    return 'Informa firmware v$version, que nunca se publicó';
  }

  @override
  String get adapterConcernFirmwareNeverReleasedDetail =>
      'Elm Electronics nunca publicó esta versión, así que el firmware de este adaptador no es el que afirma. Muchos de estos siguen funcionando — pero su descripción de sí mismo no es de fiar, y conviene sospechar de él primero cuando algo no se lea.';

  @override
  String adapterConcernPpsRefusedSummary(String version) {
    return 'Afirma v$version, pero no conoce ATPPS, que v1.1 sí tenía';
  }

  @override
  String get adapterConcernPpsRefusedDetail =>
      'El resumen de parámetros programables (ATPPS) existe desde ELM327 v1.1, y hasta adaptadores de gama alta como OBDLink lo admiten. La versión que afirma y los comandos que realmente implementa no coinciden.';

  @override
  String get adapterConcernNoIdentitySummary =>
      'No responde a AT@1, el comando de identidad del dispositivo de la primera versión';

  @override
  String get adapterConcernNoIdentityDetail =>
      'Este comando existe desde ELM327 v1.0. No responderlo significa que este chip implementa un conjunto de comandos menor que cualquier firmware oficial.';

  @override
  String get telemetryReplaySampled =>
      'La vista previa está muestreada; la exportación conserva cada evento registrado.';

  @override
  String get telemetryExportDisclosure =>
      'La exportación contiene nombres de señales, valores, tiempos de observación y de origen, tipo de transporte, protocolo, etiquetas/unidades/fórmulas de PID congeladas y los supuestos de estimación (masa, resistencia aerodinámica, cilindrada, combustible y parámetros similares). El JSON también puede contener sus propias etiquetas, unidades, fórmulas y definiciones congeladas completas personalizadas. La exportación no contiene el VIN, GPS, una cuenta, la dirección del adaptador, el perfil completo del vehículo ni el tráfico de diagnóstico en bruto.';

  @override
  String get connectTransportCancelled =>
      'El intento de conexión se detuvo antes de terminar.';

  @override
  String get connectTransportWifiRouteNoNetwork =>
      'El teléfono no está en ninguna red Wi-Fi, así que no hay ruta hacia el adaptador. Conéctese al punto de acceso Wi-Fi del adaptador y vuelva a intentarlo.';

  @override
  String get connectTransportWifiRouteAmbiguous =>
      'El teléfono está en más de una red Wi-Fi y ninguna es claramente la del adaptador, así que no se eligió ninguna. Desconecte las que no sean la del adaptador y vuelva a intentarlo.';

  @override
  String get connectTransportWifiRouteRefused =>
      'El sistema se negó a enviar esta conexión por Wi-Fi. El teléfono está en Wi-Fi; no se permitió usarlo para esto.';

  @override
  String get connectTransportWifiRouteTimeout =>
      'El sistema no respondió a la solicitud de enviar esta conexión por Wi-Fi. Espere unos segundos y vuelva a intentarlo.';

  @override
  String get connectTransportWifiRouteUnclassified =>
      'La conexión no pudo enviarse por Wi-Fi, por un motivo que el sistema no nombró. El error completo se conserva en el registro de abajo.';

  @override
  String get connectTransportWifiHostUnreachable =>
      'Nada respondió en esa dirección. Compruebe que el teléfono está en el punto de acceso Wi-Fi del adaptador; si el sistema preguntó si permanecer conectado sin internet, elija permanecer. Apagar los datos móviles también puede ayudar.';

  @override
  String get connectTransportWifiConnectTimeout =>
      'Nada respondió a tiempo en esa dirección.';

  @override
  String get connectTransportWifiRouteRestoreFailed =>
      'La conexión funcionó, pero no se pudo restaurar el enrutamiento de red del teléfono, así que se cortó la conexión en lugar de dejarla alterada. Reinicie la app y vuelva a intentarlo.';

  @override
  String get connectTransportBleLinkFailed =>
      'No se pudo conectar al adaptador. Compruebe que tiene alimentación y está dentro del alcance.';

  @override
  String get connectTransportBleNoSerialCharacteristic =>
      'El dispositivo se conectó, pero no se encontró ningún puerto serie en él, así que puede que no sea un adaptador ELM327.';

  @override
  String get connectTransportClassicAllTiersRefused =>
      'No se pudo conectar al adaptador. Emparéjelo primero en los ajustes Bluetooth del sistema y compruebe que está enchufado en el conector OBD con el encendido activado.';

  @override
  String get connectTransportClassicConnectTimeout =>
      'La conexión al adaptador agotó el tiempo de espera. Puede que aún esté respondiendo: espere unos segundos en lugar de reintentar de inmediato.';

  @override
  String get connectTransportSerialPortOpenFailed =>
      'No se pudo abrir el puerto serie. Compruebe que el sistema ha creado uno para este adaptador (COMx en Windows, /dev/rfcomm* en Linux) y que el encendido está activado.';

  @override
  String get connectTransportSerialDroppedOnOpen =>
      'El puerto serie se abrió y se cerró de inmediato.';

  @override
  String get settingsManualCommandNotConnected =>
      'No hay nada conectado, así que el comando no se envió.';

  @override
  String get settingsManualCommandLinkDropped =>
      'La conexión con el adaptador se cortó mientras este comando estaba en curso, así que nada lo respondió. No se sabe si el adaptador recibió el comando.';

  @override
  String get settingsManualCommandDisconnectedByApp =>
      'La app cerró la conexión mientras este comando estaba en curso, así que nada lo respondió. No hay nada malo en el adaptador ni en el vehículo.';

  @override
  String get settingsManualCommandAdapterSilentOnResync =>
      'Las respuestas del adaptador se habían desincronizado de los comandos enviados, y no respondió a la comprobación que las habría vuelto a sincronizar, así que se cortó la conexión. Conéctese de nuevo antes de reintentar.';

  @override
  String get settingsManualCommandLinkStoppedResponding =>
      'No llegó nada del adaptador el tiempo suficiente como para cortar la conexión. Puede que aún tenga alimentación; lo que se sabe es el silencio.';

  @override
  String get settingsManualCommandWriteFailed =>
      'El comando no pudo entregarse a la conexión del adaptador. No se sabe cuánto de él llegó al adaptador.';

  @override
  String get settingsManualCommandTimedOut =>
      'No llegó ninguna respuesta antes del límite de tiempo. Confirme que el adaptador está conectado y el encendido activado.';

  @override
  String get settingsManualCommandOperationRetired =>
      'Esta sesión ha terminado o pasó a segundo plano, así que el comando no se envió.';

  @override
  String get settingsManualCommandRequestUnaddressable =>
      'Esta solicitud no puede dirigirse en el bus que usa este vehículo, así que no se envió. Volver a intentarlo no lo cambiará.';

  @override
  String get commandFailureBusJ1939 =>
      'Este bus es SAE J1939 (vehículos comerciales pesados y maquinaria), no el protocolo de diagnóstico OBD2 que lee esta app, así que esta consulta no puede leerse.';

  @override
  String commandFailureUserCanFramingUnknown(
    String protocol,
    String parameter,
  ) {
    return 'Este adaptador está configurado en el protocolo CAN definido por el usuario $protocol, cuyo encuadre lo decide $parameter. El adaptador no informó ese ajuste, así que no se puede confirmar el formato del bus y esta consulta no puede decodificarse de forma segura.';
  }

  @override
  String get commandFailureBusUndetermined =>
      'El protocolo del bus del vehículo aún no está determinado, así que esta consulta no puede decodificarse de forma segura. Vuelva a conectarse.';

  @override
  String get settingsManualCommandCustomFlowControlRejected =>
      'El adaptador rechazó un comando de control de flujo personalizado, así que el modo solicitado no se aplicó y no se produjo ninguna medición.';

  @override
  String get settingsManualCommandFlowControlRestoreFailed =>
      'El adaptador se negó a restaurar el control de flujo predeterminado (ATFCSM0), así que el sondeo se detiene hasta que se vuelva a conectar.';

  @override
  String get settingsManualCommandExtendedAddressingUnavailable =>
      'El direccionamiento extendido no está disponible en esta ruta ELM327.';

  @override
  String get settingsManualCommandRawIsoTpModeUnavailable =>
      'El reensamblado ISO-TP visible para el host no está disponible en esta ruta ELM327.';

  @override
  String get settingsManualCommandCanPriorityUnavailable =>
      'La programación de prioridad CAN no está disponible en esta ruta ELM327.';

  @override
  String get settingsManualCommandCanReceiveFilterUnavailable =>
      'El filtrado de recepción CAN no está disponible en esta ruta ELM327.';

  @override
  String get settingsManualCommandHeaderRestoreFailed =>
      'El adaptador se negó a restaurar el encabezado (ATSH), así que el sondeo se detiene hasta que se vuelva a conectar.';

  @override
  String get manualCommandRefusedEmpty =>
      'No se escribió nada, así que no se envió nada.';

  @override
  String get manualCommandRefusedMoreThanOneCommand =>
      'Este texto lleva un salto de línea u otro carácter de control, lo que envía más de un comando a la vez. El adaptador separa los comandos por salto de línea, así que el segundo omitiría todas las comprobaciones hechas aquí — incluida la que se niega a borrar códigos de fallo. Envíe un comando cada vez.';

  @override
  String manualCommandRefusedAdapterStateWouldChange(
    Object command,
    Object allowed,
  ) {
    return 'Este cuadro acepta preguntas, no comandos que cambien lo que es el adaptador. “$command” cambiaría el estado del adaptador mientras el modelo que tiene la app de él seguiría igual — las lecturas posteriores podrían venir de un controlador distinto, sin nada en pantalla que lo diga.\nConsultas que puede enviar: $allowed.';
  }

  @override
  String get manualCommandRefusedClearHasItsOwnButton =>
      'Para borrar códigos de fallo, use el botón Borrar en la pantalla de códigos de fallo. Enviado desde aquí omitiría la confirmación, la comprobación de cobertura y la validación de la respuesta, y solo llegaría al controlador actualmente seleccionado.';

  @override
  String manualCommandRefusedCharactersNoObdCommandHas(Object command) {
    return 'El comando “$command” contiene caracteres que un comando OBD nunca tiene. Este cuadro admite códigos de servicio y parámetros hexadecimales — 0100, 03, 2211A6 — o una consulta al adaptador que empiece por AT.';
  }

  @override
  String manualCommandRefusedNotAReadOnlyQuery(Object command, Object allowed) {
    return '“$command” no es un comando que este cuadro conozca. Admite consultas de solo lectura (Mode $allowed) y consultas al adaptador.';
  }

  @override
  String commandFailureQueryHeaderRefused(Object header) {
    return 'El adaptador se negó a dirigir esta solicitud al controlador $header, así que no se envió. Dejada en la dirección que el adaptador tenga realmente, la respuesta habría venido de un controlador que nadie preguntó.';
  }

  @override
  String commandFailureWholeVehicleHeaderRefused(Object address) {
    return 'El adaptador se negó a cambiar a la dirección $address, que es por la que debe salir una pregunta hecha a todo el vehículo. Sin ella, las respuestas no pueden emparejarse con los controladores que las enviaron, así que no se hizo la solicitud.';
  }

  @override
  String commandFailureLegacyScanWouldBePartial(Object installed) {
    return 'Este vehículo usa un bus antiguo sin una dirección estándar que alcance a todos los controladores, y el adaptador está configurado actualmente en el controlador $installed. Un escaneo habría cubierto solo ese controlador mientras se presentaba como de todo el vehículo, así que no se envió. Vuelva a conectarse y escanee de nuevo.';
  }

  @override
  String get pidFormulaEmpty => 'La fórmula está vacía.';

  @override
  String get pidFormulaEmptySubExpression =>
      'Parte de la fórmula está vacía: un operador sin nada después, o paréntesis sin nada dentro.';

  @override
  String get pidFormulaUnbalancedParentheses =>
      'Los paréntesis no coinciden: cada ( necesita un ) de cierre.';

  @override
  String pidFormulaUnparsableTerm(String term) {
    return '“$term” no es un número, un operador ni un nombre que este editor entienda.';
  }

  @override
  String get pidFormulaFunctionNestingTooDeep =>
      'ABS(), LOG10(), LOG() y SQRT() están anidados demasiado profundamente para evaluarlos. Simplifique la fórmula.';

  @override
  String get pidFormulaParenthesisNestingTooDeep =>
      'Los paréntesis están anidados demasiado profundamente para evaluarlos. Simplifique la fórmula.';

  @override
  String get pidFormulaDivisionByZero => 'La fórmula divide entre cero.';

  @override
  String get pidFormulaModuloByZero => 'La fórmula toma un resto módulo cero.';

  @override
  String pidFormulaLog10NonPositiveArgument(double argument) {
    return 'LOG10 necesita un argumento mayor que 0, y este resultó ser $argument.';
  }

  @override
  String pidFormulaLogNonPositiveArgument(double argument) {
    return 'LOG necesita un argumento mayor que 0, y este resultó ser $argument.';
  }

  @override
  String pidFormulaSqrtNegativeArgument(double argument) {
    return 'SQRT necesita un argumento de 0 o mayor, y este resultó ser $argument.';
  }

  @override
  String get pidFormulaResultNotFinite =>
      'La aritmética no produjo un número usable, así que no hay lectura que mostrar.';

  @override
  String pidFormulaByteBeyondResponse(String letter, int count) {
    return 'La fórmula se refiere al byte $letter, pero la respuesta solo trajo $count bytes.';
  }

  @override
  String get pidFormulaBaroControllerUnknown =>
      'BARO no puede usarse aquí, porque no se sabe de qué controlador es la presión ambiente.';

  @override
  String get pidFormulaBaroTwoDefinitions =>
      'Dos definiciones suministran ambas la presión ambiente, así que el valor podría ser cualquiera de las dos y no se puede usar ninguna. Quite uno de los indicadores que miden la presión ambiente.';

  @override
  String get pidFormulaBaroNotYetMeasured =>
      'Aún no se ha leído la presión ambiente, así que esto no puede calcularse.';

  @override
  String get pidFormulaBaroMeasurementStale =>
      'La lectura de presión ambiente está desactualizada, así que esto no puede calcularse.';

  @override
  String get pidFormulaBaroParenFormUnsupported =>
      'BARO() es el barómetro de Android / baro de la ECU en psi, que este dialecto no implementa. Use BARO sin paréntesis para la presión ambiental en caché.';

  @override
  String get pidFormulaInt16Unclaimed =>
      'Este dialecto no atribuye un significado a INT16: la wiki dice que puede sustituir (A*255)+B, que no es (A*256)+B. Escriba una de esas identidades de forma explícita.';

  @override
  String pidFormulaTimeWindowUnsupported(String term) {
    return '$term es una función Torque de retardo, promedio o totalizer que este dialecto no implementa, así que no se puede evaluar aquí. No es 0 y no es MIN ni MAX.';
  }

  @override
  String pidFormulaDependencyControllerUnknown(String reference) {
    return '$reference no puede resolverse aquí, porque no se sabe a qué controlador pertenece ese PID.';
  }

  @override
  String pidFormulaDependencyTwoDefinitions(String key) {
    return 'Dos definiciones decodifican ambas $key, así que el valor podría ser cualquiera de las dos y no se puede usar ninguna. Cambie una de ellas a un modo+PID distinto. Nota: los PID que necesitan las estimaciones (010B, 010C, 010D) siempre se leen, así que quitar un indicador del panel no los detiene.';
  }

  @override
  String pidFormulaDependencyNotYetMeasured(String key) {
    return 'Aún no se ha leído ningún valor usable para $key.';
  }

  @override
  String get pidFormulaUnidentified =>
      'Esta fórmula no puede evaluarse, y el editor no tiene un motivo más específico.';

  @override
  String get pidRejectionMalformedModeAndPid =>
      'No es un modo+PID válido: solo caracteres hexadecimales, en pares de bytes completos.';

  @override
  String pidRejectionServiceNotReadOnly(String service, String services) {
    return 'El servicio $service no es una consulta de solo lectura y no debe enviarse al vehículo una y otra vez. Solo se permiten $services: datos actuales, fotograma congelado, información del vehículo y ReadDataByIdentifier.';
  }

  @override
  String get pidRejectionFreezeFrameNeedsFrame =>
      'Una consulta de fotograma congelado necesita dos bytes, el PID y el número de fotograma — por ejemplo 020500 (PID 05, fotograma 0).';

  @override
  String get pidRejectionIdentifierNeedsTwoBytes =>
      'ReadDataByIdentifier necesita un identificador de dos bytes — por ejemplo 221101.';

  @override
  String pidRejectionIdentifierWrongLength(String service, int bytes) {
    return 'Una consulta del servicio $service necesita un identificador de $bytes bytes.';
  }

  @override
  String get pidRejectionNameRequired => 'Introduzca un nombre.';

  @override
  String pidRejectionInvalidHeader(String text) {
    return '“$text” no es un encabezado válido: 3 dígitos para CAN de 11 bits, 6 para los protocolos heredados, 8 para CAN de 29 bits.';
  }

  @override
  String get pidRejectionBoundsRequired =>
      'Complete ambos extremos del rango del indicador.';

  @override
  String pidRejectionMinNotANumber(String text) {
    return 'El límite inferior “$text” no es un número válido.';
  }

  @override
  String pidRejectionMaxNotANumber(String text) {
    return 'El límite superior “$text” no es un número válido.';
  }

  @override
  String get pidRejectionMinNotFinite =>
      'El límite inferior tiene que ser un número finito.';

  @override
  String get pidRejectionMaxNotFinite =>
      'El límite superior tiene que ser un número finito.';

  @override
  String pidRejectionRedlineNotANumber(String text) {
    return 'El inicio de la zona roja “$text” no es un número válido.';
  }

  @override
  String get pidRejectionRedlineNotFinite =>
      'El inicio de la zona roja tiene que ser un número finito.';

  @override
  String get pidRejectionMaxNotAboveMin =>
      'El límite superior tiene que ser mayor que el inferior.';

  @override
  String pidImportMalformedCsv(String detail) {
    return 'Este archivo no pudo leerse como CSV: $detail';
  }

  @override
  String get pidImportNoRows => 'El archivo no tiene filas.';

  @override
  String pidImportDuplicateHeaderColumns(String columns) {
    return 'La fila de encabezado nombra la misma columna dos veces: $columns. No hay forma de saber cuál usar, así que corrija el archivo primero.';
  }

  @override
  String pidImportMissingRequiredColumns(String columns, String required) {
    return 'A la fila de encabezado le faltan columnas obligatorias: $columns. Se necesitan todas: $required.';
  }

  @override
  String pidImportRowTooFewColumns(int line) {
    return 'Fila $line: no hay suficientes celdas — nombre, nombre corto, PID y fórmula son el mínimo.';
  }

  @override
  String pidImportRowInvalidModeAndPid(int line, String text) {
    return 'Fila $line: “$text” no es un modo+PID válido (solo caracteres hexadecimales, en pares de bytes completos).';
  }

  @override
  String pidImportRowEmptyEquation(int line) {
    return 'Fila $line: la celda de la fórmula está vacía.';
  }

  @override
  String pidImportRowRejected(int line, String reason) {
    return 'Fila $line: $reason';
  }

  @override
  String pidImportRowRangeDefaulted(int line, double min, double max) {
    return 'Fila $line: el rango del indicador estaba en blanco, así que se aplicó $min–$max. Compruebe que esta escala conviene a este sensor.';
  }

  @override
  String get pidImportNothingImportable =>
      'El archivo tiene filas, pero ninguna es una definición de PID.';

  @override
  String get dtcCategoryNoAnswer =>
      'Esta categoría no respondió. Escanee de nuevo.';

  @override
  String get dtcCategoryError =>
      'Esta categoría no pudo leerse. El error completo se conserva en la transcripción.';

  @override
  String get dtcCategoryDisconnected =>
      'La conexión se cortó mientras se leía esta categoría.';

  @override
  String get dtcCategoryPending =>
      'Un controlador recibió la solicitud y aún está trabajando en ella. Espere y escanee de nuevo: esto no es un rechazo.';

  @override
  String get dtcCategoryUnattributed =>
      'Volvieron códigos, pero los encabezados de respuesta estaban desactivados, así que no se sabe qué controladores respondieron. Trátelo como parcial, no como un resultado limpio.';

  @override
  String dtcCategorySilentControllers(int count, String controllers) {
    return '$count controlador(es) no respondieron a esta consulta ($controllers). Las respuestas que sí llegaron son válidas, pero esto no puede valer como resultado de todo el vehículo.';
  }

  @override
  String dtcCategoryUnresolvedSources(int count, String addresses) {
    return '$count respuesta(s) no pudieron atribuirse a un controlador ($addresses). Los códigos que se leyeron siguen siendo válidos, pero esto no puede valer como resultado de todo el vehículo. Escanee de nuevo.';
  }

  @override
  String dtcCategoryPendingControllers(int count, int answered) {
    return '$count controlador(es) aún trabajan en esta solicitud ($answered ya respondieron). El resultado está incompleto. Espere y escanee de nuevo.';
  }

  @override
  String dtcCategoryRefusedControllers(int refused, int answered) {
    return '$refused controlador(es) rechazaron ($answered respondieron). Este escaneo no puede cubrir todo el vehículo.';
  }

  @override
  String dtcCategoryUnrecognisedResponses(int count, int answered) {
    return '$count respuesta(s) no pudieron leerse ($answered respondieron). El resto sigue siendo válido, pero este escaneo está incompleto.';
  }

  @override
  String dtcCategoryMilCountMismatch(
    String controller,
    int claimed,
    int observed,
  ) {
    return '$controller informó $claimed códigos de fallo confirmados, pero este escaneo solo leyó $observed. Confíe en la lámpara del panel y acuda a un taller.';
  }

  @override
  String dtcCategoryMilLitNoCodes(String controller) {
    return '$controller informó que el indicador de mal funcionamiento está encendido, pero no se leyó ninguno de sus códigos de fallo. Confíe en la lámpara del panel y acuda a un taller.';
  }

  @override
  String dtcCategoryMilDisagreement(String controllers) {
    return 'El propio estado del vehículo no coincide con los códigos de fallo que se leyeron ($controllers). Confíe en la lámpara del panel y acuda a un taller.';
  }

  @override
  String get connectPairedListFailed =>
      'No se pudo leer la lista de Bluetooth emparejado. Compruebe que Bluetooth está activado y vuelva a intentarlo.';

  @override
  String get connectBleScanUnavailable =>
      'Bluetooth no se puede usar ahora mismo. Espere un momento y busque de nuevo.';

  @override
  String get connectBleScanBluez =>
      'No se encontró ningún servicio Bluetooth BlueZ/D-Bus usable. Instale e inicie el servicio bluetooth y vuelva a intentarlo.';

  @override
  String get connectBleScanUnclassified => 'La búsqueda BLE falló.';

  @override
  String dtcClearNrcConditions(String controller) {
    return '$controller rechazó el borrado porque el estado del vehículo no lo permite. La mayoría de los controladores no borran con el motor en marcha. Ponga el encendido en ON con el motor parado y vuelva a intentarlo.';
  }

  @override
  String dtcClearNrcUnsupported(String controller) {
    return '$controller no admite el borrado Mode 04. Puede hacer falta equipo del fabricante o del concesionario.';
  }

  @override
  String dtcClearNrcBusy(String controller) {
    return '$controller está ocupado. Espere y vuelva a intentarlo.';
  }

  @override
  String dtcClearNrcSecurity(String controller) {
    return '$controller requiere acceso de seguridad antes de borrar. Se necesita equipo del fabricante o del concesionario.';
  }

  @override
  String dtcClearNrcOther(String controller, String code) {
    return '$controller rechazó el borrado (código de motivo $code). Espere y vuelva a intentarlo.';
  }

  @override
  String dtcClearSilentControllers(int count, String controllers) {
    return '$count controlador(es) no respondieron al borrado ($controllers). Los controladores que respondieron han borrado; otros pueden seguir reteniendo códigos. Vuelva a escanear. No envíe otro borrado.';
  }

  @override
  String dtcClearUnresolvedSources(int count, String addresses) {
    return '$count respuesta(s) de este escaneo no pudieron atribuirse ($addresses), así que no se sabe a qué controladores alcanzaría un borrado. Vuelva a escanear; si esa dirección no vuelve a aparecer, reconéctese antes de intentarlo.';
  }

  @override
  String dtcClearUnresolvedSourcesDoNotRepeat(int count, String addresses) {
    return '$count respuesta(s) en la respuesta del borrado no pudieron atribuirse ($addresses). No envíe otro borrado. Vuelva a escanear para ver qué códigos quedan.';
  }

  @override
  String dtcClearNrcConditionsDoNotRepeat(String controller) {
    return '$controller rechazó el borrado porque el estado del vehículo no lo permite. La mayoría de los controladores no borran con el motor en marcha. Ponga el encendido en ON con el motor parado y vuelva a escanear para ver qué códigos quedan. No envíe otro borrado global: un segundo puede restablecer la preparación de emisiones en un controlador que puede que ya haya borrado.';
  }

  @override
  String dtcClearNrcUnsupportedDoNotRepeat(String controller) {
    return '$controller no admite el borrado Mode 04. Puede hacer falta equipo del fabricante o del concesionario. No envíe otro borrado global: un segundo puede restablecer la preparación de emisiones en un controlador que puede que ya haya borrado. Vuelva a escanear para ver qué códigos quedan.';
  }

  @override
  String dtcClearNrcBusyDoNotRepeat(String controller) {
    return '$controller está ocupado. No envíe otro borrado global: un segundo puede restablecer la preparación de emisiones en un controlador que puede que ya haya borrado. Vuelva a escanear para ver qué códigos quedan.';
  }

  @override
  String dtcClearNrcSecurityDoNotRepeat(String controller) {
    return '$controller requiere acceso de seguridad antes de borrar. Se necesita equipo del fabricante o del concesionario. No envíe otro borrado global: un segundo puede restablecer la preparación de emisiones en un controlador que puede que ya haya borrado.';
  }

  @override
  String dtcClearNrcOtherDoNotRepeat(String controller, String code) {
    return '$controller rechazó el borrado (código de motivo $code). No envíe otro borrado global: un segundo puede restablecer la preparación de emisiones en un controlador que puede que ya haya borrado. Vuelva a escanear para ver qué códigos quedan.';
  }

  @override
  String get sharePolicyDenied =>
      'La conexión o el estado de conducción actuales no permiten exportar.';

  @override
  String get shareSafetyChanged =>
      'El estado cambió al preparar la exportación, así que no se abrió el compartir.';

  @override
  String get shareSizeLimit => 'La exportación supera el límite de 32 MiB.';

  @override
  String get shareStagingBusy =>
      'Un archivo de compartir anterior sigue en su periodo de retención. Inténtelo más tarde.';

  @override
  String get shareCleanupRequired =>
      'Hay que comprobar el área de preparación de compartir tras un reinicio.';

  @override
  String get shareSpaceUnknown =>
      'No se pudo confirmar el espacio libre que necesita el archivo de compartir.';

  @override
  String get shareNoSpace =>
      'No hay almacenamiento suficiente para preparar el archivo de compartir.';

  @override
  String get shareHandoffFailed =>
      'El archivo está listo, pero no se pudo abrir la hoja de compartir del sistema.';

  @override
  String get shareStorageFailure =>
      'Ocurrió un error de almacenamiento al preparar o registrar el compartir.';

  @override
  String shareTelemetrySubject(String sessionId) {
    return 'Registro OBD local $sessionId';
  }

  @override
  String shareRawTranscriptSubject(String stamp) {
    return 'Registro de transporte Telltale $stamp';
  }

  @override
  String get shareRecoveredTranscriptSubject =>
      'Registro de transporte Telltale (última conexión)';

  @override
  String get sharePidCsvSubject =>
      'Definiciones de PID personalizados de Telltale';

  @override
  String get shareTorqueSubsetCsvSubject =>
      'Definiciones de PID compatibles con Torque';

  @override
  String get shareHumanReportCsvSubject => 'Informe PID legible de Telltale';

  @override
  String get transcriptExportUnidentified => 'La exportación falló.';

  @override
  String get handshakeNoteUnexpected =>
      'Este paso falló con un error inesperado. El error completo se conserva en la transcripción.';

  @override
  String pidFormulaUnsupportedConstruct(String term) {
    return '$term es una función Torque que este dialecto no implementa, así que la fórmula no puede evaluarse aquí.';
  }

  @override
  String pidImportRowFormulaRejected(int line, String reason) {
    return 'Fila $line: $reason';
  }

  @override
  String get telemetryHistoryNeedsForeground =>
      'Vuelva a Telltale antes de continuar.';

  @override
  String get telemetrySessionPolicyChanged =>
      'El estado de conducción o de conexión cambió durante esta operación.';

  @override
  String get telemetrySessionInvalidId => 'Este id de grabación no es válido.';

  @override
  String get telemetrySessionNotFound => 'No se encontró esta grabación local.';

  @override
  String get telemetrySessionStorageFailed =>
      'Falló una operación de almacenamiento local.';

  @override
  String get telemetrySessionShareFailed =>
      'No se pudo preparar o abrir el compartir.';

  @override
  String get pidMutationPersistFailed =>
      'No se pudo guardar la lista de PID personalizados. No se cambió nada.';

  @override
  String get powertrainAuthorizeYearOutOfRange =>
      'Ese año de modelo está fuera del rango de años documentado de este perfil.';

  @override
  String get connectionLayerTransport => 'Transporte';

  @override
  String get connectionLayerProtocol => 'Protocolo';

  @override
  String get connectionLayerEcu => 'Respuestas ECU';

  @override
  String get connectionLayerEvidence => 'Evidencia';

  @override
  String get connectionLayerUnknown => 'Desconocido';

  @override
  String get connectionLayerNotObserved => 'No observado';

  @override
  String get connectionLayerObserved => 'Observado';

  @override
  String get connectionLayerAnswered => 'Respondió';

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
    return 'solicitado $requested, establecido $observed';
  }

  @override
  String get connectionLayerKwpSubtypeUnknown =>
      'KWP, 5-baud vs fast no distinguidos';

  @override
  String get connectionFailureOpenSettings => 'Abrir ajustes del sistema.';

  @override
  String get connectionFailureTurnRadioOn => 'Active Bluetooth.';

  @override
  String get connectionFailureCheckDistanceOrPower =>
      'El adaptador puede estar fuera de alcance o sin alimentación. Esa es una causa posible, no un hallazgo.';

  @override
  String get connectionFailureCheckIgnitionProtocolAdapter =>
      'Revise el encendido, el protocolo o la capacidad del adaptador. El silencio no demuestra que el vehículo no tenga OBD.';

  @override
  String get connectionFailureRetryOrAuto =>
      'Reintente, o configure el protocolo en Auto.';

  @override
  String get connectionFailureKeepInvalidAndExport =>
      'La respuesta no es válida. Manténgala no válida y exporte el diagnóstico limitado; no es una lectura.';

  @override
  String get settingsCatalogMarketCa => 'Canadá (NRCan)';

  @override
  String get settingsCaPickerTitle => 'Catálogo oficial de vehículos de Canadá';

  @override
  String settingsCaPickerScope(int firstYear, int lastYear) {
    return 'Filas de Fuel Consumption Ratings del mercado canadiense solo para $firstYear–$lastYear. ICE, eléctrico de batería e híbrido enchufable siguen siendo clases separadas. Una cadena coincidente de marca/modelo no es una configuración EPA ni de Taiwán.';
  }

  @override
  String get settingsCaMotorNotPower =>
      'La potencia del motor en kilovatios no es potencia en rueda y no se aplica.';

  @override
  String get settingsCaClassIce => 'ICE';

  @override
  String get settingsCaClassBev => 'BEV';

  @override
  String get settingsCaClassPhev => 'PHEV';

  @override
  String settingsCaWillApplyOnly(String fields) {
    return 'Solo se aplicarán $fields. Motor kW, consumo de combustible, autonomía, CO2, VE, Cd, área frontal, Crr y eficiencia de la transmisión quedan sin resolver.';
  }

  @override
  String get serviceRecipesTitle =>
      'Recetas de servicio y diagnósticos activos';

  @override
  String get serviceRecipesSubtitle =>
      'Recetas de servicio referenciadas a normas y descubrimiento de capacidades sin actuación';

  @override
  String get serviceRecipesSafetyBannerTitle => 'Cero candidatos en vivo';

  @override
  String get serviceRecipesSafetyBannerBody =>
      'La actuación física en vivo del vehículo está estrictamente prohibida (0 vehículos cualificados). Las recetas disponibles son solo datos de prueba para simulación.';

  @override
  String get serviceRecipesDiscoverySection =>
      'Descubrimiento Mode 08 sin actuación';

  @override
  String get serviceRecipesDiscoveryDescription =>
      'Consulta identificadores de prueba base estándar (\$00, \$20, ...) por CAN sin accionar ningún componente.';

  @override
  String get serviceRecipesDiscoveryButton =>
      'Descubrir TIDs admitidos de Mode 08';

  @override
  String get serviceRecipesDiscovering => 'Consultando TIDs admitidos...';

  @override
  String serviceRecipesDiscoverySuccess(String tids) {
    return 'Mode 08 es admitido por la ECU. TIDs admitidos: $tids';
  }

  @override
  String get serviceRecipesDiscoveryUnsupported =>
      'Mode 08 no es admitido por esta ECU';

  @override
  String serviceRecipesDiscoveryUnknown(String reason) {
    return 'El soporte de Mode 08 es desconocido: $reason';
  }

  @override
  String serviceRecipesDiscoveryPartialWarning(String reason, String blocks) {
    return 'El descubrimiento se completó parcialmente ($reason). Bloques sin completar: $blocks. Nota: no encontrado no significa no compatible.';
  }

  @override
  String get serviceRecipesCatalogSection => 'Recetas de servicio disponibles';

  @override
  String get serviceRecipesSimulationBadge => 'Listo para simulación';

  @override
  String get serviceRecipesLiveBlockedBadge =>
      'En vivo bloqueado (0 candidatos en vivo)';

  @override
  String serviceRecipesStandard(String standard) {
    return 'Norma: $standard';
  }

  @override
  String serviceRecipesEcuHeader(String header) {
    return 'Encabezado ECU: $header';
  }

  @override
  String serviceRecipesHash(String hash) {
    return 'Hash canónico: $hash';
  }

  @override
  String get serviceRecipesDetailTitle => 'Detalles de la receta de servicio';

  @override
  String get serviceRecipesPreconditions => 'Precondiciones de seguridad';

  @override
  String get serviceRecipesRecovery => 'Comando de recuperación';

  @override
  String get serviceRecipesClose => 'Cerrar';

  @override
  String get serviceRecipesDiscoveryRequiresCan =>
      'Requiere una conexión activa al bus CAN OBD-II.';

  @override
  String serviceRecipesLoadError(String error) {
    return 'Error al cargar las recetas de servicio: $error';
  }

  @override
  String get serviceRecipesNoPreconditions => 'Ninguna';

  @override
  String get settingsServiceRecipesEntry =>
      'Recetas de servicio y pruebas activas';

  @override
  String get settingsServiceRecipesDesc =>
      'Inspeccione recetas de taller y descubra pruebas Mode 08 admitidas';

  @override
  String get mode08ReasonUnheaderedLimitation =>
      'Atribución de origen y cobertura sin confirmar: las respuestas sin encabezado no pueden establecer la identidad de la ECU entre bloques';

  @override
  String mode08ReasonNoResponseWithEcu(
    String block,
    String ecu,
    String marker,
  ) {
    return 'Sin respuesta en el bloque $block de $ecu: $marker';
  }

  @override
  String mode08ReasonNoResponse(String block, String marker) {
    return 'Sin respuesta en el bloque $block: $marker';
  }

  @override
  String mode08ReasonNegativeWithEcu(String block, String ecu, String nrc) {
    return 'Respuesta negativa en el bloque $block de $ecu (NRC $nrc)';
  }

  @override
  String mode08ReasonNegative(String block, String nrc) {
    return 'Respuesta negativa en el bloque $block (NRC $nrc)';
  }

  @override
  String mode08ReasonMalformedWithEcu(
    String block,
    String ecu,
    String details,
  ) {
    return 'Respuesta malformada en el bloque $block de $ecu: $details';
  }

  @override
  String mode08ReasonMalformed(String block, String details) {
    return 'Respuesta malformada en el bloque $block: $details';
  }

  @override
  String mode08ReasonTimeout(String block) {
    return 'La consulta agotó el tiempo de espera para el bloque $block';
  }

  @override
  String get mode08ReasonBudgetExceeded =>
      'Se alcanzó el presupuesto de descubrimiento antes de consultar todos los bloques';

  @override
  String get mode08ReasonSessionDisconnected =>
      'La sesión se desconectó o fue reemplazada durante el descubrimiento';

  @override
  String mode08ReasonUnqueriedAnnounced(String blocks) {
    return 'Bloques no consultados anunciados por las ECU: $blocks';
  }

  @override
  String get mode08ReasonRequiresCanBus =>
      'El descubrimiento de capacidades Mode 08 requiere un bus CAN OBD-II resuelto';

  @override
  String get mode08ReasonUnexpectedExecution =>
      'Respuesta de ejecución inesperada para la consulta de TID admitidos';

  @override
  String get pidDetailEmptyTitle => 'Seleccione un PID';

  @override
  String get pidDetailEmptyBody =>
      'Elija un PID de la lista para inspeccionar su definición y estado en vivo.';

  @override
  String get pidDetailRangeLabel => 'Rango';

  @override
  String get pidDetailPriorityLabel => 'Prioridad';

  @override
  String pidDetailHeaderDefault(String header) {
    return 'Predeterminado ($header)';
  }

  @override
  String get dtcSystemOverview => 'Resumen del sistema';

  @override
  String get dtcPartialObservationBadge => 'Escaneo parcial';

  @override
  String get dtcPartialObservationBody =>
      'Este código de fallo se leyó, pero el escaneo de esta categoría no se completó en todos los controladores.';

  @override
  String get dtcLinkedFreezeFrameTitle => 'Fotograma congelado asociado';

  @override
  String get dtcNoLinkedFreezeFrame =>
      'Este escaneo no tiene un fotograma congelado que pueda asociarse de forma segura con este código de fallo y controlador.';

  @override
  String get performanceGuideTitle => 'Guía de prueba de aceleración';

  @override
  String get performanceGuideStep1 =>
      '1. Elija una velocidad objetivo y arme el temporizador';

  @override
  String get performanceGuideStep2 =>
      '2. Detenga el vehículo por completo y espere hasta que la prueba esté lista';

  @override
  String get performanceGuideStep3 =>
      '3. Empiece a acelerar; el cronometraje comienza automáticamente al detectar movimiento';

  @override
  String get performanceGuideStep4 =>
      '4. Alcance la velocidad objetivo para completar la prueba';

  @override
  String get performanceRecordingTrace =>
      'Acelerando... grabando traza de velocidad';

  @override
  String get performanceNoAnalysisTitle => 'Sin datos de análisis';

  @override
  String get performanceNoAnalysisBody =>
      'Esta prueba se detuvo antes de grabar suficientes muestras de velocidad para construir una traza o un resultado por tramos.';

  @override
  String get connectActivityReconnectingAutomatically =>
      'El adaptador dejó de responder. Reconectando automáticamente…';
}
