import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Requests browser notification permission from a direct user interaction.
///
/// Browsers require this call to originate from user activation. Do not invoke
/// this helper from startup, timer reconciliation, persistence callbacks, or
/// other automatic/background paths.
Future<bool> requestWebNotificationPermissionFromUserGesture({
  bool? isWeb,
  Future<bool?> Function()? requestPermissionForTest,
}) async {
  if (!(isWeb ?? kIsWeb)) return false;

  if (requestPermissionForTest != null) {
    return await requestPermissionForTest() ?? false;
  }

  final plugin = FlutterLocalNotificationsPlugin();
  final web = plugin
      .resolvePlatformSpecificImplementation<
        WebFlutterLocalNotificationsPlugin
      >();
  if (web == null) return false;
  if (web.permissionStatus == WebNotificationPermission.granted) return true;

  return await web.requestNotificationsPermission() ?? false;
}
