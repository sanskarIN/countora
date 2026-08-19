import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_logger.dart';
import '../data/local_store.dart';
import '../data/notification_service.dart';
import '../data/state_codec.dart';
import '../domain/models.dart';

class TimerController extends ChangeNotifier {
  TimerController({
    required TimerStore store,
    required NotificationService notifications,
    DateTime Function()? nowUtc,
    CountoraStateCodec stateCodec = const CountoraStateCodec(),
  })  : _store = store,
        _notifications = notifications,
        _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
        _stateCodec = stateCodec;

  static const _logger = AppLogger('timer_controller');

  final TimerStore _store;
  final NotificationService _notifications;
  final DateTime Function() _nowUtc;
  final CountoraStateCodec _stateCodec;

  List<CountdownTimer> _timers = const <CountdownTimer>[];
  List<TimerPreset> _presets = const <TimerPreset>[];
  List<TimerHistoryEntry> _history = const <TimerHistoryEntry>[];
  CountoraSettings _settings = const CountoraSettings();
  Timer? _ticker;
  String _searchQuery = '';
  String _groupFilter = '';
  String? _lastError;
  int _nextIdSequence = 0;
  bool _tickInProgress = false;
  bool _notificationPermissionRequestedThisSession = false;

  List<CountdownTimer> get timers => List.unmodifiable(_timers);
  List<TimerPreset> get presets => List.unmodifiable(_presets);
  List<TimerHistoryEntry> get history => List.unmodifiable(_history);
  CountoraSettings get settings => _settings;
  String get searchQuery => _searchQuery;
  String get groupFilter => _groupFilter;
  String? get lastError => _lastError;

  int get runningCount =>
      _timers.where((timer) => timer.status == CountdownStatus.running).length;
  int get pausedCount =>
      _timers.where((timer) => timer.status == CountdownStatus.paused).length;
  int get completedCount =>
      _timers.where((timer) => timer.status == CountdownStatus.completed).length;

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
    _nextIdSequence = _timers.length + _presets.length;
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

  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
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
    final safeGroup = _validatedGroup(group);
    final safeSteps = _validatedSteps(steps);
    final now = _nowUtc();
    final first = safeSteps.first;

    final timer = CountdownTimer(
      id: _newId(),
      name: safeName,
      group: safeGroup,
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

  Future<void> duplicateTimer(
    String timerId, {
    bool startImmediately = false,
  }) async {
    final timer = _findTimer(timerId);
    if (timer == null) return;
    await addTimer(
      name: timer.name,
      group: timer.group,
      steps: timer.steps,
      startImmediately: startImmediately,
    );
  }

  Future<void> updateTimerDetails({
    required String timerId,
    required String name,
    required String group,
  }) async {
    final timer = _findTimer(timerId);
    if (timer == null) return;
    final updated = timer.copyWith(
      name: _validatedName(name),
      group: _validatedGroup(group),
    );
    _replaceTimer(updated);
    await _persistAndSchedule(updated);
  }

  Future<void> addPreset({
    required String name,
    required String group,
    required List<IntervalStep> steps,
  }) async {
    final preset = TimerPreset(
      id: _newId(),
      name: _validatedName(name),
      group: _validatedGroup(group),
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

  Future<void> startFromHistory(TimerHistoryEntry entry) async {
    final duration = entry.totalDurationSeconds.clamp(
      1,
      CountoraStateCodec.maxIntervalSeconds,
    );
    await addTimer(
      name: entry.name,
      group: entry.group,
      steps: <IntervalStep>[
        IntervalStep(
          label: entry.name,
          durationSeconds: duration.toInt(),
        ),
      ],
    );
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

  Future<void> pauseAllRunning() async {
    final now = _nowUtc();
    final running = _timers
        .where((timer) => timer.status == CountdownStatus.running)
        .toList();
    if (running.isEmpty) return;

    final runningIds = running.map((timer) => timer.id).toSet();
    _timers = _timers.map((timer) {
      if (!runningIds.contains(timer.id)) return timer;
      return timer.copyWith(
        status: CountdownStatus.paused,
        remainingWhenPausedSeconds: timer.remaining(now).inSeconds,
        clearEndsAt: true,
        clearStartedAt: true,
      );
    }).toList();

    for (final timer in running) {
      await _notifications.cancelTimer(timer.id);
    }
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

  Future<void> resumeAllPaused() async {
    final pausedIds = _timers
        .where((timer) => timer.status == CountdownStatus.paused)
        .map((timer) => timer.id)
        .toList();
    if (pausedIds.isEmpty) return;

    for (final id in pausedIds) {
      await resume(id);
    }
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

  Future<void> removeCompletedTimers() async {
    if (!_timers.any((timer) => timer.status == CountdownStatus.completed)) {
      return;
    }
    _timers = _timers
        .where((timer) => timer.status != CountdownStatus.completed)
        .toList();
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

  Future<void> clearAllData() async {
    _clearError();
    try {
      await _store.clear();
    } on Object catch (error) {
      _logger.error('local_clear_failed', error: error);
      _lastError = 'Countora could not erase local data. Please try again.';
      notifyListeners();
      return;
    }

    for (final timer in _timers) {
      await _notifications.cancelTimer(timer.id);
    }
    _timers = const <CountdownTimer>[];
    _presets = const <TimerPreset>[];
    _history = const <TimerHistoryEntry>[];
    _settings = const CountoraSettings();
    _searchQuery = '';
    _groupFilter = '';
    _lastError = null;
    notifyListeners();
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

  String exportJson() => _stateCodec.encodePretty(_state);

  Future<void> importJson(String raw) async {
    _clearError();
    try {
      final imported = _stateCodec.decode(raw);

      for (final timer in _timers) {
        await _notifications.cancelTimer(timer.id);
      }

      _timers = imported.timers;
      _presets = imported.presets;
      _history = imported.history;
      _settings = imported.settings;
      _searchQuery = '';
      _groupFilter = '';
      _nextIdSequence = _timers.length + _presets.length;
      await _reconcileTimers();
      await _persist();
    } on FormatException catch (error) {
      _lastError = error.message;
      notifyListeners();
      rethrow;
    }
  }

  Duration remainingFor(CountdownTimer timer) => timer.remaining(_nowUtc());

  Future<void> reconcile() async {
    await _reconcileTimers();
    notifyListeners();
  }

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
      unawaited(_runTickSafely());
    });
  }

  Future<void> _runTickSafely() async {
    if (_tickInProgress) return;
    _tickInProgress = true;
    try {
      await _tick();
    } finally {
      _tickInProgress = false;
    }
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
      ].take(CountoraStateCodec.maxHistoryEntries).toList();
      await _notifications.cancelTimer(latest.id);
    }

    if (persist) await _persist();
  }

  Future<void> _persistAndSchedule(CountdownTimer timer) async {
    await _persist();
    await _schedule(timer);
  }

  Future<void> _schedule(CountdownTimer timer) async {
    if (!_settings.notificationsEnabled ||
        timer.status != CountdownStatus.running ||
        timer.endsAtUtc == null) {
      return;
    }
    await _ensureNotificationPermissions();
    await _notifications.scheduleTimer(
      timer,
      soundEnabled: _settings.soundEnabled,
      vibrationEnabled: _settings.vibrationEnabled,
      quietMode: _settings.quietMode,
    );
  }

  Future<void> _ensureNotificationPermissions() async {
    if (_notificationPermissionRequestedThisSession) return;
    _notificationPermissionRequestedThisSession = true;
    await _notifications.requestPermissions();
  }

  Future<bool> _persist() async {
    try {
      await _store.save(_state);
      notifyListeners();
      return true;
    } on Object catch (error) {
      _logger.error('local_save_failed', error: error);
      _lastError = 'Countora could not save local changes. Please try again.';
      notifyListeners();
      return false;
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
    if (clean.length > CountoraStateCodec.maxNameLength) {
      throw ArgumentError.value(
        value,
        'name',
        'Maximum length is ${CountoraStateCodec.maxNameLength}.',
      );
    }
    return clean;
  }

  String _validatedGroup(String value) {
    final clean = value.trim();
    if (clean.length > CountoraStateCodec.maxGroupLength) {
      throw ArgumentError.value(
        value,
        'group',
        'Maximum length is ${CountoraStateCodec.maxGroupLength}.',
      );
    }
    return clean;
  }

  List<IntervalStep> _validatedSteps(List<IntervalStep> value) {
    if (value.isEmpty || value.length > CountoraStateCodec.maxIntervalsPerTimer) {
      throw ArgumentError.value(
        value.length,
        'steps',
        'Use between 1 and ${CountoraStateCodec.maxIntervalsPerTimer} intervals.',
      );
    }
    final result = <IntervalStep>[];
    for (final step in value) {
      if (step.durationSeconds <= 0 ||
          step.durationSeconds > CountoraStateCodec.maxIntervalSeconds) {
        throw ArgumentError.value(
          step.durationSeconds,
          'durationSeconds',
          'Each interval must be between 1 second and 365 days.',
        );
      }
      final label = step.label.trim();
      if (label.isEmpty || label.length > CountoraStateCodec.maxNameLength) {
        throw ArgumentError.value(
          step.label,
          'label',
          'Interval labels must contain 1–80 characters.',
        );
      }
      result.add(
        IntervalStep(label: label, durationSeconds: step.durationSeconds),
      );
    }
    return List<IntervalStep>.unmodifiable(result);
  }

  String _newId() {
    final usedIds = <String>{
      ..._timers.map((timer) => timer.id),
      ..._presets.map((preset) => preset.id),
    };
    String candidate;
    do {
      _nextIdSequence += 1;
      candidate = 't_${_nowUtc().microsecondsSinceEpoch}_$_nextIdSequence';
    } while (usedIds.contains(candidate));
    return candidate;
  }

  void _clearError() => _lastError = null;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
