# ⏳ Countora

<p align="center">
  <strong>Multiple countdowns. Reusable presets. Interval workflows. Local-first by design.</strong>
</p>

<p align="center">
  <a href="https://buymeacoffee.com/sanskarIN">
    <img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-sanskarIN-FFDD00?logo=buy-me-a-coffee&logoColor=000000" alt="Buy Me a Coffee">
  </a>
</p>

**Countora** is a production-oriented Flutter countdown timer for running multiple timers at once, creating reusable presets, organizing named timer groups, building interval sequences, and recovering countdown state after suspension. It is account-free and local-first.

Current development version: **2.15.18+18** (release candidate).

> **Made by the Sanskar**

## Highlights

### Countdown workflows

- Multiple simultaneous countdown timers
- Pause, resume, restart, delete, duplicate, and add-time controls
- Bulk pause-all, resume-all, and remove-completed actions
- Reusable presets with usage-frequency tracking
- Named timer groups plus search and filtering
- Multi-step interval sequences with labels and reordering
- Local completion history with one-tap run-again
- Full-screen focus mode with live controls
- Compact card mode for dense layouts

### Reliability

- UTC completion instants persisted instead of decrementing storage every second
- Monotonic in-process clock to reduce live countdown jumps after wall-clock changes
- App-resume reconciliation for expired or suspended timers
- Interval catch-up that preserves absolute sequence timing after suspension
- Scheduled background completion notifications on Android, iOS, macOS, and package-identity Windows builds
- Runtime local-notification fallback on Linux, Web, and portable Windows builds
- Android exact-alarm fallback to inexact scheduling when exact permission is unavailable
- Corruption-safe local persistence recovery
- Bounded, schema-aware JSON backup validation and migration
- Resilient external-link and clipboard-export failure handling
- Non-notification preference changes avoid unnecessary running-notification rescheduling
- Protected Flutter runner bootstrap that restores repository-root files exactly after `flutter create`

### Accessibility, localization, and desktop usability

- Material 3 light, dark, and system themes
- Complete English and Hindi localization
- Persisted System language / English / Hindi override in Settings
- Regional locale resolution such as `hi-IN` through Flutter localization matching
- Reduced-motion preference
- Sound, vibration, quiet mode, and visual progress cues
- Semantic timer/progress labels and focus-mode live-region cues
- Keyboard navigation and visible standard Flutter focus behavior
- `Ctrl/Cmd + N` — create timer/preset
- `Ctrl/Cmd + F` — focus timer search
- `Ctrl/Cmd + ,` — open Settings
- Responsive phone, tablet, desktop, and web layouts

### Privacy and ownership

- No account required
- No cloud backend required
- Timers, presets, history, language, and other settings remain local unless a user explicitly copies a backup
- Structured diagnostics redact sensitive fields
- Open source under the MIT License

## Screenshots

Real product captures will be committed only after a verified runnable multi-platform build. The repository intentionally does not present mockups as if they were real app screenshots.

## Platforms

Countora intentionally supports the six primary Flutter deployment families from one codebase. Platform-native APIs are used where available, with explicit fallbacks where an OS/browser or distribution format exposes less functionality.

| Platform / distribution | Countora support | Build/release target | Completion notification behavior |
| --- | --- | --- | --- |
| Android | Supported | APK + AAB | Future scheduled delivery; exact scheduling falls back to inexact when required |
| iOS | Supported | unsigned CI build; signed distribution requires Apple credentials | Future scheduled delivery through Darwin notifications |
| Windows portable | Supported | x64 application ZIP | Local notification runtime fallback; portable builds deliberately avoid future scheduling that depends on Windows package identity |
| Windows packaged | Supported packaging path | MSIX build verification; production signing required before promotion | Package-identity build enables future scheduled Windows toast delivery |
| macOS | Supported | application ZIP | Future scheduled delivery through Darwin notifications |
| Linux | Supported | x64 tar.gz | Local notifications while the Countora runtime remains active; future OS scheduling is unavailable |
| Web | Supported | Web ZIP | Browser notifications while the page/runtime remains active; browsers do not provide guaranteed future delivery after the runtime is gone |

All six platform families retain timer state, live countdowns, presets, groups, interval sequences, history, backup/restore, responsive UI, themes, accessibility preferences, localization, and resume reconciliation. Platform differences are isolated to capabilities the underlying OS/browser/distribution genuinely exposes.

Native runner folders are generated from the installed Flutter SDK so stale framework boilerplate is not frozen into source control.

## Tech stack

- Flutter + Dart
- Flutter Material 3
- Flutter generated localization (`gen_l10n`)
- `shared_preferences` for small local state persistence
- `flutter_local_notifications` for cross-platform local notifications
- `timezone` for timezone-aware notification scheduling
- `url_launcher` behind a guarded external-link helper
- `msix` for Windows package-identity build verification

## Quick start

Prerequisites:

- Flutter stable satisfying `pubspec.yaml` (`>=3.38.1`); repository CI currently pins Flutter `3.47.1`
- Dart `>=3.10.0 <4.0.0` from a compatible Flutter SDK
- platform toolchains for the host you intend to build

```bash
git clone https://github.com/sanskarIN/countora.git
cd countora
dart run tool/bootstrap_platforms.dart
flutter pub get
dart run tool/check_localization_source.dart
flutter gen-l10n
flutter run
```

`tool/bootstrap_platforms.dart` runs `flutter create --no-pub` for Android, iOS, Web, Windows, macOS, and Linux runners, restores protected repository-root files byte-for-byte, then applies validated native notification requirements. Current transforms harden the Android manifest/Gradle/AGP setup and configure the generated iOS notification-center delegate. The transforms are idempotent and fail if expected Flutter template anchors disappear.

For complete setup instructions, see [`docs/setup.md`](docs/setup.md).

## Verification

Repository integrity checks:

```bash
dart run tool/check_required_files.dart
dart run tool/check_version_sync.dart
dart run tool/check_secrets.dart
dart run tool/check_localization_source.dart
dart run tool/check_markdown_links.dart
```

Formatting:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test tool
```

Static analysis and automated tests:

```bash
flutter gen-l10n
flutter analyze
flutter test
```

Primary integration journey on Linux:

```bash
flutter test integration_test -d linux -r github
```

For a headless Linux environment:

```bash
xvfb-run -a flutter test integration_test -d linux -r github
```

Web release verification:

```bash
flutter build web --release
```

See [`docs/testing.md`](docs/testing.md) for the testing strategy and [`docs/release.md`](docs/release.md) for release commands.

## Platform builds

Run builds only on compatible hosts/toolchains.

```bash
flutter build apk --release
flutter build appbundle --release
flutter build web --release
flutter build linux --release
flutter build windows --release
dart run msix:create
flutter build macos --release
flutter build ios --release --no-codesign
```

The normal `flutter build windows` output is a portable build and therefore uses Countora's runtime notification fallback. The MSIX configuration rebuilds Windows with `COUNTORA_WINDOWS_PACKAGED=true`, giving the application package identity for the packaged notification path. CI verifies that MSIX creation works, but a production MSIX still requires an approved signing/store strategy before it should be distributed.

The non-tagged `Platform smoke` workflow continuously compiles Android, Linux, portable Windows, Windows MSIX packaging, macOS, and unsigned iOS targets while the main CI workflow builds Web and runs the Linux integration journey. The tagged GitHub release workflow performs host-specific release builds and publishes its approved artifact set after the main quality job succeeds. It also publishes SHA-256 digest files for Android/Web, Linux, portable Windows, macOS, and unsigned iOS release artifacts.

See [`docs/release.md`](docs/release.md) for integrity-verification examples and the distinction between checksums, package identity, and production code signing.

## Project structure

```text
lib/
  l10n/
    app_en.arb              # English localization template/source
    app_hi.arb              # Complete Hindi localization source
  main.dart
  src/
    core/                   # metadata, links, safe launch, logging, clock, theme, tokens
    data/                   # validated persistence and cross-platform notifications
    domain/                 # timers, presets, history, settings
    presentation/           # controller and responsive UI
integration_test/           # end-to-end Flutter user journeys
test/                       # domain, controller, persistence, UI, localization, tool tests
tool/
  bootstrap_platforms.dart  # deterministic Flutter runner generation + native patches
  src/root_file_guard.dart  # exact root-file preservation around Flutter generation
  src/platform_patches.dart # pure validated Android/iOS runner transforms
  ...                       # repository checks
docs/                       # architecture, setup, testing, localization, release, ADRs
.github/                    # CI, platform smoke, release, security, templates, Dependabot/funding
```

## Architecture overview

Countora uses a small modular-monolith structure:

1. **Domain** — countdown, interval, preset, history, and settings models.
2. **Data** — persistence codec/store and platform notification adapter.
3. **Presentation** — controller-driven state transitions and adaptive Flutter UI.
4. **Core** — stable clock, design tokens, metadata, links, localization helper, formatting, structured logging, and safe external-link launching.

Running timers persist an absolute UTC deadline. During one process lifetime, countdown calculations use a monotonic clock anchored to UTC so a wall-clock edit does not directly make a live timer jump. On resume/startup, the controller reconciles elapsed interval steps and synchronizes notification behavior according to the target's delivery capability and, on Windows, the current packaging identity.

See [`docs/architecture.md`](docs/architecture.md), [`docs/notification-support.md`](docs/notification-support.md), and [`docs/adr/`](docs/adr/) for architectural decisions.

## Backup format and safety

Countora exports versioned JSON. Import is treated as untrusted input.

Current safety bounds include:

- maximum backup size: 2 MiB
- maximum timers: 500
- maximum presets: 500
- maximum history entries: 500
- maximum interval steps per timer/preset: 32
- maximum name length: 80 characters
- maximum group length: 40 characters
- maximum individual interval: 365 days

Unknown future schema versions are rejected instead of silently interpreted. A valid import is previewed before it replaces current local data. Clipboard export failures are reported without changing the current local state. The persisted language preference is part of Settings backup data; older backups without it safely use System language.

## Localization

English (`en`) and Hindi (`hi`) ship through ARB catalogs in `lib/l10n`. Countora follows the device/browser locale by default and also lets users persist an explicit English or Hindi override from Settings.

Translated catalogs are audited against `app_en.arb` for key parity, non-empty values, locale identity, duplicate locale declarations, and filename/`@@locale` consistency. Dart localization references are also checked before generated localization code is created.

After modifying ARB files, run:

```bash
dart run tool/check_localization_source.dart
flutter gen-l10n
```

Generated localization Dart files are intentionally ignored from Git; CI regenerates them. See [`docs/localization.md`](docs/localization.md) for the translation workflow and review checklist.

## Security and privacy

Countora has no authentication or cloud service. Security work therefore focuses on local input validation, dependency/workflow hygiene, platform permissions, safe diagnostics, and avoiding secret material in source.

- Backup/import JSON is schema/type/size bounded.
- Local corruption falls back to a safe recoverable state.
- Sensitive structured-log keys are redacted.
- External URL-launch and clipboard platform failures are contained at guarded boundaries.
- Notification capability is explicit: Android/iOS/macOS and package-identity Windows use future scheduling; Linux/Web/portable Windows use runtime fallbacks; unknown targets fail closed.
- Windows package version metadata is kept synchronized with the Flutter application version.
- Generated Android notification setup enforces required scheduling receivers, permissions, desugaring, multidex, and a compatible AGP floor.
- Generated iOS setup installs the notification-center delegate needed for foreground notification presentation.
- Dependency Review blocks newly introduced moderate-or-higher vulnerabilities on pull requests.
- CodeQL scans supported GitHub Actions workflow code.
- Tagged releases run deterministic required-file, version-sync, tracked-secret, localization-source, and documentation-link audits.
- Release artifacts include SHA-256 digests for post-download integrity checks.
- Signing keys, `.env`, keystores, certificates, and generated credentials are ignored or kept outside source control.

Read [`SECURITY.md`](SECURITY.md) and [`PRIVACY.md`](PRIVACY.md).

## CI and release

The main CI workflow checks:

- generated platform bootstrap with root-file preservation
- deterministic localization source/catalog auditing
- dependency resolution
- localization generation
- formatting
- Flutter static analysis
- Flutter tests
- local Markdown links
- Web release build

The cross-platform smoke workflow additionally compiles/verifies:

- Android on Ubuntu
- Linux on Ubuntu
- portable Windows and MSIX packaging on Windows
- macOS on macOS
- unsigned iOS on macOS

A separate Linux CI job runs the primary `integration_test` journey under Xvfb. Tagged releases additionally run repository-integrity checks and build Android APK/AAB, Web, Linux, portable Windows, macOS, and an unsigned iOS application artifact. The Windows tagged job also verifies an MSIX package-identity build. Production-signed MSIX/store distribution remains an external release-credential step and is not implied by CI packaging verification.

No release should be considered verified until the corresponding GitHub Actions runs are observed as successful. `v2.15.18` must not be created while the `[2.15.18]` changelog heading remains marked as an unreleased release candidate.

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`docs/development.md`](docs/development.md) before opening a pull request. Changes should be small, tested, documented, and committed using meaningful Conventional Commit-style messages when practical.

## Project documentation

- [`docs/architecture.md`](docs/architecture.md)
- [`docs/setup.md`](docs/setup.md)
- [`docs/development.md`](docs/development.md)
- [`docs/testing.md`](docs/testing.md)
- [`docs/localization.md`](docs/localization.md)
- [`docs/release.md`](docs/release.md)
- [`docs/troubleshooting.md`](docs/troubleshooting.md)
- [`docs/accessibility.md`](docs/accessibility.md)
- [`docs/performance.md`](docs/performance.md)
- [`docs/notification-support.md`](docs/notification-support.md)
- [`ROADMAP.md`](ROADMAP.md)
- [`CHANGELOG.md`](CHANGELOG.md)
- [`what_changed.md`](what_changed.md)

## License

MIT — see [`LICENSE`](LICENSE).

## Support & contact

- Business: `sanskarin@outlook.in`
- Business: `sanskarin.business@gmail.com`
- Support: `supportramsandesh@gmail.com`
- GitHub: https://github.com/sanskarIN
- Repository: https://github.com/sanskarIN/countora
- Buy Me a Coffee: https://buymeacoffee.com/sanskarIN

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-sanskarIN-FFDD00?logo=buy-me-a-coffee&logoColor=000000)](https://buymeacoffee.com/sanskarIN)

**Made by the Sanskar**
