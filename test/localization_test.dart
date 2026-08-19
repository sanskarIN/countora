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
  });

  test('English is a supported application locale', () {
    expect(
      AppLocalizations.supportedLocales,
      contains(const Locale('en')),
    );
  });
}
