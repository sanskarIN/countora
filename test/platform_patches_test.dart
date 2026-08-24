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

  group('patchAndroidSettingsGradle', () {
    const olderTemplate = '''
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}
''';

    test('raises older generated AGP to the notification minimum', () {
      final patched = patchAndroidSettingsGradle(olderTemplate);

      expect(
        patched,
        contains('id("com.android.application") version "8.11.1" apply false'),
      );
    });

    test('keeps a newer generated AGP version', () {
      const newerTemplate = '''
plugins {
    id("com.android.application") version "9.1.0" apply false
}
''';
      expect(patchAndroidSettingsGradle(newerTemplate), newerTemplate);
    });

    test('is idempotent after raising the AGP version', () {
      final once = patchAndroidSettingsGradle(olderTemplate);
      final twice = patchAndroidSettingsGradle(once);
      expect(twice, once);
    });

    test('rejects an unexpected settings template', () {
      expect(
        () => patchAndroidSettingsGradle('plugins { }'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('patchIosAppDelegate', () {
    const legacySource = '''
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
''';

    const currentSource = '''
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
''';

    test('adds notification delegate to the legacy iOS template', () {
      final patched = patchIosAppDelegate(legacySource);

      expect(patched, contains('import UserNotifications'));
      expect(
        patched,
        contains(
          'UNUserNotificationCenter.current().delegate = self as? '
          'UNUserNotificationCenterDelegate',
        ),
      );
      expect(
        patched.indexOf('UNUserNotificationCenter.current().delegate'),
        lessThan(
          patched.indexOf(
            'return super.application(application, '
            'didFinishLaunchingWithOptions: launchOptions)',
          ),
        ),
      );
    });

    test('adds notification delegate to the Flutter 3.47 UIScene template', () {
      final patched = patchIosAppDelegate(currentSource);

      expect(patched, contains('import UserNotifications'));
      expect(
        patched,
        contains(
          'UNUserNotificationCenter.current().delegate = self as? '
          'UNUserNotificationCenterDelegate',
        ),
      );
      expect(
        patched,
        contains(
          'GeneratedPluginRegistrant.register(with: '
          'engineBridge.pluginRegistry)',
        ),
      );
    });

    test('is idempotent for legacy and current templates', () {
      final legacyOnce = patchIosAppDelegate(legacySource);
      final currentOnce = patchIosAppDelegate(currentSource);

      expect(patchIosAppDelegate(legacyOnce), legacyOnce);
      expect(patchIosAppDelegate(currentOnce), currentOnce);
    });

    test('rejects an unexpected generated iOS template', () {
      expect(
        () => patchIosAppDelegate('import Flutter\nimport UIKit\n'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
