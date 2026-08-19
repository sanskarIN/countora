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

Current development version: **0.2.0+2**.

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
- Background local completion notifications
- Android exact-alarm fallback to inexact scheduling when exact permission is unavailable
- Corruption-safe local persistence recovery
- Bounded, schema-aware JSON backup validation and migration

### Accessibility and desktop usability

- Material 3 light, dark, and system themes
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
- Timers, presets, history, and settings remain local unless a user explicitly copies a backup
- Structured diagnostics redact sensitive fields
- Open source under the MIT License

## Screenshots

Real product captures will be committed only after a verified runnable multi-platform build. The repository intentionally does not present mockups as if they were real app screenshots.

## Platforms

| Platform | Source target | Release workflow |
| --- | --- | --- |
| Android | Supported | APK + AAB |
| Web | Supported | ZIP |
| Linux | Supported | x64 tar.gz |
| Windows | Supported | x64 ZIP |
| macOS | Supported | app ZIP |
| iOS | iOS-ready | unsigned app ZIP for CI verification; distribution requires signing |

Native runner folders are generated from the installed Flutter SDK so stale framework boilerplate is not frozen into source control.

## Tech stack

- Flutter + Dart
- Flutter Material 3
- Flutter generated localization (`gen_l10n`)
- `shared_preferences` for small local state persistence
- `flutter_local_notifications` for scheduled local notifications
- `timezone` for timezone-aware notification scheduling
- `url_launcher` for support/source links

## Quick start

Prerequisites:

- a current stable Flutter SDK compatible with Dart `>=3.10.0 <4.0.0`
- platform toolchains for the host you intend to build

```bash
git clone https://github.com/sanskarIN/countora.git
cd countora
dart run tool/bootstrap_platforms.dart
flutter pub get
flutter gen-l10n
flutter run
```

`tool/bootstrap_platforms.dart` runs `flutter create` for Android, iOS, Web, Windows, macOS, and Linux runners, then applies Android notification/desugaring configuration idempotently.

For complete setup instructions, see [`docs/setup.md`](docs/setup.md).

## Verification

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

Documentation integrity:

```bash
dart run tool/check_markdown_links.dart
```

Primary integration journey on a configured Flutter target:

```bash
flutter test integration_test/app_journey_test.dart
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
flutter build macos --release
flutter build ios --release --no-codesign
```

The tagged GitHub release workflow performs the supported host-specific builds and publishes artifacts after the main quality job succeeds.

## Project structure

```text
lib/
  l10n/
    app_en.arb              # English localization source
  main.dart
  src/
    core/                   # metadata, links, logging, clock, theme, tokens
    data/                   # validated persistence and notifications
    domain/                 # timers, presets, history, settings
    presentation/           # controller and responsive UI
integration_test/           # end-to-end Flutter user journeys
test/                       # domain, controller, persistence, UI, localization tests
tool/                       # platform bootstrap and repository checks
docs/                       # architecture, setup, testing, release, ADRs
.github/                    # CI, release, security, templates, Dependabot/funding
```

## Architecture overview

Countora uses a small modular-monolith structure:

1. **Domain** — countdown, interval, preset, history, and settings models.
2. **Data** — persistence codec/store and platform notification adapter.
3. **Presentation** — controller-driven state transitions and adaptive Flutter UI.
4. **Core** — stable clock, design tokens, metadata, links, localization helper, formatting, and structured logging.

Running timers persist an absolute UTC deadline. During one process lifetime, countdown calculations use a monotonic clock anchored to UTC so a wall-clock edit does not directly make a live timer jump. On resume/startup, the controller reconciles elapsed interval steps and reschedules completion notifications.

See [`docs/architecture.md`](docs/architecture.md) and [`docs/adr/`](docs/adr/) for architectural decisions.

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

Unknown future schema versions are rejected instead of silently interpreted. A valid import is previewed before it replaces current local data.

## Localization

English ships first through `lib/l10n/app_en.arb`. User-facing application copy is externalized so additional locales can be added with ARB files without rewriting the main screens.

After modifying ARB files, run:

```bash
flutter gen-l10n
```

Generated localization Dart files are intentionally ignored from Git; CI regenerates them.

## Security and privacy

Countora has no authentication or cloud service. Security work therefore focuses on local input validation, dependency/workflow hygiene, platform permissions, safe diagnostics, and avoiding secret material in source.

- Backup/import JSON is schema/type/size bounded.
- Local corruption falls back to a safe recoverable state.
- Sensitive structured-log keys are redacted.
- Dependency Review blocks newly introduced moderate-or-higher vulnerabilities on pull requests.
- CodeQL scans supported GitHub Actions workflow code.
- Signing keys, `.env`, keystores, and generated credentials are ignored.

Read [`SECURITY.md`](SECURITY.md) and [`PRIVACY.md`](PRIVACY.md).

## CI and release

The main CI workflow checks:

- generated platform bootstrap
- dependency resolution
- localization generation
- formatting
- Flutter static analysis
- Flutter tests
- local Markdown links
- Web release build

Tagged releases additionally build Android APK/AAB, Web, Linux, Windows, macOS, and an unsigned iOS application artifact. Signed store distribution remains an external release-credential step.

No release should be considered verified until the corresponding GitHub Actions run is observed as successful.

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`docs/development.md`](docs/development.md) before opening a pull request. Changes should be small, tested, documented, and committed using meaningful Conventional Commit-style messages when practical.

## Project documentation

- [`docs/architecture.md`](docs/architecture.md)
- [`docs/setup.md`](docs/setup.md)
- [`docs/development.md`](docs/development.md)
- [`docs/testing.md`](docs/testing.md)
- [`docs/release.md`](docs/release.md)
- [`docs/troubleshooting.md`](docs/troubleshooting.md)
- [`docs/accessibility.md`](docs/accessibility.md)
- [`docs/performance.md`](docs/performance.md)
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
