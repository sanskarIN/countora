import 'package:countora/src/data/local_store.dart';
import 'package:countora/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persists and restores local Countora state', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesTimerStore(preferences);
    final state = CountoraState(
      timers: const <CountdownTimer>[
        CountdownTimer(
          id: 'tea',
          name: 'Tea',
          group: 'Kitchen',
          steps: <IntervalStep>[
            IntervalStep(label: 'Steep', durationSeconds: 180),
          ],
          currentStepIndex: 0,
          status: CountdownStatus.paused,
          remainingWhenPausedSeconds: 120,
        ),
      ],
    );

    await store.save(state);
    final restored = await store.load();

    expect(restored.timers.single.id, 'tea');
    expect(restored.timers.single.remainingWhenPausedSeconds, 120);
  });

  test('recovers to empty state when persisted JSON is corrupted', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'countora_state_v1': '{ definitely not valid json',
    });
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesTimerStore(preferences);

    final restored = await store.load();

    expect(restored.timers, isEmpty);
    expect(restored.presets, isEmpty);
    expect(restored.history, isEmpty);
  });

  test('recovers to empty state when persisted field types are invalid', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'countora_state_v1':
          '{"schemaVersion":1,"timers":[{"id":"x","steps":"wrong"}]}',
    });
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesTimerStore(preferences);

    final restored = await store.load();

    expect(restored.timers, isEmpty);
  });

  test('clear removes stored state', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesTimerStore(preferences);
    await store.save(
      const CountoraState(
        presets: <TimerPreset>[
          TimerPreset(
            id: 'preset',
            name: 'Preset',
            group: '',
            steps: <IntervalStep>[
              IntervalStep(label: 'Preset', durationSeconds: 60),
            ],
            useCount: 0,
          ),
        ],
      ),
    );

    await store.clear();

    expect((await store.load()).presets, isEmpty);
  });
}
