import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import 'state_codec.dart';

abstract interface class TimerStore {
  Future<CountoraState> load();
  Future<void> save(CountoraState state);
  Future<void> clear();
}

class SharedPreferencesTimerStore implements TimerStore {
  SharedPreferencesTimerStore(this._preferences);

  static const _stateKey = 'countora_state_v1';
  static const _pendingKey = 'countora_state_pending_v1';
  static const _backupKey = 'countora_state_backup_v1';

  final SharedPreferences _preferences;

  @override
  Future<CountoraState> load() async {
    final primary = _decode(_preferences.getString(_stateKey));
    if (primary != null) return primary;

    // A valid pending value means a prior save produced a complete staged
    // document but did not finish promoting it. Prefer it over an older backup.
    final pending = _decode(_preferences.getString(_pendingKey));
    if (pending != null) {
      await _restoreRecoveredState(pending);
      return pending;
    }

    final backup = _decode(_preferences.getString(_backupKey));
    if (backup != null) {
      await _restoreRecoveredState(backup);
      return backup;
    }

    return const CountoraState();
  }

  @override
  Future<void> save(CountoraState state) async {
    final encoded = StateCodec.encode(state);

    if (!await _preferences.setString(_pendingKey, encoded)) {
      throw StateError('Countora could not stage local data.');
    }

    final current = _preferences.getString(_stateKey);
    if (current != null && _decode(current) != null) {
      if (!await _preferences.setString(_backupKey, current)) {
        throw StateError('Countora could not preserve the local backup.');
      }
    }

    if (!await _preferences.setString(_stateKey, encoded)) {
      throw StateError('Countora could not save local data.');
    }

    final removed = await _preferences.remove(_pendingKey);
    if (!removed && _preferences.containsKey(_pendingKey)) {
      throw StateError('Countora could not finish the local save.');
    }
  }

  @override
  Future<void> clear() async {
    for (final key in <String>[_stateKey, _pendingKey, _backupKey]) {
      final removed = await _preferences.remove(key);
      if (!removed && _preferences.containsKey(key)) {
        throw StateError('Countora could not clear local data.');
      }
    }
  }

  CountoraState? _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return StateCodec.decode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> _restoreRecoveredState(CountoraState state) async {
    final encoded = StateCodec.encode(state);
    final didSave = await _preferences.setString(_stateKey, encoded);
    if (!didSave) return;
    await _preferences.remove(_pendingKey);
  }
}
