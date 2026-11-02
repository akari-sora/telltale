// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get adapterErrorActivityAlert => 'Alerte d’activité du bus.';

  @override
  String get adapterErrorBufferFull =>
      'La mémoire tampon de l’adaptateur a débordé.';

  @override
  String get adapterErrorBus =>
      'Erreur de bus ; le câblage peut en être la cause.';

  @override
  String get adapterErrorBusBusy => 'Le bus est occupé.';

  @override
  String get adapterErrorBusInit => 'Échec de l’initialisation du bus.';

  @override
  String get adapterErrorCan => 'Erreur du bus CAN.';

  @override
  String get adapterErrorData => 'Les données reçues sont incorrectes.';

  @override
  String get adapterErrorFeedback => 'Erreur de retour du signal.';

  @override
  String get adapterErrorInternal => 'Erreur interne de l’adaptateur.';

  @override
  String get adapterErrorLowPowerAlert =>
      'L’adaptateur va passer en mode basse consommation.';

  @override
  String get adapterErrorLowVoltageReset =>
      'Une tension faible a réinitialisé l’adaptateur.';

  @override
  String get adapterErrorNoData =>
      'Aucune réponse reçue : il peut s’agir d’un silence temporaire ou d’une fonction non prise en charge par le véhicule.';

  @override
  String get adapterErrorStopped => 'Le transfert a été interrompu.';

  @override
  String get adapterErrorUnableToConnect =>
      'Impossible de joindre l’ECU. Vérifiez que le contact est mis.';

  @override
  String get adapterErrorUnknownCommand =>
      'L’adaptateur ne prend pas en charge cette commande.';

  @override
  String get appTagline => 'Télémétrie du véhicule en direct';

  @override
  String get appTitle => 'Telltale';

  @override
  String get appearanceSectionTitle => 'Apparence';

  @override
  String get connectActivityAbortingPreviousConnection =>
      'Arrêt de la connexion précédente, veuillez patienter…';

  @override
  String get connectAnswerBleWithClassic =>
      'Choisissez Bluetooth LE. Aucun appairage préalable n’est nécessaire : recherchez-le dans l’application. Même s’il apparaît dans la liste d’appairage Bluetooth du système, ne l’appairez pas ; cette méthode ne fonctionne pas. Si la recherche ne trouve rien, le 4.0 sur la boîte ne désignait que les caractéristiques de la puce : utilisez plutôt Bluetooth Classic.';

  @override
  String get connectAnswerBleWithoutClassic =>
      'Choisissez Bluetooth LE. Aucun appairage préalable n’est nécessaire : recherchez-le dans l’application. Même s’il apparaît dans la liste d’appairage Bluetooth du système, ne l’appairez pas ; cette méthode ne fonctionne pas. Si la recherche ne trouve rien, vérifiez que l’adaptateur est alimenté ou essayez plutôt Wi‑Fi ; cet appareil ne propose pas Bluetooth Classic.';

  @override
  String get connectAnswerClassic =>
      'Choisissez Bluetooth Classic. Appairez-le d’abord dans les paramètres système ; l’application ne peut pas le faire pour vous. Le code est généralement 1234 ou 0000.';

  @override
  String get connectAnswerWifiDesktop =>
      'Choisissez Wi-Fi. Connectez d’abord cet appareil à ce réseau, puis revenez saisir l’adresse.';

  @override
  String get connectAnswerWifiPhone =>
      'Choisissez Wi-Fi. Connectez d’abord le téléphone à ce réseau, puis revenez saisir l’adresse.';

  @override
  String get connectBleBody =>
      'Un adaptateur BLE n’a pas besoin d’être appairé au préalable. Lancez la recherche puis choisissez votre appareil ; ses noms courants sont OBDII, V-LINK, Vgate ou IOS-Vlink.';

  @override
  String connectBleEmptyScan(String next) {
    return 'La recherche est terminée sans trouver d’adaptateur BLE. Vérifiez dans l’ordre : le voyant de l’adaptateur est-il allumé ? La plupart des prises OBD ne sont alimentées que lorsque le contact est sur ON. Vérifiez ensuite la portée et installez-vous dans le véhicule avant la recherche. $next Un adaptateur BLE n’a pas besoin d’être appairé dans les paramètres système et ne doit pas l’être ; cette méthode ne fonctionne pas.';
  }

  @override
  String get connectBleEmptyScanNextClassic =>
      'Enfin, vérifiez les caractéristiques sur la boîte : si elle indique 2.0 ou 3.0, il s’agit de Bluetooth Classic, qui n’apparaît jamais dans cette liste. Utilisez plutôt Bluetooth Classic ci-dessus.';

  @override
  String get connectBleEmptyScanNextWifi =>
      'Enfin, vérifiez les caractéristiques sur la boîte : si elle indique 2.0/3.0 ou uniquement Wi‑Fi, essayez plutôt Wi‑Fi (cet appareil ne propose pas Bluetooth Classic).';

  @override
  String get connectBlePermissionDeniedForever =>
      'L’autorisation Bluetooth est refusée définitivement. Le système ne la redemandera pas ; activez-la dans les paramètres de l’application.';

  @override
  String get connectBlePermissionNeeded =>
      'L’autorisation Bluetooth est nécessaire pour lancer la recherche.';

  @override
  String get connectBleScan => 'Rechercher des appareils BLE';

  @override
  String get connectBleScanning => 'Recherche…';

  @override
  String get connectBleUnavailableHost =>
      'Bluetooth LE n’est pas encore disponible sur cet appareil';

  @override
  String get connectBluetoothOff =>
      'Bluetooth est désactivé. Activez d’abord Bluetooth dans les paramètres système.';

  @override
  String get connectBluetoothPermissionDeniedForever =>
      'L’autorisation Bluetooth est refusée définitivement. Activez-la dans les paramètres système, puis réessayez.';

  @override
  String get connectBluetoothPermissionNeededForPairedList =>
      'L’autorisation Bluetooth est nécessaire pour afficher les adaptateurs appairés.';

  @override
  String get connectBody =>
      'Branchez un adaptateur ELM327 et mettez le contact, ou utilisez le simulateur intégré.';

  @override
  String get connectCancel => 'Annuler';

  @override
  String get connectClassicEmptyLinuxPort =>
      'Aucun port série Bluetooth (/dev/rfcomm*) trouvé. Appairez d’abord l’ELM327 avec BlueZ, puis créez un TTY RFCOMM avec rfcomm bind (ou l’équivalent) et réessayez.';

  @override
  String get connectClassicEmptyPaired =>
      'Aucun adaptateur appairé trouvé. Appairez-le d’abord dans les paramètres Bluetooth du système (le code de la plupart des ELM327 est 1234 ou 0000).';

  @override
  String get connectClassicEmptyWindowsPort =>
      'Aucun port série Bluetooth (COMx) trouvé. Appairez d’abord l’ELM327 dans les paramètres Bluetooth de Windows et vérifiez que le Gestionnaire de périphériques affiche « Standard Serial over Bluetooth link ».';

  @override
  String get connectClassicListLinuxPort =>
      'Cette liste affiche les ports série Bluetooth associés par BlueZ (/dev/rfcomm* ou équivalent). Une liste vide signifie que le système n’a pas encore créé de nœud RFCOMM, et non que l’application est défaillante.';

  @override
  String get connectClassicListPaired =>
      'Cette liste affiche tous les appareils appairés au système, y compris les casques et les enceintes, en plaçant d’abord ceux qui ressemblent à des adaptateurs. Si vous choisissez le mauvais, appuyez sur Annuler plutôt que d’attendre l’échec ; vous pourrez aussitôt en choisir un autre.';

  @override
  String get connectClassicListWindowsPort =>
      'Cette liste affiche les ports COM associés à Bluetooth (« Standard Serial over Bluetooth link »). Une liste vide signifie que le système n’a pas encore créé de port série virtuel, et non que l’application est défaillante.';

  @override
  String get connectClassicUnavailableHost =>
      'Bluetooth Classic (SPP) est actuellement disponible sur Android, macOS (IOBluetooth RFCOMM), Windows (COM) et Linux (/dev/rfcomm*)';

  @override
  String get connectClassicUnavailableIos =>
      'iOS n’ouvre pas Bluetooth SPP aux applications tierces';

  @override
  String get connectConnect => 'Connecter';

  @override
  String get connectDemoBody =>
      'Simule un moteur quatre cylindres turbo de 2.0 L au ralenti, en accélération, à vitesse stabilisée et en décélération, avec des signaux qui restent physiquement liés (le régime moteur baisse lors d’un changement de rapport tandis que la vitesse continue d’augmenter). Les codes défaut, la lecture du VIN et les requêtes groupées fastMode fonctionnent intégralement.';

  @override
  String get connectDemoStart => 'Démarrer le simulateur';

  @override
  String get connectHandshakeTitle => 'Initialisation ELM327';

  @override
  String get connectHandshakeTitleLastAttempt =>
      'Initialisation ELM327 (dernière tentative)';

  @override
  String get connectHeadline => 'Choisir une connexion';

  @override
  String get connectIssueAdapterAcceptedThenSilent =>
      'L’adaptateur a accepté la connexion mais n’a pas répondu à temps. En général, il n’est pas encore alimenté — la plupart des prises OBD ne sont alimentées que lorsque le contact est mis — ou une autre application y est déjà connectée ; dans ce cas, fermez-la et réessayez.';

  @override
  String connectIssueAdapterSilentOnReset(String command) {
    return 'L’adaptateur n’a pas répondu à la commande de réinitialisation ($command). Cet appareil n’est peut-être pas un adaptateur ELM327, ou la connexion a peut-être été établie avec le mauvais appareil.';
  }

  @override
  String get connectIssueAdapterStoppedResponding =>
      'L’adaptateur a cessé de répondre et la connexion a été interrompue.';

  @override
  String get connectIssueConnectionSetupFailed =>
      'La connexion a échoué pendant son établissement. Vérifiez que l’adaptateur est alimenté et à proximité, puis réessayez. L’erreur complète est conservée dans le journal ci-dessous.';

  @override
  String get connectIssueHandshakeIncomplete =>
      'L’initialisation n’a pas abouti. L’adaptateur n’est peut-être pas compatible.';

  @override
  String connectIssueHandshakeStepFailed(String command, String reason) {
    return 'Échec de l’initialisation à $command ($reason). Vérifiez que l’adaptateur est bien branché et que le contact du véhicule est mis.';
  }

  @override
  String get connectIssuePreviousConnectionStillAborting =>
      'La connexion précédente est toujours en cours d’arrêt et l’adaptateur n’a pas encore été libéré. Patientez quelques secondes et réessayez.';

  @override
  String get connectLastAdapterConnect => 'Connecter maintenant';

  @override
  String get connectLastAdapterForget => 'Oublier';

  @override
  String get connectLastAdapterTitle => 'Dernier adaptateur utilisé';

  @override
  String get connectOpenAppSettings => 'Ouvrir les paramètres de l’application';

  @override
  String get connectOpenSystemSettings => 'Ouvrir les paramètres système';

  @override
  String get connectOpeningConnection => 'Ouverture de la connexion…';

  @override
  String get connectPairedPill => 'Appairé';

  @override
  String get connectQuestionBle =>
      'La boîte, l’annonce ou le nom de l’appareil indique-t-il BLE, 4.0 ou 5.0 ?';

  @override
  String get connectQuestionClassic =>
      'Aucun des deux : un modèle plus ancien portant la mention 2.0 ou 3.0 sur la boîte ?';

  @override
  String get connectQuestionWifiDesktop =>
      'Un nouveau réseau apparaît-il dans la liste Wi-Fi du système (par exemple V-LINK ou WiFi_OBDII) ?';

  @override
  String get connectQuestionWifiPhone =>
      'Un nouveau réseau apparaît-il dans la liste Wi-Fi du téléphone (par exemple V-LINK ou WiFi_OBDII) ?';

  @override
  String get connectSearchAgain => 'Relancer la recherche';

  @override
  String connectSignalStrength(int bars, int total) {
    return 'Puissance du signal $bars/$total';
  }

  @override
  String get connectTranscriptKept =>
      'Le journal complet de cette tentative a été conservé. Le fournir sera plus utile qu’un message d’une ligne.';

  @override
  String get connectTransportBleDescription =>
      'GATT UART — un adaptateur récent à faible consommation';

  @override
  String get connectTransportBleTitle => 'Bluetooth LE';

  @override
  String get connectTransportClassicDescription =>
      'RFCOMM / SPP — l’ELM327 économique le plus courant';

  @override
  String get connectTransportClassicTitle => 'Bluetooth Classic';

  @override
  String get connectTransportDemoDescription =>
      'Un ECU simulé intégré — toute l’application sans matériel';

  @override
  String get connectTransportDemoTitle => 'Simulateur Demo';

  @override
  String get connectTransportWifiDescription =>
      'Un port TCP, généralement 192.168.0.10:35000';

  @override
  String get connectTransportWifiTitle => 'Wi-Fi';

  @override
  String get connectWhichIntro =>
      'Inutile de connaître les termes SPP et GATT. Observez ce que fait votre adaptateur une fois branché :';

  @override
  String get connectWhichNoteGuessing =>
      'Vous ne risquez rien à vous tromper : si la connexion échoue, revenez essayer un autre choix. Si vous êtes vraiment bloqué, utilisez le simulateur Demo en bas pour vérifier que l’application elle-même fonctionne.';

  @override
  String get connectWhichNoteIos =>
      'Un iPhone ne peut utiliser que Wi-Fi ou BLE : un ELM327 Bluetooth ordinaire ne fonctionne pas du tout sous iOS. C’est une limite du système, qu’aucune autre application ne peut contourner.';

  @override
  String get connectWhichTitle => 'Vous ne savez pas quoi choisir ?';

  @override
  String get connectWifiHostLabel => 'Adresse IP';

  @override
  String get connectWifiHostRequired =>
      'Saisissez l’adresse IP de l’adaptateur.';

  @override
  String get connectWifiInstructionsDesktop =>
      'Connectez d’abord cet ordinateur au point d’accès Wi-Fi diffusé par l’adaptateur, puis saisissez son adresse. Si le système indique que le réseau ne peut pas accéder à Internet, choisissez d’y rester. Les ordinateurs utilisent généralement ce point d’accès comme route par défaut ; la liaison à la route Wi-Fi d’Android n’est pas nécessaire.';

  @override
  String get connectWifiInstructionsPhone =>
      'Connectez d’abord le téléphone au point d’accès Wi-Fi diffusé par l’adaptateur, puis saisissez son adresse. Si le système demande s’il faut rester sur un réseau Wi-Fi sans accès à Internet, choisissez d’y rester. Sous Android, Telltale essaie d’affecter son trafic à la route Wi-Fi pendant la connexion, afin que les données mobiles ne la remplacent pas.';

  @override
  String connectWifiPortInvalid(String value, int min, int max) {
    return '« $value » n’est pas un port valide. La plage va de $min à $max.';
  }

  @override
  String get connectWifiPortLabel => 'Port';

  @override
  String connectWifiPortRequired(int port) {
    return 'Saisissez le port (la plupart des adaptateurs utilisent $port).';
  }

  @override
  String get dashboardBatchedPolling => 'Interrogation périodique groupée';

  @override
  String get dashboardBatchingEnabled => 'Regroupement activé';

  @override
  String get dashboardChoosePids => 'Choisir les PID';

  @override
  String get dashboardEmptyBody =>
      'Choisissez les signaux à surveiller sur la page PID ; ils apparaîtront ici.';

  @override
  String get dashboardEmptyTitle => 'Le tableau de bord est vide';

  @override
  String get dashboardGenericObd => 'OBD générique';

  @override
  String get dashboardLocalRecordings => 'Enregistrements locaux';

  @override
  String get dashboardNotConnected => 'Non connecté';

  @override
  String get dashboardPollingModeHelpAction =>
      'À propos du mode d’interrogation périodique';

  @override
  String get dashboardPollingModeHelpBatching =>
      '« Regroupement activé » signifie que Telltale peut grouper des requêtes PID en un seul échange pour réduire les allers-retours : les tentatives groupées sont autorisées et rien n’a désactivé ce regroupement. Il s’agit toujours d’une autorisation, pas d’une mesure : le regroupement effectif dépend aussi des PID confirmés par le véhicule et du nombre de requêtes en attente.';

  @override
  String get dashboardPollingModeHelpObserved =>
      '« Interrogation périodique groupée » signifie qu’une commande Mode 01 de cette connexion a effectivement transporté plusieurs PID. C’est le constat de cet échange, sans garantie que le suivant sera groupé et sans affirmation sur le débit.';

  @override
  String get dashboardPollingModeHelpRate =>
      'PIDs/s est un débit observé sur la dernière seconde, sans garantie de latence, de fraîcheur ou de précision. Il varie selon l’adaptateur, le bus, l’ECU, les PID choisis, la taille des réponses et les éventuelles erreurs.';

  @override
  String get dashboardPollingModeHelpSingle =>
      'Le mode requête unique signifie que chaque PID Mode 01 est lu séparément. Telltale l’utilise lorsque le bus n’accepte jamais les requêtes groupées, comme sur tous les véhicules sans CAN ; tant qu’aucun bloc de prise en charge n’a répondu, car le regroupement de PID non confirmés par le véhicule produit une réponse trop courte ; et après l’échec d’une requête groupée à revenir sous une forme séparable, qu’elle soit tronquée, refusée parce que l’adaptateur a signalé sa mémoire tampon pleine ou restée sans réponse. Les mesures continuent de s’actualiser ; à lui seul, ce mode ne signifie pas un échec de connexion.';

  @override
  String get dashboardPollingModeHelpTitle => 'Mode d’interrogation';

  @override
  String get dashboardSingleRequestMode => 'Mode requête unique';

  @override
  String get dashboardVinRead => 'VIN lu';

  @override
  String get dashboardWorkspaceGauges => 'Cadrans';

  @override
  String get dashboardWorkspaceTrends => 'Tendances';

  @override
  String get datumBadgeCommunityDecode => 'Décodage communautaire';

  @override
  String get datumBadgeDemo => 'Simulé';

  @override
  String get datumBadgeEstimated => 'Estimé';

  @override
  String get datumBadgeExperimental => 'Expérimental';

  @override
  String get datumBadgeFieldVerified => 'Vérifié sur véhicule';

  @override
  String get datumBadgeInvalid => 'Invalide';

  @override
  String get datumBadgeJustUpdated => 'Mis à jour à l’instant';

  @override
  String get datumBadgeOutOfReferenceRange => 'Hors plage';

  @override
  String get datumBadgePartial => 'Partiel';

  @override
  String get datumBadgeStale => 'Périmé';

  @override
  String get datumBadgeTentativeDecode => 'Décodage provisoire';

  @override
  String get datumBadgeUnverified => 'Non vérifié';

  @override
  String get datumBadgeUnverifiedOnThisVehicle => 'Non vérifié sur ce véhicule';

  @override
  String get datumBadgeUserSupplied => 'Fourni par l’utilisateur';

  @override
  String get datumGapModelYearUnknown => 'Année modèle inconnue';

  @override
  String get datumGapNoCatalogMatch => 'Aucune correspondance au catalogue';

  @override
  String get datumGapVinNotRead => 'VIN non lu';

  @override
  String get datumNextStepEstimateOnly =>
      'Cela ne concerne que l’estimation ; les autres mesures restent valables.';

  @override
  String get datumNextStepGenericObd =>
      'Vous pouvez continuer avec OBD générique ou choisir le véhicule manuellement et renseigner les paramètres.';

  @override
  String get datumNextStepOtherReadings =>
      'L’échec ne concerne que cet élément ; les autres mesures restent valables.';

  @override
  String get datumNextStepRawOnly =>
      'La réponse brute et l’erreur peuvent être examinées ; aucune des deux ne doit être interprétée comme une valeur normale.';

  @override
  String get datumReasonAssumptionsUnconfirmed =>
      'Les hypothèses ne sont pas confirmées ; une estimation reste affichée.';

  @override
  String get datumReasonBusError => 'Erreur de bus.';

  @override
  String get datumReasonFormulaError => 'Erreur de formule.';

  @override
  String get datumReasonFuelEstimateMissingInputs =>
      'Une donnée nécessaire à l’estimation de consommation manque.';

  @override
  String get datumReasonHeaderNotOnThisBus =>
      'L’en-tête ne correspond pas au bus utilisé par ce véhicule.';

  @override
  String get datumReasonHorsepowerEstimateMissingInputs =>
      'Une donnée nécessaire à l’estimation de puissance manque.';

  @override
  String get datumReasonMalformedPacket =>
      'Paquet mal formé ; seule la réponse brute peut être examinée.';

  @override
  String get datumReasonNoAnswer =>
      'Aucune réponse : l’application réessaie dans environ une minute.';

  @override
  String get datumReasonNoReadingYet => 'Aucune mesure pour le moment.';

  @override
  String get datumReasonNonFiniteValue => 'Ce n’est pas un nombre fini.';

  @override
  String get datumReasonOutOfReferenceRangeKept =>
      'Hors de la plage de référence habituelle ; la valeur a été conservée telle que lue.';

  @override
  String get datumReasonPidUnsupported =>
      'Ce véhicule ne prend pas en charge ce PID.';

  @override
  String get datumReasonUnsafeService =>
      'Ce service n’est pas une requête en lecture seule.';

  @override
  String get datumReasonUnsafeServiceStopped =>
      'Ce service n’est pas une requête en lecture seule ; il n’a donc pas été envoyé.';

  @override
  String get datumStatusAssumptions => 'Hypothèses';

  @override
  String get datumStatusClose => 'Fermer';

  @override
  String get datumStatusFollowsData => 'L’état suit les données';

  @override
  String get datumStatusDetailsHint =>
      'Appuyez pour les détails de l’état des données';

  @override
  String get datumStatusUnverifiedExplanation =>
      '« Non vérifié » signifie qu’aucune comparaison sur véhicule réel pour ce décodeur sur votre véhicule n’est documentée ici. Cela ne signifie pas que la mesure est erronée et ne certifie pas sa précision. L’actualité des données et les défauts sont indiqués séparément.';

  @override
  String get datumStatusFormula => 'Formule';

  @override
  String get derivedAirflow => 'Débit d’air';

  @override
  String get derivedEcuFuelTitle => 'Données de carburant ECU';

  @override
  String get derivedEcuReported => 'Indiqué par l’ECU';

  @override
  String get derivedEngineHorsepower => 'Puissance moteur';

  @override
  String get derivedEstimatedFuelTitle => 'Consommation estimée';

  @override
  String get derivedEstimatesDetailsTitle =>
      'Formules et hypothèses des estimations';

  @override
  String get derivedEstimatesTitle => 'Valeurs estimées';

  @override
  String get derivedFuelUse => 'Consommation';

  @override
  String get derivedTorque => 'Couple';

  @override
  String get derivedUnavailableMessage =>
      'La puissance ne peut être estimée qu’après réception des données de vitesse et d’accélération du véhicule';

  @override
  String dtcBothSilentDetail(Object mode) {
    return 'Le véhicule n’a pas répondu à la requête Mode $mode, et Mode 03 n’a pas répondu non plus : il est donc impossible de savoir si le véhicule ne la prend pas en charge ou si cette connexion ne l’a simplement pas lue.';
  }

  @override
  String dtcCategoryFault(Object category) {
    return 'Un défaut lié à $category';
  }

  @override
  String get dtcClear => 'Effacer';

  @override
  String get dtcClearCancel => 'Annuler';

  @override
  String get dtcClearConfirm => 'Les effacer';

  @override
  String get dtcClearDialogBody =>
      'Cette opération efface les codes défaut mémorisés et en attente, éteint le voyant de défaut et réinitialise l’état de préparation antipollution : le véhicule doit effectuer à nouveau un cycle complet d’autodiagnostic avant de pouvoir réussir un contrôle. Les codes défaut permanents (Mode 0A) ne peuvent pas être effacés.';

  @override
  String get dtcClearDialogFrameUnread =>
      'Cette analyse n’a pas lu de trame figée ; cela ne signifie pas que le véhicule n’en possède pas. Relancez d’abord l’analyse, puis décidez si vous souhaitez effacer les codes.';

  @override
  String dtcClearDialogFrames(Object codes) {
    return 'La trame figée associée à $codes sera également effacée : tout l’enregistrement du régime moteur, de la température du liquide de refroidissement et de la charge au moment du défaut. Elle ne pourra pas être relue tant que le défaut ne se reproduit pas.';
  }

  @override
  String get dtcClearDialogTitle => 'Effacer les codes défaut ?';

  @override
  String dtcClearDialogUnanswered(int count, Object categories) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count catégories de cette analyse n’ont pas répondu complètement',
      one: 'Une catégorie de cette analyse n’a pas répondu complètement',
    );
    return '$_temp0 ($categories) ; des codes défaut ont donc pu vous échapper. Après effacement, ils ne pourront plus jamais être lus.';
  }

  @override
  String get dtcClearCancelledBeforeSend =>
      'L’effacement a été annulé avant l’envoi de toute commande par l’application. Relancez l’analyse, puis réessayez si vous souhaitez toujours effacer les codes.';

  @override
  String get dtcClearConfirmed => 'La commande d’effacement a été envoyée.';

  @override
  String get dtcClearFailureDoNotRepeat =>
      'Une commande d’effacement a peut-être déjà atteint le véhicule. N’en envoyez pas d’autre : un second effacement global peut réinitialiser l’état de préparation antipollution d’un calculateur qui a peut-être déjà effectué l’effacement. Relancez l’analyse pour voir ce qui reste.';

  @override
  String get dtcClearFailureGeneric =>
      'L’effacement ne s’est pas terminé. Relancez l’analyse pour voir les codes actuels avant de décider si vous souhaitez réessayer.';

  @override
  String get dtcClearNotAccepted =>
      'L’effacement a échoué ; aucun calculateur n’a accepté la commande. Vous pouvez réessayer.';

  @override
  String get dtcClearPartiallyConfirmed =>
      'Au moins un calculateur a signalé que l’effacement était terminé, et l’état des autres n’a pas pu être confirmé. N’envoyez pas d’autre commande d’effacement : la répéter réinitialise l’état de préparation antipollution des calculateurs ayant déjà terminé. Relancez l’analyse pour voir le résultat.';

  @override
  String get dtcClearPreviousConnectionUnconfirmed =>
      'Une connexion précédente a envoyé une commande d’effacement dont le résultat n’a pas été confirmé. Relancez d’abord l’analyse, voyez quels codes restent, puis décidez si vous souhaitez effacer.';

  @override
  String get dtcClearRescanSettled =>
      'L’effacement précédent n’a pas pu être entièrement confirmé. Voici l’état réel après cette nouvelle analyse.';

  @override
  String get dtcClearSentUnconfirmed =>
      'La commande d’effacement a été envoyée, mais la réponse a été endommagée pendant le transport ; on ignore donc si le véhicule a effectué l’effacement. Relancez l’analyse pour vérifier ; n’envoyez pas d’autre commande d’effacement : si la première a réussi, la répéter réinitialisera l’état de préparation antipollution.';

  @override
  String get dtcClearTimeout =>
      'Aucune réponse après l’envoi de la commande d’effacement ; on ignore donc si le véhicule a effectué l’effacement. Relancez l’analyse pour vérifier. N’envoyez pas une autre commande d’effacement à l’aveugle.';

  @override
  String get dtcClearUnexpected =>
      'L’effacement a échoué ; on ignore donc si le véhicule a effectué l’effacement. Relancez l’analyse pour vérifier. N’envoyez pas une autre commande d’effacement à l’aveugle.';

  @override
  String get dtcClearing => 'Effacement…';

  @override
  String get dtcScanDisconnectedMidScan =>
      'La connexion a été interrompue pendant l’analyse, qui n’a donc pas abouti.';

  @override
  String get dtcScanInterrupted =>
      'L’analyse a été interrompue (l’application est peut-être passée en arrière-plan ou la connexion a changé) et n’a pas produit de résultat complet. Relancez l’analyse.';

  @override
  String get dtcCompleteCleanBody =>
      'Cela signifie que tous les calculateurs ayant répondu n’ont signalé aucun code défaut. Cela ne signifie pas que tous les modules du véhicule ont été interrogés.';

  @override
  String get dtcCompleteCleanTitle =>
      'Aucun des calculateurs ayant répondu n’a signalé de code défaut.';

  @override
  String dtcControllerLabel(Object controller) {
    return 'Calculateur $controller';
  }

  @override
  String get dtcDismiss => 'Fermer';

  @override
  String dtcFreezeFrameBody(Object code) {
    return 'Les valeurs enregistrées par ce calculateur à l’instant où $code a été confirmé. L’effacement des codes défaut détruit aussi cet enregistrement.';
  }

  @override
  String get dtcFreezeFrameContentsUnknown =>
      'Ce calculateur possède une trame figée, mais il n’a pas répondu à la requête demandant ses éléments ; son contenu n’a donc pas pu être lu. Une nouvelle analyse peut fonctionner.';

  @override
  String get dtcFreezeFrameNothingDecodable =>
      'Ce calculateur possède une trame figée, mais aucun de ses éléments ne peut être décodé par cette application.';

  @override
  String get dtcFreezeFrameTitle => 'Le véhicule au moment du défaut';

  @override
  String dtcFreezeFrameUndecodable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count autres éléments de cette trame figée n’ont pas de formule de conversion dans cette application et ne sont donc pas affichés.',
      one: 'Un autre élément de cette trame figée n’a pas de formule de conversion dans cette application et n’est donc pas affiché.',
    );
    return '$_temp0';
  }

  @override
  String dtcFreezeFrameUnreadItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count éléments n’ont pas été reçus cette fois (le temps a pu manquer ou le calculateur n’a pas répondu). Une nouvelle analyse peut les lire.',
      one: 'Un élément n’a pas été reçu cette fois (le temps a pu manquer ou le calculateur n’a pas répondu). Une nouvelle analyse peut le lire.',
    );
    return '$_temp0';
  }

  @override
  String get dtcFreezeFrameUnreadPanel =>
      'Cette analyse n’a pas lu de trame figée ; cela ne signifie pas que le véhicule n’en possède pas. Relancez d’abord l’analyse, puis décidez si vous souhaitez effacer les codes défaut, car cet effacement détruit définitivement l’enregistrement du moment du défaut. Si toutes les analyses donnent le même résultat, ce véhicule n’en fournit peut-être pas.';

  @override
  String dtcGroupHeader(Object label, Object mode, int count) {
    return '$label (Mode $mode) · $count';
  }

  @override
  String get dtcHeadline => 'Codes défaut';

  @override
  String get dtcListSeparator => ', ';

  @override
  String get dtcManufacturerSpecific =>
      'Code propre au constructeur : consultez le manuel d’entretien de ce véhicule';

  @override
  String get dtcMilOff => 'Le voyant de défaut est éteint';

  @override
  String get dtcMilOn => 'Le voyant de défaut est allumé';

  @override
  String get dtcMonitorBoostPressure => 'Pression de suralimentation';

  @override
  String get dtcMonitorCatalyst => 'Catalyseur';

  @override
  String get dtcMonitorComponents => 'Ensemble des composants';

  @override
  String get dtcMonitorEgr => 'Système EGR / VVT';

  @override
  String get dtcMonitorEvaporative => 'Système d’émissions par évaporation';

  @override
  String get dtcMonitorExhaustSensor => 'Capteur d’échappement';

  @override
  String get dtcMonitorFuelSystem => 'Système de carburant';

  @override
  String get dtcMonitorGasolineParticulateFilter =>
      'Filtre à particules essence (GPF)';

  @override
  String get dtcMonitorHeatedCatalyst => 'Catalyseur chauffé';

  @override
  String get dtcMonitorMisfire => 'Ratés d’allumage';

  @override
  String get dtcMonitorNmhcCatalyst => 'Catalyseur NMHC';

  @override
  String get dtcMonitorNoxAftertreatment => 'Post-traitement NOx / SCR';

  @override
  String get dtcMonitorOxygenSensor => 'Sonde à oxygène';

  @override
  String get dtcMonitorOxygenSensorHeater => 'Chauffage de la sonde à oxygène';

  @override
  String get dtcMonitorParticulateFilter => 'Filtre à particules';

  @override
  String get dtcMonitorSecondaryAir => 'Système d’air secondaire';

  @override
  String dtcNoDescriptionForSubsystem(Object subsystem) {
    return '$subsystem — cette application ne possède pas de description détaillée de ce code';
  }

  @override
  String get dtcNotConnectedBody =>
      'La lecture des codes défaut nécessite un adaptateur ELM327 connecté ou le simulateur en marche.';

  @override
  String get dtcNotConnectedTitle => 'Non connecté';

  @override
  String get dtcNotScanned => 'Pas encore analysé';

  @override
  String dtcPartialCleanOptionalGaps(int count, Object controllers) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count calculateurs',
      one: 'un calculateur',
    );
    return 'Les trois catégories ont été interrogées jusqu’au bout. Pour $_temp0 ($controllers), ni les codes défaut en attente ni les codes permanents ne sont pris en charge : c’est normal sur de nombreux véhicules, mais cela empêche aussi de déclarer ce véhicule sans défaut.';
  }

  @override
  String get dtcPartialCleanTitle =>
      'Les catégories ayant répondu n’ont signalé aucun code défaut.';

  @override
  String dtcPartialCleanUnanswered(Object categories) {
    return '$categories n’ont pas répondu, leur état ne peut donc pas être confirmé : cela ne signifie pas que le véhicule est sans problème.';
  }

  @override
  String dtcPartialCodesRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count codes défaut ont été lus',
      one: 'Un code défaut a été lu',
    );
    return '$_temp0 avant l’arrêt de cette catégorie, mais la couverture est incomplète :';
  }

  @override
  String dtcPartiallyAnsweredDetail(Object message) {
    return 'Seuls certains calculateurs de cette catégorie ont répondu, les autres n’ont pas répondu ; ce résultat ne peut donc pas représenter l’ensemble du véhicule. $message';
  }

  @override
  String get dtcReadFailed => 'Échec de lecture';

  @override
  String dtcReadFailureDetail(Object label, Object mode, Object message) {
    return '$label (Mode $mode) : $message';
  }

  @override
  String get dtcReadinessAllComplete =>
      'Tous les moniteurs de préparation dont ce calculateur est responsable sont terminés.';

  @override
  String dtcReadinessIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moniteurs sont encore incomplets',
      one: '1 moniteur est encore incomplet',
    );
    return '$_temp0 : un contrôle pourrait échouer actuellement.';
  }

  @override
  String get dtcReadinessSaysNothing =>
      'Ce calculateur n’a signalé aucun moniteur de préparation ; il n’est peut-être pas chargé de la surveillance des émissions, et cela ne signifie pas qu’il est prêt.';

  @override
  String get dtcReadinessTitle => 'État de préparation antipollution';

  @override
  String get dtcRescanFirst => 'Relancez d’abord l’analyse';

  @override
  String get dtcRetry => 'Réessayer';

  @override
  String get dtcScanBody =>
      'Lit les codes défaut mémorisés Mode 03, en attente Mode 07 et permanents Mode 0A.';

  @override
  String get dtcScanTitle => 'Analyser les codes défaut du véhicule';

  @override
  String get dtcScanning => 'Analyse…';

  @override
  String dtcSelfReportedCodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ce calculateur indique lui-même $count codes défaut confirmés.',
      one: 'Ce calculateur indique lui-même 1 code défaut confirmé.',
    );
    return '$_temp0';
  }

  @override
  String get dtcSelfReportedNoCodes =>
      'Ce calculateur indique lui-même qu’il n’a aucun code défaut confirmé.';

  @override
  String get dtcSilentCategoryHeadline => 'Cette catégorie n’a pas répondu';

  @override
  String get dtcSilentPendingDetail =>
      'Les codes défaut en attente (Mode 07) n’ont pas répondu. Cet ECU ne met peut-être pas le service en œuvre, ou il n’a simplement pas été lu cette fois : l’absence de réponse ne permet pas de distinguer ces cas et ne doit pas être interprétée comme une absence de défauts en attente. Le résultat des codes défaut mémorisés n’est pas affecté.';

  @override
  String get dtcSilentPermanentDetail =>
      'Les codes défaut permanents (Mode 0A) n’ont pas répondu. Cette catégorie est apparue avec la génération OBD-II vers 2010 ; les véhicules plus anciens ne la prennent donc pas toujours en charge. Mais l’absence de réponse peut tout aussi bien signifier qu’elle n’a simplement pas été lue cette fois, sans pouvoir distinguer les deux cas. Le résultat des codes défaut mémorisés n’est pas affecté.';

  @override
  String get dtcStartScan => 'Lancer l’analyse';

  @override
  String dtcStoredSilentDetail(Object mode) {
    return 'Le véhicule n’a pas répondu à la requête Mode $mode ; il est donc impossible de confirmer s’il possède des codes défaut mémorisés. Ce n’est pas la même chose que ne pas avoir de codes défaut.';
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
  String get dtcUnconfirmed => 'Impossible à confirmer';

  @override
  String get dtcUnknownError => 'Erreur inconnue';

  @override
  String get dtcUnknownMonitor => 'Moniteur inconnu';

  @override
  String get dtcVerdictCompleteClean =>
      'Aucun code défaut des calculateurs ayant répondu';

  @override
  String get dtcVerdictPartialClean => 'Partiellement non confirmé';

  @override
  String get fieldEventBody =>
      'N’appuyez que lorsque le véhicule est complètement arrêté, en tant que passager ou conducteur d’un véhicule en stationnement. Les événements partagent une même chronologie avec les données OBD brutes et une sauvegarde immédiate est tentée.';

  @override
  String get fieldEventEngineStarted => 'Moteur démarré';

  @override
  String get fieldEventHeading => 'Marqueurs d’événements sur le terrain';

  @override
  String get fieldEventIgnitionOn => 'Contact mis';

  @override
  String get fieldEventMemoryOnly =>
      'Enregistré dans cette session, mais la sauvegarde automatique a échoué : exportez le journal de diagnostic maintenant.';

  @override
  String fieldEventRecorded(String marker) {
    return 'Enregistré et sauvegardé : $marker';
  }

  @override
  String get fieldEventRoadTestStarted => 'Essai routier commencé';

  @override
  String get fieldEventThrottleBlip => 'Bref coup d’accélérateur';

  @override
  String get fieldEventUnavailable =>
      'Aucune connexion active à un véhicule pour l’enregistrement.';

  @override
  String get gaugeNoData => 'Aucune donnée';

  @override
  String gaugeNoDataBecause(String reason) {
    return 'Aucune donnée : $reason';
  }

  @override
  String gaugeReadingStale(String reading) {
    return '$reading (données périmées)';
  }

  @override
  String get gaugeUnsupportedByVehicle => 'Non pris en charge par ce véhicule';

  @override
  String get handshakeNoteAborted =>
      'Arrêté après l’échec d’une étape précédente.';

  @override
  String get handshakeNoteEcuRefusedSupportQuery =>
      'L’ECU a refusé la requête de prise en charge (réponse négative).';

  @override
  String get handshakeNoteEcuSilent => 'L’ECU n’a pas répondu.';

  @override
  String get handshakeNoteNotAcknowledged =>
      'L’adaptateur n’a pas accusé réception de cette commande.';

  @override
  String get handshakeNoteNotModeOnePositiveReply =>
      'La réponse n’est pas une réponse positive Mode 01.';

  @override
  String get handshakeNotePidEchoMismatch =>
      'La réponse répète un PID différent de celui demandé.';

  @override
  String get handshakeNoteSupportMaskTooShort =>
      'La réponse de prise en charge est trop courte ; 41 00 et quatre octets supplémentaires sont nécessaires.';

  @override
  String get handshakeNoteTimedOut => 'Délai dépassé.';

  @override
  String get handshakeStepAdapterVersion => 'Lire la version de l’adaptateur';

  @override
  String get handshakeStepAdaptiveTiming =>
      'Activer la temporisation adaptative recommandée par la fiche technique';

  @override
  String get handshakeStepBatteryVoltage => 'Lire la tension de la batterie';

  @override
  String get handshakeStepDeviceIdentity =>
      'Lire la chaîne d’identification de l’appareil';

  @override
  String get handshakeStepEchoOff => 'Désactiver l’écho des commandes';

  @override
  String get handshakeStepLinefeedsOff => 'Désactiver les sauts de ligne';

  @override
  String get handshakeStepMemoryOff => 'Désactiver les écritures en mémoire';

  @override
  String get handshakeStepNoReason => 'aucune réponse';

  @override
  String get handshakeStepProtocolAuto =>
      'Détecter automatiquement le protocole du bus';

  @override
  String get handshakeStepProtocolDescription =>
      'Lire la description du protocole';

  @override
  String get handshakeStepProtocolNumber => 'Lire le numéro du protocole';

  @override
  String get handshakeStepReset => 'Réinitialiser l’adaptateur par logiciel';

  @override
  String get handshakeStepResponseTimeout =>
      'Régler le délai de réponse à environ 408 ms';

  @override
  String get handshakeStepSpacesOff =>
      'Désactiver les espaces pour réduire le trafic d’un tiers';

  @override
  String get handshakeStepSupportProbe =>
      'Demander quels PID l’ECU prend en charge, ce qui prouve qu’un véhicule a répondu';

  @override
  String get languageSaveFailed =>
      'Impossible d’enregistrer la langue. Réessayez.';

  @override
  String get languageSectionTitle => 'Language / 語言';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navDtc => 'Codes défaut';

  @override
  String get navPerformance => 'Chrono';

  @override
  String get navPid => 'PID';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get performanceArm => 'Armer le chronomètre';

  @override
  String get performanceDisclaimer =>
      'Les temps proviennent du signal de vitesse routière OBD. La plupart des véhicules affichent 1–3 km/h de plus sur leur compteur, et le signal ne s’actualise qu’environ 10–20 fois par seconde ; le résultat n’est donc qu’indicatif et n’équivaut pas à celui d’un équipement de mesure professionnel.';

  @override
  String get performanceHeadline => 'Test d’accélération';

  @override
  String get performanceNoSpeedSignal =>
      'Aucun signal valide de vitesse routière pour le moment (PID 010D). Le test d’accélération ne peut pas chronométrer un passage sans ce signal.';

  @override
  String get performanceNotConnectedBody =>
      'Le test d’accélération nécessite la vitesse routière en direct. Connectez un adaptateur ou démarrez le simulateur intégré.';

  @override
  String get performanceNotConnectedTitle => 'Non connecté';

  @override
  String get performancePeakSpeed => 'Vitesse maximale';

  @override
  String get performanceReset => 'Réinitialiser';

  @override
  String get performanceSecondsUnit => 'secondes';

  @override
  String get performanceSpeedGaugeLabel => 'Vitesse';

  @override
  String get performanceSpeedTraceHeading => 'Courbe de vitesse';

  @override
  String get performanceSplitsHeading => 'Temps partiels';

  @override
  String get performanceStateAborted =>
      'Ce passage n’a pas été terminé ; voici ce qui a été enregistré avant son arrêt';

  @override
  String get performanceStateAwaitingSpeedSignal =>
      'En attente d’un signal de vitesse';

  @override
  String performanceStateAwaitingStandstill(String speed) {
    return 'Arrêtez-vous complètement d’abord : actuellement $speed km/h';
  }

  @override
  String performanceStateFinished(int target) {
    return '0 → $target km/h terminé';
  }

  @override
  String get performanceStateIdle =>
      'Choisissez une vitesse cible, puis démarrez';

  @override
  String get performanceStateRunning => 'Chronométrage';

  @override
  String get performanceStateStaged =>
      'Prêt : le chronomètre démarre lorsque vous partez';

  @override
  String get performanceSubhead =>
      'Un passage chronométré au départ arrêté jusqu’à une vitesse cible';

  @override
  String get performanceTargetSpeedHeading => 'Vitesse cible';

  @override
  String get pidActionCancel => 'Annuler';

  @override
  String get pidActionDelete => 'Supprimer';

  @override
  String get pidArrangeBody =>
      'Faites glisser pour réorganiser. Le tableau de bord se remplit de gauche à droite et de haut en bas : le premier élément est donc vu en premier.';

  @override
  String get pidArrangeEmptyMessage =>
      'Activez-en quelques-uns dans la liste, puis revenez les classer.';

  @override
  String get pidArrangeEmptyTitle => 'Aucun PID n’est encore activé';

  @override
  String pidBulkActionAddConfirmed(int count) {
    return 'Ajouter les $count confirmés';
  }

  @override
  String get pidBulkActionAllActive => 'Tous déjà activés';

  @override
  String get pidBulkActionIncomplete => 'Données d’analyse incomplètes';

  @override
  String get pidBulkActionLocked =>
      'Modification impossible pendant l’enregistrement';

  @override
  String get pidBulkActionPending => 'En attente des résultats d’analyse';

  @override
  String get pidBulkActionZero => 'Aucun PID pris en charge confirmé';

  @override
  String pidBulkAddCount(int count) {
    return 'Ajouter $count';
  }

  @override
  String pidBulkAddDialogTitle(int count) {
    return 'Ajouter $count PID confirmés comme pris en charge ?';
  }

  @override
  String pidBulkAdded(int count) {
    return '$count PID confirmés comme pris en charge ont été ajoutés.';
  }

  @override
  String pidBulkUnconfirmedBlocks(int count) {
    return '$count blocs de prise en charge restent non confirmés ; seuls les éléments étayés par des preuves positives sont ajoutés.';
  }

  @override
  String pidBulkWillAdd(int count) {
    return '$count seront ajoutés. Plus le nombre de PID activés est élevé, moins chacun peut être actualisé fréquemment.';
  }

  @override
  String pidCapabilityConfirmedCount(int confirmed) {
    return '$confirmed confirmés';
  }

  @override
  String get pidCapabilityCoverageNone =>
      'Aucune couverture contiguë établie pour le moment';

  @override
  String pidCapabilityCoverageThroughEnd(String through) {
    return 'Couverture contiguë 01–$through (fin atteinte)';
  }

  @override
  String pidCapabilityCoverageThroughUnknown(String through) {
    return 'Couverture contiguë 01–$through (suite inconnue)';
  }

  @override
  String get pidCapabilityPhaseAttemptFinished =>
      'Cette tentative d’analyse de prise en charge est terminée';

  @override
  String get pidCapabilityPhaseInterrupted =>
      'L’analyse de prise en charge a été interrompue';

  @override
  String get pidCapabilityPhaseNotStarted => 'Analyse non commencée';

  @override
  String get pidCapabilityPhaseRunning =>
      'Confirmation des fonctions prises en charge par ce véhicule';

  @override
  String pidCapabilitySemantics(String phase, int confirmed, int unknown) {
    return 'PID pris en charge par le véhicule. $phase. $confirmed confirmés. $unknown blocs inconnus.';
  }

  @override
  String get pidCapabilityTitle => 'PID pris en charge par le véhicule';

  @override
  String pidCapabilityUnknownBlocks(int unknown) {
    return '$unknown blocs inconnus';
  }

  @override
  String pidEditorCollision(String name) {
    return 'Un PID personnalisé utilise déjà cette combinaison ($name). Utilisez un autre mode + PID, un autre en-tête ou un autre suffixe de nom.';
  }

  @override
  String pidEditorDeleteBody(String name) {
    return 'La définition de « $name » sera supprimée, son cadran disparaîtra du tableau de bord et cette opération est irréversible.';
  }

  @override
  String get pidEditorDeleteTitle => 'Supprimer ce PID ?';

  @override
  String get pidEditorDiscard => 'Abandonner';

  @override
  String get pidEditorDiscardBody =>
      'Les modifications de ce PID n’ont pas été enregistrées ; elles seront perdues si vous quittez.';

  @override
  String get pidEditorDiscardTitle =>
      'Abandonner les modifications non enregistrées ?';

  @override
  String pidEditorEquationHelper(String valSyntax) {
    return 'A..N correspondent aux octets de la réponse ; SIGNED(), ABS(), LOG10(), $valSyntax et BARO sont disponibles';
  }

  @override
  String get pidEditorFieldEquation => 'Expression';

  @override
  String get pidEditorFieldHeader => 'En-tête CAN';

  @override
  String get pidEditorFieldMax => 'Maximum';

  @override
  String get pidEditorFieldMin => 'Minimum';

  @override
  String get pidEditorFieldModeAndPid => 'Mode + PID';

  @override
  String get pidEditorFieldName => 'Nom';

  @override
  String get pidEditorFieldSample => 'Octets de réponse de test';

  @override
  String get pidEditorFieldShortName => 'Nom court (affiché sur le cadran)';

  @override
  String get pidEditorFieldUnits => 'Unités';

  @override
  String get pidEditorHeaderHelper => '7E0 = moteur';

  @override
  String get pidEditorKeepEditing => 'Continuer à modifier';

  @override
  String get pidEditorModeAndPidHelper => 'Par exemple 010C ou 221101';

  @override
  String get pidEditorSampleHelper =>
      'Saisissez les données hexadécimales pour prévisualiser le résultat pendant la saisie';

  @override
  String get pidEditorSave => 'Enregistrer';

  @override
  String get pidEditorSectionFormula => 'Formule';

  @override
  String get pidEditorSectionIdentity => 'Identité';

  @override
  String get pidEditorSectionQuery => 'Requête';

  @override
  String get pidEditorSectionRangeAndPriority => 'Plage du cadran et priorité';

  @override
  String get pidEditorTitleEdit => 'Modifier le PID';

  @override
  String get pidEditorTitleNew => 'Nouveau PID personnalisé';

  @override
  String pidExportFailed(String error) {
    return 'Échec de l’exportation : $error';
  }

  @override
  String get pidExportNoCustomPids => 'Aucun PID personnalisé à exporter.';

  @override
  String get pidImportNothingToImport => 'Aucune définition à importer.';

  @override
  String pidImportLandedClean(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PID personnalisés importés.',
      one: '1 PID personnalisé importé.',
    );
    return '$_temp0';
  }

  @override
  String pidImportLandedWithNotes(int count, String notes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments importés, $notes.',
      one: '1 élément importé, $notes.',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteSkippedRows(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lignes présentaient des problèmes et ont été ignorées',
      one: '1 ligne présentait des problèmes et a été ignorée',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDefaultedRanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lignes ont utilisé la plage de cadran par défaut',
      one: '1 ligne a utilisé la plage de cadran par défaut',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteReplaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments ont remplacé une définition existante',
      one: '1 élément a remplacé une définition existante',
    );
    return '$_temp0';
  }

  @override
  String pidImportNoteDuplicatesInFile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count lignes dupliquaient d’autres lignes du fichier et ont été ignorées',
      one: '1 ligne dupliquait une autre ligne du fichier et a été ignorée',
    );
    return '$_temp0';
  }

  @override
  String get pidImportPickerFailed =>
      'Impossible d’ouvrir le sélecteur de fichiers.';

  @override
  String get pidImportReadFailed => 'Impossible de lire le fichier.';

  @override
  String get pidListSeparator => ', ';

  @override
  String get pidManagerActiveOnly => 'Activés seulement';

  @override
  String get pidManagerAdd => 'Nouveau';

  @override
  String get pidManagerArrangeDashboard => 'Organiser le tableau de bord';

  @override
  String pidManagerCounts(int active, int total) {
    return '$active activés · $total disponibles';
  }

  @override
  String get pidManagerExportCsv => 'Exporter les PID personnalisés';

  @override
  String get pidManagerExportTorqueCsv =>
      'Exporter au format CSV compatible Torque';

  @override
  String get pidManagerExportHumanReport => 'Exporter le rapport PID lisible';

  @override
  String get pidManagerHeadline => 'Gestionnaire de PID';

  @override
  String get pidManagerImportCsv => 'Importer un CSV';

  @override
  String get pidManagerMoreActions => 'Plus';

  @override
  String get pidManagerNoMatchMessage =>
      'Essayez un autre mot-clé ou créez un PID personnalisé.';

  @override
  String get pidManagerNoMatchTitle => 'Aucun PID correspondant';

  @override
  String get pidManagerPowertrainBatteryCatalog =>
      'Catalogue des batteries du groupe motopropulseur';

  @override
  String get pidManagerSearchHint => 'Rechercher par nom ou code PID…';

  @override
  String get pidPickCsvDialogTitle => 'Choisir un CSV de définitions PID';

  @override
  String get pidPillCustom => 'Personnalisé';

  @override
  String get pidPillUnsupported => 'Non pris en charge';

  @override
  String get pidPreviewCannotEvaluate => 'Impossible à calculer';

  @override
  String get pidPreviewResultLabel => 'Résultat';

  @override
  String pidPreviewSubstituted(double value, String dependencies) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return 'L’aperçu remplace $dependencies par $valueString ; la valeur réelle provient de ce PID une fois connecté.';
  }

  @override
  String get pidPreviewTitle => 'Aperçu en direct';

  @override
  String get pidPriorityHigh => 'Élevée';

  @override
  String get pidPriorityLow => 'Faible';

  @override
  String get pidPriorityMedium => 'Moyenne';

  @override
  String get pidPriorityVeryLow => 'Très faible';

  @override
  String get pidRowEdit => 'Modifier';

  @override
  String pidRowShowOnDashboard(String name) {
    return 'Afficher $name sur le tableau de bord';
  }

  @override
  String pidRowStaleUnits(String units) {
    return '$units · périmé';
  }

  @override
  String powertrainAuthorizationGranted(String profile) {
    return 'Les signaux de batterie pour $profile sont activés pour cette connexion';
  }

  @override
  String powertrainAuthorizationRefused(String reason) {
    return 'Activation impossible : $reason';
  }

  @override
  String get powertrainCancel => 'Annuler';

  @override
  String powertrainCatalogCounts(int profiles, int probeable) {
    return 'Profils : $profiles · Lectures uniques : $probeable';
  }

  @override
  String get powertrainCatalogLoadFailedBody =>
      'La vérification d’intégrité a échoué ; aucune donnée du véhicule n’est affichée ni installée.';

  @override
  String get powertrainCatalogLoadFailedTitle =>
      'Impossible de charger le catalogue hors ligne';

  @override
  String get powertrainCatalogNotVerified =>
      'Le catalogue n’a pas passé la vérification ; rien ne peut donc être installé.';

  @override
  String get powertrainCatalogRevalidate => 'Vérifier à nouveau';

  @override
  String get powertrainCatalogScopeNote =>
      'Le catalogue est vaste, mais « nous avons trouvé des données » ne signifie pas « votre voiture est prise en charge ». Les entrées réservées à la recherche ne contiennent jamais de commande. Les entrées expérimentales Mode 22 peuvent être installées et interrogées périodiquement, mais chaque valeur est marquée comme non vérifiée ; les entrées expérimentales Mode 21 sont lues une seule fois par confirmation.';

  @override
  String get powertrainCatalogSearchHint =>
      'Rechercher une marque, un modèle, une variante ou un marché…';

  @override
  String get powertrainCatalogTitle =>
      'Catalogue de batteries du groupe motopropulseur';

  @override
  String get powertrainChooseCommandNote =>
      'Une commande par tentative : aucun balayage, aucun traitement par lot, aucune nouvelle tentative automatique.';

  @override
  String get powertrainChooseCommandTitle =>
      'Choisir une requête en lecture seule épinglée';

  @override
  String get powertrainClose => 'Fermer';

  @override
  String get powertrainConfirmAccept => 'C’est ce véhicule';

  @override
  String get powertrainConfirmBody =>
      'Les signaux du profil installé ne sont lus qu’après confirmation que ce véhicule est bien de ce modèle. La confirmation ne vaut que pour cette connexion.';

  @override
  String get powertrainConfirmButton => 'Confirmer le véhicule';

  @override
  String get powertrainConfirmDialogBody =>
      'Après confirmation, les requêtes de batterie en lecture seule de ce profil sont interrogées périodiquement pour le reste de cette connexion. Un mauvais profil peut produire des nombres qui paraissent plausibles mais sont faux ; annulez en cas de doute.';

  @override
  String get powertrainConfirmDialogTitle => 'Confirmer le véhicule connecté';

  @override
  String get powertrainConfirmTitle =>
      'Signaux de batterie du véhicule en attente de confirmation';

  @override
  String get powertrainConnectFirst =>
      'Connectez-vous d’abord ; l’autorisation expérimentale n’est jamais conservée entre les connexions.';

  @override
  String get powertrainConnectionChanged =>
      'La connexion a changé : confirmez à nouveau le véhicule pour cette nouvelle connexion.';

  @override
  String get powertrainEnableLabInSettings =>
      'Activez d’abord le laboratoire expérimental de batterie dans Paramètres.';

  @override
  String get powertrainEvidencePhysicalVehicle => 'Véhicule du projet';

  @override
  String get powertrainEvidenceSourceBacked => 'Données sources';

  @override
  String get powertrainEvidenceSyntheticRig => 'Banc synthétique';

  @override
  String get powertrainExperimentalDataDisclosure =>
      'Il s’agit d’une lecture candidate signalée par les auteurs de la source, et non d’une garantie du constructeur ou de sécurité pour tous les modèles ; ELM327 ne fait que transmettre la commande. La commande brute et la réponse restent dans le journal de diagnostic local et ne sont pas envoyées automatiquement par cette fonction ; les valeurs décodées ne sont jamais installées comme PID ni ajoutées à un cadran. Annuler ne modifie pas les fonctions OBD ordinaires.';

  @override
  String get powertrainExperimentalDialogTitle =>
      'Confirmation d’une lecture expérimentale unique en lecture seule';

  @override
  String get powertrainExperimentalIdentityAck =>
      'J’ai vérifié le marché, le modèle et l’année-modèle connus de la source, et j’accepte les champs non confirmés';

  @override
  String get powertrainExperimentalParkedAck =>
      'Le véhicule est garé en sécurité ; je comprends que la lecture est unique et que le nombre peut ne pas s’appliquer';

  @override
  String powertrainExperimentalWireLine(String responder, int bytes) {
    return 'Accepte uniquement RX $responder, longueur de charge utile : $bytes octets';
  }

  @override
  String get powertrainFieldListSeparator => ', ';

  @override
  String get powertrainFieldMarket => 'Marché';

  @override
  String get powertrainFieldModel => 'Modèle';

  @override
  String get powertrainFieldModelYear => 'Année-modèle';

  @override
  String get powertrainFieldVariant => 'Variante';

  @override
  String get powertrainFilterAll => 'Tous';

  @override
  String get powertrainIdentityEvidenceExact => 'preuve directe';

  @override
  String get powertrainIdentityEvidenceNone => 'aucun';

  @override
  String get powertrainIdentityEvidenceSourcePartial => 'preuve partielle';

  @override
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed) {
    return 'Preuves d’identité de la source : $fields\nChamps non confirmés : $unconfirmed';
  }

  @override
  String get powertrainIdentityEvidenceUnknown => 'inconnu';

  @override
  String get powertrainInstallButton => 'Installer les signaux de batterie';

  @override
  String get powertrainInstallConfirm => 'Installer';

  @override
  String get powertrainInstallDialogTitle =>
      'Installer les signaux de batterie de ce modèle';

  @override
  String get powertrainInstallDisclosureCommunity =>
      'L’installation ajoute uniquement des PID de batterie en lecture seule à la gestion des PID. Avant toute lecture, chaque connexion vous demande de confirmer sur le tableau de bord que ce véhicule est bien de ce modèle. Les données proviennent de sources communautaires et ont été corroborées indépendamment ; elles ne constituent toujours pas une garantie du constructeur.';

  @override
  String get powertrainInstallDisclosureExperimental =>
      'L’installation ajoute uniquement des PID de batterie en lecture seule à la gestion des PID. Avant toute lecture, chaque connexion vous demande de confirmer sur le tableau de bord que ce véhicule est bien de ce modèle. Ce décodage est expérimental, sans exigence de corroboration indépendante, non vérifié sur ce véhicule, et ne constitue toujours pas une garantie du constructeur.';

  @override
  String get powertrainInstallDisclosureReady =>
      'L’installation ajoute uniquement des PID de batterie en lecture seule à la gestion des PID. Avant toute lecture, chaque connexion vous demande de confirmer sur le tableau de bord que ce véhicule est bien de ce modèle. Les données sources sont plus complètes ; elles ne constituent toujours pas une garantie du constructeur.';

  @override
  String get powertrainInstallDisclosureResearchOnly =>
      'L’installation ajoute uniquement des PID de batterie en lecture seule à la gestion des PID. Avant toute lecture, chaque connexion vous demande de confirmer sur le tableau de bord que ce véhicule est bien de ce modèle. Cette entrée est réservée à la recherche et ne devrait pas être installée.';

  @override
  String get powertrainInstallCatalogShaMissing =>
      'Installation impossible : cet instantané du catalogue ne possède pas de SHA-256 vérifié ; rien de son contenu ne peut donc être considéré comme fiable.';

  @override
  String get powertrainInstallPersistFailed =>
      'Installation impossible : la liste des profils installés n’a pas pu être enregistrée. Réessayez ; rien n’a été ajouté à la gestion des PID.';

  @override
  String get powertrainInstallProfileNotInCatalog =>
      'Installation impossible : ce profil ne figure pas dans le catalogue vérifié.';

  @override
  String get powertrainInstallProfileNotInstallable =>
      'Installation impossible : ce profil n’est pas dans un état permettant de devenir des PID actifs.';

  @override
  String get powertrainInstallYearOutOfRange =>
      'Installation impossible : cette année-modèle est hors de la plage d’années documentée pour ce profil.';

  @override
  String get powertrainInstallIdentityAck =>
      'Mon véhicule correspond au marché, au modèle et à l’année-modèle ci-dessus';

  @override
  String get powertrainInstalledRemoveButton =>
      'Installé · retirer les signaux';

  @override
  String powertrainInstalledSignalsSnack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count signaux installés. Ajoutez-les au tableau de bord depuis la page PID ; chaque connexion nécessite une confirmation du véhicule.',
      one: '1 signal installé. Ajoutez-le au tableau de bord depuis la page PID ; chaque connexion nécessite une confirmation du véhicule.',
    );
    return '$_temp0';
  }

  @override
  String get powertrainNoMatchBody =>
      'Essayez un nom de marque ou de modèle, ou choisissez un autre type de groupe motopropulseur.';

  @override
  String get powertrainNoMatchTitle => 'Aucun véhicule correspondant';

  @override
  String get powertrainNotInstallableInThisRelease =>
      'Installation impossible dans cette version';

  @override
  String powertrainPrimarySource(String name, String license) {
    return 'Source principale : $name ($license)';
  }

  @override
  String get powertrainProbeChecksPassed =>
      'Les vérifications du répondant, de l’écho, de la longueur exacte, de la formule et de la plage ont réussi.';

  @override
  String get powertrainProbeConnectForOneShot =>
      'Connectez-vous pour une requête unique en lecture seule';

  @override
  String get powertrainProbeConnectToTryOnce =>
      'Connectez-vous d’abord pour essayer une lecture';

  @override
  String get powertrainProbeDidNotFinish =>
      'La requête unique ne s’est pas terminée ; aucune valeur n’a été publiée ni conservée.';

  @override
  String get powertrainProbeEnableLabFirst =>
      'Activez d’abord le laboratoire dans Paramètres';

  @override
  String get powertrainProbeInProgress => 'Lecture unique en cours…';

  @override
  String get powertrainProbeNoValuePublished =>
      'Aucune valeur n’a été publiée ; une erreur de structure ou de décodage est mise en quarantaine jusqu’à la reconnexion.';

  @override
  String get powertrainProbeOnceButton => 'Lire une seule fois';

  @override
  String get powertrainProbePassedTitle => 'Requête unique réussie';

  @override
  String get powertrainProbePickOneRead =>
      'Choisissez une commande, lisez une fois';

  @override
  String get powertrainProbeReconnectFirst =>
      'Reconnectez-vous, puis réessayez';

  @override
  String get powertrainProbeRefusedTitle => 'Requête unique refusée';

  @override
  String get powertrainProbeTryOnceFirst => 'Essayez d’abord une lecture';

  @override
  String get powertrainProfileNotVerified =>
      'Le profil ne figure pas dans le catalogue vérifié';

  @override
  String get powertrainQuarantinedPill => 'En quarantaine · reconnecter';

  @override
  String get powertrainRefusedCatalogHashInvalid =>
      'Non autorisé : le hachage d’intégrité du catalogue n’est pas valide ; rien de son contenu ne peut donc être lu.';

  @override
  String get powertrainRefusedCommandNotInProfile =>
      'Non autorisé : cette commande ne fait pas partie des commandes propres à ce profil vérifié.';

  @override
  String get powertrainRefusedLabClosed =>
      'Le laboratoire expérimental de batterie a été désactivé avant que cette lecture puisse être autorisée.';

  @override
  String get powertrainRefusedProfileFailedValidation =>
      'Non autorisé : ce profil n’a pas passé la validation du catalogue avec l’année-modèle choisie.';

  @override
  String get powertrainRefusedProfileNotInCatalog =>
      'Non autorisé : ce profil ne figure pas dans le catalogue vérifié.';

  @override
  String get powertrainRefusedProfileNotProbeable =>
      'Non autorisé : ce profil ne permet pas de lecture expérimentale unique.';

  @override
  String get powertrainRefusedQuarantinedAfterRejectedRead =>
      'En quarantaine pour cette connexion : une lecture unique précédente n’a pas passé ses vérifications structurelles. Reconnectez-vous avant de réessayer.';

  @override
  String get powertrainRefusedNotConnectedOrNotInForeground =>
      'La lecture unique n’a pas démarré : rien n’est connecté ou l’application n’était pas au premier plan.';

  @override
  String get powertrainRefusedNoLiveAuthorization =>
      'La lecture unique n’a pas démarré : aucune autorisation à usage unique n’est détenue. Aucune n’a été donnée, ou elle a expiré, est en délai d’attente ou a été mise en quarantaine.';

  @override
  String get powertrainRefusedDiscardedAtLifecycleBoundary =>
      'La connexion ou l’état de premier plan a changé pendant la lecture unique ; sa réponse a donc été écartée au lieu d’être affichée. Rien n’a échoué et rien n’a été conservé.';

  @override
  String powertrainRefusedQuarantinedAtAttemptCap(int attemptCap) {
    return 'En quarantaine pour cette connexion : la même commande a déjà été essayée $attemptCap fois. Reconnectez-vous avant de réessayer.';
  }

  @override
  String get powertrainResearchOnlyNeverQueries =>
      'Réservé à la recherche · aucune requête';

  @override
  String get powertrainRestoreStorageErrorRetry =>
      'Une erreur de stockage s’est produite lors de la restauration des installations précédentes. Elle a été reprogrammée ; réessayez.';

  @override
  String powertrainSecondarySource(String name, String license) {
    return 'Corroboration indépendante : $name ($license)';
  }

  @override
  String powertrainSignalCount(int count) {
    return 'Signaux : $count';
  }

  @override
  String powertrainSourceSha256(String hash) {
    return 'SHA-256 du fichier source : $hash…';
  }

  @override
  String get powertrainStatusCommunity => 'Communautaire · non vérifié';

  @override
  String get powertrainStatusExperimental => 'Expérimental · non vérifié';

  @override
  String get powertrainStatusExperimentalProbeOnly =>
      'Expérimental · lecture unique';

  @override
  String get powertrainStatusReady => 'Données sources plus complètes';

  @override
  String get powertrainStatusResearchOnly => 'Réservé à la recherche';

  @override
  String powertrainUninstalledSignalsSnack(String name) {
    return 'Signaux installés pour $name retirés.';
  }

  @override
  String powertrainVehicleYearFixed(int year) {
    return 'Année-modèle : $year';
  }

  @override
  String get powertrainVehicleYearLabel => 'Année-modèle';

  @override
  String get recommendedPurchaseDisclosure =>
      'Ce lien est un lien d’affiliation du mainteneur ; un achat admissible peut lui rapporter une commission. Ce n’est ni une certification de l’adaptateur ni une garantie d’achat. Le contenu de l’annonce et les révisions matérielles peuvent changer ; vérifiez le numéro de modèle complet et le numéro NCC avant l’achat. Vous êtes également libre de chercher d’autres vendeurs.';

  @override
  String get recommendedPurchaseHeading => 'Adaptateur recommandé';

  @override
  String recommendedPurchaseModelLine(String model, String approval) {
    return 'Modèle $model · NCC $approval';
  }

  @override
  String recommendedPurchaseNoAdapterYet(String store) {
    return 'Pas encore d’adaptateur ? Consultez celui recommandé sur $store';
  }

  @override
  String recommendedPurchaseOpenFailed(String store) {
    return 'Impossible d’ouvrir le lien $store';
  }

  @override
  String get recommendedPurchaseShortDisclosureAction =>
      'Fiche d’information complète dans Paramètres';

  @override
  String get recommendedPurchaseShortDisclosureLead =>
      'Ceci est un lien d’affiliation, pas une certification de l’adaptateur.';

  @override
  String get recommendedPurchaseStoreShopee => 'Shopee';

  @override
  String recommendedPurchaseViewOnStore(String store) {
    return 'Voir sur $store';
  }

  @override
  String get semanticsFieldSeparator => ', ';

  @override
  String get settingsAdapterConcernsFooter =>
      'Ces points révèlent des incohérences dans ce que l’adaptateur dit de lui-même, et non une preuve qu’il a mal lu le véhicule. Seule une seconde mesure indépendante permet de confirmer une valeur (voir le guide pratique).';

  @override
  String get settingsAdapterNoContradictions =>
      'Aucune contradiction trouvée dans la description que l’adaptateur donne de lui-même. Cela signifie seulement qu’il est cohérent : ce n’est ni une preuve que la puce est authentique, ni une preuve que les nombres qu’il rapporte sont corrects. Sur un clone, la chaîne de version est simplement un texte choisi par quelqu’un.';

  @override
  String get settingsAdapterNoVersion => '(aucune version signalée)';

  @override
  String get settingsAdapterSelfReportTitle =>
      'Ce que l’adaptateur dit de lui-même';

  @override
  String get settingsBatteryLabDialogBody =>
      'Il s’agit de sources candidates issues de rétro-ingénierie, et non de documentation du constructeur ni d’une prise en charge de votre véhicule par Telltale. Même une requête en lecture seule peut réveiller un calculateur ; un nombre décodé peut paraître plausible sans pour autant s’appliquer.';

  @override
  String get settingsBatteryLabDialogTitle =>
      'Activer le laboratoire de batterie';

  @override
  String get settingsBatteryLabDisableNotSaved =>
      'Le laboratoire de batterie est désactivé pour cette exécution, mais le réglage n’a pas pu être enregistré ; il pourrait réapparaître au prochain lancement et chaque requête nécessite toujours sa propre confirmation.';

  @override
  String get settingsBatteryLabEnableNotSaved =>
      'Impossible d’enregistrer le réglage du laboratoire de batterie ; il reste désactivé.';

  @override
  String get settingsBatteryLabEvidenceAck =>
      'Je comprends que les données sources et les tests synthétiques ne prouvent pas que cela s’applique à mon véhicule';

  @override
  String get settingsBatteryLabSwitchSubtitle =>
      'Affiche uniquement les requêtes uniques en lecture seule dont les sources sont complètes et liées à leur hachage. N’installe pas de PID, n’interroge pas périodiquement, n’ajoute pas de cadrans et ne considère pas les données de recherche comme une prise en charge.';

  @override
  String get settingsBatteryLabSwitchTitle =>
      'Laboratoire de batterie (expérimental)';

  @override
  String get settingsBatteryLabUnlockReadOnly =>
      'Déverrouiller uniquement les requêtes uniques en lecture seule';

  @override
  String get settingsBatteryLabWireAck =>
      'Je comprends que cela déverrouille uniquement des requêtes uniques aux adresses Mode 21/22 fixes du catalogue : ni balayage, ni session de diagnostic, ni accès de sécurité, ni écriture, ni commande';

  @override
  String get settingsCancel => 'Annuler';

  @override
  String get settingsCatalogChoose => 'Choisir dans le catalogue officiel';

  @override
  String get settingsCatalogCorrupt =>
      'Le catalogue officiel hors ligne est endommagé ou n’a pas pu être chargé ; rien n’a été appliqué.';

  @override
  String get settingsCatalogNothingApplicable =>
      'Cette configuration officielle ne contient aucun champ applicable en sécurité aux formules actuelles ; le profil existant reste inchangé.';

  @override
  String get settingsCatalogScope =>
      'Catalogues officiels : EPA des États-Unis, MOEA de Taïwan, NRCan du Canada. Chaque instantané concerne uniquement ce marché, pas toutes les marques ni toutes les années du monde.';

  @override
  String get settingsCatalogVerifying =>
      'Vérification du catalogue hors ligne…';

  @override
  String get settingsCatalogChooseMarket =>
      'Choisir le catalogue officiel à parcourir';

  @override
  String get settingsCatalogMarketTw =>
      'Taïwan (administration de l’énergie du MOEA)';

  @override
  String get settingsCatalogMarketUs => 'États-Unis (EPA)';

  @override
  String get settingsTwCertificationYear => 'Année de certification';

  @override
  String get settingsTwMake => 'Marque à Taïwan';

  @override
  String settingsTwPickerScope(int firstYear, int lastYear) {
    return 'Lignes de certification du marché taïwanais pour $firstYear–$lastYear uniquement. L’année est l’année civile de certification de l’administration de l’énergie, pas une année-modèle américaine. Un nom de marque/modèle identique ne constitue pas une configuration EPA.';
  }

  @override
  String get settingsTwPickerTitle =>
      'Catalogue officiel des véhicules de Taïwan';

  @override
  String get settingsTwReferenceMassNotCurb =>
      'La masse de référence du véhicule n’est pas la masse à vide (curb mass) et n’est pas appliquée.';

  @override
  String settingsTwWillApplyOnly(String fields) {
    return 'Seuls ces champs seront appliqués : $fields. La masse de référence, VE, Cd, la surface frontale, Crr et le rendement de transmission restent non résolus.';
  }

  @override
  String get settingsClose => 'Fermer';

  @override
  String get settingsConnectionSection => 'Connexion';

  @override
  String get settingsDiagnosticsSection => 'Journal de diagnostic';

  @override
  String get settingsDisconnect => 'Déconnecter';

  @override
  String settingsDrivetrainEfficiency(int percent) {
    return 'Rendement de transmission $percent %';
  }

  @override
  String settingsEpaApplyFields(int count) {
    return 'Appliquer $count champs officiels';
  }

  @override
  String get settingsEpaChooseExact => 'Choisir une configuration exacte';

  @override
  String get settingsEpaCloseNoFields => 'Fermer (aucun champ à appliquer)';

  @override
  String settingsEpaConfiguration(int epaId) {
    return 'Configuration EPA $epaId';
  }

  @override
  String settingsEpaCylinders(int count) {
    return '$count cyl';
  }

  @override
  String get settingsEpaDriveUnknown => 'Transmission inconnue';

  @override
  String get settingsEpaFuelUnknown => 'Carburant inconnu';

  @override
  String get settingsEpaMake => 'Marque EPA';

  @override
  String get settingsEpaModel => 'Modèle';

  @override
  String get settingsEpaNoConfigurations =>
      'Aucune configuration disponible pour ce modèle';

  @override
  String get settingsEpaNoSafeFields =>
      'Cette configuration ne contient aucun champ applicable en sécurité aux formules actuelles ; rien n’est deviné.';

  @override
  String get settingsEpaPickInOrder =>
      'Choisissez dans l’ordre l’année-modèle, la marque et le modèle';

  @override
  String settingsEpaPickerScope(int firstYear, int lastYear) {
    return 'Configurations de l’instantané du marché américain pour $firstYear–$lastYear uniquement. Les modèles de même nom nécessitent aussi l’année-modèle, la transmission, le carburant et l’identifiant EPA pour les distinguer.';
  }

  @override
  String get settingsEpaPickerTitle =>
      'Catalogue officiel des véhicules EPA des États-Unis';

  @override
  String settingsEpaWillApplyOnly(String fields) {
    return 'Seuls ces champs seront appliqués : $fields. La masse, VE, Cd, la surface frontale, Crr et le rendement de transmission restent non résolus.';
  }

  @override
  String get settingsEpaYear => 'Année-modèle';

  @override
  String get settingsExperimentalSection => 'Expérimental';

  @override
  String get settingsFieldDisplacement => 'Cylindrée';

  @override
  String get settingsFieldDragCoefficient => 'Coefficient de traînée Cd';

  @override
  String get settingsFieldDrivetrain => 'Type de transmission';

  @override
  String get settingsFieldFrontalArea => 'Surface frontale';

  @override
  String get settingsFieldFuel => 'Carburant';

  @override
  String get settingsFieldMass => 'Masse';

  @override
  String get settingsFieldMassWithDriver => 'Masse (avec conducteur)';

  @override
  String get settingsFieldRollingResistance => 'Résistance au roulement Crr';

  @override
  String get settingsFieldVolumetricEfficiency => 'Rendement volumétrique VE';

  @override
  String settingsFuelAfrAndDensity(double afr, int density) {
    return 'Rapport air-carburant $afr · densité $density g/L';
  }

  @override
  String get settingsFuelAndDrivetrainSection =>
      'Carburant et type de transmission';

  @override
  String get settingsFuelTypeLabel => 'Type de carburant';

  @override
  String get settingsGaugeSkinBody =>
      'Plus qu’un changement de couleur : chaque habillage possède un fond de cadran, une aiguille et un mouvement différents. Tous fonctionnent sur fond sombre ou clair.';

  @override
  String get settingsGaugeSkinTitle => 'Habillage des cadrans';

  @override
  String get settingsGoToConnect => 'Aller à Connexion';

  @override
  String get settingsHeadline => 'Paramètres';

  @override
  String get settingsLicenseLegalese =>
      'Les sources, transformations et conditions de réutilisation des données de batterie du groupe motopropulseur sont incluses dans cette application.';

  @override
  String get settingsListSeparator => ', ';

  @override
  String get settingsManualCommandBody =>
      'Envoyez une commande directement à l’adaptateur, par exemple ATI, ATDPN, 0100. Elle rejoint la même file que l’interrogation périodique normale, sans passer devant.';

  @override
  String get settingsManualCommandFieldLabel => 'Commande';

  @override
  String get settingsManualCommandNoContent => '(contenu de réponse vide)';

  @override
  String get settingsManualCommandSend => 'Envoyer';

  @override
  String get settingsManualCommandTitle => 'Commande manuelle';

  @override
  String get settingsNotConnected => 'Non connecté';

  @override
  String get settingsOpenSourceLicenses => 'Licences open source et données';

  @override
  String get settingsProfileConfirmAfterConnect =>
      'Connectez-vous pour confirmer ce véhicule';

  @override
  String get settingsProfileConfirmButton =>
      'Confirmer ce véhicule pour cette connexion';

  @override
  String get settingsProfileConfirmedButton => 'Confirmé pour cette connexion';

  @override
  String get settingsProfileConfirmedDetail =>
      'Le profil est confirmé pour cette connexion. Toute modification d’une valeur ou reconnexion impose une nouvelle confirmation.';

  @override
  String get settingsProfileEstimatesIntro =>
      'La puissance, le couple et la consommation sont estimés à partir de ces paramètres ; plus ils sont proches du véhicule réel, plus les estimations sont pertinentes.';

  @override
  String get settingsProfileNameProvesNothing =>
      'Le nom d’une marque ou un VIN ne suffit pas à établir la masse, la traînée, VE ou le rendement de transmission.';

  @override
  String get settingsProfileUnconfirmedConnectedDetail =>
      'Non confirmé pour cette connexion. Les mesures OBD restent affichées, mais pas les valeurs estimées à partir de la masse, de VE et de la traînée.';

  @override
  String get settingsProfileUnconfirmedDisconnectedDetail =>
      'Connectez-vous à ce véhicule avant de confirmer. La confirmation expire à chaque reconnexion ; le profil d’un véhicule n’est donc jamais appliqué au suivant.';

  @override
  String get settingsProvenanceNoneExact =>
      'Aucun champ n’a été résolu exactement pour ce véhicule ; les valeurs génériques, saisies manuellement et issues de sources anciennes doivent encore être confirmées.';

  @override
  String settingsProvenanceOnlyExact(String fields) {
    return 'Champs ayant une source officielle exacte : $fields. Tous les autres champs doivent encore être confirmés un par un.';
  }

  @override
  String settingsProvenanceOrigins(
    int official,
    int user,
    int generic,
    int scientific,
    int total,
  ) {
    return 'Provenance : officielle ou constructeur $official / $total champs · saisie utilisateur $user / $total · valeur générique par défaut $generic / $total · modèle scientifique $scientific / $total';
  }

  @override
  String settingsProvenancePublishers(String publishers) {
    return 'Sources : $publishers';
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
    return 'Résolution : source officielle exacte $exact / $total champs · confirmé pour cette session $sessionConfirmed / $total · non résolu $unresolved / $total · ambigu $ambiguous / $total · contradictoire $conflict / $total';
  }

  @override
  String get settingsStandardsFooter =>
      'L’implémentation OBD2 de cette application suit des normes publiques, notamment SAE J1979 et la fiche technique ELM327 ; chaque formule et commande AT affectant le matériel fait l’objet d’une vérification croisée dont les résultats figurent dans docs/protocol-deviations.zh-TW.md. Cette application n’est affiliée ni à Torque ni à Torque Pro.';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeSystem => 'Suivre le système';

  @override
  String get settingsVehicleProfileSection => 'Profil du véhicule';

  @override
  String get settingsVinConflict => 'Conflit de VIN';

  @override
  String get settingsVinConflictDetail =>
      'Les calculateurs ont signalé des VIN différents ; l’identité du véhicule ne peut donc pas être confirmée et tous les candidats ont été écartés.';

  @override
  String get settingsVinNotRead => 'VIN pas encore lu';

  @override
  String get settingsVinNotReadConnectedDetail =>
      'Le VIN Mode 09 peut maintenant être lu sur le véhicule ; l’identité n’est conservée que pour cette connexion. Le journal de diagnostic brut peut toutefois encore contenir le VIN.';

  @override
  String get settingsVinNotReadDisconnectedDetail =>
      'Une fois connecté, le VIN que le véhicule déclare à son propre sujet peut être lu ; l’identité ne passe pas à la connexion suivante. Le journal de diagnostic brut peut toutefois encore contenir le VIN.';

  @override
  String get settingsVinRead => 'Lire le VIN';

  @override
  String get settingsVinReading => 'Lecture…';

  @override
  String get settingsVinReportedDetail =>
      'Le VIN est ce que le véhicule déclare à son propre sujet ; il ne vérifie pas les caractéristiques du modèle. L’identité ne passe pas d’une connexion à l’autre ; le journal de diagnostic peut toutefois encore contenir le VIN.';

  @override
  String get settingsVinSimulatorReported => 'VIN déclaré par le simulateur';

  @override
  String get settingsVinUnavailable => 'VIN indisponible';

  @override
  String get settingsVinUnavailableDetail =>
      'Le véhicule peut ne pas en fournir, la réponse peut avoir été incomplète ou le VIN peut ne pas avoir été lu lors de cette connexion ; rien n’est deviné et aucun caractère n’est complété.';

  @override
  String get settingsVinVehicleReported => 'VIN déclaré par le véhicule';

  @override
  String get startupCannotComplete =>
      'Impossible de terminer les vérifications de démarrage';

  @override
  String get startupChecking =>
      'Vérification du cache de partage local et des enregistrements de télémétrie';

  @override
  String get startupRestartHint =>
      'L’état du cache de partage local ou des enregistrements de télémétrie n’a pas pu être confirmé. Quittez complètement Telltale puis rouvrez-le pour éviter d’écraser, de supprimer ou de partager le mauvais fichier.';

  @override
  String get startupRestartRequired =>
      'Redémarrage nécessaire pour continuer en sécurité';

  @override
  String get startupRetry => 'Réessayer';

  @override
  String get startupRetryHint =>
      'Gardez Telltale au premier plan, puis réessayez une fois les autres opérations sur fichiers terminées. L’enregistrement, la relecture, l’export et la suppression restent bloqués jusqu’à la fin du démarrage.';

  @override
  String get telemetryArtifactRestartRequired =>
      'L’état des opérations sur les fichiers locaux ne peut pas être confirmé. Quittez complètement Telltale puis rouvrez-le avant de continuer';

  @override
  String get telemetryBlockedByRecorder =>
      'Arrêtez puis sauvegardez d’abord l’enregistrement';

  @override
  String get telemetryCancel => 'Annuler';

  @override
  String get telemetryDamagedCollision =>
      'Un fichier terminé et un fichier inachevé partagent cet identifiant ; aucun des deux n’a été choisi';

  @override
  String get telemetryDamagedCorrupt =>
      'L’enregistrement est endommagé et ne peut pas être lu en sécurité';

  @override
  String telemetryDamagedFileTime(String time) {
    return 'Date du fichier $time';
  }

  @override
  String get telemetryDelete => 'Supprimer';

  @override
  String telemetryDeleteDamagedBody(String id, String time) {
    return 'Cette action supprime $id (date du fichier : $time). Elle est irréversible.';
  }

  @override
  String get telemetryDeleteDamagedTitle =>
      'Supprimer cet enregistrement endommagé ?';

  @override
  String get telemetryDeleteDamagedTooltip =>
      'Supprimer l’enregistrement endommagé';

  @override
  String telemetryDeleteFailed(String reason) {
    return 'La suppression ne s’est pas terminée : $reason';
  }

  @override
  String get telemetryDeleteNeedsConfirmation =>
      'Confirmez d’abord cette suppression';

  @override
  String telemetryDeleteSessionBody(String time) {
    return 'Cette action supprime l’enregistrement de $time. Elle est irréversible.';
  }

  @override
  String get telemetryDeleteSessionTitle =>
      'Supprimer cet enregistrement local ?';

  @override
  String get telemetryDemoData => 'Données du simulateur intégré';

  @override
  String get telemetryDismissNotice => 'Fermer';

  @override
  String get telemetryEndedByBackground =>
      'Arrêté au passage de Telltale en arrière-plan';

  @override
  String get telemetryEndedByConfigurationChanged =>
      'La sélection des PID a changé';

  @override
  String get telemetryEndedByDisconnect => 'Arrêté à la perte de connexion';

  @override
  String telemetryEndedByDurationLimit(int minutes) {
    return 'Limite de $minutes minutes atteinte';
  }

  @override
  String get telemetryEndedByLibrarySizeLimit =>
      'Le stockage local des enregistrements est plein';

  @override
  String get telemetryEndedByRecoveredAfterInterruption =>
      'Récupéré après la dernière interruption';

  @override
  String get telemetryEndedBySessionReplacement =>
      'La session de connexion a été remplacée';

  @override
  String get telemetryEndedBySessionSizeLimit =>
      'Cet enregistrement a atteint sa limite de taille';

  @override
  String get telemetryEndedByStorageBackpressure =>
      'Le stockage n’a pas pu suivre';

  @override
  String get telemetryEndedByStorageFailure => 'Échec de l’enregistrement';

  @override
  String get telemetryEndedByUser => 'Arrêté par vous';

  @override
  String get telemetryExport => 'Exporter';

  @override
  String get telemetryExportCsv => 'Exporter en CSV';

  @override
  String telemetryExportFailed(String reason) {
    return 'L’export ne s’est pas terminé : $reason';
  }

  @override
  String get telemetryExportJson => 'Exporter en JSON';

  @override
  String get telemetryExportSheetTitle => 'Exporter un enregistrement local';

  @override
  String telemetryGapCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lacunes',
      one: '1 lacune',
    );
    return '$_temp0';
  }

  @override
  String telemetryHistoryEntrySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groupes enregistrés · relecture et export hors ligne',
      one: '1 groupe enregistré · relecture et export hors ligne',
    );
    return '$_temp0';
  }

  @override
  String telemetryLibraryBytes(String used, int limit) {
    return '$used/$limit MiB';
  }

  @override
  String telemetryLibraryGroupCount(int groups, int limit) {
    return '$groups/$limit groupes';
  }

  @override
  String telemetryLibraryOmitted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autres groupes non affichés',
      one: '1 autre groupe non affiché',
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
    return 'Stockage local : $groups groupes sur $groupLimit, $used MiB sur $byteLimit';
  }

  @override
  String get telemetryNotConnected => 'Non connecté';

  @override
  String get telemetryOfflineSampledReplay =>
      'Relecture hors ligne échantillonnée';

  @override
  String get telemetryOpenHistory => 'Ouvrir les enregistrements locaux';

  @override
  String get telemetryPause => 'Pause';

  @override
  String get telemetryPendingOwnerRecovery =>
      'Ce processus détient encore l’opération. Si la situation persiste, quittez complètement Telltale puis rouvrez-le';

  @override
  String telemetryPhraseJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetryPlay => 'Lire';

  @override
  String telemetryRecorderDisclosure(int laneLimit, int activeCount) {
    return 'Enregistre uniquement les signaux OBD que vous avez activés : aucune donnée de localisation, de VIN ou de compte. Les tendances affichent au maximum $laneLimit signaux ; un enregistrement conserve les $activeCount signaux activés et ajoute la puissance et le débit de carburant estimés, qui reposent sur les hypothèses du véhicule.';
  }

  @override
  String get telemetryRecorderPhaseAwaitingValues =>
      'Enregistrement en cours · aucune valeur pour l’instant';

  @override
  String get telemetryRecorderPhaseCompleted => 'Enregistrement sauvegardé';

  @override
  String get telemetryRecorderPhaseFailed =>
      'Échec de la sauvegarde de l’enregistrement';

  @override
  String get telemetryRecorderPhaseFinalizing =>
      'Sauvegarde de l’enregistrement';

  @override
  String get telemetryRecorderPhaseIdle =>
      'Enregistrement local au premier plan';

  @override
  String get telemetryRecorderPhasePreparing =>
      'Préparation de l’enregistrement';

  @override
  String get telemetryRecorderPhaseRecording => 'Enregistrement';

  @override
  String telemetryRecorderStripRecording(String duration) {
    return 'Enregistrement $duration';
  }

  @override
  String telemetryRecoveryCleaned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fichiers inachevés sans valeur valide ont été supprimés',
      one: '1 fichier inachevé sans valeur valide a été supprimé',
    );
    return '$_temp0';
  }

  @override
  String telemetryRecoveryDamaged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count fichiers endommagés ou en conflit ont été laissés inchangés',
      one: '1 fichier endommagé ou en conflit a été laissé inchangé',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryDamagedNote =>
      'Le contenu endommagé n’est jamais utilisé pour la relecture ou l’export et ne peut être supprimé que manuellement, lorsque les conditions de sécurité le permettent.';

  @override
  String telemetryRecoveryInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrements interrompus ont été clôturés en sécurité',
      one: '1 enregistrement interrompu a été clôturé en sécurité',
    );
    return '$_temp0';
  }

  @override
  String get telemetryRecoveryTitle =>
      'Vérification des enregistrements au démarrage terminée';

  @override
  String get telemetryReload => 'Recharger';

  @override
  String telemetryReplayBreakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count interruptions',
      one: '1 interruption',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayLoadFailed =>
      'Impossible de charger l’enregistrement';

  @override
  String telemetryReplayPositionSemantics(int percent) {
    return 'Position de relecture $percent%';
  }

  @override
  String telemetryReplaySampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points échantillonnés',
      one: '1 point échantillonné',
    );
    return '$_temp0';
  }

  @override
  String get telemetryReplayTitle => 'Lecture de l’enregistrement';

  @override
  String get telemetryReplayUnreadable =>
      'L’enregistrement est endommagé ou illisible';

  @override
  String get telemetryRestartToRepairSave =>
      'La sauvegarde ne s’est pas terminée ; redémarrez Telltale pour réparer les enregistrements';

  @override
  String get telemetryRestartToRepairStartup =>
      'Le nettoyage au démarrage ne s’est pas terminé ; redémarrez Telltale pour réparer les enregistrements';

  @override
  String get telemetryReturnToTrends => 'Retour aux tendances';

  @override
  String get telemetryRigData => 'Données du banc d’essai';

  @override
  String telemetrySentenceJoin(String first, String second) {
    return '$first. $second';
  }

  @override
  String get telemetrySessionsDamaged => 'Fichiers d’enregistrement endommagés';

  @override
  String get telemetrySessionsEmpty =>
      'Aucun enregistrement local pour l’instant\nConnectez-vous, puis lancez un enregistrement';

  @override
  String get telemetrySessionsLoadFailed => 'Chargement impossible ; réessayez';

  @override
  String get telemetrySessionsReplayable =>
      'Enregistrements que vous pouvez relire';

  @override
  String get telemetrySessionsTitle => 'Enregistrements locaux';

  @override
  String telemetrySignalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count signaux',
      one: '1 signal',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStartBusy =>
      'Un autre enregistrement ou une autre opération sur fichier n’est pas terminé';

  @override
  String get telemetryStartCannotCreateFile =>
      'Impossible de créer le fichier d’enregistrement';

  @override
  String get telemetryStartInvalidConfiguration =>
      'Cette sélection de PID ne peut pas être enregistrée en sécurité ; vérifiez les définitions';

  @override
  String get telemetryStartInvalidatedBackground =>
      'Telltale est passé en arrière-plan ; aucun enregistrement n’a démarré';

  @override
  String get telemetryStartInvalidatedDisconnect =>
      'La connexion a été perdue ; aucun enregistrement n’a démarré';

  @override
  String get telemetryStartInvalidatedSessionReplacement =>
      'La session de connexion a été remplacée ; aucun enregistrement n’a démarré';

  @override
  String get telemetryStartLibraryByteLimit =>
      'Espace local insuffisant pour un enregistrement ; exportez-en ou supprimez-en d’abord';

  @override
  String telemetryStartLibraryGroupLimit(int limit) {
    return 'Les enregistrements locaux ont atteint la limite de $limit ; exportez-en ou supprimez-en d’abord';
  }

  @override
  String get telemetryStartMoving => 'Garez d’abord le véhicule';

  @override
  String get telemetryStartNeedsActivePid => 'Activez d’abord au moins un PID';

  @override
  String get telemetryStartNeedsConnection =>
      'Connectez-vous avant de lancer un enregistrement';

  @override
  String get telemetryStartNeedsForeground =>
      'Placez Telltale au premier plan avant de lancer un enregistrement';

  @override
  String get telemetryStartRecording => 'Enregistrement démarré';

  @override
  String get telemetryStartRecordingButton => 'Démarrer l’enregistrement';

  @override
  String get telemetryStartSpeedUnknown =>
      'Impossible de confirmer que le véhicule est arrêté ; déconnectez-vous d’abord';

  @override
  String get telemetryStartTooManyPids =>
      'L’enregistrement conserve les colonnes de puissance et de carburant estimés ; désactivez d’abord certains PID';

  @override
  String get telemetryStarting => 'Démarrage';

  @override
  String get telemetryStatusBusError => 'Erreur de bus';

  @override
  String telemetryStatusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count états',
      one: '1 état',
    );
    return '$_temp0';
  }

  @override
  String get telemetryStatusFormulaError => 'Erreur de formule';

  @override
  String get telemetryStatusHeaderMismatch =>
      'L’en-tête ne correspond pas à ce bus';

  @override
  String get telemetryStatusNoAnswer =>
      'Aucune réponse · nouvelle tentative à venir';

  @override
  String get telemetryStatusStale => 'Données périmées';

  @override
  String get telemetryStatusUnsafeServiceRefusal =>
      'Requête non limitée à la lecture seule ; rien n’a été envoyé';

  @override
  String get telemetryStatusUnsupported =>
      'Le calculateur a répondu qu’il ne prend pas cela en charge';

  @override
  String get telemetryStopAndSave => 'Arrêter et sauvegarder';

  @override
  String telemetryValueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count valeurs valides',
      one: '1 valeur valide',
    );
    return '$_temp0';
  }

  @override
  String get transcriptDelete => 'Supprimer';

  @override
  String get transcriptDeleteBusy =>
      'Une autre opération sur fichier n’est pas terminée.';

  @override
  String get transcriptDeleteFailed =>
      'Impossible de supprimer le journal de la connexion précédente.';

  @override
  String get transcriptDeleteRefusedBySafety =>
      'La vitesse ou l’état de connexion actuel ne permet pas de supprimer le journal.';

  @override
  String get transcriptExport => 'Exporter';

  @override
  String get transcriptExportButton => 'Exporter le journal';

  @override
  String get transcriptExportExplanation =>
      'Cette connexion conserve l’initialisation et le trafic brut le plus récent ; si une longue connexion omet la partie centrale, le fichier le précise. Lorsqu’une donnée ne peut pas être lue sur le véhicule, exporter le journal et le rapporter vaut bien plus qu’un simple message à l’écran.';

  @override
  String transcriptExportFailed(String error) {
    return 'Échec de l’export : $error';
  }

  @override
  String get transcriptExportWithHex => 'Avec hexadécimal';

  @override
  String get transcriptNothingToExport => 'Aucun journal à exporter.';

  @override
  String transcriptRecoveredBody(String timestamp, String size) {
    return 'Laissé à $timestamp, $size. Il a survécu à l’arrêt de Telltale par le système ou à la perte d’alimentation du téléphone.';
  }

  @override
  String get transcriptRecoveredChanged =>
      'Le journal de la connexion précédente a changé ; vérifiez-le à nouveau.';

  @override
  String get transcriptRecoveredTitle => 'Journal de la connexion précédente';

  @override
  String transcriptSizeBytes(int bytes) {
    String _temp0 = intl.Intl.pluralLogic(
      bytes,
      locale: localeName,
      other: '$bytes octets',
      one: '1 octet',
    );
    return '$_temp0';
  }

  @override
  String get trendAxisNow => 'Maintenant';

  @override
  String get trendChooseSignals => 'Choisir les signaux';

  @override
  String get trendLiveData => 'Données en direct';

  @override
  String get trendNoSignalsBody =>
      'Activez d’abord les signaux à surveiller sur la page PID.';

  @override
  String get trendNoSignalsTitle => 'Aucun signal de tendance disponible';

  @override
  String get trendNoUnits => 'Sans unité';

  @override
  String trendPickSignalsBody(int limit) {
    return 'Comparez jusqu’à $limit signaux. Cela ne modifie pas les PID interrogés périodiquement.';
  }

  @override
  String get trendPickSignalsTitle => 'Choisir les signaux de tendance';

  @override
  String trendRemoveSignal(String name) {
    return 'Retirer $name';
  }

  @override
  String get trendSelectionSaveFailed =>
      'Impossible d’enregistrer la sélection d’affichage des tendances';

  @override
  String trendSheetBody(int limit) {
    return 'Choisissez au maximum $limit signaux. Cela ne modifie que le graphique, pas l’interrogation périodique des PID ni un enregistrement en cours.';
  }

  @override
  String trendSheetDone(int selected, int limit) {
    return 'Terminé · $selected/$limit';
  }

  @override
  String get trendSignalNoLongerActive =>
      'Un de ces signaux ne figure plus dans la liste de surveillance des PID';

  @override
  String get trendSignalsHeading => 'Signaux de tendance';

  @override
  String trendTooManySelected(int limit) {
    return 'Choisissez au maximum $limit';
  }

  @override
  String trendWindowSemantics(int seconds) {
    return 'Affichage des $seconds dernières secondes';
  }

  @override
  String get wearBack => 'Retour';

  @override
  String get wearBatteryVoltageLabel => 'Batterie';

  @override
  String get wearBleAdapters => 'Adaptateurs BLE';

  @override
  String get wearCancel => 'Annuler';

  @override
  String get wearConfirmVehicle => 'Confirmer le véhicule';

  @override
  String get wearConfirmVehicleAccept => 'Oui, ce véhicule';

  @override
  String get wearConfirmVehicleBody =>
      'Après confirmation, les requêtes de batterie en lecture seule pour ce modèle sont interrogées périodiquement pendant le reste de cette connexion. Un mauvais modèle peut renvoyer un nombre plausible mais faux ; annulez en cas de doute.';

  @override
  String wearConnectFailed(String adapter) {
    return 'Connexion impossible : $adapter';
  }

  @override
  String get wearConnecting => 'Connexion…';

  @override
  String get wearDemoSimulator => 'Simulateur Demo';

  @override
  String get wearDisconnect => 'Déconnecter';

  @override
  String get wearDisconnectQuestion => 'Déconnecter ?';

  @override
  String get wearNoDevicesFound => 'Aucun appareil trouvé';

  @override
  String get wearPermissionBluetooth => 'Bluetooth';

  @override
  String get wearPermissionLocation => 'Localisation';

  @override
  String get wearScanAgain => 'Relancer';

  @override
  String get wearScanFailed => 'Échec de la recherche ; réessayez';

  @override
  String wearScanPermissionNeeded(String permission) {
    return 'La recherche nécessite l’autorisation $permission';
  }

  @override
  String wearScanPermissionPermanentlyDenied(String permission) {
    return 'L’autorisation $permission est refusée définitivement ; activez-la dans les paramètres système, puis réessayez';
  }

  @override
  String get wearScanning => 'Recherche…';

  @override
  String get telemetryRecorderNotRecording => 'Pas d’enregistrement en cours';

  @override
  String get dtcKindStored => 'Mémorisé';

  @override
  String get dtcKindPending => 'En attente';

  @override
  String get dtcKindPermanent => 'Permanent';

  @override
  String get dtcKindStoredExplanation =>
      'Défaut confirmé ; le voyant de défaut du tableau de bord est généralement allumé.';

  @override
  String get dtcKindPendingExplanation =>
      'Détecté une fois, sans avoir encore atteint le seuil de confirmation.';

  @override
  String get dtcKindPermanentExplanation =>
      'Ne peut pas être effacé avec un outil de diagnostic. L’ECU l’efface lui-même uniquement après avoir confirmé la réparation.';

  @override
  String get dtcSystemPowertrain => 'Groupe motopropulseur';

  @override
  String get dtcSystemChassis => 'Châssis';

  @override
  String get dtcSystemBody => 'Carrosserie';

  @override
  String get dtcSystemNetwork => 'Réseau';

  @override
  String get dtcSubsystemFuelAirMeteringAndAuxiliaryEmissions =>
      'Dosage du carburant et de l’air, et dispositifs antipollution auxiliaires';

  @override
  String get dtcSubsystemFuelAirMetering => 'Dosage du carburant et de l’air';

  @override
  String get dtcSubsystemFuelAirMeteringInjectorCircuit =>
      'Dosage du carburant et de l’air (circuit d’injecteur)';

  @override
  String get dtcSubsystemIgnitionOrMisfire => 'Système d’allumage ou ratés';

  @override
  String get dtcSubsystemAuxiliaryEmissionControls =>
      'Dispositifs antipollution auxiliaires';

  @override
  String get dtcSubsystemSpeedAndIdleControl =>
      'Régulation de vitesse du véhicule et du ralenti';

  @override
  String get dtcSubsystemComputerOutputCircuit =>
      'Circuit de sortie du calculateur';

  @override
  String get dtcSubsystemTransmission => 'Transmission';

  @override
  String get dtcSubsystemControlModuleSignals =>
      'Modules de commande, signaux d’entrée et de sortie';

  @override
  String get dtcDescriptionB0001 =>
      'Défaut de commande de déploiement de l’airbag conducteur';

  @override
  String get dtcDescriptionP0011 =>
      'Position d’arbre à cames A : avance de distribution excessive ou performance du système (banc 1)';

  @override
  String get dtcDescriptionP0014 =>
      'Position d’arbre à cames B : avance de distribution excessive ou performance du système (banc 1)';

  @override
  String get dtcDescriptionP0016 =>
      'Corrélation de position vilebrequin–arbre à cames (banc 1, capteur A)';

  @override
  String get dtcDescriptionP0087 =>
      'Pression de rampe ou de circuit de carburant trop basse';

  @override
  String get dtcDescriptionP0088 =>
      'Pression de rampe ou de circuit de carburant trop élevée';

  @override
  String get dtcDescriptionP0100 =>
      'Défaut du circuit du débitmètre d’air massique (MAF)';

  @override
  String get dtcDescriptionP0101 =>
      'Problème de plage ou de performance du débitmètre d’air massique';

  @override
  String get dtcDescriptionP0102 =>
      'Signal d’entrée bas du circuit du débitmètre d’air massique';

  @override
  String get dtcDescriptionP0103 =>
      'Signal d’entrée haut du circuit du débitmètre d’air massique';

  @override
  String get dtcDescriptionP0105 =>
      'Défaut du circuit du capteur de pression absolue du collecteur ou de pression barométrique';

  @override
  String get dtcDescriptionP0106 =>
      'Problème de plage ou de performance du capteur de pression absolue du collecteur';

  @override
  String get dtcDescriptionP0107 =>
      'Signal d’entrée bas du circuit du capteur de pression absolue du collecteur';

  @override
  String get dtcDescriptionP0108 =>
      'Signal d’entrée haut du circuit du capteur de pression absolue du collecteur';

  @override
  String get dtcDescriptionP0110 =>
      'Défaut du circuit du capteur de température d’air d’admission';

  @override
  String get dtcDescriptionP0111 =>
      'Problème de plage ou de performance du capteur de température d’air d’admission';

  @override
  String get dtcDescriptionP0112 =>
      'Entrée basse du circuit du capteur de température de l’air d’admission';

  @override
  String get dtcDescriptionP0113 =>
      'Entrée haute du circuit du capteur de température de l’air d’admission';

  @override
  String get dtcDescriptionP0115 =>
      'Dysfonctionnement du circuit du capteur de température du liquide de refroidissement moteur';

  @override
  String get dtcDescriptionP0116 =>
      'Problème de plage ou de performance du capteur de température du liquide de refroidissement moteur';

  @override
  String get dtcDescriptionP0117 =>
      'Entrée basse du circuit du capteur de température du liquide de refroidissement moteur';

  @override
  String get dtcDescriptionP0118 =>
      'Entrée haute du circuit du capteur de température du liquide de refroidissement moteur';

  @override
  String get dtcDescriptionP0120 =>
      'Dysfonctionnement du circuit du capteur de position du papillon';

  @override
  String get dtcDescriptionP0121 =>
      'Problème de plage ou de performance du capteur de position du papillon';

  @override
  String get dtcDescriptionP0122 =>
      'Entrée basse du circuit du capteur de position du papillon';

  @override
  String get dtcDescriptionP0123 =>
      'Entrée haute du circuit du capteur de position du papillon';

  @override
  String get dtcDescriptionP0125 =>
      'Température du liquide de refroidissement insuffisante pour le contrôle du carburant en boucle fermée';

  @override
  String get dtcDescriptionP0128 =>
      'Température du liquide de refroidissement inférieure à la température de régulation du thermostat';

  @override
  String get dtcDescriptionP0130 =>
      'Dysfonctionnement du circuit de la sonde à oxygène (banc 1, capteur 1)';

  @override
  String get dtcDescriptionP0131 =>
      'Tension basse du circuit de la sonde à oxygène (banc 1, capteur 1)';

  @override
  String get dtcDescriptionP0132 =>
      'Tension haute du circuit de la sonde à oxygène (banc 1, capteur 1)';

  @override
  String get dtcDescriptionP0133 =>
      'Réponse lente du circuit de la sonde à oxygène (banc 1, capteur 1)';

  @override
  String get dtcDescriptionP0134 =>
      'Aucune activité détectée sur le circuit de la sonde à oxygène (banc 1, capteur 1)';

  @override
  String get dtcDescriptionP0135 =>
      'Dysfonctionnement du circuit de chauffage de la sonde à oxygène (banc 1, capteur 1)';

  @override
  String get dtcDescriptionP0136 =>
      'Dysfonctionnement du circuit de la sonde à oxygène (banc 1, capteur 2)';

  @override
  String get dtcDescriptionP0137 =>
      'Tension basse du circuit de la sonde à oxygène (banc 1, capteur 2)';

  @override
  String get dtcDescriptionP0138 =>
      'Tension haute du circuit de la sonde à oxygène (banc 1, capteur 2)';

  @override
  String get dtcDescriptionP0140 =>
      'Aucune activité détectée sur le circuit de la sonde à oxygène (banc 1, capteur 2)';

  @override
  String get dtcDescriptionP0141 =>
      'Dysfonctionnement du circuit de chauffage de la sonde à oxygène (banc 1, capteur 2)';

  @override
  String get dtcDescriptionP0150 =>
      'Dysfonctionnement du circuit de la sonde à oxygène (banc 2, capteur 1)';

  @override
  String get dtcDescriptionP0155 =>
      'Dysfonctionnement du circuit de chauffage de la sonde à oxygène (banc 2, capteur 1)';

  @override
  String get dtcDescriptionP0156 =>
      'Dysfonctionnement du circuit de la sonde à oxygène (banc 2, capteur 2)';

  @override
  String get dtcDescriptionP0161 =>
      'Dysfonctionnement du circuit de chauffage de la sonde à oxygène (banc 2, capteur 2)';

  @override
  String get dtcDescriptionP0170 =>
      'Dysfonctionnement de la correction de carburant (banc 1)';

  @override
  String get dtcDescriptionP0171 => 'Mélange trop pauvre (banc 1)';

  @override
  String get dtcDescriptionP0172 => 'Mélange trop riche (banc 1)';

  @override
  String get dtcDescriptionP0173 =>
      'Dysfonctionnement de la correction de carburant (banc 2)';

  @override
  String get dtcDescriptionP0174 => 'Mélange trop pauvre (banc 2)';

  @override
  String get dtcDescriptionP0175 => 'Mélange trop riche (banc 2)';

  @override
  String get dtcDescriptionP0190 =>
      'Dysfonctionnement du circuit du capteur de pression de la rampe de carburant';

  @override
  String get dtcDescriptionP0201 =>
      'Dysfonctionnement ou circuit ouvert de l’injecteur — cylindre 1';

  @override
  String get dtcDescriptionP0202 =>
      'Dysfonctionnement ou circuit ouvert de l’injecteur — cylindre 2';

  @override
  String get dtcDescriptionP0203 =>
      'Dysfonctionnement ou circuit ouvert de l’injecteur — cylindre 3';

  @override
  String get dtcDescriptionP0204 =>
      'Dysfonctionnement ou circuit ouvert de l’injecteur — cylindre 4';

  @override
  String get dtcDescriptionP0217 => 'Surchauffe du moteur';

  @override
  String get dtcDescriptionP0221 =>
      'Problème de plage ou de performance du capteur B de position du papillon ou de la pédale';

  @override
  String get dtcDescriptionP0222 =>
      'Entrée basse du circuit du capteur B de position du papillon ou de la pédale';

  @override
  String get dtcDescriptionP0223 =>
      'Entrée haute du circuit du capteur B de position du papillon ou de la pédale';

  @override
  String get dtcDescriptionP0234 =>
      'Pression de suralimentation excessive du turbocompresseur ou du compresseur';

  @override
  String get dtcDescriptionP0299 =>
      'Pression de suralimentation insuffisante du turbocompresseur A ou du compresseur A';

  @override
  String get dtcDescriptionP0300 =>
      'Ratés d’allumage aléatoires ou sur plusieurs cylindres détectés';

  @override
  String get dtcDescriptionP0301 =>
      'Ratés d’allumage détectés sur le cylindre 1';

  @override
  String get dtcDescriptionP0302 =>
      'Ratés d’allumage détectés sur le cylindre 2';

  @override
  String get dtcDescriptionP0303 =>
      'Ratés d’allumage détectés sur le cylindre 3';

  @override
  String get dtcDescriptionP0304 =>
      'Ratés d’allumage détectés sur le cylindre 4';

  @override
  String get dtcDescriptionP0305 =>
      'Ratés d’allumage détectés sur le cylindre 5';

  @override
  String get dtcDescriptionP0306 =>
      'Ratés d’allumage détectés sur le cylindre 6';

  @override
  String get dtcDescriptionP0307 =>
      'Ratés d’allumage détectés sur le cylindre 7';

  @override
  String get dtcDescriptionP0308 =>
      'Ratés d’allumage détectés sur le cylindre 8';

  @override
  String get dtcDescriptionP0316 =>
      'Ratés d’allumage détectés immédiatement après le démarrage';

  @override
  String get dtcDescriptionP0325 =>
      'Dysfonctionnement du circuit du capteur de cliquetis (banc 1)';

  @override
  String get dtcDescriptionP0326 =>
      'Problème de plage ou de performance du capteur de cliquetis (banc 1)';

  @override
  String get dtcDescriptionP0327 =>
      'Entrée basse du circuit du capteur de cliquetis (banc 1)';

  @override
  String get dtcDescriptionP0328 =>
      'Entrée haute du circuit du capteur de cliquetis (banc 1)';

  @override
  String get dtcDescriptionP0330 =>
      'Dysfonctionnement du circuit du capteur de cliquetis (banc 2)';

  @override
  String get dtcDescriptionP0335 =>
      'Dysfonctionnement du circuit du capteur de position du vilebrequin';

  @override
  String get dtcDescriptionP0336 =>
      'Problème de plage ou de performance du capteur de position du vilebrequin';

  @override
  String get dtcDescriptionP0340 =>
      'Dysfonctionnement du circuit du capteur de position d’arbre à cames';

  @override
  String get dtcDescriptionP0341 =>
      'Problème de plage ou de performance du capteur de position d’arbre à cames';

  @override
  String get dtcDescriptionP0351 =>
      'Dysfonctionnement du circuit primaire ou secondaire de la bobine d’allumage A';

  @override
  String get dtcDescriptionP0352 =>
      'Dysfonctionnement du circuit primaire ou secondaire de la bobine d’allumage B';

  @override
  String get dtcDescriptionP0353 =>
      'Dysfonctionnement du circuit primaire ou secondaire de la bobine d’allumage C';

  @override
  String get dtcDescriptionP0354 =>
      'Dysfonctionnement du circuit primaire ou secondaire de la bobine d’allumage D';

  @override
  String get dtcDescriptionP0355 =>
      'Dysfonctionnement du circuit primaire ou secondaire de la bobine d’allumage E';

  @override
  String get dtcDescriptionP0356 =>
      'Dysfonctionnement du circuit primaire ou secondaire de la bobine d’allumage F';

  @override
  String get dtcDescriptionP0400 =>
      'Dysfonctionnement du débit de recirculation des gaz d’échappement (EGR)';

  @override
  String get dtcDescriptionP0401 =>
      'Débit insuffisant de recirculation des gaz d’échappement (EGR)';

  @override
  String get dtcDescriptionP0402 =>
      'Débit excessif de recirculation des gaz d’échappement (EGR)';

  @override
  String get dtcDescriptionP0403 =>
      'Dysfonctionnement du circuit de commande de recirculation des gaz d’échappement (EGR)';

  @override
  String get dtcDescriptionP0404 =>
      'Problème de plage ou de performance du circuit de commande de recirculation des gaz d’échappement (EGR)';

  @override
  String get dtcDescriptionP0410 =>
      'Dysfonctionnement du système d’injection d’air secondaire';

  @override
  String get dtcDescriptionP0411 =>
      'Débit incorrect détecté dans le système d’injection d’air secondaire';

  @override
  String get dtcDescriptionP0412 =>
      'Dysfonctionnement du circuit de la vanne de commutation A du système d’injection d’air secondaire';

  @override
  String get dtcDescriptionP0420 =>
      'Efficacité du système catalytique inférieure au seuil (banc 1)';

  @override
  String get dtcDescriptionP0430 =>
      'Efficacité du système catalytique inférieure au seuil (banc 2)';

  @override
  String get dtcDescriptionP0440 =>
      'Dysfonctionnement du système de contrôle des émissions par évaporation';

  @override
  String get dtcDescriptionP0441 =>
      'Débit de purge incorrect du système d’émissions par évaporation';

  @override
  String get dtcDescriptionP0442 =>
      'Fuite détectée dans le système d’émissions par évaporation (petite fuite)';

  @override
  String get dtcDescriptionP0443 =>
      'Dysfonctionnement du circuit de la vanne de commande de purge du système d’émissions par évaporation';

  @override
  String get dtcDescriptionP0446 =>
      'Dysfonctionnement du circuit de commande de mise à l’air du système d’émissions par évaporation';

  @override
  String get dtcDescriptionP0447 =>
      'Circuit ouvert de commande de mise à l’air du système d’émissions par évaporation';

  @override
  String get dtcDescriptionP0449 =>
      'Dysfonctionnement du circuit de la vanne ou de l’électrovanne de mise à l’air du système d’émissions par évaporation';

  @override
  String get dtcDescriptionP0451 =>
      'Problème de plage ou de performance du capteur de pression du système d’émissions par évaporation';

  @override
  String get dtcDescriptionP0452 =>
      'Entrée basse du circuit du capteur de pression du système d’émissions par évaporation';

  @override
  String get dtcDescriptionP0453 =>
      'Entrée haute du circuit du capteur de pression du système d’émissions par évaporation';

  @override
  String get dtcDescriptionP0455 =>
      'Fuite détectée dans le système d’émissions par évaporation (fuite importante)';

  @override
  String get dtcDescriptionP0456 =>
      'Fuite détectée dans le système d’émissions par évaporation (très petite fuite)';

  @override
  String get dtcDescriptionP0480 =>
      'Dysfonctionnement du circuit de commande du ventilateur de refroidissement 1';

  @override
  String get dtcDescriptionP0500 =>
      'Dysfonctionnement du capteur de vitesse du véhicule';

  @override
  String get dtcDescriptionP0505 =>
      'Dysfonctionnement du système de régulation du ralenti';

  @override
  String get dtcDescriptionP0506 =>
      'Régime moteur du système de régulation du ralenti inférieur à la valeur attendue';

  @override
  String get dtcDescriptionP0507 =>
      'Régime moteur du système de régulation du ralenti supérieur à la valeur attendue';

  @override
  String get dtcDescriptionP0508 =>
      'Niveau bas du circuit du système de régulation du ralenti';

  @override
  String get dtcDescriptionP0509 =>
      'Niveau haut du circuit du système de régulation du ralenti';

  @override
  String get dtcDescriptionP0560 =>
      'Dysfonctionnement de la tension du système';

  @override
  String get dtcDescriptionP0562 => 'Tension du système basse';

  @override
  String get dtcDescriptionP0563 => 'Tension du système haute';

  @override
  String get dtcDescriptionP0603 =>
      'Erreur de mémoire de maintien (KAM) du module de commande interne';

  @override
  String get dtcDescriptionP0605 =>
      'Erreur de mémoire en lecture seule (ROM) du module de commande interne';

  @override
  String get dtcDescriptionP0606 => 'Défaut du processeur ECM/PCM';

  @override
  String get dtcDescriptionP0700 =>
      'Le module de commande de transmission a demandé l’allumage du voyant de défaut — le code défaut lui-même se trouve dans le module de transmission et doit être lu séparément';

  @override
  String get dtcDescriptionP0701 =>
      'Problème de plage ou de performance du système de commande de transmission';

  @override
  String get dtcDescriptionP0702 =>
      'Défaut électrique du système de commande de transmission';

  @override
  String get dtcDescriptionP0705 =>
      'Dysfonctionnement du circuit du capteur de position de transmission';

  @override
  String get dtcDescriptionP0715 =>
      'Dysfonctionnement du circuit du capteur de vitesse d’entrée ou de turbine';

  @override
  String get dtcDescriptionP0720 =>
      'Dysfonctionnement du circuit du capteur de vitesse de sortie';

  @override
  String get dtcDescriptionP0730 => 'Rapport de transmission incorrect';

  @override
  String get dtcDescriptionP0740 =>
      'Dysfonctionnement du circuit d’embrayage du convertisseur de couple';

  @override
  String get dtcDescriptionP0741 =>
      'Embrayage du convertisseur de couple bloqué en position désengagée';

  @override
  String get dtcDescriptionP0750 =>
      'Dysfonctionnement de l’électrovanne de changement de rapport A';

  @override
  String get dtcDescriptionP0755 =>
      'Dysfonctionnement de l’électrovanne de changement de rapport B';

  @override
  String get dtcDescriptionP2135 =>
      'Corrélation des tensions des capteurs de position du papillon A/B';

  @override
  String get dtcDescriptionU0100 => 'Communication perdue avec ECM/PCM';

  @override
  String get dtcDescriptionU0101 =>
      'Communication perdue avec le module de commande de transmission';

  @override
  String get dtcDescriptionU0121 =>
      'Communication perdue avec le module de commande ABS';

  @override
  String get dtcDescriptionU0140 =>
      'Communication perdue avec le module de commande de carrosserie';

  @override
  String get dtcDescriptionU0155 =>
      'Communication perdue avec le module de commande du combiné d’instruments';

  @override
  String get gaugeSkinCluster => 'Combiné';

  @override
  String get gaugeSkinClusterDescription =>
      'Ressemble à un combiné d’instruments d’origine. Aiguille, cadran à 270 degrés, fond en creux.';

  @override
  String get gaugeSkinMinimal => 'Minimal';

  @override
  String get gaugeSkinMinimalDescription =>
      'Un demi-arc, sans aiguille ni graduations. C’est le chiffre qui se lit, pas le mouvement.';

  @override
  String get gaugeSkinTrack => 'Circuit';

  @override
  String get gaugeSkinTrackDescription =>
      'Barre segmentée, sans lissage. La valeur apparaît là où elle se trouve, sans valeur intermédiaire.';

  @override
  String get gaugeSkinClassic => 'Classique';

  @override
  String get gaugeSkinClassicDescription =>
      'Cadran imprimé, chiffres sur tout le tour et aiguille qui se stabilise lentement comme une montre mécanique.';

  @override
  String get gaugeSkinNight => 'Nuit';

  @override
  String get gaugeSkinNightDescription =>
      'Pour la conduite de nuit. Faible luminosité, arc peu marqué, aucune animation — pour solliciter votre attention le moins possible.';

  @override
  String get derivedAirflowSourceMaf => 'Capteur MAF';

  @override
  String get derivedAirflowSourceSpeedDensity => 'Estimation vitesse-densité';

  @override
  String get derivedAirflowSourceUnavailable => 'Masse d’air indisponible';

  @override
  String get derivedFuelSourceStoichiometric => 'Estimation stœchiométrique';

  @override
  String get derivedFuelSourceUnavailable => 'Débit de carburant indisponible';

  @override
  String get telemetrySourceDemo => 'Simulateur intégré';

  @override
  String get telemetrySourceRig => 'Banc d’essai';

  @override
  String get telemetrySourceFieldApp => 'Connexion de l’application terrain';

  @override
  String get fuelTypeGasoline => 'Essence';

  @override
  String get fuelTypeDiesel => 'Diesel';

  @override
  String get fuelTypeLpg => 'GPL';

  @override
  String get fuelTypeEthanolE85 => 'Éthanol E85';

  @override
  String get drivetrainFwd => 'Traction avant';

  @override
  String get drivetrainRwd => 'Propulsion arrière';

  @override
  String get drivetrainAwd => 'Transmission intégrale';

  @override
  String get assumptionFieldMass => 'Masse';

  @override
  String get assumptionFieldDragCoefficient => 'Cd';

  @override
  String get assumptionFieldFrontalArea => 'Surface frontale';

  @override
  String get assumptionFieldRollingResistance => 'Résistance au roulement';

  @override
  String get assumptionFieldDrivetrainEfficiency =>
      'Rendement de la transmission';

  @override
  String get assumptionFieldFuelType => 'Carburant';

  @override
  String get assumptionFieldStoichAfr => 'AFR';

  @override
  String get assumptionFieldFuelDensity => 'Densité';

  @override
  String get assumptionFieldDisplacement => 'Cylindrée';

  @override
  String get assumptionFieldVolumetricEfficiency => 'VE';

  @override
  String get vehicleFieldOriginGenericDefault => 'valeur générique par défaut';

  @override
  String get vehicleFieldOriginUserEntered => 'saisi par vous';

  @override
  String get vehicleFieldOriginOfficialRegistry => 'registre officiel';

  @override
  String get vehicleFieldOriginManufacturerPublication =>
      'données du constructeur';

  @override
  String get vehicleFieldOriginScientificModel => 'coefficient du modèle';

  @override
  String assumptionWithOrigin(String field, String value, String origin) {
    return '$field $value ($origin)';
  }

  @override
  String assumptionWithoutOrigin(String field, String value) {
    return '$field $value';
  }

  @override
  String get assumptionSeparator => ' ; ';

  @override
  String get datumFormulaHorsepower =>
      'wheelWatts = (m·a + ½ρ·Cd·A·v² + Crr·m·g)·v; engineHp = wheelHp / drivetrainEfficiency';

  @override
  String get datumFormulaFuelRate =>
      'L/h = (MAF g/s) / (AFR × fuel density g/L) × 3600; MAF provient soit du PID 0110, soit de l’estimation vitesse-densité (RPM × MAP × displacement × VE / T_K); L/100km = (L/h) / speed_kmh × 100';

  @override
  String get datumAssumptionsFromRecording =>
      'L’estimation utilise les paramètres du véhicule tels qu’ils étaient lors de cet enregistrement.';

  @override
  String adapterConcernFirmwareNeverReleasedSummary(String version) {
    return 'Indique le firmware v$version, qui n’a jamais été publié';
  }

  @override
  String get adapterConcernFirmwareNeverReleasedDetail =>
      'Elm Electronics n’a jamais publié cette version ; le firmware de cet adaptateur n’est donc pas celui qu’il prétend avoir. Beaucoup de ces adaptateurs fonctionnent néanmoins, mais leur propre description n’est pas fiable et il est judicieux de les suspecter en premier lorsqu’une lecture échoue.';

  @override
  String adapterConcernPpsRefusedSummary(String version) {
    return 'Annonce v$version, mais ne connaît pas ATPPS, présent depuis v1.1';
  }

  @override
  String get adapterConcernPpsRefusedDetail =>
      'Le résumé des paramètres programmables (ATPPS) existe depuis ELM327 v1.1, et même les adaptateurs haut de gamme comme OBDLink le prennent en charge. La version annoncée et les commandes effectivement implémentées ne concordent pas.';

  @override
  String get adapterConcernNoIdentitySummary =>
      'Ne répond pas à AT@1, commande d’identification de l’appareil présente dès la première version';

  @override
  String get adapterConcernNoIdentityDetail =>
      'Cette commande existe depuis ELM327 v1.0. Ne pas y répondre signifie que cette puce implémente un jeu de commandes plus restreint que tout firmware officiel.';

  @override
  String get telemetryReplaySampled =>
      'L’aperçu est échantillonné ; l’export conserve chaque événement enregistré.';

  @override
  String get telemetryExportDisclosure =>
      'L’export contient les noms et valeurs des signaux, les heures d’observation et de source, le type de transport, le protocole, les libellés, unités et formules PID figés, ainsi que les hypothèses de l’estimation (masse, traînée, cylindrée, carburant et paramètres similaires). Le JSON peut aussi contenir vos libellés, unités et formules personnalisés ainsi que les définitions figées complètes. L’export ne contient pas le VIN, le GPS, de compte, l’adresse de l’adaptateur, le profil complet du véhicule ni le trafic de diagnostic brut.';

  @override
  String get connectTransportCancelled =>
      'La tentative de connexion a été arrêtée avant la fin.';

  @override
  String get connectTransportWifiRouteNoNetwork =>
      'Le téléphone n’est connecté à aucun réseau Wi-Fi ; il n’existe donc aucune route vers l’adaptateur. Connectez-vous au point d’accès Wi-Fi de l’adaptateur, puis réessayez.';

  @override
  String get connectTransportWifiRouteAmbiguous =>
      'Le téléphone est connecté à plusieurs réseaux Wi-Fi et aucun n’est clairement celui de l’adaptateur ; aucun n’a donc été choisi. Déconnectez les réseaux qui ne sont pas ceux de l’adaptateur, puis réessayez.';

  @override
  String get connectTransportWifiRouteRefused =>
      'Le système a refusé d’acheminer cette connexion par Wi-Fi. Le téléphone est connecté au Wi-Fi, mais son utilisation pour cette connexion n’a pas été autorisée.';

  @override
  String get connectTransportWifiRouteTimeout =>
      'Le système n’a pas répondu à la demande d’acheminement de cette connexion par Wi-Fi. Attendez quelques secondes, puis réessayez.';

  @override
  String get connectTransportWifiRouteUnclassified =>
      'La connexion n’a pas pu être acheminée par Wi-Fi, pour une raison que le système n’a pas précisée. L’erreur complète est conservée dans le journal ci-dessous.';

  @override
  String get connectTransportWifiHostUnreachable =>
      'Rien n’a répondu à cette adresse. Vérifiez que le téléphone est connecté au point d’accès Wi-Fi de l’adaptateur ; si le système demande de rester connecté sans Internet, choisissez de rester connecté. Désactiver les données mobiles peut aussi aider.';

  @override
  String get connectTransportWifiConnectTimeout =>
      'Rien n’a répondu à cette adresse dans le délai imparti.';

  @override
  String get connectTransportWifiRouteRestoreFailed =>
      'La connexion a fonctionné, mais le routage réseau du téléphone n’a pas pu être rétabli ; la connexion a donc été interrompue pour éviter de laisser le routage modifié. Redémarrez l’application et réessayez.';

  @override
  String get connectTransportBleLinkFailed =>
      'Impossible de se connecter à l’adaptateur. Vérifiez qu’il est alimenté et à portée.';

  @override
  String get connectTransportBleNoSerialCharacteristic =>
      'L’appareil est connecté, mais aucun port série n’a été trouvé ; il ne s’agit donc peut-être pas d’un adaptateur ELM327.';

  @override
  String get connectTransportClassicAllTiersRefused =>
      'Impossible de se connecter à l’adaptateur. Appairez-le d’abord dans les paramètres Bluetooth du système, puis vérifiez qu’il est branché à la prise OBD et que le contact est mis.';

  @override
  String get connectTransportClassicConnectTimeout =>
      'Le délai de connexion à l’adaptateur a expiré. Il répond peut-être encore ; attendez quelques secondes avant de réessayer.';

  @override
  String get connectTransportSerialPortOpenFailed =>
      'Impossible d’ouvrir le port série. Vérifiez que le système en a créé un pour cet adaptateur (COMx sous Windows, /dev/rfcomm* sous Linux) et que le contact est mis.';

  @override
  String get connectTransportSerialDroppedOnOpen =>
      'Le port série s’est ouvert, puis refermé immédiatement.';

  @override
  String get settingsManualCommandNotConnected =>
      'Aucun appareil n’est connecté ; la commande n’a donc pas été envoyée.';

  @override
  String get settingsManualCommandLinkDropped =>
      'La connexion à l’adaptateur a été interrompue pendant l’envoi de cette commande ; aucune réponse n’est donc parvenue. On ne sait pas si l’adaptateur a reçu la commande.';

  @override
  String get settingsManualCommandDisconnectedByApp =>
      'L’application a fermé la connexion pendant l’envoi de cette commande ; aucune réponse n’est donc parvenue. L’adaptateur et le véhicule ne présentent aucun problème.';

  @override
  String get settingsManualCommandAdapterSilentOnResync =>
      'Les réponses de l’adaptateur ne correspondaient plus aux commandes envoyées et il n’a pas répondu à la vérification qui aurait rétabli leur concordance ; la connexion a donc été interrompue. Reconnectez-vous avant de réessayer.';

  @override
  String get settingsManualCommandLinkStoppedResponding =>
      'Rien n’est arrivé de l’adaptateur pendant suffisamment longtemps pour que la connexion soit interrompue. Il est peut-être toujours alimenté ; seule son absence de réponse est connue.';

  @override
  String get settingsManualCommandWriteFailed =>
      'La commande n’a pas pu être transmise à la connexion de l’adaptateur. On ne sait pas quelle partie a atteint l’adaptateur.';

  @override
  String get settingsManualCommandTimedOut =>
      'Aucune réponse n’est arrivée avant la limite de temps. Vérifiez que l’adaptateur est connecté et que le contact est mis.';

  @override
  String get settingsManualCommandOperationRetired =>
      'Cette session est terminée ou passée en arrière-plan ; la commande n’a donc pas été envoyée.';

  @override
  String get settingsManualCommandRequestUnaddressable =>
      'Cette requête ne peut pas être adressée sur le bus utilisé par ce véhicule ; elle n’a donc pas été envoyée. Réessayer ne changera rien.';

  @override
  String get commandFailureBusJ1939 =>
      'Ce bus utilise SAE J1939 (véhicules utilitaires lourds et engins), et non le protocole de diagnostic OBD2 lu par cette application ; cette requête ne peut donc pas être lue.';

  @override
  String commandFailureUserCanFramingUnknown(
    String protocol,
    String parameter,
  ) {
    return 'Cet adaptateur est réglé sur le protocole CAN personnalisé $protocol, dont le format de trame dépend de $parameter. L’adaptateur n’a pas indiqué ce réglage ; le format du bus ne peut donc pas être confirmé et cette requête ne peut pas être décodée en toute sécurité.';
  }

  @override
  String get commandFailureBusUndetermined =>
      'Le protocole du bus du véhicule n’est pas encore déterminé ; cette requête ne peut donc pas être décodée en toute sécurité. Reconnectez-vous.';

  @override
  String get settingsManualCommandCustomFlowControlRejected =>
      'L’adaptateur a refusé une commande personnalisée de contrôle de flux ; le mode demandé n’a donc pas été appliqué et aucune mesure n’a été produite.';

  @override
  String get settingsManualCommandFlowControlRestoreFailed =>
      'L’adaptateur a refusé de rétablir le contrôle de flux par défaut (ATFCSM0) ; l’interrogation périodique est donc arrêtée jusqu’à votre reconnexion.';

  @override
  String get settingsManualCommandExtendedAddressingUnavailable =>
      'L’adressage étendu n’est pas disponible sur cette liaison ELM327.';

  @override
  String get settingsManualCommandRawIsoTpModeUnavailable =>
      'Le réassemblage ISO-TP visible par l’hôte n’est pas disponible sur cette liaison ELM327.';

  @override
  String get settingsManualCommandCanPriorityUnavailable =>
      'La programmation de priorité CAN n’est pas disponible sur cette liaison ELM327.';

  @override
  String get settingsManualCommandCanReceiveFilterUnavailable =>
      'Le filtrage de réception CAN n’est pas disponible sur cette liaison ELM327.';

  @override
  String get settingsManualCommandHeaderRestoreFailed =>
      'L’adaptateur a refusé de rétablir l’en-tête (ATSH) ; l’interrogation périodique est donc arrêtée jusqu’à votre reconnexion.';

  @override
  String get manualCommandRefusedEmpty =>
      'Rien n’a été saisi ; rien n’a donc été envoyé.';

  @override
  String get manualCommandRefusedMoreThanOneCommand =>
      'Ce texte contient un saut de ligne ou un autre caractère de contrôle, ce qui envoie plusieurs commandes à la fois. L’adaptateur sépare les commandes par des sauts de ligne ; la seconde contournerait donc toutes les vérifications effectuées ici, y compris celle qui refuse l’effacement des codes défaut. Envoyez une commande à la fois.';

  @override
  String manualCommandRefusedAdapterStateWouldChange(
    Object command,
    Object allowed,
  ) {
    return 'Ce champ accepte des requêtes, pas des commandes qui modifient le fonctionnement de l’adaptateur. « $command » modifierait l’état de l’adaptateur alors que l’application conserverait son modèle précédent : les mesures suivantes pourraient provenir d’un autre calculateur sans que l’écran ne l’indique.\nRequêtes autorisées : $allowed.';
  }

  @override
  String get manualCommandRefusedClearHasItsOwnButton =>
      'Pour effacer les codes défaut, utilisez le bouton Effacer sur l’écran des codes défaut. Envoyée depuis ici, la commande contournerait la confirmation, la vérification de couverture et la validation des réponses, et n’atteindrait que le calculateur actuellement sélectionné.';

  @override
  String manualCommandRefusedCharactersNoObdCommandHas(Object command) {
    return 'La commande « $command » contient des caractères qu’une commande OBD ne comporte jamais. Ce champ accepte des codes de service et paramètres hexadécimaux — 0100, 03, 2211A6 — ou une requête d’adaptateur commençant par AT.';
  }

  @override
  String manualCommandRefusedNotAReadOnlyQuery(Object command, Object allowed) {
    return '« $command » n’est pas une commande reconnue par ce champ. Il accepte les requêtes en lecture seule (Mode $allowed) et les requêtes d’adaptateur.';
  }

  @override
  String commandFailureQueryHeaderRefused(Object header) {
    return 'L’adaptateur a refusé de diriger cette requête vers le calculateur $header ; elle n’a donc pas été envoyée. En conservant l’adresse réellement détenue par l’adaptateur, la réponse serait venue d’un calculateur qui n’avait pas été interrogé.';
  }

  @override
  String commandFailureWholeVehicleHeaderRefused(Object address) {
    return 'L’adaptateur a refusé de passer à l’adresse $address, nécessaire pour envoyer une requête à l’ensemble du véhicule. Sans elle, les réponses ne peuvent pas être attribuées aux calculateurs qui les ont envoyées ; la requête n’a donc pas été effectuée.';
  }

  @override
  String commandFailureLegacyScanWouldBePartial(Object installed) {
    return 'Ce véhicule utilise un ancien bus sans adresse standard permettant d’atteindre tous les calculateurs, et l’adaptateur est actuellement réglé sur le calculateur $installed. Une analyse n’aurait couvert que ce calculateur tout en étant présentée comme portant sur l’ensemble du véhicule ; elle n’a donc pas été envoyée. Reconnectez-vous, puis relancez l’analyse.';
  }

  @override
  String get pidFormulaEmpty => 'La formule est vide.';

  @override
  String get pidFormulaEmptySubExpression =>
      'Une partie de la formule est vide : un opérateur n’est suivi de rien ou des parenthèses ne contiennent rien.';

  @override
  String get pidFormulaUnbalancedParentheses =>
      'Les parenthèses ne correspondent pas : chaque ( doit avoir une ) fermante.';

  @override
  String pidFormulaUnparsableTerm(String term) {
    return '« $term » n’est ni un nombre, ni un opérateur, ni un nom reconnu par cet éditeur.';
  }

  @override
  String get pidFormulaFunctionNestingTooDeep =>
      'ABS(), LOG10(), LOG() et SQRT() sont trop imbriquées pour être évaluées. Simplifiez la formule.';

  @override
  String get pidFormulaParenthesisNestingTooDeep =>
      'Les parenthèses sont trop imbriquées pour permettre l’évaluation. Simplifiez la formule.';

  @override
  String get pidFormulaDivisionByZero => 'La formule divise par zéro.';

  @override
  String get pidFormulaModuloByZero =>
      'La formule calcule un reste modulo zéro.';

  @override
  String pidFormulaLog10NonPositiveArgument(double argument) {
    return 'LOG10 exige un argument supérieur à 0, et celui-ci vaut $argument.';
  }

  @override
  String pidFormulaLogNonPositiveArgument(double argument) {
    return 'LOG exige un argument supérieur à 0, et celui-ci vaut $argument.';
  }

  @override
  String pidFormulaSqrtNegativeArgument(double argument) {
    return 'SQRT exige un argument supérieur ou égal à 0, et celui-ci vaut $argument.';
  }

  @override
  String get pidFormulaResultNotFinite =>
      'Le calcul n’a produit aucun nombre utilisable ; il n’y a donc aucune mesure à afficher.';

  @override
  String pidFormulaByteBeyondResponse(String letter, int count) {
    return 'La formule fait référence à l’octet $letter, mais la réponse ne contenait que $count octets.';
  }

  @override
  String get pidFormulaBaroControllerUnknown =>
      'BARO ne peut pas être utilisé ici, car le calculateur dont la pression ambiante est demandée n’est pas connu.';

  @override
  String get pidFormulaBaroTwoDefinitions =>
      'Deux définitions fournissent toutes deux la pression ambiante ; la valeur pourrait donc provenir de l’une ou de l’autre et aucune ne peut être utilisée. Retirez l’un des cadrans qui mesure la pression ambiante.';

  @override
  String get pidFormulaBaroNotYetMeasured =>
      'La pression ambiante n’a pas encore été lue ; le calcul est donc impossible.';

  @override
  String get pidFormulaBaroMeasurementStale =>
      'La mesure de pression ambiante est périmée ; le calcul est donc impossible.';

  @override
  String get pidFormulaBaroParenFormUnsupported =>
      'BARO() désigne le baromètre Android ou la pression barométrique ECU en psi, que ce dialecte n’implémente pas. Utilisez BARO sans parenthèses pour la pression ambiante en cache.';

  @override
  String get pidFormulaInt16Unclaimed =>
      'INT16 n’a pas de définition retenue : le wiki indique qu’il peut remplacer (A*255)+B, qui n’est pas (A*256)+B. Écrivez explicitement l’une de ces expressions.';

  @override
  String pidFormulaTimeWindowUnsupported(String term) {
    return '$term est une fonction Torque de délai, de moyenne ou de totalisation (totalizer) que ce dialecte n’implémente pas ; elle ne peut donc pas être évaluée ici. Ce n’est ni 0, ni MIN, ni MAX.';
  }

  @override
  String pidFormulaDependencyControllerUnknown(String reference) {
    return '$reference ne peut pas être résolu ici, car le calculateur auquel appartient ce PID n’est pas connu.';
  }

  @override
  String pidFormulaDependencyTwoDefinitions(String key) {
    return 'Deux définitions décodent toutes deux $key ; la valeur pourrait donc provenir de l’une ou de l’autre et aucune ne peut être utilisée. Modifiez l’une d’elles pour utiliser un autre mode+PID. Remarque : les PID nécessaires aux estimations (010B, 010C, 010D) sont toujours lus ; retirer un cadran du tableau de bord n’arrête donc pas leur lecture.';
  }

  @override
  String pidFormulaDependencyNotYetMeasured(String key) {
    return 'Aucune valeur exploitable n’a encore été lue pour $key.';
  }

  @override
  String get pidFormulaUnidentified =>
      'Cette formule ne peut pas être évaluée et l’éditeur ne dispose d’aucune raison plus précise.';

  @override
  String get pidRejectionMalformedModeAndPid =>
      'Mode+PID non valide : uniquement des caractères hexadécimaux, par paires représentant des octets entiers.';

  @override
  String pidRejectionServiceNotReadOnly(String service, String services) {
    return 'Le service $service n’est pas une requête en lecture seule et ne doit pas être envoyé au véhicule en continu. Seuls $services sont autorisés : données courantes, trame figée, informations du véhicule et ReadDataByIdentifier.';
  }

  @override
  String get pidRejectionFreezeFrameNeedsFrame =>
      'Une requête de trame figée nécessite deux octets, le PID et le numéro de trame ; par exemple 020500 (PID 05, trame 0).';

  @override
  String get pidRejectionIdentifierNeedsTwoBytes =>
      'ReadDataByIdentifier nécessite un identifiant de deux octets, par exemple 221101.';

  @override
  String pidRejectionIdentifierWrongLength(String service, int bytes) {
    return 'Une requête du service $service nécessite un identifiant de $bytes octets.';
  }

  @override
  String get pidRejectionNameRequired => 'Saisissez un nom.';

  @override
  String pidRejectionInvalidHeader(String text) {
    return '« $text » n’est pas un en-tête valide : 3 chiffres pour CAN 11-bit, 6 pour les anciens protocoles, 8 pour CAN 29-bit.';
  }

  @override
  String get pidRejectionBoundsRequired =>
      'Renseignez les deux bornes de la plage du cadran.';

  @override
  String pidRejectionMinNotANumber(String text) {
    return 'La borne inférieure « $text » n’est pas un nombre valide.';
  }

  @override
  String pidRejectionMaxNotANumber(String text) {
    return 'La borne supérieure « $text » n’est pas un nombre valide.';
  }

  @override
  String get pidRejectionMinNotFinite =>
      'La borne inférieure doit être un nombre fini.';

  @override
  String get pidRejectionMaxNotFinite =>
      'La borne supérieure doit être un nombre fini.';

  @override
  String pidRejectionRedlineNotANumber(String text) {
    return 'Le début de zone rouge « $text » n’est pas un nombre valide.';
  }

  @override
  String get pidRejectionRedlineNotFinite =>
      'Le début de zone rouge doit être un nombre fini.';

  @override
  String get pidRejectionMaxNotAboveMin =>
      'La borne supérieure doit être supérieure à la borne inférieure.';

  @override
  String pidImportMalformedCsv(String detail) {
    return 'Ce fichier n’a pas pu être lu comme CSV : $detail';
  }

  @override
  String get pidImportNoRows => 'Le fichier ne contient aucune ligne.';

  @override
  String pidImportDuplicateHeaderColumns(String columns) {
    return 'La ligne d’en-tête nomme deux fois la même colonne : $columns. Il est impossible de savoir laquelle utiliser ; corrigez d’abord le fichier.';
  }

  @override
  String pidImportMissingRequiredColumns(String columns, String required) {
    return 'Il manque des colonnes obligatoires dans la ligne d’en-tête : $columns. Toutes ces colonnes sont nécessaires : $required.';
  }

  @override
  String pidImportRowTooFewColumns(int line) {
    return 'Ligne $line : pas assez de cellules — nom, nom court, PID et formule sont le minimum.';
  }

  @override
  String pidImportRowInvalidModeAndPid(int line, String text) {
    return 'Ligne $line : « $text » n’est pas un mode+PID valide (uniquement des caractères hexadécimaux, par paires représentant des octets entiers).';
  }

  @override
  String pidImportRowEmptyEquation(int line) {
    return 'Ligne $line : la cellule de formule est vide.';
  }

  @override
  String pidImportRowRejected(int line, String reason) {
    return 'Ligne $line : $reason';
  }

  @override
  String pidImportRowRangeDefaulted(int line, double min, double max) {
    return 'Ligne $line : la plage du cadran était vide ; $min–$max a donc été appliquée. Vérifiez que cette échelle convient au capteur.';
  }

  @override
  String get pidImportNothingImportable =>
      'Le fichier contient des lignes, mais aucune ne définit un PID.';

  @override
  String get dtcCategoryNoAnswer =>
      'Cette catégorie n’a pas répondu. Relancez l’analyse.';

  @override
  String get dtcCategoryError =>
      'Cette catégorie n’a pas pu être lue. L’erreur complète est conservée dans le journal de diagnostic.';

  @override
  String get dtcCategoryDisconnected =>
      'La connexion a été interrompue pendant la lecture de cette catégorie.';

  @override
  String get dtcCategoryPending =>
      'Un calculateur a reçu la requête et la traite encore. Attendez, puis relancez l’analyse ; il ne s’agit pas d’un refus.';

  @override
  String get dtcCategoryUnattributed =>
      'Des codes ont été reçus, mais les en-têtes de réponse étaient désactivés ; les calculateurs ayant répondu ne sont donc pas connus. Considérez ce résultat comme partiel, et non comme un résultat sans défaut.';

  @override
  String dtcCategorySilentControllers(int count, String controllers) {
    return '$count calculateur(s) n’ont pas répondu à cette requête ($controllers). Les réponses reçues sont valides, mais ne peuvent pas représenter un résultat pour l’ensemble du véhicule.';
  }

  @override
  String dtcCategoryUnresolvedSources(int count, String addresses) {
    return '$count réponse(s) n’ont pas pu être attribuées à un calculateur ($addresses). Les codes lus restent valides, mais ne peuvent pas représenter un résultat pour l’ensemble du véhicule. Relancez l’analyse.';
  }

  @override
  String dtcCategoryPendingControllers(int count, int answered) {
    return '$count calculateur(s) traitent encore cette requête ($answered ont déjà répondu). Le résultat est incomplet. Attendez, puis relancez l’analyse.';
  }

  @override
  String dtcCategoryRefusedControllers(int refused, int answered) {
    return '$refused calculateur(s) ont refusé ($answered ont répondu). Cette analyse ne peut pas couvrir l’ensemble du véhicule.';
  }

  @override
  String dtcCategoryUnrecognisedResponses(int count, int answered) {
    return '$count réponse(s) n’ont pas pu être lues ($answered ont répondu). Le reste demeure valide, mais cette analyse est incomplète.';
  }

  @override
  String dtcCategoryMilCountMismatch(
    String controller,
    int claimed,
    int observed,
  ) {
    return '$controller a signalé $claimed codes défaut confirmés, mais cette analyse n’en a lu que $observed. Fiez-vous au voyant du tableau de bord et consultez un atelier.';
  }

  @override
  String dtcCategoryMilLitNoCodes(String controller) {
    return '$controller a signalé que le voyant de défaut est allumé, mais aucun de ses codes défaut n’a été lu. Fiez-vous au voyant du tableau de bord et consultez un atelier.';
  }

  @override
  String dtcCategoryMilDisagreement(String controllers) {
    return 'L’état indiqué par le véhicule ne correspond pas aux codes défaut lus ($controllers). Fiez-vous au voyant du tableau de bord et consultez un atelier.';
  }

  @override
  String get connectPairedListFailed =>
      'La liste des appareils Bluetooth appairés n’a pas pu être lue. Vérifiez que Bluetooth est activé, puis réessayez.';

  @override
  String get connectBleScanUnavailable =>
      'Bluetooth n’est pas utilisable pour le moment. Patientez, puis relancez la recherche.';

  @override
  String get connectBleScanBluez =>
      'Aucun service Bluetooth BlueZ/D-Bus utilisable n’a été trouvé. Installez et démarrez le service bluetooth, puis réessayez.';

  @override
  String get connectBleScanUnclassified => 'La recherche BLE a échoué.';

  @override
  String dtcClearNrcConditions(String controller) {
    return '$controller a refusé l’effacement car l’état du véhicule ne le permet pas. La plupart des calculateurs n’effacent pas les codes lorsque le moteur tourne. Mettez le contact sur ON moteur arrêté, puis réessayez.';
  }

  @override
  String dtcClearNrcUnsupported(String controller) {
    return '$controller ne prend pas en charge l’effacement Mode 04. Un équipement du constructeur ou du concessionnaire peut être nécessaire.';
  }

  @override
  String dtcClearNrcBusy(String controller) {
    return '$controller est occupé. Attendez, puis réessayez.';
  }

  @override
  String dtcClearNrcSecurity(String controller) {
    return '$controller exige un accès de sécurité avant l’effacement. Un équipement du constructeur ou du concessionnaire est nécessaire.';
  }

  @override
  String dtcClearNrcOther(String controller, String code) {
    return '$controller a refusé l’effacement (code de motif $code). Attendez, puis réessayez.';
  }

  @override
  String dtcClearSilentControllers(int count, String controllers) {
    return '$count calculateur(s) n’ont pas répondu à la commande d’effacement ($controllers). Les calculateurs ayant répondu ont effacé les codes ; les autres peuvent encore en contenir. Relancez l’analyse. N’envoyez pas une autre commande d’effacement.';
  }

  @override
  String dtcClearUnresolvedSources(int count, String addresses) {
    return '$count réponse(s) de cette analyse n’ont pas pu être attribuées ($addresses) ; on ne sait donc pas quels calculateurs seraient atteints par une commande d’effacement. Relancez l’analyse ; si cette adresse ne réapparaît pas, reconnectez-vous avant de réessayer.';
  }

  @override
  String dtcClearUnresolvedSourcesDoNotRepeat(int count, String addresses) {
    return '$count réponse(s) à la commande d’effacement n’ont pas pu être attribuées ($addresses). N’envoyez pas une autre commande d’effacement. Relancez l’analyse pour voir quels codes restent.';
  }

  @override
  String dtcClearNrcConditionsDoNotRepeat(String controller) {
    return '$controller a refusé l’effacement car l’état du véhicule ne le permet pas. La plupart des calculateurs n’effacent pas les codes lorsque le moteur tourne. Mettez le contact sur ON moteur arrêté, puis relancez l’analyse pour voir quels codes restent. N’envoyez pas une autre commande d’effacement global : une seconde peut réinitialiser l’état de préparation antipollution d’un calculateur qui a peut-être déjà effacé ses codes.';
  }

  @override
  String dtcClearNrcUnsupportedDoNotRepeat(String controller) {
    return '$controller ne prend pas en charge l’effacement Mode 04. Un équipement du constructeur ou du concessionnaire peut être nécessaire. N’envoyez pas une autre commande d’effacement global : une seconde peut réinitialiser l’état de préparation antipollution d’un calculateur qui a peut-être déjà effacé ses codes. Relancez l’analyse pour voir quels codes restent.';
  }

  @override
  String dtcClearNrcBusyDoNotRepeat(String controller) {
    return '$controller est occupé. N’envoyez pas une autre commande d’effacement global : une seconde peut réinitialiser l’état de préparation antipollution d’un calculateur qui a peut-être déjà effacé ses codes. Relancez l’analyse pour voir quels codes restent.';
  }

  @override
  String dtcClearNrcSecurityDoNotRepeat(String controller) {
    return '$controller exige un accès de sécurité avant l’effacement. Un équipement du constructeur ou du concessionnaire est nécessaire. N’envoyez pas une autre commande d’effacement global : une seconde peut réinitialiser l’état de préparation antipollution d’un calculateur qui a peut-être déjà effacé ses codes.';
  }

  @override
  String dtcClearNrcOtherDoNotRepeat(String controller, String code) {
    return '$controller a refusé l’effacement (code de motif $code). N’envoyez pas une autre commande d’effacement global : une seconde peut réinitialiser l’état de préparation antipollution d’un calculateur qui a peut-être déjà effacé ses codes. Relancez l’analyse pour voir quels codes restent.';
  }

  @override
  String get sharePolicyDenied =>
      'L’état actuel de la connexion ou de la conduite ne permet pas l’export.';

  @override
  String get shareSafetyChanged =>
      'L’état a changé pendant la préparation de l’export ; le partage n’a donc pas été ouvert.';

  @override
  String get shareSizeLimit => 'L’export dépasse la limite de 32 MiB.';

  @override
  String get shareStagingBusy =>
      'Un précédent fichier de partage est encore dans sa période de conservation. Réessayez plus tard.';

  @override
  String get shareCleanupRequired =>
      'La zone temporaire de partage doit être vérifiée après un redémarrage.';

  @override
  String get shareSpaceUnknown =>
      'Impossible de confirmer l’espace libre nécessaire au fichier de partage.';

  @override
  String get shareNoSpace =>
      'L’espace de stockage est insuffisant pour préparer le fichier de partage.';

  @override
  String get shareHandoffFailed =>
      'Le fichier est prêt, mais la fenêtre de partage du système n’a pas pu être ouverte.';

  @override
  String get shareStorageFailure =>
      'Une erreur de stockage s’est produite lors de la préparation ou de l’enregistrement du partage.';

  @override
  String shareTelemetrySubject(String sessionId) {
    return 'Enregistrement OBD local $sessionId';
  }

  @override
  String shareRawTranscriptSubject(String stamp) {
    return 'Journal de transport Telltale $stamp';
  }

  @override
  String get shareRecoveredTranscriptSubject =>
      'Journal de transport Telltale (dernière connexion)';

  @override
  String get sharePidCsvSubject => 'Définitions PID personnalisées Telltale';

  @override
  String get shareTorqueSubsetCsvSubject =>
      'Définitions PID compatibles avec Torque';

  @override
  String get shareHumanReportCsvSubject => 'Rapport PID Telltale lisible';

  @override
  String get transcriptExportUnidentified => 'L’export a échoué.';

  @override
  String get handshakeNoteUnexpected =>
      'Cette étape a échoué avec une erreur inattendue. L’erreur complète est conservée dans le journal de diagnostic.';

  @override
  String pidFormulaUnsupportedConstruct(String term) {
    return '$term est une fonction Torque que ce dialecte n’implémente pas ; la formule ne peut donc pas être évaluée ici.';
  }

  @override
  String pidImportRowFormulaRejected(int line, String reason) {
    return 'Ligne $line : $reason';
  }

  @override
  String get telemetryHistoryNeedsForeground =>
      'Revenez à Telltale avant de continuer.';

  @override
  String get telemetrySessionPolicyChanged =>
      'L’état de conduite ou de connexion a changé pendant cette opération.';

  @override
  String get telemetrySessionInvalidId =>
      'Cet identifiant d’enregistrement n’est pas valide.';

  @override
  String get telemetrySessionNotFound =>
      'Cet enregistrement local est introuvable.';

  @override
  String get telemetrySessionStorageFailed =>
      'Une opération de stockage local a échoué.';

  @override
  String get telemetrySessionShareFailed =>
      'Impossible de préparer ou d’ouvrir le partage.';

  @override
  String get pidMutationPersistFailed =>
      'La liste des PID personnalisés n’a pas pu être enregistrée. Rien n’a été modifié.';

  @override
  String get powertrainAuthorizeYearOutOfRange =>
      'Cette année-modèle est hors de la plage d’années documentée pour ce profil.';

  @override
  String get connectionLayerTransport => 'Transport';

  @override
  String get connectionLayerProtocol => 'Protocole';

  @override
  String get connectionLayerEcu => 'Réponses ECU';

  @override
  String get connectionLayerEvidence => 'Éléments de preuve';

  @override
  String get connectionLayerUnknown => 'Inconnu';

  @override
  String get connectionLayerNotObserved => 'Non observé';

  @override
  String get connectionLayerObserved => 'Observé';

  @override
  String get connectionLayerAnswered => 'A répondu';

  @override
  String get connectionLayerSoftware => 'Logiciel';

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
    return 'demandé $requested, établi $observed';
  }

  @override
  String get connectionLayerKwpSubtypeUnknown =>
      'KWP, 5-baud ou fast non distingués';

  @override
  String get connectionFailureOpenSettings => 'Ouvrez les paramètres système.';

  @override
  String get connectionFailureTurnRadioOn => 'Activez Bluetooth.';

  @override
  String get connectionFailureCheckDistanceOrPower =>
      'L’adaptateur est peut-être hors de portée ou non alimenté. C’est une cause possible, pas un constat.';

  @override
  String get connectionFailureCheckIgnitionProtocolAdapter =>
      'Vérifiez le contact, le protocole ou les capacités de l’adaptateur. L’absence de réponse ne prouve pas que le véhicule n’a pas d’OBD.';

  @override
  String get connectionFailureRetryOrAuto =>
      'Réessayez ou réglez le protocole sur Auto.';

  @override
  String get connectionFailureKeepInvalidAndExport =>
      'La réponse est invalide. Conservez-la comme invalide et exportez le diagnostic limité ; ce n’est pas une mesure.';

  @override
  String get settingsCatalogMarketCa => 'Canada (NRCan)';

  @override
  String get settingsCaPickerTitle =>
      'Catalogue officiel des véhicules du Canada';

  @override
  String settingsCaPickerScope(int firstYear, int lastYear) {
    return 'Lignes des cotes de consommation de carburant pour le marché canadien de $firstYear à $lastYear uniquement. Les véhicules thermiques, électriques à batterie et hybrides rechargeables restent des classes distinctes. Une correspondance de marque et de modèle ne constitue pas une configuration EPA ou taïwanaise.';
  }

  @override
  String get settingsCaMotorNotPower =>
      'La puissance du moteur en kilowatts n’est pas la puissance aux roues en chevaux et n’est pas appliquée.';

  @override
  String get settingsCaClassIce => 'ICE';

  @override
  String get settingsCaClassBev => 'BEV';

  @override
  String get settingsCaClassPhev => 'PHEV';

  @override
  String settingsCaWillApplyOnly(String fields) {
    return 'Seuls $fields seront appliqués. Les kW du moteur, la consommation de carburant, l’autonomie, le CO2, VE, Cd, la surface frontale, Crr et le rendement de transmission restent non résolus.';
  }

  @override
  String get serviceRecipesTitle =>
      'Procédures d’entretien et diagnostics actifs';

  @override
  String get serviceRecipesSubtitle =>
      'Procédures d’entretien fondées sur les normes et découverte des capacités sans actionnement';

  @override
  String get serviceRecipesSafetyBannerTitle =>
      'Aucun véhicule admissible en conditions réelles';

  @override
  String get serviceRecipesSafetyBannerBody =>
      'L’actionnement physique d’un véhicule réel est strictement interdit (0 véhicule qualifié). Les procédures disponibles sont uniquement des scénarios de simulation.';

  @override
  String get serviceRecipesDiscoverySection =>
      'Découverte Mode 08 sans actionnement';

  @override
  String get serviceRecipesDiscoveryDescription =>
      'Interroge les identifiants de test de base standard (\$00, \$20, ...) sur CAN sans actionner de composant.';

  @override
  String get serviceRecipesDiscoveryButton =>
      'Rechercher les TID pris en charge en Mode 08';

  @override
  String get serviceRecipesDiscovering =>
      'Interrogation des TID pris en charge...';

  @override
  String serviceRecipesDiscoverySuccess(String tids) {
    return 'Mode 08 est pris en charge par l’ECU. TID pris en charge : $tids';
  }

  @override
  String get serviceRecipesDiscoveryUnsupported =>
      'Mode 08 n’est pas pris en charge par cet ECU';

  @override
  String serviceRecipesDiscoveryUnknown(String reason) {
    return 'Prise en charge de Mode 08 inconnue : $reason';
  }

  @override
  String serviceRecipesDiscoveryPartialWarning(String reason, String blocks) {
    return 'Découverte partiellement terminée ($reason). Blocs non terminés : $blocks. Remarque : non trouvé ne signifie pas non pris en charge.';
  }

  @override
  String get serviceRecipesCatalogSection =>
      'Procédures d’entretien disponibles';

  @override
  String get serviceRecipesSimulationBadge => 'Simulation prête';

  @override
  String get serviceRecipesLiveBlockedBadge =>
      'Exécution réelle bloquée (0 véhicule admissible)';

  @override
  String serviceRecipesStandard(String standard) {
    return 'Norme : $standard';
  }

  @override
  String serviceRecipesEcuHeader(String header) {
    return 'En-tête ECU : $header';
  }

  @override
  String serviceRecipesHash(String hash) {
    return 'Hachage canonique : $hash';
  }

  @override
  String get serviceRecipesDetailTitle => 'Détails de la procédure d’entretien';

  @override
  String get serviceRecipesPreconditions => 'Conditions préalables de sécurité';

  @override
  String get serviceRecipesRecovery => 'Commande de récupération';

  @override
  String get serviceRecipesClose => 'Fermer';

  @override
  String get serviceRecipesDiscoveryRequiresCan =>
      'Nécessite une connexion active au bus CAN OBD-II.';

  @override
  String serviceRecipesLoadError(String error) {
    return 'Erreur de chargement des procédures d’entretien : $error';
  }

  @override
  String get serviceRecipesNoPreconditions => 'Aucune';

  @override
  String get settingsServiceRecipesEntry =>
      'Procédures d’entretien et tests actifs';

  @override
  String get settingsServiceRecipesDesc =>
      'Consultez les procédures d’atelier et recherchez les tests Mode 08 pris en charge';

  @override
  String get mode08ReasonUnheaderedLimitation =>
      'Attribution des sources et couverture non confirmées : les réponses sans en-tête ne permettent pas d’établir l’identité des ECU entre les blocs';

  @override
  String mode08ReasonNoResponseWithEcu(
    String block,
    String ecu,
    String marker,
  ) {
    return 'Aucune réponse pour le bloc $block de $ecu : $marker';
  }

  @override
  String mode08ReasonNoResponse(String block, String marker) {
    return 'Aucune réponse pour le bloc $block : $marker';
  }

  @override
  String mode08ReasonNegativeWithEcu(String block, String ecu, String nrc) {
    return 'Réponse négative pour le bloc $block de $ecu (NRC $nrc)';
  }

  @override
  String mode08ReasonNegative(String block, String nrc) {
    return 'Réponse négative pour le bloc $block (NRC $nrc)';
  }

  @override
  String mode08ReasonMalformedWithEcu(
    String block,
    String ecu,
    String details,
  ) {
    return 'Réponse mal formée pour le bloc $block de $ecu : $details';
  }

  @override
  String mode08ReasonMalformed(String block, String details) {
    return 'Réponse mal formée pour le bloc $block : $details';
  }

  @override
  String mode08ReasonTimeout(String block) {
    return 'Délai de la requête dépassé pour le bloc $block';
  }

  @override
  String get mode08ReasonBudgetExceeded =>
      'Limite de découverte atteinte avant l’interrogation de tous les blocs';

  @override
  String get mode08ReasonSessionDisconnected =>
      'Session déconnectée ou remplacée pendant la découverte';

  @override
  String mode08ReasonUnqueriedAnnounced(String blocks) {
    return 'Blocs annoncés par les ECU mais non interrogés : $blocks';
  }

  @override
  String get mode08ReasonRequiresCanBus =>
      'La découverte des capacités Mode 08 nécessite un bus CAN OBD-II déterminé';

  @override
  String get mode08ReasonUnexpectedExecution =>
      'Réponse d’exécution inattendue à la requête des TID pris en charge';

  @override
  String get pidDetailEmptyTitle => 'Sélectionnez un PID';

  @override
  String get pidDetailEmptyBody =>
      'Choisissez un PID dans la liste pour consulter sa définition et son état en direct.';

  @override
  String get pidDetailRangeLabel => 'Plage';

  @override
  String get pidDetailPriorityLabel => 'Priorité';

  @override
  String pidDetailHeaderDefault(String header) {
    return 'Par défaut ($header)';
  }

  @override
  String get dtcSystemOverview => 'Vue d’ensemble du système';

  @override
  String get dtcPartialObservationBadge => 'Analyse partielle';

  @override
  String get dtcPartialObservationBody =>
      'Ce code défaut a été lu, mais l’analyse de cette catégorie ne s’est pas terminée sur tous les calculateurs.';

  @override
  String get dtcLinkedFreezeFrameTitle => 'Trame figée associée';

  @override
  String get dtcNoLinkedFreezeFrame =>
      'Cette analyse ne contient aucune trame figée pouvant être associée en toute sécurité à ce code défaut et à ce calculateur.';

  @override
  String get performanceGuideTitle => 'Guide du test d’accélération';

  @override
  String get performanceGuideStep1 =>
      '1. Choisissez une vitesse cible, puis armez le chronomètre';

  @override
  String get performanceGuideStep2 =>
      '2. Immobilisez complètement le véhicule et attendez que le test soit prêt';

  @override
  String get performanceGuideStep3 =>
      '3. Commencez à accélérer ; le chronométrage démarre automatiquement dès qu’un mouvement est détecté';

  @override
  String get performanceGuideStep4 =>
      '4. Atteignez la vitesse cible pour terminer le test';

  @override
  String get performanceRecordingTrace =>
      'Accélération... enregistrement de la courbe de vitesse';

  @override
  String get performanceNoAnalysisTitle => 'Aucune donnée d’analyse';

  @override
  String get performanceNoAnalysisBody =>
      'Ce passage s’est arrêté avant qu’assez d’échantillons de vitesse aient été enregistrés pour construire une courbe ou des temps partiels.';

  @override
  String get connectActivityReconnectingAutomatically =>
      'L’adaptateur a cessé de répondre. Reconnexion automatique…';
}
