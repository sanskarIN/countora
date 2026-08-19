# ⏳ Countora

<p align="center">
  <strong>Multiple countdowns. Reusable presets. Interval workflows. Local-first by design.</strong>
</p>

<p align="center">
  <a href="https://buymeacoffee.com/sanskarIN">
    <img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-sanskarIN-FFDD00?logo=buy-me-a-coffee&logoColor=000000" alt="Buy Me a Coffee">
  </a>
</p>

**Countora** is a production-oriented Flutter countdown timer for running multiple timers at once, creating reusable presets, organizing named timer groups, and building optional interval sequences. It stores timer state locally and anchors running countdowns to UTC completion instants so suspension and timezone changes do not reset a timer.

> **Made by the Sanskar**

## Highlights

- Multiple simultaneous countdown timers
- Pause, resume, restart, delete, and add-time controls
- Reusable presets, use-frequency tracking, and named groups
- Multi-step interval sequences
- Background local completion notifications
- Local completion history
- Search and group filtering
- Full-screen focus mode and compact card mode
- Light, dark, and system themes
- Sound, vibration, quiet mode, and reduced-motion preferences
- Local JSON backup/export and restore/import
- Responsive phone/tablet/desktop/web UI
- Keyboard-friendly Material controls and semantic timer labels
- No account requirement and no cloud data dependency

## Screenshots

Real screenshots will be added after the first verified multi-platform build. Placeholder images are intentionally not used as fake product captures.

## Platforms

Architecture targets Android, iOS, Web, Windows, macOS, and Linux. Native runner folders are generated from the installed Flutter SDK so the repository does not freeze stale platform boilerplate.

## Tech stack

- Flutter + Dart
- `shared_preferences` for small local state persistence
- `flutter_local_notifications` for scheduled local notifications
- `timezone` for timezone-aware notification scheduling
- `url_launcher` for support/source links

## Quick start

Prerequisite: Flutter SDK **3.38.1 or newer** with Dart **3.10 or newer**.

```bash
git clone https://github.com/sanskarIN/countora.git
cd countora
dart run tool/bootstrap_platforms.dart
flutter pub get
flutter run
```

The bootstrap command runs `flutter create` for all supported platform runners and applies the Android manifest and Gradle entries needed for scheduled notifications.

## Verification

```bash
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter build web --release
```

Platform builds can then be run on matching hosts:

```bash
flutter build apk --release
flutter build windows --release
flutter build linux --release
flutter build macos --release
flutter build ios --release --no-codesign
```

## Project structure

```text
lib/
  main.dart
  src/
    core/          # links, formatting, theme
    data/          # persistence and notifications
    domain/        # timers, presets, history, settings
    presentation/  # controller and responsive UI
test/              # unit/controller tests
tool/              # deterministic platform bootstrap
docs/              # architecture, setup, testing, release, ADRs
.github/            # CI, security analysis, templates
```

See [`docs/architecture.md`](docs/architecture.md) for design details.

## Reliability model

Running timers persist their UTC end instant rather than decrementing and saving every second. On app startup, Countora derives remaining time from that instant and reconciles expired timers. Interval sequences schedule the remaining completion notifications ahead of time. Device/OEM power policies may still affect notification delivery; the countdown state itself remains local and recoverable.

## Privacy and security

Countora does not require sign-in. Timer names, presets, settings, and history are stored locally. Backups are only created when the user explicitly copies/export them. See [`PRIVACY.md`](PRIVACY.md) and [`SECURITY.md`](SECURITY.md).

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a pull request. Run formatting, analysis, and tests for every change.

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
