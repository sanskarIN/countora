import 'dart:convert';

import 'models.dart';

/// Strict codec for user-controlled backup files.
///
/// Local persistence is deliberately tolerant so a partially damaged optional
/// field does not brick app startup. Imports are different: they are untrusted
/// input and are validated before replacing any existing state.
abstract final class BackupCodec {
  static const int schemaVersion = 1;
  static const int maxBackupBytes = 1024 * 1024;
  static const int maxTimers = 256;
  static const int maxPresets = 256;
  static const int maxHistoryEntries = 500;
  static const int maxStepsPerTimer = 32;
  static const int maxIntervalSeconds = 365 * 24 * 60 * 60;

  static String encode(CountoraState state) {
    return const JsonEncoder.withIndent('  ').convert(state.toJson());
  }

  static CountoraState decode(String raw) {
    if (raw.length > maxBackupBytes ||
        utf8.encode(raw).length > maxBackupBytes) {
      throw const FormatException('The Countora backup is too large.');
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('The backup is not valid JSON.');
    }

    if (decoded is! Map<Object?, Object?>) {
      throw const FormatException('The backup root must be a JSON object.');
    }

    final root = decoded.map((key, value) => MapEntry('$key', value));
    final version = root['schemaVersion'];
    if (version is! num ||
        version.toInt() != version ||
        version.toInt() != schemaVersion) {
      throw const FormatException('Unsupported Countora backup version.');
    }

    final timers = _validatedList(root, 'timers', maxTimers);
    final presets = _validatedList(root, 'presets', maxPresets);
    final history = _validatedList(root, 'history', maxHistoryEntries);

    _validateUniqueIds(timers, 'timer');
    _validateUniqueIds(presets, 'preset');

    for (final item in timers) {
      _validateTimer(item);
    }
    for (final item in presets) {
      _validatePreset(item);
    }
    for (final item in history) {
      _validateHistory(item);
    }
    _validateSettings(root['settings']);

    return CountoraState.fromJson(root);
  }

  static void _validateUniqueIds(
    List<Map<String, Object?>> items,
    String itemType,
  ) {
    final ids = <String>{};
    for (final item in items) {
      final id = item['id'];
      if (id is! String || id.trim().isEmpty || !ids.add(id)) {
        throw FormatException(
          'Backup contains a duplicate or invalid $itemType ID.',
        );
      }
    }
  }

  static List<Map<String, Object?>> _validatedList(
    Map<String, Object?> root,
    String key,
    int maxItems,
  ) {
    final value = root[key];
    if (value is! List<Object?>) {
      throw FormatException('Backup field "$key" must be a list.');
    }
    if (value.length > maxItems) {
      throw FormatException('Backup field "$key" contains too many items.');
    }

    return value.map((item) {
      if (item is! Map<Object?, Object?>) {
        throw FormatException('Backup field "$key" contains an invalid item.');
      }
      return item.map(
        (entryKey, entryValue) => MapEntry('$entryKey', entryValue),
      );
    }).toList(growable: false);
  }

  static void _validateTimer(Map<String, Object?> timer) {
    _requiredText(timer, 'id', maxLength: 120);
    _requiredText(timer, 'name', maxLength: 80);
    _optionalText(timer, 'group', maxLength: 40);

    final steps = _steps(timer);
    final currentStepIndex = _requiredInt(timer, 'currentStepIndex');
    if (currentStepIndex < 0 || currentStepIndex >= steps.length) {
      throw const FormatException('Timer currentStepIndex is out of range.');
    }

    final status = timer['status'];
    if (status is! String ||
        !CountdownStatus.values.any((item) => item.name == status)) {
      throw const FormatException('Timer status is invalid.');
    }

    final remaining = _requiredInt(timer, 'remainingWhenPausedSeconds');
    if (remaining < 0 || remaining > maxIntervalSeconds * maxStepsPerTimer) {
      throw const FormatException('Timer remaining duration is invalid.');
    }

    _optionalDate(timer, 'endsAtUtc');
    _optionalDate(timer, 'startedAtUtc');
    _optionalDate(timer, 'completedAtUtc');
  }

  static void _validatePreset(Map<String, Object?> preset) {
    _requiredText(preset, 'id', maxLength: 120);
    _requiredText(preset, 'name', maxLength: 80);
    _optionalText(preset, 'group', maxLength: 40);
    _steps(preset);
    final useCount = _requiredInt(preset, 'useCount');
    if (useCount < 0 || useCount > 1000000000) {
      throw const FormatException('Preset use count is invalid.');
    }
  }

  static List<Map<String, Object?>> _steps(Map<String, Object?> owner) {
    final raw = owner['steps'];
    if (raw is! List<Object?> || raw.isEmpty || raw.length > maxStepsPerTimer) {
      throw const FormatException('A timer must contain 1–32 interval steps.');
    }

    return raw.map((item) {
      if (item is! Map<Object?, Object?>) {
        throw const FormatException('An interval step is invalid.');
      }
      final step = item.map((key, value) => MapEntry('$key', value));
      _requiredText(step, 'label', maxLength: 80);
      final seconds = _requiredInt(step, 'durationSeconds');
      if (seconds <= 0 || seconds > maxIntervalSeconds) {
        throw const FormatException(
          'Each interval must be between 1 second and 365 days.',
        );
      }
      return step;
    }).toList(growable: false);
  }

  static void _validateHistory(Map<String, Object?> item) {
    _requiredText(item, 'timerId', maxLength: 120);
    _requiredText(item, 'name', maxLength: 80);
    _optionalText(item, 'group', maxLength: 40);
    _requiredDate(item, 'completedAtUtc');
    final total = _requiredInt(item, 'totalDurationSeconds');
    if (total < 0 || total > maxIntervalSeconds * maxStepsPerTimer) {
      throw const FormatException('History duration is invalid.');
    }
  }

  static void _validateSettings(Object? value) {
    if (value is! Map<Object?, Object?>) {
      throw const FormatException('Backup settings are invalid.');
    }
    final settings = value.map((key, item) => MapEntry('$key', item));
    final theme = settings['themeMode'];
    if (theme is! String || !{'system', 'light', 'dark'}.contains(theme)) {
      throw const FormatException('Backup theme setting is invalid.');
    }

    for (final key in <String>[
      'notificationsEnabled',
      'soundEnabled',
      'vibrationEnabled',
      'quietMode',
      'reducedMotion',
      'compactCards',
      'onboardingSeen',
    ]) {
      if (settings[key] is! bool) {
        throw FormatException('Backup setting "$key" must be a boolean.');
      }
    }
  }

  static String _requiredText(
    Map<String, Object?> map,
    String key, {
    required int maxLength,
  }) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty || value.length > maxLength) {
      throw FormatException('Backup field "$key" is invalid.');
    }
    return value;
  }

  static void _optionalText(
    Map<String, Object?> map,
    String key, {
    required int maxLength,
  }) {
    final value = map[key];
    if (value is! String || value.length > maxLength) {
      throw FormatException('Backup field "$key" is invalid.');
    }
  }

  static int _requiredInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! num || value.toInt() != value) {
      throw FormatException('Backup field "$key" must be an integer.');
    }
    return value.toInt();
  }

  static void _optionalDate(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value == null) return;
    if (value is! String || DateTime.tryParse(value) == null) {
      throw FormatException('Backup field "$key" contains an invalid date.');
    }
  }

  static void _requiredDate(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String || DateTime.tryParse(value) == null) {
      throw FormatException('Backup field "$key" contains an invalid date.');
    }
  }
}
