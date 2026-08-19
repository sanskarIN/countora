import 'package:flutter_test/flutter_test.dart';

import '../tool/src/platform_patches.dart';

void main() {
  group('patchAndroidManifest', () {
    const source = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    <application android:label="countora">
        <activity android:name=".MainActivity" />
    </application>
</manifest>
''';

    test('adds required notification permissions and receivers', () {
      final patched = patchAndroidManifest(source);

      expect(
        patched,
        contains('android.permission.RECEIVE_BOOT_COMPLETED'),
      );
      expect(
        patched,
        contains('android.permission.SCHEDULE_EXACT_ALARM'),
      );
      expect(patched, contains('ScheduledNotificationReceiver'));
      expect(patched, contains('ScheduledNotificationBootReceiver'));
      expect(patched, contains('android.intent.action.BOOT_COMPLETED'));
    });

    test('is idempotent', () {
      final once = patchAndroidManifest(source);
      final twice = patchAndroidManifest(once);

      expect(twice, once);
    });

    test('rejects templates without an application closing tag', () {
      expect(
        () => patchAndroidManifest('<manifest></manifest>'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('patchAndroidGradle', () {
    const source = '''
android {
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "dev.sanskar.countora"
    }
}
''';

    test('adds desugaring and multidex configuration', () {
      final patched = patchAndroidGradle(source);

      expect(patched, contains('isCoreLibraryDesugaringEnabled = true'));
      expect(patched, contains('multiDexEnabled = true'));
      expect(
        patched,
        contains(
          'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")',
        ),
      );
    });

    test('is idempotent', () {
      final once = patchAndroidGradle(source);
      final twice = patchAndroidGradle(once);

      expect(twice, once);
    });

    test('rejects templates missing expected compile options', () {
      expect(
        () => patchAndroidGradle('android { defaultConfig { } }'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
