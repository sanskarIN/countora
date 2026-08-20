import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/app_logger.dart';
import '../core/platform_capabilities.dart';
import '../domain/models.dart';
import 'notification_cleanup.dart';
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

InitializationSettings countoraNotificationInitializationSettings() {
  final darwinSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  return InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: darwinSettings,
    macOS: darwinSettings,
    linux: LinuxInitializationSettings(defaultActionName: 'Open Countora'),
    windows: WindowsInitializationSettings(
      appName: 'Countora',
      appUserModelId: 'Sanskar.Countora',
      guid: '2f2dc0ea-51c6-4ed1-9b53-8725823f34e0',
    ),
    web: const WebInitializationSettings(),
  );
}

AndroidNotificationDetails countoraAndroidNotificationDetails({
  required bool soundEnabled,
  required bool vibrationEnabled,
  required bool quietMode,
}) {
  final playSound = soundEnabled && !quietMode;
  final enableVibration = vibrationEnabled && !quietMode;

  late final String channelId;
  late final String channelName;
  if (playSound && enableVibration) {
    channelId = 'countora_timers_sound_vibration';
    channelName = 'Countora timers - sound and vibration';
  } else if (playSound) {
    channelId = 'countora_timers_sound_only';
    channelName = 'Countora timers - sound';
  } else if (enableVibration) {
    channelId = 'countora_timers_vibration_only';
    channelName = 'Countora timers - vibration';
  } else {
    channelId = 'countora_timers_silent';
    channelName = 'Countora timers - silent';
  }

  return AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: 'Countdown completion notifications',
    importance: Importance.high,
    priority: Priority.high,
    playSound: playSound,
    enableVibration: enableVibration,
    category: AndroidNotificationCategory.alarm,
  );
}

NotificationDetails countoraNotificationDetails({
  required bool soundEnabled,
  required bool vibrationEnabled,
  required bool quietMode,
}) {
  final playSound = soundEnabled && !quietMode;
  return NotificationDetails(
    android: countoraAndroidNotificationDetails(
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      quietMode: quietMode,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: playSound,
    ),
    macOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: playSound,
    ),
    linux: LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.normal,
      suppressSound: !playSound,
    ),
    windows: WindowsNotificationDetails(
      audio: playSound ? null : WindowsNotificationAudio.silent(),
    ),
    web: WebNotificationDetails(isSilent: !playSound),
  );
}

/// Returns whether a runtime-only notification callback that is being replaced
/// or cancelled has already reached its delivery deadline and therefore must be
/// allowed to finish. This protects the completion callback from racing the
/// controller's state-reconciliation cleanup at the exact same deadline.
bool shouldPreserveDueRuntimeNotification({
  required DateTime scheduledAtUtc,
  required DateTime nowUtc,
}) {
  return !nowUtc.toUtc().isBefore(scheduledAtUtc.toUtc());
}

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const _logger = AppLogger('notifications');

  final Map<String, _RuntimeNotificationEntry> _runtimeTimers =
      <String, _RuntimeNotificationEntry>{};
  bool _ready = false;

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    try {
      _ready = await _plugin.initialize(
            settings: countoraNotificationInitializationSettings(),
          ) ??
          false;
      _logger.info('initialized', fields: <String, Object?>{'ready': _ready});
    } on Object catch (error) {
      _logger.warning('initialize_failed', error: error);
      _ready = false;
    }
  }

  @override
  Future<void> requestPermissions() async {
    if (!_ready || !supportsLocalNotifications()) return;

    try {
      // Web permission is intentionally not requested here. Browsers require
      // permission prompts to originate directly from user activation, so the
      // Web Settings action uses requestWebNotificationPermissionFromUserGesture
      // instead of this automatic scheduling/reconciliation path.
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
    if (!_ready || timer.status != CountdownStatus.running) return;

    if (usesRuntimeNotificationFallback()) {
      _scheduleRuntimeFallback(
        timer,
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
        quietMode: quietMode,
      );
      return;
    }

    if (!supportsScheduledNotifications()) return;

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

      final details = countoraNotificationDetails(
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
        quietMode: quietMode,
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

  void _scheduleRuntimeFallback(
    CountdownTimer timer, {
    required bool soundEnabled,
    required bool vibrationEnabled,
    required bool quietMode,
  }) {
    _cancelRuntimeTimer(timer.id, preserveIfDue: true);
    final scheduledAt = timer.endsAtUtc;
    if (scheduledAt == null) return;

    final step = timer.currentStep;
    Future<void> deliver() => _showRuntimeNotification(
          timer: timer,
          step: step,
          soundEnabled: soundEnabled,
          vibrationEnabled: vibrationEnabled,
          quietMode: quietMode,
        );

    final delay = scheduledAt.difference(DateTime.now().toUtc());
    if (delay <= Duration.zero) {
      unawaited(deliver());
      return;
    }

    final entry = _RuntimeNotificationEntry(
      scheduledAtUtc: scheduledAt,
      deliver: deliver,
    );
    entry.timer = Timer(delay, () {
      if (identical(_runtimeTimers[timer.id], entry)) {
        _runtimeTimers.remove(timer.id);
      }
      unawaited(entry.deliver());
    });
    _runtimeTimers[timer.id] = entry;
  }

  void _cancelRuntimeTimer(
    String timerId, {
    required bool preserveIfDue,
  }) {
    final entry = _runtimeTimers.remove(timerId);
    if (entry == null) return;

    final isDue = shouldPreserveDueRuntimeNotification(
      scheduledAtUtc: entry.scheduledAtUtc,
      nowUtc: DateTime.now().toUtc(),
    );
    if (preserveIfDue && isDue) {
      // A controller reconciliation can race the Dart Timer at the exact
      // deadline. Leave a due callback alive so completion delivery is not
      // cancelled merely because state reconciliation won the event-loop race.
      return;
    }
    entry.timer.cancel();
  }

  Future<void> _showRuntimeNotification({
    required CountdownTimer timer,
    required IntervalStep step,
    required bool soundEnabled,
    required bool vibrationEnabled,
    required bool quietMode,
  }) async {
    if (!_ready || !supportsLocalNotifications()) return;

    try {
      await _plugin.show(
        id: _notificationId(timer.id, timer.currentStepIndex),
        title: timer.isSequence
            ? '${timer.name}: ${step.label}'
            : '${timer.name} finished',
        body: timer.isSequence
            ? 'Interval complete.'
            : 'Your countdown is complete.',
        notificationDetails: countoraNotificationDetails(
          soundEnabled: soundEnabled,
          vibrationEnabled: vibrationEnabled,
          quietMode: quietMode,
        ),
        payload: timer.id,
      );
    } on Object catch (error) {
      _logger.warning('runtime_notification_failed', error: error);
    }
  }

  @override
  Future<void> cancelTimer(String timerId) async {
    final runtimeOnly = usesRuntimeNotificationFallback();
    _cancelRuntimeTimer(timerId, preserveIfDue: runtimeOnly);
    if (!_ready || runtimeOnly) return;

    await runBoundedNotificationCleanup(
      count: CountoraStateCodec.maxIntervalsPerTimer,
      cancel: (index) =>
          _plugin.cancel(id: _notificationId(timerId, index)),
      onError: (index, error) {
        _logger.warning(
          'cancel_failed',
          error: error,
          fields: <String, Object?>{'stepIndex': index},
        );
      },
    );
  }

  int _notificationId(String timerId, int stepIndex) {
    var hash = 17;
    for (final unit in timerId.codeUnits) {
      hash = ((hash * 31) + unit) & 0x3fffffff;
    }
    return (hash + stepIndex) & 0x7fffffff;
  }
}

class _RuntimeNotificationEntry {
  _RuntimeNotificationEntry({
    required this.scheduledAtUtc,
    required this.deliver,
  });

  final DateTime scheduledAtUtc;
  final Future<void> Function() deliver;
  late final Timer timer;
}
