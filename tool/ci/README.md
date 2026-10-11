# Telltale full gate

The original Grok on-demand main runner/image remain the default. Its paused or
offline state is an execution dependency, not a test PASS. This repository does
not unpause a runner or run a privileged host command from job code.

Main and same-project merge requests use the same project-specific tags
`grok-box`, `ondemand`, and `telltale`, and
`localhost/telltale-ci-flutter:3.47.0`. SaaS gate routing is disabled in
`.gitlab-ci.yml`; `CI_GATE_RUNNER=hosted` does not enable a fallback job.
An offline runner cannot be bypassed by setting that variable.

The local image is based on the public `plugfox/flutter:3.47.0-android`
amd64 manifest pinned below, with `/opt/android-sdk-linux` pointing to
`/opt/android`. A replacement execution environment must verify that image,
project scope, exact tags, host isolation, and single-job ownership before
activation. It must execute the unchanged gate and preserve complete artifacts.
The SDK version is checked against `.fvmrc`; missing Android 36/build-tools
36/NDK 28.2 packages are installed inside the isolated job container before
non-root execution. No deployment or store action is part of the gate.

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
