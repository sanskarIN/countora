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

  final Object? decoded;
  try {
    decoded = jsonDecode(arbFile.readAsStringSync());
  } on FormatException catch (error) {
    stderr.writeln('lib/l10n/app_en.arb is invalid JSON: ${error.message}');
    exitCode = 1;
    return;
  }

  if (decoded is! Map<Object?, Object?>) {
    stderr.writeln('lib/l10n/app_en.arb must contain a JSON object.');
    exitCode = 1;
    return;
  }

  final arb = decoded.map((key, value) => MapEntry('$key', value));
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

  final result = auditLocalizationSources(arb: arb, dartSources: sources);
  if (!result.isValid) {
    stderr.writeln('Countora localization source audit failed:');
    for (final error in result.errors) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Verified ${arb.entries.where((entry) => !entry.key.startsWith('@')).length} '
    'English localization messages across ${sources.length} Dart source files.',
  );
}
