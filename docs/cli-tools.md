# Repository tools reference

Countora keeps deterministic repository/build helpers under `tool/`. These commands are intended for contributors and release engineering; they are not network services and do not require Countora user accounts.

Run commands from the repository root unless a section says otherwise.

## Toolchain prerequisites

Use a current stable Flutter SDK compatible with `pubspec.yaml`. Commands that import Countora/Flutter package code require dependency resolution first:

```bash
flutter pub get
```

Generated localization-dependent application commands should also run:

```bash
flutter gen-l10n
```

Never invent generated dependency metadata or native runner files by hand merely to make a command appear complete.

## `tool/bootstrap_platforms.dart`

Purpose: generate Flutter platform runners from the installed Flutter SDK and apply Countora-specific validated Android configuration.

Run:

```bash
dart run tool/bootstrap_platforms.dart
```

The command generates runners for the supported source targets and applies pure transforms from `tool/src/platform_patches.dart`.

Android transforms cover notification permissions/receivers plus desugaring/multidex requirements. They are designed to be idempotent and to fail when expected Flutter template anchors disappear rather than silently leaving an incomplete runner.

Generated runner directories are intentionally ignored by Git.

## `tool/check_required_files.dart`

Purpose: verify that Countora's required repository, governance, documentation, test, architecture, tooling, and workflow files are present.

Run:

```bash
dart run tool/check_required_files.dart
```

It also verifies the minimum documented ADR count. A failure should be fixed by restoring/updating the relevant repository contract, not by deleting the requirement merely to make CI green.

## `tool/check_version_sync.dart`

Purpose: ensure application/repository version metadata remains synchronized with `pubspec.yaml`.

Run:

```bash
dart run tool/check_version_sync.dart
```

Use this before release tagging and after any version/build-number change.

## `tool/check_dependency_lock.dart`

Purpose: require a reviewed application dependency lock before a release tag is allowed to proceed.

Run after generating dependency resolution with the supported Flutter SDK:

```bash
flutter pub get
dart run tool/check_dependency_lock.dart
```

The command fails when `pubspec.lock` is missing, empty, or lacks the expected top-level `packages`/`sdks` lockfile sections. Its pure logic lives in `tool/src/dependency_lock_audit.dart` and is covered by `test/dependency_lock_audit_test.dart`.

The tagged release workflow runs this command before its own `flutter pub get`, preventing release CI from silently replacing a missing reviewed lock with newly resolved dependency metadata.

## `tool/check_secrets.dart`

Purpose: scan tracked repository source for obvious secret patterns as a deterministic local baseline.

Run:

```bash
dart run tool/check_secrets.dart
```

This check does not replace GitHub secret scanning or a dedicated release-environment scanner. Never add real credentials to fixtures just to test the scanner.

## `tool/check_localization_source.dart`

Purpose: validate English localization source and committed localization getter references before generated localization Dart code is required.

Run:

```bash
dart run tool/check_localization_source.dart
```

The pure audit logic lives in `tool/src/localization_audit.dart` and is covered by `test/localization_audit_test.dart`.

The audit checks:

- the expected English locale marker;
- required product messages;
- non-empty message values;
- `strings.<key>` and `context.l10n.<key>` references against `lib/l10n/app_en.arb`.

This complements—not replaces—`flutter gen-l10n`, `flutter analyze`, and Flutter tests.

## `tool/check_markdown_links.dart`

Purpose: verify local repository Markdown references without fetching external sites.

Run:

```bash
dart run tool/check_markdown_links.dart
```

External network links are intentionally not fetched so this audit remains deterministic/offline.

## `tool/inspect_backup.dart`

Purpose: validate a Countora JSON backup through `CountoraStateCodec` without importing it into the app and emit a privacy-safe structural summary.

Run:

```bash
dart run tool/inspect_backup.dart path/to/countora-backup.json
```

The command:

- accepts exactly one file path;
- checks the configured backup byte limit before reading contents;
- safely rejects missing/unreadable/non-UTF-8 input;
- decodes with the production state codec;
- reports timer status counts, interval counts, preset/history counts, byte size, and current decoded schema;
- does not print timer names, groups, interval labels, history names, or raw backup JSON;
- never writes application state.

See [`backup-format.md`](backup-format.md).

## `tool/benchmark_state_codec.dart`

Purpose: benchmark state-codec encode/decode behavior against a deterministic bounded fixture while verifying every round trip.

Run the default benchmark:

```bash
dart run tool/benchmark_state_codec.dart
```

Or choose an iteration count:

```bash
dart run tool/benchmark_state_codec.dart --iterations 500
```

The harness emits machine-readable timing statistics. Wall-clock performance varies by hardware/SDK/runtime conditions, so Countora does not use a universal CI latency threshold.

See [`performance.md`](performance.md).

## Pure helpers under `tool/src/`

### `backup_inspection.dart`

Builds the privacy-safe structural backup summary used by `inspect_backup.dart`. It intentionally exposes counts and sizes rather than user-entered timer content.

Regression coverage: `test/backup_inspection_test.dart`.

### `dependency_lock_audit.dart`

Validates the release lockfile presence and basic generated-lock structure without resolving dependencies or modifying repository files.

Regression coverage: `test/dependency_lock_audit_test.dart`.

### `localization_audit.dart`

Implements deterministic ARB/reference checks without file-system/global state.

Regression coverage: `test/localization_audit_test.dart`.

### `platform_patches.dart`

Implements pure generated-Android template transforms and postcondition validation.

Regression coverage: `test/platform_patches_test.dart`.

## Recommended contributor sequence

After cloning:

```bash
dart run tool/bootstrap_platforms.dart
flutter pub get
flutter gen-l10n
```

Before committing:

```bash
dart run tool/check_required_files.dart
dart run tool/check_version_sync.dart
dart run tool/check_secrets.dart
dart run tool/check_localization_source.dart
dart run tool/check_markdown_links.dart
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
```

When the change affects the main user journey and a Linux target is configured:

```bash
flutter test integration_test -d linux -r github
```

## Release sequence

The complete release process is intentionally stricter than this tool catalog. It additionally requires `tool/check_dependency_lock.dart` against a reviewed committed `pubspec.lock`. Follow [`release.md`](release.md), observe actual GitHub Actions results, and perform required native/device checks before publishing platform-specific claims.

## Failure-handling rule

A repository tool failure is information. Do not:

- disable a guard solely to get a green check;
- fabricate generated outputs;
- suppress malformed backup errors;
- publish secrets/backup bodies while troubleshooting;
- claim a command passed if it was not executed successfully.

Fix the underlying source/toolchain/repository problem, add regression coverage when appropriate, then rerun the relevant checks.
