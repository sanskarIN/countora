import 'package:countora/src/data/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each Android sound and vibration profile uses a stable channel', () {
    final soundAndVibration = countoraAndroidNotificationDetails(
      soundEnabled: true,
      vibrationEnabled: true,
      quietMode: false,
    );
    final soundOnly = countoraAndroidNotificationDetails(
      soundEnabled: true,
      vibrationEnabled: false,
      quietMode: false,
    );
    final vibrationOnly = countoraAndroidNotificationDetails(
      soundEnabled: false,
      vibrationEnabled: true,
      quietMode: false,
    );
    final silent = countoraAndroidNotificationDetails(
      soundEnabled: false,
      vibrationEnabled: false,
      quietMode: false,
    );

    expect(
      <String>{
        soundAndVibration.channelId,
        soundOnly.channelId,
        vibrationOnly.channelId,
        silent.channelId,
      },
      hasLength(4),
    );
    expect(soundAndVibration.playSound, isTrue);
    expect(soundAndVibration.enableVibration, isTrue);
    expect(soundOnly.playSound, isTrue);
    expect(soundOnly.enableVibration, isFalse);
    expect(vibrationOnly.playSound, isFalse);
    expect(vibrationOnly.enableVibration, isTrue);
    expect(silent.playSound, isFalse);
    expect(silent.enableVibration, isFalse);
  });

  test('quiet mode always maps to the silent Android channel', () {
    final quiet = countoraAndroidNotificationDetails(
      soundEnabled: true,
      vibrationEnabled: true,
      quietMode: true,
    );
    final silent = countoraAndroidNotificationDetails(
      soundEnabled: false,
      vibrationEnabled: false,
      quietMode: false,
    );

    expect(quiet.channelId, silent.channelId);
    expect(quiet.playSound, isFalse);
    expect(quiet.enableVibration, isFalse);
  });
}
