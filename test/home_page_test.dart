import 'package:countora/src/app.dart';
import 'package:countora/src/domain/models.dart';
import 'package:countora/src/presentation/timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late TimerController controller;

  tearDown(() {
    controller.dispose();
  });

  testWidgets('renders saved timers and exposes accessible controls', (
    tester,
  ) async {
    controller = await _controllerWithPausedTeaTimer();
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(CountoraApp(controller: controller));
    await tester.pump();

    expect(find.text('Countora'), findsOneWidget);
    expect(find.text('Tea'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Resume'), findsOneWidget);
    final timerSemantics = tester.getSemantics(find.byType(Card).first);
    expect(timerSemantics.label, contains('Tea'));
    expect(timerSemantics.hint, 'Open focus mode');

    semantics.dispose();
  });

  testWidgets('search empty state can clear active filters', (tester) async {
    controller = await _controllerWithPausedTeaTimer();

    await tester.pumpWidget(CountoraApp(controller: controller));
    await tester.pump();
    await tester.enterText(find.byType(SearchBar), 'does-not-match');
    await tester.pump();

    expect(find.text('No matching countdowns'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pump();
    expect(find.text('Tea'), findsOneWidget);
  });

  testWidgets('timer can resume from its card', (tester) async {
    controller = await _controllerWithPausedTeaTimer();

    await tester.pumpWidget(CountoraApp(controller: controller));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Resume'));
    await tester.pump();

    expect(controller.timers.single.status, CountdownStatus.running);
    expect(find.widgetWithText(FilledButton, 'Pause'), findsOneWidget);
  });

  testWidgets('history tab can run a completed timer again', (tester) async {
    final now = DateTime.utc(2026, 8, 19, 9);
    final store = MemoryTimerStore(
      state: CountoraState(
        settings: const CountoraSettings(
          onboardingSeen: true,
          notificationsEnabled: false,
        ),
        history: <TimerHistoryEntry>[
          TimerHistoryEntry(
            timerId: 'old',
            name: 'Workout',
            group: 'Routine',
            completedAtUtc: now.subtract(const Duration(minutes: 5)),
            totalDurationSeconds: 90,
          ),
        ],
      ),
    );
    controller = TimerController(
      store: store,
      notifications: FakeNotificationService(),
      nowUtc: () => now,
    );
    await controller.initialize();

    await tester.pumpWidget(CountoraApp(controller: controller));
    await tester.pump();
    await tester.tap(find.text('History'));
    await tester.pump();

    expect(find.text('Workout'), findsOneWidget);
    await tester.tap(find.byTooltip('Run again'));
    await tester.pump();

    expect(controller.timers.single.name, 'Workout');
    expect(controller.timers.single.currentStep.durationSeconds, 90);
  });
}

Future<TimerController> _controllerWithPausedTeaTimer() async {
  final now = DateTime.utc(2026, 8, 19, 9);
  final store = MemoryTimerStore(
    state: const CountoraState(
      settings: CountoraSettings(
        onboardingSeen: true,
        notificationsEnabled: false,
      ),
      timers: <CountdownTimer>[
        CountdownTimer(
          id: 'tea',
          name: 'Tea',
          group: 'Kitchen',
          steps: <IntervalStep>[
            IntervalStep(label: 'Steep', durationSeconds: 300),
          ],
          currentStepIndex: 0,
          status: CountdownStatus.paused,
          remainingWhenPausedSeconds: 300,
        ),
      ],
    ),
  );
  final result = TimerController(
    store: store,
    notifications: FakeNotificationService(),
    nowUtc: () => now,
  );
  await result.initialize();
  return result;
}
