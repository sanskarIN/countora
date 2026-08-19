import 'package:countora/src/data/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Apple initialization defers notification permission prompts', () {
    final settings = countoraNotificationInitializationSettings();

    final ios = settings.iOS;
    final macos = settings.macOS;
    expect(ios, isNotNull);
    expect(macos, isNotNull);
    expect(ios!.requestAlertPermission, isFalse);
    expect(ios.requestBadgePermission, isFalse);
    expect(ios.requestSoundPermission, isFalse);
    expect(macos!.requestAlertPermission, isFalse);
    expect(macos.requestBadgePermission, isFalse);
    expect(macos.requestSoundPermission, isFalse);
  });

  test('initialization keeps all configured platform adapters', () {
    final settings = countoraNotificationInitializationSettings();

    expect(settings.android, isNotNull);
    expect(settings.iOS, isNotNull);
    expect(settings.macOS, isNotNull);
    expect(settings.linux, isNotNull);
    expect(settings.windows, isNotNull);
    expect(settings.web, isNotNull);
  });
}
