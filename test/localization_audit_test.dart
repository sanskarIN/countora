import 'package:flutter_test/flutter_test.dart';

import '../tool/src/localization_audit.dart';

void main() {
  const completeArb = <String, Object?>{
    '@@locale': 'en',
    'appName': 'Countora',
    'settings': 'Settings',
    'timers': 'Timers',
    'presets': 'Presets',
    'history': 'History',
    'openFocusMode': 'Open focus mode',
    'exitFocusMode': 'Exit focus mode',
    'completionNotificationsUnavailable': 'Unavailable',
    'backupExportFailed': 'Backup failed',
  };

  test('accepts required messages and referenced keys', () {
    final result = auditLocalizationSources(
      arb: completeArb,
      dartSources: const <String, String>{
        'lib/example.dart': '''
final title = strings.appName;
final action = context.l10n.openFocusMode;
''',
      },
    );

    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
  });

  test('reports missing referenced localization keys', () {
    final result = auditLocalizationSources(
      arb: completeArb,
      dartSources: const <String, String>{
        'lib/example.dart': 'final value = strings.missingMessage;',
      },
    );

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('missingMessage'));
    expect(result.errors.single, contains('lib/example.dart'));
  });

  test('reports invalid locale and blank messages', () {
    final arb = <String, Object?>{
      ...completeArb,
      '@@locale': 'fr',
      'settings': '   ',
    };

    final result = auditLocalizationSources(
      arb: arb,
      dartSources: const <String, String>{},
    );

    expect(result.isValid, isFalse);
    expect(
      result.errors,
      contains('lib/l10n/app_en.arb must declare @@locale as "en".'),
    );
    expect(result.errors.any((error) => error.contains('"settings"')), isTrue);
  });

  test('rejects keys that collide with generated AppLocalizations members', () {
    final arb = <String, Object?>{...completeArb, 'of': 'of'};

    final result = auditLocalizationSources(
      arb: arb,
      dartSources: const <String, String>{},
    );

    expect(result.isValid, isFalse);
    expect(
      result.errors,
      contains(
        'Localization message "of" collides with a generated '
        'AppLocalizations API member.',
      ),
    );
  });

  test('accepts a non-conflicting replacement for a reserved label', () {
    final arb = <String, Object?>{...completeArb, 'ofLabel': 'of'};

    final result = auditLocalizationSources(
      arb: arb,
      dartSources: const <String, String>{
        'lib/example.dart': 'final value = strings.ofLabel;',
      },
    );

    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
  });

  test('accepts locale catalogs with template key parity', () {
    final result = auditLocaleCatalogs(
      templateArb: const <String, Object?>{
        '@@locale': 'en',
        'appName': 'Countora',
        'settings': 'Settings',
      },
      localeArbs: const <String, Map<String, Object?>>{
        'lib/l10n/app_hi.arb': <String, Object?>{
          '@@locale': 'hi',
          'appName': 'Countora',
          'settings': 'सेटिंग्स',
        },
      },
    );

    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
  });

  test('reports missing, extra, blank, and invalid locale catalog entries', () {
    final result = auditLocaleCatalogs(
      templateArb: const <String, Object?>{
        '@@locale': 'en',
        'appName': 'Countora',
        'settings': 'Settings',
      },
      localeArbs: const <String, Map<String, Object?>>{
        'lib/l10n/app_hi.arb': <String, Object?>{
          '@@locale': '',
          'appName': '   ',
          'unknown': 'अतिरिक्त',
        },
      },
    );

    expect(result.isValid, isFalse);
    expect(
      result.errors.any((error) => error.contains('non-empty @@locale')),
      isTrue,
    );
    expect(
      result.errors.any(
        (error) => error.contains('missing localization message "settings"'),
      ),
      isTrue,
    );
    expect(
      result.errors.any(
        (error) => error.contains('unknown localization message "unknown"'),
      ),
      isTrue,
    );
    expect(
      result.errors.any(
        (error) =>
            error.contains('localization message "appName" must be non-empty'),
      ),
      isTrue,
    );
  });

  test(
    'reports filename locale mismatch and duplicate locale declarations',
    () {
      final result = auditLocaleCatalogs(
        templateArb: const <String, Object?>{
          '@@locale': 'en',
          'appName': 'Countora',
        },
        localeArbs: const <String, Map<String, Object?>>{
          'lib/l10n/app_hi.arb': <String, Object?>{
            '@@locale': 'fr',
            'appName': 'Countora',
          },
          'lib/l10n/app_fr.arb': <String, Object?>{
            '@@locale': 'fr',
            'appName': 'Countora',
          },
        },
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors.any(
          (error) => error.contains('app_hi.arb declares @@locale "fr"'),
        ),
        isTrue,
      );
      expect(
        result.errors.any(
          (error) => error.contains('both declare @@locale "fr"'),
        ),
        isTrue,
      );
    },
  );

  test('extracts strings and context localization references', () {
    final keys = referencedLocalizationKeys('''
final one = strings.timerProgress;
final two = context.l10n.backupExportFailed;
final unrelated = object.value;
''');

    expect(keys, containsAll(<String>['timerProgress', 'backupExportFailed']));
    expect(keys, hasLength(2));
  });
}
