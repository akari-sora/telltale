#!/usr/bin/env bash
# Prepare only the isolated CI container. Never starts/unpauses a host runner.
set -Eeuo pipefail
if [ "$(id -u)" != 0 ]; then
  command -v python3
  command -v flutter
  exit 0
fi
if ! command -v python3 >/dev/null 2>&1; then
  apt-get update
  apt-get install -y --no-install-recommends python3
fi
if id -u ubuntu >/dev/null 2>&1; then
  NONROOT=ubuntu
elif id -u flutter >/dev/null 2>&1; then
  NONROOT=flutter
else
  useradd -m -s /bin/bash flutter
  NONROOT=flutter
fi
FLUTTER_HOME=$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")
ANDROID_SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-/opt/android-sdk-linux}}"
export ANDROID_HOME="$ANDROID_SDK" ANDROID_SDK_ROOT="$ANDROID_SDK"
export PATH="$ANDROID_SDK/cmdline-tools/latest/bin:$PATH"
if [ ! -d "$ANDROID_SDK/ndk/28.2.13676358" ] || \
   [ ! -d "$ANDROID_SDK/platforms/android-36" ] || \
   [ ! -d "$ANDROID_SDK/build-tools/36.0.0" ]; then
  mkdir -p ci-artifacts
  # yes can exit on SIGPIPE; the sdkmanager exit, not yes/tee, is authoritative.
  set +e
  yes | sdkmanager --licenses > ci-artifacts/sdk-licenses.log 2>&1
  sdk_exit=${PIPESTATUS[1]}
  set -e
  if [ "$sdk_exit" != 0 ]; then exit "$sdk_exit"; fi
  sdkmanager --install 'platforms;android-36' 'build-tools;36.0.0' 'ndk;28.2.13676358'
fi
chown -R "$NONROOT:$NONROOT" "$CI_PROJECT_DIR" "$ANDROID_SDK" "$FLUTTER_HOME"
printf '%s\n' '#!/bin/bash' 'set -Eeuo pipefail' \
  "export PATH=\"$FLUTTER_HOME/bin:\$PATH\"" \
  "export PUB_CACHE=\"$CI_PROJECT_DIR/.pub-cache\"" \
  "export GRADLE_OPTS=\"${GRADLE_OPTS:-}\"" \
  "export ANDROID_HOME=\"$ANDROID_SDK\"" \
  "export ANDROID_SDK_ROOT=\"$ANDROID_SDK\"" \
  "cd \"$CI_PROJECT_DIR\"" 'exec "$@"' > /usr/local/bin/as-nonroot
chmod 755 /usr/local/bin/as-nonroot
printf '%s\n' "$NONROOT" > /tmp/ci-nonroot-user
