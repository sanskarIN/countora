import 'dart:io';

import 'src/version_audit.dart';

void main() {
  final releaseTag = Platform.environment['GITHUB_REF_TYPE'] == 'tag'
      ? Platform.environment['GITHUB_REF_NAME']
      : null;
  final result = auditVersionMetadata(
    pubspec: File('pubspec.yaml').readAsStringSync(),
    metadata: File('lib/src/core/app_metadata.dart').readAsStringSync(),
    changelog: File('CHANGELOG.md').readAsStringSync(),
    releaseTag: releaseTag,
  );

  if (!result.isValid) {
    for (final error in result.errors) {
      stderr.writeln(error);
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Version metadata is synchronized at '
    '${result.packageVersion}+${result.buildNumber}.',
  );
  if (releaseTag != null) {
    stdout.writeln('Release tag $releaseTag matches the package version.');
  }
}
