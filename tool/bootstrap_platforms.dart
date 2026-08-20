import 'dart:io';

import 'src/platform_patches.dart';
import 'src/root_file_guard.dart';

const _rootFilesToPreserve = <String>[
  '.gitignore',
  'README.md',
  'analysis_options.yaml',
  'l10n.yaml',
  'pubspec.lock',
  'pubspec.yaml',
];

Future<void> main() async {
  final flutter = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final rootSnapshots = snapshotRootFiles(
    Directory.current,
    _rootFilesToPreserve,
  );

  late final ProcessResult create;
  try {
    create = await Process.run(
      flutter,
      <String>[
        'create',
        '.',
        '--project-name=countora',
        '--org=dev.sanskar',
        '--platforms=android,ios,web,windows,macos,linux',
        '--no-pub',
      ],
      runInShell: true,
    );
  } finally {
    restoreRootFiles(Directory.current, rootSnapshots);
  }

  stdout.write(create.stdout);
  stderr.write(create.stderr);
  if (create.exitCode != 0) {
    exitCode = create.exitCode;
    return;
  }

  _patchAndroidManifest();
  _patchAndroidGradle();
  _patchAndroidSettingsGradle();
  _patchIosAppDelegate();

  stdout.writeln(
    'Countora platform runners generated and native notification setup applied.',
  );
}

void _patchAndroidManifest() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    throw StateError('AndroidManifest.xml was not generated.');
  }

  final patched = patchAndroidManifest(manifest.readAsStringSync());
  manifest.writeAsStringSync(patched);
}

void _patchAndroidGradle() {
  final kotlin = File('android/app/build.gradle.kts');
  if (!kotlin.existsSync()) {
    throw StateError(
      'android/app/build.gradle.kts was not generated. '
      'The Flutter Android runner template may have changed.',
    );
  }

  final patched = patchAndroidGradle(kotlin.readAsStringSync());
  kotlin.writeAsStringSync(patched);
}

void _patchAndroidSettingsGradle() {
  final settings = File('android/settings.gradle.kts');
  if (!settings.existsSync()) {
    throw StateError(
      'android/settings.gradle.kts was not generated. '
      'The Flutter Android runner template may have changed.',
    );
  }

  final patched = patchAndroidSettingsGradle(settings.readAsStringSync());
  settings.writeAsStringSync(patched);
}

void _patchIosAppDelegate() {
  final appDelegate = File('ios/Runner/AppDelegate.swift');
  if (!appDelegate.existsSync()) {
    throw StateError(
      'ios/Runner/AppDelegate.swift was not generated. '
      'The Flutter iOS runner template may have changed.',
    );
  }

  final patched = patchIosAppDelegate(appDelegate.readAsStringSync());
  appDelegate.writeAsStringSync(patched);
}
