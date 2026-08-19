import 'package:countora/src/app.dart';
import 'package:countora/src/data/local_store.dart';
import 'package:countora/src/data/notification_service.dart';
import 'package:countora/src/domain/models.dart';
import 'package:countora/src/presentation/timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class _MemoryStore implements TimerStore {
  CountoraState state = const CountoraState(
    settings: CountoraSettings(
      onboardingSeen: true,
      notificationsEnabled: false,
    ),
  );

  @override
  Future<void> clear() async => state = const CountoraState();

  @override
  Future<CountoraState> load() async => state;

  @override
  Future<void> save(CountoraState state) async => this.state = state;
}

class _NoopNotifications implements NotificationService {
  @override
  Future<void> cancelTimer(String timerId) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> scheduleTimer(
    CountdownTimer timer, {
    required bool soundEnabled,
    required bool vibrationEnabled,
    required bool quietMode,
  }) async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create, pause, save preset, and restart from preset', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 19, 9);
    final controller = TimerController(
      store: _MemoryStore(),
      notifications: _NoopNotifications(),
      nowUtc: () => now,
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await tester.pumpWidget(CountoraApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Timer'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Study sprint');
    await tester.enterText(fields.at(1), 'Study');
    await tester.enterText(fields.at(2), '0');
    await tester.enterText(fields.at(3), '1');
    await tester.enterText(fields.at(4), '0');
    await tester.tap(find.text('Start timer'));
    await tester.pumpAndSettle();

    expect(find.text('Study sprint'), findsOneWidget);
    expect(controller.runningCount, 1);

    await tester.tap(find.widgetWithText(FilledButton, 'Pause'));
    await tester.pumpAndSettle();
    expect(controller.pausedCount, 1);

    await tester.tap(find.byTooltip('Timer options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save as preset'));
    await tester.pumpAndSettle();
    expect(controller.presets, hasLength(1));

    await tester.tap(find.text('Presets'));
    await tester.pumpAndSettle();
    expect(find.text('Study sprint'), findsOneWidget);

    await tester.tap(find.text('Study sprint'));
    await tester.pumpAndSettle();
    expect(controller.timers, hasLength(2));
    expect(controller.runningCount, 1);
  });
}
