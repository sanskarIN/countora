import 'package:countora/src/app.dart';
import 'package:countora/src/domain/models.dart';
import 'package:countora/src/presentation/timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late TimerController controller;

  setUp(() async {
    controller = TimerController(
      store: MemoryTimerStore(
        state: const CountoraState(
          settings: CountoraSettings(
            onboardingSeen: true,
            notificationsEnabled: false,
          ),
        ),
      ),
      notifications: FakeNotificationService(),
      nowUtc: () => DateTime.utc(2026, 8, 19, 9),
    );
    await controller.initialize();
  });

  tearDown(() => controller.dispose());

  testWidgets('Ctrl+N opens the new countdown dialog', (tester) async {
    await tester.pumpWidget(CountoraApp(controller: controller));
    await tester.pump();

    await _sendControlShortcut(tester, LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();

    expect(find.text('New countdown'), findsOneWidget);
    expect(find.text('Start timer'), findsOneWidget);
  });

  testWidgets('Ctrl+F focuses timer search', (tester) async {
    await tester.pumpWidget(CountoraApp(controller: controller));
    await tester.pump();

    await _sendControlShortcut(tester, LogicalKeyboardKey.keyF);
    await tester.pump();

    final search = tester.widget<SearchBar>(find.byType(SearchBar));
    expect(search.focusNode?.hasFocus, isTrue);
  });

  testWidgets('Ctrl+comma opens Settings', (tester) async {
    await tester.pumpWidget(CountoraApp(controller: controller));
    await tester.pump();

    await _sendControlShortcut(tester, LogicalKeyboardKey.comma);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Appearance'), findsOneWidget);
  });
}

Future<void> _sendControlShortcut(
  WidgetTester tester,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}
