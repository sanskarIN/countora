import 'dart:convert';
import 'dart:math';

import 'package:countora/src/data/state_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = CountoraStateCodec();

  test('random malformed JSON shapes either decode safely or fail as FormatException', () {
    final random = Random(20260819);

    for (var iteration = 0; iteration < 500; iteration += 1) {
      final candidate = _randomJsonValue(random, depth: 0);
      final raw = jsonEncode(candidate);

      try {
        codec.decode(raw);
      } on FormatException {
        // Expected rejection type for untrusted backup data.
      } on Object catch (error, stackTrace) {
        fail(
          'Iteration $iteration escaped with ${error.runtimeType}: $error\n'
          'Input: $raw\n$stackTrace',
        );
      }
    }
  });

  test('backup size limit rejects oversized payload before model parsing', () {
    final padding = List<String>.filled(
      CountoraStateCodec.maxBackupBytes + 1,
      'x',
      growable: false,
    ).join();
    final oversized = jsonEncode(<String, Object?>{
      'schemaVersion': 1,
      'padding': padding,
    });

    expect(() => codec.decode(oversized), throwsFormatException);
  });
}

Object? _randomJsonValue(Random random, {required int depth}) {
  if (depth >= 4) return _randomScalar(random);

  switch (random.nextInt(6)) {
    case 0:
      return _randomScalar(random);
    case 1:
      return List<Object?>.generate(
        random.nextInt(5),
        (_) => _randomJsonValue(random, depth: depth + 1),
      );
    default:
      return <String, Object?>{
        for (var index = 0; index < random.nextInt(8); index += 1)
          _randomKey(random, index): _randomJsonValue(
            random,
            depth: depth + 1,
          ),
      };
  }
}

Object? _randomScalar(Random random) {
  switch (random.nextInt(7)) {
    case 0:
      return null;
    case 1:
      return random.nextBool();
    case 2:
      return random.nextInt(2000) - 1000;
    case 3:
      return random.nextDouble() * 2000 - 1000;
    case 4:
      return 'value-${random.nextInt(1000)}';
    case 5:
      return '';
    default:
      return '2026-08-${(random.nextInt(28) + 1).toString().padLeft(2, '0')}';
  }
}

String _randomKey(Random random, int index) {
  const known = <String>[
    'schemaVersion',
    'timers',
    'presets',
    'history',
    'settings',
    'id',
    'name',
    'group',
    'steps',
    'label',
    'durationSeconds',
    'currentStepIndex',
    'status',
    'remainingWhenPausedSeconds',
    'endsAtUtc',
    'startedAtUtc',
    'completedAtUtc',
    'themeMode',
    'useCount',
  ];

  if (random.nextBool()) return known[random.nextInt(known.length)];
  return 'unknown_${index.abs()}_${random.nextInt(50)}';
}
