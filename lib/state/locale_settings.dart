/// Persisted UI language preference. Independent of vehicle / PID / adapter keys.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_locales_platform.dart';
import '../l10n/app_locales_sync.dart';
import '../l10n/locale_resolution.dart';
import 'app_locales_synchronizer.dart';
import 'language_switch_guard.dart';
import 'pid_registry.dart';

class LocalePreferenceController extends Notifier<LocalePreference> {
  /// Last value known to be in the store. Failures restore to this, not to
  /// the preference that happened to be on screen when this call started —
  /// a slower older write must not wipe a newer selection.
  LocalePreference _committed = LocalePreference.system;

  /// Persist calls run one at a time so two in-flight writes cannot complete
  /// out of order and commit the older one last.
  Future<void> _persistQueue = Future<void>.value();

  /// Each [set] call, including two taps of the same value. Equality of
  /// [state] and [preference] is not identity of the request.
  int _attempt = 0;

  /// Flag indicating that state between UI, store, or OS requires reconciliation.
  bool _needsReconcile = false;

  /// Current version token to coordinate write ownership between the
  /// user picker queue and asynchronous platform synchronizers.
  int get attempt => _attempt;

  /// Whether store or OS state is partially applied and needs reconciliation.
  bool get needsReconcile => _needsReconcile;

  /// Last known committed locale preference in the local store.
  LocalePreference get committed => _committed;

  @override
  LocalePreference build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final loaded = localePreferenceFromStored(
      prefs.getString(kLocalePreferenceKey),
    );
    _committed = loaded;
    return loaded;
  }

  /// Returns false when the store rejects the write.
  ///
  /// The screen updates immediately. If this write fails, the screen goes
  /// back to [_committed] only when this call is still the latest [set].
  /// Equal values are not the same request: a second tap of English while
  /// the first save is in flight must not restore System over it.
  Future<bool> set(LocalePreference preference) {
    final block = ref.read(languageSwitchBlockProvider);
    if (block != LanguageSwitchBlock.none) {
      return Future<bool>.value(false);
    }
    final attempt = ++_attempt;
    state = preference;
    final done = Completer<bool>();
    _persistQueue = _persistQueue.then((_) async {
      try {
        done.complete(await _persist(preference, attempt));
      } on Object catch (error, stack) {
        done.completeError(error, stack);
      }
    });
    return done.future;
  }

  Future<bool> _persist(LocalePreference preference, int attempt) async {
    var wroteOs = false;
    var storeWritten = false;
    try {
      if (ref.read(languageSwitchBlockProvider) != LanguageSwitchBlock.none) {
        if (attempt == _attempt) state = _committed;
        return false;
      }
      // After the first-run marker, resume treats LocaleManager as authority.
      // An in-app picker that only wrote SharedPreferences would be clobbered
      // on the next resume. Tests keep [AppLocalesPlatform.live] false so this
      // never waits on an unanswered MethodChannel.
      if (AppLocalesPlatform.live) {
        final current = await AppLocalesPlatform.get();
        if (attempt != _attempt) return false;
        if (ref.read(languageSwitchBlockProvider) != LanguageSwitchBlock.none) {
          if (attempt == _attempt) state = _committed;
          return false;
        }
        if (current.apiSupported) {
          final expectedTags = tagsForPreference(preference);
          final written = await AppLocalesPlatform.setOverrideTags(expectedTags);
          final matches = _isOsSnapshotMatch(written, preference);
          if (matches) {
            wroteOs = true;
          }
          if (ref.read(languageSwitchBlockProvider) != LanguageSwitchBlock.none) {
            // Guard blocked! Do NOT fire an extra OS setter rollback when guard is blocked (R67-1).
            _needsReconcile = true;
            if (attempt == _attempt) state = _committed;
            return false;
          }
          if (!matches) {
            if (attempt == _attempt) state = _committed;
            return false;
          }
          if (attempt != _attempt) return false;
        }
      }

      final prefs = ref.read(sharedPreferencesProvider);
      if (ref.read(languageSwitchBlockProvider) != LanguageSwitchBlock.none) {
        if (wroteOs) _needsReconcile = true;
        if (attempt == _attempt) state = _committed;
        return false;
      }

      bool ok = false;
      try {
        ok = await prefs.setString(
          kLocalePreferenceKey,
          localePreferenceToStored(preference),
        );
      } on Object {
        ok = false;
      }
      if (!ok) {
        if (ref.read(languageSwitchBlockProvider) != LanguageSwitchBlock.none) {
          _needsReconcile = true;
        } else if (wroteOs && AppLocalesPlatform.live) {
          try {
            final rollback = await AppLocalesPlatform.setOverrideTags(
              tagsForPreference(_committed),
            );
            if (!_isOsSnapshotMatch(rollback, _committed)) {
              _needsReconcile = true;
            }
          } on Object {
            _needsReconcile = true;
          }
        }
        if (attempt == _attempt) state = _committed;
        return false;
      }

      // Store is confirmed written! Acknowledge this committed fact (R67-2).
      storeWritten = true;
      _committed = preference;

      if (ref.read(languageSwitchBlockProvider) != LanguageSwitchBlock.none) {
        _needsReconcile = true;
        return false;
      }

      if (wroteOs) {
        bool migratedOk = false;
        try {
          migratedOk = await prefs.setBool(kLocaleOsMigratedKey, true);
        } on Object {
          migratedOk = false;
        }
        if (!migratedOk) {
          _needsReconcile = true;
          // Store already acknowledged preference! Do NOT rollback OS.
          if (attempt == _attempt &&
              ref.read(languageSwitchBlockProvider) ==
                  LanguageSwitchBlock.none) {
            state = preference;
          }
          return false;
        }
        if (ref.read(languageSwitchBlockProvider) != LanguageSwitchBlock.none) {
          _needsReconcile = true;
          return false;
        }
      }

      if (attempt == _attempt) {
        state = preference;
        _needsReconcile = false;
      }
      return true;
    } on Object {
      if (storeWritten) {
        _committed = preference;
        _needsReconcile = true;
        if (attempt == _attempt &&
            ref.read(languageSwitchBlockProvider) == LanguageSwitchBlock.none) {
          state = preference;
        }
      } else {
        if (ref.read(languageSwitchBlockProvider) != LanguageSwitchBlock.none) {
          _needsReconcile = true;
        } else if (wroteOs && AppLocalesPlatform.live) {
          try {
            final rollback = await AppLocalesPlatform.setOverrideTags(
              tagsForPreference(_committed),
            );
            if (!_isOsSnapshotMatch(rollback, _committed)) {
              _needsReconcile = true;
            }
          } on Object {
            _needsReconcile = true;
          }
        }
        if (attempt == _attempt) state = _committed;
      }
      return false;
    }
  }

  /// Shared synchronization method that executes within the [_persistQueue]
  /// and respects versioning and the [LanguageSwitchBlock] guard.
  ///
  /// Prevents older OS read results from arriving late and overwriting newer
  /// user selections (R67-2).
  Future<bool> synchronize(
    Future<AppLocalesSyncResult?> Function(int version) syncAction,
  ) {
    final block = ref.read(languageSwitchBlockProvider);
    if (block != LanguageSwitchBlock.none) {
      return Future<bool>.value(false);
    }
    final expectedVersion = _attempt;
    final done = Completer<bool>();
    _persistQueue = _persistQueue.then((_) async {
      try {
        if (ref.read(languageSwitchBlockProvider) != LanguageSwitchBlock.none ||
            expectedVersion != _attempt) {
          done.complete(false);
          return;
        }
        final result = await syncAction(expectedVersion);
        if (result == null) {
          done.complete(false);
          return;
        }

        final isUnblocked =
            ref.read(languageSwitchBlockProvider) == LanguageSwitchBlock.none;
        final isVersionCurrent = expectedVersion == _attempt;

        if (result.disposition == LocaleSyncDisposition.applied ||
            result.disposition == LocaleSyncDisposition.unchanged) {
          final next = localePreferenceFromStored(
            result.storedIdCommitted ?? result.plan.storedIdToKeep,
          );
          if (isVersionCurrent && isUnblocked) {
            _committed = next;
            state = next;
            _needsReconcile = false;
            done.complete(true);
          } else {
            if (result.storeWritten && result.storedIdCommitted != null) {
              _committed = next;
            }
            if (!isUnblocked) _needsReconcile = true;
            done.complete(false);
          }
        } else if (result.disposition ==
            LocaleSyncDisposition.appliedNeedsReconcile) {
          _needsReconcile = true;
          if (result.storeWritten && result.storedIdCommitted != null) {
            final next = localePreferenceFromStored(result.storedIdCommitted!);
            _committed = next;
            if (isVersionCurrent && isUnblocked) {
              state = next;
            }
          }
          done.complete(false);
        } else {
          // failed or deferred
          if (result.storeWritten && result.storedIdCommitted != null) {
            final next = localePreferenceFromStored(result.storedIdCommitted!);
            _committed = next;
            if (isVersionCurrent && isUnblocked) {
              state = next;
            }
          }
          if (result.storeWritten || result.osWritten) {
            _needsReconcile = true;
          }
          done.complete(false);
        }
      } on Object catch (error, stack) {
        done.completeError(error, stack);
      }
    });
    return done.future;
  }
}

bool _isOsSnapshotMatch(
  AppLocalesSnapshot? snapshot,
  LocalePreference preference,
) {
  if (snapshot == null || !snapshot.apiSupported) return false;
  if (preference == LocalePreference.system) {
    return snapshot.followsSystem;
  }
  return !snapshot.followsSystem &&
      storedIdFromOsTags(snapshot.overrideTags) ==
          localePreferenceToStored(preference);
}

final localePreferenceProvider =
    NotifierProvider<LocalePreferenceController, LocalePreference>(
      LocalePreferenceController.new,
    );
