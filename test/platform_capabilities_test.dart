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

  test('Linux desktop reports future scheduling as unsupported', () {
    expect(
      supportsScheduledNotifications(
        isWeb: false,
        platform: TargetPlatform.linux,
      ),
      isFalse,
    );
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
