// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get adapterErrorActivityAlert => 'Avviso di attività del bus.';

  @override
  String get adapterErrorBufferFull =>
      'Il buffer dell\'adattatore è andato in overflow.';

  @override
  String get adapterErrorBus =>
      'Errore del bus; il cablaggio potrebbe esserne la causa.';

  @override
  String get adapterErrorBusBusy => 'Il bus è occupato.';

  @override
  String get adapterErrorBusInit => 'Inizializzazione del bus non riuscita.';

  @override
  String get adapterErrorCan => 'Errore del bus CAN.';

  @override
  String get adapterErrorData => 'I dati ricevuti non sono corretti.';

  @override
  String get adapterErrorFeedback => 'Errore di retroazione del segnale.';

  @override
  String get adapterErrorInternal => 'Errore interno dell\'adattatore.';

  @override
  String get adapterErrorLowPowerAlert =>
      'L\'adattatore sta per entrare in modalità a basso consumo.';

  @override
  String get adapterErrorLowVoltageReset =>
      'L\'adattatore si è riavviato per bassa tensione.';

  @override
  String get adapterErrorNoData =>
      'Non è arrivata alcuna risposta: potrebbe essere un silenzio temporaneo oppure il veicolo potrebbe non supportare questa funzione.';

  @override
  String get adapterErrorStopped => 'Il trasferimento è stato interrotto.';

  @override
  String get adapterErrorUnableToConnect =>
      'Impossibile raggiungere la ECU. Controlla che il quadro sia acceso.';

  @override
  String get adapterErrorUnknownCommand =>
      'L\'adattatore non supporta questo comando.';

  @override
  String get appTagline => 'Telemetria del veicolo in tempo reale';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => 'Aspetto';

  @override
  String get connectActivityAbortingPreviousConnection =>
      'Chiusura della connessione precedente, attendi…';

  @override
  String get connectAnswerBleWithClassic =>
      'Scegli Bluetooth LE. Non serve abbinarlo prima: cercalo nell\'app. Anche se compare nell\'elenco dei dispositivi Bluetooth da abbinare nelle impostazioni di sistema, non abbinarlo: quel percorso non funziona. Se la ricerca non trova nulla, il 4.0 sulla confezione indicava solo le specifiche del chip: usa invece Bluetooth Classic.';

  @override
  String get connectAnswerBleWithoutClassic =>
      'Scegli Bluetooth LE. Non serve abbinarlo prima: cercalo nell\'app. Anche se compare nell\'elenco dei dispositivi Bluetooth da abbinare nelle impostazioni di sistema, non abbinarlo: quel percorso non funziona. Se la ricerca non trova nulla, controlla che l\'adattatore sia alimentato o prova Wi‑Fi; questo dispositivo non offre Bluetooth Classic.';

  @override
  String get connectAnswerClassic =>
      'Scegli Bluetooth Classic. Abbinalo prima nelle impostazioni di sistema: l\'app non può abbinarlo per te. Il codice è di solito 1234 o 0000.';

  @override
  String get connectAnswerWifiDesktop =>
      'Scegli Wi-Fi. Collega prima questo dispositivo a quella rete, poi torna qui e inserisci l\'indirizzo.';

  @override
  String get connectAnswerWifiPhone =>
      'Scegli Wi-Fi. Collega prima il telefono a quella rete, poi torna qui e inserisci l\'indirizzo.';

  @override
  String get connectBleBody =>
      'Un adattatore BLE non deve essere abbinato prima. Cerca e scegli il dispositivo: i nomi comuni sono OBDII, V-LINK, Vgate o IOS-Vlink.';

  @override
  String connectBleEmptyScan(String next) {
    return 'La ricerca è terminata senza trovare un adattatore BLE. Controlla nell\'ordine: la spia dell\'adattatore è accesa? La maggior parte delle prese OBD non è alimentata finché il quadro non è su ON. Controlla poi la distanza: siediti in auto prima di cercare. $next Un adattatore BLE non ha bisogno di essere abbinato nelle impostazioni di sistema e non dovrebbe esserlo: quel percorso non funziona.';
  }

  @override
  String get connectBleEmptyScanNextClassic =>
      'Infine, controlla le specifiche sulla confezione: se riportano 2.0 o 3.0, si tratta di Bluetooth Classic, che non compare mai in questo elenco; usa invece Bluetooth Classic sopra.';

  @override
  String get connectBleEmptyScanNextWifi =>
      'Infine, controlla le specifiche sulla confezione: se riportano 2.0/3.0 o solo Wi‑Fi, prova Wi‑Fi (questo dispositivo non offre Bluetooth Classic).';

  @override
  String get connectBlePermissionDeniedForever =>
      'L\'autorizzazione Bluetooth è stata negata definitivamente. Il sistema non la chiederà più: attivala nelle impostazioni dell\'app.';

  @override
  String get connectBlePermissionNeeded =>
      'Per cercare serve l\'autorizzazione Bluetooth.';

  @override
  String get connectBleScan => 'Cerca dispositivi BLE';

  @override
  String get connectBleScanning => 'Ricerca in corso…';

  @override
  String get connectBleUnavailableHost =>
      'Bluetooth LE non è ancora disponibile su questo dispositivo';

  @override
  String get connectBluetoothOff =>
      'Il Bluetooth è disattivato. Attivalo prima nelle impostazioni di sistema.';

  @override
  String get connectBluetoothPermissionDeniedForever =>
      'L\'autorizzazione Bluetooth è stata negata definitivamente. Attivala nelle impostazioni di sistema e riprova.';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      'Serve l\'autorizzazione Bluetooth per elencare gli adattatori abbinati.';

  @override
  String get connectBody =>
      'Collega un adattatore ELM327 e accendi il quadro, oppure usa il simulatore integrato.';

  @override
  String get connectCancel => 'Annulla';

  @override
  String get connectClassicEmptyLinuxPort =>
      'Nessuna porta seriale Bluetooth (/dev/rfcomm*) trovata. Abbina prima l\'ELM327 con BlueZ, poi crea una TTY RFCOMM con rfcomm bind (o equivalente) e riprova.';

  @override
  String get connectClassicEmptyPaired =>
      'Nessun adattatore abbinato trovato. Abbinalo prima nelle impostazioni Bluetooth di sistema (il codice per la maggior parte degli ELM327 è 1234 o 0000).';

  @override
  String get connectClassicEmptyWindowsPort =>
      'Nessuna porta seriale Bluetooth (COMx) trovata. Abbina prima l\'ELM327 nelle impostazioni Bluetooth di Windows e verifica che Gestione dispositivi mostri «Standard Serial over Bluetooth link».';

  @override
  String get connectClassicListLinuxPort =>
      'Qui sono elencate le porte seriali Bluetooth associate da BlueZ (/dev/rfcomm* o equivalente). Un elenco vuoto significa che il sistema non ha ancora creato un nodo RFCOMM, non che l\'app sia guasta.';

  @override
  String get connectClassicListPaired =>
      'Qui sono elencati tutti i dispositivi abbinati al sistema, incluse cuffie e casse; quelli che sembrano adattatori sono mostrati per primi. Se scegli quello sbagliato, premi Annulla senza aspettare che la connessione fallisca: puoi sceglierne subito un altro.';

  @override
  String get connectClassicListWindowsPort =>
      'Qui sono elencate le porte COM associate al Bluetooth («Standard Serial over Bluetooth link»). Un elenco vuoto significa che il sistema non ha ancora creato una porta seriale virtuale, non che l\'app sia guasta.';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic (SPP) è attualmente disponibile su Android, macOS (IOBluetooth RFCOMM), Windows (COM) e Linux (/dev/rfcomm*)';

  @override
  String get connectClassicUnavailableIos =>
      'iOS non rende Bluetooth SPP disponibile alle app di terze parti';

  @override
  String get connectConnect => 'Connetti';

  @override
  String get connectDemoBody =>
      'Simula un motore turbo a quattro cilindri da 2.0 L nei cicli di minimo, accelerazione, marcia costante e decelerazione, con segnali fisicamente coerenti fra loro (i giri motore calano al cambio marcia mentre la velocità continua a salire). Codici guasto, lettura VIN e richieste raggruppate fastMode funzionano interamente.';

  @override
  String get connectDemoStart => 'Avvia il simulatore';

  @override
  String get connectHandshakeTitle => 'Inizializzazione ELM327';

  @override
  String get connectHandshakeTitleLastAttempt =>
      'Inizializzazione ELM327 (ultimo tentativo)';

  @override
  String get connectHeadline => 'Scegli una connessione';

  @override
  String get connectIssueAdapterAcceptedThenSilent =>
      'L\'adattatore ha accettato la connessione ma non ha risposto entro il tempo previsto. Di solito non è ancora alimentato (la maggior parte delle prese OBD fornisce corrente solo con il quadro acceso) oppure è già connesso a un\'altra app: in tal caso chiudila e riprova.';

  @override
  String connectIssueAdapterSilentOnReset(String command) {
    return 'L\'adattatore non ha risposto al comando di ripristino ($command). Il dispositivo potrebbe non essere un adattatore ELM327 oppure la connessione potrebbe aver raggiunto il dispositivo sbagliato.';
  }

  @override
  String get connectIssueAdapterStoppedResponding =>
      'L\'adattatore ha smesso di rispondere e la connessione è stata interrotta.';

  @override
  String get connectIssueConnectionSetupFailed =>
      'La connessione è fallita mentre veniva stabilita. Controlla che l\'adattatore sia alimentato e vicino, poi riprova. L\'errore completo è conservato nel registro qui sotto.';

  @override
  String get connectIssueHandshakeIncomplete =>
      'Inizializzazione non superata. L\'adattatore potrebbe non essere compatibile.';

  @override
  String connectIssueHandshakeStepFailed(String command, String reason) {
    return 'Inizializzazione fallita su $command ($reason). Controlla che l\'adattatore sia inserito correttamente e che il quadro del veicolo sia acceso.';
  }

  @override
  String get connectIssuePreviousConnectionStillAborting =>
      'La chiusura della connessione precedente è ancora in corso e l\'adattatore non è ancora stato rilasciato. Attendi qualche secondo e riprova.';

  @override
  String get connectLastAdapterConnect => 'Connetti ora';

  @override
  String get connectLastAdapterForget => 'Dimentica';

  @override
  String get connectLastAdapterTitle => 'Ultimo adattatore usato';

  @override
  String get connectOpenAppSettings => 'Apri impostazioni app';

  @override
  String get connectOpenSystemSettings => 'Apri impostazioni di sistema';

  @override
  String get connectOpeningConnection => 'Apertura connessione…';

  @override
  String get connectPairedPill => 'Abbinato';

  @override
  String get connectQuestionBle =>
      'La confezione, l\'inserzione o il nome del dispositivo riportano BLE, 4.0 o 5.0?';

  @override
  String get connectQuestionClassic =>
      'Nessuno dei due: è un modello più vecchio, con 2.0 o 3.0 sulla confezione?';

  @override
  String get connectQuestionWifiDesktop =>
      'Nell\'elenco Wi-Fi del sistema compare una nuova rete (per esempio V-LINK o WiFi_OBDII)?';

  @override
  String get connectQuestionWifiPhone =>
      'Nell\'elenco Wi-Fi del telefono compare una nuova rete (per esempio V-LINK o WiFi_OBDII)?';

  @override
  String get connectSearchAgain => 'Cerca di nuovo';

  @override
  String connectSignalStrength(int bars, int total) {
    return 'Intensità del segnale $bars/$total';
  }

  @override
  String get connectTranscriptKept =>
      'Il resoconto completo di questo tentativo è stato conservato. Riportarlo aiuta più di un messaggio di una sola riga.';

  @override
  String get connectTransportBleDescription =>
      'GATT UART — adattatore recente a basso consumo';

  @override
  String get connectTransportBleTitle => 'Bluetooth LE';

  @override
  String get connectTransportClassicDescription =>
      'RFCOMM / SPP — l\'ELM327 economico più diffuso';

  @override
  String get connectTransportClassicTitle => 'Bluetooth Classic';

  @override
  String get connectTransportDemoDescription =>
      'Una ECU simulata integrata: tutta l\'app senza hardware';

  @override
  String get connectTransportDemoTitle => 'Simulatore demo';

  @override
  String get connectTransportWifiDescription =>
      'Una porta TCP, di solito 192.168.0.10:35000';

  @override
  String get connectTransportWifiTitle => 'Wi-Fi';

  @override
  String get connectWhichIntro =>
      'Non preoccuparti delle sigle SPP e GATT. Guarda cosa fa il tuo adattatore una volta collegato:';

  @override
  String get connectWhichNoteGuessing =>
      'Sbagliare scelta non costa nulla: se non si connette, torna qui e provane un\'altra. Se sei davvero in difficoltà, usa il simulatore demo in basso per verificare che l\'app funzioni.';

  @override
  String get connectWhichNoteIos =>
      'Un iPhone può usare solo Wi-Fi o BLE: un normale ELM327 Bluetooth non funziona affatto su iOS. È un limite del sistema operativo e nessun\'altra app può aggirarlo.';

  @override
  String get connectWhichTitle => 'Non sai cosa scegliere?';

  @override
  String get connectWifiHostLabel => 'Indirizzo IP';

  @override
  String get connectWifiHostRequired =>
      'Inserisci l\'indirizzo IP dell\'adattatore.';

  @override
  String get connectWifiInstructionsDesktop =>
      'Collega prima questo computer all\'hotspot Wi-Fi trasmesso dall\'adattatore, poi inseriscine l\'indirizzo. Se il sistema avvisa che la rete non può accedere a Internet, scegli di rimanere connesso. I sistemi desktop normalmente usano l\'hotspot come percorso predefinito; non serve il vincolo al percorso Wi-Fi di Android.';

  @override
  String get connectWifiInstructionsPhone =>
      'Collega prima il telefono all\'hotspot Wi-Fi trasmesso dall\'adattatore, poi inseriscine l\'indirizzo. Se il sistema chiede se rimanere connesso a una rete Wi-Fi senza accesso a Internet, scegli di rimanere. Su Android, Telltale tenta di vincolare il traffico al percorso Wi-Fi durante la connessione, affinché i dati mobili non lo deviino.';

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '«$value» non è una porta valida. L\'intervallo è $min–$max.';
  }

  @override
  String get connectWifiPortLabel => 'Porta';

  @override
  String connectWifiPortRequired(int port) {
    return 'Inserisci la porta (la maggior parte degli adattatori usa $port).';
  }

  @override
  String get dashboardBatchedPolling => 'Interrogazione ciclica raggruppata';

  @override
  String get dashboardBatchingEnabled => 'Raggruppamento abilitato';

  @override
  String get dashboardChoosePids => 'Scegli PID';

  @override
  String get dashboardEmptyBody =>
      'Scegli i segnali da osservare nella pagina PID: appariranno qui.';

  @override
  String get dashboardEmptyTitle => 'Il cruscotto è vuoto';

  @override
  String get dashboardGenericObd => 'OBD generico';

  @override
  String get dashboardLocalRecordings => 'Registrazioni locali';

  @override
  String get dashboardNotConnected => 'Non connesso';

  @override
  String get dashboardPollingModeHelpAction =>
      'Info modalità di interrogazione';

  @override
  String get dashboardPollingModeHelpBatching =>
      'Raggruppamento abilitato significa che Telltale può riunire più richieste PID in un solo scambio per ridurre il numero di trasmissioni: i tentativi raggruppati sono consentiti e nulla ha disattivato il raggruppamento. È comunque un\'autorizzazione, non una misurazione: che un dato scambio raggruppi effettivamente più richieste dipende anche dai PID confermati dal veicolo e da quanti sono in attesa.';

  @override
  String get dashboardPollingModeHelpObserved =>
      'Interrogazione ciclica raggruppata significa che in questa connessione un comando Mode 01 ha effettivamente trasportato più di un PID. È la registrazione di quello scambio, non una promessa che il successivo sarà raggruppato né un\'affermazione sulla velocità di trasferimento.';

  @override
  String get dashboardPollingModeHelpRate =>
      'PIDs/s è una frequenza osservata nell\'ultimo secondo, non una promessa su latenza, aggiornamento o precisione. Varia con l\'adattatore, il bus, la ECU, i PID scelti, la dimensione di ogni risposta e gli eventuali errori.';

  @override
  String get dashboardPollingModeHelpSingle =>
      'La modalità a richiesta singola legge ogni PID Mode 01 separatamente. Telltale la usa quando il bus non accetta affatto richieste raggruppate, come in tutti i veicoli non CAN; finché nessun blocco di supporto ha risposto, perché raggruppare PID non confermati dal veicolo produce risposte troppo brevi; e dopo che una richiesta raggruppata non restituisce una risposta in una forma nuovamente suddivisibile, sia che la risposta sia troncata, sia che la richiesta venga rifiutata perché l\'adattatore ha segnalato il buffer pieno, sia che rimanga senza risposta. Le letture continuano ad aggiornarsi e, di per sé, questo non indica un errore di connessione.';

  @override
  String get dashboardPollingModeHelpTitle => 'Modalità di interrogazione';

  @override
  String get dashboardSingleRequestMode => 'Modalità a richiesta singola';

  @override
  String get dashboardVinRead => 'VIN letto';

  @override
  String get dashboardWorkspaceGauges => 'Indicatori';

  @override
  String get dashboardWorkspaceTrends => 'Andamenti';

  @override
  String get datumBadgeCommunityDecode => 'Decodifica della comunità';

  @override
  String get datumBadgeDemo => 'Simulato';

  @override
  String get datumBadgeEstimated => 'Stimato';

  @override
  String get datumBadgeExperimental => 'Sperimentale';

  @override
  String get datumBadgeFieldVerified => 'Verificato sul campo';

  @override
  String get datumBadgeInvalid => 'Non valido';

  @override
  String get datumBadgeJustUpdated => 'Appena aggiornato';

  @override
  String get datumBadgeOutOfReferenceRange => 'Fuori intervallo';

  @override
  String get datumBadgePartial => 'Parziale';

  @override
  String get datumBadgeStale => 'Non aggiornato';

  @override
  String get datumBadgeTentativeDecode => 'Decodifica provvisoria';

  @override
  String get datumBadgeUnverified => 'Non verificato';

  @override
  String get datumBadgeUnverifiedOnThisVehicle =>
      'Non verificato su questo veicolo';

  @override
  String get datumBadgeUserSupplied => 'Fornito dall\'utente';

  @override
  String get datumGapModelYearUnknown => 'Anno modello sconosciuto';

  @override
  String get datumGapNoCatalogMatch => 'Nessuna corrispondenza nel catalogo';

  @override
  String get datumGapVinNotRead => 'VIN non letto';

  @override
  String get datumNextStepEstimateOnly =>
      'Questo riguarda solo la stima; le altre letture restano valide.';

  @override
  String get datumNextStepGenericObd =>
      'Puoi continuare con OBD generico oppure scegliere il veicolo manualmente e inserire i parametri.';

  @override
  String get datumNextStepOtherReadings =>
      'L\'errore riguarda solo questo elemento; le altre letture restano valide.';

  @override
  String get datumNextStepRawOnly =>
      'La risposta grezza e l\'errore sono consultabili; nessuno dei due può essere letto come un valore normale.';

  @override
  String get datumReasonAssumptionsUnconfirmed =>
      'Le ipotesi non sono confermate; viene comunque mostrata una stima.';

  @override
  String get datumReasonBusError => 'Errore del bus.';

  @override
  String get datumReasonFormulaError => 'Errore nella formula.';

  @override
  String get datumReasonFuelEstimateMissingInputs =>
      'Manca un dato necessario alla stima del consumo di carburante.';

  @override
  String get datumReasonHeaderNotOnThisBus =>
      'L\'intestazione non corrisponde al bus usato da questo veicolo.';

  @override
  String get datumReasonHorsepowerEstimateMissingInputs =>
      'Manca un dato necessario alla stima della potenza.';

  @override
  String get datumReasonMalformedPacket =>
      'Pacchetto malformato; si può esaminare solo la risposta grezza.';

  @override
  String get datumReasonNoAnswer =>
      'Nessuna risposta: l\'app riprova tra circa un minuto.';

  @override
  String get datumReasonNoReadingYet => 'Ancora nessuna lettura.';

  @override
  String get datumReasonNonFiniteValue => 'Non è un numero finito.';

  @override
  String get datumReasonOutOfReferenceRangeKept =>
      'Fuori dal normale intervallo di riferimento; mantenuto così come letto.';

  @override
  String get datumReasonPidUnsupported =>
      'Questo veicolo non supporta questo PID.';

  @override
  String get datumReasonUnsafeService =>
      'Questo servizio non è una richiesta in sola lettura.';

  @override
  String get datumReasonUnsafeServiceStopped =>
      'Questo servizio non è una richiesta in sola lettura, quindi non è stato inviato.';

  @override
  String get datumStatusAssumptions => 'Ipotesi';

  @override
  String get datumStatusClose => 'Chiudi';

  @override
  String get datumStatusFollowsData => 'Lo stato segue i dati';

  @override
  String get datumStatusDetailsHint =>
      'Tocca per i dettagli sullo stato dei dati';

  @override
  String get datumStatusUnverifiedExplanation =>
      'Non verificato significa che qui non è documentato alcun confronto con un veicolo reale per questa decodifica sul tuo veicolo. Non significa che la lettura sia errata e non ne certifica la precisione. Aggiornamento e guasti sono mostrati separatamente.';

  @override
  String get datumStatusFormula => 'Formula';

  @override
  String get derivedAirflow => 'Portata d\'aria';

  @override
  String get derivedEcuFuelTitle => 'Dati carburante ECU';

  @override
  String get derivedEcuReported => 'Riportato dalla ECU';

  @override
  String get derivedEngineHorsepower => 'Potenza motore';

  @override
  String get derivedEstimatedFuelTitle => 'Consumo di carburante stimato';

  @override
  String get derivedEstimatesDetailsTitle => 'Formule e ipotesi delle stime';

  @override
  String get derivedEstimatesTitle => 'Valori stimati';

  @override
  String get derivedFuelUse => 'Consumo di carburante';

  @override
  String get derivedTorque => 'Coppia';

  @override
  String get derivedUnavailableMessage =>
      'La potenza può essere stimata solo quando arrivano i dati di velocità e accelerazione del veicolo';

  @override
  String dtcBothSilentDetail(Object mode) {
    return 'Il veicolo non ha risposto alla richiesta Mode $mode e neppure a Mode 03: non si può quindi distinguere tra mancato supporto del veicolo e mancata lettura durante questa connessione.';
  }

  @override
  String dtcCategoryFault(Object category) {
    return 'Un guasto relativo a $category';
  }

  @override
  String get dtcClear => 'Cancella';

  @override
  String get dtcClearCancel => 'Annulla';

  @override
  String get dtcClearConfirm => 'Cancella codici';

  @override
  String get dtcClearDialogBody =>
      'Questo cancella i codici guasto memorizzati e in attesa di conferma e spegne la spia di avaria; inoltre azzera lo stato dei monitor emissioni: il veicolo dovrà completare di nuovo un intero ciclo di autodiagnosi prima di poter superare una revisione. I codici guasto permanenti (Mode 0A) non possono essere cancellati.';

  @override
  String get dtcClearDialogFrameUnread =>
      'Questa scansione non ha letto un fermo immagine: ciò non significa che il veicolo non ne abbia. Esegui prima una nuova scansione, poi decidi se cancellare.';

  @override
  String dtcClearDialogFrames(Object codes) {
    return 'Anche il fermo immagine di $codes viene cancellato: l\'intera registrazione di giri motore, temperatura del liquido refrigerante e carico al momento del guasto non potrà essere riletta finché il guasto non si ripresenterà.';
  }

  @override
  String get dtcClearDialogTitle => 'Cancellare i codici guasto?';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count categorie di questa scansione non hanno risposto completamente',
      one: 'Una categoria di questa scansione non ha risposto completamente',
    );
    return '$_temp0 ($categories), quindi potrebbero esserci codici guasto che non hai visto. Dopo la cancellazione non potranno più essere letti.';
  }

  @override
  String get dtcClearCancelledBeforeSend =>
      'La cancellazione è stata annullata prima che qualsiasi comando lasciasse l\'app. Ripeti la scansione, poi riprova se vuoi ancora cancellare.';

  @override
  String get dtcClearConfirmed =>
      'Il comando di cancellazione è stato inviato.';

  @override
  String get dtcClearFailureDoNotRepeat =>
      'Un comando di cancellazione potrebbe aver già raggiunto il veicolo. Non inviarne un altro: una seconda cancellazione globale può azzerare lo stato dei monitor emissioni di un controller che potrebbe aver già cancellato i codici. Ripeti la scansione per vedere cosa resta.';

  @override
  String get dtcClearFailureGeneric =>
      'La cancellazione non è terminata. Ripeti la scansione per vedere i codici attuali prima di decidere se riprovare.';

  @override
  String get dtcClearNotAccepted =>
      'Cancellazione fallita; nessun controller ha accettato il comando. Puoi riprovare.';

  @override
  String get dtcClearPartiallyConfirmed =>
      'Almeno un controller ha segnalato il completamento della cancellazione, mentre per gli altri non è stato possibile confermare l\'esito. Non inviare un\'altra cancellazione: ripeterla azzera lo stato dei monitor emissioni sui controller che l\'hanno già completata. Ripeti la scansione per vedere il risultato.';

  @override
  String get dtcClearPreviousConnectionUnconfirmed =>
      'Una connessione precedente ha inviato un comando di cancellazione il cui risultato non è stato confermato. Ripeti prima la scansione, verifica quali codici rimangono e poi decidi se cancellare.';

  @override
  String get dtcClearRescanSettled =>
      'Non è stato possibile confermare completamente la cancellazione precedente. Quello che segue è lo stato effettivo dopo questa nuova scansione.';

  @override
  String get dtcClearSentUnconfirmed =>
      'Il comando di cancellazione è stato inviato, ma la risposta è stata danneggiata durante il trasferimento, quindi non si sa se il veicolo abbia cancellato i codici. Ripeti la scansione per verificare; non inviare un\'altra cancellazione: se è già riuscita, ripeterla azzera lo stato dei monitor emissioni.';

  @override
  String get dtcClearTimeout =>
      'Non è arrivata alcuna risposta dopo l\'invio del comando di cancellazione, quindi non si sa se il veicolo abbia cancellato i codici. Ripeti la scansione per verificare. Non inviare un\'altra cancellazione alla cieca.';

  @override
  String get dtcClearUnexpected =>
      'La cancellazione è fallita, quindi non si sa se il veicolo abbia cancellato i codici. Ripeti la scansione per verificare. Non inviare un\'altra cancellazione alla cieca.';

  @override
  String get dtcClearing => 'Cancellazione…';

  @override
  String get dtcScanDisconnectedMidScan =>
      'La connessione si è interrotta durante la scansione, che quindi non è terminata.';

  @override
  String get dtcScanInterrupted =>
      'La scansione è stata interrotta (l\'app potrebbe essere passata in background o la connessione potrebbe essere cambiata) e non ha ottenuto un risultato completo. Ripeti la scansione.';

  @override
  String get dtcCompleteCleanBody =>
      'Significa che ogni controller che ha risposto non ha segnalato codici guasto. Non significa che sia stato interrogato ogni modulo del veicolo.';

  @override
  String get dtcCompleteCleanTitle =>
      'Nessuno dei controller che hanno risposto ha segnalato un codice guasto.';

  @override
  String dtcControllerLabel(Object controller) {
    return 'Controller $controller';
  }

  @override
  String get dtcDismiss => 'Chiudi';

  @override
  String dtcFreezeFrameBody(Object code) {
    return 'I valori registrati da questo controller nell\'istante in cui $code è stato confermato. La cancellazione dei codici guasto distrugge anche questa registrazione.';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      'Questo controller ha un fermo immagine, ma non ha risposto alla richiesta degli elementi contenuti, quindi non è stato possibile leggerli. Una nuova scansione potrebbe funzionare.';

  @override
  String get dtcFreezeFrameNothingDecodable =>
      'Questo controller ha un fermo immagine, ma nessuno degli elementi contenuti può essere decodificato da questa app.';

  @override
  String get dtcFreezeFrameTitle => 'Il veicolo al momento del guasto';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Altri $count elementi di questo fermo immagine non hanno una formula di conversione in questa app e quindi non sono elencati.',
      one: 'Un altro elemento di questo fermo immagine non ha una formula di conversione in questa app e quindi non è elencato.',
    );
    return '$_temp0';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count elementi non sono stati ricevuti questa volta (potrebbe non esserci stato abbastanza tempo o il controller non ha risposto). Una nuova scansione potrebbe leggerli.',
      one: 'Un elemento non è stato ricevuto questa volta (potrebbe non esserci stato abbastanza tempo o il controller non ha risposto). Una nuova scansione potrebbe leggerlo.',
    );
    return '$_temp0';
  }

  @override
  String get dtcFreezeFrameUnreadPanel =>
      'Questa scansione non ha letto un fermo immagine: ciò non significa che il veicolo non ne abbia. Ripeti prima la scansione, poi decidi se cancellare i codici guasto, perché la cancellazione distrugge definitivamente la registrazione del momento del guasto. Se ogni scansione dà lo stesso risultato, questo veicolo potrebbe non fornirne uno.';

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label (Mode $mode) · $count';
  }

  @override
  String get dtcHeadline => 'Codici guasto';

  @override
  String get dtcListSeparator => ', ';

  @override
  String get dtcManufacturerSpecific =>
      'Codice specifico del costruttore: consulta il manuale di assistenza di questo veicolo';

  @override
  String get dtcMilOff => 'La spia di avaria è spenta';

  @override
  String get dtcMilOn => 'La spia di avaria è accesa';

  @override
  String get dtcMonitorBoostPressure => 'Pressione di sovralimentazione';

  @override
  String get dtcMonitorCatalyst => 'Catalizzatore';

  @override
  String get dtcMonitorComponents => 'Controllo completo componenti';

  @override
  String get dtcMonitorEgr => 'Sistema EGR / VVT';

  @override
  String get dtcMonitorEvaporative => 'Sistema emissioni evaporative';

  @override
  String get dtcMonitorExhaustSensor => 'Sensore gas di scarico';

  @override
  String get dtcMonitorFuelSystem => 'Sistema carburante';

  @override
  String get dtcMonitorGasolineParticulateFilter =>
      'Filtro antiparticolato benzina (GPF)';

  @override
  String get dtcMonitorHeatedCatalyst => 'Catalizzatore riscaldato';

  @override
  String get dtcMonitorMisfire => 'Mancata accensione';

  @override
  String get dtcMonitorNmhcCatalyst => 'Catalizzatore NMHC';

  @override
  String get dtcMonitorNoxAftertreatment => 'Post-trattamento NOx / SCR';

  @override
  String get dtcMonitorOxygenSensor => 'Sensore ossigeno';

  @override
  String get dtcMonitorOxygenSensorHeater => 'Riscaldatore sensore ossigeno';

  @override
  String get dtcMonitorParticulateFilter => 'Filtro antiparticolato';

  @override
  String get dtcMonitorSecondaryAir => 'Sistema aria secondaria';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — questa app non ha una descrizione dettagliata per questo codice';
  }

  @override
  String get dtcNotConnectedBody =>
      'Per leggere i codici guasto serve un adattatore ELM327 connesso oppure il simulatore in funzione.';

  @override
  String get dtcNotConnectedTitle => 'Non connesso';

  @override
  String get dtcNotScanned => 'Nessuna scansione effettuata';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count controller',
      one: 'un controller',
    );
    return 'Tutte e tre le categorie sono state interrogate fino al completamento. Per $_temp0 ($controllers) non sono implementati né i codici guasto in attesa di conferma né quelli permanenti: è normale su molti veicoli, ed è anche il motivo per cui non si può dichiarare il veicolo privo di guasti.';
  }

  @override
  String get dtcPartialCleanTitle =>
      'Le categorie che hanno risposto non hanno segnalato codici guasto.';

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories non hanno risposto, quindi non è possibile confermarne lo stato: non equivale a dire che il veicolo non ha problemi.';
  }

  @override
  String dtcPartialCodesRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sono stati letti $count codici guasto',
      one: 'È stato letto un codice guasto',
    );
    return '$_temp0 prima che questa categoria si arrestasse, ma la copertura è incompleta:';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return 'Solo alcuni controller di questa categoria hanno risposto e gli altri non hanno replicato, quindi questo non può rappresentare un risultato per l\'intero veicolo. $message';
  }

  @override
  String get dtcReadFailed => 'Lettura non riuscita';

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label (Mode $mode): $message';
  }

  @override
  String get dtcReadinessAllComplete =>
      'Tutti i monitor emissioni di competenza di questo controller sono completi.';

  @override
  String dtcReadinessIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monitor sono ancora incompleti',
      one: '1 monitor è ancora incompleto',
    );
    return '$_temp0: una revisione ora potrebbe non essere superata.';
  }

  @override
  String get dtcReadinessSaysNothing =>
      'Questo controller non ha segnalato alcun monitor emissioni: potrebbe non essere responsabile del monitoraggio delle emissioni e ciò non significa che sia pronto.';

  @override
  String get dtcReadinessTitle => 'Stato dei monitor emissioni';

  @override
  String get dtcRescanFirst => 'Ripeti prima la scansione';

  @override
  String get dtcRetry => 'Riprova';

  @override
  String get dtcScanBody =>
      'Legge i codici guasto memorizzati Mode 03, in attesa di conferma Mode 07 e permanenti Mode 0A.';

  @override
  String get dtcScanTitle => 'Cerca codici guasto nel veicolo';

  @override
  String get dtcScanning => 'Scansione…';

  @override
  String dtcSelfReportedCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Questo controller segnala autonomamente $count codici guasto confermati.',
      one:
          'Questo controller segnala autonomamente 1 codice guasto confermato.',
    );
    return '$_temp0';
  }

  @override
  String get dtcSelfReportedNoCodes =>
      'Questo controller segnala autonomamente che non ci sono codici guasto confermati.';

  @override
  String get dtcSilentCategoryHeadline => 'Questa categoria non ha risposto';

  @override
  String get dtcSilentPendingDetail =>
      'La richiesta dei codici guasto in attesa di conferma (Mode 07) non ha ricevuto risposta. Questa ECU potrebbe non implementare il servizio, oppure il servizio potrebbe semplicemente non essere stato letto questa volta: l\'assenza di risposta non permette di distinguere i due casi e non deve essere interpretata come assenza di guasti in attesa di conferma. Il risultato dei codici guasto memorizzati resta invariato.';

  @override
  String get dtcSilentPermanentDetail =>
      'La richiesta dei codici guasto permanenti (Mode 0A) non ha ricevuto risposta. Questa categoria è stata introdotta con la generazione OBD-II intorno al 2010, quindi i veicoli più vecchi non sempre la supportano; tuttavia, l\'assenza di risposta può anche significare che semplicemente non è stata letta questa volta e non si possono distinguere i due casi. Il risultato dei codici guasto memorizzati resta invariato.';

  @override
  String get dtcStartScan => 'Avvia scansione';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return 'Il veicolo non ha risposto alla richiesta Mode $mode, quindi non si può confermare se abbia codici guasto memorizzati. Non è la stessa cosa che non avere codici guasto.';
  }

  @override
  String dtcTotalCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count codici',
      one: '1 codice',
    );
    return '$_temp0';
  }

  @override
  String get dtcUnconfirmed => 'Impossibile confermare';

  @override
  String get dtcUnknownError => 'Errore sconosciuto';

  @override
  String get dtcUnknownMonitor => 'Monitor sconosciuto';

  @override
  String get dtcVerdictCompleteClean =>
      'Nessun codice guasto dai controller che hanno risposto';

  @override
  String get dtcVerdictPartialClean => 'Parzialmente non confermato';

  @override
  String get fieldEventBody =>
      'Premi solo quando il veicolo è completamente fermo, come passeggero o operatore con veicolo parcheggiato. Gli eventi condividono una cronologia con i dati OBD grezzi e viene tentato un salvataggio immediato.';

  @override
  String get fieldEventEngineStarted => 'Motore avviato';

  @override
  String get fieldEventHeading => 'Marcatori eventi sul campo';

  @override
  String get fieldEventIgnitionOn => 'Quadro acceso';

  @override
  String get fieldEventMemoryOnly =>
      'Registrato in questa sessione, ma il salvataggio automatico è fallito: esporta ora il resoconto diagnostico.';

  @override
  String fieldEventRecorded(String marker) {
    return 'Registrato e salvato: $marker';
  }

  @override
  String get fieldEventRoadTestStarted => 'Prova su strada avviata';

  @override
  String get fieldEventThrottleBlip => 'Colpo di acceleratore';

  @override
  String get fieldEventUnavailable =>
      'Non c\'è una connessione attiva al veicolo su cui registrare.';

  @override
  String get gaugeNoData => 'Nessun dato';

  @override
  String gaugeNoDataBecause(String reason) {
    return 'Nessun dato — $reason';
  }

  @override
  String gaugeReadingStale(String reading) {
    return '$reading (dati non aggiornati)';
  }

  @override
  String get gaugeUnsupportedByVehicle => 'Non supportato dal veicolo';

  @override
  String get handshakeNoteAborted =>
      'Interrotto dopo il fallimento di un passaggio precedente.';

  @override
  String get handshakeNoteEcuRefusedSupportQuery =>
      'La ECU ha rifiutato la richiesta di supporto (risposta negativa).';

  @override
  String get handshakeNoteEcuSilent => 'La ECU non ha risposto.';

  @override
  String get handshakeNoteNotAcknowledged =>
      'L\'adattatore non ha confermato questo comando.';

  @override
  String get handshakeNoteNotModeOnePositiveReply =>
      'La risposta non è una risposta positiva Mode 01.';

  @override
  String get handshakeNotePidEchoMismatch =>
      'La risposta ripete un PID diverso da quello richiesto.';

  @override
  String get handshakeNoteSupportMaskTooShort =>
      'La risposta di supporto è troppo breve; sono necessari 41 00 e altri quattro byte.';

  @override
  String get handshakeNoteTimedOut => 'Tempo scaduto.';

  @override
  String get handshakeStepAdapterVersion =>
      'Leggi la versione dell\'adattatore';

  @override
  String get handshakeStepAdaptiveTiming =>
      'Attiva la temporizzazione adattiva, l\'impostazione consigliata dalla scheda tecnica';

  @override
  String get handshakeStepBatteryVoltage => 'Leggi la tensione della batteria';

  @override
  String get handshakeStepDeviceIdentity =>
      'Leggi la stringa identificativa del dispositivo';

  @override
  String get handshakeStepEchoOff => 'Disattiva l\'eco dei comandi';

  @override
  String get handshakeStepLinefeedsOff => 'Disattiva gli avanzamenti di riga';

  @override
  String get handshakeStepMemoryOff => 'Disattiva la scrittura in memoria';

  @override
  String get handshakeStepNoReason => 'nessuna risposta';

  @override
  String get handshakeStepProtocolAuto =>
      'Rileva automaticamente il protocollo del bus';

  @override
  String get handshakeStepProtocolDescription =>
      'Leggi la descrizione del protocollo';

  @override
  String get handshakeStepProtocolNumber => 'Leggi il numero del protocollo';

  @override
  String get handshakeStepReset => 'Riavvia via software l\'adattatore';

  @override
  String get handshakeStepResponseTimeout =>
      'Imposta il tempo limite di risposta a circa 408 ms';

  @override
  String get handshakeStepSpacesOff =>
      'Disattiva gli spazi, riducendo il traffico di un terzo';

  @override
  String get handshakeStepSupportProbe =>
      'Chiedi alla ECU quali PID supporta, dimostrando che un veicolo ha risposto';

  @override
  String get languageSaveFailed => 'Impossibile salvare la lingua. Riprova.';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get navDashboard => 'Cruscotto';

  @override
  String get navDtc => 'Codici guasto';

  @override
  String get navPerformance => 'Tempi';

  @override
  String get navPid => 'PID';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get performanceArm => 'Prepara il cronometro';

  @override
  String get performanceDisclaimer =>
      'I tempi derivano dal segnale OBD della velocità su strada. La maggior parte dei veicoli indica 1–3 km/h in più sul proprio tachimetro e il segnale si aggiorna solo circa 10–20 volte al secondo; il risultato qui è quindi solo indicativo e non equivale a quello di apparecchiature di prova professionali.';

  @override
  String get performanceHeadline => 'Prova di accelerazione';

  @override
  String get performanceNoSpeedSignal =>
      'Al momento non c\'è un segnale valido di velocità su strada (PID 010D). Senza questo segnale la prova di accelerazione non può effettuare il cronometraggio.';

  @override
  String get performanceNotConnectedBody =>
      'La prova di accelerazione richiede la velocità su strada in tempo reale. Connetti un adattatore o avvia il simulatore integrato.';

  @override
  String get performanceNotConnectedTitle => 'Non connesso';

  @override
  String get performancePeakSpeed => 'Velocità massima';

  @override
  String get performanceReset => 'Azzera';

  @override
  String get performanceSecondsUnit => 'secondi';

  @override
  String get performanceSpeedGaugeLabel => 'Velocità';

  @override
  String get performanceSpeedTraceHeading => 'Grafico velocità';

  @override
  String get performanceSplitsHeading => 'Tempi intermedi';

  @override
  String get performanceStateAborted =>
      'Questa prova non è stata completata; sotto trovi ciò che è stato registrato prima dell\'interruzione';

  @override
  String get performanceStateAwaitingSpeedSignal =>
      'In attesa di un segnale di velocità';

  @override
  String performanceStateAwaitingStandstill(String speed) {
    return 'Fermati completamente prima di iniziare: ora $speed km/h';
  }

  @override
  String performanceStateFinished(int target) {
    return 'Completato 0 → $target km/h';
  }

  @override
  String get performanceStateIdle => 'Scegli una velocità obiettivo, poi avvia';

  @override
  String get performanceStateRunning => 'Cronometraggio';

  @override
  String get performanceStateStaged =>
      'Pronto — il cronometro parte quando ti muovi';

  @override
  String get performanceSubhead =>
      'Una prova cronometrata da fermo fino a una velocità obiettivo';

  @override
  String get performanceTargetSpeedHeading => 'Velocità obiettivo';

  @override
  String get pidActionCancel => 'Annulla';

  @override
  String get pidActionDelete => 'Elimina';

  @override
  String get pidArrangeBody =>
      'Trascina per riordinare. Il cruscotto si riempie da sinistra a destra e dall\'alto in basso: il primo elemento è quindi il primo che vedi.';

  @override
  String get pidArrangeEmptyMessage =>
      'Prima abilita alcuni PID nell\'elenco, poi torna qui per ordinarli.';

  @override
  String get pidArrangeEmptyTitle => 'Nessun PID ancora abilitato';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return 'Aggiungi i $count confermati';
  }

  @override
  String get pidBulkActionAllActive => 'Tutti già abilitati';

  @override
  String get pidBulkActionIncomplete => 'Dati della scansione incompleti';

  @override
  String get pidBulkActionLocked =>
      'Impossibile modificare durante la registrazione';

  @override
  String get pidBulkActionPending => 'In attesa dei risultati della scansione';

  @override
  String get pidBulkActionZero => 'Nessun PID supportato confermato';

  @override
  String pidBulkAddCount(int count) {
    return 'Aggiungi $count';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return 'Aggiungere $count PID supportati confermati?';
  }

  @override
  String pidBulkAdded(int count) {
    return 'Aggiunti $count PID supportati confermati.';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '$count blocchi di supporto non sono ancora confermati: verranno aggiunti solo gli elementi con evidenze positive.';
  }

  @override
  String pidBulkWillAdd(int count) {
    return 'Ne verranno aggiunti $count. Più PID sono abilitati, meno spesso ciascuno di essi potrebbe aggiornarsi.';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '$confirmed confermati';
  }

  @override
  String get pidCapabilityCoverageNone =>
      'Nessuna copertura contigua ancora stabilita';

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return 'Copertura contigua 01–$through (raggiunta la fine)';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return 'Copertura contigua 01–$through (sconosciuta oltre)';
  }

  @override
  String get pidCapabilityPhaseAttemptFinished =>
      'Questa scansione del supporto è terminata';

  @override
  String get pidCapabilityPhaseInterrupted =>
      'La scansione del supporto è stata interrotta';

  @override
  String get pidCapabilityPhaseNotStarted => 'Scansione non avviata';

  @override
  String get pidCapabilityPhaseRunning =>
      'Conferma dei PID supportati da questo veicolo';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return 'PID supportati dal veicolo. $phase. $confirmed confermati. $unknown blocchi sconosciuti.';
  }

  @override
  String get pidCapabilityTitle => 'PID supportati dal veicolo';

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '$unknown blocchi sconosciuti';
  }

  @override
  String pidEditorCollision(String name) {
    return 'Un PID personalizzato usa già questa combinazione ($name). Usa una combinazione modalità + PID, un\'intestazione o un suffisso del nome diversi.';
  }

  @override
  String pidEditorDeleteBody(String name) {
    return 'La definizione di «$name» viene eliminata, il relativo indicatore scompare dal cruscotto e l\'operazione non può essere annullata.';
  }

  @override
  String get pidEditorDeleteTitle => 'Eliminare questo PID?';

  @override
  String get pidEditorDiscard => 'Scarta';

  @override
  String get pidEditorDiscardBody =>
      'Le modifiche a questo PID non sono state salvate e uscendo andranno perse.';

  @override
  String get pidEditorDiscardTitle => 'Scartare le modifiche non salvate?';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N corrispondono ai byte della risposta; sono disponibili SIGNED(), ABS(), LOG10(), $valSyntax e BARO';
  }

  @override
  String get pidEditorFieldEquation => 'Espressione';

  @override
  String get pidEditorFieldHeader => 'Intestazione CAN';

  @override
  String get pidEditorFieldMax => 'Massimo';

  @override
  String get pidEditorFieldMin => 'Minimo';

  @override
  String get pidEditorFieldModeAndPid => 'Modalità + PID';

  @override
  String get pidEditorFieldName => 'Nome';

  @override
  String get pidEditorFieldSample => 'Byte della risposta di prova';

  @override
  String get pidEditorFieldShortName =>
      'Nome breve (mostrato sull\'indicatore)';

  @override
  String get pidEditorFieldUnits => 'Unità';

  @override
  String get pidEditorHeaderHelper => '7E0 = motore';

  @override
  String get pidEditorKeepEditing => 'Continua a modificare';

  @override
  String get pidEditorModeAndPidHelper => 'Per esempio 010C o 221101';

  @override
  String get pidEditorSampleHelper =>
      'Inserisci valori esadecimali per vedere l\'anteprima mentre digiti';

  @override
  String get pidEditorSave => 'Salva';

  @override
  String get pidEditorSectionFormula => 'Formula';

  @override
  String get pidEditorSectionIdentity => 'Identità';

  @override
  String get pidEditorSectionQuery => 'Interrogazione';

  @override
  String get pidEditorSectionRangeAndPriority =>
      'Intervallo e priorità dell\'indicatore';

  @override
  String get pidEditorTitleEdit => 'Modifica PID';

  @override
  String get pidEditorTitleNew => 'Nuovo PID personalizzato';

  @override
  String pidExportFailed(String error) {
    return 'Esportazione non riuscita: $error';
  }

  @override
  String get pidExportNoCustomPids =>
      'Non ci sono PID personalizzati da esportare.';

  @override
  String get pidImportNothingToImport => 'Nessuna definizione da importare.';

  @override
  String pidImportLandedClean(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importati $count PID personalizzati.',
      one: 'Importato 1 PID personalizzato.',
    );
    return '$_temp0';
  }

  @override
  String pidImportLandedWithNotes(int count, String notes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Importati $count elementi, $notes.',
      one: 'Importato 1 elemento, $notes.',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteSkippedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count righe presentavano problemi e sono state saltate',
      one: '1 riga presentava problemi ed è stata saltata',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDefaultedRanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count righe hanno usato l\'intervallo predefinito dell\'indicatore',
      one: '1 riga ha usato l\'intervallo predefinito dell\'indicatore',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementi hanno sostituito definizioni esistenti',
      one: '1 elemento ha sostituito una definizione esistente',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDuplicatesInFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count righe erano duplicati di altre nel file e sono state saltate',
      one: '1 riga era il duplicato di un\'altra nel file ed è stata saltata',
    );
    return '$_temp0';
  }

  @override
  String get pidImportPickerFailed => 'Impossibile aprire il selettore file.';

  @override
  String get pidImportReadFailed => 'Impossibile leggere il file.';

  @override
  String get pidListSeparator => ', ';

  @override
  String get pidManagerActiveOnly => 'Solo abilitati';

  @override
  String get pidManagerAdd => 'Nuovo';

  @override
  String get pidManagerArrangeDashboard => 'Disponi il cruscotto';

  @override
  String pidManagerCounts(int active, int total) {
    return '$active abilitati · $total disponibili';
  }

  @override
  String get pidManagerExportCsv => 'Esporta PID personalizzati';

  @override
  String get pidManagerExportTorqueCsv => 'Esporta CSV compatibile con Torque';

  @override
  String get pidManagerExportHumanReport => 'Esporta report PID leggibile';

  @override
  String get pidManagerHeadline => 'Gestione PID';

  @override
  String get pidManagerImportCsv => 'Importa CSV';

  @override
  String get pidManagerMoreActions => 'Altro';

  @override
  String get pidManagerNoMatchMessage =>
      'Prova un\'altra parola chiave oppure crea un PID personalizzato.';

  @override
  String get pidManagerNoMatchTitle => 'Nessun PID corrispondente';

  @override
  String get pidManagerPowertrainBatteryCatalog =>
      'Catalogo batterie di trazione';

  @override
  String get pidManagerSearchHint => 'Cerca per nome o codice PID…';

  @override
  String get pidPickCsvDialogTitle => 'Scegli un CSV di definizioni PID';

  @override
  String get pidPillCustom => 'Personalizzato';

  @override
  String get pidPillUnsupported => 'Non supportato';

  @override
  String get pidPreviewCannotEvaluate => 'Impossibile valutare';

  @override
  String get pidPreviewResultLabel => 'Risultato';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'L\'anteprima sostituisce $dependencies con $valueString; il valore reale proviene da quel PID una volta connessi.';
  }

  @override
  String get pidPreviewTitle => 'Anteprima in tempo reale';

  @override
  String get pidPriorityHigh => 'Alta';

  @override
  String get pidPriorityLow => 'Bassa';

  @override
  String get pidPriorityMedium => 'Media';

  @override
  String get pidPriorityVeryLow => 'Molto bassa';

  @override
  String get pidRowEdit => 'Modifica';

  @override
  String pidRowShowOnDashboard(String name) {
    return 'Mostra $name sul cruscotto';
  }

  @override
  String pidRowStaleUnits(String units) {
    return '$units · non aggiornato';
  }

  @override
  String powertrainAuthorizationGranted(String profile) {
    return 'I segnali della batteria per $profile sono attivi per questa connessione';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return 'Impossibile abilitare: $reason';
  }

  @override
  String get powertrainCancel => 'Annulla';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return 'Profili: $profiles · Letture singole: $probeable';
  }

  @override
  String get powertrainCatalogLoadFailedBody =>
      'La verifica dell\'integrità non è stata superata, quindi nessun dato del veicolo viene mostrato o installato.';

  @override
  String get powertrainCatalogLoadFailedTitle =>
      'Impossibile caricare il catalogo offline';

  @override
  String get powertrainCatalogNotVerified =>
      'Il catalogo non ha superato la verifica, quindi non è possibile installare nulla.';

  @override
  String get powertrainCatalogRevalidate => 'Verifica di nuovo';

  @override
  String get powertrainCatalogScopeNote =>
      'Il catalogo è ampio, ma «abbiamo trovato dei dati» non significa «la tua auto è supportata». Le voci riservate alla ricerca non contengono mai comandi. Le voci sperimentali Mode 22 possono essere installate e interrogate ciclicamente, ma ogni valore è indicato come non verificato; le voci sperimentali Mode 21 vengono lette una volta per ogni conferma.';

  @override
  String get powertrainCatalogSearchHint =>
      'Cerca marca, modello, variante o mercato…';

  @override
  String get powertrainCatalogTitle => 'Catalogo batterie di trazione';

  @override
  String get powertrainChooseCommandNote =>
      'Un comando per tentativo: nessuna scansione, nessun raggruppamento, nessun nuovo tentativo automatico.';

  @override
  String get powertrainChooseCommandTitle =>
      'Scegli un\'interrogazione fissa in sola lettura';

  @override
  String get powertrainClose => 'Chiudi';

  @override
  String get powertrainConfirmAccept => 'È questa l\'auto';

  @override
  String get powertrainConfirmBody =>
      'I segnali del profilo installato vengono letti solo dopo che hai confermato che questa auto è quel modello; la conferma vale solo per questa connessione.';

  @override
  String get powertrainConfirmButton => 'Conferma il veicolo';

  @override
  String get powertrainConfirmDialogBody =>
      'Dopo la conferma, le interrogazioni della batteria in sola lettura di questo profilo vengono eseguite ciclicamente per il resto della connessione. Un profilo errato può produrre numeri che sembrano plausibili ma sono sbagliati: annulla se non sei sicuro.';

  @override
  String get powertrainConfirmDialogTitle => 'Conferma il veicolo connesso';

  @override
  String get powertrainConfirmTitle =>
      'I segnali della batteria del veicolo sono in attesa di conferma';

  @override
  String get powertrainConnectFirst =>
      'Prima connettiti; l\'autorizzazione sperimentale non viene mai mantenuta tra connessioni.';

  @override
  String get powertrainConnectionChanged =>
      'La connessione è cambiata: conferma di nuovo il veicolo per la nuova connessione.';

  @override
  String get powertrainEnableLabInSettings =>
      'Prima attiva il laboratorio sperimentale della batteria nelle Impostazioni.';

  @override
  String get powertrainEvidencePhysicalVehicle => 'Veicolo del progetto';

  @override
  String get powertrainEvidenceSourceBacked => 'Dati della fonte';

  @override
  String get powertrainEvidenceSyntheticRig => 'Banco di prova sintetico';

  @override
  String get powertrainExperimentalDataDisclosure =>
      'Questa è una lettura candidata etichettata dagli autori della fonte, non una garanzia del costruttore né una garanzia di sicurezza valida per più modelli; l\'ELM327 si limita a inoltrare il comando. Il comando e la risposta grezzi restano nel resoconto diagnostico locale e questa funzione non li carica automaticamente; i valori decodificati non vengono mai installati come PID né aggiunti a un indicatore. Annullare non influisce sulle normali funzioni OBD.';

  @override
  String get powertrainExperimentalDialogTitle =>
      'Conferma della lettura singola sperimentale in sola lettura';

  @override
  String get powertrainExperimentalIdentityAck =>
      'Ho controllato mercato, modello e anno modello noti alla fonte e accetto i campi non confermati';

  @override
  String get powertrainExperimentalParkedAck =>
      'Il veicolo è parcheggiato in sicurezza; capisco che viene eseguita una sola lettura e che il numero potrebbe comunque non essere applicabile';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return 'Accetta solo RX $responder, lunghezza del payload $bytes bytes';
  }

  @override
  String get powertrainFieldListSeparator => ', ';

  @override
  String get powertrainFieldMarket => 'Mercato';

  @override
  String get powertrainFieldModel => 'Modello';

  @override
  String get powertrainFieldModelYear => 'Anno modello';

  @override
  String get powertrainFieldVariant => 'Variante';

  @override
  String get powertrainFilterAll => 'Tutti';

  @override
  String get powertrainIdentityEvidenceExact => 'evidenza diretta';

  @override
  String get powertrainIdentityEvidenceNone => 'nessuno';

  @override
  String get powertrainIdentityEvidenceSourcePartial => 'evidenza parziale';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return 'Evidenze sull\'identità nella fonte: $fields\nCampi non confermati: $unconfirmed';
  }

  @override
  String get powertrainIdentityEvidenceUnknown => 'sconosciuto';

  @override
  String get powertrainInstallButton => 'Installa segnali della batteria';

  @override
  String get powertrainInstallConfirm => 'Installa';

  @override
  String get powertrainInstallDialogTitle =>
      'Installa i segnali della batteria di questo modello';

  @override
  String get powertrainInstallDisclosureCommunity =>
      'L\'installazione aggiunge soltanto PID della batteria in sola lettura alla gestione PID. Prima che inizi qualsiasi lettura, a ogni connessione ti viene chiesto di confermare sul cruscotto che questa auto è quel modello. I dati provengono da fonti della comunità e sono stati corroborati indipendentemente; non costituiscono comunque una garanzia del costruttore.';

  @override
  String get powertrainInstallDisclosureExperimental =>
      'L\'installazione aggiunge soltanto PID della batteria in sola lettura alla gestione PID. Prima che inizi qualsiasi lettura, a ogni connessione ti viene chiesto di confermare sul cruscotto che questa auto è quel modello. Questa decodifica è sperimentale, non richiede corroborazione indipendente, non è verificata su questo veicolo e non costituisce comunque una garanzia del costruttore.';

  @override
  String get powertrainInstallDisclosureReady =>
      'L\'installazione aggiunge soltanto PID della batteria in sola lettura alla gestione PID. Prima che inizi qualsiasi lettura, a ogni connessione ti viene chiesto di confermare sul cruscotto che questa auto è quel modello. I dati della fonte sono più completi; non costituiscono comunque una garanzia del costruttore.';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      'L\'installazione aggiunge soltanto PID della batteria in sola lettura alla gestione PID. Prima che inizi qualsiasi lettura, a ogni connessione ti viene chiesto di confermare sul cruscotto che questa auto è quel modello. Questa voce è riservata alla ricerca e non deve essere installata.';

  @override
  String get powertrainInstallCatalogShaMissing =>
      'Impossibile installare: questa istantanea del catalogo non ha un SHA-256 verificato, quindi non ci si può fidare di nulla al suo interno.';

  @override
  String get powertrainInstallPersistFailed =>
      'Impossibile installare: non è stato possibile salvare l\'elenco dei profili installati. Riprova; non è stato aggiunto nulla alla gestione PID.';

  @override
  String get powertrainInstallProfileNotInCatalog =>
      'Impossibile installare: quel profilo non è nel catalogo verificato.';

  @override
  String get powertrainInstallProfileNotInstallable =>
      'Impossibile installare: questo profilo non si trova in uno stato che consenta di trasformarlo in PID in tempo reale.';

  @override
  String get powertrainInstallYearOutOfRange =>
      'Impossibile installare: quell\'anno modello è fuori dall\'intervallo di anni documentato per questo profilo.';

  @override
  String get powertrainInstallIdentityAck =>
      'Il mio veicolo corrisponde al mercato, modello e anno modello indicati sopra';

  @override
  String get powertrainInstalledRemoveButton => 'Installato · rimuovi segnali';

  @override
  String powertrainInstalledSignalsSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Installati $count segnali. Aggiungili al cruscotto dalla pagina PID; ogni connessione richiede la conferma del veicolo.',
      one: 'Installato 1 segnale. Aggiungilo al cruscotto dalla pagina PID; ogni connessione richiede la conferma del veicolo.',
    );
    return '$_temp0';
  }

  @override
  String get powertrainNoMatchBody =>
      'Prova il nome di una marca o di un modello oppure passa a un altro tipo di gruppo propulsore.';

  @override
  String get powertrainNoMatchTitle => 'Nessun veicolo corrispondente';

  @override
  String get powertrainNotInstallableInThisRelease =>
      'Non installabile in questa versione';

  @override
  String powertrainPrimarySource(String name, String license) {
    return 'Fonte primaria: $name ($license)';
  }

  @override
  String get powertrainProbeChecksPassed =>
      'Superati i controlli su risponditore, eco, lunghezza esatta, formula e intervallo.';

  @override
  String get powertrainProbeConnectForOneShot =>
      'Connettiti per un\'interrogazione singola in sola lettura';

  @override
  String get powertrainProbeConnectToTryOnce =>
      'Connettiti per provare prima una lettura';

  @override
  String get powertrainProbeDidNotFinish =>
      'L\'interrogazione singola non è terminata; nessun valore è stato pubblicato o conservato.';

  @override
  String get powertrainProbeEnableLabFirst =>
      'Prima attiva il laboratorio nelle Impostazioni';

  @override
  String get powertrainProbeInProgress => 'Lettura singola in corso…';

  @override
  String get powertrainProbeNoValuePublished =>
      'Nessun valore è stato pubblicato; un errore strutturale o di decodifica resta in quarantena finché non ti riconnetti.';

  @override
  String get powertrainProbeOnceButton => 'Leggi una sola volta';

  @override
  String get powertrainProbePassedTitle => 'Interrogazione singola superata';

  @override
  String get powertrainProbePickOneRead => 'Scegli un comando, leggi una volta';

  @override
  String get powertrainProbeReconnectFirst => 'Riconnettiti, poi riprova';

  @override
  String get powertrainProbeRefusedTitle => 'Interrogazione singola rifiutata';

  @override
  String get powertrainProbeTryOnceFirst => 'Prova prima una lettura';

  @override
  String get powertrainProfileNotVerified =>
      'Il profilo non è nel catalogo verificato';

  @override
  String get powertrainQuarantinedPill => 'In quarantena · riconnetti';

  @override
  String get powertrainRefusedCatalogHashInvalid =>
      'Non autorizzato: l\'hash di integrità del catalogo non è valido, quindi non è possibile leggere nulla al suo interno.';

  @override
  String get powertrainRefusedCommandNotInProfile =>
      'Non autorizzato: quel comando non è tra i comandi propri di questo profilo verificato.';

  @override
  String get powertrainRefusedLabClosed =>
      'Il laboratorio sperimentale della batteria è stato disattivato prima che questa lettura potesse essere autorizzata.';

  @override
  String get powertrainRefusedProfileFailedValidation =>
      'Non autorizzato: questo profilo non ha superato la convalida del catalogo per l\'anno modello che hai scelto.';

  @override
  String get powertrainRefusedProfileNotInCatalog =>
      'Non autorizzato: questo profilo non è nel catalogo verificato.';

  @override
  String get powertrainRefusedProfileNotProbeable =>
      'Non autorizzato: questo profilo non è tra quelli che possono essere letti una volta a titolo sperimentale.';

  @override
  String get powertrainRefusedQuarantinedAfterRejectedRead =>
      'In quarantena per questa connessione: una precedente lettura singola non ha superato i controlli strutturali. Riconnettiti prima di riprovare.';

  @override
  String get powertrainRefusedNotConnectedOrNotInForeground =>
      'La lettura singola non è stata avviata: non c\'è alcuna connessione oppure l\'app non era in primo piano.';

  @override
  String get powertrainRefusedNoLiveAuthorization =>
      'La lettura singola non è stata avviata: non è disponibile alcuna autorizzazione monouso. Non è stata concessa oppure è scaduta, è entrata nel periodo di attesa o è stata messa in quarantena.';

  @override
  String get powertrainRefusedDiscardedAtLifecycleBoundary =>
      'La connessione o lo stato in primo piano è cambiato durante la lettura singola, quindi la risposta è stata scartata anziché mostrata. Non si è verificato alcun errore e nulla è stato conservato.';

  @override
  String powertrainRefusedQuarantinedAtAttemptCap(int attemptCap) {
    return 'In quarantena per questa connessione: lo stesso comando è già stato provato $attemptCap volte. Riconnettiti prima di riprovare.';
  }

  @override
  String get powertrainResearchOnlyNeverQueries =>
      'Solo ricerca — non interroga mai';

  @override
  String get powertrainRestoreStorageErrorRetry =>
      'Si è verificato un errore di archiviazione durante il ripristino delle installazioni precedenti. Il ripristino è stato riprogrammato: riprova.';

  @override
  String powertrainSecondarySource(String name, String license) {
    return 'Corroborazione indipendente: $name ($license)';
  }

  @override
  String powertrainSignalCount(int count) {
    return 'Segnali: $count';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return 'SHA-256 del file sorgente: $hash…';
  }

  @override
  String get powertrainStatusCommunity => 'Comunità · non verificato';

  @override
  String get powertrainStatusExperimental => 'Sperimentale · non verificato';

  @override
  String get powertrainStatusExperimentalProbeOnly =>
      'Sperimentale · lettura singola';

  @override
  String get powertrainStatusReady => 'Dati della fonte più completi';

  @override
  String get powertrainStatusResearchOnly => 'Solo ricerca';

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return 'Rimossi i segnali installati per $name.';
  }

  @override
  String powertrainVehicleYearFixed(int year) {
    return 'Anno modello: $year';
  }

  @override
  String get powertrainVehicleYearLabel => 'Anno modello';

  @override
  String get recommendedPurchaseDisclosure =>
      'Questo è un link di affiliazione di chi mantiene il progetto; un acquisto idoneo potrebbe corrispondergli una commissione. Non è una certificazione dell\'adattatore né una garanzia di acquisto. Il contenuto dell\'inserzione e le revisioni hardware possono cambiare, quindi controlla il numero completo del modello e il numero NCC prima dell\'acquisto. Sei anche libero di cercare altri venditori.';

  @override
  String get recommendedPurchaseHeading => 'Adattatore consigliato';

  @override
  String recommendedPurchaseModelLine(String model, String approval) {
    return 'Modello $model · NCC $approval';
  }

  @override
  String recommendedPurchaseNoAdapterYet(String store) {
    return 'Non hai ancora un adattatore? Guarda quello consigliato su $store';
  }

  @override
  String recommendedPurchaseOpenFailed(String store) {
    return 'Impossibile aprire il link di $store';
  }

  @override
  String get recommendedPurchaseShortDisclosureAction =>
      'Informativa completa nelle Impostazioni';

  @override
  String get recommendedPurchaseShortDisclosureLead =>
      'Questo è un link di affiliazione, non una certificazione dell\'adattatore.';

  @override
  String get recommendedPurchaseStoreShopee => 'Shopee';

  @override
  String recommendedPurchaseViewOnStore(String store) {
    return 'Visualizza su $store';
  }

  @override
  String get semanticsFieldSeparator => ', ';

  @override
  String get settingsAdapterConcernsFooter =>
      'Queste sono incongruenze in ciò che l\'adattatore dichiara su se stesso, non evidenze che abbia letto male il veicolo. L\'unico modo per confermare un valore è una seconda misurazione indipendente (vedi la guida pratica).';

  @override
  String get settingsAdapterNoContradictions =>
      'Non sono state trovate contraddizioni in ciò che l\'adattatore dichiara su se stesso. Questo significa solo che è internamente coerente: non dimostra che il chip sia autentico né che i numeri che riporta siano corretti. Su un clone, la stringa della versione è solo testo scelto da qualcuno.';

  @override
  String get settingsAdapterNoVersion => '(nessuna versione riportata)';

  @override
  String get settingsAdapterSelfReportTitle =>
      'Cosa dice l\'adattatore su se stesso';

  @override
  String get settingsBatteryLabDialogBody =>
      'Queste sono fonti candidate ottenute tramite ingegneria inversa, non documentazione del costruttore né supporto Telltale per il tuo veicolo. Anche un\'interrogazione in sola lettura può risvegliare un controller; un numero decodificato può sembrare plausibile e tuttavia non essere applicabile.';

  @override
  String get settingsBatteryLabDialogTitle =>
      'Attiva il laboratorio della batteria';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      'Il laboratorio della batteria è disattivato per questa sessione, ma non è stato possibile salvare l\'impostazione; al prossimo avvio il laboratorio potrebbe essere mostrato di nuovo e ogni interrogazione richiede comunque una conferma specifica.';

  @override
  String get settingsBatteryLabEnableNotSaved =>
      'Impossibile salvare l\'impostazione del laboratorio della batteria; rimane disattivato.';

  @override
  String get settingsBatteryLabEvidenceAck =>
      'Capisco che i dati della fonte e i test sintetici non dimostrano che questo si applichi al mio veicolo';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      'Mostra soltanto interrogazioni singole in sola lettura le cui fonti sono complete e vincolate a un hash. Non installa PID, non esegue interrogazioni cicliche, non aggiunge indicatori e non considera i dati di ricerca come supporto.';

  @override
  String get settingsBatteryLabSwitchTitle =>
      'Laboratorio della batteria (sperimentale)';

  @override
  String get settingsBatteryLabUnlockReadOnly =>
      'Sblocca solo interrogazioni singole in sola lettura';

  @override
  String get settingsBatteryLabWireAck =>
      'Capisco che questo sblocca solo interrogazioni singole agli indirizzi fissi Mode 21/22 del catalogo: non scansioni, non una sessione diagnostica, non accesso di sicurezza, non scrittura, non controllo';

  @override
  String get settingsCancel => 'Annulla';

  @override
  String get settingsCatalogChoose => 'Scegli dal catalogo ufficiale';

  @override
  String get settingsCatalogCorrupt =>
      'Il catalogo ufficiale offline è danneggiato o non è stato possibile caricarlo; non è stato applicato nulla.';

  @override
  String get settingsCatalogNothingApplicable =>
      'Questa configurazione ufficiale non ha campi applicabili in sicurezza alle formule attuali; il profilo esistente rimane invariato.';

  @override
  String get settingsCatalogScope =>
      'Cataloghi ufficiali: U.S. EPA, Taiwan MOEA, Canada NRCan. Ogni istantanea riguarda soltanto quel mercato, non ogni marca o anno nel mondo.';

  @override
  String get settingsCatalogVerifying => 'Verifica del catalogo offline…';

  @override
  String get settingsCatalogChooseMarket =>
      'Scegli il catalogo ufficiale da consultare';

  @override
  String get settingsCatalogMarketTw =>
      'Taiwan (Amministrazione dell\'energia MOEA)';

  @override
  String get settingsCatalogMarketUs => 'Stati Uniti (EPA)';

  @override
  String get settingsTwCertificationYear => 'Anno di certificazione';

  @override
  String get settingsTwMake => 'Marca Taiwan';

  @override
  String settingsTwPickerScope(int firstYear, int lastYear) {
    return 'Solo righe di certificazione per il mercato di Taiwan dal $firstYear al $lastYear. L\'anno è l\'anno solare della certificazione dell\'Amministrazione dell\'energia, non un anno modello statunitense. Una stringa di marca/modello corrispondente non è una configurazione EPA.';
  }

  @override
  String get settingsTwPickerTitle => 'Catalogo ufficiale veicoli di Taiwan';

  @override
  String get settingsTwReferenceMassNotCurb =>
      'La massa di riferimento del veicolo non è la curb mass e non viene applicata.';

  @override
  String settingsTwWillApplyOnly(String fields) {
    return 'Verranno applicati solo $fields. Massa di riferimento, VE, Cd, area frontale, Crr e rendimento della trasmissione rimangono non determinati.';
  }

  @override
  String get settingsClose => 'Chiudi';

  @override
  String get settingsConnectionSection => 'Connessione';

  @override
  String get settingsDiagnosticsSection => 'Resoconto diagnostico';

  @override
  String get settingsDisconnect => 'Disconnetti';

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return 'Rendimento della trasmissione $percent %';
  }

  @override
  String settingsEpaApplyFields(int count) {
    return 'Applica $count campi ufficiali';
  }

  @override
  String get settingsEpaChooseExact => 'Scegli una configurazione esatta';

  @override
  String get settingsEpaCloseNoFields => 'Chiudi (nessun campo da applicare)';

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'Configurazione EPA $epaId';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count cil';
  }

  @override
  String get settingsEpaDriveUnknown => 'Trazione sconosciuta';

  @override
  String get settingsEpaFuelUnknown => 'Carburante sconosciuto';

  @override
  String get settingsEpaMake => 'Make EPA';

  @override
  String get settingsEpaModel => 'Modello';

  @override
  String get settingsEpaNoConfigurations =>
      'Nessuna configurazione disponibile per questo modello';

  @override
  String get settingsEpaNoSafeFields =>
      'Questa configurazione non ha campi applicabili in sicurezza alle formule attuali; non viene fatta alcuna ipotesi.';

  @override
  String get settingsEpaPickInOrder =>
      'Scegli in ordine anno modello, make EPA (divisione del costruttore) e modello';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return 'Solo configurazioni dell\'istantanea per il mercato statunitense dal $firstYear al $lastYear. Per distinguere i modelli con lo stesso nome servono comunque anno modello, trasmissione, carburante e ID EPA.';
  }

  @override
  String get settingsEpaPickerTitle =>
      'Catalogo ufficiale veicoli EPA degli Stati Uniti';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return 'Verranno applicati solo $fields. Massa, VE, Cd, area frontale, Crr e rendimento della trasmissione rimangono non determinati.';
  }

  @override
  String get settingsEpaYear => 'Anno modello';

  @override
  String get settingsExperimentalSection => 'Sperimentale';

  @override
  String get settingsFieldDisplacement => 'Cilindrata';

  @override
  String get settingsFieldDragCoefficient =>
      'Coefficiente di resistenza aerodinamica Cd';

  @override
  String get settingsFieldDrivetrain => 'Trazione';

  @override
  String get settingsFieldFrontalArea => 'Area frontale';

  @override
  String get settingsFieldFuel => 'Carburante';

  @override
  String get settingsFieldMass => 'Massa';

  @override
  String get settingsFieldMassWithDriver => 'Massa (con conducente)';

  @override
  String get settingsFieldRollingResistance => 'Resistenza al rotolamento Crr';

  @override
  String get settingsFieldVolumetricEfficiency => 'Efficienza volumetrica VE';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return 'Rapporto aria-carburante $afr · densità $density g/L';
  }

  @override
  String get settingsFuelAndDrivetrainSection => 'Carburante e trazione';

  @override
  String get settingsFuelTypeLabel => 'Tipo di carburante';

  @override
  String get settingsGaugeSkinBody =>
      'Non è solo un cambio di colore: ciascuno ha un quadrante, una lancetta e un movimento diversi. Tutti funzionano su sfondi scuri e chiari.';

  @override
  String get settingsGaugeSkinTitle => 'Stile dell\'indicatore';

  @override
  String get settingsGoToConnect => 'Vai a Connessione';

  @override
  String get settingsHeadline => 'Impostazioni';

  @override
  String get settingsLicenseLegalese =>
      'Le fonti della batteria di trazione, le trasformazioni e le condizioni di riutilizzo sono incluse in questa app.';

  @override
  String get settingsListSeparator => ', ';

  @override
  String get settingsManualCommandBody =>
      'Invia un comando direttamente all\'adattatore, per esempio ATI, ATDPN, 0100. Entra nella stessa coda delle normali interrogazioni cicliche e non passa avanti.';

  @override
  String get settingsManualCommandFieldLabel => 'Comando';

  @override
  String get settingsManualCommandNoContent => '(la risposta non ha contenuto)';

  @override
  String get settingsManualCommandSend => 'Invia';

  @override
  String get settingsManualCommandTitle => 'Comando manuale';

  @override
  String get settingsNotConnected => 'Non connesso';

  @override
  String get settingsOpenSourceLicenses => 'Licenze open source e dei dati';

  @override
  String get settingsProfileConfirmAfterConnect =>
      'Connettiti per confermare questo veicolo';

  @override
  String get settingsProfileConfirmButton =>
      'Conferma questo veicolo per questa connessione';

  @override
  String get settingsProfileConfirmedButton =>
      'Confermato per questa connessione';

  @override
  String get settingsProfileConfirmedDetail =>
      'Il profilo è confermato per questa connessione. Se modifichi qualsiasi valore o ti riconnetti, dovrai confermarlo di nuovo.';

  @override
  String get settingsProfileEstimatesIntro =>
      'Potenza in cavalli, coppia e consumo di carburante sono stimati a partire da questi parametri; più rispecchiano il veicolo reale, più le stime sono significative.';

  @override
  String get settingsProfileNameProvesNothing =>
      'Il solo nome di una marca o il solo VIN non stabiliscono massa, resistenza aerodinamica, VE o rendimento della trasmissione.';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      'Non confermato per questa connessione. Le letture OBD misurate vengono comunque mostrate, ma non i valori stimati da massa, VE e resistenza aerodinamica.';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      'Connettiti a questo veicolo prima di confermarlo. La conferma scade a ogni riconnessione, quindi il profilo di un\'auto non viene mai applicato alla successiva.';

  @override
  String get settingsProvenanceNoneExact =>
      'Nessun campo è stato determinato esattamente per questo veicolo; i valori generici, inseriti manualmente e provenienti da fonti meno recenti devono ancora essere tutti confermati.';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return 'Campi con una fonte ufficiale esatta: $fields. Ogni altro campo deve ancora essere confermato singolarmente.';
  }

  @override
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  ) {
    return 'Provenienza: ufficiale o costruttore $official / $total campi · inseriti da te $user / $total · valore generico predefinito $generic / $total · modello scientifico $scientific / $total';
  }

  @override
  String settingsProvenancePublishers(String publishers) {
    return 'Fonti: $publishers';
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
    return 'Determinazione: ufficiali esatti $exact / $total campi · confermati in questa sessione $sessionConfirmed / $total · non determinati $unresolved / $total · ambigui $ambiguous / $total · contrastanti $conflict / $total';
  }

  @override
  String get settingsStandardsFooter =>
      'L\'implementazione OBD2 di questa app segue standard pubblici, tra cui SAE J1979 e la scheda tecnica ELM327; ogni formula e comando AT che influisce sul comportamento dell\'hardware è verificato mediante controlli incrociati e i risultati sono riportati in docs/protocol-deviations.zh-TW.md. Questa app non è affiliata a Torque o Torque Pro.';

  @override
  String get settingsThemeDark => 'Scuro';

  @override
  String get settingsThemeLight => 'Chiaro';

  @override
  String get settingsThemeSystem => 'Segui il sistema';

  @override
  String get settingsVehicleProfileSection => 'Profilo veicolo';

  @override
  String get settingsVinConflict => 'Conflitto VIN';

  @override
  String get settingsVinConflictDetail =>
      'I controller hanno riportato VIN diversi, quindi non è possibile confermare l\'identità del veicolo; tutti i candidati sono stati scartati.';

  @override
  String get settingsVinNotRead => 'VIN non ancora letto';

  @override
  String get settingsVinNotReadConnectedDetail =>
      'Ora è possibile leggere dal veicolo il VIN tramite Mode 09; l\'identità viene conservata solo per questa connessione. Il resoconto diagnostico grezzo potrebbe comunque contenere il VIN.';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      'Una volta connessi, è possibile leggere il VIN che il veicolo dichiara su se stesso; l\'identità non passa alla connessione successiva. Il resoconto diagnostico grezzo potrebbe comunque contenere il VIN.';

  @override
  String get settingsVinRead => 'Leggi VIN';

  @override
  String get settingsVinReading => 'Lettura…';

  @override
  String get settingsVinReportedDetail =>
      'Un VIN è ciò che il veicolo dichiara su se stesso; non verifica le specifiche del modello. L\'identità non passa da una connessione all\'altra; il resoconto diagnostico potrebbe comunque contenere il VIN.';

  @override
  String get settingsVinSimulatorReported => 'VIN segnalato dal simulatore';

  @override
  String get settingsVinUnavailable => 'VIN non disponibile';

  @override
  String get settingsVinUnavailableDetail =>
      'Il veicolo potrebbe non fornirne uno, la risposta potrebbe essere stata incompleta oppure non è stato letto su questa connessione; non viene ipotizzato nulla né viene aggiunto alcun carattere.';

  @override
  String get settingsVinVehicleReported => 'VIN segnalato dal veicolo';

  @override
  String get startupCannotComplete =>
      'Impossibile completare i controlli iniziali';

  @override
  String get startupChecking =>
      'Verifica della cache locale di condivisione e delle registrazioni telemetriche';

  @override
  String get startupRestartHint =>
      'Impossibile verificare la cache locale di condivisione o le registrazioni telemetriche. Chiudi completamente e riapri Telltale per evitare di sovrascrivere, eliminare o condividere il file sbagliato.';

  @override
  String get startupRestartRequired =>
      'Riavvio necessario per continuare in sicurezza';

  @override
  String get startupRetry => 'Riprova';

  @override
  String get startupRetryHint =>
      'Mantieni Telltale in primo piano e riprova dopo il completamento delle altre operazioni sui file. Registrazione, riproduzione, esportazione ed eliminazione restano bloccate fino al completamento dell\'avvio.';

  @override
  String get telemetryArtifactRestartRequired =>
      'Impossibile verificare lo stato delle operazioni sui file locali. Chiudi completamente Telltale e riaprilo prima di continuare';

  @override
  String get telemetryBlockedByRecorder =>
      'Interrompi e salva prima la registrazione';

  @override
  String get telemetryCancel => 'Annulla';

  @override
  String get telemetryDamagedCollision =>
      'Un file completato e uno incompleto condividono questo ID: non ne è stato scelto nessuno';

  @override
  String get telemetryDamagedCorrupt =>
      'La registrazione è danneggiata e non può essere letta in sicurezza';

  @override
  String telemetryDamagedFileTime(String time) {
    return 'Data del file $time';
  }

  @override
  String get telemetryDelete => 'Elimina';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return 'Verrà eliminato $id (data del file $time). L\'operazione non può essere annullata.';
  }

  @override
  String get telemetryDeleteDamagedTitle =>
      'Eliminare questa registrazione danneggiata?';

  @override
  String get telemetryDeleteDamagedTooltip =>
      'Elimina registrazione danneggiata';

  @override
  String telemetryDeleteFailed(String reason) {
    return 'Eliminazione non completata: $reason';
  }

  @override
  String get telemetryDeleteNeedsConfirmation =>
      'Conferma prima l\'eliminazione';

  @override
  String telemetryDeleteSessionBody(String time) {
    return 'Verrà eliminata la registrazione del $time. L\'operazione non può essere annullata.';
  }

  @override
  String get telemetryDeleteSessionTitle =>
      'Eliminare questa registrazione locale?';

  @override
  String get telemetryDemoData => 'Dati del simulatore integrato';

  @override
  String get telemetryDismissNotice => 'Chiudi';

  @override
  String get telemetryEndedByBackground =>
      'Interrotta quando Telltale è passato in background';

  @override
  String get telemetryEndedByConfigurationChanged =>
      'La selezione dei PID è cambiata';

  @override
  String get telemetryEndedByDisconnect =>
      'Interrotta alla caduta della connessione';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return 'Raggiunto il limite di $minutes minuti';
  }

  @override
  String get telemetryEndedByLibrarySizeLimit =>
      'Spazio per le registrazioni locali esaurito';

  @override
  String get telemetryEndedByRecoveredAfterInterruption =>
      'Recuperata dopo l\'ultima interruzione';

  @override
  String get telemetryEndedBySessionReplacement =>
      'La sessione di connessione è stata sostituita';

  @override
  String get telemetryEndedBySessionSizeLimit =>
      'Questa registrazione ha raggiunto il limite di dimensione';

  @override
  String get telemetryEndedByStorageBackpressure =>
      'La scrittura in memoria non è riuscita a tenere il passo';

  @override
  String get telemetryEndedByStorageFailure => 'Salvataggio non riuscito';

  @override
  String get telemetryEndedByUser => 'Interrotta da te';

  @override
  String get telemetryExport => 'Esporta';

  @override
  String get telemetryExportCsv => 'Esporta CSV';

  @override
  String telemetryExportFailed(String reason) {
    return 'Esportazione non completata: $reason';
  }

  @override
  String get telemetryExportJson => 'Esporta JSON';

  @override
  String get telemetryExportSheetTitle => 'Esporta una registrazione locale';

  @override
  String telemetryGapCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lacune',
      one: '1 lacuna',
    );
    return '$_temp0';
  }

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gruppi salvati — riproduci ed esporta offline',
      one: '1 gruppo salvato — riproduci ed esporta offline',
    );
    return '$_temp0';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit gruppi';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count altri gruppi non mostrati',
      one: '1 altro gruppo non mostrato',
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
    return 'Memoria locale: $groups gruppi su $groupLimit, $used MiB su $byteLimit';
  }

  @override
  String get telemetryNotConnected => 'Non connesso';

  @override
  String get telemetryOfflineSampledReplay => 'Riproduzione offline campionata';

  @override
  String get telemetryOpenHistory => 'Apri registrazioni locali';

  @override
  String get telemetryPause => 'Pausa';

  @override
  String get telemetryPendingOwnerRecovery =>
      'Questo processo mantiene ancora bloccata l\'operazione. Se rimane così, chiudi completamente Telltale e riaprilo';

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetryPlay => 'Riproduci';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return 'Registra solo i segnali OBD che hai attivato, senza posizione, VIN o dati dell\'account. Gli andamenti mostrano al massimo $laneLimit segnali; una registrazione conserva tutti i $activeCount segnali attivati e aggiunge la potenza stimata in cavalli e la portata carburante stimata, basate sulle ipotesi relative al veicolo.';
  }

  @override
  String get telemetryRecorderPhaseAwaitingValues =>
      'Registrazione in corso — ancora nessun valore';

  @override
  String get telemetryRecorderPhaseCompleted => 'Registrazione salvata';

  @override
  String get telemetryRecorderPhaseFailed =>
      'Salvataggio della registrazione non riuscito';

  @override
  String get telemetryRecorderPhaseFinalizing =>
      'Salvataggio della registrazione';

  @override
  String get telemetryRecorderPhaseIdle =>
      'Registrazione locale in primo piano';

  @override
  String get telemetryRecorderPhasePreparing =>
      'Preparazione della registrazione';

  @override
  String get telemetryRecorderPhaseRecording => 'Registrazione in corso';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return 'Registrazione $duration';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count file incompleti senza valori validi sono stati rimossi',
      one: '1 file incompleto senza valori validi è stato rimosso',
    );
    return '$_temp0';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count file danneggiati o in conflitto sono stati lasciati invariati',
      one: '1 file danneggiato o in conflitto è stato lasciato invariato',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryDamagedNote =>
      'I contenuti danneggiati non vengono mai usati per la riproduzione o l\'esportazione e possono essere eliminati solo manualmente quando è sicuro farlo.';

  @override
  String telemetryRecoveryInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registrazioni interrotte sono state chiuse in sicurezza',
      one: '1 registrazione interrotta è stata chiusa in sicurezza',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryTitle =>
      'Controllo iniziale delle registrazioni completato';

  @override
  String get telemetryReload => 'Ricarica';

  @override
  String telemetryReplayBreakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count interruzioni',
      one: '1 interruzione',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayLoadFailed =>
      'Impossibile caricare la registrazione';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return 'Posizione di riproduzione $percent%';
  }

  @override
  String telemetryReplaySampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count punti campionati',
      one: '1 punto campionato',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayTitle => 'Riproduzione registrazione';

  @override
  String get telemetryReplayUnreadable =>
      'La registrazione è danneggiata o non può essere letta';

  @override
  String get telemetryRestartToRepairSave =>
      'Salvataggio non completato — riavvia Telltale per riparare le registrazioni';

  @override
  String get telemetryRestartToRepairStartup =>
      'Pulizia all\'avvio non completata — riavvia Telltale per riparare le registrazioni';

  @override
  String get telemetryReturnToTrends => 'Torna agli andamenti';

  @override
  String get telemetryRigData => 'Dati del banco di prova';

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetrySessionsDamaged => 'File di registrazione danneggiati';

  @override
  String get telemetrySessionsEmpty =>
      'Nessuna registrazione locale\nConnettiti, poi avvia una registrazione';

  @override
  String get telemetrySessionsLoadFailed => 'Impossibile caricare — riprova';

  @override
  String get telemetrySessionsReplayable => 'Registrazioni riproducibili';

  @override
  String get telemetrySessionsTitle => 'Registrazioni locali';

  @override
  String telemetrySignalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count segnali',
      one: '1 segnale',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStartBusy =>
      'Un\'altra registrazione o operazione sui file non è terminata';

  @override
  String get telemetryStartCannotCreateFile =>
      'Impossibile creare il file della registrazione';

  @override
  String get telemetryStartInvalidConfiguration =>
      'Questa selezione di PID non può essere registrata in sicurezza — controlla le definizioni';

  @override
  String get telemetryStartInvalidatedBackground =>
      'Telltale è passato in background — nessuna registrazione avviata';

  @override
  String get telemetryStartInvalidatedDisconnect =>
      'La connessione è caduta — nessuna registrazione avviata';

  @override
  String get telemetryStartInvalidatedSessionReplacement =>
      'La sessione di connessione è stata sostituita — nessuna registrazione avviata';

  @override
  String get telemetryStartLibraryByteLimit =>
      'Spazio locale insufficiente per una registrazione — prima esportane o eliminane alcune';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return 'Le registrazioni locali hanno raggiunto il limite di $limit — prima esportane o eliminane alcune';
  }

  @override
  String get telemetryStartMoving => 'Parcheggia prima il veicolo';

  @override
  String get telemetryStartNeedsActivePid => 'Attiva prima almeno un PID';

  @override
  String get telemetryStartNeedsConnection =>
      'Connettiti prima di avviare una registrazione';

  @override
  String get telemetryStartNeedsForeground =>
      'Porta Telltale in primo piano prima di avviare una registrazione';

  @override
  String get telemetryStartRecording => 'Registrazione avviata';

  @override
  String get telemetryStartRecordingButton => 'Avvia registrazione';

  @override
  String get telemetryStartSpeedUnknown =>
      'Impossibile confermare che il veicolo sia fermo — disconnettiti prima';

  @override
  String get telemetryStartTooManyPids =>
      'La registrazione conserva le colonne di potenza stimata e portata carburante stimata — disattiva prima alcuni PID';

  @override
  String get telemetryStarting => 'Avvio in corso';

  @override
  String get telemetryStatusBusError => 'Errore del bus';

  @override
  String telemetryStatusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stati',
      one: '1 stato',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStatusFormulaError => 'Errore nella formula';

  @override
  String get telemetryStatusHeaderMismatch =>
      'L\'intestazione non corrisponde a questo bus';

  @override
  String get telemetryStatusNoAnswer =>
      'Nessuna risposta — nuovo tentativo in seguito';

  @override
  String get telemetryStatusStale => 'Dati non aggiornati';

  @override
  String get telemetryStatusUnsafeServiceRefusal =>
      'Non è una richiesta in sola lettura — non è stato inviato nulla';

  @override
  String get telemetryStatusUnsupported =>
      'Il controller ha risposto che non lo supporta';

  @override
  String get telemetryStopAndSave => 'Interrompi e salva';

  @override
  String telemetryValueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count valori validi',
      one: '1 valore valido',
    );
    return '$_temp0';
  }

  @override
  String get transcriptDelete => 'Elimina';

  @override
  String get transcriptDeleteBusy =>
      'Un\'altra operazione sui file non è terminata.';

  @override
  String get transcriptDeleteFailed =>
      'Impossibile eliminare il resoconto diagnostico della connessione precedente.';

  @override
  String get transcriptDeleteRefusedBySafety =>
      'La velocità o lo stato della connessione attuali non consentono di eliminare il resoconto diagnostico.';

  @override
  String get transcriptExport => 'Esporta';

  @override
  String get transcriptExportButton => 'Esporta resoconto diagnostico';

  @override
  String get transcriptExportExplanation =>
      'Questa connessione conserva la negoziazione iniziale e il traffico grezzo più recente; se una connessione lunga perde la parte centrale, il file lo segnala. Quando qualcosa non si riesce a leggere sul veicolo, esportare e riportare il resoconto diagnostico è molto più utile di un singolo messaggio sullo schermo.';

  @override
  String transcriptExportFailed(String error) {
    return 'Esportazione non riuscita: $error';
  }

  @override
  String get transcriptExportWithHex => 'Con dati esadecimali';

  @override
  String get transcriptNothingToExport =>
      'Non c\'è alcun resoconto diagnostico da esportare.';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return 'Rimasto dal $timestamp, $size. Si è conservato nonostante la chiusura di Telltale da parte del sistema o la perdita di alimentazione del telefono.';
  }

  @override
  String get transcriptRecoveredChanged =>
      'Il resoconto diagnostico della connessione precedente è cambiato — controllalo di nuovo.';

  @override
  String get transcriptRecoveredTitle =>
      'Resoconto diagnostico della connessione precedente';

  @override
  String transcriptSizeBytes(int bytes) {
    String _temp0 = intl.Intl.pluralLogic(
      bytes,
      locale: localeName,
      other: '$bytes byte',
      one: '1 byte',
    );
    return '$_temp0';
  }

  @override
  String get trendAxisNow => 'Ora';

  @override
  String get trendChooseSignals => 'Scegli segnali';

  @override
  String get trendLiveData => 'Dati in tempo reale';

  @override
  String get trendNoSignalsBody =>
      'Attiva prima nella pagina PID i segnali che vuoi osservare.';

  @override
  String get trendNoSignalsTitle => 'Nessun segnale di andamento disponibile';

  @override
  String get trendNoUnits => 'Nessuna unità';

  @override
  String trendPickSignalsBody(int limit) {
    return 'Confronta fino a $limit segnali. Questo non cambia i PID interrogati ciclicamente.';
  }

  @override
  String get trendPickSignalsTitle => 'Scegli segnali di andamento';

  @override
  String trendRemoveSignal(String name) {
    return 'Rimuovi $name';
  }

  @override
  String get trendSelectionSaveFailed =>
      'Impossibile salvare la selezione di visualizzazione degli andamenti';

  @override
  String trendSheetBody(int limit) {
    return 'Scegli al massimo $limit. Questo modifica solo il grafico, non l\'interrogazione ciclica dei PID né una registrazione in corso.';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return 'Fine · $selected/$limit';
  }

  @override
  String get trendSignalNoLongerActive =>
      'Uno di questi segnali non è più nell\'elenco dei PID osservati';

  @override
  String get trendSignalsHeading => 'Segnali di andamento';

  @override
  String trendTooManySelected(int limit) {
    return 'Scegli al massimo $limit';
  }

  @override
  String trendWindowSemantics(int seconds) {
    return 'Sono mostrati gli ultimi $seconds secondi';
  }

  @override
  String get wearBack => 'Indietro';

  @override
  String get wearBatteryVoltageLabel => 'Batteria';

  @override
  String get wearBleAdapters => 'Adattatori BLE';

  @override
  String get wearCancel => 'Annulla';

  @override
  String get wearConfirmVehicle => 'Conferma veicolo';

  @override
  String get wearConfirmVehicleAccept => 'Sì, questa auto';

  @override
  String get wearConfirmVehicleBody =>
      'Dopo la conferma, le interrogazioni della batteria in sola lettura per questo modello si ripetono ciclicamente per il resto della connessione. Il modello sbagliato può restituire un numero plausibile ma errato: annulla se non sei sicuro.';

  @override
  String wearConnectFailed(String adapter) {
    return 'Impossibile connettersi: $adapter';
  }

  @override
  String get wearConnecting => 'Connessione…';

  @override
  String get wearDemoSimulator => 'Simulatore demo';

  @override
  String get wearDisconnect => 'Disconnetti';

  @override
  String get wearDisconnectQuestion => 'Disconnettere?';

  @override
  String get wearNoDevicesFound => 'Nessun dispositivo trovato';

  @override
  String get wearPermissionBluetooth => 'Bluetooth';

  @override
  String get wearPermissionLocation => 'Posizione';

  @override
  String get wearScanAgain => 'Ripeti scansione';

  @override
  String get wearScanFailed => 'Scansione non riuscita — riprova';

  @override
  String wearScanPermissionNeeded(String permission) {
    return 'La scansione richiede l\'autorizzazione $permission';
  }

  @override
  String wearScanPermissionPermanentlyDenied(String permission) {
    return 'L\'autorizzazione $permission è stata negata definitivamente — attivala nelle impostazioni di sistema e riprova';
  }

  @override
  String get wearScanning => 'Scansione…';

  @override
  String get telemetryRecorderNotRecording => 'Non in registrazione';

  @override
  String get dtcKindStored => 'Memorizzato';

  @override
  String get dtcKindPending => 'In attesa di conferma';

  @override
  String get dtcKindPermanent => 'Permanente';

  @override
  String get dtcKindStoredExplanation =>
      'Un guasto confermato; la spia di avaria sul cruscotto è solitamente accesa.';

  @override
  String get dtcKindPendingExplanation =>
      'Rilevato una volta e non ha ancora raggiunto la soglia di conferma.';

  @override
  String get dtcKindPermanentExplanation =>
      'Non può essere cancellato con uno strumento diagnostico. La ECU lo cancella da sola e solo dopo aver confermato la riparazione.';

  @override
  String get dtcSystemPowertrain => 'Gruppo propulsore';

  @override
  String get dtcSystemChassis => 'Telaio';

  @override
  String get dtcSystemBody => 'Carrozzeria';

  @override
  String get dtcSystemNetwork => 'Rete';

  @override
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions =>
      'Dosaggio carburante e aria e controlli ausiliari delle emissioni';

  @override
  String get dtcSubsystemFuelAirMetering => 'Dosaggio carburante e aria';

  @override
  String get dtcSubsystemFuelAirMeteringInjectorCircuit =>
      'Dosaggio carburante e aria (circuito iniettore)';

  @override
  String get dtcSubsystemIgnitionOrMisfire =>
      'Sistema di accensione o mancate accensioni';

  @override
  String get dtcSubsystemAuxiliaryEmissionControls =>
      'Controlli ausiliari delle emissioni';

  @override
  String get dtcSubsystemSpeedAndIdleControl =>
      'Sistema di controllo della velocità del veicolo e del minimo';

  @override
  String get dtcSubsystemComputerOutputCircuit =>
      'Circuito di uscita della centralina';

  @override
  String get dtcSubsystemTransmission => 'Trasmissione';

  @override
  String get dtcSubsystemControlModuleSignals =>
      'Centraline, segnali di ingresso e di uscita';

  @override
  String get dtcDescriptionB0001 =>
      'Guasto al controllo di attivazione dell\'airbag conducente';

  @override
  String get dtcDescriptionP0011 =>
      'Posizione albero a camme A — fasatura troppo anticipata o prestazioni del sistema (bancata 1)';

  @override
  String get dtcDescriptionP0014 =>
      'Posizione albero a camme B — fasatura troppo anticipata o prestazioni del sistema (bancata 1)';

  @override
  String get dtcDescriptionP0016 =>
      'Correlazione posizione albero motore e albero a camme (bancata 1 sensore A)';

  @override
  String get dtcDescriptionP0087 =>
      'Pressione del rail o del sistema carburante troppo bassa';

  @override
  String get dtcDescriptionP0088 =>
      'Pressione del rail o del sistema carburante troppo alta';

  @override
  String get dtcDescriptionP0100 =>
      'Malfunzionamento del circuito del sensore di massa aria (MAF)';

  @override
  String get dtcDescriptionP0101 =>
      'Problema di intervallo o prestazioni del sensore di massa aria';

  @override
  String get dtcDescriptionP0102 =>
      'Segnale di ingresso basso nel circuito del sensore di massa aria';

  @override
  String get dtcDescriptionP0103 =>
      'Segnale di ingresso alto nel circuito del sensore di massa aria';

  @override
  String get dtcDescriptionP0105 =>
      'Malfunzionamento del circuito del sensore di pressione assoluta del collettore o pressione barometrica';

  @override
  String get dtcDescriptionP0106 =>
      'Problema di intervallo o prestazioni del sensore di pressione assoluta del collettore';

  @override
  String get dtcDescriptionP0107 =>
      'Segnale di ingresso basso nel circuito del sensore di pressione assoluta del collettore';

  @override
  String get dtcDescriptionP0108 =>
      'Segnale di ingresso alto nel circuito del sensore di pressione assoluta del collettore';

  @override
  String get dtcDescriptionP0110 =>
      'Malfunzionamento del circuito del sensore di temperatura dell\'aria aspirata';

  @override
  String get dtcDescriptionP0111 =>
      'Problema di intervallo o prestazioni del sensore di temperatura dell\'aria aspirata';

  @override
  String get dtcDescriptionP0112 =>
      'Segnale di ingresso basso nel circuito del sensore di temperatura dell\'aria aspirata';

  @override
  String get dtcDescriptionP0113 =>
      'Segnale di ingresso alto nel circuito del sensore di temperatura dell\'aria aspirata';

  @override
  String get dtcDescriptionP0115 =>
      'Malfunzionamento del circuito del sensore di temperatura del liquido refrigerante motore';

  @override
  String get dtcDescriptionP0116 =>
      'Problema di intervallo o prestazioni del sensore di temperatura del liquido refrigerante motore';

  @override
  String get dtcDescriptionP0117 =>
      'Segnale di ingresso basso nel circuito del sensore di temperatura del liquido refrigerante motore';

  @override
  String get dtcDescriptionP0118 =>
      'Segnale di ingresso alto nel circuito del sensore di temperatura del liquido refrigerante motore';

  @override
  String get dtcDescriptionP0120 =>
      'Malfunzionamento del circuito del sensore di posizione della farfalla';

  @override
  String get dtcDescriptionP0121 =>
      'Problema di intervallo o prestazioni del sensore di posizione della farfalla';

  @override
  String get dtcDescriptionP0122 =>
      'Segnale di ingresso basso nel circuito del sensore di posizione della farfalla';

  @override
  String get dtcDescriptionP0123 =>
      'Segnale di ingresso alto nel circuito del sensore di posizione della farfalla';

  @override
  String get dtcDescriptionP0125 =>
      'Temperatura del liquido refrigerante insufficiente per il controllo carburante ad anello chiuso';

  @override
  String get dtcDescriptionP0128 =>
      'Temperatura del liquido refrigerante inferiore a quella di regolazione del termostato';

  @override
  String get dtcDescriptionP0130 =>
      'Malfunzionamento del circuito del sensore di ossigeno (bancata 1 sensore 1)';

  @override
  String get dtcDescriptionP0131 =>
      'Tensione bassa nel circuito del sensore di ossigeno (bancata 1 sensore 1)';

  @override
  String get dtcDescriptionP0132 =>
      'Tensione alta nel circuito del sensore di ossigeno (bancata 1 sensore 1)';

  @override
  String get dtcDescriptionP0133 =>
      'Risposta lenta del circuito del sensore di ossigeno (bancata 1 sensore 1)';

  @override
  String get dtcDescriptionP0134 =>
      'Nessuna attività rilevata nel circuito del sensore di ossigeno (bancata 1 sensore 1)';

  @override
  String get dtcDescriptionP0135 =>
      'Malfunzionamento del circuito di riscaldamento del sensore di ossigeno (bancata 1 sensore 1)';

  @override
  String get dtcDescriptionP0136 =>
      'Malfunzionamento del circuito del sensore di ossigeno (bancata 1 sensore 2)';

  @override
  String get dtcDescriptionP0137 =>
      'Tensione bassa nel circuito del sensore di ossigeno (bancata 1 sensore 2)';

  @override
  String get dtcDescriptionP0138 =>
      'Tensione alta nel circuito del sensore di ossigeno (bancata 1 sensore 2)';

  @override
  String get dtcDescriptionP0140 =>
      'Nessuna attività rilevata nel circuito del sensore di ossigeno (bancata 1 sensore 2)';

  @override
  String get dtcDescriptionP0141 =>
      'Malfunzionamento del circuito di riscaldamento del sensore di ossigeno (bancata 1 sensore 2)';

  @override
  String get dtcDescriptionP0150 =>
      'Malfunzionamento del circuito del sensore di ossigeno (bancata 2 sensore 1)';

  @override
  String get dtcDescriptionP0155 =>
      'Malfunzionamento del circuito di riscaldamento del sensore di ossigeno (bancata 2 sensore 1)';

  @override
  String get dtcDescriptionP0156 =>
      'Malfunzionamento del circuito del sensore di ossigeno (bancata 2 sensore 2)';

  @override
  String get dtcDescriptionP0161 =>
      'Malfunzionamento del circuito di riscaldamento del sensore di ossigeno (bancata 2 sensore 2)';

  @override
  String get dtcDescriptionP0170 =>
      'Malfunzionamento della correzione carburante (bancata 1)';

  @override
  String get dtcDescriptionP0171 => 'Miscela troppo magra (bancata 1)';

  @override
  String get dtcDescriptionP0172 => 'Miscela troppo ricca (bancata 1)';

  @override
  String get dtcDescriptionP0173 =>
      'Malfunzionamento della correzione carburante (bancata 2)';

  @override
  String get dtcDescriptionP0174 => 'Miscela troppo magra (bancata 2)';

  @override
  String get dtcDescriptionP0175 => 'Miscela troppo ricca (bancata 2)';

  @override
  String get dtcDescriptionP0190 =>
      'Malfunzionamento del circuito del sensore di pressione del rail carburante';

  @override
  String get dtcDescriptionP0201 =>
      'Malfunzionamento o circuito aperto dell\'iniettore — cilindro 1';

  @override
  String get dtcDescriptionP0202 =>
      'Malfunzionamento o circuito aperto dell\'iniettore — cilindro 2';

  @override
  String get dtcDescriptionP0203 =>
      'Malfunzionamento o circuito aperto dell\'iniettore — cilindro 3';

  @override
  String get dtcDescriptionP0204 =>
      'Malfunzionamento o circuito aperto dell\'iniettore — cilindro 4';

  @override
  String get dtcDescriptionP0217 => 'Temperatura del motore eccessiva';

  @override
  String get dtcDescriptionP0221 =>
      'Problema di intervallo o prestazioni del sensore B di posizione della farfalla o del pedale';

  @override
  String get dtcDescriptionP0222 =>
      'Segnale di ingresso basso nel circuito del sensore B di posizione della farfalla o del pedale';

  @override
  String get dtcDescriptionP0223 =>
      'Segnale di ingresso alto nel circuito del sensore B di posizione della farfalla o del pedale';

  @override
  String get dtcDescriptionP0234 =>
      'Pressione di sovralimentazione del turbocompressore o compressore eccessiva';

  @override
  String get dtcDescriptionP0299 =>
      'Pressione di sovralimentazione del turbocompressore o compressore A insufficiente';

  @override
  String get dtcDescriptionP0300 =>
      'Rilevate mancate accensioni casuali o su più cilindri';

  @override
  String get dtcDescriptionP0301 =>
      'Rilevata mancata accensione nel cilindro 1';

  @override
  String get dtcDescriptionP0302 =>
      'Rilevata mancata accensione nel cilindro 2';

  @override
  String get dtcDescriptionP0303 =>
      'Rilevata mancata accensione nel cilindro 3';

  @override
  String get dtcDescriptionP0304 =>
      'Rilevata mancata accensione nel cilindro 4';

  @override
  String get dtcDescriptionP0305 =>
      'Rilevata mancata accensione nel cilindro 5';

  @override
  String get dtcDescriptionP0306 =>
      'Rilevata mancata accensione nel cilindro 6';

  @override
  String get dtcDescriptionP0307 =>
      'Rilevata mancata accensione nel cilindro 7';

  @override
  String get dtcDescriptionP0308 =>
      'Rilevata mancata accensione nel cilindro 8';

  @override
  String get dtcDescriptionP0316 =>
      'Rilevata mancata accensione subito dopo l\'avviamento';

  @override
  String get dtcDescriptionP0325 =>
      'Malfunzionamento del circuito del sensore di detonazione (bancata 1)';

  @override
  String get dtcDescriptionP0326 =>
      'Problema di intervallo o prestazioni del sensore di detonazione (bancata 1)';

  @override
  String get dtcDescriptionP0327 =>
      'Segnale di ingresso basso nel circuito del sensore di detonazione (bancata 1)';

  @override
  String get dtcDescriptionP0328 =>
      'Segnale di ingresso alto nel circuito del sensore di detonazione (bancata 1)';

  @override
  String get dtcDescriptionP0330 =>
      'Malfunzionamento del circuito del sensore di detonazione (bancata 2)';

  @override
  String get dtcDescriptionP0335 =>
      'Malfunzionamento del circuito del sensore di posizione dell\'albero motore';

  @override
  String get dtcDescriptionP0336 =>
      'Problema di intervallo o prestazioni del sensore di posizione dell\'albero motore';

  @override
  String get dtcDescriptionP0340 =>
      'Malfunzionamento del circuito del sensore di posizione dell\'albero a camme';

  @override
  String get dtcDescriptionP0341 =>
      'Problema di intervallo o prestazioni del sensore di posizione dell\'albero a camme';

  @override
  String get dtcDescriptionP0351 =>
      'Malfunzionamento del circuito primario o secondario della bobina di accensione A';

  @override
  String get dtcDescriptionP0352 =>
      'Malfunzionamento del circuito primario o secondario della bobina di accensione B';

  @override
  String get dtcDescriptionP0353 =>
      'Malfunzionamento del circuito primario o secondario della bobina di accensione C';

  @override
  String get dtcDescriptionP0354 =>
      'Malfunzionamento del circuito primario o secondario della bobina di accensione D';

  @override
  String get dtcDescriptionP0355 =>
      'Malfunzionamento del circuito primario o secondario della bobina di accensione E';

  @override
  String get dtcDescriptionP0356 =>
      'Malfunzionamento del circuito primario o secondario della bobina di accensione F';

  @override
  String get dtcDescriptionP0400 =>
      'Malfunzionamento del flusso di ricircolo dei gas di scarico (EGR)';

  @override
  String get dtcDescriptionP0401 =>
      'Flusso di ricircolo dei gas di scarico (EGR) insufficiente';

  @override
  String get dtcDescriptionP0402 =>
      'Flusso di ricircolo dei gas di scarico (EGR) eccessivo';

  @override
  String get dtcDescriptionP0403 =>
      'Malfunzionamento del circuito di controllo del ricircolo dei gas di scarico (EGR)';

  @override
  String get dtcDescriptionP0404 =>
      'Problema di intervallo o prestazioni del circuito di controllo del ricircolo dei gas di scarico (EGR)';

  @override
  String get dtcDescriptionP0410 =>
      'Malfunzionamento del sistema di iniezione aria secondaria';

  @override
  String get dtcDescriptionP0411 =>
      'Rilevato flusso errato nel sistema di iniezione aria secondaria';

  @override
  String get dtcDescriptionP0412 =>
      'Malfunzionamento del circuito della valvola di commutazione A del sistema di iniezione aria secondaria';

  @override
  String get dtcDescriptionP0420 =>
      'Efficienza del catalizzatore sotto la soglia (bancata 1)';

  @override
  String get dtcDescriptionP0430 =>
      'Efficienza del catalizzatore sotto la soglia (bancata 2)';

  @override
  String get dtcDescriptionP0440 =>
      'Malfunzionamento del sistema di controllo delle emissioni evaporative';

  @override
  String get dtcDescriptionP0441 =>
      'Flusso di spurgo errato nel sistema delle emissioni evaporative';

  @override
  String get dtcDescriptionP0442 =>
      'Perdita rilevata nel sistema delle emissioni evaporative (piccola perdita)';

  @override
  String get dtcDescriptionP0443 =>
      'Malfunzionamento del circuito della valvola di controllo spurgo del sistema delle emissioni evaporative';

  @override
  String get dtcDescriptionP0446 =>
      'Malfunzionamento del circuito di controllo sfiato del sistema delle emissioni evaporative';

  @override
  String get dtcDescriptionP0447 =>
      'Circuito di controllo sfiato del sistema delle emissioni evaporative aperto';

  @override
  String get dtcDescriptionP0449 =>
      'Malfunzionamento del circuito della valvola o elettrovalvola di sfiato del sistema delle emissioni evaporative';

  @override
  String get dtcDescriptionP0451 =>
      'Problema di intervallo o prestazioni del sensore di pressione del sistema delle emissioni evaporative';

  @override
  String get dtcDescriptionP0452 =>
      'Segnale di ingresso basso nel circuito del sensore di pressione del sistema delle emissioni evaporative';

  @override
  String get dtcDescriptionP0453 =>
      'Segnale di ingresso alto nel circuito del sensore di pressione del sistema delle emissioni evaporative';

  @override
  String get dtcDescriptionP0455 =>
      'Perdita rilevata nel sistema delle emissioni evaporative (perdita grande)';

  @override
  String get dtcDescriptionP0456 =>
      'Perdita rilevata nel sistema delle emissioni evaporative (perdita molto piccola)';

  @override
  String get dtcDescriptionP0480 =>
      'Malfunzionamento del circuito di controllo della ventola di raffreddamento 1';

  @override
  String get dtcDescriptionP0500 =>
      'Malfunzionamento del sensore di velocità del veicolo';

  @override
  String get dtcDescriptionP0505 =>
      'Malfunzionamento del sistema di controllo del minimo';

  @override
  String get dtcDescriptionP0506 =>
      'Giri motore del sistema di controllo del minimo inferiori al previsto';

  @override
  String get dtcDescriptionP0507 =>
      'Giri motore del sistema di controllo del minimo superiori al previsto';

  @override
  String get dtcDescriptionP0508 =>
      'Segnale basso nel circuito del sistema di controllo del minimo';

  @override
  String get dtcDescriptionP0509 =>
      'Segnale alto nel circuito del sistema di controllo del minimo';

  @override
  String get dtcDescriptionP0560 =>
      'Malfunzionamento della tensione del sistema';

  @override
  String get dtcDescriptionP0562 => 'Tensione del sistema bassa';

  @override
  String get dtcDescriptionP0563 => 'Tensione del sistema alta';

  @override
  String get dtcDescriptionP0603 =>
      'Errore della memoria di mantenimento (KAM) interna alla centralina';

  @override
  String get dtcDescriptionP0605 =>
      'Errore della memoria di sola lettura (ROM) interna alla centralina';

  @override
  String get dtcDescriptionP0606 => 'Guasto al processore ECM/PCM';

  @override
  String get dtcDescriptionP0700 =>
      'La centralina di controllo della trasmissione ha richiesto l\'accensione della spia di avaria — il codice guasto si trova nella centralina della trasmissione e deve essere letto separatamente';

  @override
  String get dtcDescriptionP0701 =>
      'Problema di intervallo o prestazioni del sistema di controllo della trasmissione';

  @override
  String get dtcDescriptionP0702 =>
      'Guasto elettrico del sistema di controllo della trasmissione';

  @override
  String get dtcDescriptionP0705 =>
      'Malfunzionamento del circuito del sensore di posizione della trasmissione';

  @override
  String get dtcDescriptionP0715 =>
      'Malfunzionamento del circuito del sensore di velocità in ingresso o della turbina';

  @override
  String get dtcDescriptionP0720 =>
      'Malfunzionamento del circuito del sensore di velocità in uscita';

  @override
  String get dtcDescriptionP0730 => 'Rapporto di trasmissione errato';

  @override
  String get dtcDescriptionP0740 =>
      'Malfunzionamento del circuito della frizione del convertitore di coppia';

  @override
  String get dtcDescriptionP0741 =>
      'Frizione del convertitore di coppia bloccata in posizione disinserita';

  @override
  String get dtcDescriptionP0750 =>
      'Malfunzionamento dell\'elettrovalvola cambio A';

  @override
  String get dtcDescriptionP0755 =>
      'Malfunzionamento dell\'elettrovalvola cambio B';

  @override
  String get dtcDescriptionP2135 =>
      'Correlazione tensione sensori posizione farfalla A/B';

  @override
  String get dtcDescriptionU0100 => 'Comunicazione persa con ECM/PCM';

  @override
  String get dtcDescriptionU0101 =>
      'Comunicazione persa con la centralina della trasmissione';

  @override
  String get dtcDescriptionU0121 => 'Comunicazione persa con la centralina ABS';

  @override
  String get dtcDescriptionU0140 =>
      'Comunicazione persa con la centralina carrozzeria';

  @override
  String get dtcDescriptionU0155 =>
      'Comunicazione persa con la centralina del quadro strumenti';

  @override
  String get gaugeSkinCluster => 'Quadro strumenti';

  @override
  String get gaugeSkinClusterDescription =>
      'Come un quadro strumenti di serie. Lancetta, quadrante a 270 gradi, fondo incassato.';

  @override
  String get gaugeSkinMinimal => 'Essenziale';

  @override
  String get gaugeSkinMinimalDescription =>
      'Mezzo arco, senza lancetta né tacche. Leggi il numero, non il movimento.';

  @override
  String get gaugeSkinTrack => 'Pista';

  @override
  String get gaugeSkinTrackDescription =>
      'Barra a segmenti, senza interpolazione. Il valore arriva esattamente dove arriva, senza passaggi intermedi.';

  @override
  String get gaugeSkinClassic => 'Classico';

  @override
  String get gaugeSkinClassicDescription =>
      'Quadrante stampato, numeri lungo tutta la circonferenza e una lancetta che si assesta lentamente, come un orologio meccanico.';

  @override
  String get gaugeSkinNight => 'Notte';

  @override
  String get gaugeSkinNightDescription =>
      'Per guidare al buio. Luminosità ridotta, arco poco pronunciato, nessuna animazione: richiede la minima attenzione possibile.';

  @override
  String get derivedAirflowSourceMaf => 'Sensore MAF';

  @override
  String get derivedAirflowSourceSpeedDensity => 'Stima speed-density';

  @override
  String get derivedAirflowSourceUnavailable => 'Massa d\'aria non disponibile';

  @override
  String get derivedFuelSourceStoichiometric => 'Stima stechiometrica';

  @override
  String get derivedFuelSourceUnavailable =>
      'Portata carburante non disponibile';

  @override
  String get telemetrySourceDemo => 'Simulatore integrato';

  @override
  String get telemetrySourceRig => 'Banco di prova';

  @override
  String get telemetrySourceFieldApp =>
      'Connessione dell\'app su veicolo reale';

  @override
  String get fuelTypeGasoline => 'Benzina';

  @override
  String get fuelTypeDiesel => 'Diesel';

  @override
  String get fuelTypeLpg => 'GPL';

  @override
  String get fuelTypeEthanolE85 => 'Etanolo E85';

  @override
  String get drivetrainFwd => 'Trazione anteriore';

  @override
  String get drivetrainRwd => 'Trazione posteriore';

  @override
  String get drivetrainAwd => 'Trazione integrale';

  @override
  String get assumptionFieldMass => 'Massa';

  @override
  String get assumptionFieldDragCoefficient => 'Cd';

  @override
  String get assumptionFieldFrontalArea => 'Area frontale';

  @override
  String get assumptionFieldRollingResistance => 'Resistenza al rotolamento';

  @override
  String get assumptionFieldDrivetrainEfficiency =>
      'Rendimento della trasmissione';

  @override
  String get assumptionFieldFuelType => 'Carburante';

  @override
  String get assumptionFieldStoichAfr => 'AFR';

  @override
  String get assumptionFieldFuelDensity => 'Densità';

  @override
  String get assumptionFieldDisplacement => 'Cilindrata';

  @override
  String get assumptionFieldVolumetricEfficiency => 'VE';

  @override
  String get vehicleFieldOriginGenericDefault => 'valore generico predefinito';

  @override
  String get vehicleFieldOriginUserEntered => 'inserito da te';

  @override
  String get vehicleFieldOriginOfficialRegistry => 'registro ufficiale';

  @override
  String get vehicleFieldOriginManufacturerPublication =>
      'dati del costruttore';

  @override
  String get vehicleFieldOriginScientificModel => 'coefficiente del modello';

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
      'L/h = (MAF g/s) / (AFR × densità carburante g/L) × 3600; MAF è PID 0110 oppure speed-density (RPM × MAP × cilindrata × VE / T_K); L/100km = (L/h) / speed_kmh × 100';

  @override
  String get datumAssumptionsFromRecording =>
      'La stima usa le impostazioni del veicolo in vigore al momento della registrazione.';

  @override
  String adapterConcernFirmwareNeverReleasedSummary(String version) {
    return 'Dichiara il firmware v$version, mai pubblicato';
  }

  @override
  String get adapterConcernFirmwareNeverReleasedDetail =>
      'Elm Electronics non ha mai pubblicato questa versione, quindi il firmware di questo adattatore non è quello dichiarato. Molti di questi adattatori funzionano comunque, ma la descrizione che danno di sé non è affidabile: quando una lettura non riesce, conviene sospettare prima dell\'adattatore.';

  @override
  String adapterConcernPpsRefusedSummary(String version) {
    return 'Dichiara v$version, ma non conosce ATPPS, già presente nella v1.1';
  }

  @override
  String get adapterConcernPpsRefusedDetail =>
      'Il riepilogo dei parametri programmabili (ATPPS) esiste da ELM327 v1.1 ed è supportato anche da adattatori di fascia alta come OBDLink. La versione dichiarata e i comandi effettivamente implementati non corrispondono.';

  @override
  String get adapterConcernNoIdentitySummary =>
      'Non risponde ad AT@1, il comando di identificazione del dispositivo presente dalla prima versione';

  @override
  String get adapterConcernNoIdentityDetail =>
      'Questo comando esiste da ELM327 v1.0. La mancata risposta significa che questo chip implementa meno comandi di qualsiasi firmware ufficiale.';

  @override
  String get telemetryReplaySampled =>
      'L\'anteprima è campionata; l\'esportazione conserva ogni evento registrato.';

  @override
  String get telemetryExportDisclosure =>
      'L\'esportazione contiene nomi dei segnali, valori, tempi di osservazione e della sorgente, tipo di connessione, protocollo, etichette, unità e formule PID fissate al momento della registrazione e le ipotesi della stima (massa, resistenza aerodinamica, cilindrata, carburante e parametri simili). Il JSON può contenere anche le tue etichette, unità e formule personalizzate e le definizioni complete fissate al momento della registrazione. L\'esportazione non contiene il VIN, il GPS, un account, l\'indirizzo dell\'adattatore, il profilo veicolo completo o il traffico diagnostico grezzo.';

  @override
  String get connectTransportCancelled =>
      'Il tentativo di connessione è stato interrotto prima di concludersi.';

  @override
  String get connectTransportWifiRouteNoNetwork =>
      'Il telefono non è connesso ad alcuna rete Wi-Fi, quindi non esiste un percorso verso l\'adattatore. Connettiti all\'hotspot Wi-Fi dell\'adattatore e riprova.';

  @override
  String get connectTransportWifiRouteAmbiguous =>
      'Il telefono è connesso a più reti Wi-Fi e nessuna è chiaramente quella dell\'adattatore, quindi non ne è stata scelta alcuna. Disconnetti le reti che non appartengono all\'adattatore e riprova.';

  @override
  String get connectTransportWifiRouteRefused =>
      'Il sistema ha rifiutato di instradare questa connessione tramite Wi-Fi. Il telefono è connesso al Wi-Fi, ma non è stato consentito usarlo per questo collegamento.';

  @override
  String get connectTransportWifiRouteTimeout =>
      'Il sistema non ha risposto alla richiesta di instradare questa connessione tramite Wi-Fi. Attendi qualche secondo e riprova.';

  @override
  String get connectTransportWifiRouteUnclassified =>
      'Impossibile instradare la connessione tramite Wi-Fi per un motivo non specificato dal sistema. L\'errore completo è conservato nel registro qui sotto.';

  @override
  String get connectTransportWifiHostUnreachable =>
      'Nessuna risposta da quell\'indirizzo. Verifica che il telefono sia connesso all\'hotspot Wi-Fi dell\'adattatore: se il sistema chiede se restare connesso senza Internet, scegli di restare. Può essere utile anche disattivare i dati mobili.';

  @override
  String get connectTransportWifiConnectTimeout =>
      'Nessuna risposta da quell\'indirizzo entro il tempo previsto.';

  @override
  String get connectTransportWifiRouteRestoreFailed =>
      'La connessione ha funzionato, ma non è stato possibile ripristinare l\'instradamento di rete del telefono. La connessione è stata quindi chiusa per non lasciarlo modificato. Riavvia l\'app e riprova.';

  @override
  String get connectTransportBleLinkFailed =>
      'Impossibile connettersi all\'adattatore. Verifica che sia alimentato e nel raggio di copertura.';

  @override
  String get connectTransportBleNoSerialCharacteristic =>
      'Il dispositivo si è connesso, ma non è stata trovata alcuna porta seriale: potrebbe quindi non essere un adattatore ELM327.';

  @override
  String get connectTransportClassicAllTiersRefused =>
      'Impossibile connettersi all\'adattatore. Abbinalo prima nelle impostazioni Bluetooth del sistema e verifica che sia inserito nella presa OBD con il quadro acceso.';

  @override
  String get connectTransportClassicConnectTimeout =>
      'Tempo scaduto per la connessione all\'adattatore. Potrebbe stare ancora rispondendo: attendi qualche secondo prima di riprovare.';

  @override
  String get connectTransportSerialPortOpenFailed =>
      'Impossibile aprire la porta seriale. Verifica che il sistema ne abbia creata una per questo adattatore (COMx su Windows, /dev/rfcomm* su Linux) e che il quadro sia acceso.';

  @override
  String get connectTransportSerialDroppedOnOpen =>
      'La porta seriale si è aperta e richiusa immediatamente.';

  @override
  String get settingsManualCommandNotConnected =>
      'Nessun dispositivo connesso: il comando non è stato inviato.';

  @override
  String get settingsManualCommandLinkDropped =>
      'La connessione all\'adattatore si è interrotta mentre il comando era in corso, quindi non è arrivata alcuna risposta. Non è noto se l\'adattatore abbia ricevuto il comando.';

  @override
  String get settingsManualCommandDisconnectedByApp =>
      'L\'app ha chiuso la connessione mentre il comando era in corso, quindi non è arrivata alcuna risposta. Non c\'è alcun problema con l\'adattatore o il veicolo.';

  @override
  String get settingsManualCommandAdapterSilentOnResync =>
      'Le risposte dell\'adattatore non corrispondevano più ai comandi inviati e l\'adattatore non ha risposto alla verifica che avrebbe ripristinato la corrispondenza. La connessione è stata quindi chiusa. Riconnettiti prima di riprovare.';

  @override
  String get settingsManualCommandLinkStoppedResponding =>
      'Non è arrivato nulla dall\'adattatore per un tempo tale da far chiudere la connessione. Potrebbe essere ancora alimentato: l\'unica cosa nota è l\'assenza di risposte.';

  @override
  String get settingsManualCommandWriteFailed =>
      'Impossibile passare il comando alla connessione dell\'adattatore. Non è noto quanto ne sia arrivato all\'adattatore.';

  @override
  String get settingsManualCommandTimedOut =>
      'Nessuna risposta entro il tempo limite. Verifica che l\'adattatore sia connesso e che il quadro sia acceso.';

  @override
  String get settingsManualCommandOperationRetired =>
      'La sessione è terminata o è passata in secondo piano, quindi il comando non è stato inviato.';

  @override
  String get settingsManualCommandRequestUnaddressable =>
      'Questa richiesta non può essere indirizzata sul bus usato dal veicolo, quindi non è stata inviata. Riprovare non cambierà il risultato.';

  @override
  String get commandFailureBusJ1939 =>
      'Questo bus usa SAE J1939 (veicoli commerciali pesanti e macchinari), non il protocollo diagnostico OBD2 letto dall\'app, quindi questa interrogazione non può essere letta.';

  @override
  String commandFailureUserCanFramingUnknown(
    String protocol,
    String parameter,
  ) {
    return 'L\'adattatore è impostato sul protocollo CAN personalizzato $protocol, il cui formato dei frame dipende da $parameter. L\'adattatore non ha comunicato tale impostazione, quindi non è possibile confermare il formato del bus né decodificare questa interrogazione in sicurezza.';
  }

  @override
  String get commandFailureBusUndetermined =>
      'Il protocollo del bus del veicolo non è ancora determinato, quindi questa interrogazione non può essere decodificata in sicurezza. Riconnettiti.';

  @override
  String get settingsManualCommandCustomFlowControlRejected =>
      'L\'adattatore ha rifiutato un comando di controllo di flusso personalizzato, quindi la modalità richiesta non è stata applicata e non è stata prodotta alcuna misura.';

  @override
  String get settingsManualCommandFlowControlRestoreFailed =>
      'L\'adattatore ha rifiutato di ripristinare il controllo di flusso predefinito (ATFCSM0), quindi l\'interrogazione ciclica è sospesa fino alla riconnessione.';

  @override
  String get settingsManualCommandExtendedAddressingUnavailable =>
      'L\'indirizzamento esteso non è disponibile su questo percorso ELM327.';

  @override
  String get settingsManualCommandRawIsoTpModeUnavailable =>
      'La ricomposizione ISO-TP visibile all\'host non è disponibile su questo percorso ELM327.';

  @override
  String get settingsManualCommandCanPriorityUnavailable =>
      'La programmazione della priorità CAN non è disponibile su questo percorso ELM327.';

  @override
  String get settingsManualCommandCanReceiveFilterUnavailable =>
      'Il filtro di ricezione CAN non è disponibile su questo percorso ELM327.';

  @override
  String get settingsManualCommandHeaderRestoreFailed =>
      'L\'adattatore ha rifiutato di ripristinare l\'intestazione (ATSH), quindi l\'interrogazione ciclica è sospesa fino alla riconnessione.';

  @override
  String get manualCommandRefusedEmpty =>
      'Non hai digitato nulla, quindi non è stato inviato nulla.';

  @override
  String get manualCommandRefusedMoreThanOneCommand =>
      'Questo testo contiene un\'interruzione di riga o un altro carattere di controllo che invia più comandi contemporaneamente. L\'adattatore separa i comandi tramite interruzioni di riga, quindi il secondo comando aggirerebbe tutti i controlli effettuati qui, compreso quello che rifiuta la cancellazione dei codici guasto. Invia un comando alla volta.';

  @override
  String manualCommandRefusedAdapterStateWouldChange(
    Object command,
    Object allowed,
  ) {
    return 'Questa casella accetta interrogazioni, non comandi che modificano la configurazione dell\'adattatore. «$command» cambierebbe lo stato dell\'adattatore mentre per l\'app resterebbe invariato: le letture successive potrebbero provenire da un altro controller, senza alcuna indicazione sullo schermo.\nInterrogazioni che puoi inviare: $allowed.';
  }

  @override
  String get manualCommandRefusedClearHasItsOwnButton =>
      'Per cancellare i codici guasto, usa il pulsante Cancella nella schermata dei codici guasto. Inviato da qui, il comando aggirerebbe la conferma, il controllo della copertura e la verifica della risposta e raggiungerebbe solo il controller attualmente selezionato.';

  @override
  String manualCommandRefusedCharactersNoObdCommandHas(Object command) {
    return 'Il comando «$command» contiene caratteri che un comando OBD non può avere. Questa casella accetta codici di servizio e parametri esadecimali — 0100, 03, 2211A6 — oppure un\'interrogazione dell\'adattatore che inizia con AT.';
  }

  @override
  String manualCommandRefusedNotAReadOnlyQuery(Object command, Object allowed) {
    return '«$command» non è un comando riconosciuto da questa casella. Accetta interrogazioni in sola lettura (Mode $allowed) e interrogazioni dell\'adattatore.';
  }

  @override
  String commandFailureQueryHeaderRefused(Object header) {
    return 'L\'adattatore ha rifiutato di indirizzare questa richiesta al controller $header, quindi non è stata inviata. Lasciando l\'indirizzo effettivamente impostato sull\'adattatore, sarebbe arrivata una risposta da un controller non interrogato.';
  }

  @override
  String commandFailureWholeVehicleHeaderRefused(Object address) {
    return 'L\'adattatore ha rifiutato di passare all\'indirizzo $address, necessario per inviare una richiesta all\'intero veicolo. Senza questo indirizzo, le risposte non possono essere associate ai controller che le hanno inviate, quindi la richiesta non è stata effettuata.';
  }

  @override
  String commandFailureLegacyScanWouldBePartial(Object installed) {
    return 'Questo veicolo usa un bus più vecchio, senza un indirizzo standard che raggiunga tutti i controller, e l\'adattatore è attualmente impostato sul controller $installed. Una scansione avrebbe riguardato solo quel controller, pur essendo presentata come relativa all\'intero veicolo, quindi non è stata inviata. Riconnetti e ripeti la scansione.';
  }

  @override
  String get pidFormulaEmpty => 'La formula è vuota.';

  @override
  String get pidFormulaEmptySubExpression =>
      'Una parte della formula è vuota: un operatore non è seguito da nulla oppure le parentesi non contengono nulla.';

  @override
  String get pidFormulaUnbalancedParentheses =>
      'Le parentesi non corrispondono: ogni ( richiede una ) di chiusura.';

  @override
  String pidFormulaUnparsableTerm(String term) {
    return '«$term» non è un numero, un operatore o un nome riconosciuto da questo editor.';
  }

  @override
  String get pidFormulaFunctionNestingTooDeep =>
      'ABS(), LOG10(), LOG() e SQRT() sono annidate troppo profondamente per essere valutate. Semplifica la formula.';

  @override
  String get pidFormulaParenthesisNestingTooDeep =>
      'Le parentesi sono annidate troppo profondamente per essere valutate. Semplifica la formula.';

  @override
  String get pidFormulaDivisionByZero => 'La formula divide per zero.';

  @override
  String get pidFormulaModuloByZero =>
      'La formula calcola un resto modulo zero.';

  @override
  String pidFormulaLog10NonPositiveArgument(double argument) {
    return 'LOG10 richiede un argomento maggiore di 0, mentre questo è risultato $argument.';
  }

  @override
  String pidFormulaLogNonPositiveArgument(double argument) {
    return 'LOG richiede un argomento maggiore di 0, mentre questo è risultato $argument.';
  }

  @override
  String pidFormulaSqrtNegativeArgument(double argument) {
    return 'SQRT richiede un argomento maggiore o uguale a 0, mentre questo è risultato $argument.';
  }

  @override
  String get pidFormulaResultNotFinite =>
      'Il calcolo non ha prodotto un numero utilizzabile, quindi non c\'è alcuna lettura da mostrare.';

  @override
  String pidFormulaByteBeyondResponse(String letter, int count) {
    return 'La formula fa riferimento al byte $letter, ma la risposta conteneva solo $count byte.';
  }

  @override
  String get pidFormulaBaroControllerUnknown =>
      'BARO non può essere usato qui perché non si sa a quale controller debba riferirsi la pressione atmosferica.';

  @override
  String get pidFormulaBaroTwoDefinitions =>
      'Due definizioni forniscono entrambe la pressione atmosferica, quindi il valore potrebbe essere quello di una o dell\'altra e nessuno dei due può essere usato. Rimuovi uno degli indicatori che misura la pressione atmosferica.';

  @override
  String get pidFormulaBaroNotYetMeasured =>
      'La pressione atmosferica non è ancora stata letta, quindi questo valore non può essere calcolato.';

  @override
  String get pidFormulaBaroMeasurementStale =>
      'La lettura della pressione atmosferica non è aggiornata, quindi questo valore non può essere calcolato.';

  @override
  String get pidFormulaBaroParenFormUnsupported =>
      'BARO() è il barometro Android / la pressione barometrica ECU in psi, che questo dialetto non implementa. Usa BARO senza parentesi per la pressione atmosferica memorizzata nella cache.';

  @override
  String get pidFormulaInt16Unclaimed =>
      'INT16 non ha una definizione adottata: la wiki dice che può sostituire (A*255)+B, che non è (A*256)+B. Scrivi esplicitamente una delle due identità.';

  @override
  String pidFormulaTimeWindowUnsupported(String term) {
    return '$term è una funzione Torque di ritardo, media o totalizer (totalizzatore) che questo dialetto non implementa, quindi qui non può essere valutata. Non è 0 né MIN o MAX.';
  }

  @override
  String pidFormulaDependencyControllerUnknown(String reference) {
    return '$reference non può essere risolto qui perché non si sa a quale controller appartenga quel PID.';
  }

  @override
  String pidFormulaDependencyTwoDefinitions(String key) {
    return 'Due definizioni decodificano entrambe $key, quindi il valore potrebbe essere quello di una o dell\'altra e nessuno dei due può essere usato. Cambia una delle due assegnandole una modalità+PID diversa. Nota: i PID necessari alle stime (010B, 010C, 010D) sono sempre letti, quindi rimuovere un indicatore dal cruscotto non ne interrompe la lettura.';
  }

  @override
  String pidFormulaDependencyNotYetMeasured(String key) {
    return 'Non è ancora stato letto un valore utilizzabile per $key.';
  }

  @override
  String get pidFormulaUnidentified =>
      'Questa formula non può essere valutata e l\'editor non dispone di un motivo più specifico.';

  @override
  String get pidRejectionMalformedModeAndPid =>
      'Combinazione modalità+PID non valida: sono ammessi solo caratteri esadecimali, in coppie che formano byte interi.';

  @override
  String pidRejectionServiceNotReadOnly(String service, String services) {
    return 'Il servizio $service non è un\'interrogazione in sola lettura e non deve essere inviato ripetutamente al veicolo. Sono consentiti solo $services: dati correnti, fermo immagine, informazioni sul veicolo e ReadDataByIdentifier.';
  }

  @override
  String get pidRejectionFreezeFrameNeedsFrame =>
      'Una richiesta di fermo immagine richiede due byte, il PID e il numero del frame: per esempio 020500 (PID 05, frame 0).';

  @override
  String get pidRejectionIdentifierNeedsTwoBytes =>
      'ReadDataByIdentifier richiede un identificatore di due byte, per esempio 221101.';

  @override
  String pidRejectionIdentifierWrongLength(String service, int bytes) {
    return 'Una richiesta del servizio $service richiede un identificatore di $bytes byte.';
  }

  @override
  String get pidRejectionNameRequired => 'Inserisci un nome.';

  @override
  String pidRejectionInvalidHeader(String text) {
    return '«$text» non è un\'intestazione valida: 3 cifre per CAN a 11 bit, 6 per i protocolli meno recenti, 8 per CAN a 29 bit.';
  }

  @override
  String get pidRejectionBoundsRequired =>
      'Inserisci entrambi i limiti dell\'intervallo dell\'indicatore.';

  @override
  String pidRejectionMinNotANumber(String text) {
    return 'Il limite inferiore «$text» non è un numero valido.';
  }

  @override
  String pidRejectionMaxNotANumber(String text) {
    return 'Il limite superiore «$text» non è un numero valido.';
  }

  @override
  String get pidRejectionMinNotFinite =>
      'Il limite inferiore deve essere un numero finito.';

  @override
  String get pidRejectionMaxNotFinite =>
      'Il limite superiore deve essere un numero finito.';

  @override
  String pidRejectionRedlineNotANumber(String text) {
    return 'L\'inizio della zona rossa «$text» non è un numero valido.';
  }

  @override
  String get pidRejectionRedlineNotFinite =>
      'L\'inizio della zona rossa deve essere un numero finito.';

  @override
  String get pidRejectionMaxNotAboveMin =>
      'Il limite superiore deve essere maggiore del limite inferiore.';

  @override
  String pidImportMalformedCsv(String detail) {
    return 'Impossibile leggere questo file come CSV: $detail';
  }

  @override
  String get pidImportNoRows => 'Il file non contiene righe.';

  @override
  String pidImportDuplicateHeaderColumns(String columns) {
    return 'La riga di intestazione nomina due volte la stessa colonna: $columns. Non è possibile sapere quale usare, quindi correggi prima il file.';
  }

  @override
  String pidImportMissingRequiredColumns(String columns, String required) {
    return 'Nella riga di intestazione mancano colonne obbligatorie: $columns. Sono necessarie tutte le seguenti: $required.';
  }

  @override
  String pidImportRowTooFewColumns(int line) {
    return 'Riga $line: celle insufficienti; sono necessari almeno nome, nome breve, PID e formula.';
  }

  @override
  String pidImportRowInvalidModeAndPid(int line, String text) {
    return 'Riga $line: «$text» non è una modalità+PID valida (solo caratteri esadecimali, in coppie che formano byte interi).';
  }

  @override
  String pidImportRowEmptyEquation(int line) {
    return 'Riga $line: la cella della formula è vuota.';
  }

  @override
  String pidImportRowRejected(int line, String reason) {
    return 'Riga $line: $reason';
  }

  @override
  String pidImportRowRangeDefaulted(int line, double min, double max) {
    return 'Riga $line: l\'intervallo dell\'indicatore era vuoto, quindi è stato applicato $min–$max. Verifica che questa scala sia adatta al sensore.';
  }

  @override
  String get pidImportNothingImportable =>
      'Il file contiene righe, ma nessuna è una definizione PID.';

  @override
  String get dtcCategoryNoAnswer =>
      'Questa categoria non ha risposto. Ripeti la scansione.';

  @override
  String get dtcCategoryError =>
      'Non è stato possibile leggere questa categoria. L\'errore completo è conservato nel resoconto diagnostico.';

  @override
  String get dtcCategoryDisconnected =>
      'La connessione si è interrotta durante la lettura di questa categoria.';

  @override
  String get dtcCategoryPending =>
      'Un controller ha ricevuto la richiesta e la sta ancora elaborando. Attendi, poi ripeti la scansione: non si tratta di un rifiuto.';

  @override
  String get dtcCategoryUnattributed =>
      'Sono arrivati codici, ma le intestazioni delle risposte erano disattivate, quindi non si sa quali controller abbiano risposto. Considera questo risultato parziale, non un esito senza guasti.';

  @override
  String dtcCategorySilentControllers(int count, String controllers) {
    return 'Controller che non hanno risposto a questa richiesta: $count ($controllers). Le risposte ricevute sono valide, ma non possono rappresentare un risultato per l\'intero veicolo.';
  }

  @override
  String dtcCategoryUnresolvedSources(int count, String addresses) {
    return 'Risposte che non è stato possibile attribuire a un controller: $count ($addresses). I codici letti restano validi, ma non possono rappresentare un risultato per l\'intero veicolo. Ripeti la scansione.';
  }

  @override
  String dtcCategoryPendingControllers(int count, int answered) {
    return 'Controller che stanno ancora elaborando questa richiesta: $count (controller che hanno già risposto: $answered). Il risultato è incompleto. Attendi, poi ripeti la scansione.';
  }

  @override
  String dtcCategoryRefusedControllers(int refused, int answered) {
    return 'Controller che hanno rifiutato: $refused (controller che hanno risposto: $answered). Questa scansione non può coprire l\'intero veicolo.';
  }

  @override
  String dtcCategoryUnrecognisedResponses(int count, int answered) {
    return 'Risposte che non è stato possibile leggere: $count (controller che hanno risposto: $answered). Il resto è ancora valido, ma questa scansione è incompleta.';
  }

  @override
  String dtcCategoryMilCountMismatch(
    String controller,
    int claimed,
    int observed,
  ) {
    return '$controller ha segnalato $claimed codici guasto confermati, ma questa scansione ne ha letti solo $observed. Fai riferimento alla spia sul cruscotto e rivolgiti a un\'officina.';
  }

  @override
  String dtcCategoryMilLitNoCodes(String controller) {
    return '$controller ha segnalato che la spia di avaria è accesa, ma nessuno dei suoi codici guasto è stato letto. Fai riferimento alla spia sul cruscotto e rivolgiti a un\'officina.';
  }

  @override
  String dtcCategoryMilDisagreement(String controllers) {
    return 'Lo stato segnalato dal veicolo non corrisponde ai codici guasto letti ($controllers). Fai riferimento alla spia sul cruscotto e rivolgiti a un\'officina.';
  }

  @override
  String get connectPairedListFailed =>
      'Impossibile leggere l\'elenco dei dispositivi Bluetooth abbinati. Controlla che il Bluetooth sia attivo e riprova.';

  @override
  String get connectBleScanUnavailable =>
      'Il Bluetooth non è utilizzabile al momento. Attendi un istante e ripeti la ricerca.';

  @override
  String get connectBleScanBluez =>
      'Non è stato trovato alcun servizio Bluetooth BlueZ/D-Bus utilizzabile. Installa e avvia il servizio bluetooth, poi riprova.';

  @override
  String get connectBleScanUnclassified => 'Ricerca BLE non riuscita.';

  @override
  String dtcClearNrcConditions(String controller) {
    return '$controller ha rifiutato la cancellazione perché lo stato del veicolo non la consente. La maggior parte dei controller non cancella i codici con il motore acceso. Porta il quadro su ON con il motore spento, poi riprova.';
  }

  @override
  String dtcClearNrcUnsupported(String controller) {
    return '$controller non supporta la cancellazione Mode 04. Potrebbero essere necessarie apparecchiature del costruttore o del concessionario.';
  }

  @override
  String dtcClearNrcBusy(String controller) {
    return '$controller è occupato. Attendi, poi riprova.';
  }

  @override
  String dtcClearNrcSecurity(String controller) {
    return '$controller richiede l\'accesso di sicurezza prima di cancellare i codici. Sono necessarie apparecchiature del costruttore o del concessionario.';
  }

  @override
  String dtcClearNrcOther(String controller, String code) {
    return '$controller ha rifiutato la cancellazione (codice motivo $code). Attendi, poi riprova.';
  }

  @override
  String dtcClearSilentControllers(int count, String controllers) {
    return 'Controller che non hanno risposto alla cancellazione: $count ($controllers). I controller che hanno risposto hanno cancellato i codici; gli altri potrebbero conservarne ancora. Ripeti la scansione. Non inviare un\'altra cancellazione.';
  }

  @override
  String dtcClearUnresolvedSources(int count, String addresses) {
    return 'Risposte di questa scansione che non è stato possibile attribuire: $count ($addresses); quindi non si sa quali controller verrebbero raggiunti da una cancellazione. Ripeti la scansione; se quell\'indirizzo non compare più, riconnetti prima di riprovare.';
  }

  @override
  String dtcClearUnresolvedSourcesDoNotRepeat(int count, String addresses) {
    return 'Risposte all\'esito della cancellazione che non è stato possibile attribuire: $count ($addresses). Non inviare un\'altra cancellazione. Ripeti la scansione per vedere quali codici rimangono.';
  }

  @override
  String dtcClearNrcConditionsDoNotRepeat(String controller) {
    return '$controller ha rifiutato la cancellazione perché lo stato del veicolo non la consente. La maggior parte dei controller non cancella i codici con il motore acceso. Porta il quadro su ON con il motore spento, poi ripeti la scansione per vedere quali codici rimangono. Non inviare un\'altra cancellazione globale: una seconda può azzerare lo stato dei monitor emissioni su un controller che potrebbe aver già cancellato i codici.';
  }

  @override
  String dtcClearNrcUnsupportedDoNotRepeat(String controller) {
    return '$controller non supporta la cancellazione Mode 04. Potrebbero essere necessarie apparecchiature del costruttore o del concessionario. Non inviare un\'altra cancellazione globale: una seconda può azzerare lo stato dei monitor emissioni su un controller che potrebbe aver già cancellato i codici. Ripeti la scansione per vedere quali codici rimangono.';
  }

  @override
  String dtcClearNrcBusyDoNotRepeat(String controller) {
    return '$controller è occupato. Non inviare un\'altra cancellazione globale: una seconda può azzerare lo stato dei monitor emissioni su un controller che potrebbe aver già cancellato i codici. Ripeti la scansione per vedere quali codici rimangono.';
  }

  @override
  String dtcClearNrcSecurityDoNotRepeat(String controller) {
    return '$controller richiede l\'accesso di sicurezza prima di cancellare i codici. Sono necessarie apparecchiature del costruttore o del concessionario. Non inviare un\'altra cancellazione globale: una seconda può azzerare lo stato dei monitor emissioni su un controller che potrebbe aver già cancellato i codici.';
  }

  @override
  String dtcClearNrcOtherDoNotRepeat(String controller, String code) {
    return '$controller ha rifiutato la cancellazione (codice motivo $code). Non inviare un\'altra cancellazione globale: una seconda può azzerare lo stato dei monitor emissioni su un controller che potrebbe aver già cancellato i codici. Ripeti la scansione per vedere quali codici rimangono.';
  }

  @override
  String get sharePolicyDenied =>
      'Lo stato attuale della connessione o della guida non consente l\'esportazione.';

  @override
  String get shareSafetyChanged =>
      'Lo stato è cambiato durante la preparazione dell\'esportazione, quindi la condivisione non è stata aperta.';

  @override
  String get shareSizeLimit => 'L\'esportazione supera il limite di 32 MiB.';

  @override
  String get shareStagingBusy =>
      'Un file di condivisione precedente è ancora nel suo periodo di conservazione. Riprova più tardi.';

  @override
  String get shareCleanupRequired =>
      'L\'area temporanea di condivisione deve essere controllata dopo un riavvio.';

  @override
  String get shareSpaceUnknown =>
      'Impossibile confermare lo spazio libero necessario per il file di condivisione.';

  @override
  String get shareNoSpace =>
      'Non c\'è spazio di archiviazione sufficiente per preparare il file di condivisione.';

  @override
  String get shareHandoffFailed =>
      'Il file è pronto, ma non è stato possibile aprire il pannello di condivisione del sistema.';

  @override
  String get shareStorageFailure =>
      'Si è verificato un errore di archiviazione durante la preparazione o la registrazione della condivisione.';

  @override
  String shareTelemetrySubject(String sessionId) {
    return 'Registrazione OBD locale $sessionId';
  }

  @override
  String shareRawTranscriptSubject(String stamp) {
    return 'Registro di trasporto Telltale $stamp';
  }

  @override
  String get shareRecoveredTranscriptSubject =>
      'Registro di trasporto Telltale (ultima connessione)';

  @override
  String get sharePidCsvSubject => 'Definizioni PID personalizzate Telltale';

  @override
  String get shareTorqueSubsetCsvSubject =>
      'Definizioni PID compatibili con Torque';

  @override
  String get shareHumanReportCsvSubject => 'Report PID Telltale leggibile';

  @override
  String get transcriptExportUnidentified => 'Esportazione non riuscita.';

  @override
  String get handshakeNoteUnexpected =>
      'Questo passaggio è fallito con un errore imprevisto. L\'errore completo è conservato nel resoconto diagnostico.';

  @override
  String pidFormulaUnsupportedConstruct(String term) {
    return '$term è una funzione Torque che questo dialetto non implementa, quindi la formula non può essere valutata qui.';
  }

  @override
  String pidImportRowFormulaRejected(int line, String reason) {
    return 'Riga $line: $reason';
  }

  @override
  String get telemetryHistoryNeedsForeground =>
      'Torna a Telltale prima di continuare.';

  @override
  String get telemetrySessionPolicyChanged =>
      'Lo stato della guida o della connessione è cambiato durante questa operazione.';

  @override
  String get telemetrySessionInvalidId =>
      'L\'identificativo di questa registrazione non è valido.';

  @override
  String get telemetrySessionNotFound =>
      'Questa registrazione locale non è stata trovata.';

  @override
  String get telemetrySessionStorageFailed =>
      'Un\'operazione di archiviazione locale non è riuscita.';

  @override
  String get telemetrySessionShareFailed =>
      'Impossibile preparare o aprire la condivisione.';

  @override
  String get pidMutationPersistFailed =>
      'Impossibile salvare l\'elenco dei PID personalizzati. Nulla è stato modificato.';

  @override
  String get powertrainAuthorizeYearOutOfRange =>
      'L\'anno modello è fuori dall\'intervallo di anni documentato per questo profilo.';

  @override
  String get connectionLayerTransport => 'Connessione';

  @override
  String get connectionLayerProtocol => 'Protocollo';

  @override
  String get connectionLayerEcu => 'Risposte ECU';

  @override
  String get connectionLayerEvidence => 'Evidenze';

  @override
  String get connectionLayerUnknown => 'Sconosciuto';

  @override
  String get connectionLayerNotObserved => 'Non osservato';

  @override
  String get connectionLayerObserved => 'Osservato';

  @override
  String get connectionLayerAnswered => 'Ha risposto';

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
    return 'richiesto $requested, stabilito $observed';
  }

  @override
  String get connectionLayerKwpSubtypeUnknown =>
      'KWP, 5-baud e fast non distinti';

  @override
  String get connectionFailureOpenSettings =>
      'Apri le impostazioni di sistema.';

  @override
  String get connectionFailureTurnRadioOn => 'Attiva il Bluetooth.';

  @override
  String get connectionFailureCheckDistanceOrPower =>
      'L\'adattatore potrebbe essere fuori portata o non alimentato. È una possibile causa, non un fatto accertato.';

  @override
  String get connectionFailureCheckIgnitionProtocolAdapter =>
      'Verifica il quadro, il protocollo o le capacità dell\'adattatore. L\'assenza di risposte non dimostra che il veicolo non abbia OBD.';

  @override
  String get connectionFailureRetryOrAuto =>
      'Riprova o imposta il protocollo su Auto.';

  @override
  String get connectionFailureKeepInvalidAndExport =>
      'La risposta non è valida. Mantienila non valida ed esporta la diagnostica limitata: non è una lettura.';

  @override
  String get settingsCatalogMarketCa => 'Canada (NRCan)';

  @override
  String get settingsCaPickerTitle => 'Catalogo ufficiale veicoli Canada';

  @override
  String settingsCaPickerScope(int firstYear, int lastYear) {
    return 'Solo voci Fuel Consumption Ratings per il mercato canadese, anni $firstYear–$lastYear. Veicoli a combustione interna, elettrici a batteria e ibridi plug-in restano classi separate. Una corrispondenza nel testo di marca/modello non equivale a una configurazione EPA o taiwanese.';
  }

  @override
  String get settingsCaMotorNotPower =>
      'La potenza del motore in kilowatt non è la potenza alle ruote in cavalli e non viene applicata.';

  @override
  String get settingsCaClassIce => 'ICE';

  @override
  String get settingsCaClassBev => 'BEV';

  @override
  String get settingsCaClassPhev => 'PHEV';

  @override
  String settingsCaWillApplyOnly(String fields) {
    return 'Verranno applicati solo $fields. kW del motore, consumo di carburante, autonomia, CO2, VE, Cd, area frontale, Crr e rendimento della trasmissione restano non determinati.';
  }

  @override
  String get serviceRecipesTitle =>
      'Procedure di manutenzione e diagnostica attiva';

  @override
  String get serviceRecipesSubtitle =>
      'Procedure riferite a standard e rilevamento delle capacità senza azionamenti';

  @override
  String get serviceRecipesSafetyBannerTitle =>
      'Nessun candidato per prove reali';

  @override
  String get serviceRecipesSafetyBannerBody =>
      'Gli azionamenti fisici su veicoli reali sono tassativamente vietati (0 veicoli qualificati). Le procedure disponibili sono esclusivamente scenari di simulazione.';

  @override
  String get serviceRecipesDiscoverySection =>
      'Rilevamento Mode 08 senza azionamenti';

  @override
  String get serviceRecipesDiscoveryDescription =>
      'Interroga gli ID test di base standard (\$00, \$20, ...) su CAN senza azionare alcun componente.';

  @override
  String get serviceRecipesDiscoveryButton => 'Rileva TID supportati Mode 08';

  @override
  String get serviceRecipesDiscovering => 'Interrogazione dei TID supportati…';

  @override
  String serviceRecipesDiscoverySuccess(String tids) {
    return 'Mode 08 è supportato dalla ECU. TID supportati: $tids';
  }

  @override
  String get serviceRecipesDiscoveryUnsupported =>
      'Mode 08 non è supportato da questa ECU';

  @override
  String serviceRecipesDiscoveryUnknown(String reason) {
    return 'Supporto Mode 08 sconosciuto: $reason';
  }

  @override
  String serviceRecipesDiscoveryPartialWarning(String reason, String blocks) {
    return 'Rilevamento completato parzialmente ($reason). Blocchi non completati: $blocks. Nota: non trovato non significa non supportato.';
  }

  @override
  String get serviceRecipesCatalogSection =>
      'Procedure di manutenzione disponibili';

  @override
  String get serviceRecipesSimulationBadge => 'Pronto per la simulazione';

  @override
  String get serviceRecipesLiveBlockedBadge =>
      'Prove reali bloccate (0 candidati)';

  @override
  String serviceRecipesStandard(String standard) {
    return 'Standard: $standard';
  }

  @override
  String serviceRecipesEcuHeader(String header) {
    return 'Intestazione ECU: $header';
  }

  @override
  String serviceRecipesHash(String hash) {
    return 'Hash canonico: $hash';
  }

  @override
  String get serviceRecipesDetailTitle => 'Dettagli della procedura';

  @override
  String get serviceRecipesPreconditions => 'Precondizioni di sicurezza';

  @override
  String get serviceRecipesRecovery => 'Comando di ripristino';

  @override
  String get serviceRecipesClose => 'Chiudi';

  @override
  String get serviceRecipesDiscoveryRequiresCan =>
      'Richiede una connessione attiva a un bus CAN OBD-II.';

  @override
  String serviceRecipesLoadError(String error) {
    return 'Errore nel caricamento delle procedure: $error';
  }

  @override
  String get serviceRecipesNoPreconditions => 'Nessuna';

  @override
  String get settingsServiceRecipesEntry =>
      'Procedure di manutenzione e test attivi';

  @override
  String get settingsServiceRecipesDesc =>
      'Esamina le procedure di officina e rileva i test Mode 08 supportati';

  @override
  String get mode08ReasonUnheaderedLimitation =>
      'Attribuzione delle sorgenti e copertura non confermate: le risposte senza intestazione non consentono di stabilire l\'identità delle ECU tra blocchi diversi';

  @override
  String mode08ReasonNoResponseWithEcu(
    String block,
    String ecu,
    String marker,
  ) {
    return 'Nessuna risposta sul blocco $block da $ecu: $marker';
  }

  @override
  String mode08ReasonNoResponse(String block, String marker) {
    return 'Nessuna risposta sul blocco $block: $marker';
  }

  @override
  String mode08ReasonNegativeWithEcu(String block, String ecu, String nrc) {
    return 'Risposta negativa sul blocco $block da $ecu (NRC $nrc)';
  }

  @override
  String mode08ReasonNegative(String block, String nrc) {
    return 'Risposta negativa sul blocco $block (NRC $nrc)';
  }

  @override
  String mode08ReasonMalformedWithEcu(
    String block,
    String ecu,
    String details,
  ) {
    return 'Risposta malformata sul blocco $block da $ecu: $details';
  }

  @override
  String mode08ReasonMalformed(String block, String details) {
    return 'Risposta malformata sul blocco $block: $details';
  }

  @override
  String mode08ReasonTimeout(String block) {
    return 'Tempo scaduto per l\'interrogazione del blocco $block';
  }

  @override
  String get mode08ReasonBudgetExceeded =>
      'Limite di rilevamento raggiunto prima di interrogare tutti i blocchi';

  @override
  String get mode08ReasonSessionDisconnected =>
      'Sessione disconnessa o sostituita durante il rilevamento';

  @override
  String mode08ReasonUnqueriedAnnounced(String blocks) {
    return 'Blocchi annunciati dalle ECU ma non interrogati: $blocks';
  }

  @override
  String get mode08ReasonRequiresCanBus =>
      'Il rilevamento delle capacità Mode 08 richiede che il bus CAN OBD-II sia stato determinato';

  @override
  String get mode08ReasonUnexpectedExecution =>
      'Risposta di esecuzione imprevista a un\'interrogazione dei TID supportati';

  @override
  String get pidDetailEmptyTitle => 'Seleziona un PID';

  @override
  String get pidDetailEmptyBody =>
      'Scegli un PID dall\'elenco per esaminarne la definizione e lo stato in tempo reale.';

  @override
  String get pidDetailRangeLabel => 'Scala';

  @override
  String get pidDetailPriorityLabel => 'Priorità';

  @override
  String pidDetailHeaderDefault(String header) {
    return 'Predefinita ($header)';
  }

  @override
  String get dtcSystemOverview => 'Panoramica del sistema';

  @override
  String get dtcPartialObservationBadge => 'Scansione parziale';

  @override
  String get dtcPartialObservationBody =>
      'Questo codice guasto è stato letto, ma la scansione della categoria non è stata completata su tutti i controller.';

  @override
  String get dtcLinkedFreezeFrameTitle => 'Fermo immagine associato';

  @override
  String get dtcNoLinkedFreezeFrame =>
      'Questa scansione non contiene un fermo immagine associabile in sicurezza a questo codice guasto e controller.';

  @override
  String get performanceGuideTitle => 'Guida alla prova di accelerazione';

  @override
  String get performanceGuideStep1 =>
      '1. Scegli una velocità obiettivo, poi prepara il cronometro';

  @override
  String get performanceGuideStep2 =>
      '2. Ferma completamente il veicolo e attendi che la prova sia pronta';

  @override
  String get performanceGuideStep3 =>
      '3. Inizia ad accelerare: il cronometraggio parte automaticamente quando viene rilevato il movimento';

  @override
  String get performanceGuideStep4 =>
      '4. Raggiungi la velocità obiettivo per completare la prova';

  @override
  String get performanceRecordingTrace =>
      'Accelerazione… registrazione del grafico di velocità';

  @override
  String get performanceNoAnalysisTitle => 'Nessun dato da analizzare';

  @override
  String get performanceNoAnalysisBody =>
      'Questa prova si è interrotta prima che fossero registrati campioni di velocità sufficienti per tracciare una curva o calcolare i tempi intermedi.';

  @override
  String get connectActivityReconnectingAutomatically =>
      'L\'adattatore ha smesso di rispondere. Riconnessione automatica…';
}
