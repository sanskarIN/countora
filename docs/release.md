# Release

## Release candidate checklist

1. Use a clean clone.
2. Run `dart run tool/bootstrap_platforms.dart`.
3. Run `flutter pub get`.
4. Run formatting, analysis, and tests.
5. Build Web and each native target on its supported host.
6. Review dependency, secret-scanning, and security-workflow results.
7. Confirm no credentials/signing secrets are tracked.
8. Update `CHANGELOG.md` and version in `pubspec.yaml`.
9. Tag `vX.Y.Z`.
10. Publish release artifacts produced by trusted CI or release hosts.

Never commit private signing keys. Use protected CI secrets for release signing.
