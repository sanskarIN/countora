import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/app_logger.dart';
import '../domain/models.dart';
import 'state_codec.dart';

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
  static const _logger = AppLogger('notifications');

  bool _ready = false;

  bool get _supportsScheduledNotifications =>
      !kIsWeb && defaultTargetPlatform != TargetPlatform.linux;

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
      web: const WebInitializationSettings(),
    );

    try {
      _ready = await _plugin.initialize(settings: settings) ?? false;
      _logger.info('initialized', fields: <String, Object?>{'ready': _ready});
    } on Object catch (error) {
      _logger.warning('initialize_failed', error: error);
      _ready = false;
    }
  }

  @override
  Future<void> requestPermissions() async {
    if (!_ready || !_supportsScheduledNotifications) return;

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
    } on Object catch (error) {
      _logger.warning('permission_request_failed', error: error);
    }
  }

  @override
  Future<void> scheduleTimer(
    CountdownTimer timer, {
    required bool soundEnabled,
    required bool vibrationEnabled,
    required bool quietMode,
  }) async {
    if (!_ready ||
        !_supportsScheduledNotifications ||
        timer.status != CountdownStatus.running) {
      return;
    }

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

      final id = _notificationId(timer.id, index);
      final date = tz.TZDateTime.from(scheduledAt, tz.UTC);
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: timer.isSequence
              ? '${timer.name}: ${step.label}'
              : '${timer.name} finished',
          body: timer.isSequence
              ? 'Interval complete.'
              : 'Your countdown is complete.',
          scheduledDate: date,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: timer.id,
        );
      } on Object catch (error) {
        // Exact alarms can be denied independently from normal notification
        // permission on Android. Fall back to inexact scheduling rather than
        // silently losing completion cues. Treat platform-plugin failures as a
        // soft failure so a notification issue never crashes the timer UI.
        _logger.warning(
          'exact_schedule_failed',
          error: error,
          fields: <String, Object?>{'stepIndex': index},
        );
        try {
          await _plugin.zonedSchedule(
            id: id,
            title: timer.isSequence
                ? '${timer.name}: ${step.label}'
                : '${timer.name} finished',
            body: timer.isSequence
                ? 'Interval complete.'
                : 'Your countdown is complete.',
            scheduledDate: date,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: timer.id,
          );
        } on Object catch (fallbackError) {
          _logger.error(
            'fallback_schedule_failed',
            error: fallbackError,
            fields: <String, Object?>{'stepIndex': index},
          );
        }
      }
    }
  }

  @override
  Future<void> cancelTimer(String timerId) async {
    if (!_ready) return;
    for (var index = 0;
        index < CountoraStateCodec.maxIntervalsPerTimer;
        index += 1) {
      try {
        await _plugin.cancel(id: _notificationId(timerId, index));
      } on Object catch (error) {
        _logger.warning(
          'cancel_failed',
          error: error,
          fields: <String, Object?>{'stepIndex': index},
        );
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
