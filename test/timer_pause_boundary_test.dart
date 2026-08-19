import 'package:countora/src/data/local_store.dart';
import 'package:countora/src/data/notification_service.dart';
import 'package:countora/src/domain/models.dart';
import 'package:countora/src/presentation/timer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements TimerStore {
  CountoraState state = const CountoraState();

  @override
  Future<void> clear() async => state = const CountoraState();

  @override
  Future<CountoraState> load() async => state;

  @override
  Future<void> save(CountoraState state) async => this.state = state;
}

class _RecordingNotifications implements NotificationService {
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
  }) async {}
}

void main() {
  late DateTime now;
  late _MemoryStore store;
  late _RecordingNotifications notifications;
  late TimerController controller;

  setUp(() async {
    now = DateTime.utc(2026, 8, 19, 9);
    store = _MemoryStore();
    notifications = _RecordingNotifications();
    controller = TimerController(
      store: store,
      notifications: notifications,
      nowUtc: () => now,
    );
    await controller.initialize();
  });

  tearDown(() => controller.dispose());

  test('pausing at the deadline completes instead of freezing at zero', () async {
    await controller.addTimer(
      name: 'Boundary',
      group: '',
      steps: const <IntervalStep>[
        IntervalStep(label: 'Boundary', durationSeconds: 1),
      ],
    );
    final id = controller.timers.single.id;

    now = now.add(const Duration(seconds: 1));
    await controller.pause(id);

    expect(controller.timers.single.status, CountdownStatus.completed);
    expect(controller.timers.single.remainingWhenPausedSeconds, 0);
    expect(controller.history, hasLength(1));
    expect(notifications.cancelled, contains(id));
  });

  test('pausing preserves a positive fractional second by rounding up', () async {
    await controller.addTimer(
      name: 'Fractional',
      group: '',
      steps: const <IntervalStep>[
        IntervalStep(label: 'Fractional', durationSeconds: 60),
      ],
    );

    now = now.add(const Duration(seconds: 10, milliseconds: 500));
    await controller.pause(controller.timers.single.id);

    expect(controller.timers.single.status, CountdownStatus.paused);
    expect(controller.timers.single.remainingWhenPausedSeconds, 50);
  });

  test('pause all completes expired timers and pauses active timers', () async {
    await controller.addTimer(
      name: 'Short',
      group: '',
      steps: const <IntervalStep>[
        IntervalStep(label: 'Short', durationSeconds: 1),
      ],
    );
    await controller.addTimer(
      name: 'Long',
      group: '',
      steps: const <IntervalStep>[
        IntervalStep(label: 'Long', durationSeconds: 60),
      ],
    );

    now = now.add(const Duration(seconds: 2));
    await controller.pauseAllRunning();

    final byName = <String, CountdownTimer>{
      for (final timer in controller.timers) timer.name: timer,
    };
    expect(byName['Short']!.status, CountdownStatus.completed);
    expect(byName['Long']!.status, CountdownStatus.paused);
    expect(byName['Long']!.remainingWhenPausedSeconds, 58);
    expect(controller.history, hasLength(1));
  });
}
