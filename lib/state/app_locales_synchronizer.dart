/// Applies [planSync] against SharedPreferences and an injectable OS getter.
///
/// The real LocaleManager channel is only used when the caller passes it.
/// Widget tests that change language without a mock must not go through this.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_locales_platform.dart';
import '../l10n/app_locales_sync.dart';
import '../l10n/locale_resolution.dart';

typedef AppLocalesGetter = Future<AppLocalesSnapshot> Function();
typedef AppLocalesSetter = Future<AppLocalesSnapshot?> Function(
  List<String> tags,
);

enum LocaleSyncDisposition {
  unchanged,
  applied,
  deferred,
  superseded,
  failed,
  appliedNeedsReconcile,
}

final class AppLocalesSyncResult {
  const AppLocalesSyncResult({
    required this.plan,
    required this.disposition,
    this.storedIdCommitted,
    this.storeWritten = false,
    this.osWritten = false,
    this.migrationMarked = false,
    this.readbackOs,
  });

  final AppLocalesSyncPlan plan;
  final LocaleSyncDisposition disposition;
  final String? storedIdCommitted;
  final bool storeWritten;
  final bool osWritten;
  final bool migrationMarked;
  final AppLocalesSnapshot? readbackOs;

  AppLocalesSyncAction get action => plan.action;
  String get storedIdToKeep => plan.storedIdToKeep;
  bool get writeOs => plan.writeOs;
  bool get writeStored => plan.writeStored;
  bool get markMigrated => plan.markMigrated;
  List<String> get osTagsToWrite => plan.osTagsToWrite;

  bool get isSuccess =>
      disposition == LocaleSyncDisposition.applied ||
      disposition == LocaleSyncDisposition.unchanged;
}

final class AppLocalesSynchronizer {
  AppLocalesSynchronizer({
    required this.prefs,
    required this.getOs,
    this.setOs,
    this.shouldAbort,
  });

  final SharedPreferences prefs;
  final AppLocalesGetter getOs;
  final AppLocalesSetter? setOs;
  final bool Function()? shouldAbort;

  int osWriteCount = 0;
  int storedWriteCount = 0;

  Future<AppLocalesSyncResult> sync() async {
    final os = await getOs();
    final storedId = prefs.getString(kLocalePreferenceKey) ?? 'system';
    if (shouldAbort?.call() == true) {
      final abortedPlan = AppLocalesSyncPlan(
        action: AppLocalesSyncAction.alreadyMigratedFollowOs,
        storedIdToKeep: storedId,
        osTagsToWrite: const [],
        writeStored: false,
        writeOs: false,
        markMigrated: false,
      );
      return AppLocalesSyncResult(
        plan: abortedPlan,
        disposition: LocaleSyncDisposition.deferred,
        readbackOs: os,
      );
    }
    final alreadyMigrated = prefs.getBool(kLocaleOsMigratedKey) == true;
    final plan = planSync(
      apiSupported: os.apiSupported,
      alreadyMigrated: alreadyMigrated,
      followsSystem: os.followsSystem,
      osOverrideTags: os.overrideTags,
      storedId: storedId,
    );

    if (!plan.writeStored && !plan.writeOs && !plan.markMigrated) {
      return AppLocalesSyncResult(
        plan: plan,
        disposition: LocaleSyncDisposition.unchanged,
        storedIdCommitted: plan.storedIdToKeep,
        readbackOs: os,
      );
    }

    var storeWritten = false;
    if (plan.writeStored) {
      if (shouldAbort?.call() == true) {
        return AppLocalesSyncResult(
          plan: plan,
          disposition: LocaleSyncDisposition.deferred,
          readbackOs: os,
        );
      }
      storedWriteCount += 1;
      bool ok = false;
      try {
        ok = await prefs.setString(
          kLocalePreferenceKey,
          plan.storedIdToKeep,
        );
      } on Object {
        ok = false;
      }
      if (!ok) {
        return AppLocalesSyncResult(
          plan: plan,
          disposition: LocaleSyncDisposition.failed,
          storeWritten: false,
          readbackOs: os,
        );
      }
      storeWritten = true;
      if (shouldAbort?.call() == true) {
        return AppLocalesSyncResult(
          plan: plan,
          disposition: LocaleSyncDisposition.appliedNeedsReconcile,
          storedIdCommitted: plan.storedIdToKeep,
          storeWritten: true,
          readbackOs: os,
        );
      }
    }

    var osWritten = false;
    AppLocalesSnapshot? writtenOs;
    if (plan.writeOs) {
      final setter = setOs;
      if (setter == null) {
        return AppLocalesSyncResult(
          plan: plan,
          disposition: storeWritten
              ? LocaleSyncDisposition.appliedNeedsReconcile
              : LocaleSyncDisposition.failed,
          storedIdCommitted: storeWritten ? plan.storedIdToKeep : null,
          storeWritten: storeWritten,
          osWritten: false,
          readbackOs: os,
        );
      }
      if (shouldAbort?.call() == true) {
        return AppLocalesSyncResult(
          plan: plan,
          disposition: storeWritten
              ? LocaleSyncDisposition.appliedNeedsReconcile
              : LocaleSyncDisposition.deferred,
          storedIdCommitted: storeWritten ? plan.storedIdToKeep : null,
          storeWritten: storeWritten,
          readbackOs: os,
        );
      }
      osWriteCount += 1;
      writtenOs = await setter(plan.osTagsToWrite);

      final osMatches = writtenOs != null &&
          writtenOs.apiSupported &&
          (plan.osTagsToWrite.isEmpty
              ? writtenOs.followsSystem
              : (!writtenOs.followsSystem &&
                  storedIdFromOsTags(writtenOs.overrideTags) ==
                      plan.storedIdToKeep));

      if (osMatches) {
        osWritten = true;
      }

      if (shouldAbort?.call() == true) {
        return AppLocalesSyncResult(
          plan: plan,
          disposition: (storeWritten || osWritten)
              ? LocaleSyncDisposition.appliedNeedsReconcile
              : LocaleSyncDisposition.deferred,
          storedIdCommitted: storeWritten ? plan.storedIdToKeep : null,
          storeWritten: storeWritten,
          osWritten: osWritten,
          readbackOs: writtenOs ?? os,
        );
      }
      // A timeout, refusal, or unchanged OS snapshot is not a handoff. Keep
      // the stored preference retryable instead of letting the next resume
      // replace it with the OS's still-empty (follow-system) override.
      if (!osMatches) {
        return AppLocalesSyncResult(
          plan: plan,
          disposition: storeWritten
              ? LocaleSyncDisposition.appliedNeedsReconcile
              : LocaleSyncDisposition.failed,
          storedIdCommitted: storeWritten ? plan.storedIdToKeep : null,
          storeWritten: storeWritten,
          osWritten: false,
          readbackOs: writtenOs ?? os,
        );
      }
    }

    var migrationMarked = false;
    if (plan.markMigrated) {
      if (shouldAbort?.call() == true) {
        return AppLocalesSyncResult(
          plan: plan,
          disposition: (storeWritten || osWritten)
              ? LocaleSyncDisposition.appliedNeedsReconcile
              : LocaleSyncDisposition.deferred,
          storedIdCommitted: storeWritten ? plan.storedIdToKeep : null,
          storeWritten: storeWritten,
          osWritten: osWritten,
          readbackOs: writtenOs ?? os,
        );
      }
      bool marked = false;
      try {
        marked = await prefs.setBool(kLocaleOsMigratedKey, true);
      } on Object {
        marked = false;
      }
      if (!marked) {
        return AppLocalesSyncResult(
          plan: plan,
          disposition: (storeWritten || osWritten)
              ? LocaleSyncDisposition.appliedNeedsReconcile
              : LocaleSyncDisposition.failed,
          storedIdCommitted: storeWritten ? plan.storedIdToKeep : null,
          storeWritten: storeWritten,
          osWritten: osWritten,
          migrationMarked: false,
          readbackOs: writtenOs ?? os,
        );
      }
      migrationMarked = true;
    }

    return AppLocalesSyncResult(
      plan: plan,
      disposition: LocaleSyncDisposition.applied,
      storedIdCommitted: plan.storedIdToKeep,
      storeWritten: storeWritten,
      osWritten: osWritten,
      migrationMarked: migrationMarked,
      readbackOs: writtenOs ?? os,
    );
  }

  LocalePreference storedPreference() =>
      localePreferenceFromStored(prefs.getString(kLocalePreferenceKey));
}
