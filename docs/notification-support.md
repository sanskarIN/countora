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

## Persistence ordering

Notification schedule changes depend on successfully persisted timer/settings state. See [`ADR 0005`](adr/0005-persist-before-platform-side-effects.md).

Examples:

- pausing a timer persists the paused state before cancelling its platform schedule;
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

## Permission behavior

The controller requests notification permissions at most once per controller session before scheduling is first needed. The production notification adapter contains platform permission/plugin failures so a permission problem does not crash a timer operation.

A user or operating system can still deny delivery. Countora cannot override OS policy, battery restrictions, focus/do-not-disturb policy, vendor background restrictions, signing limitations, or browser/platform capability limits.

## Manual release verification

Before making a platform-specific public delivery claim, test a release candidate on that platform and record:

1. permission prompt behavior;
2. timer completion while Countora is foregrounded;
3. timer completion while Countora is backgrounded/suspended where supported;
4. sound on/off;
5. vibration on/off where applicable;
6. quiet mode;
7. pause/resume schedule replacement;
8. add-time/restart schedule replacement;
9. multi-step interval scheduling;
10. app-resume reconciliation after one or more elapsed intervals;
11. notification-disable cancellation behavior;
12. Android exact-alarm denial fallback where applicable;
13. reboot/app-update rescheduling behavior where applicable.

Source implementation is not equivalent to verified device behavior. Keep unverified platform claims qualified until the corresponding real workflow/device checks have been observed.

## Automated coverage

Relevant tests include:

- `test/platform_capabilities_test.dart`
- `test/timer_controller_test.dart`
- `test/timer_controller_workflows_test.dart`
- `test/timer_controller_resilience_test.dart`
- `test/settings_page_test.dart`
- `test/platform_patches_test.dart`

The tests protect capability decisions, ordering rules, settings presentation, and failure containment. They do not replace real operating-system notification verification.
