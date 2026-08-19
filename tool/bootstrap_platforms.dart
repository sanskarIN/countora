import 'dart:io';

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

  var text = manifest.readAsStringSync();
  const manifestOpen =
      '<manifest xmlns:android="http://schemas.android.com/apk/res/android">';
  const requiredPermissions = <String>[
    '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>',
    '<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>',
  ];

  for (final permission in requiredPermissions) {
    if (!text.contains(permission)) {
      text = text.replaceFirst(
        manifestOpen,
        '$manifestOpen\n    $permission',
      );
    }
  }

  const receivers = '''
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
''';

  if (!text.contains('ScheduledNotificationReceiver')) {
    text = text.replaceFirst(
      '</application>',
      '$receivers    </application>',
    );
  }

  manifest.writeAsStringSync(text);
}

void _patchAndroidGradle() {
  final kotlin = File('android/app/build.gradle.kts');
  if (!kotlin.existsSync()) {
    stderr.writeln(
      'Skipping Android desugaring patch: build.gradle.kts not found.',
    );
    return;
  }

  var text = kotlin.readAsStringSync();

  if (!text.contains('isCoreLibraryDesugaringEnabled = true')) {
    text = text.replaceFirst(
      'compileOptions {',
      'compileOptions {\n'
          '        isCoreLibraryDesugaringEnabled = true',
    );
  }

  if (!text.contains('multiDexEnabled = true')) {
    text = text.replaceFirst(
      'defaultConfig {',
      'defaultConfig {\n'
          '        multiDexEnabled = true',
    );
  }

  if (!text.contains('coreLibraryDesugaring(')) {
    text += '''
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
''';
  }

  kotlin.writeAsStringSync(text);
}
