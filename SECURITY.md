# Security Policy

Countora is a local-first, account-free timer. Its security surface is smaller than a network service, but local state integrity, imported data, dependency integrity, platform permissions, build workflows, and release signing still require careful handling.

## Supported versions

Security fixes are prioritized for the latest supported release line and the current `main` branch while development is pre-1.0.

| Version | Security support |
| --- | --- |
| 0.2.x / current main | Supported during current development |
| 0.1.x | Update to the latest available build before reporting when possible |

## Reporting a vulnerability

Do **not** publish a security-sensitive issue with exploit details before maintainers can assess it.

Report suspected vulnerabilities to:

- `sanskarin@outlook.in`
- `supportramsandesh@gmail.com`

Include only the minimum safe information needed to reproduce and assess the issue:

- affected Countora version/commit
- affected platform/version
- vulnerability category
- reproducible steps or safe proof of concept
- expected vs actual security boundary
- realistic impact
- suggested mitigation if known

Do not attach real user backups, credentials, signing material, access tokens, private keys, or unrelated personal information.

## In scope

Examples include:

- malformed backup input escaping validation and causing unsafe behavior
- backup schema/migration paths that corrupt or expose data
- unintended disclosure of timer/backup contents through logging
- insecure handling of external links
- unsafe platform permission behavior
- committed credentials or signing material
- vulnerable dependency/workflow changes with a practical Countora impact
- GitHub Actions/release workflow injection or artifact integrity issues
- path/file handling issues introduced by future file import/export features

## Generally out of scope

Unless they demonstrate a real Countora security boundary failure:

- generic device compromise outside Countora
- issues requiring the reporter already to control the user's OS/account
- denial of service by manually deleting/modifying Countora's private app storage as the device owner
- social engineering unrelated to Countora source/releases
- theoretical dependency CVEs that are unreachable and have no practical Countora impact

## Current defensive controls

- No application account/authentication backend.
- Core timer data is local by default.
- Versioned and bounded backup decoding.
- Future backup schemas fail closed.
- Malformed field types are converted to controlled format errors.
- State-size/entity/identifier/duration/name/group caps.
- Controller creation paths enforce the same timer/preset collection caps as decoded persistence.
- Structured diagnostics redact sensitive key categories and log error types rather than raw backup/user content.
- Structured-log sanitization recursively handles nested maps/iterables, including generic platform maps, and bounds arbitrary scalar text before JSON encoding.
- `.env`, keystores, signing files, and generated credentials are ignored.
- Dependency Review blocks newly introduced moderate-or-higher dependency vulnerabilities on pull requests.
- CodeQL scans supported GitHub Actions workflow code.
- Dependabot configuration is present for dependency/workflow updates.
- Tagged release artifacts are produced only after the main release quality job succeeds.

## Coordinated disclosure

Please allow maintainers reasonable time to reproduce, patch, test, and publish a security fix before public disclosure. Timing depends on severity, platform complexity, and release verification requirements; no fixed response-time guarantee is promised.

If a report is valid, the preferred resolution is:

1. reproduce safely;
2. add a regression test where feasible;
3. implement the smallest secure fix;
4. run the full quality/security suite;
5. publish a patch release/advisory when appropriate;
6. document the security-relevant change without exposing unnecessary exploit detail.

## Release/signing secrets

Never commit:

- Android keystores or passwords
- Apple certificates/profiles/private keys
- Windows signing certificates/private keys
- GitHub tokens
- API tokens
- generated production secrets
- private environment files

Use protected release-environment secrets for signing/distribution.

## Public issue hygiene

If a bug report accidentally includes sensitive material, remove/rotate the affected secret or data exposure first, then move the security discussion to the private reporting addresses above.
