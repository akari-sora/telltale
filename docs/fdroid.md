# F-Droid maintainer notes

F-Droid builds Telltale from the **GitLab** repository
(`https://gitlab.com/aa22396584/telltale`), the canonical source; the recipe
is `metadata/com.cbstudio.telltale.yml` in fdroiddata. Play assets live in
`store/`; F-Droid listing graphics and copy are synced into
`fastlane/metadata/android/` (see `tool/fdroid/sync_fastlane_from_store.sh`).

## Exact build command (F-Droid recipe)

One build per ABI, each with its own `--target-platform`
(`android-arm`, `android-arm64`, `android-x64`):

```bash
flutter build apk --release --flavor field -PallowUnsignedRelease=true \
  --split-per-abi --target-platform=android-arm64
```

- **Flavor:** `field` only (`applicationId` `com.cbstudio.telltale`). Do not
  build `rig` or `wear`.
- **Unsigned escape hatch:** required when `android/key.properties` is absent
  (F-Droid has no maintainer keystore). The Gradle gate is in
  `android/app/build.gradle.kts`.
- **Expected APKs:** `build/app/outputs/flutter-apk/app-<abi>-field-release.apk`
  for `armeabi-v7a`, `arm64-v8a` and `x86_64`.
- **versionCode:** the recipe's `VercodeOperation` makes each ABI's code
  `N*10+1`, `+2`, `+3` from the `+N` in `pubspec.yaml` (1.0.24+207 builds
  2071, 2072, 2073). F-Droid shows the changelog named after that code, so the
  sync script copies `changelogs/N.txt` to `N1.txt`–`N3.txt` for 206 onward.
- **Flutter pin:** `3.47.0` (`.flutter-version`, which the recipe checks out;
  also CI `FLUTTER_VERSION` / `.fvmrc`)
- **Git dependency:** `flutter_classic_bluetooth` must resolve from
  Codeberg (`https://codeberg.org/ImL1s/flutter_classic_bluetooth.git`),
  not GitHub — F-Droid builders cannot clone the GitHub fork URL.

## Signing lineages (three keys)

| Channel | Signer | Updates |
| --- | --- | --- |
| F-Droid | F-Droid signing key | Only other F-Droid builds |
| GitLab release | Maintainer key, signed on the private host (`tool/ci/build_signed_release.py`) | Only other GitLab release builds |
| Google Play | Play upload / App Signing | Only Play updates |

Do **not** upload a GitLab release or Play APK into F-Droid.

## Sync Fastlane from Play store assets

After editing `store/`:

```bash
tool/fdroid/sync_fastlane_from_store.sh
```

Then commit the Fastlane tree with the store change.
