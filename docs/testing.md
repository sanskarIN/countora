# Testing

Countora treats timing, persistence, backup parsing, and destructive data workflows as high-regression-risk areas. Tests are deterministic by default and use injected clocks, in-memory stores, and fake notification adapters instead of production credentials or network services.

## Test layers

### Domain tests

`test/models_test.dart` covers timer-model behavior such as serialization, remaining-time calculation, negative-time clamping, and malformed-state recovery.

### State codec and persistence tests

`test/state_codec_test.dart` covers:

- supported-state round trips
- legacy unversioned migration
- future-schema rejection
- non-object backup rejection
- malformed field-type rejection
- duplicate-ID handling
- invalid interval recovery
- configured name/group/use-count bounds

`test/local_store_test.dart` covers:

- SharedPreferences save/restore
- corrupted persisted JSON recovery
- invalid persisted field recovery
- explicit clear behavior

### Clock and controller tests

`test/stable_clock_test.dart` verifies the monotonic clock anchor behavior without using real elapsed time.

`test/timer_controller_test.dart` and `test/timer_controller_workflows_test.dart` cover timer creation, persistence, pause/resume, interval rollover, notification behavior, duplication, editing, bulk controls, imports, reset, and history reuse.

### Widget tests

`test/home_page_test.dart` covers primary timer presentation, accessible semantics, filtered empty states, resume controls, and history replay.

`test/localization_test.dart` verifies English localization generation/delegate behavior.

### Integration journey

`integration_test/app_journey_test.dart` exercises a primary user journey:

1. launch Countora with deterministic local fakes
2. create a timer
3. pause it
4. save it as a preset
5. start another timer from that preset

This source belongs in the repository even when a current CI runner is not configured with a device/window target capable of executing it reliably.

## Standard local quality suite

Generate localization first:

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
flutter test integration_test/app_journey_test.dart
```

Depending on the host, a device selector or desktop target may be required.

## CI expectations

`.github/workflows/ci.yml` performs:

1. checkout
2. Flutter setup
3. deterministic platform-runner generation
4. dependency resolution
5. localization generation
6. formatting verification
7. `flutter analyze`
8. `flutter test`
9. local Markdown-link verification
10. Web release build

Any failure blocks the CI job. A release must not be described as verified until a real workflow execution has been observed as successful.

## Native-platform verification

Pure Dart/widget tests cannot fully prove OS notification behavior. Before a stable release, manually verify on supported platforms where applicable:

- notification permission prompts
- completion notification delivery while app is backgrounded
- sound/vibration/quiet-mode behavior
- reboot/rescheduling behavior on Android
- exact-alarm denied fallback behavior
- pause/resume after suspension
- app-resume reconciliation
- keyboard shortcuts and focus traversal on desktop/web
- screen-reader labels and live-region behavior

## Regression rule

Every fixed defect that can be reproduced deterministically should gain the smallest useful regression test before or with the fix.
