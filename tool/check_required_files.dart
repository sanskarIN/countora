import 'dart:io';

void main() {
  const requiredFiles = <String>[
    'README.md',
    'LICENSE',
    'CONTRIBUTING.md',
    'CODE_OF_CONDUCT.md',
    'SECURITY.md',
    'SUPPORT.md',
    'PRIVACY.md',
    'CHANGELOG.md',
    'ROADMAP.md',
    'what_changed.md',
    '.gitignore',
    '.editorconfig',
    '.gitattributes',
    '.env.example',
    'analysis_options.yaml',
    'pubspec.yaml',
    'l10n.yaml',
    'assets/branding/countora-mark.svg',
    'docs/architecture.md',
    'docs/setup.md',
    'docs/development.md',
    'docs/testing.md',
    'docs/release.md',
    'docs/troubleshooting.md',
    'docs/accessibility.md',
    'docs/performance.md',
    'docs/github.md',
    'docs/backup-format.md',
    'docs/branding.md',
    'docs/cli-tools.md',
    'docs/notification-support.md',
    'docs/adr/0001-local-first-modular-flutter.md',
    'docs/adr/0002-monotonic-runtime-clock.md',
    'docs/adr/0003-versioned-bounded-json-state.md',
    'docs/adr/0004-generated-platform-runners.md',
    'docs/adr/0005-persist-before-platform-side-effects.md',
    'tool/bootstrap_platforms.dart',
    'tool/check_dependency_lock.dart',
    'tool/check_localization_source.dart',
    'tool/check_markdown_links.dart',
    'tool/check_required_files.dart',
    'tool/check_secrets.dart',
    'tool/check_version_sync.dart',
    'tool/inspect_backup.dart',
    'tool/benchmark_state_codec.dart',
    'tool/src/backup_inspection.dart',
    'tool/src/dependency_lock_audit.dart',
    'tool/src/localization_audit.dart',
    'tool/src/platform_patches.dart',
    'tool/src/version_audit.dart',
    'lib/src/core/app_logger.dart',
    'lib/src/core/platform_capabilities.dart',
    'lib/src/data/notification_cleanup.dart',
    'lib/src/data/notification_service.dart',
    'test/app_logger_test.dart',
    'test/backup_inspection_test.dart',
    'test/dependency_lock_audit_test.dart',
    'test/home_error_banner_test.dart',
    'test/localization_audit_test.dart',
    'test/notification_cleanup_test.dart',
    'test/platform_capabilities_test.dart',
    'test/platform_patches_test.dart',
    'test/external_link_launcher_test.dart',
    'test/settings_reactivity_test.dart',
    'test/timer_controller_limits_test.dart',
    'test/timer_controller_resilience_test.dart',
    'test/version_audit_test.dart',
    'integration_test/app_journey_test.dart',
    '.github/ISSUE_TEMPLATE/bug_report.yml',
    '.github/ISSUE_TEMPLATE/config.yml',
    '.github/ISSUE_TEMPLATE/documentation.yml',
    '.github/ISSUE_TEMPLATE/feature_request.yml',
    '.github/pull_request_template.md',
    '.github/dependabot.yml',
    '.github/FUNDING.yml',
    '.github/workflows/ci.yml',
    '.github/workflows/security.yml',
    '.github/workflows/codeql.yml',
    '.github/workflows/release.yml',
    '.github/workflows/repository-audit.yml',
  ];

  final missing = <String>[
    for (final path in requiredFiles)
      if (!File(path).existsSync()) path,
  ];

  if (missing.isNotEmpty) {
    stderr.writeln('Missing required Countora repository files:');
    for (final path in missing) {
      stderr.writeln('  - $path');
    }
    exitCode = 1;
    return;
  }

  final adrDirectory = Directory('docs/adr');
  final adrCount = adrDirectory
      .listSync(followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.md'))
      .length;
  if (adrCount < 5) {
    stderr.writeln('Expected at least five documented architecture decisions.');
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Verified ${requiredFiles.length} required files and $adrCount ADRs.',
  );
}
