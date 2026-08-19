import 'package:countora/src/core/platform_capabilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web never reports future scheduled notification support', () {
    for (final platform in TargetPlatform.values) {
      expect(
        supportsScheduledNotifications(isWeb: true, platform: platform),
        isFalse,
      );
    }
  });

  test('unsupported native targets fail closed', () {
    for (final platform in <TargetPlatform>[
      TargetPlatform.linux,
      TargetPlatform.fuchsia,
    ]) {
      expect(
        supportsScheduledNotifications(isWeb: false, platform: platform),
        isFalse,
        reason: '$platform is not a supported scheduled-notification target',
      );
    }
  });

  test('supported native targets report future scheduling capability', () {
    for (final platform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    ]) {
      expect(
        supportsScheduledNotifications(isWeb: false, platform: platform),
        isTrue,
        reason: '$platform should use the native notification adapter',
      );
    }
  });
}
