# Development

## Standard workflow

After cloning and generating platform runners, keep localization and dependencies current:

```bash
dart run tool/bootstrap_platforms.dart
flutter pub get
flutter gen-l10n
```

Before committing:

```bash
dart format lib test integration_test tool
flutter analyze
flutter test
dart run tool/check_markdown_links.dart
```

Before a release candidate, also execute host-supported release builds and the integration journey.

## Architectural rules

- Business rules belong in domain/controller code, not widgets.
- Platform plugins stay behind interfaces.
- Persist absolute UTC completion instants for running timers.
- Use the monotonic `StableClock` for live in-process countdown calculations.
- Validate names, groups, durations, interval counts, and imported data at trust boundaries.
- All persisted/imported state must pass through `CountoraStateCodec`.
- Keep local state bounded; do not raise caps without profiling and migration consideration.
- Never introduce global mutable domain state without a documented ADR.
- Keep donation/external-link UI optional and non-intrusive.
- Add a deterministic regression test with every reproducible bug fix.

## State transitions

`TimerController` is the application coordinator and is dependency-injected with:

- `TimerStore`
- `NotificationService`
- `nowUtc`
- `CountoraStateCodec`

Do not call SharedPreferences or platform notification plugins directly from widgets.

A timer mutation should generally:

1. validate input;
2. build a new immutable model value;
3. replace collection state;
4. persist;
5. update notification scheduling if relevant;
6. notify listeners.

## Persistence changes

Any incompatible persisted-model change must:

1. increment the supported schema version;
2. add an explicit migration in `CountoraStateCodec`;
3. preserve supported old backups;
4. reject unknown future backups;
5. add migration and malformed-input tests;
6. document the change in `CHANGELOG.md` and an ADR if architectural.

Do not manually edit persisted user data as a migration strategy.

## Platform customizations

Generated runner directories are ignored. Never rely on an untracked manual edit in `android/`, `ios/`, `windows/`, etc.

Encode required native changes in `tool/bootstrap_platforms.dart` or in Countora-owned templates copied by that script.

## Localization

English source strings live in `lib/l10n/app_en.arb`.

When adding visible UI text:

1. add an ARB key;
2. run `flutter gen-l10n`;
3. use `context.l10n` in presentation code;
4. update translation ARB files when additional locales exist.

Avoid reintroducing hard-coded visible copy into localized screens.

## Diagnostics

Use `AppLogger` for structured diagnostic events.

- Log event names and safe numeric/enum metadata.
- Do not log timer names, imported backup JSON, email addresses, tokens, cookies, authorization headers, or user-entered text.
- Pass errors as `error:` so only their runtime type is emitted by the logger.
- User-facing error messages must be safe and must not expose stack traces or raw plugin/storage exceptions.

## Async UI

Flutter callbacks that intentionally launch a `Future<void>` without awaiting it should use `unawaited(...)`. Long-running operations that require user feedback should expose progress rather than silently blocking a control.

## Commit strategy

Use small, reviewable, meaningful commits. Conventional Commit prefixes are preferred:

- `feat:`
- `fix:`
- `test:`
- `docs:`
- `refactor:`
- `perf:`
- `build:`
- `ci:`
- `chore:`

Do not create empty or churn-only commits merely to inflate history.

Requested repository commit email:

```text
sanskarin@outlook.in
```

## Definition for a merge-ready change

A normal change should have:

- formatted source
- analyzer-clean source
- relevant tests
- no new secret material
- updated docs for behavior/config changes
- no broken local Markdown references
- an atomic commit message describing the change

A release has stricter requirements in [`release.md`](release.md).
