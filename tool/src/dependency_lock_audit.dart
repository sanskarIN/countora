class DependencyLockAuditResult {
  const DependencyLockAuditResult({required this.errors});

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

DependencyLockAuditResult auditDependencyLock({
  required bool exists,
  required String? contents,
}) {
  final errors = <String>[];

  if (!exists) {
    errors.add(
      'pubspec.lock is missing. Generate dependency resolution with the '
      'supported Flutter SDK, review it, and commit the lockfile before '
      'creating a release tag.',
    );
    return DependencyLockAuditResult(errors: List<String>.unmodifiable(errors));
  }

  final normalized = contents?.trim() ?? '';
  if (normalized.isEmpty) {
    errors.add('pubspec.lock exists but is empty.');
  } else {
    if (!RegExp(r'^packages:\s*$', multiLine: true).hasMatch(normalized)) {
      errors.add('pubspec.lock does not contain a packages section.');
    }
    if (!RegExp(r'^sdks:\s*$', multiLine: true).hasMatch(normalized)) {
      errors.add('pubspec.lock does not contain an sdks section.');
    }
  }

  return DependencyLockAuditResult(errors: List<String>.unmodifiable(errors));
}
