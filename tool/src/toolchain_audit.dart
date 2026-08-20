class ToolchainAuditResult {
  const ToolchainAuditResult({
    required this.errors,
    required this.flutterVersion,
  });

  final List<String> errors;
  final String? flutterVersion;

  bool get isValid => errors.isEmpty;
}

ToolchainAuditResult auditToolchain({
  required String setupAction,
  required Map<String, String> workflowSources,
}) {
  final errors = <String>[];
  final versionMatches = RegExp(
    r'''^\s*flutter-version:\s*['"]?(\d+\.\d+\.\d+)['"]?\s*$''',
    multiLine: true,
  ).allMatches(setupAction).toList(growable: false);

  String? flutterVersion;
  if (versionMatches.length != 1) {
    errors.add(
      'Shared Flutter setup must declare exactly one pinned '
      'MAJOR.MINOR.PATCH flutter-version.',
    );
  } else {
    flutterVersion = versionMatches.single.group(1);
  }

  if (!RegExp(
    r'^\s*channel:\s*stable\s*$',
    multiLine: true,
  ).hasMatch(setupAction)) {
    errors.add('Shared Flutter setup must use the stable channel.');
  }

  if (!RegExp(
    r'^\s*cache:\s*true\s*$',
    multiLine: true,
  ).hasMatch(setupAction)) {
    errors.add('Shared Flutter setup must enable Flutter/pub caching.');
  }

  for (final entry in workflowSources.entries) {
    final path = entry.key;
    final source = entry.value;

    if (!source.contains('uses: ./.github/actions/setup-flutter')) {
      errors.add('$path must use the shared Countora Flutter setup action.');
    }

    if (source.contains('subosito/flutter-action@')) {
      errors.add(
        '$path must not bypass the shared Countora Flutter setup action.',
      );
    }
  }

  return ToolchainAuditResult(
    errors: List<String>.unmodifiable(errors),
    flutterVersion: flutterVersion,
  );
}
