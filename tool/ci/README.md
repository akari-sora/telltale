# Telltale full gate

The original Grok on-demand main runner/image remain the default. Its paused or
offline state is an execution dependency, not a test PASS. This repository does
not unpause a runner or run a privileged host command from job code.

Same-project merge requests use a GitLab-hosted small Linux runner and the public
`plugfox/flutter:3.47.0-android` image pinned to its amd64 manifest digest. Both jobs
execute the same non-root gate. The SDK version is checked against `.fvmrc`; any
missing Android36/build-tools36/NDK28.2 packages are installed in the ephemeral
container before dropping privileges. There is no floating `latest`/localhost
fallback or weakening of root-permission tests. Hosted jobs consume the project's
normal GitLab compute allowance; each job is capped at one hour. If allowance or
runner access is unavailable, the job remains blocked, never considered passed.

An explicitly requested API/web pipeline may select `CI_GATE_RUNNER=hosted` on a
review branch or main. This substitutes the execution host, not gate contents.
Same-project MR rules exclude forks from the trusted project's job. No deploy or
store action is present.

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
Runner: https://docs.gitlab.com/ci/runners/hosted_runners/linux/
