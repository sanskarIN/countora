import 'dart:io';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final metadata = File('lib/src/core/app_metadata.dart').readAsStringSync();

  final packageMatch = RegExp(
    r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$',
    multiLine: true,
  ).firstMatch(pubspec);
  if (packageMatch == null) {
    _fail('Could not read MAJOR.MINOR.PATCH+BUILD from pubspec.yaml.');
  }

  final appVersion = RegExp(
    r"static const version = '([^']+)';",
  ).firstMatch(metadata)?.group(1);
  final appBuild = RegExp(
    r'static const buildNumber = ([0-9]+);',
  ).firstMatch(metadata)?.group(1);

  if (appVersion == null || appBuild == null) {
    _fail('Could not read AppMetadata version/build number.');
  }

  final packageVersion = packageMatch!.group(1)!;
  final packageBuild = packageMatch.group(2)!;

  if (packageVersion != appVersion || packageBuild != appBuild) {
    _fail(
      'Version mismatch: pubspec=$packageVersion+$packageBuild, '
      'AppMetadata=$appVersion+$appBuild.',
    );
  }

  final changelog = File('CHANGELOG.md').readAsStringSync();
  if (!changelog.contains('[$packageVersion]')) {
    _fail('CHANGELOG.md does not contain a [$packageVersion] section.');
  }

  stdout.writeln('Version metadata is synchronized at $packageVersion+$packageBuild.');
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
