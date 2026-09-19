# Gate 2 limited device acceptance contract

Issue #104; fixed APK source `1ad08253e86ec6a6aef2b706cd0b6729372da3b3`;
APK SHA-256 `acc80f75b599d7f85e5c11416ec6c2e92f774f6b9e1699584414ca35abbade9e`.
The old, longer specification remains in Git history and the immutable ZIP.
This correction changes no business code, protocol expectation or old evidence.
Read [the inspected disposition](gate2_device_acceptance_report.md) before using
an archived PASS table. A specification is not an executed device test.

## Fixed scope

Synthetic loopback endpoint and identified Android emulator/test device only.
No physical OBD interface/vehicle, active actuator, store upload or Gate3.
Freeze actual APK, installation receipt, device image, scenario/fixture/controller
versions and locale. A different binary is a different candidate; a document edit
is not a reason to rebuild the existing one.

## D02: negotiated complete result and clean-refusal fallback

Start H0, click the actual App discovery control, and observe its ATH1 negotiation
under the existing composite owner. Use the pinned scenario:

| Query | Application reply | Expected |
|---|---|---|
| 0800 | 48 00 80 00 00 01 | TIDs $01/$20; query next block |
| 0820 | 48 20 40 00 00 00 | TID $22; no further block |

In H1 the rig renders the legal source ID/PCI; in H0 it does not. A positive result
has `{1,32,34}`, trusted `7E8` and no false partial warning. Clean ATH1 refusal
preserves known H0, still returns legal anonymous data and exposes cross-block
source/coverage uncertainty. Do not force header bytes into an H0 positive control.
The two observed device cases are accepted with the report's precise limits.

Bitmask erratum: `48 00 00 00 00 01` means $20 + continuation, not $01;
`48 00 00 00 00 02` means $1F, not $02. Multi-node fixtures are a separate existing
software case, not an added device prerequisite. Refusal/wire-zero/uncertainty
negative cases retain their accepted host regressions, not invented device logs.

## D05: actual Mode08 query crossing Android lifecycle events

The contract is **not** just generic dashboard polling or a test-container session
replacement. Preserve existing Track A OS observations and Track B host regression,
but label them at their own layer.

For the original three HOME / screen-off / HOME runs:

1. Start a unique run and capture the App/controller/endpoint identities.
2. Confirm that this App's 0800 or 0820 arrived and its response is still held.
3. Issue the real Android action on the explicit device; capture actual OS and
   controller observations. Fixed sleep can be pacing, not proof of a barrier.
4. Resume, release or cancel under the existing session contract; observe the
   resulting Mode08 UI. Correct safe cancellation is not forced into success.
5. Save the run's PNG once and immediately record its hash plus query/event
   identifiers. Different runs may legitimately have identical pixels/hashes.

Keep actual TX/RX distinct from expected fixture data. Internal counters may be
reported only if actually observed; do not print a presumed pauseEpoch or write
`PowerManagerService` prose and call it logcat. Distinguish UTC, device wall clock
and monotonic time. Do not assume identical host/device epochs. Never overwrite
historical evidence to obtain a desired terminal image or claim memory-leak tests
from navigation screenshots.

## D08: equivalent outcomes across locales

Compare the existing success/partial/unknown scenarios in English and Traditional
Chinese. TIDs, NRC and support/completeness classification must agree; localize
App-authored explanation and retain raw protocol values as diagnostics. Do not
replace a success in one language with an unrelated unknown in the other.
The six current PNGs support those paired displayed outcomes. This is not an
additional ten-case hardware matrix or a whole-product translation requirement.

## Host CI is explicitly different

`mode08_d05_supplement_test.dart` now tests host TCP receipt barriers and synthetic
session retirement only. It does not produce device evidence. The preserved old
supplement is annotated accordingly. `tool/ci/run_mode08_required.py` starts the
project reference on a dynamically allocated loopback port, runs the six existing
oracle tests and three host regressions, checks the original process exit and
existing JSON no-skip guard, and terminates its own server. No tracked evidence
is rewritten and no APK hash is assigned to a host test run.

Do not repeat unchanged suites for document timestamp cosmetics. Software fixes,
source/CI acceptance, artifact integrity and actual device qualification remain
separate. Refer to the report for the remaining D05 criterion; #104 stays open
until that criterion is supported or explicitly deferred without relabeling PASS.
