# Roadmap

This roadmap distinguishes implemented source work from release verification. A checked implementation item does not imply that every native build, browser behavior, notification path, signing path, or device behavior has already been observed as passing.

## 0.1 — Foundation

- [x] Local-first timer model
- [x] Multiple countdowns
- [x] Presets and groups
- [x] Interval sequences
- [x] History
- [x] Notifications through platform-appropriate delivery paths
- [x] Backup/restore
- [x] Responsive UI and accessibility baseline
- [x] Automated unit/controller tests
- [x] Repository documentation/community-health baseline

## 0.2 — Reliability, management, polish, and cross-platform support

### Data and timing

- [x] Schema-aware backup codec and migration boundary
- [x] Codec-owned persistence schema version
- [x] Bounded untrusted backup validation, including explicit imported identifier limits
- [x] Corrupted local-state recovery
- [x] Controller timer/preset creation aligned with persisted collection limits
- [x] Monotonic in-process runtime clock
- [x] App-resume timer reconciliation
- [x] Interval catch-up without accumulated wake-up drift
- [x] Persistence-first notification side effects for timer mutations/reconciliation
- [x] Failed-import rollback before platform notification replacement
- [x] Android exact-to-inexact scheduling fallback
- [x] Bounded notification cleanup continues after per-ID plugin failures
- [x] Explicit notification delivery tiers instead of a binary supported/unsupported flag
- [x] Scheduled future notifications on Android, iOS, macOS, and Windows
- [x] Runtime local-notification fallback on Linux and Web
- [x] Web notification-permission request path
- [x] Unsupported future targets fail closed
- [x] Generated Android notification configuration hardening
- [x] Validated/idempotent generated Android patch helpers

### Product workflows

- [x] Duplicate timer
- [x] Rename/move timer
- [x] Save timer as preset
- [x] Replay from history
- [x] Bulk pause/resume/remove-completed
- [x] Safer backup import preview
- [x] Full local-data reset
- [x] Advanced interval editor ordering and labels
- [x] Richer focus mode controls
- [x] Desktop keyboard shortcuts

### UX/platform quality

- [x] Shared design tokens
- [x] Main accessibility semantics improvements
- [x] Correct focus-mode entry/exit semantics copy
- [x] English generated-localization architecture
- [x] Structured redacting diagnostics with recursive nested-map/iterable sanitization
- [x] Guarded URL-launch and clipboard failure handling
- [x] Recoverable controller errors visible across Timers, Presets, and History
- [x] Settings listens to live controller changes and surfaces persistence failures
- [x] Responsive phone/tablet/desktop/Web navigation
- [x] Dark/light/system themes and reduced motion
- [x] Notification controls available on all six supported Countora targets where local notifications are available
- [x] Linux/Web UI clearly distinguishes runtime delivery from guaranteed future background scheduling
- [x] Android/iOS/macOS/Linux/Windows/Web notification presentation configuration

### Automated quality

- [x] State codec tests
- [x] Local persistence recovery tests
- [x] Stable clock tests
- [x] Expanded controller workflow tests
- [x] Controller collection-cap regression tests
- [x] Persistence/notification consistency regression tests
- [x] Notification cleanup continuation regression tests
- [x] Cross-platform notification capability-tier tests
- [x] Cross-platform notification presentation-detail tests
- [x] Notification initialization coverage for all six adapters
- [x] Recursive diagnostic-redaction regression tests
- [x] Global Home error-surface regression test
- [x] Settings reactivity/save-error regression test
- [x] Linux runtime-notification Settings regression coverage
- [x] Unsupported-target fail-closed Settings regression coverage
- [x] Platform patch regression tests
- [x] External-link failure regression tests
- [x] Primary widget journey tests
- [x] Focus-mode semantics widget regression
- [x] Primary integration journey source
- [x] Dedicated Linux/Xvfb integration CI job source
- [x] Localization tests
- [x] Deterministic localization-source audit before generated localization code
- [x] Localization-source audit enforced in repository audit, normal CI, and tagged release CI
- [x] Deterministic state-codec performance benchmark harness
- [x] Documentation local-link checker
- [x] Required-file/version/secret repository audit tooling
- [x] Required-file contract protects critical docs, audit/release tooling, workflows, important regression tests, integration source, branding, and issue-template configuration
- [x] Release-only committed dependency-lock audit and regression coverage
- [x] Dependency Review threshold
- [x] CodeQL workflow scan
- [x] Non-tagged native platform-smoke workflow source for Android, Linux, Windows, macOS, and unsigned iOS
- [x] Main CI Web release build source
- [x] Multi-platform tagged release workflow source
- [x] Tagged-release SHA-256 artifact checksum generation

### Still required before final 0.2 release

- [ ] Observe a successful main CI run for localization audit, formatting, analyze, tests, docs links, Web release build, and Linux integration journey
- [ ] Observe successful `Platform smoke` jobs for Android, Linux, Windows, macOS, and unsigned iOS
- [ ] Fix every concrete CI/compiler/test issue discovered by real Flutter toolchain runs
- [ ] Run the integration journey on a configured local/release Flutter target and record the result
- [ ] Run the state-codec benchmark on representative hardware and record environment/results
- [ ] Generate dependencies with a real supported Flutter SDK, review the resolved versions, and commit the resulting application `pubspec.lock`
- [ ] Verify `dart run tool/check_dependency_lock.dart` passes from the committed release-candidate checkout
- [ ] Verify Android notification permission/completion behavior on a real device/emulator
- [ ] Verify iOS and macOS notification behavior on supported Apple environments
- [ ] Verify Windows toast scheduling/cancellation on a representative packaged or release-like environment
- [ ] Verify Linux desktop notification delivery while Countora remains active and reconciliation after process suspension/restart
- [ ] Verify Web browser notification permission, runtime completion notification delivery, and reconciliation after page suspension/reload in representative browsers
- [ ] Record clearly that Linux/Web cannot guarantee future notification delivery after the Countora process/page is terminated
- [ ] Complete manual accessibility review with a real screen reader, keyboard-only navigation, reduced motion, and large text
- [ ] Capture real application screenshots from verified builds
- [ ] Run the final clean-checkout documentation/repository/release audit and record its successful output

## 1.0 — Stable release

- [ ] Validate Android production signing and Play distribution path
- [ ] Validate iOS signing/archive distribution path
- [ ] Validate macOS signing/notarization path
- [ ] Validate Windows distribution/signing approach
- [ ] Validate Linux packaging/distribution approach
- [ ] Validate Web deployment/hosting headers and browser-permission behavior
- [ ] Final dependency/security audit
- [ ] Final accessibility manual review with screen reader/keyboard/scaled text
- [ ] Final clean-checkout release candidate
- [ ] Final backup compatibility/migration review
- [ ] Publish verified screenshots and release notes

## Later candidates

These are deliberately not part of 0.2 unless they can be added without compromising reliability or simplicity:

- additional translated locales
- optional home-screen/platform widgets where native support is justified
- richer preset analytics that remain entirely local
- additional notification actions where platform APIs can be implemented consistently
- import/export through native file pickers in addition to clipboard workflows
- stable visual golden tests after the UI is no longer changing rapidly
