import 'dart:convert';

import 'package:countora/src/data/state_codec.dart';
import 'package:countora/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = CountoraStateCodec();

  group('CountoraStateCodec', () {
    test('round trips supported state', () {
      final state = CountoraState(
        timers: <CountdownTimer>[
          CountdownTimer(
            id: 'timer-1',
            name: 'Tea',
            group: 'Kitchen',
            steps: const <IntervalStep>[
              IntervalStep(label: 'Steep', durationSeconds: 180),
            ],
            currentStepIndex: 0,
            status: CountdownStatus.paused,
            remainingWhenPausedSeconds: 120,
          ),
        ],
        presets: const <TimerPreset>[
          TimerPreset(
            id: 'preset-1',
            name: 'Pomodoro',
            group: 'Study',
            steps: <IntervalStep>[
              IntervalStep(label: 'Focus', durationSeconds: 1500),
            ],
            useCount: 2,
          ),
        ],
      );

      final decoded = codec.decode(codec.encode(state));

      expect(decoded.timers.single.name, 'Tea');
      expect(decoded.timers.single.remainingWhenPausedSeconds, 120);
      expect(decoded.presets.single.useCount, 2);
    });

    test('encoded state includes the current schema version', () {
      final encoded = jsonDecode(codec.encode(const CountoraState())) as Map;

      expect(
        encoded['schemaVersion'],
        CountoraStateCodec.currentSchemaVersion,
      );
    });

    test('migrates legacy unversioned state to the current schema', () {
      final decoded = codec.decode(
        '{"timers":[],"presets":[],"history":[],"settings":{}}',
      );

      expect(decoded.timers, isEmpty);
      expect(decoded.presets, isEmpty);
    });

    test('rejects backups from a future schema', () {
      expect(
        () => codec.decode('{"schemaVersion":999}'),
        throwsFormatException,
      );
    });

    test('rejects a non-object backup root', () {
      expect(() => codec.decode('[1,2,3]'), throwsFormatException);
    });

    test('rejects malformed field types as format errors', () {
      expect(
        () => codec.decode('''
{
  "schemaVersion": 1,
  "timers": [
    {
      "id": "bad-types",
      "name": "Bad",
      "steps": [{"label":"Timer","durationSeconds":"sixty"}],
      "status": "paused",
      "remainingWhenPausedSeconds": 60
    }
  ]
}
'''),
        throwsFormatException,
      );
    });

    test('sanitizes duplicate ids and malformed interval data', () {
      final decoded = codec.decode('''
{
  "schemaVersion": 1,
  "timers": [
    {
      "id": "duplicate",
      "name": "  Recovered timer  ",
      "group": "Kitchen",
      "steps": [{"label":"Bad","durationSeconds":-5}],
      "currentStepIndex": 99,
      "status": "running",
      "remainingWhenPausedSeconds": -10
    },
    {
      "id": "duplicate",
      "name": "Should be dropped",
      "steps": [{"label":"Timer","durationSeconds":60}],
      "status": "paused",
      "remainingWhenPausedSeconds": 60
    }
  ],
  "presets": [],
  "history": [],
  "settings": {}
}
''');

      expect(decoded.timers, hasLength(1));
      expect(decoded.timers.single.name, 'Recovered timer');
      expect(decoded.timers.single.steps, hasLength(1));
      expect(decoded.timers.single.currentStep.durationSeconds, 60);
      expect(decoded.timers.single.status, CountdownStatus.paused);
      expect(decoded.timers.single.remainingWhenPausedSeconds, 0);
    });

    test('bounds oversized names, groups and use counts', () {
      final longName = List<String>.filled(120, 'n', growable: false).join();
      final longGroup = List<String>.filled(80, 'g', growable: false).join();
      final decoded = codec.decode('''
{
  "schemaVersion": 1,
  "timers": [],
  "presets": [
    {
      "id": "p1",
      "name": "$longName",
      "group": "$longGroup",
      "steps": [{"label":"Focus","durationSeconds":60}],
      "useCount": -2
    }
  ],
  "history": [],
  "settings": {}
}
''');

      expect(decoded.presets.single.name.length, 80);
      expect(decoded.presets.single.group.length, 40);
      expect(decoded.presets.single.useCount, 0);
    });
  });
}
