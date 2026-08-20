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
    expect(
      strings.backupExportFailed,
      'Could not copy the backup. Your local Countora data was unchanged.',
    );
    expect(
      strings.completionNotificationsHelp,
      'Use scheduled platform notifications where supported so countdowns can '
      'alert you while Countora is not in the foreground.',
    );
    expect(
      strings.completionNotificationsUnavailable,
      'Future background scheduling is not available on this platform. '
      'Countora can still deliver local completion notifications while its '
      'runtime remains active, and in-app state plus visual completion cues '
      'reconcile when you return.',
    );
  });

  test('English is a supported application locale', () {
    expect(
      AppLocalizations.supportedLocales,
      contains(const Locale('en')),
    );
  });
}
