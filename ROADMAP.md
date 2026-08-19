# Roadmap

This roadmap distinguishes implemented source work from release verification. A checked implementation item does not imply that every native build or device behavior has already been observed as passing.

## 0.1 — Foundation

- [x] Local-first timer model
- [x] Multiple countdowns
- [x] Presets and groups
- [x] Interval sequences
- [x] History
- [x] Scheduled notifications
- [x] Backup/restore
- [x] Responsive UI and accessibility baseline
- [x] Automated unit/controller tests
- [x] Repository documentation/community-health baseline

## 0.2 — Reliability, management, and polish

### Data and timing

- [x] Schema-aware backup codec and migration boundary
- [x] Bounded untrusted backup validation
- [x] Corrupted local-state recovery
- [x] Monotonic in-process runtime clock
- [x] App-resume timer reconciliation
- [x] Interval catch-up without accumulated wake-up drift
- [x] Notification exact-to-inexact fallback
- [x] Generated Android notification configuration hardening

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
- [x] English generated-localization architecture
- [x] Structured redacting diagnostics
- [x] Responsive phone/desktop navigation
- [x] Dark/light/system themes and reduced motion

### Automated quality

- [x] State codec tests
- [x] Local persistence recovery tests
- [x] Stable clock tests
- [x] Expanded controller workflow tests
- [x] Primary widget journey tests
- [x] Primary integration journey source
- [x] Localization tests
- [x] Documentation local-link checker
- [x] Dependency Review threshold
- [x] CodeQL workflow scan
- [x] Multi-platform tagged release workflow source

### Still required before final 0.2 release

- [ ] Observe a successful CI run for formatting, analyze, tests, docs links, and Web release build
- [ ] Fix every concrete CI/compiler/test issue discovered
- [ ] Run integration journey on a configured Flutter target
- [ ] Verify Android notification permission/completion behavior on a real device/emulator
- [ ] Verify at least one desktop native build from the release workflow
- [ ] Capture real application screenshots from a verified build
- [ ] Complete final documentation/release audit

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
