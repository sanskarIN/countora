import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

abstract interface class TimerStore {
  Future<CountoraState> load();
  Future<void> save(CountoraState state);
  Future<void> clear();
}

class SharedPreferencesTimerStore implements TimerStore {
  SharedPreferencesTimerStore(this._preferences);

  static const _stateKey = 'countora_state_v1';

  final SharedPreferences _preferences;

  @override
  Future<CountoraState> load() async {
    final raw = _preferences.getString(_stateKey);
    if (raw == null || raw.trim().isEmpty) {
      return const CountoraState();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<Object?, Object?>) {
        return const CountoraState();
      }
      return CountoraState.fromJson(
        decoded.map((key, value) => MapEntry('$key', value)),
      );
    } on FormatException {
      return const CountoraState();
    }
  }

  @override
  Future<void> save(CountoraState state) async {
    final encoded = jsonEncode(state.toJson());
    final didSave = await _preferences.setString(_stateKey, encoded);
    if (!didSave) {
      throw StateError('Countora could not save local data.');
    }
  }

  @override
  Future<void> clear() async {
    final didRemove = await _preferences.remove(_stateKey);
    if (!didRemove && _preferences.containsKey(_stateKey)) {
      throw StateError('Countora could not clear local data.');
    }
  }
}
