# Changelog

All notable Countora changes are documented here.

The format follows the spirit of Keep a Changelog and the project uses semantic versioning for release tags.

## [Unreleased]

### Added

- Multi-timer countdown engine with pause/resume/restart/add-time controls.
- Presets, groups, interval sequences, completion history, and search.
- Local persistence and JSON backup/restore.
- Scheduled local notifications with sound/vibration/quiet controls.
- Responsive Material 3 UI, focus mode, compact cards, onboarding, themes, and reduced motion.
- About/support/funding links and local-first privacy information.
- Unit/controller tests, CI, dependency review, Dependabot, and project documentation.

## [0.2.0] - Unreleased release candidate

### Added

- Schema-aware state codec with legacy migration and future-schema rejection.
- Backup size, entity-count, duration, name, group, and interval-step limits.
- Safe import preview before replacement of current local data.
- Full local-data reset and history-only clearing.
- Timer duplication, timer rename/group move, save-as-preset, and history replay.
- Bulk pause-all, resume-all, and remove-completed actions.
- Richer full-screen focus controls with semantic progress cues.
- Desktop shortcuts for creation, search, and Settings.
- Interval-step labels, validation, rename, removal, and ordering.
- Monotonic runtime clock and app-resume reconciliation.
- Structured diagnostics with sensitive-key redaction.
- Countora design tokens and centralized release metadata.
- Generated Flutter localization architecture with English ARB resources.
- Persistence, state-codec, stable-clock, controller-workflow, widget, localization, external-link, and integration regression tests.
- Markdown local-link checker.
- CodeQL scan for supported GitHub Actions code.
- Multi-platform tagged release jobs for Android, Web, Linux, Windows, macOS, and unsigned iOS verification.
- Dedicated Linux/Xvfb integration-test CI job for the primary end-to-end journey.
- SHA-256 checksum files for tagged Android/Web, Linux, Windows, macOS, and unsigned iOS artifacts.

### Changed

- SharedPreferences persistence now routes through bounded validation/sanitization.
- Corrupted persisted state recovers to an empty safe state instead of blocking startup.
- Import rejects malformed types rather than allowing low-level type-cast failures.
- Timer ticker execution is guarded against overlapping asynchronous ticks.
- Interval catch-up anchors later steps to prior deadlines to reduce drift after suspension.
- Notification permission is requested at most once per controller session.
- Disabling notifications cancels active schedules; enabling them reschedules running timers.
- Android exact scheduling falls back to inexact scheduling if exact alarms cannot be used.
- Generated Android runner configuration now includes notification receivers, permissions, desugaring, and multidex setup.
- Settings backup/import/reset UI is safer and more explicit.
- Clipboard backup export now surfaces a localized failure message instead of allowing a platform-channel exception to escape.
- Settings/About external links use a resilient launcher boundary that converts platform URL-launch failures into user-visible feedback.
- Main UI strings are externalized for future translations.
- CI now generates localization source, formats `integration_test/`, and runs the primary Linux integration journey in a virtual display.
- Release quality gates now include repository-file, version-sync, tracked-secret, test, integration, documentation, and build checks before publication.

### Security

- Added bounded validation for untrusted imported JSON.
- Added dependency-review failure threshold of moderate severity.
- Added redacting structured diagnostics.
- Added CodeQL analysis for GitHub Actions workflow source.
- Added deterministic repository audits to the tagged release gate.
- Added release artifact SHA-256 digests for post-download integrity checks.
- Kept signing keys and secrets outside version control.

### Known release requirements

- Do not tag the final 0.2.0 release until actual Flutter analyze/test/build/integration runs have been observed as successful.
- Native notification behavior must be verified on supported real platforms/devices.
- Signed mobile/desktop distribution remains a release-environment responsibility.
- Real screenshots must come from an actual verified build; mockups are not presented as product captures.

## [0.1.0] - 2026-08-19

Initial public development baseline.
