# Architecture

Countora is a local-first modular Flutter monolith. The architecture is intentionally small enough for an offline countdown utility while keeping platform adapters, untrusted persistence, timer rules, and UI concerns separated.

## Layers

### `lib/src/domain`

Owns immutable product data structures:

- `IntervalStep`
- `CountdownTimer`
- `TimerPreset`
- `TimerHistoryEntry`
- `CountoraSettings`
- `CountoraState`

Domain models describe valid application state and serialization shape but do not know about SharedPreferences, notification plugins, widgets, or navigation.

### `lib/src/data`

Owns infrastructure/trust-boundary concerns:

- `TimerStore` interface
- `SharedPreferencesTimerStore`
- `CountoraStateCodec`
- `NotificationService` interface
- `LocalNotificationService`

The controller depends on interfaces instead of plugin implementations. Unit/widget tests can therefore replace persistence and notifications with deterministic in-memory fakes.

### `lib/src/presentation`

Owns application state transitions and Flutter UI:

- `TimerController`
- Home/timer/preset/history views
- timer editor
- Settings/About screens
- full-screen focus mode

`TimerController` is the application coordinator. It contains timer transitions, reconciliation, persistence orchestration, and notification orchestration, while widgets remain mostly declarative.

### `lib/src/core`

Owns cross-cutting application infrastructure:

- `StableClock`
- structured `AppLogger`
- `openExternalUri` guarded external-launch boundary
- `supportsScheduledNotifications` platform capability policy
- design tokens/theme
- formatting helpers
- application metadata/links
- localization context helper

External links are routed through one small helper that converts a declined or throwing platform URL launch into a safe `false` result. Widgets can then show localized feedback without depending directly on plugin exception behavior.

Scheduled-notification capability is centralized in `platform_capabilities.dart`. The current policy explicitly allows Android, iOS, macOS, and Windows native targets and fails closed for Web, Linux, Fuchsia, or any target not deliberately added to the supported set. The notification adapter and Settings UI consume the same policy so product copy, controls, and platform calls do not diverge.

### `lib/l10n`

`app_en.arb` is the English source of truth for generated Flutter localization. Generated Dart localization files are build outputs and are not committed.

## Timer correctness model

### Running timers

A running timer stores an absolute UTC `endsAtUtc` instant. The persisted source of truth is never a value decremented once per second.

Within one running Countora process, `StableClock` captures one UTC wall-clock anchor and advances it with a monotonic `Stopwatch`. This reduces live countdown jumps if the operating-system clock is manually adjusted while the process remains alive.

### Paused timers

A paused timer stores `remainingWhenPausedSeconds`. Resuming calculates a new absolute UTC deadline from the current runtime clock.

### Completed timers

Completed timers clear running/paused timing fields and receive a completion instant. History insertion occurs at the controller transition that completes the sequence and is capped to the configured local-history maximum.

### Suspension/resume

On initialization and application resume, the controller reconciles running timers against the current clock. If multiple interval deadlines elapsed while suspended, it advances through those elapsed steps rather than adding a fresh duration from the wake-up time.

This prevents interval sequences from accumulating drift merely because the UI was not awake at every boundary.

## Interval sequences

A timer owns 1–32 validated interval steps. Each step has a label and positive duration.

When a running step expires:

1. the controller checks for a next step;
2. the next step starts from the previous absolute deadline, not from an arbitrary delayed UI tick;
3. if no next step exists, the timer completes and a history entry is created;
4. reconciled state is persisted;
5. only after successful persistence are affected completion notifications synchronized where the target supports scheduling.

The notification adapter schedules the remaining sequence completion instants from the current step onward on targets with future-notification support.

## Persistence and backup trust boundary

`SharedPreferencesTimerStore` persists one compact JSON document because Countora's bounded dataset is small and local.

All persisted/imported JSON crosses `CountoraStateCodec`, which enforces:

- current schema support
- migration from legacy unversioned schema
- future-schema rejection
- 2 MiB maximum backup size
- entity-count caps
- 32-step interval cap
- duration bounds
- timer/preset/history ID checks
- duplicate-ID removal
- name/group length bounds
- malformed-state normalization where safe
- controlled `FormatException` for invalid field types

The codec owns persistence schema versioning. `CountoraState.toJson()` serializes domain state without stamping a schema version, while `CountoraStateCodec` adds the current persisted schema at the trust boundary. This keeps migration/version authority in one place.

Clipboard import validates and previews the incoming state before replacement. Import then stages the decoded/reconciled state, persists it, and only after successful persistence replaces related notification schedules. If that save fails, the previous in-memory state is restored and the previous schedules are left untouched. Clipboard export catches platform-channel failures and reports them without mutating local state.

If locally persisted data is corrupted, startup falls back to a safe empty state rather than crashing. Import remains strict because silently replacing current valid data with malformed input would be destructive.

## Notification boundary

`NotificationService` isolates `flutter_local_notifications` from application logic.

The production adapter:

- initializes platform notification implementations, including the web implementation when available
- requests notification permissions only on targets where Countora can use future scheduling
- schedules remaining timer/interval deadlines on supported scheduling targets
- intentionally avoids future scheduling on Web and Linux and fails closed for unsupported native targets
- falls back from exact Android scheduling to inexact scheduling when necessary
- catches plugin/platform failures so notification infrastructure cannot crash a timer operation
- cancels stale schedules when a successfully persisted timer transition requires it
- derives its cancellation bound from the same state-codec interval limit used for validation
- avoids logging user timer names/payload contents

Web and Linux still use the same local timer model, persistence, resume reconciliation, and visible in-app completion state. Their lack of background scheduled completion delivery is a platform-capability limitation, not a different timer data model. Settings disables the scheduled-notification controls there and explains that in-app completion cues continue to work.

Generated Android runner configuration is patched by `tool/bootstrap_platforms.dart` using pure transforms in `tool/src/platform_patches.dart`. Those transforms validate expected template anchors and their postconditions rather than silently accepting an unpatched runner when Flutter's template changes.

## State change and persistence model

There is one application controller and one persisted state document. State-dependent platform notification side effects follow ADR 0005.

A normal timer/settings mutation follows this pattern:

1. validate API input at the controller boundary;
2. create immutable updated model values;
3. replace the relevant candidate in-memory collection item(s);
4. persist the resulting Countora state;
5. only after successful persistence, update/cancel dependent platform notification schedules;
6. notify Flutter listeners as state/error information changes.

This ordering protects the durable local state as Countora's restart authority. Notification delivery itself remains best-effort: if a platform operation fails after persistence, the local timer state remains valid and the failure is contained/logged rather than rolling back durable data.

No global mutable singleton stores domain state.

## Error model

- user/import validation failures are rejected before destructive replacement;
- local persistence failures are surfaced through controller error state;
- failed imported-state persistence restores the previous in-memory state before reporting failure;
- notification platform errors are logged in redacted structured diagnostics and do not corrupt timer state;
- external-link and clipboard platform failures become user-visible feedback instead of uncaught widget exceptions;
- unsupported future notification targets fail closed before scheduling calls;
- corrupted saved JSON does not block startup;
- unsupported future backup schemas fail closed;
- generated Android template drift fails bootstrap explicitly when required patch anchors disappear.

## Localization

English is shipped first, but visible UI copy is externalized in ARB resources. Adding future locales should not require branching business logic by language.

Background notification copy remains English-first in 0.2 because notification scheduling happens outside a widget context; future locale-aware notification scheduling should receive the active locale explicitly rather than reaching into UI globals.

## Platform runners

Native runners are generated using the installed Flutter SDK via `tool/bootstrap_platforms.dart`. This keeps framework-generated platform boilerplate reproducible and avoids committing stale runner files.

The script applies Countora-specific Android notification/desugaring configuration after generation. The pure text transforms are isolated in `tool/src/platform_patches.dart` and regression-tested for required additions, idempotence, and template-drift failure behavior.

## Why not an embedded database yet?

Current state is deliberately capped at 500 timers, 500 presets, and 500 history entries, with a 2 MiB import limit. At this scale, one local JSON state document is simpler than introducing database migrations/indexes and remains easy to back up.

If requirements grow beyond these bounds, replace `SharedPreferencesTimerStore` behind `TimerStore` with a transactional embedded database and add explicit migrations/query indexes before raising limits.

## Related decisions

See [`adr/`](adr/) for durable architecture decisions, including [`ADR 0005`](adr/0005-persist-before-platform-side-effects.md) for persistence/notification ordering.
