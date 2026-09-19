# Gate 2 Candidate APK Artifact Fingerprint & Verification

**Target Reference**: GitLab Issue #104 (Note 3857735494)  
**Verification Target**: Gate 2 Field Debug Candidate APK  
**Build Timestamp**: 2026-09-18T11:19:47Z  
**Build Result**: Clean Build (Exit Code 0, Duration: 30.9s)  
**Artifact Path**: `build/app/outputs/flutter-apk/app-field-debug.apk`  
**Verification Status**: PASS (Clean Build, Valid v2 Signature, Verified Manifest Metadata)

---

## 1. Git Provenance & Commit Lineage

The candidate APK was built directly from the verified Gate 2 commit HEAD with a clean working tree matching the audited test provenance package.

| Property | Value |
|---|---|
| **Commit HEAD** | `1ad08253e86ec6a6aef2b706cd0b6729372da3b3` |
| **Git Tree SHA** | `23fef0783e9cb6ca783de677ecc3196bebb498d8` |
| **Branch** | `candidate/boost-gate2-candidate-20260917` |
| **Parent Commit** | `444afd352d704f8f1065bf056e4501787a203818` |
| **Commit Subject** | `fix(obd): retain header state on command refusal and enforce adapter error classification` |

### 1.1 Git Tree Verification Proof
```bash
$ git rev-parse HEAD
1ad08253e86ec6a6aef2b706cd0b6729372da3b3

$ git rev-parse HEAD^{tree}
23fef0783e9cb6ca783de677ecc3196bebb498d8
```

---

## 2. Candidate Artifact Identity & Cryptographic Checksums

| Artifact Property | Value |
|---|---|
| **Relative Path** | `build/app/outputs/flutter-apk/app-field-debug.apk` |
| **File Name** | `app-field-debug.apk` |
| **File Size (Bytes)** | `173856260` bytes (173,856,260 B / ~165.8 MiB) |
| **SHA-256 Checksum** | `acc80f75b599d7f85e5c11416ec6c2e92f774f6b9e1699584414ca35abbade9e` |
| **SHA-1 Checksum** | `2be659150f6afa42af5c3a8359789b363bc2f9c4` |
| **MD5 Checksum** | `cc14c39dad2573d815f092aa0eea3ada` |

### 2.1 Checksum Verification Evidence
```bash
$ stat -f %z build/app/outputs/flutter-apk/app-field-debug.apk
173856260

$ shasum -a 256 build/app/outputs/flutter-apk/app-field-debug.apk
acc80f75b599d7f85e5c11416ec6c2e92f774f6b9e1699584414ca35abbade9e  build/app/outputs/flutter-apk/app-field-debug.apk

$ shasum -a 1 build/app/outputs/flutter-apk/app-field-debug.apk
2be659150f6afa42af5c3a8359789b363bc2f9c4  build/app/outputs/flutter-apk/app-field-debug.apk
```

---

## 3. Android Package & Manifest Metadata

Extracted using Android Asset Packaging Tool (`aapt`) from Android SDK Build-Tools 36.0.0.

| Manifest Attribute | Configured / Extracted Value | Specification Requirement | Verification Result |
|---|---|---|---|
| **Package ID** | `com.cbstudio.telltale` | `com.cbstudio.telltale` | MATCH |
| **Version Name** | `1.0.14` | `1.0.14` | MATCH |
| **Version Code** | `15` | `15` | MATCH |
| **minSdkVersion** | `24` (Android 7.0 Nougat) | `24` | MATCH |
| **targetSdkVersion** | `36` (Android 16) | `36` | MATCH |
| **compileSdkVersion** | `36` (Android 16) | `36` | MATCH |
| **Debuggable** | `android:debuggable="true"` | `true` | MATCH |
| **Target Flavor** | `field` | `field` | MATCH |
| **Main Activity** | `com.cbstudio.telltale.MainActivity` | Main Entrypoint | MATCH |
| **Native Architectures** | `arm64-v8a`, `armeabi-v7a`, `x86_64` | Multi-ABI debug | MATCH |

### 3.1 `aapt dump badging` Extract
```text
package: name='com.cbstudio.telltale' versionCode='15' versionName='1.0.14' platformBuildVersionName='16' platformBuildVersionCode='36' compileSdkVersion='36' compileSdkVersionCodename='16'
sdkVersion:'24'
targetSdkVersion:'36'
application-label:'Telltale'
application-debuggable
launchable-activity: name='com.cbstudio.telltale.MainActivity'  label='' icon=''
native-code: 'arm64-v8a' 'armeabi-v7a' 'x86_64'
```

### 3.2 Binary XML Tree Inspection
```bash
$ aapt dump xmltree build/app/outputs/flutter-apk/app-field-debug.apk AndroidManifest.xml | grep -E "package|version|debuggable|minSdkVersion|targetSdkVersion|compileSdkVersion"
    A: android:versionCode(0x0101021b)=(type 0x10)0xf
    A: android:versionName(0x0101021c)="1.0.14" (Raw: "1.0.14")
    A: android:compileSdkVersion(0x01010572)=(type 0x10)0x24
    A: android:compileSdkVersionCodename(0x01010573)="16" (Raw: "16")
    A: package="com.cbstudio.telltale" (Raw: "com.cbstudio.telltale")
      A: android:minSdkVersion(0x0101020c)=(type 0x10)0x18
      A: android:targetSdkVersion(0x01010270)=(type 0x10)0x24
      A: android:debuggable(0x0101000f)=(type 0x12)0xffffffff
```

*(Note: `0xf` = 15, `0x18` = 24, `0x24` = 36, `0xffffffff` = boolean true)*

---

## 4. Signature & Alignment Verification

Verified via `apksigner verify --verbose --print-certs` and `zipalign -c -v 4`.

### 4.1 Signature Scheme Status
| Scheme | Status | Details |
|---|---|---|
| **v1 Scheme (JAR signing)** | `false` | Not required for APK Signature Scheme v2 on Android 7.0+ (minSdk 24) |
| **v2 Scheme (APK Signature Scheme v2)** | `true` | **Verified and active** |
| **v3 Scheme (APK Signature Scheme v3)** | `false` | Standard debug keystore configuration |
| **v3.1 Scheme** | `false` | Standard debug keystore configuration |
| **v4 Scheme** | `false` | Standard debug keystore configuration |
| **Overall Verification** | `Verifies` | **Signature is valid and tamper-evident** |

### 4.2 Signing Certificate Details
- **Signer #1 Certificate DN**: `C=US, O=Android, CN=Android Debug`
- **Certificate SHA-256 Digest**: `64500eefad1aeb8e163c2ceeaa78b39ce013849f1a75596dd1b477fc5d023736`
- **Certificate SHA-1 Digest**: `077a3d7511a392e68ffe2ee4eff3deefdaa1299b`
- **Certificate MD5 Digest**: `d54e292feff8a2f06be6ad41dfbae565`
- **Key Algorithm**: `RSA` (2048 bits)
- **Public Key SHA-256 Digest**: `656802a4ba3c520752184032cb935422cc30170f1b32c1290bc4263e9382b9b6`

### 4.3 Verbatim `apksigner` Output
```text
$ apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-field-debug.apk
Verifies
Verified using v1 scheme (JAR signing): false
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): false
Verified using v3.1 scheme (APK Signature Scheme v3.1): false
Verified using v4 scheme (APK Signature Scheme v4): false
Verified for SourceStamp: false
Number of signers: 1
Signer #1 certificate DN: C=US, O=Android, CN=Android Debug
Signer #1 certificate SHA-256 digest: 64500eefad1aeb8e163c2ceeaa78b39ce013849f1a75596dd1b477fc5d023736
Signer #1 certificate SHA-1 digest: 077a3d7511a392e68ffe2ee4eff3deefdaa1299b
Signer #1 certificate MD5 digest: d54e292feff8a2f06be6ad41dfbae565
Signer #1 key algorithm: RSA
Signer #1 key size (bits): 2048
Signer #1 public key SHA-256 digest: 656802a4ba3c520752184032cb935422cc30170f1b32c1290bc4263e9382b9b6
Signer #1 public key SHA-1 digest: 0a245687d1375d0ff0843293903c415e514c7f3c
Signer #1 public key MD5 digest: bf0adeab7aa7dfaaed82751dd6396df2
```

### 4.4 4-Byte 32-Bit Alignment (`zipalign`)
```bash
$ zipalign -c -v 4 build/app/outputs/flutter-apk/app-field-debug.apk
...
Verification successful
```

---

## 5. Build Toolchain & Environment Specifications

| Component | Specification |
|---|---|
| **Build Command** | `flutter build apk --debug --flavor field` |
| **Build Duration** | 30.9 seconds (assembleFieldDebug) |
| **Flutter SDK** | `Flutter 3.47.0 • channel stable` |
| **Flutter Framework Revision** | `4cf2416426` (2026-08-11 11:53:49 -0700) |
| **Flutter Engine Hash** | `59d54a2b2896a6bbf356c94b7fac7b9e235bdacd` |
| **Dart SDK** | `Dart 3.13.0` |
| **JDK / JVM** | `Amazon Corretto-17.0.15.6.1 (build 17.0.15+6-LTS)` |
| **Gradle Distribution** | `Gradle 9.3.1` (commit `44f4e8d3122ee6e7cbf5a248d7e20b4ca666bda3`) |
| **Android Build-Tools** | `36.0.0` |
| **Host Operating System** | `macOS 26.6.2 (Darwin Kernel Version 25.6.0 arm64)` |

---

## 6. Independent Verification Command Reference

Auditors, reviewers, and external contributors can independently verify this candidate APK artifact using standard tools:

```bash
# 1. Verify exact SHA-256 checksum
shasum -a 256 build/app/outputs/flutter-apk/app-field-debug.apk
# Expected: acc80f75b599d7f85e5c11416ec6c2e92f774f6b9e1699584414ca35abbade9e

# 2. Verify file size in bytes
stat -f %z build/app/outputs/flutter-apk/app-field-debug.apk
# Expected: 173856260

# 3. Verify Android Package & SDK Targets
aapt dump badging build/app/outputs/flutter-apk/app-field-debug.apk | grep -E "package|sdkVersion|targetSdkVersion|application-debuggable"

# 4. Verify Signature Scheme & Certificate Fingerprint
apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-field-debug.apk

# 5. Verify 4-byte zip alignment
zipalign -c -v 4 build/app/outputs/flutter-apk/app-field-debug.apk
```
