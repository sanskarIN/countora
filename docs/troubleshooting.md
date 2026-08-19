# Troubleshooting

Start with:

```bash
flutter doctor -v
flutter --version
```

Resolve host/toolchain issues relevant to your target before assuming the Countora source is responsible.

## Platform folders are missing

This is expected after cloning because generated runner folders are ignored.

Run:

```bash
dart run tool/bootstrap_platforms.dart
```

Then:

```bash
flutter pub get
flutter gen-l10n
```

## Generated localization file is missing

Run:

```bash
flutter gen-l10n
```

The generated `app_localizations*.dart` files are intentionally not committed.

If generation fails, confirm `pubspec.yaml`, `l10n.yaml`, and `lib/l10n/app_en.arb` are valid and that your Flutter stable SDK supports the declared Dart constraint.

## `flutter analyze` reports errors after a Flutter upgrade

Regenerate the runner files and dependencies from a clean working tree:

```bash
rm -rf .dart_tool build
# On Windows remove the same directories with File Explorer/PowerShell.
dart run tool/bootstrap_platforms.dart
flutter pub get
flutter gen-l10n
flutter analyze
```

Do not manually patch generated runner files as the long-term fix. Encode required native changes in `tool/bootstrap_platforms.dart`.

## Android notification does not appear

Check:

1. Countora notifications are enabled in Settings.
2. OS notification permission is granted.
3. The target Android version/device allows notification delivery.
4. Exact-alarm permission/state if the device exposes it.
5. Battery/background restrictions applied by the device vendor.

Countora attempts exact scheduling first and falls back to an inexact allow-while-idle mode if exact scheduling throws. This fallback improves delivery robustness but cannot override OS policy or vendor restrictions.

## Notifications were disabled and old alerts still appear

Open Countora, disable completion notifications again, and verify the app has been allowed to run long enough to cancel stored timer schedules. Removing/resetting timers also cancels known scheduled IDs.

If a platform keeps a stale notification despite cancellation, capture the OS/version and file an issue with reproduction steps.

## Timer state looks stale after a long suspension

Return to the app. Countora reconciles running timers at startup and when the application resumes.

The live process uses a monotonic runtime clock, while persisted recovery uses UTC deadlines. A full process restart after a device clock edit necessarily interprets the saved UTC deadline using the device's current wall clock.

## Interval sequence skipped one or more steps after suspension

This can be expected if their absolute deadlines elapsed while Countora was suspended. Reconciliation consumes every elapsed step (up to the 32-step bound) so the sequence does not restart elapsed intervals merely because the UI was asleep.

## Import fails

Countora rejects backups when they are:

- empty
- larger than 2 MiB
- not a JSON object
- malformed JSON
- encoded with an unsupported future schema
- structurally invalid in a way that cannot be safely normalized

Import validation happens before current local data is replaced.

If a backup is from a future Countora version, update Countora rather than manually editing its schema number.

## Local state was corrupted

Countora's SharedPreferences store falls back to an empty safe state if persisted JSON cannot be decoded safely. This prevents corruption from blocking startup.

Restore from a previously exported Countora backup if available.

## Saving shows an error banner

Countora keeps the in-memory operation visible but reports that local persistence failed. Avoid closing the app until the storage problem is resolved because the most recent change may not survive process termination.

Check available device storage and platform storage permissions/health, then retry the action.

## Full data reset does not complete

If the underlying local store cannot be cleared, Countora keeps in-memory data rather than pretending the reset succeeded and shows an error. Resolve the storage issue and retry.

## Desktop shortcut does not fire

Use the main application window and ensure a platform/system shortcut is not intercepting the key combination.

Supported application shortcuts:

- `Ctrl/Cmd + N`
- `Ctrl/Cmd + F`
- `Ctrl/Cmd + ,`

All associated actions remain available through visible controls.

## Web build fails

Regenerate runners and localization, then try:

```bash
dart run tool/bootstrap_platforms.dart
flutter pub get
flutter gen-l10n
flutter build web --release
```

If a dependency has changed, review `pubspec.lock`/dependency resolution and CI before changing constraints.

## CI formatting fails

Run exactly the CI command:

```bash
dart format lib test integration_test tool
```

Commit only the formatting changes that belong to the same logical code change.

## Markdown link check fails

Run:

```bash
dart run tool/check_markdown_links.dart
```

The checker validates local repository links. External links are intentionally not fetched so documentation checks remain deterministic/offline.

## Still stuck

Open a public issue at the repository issue tracker with:

- Countora version/commit
- Flutter version
- OS/platform version
- relevant `flutter doctor -v` section
- exact reproduction steps
- expected behavior
- actual behavior
- safe logs with secrets/user data removed

Do not post signing keys, backup contents, personal timer data, tokens, or credentials in an issue.
