# Troubleshooting

## Platform folders are missing

Run:

```bash
dart run tool/bootstrap_platforms.dart
```

## Android notification does not appear

Check app notification permission and exact-alarm permission. Some device vendors apply additional battery restrictions to background work and alarms.

## Timer state looks stale after a long suspension

Return to the app. Countora reconciles running timers from stored UTC end instants during startup and the active ticker.

## Import fails

Verify the pasted backup is valid JSON produced by Countora. Invalid roots or malformed JSON are rejected without replacing current state.
