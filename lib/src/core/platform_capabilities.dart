import 'package:flutter/foundation.dart';

/// Build-time signal used by the packaged Windows distribution.
///
/// Portable Windows builds intentionally leave this false because the Windows
/// notification implementation cannot reliably cancel/retrieve notifications
/// without package identity. The MSIX build sets
/// `COUNTORA_WINDOWS_PACKAGED=true` so it can use future scheduling safely.
const bool countoraWindowsPackaged = bool.fromEnvironment(
  'COUNTORA_WINDOWS_PACKAGED',
  defaultValue: false,
);

/// Describes how Countora can deliver completion notifications on a target.
///
/// [scheduledBackground] means the platform adapter can register a future
/// notification that may fire while Countora is not running. [runtimeOnly]
/// means Countora can display local notifications but must keep delivery tied to
/// its active runtime because the target API or current packaging does not offer
/// the cancellation/scheduling guarantees Countora requires. [unavailable] is
/// reserved for targets without a supported local-notification implementation.
enum NotificationDeliveryMode { scheduledBackground, runtimeOnly, unavailable }

NotificationDeliveryMode notificationDeliveryMode({
  bool? isWeb,
  TargetPlatform? platform,
  bool? windowsPackaged,
}) {
  final web = isWeb ?? kIsWeb;
  if (web) return NotificationDeliveryMode.runtimeOnly;

  final target = platform ?? defaultTargetPlatform;
  return switch (target) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => NotificationDeliveryMode.scheduledBackground,
    TargetPlatform.windows =>
      (windowsPackaged ?? countoraWindowsPackaged)
          ? NotificationDeliveryMode.scheduledBackground
          : NotificationDeliveryMode.runtimeOnly,
    TargetPlatform.linux => NotificationDeliveryMode.runtimeOnly,
    TargetPlatform.fuchsia => NotificationDeliveryMode.unavailable,
  };
}

/// Returns whether Countora can display a local completion notification.
bool supportsLocalNotifications({
  bool? isWeb,
  TargetPlatform? platform,
  bool? windowsPackaged,
}) {
  return notificationDeliveryMode(
        isWeb: isWeb,
        platform: platform,
        windowsPackaged: windowsPackaged,
      ) !=
      NotificationDeliveryMode.unavailable;
}

/// Returns whether Countora can register future background delivery while also
/// satisfying Countora's cancellation/replacement expectations.
bool supportsScheduledNotifications({
  bool? isWeb,
  TargetPlatform? platform,
  bool? windowsPackaged,
}) {
  return notificationDeliveryMode(
        isWeb: isWeb,
        platform: platform,
        windowsPackaged: windowsPackaged,
      ) ==
      NotificationDeliveryMode.scheduledBackground;
}

/// Returns whether Countora should deliver completion notices from its runtime.
bool usesRuntimeNotificationFallback({
  bool? isWeb,
  TargetPlatform? platform,
  bool? windowsPackaged,
}) {
  return notificationDeliveryMode(
        isWeb: isWeb,
        platform: platform,
        windowsPackaged: windowsPackaged,
      ) ==
      NotificationDeliveryMode.runtimeOnly;
}
