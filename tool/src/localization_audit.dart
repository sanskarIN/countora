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

  final messageKeys = <String>{};
  for (final entry in arb.entries) {
    final key = entry.key;
    if (key.startsWith('@')) continue;

    final value = entry.value;
    if (value is! String || value.trim().isEmpty) {
      errors.add('Localization message "$key" must be a non-empty string.');
      continue;
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

LocalizationAuditResult auditLocaleCatalogs({
  required Map<String, Object?> templateArb,
  required Map<String, Map<String, Object?>> localeArbs,
}) {
  final errors = <String>[];
  final templateKeys = _messageKeys(templateArb);
  final localeOwners = <String, String>{};

  for (final catalog in localeArbs.entries) {
    final path = catalog.key;
    final arb = catalog.value;
    final locale = arb['@@locale'];
    String? normalizedLocale;
    if (locale is! String || locale.trim().isEmpty) {
      errors.add('$path must declare a non-empty @@locale.');
    } else {
      normalizedLocale = locale.trim();
      final previousOwner = localeOwners[normalizedLocale];
      if (previousOwner != null) {
        errors.add(
          '$path and $previousOwner both declare @@locale "$normalizedLocale".',
        );
      } else {
        localeOwners[normalizedLocale] = path;
      }

      final filenameLocale = _localeFromArbPath(path);
      if (filenameLocale != null && filenameLocale != normalizedLocale) {
        errors.add(
          '$path declares @@locale "$normalizedLocale" but its filename '
          'declares "$filenameLocale".',
        );
      }
    }

    final keys = _messageKeys(arb);
    final missing = templateKeys.difference(keys).toList()..sort();
    final extra = keys.difference(templateKeys).toList()..sort();

    for (final key in missing) {
      errors.add('$path is missing localization message "$key".');
    }
    for (final key in extra) {
      errors.add('$path contains unknown localization message "$key".');
    }

    for (final key in keys.intersection(templateKeys)) {
      final value = arb[key];
      if (value is! String || value.trim().isEmpty) {
        errors.add('$path localization message "$key" must be non-empty.');
      }
    }
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

Set<String> _messageKeys(Map<String, Object?> arb) => arb.keys
    .where((key) => !key.startsWith('@'))
    .toSet();

String? _localeFromArbPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  final filename = normalized.split('/').last;
  final match = RegExp(r'^app_([A-Za-z0-9_\-]+)\.arb$').firstMatch(filename);
  return match?.group(1);
}
