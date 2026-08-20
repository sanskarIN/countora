import 'package:countora/src/data/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notification details configure every supported platform', () {
    final details = countoraNotificationDetails(
      soundEnabled: true,
      vibrationEnabled: true,
      quietMode: false,
    );

    expect(details.android, isNotNull);
    expect(details.iOS, isNotNull);
    expect(details.macOS, isNotNull);
    expect(details.linux, isNotNull);
    expect(details.windows, isNotNull);
    expect(details.web, isNotNull);

    expect(details.android!.playSound, isTrue);
    expect(details.android!.enableVibration, isTrue);
    expect(details.iOS!.presentSound, isTrue);
    expect(details.macOS!.presentSound, isTrue);
    expect(details.linux!.suppressSound, isFalse);
    expect(details.windows!.audio, isNull);
    expect(details.web!.isSilent, isFalse);
  });

  test('quiet mode suppresses controllable notification audio and vibration', () {
    final details = countoraNotificationDetails(
      soundEnabled: true,
      vibrationEnabled: true,
      quietMode: true,
    );

    expect(details.android!.playSound, isFalse);
    expect(details.android!.enableVibration, isFalse);
    expect(details.iOS!.presentSound, isFalse);
    expect(details.macOS!.presentSound, isFalse);
    expect(details.linux!.suppressSound, isTrue);
    expect(details.windows!.audio, isNotNull);
    expect(details.windows!.audio!.isSilent, isTrue);
    expect(details.web!.isSilent, isTrue);
  });
}
