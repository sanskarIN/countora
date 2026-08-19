# Setup

Countora is developed against the Flutter stable channel. The repository currently declares Flutter `>=3.38.1` and Dart `>=3.10.0 <4.0.0` in `pubspec.yaml`. Prefer the current stable Flutter SDK that satisfies those constraints rather than relying on an older framework installation.

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

It is safe to rerun after a Flutter SDK/template change; custom patches are designed to be idempotent and to fail explicitly if expected template anchors disappear.

## 4. Resolve packages

```bash
flutter pub get
```

For application/release work, keep the generated `pubspec.lock` produced by the real Flutter toolchain in the working checkout and review dependency changes before release. Do not hand-create a lockfile.

## 5. Generate localization source

Run the deterministic localization-source audit first, then generate Flutter localization code:

```bash
dart run tool/check_localization_source.dart
flutter gen-l10n
```

Generated localization Dart files are ignored by Git and rebuilt by CI.

## 6. Run quality checks

```bash
dart run tool/check_required_files.dart
dart run tool/check_version_sync.dart
dart run tool/check_secrets.dart
dart run tool/check_localization_source.dart
dart run tool/check_markdown_links.dart
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
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

Android 8+ notification-channel behavior is represented by separate stable Countora channels for sound+vibration, sound-only, vibration-only, and silent/quiet delivery. Users can still override channel behavior in operating-system notification settings.

### iOS/macOS

A Mac with Xcode is required for Apple builds. Store/device distribution requires valid Apple signing identities/profiles; these are never committed.

Countora deliberately disables the Darwin plugin's initialization-time alert/badge/sound permission requests. Permission is requested later through the explicit notification-permission path when scheduling is first needed.

### Windows

Build Windows on Windows with the Flutter desktop prerequisites/Visual Studio C++ desktop tooling reported by `flutter doctor`.

### Linux

Install Flutter's Linux desktop build prerequisites such as CMake, Ninja, Clang, pkg-config, GTK development headers, and liblzma development headers as appropriate for the distribution.

Countora currently treats future scheduled background notifications as unsupported on Linux; timer state, foreground countdowns, history, and reconciliation continue to work.

### Web

A supported browser is sufficient for development. Countora currently treats future scheduled background notifications as unsupported on Web; core local timer workflows remain available and require no backend.

## Environment/configuration

Countora currently has no required production API keys, secrets, backend URL, or authentication configuration. `.env.example` exists to document that future environment configuration must use placeholders only and must never commit credentials.

## First-run verification

After setup, manually check:

1. create a timer;
2. pause/resume it, including near a completion boundary;
3. create an interval sequence;
4. save/start a preset;
5. export/import a backup;
6. open Settings/About;
7. enable notifications on a supported native platform;
8. verify sound/vibration/quiet profiles where applicable;
9. background/resume the app and verify countdown reconciliation.

See [`testing.md`](testing.md), [`release.md`](release.md), [`notification-support.md`](notification-support.md), and [`troubleshooting.md`](troubleshooting.md).
