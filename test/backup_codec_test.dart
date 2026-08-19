import 'dart:convert';

import 'package:countora/src/domain/backup_codec.dart';
import 'package:countora/src/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupCodec', () {
    test('round trips a valid version-one backup', () {
      final state = CountoraState(
        presets: const <TimerPreset>[
          TimerPreset(
            id: 'preset-1',
            name: 'Focus',
            group: 'Study',
            steps: <IntervalStep>[
              IntervalStep(label: 'Focus', durationSeconds: 1500),
            ],
            useCount: 4,
          ),
        ],
        settings: const CountoraSettings(onboardingSeen: true),
      );

      final decoded = BackupCodec.decode(BackupCodec.encode(state));

      expect(decoded.presets, hasLength(1));
      expect(decoded.presets.single.name, 'Focus');
      expect(decoded.settings.onboardingSeen, isTrue);
    });

    test('rejects fractional schema versions', () {
      final raw = jsonEncode(<String, Object?>{
        'schemaVersion': 1.5,
        'timers': <Object?>[],
        'presets': <Object?>[],
        'history': <Object?>[],
        'settings': const CountoraSettings().toJson(),
      });

      expect(() => BackupCodec.decode(raw), throwsFormatException);
    });

    test('rejects unsupported schema versions', () {
      final raw = jsonEncode(<String, Object?>{
        'schemaVersion': 99,
        'timers': <Object?>[],
        'presets': <Object?>[],
        'history': <Object?>[],
        'settings': const CountoraSettings().toJson(),
      });

      expect(() => BackupCodec.decode(raw), throwsFormatException);
    });

    test('rejects duplicate timer IDs', () {
      Map<String, Object?> timer(String name) => <String, Object?>{
            'id': 'duplicate',
            'name': name,
            'group': '',
            'steps': <Object?>[
              <String, Object?>{'label': name, 'durationSeconds': 60},
            ],
            'currentStepIndex': 0,
            'status': 'paused',
            'remainingWhenPausedSeconds': 60,
            'endsAtUtc': null,
            'startedAtUtc': null,
            'completedAtUtc': null,
          };

      final raw = jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'timers': <Object?>[timer('One'), timer('Two')],
        'presets': <Object?>[],
        'history': <Object?>[],
        'settings': const CountoraSettings().toJson(),
      });

      expect(() => BackupCodec.decode(raw), throwsFormatException);
    });

    test('rejects invalid interval durations instead of sanitizing them', () {
      final raw = jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'timers': <Object?>[
          <String, Object?>{
            'id': 'timer-1',
            'name': 'Bad timer',
            'group': '',
            'steps': <Object?>[
              <String, Object?>{'label': 'Bad', 'durationSeconds': 0},
            ],
            'currentStepIndex': 0,
            'status': 'paused',
            'remainingWhenPausedSeconds': 0,
            'endsAtUtc': null,
            'startedAtUtc': null,
            'completedAtUtc': null,
          },
        ],
        'presets': <Object?>[],
        'history': <Object?>[],
        'settings': const CountoraSettings().toJson(),
      });

      expect(() => BackupCodec.decode(raw), throwsFormatException);
    });

    test('rejects backups beyond the bounded import size', () {
      final oversized = 'x' * (BackupCodec.maxBackupBytes + 1);
      expect(() => BackupCodec.decode(oversized), throwsFormatException);
    });

    test('rejects non-object roots', () {
      expect(() => BackupCodec.decode('[]'), throwsFormatException);
    });
  });
}
