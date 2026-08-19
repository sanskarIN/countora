# Contributing to Countora

Thanks for improving Countora.

## Local setup

```bash
git config user.email "sanskarin@outlook.in"
dart run tool/bootstrap_platforms.dart
flutter pub get
```

Use a supported Flutter stable release and keep generated platform runner changes out of commits unless a native customization genuinely must be versioned.

## Quality gate

Before a pull request:

```bash
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter build web --release
```

Add regression coverage for bug fixes. Keep user-facing strings clear and accessible. Never commit credentials, signing keys, personal user data, or production secrets.

## Commit style

Prefer small Conventional Commits:

- `feat: add timer grouping`
- `fix: preserve paused duration`
- `test: cover interval rollover`
- `docs: clarify notification permissions`

## Pull requests

Explain the problem, solution, testing performed, accessibility impact, privacy/security impact, and screenshots for visible UI changes.
