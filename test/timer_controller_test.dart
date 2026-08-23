import 'package:countora/src/data/local_store.dart';
import 'package:countora/src/data/notification_service.dart';
import 'package:countora/src/domain/models.dart';
import 'package:countora/src/presentation/timer_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryStore implements TimerStore {
  CountoraState state = const CountoraState();

  @override
  Future<void> clear() async => state = const CountoraState();

  @override
  Future<CountoraState> load() async => state;

  @override
  Future<void> save(CountoraState state) async => this.state = state;
}

class FakeNotifications implements NotificationService {
  final List<String> scheduled = <String>[];
  final List<String> cancelled = <String>[];

  @override
  Future<void> cancelTimer(String timerId) async => cancelled.add(timerId);

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
  }) async {
    scheduled.add(timer.id);
  }
}

void main() {
  test('adds, pauses, resumes and persists a timer', () async {
    final store = MemoryStore();
    final notifications = FakeNotifications();
    var now = DateTime.utc(2026, 8, 19, 8);

    final controller = TimerController(
      store: store,
      notifications: notifications,
      nowUtc: () => now,
    );
    await controller.initialize();

    await controller.addTimer(
      name: 'Tea',
      group: 'Kitchen',
      steps: const <IntervalStep>[
        IntervalStep(label: 'Tea', durationSeconds: 60),
      ],
    );
    expect(controller.timers, hasLength(1));
    expect(controller.timers.single.status, CountdownStatus.running);

    now = now.add(const Duration(seconds: 10));
    await controller.pause(controller.timers.single.id);
    expect(controller.timers.single.remainingWhenPausedSeconds, 50);

    await controller.resume(controller.timers.single.id);
    expect(controller.timers.single.status, CountdownStatus.running);
    expect(store.state.timers.single.name, 'Tea');

    controller.dispose();
  });

  test('visual and language settings do not reschedule running timers', () async {
    final now = DateTime.utc(2026, 8, 23, 8);
    final store = MemoryStore()
      ..state = CountoraState(
        timers: <CountdownTimer>[
          CountdownTimer(
            id: 'running',
            name: 'Focus',
            group: 'Study',
            steps: const <IntervalStep>[
              IntervalStep(label: 'Focus', durationSeconds: 300),
            ],
            currentStepIndex: 0,
            status: CountdownStatus.running,
            remainingWhenPausedSeconds: 300,
            endsAtUtc: now.add(const Duration(minutes: 5)),
          ),
        ],
      );
    final notifications = FakeNotifications();
    final controller = TimerController(
      store: store,
      notifications: notifications,
      nowUtc: () => now,
    );
    await controller.initialize();
    notifications.scheduled.clear();

    await controller.updateSettings(
      controller.settings.copyWith(
        themeMode: ThemeMode.dark,
        language: CountoraLanguage.hindi,
        compactCards: true,
        reducedMotion: true,
      ),
    );

    expect(notifications.scheduled, isEmpty);
    expect(store.state.settings.language, CountoraLanguage.hindi);
    expect(store.state.settings.themeMode, ThemeMode.dark);

    controller.dispose();
  });

  test('notification presentation changes reschedule running timers', () async {
    final now = DateTime.utc(2026, 8, 23, 8);
    final store = MemoryStore()
      ..state = CountoraState(
        timers: <CountdownTimer>[
          CountdownTimer(
            id: 'running',
            name: 'Focus',
            group: '',
            steps: const <IntervalStep>[
              IntervalStep(label: 'Focus', durationSeconds: 300),
            ],
            currentStepIndex: 0,
            status: CountdownStatus.running,
            remainingWhenPausedSeconds: 300,
            endsAtUtc: now.add(const Duration(minutes: 5)),
          ),
        ],
      );
    final notifications = FakeNotifications();
    final controller = TimerController(
      store: store,
      notifications: notifications,
      nowUtc: () => now,
    );
    await controller.initialize();
    notifications.scheduled.clear();

    await controller.updateSettings(
      controller.settings.copyWith(soundEnabled: false),
    );

    expect(notifications.scheduled, <String>['running']);
    expect(store.state.settings.soundEnabled, isFalse);

    controller.dispose();
  });

  test('rejects a zero-length timer interval', () async {
    final controller = TimerController(
      store: MemoryStore(),
      notifications: FakeNotifications(),
      nowUtc: () => DateTime.utc(2026, 8, 19, 8),
    );
    await controller.initialize();

    await expectLater(
      controller.addTimer(
        name: 'Bad',
        group: '',
        steps: const <IntervalStep>[
          IntervalStep(label: 'Bad', durationSeconds: 0),
        ],
      ),
      throwsArgumentError,
    );

    controller.dispose();
  });

  test('advances expired interval sequences on initialization', () async {
    final now = DateTime.utc(2026, 8, 19, 8);
    final store = MemoryStore()
      ..state = CountoraState(
        timers: <CountdownTimer>[
          CountdownTimer(
            id: 'sequence',
            name: 'Intervals',
            group: 'Study',
            steps: const <IntervalStep>[
              IntervalStep(label: 'Focus', durationSeconds: 5),
              IntervalStep(label: 'Break', durationSeconds: 10),
            ],
            currentStepIndex: 0,
            status: CountdownStatus.running,
            remainingWhenPausedSeconds: 5,
            endsAtUtc: now.subtract(const Duration(seconds: 1)),
          ),
        ],
      );

    final controller = TimerController(
      store: store,
      notifications: FakeNotifications(),
      nowUtc: () => now,
    );
    await controller.initialize();

    expect(controller.timers.single.currentStepIndex, 1);
    expect(controller.timers.single.status, CountdownStatus.running);
    expect(
      controller.timers.single.endsAtUtc,
      now.add(const Duration(seconds: 9)),
    );

    controller.dispose();
  });

  test('catches up across multiple elapsed interval steps', () async {
    final now = DateTime.utc(2026, 8, 19, 8);
    final notifications = FakeNotifications();
    final store = MemoryStore()
      ..state = CountoraState(
        timers: <CountdownTimer>[
          CountdownTimer(
            id: 'elapsed-sequence',
            name: 'Elapsed sequence',
            group: 'Study',
            steps: const <IntervalStep>[
              IntervalStep(label: 'One', durationSeconds: 5),
              IntervalStep(label: 'Two', durationSeconds: 5),
              IntervalStep(label: 'Three', durationSeconds: 5),
            ],
            currentStepIndex: 0,
            status: CountdownStatus.running,
            remainingWhenPausedSeconds: 5,
            endsAtUtc: now.subtract(const Duration(seconds: 12)),
          ),
        ],
      );

    final controller = TimerController(
      store: store,
      notifications: notifications,
      nowUtc: () => now,
    );
    await controller.initialize();

    expect(controller.timers.single.status, CountdownStatus.completed);
    expect(controller.history, hasLength(1));
    expect(notifications.cancelled, contains('elapsed-sequence'));

    controller.dispose();
  });
}
