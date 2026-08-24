# Countora development handoff

Updated: 2026-08-24
Current milestone: Countora 2.15.18 release-candidate verification
Target release: 2.15.18+18
Release branch: `release/2.15.18-rc`
Release pull request: #8 — `release: prepare Countora 2.15.18`
Repository: https://github.com/sanskarIN/countora
Source model: public / open source / MIT
Primary implementation: Flutter + Dart
Pinned repository verification toolchain: Flutter 3.47.1 / stable

## Continuity contract

Countora follows `12_countora_master_prompt.md` and is being developed as a production-oriented, local-first, secure, accessible, documented multi-countdown timer.

Continue the existing repository instead of replacing working code. Keep changes small and meaningful, prefer Conventional Commit-style messages, keep this handoff current, and do not fabricate passing builds, tests, screenshots, native notification behavior, signing evidence, package-store evidence, or release artifacts.

The requested commit email remains `sanskarin@outlook.in`. GitHub connector writes use the authenticated repository identity when the connector action does not expose custom Git author metadata.

## 2.15.18 release-candidate continuation

The previous Phase 6 verification branches were intentionally not merged into the release candidate because they had diverged substantially from current `main`. `verification/phase-6-rc` was 22 commits ahead and 37 commits behind `main`; `verification/normalize-phase-6` was 33 commits ahead and 37 commits behind `main` when reviewed.

A fresh branch was therefore created directly from the latest `main` head:

```text
release/2.15.18-rc
```

This keeps all current `main` work and carries forward only relevant, reviewed release fixes from the older verification experiments.

### Version synchronization

The candidate now uses:

```text
Flutter package: 2.15.18+18
AppMetadata:     2.15.18 / build 18
Windows MSIX:    2.15.18.18
Reserved tag:    v2.15.18
```

The matching `CHANGELOG.md` section remains:

```text
## [2.15.18] - Unreleased release candidate
```

This is intentional. `tool/src/version_audit.dart` rejects a tag while the matching changelog heading still contains `unreleased`, preventing an unverified candidate from being published accidentally.

### Fresh release PR

PR #8 targets `main` from `release/2.15.18-rc`.

It was opened as a real release-candidate verification surface rather than as a tag/publish action. The PR remains open while automated and manual release gates are unresolved.

## Normalization failure discovered and fixed

The older normalization workflow provided useful real toolchain evidence before failing.

Observed successful steps on Flutter 3.47.1 / Dart 3.13.1 included:

- Flutter installation;
- Dart formatting execution;
- `flutter pub get` dependency resolution;
- generation of a real application `pubspec.lock`;
- dependency-lock shape validation;
- localization-source validation;
- patch-hygiene validation.

The workflow failed only during its final commit/push sequence. Flutter had rewritten `analysis_options.yaml`, leaving unstaged changes, and the later command:

```text
git pull --rebase
```

failed because the working tree was dirty.

The 2.15.18 candidate fixes the cause rather than hiding/stashing the mutation.

## Safe platform bootstrap

`tool/bootstrap_platforms.dart` now invokes Flutter with:

```text
flutter create .
--project-name=countora
--org=dev.sanskar
--platforms=android,ios,web,windows,macos,linux
--no-pub
```

Dependency resolution is therefore not an implicit side effect of platform-runner generation.

Before generation, Countora snapshots application-owned root files:

- `.gitignore`;
- `README.md`;
- `analysis_options.yaml`;
- `l10n.yaml`;
- `pubspec.lock`;
- `pubspec.yaml`.

After `flutter create`, those files are restored byte-for-byte in a `finally` block before native runner patches are applied.

Created:

```text
tool/src/root_file_guard.dart
```

The guard:

- preserves exact bytes rather than normalizing text;
- restores files that existed before generation;
- removes a generated file that did not exist before generation;
- permits harmless dotted repository-relative filenames;
- rejects absolute paths;
- rejects `..` traversal segments.

Regression coverage:

```text
test/bootstrap_platforms_test.dart
test/root_file_guard_test.dart
```

These tests protect the six-platform generation list, the `--no-pub` boundary, exact root-file restoration, absent-file cleanup, and unsafe path rejection.

## Flutter 3.47 iOS runner compatibility

A second useful finding from the old verification branch was that current Flutter 3.47 iOS templates can use UIScene/implicit-engine plugin registration instead of the older:

```text
GeneratedPluginRegistrant.register(with: self)
```

inside `didFinishLaunchingWithOptions`.

`patchIosAppDelegate()` no longer requires that legacy registration line. It now anchors notification-center delegate setup to the stable launch return line and supports both:

- legacy AppDelegate plugin registration;
- Flutter 3.47 `FlutterImplicitEngineDelegate` / `didInitializeImplicitFlutterEngine` templates.

The patch still:

- requires the expected UIKit import;
- adds `import UserNotifications` when absent;
- installs `UNUserNotificationCenter.current().delegate` during launch;
- remains idempotent;
- fails closed if the expected launch template anchor disappears.

`test/platform_patches_test.dart` now contains separate legacy and Flutter 3.47 template fixtures.

## Pinned toolchain policy

`.github/actions/setup-flutter/action.yml` now pins:

```text
Flutter 3.47.1
channel: stable
cache: true
```

Created:

```text
tool/src/toolchain_audit.dart
tool/check_toolchain.dart
test/toolchain_audit_test.dart
```

The audit requires:

- exactly one pinned `MAJOR.MINOR.PATCH` Flutter version in the shared setup action;
- stable channel;
- caching enabled;
- CI/release workflows to consume the shared setup action;
- workflows not to bypass it with direct `subosito/flutter-action` usage.

The audit covers:

```text
.github/workflows/ci.yml
.github/workflows/dependency-lock.yml
.github/workflows/platform-smoke.yml
.github/workflows/release.yml
.github/workflows/repository-audit.yml
```

This reduces accidental “works on one runner version” drift across the release pipeline.

## Dependency-lock workflow hardening

`.github/workflows/dependency-lock.yml` now supports both:

```text
main
release/**
```

The workflow:

1. checks out the exact current branch;
2. installs the shared pinned Flutter toolchain;
3. verifies the toolchain policy;
4. validates localization source/catalogs;
5. safely generates all platform runners;
6. explicitly runs `flutter pub get`;
7. validates the generated lockfile;
8. generates localization code;
9. runs formatting, analysis, tests, repository checks, version checks, secret checks, and documentation-link checks;
10. runs `git diff --check`;
11. rejects every unexpected tracked change other than `pubspec.lock`;
12. retains the lock as a workflow artifact;
13. commits only `pubspec.lock` when it changed;
14. rebases/pushes against the exact current branch.

The commit identity configured by that workflow remains:

```text
Sanskar <sanskarin@outlook.in>
```

A lockfile must still come from a real successful toolchain run. It must not be hand-written or fabricated.

## Release-branch CI coverage

The following workflows now run for `release/**` pushes in addition to their previous main/PR behavior where appropriate:

### CI

- shared Flutter toolchain policy;
- localization-source validation;
- platform runner generation;
- dependency resolution;
- localization generation;
- formatting;
- `flutter analyze`;
- `flutter test`;
- local documentation links;
- Web release build;
- Linux/Xvfb integration journey.

### Repository audit

- shared Flutter toolchain policy;
- required-file contract;
- synchronized version metadata;
- localization-source audit;
- obvious-secret scan;
- documentation-link audit.

### Platform smoke

- Android debug build on Ubuntu;
- Linux debug build on Ubuntu;
- portable Windows debug build on Windows;
- Windows MSIX package-identity creation on Windows;
- macOS debug build on macOS;
- unsigned iOS debug build on macOS.

### Tagged release

The tagged release quality job now includes the shared toolchain-policy audit before repository/version/lock/localization/security/build work.

The final tag remains blocked until the candidate changelog heading is finalized and all required release evidence exists.

## 2.15.18 release documentation

Created:

```text
docs/release-2.15.18.md
```

It records automated and manual release requirements for the exact candidate.

`docs/release.md`, `README.md`, `ROADMAP.md`, `CHANGELOG.md`, and the required-file contract have been aligned to the 2.15.18 candidate.

The release checklist itself is now a required repository file.

## Current cross-platform product status

Countora source intentionally supports all six primary Flutter deployment families from one application codebase:

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
- schema-aware bounded backup/restore;
- corrupted-state recovery;
- absolute UTC deadline persistence;
- monotonic in-process runtime clock;
- app-resume/startup reconciliation;
- responsive Material 3 UI;
- light, dark, and system themes;
- reduced motion and accessibility semantics;
- desktop keyboard shortcuts;
- English/Hindi localization with System override;
- Settings/About/privacy/support surfaces;
- structured redacting diagnostics;
- guarded external links/clipboard operations.

Cross-platform support does not imply identical OS APIs. Countora explicitly models capability differences and uses the safest available fallback.

## Notification capability architecture

`lib/src/core/platform_capabilities.dart` remains the notification-delivery capability source of truth.

Modes:

```text
NotificationDeliveryMode.scheduledBackground
NotificationDeliveryMode.runtimeOnly
NotificationDeliveryMode.unavailable
```

Current behavior:

| Platform / distribution | Delivery mode | Countora behavior |
| --- | --- | --- |
| Android | scheduledBackground | Native future scheduling; exact scheduling falls back to inexact when exact alarms cannot be used |
| iOS | scheduledBackground | Native Darwin future scheduling |
| macOS | scheduledBackground | Native Darwin future scheduling |
| Windows portable ZIP | runtimeOnly | Local notification while Countora remains active |
| Windows MSIX/package identity | scheduledBackground | Future Windows scheduling through `COUNTORA_WINDOWS_PACKAGED=true` |
| Linux | runtimeOnly | Linux desktop notification while Countora remains active |
| Web | runtimeOnly | Browser notification while the page/runtime remains active after explicit permission grant |
| Unsupported/unknown native target | unavailable | Fail closed |

Linux, Web, and portable Windows runtime notification delivery is not a promise of future notification delivery after the process/page has terminated.

## Existing reliability and security work retained

The 2.15.18 release work builds on rather than replaces previous Countora hardening:

- schema-aware bounded state codec;
- future-schema rejection;
- legacy state migration;
- explicit imported identifier limits;
- malformed backup/type rejection;
- safe corrupted-state recovery;
- timer/preset controller collection limits;
- monotonic runtime clock;
- startup/resume reconciliation;
- interval catch-up using prior deadlines;
- non-overlapping asynchronous ticker guard;
- persistence-before-platform-side-effect ordering;
- failed-import rollback;
- bounded notification cleanup that continues after individual plugin failures;
- runtime notification exact-deadline race protection;
- Android exact-to-inexact scheduling fallback;
- stable Android cue-profile notification channels;
- direct Web user-gesture notification permission boundary;
- no automatic Web permission prompt from startup/reconciliation;
- package-identity-aware Windows scheduling;
- recursive structured diagnostic redaction;
- deterministic localization-source/catalog audits;
- release-only dependency-lock auditing;
- required-file/version/secret/link audits;
- Dependency Review threshold;
- CodeQL workflow scan;
- SHA-256 tagged artifact digests;
- responsive Home/Settings error surfaces;
- accessibility/localization architecture;
- deterministic state-codec benchmark harness.

## Native runner hardening retained

Android generation enforces:

- `RECEIVE_BOOT_COMPLETED`;
- `SCHEDULE_EXACT_ALARM`;
- scheduled-notification receivers;
- core-library desugaring;
- multidex;
- `desugar_jdk_libs` dependency;
- AGP floor of 8.11.1 while preserving newer generated versions.

iOS generation adds the notification-center delegate needed for foreground local-notification presentation and now supports both legacy and Flutter 3.47 runner structures.

## Current verification evidence

### Evidence observed before this candidate

The older normalization run proved that Flutter 3.47.1 could install, format source, resolve the Countora dependency graph, generate a lockfile, validate the lock shape, validate localization references, and pass patch hygiene before failing at the dirty-working-tree rebase step.

That run is useful diagnostic evidence but is **not** release evidence for the new 2.15.18 candidate because the candidate tree is different.

### Current PR evidence

At the time this handoff was updated, PR #8 had live GitHub checks queued/pending for:

- CI;
- Platform smoke;
- Repository audit;
- Dependency security review;
- CodeQL workflow scan.

Those queued states are not recorded as passing. Their final results must be observed on the latest candidate commit and failures must be fixed rather than ignored.

### Not yet truthfully verified for 2.15.18

Until real successful results are observed on the exact candidate, do not claim the following are green:

- committed reviewed `pubspec.lock`;
- dependency-lock audit from the committed candidate;
- formatter check;
- `flutter analyze`;
- full `flutter test` suite;
- Linux/Xvfb integration journey;
- Web release build;
- Android smoke/release build;
- Linux smoke/release build;
- portable Windows smoke/release build;
- Windows MSIX creation;
- macOS smoke/release build;
- unsigned iOS compilation;
- Android real notification permission/background/exact-alarm behavior;
- iOS foreground/background notification behavior;
- macOS real notification behavior;
- Linux runtime notification behavior;
- Web browser permission/runtime notification behavior;
- portable Windows runtime notification behavior;
- installed package-identity Windows scheduling/cancellation behavior;
- production MSIX signing/store distribution;
- Apple signing/notarization/store distribution;
- Android store signing;
- manual accessibility review;
- representative benchmark results;
- real release screenshots.

## Remaining 2.15.18 release blockers

1. Observe the complete latest PR #8 CI result and fix every concrete failure.
2. Observe all Android/Linux/Windows/MSIX/macOS/iOS Platform smoke jobs and fix every concrete failure.
3. Observe repository audit, dependency security review, and CodeQL results.
4. Generate, review, and commit the real `pubspec.lock` using the pinned Flutter 3.47.1 toolchain.
5. Verify the dependency-lock audit against that committed candidate checkout.
6. Run an additional configured local/release integration journey where available and record evidence.
7. Run the state-codec benchmark on representative hardware and record its environment/results.
8. Verify Android notification permission/completion, exact-alarm denial fallback, cue combinations, and relevant lifecycle behavior on a representative device/emulator.
9. Verify iOS notification behavior in a signed/device-capable Apple environment.
10. Verify macOS notification behavior on a representative release-like build.
11. Verify portable Windows runtime fallback.
12. Verify installed package-identity Windows scheduled delivery and cancellation.
13. Choose and validate a trusted MSIX signing or Microsoft Store distribution strategy before publishing an MSIX.
14. Verify Linux runtime local notifications and persisted-state reconciliation.
15. Verify Web **Browser notification permission → Allow**, denial/grant, runtime completion delivery, reload, and page lifecycle behavior in representative browsers.
16. Complete manual accessibility review with screen reader, keyboard-only navigation, scaled text, reduced motion, and themes.
17. Capture only real screenshots from verified builds.
18. Run the final clean-checkout release audit and record successful output.
19. Convert `[2.15.18] - Unreleased release candidate` to the actual release date only after verification succeeds.
20. Create `v2.15.18` only after the complete release gate is satisfied.

## 2.15.18 preparation commits created in this continuation

The release branch intentionally uses many focused commits. Important new commits include:

- `7d42250` build: pin Flutter 3.47.1 for release verification
- `0efabb0` feat: guard root files during platform bootstrap
- `ff54816` fix: preserve repository files during runner generation
- `0ddf083` test: protect platform bootstrap arguments
- `78debf8` test: cover root file preservation guard
- `66f873e` chore: protect release bootstrap regression files
- `052450d` build: prepare package version 2.15.18
- `42977a3` chore: sync app metadata for 2.15.18
- `d77f0e1` docs: add 2.15.18 release candidate changelog
- `bc4e177` test: align version audit fixtures with 2.15.18
- `c077364` docs: prepare README for 2.15.18
- `ce138e4` ci: refresh dependency lock on release branches
- `470f0a3` fix: support Flutter 3.47 iOS runner template
- `37c5ee1` test: cover Flutter 3.47 iOS template patch
- `0066eba` feat: add deterministic Flutter toolchain audit
- `9bd6fb3` feat: expose Flutter toolchain audit command
- `1877416` test: cover Flutter toolchain audit
- `588d32f` chore: protect toolchain audit files
- `79a1a4e` ci: verify release branches with pinned toolchain
- `f750b60` ci: audit release branches with shared toolchain
- `a70ca68` ci: gate dependency lock on toolchain policy
- `1cf92ac` ci: run platform smoke on release branches
- `a1c34a5` docs: add 2.15.18 release verification checklist
- `4263c5e` docs: move roadmap to 2.15.18 release candidate
- `a56514c` chore: protect 2.15.18 release checklist
- `de2d53b` ci: enforce toolchain policy on tagged releases
- `b1a0448` docs: align release process with 2.15.18

Continue using focused commits for every reproducible fix or documentation/audit boundary.

## Next exact work

1. inspect the newest PR #8 workflow results for the latest branch head;
2. fetch logs for every failed job;
3. fix each real compiler/analyzer/test/workflow issue with a focused commit and regression where practical;
4. verify that the guarded dependency-lock workflow creates and commits only `pubspec.lock`;
5. rerun/observe candidate checks after every branch update;
6. update this handoff with real passing/failing evidence rather than assumptions;
7. complete the remaining manual platform/accessibility/distribution checks outside CI;
8. finalize the changelog date only when release evidence is complete;
9. tag `v2.15.18` only after the release gate is satisfied.
