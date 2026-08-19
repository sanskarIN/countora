# Privacy

Countora is designed as a **local-first, account-free countdown timer**. The current application does not require a Countora account or a Countora-operated cloud backend for core timer functionality.

## Data stored locally

Countora may store on the device:

- active, paused, and completed timer definitions
- timer names and groups entered by the user
- interval labels and durations
- reusable presets and local use counts
- completion history
- appearance/theme preferences
- reduced-motion preference
- notification, sound, vibration, and quiet-mode preferences
- onboarding-seen state

The current implementation stores this bounded application state through Flutter SharedPreferences as a versioned JSON document.

## Network behavior

Core countdown, preset, history, search, settings, backup, and restore workflows do not require a Countora server.

The application can open external destinations only when the user chooses a corresponding link, including:

- GitHub repository/profile/releases/issues
- Buy Me a Coffee
- email links for business/support

Those external services/applications have their own privacy practices.

## Notifications

If completion notifications are enabled, Countora asks the operating system for relevant notification permissions when scheduling is actually needed.

Notification scheduling uses the local platform notification system. Timer completion content can include the user-defined timer/interval name in the local notification title. Operating systems may display notifications on a lock screen according to the user's OS notification/privacy settings.

If timer names are sensitive, configure lock-screen notification visibility at the operating-system level or disable Countora notifications.

## Diagnostics

Countora does not intentionally send application diagnostics to a Countora server in the current implementation.

Local structured debug diagnostics are designed to avoid timer names, backup payloads, credentials, authorization data, emails, and other sensitive keyed content. Error diagnostics record safe event metadata/error types rather than raw user content where implemented.

## Backup/export

Export occurs only when the user explicitly chooses **Export local backup**.

The current export flow copies versioned JSON to the system clipboard. Clipboard contents can be visible to the operating system and, depending on platform policy, other software. A backup can contain user-created timer/group/interval names and local history.

Treat exported backups according to the sensitivity of the names entered into Countora. Clear clipboard contents after transferring a sensitive backup if appropriate for the device/platform.

## Backup/import

Import occurs only after the user pastes/provides JSON and confirms a validated preview.

Countora validates size/schema/types/bounds before replacing current local state. A successful import replaces current local Countora data with the imported state.

## Data limits

Current local/import limits include:

- 2 MiB backup text
- 500 timers
- 500 presets
- 500 history entries
- 32 interval steps per timer/preset
- 80-character names/labels
- 40-character groups

These caps are reliability/security boundaries, not a promise that every supported platform has identical storage quotas.

## Deletion

Users can:

- remove an individual timer
- remove an individual preset
- remove completed timers
- clear completion history while keeping timers/presets
- erase all local Countora timers, presets, history, and settings from Settings

A destructive full reset first attempts to clear the underlying store. If that clear fails, Countora does not intentionally pretend the reset succeeded.

Platform backups, device snapshots, clipboard managers, OS-level backups, or filesystem recovery may be outside Countora's control. Use operating-system tools to manage those copies.

## No sale of data

Countora's current source contains no advertising SDK, analytics SDK, account backend, or data-broker integration. The project does not implement a mechanism to sell timer data.

## Children and accounts

Countora does not require account creation and does not intentionally collect age or identity information through the application.

## Changes to privacy behavior

Any future feature that adds cloud sync, analytics, crash reporting, authentication, advertising, or remote data storage must update this document, expose the behavior clearly in the product, use explicit secure configuration, and undergo security/privacy review before release.

## Contact

Privacy/support questions:

- `supportramsandesh@gmail.com`
- `sanskarin@outlook.in`

Security-sensitive reports should follow [`SECURITY.md`](SECURITY.md).
