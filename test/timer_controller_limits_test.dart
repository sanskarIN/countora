import 'package:countora/src/data/local_store.dart';
import 'package:countora/src/data/notification_service.dart';
import 'package:countora/src/data/state_codec.dart';
import 'package:countora/src/domain/models.dart';
import 'package:countora/src/presentation/timer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements TimerStore {
  _MemoryStore(this.state);

  CountoraState state;
  int saveCount = 0;

  @override
  Future<void> clear() async {
    state = const CountoraState();
  }

  @override
  Future<CountoraState> load() async => state;

  @override
  Future<void> save(CountoraState value) async {
    saveCount += 1;
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

CountdownTimer _pausedTimer(int index) => CountdownTimer(
      id: 'timer_$index',
      name: 'Timer $index',
      group: '',
      steps: const <IntervalStep>[
        IntervalStep(label: 'Timer', durationSeconds: 60),
      ],
      currentStepIndex: 0,
      status: CountdownStatus.paused,
      remainingWhenPausedSeconds: 60,
    );

TimerPreset _preset(int index, {int useCount = 0}) => TimerPreset(
      id: 'preset_$index',
      name: 'Preset $index',
      group: '',
      steps: const <IntervalStep>[
        IntervalStep(label: 'Timer', durationSeconds: 60),
      ],
      useCount: useCount,
    );

void main() {
  test('does not create a timer beyond the persisted timer limit', () async {
    final store = _MemoryStore(
      CountoraState(
        timers: List<CountdownTimer>.generate(
          CountoraStateCodec.maxTimers,
          _pausedTimer,
          growable: false,
        ),
      ),
    );
    final controller = TimerController(
      store: store,
      notifications: _NoopNotifications(),
      nowUtc: () => DateTime.utc(2026, 8, 20),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.addTimer(
      name: 'One too many',
      group: '',
      steps: const <IntervalStep>[
        IntervalStep(label: 'Timer', durationSeconds: 60),
      ],
      startImmediately: false,
    );

    expect(controller.timers, hasLength(CountoraStateCodec.maxTimers));
    expect(controller.lastError, contains('${CountoraStateCodec.maxTimers}'));
    expect(store.saveCount, 0);
  });

  test('does not create a preset beyond the persisted preset limit', () async {
    final store = _MemoryStore(
      CountoraState(
        presets: List<TimerPreset>.generate(
          CountoraStateCodec.maxPresets,
          _preset,
          growable: false,
        ),
      ),
    );
    final controller = TimerController(
      store: store,
      notifications: _NoopNotifications(),
      nowUtc: () => DateTime.utc(2026, 8, 20),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.addPreset(
      name: 'One too many',
      group: '',
      steps: const <IntervalStep>[
        IntervalStep(label: 'Timer', durationSeconds: 60),
      ],
    );

    expect(controller.presets, hasLength(CountoraStateCodec.maxPresets));
    expect(controller.lastError, contains('${CountoraStateCodec.maxPresets}'));
    expect(store.saveCount, 0);
  });

  test('full timer capacity does not increment preset usage', () async {
    final store = _MemoryStore(
      CountoraState(
        timers: List<CountdownTimer>.generate(
          CountoraStateCodec.maxTimers,
          _pausedTimer,
          growable: false,
        ),
        presets: <TimerPreset>[_preset(1, useCount: 7)],
      ),
    );
    final controller = TimerController(
      store: store,
      notifications: _NoopNotifications(),
      nowUtc: () => DateTime.utc(2026, 8, 20),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.startPreset('preset_1');

    expect(controller.timers, hasLength(CountoraStateCodec.maxTimers));
    expect(controller.presets.single.useCount, 7);
    expect(controller.lastError, contains('${CountoraStateCodec.maxTimers}'));
    expect(store.saveCount, 0);
  });
}
