# Architecture

Countora is a modular Flutter monolith.

## Layers

- `domain`: immutable timer, preset, history, interval, settings, and persisted-state models.
- `data`: adapters for persistence and platform notifications.
- `presentation`: one `ChangeNotifier` application controller plus responsive Material UI.
- `core`: shared theme, links, and formatting.

The controller depends on interfaces (`TimerStore` and `NotificationService`) instead of concrete plugins. This keeps timer behavior testable without platform channels.

## Timer correctness

A running timer stores a UTC end instant. The UI derives remaining duration from `endsAtUtc - nowUtc`; it does not trust a one-second decrement as source of truth. This avoids accumulating tick drift and allows state recovery after app suspension.

Paused timers store remaining seconds. Resuming creates a new UTC end instant. Completed timers enter history exactly once during reconciliation.

## Interval sequences

Each timer owns 1–32 validated interval steps. When a step expires, the controller advances to the next step and sets a new end instant. The notification adapter schedules the remaining sequence completion notifications from the current step onward.

## Persistence

`SharedPreferencesTimerStore` saves one versioned JSON document. The schema begins at version 1. Model parsers use defensive fallbacks so malformed optional fields do not crash startup.

For larger future datasets, migrate to an indexed embedded database behind the same `TimerStore` interface.

## Platform runners

Native runners are generated using the installed Flutter SDK via `tool/bootstrap_platforms.dart`. This prevents stale generated boilerplate while preserving all application source and platform-specific Android notification setup deterministically.
