import 'package:flutter_test/flutter_test.dart';

import '../tool/src/version_audit.dart';

const _pubspec = '''
name: countora
version: 2.15.18+18
''';

const _pubspecWithMsix = '''
name: countora
version: 2.15.18+18

msix_config:
  display_name: Countora
  msix_version: 2.15.18.18
''';

const _metadata = '''
abstract final class AppMetadata {
  static const version = '2.15.18';
  static const buildNumber = 18;
}
''';

const _changelog = '''
## [2.15.18] - 2026-08-24
''';

void main() {
  test('accepts synchronized package metadata', () {
    final result = auditVersionMetadata(
      pubspec: _pubspec,
      metadata: _metadata,
      changelog: _changelog,
    );

    expect(result.isValid, isTrue);
    expect(result.packageVersion, '2.15.18');
    expect(result.buildNumber, '18');
  });

  test('accepts synchronized Windows MSIX metadata', () {
    final result = auditVersionMetadata(
      pubspec: _pubspecWithMsix,
      metadata: _metadata,
      changelog: _changelog,
    );

    expect(result.isValid, isTrue);
  });

  test('rejects an MSIX version that drifts from package build metadata', () {
    final result = auditVersionMetadata(
      pubspec: _pubspecWithMsix.replaceFirst('2.15.18.18', '2.15.18.19'),
      metadata: _metadata,
      changelog: _changelog,
    );

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('MSIX version mismatch'));
  });

  test('requires msix_version whenever MSIX configuration is present', () {
    final result = auditVersionMetadata(
      pubspec: _pubspecWithMsix.replaceFirst(
        '  msix_version: 2.15.18.18\n',
        '',
      ),
      metadata: _metadata,
      changelog: _changelog,
    );

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('msix_version=2.15.18.18'));
  });

  test('rejects AppMetadata drift', () {
    final result = auditVersionMetadata(
      pubspec: _pubspec,
      metadata: _metadata.replaceFirst("'2.15.18'", "'2.15.19'"),
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
    expect(result.errors.single, contains('[2.15.18]'));
  });

  test('requires an exact changelog version heading', () {
    final result = auditVersionMetadata(
      pubspec: _pubspec,
      metadata: _metadata,
      changelog: '## [2x15x18] - 2026-08-24\n',
    );

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('[2.15.18]'));
  });

  test('accepts a release tag that matches the package version', () {
    final result = auditVersionMetadata(
      pubspec: _pubspec,
      metadata: _metadata,
      changelog: _changelog,
      releaseTag: 'v2.15.18',
    );

    expect(result.isValid, isTrue);
  });

  test('rejects a release tag for a different package version', () {
    final result = auditVersionMetadata(
      pubspec: _pubspec,
      metadata: _metadata,
      changelog: _changelog,
      releaseTag: 'v2.15.19',
    );

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('Release tag mismatch'));
  });

  test('rejects tags while the changelog entry is still unreleased', () {
    final result = auditVersionMetadata(
      pubspec: _pubspec,
      metadata: _metadata,
      changelog: '## [2.15.18] - Unreleased release candidate\n',
      releaseTag: 'v2.15.18',
    );

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('finalized dated CHANGELOG'));
  });
}
