import 'dart:convert';
import 'dart:io';

import 'package:countora/src/data/state_codec.dart';
import 'package:countora/src/domain/models.dart';

const _defaultIterations = 100;
const _warmupIterations = 10;

void main(List<String> args) {
  final iterations = _readIterations(args);
  const codec = CountoraStateCodec();
  final state = _representativeState();
  final sample = codec.encode(state);
  final sampleBytes = utf8.encode(sample).length;

  if (sampleBytes > CountoraStateCodec.maxBackupBytes) {
    throw StateError(
      'Benchmark fixture is larger than CountoraStateCodec.maxBackupBytes.',
    );
  }

  for (var i = 0; i < _warmupIterations; i += 1) {
    final encoded = codec.encode(state);
    final decoded = codec.decode(encoded);
    _verifyDecoded(decoded);
  }

  final encodeMicros = <int>[];
  final decodeMicros = <int>[];

  for (var i = 0; i < iterations; i += 1) {
    final encodeWatch = Stopwatch()..start();
    final encoded = codec.encode(state);
    encodeWatch.stop();
    encodeMicros.add(encodeWatch.elapsedMicroseconds);

    final decodeWatch = Stopwatch()..start();
    final decoded = codec.decode(encoded);
    decodeWatch.stop();
    decodeMicros.add(decodeWatch.elapsedMicroseconds);
    _verifyDecoded(decoded);
  }

  final report = <String, Object?>{
    'benchmark': 'CountoraStateCodec',
    'iterations': iterations,
    'warmups': _warmupIterations,
    'fixture': <String, Object?>{
      'timers': state.timers.length,
      'presets': state.presets.length,
      'history': state.history.length,
      'intervalsPerTimer': state.timers.first.steps.length,
      'encodedBytes': sampleBytes,
      'maxBackupBytes': CountoraStateCodec.maxBackupBytes,
    },
    'encodeMicros': _summary(encodeMicros),
    'decodeMicros': _summary(decodeMicros),
  };

  // Machine-readable output makes it easy to archive measurements without
  // turning host-dependent timings into a fragile CI pass/fail threshold.
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
}

int _readIterations(List<String> args) {
  if (args.isEmpty) return _defaultIterations;
  if (args.length != 2 || args.first != '--iterations') {
    throw ArgumentError(
      'Usage: dart run tool/benchmark_state_codec.dart '
      '[--iterations <1..10000>]',
    );
  }
  final parsed = int.tryParse(args[1]);
  if (parsed == null || parsed < 1 || parsed > 10000) {
    throw ArgumentError.value(
      args[1],
      'iterations',
      'Use an integer between 1 and 10000.',
    );
  }
  return parsed;
}

CountoraState _representativeState() {
  final completedAt = DateTime.utc(2026, 8, 19, 9);
  const steps = <IntervalStep>[
    IntervalStep(label: 'Focus', durationSeconds: 25 * 60),
    IntervalStep(label: 'Short break', durationSeconds: 5 * 60),
    IntervalStep(label: 'Focus', durationSeconds: 25 * 60),
    IntervalStep(label: 'Long break', durationSeconds: 15 * 60),
  ];

  final timers = List<CountdownTimer>.generate(
    300,
    (index) => CountdownTimer(
      id: 'benchmark-timer-$index',
      name: 'Benchmark timer $index',
      group: 'Group ${index % 12}',
      steps: steps,
      currentStepIndex: index % steps.length,
      status: CountdownStatus.paused,
      remainingWhenPausedSeconds: steps[index % steps.length].durationSeconds,
    ),
    growable: false,
  );

  final presets = List<TimerPreset>.generate(
    200,
    (index) => TimerPreset(
      id: 'benchmark-preset-$index',
      name: 'Benchmark preset $index',
      group: 'Group ${index % 12}',
      steps: steps,
      useCount: index * 3,
    ),
    growable: false,
  );

  final history = List<TimerHistoryEntry>.generate(
    CountoraStateCodec.maxHistoryEntries,
    (index) => TimerHistoryEntry(
      timerId: 'history-timer-$index',
      name: 'Completed timer $index',
      group: 'Group ${index % 12}',
      completedAtUtc: completedAt.subtract(Duration(minutes: index)),
      totalDurationSeconds: 70 * 60,
    ),
    growable: false,
  );

  return CountoraState(
    timers: timers,
    presets: presets,
    history: history,
    settings: const CountoraSettings(onboardingSeen: true),
  );
}

void _verifyDecoded(CountoraState state) {
  if (state.timers.length != 300 ||
      state.presets.length != 200 ||
      state.history.length != CountoraStateCodec.maxHistoryEntries) {
    throw StateError('Benchmark round-trip changed fixture entity counts.');
  }
}

Map<String, int> _summary(List<int> values) {
  final sorted = [...values]..sort();
  return <String, int>{
    'min': sorted.first,
    'p50': _percentile(sorted, 0.50),
    'p95': _percentile(sorted, 0.95),
    'max': sorted.last,
  };
}

int _percentile(List<int> sorted, double percentile) {
  final index = ((sorted.length - 1) * percentile).round();
  return sorted[index.clamp(0, sorted.length - 1).toInt()];
}
