// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get adapterErrorActivityAlert => 'Melding van busactiviteit.';

  @override
  String get adapterErrorBufferFull =>
      'De buffer van de adapter is overgelopen.';

  @override
  String get adapterErrorBus => 'Busfout; de bedrading kan de oorzaak zijn.';

  @override
  String get adapterErrorBusBusy => 'De bus is bezet.';

  @override
  String get adapterErrorBusInit => 'Businitialisatie mislukt.';

  @override
  String get adapterErrorCan => 'CAN-busfout.';

  @override
  String get adapterErrorData => 'De ontvangen gegevens zijn niet correct.';

  @override
  String get adapterErrorFeedback => 'Fout in signaalfeedback.';

  @override
  String get adapterErrorInternal => 'Interne fout van de adapter.';

  @override
  String get adapterErrorLowPowerAlert =>
      'De adapter schakelt bijna over naar de energiebesparende modus.';

  @override
  String get adapterErrorLowVoltageReset =>
      'De adapter is gereset door lage spanning.';

  @override
  String get adapterErrorNoData =>
      'Er kwam geen antwoord — het kan tijdelijke stilte zijn, of het voertuig ondersteunt dit mogelijk niet.';

  @override
  String get adapterErrorStopped => 'De overdracht is onderbroken.';

  @override
  String get adapterErrorUnableToConnect =>
      'Kan de ECU niet bereiken. Controleer of het contact aan staat.';

  @override
  String get adapterErrorUnknownCommand =>
      'De adapter ondersteunt deze opdracht niet.';

  @override
  String get appTagline => 'Live voertuigtelemetrie';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => 'Weergave';

  @override
  String get connectActivityAbortingPreviousConnection =>
      'Vorige verbinding wordt gestopt, een ogenblik…';

  @override
  String get connectAnswerBleWithClassic =>
      'Kies Bluetooth LE. Vooraf koppelen is niet nodig — zoek ernaar in de app. Zelfs als het apparaat in de Bluetooth-koppelingslijst van het systeem verschijnt, koppel het dan niet; die route werkt niet. Als het zoeken niets oplevert, sloeg 4.0 op de doos alleen op de chipspecificatie — gebruik dan Bluetooth Classic.';

  @override
  String get connectAnswerBleWithoutClassic =>
      'Kies Bluetooth LE. Vooraf koppelen is niet nodig — zoek ernaar in de app. Zelfs als het apparaat in de Bluetooth-koppelingslijst van het systeem verschijnt, koppel het dan niet; die route werkt niet. Als het zoeken niets oplevert, controleer dan of de adapter stroom heeft of probeer in plaats daarvan Wi-Fi; dit systeem biedt geen Bluetooth Classic.';

  @override
  String get connectAnswerClassic =>
      'Kies Bluetooth Classic. Koppel de adapter eerst in de systeeminstellingen; de app kan dat niet voor je doen. De pincode is meestal 1234 of 0000.';

  @override
  String get connectAnswerWifiDesktop =>
      'Kies Wi-Fi. Verbind dit apparaat eerst met dat netwerk en kom daarna terug om het adres in te voeren.';

  @override
  String get connectAnswerWifiPhone =>
      'Kies Wi-Fi. Maak op de telefoon eerst verbinding met dat netwerk en kom daarna terug om het adres in te voeren.';

  @override
  String get connectBleBody =>
      'Een BLE-adapter hoeft niet eerst gekoppeld te worden. Zoek en kies daarna je apparaat — veelvoorkomende namen zijn OBDII, V-LINK, Vgate of IOS-Vlink.';

  @override
  String connectBleEmptyScan(String next) {
    return 'Het zoeken is voltooid zonder dat er een BLE-adapter is gevonden. Controleer in deze volgorde: brandt het lampje op de adapter — de meeste OBD-poorten krijgen pas stroom als het contact op ON staat; daarna het bereik, dus ga in de auto zitten voordat je zoekt. $next Een BLE-adapter hoeft niet in de systeeminstellingen gekoppeld te worden en mag dat ook niet zijn; die route werkt niet.';
  }

  @override
  String get connectBleEmptyScanNextClassic =>
      'Controleer tot slot de specificatie op de doos: als daar 2.0 of 3.0 staat, is het Bluetooth Classic; dat verschijnt nooit in deze lijst, dus gebruik hierboven Bluetooth Classic.';

  @override
  String get connectBleEmptyScanNextWifi =>
      'Controleer tot slot de specificatie op de doos: als daar 2.0/3.0 of alleen Wi-Fi staat, probeer dan Wi-Fi (dit systeem biedt geen Bluetooth Classic).';

  @override
  String get connectBlePermissionDeniedForever =>
      'Bluetooth-toestemming is permanent geweigerd. Het systeem vraagt er niet opnieuw om, dus schakel dit in via de app-instellingen.';

  @override
  String get connectBlePermissionNeeded =>
      'Bluetooth-toestemming is nodig om te zoeken.';

  @override
  String get connectBleScan => 'Zoeken naar BLE-apparaten';

  @override
  String get connectBleScanning => 'Zoeken…';

  @override
  String get connectBleUnavailableHost =>
      'Bluetooth LE is nog niet beschikbaar op dit systeem';

  @override
  String get connectBluetoothOff =>
      'Bluetooth staat uit. Schakel Bluetooth eerst in via de systeeminstellingen.';

  @override
  String get connectBluetoothPermissionDeniedForever =>
      'Bluetooth-toestemming is permanent geweigerd. Schakel dit in via de systeeminstellingen en probeer het opnieuw.';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      'Bluetooth-toestemming is nodig om gekoppelde adapters weer te geven.';

  @override
  String get connectBody =>
      'Sluit een ELM327-adapter aan en zet het contact aan, of gebruik de ingebouwde simulator.';

  @override
  String get connectCancel => 'Annuleren';

  @override
  String get connectClassicEmptyLinuxPort =>
      'Geen seriële Bluetooth-poort (/dev/rfcomm*) gevonden. Koppel de ELM327 eerst met BlueZ, maak daarna een RFCOMM-TTY aan met rfcomm bind (of het equivalent daarvan) en probeer het opnieuw.';

  @override
  String get connectClassicEmptyPaired =>
      'Geen gekoppelde adapter gevonden. Koppel de adapter eerst in de Bluetooth-instellingen van het systeem (de code voor de meeste ELM327-adapters is 1234 of 0000).';

  @override
  String get connectClassicEmptyWindowsPort =>
      'Geen seriële Bluetooth-poort (COMx) gevonden. Koppel de ELM327 eerst in de Bluetooth-instellingen van Windows en controleer of Apparaatbeheer “Standard Serial over Bluetooth link” toont.';

  @override
  String get connectClassicListLinuxPort =>
      'Dit toont de seriële Bluetooth-poorten die BlueZ heeft gebonden (/dev/rfcomm* of het equivalent daarvan). Een lege lijst betekent dat het systeem nog geen RFCOMM-node heeft aangemaakt, niet dat de app stuk is.';

  @override
  String get connectClassicListPaired =>
      'Dit toont elk apparaat dat met het systeem is gekoppeld — inclusief koptelefoons en luidsprekers, met de apparaten die op adapters lijken bovenaan. Als je het verkeerde apparaat kiest, tik dan op Annuleren in plaats van te wachten tot het mislukt; je kunt meteen een ander kiezen.';

  @override
  String get connectClassicListWindowsPort =>
      'Dit toont de COM-poorten die aan Bluetooth zijn gekoppeld (“Standard Serial over Bluetooth link”). Een lege lijst betekent dat het systeem nog geen virtuele seriële poort heeft aangemaakt, niet dat de app stuk is.';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic (SPP) is momenteel beschikbaar op Android, macOS (IOBluetooth RFCOMM), Windows (COM) en Linux (/dev/rfcomm*)';

  @override
  String get connectClassicUnavailableIos =>
      'iOS stelt Bluetooth SPP niet open voor apps van derden';

  @override
  String get connectConnect => 'Verbinden';

  @override
  String get connectDemoBody =>
      'Simuleert een 2,0 L viercilinder turbomotor tijdens stationair draaien, accelereren, kruissnelheid en afremmen, met signalen die fysisch met elkaar samenhangen (het motortoerental daalt bij het schakelen terwijl de rijsnelheid blijft stijgen). Storingscodes, VIN-uitlezingen en fastMode-batchquery\'s werken allemaal volledig.';

  @override
  String get connectDemoStart => 'Simulator starten';

  @override
  String get connectHandshakeTitle => 'ELM327-initialisatie';

  @override
  String get connectHandshakeTitleLastAttempt =>
      'ELM327-initialisatie (laatste poging)';

  @override
  String get connectHeadline => 'Kies een verbinding';

  @override
  String get connectIssueAdapterAcceptedThenSilent =>
      'De adapter heeft de verbinding geaccepteerd maar antwoordde niet op tijd. Meestal krijgt hij nog geen stroom — de meeste OBD-poorten leveren pas stroom als het contact aan staat — of een andere app is er al mee verbonden; sluit in dat geval die app en probeer het opnieuw.';

  @override
  String connectIssueAdapterSilentOnReset(String command) {
    return 'De adapter heeft niet geantwoord op de resetopdracht ($command). Dit apparaat is mogelijk geen ELM327-adapter, of de verbinding is naar het verkeerde apparaat gegaan.';
  }

  @override
  String get connectIssueAdapterStoppedResponding =>
      'De adapter reageert niet meer en de verbinding is verbroken.';

  @override
  String get connectIssueConnectionSetupFailed =>
      'Het opbouwen van de verbinding is mislukt. Controleer of de adapter stroom heeft en dichtbij is, en probeer het opnieuw. De volledige fout staat in het logboek hieronder.';

  @override
  String get connectIssueHandshakeIncomplete =>
      'Initialisatie is niet geslaagd. De adapter is mogelijk niet compatibel.';

  @override
  String connectIssueHandshakeStepFailed(String command, String reason) {
    return 'Initialisatie mislukt bij $command ($reason). Controleer of de adapter goed is aangesloten en het contact van het voertuig aan staat.';
  }

  @override
  String get connectIssuePreviousConnectionStillAborting =>
      'De vorige verbinding wordt nog gestopt en de adapter is nog niet vrijgegeven. Wacht een paar seconden en probeer het opnieuw.';

  @override
  String get connectLastAdapterConnect => 'Nu verbinden';

  @override
  String get connectLastAdapterForget => 'Vergeten';

  @override
  String get connectLastAdapterTitle => 'Laatst gebruikte adapter';

  @override
  String get connectOpenAppSettings => 'App-instellingen openen';

  @override
  String get connectOpenSystemSettings => 'Systeeminstellingen openen';

  @override
  String get connectOpeningConnection => 'Verbinding openen…';

  @override
  String get connectPairedPill => 'Gekoppeld';

  @override
  String get connectQuestionBle =>
      'Staat er op de doos, op de productpagina of in de apparaatnaam BLE, 4.0 of 5.0?';

  @override
  String get connectQuestionClassic =>
      'Geen van beide — een ouder model met 2.0 of 3.0 op de doos?';

  @override
  String get connectQuestionWifiDesktop =>
      'Staat er een nieuw netwerk in de Wi-Fi-lijst op het systeem (zoals V-LINK of WiFi_OBDII)?';

  @override
  String get connectQuestionWifiPhone =>
      'Staat er een nieuw netwerk in de Wi-Fi-lijst op de telefoon (zoals V-LINK of WiFi_OBDII)?';

  @override
  String get connectSearchAgain => 'Opnieuw zoeken';

  @override
  String connectSignalStrength(int bars, int total) {
    return 'Signaalsterkte $bars/$total';
  }

  @override
  String get connectTranscriptKept =>
      'Het volledige diagnoselogboek van deze poging is bewaard. Dat meesturen helpt meer dan een melding van één regel.';

  @override
  String get connectTransportBleDescription =>
      'GATT UART — een nieuwere energiezuinige adapter';

  @override
  String get connectTransportBleTitle => 'Bluetooth LE';

  @override
  String get connectTransportClassicDescription =>
      'RFCOMM / SPP — de meest voorkomende budget-ELM327';

  @override
  String get connectTransportClassicTitle => 'Bluetooth Classic';

  @override
  String get connectTransportDemoDescription =>
      'Een ingebouwde gesimuleerde ECU — de hele app zonder hardware';

  @override
  String get connectTransportDemoTitle => 'Demo-simulator';

  @override
  String get connectTransportWifiDescription =>
      'Een TCP-poort, meestal 192.168.0.10:35000';

  @override
  String get connectTransportWifiTitle => 'Wi-Fi';

  @override
  String get connectWhichIntro =>
      'Laat de termen SPP en GATT voor wat ze zijn. Kijk naar wat je adapter doet zodra je hem aansluit:';

  @override
  String get connectWhichNoteGuessing =>
      'Verkeerd gokken kan geen kwaad — als verbinden niet lukt, ga je terug en probeer je een andere. Loop je echt vast, gebruik dan onderaan de Demo-simulator om te controleren of de app zelf goed werkt.';

  @override
  String get connectWhichNoteIos =>
      'Een iPhone kan alleen Wi-Fi of BLE gebruiken — een gewone Bluetooth-ELM327 werkt helemaal niet op iOS. Dat is een beperking van het besturingssysteem en geen enkele andere app kan daar omheen.';

  @override
  String get connectWhichTitle => 'Niet zeker welke je moet kiezen?';

  @override
  String get connectWifiHostLabel => 'IP-adres';

  @override
  String get connectWifiHostRequired => 'Voer het IP-adres van de adapter in.';

  @override
  String get connectWifiInstructionsDesktop =>
      'Verbind deze computer eerst met de Wi-Fi-hotspot die de adapter uitzendt en voer daarna het adres in. Als het systeem waarschuwt dat het netwerk geen internettoegang heeft, kies er dan voor om verbonden te blijven. Desktopsystemen gebruiken de hotspot meestal als standaardroute; de Android Wi-Fi-routekoppeling is niet nodig.';

  @override
  String get connectWifiInstructionsPhone =>
      'Verbind je telefoon eerst met de Wi-Fi-hotspot die de adapter uitzendt en voer daarna het adres in. Als het systeem vraagt of je verbonden wilt blijven met een Wi-Fi-netwerk zonder internettoegang, kies er dan voor om verbonden te blijven. Op Android probeert Telltale het verkeer tijdens de verbinding aan de Wi-Fi-route te koppelen, zodat mobiele data het niet overneemt.';

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '“$value” is geen geldige poort. Het bereik is $min–$max.';
  }

  @override
  String get connectWifiPortLabel => 'Poort';

  @override
  String connectWifiPortRequired(int port) {
    return 'Voer de poort in (de meeste adapters gebruiken $port).';
  }

  @override
  String get dashboardBatchedPolling => 'Gebundelde polling';

  @override
  String get dashboardBatchingEnabled => 'Bundelen ingeschakeld';

  @override
  String get dashboardChoosePids => 'PID\'s kiezen';

  @override
  String get dashboardEmptyBody =>
      'Kies op de PID-pagina de signalen die je wilt volgen; ze verschijnen daarna hier.';

  @override
  String get dashboardEmptyTitle => 'Het dashboard is leeg';

  @override
  String get dashboardGenericObd => 'Algemene OBD';

  @override
  String get dashboardLocalRecordings => 'Lokale opnamen';

  @override
  String get dashboardNotConnected => 'Niet verbonden';

  @override
  String get dashboardPollingModeHelpAction => 'Over pollingmodus';

  @override
  String get dashboardPollingModeHelpBatching =>
      'Bundelen ingeschakeld betekent dat Telltale PID-verzoeken mag groeperen in één uitwisseling om het aantal heen-en-weer-berichten te beperken: gegroepeerde pogingen zijn toegestaan en niets heeft groeperen uitgeschakeld. Het blijft een toestemming en geen meting, want of een bepaalde uitwisseling daadwerkelijk iets heeft gegroepeerd hangt ook af van welke PID\'s het voertuig heeft bevestigd en hoeveel er wachten.';

  @override
  String get dashboardPollingModeHelpObserved =>
      'Gebundelde polling betekent dat een Mode 01-opdracht tijdens deze verbinding daadwerkelijk meer dan één PID bevatte. Het is een registratie van die uitwisseling, geen belofte dat de volgende ook zal groeperen en geen claim over de doorvoersnelheid.';

  @override
  String get dashboardPollingModeHelpRate =>
      'PIDs/s is een snelheid die over de afgelopen seconde is waargenomen, geen belofte over latentie, actualiteit of nauwkeurigheid. Deze varieert met de adapter, de bus, de ECU, de gekozen PID\'s, de grootte van elk antwoord en eventuele fouten.';

  @override
  String get dashboardPollingModeHelpSingle =>
      'Enkelvoudige verzoekmodus betekent dat elke Mode 01-PID afzonderlijk wordt uitgelezen. Telltale gebruikt dit wanneer de bus helemaal geen gegroepeerde verzoeken ondersteunt, wat geldt voor elk niet-CAN-voertuig; zolang er nog geen ondersteuningsblok heeft geantwoord, omdat het groeperen van PID\'s die het voertuig niet heeft bevestigd leidt tot een te kort antwoord; en nadat een gegroepeerd verzoek niet terugkomt in een vorm die weer kan worden opgesplitst — of het nu is afgekapt, geweigerd omdat de adapter meldde dat zijn buffer vol was, of onbeantwoord bleef. Uitlezingen blijven gewoon doorlopen en op zichzelf is dit geen verbindingsfout.';

  @override
  String get dashboardPollingModeHelpTitle => 'Pollingmodus';

  @override
  String get dashboardSingleRequestMode => 'Enkelvoudige modus';

  @override
  String get dashboardVinRead => 'VIN uitgelezen';

  @override
  String get dashboardWorkspaceGauges => 'Meters';

  @override
  String get dashboardWorkspaceTrends => 'Trends';

  @override
  String get datumBadgeCommunityDecode => 'Community-decodering';

  @override
  String get datumBadgeDemo => 'Gesimuleerd';

  @override
  String get datumBadgeEstimated => 'Geschat';

  @override
  String get datumBadgeExperimental => 'Experimenteel';

  @override
  String get datumBadgeFieldVerified => 'In de praktijk geverifieerd';

  @override
  String get datumBadgeInvalid => 'Ongeldig';

  @override
  String get datumBadgeJustUpdated => 'Zojuist bijgewerkt';

  @override
  String get datumBadgeOutOfReferenceRange => 'Buiten bereik';

  @override
  String get datumBadgePartial => 'Gedeeltelijk';

  @override
  String get datumBadgeStale => 'Verouderd';

  @override
  String get datumBadgeTentativeDecode => 'Voorlopige decodering';

  @override
  String get datumBadgeUnverified => 'Ongeverifieerd';

  @override
  String get datumBadgeUnverifiedOnThisVehicle =>
      'Ongeverifieerd op dit voertuig';

  @override
  String get datumBadgeUserSupplied => 'Door gebruiker opgegeven';

  @override
  String get datumGapModelYearUnknown => 'Modeljaar onbekend';

  @override
  String get datumGapNoCatalogMatch => 'Geen catalogusmatch';

  @override
  String get datumGapVinNotRead => 'VIN niet uitgelezen';

  @override
  String get datumNextStepEstimateOnly =>
      'Dit raakt alleen de schatting; de overige uitlezingen blijven geldig.';

  @override
  String get datumNextStepGenericObd =>
      'Je kunt doorgaan met algemene OBD, of het voertuig handmatig kiezen en de parameters invullen.';

  @override
  String get datumNextStepOtherReadings =>
      'De fout raakt alleen dit item; de overige uitlezingen blijven geldig.';

  @override
  String get datumNextStepRawOnly =>
      'Het ruwe antwoord en de fout kunnen worden geïnspecteerd; geen van beide mag als normale waarde worden gelezen.';

  @override
  String get datumReasonAssumptionsUnconfirmed =>
      'De aannames zijn onbevestigd; er wordt nog wel een schatting getoond.';

  @override
  String get datumReasonBusError => 'Busfout.';

  @override
  String get datumReasonFormulaError => 'Formulefout.';

  @override
  String get datumReasonFuelEstimateMissingInputs =>
      'Voor de schatting van het brandstofverbruik ontbreekt een vereiste invoer.';

  @override
  String get datumReasonHeaderNotOnThisBus =>
      'De header komt niet overeen met de bus die dit voertuig gebruikt.';

  @override
  String get datumReasonHorsepowerEstimateMissingInputs =>
      'Voor de schatting van het vermogen ontbreekt een vereiste invoer.';

  @override
  String get datumReasonMalformedPacket =>
      'Misvormd pakket; alleen het ruwe antwoord kan worden geïnspecteerd.';

  @override
  String get datumReasonNoAnswer =>
      'Geen antwoord — de app probeert het over ongeveer een minuut opnieuw.';

  @override
  String get datumReasonNoReadingYet => 'Nog geen uitlezing.';

  @override
  String get datumReasonNonFiniteValue => 'Geen eindig getal.';

  @override
  String get datumReasonOutOfReferenceRangeKept =>
      'Buiten het gebruikelijke referentiebereik; behouden zoals uitgelezen.';

  @override
  String get datumReasonPidUnsupported =>
      'Dit voertuig ondersteunt deze PID niet.';

  @override
  String get datumReasonUnsafeService =>
      'Deze service is geen alleen-lezen uitleesverzoek.';

  @override
  String get datumReasonUnsafeServiceStopped =>
      'Deze service is geen alleen-lezen uitleesverzoek en is daarom niet verzonden.';

  @override
  String get datumStatusAssumptions => 'Aannames';

  @override
  String get datumStatusClose => 'Sluiten';

  @override
  String get datumStatusFollowsData => 'Status volgt de gegevens';

  @override
  String get datumStatusDetailsHint =>
      'Tik voor details over de gegevensstatus';

  @override
  String get datumStatusUnverifiedExplanation =>
      'Ongeverifieerd betekent dat er hier voor deze decoder op jouw voertuig geen vergelijking met een echt voertuig is gedocumenteerd. Het betekent niet dat de uitlezing fout is, en het certificeert de nauwkeurigheid niet. Actualiteit en fouten worden apart getoond.';

  @override
  String get datumStatusFormula => 'Formule';

  @override
  String get derivedAirflow => 'Luchtstroom';

  @override
  String get derivedEcuFuelTitle => 'ECU-brandstofgegevens';

  @override
  String get derivedEcuReported => 'Gemeld door ECU';

  @override
  String get derivedEngineHorsepower => 'Motorvermogen';

  @override
  String get derivedEstimatedFuelTitle => 'Geschat brandstofverbruik';

  @override
  String get derivedEstimatesDetailsTitle => 'Schattingsformules en aannames';

  @override
  String get derivedEstimatesTitle => 'Geschatte waarden';

  @override
  String get derivedFuelUse => 'Brandstofverbruik';

  @override
  String get derivedTorque => 'Koppel';

  @override
  String get derivedUnavailableMessage =>
      'Het vermogen (pk) kan pas worden geschat zodra er gegevens over voertuigsnelheid en acceleratie binnenkomen';

  @override
  String dtcBothSilentDetail(Object mode) {
    return 'Het voertuig heeft niet geantwoord op het Mode $mode-uitleesverzoek en op Mode 03 kwam evenmin antwoord — het valt dus niet te zeggen of het voertuig dit niet ondersteunt of dat deze verbinding het simpelweg niet heeft uitgelezen.';
  }

  @override
  String dtcCategoryFault(Object category) {
    return 'Een storing met betrekking tot $category';
  }

  @override
  String get dtcClear => 'Wissen';

  @override
  String get dtcClearCancel => 'Annuleren';

  @override
  String get dtcClearConfirm => 'Codes wissen';

  @override
  String get dtcClearDialogBody =>
      'Hiermee worden opgeslagen en in afwachting zijnde storingscodes gewist en gaat het storingslampje uit, maar ook de emissiegereedheid wordt gereset — het voertuig moet opnieuw een volledige ronde zelfdiagnose voltooien voordat het voor een keuring kan slagen. Permanente storingscodes (Mode 0A) kunnen niet worden gewist.';

  @override
  String get dtcClearDialogFrameUnread =>
      'Deze scan heeft geen freeze-frame uitgelezen — dat betekent niet dat het voertuig er geen heeft. Scan eerst opnieuw en beslis daarna of je wilt wissen.';

  @override
  String dtcClearDialogFrames(Object codes) {
    return 'Het freeze-frame voor $codes gaat daarbij ook verloren — de volledige registratie van motortoerental, koelvloeistoftemperatuur en motorbelasting op het moment dat de storing optrad — en kan niet opnieuw worden uitgelezen totdat de storing zich weer voordoet.';
  }

  @override
  String get dtcClearDialogTitle => 'Storingscodes wissen?';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categorieën in deze scan',
      one: 'één categorie in deze scan',
    );
    return 'Bij $_temp0 ($categories) kwam geen volledig antwoord, dus er kunnen storingscodes zijn die je nog niet hebt gezien. Na het wissen kunnen ze nooit meer worden uitgelezen.';
  }

  @override
  String get dtcClearCancelledBeforeSend =>
      'Het wissen is geannuleerd voordat er een opdracht door de app is verzonden. Scan opnieuw en probeer het daarna nogmaals als je nog steeds wilt wissen.';

  @override
  String get dtcClearConfirmed => 'De wisopdracht is verzonden.';

  @override
  String get dtcClearFailureDoNotRepeat =>
      'Mogelijk heeft een wisopdracht het voertuig al bereikt. Stuur er geen tweede achteraan — een tweede globale wisopdracht kan de emissiegereedheid resetten op een regeleenheid die mogelijk al is gewist. Scan opnieuw om te zien wat er over is.';

  @override
  String get dtcClearFailureGeneric =>
      'Het wissen is niet voltooid. Scan opnieuw om de huidige codes te bekijken voordat je beslist of je het opnieuw wilt proberen.';

  @override
  String get dtcClearNotAccepted =>
      'Het wissen is mislukt; geen enkele regeleenheid heeft de opdracht geaccepteerd. Je kunt het opnieuw proberen.';

  @override
  String get dtcClearPartiallyConfirmed =>
      'Ten minste één regeleenheid meldde dat het wissen is voltooid en de overige konden niet worden bevestigd. Stuur geen nieuwe wisopdracht — herhalen reset de emissiegereedheid op regeleenheden die al klaar waren. Scan opnieuw om het resultaat te zien.';

  @override
  String get dtcClearPreviousConnectionUnconfirmed =>
      'Een eerdere verbinding heeft een wisopdracht verzonden waarvan het resultaat niet is bevestigd. Scan eerst opnieuw, bekijk welke codes er nog zijn en beslis daarna of je wilt wissen.';

  @override
  String get dtcClearRescanSettled =>
      'De vorige wisopdracht kon niet volledig worden bevestigd. Hieronder staat de daadwerkelijke status na deze nieuwe scan.';

  @override
  String get dtcClearSentUnconfirmed =>
      'De wisopdracht is verzonden, maar het antwoord raakte onderweg beschadigd, waardoor niet bekend is of het voertuig de codes heeft gewist. Scan opnieuw om dit te controleren; stuur geen nieuwe wisopdracht — als het wissen al is gelukt, reset herhalen de emissiegereedheid.';

  @override
  String get dtcClearTimeout =>
      'Er kwam geen antwoord nadat de wisopdracht was verzonden, waardoor niet bekend is of het voertuig de codes heeft gewist. Scan opnieuw om dit te controleren. Stuur niet blindelings nog een wisopdracht.';

  @override
  String get dtcClearUnexpected =>
      'Het wissen is mislukt, waardoor niet bekend is of het voertuig de codes heeft gewist. Scan opnieuw om dit te controleren. Stuur niet blindelings nog een wisopdracht.';

  @override
  String get dtcClearing => 'Wissen…';

  @override
  String get dtcScanDisconnectedMidScan =>
      'De verbinding werd tijdens de scan verbroken, waardoor deze scan niet is voltooid.';

  @override
  String get dtcScanInterrupted =>
      'De scan werd onderbroken (mogelijk ging de app naar de achtergrond of veranderde de verbinding) en leverde geen volledig resultaat op. Scan opnieuw.';

  @override
  String get dtcCompleteCleanBody =>
      'Dat betekent dat elke regeleenheid die antwoordde geen storingscode heeft gemeld. Het betekent niet dat elke module in het voertuig is bevraagd.';

  @override
  String get dtcCompleteCleanTitle =>
      'Geen van de regeleenheden die antwoordden heeft een storingscode gemeld.';

  @override
  String dtcControllerLabel(Object controller) {
    return 'Regeleenheid $controller';
  }

  @override
  String get dtcDismiss => 'Sluiten';

  @override
  String dtcFreezeFrameBody(Object code) {
    return 'De waarden die deze regeleenheid heeft vastgelegd op het moment dat $code werd bevestigd. Het wissen van storingscodes vernietigt ook deze registratie.';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      'Deze regeleenheid heeft een freeze-frame, maar beantwoordde niet de vraag welke items erin staan, waardoor de inhoud niet kon worden uitgelezen. Opnieuw scannen kan helpen.';

  @override
  String get dtcFreezeFrameNothingDecodable =>
      'Deze regeleenheid heeft een freeze-frame, maar geen van de items erin kan door deze app worden gedecodeerd.';

  @override
  String get dtcFreezeFrameTitle => 'Het voertuig op het moment van de storing';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Nog $count items in dit freeze-frame hebben geen omrekenformule in deze app en worden daarom niet vermeld.',
      one: 'Nog een item in dit freeze-frame heeft geen omrekenformule in deze app en wordt daarom niet vermeld.',
    );
    return '$_temp0';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count items kwamen deze keer niet terug (er was mogelijk onvoldoende tijd of de regeleenheid antwoordde niet). Bij opnieuw scannen kunnen ze mogelijk wel worden uitgelezen.',
      one: 'Eén item kwam deze keer niet terug (er was mogelijk onvoldoende tijd of de regeleenheid antwoordde niet). Bij opnieuw scannen kan het mogelijk wel worden uitgelezen.',
    );
    return '$_temp0';
  }

  @override
  String get dtcFreezeFrameUnreadPanel =>
      'Deze scan heeft geen freeze-frame uitgelezen — dat betekent niet dat het voertuig er geen heeft. Scan eerst opnieuw en beslis daarna of je de storingscodes wilt wissen, want wissen vernietigt de registratie van het storingsmoment definitief. Als elke scan hetzelfde laat zien, biedt dit voertuig er mogelijk geen aan.';

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label (Mode $mode) · $count';
  }

  @override
  String get dtcHeadline => 'Storingscodes';

  @override
  String get dtcListSeparator => ', ';

  @override
  String get dtcManufacturerSpecific =>
      'Fabrikantspecifieke code — raadpleeg het werkplaatshandboek voor dit voertuig';

  @override
  String get dtcMilOff => 'Het storingslampje brandt niet';

  @override
  String get dtcMilOn => 'Het storingslampje brandt';

  @override
  String get dtcMonitorBoostPressure => 'Laaddruk';

  @override
  String get dtcMonitorCatalyst => 'Katalysator';

  @override
  String get dtcMonitorComponents => 'Algemene componenten';

  @override
  String get dtcMonitorEgr => 'EGR / VVT-systeem';

  @override
  String get dtcMonitorEvaporative => 'Verdampingssysteem';

  @override
  String get dtcMonitorExhaustSensor => 'Uitlaatgassensor';

  @override
  String get dtcMonitorFuelSystem => 'Brandstofsysteem';

  @override
  String get dtcMonitorGasolineParticulateFilter =>
      'Benzinedeeltjesfilter (GPF)';

  @override
  String get dtcMonitorHeatedCatalyst => 'Verwarmde katalysator';

  @override
  String get dtcMonitorMisfire => 'Ontstekingsfout';

  @override
  String get dtcMonitorNmhcCatalyst => 'NMHC-katalysator';

  @override
  String get dtcMonitorNoxAftertreatment => 'NOx / SCR-nabehandeling';

  @override
  String get dtcMonitorOxygenSensor => 'Lambdasonde';

  @override
  String get dtcMonitorOxygenSensorHeater => 'Lambdasondeverwarming';

  @override
  String get dtcMonitorParticulateFilter => 'Roetfilter';

  @override
  String get dtcMonitorSecondaryAir => 'Secundair luchtsysteem';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — deze app heeft geen gedetailleerde beschrijving voor deze code';
  }

  @override
  String get dtcNotConnectedBody =>
      'Voor het uitlezen van storingscodes is een verbonden ELM327-adapter of de draaiende simulator nodig.';

  @override
  String get dtcNotConnectedTitle => 'Niet verbonden';

  @override
  String get dtcNotScanned => 'Nog niet gescand';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count regeleenheden',
      one: 'één regeleenheid',
    );
    return 'Alle drie de categorieën zijn volledig bevraagd. Bij $_temp0 ($controllers) zijn noch in afwachting zijnde noch permanente storingscodes geïmplementeerd — normaal bij veel voertuigen, en tevens de reden waarom dit voertuig niet storingsvrij kan worden verklaard.';
  }

  @override
  String get dtcPartialCleanTitle =>
      'De categorieën die antwoordden meldden geen storingscodes.';

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return 'Voor $categories kwam geen antwoord, dus de status daarvan kan niet worden bevestigd — dat is niet hetzelfde als een voertuig zonder problemen.';
  }

  @override
  String dtcPartialCodesRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Er zijn $count storingscodes uitgelezen',
      one: 'Er is één storingscode uitgelezen',
    );
    return '$_temp0 voordat deze categorie stopte, maar de dekking is onvolledig:';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return 'Slechts enkele regeleenheden in deze categorie hebben geantwoord en de rest reageerde niet, waardoor dit niet kan gelden als resultaat voor het hele voertuig. $message';
  }

  @override
  String get dtcReadFailed => 'Uitlezen mislukt';

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label (Mode $mode): $message';
  }

  @override
  String get dtcReadinessAllComplete =>
      'Elke gereedheidsmonitor waarvoor deze regeleenheid verantwoordelijk is, is voltooid.';

  @override
  String dtcReadinessIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count monitors zijn nog niet voltooid',
      one: '1 monitor is nog niet voltooid',
    );
    return '$_temp0 — een keuring op dit moment slaagt mogelijk niet.';
  }

  @override
  String get dtcReadinessSaysNothing =>
      'Deze regeleenheid meldde helemaal geen gereedheidsmonitors — mogelijk is deze niet verantwoordelijk voor emissiebewaking, en dat betekent niet dat deze gereed is.';

  @override
  String get dtcReadinessTitle => 'Emissiegereedheid';

  @override
  String get dtcRescanFirst => 'Scan eerst opnieuw';

  @override
  String get dtcRetry => 'Opnieuw';

  @override
  String get dtcScanBody =>
      'Leest opgeslagen (Mode 03), in afwachting zijnde (Mode 07) en permanente (Mode 0A) storingscodes uit.';

  @override
  String get dtcScanTitle => 'Scan het voertuig op storingscodes';

  @override
  String get dtcScanning => 'Scannen…';

  @override
  String dtcSelfReportedCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deze regeleenheid meldt zelf $count bevestigde storingscodes.',
      one: 'Deze regeleenheid meldt zelf 1 bevestigde storingscode.',
    );
    return '$_temp0';
  }

  @override
  String get dtcSelfReportedNoCodes =>
      'Deze regeleenheid meldt zelf geen bevestigde storingscodes.';

  @override
  String get dtcSilentCategoryHeadline =>
      'Deze categorie heeft niet geantwoord';

  @override
  String get dtcSilentPendingDetail =>
      'Op het verzoek om in afwachting zijnde storingscodes (Mode 07) kwam geen antwoord. Mogelijk ondersteunt deze ECU de service niet, of is deze nu simpelweg niet uitgelezen — zonder antwoord zijn die twee niet van elkaar te onderscheiden, en dit mag niet worden opgevat alsof er geen in afwachting zijnde storingen zijn. Het resultaat van de opgeslagen storingscodes blijft ongewijzigd.';

  @override
  String get dtcSilentPermanentDetail =>
      'Op het verzoek om permanente storingscodes (Mode 0A) kwam geen antwoord. Deze categorie werd geïntroduceerd met de OBD-II-generatie van rond 2010, dus oudere voertuigen ondersteunen deze niet altijd — maar geen antwoord kan net zo goed betekenen dat deze nu simpelweg niet is uitgelezen, en die twee zijn niet van elkaar te onderscheiden. Het resultaat van de opgeslagen storingscodes blijft ongewijzigd.';

  @override
  String get dtcStartScan => 'Scan starten';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return 'Het voertuig heeft niet geantwoord op het Mode $mode-uitleesverzoek, dus of er opgeslagen storingscodes zijn kan niet worden bevestigd. Dat is niet hetzelfde als geen storingscodes hebben.';
  }

  @override
  String dtcTotalCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count codes',
      one: '1 code',
    );
    return '$_temp0';
  }

  @override
  String get dtcUnconfirmed => 'Kan niet bevestigen';

  @override
  String get dtcUnknownError => 'Onbekende fout';

  @override
  String get dtcUnknownMonitor => 'Onbekende monitor';

  @override
  String get dtcVerdictCompleteClean =>
      'Geen storingscodes van de regeleenheden die antwoordden';

  @override
  String get dtcVerdictPartialClean => 'Gedeeltelijk onbevestigd';

  @override
  String get fieldEventBody =>
      'Gebruik deze knoppen alleen wanneer het voertuig volledig stilstaat, als passagier of als bestuurder van een geparkeerd voertuig. Gebeurtenissen delen één tijdlijn met de ruwe OBD-gegevens en de app probeert ze direct op te slaan.';

  @override
  String get fieldEventEngineStarted => 'Motor gestart';

  @override
  String get fieldEventHeading => 'Gebeurtenismarkeringen';

  @override
  String get fieldEventIgnitionOn => 'Contact aan';

  @override
  String get fieldEventMemoryOnly =>
      'Vastgelegd in deze sessie, maar automatisch opslaan is mislukt — exporteer het diagnoselogboek nu.';

  @override
  String fieldEventRecorded(String marker) {
    return 'Vastgelegd en opgeslagen: $marker';
  }

  @override
  String get fieldEventRoadTestStarted => 'Proefrit gestart';

  @override
  String get fieldEventThrottleBlip => 'Korte gasstoot';

  @override
  String get fieldEventUnavailable =>
      'Er is geen live verbinding met een voertuig waaraan een registratie kan worden gekoppeld.';

  @override
  String get gaugeNoData => 'Geen data';

  @override
  String gaugeNoDataBecause(String reason) {
    return 'Geen data — $reason';
  }

  @override
  String gaugeReadingStale(String reading) {
    return '$reading (gegevens zijn verouderd)';
  }

  @override
  String get gaugeUnsupportedByVehicle => 'Niet ondersteund door dit voertuig';

  @override
  String get handshakeNoteAborted => 'Gestopt nadat een eerdere stap mislukte.';

  @override
  String get handshakeNoteEcuRefusedSupportQuery =>
      'De ECU weigerde de ondersteuningsvraag (negatief antwoord).';

  @override
  String get handshakeNoteEcuSilent => 'De ECU heeft niet geantwoord.';

  @override
  String get handshakeNoteNotAcknowledged =>
      'De adapter heeft deze opdracht niet bevestigd.';

  @override
  String get handshakeNoteNotModeOnePositiveReply =>
      'Het antwoord is geen positieve Mode 01-respons.';

  @override
  String get handshakeNotePidEchoMismatch =>
      'Het antwoord herhaalt een andere PID dan waarom werd gevraagd.';

  @override
  String get handshakeNoteSupportMaskTooShort =>
      'Het ondersteuningsantwoord is te kort; 41 00 en nog vier bytes zijn vereist.';

  @override
  String get handshakeNoteTimedOut => 'Time-out.';

  @override
  String get handshakeStepAdapterVersion => 'Adapterversie uitlezen';

  @override
  String get handshakeStepAdaptiveTiming =>
      'Adaptieve timing inschakelen, de door het datablad aanbevolen instelling';

  @override
  String get handshakeStepBatteryVoltage => 'Accuspanning uitlezen';

  @override
  String get handshakeStepDeviceIdentity => 'Apparaatidentificatie uitlezen';

  @override
  String get handshakeStepEchoOff => 'Opdrachtecho uitschakelen';

  @override
  String get handshakeStepLinefeedsOff => 'Regelovergangen uitschakelen';

  @override
  String get handshakeStepMemoryOff => 'Schrijven naar geheugen uitschakelen';

  @override
  String get handshakeStepNoReason => 'geen antwoord';

  @override
  String get handshakeStepProtocolAuto => 'Busprotocol automatisch detecteren';

  @override
  String get handshakeStepProtocolDescription =>
      'Protocolbeschrijving uitlezen';

  @override
  String get handshakeStepProtocolNumber => 'Protocolnummer uitlezen';

  @override
  String get handshakeStepReset => 'Adapter softwarematig resetten';

  @override
  String get handshakeStepResponseTimeout =>
      'Antwoordtime-out instellen op ongeveer 408 ms';

  @override
  String get handshakeStepSpacesOff =>
      'Spaties uitschakelen (bespaart een derde van het verkeer)';

  @override
  String get handshakeStepSupportProbe =>
      'Opvragen welke PID\'s de ECU ondersteunt, als bewijs dat een voertuig antwoordde';

  @override
  String get languageSaveFailed =>
      'Kon de taal niet opslaan. Probeer het opnieuw.';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navDtc => 'Storingscodes';

  @override
  String get navPerformance => 'Tijdmeting';

  @override
  String get navPid => 'PID';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get performanceArm => 'Timer klaarzetten';

  @override
  String get performanceDisclaimer =>
      'Tijden zijn afkomstig van het OBD-rijsnelheidssignaal. De meeste voertuigen geven op hun eigen snelheidsmeter 1–3 km/h meer aan en het signaal wordt slechts circa 10–20 keer per seconde bijgewerkt; een resultaat hier is dus uitsluitend indicatief — niet gelijkwaardig aan professionele meetapparatuur.';

  @override
  String get performanceHeadline => 'Acceleratietest';

  @override
  String get performanceNoSpeedSignal =>
      'Er is momenteel geen geldig rijsnelheidssignaal (PID 010D). Zonder dit signaal kan de acceleratietest geen run timen.';

  @override
  String get performanceNotConnectedBody =>
      'De acceleratietest heeft live rijsnelheid nodig. Verbind een adapter of start de ingebouwde simulator.';

  @override
  String get performanceNotConnectedTitle => 'Niet verbonden';

  @override
  String get performancePeakSpeed => 'Pieksnelheid';

  @override
  String get performanceReset => 'Resetten';

  @override
  String get performanceSecondsUnit => 'seconden';

  @override
  String get performanceSpeedGaugeLabel => 'Snelheid';

  @override
  String get performanceSpeedTraceHeading => 'Snelheidsverloop';

  @override
  String get performanceSplitsHeading => 'Tussentijden';

  @override
  String get performanceStateAborted =>
      'Deze run is niet voltooid; hieronder staat wat er is vastgelegd voordat hij stopte';

  @override
  String get performanceStateAwaitingSpeedSignal =>
      'Wachten op een snelheidssignaal';

  @override
  String performanceStateAwaitingStandstill(String speed) {
    return 'Kom eerst volledig tot stilstand — nu $speed km/h';
  }

  @override
  String performanceStateFinished(int target) {
    return '0 → $target km/h voltooid';
  }

  @override
  String get performanceStateIdle => 'Kies een doelsnelheid en start daarna';

  @override
  String get performanceStateRunning => 'Tijdmeting';

  @override
  String get performanceStateStaged =>
      'Gereed — de klok start zodra je wegrijdt';

  @override
  String get performanceSubhead =>
      'Een getimede run vanuit stilstand naar een doelsnelheid';

  @override
  String get performanceTargetSpeedHeading => 'Doelsnelheid';

  @override
  String get pidActionCancel => 'Annuleren';

  @override
  String get pidActionDelete => 'Verwijderen';

  @override
  String get pidArrangeBody =>
      'Sleep om de volgorde te wijzigen. Het dashboard wordt van links naar rechts en van boven naar beneden gevuld, dus wat vooraan staat zie je als eerste.';

  @override
  String get pidArrangeEmptyMessage =>
      'Schakel er eerst een paar in de lijst in en kom daarna terug om ze te ordenen.';

  @override
  String get pidArrangeEmptyTitle => 'Er is nog geen PID ingeschakeld';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return 'De $count bevestigde toevoegen';
  }

  @override
  String get pidBulkActionAllActive => 'Alles al ingeschakeld';

  @override
  String get pidBulkActionIncomplete => 'Scangegevens zijn onvolledig';

  @override
  String get pidBulkActionLocked => 'Kan niet wijzigen tijdens opname';

  @override
  String get pidBulkActionPending => 'Wachten op scanresultaten';

  @override
  String get pidBulkActionZero => 'Geen bevestigde ondersteunde PID\'s';

  @override
  String pidBulkAddCount(int count) {
    return '$count toevoegen';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return '$count bevestigde ondersteunde PID\'s toevoegen?';
  }

  @override
  String pidBulkAdded(int count) {
    return '$count bevestigde ondersteunde PID\'s toegevoegd.';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '$count ondersteuningsblokken zijn nog onbevestigd — hiermee worden alleen de items met positief bewijs toegevoegd.';
  }

  @override
  String pidBulkWillAdd(int count) {
    return 'Voegt er $count toe. Hoe meer PID\'s er zijn ingeschakeld, hoe minder vaak elke afzonderlijke PID mogelijk wordt ververst.';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '$confirmed bevestigd';
  }

  @override
  String get pidCapabilityCoverageNone =>
      'Nog geen aaneengesloten dekking vastgesteld';

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return 'Aaneengesloten dekking 01–$through (einde bereikt)';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return 'Aaneengesloten dekking 01–$through (daarna onbekend)';
  }

  @override
  String get pidCapabilityPhaseAttemptFinished =>
      'Deze ondersteuningsscan is voltooid';

  @override
  String get pidCapabilityPhaseInterrupted =>
      'De ondersteuningsscan is onderbroken';

  @override
  String get pidCapabilityPhaseNotStarted => 'Scan niet gestart';

  @override
  String get pidCapabilityPhaseRunning =>
      'Bevestigen wat dit voertuig ondersteunt';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return 'Door voertuig ondersteunde PID\'s. $phase. $confirmed bevestigd. $unknown onbekende blokken.';
  }

  @override
  String get pidCapabilityTitle => 'Door voertuig ondersteunde PID\'s';

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '$unknown onbekende blokken';
  }

  @override
  String pidEditorCollision(String name) {
    return 'Een aangepaste PID gebruikt deze combinatie al ($name). Gebruik een andere mode + PID, header of achtervoegsel bij de naam.';
  }

  @override
  String pidEditorDeleteBody(String name) {
    return 'De definitie voor “$name” wordt verwijderd, de bijbehorende meter verdwijnt van het dashboard en dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get pidEditorDeleteTitle => 'Deze PID verwijderen?';

  @override
  String get pidEditorDiscard => 'Verwerpen';

  @override
  String get pidEditorDiscardBody =>
      'De wijzigingen aan deze PID zijn niet opgeslagen en gaan verloren als je weggaat.';

  @override
  String get pidEditorDiscardTitle => 'Niet-opgeslagen wijzigingen verwerpen?';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N verwijzen naar de antwoordbytes; SIGNED(), ABS(), LOG10(), $valSyntax en BARO zijn beschikbaar';
  }

  @override
  String get pidEditorFieldEquation => 'Expressie';

  @override
  String get pidEditorFieldHeader => 'CAN-header';

  @override
  String get pidEditorFieldMax => 'Maximum';

  @override
  String get pidEditorFieldMin => 'Minimum';

  @override
  String get pidEditorFieldModeAndPid => 'Mode + PID';

  @override
  String get pidEditorFieldName => 'Naam';

  @override
  String get pidEditorFieldSample => 'Testantwoordbytes';

  @override
  String get pidEditorFieldShortName => 'Korte naam (op de meter)';

  @override
  String get pidEditorFieldUnits => 'Eenheden';

  @override
  String get pidEditorHeaderHelper => '7E0 = motor';

  @override
  String get pidEditorKeepEditing => 'Blijven bewerken';

  @override
  String get pidEditorModeAndPidHelper => 'Bijvoorbeeld 010C of 221101';

  @override
  String get pidEditorSampleHelper =>
      'Voer hex in om het resultaat tijdens het typen te bekijken';

  @override
  String get pidEditorSave => 'Opslaan';

  @override
  String get pidEditorSectionFormula => 'Formule';

  @override
  String get pidEditorSectionIdentity => 'Identiteit';

  @override
  String get pidEditorSectionQuery => 'Uitleesverzoek';

  @override
  String get pidEditorSectionRangeAndPriority => 'Meterbereik en prioriteit';

  @override
  String get pidEditorTitleEdit => 'PID bewerken';

  @override
  String get pidEditorTitleNew => 'Nieuwe aangepaste PID';

  @override
  String pidExportFailed(String error) {
    return 'Exporteren mislukt: $error';
  }

  @override
  String get pidExportNoCustomPids =>
      'Er zijn geen aangepaste PID\'s om te exporteren.';

  @override
  String get pidImportNothingToImport => 'Geen definities om te importeren.';

  @override
  String pidImportLandedClean(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aangepaste PID\'s geïmporteerd.',
      one: '1 aangepaste PID geïmporteerd.',
    );
    return '$_temp0';
  }

  @override
  String pidImportLandedWithNotes(int count, String notes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items geïmporteerd, $notes.',
      one: '1 item geïmporteerd, $notes.',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteSkippedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rijen hadden problemen en zijn overgeslagen',
      one: '1 rij had problemen en is overgeslagen',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDefaultedRanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'voor $count rijen is het standaard meterbereik gebruikt',
      one: 'voor 1 rij is het standaard meterbereik gebruikt',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items hebben bestaande definities vervangen',
      one: '1 item heeft een bestaande definitie vervangen',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDuplicatesInFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count rijen waren duplicaten van een andere rij in het bestand en zijn overgeslagen',
      one: '1 rij was een duplicaat van een andere rij in het bestand en is overgeslagen',
    );
    return '$_temp0';
  }

  @override
  String get pidImportPickerFailed => 'Kon de bestandskiezer niet openen.';

  @override
  String get pidImportReadFailed => 'Kon het bestand niet lezen.';

  @override
  String get pidListSeparator => ', ';

  @override
  String get pidManagerActiveOnly => 'Alleen actief';

  @override
  String get pidManagerAdd => 'Nieuw';

  @override
  String get pidManagerArrangeDashboard => 'Dashboard indelen';

  @override
  String pidManagerCounts(int active, int total) {
    return '$active ingeschakeld · $total beschikbaar';
  }

  @override
  String get pidManagerExportCsv => 'Aangepaste PID\'s exporteren';

  @override
  String get pidManagerExportTorqueCsv => 'Torque-compatibele CSV exporteren';

  @override
  String get pidManagerExportHumanReport => 'Leesbaar PID-rapport exporteren';

  @override
  String get pidManagerHeadline => 'PID-beheer';

  @override
  String get pidManagerImportCsv => 'CSV importeren';

  @override
  String get pidManagerMoreActions => 'Meer';

  @override
  String get pidManagerNoMatchMessage =>
      'Probeer een ander zoekwoord of maak een aangepaste PID aan.';

  @override
  String get pidManagerNoMatchTitle => 'Geen overeenkomende PID';

  @override
  String get pidManagerPowertrainBatteryCatalog => 'Aandrijfaccu-catalogus';

  @override
  String get pidManagerSearchHint => 'Zoek op naam of PID-code…';

  @override
  String get pidPickCsvDialogTitle => 'Kies een CSV met PID-definities';

  @override
  String get pidPillCustom => 'Aangepast';

  @override
  String get pidPillUnsupported => 'Niet ondersteund';

  @override
  String get pidPreviewCannotEvaluate => 'Kan niet evalueren';

  @override
  String get pidPreviewResultLabel => 'Resultaat';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'Het voorbeeld vult $valueString in voor $dependencies; de echte waarde komt van die PID zodra er verbinding is.';
  }

  @override
  String get pidPreviewTitle => 'Live voorbeeld';

  @override
  String get pidPriorityHigh => 'Hoog';

  @override
  String get pidPriorityLow => 'Laag';

  @override
  String get pidPriorityMedium => 'Gemiddeld';

  @override
  String get pidPriorityVeryLow => 'Zeer laag';

  @override
  String get pidRowEdit => 'Bewerken';

  @override
  String pidRowShowOnDashboard(String name) {
    return 'Toon $name op het dashboard';
  }

  @override
  String pidRowStaleUnits(String units) {
    return '$units · verouderd';
  }

  @override
  String powertrainAuthorizationGranted(String profile) {
    return 'Accusignalen voor $profile staan aan voor deze verbinding';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return 'Kon niet inschakelen: $reason';
  }

  @override
  String get powertrainCancel => 'Annuleren';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return 'Profielen: $profiles · Eenmalige uitlezingen: $probeable';
  }

  @override
  String get powertrainCatalogLoadFailedBody =>
      'Integriteitsverificatie is niet geslaagd, dus er worden geen voertuiggegevens getoond of geïnstalleerd.';

  @override
  String get powertrainCatalogLoadFailedTitle =>
      'Offline catalogus kon niet worden geladen';

  @override
  String get powertrainCatalogNotVerified =>
      'De catalogus is niet door de verificatie gekomen, dus er kan niets worden geïnstalleerd.';

  @override
  String get powertrainCatalogRevalidate => 'Opnieuw verifiëren';

  @override
  String get powertrainCatalogScopeNote =>
      'De catalogus is uitgebreid, maar “we hebben gegevens gevonden” betekent niet “jouw auto wordt ondersteund”. Vermeldingen die uitsluitend voor onderzoek zijn, bevatten nooit een opdracht. Experimentele Mode 22-vermeldingen kunnen worden geïnstalleerd en gepolld, maar elke waarde krijgt het label ongeverifieerd; experimentele Mode 21 wordt eenmalig per bevestiging uitgelezen.';

  @override
  String get powertrainCatalogSearchHint =>
      'Zoek op merk, model, variant of markt…';

  @override
  String get powertrainCatalogTitle => 'Aandrijfaccu-catalogus';

  @override
  String get powertrainChooseCommandNote =>
      'Eén opdracht per poging: geen scan, geen batch, geen automatische herhaling.';

  @override
  String get powertrainChooseCommandTitle =>
      'Kies één vastgepind alleen-lezen uitleesverzoek';

  @override
  String get powertrainClose => 'Sluiten';

  @override
  String get powertrainConfirmAccept => 'Dit is de auto';

  @override
  String get powertrainConfirmBody =>
      'Geïnstalleerde profielsignalen worden pas uitgelezen nadat je bevestigt dat deze auto dat model is, en die bevestiging geldt uitsluitend voor deze verbinding.';

  @override
  String get powertrainConfirmButton => 'Voertuig bevestigen';

  @override
  String get powertrainConfirmDialogBody =>
      'Na bevestiging worden de alleen-lezen accu-uitleesverzoeken van dit profiel voor de rest van deze verbinding gepolld. Het verkeerde profiel kan getallen opleveren die plausibel lijken maar fout zijn — annuleer als je niet zeker bent.';

  @override
  String get powertrainConfirmDialogTitle => 'Bevestig het verbonden voertuig';

  @override
  String get powertrainConfirmTitle =>
      'Accusignalen van voertuig wachten op bevestiging';

  @override
  String get powertrainConnectFirst =>
      'Maak eerst verbinding; experimentele autorisatie wordt nooit over verbindingen heen bewaard.';

  @override
  String get powertrainConnectionChanged =>
      'De verbinding is gewijzigd — bevestig het voertuig opnieuw voor de nieuwe verbinding.';

  @override
  String get powertrainEnableLabInSettings =>
      'Schakel eerst het experimentele acculaboratorium in via Instellingen.';

  @override
  String get powertrainEvidencePhysicalVehicle => 'Projectvoertuig';

  @override
  String get powertrainEvidenceSourceBacked => 'Brongegevens';

  @override
  String get powertrainEvidenceSyntheticRig => 'Synthetische testopstelling';

  @override
  String get powertrainExperimentalDataDisclosure =>
      'Dit is een kandidaatuitlezing gelabeld door de auteurs van de bron, geen veiligheidsgarantie van de fabrikant of tussen modellen onderling; ELM327 stuurt de opdracht alleen door. De ruwe opdracht en het antwoord blijven in het lokale diagnoselogboek en worden door deze functie niet automatisch geüpload; gedecodeerde waarden worden nooit als PID geïnstalleerd of aan een meter toegevoegd. Annuleren heeft geen invloed op gewone OBD-functies.';

  @override
  String get powertrainExperimentalDialogTitle =>
      'Eenmalige experimentele alleen-lezen bevestiging';

  @override
  String get powertrainExperimentalIdentityAck =>
      'Ik heb de markt, het model en het modeljaar die bij de bron bekend zijn gecontroleerd en ik accepteer de onbevestigde velden';

  @override
  String get powertrainExperimentalParkedAck =>
      'Het voertuig staat veilig geparkeerd; ik begrijp dat dit eenmalig wordt uitgelezen en dat het getal alsnog niet van toepassing kan zijn';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return 'Accepteert uitsluitend RX $responder, payloadlengte $bytes bytes';
  }

  @override
  String get powertrainFieldListSeparator => ', ';

  @override
  String get powertrainFieldMarket => 'Markt';

  @override
  String get powertrainFieldModel => 'Model';

  @override
  String get powertrainFieldModelYear => 'Modeljaar';

  @override
  String get powertrainFieldVariant => 'Variant';

  @override
  String get powertrainFilterAll => 'Alle';

  @override
  String get powertrainIdentityEvidenceExact => 'direct bewijs';

  @override
  String get powertrainIdentityEvidenceNone => 'geen';

  @override
  String get powertrainIdentityEvidenceSourcePartial => 'gedeeltelijk bewijs';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return 'Bronbewijs voor de voertuigidentiteit: $fields\nOnbevestigde velden: $unconfirmed';
  }

  @override
  String get powertrainIdentityEvidenceUnknown => 'onbekend';

  @override
  String get powertrainInstallButton => 'Accusignalen installeren';

  @override
  String get powertrainInstallConfirm => 'Installeren';

  @override
  String get powertrainInstallDialogTitle =>
      'Accusignalen van dit model installeren';

  @override
  String get powertrainInstallDisclosureCommunity =>
      'Installeren voegt uitsluitend alleen-lezen accu-PID\'s toe aan PID-beheer. Voordat het uitlezen begint, word je bij elke verbinding op het dashboard gevraagd te bevestigen dat deze auto dat model is. De gegevens komen uit communitybronnen en zijn onafhankelijk bevestigd; het blijft geen garantie van de fabrikant.';

  @override
  String get powertrainInstallDisclosureExperimental =>
      'Installeren voegt uitsluitend alleen-lezen accu-PID\'s toe aan PID-beheer. Voordat het uitlezen begint, word je bij elke verbinding op het dashboard gevraagd te bevestigen dat deze auto dat model is. Dit is een experimentele decodering zonder vereiste van onafhankelijke bevestiging, ongeverifieerd op dit voertuig en nog steeds geen garantie van de fabrikant.';

  @override
  String get powertrainInstallDisclosureReady =>
      'Installeren voegt uitsluitend alleen-lezen accu-PID\'s toe aan PID-beheer. Voordat het uitlezen begint, word je bij elke verbinding op het dashboard gevraagd te bevestigen dat deze auto dat model is. De brongegevens zijn vollediger; het blijft geen garantie van de fabrikant.';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      'Installeren voegt uitsluitend alleen-lezen accu-PID\'s toe aan PID-beheer. Voordat het uitlezen begint, word je bij elke verbinding op het dashboard gevraagd te bevestigen dat deze auto dat model is. Deze vermelding is uitsluitend voor onderzoek en mag niet worden geïnstalleerd.';

  @override
  String get powertrainInstallCatalogShaMissing =>
      'Kan niet installeren: deze catalogus-momentopname heeft geen geverifieerde SHA-256, dus niets erin kan worden vertrouwd.';

  @override
  String get powertrainInstallPersistFailed =>
      'Kan niet installeren: de lijst met geïnstalleerde profielen kon niet worden opgeslagen. Probeer het opnieuw; er is niets toegevoegd aan PID-beheer.';

  @override
  String get powertrainInstallProfileNotInCatalog =>
      'Kan niet installeren: dat profiel staat niet in de geverifieerde catalogus.';

  @override
  String get powertrainInstallProfileNotInstallable =>
      'Kan niet installeren: dit profiel verkeert niet in een status die kan worden omgezet naar live PID\'s.';

  @override
  String get powertrainInstallYearOutOfRange =>
      'Kan niet installeren: dat modeljaar valt buiten het gedocumenteerde jaarbereik van dit profiel.';

  @override
  String get powertrainInstallIdentityAck =>
      'Mijn voertuig komt overeen met de markt, het model en het modeljaar hierboven';

  @override
  String get powertrainInstalledRemoveButton =>
      'Geïnstalleerd · signalen verwijderen';

  @override
  String powertrainInstalledSignalsSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count signalen geïnstalleerd. Voeg ze vanaf de PID-pagina toe aan het dashboard; bij elke verbinding is een voertuigbevestiging vereist.',
      one: '1 signaal geïnstalleerd. Voeg het vanaf de PID-pagina toe aan het dashboard; bij elke verbinding is een voertuigbevestiging vereist.',
    );
    return '$_temp0';
  }

  @override
  String get powertrainNoMatchBody =>
      'Probeer een merk- of modelnaam, of schakel over naar een ander aandrijflijntype.';

  @override
  String get powertrainNoMatchTitle => 'Geen overeenkomend voertuig';

  @override
  String get powertrainNotInstallableInThisRelease =>
      'Niet installeerbaar in deze versie';

  @override
  String powertrainPrimarySource(String name, String license) {
    return 'Primaire bron: $name ($license)';
  }

  @override
  String get powertrainProbeChecksPassed =>
      'Geslaagd voor de controles op responder, echo, exacte lengte, formule en bereik.';

  @override
  String get powertrainProbeConnectForOneShot =>
      'Verbind voor een eenmalig alleen-lezen uitleesverzoek';

  @override
  String get powertrainProbeConnectToTryOnce =>
      'Verbind om eerst één uitlezing te proberen';

  @override
  String get powertrainProbeDidNotFinish =>
      'Het eenmalige uitleesverzoek is niet voltooid; er is geen waarde gepubliceerd of bewaard.';

  @override
  String get powertrainProbeEnableLabFirst =>
      'Schakel eerst het laboratorium in via Instellingen';

  @override
  String get powertrainProbeInProgress => 'Eenmalig uitlezen…';

  @override
  String get powertrainProbeNoValuePublished =>
      'Er is geen waarde gepubliceerd; een structuur- of decodeerfout blijft in quarantaine totdat je opnieuw verbindt.';

  @override
  String get powertrainProbeOnceButton => 'Slechts eenmalig uitlezen';

  @override
  String get powertrainProbePassedTitle => 'Eenmalig uitleesverzoek geslaagd';

  @override
  String get powertrainProbePickOneRead =>
      'Kies één opdracht, lees eenmalig uit';

  @override
  String get powertrainProbeReconnectFirst =>
      'Verbind opnieuw en probeer het daarna nogmaals';

  @override
  String get powertrainProbeRefusedTitle => 'Eenmalig uitleesverzoek geweigerd';

  @override
  String get powertrainProbeTryOnceFirst => 'Probeer eerst één uitlezing';

  @override
  String get powertrainProfileNotVerified =>
      'Het profiel staat niet in de geverifieerde catalogus';

  @override
  String get powertrainQuarantinedPill => 'In quarantaine · verbind opnieuw';

  @override
  String get powertrainRefusedCatalogHashInvalid =>
      'Niet geautoriseerd: de integriteitshash van de catalogus is ongeldig, dus er kan niets uit worden uitgelezen.';

  @override
  String get powertrainRefusedCommandNotInProfile =>
      'Niet geautoriseerd: die opdracht hoort niet bij de eigen opdrachten van dit geverifieerde profiel.';

  @override
  String get powertrainRefusedLabClosed =>
      'Het experimentele acculaboratorium is uitgeschakeld voordat deze uitlezing kon worden geautoriseerd.';

  @override
  String get powertrainRefusedProfileFailedValidation =>
      'Niet geautoriseerd: dit profiel kwam niet door de catalogusvalidatie met het door jou gekozen modeljaar.';

  @override
  String get powertrainRefusedProfileNotInCatalog =>
      'Niet geautoriseerd: dit profiel staat niet in de geverifieerde catalogus.';

  @override
  String get powertrainRefusedProfileNotProbeable =>
      'Niet geautoriseerd: dit profiel kan niet eenmalig experimenteel worden uitgelezen.';

  @override
  String get powertrainRefusedQuarantinedAfterRejectedRead =>
      'In quarantaine voor deze verbinding: een eerdere eenmalige uitlezing kwam niet door de structuurcontroles. Verbind opnieuw voordat je het nogmaals probeert.';

  @override
  String get powertrainRefusedNotConnectedOrNotInForeground =>
      'De eenmalige uitlezing is niet gestart: er is niets verbonden of de app was niet op de voorgrond.';

  @override
  String get powertrainRefusedNoLiveAuthorization =>
      'De eenmalige uitlezing is niet gestart: er is geen actieve eenmalige autorisatie. Er is geen autorisatie gegeven, of deze is verlopen, zit in een afkoelperiode of is in quarantaine geplaatst.';

  @override
  String get powertrainRefusedDiscardedAtLifecycleBoundary =>
      'De verbinding of de voorgrondstatus veranderde terwijl de eenmalige uitlezing liep, waardoor het antwoord is verworpen in plaats van getoond. Er is niets mislukt en er is niets bewaard.';

  @override
  String powertrainRefusedQuarantinedAtAttemptCap(int attemptCap) {
    return 'In quarantaine voor deze verbinding: dezelfde opdracht is al $attemptCap keer geprobeerd. Verbind opnieuw voordat je het nogmaals probeert.';
  }

  @override
  String get powertrainResearchOnlyNeverQueries =>
      'Alleen onderzoek — verstuurt nooit uitleesverzoeken';

  @override
  String get powertrainRestoreStorageErrorRetry =>
      'Er is een opslagfout opgetreden bij het herstellen van eerdere installaties. Dit is opnieuw ingepland — probeer het opnieuw.';

  @override
  String powertrainSecondarySource(String name, String license) {
    return 'Onafhankelijke bevestiging: $name ($license)';
  }

  @override
  String powertrainSignalCount(int count) {
    return 'Signalen: $count';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return 'SHA-256 van bronbestand: $hash…';
  }

  @override
  String get powertrainStatusCommunity => 'Community · ongeverifieerd';

  @override
  String get powertrainStatusExperimental => 'Experimenteel · ongeverifieerd';

  @override
  String get powertrainStatusExperimentalProbeOnly =>
      'Experimenteel · eenmalig lezen';

  @override
  String get powertrainStatusReady => 'Volledigere brongegevens';

  @override
  String get powertrainStatusResearchOnly => 'Alleen onderzoek';

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return 'De geïnstalleerde signalen voor $name zijn verwijderd.';
  }

  @override
  String powertrainVehicleYearFixed(int year) {
    return 'Modeljaar: $year';
  }

  @override
  String get powertrainVehicleYearLabel => 'Modeljaar';

  @override
  String get recommendedPurchaseDisclosure =>
      'Dit is een affiliatelink van de beheerder; een in aanmerking komende aankoop kan de beheerder een commissie opleveren. Het is geen adaptercertificering of aankoopgarantie. De inhoud van de productpagina en hardwarerevisies kunnen veranderen, dus controleer vóór aankoop het volledige modelnummer en NCC-nummer. Het staat je ook vrij om zelf naar andere verkopers te zoeken.';

  @override
  String get recommendedPurchaseHeading => 'Aanbevolen adapter';

  @override
  String recommendedPurchaseModelLine(String model, String approval) {
    return 'Model $model · NCC $approval';
  }

  @override
  String recommendedPurchaseNoAdapterYet(String store) {
    return 'Nog geen adapter? Bekijk het aanbevolen exemplaar op $store';
  }

  @override
  String recommendedPurchaseOpenFailed(String store) {
    return 'Kon de link naar $store niet openen';
  }

  @override
  String get recommendedPurchaseShortDisclosureAction =>
      'Volledige toelichting in Instellingen';

  @override
  String get recommendedPurchaseShortDisclosureLead =>
      'Dit is een affiliatelink, geen adaptercertificering.';

  @override
  String get recommendedPurchaseStoreShopee => 'Shopee';

  @override
  String recommendedPurchaseViewOnStore(String store) {
    return 'Bekijken op $store';
  }

  @override
  String get semanticsFieldSeparator => ', ';

  @override
  String get settingsAdapterConcernsFooter =>
      'Dit zijn punten waarop de zelfbeschrijving van de adapter niet klopt, geen bewijs dat de adapter de auto verkeerd heeft uitgelezen. De enige manier om een waarde te bevestigen is een tweede onafhankelijke meting (zie de praktijkgids).';

  @override
  String get settingsAdapterNoContradictions =>
      'Geen tegenstrijdigheden in de zelfbeschrijving gevonden. Dat betekent alleen dat de adapter consistent is over zichzelf — het is geen bewijs dat de chip echt is en geen bewijs dat de gemelde getallen kloppen. Bij een kloon is de versietekst slechts tekst die iemand heeft gekozen.';

  @override
  String get settingsAdapterNoVersion => '(geen versie gemeld)';

  @override
  String get settingsAdapterSelfReportTitle =>
      'Wat de adapter over zichzelf zegt';

  @override
  String get settingsBatteryLabDialogBody =>
      'Dit zijn via reverse-engineering verkregen kandidaatbronnen, geen fabrikantdocumentatie en geen Telltale-ondersteuning voor jouw voertuig. Zelfs een alleen-lezen uitleesverzoek kan een regeleenheid wekken; een gedecodeerd getal kan plausibel lijken en toch niet van toepassing zijn.';

  @override
  String get settingsBatteryLabDialogTitle => 'Acculaboratorium inschakelen';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      'Het acculaboratorium staat voor deze sessie uit, maar de instelling kon niet worden opgeslagen; bij de volgende start kan het laboratorium weer zichtbaar zijn en elk uitleesverzoek vereist nog steeds een eigen bevestiging.';

  @override
  String get settingsBatteryLabEnableNotSaved =>
      'Kon de instelling voor het acculaboratorium niet opslaan; deze blijft uitgeschakeld.';

  @override
  String get settingsBatteryLabEvidenceAck =>
      'Ik begrijp dat de brongegevens en de synthetische tests niet bewijzen dat dit op mijn eigen voertuig van toepassing is';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      'Maakt uitsluitend eenmalige alleen-lezen uitleesverzoeken zichtbaar waarvan de bronnen volledig en hash-gebonden zijn. Het installeert geen PID\'s, pollt niet, voegt geen meters toe en behandelt onderzoeksgegevens niet als ondersteuning.';

  @override
  String get settingsBatteryLabSwitchTitle =>
      'Acculaboratorium (experimenteel)';

  @override
  String get settingsBatteryLabUnlockReadOnly =>
      'Uitsluitend eenmalige alleen-lezen uitleesverzoeken ontgrendelen';

  @override
  String get settingsBatteryLabWireAck =>
      'Ik begrijp dat dit uitsluitend eenmalige uitleesverzoeken op vaste Mode 21/22-adressen uit de catalogus ontgrendelt — geen scans, geen diagnosesessie, geen beveiligingstoegang, geen schrijfacties, geen aansturing';

  @override
  String get settingsCancel => 'Annuleren';

  @override
  String get settingsCatalogChoose => 'Kiezen uit de officiële catalogus';

  @override
  String get settingsCatalogCorrupt =>
      'De officiële offline catalogus is beschadigd of kon niet worden geladen; er is niets toegepast.';

  @override
  String get settingsCatalogNothingApplicable =>
      'Deze officiële configuratie heeft geen veld dat veilig op de huidige formules kan worden toegepast; het bestaande profiel blijft ongewijzigd.';

  @override
  String get settingsCatalogScope =>
      'Officiële catalogi: U.S. EPA, Taiwan MOEA, Canada NRCan. Elke momentopname geldt uitsluitend voor die markt, niet voor elk merk of bouwjaar wereldwijd.';

  @override
  String get settingsCatalogVerifying => 'Offline catalogus verifiëren…';

  @override
  String get settingsCatalogChooseMarket =>
      'Kies welke officiële catalogus je wilt doorbladeren';

  @override
  String get settingsCatalogMarketTw => 'Taiwan (MOEA-energieadministratie)';

  @override
  String get settingsCatalogMarketUs => 'Verenigde Staten (EPA)';

  @override
  String get settingsTwCertificationYear => 'Certificeringsjaar';

  @override
  String get settingsTwMake => 'Merk (Taiwan)';

  @override
  String settingsTwPickerScope(int firstYear, int lastYear) {
    return 'Uitsluitend certificeringsrijen voor de Taiwanese markt voor $firstYear–$lastYear. Het jaar is het certificeringskalenderjaar van de Energy Administration, geen Amerikaans model year. Een overeenkomende merk-/modelnaam is geen EPA-configuratie.';
  }

  @override
  String get settingsTwPickerTitle => 'Officiële Taiwanese voertuigcatalogus';

  @override
  String get settingsTwReferenceMassNotCurb =>
      'Referentievoertuigmassa is geen curb mass en wordt niet toegepast.';

  @override
  String settingsTwWillApplyOnly(String fields) {
    return 'Alleen $fields wordt toegepast. Referentiemassa, VE, Cd, frontaal oppervlak, Crr en transmissierendement blijven onopgelost.';
  }

  @override
  String get settingsClose => 'Sluiten';

  @override
  String get settingsConnectionSection => 'Verbinding';

  @override
  String get settingsDiagnosticsSection => 'Diagnoselogboek';

  @override
  String get settingsDisconnect => 'Verbinding verbreken';

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return 'Transmissierendement $percent %';
  }

  @override
  String settingsEpaApplyFields(int count) {
    return '$count officiële velden toepassen';
  }

  @override
  String get settingsEpaChooseExact => 'Kies een exacte configuratie';

  @override
  String get settingsEpaCloseNoFields => 'Sluiten (geen toepasbare velden)';

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'EPA-configuratie $epaId';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count cil.';
  }

  @override
  String get settingsEpaDriveUnknown => 'Aandrijving onbekend';

  @override
  String get settingsEpaFuelUnknown => 'Brandstof onbekend';

  @override
  String get settingsEpaMake => 'EPA-merk (afdeling)';

  @override
  String get settingsEpaModel => 'Model';

  @override
  String get settingsEpaNoConfigurations =>
      'Geen configuraties beschikbaar voor dit model';

  @override
  String get settingsEpaNoSafeFields =>
      'Deze configuratie heeft geen veld dat veilig op de huidige formules kan worden toegepast; er wordt niets gegokt.';

  @override
  String get settingsEpaPickInOrder =>
      'Kies op volgorde modeljaar, merk en model';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return 'Uitsluitend momentopname-configuraties voor de Amerikaanse markt voor $firstYear–$lastYear. Voor modellen met dezelfde naam zijn nog steeds het modeljaar, de transmissie, de brandstof en de EPA-ID nodig om ze uit elkaar te houden.';
  }

  @override
  String get settingsEpaPickerTitle => 'Officiële U.S. EPA-voertuigcatalogus';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return 'Alleen $fields wordt toegepast. Massa, VE, Cd, frontaal oppervlak, Crr en transmissierendement blijven onopgelost.';
  }

  @override
  String get settingsEpaYear => 'Modeljaar';

  @override
  String get settingsExperimentalSection => 'Experimenteel';

  @override
  String get settingsFieldDisplacement => 'Cilinderinhoud';

  @override
  String get settingsFieldDragCoefficient => 'Luchtweerstandscoëfficiënt Cd';

  @override
  String get settingsFieldDrivetrain => 'Aandrijving';

  @override
  String get settingsFieldFrontalArea => 'Frontaal oppervlak';

  @override
  String get settingsFieldFuel => 'Brandstof';

  @override
  String get settingsFieldMass => 'Massa';

  @override
  String get settingsFieldMassWithDriver => 'Massa (met bestuurder)';

  @override
  String get settingsFieldRollingResistance => 'Rolweerstand Crr';

  @override
  String get settingsFieldVolumetricEfficiency => 'Volumetrisch rendement VE';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return 'Lucht-brandstofverhouding $afr · dichtheid $density g/L';
  }

  @override
  String get settingsFuelAndDrivetrainSection => 'Brandstof en aandrijving';

  @override
  String get settingsFuelTypeLabel => 'Brandstoftype';

  @override
  String get settingsGaugeSkinBody =>
      'Niet alleen een andere kleur — elke stijl heeft een eigen wijzerplaat, naald en beweging. Ze werken allemaal op donkere en lichte achtergronden.';

  @override
  String get settingsGaugeSkinTitle => 'Meterstijl';

  @override
  String get settingsGoToConnect => 'Ga naar Verbinden';

  @override
  String get settingsHeadline => 'Instellingen';

  @override
  String get settingsLicenseLegalese =>
      'Bronnen, bewerkingen en hergebruiksvoorwaarden voor aandrijfaccu\'s zijn bij deze app inbegrepen.';

  @override
  String get settingsListSeparator => ', ';

  @override
  String get settingsManualCommandBody =>
      'Stuur één opdracht rechtstreeks naar de adapter — bijvoorbeeld ATI, ATDPN, 0100. Deze sluit aan in dezelfde wachtrij als normale polling en dringt niet voor.';

  @override
  String get settingsManualCommandFieldLabel => 'Opdracht';

  @override
  String get settingsManualCommandNoContent => '(geen antwoordinhoud)';

  @override
  String get settingsManualCommandSend => 'Verzenden';

  @override
  String get settingsManualCommandTitle => 'Handmatige opdracht';

  @override
  String get settingsNotConnected => 'Niet verbonden';

  @override
  String get settingsOpenSourceLicenses => 'Opensource- en datalicenties';

  @override
  String get settingsProfileConfirmAfterConnect =>
      'Verbind om dit voertuig te bevestigen';

  @override
  String get settingsProfileConfirmButton =>
      'Bevestig dit voertuig voor deze verbinding';

  @override
  String get settingsProfileConfirmedButton => 'Bevestigd voor deze verbinding';

  @override
  String get settingsProfileConfirmedDetail =>
      'Het profiel is bevestigd voor deze verbinding. Als je een waarde wijzigt of opnieuw verbindt, moet je opnieuw bevestigen.';

  @override
  String get settingsProfileEstimatesIntro =>
      'Vermogen (pk), koppel en brandstofverbruik worden uit deze parameters geschat; hoe dichter ze bij het daadwerkelijke voertuig liggen, hoe meer de schattingen betekenen.';

  @override
  String get settingsProfileNameProvesNothing =>
      'Een merknaam of een VIN alleen bewijst niets over massa, luchtweerstand, VE of transmissierendement.';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      'Niet bevestigd voor deze verbinding. Gemeten OBD-uitlezingen worden wel getoond, maar waarden geschat op basis van massa, VE en luchtweerstand niet.';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      'Maak eerst verbinding met dit voertuig voordat je bevestigt. De bevestiging vervalt bij elke nieuwe verbinding, zodat het profiel van de ene auto nooit op de volgende wordt toegepast.';

  @override
  String get settingsProvenanceNoneExact =>
      'Er is geen enkel veld exact tot dit voertuig herleid; algemene, handmatig ingevoerde en oudere bronwaarden moeten allemaal nog worden bevestigd.';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return 'Velden met een exacte officiële bron: $fields. Elk ander veld moet nog één voor één worden bevestigd.';
  }

  @override
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  ) {
    return 'Herkomst: officieel of fabrikant $official / $total velden · door gebruiker ingevoerd $user / $total · algemene standaardwaarde $generic / $total · wetenschappelijk model $scientific / $total';
  }

  @override
  String settingsProvenancePublishers(String publishers) {
    return 'Bronnen: $publishers';
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
    return 'Vaststelling: officieel exact $exact / $total velden · in deze sessie bevestigd $sessionConfirmed / $total · onopgelost $unresolved / $total · meerduidig $ambiguous / $total · tegenstrijdig $conflict / $total';
  }

  @override
  String get settingsStandardsFooter =>
      'De OBD2-implementatie van deze app volgt openbare standaarden, waaronder SAE J1979 en het ELM327-datablad; elke formule en AT-opdracht die het gedrag van de hardware beïnvloedt is kruiselings geverifieerd en de resultaten zijn vastgelegd in docs/protocol-deviations.zh-TW.md. Deze app is niet gelieerd aan Torque of Torque Pro.';

  @override
  String get settingsThemeDark => 'Donker';

  @override
  String get settingsThemeLight => 'Licht';

  @override
  String get settingsThemeSystem => 'Systeem volgen';

  @override
  String get settingsVehicleProfileSection => 'Voertuigprofiel';

  @override
  String get settingsVinConflict => 'VIN-conflict';

  @override
  String get settingsVinConflictDetail =>
      'Regeleenheden meldden verschillende VIN\'s, waardoor de voertuigidentiteit niet kan worden bevestigd; elke kandidaat is verworpen.';

  @override
  String get settingsVinNotRead => 'VIN nog niet uitgelezen';

  @override
  String get settingsVinNotReadConnectedDetail =>
      'Het Mode 09-VIN kan nu uit het voertuig worden uitgelezen; de identiteit wordt uitsluitend voor deze verbinding bewaard. Het ruwe diagnoselogboek kan het VIN nog steeds bevatten.';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      'Zodra er verbinding is, kan het VIN dat het voertuig over zichzelf meldt worden uitgelezen; de identiteit wordt niet meegenomen naar de volgende verbinding. Het ruwe diagnoselogboek kan het VIN nog steeds bevatten.';

  @override
  String get settingsVinRead => 'VIN uitlezen';

  @override
  String get settingsVinReading => 'Uitlezen…';

  @override
  String get settingsVinReportedDetail =>
      'Een VIN is wat het voertuig over zichzelf meldt; het verifieert niet de specificaties van het model. De identiteit gaat niet mee over verbindingen heen; het diagnoselogboek kan het VIN nog steeds bevatten.';

  @override
  String get settingsVinSimulatorReported => 'Door simulator gemeld VIN';

  @override
  String get settingsVinUnavailable => 'VIN niet beschikbaar';

  @override
  String get settingsVinUnavailableDetail =>
      'Mogelijk biedt het voertuig er geen aan, was het antwoord onvolledig of is het tijdens deze verbinding niet uitgelezen; er wordt niets gegokt en er worden geen tekens aangevuld.';

  @override
  String get settingsVinVehicleReported => 'Door voertuig gemeld VIN';

  @override
  String get startupCannotComplete => 'Kan opstartcontroles niet voltooien';

  @override
  String get startupChecking =>
      'Lokale deelcache en telemetrieopnamen controleren';

  @override
  String get startupRestartHint =>
      'Lokale deelcache of telemetrieopnamen konden niet worden bevestigd. Sluit Telltale volledig af en open de app opnieuw, zodat niet het verkeerde bestand wordt overschreven, verwijderd of gedeeld.';

  @override
  String get startupRestartRequired =>
      'Herstart vereist om veilig verder te gaan';

  @override
  String get startupRetry => 'Opnieuw';

  @override
  String get startupRetryHint =>
      'Houd Telltale op de voorgrond en probeer het opnieuw nadat andere bestandsbewerkingen zijn voltooid. Opnemen, afspelen, exporteren en verwijderen blijven gesloten totdat het opstarten is voltooid.';

  @override
  String get telemetryArtifactRestartRequired =>
      'De status van lokale bestandsbewerkingen kan niet worden bevestigd. Sluit Telltale volledig af en open de app opnieuw voordat je verdergaat';

  @override
  String get telemetryBlockedByRecorder => 'Stop en bewaar eerst de opname';

  @override
  String get telemetryCancel => 'Annuleren';

  @override
  String get telemetryDamagedCollision =>
      'Een voltooid en een onvoltooid bestand delen deze ID — geen van beide is gekozen';

  @override
  String get telemetryDamagedCorrupt =>
      'De opname is beschadigd en kan niet veilig worden gelezen';

  @override
  String telemetryDamagedFileTime(String time) {
    return 'Bestandstijd $time';
  }

  @override
  String get telemetryDelete => 'Verwijderen';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return 'Hiermee wordt $id (bestandstijd $time) verwijderd. Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get telemetryDeleteDamagedTitle =>
      'Deze beschadigde opname verwijderen?';

  @override
  String get telemetryDeleteDamagedTooltip => 'Beschadigde opname verwijderen';

  @override
  String telemetryDeleteFailed(String reason) {
    return 'Verwijderen is niet voltooid: $reason';
  }

  @override
  String get telemetryDeleteNeedsConfirmation =>
      'Bevestig eerst deze verwijdering';

  @override
  String telemetryDeleteSessionBody(String time) {
    return 'Hiermee wordt de opname van $time verwijderd. Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get telemetryDeleteSessionTitle => 'Deze lokale opname verwijderen?';

  @override
  String get telemetryDemoData => 'Gegevens van ingebouwde simulator';

  @override
  String get telemetryDismissNotice => 'Sluiten';

  @override
  String get telemetryEndedByBackground =>
      'Gestopt toen Telltale naar de achtergrond ging';

  @override
  String get telemetryEndedByConfigurationChanged =>
      'De PID-selectie is gewijzigd';

  @override
  String get telemetryEndedByDisconnect =>
      'Gestopt toen de verbinding werd verbroken';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return 'Limiet van $minutes minuten bereikt';
  }

  @override
  String get telemetryEndedByLibrarySizeLimit =>
      'Lokale opslag voor opnamen is vol';

  @override
  String get telemetryEndedByRecoveredAfterInterruption =>
      'Hersteld na de laatste onderbreking';

  @override
  String get telemetryEndedBySessionReplacement =>
      'De verbindingssessie is vervangen';

  @override
  String get telemetryEndedBySessionSizeLimit =>
      'Deze opname heeft de groottelimiet bereikt';

  @override
  String get telemetryEndedByStorageBackpressure =>
      'De opslag kon het tempo niet bijhouden';

  @override
  String get telemetryEndedByStorageFailure => 'Opslaan is mislukt';

  @override
  String get telemetryEndedByUser => 'Door jou gestopt';

  @override
  String get telemetryExport => 'Exporteren';

  @override
  String get telemetryExportCsv => 'CSV exporteren';

  @override
  String telemetryExportFailed(String reason) {
    return 'Exporteren is niet voltooid: $reason';
  }

  @override
  String get telemetryExportJson => 'JSON exporteren';

  @override
  String get telemetryExportSheetTitle => 'Een lokale opname exporteren';

  @override
  String telemetryGapCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count onderbrekingen',
      one: '1 onderbreking',
    );
    return '$_temp0';
  }

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opgeslagen groepen — offline afspelen en exporteren',
      one: '1 opgeslagen groep — offline afspelen en exporteren',
    );
    return '$_temp0';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit groepen';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nog $count groepen niet getoond',
      one: 'Nog 1 groep niet getoond',
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
    return 'Lokale opslag: $groups van $groupLimit groepen, $used van $byteLimit MiB';
  }

  @override
  String get telemetryNotConnected => 'Niet verbonden';

  @override
  String get telemetryOfflineSampledReplay => 'Offline bemonsterde weergave';

  @override
  String get telemetryOpenHistory => 'Lokale opnamen openen';

  @override
  String get telemetryPause => 'Pauzeren';

  @override
  String get telemetryPendingOwnerRecovery =>
      'Dit proces houdt de bewerking nog vast. Als dit zo blijft, sluit Telltale dan volledig af en open de app opnieuw';

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetryPlay => 'Afspelen';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return 'Neemt uitsluitend de OBD-signalen op die je hebt ingeschakeld — geen locatie-, VIN- of accountgegevens. Trends tonen hooguit $laneLimit signalen; een opname bewaart alle $activeCount ingeschakelde signalen en voegt het geschatte vermogen en het geschatte brandstofverbruik toe, die berusten op de voertuigaannames.';
  }

  @override
  String get telemetryRecorderPhaseAwaitingValues =>
      'Opnemen — nog geen waarden';

  @override
  String get telemetryRecorderPhaseCompleted => 'Opname opgeslagen';

  @override
  String get telemetryRecorderPhaseFailed => 'Opslaan van de opname is mislukt';

  @override
  String get telemetryRecorderPhaseFinalizing => 'Opname opslaan';

  @override
  String get telemetryRecorderPhaseIdle => 'Lokale opname op de voorgrond';

  @override
  String get telemetryRecorderPhasePreparing => 'Opname voorbereiden';

  @override
  String get telemetryRecorderPhaseRecording => 'Opnemen';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return 'Opname $duration';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count onvoltooide bestanden zonder geldige waarden zijn opgeruimd',
      one: '1 onvoltooid bestand zonder geldige waarden is opgeruimd',
    );
    return '$_temp0';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count beschadigde of tegenstrijdige bestanden zijn ongewijzigd gelaten',
      one: '1 beschadigd of tegenstrijdig bestand is ongewijzigd gelaten',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryDamagedNote =>
      'Beschadigde inhoud wordt nooit gebruikt voor afspelen of exporteren en kan alleen handmatig worden verwijderd wanneer dat veilig kan.';

  @override
  String telemetryRecoveryInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count onderbroken opnamen zijn veilig verzegeld',
      one: '1 onderbroken opname is veilig verzegeld',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryTitle =>
      'Opstartcontrole van de opnamen is voltooid';

  @override
  String get telemetryReload => 'Herladen';

  @override
  String telemetryReplayBreakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count onderbrekingen',
      one: '1 onderbreking',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayLoadFailed => 'Kon de opname niet laden';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return 'Afspeelpositie $percent%';
  }

  @override
  String telemetryReplaySampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bemonsterde punten',
      one: '1 bemonsterd punt',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayTitle => 'Opname afspelen';

  @override
  String get telemetryReplayUnreadable =>
      'De opname is beschadigd of kan niet worden gelezen';

  @override
  String get telemetryRestartToRepairSave =>
      'Opslaan is niet voltooid — herstart Telltale om de opnamen te herstellen';

  @override
  String get telemetryRestartToRepairStartup =>
      'Opstartopruiming is niet voltooid — herstart Telltale om de opnamen te herstellen';

  @override
  String get telemetryReturnToTrends => 'Terug naar trends';

  @override
  String get telemetryRigData => 'Gegevens van testopstelling';

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetrySessionsDamaged => 'Beschadigde opnamebestanden';

  @override
  String get telemetrySessionsEmpty =>
      'Nog geen lokale opnamen\nMaak verbinding en start daarna een opname';

  @override
  String get telemetrySessionsLoadFailed => 'Kon niet laden — opnieuw proberen';

  @override
  String get telemetrySessionsReplayable => 'Opnamen die je kunt afspelen';

  @override
  String get telemetrySessionsTitle => 'Lokale opnamen';

  @override
  String telemetrySignalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count signalen',
      one: '1 signaal',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStartBusy =>
      'Een andere opname of bestandsbewerking is nog niet voltooid';

  @override
  String get telemetryStartCannotCreateFile =>
      'Kon het opnamebestand niet aanmaken';

  @override
  String get telemetryStartInvalidConfiguration =>
      'Deze PID-selectie kan niet veilig worden opgenomen — controleer de definities';

  @override
  String get telemetryStartInvalidatedBackground =>
      'Telltale ging naar de achtergrond — er is geen opname gestart';

  @override
  String get telemetryStartInvalidatedDisconnect =>
      'De verbinding werd verbroken — er is geen opname gestart';

  @override
  String get telemetryStartInvalidatedSessionReplacement =>
      'De verbindingssessie werd vervangen — er is geen opname gestart';

  @override
  String get telemetryStartLibraryByteLimit =>
      'Niet genoeg lokale opslagruimte voor een opname — exporteer of verwijder eerst enkele opnamen';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return 'Lokale opnamen hebben de limiet van $limit bereikt — exporteer of verwijder er eerst enkele';
  }

  @override
  String get telemetryStartMoving => 'Parkeer eerst het voertuig';

  @override
  String get telemetryStartNeedsActivePid =>
      'Schakel eerst ten minste één PID in';

  @override
  String get telemetryStartNeedsConnection =>
      'Maak verbinding voordat je een opname start';

  @override
  String get telemetryStartNeedsForeground =>
      'Breng Telltale naar de voorgrond voordat je een opname start';

  @override
  String get telemetryStartRecording => 'Opname gestart';

  @override
  String get telemetryStartRecordingButton => 'Opname starten';

  @override
  String get telemetryStartSpeedUnknown =>
      'Kan niet bevestigen dat het voertuig stilstaat — verbreek eerst de verbinding';

  @override
  String get telemetryStartTooManyPids =>
      'Een opname behoudt de kolommen voor geschat vermogen en geschat brandstofverbruik — schakel eerst enkele PID\'s uit';

  @override
  String get telemetryStarting => 'Starten';

  @override
  String get telemetryStatusBusError => 'Busfout';

  @override
  String telemetryStatusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count statussen',
      one: '1 status',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStatusFormulaError => 'Formulefout';

  @override
  String get telemetryStatusHeaderMismatch =>
      'Header komt niet overeen met deze bus';

  @override
  String get telemetryStatusNoAnswer =>
      'Geen antwoord — wordt opnieuw geprobeerd';

  @override
  String get telemetryStatusStale => 'Gegevens zijn verouderd';

  @override
  String get telemetryStatusUnsafeServiceRefusal =>
      'Geen alleen-lezen uitleesverzoek — er is niets verzonden';

  @override
  String get telemetryStatusUnsupported =>
      'De regeleenheid antwoordde dat dit niet wordt ondersteund';

  @override
  String get telemetryStopAndSave => 'Stoppen en opslaan';

  @override
  String telemetryValueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count geldige waarden',
      one: '1 geldige waarde',
    );
    return '$_temp0';
  }

  @override
  String get transcriptDelete => 'Verwijderen';

  @override
  String get transcriptDeleteBusy =>
      'Een andere bestandsbewerking is nog niet voltooid.';

  @override
  String get transcriptDeleteFailed =>
      'Kon het diagnoselogboek van de vorige verbinding niet verwijderen.';

  @override
  String get transcriptDeleteRefusedBySafety =>
      'De huidige snelheid of verbindingsstatus staat het verwijderen van het diagnoselogboek niet toe.';

  @override
  String get transcriptExport => 'Exporteren';

  @override
  String get transcriptExportButton => 'Logboek exporteren';

  @override
  String get transcriptExportExplanation =>
      'Deze verbinding bewaart de openingshandshake en het meest recente ruwe verkeer; als bij een lange verbinding het middendeel wegvalt, vermeldt het bestand dat. Wanneer iets bij de auto niet kan worden uitgelezen, is het exporteren en meesturen van het diagnoselogboek veel waardevoller dan één melding op het scherm.';

  @override
  String transcriptExportFailed(String error) {
    return 'Exporteren mislukt: $error';
  }

  @override
  String get transcriptExportWithHex => 'Met hex';

  @override
  String get transcriptNothingToExport =>
      'Er is geen diagnoselogboek om te exporteren.';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return 'Achtergelaten op $timestamp, $size. Het bleef bewaard toen het systeem Telltale afsloot of de telefoon uitviel.';
  }

  @override
  String get transcriptRecoveredChanged =>
      'Het diagnoselogboek van de vorige verbinding is gewijzigd — controleer het opnieuw.';

  @override
  String get transcriptRecoveredTitle =>
      'Diagnoselogboek van de vorige verbinding';

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
  String get trendAxisNow => 'Nu';

  @override
  String get trendChooseSignals => 'Signalen kiezen';

  @override
  String get trendLiveData => 'Live gegevens';

  @override
  String get trendNoSignalsBody =>
      'Schakel eerst op de PID-pagina de signalen in die je wilt volgen.';

  @override
  String get trendNoSignalsTitle => 'Geen trendsignalen beschikbaar';

  @override
  String get trendNoUnits => 'Geen eenheden';

  @override
  String trendPickSignalsBody(int limit) {
    return 'Vergelijk tot $limit signalen. Dit verandert niet welke PID\'s worden gepolld.';
  }

  @override
  String get trendPickSignalsTitle => 'Trendsignalen kiezen';

  @override
  String trendRemoveSignal(String name) {
    return '$name verwijderen';
  }

  @override
  String get trendSelectionSaveFailed =>
      'Kon de selectie voor de trendweergave niet opslaan';

  @override
  String trendSheetBody(int limit) {
    return 'Kies hooguit $limit. Dit verandert alleen de grafiek, niet de PID-polling of een lopende opname.';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return 'Klaar · $selected/$limit';
  }

  @override
  String get trendSignalNoLongerActive =>
      'Een van die signalen staat niet meer in de PID-volglijst';

  @override
  String get trendSignalsHeading => 'Trendsignalen';

  @override
  String trendTooManySelected(int limit) {
    return 'Kies hooguit $limit';
  }

  @override
  String trendWindowSemantics(int seconds) {
    return 'Toont de laatste $seconds seconden';
  }

  @override
  String get wearBack => 'Terug';

  @override
  String get wearBatteryVoltageLabel => 'Accu';

  @override
  String get wearBleAdapters => 'BLE-adapters';

  @override
  String get wearCancel => 'Annuleren';

  @override
  String get wearConfirmVehicle => 'Voertuig bevestigen';

  @override
  String get wearConfirmVehicleAccept => 'Ja, deze auto';

  @override
  String get wearConfirmVehicleBody =>
      'Na bevestiging worden de alleen-lezen accu-uitleesverzoeken voor dit model voor de rest van deze verbinding gepolld. Het verkeerde model kan een plausibel maar fout getal opleveren — annuleer als je niet zeker bent.';

  @override
  String wearConnectFailed(String adapter) {
    return 'Kon niet verbinden: $adapter';
  }

  @override
  String get wearConnecting => 'Verbinden…';

  @override
  String get wearDemoSimulator => 'Demo-simulator';

  @override
  String get wearDisconnect => 'Verbreken';

  @override
  String get wearDisconnectQuestion => 'Verbreken?';

  @override
  String get wearNoDevicesFound => 'Geen apparaten gevonden';

  @override
  String get wearPermissionBluetooth => 'Bluetooth';

  @override
  String get wearPermissionLocation => 'Locatie';

  @override
  String get wearScanAgain => 'Opnieuw';

  @override
  String get wearScanFailed => 'Scan mislukt — probeer opnieuw';

  @override
  String wearScanPermissionNeeded(String permission) {
    return 'Scannen vereist toestemming voor $permission';
  }

  @override
  String wearScanPermissionPermanentlyDenied(String permission) {
    return 'Toestemming voor $permission is permanent geweigerd — schakel dit in via de systeeminstellingen en probeer het opnieuw';
  }

  @override
  String get wearScanning => 'Scannen…';

  @override
  String get telemetryRecorderNotRecording => 'Neemt niet op';

  @override
  String get dtcKindStored => 'Opgeslagen';

  @override
  String get dtcKindPending => 'In afwachting';

  @override
  String get dtcKindPermanent => 'Permanent';

  @override
  String get dtcKindStoredExplanation =>
      'Een bevestigde storing; het storingslampje op het dashboard brandt meestal.';

  @override
  String get dtcKindPendingExplanation =>
      'Eenmaal gedetecteerd; de bevestigingsdrempel is nog niet bereikt.';

  @override
  String get dtcKindPermanentExplanation =>
      'Kan niet met een diagnosetool worden gewist. De ECU wist deze zelf, en pas nadat de reparatie is bevestigd.';

  @override
  String get dtcSystemPowertrain => 'Aandrijflijn';

  @override
  String get dtcSystemChassis => 'Chassis';

  @override
  String get dtcSystemBody => 'Carrosserie';

  @override
  String get dtcSystemNetwork => 'Netwerk';

  @override
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions =>
      'Brandstof- en luchtdosering en aanvullende emissieregeling';

  @override
  String get dtcSubsystemFuelAirMetering => 'Brandstof- en luchtdosering';

  @override
  String get dtcSubsystemFuelAirMeteringInjectorCircuit =>
      'Brandstof- en luchtdosering (injectorcircuit)';

  @override
  String get dtcSubsystemIgnitionOrMisfire =>
      'Ontstekingssysteem of ontstekingsfout';

  @override
  String get dtcSubsystemAuxiliaryEmissionControls =>
      'Aanvullende emissieregeling';

  @override
  String get dtcSubsystemSpeedAndIdleControl =>
      'Voertuigsnelheidsregeling en stationairregelsysteem';

  @override
  String get dtcSubsystemComputerOutputCircuit => 'Computer-uitgangscircuit';

  @override
  String get dtcSubsystemTransmission => 'Transmissie';

  @override
  String get dtcSubsystemControlModuleSignals =>
      'Regeleenheden, in- en uitgangssignalen';

  @override
  String get dtcDescriptionB0001 => 'Storing in aansturing bestuurdersairbag';

  @override
  String get dtcDescriptionP0011 =>
      'Nokkenaspositie A — timing te vroeg of systeemprestaties (Bank 1)';

  @override
  String get dtcDescriptionP0014 =>
      'Nokkenaspositie B — timing te vroeg of systeemprestaties (Bank 1)';

  @override
  String get dtcDescriptionP0016 =>
      'Correlatie krukaspositie – nokkenaspositie (Bank 1 Sensor A)';

  @override
  String get dtcDescriptionP0087 => 'Brandstofrail-/systeemdruk te laag';

  @override
  String get dtcDescriptionP0088 => 'Brandstofrail-/systeemdruk te hoog';

  @override
  String get dtcDescriptionP0100 => 'Storing in circuit luchtmassameter (MAF)';

  @override
  String get dtcDescriptionP0101 => 'Bereik-/prestatieprobleem luchtmassameter';

  @override
  String get dtcDescriptionP0102 =>
      'Laag ingangssignaal circuit luchtmassameter';

  @override
  String get dtcDescriptionP0103 =>
      'Hoog ingangssignaal circuit luchtmassameter';

  @override
  String get dtcDescriptionP0105 =>
      'Storing in circuit inlaatspruitstukdruk-/barometrische druksensor';

  @override
  String get dtcDescriptionP0106 =>
      'Bereik-/prestatieprobleem inlaatspruitstukdruksensor';

  @override
  String get dtcDescriptionP0107 =>
      'Laag ingangssignaal circuit inlaatspruitstukdruksensor';

  @override
  String get dtcDescriptionP0108 =>
      'Hoog ingangssignaal circuit inlaatspruitstukdruksensor';

  @override
  String get dtcDescriptionP0110 =>
      'Storing in circuit inlaatluchttemperatuursensor';

  @override
  String get dtcDescriptionP0111 =>
      'Bereik-/prestatieprobleem inlaatluchttemperatuursensor';

  @override
  String get dtcDescriptionP0112 =>
      'Laag ingangssignaal circuit inlaatluchttemperatuursensor';

  @override
  String get dtcDescriptionP0113 =>
      'Hoog ingangssignaal circuit inlaatluchttemperatuursensor';

  @override
  String get dtcDescriptionP0115 =>
      'Storing in circuit motorkoelvloeistoftemperatuursensor';

  @override
  String get dtcDescriptionP0116 =>
      'Bereik-/prestatieprobleem motorkoelvloeistoftemperatuursensor';

  @override
  String get dtcDescriptionP0117 =>
      'Laag ingangssignaal circuit motorkoelvloeistoftemperatuursensor';

  @override
  String get dtcDescriptionP0118 =>
      'Hoog ingangssignaal circuit motorkoelvloeistoftemperatuursensor';

  @override
  String get dtcDescriptionP0120 => 'Storing in circuit gaskleppositiesensor';

  @override
  String get dtcDescriptionP0121 =>
      'Bereik-/prestatieprobleem gaskleppositiesensor';

  @override
  String get dtcDescriptionP0122 =>
      'Laag ingangssignaal circuit gaskleppositiesensor';

  @override
  String get dtcDescriptionP0123 =>
      'Hoog ingangssignaal circuit gaskleppositiesensor';

  @override
  String get dtcDescriptionP0125 =>
      'Onvoldoende koelvloeistoftemperatuur voor gesloten-lus brandstofregeling';

  @override
  String get dtcDescriptionP0128 =>
      'Koelvloeistoftemperatuur onder regeltemperatuur van thermostaat';

  @override
  String get dtcDescriptionP0130 =>
      'Storing in circuit lambdasonde (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0131 =>
      'Lage spanning in circuit lambdasonde (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0132 =>
      'Hoge spanning in circuit lambdasonde (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0133 =>
      'Trage respons in circuit lambdasonde (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0134 =>
      'Geen activiteit gedetecteerd in circuit lambdasonde (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0135 =>
      'Storing in verwarmingscircuit lambdasonde (Bank 1 Sensor 1)';

  @override
  String get dtcDescriptionP0136 =>
      'Storing in circuit lambdasonde (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0137 =>
      'Lage spanning in circuit lambdasonde (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0138 =>
      'Hoge spanning in circuit lambdasonde (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0140 =>
      'Geen activiteit gedetecteerd in circuit lambdasonde (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0141 =>
      'Storing in verwarmingscircuit lambdasonde (Bank 1 Sensor 2)';

  @override
  String get dtcDescriptionP0150 =>
      'Storing in circuit lambdasonde (Bank 2 Sensor 1)';

  @override
  String get dtcDescriptionP0155 =>
      'Storing in verwarmingscircuit lambdasonde (Bank 2 Sensor 1)';

  @override
  String get dtcDescriptionP0156 =>
      'Storing in circuit lambdasonde (Bank 2 Sensor 2)';

  @override
  String get dtcDescriptionP0161 =>
      'Storing in verwarmingscircuit lambdasonde (Bank 2 Sensor 2)';

  @override
  String get dtcDescriptionP0170 => 'Storing in brandstofcorrectie (Bank 1)';

  @override
  String get dtcDescriptionP0171 => 'Systeem te arm (Bank 1)';

  @override
  String get dtcDescriptionP0172 => 'Systeem te rijk (Bank 1)';

  @override
  String get dtcDescriptionP0173 => 'Storing in brandstofcorrectie (Bank 2)';

  @override
  String get dtcDescriptionP0174 => 'Systeem te arm (Bank 2)';

  @override
  String get dtcDescriptionP0175 => 'Systeem te rijk (Bank 2)';

  @override
  String get dtcDescriptionP0190 =>
      'Storing in circuit brandstofraildruksensor';

  @override
  String get dtcDescriptionP0201 =>
      'Storing of onderbreking in injectorcircuit — cilinder 1';

  @override
  String get dtcDescriptionP0202 =>
      'Storing of onderbreking in injectorcircuit — cilinder 2';

  @override
  String get dtcDescriptionP0203 =>
      'Storing of onderbreking in injectorcircuit — cilinder 3';

  @override
  String get dtcDescriptionP0204 =>
      'Storing of onderbreking in injectorcircuit — cilinder 4';

  @override
  String get dtcDescriptionP0217 => 'Oververhitting van de motor';

  @override
  String get dtcDescriptionP0221 =>
      'Bereik-/prestatieprobleem gasklep-/pedaalpositiesensor B';

  @override
  String get dtcDescriptionP0222 =>
      'Laag ingangssignaal circuit gasklep-/pedaalpositiesensor B';

  @override
  String get dtcDescriptionP0223 =>
      'Hoog ingangssignaal circuit gasklep-/pedaalpositiesensor B';

  @override
  String get dtcDescriptionP0234 => 'Laaddruk turbo/compressor te hoog';

  @override
  String get dtcDescriptionP0299 => 'Laaddruk turbo/compressor A te laag';

  @override
  String get dtcDescriptionP0300 =>
      'Willekeurige ontstekingsfout of ontstekingsfout op meerdere cilinders gedetecteerd';

  @override
  String get dtcDescriptionP0301 => 'Ontstekingsfout cilinder 1 gedetecteerd';

  @override
  String get dtcDescriptionP0302 => 'Ontstekingsfout cilinder 2 gedetecteerd';

  @override
  String get dtcDescriptionP0303 => 'Ontstekingsfout cilinder 3 gedetecteerd';

  @override
  String get dtcDescriptionP0304 => 'Ontstekingsfout cilinder 4 gedetecteerd';

  @override
  String get dtcDescriptionP0305 => 'Ontstekingsfout cilinder 5 gedetecteerd';

  @override
  String get dtcDescriptionP0306 => 'Ontstekingsfout cilinder 6 gedetecteerd';

  @override
  String get dtcDescriptionP0307 => 'Ontstekingsfout cilinder 7 gedetecteerd';

  @override
  String get dtcDescriptionP0308 => 'Ontstekingsfout cilinder 8 gedetecteerd';

  @override
  String get dtcDescriptionP0316 =>
      'Ontstekingsfout direct na starten gedetecteerd';

  @override
  String get dtcDescriptionP0325 => 'Storing in circuit klopsensor (Bank 1)';

  @override
  String get dtcDescriptionP0326 =>
      'Bereik-/prestatieprobleem klopsensor (Bank 1)';

  @override
  String get dtcDescriptionP0327 =>
      'Laag ingangssignaal circuit klopsensor (Bank 1)';

  @override
  String get dtcDescriptionP0328 =>
      'Hoog ingangssignaal circuit klopsensor (Bank 1)';

  @override
  String get dtcDescriptionP0330 => 'Storing in circuit klopsensor (Bank 2)';

  @override
  String get dtcDescriptionP0335 => 'Storing in circuit krukaspositiesensor';

  @override
  String get dtcDescriptionP0336 =>
      'Bereik-/prestatieprobleem krukaspositiesensor';

  @override
  String get dtcDescriptionP0340 => 'Storing in circuit nokkenaspositiesensor';

  @override
  String get dtcDescriptionP0341 =>
      'Bereik-/prestatieprobleem nokkenaspositiesensor';

  @override
  String get dtcDescriptionP0351 =>
      'Storing in primair/secundair circuit bobine A';

  @override
  String get dtcDescriptionP0352 =>
      'Storing in primair/secundair circuit bobine B';

  @override
  String get dtcDescriptionP0353 =>
      'Storing in primair/secundair circuit bobine C';

  @override
  String get dtcDescriptionP0354 =>
      'Storing in primair/secundair circuit bobine D';

  @override
  String get dtcDescriptionP0355 =>
      'Storing in primair/secundair circuit bobine E';

  @override
  String get dtcDescriptionP0356 =>
      'Storing in primair/secundair circuit bobine F';

  @override
  String get dtcDescriptionP0400 =>
      'Storing in doorstroming uitlaatgasrecirculatie (EGR)';

  @override
  String get dtcDescriptionP0401 =>
      'Doorstroming uitlaatgasrecirculatie (EGR) onvoldoende';

  @override
  String get dtcDescriptionP0402 =>
      'Doorstroming uitlaatgasrecirculatie (EGR) overmatig';

  @override
  String get dtcDescriptionP0403 =>
      'Storing in regelcircuit uitlaatgasrecirculatie (EGR)';

  @override
  String get dtcDescriptionP0404 =>
      'Bereik-/prestatieprobleem regelcircuit uitlaatgasrecirculatie (EGR)';

  @override
  String get dtcDescriptionP0410 => 'Storing in secundair luchtinjectiesysteem';

  @override
  String get dtcDescriptionP0411 =>
      'Onjuiste doorstroming gedetecteerd in secundair luchtinjectiesysteem';

  @override
  String get dtcDescriptionP0412 =>
      'Storing in circuit schakelklep A van secundair luchtinjectiesysteem';

  @override
  String get dtcDescriptionP0420 =>
      'Rendement katalysatorsysteem onder drempelwaarde (Bank 1)';

  @override
  String get dtcDescriptionP0430 =>
      'Rendement katalysatorsysteem onder drempelwaarde (Bank 2)';

  @override
  String get dtcDescriptionP0440 => 'Storing in verdampingsemissiesysteem';

  @override
  String get dtcDescriptionP0441 =>
      'Onjuiste spoelstroom in verdampingsemissiesysteem';

  @override
  String get dtcDescriptionP0442 =>
      'Lek gedetecteerd in verdampingsemissiesysteem (klein lek)';

  @override
  String get dtcDescriptionP0443 =>
      'Storing in circuit spoelregelklep van verdampingsemissiesysteem';

  @override
  String get dtcDescriptionP0446 =>
      'Storing in ontluchtingsregelcircuit van verdampingsemissiesysteem';

  @override
  String get dtcDescriptionP0447 =>
      'Ontluchtingsregelcircuit van verdampingsemissiesysteem open';

  @override
  String get dtcDescriptionP0449 =>
      'Storing in circuit ontluchtingsklep/-magneetklep van verdampingsemissiesysteem';

  @override
  String get dtcDescriptionP0451 =>
      'Bereik-/prestatieprobleem druksensor verdampingsemissiesysteem';

  @override
  String get dtcDescriptionP0452 =>
      'Laag ingangssignaal circuit druksensor verdampingsemissiesysteem';

  @override
  String get dtcDescriptionP0453 =>
      'Hoog ingangssignaal circuit druksensor verdampingsemissiesysteem';

  @override
  String get dtcDescriptionP0455 =>
      'Lek gedetecteerd in verdampingsemissiesysteem (groot lek)';

  @override
  String get dtcDescriptionP0456 =>
      'Lek gedetecteerd in verdampingsemissiesysteem (zeer klein lek)';

  @override
  String get dtcDescriptionP0480 => 'Storing in regelcircuit koelventilator 1';

  @override
  String get dtcDescriptionP0500 => 'Storing in voertuigsnelheidssensor';

  @override
  String get dtcDescriptionP0505 => 'Storing in stationairregelsysteem';

  @override
  String get dtcDescriptionP0506 =>
      'Toerental stationairregelsysteem lager dan verwacht';

  @override
  String get dtcDescriptionP0507 =>
      'Toerental stationairregelsysteem hoger dan verwacht';

  @override
  String get dtcDescriptionP0508 =>
      'Laag signaal in circuit stationairregelsysteem';

  @override
  String get dtcDescriptionP0509 =>
      'Hoog signaal in circuit stationairregelsysteem';

  @override
  String get dtcDescriptionP0560 => 'Storing in systeemspanning';

  @override
  String get dtcDescriptionP0562 => 'Systeemspanning laag';

  @override
  String get dtcDescriptionP0563 => 'Systeemspanning hoog';

  @override
  String get dtcDescriptionP0603 =>
      'Interne fout in keep-alive-geheugen (KAM) van regeleenheid';

  @override
  String get dtcDescriptionP0605 =>
      'Interne fout in alleen-lezen-geheugen (ROM) van regeleenheid';

  @override
  String get dtcDescriptionP0606 => 'Processorfout ECM/PCM';

  @override
  String get dtcDescriptionP0700 =>
      'De transmissieregeleenheid heeft om het storingslampje gevraagd — de storingscode zelf staat in de transmissiemodule en moet apart worden uitgelezen';

  @override
  String get dtcDescriptionP0701 =>
      'Bereik-/prestatieprobleem transmissieregelsysteem';

  @override
  String get dtcDescriptionP0702 =>
      'Elektrische storing in transmissieregelsysteem';

  @override
  String get dtcDescriptionP0705 =>
      'Storing in circuit transmissiebereiksensor';

  @override
  String get dtcDescriptionP0715 =>
      'Storing in circuit ingaande-as-/turbinetoerentalsensor';

  @override
  String get dtcDescriptionP0720 =>
      'Storing in circuit uitgaande-astoerentalsensor';

  @override
  String get dtcDescriptionP0730 => 'Onjuiste overbrengingsverhouding';

  @override
  String get dtcDescriptionP0740 =>
      'Storing in circuit koppelomvormerkoppeling';

  @override
  String get dtcDescriptionP0741 =>
      'Koppelomvormerkoppeling blijft uitgeschakeld hangen';

  @override
  String get dtcDescriptionP0750 => 'Storing in schakelmagneetklep A';

  @override
  String get dtcDescriptionP0755 => 'Storing in schakelmagneetklep B';

  @override
  String get dtcDescriptionP2135 =>
      'Spanningscorrelatie gaskleppositiesensor A/B';

  @override
  String get dtcDescriptionU0100 => 'Communicatie met ECM/PCM verbroken';

  @override
  String get dtcDescriptionU0101 =>
      'Communicatie met de transmissieregeleenheid verbroken';

  @override
  String get dtcDescriptionU0121 =>
      'Communicatie met de ABS-regeleenheid verbroken';

  @override
  String get dtcDescriptionU0140 =>
      'Communicatie met de carrosserieregeleenheid verbroken';

  @override
  String get dtcDescriptionU0155 =>
      'Communicatie met de regeleenheid van het instrumentenpaneel verbroken';

  @override
  String get gaugeSkinCluster => 'Cluster';

  @override
  String get gaugeSkinClusterDescription =>
      'Ziet eruit als een fabrieksinstrumentenpaneel. Naald, 270-gradenschaal, verzonken wijzerplaat.';

  @override
  String get gaugeSkinMinimal => 'Minimaal';

  @override
  String get gaugeSkinMinimalDescription =>
      'Halve boog, geen naald, geen maatstreepjes. Het getal is wat je afleest, niet de beweging.';

  @override
  String get gaugeSkinTrack => 'Circuit';

  @override
  String get gaugeSkinTrackDescription =>
      'Gesegmenteerde balk, geen afvlakking. De waarde staat waar hij staat, zonder tussenstappen.';

  @override
  String get gaugeSkinClassic => 'Klassiek';

  @override
  String get gaugeSkinClassicDescription =>
      'Gedrukte wijzerplaat, cijfers helemaal rondom, een naald die rustig tot stilstand komt zoals bij een mechanisch horloge.';

  @override
  String get gaugeSkinNight => 'Nacht';

  @override
  String get gaugeSkinNightDescription =>
      'Voor rijden in het donker. Lage helderheid, een vlakke boog, geen animatie — vraagt zo min mogelijk van je aandacht.';

  @override
  String get derivedAirflowSourceMaf => 'MAF-sensor';

  @override
  String get derivedAirflowSourceSpeedDensity => 'Speed-Density-schatting';

  @override
  String get derivedAirflowSourceUnavailable => 'Luchtmassa niet beschikbaar';

  @override
  String get derivedFuelSourceStoichiometric => 'Stoichiometrische schatting';

  @override
  String get derivedFuelSourceUnavailable =>
      'Brandstofverbruiksnelheid niet beschikbaar';

  @override
  String get telemetrySourceDemo => 'Ingebouwde simulator';

  @override
  String get telemetrySourceRig => 'Testopstelling';

  @override
  String get telemetrySourceFieldApp => 'Verbinding via veld-app';

  @override
  String get fuelTypeGasoline => 'Benzine';

  @override
  String get fuelTypeDiesel => 'Diesel';

  @override
  String get fuelTypeLpg => 'LPG';

  @override
  String get fuelTypeEthanolE85 => 'E85-ethanol';

  @override
  String get drivetrainFwd => 'Voorwielaandrijving';

  @override
  String get drivetrainRwd => 'Achterwielaandrijving';

  @override
  String get drivetrainAwd => 'Vierwielaandrijving';

  @override
  String get assumptionFieldMass => 'Massa';

  @override
  String get assumptionFieldDragCoefficient => 'Cd';

  @override
  String get assumptionFieldFrontalArea => 'Frontaal oppervlak';

  @override
  String get assumptionFieldRollingResistance => 'Rolweerstand';

  @override
  String get assumptionFieldDrivetrainEfficiency => 'Transmissierendement';

  @override
  String get assumptionFieldFuelType => 'Brandstof';

  @override
  String get assumptionFieldStoichAfr => 'AFR';

  @override
  String get assumptionFieldFuelDensity => 'Dichtheid';

  @override
  String get assumptionFieldDisplacement => 'Cilinderinhoud';

  @override
  String get assumptionFieldVolumetricEfficiency => 'VE';

  @override
  String get vehicleFieldOriginGenericDefault => 'algemene standaardwaarde';

  @override
  String get vehicleFieldOriginUserEntered => 'door jou ingevoerd';

  @override
  String get vehicleFieldOriginOfficialRegistry => 'officieel register';

  @override
  String get vehicleFieldOriginManufacturerPublication => 'fabrikantgegevens';

  @override
  String get vehicleFieldOriginScientificModel => 'modelcoëfficiënt';

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
      'L/h = (MAF g/s) / (AFR × brandstofdichtheid g/L) × 3600; MAF is ofwel PID 0110 ofwel Speed-Density (RPM × MAP × cilinderinhoud × VE / T_K); L/100km = (L/h) / speed_kmh × 100';

  @override
  String get datumAssumptionsFromRecording =>
      'De schatting gebruikt de voertuiginstellingen zoals die waren toen dit werd opgenomen.';

  @override
  String adapterConcernFirmwareNeverReleasedSummary(String version) {
    return 'Meldt firmware v$version, die nooit is uitgebracht';
  }

  @override
  String get adapterConcernFirmwareNeverReleasedDetail =>
      'Elm Electronics heeft deze versie nooit uitgebracht, dus de firmware op deze adapter is niet de versie die hij beweert te hebben. Veel van zulke adapters werken nog steeds — maar zijn beschrijving van zichzelf is niet te vertrouwen, en het is de moeite waard om hem als eerste te verdenken wanneer iets niet kan worden uitgelezen.';

  @override
  String adapterConcernPpsRefusedSummary(String version) {
    return 'Beweert v$version te zijn, maar kent ATPPS niet, wat v1.1 al had';
  }

  @override
  String get adapterConcernPpsRefusedDetail =>
      'Het overzicht van programmeerbare parameters (ATPPS) bestaat al sinds ELM327 v1.1 en zelfs hoogwaardige adapters zoals OBDLink ondersteunen het. De versie die de adapter beweert te hebben en de opdrachten die hij daadwerkelijk implementeert komen niet overeen.';

  @override
  String get adapterConcernNoIdentitySummary =>
      'Beantwoordt AT@1 niet, de apparaatidentiteitsopdracht uit de eerste versie';

  @override
  String get adapterConcernNoIdentityDetail =>
      'Deze opdracht bestaat al sinds ELM327 v1.0. Het niet beantwoorden ervan betekent dat deze chip een kleinere opdrachtenset implementeert dan welke officiële firmware dan ook.';

  @override
  String get telemetryReplaySampled =>
      'Het voorbeeld is bemonsterd; de export behoudt elke opgenomen gebeurtenis.';

  @override
  String get telemetryExportDisclosure =>
      'De export bevat signaalnamen, waarden, waarnemings- en brontijden, verbindingstype, protocol, bevroren PID-labels, eenheden en formules, en de schattingsaannames (massa, luchtweerstand, cilinderinhoud, brandstof en soortgelijke parameters). JSON kan ook je eigen aangepaste labels, eenheden, formules en volledige bevroren definities bevatten. De export bevat niet het VIN, GPS, een account, het adapteradres, het volledige voertuigprofiel of ruw diagnoseverkeer.';

  @override
  String get connectTransportCancelled =>
      'De verbindingspoging is gestopt voordat deze was voltooid.';

  @override
  String get connectTransportWifiRouteNoNetwork =>
      'De telefoon is met geen enkel Wi-Fi-netwerk verbonden, dus er is geen route naar de adapter. Maak verbinding met de Wi-Fi-hotspot van de adapter en probeer het opnieuw.';

  @override
  String get connectTransportWifiRouteAmbiguous =>
      'De telefoon is met meer dan één Wi-Fi-netwerk verbonden en geen daarvan is duidelijk van de adapter, dus er is geen netwerk gekozen. Verbreek de verbinding met de netwerken die niet van de adapter zijn en probeer het opnieuw.';

  @override
  String get connectTransportWifiRouteRefused =>
      'Het systeem weigerde deze verbinding via Wi-Fi te laten lopen. De telefoon is verbonden met Wi-Fi; die verbinding mocht hiervoor niet worden gebruikt.';

  @override
  String get connectTransportWifiRouteTimeout =>
      'Het systeem heeft niet geantwoord op het verzoek om deze verbinding via Wi-Fi te laten lopen. Wacht een paar seconden en probeer het opnieuw.';

  @override
  String get connectTransportWifiRouteUnclassified =>
      'De verbinding kon niet via Wi-Fi worden geleid, om een reden die het systeem niet heeft genoemd. De volledige fout staat in het logboek hieronder.';

  @override
  String get connectTransportWifiHostUnreachable =>
      'Er kwam geen antwoord op dat adres. Controleer of de telefoon is verbonden met de Wi-Fi-hotspot van de adapter — als het systeem vroeg of je verbonden wilt blijven zonder internet, kies er dan voor om verbonden te blijven. Mobiele data uitschakelen kan ook helpen.';

  @override
  String get connectTransportWifiConnectTimeout =>
      'Er kwam niet op tijd antwoord op dat adres.';

  @override
  String get connectTransportWifiRouteRestoreFailed =>
      'De verbinding werkte, maar de netwerkroutering van de telefoon kon niet worden teruggezet, dus de verbinding is verbroken in plaats van de routering gewijzigd achter te laten. Herstart de app en probeer het opnieuw.';

  @override
  String get connectTransportBleLinkFailed =>
      'Kon niet verbinden met de adapter. Controleer of hij stroom heeft en binnen bereik is.';

  @override
  String get connectTransportBleNoSerialCharacteristic =>
      'Het apparaat maakte verbinding, maar er is geen seriële poort op gevonden, dus het is mogelijk geen ELM327-adapter.';

  @override
  String get connectTransportClassicAllTiersRefused =>
      'Kon niet verbinden met de adapter. Koppel hem eerst in de Bluetooth-instellingen van het systeem en controleer of hij in de OBD-poort zit met het contact aan.';

  @override
  String get connectTransportClassicConnectTimeout =>
      'Time-out bij het verbinden met de adapter. Mogelijk antwoordt hij nog — wacht een paar seconden in plaats van het direct opnieuw te proberen.';

  @override
  String get connectTransportSerialPortOpenFailed =>
      'Kon de seriële poort niet openen. Controleer of het systeem er een heeft aangemaakt voor deze adapter (COMx op Windows, /dev/rfcomm* op Linux) en of het contact aan staat.';

  @override
  String get connectTransportSerialDroppedOnOpen =>
      'De seriële poort werd geopend en sloot direct weer.';

  @override
  String get settingsManualCommandNotConnected =>
      'Er is niets verbonden, dus de opdracht is niet verzonden.';

  @override
  String get settingsManualCommandLinkDropped =>
      'De verbinding met de adapter viel weg terwijl deze opdracht onderweg was, waardoor er geen antwoord kwam. Of de adapter de opdracht heeft ontvangen is niet bekend.';

  @override
  String get settingsManualCommandDisconnectedByApp =>
      'De app heeft de verbinding gesloten terwijl deze opdracht onderweg was, waardoor er geen antwoord kwam. Er is niets mis met de adapter of het voertuig.';

  @override
  String get settingsManualCommandAdapterSilentOnResync =>
      'De antwoorden van de adapter liepen niet meer synchroon met de verzonden opdrachten en de adapter beantwoordde niet de controle die ze weer synchroon had moeten zetten, waardoor de verbinding is verbroken. Maak opnieuw verbinding voordat je het nogmaals probeert.';

  @override
  String get settingsManualCommandLinkStoppedResponding =>
      'Er kwam zo lang niets binnen van de adapter dat de verbinding is verbroken. Mogelijk heeft hij nog stroom; wat vaststaat is de stilte.';

  @override
  String get settingsManualCommandWriteFailed =>
      'De opdracht kon niet aan de verbinding van de adapter worden overgedragen. Hoeveel ervan de adapter heeft bereikt is niet bekend.';

  @override
  String get settingsManualCommandTimedOut =>
      'Er kwam geen antwoord vóór de tijdslimiet. Controleer of de adapter is verbonden en het contact aan staat.';

  @override
  String get settingsManualCommandOperationRetired =>
      'Deze sessie is beëindigd of naar de achtergrond gegaan, dus de opdracht is niet verzonden.';

  @override
  String get settingsManualCommandRequestUnaddressable =>
      'Dit verzoek kan niet worden geadresseerd op de bus die dit voertuig gebruikt, dus het is niet verzonden. Opnieuw proberen verandert daar niets aan.';

  @override
  String get commandFailureBusJ1939 =>
      'Deze bus is SAE J1939 (zware bedrijfsvoertuigen en machines), niet het OBD2-diagnoseprotocol dat deze app uitleest, dus dit verzoek kan niet worden uitgelezen.';

  @override
  String commandFailureUserCanFramingUnknown(
    String protocol,
    String parameter,
  ) {
    return 'Deze adapter is ingesteld op het door de gebruiker gedefinieerde CAN-protocol $protocol, waarvan de framing wordt bepaald door $parameter. De adapter heeft die instelling niet gemeld, waardoor het busformaat niet kan worden bevestigd en dit uitleesverzoek niet veilig kan worden gedecodeerd.';
  }

  @override
  String get commandFailureBusUndetermined =>
      'Het busprotocol van het voertuig is nog niet vastgesteld, waardoor dit uitleesverzoek niet veilig kan worden gedecodeerd. Verbind opnieuw.';

  @override
  String get settingsManualCommandCustomFlowControlRejected =>
      'De adapter weigerde een aangepaste flow-control-opdracht, waardoor de gevraagde modus niet is toegepast en er geen meting is geproduceerd.';

  @override
  String get settingsManualCommandFlowControlRestoreFailed =>
      'De adapter weigerde de standaard flow-control (ATFCSM0) te herstellen, waardoor polling is gestopt totdat je opnieuw verbindt.';

  @override
  String get settingsManualCommandExtendedAddressingUnavailable =>
      'Uitgebreide adressering is niet beschikbaar op dit ELM327-pad.';

  @override
  String get settingsManualCommandRawIsoTpModeUnavailable =>
      'Voor het systeem zichtbare ISO-TP-herassemblage is niet beschikbaar op dit ELM327-pad.';

  @override
  String get settingsManualCommandCanPriorityUnavailable =>
      'CAN-prioriteitsprogrammering is niet beschikbaar op dit ELM327-pad.';

  @override
  String get settingsManualCommandCanReceiveFilterUnavailable =>
      'CAN-ontvangstfiltering is niet beschikbaar op dit ELM327-pad.';

  @override
  String get settingsManualCommandHeaderRestoreFailed =>
      'De adapter weigerde de header (ATSH) te herstellen, waardoor polling is gestopt totdat je opnieuw verbindt.';

  @override
  String get manualCommandRefusedEmpty =>
      'Er is niets getypt, dus er is niets verzonden.';

  @override
  String get manualCommandRefusedMoreThanOneCommand =>
      'Deze tekst bevat een regelovergang of een ander stuurteken, waarmee meer dan één opdracht tegelijk wordt verzonden. De adapter scheidt opdrachten op regelovergangen, waardoor de tweede opdracht elke controle hier zou overslaan — inclusief de controle die weigert storingscodes te wissen. Stuur één opdracht tegelijk.';

  @override
  String manualCommandRefusedAdapterStateWouldChange(
    Object command,
    Object allowed,
  ) {
    return 'Dit vak accepteert vragen, geen opdrachten die veranderen wat de adapter is. “$command” zou de status van de adapter wijzigen terwijl het model ervan in de app hetzelfde bleef — de uitlezingen erna zouden van een andere regeleenheid kunnen komen zonder dat iets op het scherm dat aangeeft.\nUitleesverzoeken die je kunt sturen: $allowed.';
  }

  @override
  String get manualCommandRefusedClearHasItsOwnButton =>
      'Gebruik de knop Wissen op het scherm Storingscodes om storingscodes te wissen. Vanaf hier verzonden zou de opdracht de bevestiging, de dekkingscontrole en de antwoordvalidatie overslaan en alleen de ene regeleenheid bereiken die momenteel is geselecteerd.';

  @override
  String manualCommandRefusedCharactersNoObdCommandHas(Object command) {
    return 'De opdracht “$command” bevat tekens die een OBD-opdracht nooit heeft. Dit vak accepteert hexadecimale servicecodes en parameters — 0100, 03, 2211A6 — of een adaptervraag die begint met AT.';
  }

  @override
  String manualCommandRefusedNotAReadOnlyQuery(Object command, Object allowed) {
    return '“$command” is geen opdracht die dit vak kent. Het accepteert alleen-lezen uitleesverzoeken (Mode $allowed) en adaptervragen.';
  }

  @override
  String commandFailureQueryHeaderRefused(Object header) {
    return 'De adapter weigerde dit verzoek te richten aan regeleenheid $header, dus het is niet verzonden. Als het op het adres was gelaten dat de adapter daadwerkelijk vasthoudt, zou het antwoord afkomstig zijn geweest van een regeleenheid die niemand had bevraagd.';
  }

  @override
  String commandFailureWholeVehicleHeaderRefused(Object address) {
    return 'De adapter weigerde over te schakelen naar adres $address, het adres waarop een vraag aan het hele voertuig moet worden verstuurd. Zonder dat adres kunnen antwoorden niet worden gekoppeld aan de regeleenheden die ze hebben verzonden, dus het verzoek is niet gedaan.';
  }

  @override
  String commandFailureLegacyScanWouldBePartial(Object installed) {
    return 'Dit voertuig gebruikt een oudere bus zonder standaardadres dat elke regeleenheid bereikt, en de adapter staat momenteel ingesteld op regeleenheid $installed. Een scan zou uitsluitend die ene regeleenheid hebben gedekt terwijl het resultaat als een resultaat voor het hele voertuig zou zijn gepresenteerd, dus de scan is niet verzonden. Verbind opnieuw en scan daarna nogmaals.';
  }

  @override
  String get pidFormulaEmpty => 'De formule is leeg.';

  @override
  String get pidFormulaEmptySubExpression =>
      'Een deel van de formule is leeg — een operator zonder iets erachter, of haakjes zonder inhoud.';

  @override
  String get pidFormulaUnbalancedParentheses =>
      'De haakjes kloppen niet: elke ( heeft een sluitende ) nodig.';

  @override
  String pidFormulaUnparsableTerm(String term) {
    return '“$term” is geen getal, operator of naam die deze editor begrijpt.';
  }

  @override
  String get pidFormulaFunctionNestingTooDeep =>
      'ABS(), LOG10(), LOG() en SQRT() zijn te diep genest om te evalueren. Vereenvoudig de formule.';

  @override
  String get pidFormulaParenthesisNestingTooDeep =>
      'De haakjes zijn te diep genest om te evalueren. Vereenvoudig de formule.';

  @override
  String get pidFormulaDivisionByZero => 'De formule deelt door nul.';

  @override
  String get pidFormulaModuloByZero =>
      'De formule berekent een rest modulo nul.';

  @override
  String pidFormulaLog10NonPositiveArgument(double argument) {
    return 'LOG10 heeft een argument groter dan 0 nodig, en dit kwam uit op $argument.';
  }

  @override
  String pidFormulaLogNonPositiveArgument(double argument) {
    return 'LOG heeft een argument groter dan 0 nodig, en dit kwam uit op $argument.';
  }

  @override
  String pidFormulaSqrtNegativeArgument(double argument) {
    return 'SQRT heeft een argument van 0 of groter nodig, en dit kwam uit op $argument.';
  }

  @override
  String get pidFormulaResultNotFinite =>
      'De berekening leverde geen bruikbaar getal op, dus er is geen uitlezing om te tonen.';

  @override
  String pidFormulaByteBeyondResponse(String letter, int count) {
    return 'De formule verwijst naar byte $letter, maar het antwoord bevatte slechts $count bytes.';
  }

  @override
  String get pidFormulaBaroControllerUnknown =>
      'BARO kan hier niet worden gebruikt, omdat niet bekend is van welke regeleenheid de omgevingsdruk wordt bedoeld.';

  @override
  String get pidFormulaBaroTwoDefinitions =>
      'Twee definities leveren allebei de omgevingsdruk, waardoor beide waarden mogelijk zijn en geen van beide kan worden gebruikt. Verwijder een van de meters die de omgevingsdruk meet.';

  @override
  String get pidFormulaBaroNotYetMeasured =>
      'De omgevingsdruk is nog niet uitgelezen, dus dit kan niet worden berekend.';

  @override
  String get pidFormulaBaroMeasurementStale =>
      'De uitlezing van de omgevingsdruk is verouderd, dus dit kan niet worden berekend.';

  @override
  String get pidFormulaBaroParenFormUnsupported =>
      'BARO() is de Android-barometer / ECU-baro in psi, die dit dialect niet implementeert. Gebruik BARO zonder haakjes voor de gecachte omgevingsdruk.';

  @override
  String get pidFormulaInt16Unclaimed =>
      'INT16 heeft in dit dialect geen vastgelegde betekenis: de wiki zegt dat het (A*255)+B kan vervangen, wat niet gelijk is aan (A*256)+B. Schrijf een van die twee uitdrukkingen expliciet uit.';

  @override
  String pidFormulaTimeWindowUnsupported(String term) {
    return '$term is een vertragings-, gemiddelde- of totalizer-functie van Torque die dit dialect niet implementeert, dus deze kan hier niet worden geëvalueerd. Het is niet 0 en niet MIN of MAX.';
  }

  @override
  String pidFormulaDependencyControllerUnknown(String reference) {
    return '$reference kan hier niet worden opgelost, omdat niet bekend is bij welke regeleenheid die PID hoort.';
  }

  @override
  String pidFormulaDependencyTwoDefinitions(String key) {
    return 'Twee definities decoderen allebei $key, waardoor beide waarden mogelijk zijn en geen van beide kan worden gebruikt. Wijzig een van beide naar een andere mode+PID. Let op: de PID\'s die voor de schattingen nodig zijn (010B, 010C, 010D) worden altijd uitgelezen, dus een meter van het dashboard halen stopt ze niet.';
  }

  @override
  String pidFormulaDependencyNotYetMeasured(String key) {
    return 'Er is nog geen bruikbare waarde uitgelezen voor $key.';
  }

  @override
  String get pidFormulaUnidentified =>
      'Deze formule kan niet worden geëvalueerd en de editor heeft daar geen specifiekere reden voor.';

  @override
  String get pidRejectionMalformedModeAndPid =>
      'Geen geldige mode+PID: uitsluitend hexadecimale tekens, in volledige byteparen.';

  @override
  String pidRejectionServiceNotReadOnly(String service, String services) {
    return 'Service $service is geen alleen-lezen uitleesverzoek en mag niet telkens opnieuw naar het voertuig worden gestuurd. Alleen $services zijn toegestaan — actuele gegevens, freeze-frame, voertuiginformatie en ReadDataByIdentifier.';
  }

  @override
  String get pidRejectionFreezeFrameNeedsFrame =>
      'Een freeze-frame-uitleesverzoek heeft twee bytes nodig, de PID en het framenummer — bijvoorbeeld 020500 (PID 05, frame 0).';

  @override
  String get pidRejectionIdentifierNeedsTwoBytes =>
      'ReadDataByIdentifier heeft een ID van twee bytes nodig — bijvoorbeeld 221101.';

  @override
  String pidRejectionIdentifierWrongLength(String service, int bytes) {
    return 'Een uitleesverzoek voor service $service heeft een ID van $bytes bytes nodig.';
  }

  @override
  String get pidRejectionNameRequired => 'Voer een naam in.';

  @override
  String pidRejectionInvalidHeader(String text) {
    return '“$text” is geen geldige header: 3 tekens voor 11-bit CAN, 6 voor de oudere protocollen, 8 voor 29-bit CAN.';
  }

  @override
  String get pidRejectionBoundsRequired =>
      'Vul beide uiteinden van het meterbereik in.';

  @override
  String pidRejectionMinNotANumber(String text) {
    return 'De ondergrens “$text” is geen geldig getal.';
  }

  @override
  String pidRejectionMaxNotANumber(String text) {
    return 'De bovengrens “$text” is geen geldig getal.';
  }

  @override
  String get pidRejectionMinNotFinite =>
      'De ondergrens moet een eindig getal zijn.';

  @override
  String get pidRejectionMaxNotFinite =>
      'De bovengrens moet een eindig getal zijn.';

  @override
  String pidRejectionRedlineNotANumber(String text) {
    return 'Het begin van het rode gebied “$text” is geen geldig getal.';
  }

  @override
  String get pidRejectionRedlineNotFinite =>
      'Het begin van het rode gebied moet een eindig getal zijn.';

  @override
  String get pidRejectionMaxNotAboveMin =>
      'De bovengrens moet groter zijn dan de ondergrens.';

  @override
  String pidImportMalformedCsv(String detail) {
    return 'Dit bestand kon niet als CSV worden gelezen: $detail';
  }

  @override
  String get pidImportNoRows => 'Het bestand bevat geen rijen.';

  @override
  String pidImportDuplicateHeaderColumns(String columns) {
    return 'De koprij noemt dezelfde kolom twee keer: $columns. Het is niet te bepalen welke moet worden gebruikt, dus herstel eerst het bestand.';
  }

  @override
  String pidImportMissingRequiredColumns(String columns, String required) {
    return 'In de koprij ontbreken vereiste kolommen: $columns. $required zijn allemaal nodig.';
  }

  @override
  String pidImportRowTooFewColumns(int line) {
    return 'Rij $line: te weinig cellen — naam, korte naam, PID en formule zijn het minimum.';
  }

  @override
  String pidImportRowInvalidModeAndPid(int line, String text) {
    return 'Rij $line: “$text” is geen geldige mode+PID (uitsluitend hexadecimale tekens, in volledige byteparen).';
  }

  @override
  String pidImportRowEmptyEquation(int line) {
    return 'Rij $line: de formulecel is leeg.';
  }

  @override
  String pidImportRowRejected(int line, String reason) {
    return 'Rij $line: $reason';
  }

  @override
  String pidImportRowRangeDefaulted(int line, double min, double max) {
    return 'Rij $line: het meterbereik was leeg, dus $min–$max is toegepast. Controleer of deze schaal past bij deze sensor.';
  }

  @override
  String get pidImportNothingImportable =>
      'Het bestand bevat rijen, maar geen daarvan is een PID-definitie.';

  @override
  String get dtcCategoryNoAnswer =>
      'Deze categorie heeft niet geantwoord. Scan opnieuw.';

  @override
  String get dtcCategoryError =>
      'Deze categorie kon niet worden uitgelezen. De volledige fout staat in het diagnoselogboek.';

  @override
  String get dtcCategoryDisconnected =>
      'De verbinding viel weg terwijl deze categorie werd uitgelezen.';

  @override
  String get dtcCategoryPending =>
      'Een regeleenheid heeft het verzoek ontvangen en is er nog mee bezig. Wacht even en scan daarna opnieuw — dit is geen weigering.';

  @override
  String get dtcCategoryUnattributed =>
      'Er kwamen codes terug, maar antwoordheaders stonden uit, waardoor niet bekend is welke regeleenheden antwoordden. Beschouw dit als gedeeltelijk, niet als een schoon resultaat.';

  @override
  String dtcCategorySilentControllers(int count, String controllers) {
    return 'Aantal regeleenheden dat niet antwoordde op dit uitleesverzoek: $count ($controllers). De antwoorden die wel terugkwamen zijn geldig, maar dit kan niet gelden als resultaat voor het hele voertuig.';
  }

  @override
  String dtcCategoryUnresolvedSources(int count, String addresses) {
    return 'Aantal antwoorden waarvan de regeleenheid niet kon worden vastgesteld: $count ($addresses). Uitgelezen codes blijven geldig, maar dit kan niet gelden als resultaat voor het hele voertuig. Scan opnieuw.';
  }

  @override
  String dtcCategoryPendingControllers(int count, int answered) {
    return 'Aantal regeleenheden dat nog bezig is met dit verzoek: $count (al geantwoord: $answered). Het resultaat is onvolledig. Wacht even en scan daarna opnieuw.';
  }

  @override
  String dtcCategoryRefusedControllers(int refused, int answered) {
    return 'Aantal regeleenheden dat het verzoek weigerde: $refused (geantwoord: $answered). Deze scan kan niet het hele voertuig dekken.';
  }

  @override
  String dtcCategoryUnrecognisedResponses(int count, int answered) {
    return 'Aantal antwoorden dat niet kon worden gelezen: $count (geantwoord: $answered). De rest blijft geldig, maar deze scan is onvolledig.';
  }

  @override
  String dtcCategoryMilCountMismatch(
    String controller,
    int claimed,
    int observed,
  ) {
    return '$controller meldde $claimed bevestigde storingscodes, maar deze scan heeft er slechts $observed uitgelezen. Vertrouw op het storingslampje op het dashboard en raadpleeg een werkplaats.';
  }

  @override
  String dtcCategoryMilLitNoCodes(String controller) {
    return '$controller meldde dat het storingslampje brandt, maar er zijn daarvan geen storingscodes uitgelezen. Vertrouw op het storingslampje op het dashboard en raadpleeg een werkplaats.';
  }

  @override
  String dtcCategoryMilDisagreement(String controllers) {
    return 'De eigen status van het voertuig komt niet overeen met de uitgelezen storingscodes ($controllers). Vertrouw op het storingslampje op het dashboard en raadpleeg een werkplaats.';
  }

  @override
  String get connectPairedListFailed =>
      'De lijst met gekoppelde Bluetooth-apparaten kon niet worden gelezen. Controleer of Bluetooth aan staat en probeer het opnieuw.';

  @override
  String get connectBleScanUnavailable =>
      'Bluetooth is momenteel niet bruikbaar. Wacht een ogenblik en zoek daarna opnieuw.';

  @override
  String get connectBleScanBluez =>
      'Er is geen bruikbare BlueZ/D-Bus Bluetooth-service gevonden. Installeer en start de bluetooth-service en probeer het opnieuw.';

  @override
  String get connectBleScanUnclassified => 'BLE-zoeken mislukt.';

  @override
  String dtcClearNrcConditions(String controller) {
    return '$controller weigerde het wissen omdat de voertuigstatus dit niet toestaat. De meeste regeleenheden wissen niet terwijl de motor draait. Zet het contact op AAN met uitgeschakelde motor en probeer het opnieuw.';
  }

  @override
  String dtcClearNrcUnsupported(String controller) {
    return '$controller ondersteunt wissen via Mode 04 niet. Mogelijk is apparatuur van de fabrikant of dealer vereist.';
  }

  @override
  String dtcClearNrcBusy(String controller) {
    return '$controller is bezet. Wacht even en probeer het daarna opnieuw.';
  }

  @override
  String dtcClearNrcSecurity(String controller) {
    return '$controller vereist beveiligingstoegang voordat er kan worden gewist. Apparatuur van de fabrikant of dealer is vereist.';
  }

  @override
  String dtcClearNrcOther(String controller, String code) {
    return '$controller weigerde het wissen (redencode $code). Wacht even en probeer het daarna opnieuw.';
  }

  @override
  String dtcClearSilentControllers(int count, String controllers) {
    return 'Aantal regeleenheden dat niet antwoordde op de wisopdracht: $count ($controllers). De regeleenheden die antwoordden hebben de codes gewist; andere kunnen nog codes bevatten. Scan opnieuw. Stuur geen nieuwe wisopdracht.';
  }

  @override
  String dtcClearUnresolvedSources(int count, String addresses) {
    return 'Aantal antwoorden uit deze scan waarvan de bron niet kon worden vastgesteld: $count ($addresses). Daardoor is niet bekend welke regeleenheden een wisopdracht zou bereiken. Scan opnieuw; als dat adres niet opnieuw verschijnt, maak dan opnieuw verbinding voordat je het probeert.';
  }

  @override
  String dtcClearUnresolvedSourcesDoNotRepeat(int count, String addresses) {
    return 'Aantal antwoorden op de wisopdracht waarvan de bron niet kon worden vastgesteld: $count ($addresses). Stuur geen nieuwe wisopdracht. Scan opnieuw om te zien welke codes er nog zijn.';
  }

  @override
  String dtcClearNrcConditionsDoNotRepeat(String controller) {
    return '$controller weigerde het wissen omdat de voertuigstatus dit niet toestaat. De meeste regeleenheden wissen niet terwijl de motor draait. Zet het contact op AAN met uitgeschakelde motor en scan daarna opnieuw om te zien welke codes er nog zijn. Stuur geen tweede globale wisopdracht — een tweede opdracht kan de emissiegereedheid resetten op een regeleenheid die mogelijk al is gewist.';
  }

  @override
  String dtcClearNrcUnsupportedDoNotRepeat(String controller) {
    return '$controller ondersteunt wissen via Mode 04 niet. Mogelijk is apparatuur van de fabrikant of dealer vereist. Stuur geen tweede globale wisopdracht — een tweede opdracht kan de emissiegereedheid resetten op een regeleenheid die mogelijk al is gewist. Scan opnieuw om te zien welke codes er nog zijn.';
  }

  @override
  String dtcClearNrcBusyDoNotRepeat(String controller) {
    return '$controller is bezet. Stuur geen tweede globale wisopdracht — een tweede opdracht kan de emissiegereedheid resetten op een regeleenheid die mogelijk al is gewist. Scan opnieuw om te zien welke codes er nog zijn.';
  }

  @override
  String dtcClearNrcSecurityDoNotRepeat(String controller) {
    return '$controller vereist beveiligingstoegang voordat er kan worden gewist. Apparatuur van de fabrikant of dealer is vereist. Stuur geen tweede globale wisopdracht — een tweede opdracht kan de emissiegereedheid resetten op een regeleenheid die mogelijk al is gewist.';
  }

  @override
  String dtcClearNrcOtherDoNotRepeat(String controller, String code) {
    return '$controller weigerde het wissen (redencode $code). Stuur geen tweede globale wisopdracht — een tweede opdracht kan de emissiegereedheid resetten op een regeleenheid die mogelijk al is gewist. Scan opnieuw om te zien welke codes er nog zijn.';
  }

  @override
  String get sharePolicyDenied =>
      'De huidige verbindings- of rijstatus staat exporteren niet toe.';

  @override
  String get shareSafetyChanged =>
      'De status veranderde tijdens het voorbereiden van de export, waardoor delen niet is geopend.';

  @override
  String get shareSizeLimit => 'De export overschrijdt de limiet van 32 MiB.';

  @override
  String get shareStagingBusy =>
      'Een eerder deelbestand bevindt zich nog in de bewaarperiode. Probeer het later opnieuw.';

  @override
  String get shareCleanupRequired =>
      'Het tijdelijke deelgebied moet na een herstart worden gecontroleerd.';

  @override
  String get shareSpaceUnknown =>
      'Kon de vrije ruimte die het deelbestand nodig heeft niet bevestigen.';

  @override
  String get shareNoSpace =>
      'Er is onvoldoende opslagruimte om het deelbestand voor te bereiden.';

  @override
  String get shareHandoffFailed =>
      'Het bestand is klaar, maar het deelvenster van het systeem kon niet worden geopend.';

  @override
  String get shareStorageFailure =>
      'Er is een opslagfout opgetreden bij het voorbereiden of vastleggen van het delen.';

  @override
  String shareTelemetrySubject(String sessionId) {
    return 'Lokale OBD-opname $sessionId';
  }

  @override
  String shareRawTranscriptSubject(String stamp) {
    return 'Telltale-transportlogboek $stamp';
  }

  @override
  String get shareRecoveredTranscriptSubject =>
      'Telltale-transportlogboek (laatste verbinding)';

  @override
  String get sharePidCsvSubject => 'Aangepaste PID-definities van Telltale';

  @override
  String get shareTorqueSubsetCsvSubject => 'Torque-compatibele PID-definities';

  @override
  String get shareHumanReportCsvSubject => 'Leesbaar PID-rapport van Telltale';

  @override
  String get transcriptExportUnidentified => 'Exporteren mislukt.';

  @override
  String get handshakeNoteUnexpected =>
      'Deze stap is mislukt met een onverwachte fout. De volledige fout staat in het diagnoselogboek.';

  @override
  String pidFormulaUnsupportedConstruct(String term) {
    return '$term is een Torque-functie die dit dialect niet implementeert, dus de formule kan hier niet worden geëvalueerd.';
  }

  @override
  String pidImportRowFormulaRejected(int line, String reason) {
    return 'Rij $line: $reason';
  }

  @override
  String get telemetryHistoryNeedsForeground =>
      'Keer terug naar Telltale voordat je verdergaat.';

  @override
  String get telemetrySessionPolicyChanged =>
      'Rij- of verbindingsstatus is tijdens deze bewerking gewijzigd.';

  @override
  String get telemetrySessionInvalidId => 'Deze opname-ID is ongeldig.';

  @override
  String get telemetrySessionNotFound => 'Deze lokale opname is niet gevonden.';

  @override
  String get telemetrySessionStorageFailed =>
      'Een lokale opslagbewerking is mislukt.';

  @override
  String get telemetrySessionShareFailed =>
      'Kon delen niet voorbereiden of openen.';

  @override
  String get pidMutationPersistFailed =>
      'De lijst met aangepaste PID\'s kon niet worden opgeslagen. Er is niets gewijzigd.';

  @override
  String get powertrainAuthorizeYearOutOfRange =>
      'Dat modeljaar valt buiten het gedocumenteerde jaarbereik van dit profiel.';

  @override
  String get connectionLayerTransport => 'Verbindingstype';

  @override
  String get connectionLayerProtocol => 'Protocol';

  @override
  String get connectionLayerEcu => 'ECU-antwoorden';

  @override
  String get connectionLayerEvidence => 'Bewijs';

  @override
  String get connectionLayerUnknown => 'Onbekend';

  @override
  String get connectionLayerNotObserved => 'Niet waargenomen';

  @override
  String get connectionLayerObserved => 'Waargenomen';

  @override
  String get connectionLayerAnswered => 'Beantwoord';

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
    return 'gevraagd $requested, vastgesteld $observed';
  }

  @override
  String get connectionLayerKwpSubtypeUnknown =>
      'KWP, 5-baud en fast niet onderscheiden';

  @override
  String get connectionFailureOpenSettings => 'Systeeminstellingen openen.';

  @override
  String get connectionFailureTurnRadioOn => 'Schakel Bluetooth in.';

  @override
  String get connectionFailureCheckDistanceOrPower =>
      'De adapter is mogelijk buiten bereik of heeft geen stroom. Dat is een mogelijke oorzaak, geen bevinding.';

  @override
  String get connectionFailureCheckIgnitionProtocolAdapter =>
      'Controleer het contact, het protocol of de mogelijkheden van de adapter. Stilte is geen bewijs dat het voertuig geen OBD heeft.';

  @override
  String get connectionFailureRetryOrAuto =>
      'Probeer opnieuw, of zet het protocol op Auto.';

  @override
  String get connectionFailureKeepInvalidAndExport =>
      'Het antwoord is ongeldig. Laat het ongeldig en exporteer de beperkte diagnose; het is geen uitlezing.';

  @override
  String get settingsCatalogMarketCa => 'Canada (NRCan)';

  @override
  String get settingsCaPickerTitle => 'Officiële Canadese voertuigcatalogus';

  @override
  String settingsCaPickerScope(int firstYear, int lastYear) {
    return 'Uitsluitend Canadese Fuel Consumption Ratings-rijen voor $firstYear–$lastYear. Verbrandingsmotor (ICE), batterij-elektrisch (BEV) en plug-inhybride (PHEV) blijven aparte klassen. Een overeenkomende merk-/modelnaam is geen EPA- of Taiwanese configuratie.';
  }

  @override
  String get settingsCaMotorNotPower =>
      'Motorvermogen in kilowatt is geen wielvermogen (pk) en wordt niet toegepast.';

  @override
  String get settingsCaClassIce => 'ICE';

  @override
  String get settingsCaClassBev => 'BEV';

  @override
  String get settingsCaClassPhev => 'PHEV';

  @override
  String settingsCaWillApplyOnly(String fields) {
    return 'Alleen $fields wordt toegepast. Motor-kW, brandstofverbruik, actieradius, CO2, VE, Cd, frontaal oppervlak, Crr en transmissierendement blijven onopgelost.';
  }

  @override
  String get serviceRecipesTitle => 'Servicerecepten & actieve diagnose';

  @override
  String get serviceRecipesSubtitle =>
      'Aan standaarden gekoppelde servicerecepten en niet-aansturende functieherkenning';

  @override
  String get serviceRecipesSafetyBannerTitle => 'Geen live kandidaten';

  @override
  String get serviceRecipesSafetyBannerBody =>
      'Live aansturing van een fysiek voertuig is strikt verboden (0 gekwalificeerde voertuigen). Beschikbare recepten zijn uitsluitend simulatie-opstellingen.';

  @override
  String get serviceRecipesDiscoverySection =>
      'Mode 08 niet-aansturende herkenning';

  @override
  String get serviceRecipesDiscoveryDescription =>
      'Vraagt standaard basis-Test-ID\'s (\$00, \$20, ...) op via CAN zonder enig onderdeel aan te sturen.';

  @override
  String get serviceRecipesDiscoveryButton =>
      'Ondersteunde Mode 08-TID\'s ontdekken';

  @override
  String get serviceRecipesDiscovering => 'Ondersteunde TID\'s opvragen...';

  @override
  String serviceRecipesDiscoverySuccess(String tids) {
    return 'Mode 08 wordt ondersteund door de ECU. Ondersteunde TID\'s: $tids';
  }

  @override
  String get serviceRecipesDiscoveryUnsupported =>
      'Mode 08 wordt niet ondersteund door deze ECU';

  @override
  String serviceRecipesDiscoveryUnknown(String reason) {
    return 'Mode 08-ondersteuning is onbekend: $reason';
  }

  @override
  String serviceRecipesDiscoveryPartialWarning(String reason, String blocks) {
    return 'Herkenning gedeeltelijk voltooid ($reason). Niet-voltooide blokken: $blocks. Let op: niet gevonden betekent niet dat het niet wordt ondersteund.';
  }

  @override
  String get serviceRecipesCatalogSection => 'Beschikbare servicerecepten';

  @override
  String get serviceRecipesSimulationBadge => 'Klaar voor simulatie';

  @override
  String get serviceRecipesLiveBlockedBadge =>
      'Live geblokkeerd (0 live kandidaten)';

  @override
  String serviceRecipesStandard(String standard) {
    return 'Standaard: $standard';
  }

  @override
  String serviceRecipesEcuHeader(String header) {
    return 'ECU-header: $header';
  }

  @override
  String serviceRecipesHash(String hash) {
    return 'Canonieke hash: $hash';
  }

  @override
  String get serviceRecipesDetailTitle => 'Details servicerecept';

  @override
  String get serviceRecipesPreconditions => 'Veiligheidsvoorwaarden';

  @override
  String get serviceRecipesRecovery => 'Herstelopdracht';

  @override
  String get serviceRecipesClose => 'Sluiten';

  @override
  String get serviceRecipesDiscoveryRequiresCan =>
      'Vereist een actieve OBD-II CAN-busverbinding.';

  @override
  String serviceRecipesLoadError(String error) {
    return 'Fout bij laden van servicerecepten: $error';
  }

  @override
  String get serviceRecipesNoPreconditions => 'Geen';

  @override
  String get settingsServiceRecipesEntry => 'Servicerecepten & actieve tests';

  @override
  String get settingsServiceRecipesDesc =>
      'Bekijk werkplaats-servicerecepten en ontdek ondersteunde Mode 08-tests';

  @override
  String get mode08ReasonUnheaderedLimitation =>
      'Brontoewijzing en dekking onbevestigd: antwoorden zonder header kunnen de ECU-identiteit niet over meerdere blokken vaststellen';

  @override
  String mode08ReasonNoResponseWithEcu(
    String block,
    String ecu,
    String marker,
  ) {
    return 'Geen antwoord op blok $block van $ecu: $marker';
  }

  @override
  String mode08ReasonNoResponse(String block, String marker) {
    return 'Geen antwoord op blok $block: $marker';
  }

  @override
  String mode08ReasonNegativeWithEcu(String block, String ecu, String nrc) {
    return 'Negatief antwoord op blok $block van $ecu (NRC $nrc)';
  }

  @override
  String mode08ReasonNegative(String block, String nrc) {
    return 'Negatief antwoord op blok $block (NRC $nrc)';
  }

  @override
  String mode08ReasonMalformedWithEcu(
    String block,
    String ecu,
    String details,
  ) {
    return 'Misvormd antwoord op blok $block van $ecu: $details';
  }

  @override
  String mode08ReasonMalformed(String block, String details) {
    return 'Misvormd antwoord op blok $block: $details';
  }

  @override
  String mode08ReasonTimeout(String block) {
    return 'Time-out bij uitleesverzoek voor blok $block';
  }

  @override
  String get mode08ReasonBudgetExceeded =>
      'Herkenningsbudget bereikt voordat alle blokken zijn bevraagd';

  @override
  String get mode08ReasonSessionDisconnected =>
      'Sessie verbroken of vervangen tijdens herkenning';

  @override
  String mode08ReasonUnqueriedAnnounced(String blocks) {
    return 'Niet-bevraagde blokken aangekondigd door ECU\'s: $blocks';
  }

  @override
  String get mode08ReasonRequiresCanBus =>
      'Mode 08-functieherkenning vereist een vastgestelde OBD-II CAN-bus';

  @override
  String get mode08ReasonUnexpectedExecution =>
      'Onverwacht uitvoeringsantwoord op uitleesverzoek voor ondersteunde TID\'s';

  @override
  String get pidDetailEmptyTitle => 'Selecteer een PID';

  @override
  String get pidDetailEmptyBody =>
      'Kies een PID uit de lijst om de definitie en live status te bekijken.';

  @override
  String get pidDetailRangeLabel => 'Bereik';

  @override
  String get pidDetailPriorityLabel => 'Prioriteit';

  @override
  String pidDetailHeaderDefault(String header) {
    return 'Standaard ($header)';
  }

  @override
  String get dtcSystemOverview => 'Systeemoverzicht';

  @override
  String get dtcPartialObservationBadge => 'Gedeeltelijke scan';

  @override
  String get dtcPartialObservationBody =>
      'Deze storingscode is uitgelezen, maar de scan voor deze categorie is niet bij alle regeleenheden voltooid.';

  @override
  String get dtcLinkedFreezeFrameTitle => 'Bijbehorend freeze-frame';

  @override
  String get dtcNoLinkedFreezeFrame =>
      'Deze scan heeft geen freeze-frame dat veilig aan deze storingscode en regeleenheid kan worden gekoppeld.';

  @override
  String get performanceGuideTitle => 'Uitleg acceleratierun';

  @override
  String get performanceGuideStep1 =>
      '1. Kies een doelsnelheid en zet daarna de timer klaar';

  @override
  String get performanceGuideStep2 =>
      '2. Breng het voertuig volledig tot stilstand en wacht tot de run gereed is';

  @override
  String get performanceGuideStep3 =>
      '3. Begin met accelereren; de tijdmeting start automatisch zodra er beweging wordt gedetecteerd';

  @override
  String get performanceGuideStep4 =>
      '4. Bereik de doelsnelheid om de run te voltooien';

  @override
  String get performanceRecordingTrace =>
      'Accelereren... snelheidsverloop wordt opgenomen';

  @override
  String get performanceNoAnalysisTitle => 'Geen analysegegevens';

  @override
  String get performanceNoAnalysisBody =>
      'Deze run stopte voordat er genoeg snelheidsuitlezingen waren opgenomen om een snelheidsverloop of tussentijden op te stellen.';

  @override
  String get connectActivityReconnectingAutomatically =>
      'De adapter reageert niet meer. Automatisch opnieuw verbinden…';
}
