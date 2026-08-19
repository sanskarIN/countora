# Testing

Current automated tests cover domain serialization, remaining-time calculation, negative-time clamping, malformed-state recovery, controller add/pause/resume/persistence behavior, and interval rollover on startup.

Run:

```bash
flutter test
flutter test --coverage
```

CI also runs formatting and static analysis.

Future integration coverage should exercise platform notification scheduling on actual/simulated supported targets because platform channels cannot be fully validated by pure Dart/widget tests.
