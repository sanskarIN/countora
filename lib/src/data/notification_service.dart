import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/models.dart';

abstract interface class NotificationService {
  Future<void> initialize();
  Future<void> requestPermissions();
  Future<void> scheduleTimer(
    CountdownTimer timer, {
    required bool soundEnabled,
    required bool vibrationEnabled,
    required bool quietMode,
  });
  Future<void> cancelTimer(String timerId);
}

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    final settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Open Countora'),
      windows: WindowsInitializationSettings(
        appName: 'Countora',
        appUserModelId: 'Sanskar.Countora',
        guid: '2f2dc0ea-51c6-4ed1-9b53-8725823f34e0',
      ),
    );

    try {
      _ready = await _plugin.initialize(settings: settings) ?? false;
    } on Exception catch (error, stackTrace) {
      debugPrint('Notification initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _ready = false;
    }
  }

  @override
  Future<void> requestPermissions() async {
    if (!_ready) return;

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();

      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true, badge: false);

      await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true, badge: false);
    } on Exception catch (error, stackTrace) {
      debugPrint('Notification permission request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> scheduleTimer(
    CountdownTimer timer, {
    required bool soundEnabled,
    required bool vibrationEnabled,
    required bool quietMode,
  }) async {
    if (!_ready || timer.status != CountdownStatus.running) return;

    await cancelTimer(timer.id);

    var scheduledAt = timer.endsAtUtc;
    if (scheduledAt == null) return;

    for (var index = timer.currentStepIndex;
        index < timer.steps.length;
        index += 1) {
      final step = timer.steps[index];
      final isCurrent = index == timer.currentStepIndex;
      if (!isCurrent) {
        scheduledAt = scheduledAt!.add(Duration(seconds: step.durationSeconds));
      }

      if (!scheduledAt!.isAfter(DateTime.now().toUtc())) continue;

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          quietMode ? 'countora_quiet' : 'countora_timers',
          quietMode ? 'Countora quiet timers' : 'Countora timers',
          channelDescription: 'Countdown completion notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: soundEnabled && !quietMode,
          enableVibration: vibrationEnabled && !quietMode,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: soundEnabled && !quietMode,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: soundEnabled && !quietMode,
        ),
      );

      try {
        await _plugin.zonedSchedule(
          id: _notificationId(timer.id, index),
          title: timer.isSequence
              ? '${timer.name}: ${step.label}'
              : '${timer.name} finished',
          body: timer.isSequence
              ? 'Interval complete.'
              : 'Your countdown is complete.',
          scheduledDate: tz.TZDateTime.from(scheduledAt, tz.UTC),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: timer.id,
        );
      } on Exception catch (error, stackTrace) {
        debugPrint('Scheduling notification failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  @override
  Future<void> cancelTimer(String timerId) async {
    if (!_ready) return;
    for (var index = 0; index < 32; index += 1) {
      try {
        await _plugin.cancel(id: _notificationId(timerId, index));
      } on Exception catch (error) {
        debugPrint('Cancelling notification failed: $error');
        break;
      }
    }
  }

  int _notificationId(String timerId, int stepIndex) {
    var hash = 17;
    for (final unit in timerId.codeUnits) {
      hash = ((hash * 31) + unit) & 0x3fffffff;
    }
    return (hash + stepIndex) & 0x7fffffff;
  }
}
