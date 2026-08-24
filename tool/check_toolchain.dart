import 'dart:io';

import 'src/toolchain_audit.dart';

void main() {
  const setupPath = '.github/actions/setup-flutter/action.yml';
  const workflowPaths = <String>[
    '.github/workflows/ci.yml',
    '.github/workflows/dependency-lock.yml',
    '.github/workflows/platform-smoke.yml',
    '.github/workflows/release.yml',
    '.github/workflows/repository-audit.yml',
  ];

  final missing = <String>[
    setupPath,
    ...workflowPaths,
  ].where((path) => !File(path).existsSync()).toList(growable: false);

  if (missing.isNotEmpty) {
    for (final path in missing) {
      stderr.writeln('Toolchain audit input is missing: $path');
    }
    exitCode = 1;
    return;
  }

  final result = auditToolchain(
    setupAction: File(setupPath).readAsStringSync(),
    workflowSources: <String, String>{
      for (final path in workflowPaths) path: File(path).readAsStringSync(),
    },
  );

  if (!result.isValid) {
    for (final error in result.errors) {
      stderr.writeln(error);
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'CI workflows use the shared Flutter ${result.flutterVersion} toolchain.',
  );
}
