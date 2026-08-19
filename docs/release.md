# Release

Countora release tags must represent verified source, not merely a version bump. Do not create a final release tag while known analyzer/test/build failures remain.

## Versioning

The Flutter package version is declared in `pubspec.yaml` as:

```text
MAJOR.MINOR.PATCH+BUILD
```

`AppMetadata.version` and `AppMetadata.buildNumber` must match the package version shown to users.

Before a release, update:

- `pubspec.yaml`
- `lib/src/core/app_metadata.dart`
- `CHANGELOG.md`
- `ROADMAP.md`
- `what_changed.md`

## Clean-checkout release candidate

From a clean clone:

```bash
dart run tool/bootstrap_platforms.dart
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
dart run tool/check_markdown_links.dart
```

Then run the integration journey on a configured target:

```bash
flutter test integration_test/app_journey_test.dart
```

## Platform build verification

Run only on compatible hosts/toolchains.

### Android

```bash
flutter build apk --release
flutter build appbundle --release
```

The repository's default source build is not a substitute for Play signing. Store signing credentials must be injected through the release environment and never committed.

### Web

```bash
flutter build web --release
```

### Linux

```bash
flutter build linux --release
```

### Windows

```bash
flutter build windows --release
```

### macOS

```bash
flutter build macos --release
```

Distribution outside local testing may require signing/notarization.

### iOS source verification

```bash
flutter build ios --release --no-codesign
```

An unsigned iOS application verifies compilation only. App Store/device distribution requires Apple signing/provisioning and should be performed on a trusted release host.

## GitHub tagged release workflow

`.github/workflows/release.yml` runs for tags matching `v*`.

The initial Ubuntu quality job must pass before desktop/Apple jobs run. It performs:

- platform runner generation
- dependency resolution
- localization generation
- formatting verification
- `flutter analyze`
- `flutter test`
- local Markdown-link check
- Web release build
- Android APK/AAB builds

After that quality gate:

- Ubuntu builds Linux x64
- Windows builds Windows x64
- macOS builds macOS and an unsigned iOS application

The workflow attaches matching artifacts to the GitHub release.

## Security/repository checks

Before tagging:

1. Review CI status for the release commit.
2. Review Dependency Review on dependency-changing pull requests.
3. Review CodeQL GitHub Actions scan status.
4. Review Dependabot alerts/update pull requests where available.
5. Confirm `.env`, keystores, signing profiles, private keys, tokens, and generated credentials are not tracked.
6. Confirm generated backup/test fixtures contain only fictional data.
7. Run a repository secret scan if a trusted scanner is available in the release environment.

## Native behavior checks

Before a stable public release, manually verify on representative targets:

- timer start/pause/resume/restart/add-time
- multiple simultaneous timers
- interval rollover
- app suspension/resume reconciliation
- completion notification delivery
- notification permission denial
- Android exact-alarm denial fallback
- quiet mode/sound/vibration combinations
- backup export/import/reset
- keyboard shortcuts on desktop/web
- dark/light/system themes
- reduced motion
- screen-reader/scaled-text basics

## Screenshots

Use only screenshots from an actual release-candidate build. Do not publish mockups as product captures. Store source captures in `docs/screenshots/` when they become available and update README references in the same commit.

## Tagging

Only after the release commit is verified:

```bash
git tag -s vX.Y.Z -m "Countora vX.Y.Z"
git push origin vX.Y.Z
```

If signed tags are not configured, use the repository's approved release process rather than weakening key security merely to satisfy this example.

## Release notes

Convert the matching `CHANGELOG.md` candidate section into a dated release entry and use it as the source for GitHub release notes. Include:

- user-facing additions/changes
- important fixes
- privacy/security changes
- known limitations
- supported artifact types
- upgrade/backup compatibility notes

## Rollback

If a release artifact is broken:

1. stop promoting the affected artifact;
2. document the issue publicly;
3. fix forward on a patch branch/version;
4. add a regression test;
5. rerun the complete quality/release workflow;
6. publish a patch release rather than rewriting an existing public tag.

Never replace a published tag with different source.
