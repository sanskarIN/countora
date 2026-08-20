import 'dart:convert';

import '../domain/models.dart';

/// Encodes and validates Countora's persisted local state.
///
/// The codec intentionally keeps persistence concerns outside the domain models:
/// models remain easy to use in tests while all untrusted JSON is bounded,
/// migrated, and sanitized at the storage/import boundary.
class CountoraStateCodec {
  const CountoraStateCodec();

  static const int currentSchemaVersion = 1;
  static const int maxBackupBytes = 2 * 1024 * 1024;
  static const int maxTimers = 500;
  static const int maxPresets = 500;
  static const int maxHistoryEntries = 500;
  static const int maxIntervalsPerTimer = 32;
  static const int maxIdLength = 128;
  static const int maxNameLength = 80;
  static const int maxGroupLength = 40;
  static const int maxIntervalSeconds = 365 * 24 * 60 * 60;
  static const int maxRemainingSeconds = 10 * 365 * 24 * 60 * 60;

  String encode(CountoraState state) => jsonEncode(_encodedMap(state));

  String encodePretty(CountoraState state) =>
      const JsonEncoder.withIndent('  ').convert(_encodedMap(state));

  Map<String, Object?> _encodedMap(CountoraState state) => <String, Object?>{
        ...state.toJson(),
        // The persistence codec owns schema evolution. Keep this last so a
        // model-level serialization default can never override the current
        // persisted schema during a future migration.
        'schemaVersion': currentSchemaVersion,
      };

  CountoraState decode(String raw) {
    if (raw.trim().isEmpty) {
      throw const FormatException('The backup is empty.');
    }
    if (utf8.encode(raw).length > maxBackupBytes) {
      throw const FormatException('The backup is larger than 2 MiB.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      rethrow;
    }
    if (decoded is! Map<Object?, Object?>) {
      throw const FormatException('The backup root must be a JSON object.');
    }

    final root = decoded.map((key, value) => MapEntry('$key', value));
    final schemaVersion = _readSchemaVersion(root['schemaVersion']);
    final migrated = _migrate(root, schemaVersion);

    try {
      return _sanitize(CountoraState.fromJson(migrated));
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException(
        'The backup contains fields with invalid data types.',
      );
    }
  }

  int _readSchemaVersion(Object? value) {
    if (value == null) return 0;
    if (value is! num || value.isNaN || value.isInfinite) {
      throw const FormatException('schemaVersion must be a finite number.');
    }
    final result = value.toInt();
    if (result != value || result < 0) {
      throw const FormatException('schemaVersion must be a non-negative integer.');
    }
    if (result > currentSchemaVersion) {
      throw FormatException(
        'This backup uses schema $result, but this Countora build supports up to '
        'schema $currentSchemaVersion.',
      );
    }
    return result;
  }

  Map<String, Object?> _migrate(
    Map<String, Object?> root,
    int schemaVersion,
  ) {
    var current = Map<String, Object?>.from(root);
    var version = schemaVersion;

    // Schema 0 is the pre-versioned development format. Its field layout is
    // compatible with schema 1, so migration only stamps the explicit version.
    if (version == 0) {
      current['schemaVersion'] = 1;
      version = 1;
    }

    if (version != currentSchemaVersion) {
      throw FormatException('Unsupported migrated schema version: $version.');
    }
    return current;
  }

  CountoraState _sanitize(CountoraState state) {
    final timerIds = <String>{};
    final timers = <CountdownTimer>[];
    for (final timer in state.timers) {
      if (timers.length >= maxTimers) break;
      final id = _cleanId(timer.id);
      if (id == null || !timerIds.add(id)) continue;
      timers.add(_sanitizeTimer(timer, id));
    }

    final presetIds = <String>{};
    final presets = <TimerPreset>[];
    for (final preset in state.presets) {
      if (presets.length >= maxPresets) break;
      final id = _cleanId(preset.id);
      if (id == null || !presetIds.add(id)) continue;
      presets.add(
        TimerPreset(
          id: id,
          name: _cleanText(preset.name, fallback: 'Preset'),
          group: _cleanGroup(preset.group),
          steps: _sanitizeSteps(preset.steps),
          useCount: preset.useCount.clamp(0, 1000000000).toInt(),
        ),
      );
    }

    final history = <TimerHistoryEntry>[];
    for (final entry in state.history) {
      if (history.length >= maxHistoryEntries) break;
      final timerId = _cleanId(entry.timerId);
      if (timerId == null) continue;
      history.add(
        TimerHistoryEntry(
          timerId: timerId,
          name: _cleanText(entry.name, fallback: 'Timer'),
          group: _cleanGroup(entry.group),
          completedAtUtc: entry.completedAtUtc.toUtc(),
          totalDurationSeconds: entry.totalDurationSeconds
              .clamp(0, maxIntervalSeconds * maxIntervalsPerTimer)
              .toInt(),
        ),
      );
    }

    return CountoraState(
      timers: List<CountdownTimer>.unmodifiable(timers),
      presets: List<TimerPreset>.unmodifiable(presets),
      history: List<TimerHistoryEntry>.unmodifiable(history),
      settings: state.settings,
    );
  }

  CountdownTimer _sanitizeTimer(CountdownTimer timer, String id) {
    final steps = _sanitizeSteps(timer.steps);
    final index = timer.currentStepIndex.clamp(0, steps.length - 1).toInt();
    final remaining = timer.remainingWhenPausedSeconds
        .clamp(0, maxRemainingSeconds)
        .toInt();

    var status = timer.status;
    var endsAtUtc = timer.endsAtUtc?.toUtc();
    var startedAtUtc = timer.startedAtUtc?.toUtc();
    var completedAtUtc = timer.completedAtUtc?.toUtc();

    if (status == CountdownStatus.running && endsAtUtc == null) {
      status = CountdownStatus.paused;
      startedAtUtc = null;
    }
    if (status == CountdownStatus.completed) {
      endsAtUtc = null;
      startedAtUtc = null;
      completedAtUtc ??= DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    } else {
      completedAtUtc = null;
    }

    return CountdownTimer(
      id: id,
      name: _cleanText(timer.name, fallback: 'Timer'),
      group: _cleanGroup(timer.group),
      steps: steps,
      currentStepIndex: index,
      status: status,
      remainingWhenPausedSeconds:
          status == CountdownStatus.completed ? 0 : remaining,
      endsAtUtc: endsAtUtc,
      startedAtUtc: startedAtUtc,
      completedAtUtc: completedAtUtc,
    );
  }

  List<IntervalStep> _sanitizeSteps(List<IntervalStep> raw) {
    final steps = <IntervalStep>[];
    for (final step in raw) {
      if (steps.length >= maxIntervalsPerTimer) break;
      final duration = step.durationSeconds;
      if (duration <= 0 || duration > maxIntervalSeconds) continue;
      steps.add(
        IntervalStep(
          label: _cleanText(step.label, fallback: 'Interval'),
          durationSeconds: duration,
        ),
      );
    }
    if (steps.isEmpty) {
      steps.add(const IntervalStep(label: 'Timer', durationSeconds: 60));
    }
    return List<IntervalStep>.unmodifiable(steps);
  }

  String? _cleanId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > maxIdLength) return null;
    return trimmed;
  }

  String _cleanText(String value, {required String fallback}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.length <= maxNameLength
        ? trimmed
        : trimmed.substring(0, maxNameLength);
  }

  String _cleanGroup(String value) {
    final trimmed = value.trim();
    return trimmed.length <= maxGroupLength
        ? trimmed
        : trimmed.substring(0, maxGroupLength);
  }
}
