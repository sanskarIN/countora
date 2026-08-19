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
- Platform plugins stay behind interfaces or small guarded boundary helpers.
- Persist absolute UTC completion instants for running timers.
- Use the monotonic `StableClock` for live in-process countdown calculations.
- Validate names, groups, durations, interval counts, and imported data at trust boundaries.
- All persisted/imported state must pass through `CountoraStateCodec`.
- Keep persistence schema ownership in the codec, not domain-model serialization.
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
4. persist the new durable state;
5. only after successful persistence, apply external notification scheduling/cancellation side effects when the operation depends on that state;
6. notify listeners.

This ordering matters. A failed local save must not cancel or create a platform notification for state that durable storage does not yet represent. Regression coverage in `test/timer_controller_resilience_test.dart` protects this rule for direct scheduling, pause/removal cancellation, and notification-setting changes.

Platform operations that are best-effort by nature, such as URL launching, remain guarded so plugin/platform exceptions do not escape into the widget tree.

## Persistence changes

Any incompatible persisted-model change must:

1. increment the supported schema version;
2. add an explicit migration in `CountoraStateCodec`;
3. preserve supported old backups;
4. reject unknown future backups;
5. add migration and malformed-input tests;
6. document the change in `CHANGELOG.md` and an ADR if architectural.

Do not manually edit persisted user data as a migration strategy.

`CountoraState.toJson()` intentionally contains only domain state. `CountoraStateCodec` adds the persisted `schemaVersion`, keeping migration/version authority in one boundary.

## Platform customizations

Generated runner directories are ignored. Never rely on an untracked manual edit in `android/`, `ios/`, `windows/`, etc.

Encode required native changes through `tool/bootstrap_platforms.dart`. Pure generated-template transforms belong in `tool/src/platform_patches.dart` so they can be regression-tested without launching Flutter or mutating the file system.

A platform patch must:

1. detect the template structure it expects;
2. fail explicitly when required anchors disappear;
3. verify required postconditions;
4. remain idempotent;
5. gain/update a test in `test/platform_patches_test.dart`.

Silent success with an incompletely patched native runner is not acceptable.

## Localization

English source strings live in `lib/l10n/app_en.arb`.

When adding visible UI text:

1. add an ARB key;
2. run `flutter gen-l10n`;
3. use `context.l10n` in presentation code;
4. update translation ARB files when additional locales exist.

Avoid reintroducing hard-coded visible copy into localized screens.

Semantics hints are user-facing copy too. For example, a timer card announces that activating it will **open** focus mode, while the close control announces the separate exit action.

## Diagnostics

Use `AppLogger` for structured diagnostic events.

- Log event names and safe numeric/enum metadata.
- Do not log timer names, imported backup JSON, email addresses, tokens, cookies, authorization headers, or user-entered text.
- Pass errors as `error:` so only their runtime type is emitted by the logger.
- User-facing error messages must be safe and must not expose stack traces or raw plugin/storage exceptions.

## Performance work

Do not guess at performance improvements. Use bounded deterministic fixtures and record environment details for wall-clock measurements.

The codec benchmark can be run with:

```bash
dart run tool/benchmark_state_codec.dart
```

or:

```bash
dart run tool/benchmark_state_codec.dart --iterations 500
```

See [`performance.md`](performance.md) for fixture details and benchmarking policy. Do not add a universal CI timing threshold unless the runner environment is controlled well enough to make it meaningful.

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
