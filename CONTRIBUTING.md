# Contributing to Countora

Thanks for improving Countora. Contributions should keep the project local-first, accessible, secure, maintainable, and useful as a countdown product rather than adding features only for feature count.

## Before starting

For significant behavior or architecture changes:

1. check existing issues/discussions;
2. describe the user problem being solved;
3. identify persistence/notification/platform/accessibility implications;
4. add or update an ADR when the architecture boundary changes.

Security-sensitive work must follow [`SECURITY.md`](SECURITY.md) instead of public exploit discussion.

## Local setup

```bash
git config user.email "sanskarin@outlook.in"
dart run tool/bootstrap_platforms.dart
flutter pub get
flutter gen-l10n
```

Use a compatible Flutter stable SDK. Generated platform runner directories are intentionally ignored; encode required native customizations in the bootstrap script rather than relying on manual generated-file edits.

See [`docs/setup.md`](docs/setup.md) and [`docs/development.md`](docs/development.md).

## Quality gate

Before a pull request:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
dart run tool/check_markdown_links.dart
flutter build web --release
```

Run relevant host-native builds for platform-specific changes.

For changes to a primary user journey, run or update:

```bash
flutter test integration_test/app_journey_test.dart
```

## Code requirements

- Keep business rules outside widgets where practical.
- Keep plugin access behind interfaces.
- Preserve absolute UTC persisted deadlines and the stable runtime clock model.
- Route persisted/imported state through `CountoraStateCodec`.
- Do not weaken backup/entity/duration caps without evidence and documentation.
- Keep async callbacks safe; do not knowingly introduce unhandled persistence/plugin failures.
- Add deterministic regression coverage with every reproducible bug fix.
- Avoid unnecessary dependencies.
- Do not introduce forced sign-in, analytics, advertising, or remote storage without an explicit architecture/privacy/security proposal.

## Localization

Visible application copy belongs in `lib/l10n/app_en.arb` and should be read through generated localization resources.

After changing ARB files:

```bash
flutter gen-l10n
```

Do not add a translation by copying conditional strings throughout widgets. Add the locale ARB and preserve one localization interface.

## Accessibility

For UI changes verify:

- keyboard reachability on desktop/web
- semantic purpose for icon-only controls
- scaled text
- reduced motion
- non-color-only status
- non-audio completion/progress cues
- destructive-action clarity

See [`docs/accessibility.md`](docs/accessibility.md).

## Privacy and security

Never commit:

- credentials/tokens
- signing keys/keystores/profiles
- production secrets
- real user backups
- personal timer data
- private endpoints

Do not log user timer names, backup JSON, authorization data, credentials, or unrelated personal content.

Review [`PRIVACY.md`](PRIVACY.md) and [`SECURITY.md`](SECURITY.md) for changes affecting those boundaries.

## Commit style

Prefer small Conventional Commits:

- `feat: add timer grouping`
- `fix: preserve paused duration`
- `test: cover interval rollover`
- `docs: clarify notification permissions`
- `refactor: isolate persistence codec`
- `perf: bound expensive reconciliation`
- `ci: validate release build`

Do not create empty/churn-only commits to inflate history.

## Pull requests

A pull request should explain:

- problem/user need
- implementation approach
- tests/checks actually run
- accessibility impact
- privacy/security impact
- persistence/migration impact
- platform impact
- screenshots from a real build for visible UI changes when available
- known limitations/follow-up work

Do not state that a test/build passes unless it was actually run successfully.

## Review checklist

A reviewer should check:

- behavior is coherent with Countora
- new data has validation and migration strategy
- timer correctness is deterministic
- platform permissions are least-privilege
- user-visible text is localized
- accessibility basics are preserved
- tests cover the regression/feature boundary
- docs match source
- no secrets or private data are present
- commit history remains meaningful
