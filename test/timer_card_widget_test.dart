import 'package:countora/src/domain/models.dart';
import 'package:countora/src/presentation/timer_card.dart';
import 'package:countora/src/presentation/timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('timer card exposes readable semantics and controls', (tester) async {
    final now = DateTime.utc(2026, 8, 19, 8);
    final controller = TimerController(
      store: MemoryTimerStore(),
      notifications: FakeNotificationService(),
      nowUtc: () => now,
    );
    await controller.initialize();
    await controller.addTimer(
      name: 'Study',
      group: 'Focus',
      steps: const <IntervalStep>[
        IntervalStep(label: 'Study', durationSeconds: 60),
      ],
    );

    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimerCard(
            timer: controller.timers.single,
            controller: controller,
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Study, 01:00 remaining, running'),
      findsOneWidget,
    );
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('+1 min'), findsOneWidget);

    semantics.dispose();
    controller.dispose();
  });
}
