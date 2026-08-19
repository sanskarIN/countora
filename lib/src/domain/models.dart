import 'package:flutter/material.dart';

enum CountdownStatus { running, paused, completed }

extension CountdownStatusCodec on CountdownStatus {
  static CountdownStatus parse(String value) =>
      CountdownStatus.values.firstWhere(
        (item) => item.name == value,
        orElse: () => CountdownStatus.paused,
      );
}

class IntervalStep {
  const IntervalStep({
    required this.label,
    required this.durationSeconds,
  });

  final String label;
  final int durationSeconds;

  Map<String, Object?> toJson() => {
        'label': label,
        'durationSeconds': durationSeconds,
      };

  factory IntervalStep.fromJson(Map<String, Object?> json) {
    final rawLabel = json['label'] as String?;
    return IntervalStep(
      label: rawLabel != null && rawLabel.trim().isNotEmpty
          ? rawLabel
          : 'Interval',
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 60,
    );
  }
}

class CountdownTimer {
  const CountdownTimer({
    required this.id,
    required this.name,
    required this.group,
    required this.steps,
    required this.currentStepIndex,
    required this.status,
    required this.remainingWhenPausedSeconds,
    this.endsAtUtc,
    this.startedAtUtc,
    this.completedAtUtc,
  });

  final String id;
  final String name;
  final String group;
  final List<IntervalStep> steps;
  final int currentStepIndex;
  final CountdownStatus status;
  final int remainingWhenPausedSeconds;
  final DateTime? endsAtUtc;
  final DateTime? startedAtUtc;
  final DateTime? completedAtUtc;

  IntervalStep get currentStep =>
      steps[currentStepIndex.clamp(0, steps.length - 1).toInt()];

  bool get isSequence => steps.length > 1;

  int get totalDurationSeconds =>
      steps.fold<int>(0, (sum, step) => sum + step.durationSeconds);

  Duration remaining(DateTime nowUtc) {
    if (status == CountdownStatus.completed) return Duration.zero;
    if (status == CountdownStatus.paused) {
      return Duration(seconds: remainingWhenPausedSeconds);
    }
    final end = endsAtUtc;
    if (end == null) return Duration.zero;
    final result = end.difference(nowUtc);
    return result.isNegative ? Duration.zero : result;
  }

  CountdownTimer copyWith({
    String? name,
    String? group,
    List<IntervalStep>? steps,
    int? currentStepIndex,
    CountdownStatus? status,
    int? remainingWhenPausedSeconds,
    DateTime? endsAtUtc,
    bool clearEndsAt = false,
    DateTime? startedAtUtc,
    bool clearStartedAt = false,
    DateTime? completedAtUtc,
    bool clearCompletedAt = false,
  }) {
    return CountdownTimer(
      id: id,
      name: name ?? this.name,
      group: group ?? this.group,
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      status: status ?? this.status,
      remainingWhenPausedSeconds:
          remainingWhenPausedSeconds ?? this.remainingWhenPausedSeconds,
      endsAtUtc: clearEndsAt ? null : (endsAtUtc ?? this.endsAtUtc),
      startedAtUtc:
          clearStartedAt ? null : (startedAtUtc ?? this.startedAtUtc),
      completedAtUtc:
          clearCompletedAt ? null : (completedAtUtc ?? this.completedAtUtc),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'group': group,
        'steps': steps.map((step) => step.toJson()).toList(),
        'currentStepIndex': currentStepIndex,
        'status': status.name,
        'remainingWhenPausedSeconds': remainingWhenPausedSeconds,
        'endsAtUtc': endsAtUtc?.toIso8601String(),
        'startedAtUtc': startedAtUtc?.toIso8601String(),
        'completedAtUtc': completedAtUtc?.toIso8601String(),
      };

  factory CountdownTimer.fromJson(Map<String, Object?> json) {
    final rawSteps = (json['steps'] as List<Object?>? ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(
          (entry) => IntervalStep.fromJson(
            entry.map((key, value) => MapEntry('$key', value)),
          ),
        )
        .where((step) => step.durationSeconds > 0)
        .toList();

    final safeSteps = rawSteps.isEmpty
        ? const <IntervalStep>[
            IntervalStep(label: 'Timer', durationSeconds: 60),
          ]
        : rawSteps;

    final rawIndex = (json['currentStepIndex'] as num?)?.toInt() ?? 0;
    final index = rawIndex.clamp(0, safeSteps.length - 1).toInt();

    DateTime? parseDate(Object? value) =>
        value is String ? DateTime.tryParse(value)?.toUtc() : null;

    return CountdownTimer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Timer',
      group: json['group'] as String? ?? '',
      steps: safeSteps,
      currentStepIndex: index,
      status:
          CountdownStatusCodec.parse(json['status'] as String? ?? 'paused'),
      remainingWhenPausedSeconds:
          (json['remainingWhenPausedSeconds'] as num?)?.toInt() ??
              safeSteps[index].durationSeconds,
      endsAtUtc: parseDate(json['endsAtUtc']),
      startedAtUtc: parseDate(json['startedAtUtc']),
      completedAtUtc: parseDate(json['completedAtUtc']),
    );
  }
}

class TimerPreset {
  const TimerPreset({
    required this.id,
    required this.name,
    required this.group,
    required this.steps,
    required this.useCount,
  });

  final String id;
  final String name;
  final String group;
  final List<IntervalStep> steps;
  final int useCount;

  TimerPreset copyWith({int? useCount}) => TimerPreset(
        id: id,
        name: name,
        group: group,
        steps: steps,
        useCount: useCount ?? this.useCount,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'group': group,
        'steps': steps.map((step) => step.toJson()).toList(),
        'useCount': useCount,
      };

  factory TimerPreset.fromJson(Map<String, Object?> json) {
    final steps = (json['steps'] as List<Object?>? ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(
          (entry) => IntervalStep.fromJson(
            entry.map((key, value) => MapEntry('$key', value)),
          ),
        )
        .where((step) => step.durationSeconds > 0)
        .toList();

    return TimerPreset(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Preset',
      group: json['group'] as String? ?? '',
      steps: steps.isEmpty
          ? const <IntervalStep>[
              IntervalStep(label: 'Timer', durationSeconds: 60),
            ]
          : steps,
      useCount: (json['useCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class TimerHistoryEntry {
  const TimerHistoryEntry({
    required this.timerId,
    required this.name,
    required this.group,
    required this.completedAtUtc,
    required this.totalDurationSeconds,
  });

  final String timerId;
  final String name;
  final String group;
  final DateTime completedAtUtc;
  final int totalDurationSeconds;

  Map<String, Object?> toJson() => {
        'timerId': timerId,
        'name': name,
        'group': group,
        'completedAtUtc': completedAtUtc.toIso8601String(),
        'totalDurationSeconds': totalDurationSeconds,
      };

  factory TimerHistoryEntry.fromJson(Map<String, Object?> json) {
    return TimerHistoryEntry(
      timerId: json['timerId'] as String? ?? '',
      name: json['name'] as String? ?? 'Timer',
      group: json['group'] as String? ?? '',
      completedAtUtc:
          DateTime.tryParse(json['completedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      totalDurationSeconds:
          (json['totalDurationSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}

class CountoraSettings {
  const CountoraSettings({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietMode = false,
    this.reducedMotion = false,
    this.compactCards = false,
    this.onboardingSeen = false,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool quietMode;
  final bool reducedMotion;
  final bool compactCards;
  final bool onboardingSeen;

  CountoraSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? quietMode,
    bool? reducedMotion,
    bool? compactCards,
    bool? onboardingSeen,
  }) {
    return CountoraSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietMode: quietMode ?? this.quietMode,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      compactCards: compactCards ?? this.compactCards,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    );
  }

  Map<String, Object?> toJson() => {
        'themeMode': themeMode.name,
        'notificationsEnabled': notificationsEnabled,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'quietMode': quietMode,
        'reducedMotion': reducedMotion,
        'compactCards': compactCards,
        'onboardingSeen': onboardingSeen,
      };

  factory CountoraSettings.fromJson(Map<String, Object?> json) {
    final themeMode = ThemeMode.values.firstWhere(
      (item) => item.name == json['themeMode'],
      orElse: () => ThemeMode.system,
    );
    bool readBool(String key, bool fallback) => json[key] as bool? ?? fallback;

    return CountoraSettings(
      themeMode: themeMode,
      notificationsEnabled: readBool('notificationsEnabled', true),
      soundEnabled: readBool('soundEnabled', true),
      vibrationEnabled: readBool('vibrationEnabled', true),
      quietMode: readBool('quietMode', false),
      reducedMotion: readBool('reducedMotion', false),
      compactCards: readBool('compactCards', false),
      onboardingSeen: readBool('onboardingSeen', false),
    );
  }
}

class CountoraState {
  const CountoraState({
    this.timers = const <CountdownTimer>[],
    this.presets = const <TimerPreset>[],
    this.history = const <TimerHistoryEntry>[],
    this.settings = const CountoraSettings(),
  });

  final List<CountdownTimer> timers;
  final List<TimerPreset> presets;
  final List<TimerHistoryEntry> history;
  final CountoraSettings settings;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'timers': timers.map((item) => item.toJson()).toList(),
        'presets': presets.map((item) => item.toJson()).toList(),
        'history': history.map((item) => item.toJson()).toList(),
        'settings': settings.toJson(),
      };

  factory CountoraState.fromJson(Map<String, Object?> json) {
    List<Map<String, Object?>> maps(String key) =>
        (json[key] as List<Object?>? ?? const <Object?>[])
            .whereType<Map<Object?, Object?>>()
            .map(
              (entry) =>
                  entry.map((key, value) => MapEntry('$key', value)),
            )
            .toList();

    final settingsRaw = json['settings'];
    final settings = settingsRaw is Map<Object?, Object?>
        ? CountoraSettings.fromJson(
            settingsRaw.map((key, value) => MapEntry('$key', value)),
          )
        : const CountoraSettings();

    return CountoraState(
      timers: maps('timers')
          .map(CountdownTimer.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList(),
      presets: maps('presets')
          .map(TimerPreset.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList(),
      history: maps('history').map(TimerHistoryEntry.fromJson).toList(),
      settings: settings,
    );
  }
}
