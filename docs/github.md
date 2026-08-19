# GitHub repository operations

This file documents repository settings that live outside source control so a maintainer can reproduce the intended governance after cloning/forking the repository.

## Default branch

- Default branch: `main`
- Do not force-push normal development history to `main`.
- Do not rewrite published release tags.

## Recommended branch protection / ruleset

Protect `main` with a repository ruleset or branch-protection rule that requires:

- pull request before merge for normal external contributions
- at least one approving review where the repository has multiple maintainers/reviewers
- dismissal of stale approvals when new code is pushed when practical
- conversation resolution before merge
- successful required status checks
- branches to be up to date before merge where the workflow volume remains reasonable
- no force pushes
- no branch deletion

Recommended required checks are the actual checks backed by committed workflows, once their exact check names have been observed in GitHub Actions:

- main Flutter CI job from `.github/workflows/ci.yml`
- dependency review on dependency-changing pull requests
- CodeQL GitHub Actions analysis where supported/enabled

Do **not** configure a guessed required-check name before observing the check in the repository UI; an incorrect required name can make `main` impossible to merge into.

## Security settings

Enable repository security features available to the public repository/account:

- Dependabot alerts
- Dependabot security updates
- dependency graph
- secret scanning
- push protection when available
- private vulnerability reporting when available
- code scanning alerts for the committed CodeQL Actions workflow

Security-sensitive reports should follow [`../SECURITY.md`](../SECURITY.md), not a normal public issue.

## Actions permissions

Prefer least privilege:

- default workflow token permissions should be read-only where repository settings allow it
- individual jobs/workflows should grant only the write scopes they actually need
- release workflow needs `contents: write` only to attach release artifacts
- CodeQL job needs `security-events: write` for analysis upload

Third-party Actions should be maintained and reviewed during dependency updates. Consider pinning third-party Actions to immutable commit SHAs for a stricter supply-chain posture after validating update maintenance.

## Merge strategy

Recommended:

- squash merge for normal feature/fix pull requests when it produces a clean atomic `main` history
- rebase merge only when preserving a deliberately curated atomic commit series is valuable
- disable merge commits if a linear history is preferred
- auto-delete merged branches

Direct emergency fixes should still run the same CI/security checks and receive a follow-up review.

## Discussions

Enable GitHub Discussions for:

- usage questions
- ideas before formal feature requests
- community examples/workflows
- general project feedback

Keep confirmed defects in Issues and sensitive reports out of public Discussions.

Suggested categories:

- Announcements
- Q&A
- Ideas
- Show and tell

## Labels

Suggested core labels:

### Type

- `bug`
- `enhancement`
- `documentation`
- `tests`
- `ci`
- `dependencies`

### Quality area

- `accessibility`
- `security`
- `performance`
- `privacy`
- `localization`

### Platform

- `platform: android`
- `platform: ios`
- `platform: web`
- `platform: windows`
- `platform: macos`
- `platform: linux`

### Triage

- `needs-triage`
- `needs-reproduction`
- `blocked`
- `good first issue`
- `help wanted`

Avoid an excessive label taxonomy that no maintainer consistently uses.

## Milestones

Suggested milestones:

- `0.2.0` — reliability/localization/release hardening
- `1.0.0` — first fully verified stable multi-platform release
- later release milestones only when enough concrete work exists

Close or move stale issues rather than keeping a milestone permanently ambiguous.

## Releases

- Release tags use `vX.Y.Z`.
- Tagged release workflow artifacts must come from the tagged source.
- Never replace a public tag with different source/artifacts.
- GitHub release notes should be derived from `CHANGELOG.md` and actual merged work.
- Signing/notarization credentials must remain outside the repository.

## Funding

`.github/FUNDING.yml` and README/SUPPORT documentation point to:

- https://buymeacoffee.com/sanskarIN

Funding must remain optional and non-intrusive.

## Repository presentation

Recommended repository topics:

- `flutter`
- `dart`
- `countdown-timer`
- `timer`
- `productivity`
- `open-source`
- `android`
- `ios`
- `windows`
- `macos`
- `linux`
- `web`

Recommended short description:

> Local-first multi-countdown timer with presets, interval sequences, history, notifications, accessibility, and multi-platform Flutter support.

## Periodic maintenance

At least once per release cycle:

1. review Dependabot/security alerts;
2. review Actions versions and workflow permissions;
3. review issue/PR templates;
4. verify required checks still use real current check names;
5. remove stale labels/milestones;
6. confirm contact/funding/release links remain correct;
7. review branch/ruleset settings after major GitHub feature changes.
