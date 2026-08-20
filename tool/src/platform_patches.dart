/// Pure text transforms used by Countora's generated-platform bootstrap.
///
/// Keeping these transforms free of file-system and process side effects makes
/// them deterministic, testable, and safer to evolve alongside Flutter's
/// generated runner templates.
String patchAndroidManifest(String source) {
  var text = source;

  const requiredPermissions = <String>[
    '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>',
    '<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>',
  ];

  final missingPermissions = requiredPermissions
      .where((permission) => !text.contains(permission))
      .toList(growable: false);

  if (missingPermissions.isNotEmpty) {
    final manifestMatch = RegExp(r'<manifest\b[^>]*>').firstMatch(text);
    if (manifestMatch == null) {
      throw const FormatException(
        'AndroidManifest.xml does not contain an opening <manifest> element.',
      );
    }

    final insertion = '\n    ${missingPermissions.join('\n    ')}';
    text = text.replaceRange(manifestMatch.end, manifestMatch.end, insertion);
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
    final applicationClose = text.lastIndexOf('</application>');
    if (applicationClose < 0) {
      throw const FormatException(
        'AndroidManifest.xml does not contain a closing </application> element.',
      );
    }
    text = text.replaceRange(applicationClose, applicationClose, receivers);
  }

  for (final permission in requiredPermissions) {
    if (!text.contains(permission)) {
      throw FormatException('Failed to apply required permission: $permission');
    }
  }
  if (!text.contains('ScheduledNotificationReceiver') ||
      !text.contains('ScheduledNotificationBootReceiver')) {
    throw const FormatException(
      'Failed to apply required local-notification receivers.',
    );
  }

  return text;
}

String patchAndroidGradle(String source) {
  var text = source;

  if (!text.contains('isCoreLibraryDesugaringEnabled = true')) {
    text = _insertAfterRequiredMarker(
      text,
      marker: 'compileOptions {',
      insertion: '\n        isCoreLibraryDesugaringEnabled = true',
      fileDescription: 'android/app/build.gradle.kts',
    );
  }

  if (!text.contains('multiDexEnabled = true')) {
    text = _insertAfterRequiredMarker(
      text,
      marker: 'defaultConfig {',
      insertion: '\n        multiDexEnabled = true',
      fileDescription: 'android/app/build.gradle.kts',
    );
  }

  if (!text.contains('coreLibraryDesugaring(')) {
    text = '${text.trimRight()}\n\n'
        'dependencies {\n'
        '    coreLibraryDesugaring('
        '"com.android.tools:desugar_jdk_libs:2.1.5")\n'
        '}\n';
  }

  const requiredSnippets = <String>[
    'isCoreLibraryDesugaringEnabled = true',
    'multiDexEnabled = true',
    'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")',
  ];
  for (final snippet in requiredSnippets) {
    if (!text.contains(snippet)) {
      throw FormatException('Failed to apply required Gradle snippet: $snippet');
    }
  }

  return text;
}

/// Applies the notification-center delegate required by
/// flutter_local_notifications for foreground iOS presentation.
String patchIosAppDelegate(String source) {
  var text = source;

  if (!text.contains('import UIKit')) {
    throw const FormatException(
      'ios/Runner/AppDelegate.swift does not contain the expected UIKit import.',
    );
  }
  if (!text.contains('GeneratedPluginRegistrant.register(with: self)')) {
    throw const FormatException(
      'ios/Runner/AppDelegate.swift does not contain the expected plugin '
      'registration marker.',
    );
  }

  if (!text.contains('import UserNotifications')) {
    text = text.replaceFirst(
      'import UIKit',
      'import UIKit\nimport UserNotifications',
    );
  }

  const delegateLine =
      'UNUserNotificationCenter.current().delegate = self as? '
      'UNUserNotificationCenterDelegate';
  if (!text.contains(delegateLine)) {
    text = text.replaceFirst(
      '    GeneratedPluginRegistrant.register(with: self)',
      '    $delegateLine\n'
      '    GeneratedPluginRegistrant.register(with: self)',
    );
  }

  if (!text.contains('import UserNotifications') ||
      !text.contains(delegateLine)) {
    throw const FormatException(
      'Failed to apply required iOS notification-center delegate setup.',
    );
  }

  return text;
}

String _insertAfterRequiredMarker(
  String source, {
  required String marker,
  required String insertion,
  required String fileDescription,
}) {
  final index = source.indexOf(marker);
  if (index < 0) {
    throw FormatException(
      '$fileDescription does not contain the expected marker "$marker".',
    );
  }
  final insertionIndex = index + marker.length;
  return source.replaceRange(insertionIndex, insertionIndex, insertion);
}
