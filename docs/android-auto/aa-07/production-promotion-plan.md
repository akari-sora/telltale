# Architecture Decision Record (ADR): Production Promotion Topology (AA-07)

**Status:** APPROVED / CANONICAL ADR  
**Date:** 2026-10-05  
**Context:** Transitioning Android for Cars capabilities from prototype spike (`carProto`) to Google Play Store production distribution.  
**Package:** `com.cbstudio.telltale`  

---

## 2026-10-12 integration decision (supersedes the field fallback below)

The normal `field` artifact now includes phone and Android Auto functionality
under `com.cbstudio.telltale`. A user installs one app and shares the same OBD
connection, settings, and diagnostic reports between phone and projected screens.
The former emergency phone-only `fieldRelease` topology described below is a
historical decision and no longer describes 1.0.19 builds. `rig` and `wear` still
exclude projected-car services; the standalone AAOS artifact remains separate.

The first distribution target is Google Play internal testing. Before creating
or promoting a Play release, read back consumed bundle codes and the actual Play
app-signing certificate, then compare them with the installed test phone. A
signer mismatch cannot be repaired by `adb install -r`; preserve data and resolve
the migration explicitly. Internal App Sharing uses a separate signing key and
is not interchangeable with the internal test track.

Automotive category acceptance remains pending. Integration, internal testing,
and the user's selected DHU simulation do not establish Google production
approval or actual vehicle/head-unit compatibility. All CI and signed builds
must run on the selected Ryzen 9700X, with exact-source acceptance and ephemeral
signing inputs; the normal public APK/AAB uses one package identity.

## 1. Context & Problem Statement

Prior to Phase AA-07, `docs/android-auto/aa-00-eligibility.md` established an isolation contract:
> "The production mobile package must remain unaffected until category eligibility is confirmed. ... Only `carProto` and `:automotive` prototype may depend on `:car-core`."

With the completion of Phase AA-06 (comprehensive Desktop Head Unit verification, 1,884-second AAOS soak testing, rotary navigation, and VHAL speed injection passing all 107 clauses) and Phase AA-07 Phase 01 (category fit confirmation, localization hardening, and Fastlane store asset integration), the engineering requirements for automotive distribution are fully satisfied.

However, distributing an automotive app to Google Play involves distribution risks:
- If an automotive bundle is bundled directly into the primary production mobile track without gating, an automotive review rejection or delay would block emergency bug fixes for the core mobile phone application.
- Therefore, a robust, phased promotion topology is required.

---

## 2. Decision Matrix & Evaluated Options

### Option A: Monolithic Single-Step Release (Direct Merge into `fieldRelease`)
- **Description:** Directly include `:car-core` and automotive metadata into `fieldRelease` and submit to Google Play Production track.
- **Pros:** Single APK/AAB bundle, simplest build pipeline.
- **Cons:** **EXTREME RISK**. If Google Play review takes 7–14 days for car qualification or raises non-binary feedback, mobile phone updates are completely blocked.
- **Verdict:** **REJECTED**.

### Option B: Permanent Separate Listing for Car OS (`com.cbstudio.telltale.automotive`)
- **Description:** Maintain two distinct Google Play store listings: one for Phone/Android Auto projection (`com.cbstudio.telltale`) and one for Standalone Android Automotive OS (`com.cbstudio.telltale.automotive`).
- **Pros:** Complete isolation of store ratings and reviews; AAOS can be updated independently.
- **Cons:** Fragmented branding; users must discover two separate listings; double administrative overhead.
- **Verdict:** **DEFERRED for AAOS embedded OEMs only**.

### Option C: Dual-Track Architecture (Dedicated AAOS Track + Phased Phone Bundle) (SELECTED)
- **Description:** Align with Google Play Console's actual form factor release topology:
  1. **Android Automotive OS (AAOS Dedicated Track):** AAOS is managed via Google Play's dedicated "Android Automotive OS" form-factor track. The standalone `:automotive` AAB/APK can be built, uploaded, reviewed, and rolled back completely independently of the mobile app.
  2. **Android Auto (Integrated Mobile Bundle):** Android Auto is delivered as part of the phone/tablet application bundle (`:app` with `:car-core` integrated). In Google Play, Android Auto review is **non-blocking** on Internal/Closed testing tracks, but **blocking** on Open/Production tracks.
  3. **Emergency Phone Bypass (`fieldRelease`):** The existing pure mobile flavor (`fieldRelease`) maintains strictly zero car dependencies and zero car manifest declarations. If an integrated phone bundle faces unexpected car review blocking or latency on Production, `fieldRelease` can be deployed immediately to unblock critical mobile hotfixes.
- **Pros:**
  - Accurately matches Google Play's actual platform track mechanics (no phantom "Android Auto track").
  - AAOS enjoys complete track autonomy and independent rollback.
  - Mobile phone updates have a guaranteed zero-downtime escape hatch via `fieldRelease`.
- **Verdict:** **ACCEPTED & SELECTED**.

---

## 3. Promotion Topology Architecture

```
[ Git Main Branch ]
         │
         ├──> :car-core (Shared Car Logic, Templates & Localizations)
         │         │
         │         ├──> [ Standalone AAOS Bundle (:automotive) ]
         │         │         │
         │         │         └──> Google Play Dedicated "Android Automotive OS" Track
         │         │                   (100% Independent Release, Review & Rollback)
         │         │
         │         └──> [ Integrated Phone+Auto Bundle (:app car-integrated) ]
         │                   │
         │                   ├──> Phase 1: Closed Testing Track
         │                   │         │   (Android Auto review is non-blocking)
         │                   │         └──> Reviewer verification with Zero-Hardware Guide
         │                   │
         │                   └──> Phase 2: Production Track Promotion
         │                             (Android Auto review is blocking for this bundle)
         │
         ├──> :app (fieldRelease - Pure Phone Bundle, Zero Car Manifest/Deps)
         │         │
         │         └──> Emergency Phone Production Track (Bypasses car review entirely)
         │
         └──> lib/obd/ (100% Isolated Pure Protocol Layer - 0 Changes)
```

---

## 4. Promotion Gate Criteria

Before a build may be promoted from Closed Testing to Google Play Production, all of the following gates must be satisfied:

1. **Category Acceptance:** Google Play App Review approves the `androidx.car.app.category.IOT` declaration on the closed testing track without blocking feedback.
2. **Crash-Free Sessions:** Closed testing metrics report >= 99.9% crash-free sessions over a minimum 7-day observation window.
3. **Driver Distraction Zero-Defect:** Zero reports of diagnostic screen access while vehicle is in motion.
4. **CI Matrix Green:**
   - `tool/ci/full_gate.sh` 100% PASS.
   - `python3 tool/ci/verify_car_manifest_isolation.py` PASS.
   - `:car-core:testDebugUnitTest` PASS (including string parity, BiDi isolation, and screen rendering).
   - Core OBD layer (`lib/obd/`) maintains 0 diff.

---

## 5. Rollback Strategy & Emergency Brake

If an unexpected rejection or policy clarification is requested by Google Play during automotive review:
1. **AAOS Dedicated Track Isolation:** Because Android Automotive OS uses a dedicated form-factor track in Google Play Console, an AAOS release can be halted, rolled back, or staged independently without touching the phone app.
2. **Android Auto Integrated Bundle Realities:** Because Android Auto does not have a separate Play Store release track (it is embedded within the phone AAB/APK artifact), Android Auto cannot be rolled back independently of the phone build.
3. **Emergency Mobile Brake (`fieldRelease`):** If an integrated Phone+Auto build is held or rejected by Google Play during production review, the release engineer immediately deploys `fieldRelease` to the Phone Production track. Because `fieldRelease` is strictly verified by `verify_car_manifest_isolation.py` to contain 0 car manifest declarations and 0 car dependencies, Google Play treats it as a standard phone-only update, bypassing all automotive review queues in minutes.
4. **Appeal Execution:** If the reviewer misunderstands the IoT peripheral sensor classification, execute the pre-drafted appeal playbooks documented in `docs/android-auto/aa-07/reviewer-guide.md` Section 5.
