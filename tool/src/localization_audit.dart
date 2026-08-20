class LocalizationAuditResult {
  const LocalizationAuditResult({required this.errors});

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

LocalizationAuditResult auditLocalizationSources({
  required Map<String, Object?> arb,
  required Map<String, String> dartSources,
}) {
  final errors = <String>[];
  final locale = arb['@@locale'];
  if (locale != 'en') {
    errors.add('lib/l10n/app_en.arb must declare @@locale as "en".');
  }

  const reservedGeneratedMemberNames = <String>{
    'delegate',
    'localizationsDelegates',
    'of',
    'supportedLocales',
  };
  final messageKeys = <String>{};
  for (final entry in arb.entries) {
    final key = entry.key;
    if (key.startsWith('@')) continue;

    final value = entry.value;
    if (value is! String || value.trim().isEmpty) {
      errors.add('Localization message "$key" must be a non-empty string.');
      continue;
    }
    if (reservedGeneratedMemberNames.contains(key)) {
      errors.add(
        'Localization message "$key" collides with a generated '
        'AppLocalizations API member.',
      );
    }
    messageKeys.add(key);
  }

  const requiredKeys = <String>{
    'appName',
    'settings',
    'timers',
    'presets',
    'history',
    'openFocusMode',
    'exitFocusMode',
    'completionNotificationsUnavailable',
    'backupExportFailed',
  };
  final missingRequired = requiredKeys.difference(messageKeys).toList()..sort();
  for (final key in missingRequired) {
    errors.add('Required English localization message "$key" is missing.');
  }

  final referencedByKey = <String, Set<String>>{};
  for (final entry in dartSources.entries) {
    for (final key in referencedLocalizationKeys(entry.value)) {
      referencedByKey.putIfAbsent(key, () => <String>{}).add(entry.key);
    }
  }

  final referencedKeys = referencedByKey.keys.toSet();
  final missingReferences = referencedKeys.difference(messageKeys).toList()
    ..sort();
  for (final key in missingReferences) {
    final locations = referencedByKey[key]!.toList()..sort();
    errors.add(
      'Dart source references missing localization message "$key" in '
      '${locations.join(', ')}.',
    );
  }

  return LocalizationAuditResult(errors: List<String>.unmodifiable(errors));
}

Set<String> referencedLocalizationKeys(String source) {
  final result = <String>{};
  final pattern = RegExp(
    r'\b(?:strings|context\.l10n)\.([A-Za-z][A-Za-z0-9_]*)',
  );
  for (final match in pattern.allMatches(source)) {
    final key = match.group(1);
    if (key != null) result.add(key);
  }
  return result;
}
