# Countora 2.15.18 release candidate

Status: **release candidate — not yet published**

Package version: `2.15.18+18`

Windows MSIX version: `2.15.18.18`

Release tag reserved after verification: `v2.15.18`

## Release-candidate goals

Countora 2.15.18 carries forward the local-first multi-timer product and cross-platform support while tightening the release pipeline around a pinned, reproducible Flutter toolchain.

The release candidate is intentionally prepared from current `main` rather than from the older divergent Phase 6 verification branches.

## Release engineering completed in this candidate

- Flutter CI toolchain pinned to `3.47.1`.
- Package, runtime metadata, changelog, and Windows MSIX versions synchronized.
- Generated platform runners use `flutter create --no-pub`.
- Protected root files are snapshotted and restored byte-for-byte around runner generation.
- Root-file preservation and bootstrap-argument regression tests added.
- iOS runner patch supports both the legacy AppDelegate template and the Flutter 3.47 UIScene/implicit-engine template.
- Deterministic toolchain audit verifies one pinned stable cached Flutter version and rejects workflow bypasses.
- Release branches run the main CI, repository audit, platform-smoke matrix, and dependency-lock refresh workflow.
- Dependency-lock refresh rejects unexpected tracked changes before committing the reviewed lockfile.

## Required automated verification

Before the candidate can be tagged:

- [ ] dependency lock generated and committed by the pinned Flutter toolchain
- [ ] dependency-lock audit passes from the committed checkout
- [ ] localization source/catalog audit passes
- [ ] formatting check passes
- [ ] `flutter analyze` passes
- [ ] full Flutter test suite passes
- [ ] required-file/version/toolchain/secret/link audits pass
- [ ] Web release build passes
- [ ] Linux/Xvfb integration journey passes
- [ ] Android smoke build passes
- [ ] Linux smoke build passes
- [ ] portable Windows smoke build passes
- [ ] Windows MSIX creation passes
- [ ] macOS smoke build passes
- [ ] unsigned iOS smoke build passes

## Required manual/platform verification

- [ ] Android notification permission/completion and exact-alarm denial fallback
- [ ] iOS foreground/background notification behavior on a signed supported environment
- [ ] macOS notification behavior on a representative release-like environment
- [ ] portable Windows runtime notification behavior
- [ ] installed package-identity Windows scheduling/cancellation behavior
- [ ] Linux runtime notification and resume/restart reconciliation
- [ ] Web notification permission denial/grant, runtime completion, reload, and page suspension behavior
- [ ] screen-reader, keyboard-only, reduced-motion, and large-text review
- [ ] state-codec benchmark recorded on representative hardware
- [ ] real screenshots captured from verified builds
- [ ] final clean-checkout release audit recorded

## Distribution work that remains outside source verification

Production publishing still requires the appropriate signing/distribution environment for Android, iOS, macOS, and packaged Windows. Linux packaging and Web hosting/deployment behavior also require final distribution validation.

Do not create `v2.15.18` while the changelog entry is marked as an unreleased release candidate.
