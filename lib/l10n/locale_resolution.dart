/// App locale preference and resolution. Pure functions — no Flutter widgets,
/// no OBD, no SharedPreferences.
///
/// UI languages: English, Traditional and Simplified Chinese, German, Japanese,
/// Korean, Spanish, French, Brazilian Portuguese, Italian and Dutch.
/// German was machine-translated and corrected by hand. The eight newer
/// translations require mechanical checks and a second-model hedge review;
/// none claims a native speaker's reading on a screen. See docs/i18n/README.md.
library;

import 'package:flutter/widgets.dart';

enum LocalePreference {
  system,
  english,
  traditionalChinese,
  german,
  japanese,
  korean,
  spanish,
  french,
  brazilianPortuguese,
  simplifiedChinese,
  italian,
  dutch,
}

const kLocalePreferenceKey = 'locale_preference_v1';

const englishLocale = Locale('en');
const traditionalChineseLocale = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hant',
);
const germanLocale = Locale('de');
const japaneseLocale = Locale('ja');
const koreanLocale = Locale('ko');
const spanishLocale = Locale('es');
const frenchLocale = Locale('fr');
const brazilianPortugueseLocale = Locale('pt');
const simplifiedChineseLocale = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hans',
);
const italianLocale = Locale('it');
const dutchLocale = Locale('nl');

const supportedAppLocales = <Locale>[
  englishLocale,
  traditionalChineseLocale,
  germanLocale,
  japaneseLocale,
  koreanLocale,
  spanishLocale,
  frenchLocale,
  brazilianPortugueseLocale,
  simplifiedChineseLocale,
  italianLocale,
  dutchLocale,
];

/// The stored ids are a format, not an implementation detail: they are written
/// to disk under [kLocalePreferenceKey] and read back by whatever build is
/// installed next. An id this build does not know — one written by a newer
/// build, then downgraded — falls back to [LocalePreference.system] rather than
/// throwing or resolving to some other language.
LocalePreference localePreferenceFromStored(Object? raw) {
  if (raw is! String) return LocalePreference.system;
  return switch (raw) {
    'en' => LocalePreference.english,
    'zh_Hant' => LocalePreference.traditionalChinese,
    'de' => LocalePreference.german,
    'ja' => LocalePreference.japanese,
    'ko' => LocalePreference.korean,
    'es' => LocalePreference.spanish,
    'fr' => LocalePreference.french,
    'pt' => LocalePreference.brazilianPortuguese,
    'zh_Hans' => LocalePreference.simplifiedChinese,
    'it' => LocalePreference.italian,
    'nl' => LocalePreference.dutch,
    'system' => LocalePreference.system,
    _ => LocalePreference.system,
  };
}

String localePreferenceToStored(LocalePreference preference) {
  return switch (preference) {
    LocalePreference.system => 'system',
    LocalePreference.english => 'en',
    LocalePreference.traditionalChinese => 'zh_Hant',
    LocalePreference.german => 'de',
    LocalePreference.japanese => 'ja',
    LocalePreference.korean => 'ko',
    LocalePreference.spanish => 'es',
    LocalePreference.french => 'fr',
    LocalePreference.brazilianPortuguese => 'pt',
    LocalePreference.simplifiedChinese => 'zh_Hans',
    LocalePreference.italian => 'it',
    LocalePreference.dutch => 'nl',
  };
}

/// Resolve the UI locale. An explicit preference wins. [system] walks
/// [deviceLocales] in order and never writes the computed result back.
Locale resolveAppLocale({
  required LocalePreference preference,
  required List<Locale> deviceLocales,
}) {
  return switch (preference) {
    LocalePreference.english => englishLocale,
    LocalePreference.traditionalChinese => traditionalChineseLocale,
    LocalePreference.german => germanLocale,
    LocalePreference.japanese => japaneseLocale,
    LocalePreference.korean => koreanLocale,
    LocalePreference.spanish => spanishLocale,
    LocalePreference.french => frenchLocale,
    LocalePreference.brazilianPortuguese => brazilianPortugueseLocale,
    LocalePreference.simplifiedChinese => simplifiedChineseLocale,
    LocalePreference.italian => italianLocale,
    LocalePreference.dutch => dutchLocale,
    LocalePreference.system => resolveSystemLocale(deviceLocales),
  };
}

Locale resolveSystemLocale(List<Locale> deviceLocales) {
  for (final locale in deviceLocales) {
    final mapped = mapDeviceLocale(locale);
    if (mapped != null) return mapped;
  }
  return englishLocale;
}

/// Returns a supported UI locale, or null to try the next device locale.
///
/// Script beats a conflicting region: `zh-Hans-TW` is still Hans.
Locale? mapDeviceLocale(Locale locale) {
  final language = locale.languageCode.toLowerCase();
  if (language == 'en') return englishLocale;
  // Regional variants share one bundle; all pt regions use Brazilian content.
  if (language == 'de') return germanLocale;
  if (language == 'ja') return japaneseLocale;
  if (language == 'ko') return koreanLocale;
  if (language == 'es') return spanishLocale;
  if (language == 'fr') return frenchLocale;
  if (language == 'pt') return brazilianPortugueseLocale;
  if (language == 'it') return italianLocale;
  if (language == 'nl') return dutchLocale;
  if (language != 'zh') return null;

  final script = locale.scriptCode?.toLowerCase();
  if (script == 'hans') return simplifiedChineseLocale;
  if (script == 'hant') return traditionalChineseLocale;

  final country = locale.countryCode?.toUpperCase();
  if (country == 'CN' || country == 'SG') return simplifiedChineseLocale;
  if (country == 'TW' || country == 'HK' || country == 'MO') {
    return traditionalChineseLocale;
  }
  if (country == null || country.isEmpty) {
    // Preserve the existing bare `zh` fallback to Traditional Chinese.
    return traditionalChineseLocale;
  }
  // Other regions without a recognized script are not a supported match.
  return null;
}
