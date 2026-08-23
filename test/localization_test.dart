import 'package:countora/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English localization exposes core Countora copy', () async {
    final strings = await AppLocalizations.delegate.load(const Locale('en'));

    expect(strings.appName, 'Countora');
    expect(strings.timers, 'Timers');
    expect(strings.presets, 'Presets');
    expect(strings.history, 'History');
    expect(strings.madeBySanskar, 'Made by the Sanskar');
    expect(strings.importLocalBackup, 'Import local backup');
    expect(strings.openFocusMode, 'Open focus mode');
    expect(strings.exitFocusMode, 'Exit focus mode');
    expect(strings.language, 'Language');
    expect(strings.systemLanguage, 'System language');
    expect(strings.englishLanguage, 'English');
    expect(strings.hindiLanguage, 'Hindi');
    expect(
      strings.backupExportFailed,
      'Could not copy the backup. Your local Countora data was unchanged.',
    );
    expect(
      strings.browserNotificationPermission,
      'Browser notification permission',
    );
    expect(
      strings.browserNotificationPermissionHelp,
      'Browsers require notification permission to be requested directly from '
      'a button press. Allow it here before relying on Web completion '
      'notifications.',
    );
    expect(
      strings.completionNotificationsHelp,
      'Use scheduled platform notifications where supported so countdowns can '
      'alert you while Countora is not in the foreground.',
    );
    expect(
      strings.completionNotificationsUnavailable,
      'Future background scheduling is not available on this platform or '
      'distribution mode. Countora can still deliver local completion '
      'notifications while its runtime remains active, and in-app state plus '
      'visual completion cues reconcile when you return.',
    );
  });

  test('Hindi localization exposes core Countora copy', () async {
    final strings = await AppLocalizations.delegate.load(const Locale('hi'));

    expect(strings.appName, 'Countora');
    expect(strings.timers, 'टाइमर');
    expect(strings.presets, 'प्रीसेट');
    expect(strings.history, 'इतिहास');
    expect(strings.settings, 'सेटिंग्स');
    expect(strings.language, 'भाषा');
    expect(strings.systemLanguage, 'सिस्टम भाषा');
    expect(strings.englishLanguage, 'अंग्रेज़ी');
    expect(strings.hindiLanguage, 'हिन्दी');
    expect(strings.openFocusMode, 'फोकस मोड खोलें');
    expect(strings.exitFocusMode, 'फोकस मोड से बाहर आएँ');
  });

  test('English and Hindi are supported application locales', () {
    expect(
      AppLocalizations.supportedLocales,
      containsAll(<Locale>[const Locale('en'), const Locale('hi')]),
    );
  });

  test('regional English and Hindi locales resolve through language support', () {
    expect(AppLocalizations.delegate.isSupported(const Locale('en', 'IN')), isTrue);
    expect(AppLocalizations.delegate.isSupported(const Locale('hi', 'IN')), isTrue);
  });
}
