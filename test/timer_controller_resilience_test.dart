import 'package:countora/src/data/local_store.dart';
import 'package:countora/src/data/notification_service.dart';
import 'package:countora/src/domain/models.dart';
import 'package:countora/src/presentation/timer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingStore implements TimerStore {
  _FailingStore({
    this.failSave = false,
    this.failClear = false,
    CountoraState initialState = const CountoraState(),
  }) : _state = initialState;

  bool failSave;
  bool failClear;
  CountoraState _state;

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('simulated clear failure');
    _state = const CountoraState();
  }

  @override
  Future<CountoraState> load() async => _state;

  @override
  Future<void> save(CountoraState state) async {
    if (failSave) throw StateError('simulated save failure');
    _state = state;
  }
}

class _QuietNotifications implements NotificationService {
  int permissionRequests = 0;
  int scheduleCount = 0;
  int cancelCount = 0;

  @override
  Future<void> cancelTimer(String timerId) async {
    cancelCount += 1;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermissions() async {
    permissionRequests += 1;
  }

  @override
  Future<void> scheduleTimer(
    CountdownTimer timer, {
    required bool soundEnabled,
    required bool vibrationEnabled,
    required bool quietMode,
  }) async {
    scheduleCount += 1;
  }
}

void main() {
  test(
    'save failure is surfaced without escaping the UI-facing operation',
    () async {
      final store = _FailingStore(failSave: true);
      final controller = TimerController(
        store: store,
        notifications: _QuietNotifications(),
        nowUtc: () => DateTime.utc(2026, 8, 19, 9),
      );
      addTearDown(controller.dispose);
      await controller.initialize();

      await expectLater(
        controller.addTimer(
          name: 'Unsaved timer',
          group: '',
          steps: const <IntervalStep>[
            IntervalStep(label: 'Timer', durationSeconds: 60),
          ],
          startImmediately: false,
        ),
        completes,
      );

      expect(controller.timers, hasLength(1));
      expect(controller.lastError, contains('could not save'));
    },
  );

  test(
    'failed persistence does not create a platform notification schedule',
    () async {
      final store = _FailingStore(failSave: true);
      final notifications = _QuietNotifications();
      final controller = TimerController(
        store: store,
        notifications: notifications,
        nowUtc: () => DateTime.utc(2026, 8, 19, 9),
      );
      addTearDown(controller.dispose);
      await controller.initialize();

      await controller.updateSettings(
        controller.settings.copyWith(notificationsEnabled: true),
      );
      expect(controller.lastError, contains('could not save'));

      controller.clearError();
      await controller.addTimer(
        name: 'Unsaved running timer',
        group: '',
        steps: const <IntervalStep>[
          IntervalStep(label: 'Timer', durationSeconds: 60),
        ],
      );

      expect(controller.timers, hasLength(1));
      expect(controller.lastError, contains('could not save'));
      expect(notifications.scheduleCount, 0);
    },
  );

  test('failed pause persistence leaves platform schedule untouched', () async {
    final store = _FailingStore();
    final notifications = _QuietNotifications();
    final controller = TimerController(
      store: store,
      notifications: notifications,
      nowUtc: () => DateTime.utc(2026, 8, 19, 9),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.addTimer(
      name: 'Running timer',
      group: '',
      steps: const <IntervalStep>[
        IntervalStep(label: 'Timer', durationSeconds: 60),
      ],
    );
    expect(notifications.scheduleCount, 1);

    store.failSave = true;
    await controller.pause(controller.timers.single.id);

    expect(controller.lastError, contains('could not save'));
    expect(notifications.cancelCount, 0);
  });

  test(
    'failed removal persistence leaves platform schedule untouched',
    () async {
      final store = _FailingStore();
      final notifications = _QuietNotifications();
      final controller = TimerController(
        store: store,
        notifications: notifications,
        nowUtc: () => DateTime.utc(2026, 8, 19, 9),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.addTimer(
        name: 'Running timer',
        group: '',
        steps: const <IntervalStep>[
          IntervalStep(label: 'Timer', durationSeconds: 60),
        ],
      );
      final id = controller.timers.single.id;

      store.failSave = true;
      await controller.removeTimer(id);

      expect(controller.lastError, contains('could not save'));
      expect(notifications.cancelCount, 0);
    },
  );

  test(
    'failed settings persistence leaves notification schedules untouched',
    () async {
      final store = _FailingStore();
      final notifications = _QuietNotifications();
      final controller = TimerController(
        store: store,
        notifications: notifications,
        nowUtc: () => DateTime.utc(2026, 8, 19, 9),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.addTimer(
        name: 'Running timer',
        group: '',
        steps: const <IntervalStep>[
          IntervalStep(label: 'Timer', durationSeconds: 60),
        ],
      );
      expect(notifications.scheduleCount, 1);

      store.failSave = true;
      await controller.updateSettings(
        controller.settings.copyWith(notificationsEnabled: false),
      );

      expect(controller.lastError, contains('could not save'));
      expect(notifications.cancelCount, 0);
      expect(notifications.scheduleCount, 1);
    },
  );

  test('failed reconciliation persistence does not cancel schedules', () async {
    final now = DateTime.utc(2026, 8, 19, 9);
    final notifications = _QuietNotifications();
    final store = _FailingStore(
      failSave: true,
      initialState: CountoraState(
        timers: <CountdownTimer>[
          CountdownTimer(
            id: 'expired',
            name: 'Expired',
            group: '',
            steps: const <IntervalStep>[
              IntervalStep(label: 'Timer', durationSeconds: 60),
            ],
            currentStepIndex: 0,
            status: CountdownStatus.running,
            remainingWhenPausedSeconds: 60,
            startedAtUtc: now.subtract(const Duration(minutes: 2)),
            endsAtUtc: now.subtract(const Duration(minutes: 1)),
          ),
        ],
      ),
    );
    final controller = TimerController(
      store: store,
      notifications: notifications,
      nowUtc: () => now,
    );
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.timers.single.status, CountdownStatus.completed);
    expect(controller.lastError, contains('could not save'));
    expect(notifications.cancelCount, 0);
    expect(notifications.scheduleCount, 0);
  });

  test('failed import persistence restores prior in-memory state', () async {
    final store = _FailingStore(
      initialState: const CountoraState(
        settings: CountoraSettings(notificationsEnabled: false),
        timers: <CountdownTimer>[
          CountdownTimer(
            id: 'original',
            name: 'Original',
            group: '',
            steps: <IntervalStep>[
              IntervalStep(label: 'Timer', durationSeconds: 60),
            ],
            currentStepIndex: 0,
            status: CountdownStatus.paused,
            remainingWhenPausedSeconds: 60,
          ),
        ],
      ),
    );
    final notifications = _QuietNotifications();
    final controller = TimerController(
      store: store,
      notifications: notifications,
      nowUtc: () => DateTime.utc(2026, 8, 19, 9),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    store.failSave = true;

    await expectLater(
      controller.importJson('''
{
  "schemaVersion": 1,
  "timers": [
    {
      "id": "replacement",
      "name": "Replacement",
      "group": "",
      "steps": [{"label":"Timer","durationSeconds":120}],
      "currentStepIndex": 0,
      "status": "paused",
      "remainingWhenPausedSeconds": 120
    }
  ],
  "presets": [],
  "history": [],
  "settings": {"notificationsEnabled": false}
}
'''),
      throwsA(isA<StateError>()),
    );

    expect(controller.timers.single.id, 'original');
    expect(controller.timers.single.name, 'Original');
    expect(controller.lastError, contains('could not save'));
    expect(notifications.cancelCount, 0);
  });

  test(
    'clear failure keeps in-memory state and exposes safe error text',
    () async {
      final store = _FailingStore();
      final controller = TimerController(
        store: store,
        notifications: _QuietNotifications(),
        nowUtc: () => DateTime.utc(2026, 8, 19, 9),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      await controller.addTimer(
        name: 'Keep me',
        group: '',
        steps: const <IntervalStep>[
          IntervalStep(label: 'Timer', durationSeconds: 60),
        ],
        startImmediately: false,
      );
      store.failClear = true;

      await controller.clearAllData();

      expect(controller.timers, hasLength(1));
      expect(controller.lastError, contains('could not erase'));
    },
  );
}
