import 'package:flutter/foundation.dart';

/// Returns whether Countora can use its current notification adapter for
/// future scheduled completion delivery on the target.
///
/// Optional overrides keep capability decisions deterministic in tests without
/// changing Flutter's global platform override. Unknown/unsupported native
/// targets fail closed instead of being assumed notification-capable.
bool supportsScheduledNotifications({
  bool? isWeb,
  TargetPlatform? platform,
}) {
  final web = isWeb ?? kIsWeb;
  if (web) return false;

  final target = platform ?? defaultTargetPlatform;
  return target == TargetPlatform.android ||
      target == TargetPlatform.iOS ||
      target == TargetPlatform.macOS ||
      target == TargetPlatform.windows;
}
