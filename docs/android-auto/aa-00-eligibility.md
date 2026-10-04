# AA-00 — Android for Cars Eligibility Spike

Status: PROVISIONAL / NOT APPROVED FOR PRODUCTION DISTRIBUTION

## Scope

Telltale is evaluating a read-only vehicle-monitoring experience for:

- Android Auto projected apps
- Android Automotive OS templated apps

The production mobile package must remain unaffected until category
eligibility is confirmed.

## Provisional category

Prototype artifacts currently declare:

`androidx.car.app.category.IOT`

This is an engineering hypothesis, not a statement that Google Play has
accepted Telltale as an IoT car app.

Google documents IoT apps primarily as experiences for connected devices.
Vehicle OBD-II telemetry/diagnostics is not explicitly documented as an
accepted IoT use case.

## Isolation contract

The following production variants MUST NOT include Android for Cars metadata:

- field
- rig
- wear

Only:

- carProto
- :automotive prototype

may depend on `:car-core` while AA-00 is unresolved.

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
| Projected Prototype | `app-carProto-debug.apk` | `com.cbstudio.telltale.carproto` | Android Auto phone projection test vehicle |
| AAOS Prototype | `automotive-debug.apk` | `com.cbstudio.telltale.carproto.aaos` | Standalone Android Automotive OS test vehicle |
| Production ID | Release artifacts | Deferred until eligibility decision | Subject to Google Play single-listing vs separate-listing review |

## Promotion criteria

Production Android Auto/AAOS support may not be enabled until all of:

1. Android for Cars category eligibility has been validated.
2. Google Play review strategy is documented.
3. Production artifact category is explicitly approved.
4. Driver-distraction policy is implemented.
5. AA-02 telemetry bridge is read-only and versioned.
6. DHU / AAOS emulator acceptance gates pass.

Until then, `carProto` remains non-production.
