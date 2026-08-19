# ADR 0005: Persist state before platform notification side effects

- Status: Accepted
- Date: 2026-08-19

## Context

Countora keeps timer state locally while also asking the operating system to schedule or cancel completion notifications. Those two systems are not one transaction: local persistence can fail independently from the notification plugin, and notification operations can fail independently from local storage.

If Countora changes a platform notification before the matching timer state is durably saved, a failed save can leave two conflicting truths. For example, the in-memory UI could show a paused timer while the previously persisted timer is still running, but its platform notification has already been cancelled. A restart would then recover a running timer with no corresponding completion schedule.

Backup replacement has the same risk at larger scale: cancelling the old schedules before the imported state is durably saved could destroy valid platform schedules even if the imported replacement cannot be persisted.

## Decision

For timer and notification-setting mutations whose platform side effects depend on newly persisted state, Countora uses this order:

1. validate the requested change;
2. update the candidate in-memory state;
3. persist the resulting Countora state;
4. only after successful persistence, schedule or cancel dependent platform notifications;
5. surface persistence failures without pretending platform state was updated.

Timer reconciliation follows the same rule. Expired/advanced timer state is reconciled in memory, then persisted, and only then are the affected notification schedules synchronized.

Backup import is staged before platform changes:

1. decode and validate the backup;
2. snapshot the current in-memory state;
3. stage and reconcile the imported state without notification side effects;
4. persist the fully staged state;
5. if persistence fails, restore the previous in-memory state and leave the existing notification schedules untouched;
6. if persistence succeeds, cancel schedules for the replaced timers and schedule the imported running timers where supported.

Platform notification operations remain best-effort after persistence. A notification plugin failure must not roll back successfully persisted timer data or crash the timer UI.

## Consequences

### Positive

- Durable timer state remains the authority for restart recovery.
- Failed saves do not create or cancel notification schedules for state that storage never accepted.
- Failed backup persistence does not destroy the previous notification configuration.
- Reconciliation cannot silently desynchronize durable timer state and platform schedules through save-ordering alone.
- Failure-path behavior can be tested with deterministic fake stores and notification services.

### Trade-offs

- Local persistence occurs before notification side effects, so a later notification failure can still leave persisted state without an OS schedule. This is intentionally treated as a recoverable best-effort platform failure rather than corrupting local state.
- Cross-system atomicity is impossible with the current platform APIs. The chosen ordering protects Countora's durable source of truth rather than claiming a transaction that does not exist.
- Import needs a previous-state snapshot so it can restore the in-memory view when the staged replacement cannot be saved.

## Verification

Regression coverage belongs in `test/timer_controller_resilience_test.dart` and must protect at least:

- no scheduling after failed timer persistence;
- no cancellation after failed pause/removal persistence;
- no notification-setting side effects after failed settings persistence;
- no reconciliation schedule changes after failed reconciled-state persistence;
- imported state restoration and unchanged old schedules after failed import persistence.

Any future background service, widget, alarm manager, or database adapter that introduces another state-dependent external side effect should follow this ADR or document a superseding decision.
