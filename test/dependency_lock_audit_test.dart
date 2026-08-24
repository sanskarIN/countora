import 'package:flutter_test/flutter_test.dart';

import '../tool/src/dependency_lock_audit.dart';

const _validLockfile = '''
packages:
  example:
    dependency: transitive
    description:
      name: example
    source: hosted
    version: "1.0.0"
sdks:
  dart: ">=3.10.0 <4.0.0"
  flutter: ">=3.38.1"
''';

void main() {
  test('accepts a non-empty Flutter dependency lockfile shape', () {
    final result = auditDependencyLock(exists: true, contents: _validLockfile);

    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
  });

  test('rejects a missing lockfile', () {
    final result = auditDependencyLock(exists: false, contents: null);

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('pubspec.lock is missing'));
  });

  test('rejects an empty lockfile', () {
    final result = auditDependencyLock(exists: true, contents: '  \n');

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('empty'));
  });

  test('rejects a lockfile without a packages section', () {
    final result = auditDependencyLock(
      exists: true,
      contents: 'sdks:\n  dart: ">=3.10.0 <4.0.0"\n',
    );

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('packages section'));
  });

  test('rejects a lockfile without an sdks section', () {
    final result = auditDependencyLock(
      exists: true,
      contents: 'packages:\n  example: {}\n',
    );

    expect(result.isValid, isFalse);
    expect(result.errors.single, contains('sdks section'));
  });
}
