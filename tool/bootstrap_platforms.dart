import 'dart:io';

import 'src/platform_patches.dart';

Future<void> main() async {
  final flutter = Platform.isWindows ? 'flutter.bat' : 'flutter';

  final create = await Process.run(
    flutter,
    <String>[
      'create',
      '.',
      '--project-name=countora',
      '--org=dev.sanskar',
      '--platforms=android,ios,web,windows,macos,linux',
    ],
    runInShell: true,
  );
  stdout.write(create.stdout);
  stderr.write(create.stderr);
  if (create.exitCode != 0) {
    exit(create.exitCode);
  }

  _patchAndroidManifest();
  _patchAndroidGradle();

  stdout.writeln(
    'Countora platform runners generated and Android notifications configured.',
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
