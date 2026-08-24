import 'package:countora/src/app.dart';
import 'package:countora/src/data/local_store.dart';
import 'package:countora/src/data/notification_service.dart';
import 'package:countora/src/domain/models.dart';
import 'package:countora/src/presentation/timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingMemoryStore implements TimerStore {
  _FailingMemoryStore(this.state);

  CountoraState state;
  bool failSave = false;

  @override
  Future<void> clear() async {
    state = const CountoraState();
  }

  @override
  Future<CountoraState> load() async => state;

  @override
  Future<void> save(CountoraState value) async {
    if (failSave) throw StateError('simulated persistence failure');
    state = value;
  }
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
  testWidgets('controller errors remain visible on the Presets destination', (
    tester,
  ) async {
    final store = _FailingMemoryStore(
      const CountoraState(settings: CountoraSettings(onboardingSeen: true)),
    );
    final controller = TimerController(
      store: store,
      notifications: _NoopNotifications(),
      nowUtc: () => DateTime.utc(2026, 8, 20),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await tester.pumpWidget(CountoraApp(controller: controller));
    await tester.pump();

    await tester.tap(find.text('Presets'));
    await tester.pump();

    store.failSave = true;
    await controller.addPreset(
      name: 'Unsaved preset',
      group: '',
      steps: const <IntervalStep>[
        IntervalStep(label: 'Timer', durationSeconds: 60),
      ],
    );
    await tester.pump();

    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(
      find.text('Countora could not save local changes. Please try again.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Dismiss'));
    await tester.pump();

    expect(find.byType(MaterialBanner), findsNothing);
  });
}
