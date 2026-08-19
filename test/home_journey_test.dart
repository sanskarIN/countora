import 'package:countora/src/domain/models.dart';
import 'package:countora/src/presentation/home_page.dart';
import 'package:countora/src/presentation/timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('user can create and pause a countdown from the home screen', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 19, 8);
    final controller = TimerController(
      store: MemoryTimerStore(
        const CountoraState(
          settings: CountoraSettings(onboardingSeen: true),
        ),
      ),
      notifications: FakeNotificationService(),
      nowUtc: () => now,
    );
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(home: HomePage(controller: controller)),
    );
    expect(find.text('No countdowns yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Timer'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Reading',
    );
    await tester.tap(find.text('Start timer'));
    await tester.pumpAndSettle();

    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Resume'), findsOneWidget);

    controller.dispose();
  });
}
