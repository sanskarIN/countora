# Backup format

Countora exports local application state as a versioned JSON object. The format is intentionally human-readable, but imported backup text is treated as untrusted input and must pass through `CountoraStateCodec` before it can replace current local state.

Do not manually change `schemaVersion` to make an incompatible backup appear supported.

## Top-level document

A current Countora backup has this shape:

```json
{
  "schemaVersion": 1,
  "timers": [],
  "presets": [],
  "history": [],
  "settings": {}
}
```

The codec owns `schemaVersion`. Domain-model `toJson()` methods do not independently stamp persistence schema metadata.

## Schema compatibility

Current behavior:

- the current schema is accepted;
- legacy unversioned state is migrated through the codec;
- unknown future schema versions are rejected;
- malformed JSON is rejected;
- a JSON root that is not an object is rejected;
- structurally invalid field types are rejected when they cannot be safely normalized.

Any incompatible future persistence change must add an explicit migration and update regression coverage before the schema version changes.

## Safety bounds

The codec keeps the local document bounded:

| Item | Maximum/current rule |
| --- | --- |
| Backup text | 2 MiB |
| Timers | 500 |
| Presets | 500 |
| History entries | 500 |
| Interval steps per timer/preset | 32 |
| Timer/preset/history identifier | 128 characters; oversized identifiers are dropped, not truncated |
| Name/interval label | 80 characters |
| Group | 40 characters |
| Individual interval duration | 365 days |

Imported duplicate/invalid entities may be removed or normalized where the codec has an unambiguous safe recovery rule. Inputs that cannot be interpreted safely fail closed instead.

Identifiers are not truncated because truncation could turn two distinct imported identifiers into the same identifier or accidentally change history/timer relationships. Empty or oversized timer/preset IDs are dropped, and history entries with empty or oversized timer IDs are dropped.

## Timer object

A serialized timer contains:

```json
{
  "id": "t_example",
  "name": "Tea",
  "group": "Kitchen",
  "steps": [
    {
      "label": "Steep",
      "durationSeconds": 180
    }
  ],
  "currentStepIndex": 0,
  "status": "paused",
  "remainingWhenPausedSeconds": 180,
  "endsAtUtc": null,
  "startedAtUtc": null,
  "completedAtUtc": null
}
```

### Timer fields

- `id` — local timer identifier. Empty or oversized IDs are not retained by decoded state.
- `name` — user-visible timer name.
- `group` — optional user-visible group name.
- `steps` — one or more interval objects.
- `currentStepIndex` — zero-based current interval index, clamped to the recovered interval list.
- `status` — `running`, `paused`, or `completed`.
- `remainingWhenPausedSeconds` — persisted paused duration. Running timer display is derived from its absolute deadline rather than decrementing this field every second.
- `endsAtUtc` — ISO-8601 UTC deadline for a running step, otherwise `null` when appropriate.
- `startedAtUtc` — ISO-8601 UTC start instant when available.
- `completedAtUtc` — ISO-8601 UTC completion instant for a completed timer when available.

For a running timer, the absolute UTC deadline is the persisted recovery source of truth. During one live process, Countora uses its monotonic runtime clock to reduce jumps caused by wall-clock edits.

## Interval step object

```json
{
  "label": "Focus",
  "durationSeconds": 1500
}
```

- `label` is required after validation/recovery and is bounded to the same user-facing label limit used by the controller.
- `durationSeconds` must be positive and remain within Countora's configured maximum individual interval duration.

An imported timer/preset whose interval data is unusable is normalized to a bounded safe fallback where the codec can do so deterministically.

## Preset object

```json
{
  "id": "preset_example",
  "name": "Pomodoro",
  "group": "Study",
  "steps": [
    {
      "label": "Focus",
      "durationSeconds": 1500
    },
    {
      "label": "Break",
      "durationSeconds": 300
    }
  ],
  "useCount": 4
}
```

Preset identifiers follow the same 128-character maximum as timer identifiers. `useCount` is local usage metadata and is normalized to a non-negative bounded value by the persistence trust boundary.

## History object

```json
{
  "timerId": "t_example",
  "name": "Tea",
  "group": "Kitchen",
  "completedAtUtc": "2026-08-19T09:00:00.000Z",
  "totalDurationSeconds": 180
}
```

History is local completion history. The controller retains at most 500 entries. History entries whose imported `timerId` is empty or exceeds the identifier bound are discarded at the codec boundary.

## Settings object

A settings object can contain:

```json
{
  "themeMode": "system",
  "language": "system",
  "notificationsEnabled": true,
  "soundEnabled": true,
  "vibrationEnabled": true,
  "quietMode": false,
  "reducedMotion": false,
  "compactCards": false,
  "onboardingSeen": true
}
```

The `language` field currently accepts Countora's persisted preference names:

- `system` — follow the device/browser locale;
- `english` — force English (`en`);
- `hindi` — force Hindi (`hi`).

Older backups that omit `language`, or backups containing an unknown language preference, safely fall back to `system`. This optional additive setting therefore does not require a persistence-schema bump.

Unknown/missing supported settings fall back to Countora's safe defaults where implemented. Platform capability remains separate from the saved preference: for example, a backup can contain `notificationsEnabled: true`, while Web/Linux still refuse unsupported future scheduling and keep only their documented runtime notification behavior.

## Import transaction behavior

Countora does not immediately destroy current local state after JSON parsing succeeds.

The controller import sequence is:

1. decode and validate the backup;
2. snapshot current in-memory state;
3. stage imported timers, presets, history, and settings;
4. reconcile staged running timers without platform notification side effects;
5. persist the staged/reconciled replacement;
6. restore the previous in-memory state if persistence fails;
7. only after successful persistence replace old notification schedules with schedules for the imported running timers where supported.

This ordering keeps durable local state authoritative and prevents a failed backup save from destroying the previous platform notification configuration.

See [`adr/0005-persist-before-platform-side-effects.md`](adr/0005-persist-before-platform-side-effects.md).

## Read-only backup inspection

After dependency resolution, a backup file can be validated without importing it into the app:

```bash
dart run tool/inspect_backup.dart path/to/countora-backup.json
```

The command:

- checks that exactly one file path was supplied;
- rejects files above the configured backup-size limit before reading their contents;
- rejects unreadable/non-UTF-8 input safely;
- decodes the file through `CountoraStateCodec`;
- emits machine-readable JSON containing only structural counts and byte size;
- does not print timer names, groups, interval labels, history names, or the backup body.

Example structural output:

```json
{
  "valid": true,
  "schemaVersion": 1,
  "inspection": {
    "encodedBytes": 1234,
    "timers": {
      "total": 3,
      "running": 1,
      "paused": 1,
      "completed": 1,
      "intervalSteps": 5
    },
    "presets": {
      "total": 2,
      "intervalSteps": 6
    },
    "historyEntries": 10
  }
}
```

The inspection command is read-only. It never writes Countora application state and should not be confused with the app's import confirmation workflow.

## Privacy guidance

Backup JSON can contain user-entered timer names, groups, interval labels, completion history, and local preferences. Treat the complete backup as private user data.

Do not:

- attach a real personal backup to a public issue;
- paste backup contents into CI logs;
- commit real backups to the repository;
- include backup bodies in diagnostic logs;
- upload backups to third-party services merely to validate JSON.

Use synthetic fixtures for tests and issue reproduction.

## Recovery guidance

If an import is rejected:

1. keep the original file unchanged;
2. verify that it is actually a Countora backup;
3. use the read-only inspection command on a trusted local machine if appropriate;
4. if the backup reports a future schema version, update Countora rather than editing the version field;
5. if corruption is suspected, restore from another known-good exported backup.

See [`troubleshooting.md`](troubleshooting.md) for additional recovery guidance.