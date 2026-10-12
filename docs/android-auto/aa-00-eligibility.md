# AA-00 — Android for Cars Eligibility Spike

Status: INTEGRATED PHONE APP FOR TESTING / GOOGLE PRODUCTION CATEGORY REVIEW PENDING

## Scope

Telltale is evaluating a read-only vehicle-monitoring experience for:

- Android Auto projected apps
- Android Automotive OS templated apps

From 1.0.19, the normal `field` phone app includes Android Auto in the same
`com.cbstudio.telltale` installation. This supersedes the earlier prototype-only
isolation decision at the user's explicit request. The integration decision does
not establish Google Play automotive category approval or physical car acceptance.

## Provisional category

Prototype artifacts currently declare:

`androidx.car.app.category.IOT`

This is an engineering hypothesis, not a statement that Google Play has
accepted Telltale as an IoT car app.

Google documents IoT apps primarily as experiences for connected devices.
Vehicle OBD-II telemetry/diagnostics is not explicitly documented as an
accepted IoT use case.

## Isolation contract

The following variants MUST NOT include projected Android Auto components:

- rig
- wear

Projected Android Auto is included in:

- field (normal phone app)
- carProto (legacy development/testing identity)

The standalone `:automotive` artifact remains an AAOS form-factor build. All
three car-capable variants may depend on `:car-core`; AAOS-only permissions must
not leak into either projected phone variant.

## Forbidden prototype claims

The car experience is read-only.

It MUST NOT expose:

- Clear DTC
- adapter pairing/setup
- PID editing/reordering
- telemetry export/share
- service active tests
- performance timing
- destructive vehicle commands

## Prototype identities

| Target | Artifact | applicationId | Purpose |
| :--- | :--- | :--- | :--- |
| Integrated Phone + Auto | `app-field-release.aab` / field APKs | `com.cbstudio.telltale` | Normal app with phone and projected car screens sharing one connection |
| Projected Prototype | `app-carProto-debug.apk` | `com.cbstudio.telltale.carproto` | Android Auto phone projection test vehicle |
| AAOS Prototype | `automotive-debug.apk` | `com.cbstudio.telltale.carproto.aaos` | Standalone Android Automotive OS test vehicle |

## Promotion criteria

Google Play production promotion for automotive distribution requires all of:

1. Android for Cars category eligibility has been validated.
2. Google Play review strategy is documented.
3. Production artifact category is explicitly approved.
4. Driver-distraction policy is implemented.
5. AA-02 telemetry bridge is read-only and versioned.
6. DHU / AAOS emulator acceptance gates pass.

Engineering integration and internal testing can proceed before that review.
Real-head-unit installation uses a trusted Play testing source; the Android Auto
"unknown sources" option does not permit Car App Library apps. A DHU acceptance
record states the actual phone, APK, installation source, and simulated host.
It does not imply a physical vehicle/head-unit compatibility result.
