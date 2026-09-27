# Task TELLTALE-1L-C1B-N1-ANDROID-LOCALE-CANDIDATE Verification Record

## 1. Executive Summary & Boundaries

- **Task ID**: `TELLTALE-1L-C1B-N1-ANDROID-LOCALE-CANDIDATE`
- **References**: Refs #36 (Owner), #40, #34
- **Branch**: `test/l02-android-native-locale-candidate`
- **Base Commit**: `8adb3fd66588001075054e21f94c5a7e6bb23859`
- **Target Profile**: `candidate-native-locale` (Android API 33+ AOSP Emulator Rig Target)
- **Exit Level**: `NATIVE_LOCALE_CANDIDATE_N1_ACCEPTED`
- **Strict Scope Boundaries**:
  - Does NOT claim physical hardware qualification, physical Wear BLE (#91), or full platform closure.
  - Keeps Issue #36, #40, and #34 OPEN until residual ledgers are independently satisfied.
  - Zero edits to `lib/` (denylist strictly preserved).

---

## 2. Allowlist Compliance

The following files constitute the strict allowlist for this batch:
1. `tool/l10n_rig/android_os_locale.py` (Candidate verification validator and execution lane)
2. `tool/l10n_rig/run.py` (L10n rig dispatcher argument pass-through)
3. `integration_test/rig_support.dart` (Rig testing support harness)
4. `test/tool/test_android_locale_candidate.py` (N00-N07 matrix Python unit tests)
5. `docs/verification/l02-candidate-native-locale.md` (This document)

---

## 3. Candidate Lifecycle State Machine

```
PREPARED
  │
  ▼
TARGET / CANDIDATE AUDIT
  │ (Check API 33+, package com.cbstudio.telltale.rig, flavor rig, SHA-256)
  ▼
PRESERVE INITIAL STATE
  │ (Save original system locale list and app locale override)
  ▼
OS -> APP ENGLISH
  │ (cmd locale set-app-locales en-US -> verify English UI markers)
  ▼
OS -> APP TRADITIONAL CHINESE
  │ (cmd locale set-app-locales zh-Hant-TW -> verify 內建模擬器 UI marker)
  ▼
APP -> OS SYNC
  │ (LanguagePicker via MethodChannel -> verify OS LocaleManager update, no infinite loop)
  ▼
FOLLOW SYSTEM RESET
  │ (Clear override -> verify app tracks system locale without fallback degradation)
  ▼
IDLE PROCESS RESTART
  │ (force-stop and relaunch -> verify persisted preference and session data intact)
  ▼
RESTORE & CLEANUP
  │ (Restore original device locale and app override)
  ▼
ARCHIVE & REVIEW
  │ (Emit structured candidate report with SHA-256 digests and exit 0)
```

---

## 4. Verification Matrix (N00 - N07)

| Case ID | Objective | Verification Method | Status |
|---|---|---|---|
| **N00** | Candidate Identity & Provenance | Verify 64-hex binary SHA-256, 40-hex Git `source_sha`, 40-hex `tree_sha`, package name `com.cbstudio.telltale.rig`, flavor `rig`, target API >= 33, signature digest. | **ACCEPTED** |
| **N01** | Manifest & LocaleConfig Discoverability | Verify `AndroidManifest.xml` declares `android:localeConfig="@xml/locales_config"` and `locales_config.xml` includes `en`, `zh-Hant`, `de`. | **ACCEPTED** |
| **N02** | OS -> App Dynamic Sync | Verify `cmd locale set-app-locales` updates live UI copy (English "built-in simulator" and Traditional Chinese "內建模擬器") with 0 unexpected re-prompts. | **ACCEPTED** |
| **N03** | App -> OS Sync & Loop Prevention | Verify LanguagePicker action propagates to OS `LocaleManager` synchronously; reject invalid locales without overwriting preferences; prove 0 ping-pong loop broadcasts. | **ACCEPTED** |
| **N04** | Follow-System Preference | Verify clearing app override via empty tags restores follow-system mode; verify it does not default to hardcoded English if system locale is Traditional Chinese. | **ACCEPTED** |
| **N05** | Idle Process Restart Retention | Verify process recreation via force-stop and cold relaunch retains selected locale preference and session records without data corruption. | **ACCEPTED** |
| **N06** | Teardown Restoration | Verify test lifecycle restores original system language and app override settings upon completion; errors fail closed and are visible. | **ACCEPTED** |
| **N07** | Negative Controls Matrix | Verify fail-closed rejection of tampered candidate SHA, corrupted screenshots, wrong device serial (`R5CX10VFFBA`), API < 33, nonzero exit, or missing case IDs. | **ACCEPTED** |

---

## 5. Verification Commands

```bash
# 1. Analyzer Gate
fvm flutter analyze

# 2. Candidate Matrix Test Suite
python3 -m unittest discover -s test/tool -p 'test_android_locale_candidate.py'

# 3. Legacy Rig Runner Suite
python3 -m unittest discover -s test/tool -p 'test_android_os_locale.py'
python3 -m unittest discover -s test/tool -p 'test_l10n_rig_run.py'

# 4. Flutter L10n Suite
fvm flutter test test/l10n/
```
