# Roadmap

This roadmap distinguishes implemented source work from release verification. A checked implementation item does not imply that every native build or device behavior has already been observed as passing.

## 0.1 — Foundation

- [x] Local-first timer model
- [x] Multiple countdowns
- [x] Presets and groups
- [x] Interval sequences
- [x] History
- [x] Scheduled notifications on supported scheduling targets
- [x] Backup/restore
- [x] Responsive UI and accessibility baseline
- [x] Automated unit/controller tests
- [x] Repository documentation/community-health baseline

## 0.2 — Reliability, management, and polish

### Data and timing

- [x] Schema-aware backup codec and migration boundary
- [x] Codec-owned persistence schema version
- [x] Bounded untrusted backup validation
- [x] Corrupted local-state recovery
- [x] Monotonic in-process runtime clock
- [x] App-resume timer reconciliation
- [x] Interval catch-up without accumulated wake-up drift
- [x] Persistence-first notification side effects for timer mutations/reconciliation
- [x] Failed-import rollback before platform notification replacement
- [x] Notification exact-to-inexact fallback
- [x] Unsupported Web/Linux future-notification scheduling guard
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
- [x] Structured redacting diagnostics
- [x] Guarded URL-launch and clipboard failure handling
- [x] Responsive phone/desktop navigation
- [x] Dark/light/system themes and reduced motion

### Automated quality

- [x] State codec tests
- [x] Local persistence recovery tests
- [x] Stable clock tests
- [x] Expanded controller workflow tests
- [x] Persistence/notification consistency regression tests
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
- [x] Required-file contract protects critical docs, audit/release tooling, workflows, integration source, and issue-template configuration
- [x] Release-only committed dependency-lock audit and regression coverage
- [x] Dependency Review threshold
- [x] CodeQL workflow scan
- [x] Multi-platform tagged release workflow source
- [x] Tagged-release SHA-256 artifact checksum generation

### Still required before final 0.2 release

- [ ] Observe a successful CI run for formatting, analyze, tests, docs links, Web release build, and the Linux integration job
- [ ] Fix every concrete CI/compiler/test issue discovered by a real Flutter toolchain run
- [ ] Run the integration journey on a configured local/release Flutter target and record the result
- [ ] Run the state-codec benchmark on representative hardware and record environment/results
- [ ] Generate dependencies with a real supported Flutter SDK, review the resolved versions, and commit the resulting application `pubspec.lock`
- [ ] Verify `dart run tool/check_dependency_lock.dart` passes from the committed release-candidate checkout
- [ ] Verify Android notification permission/completion behavior on a real device/emulator
- [ ] Verify at least one desktop native build from the release workflow
- [ ] Verify Windows/macOS/iOS notification behavior on supported real environments before making platform-specific delivery claims
- [ ] Complete manual accessibility review with a real screen reader, keyboard-only navigation, reduced motion, and large text
- [ ] Capture real application screenshots from a verified build
- [ ] Run the final clean-checkout documentation/repository/release audit and record its successful output

## 1.0 — Stable release

- [ ] Validate Android production signing and Play distribution path
- [ ] Validate iOS signing/archive distribution path
- [ ] Validate macOS signing/notarization path
- [ ] Validate Windows distribution/signing approach
- [ ] Validate Linux packaging/distribution approach
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
