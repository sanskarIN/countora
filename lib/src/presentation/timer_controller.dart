import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/local_store.dart';
import '../data/notification_service.dart';
import '../domain/models.dart';

class TimerController extends ChangeNotifier {
  TimerController({
    required TimerStore store,
    required NotificationService notifications,
    DateTime Function()? nowUtc,
  })  : _store = store,
        _notifications = notifications,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  final TimerStore _store;
  final NotificationService _notifications;
  final DateTime Function() _nowUtc;

  List<CountdownTimer> _timers = const <CountdownTimer>[];
  List<TimerPreset> _presets = const <TimerPreset>[];
  List<TimerHistoryEntry> _history = const <TimerHistoryEntry>[];
  CountoraSettings _settings = const CountoraSettings();
  Timer? _ticker;
  String _searchQuery = '';
  String _groupFilter = '';
  String? _lastError;

  List<CountdownTimer> get timers => List.unmodifiable(_timers);
  List<TimerPreset> get presets => List.unmodifiable(_presets);
  List<TimerHistoryEntry> get history => List.unmodifiable(_history);
  CountoraSettings get settings => _settings;
  String get searchQuery => _searchQuery;
  String get groupFilter => _groupFilter;
  String? get lastError => _lastError;

  List<String> get groups {
    final values = <String>{
      ..._timers.map((timer) => timer.group.trim()),
      ..._presets.map((preset) => preset.group.trim()),
    }..removeWhere((value) => value.isEmpty);
    final result = values.toList()..sort();
    return result;
  }

  List<CountdownTimer> get visibleTimers {
    final query = _searchQuery.trim().toLowerCase();
    return _timers.where((timer) {
      final groupMatches = _groupFilter.isEmpty || timer.group == _groupFilter;
      final queryMatches = query.isEmpty ||
          timer.name.toLowerCase().contains(query) ||
          timer.group.toLowerCase().contains(query) ||
          timer.steps.any((step) => step.label.toLowerCase().contains(query));
      return groupMatches && queryMatches;
    }).toList()
      ..sort((a, b) {
        final statusOrder = a.status.index.compareTo(b.status.index);
        if (statusOrder != 0) return statusOrder;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  Future<void> initialize() async {
    final state = await _store.load();
    _timers = state.timers;
    _presets = state.presets;
    _history = state.history;
    _settings = state.settings;
    await _reconcileTimers();
    _startTicker();
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  void setGroupFilter(String value) {
    if (_groupFilter == value) return;
    _groupFilter = value;
    notifyListeners();
  }

  Future<void> addTimer({
    required String name,
    required String group,
    required List<IntervalStep> steps,
    bool startImmediately = true,
  }) async {
    _clearError();
    final safeName = _validatedName(name);
    final safeSteps = _validatedSteps(steps);
    final now = _nowUtc();
    final first = safeSteps.first;

    final timer = CountdownTimer(
      id: _newId(),
      name: safeName,
      group: group.trim(),
      steps: safeSteps,
      currentStepIndex: 0,
      status:
          startImmediately ? CountdownStatus.running : CountdownStatus.paused,
      remainingWhenPausedSeconds: first.durationSeconds,
      startedAtUtc: startImmediately ? now : null,
      endsAtUtc: startImmediately
          ? now.add(Duration(seconds: first.durationSeconds))
          : null,
    );

    _timers = <CountdownTimer>[..._timers, timer];
    await _persistAndSchedule(timer);
  }

  Future<void> addPreset({
    required String name,
    required String group,
    required List<IntervalStep> steps,
  }) async {
    final preset = TimerPreset(
      id: _newId(),
      name: _validatedName(name),
      group: group.trim(),
      steps: _validatedSteps(steps),
      useCount: 0,
    );
    _presets = <TimerPreset>[..._presets, preset];
    await _persist();
  }

  Future<void> startPreset(String presetId) async {
    final index = _presets.indexWhere((preset) => preset.id == presetId);
    if (index < 0) return;
    final preset = _presets[index];
    await addTimer(
      name: preset.name,
      group: preset.group,
      steps: preset.steps,
    );
    final updated = preset.copyWith(useCount: preset.useCount + 1);
    _presets = <TimerPreset>[..._presets]..[index] = updated;
    await _persist();
  }

  Future<void> saveTimerAsPreset(String timerId) async {
    final timer = _findTimer(timerId);
    if (timer == null) return;
    await addPreset(
      name: timer.name,
      group: timer.group,
      steps: timer.steps,
    );
  }

  Future<void> pause(String timerId) async {
    final timer = _findTimer(timerId);
    if (timer == null || timer.status != CountdownStatus.running) return;

    final remaining = timer.remaining(_nowUtc()).inSeconds;
    final updated = timer.copyWith(
      status: CountdownStatus.paused,
      remainingWhenPausedSeconds: remaining,
      clearEndsAt: true,
      clearStartedAt: true,
    );
    _replaceTimer(updated);
    await _notifications.cancelTimer(timerId);
    await _persist();
  }

  Future<void> resume(String timerId) async {
    final timer = _findTimer(timerId);
    if (timer == null || timer.status != CountdownStatus.paused) return;
    if (timer.remainingWhenPausedSeconds <= 0) {
      await _advanceOrComplete(timer);
      return;
    }

    final now = _nowUtc();
    final updated = timer.copyWith(
      status: CountdownStatus.running,
      startedAtUtc: now,
      endsAtUtc: now.add(
        Duration(seconds: timer.remainingWhenPausedSeconds),
      ),
    );
    _replaceTimer(updated);
    await _persistAndSchedule(updated);
  }

  Future<void> addTime(String timerId, Duration amount) async {
    if (amount.inSeconds <= 0) return;
    final timer = _findTimer(timerId);
    if (timer == null || timer.status == CountdownStatus.completed) return;

    CountdownTimer updated;
    if (timer.status == CountdownStatus.running && timer.endsAtUtc != null) {
      updated = timer.copyWith(endsAtUtc: timer.endsAtUtc!.add(amount));
    } else {
      updated = timer.copyWith(
        remainingWhenPausedSeconds:
            timer.remainingWhenPausedSeconds + amount.inSeconds,
      );
    }

    _replaceTimer(updated);
    await _persistAndSchedule(updated);
  }

  Future<void> restart(String timerId) async {
    final timer = _findTimer(timerId);
    if (timer == null) return;
    final now = _nowUtc();
    final first = timer.steps.first;
    final updated = timer.copyWith(
      currentStepIndex: 0,
      status: CountdownStatus.running,
      remainingWhenPausedSeconds: first.durationSeconds,
      startedAtUtc: now,
      endsAtUtc: now.add(Duration(seconds: first.durationSeconds)),
      clearCompletedAt: true,
    );
    _replaceTimer(updated);
    await _persistAndSchedule(updated);
  }

  Future<void> removeTimer(String timerId) async {
    _timers = _timers.where((timer) => timer.id != timerId).toList();
    await _notifications.cancelTimer(timerId);
    await _persist();
  }

  Future<void> removePreset(String presetId) async {
    _presets = _presets.where((preset) => preset.id != presetId).toList();
    await _persist();
  }

  Future<void> clearHistory() async {
    _history = const <TimerHistoryEntry>[];
    await _persist();
  }

  Future<void> updateSettings(CountoraSettings value) async {
    final notificationsWereDisabled =
        _settings.notificationsEnabled && !value.notificationsEnabled;
    _settings = value;

    if (notificationsWereDisabled) {
      for (final timer in _timers) {
        await _notifications.cancelTimer(timer.id);
      }
    } else if (value.notificationsEnabled) {
      await _notifications.requestPermissions();
      for (final timer in _timers.where(
        (item) => item.status == CountdownStatus.running,
      )) {
        await _schedule(timer);
      }
    }

    await _persist();
  }

  Future<void> markOnboardingSeen() async {
    await updateSettings(_settings.copyWith(onboardingSeen: true));
  }

  String exportJson() {
    return const JsonEncoder.withIndent('  ').convert(_state.toJson());
  }

  Future<void> importJson(String raw) async {
    _clearError();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<Object?, Object?>) {
        throw const FormatException('The backup root must be a JSON object.');
      }
      final imported = CountoraState.fromJson(
        decoded.map((key, value) => MapEntry('$key', value)),
      );
      _timers = imported.timers;
      _presets = imported.presets;
      _history = imported.history.take(500).toList();
      _settings = imported.settings;
      await _reconcileTimers();
      await _persist();
    } on FormatException catch (error) {
      _lastError = error.message;
      notifyListeners();
      rethrow;
    }
  }

  Duration remainingFor(CountdownTimer timer) => timer.remaining(_nowUtc());

  Future<void> _reconcileTimers() async {
    final now = _nowUtc();
    var changed = false;
    final runningIds = _timers
        .where((timer) => timer.status == CountdownStatus.running)
        .map((timer) => timer.id)
        .toList();

    for (final timerId in runningIds) {
      changed =
          await _consumeExpiredTimer(timerId, now, scheduleFinal: false) ||
          changed;
    }
    if (changed) {
      await _persist();
    }
    for (final timer
        in _timers.where((item) => item.status == CountdownStatus.running)) {
      await _schedule(timer);
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_tick());
    });
  }

  Future<void> _tick() async {
    final now = _nowUtc();
    final expiredIds = _timers
        .where(
          (timer) =>
              timer.status == CountdownStatus.running &&
              timer.remaining(now) == Duration.zero,
        )
        .map((timer) => timer.id)
        .toList();

    var changed = false;
    for (final timerId in expiredIds) {
      changed = await _consumeExpiredTimer(timerId, now) || changed;
    }
    if (changed) {
      await _persist();
    } else if (_timers.any(
      (timer) => timer.status == CountdownStatus.running,
    )) {
      notifyListeners();
    }
  }

  Future<bool> _consumeExpiredTimer(
    String timerId,
    DateTime now, {
    bool scheduleFinal = true,
  }) async {
    var changed = false;
    // A timer has at most 32 interval steps, so this guard also protects
    // against corrupted state causing an accidental infinite loop.
    for (var guard = 0; guard < 33; guard += 1) {
      final current = _findTimer(timerId);
      if (current == null ||
          current.status != CountdownStatus.running ||
          current.remaining(now) > Duration.zero) {
        break;
      }
      await _advanceOrComplete(
        current,
        persist: false,
        scheduleNotifications: false,
      );
      changed = true;
    }

    final current = _findTimer(timerId);
    if (scheduleFinal &&
        current != null &&
        current.status == CountdownStatus.running) {
      await _schedule(current);
    }
    return changed;
  }

  Future<void> _advanceOrComplete(
    CountdownTimer timer, {
    bool persist = true,
    bool scheduleNotifications = true,
  }) async {
    final latest = _findTimer(timer.id);
    if (latest == null) return;

    final nextIndex = latest.currentStepIndex + 1;
    if (nextIndex < latest.steps.length) {
      final now = _nowUtc();
      final next = latest.steps[nextIndex];
      // Anchor the next interval to the previous absolute deadline rather than
      // to the moment the UI wakes up. This prevents interval drift and lets
      // suspended apps catch up through multiple elapsed steps deterministically.
      final nextStartedAt = latest.endsAtUtc ?? now;
      final advanced = latest.copyWith(
        currentStepIndex: nextIndex,
        status: CountdownStatus.running,
        remainingWhenPausedSeconds: next.durationSeconds,
        startedAtUtc: nextStartedAt,
        endsAtUtc: nextStartedAt.add(Duration(seconds: next.durationSeconds)),
      );
      _replaceTimer(advanced);
      if (scheduleNotifications) {
        await _schedule(advanced);
      }
    } else {
      final completedAt = _nowUtc();
      final completed = latest.copyWith(
        status: CountdownStatus.completed,
        remainingWhenPausedSeconds: 0,
        clearEndsAt: true,
        clearStartedAt: true,
        completedAtUtc: completedAt,
      );
      _replaceTimer(completed);
      _history = <TimerHistoryEntry>[
        TimerHistoryEntry(
          timerId: latest.id,
          name: latest.name,
          group: latest.group,
          completedAtUtc: completedAt,
          totalDurationSeconds: latest.totalDurationSeconds,
        ),
        ..._history,
      ].take(500).toList();
      await _notifications.cancelTimer(latest.id);
    }

    if (persist) await _persist();
  }

  Future<void> _persistAndSchedule(CountdownTimer timer) async {
    await _persist();
    await _schedule(timer);
  }

  Future<void> _schedule(CountdownTimer timer) async {
    if (!_settings.notificationsEnabled) return;
    await _notifications.scheduleTimer(
      timer,
      soundEnabled: _settings.soundEnabled,
      vibrationEnabled: _settings.vibrationEnabled,
      quietMode: _settings.quietMode,
    );
  }

  Future<void> _persist() async {
    try {
      await _store.save(_state);
      notifyListeners();
    } on Object catch (error) {
      _lastError = 'Local save failed: $error';
      notifyListeners();
      rethrow;
    }
  }

  CountoraState get _state => CountoraState(
        timers: _timers,
        presets: _presets,
        history: _history,
        settings: _settings,
      );

  CountdownTimer? _findTimer(String id) {
    for (final timer in _timers) {
      if (timer.id == id) return timer;
    }
    return null;
  }

  void _replaceTimer(CountdownTimer updated) {
    final index = _timers.indexWhere((timer) => timer.id == updated.id);
    if (index < 0) return;
    _timers = <CountdownTimer>[..._timers]..[index] = updated;
  }

  String _validatedName(String value) {
    final clean = value.trim();
    if (clean.isEmpty) {
      throw ArgumentError.value(value, 'name', 'Timer name is required.');
    }
    if (clean.length > 80) {
      throw ArgumentError.value(value, 'name', 'Maximum length is 80.');
    }
    return clean;
  }

  List<IntervalStep> _validatedSteps(List<IntervalStep> value) {
    if (value.isEmpty || value.length > 32) {
      throw ArgumentError.value(
        value.length,
        'steps',
        'Use between 1 and 32 intervals.',
      );
    }
    for (final step in value) {
      if (step.durationSeconds <= 0 ||
          step.durationSeconds > const Duration(days: 365).inSeconds) {
        throw ArgumentError.value(
          step.durationSeconds,
          'durationSeconds',
          'Each interval must be between 1 second and 365 days.',
        );
      }
      if (step.label.trim().isEmpty || step.label.length > 80) {
        throw ArgumentError.value(
          step.label,
          'label',
          'Interval labels must contain 1–80 characters.',
        );
      }
    }
    return List<IntervalStep>.unmodifiable(value);
  }

  String _newId() {
    final now = _nowUtc().microsecondsSinceEpoch;
    return 't_${now}_${_timers.length + _presets.length}';
  }

  void _clearError() => _lastError = null;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
