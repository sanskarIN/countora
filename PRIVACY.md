# Privacy

Countora is designed as a local-first timer.

## Data stored locally

The app may store:

- active and paused timer definitions
- timer groups and interval steps
- reusable presets and use counts
- completion history
- appearance, accessibility, notification, and quiet-mode settings

The current implementation does not require an account and does not send this timer data to a Countora server.

## Backup/export

Export creates JSON only when the user explicitly requests it and places that content on the system clipboard. Clipboard contents may be visible to the operating system or other software according to platform rules. Treat exported backups according to the sensitivity of the names you put in timers.

## External links

The About screen can open GitHub, Buy Me a Coffee, and email links through the operating system.

## Deletion

Users can clear history in Settings. Removing a timer or preset removes it from Countora's local state on the next successful save.
