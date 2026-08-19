import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/core/stable_clock.dart';
import 'src/data/local_store.dart';
import 'src/data/notification_service.dart';
import 'src/presentation/timer_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await SharedPreferences.getInstance();
  final store = SharedPreferencesTimerStore(preferences);
  final notifications = LocalNotificationService();
  await notifications.initialize();
  final clock = StableClock();

  final controller = TimerController(
    store: store,
    notifications: notifications,
    nowUtc: clock.nowUtc,
  );
  await controller.initialize();

  runApp(CountoraApp(controller: controller));
}
