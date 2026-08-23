import 'dart:convert';
import 'dart:io';

import 'src/localization_audit.dart';

void main() {
  final arbFile = File('lib/l10n/app_en.arb');
  if (!arbFile.existsSync()) {
    stderr.writeln('Missing lib/l10n/app_en.arb.');
    exitCode = 1;
    return;
  }

  final Map<String, Object?> arb;
  try {
    arb = _decodeArbFile(arbFile);
  } on FormatException catch (error) {
    stderr.writeln('${arbFile.path} is invalid: ${error.message}');
    exitCode = 1;
    return;
  }

  final localeCatalogs = <String, Map<String, Object?>>{};
  final l10nDirectory = Directory('lib/l10n');
  final localeFiles = l10nDirectory
      .listSync(followLinks: false)
      .whereType<File>()
      .where(
        (file) => file.path.replaceAll('\\', '/').split('/').last.startsWith('app_'),
      )
      .where((file) => file.path.endsWith('.arb') && file.path != arbFile.path)
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in localeFiles) {
    try {
      localeCatalogs[file.path.replaceAll('\\', '/')] = _decodeArbFile(file);
    } on FormatException catch (error) {
      stderr.writeln('${file.path} is invalid: ${error.message}');
      exitCode = 1;
      return;
    }
  }

  final sources = <String, String>{};
  final libDirectory = Directory('lib');
  if (!libDirectory.existsSync()) {
    stderr.writeln('Missing lib directory.');
    exitCode = 1;
    return;
  }

  for (final entity in libDirectory.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final normalized = entity.path.replaceAll('\\', '/');
    if (normalized.contains('/l10n/app_localizations')) continue;
    sources[normalized] = entity.readAsStringSync();
  }

  final sourceResult = auditLocalizationSources(arb: arb, dartSources: sources);
  final catalogResult = auditLocaleCatalogs(
    templateArb: arb,
    localeArbs: localeCatalogs,
  );
  final errors = <String>[...sourceResult.errors, ...catalogResult.errors];
  if (errors.isNotEmpty) {
    stderr.writeln('Countora localization source audit failed:');
    for (final error in errors) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
    return;
  }

  final messageCount =
      arb.entries.where((entry) => !entry.key.startsWith('@')).length;
  stdout.writeln(
    'Verified $messageCount English localization messages across '
    '${sources.length} Dart source files and ${localeCatalogs.length} '
    'translated locale catalog(s).',
  );
}

Map<String, Object?> _decodeArbFile(File file) {
  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (error) {
    throw FormatException('invalid JSON: ${error.message}');
  }

  if (decoded is! Map<Object?, Object?>) {
    throw const FormatException('must contain a JSON object.');
  }
  return decoded.map((key, value) => MapEntry('$key', value));
}
