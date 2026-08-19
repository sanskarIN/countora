# Development

## Commands

```bash
dart format lib test tool
flutter analyze
flutter test
```

## Design rules

- Business rules belong in domain/controller code, not widgets.
- Platform plugins stay behind interfaces.
- Persist absolute UTC end instants for running timers.
- Validate names, durations, interval counts, and imported data.
- Keep donation and external-link UI optional and non-intrusive.
- Add a regression test before or with each bug fix.

## State

`TimerController` is deliberately explicit and dependency-injected. Avoid introducing global mutable singletons. If state complexity grows substantially, preserve interfaces and domain models while migrating presentation state in a separate refactor.
