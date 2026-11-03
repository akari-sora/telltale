// Guards the ARB files against the failure that no other test can see: a key
// that exists in one language and not in another.
//
// `gen-l10n` does not fail on a missing translation — it falls back to the
// template locale. So a forgotten Traditional Chinese entry ships as English
// inside an otherwise Chinese screen, and every widget test still passes,
// because the widget renders *something*. The suite would agree with itself.
//
// `app_zh.arb` is a byte-for-byte fallback for a plain `zh` device locale that
// carries no script subtag. It is not a second translation and must never
// become one: two Chinese files free to drift are two sources of truth.
//
// German is a machine translation corrected by hand (docs/i18n/README.md). That
// changes what a reviewer can promise about its sentences; it changes nothing
// about what this file checks, because keys, arguments and empty values are
// exactly the failures a translator — human or machine — cannot see and the app
// will not report.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:torque_obd/l10n/generated/app_localizations.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';

Map<String, dynamic> _readArb(String name) {
  final file = File('lib/l10n/$name');
  if (!file.existsSync()) {
    // Thrown, not expect()ed: this runs while the file is being loaded, before
    // any test body exists to own the failure.
    throw StateError('lib/l10n/$name is missing; l10n.yaml still expects it');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// ARB placeholder names for one message, or an empty set when it takes none.
Set<String> _placeholders(Map<String, dynamic> arb, String key) {
  final meta = arb['@$key'];
  if (meta is! Map) return <String>{};
  final placeholders = meta['placeholders'];
  if (placeholders is! Map) return <String>{};
  return placeholders.keys.map((k) => k.toString()).toSet();
}

void main() {
  final en = _readArb('app_en.arb');
  final zhHant = _readArb('app_zh_Hant.arb');
  final zh = _readArb('app_zh.arb');
  final de = _readArb('app_de.arb');

  /// Every shipped locale except the template, by file name. `app_zh.arb` is in
  /// here too: it is a copy rather than a translation, but a key missing from a
  /// copy still ships as English on a plain `zh` device.
  final shipped = <String, Map<String, dynamic>>{
    'app_zh_Hant.arb': zhHant,
    'app_zh.arb': zh,
    'app_de.arb': de,
    'app_ja.arb': _readArb('app_ja.arb'),
    'app_ko.arb': _readArb('app_ko.arb'),
    'app_es.arb': _readArb('app_es.arb'),
    'app_fr.arb': _readArb('app_fr.arb'),
    'app_pt.arb': _readArb('app_pt.arb'),
    'app_zh_Hans.arb': _readArb('app_zh_Hans.arb'),
    'app_it.arb': _readArb('app_it.arb'),
    'app_nl.arb': _readArb('app_nl.arb'),
  };

  /// The template and everything that has to agree with it.
  final everyLocale = <String, Map<String, dynamic>>{
    'app_en.arb': en,
    ...shipped,
  };

  /// Locales that carry their own copy. `app_zh.arb` is excluded because it is
  /// checked against `app_zh_Hant.arb` further down instead.
  final translations = Map<String, Map<String, dynamic>>.from(shipped)
    ..remove('app_zh.arb');

  test('every locale declares the same message keys', () {
    final enKeys = _messageKeys(en);
    expect(enKeys, isNotEmpty);
    for (final entry in shipped.entries) {
      expect(
        _messageKeys(entry.value),
        enKeys,
        reason: '${entry.key} and app_en.arb disagree on which messages exist',
      );
    }
  });

  test('no message is empty', () {
    for (final key in _messageKeys(en)) {
      for (final entry in everyLocale.entries) {
        final value = entry.value[key];
        expect(
          value,
          isA<String>(),
          reason: '${entry.key} key "$key" is not a string',
        );
        expect(
          (value as String).trim(),
          isNotEmpty,
          reason: '${entry.key} key "$key" is empty',
        );
      }
    }
  });

  test('sentences that exist to contradict each other still do', () {
    // Cheaper than one assertion per sentence, and harder to defeat: for a
    // binary readout, an inverted translation is only visible as a collision
    // with its opposite. A reviewer inverted `dtcMilOff` to 'The fault lamp is
    // lit' and the whole suite stayed green — both branches of
    // `dtc_screen.dart:1072` would have said the same thing about a warning
    // lamp, in an app whose reason for existing is that a plausible wrong
    // statement is worse than none.
    //
    // Each pair is chosen at a site where the code picks one or the other, so
    // collapsing them is always a defect and never a style choice.
    const mustDiffer = <List<String>>[
      // dtc_screen.dart:1072 — `summary.milOn ? … : …`, a physical lamp.
      ['dtcMilOn', 'dtcMilOff'],
      // Two different handshake outcomes: the adapter refused the command, or
      // the vehicle never answered it. Different faults, different next steps.
      ['handshakeNoteEcuSilent', 'handshakeNoteNotAcknowledged'],
      // "only the estimate is affected" is not "only this item is affected".
      ['datumNextStepEstimateOnly', 'datumNextStepOtherReadings'],
      // A datum you may not read as a value, versus one you may.
      ['datumNextStepRawOnly', 'datumNextStepOtherReadings'],
      // Emissions readiness: complete-and-clean is not partially-clean.
      ['dtcCompleteCleanTitle', 'dtcVerdictPartialClean'],
    ];
    final collapsed = <String>[];
    for (final locale in everyLocale.values) {
      for (final pair in mustDiffer) {
        final a = locale[pair[0]];
        final b = locale[pair[1]];
        if (a == null || b == null) {
          collapsed.add('${pair.join(' / ')} — a key is missing');
          continue;
        }
        if (a == b) collapsed.add('${pair.join(' / ')} both say "$a"');
      }
    }
    expect(
      collapsed,
      isEmpty,
      reason:
          'These pairs are chosen from one another at a call site, so a reader '
          'who sees the wrong one is told the opposite of the truth:\n'
          '${collapsed.join('\n')}',
    );
  });

  test('no message is left as its English source in a translation', () {
    // The failure gen-l10n cannot report. It does not fail on a missing
    // translation — it falls back to the template — so a forgotten entry ships
    // as English inside an otherwise Chinese screen, and every widget test
    // still passes because the widget rendered something.
    //
    // A few entries are identical in every language on purpose. They are listed
    // here by name so that adding another is a decision somebody makes rather
    // than a translation somebody forgot.
    const identicalOnPurpose = <String>{
      // A product name is not translated.
      'appTitle',
      // The language control names the languages in their own scripts, so a
      // reader who cannot read the current one can still find their way out.
      'languageSectionTitle',
      // An SAE J1979 term, on docs/i18n/do-not-translate.md. Somebody who has
      // met PIDs knows the acronym, and somebody who has not is not helped by a
      // translation of it that no other tool or datasheet uses.
      'navPid',
      // Placeholders and a unit. Units are not a language: MiB is MiB in both,
      // and translating it would make two exports incomparable.
      'telemetryLibraryBytes',
      // The three transport product names, all on
      // docs/i18n/do-not-translate.md. They are ARB entries rather than
      // literals so that the rule is enforced here — a future translation of
      // "Wi-Fi" fails this test instead of shipping — and the fourth tile,
      // connectTransportDemoTitle, is deliberately NOT on this list because
      // 'Demo 模擬器' is copy and does get translated.
      'connectTransportBleTitle',
      'connectTransportClassicTitle',
      'connectTransportWifiTitle',
      // Engineering symbols in the estimate assumptions. Cd is Cd on every
      // drag chart ever printed; AFR and VE are the abbreviations a J1979
      // datasheet uses. Expanding them into Chinese words would make the
      // details dialog harder to check against the sources it cites, which is
      // the only reason that dialog exists.
      'assumptionFieldDragCoefficient',
      'assumptionFieldStoichAfr',
      'assumptionFieldVolumetricEfficiency',
      // Two placeholders and a space. There is nothing here to translate; the
      // bracketed form, assumptionWithOrigin, is where the punctuation differs
      // and it is NOT on this list.
      'assumptionWithoutOrigin',
      // Arithmetic. The power formula is symbols and identifier names end to
      // end, with no connecting prose to render — unlike datumFormulaFuelRate,
      // which has a sentence in the middle and is therefore not listed here.
      'datumFormulaHorsepower',
    };
    // Some entries land on the English word in one language and not in another,
    // and that is a fact about the language rather than a lapse: German writes
    // Dashboard, Trends, Pause, Diesel and Port, and its separators and
    // placeholder-only strings have nothing in them to translate. Listed per
    // locale so each one is a decision made about that language.
    const coincidental = <String, Set<String>>{
      'app_zh_Hant.arb': <String>{},
      // Reviewed packet exceptions, with each identical value justified below.
      'app_ja.arb': <String>{
        // Shopee is the brand/storefront name used in Japanese and international markets (unlike
        // Taiwan's 蝦皮) and is also listed in do-not-translate.md.
        'recommendedPurchaseStoreShopee',
        // Bluetooth is a standard technical/trademarked name used unchanged in Japanese
        // Android/Wear OS system UI.
        'wearPermissionBluetooth',
        // Bluetooth LE is a transport standard/product name kept in English across the app
        // (matching connectTransportBleTitle).
        'connectionLayerBle',
        // Bluetooth Classic is a transport standard/product name kept in English across the app
        // (matching connectTransportClassicTitle).
        'connectionLayerClassic',
        // Wi-Fi is a standard trademarked networking term used unchanged in Japanese (matching
        // connectTransportWifiTitle).
        'connectionLayerWifi',
      },
      'app_ko.arb': <String>{
        // Placeholder-only template ({label} (Mode {mode}) · {count}) where Mode is a DNT token
        // and Korean uses ASCII parentheses and middle dot
        'dtcGroupHeader',
        // Korean uses the standard ASCII comma and space (, ) to join inline fault-code and
        // controller lists
        'dtcListSeparator',
        // Placeholder-only template ({label} (Mode {mode}): {message}) where Mode is a DNT token
        // and Korean uses ASCII parentheses and colon-space
        'dtcReadFailureDetail',
        // Korean uses the standard ASCII comma and space (, ) to separate inline machine tokens
        'pidListSeparator',
        // Korean uses the standard ASCII comma and space (, ) to join unconfirmed field names
        'powertrainFieldListSeparator',
        // Shopee is the storefront brand name used in international/Korean references outside
        // Taiwan
        'recommendedPurchaseStoreShopee',
        // Korean screen-reader labels use the standard ASCII comma and space (, ) rather than
        // fullwidth punctuation
        'semanticsFieldSeparator',
        // Korean uses the standard ASCII comma and space (, ) to join runtime label lists
        'settingsListSeparator',
        // Korean uses a period and space ({first}. {second}) between clauses in composed screen-
        // reader labels
        'telemetryPhraseJoin',
        // Korean uses an ASCII period and space ({first}. {second}) to join complete sentences
        'telemetrySentenceJoin',
        // LPG is the universal everyday and technical term for liquefied petroleum gas in South
        // Korea (LPG 충전소 / LPG 차량)
        'fuelTypeLpg',
        // Placeholder-only template ({field} {value} ({origin})) where Korean uses standard ASCII
        // parentheses with a leading space
        'assumptionWithOrigin',
        // Korean uses an ASCII semicolon and space (; ) to separate inline assumption items
        'assumptionSeparator',
        // Matches connectTransportBleTitle (in IDENTICAL_ON_PURPOSE); Bluetooth LE is standard
        // technical notation in Korean
        'connectionLayerBle',
        // Matches connectTransportClassicTitle (in IDENTICAL_ON_PURPOSE); Bluetooth Classic is
        // standard technical notation in Korean
        'connectionLayerClassic',
        // Matches connectTransportWifiTitle (in IDENTICAL_ON_PURPOSE); Wi-Fi is standard notation
        // in Korean UI
        'connectionLayerWifi',
      },
      'app_es.arb': <String>{
        // UI badge token kept as Experimental (loanword, matches Experimental · unverified pattern
        // elsewhere)
        'datumBadgeExperimental',
        // Format token {system} · {category} punctuation identical
        'dtcGroupHeader',
        // list separator punctuation
        'dtcListSeparator',
        // placeholder-only / punctuation structure
        'dtcReadFailureDetail',
        // list separator punctuation
        'pidListSeparator',
        // list separator punctuation
        'powertrainFieldListSeparator',
        // Shopee is a do-not-translate store name
        'recommendedPurchaseStoreShopee',
        // separator punctuation
        'semanticsFieldSeparator',
        // section label uses Experimental loanword
        'settingsExperimentalSection',
        // list separator punctuation
        'settingsListSeparator',
        // phrase join punctuation
        'telemetryPhraseJoin',
        // sentence join punctuation
        'telemetrySentenceJoin',
        // byte/bytes unit words identical in Spanish for this scale
        'transcriptSizeBytes',
        // Bluetooth is do-not-translate
        'wearPermissionBluetooth',
        // skin id/name Minimal kept
        'gaugeSkinMinimal',
        // LPG acronym
        'fuelTypeLpg',
        // intentionally identical to English (unit, acronym, separator, or borrowed term)
        'assumptionWithOrigin',
        // intentionally identical to English (unit, acronym, separator, or borrowed term)
        'assumptionSeparator',
        // intentionally identical to English (unit, acronym, separator, or borrowed term)
        'connectionLayerSoftware',
        // intentionally identical to English (unit, acronym, separator, or borrowed term)
        'connectionLayerDemo',
        // intentionally identical to English (unit, acronym, separator, or borrowed term)
        'connectionLayerBle',
        // intentionally identical to English (unit, acronym, separator, or borrowed term)
        'connectionLayerClassic',
        // Wi-Fi do-not-translate
        'connectionLayerWifi',
        // ICE acronym
        'settingsCaClassIce',
        // BEV acronym
        'settingsCaClassBev',
        // PHEV acronym
        'settingsCaClassPhev',
      },
      'app_fr.arb': <String>{
        // Port is the standard French networking term as well as the English one.
        'connectWifiPortLabel',
        // The value consists only of unchanged placeholders, Mode and punctuation.
        'dtcGroupHeader',
        // Comma and space are also the French list separator here.
        'dtcListSeparator',
        // Code/codes and both numeric ICU branches are identical in French.
        'dtcTotalCodes',
        // Expression is the correct French mathematical term.
        'pidEditorFieldEquation',
        // Maximum is the same French word.
        'pidEditorFieldMax',
        // Minimum is the same French word.
        'pidEditorFieldMin',
        // Mode is also French and PID is an identifier.
        'pidEditorFieldModeAndPid',
        // Comma and space are also the French list separator here.
        'pidListSeparator',
        // Comma and space are also the French list separator here.
        'powertrainFieldListSeparator',
        // Shopee is the protected proper name of the store.
        'recommendedPurchaseStoreShopee',
        // This is a punctuation separator, independent of language.
        'semanticsFieldSeparator',
        // The count placeholder is unchanged and cyl is also the standard French abbreviation for
        // cylindres.
        'settingsEpaCylinders',
        // Comma and space are also the French list separator here.
        'settingsListSeparator',
        // Pause is the correct French control label.
        'telemetryPause',
        // This punctuation join is also correct in French.
        'telemetryPhraseJoin',
        // This punctuation join is also correct in French.
        'telemetrySentenceJoin',
        // Bluetooth is a protected product/transport name.
        'wearPermissionBluetooth',
        // Permanent is the same French adjective for a code.
        'dtcKindPermanent',
        // Transmission is the same French automotive term.
        'dtcSubsystemTransmission',
        // Minimal is the same French adjective/name for this skin.
        'gaugeSkinMinimal',
        // Diesel is the same French fuel name.
        'fuelTypeDiesel',
        // The value consists only of unchanged placeholders and punctuation.
        'assumptionWithOrigin',
        // Transport is also the French technical term for this layer.
        'connectionLayerTransport',
        // Demo is the simulator mode identifier.
        'connectionLayerDemo',
        // Bluetooth LE is the protected transport product name.
        'connectionLayerBle',
        // Bluetooth Classic is the protected transport product name.
        'connectionLayerClassic',
        // Wi-Fi is the protected transport name.
        'connectionLayerWifi',
        // Canada has the same French name and NRCan is the dataset agency identifier retained from
        // the source.
        'settingsCatalogMarketCa',
        // ICE is the retained powertrain classification identifier.
        'settingsCaClassIce',
        // BEV is the protected powertrain classification identifier.
        'settingsCaClassBev',
        // PHEV is the protected powertrain classification identifier.
        'settingsCaClassPhev',
      },
      'app_pt.arb': <String>{
        // UI badge loanword Experimental kept
        'datumBadgeExperimental',
        // short gauge label Torque (also product-family word) kept
        'derivedTorque',
        // {label} (Mode {mode}) · {count} format kept
        'dtcGroupHeader',
        // list separator ", " kept
        'dtcListSeparator',
        // {label} (Mode {mode}): {message} format kept
        'dtcReadFailureDetail',
        // Mode {mode} PID {pid} field pattern kept
        'pidEditorFieldModeAndPid',
        // list separator kept
        'pidListSeparator',
        // list separator kept
        'powertrainFieldListSeparator',
        // Shopee product/store name kept
        'recommendedPurchaseStoreShopee',
        // accessibility separator kept
        'semanticsFieldSeparator',
        // Taiwan market code Tw kept as short label
        'settingsCatalogMarketTw',
        // section title Experimental kept
        'settingsExperimentalSection',
        // list separator kept
        'settingsListSeparator',
        // phrase join token kept
        'telemetryPhraseJoin',
        // sentence join token kept
        'telemetrySentenceJoin',
        // {size} B unit format kept
        'transcriptSizeBytes',
        // Bluetooth permission label kept
        'wearPermissionBluetooth',
        // skin name Cluster kept
        'gaugeSkinCluster',
        // fuel type Diesel kept
        'fuelTypeDiesel',
        // {field} {value} format kept
        'assumptionWithOrigin',
        // separator kept
        'assumptionSeparator',
        // layer label Software kept
        'connectionLayerSoftware',
        // layer label Demo kept
        'connectionLayerDemo',
        // BLE transport short label kept
        'connectionLayerBle',
        // Classic transport short label kept
        'connectionLayerClassic',
        // Wi-Fi transport short label kept
        'connectionLayerWifi',
        // vehicle class ICE kept
        'settingsCaClassIce',
        // vehicle class BEV kept
        'settingsCaClassBev',
        // vehicle class PHEV kept
        'settingsCaClassPhev',
      },
      'app_zh_Hans.arb': <String>{
        // Store brand self-name; DNT requires Shopee byte-identical (not 虾皮).
        'recommendedPurchaseStoreShopee',
        // Vehicle class code BEV; DNT token, kept as English code.
        'settingsCaClassBev',
        // Vehicle class code PHEV; DNT token, kept as English code.
        'settingsCaClassPhev',
        // Transport layer name: the BLE product name is on do-not-translate.md and the label
        // carries no other words.
        'connectionLayerBle',
      },
      'app_it.arb': <String>{
        // Formula is also the Italian noun for formula.
        'datumStatusFormula',
        // Controller is established Italian technical usage; the placeholder is unchanged.
        'dtcControllerLabel',
        // Only translated label/count placeholders, the protected Mode identifier and punctuation.
        'dtcGroupHeader',
        // The source separator is conventional Italian punctuation and spacing.
        'dtcListSeparator',
        // Only translated placeholders, the protected Mode identifier and punctuation.
        'dtcReadFailureDetail',
        // Formula is also the Italian noun for formula.
        'pidEditorSectionFormula',
        // The source separator is conventional Italian punctuation and spacing.
        'pidListSeparator',
        // The source separator is conventional Italian punctuation and spacing.
        'powertrainFieldListSeparator',
        // Shopee is a protected marketplace name.
        'recommendedPurchaseStoreShopee',
        // The source separator is conventional Italian punctuation and spacing.
        'semanticsFieldSeparator',
        // The source separator is conventional Italian punctuation and spacing.
        'settingsListSeparator',
        // Only translated sentence placeholders with conventional Italian sentence punctuation.
        'telemetryPhraseJoin',
        // Only translated sentence placeholders with conventional Italian sentence punctuation.
        'telemetrySentenceJoin',
        // Bluetooth is a protected technology name.
        'wearPermissionBluetooth',
        // Diesel is also the established Italian fuel name.
        'fuelTypeDiesel',
        // Only placeholders, spacing and Italian-compatible parentheses.
        'assumptionWithOrigin',
        // The source separator is conventional Italian punctuation and spacing.
        'assumptionSeparator',
        // Software is an established Italian borrowing.
        'connectionLayerSoftware',
        // Demo is an established Italian borrowing.
        'connectionLayerDemo',
        // Bluetooth LE is a protected transport name.
        'connectionLayerBle',
        // Bluetooth Classic is a protected transport name.
        'connectionLayerClassic',
        // Wi-Fi is a protected technology name.
        'connectionLayerWifi',
        // Canada is also the Italian country name; NRCan is the authority acronym.
        'settingsCatalogMarketCa',
        // ICE is the source catalog class identifier.
        'settingsCaClassIce',
        // BEV is a protected powertrain class identifier.
        'settingsCaClassBev',
        // PHEV is a protected powertrain class identifier.
        'settingsCaClassPhev',
        // Standard is also the Italian noun; the placeholder is unchanged.
        'serviceRecipesStandard',
      },
      'app_nl.arb': <String>{
        // 'Trends' is the standard Dutch plural noun for trends/time-series charts.
        'dashboardWorkspaceTrends',
        // Template consisting purely of placeholders and the do-not-translate OBD token 'Mode'.
        'dtcGroupHeader',
        // Standard Dutch inline list separator (comma followed by space, matching Latin-script
        // punctuation).
        'dtcListSeparator',
        // Template consisting purely of placeholders, colon punctuation, and the do-not-translate
        // OBD token 'Mode'.
        'dtcReadFailureDetail',
        // 'code' (singular) and 'codes' (plural) are standard Dutch spelling.
        'dtcTotalCodes',
        // 'Dashboard' is the standard Dutch automotive and software UI term.
        'navDashboard',
        // 'Maximum' is the standard Dutch noun for maximum value.
        'pidEditorFieldMax',
        // 'Minimum' is the standard Dutch noun for minimum value.
        'pidEditorFieldMin',
        // Consists solely of the do-not-translate OBD tokens 'Mode' and 'PID' joined by '+'.
        'pidEditorFieldModeAndPid',
        // Standard Dutch inline list separator (comma followed by space).
        'pidListSeparator',
        // Standard Dutch inline list separator (comma followed by space).
        'powertrainFieldListSeparator',
        // 'Model' is the standard Dutch noun for vehicle model.
        'powertrainFieldModel',
        // 'Variant' is the standard Dutch noun for vehicle variant/trim.
        'powertrainFieldVariant',
        // 'Model' is standard Dutch and 'NCC' is the untranslated regulatory certification mark.
        'recommendedPurchaseModelLine',
        // 'Shopee' is the storefront's proper brand name outside Taiwan.
        'recommendedPurchaseStoreShopee',
        // Standard Dutch screen-reader field separator (comma followed by space).
        'semanticsFieldSeparator',
        // 'Model' is the standard Dutch noun for vehicle model.
        'settingsEpaModel',
        // Standard Dutch inline list separator (comma followed by space).
        'settingsListSeparator',
        // Standard Dutch period-and-space separator template joining two phrases.
        'telemetryPhraseJoin',
        // Standard Dutch period-and-space separator template joining two sentences.
        'telemetrySentenceJoin',
        // 'byte' (singular) and 'bytes' (plural) are standard Dutch spelling.
        'transcriptSizeBytes',
        // 'Bluetooth' is a do-not-translate wireless standard proper noun.
        'wearPermissionBluetooth',
        // 'Permanent' is the standard Dutch adjective for permanent fault codes.
        'dtcKindPermanent',
        // 'Chassis' is the standard Dutch automotive term for the chassis system.
        'dtcSystemChassis',
        // 'Cluster' is the standard Dutch instrument-cluster skin name.
        'gaugeSkinCluster',
        // 'Diesel' is the standard Dutch noun for diesel fuel.
        'fuelTypeDiesel',
        // 'LPG' is the standard Dutch abbreviation for liquefied petroleum gas (autogas).
        'fuelTypeLpg',
        // Standard Dutch parenthetical formatting template with ASCII parentheses.
        'assumptionWithOrigin',
        // Standard Dutch semicolon-and-space list separator.
        'assumptionSeparator',
        // 'Protocol' is the standard Dutch technical noun.
        'connectionLayerProtocol',
        // 'Software' is the standard Dutch technical noun.
        'connectionLayerSoftware',
        // 'Demo' is the standard Dutch short label for demonstration/simulation mode.
        'connectionLayerDemo',
        // 'Bluetooth LE' is a do-not-translate technical standard name.
        'connectionLayerBle',
        // 'Bluetooth Classic' is a do-not-translate technical standard name.
        'connectionLayerClassic',
        // 'Wi-Fi' is a do-not-translate technical standard name.
        'connectionLayerWifi',
        // 'Canada' is spelled identically in Dutch and 'NRCan' is the official agency acronym.
        'settingsCatalogMarketCa',
        // Standard automotive drivetrain class acronym (ICE, glossed as Verbrandingsmotor (ICE) in
        // settingsCaPickerScope) kept compact for segmented chip.
        'settingsCaClassIce',
        // Do-not-translate drivetrain class acronym (BEV in docs/i18n/do-not-translate.md,
        // glossed in settingsCaPickerScope).
        'settingsCaClassBev',
        // Do-not-translate drivetrain class acronym (PHEV in docs/i18n/do-not-translate.md,
        // glossed in settingsCaPickerScope).
        'settingsCaClassPhev',
      },

      'app_de.arb': <String>{
        // German uses the English word.
        'connectWifiPortLabel',
        'dashboardWorkspaceTrends',
        'navDashboard',
        'performanceSplitsHeading',
        'telemetryPause',
        'dtcKindPermanent',
        'gaugeSkinCluster',
        'gaugeSkinMinimal',
        'fuelTypeDiesel',
        'fuelTypeLpg',
        'pidEditorFieldName',
        // Punctuation, placeholders, and tokens from
        // docs/i18n/do-not-translate.md — nothing in them is language.
        'dtcGroupHeader',
        'dtcReadFailureDetail',
        'pidEditorFieldModeAndPid',
        'wearPermissionBluetooth',
        'recommendedPurchaseStoreShopee',
        'assumptionWithOrigin',
        'assumptionSeparator',
        'dtcListSeparator',
        'pidListSeparator',
        'powertrainFieldListSeparator',
        'semanticsFieldSeparator',
        'settingsListSeparator',
        'telemetryPhraseJoin',
        'telemetrySentenceJoin',
      },
    };
    expect(coincidental.keys.toSet(), translations.keys.toSet());
    for (final entry in translations.entries) {
      final allowed = coincidental[entry.key] ?? const <String>{};
      final untranslated = <String>[];
      for (final key in _messageKeys(en)) {
        if (identicalOnPurpose.contains(key)) continue;
        if (allowed.contains(key)) continue;
        if (entry.value[key] == en[key]) untranslated.add(key);
      }
      expect(
        untranslated,
        isEmpty,
        reason:
            '${entry.key} carries the English source verbatim for: '
            '${untranslated.join(", ")}',
      );
      // A stale allowance is its own defect: it silently exempts a key that has
      // since been translated, so the next regression there goes unreported.
      final stale = allowed
          .where((key) => entry.value[key] != en[key])
          .toList();
      expect(
        stale,
        isEmpty,
        reason:
            '${entry.key} no longer matches English for ${stale.join(", ")} — '
            'remove them from coincidental',
      );
    }
  });

  test('placeholders match across locales, by name', () {
    for (final key in _messageKeys(en)) {
      final expected = _placeholders(en, key);
      for (final entry in shipped.entries) {
        final actual = _placeholders(entry.value, key);
        // A translation may omit the metadata block and inherit the template's
        // placeholders; it may not declare a *different* set.
        if (actual.isEmpty && expected.isNotEmpty) continue;
        expect(
          actual,
          expected,
          reason:
              '${entry.key} key "$key" declares placeholders $actual, template declares $expected',
        );
      }
    }
  });

  test('every placeholder named in a message is declared for that message', () {
    // Strip ICU argument blocks before scanning. `{count, plural, other{items}}`
    // contains `{items}`, which is a branch body and not a placeholder; a naive
    // scan reports the first legitimate plural message as interpolating an
    // undeclared `items` and blames the template. gen-l10n accepts the message,
    // so the test would be wrong and the author would edit good data.
    final icuBlock = RegExp(
      r'\{\s*\w+\s*,\s*(?:plural|select|selectordinal)\s*,[\s\S]*\}',
    );
    final reference = RegExp(r'\{(\w+)\}');
    for (final entry in everyLocale.entries) {
      for (final key in _messageKeys(entry.value)) {
        final value = entry.value[key];
        if (value is! String) continue;
        final simpleArguments = value.replaceAll(icuBlock, '');
        final used = reference
            .allMatches(simpleArguments)
            .map((m) => m.group(1)!)
            .toSet();
        if (used.isEmpty) continue;
        final declared = _placeholders(entry.value, key).isEmpty
            ? _placeholders(en, key)
            : _placeholders(entry.value, key);
        expect(
          used.difference(declared),
          isEmpty,
          reason:
              '${entry.key} key "$key" interpolates ${used.difference(declared)} '
              'but declares $declared',
        );
      }
    }
  });

  test('app_zh.arb is a fallback copy of app_zh_Hant.arb, not a translation', () {
    for (final key in _messageKeys(zhHant)) {
      expect(
        zh[key],
        zhHant[key],
        reason:
            'app_zh.arb key "$key" has drifted from app_zh_Hant.arb. The plain-zh '
            'file exists only so a device reporting "zh" with no script subtag '
            'still reads Traditional Chinese; it is not a place to write '
            'different copy; Simplified Chinese lives in app_zh_Hans.arb.',
      );
    }
  });

  test('every shipped locale resolves to a bundle instead of throwing', () {
    for (final locale in supportedAppLocales) {
      expect(
        () => lookupAppLocalizations(locale),
        returnsNormally,
        reason: '$locale is offered in supportedAppLocales but has no bundle',
      );
    }
    // Every explicit picker preference must have a generated bundle.
    for (final preference in LocalePreference.values) {
      final locale = resolveAppLocale(
        preference: preference,
        deviceLocales: const [],
      );
      expect(
        () => lookupAppLocalizations(locale),
        returnsNormally,
        reason: '$preference resolves to $locale, which has no bundle',
      );
    }
  });
}
