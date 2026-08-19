# ADR 0002 — Use a monotonic runtime clock for live countdowns

- Status: Accepted
- Date: 2026-08-19

## Context

A countdown based directly on repeated `DateTime.now()` calls can jump forward or backward if the device wall clock changes while Countora is running. A simple decrementing counter avoids that specific problem but accumulates drift and cannot recover accurately after process suspension.

Countora must also restore timers after a process restart, which requires a wall-clock-compatible persisted representation.

## Decision

Persist running countdown deadlines as UTC instants, but use `StableClock` during a process lifetime:

1. capture one UTC wall-clock anchor at startup;
2. start a monotonic Dart `Stopwatch`;
3. compute runtime `nowUtc` as `anchor + stopwatch.elapsed`;
4. derive remaining time from the persisted UTC deadline and runtime clock;
5. reconcile persisted deadlines again at process initialization/application resume.

## Consequences

### Positive

- live countdowns are less sensitive to manual/system wall-clock edits;
- timers still survive process termination because deadlines remain UTC instants;
- countdown progress does not depend on one-second decrement accuracy;
- deterministic tests can inject time.

### Trade-offs

- after a full process restart, Countora necessarily uses the current wall clock to interpret persisted UTC deadlines;
- device clock changes while the app is not running can affect the restored interpretation;
- platform notification schedulers still operate using platform time facilities and are reconciled when Countora resumes.

## Alternatives rejected

- Persist/decrement remaining time every second: unnecessary writes, drift, poor suspension recovery.
- Use only wall-clock `DateTime.now()`: simpler but live timers jump with wall-clock edits.
- Implement a native monotonic service per platform: much higher complexity without enough value for the current offline timer scope.
