# Development

## Standard workflow

After cloning and generating platform runners, keep dependencies and localization current:

```bash
dart run tool/bootstrap_platforms.dart
flutter pub get
dart run tool/check_localization_source.dart
flutter gen-l10n
```

Before committing, run the deterministic repository/source checks and Flutter quality suite:

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

For primary-journey changes, run the integration test on a configured target. Before a release candidate, also execute the host-supported release builds and follow [`release.md`](release.md).

## Architectural rules

- Business rules belong in domain/controller code, not widgets.
- Platform plugins stay behind interfaces or small guarded boundary helpers.
- Persist absolute UTC completion instants for running timers.
- Use the monotonic `StableClock` for live in-process countdown calculations.
- Reconcile an expired running timer before converting it to paused state.
- Preserve positive fractional remaining time when converting a running deadline to whole paused seconds.
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
2. reconcile any deadline-dependent lifecycle state that has already become authoritative;
3. build a new immutable model value;
4. replace collection state;
5. persist the new durable state;
6. only after successful persistence, apply external notification scheduling/cancellation side effects when the operation depends on that state;
7. notify listeners.

This ordering matters. A failed local save must not cancel or create a platform notification for state that durable storage does not yet represent. Regression coverage in `test/timer_controller_resilience_test.dart` protects this rule for direct scheduling, pause/removal cancellation, notification-setting changes, reconciliation, and import rollback.

`test/timer_pause_boundary_test.dart` protects deadline-sensitive pause behavior so an expired timer cannot be frozen as paused-at-zero and a positive fractional second is not truncated away.

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

## Notification boundaries

`LocalNotificationService` owns plugin/platform notification access.

- Keep future-scheduling support explicit in `platform_capabilities.dart`; unknown targets fail closed.
- Keep permission requests user-need driven rather than initialization driven.
- iOS/macOS initialization must continue to defer alert/badge/sound permission prompts until the explicit permission path is used.
- Android cue profiles use stable channel IDs for sound+vibration, sound-only, vibration-only, and silent/quiet behavior because channel configuration persists at the OS level.
- Do not treat source support as proof of native delivery; platform/device verification belongs in the release process.

See [`notification-support.md`](notification-support.md).

## Localization

English source strings live in `lib/l10n/app_en.arb`.

When adding visible UI text:

1. add an ARB key;
2. run `dart run tool/check_localization_source.dart`;
3. run `flutter gen-l10n`;
4. use `context.l10n` in presentation code;
5. update translation ARB files when additional locales exist.

Avoid reintroducing hard-coded visible copy into localized screens. The deterministic localization audit is enforced in normal CI, repository audit, and tagged release quality gates.

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

## Release metadata changes

Version changes must keep these synchronized:

- `pubspec.yaml`
- `lib/src/core/app_metadata.dart`
- `CHANGELOG.md`

`tool/check_version_sync.dart` owns the deterministic check. Its pure helper in `tool/src/version_audit.dart` also validates GitHub release tags and rejects a tagged changelog section that remains marked unreleased.

Do not weaken this guard to make a premature tag pass.

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

- deterministic repository/source audits passing
- formatted source
- analyzer-clean source
- relevant tests
- no new secret material
- updated docs for behavior/config changes
- no broken local Markdown references
- an atomic commit message describing the change

A release has stricter requirements in [`release.md`](release.md).
