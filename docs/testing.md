# Testing

Countora treats timing, persistence, backup parsing, notification synchronization, cross-platform capability decisions, native runner patching, packaging metadata, structured diagnostics, external-link handling, and destructive data workflows as high-regression-risk areas. Tests are deterministic by default and use injected clocks, in-memory stores, fake notification adapters, and injectable platform boundaries instead of production credentials or network services.

## Test layers

### Domain tests

`test/models_test.dart` covers timer-model behavior such as serialization, remaining-time calculation, negative-time clamping, and malformed-state recovery.

### State codec and persistence tests

`test/state_codec_test.dart` covers:

- supported-state round trips
- codec-owned schema stamping
- domain serialization remaining schema-agnostic
- legacy unversioned migration
- future-schema rejection
- non-object backup rejection
- malformed field-type rejection
- duplicate-ID handling
- invalid interval recovery
- configured identifier/name/group/use-count bounds

`test/state_codec_fuzz_test.dart` adds deterministic malformed-input/fuzz-style regression coverage around the backup trust boundary.

`test/local_store_test.dart` covers:

- SharedPreferences save/restore
- corrupted persisted JSON recovery
- invalid persisted field recovery
- explicit clear behavior

### Clock and controller tests

`test/stable_clock_test.dart` verifies the monotonic clock anchor behavior without using real elapsed time.

`test/timer_controller_test.dart` and `test/timer_controller_workflows_test.dart` cover timer creation, persistence, pause/resume, interval rollover, notification behavior, duplication, editing, bulk controls, imports, reset, and history reuse.

`test/timer_controller_limits_test.dart` verifies that live timer/preset creation respects the same collection caps as persistence decoding and that a full timer collection does not increment preset usage without creating a timer.

`test/timer_controller_resilience_test.dart` specifically covers recoverable infrastructure failures, including:

- save failures surfaced without escaping normal UI-facing operations
- no notification scheduling after a failed timer persistence attempt
- no notification cancellation after failed pause/removal persistence
- no notification side effects after failed notification-settings persistence
- no reconciliation notification side effects when the reconciled state cannot be saved
- failed backup-import persistence restoring the previous in-memory state
- local-store clear failure preserving current in-memory state

### Security/diagnostic tests

`test/app_logger_test.dart` verifies structured diagnostic sanitization across nested generic maps and iterables, sensitive-key normalization, enum conversion, and bounded arbitrary scalar text.

The logger regression deliberately uses synthetic credential-like strings. It must never contain real secrets or user backups.

### Platform-boundary tests

`test/external_link_launcher_test.dart` verifies that successful, declined, and throwing URL-launch operations are converted into a safe boolean result instead of allowing platform failures to escape into the widget tree.

`test/platform_capabilities_test.dart` verifies Countora's notification delivery tiers:

- Android, iOS, and macOS use `scheduledBackground` delivery;
- Linux and Web use `runtimeOnly` local-notification delivery;
- portable Windows uses `runtimeOnly` without package identity;
- packaged Windows uses `scheduledBackground` when `windowsPackaged`/`COUNTORA_WINDOWS_PACKAGED` is true;
- unsupported native targets such as Fuchsia fail closed with `unavailable`.

`test/notification_initialization_test.dart` verifies that notification initialization includes Android, iOS, macOS, Linux, Windows, and Web adapters while Apple permission prompts remain deferred until notification delivery is actually needed.

`test/notification_details_test.dart` verifies cross-platform presentation details for all six supported targets and checks quiet-mode suppression for the platform properties Countora controls.

`test/notification_cleanup_test.dart` verifies that a failure cancelling one derived interval notification does not prevent cleanup attempts for the remaining bounded notification IDs.

`test/runtime_notification_policy_test.dart` verifies that Countora preserves a runtime notification callback at/after its delivery deadline while still cancelling callbacks that are genuinely early. This protects Linux/Web/portable-Windows completion delivery from an exact-deadline race with controller reconciliation.

### Native runner patch tests

`test/platform_patches_test.dart` verifies generated native transforms:

- Android scheduling permissions and receivers;
- Android core-library desugaring;
- Android multidex;
- Android Plugin DSL AGP floor (`8.11.1`) with newer-version preservation;
- Android patch idempotence and explicit template-drift failure;
- iOS `UserNotifications` import;
- iOS notification-center delegate installation before plugin registration;
- iOS patch idempotence and explicit template-drift failure.

The declared Flutter baseline, 3.38.1, already generates Gradle 8.14, AGP 8.11.1, and compileSdk 36. The AGP transform is therefore a defensive floor on the supported baseline, not a forced downgrade/upgrade during normal generation.

### Version and Windows packaging tests

`test/version_audit_test.dart` protects synchronization between:

- `pubspec.yaml` `MAJOR.MINOR.PATCH+BUILD`;
- `AppMetadata` version/build values;
- matching changelog release headings;
- release tags;
- Windows `msix_version` in `MAJOR.MINOR.PATCH.BUILD` form whenever `msix_config` exists.

For example, package `0.2.0+2` requires MSIX `0.2.0.2`.

### Widget tests

`test/home_page_test.dart` covers primary timer presentation, accessible semantics, the focus-mode entry hint, filtered empty states, resume controls, and history replay.

`test/home_error_banner_test.dart` verifies recoverable controller failures remain visible and dismissible after navigating away from the Timers destination, including the Presets surface.

`test/settings_page_test.dart` covers Settings sections, reduced-motion persistence, destructive reset confirmation, clipboard-backup failure feedback, runtime-notification controls, and fail-closed notification controls on unsupported targets.

`test/settings_reactivity_test.dart` verifies the pushed Settings route listens to controller changes and surfaces controller persistence failures without requiring navigation back to Home.

`test/keyboard_shortcuts_test.dart` covers the primary desktop keyboard shortcuts.

`test/localization_test.dart` verifies English localization generation/delegate behavior, including distinct focus-mode entry/exit semantics and the scheduled-vs-runtime notification explanatory copy.

### Integration journey

`integration_test/app_journey_test.dart` exercises a primary user journey:

1. launch Countora with deterministic local fakes
2. create a timer
3. pause it
4. save it as a preset
5. start another timer from that preset

CI has a dedicated Linux integration job that installs the required GTK build dependencies plus Xvfb, validates committed localization references, generates Countora's platform runners/localization source, and executes the integration suite against the Linux desktop target in a virtual display.

## Cross-platform build smoke coverage

`.github/workflows/platform-smoke.yml` exists to catch platform compilation/packaging drift before a release tag is created.

It verifies:

- Android debug APK on Ubuntu;
- Linux debug application on Ubuntu;
- portable Windows debug application on Windows;
- Windows MSIX package-identity creation on Windows;
- macOS debug application on macOS;
- unsigned iOS debug application on macOS.

The Windows job runs `tool/check_version_sync.dart` before packaging so stale MSIX version metadata cannot silently reach the packaging step.

Web compilation remains part of `.github/workflows/ci.yml` as a release-mode Web build.

Each platform-smoke job performs localization-source validation, deterministic runner generation, dependency resolution, localization generation, and a host-appropriate build. Windows additionally exercises both portable and package-identity distribution modes.

The existence of this workflow is source coverage only. A platform must not be described as build-verified until its actual workflow result has been observed as successful.

## Performance measurement

The deterministic codec benchmark harness is not a correctness test and intentionally has no universal wall-clock pass/fail threshold.

Run:

```bash
dart run tool/benchmark_state_codec.dart
```

or:

```bash
dart run tool/benchmark_state_codec.dart --iterations 500
```

The harness verifies every encode/decode round trip and emits JSON with fixture size plus minimum, p50, p95, and maximum encode/decode microseconds. See [`performance.md`](performance.md) for the measurement policy and required environment metadata.

## Standard local quality suite

Validate version/package metadata and committed localization references:

```bash
dart run tool/check_version_sync.dart
dart run tool/check_localization_source.dart
```

Generate localization:

```bash
flutter gen-l10n
```

Verify formatting:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test tool
```

Run analysis and normal automated tests:

```bash
flutter analyze
flutter test
```

Optional coverage:

```bash
flutter test --coverage
```

Check local Markdown references:

```bash
dart run tool/check_markdown_links.dart
```

Run the integration journey on a configured Flutter target:

```bash
flutter test integration_test -d linux -r github
```

On a headless Linux host, provide a display such as Xvfb. The repository CI uses:

```bash
xvfb-run -a flutter test integration_test -d linux -r github
```

A different explicit device selector can be used when validating another supported target.

## CI expectations

`.github/workflows/ci.yml` contains two complementary jobs.

The main Flutter quality job performs:

1. checkout
2. Flutter setup
3. deterministic localization-source/reference validation
4. deterministic platform-runner generation and native patching
5. dependency resolution
6. localization generation
7. formatting verification
8. `flutter analyze`
9. `flutter test`
10. local Markdown-link verification
11. Web release build

The Linux integration job performs:

1. checkout and Flutter setup
2. installation of GTK/Linux build dependencies and Xvfb
3. deterministic localization-source/reference validation
4. deterministic platform-runner generation
5. dependency resolution and localization generation
6. the full `integration_test` directory against `-d linux`

`.github/workflows/platform-smoke.yml` independently compiles/packages the remaining native target families on matching GitHub-hosted operating systems.

Any failure blocks its CI job. A release must not be described as verified until real workflow executions have been observed as successful.

## Native and browser verification

Automated Dart/widget/build-smoke/Linux integration tests cannot fully prove OS/browser notification behavior. Before a stable release, manually verify on supported targets where applicable:

- notification permission prompts;
- completion notification delivery while Countora is foregrounded;
- completion notification delivery while app is backgrounded on scheduled-delivery targets;
- iOS foreground notification presentation after generated AppDelegate patching;
- Linux runtime notification delivery while Countora remains active;
- Web notification permission and runtime delivery in representative browsers;
- portable Windows runtime notification delivery;
- installed package-identity Windows scheduling/cancellation;
- Linux/Web/portable-Windows reconciliation after process/page/runtime interruption;
- explicit absence of guaranteed future delivery after runtime termination for runtime-only modes;
- sound/vibration/quiet-mode behavior where the platform exposes those controls;
- cleanup/replacement of multi-step notification schedules/runtime timers;
- reboot/rescheduling behavior on Android;
- exact-alarm denied fallback behavior;
- pause/resume after suspension;
- app-resume reconciliation;
- keyboard shortcuts and focus traversal on desktop/Web;
- screen-reader labels and live-region behavior;
- Settings capability messaging for scheduled and runtime-only targets.

## Regression rule

Every fixed defect that can be reproduced deterministically should gain the smallest useful regression test before or with the fix.
