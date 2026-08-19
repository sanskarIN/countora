# ADR 0003 — Use versioned bounded JSON for local state and backups

- Status: Accepted
- Date: 2026-08-19

## Context

Countora is an offline-first utility with a deliberately bounded dataset. It needs simple local persistence and a human-portable backup format, but imported JSON is untrusted input and old backups must remain interpretable as the model evolves.

Blindly passing decoded JSON into domain constructors would make corrupted or hostile inputs capable of causing startup/import failures, excessive memory use, or invalid application state.

## Decision

Use one versioned JSON state document behind `TimerStore` and process every persisted/imported document through `CountoraStateCodec`.

The codec:

- defines the supported schema version;
- migrates known legacy schemas explicitly;
- rejects unknown future schemas;
- rejects non-object roots and malformed field types;
- caps raw backup size;
- caps timers, presets, history entries, interval count, durations, names, and groups;
- removes duplicate/empty IDs where recovery is safe;
- normalizes malformed domain values conservatively;
- returns controlled `FormatException` failures for unsafe inputs.

Clipboard import validates before replacing current state and shows a count preview first.

## Consequences

### Positive

- backup compatibility has an explicit migration boundary;
- malformed imports fail closed instead of partially replacing valid data;
- resource use is bounded;
- local corruption can be recovered safely;
- persistence remains simple for the current product scale.

### Trade-offs

- state writes serialize the bounded document as a whole;
- query/index performance is not appropriate for unbounded datasets;
- migrations must be added whenever a future schema becomes incompatible.

## Migration rule

Never silently reinterpret a future schema. Increment `currentSchemaVersion`, implement an explicit migration from every still-supported predecessor, and add migration/regression tests before release.

## When to revisit

Move to a transactional embedded database behind `TimerStore` if state volume, query complexity, partial-update requirements, or migration requirements outgrow the bounded document model.
