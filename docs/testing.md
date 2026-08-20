# Testing

Countora treats timing, persistence, backup parsing, notification synchronization, platform capability decisions, structured diagnostics, external-link handling, and destructive data workflows as high-regression-risk areas. Tests are deterministic by default and use injected clocks, in-memory stores, fake notification adapters, and injectable platform boundaries instead of production credentials or network services.

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

`test/platform_capabilities_test.dart` verifies Countora's explicit future-notification policy: Web and Linux are unsupported by the current scheduled-notification adapter while Android, iOS, macOS, and Windows use their native adapter paths.

`test/platform_patches_test.dart` verifies generated Android runner transforms for required notification permissions/receivers, desugaring, multidex, idempotence, and explicit template-drift failure.

`test/notification_cleanup_test.dart` verifies that a failure cancelling one derived interval notification does not prevent cleanup attempts for the remaining bounded notification IDs.

### Widget tests

`test/home_page_test.dart` covers primary timer presentation, accessible semantics, the focus-mode entry hint, filtered empty states, resume controls, and history replay.

`test/settings_page_test.dart` covers Settings sections, reduced-motion persistence, destructive reset confirmation, and clipboard-backup failure feedback.

`test/keyboard_shortcuts_test.dart` covers the primary desktop keyboard shortcuts.

`test/localization_test.dart` verifies English localization generation/delegate behavior, including distinct focus-mode entry/exit semantics and supported/unsupported notification explanatory copy.

### Integration journey

`integration_test/app_journey_test.dart` exercises a primary user journey:

1. launch Countora with deterministic local fakes
2. create a timer
3. pause it
4. save it as a preset
5. start another timer from that preset

CI has a dedicated Linux integration job that installs the required GTK build dependencies plus Xvfb, validates committed localization references, generates Countora's platform runners/localization source, and executes the integration suite against the Linux desktop target in a virtual display.

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

Validate committed localization references before generated source can hide a stale ARB/reference mismatch:

```bash
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
4. deterministic platform-runner generation
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

Any failure blocks its CI job. A release must not be described as verified until real workflow executions have been observed as successful.

## Native-platform verification

Automated Dart/widget/Linux integration tests cannot fully prove OS notification behavior on every platform. Before a stable release, manually verify on supported platforms where applicable:

- notification permission prompts
- completion notification delivery while app is backgrounded
- sound/vibration/quiet-mode behavior
- cleanup/replacement of multi-step notification schedules
- reboot/rescheduling behavior on Android
- exact-alarm denied fallback behavior
- pause/resume after suspension
- app-resume reconciliation
- keyboard shortcuts and focus traversal on desktop/web
- screen-reader labels and live-region behavior
- Settings capability messaging on targets without scheduled background notification support

## Regression rule

Every fixed defect that can be reproduced deterministically should gain the smallest useful regression test before or with the fix.
