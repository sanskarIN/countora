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
- Backup size, entity-count, identifier, duration, name, group, and interval-step limits.
- Safe import preview before replacement of current local data.
- Full local-data reset and history-only clearing.
- Timer duplication, timer rename/group move, save-as-preset, and history replay.
- Bulk pause-all, resume-all, and remove-completed actions.
- Richer full-screen focus controls with semantic progress cues.
- Desktop shortcuts for creation, search, and Settings.
- Interval-step labels, validation, rename, removal, and ordering.
- Monotonic runtime clock and app-resume reconciliation.
- Structured diagnostics with recursive sensitive-key redaction across nested maps/iterables.
- Countora design tokens and centralized release metadata.
- Generated Flutter localization architecture with English ARB resources.
- Cross-platform notification delivery tiers: scheduled background delivery on Android/iOS/macOS/Windows, runtime local-notification fallback on Linux/Web, and fail-closed handling for unsupported future targets.
- Cross-platform notification presentation details for Android, iOS, macOS, Linux, Windows, and Web.
- Persistence, state-codec, stable-clock, controller-workflow, controller-capacity, diagnostic-redaction, notification-cleanup, notification-presentation, home-error-surface, Settings-reactivity, widget, localization, external-link, platform-capability, platform-patch, dependency-lock, and integration regression tests.
- Deterministic state-codec benchmark harness with machine-readable latency summaries.
- ADR 0005 documenting durable-state-before-platform-side-effect ordering.
- Markdown local-link checker.
- Release-only committed dependency-lock audit that rejects missing/empty/malformed `pubspec.lock` metadata before dependency resolution.
- Deterministic localization-source audit enforced by repository audit, normal CI, and tagged release CI before generated localization code is created.
- Expanded required-file contract protecting repository audit, release tooling, localization/backup/diagnostic audit tooling, critical docs, branding source, integration journey source, important UI regressions, cross-platform notification regressions, and issue-template configuration.
- CodeQL scan for supported GitHub Actions code.
- Multi-platform tagged release jobs for Android, Web, Linux, Windows, macOS, and unsigned iOS verification.
- Dedicated non-tagged platform-smoke workflow compiling Android, Linux, Windows, macOS, and unsigned iOS targets on their appropriate GitHub-hosted runners.
- Dedicated Linux/Xvfb integration-test CI job for the primary end-to-end journey.
- SHA-256 checksum files for tagged Android/Web, Linux, Windows, macOS, and unsigned iOS artifacts.

### Changed

- SharedPreferences persistence now routes through bounded validation/sanitization.
- Persistence schema ownership now lives exclusively at the `CountoraStateCodec` boundary instead of leaking into domain-state serialization.
- Corrupted persisted state recovers to an empty safe state instead of blocking startup.
- Import rejects malformed types rather than allowing low-level type-cast failures.
- Imported timer/preset/history identifiers are limited to 128 characters; oversized identifiers are discarded instead of truncated to avoid accidental collisions or altered relationships.
- Backup import now reconciles staged state and requires successful persistence before replacing platform notification schedules; a failed import save restores the prior in-memory state and surfaces failure.
- Timer and preset creation now stops at the same 500-entity limits enforced by decoded persistence, preventing live controller state from exceeding those collection bounds.
- Starting a preset at full timer capacity no longer increments its usage counter without creating the requested timer.
- Timer ticker execution is guarded against overlapping asynchronous ticks.
- Interval catch-up anchors later steps to prior deadlines to reduce drift after suspension.
- Timer reconciliation persists completed/advanced state before changing associated platform schedules.
- Direct pause, bulk pause, timer removal, timer scheduling, and notification-setting changes keep notification side effects behind successful local persistence.
- Notification permission is requested at most once per controller session.
- Web notification permission is now requested through the web implementation when notification delivery is first needed.
- Disabling notifications cancels active platform schedules/runtime timers; enabling them reschedules running timers after settings persistence succeeds.
- Multi-step notification cancellation now continues through the full bounded notification-ID range even when one plugin cancellation fails.
- Android exact scheduling falls back to inexact scheduling if exact alarms cannot be used.
- Linux and Web are now first-class Countora targets for local completion notifications while their runtime remains active instead of having notification controls disabled outright.
- Future scheduled-notification capability remains explicit: Android, iOS, macOS, and Windows use native future scheduling; Linux/Web use runtime fallbacks; unsupported future targets fail closed.
- Settings keeps notification controls available on Linux/Web and explains their runtime-only delivery limitation rather than presenting those platforms as unsupported.
- Generated Android runner configuration now includes notification receivers, permissions, desugaring, and multidex setup through validated idempotent patch helpers.
- Settings backup/import/reset UI is safer and more explicit.
- Settings now listens directly to controller changes while its route is open and surfaces recoverable controller persistence errors without requiring navigation back to Home.
- Recoverable controller errors are displayed above the shared Home destination content, so Presets and History operations receive the same visible feedback as Timers.
- Clipboard backup export now surfaces a localized failure message instead of allowing a platform-channel exception to escape.
- Settings/About external links use a resilient launcher boundary that converts platform URL-launch failures into user-visible feedback.
- Timer-card semantics now announce the **Open focus mode** action instead of incorrectly announcing the inverse exit action before navigation.
- Main UI strings are externalized for future translations.
- CI now generates localization source, formats `integration_test/`, validates committed localization references before generation, builds Web, runs the primary Linux integration journey, and has a separate cross-platform build-smoke workflow for native targets.
- Tagged release quality gates now require a reviewed committed dependency lock and deterministic localization-source audit before `flutter pub get`/`flutter gen-l10n`, in addition to repository/version/secret/test/integration/documentation/build checks.

### Fixed

- Corrected the required-file audit to reference the repository's actual `0001-local-first-modular-flutter.md` ADR path.
- Prevented persistence failures from creating/cancelling notification schedules for state not durably saved.
- Prevented failed backup persistence from being reported as a successful import.
- Prevented generated-runner patching from silently succeeding when expected Flutter Android template anchors disappear.
- Prevented unsupported or unknown notification targets from being treated as future-scheduling capable by default.
- Prevented nested structured-log maps with non-`String` generic types from bypassing recursive sensitive-key redaction through stringification.
- Prevented timer/preset creation from exceeding the persistence collection limits and producing restart-time truncation surprises.
- Prevented a single notification-plugin cancellation exception from abandoning cleanup of later interval notification IDs.
- Prevented Presets/History controller failures from being hidden because the error banner existed only inside the Timers destination.
- Prevented the pushed Settings route from displaying stale controller values or hiding save failures until navigation returned to Home.

### Security

- Added bounded validation for untrusted imported JSON, including explicit identifier length limits.
- Expanded structured-log sanitization for nested maps/iterables and common credential/session/API/private-key key names.
- Added dependency-review failure threshold of moderate severity.
- Added redacting structured diagnostics.
- Added CodeQL analysis for GitHub Actions workflow source.
- Added deterministic repository audits to the tagged release gate.
- Added release artifact SHA-256 digests for post-download integrity checks.
- Kept signing keys and secrets outside version control.

### Known release requirements

- Do not tag the final 0.2.0 release until actual Flutter analyze/test/build/integration runs have been observed as successful.
- Generate dependency resolution with a real Flutter SDK, review it, and commit the resulting application `pubspec.lock`; the tagged release workflow now fails before `flutter pub get` when that reviewed lock is absent.
- Observe successful cross-platform smoke builds for Android, Linux, Windows, macOS, and unsigned iOS, plus the main Web build.
- Native/browser notification behavior must be verified on representative supported targets, including Linux/Web runtime fallback behavior.
- Signed mobile/desktop distribution remains a release-environment responsibility.
- Real screenshots must come from an actual verified build; mockups are not presented as product captures.

## [0.1.0] - 2026-08-19

Initial public development baseline.
