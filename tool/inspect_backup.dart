import 'dart:convert';
import 'dart:io';

import 'package:countora/src/data/state_codec.dart';

import 'src/backup_inspection.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/inspect_backup.dart <countora-backup.json>',
    );
    exitCode = 64;
    return;
  }

  final file = File(args.single);
  if (!file.existsSync()) {
    stderr.writeln('Backup file does not exist.');
    exitCode = 66;
    return;
  }

  final encodedBytes = file.lengthSync();
  if (encodedBytes > CountoraStateCodec.maxBackupBytes) {
    stderr.writeln(
      'Backup exceeds the ${CountoraStateCodec.maxBackupBytes}-byte limit.',
    );
    exitCode = 65;
    return;
  }

  final String raw;
  try {
    raw = file.readAsStringSync();
  } on FileSystemException {
    stderr.writeln('Backup file could not be read.');
    exitCode = 74;
    return;
  }

  try {
    const codec = CountoraStateCodec();
    final state = codec.decode(raw);
    final inspection = inspectCountoraState(
      state,
      encodedBytes: encodedBytes,
    );
    final output = <String, Object?>{
      'valid': true,
      'schemaVersion': CountoraStateCodec.currentSchemaVersion,
      'inspection': inspection.toJson(),
    };
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(output));
  } on FormatException catch (error) {
    stderr.writeln('Backup is invalid: ${error.message}');
    exitCode = 65;
  }
}
