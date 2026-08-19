# Setup

Countora is developed against the Flutter stable channel. Prefer the current stable SDK that satisfies the Dart constraint declared in `pubspec.yaml` instead of relying on a hard-coded framework version in this document.

## 1. Install Flutter

Install Flutter stable and the platform toolchains for the targets you intend to build.

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

## 3. Generate platform runners

Countora intentionally does not commit Flutter-generated platform runner directories.

Generate Android, iOS, Web, Windows, macOS, and Linux project files with:

```bash
dart run tool/bootstrap_platforms.dart
```

The bootstrap script also applies Countora's required Android notification/desugaring configuration.

It is safe to rerun after a Flutter SDK/template change; custom patches are designed to be idempotent.

## 4. Resolve packages

```bash
flutter pub get
```

For application/release work, keep the generated `pubspec.lock` produced by the real Flutter toolchain in the working checkout and review dependency changes before release.

## 5. Generate localization source

```bash
flutter gen-l10n
```

Generated localization Dart files are ignored by Git and rebuilt by CI.

## 6. Run quality checks

```bash
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
dart run tool/check_markdown_links.dart
```

## 7. Run the application

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

### iOS/macOS

A Mac with Xcode is required for Apple builds. Store/device distribution requires valid Apple signing identities/profiles; these are never committed.

### Windows

Build Windows on Windows with the Flutter desktop prerequisites/Visual Studio C++ desktop tooling reported by `flutter doctor`.

### Linux

Install Flutter's Linux desktop build prerequisites such as CMake, Ninja, Clang, pkg-config, GTK development headers, and liblzma development headers as appropriate for the distribution.

### Web

A supported browser is sufficient for development, but platform notification behavior can differ from native targets. Core Countora timer workflows remain local and do not require a backend.

## Environment/configuration

Countora currently has no required production API keys, secrets, backend URL, or authentication configuration. `.env.example` exists to document that future environment configuration must use placeholders only and must never commit credentials.

## First-run verification

After setup, manually check:

1. create a timer;
2. pause/resume it;
3. create an interval sequence;
4. save/start a preset;
5. export/import a backup;
6. open Settings/About;
7. enable notifications on a native platform;
8. background/resume the app and verify countdown reconciliation.

See [`testing.md`](testing.md), [`release.md`](release.md), and [`troubleshooting.md`](troubleshooting.md).
