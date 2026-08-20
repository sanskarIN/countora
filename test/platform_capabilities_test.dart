import 'package:countora/src/core/platform_capabilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web supports runtime notifications but not future scheduling', () {
    for (final platform in TargetPlatform.values) {
      expect(
        notificationDeliveryMode(isWeb: true, platform: platform),
        NotificationDeliveryMode.runtimeOnly,
      );
      expect(
        supportsLocalNotifications(isWeb: true, platform: platform),
        isTrue,
      );
      expect(
        supportsScheduledNotifications(isWeb: true, platform: platform),
        isFalse,
      );
      expect(
        usesRuntimeNotificationFallback(isWeb: true, platform: platform),
        isTrue,
      );
    }
  });

  test('Linux uses runtime completion notification fallback', () {
    expect(
      notificationDeliveryMode(
        isWeb: false,
        platform: TargetPlatform.linux,
      ),
      NotificationDeliveryMode.runtimeOnly,
    );
    expect(
      supportsLocalNotifications(
        isWeb: false,
        platform: TargetPlatform.linux,
      ),
      isTrue,
    );
    expect(
      supportsScheduledNotifications(
        isWeb: false,
        platform: TargetPlatform.linux,
      ),
      isFalse,
    );
  });

  test('Android Apple and Windows support scheduled background delivery', () {
    for (final platform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    ]) {
      expect(
        notificationDeliveryMode(isWeb: false, platform: platform),
        NotificationDeliveryMode.scheduledBackground,
        reason: '$platform should use future native notification scheduling',
      );
      expect(
        supportsLocalNotifications(isWeb: false, platform: platform),
        isTrue,
      );
      expect(
        supportsScheduledNotifications(isWeb: false, platform: platform),
        isTrue,
      );
      expect(
        usesRuntimeNotificationFallback(isWeb: false, platform: platform),
        isFalse,
      );
    }
  });

  test('unknown unsupported native targets fail closed', () {
    expect(
      notificationDeliveryMode(
        isWeb: false,
        platform: TargetPlatform.fuchsia,
      ),
      NotificationDeliveryMode.unavailable,
    );
    expect(
      supportsLocalNotifications(
        isWeb: false,
        platform: TargetPlatform.fuchsia,
      ),
      isFalse,
    );
    expect(
      supportsScheduledNotifications(
        isWeb: false,
        platform: TargetPlatform.fuchsia,
      ),
      isFalse,
    );
  });
}
