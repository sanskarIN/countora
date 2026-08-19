# Performance

Countora avoids storing a changing value every second. One shared one-second ticker refreshes visible remaining times while persisted running timers are represented by UTC end instants.

Performance goals:

- no per-timer periodic `Timer` objects
- no persistence write on every UI tick
- local state document kept small through a 500-entry history cap
- responsive grid limits layout work to visible slivers
- no network dependency for core timer workflows

Benchmark dedicated large-history/database behavior before replacing the current simple persistence layer.
