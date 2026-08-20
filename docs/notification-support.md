# Notification support

Countora supports its timer experience across Android, iOS, Windows, macOS, Linux, and Web. Notification delivery is modeled as a capability tier because operating systems, browsers, and Windows packaging modes do not expose identical future-scheduling and cancellation guarantees.

Timer correctness never depends on a notification. Persisted deadlines, pause/resume, interval reconciliation, history, and in-app completion cues continue to work on every supported Countora target even when future background notification delivery is unavailable.

## Capability tiers

The single source of truth is `lib/src/core/platform_capabilities.dart`.

Countora uses three delivery modes:

- `scheduledBackground` — Countora can register future delivery and can satisfy the cancellation/replacement behavior required by timer edits.
- `runtimeOnly` — the target can display local notifications, but Countora intentionally ties delivery to its active runtime because the platform API or current packaging does not provide the full scheduling/cancellation guarantees Countora requires.
- `unavailable` — no intentionally supported local-notification implementation exists for that target.

| Target / distribution | Countora app support | Notification delivery mode | Current behavior |
| --- | --- | --- | --- |
| Android | Supported | `scheduledBackground` | Exact scheduling is attempted first; Countora falls back to inexact allow-while-idle scheduling when exact scheduling fails. |
| iOS | Supported / signing required for distribution | `scheduledBackground` | Uses Darwin future scheduling. Generated runner setup installs the notification-center delegate required for foreground presentation. |
| macOS | Supported | `scheduledBackground` | Uses Darwin future scheduling; signing/notarization remains a distribution concern. |
| Windows portable ZIP | Supported | `runtimeOnly` | Displays Windows notifications while Countora is active. Portable builds deliberately avoid future scheduling because reliable notification cancellation/history requires Windows package identity. |
| Windows MSIX | Supported packaging path | `scheduledBackground` | The MSIX build sets `COUNTORA_WINDOWS_PACKAGED=true`, enabling future Windows scheduling with package identity. Production signing remains a release-environment responsibility. |
| Linux | Supported | `runtimeOnly` | Uses Linux desktop notifications while the Countora process remains active; timer state reconciles correctly after resume/restart. |
| Web | Supported | `runtimeOnly` | Uses the browser Notifications API while the page/runtime remains active. Permission is requested only from the explicit Settings button; browsers do not provide Countora with guaranteed future scheduled delivery after the page/runtime is gone. |
| Fuchsia | Not an intentional Countora target | `unavailable` | Fails closed instead of assuming unsupported behavior. |

A future platform must be explicitly classified and tested. Unknown native targets must never be assumed notification-capable.

## Runtime notification fallback

`LocalNotificationService` keeps a bounded in-process `Timer` for the active timer step on `runtimeOnly` targets: Linux, Web, and portable Windows builds.

When the deadline is observed while the runtime remains alive:

1. Countora shows a local notification through the platform/browser plugin.
2. The normal controller ticker reconciles the timer or interval step.
3. If another interval remains, the next step receives a fresh runtime fallback timer.
4. Pausing, deleting, restarting, disabling notifications, importing state, or clearing data cancels/replaces the associated runtime timer through the same notification synchronization path.

A deadline-race guard prevents controller reconciliation from cancelling a completion callback that is already due. `test/runtime_notification_policy_test.dart` protects that policy.

This gives runtime-only targets useful completion notifications without pretending that a terminated process, closed browser page, or unpackaged Windows build has the same guarantees as native scheduled-delivery targets.

## Windows package identity

Countora differentiates portable and packaged Windows builds through a compile-time flag:

```text
COUNTORA_WINDOWS_PACKAGED
```

The default is `false`, so a normal portable `flutter build windows` uses the safe runtime fallback.

`pubspec.yaml` contains an MSIX packaging configuration whose Windows build arguments set:

```text
--dart-define=COUNTORA_WINDOWS_PACKAGED=true
```

That packaged build can use scheduled Windows delivery because it has package identity. `tool/src/version_audit.dart` also requires the MSIX four-part version to stay synchronized with `MAJOR.MINOR.PATCH+BUILD`.

The current CI/release workflows **verify MSIX creation but do not present the development/self-signed MSIX as a production-signed artifact**. A trusted production certificate or store signing configuration must be provided by the release environment before a packaged Windows build is promoted publicly.

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

On Android, iOS, macOS, and packaged Windows builds:

- completion notifications can be enabled/disabled;
- sound/vibration/quiet preferences remain available;
- Countora explains that platform scheduling can notify while the app is not foregrounded.

On Linux, Web, and portable Windows builds:

- completion notifications remain available instead of being disabled;
- sound/vibration/quiet preferences remain editable where the underlying target honors them;
- Countora explains that future background scheduling is unavailable for that runtime/distribution mode;
- in-app state and visual completion cues continue to reconcile after resume/restart.

On Web specifically, Settings also exposes **Browser notification permission → Allow**. That button is the only path that asks the browser for notification permission. Automatic timer scheduling, startup, persistence, and reconciliation never trigger the Web prompt.

Unsupported targets still fail closed.

## Permission behavior

The controller requests native notification permission at most once per controller session before native notification delivery is first needed.

The production adapter automatically handles:

- Android notification permission and exact-alarm access;
- iOS notification permission;
- macOS notification permission;
- Linux/Windows paths that do not use the same explicit permission-prompt API.

Web is intentionally different. Browsers require notification permission to originate directly from user activation. `lib/src/data/web_notification_permission.dart` isolates that boundary, and `SettingsPage` invokes it directly from the **Allow** button. `LocalNotificationService.requestPermissions()` deliberately does not request Web permission, preventing startup/reconciliation/timer callbacks from causing an invalid automatic browser prompt.

If the browser denies permission, Countora keeps timer state, history, reconciliation, and in-app visual completion cues working; only browser notification delivery is unavailable until browser/user policy changes.

Permission/plugin errors are contained so they do not crash timer operations. Representative browsers still require manual verification because browser policy ultimately decides whether notification permission and delivery are allowed.

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

The generated Android application is hardened for:

- `RECEIVE_BOOT_COMPLETED`;
- `SCHEDULE_EXACT_ALARM`;
- scheduled-notification receiver;
- scheduled-notification boot receiver;
- core-library desugaring;
- multidex support;
- Android Gradle Plugin **8.11.1 or newer**, matching the minimum required by the current `flutter_local_notifications` dependency line.

`patchAndroidSettingsGradle()` raises an older generated Plugin DSL AGP declaration to `8.11.1` but leaves a newer AGP untouched. The transform fails explicitly if Flutter's generated settings template no longer contains the expected declaration.

The dependency also requires an Android compile SDK of at least 35. Countora relies on the supported Flutter SDK's generated `flutter.compileSdkVersion`; the real Android smoke/release build remains the final proof that the generated toolchain satisfies that requirement.

## iOS generated-runner requirement

`tool/bootstrap_platforms.dart` also patches `ios/Runner/AppDelegate.swift`.

The transform:

- adds `import UserNotifications`;
- installs `UNUserNotificationCenter.current().delegate` before generated plugin registration;
- is idempotent;
- fails explicitly if Flutter's generated AppDelegate template no longer contains the expected anchors.

`test/platform_patches_test.dart` protects Android manifest/Gradle/settings transforms and the iOS AppDelegate transform.

## Build verification policy

Cross-platform source support is continuously represented in `.github/workflows/platform-smoke.yml`:

- Android debug APK on Ubuntu;
- Linux debug application on Ubuntu;
- Windows portable debug application plus MSIX packaging smoke on Windows;
- macOS debug application on macOS;
- unsigned iOS debug compilation on macOS.

The main CI workflow builds Web and runs the Linux integration journey. Tagged releases continue to build the release artifact set; the Windows release job also verifies that MSIX packaging succeeds.

A workflow existing in source is not proof that it has passed. Release claims must still wait for observed successful executions.

## Manual release verification

Before making a platform-specific public delivery claim, test a release candidate on that platform and record:

1. permission prompt behavior;
2. timer completion while Countora is foregrounded;
3. timer completion while Countora is backgrounded/suspended where the target supports scheduled delivery;
4. Linux/Web/portable-Windows runtime fallback behavior;
5. Web **Allow** permission action, denial, re-entry, and representative browser behavior;
6. sound on/off;
7. vibration behavior where the OS/browser exposes it;
8. quiet mode;
9. pause/resume schedule replacement;
10. add-time/restart schedule replacement;
11. multi-step interval scheduling/runtime fallback;
12. app-resume reconciliation after one or more elapsed intervals;
13. notification-disable cancellation behavior;
14. Android exact-alarm denial fallback;
15. reboot/app-update rescheduling where applicable;
16. packaged Windows scheduling/cancellation and portable Windows runtime fallback;
17. iOS foreground presentation after generated AppDelegate patching.

Countora cannot override OS focus/do-not-disturb policy, browser lifecycle rules, battery restrictions, vendor background restrictions, signing limitations, or notification-server capabilities.

## Automated coverage

Relevant tests include:

- `test/platform_capabilities_test.dart`
- `test/notification_initialization_test.dart`
- `test/notification_details_test.dart`
- `test/notification_cleanup_test.dart`
- `test/runtime_notification_policy_test.dart`
- `test/web_notification_permission_test.dart`
- `test/timer_controller_test.dart`
- `test/timer_controller_workflows_test.dart`
- `test/timer_controller_resilience_test.dart`
- `test/settings_page_test.dart`
- `test/platform_patches_test.dart`
- `test/version_audit_test.dart`

These tests protect capability decisions, permission boundaries, adapter configuration, runner patching, version synchronization, ordering rules, Settings presentation, and failure containment. They do not replace real operating-system/browser verification.
