import 'package:countora/src/domain/models.dart';

class BackupInspection {
  const BackupInspection({
    required this.encodedBytes,
    required this.timerCount,
    required this.runningTimerCount,
    required this.pausedTimerCount,
    required this.completedTimerCount,
    required this.presetCount,
    required this.historyCount,
    required this.totalTimerSteps,
    required this.totalPresetSteps,
  });

  final int encodedBytes;
  final int timerCount;
  final int runningTimerCount;
  final int pausedTimerCount;
  final int completedTimerCount;
  final int presetCount;
  final int historyCount;
  final int totalTimerSteps;
  final int totalPresetSteps;

  Map<String, Object?> toJson() => <String, Object?>{
    'encodedBytes': encodedBytes,
    'timers': <String, int>{
      'total': timerCount,
      'running': runningTimerCount,
      'paused': pausedTimerCount,
      'completed': completedTimerCount,
      'intervalSteps': totalTimerSteps,
    },
    'presets': <String, int>{
      'total': presetCount,
      'intervalSteps': totalPresetSteps,
    },
    'historyEntries': historyCount,
  };
}

BackupInspection inspectCountoraState(
  CountoraState state, {
  required int encodedBytes,
}) {
  var running = 0;
  var paused = 0;
  var completed = 0;
  var timerSteps = 0;

  for (final timer in state.timers) {
    timerSteps += timer.steps.length;
    switch (timer.status) {
      case CountdownStatus.running:
        running += 1;
      case CountdownStatus.paused:
        paused += 1;
      case CountdownStatus.completed:
        completed += 1;
    }
  }

  var presetSteps = 0;
  for (final preset in state.presets) {
    presetSteps += preset.steps.length;
  }

  return BackupInspection(
    encodedBytes: encodedBytes,
    timerCount: state.timers.length,
    runningTimerCount: running,
    pausedTimerCount: paused,
    completedTimerCount: completed,
    presetCount: state.presets.length,
    historyCount: state.history.length,
    totalTimerSteps: timerSteps,
    totalPresetSteps: presetSteps,
  );
}
