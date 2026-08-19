class VersionAuditResult {
  const VersionAuditResult({
    required this.packageVersion,
    required this.buildNumber,
    required this.errors,
  });

  final String? packageVersion;
  final String? buildNumber;
  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

VersionAuditResult auditVersionMetadata({
  required String pubspec,
  required String metadata,
  required String changelog,
  String? releaseTag,
}) {
  final errors = <String>[];

  final packageMatch = RegExp(
    r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$',
    multiLine: true,
  ).firstMatch(pubspec);
  if (packageMatch == null) {
    return VersionAuditResult(
      packageVersion: null,
      buildNumber: null,
      errors: const <String>[
        'Could not read MAJOR.MINOR.PATCH+BUILD from pubspec.yaml.',
      ],
    );
  }

  final packageVersion = packageMatch.group(1)!;
  final packageBuild = packageMatch.group(2)!;
  final appVersion = RegExp(
    r"static const version = '([^']+)';",
  ).firstMatch(metadata)?.group(1);
  final appBuild = RegExp(
    r'static const buildNumber = ([0-9]+);',
  ).firstMatch(metadata)?.group(1);

  if (appVersion == null || appBuild == null) {
    errors.add('Could not read AppMetadata version/build number.');
  } else if (packageVersion != appVersion || packageBuild != appBuild) {
    errors.add(
      'Version mismatch: pubspec=$packageVersion+$packageBuild, '
      'AppMetadata=$appVersion+$appBuild.',
    );
  }

  if (!changelog.contains('[$packageVersion]')) {
    errors.add('CHANGELOG.md does not contain a [$packageVersion] section.');
  }

  final tag = releaseTag?.trim();
  if (tag != null && tag.isNotEmpty) {
    final expectedTag = 'v$packageVersion';
    if (tag != expectedTag) {
      errors.add(
        'Release tag mismatch: tag=$tag, expected=$expectedTag for '
        'pubspec version $packageVersion.',
      );
    }
  }

  return VersionAuditResult(
    packageVersion: packageVersion,
    buildNumber: packageBuild,
    errors: List<String>.unmodifiable(errors),
  );
}
