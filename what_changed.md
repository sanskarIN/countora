# Countora development handoff

Updated: 2026-08-19
Current milestone: 0.2.0 source hardening and documentation complete; final executable/native release verification pending
Target release: 0.2.0+2
Repository: https://github.com/sanskarIN/countora
Source model: public / open source / MIT
Verification branch: `final-audit-2026-08-19`

## Source prompt and project contract

Implementation follows `12_countora_master_prompt.md`: Countora is a production-oriented, local-first, secure, accessible, documented Flutter countdown application for Android, iOS-ready source, Windows, macOS, Linux, and Web. The repository should preserve meaningful granular history, keep user data local unless explicitly exported, avoid secrets, document behavior and release limits, and never claim successful runtime/build verification that has not actually been observed.

This file is the detailed development handoff so chat messages can remain short.

## Current product implementation

### Countdown engine

Implemented:

- multiple simultaneous countdown timers
- absolute UTC deadlines for running timers
- monotonic process-lifetime runtime clock anchored to UTC
- pause, resume, restart, add-time, delete, duplicate
- bulk pause-all, resume-all, remove-completed
- deadline reconciliation on startup/resume/manual reconciliation
- multi-step interval sequences
- catch-up through elapsed interval steps without accumulating wake-up drift
- timer groups, search, filtering, and status counts
- full-screen focus mode
- compact card mode
- local completion history
- run-again from history
- save existing timer as preset
- preset usage-frequency tracking

### Deadline-boundary hardening completed in the final audit

A running timer previously could be paused after its deadline had already arrived and become a paused `0s` timer until a later resume/reconcile action. The final audit changed pause semantics so lifecycle state wins over the pause command at that boundary:

- `pause(timerId)` now checks the actual remaining `Duration` before converting to paused state;
- an already-expired running timer is reconciled/advanced/completed first;
- positive fractional seconds are rounded **up** when persisted as paused whole seconds instead of being truncated;
- `pauseAllRunning()` reconciles already-expired timers first, persists/synchronizes those lifecycle changes, then pauses timers that are still active;
- deterministic tests cover exact-deadline pause, positive fractional remaining time, and mixed expired/active bulk pause.

Relevant final commits:

- `4902dcc` — `fix: reconcile timer deadlines before pausing`
- `23cfeb3` — `test: cover timer pause deadline boundaries`

## Persistence, backup, and local-data safety

Implemented:

- `CountoraStateCodec` as the persistence/import trust boundary
- explicit schema version ownership in the codec
- migration of legacy unversioned state to schema 1
- rejection of unsupported future schema versions
- 2 MiB backup limit
- bounded timer/preset/history entity counts
- 32 interval-step maximum per timer/preset
- bounded names, groups, durations, remaining time, and use counts
- malformed-field type rejection through controlled `FormatException`
- duplicate-ID filtering
- malformed interval recovery
- safe corrupted-local-state fallback
- SharedPreferences save/load/clear adapter
- import preview before destructive replacement
- staged/reconciled import before platform schedule replacement
- failed-import persistence rollback to previous in-memory state
- full local-data reset
- history-only clearing
- JSON export
- privacy-safe backup inspection CLI
- deterministic malformed-input/fuzz-style state-codec tests
- deterministic codec benchmark harness

Persistence-dependent notification side effects follow durable-state-first ordering documented by ADR 0005.

## Notification implementation

### Capability policy

Future scheduled completion is explicitly enabled in source only for:

- Android
- iOS
- macOS
- Windows

It fails closed for:

- Web
- Linux
- Fuchsia
- unknown/unapproved future targets

Unsupported scheduling targets keep local timer state, foreground countdowns, history, completion state, and resume reconciliation.

### Android

Implemented:

- generated boot receiver configuration
- `RECEIVE_BOOT_COMPLETED`
- exact-alarm scheduling setup
- core-library desugaring
- multidex setup
- validated/idempotent Android template patch helpers
- explicit failure when expected Flutter template anchors drift
- notification permission request
- exact-alarm permission request
- exact scheduling with inexact allow-while-idle fallback
- schedule cancellation/replacement after durable state changes

Final audit fix: Android notification channels are persistent configuration, so Countora no longer reuses one channel ID while asking it to behave as contradictory sound/vibration profiles. Four stable profiles now exist:

- sound + vibration
- sound only
- vibration only
- silent / quiet

Relevant final commits:

- `e2d8d4b` — `fix: use stable Android channels per cue profile`
- `eae606f` — `test: cover Android notification cue channels`

### iOS/macOS

Final audit fix: Darwin notification initialization defaults can request permission during plugin initialization. Countora now creates explicit Darwin initialization settings with alert/badge/sound permission requests disabled at initialization. The controller's explicit notification-permission path remains responsible for requesting permission when future scheduling is first needed.

Relevant final commits:

- `b78f226` — `fix: defer Apple notification permission prompts`
- `a90fd29` — `test: verify deferred Apple notification permissions`

Native delivery behavior still requires real Apple/Android/Windows platform verification before stronger public claims are made.

## User experience and management

Implemented:

- responsive phone/tablet/desktop/web layout
- Material 3 theme
- light/dark/system appearance
- reduced motion
- reusable design tokens
- onboarding
- Home/Timers, Presets, History, Settings, About surfaces
- timer create/edit validation
- interval labels
- interval rename/remove/reorder
- group creation/filtering
- search
- focus mode
- timer/preset delete confirmation
- bulk actions
- backup preview/import/reset UI
- Settings capability messaging
- About metadata/support/privacy/license links
- Buy Me a Coffee link
- `Made by the Sanskar` credit

## Accessibility and keyboard support

Implemented:

- timer/progress semantics
- focus-mode live-region semantics
- corrected focus-mode entry/exit semantic copy
- visual progress cues independent of audio
- reduced-motion setting
- keyboard-accessible Flutter controls
- desktop/web shortcuts:
  - `Ctrl/Cmd + N`
  - `Ctrl/Cmd + F`
  - `Ctrl/Cmd + ,`
- Settings/accessibility widget regression coverage

A final manual screen-reader, keyboard-only, large-text, and real-device review remains a release-environment requirement.

## Localization

Implemented:

- generated Flutter `gen_l10n` architecture
- `l10n.yaml`
- `lib/l10n/app_en.arb`
- localized Home/navigation/timer/focus/editor/Settings/data/About/support copy
- localization context helper
- generated delegates/locales wired into the app
- localization tests
- deterministic committed-source/reference auditor at `tool/check_localization_source.dart`
- pure audit logic in `tool/src/localization_audit.dart`
- audit regression tests

Final audit found the localization-source checker existed but was not actually enforced by workflows. It is now part of:

- normal Flutter CI
- repository audit workflow
- tagged release quality gate

Relevant branch commits:

- `adb6227` — `ci: enforce localization source audit`
- `d4f3788` — `ci: add localization audit to repository checks`
- `3348bcb` — `ci: gate releases on localization audit`

English is currently the shipped locale; additional locales can be added through ARB resources without rewriting the main UI.

## Release/version safety

Final audit added a pure release version audit in `tool/src/version_audit.dart` and refactored `tool/check_version_sync.dart` around it.

The audit now checks:

- `pubspec.yaml` uses `MAJOR.MINOR.PATCH+BUILD`;
- `AppMetadata.version` matches the semantic version;
- `AppMetadata.buildNumber` matches the build number;
- `CHANGELOG.md` contains an exact semantic-version heading;
- when GitHub Actions is running a tag, the tag must equal `vMAJOR.MINOR.PATCH`;
- a tagged release is rejected while its matching changelog section is still marked `Unreleased`.

This intentionally prevents tagging the current `0.2.0` release candidate until the release entry is finalized after actual verification.

Relevant commits:

- `2e0ef85` — `build: add pure release version audit`
- `e1314e1` — `test: cover release version and tag audit`
- `5cdf39a` — `build: verify release tag matches package version`
- `a9676bf` — `build: block tags with unreleased changelog entries`
- `15ce009` — `build: match changelog release headings exactly`
- `b202c2e` — `test: reject unreleased changelog tags`

## Toolchain declaration

`pubspec.yaml` now explicitly declares:

- Flutter `>=3.38.1`
- Dart `>=3.10.0 <4.0.0`

This makes the framework baseline visible to package tooling and contributors instead of relying only on prose.

Relevant commit:

- `06c64ca` — `build: declare minimum supported Flutter SDK`

## Testing inventory

Current automated source includes coverage for:

- domain models
- state codec round trips/migrations/bounds/malformed types
- deterministic malformed-input/fuzz cases
- local persistence/corruption recovery
- monotonic clock
- timer controller lifecycle/workflows
- persistence/notification consistency failures
- timer pause/deadline boundaries
- notification initialization policy
- Android notification cue-profile channels
- platform notification capability policy
- Android generated-runner patch helpers
- external-link failure containment
- backup inspection summaries
- localization audit
- release version audit
- Home/timer widget journeys
- Settings/destructive/clipboard/accessibility behavior
- keyboard shortcuts
- generated localization resources
- primary integration journey

`integration_test/app_journey_test.dart` covers a primary create → pause → save-as-preset → run-from-preset journey.

## Repository tools

Current deterministic tools include:

- `tool/bootstrap_platforms.dart`
- `tool/check_required_files.dart`
- `tool/check_version_sync.dart`
- `tool/check_secrets.dart`
- `tool/check_localization_source.dart`
- `tool/check_markdown_links.dart`
- `tool/inspect_backup.dart`
- `tool/benchmark_state_codec.dart`

Pure helpers under `tool/src/` include:

- `backup_inspection.dart`
- `localization_audit.dart`
- `platform_patches.dart`
- `version_audit.dart`

## CI, security, and release automation

Implemented workflow/source hardening includes:

- normal CI on main/pull requests
- deterministic platform runner bootstrap
- dependency resolution
- localization source audit and generation
- formatting verification including `integration_test/`
- `flutter analyze`
- `flutter test`
- local Markdown-link audit
- Web release build
- dedicated Linux/Xvfb integration journey job
- repository audit workflow
- required-file audit
- version/tag/changelog audit
- tracked-source obvious-secret audit
- localization-source audit
- documentation-link audit
- Dependency Review with moderate-or-higher threshold
- Dependabot configuration
- CodeQL scan for supported GitHub Actions workflow source
- tagged release quality gate
- Android APK/AAB build
- Web ZIP build
- Linux x64 package
- Windows x64 ZIP
- macOS application ZIP
- unsigned iOS application ZIP for compilation verification
- SHA-256 checksum files for tagged artifacts

Signing, notarization, store credentials, and real platform/device notification verification remain intentionally outside source control.

## Documentation status

The documentation set has been deeply expanded and synchronized. Important references include:

- `README.md`
- `CHANGELOG.md`
- `ROADMAP.md`
- `PRIVACY.md`
- `SECURITY.md`
- `SUPPORT.md`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `docs/architecture.md`
- `docs/setup.md`
- `docs/development.md`
- `docs/testing.md`
- `docs/release.md`
- `docs/troubleshooting.md`
- `docs/accessibility.md`
- `docs/performance.md`
- `docs/backup-format.md`
- `docs/notification-support.md`
- `docs/cli-tools.md`
- `docs/github.md`
- `docs/branding.md`
- `docs/adr/`

Final documentation refresh commits on the verification branch:

- `f01c641` — `docs: align setup with supported Flutter baseline`
- `ca9bd37` — `docs: document notification permission and channel behavior`
- `8c0524f` — `docs: document release version audit behavior`
- `a2dc985` — `docs: expand final regression test inventory`
- `9d0a715` — `docs: harden final release procedure`
- `b082fa4` — `docs: refresh Countora project overview`
- `571c204` — `docs: close implemented 0.2 hardening items`
- `80fb53e` — `docs: record final 0.2 hardening fixes`

## Verification status

### Verified by source/repository inspection

- The repository is public and the inspected default branch is `main`.
- The current development metadata is `0.2.0+2`.
- The final source changes are committed as granular commits rather than one giant rewrite.
- The final timer-controller fix diff was inspected after write and was limited to the intended pause/reconciliation changes.
- The notification plugin's source API was checked for the Darwin initialization permission fields used by Countora.
- The repository source includes complete normal CI, repository-audit, security, integration, and multi-platform tagged-release workflows.
- Documentation has been updated to distinguish implemented source from unverified native behavior.
- No signing credentials, production secrets, private keys, or fabricated screenshots were added.

### Not yet claimed as successfully executed

The direct execution environment used for this continuation does not expose a runnable local Flutter/Dart toolchain, so local commands are **not** being falsely reported as passing.

Until an actual workflow or compatible release host result is observed, do not claim success for:

- `dart format --output=none --set-exit-if-changed ...`
- `flutter analyze`
- `flutter test`
- Linux integration execution
- `flutter build web --release`
- Android APK/AAB release builds
- Linux/Windows/macOS builds
- unsigned iOS compilation
- native notification delivery behavior
- production signing/notarization

A pull-request verification pass is being used to surface real GitHub Actions results for the final tree where available. Any concrete compiler/test/workflow failure that can be retrieved must be fixed before merging/tagging.

## Deliberate release blockers / external verification work

These are not missing source features; they require a compatible real environment or release credentials:

1. observe the final CI/repository-audit/Linux-integration results;
2. fix any concrete analyzer/test/build failures found by those runs;
3. run the integration journey on a configured target outside CI as part of the release record;
4. generate/review `pubspec.lock` using a real supported Flutter SDK and commit it if the application release policy requires locking dependencies;
5. run the codec benchmark on representative hardware and record the environment/results;
6. verify Android notification permission, exact/inexact fallback, cue channels, background completion, reboot/update behavior on a real emulator/device;
7. verify Windows/macOS/iOS notification behavior before strengthening platform delivery claims;
8. verify at least one desktop release artifact on its native runner;
9. perform the final manual accessibility review;
10. capture real release-candidate screenshots;
11. validate production signing/notarization/store distribution paths;
12. replace `## [0.2.0] - Unreleased release candidate` with the actual release date only after verification;
13. create `v0.2.0` only after the release commit is verified.

## 0.2.0 release candidate summary

### Added

- validated versioned local backup/migration boundary
- privacy-safe backup inspection CLI
- deterministic codec benchmark
- timer duplicate/edit/save-as-preset/history-replay workflows
- bulk timer actions
- richer interval editor and focus mode
- desktop shortcuts
- structured redacting diagnostics
- monotonic runtime clock and resume reconciliation
- generated English localization architecture
- deterministic localization audit
- explicit platform notification capability policy
- release version/tag/changelog audit
- expanded controller/widget/tool/integration regression coverage
- repository audit and multi-platform release automation

### Changed

- persistence is validated/bounded before accepting imported/local JSON
- platform notification side effects follow successful durable persistence
- expired pause boundaries reconcile instead of freezing at zero
- fractional seconds are rounded up when pausing
- Apple notification permissions are deferred until scheduling is needed
- Android cue profiles use separate stable channels
- Android exact scheduling has inexact fallback
- unknown notification targets fail closed
- the package declares its minimum supported Flutter version
- localization source checking is enforced by CI/repository/release workflows
- release tags must match package version and a finalized changelog entry

### Security/privacy

- bounded untrusted JSON parsing
- corruption-safe persistence recovery
- sensitive structured-log key redaction
- obvious tracked-secret audit
- Dependency Review threshold
- CodeQL workflow scan
- artifact SHA-256 digests
- local-first/no-account behavior preserved

## Final checkpoint rule

Source work for 0.2 is considered implemented and documented at this checkpoint. Do **not** mark 0.2.0 as a verified public release solely because source work is complete. The final release decision must be based on observed CI/build/native results, dependency resolution, manual platform/accessibility checks, and a finalized changelog/tag.
