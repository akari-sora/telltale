# Telltale full gate

The Grok on-demand project Runner remains the execution target. Its paused or
offline state is an execution dependency, not a test PASS. This repository does
not unpause a runner or run a privileged host command from job code.

Main and same-project merge requests use the same project-specific tags
`grok-box`, `ondemand`, and `telltale`, and
`docker.io/plugfox/flutter@sha256:9cc3fb4d2c742c21d8bb6ab16eef657810b27ac78429920c6cd644dc8e158e22`.
The remote Docker Runner pulls this verified, immutable public image directly;
it does not depend on a host-local image bootstrap. SaaS gate routing is disabled in
`.gitlab-ci.yml`; `CI_GATE_RUNNER=hosted` does not enable a fallback job.
An offline runner cannot be bypassed by setting that variable.

The pinned `plugfox/flutter:3.47.0-android` amd64 image provides the Android SDK
at `/opt/android`. The isolated `prepare_gate.sh` step installs any missing
Python, build, Android 36, build-tools 36, and NDK 28.2 dependencies inside the
job container before non-root execution. No host-privileged preparation command
is required. A replacement execution environment must still verify the image,
project scope, exact tags, host isolation, and single-job ownership before
activation. It must execute the unchanged gate and preserve complete artifacts.
The Flutter SDK version is checked against `.fvmrc`. No deployment or store
action is part of the gate.

`full_gate.sh` preserves each command, separate stdout/stderr and original exit,
runs analysis, Python tool tests, Python reference tests, all Flutter tests,
required Mode08 TCP integration and the debug field APK build. Optional unrelated
oracle skips in the ordinary suite remain visible. The required Mode08 run may
not skip: it uses nine visible cases (six existing oracle + three explicitly
host-only session tests) and `tool/oracle_guard/assert_no_skips.py`.

Artifacts are uploaded on failure as well as success for 14 days. APK hashes name
new CI outputs; they do not inherit any older candidate's device qualification.
No copied/generated Android events can count as a device run.

A metadata/runner guard was executed in the review environment: 11 Python tests
passed; Python compilation, bash syntax and YAML parsing also passed. Flutter and
APK build results must come from the actual candidate pipeline, not these tests.

Image source: https://hub.docker.com/layers/plugfox/flutter/3.47.0-android/images/sha256-9cc3fb4d2c742c21d8bb6ab16eef657810b27ac78429920c6cd644dc8e158e22
Runner: https://docs.gitlab.com/runner/executors/docker/
