import 'package:flutter_test/flutter_test.dart';

import '../tool/src/toolchain_audit.dart';

void main() {
  const validSetup = '''
runs:
  using: composite
  steps:
    - uses: subosito/flutter-action@v2
      with:
        channel: stable
        flutter-version: '3.47.1'
        cache: true
''';

  const sharedWorkflow = '''
steps:
  - uses: actions/checkout@v6
  - uses: ./.github/actions/setup-flutter
''';

  test('accepts one exact stable cached toolchain shared by workflows', () {
    final result = auditToolchain(
      setupAction: validSetup,
      workflowSources: const {
        'ci.yml': sharedWorkflow,
        'release.yml': sharedWorkflow,
      },
    );

    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
    expect(result.flutterVersion, '3.47.1');
  });

  test('rejects a moving or missing Flutter version', () {
    final result = auditToolchain(
      setupAction: validSetup.replaceFirst(
        "flutter-version: '3.47.1'",
        "flutter-version: '3.x'",
      ),
      workflowSources: const {'ci.yml': sharedWorkflow},
    );

    expect(result.isValid, isFalse);
    expect(
      result.errors,
      contains(
        'Shared Flutter setup must declare exactly one pinned '
        'MAJOR.MINOR.PATCH flutter-version.',
      ),
    );
  });

  test('rejects non-stable or uncached shared setup', () {
    final result = auditToolchain(
      setupAction: validSetup
          .replaceFirst('channel: stable', 'channel: beta')
          .replaceFirst('cache: true', 'cache: false'),
      workflowSources: const {'ci.yml': sharedWorkflow},
    );

    expect(result.isValid, isFalse);
    expect(
      result.errors,
      contains('Shared Flutter setup must use the stable channel.'),
    );
    expect(
      result.errors,
      contains('Shared Flutter setup must enable Flutter/pub caching.'),
    );
  });

  test('rejects workflows that bypass the shared setup action', () {
    const bypassingWorkflow = '''
steps:
  - uses: subosito/flutter-action@v2
    with:
      channel: stable
''';

    final result = auditToolchain(
      setupAction: validSetup,
      workflowSources: const {'ci.yml': bypassingWorkflow},
    );

    expect(result.isValid, isFalse);
    expect(
      result.errors,
      contains('ci.yml must use the shared Countora Flutter setup action.'),
    );
    expect(
      result.errors,
      contains(
        'ci.yml must not bypass the shared Countora Flutter setup action.',
      ),
    );
  });
}
