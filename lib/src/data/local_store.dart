import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import 'state_codec.dart';

abstract interface class TimerStore {
  Future<CountoraState> load();
  Future<void> save(CountoraState state);
  Future<void> clear();
}

class SharedPreferencesTimerStore implements TimerStore {
  SharedPreferencesTimerStore(
    this._preferences, {
    CountoraStateCodec codec = const CountoraStateCodec(),
  }) : _codec = codec;

  static const _stateKey = 'countora_state_v1';

  final SharedPreferences _preferences;
  final CountoraStateCodec _codec;

  @override
  Future<CountoraState> load() async {
    final raw = _preferences.getString(_stateKey);
    if (raw == null || raw.trim().isEmpty) {
      return const CountoraState();
    }

    try {
      return _codec.decode(raw);
    } on FormatException {
      // Corrupted local state must never prevent Countora from starting. Import
      // operations are strict and surface validation errors to the user; local
      // recovery instead falls back to a safe empty state.
      return const CountoraState();
    }
  }

  @override
  Future<void> save(CountoraState state) async {
    final encoded = _codec.encode(state);
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
