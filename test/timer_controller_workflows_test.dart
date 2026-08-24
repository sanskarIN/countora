import 'package:countora/src/data/local_store.dart';
import 'package:countora/src/data/notification_service.dart';
import 'package:countora/src/domain/models.dart';
import 'package:countora/src/presentation/timer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class WorkflowMemoryStore implements TimerStore {
  CountoraState state = const CountoraState();
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount += 1;
    state = const CountoraState();
  }

  @override
  Future<CountoraState> load() async => state;

  @override
  Future<void> save(CountoraState state) async => this.state = state;
}

class WorkflowNotifications implements NotificationService {
  final List<String> scheduled = <String>[];
  final List<String> cancelled = <String>[];
  int permissionRequests = 0;

  @override
  Future<void> cancelTimer(String timerId) async => cancelled.add(timerId);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermissions() async => permissionRequests += 1;

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
  late DateTime now;
  late WorkflowMemoryStore store;
  late WorkflowNotifications notifications;
  late TimerController controller;

  setUp(() async {
    now = DateTime.utc(2026, 8, 19, 9);
    store = WorkflowMemoryStore();
    notifications = WorkflowNotifications();
    controller = TimerController(
      store: store,
      notifications: notifications,
      nowUtc: () => now,
    );
    await controller.initialize();
  });

  tearDown(() => controller.dispose());

  test(
    'requests notification permission only once per controller session',
    () async {
      await controller.addTimer(
        name: 'One',
        group: '',
        steps: const <IntervalStep>[
          IntervalStep(label: 'One', durationSeconds: 60),
        ],
      );
      await controller.addTimer(
        name: 'Two',
        group: '',
        steps: const <IntervalStep>[
          IntervalStep(label: 'Two', durationSeconds: 60),
        ],
      );

      expect(notifications.permissionRequests, 1);
      expect(notifications.scheduled, hasLength(2));
    },
  );

  test('duplicates a timer as a unique paused timer by default', () async {
    await controller.addTimer(
      name: 'Tea',
      group: 'Kitchen',
      steps: const <IntervalStep>[
        IntervalStep(label: 'Steep', durationSeconds: 180),
      ],
    );
    final original = controller.timers.single;

    await controller.duplicateTimer(original.id);

    expect(controller.timers, hasLength(2));
    final duplicate = controller.timers.last;
    expect(duplicate.id, isNot(original.id));
    expect(duplicate.name, 'Tea');
    expect(duplicate.group, 'Kitchen');
    expect(duplicate.status, CountdownStatus.paused);
    expect(duplicate.remainingWhenPausedSeconds, 180);
  });

  test(
    'updates timer name and group without changing countdown state',
    () async {
      await controller.addTimer(
        name: 'Old',
        group: '',
        steps: const <IntervalStep>[
          IntervalStep(label: 'Work', durationSeconds: 60),
        ],
      );
      final before = controller.timers.single;

      await controller.updateTimerDetails(
        timerId: before.id,
        name: '  New name  ',
        group: '  Focus  ',
      );

      final after = controller.timers.single;
      expect(after.name, 'New name');
      expect(after.group, 'Focus');
      expect(after.status, before.status);
      expect(after.endsAtUtc, before.endsAtUtc);
    },
  );

  test(
    'editing a paused timer does not request notification permission',
    () async {
      await controller.addTimer(
        name: 'Paused',
        group: '',
        steps: const <IntervalStep>[
          IntervalStep(label: 'Paused', durationSeconds: 60),
        ],
        startImmediately: false,
      );

      await controller.updateTimerDetails(
        timerId: controller.timers.single.id,
        name: 'Still paused',
        group: 'Later',
      );

      expect(notifications.permissionRequests, 0);
      expect(notifications.scheduled, isEmpty);
    },
  );

  test('pauses and resumes all eligible timers', () async {
    for (final name in <String>['One', 'Two']) {
      await controller.addTimer(
        name: name,
        group: 'Batch',
        steps: <IntervalStep>[IntervalStep(label: name, durationSeconds: 60)],
      );
    }

    now = now.add(const Duration(seconds: 10));
    await controller.pauseAllRunning();

    expect(controller.runningCount, 0);
    expect(controller.pausedCount, 2);
    expect(
      controller.timers.map((timer) => timer.remainingWhenPausedSeconds),
      everyElement(50),
    );

    await controller.resumeAllPaused();
    expect(controller.runningCount, 2);
    expect(controller.pausedCount, 0);
  });

  test(
    'valid import cancels notifications belonging to replaced timers',
    () async {
      await controller.addTimer(
        name: 'Old timer',
        group: '',
        steps: const <IntervalStep>[
          IntervalStep(label: 'Old', durationSeconds: 60),
        ],
      );
      final oldId = controller.timers.single.id;

      await controller.importJson('''
{
  "schemaVersion": 1,
  "timers": [],
  "presets": [],
  "history": [],
  "settings": {}
}
''');

      expect(notifications.cancelled, contains(oldId));
      expect(controller.timers, isEmpty);
    },
  );

  test(
    'future-schema import is rejected before replacing current state',
    () async {
      await controller.addTimer(
        name: 'Keep me',
        group: '',
        steps: const <IntervalStep>[
          IntervalStep(label: 'Keep me', durationSeconds: 60),
        ],
      );
      final id = controller.timers.single.id;

      await expectLater(
        controller.importJson('{"schemaVersion": 999}'),
        throwsFormatException,
      );

      expect(controller.timers.single.id, id);
      expect(controller.lastError, contains('schema'));
    },
  );

  test('clearAllData cancels timers and clears persisted state', () async {
    await controller.addTimer(
      name: 'Reset me',
      group: '',
      steps: const <IntervalStep>[
        IntervalStep(label: 'Reset me', durationSeconds: 60),
      ],
    );
    final id = controller.timers.single.id;

    await controller.clearAllData();

    expect(store.clearCount, 1);
    expect(notifications.cancelled, contains(id));
    expect(controller.timers, isEmpty);
    expect(controller.presets, isEmpty);
    expect(controller.history, isEmpty);
    expect(controller.settings, isA<CountoraSettings>());
  });

  test('history entries can be reused as fresh countdowns', () async {
    final entry = TimerHistoryEntry(
      timerId: 'old',
      name: 'Workout',
      group: 'Health',
      completedAtUtc: now.subtract(const Duration(hours: 1)),
      totalDurationSeconds: 90,
    );

    await controller.startFromHistory(entry);

    expect(controller.timers.single.name, 'Workout');
    expect(controller.timers.single.group, 'Health');
    expect(controller.timers.single.currentStep.durationSeconds, 90);
    expect(controller.timers.single.status, CountdownStatus.running);
  });
}
