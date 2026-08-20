# Notification support

Countora supports its timer experience across Android, iOS, Windows, macOS, Linux, and Web. Notification delivery is modeled as a capability tier because the operating systems and browsers do not all expose the same future-scheduling API.

Timer correctness never depends on a notification. Persisted deadlines, pause/resume, interval reconciliation, history, and in-app completion cues continue to work on every supported Countora target even when the platform cannot schedule a future background notification.

## Capability tiers

The single source of truth is `lib/src/core/platform_capabilities.dart`.

Countora uses three delivery modes:

- `scheduledBackground` — the adapter can register a future notification with the platform.
- `runtimeOnly` — the platform can display local notifications, but Countora must use an in-process timer because the platform/browser cannot register future scheduled delivery.
- `unavailable` — no intentionally supported local-notification implementation exists for that target.

| Target | Countora app support | Notification delivery mode | Current behavior |
| --- | --- | --- | --- |
| Android | Supported | `scheduledBackground` | Exact scheduling is attempted first; Countora falls back to inexact allow-while-idle scheduling when exact scheduling fails. |
| iOS | Supported / signing required for distribution | `scheduledBackground` | Uses the Darwin notification implementation; signed-device behavior remains a release-verification requirement. |
| macOS | Supported | `scheduledBackground` | Uses the Darwin notification implementation; signing/notarization remains a distribution concern. |
| Windows | Supported | `scheduledBackground` | Uses Windows toast notifications; native packaging and cancellation behavior must be verified on release artifacts. |
| Linux | Supported | `runtimeOnly` | Uses Linux desktop notifications while the Countora process remains active; timer state reconciles correctly after resume even when the process could not deliver a background notification. |
| Web | Supported | `runtimeOnly` | Uses the browser Notifications API while the page/runtime remains active. Browsers do not provide future scheduled notification delivery. |
| Fuchsia | Not an intentional Countora target | `unavailable` | Fails closed instead of assuming unsupported behavior. |

A future platform must be explicitly classified and tested. Unknown native targets must never be assumed notification-capable.

## Linux and Web runtime fallback

`LocalNotificationService` keeps a bounded in-process `Timer` for the active timer step on `runtimeOnly` targets.

When the deadline is observed while the runtime remains alive:

1. Countora shows a local notification through the platform/browser plugin.
2. The normal controller ticker reconciles the timer or interval step.
3. If another interval remains, the next step receives a fresh runtime fallback timer.
4. Pausing, deleting, restarting, disabling notifications, importing state, or clearing data cancels/replaces the associated runtime timer through the same notification synchronization path.

This gives Linux and Web useful completion notifications without pretending that a browser tab or Linux process can guarantee delivery after the process has been terminated.

## Cross-platform notification presentation

`countoraNotificationDetails()` configures presentation details for all six supported Flutter targets:

- Android — cue-profile notification channel, sound, vibration, alarm category.
- iOS/macOS — Darwin alert and sound presentation.
- Linux — normal urgency with sound suppression in quiet mode.
- Windows — default audio or an explicitly silent notification in quiet mode.
- Web — browser notification with the `isSilent` flag reflecting quiet/sound preferences.

`test/notification_details_test.dart` protects these per-platform details.

## Settings behavior

`SettingsPage` consumes the same capability source as `LocalNotificationService`.

On Android, iOS, macOS, and Windows:

- completion notifications can be enabled/disabled;
- sound/vibration/quiet preferences remain available;
- Countora explains that platform scheduling can notify while the app is not foregrounded.

On Linux and Web:

- completion notifications remain available instead of being disabled;
- sound/vibration/quiet preferences remain editable where the underlying platform honors them;
- Countora explains that future background scheduling is unavailable and that notification delivery depends on the app runtime remaining active;
- in-app state and visual completion cues continue to reconcile after resume.

Unsupported targets still fail closed.

## Permission behavior

The controller requests notification permission at most once per controller session before notification delivery is first needed.

The production adapter handles:

- Android notification permission and exact-alarm access;
- iOS notification permission;
- macOS notification permission;
- Web notification permission through `WebFlutterLocalNotificationsPlugin`;
- Linux/Windows paths that do not require the same explicit prompt API.

Permission/plugin errors are contained so they do not crash timer operations.

Web permission prompts are governed by browser user-activation rules. Countora requests permission as part of user-initiated timer/notification workflows, but browsers can still reject or suppress the prompt according to their own policy.

## Persistence ordering

Platform schedule changes depend on successfully persisted timer/settings state. See [`ADR 0005`](adr/0005-persist-before-platform-side-effects.md).

Examples:

- pausing a timer persists the paused state before cancelling its platform/runtime schedule;
- removing a timer persists the removal before cancelling its schedule;
- enabling/disabling notifications persists the setting before scheduling/cancelling running timers;
- reconciliation persists advanced/completed state before syncing affected schedules;
- backup import persists the staged/reconciled imported state before replacing old schedules.

If local persistence fails, Countora surfaces the save/import failure and intentionally leaves dependent notification schedules untouched.

## Android generated-runner requirements

`tool/bootstrap_platforms.dart` applies Countora's Android notification requirements after Flutter runner generation by using the pure transforms in `tool/src/platform_patches.dart`.

The generated Android application needs:

- `RECEIVE_BOOT_COMPLETED`
- `SCHEDULE_EXACT_ALARM`
- scheduled-notification receiver
- scheduled-notification boot receiver
- core-library desugaring
- multidex support

The transforms are idempotent and fail explicitly if expected Flutter template anchors disappear. `test/platform_patches_test.dart` protects those assumptions.

## Build verification policy

Cross-platform source support is continuously represented in `.github/workflows/platform-smoke.yml`:

- Android debug APK on Ubuntu;
- Linux debug application on Ubuntu;
- Windows debug application on Windows;
- macOS debug application on macOS;
- unsigned iOS debug compilation on macOS.

The main CI workflow already builds Web and runs the Linux integration journey. Tagged releases continue to build the release artifact set.

A workflow existing in source is not proof that it has passed. Release claims must still wait for observed successful executions.

## Manual release verification

Before making a platform-specific public delivery claim, test a release candidate on that platform and record:

1. permission prompt behavior;
2. timer completion while Countora is foregrounded;
3. timer completion while Countora is backgrounded/suspended where the platform supports it;
4. Linux/Web runtime fallback behavior;
5. sound on/off;
6. vibration behavior where the OS/browser exposes it;
7. quiet mode;
8. pause/resume schedule replacement;
9. add-time/restart schedule replacement;
10. multi-step interval scheduling/runtime fallback;
11. app-resume reconciliation after one or more elapsed intervals;
12. notification-disable cancellation behavior;
13. Android exact-alarm denial fallback;
14. reboot/app-update rescheduling where applicable;
15. Windows packaged vs unpackaged notification cancellation behavior.

Countora cannot override OS focus/do-not-disturb policy, browser lifecycle rules, battery restrictions, vendor background restrictions, signing limitations, or notification-server capabilities.

## Automated coverage

Relevant tests include:

- `test/platform_capabilities_test.dart`
- `test/notification_initialization_test.dart`
- `test/notification_details_test.dart`
- `test/notification_cleanup_test.dart`
- `test/timer_controller_test.dart`
- `test/timer_controller_workflows_test.dart`
- `test/timer_controller_resilience_test.dart`
- `test/settings_page_test.dart`
- `test/platform_patches_test.dart`

These tests protect capability decisions, adapter configuration, ordering rules, settings presentation, and failure containment. They do not replace real operating-system/browser verification.
