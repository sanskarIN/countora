# Performance

Countora's main hot path is countdown presentation, not network or database throughput. The design deliberately avoids one periodic timer and one persistence write per countdown.

## Current performance model

- One shared one-second controller ticker updates visible countdown text.
- Running state is represented by an absolute deadline; persistence is not rewritten every second.
- There are no per-countdown periodic `Timer` objects.
- Timer lists use slivers/grids so layout work is scoped to visible children.
- Core functionality has no network request path.
- Backup/persisted state is capped before parsing or growth becomes unbounded.
- History is capped at 500 entries.
- Timers are capped at 500.
- Presets are capped at 500.
- Interval steps are capped at 32 per timer/preset.
- Backup text is capped at 2 MiB.

## Release performance budgets

These are engineering budgets rather than claims from an unrun benchmark:

- idle Countora should not write persisted state on one-second UI refreshes;
- adding/removing/pausing one timer should require at most one local state save for that direct operation;
- timer reconciliation loops must be bounded by timer count and the 32-step interval cap;
- malformed backup parsing must reject input above 2 MiB before model construction;
- main timer list scrolling should remain interactive at the supported 500-timer cap on a representative release device;
- no core timer action may wait for a network response.

## CPU behavior

`TimerController` runs one one-second ticker. The asynchronous tick is guarded against overlap, preventing a slow reconciliation from stacking multiple concurrent tick executions.

On a normal tick with no expired timer, the controller calculates remaining time for running timers and notifies listeners. Expensive persistence and notification rescheduling occur only when state changes.

## Persistence behavior

The current SharedPreferences document approach is appropriate only because the dataset is explicitly bounded. Each mutation serializes the bounded state document.

Do not increase entity/backup caps casually. If real measurements show serialization or query costs becoming material, replace the `TimerStore` implementation with a transactional embedded database rather than making the current document unbounded.

The persistence codec is also the backup parser, so encode/decode cost is worth measuring at a representative high-cardinality state. Countora includes a standalone benchmark harness at `tool/benchmark_state_codec.dart`.

After dependency resolution, run:

```bash
dart run tool/benchmark_state_codec.dart
```

Or choose a bounded iteration count:

```bash
dart run tool/benchmark_state_codec.dart --iterations 500
```

The harness builds a deterministic representative state containing 300 timers, 200 presets, 500 history entries, and four intervals per timer/preset. It verifies every decode round trip and emits machine-readable JSON with fixture size plus encode/decode minimum, p50, p95, and maximum microseconds.

The script intentionally does **not** fail on a wall-clock threshold. Host speed, build mode, thermal state, virtualization, SDK version, and background load make a universal CI timing threshold misleading. Archive measurements with the environment metadata instead.

## Notification behavior

Notification scheduling is event-driven: create/resume/add-time/restart/reconcile/settings changes. It is not performed on every display tick.

Web and Linux currently avoid future background notification scheduling because that capability is unavailable through Countora's current notification adapter there. This prevents repeated unsupported platform calls from becoming timer-action overhead or failures.

## Profiling checklist

Before a stable 1.0 release, profile representative release builds with Flutter DevTools:

1. 1 running timer
2. 50 mixed timers
3. 500 mixed timers
4. 32-step interval sequence
5. 500 history entries
6. maximum-size valid backup export/import
7. background/resume reconciliation with expired intervals
8. repeated navigation between Timers, Presets, History, and Settings

Record:

- frame timings/jank
- CPU during idle one-second refresh
- memory before/after maximum bounded state load
- serialization/import time
- notification scheduling time on Android

For codec measurements, also record:

- exact Countora commit
- Flutter/Dart version
- operating system and architecture
- debug/profile/release context if relevant
- CPU/device model
- iteration count
- encoded fixture size
- p50/p95 encode and decode times

## Benchmark policy

Do not add a fragile wall-clock threshold to normal CI without a controlled benchmark runner. Deterministic correctness tests protect bounds today; the benchmark harness provides repeatable measurement input, while performance claims must still be gathered on explicit representative hardware and documented with device/Flutter/build-mode details.
