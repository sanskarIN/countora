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

  test('rejects names reserved by generated localization APIs', () {
    final result = auditLocalizationSources(
      arb: const <String, Object?>{
        ...completeArb,
        'of': 'of',
      },
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
    expect(
      result.errors.any((error) => error.contains('"settings"')),
      isTrue,
    );
  });

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
