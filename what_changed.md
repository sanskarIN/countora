# Countora development handoff

Updated: 2026-08-20
Current milestone: Phase 6 cross-platform release-candidate verification
Target release: 0.2.0+2
Repository: https://github.com/sanskarIN/countora
Source model: public / open source / MIT
Primary implementation: Flutter + Dart

## Continuity contract

Countora follows `12_countora_master_prompt.md` and is being developed as a production-oriented, local-first, secure, accessible, documented multi-countdown timer.

Continue the existing repository instead of replacing working code. Keep changes small and meaningful, prefer Conventional Commit-style messages, keep this handoff current, and do not fabricate passing builds, tests, screenshots, native notification behavior, signing evidence, package-store evidence, or release artifacts.

The requested commit email remains `sanskarin@outlook.in`. GitHub connector writes use the authenticated repository identity when the connector action does not expose custom Git author metadata.

## Current cross-platform status

Countora source now intentionally supports all six primary Flutter deployment families from one application codebase:

1. Android
2. iOS
3. Windows
4. macOS
5. Linux
6. Web

Shared product behavior across all six platform families includes:

- multiple simultaneous countdown timers;
- start, pause, resume, restart, add-time, duplicate, edit, and delete workflows;
- bulk pause-all, resume-all, and remove-completed workflows;
- presets and local usage tracking;
- groups, search, and filtering;
- multi-step interval sequences with custom labels and ordering;
- local completion history and replay;
- local-first persistence;
- schema-aware, bounded backup/restore;
- corruption recovery;
- absolute UTC deadline persistence;
- monotonic in-process runtime clock;
- app-resume/startup reconciliation;
- responsive Material 3 UI;
- light, dark, and system themes;
- reduced motion and accessibility semantics;
- desktop keyboard shortcuts;
- Settings/About/privacy/support surfaces;
- generated-localization architecture;
- structured redacting diagnostics;
- guarded external links/clipboard operations.

Cross-platform support does **not** mean pretending every operating system, browser, or packaging mode exposes identical APIs. Countora now models those differences explicitly and provides the safest useful fallback for each target.

## Notification capability architecture

`lib/src/core/platform_capabilities.dart` is the notification-delivery capability source of truth.

It defines:

```text
NotificationDeliveryMode.scheduledBackground
NotificationDeliveryMode.runtimeOnly
NotificationDeliveryMode.unavailable
```

It also exposes:

- `notificationDeliveryMode()`;
- `supportsLocalNotifications()`;
- `supportsScheduledNotifications()`;
- `usesRuntimeNotificationFallback()`.

Current behavior:

| Platform / distribution | Delivery mode | Countora behavior |
| --- | --- | --- |
| Android | scheduledBackground | Native future scheduling; exact scheduling falls back to inexact when exact alarms cannot be used |
| iOS | scheduledBackground | Native Darwin future scheduling; generated AppDelegate receives required notification-center delegate setup |
| macOS | scheduledBackground | Native Darwin future scheduling |
| Windows portable ZIP | runtimeOnly | Local Windows notifications while Countora remains active; no unsafe dependency on package-identity-only cancellation APIs |
| Windows MSIX/package identity | scheduledBackground | Future Windows scheduling enabled through `COUNTORA_WINDOWS_PACKAGED=true` |
| Linux | runtimeOnly | Linux desktop notifications while the Countora process remains active |
| Web | runtimeOnly | Browser notifications while the page/runtime remains active, after explicit browser permission grant |
| Fuchsia/unknown unsupported native target | unavailable | Fail closed |

The Windows decision is intentionally distribution-aware. The notification plugin can display notifications without package identity, but reliable retrieval/cancellation of previous Windows notifications depends on package identity. Countora therefore does not use future-scheduling semantics in a normal portable ZIP build.

## Runtime notification fallback

`LocalNotificationService` now provides a runtime completion-notification path for Linux, Web, and portable Windows builds.

The fallback stores an in-process timer for the current countdown/interval deadline.

Behavior:

- starting/resuming a timer establishes a runtime completion callback;
- extending/restarting/reconciling a timer replaces the associated callback;
- pausing/deleting/disabling notifications cancels pending callbacks before their deadline;
- after an interval advances, the next current interval receives a fresh callback;
- when a deadline fires while Countora remains alive, the platform/browser local notification is shown;
- timer correctness remains driven by persisted UTC deadlines and controller reconciliation rather than by the notification timer.

This does not claim that Linux, a browser page, or a portable Windows process can notify after that runtime has been terminated.

### Exact-deadline race hardening

A real lifecycle race was found during this cross-platform work: the controller ticker can reconcile a completed timer at the same deadline before the runtime notification `Timer` callback gets its event-loop turn.

The fallback now stores `_RuntimeNotificationEntry` values with the UTC deadline and delivery callback.

`shouldPreserveDueRuntimeNotification()` returns true at/after the deadline. Cleanup preserves a due callback instead of cancelling it merely because controller reconciliation won the event-loop race.

The callback uses identity checks before removing its runtime-map entry so an older due callback cannot accidentally delete a newer replacement for the same timer ID.

`test/runtime_notification_policy_test.dart` protects:

- before-deadline cancellation;
- exact-deadline preservation;
- after-deadline preservation;
- timezone normalization.

## Cross-platform notification presentation

`countoraNotificationDetails()` now configures every supported notification adapter:

- Android — stable cue-profile channel, high importance/priority, alarm category, sound/vibration flags;
- iOS — Darwin alert/sound presentation;
- macOS — Darwin alert/sound presentation;
- Linux — normal urgency and quiet-mode sound suppression;
- Windows — normal audio or explicit silent audio;
- Web — `isSilent` behavior following Countora sound/quiet preferences.

`test/notification_details_test.dart` protects the six-target configuration and quiet-mode behavior.

## Web notification permission boundary

Web required special handling because browsers require notification permission to originate directly from user activation.

Countora no longer asks Web for notification permission inside `LocalNotificationService.requestPermissions()`.

That automatic method remains responsible for the native permission paths where appropriate:

- Android notification/exact-alarm permission;
- iOS notification permission;
- macOS notification permission.

### New explicit Web boundary

Created:

```text
lib/src/data/web_notification_permission.dart
```

It exposes:

```text
requestWebNotificationPermissionFromUserGesture()
```

The helper:

- returns immediately on non-Web targets;
- resolves `WebFlutterLocalNotificationsPlugin` only on Web;
- recognizes already-granted permission;
- otherwise requests browser permission;
- returns a safe boolean result;
- has an injectable request function for deterministic tests.

### Web Settings action

`SettingsPage` now renders, only on Web:

```text
Browser notification permission
Allow
```

The **Allow** button invokes the browser permission helper directly from the button action.

Startup, persistence, controller reconciliation, scheduled timer callbacks, and other automatic lifecycle paths never request Web notification permission.

If permission is denied, Countora still keeps timers, persistence, history, reconciliation, and visual/in-app completion cues working.

`test/web_notification_permission_test.dart` protects:

- non-Web no-op behavior;
- one direct Web request;
- denial returning safely.

`test/localization_test.dart` now also protects the browser-permission copy and the updated runtime-only notification explanation.

## Windows portable vs MSIX support

Windows now has two intentional distribution modes.

### Portable Windows

Normal:

```text
flutter build windows
```

leaves:

```text
COUNTORA_WINDOWS_PACKAGED=false
```

and Countora uses `runtimeOnly` notification delivery.

The portable release ZIP remains a supported Countora application build and retains every core timer/data/UI capability.

### Package-identity Windows

`pubspec.yaml` now includes `msix: ^3.18.0` and `msix_config`.

Current MSIX configuration includes:

```text
display_name: Countora
publisher_display_name: Sanskar
identity_name: dev.sanskar.countora
msix_version: 0.2.0.2
windows_build_args: --dart-define=COUNTORA_WINDOWS_PACKAGED=true
install_certificate: false
```

The MSIX build therefore rebuilds Countora with package identity enabled and selects `scheduledBackground` Windows delivery.

### Windows package version audit

`tool/src/version_audit.dart` now checks the Windows MSIX four-part version whenever `msix_config` exists.

Mapping rule:

```text
Flutter package: MAJOR.MINOR.PATCH+BUILD
Windows MSIX:    MAJOR.MINOR.PATCH.BUILD
```

For the current candidate:

```text
0.2.0+2 -> 0.2.0.2
```

`test/version_audit_test.dart` covers:

- synchronized MSIX metadata;
- drift rejection;
- missing `msix_version` rejection;
- existing package/AppMetadata/changelog/tag checks.

### MSIX signing boundary

CI now verifies that MSIX/package-identity creation works, but Countora does **not** present a development/self-signed MSIX as a production-signed artifact.

A trusted production certificate or Microsoft Store distribution/signing strategy remains required before the packaged Windows build is promoted publicly.

The portable ZIP remains the currently published Windows CI/release artifact while MSIX production signing is unresolved.

## Native runner generation and platform hardening

Countora intentionally regenerates native Flutter runners through:

```text
dart run tool/bootstrap_platforms.dart
```

The command generates:

- Android;
- iOS;
- Web;
- Windows;
- macOS;
- Linux.

It then applies deterministic native patches from `tool/src/platform_patches.dart`.

### Android runner hardening

The bootstrap ensures generated Android source contains:

- `RECEIVE_BOOT_COMPLETED`;
- `SCHEDULE_EXACT_ALARM`;
- `ScheduledNotificationReceiver`;
- `ScheduledNotificationBootReceiver`;
- core-library desugaring;
- multidex;
- desugar JDK libs dependency;
- Android Plugin DSL AGP floor of 8.11.1.

`patchAndroidSettingsGradle()`:

- finds the generated `com.android.application` Plugin DSL declaration;
- raises versions below 8.11.1;
- leaves newer versions untouched;
- fails explicitly if the expected Flutter template declaration disappears.

The declared Flutter baseline is `>=3.38.1`. Flutter 3.38.1 already generates Gradle 8.14, AGP 8.11.1, and compileSdk 36, so the AGP transform is a defensive floor/no-op on that supported baseline rather than a forced change.

### iOS runner hardening

`patchIosAppDelegate()` now:

- verifies the expected generated Swift template anchors;
- adds `import UserNotifications`;
- adds `UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate` before generated plugin registration;
- remains idempotent;
- fails explicitly if Flutter changes the expected AppDelegate template.

This protects foreground local-notification presentation setup instead of relying on an undocumented manual post-generation step.

### Native patch regression coverage

`test/platform_patches_test.dart` now covers:

- Android manifest patching;
- Android Gradle desugaring/multidex patching;
- Android AGP floor behavior;
- preservation of newer AGP versions;
- idempotence;
- explicit template-drift failure;
- iOS UserNotifications/delegate patching;
- iOS idempotence;
- iOS template-drift failure.

## Cross-platform CI and release verification source

### Main CI

`.github/workflows/ci.yml` continues to provide the main Flutter quality job and Linux integration job.

It includes:

- stable Flutter setup;
- localization-source validation;
- native runner generation/patching;
- dependency resolution;
- localization generation;
- formatting verification;
- `flutter analyze`;
- `flutter test`;
- Markdown-link checking;
- Web release build;
- Linux/Xvfb integration journey.

### New Platform smoke workflow

Added:

```text
.github/workflows/platform-smoke.yml
```

It runs on `main`, pull requests targeting `main`, and manual dispatch.

Jobs:

#### Android / Ubuntu

- localization audit;
- generated runners;
- dependencies;
- localization;
- debug APK build.

#### Linux / Ubuntu

- Linux build dependencies;
- localization audit;
- generated runners;
- dependencies;
- localization;
- debug Linux build.

#### Windows / Windows runner

- version/MSIX metadata audit;
- localization audit;
- generated runners;
- dependencies;
- localization;
- portable Windows debug build;
- MSIX package-identity debug creation.

#### Apple / macOS runner

- localization audit;
- generated runners;
- dependencies;
- localization;
- macOS debug build;
- unsigned iOS debug compilation.

Web remains covered by the main CI release-mode Web build.

### Tagged release workflow

The existing tagged release workflow remains gated by repository/version/dependency/localization/secret/test/build checks.

Its Windows job now:

1. builds the portable Windows release;
2. archives the portable ZIP;
3. verifies MSIX/package-identity creation;
4. publishes the portable ZIP/checksum only.

This verifies both Windows code paths while keeping production MSIX signing outside CI source until an approved signing/store configuration exists.

## Repository contract additions

`tool/check_required_files.dart` now protects the new cross-platform assets, including:

- `lib/src/data/web_notification_permission.dart`;
- `test/web_notification_permission_test.dart`;
- `test/runtime_notification_policy_test.dart`;
- `test/notification_details_test.dart`;
- `test/notification_initialization_test.dart`;
- cross-platform Settings/capability tests;
- `.github/workflows/platform-smoke.yml`;
- existing critical repository/release/source/test/documentation tooling.

A future deletion of these important support boundaries will therefore fail the deterministic repository contract.

## Existing reliability/security work retained

The cross-platform work builds on, and does not replace, the existing Countora hardening:

- schema-aware bounded state codec;
- future-schema rejection;
- legacy state migration;
- explicit imported identifier length limits;
- malformed backup/type rejection;
- safe corrupted-state recovery;
- controller timer/preset collection capacity limits;
- monotonic runtime clock;
- startup/resume reconciliation;
- interval catch-up using prior deadlines;
- guarded non-overlapping ticker execution;
- persistence-before-platform-side-effect ordering;
- failed-import rollback;
- bounded notification cleanup that continues after per-ID plugin failures;
- stable Android cue-profile channels;
- recursive structured diagnostic redaction;
- deterministic localization-source auditing;
- release-only dependency-lock auditing;
- required-file/version/secret/link repository checks;
- Dependency Review threshold;
- CodeQL workflow scan;
- SHA-256 tagged artifact digests;
- responsive Home/Settings error surfaces;
- accessibility and localization architecture;
- deterministic state-codec benchmark harness.

## Current documentation status

Cross-platform behavior has been synchronized in:

- `README.md`;
- `CHANGELOG.md`;
- `ROADMAP.md`;
- `docs/setup.md`;
- `docs/testing.md`;
- `docs/release.md`;
- `docs/notification-support.md`;
- `lib/l10n/app_en.arb`;
- this `what_changed.md` handoff.

The documentation distinguishes:

- supported application platform family;
- scheduled vs runtime notification capability;
- portable vs package-identity Windows behavior;
- CI package verification vs production signing;
- source implementation vs actually observed release evidence.

## Current dependency-lock status

`pubspec.lock` is still absent from the repository.

This is deliberate, not complete.

The cross-platform work added a new dev dependency (`msix`), so a real supported Flutter SDK must now perform dependency resolution again before release.

Required release sequence:

1. clean checkout with supported Flutter SDK;
2. `dart run tool/bootstrap_platforms.dart`;
3. `flutter pub get`;
4. review the resolved dependency graph;
5. commit the generated application `pubspec.lock`;
6. run `dart run tool/check_dependency_lock.dart` from that committed checkout.

Do not fabricate or hand-write `pubspec.lock`.

The tagged release workflow already runs the dependency-lock audit before its own `flutter pub get`, preventing a release tag from silently resolving a fresh graph and treating it as reviewed source.

## Verification status

### Verified by repository/source inspection and completed GitHub writes

- Countora source intentionally targets Android, iOS, Windows, macOS, Linux, and Web.
- Native runner bootstrap targets all six platform families.
- Notification capability logic distinguishes scheduled/runtime/unavailable modes.
- Windows capability distinguishes portable vs package-identity builds.
- Linux/Web/portable-Windows runtime fallback source is present.
- Runtime deadline-race hardening is present.
- Web notification permission is isolated behind a direct Settings user action.
- Automatic native notification permission code deliberately excludes Web.
- Six-platform notification presentation configuration is present.
- Android manifest/Gradle/AGP hardening source is present.
- iOS AppDelegate notification delegate patch source is present.
- Windows MSIX packaging metadata and package-identity Dart define are present.
- Version auditing protects MSIX version synchronization.
- Platform smoke workflow source is present.
- Tagged release workflow verifies Windows MSIX package creation without publishing it as a production-signed artifact.
- Required-file contract protects the new critical cross-platform source/tests/workflow.
- Cross-platform documentation is synchronized.

### Not truthfully verified in this chat environment

No local working Flutter/Dart toolchain run has been observed here, and no completed green GitHub Actions result has yet been used as release evidence for these direct-push changes.

Therefore the following are **not claimed as passing** yet:

- generated `pubspec.lock` resolution;
- dependency-lock audit against a committed generated lock;
- `dart format --output=none --set-exit-if-changed lib test integration_test tool`;
- `flutter analyze`;
- `flutter test`;
- Linux/Xvfb integration journey;
- Web release build;
- Android debug/release build after the latest native changes;
- Linux debug/release build after the latest changes;
- portable Windows build after the latest changes;
- Windows MSIX creation after the latest changes;
- macOS build after the latest changes;
- unsigned iOS compilation after the latest changes;
- real Android notification permission/background/exact-alarm behavior;
- real iOS foreground/background notification behavior;
- real macOS notification behavior;
- real Linux runtime notification behavior;
- real Web permission/runtime notification behavior in representative browsers;
- real portable Windows runtime notification behavior;
- real installed package-identity Windows scheduling/cancellation behavior;
- production MSIX signing/store distribution;
- Apple signing/notarization/store distribution;
- Android store signing;
- manual accessibility review;
- representative benchmark results;
- real application screenshots.

## Remaining release blockers

1. Generate/review/commit `pubspec.lock` with the supported Flutter SDK.
2. Run/observe all deterministic repository/version/dependency/localization/secret/link checks from a clean checkout.
3. Run/observe formatter, analyzer, and Flutter tests.
4. Observe successful main CI Web + Linux integration jobs.
5. Observe successful `Platform smoke` Android/Linux/Windows portable/Windows MSIX/macOS/iOS jobs.
6. Fix every concrete compiler/analyzer/test/workflow issue returned by those real executions.
7. Verify Android notification permission, background completion, exact-alarm denial fallback, cue combinations, and reboot/app-update behavior on representative devices/emulators.
8. Verify iOS foreground/background notification behavior in a signed/device-capable Apple environment.
9. Verify macOS notification behavior on a representative release-like build.
10. Verify portable Windows runtime fallback.
11. Verify installed package-identity Windows scheduled delivery and cancellation.
12. Choose and validate a trusted MSIX signing or Microsoft Store distribution strategy before publishing the MSIX path.
13. Verify Linux runtime local notification delivery and persisted-state reconciliation.
14. Verify Web **Browser notification permission → Allow** behavior, denial, runtime completion notification delivery, and page lifecycle behavior in representative browsers.
15. Keep Linux/Web/portable-Windows documentation explicit that runtime-only delivery is not a guarantee after the process/page is gone.
16. Complete manual accessibility review with screen reader, keyboard-only navigation, scaled text, reduced motion, and themes.
17. Run and record the deterministic benchmark on representative hardware.
18. Capture only real screenshots from verified builds.
19. Validate final signing/notarization/store distribution paths.
20. Run the final clean-checkout release audit.
21. Only after required evidence is green, finalize the dated 0.2.0 changelog entry and create the release tag.

## Recent cross-platform commits

### Web permission and final consistency

- `4ded3c8` feat: add user-initiated web notification permission boundary
- `17163cd` fix: avoid automatic browser permission prompts
- `02a2799` test: cover user-initiated web notification permission boundary
- `0451f25` feat: add explicit browser notification permission action
- `cdcecc8` feat: localize browser notification permission action
- `060cfc0` test: cover browser notification permission copy
- `386551d` chore: protect Web permission boundary regressions
- `55325a6` docs: require direct Web notification permission action
- `14ea7be` docs: cover browser permission boundary tests
- `ca4777f` docs: record direct Web notification permission flow
- `b30fdcb` docs: track direct browser permission boundary

### Android/iOS/Windows native/package hardening

- `6a584b3` build: patch generated iOS notification delegate
- `8ed1c27` build: configure generated iOS notifications
- `6cbd6d9` test: cover generated iOS notification patch
- `1d43f36` build: add Windows MSIX packaging support
- `6fd95c2` fix: make Windows scheduling package-identity aware
- `c3a5b68` test: cover packaged and portable Windows notification modes
- `4c71d61` build: enable packaged Windows notification mode in MSIX
- `04a8b50` build: keep MSIX version synchronized
- `3db0d41` test: cover Windows MSIX version synchronization
- `137c6fe` ci: verify Windows package identity build
- `a4c4394` ci: verify Windows MSIX packaging on releases
- `8d58e60` build: enforce notification-compatible Android AGP
- `6948e35` build: patch generated Android AGP settings
- `9f5fe05` test: cover Android AGP bootstrap hardening
- `dd6f36c` ci: validate Windows package version before MSIX smoke

### Initial six-platform notification architecture

- `74bfa14` feat: model cross-platform notification delivery tiers
- `084777e` test: cover cross-platform notification capability tiers
- `a08abdc` feat: support local notifications across all Flutter targets
- `7e8ad24` feat: add Linux and web runtime notification fallback
- `628a813` feat: enable notification controls across supported platforms
- `4a56ca4` test: enable Linux runtime notification settings
- `026ee86` test: cover cross-platform notification presentation details
- `f29dc7c` ci: add cross-platform build smoke matrix
- `f9f010e` chore: protect cross-platform support regressions
- `ba24b33` fix: preserve due runtime completion notifications
- `c55ae43` testable: expose runtime notification deadline policy
- `3abb4f2` test: protect runtime notification deadline race policy
- `5bffc4d` chore: require runtime notification race regression

## Next exact work

On a clean checkout with Flutter `>=3.38.1` and compatible Dart:

1. run `dart run tool/bootstrap_platforms.dart`;
2. run `flutter pub get`;
3. inspect dependency changes including the new `msix` development dependency;
4. commit the reviewed `pubspec.lock`;
5. run `dart run tool/check_required_files.dart`;
6. run `dart run tool/check_version_sync.dart`;
7. run `dart run tool/check_dependency_lock.dart`;
8. run `dart run tool/check_secrets.dart`;
9. run `dart run tool/check_localization_source.dart`;
10. run `dart run tool/check_markdown_links.dart`;
11. run `flutter gen-l10n`;
12. run `dart format --output=none --set-exit-if-changed lib test integration_test tool`;
13. run `flutter analyze`;
14. run `flutter test`;
15. run/observe Linux integration tests;
16. observe each Platform smoke job;
17. fix every real toolchain failure with a regression where practical;
18. manually verify platform notification/device/browser behavior;
19. update this file with actual evidence;
20. complete signing/distribution/accessibility/screenshots/benchmark work;
21. only then finalize and tag 0.2.0.
