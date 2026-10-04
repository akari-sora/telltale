#!/usr/bin/env bash
# AA02-02: the committed Pigeon output must be exactly what the pinned
# generator produces from pigeons/car_telemetry.dart.
#
# Regenerates in place, then fails if either generated file differs from the
# commit (modified, deleted, or untracked).
set -Eeuo pipefail

cd "$(git rev-parse --show-toplevel)"

generated=(
  lib/car/generated/car_telemetry.g.dart
  android/app/src/carProto/kotlin/com/cbstudio/telltale/carbridge/generated/CarTelemetry.g.kt
)

# CI images put the Flutter SDK's dart on PATH; local checkouts may only
# expose it through fvm (.fvmrc pins the same SDK).
if command -v dart >/dev/null 2>&1; then
  dart_cmd=(dart)
elif command -v fvm >/dev/null 2>&1; then
  dart_cmd=(fvm dart)
else
  echo "Neither dart nor fvm is on PATH; cannot verify Pigeon codegen." >&2
  exit 1
fi

"${dart_cmd[@]}" run pigeon --input pigeons/car_telemetry.dart

status="$(git status --porcelain -- "${generated[@]}")"
if [[ -n "$status" ]]; then
  echo "Pigeon generated code drifted from pigeons/car_telemetry.dart:" >&2
  echo "$status" >&2
  git --no-pager diff -- "${generated[@]}" >&2 || true
  echo "Run: dart run pigeon --input pigeons/car_telemetry.dart and commit." >&2
  exit 1
fi

for file in "${generated[@]}"; do
  if ! git ls-files --error-unmatch -- "$file" >/dev/null 2>&1; then
    echo "Generated file is not committed: $file" >&2
    exit 1
  fi
done

echo "Pigeon codegen drift: none (${#generated[@]} files)."
