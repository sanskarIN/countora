# Setup

Countora is developed against the Flutter stable channel. The package constraint remains Flutter `>=3.38.1`, while the active 2.15.18 repository verification pipeline pins Flutter `3.47.1` so CI, lockfile generation, smoke builds, and tagged-release checks use one reproducible framework version.

Flutter 3.38.1 itself generates Android projects with Gradle 8.14, AGP 8.11.1, and compileSdk 36, which satisfy Countora's current notification dependency requirements. Countora still validates/patches critical generated native settings defensively so future template drift fails visibly.

## 1. Install Flutter

Install Flutter stable and the platform toolchains for the targets you intend to build. For release-candidate reproduction, use the same Flutter version pinned in `.github/actions/setup-flutter/action.yml`.

Verify:

```bash
flutter --version
flutter doctor -v
```

Resolve all `flutter doctor` errors relevant to your target before diagnosing Countora build failures.

## 2. Clone

```bash
git clone https://github.com/sanskarIN/countora.git
cd countora
```

For the active release candidate:

```bash
git switch release/2.15.18-rc
```

## 3. Verify the repository toolchain policy

```bash
dart run tool/check_toolchain.dart
```

This verifies the shared CI setup uses one exact stable cached Flutter version and that critical workflows do not bypass it.

## 4. Generate platform runners

Countora intentionally does not commit Flutter-generated platform runner directories.

Generate Android, iOS, Web, Windows, macOS, and Linux project files with:

```bash
dart run tool/bootstrap_platforms.dart
```

The bootstrap invokes `flutter create --no-pub`. It snapshots application-owned repository-root files before generation and restores them byte-for-byte afterward, including `analysis_options.yaml`, `pubspec.yaml`, `pubspec.lock`, `README.md`, `l10n.yaml`, and `.gitignore`.

It then applies deterministic native notification setup:

- Android manifest scheduling permissions and receivers;
- Android core-library desugaring and multidex configuration;
- an Android Plugin DSL AGP floor of 8.11.1 while leaving newer versions untouched;
- iOS `UserNotifications` import and `UNUserNotificationCenter` delegate setup for foreground presentation.

The iOS transform supports both legacy AppDelegate plugin registration and Flutter 3.47's UIScene/implicit-engine template. The transforms are idempotent and fail explicitly when an expected Flutter template anchor disappears.

## 5. Resolve packages

```bash
flutter pub get
```

For release work, review the generated `pubspec.lock` and keep it in the release-candidate checkout. A release tag must use the reviewed committed lockfile rather than resolving an unreviewed dependency graph.

After the lock is committed, release verification should use:

```bash
flutter pub get --enforce-lockfile
dart run tool/check_dependency_lock.dart
```

## 6. Generate localization source

Validate committed localization input first:

```bash
dart run tool/check_localization_source.dart
flutter gen-l10n
```

Generated localization Dart files are ignored by Git and rebuilt by CI.

## 7. Run quality checks

```bash
dart run tool/check_toolchain.dart
dart run tool/check_required_files.dart
dart run tool/check_version_sync.dart
dart run tool/check_dependency_lock.dart
dart run tool/check_secrets.dart
dart run tool/check_localization_source.dart
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
dart run tool/check_markdown_links.dart
```

`check_dependency_lock.dart` is a release-candidate requirement once the reviewed lockfile has been committed.

## 8. Run the application

List targets:

```bash
flutter devices
```

Run on a selected target:

```bash
flutter run -d <device-id>
```

For Web, a common development target is:

```bash
flutter run -d chrome
```

## Platform requirements

### Android

Install Android Studio/SDK tooling and accept required Android SDK licenses.

```bash
flutter doctor --android-licenses
```

Countora requests notification permission when notifications are actually needed. Exact alarms are requested where supported; scheduling falls back to an inexact mode if exact scheduling is unavailable.

The supported Flutter baseline already supplies the required AGP/Gradle/compileSdk levels. `tool/bootstrap_platforms.dart` additionally validates/hardens the generated notification-specific manifest and Gradle configuration.

### iOS

A Mac with Xcode is required for iOS builds. The generated AppDelegate is patched to install the notification-center delegate required for foreground local-notification presentation. The patch supports the current Flutter 3.47 UIScene/implicit-engine runner as well as the older template.

Unsigned source compilation:

```bash
flutter build ios --debug --no-codesign
```

Device/App Store distribution requires valid Apple signing identities/profiles; these are never committed.

### macOS

A Mac with Xcode is required. Distribution outside local testing may require code signing and notarization.

### Windows

Build Windows on Windows with the Flutter desktop prerequisites/Visual Studio C++ desktop tooling reported by `flutter doctor`.

Portable build:

```bash
flutter build windows --release
```

Portable Windows uses Countora's runtime local-notification fallback because reliable future notification cancellation/history depends on Windows package identity.

Package-identity/MSIX build verification:

```bash
dart run msix:create
```

The MSIX configuration rebuilds Countora with `COUNTORA_WINDOWS_PACKAGED=true`, enabling the packaged Windows scheduled-notification path. The default MSIX development signing behavior is not a production distribution strategy; use a trusted certificate or Microsoft Store signing path before publishing an MSIX.

`tool/check_version_sync.dart` verifies that `msix_version` remains synchronized with the Flutter package version/build number. For 2.15.18, the mapping is `2.15.18+18` → `2.15.18.18`.

### Linux

Install Flutter's Linux desktop build prerequisites such as CMake, Ninja, Clang, pkg-config, GTK development headers, and liblzma development headers as appropriate for the distribution.

Linux local notifications use Countora's runtime fallback. They can notify while the Countora process remains active; persisted timer state still reconciles correctly after restart/resume.

### Web

A supported browser is sufficient for development. Web local notifications use the browser Notifications API while the Countora page/runtime remains active. Browser permission prompts depend on user-activation/browser policy, and future delivery after the page/runtime is gone is not guaranteed.

Core Countora timer workflows remain local and do not require a backend.

## Environment/configuration

Countora currently has no required production API keys, secrets, backend URL, or authentication configuration. `.env.example` exists to document that future environment configuration must use placeholders only and must never commit credentials.

The Windows package-identity behavior uses a compile-time Dart define generated by the MSIX build configuration; it is not a secret.

## First-run verification

After setup, manually check:

1. create a timer;
2. pause/resume it;
3. create an interval sequence;
4. save/start a preset;
5. export/import a backup;
6. open Settings/About;
7. enable notifications and verify the delivery mode appropriate to the target/distribution;
8. background/resume the app and verify countdown reconciliation;
9. on Windows, compare portable runtime-fallback behavior with an installed package-identity build;
10. on Web, verify permission behavior from a user interaction in representative browsers.

For the active release gate, follow [`release-2.15.18.md`](release-2.15.18.md) in addition to [`testing.md`](testing.md), [`release.md`](release.md), [`notification-support.md`](notification-support.md), and [`troubleshooting.md`](troubleshooting.md).
