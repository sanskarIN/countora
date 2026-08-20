import 'package:countora/src/data/web_notification_permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('non-web targets do not request browser notification permission', () async {
    var requests = 0;
    final granted = await requestWebNotificationPermissionFromUserGesture(
      isWeb: false,
      requestPermissionForTest: () async {
        requests += 1;
        return true;
      },
    );

    expect(granted, isFalse);
    expect(requests, 0);
  });

  test('web user action delegates to the browser permission request', () async {
    var requests = 0;
    final granted = await requestWebNotificationPermissionFromUserGesture(
      isWeb: true,
      requestPermissionForTest: () async {
        requests += 1;
        return true;
      },
    );

    expect(granted, isTrue);
    expect(requests, 1);
  });

  test('web denial is returned without throwing', () async {
    final granted = await requestWebNotificationPermissionFromUserGesture(
      isWeb: true,
      requestPermissionForTest: () async => false,
    );

    expect(granted, isFalse);
  });
}
