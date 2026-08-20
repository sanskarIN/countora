import 'package:flutter/foundation.dart';

/// Describes how Countora can deliver completion notifications on a target.
///
/// [scheduledBackground] means the platform adapter can register a future
/// notification that may fire while Countora is not running. [runtimeOnly]
/// means the platform can display local notifications, but the current OS or
/// browser API cannot schedule them for future delivery; Countora therefore
/// emits completion notifications when its runtime observes/reconciles the
/// finished timer. [unavailable] is reserved for targets without a supported
/// local-notification implementation.
enum NotificationDeliveryMode {
  scheduledBackground,
  runtimeOnly,
  unavailable,
}

NotificationDeliveryMode notificationDeliveryMode({
  bool? isWeb,
  TargetPlatform? platform,
}) {
  final web = isWeb ?? kIsWeb;
  if (web) return NotificationDeliveryMode.runtimeOnly;

  final target = platform ?? defaultTargetPlatform;
  return switch (target) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS ||
    TargetPlatform.windows =>
      NotificationDeliveryMode.scheduledBackground,
    TargetPlatform.linux => NotificationDeliveryMode.runtimeOnly,
    TargetPlatform.fuchsia => NotificationDeliveryMode.unavailable,
  };
}

/// Returns whether Countora can display a local completion notification.
bool supportsLocalNotifications({
  bool? isWeb,
  TargetPlatform? platform,
}) {
  return notificationDeliveryMode(isWeb: isWeb, platform: platform) !=
      NotificationDeliveryMode.unavailable;
}

/// Returns whether Countora can register future background delivery.
bool supportsScheduledNotifications({
  bool? isWeb,
  TargetPlatform? platform,
}) {
  return notificationDeliveryMode(isWeb: isWeb, platform: platform) ==
      NotificationDeliveryMode.scheduledBackground;
}

/// Returns whether Countora should deliver completion notices from its runtime
/// after the timer is observed/reconciled as completed.
bool usesRuntimeNotificationFallback({
  bool? isWeb,
  TargetPlatform? platform,
}) {
  return notificationDeliveryMode(isWeb: isWeb, platform: platform) ==
      NotificationDeliveryMode.runtimeOnly;
}
