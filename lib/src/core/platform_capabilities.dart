import 'package:flutter/foundation.dart';

/// Returns whether Countora can use its current notification adapter for
/// future scheduled completion delivery on the target.
///
/// Optional overrides keep capability decisions deterministic in tests without
/// changing Flutter's global platform override.
bool supportsScheduledNotifications({
  bool? isWeb,
  TargetPlatform? platform,
}) {
  final web = isWeb ?? kIsWeb;
  final target = platform ?? defaultTargetPlatform;
  return !web && target != TargetPlatform.linux;
}
