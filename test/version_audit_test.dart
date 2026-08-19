import 'package:flutter_test/flutter_test.dart';

import '../tool/src/version_audit.dart';

const _pubspec = '''
name: countora
version: 0.2.0+2
''';

const _metadata = '''
abstract final class AppMetadata {
  static const version = '0.2.0';
  static const buildNumber = 2;
}
''';

const _changelog = '''
## [0.2.0] - 2026-08-19
''';

void main() {
  test('accepts synchronized package metadata', () {
    final result = auditVersionMetadata(
      pubspec: _pubspec,
      metadata: _metadata,
      changelog: _changelog,
    );

    expect(result.isValid, isTrue);
    expect(result.packageVersion, '0.2.0');
    expect(result.buildNumber, '2');
  });

  test('rejects AppMetadata drift', () {
    final result = auditVersionMetadata(
      pubspec: _pubspec,
      metadata: _metadata.replaceFirst("'0.2.0'", "'0.2.1'"),
      changelog: _changelog,
    );

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('Version mismatch'));
  });

  test('rejects a missing changelog release section', () {
    final result = auditVersionMetadata(
      pubspec: _pubspec,
      metadata: _metadata,
      changelog: '# Changelog\n',
    );

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('[0.2.0]'));
  });

  test('accepts a release tag that matches the package version', () {
    final result = auditVersionMetadata(
      pubspec: _pubspec,
      metadata: _metadata,
      changelog: _changelog,
      releaseTag: 'v0.2.0',
    );

    expect(result.isValid, isTrue);
  });

  test('rejects a release tag for a different package version', () {
    final result = auditVersionMetadata(
      pubspec: _pubspec,
      metadata: _metadata,
      changelog: _changelog,
      releaseTag: 'v0.2.1',
    );

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('Release tag mismatch'));
  });
}
