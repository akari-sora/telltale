# AA-09 — Android Auto metric graphics

Status: metric graphics plus exact-source signed disconnect/reconnect and DTC
navigation gates verified (2026-10-12). MR/main release CI remains an independent
acceptance surface.

Home, Health and Powertrain previously presented metrics as text-only rows.
The graphic pass adds monochrome vector symbols for each metric and redundant
semantic warning tint while retaining each localized title, reading and unit.
The shared car-core implementation also applies to AAOS.

## Design decision

See [DESIGN.md](../../DESIGN.md), especially Information architecture,
Visual language, Accessibility and Implementation constraints.

[Pane refresh rules](https://developer.android.com/reference/androidx/car/app/model/PaneTemplate)
require stable template titles, row counts and row titles. Live values therefore
remain secondary text. The IoT prototype uses established templates; no custom
Surface, animated gauge, bitmap chart, range assumption or fabricated history
is introduced. Full curves remain on the phone. The read-only bridge, approximately 1 Hz model-diff refresh, speed arbitration,
localization and parked-only diagnostic behavior are retained.

Icons use resource-backed CarIcon with host-default tint. Established warning
states request semantic warning tint and preserve warning text because the host
may override color. Missing/stale readings retain their existing text; icon
presence does not claim a current reading or healthy vehicle.

This local engineering result does not resolve the [AA-00 category gate](aa-00-eligibility.md)
or establish production Google Play approval.

## Verification record

The capture archive is `telltale-aa-graphics-20261011` in the October 11 task's
`artifacts` directory. It keeps unmodified PNGs, installed-APK hash readbacks,
fixture command traffic, test output and owned-resource cleanup separately.
The previous AA-06 archive remains historical and was not overwritten.

| Verified case | Source and evidence | Result |
| --- | --- | --- |
| Shared metric graphics | `b4f5c5d89803270366e8f11da895a304c0b81a73`; 9 resource vectors, localized static titles, read-only rows | No custom surface, changing title, chart history or new dependency |
| Native car-core / carProto suites | `fe5d04ebb862b58bff024036835afbfee0a49f5d`; `native-tests/final-readback.json` | 227 / 57 tests; zero failures, errors or skips |
| Dart lease/lifecycle/bridge regression | Same source; `late-lease-regression.log` | 27 tests passed, including background drain and reconnect |
| Final consumed-generation guard | `73f87ab097620d2a5605e66fc6f9b47f0fe4e440`; `native-tests/guard-final-carproto/readback.json` and final lease test output | 59 native tests and 11 focused Dart lease tests passed; repeated unarmed generation, failed start, foreground recovery and newer generation covered |
| Final normal phone APK build | Same final source; `apks/final-build-receipt.json` | `carProtoDebug`, normal `lib/main.dart`; SHA-256 `a9a8e559cc5875fc148a7561b12ec41c01db31e568914d7be9b4eedb946f939d` |
| Final Dart lease/lifecycle/bridge regression | Same final source; `guard-final-dart.log` | 28 tests passed, including failed background attempt, foreground recovery and newer projection generation |
| Projected 800×480 Home/Health/Powertrain | Initial graphics APK SHA-256 `fb59c74e4e8f22e69c59864a38a74056daf068bdbcc086bfb7b93e04cb0eda6b`; `device/p1-*.png` | Metric icons and localized text readable; host scroll reaches lower rows |
| Host day/night commands | Same initial graphics source and captures | This DHU/host retained its dark palette in both modes; no app light-theme or measured contrast-ratio claim |
| Background-first normal phone → Android Auto | `fe5d04e`; repaired normal `lib/main.dart` APK SHA-256 `b10423e38ec4786c7ec705feb7e0f1fb32ca4d3e1c37eeb2ad9328d607333a96`; `device/final/aa-p1-home-background-cold-day.png` | Phone was paused before opening Telltale in DHU; service notification 4102 and live 0 km/h, 800 RPM, 88 °C appeared without foregrounding the phone |
| Final-source background-first handoff | `73f87ab0`; final APK above; `device/guard-final/aa-p1-home-background-latelease-final.png` | On S24 / Android 16, MainActivity in an owned virtual display was stopped and invisible before DHU opened. It stayed stopped while service 4102 became foreground and controlled 0/800/88 readings appeared; the personal primary display remained untouched |
| Final-source high-temperature graphics | Same source/APK; `device/guard-final/aa-p1-*-high-coolant-final.png` | Controlled 120 °C appeared with red temperature icons and redundant warning text on Home and Powertrain |
| Final-source phone curves and cleanup | Same source/APK; `emulator-final/result.md` and raw zh-TW captures | Android 16 phone emulator rendered built-in Demo gauges and trend curves; installed hash matched; owned emulator/private ADB stopped and ports released |
| AAOS 1024×768 native speed | Graphics source `b4f5c5d`; APK SHA-256 `8d94ab5e4e6fff343af7eee3b33ca29290a89eb38db12da02a844a25fe5513f6`; `aaos/verified-captures.json` | Cold read-only boot; current driver speed permission; official VHAL debug set/read yielded 0 → 48 → 0 km/h. Other OBD values correctly remain absent |
| AAOS cleanup | `aaos/cleanup.json` | Overlay app removed; owned emulator and private ADB stopped; ports 15039/5584/5585 free |

The AAOS emulator initially hit a platform CarPropertyService/VHAL lock on a
saved-snapshot/host-restart path. A fresh boot and the official VHAL debug
interface restored native speed updates. Headless rendering also produced
intermittent incomplete frames affecting static system text; those diagnostic
captures are retained separately from complete selected images. These runs do
not establish physical head-unit rendering performance.

## Projection handoff repair

The initial UI pass reproduced an existing ordering defect: phone pause drained polling
before Android Auto sent its active session lease. Both Dart and native admission
then required the phone Activity to be foreground, blocking the existing
background ATRV proof. Admission now uses the exact projection identity, current
projection connection and registered engine; the existing OBD generation and
ATRV validation still decide whether polling resumes. No second engine or OBD
connection is created.

A signed-release DHU walk subsequently reproduced a separate defect: projection
disconnect stopped the foreground service, Android closed the OBD TCP socket,
and a new car session displayed missing values while the phone stayed hidden.
The repair gives the user-connected OBD transport its own exact-generation
service owner. Only a foreground phone with a connected non-Demo OBD transport
may claim that owner; built-in Demo does not create a connected-device service.
Pending and confirmed owners retain the existing Flutter engine.

Projection arm attaches to an already confirmed producer and never starts a
foreground service. Projection disconnect drains the read-only poller before
acknowledgement, releases the wake lock, and retains the transport owner. A new
projection reuses that connection and the existing ATRV validation before
resuming periodic reads. Diagnostics remain foreground-only. Disconnect, link
loss, replacement and runtime disposal retire the exact producer; stale
callbacks cannot retire a newer connection. Missing drain acknowledgement
still fails closed after eight seconds.

This ownership split follows Android's
[foreground service start restrictions](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start)
and the independent [car Session lifecycle](https://developer.android.com/reference/androidx/car/app/Session).
It does not assume a car callback exempts a background foreground-service start.
The previous device receipts above remain historical and were not overwritten.
Fresh signed repair acceptance passed on source
`93c4708861ac9f4c1c1c9d4ae983dbfa44bafc85` (tree
`102f4b146fe94cb332b48255f199fad1abc63839`) with the exact arm64
`carProto` APK SHA-256
`f31b7d949b1a3883e69a37c1207b0e4646fab4140338814fc704ce5a77526466`.
The same source passed 4,364 Flutter tests with 23 opt-in skips, 62 native
carProto tests, and Android lint with zero errors and 12 warnings.

After DHU exit and explicit phone HOME, a controlled 20-second window produced
zero fixture events and commands while the same TCP socket, producer foreground
service, and app process remained alive. DHU reconnect did not foreground the
phone; it reused that process and socket and resumed with `ATRV` before PID
reads. DTC summary/detail/back and Powertrain navigation passed. Fault Codes did
not navigate at 55 m/s or with unknown speed and opened at 0 m/s. No toast text
is claimed because no persisted toast image or log was captured. The host
remained dark, so Android Auto light-theme rendering is not claimed.

The acceptance manifests record the exact source, installed APK, screen
profiles, safety gates, phone-hidden interval, reconnect traffic, and owned
cleanup. Raw receipts remain in the external task bundle and are summarized
here without fragile repository-relative links. MR/main release CI is
independent of this device acceptance. Controlled ELM data and simulated VHAL
data do not prove Bluetooth, an actual adapter, ECU, real vehicle, Google
approval, or production Play eligibility.
