import 'package:countora/src/app.dart';
import 'package:countora/src/domain/models.dart';
import 'package:countora/src/presentation/timer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('persisted Hindi preference localizes the app at startup', (
    tester,
  ) async {
    final controller = TimerController(
      store: MemoryTimerStore(
        state: const CountoraState(
          settings: CountoraSettings(
            language: CountoraLanguage.hindi,
            onboardingSeen: true,
            notificationsEnabled: false,
          ),
        ),
      ),
      notifications: FakeNotificationService(),
      nowUtc: () => DateTime.utc(2026, 8, 23, 8),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await tester.pumpWidget(CountoraApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byTooltip('सेटिंग्स'), findsOneWidget);
    expect(find.text('टाइमर'), findsWidgets);
    expect(find.text('प्रीसेट'), findsOneWidget);
    expect(find.text('इतिहास'), findsOneWidget);
  });
}
