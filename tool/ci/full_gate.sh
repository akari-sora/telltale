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
# `pub get` clones flutter_classic_bluetooth from Codeberg. A TLS reset on that
# clone failed the 1.0.23 main pipeline with nothing wrong in the tree (1 of the
# last 40 failed pipelines). Three bounded attempts; the artifact keeps the last.
for pub_get_attempt in 1 2 3; do
  pub_get_rc=0
  run_step pub-get flutter pub get || pub_get_rc=$?
  if [ "$pub_get_rc" = 0 ]; then break; fi
  # Keep each failed attempt's output; run_step overwrites pub-get.* each time.
  for stream in stdout stderr exit; do
    cp "ci-artifacts/pub-get.$stream" "ci-artifacts/pub-get.attempt$pub_get_attempt.$stream"
  done
  if [ "$pub_get_attempt" = 3 ]; then exit "$pub_get_rc"; fi
  printf 'pub get attempt %s failed (exit %s); retrying\n' "$pub_get_attempt" "$pub_get_rc" >&2
  sleep $((pub_get_attempt * 10))
done
run_step car-pigeon-codegen bash tool/ci/verify_car_pigeon_codegen.sh
run_step analyze flutter analyze
run_step python-tools python3 -m unittest discover -s test/tool -p 'test_*.py'
run_step python-aa08-pytest python3 -m pytest -q test/tool/test_challenger_empirical_r3.py test/tool/test_run_targeted_mutations.py
run_step python-mode08 python3 -m unittest discover -s tool/obd_test_rig -p 'test_mode08_replay_reference.py'
run_step car-core-unit ./android/gradlew -p android :car-core:testDebugUnitTest
run_step car-field-unit ./android/gradlew -p android :app:testFieldDebugUnitTest
run_step car-proto-unit ./android/gradlew -p android :app:testCarProtoDebugUnitTest
run_step car-field-projected-build ./android/gradlew -p android :app:assembleFieldDebug
run_step car-projected-build ./android/gradlew -p android :app:assembleCarProtoDebug
run_step car-aaos-build ./android/gradlew -p android :automotive:assembleDebug
run_step car-field-manifest ./android/gradlew -p android :app:processFieldDebugMainManifest
run_step car-field-release-manifest ./android/gradlew -p android :app:processFieldReleaseMainManifest
run_step car-rig-manifest ./android/gradlew -p android :app:processRigDebugMainManifest
run_step car-wear-manifest ./android/gradlew -p android :app:processWearDebugMainManifest
run_step car-manifest-isolation python3 tool/ci/verify_car_manifest_isolation.py
run_step foldable-quality flutter test test/ui/foldable_quality_gate_test.dart --reporter expanded
run_step flutter-tests flutter test --reporter expanded
run_step mode08-required python3 tool/ci/run_mode08_required.py --output-dir ci-artifacts/mode08-required
run_step ws10-s1-required python3 tool/ci/run_ws10_s1_required.py --output-dir ci-artifacts/ws10-s1-required
run_step ws10-s2-step1-native python3 tool/ci/run_ws10_s2_step1_native.py --output-dir ci-artifacts/ws10-s2-step1-native --require-toolchain
run_step l10n-required python3 tool/ci/run_l10n_required.py --flutter flutter --evidence ci-artifacts/l10n-required/receipt.json
# android/app/build.gradle.kts enables ABI splits for the F-Droid contract.
# Ask Flutter for matching split outputs; an unsplit build injects ndk
# abiFilters and conflicts with the Gradle splits.abi configuration.
run_step apk-build flutter build apk --verbose --debug --flavor field --split-per-abi
sha256sum build/app/outputs/flutter-apk/*.apk > ci-artifacts/apks.sha256
# Release preparation remains secret-free and in the same accepted CI job.
# An API request on protected main explicitly opts into the extra AAB/APK build.
if [ "${TELLTALE_RELEASE_CANDIDATE:-false}" = true ]; then
  run_step release-candidate python3 tool/ci/build_release_candidate.py
fi
printf '\nAll gate commands and required replay passed. This is NOT Android device acceptance.\n'
