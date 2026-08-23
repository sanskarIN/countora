# Changelog

All notable Countora changes are documented here.

The format follows the spirit of Keep a Changelog and the project uses semantic versioning for release tags.

## [Unreleased]

### Added

- Multi-timer countdown engine with pause/resume/restart/add-time controls.
- Presets, groups, interval sequences, completion history, and search.
- Local persistence and JSON backup/restore.
- Scheduled/local completion notifications with sound/vibration/quiet controls using platform-appropriate delivery modes.
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
- Complete Hindi ARB localization and a persisted System/English/Hindi language selector that is included in local backup data.
- Localization catalog parity/identity auditing for missing, extra, blank, duplicate, or filename-mismatched locale resources.
- Cross-platform notification delivery tiers: scheduled background delivery on Android/iOS/macOS and package-identity Windows, runtime local-notification fallback on Linux/Web/portable Windows, and fail-closed handling for unsupported future targets.
- Cross-platform notification presentation details for Android, iOS, macOS, Linux, Windows, and Web.
- Explicit Web **Browser notification permission → Allow** Settings action so browser permission is requested directly from user activation instead of an automatic timer/reconciliation path.
- Windows MSIX package-identity build configuration with synchronized four-part package version metadata.
- Generated iOS notification-center delegate patch for foreground local-notification presentation.
- Generated Android AGP floor validation in addition to manifest/desugaring/multidex notification hardening.
- Persistence, state-codec, stable-clock, controller-workflow, controller-capacity, diagnostic-redaction, notification-cleanup, runtime-deadline, Web-permission, notification-presentation, home-error-surface, Settings-reactivity, widget, localization, external-link, platform-capability, platform-patch, version/MSIX, dependency-lock, and integration regression tests.
- Deterministic state-codec benchmark harness with machine-readable latency summaries.
- ADR 0005 documenting durable-state-before-platform-side-effect ordering.
- Markdown local-link checker.
- Release-only committed dependency-lock audit that rejects missing/empty/malformed `pubspec.lock` metadata before dependency resolution.
- Deterministic localization-source audit enforced by repository audit, normal CI, and tagged release CI before generated localization code is created.
- Expanded required-file contract protecting repository audit, release tooling, localization/backup/diagnostic audit tooling, critical docs, branding source, integration journey source, core model/state/controller regressions, important UI/cross-platform regressions, and issue-template configuration.
- CodeQL scan for supported GitHub Actions code.
- Multi-platform tagged release jobs for Android, Web, Linux, portable Windows, macOS, and unsigned iOS verification, with Windows MSIX packaging verification.
- Dedicated non-tagged platform-smoke workflow compiling Android, Linux, portable Windows, Windows MSIX, macOS, and unsigned iOS targets on their appropriate GitHub-hosted runners.
- Dedicated Linux/Xvfb integration-test CI job for the primary end-to-end journey.
- SHA-256 checksum files for tagged Android/Web, Linux, portable Windows, macOS, and unsigned iOS artifacts.

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
- Native notification permission is requested at most once per controller session where that automatic native path applies.
- Web notification permission is no longer requested automatically by `LocalNotificationService.requestPermissions()`; the explicit Settings button owns the browser user-gesture boundary.
- Disabling notifications cancels active platform schedules/runtime timers; enabling them reschedules running timers after settings persistence succeeds.
- Sound, vibration, and quiet-mode changes reschedule running notifications when needed, while theme, language, compact-card, reduced-motion, and onboarding changes no longer churn notification schedules.
- Multi-step notification cancellation now continues through the full bounded notification-ID range even when one plugin cancellation fails.
- Android exact scheduling falls back to inexact scheduling if exact alarms cannot be used.
- Linux, Web, and portable Windows use runtime local-notification fallback instead of being treated as unsupported notification targets.
- Windows future scheduling is now package-identity aware: portable builds default to runtime delivery, while the MSIX build sets `COUNTORA_WINDOWS_PACKAGED=true` for scheduled delivery.
- Settings keeps notification controls available on runtime-only targets and explains their delivery limitation rather than presenting those targets as unsupported.
- Generated Android runner configuration now includes notification receivers, permissions, desugaring, multidex, and an AGP 8.11.1 minimum transform that leaves newer generated versions untouched.
- Generated iOS runner configuration now adds `UserNotifications` and installs the notification-center delegate before generated plugin registration.
- Windows `msix_version` is checked by the central version audit and must map `MAJOR.MINOR.PATCH+BUILD` to `MAJOR.MINOR.PATCH.BUILD`.
- Windows smoke/release jobs now verify both portable compilation and MSIX package-identity creation; the portable ZIP remains the published CI artifact until a production MSIX signing/store strategy is configured.
- Settings backup/import/reset UI is safer and more explicit.
- Settings now listens directly to controller changes while its route is open and surfaces recoverable controller persistence errors without requiring navigation back to Home.
- Settings language changes apply immediately, persist locally, and fall back safely to the system locale for older or unknown preference values.
- Recoverable controller errors are displayed above the shared Home destination content, so Presets and History operations receive the same visible feedback as Timers.
- Clipboard backup export now surfaces a localized failure message instead of allowing a platform-channel exception to escape.
- Settings/About external links use a resilient launcher boundary that converts platform URL-launch failures into user-visible feedback.
- Timer-card semantics now announce the **Open focus mode** action instead of incorrectly announcing the inverse exit action before navigation.
- Main UI strings are externalized for future translations.
- CI now generates localization source, formats `integration_test/`, validates committed localization references and every translated catalog before generation, builds Web, runs the primary Linux integration journey, and has a separate cross-platform build/package smoke workflow for native targets.
- Tagged release quality gates now require a reviewed committed dependency lock and deterministic localization-source audit before `flutter pub get`/`flutter gen-l10n`, in addition to repository/version/secret/test/integration/documentation/build checks.

### Fixed

- Corrected the required-file audit to reference the repository's actual `0001-local-first-modular-flutter.md` ADR path.
- Prevented persistence failures from creating/cancelling notification schedules for state not durably saved.
- Prevented failed backup persistence from being reported as a successful import.
- Prevented generated-runner patching from silently succeeding when expected Flutter Android/iOS template anchors disappear.
- Prevented unsupported or unknown notification targets from being treated as future-scheduling capable by default.
- Prevented portable Windows builds from claiming scheduled notification semantics that depend on Windows package identity.
- Prevented a due runtime completion notification callback from being cancelled by controller reconciliation at the exact deadline.
- Prevented automatic/startup/reconciliation paths from attempting the Web permission prompt outside a direct browser user interaction.
- Prevented nested structured-log maps with non-`String` generic types from bypassing recursive sensitive-key redaction through stringification.
- Prevented timer/preset creation from exceeding the persistence collection limits and producing restart-time truncation surprises.
- Prevented a single notification-plugin cancellation exception from abandoning cleanup of later interval notification IDs.
- Prevented Presets/History controller failures from being hidden because the error banner existed only inside the Timers destination.
- Prevented the pushed Settings route from displaying stale controller values or hiding save failures until navigation returned to Home.
- Kept the language dropdown synchronized when backup import or another external settings change updates the persisted language while Settings remains open.
- Updated the Linux runtime-notification regression copy to match the current distribution-mode wording.

### Security

- Added bounded validation for untrusted imported JSON, including explicit identifier length limits.
- Expanded structured-log sanitization for nested maps/iterables and common credential/session/API/private-key key names.
- Added package-aware Windows notification policy so unpackaged builds do not rely on package-identity-only cancellation behavior.
- Added MSIX version synchronization and kept production certificate/store signing external to source control.
- Kept Web notification permission behind a direct, explicit user action rather than silently prompting from automatic timer lifecycle code.
- Added dependency-review failure threshold of moderate severity.
- Added redacting structured diagnostics.
- Added CodeQL analysis for GitHub Actions workflow source.
- Added deterministic repository audits to the tagged release gate.
- Added release artifact SHA-256 digests for post-download integrity checks.
- Kept signing keys, certificates, and secrets outside version control.

### Known release requirements

- Do not tag the final 0.2.0 release until actual Flutter analyze/test/build/integration runs have been observed as successful.
- Generate dependency resolution with a real Flutter SDK, review it, and commit the resulting application `pubspec.lock`; the tagged release workflow fails before `flutter pub get` when that reviewed lock is absent.
- Observe successful cross-platform smoke builds for Android, Linux, portable Windows, Windows MSIX packaging, macOS, and unsigned iOS, plus the main Web build.
- Native/browser notification behavior must be verified on representative supported targets, including Web direct permission-button behavior, Linux/Web/portable-Windows runtime fallback, and package-identity Windows scheduled behavior.
- Production MSIX signing or Microsoft Store distribution must be configured before promoting the packaged Windows build publicly.
- Signed mobile/desktop distribution remains a release-environment responsibility.
- Real screenshots must come from actual verified builds; mockups are not presented as product captures.

## [0.1.0] - 2026-08-19

Initial public development baseline.