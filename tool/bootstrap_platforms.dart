import 'dart:io';

import 'src/platform_patches.dart';

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
  final rootSnapshots = _snapshotRootFiles();

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
    _restoreRootFiles(rootSnapshots);
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

Map<String, List<int>?> _snapshotRootFiles() {
  return <String, List<int>?>{
    for (final path in _rootFilesToPreserve)
      path: File(path).existsSync() ? File(path).readAsBytesSync() : null,
  };
}

void _restoreRootFiles(Map<String, List<int>?> snapshots) {
  for (final entry in snapshots.entries) {
    final file = File(entry.key);
    final bytes = entry.value;
    if (bytes == null) {
      if (file.existsSync()) {
        file.deleteSync();
      }
      continue;
    }
    file.writeAsBytesSync(bytes, flush: true);
  }
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
