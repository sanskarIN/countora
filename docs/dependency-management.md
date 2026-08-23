# Dependency management

Countora is a Flutter application, so reproducible dependency resolution is part of the release contract rather than an optional convenience.

## Approved Flutter toolchain

GitHub Actions installs the repository-approved Flutter version through:

```text
.github/actions/setup-flutter/action.yml
```

The current approved toolchain is Flutter `3.44.7` on the stable channel.

All Countora validation, platform-smoke, repository-audit, dependency-lock, and tagged-release workflows should use this shared action instead of selecting a moving `stable` version independently. When the approved Flutter version changes, update the shared action in one reviewed commit and let the normal validation matrix prove compatibility.

The minimum Flutter constraint in `pubspec.yaml` remains a source-compatibility statement. The shared CI action is the reproducible build-toolchain selection.

## Application lockfile policy

Countora must commit `pubspec.lock` before a release is tagged.

The lockfile must be produced by the approved Flutter toolchain. Do not:

- hand-write a lockfile;
- copy a lockfile from another application;
- edit package versions or content hashes manually;
- accept an unexplained lockfile rewrite;
- create a release tag when `tool/check_dependency_lock.dart` fails.

A normal dependency refresh starts with:

```bash
dart run tool/check_localization_source.dart
dart run tool/bootstrap_platforms.dart
flutter pub get
dart run tool/check_dependency_lock.dart
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
```

Review the resulting `pubspec.lock` diff before committing it.

## Guarded GitHub lock refresh

`.github/workflows/dependency-lock.yml` provides a repository-hosted refresh path for environments where the approved Flutter toolchain is not available locally.

The workflow runs when its dependency inputs change and can also be started manually. It:

1. checks out `main`;
2. installs the shared pinned Flutter toolchain;
3. validates localization references and every translated catalog;
4. generates and patches all Flutter platform runners;
5. resolves dependencies;
6. validates the generated lockfile shape;
7. generates localization output;
8. verifies formatting;
9. runs `flutter analyze`;
10. runs the Flutter unit/widget test suite;
11. runs repository, version, secret, and documentation checks;
12. verifies patch whitespace hygiene;
13. uploads the verified lockfile as a 14-day workflow artifact;
14. commits only `pubspec.lock` when it actually changed;
15. uses `sanskarin@outlook.in` as the automated Git commit email.

The artifact exists as a recovery path if repository branch rules prevent the workflow from pushing directly. An uploaded artifact is not automatically approved source; review it before committing it manually.

## Release enforcement

The tagged release workflow first runs:

```bash
dart run tool/check_dependency_lock.dart
```

before dependency installation. It then installs packages with:

```bash
flutter pub get --enforce-lockfile
```

The enforcement flag makes dependency resolution fail when the committed lockfile cannot exactly satisfy `pubspec.yaml` or when a hosted-package content hash does not match. Release jobs on Linux, Windows, macOS, iOS, Android, and Web therefore consume the reviewed graph rather than silently creating a different one.

## Adding or changing a dependency

For every direct dependency change:

1. modify `pubspec.yaml` deliberately;
2. regenerate `pubspec.lock` with the approved Flutter toolchain;
3. inspect both direct and relevant transitive changes;
4. review package release notes and security implications when the change is significant;
5. run the smallest relevant tests first;
6. run the full Countora quality suite before release;
7. keep `pubspec.yaml` and `pubspec.lock` changes in the same reviewed dependency update;
8. do not weaken version constraints merely to force resolution.

For major plugin upgrades, also rerun the platform-smoke matrix because native Android, Apple, Windows, Linux, or Web integration requirements can change even when Dart analysis succeeds.

## Updating Flutter

A Flutter upgrade is a toolchain change and must be treated separately from an ordinary package refresh.

1. Verify the intended stable Flutter release from official Flutter release information.
2. Update `.github/actions/setup-flutter/action.yml`.
3. Regenerate native runners with `tool/bootstrap_platforms.dart`.
4. Regenerate and review `pubspec.lock`.
5. Run formatting, analysis, tests, Web build, Linux integration, and the full platform-smoke matrix.
6. Review generated-runner patch tests for Flutter template drift.
7. Update setup/release documentation when the supported baseline changes.
8. Do not tag a release until the exact release-candidate commit has successful required checks.

## Dependency rollback

If a package or toolchain upgrade introduces a regression:

1. identify the smallest responsible dependency/toolchain change;
2. revert or constrain that change without manually corrupting the lockfile;
3. regenerate the lockfile using the approved Flutter version;
4. add a regression test when practical;
5. rerun the affected platform build plus the normal quality suite;
6. document any user-visible impact in `CHANGELOG.md` when the regression reached a public release.

Never rewrite an already published release tag to hide a dependency problem.