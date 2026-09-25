#!/usr/bin/env bash
# Shared by the existing on-demand runner and the portable MR runner.
set -Eeuo pipefail
mkdir -p ci-artifacts
run_step() {
  local name="$1" rc
  shift
  printf '\n== %s ==\n' "$name"
  printf '%q ' "$@" > "ci-artifacts/$name.command"
  printf '\n' >> "ci-artifacts/$name.command"
  set +e
  "$@" > "ci-artifacts/$name.stdout" 2> "ci-artifacts/$name.stderr"
  rc=$?
  set -e
  printf '%s\n' "$rc" > "ci-artifacts/$name.exit"
  tail -n 15 "ci-artifacts/$name.stdout"
  tail -n 15 "ci-artifacts/$name.stderr" >&2
  return "$rc"
}
run_step source git rev-parse HEAD 'HEAD^{tree}'
run_step flutter-config flutter config --no-analytics
run_step sdk flutter --version --machine
run_step sdk-pin python3 -c 'import json; from pathlib import Path; actual=json.loads(Path("ci-artifacts/sdk.stdout").read_text()); expected=json.loads(Path(".fvmrc").read_text())["flutter"]; assert actual["frameworkVersion"]==expected, (actual, expected); print("Pinned Flutter:", expected)'
run_step pub-get flutter pub get
run_step analyze flutter analyze
run_step python-tools python3 -m unittest discover -s test/tool -p 'test_*.py'
run_step python-mode08 python3 -m unittest discover -s tool/obd_test_rig -p 'test_mode08_replay_reference.py'
run_step flutter-tests flutter test --reporter expanded
run_step mode08-required python3 tool/ci/run_mode08_required.py --output-dir ci-artifacts/mode08-required
run_step ws10-s1-required python3 tool/ci/run_ws10_s1_required.py --output-dir ci-artifacts/ws10-s1-required
# android/app/build.gradle.kts enables ABI splits for the F-Droid contract.
# Ask Flutter for matching split outputs; an unsplit build injects ndk
# abiFilters and conflicts with the Gradle splits.abi configuration.
run_step apk-build flutter build apk --verbose --debug --flavor field --split-per-abi
sha256sum build/app/outputs/flutter-apk/*.apk > ci-artifacts/apks.sha256
printf '\nAll gate commands and required replay passed. This is NOT Android device acceptance.\n'
