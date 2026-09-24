# Telltale Privacy Policy ↔ Implemented Data Flow Contract

**Status:** Normative (Issue #11, WS-07 Slice 4)  
**Contract ID:** `ws07-privacy-data-flow-contract`  
**Audited Base:** `4c7d0b5a57ea95f612e591e3203db6095de0b218`  
**Related Specifications:**  
- [Public Artifact Boundary](public-artifact-boundary.md) (WS-07 Slice 3)
- [Public Artifact Policy](public-artifact-policy.json) (WS-07 Slice 3)
- [Data Flow Inventory](data-flow-inventory.json) (WS-07 Slice 4)

---

## 1. Scope and Governance

This document establishes the normative contract between user-visible privacy documentation (`PRIVACY.md`, `docs/privacy.html`), runtime storage/data flow implementations, and automated verification suites for Telltale (Issue #11, WS-07 Slice 4).

### Governing Principles:
1. **Fact-First Truthfulness:** Privacy claims must reflect actual code execution, concrete filesystem paths, explicit network transports, and genuine operating system constraints.
2. **Fail-Closed Verification:** Any drift between declared policy claims and runtime data flow facts triggers a deterministic build failure.
3. **Explicit Partitioning:** Diagnostic captures, telemetry sessions, temporary share caches, and settings reside in distinct storage partitions with distinct lifecycles.
4. **Boundary Distinction:** App local operations, OS backup mechanisms, external third-party apps (share recipients), and maintainer-only offline tools are strictly delineated.

---

## 2. Data Flow Inventory Matrix (DF01–DF10)

The canonical inventory resides in [`docs/privacy/data-flow-inventory.json`](data-flow-inventory.json). All ten coverage categories are mandatory:

| Coverage ID | Subsystem / Flow | Source Anchors | Storage Location | Retention / Lifecycle |
|---|---|---|---|---|
| **DF01** | Vehicle Profile, Adapter & UI Settings | `lib/state/settings.dart` (`VehicleProfileController`, `LastAdapterController`, `ThemeModeController`, `GaugeSkinController`) | `SharedPreferences` (`vehicle_profile_v1`, `last_adapter_v1`, `theme_mode_v1`, `gauge_skin`) | Persistent until overwritten or app uninstalled. |
| **DF02** | Custom PID Definitions | `lib/state/pid_registry.dart` (`PidRegistryNotifier`) | `SharedPreferences` (`custom_pids_v1`, `active_pid_ids_v1`) | User-authored; persistent until edited, deleted, or uninstalled. |
| **DF03** | Diagnostic Transcript (Last Session) | `lib/obd/transcript_store.dart` (`TranscriptStore`, `StoredTranscript`) | `Documents/last-session.log` & `.part` | Exactly one session snapshot; overwritten on next connection boundary or cleared. |
| **DF04** | Telemetry Session Archives | `lib/telemetry/session/telemetry_session_store.dart` (`TelemetrySessionStore`) | `Documents/telltale-telemetry/<id>.ndjson` | User-managed; deleted individually or upon uninstallation. Structured fields exclude VIN, GPS, accounts; user-authored labels/notes are preserved. |
| **DF05** | Share Staging Cache & Leases | `lib/core/share/app_share_cache.dart`, `lib/core/share/share_lease_ledger.dart` | `Caches/telltale-app-shares/` (`*.share`, `*.lease.json`) | 15-min eligible, 24-hr due; cleaned at app launch & share entry. |
| **DF06** | Formal User-Initiated Share (5 Kinds) | `lib/state/app_share_coordinator.dart`, `lib/state/app_share_entry_controller.dart` | Staged in Cache; handed off via `AppSharePlatformBridge` | Explicit opt-in only. Zero handoff prior to user action. Dismissed returns dismissed without claiming delivery. |
| **DF07** | Adapter Communication Channels | `lib/obd/transport/wifi_transport.dart`, `lib/obd/transport/ble_transport.dart`, `lib/obd/transport/classic_transport.dart`, `lib/obd/transport/serial_transport.dart` | In-memory socket / BLE / RFCOMM / Serial stream | Configurable host/port (typically LAN `192.168.0.10:35000`); no developer servers or telemetry uploads. |
| **DF08** | Recommended Purchases Links | `lib/ui/widgets/recommended_purchase_panel.dart` | External system browser launch | Affiliate disclosure; zero diagnostic or identifier data attached. Zero opener calls prior to explicit tap. |
| **DF09** (App) | Bundled Vehicle Catalog Assets | `lib/obd/vehicle_catalog/us_vehicle_catalog.dart` | Bundled in package (`assets/`) | Mobile app reads bundled catalog fully offline with zero network egress. |
| **DF09** (Maintainer) | Maintainer Catalog Update Tool | `tool/update_us_vehicle_catalog.py` | Developer workstation | Maintainer script downloads public government catalog archive on workstation; completely isolated from mobile devices. |
| **DF10** | Absence of Third-Party Tracking / Uploads | `pubspec.yaml`, `android/app/build.gradle.kts`, bounded codebase scan | None | No analytics, ads, crash reporters, accounts, or upload services (verified via static AST and dependency audit). |

---

## 3. Normative Privacy Policy Claims (Claims 01–12)

Every user-visible policy document (`PRIVACY.md` in Traditional Chinese & English, and `docs/privacy.html` in Traditional Chinese & English) must faithfully present the following twelve claims:

### `CLAIM-DEVELOPER-NO-COLLECTION`
- **Claim:** The developer does not collect personal data, operates no remote backend servers, and requires no user accounts.
- **Scope:** Application-wide.

### `CLAIM-LOCAL-STORAGE-PARTITION`
- **Claim:** All app data is strictly written to local private device storage, segregated across `SharedPreferences` (settings, PIDs), `Documents` (transcripts, telemetry), and `Application Cache` (share staging).
- **Scope:** Runtime storage subsystem.

### `CLAIM-DIAGNOSTIC-RAW-BYTES`
- **Claim:** Diagnostic transcript records raw OBD-II protocol exchanges including reported VIN and DTCs. Kept strictly on-device in `Documents/last-session.log` until explicit user export.
- **Scope:** Diagnostic subsystem (`TranscriptStore`).

### `CLAIM-TELEMETRY-NDJSON`
- **Claim:** Telemetry sessions are stored locally in `Documents/telltale-telemetry/<id>.ndjson`. The user may inspect, replay, export (CSV/JSON), or delete records locally. Structured export fields exclude VIN, GPS coordinates, and user accounts; user-authored signal names, equations, units, and notes are preserved in the export as written without automatic redaction.
- **Scope:** Telemetry subsystem (`TelemetrySessionStore`, `TelemetryExportCodec`).

### `CLAIM-SHARE-CACHE-LIFECYCLE`
- **Claim:** Staged share artifacts reside in `Application Cache/telltale-app-shares/` with 15-minute eligibility and 24-hour due timestamps, cleaned during app launch and share flows. Not an absolute OS daemon guarantee.
- **Scope:** Share subsystem (`AppShareCache`, `ShareLeaseLedger`).

### `CLAIM-USER-CONTROLLED-SHARE`
- **Claim:** Five formal export types (`rawTranscript`, `recoveredTranscript`, `telemetryCsv`, `telemetryJson`, `pidCsv`) require explicit user action. Zero pre-action handoff. Local deletion cannot recall copies handed to external apps.
- **Scope:** Share coordinator & entry controllers.

### `CLAIM-NETWORK-ADAPTER-ONLY`
- **Claim:** `INTERNET` permission is utilized solely for opening a TCP socket to a user-configured Wi-Fi adapter (typically local `192.168.0.10:35000`). Destination endpoints depend on user settings; app has no built-in developer data collection or telemetry upload services.
- **Scope:** OBD network transports (`WifiTransport`).

### `CLAIM-EXTERNAL-AFFILIATE-LINKS`
- **Claim:** Recommended adapter links are affiliate listings opened via system launcher only upon explicit tap. No telemetry, VIN, device UUID, or customer data is appended. Zero opener calls occur prior to tap or across widget rebuilds.
- **Scope:** Recommended purchase UI widgets.

### `CLAIM-PERMISSIONS-MINIMAL`
- **Claim:** Declares only required permissions: `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN` (`neverForLocation`), legacy location (Android <=30), and `INTERNET` (Wi-Fi adapter). `BLUETOOTH_ADVERTISE` is explicitly stripped (`tools:node="remove"`).
- **Scope:** Platform manifests.

### `CLAIM-NO-THIRD-PARTY-SDKS`
- **Claim:** App contains zero analytics, advertising, crash reporting, or user tracking SDKs. Verified via bounded dependency and source audit.
- **Scope:** `pubspec.yaml` dependencies and build manifests.

### `CLAIM-OS-BACKUP-BEHAVIOR`
- **Claim:** Operating system backups (Android Cloud/D2D, iOS/macOS system backups) may copy app private files depending on user device settings. Uninstalling removes local files but not preexisting OS backups. Users may disable backup in OS settings.
- **Scope:** Platform backup configurations.

### `CLAIM-OPEN-SOURCE-VERIFIABLE`
- **Claim:** Telltale is licensed under GPL-3.0; all privacy declarations are fully verifiable in public source code.
- **Scope:** Governance & repository distribution.

---

## 4. Platform Backup and Storage Directory Mapping

| Storage Role | Flutter Plugin API | Android Native Directory | Android Backup Domain | iOS / macOS Native Directory | Apple Backup Classification |
|---|---|---|---|---|---|
| **Preferences & Settings** | `SharedPreferences` | `/data/data/<pkg>/shared_prefs/FlutterSharedPreferences.xml` | `sharedpref` (Auto Backup eligible) | `Library/Preferences/<pkg>.plist` | Included in device backup |
| **Documents & Logs** | `getApplicationDocumentsDirectory` | `/data/data/<pkg>/app_flutter/` | `root` (`dataDir`) (Auto Backup eligible) | `Documents/` (`NSDocumentDirectory`) | Included in device backup |
| **Share Staging Cache** | `getApplicationCacheDirectory` | `/data/data/<pkg>/cache/` | `cache` (OS excluded from Auto Backup) | `Library/Caches/` (`NSCachesDirectory`) | OS excluded from device backup |

### Android Effective Configuration:
1. **Manifest Configuration:** `android/app/src/main/AndroidManifest.xml` does not explicitly set `android:allowBackup`. Under Android platform defaults, `allowBackup` defaults to `true`.
2. **Cloud vs. D2D Backup & Native Storage Mapping:**
   - Flutter's `path_provider_android` plugin creates `getApplicationDocumentsDirectory()` (`app_flutter/`) via `context.getDir("flutter", Context.MODE_PRIVATE)` inside the app private data directory (`dataDir`), corresponding to the `<root path="app_flutter"/>` domain in Android Auto Backup XML rules. It is not located in `getFilesDir()` (`<file>` domain). Because it resides within `dataDir`, it is eligible for backup under default Android Auto Backup rules.
   - `SharedPreferences` persists to `/data/data/<pkg>/shared_prefs/FlutterSharedPreferences.xml` (`<sharedpref>` domain) and is eligible for backup.
   - Cache directories (`getApplicationCacheDirectory()`, `/data/data/<pkg>/cache/`) correspond to the `<cache>` domain and are excluded from backup by the operating system by default.
3. **Parity Assurance:** The policy states that OS backups may include app data unless disabled by the user in system settings. The app does not make misleading claims that data never leaves the device under OS backup.

### 4.1 Verification of Effective Merged Android Manifest (Field-Release and Field-Debug)

To verify that the build output does not inject any custom backup rules or modify backup behavior across both release and debug variants, the effective merged configuration is cryptographically locked and bound to the candidate source-set:

1. **Candidate Source-Set Identity and Locked Toolchain Values:**
   - **Candidate Source-Set & Parent Build Baseline:**
     - Verified Parent Baseline Commit: `22cea7b4417d199d5b64ddc7024d8eb04960e7de` (Git Tree SHA: `69fdd606091427e5e4899f9ac8106e26fc2c064e`)
     - Current Branch HEAD: `3f2cdf9ade0bc029c1692f700683bdf88081e710` (Git Tree SHA: `68b55eab8a4187786239241dfe53784a7825e81b`)
     - Base Commit: `4c7d0b5a57ea95f612e591e3203db6095de0b218`
     - Clean `lib/` Tree SHA: `45c11f2c0d9702c712fe13bd2c0a49fa8a69951e` (100% identical and untouched; zero product modifications)
     - Note: All build inputs between parent and current candidate remain identical; subsequent commits solely bind governance documentation and immutable evidence files under `docs/privacy/evidence/`.
   - **Locked Engine, Plugin, and Platform SDK Values:**
     - Flutter SDK: `3.47.0` (channel stable, Dart `3.13.0`, DevTools `2.60.0`)
     - Flutter Framework: `revision 4cf2416426 (2026-08-11 11:53:49 -0700)`
     - Flutter Engine: `hash 59d54a2b2896a6bbf356c94b7fac7b9e235bdacd (revision 5f77625673)`
     - Android Gradle Plugin (AGP): `9.1.0` (resolved from `android/settings.gradle.kts`: `id("com.android.application") version "9.1.0" apply false`)
     - Gradle: `9.3.1` (resolved from `gradle/wrapper/gradle-wrapper.properties`: `gradle-9.3.1-all.zip`)
     - Java / JVM: `OpenJDK Runtime Environment (build 21.0.6+7-Ubuntu-124.04.1)`
     - Android `compileSdkVersion`: `36` (resolved via `flutter.compileSdkVersion` under AGP 9.1.0 / platformBuildVersionCode 36)
     - Android `minSdkVersion`: `24` (resolved via `flutter.minSdkVersion` in merged manifest)
     - Android `targetSdkVersion`: `36` (resolved via `flutter.targetSdkVersion`)
     - Android `ndkVersion`: `27.0.12077973` (resolved via `flutter.ndkVersion`)

2. **Field-Release Build Evidence & Manifest Blame Attribution:**
   - **Build Task & Command:** `flutter build apk --release --flavor field --split-per-abi -PallowUnsignedRelease=true`
   - **Exit Code:** `0`
   - **Committed Raw Evidence Files in Repository:**
     - Full Merged Manifest: [`docs/privacy/evidence/field-release-merged-manifest.xml`](evidence/field-release-merged-manifest.xml) (8,382 bytes, SHA-256: `2576996797a7318e7305638fbc5e9f2092dfcc7749b5f654709292c34a1c1bcc`)
     - Full Merger Blame Report: [`docs/privacy/evidence/field-release-manifest-merger-blame-report.txt`](evidence/field-release-manifest-merger-blame-report.txt) (Committed sanitized: 23,766 bytes, SHA-256: `ec55183ad4bdc463e550abd317b21290c4e7d66ad38e6855a22ca3789cd60b3a`; Raw verified intermediate: 26,786 bytes, SHA-256: `c309e7b9eaed3cdc7507f3ae7e351c93acdc1e121bfbde14b30c9bd5716d8996`)
     - Resolved Configuration Record: [`docs/privacy/evidence/resolved-build-configuration.json`](evidence/resolved-build-configuration.json)
     - Native Storage Mapping: [`docs/privacy/evidence/native-storage-mapping.md`](evidence/native-storage-mapping.md)
   - **Effective Merged Manifest (`build/app/intermediates/merged_manifests/fieldRelease/processFieldReleaseManifest/arm64-v8a/AndroidManifest.xml`):**
     - File Size: `8382 bytes`
     - SHA-256 Digest: `2576996797a7318e7305638fbc5e9f2092dfcc7749b5f654709292c34a1c1bcc`
     ```xml
     <application
         android:name="android.app.Application"
         android:appComponentFactory="androidx.core.app.CoreComponentFactory"
         android:extractNativeLibs="false"
         android:icon="@mipmap/ic_launcher"
         android:label="Telltale"
         android:localeConfig="@xml/locales_config" >
     ```
   - **Merger Blame Report (`build/app/intermediates/manifest_merge_blame_file/fieldRelease/processFieldReleaseMainManifest/manifest-merger-blame-field-release-report.txt`):**
     - Raw Intermediate: `26786 bytes`, SHA-256 Digest: `c309e7b9eaed3cdc7507f3ae7e351c93acdc1e121bfbde14b30c9bd5716d8996`
     - Committed Sanitized Evidence: `23766 bytes`, SHA-256 Digest: `ec55183ad4bdc463e550abd317b21290c4e7d66ad38e6855a22ca3789cd60b3a` (user home paths sanitized to `<REPO_ROOT>` and `<GRADLE_USER_HOME>`)
     - Lines 92–108 attribute all `<application>` properties exclusively to platform injection, androidx.core, and local main manifest:
       ```text
       92    <application
       92-->INJECTED
       93        android:name="android.app.Application"
       93-->INJECTED
       94        android:appComponentFactory="androidx.core.app.CoreComponentFactory"
       94-->[androidx.core:core:1.18.0] .../core-1.18.0/AndroidManifest.xml:28:18-86
       95        android:extractNativeLibs="false"
       95-->INJECTED
       96        android:icon="@mipmap/ic_launcher"
       96-->android/app/src/main/AndroidManifest.xml:60:9-43
       97        android:label="Telltale"
       97-->android/app/src/main/AndroidManifest.xml:58:9-33
       98        android:localeConfig="@xml/locales_config" >
       98-->android/app/src/main/AndroidManifest.xml:61:9-51
       ```
   - **Verification & Acceptance Scope:**
     - Gate acceptance boundary is strictly verified via the effective merged AndroidManifest.xml and merger blame reports above. Standalone split APK digests are not gate acceptance artifacts.

3. **Field-Debug Build Evidence (Pipeline #2879697867 / Job #16716206167):**
   - **Command:** `flutter build apk --debug --flavor field --split-per-abi`
   - **Exit Code:** `0`
   - **Committed Raw Evidence Files in Repository:**
     - Full Merged Manifest: [`docs/privacy/evidence/field-debug-merged-manifest.xml`](evidence/field-debug-merged-manifest.xml) (8,555 bytes, SHA-256: `9347e5df2068fd1529f9c977d1f00831f8f89e4204c003399a866facdc979086`)
     - Full Merger Blame Report: [`docs/privacy/evidence/field-debug-manifest-merger-blame-report.txt`](evidence/field-debug-manifest-merger-blame-report.txt) (Committed sanitized: 22,225 bytes, SHA-256: `4f86f2c210f3e5d5e29edec896509a62064a7b602b251c592f696c8f9adebd65`; Raw verified intermediate: 24,405 bytes, SHA-256: `a584024c18979bd96f25353be7bf00c8bac020130813cafa416bad322beb47ad`)
   - **Effective Merged Manifest (`build/app/intermediates/merged_manifests/fieldDebug/processFieldDebugManifest/arm64-v8a/AndroidManifest.xml`):**
     - File Size: `8555 bytes`
     - SHA-256 Digest: `9347e5df2068fd1529f9c977d1f00831f8f89e4204c003399a866facdc979086`
   - **Merger Blame Report (`build/app/intermediates/manifest_merge_blame_file/fieldDebug/processFieldDebugMainManifest/manifest-merger-blame-field-debug-report.txt`):**
     - Raw Intermediate: `24405 bytes`, SHA-256 Digest: `a584024c18979bd96f25353be7bf00c8bac020130813cafa416bad322beb47ad`
     - Committed Sanitized Evidence: `22225 bytes`, SHA-256 Digest: `4f86f2c210f3e5d5e29edec896509a62064a7b602b251c592f696c8f9adebd65` (user home paths sanitized to `<REPO_ROOT>` and `<GRADLE_USER_HOME>`)
   - **Merged Manifest / aapt2 dump badging:**
     ```text
     package: name='com.cbstudio.telltale' versionCode='152' versionName='1.0.14' platformBuildVersionName='16' platformBuildVersionCode='36' compileSdkVersion='36' compileSdkVersionCodename='16'
     targetSdkVersion:'36'
     application-label:'Telltale'
     application: label='Telltale' icon='res/BW.xml'
     ```

This confirms across both Release and Debug variants:
- Zero custom `android:allowBackup` attribute (defaults to platform `true`).
- Zero custom `android:fullBackupContent` attribute.
- Zero custom `android:dataExtractionRules` attribute.

### 4.2 Offline Dependency Graph Output Digest and Gate Evidence Boundaries

To maintain full transparency and reproducibility regarding third-party dependencies:
1. **Raw Dependency Graph Command Output:**
   - **Command:** `flutter pub deps --style=compact`
   - **Tool Environment:** `Flutter 3.47.0 (Dart 3.13.0)`
   - **Input Subject:** `pubspec.lock` (SHA-256: `0c59c66b40489b3490b71b64be682387dd27ebde0db6205f73bc4c87d585b90c`)
   - **Exit Code:** `0`
   - **Raw Stdout SHA-256 Digest:** `5644195d11ff649ae502c03e52b2ed9aff446aed9369121bf3d919a2db99da0a`
2. **Formal Gate Verification Boundary:**
   - In accordance with review governance, raw CLI string outputs from `pub deps` are not parsed as gate acceptance proof.
   - Formal gate verification (`tool/workshop/validate_privacy_contract.py`) enforces fail-closed evidence: direct cryptographic SHA-256 verification of 191 audited source files, `pubspec.lock` exact integrity check, and regex word-boundary scanning for prohibited SDK identifiers (`appsflyer`, `facebook`, `firebase`, `flurry`, `google_mobile_ads`, `mixpanel`, `sentry`) across all declared roots.

### iOS and macOS Effective Configuration:
1. **iOS Sandbox:** `Documents/` is backed up to iCloud/iTunes by default unless explicitly tagged with `NSURLIsExcludedFromBackupKey`. `Library/Caches/` and `tmp/` are excluded by the OS.
2. **macOS Sandbox:** App Sandbox is enforced via `macos/Runner/Release.entitlements` (`com.apple.security.app-sandbox = true`). Local data resides in container directories.
3. **Parity Assurance:** Policy documents acknowledge system backup inclusion while clarifying that Telltale does not configure or request proprietary app-level iCloud sync entitlements.
4. **Verification Status:** Static contract and directory mapping verified; live cloud/D2D physical restoration experiments are classified as `NOT_RUN`.

---

## 5. Verification Gate and Mutations

Verification is enforced by:
1. `tool/workshop/validate_privacy_contract.py`: Deterministic offline Python validator enforcing schema, source SHA-256 digests, storage facts, comment/code symbol presence, path containment, and 4-way visible policy text parity.
2. `test/tool/test_validate_privacy_contract.py`: Python unit tests with genuine fail-closed mutations (M1–M7) and non-leak assertion.
3. `test/privacy/privacy_policy_contract_test.dart`: Dart 4-way policy text parity contract test with required keywords and forbidden contradiction checks.
4. `test/privacy/privacy_data_flow_contract_test.dart`: Dart runtime data flow & zero-handoff contract test across all 5 export methods, widget 0-call assertions, and cache vs canonical segregation.
5. `test/privacy/platform_backup_contract_test.dart`: Dart platform backup configuration contract test parsing XML and Plist element attributes.
