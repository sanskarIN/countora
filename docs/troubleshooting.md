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

Do not manually patch generated runner files as the long-term fix. Encode required native changes in `tool/bootstrap_platforms.dart` and its pure helpers under `tool/src/`. The platform-patch regression tests should be updated with any intentional template adaptation.

## Android notification does not appear

Check:

1. Countora notifications are enabled in Settings.
2. OS notification permission is granted.
3. The target Android version/device allows notification delivery.
4. Exact-alarm permission/state if the device exposes it.
5. Battery/background restrictions applied by the device vendor.

Countora attempts exact scheduling first and falls back to an inexact allow-while-idle mode if exact scheduling throws. This fallback improves delivery robustness but cannot override OS policy or vendor restrictions.

## Web or Linux does not show a background completion notification

Countora continues to run its timer model and in-app completion state on Web and Linux, but scheduled background completion notifications are currently disabled on those targets because the notification plugin/platform capability used by Countora does not provide future scheduled delivery there.

This is intentional defensive behavior: Countora avoids calling an unsupported scheduled-notification API and therefore avoids turning a normal timer operation into an unsupported-platform exception. Keep Countora open when an in-app completion cue is required on those targets.

Settings uses the same centralized capability policy as the notification adapter. On a target where future notification scheduling is unavailable, the completion-notification switch and its sound/vibration/quiet controls are disabled and the UI explains that in-app completion cues still work.

Countora also fails closed for native targets that are not explicitly included in the supported scheduled-notification set. A newly added platform must gain an intentional capability decision and regression coverage before the UI or service assumes scheduling is available.

## Notifications were disabled and old alerts still appear

Open Countora, disable completion notifications again, and verify the app has been allowed to run long enough to cancel stored timer schedules. Removing/resetting timers also cancels known scheduled IDs after the corresponding durable state change succeeds.

If a platform keeps a stale notification despite cancellation, capture the OS/version and file an issue with reproduction steps.

## Timer state looks stale after a long suspension

Return to the app. Countora reconciles running timers at startup and when the application resumes.

The live process uses a monotonic runtime clock, while persisted recovery uses UTC deadlines. A full process restart after a device clock edit necessarily interprets the saved UTC deadline using the device's current wall clock.

Reconciliation persists an advanced/completed timer state before applying dependent notification schedule changes. If local persistence fails, Countora reports the save problem and does not intentionally change those schedules for an unsaved reconciled state.

## Interval sequence skipped one or more steps after suspension

This can be expected if their absolute deadlines elapsed while Countora was suspended. Reconciliation consumes every elapsed step (up to the configured interval-step bound) so the sequence does not restart elapsed intervals merely because the UI was asleep.

## Import fails

Countora rejects backups when they are:

- empty
- larger than 2 MiB
- not a JSON object
- malformed JSON
- encoded with an unsupported future schema
- structurally invalid in a way that cannot be safely normalized

Import validation happens before current local data is replaced.

After validation/confirmation, the imported state is staged and reconciled before Countora attempts to persist the replacement. Existing notification schedules are not replaced until that persistence succeeds. If the staged import cannot be saved, Countora restores the previous in-memory state, leaves the previous schedules untouched, and reports import failure instead of reporting success.

If a backup is from a future Countora version, update Countora rather than manually editing its schema number.

## Local state was corrupted

Countora's SharedPreferences store falls back to an empty safe state if persisted JSON cannot be decoded safely. This prevents corruption from blocking startup.

Restore from a previously exported Countora backup if available.

## Saving shows an error banner

Countora keeps the in-memory operation visible but reports that local persistence failed. Avoid closing the app until the storage problem is resolved because the most recent change may not survive process termination.

State-dependent notification schedule changes are intentionally kept behind successful persistence. A failed save therefore does not intentionally create/cancel a notification for the unsaved state change.

Check available device storage and platform storage permissions/health, then retry the action.

## Full data reset does not complete

If the underlying local store cannot be cleared, Countora keeps in-memory data rather than pretending the reset succeeded and shows an error. Resolve the storage issue and retry.

## Backup export cannot copy to the clipboard

Countora reports the clipboard failure and leaves local timer data unchanged. Clipboard access can fail when the target platform, test environment, remote session, browser, or OS policy does not expose a writable clipboard.

Resolve the platform clipboard issue and retry. Do not erase local data until a required backup has been successfully copied and stored somewhere you control.

## A source/support link does not open

Countora catches URL-launch failures and shows a failure message instead of allowing a platform-channel error to escape into the UI. Confirm the platform has a default handler for the URI type and that browser/OS policy permits external launches.

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

If a dependency has changed, review dependency resolution and CI before changing constraints. Do not invent or hand-edit a lockfile; generate it through Flutter/Dart package resolution.

## CI formatting fails

Run exactly the CI command:

```bash
dart format lib test integration_test tool
```

Commit only the formatting changes that belong to the same logical code change.

## Linux integration CI fails to start a window

The repository CI executes the integration suite through a virtual X display:

```bash
xvfb-run -a flutter test integration_test -d linux -r github
```

Confirm Linux desktop support is enabled, GTK build dependencies are installed, Xvfb is available, platform runners were generated, dependencies resolved, and localization generated before the test command.

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
