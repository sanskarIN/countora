import 'package:countora/src/app.dart';
import 'package:countora/src/domain/models.dart';
import 'package:countora/src/presentation/timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late TimerController controller;

  tearDown(() => controller.dispose());

  testWidgets('settings exposes appearance, accessibility, updates, and privacy', (
    tester,
  ) async {
    controller = await _buildController();

    await tester.pumpWidget(CountoraApp(controller: controller));
    await tester.pump();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Accessibility'), findsWidgets);
    expect(find.text('Notifications & cues'), findsOneWidget);
    expect(find.text('Privacy & data'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Updates'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Updates'), findsOneWidget);
    expect(find.text('Check for updates'), findsOneWidget);
    expect(find.text('Report an issue'), findsOneWidget);
  });

  testWidgets('reduced motion preference persists through the controller', (
    tester,
  ) async {
    controller = await _buildController();

    await tester.pumpWidget(CountoraApp(controller: controller));
    await tester.pump();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    final reducedMotion = find.widgetWithText(SwitchListTile, 'Reduced motion');
    expect(reducedMotion, findsOneWidget);
    await tester.tap(reducedMotion);
    await tester.pump();

    expect(controller.settings.reducedMotion, isTrue);
  });

  testWidgets('erase all data requires confirmation and clears local state', (
    tester,
  ) async {
    controller = await _buildController(withTimer: true);

    await tester.pumpWidget(CountoraApp(controller: controller));
    await tester.pump();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Erase all local Countora data'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Erase all local Countora data'));
    await tester.pumpAndSettle();

    expect(find.text('Erase all local data?'), findsOneWidget);
    expect(controller.timers, isNotEmpty);

    await tester.tap(find.text('Erase all data'));
    await tester.pumpAndSettle();

    expect(controller.timers, isEmpty);
    expect(controller.presets, isEmpty);
    expect(controller.history, isEmpty);
  });
}

Future<TimerController> _buildController({bool withTimer = false}) async {
  final now = DateTime.utc(2026, 8, 19, 9);
  final store = MemoryTimerStore(
    state: CountoraState(
      settings: const CountoraSettings(
        onboardingSeen: true,
        notificationsEnabled: false,
      ),
      timers: withTimer
          ? const <CountdownTimer>[
              CountdownTimer(
                id: 'timer',
                name: 'Timer',
                group: '',
                steps: <IntervalStep>[
                  IntervalStep(label: 'Timer', durationSeconds: 60),
                ],
                currentStepIndex: 0,
                status: CountdownStatus.paused,
                remainingWhenPausedSeconds: 60,
              ),
            ]
          : const <CountdownTimer>[],
    ),
  );
  final controller = TimerController(
    store: store,
    notifications: FakeNotificationService(),
    nowUtc: () => now,
  );
  await controller.initialize();
  return controller;
}
