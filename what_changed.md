# Countora development handoff

Updated: 2026-08-20
Current milestone: Phase 6 release-candidate verification; static source, test, documentation, repository-governance, and release-workflow hardening are substantially complete
Target release: 0.2.0+2
Repository: https://github.com/sanskarIN/countora
Source model: public / open source / MIT
Primary implementation: Flutter + Dart

## Source prompt and continuity contract

Implementation follows `12_countora_master_prompt.md`: build Countora as a production-quality, local-first, secure, accessible, documented Flutter countdown timer for Android, iOS-ready, Windows, macOS, Linux, and Web.

The project continuity rules remain:

- inspect and continue the existing repository rather than replacing working code;
- preserve useful history and backward compatibility where reasonable;
- use small, meaningful, Conventional Commit-style commits;
- use `sanskarin@outlook.in` as the requested commit email;
- keep `what_changed.md` current so another chat can resume without reconstructing completed work;
- do not fabricate successful verification, screenshots, dependency metadata, native behavior, or release artifacts;
- do not tag a release while concrete analyzer/test/build/device blockers remain.

## Current product implementation

### Core countdown workflows

The repository contains source for:

- multiple simultaneous countdown timers;
- start, pause, resume, restart, add-time, and delete controls;
- reusable presets with local usage-frequency tracking;
- named timer groups;
- timer search and filtering;
- interval sequences with multiple timed steps;
- custom interval-step labels;
- interval-step rename, remove, move-up, and move-down controls;
- local completion history;
- replay from history as a fresh timer;
- timer duplication as a fresh paused countdown;
- timer name/group editing without resetting countdown progress;
- save-existing-timer-as-preset;
- bulk pause-all, resume-all, and remove-completed actions;
- full-screen focus mode with pause/resume/restart/add-time controls;
- interval progress in focus mode;
- compact timer cards for denser layouts;
- local running/paused/completed count summaries.

### Timing and lifecycle reliability

Implemented reliability work includes:

- persisted UTC completion instants rather than decrementing stored values every second;
- an in-process monotonic runtime clock anchored to UTC so wall-clock edits do not directly make active timers jump during the same process lifetime;
- non-overlapping asynchronous ticker execution;
- startup/app-resume timer reconciliation;
- interval catch-up after suspension;
- later interval steps anchored to prior deadlines to reduce accumulated wake-up drift;
- deadline reconciliation before pausing so an already-expired timer is not incorrectly frozen as still active;
- persistence-first ordering for timer state mutations before notification side effects;
- persistence-first timer reconciliation before schedule changes;
- failed-import rollback before replacing platform notification schedules;
- regression coverage for persistence/notification consistency boundaries.

### Local state, backup, migration, and corruption recovery

`lib/src/data/state_codec.dart` is the persistence/import trust boundary.

Implemented data-safety behavior includes:

- explicit state schema versioning;
- migration of supported legacy/unversioned state to the current schema;
- rejection of unknown future schema versions rather than guessing compatibility;
- bounded backup size;
- bounded timer, preset, history, and interval-step counts;
- bounded names, groups, interval durations, and remaining durations;
- malformed type rejection through controlled format failures;
- duplicate-ID handling;
- malformed-domain-data sanitization where safe;
- SharedPreferences persistence routed through the codec;
- corrupted persisted state recovery to a safe empty state instead of blocking startup;
- surfaced save/clear failures instead of silent failure;
- import validation before replacement;
- import preview showing timer/preset/history counts before destructive replacement;
- full local-data reset;
- history-only clearing;
- privacy-safe read-only backup inspection tooling;
- documented backup format and limits;
- synthetic non-personal backup fixtures for testing.

### Notifications and platform capability policy

Implemented notification work includes:

- local completion notification support on explicitly approved scheduling targets;
- a centralized scheduled-notification capability policy;
- fail-closed behavior for unsupported/unknown targets rather than assuming new platforms support scheduling;
- Web/Linux/Fuchsia/unknown future-target scheduling guards;
- Settings UI that explains unsupported background scheduling while preserving in-app completion behavior;
- notification permission request de-duplication per controller session;
- deferred Apple permission requests instead of prompting unnecessarily during adapter initialization;
- disabling notifications cancels active schedules after settings persistence succeeds;
- enabling notifications reschedules running timers after settings persistence succeeds;
- Android exact-alarm scheduling fallback to inexact scheduling when exact scheduling cannot be used;
- stable Android notification channels per cue profile so channel behavior does not drift with timer identity;
- generated Android manifest/Gradle hardening for notification receivers, exact-alarm permission, desugaring, and multidex;
- validated/idempotent Android generated-runner patch helpers that fail if expected Flutter template anchors disappear;
- regression tests for scheduled-notification capability, unsupported targets/settings state, Apple permission behavior, Android channel profiles, and generated runner patches.

### UI, responsive design, accessibility, and desktop usability

Implemented source includes:

- Material 3 UI;
- light, dark, and system themes;
- reduced-motion preference;
- reusable design tokens for spacing, radii, motion, touch targets, content width, and brand seed;
- responsive phone/tablet/desktop/web navigation;
- clear empty and filtered-empty states;
- one-click clear-filter behavior;
- visible controller error banner with dismiss action;
- keyboard-accessible standard Flutter controls/focus behavior;
- `Ctrl/Cmd+N` for creating a timer/preset;
- `Ctrl/Cmd+F` for returning to timers and focusing search;
- `Ctrl/Cmd+,` for opening Settings;
- timer and progress semantics;
- focus-mode live-region countdown semantics;
- non-audio progress cues;
- corrected focus-mode action semantics so the entry action announces **Open focus mode** rather than the inverse exit action;
- touch-friendly controls and responsive layouts;
- onboarding, Settings, About, privacy/data-management, appearance, accessibility, and support surfaces.

Manual screen-reader/scaled-text/reduced-motion verification on real targets remains a release requirement and is not claimed complete merely because semantics source/tests exist.

### Localization readiness

Implemented localization architecture includes:

- Flutter generated `gen_l10n` infrastructure;
- `flutter_localizations` and `intl` support;
- `l10n.yaml`;
- `lib/l10n/app_en.arb` as the English source of truth;
- generated localization delegates and supported locales wired into the application;
- a `BuildContext` localization helper;
- main Home/navigation/timer/focus/editor/Settings/data/About/support/accessibility/project copy externalized;
- deterministic localization-source audit tooling;
- regression tests for English resources and localization-source references.

English remains the only shipped locale for 0.2.0. Additional locales can be added through ARB resources without rewriting the main screens.

### Security and privacy hardening

Implemented safeguards include:

- local-first/no-account architecture;
- bounded validation of imported JSON;
- explicit schema/version trust boundary;
- structured JSON diagnostics with sensitive-key redaction;
- diagnostic events that avoid timer names, raw backup payloads, credentials, authentication data, and other unnecessary user content;
- guarded external URL launching with user-safe failure feedback;
- guarded clipboard backup export with localized failure feedback;
- tracked-source obvious-secret audit tooling;
- Dependency Review configured to fail newly introduced `moderate`-or-higher vulnerabilities on pull requests;
- CodeQL workflow analysis for supported GitHub Actions source;
- least-privilege workflow permissions where practical;
- no signing secrets, keystores, generated credentials, or production secrets intentionally committed;
- SHA-256 digest generation for tagged release artifacts;
- `SECURITY.md`, `PRIVACY.md`, responsible-disclosure guidance, and repository security-settings guidance.

### Performance work

Implemented performance/reliability support includes:

- absolute deadlines rather than persistent per-second writes;
- bounded persisted/imported collection sizes;
- interval catch-up rather than replaying every missed UI tick;
- deterministic state-codec benchmark harness;
- machine-readable latency summaries;
- documented benchmark procedure and explicit rule not to invent a universal hardware-independent CI threshold.

Benchmark execution on representative hardware remains a release-evidence task.

## Automated test and regression source now present

The repository includes coverage for the major domain, data, controller, UI, platform-boundary, and tooling areas, including:

### State and persistence

- `test/state_codec_test.dart`
  - round trip;
  - legacy schema migration;
  - future-schema rejection;
  - non-object rejection;
  - malformed type rejection;
  - duplicate ID handling;
  - malformed interval recovery;
  - name/group/use-count and other bounds.
- `test/local_store_test.dart`
  - persistence/restore;
  - corrupted JSON recovery;
  - invalid persisted-field recovery;
  - clear operation.
- state-codec malformed-input/property-style cases added during later hardening.
- privacy-safe backup inspection regression tests.

### Timing and controller workflows

- `test/stable_clock_test.dart`
  - monotonic elapsed-time behavior;
  - UTC normalization.
- `test/timer_controller_workflows_test.dart`
  - permission request de-duplication;
  - duplicate timer;
  - rename/group move;
  - bulk pause/resume;
  - import notification replacement behavior;
  - future-schema import preservation;
  - full-data reset;
  - history replay.
- controller resilience/persistence-first regression tests;
- timer pause/deadline boundary regression tests.

### UI/accessibility/localization

- `test/home_page_test.dart`
  - saved timer journey;
  - semantics exposure;
  - filtered empty state;
  - card resume;
  - history replay.
- focus-mode semantics regression coverage;
- Settings/platform-capability behavior coverage;
- `test/localization_test.dart`;
- localization source audit tests;
- external-link failure tests.

### Platform/repository/release tooling

- platform-capability policy tests;
- generated Android platform-patch tests;
- backup inspection tests;
- version/tag/changelog audit tests;
- release-changelog exact-heading and unreleased-tag rejection tests;
- dependency-lock audit tests added on 2026-08-20;
- deterministic required-file/version/secret/localization/link repository tooling.

### End-to-end source

`integration_test/app_journey_test.dart` covers the primary journey source for:

- create timer;
- pause timer;
- save as preset;
- start again from the saved preset.

CI source includes a dedicated Linux/Xvfb integration job. Actual execution success is still waiting for an observable real Flutter CI/toolchain run.

## CI and release automation currently implemented

### Main CI

`.github/workflows/ci.yml` is configured to:

- check out source;
- install stable Flutter;
- generate platform runners;
- resolve dependencies;
- generate localization sources;
- verify formatting for `lib`, `test`, `integration_test`, and `tool`;
- run `flutter analyze`;
- run `flutter test`;
- check local Markdown links;
- build Web in release mode;
- run the primary integration journey in a separate Linux/Xvfb job;
- cancel superseded in-progress CI for the same ref.

### Repository/security automation

The repository also contains:

- deterministic repository audit workflow;
- dependency-review workflow;
- CodeQL workflow for supported GitHub Actions source;
- Dependabot configuration;
- funding configuration;
- bug/feature/documentation issue templates;
- pull-request template;
- repository governance guidance for branch protection/rulesets, Discussions, labels, milestones, topics, merge policy, and security settings.

### Tagged release workflow

`.github/workflows/release.yml` is configured to build/publish after quality checks:

- Android release APK;
- Android release AAB;
- Web ZIP;
- Linux x64 tar.gz;
- Windows x64 ZIP;
- macOS application ZIP;
- unsigned iOS application ZIP for compilation verification;
- SHA-256 checksum files for the produced artifact groups.

The release quality job performs repository/version/secret/docs/test/build checks before artifact publication. Desktop/Apple jobs depend on the initial Android/Web quality job.

## New release-safety work completed on 2026-08-20

A remaining static release gap was identified: because `pubspec.lock` is not yet committed, a tagged release could otherwise run `flutter pub get` and resolve fresh dependency metadata inside CI. That would not prove that the exact release dependency graph had been generated with the supported SDK, reviewed, and committed.

This continuation added a release-only committed dependency-lock gate without fabricating a lockfile and without blocking ordinary development while runtime verification is unavailable.

### Added dependency-lock audit logic

Created `tool/src/dependency_lock_audit.dart`.

It rejects:

- missing `pubspec.lock`;
- empty `pubspec.lock`;
- a lockfile without a top-level `packages:` section;
- a lockfile without a top-level `sdks:` section.

The audit intentionally validates release evidence/presence/shape; it does not pretend to resolve dependencies itself.

### Added dependency-lock regression tests

Created `test/dependency_lock_audit_test.dart` covering:

- valid lockfile shape;
- missing lockfile;
- empty lockfile;
- missing `packages:` section;
- missing `sdks:` section.

### Added executable repository check

Created `tool/check_dependency_lock.dart`.

The command:

- reads the committed `pubspec.lock`;
- invokes the pure audit;
- prints every failure to stderr;
- exits non-zero on failure;
- reports success only after the file passes the basic generated-lock structure check.

### Hardened tagged release ordering

Updated `.github/workflows/release.yml` so the tagged release quality job now runs:

```text
dart run tool/check_dependency_lock.dart
```

**before** its own `flutter pub get` step.

This means a release tag cannot silently create the missing lockfile during CI and then treat that newly generated dependency graph as reviewed release source.

### Synchronized repository contracts/documentation

Updated:

- `tool/check_required_files.dart` to require the dependency-lock audit source, command, and regression test;
- `docs/release.md` with the reviewed application-lock policy and clean-checkout release sequence;
- `docs/cli-tools.md` with the new command/helper contract;
- `CHANGELOG.md` with the release dependency-lock gate and release blocker wording;
- `ROADMAP.md` to mark the static dependency-lock audit complete while keeping actual lock generation/review/commit unchecked.

No fabricated `pubspec.lock` was added.

## Other hardening completed since the previous handoff was last written

The previous handoff had become stale because several later 2026-08-19 commits were not yet reflected in it. Important completed work includes:

- persistence-first timer reconciliation and import behavior;
- centralized/fail-closed notification capability policy;
- unsupported scheduling-target Settings behavior;
- focus-mode semantics correction and regression coverage;
- deterministic state-codec benchmark harness;
- localization source audit tooling and regression coverage;
- privacy-safe backup inspection command and documentation;
- notification capability documentation;
- repository CLI tools reference;
- documentation issue template;
- release version/tag audit tooling;
- tagged-release tag-to-package-version verification;
- exact changelog release-heading matching;
- rejection of tags while the matching changelog entry remains unreleased;
- minimum supported Flutter SDK declaration;
- Apple notification permission deferral and regression coverage;
- stable Android cue-profile notification channels and regression coverage;
- pause-at-deadline reconciliation fix and boundary regression coverage;
- multi-platform tagged release packaging/checksum workflow source.

## Documentation status

The repository currently contains and maintains the master-prompt documentation set, including:

- `README.md`;
- `LICENSE`;
- `CONTRIBUTING.md`;
- `CODE_OF_CONDUCT.md`;
- `SECURITY.md`;
- `SUPPORT.md`;
- `PRIVACY.md`;
- `CHANGELOG.md`;
- `ROADMAP.md`;
- `what_changed.md`;
- `.gitignore`;
- `.editorconfig`;
- `.gitattributes`;
- `.env.example`;
- `docs/architecture.md`;
- `docs/setup.md`;
- `docs/development.md`;
- `docs/testing.md`;
- `docs/release.md`;
- `docs/troubleshooting.md`;
- `docs/accessibility.md`;
- `docs/performance.md`;
- `docs/github.md`;
- `docs/backup-format.md`;
- `docs/notification-support.md`;
- `docs/cli-tools.md`;
- branding documentation;
- architecture decision records under `docs/adr/`.

README already includes the product identity/value proposition, feature overview, platform matrix, tech stack, quick start, setup/testing/build instructions, architecture overview, security/privacy, contribution/license/support information, Buy Me a Coffee badge/link, and **Made by the Sanskar** credit.

Real screenshots remain intentionally absent until captured from an actual verified runnable release candidate; fake screenshots/mockups are not presented as product captures.

## Verification status

### Verified by repository inspection and completed GitHub writes

- Repository is `sanskarIN/countora` and remains public.
- Default branch is `main`.
- The authenticated connection has repository write/admin capability.
- Source, test, documentation, workflow, and tooling files referenced above were inspected after writes.
- `pubspec.yaml` currently declares `0.2.0+2` with Dart `>=3.10.0 <4.0.0` and Flutter `>=3.38.1`.
- `pubspec.lock` is currently absent; this is deliberately recorded as a release blocker instead of being fabricated.
- No open repository Issues were returned during this continuation.
- Repository code search returned no TODO/FIXME/XXX/HACK result during this continuation.
- The release workflow now checks for the committed dependency lock before dependency resolution.
- The release workflow source contains Android/Web/Linux/Windows/macOS/unsigned-iOS artifact jobs and checksum generation.
- The changelog, roadmap, release docs, CLI tools docs, and this handoff now describe the dependency-lock release policy consistently.
- Earlier continuity work explicitly checked the requested commit identity and recorded `Sanskar <sanskarin@outlook.in>` for author/committer metadata where exposed.

### Not truthfully verified in this chat environment

This execution environment does not expose a working Flutter/Dart SDK. The GitHub workflow-run lookup available during this continuation did not provide an observable completed run for these direct-push commits. Therefore the following are **not claimed as passing**:

- `dart run tool/check_required_files.dart` in a real Dart/Flutter checkout;
- `dart run tool/check_version_sync.dart` in a real Dart/Flutter checkout;
- `dart run tool/check_dependency_lock.dart` against a generated committed lockfile;
- `dart run tool/check_secrets.dart`;
- `dart run tool/check_localization_source.dart`;
- `dart run tool/check_markdown_links.dart`;
- `dart format --output=none --set-exit-if-changed lib test integration_test tool`;
- `flutter analyze`;
- `flutter test`;
- Linux/Xvfb integration-test execution;
- `flutter build web --release`;
- Android APK/AAB release builds;
- Linux release build;
- Windows release build;
- macOS release build;
- unsigned iOS release compilation;
- real-device/native notification delivery behavior;
- benchmark measurements on representative hardware;
- manual screen-reader/keyboard/scaled-text/reduced-motion review;
- production signing/notarization/store distribution;
- real application screenshot capture.

No result above should be marked green until it is actually executed and observed.

## Current known limitations and release blockers

1. A supported Flutter SDK must generate native runners through `dart run tool/bootstrap_platforms.dart`; generated runner directories are intentionally not frozen into the repository.
2. A supported Flutter SDK must run `flutter pub get`; the resulting application `pubspec.lock` must be reviewed and committed before a release tag.
3. `dart run tool/check_dependency_lock.dart` must pass from the committed release-candidate checkout before tagging.
4. Main CI must be observed successfully passing formatting, analyze, tests, documentation checks, Web release build, and Linux integration journey.
5. Every concrete analyzer/compiler/test/workflow failure discovered by the real Flutter toolchain must be fixed and regression-covered where appropriate.
6. The state-codec benchmark should be run on representative hardware and the environment/results recorded without turning one machine's number into a universal threshold.
7. Android completion notifications, permission denial, exact-alarm fallback, and cue combinations require real device/emulator verification.
8. Windows/macOS/iOS notification behavior requires supported native environments before platform-specific delivery claims are promoted.
9. At least one desktop native release build should be observed from the release workflow before claiming desktop release verification.
10. Manual accessibility review remains required with a real screen reader, keyboard-only navigation, large/scaled text, and reduced motion.
11. Real screenshots/demo captures must come from a verified release-candidate build.
12. Android store signing, Apple signing/provisioning/notarization, Windows signing, and other production-distribution credentials remain external to source control.
13. English is the only shipped locale for 0.2.0.
14. Signed distribution artifacts must not be implied by the unsigned CI compilation artifacts.
15. Final 0.2.0 changelog date/tag must remain unreleased until all required verification evidence exists.

## Next exact tasks

These are now primarily execution/environment verification tasks rather than missing static feature work.

1. On a clean checkout with Flutter `>=3.38.1` and compatible Dart:
   - run `dart run tool/bootstrap_platforms.dart`;
   - run `flutter pub get`;
   - inspect the generated dependency resolution;
   - review and commit `pubspec.lock` if the resolved graph is acceptable.
2. From the committed lockfile checkout run:
   - `dart run tool/check_required_files.dart`;
   - `dart run tool/check_version_sync.dart`;
   - `dart run tool/check_dependency_lock.dart`;
   - `dart run tool/check_secrets.dart`;
   - `dart run tool/check_localization_source.dart`;
   - `dart run tool/check_markdown_links.dart`.
3. Run:
   - `flutter gen-l10n`;
   - `dart format --output=none --set-exit-if-changed lib test integration_test tool`;
   - `flutter analyze`;
   - `flutter test`.
4. Run the primary integration journey on Linux or another configured supported target; on headless Linux use Xvfb as documented.
5. Run `tool/benchmark_state_codec.dart` on representative hardware and record SDK/runtime/hardware context with the result.
6. Observe the actual GitHub Actions runs for the release-candidate commit and fix every concrete failure.
7. Verify Android notification lifecycle behavior on a real device/emulator, including permission denial and exact-to-inexact fallback.
8. Observe native release builds, including at least one desktop target, and then validate additional Windows/macOS/iOS behavior on appropriate environments.
9. Perform manual accessibility review with screen reader, keyboard-only navigation, scaled text, dark/light/system theme, and reduced motion.
10. Capture real screenshots from the verified release candidate and add them under the documented screenshots path/README references.
11. Run the final clean-checkout repository/release audit.
12. Only after all release blockers are cleared:
    - convert the `0.2.0` changelog heading from release candidate to a real date;
    - update this handoff with observed verification evidence;
    - create/push `v0.2.0` through the approved release process;
    - inspect published artifacts/checksums before promoting the release.

## Migration and compatibility notes

- Current persisted/imported state is schema-versioned through `CountoraStateCodec`.
- Supported legacy unversioned state is migrated into the current schema boundary.
- Unknown future schemas are rejected rather than interpreted optimistically.
- Valid imported state is staged/validated before replacement.
- A failed persistence step must not be followed by platform schedule changes that imply unsaved state succeeded.
- Existing 0.1-era local data should be exercised during final release-candidate migration testing using fictional/controlled fixtures and a real Flutter runtime.
- A release must never weaken import bounds merely to accept malformed backup data.

## Recent meaningful commits

### 2026-08-20 — dependency-lock release gate and handoff synchronization

- `3589772` build: add dependency lock audit
- `da09f64` test: cover dependency lock audit
- `6bf31cf` build: add dependency lock check command
- `f5ae3bc` test: simplify dependency lock assertions
- `26de6da` ci: require committed dependency lock for releases
- `2ab0466` chore: require dependency lock audit tooling
- `442110a` docs: enforce reviewed dependency locks before tags
- `7e1db3d` docs: document dependency lock audit
- `eab80fb` docs: record release dependency lock gate
- `8e64cc0` docs: update release readiness roadmap
- current commit: docs: refresh Countora release handoff

### Late 2026-08-19 — release/version and platform reliability hardening

- `b202c2e` test: reject unreleased changelog tags
- `15ce009` build: match changelog release headings exactly
- `a9676bf` build: block tags with unreleased changelog entries
- `06c64ca` build: declare minimum supported Flutter SDK
- `eae606f` test: cover Android notification cue channels
- `e2d8d4b` fix: use stable Android channels per cue profile
- `a90fd29` test: verify deferred Apple notification permissions
- `b78f226` fix: defer Apple notification permission prompts
- `23cfeb3` test: cover timer pause deadline boundaries
- `4902dcc` fix: reconcile timer deadlines before pausing
- `5cdf39a` build: verify release tag matches package version
- `e1314e1` test: cover release version and tag audit
- `2e0ef85` build: add pure release version audit

### Additional 2026-08-19 hardening after the original baseline

- `67ffce7` test: add synthetic valid backup fixture
- `0f437fc` docs: add Countora repository tools reference
- `bfe98c9` docs: document Countora backup format
- `d2fc10d` feat: add read-only backup inspection command
- `94a63d5` test: cover privacy-safe backup inspection
- `d2ab31a` feat: add privacy-safe backup inspection summary
- `7fd54b5` chore: add documentation issue template
- `7a33883` test: cover localization source audit
- `aec9465` chore: add deterministic localization source check
- `92a06d2` feat: add pure localization source audit
- `cddec30` docs: add notification capability guide
- `db60d6f` test: cover unsupported notification settings state
- `9a36485` feat: reflect notification capability in Settings
- `e751b48` feat: explain unsupported scheduled notifications
- `56bd4b8` refactor: share notification capability policy
- `e688681` test: cover scheduled notification capability
- `6d2d939` feat: centralize scheduled notification capability
- `111bbe3` docs: record persistence-first side effect decision
- `875d438` fix: make timer reconciliation persistence-first
- `75033b7` test: cover persistence-first reconciliation and import
- `10a503f` fix: persist timer state before notification side effects
- `9f96023` test: keep notification side effects behind persistence
- `c12761a` fix: announce focus mode action correctly
- `6eced19` test: cover focus mode entry semantics
- `cd7efb4` perf: add repeatable state codec benchmark harness

### Earlier principal implementation continuation

- `35e29b0` docs: add development handoff log
- `8d66d25` feat: add schema-aware local state codec
- `90bd711` test: cover state codec validation and migrations
- `2cad011` refactor: route local persistence through state codec
- `55a91b2` feat: harden timer controller lifecycle and data workflows
- `0969ab7` test: cover controller data and bulk workflows
- `e0e3523` feat: add monotonic runtime clock
- `35af31b` test: verify monotonic clock behavior
- `015ee8b` feat: use monotonic clock for active countdowns
- `cd81963` feat: reconcile timers when app resumes
- `8e8c365` feat: add redacting structured logger
- `a671709` fix: add resilient notification scheduling fallback
- `07d10b4` feat: expand timer card management and focus controls
- `5e4910a` feat: add desktop shortcuts and timer bulk actions
- `c4eb372` feat: add backup preview and full local data reset
- `fd11bb3` fix: reject malformed backup field types safely
- `160de21` test: cover malformed backup field types
- `c8c3aae` test: cover local persistence recovery
- `1d5a265` fix: harden generated Android notification configuration
- `321e8dc` feat: add Countora design tokens
- `93e8530` refactor: apply shared design tokens to themes
- `208f600` feat: improve interval editor validation and ordering
- `f8899f4` chore: centralize Countora release metadata
- `157a07e` chore: prepare Countora 0.2.0
- `e5baf64` feat: expand About with release and project metadata
- `97dc1b2` ci: scan GitHub Actions workflows with CodeQL
- `8952f54` ci: enforce moderate dependency vulnerability threshold
- `653da9e` build: add local documentation link checker
- `86b6ea3` ci: expand quality gates for Countora
- `ddf6ffd` ci: harden tagged release verification
- `41c1a4a` test: add reusable Countora test fakes
- `b8e377b` test: cover primary timer UI journeys
- `2da8e4d` test: add Flutter integration test support
- `1b50caf` test: add primary Countora integration journey
- `d9c9ad3` feat: add Flutter localization infrastructure
- `7572967` build: configure Flutter localization generation
- `7ae172b` feat: externalize English UI strings
- `f70dbe4` feat: wire generated localization resources into app
- `a053019` feat: add localization context helper
- `799b3b5` refactor: localize home and timer navigation
- `35730c7` feat: add shared localized labels for dynamic UI
- `608c167` refactor: localize timer cards and focus mode
- `017f2ef` refactor: localize countdown and interval editor
- `64ba77d` refactor: localize settings and data management
- `3b446fa` refactor: localize About and support links
- `12b7c9b` chore: ignore generated localization source
- `3d44a75` test: verify English localization resources

## Release notes draft — 0.2.0

### Added

- schema-aware validated backups and legacy migration safety;
- privacy-safe backup inspection tooling;
- timer duplicate/edit/save-as-preset workflows;
- history replay;
- bulk pause/resume/remove-completed actions;
- enhanced interval editor labels/validation/reordering;
- richer full-screen focus mode;
- desktop keyboard shortcuts;
- structured redacting diagnostics;
- monotonic runtime clock and app-resume reconciliation;
- fail-closed notification scheduling capability policy;
- English generated-localization resource architecture;
- localization source audit tooling;
- deterministic state-codec benchmark harness;
- expanded domain/controller/widget/persistence/platform/tooling/integration regression coverage;
- repository required-file/version/secret/localization/link checks;
- release-only committed dependency-lock audit;
- CodeQL Actions scanning;
- strengthened Dependency Review;
- Android/Web/Linux/Windows/macOS/unsigned-iOS tagged release artifact workflow source;
- SHA-256 release artifact digest generation;
- repository governance/operations documentation.

### Changed

- persistence validates and bounds untrusted local/imported JSON;
- durable state is persisted before associated platform notification side effects;
- failed imports restore prior in-memory state rather than reporting a false successful replacement;
- timer reconciliation handles suspended/elapsed sequences more safely;
- pause reconciles elapsed deadlines first;
- notification permission requests are de-duplicated/deferred appropriately;
- Android scheduling falls back from exact to inexact where required;
- Android notification channels are stable per cue profile;
- unsupported notification targets fail closed and Settings explains the limitation;
- generated Android runner patching validates template assumptions;
- design tokens centralize UI constants;
- Settings import/reset/export/external-link failure handling is safer;
- main UI strings are externalized;
- CI formats integration tests and contains a dedicated Linux/Xvfb journey;
- tagged releases now require synchronized version metadata, finalized changelog entry, matching tag, reviewed committed dependency lock, repository audits, tests/build gates, and artifact checksums.

### Security and privacy

- bounded backup size/schema/type validation;
- corrupted local-state recovery;
- sensitive structured-log redaction;
- guarded external/platform failure boundaries;
- moderate-or-higher Dependency Review threshold;
- CodeQL workflow scan;
- deterministic secret/repository checks;
- release artifact SHA-256 digests;
- local-first/no-account behavior remains unchanged;
- release signing secrets remain external to source control.

### Remaining release blockers

- generate/review/commit `pubspec.lock` using the supported Flutter SDK;
- observe successful real Flutter formatting/analyze/test/integration/build results;
- fix any concrete failures returned by that toolchain;
- run and record benchmark evidence;
- verify native notification behavior on representative targets;
- complete manual accessibility review;
- capture real release-candidate screenshots;
- validate final release artifacts/signing/distribution as applicable;
- do not finalize the 0.2.0 changelog date or create `v0.2.0` until the blockers above are cleared.
