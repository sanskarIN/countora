# Countora development handoff

Updated: 2026-08-20
Current milestone: Phase 6 cross-platform release-candidate verification
Target release: 0.2.0+2
Repository: https://github.com/sanskarIN/countora
Source model: public / open source / MIT
Primary implementation: Flutter + Dart

## Continuity contract

Countora follows `12_countora_master_prompt.md` and is being developed as a production-oriented, local-first, secure, accessible, documented multi-countdown timer.

Continue the existing repository instead of replacing working code. Keep changes small and meaningful, prefer Conventional Commit-style messages, keep this handoff current, and do not fabricate passing builds, tests, screenshots, native notification behavior, signing evidence, or release artifacts.

The requested commit email remains `sanskarin@outlook.in`. GitHub connector writes use the authenticated repository identity when the connector action does not expose custom Git author metadata.

## Supported application platforms

Countora source now intentionally supports all six primary Flutter deployment families from one application codebase:

1. Android
2. iOS
3. Windows
4. macOS
5. Linux
6. Web

Core product behavior is shared across all six targets:

- multiple simultaneous countdowns;
- pause, resume, restart, add-time, duplicate, edit, and delete workflows;
- presets and usage tracking;
- groups, search, and filtering;
- multi-step interval sequences;
- completion history and replay;
- local-first persistence;
- schema-aware bounded backup/restore;
- responsive Material 3 UI;
- light/dark/system themes;
- reduced motion and accessibility semantics;
- Settings/About/support surfaces;
- localization-ready UI architecture;
- app-resume timer reconciliation.

Platform-specific functionality is represented as an explicit capability rather than pretending every OS/browser exposes identical APIs.

## Cross-platform notification delivery model

`lib/src/core/platform_capabilities.dart` now defines three notification delivery modes:

- `NotificationDeliveryMode.scheduledBackground`
- `NotificationDeliveryMode.runtimeOnly`
- `NotificationDeliveryMode.unavailable`

Current policy:

| Platform | Delivery mode | Behavior |
| --- | --- | --- |
| Android | scheduledBackground | Native future scheduling; exact alarms fall back to inexact scheduling when required |
| iOS | scheduledBackground | Native Darwin future scheduling |
| macOS | scheduledBackground | Native Darwin future scheduling |
| Windows | scheduledBackground | Native Windows future toast scheduling |
| Linux | runtimeOnly | Desktop notification while Countora remains running; timer state still reconciles after resume/restart |
| Web | runtimeOnly | Browser notification while the page/runtime remains active; timer state still reconciles after page return/reload |
| Fuchsia/unknown unsupported target | unavailable | Fail closed |

This distinction is important. Linux notification servers and browser notification APIs do not provide Countora with the same guaranteed future scheduling mechanism as Android/iOS/macOS/Windows. Countora therefore supports those application targets fully while using a runtime notification fallback instead of making a false background-delivery claim.

## Cross-platform notification implementation added on 2026-08-20

### Capability layer

`lib/src/core/platform_capabilities.dart` now provides:

- `notificationDeliveryMode()`
- `supportsLocalNotifications()`
- `supportsScheduledNotifications()`
- `usesRuntimeNotificationFallback()`

Web is classified before `defaultTargetPlatform`, so Web behavior is deterministic regardless of browser host platform. Unsupported native targets continue to fail closed.

### Platform notification initialization

`countoraNotificationInitializationSettings()` configures:

- Android notification initialization;
- iOS Darwin initialization;
- macOS Darwin initialization;
- Linux initialization;
- Windows initialization;
- Web initialization.

Apple permission prompts remain deferred instead of appearing automatically during adapter startup.

### Platform presentation details

`countoraNotificationDetails()` now provides notification details for all six supported application targets:

- Android cue-profile channels, sound, vibration, and alarm category;
- iOS/macOS alert and sound presentation;
- Linux normal urgency and quiet-mode sound suppression;
- Windows default audio or explicit silent audio in quiet mode;
- Web browser notification `isSilent` behavior.

### Web permissions

When notification delivery is first needed, the production adapter resolves `WebFlutterLocalNotificationsPlugin` and requests notification permission when permission is not already granted.

Browser user-activation policy still controls whether the permission prompt is accepted or allowed. This must be verified in representative real browsers before release.

### Linux/Web runtime notification fallback

`LocalNotificationService` now keeps an in-process runtime timer for the current timer/interval deadline on `runtimeOnly` targets.

The fallback:

- replaces the runtime timer when a timer is restarted, extended, paused/resumed, or progresses to another interval;
- shows a local Linux/browser notification when the deadline fires while Countora remains active;
- preserves normal controller reconciliation and persistence behavior;
- cancels pending runtime timers when the user pauses/deletes/disables notification behavior before the deadline;
- does not call unsupported future-scheduling APIs on Linux/Web.

### Exact-deadline race hardening

A race was identified during this continuation: the controller's periodic reconciliation could reach completion cleanup at the same deadline before the runtime notification timer callback, causing the notification callback to be cancelled.

The runtime scheduler now stores `_RuntimeNotificationEntry` records with their UTC deadline and delivery callback. When cancellation races a notification that is already due, the due callback is preserved instead of cancelled. Replacement logic uses identity checks so an older due callback cannot remove a newer runtime timer entry for the same Countora timer.

On runtime-only targets, controller cleanup does not dismiss an already-delivered local completion notification merely because state reconciliation also completed.

## Settings behavior

`SettingsPage` now treats local notification availability separately from future scheduling capability.

On Android/iOS/macOS/Windows:

- completion-notification controls are available;
- scheduled-background help text is shown;
- sound/vibration/quiet preferences remain available when notifications are enabled.

On Linux/Web:

- completion-notification controls remain available instead of being disabled;
- sound/vibration/quiet preferences remain editable where the target honors them;
- the UI explains that future background scheduling is not available;
- the UI explains that local completion notifications work while the runtime remains active;
- in-app completion state and visual cues continue to reconcile when returning to Countora.

Unsupported future targets still have notification controls disabled.

## Cross-platform CI/build coverage

A new `.github/workflows/platform-smoke.yml` workflow was added.

It runs on pushes to `main`, pull requests targeting `main`, and manual dispatch.

Jobs:

### Android

Ubuntu runner:

- localization-source audit;
- generated runner bootstrap;
- dependency resolution;
- localization generation;
- `flutter build apk --debug`.

### Linux

Ubuntu runner with GTK/Linux build dependencies:

- localization-source audit;
- generated runner bootstrap;
- dependency resolution;
- localization generation;
- `flutter build linux --debug`.

### Windows

Windows runner:

- localization-source audit;
- generated runner bootstrap;
- dependency resolution;
- localization generation;
- `flutter build windows --debug`.

### macOS + iOS

macOS runner:

- localization-source audit;
- generated runner bootstrap;
- dependency resolution;
- localization generation;
- `flutter build macos --debug`;
- `flutter build ios --debug --no-codesign`.

### Web

Web remains covered by the main `.github/workflows/ci.yml` release-mode Web build.

The main CI workflow also runs Flutter analyze/tests and the Linux/Xvfb integration journey.

The existence of these workflows does **not** mean they have been observed passing. Real GitHub Actions results remain release evidence that must be checked.

## Regression coverage added/updated

### `test/platform_capabilities_test.dart`

Covers:

- Web runtime-only behavior independent of host target;
- Linux runtime-only behavior;
- Android/iOS/macOS/Windows scheduled-background behavior;
- unsupported native target fail-closed behavior;
- local-notification and scheduled-notification helpers.

### `test/notification_initialization_test.dart`

Existing coverage protects initialization settings for Android, iOS, macOS, Linux, Windows, and Web plus deferred Apple permission prompts.

### `test/notification_details_test.dart`

New coverage verifies:

- all six `NotificationDetails` platform fields are configured;
- normal sound/vibration presentation values;
- quiet mode suppresses controllable sound/vibration properties across platform implementations.

### `test/settings_page_test.dart`

Updated coverage verifies:

- Linux notification controls remain available;
- Linux runtime-only explanatory copy is shown;
- notification settings can be enabled on Linux;
- sound/vibration/quiet controls become available;
- unsupported Fuchsia behavior remains fail closed.

### `test/localization_test.dart`

Updated to verify the new runtime-fallback explanatory copy.

### Repository contract

`tool/check_required_files.dart` now protects:

- `test/notification_details_test.dart`;
- `test/notification_initialization_test.dart`;
- `test/settings_page_test.dart`;
- `.github/workflows/platform-smoke.yml`;
- existing critical source/tests/docs/workflows/tooling.

## Documentation synchronized

Updated during this cross-platform continuation:

- `README.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `docs/notification-support.md`
- `docs/testing.md`
- `lib/l10n/app_en.arb`
- this `what_changed.md`

README now presents Android, iOS, Windows, macOS, Linux, and Web as intentional Countora application targets while accurately qualifying Linux/Web notification limitations.

## Existing reliability/security work retained

The cross-platform changes build on prior repository hardening rather than replacing it.

Still implemented:

- schema-aware bounded state codec;
- future-schema rejection;
- legacy migration support;
- explicit imported identifier limits;
- malformed backup/type handling;
- local corruption recovery;
- controller collection limits aligned with persistence limits;
- monotonic runtime clock;
- app-resume reconciliation;
- interval catch-up without accumulated wake-up drift;
- persistence-before-platform-side-effect ordering;
- failed-import rollback;
- notification cleanup continuation after individual cancellation failures;
- Android exact-to-inexact fallback;
- generated Android permission/receiver/desugaring/multidex patches;
- recursive structured-log redaction;
- guarded external links and clipboard export;
- responsive error surfaces in Home and Settings;
- deterministic localization audit;
- repository required-file/version/secret/link audits;
- Dependency Review and CodeQL workflow source;
- multi-platform release workflow with SHA-256 artifact digests;
- integration journey source;
- benchmark harness;
- accessibility documentation and semantics regressions.

## Current release blockers — do not mark complete without evidence

The following remain unverified in this chat environment:

1. Generate dependencies with a real supported Flutter SDK, review them, and commit the application `pubspec.lock`.
2. Run/observe `dart run tool/check_dependency_lock.dart` against that committed lockfile.
3. Observe successful main CI localization/format/analyze/test/docs/Web/Linux-integration jobs.
4. Observe successful `Platform smoke` builds for Android, Linux, Windows, macOS, and unsigned iOS.
5. Fix every concrete compiler/analyzer/test/workflow issue returned by those real runs.
6. Verify Android notification permission, background completion, exact-alarm denial fallback, sound/vibration/quiet behavior on a real device/emulator.
7. Verify iOS notification behavior in a supported signed/device environment.
8. Verify macOS notification behavior and eventual signed/notarized distribution path.
9. Verify Windows toast behavior in a representative release-like environment.
10. Verify Linux desktop notification runtime fallback and resume/restart reconciliation.
11. Verify Web notification permission/runtime delivery in representative browsers, including browser user-activation restrictions.
12. Confirm Linux/Web documentation continues to state that future notification delivery cannot be guaranteed after process/page termination.
13. Run benchmark measurements on representative hardware and record environment/results.
14. Complete manual accessibility review with a real screen reader, keyboard-only navigation, scaled text, dark/light/system themes, and reduced motion.
15. Capture real screenshots from verified builds only.
16. Validate production signing/notarization/store-distribution paths.
17. Run the final clean-checkout repository/release audit.
18. Do not finalize the 0.2.0 changelog date or create `v0.2.0` until required evidence is green.

## Dependency-lock status

`pubspec.lock` remains intentionally absent until a supported Flutter SDK performs real dependency resolution and the result is reviewed.

The tagged release workflow already checks for a committed valid-looking dependency lock **before** its own `flutter pub get`, preventing a release tag from silently resolving an unreviewed dependency graph and treating it as release evidence.

Do not fabricate a lockfile.

## Recent cross-platform commits

- `74bfa14` feat: model cross-platform notification delivery tiers
- `084777e` test: cover cross-platform notification capability tiers
- `7e8ad24` feat: add Linux and web runtime notification fallback
- `628a813` feat: enable notification controls across supported platforms
- `7ef9685` docs: explain runtime notification fallback in app copy
- `4a56ca4` test: enable Linux runtime notification settings
- `026ee86` test: cover cross-platform notification presentation details
- `f29dc7c` ci: add cross-platform build smoke matrix
- `f9f010e` chore: protect cross-platform support regressions
- `28093fd` docs: define six-platform notification support policy
- `6866277` test: update runtime notification fallback copy
- `6e41c29` docs: document full six-platform Countora support
- `bdcc912` docs: record six-platform support hardening
- `0ef3e38` docs: make six-platform verification explicit
- `383c8aa` docs: expand cross-platform test strategy
- `ba24b33` fix: preserve due runtime completion notifications
- current handoff commit: docs: hand off full cross-platform support work

## Next exact work

1. Use a clean checkout with Flutter `>=3.38.1` and compatible Dart.
2. Run `dart run tool/bootstrap_platforms.dart`.
3. Run `flutter pub get`, inspect the dependency resolution, then commit the reviewed `pubspec.lock`.
4. Run repository/version/dependency/localization/secret/link checks.
5. Run `flutter gen-l10n`.
6. Run `dart format --output=none --set-exit-if-changed lib test integration_test tool`.
7. Run `flutter analyze` and `flutter test`.
8. Run/observe the Linux integration journey.
9. Observe every `Platform smoke` job and fix any platform-specific compiler/build issue.
10. Test notification behavior on real/representative Android, Apple, Windows, Linux, and Web environments.
11. Record actual verification results here.
12. Only after all required release evidence is green, finalize the 0.2.0 changelog and release process.
