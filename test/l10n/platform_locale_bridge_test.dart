/// Software path for #43: OS vs stored migration and language-switch guard.
///
/// These tests drive [planSync] and [AppLocalesSynchronizer] with a fake OS.
/// They are not an Android process recreation.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torque_obd/core/app_locales_platform.dart';
import 'package:torque_obd/l10n/app_locales_sync.dart';
import 'package:torque_obd/l10n/locale_resolution.dart';
import 'package:torque_obd/l10n/generated/app_localizations_en.dart';
import 'package:torque_obd/l10n/generated/app_localizations_zh.dart';
import 'package:torque_obd/state/app_locales_synchronizer.dart';
import 'package:torque_obd/state/language_switch_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every stored preference hands off a configured OS language tag', () {
    final xml = File('android/app/src/main/res/xml/locales_config.xml')
        .readAsStringSync();
    final configured = RegExp(r'android:name="([^"]+)"')
        .allMatches(xml)
        .map((match) => match.group(1)!)
        .toSet();
    final expected = <String, String>{
      'en': 'en',
      'zh_Hant': 'zh-Hant',
      'de': 'de',
      'ja': 'ja',
      'ko': 'ko',
      'es': 'es',
      'fr': 'fr',
      'pt': 'pt-BR',
      'zh_Hans': 'zh-Hans',
      'it': 'it',
      'nl': 'nl',
    };
    expect(configured, expected.values.toSet());
    for (final entry in expected.entries) {
      expect(tagsForStoredId(entry.key), [entry.value]);
      expect(storedIdFromOsTags([entry.value]), entry.key);
      final plan = planSync(
        apiSupported: true,
        alreadyMigrated: false,
        followsSystem: true,
        osOverrideTags: const [],
        storedId: entry.key,
      );
      expect(plan.action, AppLocalesSyncAction.handoffStoredOnce);
      expect(plan.osTagsToWrite, [entry.value]);
    }
  });

  test('regional OS tags and Chinese scripts map to the shipped choices', () {
    final cases = <String, String>{
      'ja-JP': 'ja',
      'ko-KR': 'ko',
      'es-MX': 'es',
      'fr-CA': 'fr',
      'pt-PT': 'pt',
      'pt-BR': 'pt',
      'it-CH': 'it',
      'nl-BE': 'nl',
      'zh': 'zh_Hant',
      'zh-CN': 'zh_Hans',
      'zh-SG': 'zh_Hans',
      'zh-TW': 'zh_Hant',
      'zh-HK': 'zh_Hant',
      'zh-MO': 'zh_Hant',
      'zh-Hans-TW': 'zh_Hans',
      'zh-Hant-CN': 'zh_Hant',
      'zh-Latn': 'zh_Hant',
      'zh-Latn-CN': 'zh_Hans',
      'zh-Latn-SG': 'zh_Hans',
      'zh-Latn-TW': 'zh_Hant',
      'zh-Latn-HK': 'zh_Hant',
      'zh-Latn-MO': 'zh_Hant',
    };
    for (final entry in cases.entries) {
      expect(storedIdFromOsTags([entry.key]), entry.value, reason: entry.key);
    }
    expect(storedIdFromOsTags(['zh-US']), 'system');
    expect(storedIdFromOsTags(['zh-Latn-US']), 'system');
    expect(storedIdFromOsTags(['sv']), 'system');
    expect(storedIdFromOsTags(['pt-BR', 'fr']), 'system');
  });

  test('unknown Chinese script preserves numeric region', () {
    expect(storedIdFromOsTags(['zh-Latn-419']), 'system');
  });

  test('Chinese extensions do not supply a region or script', () {
    expect(storedIdFromOsTags(['zh-Latn-u-nu-hanidec']), 'zh_Hant');
    expect(storedIdFromOsTags(['zh-Latn-CN-u-nu-hanidec']), 'zh_Hans');
    expect(storedIdFromOsTags(['zh-Hans-TW-u-nu-hanidec']), 'zh_Hans');
    expect(storedIdFromOsTags(['zh-u-nu-hanidec']), 'zh_Hant');
  });

  group('planSync first run', () {
    test('API 32 does not write the OS or clobber a stored id', () {
      final plan = planSync(
        apiSupported: false,
        alreadyMigrated: false,
        followsSystem: true,
        osOverrideTags: const [],
        storedId: 'en',
      );
      expect(plan.action, AppLocalesSyncAction.apiUnsupported);
      expect(plan.writeOs, isFalse);
      expect(plan.markMigrated, isFalse);
      expect(plan.writeStored, isFalse);
      expect(plan.storedIdToKeep, 'en');
    });

    test('an explicit OS override wins and is not overwritten by stored', () {
      final plan = planSync(
        apiSupported: true,
        alreadyMigrated: false,
        followsSystem: false,
        osOverrideTags: const ['de-DE'],
        storedId: 'en',
      );
      expect(plan.action, AppLocalesSyncAction.useOsOverride);
      expect(plan.writeOs, isFalse);
      expect(plan.storedIdToKeep, 'de');
      expect(plan.writeStored, isTrue);
      expect(plan.markMigrated, isTrue);
    });

    test('an empty OS list hands off a stored explicit preference once', () {
      final plan = planSync(
        apiSupported: true,
        alreadyMigrated: false,
        followsSystem: true,
        osOverrideTags: const [],
        storedId: 'zh_Hant',
      );
      expect(plan.action, AppLocalesSyncAction.handoffStoredOnce);
      expect(plan.writeOs, isTrue);
      expect(plan.osTagsToWrite, ['zh-Hant']);
      expect(plan.writeStored, isFalse);
      expect(plan.markMigrated, isTrue);
    });

    test('empty stored does not overwrite follow-system', () {
      final plan = planSync(
        apiSupported: true,
        alreadyMigrated: false,
        followsSystem: true,
        osOverrideTags: const [],
        storedId: 'system',
      );
      expect(plan.action, AppLocalesSyncAction.followSystem);
      expect(plan.writeOs, isFalse);
      expect(plan.markMigrated, isTrue);
    });

    test('an OS override we do not ship still wins', () {
      final plan = planSync(
        apiSupported: true,
        alreadyMigrated: false,
        followsSystem: false,
        osOverrideTags: const ['sv'],
        storedId: 'en',
      );
      expect(plan.writeOs, isFalse);
      expect(plan.storedIdToKeep, 'system');
    });
  });

  group('planSync after the one-time marker', () {
    test('a later resume never writes stored back onto the OS', () {
      final plan = planSync(
        apiSupported: true,
        alreadyMigrated: true,
        followsSystem: false,
        osOverrideTags: const ['de'],
        storedId: 'en',
      );
      expect(plan.action, AppLocalesSyncAction.alreadyMigratedFollowOs);
      expect(plan.writeOs, isFalse);
      expect(plan.storedIdToKeep, 'de');
    });

    test('OS follow-system after migrate clears a leftover stored id', () {
      final plan = planSync(
        apiSupported: true,
        alreadyMigrated: true,
        followsSystem: true,
        osOverrideTags: const [],
        storedId: 'en',
      );
      expect(plan.writeOs, isFalse);
      expect(plan.storedIdToKeep, 'system');
      expect(plan.writeStored, isTrue);
    });
  });

  group('AppLocalesSynchronizer', () {
    test('handoff writes OS once; a second resume does not', () async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
      });
      final prefs = await SharedPreferences.getInstance();
      var osTags = <String>[];
      var followsSystem = true;
      final writes = <List<String>>[];
      final sync = AppLocalesSynchronizer(
        prefs: prefs,
        getOs: () async => AppLocalesSnapshot(
          apiSupported: true,
          sdkInt: 36,
          followsSystem: followsSystem,
          overrideTags: osTags,
          configurationTags: const ['en-US'],
        ),
        setOs: (tags) async {
          writes.add(List<String>.from(tags));
          osTags = List<String>.from(tags);
          followsSystem = tags.isEmpty;
          return AppLocalesSnapshot(
            apiSupported: true,
            sdkInt: 36,
            followsSystem: followsSystem,
            overrideTags: osTags,
            configurationTags: osTags,
          );
        },
      );

      final first = await sync.sync();
      expect(first.action, AppLocalesSyncAction.handoffStoredOnce);
      expect(sync.osWriteCount, 1);
      expect(writes, [
        ['en'],
      ]);
      expect(prefs.getBool(kLocaleOsMigratedKey), isTrue);

      final second = await sync.sync();
      expect(second.action, AppLocalesSyncAction.alreadyMigratedFollowOs);
      expect(sync.osWriteCount, 1);
      expect(writes, hasLength(1));
    });

    test('after migrate, an OS change updates stored and does not write OS',
        () async {
      SharedPreferences.setMockInitialValues({
        kLocalePreferenceKey: 'en',
        kLocaleOsMigratedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final sync = AppLocalesSynchronizer(
        prefs: prefs,
        getOs: () async => const AppLocalesSnapshot(
          apiSupported: true,
          sdkInt: 36,
          followsSystem: false,
          overrideTags: ['de'],
          configurationTags: ['de-DE'],
        ),
        setOs: (tags) async {
          fail('must not write OS after migrate: $tags');
        },
      );
      final plan = await sync.sync();
      expect(plan.writeOs, isFalse);
      expect(prefs.getString(kLocalePreferenceKey), 'de');
      expect(sync.osWriteCount, 0);
    });
  });

  group('languageSwitchBlock', () {
    test('recording blocks before a dirty editor', () {
      expect(
        languageSwitchBlock(
          recording: true,
          artifactBusy: false,
          pidMutationLocked: false,
          pidEditorDirty: true,
        ),
        LanguageSwitchBlock.recording,
      );
    });

    test('a dirty PID editor blocks when nothing else is in flight', () {
      expect(
        languageSwitchBlock(
          recording: false,
          artifactBusy: false,
          pidMutationLocked: false,
          pidEditorDirty: true,
        ),
        LanguageSwitchBlock.pidEditorDirty,
      );
    });

    test('clear path is none', () {
      expect(
        languageSwitchBlock(
          recording: false,
          artifactBusy: false,
          pidMutationLocked: false,
          pidEditorDirty: false,
        ),
        LanguageSwitchBlock.none,
      );
    });

    test('TorqueApp and the picker are wired to sync and the guard', () {
      final app = File('lib/app.dart').readAsStringSync();
      expect(app, contains('_syncAppLocales'));
      expect(app, contains('onResume: _onResume'));
      expect(app, contains('didChangeLocales'));
      final picker = File(
        'lib/ui/widgets/language_picker.dart',
      ).readAsStringSync();
      expect(picker, contains('languageSwitchBlockProvider'));
      expect(picker, isNot(contains('force-stop')));
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, contains('AppLocalesPlatform.live = true'));
      // PidEditorScreen must not write pidEditorDirtyProvider from dispose:
      // Riverpod 3 forbids using ref while unmounting, and 25 editor tests
      // failed on that path in telltale#294 CI 34468560906.
      final editor = File(
        'lib/ui/screens/pids/pid_editor_screen.dart',
      ).readAsStringSync();
      expect(editor, isNot(contains('language_switch_guard')));
      expect(editor, isNot(contains('pidEditorDirtyProvider')));
    });

    test('copy is localized, not a raw identifier', () {
      final en = AppLocalizationsEn();
      final zh = AppLocalizationsZhHant();
      expect(
        languageSwitchBlockText(en, LanguageSwitchBlock.recording),
        en.telemetryBlockedByRecorder,
      );
      expect(
        languageSwitchBlockText(zh, LanguageSwitchBlock.recording),
        zh.telemetryBlockedByRecorder,
      );
      expect(
        languageSwitchBlockText(en, LanguageSwitchBlock.pidEditorDirty),
        en.pidEditorDiscardBody,
      );
      expect(
        languageSwitchBlockText(en, LanguageSwitchBlock.recording),
        isNot('LanguageSwitchBlock.recording'),
      );
    });
  });
}
