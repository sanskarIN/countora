# Localization

Countora uses Flutter generated localizations with ARB source files in `lib/l10n`.

## Supported languages

Current source catalogs:

- English (`en`) — template and fallback source
- Hindi (`hi`) — complete translated catalog

By default, Countora follows the operating system or browser locale through Flutter's normal locale resolution. Regional variants such as `hi-IN` resolve to the supported Hindi language catalog when Flutter performs language matching.

Settings also exposes a persisted language preference with three choices:

- System language
- English
- Hindi

An explicit English or Hindi selection overrides the device locale. The preference is stored in Countora's local state and is included in normal Countora backup/export data. Older backups that do not contain the preference safely fall back to System language.

## Source of truth

`lib/l10n/app_en.arb` is the template catalog configured by `l10n.yaml`.

Every translated `app_*.arb` catalog must:

- contain valid JSON;
- declare a non-empty `@@locale`;
- match the locale encoded in its filename;
- avoid declaring a locale already owned by another catalog;
- contain every message key from `app_en.arb`;
- contain no message keys that are absent from the English template;
- use a non-empty string for every translated message.

`dart run tool/check_localization_source.dart` validates those rules before generated localization code is trusted.

The same audit also scans Countora Dart source for `strings.<message>` and `context.l10n.<message>` references and fails when code refers to a message missing from the English template.

## Adding a language

1. Copy the English message-key set into `lib/l10n/app_<locale>.arb`.
2. Set `@@locale` to the intended locale code and keep it synchronized with the filename.
3. Translate every user-visible message without changing message keys.
4. Add the locale to `CountoraLanguage` only when it should appear as an explicit Settings choice; system locale resolution can still use generated supported locales independently.
5. Run `dart run tool/check_localization_source.dart`.
6. Run `flutter gen-l10n`.
7. Add focused assertions to `test/localization_test.dart` for core navigation, Settings, backup, notification, and accessibility copy.
8. Add or update language-selection persistence/widget coverage when the locale becomes a manual Settings choice.
9. Run `flutter test test/localization_audit_test.dart test/localization_test.dart test/app_language_test.dart test/settings_page_test.dart`.
10. Run the normal Countora quality suite before merging or tagging a release.

Do not edit generated `app_localizations*.dart` files manually. They are regenerated from ARB source.

## Translation quality

Translations should preserve product meaning rather than copy English word order mechanically. Keep technical names such as Countora, GitHub, JSON, Ctrl/Cmd shortcuts, and platform names recognizable where translating them would reduce clarity.

Notification capability wording must remain precise: runtime-only platforms must not imply guaranteed delivery after the Countora process or browser page is gone.

Backup/import wording must not imply cloud storage or automatic upload. Countora remains local-first unless the user explicitly exports data.

## Review checklist

For each changed locale:

- verify all keys still match the English template;
- verify the ARB filename, `@@locale`, and manual language enum choice stay synchronized where applicable;
- review punctuation and terminology consistency;
- check long labels on narrow phone layouts;
- check large-text accessibility;
- verify right-to-left behavior separately before introducing an RTL locale;
- verify notification, backup, destructive-action, and permission wording especially carefully;
- verify generated localization tests on the repository-approved Flutter toolchain.
