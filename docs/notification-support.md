# Notification support

Countora treats background completion notifications as an optional platform capability rather than a requirement for timer correctness. The timer model, persisted deadlines, pause/resume behavior, interval reconciliation, history, and in-app completion cues continue to work even when future notification scheduling is unavailable.

## Current capability policy

The single source of truth is `lib/src/core/platform_capabilities.dart`.

| Target | Future scheduled completion notifications | Current behavior |
| --- | --- | --- |
| Android | Enabled | Exact scheduling is attempted first; Countora falls back to inexact allow-while-idle scheduling when exact scheduling fails. |
| iOS | Enabled in source | Uses the Darwin notification implementation; signed-device behavior still requires release verification. |
| macOS | Enabled in source | Uses the Darwin notification implementation; distribution behavior still requires release verification. |
| Windows | Enabled in source | Uses the Windows notification implementation; native release verification remains required. |
| Web | Disabled | Countora keeps timer state and in-app completion cues but does not call the future-scheduling API. |
| Linux | Disabled | Countora keeps timer state and in-app completion cues but does not call the future-scheduling API. |
| Fuchsia | Disabled | Countora fails closed because this repository does not intentionally support a scheduled-notification adapter there. |

A future platform must be explicitly added to the supported set after its notification implementation and scheduling behavior are verified. Unknown targets must not be assumed capable.

## Settings behavior

`SettingsPage` consumes the same capability helper as `LocalNotificationService`.

When future scheduling is available:

- Completion notifications can be enabled/disabled.
- Sound can be enabled/disabled.
- Vibration can be enabled/disabled.
- Quiet mode can suppress sound/vibration while keeping visual notification delivery.

When future scheduling is unavailable:

- the completion-notification control is disabled;
- sound, vibration, and quiet-mode controls are disabled because they only affect scheduled completion notifications;
- Countora explains that in-app countdown state and visual completion cues still work.

This prevents the UI from promising a background capability that the service intentionally does not call.

## Permission behavior

The controller requests notification permissions at most once per controller session before scheduling is first needed. The production notification adapter contains platform permission/plugin failures so a permission problem does not crash a timer operation.

On iOS and macOS, `countoraNotificationInitializationSettings()` explicitly disables initialization-time alert, badge, and sound permission requests. Permission is requested later through `requestPermissions()` only when Countora reaches the scheduling path. This keeps startup from prompting merely because the notification plugin was initialized.

On Android, Countora requests normal notification permission and exact-alarm permission through the platform adapter when scheduling is first needed. If exact scheduling is unavailable, the scheduling path attempts the inexact allow-while-idle fallback.

A user or operating system can still deny delivery. Countora cannot override OS policy, battery restrictions, focus/do-not-disturb policy, vendor background restrictions, signing limitations, or browser/platform capability limits.

## Android cue-profile channels

Android notification channel configuration is persistent once the operating system creates a channel. To avoid reusing one channel ID while asking for contradictory sound/vibration behavior, Countora maps cue profiles to four stable channel IDs:

- sound + vibration
- sound only
- vibration only
- silent (also used by quiet mode)

`countoraAndroidNotificationDetails()` owns this mapping. This makes Countora's selected cue profile explicit when a notification is scheduled. Users remain in control of channel-level behavior through Android system settings, so device-level overrides can still differ from in-app defaults.

## Persistence ordering

Notification schedule changes depend on successfully persisted timer/settings state. See [`ADR 0005`](adr/0005-persist-before-platform-side-effects.md).

Examples:

- pausing a timer persists the paused state before cancelling its platform schedule;
- removing a timer persists the removal before cancelling its schedule;
- enabling/disabling notifications persists the setting before scheduling/cancelling running timers;
- reconciliation persists advanced/completed state before syncing affected schedules;
- backup import persists the staged/reconciled imported state before replacing old schedules.

If local persistence fails, Countora surfaces the save/import failure and intentionally leaves dependent notification schedules untouched.

## Deadline-boundary behavior

Pause operations reconcile a running timer whose deadline has already arrived instead of freezing it as a paused zero-second countdown. Positive fractional seconds are rounded up when converting a running deadline into persisted paused whole seconds, avoiding an early one-second truncation at the pause boundary.

Bulk pause first reconciles already-expired timers, persists those lifecycle changes, synchronizes their schedules, and then pauses timers that are still running.

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

## Manual release verification

Before making a platform-specific public delivery claim, test a release candidate on that platform and record:

1. permission prompt behavior, including absence of an Apple startup prompt before notification use;
2. timer completion while Countora is foregrounded;
3. timer completion while Countora is backgrounded/suspended where supported;
4. sound on/off;
5. vibration on/off where applicable;
6. quiet mode;
7. Android cue-profile/channel behavior and OS-level overrides;
8. pause/resume schedule replacement;
9. add-time/restart schedule replacement;
10. multi-step interval scheduling;
11. app-resume reconciliation after one or more elapsed intervals;
12. notification-disable cancellation behavior;
13. Android exact-alarm denial fallback where applicable;
14. reboot/app-update rescheduling behavior where applicable.

Source implementation is not equivalent to verified device behavior. Keep unverified platform claims qualified until the corresponding real workflow/device checks have been observed.

## Automated coverage

Relevant tests include:

- `test/platform_capabilities_test.dart`
- `test/notification_initialization_test.dart`
- `test/notification_channel_profile_test.dart`
- `test/timer_controller_test.dart`
- `test/timer_controller_workflows_test.dart`
- `test/timer_controller_resilience_test.dart`
- `test/timer_pause_boundary_test.dart`
- `test/settings_page_test.dart`
- `test/platform_patches_test.dart`

The tests protect capability decisions, permission-init policy, channel-profile mapping, persistence ordering, deadline-boundary behavior, settings presentation, and failure containment. They do not replace real operating-system notification verification.
