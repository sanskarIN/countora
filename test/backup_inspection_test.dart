import 'package:countora/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/src/backup_inspection.dart';

void main() {
  test('summarizes entity, status, and interval counts without user text', () {
    final state = CountoraState(
      timers: const <CountdownTimer>[
        CountdownTimer(
          id: 'running',
          name: 'Private running name',
          group: 'Private group',
          steps: <IntervalStep>[
            IntervalStep(label: 'One', durationSeconds: 60),
            IntervalStep(label: 'Two', durationSeconds: 30),
          ],
          currentStepIndex: 0,
          status: CountdownStatus.running,
          remainingWhenPausedSeconds: 60,
        ),
        CountdownTimer(
          id: 'paused',
          name: 'Private paused name',
          group: '',
          steps: <IntervalStep>[
            IntervalStep(label: 'Only', durationSeconds: 90),
          ],
          currentStepIndex: 0,
          status: CountdownStatus.paused,
          remainingWhenPausedSeconds: 45,
        ),
        CountdownTimer(
          id: 'complete',
          name: 'Private completed name',
          group: '',
          steps: <IntervalStep>[
            IntervalStep(label: 'Done', durationSeconds: 10),
          ],
          currentStepIndex: 0,
          status: CountdownStatus.completed,
          remainingWhenPausedSeconds: 0,
        ),
      ],
      presets: const <TimerPreset>[
        TimerPreset(
          id: 'preset',
          name: 'Private preset',
          group: '',
          steps: <IntervalStep>[
            IntervalStep(label: 'A', durationSeconds: 25),
            IntervalStep(label: 'B', durationSeconds: 5),
          ],
          useCount: 4,
        ),
      ],
      history: <TimerHistoryEntry>[
        TimerHistoryEntry(
          timerId: 'history',
          name: 'Private history name',
          group: '',
          completedAtUtc: DateTime.utc(2026, 8, 19, 9),
          totalDurationSeconds: 30,
        ),
      ],
    );

    final inspection = inspectCountoraState(state, encodedBytes: 1234);
    final json = inspection.toJson();

    expect(inspection.encodedBytes, 1234);
    expect(inspection.timerCount, 3);
    expect(inspection.runningTimerCount, 1);
    expect(inspection.pausedTimerCount, 1);
    expect(inspection.completedTimerCount, 1);
    expect(inspection.presetCount, 1);
    expect(inspection.historyCount, 1);
    expect(inspection.totalTimerSteps, 4);
    expect(inspection.totalPresetSteps, 2);
    expect(json.toString(), isNot(contains('Private')));
  });

  test('empty state produces zero counts', () {
    final inspection = inspectCountoraState(
      const CountoraState(),
      encodedBytes: 2,
    );

    expect(inspection.timerCount, 0);
    expect(inspection.runningTimerCount, 0);
    expect(inspection.pausedTimerCount, 0);
    expect(inspection.completedTimerCount, 0);
    expect(inspection.presetCount, 0);
    expect(inspection.historyCount, 0);
    expect(inspection.totalTimerSteps, 0);
    expect(inspection.totalPresetSteps, 0);
  });
}
