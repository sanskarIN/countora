import 'dart:io';

import 'src/dependency_lock_audit.dart';

void main() {
  final lockfile = File('pubspec.lock');
  final result = auditDependencyLock(
    exists: lockfile.existsSync(),
    contents: lockfile.existsSync() ? lockfile.readAsStringSync() : null,
  );

  if (!result.isValid) {
    for (final error in result.errors) {
      stderr.writeln(error);
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'pubspec.lock is present and has the expected lockfile shape.',
  );
}
